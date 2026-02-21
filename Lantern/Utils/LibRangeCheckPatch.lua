-- Patch LibRangeCheck-3.0 with spells missing from the upstream library.
-- The lib's spell tables are local, so we hook init() and inject checkers post-init.
-- When the upstream library adds these spells, the duplicate-range guard skips our entries.

local ADDON_NAME, addon = ...;

local LRC = LibStub and LibStub("LibRangeCheck-3.0", true);
if (not LRC) then return; end

local _, playerClass = UnitClass("player");

-- Extra harm spells the library doesn't include yet (keyed by class).
-- Uses C_Spell.IsSpellInRange (modern API) for tighter range detection.
local EXTRA_HARM = {
    DEATHKNIGHT = {
        { id = 49998, range = 5 },  -- Death Strike (Melee Range)
    },
    DEMONHUNTER = {
        { id = 473662, range = 25 }, -- Consume (Devourer) (25 yards)
        { id = 162243, range = 5 },  -- Demon's Bite (Havoc) (Melee Range)
    },
    HUNTER = {
        { id = 186270, range = 5 },  -- Raptor Strike (Survival) (Melee Range)
    },
    ROGUE = {
        { id = 1752, range = 5 },    -- Sinister Strike (Melee Range)
    },
    WARRIOR = {
        { id = 1464, range = 5 },    -- Slam (Arms/Fury) (Melee Range)
        { id = 23922, range = 5 },   -- Shield Slam (Protection) (Melee Range)
    },
};

local spells = EXTRA_HARM[playerClass];
if (not spells) then return; end

-- Sorted insert matching the lib's addChecker: descending range, skip duplicates.
local function inject(list, range, checker, info)
    for i = 1, #list do
        if (list[i].range == range) then return; end
        if (range > list[i].range) then
            table.insert(list, i, { range = range, minRange = nil, checker = checker, info = info });
            return;
        end
    end
    table.insert(list, { range = range, minRange = nil, checker = checker, info = info });
end

local origInit = LRC.init;
LRC.init = function(self, forced)
    origInit(self, forced);
    for _, spell in ipairs(spells) do
        if (IsPlayerSpell(spell.id)) then
            local spellID = spell.id;
            local checker = function(unit)
                return C_Spell.IsSpellInRange(spellID, unit);
            end;
            local info = "spell:" .. spellID .. ":Lantern";
            inject(self.harmRC, spell.range, checker, info);
            inject(self.harmRCInCombat, spell.range, checker, info);
            inject(self.harmNoItemsRC, spell.range, checker, info);
            inject(self.harmNoItemsRCInCombat, spell.range, checker, info);
        end
    end
end;
