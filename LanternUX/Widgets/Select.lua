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

local SELECT_HEIGHT      = 32;
local SELECT_BTN_W       = 160;
local SELECT_BTN_H       = 28;
local SELECT_ITEM_H      = 24;
local SELECT_MAX_VISIBLE = 10;
local SCROLLBAR_W        = 10;
local SCROLLBAR_VISUAL_W = 3;
local SCROLLBAR_THUMB_MIN = 16;

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

    local scrollChild = CreateFrame("Frame", "LUX_DropdownScrollChild", scrollFrame);
    scrollChild:SetWidth(1);
    scrollFrame:SetScrollChild(scrollChild);

    -- Scrollbar track
    local track = CreateFrame("Frame", "LUX_DropdownTrack", f);
    track:SetWidth(SCROLLBAR_W);
    track:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -2);
    track:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 2);
    track:EnableMouse(true);
    local trackBg = track:CreateTexture(nil, "BACKGROUND");
    trackBg:SetWidth(SCROLLBAR_VISUAL_W);
    trackBg:SetPoint("TOP");
    trackBg:SetPoint("BOTTOM");
    trackBg:SetPoint("RIGHT", -1, 0);
    trackBg:SetColorTexture(unpack(T.scrollTrack));
    track:Hide();

    -- Scrollbar thumb
    local thumb = CreateFrame("Frame", "LUX_DropdownThumb", track);
    thumb:SetWidth(SCROLLBAR_W);
    thumb:EnableMouse(true);
    thumb:SetMovable(true);
    local thumbBg = thumb:CreateTexture(nil, "ARTWORK");
    thumbBg:SetWidth(SCROLLBAR_VISUAL_W);
    thumbBg:SetPoint("TOP");
    thumbBg:SetPoint("BOTTOM");
    thumbBg:SetPoint("RIGHT", -1, 0);
    thumbBg:SetColorTexture(unpack(T.scrollThumb));
    thumb:Hide();

    -- Thumb position updater
    local function UpdateDropdownThumb()
        local maxScroll = scrollFrame._maxScroll or 0;
        if (maxScroll <= 0) then
            track:Hide();
            thumb:Hide();
            scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1);
            return;
        end

        track:Show();
        thumb:Show();
        scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -(SCROLLBAR_W + 1), 1);

        local trackHeight = track:GetHeight();
        local thumbHeight = math.max(SCROLLBAR_THUMB_MIN, (1 - maxScroll / (maxScroll + scrollFrame:GetHeight())) * trackHeight);
        thumb:SetHeight(thumbHeight);

        local currentScroll = scrollFrame:GetVerticalScroll();
        local scrollRatio = (maxScroll > 0) and (currentScroll / maxScroll) or 0;
        local thumbOffset = scrollRatio * (trackHeight - thumbHeight);

        thumb:ClearAllPoints();
        thumb:SetPoint("TOPLEFT", track, "TOPLEFT", 0, -thumbOffset);
    end
    f._updateThumb = UpdateDropdownThumb;

    -- Mouse wheel scrolling
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local maxScroll = self._maxScroll or 0;
        if (maxScroll <= 0) then return; end
        local current = self:GetVerticalScroll();
        local newScroll = math.max(0, math.min(maxScroll, current - delta * SELECT_ITEM_H * 2));
        self:SetVerticalScroll(newScroll);
        UpdateDropdownThumb();
    end);

    -- Thumb drag
    local isDragging = false;
    local dragStartY, dragStartScroll;

    thumb:SetScript("OnMouseDown", function(_, button)
        if (button ~= "LeftButton") then return; end
        isDragging = true;
        dragStartY = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale();
        dragStartScroll = scrollFrame:GetVerticalScroll();
    end);
    thumb:SetScript("OnMouseUp", function() isDragging = false; end);
    track:SetScript("OnMouseUp", function() isDragging = false; end);

    thumb:SetScript("OnUpdate", function()
        if (not isDragging) then return; end
        local cursorY = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale();
        local deltaY = dragStartY - cursorY;
        local trackHeight = track:GetHeight();
        local thumbHeight = thumb:GetHeight();
        local maxScroll = scrollFrame._maxScroll or 0;
        if (trackHeight <= thumbHeight or maxScroll <= 0) then return; end
        local scrollPerPixel = maxScroll / (trackHeight - thumbHeight);
        local newScroll = math.max(0, math.min(dragStartScroll + deltaY * scrollPerPixel, maxScroll));
        scrollFrame:SetVerticalScroll(newScroll);
        UpdateDropdownThumb();
    end);

    -- Track click to jump
    track:SetScript("OnMouseDown", function(_, button)
        if (button ~= "LeftButton") then return; end
        local cursorY = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale();
        local trackTop = track:GetTop();
        local trackHeight = track:GetHeight();
        if (not trackTop or trackHeight <= 0) then return; end
        local clickRatio = (trackTop - cursorY) / trackHeight;
        clickRatio = math.max(0, math.min(clickRatio, 1));
        local maxScroll = scrollFrame._maxScroll or 0;
        scrollFrame:SetVerticalScroll(clickRatio * maxScroll);
        UpdateDropdownThumb();
    end);

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
    local hasPreview = (w._previewFn ~= nil);
    local previewBtnW = 22;
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

            local itemText = item:CreateFontString(nil, "ARTWORK", T.fontBody);
            itemText:SetPoint("LEFT", 10, 0);
            itemText:SetJustifyH("LEFT");
            item._text = itemText;

            -- Preview icon (created once, shown/hidden per dropdown open)
            local pvBtn = CreateFrame("Button", NextName("LUX_DropdownPreview_"), item);
            pvBtn:SetSize(previewBtnW, SELECT_ITEM_H);
            pvBtn:SetPoint("RIGHT", item, "RIGHT", 0, 0);
            local pvIcon = pvBtn:CreateTexture(nil, "ARTWORK");
            pvIcon:SetSize(12, 12);
            pvIcon:SetPoint("CENTER");
            pvIcon:SetAtlas("voicechat-icon-speaker");
            pvIcon:SetVertexColor(unpack(T.textDim));
            pvBtn._icon = pvIcon;
            pvBtn:Hide();
            item._previewBtn = pvBtn;

            pvBtn:SetScript("OnEnter", function()
                pvIcon:SetVertexColor(unpack(T.accent));
                item._bg:SetColorTexture(unpack(T.dropdownItem));
            end);
            pvBtn:SetScript("OnLeave", function()
                pvIcon:SetVertexColor(unpack(T.textDim));
                item._bg:SetColorTexture(0, 0, 0, 0);
            end);

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

        -- Preview button: show/hide and wire up per item
        if (hasPreview) then
            item._text:SetPoint("RIGHT", item._previewBtn, "LEFT", -2, 0);
            item._previewBtn:Show();
            item._previewBtn:SetScript("OnClick", function()
                w._previewFn(key);
            end);
        else
            item._text:SetPoint("RIGHT", item, "RIGHT", -10, 0);
            item._previewBtn:Hide();
        end

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
    local needsScroll = (totalContentHeight > popupHeight);
    local scrollbarExtra = needsScroll and SCROLLBAR_W or 0;
    local previewExtra = hasPreview and previewBtnW or 0;
    local popupWidth = math.max(SELECT_BTN_W, maxTextWidth + 24 + scrollbarExtra + previewExtra);
    popup:SetWidth(popupWidth);
    popup:SetHeight(popupHeight);

    scrollChild:SetWidth(popupWidth - 2 - scrollbarExtra);
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

    -- Update scrollbar after show (needs valid dimensions)
    if (popup._updateThumb) then
        popup._updateThumb();
    end
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

    local btnText = btn:CreateFontString(nil, "ARTWORK", T.fontBody);
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
            btn:SetBackdropBorderColor(unpack(T.inputFocus));
        end
        ShowDescription(w._label:GetText(), w._desc_text);
    end);
    btn:SetScript("OnLeave", function()
        if (not w._disabled) then
            btn:SetBackdropColor(unpack(T.buttonBg));
            btn:SetBackdropBorderColor(unpack(T.buttonBorder));
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
    w._previewFn = data.preview;

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
