local ADDON_NAME, NS = ...;
local ST = NS.SpellTracker;
if (not ST) then return; end

-------------------------------------------------------------------------------
-- Secret Value Unwrapping
--
-- In Patch 12.0.0, Blizzard introduced "secret values" that restrict addon
-- access to party member spell data (spellIDs, aura data, etc.) during
-- combat and M+ keys. A StatusBar's OnValueChanged callback receives a
-- clean copy because the C++ widget layer re-reads the value from internal
-- storage and passes it to Lua, bypassing the secret wrapper.
--
-- This technique was discovered by the WoW addon community. Blizzard has
-- stated they may close workarounds in future patches. If this stops
-- working, party member tracking will degrade (player's own data is
-- always clean and unaffected).
--
-- Taint laundering technique from ShimmerTracker; interrupt correlation
-- inspired by MythicInterruptTracker by KinderLine.
--
-- These frames MUST be created at file scope (clean load-time context).
-------------------------------------------------------------------------------

local _unwrapResult = nil;
local _unwrapFrame = CreateFrame("StatusBar");
_unwrapFrame:SetMinMaxValues(0, 9999999);
_unwrapFrame:SetScript("OnValueChanged", function(_, val)
    _unwrapResult = val;
end);

local _unwrapWorks = true;

local function Unwrap(secretValue)
    if (not _unwrapWorks) then return secretValue; end
    _unwrapResult = nil;
    _unwrapFrame:SetValue(0);
    pcall(_unwrapFrame.SetValue, _unwrapFrame, secretValue);
    return _unwrapResult;
end

local function ValidateUnwrap()
    local test = Unwrap(47528);
    if (test ~= 47528) then
        _unwrapWorks = false;
        if (ST.Print) then
            ST:Print("|cFFFF6600Warning:|r Secret value unwrapping is no longer working. "
                .. "Party member tracking may be inaccurate.");
        end
    end
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
local _inspectRetries = {};    -- name -> retry count
local MAX_INSPECT_RETRIES = 3;

-------------------------------------------------------------------------------
-- CD Resolution
--
-- Resolves the effective cooldown for a spell, checking cdBySpec first.
-------------------------------------------------------------------------------

local function ResolveCd(spell, spec)
    if (spell.cdBySpec and spec and spell.cdBySpec[spec]) then
        return spell.cdBySpec[spec];
    end
    return spell.cd;
end

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
                        baseCd     = ResolveCd(spell, player.spec),
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
                            baseCd     = ResolveCd(spell, player.spec),
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
        -- Start recharge timer if not already running
        if (spellState.cdEnd <= now) then
            spellState.cdEnd = now + spellState.baseCd;
        end
        if (spellData.duration) then
            spellState.state = "active";
            spellState.activeEnd = now + spellData.duration;
        elseif (spellState.charges == 0) then
            spellState.state = "cooldown";
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
-- Unwraps the secret spellID before matching against the spell database.
-------------------------------------------------------------------------------

local function OnPartySpellCast(self, _, _, _, taintedSpellID)
    local name = UnitName(self.unit);
    local cleanID = Unwrap(taintedSpellID);
    if (cleanID) then
        local resolvedID = ST.spellAliases[cleanID] or cleanID;
        if (ST.spellDB[resolvedID]) then
            RecordSpellCast(self.unit, cleanID, name);
        elseif (name) then
            ST._recentCasts[name] = GetTime();
        end
    end
end

local function OnPetSpellCast(self, _, _, _, taintedSpellID)
    local name = UnitName(self.ownerUnit);
    local cleanID = Unwrap(taintedSpellID);
    if (cleanID) then
        local resolvedID = ST.spellAliases[cleanID] or cleanID;
        if (ST.spellDB[resolvedID]) then
            RecordSpellCast(self.ownerUnit, cleanID, name);
        elseif (name) then
            ST._recentCasts[name] = GetTime();
        end
    end
end

local RefreshPartyWatchers;

RefreshPartyWatchers = function()
    for i = 1, 4 do
        _partyWatchers[i]:UnregisterAllEvents();
        _petWatchers[i]:UnregisterAllEvents();

        local unit = "party" .. i;
        if (UnitExists(unit)) then
            _partyWatchers[i].unit = unit;
            _partyWatchers[i]:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", unit);
            _partyWatchers[i]:SetScript("OnEvent", OnPartySpellCast);

            local petUnit = "partypet" .. i;
            if (UnitExists(petUnit)) then
                _petWatchers[i].ownerUnit = unit;
                _petWatchers[i]:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", petUnit);
                _petWatchers[i]:SetScript("OnEvent", OnPetSpellCast);
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
    for name in pairs(_inspectRetries) do
        if (not active[name]) then _inspectRetries[name] = nil; end
    end
end

-------------------------------------------------------------------------------
-- Self-Cooldown Tracking
--
-- Uses C_Spell.GetSpellCooldown for precise timing on the player's own
-- spells. Player data is exempt from secret values (Blizzard confirmed
-- "the player's own spellcasts will no longer be secret, even in combat"),
-- so no unwrapping is needed here.
-------------------------------------------------------------------------------

local function UpdateSelfCooldowns()
    local name = ST.playerName;
    if (not name) then return; end
    local player = ST.trackedPlayers[name];
    if (not player) then return; end

    local now = GetTime();
    for spellID, spellState in pairs(player.spells) do
        if (IsSpellKnown(spellID) or IsPlayerSpell(spellID)) then
            local ok, cdInfo = pcall(C_Spell.GetSpellCooldown, spellID);
            if (ok and cdInfo) then
                local dur = Unwrap(cdInfo.duration);
                local start = Unwrap(cdInfo.startTime);
                if (dur and start and dur > 1.5) then
                    local cdEnd = start + dur;
                    spellState.cdEnd = cdEnd;
                    if (spellState.state == "ready" and cdEnd > now) then
                        local spellData = ST.spellDB[spellID];
                        if (spellData and spellData.duration and spellState.activeEnd > now) then
                            spellState.state = "active";
                        else
                            spellState.state = "cooldown";
                        end
                    end
                end
            end

            -- Check charges
            local ok2, chargeInfo = pcall(C_Spell.GetSpellCharges, spellID);
            if (ok2 and chargeInfo) then
                local maxCh = Unwrap(chargeInfo.maxCharges);
                if (maxCh and maxCh > 1) then
                    spellState.charges = Unwrap(chargeInfo.currentCharges) or spellState.charges;
                    spellState.maxCharges = maxCh;
                    local cdDur = Unwrap(chargeInfo.cooldownDuration);
                    local cdStart = Unwrap(chargeInfo.cooldownStartTime);
                    if (cdDur and cdStart and cdDur > 0) then
                        spellState.cdEnd = cdStart + cdDur;
                    end
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
-- and C_UnitAuras.GetAuraDataByIndex for party members (avoids
-- AuraUtil.ForEachAura taint crash in Midnight).
--
-- Party member aura iteration uses a single pass: iterate auras once,
-- unwrap each spellId, and look it up in the tracked set. This is
-- O(auras) instead of O(spells * auras).
-------------------------------------------------------------------------------

local function CheckUnitBuffs(unit)
    local name = UnitName(unit);
    if (not name) then return; end
    local player = ST.trackedPlayers[name];
    if (not player) then return; end

    -- Collect spells that have durations (need buff checking)
    local durationSpells;
    for spellID, spellState in pairs(player.spells) do
        local spellData = ST.spellDB[spellID];
        if (spellData and spellData.duration) then
            if (not durationSpells) then durationSpells = {}; end
            durationSpells[spellID] = true;
        end
    end
    if (not durationSpells) then return; end

    local now = GetTime();
    local isPlayer = (unit == "player");

    -- Build active aura lookup (spellID -> expirationTime)
    local activeAuras = {};
    if (isPlayer) then
        -- Player aura queries are clean (no unwrapping needed)
        for spellID in pairs(durationSpells) do
            local aura = C_UnitAuras.GetPlayerAuraBySpellID(spellID);
            if (not aura) then
                -- Also check debuffs (for passive procs like Purgatory)
                aura = C_UnitAuras.GetPlayerAuraBySpellID(spellID, "HARMFUL");
            end
            if (aura) then
                activeAuras[spellID] = aura.expirationTime;
            end
        end
    else
        -- Single pass over party member auras, unwrap once per aura
        for i = 1, 40 do
            local data = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL");
            if (not data) then break; end
            local cleanId = Unwrap(data.spellId);
            if (cleanId and durationSpells[cleanId]) then
                activeAuras[cleanId] = Unwrap(data.expirationTime);
            end
        end
        -- Also check debuffs (for passive procs like Purgatory)
        for i = 1, 40 do
            local data = C_UnitAuras.GetAuraDataByIndex(unit, i, "HARMFUL");
            if (not data) then break; end
            local cleanId = Unwrap(data.spellId);
            if (cleanId and durationSpells[cleanId] and not activeAuras[cleanId]) then
                activeAuras[cleanId] = Unwrap(data.expirationTime);
            end
        end
    end

    -- Update spell states
    for spellID in pairs(durationSpells) do
        local spellState = player.spells[spellID];
        local expiry = activeAuras[spellID];
        if (expiry) then
            -- If transitioning to active from a passive proc (no cast event),
            -- set cdEnd so it goes to cooldown properly after the aura fades.
            if (spellState.state ~= "active" and spellState.cdEnd <= now) then
                spellState.cdEnd = now + spellState.baseCd;
            end
            spellState.state = "active";
            if (expiry > 0) then
                spellState.activeEnd = expiry;
            else
                spellState.activeEnd = now + ST.spellDB[spellID].duration;
            end
        elseif (spellState.state == "active" and now >= spellState.activeEnd) then
            -- Buff faded, transition to cooldown (cdEnd already set from cast)
            spellState.state = "cooldown";
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
                if (s.maxCharges > 1 and s.charges > 0) then
                    s.state = "ready";
                else
                    s.state = "cooldown";
                end
            end
            if (s.state == "cooldown" and now >= s.cdEnd) then
                if (s.maxCharges > 1) then
                    s.charges = s.charges + 1;
                    if (s.charges >= s.maxCharges) then
                        s.state = "ready";
                        s.cdEnd = 0;
                        s.activeEnd = 0;
                    else
                        -- More charges to recharge
                        s.state = "ready";
                        s.cdEnd = now + s.baseCd;
                    end
                else
                    s.state = "ready";
                    s.cdEnd = 0;
                    s.activeEnd = 0;
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

local function ApplySpecOverrides(player, name, specID)
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
                        baseCd     = ResolveCd(spell, specID),
                    };
                else
                    -- Update baseCd now that we know the spec
                    player.spells[spellID].baseCd = ResolveCd(spell, specID);
                end
            end
        end
    end
end

local function ScanTalentModifiers(player)
    local configID = -1;
    local ok, configInfo = pcall(C_Traits.GetConfigInfo, configID);
    if (not ok or not configInfo or not configInfo.treeIDs or #configInfo.treeIDs == 0) then
        return;
    end

    local ok2, nodeIDs = pcall(C_Traits.GetTreeNodes, configInfo.treeIDs[1]);
    if (not ok2 or not nodeIDs) then
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
end

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
        ApplySpecOverrides(player, name, specID);
        ScanTalentModifiers(player);
        ClearInspectPlayer();
        _inspectedNames[name] = true;
        _inspectRetries[name] = nil;
    else
        -- Spec not available yet — retry if under limit
        ClearInspectPlayer();
        local retries = (_inspectRetries[name] or 0) + 1;
        _inspectRetries[name] = retries;
        if (retries < MAX_INSPECT_RETRIES) then
            C_Timer.After(1, function()
                if (not _inspectedNames[name]) then
                    table.insert(_inspectPending, unit);
                    ProcessNextInspect();
                end
            end);
        else
            -- Give up, mark as inspected to stop retrying
            _inspectedNames[name] = true;
        end
    end
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
                -- Timeout: if INSPECT_READY never fires, unblock after 5s
                C_Timer.After(5, function()
                    if (_inspectInProgress and _inspectCurrentUnit == unit) then
                        _inspectInProgress = false;
                        _inspectCurrentUnit = nil;
                        -- Re-queue for retry if under limit
                        local n = UnitName(unit);
                        if (n and not _inspectedNames[n]) then
                            local retries = (_inspectRetries[n] or 0) + 1;
                            _inspectRetries[n] = retries;
                            if (retries < MAX_INSPECT_RETRIES) then
                                table.insert(_inspectPending, unit);
                            end
                        end
                        ProcessNextInspect();
                    end
                end);
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
                -- Skip players whose spec is already known
                local player = ST.trackedPlayers[name];
                if (not player or not player.spec) then
                    table.insert(_inspectPending, u);
                end
            end
        end
    end
    ProcessNextInspect();
end

-------------------------------------------------------------------------------
-- Engine Enable / Disable
--
-- Called from Core.lua's Enable/Disable. Manages event frames,
-- the state ticker, and initial party registration.
-------------------------------------------------------------------------------

local _eventFrame = CreateFrame("Frame");

function ST:EnableEngine()
    -- Verify unwrapping still works (Blizzard may patch this in future)
    ValidateUnwrap();

    -- Register party change events
    _eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE");
    _eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
    _eventFrame:RegisterEvent("LOADING_SCREEN_DISABLED");
    _eventFrame:RegisterEvent("UNIT_PET");
    _eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN");
    _eventFrame:RegisterEvent("SPELLS_CHANGED");
    _eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED");
    _eventFrame:RegisterEvent("INSPECT_READY");
    _eventFrame:RegisterEvent("READY_CHECK");
    _eventFrame:RegisterEvent("ROLE_CHANGED_INFORM");
    _eventFrame:RegisterUnitEvent("UNIT_AURA", "player", "party1", "party2", "party3", "party4");
    _eventFrame:SetScript("OnEvent", function(_, event, ...)
        if (event == "GROUP_ROSTER_UPDATE") then
            PruneTrackedPlayers();
            RegisterPartyByClass();
            RefreshPartyWatchers();
            QueueInspects();
        elseif (event == "PLAYER_ENTERING_WORLD" or event == "LOADING_SCREEN_DISABLED") then
            PruneTrackedPlayers();
            RegisterPartyByClass();
            RefreshPartyWatchers();
            -- Staggered inspect attempts — party members may still be loading
            C_Timer.After(2, function() RegisterPartyByClass(); QueueInspects(); end);
            C_Timer.After(5, function() RegisterPartyByClass(); QueueInspects(); end);
            C_Timer.After(10, function() RegisterPartyByClass(); QueueInspects(); end);
        elseif (event == "UNIT_PET") then
            RefreshPartyWatchers();
        elseif (event == "SPELL_UPDATE_COOLDOWN") then
            UpdateSelfCooldowns();
        elseif (event == "SPELLS_CHANGED") then
            IdentifyPlayerSpells();
        elseif (event == "PLAYER_SPECIALIZATION_CHANGED") then
            local unit = ...;
            if (not unit or unit == "player") then
                IdentifyPlayerSpells();
            else
                -- Party member changed spec — clear inspect cache and re-inspect
                local name = UnitName(unit);
                if (name) then
                    _inspectedNames[name] = nil;
                    local _, cls = UnitClass(unit);
                    if (cls) then RegisterPlayer(name, cls); end
                    C_Timer.After(1, QueueInspects);
                end
            end
        elseif (event == "ROLE_CHANGED_INFORM") then
            -- Re-evaluate exclusions when roles change (e.g. healer swap)
            for i = 1, 4 do
                local u = "party" .. i;
                if (UnitExists(u)) then
                    local name = UnitName(u);
                    local player = name and ST.trackedPlayers[name];
                    if (player and player.spec) then
                        ApplySpecOverrides(player, name, player.spec);
                    end
                end
            end
        elseif (event == "UNIT_AURA") then
            local unit = ...;
            if (unit) then
                CheckUnitBuffs(unit);
            end
        elseif (event == "READY_CHECK") then
            -- Re-inspect all party members on ready check (good time to refresh specs)
            _inspectedNames = {};
            QueueInspects();
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
            local cleanID = Unwrap(spellID);
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
    _inspectRetries = {};

    -- Hide all display frames (Display.lua)
    if (ST.HideAllDisplays) then
        ST:HideAllDisplays();
    end
end
