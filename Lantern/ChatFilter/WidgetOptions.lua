local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local LanternUX = _G.LanternUX;
local T = LanternUX and LanternUX.Theme;
if (not T) then return; end

local module = Lantern.modules["ChatFilter"];
if (not module) then return; end
local L = Lantern.L;

local moduleEnabled = Lantern.moduleEnabled;
local moduleToggle = Lantern.moduleToggle;

module.widgetOptions = function()
    local function db()
        Lantern.db.chatFilter = Lantern.db.chatFilter or {};
        if (type(Lantern.db.chatFilter.keywords) ~= "table") then
            Lantern.db.chatFilter.keywords = {};
        end
        return Lantern.db.chatFilter;
    end

    local isDisabled = function()
        return not moduleEnabled("ChatFilter");
    end

    local refreshPage = Lantern.refreshPage;

    local function getModule()
        return Lantern.modules and Lantern.modules.ChatFilter;
    end

    Lantern._chatFilterInput = Lantern._chatFilterInput or "";

    local widgets = {};

    -- Enable
    table.insert(widgets, moduleToggle("ChatFilter", L["ENABLE"], L["CHATFILTER_ENABLE_DESC"]));
    table.insert(widgets, {
        type = "toggle",
        label = L["CHATFILTER_LOGIN_MESSAGE"],
        desc = L["CHATFILTER_LOGIN_MESSAGE_DESC"],
        disabled = isDisabled,
        get = function() return db().loginMessage; end,
        set = function(val) db().loginMessage = val and true or false; end,
    });

    ---------------------------------------------------------------------------
    -- Add keyword
    ---------------------------------------------------------------------------
    table.insert(widgets, {
        type = "input",
        label = L["CHATFILTER_ADD_KEYWORD"],
        desc = L["CHATFILTER_ADD_KEYWORD_DESC"],
        disabled = isDisabled,
        get = function() return Lantern._chatFilterInput or ""; end,
        set = function(val)
            if (not val or val:match("^%s*$")) then return; end
            val = val:match("^%s*(.-)%s*$"); -- trim
            if (val == "") then return; end
            local d = db();
            local lowerVal = val:lower();
            -- Check for duplicates (case-insensitive)
            for existing in pairs(d.keywords) do
                if (existing:lower() == lowerVal) then
                    Lantern:Print(L["CHATFILTER_MSG_KEYWORD_EXISTS"]);
                    Lantern._chatFilterInput = "";
                    refreshPage();
                    return;
                end
            end
            d.keywords[val] = true;
            Lantern:Print(format(L["CHATFILTER_MSG_KEYWORD_ADDED"], val));
            Lantern._chatFilterInput = "";
            refreshPage();
        end,
    });

    ---------------------------------------------------------------------------
    -- Keyword list
    ---------------------------------------------------------------------------
    local d = db();
    local sortedKeywords = {};
    for keyword, active in pairs(d.keywords) do
        if (active) then
            table.insert(sortedKeywords, keyword);
        end
    end
    table.sort(sortedKeywords, function(a, b)
        return a:lower() < b:lower();
    end);

    local keywordChildren = {};

    if (#sortedKeywords == 0) then
        table.insert(keywordChildren, {
            type = "description",
            text = L["CHATFILTER_NO_KEYWORDS"],
            fontSize = "small",
            color = T.textDim,
        });
    else
        for _, keyword in ipairs(sortedKeywords) do
            table.insert(keywordChildren, {
                type = "label_action",
                text = keyword,
                buttonLabel = L["SHARED_REMOVE"],
                desc = format(L["CHATFILTER_REMOVE_KEYWORD_DESC"], keyword),
                confirm = L["SHARED_REMOVE_CONFIRM"],
                disabled = isDisabled,
                func = function()
                    db().keywords[keyword] = nil;
                    refreshPage();
                end,
            });
        end
    end

    table.insert(widgets, {
        type = "group",
        text = format(L["CHATFILTER_KEYWORDS_GROUP"], #sortedKeywords),
        stateKey = "chatFilterKeywords",
        children = keywordChildren,
    });

    ---------------------------------------------------------------------------
    -- Restore defaults
    ---------------------------------------------------------------------------
    table.insert(widgets, {
        type = "execute",
        label = L["CHATFILTER_RESTORE_DEFAULTS"],
        desc = L["CHATFILTER_RESTORE_DEFAULTS_DESC"],
        confirm = L["CHATFILTER_RESTORE_CONFIRM"],
        disabled = isDisabled,
        func = function()
            local mod = getModule();
            if (mod and mod.RestoreDefaults) then
                mod:RestoreDefaults();
            end
            refreshPage();
        end,
    });

    return widgets;
end
