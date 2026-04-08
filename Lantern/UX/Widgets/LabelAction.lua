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

local LABEL_ACTION_HEIGHT = 28;
local LABEL_ACTION_BTN_H  = 22;

-------------------------------------------------------------------------------
-- Create / Setup
-------------------------------------------------------------------------------

local function CreateLabelAction(parent)
    local w = AcquireWidget("label_action", parent);
    if (w) then return w; end

    w = {};
    local frame = CreateFrame("Frame", NextName("LUX_LabelAction_"), parent);
    frame:SetHeight(LABEL_ACTION_HEIGHT);
    frame:EnableMouse(true);
    w.frame = frame;

    -- Button (right side, created first so text can anchor to it)
    local btn = CreateFrame("Button", NextName("LUX_LabelActionBtn_"), frame, "BackdropTemplate");
    btn:SetHeight(LABEL_ACTION_BTN_H);
    btn:SetPoint("RIGHT", frame, "RIGHT", 0, 0);
    btn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    });
    btn:SetBackdropColor(unpack(T.buttonBg));
    btn:SetBackdropBorderColor(unpack(T.buttonBorder));
    w._btn = btn;

    local btnText = btn:CreateFontString(nil, "ARTWORK", T.fontSmall);
    btnText:SetPoint("CENTER");
    btnText:SetTextColor(unpack(T.buttonText));
    w._btnText = btnText;

    -- Text label (left side)
    local text = frame:CreateFontString(nil, "ARTWORK", T.fontBody);
    text:SetPoint("LEFT", frame, "LEFT", 0, 0);
    text:SetPoint("RIGHT", btn, "LEFT", -8, 0);
    text:SetJustifyH("LEFT");
    text:SetWordWrap(false);
    text:SetTextColor(unpack(T.text));
    w._text = text;

    -- State
    w._disabled = false;
    w._confirming = false;

    -- Hover (button)
    btn:SetScript("OnEnter", function()
        if (not w._disabled) then
            btn:SetBackdropColor(unpack(T.buttonHover));
            btn:SetBackdropBorderColor(unpack(T.inputFocus));
        end
        ShowDescription(w._originalLabel or w._btnText:GetText(), w._desc_text);
    end);
    btn:SetScript("OnLeave", function()
        if (not w._disabled) then
            btn:SetBackdropColor(unpack(T.buttonBg));
            btn:SetBackdropBorderColor(unpack(T.buttonBorder));
        end
        if (w._confirming) then
            w._confirming = false;
            w._btnText:SetText(w._originalLabel or "");
            w._btnText:SetTextColor(unpack(T.buttonText));
        end
        ClearDescription();
    end);

    -- Click (button)
    btn:SetScript("OnClick", function()
        if (w._disabled) then return; end

        if (w._confirmText and not w._confirming) then
            w._confirming = true;
            w._btnText:SetText(w._confirmText);
            w._btnText:SetTextColor(unpack(T.dangerText));
            btn:SetBackdropColor(unpack(T.dangerBg));
            btn:SetBackdropBorderColor(unpack(T.dangerBorder));
            return;
        end

        w._confirming = false;
        w._btnText:SetText(w._originalLabel or "");
        w._btnText:SetTextColor(unpack(T.buttonText));
        btn:SetBackdropColor(unpack(T.buttonBg));
        btn:SetBackdropBorderColor(unpack(T.buttonBorder));
        if (w._func) then w._func(); end
    end);

    -- Hover (text label area -- show description on hover)
    frame:SetScript("OnEnter", function()
        ShowDescription(w._originalLabel or w._btnText:GetText(), w._desc_text);
    end);
    frame:SetScript("OnLeave", function()
        ClearDescription();
    end);

    RegisterWidget("label_action", w);
    return w;
end

local function SetupLabelAction(w, parent, data, contentWidth)
    w.frame:SetParent(parent);
    w.frame:SetWidth(contentWidth);

    -- Text
    w._text:SetText(data.text or "");

    -- Button
    w._originalLabel = data.buttonLabel or "Action";
    w._btnText:SetText(w._originalLabel);
    w._func = data.func;
    w._confirmText = data.confirm;
    w._confirming = false;
    w._disabledFn = data.disabled;
    w._desc_text = data.desc;

    -- Button width: auto from label, minimum 80
    local textWidth = w._btnText:GetStringWidth() or 40;
    w._btn:SetWidth(math.max(80, textWidth + 20));

    w.frame:SetHeight(LABEL_ACTION_HEIGHT);
    w.height = LABEL_ACTION_HEIGHT;

    -- Disabled state
    local disabled = false;
    if (data.disabled) then
        if (type(data.disabled) == "function") then disabled = data.disabled();
        else disabled = data.disabled; end
    end
    w._disabled = disabled;

    if (disabled) then
        w._text:SetTextColor(unpack(T.disabledText));
        w._btn:SetBackdropColor(unpack(T.disabledBg));
        w._btn:SetBackdropBorderColor(unpack(T.disabled));
        w._btnText:SetTextColor(unpack(T.disabledText));
    else
        w._text:SetTextColor(unpack(T.text));
        w._btn:SetBackdropColor(unpack(T.buttonBg));
        w._btn:SetBackdropBorderColor(unpack(T.buttonBorder));
        w._btnText:SetTextColor(unpack(T.buttonText));
    end

    return w;
end

-------------------------------------------------------------------------------
-- Register
-------------------------------------------------------------------------------

_W.factories.label_action = { create = CreateLabelAction, setup = SetupLabelAction };

_W.refreshers.label_action = function(w)
    local disabled = EvalDisabled(w);
    if (disabled) then
        w._text:SetTextColor(unpack(T.disabledText));
        w._btn:SetBackdropColor(unpack(T.disabledBg));
        w._btn:SetBackdropBorderColor(unpack(T.disabled));
        w._btnText:SetTextColor(unpack(T.disabledText));
    else
        w._text:SetTextColor(unpack(T.text));
        w._btn:SetBackdropColor(unpack(T.buttonBg));
        w._btn:SetBackdropBorderColor(unpack(T.buttonBorder));
        w._btnText:SetTextColor(unpack(T.buttonText));
    end
end;
