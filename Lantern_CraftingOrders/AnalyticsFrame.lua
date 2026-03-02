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
        return string.format("%dg %ds", gold, silver);
    end
    return string.format("%ds", silver);
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

    -- Invisible backdrop to catch outside clicks and close the menu
    local backdrop = CreateFrame("Button", baseName .. "_Backdrop", UIParent);
    backdrop:SetAllPoints(UIParent);
    backdrop:SetFrameStrata("TOOLTIP");
    backdrop:SetFrameLevel(0);
    backdrop:Hide();
    backdrop:SetScript("OnClick", function()
        CloseDropdownMenu();
        backdrop:Hide();
    end);

    -- Menu popup
    local menuName = baseName .. "_Menu";
    local menu = CreateFrame("Frame", menuName, dropFrame, "BackdropTemplate");
    menu:SetWidth(DROPDOWN_W);
    menu:SetFrameStrata("TOOLTIP");
    menu:SetFrameLevel(1);
    menu:SetPoint("TOPLEFT", dropFrame, "BOTTOMLEFT", 0, -2);
    menu:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    });
    menu:SetBackdropColor(unpack(T.dropdownBg));
    menu:SetBackdropBorderColor(unpack(T.inputBorder));
    menu:Hide();

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
            backdrop:Hide();
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
            backdrop:Hide();
            activeDropdownMenu = nil;
        else
            CloseDropdownMenu();
            menu:Show();
            backdrop:Show();
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

local dashScroll, dashFilter;
local dashElements = {};
local dashElementCount = 0;

local function HideAllDashElements()
    for i = 1, dashElementCount do
        if (dashElements[i]) then dashElements[i]:Hide(); end
    end
    dashElementCount = 0;
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
    elem:Show();
    return elem;
end

local function CreateStatCard(parent, yOffset, labelText, valueText)
    local CARD_W = 140;
    local CARD_H = 56;

    local card = AcquireDashFrame(parent, CARD_H);
    card:SetWidth(CARD_W);

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
        card._value:SetFontObject(T.fontHeading);
        card._value:SetPoint("TOP", card, "TOP", 0, -10);
    end
    card._value:SetText(valueText);
    card._value:SetTextColor(unpack(T.textBright));
    card._value:Show();

    -- Label text (small)
    if (not card._label) then
        card._label = card:CreateFontString(card:GetName() .. "_Lbl", "OVERLAY");
        card._label:SetFontObject(T.fontSmall);
        card._label:SetPoint("BOTTOM", card, "BOTTOM", 0, 8);
    end
    card._label:SetText(labelText);
    card._label:SetTextColor(unpack(T.textDim));
    card._label:Show();

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
    if (header._valueLabel) then header._valueLabel:Hide(); end

    return header;
end

local function CreateDashRankedRow(parent, yOffset, rank, name, valueText)
    local row = AcquireDashFrame(parent, 20);
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset);
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -20, yOffset);

    if (not row._rankLabel) then
        row._rankLabel = row:CreateFontString(row:GetName() .. "_Rank", "OVERLAY");
        row._rankLabel:SetFontObject(T.fontBody);
        row._rankLabel:SetPoint("LEFT", row, "LEFT", 0, 0);
        row._rankLabel:SetWidth(20);
        row._rankLabel:SetJustifyH("LEFT");
    end
    row._rankLabel:SetText(rank .. ".");
    row._rankLabel:SetTextColor(unpack(T.textDim));
    row._rankLabel:Show();

    if (not row._nameLabel) then
        row._nameLabel = row:CreateFontString(row:GetName() .. "_Name", "OVERLAY");
        row._nameLabel:SetFontObject(T.fontBody);
        row._nameLabel:SetPoint("LEFT", row._rankLabel, "RIGHT", 4, 0);
        row._nameLabel:SetPoint("RIGHT", row, "RIGHT", -100, 0);
        row._nameLabel:SetJustifyH("LEFT");
        row._nameLabel:SetWordWrap(false);
    end
    row._nameLabel:SetText(name);
    row._nameLabel:SetTextColor(unpack(T.text));
    row._nameLabel:Show();

    if (not row._valueLabel) then
        row._valueLabel = row:CreateFontString(row:GetName() .. "_Val", "OVERLAY");
        row._valueLabel:SetFontObject(T.fontBody);
        row._valueLabel:SetPoint("RIGHT", row, "RIGHT", 0, 0);
        row._valueLabel:SetWidth(90);
        row._valueLabel:SetJustifyH("RIGHT");
    end
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

    -- Stats cards (row of 5)
    local CARD_W = 140;
    local CARD_GAP = 8;
    local cardsData = {
        { label = L["CO_DASH_TOTAL_ORDERS"], value = tostring(stats.totalOrders) },
        { label = L["CO_DASH_TOTAL_TIPS"],   value = FormatMoney(stats.totalTips) },
        { label = L["CO_DASH_AVG_TIP"],      value = FormatMoney(stats.avgTip) },
        { label = L["CO_DASH_THIS_WEEK"],    value = tostring(stats.weekOrders) },
        { label = L["CO_DASH_THIS_MONTH"],   value = tostring(stats.monthOrders) },
    end

    local startX = 16;

    for i, cd in ipairs(cardsData) do
        local card = CreateStatCard(f, y, cd.label, cd.value);
        card:SetPoint("TOPLEFT", f, "TOPLEFT", startX + (i - 1) * (CARD_W + CARD_GAP), y);
    end

    y = y - 70;

    -- Top 5 Customers
    local customerData = CraftingOrders:GetCustomerList(filter);
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
        for i = 1, count do
            local c = customerData[i];
            CreateDashRankedRow(f, y, i, c.name, FormatMoney(c.totalTip));
            y = y - 22;
        end
    end

    y = y - 16;

    -- Top 5 Items
    local itemData = CraftingOrders:GetItemList(filter);
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
        for i = 1, count do
            local it = itemData[i];
            local displayName = it.itemLink or ("Item #" .. tostring(it.itemID));
            CreateDashRankedRow(f, y, i, displayName, FormatMoney(it.totalTip));
            y = y - 22;
        end
    end

    dashScroll:SetContentHeight(math.abs(y) + 20);
end

local function CreateDashboardContent(parent)
    local scroll = LanternUX.CreateScrollContainer(parent);
    dashScroll = scroll;

    local f = scroll.scrollChild;

    -- Filter dropdown at top
    dashFilter = CreateCharFilterDropdown(scroll.scrollFrame, function()
        -- Also update the other filters
        PopulateDashboard();
        -- Sync other page filters when they exist
        SyncAllFilters();
    end);
    dashFilter:SetPoint("TOPRIGHT", scroll.scrollFrame, "TOPRIGHT", -12, -8);

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
            { key = "totalTip",   label = L["CO_COL_TOTAL_TIPS"], width = 110, align = "RIGHT", format = function(v) return FormatMoney(v or 0); end },
            { key = "avgTip",     label = L["CO_COL_AVG_TIP"],    width = 100, align = "RIGHT", format = function(v) return FormatMoney(v or 0); end },
            { key = "uniqueItems",label = L["CO_COL_ITEM"],       width = 60,  align = "RIGHT" },
            { key = "lastOrder",  label = L["CO_COL_LAST_ORDER"], width = 90,  align = "RIGHT", format = function(v) return FormatTimeAgo(v); end },
        },
        rowHeight = 24,
        defaultSort = { key = "count", ascending = false },
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
            { key = "avgTip",          label = L["CO_COL_AVG_TIP"],   width = 100, align = "RIGHT", format = function(v) return FormatMoney(v or 0); end },
            { key = "totalTip",        label = L["CO_COL_REVENUE"],   width = 110, align = "RIGHT", format = function(v) return FormatMoney(v or 0); end },
            { key = "uniqueCustomers", label = L["CO_COL_CUSTOMERS"], width = 80,  align = "RIGHT" },
        },
        rowHeight = 24,
        defaultSort = { key = "count", ascending = false },
    });

    itemsTable.frame:SetAllPoints(tableFrame);

    return container;
end

-------------------------------------------------------------------------------
-- Filter sync helper
-------------------------------------------------------------------------------

SyncAllFilters = function()
    if (dashFilter) then dashFilter:UpdateLabel(); end
    if (customersFilter) then customersFilter:UpdateLabel(); end
    if (itemsFilter) then itemsFilter:UpdateLabel(); end
end

-------------------------------------------------------------------------------
-- Panel creation
-------------------------------------------------------------------------------

local function EnsurePanel()
    if (panel) then return panel; end

    panel = LanternUX:CreatePanel({
        name   = "LanternCO_Analytics",
        title  = L["CO_ANALYTICS_TITLE"],
        width  = 750,
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

    return panel;
end

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
    end
end

function CraftingOrders:OpenAnalytics()
    CloseDropdownMenu();
    local p = EnsurePanel();
    p:Show();
end

function CraftingOrders:ToggleAnalytics()
    local p = EnsurePanel();
    CloseDropdownMenu();
    p:Toggle();
end
