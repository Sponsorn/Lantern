local ADDON_NAME, ns = ...;

local cache = {};
local cacheBuilt = false;

local function GetDB()
    return _G.LanternCraftingOrdersDB or {};
end

local function GetThresholds(db)
    db = db or GetDB();
    return db.tipperThresholds or { bad = 5000000, good = 100000000 };
end

local function GetMeta(db, name)
    if (not db.customerMeta) then return nil; end
    return db.customerMeta[name];
end

-------------------------------------------------------------------------------
-- Build cache from scratch (called once on login)
-------------------------------------------------------------------------------

local function BuildCache()
    local db = GetDB();
    local thresholds = GetThresholds(db);
    local TipperRating = ns.TipperRating;

    cache = {};

    -- Iterate all characters' orders
    local chars = db.characters or {};
    for _, charData in pairs(chars) do
        local orders = charData.orders or {};
        for _, order in ipairs(orders) do
            local name = order.customer or "Unknown";
            if (not cache[name]) then
                cache[name] = {
                    count = 0,
                    totalTip = 0,
                    personalCount = 0,
                    personalTotalTip = 0,
                };
            end
            local c = cache[name];
            c.count = c.count + 1;
            c.totalTip = c.totalTip + (order.tip or 0);
            if (order.orderType == "personal") then
                c.personalCount = c.personalCount + 1;
                c.personalTotalTip = c.personalTotalTip + (order.tip or 0);
            end
        end
    end

    -- Compute ratings
    for name, c in pairs(cache) do
        local meta = GetMeta(db, name);
        local override = meta and meta.ratingOverride or nil;
        local nickname = meta and meta.nickname or nil;
        c.avgTip = c.count > 0 and math.floor(c.totalTip / c.count) or 0;
        c.personalAvgTip = c.personalCount > 0 and math.floor(c.personalTotalTip / c.personalCount) or 0;
        c.rating = TipperRating.GetTipperRating(c.personalAvgTip, c.personalCount, thresholds, override);
        c.nickname = nickname;
    end

    cacheBuilt = true;
end

-------------------------------------------------------------------------------
-- Incremental update (called when a new order is recorded)
-------------------------------------------------------------------------------

local function UpdateCustomer(customerName, tip, orderType)
    local db = GetDB();
    local thresholds = GetThresholds(db);
    local TipperRating = ns.TipperRating;

    if (not cache[customerName]) then
        cache[customerName] = {
            count = 0,
            totalTip = 0,
            personalCount = 0,
            personalTotalTip = 0,
            avgTip = 0,
            personalAvgTip = 0,
            rating = "neutral",
            nickname = nil,
        };
    end

    local c = cache[customerName];
    c.count = c.count + 1;
    c.totalTip = c.totalTip + (tip or 0);
    if (orderType == "personal") then
        c.personalCount = c.personalCount + 1;
        c.personalTotalTip = c.personalTotalTip + (tip or 0);
    end
    c.avgTip = c.count > 0 and math.floor(c.totalTip / c.count) or 0;
    c.personalAvgTip = c.personalCount > 0 and math.floor(c.personalTotalTip / c.personalCount) or 0;

    local meta = GetMeta(db, customerName);
    local override = meta and meta.ratingOverride or nil;
    c.rating = TipperRating.GetTipperRating(c.personalAvgTip, c.personalCount, thresholds, override);
    c.nickname = meta and meta.nickname or nil;
end

-------------------------------------------------------------------------------
-- Recompute all ratings (called when thresholds change)
-------------------------------------------------------------------------------

local function RecomputeRatings()
    local db = GetDB();
    local thresholds = GetThresholds(db);
    local TipperRating = ns.TipperRating;

    for name, c in pairs(cache) do
        local meta = GetMeta(db, name);
        local override = meta and meta.ratingOverride or nil;
        c.rating = TipperRating.GetTipperRating(c.personalAvgTip, c.personalCount, thresholds, override);
        c.nickname = meta and meta.nickname or nil;
    end
end

-------------------------------------------------------------------------------
-- Update customer metadata (nickname, ratingOverride)
-------------------------------------------------------------------------------

local function UpdateMeta(customerName, field, value)
    local db = GetDB();
    db.customerMeta = db.customerMeta or {};
    if (not db.customerMeta[customerName]) then
        db.customerMeta[customerName] = {};
    end
    db.customerMeta[customerName][field] = value;

    -- Update cache entry if it exists
    if (cache[customerName]) then
        if (field == "nickname") then
            cache[customerName].nickname = value;
        elseif (field == "ratingOverride") then
            local thresholds = GetThresholds(db);
            local TipperRating = ns.TipperRating;
            local c = cache[customerName];
            c.rating = TipperRating.GetTipperRating(c.personalAvgTip, c.personalCount, thresholds, value);
        end
    end
end

-------------------------------------------------------------------------------
-- Find all customers sharing a nickname
-------------------------------------------------------------------------------

local function GetAltsForNickname(nickname)
    if (not nickname or nickname == "") then return {}; end
    local db = GetDB();
    local alts = {};
    if (db.customerMeta) then
        for name, meta in pairs(db.customerMeta) do
            if (meta.nickname == nickname) then
                alts[#alts + 1] = name;
            end
        end
    end
    table.sort(alts);
    return alts;
end

-------------------------------------------------------------------------------
-- Lookup
-------------------------------------------------------------------------------

local function GetCustomerInfo(name)
    return cache[name];
end

local function IsBuilt()
    return cacheBuilt;
end

-------------------------------------------------------------------------------
-- Export
-------------------------------------------------------------------------------

ns.CustomerCache = {
    BuildCache           = BuildCache,
    UpdateCustomer       = UpdateCustomer,
    RecomputeRatings     = RecomputeRatings,
    UpdateMeta           = UpdateMeta,
    GetAltsForNickname   = GetAltsForNickname,
    GetCustomerInfo      = GetCustomerInfo,
    IsBuilt              = IsBuilt,
};
