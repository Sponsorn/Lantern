local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local LanternUX = _G.LanternUX;
local T = LanternUX and LanternUX.Theme;
if (not T) then return; end

local module = Lantern.modules["Tooltip"];
if (not module) then return; end
local L = Lantern.L;

local moduleEnabled = Lantern.moduleEnabled;
local moduleToggle = Lantern.moduleToggle;

module.widgetOptions = function()
    local function tdb()
        if (not Lantern.db) then Lantern.db = {}; end
        if (not Lantern.db.tooltip) then Lantern.db.tooltip = {}; end
        return Lantern.db.tooltip;
    end

    local isDisabled = function()
        return not moduleEnabled("Tooltip");
    end

    return {
        moduleToggle("Tooltip", L["ENABLE"], L["TOOLTIP_ENABLE_DESC"]),
        {
            type = "callout",
            text = L["TOOLTIP_COMBAT_NOTE"],
            severity = "info",
        },
        {
            type = "group",
            text = L["TOOLTIP_GROUP_PLAYER"],
            expanded = true,
            children = {
                {
                    type = "toggle",
                    label = L["TOOLTIP_MOUNT_NAME"],
                    desc = L["TOOLTIP_MOUNT_NAME_DESC"],
                    disabled = isDisabled,
                    get = function() return tdb().showMount ~= false; end,
                    set = function(val) tdb().showMount = val; end,
                },
            },
        },
        {
            type = "group",
            text = L["TOOLTIP_GROUP_ITEMS"],
            expanded = true,
            children = {
                {
                    type = "toggle",
                    label = L["TOOLTIP_ITEM_ID"],
                    desc = L["TOOLTIP_ITEM_ID_DESC"],
                    disabled = isDisabled,
                    get = function() return tdb().showItemID ~= false; end,
                    set = function(val) tdb().showItemID = val; end,
                },
                {
                    type = "toggle",
                    label = L["TOOLTIP_ITEM_SPELL_ID"],
                    desc = L["TOOLTIP_ITEM_SPELL_ID_DESC"],
                    disabled = isDisabled,
                    get = function() return tdb().showItemSpellID ~= false; end,
                    set = function(val) tdb().showItemSpellID = val; end,
                },
            },
        },
        {
            type = "group",
            text = L["TOOLTIP_GROUP_SPELLS"],
            children = {
                {
                    type = "toggle",
                    label = L["TOOLTIP_SPELL_ID"],
                    desc = L["TOOLTIP_SPELL_ID_DESC"],
                    disabled = isDisabled,
                    get = function() return tdb().showSpellID ~= false; end,
                    set = function(val) tdb().showSpellID = val; end,
                },
                {
                    type = "toggle",
                    label = L["TOOLTIP_NODE_ID"],
                    desc = L["TOOLTIP_NODE_ID_DESC"],
                    disabled = isDisabled,
                    get = function() return tdb().showNodeID ~= false; end,
                    set = function(val) tdb().showNodeID = val; end,
                },
            },
        },
        {
            type = "group",
            text = L["TOOLTIP_GROUP_COPY"],
            children = {
                {
                    type = "toggle",
                    label = L["TOOLTIP_CTRL_C"],
                    desc = L["TOOLTIP_CTRL_C_DESC"],
                    disabled = isDisabled,
                    get = function() return tdb().copyOnCtrlC ~= false; end,
                    set = function(val) tdb().copyOnCtrlC = val; end,
                },
            },
        },
    };
end
