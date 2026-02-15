local ADDON_NAME, NS = ...;
local ST = NS.SpellTracker;
if (not ST) then return; end

-------------------------------------------------------------------------------
-- Bar frame creation per category
-------------------------------------------------------------------------------

function ST._BuildBarFrame(categoryKey)
    if (ST.displayFrames[categoryKey]) then return; end
    local catDB = ST:GetCategoryDB(categoryKey);

    local frame = CreateFrame("Frame", "LanternMythicTracker_" .. categoryKey, UIParent);
    frame:SetSize(catDB.barWidth, 200);
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, -150);
    frame:SetFrameStrata("MEDIUM");
    frame:SetClampedToScreen(true);
    frame:SetMovable(true);
    frame:EnableMouse(true);
    frame:RegisterForDrag("LeftButton");
    frame:SetScript("OnDragStart", function(self)
        if (not catDB.locked or IsShiftKeyDown()) then
            self:StartMoving();
        end
    end);
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing();
        ST._SavePosition(categoryKey);
    end);
    frame:SetAlpha(catDB.barAlpha);

    -- Title bar (visible when unlocked)
    local title = ST._CreateTitleBar(frame, categoryKey, catDB);

    -- Bar pool
    local bh = math.max(12, catDB.barHeight);
    local iconSize = bh;
    local barW = math.max(60, catDB.barWidth - iconSize);
    local nameFontSize = math.max(9, math.floor(bh * 0.45));
    local cdFontSize = math.max(10, math.floor(bh * 0.55));
    local fontPath = ST._GetFontPath(catDB.font);
    local outline = catDB.fontOutline or "OUTLINE";

    local barPool = {};
    for i = 1, ST._BAR_POOL_SIZE do
        local yOff = catDB.growUp
            and ((i - 1) * (bh + 1))
            or (-((i - 1) * (bh + 1)));

        local row = CreateFrame("Frame", nil, frame);
        row:SetSize(iconSize + barW, bh);
        if (catDB.growUp) then
            row:SetPoint("BOTTOMLEFT", 0, yOff);
        else
            row:SetPoint("TOPLEFT", 0, yOff);
        end

        local ico = row:CreateTexture(nil, "ARTWORK");
        ico:SetSize(iconSize, bh);
        ico:SetPoint("LEFT", 0, 0);
        ico:SetTexCoord(0.08, 0.92, 0.08, 0.92);
        row.icon = ico;

        local barBg = row:CreateTexture(nil, "BACKGROUND");
        barBg:SetPoint("TOPLEFT", iconSize, 0);
        barBg:SetPoint("BOTTOMRIGHT", 0, 0);
        barBg:SetTexture(ST._SOLID);
        barBg:SetVertexColor(0.15, 0.15, 0.15, 1);
        row.barBg = barBg;

        local sb = CreateFrame("StatusBar", nil, row);
        sb:SetPoint("TOPLEFT", iconSize, 0);
        sb:SetPoint("BOTTOMRIGHT", 0, 0);
        sb:SetStatusBarTexture(ST._SOLID);
        sb:SetStatusBarColor(1, 1, 1, 0.85);
        sb:SetMinMaxValues(0, 1);
        sb:SetValue(0);
        sb:SetFrameLevel(row:GetFrameLevel() + 1);
        row.cdBar = sb;

        local overlay = CreateFrame("Frame", nil, row);
        overlay:SetPoint("TOPLEFT", iconSize, 0);
        overlay:SetPoint("BOTTOMRIGHT", 0, 0);
        overlay:SetFrameLevel(sb:GetFrameLevel() + 1);
        row.overlay = overlay;

        local nameStr = overlay:CreateFontString(nil, "OVERLAY");
        nameStr:SetFont(fontPath, nameFontSize, outline);
        nameStr:SetPoint("LEFT", 6, 0);
        nameStr:SetJustifyH("LEFT");
        nameStr:SetWidth(barW - 50);
        nameStr:SetWordWrap(false);
        nameStr:SetShadowOffset(1, -1);
        nameStr:SetShadowColor(0, 0, 0, 1);
        row.nameText = nameStr;

        local cdStr = overlay:CreateFontString(nil, "OVERLAY");
        cdStr:SetFont(fontPath, cdFontSize, outline);
        cdStr:SetPoint("RIGHT", -6, 0);
        cdStr:SetShadowOffset(1, -1);
        cdStr:SetShadowColor(0, 0, 0, 1);
        row.cdText = cdStr;

        row:Hide();
        barPool[i] = row;
    end

    local display = {
        frame   = frame,
        title   = title,
        barPool = barPool,
    };
    ST.displayFrames[categoryKey] = display;

    ST._RestorePosition(categoryKey);
    frame:Hide();
end

-------------------------------------------------------------------------------
-- Render bar mode for a category
-------------------------------------------------------------------------------

function ST._RenderBarCategory(categoryKey)
    local display = ST.displayFrames[categoryKey];
    if (not display or not display.frame) then return; end
    local catDB = ST:GetCategoryDB(categoryKey);
    local bh = math.max(12, catDB.barHeight);

    local entries = ST._CollectSortedEntries(categoryKey);

    for i = 1, ST._BAR_POOL_SIZE do
        local bar = display.barPool[i];
        local entry = entries[i];

        if (entry) then
            bar:Show();

            local tex = ST._GetSpellTexture(entry.spellID);
            if (tex) then
                bar.icon:SetTexture(tex);
            end

            local cr, cg, cb = ST:GetClassColor(entry.class);

            bar.nameText:SetText("|cFFFFFFFF" .. entry.name .. "|r");

            if (entry.state == "ready") then
                -- Green bar, "READY"
                bar.cdBar:SetMinMaxValues(0, 1);
                bar.cdBar:SetValue(0);
                bar.barBg:SetVertexColor(0.2, 0.8, 0.2, 1);
                bar.cdText:SetText("READY");
                bar.cdText:SetTextColor(0.2, 1.0, 0.2);
            elseif (entry.state == "active") then
                -- Accent amber bar, duration countdown
                local spellData = ST.spellDB[entry.spellID];
                local totalDur = spellData and spellData.duration or 1;
                bar.cdBar:SetMinMaxValues(0, totalDur);
                bar.cdBar:SetValue(entry.remaining);
                bar.cdBar:SetStatusBarColor(0.9, 0.77, 0.1, 0.85);  -- amber accent
                bar.barBg:SetVertexColor(0.22, 0.19, 0.03, 1);
                bar.cdText:SetText(ST._FormatTime(entry.remaining));
                bar.cdText:SetTextColor(1, 0.9, 0.3);
            elseif (entry.state == "cooldown") then
                -- Class-colored bar, CD countdown
                bar.cdBar:SetMinMaxValues(0, entry.baseCd);
                bar.cdBar:SetValue(entry.remaining);
                bar.cdBar:SetStatusBarColor(cr, cg, cb, 0.85);
                bar.barBg:SetVertexColor(cr * 0.25, cg * 0.25, cb * 0.25, 1);
                bar.cdText:SetText(ST._FormatTime(entry.remaining));
                bar.cdText:SetTextColor(1, 1, 1);
            end
        else
            bar:Hide();
        end
    end

    local numVisible = math.min(#entries, ST._BAR_POOL_SIZE);
    if (numVisible > 0) then
        display.frame:SetHeight(numVisible * (bh + 1) + 2);
    end
end

-------------------------------------------------------------------------------
-- Layout refresh (for settings changes)
-------------------------------------------------------------------------------

function ST:RefreshBarLayout(categoryKey)
    local display = self.displayFrames[categoryKey];
    if (not display or not display.frame) then return; end
    local catDB = self:GetCategoryDB(categoryKey);

    local fontPath = ST._GetFontPath(catDB.font);
    local outline = catDB.fontOutline or "OUTLINE";
    local bh = math.max(12, catDB.barHeight);
    local iconSize = bh;
    local barW = math.max(60, catDB.barWidth - iconSize);
    local nameFontSize = math.max(9, math.floor(bh * 0.45));
    local cdFontSize = math.max(10, math.floor(bh * 0.55));

    display.frame:SetWidth(catDB.barWidth);
    display.frame:SetAlpha(catDB.barAlpha);

    if (display.title) then
        local cat = self:GetCategory(categoryKey);
        local label = cat and cat.label or categoryKey;
        if (display.title.text) then
            display.title.text:SetFont(fontPath, 12, outline);
        end
        if (catDB.locked) then
            display.title:Hide();
        else
            display.title:Show();
            display.title.text:SetText("|cFFe6c619" .. label .. " (unlocked)|r");
        end
    end

    for i = 1, ST._BAR_POOL_SIZE do
        local bar = display.barPool[i];
        if (bar) then
            bar:SetSize(iconSize + barW, bh);
            bar.icon:SetSize(iconSize, bh);
            bar:ClearAllPoints();
            local yOff = catDB.growUp
                and ((i - 1) * (bh + 1))
                or (-((i - 1) * (bh + 1)));
            if (catDB.growUp) then
                bar:SetPoint("BOTTOMLEFT", 0, yOff);
            else
                bar:SetPoint("TOPLEFT", 0, yOff);
            end
            bar.barBg:ClearAllPoints();
            bar.barBg:SetPoint("TOPLEFT", iconSize, 0);
            bar.barBg:SetPoint("BOTTOMRIGHT", 0, 0);
            bar.cdBar:ClearAllPoints();
            bar.cdBar:SetPoint("TOPLEFT", iconSize, 0);
            bar.cdBar:SetPoint("BOTTOMRIGHT", 0, 0);
            if (bar.overlay) then
                bar.overlay:ClearAllPoints();
                bar.overlay:SetPoint("TOPLEFT", iconSize, 0);
                bar.overlay:SetPoint("BOTTOMRIGHT", 0, 0);
            end
            bar.nameText:SetWidth(barW - 50);
            bar.nameText:SetFont(fontPath, nameFontSize, outline);
            bar.cdText:SetFont(fontPath, cdFontSize, outline);
        end
    end
end
