local ADDON_NAME, ns = ...;
local L = ns.L;
local Lantern = _G.Lantern;
if (not Lantern) then return; end

local CraftingOrders = Lantern.modules and Lantern.modules.CraftingOrders;
if (not CraftingOrders) then return; end

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local FRAME_WIDTH = 700;
local FRAME_HEIGHT = 500;
local ROW_HEIGHT = 22;
local HEADER_HEIGHT = 24;
local TAB_CUSTOMERS = 1;
local TAB_ITEMS = 2;
local TAB_DASHBOARD = 3;

-- Column definitions per tab
local CUSTOMER_COLUMNS = {
    { key = "name",     label = "CO_COL_CUSTOMER",   width = 160, align = "LEFT" },
    { key = "count",    label = "CO_COL_ORDERS",     width = 80,  align = "RIGHT" },
    { key = "totalTip", label = "CO_COL_TOTAL_TIPS", width = 120, align = "RIGHT", isMoney = true },
    { key = "avgTip",   label = "CO_COL_AVG_TIP",    width = 100, align = "RIGHT", isMoney = true },
    { key = "lastOrder",label = "CO_COL_LAST_ORDER",  width = 100, align = "RIGHT", isTime = true },
};

local ITEM_COLUMNS = {
    { key = "itemLink", label = "CO_COL_ITEM",       width = 200, align = "LEFT", isLink = true },
    { key = "count",    label = "CO_COL_CRAFTS",     width = 80,  align = "RIGHT" },
    { key = "avgTip",   label = "CO_COL_AVG_TIP",    width = 100, align = "RIGHT", isMoney = true },
    { key = "totalTip", label = "CO_COL_REVENUE",    width = 120, align = "RIGHT", isMoney = true },
    { key = "uniqueCustomers", label = "CO_COL_CUSTOMERS", width = 80, align = "RIGHT" },
};

-------------------------------------------------------------------------------
-- Theme helpers (LanternUX fallback)
-------------------------------------------------------------------------------

local function GetThemeColor(key, fallbackR, fallbackG, fallbackB, fallbackA)
    local T = _G.LanternUX and _G.LanternUX.Theme;
    if (T and T[key]) then
        return unpack(T[key]);
    end
    return fallbackR, fallbackG, fallbackB, fallbackA or 1;
end

-------------------------------------------------------------------------------
-- Frame state
-------------------------------------------------------------------------------

local frame = nil;
local currentTab = TAB_CUSTOMERS;
local charFilter = nil; -- nil = current character
local sortKey = "count";
local sortAscending = false;
local dataRows = {};
local headerButtons = {};
local scrollChild = nil;
local scrollFrame = nil;
local filterDropdown = nil;

-------------------------------------------------------------------------------
-- Formatting helpers
-------------------------------------------------------------------------------

local function FormatMoney(copper)
    if (Lantern.Convert) then
        local result = Lantern:Convert("money:format_copper", copper);
        if (result and result ~= "") then return result; end
    end
    -- Fallback: simple gold display
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

local function FormatCellValue(value, column)
    if (column.isMoney) then
        return FormatMoney(value or 0);
    elseif (column.isTime) then
        return FormatTimeAgo(value);
    elseif (column.isLink) then
        -- Item links are set directly as text (they contain color codes)
        return tostring(value or "");
    else
        return tostring(value or "");
    end
end

local function GetCharFilterValue()
    return charFilter or "current";
end

local function GetCharFilterForAPI()
    if (charFilter == "all") then return "all"; end
    return nil; -- nil means current character in the API
end

-------------------------------------------------------------------------------
-- Row pool
-------------------------------------------------------------------------------

local function ClearRows()
    for _, row in ipairs(dataRows) do
        row:Hide();
        row:SetParent(nil);
    end
    dataRows = {};
end

local function CreateRow(parent, index)
    local rowName = "LanternCO_AnalyticsRow_" .. index;
    local row = CreateFrame("Frame", rowName, parent);
    row:SetHeight(ROW_HEIGHT);
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -((index - 1) * ROW_HEIGHT));
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -((index - 1) * ROW_HEIGHT));
    row:EnableMouse(true);

    -- Alternating background
    local bg = row:CreateTexture(rowName .. "_Bg", "BACKGROUND");
    bg:SetAllPoints();
    bg:SetColorTexture(1, 1, 1, (index % 2 == 0) and 0.04 or 0.0);
    row.bg = bg;

    -- Highlight
    local highlight = row:CreateTexture(rowName .. "_Highlight", "HIGHLIGHT");
    highlight:SetAllPoints();
    highlight:SetColorTexture(1, 1, 1, 0.08);

    row.cells = {};
    return row;
end

local function EnsureRowCells(row, columns, rowIndex)
    -- Clear existing cells
    if (row.cells) then
        for _, cell in ipairs(row.cells) do
            cell:Hide();
        end
    end
    row.cells = {};

    local xOffset = 8;
    for i, col in ipairs(columns) do
        local cellName = row:GetName() .. "_Cell_" .. i;
        local cell = row:CreateFontString(cellName, "OVERLAY", "GameFontHighlightSmall");
        cell:SetPoint("LEFT", row, "LEFT", xOffset, 0);
        cell:SetWidth(col.width - 8);
        cell:SetJustifyH(col.align);
        cell:SetWordWrap(false);
        row.cells[i] = cell;
        xOffset = xOffset + col.width;
    end
end

-------------------------------------------------------------------------------
-- Column headers
-------------------------------------------------------------------------------

local headerFrame = nil;

local function ClearHeaders()
    if (headerButtons) then
        for _, btn in ipairs(headerButtons) do
            btn:Hide();
            btn:SetParent(nil);
        end
    end
    headerButtons = {};
end

local function CreateHeaders(parent, columns)
    ClearHeaders();

    if (not headerFrame) then
        headerFrame = CreateFrame("Frame", "LanternCO_AnalyticsHeaders", parent);
        headerFrame:SetHeight(HEADER_HEIGHT);
    end
    headerFrame:SetParent(parent);
    headerFrame:ClearAllPoints();
    headerFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0);
    headerFrame:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0);
    headerFrame:Show();

    -- Header background
    if (not headerFrame.bg) then
        headerFrame.bg = headerFrame:CreateTexture("LanternCO_AnalyticsHeaders_Bg", "BACKGROUND");
        headerFrame.bg:SetAllPoints();
    end
    headerFrame.bg:SetColorTexture(GetThemeColor("cardBg", 1, 1, 1, 0.035));

    -- Bottom divider
    if (not headerFrame.divider) then
        headerFrame.divider = headerFrame:CreateTexture("LanternCO_AnalyticsHeaders_Div", "ARTWORK");
        headerFrame.divider:SetHeight(1);
        headerFrame.divider:SetPoint("BOTTOMLEFT", headerFrame, "BOTTOMLEFT", 0, 0);
        headerFrame.divider:SetPoint("BOTTOMRIGHT", headerFrame, "BOTTOMRIGHT", 0, 0);
    end
    headerFrame.divider:SetColorTexture(GetThemeColor("divider", 0.20, 0.20, 0.22, 0.5));

    local xOffset = 8;
    for i, col in ipairs(columns) do
        local btnName = "LanternCO_AnalyticsHeader_" .. i;
        local btn = CreateFrame("Button", btnName, headerFrame);
        btn:SetHeight(HEADER_HEIGHT);
        btn:SetWidth(col.width);
        btn:SetPoint("LEFT", headerFrame, "LEFT", xOffset, 0);

        local label = btn:CreateFontString(btnName .. "_Text", "OVERLAY", "GameFontNormalSmall");
        label:SetPoint("LEFT", btn, "LEFT", 0, 0);
        label:SetPoint("RIGHT", btn, "RIGHT", -4, 0);
        label:SetJustifyH(col.align);
        label:SetText(L[col.label] or col.label);
        btn.label = label;

        -- Sort arrow
        local arrow = btn:CreateFontString(btnName .. "_Arrow", "OVERLAY", "GameFontNormalSmall");
        if (col.align == "LEFT") then
            arrow:SetPoint("LEFT", label, "RIGHT", 2, 0);
        else
            arrow:SetPoint("RIGHT", label, "LEFT", -2, 0);
        end
        arrow:SetText("");
        btn.arrow = arrow;

        -- Hover highlight
        local hoverTex = btn:CreateTexture(btnName .. "_Hover", "HIGHLIGHT");
        hoverTex:SetAllPoints();
        hoverTex:SetColorTexture(1, 1, 1, 0.05);

        btn:SetScript("OnClick", function()
            if (sortKey == col.key) then
                sortAscending = not sortAscending;
            else
                sortKey = col.key;
                sortAscending = false;
            end
            CraftingOrders:RefreshAnalytics();
        end);

        table.insert(headerButtons, btn);
        xOffset = xOffset + col.width;
    end
end

local function UpdateSortArrows(columns)
    for i, btn in ipairs(headerButtons) do
        if (btn.arrow) then
            if (columns[i] and columns[i].key == sortKey) then
                btn.arrow:SetText(sortAscending and " ^" or " v");
                local ar, ag, ab = GetThemeColor("accent", 0.88, 0.56, 0.18, 1);
                btn.label:SetTextColor(ar, ag, ab);
                btn.arrow:SetTextColor(ar, ag, ab);
            else
                btn.arrow:SetText("");
                btn.label:SetTextColor(1, 0.82, 0, 1);
            end
        end
    end
end

-------------------------------------------------------------------------------
-- Data sorting
-------------------------------------------------------------------------------

local function SortData(data, key, ascending)
    table.sort(data, function(a, b)
        local va = a[key];
        local vb = b[key];
        -- Handle nil values
        if (va == nil and vb == nil) then return false; end
        if (va == nil) then return ascending; end
        if (vb == nil) then return not ascending; end
        -- String compare for string values
        if (type(va) == "string" and type(vb) == "string") then
            if (ascending) then
                return va:lower() < vb:lower();
            else
                return va:lower() > vb:lower();
            end
        end
        -- Numeric compare
        if (ascending) then
            return va < vb;
        else
            return va > vb;
        end
    end);
end

-------------------------------------------------------------------------------
-- Tab: Customers
-------------------------------------------------------------------------------

local function PopulateCustomers()
    ClearRows();
    if (headerFrame) then headerFrame:Show(); end

    local filter = GetCharFilterForAPI();
    local data = CraftingOrders:GetCustomerList(filter);

    SortData(data, sortKey, sortAscending);
    CreateHeaders(scrollChild, CUSTOMER_COLUMNS);
    UpdateSortArrows(CUSTOMER_COLUMNS);

    if (#data == 0) then
        local noData = CreateFrame("Frame", "LanternCO_AnalyticsNoData", scrollChild);
        noData:SetSize(FRAME_WIDTH - 40, 40);
        noData:SetPoint("TOP", scrollChild, "TOP", 0, -(HEADER_HEIGHT + 20));
        local text = noData:CreateFontString("LanternCO_AnalyticsNoData_Text", "OVERLAY", "GameFontNormal");
        text:SetPoint("CENTER");
        text:SetText(L["CO_DASH_NO_DATA"]);
        text:SetTextColor(0.5, 0.5, 0.5);
        table.insert(dataRows, noData);
        scrollChild:SetHeight(HEADER_HEIGHT + 80);
        return;
    end

    for i, entry in ipairs(data) do
        local row = CreateRow(scrollChild, i);
        row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -(HEADER_HEIGHT + (i - 1) * ROW_HEIGHT));
        row:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, -(HEADER_HEIGHT + (i - 1) * ROW_HEIGHT));
        EnsureRowCells(row, CUSTOMER_COLUMNS, i);

        for j, col in ipairs(CUSTOMER_COLUMNS) do
            local value = entry[col.key];
            row.cells[j]:SetText(FormatCellValue(value, col));
        end

        table.insert(dataRows, row);
    end

    scrollChild:SetHeight(HEADER_HEIGHT + #data * ROW_HEIGHT + 20);
end

-------------------------------------------------------------------------------
-- Tab: Items
-------------------------------------------------------------------------------

local function PopulateItems()
    ClearRows();
    if (headerFrame) then headerFrame:Show(); end

    local filter = GetCharFilterForAPI();
    local data = CraftingOrders:GetItemList(filter);

    SortData(data, sortKey, sortAscending);
    CreateHeaders(scrollChild, ITEM_COLUMNS);
    UpdateSortArrows(ITEM_COLUMNS);

    if (#data == 0) then
        local noData = CreateFrame("Frame", "LanternCO_AnalyticsNoData", scrollChild);
        noData:SetSize(FRAME_WIDTH - 40, 40);
        noData:SetPoint("TOP", scrollChild, "TOP", 0, -(HEADER_HEIGHT + 20));
        local text = noData:CreateFontString("LanternCO_AnalyticsNoData_Text", "OVERLAY", "GameFontNormal");
        text:SetPoint("CENTER");
        text:SetText(L["CO_DASH_NO_DATA"]);
        text:SetTextColor(0.5, 0.5, 0.5);
        table.insert(dataRows, noData);
        scrollChild:SetHeight(HEADER_HEIGHT + 80);
        return;
    end

    for i, entry in ipairs(data) do
        local row = CreateRow(scrollChild, i);
        row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -(HEADER_HEIGHT + (i - 1) * ROW_HEIGHT));
        row:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, -(HEADER_HEIGHT + (i - 1) * ROW_HEIGHT));
        EnsureRowCells(row, ITEM_COLUMNS, i);

        for j, col in ipairs(ITEM_COLUMNS) do
            local value = entry[col.key];
            row.cells[j]:SetText(FormatCellValue(value, col));
        end

        table.insert(dataRows, row);
    end

    scrollChild:SetHeight(HEADER_HEIGHT + #data * ROW_HEIGHT + 20);
end

-------------------------------------------------------------------------------
-- Tab: Dashboard
-------------------------------------------------------------------------------

local dashElements = {};

local function ClearDashboard()
    for _, elem in ipairs(dashElements) do
        elem:Hide();
        elem:SetParent(nil);
    end
    dashElements = {};
end

local function CreateDashStatRow(parent, yOffset, labelText, valueText)
    local row = CreateFrame("Frame", "LanternCO_DashStat_" .. (#dashElements + 1), parent);
    row:SetHeight(24);
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, yOffset);
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -12, yOffset);

    local label = row:CreateFontString(row:GetName() .. "_Label", "OVERLAY", "GameFontNormal");
    label:SetPoint("LEFT", row, "LEFT", 0, 0);
    label:SetJustifyH("LEFT");
    label:SetText(labelText);
    label:SetTextColor(0.72, 0.72, 0.72);

    local value = row:CreateFontString(row:GetName() .. "_Value", "OVERLAY", "GameFontHighlight");
    value:SetPoint("RIGHT", row, "RIGHT", 0, 0);
    value:SetJustifyH("RIGHT");
    value:SetText(valueText);

    table.insert(dashElements, row);
    return row;
end

local function CreateDashSectionHeader(parent, yOffset, text)
    local header = CreateFrame("Frame", "LanternCO_DashHeader_" .. (#dashElements + 1), parent);
    header:SetHeight(28);
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, yOffset);
    header:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -8, yOffset);

    -- Background
    local bg = header:CreateTexture(header:GetName() .. "_Bg", "BACKGROUND");
    bg:SetAllPoints();
    bg:SetColorTexture(GetThemeColor("cardBg", 1, 1, 1, 0.035));

    local label = header:CreateFontString(header:GetName() .. "_Label", "OVERLAY", "GameFontNormal");
    label:SetPoint("LEFT", header, "LEFT", 6, 0);
    label:SetJustifyH("LEFT");
    label:SetText(text);
    local ar, ag, ab = GetThemeColor("accent", 0.88, 0.56, 0.18, 1);
    label:SetTextColor(ar, ag, ab);

    table.insert(dashElements, header);
    return header;
end

local function CreateDashRankedRow(parent, yOffset, rank, name, valueText)
    local row = CreateFrame("Frame", "LanternCO_DashRank_" .. (#dashElements + 1), parent);
    row:SetHeight(20);
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, yOffset);
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -12, yOffset);

    local rankLabel = row:CreateFontString(row:GetName() .. "_Rank", "OVERLAY", "GameFontHighlightSmall");
    rankLabel:SetPoint("LEFT", row, "LEFT", 0, 0);
    rankLabel:SetWidth(20);
    rankLabel:SetJustifyH("LEFT");
    rankLabel:SetText(rank .. ".");
    rankLabel:SetTextColor(0.5, 0.5, 0.5);

    local nameLabel = row:CreateFontString(row:GetName() .. "_Name", "OVERLAY", "GameFontHighlightSmall");
    nameLabel:SetPoint("LEFT", rankLabel, "RIGHT", 4, 0);
    nameLabel:SetPoint("RIGHT", row, "RIGHT", -100, 0);
    nameLabel:SetJustifyH("LEFT");
    nameLabel:SetText(name);
    nameLabel:SetWordWrap(false);

    local valueLabel = row:CreateFontString(row:GetName() .. "_Value", "OVERLAY", "GameFontHighlightSmall");
    valueLabel:SetPoint("RIGHT", row, "RIGHT", 0, 0);
    valueLabel:SetWidth(90);
    valueLabel:SetJustifyH("RIGHT");
    valueLabel:SetText(valueText);
    valueLabel:SetTextColor(0.72, 0.72, 0.72);

    table.insert(dashElements, row);
    return row;
end

local function PopulateDashboard()
    ClearRows();
    ClearDashboard();
    if (headerFrame) then headerFrame:Hide(); end

    local filter = GetCharFilterForAPI();
    local stats = CraftingOrders:GetDashboardStats(filter);

    if (stats.totalOrders == 0) then
        local noData = CreateFrame("Frame", "LanternCO_DashNoData", scrollChild);
        noData:SetSize(FRAME_WIDTH - 40, 40);
        noData:SetPoint("TOP", scrollChild, "TOP", 0, -40);
        local text = noData:CreateFontString("LanternCO_DashNoData_Text", "OVERLAY", "GameFontNormal");
        text:SetPoint("CENTER");
        text:SetText(L["CO_DASH_NO_DATA"]);
        text:SetTextColor(0.5, 0.5, 0.5);
        table.insert(dashElements, noData);
        scrollChild:SetHeight(120);
        return;
    end

    local y = -12;

    -- Summary stats section
    CreateDashSectionHeader(scrollChild, y, L["CO_ANALYTICS_TITLE"]);
    y = y - 34;

    CreateDashStatRow(scrollChild, y, L["CO_DASH_TOTAL_ORDERS"], tostring(stats.totalOrders));
    y = y - 26;

    CreateDashStatRow(scrollChild, y, L["CO_DASH_TOTAL_TIPS"], FormatMoney(stats.totalTips));
    y = y - 26;

    CreateDashStatRow(scrollChild, y, L["CO_DASH_AVG_TIP"], FormatMoney(stats.avgTip));
    y = y - 26;

    CreateDashStatRow(scrollChild, y, L["CO_DASH_THIS_WEEK"], tostring(stats.weekOrders));
    y = y - 26;

    CreateDashStatRow(scrollChild, y, L["CO_DASH_THIS_MONTH"], tostring(stats.monthOrders));
    y = y - 40;

    -- Top 5 Customers
    local customerData = CraftingOrders:GetCustomerList(filter);
    SortData(customerData, "totalTip", false);

    CreateDashSectionHeader(scrollChild, y, L["CO_DASH_TOP_CUSTOMERS"]);
    y = y - 32;

    local count = math.min(5, #customerData);
    for i = 1, count do
        local c = customerData[i];
        CreateDashRankedRow(scrollChild, y, i, c.name, FormatMoney(c.totalTip));
        y = y - 22;
    end
    if (count == 0) then
        local empty = CreateFrame("Frame", "LanternCO_DashEmptyCust", scrollChild);
        empty:SetSize(200, 20);
        empty:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 20, y);
        local emptyText = empty:CreateFontString("LanternCO_DashEmptyCust_Text", "OVERLAY", "GameFontHighlightSmall");
        emptyText:SetPoint("LEFT");
        emptyText:SetText("-");
        emptyText:SetTextColor(0.5, 0.5, 0.5);
        table.insert(dashElements, empty);
        y = y - 22;
    end

    y = y - 16;

    -- Top 5 Items
    local itemData = CraftingOrders:GetItemList(filter);
    SortData(itemData, "totalTip", false);

    CreateDashSectionHeader(scrollChild, y, L["CO_DASH_TOP_ITEMS"]);
    y = y - 32;

    count = math.min(5, #itemData);
    for i = 1, count do
        local it = itemData[i];
        local displayName = it.itemLink or ("Item #" .. tostring(it.itemID));
        CreateDashRankedRow(scrollChild, y, i, displayName, FormatMoney(it.totalTip));
        y = y - 22;
    end
    if (count == 0) then
        local empty = CreateFrame("Frame", "LanternCO_DashEmptyItems", scrollChild);
        empty:SetSize(200, 20);
        empty:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 20, y);
        local emptyText = empty:CreateFontString("LanternCO_DashEmptyItems_Text", "OVERLAY", "GameFontHighlightSmall");
        emptyText:SetPoint("LEFT");
        emptyText:SetText("-");
        emptyText:SetTextColor(0.5, 0.5, 0.5);
        table.insert(dashElements, empty);
        y = y - 22;
    end

    scrollChild:SetHeight(math.abs(y) + 20);
end

-------------------------------------------------------------------------------
-- Tab system
-------------------------------------------------------------------------------

local tabs = {};

local function SetTab(tabIndex)
    currentTab = tabIndex;

    -- Reset sort defaults per tab
    if (tabIndex == TAB_CUSTOMERS) then
        sortKey = "count";
        sortAscending = false;
    elseif (tabIndex == TAB_ITEMS) then
        sortKey = "count";
        sortAscending = false;
    elseif (tabIndex == TAB_DASHBOARD) then
        sortKey = "totalTip";
        sortAscending = false;
    end

    -- Update tab visual state
    for i, tab in ipairs(tabs) do
        if (i == tabIndex) then
            PanelTemplates_SelectTab(tab);
        else
            PanelTemplates_DeselectTab(tab);
        end
    end

    CraftingOrders:RefreshAnalytics();
end

local function CreateTabs(parentFrame)
    local tabData = {
        { label = L["CO_TAB_CUSTOMERS"] },
        { label = L["CO_TAB_ITEMS"] },
        { label = L["CO_TAB_DASHBOARD"] },
    };

    for i, info in ipairs(tabData) do
        local tabName = "LanternCO_AnalyticsTab" .. i;
        local tab = CreateFrame("Button", tabName, parentFrame, "PanelTabButtonTemplate");

        if (i == 1) then
            tab:SetPoint("BOTTOMLEFT", parentFrame, "BOTTOMLEFT", 15, -30);
        else
            tab:SetPoint("LEFT", tabs[i - 1], "RIGHT", -5, 0);
        end

        tab:SetText(info.label);
        tab:SetID(i);
        PanelTemplates_TabResize(tab, 0);

        tab:SetScript("OnClick", function()
            SetTab(i);
        end);

        table.insert(tabs, tab);
    end

    -- Set initial tab selection
    PanelTemplates_SelectTab(tabs[TAB_CUSTOMERS]);
    for i = 2, #tabs do
        PanelTemplates_DeselectTab(tabs[i]);
    end
end

-------------------------------------------------------------------------------
-- Character filter dropdown
-------------------------------------------------------------------------------

local function InitFilterDropdown(self, level)
    local info = UIDropDownMenu_CreateInfo();

    -- Current character option
    info.text = L["CO_FILTER_CURRENT"];
    info.value = "current";
    info.checked = (GetCharFilterValue() == "current");
    info.func = function()
        charFilter = nil;
        UIDropDownMenu_SetText(filterDropdown, L["CO_FILTER_CURRENT"]);
        CraftingOrders:RefreshAnalytics();
    end;
    UIDropDownMenu_AddButton(info);

    -- All characters option
    info = UIDropDownMenu_CreateInfo();
    info.text = L["CO_FILTER_ALL"];
    info.value = "all";
    info.checked = (GetCharFilterValue() == "all");
    info.func = function()
        charFilter = "all";
        UIDropDownMenu_SetText(filterDropdown, L["CO_FILTER_ALL"]);
        CraftingOrders:RefreshAnalytics();
    end;
    UIDropDownMenu_AddButton(info);
end

local function CreateFilterDropdown(parentFrame)
    filterDropdown = CreateFrame("Frame", "LanternCO_AnalyticsFilter", parentFrame, "UIDropDownMenuTemplate");
    filterDropdown:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", -40, -28);
    UIDropDownMenu_SetWidth(filterDropdown, 140);
    UIDropDownMenu_SetText(filterDropdown, L["CO_FILTER_CURRENT"]);
    UIDropDownMenu_Initialize(filterDropdown, InitFilterDropdown);
end

-------------------------------------------------------------------------------
-- Main frame creation
-------------------------------------------------------------------------------

local function CreateAnalyticsFrame()
    if (frame) then return frame; end

    frame = CreateFrame("Frame", "LanternCO_AnalyticsFrame", UIParent, "ButtonFrameTemplate");
    frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT);
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
    frame:SetMovable(true);
    frame:EnableMouse(true);
    frame:RegisterForDrag("LeftButton");
    frame:SetScript("OnDragStart", frame.StartMoving);
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing();
    end);
    frame:SetClampedToScreen(true);
    frame:SetFrameStrata("HIGH");
    frame:SetFrameLevel(100);

    -- Portrait and title
    frame:SetPortraitToAsset("Interface\\Icons\\inv_misc_coin_02");
    frame:SetTitle(L["CO_ANALYTICS_TITLE"]);

    -- Title bar drag
    if (frame.TitleContainer) then
        frame.TitleContainer:EnableMouse(true);
        frame.TitleContainer:RegisterForDrag("LeftButton");
        frame.TitleContainer:SetScript("OnDragStart", function()
            frame:StartMoving();
        end);
        frame.TitleContainer:SetScript("OnDragStop", function()
            frame:StopMovingOrSizing();
        end);
    end

    -- Inset adjusted for tabs at bottom of title and content area
    frame.Inset:ClearAllPoints();
    frame.Inset:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -56);
    frame.Inset:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -6, 6);

    -- Scroll frame inside the inset
    scrollFrame = CreateFrame("ScrollFrame", "LanternCO_AnalyticsScroll", frame.Inset, "UIPanelScrollFrameTemplate");
    scrollFrame:SetPoint("TOPLEFT", frame.Inset, "TOPLEFT", 4, -4);
    scrollFrame:SetPoint("BOTTOMRIGHT", frame.Inset, "BOTTOMRIGHT", -22, 4);

    scrollChild = CreateFrame("Frame", "LanternCO_AnalyticsScrollChild", scrollFrame);
    scrollChild:SetWidth(scrollFrame:GetWidth() or (FRAME_WIDTH - 60));
    scrollChild:SetHeight(1);
    scrollFrame:SetScrollChild(scrollChild);

    -- Fix scroll child width when scroll frame resizes
    scrollFrame:SetScript("OnSizeChanged", function(self, width, height)
        if (scrollChild and width and width > 0) then
            scrollChild:SetWidth(width);
        end
    end);

    -- Create tabs
    CreateTabs(frame);

    -- Create character filter dropdown
    CreateFilterDropdown(frame);

    -- Close button hook
    frame.CloseButton:SetScript("OnClick", function()
        frame:Hide();
    end);

    -- ESC to close
    table.insert(UISpecialFrames, "LanternCO_AnalyticsFrame");

    frame:Hide();

    return frame;
end

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------

function CraftingOrders:RefreshAnalytics()
    if (not frame or not frame:IsShown()) then return; end

    -- Clear scroll position
    if (scrollFrame and scrollFrame.SetVerticalScroll) then
        scrollFrame:SetVerticalScroll(0);
    end

    if (currentTab == TAB_CUSTOMERS) then
        PopulateCustomers();
    elseif (currentTab == TAB_ITEMS) then
        PopulateItems();
    elseif (currentTab == TAB_DASHBOARD) then
        PopulateDashboard();
    end
end

function CraftingOrders:OpenAnalytics()
    local f = CreateAnalyticsFrame();
    f:Show();
    self:RefreshAnalytics();
end

function CraftingOrders:ToggleAnalytics()
    if (frame and frame:IsShown()) then
        frame:Hide();
    else
        self:OpenAnalytics();
    end
end
