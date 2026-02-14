local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

-------------------------------------------------------------------------------
-- Module namespace (shared across SpellTracker files via addon table)
-------------------------------------------------------------------------------

local ST = {};
Lantern.SpellTracker = ST;

-- Category registry
ST.categories = {};       -- ordered array: { key, config }
ST.categoryMap = {};      -- key -> config

-- Tracked player data
ST.trackedPlayers = {};   -- "Name-Realm" -> { class, spec, spells = { [spellID] = state } }
ST.excludedPlayers = {};  -- "Name-Realm" -> true

-- Player info
ST.playerClass = nil;
ST.playerName = nil;

-- DB reference (set on init)
ST.db = nil;

-------------------------------------------------------------------------------
-- Category Registration
-------------------------------------------------------------------------------

function ST:RegisterCategory(key, config)
    if (self.categoryMap[key]) then return; end
    config.key = key;
    config.enabled = true;  -- runtime state, read from DB on init
    table.insert(self.categories, { key = key, config = config });
    self.categoryMap[key] = config;
end

function ST:GetCategory(key)
    return self.categoryMap[key];
end

function ST:GetEnabledCategories()
    local result = {};
    for _, entry in ipairs(self.categories) do
        if (entry.config.enabled) then
            table.insert(result, entry.config);
        end
    end
    return result;
end

-------------------------------------------------------------------------------
-- DB Defaults
-------------------------------------------------------------------------------

local DEFAULTS = {
    categories = {},  -- per-category settings: { [key] = { enabled, layout, filter, ... } }
};

local CATEGORY_DEFAULTS = {
    enabled      = true,
    layout       = nil,     -- nil = use category's defaultLayout
    filter       = nil,     -- nil = use category's defaultFilter
    showSelf     = true,
    sortMode     = "remaining",
    selfOnTop    = false,
    locked       = false,
    growUp       = false,
    position     = nil,
    -- Bar-specific
    barWidth     = 220,
    barHeight    = 28,
    barAlpha     = 0.9,
    font         = "Friz Quadrata TT",
    fontOutline  = "OUTLINE",
    -- Icon-specific
    iconSize     = 28,
    iconSpacing  = 2,
    showNames    = true,
};

local function getDB()
    if (not Lantern.db) then Lantern.db = {}; end
    if (not Lantern.db.spellTracker) then Lantern.db.spellTracker = {}; end
    local db = Lantern.db.spellTracker;
    for k, v in pairs(DEFAULTS) do
        if (db[k] == nil) then db[k] = v; end
    end
    ST.db = db;
    return db;
end

function ST:GetCategoryDB(categoryKey)
    local db = getDB();
    if (not db.categories[categoryKey]) then
        db.categories[categoryKey] = {};
    end
    local catDB = db.categories[categoryKey];
    for k, v in pairs(CATEGORY_DEFAULTS) do
        if (catDB[k] == nil) then catDB[k] = v; end
    end
    return catDB;
end

-------------------------------------------------------------------------------
-- Module Definition
-------------------------------------------------------------------------------

local module = Lantern:NewModule("SpellTracker", {
    title = "Spell Tracker",
    desc = "Tracks party member spell cooldowns (interrupts, defensives, major CDs).",
    skipOptions = true,
    defaultEnabled = false,
});

ST.module = module;

function module:OnInit()
    getDB();
end

function module:OnEnable()
    getDB();

    local _, cls = UnitClass("player");
    ST.playerClass = cls;
    ST.playerName = UnitName("player");

    -- Sync category enabled states from DB
    for _, entry in ipairs(ST.categories) do
        local catDB = ST:GetCategoryDB(entry.key);
        entry.config.enabled = catDB.enabled;
    end

    -- Engine.lua handles the rest (events, detection, display)
    if (ST.EnableEngine) then
        ST:EnableEngine();
    end
end

function module:OnDisable()
    if (ST.DisableEngine) then
        ST:DisableEngine();
    end

    ST.trackedPlayers = {};
    ST.excludedPlayers = {};
end

Lantern:RegisterModule(module);
