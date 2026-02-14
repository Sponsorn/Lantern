local ADDON_NAME, NS = ...;
local ST = NS.SpellTracker;
if (not ST) then return; end

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true);
local SOLID = "Interface\\BUTTONS\\WHITE8X8";

-------------------------------------------------------------------------------
-- Display frame storage
-------------------------------------------------------------------------------

ST.displayFrames = {};  -- categoryKey -> { frame, title, barPool }

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function GetFontPath(fontName)
    if (LSM) then
        local path = LSM:Fetch("font", fontName);
        if (path) then return path; end
    end
    return "Fonts\\FRIZQT__.TTF";
end

local function FormatTime(seconds)
    if (seconds <= 0) then return ""; end
    if (seconds < 10) then return string.format("%.1f", seconds); end
    if (seconds < 60) then return string.format("%.0f", seconds); end
    return string.format("%d:%02d", math.floor(seconds / 60), math.floor(seconds % 60));
end

-------------------------------------------------------------------------------
-- Section 1b: Party frame lookup helpers (for attached mode)
-------------------------------------------------------------------------------

local function GetPartyMemberFrame(unitToken)
    local useRaid = EditModeManagerFrame
        and EditModeManagerFrame.UseRaidStylePartyFrames
        and EditModeManagerFrame:UseRaidStylePartyFrames();

    if (useRaid) then
        -- CompactPartyFrame: static frames with .unit property (includes "player")
        for i = 1, 5 do
            local frame = _G["CompactPartyFrameMember" .. i];
            if (frame and frame.unit == unitToken and frame:IsShown()) then
                return frame;
            end
        end
    else
        -- Modern PartyFrame: pool-based with .unitToken
        if (PartyFrame and PartyFrame.MemberFrames) then
            for _, memberFrame in pairs(PartyFrame.MemberFrames) do
                if (memberFrame.unitToken == unitToken and memberFrame:IsShown()) then
                    return memberFrame;
                end
            end
        end
    end
    return nil;
end

local function BuildNameToUnitMap()
    local map = {};
    -- Include self (shown in raid-style party frames)
    if (ST.playerName) then
        map[ST.playerName] = "player";
    end
    for i = 1, 4 do
        local unit = "party" .. i;
        if (UnitExists(unit)) then
            local name = UnitName(unit);
            if (name) then map[name] = unit; end
        end
    end
    return map;
end

-------------------------------------------------------------------------------
-- Section 2: Bar frame creation per category
-------------------------------------------------------------------------------

local BAR_POOL_SIZE = 20;  -- max rows per category (5 players * up to 4 spells)

local function SavePosition(categoryKey)
    local display = ST.displayFrames[categoryKey];
    if (not display or not display.frame) then return; end
    local point, _, relativePoint, x, y = display.frame:GetPoint();
    local catDB = ST:GetCategoryDB(categoryKey);
    catDB.position = { point = point, relativePoint = relativePoint, x = x, y = y };
end

local function RestorePosition(categoryKey)
    local display = ST.displayFrames[categoryKey];
    if (not display or not display.frame) then return; end
    local catDB = ST:GetCategoryDB(categoryKey);
    if (catDB.position) then
        local p = catDB.position;
        display.frame:ClearAllPoints();
        display.frame:SetPoint(p.point or "CENTER", UIParent, p.relativePoint or "CENTER", p.x or 0, p.y or -150);
    end
end

local function BuildBarFrame(categoryKey)
    if (ST.displayFrames[categoryKey]) then return; end
    local catDB = ST:GetCategoryDB(categoryKey);
    local cat = ST:GetCategory(categoryKey);
    local label = cat and cat.label or categoryKey;

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
        SavePosition(categoryKey);
    end);
    frame:SetAlpha(catDB.barAlpha);

    -- Title bar (visible when unlocked)
    local title = CreateFrame("Frame", nil, frame);
    title:SetHeight(18);
    title:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 2);
    title:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, 2);
    title:EnableMouse(true);
    title:RegisterForDrag("LeftButton");
    title:SetScript("OnDragStart", function() frame:StartMoving(); end);
    title:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing();
        SavePosition(categoryKey);
    end);

    local titleBg = title:CreateTexture(nil, "BACKGROUND");
    titleBg:SetAllPoints();
    titleBg:SetTexture(SOLID);
    titleBg:SetVertexColor(0.1, 0.1, 0.1, 0.8);

    local titleText = title:CreateFontString(nil, "OVERLAY");
    titleText:SetFont(GetFontPath(catDB.font), 12, catDB.fontOutline or "OUTLINE");
    titleText:SetPoint("CENTER", 0, 0);
    titleText:SetText("|cFFe6c619" .. label .. " (unlocked)|r");
    title.text = titleText;

    if (catDB.locked) then title:Hide(); end

    -- Bar pool
    local bh = math.max(12, catDB.barHeight);
    local iconSize = bh;
    local barW = math.max(60, catDB.barWidth - iconSize);
    local nameFontSize = math.max(9, math.floor(bh * 0.45));
    local cdFontSize = math.max(10, math.floor(bh * 0.55));
    local fontPath = GetFontPath(catDB.font);
    local outline = catDB.fontOutline or "OUTLINE";

    local barPool = {};
    for i = 1, BAR_POOL_SIZE do
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
        barBg:SetTexture(SOLID);
        barBg:SetVertexColor(0.15, 0.15, 0.15, 1);
        row.barBg = barBg;

        local sb = CreateFrame("StatusBar", nil, row);
        sb:SetPoint("TOPLEFT", iconSize, 0);
        sb:SetPoint("BOTTOMRIGHT", 0, 0);
        sb:SetStatusBarTexture(SOLID);
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

    RestorePosition(categoryKey);
    frame:Hide();
end

-------------------------------------------------------------------------------
-- Section 3: Collect sorted entries for a category
-------------------------------------------------------------------------------

local function CollectSortedEntries(categoryKey)
    local catDB = ST:GetCategoryDB(categoryKey);
    local filter = catDB.filter or (ST:GetCategory(categoryKey) and ST:GetCategory(categoryKey).defaultFilter) or "all";
    local entries = {};
    local now = GetTime();

    for playerName, player in pairs(ST.trackedPlayers) do
        local isSelf = (playerName == ST.playerName);
        if (isSelf and not catDB.showSelf) then
            -- Skip self if showSelf is off
        else
            for spellID, spellState in pairs(player.spells) do
                if (spellState.category == categoryKey) then
                    -- Apply filter
                    local include = true;
                    if (filter == "hide_ready" and spellState.state == "ready") then
                        include = false;
                    elseif (filter == "active_only" and spellState.state ~= "active") then
                        include = false;
                    end

                    if (include) then
                        local remaining = 0;
                        if (spellState.state == "cooldown") then
                            remaining = math.max(0, spellState.cdEnd - now);
                        elseif (spellState.state == "active") then
                            remaining = math.max(0, spellState.activeEnd - now);
                        end

                        table.insert(entries, {
                            name      = playerName,
                            class     = player.class,
                            spellID   = spellID,
                            baseCd    = spellState.baseCd,
                            remaining = remaining,
                            state     = spellState.state,
                            isSelf    = isSelf,
                        });
                    end
                end
            end
        end
    end

    -- Sort
    local selfOnTop = catDB.selfOnTop;
    local sortByBaseCd = (catDB.sortMode == "basecd");

    table.sort(entries, function(a, b)
        if (selfOnTop) then
            if (a.isSelf ~= b.isSelf) then return a.isSelf; end
        end
        -- Ready first, then active, then cooldown
        local stateOrder = { ready = 0, active = 1, cooldown = 2 };
        local aOrder = stateOrder[a.state] or 3;
        local bOrder = stateOrder[b.state] or 3;
        if (aOrder ~= bOrder) then return aOrder < bOrder; end
        if (sortByBaseCd) then return a.baseCd < b.baseCd; end
        return a.remaining < b.remaining;
    end);

    return entries;
end

-------------------------------------------------------------------------------
-- Section 4: Render bar mode for a category
-------------------------------------------------------------------------------

local function RenderBarCategory(categoryKey)
    local display = ST.displayFrames[categoryKey];
    if (not display or not display.frame) then return; end
    local catDB = ST:GetCategoryDB(categoryKey);
    local bh = math.max(12, catDB.barHeight);

    local entries = CollectSortedEntries(categoryKey);

    for i = 1, BAR_POOL_SIZE do
        local bar = display.barPool[i];
        local entry = entries[i];

        if (entry) then
            bar:Show();

            -- Icon: use C_Spell.GetSpellTexture for runtime icon lookup
            local ok, tex = pcall(C_Spell.GetSpellTexture, entry.spellID);
            if (ok and tex) then
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
                bar.cdText:SetText(FormatTime(entry.remaining));
                bar.cdText:SetTextColor(1, 0.9, 0.3);
            elseif (entry.state == "cooldown") then
                -- Class-colored bar, CD countdown
                bar.cdBar:SetMinMaxValues(0, entry.baseCd);
                bar.cdBar:SetValue(entry.remaining);
                bar.cdBar:SetStatusBarColor(cr, cg, cb, 0.85);
                bar.barBg:SetVertexColor(cr * 0.25, cg * 0.25, cb * 0.25, 1);
                bar.cdText:SetText(FormatTime(entry.remaining));
                bar.cdText:SetTextColor(1, 1, 1);
            end
        else
            bar:Hide();
        end
    end

    local numVisible = math.min(#entries, BAR_POOL_SIZE);
    if (numVisible > 0) then
        display.frame:SetHeight(numVisible * (bh + 1) + 2);
    end
end

-------------------------------------------------------------------------------
-- Section 4b: Icon frame creation per category
-------------------------------------------------------------------------------

local ICON_POOL_SIZE = 40;  -- max spell icons across all players

local function CreateSpellIcon(parent, size)
    local frame = CreateFrame("Frame", nil, parent);
    frame:SetSize(size, size);

    local icon = frame:CreateTexture(nil, "ARTWORK");
    icon:SetAllPoints();
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92);
    frame.icon = icon;

    -- Cooldown swipe overlay
    local cd = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate");
    cd:SetAllPoints();
    cd:SetDrawEdge(false);
    cd:SetHideCountdownNumbers(true);
    frame.cooldown = cd;

    -- Duration/CD text overlay
    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
    text:SetPoint("CENTER", 0, 0);
    text:SetShadowOffset(1, -1);
    text:SetShadowColor(0, 0, 0, 1);
    frame.text = text;

    -- Glow border for active state
    local glow = frame:CreateTexture(nil, "OVERLAY");
    glow:SetPoint("TOPLEFT", -2, 2);
    glow:SetPoint("BOTTOMRIGHT", 2, -2);
    glow:SetTexture("Interface\\BUTTONS\\WHITE8X8");
    glow:SetVertexColor(0.9, 0.77, 0.1, 0.6);  -- amber accent
    glow:Hide();
    frame.glow = glow;

    frame:Hide();
    return frame;
end

local function BuildIconFrame(categoryKey)
    if (ST.displayFrames[categoryKey]) then return; end
    local catDB = ST:GetCategoryDB(categoryKey);
    local cat = ST:GetCategory(categoryKey);
    local label = cat and cat.label or categoryKey;

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
        SavePosition(categoryKey);
    end);

    -- Title bar
    local title = CreateFrame("Frame", nil, frame);
    title:SetHeight(18);
    title:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 2);
    title:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, 2);
    title:EnableMouse(true);
    title:RegisterForDrag("LeftButton");
    title:SetScript("OnDragStart", function() frame:StartMoving(); end);
    title:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing();
        SavePosition(categoryKey);
    end);

    local titleBg = title:CreateTexture(nil, "BACKGROUND");
    titleBg:SetAllPoints();
    titleBg:SetTexture(SOLID);
    titleBg:SetVertexColor(0.1, 0.1, 0.1, 0.8);

    local titleText = title:CreateFontString(nil, "OVERLAY");
    titleText:SetFont(GetFontPath(catDB.font), 12, catDB.fontOutline or "OUTLINE");
    titleText:SetPoint("CENTER", 0, 0);
    titleText:SetText("|cFFe6c619" .. label .. " (unlocked)|r");
    title.text = titleText;

    if (catDB.locked) then title:Hide(); end

    -- Pre-create icon pool and name label pool
    local iconPool = {};
    for i = 1, ICON_POOL_SIZE do
        iconPool[i] = CreateSpellIcon(frame, catDB.iconSize);
    end

    local namePool = {};
    for i = 1, 5 do
        local nameLabel = frame:CreateFontString(nil, "OVERLAY");
        nameLabel:SetFont(GetFontPath(catDB.font), 12, catDB.fontOutline or "OUTLINE");
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

    RestorePosition(categoryKey);
    frame:Hide();
end

-------------------------------------------------------------------------------
-- Section 4c: Render icon mode for a category
-------------------------------------------------------------------------------

local function RenderIconCategory(categoryKey)
    local display = ST.displayFrames[categoryKey];
    if (not display or not display.frame) then return; end
    if (not display.iconPool) then return; end
    local catDB = ST:GetCategoryDB(categoryKey);
    local iconSize = catDB.iconSize;
    local spacing = catDB.iconSpacing;
    local showNames = catDB.showNames;
    local fontPath = GetFontPath(catDB.font);
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
        if (isSelf and not catDB.showSelf) then
            -- skip
        else
            local spells = {};
            for spellID, spellState in pairs(player.spells) do
                if (spellState.category == categoryKey) then
                    local include = true;
                    if (filter == "hide_ready" and spellState.state == "ready") then
                        include = false;
                    elseif (filter == "active_only" and spellState.state ~= "active") then
                        include = false;
                    end
                    if (include) then
                        table.insert(spells, {
                            spellID = spellID,
                            state = spellState.state,
                            cdEnd = spellState.cdEnd,
                            activeEnd = spellState.activeEnd,
                            baseCd = spellState.baseCd,
                        });
                    end
                end
            end
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
                lbl:SetPoint("BOTTOMLEFT", display.frame, "BOTTOMLEFT", 0, -y);
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
            if (iconIdx > ICON_POOL_SIZE) then break; end
            local ico = display.iconPool[iconIdx];
            ico:SetSize(iconSize, iconSize);

            -- Position
            ico:ClearAllPoints();
            if (growUp) then
                ico:SetPoint("BOTTOMLEFT", display.frame, "BOTTOMLEFT", x, -y);
            else
                ico:SetPoint("TOPLEFT", display.frame, "TOPLEFT", x, -y);
            end

            -- Icon texture
            local ok, tex = pcall(C_Spell.GetSpellTexture, spell.spellID);
            if (ok and tex) then
                ico.icon:SetTexture(tex);
            end

            -- State rendering
            if (spell.state == "ready") then
                ico.icon:SetDesaturated(false);
                ico.cooldown:Clear();
                ico.text:SetText("");
                ico.glow:Hide();
            elseif (spell.state == "active") then
                ico.icon:SetDesaturated(false);
                ico.cooldown:Clear();
                local remaining = math.max(0, spell.activeEnd - now);
                ico.text:SetText(FormatTime(remaining));
                ico.text:SetTextColor(1, 0.9, 0.3);
                ico.glow:Show();
            elseif (spell.state == "cooldown") then
                ico.icon:SetDesaturated(true);
                -- Set cooldown swipe
                local remaining = math.max(0, spell.cdEnd - now);
                if (remaining > 0) then
                    ico.cooldown:SetCooldown(spell.cdEnd - spell.baseCd, spell.baseCd);
                else
                    ico.cooldown:Clear();
                end
                ico.text:SetText(FormatTime(remaining));
                ico.text:SetTextColor(1, 1, 1);
                ico.glow:Hide();
            end

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
-- Section 4d: Attached mode — per-player containers on party frames
-------------------------------------------------------------------------------

local ATTACHED_ICON_POOL_SIZE = 8;

ST.attachedContainers = {};  -- [categoryKey][unitToken] = { frame, iconPool = {} }

local function GetOrCreateAttachedContainer(categoryKey, unitToken, parentFrame)
    if (not ST.attachedContainers[categoryKey]) then
        ST.attachedContainers[categoryKey] = {};
    end

    local existing = ST.attachedContainers[categoryKey][unitToken];
    if (existing and existing.frame) then
        return existing;
    end

    local catDB = ST:GetCategoryDB(categoryKey);
    local iconSize = catDB.iconSize;

    -- Parent to UIParent to avoid secure frame taint
    local container = CreateFrame("Frame", nil, UIParent);
    container:SetSize(iconSize, iconSize);
    container:SetFrameStrata("MEDIUM");
    container:SetFrameLevel(parentFrame:GetFrameLevel() + 10);

    -- Icon pool
    local iconPool = {};
    for i = 1, ATTACHED_ICON_POOL_SIZE do
        iconPool[i] = CreateSpellIcon(container, iconSize);
    end

    local entry = {
        frame    = container,
        iconPool = iconPool,
    };
    ST.attachedContainers[categoryKey][unitToken] = entry;
    return entry;
end

local function AnchorAttachedContainer(container, parentFrame, catDB)
    container.frame:ClearAllPoints();
    local anchor = catDB.attachAnchor or "RIGHT";
    local ox = catDB.attachOffsetX or 2;
    local oy = catDB.attachOffsetY or 0;

    if (anchor == "LEFT") then
        container.frame:SetPoint("RIGHT", parentFrame, "LEFT", -ox, oy);
    elseif (anchor == "BOTTOM") then
        container.frame:SetPoint("TOP", parentFrame, "BOTTOM", ox, -oy);
    else  -- "RIGHT" (default)
        container.frame:SetPoint("LEFT", parentFrame, "RIGHT", ox, oy);
    end
end

local function RenderAttachedCategory(categoryKey)
    local catDB = ST:GetCategoryDB(categoryKey);
    local filter = catDB.filter or (ST:GetCategory(categoryKey) and ST:GetCategory(categoryKey).defaultFilter) or "all";
    local iconSize = catDB.iconSize;
    local spacing = catDB.iconSpacing;
    local nameToUnit = BuildNameToUnitMap();
    local now = GetTime();

    -- Track which units we rendered so we can hide the rest
    local renderedUnits = {};

    for playerName, player in pairs(ST.trackedPlayers) do
        local isSelf = (playerName == ST.playerName);
        if (isSelf and not catDB.showSelf) then
            -- skip self
        else
            -- Collect this player's spells for this category
            local spells = {};
            for spellID, spellState in pairs(player.spells) do
                if (spellState.category == categoryKey) then
                    local include = true;
                    if (filter == "hide_ready" and spellState.state == "ready") then
                        include = false;
                    elseif (filter == "active_only" and spellState.state ~= "active") then
                        include = false;
                    end
                    if (include) then
                        table.insert(spells, {
                            spellID   = spellID,
                            state     = spellState.state,
                            cdEnd     = spellState.cdEnd,
                            activeEnd = spellState.activeEnd,
                            baseCd    = spellState.baseCd,
                        });
                    end
                end
            end

            if (#spells > 0) then
                local unitToken = nameToUnit[playerName];
                if (unitToken) then
                    local partyFrame = GetPartyMemberFrame(unitToken);
                    if (partyFrame) then
                        renderedUnits[unitToken] = true;
                        local container = GetOrCreateAttachedContainer(categoryKey, unitToken, partyFrame);

                        -- Re-anchor (party frames can move)
                        AnchorAttachedContainer(container, partyFrame, catDB);

                        -- Resize icons to match current setting
                        for _, ico in ipairs(container.iconPool) do
                            ico:SetSize(iconSize, iconSize);
                            ico:Hide();
                        end

                        -- Render spell icons (grow direction matches anchor side)
                        local anchor = catDB.attachAnchor or "RIGHT";
                        local growLeft = (anchor == "LEFT");
                        local x = 0;
                        for idx, spell in ipairs(spells) do
                            if (idx > ATTACHED_ICON_POOL_SIZE) then break; end
                            local ico = container.iconPool[idx];
                            ico:ClearAllPoints();
                            if (growLeft) then
                                ico:SetPoint("TOPRIGHT", -x, 0);
                            else
                                ico:SetPoint("TOPLEFT", x, 0);
                            end

                            -- Icon texture
                            local ok, tex = pcall(C_Spell.GetSpellTexture, spell.spellID);
                            if (ok and tex) then
                                ico.icon:SetTexture(tex);
                            end

                            -- State rendering (same logic as RenderIconCategory)
                            if (spell.state == "ready") then
                                ico.icon:SetDesaturated(false);
                                ico.cooldown:Clear();
                                ico.text:SetText("");
                                ico.glow:Hide();
                            elseif (spell.state == "active") then
                                ico.icon:SetDesaturated(false);
                                ico.cooldown:Clear();
                                local remaining = math.max(0, spell.activeEnd - now);
                                ico.text:SetText(FormatTime(remaining));
                                ico.text:SetTextColor(1, 0.9, 0.3);
                                ico.glow:Show();
                            elseif (spell.state == "cooldown") then
                                ico.icon:SetDesaturated(true);
                                local remaining = math.max(0, spell.cdEnd - now);
                                if (remaining > 0) then
                                    ico.cooldown:SetCooldown(spell.cdEnd - spell.baseCd, spell.baseCd);
                                else
                                    ico.cooldown:Clear();
                                end
                                ico.text:SetText(FormatTime(remaining));
                                ico.text:SetTextColor(1, 1, 1);
                                ico.glow:Hide();
                            end

                            ico:Show();
                            x = x + iconSize + spacing;
                        end

                        -- Resize container to fit icons
                        local numIcons = math.min(#spells, ATTACHED_ICON_POOL_SIZE);
                        if (numIcons > 0) then
                            container.frame:SetSize(numIcons * (iconSize + spacing) - spacing, iconSize);
                        end
                        container.frame:Show();
                    end
                end
            end
        end
    end

    -- Hide containers for units no longer shown
    if (ST.attachedContainers[categoryKey]) then
        for unitToken, container in pairs(ST.attachedContainers[categoryKey]) do
            if (not renderedUnits[unitToken] and container.frame) then
                container.frame:Hide();
            end
        end
    end
end

local function StackAttachedContainers()
    -- Collect all attached category keys and group by anchor side
    local unitContainers = {};  -- [unitToken] = { { categoryKey, container }, ... }

    for _, entry in ipairs(ST.categories) do
        local key = entry.key;
        local catDB = ST:GetCategoryDB(key);
        if (entry.config.enabled and catDB.attachMode == "party" and ST.attachedContainers[key]) then
            for unitToken, container in pairs(ST.attachedContainers[key]) do
                if (container.frame and container.frame:IsShown()) then
                    if (not unitContainers[unitToken]) then
                        unitContainers[unitToken] = {};
                    end
                    table.insert(unitContainers[unitToken], {
                        key       = key,
                        container = container,
                        catDB     = catDB,
                    });
                end
            end
        end
    end

    -- Stack containers per unit
    for unitToken, containers in pairs(unitContainers) do
        if (#containers > 1) then
            local partyFrame = GetPartyMemberFrame(unitToken);
            if (partyFrame) then
                -- First container anchors to party frame (already done), subsequent stack
                for i = 2, #containers do
                    local prev = containers[i - 1];
                    local curr = containers[i];
                    local growDir = curr.catDB.attachGrowDir or "DOWN";

                    local anchor = curr.catDB.attachAnchor or "RIGHT";
                    local sp = curr.catDB.iconSpacing or 2;

                    curr.container.frame:ClearAllPoints();
                    if (growDir == "RIGHT") then
                        if (anchor == "LEFT") then
                            curr.container.frame:SetPoint("TOPRIGHT", prev.container.frame, "TOPLEFT", -sp, 0);
                        else
                            curr.container.frame:SetPoint("TOPLEFT", prev.container.frame, "TOPRIGHT", sp, 0);
                        end
                    else  -- "DOWN"
                        if (anchor == "LEFT") then
                            curr.container.frame:SetPoint("TOPRIGHT", prev.container.frame, "BOTTOMRIGHT", 0, -sp);
                        else
                            curr.container.frame:SetPoint("TOPLEFT", prev.container.frame, "BOTTOMLEFT", 0, -sp);
                        end
                    end
                end
            end
        end
    end
end

local function HideAttachedContainers(categoryKey)
    if (categoryKey) then
        -- Hide containers for a specific category
        if (ST.attachedContainers[categoryKey]) then
            for _, container in pairs(ST.attachedContainers[categoryKey]) do
                if (container.frame) then container.frame:Hide(); end
            end
        end
    else
        -- Hide all attached containers
        for key, units in pairs(ST.attachedContainers) do
            for _, container in pairs(units) do
                if (container.frame) then container.frame:Hide(); end
            end
        end
    end
end

-- Expose for external use (Options.lua cleanup)
function ST:HideAttachedContainers(categoryKey)
    HideAttachedContainers(categoryKey);
end

-------------------------------------------------------------------------------
-- Section 5: Visibility and RefreshDisplay
-------------------------------------------------------------------------------

local function ShouldBeVisible()
    return IsInGroup() and not IsInRaid();
end

function ST:RefreshDisplay()
    -- Auto-disable preview when settings panel closes
    if (ST._previewActive) then
        local panelOpen = false;
        if (SettingsPanel and SettingsPanel:IsShown()) then panelOpen = true; end
        local uxPanel = _G["LanternSettingsPanel"];
        if (uxPanel and uxPanel:IsShown()) then panelOpen = true; end
        local mtPanel = _G["LanternMythicTrackerOptions"];
        if (mtPanel and mtPanel:IsShown()) then panelOpen = true; end
        if (not panelOpen) then
            ST:DeactivatePreview();
            return;
        end
    end

    local show = ShouldBeVisible() or ST._previewActive;
    local hasAttached = false;

    for _, entry in ipairs(self.categories) do
        local key = entry.key;
        local catDB = self:GetCategoryDB(key);
        local layout = catDB.layout or entry.config.defaultLayout or "bar";
        local attachMode = catDB.attachMode or "free";

        if (entry.config.enabled and show) then
            -- Attached mode: anchor icons to party frames (falls back to free during preview)
            if (attachMode == "party" and not ST._previewActive) then
                -- Hide the monolithic free-floating frame
                local display = self.displayFrames[key];
                if (display and display.frame) then
                    display.frame:Hide();
                end
                RenderAttachedCategory(key);
                hasAttached = true;
            else
                -- Free-floating mode (or preview fallback)
                HideAttachedContainers(key);
                if (layout == "bar") then
                    BuildBarFrame(key);
                    local display = self.displayFrames[key];
                    if (display and display.frame) then
                        display.frame:Show();
                    end
                    RenderBarCategory(key);
                elseif (layout == "icon") then
                    BuildIconFrame(key);
                    local display = self.displayFrames[key];
                    if (display and display.frame) then
                        display.frame:Show();
                    end
                    RenderIconCategory(key);
                end
            end
        else
            local display = self.displayFrames[key];
            if (display and display.frame) then
                display.frame:Hide();
            end
            HideAttachedContainers(key);
        end
    end

    if (hasAttached) then
        StackAttachedContainers();
    end

    self:ApplyDocking();
end

-------------------------------------------------------------------------------
-- Section 6: Layout refresh (for settings changes)
-------------------------------------------------------------------------------

function ST:RefreshBarLayout(categoryKey)
    local display = self.displayFrames[categoryKey];
    if (not display or not display.frame) then return; end
    local catDB = self:GetCategoryDB(categoryKey);

    local fontPath = GetFontPath(catDB.font);
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

    for i = 1, BAR_POOL_SIZE do
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

function ST:RefreshIconLayout(categoryKey)
    local display = self.displayFrames[categoryKey];
    if (not display or not display.frame) then return; end
    if (not display.iconPool) then return; end
    local catDB = self:GetCategoryDB(categoryKey);

    local fontPath = GetFontPath(catDB.font);
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
            display.title.text:SetText("|cFFe6c619" .. label .. " (unlocked)|r");
        end
    end

    for _, ico in ipairs(display.iconPool) do
        ico:SetSize(iconSize, iconSize);
    end

    for _, lbl in ipairs(display.namePool) do
        lbl:SetFont(fontPath, 11, outline);
    end

    -- Re-render to apply new layout
    RenderIconCategory(categoryKey);
end

-------------------------------------------------------------------------------
-- Section 7: Cleanup
-------------------------------------------------------------------------------

function ST:HideAllDisplays()
    for key, display in pairs(self.displayFrames) do
        if (display.frame) then
            display.frame:Hide();
        end
    end
    HideAttachedContainers();
end

function ST:ResetPosition(categoryKey)
    local display = self.displayFrames[categoryKey];
    if (not display or not display.frame) then return; end
    local catDB = self:GetCategoryDB(categoryKey);
    display.frame:ClearAllPoints();
    display.frame:SetPoint("CENTER", UIParent, "CENTER", 0, -150);
    catDB.position = nil;
end

-------------------------------------------------------------------------------
-- Preview Mode
-------------------------------------------------------------------------------

local PREVIEW_PLAYERS = {
    { name = "Thralldk",   class = "DEATHKNIGHT" },
    { name = "Jainalee",   class = "MAGE" },
    { name = "Sylvanash",  class = "ROGUE" },
    { name = "Garroshwar", class = "WARRIOR" },
};

local _previewTimer = nil;

function ST:ActivatePreview()
    ST._previewActive = true;

    -- Save real tracked players and replace with fake ones
    ST._savedTrackedPlayers = ST.trackedPlayers;
    ST.trackedPlayers = {};

    for _, fake in ipairs(PREVIEW_PLAYERS) do
        local player = { class = fake.class, spec = nil, spells = {} };
        -- Add spells from all enabled categories for this class
        for _, entry in ipairs(ST.categories) do
            if (entry.config.enabled) then
                local classSpells = ST:GetSpellsForClassAndCategory(fake.class, nil, entry.key);
                for spellID, spell in pairs(classSpells) do
                    local cd = spell.cd;
                    if (spell.cdBySpec) then
                        -- Preview doesn't have real specs, just use default
                        cd = spell.cd;
                    end
                    player.spells[spellID] = {
                        category   = spell.category,
                        state      = "ready",
                        cdEnd      = 0,
                        activeEnd  = 0,
                        charges    = spell.charges or 1,
                        maxCharges = spell.charges or 1,
                        baseCd     = cd,
                    };
                end
            end
        end
        ST.trackedPlayers[fake.name] = player;
    end

    -- Start simulation ticker
    if (_previewTimer) then _previewTimer:Cancel(); end
    _previewTimer = C_Timer.NewTicker(2, function()
        if (not ST._previewActive) then
            if (_previewTimer) then _previewTimer:Cancel(); _previewTimer = nil; end
            return;
        end
        local now = GetTime();
        for _, player in pairs(ST.trackedPlayers) do
            for spellID, spellState in pairs(player.spells) do
                if (spellState.state == "ready" and math.random() < 0.3) then
                    local spellData = ST.spellDB[spellID];
                    if (spellData and spellData.duration) then
                        spellState.state = "active";
                        spellState.activeEnd = now + spellData.duration;
                        spellState.cdEnd = now + spellState.baseCd;
                    else
                        spellState.state = "cooldown";
                        spellState.cdEnd = now + spellState.baseCd;
                    end
                end
            end
        end
    end);

    -- Force display refresh
    ST:RefreshDisplay();
end

function ST:DeactivatePreview()
    ST._previewActive = false;
    if (_previewTimer) then _previewTimer:Cancel(); _previewTimer = nil; end

    -- Restore real tracked players
    if (ST._savedTrackedPlayers) then
        ST.trackedPlayers = ST._savedTrackedPlayers;
        ST._savedTrackedPlayers = nil;
    else
        ST.trackedPlayers = {};
    end

    ST:RefreshDisplay();
end

-------------------------------------------------------------------------------
-- Docking
-------------------------------------------------------------------------------

function ST:ApplyDocking()
    for _, entry in ipairs(self.categories) do
        local key = entry.key;
        local catDB = self:GetCategoryDB(key);
        local display = self.displayFrames[key];
        if (not display or not display.frame) then
            -- skip, frame not built yet
        elseif (catDB.dockTo and catDB.dockTo ~= "") then
            local targetDisplay = self.displayFrames[catDB.dockTo];
            if (targetDisplay and targetDisplay.frame) then
                display.frame:ClearAllPoints();
                display.frame:SetPoint("TOPLEFT", targetDisplay.frame, "BOTTOMLEFT", 0, -4);
                display.frame:SetMovable(false);
            end
        else
            -- Not docked, restore independent position
            display.frame:SetMovable(true);
            RestorePosition(key);
        end
    end
end
