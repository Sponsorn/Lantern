local ADDON_NAME = ...;

local _W = LanternUX._W;
local T = _W.T;
local AcquireWidget = _W.AcquireWidget;
local RegisterWidget = _W.RegisterWidget;
local ShowDescription = _W.ShowDescription;
local ClearDescription = _W.ClearDescription;
local NextName = _W.NextName;

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local DROP_SLOT_SIZE   = 37;
local DROP_SLOT_HEIGHT = 44;

-------------------------------------------------------------------------------
-- Create / Setup
-------------------------------------------------------------------------------

local function CreateDropSlot(parent)
    local w = AcquireWidget("drop_slot", parent);
    if (w) then return w; end

    w = {};
    local frame = CreateFrame("Frame", NextName("LUX_DropSlot_"), parent);
    frame:SetHeight(DROP_SLOT_HEIGHT);
    frame:EnableMouse(true);
    w.frame = frame;

    -- Label (left side)
    local label = frame:CreateFontString(nil, "ARTWORK", T.fontBody);
    label:SetPoint("LEFT", frame, "LEFT", 0, 0);
    label:SetJustifyH("LEFT");
    label:SetTextColor(unpack(T.text));
    w._label = label;

    -- Slot button (right of label)
    local slot = CreateFrame("Button", NextName("LUX_DropSlotBtn_"), frame, "BackdropTemplate");
    slot:SetSize(DROP_SLOT_SIZE, DROP_SLOT_SIZE);
    slot:SetPoint("LEFT", label, "RIGHT", 8, 0);
    slot:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    });
    slot:SetBackdropColor(unpack(T.inputBg));
    slot:SetBackdropBorderColor(unpack(T.inputBorder));
    w._slot = slot;

    -- Item icon (shown briefly after drop)
    local icon = slot:CreateTexture(nil, "ARTWORK");
    icon:SetSize(DROP_SLOT_SIZE - 6, DROP_SLOT_SIZE - 6);
    icon:SetPoint("CENTER");
    icon:Hide();
    w._icon = icon;

    -- Plus overlay
    local plus = slot:CreateTexture(nil, "OVERLAY");
    plus:SetSize(20, 20);
    plus:SetPoint("CENTER");
    plus:SetTexture("Interface\\PaperDollInfoFrame\\Character-Plus");
    plus:SetAlpha(0.7);
    w._plus = plus;

    -- Highlight overlay
    local highlight = slot:CreateTexture(nil, "HIGHLIGHT");
    highlight:SetAllPoints();
    highlight:SetColorTexture(unpack(T.hover));
    w._highlight = highlight;

    -- State
    w._disabled = false;

    -- Drop handler
    local function handleDrop()
        if (w._disabled) then return; end
        local cursorType, itemID = GetCursorInfo();
        if (cursorType == "item" and itemID) then
            ClearCursor();
            -- Visual feedback: show icon briefly
            local iconPath = C_Item.GetItemIconByID(itemID);
            if (iconPath) then
                w._icon:SetTexture(iconPath);
                w._icon:Show();
                w._plus:Hide();
                C_Timer.After(0.5, function()
                    if (w._icon and w._inUse) then
                        w._icon:SetTexture(nil);
                        w._icon:Hide();
                        w._plus:Show();
                    end
                end);
            end
            if (w._onDrop) then w._onDrop(itemID); end
        end
    end

    slot:SetScript("OnReceiveDrag", handleDrop);
    slot:SetScript("OnClick", handleDrop);

    -- Hover (slot)
    slot:SetScript("OnEnter", function(self)
        if (not w._disabled) then
            slot:SetBackdropBorderColor(unpack(T.inputFocus));
        end
        ShowDescription(w._label:GetText(), w._desc_text);
    end);
    slot:SetScript("OnLeave", function()
        if (not w._disabled) then
            slot:SetBackdropBorderColor(unpack(T.inputBorder));
        end
        ClearDescription();
    end);

    -- Hover (label area)
    frame:SetScript("OnEnter", function()
        ShowDescription(w._label:GetText(), w._desc_text);
    end);
    frame:SetScript("OnLeave", ClearDescription);

    RegisterWidget("drop_slot", w);
    return w;
end

local function SetupDropSlot(w, parent, data, contentWidth)
    w.frame:SetParent(parent);
    w.frame:SetWidth(contentWidth);

    w._label:SetText(data.label or "");
    w._desc_text = data.desc;
    w._onDrop = data.onDrop;
    w._disabledFn = data.disabled;

    -- Reset icon state
    w._icon:SetTexture(nil);
    w._icon:Hide();
    w._plus:Show();

    w.frame:SetHeight(DROP_SLOT_HEIGHT);
    w.height = DROP_SLOT_HEIGHT;

    -- Disabled state
    local disabled = false;
    if (data.disabled) then
        if (type(data.disabled) == "function") then disabled = data.disabled();
        else disabled = data.disabled; end
    end
    w._disabled = disabled;

    if (disabled) then
        w._label:SetTextColor(unpack(T.disabledText));
        w._slot:SetBackdropColor(unpack(T.disabledBg));
        w._slot:SetBackdropBorderColor(unpack(T.disabled));
        w._plus:SetAlpha(0.3);
    else
        w._label:SetTextColor(unpack(T.text));
        w._slot:SetBackdropColor(unpack(T.inputBg));
        w._slot:SetBackdropBorderColor(unpack(T.inputBorder));
        w._plus:SetAlpha(0.7);
    end

    return w;
end

-------------------------------------------------------------------------------
-- Register
-------------------------------------------------------------------------------

_W.factories.drop_slot = { create = CreateDropSlot, setup = SetupDropSlot };
