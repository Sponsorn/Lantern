local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local LanternUX = _G.LanternUX;
local T = LanternUX and LanternUX.Theme;
if (not T) then return; end

local module = Lantern.modules["RangeCheck"];
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
        if (not Lantern.db) then Lantern.db = {}; end
        if (not Lantern.db.rangeCheck) then Lantern.db.rangeCheck = {}; end
        local d = Lantern.db.rangeCheck;
        local defaults = { combatOnly = false, fontSize = 16, locked = true, displayMode = "range", hideInRange = false };
        for k, v in pairs(defaults) do
            if (d[k] == nil) then d[k] = v; end
        end
        return d;
    end

    local isDisabled = function()
        return not moduleEnabled("RangeCheck");
    end

    local isStatusMode = function()
        return db().displayMode == "status";
    end

    local refreshPage = function()
        if (Lantern._uxPanel and Lantern._uxPanel.refreshPage) then
            Lantern._uxPanel:refreshPage();
        end
    end

    return {
        moduleToggle("RangeCheck", "Enable", "Show distance to your current target."),
        {
            type = "group",
            text = "Display",
            expanded = true,
            children = {
                {
                    type = "select",
                    label = "Display Mode",
                    desc = "Range: show distance numbers. Status: show In Range / Out of Range.",
                    disabled = isDisabled,
                    values = {
                        range = "Range (numbers)",
                        status = "Status (in/out)",
                    },
                    sorting = { "range", "status" },
                    get = function() return db().displayMode; end,
                    set = function(val)
                        db().displayMode = val;
                        refreshPage();
                    end,
                },
                {
                    type = "toggle",
                    label = "Hide When In Range",
                    desc = "Hide the display when your target is within range. Only shows when out of range.",
                    disabled = function() return isDisabled() or not isStatusMode(); end,
                    hidden = function() return not isStatusMode(); end,
                    get = function() return db().hideInRange; end,
                    set = function(val) db().hideInRange = val; end,
                },
                {
                    type = "toggle",
                    label = "Combat Only",
                    desc = "Only show range when in combat.",
                    disabled = isDisabled,
                    get = function() return db().combatOnly; end,
                    set = function(val) db().combatOnly = val; end,
                },
                {
                    type = "range",
                    label = "Font Size",
                    desc = "Size of the range text.",
                    min = 10, max = 36, step = 1,
                    disabled = isDisabled,
                    get = function() return db().fontSize; end,
                    set = function(val)
                        db().fontSize = val;
                        if (module.RefreshFont) then module:RefreshFont(); end
                    end,
                },
            },
        },
        {
            type = "group",
            text = "Position",
            children = {
                {
                    type = "toggle",
                    label = "Lock Position",
                    desc = "Prevent the range display from being moved.",
                    disabled = isDisabled,
                    get = function() return db().locked; end,
                    set = function(val)
                        db().locked = val;
                        if (module.UpdateLock) then module:UpdateLock(); end
                    end,
                },
                {
                    type = "execute",
                    label = "Reset Position",
                    desc = "Reset the range display to its default position.",
                    disabled = isDisabled,
                    func = function()
                        if (module.ResetPosition) then module:ResetPosition(); end
                    end,
                },
            },
        },
    };
end
