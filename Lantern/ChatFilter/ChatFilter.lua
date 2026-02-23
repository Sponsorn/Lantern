local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end
local L = Lantern.L;

local module = Lantern:NewModule("ChatFilter", {
    title = L["CHATFILTER_TITLE"],
    desc = L["CHATFILTER_DESC"],
});

local FILTERED_EVENTS = {
    "CHAT_MSG_WHISPER",
    "CHAT_MSG_CHANNEL",
};

local DEFAULT_KEYWORDS = {
    -- Gold selling
    "wts gold", "buy gold", "cheap gold", "gold discount", "gold delivery",
    -- Boost / carry
    "wts boost", "wts carry", "wts run", "boost cheap", "carry cheap",
    "piloted", "selfplay", "account sharing", "powerleveling",
    "pay in raid", "wts",
};

local function ensureDB(self)
    if (not self.addon.db) then return; end
    if (not self.addon.db.chatFilter) then
        self.addon.db.chatFilter = {};
    end
    self.db = self.addon.db.chatFilter;

    if (type(self.db.keywords) ~= "table") then
        self.db.keywords = {};
        for _, kw in ipairs(DEFAULT_KEYWORDS) do
            self.db.keywords[kw] = true;
        end
    end

    if (self.db.loginMessage == nil) then
        self.db.loginMessage = true;
    end
end

function module:OnInit()
    ensureDB(self);
end

function module:OnEnable()
    ensureDB(self);
    self:RegisterChatFilters();

    if (self.db.loginMessage) then
        local count = 0;
        for _, active in pairs(self.db.keywords) do
            if (active) then count = count + 1; end
        end
        Lantern:Print(format(L["CHATFILTER_MSG_ACTIVE"], count));
    end
end

function module:OnDisable()
    self:UnregisterChatFilters();
end

function module:RegisterChatFilters()
    if (self._chatFilter) then return; end

    self._chatFilter = function(chatFrame, event, msg, ...)
        if (self:FilterMessage(msg)) then
            return true;
        end
        return false, msg, ...;
    end

    for _, event in ipairs(FILTERED_EVENTS) do
        ChatFrame_AddMessageEventFilter(event, self._chatFilter);
    end
end

function module:UnregisterChatFilters()
    if (not self._chatFilter) then return; end
    for _, event in ipairs(FILTERED_EVENTS) do
        ChatFrame_RemoveMessageEventFilter(event, self._chatFilter);
    end
    self._chatFilter = nil;
end

function module:FilterMessage(msg)
    if (not msg or not self.enabled) then return false; end

    local lowerMsg = msg:lower();
    local keywords = self.db and self.db.keywords;
    if (not keywords) then return false; end

    for keyword, active in pairs(keywords) do
        if (active and lowerMsg:find(keyword:lower(), 1, true)) then
            return true;
        end
    end

    return false;
end

function module:GetDefaultKeywords()
    return DEFAULT_KEYWORDS;
end

function module:RestoreDefaults()
    if (not self.db) then return; end
    self.db.keywords = {};
    for _, kw in ipairs(DEFAULT_KEYWORDS) do
        self.db.keywords[kw] = true;
    end
end

Lantern:RegisterModule(module);
