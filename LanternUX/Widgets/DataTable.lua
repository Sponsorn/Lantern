local ADDON_NAME = ...;

local LanternUX = _G.LanternUX;
local T = LanternUX and LanternUX.Theme;
if (not T) then return; end

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local DEFAULT_ROW_HEIGHT = 24;
local HEADER_HEIGHT      = 26;
local CELL_PAD           = 8;
local SORT_ARROW_UP      = " ^";
local SORT_ARROW_DOWN    = " v";
local CHEVRON_COLLAPSED  = "> ";
local CHEVRON_EXPANDED   = "v ";
local CHILD_INDENT       = 16;
local CHILD_BORDER_W     = 2;
local SEARCH_INPUT_H     = 24;
local SEARCH_PAD         = 6;
local SEARCH_TOTAL_H     = SEARCH_PAD + SEARCH_INPUT_H + SEARCH_PAD;
local SEARCH_DEBOUNCE    = 0.15;

local nameCounter = 0;
local function NextName(prefix)
    nameCounter = nameCounter + 1;
    return prefix .. nameCounter;
end

-------------------------------------------------------------------------------
-- CreateDataTable
-------------------------------------------------------------------------------

function LanternUX.CreateDataTable(parent, config)
    local dt = {};
    dt._columns        = config.columns or {};
    dt._rowHeight      = config.rowHeight or DEFAULT_ROW_HEIGHT;
    dt._onRowClick     = config.onRowClick;
    dt._rowTooltip     = config.rowTooltip;
    dt._data           = {};
    dt._sortKey        = config.defaultSort and config.defaultSort.key or nil;
    dt._sortAsc        = config.defaultSort and config.defaultSort.ascending or false;
    dt._rowPool        = {};
    dt._activeRows     = 0;
    dt._page           = 1;
    dt._pageSize       = config.pageSize or nil;
    dt._totalPages     = 1;

    -- Expandable row config
    dt._expandKey      = config.expandKey or nil;
    dt._childColumns   = config.childColumns or nil;
    dt._getChildren    = config.getChildren or nil;
    dt._childRowTooltip = config.childRowTooltip or nil;
    dt._expandedKey    = nil;

    -- Child row pool (separate from parent pool since child rows have different column sets)
    dt._childRowPool   = {};
    dt._activeChildRows = 0;

    -- Search config
    dt._searchColumns     = config.searchColumns or nil;
    dt._searchPlaceholder = config.searchPlaceholder or "Search...";
    dt._searchQuery       = "";
    dt._searchDebounce    = nil;

    -- Outer container frame
    local frameName = NextName("LUX_DT_");
    local frame = CreateFrame("Frame", frameName, parent);
    dt.frame = frame;

    ---------------------------------------------------------------------------
    -- Header bar
    ---------------------------------------------------------------------------

    local headerFrame = CreateFrame("Frame", frameName .. "_Header", frame);
    headerFrame:SetHeight(HEADER_HEIGHT);
    headerFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0);
    headerFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0);
    dt._headerFrame = headerFrame;

    -- Header background
    local headerBg = headerFrame:CreateTexture(frameName .. "_HeaderBg", "BACKGROUND");
    headerBg:SetAllPoints();
    headerBg:SetColorTexture(unpack(T.cardBg));

    -- Header bottom border
    local headerBorder = headerFrame:CreateTexture(frameName .. "_HeaderBorder", "ARTWORK");
    headerBorder:SetHeight(1);
    headerBorder:SetPoint("BOTTOMLEFT", headerFrame, "BOTTOMLEFT", 0, 0);
    headerBorder:SetPoint("BOTTOMRIGHT", headerFrame, "BOTTOMRIGHT", 0, 0);
    headerBorder:SetColorTexture(unpack(T.cardBorder));

    -- Build header buttons
    dt._headerButtons = {};
    local xOffset = CELL_PAD;

    for i, col in ipairs(dt._columns) do
        local btnName = NextName("LUX_DT_Header_");
        local btn = CreateFrame("Button", btnName, headerFrame);
        btn:SetHeight(HEADER_HEIGHT);
        btn:SetWidth(col.width);
        btn:SetPoint("LEFT", headerFrame, "LEFT", xOffset, 0);

        local arrow = btn:CreateFontString(btnName .. "_Arrow", "OVERLAY");
        arrow:SetFontObject(T.fontSmallBold);
        arrow:SetText("");
        arrow:SetTextColor(unpack(T.accent));
        btn._arrow = arrow;

        local label = btn:CreateFontString(btnName .. "_Text", "OVERLAY");
        label:SetFontObject(T.fontSmallBold);
        label:SetJustifyH(col.align or "LEFT");
        label:SetText(col.label or "");
        label:SetTextColor(unpack(T.textDim));
        btn._label = label;

        -- Anchor arrow inside the button edge, label fills remaining space
        if (col.align == "RIGHT") then
            arrow:SetPoint("LEFT", btn, "LEFT", 2, 0);
            label:SetPoint("LEFT", arrow, "RIGHT", 2, 0);
            label:SetPoint("RIGHT", btn, "RIGHT", -4, 0);
        else
            label:SetPoint("LEFT", btn, "LEFT", 4, 0);
            arrow:SetPoint("RIGHT", btn, "RIGHT", -4, 0);
            label:SetPoint("RIGHT", arrow, "LEFT", -2, 0);
        end

        -- Hover highlight
        local hoverTex = btn:CreateTexture(btnName .. "_Hover", "HIGHLIGHT");
        hoverTex:SetAllPoints();
        hoverTex:SetColorTexture(unpack(T.hover));

        -- Click handler: toggle sort
        local colKey = col.key;
        btn:SetScript("OnClick", function()
            if (dt._sortKey == colKey) then
                dt._sortAsc = not dt._sortAsc;
            else
                dt._sortKey = colKey;
                -- Default sort direction: prefer descending for new columns
                dt._sortAsc = false;
            end
            dt:Refresh();
        end);

        dt._headerButtons[i] = btn;
        xOffset = xOffset + col.width;
    end

    ---------------------------------------------------------------------------
    -- Search input (optional — only built when searchColumns is configured)
    ---------------------------------------------------------------------------

    local searchFrame;

    if (dt._searchColumns) then
        searchFrame = CreateFrame("Frame", frameName .. "_Search", frame);
        searchFrame:SetHeight(SEARCH_TOTAL_H);
        searchFrame:SetPoint("TOPLEFT", headerFrame, "BOTTOMLEFT", 0, 0);
        searchFrame:SetPoint("TOPRIGHT", headerFrame, "BOTTOMRIGHT", 0, 0);

        -- Background to match header
        local searchBg = searchFrame:CreateTexture(frameName .. "_SearchBg", "BACKGROUND");
        searchBg:SetAllPoints();
        searchBg:SetColorTexture(unpack(T.cardBg));

        local boxName = frameName .. "_SearchBox";
        local searchBox = CreateFrame("EditBox", boxName, searchFrame, "BackdropTemplate");
        searchBox:SetHeight(SEARCH_INPUT_H);
        searchBox:SetPoint("TOPLEFT", searchFrame, "TOPLEFT", CELL_PAD, -SEARCH_PAD);
        searchBox:SetPoint("TOPRIGHT", searchFrame, "TOPRIGHT", -CELL_PAD, -SEARCH_PAD);
        searchBox:SetAutoFocus(false);
        searchBox:SetFontObject(T.fontSmall);
        searchBox:SetTextInsets(20, 6, 0, 0);
        searchBox:SetMaxLetters(64);

        searchBox:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        });
        searchBox:SetBackdropColor(T.inputBg[1], T.inputBg[2], T.inputBg[3], T.inputBg[4]);
        searchBox:SetBackdropBorderColor(T.inputBorder[1], T.inputBorder[2], T.inputBorder[3], T.inputBorder[4]);
        searchBox:SetTextColor(unpack(T.text));

        -- Magnifying glass icon
        local searchIcon = searchBox:CreateTexture(boxName .. "_Icon", "ARTWORK");
        searchIcon:SetSize(12, 12);
        searchIcon:SetPoint("LEFT", 5, 0);
        searchIcon:SetAtlas("common-search-magnifyingglass");
        searchIcon:SetDesaturated(true);
        searchIcon:SetVertexColor(unpack(T.textDim));

        -- Placeholder text
        local placeholder = searchBox:CreateFontString(boxName .. "_PH", "ARTWORK");
        placeholder:SetFontObject(T.fontSmall);
        placeholder:SetPoint("LEFT", 20, 0);
        placeholder:SetText(dt._searchPlaceholder);
        placeholder:SetTextColor(T.textDim[1], T.textDim[2], T.textDim[3], 0.6);

        -- Focus handlers
        searchBox:SetScript("OnEditFocusGained", function(self_)
            self_:SetBackdropBorderColor(T.inputFocus[1], T.inputFocus[2], T.inputFocus[3], T.inputFocus[4]);
            if (self_:GetText() == "") then placeholder:Hide(); end
        end);
        searchBox:SetScript("OnEditFocusLost", function(self_)
            self_:SetBackdropBorderColor(T.inputBorder[1], T.inputBorder[2], T.inputBorder[3], T.inputBorder[4]);
            if (self_:GetText() == "") then placeholder:Show(); end
        end);

        -- Debounced text change
        searchBox:SetScript("OnTextChanged", function(self_, userInput)
            if (not userInput) then return; end
            local text = self_:GetText();
            if (text == "") then placeholder:Show(); else placeholder:Hide(); end

            if (dt._searchDebounce) then
                dt._searchDebounce:Cancel();
            end
            dt._searchDebounce = C_Timer.NewTimer(SEARCH_DEBOUNCE, function()
                dt._searchDebounce = nil;
                dt._searchQuery = text;
                dt._page = 1;
                dt:Refresh();
            end);
        end);

        -- ESC clears search
        searchBox:SetScript("OnEscapePressed", function(self_)
            self_:SetText("");
            self_:ClearFocus();
            placeholder:Show();
            if (dt._searchDebounce) then dt._searchDebounce:Cancel(); dt._searchDebounce = nil; end
            dt._searchQuery = "";
            dt._page = 1;
            dt:Refresh();
        end);

        -- Enter clears focus but keeps filter
        searchBox:SetScript("OnEnterPressed", function(self_)
            self_:ClearFocus();
        end);

        dt._searchBox = searchBox;
    end

    -- Anchor reference: scroll area starts below search (if present) or header
    local scrollAnchor = searchFrame or headerFrame;

    ---------------------------------------------------------------------------
    -- Scroll container for rows
    ---------------------------------------------------------------------------

    local scrollArea = CreateFrame("Frame", frameName .. "_ScrollArea", frame);
    scrollArea:SetPoint("TOPLEFT", scrollAnchor, "BOTTOMLEFT", 0, 0);
    scrollArea:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0);

    local scroll = LanternUX.CreateScrollContainer(scrollArea);
    dt._scroll = scroll;
    dt._scrollArea = scrollArea;

    -- Keep scroll child width in sync
    scrollArea:SetScript("OnSizeChanged", function(_, w)
        if (w and w > 0) then
            scroll.scrollChild:SetWidth(w);
        end
    end);

    ---------------------------------------------------------------------------
    -- "No data" text
    ---------------------------------------------------------------------------

    local noDataText = scroll.scrollChild:CreateFontString(frameName .. "_NoData", "OVERLAY");
    noDataText:SetFontObject(T.fontBody);
    noDataText:SetPoint("TOP", scroll.scrollChild, "TOP", 0, -20);
    noDataText:SetTextColor(unpack(T.textDim));
    noDataText:SetText("");
    noDataText:Hide();
    dt._noDataText = noDataText;

    local noMatchText = scroll.scrollChild:CreateFontString(frameName .. "_NoMatch", "OVERLAY");
    noMatchText:SetFontObject(T.fontBody);
    noMatchText:SetPoint("TOP", scroll.scrollChild, "TOP", 0, -20);
    noMatchText:SetTextColor(unpack(T.textDim));
    noMatchText:SetText("No matches");
    noMatchText:Hide();
    dt._noMatchText = noMatchText;

    ---------------------------------------------------------------------------
    -- Pagination footer
    ---------------------------------------------------------------------------

    local footer, footerPrev, footerNext, footerLabel;

    if (dt._pageSize) then
        local FOOTER_H = 28;

        scrollArea:ClearAllPoints();
        scrollArea:SetPoint("TOPLEFT", scrollAnchor, "BOTTOMLEFT", 0, 0);
        scrollArea:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, FOOTER_H);

        local footerName = NextName("LUX_DT_");
        footer = CreateFrame("Frame", footerName .. "_Footer", frame);
        footer:SetHeight(FOOTER_H);
        footer:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0);
        footer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0);

        local footerBg = footer:CreateTexture(footerName .. "_FooterBg", "BACKGROUND");
        footerBg:SetAllPoints();
        footerBg:SetColorTexture(unpack(T.cardBg));

        local footerBorder = footer:CreateTexture(footerName .. "_FooterBorder", "ARTWORK");
        footerBorder:SetHeight(1);
        footerBorder:SetPoint("TOPLEFT", footer, "TOPLEFT", 0, 0);
        footerBorder:SetPoint("TOPRIGHT", footer, "TOPRIGHT", 0, 0);
        footerBorder:SetColorTexture(unpack(T.cardBorder));

        local prevName = NextName("LUX_DT_");
        footerPrev = CreateFrame("Button", prevName .. "_Prev", footer);
        footerPrev:SetSize(FOOTER_H, FOOTER_H);
        footerPrev:SetPoint("LEFT", footer, "LEFT", 0, 0);

        local prevLabel = footerPrev:CreateFontString(prevName .. "_PrevText", "OVERLAY");
        prevLabel:SetFontObject(T.fontSmallBold);
        prevLabel:SetPoint("CENTER");
        prevLabel:SetText("<");
        prevLabel:SetTextColor(unpack(T.text));
        footerPrev._label = prevLabel;

        local prevHover = footerPrev:CreateTexture(prevName .. "_PrevHL", "HIGHLIGHT");
        prevHover:SetAllPoints();
        prevHover:SetColorTexture(unpack(T.hover));

        footerPrev:SetScript("OnClick", function()
            if (dt._page > 1) then
                dt._page = dt._page - 1;
                dt:Refresh();
            end
        end);

        local nextName = NextName("LUX_DT_");
        footerNext = CreateFrame("Button", nextName .. "_Next", footer);
        footerNext:SetSize(FOOTER_H, FOOTER_H);
        footerNext:SetPoint("RIGHT", footer, "RIGHT", 0, 0);

        local nextLabel = footerNext:CreateFontString(nextName .. "_NextText", "OVERLAY");
        nextLabel:SetFontObject(T.fontSmallBold);
        nextLabel:SetPoint("CENTER");
        nextLabel:SetText(">");
        nextLabel:SetTextColor(unpack(T.text));
        footerNext._label = nextLabel;

        local nextHover = footerNext:CreateTexture(nextName .. "_NextHL", "HIGHLIGHT");
        nextHover:SetAllPoints();
        nextHover:SetColorTexture(unpack(T.hover));

        footerNext:SetScript("OnClick", function()
            if (dt._page < dt._totalPages) then
                dt._page = dt._page + 1;
                dt:Refresh();
            end
        end);

        footerLabel = footer:CreateFontString(footerName .. "_PageLabel", "OVERLAY");
        footerLabel:SetFontObject(T.fontBody);
        footerLabel:SetPoint("CENTER", footer, "CENTER", 0, 0);
        footerLabel:SetTextColor(unpack(T.textDim));
        footerLabel:SetText("");
    end

    ---------------------------------------------------------------------------
    -- Row pool
    ---------------------------------------------------------------------------

    local function ReleaseAllRows()
        for i = 1, dt._activeRows do
            local row = dt._rowPool[i];
            if (row) then row:Hide(); end
        end
        dt._activeRows = 0;
    end
    dt._ReleaseAllRows = ReleaseAllRows;

    local function ReleaseAllChildRows()
        for i = 1, dt._activeChildRows do
            local row = dt._childRowPool[i];
            if (row) then row:Hide(); end
        end
        dt._activeChildRows = 0;
    end
    dt._ReleaseAllChildRows = ReleaseAllChildRows;

    local function AcquireRow(index)
        local row = dt._rowPool[index];
        if (not row) then
            local rowName = NextName("LUX_DT_Row_");
            row = CreateFrame("Frame", rowName, scroll.scrollChild);
            row:SetHeight(dt._rowHeight);
            row:EnableMouse(true);

            -- Alternating background
            local bg = row:CreateTexture(rowName .. "_Bg", "BACKGROUND");
            bg:SetAllPoints();
            row._bg = bg;

            -- Highlight on mouseover
            local highlight = row:CreateTexture(rowName .. "_HL", "HIGHLIGHT");
            highlight:SetAllPoints();
            highlight:SetColorTexture(unpack(T.hover));

            row._cells = {};
            dt._rowPool[index] = row;
        end

        row:SetParent(scroll.scrollChild);
        row:ClearAllPoints();

        -- Alternating stripe
        if (index % 2 == 0) then
            row._bg:SetColorTexture(unpack(T.cardBg));
        else
            row._bg:SetColorTexture(0, 0, 0, 0);
        end

        row:Show();
        dt._activeRows = index;
        return row;
    end

    local function AcquireChildRow(index)
        local row = dt._childRowPool[index];
        if (not row) then
            local rowName = NextName("LUX_DT_ChildRow_");
            row = CreateFrame("Frame", rowName, scroll.scrollChild);
            row:SetHeight(dt._rowHeight);
            row:EnableMouse(true);

            -- Background (inverted stripe: even=transparent, odd=hover color)
            local bg = row:CreateTexture(rowName .. "_Bg", "BACKGROUND");
            bg:SetAllPoints();
            row._bg = bg;

            -- Highlight on mouseover
            local highlight = row:CreateTexture(rowName .. "_HL", "HIGHLIGHT");
            highlight:SetAllPoints();
            highlight:SetColorTexture(unpack(T.hover));

            -- Left accent border
            local borderName = NextName("LUX_DT_ChildBorder_");
            local border = CreateFrame("Frame", borderName, row);
            border:SetWidth(CHILD_BORDER_W);
            border:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0);
            border:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0);
            local borderTex = border:CreateTexture(borderName .. "_Tex", "ARTWORK");
            borderTex:SetAllPoints();
            borderTex:SetColorTexture(unpack(T.accent));
            row._border = border;

            row._cells = {};
            dt._childRowPool[index] = row;
        end

        row:SetParent(scroll.scrollChild);
        row:ClearAllPoints();

        -- Inverted stripe: odd child rows get hover bg, even are transparent
        if (index % 2 == 1) then
            row._bg:SetColorTexture(unpack(T.hover));
        else
            row._bg:SetColorTexture(0, 0, 0, 0);
        end

        row:Show();
        dt._activeChildRows = index;
        return row;
    end

    local function EnsureRowCells(row, columns)
        local cx = CELL_PAD;
        for i, col in ipairs(columns) do
            local cell = row._cells[i];
            if (not cell) then
                local cellName = row:GetName() .. "_C" .. i;
                cell = row:CreateFontString(cellName, "OVERLAY");
                cell:SetFontObject(T.fontBody);
                cell:SetWordWrap(false);
                row._cells[i] = cell;
            end
            cell:ClearAllPoints();
            cell:SetPoint("LEFT", row, "LEFT", cx + 4, 0);
            cell:SetWidth(col.width - CELL_PAD - 4);
            cell:SetJustifyH(col.align or "LEFT");
            cell:SetTextColor(unpack(T.text));
            cell:SetText("");
            cell:Show();
            cx = cx + col.width;
        end

        -- Hide excess cells
        for i = #columns + 1, #row._cells do
            row._cells[i]:Hide();
        end
    end

    local function EnsureChildRowCells(row, columns)
        -- First column is indented by CHILD_INDENT extra pixels
        local cx = CELL_PAD + CHILD_INDENT;
        for i, col in ipairs(columns) do
            local cell = row._cells[i];
            if (not cell) then
                local cellName = row:GetName() .. "_C" .. i;
                cell = row:CreateFontString(cellName, "OVERLAY");
                cell:SetFontObject(T.fontBody);
                cell:SetWordWrap(false);
                row._cells[i] = cell;
            end
            cell:ClearAllPoints();
            cell:SetPoint("LEFT", row, "LEFT", cx + 4, 0);
            -- First column loses width equal to the extra indent
            if (i == 1) then
                cell:SetWidth(col.width - CELL_PAD - 4 - CHILD_INDENT);
            else
                cell:SetWidth(col.width - CELL_PAD - 4);
            end
            cell:SetJustifyH(col.align or "LEFT");
            cell:SetTextColor(unpack(T.text));
            cell:SetText("");
            cell:Show();
            -- Only first column is indented; subsequent columns start at their normal x
            if (i == 1) then
                cx = CELL_PAD + col.width;
            else
                cx = cx + col.width;
            end
        end

        -- Hide excess cells
        for i = #columns + 1, #row._cells do
            row._cells[i]:Hide();
        end
    end

    ---------------------------------------------------------------------------
    -- Sort logic
    ---------------------------------------------------------------------------

    local function SortData(data, key, ascending)
        if (not key) then return; end
        table.sort(data, function(a, b)
            local va = a[key];
            local vb = b[key];
            if (va == nil and vb == nil) then return false; end
            if (va == nil) then return ascending; end
            if (vb == nil) then return not ascending; end

            local ta = type(va);
            local tb = type(vb);

            if (ta ~= tb) then
                if (ta == "number") then return ascending; end
                if (tb == "number") then return not ascending; end
                if (ascending) then return ta < tb; end
                return ta > tb;
            end

            if (ta == "string") then
                if (ascending) then return va:lower() < vb:lower(); end
                return va:lower() > vb:lower();
            end

            if (ascending) then return va < vb; end
            return va > vb;
        end);
    end

    ---------------------------------------------------------------------------
    -- Update sort arrow indicators
    ---------------------------------------------------------------------------

    local function UpdateSortArrows()
        for i, btn in ipairs(dt._headerButtons) do
            local col = dt._columns[i];
            if (col and col.key == dt._sortKey) then
                btn._arrow:SetText(dt._sortAsc and SORT_ARROW_UP or SORT_ARROW_DOWN);
                btn._label:SetTextColor(unpack(T.textBright));
                btn._arrow:SetTextColor(unpack(T.accent));
            else
                btn._arrow:SetText("");
                btn._label:SetTextColor(unpack(T.textDim));
            end
        end
    end

    ---------------------------------------------------------------------------
    -- Search filter
    ---------------------------------------------------------------------------

    local function FilterData(data, query, columns)
        if (not query or query == "" or not columns) then return data; end
        local q = query:lower();
        local filtered = {};
        for _, entry in ipairs(data) do
            for _, key in ipairs(columns) do
                local val = entry[key];
                -- Note: only matches string values. Numeric/formatted columns are not searchable.
                if (val and type(val) == "string" and val:lower():find(q, 1, true)) then
                    filtered[#filtered + 1] = entry;
                    break;
                end
            end
        end
        return filtered;
    end

    ---------------------------------------------------------------------------
    -- Public methods
    ---------------------------------------------------------------------------

    function dt:SetData(data)
        self._data = data or {};
    end

    function dt:SetSortKey(key, ascending)
        self._sortKey = key;
        self._sortAsc = ascending;
    end

    function dt:SetNoDataText(text)
        self._noDataText:SetText(text or "");
    end

    function dt:SetPage(n)
        self._page = n or 1;
        self:Refresh();
    end

    function dt:GetPage()
        return self._page;
    end

    function dt:GetTotalPages()
        return self._totalPages;
    end

    function dt:SetPageSize(n)
        self._pageSize = n;
        self._page = 1;
        self:Refresh();
    end

    function dt:SetSearchQuery(text)
        self._searchQuery = text or "";
        self._page = 1;
        if (self._searchBox) then
            self._searchBox:SetText(text or "");
        end
        self:Refresh();
    end

    function dt:GetSearchQuery()
        return self._searchQuery;
    end

    function dt:Refresh(preserveScroll)
        ReleaseAllRows();
        ReleaseAllChildRows();
        self._noDataText:Hide();
        self._noMatchText:Hide();

        -- Sort a copy so we don't mutate the caller's table
        local sorted = {};
        for i, v in ipairs(self._data) do
            sorted[i] = v;
        end

        -- Apply search filter
        if (self._searchQuery ~= "" and self._searchColumns) then
            sorted = FilterData(sorted, self._searchQuery, self._searchColumns);
        end

        if (self._sortKey) then
            SortData(sorted, self._sortKey, self._sortAsc);
        end

        UpdateSortArrows();

        if (#sorted == 0) then
            if (self._searchQuery ~= "" and self._searchColumns and #self._data > 0) then
                self._noMatchText:Show();
            else
                self._noDataText:Show();
            end
            self._scroll:SetContentHeight(60);
            if (footerLabel) then
                footerLabel:SetText("");
                footerPrev:Disable();
                footerNext:Disable();
                footerPrev._label:SetTextColor(unpack(T.textDim));
                footerNext._label:SetTextColor(unpack(T.textDim));
            end
            return;
        end

        -- Validate that the currently expanded key still exists in sorted data
        if (self._expandedKey and self._expandKey) then
            local found = false;
            for _, entry in ipairs(sorted) do
                if (entry[self._expandKey] == self._expandedKey) then
                    found = true;
                    break;
                end
            end
            if (not found) then
                self._expandedKey = nil;
            end
        end

        local startIdx = 1;
        local endIdx = #sorted;
        if (self._pageSize and self._pageSize > 0) then
            self._totalPages = math.ceil(#sorted / self._pageSize);
            if (self._page > self._totalPages) then self._page = self._totalPages; end
            if (self._page < 1) then self._page = 1; end
            startIdx = (self._page - 1) * self._pageSize + 1;
            endIdx = math.min(self._page * self._pageSize, #sorted);
        else
            self._totalPages = 1;
        end

        local rowH = self._rowHeight;
        local rowIndex = 0;
        local childIndex = 0;
        -- Cumulative Y offset in pixels (grows downward, stored as positive)
        local yOffset = 0;

        local isExpandable = self._getChildren and self._expandKey and self._childColumns;

        for i = startIdx, endIdx do
            local entry = sorted[i];
            rowIndex = rowIndex + 1;
            local row = AcquireRow(rowIndex);
            row:SetPoint("TOPLEFT", scroll.scrollChild, "TOPLEFT", 0, -yOffset);
            row:SetPoint("TOPRIGHT", scroll.scrollChild, "TOPRIGHT", 0, -yOffset);
            EnsureRowCells(row, self._columns);

            local entryKey = isExpandable and entry[self._expandKey] or nil;
            local isExpanded = entryKey and (entryKey == self._expandedKey);

            for j, col in ipairs(self._columns) do
                local value = entry[col.key];
                local displayText;

                if (col.format) then
                    displayText = col.format(value, entry);
                else
                    displayText = tostring(value or "");
                end

                -- Prepend chevron to first cell when row is expandable
                if (isExpandable and j == 1) then
                    local chevron = isExpanded and CHEVRON_EXPANDED or CHEVRON_COLLAPSED;
                    displayText = chevron .. displayText;
                end

                row._cells[j]:SetText(displayText);

                if (col.isLink and value and type(value) == "string" and value:find("|c")) then
                    row._cells[j]:SetTextColor(1, 1, 1, 1);
                end
            end

            -- Row click handler
            if (isExpandable) then
                local rowData = entry;
                local rowEntryKey = entryKey;
                row:SetScript("OnMouseUp", function(_, button)
                    if (button == "LeftButton") then
                        -- Toggle expand/collapse
                        if (self._expandedKey == rowEntryKey) then
                            self._expandedKey = nil;
                        else
                            self._expandedKey = rowEntryKey;
                        end
                        self:Refresh(true);
                        -- Also fire onRowClick if configured
                        if (self._onRowClick) then
                            self._onRowClick(rowData);
                        end
                    end
                end);
            elseif (self._onRowClick) then
                local rowData = entry;
                row:SetScript("OnMouseUp", function(_, button)
                    if (button == "LeftButton") then
                        self._onRowClick(rowData);
                    end
                end);
            else
                row:SetScript("OnMouseUp", nil);
            end

            if (self._rowTooltip) then
                local rowData = entry;
                row:SetScript("OnEnter", function(self_row)
                    GameTooltip:SetOwner(self_row, "ANCHOR_RIGHT");
                    dt._rowTooltip(rowData, GameTooltip);
                    GameTooltip:Show();
                end);
                row:SetScript("OnLeave", function()
                    GameTooltip:Hide();
                end);
            else
                row:SetScript("OnEnter", nil);
                row:SetScript("OnLeave", nil);
            end

            yOffset = yOffset + rowH;

            -- Render child rows if this parent is expanded
            if (isExpandable and isExpanded) then
                local children = self._getChildren(entry);
                if (children and #children > 0) then
                    for ci, childEntry in ipairs(children) do
                        childIndex = childIndex + 1;
                        local childRow = AcquireChildRow(childIndex);
                        childRow:SetPoint("TOPLEFT", scroll.scrollChild, "TOPLEFT", 0, -yOffset);
                        childRow:SetPoint("TOPRIGHT", scroll.scrollChild, "TOPRIGHT", 0, -yOffset);
                        EnsureChildRowCells(childRow, self._childColumns);

                        for j, col in ipairs(self._childColumns) do
                            local value = childEntry[col.key];
                            local displayText;

                            if (col.format) then
                                displayText = col.format(value, childEntry);
                            else
                                displayText = tostring(value or "");
                            end

                            childRow._cells[j]:SetText(displayText);

                            if (col.isLink and value and type(value) == "string" and value:find("|c")) then
                                childRow._cells[j]:SetTextColor(1, 1, 1, 1);
                            end
                        end

                        -- Child rows do not expand; no OnMouseUp unless childRowTooltip needs it
                        childRow:SetScript("OnMouseUp", nil);

                        if (self._childRowTooltip) then
                            local childData = childEntry;
                            childRow:SetScript("OnEnter", function(self_row)
                                GameTooltip:SetOwner(self_row, "ANCHOR_RIGHT");
                                dt._childRowTooltip(childData, GameTooltip);
                                GameTooltip:Show();
                            end);
                            childRow:SetScript("OnLeave", function()
                                GameTooltip:Hide();
                            end);
                        else
                            childRow:SetScript("OnEnter", nil);
                            childRow:SetScript("OnLeave", nil);
                        end

                        yOffset = yOffset + rowH;
                    end
                end
            end
        end

        local totalHeight = yOffset + 8;
        if (preserveScroll) then
            self._scroll:UpdateContentHeight(totalHeight);
        else
            self._scroll:SetContentHeight(totalHeight);
        end

        if (footerLabel) then
            footerLabel:SetText("Page " .. self._page .. " / " .. self._totalPages);
            local canPrev = self._page > 1;
            local canNext = self._page < self._totalPages;
            if (canPrev) then
                footerPrev:Enable();
                footerPrev._label:SetTextColor(unpack(T.text));
            else
                footerPrev:Disable();
                footerPrev._label:SetTextColor(unpack(T.textDim));
            end
            if (canNext) then
                footerNext:Enable();
                footerNext._label:SetTextColor(unpack(T.text));
            else
                footerNext:Disable();
                footerNext._label:SetTextColor(unpack(T.textDim));
            end
        end
    end

    return dt;
end
