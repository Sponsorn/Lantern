local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local module = Lantern:NewModule("CursorRing", {
    title = "Cursor Ring & Trail",
    desc = "Displays customizable ring(s) around the mouse cursor with cast/GCD indicators and an optional trail.",
    skipOptions = true,
    defaultEnabled = false,
});

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local ASSET_PATH = "Interface\\AddOns\\Lantern\\Media\\Images\\MouseRing\\";
local CAST_SEGMENTS = 36;
local TRAIL_UPDATE_INTERVAL = 0.016; -- ~60Hz
local TRAIL_MOVE_THRESHOLD_SQ = 4;   -- 2px squared
local TRAIL_MAX_ALPHA = 0.8;
local GCD_SPELL_ID = 61304;
local GCD_SHOW_DELAY = 0.07;
local CAST_TICKER_INTERVAL = 0.033;  -- ~30fps
local ALPHA_CHECK_INTERVAL = 0.5;
local TEXCOORD_HALF = 0.5 / 256;
local TRAIL_TEXCOORD_HALF = 0.5 / 128;

local floor = math.floor;
local sqrt = math.sqrt;
local max = math.max;
local min = math.min;
local rad = math.rad;
local abs = math.abs;

local SHAPES = {
    ring = "ring.tga",
    thin_ring = "thin_ring.tga",
};

local FILLS = {
    ring = "ring_fill.tga",
    thin_ring = "thin_ring_fill.tga",
};

local TRAIL_STYLE_PRESETS = {
    glow      = { maxPoints = 20, dotSize = 24, dotSpacing = 2, shrink = true,  shrinkDistance = false },
    line      = { maxPoints = 60, dotSize = 12, dotSpacing = 1, shrink = false, shrinkDistance = true },
    thickline = { maxPoints = 60, dotSize = 22, dotSpacing = 1, shrink = false, shrinkDistance = true },
    dots      = { maxPoints = 12, dotSize = 18, dotSpacing = 8, shrink = true,  shrinkDistance = false },
};

local DEFAULTS = {
    showOutOfCombat = true,
    opacityInCombat = 1.0,
    opacityOutOfCombat = 1.0,

    ring1Enabled = true,
    ring1Size = 48,
    ring1Shape = "ring",
    ring1Color = { r = 1.0, g = 0.66, b = 0.0 },

    ring2Enabled = false,
    ring2Size = 32,
    ring2Shape = "thin_ring",
    ring2Color = { r = 1.0, g = 1.0, b = 1.0 },

    dotEnabled = false,
    dotColor = { r = 1.0, g = 1.0, b = 1.0 },
    dotSize = 8,

    castEnabled = true,
    castStyle = "segments",
    castColor = { r = 1.0, g = 0.66, b = 0.0 },
    castOffset = 8,

    gcdEnabled = false,
    gcdColor = { r = 0.0, g = 0.56, b = 0.91 },
    gcdOffset = 8,

    trailEnabled = false,
    trailStyle = "glow",
    trailDuration = 0.4,
    trailColor = { r = 1.0, g = 1.0, b = 1.0 },
    trailMaxPoints = 20,
    trailDotSize = 24,
    trailDotSpacing = 2,
    trailShrink = true,
    trailShrinkDistance = false,
};

-------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------

local db;
local frames = {};
local inCombat = false;
local inInstance = false;
local isCasting = false;
local gcdActive = false;
local castTicker = nil;
local gcdDelayTimer = nil;
local previewMode = false;
local previewLoopTimer = nil;
local fakeCastTimer = nil;
local fakeGCDTimer = nil;

-- Trail state
local trailBuf = {};
local trailPoolSize = 0;
local trailHead = 0;
local trailCount = 0;
local trailActive = false;
local trailUpdateTimer = 0;
local lastTrailX, lastTrailY = 0, 0;
local lastRingX, lastRingY = 0, 0;
local trailDormant = false;
local trailLastUpdateTime = nil;

-------------------------------------------------------------------------------
-- Database
-------------------------------------------------------------------------------

local function getDB()
    if (not Lantern.db) then Lantern.db = {}; end
    if (not Lantern.db.cursorRing) then Lantern.db.cursorRing = {}; end
    local d = Lantern.db.cursorRing;
    for k, v in pairs(DEFAULTS) do
        if (d[k] == nil) then
            if (type(v) == "table") then
                d[k] = { r = v.r, g = v.g, b = v.b };
            else
                d[k] = v;
            end
        end
    end
    db = d;
    return d;
end

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function clamp01(v)
    if (v < 0) then return 0; end
    if (v > 1) then return 1; end
    return v;
end

local function RefreshCombatCache()
    inCombat = InCombatLockdown() or UnitAffectingCombat("player");
    local inInst, instType = IsInInstance();
    inInstance = inInst and (instType == "party" or instType == "raid"
        or instType == "pvp" or instType == "arena" or instType == "scenario");
end

local function ShouldShow()
    if (previewMode) then return true; end
    if (inCombat or inInstance) then return true; end
    return db.showOutOfCombat;
end

local function GetCurrentOpacity()
    if (previewMode) then return 1.0; end
    return (inCombat or inInstance) and db.opacityInCombat or db.opacityOutOfCombat;
end

local function GetContainerSize()
    local s = max(db.ring1Enabled and db.ring1Size or 0, db.ring2Enabled and db.ring2Size or 0);
    if (db.gcdEnabled) then
        s = max(s, db.ring1Size + db.gcdOffset * 2);
    end
    if (db.castEnabled and db.castStyle == "swipe") then
        s = max(s, db.ring1Size + db.gcdOffset * 2 + db.castOffset * 2);
    end
    return max(s, 16);
end

local function SetTexProps(tex)
    if (tex.SetSnapToPixelGrid) then
        tex:SetSnapToPixelGrid(false);
        tex:SetTexelSnappingBias(0);
    end
end

-------------------------------------------------------------------------------
-- GCD Cooldown Helpers
-------------------------------------------------------------------------------

local function FetchGCDCooldown()
    if (C_Spell and C_Spell.GetSpellCooldown) then
        local result = C_Spell.GetSpellCooldown(GCD_SPELL_ID);
        if (type(result) == "table") then
            return result.startTime or result.start, result.duration, result.modRate;
        end
    end
    return nil, nil, nil;
end

local function SetupCooldownFrame(cd, parent)
    cd:SetDrawSwipe(true);
    cd:SetDrawEdge(false);
    cd:SetHideCountdownNumbers(true);
    cd:SetReverse(true);
    if (cd.SetDrawBling) then cd:SetDrawBling(false); end
    if (cd.SetUseCircularEdge) then cd:SetUseCircularEdge(true); end
    SetTexProps(cd);
    cd:SetFrameStrata("TOOLTIP");
    cd:SetFrameLevel(parent:GetFrameLevel() + 5);
    cd:EnableMouse(false);
    cd:Hide();
end

-------------------------------------------------------------------------------
-- Cast Ticker
-------------------------------------------------------------------------------

local function StopCastTicker()
    if (castTicker) then
        castTicker:Cancel();
        castTicker = nil;
    end
    isCasting = false;

    -- Clear segment visuals
    if (frames.castSegments) then
        for i = 1, CAST_SEGMENTS do
            local seg = frames.castSegments[i];
            if (seg) then
                seg:SetVertexColor(1, 1, 1, 0);
                seg:Hide();
            end
        end
    end
    -- Clear fill overlay
    if (frames.castOverlay) then
        frames.castOverlay:SetAlpha(0);
        frames.castOverlay:SetSize(1, 1);
        frames.castOverlay:Hide();
    end
    -- Hide cast cooldown (swipe style)
    if (frames.castCooldown) then
        frames.castCooldown:Hide();
    end
end

local function StartCastTicker()
    if (castTicker) then return; end
    if (db.castStyle == "swipe") then return; end -- swipe uses Cooldown frame directly

    castTicker = C_Timer.NewTicker(CAST_TICKER_INTERVAL, function()
        local now = GetTime();
        local progress = 0;
        local _, _, _, castStart, castEnd = UnitCastingInfo("player");
        local _, _, _, chanStart, chanEnd = UnitChannelInfo("player");

        if (castStart) then
            progress = (now - castStart / 1000) / ((castEnd - castStart) / 1000);
        elseif (chanStart) then
            progress = 1 - (now - chanStart / 1000) / ((chanEnd - chanStart) / 1000);
        else
            StopCastTicker();
            return;
        end

        progress = clamp01(progress);
        local visible = ShouldShow();
        local c = db.castColor;

        if (db.castStyle == "segments" and frames.castSegments) then
            local lit = floor(progress * CAST_SEGMENTS + 0.5);
            for i = 1, CAST_SEGMENTS do
                local seg = frames.castSegments[i];
                if (seg) then
                    local show = visible and (i <= lit);
                    seg:SetShown(show);
                    if (show) then seg:SetVertexColor(c.r, c.g, c.b, 1); end
                end
            end
        elseif (db.castStyle == "fill" and frames.castOverlay) then
            local show = visible and progress > 0;
            frames.castOverlay:SetShown(show);
            if (show) then
                frames.castOverlay:SetAlpha(1);
                local sz = db.ring1Size * max(progress, 0.01);
                frames.castOverlay:SetSize(sz, sz);
            end
        end
    end);
end

-------------------------------------------------------------------------------
-- GCD Processing
-------------------------------------------------------------------------------

local function ProcessGCDUpdate()
    if (gcdDelayTimer) then
        gcdDelayTimer:Cancel();
        gcdDelayTimer = nil;
    end

    if (not db.gcdEnabled or not frames.gcdCooldown) then
        if (frames.gcdCooldown) then
            frames.gcdCooldown:Hide();
            gcdActive = false;
        end
        return;
    end

    if (not ShouldShow()) then
        frames.gcdCooldown:Hide();
        gcdActive = false;
        return;
    end

    -- Don't show GCD during cast
    if (isCasting) then return; end

    local start, duration, modRate = FetchGCDCooldown();
    if (start and duration and duration > 0 and start > 0) then
        gcdDelayTimer = C_Timer.NewTimer(GCD_SHOW_DELAY, function()
            gcdDelayTimer = nil;
            if (isCasting) then return; end
            if (not ShouldShow()) then return; end
            if (not frames.gcdCooldown) then return; end

            frames.gcdCooldown:Show();
            gcdActive = true;
            if (modRate) then
                frames.gcdCooldown:SetCooldown(start, duration, modRate);
            else
                frames.gcdCooldown:SetCooldown(start, duration);
            end
        end);
    else
        frames.gcdCooldown:Hide();
        gcdActive = false;
    end
end

-------------------------------------------------------------------------------
-- Visibility
-------------------------------------------------------------------------------

local function UpdateVisibility()
    if (not frames.container) then return; end

    local show = ShouldShow();
    local alpha = GetCurrentOpacity();

    frames.container:SetShown(show);
    frames.container:SetAlpha(alpha);

    if (frames.ring1Tex) then
        frames.ring1Tex:SetShown(show and db.ring1Enabled);
    end
    if (frames.ring2Tex) then
        frames.ring2Tex:SetShown(show and db.ring2Enabled);
    end
    if (frames.dotTex) then
        frames.dotTex:SetShown(show and db.dotEnabled);
    end
end

local function UpdateTrailVisibility()
    trailActive = db.trailEnabled and ShouldShow();
    if (not trailActive) then
        for i = 1, trailPoolSize do
            local pt = trailBuf[i];
            if (pt and pt.active and pt.tex) then
                pt.tex:Hide();
            end
        end
    end
end

-------------------------------------------------------------------------------
-- Appearance Updates (called from Options)
-------------------------------------------------------------------------------

local function UpdateDotAppearance()
    if (not frames.dotTex) then return; end
    local c = db.dotColor;
    frames.dotTex:SetVertexColor(c.r, c.g, c.b, 1);
    frames.dotTex:SetSize(db.dotSize, db.dotSize);
    frames.dotTex:SetShown(db.dotEnabled);
end

local function UpdateRingAppearance(ringNum)
    local prefix = "ring" .. ringNum;
    local texKey = prefix .. "Tex";
    local tex = frames[texKey];

    if (not tex or not frames.container) then return; end

    local enabled = db[prefix .. "Enabled"];
    local size = db[prefix .. "Size"];
    local shape = db[prefix .. "Shape"];
    local color = db[prefix .. "Color"];

    tex:SetTexture(ASSET_PATH .. (SHAPES[shape] or "ring.tga"), "CLAMP", "CLAMP", "TRILINEAR");
    tex:SetTexCoord(TEXCOORD_HALF, 1 - TEXCOORD_HALF, TEXCOORD_HALF, 1 - TEXCOORD_HALF);
    tex:SetSize(size, size);
    tex:SetVertexColor(color.r, color.g, color.b, 1);
    tex:SetShown(enabled);

    -- Resize container
    frames.container:SetSize(GetContainerSize(), GetContainerSize());

    -- Update cast segments size to match ring1
    if (ringNum == 1 and frames.castSegments) then
        for i = 1, CAST_SEGMENTS do
            local seg = frames.castSegments[i];
            if (seg) then
                seg:SetSize(db.ring1Size, db.ring1Size);
            end
        end
    end
end

local function UpdateGCDAppearance()
    if (not frames.gcdCooldown) then return; end

    local size = db.ring1Size + db.gcdOffset * 2;
    frames.gcdCooldown:SetSize(size, size);

    local texPath = ASSET_PATH .. (SHAPES[db.ring1Shape] or "ring.tga");
    frames.gcdCooldown:SetSwipeTexture(texPath);

    local c = db.gcdColor;
    frames.gcdCooldown:SetSwipeColor(c.r, c.g, c.b, 1);

    -- Resize container
    if (frames.container) then
        frames.container:SetSize(GetContainerSize(), GetContainerSize());
    end
end

local function UpdateCastAppearance()
    if (not frames.container) then return; end

    -- Update segments texture
    if (frames.castSegments) then
        local texPath;
        if (db.castStyle == "fill") then
            texPath = ASSET_PATH .. (FILLS[db.ring1Shape] or "ring_fill.tga");
        else
            texPath = ASSET_PATH .. "cast_segment.tga";
        end
        for i = 1, CAST_SEGMENTS do
            local seg = frames.castSegments[i];
            if (seg) then
                seg:SetTexture(texPath, "CLAMP", "CLAMP", "TRILINEAR");
                seg:SetSize(db.ring1Size, db.ring1Size);
            end
        end
    end

    -- Update cast overlay (fill style)
    if (frames.castOverlay) then
        local fillPath = ASSET_PATH .. (FILLS[db.ring1Shape] or "ring_fill.tga");
        frames.castOverlay:SetTexture(fillPath, "CLAMP", "CLAMP", "TRILINEAR");
        local c = db.castColor;
        frames.castOverlay:SetVertexColor(c.r, c.g, c.b, 1);
    end

    -- Update cast cooldown (swipe style)
    if (frames.castCooldown) then
        local size = db.ring1Size + db.gcdOffset * 2 + db.castOffset * 2;
        frames.castCooldown:SetSize(size, size);

        local texPath = ASSET_PATH .. (SHAPES[db.ring1Shape] or "ring.tga");
        frames.castCooldown:SetSwipeTexture(texPath);

        local c = db.castColor;
        frames.castCooldown:SetSwipeColor(c.r, c.g, c.b, 1);
    end

    -- Resize container
    frames.container:SetSize(GetContainerSize(), GetContainerSize());
end

-- Forward declarations for trail functions (defined after CreateTrailFrame)
local EnsureTrailPool;
local ResetTrailState;

-- Exposed for Options.lua
function module:UpdateRing(ringNum) UpdateRingAppearance(ringNum); end
function module:UpdateDot() UpdateDotAppearance(); end
function module:UpdateGCD() UpdateGCDAppearance(); end
function module:UpdateCast() UpdateCastAppearance(); end
function module:UpdateVisibility()
    UpdateVisibility();
    UpdateTrailVisibility();
end
function module:UpdateTrail()
    if (not frames.trailContainer) then return; end
    local newSize = db.trailMaxPoints or 20;
    if (newSize ~= trailPoolSize) then
        EnsureTrailPool(newSize);
    end
    -- Update dot sizes for non-shrink styles (shrink styles set size in OnUpdate)
    local dotSize = db.trailDotSize or 24;
    for i = 1, trailPoolSize do
        local pt = trailBuf[i];
        if (pt and pt.tex) then
            pt.tex:SetSize(dotSize, dotSize);
        end
    end
end
module.TRAIL_STYLE_PRESETS = TRAIL_STYLE_PRESETS;

-------------------------------------------------------------------------------
-- Preview Mode (called from Options)
-------------------------------------------------------------------------------

function module:SetPreviewMode(enabled)
    previewMode = enabled;

    if (previewLoopTimer) then
        previewLoopTimer:Cancel();
        previewLoopTimer = nil;
    end

    if (enabled) then
        self:TestBoth();
        previewLoopTimer = C_Timer.NewTicker(3, function()
            if (not previewMode) then return; end
            self:TestBoth();
        end);
    end

    UpdateVisibility();
    UpdateTrailVisibility();
end

function module:IsPreviewActive()
    return previewMode;
end

function module:TestCast(duration)
    duration = duration or 2.5;
    if (not frames.container or not db.castEnabled) then return; end

    -- Stop any existing fake cast
    if (fakeCastTimer) then fakeCastTimer:Cancel(); fakeCastTimer = nil; end
    StopCastTicker();

    isCasting = true;
    local startTime = GetTime();
    local c = db.castColor;

    if (db.castStyle == "swipe" and frames.castCooldown) then
        frames.castCooldown:SetSwipeColor(c.r, c.g, c.b, 1);
        frames.castCooldown:Show();
        frames.castCooldown:SetCooldown(startTime, duration);
        fakeCastTimer = C_Timer.NewTimer(duration, function()
            fakeCastTimer = nil;
            isCasting = false;
            frames.castCooldown:Hide();
        end);
    else
        -- Segments or fill: use a ticker
        castTicker = C_Timer.NewTicker(CAST_TICKER_INTERVAL, function()
            local now = GetTime();
            local progress = clamp01((now - startTime) / duration);

            if (progress >= 1) then
                StopCastTicker();
                isCasting = false;
                return;
            end

            if (db.castStyle == "segments" and frames.castSegments) then
                local lit = floor(progress * CAST_SEGMENTS + 0.5);
                for i = 1, CAST_SEGMENTS do
                    local seg = frames.castSegments[i];
                    if (seg) then
                        local show = (i <= lit);
                        seg:SetShown(show);
                        if (show) then seg:SetVertexColor(c.r, c.g, c.b, 1); end
                    end
                end
            elseif (db.castStyle == "fill" and frames.castOverlay) then
                local show = progress > 0;
                frames.castOverlay:SetShown(show);
                if (show) then
                    frames.castOverlay:SetAlpha(1);
                    local sz = db.ring1Size * max(progress, 0.01);
                    frames.castOverlay:SetSize(sz, sz);
                end
            end
        end);
    end
end

function module:TestGCD(duration)
    duration = duration or 1.5;
    if (not frames.gcdCooldown or not db.gcdEnabled) then return; end

    if (fakeGCDTimer) then fakeGCDTimer:Cancel(); fakeGCDTimer = nil; end

    local c = db.gcdColor;
    frames.gcdCooldown:SetSwipeColor(c.r, c.g, c.b, 1);
    frames.gcdCooldown:Show();
    gcdActive = true;
    frames.gcdCooldown:SetCooldown(GetTime(), duration);

    fakeGCDTimer = C_Timer.NewTimer(duration, function()
        fakeGCDTimer = nil;
        frames.gcdCooldown:Hide();
        gcdActive = false;
    end);
end

function module:TestBoth()
    self:TestGCD(1.5);
    self:TestCast(2.5);
end

-------------------------------------------------------------------------------
-- Frame Creation
-------------------------------------------------------------------------------

local function CreateRingTexture(parent, ringNum)
    local prefix = "ring" .. ringNum;
    local tex = parent:CreateTexture(nil, "BORDER");
    local shape = db[prefix .. "Shape"];
    local color = db[prefix .. "Color"];
    local size = db[prefix .. "Size"];

    tex:SetTexture(ASSET_PATH .. (SHAPES[shape] or "ring.tga"), "CLAMP", "CLAMP", "TRILINEAR");
    tex:SetTexCoord(TEXCOORD_HALF, 1 - TEXCOORD_HALF, TEXCOORD_HALF, 1 - TEXCOORD_HALF);
    tex:SetSize(size, size);
    tex:SetPoint("CENTER");
    tex:SetVertexColor(color.r, color.g, color.b, 1);
    SetTexProps(tex);
    tex:SetShown(db[prefix .. "Enabled"]);

    return tex;
end

local function CreateDotTexture(parent)
    local dot = parent:CreateTexture(nil, "OVERLAY");
    dot:SetTexture(ASSET_PATH .. "dot.tga", "CLAMP", "CLAMP", "TRILINEAR");
    dot:SetSize(db.dotSize, db.dotSize);
    dot:SetPoint("CENTER");
    local c = db.dotColor;
    dot:SetVertexColor(c.r, c.g, c.b, 1);
    SetTexProps(dot);
    dot:SetShown(db.dotEnabled);

    return dot;
end

local function CreateCastSegments(parent)
    local segments = {};
    local texPath = ASSET_PATH .. "cast_segment.tga";

    for i = 1, CAST_SEGMENTS do
        local seg = parent:CreateTexture(nil, "ARTWORK");
        seg:SetTexture(texPath, "CLAMP", "CLAMP", "TRILINEAR");
        seg:SetSize(db.ring1Size, db.ring1Size);
        seg:SetPoint("CENTER");
        seg:SetRotation(rad((i - 1) * (360 / CAST_SEGMENTS)));
        seg:SetVertexColor(1, 1, 1, 0);
        seg:SetTexCoord(TEXCOORD_HALF, 1 - TEXCOORD_HALF, TEXCOORD_HALF, 1 - TEXCOORD_HALF);
        SetTexProps(seg);
        seg:Hide();
        segments[i] = seg;
    end

    return segments;
end

local function CreateCastOverlay(parent)
    local fillPath = ASSET_PATH .. (FILLS[db.ring1Shape] or "ring_fill.tga");
    local overlay = parent:CreateTexture(nil, "OVERLAY");
    overlay:SetTexture(fillPath, "CLAMP", "CLAMP", "TRILINEAR");
    local c = db.castColor;
    overlay:SetVertexColor(c.r, c.g, c.b, 1);
    overlay:SetAlpha(0);
    overlay:SetSize(1, 1);
    overlay:SetPoint("CENTER");
    overlay:SetTexCoord(TEXCOORD_HALF, 1 - TEXCOORD_HALF, TEXCOORD_HALF, 1 - TEXCOORD_HALF);
    SetTexProps(overlay);
    overlay:Hide();
    return overlay;
end

EnsureTrailPool = function(count)
    if (not frames.trailContainer) then return; end

    -- Grow pool if needed
    for i = trailPoolSize + 1, count do
        local tex = frames.trailContainer:CreateTexture(nil, "BACKGROUND");
        tex:SetTexture(ASSET_PATH .. "trail_glow.tga", "CLAMP", "CLAMP", "TRILINEAR");
        tex:SetTexCoord(TRAIL_TEXCOORD_HALF, 1 - TRAIL_TEXCOORD_HALF, TRAIL_TEXCOORD_HALF, 1 - TRAIL_TEXCOORD_HALF);
        tex:SetBlendMode("ADD");
        tex:SetSize(db.trailDotSize or 24, db.trailDotSize or 24);
        tex:Hide();
        trailBuf[i] = { x = 0, y = 0, time = 0, tex = tex, active = false };
    end

    -- Hide excess textures if shrinking
    for i = count + 1, trailPoolSize do
        local pt = trailBuf[i];
        if (pt) then
            pt.active = false;
            if (pt.tex) then pt.tex:Hide(); end
        end
    end

    trailPoolSize = count;

    -- Reset ring buffer if pool changed
    trailHead = 0;
    trailCount = 0;
    trailDormant = false;
    trailLastUpdateTime = nil;
end

ResetTrailState = function()
    for i = 1, trailPoolSize do
        local pt = trailBuf[i];
        if (pt) then
            pt.active = false;
            if (pt.tex) then pt.tex:Hide(); end
        end
    end
    trailHead = 0;
    trailCount = 0;
    trailDormant = false;
    trailLastUpdateTime = nil;
end

local function CreateTrailFrame()
    if (frames.trailContainer) then return; end

    local container = CreateFrame("Frame", "LanternCursorRingTrail", UIParent);
    container:SetSize(1, 1);
    container:SetFrameStrata("TOOLTIP");
    container:SetFrameLevel(1);
    container:EnableMouse(false);
    container:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0);
    frames.trailContainer = container;

    -- Create pooled trail textures
    local poolCount = db.trailMaxPoints or 20;
    EnsureTrailPool(poolCount);

    -- Trail OnUpdate
    container:SetScript("OnUpdate", function(_, elapsed)
        if (not db.trailEnabled or not trailActive) then return; end

        trailUpdateTimer = trailUpdateTimer + elapsed;
        if (trailUpdateTimer < TRAIL_UPDATE_INTERVAL) then return; end
        trailUpdateTimer = 0;

        local now = GetTime();
        local maxPts = trailPoolSize;

        -- Hitch recovery: after a loading screen or long stutter, reset trail
        -- instead of drawing a teleported line of dots
        if (trailLastUpdateTime and (now - trailLastUpdateTime) > 0.25) then
            ResetTrailState();
            local cx, cy = GetCursorPosition();
            local sc = UIParent:GetEffectiveScale();
            lastTrailX, lastTrailY = floor(cx / sc + 0.5), floor(cy / sc + 0.5);
            trailLastUpdateTime = now;
            return;
        end
        trailLastUpdateTime = now;

        -- Read cursor once, reuse for dormant check and emission
        local cx, cy = GetCursorPosition();
        local scale = UIParent:GetEffectiveScale();
        local x, y = floor(cx / scale + 0.5), floor(cy / scale + 0.5);

        -- Dormant: cursor hasn't moved and all dots have faded out
        if (trailDormant) then
            local ddx, ddy = x - lastTrailX, y - lastTrailY;
            if (ddx * ddx + ddy * ddy < TRAIL_MOVE_THRESHOLD_SQ) then
                return; -- still dormant, skip everything
            end
            -- Don't update lastTrailX/Y here — let the emission code below
            -- see the full distance from the pre-dormant position and emit naturally
            trailDormant = false;
        end

        local opacity = GetCurrentOpacity();
        local spacing = db.trailDotSpacing or 2;
        local spacingSq = spacing * spacing;
        local dotSize = db.trailDotSize or 24;
        local shouldShrink = db.trailShrink;
        local shrinkDist = db.trailShrinkDistance;
        local anyShrink = shouldShrink or shrinkDist;

        -- Emit dots along the path — interpolate to fill gaps during fast movement
        local dx, dy = x - lastTrailX, y - lastTrailY;
        local distSq = dx * dx + dy * dy;
        if (distSq >= spacingSq) then
            local dist = sqrt(distSq);
            local n = floor(dist / spacing);
            if (n > maxPts) then n = maxPts; end -- cap to pool size
            local ux, uy = dx / dist, dy / dist;
            for s = 1, n do
                local px = lastTrailX + ux * spacing * s;
                local py = lastTrailY + uy * spacing * s;
                trailHead = (trailHead % maxPts) + 1;
                local slot = trailBuf[trailHead];
                slot.x, slot.y, slot.time, slot.active = px, py, now, true;
                if (trailCount < maxPts) then trailCount = trailCount + 1; end
                local tex = slot.tex;
                if (tex) then
                    tex:ClearAllPoints();
                    tex:SetPoint("CENTER", UIParent, "BOTTOMLEFT", px, py);
                end
            end
            lastTrailX = lastTrailX + ux * spacing * n;
            lastTrailY = lastTrailY + uy * spacing * n;
        end

        -- Update existing points (alpha + size only, no repositioning)
        local dur = db.trailDuration > 0 and db.trailDuration or 0.1;
        local invDur = 1 / dur;
        local tc = db.trailColor;
        local anyActive = false;

        -- Walk ring buffer head-to-tail to assign distance ranks
        -- rank 1 = newest (near cursor), rank N = oldest (tail end)
        local visibleCount = 0;
        if (shrinkDist) then
            local idx = trailHead;
            for i = 1, maxPts do
                local pt = trailBuf[idx];
                if (pt and pt.active) then
                    local age = (now - pt.time) * invDur;
                    if (age < 1) then
                        visibleCount = visibleCount + 1;
                    end
                end
                idx = idx - 1;
                if (idx < 1) then idx = maxPts; end
            end
        end

        local rank = 0;
        local idx = trailHead;
        for i = 1, maxPts do
            local pt = trailBuf[idx];
            if (pt and pt.active and pt.tex) then
                local fade = 1 - ((now - pt.time) * invDur);
                if (fade <= 0) then
                    pt.active = false;
                    trailCount = trailCount - 1;
                    pt.tex:Hide();
                else
                    anyActive = true;
                    rank = rank + 1;

                    -- Distance-based scale: 1.0 at head, tapering toward 0 at tail
                    local distScale = 1;
                    if (shrinkDist and visibleCount > 1) then
                        distScale = 1 - ((rank - 1) / (visibleCount - 1));
                        distScale = sqrt(distScale); -- softer taper
                    end

                    local alpha = fade * distScale * opacity * TRAIL_MAX_ALPHA;
                    pt.tex:SetVertexColor(tc.r, tc.g, tc.b, alpha);

                    -- Only call SetSize when shrink is active (scale changes per dot)
                    if (anyShrink) then
                        local scale = distScale;
                        if (shouldShrink) then
                            scale = scale * fade;
                        end
                        pt.tex:SetSize(dotSize * scale, dotSize * scale);
                    end

                    pt.tex:Show();
                end
            end
            idx = idx - 1;
            if (idx < 1) then idx = maxPts; end
        end

        -- Enter dormant mode when cursor is still and all dots have faded
        if (not anyActive) then
            local ddx, ddy = x - lastTrailX, y - lastTrailY;
            if (ddx * ddx + ddy * ddy < TRAIL_MOVE_THRESHOLD_SQ) then
                trailDormant = true;
            end
        end
    end);

    container:Show();
end

local function CreateFrames()
    if (frames.container) then return; end

    local containerSize = GetContainerSize();
    local container = CreateFrame("Frame", "LanternCursorRing", UIParent);
    container:SetSize(containerSize, containerSize);
    container:SetFrameStrata("TOOLTIP");
    container:SetIgnoreParentScale(false);
    container:EnableMouse(false);
    container:SetClampedToScreen(false);
    frames.container = container;

    -- Ring 2 (inner, drawn first / behind ring 1)
    frames.ring2Tex = CreateRingTexture(container, 2);

    -- Ring 1 (outer)
    frames.ring1Tex = CreateRingTexture(container, 1);

    -- Center dot (shared, drawn on top)
    frames.dotTex = CreateDotTexture(container);

    -- GCD Cooldown
    local gcdSize = db.ring1Size + db.gcdOffset * 2;
    local gcdCd = CreateFrame("Cooldown", "LanternCursorRing_GCDCooldown", container);
    gcdCd:SetSize(gcdSize, gcdSize);
    gcdCd:SetPoint("CENTER");
    SetupCooldownFrame(gcdCd, container);
    local gcdTexPath = ASSET_PATH .. (SHAPES[db.ring1Shape] or "ring.tga");
    gcdCd:SetSwipeTexture(gcdTexPath);
    local gc = db.gcdColor;
    gcdCd:SetSwipeColor(gc.r, gc.g, gc.b, 1);
    gcdCd:SetScript("OnCooldownDone", function()
        gcdActive = false;
        gcdCd:Hide();
    end);
    frames.gcdCooldown = gcdCd;

    -- Cast Cooldown (swipe style)
    local castSize = db.ring1Size + db.gcdOffset * 2 + db.castOffset * 2;
    local castCd = CreateFrame("Cooldown", "LanternCursorRing_CastCooldown", container);
    castCd:SetSize(castSize, castSize);
    castCd:SetPoint("CENTER");
    SetupCooldownFrame(castCd, container);
    castCd:SetFrameLevel(container:GetFrameLevel() + 6); -- above GCD
    local castTexPath = ASSET_PATH .. (SHAPES[db.ring1Shape] or "ring.tga");
    castCd:SetSwipeTexture(castTexPath);
    local cc = db.castColor;
    castCd:SetSwipeColor(cc.r, cc.g, cc.b, 1);
    castCd:SetScript("OnCooldownDone", function()
        castCd:Hide();
    end);
    frames.castCooldown = castCd;

    -- Cast Segments
    frames.castSegments = CreateCastSegments(container);

    -- Cast Overlay (fill style)
    frames.castOverlay = CreateCastOverlay(container);

    -- OnUpdate: cursor tracking + periodic alpha check
    local alphaTimer = 0;
    container:SetScript("OnUpdate", function(self, elapsed)
        local x, y = GetCursorPosition();
        local scale = UIParent:GetEffectiveScale();
        x, y = floor(x / scale + 0.5), floor(y / scale + 0.5);

        if (x ~= lastRingX or y ~= lastRingY) then
            lastRingX, lastRingY = x, y;
            self:ClearAllPoints();
            self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y);
        end

        -- Periodic alpha update
        alphaTimer = alphaTimer + elapsed;
        if (alphaTimer >= ALPHA_CHECK_INTERVAL) then
            alphaTimer = 0;
            -- Auto-disable preview when settings panel closes
            if (previewMode) then
                local panel = _G.Lantern and _G.Lantern._uxPanel;
                local panelShown = panel and panel.frame and panel.frame:IsShown();
                if (not panelShown) then
                    module:SetPreviewMode(false);
                end
            end
            UpdateVisibility();
        end
    end);

    -- Create trail if enabled
    if (db.trailEnabled) then
        CreateTrailFrame();
        local x, y = GetCursorPosition();
        local scale = UIParent:GetEffectiveScale();
        lastTrailX, lastTrailY = x / scale, y / scale;
    end

    -- Position at cursor immediately
    local x, y = GetCursorPosition();
    local scale = UIParent:GetEffectiveScale();
    x, y = floor(x / scale + 0.5), floor(y / scale + 0.5);
    lastRingX, lastRingY = x, y;
    container:ClearAllPoints();
    container:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y);

    UpdateVisibility();
    UpdateTrailVisibility();
    container:Show();
end

local function DestroyFrames()
    StopCastTicker();

    if (gcdDelayTimer) then gcdDelayTimer:Cancel(); gcdDelayTimer = nil; end
    if (previewLoopTimer) then previewLoopTimer:Cancel(); previewLoopTimer = nil; end
    if (fakeCastTimer) then fakeCastTimer:Cancel(); fakeCastTimer = nil; end
    if (fakeGCDTimer) then fakeGCDTimer:Cancel(); fakeGCDTimer = nil; end

    if (frames.container) then
        frames.container:SetScript("OnUpdate", nil);
        frames.container:Hide();
    end

    if (frames.trailContainer) then
        frames.trailContainer:SetScript("OnUpdate", nil);
        frames.trailContainer:Hide();
    end

    -- Clear trail state
    for i = 1, trailPoolSize do
        local pt = trailBuf[i];
        if (pt) then
            if (pt.tex) then pt.tex:Hide(); end
            pt.active = false;
        end
    end
    trailHead = 0;
    trailCount = 0;
    trailPoolSize = 0;
    trailActive = false;
    trailDormant = false;
    trailLastUpdateTime = nil;

    gcdActive = false;
    isCasting = false;
    previewMode = false;

    -- Nil out frame refs (will be recreated on enable)
    frames.container = nil;
    frames.ring1Tex = nil;
    frames.ring2Tex = nil;
    frames.dotTex = nil;
    frames.gcdCooldown = nil;
    frames.castCooldown = nil;
    frames.castSegments = nil;
    frames.castOverlay = nil;
    frames.trailContainer = nil;
end

-------------------------------------------------------------------------------
-- Trail on-demand creation (for when trail gets enabled via options)
-------------------------------------------------------------------------------

function module:EnsureTrail()
    if (not frames.trailContainer and db.trailEnabled) then
        CreateTrailFrame();
        local x, y = GetCursorPosition();
        local scale = UIParent:GetEffectiveScale();
        lastTrailX, lastTrailY = x / scale, y / scale;
    end
    UpdateTrailVisibility();
end

-------------------------------------------------------------------------------
-- Event Handling
-------------------------------------------------------------------------------

local function OnEvent(_, event, unit, _, spellID)
    if (event == "PLAYER_ENTERING_WORLD") then
        RefreshCombatCache();
        if (not frames.container) then
            CreateFrames();
        end
        UpdateVisibility();
        UpdateTrailVisibility();

        -- Snap to cursor position after loading
        C_Timer.After(0, function()
            if (frames.container and frames.container:IsShown()) then
                local x, y = GetCursorPosition();
                local scale = UIParent:GetEffectiveScale();
                x, y = floor(x / scale + 0.5), floor(y / scale + 0.5);
                lastRingX, lastRingY = x, y;
                frames.container:ClearAllPoints();
                frames.container:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y);
            end
        end);

    elseif (event == "PLAYER_LEAVING_WORLD") then
        DestroyFrames();

    elseif (event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED") then
        RefreshCombatCache();
        UpdateVisibility();
        UpdateTrailVisibility();

    elseif (event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START") then
        if (unit == "player" and db.castEnabled) then
            local startTime, endTime;
            if (event == "UNIT_SPELLCAST_CHANNEL_START") then
                _, _, _, startTime, endTime = UnitChannelInfo("player");
            else
                _, _, _, startTime, endTime = UnitCastingInfo("player");
            end
            if (startTime and endTime) then
                -- Cancel pending GCD timer
                if (gcdDelayTimer) then
                    gcdDelayTimer:Cancel();
                    gcdDelayTimer = nil;
                end

                isCasting = true;

                if (db.castStyle == "swipe" and frames.castCooldown) then
                    local dur = (endTime - startTime) / 1000;
                    local start = startTime / 1000;
                    local c = db.castColor;
                    frames.castCooldown:SetSwipeColor(c.r, c.g, c.b, 1);
                    frames.castCooldown:Show();
                    frames.castCooldown:SetCooldown(start, dur);
                else
                    StartCastTicker();
                end
            end
        end

    elseif (event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP"
            or event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED"
            or event == "UNIT_SPELLCAST_FAILED_QUIET") then
        if (unit == "player") then
            -- Don't stop if still casting/channeling
            if (UnitCastingInfo("player") or UnitChannelInfo("player")) then return; end
            StopCastTicker();
            isCasting = false;
        end

    elseif (event == "SPELL_UPDATE_COOLDOWN") then
        ProcessGCDUpdate();
    end
end

-------------------------------------------------------------------------------
-- Module Lifecycle
-------------------------------------------------------------------------------

function module:OnInit()
    getDB();
end

function module:OnEnable()
    getDB();
    RefreshCombatCache();

    local eventFrame = CreateFrame("Frame");
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
    eventFrame:RegisterEvent("PLAYER_LEAVING_WORLD");
    eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED");
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", "player");
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player");
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player");
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player");
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player");
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player");
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED_QUIET", "player");
    if (db.gcdEnabled) then
        eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN");
    end
    eventFrame:SetScript("OnEvent", OnEvent);
    self._eventFrame = eventFrame;

    -- Create frames if we're already in-world
    if (IsLoggedIn and IsLoggedIn()) then
        CreateFrames();
    end
end

function module:OnDisable()
    DestroyFrames();
    if (self._eventFrame) then
        self._eventFrame:UnregisterAllEvents();
        self._eventFrame:SetScript("OnEvent", nil);
        self._eventFrame = nil;
    end
end

-- Allow options to toggle GCD event registration
function module:SetGCDEnabled(enabled)
    if (self._eventFrame) then
        if (enabled) then
            self._eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN");
        else
            self._eventFrame:UnregisterEvent("SPELL_UPDATE_COOLDOWN");
            if (frames.gcdCooldown) then
                frames.gcdCooldown:Hide();
            end
            gcdActive = false;
        end
    end
end

Lantern:RegisterModule(module);
