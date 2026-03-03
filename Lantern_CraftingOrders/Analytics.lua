local ADDON_NAME, ns = ...;
local Lantern = _G.Lantern;
if (not Lantern) then return; end

local CraftingOrders = Lantern.modules and Lantern.modules.CraftingOrders;
if (not CraftingOrders) then return; end

local MAX_ORDERS_DEFAULT = 500;

-------------------------------------------------------------------------------
-- Database
-------------------------------------------------------------------------------

local function ensureHistoryDB()
    if (not _G.LanternCraftingOrdersDB) then
        _G.LanternCraftingOrdersDB = {};
    end
    local db = _G.LanternCraftingOrdersDB;
    db.characters = db.characters or {};
    if (db.trackHistory == nil) then db.trackHistory = true; end
    if (db.maxOrders == nil) then db.maxOrders = MAX_ORDERS_DEFAULT; end
    if (db.excludedCustomers == nil) then db.excludedCustomers = {}; end
    return db;
end

local function getCharacterKey()
    return Lantern:GetCharacterKey();
end

local function ensureCharacterData(db)
    local key = getCharacterKey();
    if (not key) then return nil, nil; end
    if (not db.characters[key]) then
        local _, class = UnitClass("player");
        db.characters[key] = {
            orders = {},
            class = class or "UNKNOWN",
            realm = GetRealmName() or "",
        };
    end
    return db.characters[key], key;
end

local function extractItemID(link)
    if (not link or type(link) ~= "string") then return nil; end
    local id = link:match("item:(%d+)");
    return id and tonumber(id) or nil;
end

-------------------------------------------------------------------------------
-- Recording
-------------------------------------------------------------------------------

function CraftingOrders:RecordOrder(orderData)
    local db = ensureHistoryDB();
    if (not db.trackHistory) then return; end

    local charData = ensureCharacterData(db);
    if (not charData) then return; end

    local record = {
        customer = orderData.customer or "Unknown",
        item = orderData.item or "",
        itemID = orderData.itemID or extractItemID(orderData.item),
        tip = orderData.tip or 0,
        cut = orderData.cut or 0,
        orderType = orderData.orderType or "unknown",
        timestamp = time(),
    };

    table.insert(charData.orders, 1, record);

    -- Prune oldest if over max
    local max = db.maxOrders or MAX_ORDERS_DEFAULT;
    while (#charData.orders > max) do
        table.remove(charData.orders);
    end
end

function CraftingOrders:GetHistoryDB()
    return ensureHistoryDB();
end

function CraftingOrders:GetCharacterOrderCount()
    local db = ensureHistoryDB();
    local charData = ensureCharacterData(db);
    if (not charData or not charData.orders) then return 0; end
    return #charData.orders;
end

function CraftingOrders:ClearCharacterHistory()
    local db = ensureHistoryDB();
    local key = getCharacterKey();
    if (key and db.characters[key]) then
        db.characters[key].orders = {};
    end
end

-------------------------------------------------------------------------------
-- Aggregation
-------------------------------------------------------------------------------

local function iterateOrders(charFilter, callback)
    local db = ensureHistoryDB();
    local excluded = db.excludedCustomers;
    if (charFilter == "all") then
        for _, charData in pairs(db.characters) do
            if (charData.orders) then
                for _, order in ipairs(charData.orders) do
                    if (not order.customer or not excluded[order.customer:lower()]) then
                        callback(order);
                    end
                end
            end
        end
    else
        local charData = ensureCharacterData(db);
        if (charData and charData.orders) then
            for _, order in ipairs(charData.orders) do
                if (not order.customer or not excluded[order.customer:lower()]) then
                    callback(order);
                end
            end
        end
    end
end

function CraftingOrders:GetCustomerList(charFilter)
    local map = {};

    iterateOrders(charFilter, function(order)
        local name = order.customer or "Unknown";
        if (not map[name]) then
            map[name] = {
                name = name,
                count = 0,
                totalTip = 0,
                firstOrder = order.timestamp,
                lastOrder = order.timestamp,
                items = {},
            };
        end
        local c = map[name];
        c.count = c.count + 1;
        c.totalTip = c.totalTip + (order.tip or 0);
        if (order.timestamp and order.timestamp < c.firstOrder) then
            c.firstOrder = order.timestamp;
        end
        if (order.timestamp and order.timestamp > c.lastOrder) then
            c.lastOrder = order.timestamp;
        end
        if (order.itemID) then c.items[order.itemID] = true; end
    end);

    local list = {};
    for _, data in pairs(map) do
        data.avgTip = data.count > 0 and math.floor(data.totalTip / data.count) or 0;
        local n = 0;
        for _ in pairs(data.items) do n = n + 1; end
        data.uniqueItems = n;
        table.insert(list, data);
    end

    return list;
end

function CraftingOrders:GetItemList(charFilter)
    local map = {};

    iterateOrders(charFilter, function(order)
        local id = order.itemID;
        if (not id) then return; end
        if (not map[id]) then
            map[id] = {
                itemID = id,
                itemLink = order.item,
                count = 0,
                totalTip = 0,
                customers = {},
            };
        end
        local it = map[id];
        it.count = it.count + 1;
        it.totalTip = it.totalTip + (order.tip or 0);
        -- Keep the most recent item link (may have updated quality)
        if (order.item and order.item ~= "") then
            it.itemLink = order.item;
        end
        if (order.customer) then it.customers[order.customer] = true; end
    end);

    local list = {};
    for _, data in pairs(map) do
        data.avgTip = data.count > 0 and math.floor(data.totalTip / data.count) or 0;
        local n = 0;
        for _ in pairs(data.customers) do n = n + 1; end
        data.uniqueCustomers = n;
        table.insert(list, data);
    end

    return list;
end

function CraftingOrders:GetDashboardStats(charFilter)
    local stats = {
        totalOrders = 0,
        totalTips = 0,
        weekOrders = 0,
        monthOrders = 0,
    };

    local now = time();
    local weekAgo = now - (7 * 24 * 3600);
    local monthAgo = now - (30 * 24 * 3600);

    iterateOrders(charFilter, function(order)
        stats.totalOrders = stats.totalOrders + 1;
        stats.totalTips = stats.totalTips + (order.tip or 0);
        if (order.timestamp and order.timestamp >= weekAgo) then
            stats.weekOrders = stats.weekOrders + 1;
        end
        if (order.timestamp and order.timestamp >= monthAgo) then
            stats.monthOrders = stats.monthOrders + 1;
        end
    end);

    stats.avgTip = stats.totalOrders > 0
        and math.floor(stats.totalTips / stats.totalOrders) or 0;

    return stats;
end

function CraftingOrders:GetCharacterKeys()
    local db = ensureHistoryDB();
    local keys = {};
    for key in pairs(db.characters) do
        table.insert(keys, key);
    end
    table.sort(keys);
    return keys;
end

function CraftingOrders:GetOrderList(charFilter)
    local db = ensureHistoryDB();
    local excluded = db.excludedCustomers;
    local list = {};
    if (charFilter == "all") then
        for charKey, charData in pairs(db.characters) do
            if (charData.orders) then
                for idx, order in ipairs(charData.orders) do
                    if (not order.customer or not excluded[order.customer:lower()]) then
                        table.insert(list, {
                            charKey = charKey,
                            index = idx,
                            customer = order.customer,
                            item = order.item,
                            itemID = order.itemID,
                            tip = order.tip or 0,
                            orderType = order.orderType,
                            timestamp = order.timestamp or 0,
                        });
                    end
                end
            end
        end
    else
        local charData, charKey = ensureCharacterData(db);
        if (charData and charData.orders and charKey) then
            for idx, order in ipairs(charData.orders) do
                if (not order.customer or not excluded[order.customer:lower()]) then
                    table.insert(list, {
                        charKey = charKey,
                        index = idx,
                        customer = order.customer,
                        item = order.item,
                        itemID = order.itemID,
                        tip = order.tip or 0,
                        orderType = order.orderType,
                        timestamp = order.timestamp or 0,
                    });
                end
            end
        end
    end
    -- Sort newest first
    table.sort(list, function(a, b) return (a.timestamp or 0) > (b.timestamp or 0); end);
    return list;
end

function CraftingOrders:RemoveOrder(charKey, index)
    local db = ensureHistoryDB();
    if (not charKey or not index) then return; end
    local charData = db.characters and db.characters[charKey];
    if (not charData or not charData.orders) then return; end
    if (index < 1 or index > #charData.orders) then return; end
    table.remove(charData.orders, index);
end

-------------------------------------------------------------------------------
-- Customer exclusion
-------------------------------------------------------------------------------

function CraftingOrders:GetExcludedCustomers()
    local db = ensureHistoryDB();
    return db.excludedCustomers;
end

function CraftingOrders:AddExcludedCustomer(name)
    if (not name) then return false; end
    name = strtrim(name):lower();
    if (name == "") then return false; end
    local db = ensureHistoryDB();
    if (db.excludedCustomers[name]) then return false; end
    db.excludedCustomers[name] = true;
    return true;
end

function CraftingOrders:RemoveExcludedCustomer(name)
    if (not name) then return; end
    local db = ensureHistoryDB();
    db.excludedCustomers[name:lower()] = nil;
end

-------------------------------------------------------------------------------
-- Expose DB helpers
-------------------------------------------------------------------------------

CraftingOrders._ensureHistoryDB = ensureHistoryDB;
CraftingOrders._ensureCharacterData = ensureCharacterData;
CraftingOrders._extractItemID = extractItemID;
