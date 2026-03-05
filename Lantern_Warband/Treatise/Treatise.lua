local L = select(2, ...).L;
local Lantern = _G.Lantern;
if (not Lantern or not Lantern.modules or not Lantern.modules.Warband) then return; end
if (not Enum or not Enum.BagIndex or not Enum.BagIndex.AccountBankTab_1) then return; end

local Warband = Lantern.modules.Warband;

local Treatise = {};
Warband.Treatise = Treatise;

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local WARBANK_TAB_START = Enum.BagIndex.AccountBankTab_1;
local WARBANK_TAB_END = Enum.BagIndex.AccountBankTab_5;
local INVENTORY_START = 0;
local INVENTORY_END = 4;

-- Midnight treatises: ordered by profession name for display
local MIDNIGHT_TREATISES = {
    { name = "Alchemy",        skillLineID = 171, itemID = 245755, questID = 95127 },
    { name = "Blacksmithing",  skillLineID = 164, itemID = 245763, questID = 95128 },
    { name = "Enchanting",     skillLineID = 333, itemID = 245759, questID = 95129 },
    { name = "Engineering",    skillLineID = 202, itemID = 245809, questID = 83728 },
    { name = "Herbalism",      skillLineID = 182, itemID = 245761, questID = 95130 },
    { name = "Inscription",    skillLineID = 773, itemID = 245757, questID = 95131 },
    { name = "Jewelcrafting",  skillLineID = 755, itemID = 245760, questID = 95133 },
    { name = "Leatherworking", skillLineID = 165, itemID = 245758, questID = 95134 },
    { name = "Mining",         skillLineID = 186, itemID = 245762, questID = 95135 },
    { name = "Skinning",       skillLineID = 393, itemID = 245828, questID = 95136 },
    { name = "Tailoring",      skillLineID = 197, itemID = 245756, questID = 95137 },
};

Treatise.MIDNIGHT_TREATISES = MIDNIGHT_TREATISES;

-------------------------------------------------------------------------------
-- Profession Detection
-------------------------------------------------------------------------------

-- Returns a set of base skillLineIDs the current character has: { [skillLineID] = true }
function Treatise:GetPlayerProfessions()
    local result = {};

    -- GetProfessions() is character-specific (unlike GetAllProfessionTradeSkillLines which is warband-wide)
    if (GetProfessions) then
        local prof1, prof2 = GetProfessions();
        for _, idx in ipairs({ prof1, prof2 }) do
            if (idx) then
                local _, _, _, _, _, _, skillLineID = GetProfessionInfo(idx);
                if (skillLineID) then
                    result[skillLineID] = true;
                end
            end
        end
    end

    return result;
end

-------------------------------------------------------------------------------
-- Warbank Scanning
-------------------------------------------------------------------------------

-- Scan warbank tabs for treatise itemIDs
-- Returns { [itemID] = { total = count, slots = { {bag, slot}, ... } } }
function Treatise:ScanWarbank()
    local found = {};

    -- Build lookup set for treatise itemIDs
    local treatiseItems = {};
    for _, t in ipairs(MIDNIGHT_TREATISES) do
        treatiseItems[t.itemID] = true;
    end

    for bag = WARBANK_TAB_START, WARBANK_TAB_END do
        local numSlots = C_Container.GetContainerNumSlots(bag);
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bag, slot);
            if (info and info.itemID and treatiseItems[info.itemID]) then
                local id = info.itemID;
                if (not found[id]) then
                    found[id] = { total = 0, slots = {} };
                end
                found[id].total = found[id].total + info.stackCount;
                table.insert(found[id].slots, { bag = bag, slot = slot });
            end
        end
    end

    return found;
end

-------------------------------------------------------------------------------
-- Status Aggregation
-------------------------------------------------------------------------------

-- Returns an ordered list of treatise status entries:
-- { name, itemID, questID, skillLineID, count, playerHas, completedThisWeek }
function Treatise:GetTreatiseStatus()
    local professions = self:GetPlayerProfessions();
    local warbank = self:ScanWarbank();
    local status = {};

    for _, t in ipairs(MIDNIGHT_TREATISES) do
        local warbankData = warbank[t.itemID];
        local count = warbankData and warbankData.total or 0;
        local playerHas = professions[t.skillLineID] or false;
        local completed = C_QuestLog.IsQuestFlaggedCompleted(t.questID);

        table.insert(status, {
            name = t.name,
            itemID = t.itemID,
            questID = t.questID,
            skillLineID = t.skillLineID,
            count = count,
            slots = warbankData and warbankData.slots or {},
            playerHas = playerHas,
            completedThisWeek = completed,
        });
    end

    return status;
end

-------------------------------------------------------------------------------
-- Bag Utilities
-------------------------------------------------------------------------------

-- Returns a set of treatise itemIDs the player has in bags: { [itemID] = true }
function Treatise:GetInventoryTreatises()
    local found = {};
    local treatiseItems = {};
    for _, t in ipairs(MIDNIGHT_TREATISES) do
        treatiseItems[t.itemID] = true;
    end

    for bag = INVENTORY_START, INVENTORY_END do
        local numSlots = C_Container.GetContainerNumSlots(bag);
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bag, slot);
            if (info and info.itemID and treatiseItems[info.itemID]) then
                found[info.itemID] = true;
            end
        end
    end
    return found;
end

-- Find first empty bag slot (bags 0-4)
function Treatise:FindFreeBagSlot()
    for bag = INVENTORY_START, INVENTORY_END do
        local numSlots = C_Container.GetContainerNumSlots(bag);
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bag, slot);
            if (not info) then
                return bag, slot;
            end
        end
    end
    return nil, nil;
end
