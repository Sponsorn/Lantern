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

local EXECUTE_HEIGHT = 32;
local EXECUTE_BTN_H  = 28;

-------------------------------------------------------------------------------
-- Create / Setup
-------------------------------------------------------------------------------

local function CreateExecute(parent)
    local w = AcquireWidget("execute", parent);
    if (w) then return w; end

    w = {};
    local frame = CreateFrame("Frame", NextName("LUX_Execute_"), parent);
    frame:SetHeight(EXECUTE_HEIGHT);
    w.frame = frame;

    -- Button
    local btn = CreateFrame("Button", NextName("LUX_ExecuteBtn_"), frame, "BackdropTemplate");
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
        w._btn:SetBackdropColor(unpack(T.disabledBg));
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
-- Register
-------------------------------------------------------------------------------

_W.factories.execute = { create = CreateExecute, setup = SetupExecute };

_W.refreshers.execute = function(w)
    local disabled = EvalDisabled(w);
    if (disabled) then
        w._btn:SetBackdropColor(unpack(T.disabledBg));
        w._btn:SetBackdropBorderColor(unpack(T.disabled));
        w._btnText:SetTextColor(unpack(T.disabledText));
    else
        w._btn:SetBackdropColor(unpack(T.buttonBg));
        w._btn:SetBackdropBorderColor(unpack(T.buttonBorder));
        w._btnText:SetTextColor(unpack(T.buttonText));
    end
end;
