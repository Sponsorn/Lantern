local L = select(2, ...).L;
local Lantern = _G.Lantern;
if (not Lantern or not Lantern.modules or not Lantern.modules.Warband) then return; end

-- Guard: Retail only (account bank tabs don't exist in Classic)
if (not Enum or not Enum.BagIndex or not Enum.BagIndex.AccountBankTab_1) then return; end

local Warband = Lantern.modules.Warband;

local Warehousing = {};
Warband.Warehousing = Warehousing;

-- Inventory constants
local INVENTORY_START = 0;
local INVENTORY_END = 4;
local WARBANK_TAB_START = Enum.BagIndex.AccountBankTab_1;
local WARBANK_TAB_END = Enum.BagIndex.AccountBankTab_5;

local function getDB()
    if (not Warband.db) then return nil; end
    if (not Warband.db.warehousing) then
        Warband.db.warehousing = { groups = {} };
    end
    if (not Warband.db.warehousing.groups) then
        Warband.db.warehousing.groups = {};
    end

    -- Migrate old formats to new enabled/all/limit model
    for _, group in pairs(Warband.db.warehousing.groups) do
        if (group.depositEnabled == nil) then
            if (group.depositMode ~= nil) then
                -- Original format: depositMode + limit
                local oldLimit = group.limit or 0;
                group.depositEnabled = true;
                group.depositAll = true;
                group.depositLimit = 0;
                group.restockEnabled = (oldLimit > 0);
                group.restockAll = false;
                group.restockLimit = oldLimit;
                group.keepEnabled = (group.depositMode == "keep_limit");
                group.keepLimit = (group.depositMode == "keep_limit") and oldLimit or 0;
                group.depositMode = nil;
                group.limit = nil;
            else
                -- Intermediate numeric-only format
                group.depositEnabled = (group.depositLimit or 0) > 0;
                group.depositAll = not group.depositEnabled;
                group.restockEnabled = (group.restockLimit or 0) > 0;
                group.restockAll = not group.restockEnabled;
                group.keepEnabled = (group.keepLimit or 0) > 0;
            end
        end
    end

    return Warband.db.warehousing;
end

-- Group CRUD

function Warehousing:CreateGroup(name)
    local db = getDB();
    if (not db) then return false; end
    if (not name or name == "") then return false; end
    if (db.groups[name]) then return false; end

    db.groups[name] = {
        name = name,
        depositEnabled = false,
        depositAll = true,
        depositLimit = 0,
        restockEnabled = false,
        restockAll = true,
        restockLimit = 0,
        keepEnabled = false,
        keepLimit = 0,
        items = {},
    };
    return true;
end

function Warehousing:DeleteGroup(name)
    local db = getDB();
    if (not db) then return false; end
    if (not name or not db.groups[name]) then return false; end

    db.groups[name] = nil;
    return true;
end

function Warehousing:GetAllGroups()
    local db = getDB();
    if (not db) then return {}; end
    return db.groups;
end

function Warehousing:GetGroup(name)
    local db = getDB();
    if (not db) then return nil; end
    return db.groups[name];
end

function Warehousing:SetGroupDepositLimit(name, val)
    local db = getDB();
    if (not db or not db.groups[name]) then return false; end

    val = tonumber(val);
    if (not val or val < 0) then return false; end

    db.groups[name].depositLimit = val;
    return true;
end

function Warehousing:SetGroupRestockLimit(name, val)
    local db = getDB();
    if (not db or not db.groups[name]) then return false; end

    val = tonumber(val);
    if (not val or val < 0) then return false; end

    db.groups[name].restockLimit = val;
    return true;
end

function Warehousing:SetGroupKeepLimit(name, val)
    local db = getDB();
    if (not db or not db.groups[name]) then return false; end

    val = tonumber(val);
    if (not val or val < 0) then return false; end

    db.groups[name].keepLimit = val;
    return true;
end

function Warehousing:AddItemToGroup(groupName, itemID, itemName)
    local db = getDB();
    if (not db or not db.groups[groupName]) then return false; end

    itemID = tonumber(itemID);
    if (not itemID) then return false; end

    db.groups[groupName].items[itemID] = itemName or "";
    return true;
end

function Warehousing:RemoveItemFromGroup(groupName, itemID)
    local db = getDB();
    if (not db or not db.groups[groupName]) then return false; end

    itemID = tonumber(itemID);
    if (not itemID) then return false; end

    db.groups[groupName].items[itemID] = nil;
    return true;
end

-- Scanning

function Warehousing:ScanInventory()
    local results = {};

    for bag = INVENTORY_START, INVENTORY_END do
        local numSlots = C_Container.GetContainerNumSlots(bag);
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bag, slot);
            if (info and info.itemID) then
                local itemID = info.itemID;
                if (not results[itemID]) then
                    results[itemID] = { total = 0, slots = {} };
                end
                results[itemID].total = results[itemID].total + info.stackCount;
                table.insert(results[itemID].slots, {
                    bag = bag,
                    slot = slot,
                    count = info.stackCount,
                });
            end
        end
    end

    return results;
end

function Warehousing:ScanWarbank()
    local results = {};

    for bag = WARBANK_TAB_START, WARBANK_TAB_END do
        local numSlots = C_Container.GetContainerNumSlots(bag);
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bag, slot);
            if (info and info.itemID) then
                local itemID = info.itemID;
                if (not results[itemID]) then
                    results[itemID] = { total = 0, slots = {} };
                end
                results[itemID].total = results[itemID].total + info.stackCount;
                table.insert(results[itemID].slots, {
                    bag = bag,
                    slot = slot,
                    count = info.stackCount,
                });
            end
        end
    end

    return results;
end

function Warehousing:GetUngroupedInventoryItems()
    local db = getDB();
    if (not db) then return {}; end

    -- Build set of all itemIDs across all groups
    local grouped = {};
    for _, group in pairs(db.groups) do
        if (group.items) then
            for itemID, _ in pairs(group.items) do
                grouped[itemID] = true;
            end
        end
    end

    -- Scan inventory and filter
    local ungrouped = {};
    for bag = INVENTORY_START, INVENTORY_END do
        local numSlots = C_Container.GetContainerNumSlots(bag);
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bag, slot);
            if (info and info.itemID and not grouped[info.itemID] and not ungrouped[info.itemID]) then
                local itemName = C_Item.GetItemNameByID(info.itemID) or "";
                local itemIcon = C_Item.GetItemIconByID(info.itemID);
                ungrouped[info.itemID] = {
                    name = itemName,
                    count = 0,
                    icon = itemIcon,
                };
            end
            -- Accumulate count
            if (info and info.itemID and ungrouped[info.itemID]) then
                ungrouped[info.itemID].count = ungrouped[info.itemID].count + info.stackCount;
            end
        end
    end

    return ungrouped;
end

-- Trim source slots to only enough to cover the needed amount
local function trimSlots(slots, amount)
    -- Sort by count descending (prefer larger stacks)
    table.sort(slots, function(a, b) return a.count > b.count; end);

    local trimmed = {};
    local covered = 0;
    for _, s in ipairs(slots) do
        if (covered >= amount) then break; end
        table.insert(trimmed, s);
        covered = covered + s.count;
    end
    return trimmed;
end

-- Compute operations

function Warehousing:ComputeDeposit(groupName)
    local db = getDB();
    if (not db or not db.groups[groupName]) then return {}; end

    local group = db.groups[groupName];
    local inventoryItems = self:ScanInventory();
    local operations = {};

    for itemID, itemName in pairs(group.items) do
        local inventoryData = inventoryItems[itemID];
        local inventoryCount = inventoryData and inventoryData.total or 0;

        if (inventoryCount > 0) then
            -- Pre-check: verify item is allowed in account bank
            local allowed = true;
            if (C_Bank and C_Bank.IsItemAllowedInBankType and inventoryData.slots and inventoryData.slots[1]) then
                local firstSlot = inventoryData.slots[1];
                local itemLoc = ItemLocation:CreateFromBagAndSlot(firstSlot.bag, firstSlot.slot);
                if (itemLoc and itemLoc:IsValid()) then
                    allowed = C_Bank.IsItemAllowedInBankType(Enum.BankType.Account, itemLoc);
                end
            end

            if (not allowed) then
                local name = itemName ~= "" and itemName or ("item " .. tostring(itemID));
                Lantern:Print(string.format(L["WARBAND_WH_MSG_SKIP_NOT_WARBOUND"], name));
            elseif (group.depositEnabled) then
                local depositAmount;
                if (group.depositAll) then
                    depositAmount = inventoryCount;
                else
                    depositAmount = math.min(inventoryCount, group.depositLimit);
                end

                -- Apply keep limit: don't let bags drop below keepLimit
                if (group.keepEnabled and group.keepLimit > 0) then
                    local maxDeposit = math.max(0, inventoryCount - group.keepLimit);
                    depositAmount = math.min(depositAmount, maxDeposit);
                end

                if (depositAmount > 0) then
                    table.insert(operations, {
                        itemID = itemID,
                        itemName = itemName,
                        mode = "deposit",
                        amount = depositAmount,
                        limit = math.max(0, inventoryCount - depositAmount),
                        sourceSlots = trimSlots(inventoryData.slots, depositAmount),
                    });
                end
            end
        end
    end

    return operations;
end

function Warehousing:ComputeRestock(groupName)
    local db = getDB();
    if (not db or not db.groups[groupName]) then return {}; end

    local group = db.groups[groupName];
    local inventoryItems = self:ScanInventory();
    local warbankItems = self:ScanWarbank();
    local operations = {};

    for itemID, itemName in pairs(group.items) do
        local inventoryData = inventoryItems[itemID];
        local warbankData = warbankItems[itemID];
        local inventoryCount = inventoryData and inventoryData.total or 0;
        local warbankCount = warbankData and warbankData.total or 0;

        if (group.restockEnabled and warbankCount > 0) then
            local deficit;
            if (group.restockAll) then
                deficit = warbankCount;
            else
                if (inventoryCount >= group.restockLimit) then
                    deficit = 0;
                else
                    deficit = group.restockLimit - inventoryCount;
                end
            end

            -- Apply keep limit: don't let warbank drop below keepLimit
            if (group.keepEnabled and group.keepLimit > 0) then
                local maxWithdraw = math.max(0, warbankCount - group.keepLimit);
                deficit = math.min(deficit, maxWithdraw);
            end

            local withdrawAmount = math.min(deficit, warbankCount);

            if (withdrawAmount > 0) then
                local restockTarget = group.restockAll and (inventoryCount + withdrawAmount) or group.restockLimit;
                table.insert(operations, {
                    itemID = itemID,
                    itemName = itemName,
                    mode = "withdraw",
                    amount = withdrawAmount,
                    limit = restockTarget,
                    sourceSlots = trimSlots(warbankData.slots, withdrawAmount),
                });
            end
        end
    end

    return operations;
end
