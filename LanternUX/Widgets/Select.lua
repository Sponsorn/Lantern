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

local SELECT_HEIGHT      = 28;
local SELECT_BTN_W       = 160;
local SELECT_BTN_H       = 24;
local SELECT_ITEM_H      = 24;
local SELECT_MAX_VISIBLE = 10;

-------------------------------------------------------------------------------
-- Dropdown popup (shared singleton)
-------------------------------------------------------------------------------

local dropdownPopup;

local function CloseDropdown()
    if (dropdownPopup) then
        dropdownPopup:Hide();
        dropdownPopup._owner = nil;
    end
end

-- Register cleanup hook so Core's ReleaseAll can close the dropdown
_W.closeDropdown = CloseDropdown;

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
        f._closeListener = f._closeListener or CreateFrame("Button", "LUX_DropdownOverlay", UIParent);
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

    -- Scroll frame inside the popup for long lists
    local scrollFrame = CreateFrame("ScrollFrame", "LUX_DropdownScroll", f);
    scrollFrame:SetPoint("TOPLEFT", 1, -1);
    scrollFrame:SetPoint("BOTTOMRIGHT", -1, 1);
    scrollFrame:EnableMouseWheel(true);
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local maxScroll = self._maxScroll or 0;
        if (maxScroll <= 0) then return; end
        local current = self:GetVerticalScroll();
        local newScroll = math.max(0, math.min(maxScroll, current - delta * SELECT_ITEM_H * 2));
        self:SetVerticalScroll(newScroll);
    end);

    local scrollChild = CreateFrame("Frame", "LUX_DropdownScrollChild", scrollFrame);
    scrollChild:SetWidth(1);
    scrollFrame:SetScrollChild(scrollChild);

    f._scrollFrame = scrollFrame;
    f._scrollChild = scrollChild;
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

    local scrollChild = popup._scrollChild;

    -- Create/show items
    local y = -4;
    local maxTextWidth = 0;
    local selectedIndex = 0;
    for i, key in ipairs(keys) do
        local item = popup._items[i];
        if (not item) then
            item = CreateFrame("Button", NextName("LUX_DropdownItem_"), scrollChild);
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
                if (self._owner) then
                    ShowDescription(self._owner._label:GetText(), self._owner._desc_text);
                end
            end);
            item:SetScript("OnLeave", function(self)
                self._bg:SetColorTexture(0, 0, 0, 0);
                ClearDescription();
            end);

            popup._items[i] = item;
        end

        item._owner = w;
        item:SetParent(scrollChild);
        item:ClearAllPoints();
        item:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, y);
        item:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, y);
        item._text:SetText(values[key]);
        item._text:SetTextColor(unpack(T.text));

        -- Track widest item for popup sizing
        local tw = item._text:GetStringWidth() or 0;
        if (tw > maxTextWidth) then maxTextWidth = tw; end

        -- Highlight current selection
        if (key == w._currentKey) then
            item._text:SetTextColor(unpack(T.accent));
            selectedIndex = i;
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

    -- Size popup (fit content, cap height for long lists)
    local totalContentHeight = math.abs(y) + 8;
    local maxVisibleHeight = SELECT_MAX_VISIBLE * SELECT_ITEM_H + 8;
    local popupHeight = math.min(totalContentHeight, maxVisibleHeight);
    local popupWidth = math.max(SELECT_BTN_W, maxTextWidth + 24);
    popup:SetWidth(popupWidth);
    popup:SetHeight(popupHeight);

    scrollChild:SetWidth(popupWidth - 2);
    scrollChild:SetHeight(totalContentHeight);

    -- Set scroll range and scroll selected item into view
    local maxScroll = math.max(0, totalContentHeight - popupHeight);
    popup._scrollFrame._maxScroll = maxScroll;
    if (selectedIndex > 0 and maxScroll > 0) then
        local selectedY = (selectedIndex - 1) * SELECT_ITEM_H;
        popup._scrollFrame:SetVerticalScroll(math.min(selectedY, maxScroll));
    else
        popup._scrollFrame:SetVerticalScroll(0);
    end

    -- Anchor below the select button
    popup:ClearAllPoints();
    popup:SetPoint("TOPLEFT", w._btn, "BOTTOMLEFT", 0, -2);

    popup:Show();
end

-------------------------------------------------------------------------------
-- Create / Setup
-------------------------------------------------------------------------------

local function CreateSelect(parent)
    local w = AcquireWidget("select", parent);
    if (w) then return w; end

    w = {};
    local frame = CreateFrame("Frame", NextName("LUX_Select_"), parent);
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
    local btn = CreateFrame("Button", NextName("LUX_SelectBtn_"), frame, "BackdropTemplate");
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
    local arrowWrap = CreateFrame("Frame", NextName("LUX_SelectArrow_"), btn);
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

    -- Proxy so refresh can call w._arrow:SetVertexColor()
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
        w._btn:SetBackdropColor(unpack(T.disabledBg));
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
-- Register
-------------------------------------------------------------------------------

_W.factories.select = { create = CreateSelect, setup = SetupSelect };

_W.refreshers.select = function(w)
    if (w._getFn) then
        w._currentKey = w._getFn();
        local values = w._values;
        if (type(values) == "function") then values = values(); end
        w._btnText:SetText((w._currentKey and values[w._currentKey]) or "");
    end
    local disabled = EvalDisabled(w);
    if (disabled) then
        w._label:SetTextColor(unpack(T.disabledText));
        w._btn:SetBackdropColor(unpack(T.disabledBg));
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
end;
