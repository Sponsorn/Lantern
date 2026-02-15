local ADDON_NAME, NS = ...;
local ST = NS.SpellTracker;
if (not ST) then return; end

-------------------------------------------------------------------------------
-- Interrupt Spell Database
--
-- Ported from InterruptTracker.lua into the SpellTracker registry format.
-- Each entry is a flat spell record registered via ST:RegisterSpells().
-------------------------------------------------------------------------------

ST:RegisterSpells({
    -- Death Knight: Mind Freeze
    {
        id       = 47528,
        cd       = 15,
        duration = nil,
        charges  = nil,
        class    = "DEATHKNIGHT",
        specs    = nil,
        category = "interrupts",
    },
    -- Demon Hunter: Disrupt
    {
        id       = 183752,
        cd       = 15,
        duration = nil,
        charges  = nil,
        class    = "DEMONHUNTER",
        specs    = nil,
        category = "interrupts",
    },
    -- Druid: Skull Bash (Feral / Guardian)
    {
        id       = 106839,
        cd       = 15,
        duration = nil,
        charges  = nil,
        class    = "DRUID",
        specs    = { [103] = true, [104] = true },
        category = "interrupts",
    },
    -- Druid: Solar Beam (Balance)
    {
        id       = 78675,
        cd       = 60,
        duration = nil,
        charges  = nil,
        class    = "DRUID",
        specs    = { [102] = true },
        category = "interrupts",
    },
    -- Evoker: Quell
    {
        id       = 351338,
        cd       = 40,
        duration = nil,
        charges  = nil,
        class    = "EVOKER",
        specs    = nil,
        category = "interrupts",
    },
    -- Hunter: Counter Shot (BM / MM)
    {
        id       = 147362,
        cd       = 24,
        duration = nil,
        charges  = nil,
        class    = "HUNTER",
        specs    = { [253] = true, [254] = true },
        category = "interrupts",
    },
    -- Hunter: Muzzle (Survival)
    {
        id       = 187707,
        cd       = 15,
        duration = nil,
        charges  = nil,
        class    = "HUNTER",
        specs    = { [255] = true },
        category = "interrupts",
    },
    -- Mage: Counterspell
    {
        id       = 2139,
        cd       = 24,
        duration = nil,
        charges  = nil,
        class    = "MAGE",
        specs    = nil,
        category = "interrupts",
    },
    -- Monk: Spear Hand Strike
    {
        id       = 116705,
        cd       = 15,
        duration = nil,
        charges  = nil,
        class    = "MONK",
        specs    = nil,
        category = "interrupts",
    },
    -- Paladin: Rebuke
    {
        id       = 96231,
        cd       = 15,
        duration = nil,
        charges  = nil,
        class    = "PALADIN",
        specs    = nil,
        category = "interrupts",
    },
    -- Priest: Silence (Shadow only)
    {
        id       = 15487,
        cd       = 45,
        duration = nil,
        charges  = nil,
        class    = "PRIEST",
        specs    = { [258] = true },
        category = "interrupts",
    },
    -- Rogue: Kick
    {
        id       = 1766,
        cd       = 15,
        duration = nil,
        charges  = nil,
        class    = "ROGUE",
        specs    = nil,
        category = "interrupts",
    },
    -- Shaman: Wind Shear (12s base, 30s for Resto)
    {
        id       = 57994,
        cd       = 12,
        cdBySpec = { [264] = 30 },
        duration = nil,
        charges  = nil,
        class    = "SHAMAN",
        specs    = nil,
        category = "interrupts",
    },
    -- Warlock: Spell Lock (Felhunter — Affliction / Destruction)
    {
        id       = 19647,
        cd       = 24,
        duration = nil,
        charges  = nil,
        class    = "WARLOCK",
        specs    = { [265] = true, [267] = true },
        category = "interrupts",
    },
    -- Warlock: Spell Lock (Felhunter alt ID — Affliction / Destruction)
    {
        id       = 132409,
        cd       = 24,
        duration = nil,
        charges  = nil,
        class    = "WARLOCK",
        specs    = { [265] = true, [267] = true },
        category = "interrupts",
    },
    -- Warlock: Axe Toss (Felguard — Demonology)
    {
        id       = 119914,
        cd       = 30,
        duration = nil,
        charges  = nil,
        class    = "WARLOCK",
        specs    = { [266] = true },
        category = "interrupts",
    },
    -- Warrior: Pummel
    {
        id       = 6552,
        cd       = 15,
        duration = nil,
        charges  = nil,
        class    = "WARRIOR",
        specs    = nil,
        category = "interrupts",
    },
});

-------------------------------------------------------------------------------
-- Talent CD Modifiers
-------------------------------------------------------------------------------

ST:RegisterTalentModifiers({
    -- Lone Survivor (Hunter): reduces Counter Shot CD by 2s
    { spellID = 388039, affectsSpell = 147362, cdReduction = 2 },
    -- Imposing Presence (Evoker): reduces Quell CD by 20s
    { spellID = 371016, affectsSpell = 351338, cdReduction = 20 },
});

-------------------------------------------------------------------------------
-- Spell Aliases
-------------------------------------------------------------------------------

ST:RegisterSpellAliases({
    [1276467] = 119914,  -- Fel Ravager -> Axe Toss (both Felguard abilities)
});

-------------------------------------------------------------------------------
-- Interrupt-Specific Config
--
-- Data consumed by the interrupt detection/display logic that doesn't fit
-- the generic spell entry format (spec removal, healer overrides, etc.).
-------------------------------------------------------------------------------

ST.interruptConfig = {
    -- Specs that lose their interrupt entirely
    specsWithoutInterrupt = {
        [256] = true,  -- Discipline Priest
        [257] = true,  -- Holy Priest
        [105] = true,  -- Restoration Druid
        [65]  = true,  -- Holy Paladin
    },

    -- Healer specs that keep their interrupt
    healerHasKick = {
        SHAMAN = true,
    },

    -- Talents that reduce cooldown only on a successful interrupt
    kickBonuses = {
        [378848] = { reduction = 3 },  -- Coldthirst (DK)
    },
};

-------------------------------------------------------------------------------
-- Mob Interrupt Correlation
--
-- When an enemy's cast is interrupted, we correlate it with the most
-- recent party member cast (within a short window) to attribute the kick.
-------------------------------------------------------------------------------

local CORRELATE_WINDOW = 0.5;   -- max seconds between cast and interrupt to attribute
local RECENT_CAST_TTL  = 1.0;   -- seconds before a recent cast entry expires

local function CorrelateInterrupt(unit)
    if (not ST._recentCasts) then return; end
    local now = GetTime();
    local closest, closestDelta = nil, 999;

    for name, ts in pairs(ST._recentCasts) do
        local delta = now - ts;
        if (delta > RECENT_CAST_TTL) then
            ST._recentCasts[name] = nil;
        elseif (delta < closestDelta) then
            closestDelta = delta;
            closest = name;
        end
    end

    if (not closest or closestDelta >= CORRELATE_WINDOW) then return; end

    local player = ST.trackedPlayers[closest];
    if (player) then
        -- Apply on-kick talent bonus if applicable
        for spellID, spellState in pairs(player.spells) do
            if (spellState.category == "interrupts" and spellState.kickBonus) then
                local adjusted = spellState.cdEnd - spellState.kickBonus;
                spellState.cdEnd = math.max(adjusted, now);
            end
        end
    end
end

-- Mob interrupt detection frames (file scope for clean context)
local _mobFrame = CreateFrame("Frame");
_mobFrame:SetScript("OnEvent", function(_, _, unit)
    CorrelateInterrupt(unit);
end);

local _npCastFrames = {};
local function OnNameplateCastInterrupted(_, _, u)
    CorrelateInterrupt(u);
end
local _npFrame = CreateFrame("Frame");
_npFrame:SetScript("OnEvent", function(_, event, unit)
    if (event == "NAME_PLATE_UNIT_ADDED") then
        if (not _npCastFrames[unit]) then
            _npCastFrames[unit] = CreateFrame("Frame");
            _npCastFrames[unit]:SetScript("OnEvent", OnNameplateCastInterrupted);
        end
        _npCastFrames[unit]:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", unit);
    elseif (event == "NAME_PLATE_UNIT_REMOVED") then
        if (_npCastFrames[unit]) then
            _npCastFrames[unit]:UnregisterAllEvents();
        end
    end
end);

-------------------------------------------------------------------------------
-- Communication
-------------------------------------------------------------------------------

local COMM_PREFIX = "LIT";
local lastJoinBroadcast = 0;

local function SendMessage(payload)
    if (IsInGroup(LE_PARTY_CATEGORY_INSTANCE)) then
        local ok = pcall(C_ChatInfo.SendAddonMessage, COMM_PREFIX, payload, "INSTANCE_CHAT");
        if (ok) then return; end
    end
    if (IsInGroup(LE_PARTY_CATEGORY_HOME)) then
        local ok = pcall(C_ChatInfo.SendAddonMessage, COMM_PREFIX, payload, "PARTY");
        if (ok) then return; end
    end
end

local function BroadcastJoin()
    if (not ST.playerClass or not ST.playerName) then return; end
    local now = GetTime();
    if (now - lastJoinBroadcast < 3) then return; end
    lastJoinBroadcast = now;

    -- Find the player's interrupt spell
    local player = ST.trackedPlayers[ST.playerName];
    if (not player) then return; end
    local kickID, kickCd;
    for spellID, spellState in pairs(player.spells) do
        if (spellState.category == "interrupts") then
            kickID = spellID;
            kickCd = spellState.baseCd;
            break;
        end
    end
    if (not kickID) then return; end

    SendMessage("J:" .. ST.playerClass .. ":" .. kickID .. ":" .. (kickCd or 15));
end

local function HandleAddonMessage(_, event, prefix, message, channel, sender)
    if (prefix ~= COMM_PREFIX) then return; end
    local shortName = Ambiguate(sender, "short");
    if (shortName == ST.playerName) then return; end

    local cmd, arg1, arg2, arg3 = strsplit(":", message);

    if (cmd == "J") then
        local cls = arg1;
        local sid = tonumber(arg2);
        local cd = tonumber(arg3);
        if (not cls or not sid or not ST.spellDB[sid]) then return; end

        local player = ST.trackedPlayers[shortName];
        if (not player) then return; end

        -- Update the interrupt spell's baseCd if the remote client reports one
        local spellState = player.spells[sid];
        if (spellState and cd and cd > 0) then
            spellState.baseCd = cd;
        end

        BroadcastJoin();

    elseif (cmd == "C") then
        -- CAST sync: remote player used their interrupt, start CD immediately
        local sid = tonumber(arg1);
        local cd = tonumber(arg2);
        if (not sid or not cd or cd <= 0) then return; end

        local player = ST.trackedPlayers[shortName];
        if (not player) then return; end

        local spellState = player.spells[sid];
        if (spellState and spellState.category == "interrupts") then
            local now = GetTime();
            spellState.state = "cooldown";
            spellState.cdEnd = now + cd;
            spellState.baseCd = cd;
        end
    end
end

local _commFrame = CreateFrame("Frame");
_commFrame:SetScript("OnEvent", HandleAddonMessage);

-------------------------------------------------------------------------------
-- Category Registration
-------------------------------------------------------------------------------

local interruptConfig = ST.interruptConfig;

ST:RegisterCategory("interrupts", {
    label             = "Interrupts",
    trackBuffDuration = false,
    defaultLayout     = "bar",
    defaultFilter     = "all",
    hooks = {
        -- Lifecycle hooks for enabling/disabling the interrupt tracker
        onEnable = function()
            if (ST.EnableInterruptTracker) then ST:EnableInterruptTracker(); end
        end,
        onDisable = function()
            if (ST.DisableInterruptTracker) then ST:DisableInterruptTracker(); end
        end,

        -- Called by engine when a spell is cast
        onSpellCast = function(name, spellID, time)
            -- Broadcast CD to other addon users when we use our interrupt
            if (name == ST.playerName) then
                local player = ST.trackedPlayers[name];
                if (player) then
                    local spellState = player.spells[spellID];
                    if (spellState) then
                        SendMessage("C:" .. spellID .. ":" .. spellState.baseCd);
                    end
                end
            end
        end,

        -- Called by engine during inspect to decide if a player should be excluded
        shouldExclude = function(name, class, specID)
            if (interruptConfig.specsWithoutInterrupt[specID]) then
                return true;
            end
            -- Check if healer class without kick
            local role = nil;
            for i = 1, 4 do
                local u = "party" .. i;
                if (UnitExists(u) and UnitName(u) == name) then
                    role = UnitGroupRolesAssigned(u);
                    break;
                end
            end
            if (role == "HEALER" and not interruptConfig.healerHasKick[class]) then
                return true;
            end
            return false;
        end,
    },
});

-------------------------------------------------------------------------------
-- Lifecycle
-------------------------------------------------------------------------------

function ST:EnableInterruptTracker()
    C_ChatInfo.RegisterAddonMessagePrefix(COMM_PREFIX);

    _mobFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "target", "focus");
    _npFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED");
    _npFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED");
    _commFrame:RegisterEvent("CHAT_MSG_ADDON");
end

function ST:DisableInterruptTracker()
    _mobFrame:UnregisterAllEvents();
    _npFrame:UnregisterAllEvents();
    _commFrame:UnregisterAllEvents();
    for _, frame in pairs(_npCastFrames) do
        frame:UnregisterAllEvents();
    end
    wipe(_npCastFrames);
end
