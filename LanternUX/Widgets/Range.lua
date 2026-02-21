local ADDON_NAME = ...;

local _W = LanternUX._W;
local T = _W.T;
local AcquireWidget = _W.AcquireWidget;
local RegisterWidget = _W.RegisterWidget;
local ShowDescription = _W.ShowDescription;
local ClearDescription = _W.ClearDescription;
local ClampValue = _W.ClampValue;
local FormatValue = _W.FormatValue;
local EvalDisabled = _W.EvalDisabled;
local RefreshActiveWidgets = _W.RefreshActiveWidgets;
local NextName = _W.NextName;

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local RANGE_HEIGHT    = 44;
local TRACK_HEIGHT    = 6;
local THUMB_SIZE      = 18;
local RANGE_LABEL_H   = 18;
local RANGE_TRACK_PAD = 4;

-------------------------------------------------------------------------------
-- Create / Setup
-------------------------------------------------------------------------------

local function CreateRange(parent)
    local w = AcquireWidget("range", parent);
    if (w) then return w; end

    w = {};
    local frame = CreateFrame("Frame", NextName("LUX_Range_"), parent);
    frame:SetHeight(RANGE_HEIGHT);
    frame:EnableMouse(true);
    w.frame = frame;

    -- Label (left)
    local label = frame:CreateFontString(nil, "ARTWORK", T.fontBody);
    label:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0);
    label:SetJustifyH("LEFT");
    label:SetTextColor(unpack(T.text));
    w._label = label;

    -- Value text (right)
    local valueText = frame:CreateFontString(nil, "ARTWORK", T.fontBody);
    valueText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0);
    valueText:SetJustifyH("RIGHT");
    valueText:SetTextColor(unpack(T.textDim));
    w._valueText = valueText;

    -- Description panel on hover
    frame:SetScript("OnEnter", function()
        ShowDescription(w._label:GetText(), w._desc_text);
    end);
    frame:SetScript("OnLeave", ClearDescription);

    -- Track background
    local trackFrame = CreateFrame("Frame", NextName("LUX_RangeTrack_"), frame);
    trackFrame:SetHeight(TRACK_HEIGHT);
    trackFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -(RANGE_LABEL_H + RANGE_TRACK_PAD));
    trackFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -(RANGE_LABEL_H + RANGE_TRACK_PAD));
    w._trackFrame = trackFrame;

    local trackBg = trackFrame:CreateTexture(nil, "BACKGROUND");
    trackBg:SetAllPoints();
    trackBg:SetColorTexture(unpack(T.trackBg));
    w._trackBg = trackBg;

    -- Filled portion
    local fill = trackFrame:CreateTexture(nil, "BORDER");
    fill:SetHeight(TRACK_HEIGHT);
    fill:SetPoint("TOPLEFT", trackFrame, "TOPLEFT");
    fill:SetColorTexture(unpack(T.accent));
    w._fill = fill;

    -- Thumb
    local thumb = CreateFrame("Frame", NextName("LUX_RangeThumb_"), trackFrame);
    thumb:SetSize(THUMB_SIZE, THUMB_SIZE);
    thumb:SetFrameLevel(trackFrame:GetFrameLevel() + 2);

    local thumbBg = thumb:CreateTexture(nil, "ARTWORK");
    thumbBg:SetAllPoints();
    thumbBg:SetColorTexture(unpack(T.thumbBg));
    w._thumb = thumb;
    w._thumbBg = thumbBg;

    -- Default marker (subtle tick on the track)
    local defaultMark = trackFrame:CreateTexture(nil, "ARTWORK");
    defaultMark:SetSize(2, TRACK_HEIGHT + 6);
    defaultMark:SetColorTexture(unpack(T.textDim));
    defaultMark:SetAlpha(0.5);
    defaultMark:Hide();
    w._defaultMark = defaultMark;

    -- State
    w._value = 0;
    w._min = 0;
    w._max = 1;
    w._step = 0.01;
    w._isPercent = false;
    w._disabled = false;
    w._dragging = false;

    -- Helper: update visuals from current value
    local function UpdateThumbPosition()
        local trackWidth = trackFrame:GetWidth();
        if (trackWidth <= 0) then return; end
        local range = w._max - w._min;
        if (range <= 0) then return; end
        local ratio = (w._value - w._min) / range;
        local xPos = ratio * (trackWidth - THUMB_SIZE);
        thumb:ClearAllPoints();
        thumb:SetPoint("LEFT", trackFrame, "LEFT", xPos, 0);
        w._fill:SetWidth(math.max(1, xPos + THUMB_SIZE / 2));
        w._valueText:SetText(FormatValue(w._value, w._isPercent));
    end
    w._updateThumb = UpdateThumbPosition;

    -- Helper: set value from mouse x position
    local function SetValueFromX(x)
        if (w._disabled) then return; end
        local trackWidth = trackFrame:GetWidth();
        if (trackWidth <= 0) then return; end
        local ratio = math.max(0, math.min(1, (x - THUMB_SIZE / 2) / (trackWidth - THUMB_SIZE)));
        local raw = w._min + ratio * (w._max - w._min);
        local step = w._dragging and w._step or (w._bigStep or w._step);
        local clamped = ClampValue(raw, w._min, w._max, step);
        if (clamped ~= w._value) then
            w._value = clamped;
            UpdateThumbPosition();
            if (w._onSet) then w._onSet(clamped); end
            C_Timer.After(0, RefreshActiveWidgets);
        end
    end

    -- Helper: get cursor x relative to the track frame
    local function GetTrackRelativeX()
        local cursorX = GetCursorPosition();
        local scale = trackFrame:GetEffectiveScale();
        local left = trackFrame:GetLeft();
        if (not left) then return 0; end
        return (cursorX / scale) - left;
    end

    -- Drag handling on the track frame (covers both thumb and track clicks)
    local dragFrame = CreateFrame("Frame", NextName("LUX_RangeDrag_"), trackFrame);
    dragFrame:SetAllPoints(trackFrame);
    dragFrame:SetFrameLevel(trackFrame:GetFrameLevel() + 3);
    dragFrame:EnableMouse(true);

    dragFrame:SetScript("OnMouseDown", function(self, button)
        if (button ~= "LeftButton" or w._disabled) then return; end
        w._dragging = true;
        SetValueFromX(GetTrackRelativeX());
        -- Track on the main frame so dragging works even when cursor leaves the track
        frame:SetScript("OnUpdate", function()
            if (not w._dragging or not IsMouseButtonDown("LeftButton")) then
                w._dragging = false;
                frame:SetScript("OnUpdate", nil);
                return;
            end
            SetValueFromX(GetTrackRelativeX());
        end);
    end);

    dragFrame:SetScript("OnMouseUp", function(self, button)
        if (button ~= "LeftButton") then return; end
        w._dragging = false;
        frame:SetScript("OnUpdate", nil);
    end);

    -- Hover on track/thumb
    dragFrame:SetScript("OnEnter", function()
        if (not w._disabled) then
            w._thumbBg:SetColorTexture(unpack(T.thumbHover));
        end
        ShowDescription(w._label:GetText(), w._desc_text);
    end);
    dragFrame:SetScript("OnLeave", function()
        if (not w._disabled) then
            w._thumbBg:SetColorTexture(unpack(T.thumbBg));
        end
        ClearDescription();
        -- Don't stop dragging on leave -- OnUpdate checks IsMouseButtonDown
    end);

    dragFrame:EnableMouseWheel(false);

    RegisterWidget("range", w);
    return w;
end

local function SetupRange(w, parent, data, contentWidth)
    w.frame:SetParent(parent);
    w.frame:SetWidth(contentWidth);

    w._label:SetText(data.label or "");
    w._min = data.min or 0;
    w._max = data.max or 1;
    w._step = data.step or 0.01;
    w._bigStep = data.bigStep;
    w._isPercent = data.isPercent or false;
    w._onSet = data.set;
    w._getFn = data.get;
    w._disabledFn = data.disabled;
    w._default = data.default;

    -- Get current value
    local val = 0;
    if (data.get) then val = data.get() or 0; end
    w._value = ClampValue(val, w._min, w._max, w._step);

    -- Description (shown as tooltip)
    w._desc_text = data.desc;
    w.frame:SetHeight(RANGE_HEIGHT);
    w.height = RANGE_HEIGHT;

    -- Disabled state
    local disabled = false;
    if (data.disabled) then
        if (type(data.disabled) == "function") then disabled = data.disabled();
        else disabled = data.disabled; end
    end
    w._disabled = disabled;

    if (disabled) then
        w._label:SetTextColor(unpack(T.disabledText));
        w._valueText:SetTextColor(unpack(T.disabled));
        w._trackBg:SetColorTexture(unpack(T.disabled));
        w._fill:SetColorTexture(T.accent[1] * 0.45, T.accent[2] * 0.45, T.accent[3] * 0.45, 1.0);
        w._thumbBg:SetColorTexture(T.accent[1] * 0.45, T.accent[2] * 0.45, T.accent[3] * 0.45, 1.0);
    else
        w._label:SetTextColor(unpack(T.text));
        w._valueText:SetTextColor(unpack(T.textDim));
        w._trackBg:SetColorTexture(unpack(T.trackBg));
        w._fill:SetColorTexture(unpack(T.accent));
        w._thumbBg:SetColorTexture(unpack(T.thumbBg));
    end

    -- Defer thumb + default marker position to next frame so width is resolved
    C_Timer.After(0, function()
        if (not w._inUse) then return; end
        w._updateThumb();
        -- Position default marker
        if (w._default ~= nil) then
            local trackWidth = w._trackFrame:GetWidth();
            if (trackWidth > 0) then
                local range = w._max - w._min;
                if (range > 0) then
                    local ratio = (w._default - w._min) / range;
                    local xPos = ratio * (trackWidth - THUMB_SIZE) + THUMB_SIZE / 2;
                    w._defaultMark:ClearAllPoints();
                    w._defaultMark:SetPoint("CENTER", w._trackFrame, "LEFT", xPos, 0);
                    w._defaultMark:Show();
                end
            end
        else
            w._defaultMark:Hide();
        end
    end);

    return w;
end

-------------------------------------------------------------------------------
-- Register
-------------------------------------------------------------------------------

_W.factories.range = { create = CreateRange, setup = SetupRange };

_W.refreshers.range = function(w)
    if (w._getFn) then
        w._value = ClampValue(w._getFn() or 0, w._min, w._max, w._step);
        w._updateThumb();
    end
    local disabled = EvalDisabled(w);
    if (disabled) then
        w._label:SetTextColor(unpack(T.disabledText));
        w._valueText:SetTextColor(unpack(T.disabled));
        w._trackBg:SetColorTexture(unpack(T.disabled));
        w._fill:SetColorTexture(T.accent[1] * 0.45, T.accent[2] * 0.45, T.accent[3] * 0.45, 1.0);
        w._thumbBg:SetColorTexture(T.accent[1] * 0.45, T.accent[2] * 0.45, T.accent[3] * 0.45, 1.0);
    else
        w._label:SetTextColor(unpack(T.text));
        w._valueText:SetTextColor(unpack(T.textDim));
        w._trackBg:SetColorTexture(unpack(T.trackBg));
        w._fill:SetColorTexture(unpack(T.accent));
        w._thumbBg:SetColorTexture(unpack(T.thumbBg));
    end
end;
