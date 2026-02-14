local ADDON_NAME, Lantern = ...;
if (not Lantern or not Lantern.SpellTracker) then return; end
local ST = Lantern.SpellTracker;

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
    -- Shaman: Wind Shear
    {
        id       = 57994,
        cd       = 12,
        duration = nil,
        charges  = nil,
        class    = "SHAMAN",
        specs    = nil,
        category = "interrupts",
    },
    -- Warlock: Spell Lock (Felhunter)
    {
        id       = 19647,
        cd       = 24,
        duration = nil,
        charges  = nil,
        class    = "WARLOCK",
        specs    = nil,
        category = "interrupts",
    },
    -- Warlock: Spell Lock (Felhunter alt ID)
    {
        id       = 132409,
        cd       = 24,
        duration = nil,
        charges  = nil,
        class    = "WARLOCK",
        specs    = nil,
        category = "interrupts",
    },
    -- Warlock: Axe Toss (Felguard)
    {
        id       = 119914,
        cd       = 30,
        duration = nil,
        charges  = nil,
        class    = "WARLOCK",
        specs    = nil,
        category = "interrupts",
    },
    -- Warlock: Fel Ravager (Felguard ability)
    {
        id       = 1276467,
        cd       = 25,
        duration = nil,
        charges  = nil,
        class    = "WARLOCK",
        specs    = nil,
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
    [1276467] = 132409,  -- Fel Ravager -> Spell Lock (Felhunter alt ID)
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

    -- Spec-specific interrupt overrides (specID -> override)
    specOverrides = {
        [255] = { spellID = 187707, cd = 15 },                -- Survival Hunter: Muzzle
        [264] = { spellID = 57994,  cd = 30 },                -- Resto Shaman: Wind Shear at 30s
        [266] = { spellID = 119914, cd = 30, isPet = true },  -- Demo Warlock: Axe Toss (pet)
    },
};
