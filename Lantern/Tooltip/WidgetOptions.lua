local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local LanternUX = _G.LanternUX;
local T = LanternUX and LanternUX.Theme;
if (not T) then return; end

local module = Lantern.modules["Tooltip"];
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
    local function tdb()
        if (not Lantern.db) then Lantern.db = {}; end
        if (not Lantern.db.tooltip) then Lantern.db.tooltip = {}; end
        return Lantern.db.tooltip;
    end

    local isDisabled = function()
        return not moduleEnabled("Tooltip");
    end

    return {
        moduleToggle("Tooltip", "Enable", "Enhance tooltips with extra information."),
        {
            type = "group",
            text = "Player",
            expanded = true,
            children = {
                {
                    type = "toggle",
                    label = "Mount name",
                    desc = "Show what mount a player is currently riding.",
                    disabled = isDisabled,
                    get = function() return tdb().showMount ~= false; end,
                    set = function(val) tdb().showMount = val; end,
                },
            },
        },
        {
            type = "group",
            text = "Items",
            expanded = true,
            children = {
                {
                    type = "toggle",
                    label = "Item ID",
                    desc = "Show the item ID on item tooltips.",
                    disabled = isDisabled,
                    get = function() return tdb().showItemID ~= false; end,
                    set = function(val) tdb().showItemID = val; end,
                },
                {
                    type = "toggle",
                    label = "Item spell ID",
                    desc = "Show the use-effect spell ID on consumables and other items with on-use abilities.",
                    disabled = isDisabled,
                    get = function() return tdb().showItemSpellID ~= false; end,
                    set = function(val) tdb().showItemSpellID = val; end,
                },
            },
        },
        {
            type = "group",
            text = "Spells",
            children = {
                {
                    type = "toggle",
                    label = "Spell ID",
                    desc = "Show the spell ID on spell, aura, and talent tooltips.",
                    disabled = isDisabled,
                    get = function() return tdb().showSpellID ~= false; end,
                    set = function(val) tdb().showSpellID = val; end,
                },
                {
                    type = "toggle",
                    label = "Node ID",
                    desc = "Show the talent tree node ID on talent tooltips.",
                    disabled = isDisabled,
                    get = function() return tdb().showNodeID ~= false; end,
                    set = function(val) tdb().showNodeID = val; end,
                },
            },
        },
        {
            type = "group",
            text = "Copy",
            children = {
                {
                    type = "toggle",
                    label = "Ctrl+C to copy",
                    desc = "Press Ctrl+C to copy the primary ID, or Ctrl+Shift+C to copy the secondary ID (e.g. an item's use-effect SpellID).",
                    disabled = isDisabled,
                    get = function() return tdb().copyOnCtrlC ~= false; end,
                    set = function(val) tdb().copyOnCtrlC = val; end,
                },
            },
        },
    };
end
