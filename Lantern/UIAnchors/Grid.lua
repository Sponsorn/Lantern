local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local module = Lantern.modules["UIAnchors"];
if (not module) then return; end

local T = Lantern.UX and Lantern.UX.Theme;

local LINE_COLOR     = { 1, 1, 1, 0.08 };
local CENTER_COLOR   = { 1, 1, 1, 1.0 };
local GRID_SPACING   = 20; -- pixels between grid lines

local gridFrame;

local function createGrid()
    local f = CreateFrame("Frame", "LanternAnchorsGrid", UIParent);
    f:SetAllPoints(UIParent);
    f:SetFrameStrata("BACKGROUND");
    f:SetFrameLevel(0);
    f.lines = {};

    local function rebuild()
        -- Hide existing lines
        for _, line in ipairs(f.lines) do
            line:Hide();
        end

        local sw, sh = GetPhysicalScreenSize();
        local scale = UIParent:GetEffectiveScale();
        local w = sw / scale;
        local h = sh / scale;
        local cx = w / 2;
        local cy = h / 2;

        local idx = 0;

        local function getLine()
            idx = idx + 1;
            local line = f.lines[idx];
            if (not line) then
                line = f:CreateLine(nil, "BACKGROUND");
                f.lines[idx] = line;
            end
            line:Show();
            return line;
        end

        -- Center crosshair (brighter)
        local vCenter = getLine();
        vCenter:SetThickness(1);
        vCenter:SetColorTexture(CENTER_COLOR[1], CENTER_COLOR[2], CENTER_COLOR[3], CENTER_COLOR[4]);
        vCenter:SetStartPoint("BOTTOM", f, -(cx - cx), 0);
        vCenter:SetEndPoint("TOP", f, -(cx - cx), 0);
        -- Use CENTER anchor for vertical center line
        vCenter:ClearAllPoints();
        vCenter:SetStartPoint("BOTTOM", f, 0, 0);
        vCenter:SetEndPoint("TOP", f, 0, 0);

        local hCenter = getLine();
        hCenter:SetThickness(1);
        hCenter:SetColorTexture(CENTER_COLOR[1], CENTER_COLOR[2], CENTER_COLOR[3], CENTER_COLOR[4]);
        hCenter:ClearAllPoints();
        hCenter:SetStartPoint("LEFT", f, 0, 0);
        hCenter:SetEndPoint("RIGHT", f, 0, 0);

        -- Grid lines (vertical)
        local spacing = GRID_SPACING / scale;
        for x = spacing, cx, spacing do
            -- Right of center
            local lineR = getLine();
            lineR:SetThickness(1);
            lineR:SetColorTexture(LINE_COLOR[1], LINE_COLOR[2], LINE_COLOR[3], LINE_COLOR[4]);
            lineR:ClearAllPoints();
            lineR:SetStartPoint("BOTTOM", f, x, 0);
            lineR:SetEndPoint("TOP", f, x, 0);

            -- Left of center (mirror)
            local lineL = getLine();
            lineL:SetThickness(1);
            lineL:SetColorTexture(LINE_COLOR[1], LINE_COLOR[2], LINE_COLOR[3], LINE_COLOR[4]);
            lineL:ClearAllPoints();
            lineL:SetStartPoint("BOTTOM", f, -x, 0);
            lineL:SetEndPoint("TOP", f, -x, 0);
        end

        -- Grid lines (horizontal)
        for y = spacing, cy, spacing do
            -- Above center
            local lineU = getLine();
            lineU:SetThickness(1);
            lineU:SetColorTexture(LINE_COLOR[1], LINE_COLOR[2], LINE_COLOR[3], LINE_COLOR[4]);
            lineU:ClearAllPoints();
            lineU:SetStartPoint("LEFT", f, 0, y);
            lineU:SetEndPoint("RIGHT", f, 0, y);

            -- Below center (mirror)
            local lineD = getLine();
            lineD:SetThickness(1);
            lineD:SetColorTexture(LINE_COLOR[1], LINE_COLOR[2], LINE_COLOR[3], LINE_COLOR[4]);
            lineD:ClearAllPoints();
            lineD:SetStartPoint("LEFT", f, 0, -y);
            lineD:SetEndPoint("RIGHT", f, 0, -y);
        end

        -- Hide unused lines
        for i = idx + 1, #f.lines do
            f.lines[i]:Hide();
        end
    end

    f.Rebuild = rebuild;
    rebuild();

    f:Hide();
    return f;
end

function module:ShowGrid()
    if (not gridFrame) then
        gridFrame = createGrid();
    end
    gridFrame:Rebuild();
    gridFrame:Show();
    module._gridVisible = true;
end

function module:HideGrid()
    if (gridFrame) then
        gridFrame:Hide();
    end
    module._gridVisible = false;
end

function module:ToggleGrid()
    if (module._gridVisible) then
        self:HideGrid();
    else
        self:ShowGrid();
    end
end
