local ADDON_NAME, ns = ...;
local Lantern = _G.Lantern;
if (not Lantern) then return; end

local CraftingOrders = Lantern.modules and Lantern.modules.CraftingOrders;
if (not CraftingOrders) then return; end

local MAX_ORDERS_DEFAULT = 2000;

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
    if (db.trackOrderTypes == nil) then db.trackOrderTypes = { guild = true, personal = true }; end
    if (db.showResetTimers == nil) then db.showResetTimers = true; end
    if (db.resetTimers == nil) then db.resetTimers = { mode = "auto" }; end
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

local function isOrderTypeVisible(db, orderType)
    local types = db.trackOrderTypes;
    if (not types) then return true; end
    if (orderType == "guild") then return types.guild ~= false; end
    if (orderType == "personal") then return types.personal ~= false; end
    return true;
end

local function iterateOrders(charFilter, callback, since)
    local db = ensureHistoryDB();
    local excluded = db.excludedCustomers;
    if (charFilter == "all") then
        for _, charData in pairs(db.characters) do
            if (charData.orders) then
                for _, order in ipairs(charData.orders) do
                    if ((not since or (order.timestamp and order.timestamp >= since))
                        and (not order.customer or not excluded[order.customer:lower()])
                        and isOrderTypeVisible(db, order.orderType)) then
                        callback(order);
                    end
                end
            end
        end
    else
        local charData = ensureCharacterData(db);
        if (charData and charData.orders) then
            for _, order in ipairs(charData.orders) do
                if ((not since or (order.timestamp and order.timestamp >= since))
                    and (not order.customer or not excluded[order.customer:lower()])
                    and isOrderTypeVisible(db, order.orderType)) then
                    callback(order);
                end
            end
        end
    end
end

function CraftingOrders:GetCustomerList(charFilter, since)
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
    end, since);

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

function CraftingOrders:GetCustomerOrders(customerName, charFilter)
    local list = {};

    iterateOrders(charFilter, function(order)
        if ((order.customer or "Unknown") == customerName) then
            table.insert(list, {
                item = order.item,
                itemID = order.itemID,
                tip = order.tip or 0,
                orderType = order.orderType,
                timestamp = order.timestamp or 0,
            });
        end
    end);

    -- Sort newest first
    table.sort(list, function(a, b) return a.timestamp > b.timestamp; end);
    return list;
end

function CraftingOrders:GetItemList(charFilter, since)
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
    end, since);

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
        dayOrders = 0,
        dayTips = 0,
        weekOrders = 0,
        weekTips = 0,
        monthOrders = 0,
        monthTips = 0,
    };

    local now = time();
    local dayAgo = now - (24 * 3600);
    local weekAgo = now - (7 * 24 * 3600);
    local monthAgo = now - (30 * 24 * 3600);

    iterateOrders(charFilter, function(order)
        local tip = order.tip or 0;
        stats.totalOrders = stats.totalOrders + 1;
        stats.totalTips = stats.totalTips + tip;
        if (order.timestamp) then
            if (order.timestamp >= dayAgo) then
                stats.dayOrders = stats.dayOrders + 1;
                stats.dayTips = stats.dayTips + tip;
            end
            if (order.timestamp >= weekAgo) then
                stats.weekOrders = stats.weekOrders + 1;
                stats.weekTips = stats.weekTips + tip;
            end
            if (order.timestamp >= monthAgo) then
                stats.monthOrders = stats.monthOrders + 1;
                stats.monthTips = stats.monthTips + tip;
            end
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
                    if ((not order.customer or not excluded[order.customer:lower()]) and isOrderTypeVisible(db, order.orderType)) then
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
                if ((not order.customer or not excluded[order.customer:lower()]) and isOrderTypeVisible(db, order.orderType)) then
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
-- Order type tracking
-------------------------------------------------------------------------------

function CraftingOrders:GetTrackOrderTypes()
    local db = ensureHistoryDB();
    return db.trackOrderTypes;
end

function CraftingOrders:SetTrackOrderType(orderType, enabled)
    local db = ensureHistoryDB();
    db.trackOrderTypes[orderType] = enabled;
end

function CraftingOrders:IsOrderTypeTracked(orderType)
    local db = ensureHistoryDB();
    return isOrderTypeVisible(db, orderType);
end

-------------------------------------------------------------------------------
-- Reset timer settings
-------------------------------------------------------------------------------

function CraftingOrders:GetShowResetTimers()
    local db = ensureHistoryDB();
    return db.showResetTimers ~= false;
end

function CraftingOrders:SetShowResetTimers(enabled)
    local db = ensureHistoryDB();
    db.showResetTimers = enabled;
end

function CraftingOrders:GetResetTimerSettings()
    local db = ensureHistoryDB();
    return db.resetTimers;
end

function CraftingOrders:SetResetTimerSetting(key, value)
    local db = ensureHistoryDB();
    db.resetTimers[key] = value;
end

-- Get the offset (in seconds) between server time and UTC
-- Positive means server is ahead of UTC
function CraftingOrders:GetServerTimeOffset()
    local serverHour, serverMin = GetGameTime();
    local now = GetServerTime();
    local utcHour = tonumber(date("!%H", now));
    local utcMin = tonumber(date("!%M", now));
    local serverSec = serverHour * 3600 + serverMin * 60;
    local utcSec = utcHour * 3600 + utcMin * 60;
    local offset = serverSec - utcSec;
    -- Normalize to [-12h, +12h]
    if (offset > 43200) then offset = offset - 86400; end
    if (offset < -43200) then offset = offset + 86400; end
    return offset;
end

-- Returns next daily and weekly reset epochs based on settings
function CraftingOrders:GetResetEpochs()
    if (not self:GetShowResetTimers()) then return nil, nil; end

    local settings = self:GetResetTimerSettings();
    local now = GetServerTime();

    local nextDailyReset, nextWeeklyReset;

    if (settings.mode == "custom") then
        -- Custom: user-defined hours in realm time, convert to UTC for calculation
        local offset = self:GetServerTimeOffset();
        local dailyHourRealm = settings.dailyHour or 7;
        local weeklyDay = settings.weeklyDay or 2; -- 0=Sun..6=Sat
        local weeklyHourRealm = settings.weeklyHour or 7;

        -- Convert realm hours to UTC epoch targets
        local dailyHourUTC_sec = dailyHourRealm * 3600 - offset;
        local weeklyHourUTC_sec = weeklyHourRealm * 3600 - offset;

        -- Calculate next daily reset
        local daysSinceEpoch = math.floor(now / 86400);
        local todayResetUTC = daysSinceEpoch * 86400 + dailyHourUTC_sec;
        if (now >= todayResetUTC) then
            nextDailyReset = todayResetUTC + 86400;
        else
            nextDailyReset = todayResetUTC;
        end

        -- Calculate next weekly reset
        local candidate = daysSinceEpoch * 86400 + weeklyHourUTC_sec;
        if (now >= candidate) then
            candidate = candidate + 86400;
        end
        for _ = 1, 7 do
            local wday = tonumber(date("!%w", candidate));
            if (wday == weeklyDay) then
                nextWeeklyReset = candidate;
                break;
            end
            candidate = candidate + 86400;
        end
    else
        -- Auto: use region-detected resets
        local lastDaily = Lantern:GetLastDailyResetEpoch(now);
        nextDailyReset = lastDaily and (lastDaily + 86400) or nil;
        nextWeeklyReset = Lantern:GetNextWeeklyResetEpoch(now);
    end

    return nextDailyReset, nextWeeklyReset;
end

-------------------------------------------------------------------------------
-- Heat map aggregation
-------------------------------------------------------------------------------

function CraftingOrders:GetHeatMapData(charFilter, since)
    local offset = self:GetServerTimeOffset();
    local orders = {};
    local gold = {};
    local maxOrders = 0;
    local maxGold = 0;

    for day = 0, 6 do
        orders[day] = {};
        gold[day] = {};
        for hour = 0, 23 do
            orders[day][hour] = 0;
            gold[day][hour] = 0;
        end
    end

    iterateOrders(charFilter, function(order)
        if (not order.timestamp) then return; end
        local realmTime = order.timestamp + offset;
        local wday = tonumber(date("!%w", realmTime));
        local hour = tonumber(date("!%H", realmTime));

        orders[wday][hour] = orders[wday][hour] + 1;
        if (orders[wday][hour] > maxOrders) then
            maxOrders = orders[wday][hour];
        end

        local tip = order.tip or 0;
        gold[wday][hour] = gold[wday][hour] + tip;
        if (gold[wday][hour] > maxGold) then
            maxGold = gold[wday][hour];
        end
    end, since);

    return {
        orders = orders,
        gold = gold,
        maxOrders = maxOrders,
        maxGold = maxGold,
    };
end

-------------------------------------------------------------------------------
-- Earnings chart aggregation
-------------------------------------------------------------------------------

function CraftingOrders:GetEarningsChartData(charFilter, bucketType, since)
    local offset = self:GetServerTimeOffset();
    local buckets = {};
    local bucketOrder = {};
    local maxValue = 0;

    iterateOrders(charFilter, function(order)
        if (not order.timestamp) then return; end
        local realmTime = order.timestamp + offset;
        local key;
        if (bucketType == "weekly") then
            -- Find Monday of this week
            local wday = tonumber(date("!%w", realmTime)); -- 0=Sun
            local mondayOffset = (wday == 0) and 6 or (wday - 1);
            local mondayEpoch = realmTime - mondayOffset * 86400;
            key = date("!%Y-%m-%d", mondayEpoch);
        else
            key = date("!%Y-%m-%d", realmTime);
        end

        if (not buckets[key]) then
            buckets[key] = 0;
            table.insert(bucketOrder, key);
        end
        local tip = order.tip or 0;
        buckets[key] = buckets[key] + tip;
    end, since);

    -- Sort bucket keys chronologically
    table.sort(bucketOrder);

    -- Month abbreviation lookup
    local months = { "Jan", "Feb", "Mar", "Apr", "May", "Jun",
                     "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" };

    local function formatLabel(key)
        local y, m, d = key:match("(%d+)-(%d+)-(%d+)");
        if (not y) then return ""; end
        local mon = months[tonumber(m)] or m;
        local day = tonumber(d);
        if (bucketType ~= "weekly") then
            return mon .. " " .. day;
        end
        -- Weekly: show range "Mar 3-9" or "Mar 28-Apr 3"
        local mondayEpoch = time({ year = tonumber(y), month = tonumber(m), day = day, hour = 12 });
        local sundayEpoch = mondayEpoch + 6 * 86400;
        local sunM = tonumber(date("!%m", sundayEpoch));
        local sunD = tonumber(date("!%d", sundayEpoch));
        if (sunM == tonumber(m)) then
            return mon .. " " .. day .. "-" .. sunD;
        else
            return mon .. " " .. day .. "-" .. (months[sunM] or sunM) .. " " .. sunD;
        end
    end

    -- Build result with formatted labels
    local result = {};
    for _, key in ipairs(bucketOrder) do
        local value = buckets[key];
        table.insert(result, { label = formatLabel(key), value = value, dateKey = key });
        if (value > maxValue) then maxValue = value; end
    end

    -- Fill gaps: ensure every day/week in range has a bucket
    if (since) then
        local now = GetServerTime();
        local realmNow = now + offset;
        local step = (bucketType == "weekly") and 7 * 86400 or 86400;
        local cursor = since + offset;

        -- Build lookup from existing buckets
        local lookup = {};
        for _, b in ipairs(result) do
            lookup[b.dateKey] = b;
        end

        while (cursor <= realmNow) do
            local key;
            if (bucketType == "weekly") then
                local wday = tonumber(date("!%w", cursor));
                local mondayOffset = (wday == 0) and 6 or (wday - 1);
                local mondayEpoch = cursor - mondayOffset * 86400;
                key = date("!%Y-%m-%d", mondayEpoch);
            else
                key = date("!%Y-%m-%d", cursor);
            end

            if (not lookup[key]) then
                lookup[key] = { label = formatLabel(key), value = 0, dateKey = key };
            end

            cursor = cursor + step;
        end

        -- Rebuild sorted
        result = {};
        for key, b in pairs(lookup) do
            table.insert(result, b);
        end
        table.sort(result, function(a, b) return a.dateKey < b.dateKey; end);
    end

    return {
        buckets = result,
        maxValue = maxValue,
    };
end

-------------------------------------------------------------------------------
-- Expose DB helpers
-------------------------------------------------------------------------------

CraftingOrders._ensureHistoryDB = ensureHistoryDB;
CraftingOrders._ensureCharacterData = ensureCharacterData;
CraftingOrders._extractItemID = extractItemID;
