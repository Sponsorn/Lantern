local ADDON_NAME = ...;
local _W = LanternUX._W;
local T = _W.T;
local AcquireWidget = _W.AcquireWidget;
local RegisterWidget = _W.RegisterWidget;
local NextName = _W.NextName;

local DEFAULT_HEIGHT = 120;
local DEFAULT_BAR_GAP = 2;
local DEFAULT_DIM_ALPHA = 0.6;
local LABEL_H = 16;
local MIN_BAR_W = 8;
local MAX_BARS = 60;
local Y_AXIS_WIDTH = 40;
local GRID_LINE_COUNT = 3; -- number of horizontal grid lines (excluding baseline)
local GRID_LINE_ALPHA = 0.15;

-------------------------------------------------------------------------------
-- Nice number rounding for y-axis values
-------------------------------------------------------------------------------

-- Find the smallest nice step so that step * GRID_LINE_COUNT >= maxVal.
-- Produces steps like 100, 200, 250, 500, 1000, ...
local NICE_STEPS = { 1, 1.5, 2, 2.5, 3, 5, 10 };
local function NiceStep(maxVal, lines)
    if (maxVal <= 0) then return 1; end
    local rough = maxVal / lines;
    local exp = math.floor(math.log10(rough));
    local base = 10 ^ exp;
    for _, m in ipairs(NICE_STEPS) do
        local step = m * base;
        if (step * lines >= maxVal) then
            return step;
        end
    end
    return 10 * base;
end

-------------------------------------------------------------------------------
-- Widget
-------------------------------------------------------------------------------

local function CreateBarChart(parent)
    local w = AcquireWidget("barchart", parent);
    if (w) then return w; end

    w = {};
    local frame = CreateFrame("Frame", NextName("LUX_BC_"), parent);
    w.frame = frame;

    -- Pools (populated on demand during setup/refresh)
    w._bars = {};      -- [i] = texture
    w._labels = {};    -- [i] = fontstring
    w._buttons = {};   -- [i] = button (tooltip hitbox)
    w._barData = {};   -- [i] = { label, value, ... } for tooltips
    w._barCount = 0;

    -- Grid line pools
    w._gridLines = {};  -- [i] = texture
    w._gridLabels = {}; -- [i] = fontstring

    -- Empty text
    local emptyText = frame:CreateFontString(NextName("LUX_BC_Empty_"), "OVERLAY");
    emptyText:SetFontObject(T.fontBody);
    emptyText:SetPoint("CENTER", frame, "CENTER", 0, 0);
    emptyText:SetTextColor(unpack(T.textDim));
    emptyText:SetText("");
    emptyText:Hide();
    w._emptyText = emptyText;

    -- Layout function
    w._layoutBars = function()
        if (w._isEmpty) then return; end
        local totalW = w.frame:GetWidth();
        if (not totalW or totalW <= 0) then return; end
        local barCount = w._barCount;
        if (barCount == 0) then return; end

        local gap = w._barGap or DEFAULT_BAR_GAP;
        local chartH = w._chartHeight or DEFAULT_HEIGHT;
        local maxVal = w._maxVal or 1;
        local dimAlpha = w._dimAlpha or DEFAULT_DIM_ALPHA;
        local highlightLast = w._highlightLast;
        local yLabelFn = w._yLabelFn;
        local leftMargin = yLabelFn and Y_AXIS_WIDTH or 0;
        local barAreaW = totalW - leftMargin;
        local barW = math.max(MIN_BAR_W, math.floor((barAreaW - (barCount - 1) * gap) / barCount));

        -- Grid lines and y-axis labels
        -- Always 3 lines at nice round values that cover maxVal
        local lineCount = 0;
        local drawMax = maxVal;
        local niceStep = 0;
        if (yLabelFn and maxVal > 0) then
            niceStep = NiceStep(maxVal, GRID_LINE_COUNT);
            lineCount = GRID_LINE_COUNT;
            drawMax = niceStep * lineCount;
        end

        for i = 1, lineCount do
            local lineVal = niceStep * i;
            local yFrac = (drawMax > 0) and (lineVal / drawMax) or 0;
            local yPos = LABEL_H + math.floor(yFrac * chartH);

            -- Grid line texture
            if (not w._gridLines[i]) then
                local line = w.frame:CreateTexture(NextName("LUX_BC_Grid_"), "BACKGROUND");
                w._gridLines[i] = line;
            end
            local line = w._gridLines[i];
            line:ClearAllPoints();
            line:SetPoint("LEFT", w.frame, "BOTTOMLEFT", leftMargin, yPos);
            line:SetPoint("RIGHT", w.frame, "BOTTOMRIGHT", 0, yPos);
            line:SetHeight(1);
            local dc = T.divider or { 1, 1, 1 };
            line:SetColorTexture(dc[1], dc[2], dc[3], GRID_LINE_ALPHA);
            line:Show();

            -- Y-axis label
            if (not w._gridLabels[i]) then
                local lbl = w.frame:CreateFontString(NextName("LUX_BC_YLbl_"), "OVERLAY");
                lbl:SetFontObject(T.fontSmall);
                lbl:SetJustifyH("RIGHT");
                lbl:SetTextColor(unpack(T.textDim));
                w._gridLabels[i] = lbl;
            end
            local lbl = w._gridLabels[i];
            lbl:ClearAllPoints();
            lbl:SetPoint("RIGHT", w.frame, "BOTTOMLEFT", leftMargin - 4, yPos);
            lbl:SetWidth(leftMargin - 6);
            lbl:SetText(yLabelFn(lineVal));
            lbl:Show();
        end

        -- Hide excess grid elements
        for i = lineCount + 1, #w._gridLines do
            w._gridLines[i]:Hide();
        end
        for i = lineCount + 1, #w._gridLabels do
            w._gridLabels[i]:Hide();
        end

        -- Layout bars
        for i = 1, barCount do
            local data = w._barData[i];
            local value = data and data.value or 0;
            local barH = (drawMax > 0) and math.floor((value / drawMax) * chartH) or 0;
            local xOff = leftMargin + (i - 1) * (barW + gap);

            -- Bar texture
            local bar = w._bars[i];
            bar:ClearAllPoints();
            bar:SetPoint("BOTTOMLEFT", w.frame, "BOTTOMLEFT", xOff, LABEL_H);
            bar:SetSize(barW, math.max(barH, 0));
            local alpha = (highlightLast and i == barCount) and 1.0 or dimAlpha;
            local c = w._color or T.accent;
            bar:SetColorTexture(c[1], c[2], c[3], alpha);
            bar:Show();

            -- Tooltip button
            local btn = w._buttons[i];
            btn:ClearAllPoints();
            btn:SetPoint("BOTTOMLEFT", w.frame, "BOTTOMLEFT", xOff, LABEL_H);
            btn:SetSize(barW, chartH);
            btn:Show();

            -- X-axis label
            local lbl = w._labels[i];
            lbl:ClearAllPoints();
            lbl:SetPoint("TOP", bar, "BOTTOM", 0, -1);
            lbl:SetWidth(barW);
            lbl:SetText(data and data.label or "");
            lbl:Show();
        end
    end;

    frame:SetScript("OnSizeChanged", function()
        w._layoutBars();
    end);

    RegisterWidget("barchart", w);
    return w;
end

local function SetupBarChart(w, parent, data, contentWidth)
    w.frame:SetParent(parent);
    if (contentWidth) then
        w.frame:SetWidth(contentWidth);
    end

    local chartH = data.height or DEFAULT_HEIGHT;
    local totalH = chartH + LABEL_H;
    w.frame:SetHeight(totalH);
    w.height = totalH;

    w._tooltipFn = data.tooltipFn;
    w._yLabelFn = data.yLabelFn;
    w._color = data.color or T.accent;
    w._barGap = data.barGap or DEFAULT_BAR_GAP;
    w._chartHeight = chartH;
    w._dimAlpha = data.dimAlpha or DEFAULT_DIM_ALPHA;
    w._highlightLast = (data.highlightLast ~= false); -- default true
    w._emptyText:SetText(data.emptyText or "");

    -- Process bars
    local bars = data.bars or {};
    local barCount = math.min(#bars, MAX_BARS);

    -- If too many bars, truncate oldest (start of array)
    local startIdx = #bars - barCount + 1;

    -- Compute maxVal from visible bars
    local maxVal = data.maxVal;
    if (not maxVal or maxVal <= 0) then
        maxVal = 0;
        for i = startIdx, #bars do
            local v = bars[i].value or 0;
            if (v > maxVal) then maxVal = v; end
        end
    end
    if (maxVal <= 0) then maxVal = 1; end
    w._maxVal = maxVal;

    -- Ensure pools are large enough
    local visibleIdx = 0;
    for i = startIdx, #bars do
        visibleIdx = visibleIdx + 1;
        local barEntry = bars[i];

        -- Ensure bar texture
        if (not w._bars[visibleIdx]) then
            w._bars[visibleIdx] = w.frame:CreateTexture(NextName("LUX_BC_Bar_"), "ARTWORK");
        end

        -- Ensure tooltip button
        if (not w._buttons[visibleIdx]) then
            local btn = CreateFrame("Button", NextName("LUX_BC_Btn_"), w.frame);
            w._buttons[visibleIdx] = btn;
            local idx = visibleIdx;
            btn:SetScript("OnEnter", function(self)
                if (w._tooltipFn) then
                    local d = w._barData[idx];
                    if (d) then
                        local text = w._tooltipFn(d);
                        if (text) then
                            GameTooltip:SetOwner(self, "ANCHOR_CURSOR");
                            GameTooltip:AddLine(text, 1, 1, 1, true);
                            GameTooltip:Show();
                        end
                    end
                end
            end);
            btn:SetScript("OnLeave", function()
                GameTooltip:Hide();
            end);
        end

        -- Ensure label
        if (not w._labels[visibleIdx]) then
            local lbl = w.frame:CreateFontString(NextName("LUX_BC_Lbl_"), "OVERLAY");
            lbl:SetFontObject(T.fontSmall);
            lbl:SetJustifyH("CENTER");
            lbl:SetTextColor(unpack(T.textDim));
            w._labels[visibleIdx] = lbl;
        end

        w._barData[visibleIdx] = barEntry;
    end

    w._barCount = visibleIdx;

    -- Hide excess pool items
    for i = visibleIdx + 1, #w._bars do
        w._bars[i]:Hide();
    end
    for i = visibleIdx + 1, #w._buttons do
        w._buttons[i]:Hide();
    end
    for i = visibleIdx + 1, #w._labels do
        w._labels[i]:Hide();
    end

    -- Show empty text or bars
    local hasData = false;
    for i = 1, visibleIdx do
        if ((w._barData[i].value or 0) > 0) then hasData = true; break; end
    end
    w._isEmpty = not hasData;
    if (not hasData) then
        w._emptyText:Show();
        for i = 1, visibleIdx do
            w._bars[i]:Hide();
            w._labels[i]:Hide();
            w._buttons[i]:Hide();
        end
        -- Hide grid lines when empty
        for i = 1, #w._gridLines do w._gridLines[i]:Hide(); end
        for i = 1, #w._gridLabels do w._gridLabels[i]:Hide(); end
    else
        w._emptyText:Hide();
        w._layoutBars();
    end

    return w;
end

_W.factories.barchart = { create = CreateBarChart, setup = SetupBarChart };

_W.refreshers.barchart = function(w)
    if (not w._barData or w._barCount == 0) then return; end
    w._layoutBars();
end
