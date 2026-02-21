-- Patch LibRangeCheck-3.0 to add Devourer Demon Hunter (new in 12.0).
-- The lib's spell tables are local, so we hook init() and inject checkers post-init.
-- When the upstream library adds this spec, the duplicate-range guard skips our entry.

local ADDON_NAME, addon = ...;

local LRC = LibStub and LibStub("LibRangeCheck-3.0", true);
if (not LRC) then return; end

local _, playerClass = UnitClass("player");
if (playerClass ~= "DEMONHUNTER") then return; end

local CONSUME_SPELL_ID = 473662; -- Consume (Devourer DH, 25 yards)

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
    if (IsPlayerSpell(CONSUME_SPELL_ID)) then
        local checker = function(unit)
            return C_Spell.IsSpellInRange(CONSUME_SPELL_ID, unit);
        end;
        local info = "spell:" .. CONSUME_SPELL_ID .. ":Lantern";
        inject(self.harmRC, 25, checker, info);
        inject(self.harmRCInCombat, 25, checker, info);
        inject(self.harmNoItemsRC, 25, checker, info);
        inject(self.harmNoItemsRCInCombat, 25, checker, info);
    end
end;
