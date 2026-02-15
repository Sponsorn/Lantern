local ADDON_NAME, NS = ...;
local ST = NS.SpellTracker;
if (not ST) then return; end

-------------------------------------------------------------------------------
-- Major Defensive Cooldown Database (Midnight / 12.0)
--
-- Tracks major defensive cooldowns across all classes for M+ groups.
-- Each entry follows the same spell record format as interrupts/cooldowns.
-------------------------------------------------------------------------------

local spells = {
    -- WARRIOR: Shield Wall (Protection)
    {
        id       = 871,
        cd       = 210,
        duration = 8,
        charges  = nil,
        class    = "WARRIOR",
        specs    = { [73] = true },
        category = "defensive",
    },
    -- WARRIOR: Die by the Sword (Arms)
    {
        id       = 118038,
        cd       = 120,
        duration = 8,
        charges  = nil,
        class    = "WARRIOR",
        specs    = { [71] = true },
        category = "defensive",
    },
    -- WARRIOR: Enraged Regeneration (Fury)
    {
        id       = 184364,
        cd       = 120,
        duration = 8,
        charges  = nil,
        class    = "WARRIOR",
        specs    = { [72] = true },
        category = "defensive",
    },
    -- WARRIOR: Rallying Cry (group HP increase)
    {
        id       = 97462,
        cd       = 180,
        duration = 10,
        charges  = nil,
        class    = "WARRIOR",
        specs    = nil,
        category = "defensive",
    },
    -- WARRIOR: Last Stand
    {
        id       = 12975,
        cd       = 180,
        duration = 8,
        charges  = nil,
        class    = "WARRIOR",
        specs    = nil,
        category = "defensive",
    },

    -- PALADIN: Divine Shield
    {
        id       = 642,
        cd       = 300,
        duration = 8,
        charges  = nil,
        class    = "PALADIN",
        specs    = nil,
        category = "defensive",
    },
    -- PALADIN: Ardent Defender (Protection)
    {
        id       = 31850,
        cd       = 120,
        duration = 8,
        charges  = nil,
        class    = "PALADIN",
        specs    = { [66] = true },
        category = "defensive",
    },
    -- PALADIN: Guardian of Ancient Kings (Protection)
    {
        id       = 86659,
        cd       = 180,
        duration = 8,
        charges  = nil,
        class    = "PALADIN",
        specs    = { [66] = true },
        category = "defensive",
    },
    -- PALADIN: Blessing of Protection
    {
        id       = 1022,
        cd       = 300,
        duration = 10,
        charges  = nil,
        class    = "PALADIN",
        specs    = nil,
        category = "defensive",
    },

    -- DEATHKNIGHT: Anti-Magic Shell
    {
        id       = 48707,
        cd       = 60,
        duration = 5,
        charges  = nil,
        class    = "DEATHKNIGHT",
        specs    = nil,
        category = "defensive",
    },
    -- DEATHKNIGHT: Icebound Fortitude
    {
        id       = 48792,
        cd       = 180,
        duration = 8,
        charges  = nil,
        class    = "DEATHKNIGHT",
        specs    = nil,
        category = "defensive",
    },
    -- DEATHKNIGHT: Anti-Magic Zone
    {
        id       = 51052,
        cd       = 120,
        duration = 8,
        charges  = nil,
        class    = "DEATHKNIGHT",
        specs    = nil,
        category = "defensive",
    },
    -- DEATHKNIGHT: Lichborne
    {
        id       = 49039,
        cd       = 120,
        duration = 10,
        charges  = nil,
        class    = "DEATHKNIGHT",
        specs    = nil,
        category = "defensive",
    },
    -- DEATHKNIGHT: Death Pact
    {
        id       = 48743,
        cd       = 120,
        duration = nil,
        charges  = nil,
        class    = "DEATHKNIGHT",
        specs    = nil,
        category = "defensive",
    },
    -- DEATHKNIGHT: Vampiric Blood (Blood)
    {
        id       = 55233,
        cd       = 90,
        duration = 12,
        charges  = nil,
        class    = "DEATHKNIGHT",
        specs    = { [250] = true },
        category = "defensive",
    },
    -- DEATHKNIGHT: Dancing Rune Weapon (Blood)
    {
        id       = 49028,
        cd       = 120,
        duration = 8,
        charges  = nil,
        class    = "DEATHKNIGHT",
        specs    = { [250] = true },
        category = "defensive",
    },
    -- DEATHKNIGHT: Tombstone (Blood)
    {
        id       = 219809,
        cd       = 60,
        duration = 8,
        charges  = nil,
        class    = "DEATHKNIGHT",
        specs    = { [250] = true },
        category = "defensive",
    },
    -- DEATHKNIGHT: Purgatory (Blood — passive cheat death, detected via debuff aura)
    {
        id       = 114556,
        cd       = 600,
        duration = 4,
        charges  = nil,
        class    = "DEATHKNIGHT",
        specs    = { [250] = true },
        category = "defensive",
    },

    -- ROGUE: Cloak of Shadows
    {
        id       = 31224,
        cd       = 120,
        duration = 5,
        charges  = nil,
        class    = "ROGUE",
        specs    = nil,
        category = "defensive",
    },
    -- ROGUE: Evasion
    {
        id       = 5277,
        cd       = 120,
        duration = 10,
        charges  = nil,
        class    = "ROGUE",
        specs    = nil,
        category = "defensive",
    },

    -- MAGE: Ice Block
    {
        id       = 45438,
        cd       = 240,
        duration = 10,
        charges  = nil,
        class    = "MAGE",
        specs    = nil,
        category = "defensive",
    },
    -- MAGE: Greater Invisibility
    {
        id       = 110959,
        cd       = 120,
        duration = 20,
        charges  = nil,
        class    = "MAGE",
        specs    = nil,
        category = "defensive",
    },

    -- HUNTER: Survival of the Fittest (Lone Wolf — no pet version)
    {
        id       = 281195,
        cd       = 180,
        duration = 6,
        charges  = nil,
        class    = "HUNTER",
        specs    = nil,
        category = "defensive",
    },
    -- HUNTER: Aspect of the Turtle
    {
        id       = 186265,
        cd       = 180,
        duration = 8,
        charges  = nil,
        class    = "HUNTER",
        specs    = nil,
        category = "defensive",
    },

    -- DRUID: Barkskin
    {
        id       = 22812,
        cd       = 60,
        duration = 8,
        charges  = nil,
        class    = "DRUID",
        specs    = nil,
        category = "defensive",
    },
    -- DRUID: Survival Instincts (Feral / Guardian)
    {
        id       = 61336,
        cd       = 180,
        duration = 6,
        charges  = 2,
        class    = "DRUID",
        specs    = { [103] = true, [104] = true },
        category = "defensive",
    },

    -- MONK: Fortifying Brew
    {
        id       = 115203,
        cd       = 180,
        duration = 15,
        charges  = nil,
        class    = "MONK",
        specs    = nil,
        category = "defensive",
    },
    -- MONK: Dampen Harm (20-50% DR based on hit size)
    {
        id       = 122278,
        cd       = 120,
        duration = 10,
        charges  = nil,
        class    = "MONK",
        specs    = nil,
        category = "defensive",
    },

    -- DEMONHUNTER: Blur (Havoc / Devourer)
    {
        id       = 198589,
        cd       = 60,
        duration = 10,
        charges  = nil,
        class    = "DEMONHUNTER",
        specs    = { [577] = true, [1480] = true },
        category = "defensive",
    },
    -- DEMONHUNTER: Metamorphosis (Vengeance — defensive version)
    {
        id       = 187827,
        cd       = 180,
        duration = 15,
        charges  = nil,
        class    = "DEMONHUNTER",
        specs    = { [581] = true },
        category = "defensive",
    },
    -- DEMONHUNTER: Darkness (group avoidance)
    {
        id       = 196718,
        cd       = 300,
        duration = 8,
        charges  = nil,
        class    = "DEMONHUNTER",
        specs    = nil,
        category = "defensive",
    },

    -- PRIEST: Dispersion (Shadow)
    {
        id       = 47585,
        cd       = 90,
        duration = 6,
        charges  = nil,
        class    = "PRIEST",
        specs    = { [258] = true },
        category = "defensive",
    },
    -- PRIEST: Desperate Prayer (all specs — +25% max HP self-heal)
    {
        id       = 19236,
        cd       = 90,
        duration = 10,
        charges  = nil,
        class    = "PRIEST",
        specs    = nil,
        category = "defensive",
    },
    -- PRIEST: Vampiric Embrace (Shadow — group sustain heal)
    {
        id       = 15286,
        cd       = 120,
        duration = 12,
        charges  = nil,
        class    = "PRIEST",
        specs    = { [258] = true },
        category = "defensive",
    },

    -- SHAMAN: Astral Shift
    {
        id       = 108271,
        cd       = 120,
        duration = 12,
        charges  = nil,
        class    = "SHAMAN",
        specs    = nil,
        category = "defensive",
    },
    -- SHAMAN: Earth Elemental (emergency tank / survivability with Primordial Bond)
    {
        id       = 198103,
        cd       = 180,
        duration = 30,
        charges  = nil,
        class    = "SHAMAN",
        specs    = nil,
        category = "defensive",
    },

    -- WARLOCK: Unending Resolve
    {
        id       = 104773,
        cd       = 180,
        duration = 8,
        charges  = nil,
        class    = "WARLOCK",
        specs    = nil,
        category = "defensive",
    },

    -- EVOKER: Obsidian Scales
    {
        id       = 363916,
        cd       = 90,
        duration = 12,
        charges  = nil,
        class    = "EVOKER",
        specs    = nil,
        category = "defensive",
    },
    -- EVOKER: Zephyr (group AoE damage reduction)
    {
        id       = 374227,
        cd       = 120,
        duration = 8,
        charges  = nil,
        class    = "EVOKER",
        specs    = nil,
        category = "defensive",
    },
};

ST:RegisterSpells(spells);

-------------------------------------------------------------------------------
-- Category Registration
-------------------------------------------------------------------------------

ST:RegisterCategory("defensive", {
    label             = "Defensives",
    trackBuffDuration = true,
    defaultLayout     = "icon",
    defaultFilter     = "all",
});
