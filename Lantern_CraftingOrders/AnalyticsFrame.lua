local ADDON_NAME, ns = ...;
local L = ns.L;
local Lantern = _G.Lantern;
if (not Lantern) then return; end

local CraftingOrders = Lantern.modules and Lantern.modules.CraftingOrders;
if (not CraftingOrders) then return; end

local T = _G.LanternUX and _G.LanternUX.Theme;
if (not T) then return; end

-------------------------------------------------------------------------------
-- Formatting helpers
-------------------------------------------------------------------------------

local function FormatMoney(copper)
    if (Lantern.Convert) then
        local result = Lantern:Convert("money:format_copper", copper);
        if (result and result ~= "") then return result; end
    end
    local amount = tonumber(copper) or 0;
    if (amount <= 0) then return "0g"; end
    local gold = math.floor(amount / 10000);
    local silver = math.floor((amount % 10000) / 100);
    if (gold > 0) then
        return string.format("%dg", gold);
    end
    if (silver > 0) then
        return string.format("%ds", silver);
    end
    return string.format("%dc", amount % 100);
end

local function FormatMoneyCompact(copper)
    local amount = tonumber(copper) or 0;
    if (amount <= 0) then return "0g"; end
    local gold = math.floor(amount / 10000);
    if (gold >= 1000000) then
        return string.format("%.1fM g", gold / 1000000);
    elseif (gold >= 1000) then
        return string.format("%.1fk g", gold / 1000);
    elseif (gold > 0) then
        return string.format("%dg", gold);
    end
    local silver = math.floor((amount % 10000) / 100);
    if (silver > 0) then
        return string.format("%ds", silver);
    end
    return string.format("%dc", amount % 100);
end

local function FormatTimeAgo(timestamp)
    if (not timestamp or timestamp == 0) then return ""; end
    local diff = time() - timestamp;
    if (diff < 60) then
        return L["CO_TIME_JUST_NOW"];
    elseif (diff < 3600) then
        return string.format(L["CO_TIME_MINUTES_AGO"], math.floor(diff / 60));
    elseif (diff < 86400) then
        return string.format(L["CO_TIME_HOURS_AGO"], math.floor(diff / 3600));
    else
        return string.format(L["CO_TIME_DAYS_AGO"], math.floor(diff / 86400));
    end
end

-------------------------------------------------------------------------------
-- Naming helper
-------------------------------------------------------------------------------

local nameCounter = 0;
local function NextName(prefix)
    nameCounter = nameCounter + 1;
    return prefix .. nameCounter;
end

-------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------

local panel = nil;
local charFilter = nil; -- nil = current character, "all" = all characters
local activePage = nil; -- tracks which page is currently shown

local SyncAllFilters; -- forward declaration (defined after page creators)

-------------------------------------------------------------------------------
-- Static popup for destructive actions
-------------------------------------------------------------------------------

StaticPopupDialogs["LANTERN_CO_CLEAR_HISTORY"] = {
    text = L["CO_CLEAR_HISTORY_CONFIRM"],
    button1 = YES,
    button2 = NO,
    OnAccept = function()
        CraftingOrders:ClearCharacterHistory();
        if (panel) then panel:RefreshCurrentPage(); end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
};

local function GetCharFilterForAPI()
    if (charFilter == "all") then return "all"; end
    return nil;
end

-------------------------------------------------------------------------------
-- Character filter dropdown (shared themed component)
-------------------------------------------------------------------------------

local activeDropdownMenu = nil;

local function CloseDropdownMenu()
    if (activeDropdownMenu) then
        activeDropdownMenu:Hide();
        activeDropdownMenu = nil;
    end
end

local function CreateCharFilterDropdown(parent, onChangeCallback)
    local DROPDOWN_W = 170;
    local DROPDOWN_H = 28;

    local baseName = NextName("LanternCO_Filter_");

    local dropFrame = CreateFrame("Frame", baseName, parent, "BackdropTemplate");
    dropFrame:SetSize(DROPDOWN_W, DROPDOWN_H);
    dropFrame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    });
    dropFrame:SetBackdropColor(unpack(T.inputBg));
    dropFrame:SetBackdropBorderColor(unpack(T.inputBorder));

    local btn = CreateFrame("Button", baseName .. "_Btn", dropFrame);
    btn:SetAllPoints();

    local label = btn:CreateFontString(baseName .. "_Label", "OVERLAY");
    label:SetFontObject(T.fontBody);
    label:SetPoint("LEFT", 10, 0);
    label:SetPoint("RIGHT", -20, 0);
    label:SetJustifyH("LEFT");
    label:SetTextColor(unpack(T.text));
    label:SetText(L["CO_FILTER_CURRENT"]);
    dropFrame._label = label;

    -- Arrow
    local arrow = btn:CreateFontString(baseName .. "_Arrow", "OVERLAY");
    arrow:SetFontObject(T.fontSmall);
    arrow:SetPoint("RIGHT", -6, 0);
    arrow:SetText("v");
    arrow:SetTextColor(unpack(T.textDim));

    -- Hover
    btn:SetScript("OnEnter", function()
        dropFrame:SetBackdropBorderColor(unpack(T.accent));
    end);
    btn:SetScript("OnLeave", function()
        dropFrame:SetBackdropBorderColor(unpack(T.inputBorder));
    end);

    -- Menu popup (parented to UIParent to avoid panel strata conflicts)
    local menuName = baseName .. "_Menu";
    local menu = CreateFrame("Frame", menuName, UIParent, "BackdropTemplate");
    menu:SetWidth(DROPDOWN_W);
    menu:SetFrameStrata("TOOLTIP");
    menu:SetClampedToScreen(true);
    menu:EnableMouse(true);
    menu:SetPoint("TOPLEFT", dropFrame, "BOTTOMLEFT", 0, -2);
    menu:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    });
    menu:SetBackdropColor(unpack(T.dropdownBg));
    menu:SetBackdropBorderColor(unpack(T.inputBorder));
    menu:Hide();

    -- Invisible overlay to catch outside clicks (frame level below menu)
    local overlay = CreateFrame("Button", baseName .. "_Overlay", UIParent);
    overlay:SetAllPoints(UIParent);
    overlay:SetFrameStrata("TOOLTIP");
    overlay:Hide();
    overlay:SetScript("OnClick", function()
        CloseDropdownMenu();
    end);

    -- Keep overlay one level below the menu
    menu:SetScript("OnShow", function()
        overlay:SetFrameLevel(menu:GetFrameLevel() - 1);
        overlay:Show();
    end);
    menu:SetScript("OnHide", function()
        overlay:Hide();
    end);

    local ITEM_H = 26;

    local function AddMenuItem(text, value, yOffset)
        local itemName = NextName(menuName .. "_Item_");
        local item = CreateFrame("Button", itemName, menu);
        item:SetHeight(ITEM_H);
        item:SetPoint("TOPLEFT", menu, "TOPLEFT", 1, -yOffset);
        item:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -1, -yOffset);

        local itemBg = item:CreateTexture(itemName .. "_HL", "HIGHLIGHT");
        itemBg:SetAllPoints();
        itemBg:SetColorTexture(unpack(T.dropdownItem));

        local itemLabel = item:CreateFontString(itemName .. "_Text", "OVERLAY");
        itemLabel:SetFontObject(T.fontBody);
        itemLabel:SetPoint("LEFT", 10, 0);
        itemLabel:SetTextColor(unpack(T.text));
        itemLabel:SetText(text);

        item:SetScript("OnClick", function()
            charFilter = value;
            label:SetText(text);
            menu:Hide();
            activeDropdownMenu = nil;
            if (onChangeCallback) then onChangeCallback(); end
        end);

        return item;
    end

    AddMenuItem(L["CO_FILTER_CURRENT"], nil, 1);
    AddMenuItem(L["CO_FILTER_ALL"], "all", 1 + ITEM_H);
    menu:SetHeight(2 + ITEM_H * 2);

    btn:SetScript("OnClick", function()
        if (menu:IsShown()) then
            menu:Hide();
            activeDropdownMenu = nil;
        else
            CloseDropdownMenu();
            menu:Show();
            activeDropdownMenu = menu;
        end
    end);

    -- Update label to reflect current state
    function dropFrame:UpdateLabel()
        if (charFilter == "all") then
            label:SetText(L["CO_FILTER_ALL"]);
        else
            label:SetText(L["CO_FILTER_CURRENT"]);
        end
    end

    return dropFrame;
end

-------------------------------------------------------------------------------
-- Page 1: Dashboard
-------------------------------------------------------------------------------

local dashScroll, dashFilter, dashTimeframeFilter;
local dashChart; -- barchart widget, created once
local dashChartHeader; -- section header frame
local dashChartSubtitle; -- info text fontstring
local dashTimeframe = "all"; -- "all", "day", "week", "month"
local dashElements = {};
local dashElementCount = 0;

local function HideAllDashElements()
    for i = 1, dashElementCount do
        if (dashElements[i]) then dashElements[i]:Hide(); end
    end
    dashElementCount = 0;
    if (dashChartHeader) then dashChartHeader:Hide(); end
    if (dashChartSubtitle) then dashChartSubtitle:Hide(); end
    if (dashChart) then dashChart.frame:Hide(); end
end

local function AcquireDashFrame(parent, height)
    dashElementCount = dashElementCount + 1;
    local idx = dashElementCount;
    local elem = dashElements[idx];
    if (not elem) then
        elem = CreateFrame("Frame", "LanternCO_Dash_" .. idx, parent);
        dashElements[idx] = elem;
    end
    elem:SetParent(parent);
    elem:SetHeight(height);
    elem:ClearAllPoints();
    -- Hide all sub-elements from previous reuse before showing
    if (elem._bg) then elem._bg:Hide(); end
    if (elem._border) then elem._border:Hide(); end
    if (elem._value) then elem._value:Hide(); end
    if (elem._label) then elem._label:Hide(); end
    if (elem._rankLabel) then elem._rankLabel:Hide(); end
    if (elem._nameLabel) then elem._nameLabel:Hide(); end
    if (elem._countLabel) then elem._countLabel:Hide(); end
    if (elem._valueLabel) then elem._valueLabel:Hide(); end
    if (elem._sectionLabel) then elem._sectionLabel:Hide(); end
    if (elem._divider) then elem._divider:Hide(); end
    elem:Show();
    return elem;
end

local function CreateStatCard(parent, yOffset, labelText, valueText, tooltipText)
    local CARD_W = 140;
    local CARD_H = 56;

    local card = AcquireDashFrame(parent, CARD_H);
    card:SetWidth(CARD_W);
    card:EnableMouse(tooltipText ~= nil);

    -- Card background
    if (not card._bg) then
        card._bg = card:CreateTexture(card:GetName() .. "_Bg", "BACKGROUND");
        card._bg:SetAllPoints();
    end
    card._bg:SetColorTexture(unpack(T.cardBg));
    card._bg:Show();

    -- Card border
    if (not card._border) then
        card._border = CreateFrame("Frame", card:GetName() .. "_Border", card, "BackdropTemplate");
        card._border:SetAllPoints();
        card._border:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        });
    end
    card._border:SetBackdropBorderColor(unpack(T.cardBorder));
    card._border:Show();

    -- Value text (large)
    if (not card._value) then
        card._value = card:CreateFontString(card:GetName() .. "_Val", "OVERLAY");
    end
    card._value:SetFontObject(T.fontHeading);
    card._value:ClearAllPoints();
    card._value:SetPoint("TOP", card, "TOP", 0, -10);
    card._value:SetText(valueText);
    card._value:SetTextColor(unpack(T.textBright));
    card._value:Show();

    -- Label text (small)
    if (not card._label) then
        card._label = card:CreateFontString(card:GetName() .. "_Lbl", "OVERLAY");
    end
    card._label:SetFontObject(T.fontSmall);
    card._label:ClearAllPoints();
    card._label:SetPoint("BOTTOM", card, "BOTTOM", 0, 8);
    card._label:SetText(labelText);
    card._label:SetTextColor(unpack(T.textDim));
    card._label:Show();

    -- Tooltip
    if (tooltipText) then
        card:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM");
            GameTooltip:AddLine(tooltipText, 1, 1, 1);
            GameTooltip:Show();
        end);
        card:SetScript("OnLeave", function() GameTooltip:Hide(); end);
    else
        card:SetScript("OnEnter", nil);
        card:SetScript("OnLeave", nil);
    end

    -- Hide sub-elements from other reuse types
    if (card._rankLabel) then card._rankLabel:Hide(); end
    if (card._nameLabel) then card._nameLabel:Hide(); end
    if (card._countLabel) then card._countLabel:Hide(); end
    if (card._valueLabel) then card._valueLabel:Hide(); end
    if (card._sectionLabel) then card._sectionLabel:Hide(); end

    return card;
end

local function FormatResetTime(seconds)
    if (not seconds or seconds <= 0) then return nil; end
    local days = math.floor(seconds / 86400);
    local hours = math.floor((seconds % 86400) / 3600);
    local mins = math.floor((seconds % 3600) / 60);
    if (days > 0) then
        return string.format(L["CO_DASH_RESETS_IN"], string.format("%dd %dh", days, hours));
    elseif (hours > 0) then
        return string.format(L["CO_DASH_RESETS_IN"], string.format("%dh %dm", hours, mins));
    else
        return string.format(L["CO_DASH_RESETS_IN"], string.format("%dm", mins));
    end
end

local function CreateTimeframeCard(parent, yOffset, labelText, orderCount, tipsCopper, resetEpoch)
    local CARD_W = 220;
    local CARD_H = 70;

    local card = AcquireDashFrame(parent, CARD_H);
    card:SetWidth(CARD_W);
    card:EnableMouse(tipsCopper > 0);

    -- Card background
    if (not card._bg) then
        card._bg = card:CreateTexture(card:GetName() .. "_Bg", "BACKGROUND");
        card._bg:SetAllPoints();
    end
    card._bg:SetColorTexture(unpack(T.cardBg));
    card._bg:Show();

    -- Card border
    if (not card._border) then
        card._border = CreateFrame("Frame", card:GetName() .. "_Border", card, "BackdropTemplate");
        card._border:SetAllPoints();
        card._border:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        });
    end
    card._border:SetBackdropBorderColor(unpack(T.cardBorder));
    card._border:Show();

    -- Orders count (large, left-aligned)
    if (not card._value) then
        card._value = card:CreateFontString(card:GetName() .. "_Val", "OVERLAY");
    end
    card._value:SetFontObject(T.fontHeading);
    card._value:ClearAllPoints();
    card._value:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -10);
    card._value:SetText(tostring(orderCount) .. " " .. (orderCount == 1 and L["CO_DASH_TF_ORDER"] or L["CO_DASH_TF_ORDERS"]));
    card._value:SetTextColor(unpack(T.textBright));
    card._value:Show();

    -- Tips amount (secondary line)
    if (not card._countLabel) then
        card._countLabel = card:CreateFontString(card:GetName() .. "_Tips", "OVERLAY");
    end
    card._countLabel:SetFontObject(T.fontBody);
    card._countLabel:ClearAllPoints();
    card._countLabel:SetPoint("TOPLEFT", card._value, "BOTTOMLEFT", 0, -2);
    card._countLabel:SetText(FormatMoneyCompact(tipsCopper) .. " earned");
    card._countLabel:SetTextColor(unpack(T.accent));
    card._countLabel:Show();

    -- Label text (small, bottom-left)
    if (not card._label) then
        card._label = card:CreateFontString(card:GetName() .. "_Lbl", "OVERLAY");
    end
    card._label:SetFontObject(T.fontSmall);
    card._label:ClearAllPoints();
    card._label:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 12, 6);
    card._label:SetText(labelText);
    card._label:SetTextColor(unpack(T.textDim));
    card._label:Show();

    -- Reset timer (small, bottom-right)
    if (not card._resetLabel) then
        card._resetLabel = card:CreateFontString(card:GetName() .. "_Reset", "OVERLAY");
    end
    local now = GetServerTime();
    local resetText = resetEpoch and FormatResetTime(resetEpoch - now) or nil;
    if (resetText) then
        card._resetLabel:SetFontObject(T.fontSmall);
        card._resetLabel:ClearAllPoints();
        card._resetLabel:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -12, 6);
        card._resetLabel:SetText(resetText);
        card._resetLabel:SetTextColor(unpack(T.textDim));
        card._resetLabel:Show();
    else
        card._resetLabel:Hide();
    end

    -- Tooltip with exact amount
    if (tipsCopper > 0) then
        card:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM");
            GameTooltip:AddLine(FormatMoney(tipsCopper), 1, 1, 1);
            GameTooltip:Show();
        end);
        card:SetScript("OnLeave", function() GameTooltip:Hide(); end);
    else
        card:SetScript("OnEnter", nil);
        card:SetScript("OnLeave", nil);
    end

    -- Hide sub-elements from other reuse types
    if (card._rankLabel) then card._rankLabel:Hide(); end
    if (card._nameLabel) then card._nameLabel:Hide(); end
    if (card._valueLabel) then card._valueLabel:Hide(); end
    if (card._sectionLabel) then card._sectionLabel:Hide(); end

    return card;
end

local function CreateDashSectionHeader(parent, yOffset, text)
    local header = AcquireDashFrame(parent, 24);
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, yOffset);
    header:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -16, yOffset);

    if (not header._sectionLabel) then
        header._sectionLabel = header:CreateFontString(header:GetName() .. "_SLbl", "OVERLAY");
        header._sectionLabel:SetFontObject(T.fontBodyBold);
        header._sectionLabel:SetPoint("LEFT", header, "LEFT", 0, 0);
        header._sectionLabel:SetJustifyH("LEFT");
    end
    header._sectionLabel:SetText(text);
    header._sectionLabel:SetTextColor(unpack(T.accent));
    header._sectionLabel:Show();

    -- Divider below
    if (not header._divider) then
        header._divider = header:CreateTexture(header:GetName() .. "_Div", "ARTWORK");
        header._divider:SetHeight(1);
        header._divider:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 0, 0);
        header._divider:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", 0, 0);
    end
    header._divider:SetColorTexture(unpack(T.divider));
    header._divider:Show();

    -- Hide sub-elements from other reuse types
    if (header._bg) then header._bg:Hide(); end
    if (header._border) then header._border:Hide(); end
    if (header._value) then header._value:Hide(); end
    if (header._label) then header._label:Hide(); end
    if (header._rankLabel) then header._rankLabel:Hide(); end
    if (header._nameLabel) then header._nameLabel:Hide(); end
    if (header._countLabel) then header._countLabel:Hide(); end
    if (header._valueLabel) then header._valueLabel:Hide(); end

    return header;
end

local function CreateDashColumnHeader(parent, yOffset, nameHeader, countHeader, valueHeader)
    local row = AcquireDashFrame(parent, 18);
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset);
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -20, yOffset);

    if (not row._nameLabel) then
        row._nameLabel = row:CreateFontString(row:GetName() .. "_Name", "OVERLAY");
    end
    row._nameLabel:SetFontObject(T.fontSmall);
    row._nameLabel:ClearAllPoints();
    row._nameLabel:SetPoint("LEFT", row, "LEFT", 24, 0);
    row._nameLabel:SetJustifyH("LEFT");
    row._nameLabel:SetText(nameHeader);
    row._nameLabel:SetTextColor(unpack(T.textDim));
    row._nameLabel:Show();

    if (not row._countLabel) then
        row._countLabel = row:CreateFontString(row:GetName() .. "_Cnt", "OVERLAY");
    end
    row._countLabel:SetFontObject(T.fontSmall);
    row._countLabel:ClearAllPoints();
    row._countLabel:SetPoint("RIGHT", row, "RIGHT", -100, 0);
    row._countLabel:SetWidth(60);
    row._countLabel:SetJustifyH("RIGHT");
    row._countLabel:SetText(countHeader);
    row._countLabel:SetTextColor(unpack(T.textDim));
    row._countLabel:Show();

    if (not row._valueLabel) then
        row._valueLabel = row:CreateFontString(row:GetName() .. "_Val", "OVERLAY");
    end
    row._valueLabel:SetFontObject(T.fontSmall);
    row._valueLabel:ClearAllPoints();
    row._valueLabel:SetPoint("RIGHT", row, "RIGHT", 0, 0);
    row._valueLabel:SetWidth(90);
    row._valueLabel:SetJustifyH("RIGHT");
    row._valueLabel:SetText(valueHeader);
    row._valueLabel:SetTextColor(unpack(T.textDim));
    row._valueLabel:Show();

    -- Hide sub-elements from other reuse types
    if (row._bg) then row._bg:Hide(); end
    if (row._border) then row._border:Hide(); end
    if (row._value) then row._value:Hide(); end
    if (row._label) then row._label:Hide(); end
    if (row._rankLabel) then row._rankLabel:Hide(); end
    if (row._sectionLabel) then row._sectionLabel:Hide(); end
    if (row._divider) then row._divider:Hide(); end

    return row;
end

local function CreateDashRankedRow(parent, yOffset, rank, name, countText, valueText)
    local row = AcquireDashFrame(parent, 20);
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset);
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -20, yOffset);

    if (not row._rankLabel) then
        row._rankLabel = row:CreateFontString(row:GetName() .. "_Rank", "OVERLAY");
    end
    row._rankLabel:SetFontObject(T.fontBody);
    row._rankLabel:ClearAllPoints();
    row._rankLabel:SetPoint("LEFT", row, "LEFT", 0, 0);
    row._rankLabel:SetWidth(20);
    row._rankLabel:SetJustifyH("LEFT");
    row._rankLabel:SetText(rank .. ".");
    row._rankLabel:SetTextColor(unpack(T.textDim));
    row._rankLabel:Show();

    if (not row._nameLabel) then
        row._nameLabel = row:CreateFontString(row:GetName() .. "_Name", "OVERLAY");
    end
    row._nameLabel:SetFontObject(T.fontBody);
    row._nameLabel:ClearAllPoints();
    row._nameLabel:SetPoint("LEFT", row._rankLabel, "RIGHT", 4, 0);
    row._nameLabel:SetPoint("RIGHT", row, "RIGHT", -170, 0);
    row._nameLabel:SetJustifyH("LEFT");
    row._nameLabel:SetWordWrap(false);
    row._nameLabel:SetText(name);
    row._nameLabel:SetTextColor(unpack(T.text));
    row._nameLabel:Show();

    if (not row._countLabel) then
        row._countLabel = row:CreateFontString(row:GetName() .. "_Cnt", "OVERLAY");
    end
    row._countLabel:SetFontObject(T.fontBody);
    row._countLabel:ClearAllPoints();
    row._countLabel:SetPoint("RIGHT", row, "RIGHT", -100, 0);
    row._countLabel:SetWidth(60);
    row._countLabel:SetJustifyH("RIGHT");
    row._countLabel:SetText(countText);
    row._countLabel:SetTextColor(unpack(T.textDim));
    row._countLabel:Show();

    if (not row._valueLabel) then
        row._valueLabel = row:CreateFontString(row:GetName() .. "_Val", "OVERLAY");
    end
    row._valueLabel:SetFontObject(T.fontBody);
    row._valueLabel:ClearAllPoints();
    row._valueLabel:SetPoint("RIGHT", row, "RIGHT", 0, 0);
    row._valueLabel:SetWidth(90);
    row._valueLabel:SetJustifyH("RIGHT");
    row._valueLabel:SetText(valueText);
    row._valueLabel:SetTextColor(unpack(T.textDim));
    row._valueLabel:Show();

    -- Hide sub-elements from other reuse types
    if (row._bg) then row._bg:Hide(); end
    if (row._border) then row._border:Hide(); end
    if (row._value) then row._value:Hide(); end
    if (row._label) then row._label:Hide(); end
    if (row._sectionLabel) then row._sectionLabel:Hide(); end
    if (row._divider) then row._divider:Hide(); end

    return row;
end

local function GetDashTimeframeSince()
    if (dashTimeframe == "all") then return nil; end
    local now = time();
    if (dashTimeframe == "day") then return now - (24 * 3600); end
    if (dashTimeframe == "week") then return now - (7 * 24 * 3600); end
    if (dashTimeframe == "month") then return now - (30 * 24 * 3600); end
    return nil;
end

local function GetChartParams()
    if (dashTimeframe == "day") then
        local since = GetServerTime() - 7 * 86400;
        return "daily", since, 7;
    elseif (dashTimeframe == "week") then
        local since = GetServerTime() - 14 * 86400;
        return "daily", since, 14;
    elseif (dashTimeframe == "month") then
        local since = GetServerTime() - 30 * 86400;
        return "daily", since, 30;
    else -- "all"
        local since = GetServerTime() - 12 * 7 * 86400;
        return "weekly", since, 12;
    end
end

local TIMEFRAME_OPTIONS = {
    { value = "all",   key = "CO_DASH_TIMEFRAME_ALL" },
    { value = "day",   key = "CO_DASH_TIMEFRAME_DAY" },
    { value = "week",  key = "CO_DASH_TIMEFRAME_WEEK" },
    { value = "month", key = "CO_DASH_TIMEFRAME_MONTH" },
};

local function CreateTimeframeDropdown(parent, onChangeCallback, getStateFn, setStateFn)
    local DROPDOWN_W = 150;
    local DROPDOWN_H = 28;

    local baseName = NextName("LanternCO_TFFilter_");

    local dropFrame = CreateFrame("Frame", baseName, parent, "BackdropTemplate");
    dropFrame:SetSize(DROPDOWN_W, DROPDOWN_H);
    dropFrame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    });
    dropFrame:SetBackdropColor(unpack(T.inputBg));
    dropFrame:SetBackdropBorderColor(unpack(T.inputBorder));

    local btn = CreateFrame("Button", baseName .. "_Btn", dropFrame);
    btn:SetAllPoints();

    local label = btn:CreateFontString(baseName .. "_Label", "OVERLAY");
    label:SetFontObject(T.fontBody);
    label:SetPoint("LEFT", 10, 0);
    label:SetPoint("RIGHT", -20, 0);
    label:SetJustifyH("LEFT");
    label:SetTextColor(unpack(T.text));
    local initialValue = getStateFn and getStateFn() or "all";
    for _, o in ipairs(TIMEFRAME_OPTIONS) do
        if (o.value == initialValue) then
            label:SetText(L[o.key]);
            break;
        end
    end
    dropFrame._label = label;

    local arrow = btn:CreateFontString(baseName .. "_Arrow", "OVERLAY");
    arrow:SetFontObject(T.fontSmall);
    arrow:SetPoint("RIGHT", -6, 0);
    arrow:SetText("v");
    arrow:SetTextColor(unpack(T.textDim));

    function dropFrame:UpdateLabel()
        local current = getStateFn and getStateFn() or "all";
        for _, o in ipairs(TIMEFRAME_OPTIONS) do
            if (o.value == current) then
                label:SetText(L[o.key]);
                break;
            end
        end
    end

    btn:SetScript("OnEnter", function()
        dropFrame:SetBackdropBorderColor(unpack(T.accent));
    end);
    btn:SetScript("OnLeave", function()
        dropFrame:SetBackdropBorderColor(unpack(T.inputBorder));
    end);

    local menuName = baseName .. "_Menu";
    local menu = CreateFrame("Frame", menuName, UIParent, "BackdropTemplate");
    menu:SetWidth(DROPDOWN_W);
    menu:SetFrameStrata("TOOLTIP");
    menu:SetClampedToScreen(true);
    menu:EnableMouse(true);
    menu:SetPoint("TOPLEFT", dropFrame, "BOTTOMLEFT", 0, -2);
    menu:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    });
    menu:SetBackdropColor(unpack(T.dropdownBg));
    menu:SetBackdropBorderColor(unpack(T.inputBorder));
    menu:Hide();

    local overlay = CreateFrame("Button", baseName .. "_Overlay", UIParent);
    overlay:SetAllPoints(UIParent);
    overlay:SetFrameStrata("TOOLTIP");
    overlay:Hide();
    overlay:SetScript("OnClick", function()
        CloseDropdownMenu();
    end);

    menu:SetScript("OnShow", function()
        overlay:SetFrameLevel(menu:GetFrameLevel() - 1);
        overlay:Show();
    end);
    menu:SetScript("OnHide", function()
        overlay:Hide();
    end);

    local ITEM_H = 24;
    local yOff = 1;
    for _, opt in ipairs(TIMEFRAME_OPTIONS) do
        local itemName = NextName(menuName .. "_Item_");
        local item = CreateFrame("Button", itemName, menu);
        item:SetHeight(ITEM_H);
        item:SetPoint("TOPLEFT", menu, "TOPLEFT", 1, -yOff);
        item:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -1, -yOff);

        local itemBg = item:CreateTexture(itemName .. "_HL", "HIGHLIGHT");
        itemBg:SetAllPoints();
        itemBg:SetColorTexture(unpack(T.dropdownItem));

        local itemLabel = item:CreateFontString(itemName .. "_Text", "OVERLAY");
        itemLabel:SetFontObject(T.fontSmall);
        itemLabel:SetPoint("LEFT", 8, 0);
        itemLabel:SetTextColor(unpack(T.text));
        itemLabel:SetText(L[opt.key]);

        item:SetScript("OnClick", function()
            setStateFn(opt.value);
            label:SetText(L[opt.key]);
            menu:Hide();
            activeDropdownMenu = nil;
            if (onChangeCallback) then onChangeCallback(); end
        end);

        yOff = yOff + ITEM_H;
    end
    menu:SetHeight(2 + ITEM_H * #TIMEFRAME_OPTIONS);

    btn:SetScript("OnClick", function()
        if (menu:IsShown()) then
            menu:Hide();
            activeDropdownMenu = nil;
        else
            CloseDropdownMenu();
            menu:Show();
            activeDropdownMenu = menu;
        end
    end);

    return dropFrame;
end

local function PopulateDashboard()
    if (not dashScroll) then return; end
    HideAllDashElements();

    local filter = GetCharFilterForAPI();
    local stats = CraftingOrders:GetDashboardStats(filter);

    local f = dashScroll.scrollChild;

    if (stats.totalOrders == 0) then
        local empty = AcquireDashFrame(f, 40);
        empty:SetPoint("TOP", f, "TOP", 0, -50);
        empty:SetWidth(300);
        if (not empty._label) then
            empty._label = empty:CreateFontString(empty:GetName() .. "_Lbl", "OVERLAY");
            empty._label:SetFontObject(T.fontBody);
            empty._label:SetPoint("CENTER");
        end
        empty._label:SetText(L["CO_DASH_NO_DATA"]);
        empty._label:SetTextColor(unpack(T.textDim));
        empty._label:Show();
        dashScroll:SetContentHeight(120);
        return;
    end

    local y = -12;

    -- Dynamic card width for uniform 3-column grid
    local contentW = f:GetWidth();
    if (not contentW or contentW <= 0) then contentW = 600; end
    local startX = 16;
    local CARD_GAP = 8;
    local cardWidth = math.floor((contentW - 2 * CARD_GAP - 2 * startX) / 3);

    -- Row 1: All-time stats (3 cards)
    local allTimeCards = {
        { label = L["CO_DASH_TOTAL_ORDERS"], value = tostring(stats.totalOrders) },
        { label = L["CO_DASH_TOTAL_TIPS"],   value = FormatMoneyCompact(stats.totalTips), tooltip = FormatMoney(stats.totalTips) },
        { label = L["CO_DASH_AVG_TIP"],      value = FormatMoneyCompact(stats.avgTip),    tooltip = FormatMoney(stats.avgTip) },
    };

    for i, cd in ipairs(allTimeCards) do
        local card = CreateStatCard(f, y, cd.label, cd.value, cd.tooltip);
        card:SetWidth(cardWidth);
        card:SetPoint("TOPLEFT", f, "TOPLEFT", startX + (i - 1) * (cardWidth + CARD_GAP), y);
    end

    y = y - 70;

    -- Row 2: Timeframe cards (daily, weekly, monthly) with orders + tips
    local nextDailyReset, nextWeeklyReset = CraftingOrders:GetResetEpochs();
    local timeframeCards = {
        { label = L["CO_DASH_TODAY"],      orders = stats.dayOrders,   tips = stats.dayTips,   reset = nextDailyReset },
        { label = L["CO_DASH_THIS_WEEK"],  orders = stats.weekOrders,  tips = stats.weekTips,  reset = nextWeeklyReset },
        { label = L["CO_DASH_THIS_MONTH"], orders = stats.monthOrders, tips = stats.monthTips },
    };

    for i, tf in ipairs(timeframeCards) do
        local card = CreateTimeframeCard(f, y, tf.label, tf.orders, tf.tips, tf.reset);
        card:SetWidth(cardWidth);
        card:SetPoint("TOPLEFT", f, "TOPLEFT", startX + (i - 1) * (cardWidth + CARD_GAP), y);
    end

    y = y - 84;

    -- Earnings chart
    if (dashChart and dashChartHeader) then
        local bucketType, chartSince, rangeNum = GetChartParams();
        local chartData = CraftingOrders:GetEarningsChartData(filter, bucketType, chartSince);

        -- Section header
        dashChartHeader:ClearAllPoints();
        dashChartHeader:SetPoint("TOPLEFT", f, "TOPLEFT", 16, y);
        dashChartHeader:SetPoint("TOPRIGHT", f, "TOPRIGHT", -16, y);
        dashChartHeader:Show();
        y = y - 28;

        -- Subtitle
        local subtitleText;
        if (bucketType == "weekly") then
            subtitleText = string.format(L["CO_DASH_EARNINGS_WEEKLY"], rangeNum);
        else
            subtitleText = string.format(L["CO_DASH_EARNINGS_DAILY"], rangeNum);
        end
        dashChartSubtitle:ClearAllPoints();
        dashChartSubtitle:SetPoint("TOPLEFT", f, "TOPLEFT", 16, y);
        dashChartSubtitle:SetText(subtitleText);
        dashChartSubtitle:Show();
        y = y - 18;

        -- Chart widget
        local chartFactory = LanternUX._W.factories.barchart;
        if (chartFactory) then
            chartFactory.setup(dashChart, f, {
                bars = chartData.buckets,
                maxVal = chartData.maxValue,
                height = 120,
                emptyText = L["CO_DASH_EARNINGS_NO_DATA"],
                tooltipFn = function(barEntry)
                    if (not barEntry) then return nil; end
                    local goldText = FormatMoney(barEntry.value or 0);
                    return barEntry.label .. ": " .. goldText;
                end,
            });
            dashChart.frame:ClearAllPoints();
            dashChart.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 16, y);
            dashChart.frame:SetPoint("TOPRIGHT", f, "TOPRIGHT", -16, y);
            dashChart.frame:Show();
            y = y - (dashChart.height or 136) - 12;
        end
    end

    -- Timeframe filter for top 5 sections
    local since = GetDashTimeframeSince();

    if (dashTimeframeFilter) then
        dashTimeframeFilter:ClearAllPoints();
        dashTimeframeFilter:SetPoint("TOPRIGHT", f, "TOPRIGHT", -16, y);
        dashTimeframeFilter:Show();
    end
    y = y - 36;

    -- Top 5 Customers
    local customerData = CraftingOrders:GetCustomerList(filter, since);
    table.sort(customerData, function(a, b) return (a.totalTip or 0) > (b.totalTip or 0); end);

    CreateDashSectionHeader(f, y, L["CO_DASH_TOP_CUSTOMERS"]);
    y = y - 30;

    local count = math.min(5, #customerData);
    if (count == 0) then
        local empty = AcquireDashFrame(f, 20);
        empty:SetPoint("TOPLEFT", f, "TOPLEFT", 20, y);
        empty:SetWidth(200);
        if (not empty._label) then
            empty._label = empty:CreateFontString(empty:GetName() .. "_Lbl", "OVERLAY");
            empty._label:SetFontObject(T.fontBody);
            empty._label:SetPoint("LEFT");
        end
        empty._label:SetText("-");
        empty._label:SetTextColor(unpack(T.textDim));
        empty._label:Show();
        y = y - 22;
    else
        CreateDashColumnHeader(f, y, L["CO_COL_CUSTOMER"], L["CO_COL_ORDERS"], L["CO_COL_TOTAL_TIPS"]);
        y = y - 20;
        for i = 1, count do
            local c = customerData[i];
            CreateDashRankedRow(f, y, i, c.name, tostring(c.count), FormatMoneyCompact(c.totalTip));
            y = y - 22;
        end
    end

    y = y - 16;

    -- Top 5 Items
    local itemData = CraftingOrders:GetItemList(filter, since);
    table.sort(itemData, function(a, b) return (a.totalTip or 0) > (b.totalTip or 0); end);

    CreateDashSectionHeader(f, y, L["CO_DASH_TOP_ITEMS"]);
    y = y - 30;

    count = math.min(5, #itemData);
    if (count == 0) then
        local empty = AcquireDashFrame(f, 20);
        empty:SetPoint("TOPLEFT", f, "TOPLEFT", 20, y);
        empty:SetWidth(200);
        if (not empty._label) then
            empty._label = empty:CreateFontString(empty:GetName() .. "_Lbl", "OVERLAY");
            empty._label:SetFontObject(T.fontBody);
            empty._label:SetPoint("LEFT");
        end
        empty._label:SetText("-");
        empty._label:SetTextColor(unpack(T.textDim));
        empty._label:Show();
        y = y - 22;
    else
        CreateDashColumnHeader(f, y, L["CO_COL_ITEM"], L["CO_COL_CRAFTS"], L["CO_COL_TOTAL_TIPS"]);
        y = y - 20;
        for i = 1, count do
            local it = itemData[i];
            local displayName = it.itemLink or ("Item #" .. tostring(it.itemID));
            CreateDashRankedRow(f, y, i, displayName, tostring(it.count), FormatMoneyCompact(it.totalTip));
            y = y - 22;
        end
    end

    dashScroll:UpdateContentHeight(math.abs(y) + 20);
end

local function CreateDashboardContent(parent)
    local scroll = LanternUX.CreateScrollContainer(parent);
    dashScroll = scroll;

    local f = scroll.scrollChild;

    -- Earnings chart (created once, repositioned in PopulateDashboard)
    dashChartHeader = CreateFrame("Frame", "LanternCO_DashChartHeader", f);
    dashChartHeader:SetHeight(24);
    local chartHeaderLabel = dashChartHeader:CreateFontString("LanternCO_DashChartHL", "OVERLAY");
    chartHeaderLabel:SetFontObject(T.fontBodyBold);
    chartHeaderLabel:SetPoint("LEFT", dashChartHeader, "LEFT", 0, 0);
    chartHeaderLabel:SetJustifyH("LEFT");
    chartHeaderLabel:SetText(L["CO_DASH_EARNINGS_HEADER"]);
    chartHeaderLabel:SetTextColor(unpack(T.accent));
    local chartDivider = dashChartHeader:CreateTexture("LanternCO_DashChartDiv", "ARTWORK");
    chartDivider:SetHeight(1);
    chartDivider:SetPoint("BOTTOMLEFT", dashChartHeader, "BOTTOMLEFT", 0, 0);
    chartDivider:SetPoint("BOTTOMRIGHT", dashChartHeader, "BOTTOMRIGHT", 0, 0);
    chartDivider:SetColorTexture(unpack(T.divider));
    dashChartHeader:Hide();

    dashChartSubtitle = f:CreateFontString("LanternCO_DashChartSub", "OVERLAY");
    dashChartSubtitle:SetFontObject(T.fontSmall);
    dashChartSubtitle:SetTextColor(unpack(T.textDim));
    dashChartSubtitle:Hide();

    local chartFactory = LanternUX._W.factories.barchart;
    if (chartFactory) then
        dashChart = chartFactory.create(f);
        dashChart.frame:Hide();
    end

    -- Filter dropdown at top
    dashFilter = CreateCharFilterDropdown(scroll.scrollFrame, function()
        PopulateDashboard();
        SyncAllFilters();
    end);
    dashFilter:SetPoint("TOPRIGHT", scroll.scrollFrame, "TOPRIGHT", -12, -8);

    -- Timeframe filter for top 5 sections (repositioned in PopulateDashboard, hidden until then)
    dashTimeframeFilter = CreateTimeframeDropdown(scroll.scrollFrame, function()
        PopulateDashboard();
    end, function() return dashTimeframe; end, function(val) dashTimeframe = val; end);
    dashTimeframeFilter:Hide();

    -- Title
    local title = scroll.scrollFrame:CreateFontString("LanternCO_DashTitle", "OVERLAY");
    title:SetFontObject(T.fontHeading);
    title:SetPoint("TOPLEFT", scroll.scrollFrame, "TOPLEFT", 16, -12);
    title:SetText(L["CO_TAB_DASHBOARD"]);
    title:SetTextColor(unpack(T.textBright));

    -- Offset content below filter/title
    scroll.scrollFrame:ClearAllPoints();
    scroll.scrollFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -42);
    scroll.scrollFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0);

    -- Re-anchor title/filter relative to parent
    title:ClearAllPoints();
    title:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, -12);
    dashFilter:ClearAllPoints();
    dashFilter:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -12, -8);

    -- Keep scroll child width in sync
    scroll.scrollFrame:SetScript("OnSizeChanged", function(_, w)
        if (w and w > 0) then
            scroll.scrollChild:SetWidth(w);
        end
    end);

    return scroll.scrollFrame;
end

-------------------------------------------------------------------------------
-- Page 2: Customers
-------------------------------------------------------------------------------

local customersTable, customersFilter;

local function RefreshCustomers()
    if (not customersTable) then return; end
    local filter = GetCharFilterForAPI();
    local data = CraftingOrders:GetCustomerList(filter);
    customersTable:SetData(data);
    customersTable:SetNoDataText(L["CO_DASH_NO_DATA"]);
    customersTable:Refresh();
end

local function CreateCustomersContent(parent)
    local container = CreateFrame("Frame", "LanternCO_CustomersPage", parent);
    container:SetAllPoints();

    -- Filter dropdown
    customersFilter = CreateCharFilterDropdown(container, function()
        RefreshCustomers();
        SyncAllFilters();
    end);
    customersFilter:SetPoint("TOPRIGHT", container, "TOPRIGHT", -12, -8);

    -- Title
    local title = container:CreateFontString("LanternCO_CustTitle", "OVERLAY");
    title:SetFontObject(T.fontHeading);
    title:SetPoint("TOPLEFT", container, "TOPLEFT", 16, -12);
    title:SetText(L["CO_TAB_CUSTOMERS"]);
    title:SetTextColor(unpack(T.textBright));

    -- DataTable
    local tableFrame = CreateFrame("Frame", "LanternCO_CustTableWrap", container);
    tableFrame:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -42);
    tableFrame:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", 0, 0);

    customersTable = LanternUX.CreateDataTable(tableFrame, {
        columns = {
            { key = "name",       label = L["CO_COL_CUSTOMER"],   width = 160, align = "LEFT" },
            { key = "count",      label = L["CO_COL_ORDERS"],     width = 70,  align = "RIGHT" },
            { key = "totalTip",   label = L["CO_COL_TOTAL_TIPS"], width = 110, align = "RIGHT", format = function(v) return FormatMoneyCompact(v or 0); end },
            { key = "avgTip",     label = L["CO_COL_AVG_TIP"],    width = 100, align = "RIGHT", format = function(v) return FormatMoneyCompact(v or 0); end },
            { key = "uniqueItems",label = L["CO_COL_ITEM"],       width = 60,  align = "RIGHT" },
            { key = "lastOrder",  label = L["CO_COL_LAST_ORDER"], width = 90,  align = "RIGHT", format = function(v) return FormatTimeAgo(v); end },
        },
        rowHeight = 24,
        defaultSort = { key = "count", ascending = false },
        expandKey = "name",
        childColumns = {
            { key = "item",      label = L["CO_COL_ITEM"],  width = 250, isLink = true },
            { key = "tip",       label = L["CO_COL_TIP"],   width = 90,  align = "RIGHT", format = function(v) return FormatMoney(v); end },
            { key = "orderType", label = L["CO_COL_TYPE"],  width = 60 },
            { key = "timestamp", label = L["CO_COL_DATE"],  width = 88,  format = function(v) return FormatTimeAgo(v); end },
        },
        getChildren = function(entry)
            local filter = GetCharFilterForAPI();
            return CraftingOrders:GetCustomerOrders(entry.name, filter);
        end,
        childRowTooltip = function(entry, tip)
            tip:AddLine(entry.item or "", 1, 1, 1);
            if (entry.tip and entry.tip > 0) then
                tip:AddLine(L["CO_COL_TIP"] .. ": " .. FormatMoney(entry.tip), unpack(T.text));
            end
        end,
        rowTooltip = function(entry, tip)
            tip:AddLine(entry.name or "", 1, 1, 1);
            tip:AddLine(L["CO_COL_TOTAL_TIPS"] .. ": " .. FormatMoney(entry.totalTip or 0), unpack(T.text));
            tip:AddLine(L["CO_COL_AVG_TIP"] .. ": " .. FormatMoney(entry.avgTip or 0), unpack(T.text));
        end,
    });

    customersTable.frame:SetAllPoints(tableFrame);

    return container;
end

-------------------------------------------------------------------------------
-- Page 3: Items
-------------------------------------------------------------------------------

local itemsTable, itemsFilter;

local function RefreshItems()
    if (not itemsTable) then return; end
    local filter = GetCharFilterForAPI();
    local data = CraftingOrders:GetItemList(filter);
    itemsTable:SetData(data);
    itemsTable:SetNoDataText(L["CO_DASH_NO_DATA"]);
    itemsTable:Refresh();
end

local function CreateItemsContent(parent)
    local container = CreateFrame("Frame", "LanternCO_ItemsPage", parent);
    container:SetAllPoints();

    -- Filter dropdown
    itemsFilter = CreateCharFilterDropdown(container, function()
        RefreshItems();
        SyncAllFilters();
    end);
    itemsFilter:SetPoint("TOPRIGHT", container, "TOPRIGHT", -12, -8);

    -- Title
    local title = container:CreateFontString("LanternCO_ItemsTitle", "OVERLAY");
    title:SetFontObject(T.fontHeading);
    title:SetPoint("TOPLEFT", container, "TOPLEFT", 16, -12);
    title:SetText(L["CO_TAB_ITEMS"]);
    title:SetTextColor(unpack(T.textBright));

    -- DataTable
    local tableFrame = CreateFrame("Frame", "LanternCO_ItemsTableWrap", container);
    tableFrame:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -42);
    tableFrame:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", 0, 0);

    itemsTable = LanternUX.CreateDataTable(tableFrame, {
        columns = {
            { key = "itemLink",        label = L["CO_COL_ITEM"],      width = 200, align = "LEFT", isLink = true,
                format = function(v, entry)
                    return v or ("Item #" .. tostring(entry.itemID or "?"));
                end },
            { key = "count",           label = L["CO_COL_CRAFTS"],    width = 70,  align = "RIGHT" },
            { key = "avgTip",          label = L["CO_COL_AVG_TIP"],   width = 100, align = "RIGHT", format = function(v) return FormatMoneyCompact(v or 0); end },
            { key = "totalTip",        label = L["CO_COL_REVENUE"],   width = 110, align = "RIGHT", format = function(v) return FormatMoneyCompact(v or 0); end },
            { key = "uniqueCustomers", label = L["CO_COL_CUSTOMERS"], width = 80,  align = "RIGHT" },
        },
        rowHeight = 24,
        defaultSort = { key = "count", ascending = false },
        rowTooltip = function(entry, tip)
            local name = entry.itemLink or ("Item #" .. tostring(entry.itemID or "?"));
            tip:AddLine(name, 1, 1, 1);
            tip:AddLine(L["CO_COL_AVG_TIP"] .. ": " .. FormatMoney(entry.avgTip or 0), unpack(T.text));
            tip:AddLine(L["CO_COL_REVENUE"] .. ": " .. FormatMoney(entry.totalTip or 0), unpack(T.text));
        end,
    });

    itemsTable.frame:SetAllPoints(tableFrame);

    return container;
end

-------------------------------------------------------------------------------
-- Page 4: Orders (individual order list with remove)
-------------------------------------------------------------------------------

local ordersFilter, ordersTable;

local RefreshOrders; -- forward declaration

RefreshOrders = function()
    if (not ordersTable) then return; end
    local filter = GetCharFilterForAPI();
    local data = CraftingOrders:GetOrderList(filter);
    local db = _G.LanternCraftingOrdersDB or {};
    ordersTable:SetPageSize(db.ordersPerPage or 50);
    ordersTable:SetData(data);
    ordersTable:Refresh();
end

local function CreateOrdersContent(parent)
    local container = CreateFrame("Frame", "LanternCO_OrdersPage", parent);
    container:SetAllPoints();

    -- Filter dropdown
    ordersFilter = CreateCharFilterDropdown(container, function()
        RefreshOrders();
        SyncAllFilters();
    end);
    ordersFilter:SetPoint("TOPRIGHT", container, "TOPRIGHT", -12, -8);

    -- Title
    local title = container:CreateFontString("LanternCO_OrdersTitle", "OVERLAY");
    title:SetFontObject(T.fontHeading);
    title:SetPoint("TOPLEFT", container, "TOPLEFT", 16, -12);
    title:SetText(L["CO_TAB_ORDERS"]);
    title:SetTextColor(unpack(T.textBright));

    -- DataTable
    local db = _G.LanternCraftingOrdersDB or {};
    local tableFrame = CreateFrame("Frame", "LanternCO_OrdersTableFrame", container);
    tableFrame:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -42);
    tableFrame:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", 0, 0);

    ordersTable = LanternUX.CreateDataTable(tableFrame, {
        columns = {
            { key = "timestamp", label = L["CO_COL_DATE"],     width = 88,  format = function(v) return FormatTimeAgo(v); end },
            { key = "customer",  label = L["CO_COL_CUSTOMER"], width = 128 },
            { key = "item",      label = L["CO_COL_ITEM"],     width = 250, isLink = true },
            { key = "tip",       label = L["CO_COL_TIP"],      width = 90,  align = "RIGHT", format = function(v) return FormatMoney(v); end },
            { key = "orderType", label = L["CO_COL_TYPE"],     width = 60 },
        },
        defaultSort = { key = "timestamp", ascending = false },
        pageSize = db.ordersPerPage or 50,
        onRowClick = function(entry)
            if (not IsShiftKeyDown()) then return; end
            CraftingOrders:RemoveOrder(entry.charKey, entry.index);
            RefreshOrders();
            PopulateDashboard();
            if (customersTable) then RefreshCustomers(); end
            if (itemsTable) then RefreshItems(); end
        end,
        rowTooltip = function(entry, tooltip)
            tooltip:AddLine(entry.item or "", 1, 1, 1);
            tooltip:AddLine(L["CO_ORDERS_SHIFT_CLICK_REMOVE"], 0.7, 0.7, 0.7);
        end,
    });
    ordersTable.frame:SetAllPoints(tableFrame);
    ordersTable:SetNoDataText(L["CO_DASH_NO_DATA"]);

    return container;
end

-------------------------------------------------------------------------------
-- Page 6: Heat Maps
-------------------------------------------------------------------------------

local heatmapScroll, heatmapFilter, heatmapTimeframeFilter;
local heatmapTimeframe = "all";
local heatmapOrdersGrid, heatmapGoldGrid, heatmapTradeGrid;

local function FormatDayHour(day, hour)
    local use12h = not GetCVarBool("timeMgrUseMilitaryTime");
    local dayName = date("%A", 345600 + day * 86400);
    local hourStr;
    if (use12h) then
        if (hour == 0) then hourStr = "12:00 AM";
        elseif (hour < 12) then hourStr = hour .. ":00 AM";
        elseif (hour == 12) then hourStr = "12:00 PM";
        else hourStr = (hour - 12) .. ":00 PM"; end
    else
        hourStr = string.format("%02d:00", hour);
    end
    return dayName .. " " .. hourStr;
end

local function HeatMapOrderTooltip(day, hour, value)
    local prefix = FormatDayHour(day, hour);
    if (value == 0) then
        return prefix .. " -- " .. L["CO_HEATMAP_TIP_NO_ACTIVITY"];
    elseif (value == 1) then
        return prefix .. " -- " .. L["CO_HEATMAP_TIP_ORDERS_SINGLE"];
    end
    return prefix .. " -- " .. string.format(L["CO_HEATMAP_TIP_ORDERS"], value);
end

local function HeatMapGoldTooltip(day, hour, value)
    local prefix = FormatDayHour(day, hour);
    if (value == 0) then
        return prefix .. " -- " .. L["CO_HEATMAP_TIP_NO_ACTIVITY"];
    end
    return prefix .. " -- " .. string.format(L["CO_HEATMAP_TIP_GOLD"], FormatMoney(value));
end

local function HeatMapTradeTooltip(profData)
    return function(day, hour, value)
        local prefix = FormatDayHour(day, hour);
        if (value == 0) then
            return prefix .. " -- " .. L["CO_HEATMAP_TIP_NO_ACTIVITY"];
        end
        local base;
        if (value == 1) then
            base = prefix .. " -- " .. L["CO_HEATMAP_TIP_TRADE_SINGLE"];
        else
            base = prefix .. " -- " .. string.format(L["CO_HEATMAP_TIP_TRADE"], value);
        end
        local profs = profData and profData[day] and profData[day][hour];
        if (profs) then
            local parts = {};
            for prof, count in pairs(profs) do
                table.insert(parts, prof .. ": " .. count);
            end
            if (#parts > 0) then
                table.sort(parts);
                base = base .. "\n(" .. table.concat(parts, ", ") .. ")";
            end
        end
        return base;
    end;
end

local function GetHeatmapTimeframeSince()
    if (heatmapTimeframe == "all") then return nil; end
    local now = time();
    if (heatmapTimeframe == "day") then return now - (24 * 3600); end
    if (heatmapTimeframe == "week") then return now - (7 * 24 * 3600); end
    if (heatmapTimeframe == "month") then return now - (30 * 24 * 3600); end
    return nil;
end

local function PopulateHeatMaps()
    if (not heatmapScroll) then return; end

    local filter = GetCharFilterForAPI();
    local since = GetHeatmapTimeframeSince();
    local f = heatmapScroll.scrollChild;

    -- Order & Gold data
    local hmData = CraftingOrders:GetHeatMapData(filter, since);

    -- Update or create order grid
    if (heatmapOrdersGrid) then
        local setupFn = LanternUX._W.factories.heatmap.setup;
        setupFn(heatmapOrdersGrid, f, {
            data = hmData.orders,
            maxVal = hmData.maxOrders,
            tooltipFn = HeatMapOrderTooltip,
        }, nil);
    end

    -- Update or create gold grid
    if (heatmapGoldGrid) then
        local setupFn = LanternUX._W.factories.heatmap.setup;
        setupFn(heatmapGoldGrid, f, {
            data = hmData.gold,
            maxVal = hmData.maxGold,
            tooltipFn = HeatMapGoldTooltip,
            formatFn = function(v) return v > 0 and FormatMoneyCompact(v) or ""; end,
        }, nil);
    end

    -- Trade chat grid
    if (CraftingOrders:IsTradeChatEnabled()) then
        local tradeData = CraftingOrders:GetTradeChatHeatMapData(since);
        if (heatmapTradeGrid) then
            heatmapTradeGrid.frame:Show();
            local setupFn = LanternUX._W.factories.heatmap.setup;
            setupFn(heatmapTradeGrid, f, {
                data = tradeData.grid,
                maxVal = tradeData.maxTotal,
                tooltipFn = HeatMapTradeTooltip(tradeData.professions),
            }, nil);
        end
        if (heatmapScroll._disabledMsg) then heatmapScroll._disabledMsg:Hide(); end
        if (heatmapScroll._enableBtn) then heatmapScroll._enableBtn:Hide(); end
    else
        if (heatmapTradeGrid) then heatmapTradeGrid.frame:Hide(); end
        if (heatmapScroll._disabledMsg) then heatmapScroll._disabledMsg:Show(); end
        if (heatmapScroll._enableBtn) then heatmapScroll._enableBtn:Show(); end
    end
end

local function CreateHeatMapsContent(parent)
    local scroll = LanternUX.CreateScrollContainer(parent);
    heatmapScroll = scroll;

    local f = scroll.scrollChild;

    -- Char filter dropdown
    heatmapFilter = CreateCharFilterDropdown(scroll.scrollFrame, function()
        PopulateHeatMaps();
        SyncAllFilters();
    end);
    heatmapFilter:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -12, -8);

    -- Title
    local title = scroll.scrollFrame:CreateFontString("LanternCO_HMTitle", "OVERLAY");
    title:SetFontObject(T.fontHeading);
    title:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, -12);
    title:SetText(L["CO_TAB_HEATMAPS"]);
    title:SetTextColor(unpack(T.textBright));

    -- Timeframe dropdown
    heatmapTimeframeFilter = CreateTimeframeDropdown(parent, function()
        PopulateHeatMaps();
    end, function() return heatmapTimeframe; end, function(val) heatmapTimeframe = val; end);
    heatmapTimeframeFilter:SetPoint("TOPRIGHT", heatmapFilter, "TOPLEFT", -8, 0);

    -- Offset scroll content below title/filters
    scroll.scrollFrame:ClearAllPoints();
    scroll.scrollFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -42);
    scroll.scrollFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0);

    scroll.scrollFrame:SetScript("OnSizeChanged", function(_, w)
        if (w and w > 0) then f:SetWidth(w); end
    end);

    local y = -12;
    local LUX = _G.LanternUX;

    -- Section 1: Orders heat map
    local ordersHeader = f:CreateFontString("LanternCO_HM_OrdersH", "OVERLAY");
    ordersHeader:SetFontObject(T.fontBodyBold);
    ordersHeader:SetPoint("TOPLEFT", f, "TOPLEFT", 16, y);
    ordersHeader:SetText(L["CO_HEATMAP_ORDERS"]);
    ordersHeader:SetTextColor(unpack(T.accent));
    y = y - 24;

    heatmapOrdersGrid = LUX.CreateStandaloneWidget("heatmap", f, {
        data = {},
        tooltipFn = HeatMapOrderTooltip,
    });
    heatmapOrdersGrid.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 16, y);
    heatmapOrdersGrid.frame:SetPoint("RIGHT", f, "RIGHT", -16, 0);
    y = y - (heatmapOrdersGrid.height or 428) - 24;

    -- Section 2: Gold heat map
    local goldHeader = f:CreateFontString("LanternCO_HM_GoldH", "OVERLAY");
    goldHeader:SetFontObject(T.fontBodyBold);
    goldHeader:SetPoint("TOPLEFT", f, "TOPLEFT", 16, y);
    goldHeader:SetText(L["CO_HEATMAP_GOLD"]);
    goldHeader:SetTextColor(unpack(T.accent));
    y = y - 24;

    heatmapGoldGrid = LUX.CreateStandaloneWidget("heatmap", f, {
        data = {},
        tooltipFn = HeatMapGoldTooltip,
        formatFn = function(v) return v > 0 and FormatMoneyCompact(v) or ""; end,
    });
    heatmapGoldGrid.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 16, y);
    heatmapGoldGrid.frame:SetPoint("RIGHT", f, "RIGHT", -16, 0);
    y = y - (heatmapGoldGrid.height or 428) - 24;

    -- Section 3: Trade Chat heat map
    local tradeHeader = f:CreateFontString("LanternCO_HM_TradeH", "OVERLAY");
    tradeHeader:SetFontObject(T.fontBodyBold);
    tradeHeader:SetPoint("TOPLEFT", f, "TOPLEFT", 16, y);
    tradeHeader:SetText(L["CO_HEATMAP_TRADE_CHAT"]);
    tradeHeader:SetTextColor(unpack(T.accent));
    y = y - 24;

    -- Trade chat disabled message
    local disabledMsg = f:CreateFontString("LanternCO_HM_TradeDisabled", "OVERLAY");
    disabledMsg:SetFontObject(T.fontBody);
    disabledMsg:SetPoint("TOPLEFT", f, "TOPLEFT", 16, y);
    disabledMsg:SetText(L["CO_HEATMAP_TRADE_DISABLED"]);
    disabledMsg:SetTextColor(unpack(T.textDim));
    disabledMsg:Hide();
    scroll._disabledMsg = disabledMsg;

    -- "Enable in Settings" button
    local enableBtn = CreateFrame("Button", "LanternCO_HM_EnableBtn", f);
    enableBtn:SetPoint("TOPLEFT", disabledMsg, "BOTTOMLEFT", 0, -4);
    enableBtn:SetSize(150, 24);
    local enableText = enableBtn:CreateFontString("LanternCO_HM_EnableBtnText", "OVERLAY");
    enableText:SetFontObject(T.fontBody);
    enableText:SetAllPoints();
    enableText:SetJustifyH("LEFT");
    enableText:SetText(L["CO_HEATMAP_TRADE_ENABLE_LINK"]);
    enableText:SetTextColor(unpack(T.accent));
    enableBtn:SetScript("OnClick", function()
        if (panel) then
            panel:SelectPage("settings");
        end
    end);
    enableBtn:SetScript("OnEnter", function()
        enableText:SetTextColor(unpack(T.textBright));
    end);
    enableBtn:SetScript("OnLeave", function()
        enableText:SetTextColor(unpack(T.accent));
    end);
    enableBtn:Hide();
    scroll._enableBtn = enableBtn;

    -- Trade chat grid
    heatmapTradeGrid = LUX.CreateStandaloneWidget("heatmap", f, {
        data = {},
        tooltipFn = HeatMapTradeTooltip({}),
    });
    heatmapTradeGrid.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 16, y);
    heatmapTradeGrid.frame:SetPoint("RIGHT", f, "RIGHT", -16, 0);
    y = y - (heatmapTradeGrid.height or 428) - 20;

    scroll:SetContentHeight(math.abs(y) + 20);

    return scroll.scrollFrame;
end

-------------------------------------------------------------------------------
-- Page 5: Settings (widget renderer)
-------------------------------------------------------------------------------

local function GetSettingsWidgets()
    local refreshPage = function()
        if (panel) then panel:RefreshCurrentPage(); end
    end;

    local LL = Lantern.L;
    local widgets = {};

    -- Order Types group
    table.insert(widgets, {
        type = "group",
        text = L["CO_SETTINGS_ORDER_TYPES"],
        desc = L["CO_SETTINGS_ORDER_TYPES_DESC"],
        expanded = true,
        stateKey = "orderTypes",
        children = {
            {
                type = "toggle",
                label = L["CO_SETTINGS_TRACK_GUILD"],
                get = function() return CraftingOrders:IsOrderTypeTracked("guild"); end,
                set = function(val)
                    CraftingOrders:SetTrackOrderType("guild", val);
                end,
            },
            {
                type = "toggle",
                label = L["CO_SETTINGS_TRACK_PERSONAL"],
                get = function() return CraftingOrders:IsOrderTypeTracked("personal"); end,
                set = function(val)
                    CraftingOrders:SetTrackOrderType("personal", val);
                end,
            },
        },
    });

    -- Reset Timers group
    local resetSettings = CraftingOrders:GetResetTimerSettings();
    local showResetTimers = CraftingOrders:GetShowResetTimers();
    local resetChildren = {
        {
            type = "toggle",
            label = L["CO_SETTINGS_SHOW_RESET_TIMERS"],
            get = function() return CraftingOrders:GetShowResetTimers(); end,
            set = function(val)
                CraftingOrders:SetShowResetTimers(val);
                refreshPage();
            end,
        },
    };

    if (showResetTimers) then
        table.insert(resetChildren, {
            type = "select",
            label = L["CO_SETTINGS_RESET_MODE"],
            get = function() return resetSettings.mode or "auto"; end,
            set = function(val)
                CraftingOrders:SetResetTimerSetting("mode", val);
                refreshPage();
            end,
            values = {
                auto = L["CO_SETTINGS_RESET_AUTO"],
                custom = L["CO_SETTINGS_RESET_CUSTOM"],
            },
            sorting = { "auto", "custom" },
        });

        if (resetSettings.mode == "custom") then
            local use12h = not GetCVarBool("timeMgrUseMilitaryTime");
            local hourValues = {};
            local hourSorting = {};
            for h = 0, 23 do
                local lbl;
                if (use12h) then
                    if (h == 0) then lbl = "12:00 AM";
                    elseif (h < 12) then lbl = h .. ":00 AM";
                    elseif (h == 12) then lbl = "12:00 PM";
                    else lbl = (h - 12) .. ":00 PM"; end
                else
                    lbl = string.format("%02d:00", h);
                end
                hourValues[h] = lbl;
                table.insert(hourSorting, h);
            end

            local dayKeys = { "DAY_SUN", "DAY_MON", "DAY_TUE", "DAY_WED", "DAY_THU", "DAY_FRI", "DAY_SAT" };
            local dayValues = {};
            local daySorting = {};
            for i, key in ipairs(dayKeys) do
                local dayIdx = i - 1;
                dayValues[dayIdx] = LL[key] or key;
                table.insert(daySorting, dayIdx);
            end

            table.insert(resetChildren, {
                type = "select",
                label = L["CO_SETTINGS_DAILY_RESET_HOUR"],
                get = function() return resetSettings.dailyHour or 7; end,
                set = function(val) CraftingOrders:SetResetTimerSetting("dailyHour", val); end,
                values = hourValues,
                sorting = hourSorting,
            });
            table.insert(resetChildren, {
                type = "select",
                label = L["CO_SETTINGS_WEEKLY_RESET_DAY"],
                get = function() return resetSettings.weeklyDay or 2; end,
                set = function(val) CraftingOrders:SetResetTimerSetting("weeklyDay", val); end,
                values = dayValues,
                sorting = daySorting,
            });
            table.insert(resetChildren, {
                type = "select",
                label = L["CO_SETTINGS_WEEKLY_RESET_HOUR"],
                get = function() return resetSettings.weeklyHour or 7; end,
                set = function(val) CraftingOrders:SetResetTimerSetting("weeklyHour", val); end,
                values = hourValues,
                sorting = hourSorting,
            });
        end
    end

    table.insert(widgets, {
        type = "group",
        text = L["CO_SETTINGS_RESET_TIMERS"],
        desc = L["CO_SETTINGS_RESET_TIMERS_DESC"],
        stateKey = "resetTimers",
        children = resetChildren,
    });

    -- Trade Chat Tracking group
    local tradeChildren = {
        {
            type = "toggle",
            label = L["CO_SETTINGS_TRADE_CHAT_ENABLE"],
            desc = L["CO_SETTINGS_TRADE_CHAT_ENABLE_DESC"],
            get = function() return CraftingOrders:IsTradeChatEnabled(); end,
            set = function(val)
                CraftingOrders:SetTradeChatEnabled(val);
                refreshPage();
            end,
        },
    };

    if (CraftingOrders:IsTradeChatEnabled()) then
        table.insert(tradeChildren, {
            type = "select",
            label = L["CO_SETTINGS_TRADE_CHAT_RETENTION"],
            desc = L["CO_SETTINGS_TRADE_CHAT_RETENTION_DESC"],
            get = function() return CraftingOrders:GetTradeChatRetention(); end,
            set = function(val) CraftingOrders:SetTradeChatRetention(val); end,
            values = {
                [30] = L["CO_SETTINGS_TRADE_CHAT_30"],
                [60] = L["CO_SETTINGS_TRADE_CHAT_60"],
                [90] = L["CO_SETTINGS_TRADE_CHAT_90"],
            },
            sorting = { 30, 60, 90 },
        });

        table.insert(tradeChildren, {
            type = "header",
            text = L["CO_SETTINGS_INCLUDE_KEYWORDS"],
            desc = L["CO_SETTINGS_INCLUDE_KEYWORDS_DESC"],
        });
        local keywords = CraftingOrders:GetTradeChatKeywords();
        for _, kw in ipairs(keywords.include) do
            table.insert(tradeChildren, {
                type = "label_action",
                text = kw,
                buttonLabel = L["CO_SETTINGS_KEYWORD_REMOVE"],
                func = function()
                    CraftingOrders:RemoveTradeChatKeyword("include", kw);
                    refreshPage();
                end,
            });
        end
        table.insert(tradeChildren, {
            type = "input",
            label = L["CO_SETTINGS_KEYWORD_ADD"],
            get = function() return ""; end,
            set = function(val)
                if (CraftingOrders:AddTradeChatKeyword("include", val)) then
                    refreshPage();
                end
            end,
        });

        table.insert(tradeChildren, {
            type = "header",
            text = L["CO_SETTINGS_EXCLUDE_KEYWORDS"],
            desc = L["CO_SETTINGS_EXCLUDE_KEYWORDS_DESC"],
        });
        for _, kw in ipairs(keywords.exclude) do
            table.insert(tradeChildren, {
                type = "label_action",
                text = kw,
                buttonLabel = L["CO_SETTINGS_KEYWORD_REMOVE"],
                func = function()
                    CraftingOrders:RemoveTradeChatKeyword("exclude", kw);
                    refreshPage();
                end,
            });
        end
        table.insert(tradeChildren, {
            type = "input",
            label = L["CO_SETTINGS_KEYWORD_ADD"],
            get = function() return ""; end,
            set = function(val)
                if (CraftingOrders:AddTradeChatKeyword("exclude", val)) then
                    refreshPage();
                end
            end,
        });
    end

    table.insert(widgets, {
        type = "group",
        text = L["CO_SETTINGS_TRADE_CHAT"],
        desc = L["CO_SETTINGS_TRADE_CHAT_DESC"],
        stateKey = "tradeChat",
        children = tradeChildren,
    });

    -- Excluded Customers group
    local customerChildren = {};
    local excluded = CraftingOrders:GetExcludedCustomers();
    local sortedNames = {};
    for name in pairs(excluded) do
        table.insert(sortedNames, name);
    end
    table.sort(sortedNames);

    if (#sortedNames == 0) then
        table.insert(customerChildren, {
            type = "label",
            text = L["CO_SETTINGS_EXCLUDED_EMPTY"],
        });
    else
        for _, name in ipairs(sortedNames) do
            table.insert(customerChildren, {
                type = "label_action",
                text = name,
                buttonLabel = L["CO_SETTINGS_REMOVE"],
                func = function()
                    CraftingOrders:RemoveExcludedCustomer(name);
                    refreshPage();
                end,
            });
        end
    end
    table.insert(customerChildren, {
        type = "input",
        label = L["CO_SETTINGS_ADD"],
        get = function() return ""; end,
        set = function(val)
            if (CraftingOrders:AddExcludedCustomer(val)) then
                refreshPage();
            end
        end,
    });

    table.insert(widgets, {
        type = "group",
        text = L["CO_SETTINGS_EXCLUDED_CUSTOMERS"],
        desc = L["CO_SETTINGS_EXCLUDED_DESC"],
        stateKey = "excludedCustomers",
        children = customerChildren,
    });

    -- Order History group
    table.insert(widgets, {
        type = "group",
        text = L["CO_HISTORY_HEADER"],
        desc = L["CO_CLEAR_HISTORY_DESC"],
        stateKey = "orderHistory",
        children = {
            {
                type = "toggle",
                label = L["CO_TRACK_HISTORY"],
                desc = L["CO_TRACK_HISTORY_DESC"],
                get = function()
                    local db = CraftingOrders:GetHistoryDB();
                    return db.trackHistory;
                end,
                set = function(val)
                    local db = CraftingOrders:GetHistoryDB();
                    db.trackHistory = val;
                end,
            },
            {
                type = "select",
                label = L["CO_MAX_ORDERS"],
                desc = L["CO_MAX_ORDERS_DESC"],
                get = function()
                    local db = CraftingOrders:GetHistoryDB();
                    return db.maxOrders;
                end,
                set = function(val)
                    local db = CraftingOrders:GetHistoryDB();
                    db.maxOrders = val;
                end,
                values = {
                    [500] = "500",
                    [1000] = "1,000",
                    [2000] = "2,000",
                    [5000] = "5,000",
                    [10000] = "10,000",
                },
                sorting = { 500, 1000, 2000, 5000, 10000 },
            },
            {
                type = "label_action",
                text = string.format(L["CO_HISTORY_COUNT"], CraftingOrders:GetCharacterOrderCount()),
                buttonLabel = L["CO_CLEAR_HISTORY"],
                func = function()
                    StaticPopup_Show("LANTERN_CO_CLEAR_HISTORY");
                end,
            },
        },
    });

    return widgets;
end

-------------------------------------------------------------------------------
-- Filter sync helper
-------------------------------------------------------------------------------

SyncAllFilters = function()
    if (dashFilter) then dashFilter:UpdateLabel(); end
    if (customersFilter) then customersFilter:UpdateLabel(); end
    if (itemsFilter) then itemsFilter:UpdateLabel(); end
    if (ordersFilter) then ordersFilter:UpdateLabel(); end
    if (heatmapFilter) then heatmapFilter:UpdateLabel(); end
end

-------------------------------------------------------------------------------
-- Panel creation
-------------------------------------------------------------------------------

local function EnsurePanel()
    if (panel) then return panel; end

    panel = LanternUX:CreatePanel({
        name   = "LanternCO_Analytics",
        title  = L["CO_ANALYTICS_TITLE"],
        width  = 960,
        height = 500,
    });

    panel:AddPage("dashboard", {
        label  = L["CO_TAB_DASHBOARD"],
        frame  = CreateDashboardContent,
        onShow = function()
            activePage = "dashboard";
            CloseDropdownMenu();
            if (dashFilter) then dashFilter:UpdateLabel(); end
            PopulateDashboard();
        end,
    });

    panel:AddPage("customers", {
        label  = L["CO_TAB_CUSTOMERS"],
        frame  = CreateCustomersContent,
        onShow = function()
            activePage = "customers";
            CloseDropdownMenu();
            if (customersFilter) then customersFilter:UpdateLabel(); end
            RefreshCustomers();
        end,
    });

    panel:AddPage("items", {
        label  = L["CO_TAB_ITEMS"],
        frame  = CreateItemsContent,
        onShow = function()
            activePage = "items";
            CloseDropdownMenu();
            if (itemsFilter) then itemsFilter:UpdateLabel(); end
            RefreshItems();
        end,
    });

    panel:AddPage("orders", {
        label  = L["CO_TAB_ORDERS"],
        frame  = CreateOrdersContent,
        onShow = function()
            activePage = "orders";
            CloseDropdownMenu();
            if (ordersFilter) then ordersFilter:UpdateLabel(); end
            RefreshOrders();
        end,
    });

    panel:AddPage("heatmaps", {
        label  = L["CO_TAB_HEATMAPS"],
        frame  = CreateHeatMapsContent,
        onShow = function()
            activePage = "heatmaps";
            CloseDropdownMenu();
            if (heatmapFilter) then heatmapFilter:UpdateLabel(); end
            if (heatmapTimeframeFilter) then heatmapTimeframeFilter:UpdateLabel(); end
            PopulateHeatMaps();
        end,
    });

    panel:AddPage("settings", {
        label  = L["CO_TAB_SETTINGS"],
        widgets = GetSettingsWidgets,
        onShow = function()
            activePage = "settings";
            CloseDropdownMenu();
        end,
    });

    -- Expose so settings panel can close us
    CraftingOrders._analyticsPanel = panel;

    return panel;
end

-------------------------------------------------------------------------------
-- Close analytics when the settings panel opens
-------------------------------------------------------------------------------

hooksecurefunc(Lantern, "OpenOptions", function()
    if (panel) then
        CloseDropdownMenu();
        panel:Hide();
    end
end);

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------

function CraftingOrders:RefreshAnalytics()
    if (not panel) then return; end
    local f = panel:GetFrame();
    if (not f or not f:IsShown()) then return; end

    -- Refresh whichever page is active
    if (activePage == "dashboard") then
        PopulateDashboard();
    elseif (activePage == "customers") then
        RefreshCustomers();
    elseif (activePage == "items") then
        RefreshItems();
    elseif (activePage == "orders") then
        RefreshOrders();
    elseif (activePage == "heatmaps") then
        PopulateHeatMaps();
    elseif (activePage == "settings") then
        if (panel) then panel:RefreshCurrentPage(); end
    end
end

local function HideSettingsPanel()
    local settingsPanel = Lantern._uxPanel;
    if (settingsPanel and settingsPanel.Hide) then
        settingsPanel:Hide();
    end
end

function CraftingOrders:OpenAnalytics()
    CloseDropdownMenu();
    HideSettingsPanel();
    local p = EnsurePanel();
    p:Show();
end

function CraftingOrders:ToggleAnalytics()
    local p = EnsurePanel();
    CloseDropdownMenu();
    if (p:GetFrame() and p:GetFrame():IsShown()) then
        p:Hide();
    else
        HideSettingsPanel();
        p:Show();
    end
end
