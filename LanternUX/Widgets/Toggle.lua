local ADDON_NAME = ...;

local _W = LanternUX._W;
local T = _W.T;
local AcquireWidget = _W.AcquireWidget;
local RegisterWidget = _W.RegisterWidget;
local ShowDescription = _W.ShowDescription;
local ClearDescription = _W.ClearDescription;
local EvalDisabled = _W.EvalDisabled;
local RefreshActiveWidgets = _W.RefreshActiveWidgets;
local NextName = _W.NextName;

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local TRACK_W    = 34;   -- Track width (pill shape)
local TRACK_H    = 18;   -- Track height
local THUMB_SIZE = 14;   -- Thumb square inside track
local THUMB_PAD  = 2;    -- Inset from track edge
local TOGGLE_PAD = 8;    -- Space between switch and label
local ANIM_SPEED = 8;    -- Lerp speed multiplier (~150ms feel)

local SLIDE_RANGE = TRACK_W - THUMB_SIZE - 2 * THUMB_PAD;  -- 16px

-------------------------------------------------------------------------------
-- Create / Setup
-------------------------------------------------------------------------------

local function CreateToggle(parent)
    local w = AcquireWidget("toggle", parent);
    if (w) then return w; end

    w = {};
    local frame = CreateFrame("Button", NextName("LUX_Toggle_"), parent);
    frame:SetHeight(TRACK_H + 4);
    w.frame = frame;

    -- Track (pill background)
    local track = CreateFrame("Frame", NextName("LUX_ToggleTrack_"), frame, "BackdropTemplate");
    track:SetSize(TRACK_W, TRACK_H);
    track:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -2);
    track:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    });
    track:SetBackdropColor(unpack(T.toggleTrack));
    track:SetBackdropBorderColor(unpack(T.checkBorder));
    w._track = track;

    -- Thumb (small square that slides inside track)
    local thumb = CreateFrame("Frame", NextName("LUX_ToggleThumb_"), track);
    thumb:SetSize(THUMB_SIZE, THUMB_SIZE);
    thumb:SetPoint("LEFT", track, "LEFT", THUMB_PAD, 0);

    local thumbBg = thumb:CreateTexture(nil, "ARTWORK");
    thumbBg:SetAllPoints();
    thumbBg:SetColorTexture(unpack(T.toggleThumb));
    w._thumb = thumb;
    w._thumbBg = thumbBg;

    -- Label
    local label = frame:CreateFontString(nil, "ARTWORK", T.fontBody);
    label:SetPoint("LEFT", track, "RIGHT", TOGGLE_PAD, 0);
    label:SetJustifyH("LEFT");
    label:SetTextColor(unpack(T.text));
    w._label = label;

    -- State
    w._checked = false;
    w._disabled = false;
    w._thumbPos = 0;      -- 0 = OFF (left), 1 = ON (right)
    w._thumbTarget = 0;

    -- Helper: position thumb based on _thumbPos
    local function PositionThumb()
        local xOffset = THUMB_PAD + w._thumbPos * SLIDE_RANGE;
        thumb:ClearAllPoints();
        thumb:SetPoint("LEFT", track, "LEFT", xOffset, 0);
    end
    w._positionThumb = PositionThumb;

    -- Helper: apply track/thumb colors for current checked state
    local function ApplyColors()
        if (w._disabled) then
            track:SetBackdropColor(unpack(T.toggleTrackDis));
            track:SetBackdropBorderColor(unpack(T.disabled));
            thumbBg:SetColorTexture(unpack(T.toggleThumbDis));
            label:SetTextColor(unpack(T.disabledText));
        elseif (w._checked) then
            track:SetBackdropColor(unpack(T.toggleTrackOn));
            thumbBg:SetColorTexture(unpack(T.toggleThumbOn));
            label:SetTextColor(unpack(T.text));
        else
            track:SetBackdropColor(unpack(T.toggleTrack));
            thumbBg:SetColorTexture(unpack(T.toggleThumb));
            label:SetTextColor(unpack(T.text));
        end
    end
    w._applyColors = ApplyColors;

    -- Slide animation (OnUpdate lerp on frame)
    local function OnUpdate_Slide(self, elapsed)
        local blend = math.min(1, ANIM_SPEED * elapsed);
        w._thumbPos = w._thumbPos + (w._thumbTarget - w._thumbPos) * blend;
        if (math.abs(w._thumbPos - w._thumbTarget) < 0.01) then
            w._thumbPos = w._thumbTarget;
            self:SetScript("OnUpdate", nil);
        end
        PositionThumb();
    end
    w._onUpdateSlide = OnUpdate_Slide;

    -- Hover
    frame:SetScript("OnEnter", function()
        if (not w._disabled) then
            track:SetBackdropBorderColor(unpack(T.checkHover));
        end
        ShowDescription(w._label:GetText(), w._desc_text);
    end);
    frame:SetScript("OnLeave", function()
        if (not w._disabled) then
            track:SetBackdropBorderColor(unpack(T.checkBorder));
        end
        ClearDescription();
    end);

    -- Click
    frame:SetScript("OnClick", function()
        if (w._disabled) then return; end
        w._checked = not w._checked;
        w._thumbTarget = w._checked and 1 or 0;
        -- Instant color swap, animated position
        ApplyColors();
        frame:SetScript("OnUpdate", OnUpdate_Slide);
        if (w._onSet) then
            w._onSet(w._checked);
        end
        -- Refresh all widgets so disabled states update immediately
        C_Timer.After(0, RefreshActiveWidgets);
    end);

    RegisterWidget("toggle", w);
    return w;
end

local function SetupToggle(w, parent, data, contentWidth)
    w.frame:SetParent(parent);
    w.frame:SetWidth(contentWidth);

    -- Label
    w._label:SetText(data.label or "");

    -- Description (shown in right panel on hover)
    w._desc_text = data.desc;
    w.frame:SetHeight(TRACK_H + 4);
    w.height = TRACK_H + 4;

    -- Checked state
    local checked = false;
    if (data.get) then
        checked = data.get();
    end
    w._checked = checked;

    -- Snap thumb to position (no animation on setup)
    w._thumbPos = checked and 1 or 0;
    w._thumbTarget = w._thumbPos;
    w._positionThumb();
    w.frame:SetScript("OnUpdate", nil);

    -- Store callbacks for refresh
    w._getFn = data.get;
    w._onSet = data.set;
    w._disabledFn = data.disabled;

    -- Disabled state
    local disabled = false;
    if (data.disabled) then
        if (type(data.disabled) == "function") then
            disabled = data.disabled();
        else
            disabled = data.disabled;
        end
    end
    w._disabled = disabled;

    -- Apply colors
    w._applyColors();

    -- Reset border (not hovered during setup)
    if (disabled) then
        w._track:SetBackdropBorderColor(unpack(T.disabled));
    else
        w._track:SetBackdropBorderColor(unpack(T.checkBorder));
    end

    return w;
end

-------------------------------------------------------------------------------
-- Register
-------------------------------------------------------------------------------

_W.factories.toggle = { create = CreateToggle, setup = SetupToggle };

_W.refreshers.toggle = function(w)
    if (w._getFn) then
        local newChecked = w._getFn();
        if (newChecked ~= w._checked) then
            w._checked = newChecked;
            -- Snap position on refresh (no animation)
            w._thumbPos = newChecked and 1 or 0;
            w._thumbTarget = w._thumbPos;
            w._positionThumb();
            w.frame:SetScript("OnUpdate", nil);
        end
    end
    local disabled = EvalDisabled(w);
    w._applyColors();
    if (disabled) then
        w._track:SetBackdropBorderColor(unpack(T.disabled));
    else
        w._track:SetBackdropBorderColor(unpack(T.checkBorder));
    end
end;
