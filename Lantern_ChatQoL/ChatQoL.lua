local Lantern = _G.Lantern;

-- Abort early if the core addon is not available.
if (not Lantern) then return; end

local ChatQoL = Lantern:NewModule("ChatQoL", {
    title = "Chat QoL",
    desc = "Chat QoL improvements for channels and message display.",
    enableLabel = "Enable Chat QoL",
});

local MAIN_CHAT_FRAME = 1;
local CHANNEL_REFRESH_DELAY = 1.0;
local MODE_MOVE = "move";
local MODE_LEAVE = "leave";
local MODE_NOTHING = "nothing";
local MODE_KEEP = "keep";

local DEFAULTS = {
    tradeMode = MODE_MOVE,
    tradeTabName = "Trade",
    servicesMode = MODE_MOVE,
    servicesTabName = "Services",
    usePlainUpArrow = false,
};

local function isTradeServicesChannel(name)
    if (type(name) ~= "string") then return; end
    local lower = name:lower();
    if (lower:find("services", 1, true)) then
        return "Services";
    end
    if (lower:find("trade", 1, true)) then
        return "Trade";
    end
end

local function getWindowIndexByName(name)
    if (not name) then return; end
    local max = NUM_CHAT_WINDOWS or 10;
    for i = 1, max do
        local windowName = GetChatWindowInfo(i);
        if (windowName == name) then
            return i;
        end
    end
end

local function refreshDock()
    if (GeneralDockManager and GeneralDockManager.UpdateTabs) then
        GeneralDockManager:UpdateTabs();
    end
    if (FCFDock_UpdateTabs and GeneralDockManager) then
        pcall(FCFDock_UpdateTabs, GeneralDockManager);
    end
    if (FCF_UpdateDockPosition) then
        pcall(FCF_UpdateDockPosition);
    end
    if (FCF_SelectWindow and _G.DEFAULT_CHAT_FRAME) then
        pcall(FCF_SelectWindow, _G.DEFAULT_CHAT_FRAME);
    end
end

local function ensureWindow(windowName)
    local function showAndDock(index, label)
        local frame = _G["ChatFrame" .. index];
        if (frame) then
            if (frame.Show) then frame:Show(); end
            if (frame.SetShown) then frame:SetShown(true); end
            if (GeneralDockManager and GeneralDockManager.DOCKED_CHAT_FRAMES) then
                if (frame.isDocked ~= 1) then
                    local ok = false;
                    if (FCFDock_AddChatFrame) then
                        local position = #GeneralDockManager.DOCKED_CHAT_FRAMES + 1;
                        ok = pcall(FCFDock_AddChatFrame, GeneralDockManager, frame, position);
                    end
                    if (not ok and FCF_DockFrame) then
                        pcall(FCF_DockFrame, frame, 1);
                    end
                end
            end
        end
        refreshDock();
        Lantern:Print("Chat QoL: tab ready: " .. tostring(label) .. " (#" .. tostring(index) .. ")");
    end

    local index = getWindowIndexByName(windowName);
    if (index) then
        showAndDock(index, windowName);
        return index;
    end
    if (FCF_OpenNewWindow) then
        local frame = FCF_OpenNewWindow(windowName);
        if (frame and frame.GetID) then
            local id = frame:GetID();
            showAndDock(id, windowName);
            return id;
        end
    end
    if (FCF_NewChatWindow) then
        local newIndex = FCF_NewChatWindow(windowName);
        if (newIndex) then
            showAndDock(newIndex, windowName);
            return newIndex;
        end
    end
    Lantern:Print("Chat QoL: failed to create tab: " .. tostring(windowName));
end

local function getChannelIdByName(channelName)
    if (not GetChannelName) then return; end
    local id = GetChannelName(channelName);
    if (type(id) == "number" and id > 0) then
        return id;
    end
end

local function addChannelToWindow(index, channelName)
    if (not index or not channelName) then return; end
    local channelId = getChannelIdByName(channelName);
    if (AddChatWindowChannel) then
        AddChatWindowChannel(index, channelId or channelName);
    end
    if (C_ChatInfo and C_ChatInfo.AddChatWindowChannel) then
        C_ChatInfo.AddChatWindowChannel(index, channelId or channelName);
    end
end

local function windowHasChannel(index, channelName)
    local channels = { GetChatWindowChannels(index) };
    for i = 1, #channels, 2 do
        if (channels[i] == channelName or channels[i + 1] == channelName) then
            return true;
        end
    end
end

local function removeChannelFromWindow(index, channelName)
    local frame = _G["ChatFrame" .. index];
    if (not frame or not channelName) then return; end
    if (ChatFrame_RemoveChannel) then
        ChatFrame_RemoveChannel(frame, channelName);
        return;
    end
    if (C_ChatInfo and C_ChatInfo.RemoveChatWindowChannel and frame.GetID) then
        C_ChatInfo.RemoveChatWindowChannel(frame:GetID(), channelName);
        if (frame.UpdateChannelMenu) then
            frame:UpdateChannelMenu();
        end
    end
end


local function ensureDB(self)
    _G.LanternChatQoLDB = _G.LanternChatQoLDB or {};
    self.db = _G.LanternChatQoLDB;
    for k, v in pairs(DEFAULTS) do
        if (self.db[k] == nil) then
            self.db[k] = v;
        end
    end
end

local function getModeConfig(self, kind)
    if (kind == "Services") then
        return self.db.servicesMode, self.db.servicesTabName;
    end
    return self.db.tradeMode, self.db.tradeTabName;
end

local function normalizeTabName(kind, name)
    if (type(name) ~= "string") then
        return kind;
    end
    name = name:match("^%s*(.-)%s*$");
    if (name == "") then
        return kind;
    end
    return name;
end


local lastMessage;
local playerName = UnitName("player");
local playerFullName;
do
    local realm = GetNormalizedRealmName and GetNormalizedRealmName();
    if (realm) then
        playerFullName = playerName .. "-" .. realm;
    end
end

local MONITORED_CHAT_EVENTS = {
    "CHAT_MSG_SAY",
    "CHAT_MSG_YELL",
    "CHAT_MSG_PARTY",
    "CHAT_MSG_PARTY_LEADER",
    "CHAT_MSG_RAID",
    "CHAT_MSG_RAID_LEADER",
    "CHAT_MSG_INSTANCE_CHAT",
    "CHAT_MSG_INSTANCE_CHAT_LEADER",
    "CHAT_MSG_GUILD",
    "CHAT_MSG_OFFICER",
    "CHAT_MSG_CHANNEL",
    "CHAT_MSG_EMOTE",
    "CHAT_MSG_TEXT_EMOTE",
    "CHAT_MSG_WHISPER_INFORM",
    "CHAT_MSG_BN_WHISPER_INFORM",
    "CHAT_MSG_WHISPER",
    "CHAT_MSG_BN_WHISPER",
};

local function captureMessage(_, msg, author)
    if (author == playerName or author == playerFullName) then
        lastMessage = msg;
    end
end

local function shouldUsePlainUp(self)
    return self.db and self.db.usePlainUpArrow;
end

local function handleEditBoxKey(module, editBox, key)
    if (not module.enabled or not lastMessage or key ~= "UP") then return false; end
    local usePlain = shouldUsePlainUp(module);
    local altDown = IsAltKeyDown();
    if (not usePlain and not altDown) then
        return false;
    end
    if (usePlain and (IsControlKeyDown() or IsShiftKeyDown() or IsAltKeyDown())) then
        return false;
    end
    editBox:SetText(lastMessage);
    editBox:SetCursorPosition(strlen(lastMessage or ""));
    return true;
end

function ChatQoL:AttachEditBoxHandlers()
    if (self._editBoxesHooked) then return; end
    local max = NUM_CHAT_WINDOWS or 10;
    for i = 1, max do
        local box = _G["ChatFrame" .. i .. "EditBox"];
        if (box and not box._lanternChatQoLHooked) then
            box._lanternChatQoLHooked = true;
            box._lanternChatQoL_OnKeyDown = box:GetScript("OnKeyDown");
            box:SetScript("OnKeyDown", function(editBox, key)
                if (handleEditBoxKey(ChatQoL, editBox, key)) then
                    return;
                end
                if (editBox._lanternChatQoL_OnKeyDown) then
                    editBox._lanternChatQoL_OnKeyDown(editBox, key);
                end
            end);
        end
    end
    self._editBoxesHooked = true;
end

function ChatQoL:GetOptions()
    ensureDB(self);
    local modeValues = {
        [MODE_MOVE] = "Move to own tab",
        [MODE_LEAVE] = "Leave",
        [MODE_NOTHING] = "Nothing",
        [MODE_KEEP] = "Keep in main chat",
    };
    return {
        general = {
            order = 1,
            type = "group",
            name = "General",
            args = {
                usePlainUpArrow = {
                    order = 1,
                    type = "toggle",
                    name = "Use up/down without Alt",
                    width = "full",
                    get = function() return self.db.usePlainUpArrow; end,
                    set = function(_, value)
                        self.db.usePlainUpArrow = value and true or false;
                    end,
                },
            },
        },
        channels = {
            order = 2,
            type = "group",
            name = "Chat channels",
            args = {
                desc = {
                    order = 0,
                    type = "description",
                    name = "Choose how chat channels are handled. This setting applies globally to all characters.",
                    fontSize = "medium",
                },
                runNow = {
                    order = 1,
                    type = "execute",
                    name = "Apply now",
                    width = "full",
                    func = function()
                        self:ApplyChannelSettingsNow();
                    end,
                },
                tradeMode = {
                    order = 10,
                    type = "select",
                    name = "Trade channel",
                    values = modeValues,
                    get = function() return self.db.tradeMode; end,
            set = function(_, value)
                self.db.tradeMode = value;
                self:ScheduleChannelCheck();
            end,
        },
                tradeTabName = {
                    order = 11,
                    type = "input",
                    name = "Trade channel name",
                    disabled = function() return self.db.tradeMode ~= MODE_MOVE; end,
                    get = function() return self.db.tradeTabName; end,
                    set = function(_, value)
                        self.db.tradeTabName = normalizeTabName("Trade", value);
                        self:ScheduleChannelCheck();
                    end,
                },
                servicesMode = {
                    order = 12,
                    type = "select",
                    name = "Services channel",
                    values = modeValues,
                    get = function() return self.db.servicesMode; end,
            set = function(_, value)
                self.db.servicesMode = value;
                self:ScheduleChannelCheck();
            end,
        },
                servicesTabName = {
                    order = 13,
                    type = "input",
                    name = "Services channel name",
                    disabled = function() return self.db.servicesMode ~= MODE_MOVE; end,
                    get = function() return self.db.servicesTabName; end,
                    set = function(_, value)
                        self.db.servicesTabName = normalizeTabName("Services", value);
                        self:ScheduleChannelCheck();
                    end,
                },
            },
        },
    };
end

function ChatQoL:HandleChatChannels()
    local tradeMode, tradeTabName = getModeConfig(self, "Trade");
    local servicesMode, servicesTabName = getModeConfig(self, "Services");
    if (tradeMode == MODE_MOVE) then
        local name = normalizeTabName("Trade", tradeTabName);
        local existing = getWindowIndexByName(name);
        local index = existing or ensureWindow(name);
        if (index and not existing) then
            addChannelToWindow(index, "Trade");
        end
        if (index and index ~= MAIN_CHAT_FRAME and windowHasChannel(index, "Trade") and windowHasChannel(MAIN_CHAT_FRAME, "Trade")) then
            removeChannelFromWindow(MAIN_CHAT_FRAME, "Trade");
        end
    end
    if (servicesMode == MODE_MOVE) then
        local name = normalizeTabName("Services", servicesTabName);
        local existing = getWindowIndexByName(name);
        local index = existing or ensureWindow(name);
        if (index and not existing) then
            addChannelToWindow(index, "Services");
        end
        if (index and index ~= MAIN_CHAT_FRAME and windowHasChannel(index, "Services") and windowHasChannel(MAIN_CHAT_FRAME, "Services")) then
            removeChannelFromWindow(MAIN_CHAT_FRAME, "Services");
        end
    end
end

function ChatQoL:ApplyChannelSettingsNow()
    local tradeMove = self.db.tradeMode == MODE_MOVE;
    local servicesMove = self.db.servicesMode == MODE_MOVE;
    if (not tradeMove and not servicesMove) then
        Lantern:Print("Chat QoL: no channel tabs configured.");
        return;
    end
    Lantern:Print("Chat QoL: creating channel tabs...");
    self:HandleChatChannels();
    Lantern:Print("Chat QoL: channel tabs ready.");
end

function ChatQoL:ScheduleChannelCheck()
    if (self._channelCheckPending) then return; end
    self._channelCheckPending = true;
    if (C_Timer and C_Timer.After) then
        C_Timer.After(CHANNEL_REFRESH_DELAY, function()
            self._channelCheckPending = nil;
            self:HandleChatChannels();
        end);
    else
        self._channelCheckPending = nil;
            self:HandleChatChannels();
    end
end

function ChatQoL:OnInit()
    ensureDB(self);
    self._channelCheckPending = nil;
    self:AttachEditBoxHandlers();
end

function ChatQoL:OnEnable()
    ensureDB(self);
    self:AttachEditBoxHandlers();
    for _, ev in ipairs(MONITORED_CHAT_EVENTS) do
        self.addon:ModuleRegisterEvent(self, ev, function(_, _, msg, author)
            captureMessage(_, msg, author);
        end);
    end
    self:ScheduleChannelCheck();
    self.addon:ModuleRegisterEvent(self, "CHANNEL_UI_UPDATE", function()
        self:ScheduleChannelCheck();
    end);
    self.addon:ModuleRegisterEvent(self, "PLAYER_ENTERING_WORLD", function()
        self:ScheduleChannelCheck();
    end);
end

function ChatQoL:OnDisable()
    self._channelCheckPending = nil;
end

Lantern:RegisterModule(ChatQoL);
