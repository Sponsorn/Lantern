local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local LanternUX = _G.LanternUX;
local T = LanternUX and LanternUX.Theme;
if (not T) then return; end

local module = Lantern.modules["ChatFilter"];
if (not module) then return; end

local function moduleEnabled(name)
    local m = Lantern.modules and Lantern.modules[name];
    return m and m.enabled;
end

local function moduleToggle(name, label, desc)
    return {
        type = "toggle",
        label = label or "Enable",
        desc = desc,
        get = function() return moduleEnabled(name); end,
        set = function(val)
            if (val) then
                Lantern:EnableModule(name);
            else
                Lantern:DisableModule(name);
            end
        end,
    };
end

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

    local function refreshPage()
        local panel = Lantern._uxPanel;
        if (panel and panel.RefreshCurrentPage) then
            panel:RefreshCurrentPage();
        end
    end

    local function getModule()
        return Lantern.modules and Lantern.modules.ChatFilter;
    end

    Lantern._chatFilterInput = Lantern._chatFilterInput or "";

    local widgets = {};

    -- Enable
    table.insert(widgets, moduleToggle("ChatFilter", "Enable", "Enable or disable the Chat Filter."));
    table.insert(widgets, {
        type = "toggle",
        label = "Login message",
        desc = "Show a chat message on login confirming the filter is active.",
        disabled = isDisabled,
        get = function() return db().loginMessage; end,
        set = function(val) db().loginMessage = val and true or false; end,
    });

    ---------------------------------------------------------------------------
    -- Add keyword
    ---------------------------------------------------------------------------
    table.insert(widgets, {
        type = "input",
        label = "Add keyword",
        desc = "Enter a word or phrase to filter. Matching is case-insensitive.",
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
                    Lantern:Print("Keyword already in filter list.");
                    Lantern._chatFilterInput = "";
                    refreshPage();
                    return;
                end
            end
            d.keywords[val] = true;
            Lantern:Print("Added \"" .. val .. "\" to chat filter.");
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
            text = "No keywords configured.",
            fontSize = "small",
            color = T.textDim,
        });
    else
        for _, keyword in ipairs(sortedKeywords) do
            table.insert(keywordChildren, {
                type = "label_action",
                text = keyword,
                buttonLabel = "Remove",
                desc = "Remove \"" .. keyword .. "\" from the filter list.",
                confirm = "Remove?",
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
        text = "Keywords (" .. #sortedKeywords .. ")",
        stateKey = "chatFilterKeywords",
        children = keywordChildren,
    });

    table.insert(widgets, { type = "divider" });

    ---------------------------------------------------------------------------
    -- Restore defaults
    ---------------------------------------------------------------------------
    table.insert(widgets, {
        type = "execute",
        label = "Restore default keywords",
        desc = "Reset the keyword list to the built-in defaults. This replaces all custom keywords.",
        confirm = "Restore?",
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
