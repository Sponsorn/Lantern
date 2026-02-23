local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local LanternUX = _G.LanternUX;
local T = LanternUX and LanternUX.Theme;
if (not T) then return; end

local module = Lantern.modules["DisableLootWarnings"];
if (not module) then return; end
local L = Lantern.L;

local function moduleEnabled(name)
    local m = Lantern.modules and Lantern.modules[name];
    return m and m.enabled;
end

local function moduleToggle(name, label, desc)
    return {
        type = "toggle",
        label = label or L["ENABLE"],
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
        moduleToggle("DisableLootWarnings", L["ENABLE"], format(L["LOOTWARNINGS_ENABLE_DESC"], Lantern:GetModifierName())),
        {
            type = "group",
            text = L["LOOTWARNINGS_GROUP_TYPES"],
            expanded = true,
            children = {
                {
                    type = "toggle",
                    label = L["LOOTWARNINGS_LOOT_ROLL"],
                    desc = L["LOOTWARNINGS_LOOT_ROLL_DESC"],
                    disabled = isDisabled,
                    get = function() return db().lootRoll; end,
                    set = function(val) db().lootRoll = val; end,
                },
                {
                    type = "toggle",
                    label = L["LOOTWARNINGS_BIND_ON_PICKUP"],
                    desc = L["LOOTWARNINGS_BIND_ON_PICKUP_DESC"],
                    disabled = isDisabled,
                    get = function() return db().bindOnPickup; end,
                    set = function(val) db().bindOnPickup = val; end,
                },
                {
                    type = "toggle",
                    label = L["LOOTWARNINGS_MERCHANT_REFUND"],
                    desc = L["LOOTWARNINGS_MERCHANT_REFUND_DESC"],
                    disabled = isDisabled,
                    get = function() return db().merchantRefund; end,
                    set = function(val) db().merchantRefund = val; end,
                },
                {
                    type = "toggle",
                    label = L["LOOTWARNINGS_MAIL_LOCK"],
                    desc = L["LOOTWARNINGS_MAIL_LOCK_DESC"],
                    disabled = isDisabled,
                    get = function() return db().mailLock; end,
                    set = function(val) db().mailLock = val; end,
                },
            },
        },
    };
end
