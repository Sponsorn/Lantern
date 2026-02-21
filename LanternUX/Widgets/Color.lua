local ADDON_NAME = ...;

local _W = LanternUX._W;
local T = _W.T;
local AcquireWidget = _W.AcquireWidget;
local RegisterWidget = _W.RegisterWidget;
local ShowDescription = _W.ShowDescription;
local ClearDescription = _W.ClearDescription;
local EvalDisabled = _W.EvalDisabled;
local NextName = _W.NextName;

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local COLOR_HEIGHT = 22;
local SWATCH_SIZE  = 16;

-------------------------------------------------------------------------------
-- Create / Setup
-------------------------------------------------------------------------------

local function CreateColor(parent)
    local w = AcquireWidget("color", parent);
    if (w) then return w; end

    w = {};
    local frame = CreateFrame("Frame", NextName("LUX_Color_"), parent);
    frame:SetHeight(COLOR_HEIGHT);
    w.frame = frame;

    -- Label (left)
    local label = frame:CreateFontString(nil, "ARTWORK", T.fontBody);
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
    local btn = CreateFrame("Button", NextName("LUX_ColorBtn_"), frame);
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

    -- Click -> open native color picker
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
-- Register
-------------------------------------------------------------------------------

_W.factories.color = { create = CreateColor, setup = SetupColor };

_W.refreshers.color = function(w)
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
end;
