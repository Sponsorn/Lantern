local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local module = Lantern.modules["UIAnchors"];
if (not module) then return; end

local L = Lantern.L;
local T = _G.LanternUX and _G.LanternUX.Theme;

local ANCHOR_DEFS = Lantern.UI_ANCHORS;

-- Theme colors: arrays { r, g, b [, a] }
local BG_COLOR     = T and T.bg        or { 0.06, 0.06, 0.07, 1.0 };
local BORDER_COLOR = T and T.border    or { 0.18, 0.18, 0.20, 1.0 };
local ACCENT_COLOR = T and T.accent    or { 0.88, 0.56, 0.18, 1.0 };
local TEXT_COLOR   = T and T.text      or { 0.72, 0.72, 0.72, 1.0 };
local DIM_COLOR    = T and T.textDim   or { 0.52, 0.52, 0.54, 1.0 };
local FONT_PATH    = T and T.fontPathRegular or "Interface\\AddOns\\LanternUX\\Fonts\\Roboto-Regular.ttf";

local DRAWER_WIDTH = 200;
local ROW_HEIGHT = 20;
local PADDING = 8;
local GROUP_HEADER_HEIGHT = 18;

-- Anchor groups for the drawer
local GROUPS = {
    { key = "bar",  label = L["UIANCHORS_DRAWER_GROUP_BARS"],  ids = { "barsLeft", "barsRight", "barsCenter", "barsTop" } },
    { key = "icon", label = L["UIANCHORS_DRAWER_GROUP_ICONS"], ids = { "iconsLeft", "iconsRight", "iconsCenter" } },
    { key = "text", label = L["UIANCHORS_DRAWER_GROUP_TEXT"],  ids = { "textTop", "textBottom", "listLeft", "listRight", "notifications" } },
};

local drawer; -- the frame, created lazily

-------------------------------------------------------------------------------
-- Checkbox factory
-------------------------------------------------------------------------------

local function createCheckbox(parent, anchorId, label)
    local row = CreateFrame("Frame", "LanternDrawer_Row_" .. anchorId, parent);
    row:SetSize(DRAWER_WIDTH - PADDING * 2, ROW_HEIGHT);

    local cb = CreateFrame("CheckButton", "LanternDrawer_CB_" .. anchorId, row, "UICheckButtonTemplate");
    cb:SetSize(18, 18);
    cb:SetPoint("LEFT", row, "LEFT", 0, 0);
    cb:SetChecked(module:IsAnchorEnabled(anchorId));
    cb:SetScript("OnClick", function(btn)
        local checked = btn:GetChecked();
        module:SetAnchorEnabled(anchorId, checked);
    end);

    local text = row:CreateFontString(nil, "OVERLAY");
    text:SetFont(FONT_PATH, 11, "");
    text:SetTextColor(TEXT_COLOR[1], TEXT_COLOR[2], TEXT_COLOR[3]);
    text:SetPoint("LEFT", cb, "RIGHT", 4, 0);
    text:SetText(label);

    row.checkbox = cb;
    return row;
end

-------------------------------------------------------------------------------
-- Drawer creation
-------------------------------------------------------------------------------

local function createDrawer()
    local f = CreateFrame("Frame", "LanternAnchorsDrawer", UIParent, "BackdropTemplate");
    f:SetSize(DRAWER_WIDTH, 10); -- height calculated dynamically
    f:SetPoint("RIGHT", UIParent, "RIGHT", -60, 0);
    f:SetFrameStrata("DIALOG");
    f:SetBackdrop({
        bgFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = 1,
    });
    f:SetBackdropColor(BG_COLOR[1], BG_COLOR[2], BG_COLOR[3], 0.92);
    f:SetBackdropBorderColor(BORDER_COLOR[1], BORDER_COLOR[2], BORDER_COLOR[3], 0.8);
    f:SetMovable(true);
    f:SetClampedToScreen(true);

    local TITLE_H = 28;

    -- Title bar
    local titleBar = CreateFrame("Frame", "LanternAnchorsDrawer_TitleBar", f);
    titleBar:SetSize(DRAWER_WIDTH, TITLE_H);
    titleBar:SetPoint("TOP", f, "TOP", 0, 0);
    titleBar:EnableMouse(true);
    titleBar:RegisterForDrag("LeftButton");
    titleBar:SetScript("OnDragStart", function() f:StartMoving(); end);
    titleBar:SetScript("OnDragStop", function() f:StopMovingOrSizing(); end);

    local titleText = titleBar:CreateFontString(nil, "OVERLAY");
    titleText:SetFont(FONT_PATH, 12, "");
    titleText:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3]);
    titleText:SetPoint("LEFT", titleBar, "LEFT", PADDING, 0);
    titleText:SetText(L["UIANCHORS_DRAWER_TITLE"]);

    -- Close button (same as LanternUX panel: common-icon-redx, desaturated)
    local closeBtn = CreateFrame("Button", "LanternAnchorsDrawer_Close", titleBar);
    closeBtn:SetSize(TITLE_H, TITLE_H);
    closeBtn:SetPoint("TOPRIGHT");
    local closeIcon = closeBtn:CreateTexture(nil, "ARTWORK");
    closeIcon:SetAtlas("common-icon-redx");
    closeIcon:SetSize(16, 16);
    closeIcon:SetPoint("CENTER");
    closeIcon:SetDesaturated(true);
    closeIcon:SetVertexColor(TEXT_COLOR[1], TEXT_COLOR[2], TEXT_COLOR[3]);
    local closeHover = closeBtn:CreateTexture(nil, "HIGHLIGHT");
    closeHover:SetAllPoints();
    closeHover:SetColorTexture(0.8, 0.2, 0.2, 0.15);
    closeBtn:SetScript("OnEnter", function() closeIcon:SetDesaturated(false); closeIcon:SetVertexColor(1, 1, 1); end);
    closeBtn:SetScript("OnLeave", function() closeIcon:SetDesaturated(true); closeIcon:SetVertexColor(DIM_COLOR[1], DIM_COLOR[2], DIM_COLOR[3]); end);
    closeBtn:SetScript("OnClick", function()
        if (module._anchorsVisible) then
            module:ToggleAnchors(); -- toggles off
        end
    end);

    -- Collapse button (same as LanternUX panel: "_" / "+" text)
    local collapseBtn = CreateFrame("Button", "LanternAnchorsDrawer_Collapse", titleBar);
    collapseBtn:SetSize(TITLE_H, TITLE_H);
    collapseBtn:SetPoint("TOPRIGHT", -TITLE_H, 0);
    local collapseIcon = collapseBtn:CreateFontString(nil, "ARTWORK");
    collapseIcon:SetFont(FONT_PATH, 14, "");
    collapseIcon:SetPoint("CENTER", 0, 1);
    collapseIcon:SetText("_");
    collapseIcon:SetTextColor(TEXT_COLOR[1], TEXT_COLOR[2], TEXT_COLOR[3]);
    local collapseHover = collapseBtn:CreateTexture(nil, "HIGHLIGHT");
    collapseHover:SetAllPoints();
    collapseHover:SetColorTexture(1, 1, 1, 0.06);
    collapseBtn:SetScript("OnEnter", function() collapseIcon:SetTextColor(1, 1, 1); end);
    collapseBtn:SetScript("OnLeave", function() collapseIcon:SetTextColor(TEXT_COLOR[1], TEXT_COLOR[2], TEXT_COLOR[3]); end);

    -- Content container (hidden when collapsed)
    local content = CreateFrame("Frame", "LanternAnchorsDrawer_Content", f);
    content:SetPoint("TOP", titleBar, "BOTTOM", 0, -2);
    content:SetPoint("LEFT", f, "LEFT", PADDING, 0);
    content:SetPoint("RIGHT", f, "RIGHT", -PADDING, 0);

    -- Grid toggle at the top of content
    local gridRow = CreateFrame("Frame", "LanternDrawer_Row_Grid", content);
    gridRow:SetSize(DRAWER_WIDTH - PADDING * 2, ROW_HEIGHT);
    gridRow:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0);

    local gridCb = CreateFrame("CheckButton", "LanternDrawer_CB_Grid", gridRow, "UICheckButtonTemplate");
    gridCb:SetSize(18, 18);
    gridCb:SetPoint("LEFT", gridRow, "LEFT", 0, 0);
    gridCb:SetChecked(false);
    gridCb:SetScript("OnClick", function(btn)
        if (module.ToggleGrid) then
            module:ToggleGrid();
            btn:SetChecked(module._gridVisible or false);
        end
    end);

    local gridText = gridRow:CreateFontString(nil, "OVERLAY");
    gridText:SetFont(FONT_PATH, 11, "");
    gridText:SetTextColor(TEXT_COLOR[1], TEXT_COLOR[2], TEXT_COLOR[3]);
    gridText:SetPoint("LEFT", gridCb, "RIGHT", 4, 0);
    gridText:SetText(L["UIANCHORS_SHOW_GRID"]);

    f.gridCheckbox = gridCb;

    -- Build checkbox rows
    local rows = {};
    local yOffset = ROW_HEIGHT + 6; -- offset past grid toggle
    for _, group in ipairs(GROUPS) do
        -- Group header
        local header = content:CreateFontString(nil, "OVERLAY");
        header:SetFont(FONT_PATH, 10, "");
        header:SetTextColor(DIM_COLOR[1], DIM_COLOR[2], DIM_COLOR[3]);
        header:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOffset);
        header:SetText(group.label);
        yOffset = yOffset + GROUP_HEADER_HEIGHT;

        -- Checkboxes
        for _, anchorId in ipairs(group.ids) do
            local def = Lantern.UI_ANCHORS_BY_ID[anchorId];
            if (def) then
                local row = createCheckbox(content, anchorId, def.label);
                row:SetPoint("TOPLEFT", content, "TOPLEFT", 4, -yOffset);
                table.insert(rows, { anchorId = anchorId, row = row });
                yOffset = yOffset + ROW_HEIGHT;
            end
        end

        yOffset = yOffset + 4; -- spacing between groups
    end

    local contentHeight = yOffset;
    content:SetHeight(contentHeight);
    f.content = content;
    f.rows = rows;

    -- Collapsed state
    f.collapsed = false;
    local expandedHeight = TITLE_H + contentHeight + PADDING;
    local collapsedHeight = TITLE_H;
    f:SetHeight(expandedHeight);

    collapseBtn:SetScript("OnClick", function()
        f.collapsed = not f.collapsed;
        if (f.collapsed) then
            content:Hide();
            f:SetHeight(collapsedHeight);
            collapseIcon:SetText("+");
        else
            content:Show();
            f:SetHeight(expandedHeight);
            collapseIcon:SetText("_");
        end
    end);

    f:Hide();
    return f;
end

-------------------------------------------------------------------------------
-- Public API for Edit Mode callbacks
-------------------------------------------------------------------------------

function module:ShowDrawer()
    if (not drawer) then
        drawer = createDrawer();
    end
    -- Refresh checkbox states for current layout
    self:RefreshDrawer();
    drawer:Show();
end

function module:HideDrawer()
    if (drawer) then
        drawer:Hide();
    end
end

function module:RefreshDrawer()
    if (not drawer or not drawer.rows) then return; end
    for _, entry in ipairs(drawer.rows) do
        entry.row.checkbox:SetChecked(self:IsAnchorEnabled(entry.anchorId));
    end
    if (drawer.gridCheckbox) then
        drawer.gridCheckbox:SetChecked(module._gridVisible or false);
    end
end
