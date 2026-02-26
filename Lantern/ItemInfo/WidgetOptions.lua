local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local LanternUX = _G.LanternUX;
local T = LanternUX and LanternUX.Theme;
if (not T) then return; end

local module = Lantern.modules["ItemInfo"];
if (not module) then return; end
local L = Lantern.L;

local moduleEnabled = Lantern.moduleEnabled;
local moduleToggle = Lantern.moduleToggle;

module.widgetOptions = function()
    local function db()
        Lantern.db.itemInfo = Lantern.db.itemInfo or {};
        return Lantern.db.itemInfo;
    end

    local isDisabled = function()
        return not moduleEnabled("ItemInfo");
    end

    local widgets = {};

    table.insert(widgets, moduleToggle("ItemInfo", L["ENABLE"], L["ITEMINFO_ENABLE_DESC"]));

    table.insert(widgets, {
        type = "toggle",
        label = L["ITEMINFO_SHOW_ILVL_CHARACTER"],
        desc = L["ITEMINFO_SHOW_ILVL_CHARACTER_DESC"],
        disabled = isDisabled,
        get = function() return db().showIlvlCharacter ~= false; end,
        set = function(val) db().showIlvlCharacter = val and true or false; end,
    });

    table.insert(widgets, {
        type = "toggle",
        label = L["ITEMINFO_SHOW_ILVL_BAGS"],
        desc = L["ITEMINFO_SHOW_ILVL_BAGS_DESC"],
        disabled = isDisabled,
        get = function() return db().showIlvlBags ~= false; end,
        set = function(val) db().showIlvlBags = val and true or false; end,
    });

    table.insert(widgets, {
        type = "toggle",
        label = L["ITEMINFO_UPGRADE_ARROW"],
        desc = L["ITEMINFO_UPGRADE_ARROW_DESC"],
        disabled = isDisabled,
        get = function() return db().showUpgradeArrow ~= false; end,
        set = function(val) db().showUpgradeArrow = val and true or false; end,
    });

    table.insert(widgets, {
        type = "toggle",
        label = L["ITEMINFO_SHOW_MISSING_ENCHANTS"],
        desc = L["ITEMINFO_SHOW_MISSING_ENCHANTS_DESC"],
        disabled = isDisabled,
        get = function() return db().showMissingEnchants ~= false; end,
        set = function(val) db().showMissingEnchants = val and true or false; end,
    });

    table.insert(widgets, {
        type = "toggle",
        label = L["ITEMINFO_SHOW_MISSING_GEMS"],
        desc = L["ITEMINFO_SHOW_MISSING_GEMS_DESC"],
        disabled = isDisabled,
        get = function() return db().showMissingGems ~= false; end,
        set = function(val) db().showMissingGems = val and true or false; end,
    });

    return widgets;
end
