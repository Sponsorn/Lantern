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
    aggregateGuildAchievements = false,
    guildAchievementWindow = 1.5,
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

local function getChannelInfo(channelName)
    if (not GetChannelName) then return; end
    local id, name = GetChannelName(channelName);
    if (type(id) == "number" and id > 0) then
        return id, name;
    end
    if (GetChannelList and type(channelName) == "string") then
        local list = { GetChannelList() };
        local stride = (type(list[3]) == "number") and 3 or 2;
        local needle = channelName:lower();
        for i = 1, #list, stride do
            local channelId = list[i];
            local channelNameFull = list[i + 1];
            if (type(channelNameFull) == "string") then
                local lower = channelNameFull:lower();
                if (lower:find(needle, 1, true)) then
                    return channelId, channelNameFull;
                end
                local kind = isTradeServicesChannel(channelNameFull);
                if (kind == channelName) then
                    return channelId, channelNameFull;
                end
            end
        end
    end
end

local function addChannelToWindow(index, channelName)
    if (not index or not channelName) then return; end
    local channelId, channelFullName = getChannelInfo(channelName);
    if (AddChatWindowChannel) then
        AddChatWindowChannel(index, channelId or channelFullName or channelName);
    end
    if (C_ChatInfo and C_ChatInfo.AddChatWindowChannel) then
        C_ChatInfo.AddChatWindowChannel(index, channelFullName or channelName);
    end
end

local function windowHasChannel(index, channelName)
    local channelId, channelFullName = getChannelInfo(channelName);
    local channels = { GetChatWindowChannels(index) };
    for i = 1, #channels, 2 do
        local name = channels[i];
        local id = channels[i + 1];
        if (name == channelName or name == channelFullName or id == channelId) then
            return true;
        end
    end
end

local function removeChannelFromWindow(index, channelName)
    local frame = _G["ChatFrame" .. index];
    if (not frame or not channelName) then return; end
    local _, channelFullName = getChannelInfo(channelName);
    local targetName = channelFullName or channelName;
    if (ChatFrame_RemoveChannel) then
        ChatFrame_RemoveChannel(frame, targetName);
        return;
    end
    if (C_ChatInfo and C_ChatInfo.RemoveChatWindowChannel and frame.GetID) then
        C_ChatInfo.RemoveChatWindowChannel(frame:GetID(), targetName);
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

local function extractAchievementLinks(message)
    local links = {};
    if (type(message) ~= "string") then return links; end
    local seen = {};
    local function addLink(link)
        if (link and not seen[link]) then
            seen[link] = true;
            links[#links + 1] = link;
        end
    end
    for link in message:gmatch("|c%x%x%x%x%x%x%x%x|Hachievement:[^|]+|h%[[^%]]+%]|h|r") do
        addLink(link);
    end
    for link in message:gmatch("|Hachievement:[^|]+|h%[[^%]]+%]|h") do
        addLink(link);
    end
    for link in message:gmatch("|c%x%x%x%x%x%x%x%x|HguildAchievement:[^|]+|h%[[^%]]+%]|h|r") do
        addLink(link);
    end
    for link in message:gmatch("|HguildAchievement:[^|]+|h%[[^%]]+%]|h") do
        addLink(link);
    end
    return links;
end

local function normalizeAchievementSender(sender, message)
    if (type(sender) == "string" and sender ~= "") then
        return sender;
    end
    if (type(message) ~= "string") then return; end
    local fromLink = message:match("|Hplayer:([^:|]+)") or message:match("|Hplayer:([^|]+)");
    if (fromLink and fromLink ~= "") then
        return fromLink;
    end
    local fromText = message:match("^([^%s]+)%s+has earned the achievement")
        or message:match("^([^%s]+)%s+earned the achievement")
        or message:match("^([^%s]+)%s+has earned the guild achievement")
        or message:match("^([^%s]+)%s+earned the guild achievement");
    if (fromText and fromText ~= "") then
        return fromText;
    end
end

function ChatQoL:QueueGuildAchievement(message, sender)
    sender = normalizeAchievementSender(sender, message);
    if (type(sender) ~= "string" or sender == "") then
        return false;
    end
    self._guildAchievementQueue = self._guildAchievementQueue or {};
    local bucket = self._guildAchievementQueue[sender];
    if (not bucket) then
        bucket = { achievements = {}, raw = {} };
        self._guildAchievementQueue[sender] = bucket;
    end
    local links = extractAchievementLinks(message);
    if (#links > 0) then
        for i = 1, #links do
            bucket.achievements[#bucket.achievements + 1] = links[i];
        end
    else
        bucket.raw[#bucket.raw + 1] = message;
    end
    if (not self._guildAchievementTimerPending) then
        self._guildAchievementTimerPending = true;
        local delay = tonumber(self.db and self.db.guildAchievementWindow) or 1.5;
        if (C_Timer and C_Timer.After and delay > 0) then
            C_Timer.After(delay, function()
                self._guildAchievementTimerPending = nil;
                self:FlushGuildAchievements();
            end);
        else
            self._guildAchievementTimerPending = nil;
            self:FlushGuildAchievements();
        end
    end
    return true;
end

function ChatQoL:FlushGuildAchievements()
    local queue = self._guildAchievementQueue;
    if (not queue) then return; end
    self._guildAchievementQueue = nil;
    local frame = _G.DEFAULT_CHAT_FRAME or _G.ChatFrame1;
    if (not frame or not frame.AddMessage) then return; end
    local info = ChatTypeInfo and ChatTypeInfo["GUILD_ACHIEVEMENT"];
    local r = info and info.r or 0.25;
    local g = info and info.g or 1.0;
    local b = info and info.b or 0.25;
    for sender, bucket in pairs(queue) do
        local achievements = bucket.achievements;
        local raw = bucket.raw;
        if (achievements and #achievements > 1) then
            local text = sender .. " earned achievements: " .. table.concat(achievements, ", ");
            frame:AddMessage(text, r, g, b);
        else
            if (achievements and #achievements == 1) then
                local text = sender .. " has earned the achievement " .. achievements[1] .. "!";
                frame:AddMessage(text, r, g, b);
            end
            if (raw) then
                for i = 1, #raw do
                    frame:AddMessage(raw[i], r, g, b);
                end
            end
        end
    end
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
                aggregateGuildAchievements = {
                    order = 2,
                    type = "toggle",
                    name = "Aggregate guild achievements",
                    width = "full",
                    get = function() return self.db.aggregateGuildAchievements; end,
                    set = function(_, value)
                        self.db.aggregateGuildAchievements = value and true or false;
                        self:RefreshGuildAchievementFilter();
                    end,
                },
                aggregateGuildAchievementsInfo = {
                    order = 2.1,
                    type = "description",
                    name = "Combine multiple guild achievement messages from the same player into one line when they occur close together.",
                    fontSize = "small",
                },
                guildAchievementWindow = {
                    order = 3,
                    type = "range",
                    name = "Guild achievement merge window",
                    min = 0.2,
                    max = 3.0,
                    step = 0.1,
                    get = function() return self.db.guildAchievementWindow; end,
                    set = function(_, value)
                        self.db.guildAchievementWindow = value;
                    end,
                    disabled = function() return not self.db.aggregateGuildAchievements; end,
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
        if (index and not windowHasChannel(index, "Trade")) then
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
        if (index and not windowHasChannel(index, "Services")) then
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

function ChatQoL:RefreshGuildAchievementFilter()
    if (not ChatFrame_AddMessageEventFilter or not ChatFrame_RemoveMessageEventFilter) then return; end
    if (self.db and self.db.aggregateGuildAchievements) then
        if (not self._guildAchievementFilter) then
            self._guildAchievementFilter = function(_, _, msg, sender, ...)
                return ChatQoL:QueueGuildAchievement(msg, sender);
            end;
        end
        ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD_ACHIEVEMENT", self._guildAchievementFilter);
    elseif (self._guildAchievementFilter) then
        ChatFrame_RemoveMessageEventFilter("CHAT_MSG_GUILD_ACHIEVEMENT", self._guildAchievementFilter);
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
    self:RefreshGuildAchievementFilter();
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
    if (self._guildAchievementFilter and ChatFrame_RemoveMessageEventFilter) then
        ChatFrame_RemoveMessageEventFilter("CHAT_MSG_GUILD_ACHIEVEMENT", self._guildAchievementFilter);
    end
    self._guildAchievementQueue = nil;
    self._guildAchievementTimerPending = nil;
end

Lantern:RegisterModule(ChatQoL);
