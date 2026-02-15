local ADDON_NAME, NS = ...;
local ST = NS.SpellTracker;
if (not ST) then return; end

-------------------------------------------------------------------------------
-- Icon frame creation per category
-------------------------------------------------------------------------------

function ST._BuildIconFrame(categoryKey)
    if (ST.displayFrames[categoryKey]) then return; end
    local catDB = ST:GetCategoryDB(categoryKey);

    local frame = CreateFrame("Frame", "LanternMythicTracker_" .. categoryKey, UIParent);
    frame:SetSize(200, 200);
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

    -- Title bar (visible when unlocked)
    local title = ST._CreateTitleBar(frame, categoryKey, catDB);

    -- Pre-create icon pool and name label pool
    local iconPool = {};
    for i = 1, ST._ICON_POOL_SIZE do
        iconPool[i] = ST._CreateSpellIcon(frame, catDB.iconSize);
    end

    local namePool = {};
    for i = 1, 5 do
        local nameLabel = frame:CreateFontString(nil, "OVERLAY");
        nameLabel:SetFont(ST._GetFontPath(catDB.font), 12, catDB.fontOutline or "OUTLINE");
        nameLabel:SetJustifyH("LEFT");
        nameLabel:SetShadowOffset(1, -1);
        nameLabel:SetShadowColor(0, 0, 0, 1);
        nameLabel:Hide();
        namePool[i] = nameLabel;
    end

    local display = {
        frame    = frame,
        title    = title,
        iconPool = iconPool,
        namePool = namePool,
    };
    ST.displayFrames[categoryKey] = display;

    ST._RestorePosition(categoryKey);
    frame:Hide();
end

-------------------------------------------------------------------------------
-- Render icon mode for a category
-------------------------------------------------------------------------------

function ST._RenderIconCategory(categoryKey)
    local display = ST.displayFrames[categoryKey];
    if (not display or not display.frame) then return; end
    if (not display.iconPool) then return; end
    local catDB = ST:GetCategoryDB(categoryKey);
    local iconSize = catDB.iconSize;
    local spacing = catDB.iconSpacing;
    local showNames = catDB.showNames;
    local fontPath = ST._GetFontPath(catDB.font);
    local outline = catDB.fontOutline or "OUTLINE";

    -- Hide everything first
    for _, ico in ipairs(display.iconPool) do ico:Hide(); end
    for _, lbl in ipairs(display.namePool) do lbl:Hide(); end

    -- Group entries by player
    local filter = catDB.filter or (ST:GetCategory(categoryKey) and ST:GetCategory(categoryKey).defaultFilter) or "all";
    local playerOrder = {};
    local playerSpells = {};
    local now = GetTime();

    for playerName, player in pairs(ST.trackedPlayers) do
        local isSelf = (playerName == ST.playerName);
        if (not isSelf or catDB.showSelf) then
            local spells = ST._CollectPlayerCategorySpells(player, categoryKey, filter);
            if (#spells > 0) then
                table.insert(playerOrder, { name = playerName, class = player.class, isSelf = isSelf });
                playerSpells[playerName] = spells;
            end
        end
    end

    -- Sort players: self on top, then alphabetical
    table.sort(playerOrder, function(a, b)
        if (catDB.selfOnTop and a.isSelf ~= b.isSelf) then return a.isSelf; end
        return a.name < b.name;
    end);

    -- Layout
    local y = 0;
    local iconIdx = 1;
    local nameIdx = 1;
    local maxWidth = 0;
    local growUp = catDB.growUp;

    for _, playerInfo in ipairs(playerOrder) do
        local spells = playerSpells[playerInfo.name];
        if (not spells) then break; end

        -- Player name header
        if (showNames and nameIdx <= #display.namePool) then
            local lbl = display.namePool[nameIdx];
            lbl:SetFont(fontPath, 11, outline);
            local cr, cg, cb = ST:GetClassColor(playerInfo.class);
            lbl:SetTextColor(cr, cg, cb);
            lbl:SetText(playerInfo.name);
            lbl:ClearAllPoints();
            if (growUp) then
                lbl:SetPoint("BOTTOMLEFT", display.frame, "BOTTOMLEFT", 0, y);
            else
                lbl:SetPoint("TOPLEFT", display.frame, "TOPLEFT", 0, -y);
            end
            lbl:Show();
            nameIdx = nameIdx + 1;
            y = y + 14;
        end

        -- Spell icons in a row
        local x = 0;
        for _, spell in ipairs(spells) do
            if (iconIdx > ST._ICON_POOL_SIZE) then break; end
            local ico = display.iconPool[iconIdx];
            ico:SetSize(iconSize, iconSize);

            -- Position
            ico:ClearAllPoints();
            if (growUp) then
                ico:SetPoint("BOTTOMLEFT", display.frame, "BOTTOMLEFT", x, y);
            else
                ico:SetPoint("TOPLEFT", display.frame, "TOPLEFT", x, -y);
            end

            ST._ApplyIconState(ico, spell.state, spell.spellID, spell.cdEnd, spell.activeEnd, spell.baseCd, now);

            ico:Show();
            iconIdx = iconIdx + 1;
            x = x + iconSize + spacing;
        end

        if (x > maxWidth) then maxWidth = x; end
        y = y + iconSize + spacing + 2;
    end

    -- Resize frame to fit content
    if (maxWidth > 0 and y > 0) then
        display.frame:SetSize(math.max(maxWidth, 100), y);
    end
end

-------------------------------------------------------------------------------
-- Layout refresh (for settings changes)
-------------------------------------------------------------------------------

function ST:RefreshIconLayout(categoryKey)
    local display = self.displayFrames[categoryKey];
    if (not display or not display.frame) then return; end
    if (not display.iconPool) then return; end
    local catDB = self:GetCategoryDB(categoryKey);

    local fontPath = ST._GetFontPath(catDB.font);
    local outline = catDB.fontOutline or "OUTLINE";
    local iconSize = catDB.iconSize;

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
            local attachMode = catDB.attachMode or "free";
            local suffix = (attachMode == "party") and " (party frames preview)" or " (unlocked)";
            display.title.text:SetText("|cFFe6c619" .. label .. suffix .. "|r");
        end
    end

    for _, ico in ipairs(display.iconPool) do
        ico:SetSize(iconSize, iconSize);
    end

    for _, lbl in ipairs(display.namePool) do
        lbl:SetFont(fontPath, 11, outline);
    end

    -- Re-render to apply new layout
    ST._RenderIconCategory(categoryKey);
end
