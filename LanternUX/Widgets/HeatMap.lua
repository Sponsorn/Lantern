local ADDON_NAME = ...;
local _W = LanternUX._W;
local T = _W.T;
local AcquireWidget = _W.AcquireWidget;
local RegisterWidget = _W.RegisterWidget;
local NextName = _W.NextName;
local ShowDescription = _W.ShowDescription;
local ClearDescription = _W.ClearDescription;

local COLS = 7;
local ROWS = 24;
local CELL_H = 16;
local CELL_GAP = 1;
local ROW_LABEL_W = 60;
local COL_HEADER_H = 20;
local MIN_CELL_W = 36;
local GRID_H = COL_HEADER_H + ROWS * (CELL_H + CELL_GAP);

-- Day key (date("!%w")) to Monday-first column index
local DAY_TO_COL_MON = { [1] = 1, [2] = 2, [3] = 3, [4] = 4, [5] = 5, [6] = 6, [0] = 7 };
-- Day key to Sunday-first column index
local DAY_TO_COL_SUN = { [0] = 1, [1] = 2, [2] = 3, [3] = 4, [4] = 5, [5] = 6, [6] = 7 };

-- Column index to day key (inverse maps)
local COL_TO_DAY_MON = { 1, 2, 3, 4, 5, 6, 0 };
local COL_TO_DAY_SUN = { 0, 1, 2, 3, 4, 5, 6 };

local function LerpColor(bg, fg, t)
    t = math.max(0, math.min(1, t));
    return
        bg[1] + (fg[1] - bg[1]) * t,
        bg[2] + (fg[2] - bg[2]) * t,
        bg[3] + (fg[3] - bg[3]) * t;
end

local function GetDayAbbrev(dayKey)
    -- dayKey: 0=Sun..6=Sat. Use date("%a") with a known epoch offset.
    -- Jan 4 1970 was a Sunday (dayKey=0). Add dayKey days.
    return date("%a", 345600 + dayKey * 86400);
end

local function FormatHour(hour, use12h)
    if (use12h) then
        if (hour == 0) then return "12 AM"; end
        if (hour < 12) then return hour .. " AM"; end
        if (hour == 12) then return "12 PM"; end
        return (hour - 12) .. " PM";
    end
    return string.format("%02d:00", hour);
end

-------------------------------------------------------------------------------
-- Create / Setup
-------------------------------------------------------------------------------

local function CreateHeatMap(parent)
    local w = AcquireWidget("heatmap", parent);
    if (w) then return w; end

    w = {};
    local frame = CreateFrame("Frame", NextName("LUX_HeatMap_"), parent);
    frame:SetHeight(GRID_H);
    w.frame = frame;

    -- Column headers (7 day labels)
    w._colHeaders = {};
    for col = 1, COLS do
        local fs = frame:CreateFontString(NextName("LUX_HM_ColH_"), "OVERLAY");
        fs:SetFontObject(T.fontSmall);
        fs:SetJustifyH("CENTER");
        fs:SetTextColor(unpack(T.textDim));
        w._colHeaders[col] = fs;
    end

    -- Row labels (24 hour labels)
    w._rowLabels = {};
    for row = 1, ROWS do
        local fs = frame:CreateFontString(NextName("LUX_HM_RowL_"), "OVERLAY");
        fs:SetFontObject(T.fontSmall);
        fs:SetJustifyH("RIGHT");
        fs:SetTextColor(unpack(T.textDim));
        w._rowLabels[row] = fs;
    end

    -- Cells (7x24 textures + tooltip buttons)
    w._cells = {};      -- [col][row] = texture
    w._buttons = {};    -- [col][row] = button
    w._cellData = {};   -- [col][row] = { day, hour, value } for tooltips

    for col = 1, COLS do
        w._cells[col] = {};
        w._buttons[col] = {};
        w._cellData[col] = {};
        for row = 1, ROWS do
            local tex = frame:CreateTexture(NextName("LUX_HM_Cell_"), "ARTWORK");
            tex:SetHeight(CELL_H);
            w._cells[col][row] = tex;

            local btn = CreateFrame("Button", NextName("LUX_HM_Btn_"), frame);
            btn:SetHeight(CELL_H);
            btn:SetAllPoints(tex);
            w._buttons[col][row] = btn;
            w._cellData[col][row] = { day = 0, hour = 0, value = 0 };

            btn:SetScript("OnEnter", function(self)
                local cd = w._cellData[col][row];
                if (w._tooltipFn) then
                    local text = w._tooltipFn(cd.day, cd.hour, cd.value);
                    if (text) then
                        GameTooltip:SetOwner(self, "ANCHOR_CURSOR");
                        GameTooltip:AddLine(text, 1, 1, 1, true);
                        GameTooltip:Show();
                    end
                end
            end);
            btn:SetScript("OnLeave", function()
                GameTooltip:Hide();
            end);
        end
    end

    -- Layout function (called on width change)
    w._layoutCells = function()
        local totalW = w.frame:GetWidth();
        if (not totalW or totalW <= 0) then return; end
        local cellW = math.max(MIN_CELL_W, math.floor((totalW - ROW_LABEL_W - (COLS - 1) * CELL_GAP) / COLS));

        -- Position column headers
        for col = 1, COLS do
            local h = w._colHeaders[col];
            h:ClearAllPoints();
            h:SetPoint("BOTTOM", w.frame, "TOPLEFT",
                ROW_LABEL_W + (col - 1) * (cellW + CELL_GAP) + cellW / 2,
                -COL_HEADER_H);
            h:SetWidth(cellW);
        end

        -- Position row labels and cells
        for row = 1, ROWS do
            local yOff = -COL_HEADER_H - (row - 1) * (CELL_H + CELL_GAP);

            w._rowLabels[row]:ClearAllPoints();
            w._rowLabels[row]:SetPoint("TOPRIGHT", w.frame, "TOPLEFT", ROW_LABEL_W - 4, yOff);
            w._rowLabels[row]:SetWidth(ROW_LABEL_W - 8);

            for col = 1, COLS do
                local xOff = ROW_LABEL_W + (col - 1) * (cellW + CELL_GAP);
                w._cells[col][row]:ClearAllPoints();
                w._cells[col][row]:SetPoint("TOPLEFT", w.frame, "TOPLEFT", xOff, yOff);
                w._cells[col][row]:SetWidth(cellW);
            end
        end
    end;

    frame:SetScript("OnSizeChanged", function()
        w._layoutCells();
    end);

    RegisterWidget("heatmap", w);
    return w;
end

local function SetupHeatMap(w, parent, data, contentWidth)
    w.frame:SetParent(parent);
    if (contentWidth) then
        w.frame:SetWidth(contentWidth);
    end
    w.frame:SetHeight(GRID_H);
    w.height = GRID_H;

    w._desc_text = data.desc;
    w._tooltipFn = data.tooltipFn;

    -- Determine settings
    local mondayFirst = (data.mondayFirst ~= false); -- default true
    local use12h;
    if (data.use12h ~= nil) then
        use12h = data.use12h;
    else
        use12h = not GetCVarBool("timeMgrUseMilitaryTime");
    end
    local accentColor = data.color or T.accent;
    local bgColor = T.checkInner; -- {0.10, 0.10, 0.12} solid dark, not T.cardBg (translucent white)

    -- Column order mapping
    local colToDay = mondayFirst and COL_TO_DAY_MON or COL_TO_DAY_SUN;

    -- Set column headers
    for col = 1, COLS do
        w._colHeaders[col]:SetText(GetDayAbbrev(colToDay[col]));
    end

    -- Set row labels
    for row = 1, ROWS do
        w._rowLabels[row]:SetText(FormatHour(row - 1, use12h));
    end

    -- Compute maxVal if not provided
    local gridData = data.data or {};
    local maxVal = data.maxVal;
    if (not maxVal or maxVal <= 0) then
        maxVal = 0;
        for day = 0, 6 do
            local dayData = gridData[day];
            if (dayData) then
                for hour = 0, 23 do
                    local v = dayData[hour] or 0;
                    if (v > maxVal) then maxVal = v; end
                end
            end
        end
    end
    if (maxVal <= 0) then maxVal = 1; end -- avoid div by zero

    -- Apply cell colors and store cell data
    local dayToCol = mondayFirst and DAY_TO_COL_MON or DAY_TO_COL_SUN;

    for day = 0, 6 do
        local col = dayToCol[day];
        local dayData = gridData[day];
        for hour = 0, 23 do
            local row = hour + 1;
            local value = (dayData and dayData[hour]) or 0;
            local t = value / maxVal;
            local r, g, b = LerpColor(bgColor, accentColor, t);
            w._cells[col][row]:SetColorTexture(r, g, b, 1);
            w._cellData[col][row].day = day;
            w._cellData[col][row].hour = hour;
            w._cellData[col][row].value = value;
        end
    end

    -- Store data references for refresher
    w._gridData = gridData;
    w._maxVal = maxVal;
    w._accentColor = accentColor;
    w._bgColor = bgColor;
    w._dayToCol = dayToCol;

    -- Layout cells
    w._layoutCells();

    return w;
end

-------------------------------------------------------------------------------
-- Register
-------------------------------------------------------------------------------

_W.factories.heatmap = { create = CreateHeatMap, setup = SetupHeatMap };

_W.refreshers.heatmap = function(w)
    -- Re-apply cell colors from stored data (called after data changes)
    if (not w._gridData or not w._dayToCol) then return; end
    local maxVal = w._maxVal or 1;
    for day = 0, 6 do
        local col = w._dayToCol[day];
        local dayData = w._gridData[day];
        for hour = 0, 23 do
            local row = hour + 1;
            local value = (dayData and dayData[hour]) or 0;
            local t = value / maxVal;
            local r, g, b = LerpColor(w._bgColor, w._accentColor, t);
            w._cells[col][row]:SetColorTexture(r, g, b, 1);
            w._cellData[col][row].value = value;
        end
    end
end
