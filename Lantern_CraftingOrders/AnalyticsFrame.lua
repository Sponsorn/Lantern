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
local rowPool = {};      -- persistent pool of row frames (indexed by number)
local activeRowCount = 0; -- how many pool entries are currently in use
local headerPool = {};    -- persistent pool of header buttons (indexed by number)
local activeHeaderCount = 0;
local dashPool = {};      -- persistent pool of dashboard elements (indexed by number)
local activeDashCount = 0;
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

local function HideAllRows()
    for i = 1, #rowPool do
        rowPool[i]:Hide();
    end
    activeRowCount = 0;
end

local function AcquireRow(parent, index)
    local row = rowPool[index];
    if (not row) then
        -- Create a new row and add to pool
        local rowName = "LanternCO_AnalyticsRow_" .. index;
        row = CreateFrame("Frame", rowName, parent);
        row:SetHeight(ROW_HEIGHT);
        row:EnableMouse(true);

        -- Alternating background
        local bg = row:CreateTexture(rowName .. "_Bg", "BACKGROUND");
        bg:SetAllPoints();
        row.bg = bg;

        -- Highlight
        local highlight = row:CreateTexture(rowName .. "_Highlight", "HIGHLIGHT");
        highlight:SetAllPoints();
        highlight:SetColorTexture(1, 1, 1, 0.08);

        row.cells = {};
        rowPool[index] = row;
    end

    -- Update parent (in case it changed) and alternating background
    row:SetParent(parent);
    row.bg:SetColorTexture(1, 1, 1, (index % 2 == 0) and 0.04 or 0.0);
    row:ClearAllPoints();
    row:Show();
    activeRowCount = index;
    return row;
end

local function EnsureRowCells(row, columns, rowIndex)
    if (not row.cells) then
        row.cells = {};
    end

    local xOffset = 8;
    for i, col in ipairs(columns) do
        local cell = row.cells[i];
        if (not cell) then
            -- Only create a new FontString if one doesn't already exist at this index
            local cellName = row:GetName() .. "_Cell_" .. i;
            cell = row:CreateFontString(cellName, "OVERLAY", "GameFontHighlightSmall");
            cell:SetWordWrap(false);
            row.cells[i] = cell;
        end
        cell:ClearAllPoints();
        cell:SetPoint("LEFT", row, "LEFT", xOffset, 0);
        cell:SetWidth(col.width - 8);
        cell:SetJustifyH(col.align);
        cell:SetText("");
        cell:Show();
        xOffset = xOffset + col.width;
    end

    -- Hide excess cells from a previous layout with more columns
    for i = #columns + 1, #row.cells do
        row.cells[i]:Hide();
    end
end

-------------------------------------------------------------------------------
-- Column headers
-------------------------------------------------------------------------------

local headerFrame = nil;

local function HideAllHeaders()
    for i = 1, #headerPool do
        headerPool[i]:Hide();
    end
    activeHeaderCount = 0;
end

local function CreateHeaders(parent, columns)
    HideAllHeaders();

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
        local btn = headerPool[i];
        if (not btn) then
            -- Create a new header button and add to pool
            local btnName = "LanternCO_AnalyticsHeader_" .. i;
            btn = CreateFrame("Button", btnName, headerFrame);

            local label = btn:CreateFontString(btnName .. "_Text", "OVERLAY", "GameFontNormalSmall");
            label:SetPoint("LEFT", btn, "LEFT", 0, 0);
            label:SetPoint("RIGHT", btn, "RIGHT", -4, 0);
            btn.label = label;

            -- Sort arrow
            local arrow = btn:CreateFontString(btnName .. "_Arrow", "OVERLAY", "GameFontNormalSmall");
            btn.arrow = arrow;

            -- Hover highlight
            local hoverTex = btn:CreateTexture(btnName .. "_Hover", "HIGHLIGHT");
            hoverTex:SetAllPoints();
            hoverTex:SetColorTexture(1, 1, 1, 0.05);

            headerPool[i] = btn;
        end

        -- Update per-refresh properties
        btn:SetParent(headerFrame);
        btn:SetHeight(HEADER_HEIGHT);
        btn:SetWidth(col.width);
        btn:ClearAllPoints();
        btn:SetPoint("LEFT", headerFrame, "LEFT", xOffset, 0);

        btn.label:SetJustifyH(col.align);
        btn.label:SetText(L[col.label] or col.label);

        btn.arrow:ClearAllPoints();
        if (col.align == "LEFT") then
            btn.arrow:SetPoint("LEFT", btn.label, "RIGHT", 2, 0);
        else
            btn.arrow:SetPoint("RIGHT", btn.label, "LEFT", -2, 0);
        end
        btn.arrow:SetText("");

        -- Capture col.key for the closure
        local colKey = col.key;
        btn:SetScript("OnClick", function()
            if (sortKey == colKey) then
                sortAscending = not sortAscending;
            else
                sortKey = colKey;
                sortAscending = false;
            end
            CraftingOrders:RefreshAnalytics();
        end);

        btn:Show();
        activeHeaderCount = i;
        xOffset = xOffset + col.width;
    end
end

local function UpdateSortArrows(columns)
    for i = 1, activeHeaderCount do
        local btn = headerPool[i];
        if (btn and btn.arrow) then
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

        local ta = type(va);
        local tb = type(vb);

        -- Mixed types: sort numbers before strings for a stable order
        if (ta ~= tb) then
            if (ta == "number") then return ascending; end
            if (tb == "number") then return not ascending; end
            -- Fallback: compare type names for any other mixed types
            if (ascending) then return ta < tb; end
            return ta > tb;
        end

        -- String compare
        if (ta == "string") then
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

-- Persistent "no data" frames (created on first use, one per tab)
local customersNoData = nil;
local itemsNoData = nil;
local dashNoData = nil;

local function HideAllNoData()
    if (customersNoData) then customersNoData:Hide(); end
    if (itemsNoData) then itemsNoData:Hide(); end
    if (dashNoData) then dashNoData:Hide(); end
end

local function PopulateCustomers()
    HideAllRows();
    HideAllNoData();
    if (headerFrame) then headerFrame:Show(); end

    local filter = GetCharFilterForAPI();
    local data = CraftingOrders:GetCustomerList(filter);

    SortData(data, sortKey, sortAscending);
    CreateHeaders(scrollChild, CUSTOMER_COLUMNS);
    UpdateSortArrows(CUSTOMER_COLUMNS);

    if (#data == 0) then
        if (not customersNoData) then
            customersNoData = CreateFrame("Frame", "LanternCO_CustomersNoData", scrollChild);
            customersNoData:SetSize(FRAME_WIDTH - 40, 40);
            local text = customersNoData:CreateFontString("LanternCO_CustomersNoData_Text", "OVERLAY", "GameFontNormal");
            text:SetPoint("CENTER");
            text:SetTextColor(0.5, 0.5, 0.5);
            customersNoData.text = text;
        end
        customersNoData:SetParent(scrollChild);
        customersNoData:ClearAllPoints();
        customersNoData:SetPoint("TOP", scrollChild, "TOP", 0, -(HEADER_HEIGHT + 20));
        customersNoData.text:SetText(L["CO_DASH_NO_DATA"]);
        customersNoData:Show();
        scrollChild:SetHeight(HEADER_HEIGHT + 80);
        return;
    end

    for i, entry in ipairs(data) do
        local row = AcquireRow(scrollChild, i);
        row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -(HEADER_HEIGHT + (i - 1) * ROW_HEIGHT));
        row:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, -(HEADER_HEIGHT + (i - 1) * ROW_HEIGHT));
        EnsureRowCells(row, CUSTOMER_COLUMNS, i);

        for j, col in ipairs(CUSTOMER_COLUMNS) do
            local value = entry[col.key];
            row.cells[j]:SetText(FormatCellValue(value, col));
        end
    end

    scrollChild:SetHeight(HEADER_HEIGHT + #data * ROW_HEIGHT + 20);
end

-------------------------------------------------------------------------------
-- Tab: Items
-------------------------------------------------------------------------------

local function PopulateItems()
    HideAllRows();
    HideAllNoData();
    if (headerFrame) then headerFrame:Show(); end

    local filter = GetCharFilterForAPI();
    local data = CraftingOrders:GetItemList(filter);

    SortData(data, sortKey, sortAscending);
    CreateHeaders(scrollChild, ITEM_COLUMNS);
    UpdateSortArrows(ITEM_COLUMNS);

    if (#data == 0) then
        if (not itemsNoData) then
            itemsNoData = CreateFrame("Frame", "LanternCO_ItemsNoData", scrollChild);
            itemsNoData:SetSize(FRAME_WIDTH - 40, 40);
            local text = itemsNoData:CreateFontString("LanternCO_ItemsNoData_Text", "OVERLAY", "GameFontNormal");
            text:SetPoint("CENTER");
            text:SetTextColor(0.5, 0.5, 0.5);
            itemsNoData.text = text;
        end
        itemsNoData:SetParent(scrollChild);
        itemsNoData:ClearAllPoints();
        itemsNoData:SetPoint("TOP", scrollChild, "TOP", 0, -(HEADER_HEIGHT + 20));
        itemsNoData.text:SetText(L["CO_DASH_NO_DATA"]);
        itemsNoData:Show();
        scrollChild:SetHeight(HEADER_HEIGHT + 80);
        return;
    end

    for i, entry in ipairs(data) do
        local row = AcquireRow(scrollChild, i);
        row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -(HEADER_HEIGHT + (i - 1) * ROW_HEIGHT));
        row:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, -(HEADER_HEIGHT + (i - 1) * ROW_HEIGHT));
        EnsureRowCells(row, ITEM_COLUMNS, i);

        for j, col in ipairs(ITEM_COLUMNS) do
            local value = entry[col.key];
            row.cells[j]:SetText(FormatCellValue(value, col));
        end
    end

    scrollChild:SetHeight(HEADER_HEIGHT + #data * ROW_HEIGHT + 20);
end

-------------------------------------------------------------------------------
-- Tab: Dashboard
-------------------------------------------------------------------------------

local function HideAllDashElements()
    for i = 1, #dashPool do
        dashPool[i]:Hide();
    end
    activeDashCount = 0;
end

local function AcquireDashElement(parent, height)
    activeDashCount = activeDashCount + 1;
    local idx = activeDashCount;
    local elem = dashPool[idx];
    if (not elem) then
        local elemName = "LanternCO_DashElem_" .. idx;
        elem = CreateFrame("Frame", elemName, parent);
        dashPool[idx] = elem;
    end
    elem:SetParent(parent);
    elem:SetHeight(height);
    elem:ClearAllPoints();
    elem:Show();
    return elem;
end

local function CreateDashStatRow(parent, yOffset, labelText, valueText)
    local row = AcquireDashElement(parent, 24);
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, yOffset);
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -12, yOffset);

    if (not row.label) then
        row.label = row:CreateFontString(row:GetName() .. "_Label", "OVERLAY", "GameFontNormal");
        row.label:SetPoint("LEFT", row, "LEFT", 0, 0);
        row.label:SetJustifyH("LEFT");
    end
    row.label:SetText(labelText);
    row.label:SetTextColor(0.72, 0.72, 0.72);
    row.label:Show();

    if (not row.value) then
        row.value = row:CreateFontString(row:GetName() .. "_Value", "OVERLAY", "GameFontHighlight");
        row.value:SetPoint("RIGHT", row, "RIGHT", 0, 0);
        row.value:SetJustifyH("RIGHT");
    end
    row.value:SetText(valueText);
    row.value:Show();

    -- Hide sub-elements from other dashboard element types if this frame was reused
    if (row.bg) then row.bg:Hide(); end
    if (row.rankLabel) then row.rankLabel:Hide(); end
    if (row.nameLabel) then row.nameLabel:Hide(); end
    if (row.valueLabel) then row.valueLabel:Hide(); end

    return row;
end

local function CreateDashSectionHeader(parent, yOffset, text)
    local header = AcquireDashElement(parent, 28);
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, yOffset);
    header:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -8, yOffset);

    -- Background
    if (not header.bg) then
        header.bg = header:CreateTexture(header:GetName() .. "_Bg", "BACKGROUND");
        header.bg:SetAllPoints();
    end
    header.bg:SetColorTexture(GetThemeColor("cardBg", 1, 1, 1, 0.035));
    header.bg:Show();

    if (not header.label) then
        header.label = header:CreateFontString(header:GetName() .. "_Label", "OVERLAY", "GameFontNormal");
        header.label:SetPoint("LEFT", header, "LEFT", 6, 0);
        header.label:SetJustifyH("LEFT");
    end
    header.label:SetText(text);
    local ar, ag, ab = GetThemeColor("accent", 0.88, 0.56, 0.18, 1);
    header.label:SetTextColor(ar, ag, ab);
    header.label:Show();

    -- Hide sub-elements from other dashboard element types if this frame was reused
    if (header.value) then header.value:Hide(); end
    if (header.rankLabel) then header.rankLabel:Hide(); end
    if (header.nameLabel) then header.nameLabel:Hide(); end
    if (header.valueLabel) then header.valueLabel:Hide(); end

    return header;
end

local function CreateDashRankedRow(parent, yOffset, rank, name, valueText)
    local row = AcquireDashElement(parent, 20);
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, yOffset);
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -12, yOffset);

    if (not row.rankLabel) then
        row.rankLabel = row:CreateFontString(row:GetName() .. "_Rank", "OVERLAY", "GameFontHighlightSmall");
        row.rankLabel:SetPoint("LEFT", row, "LEFT", 0, 0);
        row.rankLabel:SetWidth(20);
        row.rankLabel:SetJustifyH("LEFT");
    end
    row.rankLabel:SetText(rank .. ".");
    row.rankLabel:SetTextColor(0.5, 0.5, 0.5);
    row.rankLabel:Show();

    if (not row.nameLabel) then
        row.nameLabel = row:CreateFontString(row:GetName() .. "_Name", "OVERLAY", "GameFontHighlightSmall");
        row.nameLabel:SetPoint("LEFT", row.rankLabel, "RIGHT", 4, 0);
        row.nameLabel:SetPoint("RIGHT", row, "RIGHT", -100, 0);
        row.nameLabel:SetJustifyH("LEFT");
        row.nameLabel:SetWordWrap(false);
    end
    row.nameLabel:SetText(name);
    row.nameLabel:Show();

    if (not row.valueLabel) then
        row.valueLabel = row:CreateFontString(row:GetName() .. "_Value", "OVERLAY", "GameFontHighlightSmall");
        row.valueLabel:SetPoint("RIGHT", row, "RIGHT", 0, 0);
        row.valueLabel:SetWidth(90);
        row.valueLabel:SetJustifyH("RIGHT");
    end
    row.valueLabel:SetText(valueText);
    row.valueLabel:SetTextColor(0.72, 0.72, 0.72);
    row.valueLabel:Show();

    -- Hide sub-elements from other dashboard element types if this frame was reused
    if (row.bg) then row.bg:Hide(); end
    if (row.label) then row.label:Hide(); end
    if (row.value) then row.value:Hide(); end

    return row;
end

local function PopulateDashboard()
    HideAllRows();
    HideAllNoData();
    HideAllDashElements();
    if (headerFrame) then headerFrame:Hide(); end

    local filter = GetCharFilterForAPI();
    local stats = CraftingOrders:GetDashboardStats(filter);

    if (stats.totalOrders == 0) then
        if (not dashNoData) then
            dashNoData = CreateFrame("Frame", "LanternCO_DashNoData", scrollChild);
            dashNoData:SetSize(FRAME_WIDTH - 40, 40);
            local text = dashNoData:CreateFontString("LanternCO_DashNoData_Text", "OVERLAY", "GameFontNormal");
            text:SetPoint("CENTER");
            text:SetTextColor(0.5, 0.5, 0.5);
            dashNoData.text = text;
        end
        dashNoData:SetParent(scrollChild);
        dashNoData:ClearAllPoints();
        dashNoData:SetPoint("TOP", scrollChild, "TOP", 0, -40);
        dashNoData.text:SetText(L["CO_DASH_NO_DATA"]);
        dashNoData:Show();
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
        -- Use the dashboard pool for the empty placeholder
        local empty = AcquireDashElement(scrollChild, 20);
        empty:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 20, y);
        empty:SetWidth(200);
        if (not empty.label) then
            empty.label = empty:CreateFontString(empty:GetName() .. "_Label", "OVERLAY", "GameFontHighlightSmall");
            empty.label:SetPoint("LEFT");
        end
        empty.label:SetText("-");
        empty.label:SetTextColor(0.5, 0.5, 0.5);
        empty.label:Show();
        -- Hide sub-elements from other types
        if (empty.bg) then empty.bg:Hide(); end
        if (empty.value) then empty.value:Hide(); end
        if (empty.rankLabel) then empty.rankLabel:Hide(); end
        if (empty.nameLabel) then empty.nameLabel:Hide(); end
        if (empty.valueLabel) then empty.valueLabel:Hide(); end
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
        -- Use the dashboard pool for the empty placeholder
        local empty = AcquireDashElement(scrollChild, 20);
        empty:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 20, y);
        empty:SetWidth(200);
        if (not empty.label) then
            empty.label = empty:CreateFontString(empty:GetName() .. "_Label", "OVERLAY", "GameFontHighlightSmall");
            empty.label:SetPoint("LEFT");
        end
        empty.label:SetText("-");
        empty.label:SetTextColor(0.5, 0.5, 0.5);
        empty.label:Show();
        -- Hide sub-elements from other types
        if (empty.bg) then empty.bg:Hide(); end
        if (empty.value) then empty.value:Hide(); end
        if (empty.rankLabel) then empty.rankLabel:Hide(); end
        if (empty.nameLabel) then empty.nameLabel:Hide(); end
        if (empty.valueLabel) then empty.valueLabel:Hide(); end
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
    local w = scrollFrame:GetWidth();
    scrollChild:SetWidth((w > 0) and w or (FRAME_WIDTH - 60));
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
