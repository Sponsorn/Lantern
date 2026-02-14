local ADDON_NAME, Lantern = ...;
if (not Lantern or not Lantern.SpellTracker) then return; end
local ST = Lantern.SpellTracker;

-------------------------------------------------------------------------------
-- Taint Laundering
--
-- Party member spellIDs arrive tainted in UNIT_SPELLCAST_SUCCEEDED.
-- A StatusBar's OnValueChanged callback receives a clean copy from the
-- C++ engine, which strips taint. We use this to recover the real spellID.
-- These frames MUST be created at file scope (clean load-time context).
-------------------------------------------------------------------------------

local _launderResult = nil;
local _launderFrame = CreateFrame("StatusBar");
_launderFrame:SetMinMaxValues(0, 9999999);
_launderFrame:SetScript("OnValueChanged", function(_, val)
    _launderResult = val;
end);

local function LaunderSpellID(taintedID)
    _launderResult = nil;
    _launderFrame:SetValue(0);
    pcall(_launderFrame.SetValue, _launderFrame, taintedID);
    return _launderResult;
end

-- Pre-created watcher frames for party units (must be at file scope)
local _partyWatchers = {};
local _petWatchers = {};
for i = 1, 4 do
    _partyWatchers[i] = CreateFrame("Frame");
    _petWatchers[i] = CreateFrame("Frame");
end

-- Self-cast watcher frame (must be at file scope for clean context)
local _selfFrame = CreateFrame("Frame");

-- Inspect state
local _inspectPending = {};
local _inspectInProgress = false;
local _inspectCurrentUnit = nil;
local _inspectedNames = {};

-------------------------------------------------------------------------------
-- Register Player
--
-- Register all spells for a player's class across all enabled categories.
-- Populates ST.trackedPlayers with per-spell state entries.
-------------------------------------------------------------------------------

local function RegisterPlayer(name, class)
    if (ST.excludedPlayers[name]) then return; end

    if (not ST.trackedPlayers[name]) then
        ST.trackedPlayers[name] = { class = class, spec = nil, spells = {} };
    end

    local player = ST.trackedPlayers[name];
    player.class = class;

    for _, entry in ipairs(ST.categories) do
        if (entry.config.enabled) then
            local classSpells = ST:GetSpellsForClassAndCategory(class, player.spec, entry.key);
            for spellID, spell in pairs(classSpells) do
                if (not player.spells[spellID]) then
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
    end
end

-------------------------------------------------------------------------------
-- Identify Player Spells
--
-- Detects the player's current spec and registers all known spells from
-- enabled categories. Uses untainted APIs (IsSpellKnown, IsPlayerSpell)
-- since the player's own spell info is always clean.
-------------------------------------------------------------------------------

local function IdentifyPlayerSpells()
    local class = ST.playerClass;
    local name = ST.playerName;
    if (not class or not name) then return; end

    if (not ST.trackedPlayers[name]) then
        ST.trackedPlayers[name] = { class = class, spec = nil, spells = {} };
    end
    local player = ST.trackedPlayers[name];

    -- Detect current spec
    local specIndex = GetSpecialization();
    if (specIndex) then
        player.spec = GetSpecializationInfo(specIndex);
    end

    -- Register known spells across all enabled categories
    for _, entry in ipairs(ST.categories) do
        if (entry.config.enabled) then
            local classSpells = ST:GetSpellsForClassAndCategory(class, player.spec, entry.key);
            for spellID, spell in pairs(classSpells) do
                if (IsSpellKnown(spellID) or IsSpellKnown(spellID, true) or IsPlayerSpell(spellID)) then
                    if (not player.spells[spellID]) then
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
        end
    end
end

-------------------------------------------------------------------------------
-- Record Spell Cast
--
-- Called when a party member casts a tracked spell. Updates the spell's
-- state (charges, cooldown, active duration) and fires category hooks.
-------------------------------------------------------------------------------

local function RecordSpellCast(unit, spellID, name)
    if (not name or ST.excludedPlayers[name]) then return; end

    local resolvedID = ST.spellAliases[spellID] or spellID;
    local spellData = ST.spellDB[resolvedID];
    if (not spellData) then return; end

    local player = ST.trackedPlayers[name];
    if (not player) then
        local ok, _, cls = pcall(UnitClass, unit);
        if (not ok or not cls) then return; end
        RegisterPlayer(name, cls);
        player = ST.trackedPlayers[name];
        if (not player) then return; end
    end

    local spellState = player.spells[resolvedID];
    if (not spellState) then return; end

    local now = GetTime();

    -- Handle charges
    if (spellState.maxCharges > 1) then
        spellState.charges = math.max(0, spellState.charges - 1);
        if (spellState.charges == 0) then
            spellState.state = "cooldown";
            spellState.cdEnd = now + spellState.baseCd;
        end
    else
        -- Single charge: go to active or cooldown
        if (spellData.duration) then
            spellState.state = "active";
            spellState.activeEnd = now + spellData.duration;
            spellState.cdEnd = now + spellState.baseCd;
        else
            spellState.state = "cooldown";
            spellState.cdEnd = now + spellState.baseCd;
        end
    end

    -- Record cast time for interrupt correlation (used by interrupt tracker hooks)
    if (not ST._recentCasts) then ST._recentCasts = {}; end
    ST._recentCasts[name] = now;

    -- Call category hooks
    local cat = ST.categoryMap[spellData.category];
    if (cat and cat.hooks and cat.hooks.onSpellCast) then
        cat.hooks.onSpellCast(name, resolvedID, now);
    end
end

-------------------------------------------------------------------------------
-- Refresh Party Watchers
--
-- Re-registers UNIT_SPELLCAST_SUCCEEDED on party and pet unit frames.
-- Launders the tainted spellID before matching against the spell database.
-------------------------------------------------------------------------------

local RefreshPartyWatchers;

RefreshPartyWatchers = function()
    for i = 1, 4 do
        _partyWatchers[i]:UnregisterAllEvents();
        _petWatchers[i]:UnregisterAllEvents();

        local unit = "party" .. i;
        if (UnitExists(unit)) then
            _partyWatchers[i]:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", unit);
            _partyWatchers[i]:SetScript("OnEvent", function(_, _, _, _, taintedSpellID)
                local cleanUnit = "party" .. i;
                local name = UnitName(cleanUnit);
                local cleanID = LaunderSpellID(taintedSpellID);
                if (cleanID) then
                    local resolvedID = ST.spellAliases[cleanID] or cleanID;
                    if (ST.spellDB[resolvedID]) then
                        RecordSpellCast(cleanUnit, cleanID, name);
                    elseif (name) then
                        -- Track recent cast even if not a tracked spell (for interrupt correlation)
                        if (not ST._recentCasts) then ST._recentCasts = {}; end
                        ST._recentCasts[name] = GetTime();
                    end
                end
            end);

            local petUnit = "partypet" .. i;
            if (UnitExists(petUnit)) then
                _petWatchers[i]:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", petUnit);
                _petWatchers[i]:SetScript("OnEvent", function(_, _, _, _, taintedSpellID)
                    local ownerUnit = "party" .. i;
                    local name = UnitName(ownerUnit);
                    local cleanID = LaunderSpellID(taintedSpellID);
                    if (cleanID) then
                        local resolvedID = ST.spellAliases[cleanID] or cleanID;
                        if (ST.spellDB[resolvedID]) then
                            RecordSpellCast(ownerUnit, cleanID, name);
                        elseif (name) then
                            if (not ST._recentCasts) then ST._recentCasts = {}; end
                            ST._recentCasts[name] = GetTime();
                        end
                    end
                end);
            end
        end
    end
end;

-------------------------------------------------------------------------------
-- Party Registration and Pruning
-------------------------------------------------------------------------------

local function RegisterPartyByClass()
    for i = 1, 4 do
        local u = "party" .. i;
        if (UnitExists(u)) then
            local name = UnitName(u);
            local _, cls = UnitClass(u);
            if (name and cls and not ST.trackedPlayers[name] and not ST.excludedPlayers[name]) then
                RegisterPlayer(name, cls);
            end
        end
    end
end

local function PruneTrackedPlayers()
    local active = {};
    for i = 1, 4 do
        local u = "party" .. i;
        if (UnitExists(u)) then
            active[UnitName(u)] = true;
        end
    end

    -- Keep self
    if (ST.playerName) then
        active[ST.playerName] = true;
    end

    for name in pairs(ST.trackedPlayers) do
        if (not active[name]) then ST.trackedPlayers[name] = nil; end
    end
    for name in pairs(ST.excludedPlayers) do
        if (not active[name]) then ST.excludedPlayers[name] = nil; end
    end
    for name in pairs(_inspectedNames) do
        if (not active[name]) then _inspectedNames[name] = nil; end
    end
end

-------------------------------------------------------------------------------
-- Self-Cooldown Tracking
--
-- Uses C_Spell.GetSpellCooldown for precise timing on the player's own
-- spells. Party members rely on estimated cooldowns from cast detection,
-- but the player's own data is accurate from the API.
-------------------------------------------------------------------------------

local function UpdateSelfCooldowns()
    local name = ST.playerName;
    if (not name) then return; end
    local player = ST.trackedPlayers[name];
    if (not player) then return; end

    for spellID, spellState in pairs(player.spells) do
        if (IsSpellKnown(spellID) or IsPlayerSpell(spellID)) then
            local ok, cdInfo = pcall(C_Spell.GetSpellCooldown, spellID);
            if (ok and cdInfo and cdInfo.duration and cdInfo.duration > 1.5) then
                local cdEnd = cdInfo.startTime + cdInfo.duration;
                spellState.cdEnd = cdEnd;
                if (spellState.state == "ready" and cdEnd > GetTime()) then
                    -- Spell is on CD but we missed the cast (e.g., logged in mid-CD)
                    local spellData = ST.spellDB[spellID];
                    if (spellData and spellData.duration and spellState.activeEnd > GetTime()) then
                        spellState.state = "active";
                    else
                        spellState.state = "cooldown";
                    end
                end
            end

            -- Check charges
            local ok2, chargeInfo = pcall(C_Spell.GetSpellCharges, spellID);
            if (ok2 and chargeInfo and chargeInfo.maxCharges and chargeInfo.maxCharges > 1) then
                spellState.charges = chargeInfo.currentCharges;
                spellState.maxCharges = chargeInfo.maxCharges;
                if (chargeInfo.cooldownStartTime and chargeInfo.cooldownDuration and chargeInfo.cooldownDuration > 0) then
                    spellState.cdEnd = chargeInfo.cooldownStartTime + chargeInfo.cooldownDuration;
                end
            end
        end
    end
end

-------------------------------------------------------------------------------
-- Buff Tracking
--
-- Checks auras on a unit and updates spell states accordingly.
-- Uses C_UnitAuras.GetPlayerAuraBySpellID for the player (fast path),
-- and AuraUtil.ForEachAura for party members (full scan).
-------------------------------------------------------------------------------

local function CheckUnitBuffs(unit)
    local name = UnitName(unit);
    if (not name) then return; end
    local player = ST.trackedPlayers[name];
    if (not player) then return; end

    for spellID, spellState in pairs(player.spells) do
        local spellData = ST.spellDB[spellID];
        if (spellData and spellData.duration) then
            -- Check if the buff is active on this unit
            local aura = nil;
            if (unit == "player") then
                aura = C_UnitAuras.GetPlayerAuraBySpellID(spellID);
            else
                -- For party members, scan their auras
                AuraUtil.ForEachAura(unit, "HELPFUL", nil, function(a)
                    if (a.spellId == spellID) then
                        aura = a;
                        return true;  -- stop iteration
                    end
                end);
            end

            if (aura) then
                spellState.state = "active";
                if (aura.expirationTime and aura.expirationTime > 0) then
                    spellState.activeEnd = aura.expirationTime;
                else
                    spellState.activeEnd = GetTime() + spellData.duration;
                end
            elseif (spellState.state == "active" and GetTime() >= spellState.activeEnd) then
                -- Buff faded, transition to cooldown (cdEnd already set from cast)
                spellState.state = "cooldown";
            end
        end
    end
end

-------------------------------------------------------------------------------
-- State Ticker
--
-- Runs at 0.1s intervals to transition spell states:
--   "active"   -> "cooldown" when activeEnd is reached
--   "cooldown" -> "ready"    when cdEnd is reached
-------------------------------------------------------------------------------

local _tickerFrame = CreateFrame("Frame");
local _tickerElapsed = 0;
local TICK_INTERVAL = 0.1;

local function OnTick(_, elapsed)
    _tickerElapsed = _tickerElapsed + elapsed;
    if (_tickerElapsed < TICK_INTERVAL) then return; end
    _tickerElapsed = 0;

    local now = GetTime();
    for _, player in pairs(ST.trackedPlayers) do
        for spellID, s in pairs(player.spells) do
            if (s.state == "active" and now >= s.activeEnd) then
                s.state = "cooldown";
            end
            if (s.state == "cooldown" and now >= s.cdEnd) then
                s.state = "ready";
                s.cdEnd = 0;
                s.activeEnd = 0;
                local spellData = ST.spellDB[spellID];
                if (spellData and spellData.charges) then
                    s.charges = s.maxCharges;
                end
            end
        end
    end

    -- Refresh display (Display.lua will provide this)
    if (ST.RefreshDisplay) then
        ST:RefreshDisplay();
    end
end

-------------------------------------------------------------------------------
-- Inspect System
--
-- After joining a group, we inspect party members one at a time to
-- determine their spec (for overrides) and scan talents for CD modifiers.
-- Uses configID = -1 which is the inspected player's config ID.
-------------------------------------------------------------------------------

local function ApplyInspectResults(unit)
    local name = UnitName(unit);
    if (not name) then return; end

    local player = ST.trackedPlayers[name];
    if (not player) then
        _inspectedNames[name] = true;
        return;
    end

    local specID = GetInspectSpecialization(unit);
    if (specID and specID > 0) then
        player.spec = specID;

        -- Let category hooks decide if this player should be excluded
        for _, entry in ipairs(ST.categories) do
            if (entry.config.enabled and entry.config.hooks and entry.config.hooks.shouldExclude) then
                if (entry.config.hooks.shouldExclude(name, player.class, specID)) then
                    -- Remove spells from this category only
                    for spellID, spellState in pairs(player.spells) do
                        if (spellState.category == entry.key) then
                            player.spells[spellID] = nil;
                        end
                    end
                end
            end
        end

        -- Re-evaluate which spells this player should have based on spec
        for _, entry in ipairs(ST.categories) do
            if (entry.config.enabled) then
                local classSpells = ST:GetSpellsForClassAndCategory(player.class, specID, entry.key);
                -- Remove spells that don't belong to this spec
                for spellID, spellState in pairs(player.spells) do
                    if (spellState.category == entry.key and not classSpells[spellID]) then
                        player.spells[spellID] = nil;
                    end
                end
                -- Add spec-specific spells
                for spellID, spell in pairs(classSpells) do
                    if (not player.spells[spellID]) then
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
        end
    end

    -- Scan talent tree for CD modifiers
    local configID = -1;
    local ok, configInfo = pcall(C_Traits.GetConfigInfo, configID);
    if (not ok or not configInfo or not configInfo.treeIDs or #configInfo.treeIDs == 0) then
        _inspectedNames[name] = true;
        return;
    end

    local ok2, nodeIDs = pcall(C_Traits.GetTreeNodes, configInfo.treeIDs[1]);
    if (not ok2 or not nodeIDs) then
        _inspectedNames[name] = true;
        return;
    end

    for _, nodeID in ipairs(nodeIDs) do
        local ok3, nodeInfo = pcall(C_Traits.GetNodeInfo, configID, nodeID);
        if (ok3 and nodeInfo and nodeInfo.activeEntry
            and nodeInfo.activeRank and nodeInfo.activeRank > 0) then
            local entryID = nodeInfo.activeEntry.entryID;
            if (entryID) then
                local ok4, entryInfo = pcall(C_Traits.GetEntryInfo, configID, entryID);
                if (ok4 and entryInfo and entryInfo.definitionID) then
                    local ok5, defInfo = pcall(C_Traits.GetDefinitionInfo, entryInfo.definitionID);
                    if (ok5 and defInfo and defInfo.spellID) then
                        -- Check talent CD modifiers
                        for _, talentMod in ipairs(ST.talentModifiers) do
                            if (talentMod.spellID == defInfo.spellID) then
                                local spellState = player.spells[talentMod.affectsSpell];
                                if (spellState) then
                                    spellState.baseCd = math.max(1, spellState.baseCd - talentMod.cdReduction);
                                end
                            end
                        end

                        -- Check interrupt-specific kick bonuses
                        if (ST.interruptConfig and ST.interruptConfig.kickBonuses) then
                            local kickMod = ST.interruptConfig.kickBonuses[defInfo.spellID];
                            if (kickMod and player.spells) then
                                -- Store the kick bonus on interrupt spells for this player
                                for spellID, spellState in pairs(player.spells) do
                                    if (spellState.category == "interrupts") then
                                        spellState.kickBonus = kickMod.reduction;
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    _inspectedNames[name] = true;
end

local function ProcessNextInspect()
    if (_inspectInProgress) then return; end
    while (#_inspectPending > 0) do
        local unit = table.remove(_inspectPending, 1);
        if (UnitExists(unit) and UnitIsConnected(unit)) then
            local name = UnitName(unit);
            if (name and not _inspectedNames[name]) then
                _inspectInProgress = true;
                _inspectCurrentUnit = unit;
                NotifyInspect(unit);
                return;
            end
        end
    end
end

local function QueueInspects()
    _inspectPending = {};
    for i = 1, 4 do
        local u = "party" .. i;
        if (UnitExists(u)) then
            local name = UnitName(u);
            if (name and not _inspectedNames[name]) then
                table.insert(_inspectPending, u);
            end
        end
    end
    ProcessNextInspect();
end

-------------------------------------------------------------------------------
-- Engine Enable / Disable
--
-- Called from SpellTracker.lua's OnEnable/OnDisable. Manages event frames,
-- the state ticker, and initial party registration.
-------------------------------------------------------------------------------

local _eventFrame = CreateFrame("Frame");

function ST:EnableEngine()
    -- Initialize recent casts table
    ST._recentCasts = {};

    -- Register party change events
    _eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE");
    _eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
    _eventFrame:RegisterEvent("UNIT_PET");
    _eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN");
    _eventFrame:RegisterEvent("SPELLS_CHANGED");
    _eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED");
    _eventFrame:RegisterEvent("INSPECT_READY");
    _eventFrame:RegisterUnitEvent("UNIT_AURA", "player", "party1", "party2", "party3", "party4");
    _eventFrame:SetScript("OnEvent", function(_, event, ...)
        if (event == "GROUP_ROSTER_UPDATE") then
            PruneTrackedPlayers();
            RegisterPartyByClass();
            RefreshPartyWatchers();
            QueueInspects();
        elseif (event == "PLAYER_ENTERING_WORLD") then
            PruneTrackedPlayers();
            RegisterPartyByClass();
            RefreshPartyWatchers();
            C_Timer.After(2, QueueInspects);
        elseif (event == "UNIT_PET") then
            RefreshPartyWatchers();
        elseif (event == "SPELL_UPDATE_COOLDOWN") then
            UpdateSelfCooldowns();
        elseif (event == "SPELLS_CHANGED" or event == "PLAYER_SPECIALIZATION_CHANGED") then
            IdentifyPlayerSpells();
        elseif (event == "UNIT_AURA") then
            local unit = ...;
            if (unit) then
                CheckUnitBuffs(unit);
            end
        elseif (event == "INSPECT_READY") then
            if (_inspectInProgress and _inspectCurrentUnit) then
                ApplyInspectResults(_inspectCurrentUnit);
                _inspectInProgress = false;
                _inspectCurrentUnit = nil;
                ProcessNextInspect();
            end
        end
    end);

    -- Register self-cast watcher for player and pet casts
    _selfFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "pet");
    _selfFrame:SetScript("OnEvent", function(_, _, unit, _, spellID)
        local name = ST.playerName;
        if (not name) then return; end

        if (unit == "pet") then
            -- Pet spells may be tainted
            local cleanID = LaunderSpellID(spellID);
            local matchID = cleanID or spellID;
            local resolvedID = ST.spellAliases[matchID] or matchID;
            if (ST.spellDB[resolvedID]) then
                RecordSpellCast("player", resolvedID, name);
            end
        else
            -- Player spells are not tainted
            local resolvedID = ST.spellAliases[spellID] or spellID;
            if (ST.spellDB[resolvedID]) then
                RecordSpellCast("player", resolvedID, name);
            end
        end
    end);

    -- Start state ticker
    _tickerFrame:SetScript("OnUpdate", OnTick);

    -- Initial setup
    IdentifyPlayerSpells();
    RegisterPartyByClass();
    RefreshPartyWatchers();

    -- Enable category-specific trackers
    if (ST.EnableInterruptTracker) then ST:EnableInterruptTracker(); end
end

function ST:DisableEngine()
    _eventFrame:UnregisterAllEvents();
    _eventFrame:SetScript("OnEvent", nil);
    _selfFrame:UnregisterAllEvents();
    _selfFrame:SetScript("OnEvent", nil);
    _tickerFrame:SetScript("OnUpdate", nil);

    -- Disable category-specific trackers
    if (ST.DisableInterruptTracker) then ST:DisableInterruptTracker(); end

    for i = 1, 4 do
        _partyWatchers[i]:UnregisterAllEvents();
        _petWatchers[i]:UnregisterAllEvents();
    end

    ST.trackedPlayers = {};
    ST.excludedPlayers = {};
    ST._recentCasts = {};

    _inspectPending = {};
    _inspectInProgress = false;
    _inspectCurrentUnit = nil;
    _inspectedNames = {};

    -- Hide all display frames (Display.lua)
    if (ST.HideAllDisplays) then
        ST:HideAllDisplays();
    end
end
