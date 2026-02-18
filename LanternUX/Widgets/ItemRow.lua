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

local ITEM_ROW_HEIGHT = 28;
local ITEM_ROW_ICON   = 20;
local ITEM_ROW_BTN_H  = 22;

-------------------------------------------------------------------------------
-- Create / Setup
-------------------------------------------------------------------------------

local function CreateItemRow(parent)
    local w = AcquireWidget("item_row", parent);
    if (w) then return w; end

    w = {};
    local frame = CreateFrame("Button", NextName("LUX_ItemRow_"), parent);
    frame:SetHeight(ITEM_ROW_HEIGHT);
    w.frame = frame;

    -- Icon (left side)
    local icon = frame:CreateTexture(nil, "ARTWORK");
    icon:SetSize(ITEM_ROW_ICON, ITEM_ROW_ICON);
    icon:SetPoint("LEFT", frame, "LEFT", 0, 0);
    w._icon = icon;

    -- Remove button (right side, created before text so text can anchor to it)
    local btn = CreateFrame("Button", NextName("LUX_ItemRowBtn_"), frame, "BackdropTemplate");
    btn:SetHeight(ITEM_ROW_BTN_H);
    btn:SetPoint("RIGHT", frame, "RIGHT", 0, 0);
    btn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    });
    btn:SetBackdropColor(unpack(T.buttonBg));
    btn:SetBackdropBorderColor(unpack(T.buttonBorder));
    w._btn = btn;

    local btnText = btn:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
    btnText:SetPoint("CENTER");
    btnText:SetText("Remove");
    btnText:SetTextColor(unpack(T.buttonText));
    w._btnText = btnText;

    -- Item name text (between icon and button)
    local nameText = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
    nameText:SetPoint("LEFT", icon, "RIGHT", 6, 0);
    nameText:SetPoint("RIGHT", btn, "LEFT", -8, 0);
    nameText:SetJustifyH("LEFT");
    nameText:SetWordWrap(false);
    nameText:SetTextColor(unpack(T.text));
    w._text = nameText;

    -- State
    w._disabled = false;
    w._confirming = false;

    -- Row hover (item tooltip)
    frame:SetScript("OnEnter", function(self)
        if (w._itemID) then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
            GameTooltip:SetItemByID(w._itemID);
            GameTooltip:Show();
        end
        ShowDescription(w._text:GetText(), w._desc_text);
    end);
    frame:SetScript("OnLeave", function()
        GameTooltip:Hide();
        ClearDescription();
    end);

    -- Button hover
    btn:SetScript("OnEnter", function()
        if (not w._disabled) then
            btn:SetBackdropColor(unpack(T.buttonHover));
            btn:SetBackdropBorderColor(unpack(T.inputFocus));
        end
        ShowDescription(w._originalLabel or "Remove", w._desc_text);
    end);
    btn:SetScript("OnLeave", function()
        if (not w._disabled) then
            btn:SetBackdropColor(unpack(T.buttonBg));
            btn:SetBackdropBorderColor(unpack(T.buttonBorder));
        end
        if (w._confirming) then
            w._confirming = false;
            w._btnText:SetText(w._originalLabel or "Remove");
            w._btnText:SetTextColor(unpack(T.buttonText));
        end
        ClearDescription();
    end);

    -- Button click (with confirm pattern)
    btn:SetScript("OnClick", function()
        if (w._disabled) then return; end

        if (w._confirmText and not w._confirming) then
            w._confirming = true;
            w._btnText:SetText(w._confirmText);
            w._btnText:SetTextColor(unpack(T.accent));
            return;
        end

        w._confirming = false;
        w._btnText:SetText(w._originalLabel or "Remove");
        w._btnText:SetTextColor(unpack(T.buttonText));
        if (w._func) then w._func(); end
    end);

    RegisterWidget("item_row", w);
    return w;
end

local function SetupItemRow(w, parent, data, contentWidth)
    w.frame:SetParent(parent);
    w.frame:SetWidth(contentWidth);

    w._itemID = data.itemID;
    w._originalLabel = data.buttonLabel or "Remove";
    w._btnText:SetText(w._originalLabel);
    w._func = data.func;
    w._confirmText = data.confirm;
    w._confirming = false;
    w._disabledFn = data.disabled;
    w._desc_text = data.desc;

    -- Button width: auto from label, minimum 80
    local textWidth = w._btnText:GetStringWidth() or 40;
    w._btn:SetWidth(math.max(80, textWidth + 20));

    w.frame:SetHeight(ITEM_ROW_HEIGHT);
    w.height = ITEM_ROW_HEIGHT;

    -- Icon (async-safe)
    local iconPath = C_Item.GetItemIconByID(data.itemID);
    if (iconPath) then
        w._icon:SetTexture(iconPath);
    else
        w._icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
        local item = Item:CreateFromItemID(data.itemID);
        item:ContinueOnItemLoad(function()
            local loaded = C_Item.GetItemIconByID(data.itemID);
            if (loaded and w._icon and w._inUse) then
                w._icon:SetTexture(loaded);
            end
        end);
    end

    -- Name (async-safe)
    local displayName = data.itemName;
    if (not displayName or displayName == "") then
        displayName = C_Item.GetItemNameByID(data.itemID);
    end
    if (displayName and displayName ~= "") then
        w._text:SetText(displayName);
    else
        w._text:SetText("Loading...");
        local item = Item:CreateFromItemID(data.itemID);
        item:ContinueOnItemLoad(function()
            local loaded = C_Item.GetItemNameByID(data.itemID);
            if (loaded and w._text and w._inUse) then
                w._text:SetText(loaded);
            end
        end);
    end

    -- Disabled state
    local disabled = false;
    if (data.disabled) then
        if (type(data.disabled) == "function") then disabled = data.disabled();
        else disabled = data.disabled; end
    end
    w._disabled = disabled;

    if (disabled) then
        w._text:SetTextColor(unpack(T.disabledText));
        w._icon:SetVertexColor(0.5, 0.5, 0.5);
        w._btn:SetBackdropColor(unpack(T.disabledBg));
        w._btn:SetBackdropBorderColor(unpack(T.disabled));
        w._btnText:SetTextColor(unpack(T.disabledText));
    else
        w._text:SetTextColor(unpack(T.text));
        w._icon:SetVertexColor(1, 1, 1);
        w._btn:SetBackdropColor(unpack(T.buttonBg));
        w._btn:SetBackdropBorderColor(unpack(T.buttonBorder));
        w._btnText:SetTextColor(unpack(T.buttonText));
    end

    return w;
end

-------------------------------------------------------------------------------
-- Register
-------------------------------------------------------------------------------

_W.factories.item_row = { create = CreateItemRow, setup = SetupItemRow };

_W.refreshers.item_row = function(w)
    local disabled = EvalDisabled(w);
    if (disabled) then
        w._text:SetTextColor(unpack(T.disabledText));
        w._icon:SetVertexColor(0.5, 0.5, 0.5);
        w._btn:SetBackdropColor(unpack(T.disabledBg));
        w._btn:SetBackdropBorderColor(unpack(T.disabled));
        w._btnText:SetTextColor(unpack(T.disabledText));
    else
        w._text:SetTextColor(unpack(T.text));
        w._icon:SetVertexColor(1, 1, 1);
        w._btn:SetBackdropColor(unpack(T.buttonBg));
        w._btn:SetBackdropBorderColor(unpack(T.buttonBorder));
        w._btnText:SetTextColor(unpack(T.buttonText));
    end
end;
