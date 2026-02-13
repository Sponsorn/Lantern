local ADDON_NAME = ...;

-------------------------------------------------------------------------------
-- Theme (shared reference from SettingsPanel)
-------------------------------------------------------------------------------

local T = {
    -- Core
    bg           = { 0.06, 0.06, 0.07, 0.95 },
    border       = { 0.18, 0.18, 0.20, 1.0 },
    text         = { 0.72, 0.72, 0.72, 1.0 },
    textBright   = { 1.0,  1.0,  1.0,  1.0 },
    textDim      = { 0.52, 0.52, 0.54, 1.0 },
    sectionLabel = { 0.50, 0.50, 0.53, 1.0 },
    accent       = { 0.88, 0.56, 0.18, 1.0 },
    accentDim    = { 0.88, 0.56, 0.18, 0.40 },
    hover        = { 1.0,  1.0,  1.0,  0.04 },
    divider      = { 0.20, 0.20, 0.22, 0.5 },
    -- Toggle/checkbox
    checkBorder  = { 0.35, 0.35, 0.38, 1.0 },
    checkInner   = { 0.10, 0.10, 0.12, 1.0 },
    checkHover   = { 0.42, 0.42, 0.45, 1.0 },
    -- Disabled
    disabled     = { 0.30, 0.30, 0.30, 1.0 },
    disabledText = { 0.40, 0.40, 0.40, 1.0 },
    -- Panel shell
    sidebar      = { 0.09, 0.09, 0.10, 1.0 },
    titleBar     = { 0.09, 0.09, 0.10, 1.0 },
    selected     = { 0.88, 0.56, 0.18, 0.10 },
    accentBar    = { 0.88, 0.56, 0.18, 0.80 },
    splashText   = { 0.60, 0.60, 0.60, 1.0 },
    enabled      = { 0.40, 0.67, 0.40, 1.0 },
    disabledDot  = { 0.67, 0.40, 0.40, 1.0 },
    -- Input/range
    inputBg      = { 0.10, 0.10, 0.12, 1.0 },
    inputBorder  = { 0.28, 0.28, 0.30, 1.0 },
    inputFocus   = { 0.88, 0.56, 0.18, 0.60 },
    -- Slider
    trackBg      = { 0.20, 0.20, 0.22, 1.0 },
    thumbBg      = { 0.88, 0.56, 0.18, 1.0 },
    thumbHover   = { 1.0,  0.70, 0.30, 1.0 },
    -- Button
    buttonBg     = { 0.14, 0.14, 0.16, 1.0 },
    buttonBorder = { 0.30, 0.30, 0.32, 1.0 },
    buttonHover  = { 0.20, 0.20, 0.22, 1.0 },
    buttonText   = { 0.80, 0.80, 0.80, 1.0 },
    -- Dropdown
    dropdownBg   = { 0.08, 0.08, 0.10, 0.98 },
    dropdownItem = { 1.0,  1.0,  1.0,  0.06 },
};

-------------------------------------------------------------------------------
-- Layout constants
-------------------------------------------------------------------------------

local CONTENT_PAD    = 20;
local WIDGET_GAP     = 6;
local TOGGLE_SIZE    = 16;
local TOGGLE_PAD     = 8;   -- gap between checkbox and label
local HEADER_HEIGHT  = 28;
local DIVIDER_HEIGHT = 16;
local DESC_PAD_BOT   = 4;

-------------------------------------------------------------------------------
-- Widget pools
-------------------------------------------------------------------------------

local dropdownPopup;   -- forward declaration (used by ReleaseAll + Select widget)
local groupStates = {};    -- per-session expand/collapse state, keyed by "pageKey:groupText"
local currentPageKey = nil;  -- set by RenderContent so groups know which page they belong to
local pools = {};

local function AcquireWidget(widgetType, parent)
    pools[widgetType] = pools[widgetType] or {};
    local pool = pools[widgetType];

    for _, w in ipairs(pool) do
        if (not w._inUse) then
            w._inUse = true;
            w.frame:SetParent(parent);
            w.frame:Show();
            return w;
        end
    end

    return nil;  -- caller must create
end

local function ReleaseAll()
    -- Close any open dropdown
    if (dropdownPopup and dropdownPopup:IsShown()) then
        dropdownPopup:Hide();
        dropdownPopup._owner = nil;
    end

    for _, pool in pairs(pools) do
        for _, w in ipairs(pool) do
            w._inUse = false;
            w.frame:Hide();
            w.frame:ClearAllPoints();
        end
    end
end

local function RegisterWidget(widgetType, widget)
    pools[widgetType] = pools[widgetType] or {};
    widget._inUse = true;
    table.insert(pools[widgetType], widget);
end

-------------------------------------------------------------------------------
-- Shared helpers (must be above RefreshActiveWidgets and widget factories)
-------------------------------------------------------------------------------

local function ClampValue(val, min, max, step)
    if (step and step > 0) then
        val = math.floor((val - min) / step + 0.5) * step + min;
    end
    return math.max(min, math.min(max, val));
end

local function FormatValue(val, isPercent)
    if (isPercent) then
        return string.format("%d%%", math.floor(val * 100 + 0.5));
    end
    local s = string.format("%.2f", val);
    s = s:gsub("%.?0+$", "");
    return s;
end

-------------------------------------------------------------------------------
-- Description panel API (hover updates the right-side description pane)
-------------------------------------------------------------------------------

local function ShowDescription(label, desc)
    local dp = _G.LanternUX and _G.LanternUX.descPanel;
    if (not dp or not desc or desc == "") then return; end
    dp._title:SetText(label or "");
    dp._text:SetText(desc);
end

local function ClearDescription()
    local dp = _G.LanternUX and _G.LanternUX.descPanel;
    if (not dp) then return; end
    dp._title:SetText(dp._defaultTitle or "");
    dp._text:SetText(dp._defaultDesc or "");
end

local function SetDefaultDescription(title, desc)
    local dp = _G.LanternUX and _G.LanternUX.descPanel;
    if (not dp) then return; end
    dp._defaultTitle = title or "";
    dp._defaultDesc = desc or "";
    dp._title:SetText(title or "");
    dp._text:SetText(desc or "");
end

-------------------------------------------------------------------------------
-- Widget refresh (re-evaluates disabled + value state on all active widgets)
-------------------------------------------------------------------------------

local function EvalDisabled(w)
    local disabled = false;
    if (w._disabledFn) then
        if (type(w._disabledFn) == "function") then
            disabled = w._disabledFn();
        else
            disabled = w._disabledFn;
        end
    end
    w._disabled = disabled;
    return disabled;
end

local function RefreshActiveWidgets()
    -- Toggles
    for _, w in ipairs(pools["toggle"] or {}) do
        if (w._inUse) then
            if (w._getFn) then
                w._checked = w._getFn();
                if (w._checked) then w._mark:Show(); else w._mark:Hide(); end
            end
            local disabled = EvalDisabled(w);
            if (disabled) then
                w._boxBorder:SetColorTexture(unpack(T.disabled));
                w._boxInner:SetColorTexture(0.08, 0.08, 0.08, 1.0);
                w._mark:SetColorTexture(unpack(T.accentDim));
                w._label:SetTextColor(unpack(T.disabledText));
            else
                w._boxBorder:SetColorTexture(unpack(T.checkBorder));
                w._boxInner:SetColorTexture(unpack(T.checkInner));
                w._mark:SetColorTexture(unpack(T.accent));
                w._label:SetTextColor(unpack(T.text));
            end
        end
    end

    -- Ranges
    for _, w in ipairs(pools["range"] or {}) do
        if (w._inUse) then
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
        end
    end

    -- Selects
    for _, w in ipairs(pools["select"] or {}) do
        if (w._inUse) then
            if (w._getFn) then
                w._currentKey = w._getFn();
                local values = w._values;
                if (type(values) == "function") then values = values(); end
                w._btnText:SetText((w._currentKey and values[w._currentKey]) or "");
            end
            local disabled = EvalDisabled(w);
            if (disabled) then
                w._label:SetTextColor(unpack(T.disabledText));
                w._btn:SetBackdropColor(0.08, 0.08, 0.08, 1.0);
                w._btn:SetBackdropBorderColor(unpack(T.disabled));
                w._btnText:SetTextColor(unpack(T.disabledText));
                w._arrow:SetVertexColor(unpack(T.disabled));
            else
                w._label:SetTextColor(unpack(T.text));
                w._btn:SetBackdropColor(unpack(T.buttonBg));
                w._btn:SetBackdropBorderColor(unpack(T.buttonBorder));
                w._btnText:SetTextColor(unpack(T.buttonText));
                w._arrow:SetVertexColor(unpack(T.textDim));
            end
        end
    end

    -- Executes
    for _, w in ipairs(pools["execute"] or {}) do
        if (w._inUse) then
            local disabled = EvalDisabled(w);
            if (disabled) then
                w._btn:SetBackdropColor(0.08, 0.08, 0.08, 1.0);
                w._btn:SetBackdropBorderColor(unpack(T.disabled));
                w._btnText:SetTextColor(unpack(T.disabledText));
            else
                w._btn:SetBackdropColor(unpack(T.buttonBg));
                w._btn:SetBackdropBorderColor(unpack(T.buttonBorder));
                w._btnText:SetTextColor(unpack(T.buttonText));
            end
        end
    end

    -- Inputs
    for _, w in ipairs(pools["input"] or {}) do
        if (w._inUse) then
            if (w._getFn and not w._box:HasFocus()) then
                w._box:SetText(w._getFn() or "");
            end
            local disabled = EvalDisabled(w);
            if (disabled) then
                w._label:SetTextColor(unpack(T.disabledText));
                w._box:SetBackdropColor(0.08, 0.08, 0.08, 1.0);
                w._box:SetBackdropBorderColor(unpack(T.disabled));
                w._box:SetTextColor(unpack(T.disabledText));
                w._box:EnableMouse(false);
            else
                w._label:SetTextColor(unpack(T.text));
                w._box:SetBackdropColor(unpack(T.inputBg));
                w._box:SetBackdropBorderColor(unpack(T.inputBorder));
                w._box:SetTextColor(unpack(T.text));
                w._box:EnableMouse(true);
            end
        end
    end

    -- Colors
    for _, w in ipairs(pools["color"] or {}) do
        if (w._inUse) then
            if (w._getFn) then
                local r, g, b = w._getFn();
                w._r, w._g, w._b = r or 1, g or 1, b or 1;
                w._swatch:SetColorTexture(w._r, w._g, w._b);
            end
            local disabled = EvalDisabled(w);
            if (disabled) then
                w._label:SetTextColor(unpack(T.disabledText));
                w._border:SetColorTexture(unpack(T.disabled));
                w._swatch:SetVertexColor(0.5, 0.5, 0.5, 0.5);
            else
                w._label:SetTextColor(unpack(T.text));
                w._border:SetColorTexture(unpack(T.checkBorder));
                w._swatch:SetVertexColor(1, 1, 1, 1);
            end
        end
    end
end


-------------------------------------------------------------------------------
-- Widget: Toggle
-------------------------------------------------------------------------------

local function CreateToggle(parent)
    local w = AcquireWidget("toggle", parent);
    if (w) then return w; end

    w = {};
    local frame = CreateFrame("Button", nil, parent);
    frame:SetHeight(TOGGLE_SIZE + 4);
    w.frame = frame;

    -- Checkbox box
    local box = CreateFrame("Frame", nil, frame);
    box:SetSize(TOGGLE_SIZE, TOGGLE_SIZE);
    box:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -2);

    local boxBorder = box:CreateTexture(nil, "BORDER");
    boxBorder:SetAllPoints();
    boxBorder:SetColorTexture(unpack(T.checkBorder));
    w._boxBorder = boxBorder;

    local boxInner = box:CreateTexture(nil, "BACKGROUND");
    boxInner:SetPoint("TOPLEFT", 1, -1);
    boxInner:SetPoint("BOTTOMRIGHT", -1, 1);
    boxInner:SetColorTexture(unpack(T.checkInner));
    w._boxInner = boxInner;

    -- Checkmark (filled square when checked)
    local mark = box:CreateTexture(nil, "ARTWORK");
    mark:SetPoint("TOPLEFT", 3, -3);
    mark:SetPoint("BOTTOMRIGHT", -3, 3);
    mark:SetColorTexture(unpack(T.accent));
    mark:Hide();
    w._mark = mark;

    w._box = box;

    -- Label
    local label = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
    label:SetPoint("LEFT", box, "RIGHT", TOGGLE_PAD, 0);
    label:SetJustifyH("LEFT");
    label:SetTextColor(unpack(T.text));
    w._label = label;

    -- State
    w._checked = false;
    w._disabled = false;

    -- Hover
    frame:SetScript("OnEnter", function()
        if (not w._disabled) then
            boxBorder:SetColorTexture(unpack(T.checkHover));
        end
        ShowDescription(w._label:GetText(), w._desc_text);
    end);
    frame:SetScript("OnLeave", function()
        if (not w._disabled) then
            boxBorder:SetColorTexture(unpack(T.checkBorder));
        end
        ClearDescription();
    end);

    -- Click
    frame:SetScript("OnClick", function()
        if (w._disabled) then return; end
        w._checked = not w._checked;
        if (w._checked) then
            w._mark:Show();
        else
            w._mark:Hide();
        end
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
    w.frame:SetHeight(TOGGLE_SIZE + 4);
    w.height = TOGGLE_SIZE + 4;

    -- Checked state
    local checked = false;
    if (data.get) then
        checked = data.get();
    end
    w._checked = checked;
    if (checked) then w._mark:Show(); else w._mark:Hide(); end

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

    if (disabled) then
        w._boxBorder:SetColorTexture(unpack(T.disabled));
        w._boxInner:SetColorTexture(0.08, 0.08, 0.08, 1.0);
        w._mark:SetColorTexture(unpack(T.accentDim));
        w._label:SetTextColor(unpack(T.disabledText));
    else
        w._boxBorder:SetColorTexture(unpack(T.checkBorder));
        w._boxInner:SetColorTexture(unpack(T.checkInner));
        w._mark:SetColorTexture(unpack(T.accent));
        w._label:SetTextColor(unpack(T.text));
    end

    return w;
end

-------------------------------------------------------------------------------
-- Widget: Label / Description
-------------------------------------------------------------------------------

local function CreateLabel(parent)
    local w = AcquireWidget("label", parent);
    if (w) then return w; end

    w = {};
    local frame = CreateFrame("Frame", nil, parent);
    frame:SetHeight(18);
    w.frame = frame;

    local text = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
    text:SetPoint("TOPLEFT");
    text:SetJustifyH("LEFT");
    text:SetWordWrap(true);
    text:SetTextColor(unpack(T.text));
    w._text = text;

    RegisterWidget("label", w);
    return w;
end

local function SetupLabel(w, parent, data, contentWidth)
    w.frame:SetParent(parent);
    w.frame:SetWidth(contentWidth);

    local fontSize = data.fontSize or "medium";
    if (fontSize == "small") then
        w._text:SetFontObject("GameFontHighlightSmall");
    elseif (fontSize == "large") then
        w._text:SetFontObject("GameFontNormalLarge");
    else
        w._text:SetFontObject("GameFontHighlight");
    end

    w._text:SetWidth(contentWidth);
    w._text:SetText(data.text or "");
    w._text:SetTextColor(unpack(data.color or T.text));

    local textHeight = w._text:GetStringHeight() or 14;
    w.frame:SetHeight(textHeight + DESC_PAD_BOT);
    w.height = textHeight + DESC_PAD_BOT;

    return w;
end

-------------------------------------------------------------------------------
-- Widget: Header
-------------------------------------------------------------------------------

local function CreateHeader(parent)
    local w = AcquireWidget("header", parent);
    if (w) then return w; end

    w = {};
    local frame = CreateFrame("Frame", nil, parent);
    frame:SetHeight(HEADER_HEIGHT);
    w.frame = frame;

    local text = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
    text:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 6);
    text:SetJustifyH("LEFT");
    text:SetTextColor(unpack(T.textBright));
    w._text = text;

    local line = frame:CreateTexture(nil, "ARTWORK");
    line:SetHeight(1);
    line:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0);
    line:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0);
    line:SetColorTexture(unpack(T.divider));
    w._line = line;

    w.height = HEADER_HEIGHT;

    RegisterWidget("header", w);
    return w;
end

local function SetupHeader(w, parent, data, contentWidth)
    w.frame:SetParent(parent);
    w.frame:SetWidth(contentWidth);
    w._text:SetText(data.text or "");
    return w;
end

-------------------------------------------------------------------------------
-- Widget: Divider
-------------------------------------------------------------------------------

local function CreateDivider(parent)
    local w = AcquireWidget("divider", parent);
    if (w) then return w; end

    w = {};
    local frame = CreateFrame("Frame", nil, parent);
    frame:SetHeight(DIVIDER_HEIGHT);
    w.frame = frame;

    local line = frame:CreateTexture(nil, "ARTWORK");
    line:SetHeight(1);
    line:SetPoint("LEFT", frame, "LEFT", 0, 0);
    line:SetPoint("RIGHT", frame, "RIGHT", 0, 0);
    line:SetColorTexture(unpack(T.divider));
    w._line = line;

    w.height = DIVIDER_HEIGHT;

    RegisterWidget("divider", w);
    return w;
end

local function SetupDivider(w, parent, data, contentWidth)
    w.frame:SetParent(parent);
    w.frame:SetWidth(contentWidth);
    return w;
end

-------------------------------------------------------------------------------
-- Widget: Range (Slider)
-------------------------------------------------------------------------------

local RANGE_HEIGHT     = 44;
local TRACK_HEIGHT     = 6;
local THUMB_SIZE       = 14;
local RANGE_LABEL_H    = 18;
local RANGE_TRACK_PAD  = 4;   -- gap between label row and track

local function CreateRange(parent)
    local w = AcquireWidget("range", parent);
    if (w) then return w; end

    w = {};
    local frame = CreateFrame("Frame", nil, parent);
    frame:SetHeight(RANGE_HEIGHT);
    frame:EnableMouse(true);
    w.frame = frame;

    -- Label (left)
    local label = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
    label:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0);
    label:SetJustifyH("LEFT");
    label:SetTextColor(unpack(T.text));
    w._label = label;

    -- Value text (right)
    local valueText = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
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
    local trackFrame = CreateFrame("Frame", nil, frame);
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
    local thumb = CreateFrame("Frame", nil, trackFrame);
    thumb:SetSize(THUMB_SIZE, THUMB_SIZE);
    thumb:SetFrameLevel(trackFrame:GetFrameLevel() + 2);

    local thumbBg = thumb:CreateTexture(nil, "ARTWORK");
    thumbBg:SetAllPoints();
    thumbBg:SetColorTexture(unpack(T.thumbBg));
    w._thumb = thumb;
    w._thumbBg = thumbBg;

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
    local dragFrame = CreateFrame("Frame", nil, trackFrame);
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
        -- Don't stop dragging on leave — OnUpdate checks IsMouseButtonDown
    end);

    -- Mouse wheel to increment/decrement by step
    dragFrame:EnableMouseWheel(true);
    dragFrame:SetScript("OnMouseWheel", function(self, delta)
        if (w._disabled) then return; end
        local step = w._bigStep or w._step;
        local newVal = ClampValue(w._value + delta * step, w._min, w._max, w._step);
        if (newVal ~= w._value) then
            w._value = newVal;
            UpdateThumbPosition();
            if (w._onSet) then w._onSet(newVal); end
            C_Timer.After(0, RefreshActiveWidgets);
        end
    end);

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

    -- Defer thumb position to next frame so width is resolved
    C_Timer.After(0, function()
        if (w._inUse) then w._updateThumb(); end
    end);

    return w;
end

-------------------------------------------------------------------------------
-- Widget: Select (Dropdown)
-------------------------------------------------------------------------------

local SELECT_HEIGHT    = 28;
local SELECT_BTN_W     = 160;
local SELECT_BTN_H     = 24;
local SELECT_ITEM_H    = 24;

local function CloseDropdown()
    if (dropdownPopup) then
        dropdownPopup:Hide();
        dropdownPopup._owner = nil;
    end
end

local function EnsureDropdownPopup()
    if (dropdownPopup) then return dropdownPopup; end

    local f = CreateFrame("Frame", "LanternUXDropdownPopup", UIParent, "BackdropTemplate");
    f:SetFrameStrata("TOOLTIP");
    f:SetClampedToScreen(true);
    f:EnableMouse(true);
    f:Hide();

    f:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    });
    f:SetBackdropColor(unpack(T.dropdownBg));
    f:SetBackdropBorderColor(unpack(T.border));

    -- Close on ESC
    table.insert(UISpecialFrames, "LanternUXDropdownPopup");

    -- Close on click-outside
    f:SetScript("OnShow", function()
        f._closeListener = f._closeListener or CreateFrame("Button", nil, UIParent);
        f._closeListener:SetAllPoints(UIParent);
        f._closeListener:SetFrameStrata("TOOLTIP");
        f._closeListener:SetFrameLevel(f:GetFrameLevel() - 1);
        f._closeListener:Show();
        f._closeListener:SetScript("OnClick", function()
            CloseDropdown();
        end);
    end);
    f:SetScript("OnHide", function()
        if (f._closeListener) then f._closeListener:Hide(); end
    end);

    f._items = {};
    dropdownPopup = f;
    return f;
end

local function OpenDropdown(w)
    CloseDropdown();

    local popup = EnsureDropdownPopup();
    popup._owner = w;

    -- Resolve values and sorting
    local values = w._values;
    if (type(values) == "function") then values = values(); end
    local sorting = w._sorting;
    if (type(sorting) == "function") then sorting = sorting(); end

    -- Build ordered key list
    local keys = {};
    if (sorting) then
        for _, k in ipairs(sorting) do
            if (values[k]) then table.insert(keys, k); end
        end
    else
        for k in pairs(values) do table.insert(keys, k); end
        table.sort(keys, function(a, b) return tostring(values[a]) < tostring(values[b]); end);
    end

    -- Hide old items
    for _, item in ipairs(popup._items) do item:Hide(); end

    -- Create/show items
    local y = -4;
    local maxTextWidth = 0;
    for i, key in ipairs(keys) do
        local item = popup._items[i];
        if (not item) then
            item = CreateFrame("Button", nil, popup);
            item:SetHeight(SELECT_ITEM_H);

            local itemBg = item:CreateTexture(nil, "BACKGROUND");
            itemBg:SetAllPoints();
            itemBg:SetColorTexture(0, 0, 0, 0);
            item._bg = itemBg;

            local itemText = item:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
            itemText:SetPoint("LEFT", 10, 0);
            itemText:SetJustifyH("LEFT");
            item._text = itemText;

            item:SetScript("OnEnter", function(self)
                self._bg:SetColorTexture(unpack(T.dropdownItem));
            end);
            item:SetScript("OnLeave", function(self)
                self._bg:SetColorTexture(0, 0, 0, 0);
            end);

            popup._items[i] = item;
        end

        item:SetParent(popup);
        item:ClearAllPoints();
        item:SetPoint("TOPLEFT", popup, "TOPLEFT", 1, y);
        item:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -1, y);
        item._text:SetText(values[key]);
        item._text:SetTextColor(unpack(T.text));

        -- Track widest item for popup sizing
        local tw = item._text:GetStringWidth() or 0;
        if (tw > maxTextWidth) then maxTextWidth = tw; end

        -- Highlight current selection
        if (key == w._currentKey) then
            item._text:SetTextColor(unpack(T.accent));
        end

        item:SetScript("OnClick", function()
            if (w._onSet) then w._onSet(key); end
            w._currentKey = key;
            w._btnText:SetText(values[key] or "");
            CloseDropdown();
            C_Timer.After(0, RefreshActiveWidgets);
        end);

        item:Show();
        y = y - SELECT_ITEM_H;
    end

    -- Size popup (fit content, at least as wide as the button)
    local popupHeight = math.abs(y) + 8;
    local popupWidth = math.max(SELECT_BTN_W, maxTextWidth + 24);
    popup:SetWidth(popupWidth);
    popup:SetHeight(popupHeight);

    -- Anchor below the select button
    popup:ClearAllPoints();
    popup:SetPoint("TOPLEFT", w._btn, "BOTTOMLEFT", 0, -2);

    popup:Show();
end

local function CreateSelect(parent)
    local w = AcquireWidget("select", parent);
    if (w) then return w; end

    w = {};
    local frame = CreateFrame("Frame", nil, parent);
    frame:SetHeight(SELECT_HEIGHT);
    w.frame = frame;

    -- Label (left)
    local label = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
    label:SetPoint("LEFT", frame, "LEFT", 0, 0);
    label:SetJustifyH("LEFT");
    label:SetTextColor(unpack(T.text));
    w._label = label;

    -- Description panel on hover
    frame:EnableMouse(true);
    frame:SetScript("OnEnter", function()
        ShowDescription(w._label:GetText(), w._desc_text);
    end);
    frame:SetScript("OnLeave", ClearDescription);

    -- Button (right)
    local btn = CreateFrame("Button", nil, frame, "BackdropTemplate");
    btn:SetSize(SELECT_BTN_W, SELECT_BTN_H);
    btn:SetPoint("RIGHT", frame, "RIGHT", 0, 0);

    btn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    });
    btn:SetBackdropColor(unpack(T.buttonBg));
    btn:SetBackdropBorderColor(unpack(T.buttonBorder));
    w._btn = btn;

    local btnText = btn:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
    btnText:SetPoint("LEFT", 8, 0);
    btnText:SetPoint("RIGHT", -20, 0);
    btnText:SetJustifyH("LEFT");
    btnText:SetTextColor(unpack(T.buttonText));
    w._btnText = btnText;

    -- Arrow chevron (two rotated lines forming a "V")
    local arrowWrap = CreateFrame("Frame", nil, btn);
    arrowWrap:SetSize(10, 6);
    arrowWrap:SetPoint("RIGHT", -8, 0);

    local arrowL = arrowWrap:CreateTexture(nil, "ARTWORK");
    arrowL:SetSize(6, 1.5);
    arrowL:SetTexture("Interface\\Buttons\\WHITE8x8");
    arrowL:SetRotation(math.rad(-40));
    arrowL:SetPoint("CENTER", arrowWrap, "CENTER", -2, 0);
    arrowL:SetVertexColor(unpack(T.textDim));

    local arrowR = arrowWrap:CreateTexture(nil, "ARTWORK");
    arrowR:SetSize(6, 1.5);
    arrowR:SetTexture("Interface\\Buttons\\WHITE8x8");
    arrowR:SetRotation(math.rad(40));
    arrowR:SetPoint("CENTER", arrowWrap, "CENTER", 2, 0);
    arrowR:SetVertexColor(unpack(T.textDim));

    -- Proxy so RefreshActiveWidgets can call w._arrow:SetVertexColor()
    arrowWrap.SetVertexColor = function(self, r, g, b, a)
        arrowL:SetVertexColor(r, g, b, a or 1);
        arrowR:SetVertexColor(r, g, b, a or 1);
    end;
    w._arrow = arrowWrap;

    -- Hover
    btn:SetScript("OnEnter", function()
        if (not w._disabled) then
            btn:SetBackdropColor(unpack(T.buttonHover));
        end
        ShowDescription(w._label:GetText(), w._desc_text);
    end);
    btn:SetScript("OnLeave", function()
        if (not w._disabled) then
            btn:SetBackdropColor(unpack(T.buttonBg));
        end
        ClearDescription();
    end);

    -- Click
    btn:SetScript("OnClick", function()
        if (w._disabled) then return; end
        if (dropdownPopup and dropdownPopup:IsShown() and dropdownPopup._owner == w) then
            CloseDropdown();
        else
            OpenDropdown(w);
        end
    end);

    -- State
    w._disabled = false;

    RegisterWidget("select", w);
    return w;
end

local function SetupSelect(w, parent, data, contentWidth)
    w.frame:SetParent(parent);
    w.frame:SetWidth(contentWidth);

    w._label:SetText(data.label or "");
    w._values = data.values or {};
    w._sorting = data.sorting;
    w._onSet = data.set;
    w._getFn = data.get;
    w._disabledFn = data.disabled;

    -- Current value
    local currentKey = data.get and data.get() or nil;
    w._currentKey = currentKey;

    -- Resolve display text
    local values = w._values;
    if (type(values) == "function") then values = values(); end
    w._btnText:SetText((currentKey and values[currentKey]) or "");

    -- Description (shown as tooltip)
    w._desc_text = data.desc;
    w.frame:SetHeight(SELECT_HEIGHT);
    w.height = SELECT_HEIGHT;

    -- Disabled state
    local disabled = false;
    if (data.disabled) then
        if (type(data.disabled) == "function") then disabled = data.disabled();
        else disabled = data.disabled; end
    end
    w._disabled = disabled;

    if (disabled) then
        w._label:SetTextColor(unpack(T.disabledText));
        w._btn:SetBackdropColor(0.08, 0.08, 0.08, 1.0);
        w._btn:SetBackdropBorderColor(unpack(T.disabled));
        w._btnText:SetTextColor(unpack(T.disabledText));
        w._arrow:SetVertexColor(unpack(T.disabled));
    else
        w._label:SetTextColor(unpack(T.text));
        w._btn:SetBackdropColor(unpack(T.buttonBg));
        w._btn:SetBackdropBorderColor(unpack(T.buttonBorder));
        w._btnText:SetTextColor(unpack(T.buttonText));
        w._arrow:SetVertexColor(unpack(T.textDim));
    end

    return w;
end

-------------------------------------------------------------------------------
-- Widget: Execute (Action Button)
-------------------------------------------------------------------------------

local EXECUTE_HEIGHT   = 32;
local EXECUTE_BTN_H    = 28;

local function CreateExecute(parent)
    local w = AcquireWidget("execute", parent);
    if (w) then return w; end

    w = {};
    local frame = CreateFrame("Frame", nil, parent);
    frame:SetHeight(EXECUTE_HEIGHT);
    w.frame = frame;

    -- Button
    local btn = CreateFrame("Button", nil, frame, "BackdropTemplate");
    btn:SetHeight(EXECUTE_BTN_H);
    btn:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0);

    btn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    });
    btn:SetBackdropColor(unpack(T.buttonBg));
    btn:SetBackdropBorderColor(unpack(T.buttonBorder));
    w._btn = btn;

    local btnText = btn:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
    btnText:SetPoint("CENTER");
    btnText:SetTextColor(unpack(T.buttonText));
    w._btnText = btnText;

    -- State
    w._disabled = false;
    w._confirming = false;

    -- Hover
    btn:SetScript("OnEnter", function()
        if (not w._disabled) then
            btn:SetBackdropColor(unpack(T.buttonHover));
        end
        ShowDescription(w._originalLabel or w._btnText:GetText(), w._desc_text);
    end);
    btn:SetScript("OnLeave", function()
        if (not w._disabled) then
            btn:SetBackdropColor(unpack(T.buttonBg));
        end
        -- Reset confirm state on leave
        if (w._confirming) then
            w._confirming = false;
            w._btnText:SetText(w._originalLabel or "");
            w._btnText:SetTextColor(unpack(T.buttonText));
        end
        ClearDescription();
    end);

    -- Click
    btn:SetScript("OnClick", function()
        if (w._disabled) then return; end

        if (w._confirmText and not w._confirming) then
            -- First click: show confirm text
            w._confirming = true;
            w._btnText:SetText(w._confirmText);
            w._btnText:SetTextColor(unpack(T.accent));
            return;
        end

        -- Execute
        w._confirming = false;
        w._btnText:SetText(w._originalLabel or "");
        w._btnText:SetTextColor(unpack(T.buttonText));
        if (w._func) then w._func(); end
    end);

    RegisterWidget("execute", w);
    return w;
end

local function SetupExecute(w, parent, data, contentWidth)
    w.frame:SetParent(parent);
    w.frame:SetWidth(contentWidth);

    w._originalLabel = data.label or "Execute";
    w._btnText:SetText(w._originalLabel);
    w._func = data.func;
    w._confirmText = data.confirm;
    w._confirming = false;
    w._disabledFn = data.disabled;
    w._desc_text = data.desc;

    -- Button width: auto from label, minimum 120
    local textWidth = w._btnText:GetStringWidth() or 60;
    w._btn:SetWidth(math.max(120, textWidth + 30));

    w.frame:SetHeight(EXECUTE_HEIGHT);
    w.height = EXECUTE_HEIGHT;

    -- Disabled state
    local disabled = false;
    if (data.disabled) then
        if (type(data.disabled) == "function") then disabled = data.disabled();
        else disabled = data.disabled; end
    end
    w._disabled = disabled;

    if (disabled) then
        w._btn:SetBackdropColor(0.08, 0.08, 0.08, 1.0);
        w._btn:SetBackdropBorderColor(unpack(T.disabled));
        w._btnText:SetTextColor(unpack(T.disabledText));
    else
        w._btn:SetBackdropColor(unpack(T.buttonBg));
        w._btn:SetBackdropBorderColor(unpack(T.buttonBorder));
        w._btnText:SetTextColor(unpack(T.buttonText));
    end

    return w;
end

-------------------------------------------------------------------------------
-- Widget: Input (Text Field)
-------------------------------------------------------------------------------

local INPUT_HEIGHT     = 44;
local INPUT_BOX_H      = 24;

local function CreateInput(parent)
    local w = AcquireWidget("input", parent);
    if (w) then return w; end

    w = {};
    local frame = CreateFrame("Frame", nil, parent);
    frame:SetHeight(INPUT_HEIGHT);
    frame:EnableMouse(true);
    w.frame = frame;

    -- Label
    local label = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
    label:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0);
    label:SetJustifyH("LEFT");
    label:SetTextColor(unpack(T.text));
    w._label = label;

    -- Description panel on hover
    frame:SetScript("OnEnter", function()
        ShowDescription(w._label:GetText(), w._desc_text);
    end);
    frame:SetScript("OnLeave", ClearDescription);

    -- EditBox
    local box = CreateFrame("EditBox", nil, frame, "BackdropTemplate");
    box:SetHeight(INPUT_BOX_H);
    box:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -18);
    box:SetPoint("RIGHT", frame, "RIGHT", 0, 0);
    box:SetAutoFocus(false);
    box:SetFontObject("GameFontHighlight");
    box:SetTextInsets(8, 8, 0, 0);
    box:SetMaxLetters(256);

    box:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    });
    box:SetBackdropColor(unpack(T.inputBg));
    box:SetBackdropBorderColor(unpack(T.inputBorder));
    box:SetTextColor(unpack(T.text));
    w._box = box;

    -- Focus highlight
    box:SetScript("OnEditFocusGained", function(self)
        if (not w._disabled) then
            self:SetBackdropBorderColor(unpack(T.inputFocus));
        end
    end);
    box:SetScript("OnEditFocusLost", function(self)
        self:SetBackdropBorderColor(unpack(T.inputBorder));
        -- Commit on focus loss
        if (w._onSet) then
            w._onSet(self:GetText());
        end
    end);

    -- Enter clears focus (commit handled by OnEditFocusLost)
    box:SetScript("OnEnterPressed", function(self)
        self:ClearFocus();
    end);

    -- Escape reverts and clears focus
    box:SetScript("OnEscapePressed", function(self)
        if (w._getFn) then
            self:SetText(w._getFn() or "");
        end
        self:ClearFocus();
    end);

    -- Hover on editbox (show description when hovering the input field)
    box:SetScript("OnEnter", function()
        ShowDescription(w._label:GetText(), w._desc_text);
    end);
    box:SetScript("OnLeave", ClearDescription);

    -- State
    w._disabled = false;

    RegisterWidget("input", w);
    return w;
end

local function SetupInput(w, parent, data, contentWidth)
    w.frame:SetParent(parent);
    w.frame:SetWidth(contentWidth);

    w._label:SetText(data.label or "");
    w._onSet = data.set;
    w._getFn = data.get;
    w._disabledFn = data.disabled;
    w._desc_text = data.desc;

    -- Current value
    local val = data.get and data.get() or "";
    w._box:SetText(val);

    w.frame:SetHeight(INPUT_HEIGHT);
    w.height = INPUT_HEIGHT;

    -- Disabled state
    local disabled = false;
    if (data.disabled) then
        if (type(data.disabled) == "function") then disabled = data.disabled();
        else disabled = data.disabled; end
    end
    w._disabled = disabled;

    if (disabled) then
        w._label:SetTextColor(unpack(T.disabledText));
        w._box:SetBackdropColor(0.08, 0.08, 0.08, 1.0);
        w._box:SetBackdropBorderColor(unpack(T.disabled));
        w._box:SetTextColor(unpack(T.disabledText));
        w._box:EnableMouse(false);
    else
        w._label:SetTextColor(unpack(T.text));
        w._box:SetBackdropColor(unpack(T.inputBg));
        w._box:SetBackdropBorderColor(unpack(T.inputBorder));
        w._box:SetTextColor(unpack(T.text));
        w._box:EnableMouse(true);
    end

    return w;
end

-------------------------------------------------------------------------------
-- Widget: Color Picker
-------------------------------------------------------------------------------

local COLOR_HEIGHT     = 22;
local SWATCH_SIZE      = 16;

local function CreateColor(parent)
    local w = AcquireWidget("color", parent);
    if (w) then return w; end

    w = {};
    local frame = CreateFrame("Frame", nil, parent);
    frame:SetHeight(COLOR_HEIGHT);
    w.frame = frame;

    -- Label (left)
    local label = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
    label:SetPoint("LEFT", frame, "LEFT", 0, 0);
    label:SetJustifyH("LEFT");
    label:SetTextColor(unpack(T.text));
    w._label = label;

    -- Description panel on hover
    frame:EnableMouse(true);
    frame:SetScript("OnEnter", function()
        ShowDescription(w._label:GetText(), w._desc_text);
    end);
    frame:SetScript("OnLeave", ClearDescription);

    -- Swatch button (right)
    local btn = CreateFrame("Button", nil, frame);
    btn:SetSize(SWATCH_SIZE, SWATCH_SIZE);
    btn:SetPoint("RIGHT", frame, "RIGHT", 0, 0);
    w._btn = btn;

    -- Swatch border
    local border = btn:CreateTexture(nil, "BORDER");
    border:SetAllPoints();
    border:SetColorTexture(unpack(T.checkBorder));
    w._border = border;

    -- Swatch color fill
    local swatch = btn:CreateTexture(nil, "ARTWORK");
    swatch:SetPoint("TOPLEFT", 1, -1);
    swatch:SetPoint("BOTTOMRIGHT", -1, 1);
    swatch:SetColorTexture(1, 1, 1);
    w._swatch = swatch;

    -- State
    w._disabled = false;
    w._r = 1;
    w._g = 1;
    w._b = 1;

    -- Hover
    btn:SetScript("OnEnter", function()
        if (not w._disabled) then
            border:SetColorTexture(unpack(T.checkHover));
        end
        ShowDescription(w._label:GetText(), w._desc_text);
    end);
    btn:SetScript("OnLeave", function()
        if (not w._disabled) then
            border:SetColorTexture(unpack(T.checkBorder));
        end
        ClearDescription();
    end);

    -- Click → open native color picker
    btn:SetScript("OnClick", function()
        if (w._disabled) then return; end

        local info = {};
        info.r = w._r;
        info.g = w._g;
        info.b = w._b;
        info.hasOpacity = w._hasAlpha or false;
        info.opacity = w._hasAlpha and (1 - (w._a or 1)) or 0;

        info.swatchFunc = function()
            local r, g, b = ColorPickerFrame:GetColorRGB();
            w._r, w._g, w._b = r, g, b;
            if (w._hasAlpha) then
                w._a = 1 - ColorPickerFrame:GetColorAlpha();
            end
            w._swatch:SetColorTexture(r, g, b);
            if (w._onSet) then w._onSet(r, g, b, w._a); end
        end;

        info.cancelFunc = function(prev)
            w._r, w._g, w._b = prev.r, prev.g, prev.b;
            if (w._hasAlpha) then
                w._a = 1 - (prev.opacity or 0);
            end
            w._swatch:SetColorTexture(prev.r, prev.g, prev.b);
            if (w._onSet) then w._onSet(prev.r, prev.g, prev.b, w._a); end
        end;

        ColorPickerFrame:SetupColorPickerAndShow(info);
    end);

    RegisterWidget("color", w);
    return w;
end

local function SetupColor(w, parent, data, contentWidth)
    w.frame:SetParent(parent);
    w.frame:SetWidth(contentWidth);

    w._label:SetText(data.label or "");
    w._onSet = data.set;
    w._getFn = data.get;
    w._disabledFn = data.disabled;
    w._hasAlpha = data.hasAlpha or false;

    -- Get current color
    local r, g, b, a = 1, 1, 1, 1;
    if (data.get) then r, g, b, a = data.get(); end
    w._r = r or 1;
    w._g = g or 1;
    w._b = b or 1;
    w._a = a or 1;
    w._swatch:SetColorTexture(w._r, w._g, w._b);

    -- Description (shown as tooltip)
    w._desc_text = data.desc;
    w.frame:SetHeight(COLOR_HEIGHT);
    w.height = COLOR_HEIGHT;

    -- Disabled state
    local disabled = false;
    if (data.disabled) then
        if (type(data.disabled) == "function") then disabled = data.disabled();
        else disabled = data.disabled; end
    end
    w._disabled = disabled;

    if (disabled) then
        w._label:SetTextColor(unpack(T.disabledText));
        w._border:SetColorTexture(unpack(T.disabled));
        w._swatch:SetVertexColor(0.5, 0.5, 0.5, 0.5);
    else
        w._label:SetTextColor(unpack(T.text));
        w._border:SetColorTexture(unpack(T.checkBorder));
        w._swatch:SetVertexColor(1, 1, 1, 1);
    end

    return w;
end

-------------------------------------------------------------------------------
-- Widget: Group (Collapsible Section)
-------------------------------------------------------------------------------

local GROUP_HEADER_H   = 28;
local GROUP_ARROW_SIZE = 10;
local GROUP_ARROW_PAD  = 6;   -- gap between arrow and text

local function CreateGroup(parent)
    local w = AcquireWidget("group", parent);
    if (w) then return w; end

    w = {};
    local frame = CreateFrame("Button", nil, parent);
    frame:SetHeight(GROUP_HEADER_H);
    w.frame = frame;

    -- Arrow (chevron composed of two rotated lines, same technique as dropdown arrow)
    local arrowWrap = CreateFrame("Frame", nil, frame);
    arrowWrap:SetSize(GROUP_ARROW_SIZE, GROUP_ARROW_SIZE);
    arrowWrap:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 6);

    local arrowL = arrowWrap:CreateTexture(nil, "ARTWORK");
    arrowL:SetSize(6, 1.5);
    arrowL:SetTexture("Interface\\Buttons\\WHITE8x8");
    arrowL:SetVertexColor(unpack(T.textDim));
    arrowWrap._L = arrowL;

    local arrowR = arrowWrap:CreateTexture(nil, "ARTWORK");
    arrowR:SetSize(6, 1.5);
    arrowR:SetTexture("Interface\\Buttons\\WHITE8x8");
    arrowR:SetVertexColor(unpack(T.textDim));
    arrowWrap._R = arrowR;

    -- Proxy so we can call w._arrow:SetVertexColor()
    arrowWrap.SetVertexColor = function(self, r, g, b, a)
        arrowL:SetVertexColor(r, g, b, a or 1);
        arrowR:SetVertexColor(r, g, b, a or 1);
    end;

    w._arrow = arrowWrap;
    w._arrowL = arrowL;
    w._arrowR = arrowR;

    -- Label
    local text = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
    text:SetPoint("BOTTOMLEFT", arrowWrap, "BOTTOMRIGHT", GROUP_ARROW_PAD, -1);
    text:SetJustifyH("LEFT");
    text:SetTextColor(unpack(T.textBright));
    w._text = text;

    -- Divider line
    local line = frame:CreateTexture(nil, "ARTWORK");
    line:SetHeight(1);
    line:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0);
    line:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0);
    line:SetColorTexture(unpack(T.divider));
    w._line = line;

    -- Helper: set arrow orientation
    local function SetArrowExpanded(expanded)
        if (expanded) then
            -- Down-pointing chevron (V shape)
            arrowL:ClearAllPoints();
            arrowL:SetRotation(math.rad(-40));
            arrowL:SetPoint("CENTER", arrowWrap, "CENTER", -2, 0);
            arrowR:ClearAllPoints();
            arrowR:SetRotation(math.rad(40));
            arrowR:SetPoint("CENTER", arrowWrap, "CENTER", 2, 0);
        else
            -- Up-pointing chevron (^ shape)
            arrowL:ClearAllPoints();
            arrowL:SetRotation(math.rad(40));
            arrowL:SetPoint("CENTER", arrowWrap, "CENTER", -2, 0);
            arrowR:ClearAllPoints();
            arrowR:SetRotation(math.rad(-40));
            arrowR:SetPoint("CENTER", arrowWrap, "CENTER", 2, 0);
        end
    end
    w._setArrowExpanded = SetArrowExpanded;

    -- State
    w._expanded = false;

    -- Hover
    frame:SetScript("OnEnter", function()
        w._text:SetTextColor(1, 1, 1, 1);
        w._arrow:SetVertexColor(unpack(T.textBright));
        ShowDescription(w._text:GetText(), w._desc_text);
    end);
    frame:SetScript("OnLeave", function()
        w._text:SetTextColor(unpack(T.textBright));
        w._arrow:SetVertexColor(unpack(T.textDim));
        ClearDescription();
    end);

    -- Click to toggle
    frame:SetScript("OnClick", function()
        w._expanded = not w._expanded;
        -- Save state
        if (w._stateKey) then
            groupStates[w._stateKey] = w._expanded;
        end
        SetArrowExpanded(w._expanded);
        -- Re-layout the page
        if (w._reRender) then w._reRender(); end
    end);

    RegisterWidget("group", w);
    return w;
end

local function SetupGroup(w, parent, data, contentWidth)
    w.frame:SetParent(parent);
    w.frame:SetWidth(contentWidth);

    w._text:SetText(data.text or "");
    w._desc_text = data.desc;

    -- State key for per-session memory
    w._stateKey = (currentPageKey or "") .. ":" .. (data.text or "");

    -- Resolve expanded state: saved > data default > collapsed
    if (groupStates[w._stateKey] ~= nil) then
        w._expanded = groupStates[w._stateKey];
    elseif (data.expanded) then
        w._expanded = true;
    else
        w._expanded = false;
    end

    -- Arrow orientation
    w._setArrowExpanded(w._expanded);

    w.height = GROUP_HEADER_H;
    w.frame:SetHeight(GROUP_HEADER_H);

    return w;
end

-------------------------------------------------------------------------------
-- Scroll container
-------------------------------------------------------------------------------

local SCROLL_STEP       = 40;
local SCROLL_BLEND      = 0.15;
local SCROLL_SNAP_THRESHOLD = 0.5;

local function CreateScrollContainer(parent)
    local container = {};
    local scrollTarget = 0;

    local scrollFrame = CreateFrame("ScrollFrame", nil, parent);
    scrollFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0);
    scrollFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0);
    scrollFrame:EnableMouseWheel(true);

    local scrollChild = CreateFrame("Frame", nil, scrollFrame);
    scrollChild:SetWidth(1);  -- set properly on render
    scrollFrame:SetScrollChild(scrollChild);

    -- Smooth scroll OnUpdate (set/removed dynamically)
    local function OnUpdate_SmoothScroll(self, elapsed)
        local current = self:GetVerticalScroll();
        local amount = math.min(1, SCROLL_BLEND * elapsed * 60);
        local newPos = current + (scrollTarget - current) * amount;

        local diff = math.abs(newPos - scrollTarget);
        if (diff < SCROLL_SNAP_THRESHOLD) then
            newPos = scrollTarget;
            self:SetScript("OnUpdate", nil);
        end

        self:SetVerticalScroll(newPos);
        container:UpdateThumb();
    end

    -- Mouse wheel scrolling
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local maxScroll = self:GetVerticalScrollRange();
        scrollTarget = scrollTarget - (delta * SCROLL_STEP);
        scrollTarget = math.max(0, math.min(scrollTarget, maxScroll));
        self:SetScript("OnUpdate", OnUpdate_SmoothScroll);
    end);

    -- Scrollbar track
    local track = CreateFrame("Frame", nil, scrollFrame);
    track:SetWidth(4);
    track:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", -2, -2);
    track:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", -2, 2);
    local trackBg = track:CreateTexture(nil, "BACKGROUND");
    trackBg:SetAllPoints();
    trackBg:SetColorTexture(0.14, 0.14, 0.16, 0.3);
    track:Hide();

    -- Scrollbar thumb
    local thumb = CreateFrame("Frame", nil, track);
    thumb:SetWidth(4);
    local thumbBg = thumb:CreateTexture(nil, "ARTWORK");
    thumbBg:SetAllPoints();
    thumbBg:SetColorTexture(0.40, 0.40, 0.44, 0.6);
    thumb:Hide();

    container.scrollFrame = scrollFrame;
    container.scrollChild = scrollChild;
    container.track = track;
    container.thumb = thumb;

    function container:UpdateThumb()
        local visibleHeight = self.scrollFrame:GetHeight();
        local contentHeight = self.scrollChild:GetHeight();

        if (contentHeight <= visibleHeight or contentHeight <= 0) then
            self.track:Hide();
            self.thumb:Hide();
            return;
        end

        self.track:Show();
        self.thumb:Show();

        local trackHeight = self.track:GetHeight();
        local thumbHeight = math.max(20, (visibleHeight / contentHeight) * trackHeight);
        self.thumb:SetHeight(thumbHeight);

        local scrollRange = self.scrollFrame:GetVerticalScrollRange();
        local currentScroll = self.scrollFrame:GetVerticalScroll();
        local scrollRatio = (scrollRange > 0) and (currentScroll / scrollRange) or 0;
        local thumbOffset = scrollRatio * (trackHeight - thumbHeight);

        self.thumb:ClearAllPoints();
        self.thumb:SetPoint("TOPLEFT", self.track, "TOPLEFT", 0, -thumbOffset);
    end

    function container:SetContentHeight(height)
        self.scrollChild:SetHeight(height);
        self.scrollFrame:SetVerticalScroll(0);
        scrollTarget = 0;
        self.scrollFrame:SetScript("OnUpdate", nil);
        -- Defer thumb update to next frame (dimensions need to settle)
        C_Timer.After(0, function()
            self:UpdateThumb();
        end);
    end

    function container:UpdateContentHeight(height)
        self.scrollChild:SetHeight(height);
        -- Clamp current scroll to new range
        local visibleHeight = self.scrollFrame:GetHeight();
        local maxScroll = math.max(0, height - visibleHeight);
        local current = math.min(self.scrollFrame:GetVerticalScroll(), maxScroll);
        self.scrollFrame:SetVerticalScroll(current);
        scrollTarget = current;
        self.scrollFrame:SetScript("OnUpdate", nil);
        C_Timer.After(0, function()
            self:UpdateThumb();
        end);
    end

    function container:Reset()
        self.scrollFrame:SetVerticalScroll(0);
        scrollTarget = 0;
        self.scrollFrame:SetScript("OnUpdate", nil);
        self.track:Hide();
        self.thumb:Hide();
    end

    return container;
end

-------------------------------------------------------------------------------
-- Content renderer
-------------------------------------------------------------------------------

local widgetFactories = {
    toggle      = { create = CreateToggle,   setup = SetupToggle },
    label       = { create = CreateLabel,    setup = SetupLabel },
    description = { create = CreateLabel,    setup = SetupLabel },
    header      = { create = CreateHeader,   setup = SetupHeader },
    divider     = { create = CreateDivider,  setup = SetupDivider },
    range       = { create = CreateRange,    setup = SetupRange },
    select      = { create = CreateSelect,   setup = SetupSelect },
    execute     = { create = CreateExecute,  setup = SetupExecute },
    input       = { create = CreateInput,    setup = SetupInput },
    color       = { create = CreateColor,    setup = SetupColor },
    group       = { create = CreateGroup,   setup = SetupGroup },
};

local lastRenderArgs = {};  -- stored for group re-render on expand/collapse

local function RenderContent(scrollContainer, options, headerInfo, pageKey, preserveScroll)
    ReleaseAll();

    currentPageKey = pageKey or "";
    lastRenderArgs = { scrollContainer = scrollContainer, options = options, headerInfo = headerInfo, pageKey = pageKey };

    local parent = scrollContainer.scrollChild;
    local scrollWidth = scrollContainer.scrollFrame:GetWidth();
    local contentWidth = scrollWidth - CONTENT_PAD * 2 - 10;  -- 10 for scrollbar space
    parent:SetWidth(scrollWidth);

    local y = -CONTENT_PAD;

    -- Reset description panel default
    SetDefaultDescription("", "");

    -- Content header (title + description + divider)
    if (headerInfo and headerInfo.title) then
        local title = headerInfo.title;
        local desc = headerInfo.description;

        -- Title
        local titleW = CreateLabel(parent);
        SetupLabel(titleW, parent, {
            text = title,
            fontSize = "large",
            color = T.textBright,
        }, contentWidth);
        titleW.frame:ClearAllPoints();
        titleW.frame:SetPoint("TOPLEFT", parent, "TOPLEFT", CONTENT_PAD, y);
        y = y - (titleW.height or 20) - 2;

        -- Description
        if (desc) then
            local descW = CreateLabel(parent);
            SetupLabel(descW, parent, {
                text = desc,
                fontSize = "small",
                color = T.textDim,
            }, contentWidth);
            descW.frame:ClearAllPoints();
            descW.frame:SetPoint("TOPLEFT", parent, "TOPLEFT", CONTENT_PAD, y);
            y = y - (descW.height or 14) - 2;
        end

        -- Divider after header
        local divW = CreateDivider(parent);
        SetupDivider(divW, parent, {}, contentWidth);
        divW.frame:ClearAllPoints();
        divW.frame:SetPoint("TOPLEFT", parent, "TOPLEFT", CONTENT_PAD, y);
        y = y - (divW.height or DIVIDER_HEIGHT);
    end

    -- Helper: check hidden flag
    local function isHidden(data)
        if (not data.hidden) then return false; end
        if (type(data.hidden) == "function") then return data.hidden(); end
        return data.hidden;
    end

    -- Helper: render a single widget and advance y
    local function renderWidget(data)
        local factory = widgetFactories[data.type];
        if (not factory or isHidden(data)) then return; end

        local w = factory.create(parent);
        factory.setup(w, parent, data, contentWidth);
        w.frame:ClearAllPoints();
        w.frame:SetPoint("TOPLEFT", parent, "TOPLEFT", CONTENT_PAD, y);
        y = y - (w.height or 20) - WIDGET_GAP;

        -- Group widgets need a re-render callback for expand/collapse
        if (data.type == "group") then
            w._reRender = function()
                local args = lastRenderArgs;
                if (args.scrollContainer) then
                    RenderContent(args.scrollContainer, args.options, args.headerInfo, args.pageKey, true);
                end
            end;

            -- If expanded, render children inline
            if (w._expanded and data.children) then
                for _, childData in ipairs(data.children) do
                    if (childData.type ~= "group") then
                        renderWidget(childData);
                    end
                end
            end
        end
    end

    -- Render each option entry
    for _, data in ipairs(options) do
        renderWidget(data);
    end

    -- Set total content height
    local totalHeight = math.abs(y) + CONTENT_PAD;
    if (preserveScroll) then
        scrollContainer:UpdateContentHeight(totalHeight);
    else
        scrollContainer:SetContentHeight(totalHeight);
    end
end

local function ResetGroupStates()
    wipe(groupStates);
end

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------

_G.LanternUX = _G.LanternUX or {};
LanternUX.RenderContent = RenderContent;
LanternUX.ReleaseAll = ReleaseAll;
LanternUX.ResetGroupStates = ResetGroupStates;
LanternUX.CreateScrollContainer = CreateScrollContainer;
LanternUX.Theme = T;
