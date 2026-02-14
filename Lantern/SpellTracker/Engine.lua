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
    _eventFrame:SetScript("OnEvent", function(_, event, ...)
        if (event == "GROUP_ROSTER_UPDATE") then
            PruneTrackedPlayers();
            RegisterPartyByClass();
            RefreshPartyWatchers();
        elseif (event == "PLAYER_ENTERING_WORLD") then
            PruneTrackedPlayers();
            RegisterPartyByClass();
            RefreshPartyWatchers();
        elseif (event == "UNIT_PET") then
            RefreshPartyWatchers();
        end
    end);

    -- Start state ticker
    _tickerFrame:SetScript("OnUpdate", OnTick);

    -- Initial setup
    RegisterPartyByClass();
    RefreshPartyWatchers();
end

function ST:DisableEngine()
    _eventFrame:UnregisterAllEvents();
    _eventFrame:SetScript("OnEvent", nil);
    _tickerFrame:SetScript("OnUpdate", nil);

    for i = 1, 4 do
        _partyWatchers[i]:UnregisterAllEvents();
        _petWatchers[i]:UnregisterAllEvents();
    end

    ST.trackedPlayers = {};
    ST.excludedPlayers = {};
    ST._recentCasts = {};
end
