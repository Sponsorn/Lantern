local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end
local L = Lantern.L;

local module = Lantern:NewModule("MapPins", {
    title = L["MAPPINS_TITLE"],
    desc = L["MAPPINS_DESC"],
    defaultEnabled = false,
});

local DEFAULTS = {
    pinSize = 24,
    showLabels = true,
    showOnMinimap = true,
    categories = {},
};

local HBD, HBDPins;
local Data;

-- Pin frame pools (keyed by "mapID:index")
local worldPinFrames = {};
local minimapPinFrames = {};

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function db()
    if (not Lantern.db) then return DEFAULTS; end
    Lantern.db.mapPins = Lantern.db.mapPins or {};
    local d = Lantern.db.mapPins;
    for k, v in pairs(DEFAULTS) do
        if (d[k] == nil) then
            if (type(v) == "table") then
                d[k] = {};
                for kk, vv in pairs(v) do d[k][kk] = vv; end
            else
                d[k] = v;
            end
        end
    end
    return d;
end

local function isCategoryEnabled(categoryKey)
    local d = db();
    local override = d.categories[categoryKey];
    if (override ~= nil) then
        return override;
    end
    -- Fall back to category default
    local catDef = Data and Data.CATEGORIES[categoryKey];
    return catDef and catDef.defaultEnabled or false;
end

-------------------------------------------------------------------------------
-- Pin frame creation
-------------------------------------------------------------------------------

local function CreatePinFrame(name, parent)
    local frame = CreateFrame("Frame", name, parent);
    frame:SetSize(24, 24);
    frame:SetFrameStrata("HIGH");
    frame:EnableMouse(true);

    local icon = frame:CreateTexture(name .. "_Icon", "ARTWORK");
    icon:SetPoint("CENTER");
    icon:SetSize(20, 20);
    frame.Icon = icon;

    local label = frame:CreateFontString(name .. "_Label", "OVERLAY", "GameFontNormalSmall");
    label:SetPoint("TOP", icon, "BOTTOM", 0, -2);
    label:SetJustifyH("CENTER");
    label:SetTextColor(1, 0.82, 0);
    frame.Label = label;

    frame:SetScript("OnEnter", function(self)
        if (not self._pinData) then return; end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        GameTooltip:SetText(self._pinData.name, 1, 1, 1);
        local catDef = Data and Data.CATEGORIES[self._pinData.category];
        if (catDef) then
            GameTooltip:AddLine(L[catDef.label] or self._pinData.category, 0.8, 0.8, 0.8);
        end
        GameTooltip:Show();
    end);

    frame:SetScript("OnLeave", function()
        GameTooltip:Hide();
    end);

    return frame;
end

local function ConfigurePinFrame(frame, pinData, pinSize, showLabels)
    frame._pinData = pinData;
    frame:SetSize(pinSize, pinSize);
    frame.Icon:SetSize(pinSize - 4, pinSize - 4);
    frame.Icon:SetAtlas(pinData.atlas or "worldquest-icon-alchemy");

    if (showLabels) then
        frame.Label:SetText(pinData.name);
        frame.Label:Show();
    else
        frame.Label:Hide();
    end
end

local function GetOrCreateWorldPin(key, parent)
    if (not worldPinFrames[key]) then
        worldPinFrames[key] = CreatePinFrame("LMP_W_" .. key, parent);
    end
    return worldPinFrames[key];
end

local function GetOrCreateMinimapPin(key, parent)
    if (not minimapPinFrames[key]) then
        minimapPinFrames[key] = CreatePinFrame("LMP_M_" .. key, parent);
    end
    return minimapPinFrames[key];
end

-------------------------------------------------------------------------------
-- Refresh logic
-------------------------------------------------------------------------------

local function RefreshWorldMapPins()
    if (not HBDPins or not module.enabled) then return; end

    HBDPins:RemoveAllWorldMapIcons(module);

    if (not WorldMapFrame or not WorldMapFrame:IsShown()) then return; end

    local mapID = WorldMapFrame:GetMapID();
    if (not mapID) then return; end

    local pins = Data:GetPinsForMap(mapID);
    if (not pins) then return; end

    local d = db();
    local pinSize = d.pinSize or 24;
    local showLabels = d.showLabels;

    for i, pinData in ipairs(pins) do
        if (isCategoryEnabled(pinData.category)) then
            local key = mapID .. "_" .. i;
            local frame = GetOrCreateWorldPin(key, WorldMapFrame:GetCanvas());
            ConfigurePinFrame(frame, pinData, pinSize, showLabels);
            HBDPins:AddWorldMapIconMap(module, frame, mapID, pinData.x, pinData.y, HBD_PINS_WORLDMAP_SHOW_CURRENT);
        end
    end
end

local function RefreshMinimapPins()
    if (not HBDPins or not module.enabled) then return; end

    HBDPins:RemoveAllMinimapIcons(module);

    local d = db();
    if (not d.showOnMinimap) then return; end

    local mapID = C_Map.GetBestMapForUnit("player");
    if (not mapID) then return; end

    local pins = Data:GetPinsForMap(mapID);
    if (not pins) then return; end

    local pinSize = d.pinSize or 24;
    local showLabels = d.showLabels;

    for i, pinData in ipairs(pins) do
        if (isCategoryEnabled(pinData.category)) then
            local key = mapID .. "_" .. i;
            local frame = GetOrCreateMinimapPin(key, Minimap);
            ConfigurePinFrame(frame, pinData, pinSize, showLabels);
            HBDPins:AddMinimapIconMap(module, frame, mapID, pinData.x, pinData.y, true, true);
        end
    end
end

-- Expose for WidgetOptions to trigger refresh
module.RefreshPins = function()
    RefreshWorldMapPins();
    RefreshMinimapPins();
end

-------------------------------------------------------------------------------
-- World map hook
-------------------------------------------------------------------------------

local worldMapHooked = false;

local function HookWorldMap()
    if (worldMapHooked) then return; end
    if (not WorldMapFrame) then return; end
    worldMapHooked = true;

    hooksecurefunc(WorldMapFrame, "OnMapChanged", function()
        if (module.enabled) then
            RefreshWorldMapPins();
        end
    end);

    WorldMapFrame:HookScript("OnShow", function()
        if (module.enabled) then
            RefreshWorldMapPins();
        end
    end);

    WorldMapFrame:HookScript("OnHide", function()
        if (module.enabled) then
            HBDPins:RemoveAllWorldMapIcons(module);
        end
    end);
end

-------------------------------------------------------------------------------
-- Module lifecycle
-------------------------------------------------------------------------------

function module:OnInit()
    db();
    Data = Lantern._mapPinsData;

    HBD = LibStub("HereBeDragons-2.0", true);
    HBDPins = LibStub("HereBeDragons-Pins-2.0", true);

    if (not HBD or not HBDPins) then
        Lantern:Print("|cffff0000MapPins:|r HereBeDragons not found.");
        return;
    end
end

function module:OnEnable()
    if (not HBDPins) then return; end

    HookWorldMap();
    self.addon:ModuleRegisterEvent(self, "ZONE_CHANGED_NEW_AREA", function()
        RefreshMinimapPins();
    end);
    self.addon:ModuleRegisterEvent(self, "ZONE_CHANGED", function()
        RefreshMinimapPins();
    end);

    -- Refresh now
    RefreshWorldMapPins();
    RefreshMinimapPins();
end

function module:OnDisable()
    if (HBDPins) then
        HBDPins:RemoveAllWorldMapIcons(module);
        HBDPins:RemoveAllMinimapIcons(module);
    end
end

Lantern:RegisterModule(module);
