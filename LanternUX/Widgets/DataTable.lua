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
    dt._columns     = config.columns or {};
    dt._rowHeight   = config.rowHeight or DEFAULT_ROW_HEIGHT;
    dt._onRowClick  = config.onRowClick;
    dt._data        = {};
    dt._sortKey     = config.defaultSort and config.defaultSort.key or nil;
    dt._sortAsc     = config.defaultSort and config.defaultSort.ascending or false;
    dt._rowPool     = {};
    dt._activeRows  = 0;

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

        local label = btn:CreateFontString(btnName .. "_Text", "OVERLAY");
        label:SetFontObject(T.fontSmallBold);
        label:SetPoint("LEFT", btn, "LEFT", 0, 0);
        label:SetPoint("RIGHT", btn, "RIGHT", -4, 0);
        label:SetJustifyH(col.align or "LEFT");
        label:SetText(col.label or "");
        label:SetTextColor(unpack(T.textDim));
        btn._label = label;

        local arrow = btn:CreateFontString(btnName .. "_Arrow", "OVERLAY");
        arrow:SetFontObject(T.fontSmallBold);
        if (col.align == "RIGHT") then
            arrow:SetPoint("RIGHT", label, "LEFT", -1, 0);
        else
            arrow:SetPoint("LEFT", label, "RIGHT", 1, 0);
        end
        arrow:SetText("");
        arrow:SetTextColor(unpack(T.accent));
        btn._arrow = arrow;

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
    -- Scroll container for rows
    ---------------------------------------------------------------------------

    local scrollArea = CreateFrame("Frame", frameName .. "_ScrollArea", frame);
    scrollArea:SetPoint("TOPLEFT", headerFrame, "BOTTOMLEFT", 0, 0);
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
            cell:SetPoint("LEFT", row, "LEFT", cx, 0);
            cell:SetWidth(col.width - CELL_PAD);
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

    function dt:Refresh()
        ReleaseAllRows();
        self._noDataText:Hide();

        -- Sort a copy so we don't mutate the caller's table
        local sorted = {};
        for i, v in ipairs(self._data) do
            sorted[i] = v;
        end

        if (self._sortKey) then
            SortData(sorted, self._sortKey, self._sortAsc);
        end

        UpdateSortArrows();

        if (#sorted == 0) then
            self._noDataText:Show();
            self._scroll:SetContentHeight(60);
            return;
        end

        local rowH = self._rowHeight;
        for i, entry in ipairs(sorted) do
            local row = AcquireRow(i);
            row:SetPoint("TOPLEFT", scroll.scrollChild, "TOPLEFT", 0, -((i - 1) * rowH));
            row:SetPoint("TOPRIGHT", scroll.scrollChild, "TOPRIGHT", 0, -((i - 1) * rowH));
            EnsureRowCells(row, self._columns);

            for j, col in ipairs(self._columns) do
                local value = entry[col.key];
                local displayText;

                if (col.format) then
                    displayText = col.format(value, entry);
                else
                    displayText = tostring(value or "");
                end

                row._cells[j]:SetText(displayText);

                -- Special coloring for item links (already have color codes)
                if (col.isLink and value and type(value) == "string" and value:find("|c")) then
                    row._cells[j]:SetTextColor(1, 1, 1, 1);
                end
            end

            -- Row click handler
            if (self._onRowClick) then
                local rowData = entry;
                row:SetScript("OnMouseUp", function(_, button)
                    if (button == "LeftButton") then
                        self._onRowClick(rowData);
                    end
                end);
            else
                row:SetScript("OnMouseUp", nil);
            end
        end

        local totalHeight = #sorted * rowH + 8;
        self._scroll:SetContentHeight(totalHeight);
    end

    return dt;
end
