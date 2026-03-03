local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local LanternUX = _G.LanternUX;
local T = LanternUX and LanternUX.Theme;
if (not T) then return; end

local module = Lantern.modules["MapPins"];
if (not module) then return; end
local L = Lantern.L;

local moduleEnabled = Lantern.moduleEnabled;
local moduleToggle = Lantern.moduleToggle;

module.widgetOptions = function()
    local Data = Lantern._mapPinsData;

    local function mpDB()
        if (not Lantern.db) then Lantern.db = {}; end
        Lantern.db.mapPins = Lantern.db.mapPins or {};
        local d = Lantern.db.mapPins;
        if (d.pinSize == nil) then d.pinSize = 24; end
        if (d.showLabels == nil) then d.showLabels = true; end
        if (d.showOnMinimap == nil) then d.showOnMinimap = true; end
        if (type(d.categories) ~= "table") then d.categories = {}; end
        return d;
    end

    local function isDisabled()
        return not moduleEnabled("MapPins");
    end

    local function refresh()
        if (module.RefreshPins) then module.RefreshPins(); end
    end

    local widgets = {};

    -- Module toggle
    table.insert(widgets, moduleToggle("MapPins", L["ENABLE"], L["MAPPINS_ENABLE_DESC"]));

    -- Show on Minimap
    table.insert(widgets, {
        type = "toggle",
        label = L["MAPPINS_SHOW_MINIMAP"],
        desc = L["MAPPINS_SHOW_MINIMAP_DESC"],
        disabled = isDisabled,
        get = function() return mpDB().showOnMinimap; end,
        set = function(val)
            mpDB().showOnMinimap = val;
            refresh();
        end,
    });

    -- Pin Size
    table.insert(widgets, {
        type = "range",
        label = L["MAPPINS_PIN_SIZE"],
        desc = L["MAPPINS_PIN_SIZE_DESC"],
        min = 16,
        max = 48,
        step = 4,
        default = 24,
        disabled = isDisabled,
        get = function() return mpDB().pinSize or 24; end,
        set = function(val)
            mpDB().pinSize = val;
            refresh();
        end,
    });

    -- Show Labels
    table.insert(widgets, {
        type = "toggle",
        label = L["MAPPINS_SHOW_LABELS"],
        desc = L["MAPPINS_SHOW_LABELS_DESC"],
        disabled = isDisabled,
        get = function() return mpDB().showLabels; end,
        set = function(val)
            mpDB().showLabels = val;
            refresh();
        end,
    });

    -- Categories group
    if (Data and Data.CATEGORIES) then
        local catChildren = {};
        for catKey, catDef in pairs(Data.CATEGORIES) do
            local catLabel = L[catDef.label] or catKey;
            local catDescKey = catDef.label .. "_DESC";
            local catDesc = L[catDescKey] or "";
            table.insert(catChildren, {
                type = "toggle",
                label = catLabel,
                desc = catDesc,
                disabled = isDisabled,
                get = function()
                    local d = mpDB();
                    if (d.categories[catKey] ~= nil) then
                        return d.categories[catKey];
                    end
                    return catDef.defaultEnabled;
                end,
                set = function(val)
                    mpDB().categories[catKey] = val;
                    refresh();
                end,
            });
        end

        table.insert(widgets, {
            type = "group",
            text = L["MAPPINS_GROUP_CATEGORIES"],
            expanded = true,
            stateKey = "mapPinsCategories",
            children = catChildren,
        });
    end

    return widgets;
end
