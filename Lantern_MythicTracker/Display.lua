local ADDON_NAME, NS = ...;
local ST = NS.SpellTracker;
if (not ST) then return; end

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true);

-------------------------------------------------------------------------------
-- Shared constants (exported for sub-files)
-------------------------------------------------------------------------------

ST._SOLID = "Interface\\BUTTONS\\WHITE8X8";

ST._STATE_ORDER = { ready = 0, active = 1, cooldown = 2 };

ST._BAR_POOL_SIZE           = 20;  -- max rows per category (5 players * up to 4 spells)
ST._ICON_POOL_SIZE          = 40;  -- max spell icons across all players
ST._ATTACHED_ICON_POOL_SIZE = 8;   -- max icons per player per category in attached mode

local _frameID = 0;
function ST._FrameName(tag)
    _frameID = _frameID + 1;
    return "LMT_" .. tag .. "_" .. _frameID;
end

-------------------------------------------------------------------------------
-- Display frame storage
-------------------------------------------------------------------------------

ST.displayFrames = {};      -- categoryKey -> { frame, title, barPool/iconPool/namePool }
ST.attachedContainers = {}; -- [categoryKey][unitToken] = { frame, iconPool = {} }

-- Preview state (declared early so functions below can capture the upvalues)
local _previewNameToUnit = {};   -- fake.name -> unit token during preview

-------------------------------------------------------------------------------
-- Shared helpers (exported for sub-files)
-------------------------------------------------------------------------------

-- Spell texture cache (textures don't change at runtime)
local _textureCache = {};

function ST._GetSpellTexture(spellID)
    local cached = _textureCache[spellID];
    if (cached ~= nil) then return cached; end
    local ok, tex = pcall(C_Spell.GetSpellTexture, spellID);
    local result = (ok and tex) or nil;
    _textureCache[spellID] = result or false;
    return result;
end

function ST._GetFontPath(fontName)
    if (LSM) then
        local path = LSM:Fetch("font", fontName);
        if (path) then return path; end
    end
    return "Fonts\\FRIZQT__.TTF";
end

function ST._FormatTime(seconds)
    if (seconds <= 0) then return ""; end
    if (seconds < 10) then return string.format("%.1f", seconds); end
    if (seconds < 60) then return string.format("%.0f", seconds); end
    return string.format("%d:%02d", math.floor(seconds / 60), math.floor(seconds % 60));
end

function ST._ApplyIconState(ico, state, spellID, cdEnd, activeEnd, baseCd, now)
    local tex = ST._GetSpellTexture(spellID);
    if (tex) then ico.icon:SetTexture(tex); end

    if (state == "ready") then
        ico.icon:SetDesaturated(false);
        ico.cooldown:Clear();
        ico.text:SetText("");
        ico.glow:Hide();
    elseif (state == "active") then
        ico.icon:SetDesaturated(false);
        ico.cooldown:Clear();
        local remaining = math.max(0, activeEnd - now);
        ico.text:SetText(ST._FormatTime(remaining));
        ico.text:SetTextColor(1, 0.9, 0.3);
        ico.glow:Show();
    elseif (state == "cooldown") then
        ico.icon:SetDesaturated(true);
        local remaining = math.max(0, cdEnd - now);
        if (remaining > 0) then
            ico.cooldown:SetCooldown(cdEnd - baseCd, baseCd);
        else
            ico.cooldown:Clear();
        end
        ico.text:SetText(ST._FormatTime(remaining));
        ico.text:SetTextColor(1, 1, 1);
        ico.glow:Hide();
    end
end

function ST._CollectPlayerCategorySpells(player, categoryKey, filter, catDB)
    local spells = {};
    for spellID, spellState in pairs(player.spells) do
        if (spellState.category == categoryKey) then
            local include = true;
            if (filter == "hide_ready" and spellState.state == "ready") then
                include = false;
            elseif (filter == "active_only" and spellState.state ~= "active") then
                include = false;
            end
            if (include and catDB and catDB.disabledSpells[spellID]) then
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
    return spells;
end

-- Reusable table for CollectSortedEntries (reduce per-tick allocations)
local _sortEntries = {};

function ST._CollectSortedEntries(categoryKey)
    local catDB = ST:GetCategoryDB(categoryKey);
    local filter = catDB.filter or (ST:GetCategory(categoryKey) and ST:GetCategory(categoryKey).defaultFilter) or "all";
    wipe(_sortEntries);
    local entries = _sortEntries;
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
                    if (include and catDB.disabledSpells[spellID]) then
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
    local STATE_ORDER = ST._STATE_ORDER;

    table.sort(entries, function(a, b)
        if (selfOnTop) then
            if (a.isSelf ~= b.isSelf) then return a.isSelf; end
        end
        local aOrder = STATE_ORDER[a.state] or 3;
        local bOrder = STATE_ORDER[b.state] or 3;
        if (aOrder ~= bOrder) then return aOrder < bOrder; end
        if (sortByBaseCd) then return a.baseCd < b.baseCd; end
        return a.remaining < b.remaining;
    end);

    return entries;
end

-------------------------------------------------------------------------------
-- Position persistence
-------------------------------------------------------------------------------

function ST._SavePosition(categoryKey)
    local display = ST.displayFrames[categoryKey];
    if (not display or not display.frame) then return; end
    local point, _, relativePoint, x, y = display.frame:GetPoint();
    local catDB = ST:GetCategoryDB(categoryKey);
    catDB.position = { point = point, relativePoint = relativePoint, x = x, y = y };
end

function ST._RestorePosition(categoryKey)
    local display = ST.displayFrames[categoryKey];
    if (not display or not display.frame) then return; end
    local catDB = ST:GetCategoryDB(categoryKey);
    if (catDB.position) then
        local p = catDB.position;
        display.frame:ClearAllPoints();
        display.frame:SetPoint(p.point or "CENTER", UIParent, p.relativePoint or "CENTER", p.x or 0, p.y or -150);
    end
end

-------------------------------------------------------------------------------
-- Shared frame factories
-------------------------------------------------------------------------------

function ST._CreateSpellIcon(parent, size)
    local frame = CreateFrame("Frame", ST._FrameName("SpellIcon"), parent);
    frame:SetSize(size, size);

    local icon = frame:CreateTexture(nil, "ARTWORK");
    icon:SetAllPoints();
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92);
    frame.icon = icon;

    -- Cooldown swipe overlay
    local cd = CreateFrame("Cooldown", ST._FrameName("IconCooldown"), frame, "CooldownFrameTemplate");
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

    -- Border glow for active state
    local glow = CreateFrame("Frame", ST._FrameName("IconGlow"), frame, "BackdropTemplate");
    glow:SetPoint("TOPLEFT", -2, 2);
    glow:SetPoint("BOTTOMRIGHT", 2, -2);
    glow:SetFrameLevel(frame:GetFrameLevel() + 2);
    glow:SetBackdrop({ edgeFile = ST._SOLID, edgeSize = 2 });
    glow:SetBackdropBorderColor(0.9, 0.77, 0.1, 1);
    glow:Hide();
    frame.glow = glow;

    frame:Hide();
    return frame;
end

function ST._CreateTitleBar(frame, categoryKey, catDB)
    local cat = ST:GetCategory(categoryKey);
    local label = cat and cat.label or categoryKey;

    local title = CreateFrame("Frame", ST._FrameName("TitleBar"), frame);
    title:SetHeight(18);
    title:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 2);
    title:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, 2);
    title:EnableMouse(true);
    title:RegisterForDrag("LeftButton");
    title:SetScript("OnDragStart", function() frame:StartMoving(); end);
    title:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing();
        ST._SavePosition(categoryKey);
    end);

    local titleBg = title:CreateTexture(nil, "BACKGROUND");
    titleBg:SetAllPoints();
    titleBg:SetTexture(ST._SOLID);
    titleBg:SetVertexColor(0.1, 0.1, 0.1, 0.8);

    local titleText = title:CreateFontString(nil, "OVERLAY");
    titleText:SetFont(ST._GetFontPath(catDB.font), 12, catDB.fontOutline or "OUTLINE");
    titleText:SetPoint("CENTER", 0, 0);
    local attachMode = catDB.attachMode or "free";
    local suffix = (attachMode == "party") and " (party frames preview)" or " (unlocked)";
    titleText:SetText("|cFFe6c619" .. label .. suffix .. "|r");
    title.text = titleText;

    if (catDB.locked) then title:Hide(); end

    return title;
end

-------------------------------------------------------------------------------
-- Party frame lookup helpers (for attached mode)
-------------------------------------------------------------------------------

function ST._GetPartyMemberFrame(unitToken)
    -- During preview, find visible party frames by slot index
    -- Edit Mode shows CompactPartyFrameMembers with "player" as unit for all slots
    if (ST._previewActive) then
        local slot = tonumber(unitToken:match("^previewslot(%d+)$"));
        if (slot) then
            -- Try raid-style CompactPartyFrame members
            local frame = _G["CompactPartyFrameMember" .. slot];
            if (frame and frame:IsShown()) then return frame; end
            -- Try non-raid-style PartyFrame members
            if (PartyFrame and PartyFrame.MemberFrames) then
                local mf = PartyFrame.MemberFrames[slot];
                if (mf and mf:IsShown()) then return mf; end
            end
        end
        return nil;
    end

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

function ST._BuildNameToUnitMap()
    -- During preview, map fake players to visible party frame slots
    if (ST._previewActive) then
        if (next(_previewNameToUnit)) then
            return _previewNameToUnit;
        end
        return {};
    end

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
-- Visibility and RefreshDisplay (coordinator)
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
            -- Attached mode: anchor icons to party frames (uses fake frames during preview)
            if (attachMode == "party") then
                -- Hide the monolithic free-floating frame
                local display = self.displayFrames[key];
                if (display and display.frame) then
                    display.frame:Hide();
                end
                ST._RenderAttachedCategory(key);
                hasAttached = true;
            else
                -- Free-floating mode (or preview fallback)
                ST._HideAttachedContainers(key);
                if (layout == "bar") then
                    ST._BuildBarFrame(key);
                    local display = self.displayFrames[key];
                    if (display and display.frame) then
                        display.frame:Show();
                    end
                    ST._RenderBarCategory(key);
                elseif (layout == "icon") then
                    ST._BuildIconFrame(key);
                    local display = self.displayFrames[key];
                    if (display and display.frame) then
                        display.frame:Show();
                    end
                    ST._RenderIconCategory(key);
                end
            end
        else
            local display = self.displayFrames[key];
            if (display and display.frame) then
                display.frame:Hide();
            end
            ST._HideAttachedContainers(key);
        end
    end

    if (hasAttached) then
        ST._StackAttachedContainers();
    end

    self:ApplyDocking();
end

-------------------------------------------------------------------------------
-- Cleanup
-------------------------------------------------------------------------------

function ST:HideAllDisplays()
    for key, display in pairs(self.displayFrames) do
        if (display.frame) then
            display.frame:Hide();
        end
    end
    ST._HideAttachedContainers();
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
    { name = "Rexxar",     class = "HUNTER",  spec = 253 },  -- Beast Mastery
    { name = "Sylvanas",   class = "HUNTER",  spec = 254 },  -- Marksmanship
    { name = "Halduron",   class = "HUNTER",  spec = 255 },  -- Survival
    { name = "Zulara",     class = "SHAMAN",  spec = 264 },  -- Restoration
};

local _previewTimer = nil;

-- Scan for visible party frames and map fake player names to slot tokens
local function BuildPreviewPartyMapping()
    wipe(_previewNameToUnit);

    -- Count visible party frame slots
    local visibleSlots = {};
    for i = 1, 5 do
        local frame = _G["CompactPartyFrameMember" .. i];
        if (frame and frame:IsShown()) then
            table.insert(visibleSlots, i);
        end
    end
    -- Fallback: check non-raid-style PartyFrame
    if (#visibleSlots == 0 and PartyFrame and PartyFrame.MemberFrames) then
        for idx, mf in pairs(PartyFrame.MemberFrames) do
            if (mf and mf:IsShown()) then
                table.insert(visibleSlots, idx);
            end
        end
    end

    -- Map fake players to visible slots (as many as we have)
    local allNames = {};
    -- Self player first
    local playerName = ST.playerName or UnitName("player");
    if (playerName) then
        table.insert(allNames, playerName);
    end
    for _, fake in ipairs(PREVIEW_PLAYERS) do
        table.insert(allNames, fake.name);
    end

    for i, slot in ipairs(visibleSlots) do
        local name = allNames[i];
        if (name) then
            _previewNameToUnit[name] = "previewslot" .. slot;
        end
    end
end

function ST:ActivatePreview()
    ST._previewActive = true;

    -- Save real tracked players and replace with fake ones
    ST._savedTrackedPlayers = ST.trackedPlayers;
    ST.trackedPlayers = {};

    for _, fake in ipairs(PREVIEW_PLAYERS) do
        local player = { class = fake.class, spec = fake.spec, spells = {} };
        for _, entry in ipairs(ST.categories) do
            if (entry.config.enabled) then
                local classSpells = ST:GetSpellsForClassAndCategory(fake.class, fake.spec, entry.key);
                for spellID, spell in pairs(classSpells) do
                    player.spells[spellID] = {
                        category   = spell.category,
                        state      = "ready",
                        cdEnd      = 0,
                        activeEnd  = 0,
                        charges    = spell.charges or 1,
                        maxCharges = spell.charges or 1,
                        baseCd     = spell.cd,
                    };
                end
            end
        end
        ST.trackedPlayers[fake.name] = player;
    end

    -- Also add self player for attached mode preview
    local playerName = ST.playerName or UnitName("player");
    local playerClass = ST.playerClass or select(2, UnitClass("player"));
    local playerSpec = GetSpecializationInfo(GetSpecialization() or 0) or nil;
    if (playerName and playerClass) then
        local selfPlayer = { class = playerClass, spec = playerSpec, spells = {} };
        for _, entry in ipairs(ST.categories) do
            if (entry.config.enabled) then
                local classSpells = ST:GetSpellsForClassAndCategory(playerClass, playerSpec, entry.key);
                for spellID, spell in pairs(classSpells) do
                    selfPlayer.spells[spellID] = {
                        category   = spell.category,
                        state      = "ready",
                        cdEnd      = 0,
                        activeEnd  = 0,
                        charges    = spell.charges or 1,
                        maxCharges = spell.charges or 1,
                        baseCd     = spell.cd,
                    };
                end
            end
        end
        ST.trackedPlayers[playerName] = selfPlayer;
    end

    -- Start simulation ticker
    if (_previewTimer) then _previewTimer:Cancel(); end
    _previewTimer = C_Timer.NewTicker(2, function()
        if (not ST._previewActive) then
            if (_previewTimer) then _previewTimer:Cancel(); _previewTimer = nil; end
            return;
        end
        -- Refresh party frame mapping (Edit Mode frames may appear/disappear)
        BuildPreviewPartyMapping();

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
        -- Re-render (engine OnUpdate doesn't run during solo preview)
        ST:RefreshDisplay();
    end);

    -- Build initial party frame mapping
    BuildPreviewPartyMapping();

    -- Force display refresh
    ST:RefreshDisplay();
end

function ST:DeactivatePreview()
    ST._previewActive = false;
    if (_previewTimer) then _previewTimer:Cancel(); _previewTimer = nil; end
    wipe(_previewNameToUnit);

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
            -- Not docked, just ensure movable
            display.frame:SetMovable(true);
        end
    end
end
