local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local module = Lantern.modules["UIAnchors"];
if (not module) then return; end

local L = Lantern.L;
local T = Lantern.UX and Lantern.UX.Theme;

local ANCHOR_DEFS = Lantern.UI_ANCHORS;

local PREVIEW_ALPHA = 0.25;
local ACCENT_COLOR = T and T.accent or { 0.88, 0.56, 0.18, 1.0 };
local LABEL_FONT = T and T.fontPathRegular or "Interface\\AddOns\\Lantern\\UX\\Fonts\\Roboto-Regular.ttf";
local LABEL_SIZE = 10;

-- Placeholder icon textures for icon previews
local ICON_TEXTURES = {
    "Interface\\Icons\\INV_Misc_QuestionMark",
    "Interface\\Icons\\Spell_Nature_Rejuvenation",
    "Interface\\Icons\\Ability_Rogue_Sprint",
    "Interface\\Icons\\Spell_Holy_FlashHeal",
    "Interface\\Icons\\Spell_Fire_FlameBolt",
    "Interface\\Icons\\Spell_Frost_FrostBolt02",
    "Interface\\Icons\\Spell_Nature_Lightning",
    "Interface\\Icons\\Spell_Shadow_ShadowBolt",
    "Interface\\Icons\\Spell_Holy_PowerWordShield",
    "Interface\\Icons\\Spell_Nature_HealingTouch",
};

local GROW_ARROWS = {
    UP    = { rotation = 0 },
    DOWN  = { rotation = math.pi },
    LEFT  = { rotation = math.pi / 2 },
    RIGHT = { rotation = -math.pi / 2 },
    HORIZONTAL = { rotation = -math.pi / 2 },
};

-------------------------------------------------------------------------------
-- Preview element factories
-------------------------------------------------------------------------------

local function createBarPreview(parent, index, width, height)
    local bar = CreateFrame("Frame", parent:GetName() .. "_Bar" .. index, parent, "BackdropTemplate");
    bar:SetSize(width, height);
    -- Dark background
    bar:SetBackdrop({ bgFile = "Interface\\BUTTONS\\WHITE8X8" });
    bar:SetBackdropColor(0.1, 0.1, 0.1, 0.6);
    -- White "fill" overlay (partial width to look like a status bar)
    local fill = bar:CreateTexture(nil, "ARTWORK");
    fill:SetTexture("Interface\\BUTTONS\\WHITE8X8");
    fill:SetVertexColor(1, 1, 1, PREVIEW_ALPHA);
    fill:SetPoint("TOPLEFT", bar, "TOPLEFT", 1, -1);
    fill:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 1, 1);
    -- Random-ish fill width per bar (60-90%)
    local fillPct = 0.6 + (index * 0.1);
    if (fillPct > 0.9) then fillPct = 0.9; end
    fill:SetWidth((width - 2) * fillPct);
    bar.fill = fill;
    return bar;
end

local function createIconPreview(parent, index, size)
    local icon = CreateFrame("Frame", parent:GetName() .. "_Icon" .. index, parent, "BackdropTemplate");
    icon:SetSize(size, size);
    -- Dark border
    icon:SetBackdrop({
        bgFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = 1,
    });
    icon:SetBackdropColor(0.1, 0.1, 0.1, 0.6);
    icon:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.6);
    -- Placeholder icon texture
    local tex = icon:CreateTexture(nil, "ARTWORK");
    tex:SetPoint("TOPLEFT", 2, -2);
    tex:SetPoint("BOTTOMRIGHT", -2, 2);
    tex:SetTexture(ICON_TEXTURES[((index - 1) % #ICON_TEXTURES) + 1]);
    tex:SetAlpha(PREVIEW_ALPHA + 0.15);
    tex:SetTexCoord(0.08, 0.92, 0.08, 0.92); -- trim icon edges
    icon.iconTex = tex;
    return icon;
end

local function createTextPreview(parent, index, width, height)
    local textFrame = CreateFrame("Frame", parent:GetName() .. "_Text" .. index, parent);
    textFrame:SetSize(width, height);
    local fs = textFrame:CreateFontString(nil, "OVERLAY");
    fs:SetFont(LABEL_FONT, height - 2, "");
    fs:SetTextColor(1, 1, 1, PREVIEW_ALPHA + 0.1);
    fs:SetAllPoints();
    fs:SetText("Text Line " .. index);
    fs:SetJustifyH("CENTER");
    textFrame.text = fs;
    return textFrame;
end

-------------------------------------------------------------------------------
-- Preview layout
-------------------------------------------------------------------------------

local function layoutPreviews(frame, previews, grow, spacing)
    if (not previews or #previews == 0) then return; end
    local prev = nil;
    for i, preview in ipairs(previews) do
        preview:ClearAllPoints();
        if (i == 1) then
            if (grow == "UP") then
                preview:SetPoint("BOTTOM", frame, "TOP", 0, 4);
            elseif (grow == "DOWN") then
                preview:SetPoint("TOP", frame, "BOTTOM", 0, -4);
            elseif (grow == "LEFT") then
                preview:SetPoint("RIGHT", frame, "LEFT", -4, 0);
            elseif (grow == "RIGHT") then
                preview:SetPoint("LEFT", frame, "RIGHT", 4, 0);
            elseif (grow == "HORIZONTAL") then
                local totalWidth = 0;
                for _, p in ipairs(previews) do
                    totalWidth = totalWidth + p:GetWidth();
                end
                totalWidth = totalWidth + spacing * (#previews - 1);
                preview:SetPoint("LEFT", frame, "CENTER", -totalWidth / 2, 0);
            end
        else
            if (grow == "UP") then
                preview:SetPoint("BOTTOM", prev, "TOP", 0, spacing);
            elseif (grow == "DOWN") then
                preview:SetPoint("TOP", prev, "BOTTOM", 0, -spacing);
            elseif (grow == "LEFT") then
                preview:SetPoint("RIGHT", prev, "LEFT", -spacing, 0);
            elseif (grow == "RIGHT" or grow == "HORIZONTAL") then
                preview:SetPoint("LEFT", prev, "RIGHT", spacing, 0);
            end
        end
        prev = preview;
    end
end

-------------------------------------------------------------------------------
-- Edit visuals per frame
-------------------------------------------------------------------------------

local function setupEditVisuals(frame)
    local def = frame.anchorDef;
    if (not def) then return; end

    if (not frame.editBorder) then
        frame.editBorder = CreateFrame("Frame", frame:GetName() .. "_Border", frame, "BackdropTemplate");
        frame.editBorder:SetBackdrop({
            edgeFile = "Interface\\BUTTONS\\WHITE8X8",
            edgeSize = 1,
        });
        frame.editBorder:SetBackdropBorderColor(1, 1, 1, 0.3);
    end

    -- Label anchored above the border (positioned after border in buildPreviews)
    if (not frame.editLabel) then
        frame.editLabel = frame:CreateFontString(frame:GetName() .. "_Label", "OVERLAY");
        frame.editLabel:SetFont(LABEL_FONT, LABEL_SIZE, "OUTLINE");
        frame.editLabel:SetTextColor(1, 1, 1, 0.9);
        frame.editLabel:SetText(def.label);
    end

    if (not frame.editArrow) then
        frame.editArrow = frame:CreateTexture(frame:GetName() .. "_Arrow", "OVERLAY");
        frame.editArrow:SetTexture("Interface\\BUTTONS\\Arrow-Up-Up");
        frame.editArrow:SetSize(12, 12);
        local arrowData = GROW_ARROWS[def.grow];
        if (arrowData and arrowData.rotation ~= 0) then
            frame.editArrow:SetRotation(arrowData.rotation);
        end
    end

    -- Second arrow for HORIZONTAL grow (points left, mirroring the right arrow)
    if (def.grow == "HORIZONTAL" and not frame.editArrowLeft) then
        frame.editArrowLeft = frame:CreateTexture(frame:GetName() .. "_ArrowL", "OVERLAY");
        frame.editArrowLeft:SetTexture("Interface\\BUTTONS\\Arrow-Up-Up");
        frame.editArrowLeft:SetSize(12, 12);
        frame.editArrowLeft:SetRotation(math.pi / 2); -- points left
    end
end

local function buildPreviews(frame)
    local def = frame.anchorDef;
    if (not def) then return; end

    -- Hide existing previews; pool for reuse
    if (frame.editPreviews) then
        for _, p in ipairs(frame.editPreviews) do
            p:Hide();
        end
    end
    frame._previewPool = frame._previewPool or {};
    for _, p in ipairs(frame.editPreviews or {}) do
        table.insert(frame._previewPool, p);
    end
    frame.editPreviews = {};

    local settings = module:GetPreviewSettings(def.id);
    local pool = frame._previewPool or {};
    for i = 1, settings.count do
        local preview = table.remove(pool);
        if (preview) then
            preview:SetParent(frame);
            if (def.previewType == "bar" or def.previewType == "text") then
                preview:SetSize(settings.width, settings.height);
            else
                preview:SetSize(settings.height, settings.height);
            end
        else
            if (def.previewType == "bar") then
                preview = createBarPreview(frame, i, settings.width, settings.height);
            elseif (def.previewType == "icon") then
                preview = createIconPreview(frame, i, settings.height);
            elseif (def.previewType == "text") then
                preview = createTextPreview(frame, i, settings.width, settings.height);
            end
        end
        if (preview) then
            table.insert(frame.editPreviews, preview);
        end
    end
    frame._previewPool = pool;

    layoutPreviews(frame, frame.editPreviews, def.grow, settings.spacing);

    -- Position border to encompass the preview area (not centered on the 1x1 anchor)
    if (frame.editBorder and #frame.editPreviews > 0) then
        local elemW = (def.previewType == "icon") and settings.height or settings.width;
        local totalW, totalH;
        if (def.grow == "UP" or def.grow == "DOWN") then
            totalW = elemW + 8;
            totalH = settings.count * settings.height + (settings.count - 1) * settings.spacing + 8;
        else
            totalW = settings.count * elemW + (settings.count - 1) * settings.spacing + 8;
            totalH = settings.height + 8;
        end
        frame.editBorder:SetSize(math.max(totalW, 40), math.max(totalH, 20));
        frame.editBorder:ClearAllPoints();

        -- Anchor border relative to the first preview element
        local first = frame.editPreviews[1];
        if (def.grow == "UP") then
            frame.editBorder:SetPoint("BOTTOM", first, "BOTTOM", 0, -4);
            frame.editBorder:SetPoint("TOP", frame.editPreviews[#frame.editPreviews], "TOP", 0, 4);
            frame.editBorder:SetWidth(math.max(totalW, 40));
        elseif (def.grow == "DOWN") then
            frame.editBorder:SetPoint("TOP", first, "TOP", 0, 4);
            frame.editBorder:SetPoint("BOTTOM", frame.editPreviews[#frame.editPreviews], "BOTTOM", 0, -4);
            frame.editBorder:SetWidth(math.max(totalW, 40));
        elseif (def.grow == "LEFT") then
            frame.editBorder:SetPoint("RIGHT", first, "RIGHT", 4, 0);
            frame.editBorder:SetPoint("LEFT", frame.editPreviews[#frame.editPreviews], "LEFT", -4, 0);
            frame.editBorder:SetHeight(math.max(totalH, 20));
        elseif (def.grow == "RIGHT" or def.grow == "HORIZONTAL") then
            frame.editBorder:SetPoint("LEFT", first, "LEFT", -4, 0);
            frame.editBorder:SetPoint("RIGHT", frame.editPreviews[#frame.editPreviews], "RIGHT", 4, 0);
            frame.editBorder:SetHeight(math.max(totalH, 20));
        end
    end

    -- Position label above the border
    if (frame.editLabel and frame.editBorder) then
        frame.editLabel:ClearAllPoints();
        frame.editLabel:SetPoint("BOTTOM", frame.editBorder, "TOP", 0, 4);
    end

    -- Position arrow(s)
    if (frame.editArrow and frame.editLabel) then
        frame.editArrow:ClearAllPoints();
        if (def.grow == "HORIZONTAL") then
            -- Right arrow to the right of the label
            frame.editArrow:SetPoint("LEFT", frame.editLabel, "RIGHT", 4, 0);
        else
            -- Single arrow below label
            frame.editArrow:SetPoint("TOP", frame.editLabel, "BOTTOM", 0, -2);
        end
    end
    if (frame.editArrowLeft and frame.editLabel) then
        frame.editArrowLeft:ClearAllPoints();
        frame.editArrowLeft:SetPoint("RIGHT", frame.editLabel, "LEFT", -4, 0);
    end
end

-------------------------------------------------------------------------------
-- Nudge buttons (1px directional arrows around the border)
-------------------------------------------------------------------------------

local NUDGE_SIZE = 26;
local NUDGE_TEX = "Interface\\BUTTONS\\UI-ScrollBar-ScrollUpButton-Up";

local function nudgeAnchor(frame, dx, dy)
    local sw, sh = GetPhysicalScreenSize();
    local scale = UIParent:GetEffectiveScale();
    local oneX = 1 / scale;
    local oneY = 1 / scale;
    local xPct, yPct = module:GetAnchorPosition(frame.anchorId);
    module:SaveAnchorPosition(frame.anchorId, xPct + (dx * oneX) / sw, yPct + (dy * oneY) / sh);
    module:RepositionAllAnchors();
end

local function createNudgeButton(parent, name, rotation, dx, dy)
    local btn = CreateFrame("Button", parent:GetName() .. "_Nudge" .. name, parent);
    btn:SetSize(NUDGE_SIZE, NUDGE_SIZE);
    local normal = btn:CreateTexture(nil, "ARTWORK");
    normal:SetAllPoints();
    normal:SetTexture(NUDGE_TEX);
    if (rotation ~= 0) then
        normal:SetRotation(rotation);
    end
    btn:SetNormalTexture(normal);

    local highlight = btn:CreateTexture(nil, "HIGHLIGHT");
    highlight:SetAllPoints();
    highlight:SetTexture(NUDGE_TEX);
    if (rotation ~= 0) then
        highlight:SetRotation(rotation);
    end

    btn:SetScript("OnClick", function()
        nudgeAnchor(parent, dx, dy);
    end);

    return btn;
end

local function setupNudgeButtons(frame)
    if (frame._nudgeButtons) then return; end

    local border = frame.editBorder;
    if (not border) then return; end

    local up    = createNudgeButton(frame, "Up",    0,            0,  1);
    local down  = createNudgeButton(frame, "Down",  math.pi,      0, -1);
    local left  = createNudgeButton(frame, "Left",  math.pi / 2, -1,  0);
    local right = createNudgeButton(frame, "Right", -math.pi / 2, 1,  0);

    up:SetPoint("BOTTOM", border, "TOP", 0, 2);
    down:SetPoint("TOP", border, "BOTTOM", 0, -2);
    left:SetPoint("RIGHT", border, "LEFT", -2, 0);
    right:SetPoint("LEFT", border, "RIGHT", 2, 0);

    frame._nudgeButtons = { up, down, left, right };
end

local function showNudgeButtons(frame)
    if (not frame._nudgeButtons) then return; end
    for _, btn in ipairs(frame._nudgeButtons) do
        btn:Show();
    end
end

local function hideNudgeButtons(frame)
    if (not frame._nudgeButtons) then return; end
    for _, btn in ipairs(frame._nudgeButtons) do
        btn:Hide();
    end
end

-------------------------------------------------------------------------------
-- Show / hide edit visuals
-------------------------------------------------------------------------------

local function showEditVisuals(frame)
    setupEditVisuals(frame);
    buildPreviews(frame);
    setupNudgeButtons(frame);
    if (frame.editLabel) then frame.editLabel:Show(); end
    if (frame.editBorder) then frame.editBorder:Show(); end
    if (frame.editArrow) then frame.editArrow:Show(); end
    if (frame.editArrowLeft) then frame.editArrowLeft:Show(); end
    if (frame.editPreviews) then
        for _, p in ipairs(frame.editPreviews) do p:Show(); end
    end
    showNudgeButtons(frame);
    frame:Show();
end

local function hideEditVisuals(frame)
    if (frame.editLabel) then frame.editLabel:Hide(); end
    if (frame.editBorder) then frame.editBorder:Hide(); end
    if (frame.editArrow) then frame.editArrow:Hide(); end
    if (frame.editArrowLeft) then frame.editArrowLeft:Hide(); end
    if (frame.editPreviews) then
        for _, p in ipairs(frame.editPreviews) do p:Hide(); end
    end
    hideNudgeButtons(frame);
end

-------------------------------------------------------------------------------
-- In-house dragging
-------------------------------------------------------------------------------

local function makeDraggable(frame)
    if (frame._draggable) then return; end

    -- Expand the hit rect so the 1x1 anchor is easy to grab via its border/previews
    frame:SetHitRectInsets(-100, -100, -40, -100);
    frame:SetMovable(true);
    frame:EnableMouse(true);
    frame:RegisterForDrag("LeftButton");
    frame:SetClampedToScreen(true);

    frame:SetScript("OnDragStart", function(f)
        if (not module._anchorsVisible) then return; end
        f:StartMoving();
    end);

    frame:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing();
        -- Convert current position to percentage offset from screen center
        local fX, fY = f:GetCenter();
        local pX, pY = UIParent:GetCenter();
        local relX = (fX or 0) - (pX or 0);
        local relY = (fY or 0) - (pY or 0);
        local sw, sh = GetPhysicalScreenSize();
        module:SaveAnchorPosition(f.anchorId, relX / sw, relY / sh);
    end);

    frame._draggable = true;
end

-------------------------------------------------------------------------------
-- Public API for showing/hiding anchors
-------------------------------------------------------------------------------

function module:ShowAnchorVisuals(anchorId)
    local frame = self.frames[anchorId];
    if (not frame) then return; end
    makeDraggable(frame);
    showEditVisuals(frame);
end

function module:HideAnchorVisuals(anchorId)
    local frame = self.frames[anchorId];
    if (not frame) then return; end
    hideEditVisuals(frame);
    self:ApplyAnchorVisibility(anchorId);
end

-- Toggle all enabled anchors + drawer
function module:ToggleAnchors()
    module._anchorsVisible = not module._anchorsVisible;
    for _, def in ipairs(ANCHOR_DEFS) do
        if (self:IsAnchorEnabled(def.id)) then
            if (module._anchorsVisible) then
                self:ShowAnchorVisuals(def.id);
            else
                self:HideAnchorVisuals(def.id);
            end
        end
    end
    if (module._anchorsVisible) then
        if (self.ShowDrawer) then self:ShowDrawer(); end
    else
        if (self.HideDrawer) then self:HideDrawer(); end
        if (self.HideGrid) then self:HideGrid(); end
    end
end

-- Refresh previews for a specific anchor
function module:RefreshAnchorPreview(anchorId)
    local frame = self.frames[anchorId];
    if (frame and module._anchorsVisible and self:IsAnchorEnabled(anchorId)) then
        buildPreviews(frame);
        if (frame.editPreviews) then
            for _, p in ipairs(frame.editPreviews) do p:Show(); end
        end
    end
end
