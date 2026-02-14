local ADDON_NAME, NS = ...;
local ST = NS.SpellTracker;
if (not ST) then return; end

-- Spell database populated by tracker files via ST:RegisterSpells()
ST.spellDB = {};          -- spellID -> spell entry
ST.talentModifiers = {};  -- array of talent modifier entries
ST.spellAliases = {};     -- altSpellID -> canonicalSpellID

function ST:RegisterSpells(spells)
    for _, spell in ipairs(spells) do
        self.spellDB[spell.id] = spell;
    end
end

function ST:RegisterTalentModifiers(modifiers)
    for _, mod in ipairs(modifiers) do
        table.insert(self.talentModifiers, mod);
    end
end

function ST:RegisterSpellAliases(aliases)
    for alt, canonical in pairs(aliases) do
        self.spellAliases[alt] = canonical;
    end
end

function ST:GetSpellsForCategory(categoryKey)
    local result = {};
    for id, spell in pairs(self.spellDB) do
        if (spell.category == categoryKey) then
            result[id] = spell;
        end
    end
    return result;
end

function ST:GetSpellsForClassAndCategory(class, spec, categoryKey)
    local result = {};
    for id, spell in pairs(self.spellDB) do
        if (spell.category == categoryKey and spell.class == class) then
            if (not spell.specs or (spec and spell.specs[spec])) then
                result[id] = spell;
            end
        end
    end
    return result;
end
