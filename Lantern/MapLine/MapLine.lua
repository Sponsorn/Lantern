local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end
local L = Lantern.L;

local module = Lantern:NewModule("MapLine", {
    title = L["MAPLINE_TITLE"],
    desc = L["MAPLINE_DESC"],
    skipOptions = true,
});

local DEFAULTS = {
    lineStyle = "solid",
    lineSize = 400,
    color = { 1, 1, 1, 0.8 },
};

local STYLE_PRESETS = {
    solid  = { dotSize = 4, spacing = 3.3 },
    dotted = { dotSize = 8, spacing = 25 },
    thick  = { dotSize = 10, spacing = 5 },
};

-------------------------------------------------------------------------------
-- Pin mixin
-------------------------------------------------------------------------------

LanternMapLinePinMixin = CreateFromMixins(MapCanvasPinMixin);

function LanternMapLinePinMixin:OnLoad()
    self:UseFrameLevelType("PIN_FRAME_LEVEL_AREA_POI");
end

-------------------------------------------------------------------------------
-- Data provider
-------------------------------------------------------------------------------

local provider = CreateFromMixins(MapCanvasDataProviderMixin);
local dotPool = {};
local pin = nil;
local isShowing = false;
local providerAdded = false;
local appliedStyle = nil;
local appliedColor = nil;
local appliedLineSize = nil;

local function EnsureProvider()
    if (providerAdded) then return true; end
    if (not WorldMapFrame or not WorldMapFrame.AddDataProvider) then return false; end
    WorldMapFrame:AddDataProvider(provider);
    providerAdded = true;
    return true;
end

function provider:HideLine()
    if (not pin) then return; end
    for i = 1, #dotPool do
        dotPool[i]:Hide();
    end
    pin:Hide();
    isShowing = false;
end

function provider:ShowLine()
    if (not self:GetMap()) then return; end
    if (not pin) then
        pin = self:GetMap():AcquirePin("LanternMapLinePinTemplate");
    end
    pin:Show();
    isShowing = true;

    local db = module.db or DEFAULTS;
    local style = db.lineStyle or "solid";
    local lineSize = db.lineSize or DEFAULTS.lineSize;
    local preset = STYLE_PRESETS[style];
    local c = db.color or DEFAULTS.color;
    appliedStyle = style;
    appliedColor = c;
    appliedLineSize = lineSize;

    local spacing = preset and preset.spacing or 5;
    local amount = math.max(1, math.floor(lineSize / spacing));
    local size = preset and preset.dotSize or 5;
    local texture = (style == "dotted")
        and "Interface\\CHARACTERFRAME\\TempPortraitAlphaMaskSmall"
        or "Interface\\Buttons\\WHITE8x8";

    -- Ensure pool has enough dots
    for i = #dotPool + 1, amount do
        local dot = pin:CreateTexture("LanternML_Dot" .. i, "OVERLAY");
        dot:SetPoint("CENTER");
        dotPool[i] = dot;
    end

    -- Configure all dots
    for i = 1, #dotPool do
        local dot = dotPool[i];
        dot:SetTexture(texture);
        dot:SetSize(size, size);
        dot:SetVertexColor(c[1], c[2], c[3], c[4] or 0.8);
        if (i <= amount) then dot:Show(); else dot:Hide(); end
    end
end

-------------------------------------------------------------------------------
-- Update frame
-------------------------------------------------------------------------------

local updateFrame = CreateFrame("Frame", "LanternMapLineUpdate");

updateFrame:SetScript("OnUpdate", function()
    if (not module.enabled) then
        if (isShowing) then provider:HideLine(); end
        return;
    end

    local map = WorldMapFrame;
    local mapShown = map and map:IsShown();
    local flying = IsFlying();
    local inInstance = IsInInstance();
    local facing = GetPlayerFacing();

    if (mapShown and flying and not inInstance and facing) then
        -- Lazily add data provider (WorldMapFrame is load-on-demand)
        if (not EnsureProvider()) then return; end

        local mapID = map.mapID;
        if (not mapID) then
            if (isShowing) then provider:HideLine(); end
            return;
        end

        local vec2 = C_Map.GetPlayerMapPosition(mapID, "player");
        if (not vec2) then
            if (isShowing) then provider:HideLine(); end
            return;
        end

        if (not isShowing) then
            provider:ShowLine();
        else
            -- Refresh dots if style, color, or length changed
            local db = module.db or DEFAULTS;
            local curStyle = db.lineStyle or "solid";
            local curColor = db.color or DEFAULTS.color;
            local curLineSize = db.lineSize or DEFAULTS.lineSize;
            if (curStyle ~= appliedStyle or curColor ~= appliedColor or curLineSize ~= appliedLineSize) then
                provider:ShowLine();
            end
        end

        local px, py = vec2.x, vec2.y;
        pin:SetPosition(px, py);

        -- Calculate direction vector (WoW facing: 0=north, increases counter-clockwise)
        -- In map coords: +X = east (right), +Y = south (down)
        -- In pixel space: +X = right, +Y = up
        local fwd_x = -math.sin(facing);
        local fwd_y = math.cos(facing);

        local db = module.db or DEFAULTS;
        local style = db.lineStyle or "solid";
        local lineSize = db.lineSize or DEFAULTS.lineSize;
        local preset = STYLE_PRESETS[style];
        local spacing = preset and preset.spacing or 5;
        local amount = math.max(1, math.floor(lineSize / spacing));

        -- Pixel spacing between dots
        local pixelSpacing = lineSize / amount;

        for i = 1, math.min(amount, #dotPool) do
            local dot = dotPool[i];
            -- fwd_x/fwd_y are in map-coordinate direction
            -- Pixel X: same direction as map X (right = positive)
            -- Pixel Y: inverted from map Y (up = positive in pixels, but south = positive in map coords)
            local offsetX = fwd_x * pixelSpacing * i;
            local offsetY = fwd_y * pixelSpacing * i;
            dot:ClearAllPoints();
            dot:SetPoint("CENTER", pin, "CENTER", offsetX, offsetY);
            if (not dot:IsShown()) then dot:Show(); end
        end
    else
        if (isShowing) then provider:HideLine(); end
    end
end);

updateFrame:Hide();

-------------------------------------------------------------------------------
-- Module lifecycle
-------------------------------------------------------------------------------

function module:OnInit()
    local db = self.addon.db;
    if (not db.mapLine) then db.mapLine = {}; end
    self.db = db.mapLine;
    for k, v in pairs(DEFAULTS) do
        if (self.db[k] == nil) then self.db[k] = v; end
    end
end

function module:OnEnable()
    -- Try to add provider now; if WorldMapFrame isn't loaded yet,
    -- EnsureProvider() in the OnUpdate will add it lazily.
    EnsureProvider();
    updateFrame:Show();
end

function module:OnDisable()
    updateFrame:Hide();
    if (isShowing) then provider:HideLine(); end
    if (providerAdded and WorldMapFrame and WorldMapFrame.RemoveDataProvider) then
        WorldMapFrame:RemoveDataProvider(provider);
        providerAdded = false;
    end
end

Lantern:RegisterModule(module);
