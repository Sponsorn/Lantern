local ADDON_NAME, Lantern = ...;
if (not Lantern or not Lantern.SpellTracker) then return; end
local ST = Lantern.SpellTracker;

local spells = {
    -- WARRIOR
    {
        id       = 871,
        cd       = 210,
        duration = 8,
        charges  = nil,
        class    = "WARRIOR",
        specs    = { [73] = true },
        category = "defensive",
    },
    {
        id       = 118038,
        cd       = 120,
        duration = 8,
        charges  = nil,
        class    = "WARRIOR",
        specs    = { [71] = true },
        category = "defensive",
    },
    {
        id       = 184364,
        cd       = 120,
        duration = 8,
        charges  = nil,
        class    = "WARRIOR",
        specs    = { [72] = true },
        category = "defensive",
    },

    -- PALADIN
    {
        id       = 642,
        cd       = 300,
        duration = 8,
        charges  = nil,
        class    = "PALADIN",
        specs    = nil,
        category = "defensive",
    },
    {
        id       = 31850,
        cd       = 120,
        duration = 8,
        charges  = nil,
        class    = "PALADIN",
        specs    = { [66] = true },
        category = "defensive",
    },

    -- DEATHKNIGHT
    {
        id       = 48707,
        cd       = 60,
        duration = 5,
        charges  = nil,
        class    = "DEATHKNIGHT",
        specs    = nil,
        category = "defensive",
    },
    {
        id       = 48792,
        cd       = 180,
        duration = 8,
        charges  = nil,
        class    = "DEATHKNIGHT",
        specs    = nil,
        category = "defensive",
    },

    -- ROGUE
    {
        id       = 31224,
        cd       = 120,
        duration = 5,
        charges  = nil,
        class    = "ROGUE",
        specs    = nil,
        category = "defensive",
    },
    {
        id       = 5277,
        cd       = 120,
        duration = 10,
        charges  = nil,
        class    = "ROGUE",
        specs    = nil,
        category = "defensive",
    },

    -- MAGE
    {
        id       = 45438,
        cd       = 240,
        duration = 10,
        charges  = nil,
        class    = "MAGE",
        specs    = nil,
        category = "defensive",
    },

    -- HUNTER
    {
        id       = 186265,
        cd       = 180,
        duration = 8,
        charges  = nil,
        class    = "HUNTER",
        specs    = nil,
        category = "defensive",
    },

    -- DRUID
    {
        id       = 22812,
        cd       = 60,
        duration = 8,
        charges  = nil,
        class    = "DRUID",
        specs    = nil,
        category = "defensive",
    },
    {
        id       = 61336,
        cd       = 180,
        duration = 6,
        charges  = 2,
        class    = "DRUID",
        specs    = { [103] = true, [104] = true },
        category = "defensive",
    },

    -- MONK
    {
        id       = 115203,
        cd       = 180,
        duration = 15,
        charges  = nil,
        class    = "MONK",
        specs    = nil,
        category = "defensive",
    },

    -- DEMONHUNTER
    {
        id       = 198589,
        cd       = 60,
        duration = 10,
        charges  = nil,
        class    = "DEMONHUNTER",
        specs    = { [577] = true },
        category = "defensive",
    },
    {
        id       = 187827,
        cd       = 180,
        duration = 15,
        charges  = nil,
        class    = "DEMONHUNTER",
        specs    = { [581] = true },
        category = "defensive",
    },

    -- PRIEST
    {
        id       = 47585,
        cd       = 120,
        duration = 6,
        charges  = nil,
        class    = "PRIEST",
        specs    = { [258] = true },
        category = "defensive",
    },

    -- SHAMAN
    {
        id       = 108271,
        cd       = 120,
        duration = 12,
        charges  = nil,
        class    = "SHAMAN",
        specs    = nil,
        category = "defensive",
    },

    -- WARLOCK
    {
        id       = 104773,
        cd       = 180,
        duration = 8,
        charges  = nil,
        class    = "WARLOCK",
        specs    = nil,
        category = "defensive",
    },

    -- EVOKER
    {
        id       = 363916,
        cd       = 90,
        duration = 12,
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
    spellsPerPlayer   = "all",
    trackBuffDuration = true,
    defaultLayout     = "icon",
    defaultFilter     = "hide_ready",
});
