local ADDON_NAME, addon = ...;

addon.textAnimations = addon.textAnimations or {};

local TextAnimations = addon.textAnimations;

-- Registry of available animation styles
local animations = {};

-- Math helpers for smooth interpolation
local sin = math.sin;
local pi = math.pi;

-------------------------------------------------------------------------------
-- Animation Registration
-------------------------------------------------------------------------------

function addon:RegisterTextAnimation(name, setupFn)
    if (not name or type(setupFn) ~= "function") then return; end
    animations[name] = setupFn;
end

function addon:GetTextAnimationList()
    local list = {};
    for name in pairs(animations) do
        table.insert(list, name);
    end
    table.sort(list);
    return list;
end

function addon:ApplyTextAnimation(fontString, animationName)
    if (not fontString) then return; end

    -- Stop any existing animation first
    self:StopTextAnimation(fontString);

    local setupFn = animations[animationName];
    if (not setupFn) then return; end

    local result = setupFn(fontString);
    if (result) then
        -- Can be either an AnimationGroup or a frame with OnUpdate
        fontString._lanternAnimGroup = result;
        if (result.Play) then
            result:Play();
        elseif (result.Show) then
            result:Show();
        end
    end
end

function addon:StopTextAnimation(fontString)
    if (not fontString) then return; end
    if (fontString._lanternAnimGroup) then
        local anim = fontString._lanternAnimGroup;
        if (anim.Stop) then
            anim:Stop();
        end
        if (anim.Hide) then
            anim:Hide();
        end
        if (anim.SetScript) then
            anim:SetScript("OnUpdate", nil);
        end
        fontString._lanternAnimGroup = nil;
    end
    -- Reset any transforms
    fontString:SetAlpha(1);
    if (fontString.SetScale) then
        fontString:SetScale(1);
    end
end

-------------------------------------------------------------------------------
-- Built-in Animations
-------------------------------------------------------------------------------

-- None - static text, no animation
addon:RegisterTextAnimation("none", function(fontString)
    return nil;
end);

-- Bounce - vertical bouncing motion
addon:RegisterTextAnimation("bounce", function(fontString)
    local parent = fontString:GetParent();
    if (not parent) then return nil; end

    local animGroup = fontString:CreateAnimationGroup();
    animGroup:SetLooping("REPEAT");

    local moveUp = animGroup:CreateAnimation("Translation");
    moveUp:SetOffset(0, 8);
    moveUp:SetDuration(0.3);
    moveUp:SetOrder(1);
    moveUp:SetSmoothing("OUT");

    local moveDown = animGroup:CreateAnimation("Translation");
    moveDown:SetOffset(0, -8);
    moveDown:SetDuration(0.3);
    moveDown:SetOrder(2);
    moveDown:SetSmoothing("IN");

    return animGroup;
end);

-- Pulse - smooth scale up/down using OnUpdate for 60fps interpolation
addon:RegisterTextAnimation("pulse", function(fontString)
    local frame = CreateFrame("Frame");
    local elapsed = 0;
    local duration = 1.5; -- Full cycle duration
    local minScale = 1.0;
    local maxScale = 1.12;

    frame:SetScript("OnUpdate", function(self, delta)
        elapsed = elapsed + delta;
        -- Sine wave for smooth oscillation: 0 to 1 to 0
        local progress = (sin((elapsed / duration) * pi * 2 - pi / 2) + 1) / 2;
        local scale = minScale + (maxScale - minScale) * progress;
        fontString:SetScale(scale);
    end);

    return frame;
end);

-- Fade - fade in/out
addon:RegisterTextAnimation("fade", function(fontString)
    local frame = CreateFrame("Frame");
    local elapsed = 0;
    local duration = 1.6; -- Full cycle duration
    local minAlpha = 0.35;
    local maxAlpha = 1.0;

    frame:SetScript("OnUpdate", function(self, delta)
        elapsed = elapsed + delta;
        local progress = (sin((elapsed / duration) * pi * 2 - pi / 2) + 1) / 2;
        local alpha = minAlpha + (maxAlpha - minAlpha) * progress;
        fontString:SetAlpha(alpha);
    end);

    return frame;
end);

-- Shake - horizontal shake
addon:RegisterTextAnimation("shake", function(fontString)
    local animGroup = fontString:CreateAnimationGroup();
    animGroup:SetLooping("REPEAT");

    local shakeLeft = animGroup:CreateAnimation("Translation");
    shakeLeft:SetOffset(-4, 0);
    shakeLeft:SetDuration(0.05);
    shakeLeft:SetOrder(1);

    local shakeRight = animGroup:CreateAnimation("Translation");
    shakeRight:SetOffset(8, 0);
    shakeRight:SetDuration(0.1);
    shakeRight:SetOrder(2);

    local shakeBack = animGroup:CreateAnimation("Translation");
    shakeBack:SetOffset(-4, 0);
    shakeBack:SetDuration(0.05);
    shakeBack:SetOrder(3);

    local pause = animGroup:CreateAnimation("Translation");
    pause:SetOffset(0, 0);
    pause:SetDuration(0.8);
    pause:SetOrder(4);

    return animGroup;
end);

-- Glow - smooth pulse with alpha using OnUpdate for 60fps interpolation
addon:RegisterTextAnimation("glow", function(fontString)
    local frame = CreateFrame("Frame");
    local elapsed = 0;
    local duration = 1.8; -- Full cycle duration
    local minScale = 1.0;
    local maxScale = 1.08;
    local minAlpha = 0.7;
    local maxAlpha = 1.0;

    frame:SetScript("OnUpdate", function(self, delta)
        elapsed = elapsed + delta;
        local progress = (sin((elapsed / duration) * pi * 2 - pi / 2) + 1) / 2;
        local scale = minScale + (maxScale - minScale) * progress;
        local alpha = minAlpha + (maxAlpha - minAlpha) * progress;
        fontString:SetScale(scale);
        fontString:SetAlpha(alpha);
    end);

    return frame;
end);

-- Heartbeat - double pulse like a heartbeat
addon:RegisterTextAnimation("heartbeat", function(fontString)
    local frame = CreateFrame("Frame");
    local elapsed = 0;
    local cycleDuration = 1.2;

    frame:SetScript("OnUpdate", function(self, delta)
        elapsed = elapsed + delta;
        local cyclePos = (elapsed % cycleDuration) / cycleDuration;

        local scale = 1.0;
        -- First beat at 0-0.15
        if (cyclePos < 0.15) then
            local t = cyclePos / 0.15;
            scale = 1.0 + 0.15 * sin(t * pi);
        -- Second beat at 0.2-0.35
        elseif (cyclePos >= 0.2 and cyclePos < 0.35) then
            local t = (cyclePos - 0.2) / 0.15;
            scale = 1.0 + 0.1 * sin(t * pi);
        end

        fontString:SetScale(scale);
    end);

    return frame;
end);
