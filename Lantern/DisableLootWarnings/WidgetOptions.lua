local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local LanternUX = _G.LanternUX;
local T = LanternUX and LanternUX.Theme;
if (not T) then return; end

local module = Lantern.modules["DisableLootWarnings"];
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
        if (not Lantern.db.disableLootWarnings) then Lantern.db.disableLootWarnings = {}; end
        local d = Lantern.db.disableLootWarnings;
        local defaults = { lootRoll = true, bindOnPickup = true, merchantRefund = true, mailLock = true };
        for k, v in pairs(defaults) do
            if (d[k] == nil) then d[k] = v; end
        end
        return d;
    end

    local isDisabled = function()
        return not moduleEnabled("DisableLootWarnings");
    end

    return {
        moduleToggle("DisableLootWarnings", "Enable", "Auto-confirm loot and trade popups. Hold " .. Lantern:GetModifierName() .. " to see popups normally."),
        {
            type = "group",
            text = "Popup Types",
            expanded = true,
            children = {
                {
                    type = "toggle",
                    label = "Loot Roll (BoP)",
                    desc = "Auto-confirm bind-on-pickup loot rolls (Need/Greed on soulbound items).",
                    disabled = isDisabled,
                    get = function() return db().lootRoll; end,
                    set = function(val) db().lootRoll = val; end,
                },
                {
                    type = "toggle",
                    label = "Bind on Pickup",
                    desc = "Auto-confirm bind-on-pickup warnings when looting items.",
                    disabled = isDisabled,
                    get = function() return db().bindOnPickup; end,
                    set = function(val) db().bindOnPickup = val; end,
                },
                {
                    type = "toggle",
                    label = "Merchant Refund",
                    desc = "Auto-confirm merchant refund timer removal warnings.",
                    disabled = isDisabled,
                    get = function() return db().merchantRefund; end,
                    set = function(val) db().merchantRefund = val; end,
                },
                {
                    type = "toggle",
                    label = "Mail Lock Send",
                    desc = "Auto-confirm mail item lock warnings when sending items.",
                    disabled = isDisabled,
                    get = function() return db().mailLock; end,
                    set = function(val) db().mailLock = val; end,
                },
            },
        },
        {
            type = "callout",
            text = "Note: changes to popup types take effect after reloading the UI.",
            severity = "notice",
        },
    };
end
