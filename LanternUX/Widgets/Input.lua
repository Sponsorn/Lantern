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

local INPUT_HEIGHT = 44;
local INPUT_BOX_H  = 24;

-------------------------------------------------------------------------------
-- Item link insertion hook
-------------------------------------------------------------------------------

hooksecurefunc("ChatEdit_InsertLink", function(text)
    if (_W.activeInputBox and _W.activeInputBox:HasFocus()) then
        _W.activeInputBox:Insert(text);
    end
end);

-------------------------------------------------------------------------------
-- Create / Setup
-------------------------------------------------------------------------------

local function CreateInput(parent)
    local w = AcquireWidget("input", parent);
    if (w) then return w; end

    w = {};
    local frame = CreateFrame("Frame", NextName("LUX_Input_"), parent);
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
    local box = CreateFrame("EditBox", NextName("LUX_InputBox_"), frame, "BackdropTemplate");
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

    -- Focus highlight + item link insertion tracking
    box:SetScript("OnEditFocusGained", function(self)
        _W.activeInputBox = self;
        if (not w._disabled) then
            self:SetBackdropBorderColor(unpack(T.inputFocus));
        end
    end);
    box:SetScript("OnEditFocusLost", function(self)
        if (_W.activeInputBox == self) then _W.activeInputBox = nil; end
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
        w._box:SetBackdropColor(unpack(T.disabledBg));
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
-- Register
-------------------------------------------------------------------------------

_W.factories.input = { create = CreateInput, setup = SetupInput };

_W.refreshers.input = function(w)
    if (w._getFn and not w._box:HasFocus()) then
        w._box:SetText(w._getFn() or "");
    end
    local disabled = EvalDisabled(w);
    if (disabled) then
        w._label:SetTextColor(unpack(T.disabledText));
        w._box:SetBackdropColor(unpack(T.disabledBg));
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
end;
