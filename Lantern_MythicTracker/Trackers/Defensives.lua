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
        cd       = 90,
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
    -- PALADIN: Blessing of Spellwarding (Protection — choice node with BoP)
    {
        id       = 204018,
        cd       = 300,
        duration = 10,
        charges  = nil,
        class    = "PALADIN",
        specs    = { [66] = true },
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
        cd       = 90,
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

    -- HUNTER: Survival of the Fittest
    {
        id       = 264735,
        cd       = 180,
        duration = 6,
        charges  = nil,
        class    = "HUNTER",
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
-- Talent CD Modifiers
--
-- Static cooldown reductions from talents detected via inspect.
-- Dynamic/proc-based reductions (Red Thirst, Bloody Fortitude) cannot be
-- tracked as static modifiers and are intentionally excluded.
-------------------------------------------------------------------------------

ST:RegisterTalentModifiers({
    ---------------------------------------------------------------------------
    -- DEATHKNIGHT
    -- Skipped (dynamic): Red Thirst (VB CD per RP spent), Bloody Fortitude
    --                     (IBF CD per kill)
    ---------------------------------------------------------------------------
    -- Anti-Magic Barrier: reduces Anti-Magic Shell CD by 20s
    { spellID = 205727, affectsSpell = 48707, cdReduction = 20 },
    -- Assimilation: reduces Anti-Magic Zone CD by 60s
    { spellID = 374383, affectsSpell = 51052, cdReduction = 60 },
    -- Insatiable Blade: reduces Dancing Rune Weapon CD by 30s (Blood)
    { spellID = 377637, affectsSpell = 49028, cdReduction = 30 },
    -- Unholy Endurance: reduces Lichborne CD by 30s
    { spellID = 389682, affectsSpell = 49039, cdReduction = 30 },
    -- Death's Messenger: reduces Lichborne CD by 30s
    { spellID = 437122, affectsSpell = 49039, cdReduction = 30 },

    ---------------------------------------------------------------------------
    -- WARRIOR
    -- Skipped (dynamic): Anger Management (Shield Wall CD per rage spent),
    --                     Impenetrable Wall (Shield Slam reduces SW CD by 6s)
    ---------------------------------------------------------------------------
    -- Honed Reflexes: reduces defensive CDs by 10% (also affects Pummel in Interrupts.lua)
    { spellID = 391271, affectsSpell = 118038, cdReductionPct = 0.10 },  -- Die by the Sword (Arms)
    { spellID = 391271, affectsSpell = 184364, cdReductionPct = 0.10 },  -- Enraged Regeneration (Fury)
    { spellID = 391271, affectsSpell = 871,    cdReductionPct = 0.10 },  -- Shield Wall (Prot)
    -- Defender's Aegis: Shield Wall CD -60s and +1 charge (Prot)
    { spellID = 397103, affectsSpell = 871, cdReduction = 60, chargeIncrease = 1 },

    ---------------------------------------------------------------------------
    -- PALADIN
    ---------------------------------------------------------------------------
    -- Unbreakable Spirit: reduces Divine Shield, Ardent Defender CD by 30%
    { spellID = 114154, affectsSpell = 642,   cdReductionPct = 0.30 },  -- Divine Shield
    { spellID = 114154, affectsSpell = 31850, cdReductionPct = 0.30 },  -- Ardent Defender
    -- Uther's Counsel: reduces Divine Shield, BoP, Spellwarding CD by 15%
    { spellID = 378425, affectsSpell = 642,    cdReductionPct = 0.15 },  -- Divine Shield
    { spellID = 378425, affectsSpell = 1022,   cdReductionPct = 0.15 },  -- Blessing of Protection
    { spellID = 378425, affectsSpell = 204018, cdReductionPct = 0.15 },  -- Blessing of Spellwarding
    -- Improved Blessing of Protection: BoP and Spellwarding CD -60s
    { spellID = 384909, affectsSpell = 1022,   cdReduction = 60 },  -- Blessing of Protection
    { spellID = 384909, affectsSpell = 204018, cdReduction = 60 },  -- Blessing of Spellwarding
    -- Empyrean Authority: Guardian of Ancient Kings +1 charge (Prot)
    { spellID = 1246481, affectsSpell = 86659, chargeIncrease = 1 },

    ---------------------------------------------------------------------------
    -- MAGE
    ---------------------------------------------------------------------------
    -- Master of Escape: reduces Greater Invisibility CD by 60s
    { spellID = 210476, affectsSpell = 110959, cdReduction = 60 },
    -- Winter's Protection: reduces Ice Block CD by 30s per rank (2 ranks)
    { spellID = 382424, affectsSpell = 45438, cdReduction = 30, perRank = true },
    -- Permafrost Bauble: reduces Ice Block CD by 30s
    { spellID = 1265517, affectsSpell = 45438, cdReduction = 30 },

    ---------------------------------------------------------------------------
    -- HUNTER
    ---------------------------------------------------------------------------
    -- Born To Be Wild: reduces Aspect of the Turtle CD by 15s per rank (2 ranks)
    { spellID = 266921, affectsSpell = 186265, cdReduction = 15, perRank = true },
    -- Improved Aspect of the Turtle: reduces Aspect of the Turtle CD by 30s
    { spellID = 1258485, affectsSpell = 186265, cdReduction = 30 },
    -- Padded Armor: Survival of the Fittest +1 charge
    { spellID = 459450, affectsSpell = 264735, chargeIncrease = 1 },
    { spellID = 459450, affectsSpell = 281195, chargeIncrease = 1 },

    ---------------------------------------------------------------------------
    -- DRUID
    ---------------------------------------------------------------------------
    -- Survival of the Fittest: reduces Barkskin and Survival Instincts CD by 12% per rank (2 ranks, Guardian only)
    { spellID = 203965, affectsSpell = 22812, cdReductionPct = 0.12, perRank = true },  -- Barkskin
    { spellID = 203965, affectsSpell = 61336, cdReductionPct = 0.12, perRank = true },  -- Survival Instincts

    ---------------------------------------------------------------------------
    -- MONK
    -- Skipped (dynamic): Tiger Palm/Keg Smash brew CD reduction (Brewmaster)
    ---------------------------------------------------------------------------
    -- Expeditious Fortification: reduces Fortifying Brew CD by 30s
    { spellID = 388813, affectsSpell = 115203, cdReduction = 30 },

    ---------------------------------------------------------------------------
    -- DEMONHUNTER
    -- Skipped (dynamic): World Killer (Metamorphosis -10s per 3rd Voidfall proc,
    --                     Vengeance/Annihilator hero tree only)
    ---------------------------------------------------------------------------
    -- Pitch Black: reduces Darkness CD by 120s
    { spellID = 389783, affectsSpell = 196718, cdReduction = 120 },
    -- Demonic Resilience: Blur +1 charge (Havoc/Devourer)
    { spellID = 1266307, affectsSpell = 198589, chargeIncrease = 1 },

    ---------------------------------------------------------------------------
    -- PRIEST
    ---------------------------------------------------------------------------
    -- Intangibility: reduces Dispersion CD by 30s (Shadow)
    { spellID = 288733, affectsSpell = 47585, cdReduction = 30 },
    -- Angel's Mercy: reduces Desperate Prayer CD by 20s
    { spellID = 238100, affectsSpell = 19236, cdReduction = 20 },

    ---------------------------------------------------------------------------
    -- SHAMAN
    ---------------------------------------------------------------------------
    -- Planes Traveler: reduces Astral Shift CD by 30s
    { spellID = 381647, affectsSpell = 108271, cdReduction = 30 },

    ---------------------------------------------------------------------------
    -- WARLOCK
    ---------------------------------------------------------------------------
    -- Dark Accord: reduces Unending Resolve CD by 45s
    { spellID = 386659, affectsSpell = 104773, cdReduction = 45 },

    ---------------------------------------------------------------------------
    -- EVOKER
    ---------------------------------------------------------------------------
    -- Obsidian Bulwark: Obsidian Scales +1 charge
    { spellID = 375406, affectsSpell = 363916, chargeIncrease = 1 },
    -- Interwoven Threads: reduces Obsidian Scales CD by 10% (Augmentation only)
    { spellID = 412713, affectsSpell = 363916, cdReductionPct = 0.10 },
});

-------------------------------------------------------------------------------
-- Category Registration
-------------------------------------------------------------------------------

ST:RegisterCategory("defensive", {
    label             = "Defensives",
    trackBuffDuration = true,
    defaultLayout     = "icon",
    defaultFilter     = "all",
});
