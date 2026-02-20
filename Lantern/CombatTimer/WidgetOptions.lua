local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local LanternUX = _G.LanternUX;
local T = LanternUX and LanternUX.Theme;
if (not T) then return; end

local module = Lantern.modules["CombatTimer"];
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
        if (not Lantern.db.combatTimer) then Lantern.db.combatTimer = {}; end
        local d = Lantern.db.combatTimer;
        local defaults = { fontSize = 18, stickyDuration = 5, locked = true };
        for k, v in pairs(defaults) do
            if (d[k] == nil) then d[k] = v; end
        end
        return d;
    end

    local isDisabled = function()
        return not moduleEnabled("CombatTimer");
    end

    return {
        moduleToggle("CombatTimer", "Enable", "Show a timer during combat."),
        {
            type = "group",
            text = "Display",
            expanded = true,
            children = {
                {
                    type = "range",
                    label = "Font Size",
                    desc = "Size of the timer text.",
                    min = 12, max = 48, step = 1,
                    disabled = isDisabled,
                    get = function() return db().fontSize; end,
                    set = function(val)
                        db().fontSize = val;
                        if (module.RefreshFont) then module:RefreshFont(); end
                    end,
                },
                {
                    type = "range",
                    label = "Sticky Duration",
                    desc = "Seconds to keep showing the final time after combat ends. Set to 0 to hide immediately.",
                    min = 0, max = 30, step = 1,
                    disabled = isDisabled,
                    get = function() return db().stickyDuration; end,
                    set = function(val) db().stickyDuration = val; end,
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
                    desc = "Prevent the timer from being moved.",
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
                    desc = "Reset the timer to its default position.",
                    disabled = isDisabled,
                    func = function()
                        if (module.ResetPosition) then module:ResetPosition(); end
                    end,
                },
            },
        },
    };
end
