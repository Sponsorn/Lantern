local ADDON_NAME, ns = ...;
local L = ns.L;
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
-- Expose DB helpers
-------------------------------------------------------------------------------

CraftingOrders._ensureHistoryDB = ensureHistoryDB;
CraftingOrders._ensureCharacterData = ensureCharacterData;
CraftingOrders._extractItemID = extractItemID;
