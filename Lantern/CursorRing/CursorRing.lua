local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local module = Lantern:NewModule("CursorRing", {
    title = "Cursor Ring",
    desc = "Displays customizable ring(s) around the mouse cursor with cast/GCD indicators and an optional trail.",
    skipOptions = true,
    defaultEnabled = false,
});

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local ASSET_PATH = "Interface\\AddOns\\Lantern\\Media\\Images\\MouseRing\\";
local CAST_SEGMENTS = 36;
local TRAIL_MAX_POINTS = 20;
local TRAIL_UPDATE_INTERVAL = 0.025; -- 40Hz
local TRAIL_MOVE_THRESHOLD_SQ = 4;   -- 2px squared
local TRAIL_MAX_ALPHA = 0.8;
local GCD_SPELL_ID = 61304;
local GCD_SHOW_DELAY = 0.07;
local CAST_TICKER_INTERVAL = 0.033;  -- ~30fps
local ALPHA_CHECK_INTERVAL = 0.5;
local TEXCOORD_HALF = 0.5 / 256;
local TRAIL_TEXCOORD_HALF = 0.5 / 128;

local floor = math.floor;
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
    trailDuration = 0.4,
    trailColor = { r = 1.0, g = 1.0, b = 1.0 },
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
local trailHead = 0;
local trailCount = 0;
local trailActive = false;
local trailUpdateTimer = 0;
local lastTrailX, lastTrailY = 0, 0;
local lastRingX, lastRingY = 0, 0;

for i = 1, TRAIL_MAX_POINTS do
    trailBuf[i] = { x = 0, y = 0, time = 0, tex = nil, active = false };
end

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
        for i = 1, TRAIL_MAX_POINTS do
            local pt = trailBuf[i];
            if (pt.active and pt.tex) then
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

-- Exposed for Options.lua
function module:UpdateRing(ringNum) UpdateRingAppearance(ringNum); end
function module:UpdateDot() UpdateDotAppearance(); end
function module:UpdateGCD() UpdateGCDAppearance(); end
function module:UpdateCast() UpdateCastAppearance(); end
function module:UpdateVisibility()
    UpdateVisibility();
    UpdateTrailVisibility();
end

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
    for i = 1, TRAIL_MAX_POINTS do
        local tex = container:CreateTexture(nil, "BACKGROUND");
        tex:SetTexture(ASSET_PATH .. "trail_glow.tga", "CLAMP", "CLAMP", "TRILINEAR");
        tex:SetTexCoord(TRAIL_TEXCOORD_HALF, 1 - TRAIL_TEXCOORD_HALF, TRAIL_TEXCOORD_HALF, 1 - TRAIL_TEXCOORD_HALF);
        tex:SetBlendMode("ADD");
        tex:SetAlpha(0);
        tex:SetSize(24, 24);
        tex:Hide();
        trailBuf[i].tex = tex;
    end

    -- Trail OnUpdate
    container:SetScript("OnUpdate", function(_, elapsed)
        if (not db.trailEnabled or not trailActive) then return; end

        trailUpdateTimer = trailUpdateTimer + elapsed;
        if (trailUpdateTimer < TRAIL_UPDATE_INTERVAL) then return; end
        trailUpdateTimer = 0;

        local x, y = GetCursorPosition();
        local scale = UIParent:GetEffectiveScale();
        x, y = floor(x / scale + 0.5), floor(y / scale + 0.5);

        local now = GetTime();
        local opacity = GetCurrentOpacity();

        -- Add new point if moved enough
        local dx, dy = x - lastTrailX, y - lastTrailY;
        if (dx * dx + dy * dy >= TRAIL_MOVE_THRESHOLD_SQ) then
            lastTrailX, lastTrailY = x, y;
            trailHead = (trailHead % TRAIL_MAX_POINTS) + 1;
            local slot = trailBuf[trailHead];
            slot.x, slot.y, slot.time, slot.active = x, y, now, true;
            if (trailCount < TRAIL_MAX_POINTS) then trailCount = trailCount + 1; end
        end

        -- Update existing points
        local duration = db.trailDuration > 0 and db.trailDuration or 0.1;
        local invDuration = 1 / duration;
        local tc = db.trailColor;

        for i = 1, TRAIL_MAX_POINTS do
            local pt = trailBuf[i];
            if (pt.active and pt.tex) then
                local fade = 1 - ((now - pt.time) * invDuration);
                if (fade <= 0) then
                    pt.active = false;
                    trailCount = trailCount - 1;
                    pt.tex:Hide();
                else
                    pt.tex:ClearAllPoints();
                    pt.tex:SetPoint("CENTER", UIParent, "BOTTOMLEFT", pt.x, pt.y);
                    pt.tex:SetVertexColor(tc.r, tc.g, tc.b, fade * opacity * TRAIL_MAX_ALPHA);
                    local sz = 24 * fade;
                    pt.tex:SetSize(sz, sz);
                    pt.tex:Show();
                end
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
    local gcdCd = CreateFrame("Cooldown", nil, container);
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
    local castCd = CreateFrame("Cooldown", nil, container);
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
    for i = 1, TRAIL_MAX_POINTS do
        local pt = trailBuf[i];
        if (pt.tex) then pt.tex:Hide(); end
        pt.active = false;
    end
    trailHead = 0;
    trailCount = 0;
    trailActive = false;

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
