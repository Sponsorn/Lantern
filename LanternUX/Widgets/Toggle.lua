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

local TOGGLE_SIZE = 16;
local TOGGLE_PAD  = 8;

-------------------------------------------------------------------------------
-- Create / Setup
-------------------------------------------------------------------------------

local function CreateToggle(parent)
    local w = AcquireWidget("toggle", parent);
    if (w) then return w; end

    w = {};
    local frame = CreateFrame("Button", NextName("LUX_Toggle_"), parent);
    frame:SetHeight(TOGGLE_SIZE + 4);
    w.frame = frame;

    -- Checkbox box
    local box = CreateFrame("Frame", NextName("LUX_ToggleBox_"), frame);
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
        w._boxInner:SetColorTexture(unpack(T.disabledBg));
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
-- Register
-------------------------------------------------------------------------------

_W.factories.toggle = { create = CreateToggle, setup = SetupToggle };

_W.refreshers.toggle = function(w)
    if (w._getFn) then
        w._checked = w._getFn();
        if (w._checked) then w._mark:Show(); else w._mark:Hide(); end
    end
    local disabled = EvalDisabled(w);
    if (disabled) then
        w._boxBorder:SetColorTexture(unpack(T.disabled));
        w._boxInner:SetColorTexture(unpack(T.disabledBg));
        w._mark:SetColorTexture(unpack(T.accentDim));
        w._label:SetTextColor(unpack(T.disabledText));
    else
        w._boxBorder:SetColorTexture(unpack(T.checkBorder));
        w._boxInner:SetColorTexture(unpack(T.checkInner));
        w._mark:SetColorTexture(unpack(T.accent));
        w._label:SetTextColor(unpack(T.text));
    end
end;
