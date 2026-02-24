local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local module = Lantern.modules["CursorRing"];
if (not module) then return; end

-------------------------------------------------------------------------------
-- Bridge accessors (set by CursorRing.lua before this file loads)
-------------------------------------------------------------------------------

local ASSET_PATH = module._assetPath;

local function db()       return module._db(); end
local function frames()   return module._frames(); end
local function ShouldShow()       return module._shouldShow(); end
local function GetCurrentOpacity() return module._getOpacity(); end
local function GetPlayerClassColor() return module._classColor(); end

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local TRAIL_UPDATE_INTERVAL = 0.016; -- ~60Hz
local TRAIL_MOVE_THRESHOLD_SQ = 4;   -- 2px squared
local TRAIL_MAX_ALPHA = 0.8;

local SPARKLE_POOL_SIZE = 40;
local SPARKLE_DURATION = 0.4;
local SPARKLE_SIZE_MIN = 6;
local SPARKLE_SIZE_MAX = 18;
local SPARKLE_OFFSET = 10;       -- random offset range from trail dot
local SPARKLE_CHANCE = 0.30;     -- 30% chance per trail dot placed
local SPARKLE_DRIFT_Y = 18;     -- upward drift in px over lifetime
local SPARKLE_TWINKLE_SPEED = 14; -- sine oscillation speed

local TRAIL_TEXCOORD_HALF = 0.5 / 128;

local floor = math.floor;
local sqrt = math.sqrt;
local max = math.max;

-------------------------------------------------------------------------------
-- Presets
-------------------------------------------------------------------------------

local TRAIL_STYLE_PRESETS = {
    glow      = { maxPoints = 20, dotSize = 24, dotSpacing = 2, shrink = true,  shrinkDistance = false },
    line      = { maxPoints = 60, dotSize = 12, dotSpacing = 1, shrink = false, shrinkDistance = true },
    thickline = { maxPoints = 60, dotSize = 22, dotSpacing = 1, shrink = false, shrinkDistance = true },
    dots      = { maxPoints = 12, dotSize = 18, dotSpacing = 8, shrink = true,  shrinkDistance = false },
};

local TRAIL_COLOR_PRESETS = {
    -- custom and class are resolved dynamically
    gold   = { r = 1.0,  g = 0.66, b = 0.0  },
    arcane = { r = 0.64, g = 0.21, b = 0.93 },
    fel    = { r = 0.0,  g = 0.9,  b = 0.1  },
    fire   = { r = 1.0,  g = 0.3,  b = 0.0  },
    frost  = { r = 0.5,  g = 0.8,  b = 1.0  },
    holy   = { r = 1.0,  g = 0.9,  b = 0.5  },
    shadow = { r = 0.5,  g = 0.0,  b = 0.8  },
};

-- Multi-color presets: gradient from -> to, or special "rainbow" HSV cycle
local TRAIL_GRADIENT_PRESETS = {
    rainbow = true,
    alar    = { from = { r = 1.0, g = 0.55, b = 0.05 }, to = { r = 0.95, g = 0.05, b = 0.65 } },
    ember   = { from = { r = 1.0, g = 0.95, b = 0.3 }, to = { r = 0.8, g = 0.1, b = 0.0 } },
    ocean   = { from = { r = 0.3, g = 1.0, b = 1.0 }, to = { r = 0.0, g = 0.15, b = 0.7 } },
};

-- Export presets for WidgetOptions.lua
module.TRAIL_STYLE_PRESETS = TRAIL_STYLE_PRESETS;
module.TRAIL_COLOR_PRESETS = TRAIL_COLOR_PRESETS;

-------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------

local trailBuf = {};
local trailPoolSize = 0;
local trailHead = 0;
local trailCount = 0;
local trailActive = false;
local trailUpdateTimer = 0;
local lastTrailX, lastTrailY = 0, 0;
local rainbowHueOffset = 0;
local trailDormant = false;
local trailLastUpdateTime = nil;
local sparkleBuf = {};
local sparkleHead = 0;

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function ResolveTrailColor()
    local d = db();
    local preset = d.trailColorPreset;
    if (preset == "class") then
        return GetPlayerClassColor();
    end
    local static = TRAIL_COLOR_PRESETS[preset];
    if (static) then
        return static;
    end
    return d.trailColor;
end

local function HSVtoRGB(h, s, v)
    local i = floor(h * 6);
    local f = h * 6 - i;
    local p = v * (1 - s);
    local q = v * (1 - f * s);
    local t = v * (1 - (1 - f) * s);
    local m = i % 6;
    if (m == 0) then return v, t, p; end
    if (m == 1) then return q, v, p; end
    if (m == 2) then return p, v, t; end
    if (m == 3) then return p, q, v; end
    if (m == 4) then return t, p, v; end
    return v, p, q;
end

-- t: 0 = head (newest), 1 = tail (oldest)
local function ResolveGradientColor(preset, t)
    if (preset == "rainbow") then
        return HSVtoRGB((t * 0.83 + rainbowHueOffset) % 1, 1, 1);
    end
    local grad = TRAIL_GRADIENT_PRESETS[preset];
    if (grad) then
        local a, b = grad.from, grad.to;
        return a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t;
    end
    return 1, 1, 1;
end

-------------------------------------------------------------------------------
-- Pool & Frame Management
-------------------------------------------------------------------------------

local function EnsureTrailPool(count)
    local f = frames();
    local d = db();
    if (not f.trailContainer) then return; end

    -- Grow pool if needed
    for i = trailPoolSize + 1, count do
        local tex = f.trailContainer:CreateTexture(nil, "BACKGROUND");
        tex:SetTexture(ASSET_PATH .. "trail_glow.tga", "CLAMP", "CLAMP", "TRILINEAR");
        tex:SetTexCoord(TRAIL_TEXCOORD_HALF, 1 - TRAIL_TEXCOORD_HALF, TRAIL_TEXCOORD_HALF, 1 - TRAIL_TEXCOORD_HALF);
        tex:SetBlendMode("ADD");
        tex:SetSize(d.trailDotSize or 24, d.trailDotSize or 24);
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

local function ResetTrailState()
    for i = 1, trailPoolSize do
        local pt = trailBuf[i];
        if (pt) then
            pt.active = false;
            if (pt.tex) then pt.tex:Hide(); end
        end
    end
    for i = 1, SPARKLE_POOL_SIZE do
        local sp = sparkleBuf[i];
        if (sp) then
            sp.active = false;
            if (sp.tex) then sp.tex:Hide(); end
        end
    end
    trailHead = 0;
    trailCount = 0;
    sparkleHead = 0;
    trailDormant = false;
    trailLastUpdateTime = nil;
end

local function CreateTrailFrame()
    local f = frames();
    local d = db();
    if (f.trailContainer) then return; end

    local container = CreateFrame("Frame", "LanternCursorRingTrail", UIParent);
    container:SetSize(1, 1);
    container:SetFrameStrata("TOOLTIP");
    container:SetFrameLevel(1);
    container:EnableMouse(false);
    container:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0);
    f.trailContainer = container;

    -- Create pooled trail textures
    local poolCount = d.trailMaxPoints or 20;
    EnsureTrailPool(poolCount);

    -- Create sparkle pool
    for i = 1, SPARKLE_POOL_SIZE do
        local tex = container:CreateTexture(nil, "BACKGROUND");
        tex:SetTexture(ASSET_PATH .. "trail_glow.tga", "CLAMP", "CLAMP", "TRILINEAR");
        tex:SetTexCoord(TRAIL_TEXCOORD_HALF, 1 - TRAIL_TEXCOORD_HALF, TRAIL_TEXCOORD_HALF, 1 - TRAIL_TEXCOORD_HALF);
        tex:SetBlendMode("ADD");
        tex:Hide();
        sparkleBuf[i] = { x = 0, y = 0, time = 0, size = 4, r = 1, g = 1, b = 1, tex = tex, active = false };
    end

    -- Trail OnUpdate
    container:SetScript("OnUpdate", function(_, elapsed)
        local d = db();
        if (not d.trailEnabled or not trailActive) then return; end

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
            -- Don't update lastTrailX/Y here -- let the emission code below
            -- see the full distance from the pre-dormant position and emit naturally
            trailDormant = false;
        end

        local opacity = GetCurrentOpacity();
        local spacing = d.trailDotSpacing or 2;
        local spacingSq = spacing * spacing;
        local dotSize = d.trailDotSize or 24;
        local shouldShrink = d.trailShrink;
        local shrinkDist = d.trailShrinkDistance;
        local anyShrink = shouldShrink or shrinkDist;

        -- Resolve trail color once (used by emission and update)
        local tc = ResolveTrailColor();
        local gradientPreset = TRAIL_GRADIENT_PRESETS[d.trailColorPreset] and d.trailColorPreset or nil;

        -- Emit dots along the path -- interpolate to fill gaps during fast movement
        local dx, dy = x - lastTrailX, y - lastTrailY;
        local distSq = dx * dx + dy * dy;
        if (distSq >= spacingSq) then
            local dist = sqrt(distSq);
            local n = floor(dist / spacing);
            if (n > maxPts) then n = maxPts; end -- cap to pool size
            local ux, uy = dx / dist, dy / dist;
            local sparkleEnabled = d.trailSparkle ~= "off" and sparkleBuf[1];
            local sparkleColor;
            if (sparkleEnabled) then
                if (gradientPreset) then
                    local sr, sg, sb = ResolveGradientColor(gradientPreset, 0);
                    sparkleColor = { sr, sg, sb };
                else
                    sparkleColor = { tc.r, tc.g, tc.b };
                end
            end

            for s = 1, n do
                local px = lastTrailX + ux * spacing * s;
                local py = lastTrailY + uy * spacing * s;
                trailHead = (trailHead % maxPts) + 1;
                local slot = trailBuf[trailHead];
                slot.x, slot.y, slot.time, slot.active = px, py, now, true;
                if (trailCount < maxPts) then trailCount = trailCount + 1; end
                rainbowHueOffset = rainbowHueOffset + 0.001;
                local tex = slot.tex;
                if (tex) then
                    tex:ClearAllPoints();
                    tex:SetPoint("CENTER", UIParent, "BOTTOMLEFT", px, py);
                end

                -- Sparkle emission
                if (sparkleEnabled and math.random() < SPARKLE_CHANCE) then
                    sparkleHead = (sparkleHead % SPARKLE_POOL_SIZE) + 1;
                    local sp = sparkleBuf[sparkleHead];
                    local sx = px + (math.random() * 2 - 1) * SPARKLE_OFFSET;
                    local sy = py + (math.random() * 2 - 1) * SPARKLE_OFFSET;
                    local sz = SPARKLE_SIZE_MIN + math.random() * (SPARKLE_SIZE_MAX - SPARKLE_SIZE_MIN);
                    sp.x, sp.y, sp.time, sp.active = sx, sy, now, true;
                    sp.size = sz;
                    sp.r, sp.g, sp.b = sparkleColor[1], sparkleColor[2], sparkleColor[3];
                    local stex = sp.tex;
                    if (stex) then
                        stex:SetSize(sz, sz);
                        stex:ClearAllPoints();
                        stex:SetPoint("CENTER", UIParent, "BOTTOMLEFT", sx, sy);
                    end
                end
            end
            lastTrailX = lastTrailX + ux * spacing * n;
            lastTrailY = lastTrailY + uy * spacing * n;
        end

        -- Update existing points (alpha + size only, no repositioning)
        local dur = d.trailDuration > 0 and d.trailDuration or 0.1;
        local invDur = 1 / dur;
        local anyActive = false;

        -- Walk ring buffer head-to-tail to assign distance ranks
        -- rank 1 = newest (near cursor), rank N = oldest (tail end)
        local visibleCount = 0;
        if (shrinkDist or gradientPreset) then
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
                    if (gradientPreset) then
                        local t = (visibleCount > 1) and ((rank - 1) / (visibleCount - 1)) or 0;
                        local gr, gg, gb = ResolveGradientColor(gradientPreset, t);
                        pt.tex:SetVertexColor(gr, gg, gb, alpha);
                    else
                        pt.tex:SetVertexColor(tc.r, tc.g, tc.b, alpha);
                    end

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

        -- Update sparkles
        local sparkleMode = d.trailSparkle;
        if (sparkleMode ~= "off") then
            local invSpkDur = 1 / SPARKLE_DURATION;
            local isTwinkle = (sparkleMode == "twinkle");
            for i = 1, SPARKLE_POOL_SIZE do
                local sp = sparkleBuf[i];
                if (sp and sp.active) then
                    local age = now - sp.time;
                    if (age >= SPARKLE_DURATION) then
                        sp.active = false;
                        sp.tex:Hide();
                    else
                        anyActive = true;
                        local t = age * invSpkDur; -- 0->1 over lifetime
                        local fade = (1 - t) * (1 - t); -- quadratic fade-out
                        local alpha;

                        if (isTwinkle) then
                            local twinkle = 0.5 + 0.5 * math.sin(age * SPARKLE_TWINKLE_SPEED);
                            alpha = fade * twinkle * opacity;
                            sp.tex:ClearAllPoints();
                            sp.tex:SetPoint("CENTER", UIParent, "BOTTOMLEFT", sp.x, sp.y + t * SPARKLE_DRIFT_Y);
                        else
                            alpha = fade * opacity;
                        end

                        sp.tex:SetVertexColor(sp.r, sp.g, sp.b, alpha);
                        sp.tex:Show();
                    end
                end
            end
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

-------------------------------------------------------------------------------
-- Module API (called by CursorRing.lua and WidgetOptions.lua)
-------------------------------------------------------------------------------

function module:UpdateTrailVisibility()
    local d = db();
    trailActive = d.trailEnabled and ShouldShow();
    if (not trailActive) then
        for i = 1, trailPoolSize do
            local pt = trailBuf[i];
            if (pt and pt.active and pt.tex) then
                pt.tex:Hide();
            end
        end
    end
end

function module:UpdateTrail()
    local f = frames();
    local d = db();
    if (not f.trailContainer) then return; end
    local newSize = d.trailMaxPoints or 20;
    if (newSize ~= trailPoolSize) then
        EnsureTrailPool(newSize);
    end
    -- Update dot sizes for non-shrink styles (shrink styles set size in OnUpdate)
    local dotSize = d.trailDotSize or 24;
    for i = 1, trailPoolSize do
        local pt = trailBuf[i];
        if (pt and pt.tex) then
            pt.tex:SetSize(dotSize, dotSize);
        end
    end
end

function module:EnsureTrail()
    local f = frames();
    local d = db();
    if (not f.trailContainer and d.trailEnabled) then
        CreateTrailFrame();
        local x, y = GetCursorPosition();
        local scale = UIParent:GetEffectiveScale();
        lastTrailX, lastTrailY = x / scale, y / scale;
    end
    self:UpdateTrailVisibility();
end

function module:CreateTrailIfEnabled()
    local d = db();
    if (d.trailEnabled) then
        CreateTrailFrame();
        local x, y = GetCursorPosition();
        local scale = UIParent:GetEffectiveScale();
        lastTrailX, lastTrailY = x / scale, y / scale;
    end
end

function module:DestroyTrail()
    local f = frames();
    if (f.trailContainer) then
        f.trailContainer:SetScript("OnUpdate", nil);
        f.trailContainer:Hide();
    end

    -- Clear trail state
    for i = 1, trailPoolSize do
        local pt = trailBuf[i];
        if (pt) then
            if (pt.tex) then pt.tex:Hide(); end
            pt.active = false;
        end
    end
    for i = 1, SPARKLE_POOL_SIZE do
        local sp = sparkleBuf[i];
        if (sp) then
            if (sp.tex) then sp.tex:Hide(); end
            sp.active = false;
        end
    end
    trailHead = 0;
    trailCount = 0;
    sparkleHead = 0;
    trailPoolSize = 0;
    trailActive = false;
    trailDormant = false;
    trailLastUpdateTime = nil;

    f.trailContainer = nil;
end
