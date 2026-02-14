local ADDON_NAME, NS = ...;

-------------------------------------------------------------------------------
-- Module namespace (shared across MythicTracker files via addon table)
-------------------------------------------------------------------------------

local ST = {};
NS.SpellTracker = ST;

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
-- Print Helper
-------------------------------------------------------------------------------

function ST:Print(msg)
    local Lantern = _G.Lantern;
    if (Lantern and Lantern.Print) then
        Lantern:Print(msg);
    else
        print("|cFF33FF99[Mythic+ Tracker]|r " .. tostring(msg));
    end
end

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
    -- Docking
    dockTo       = nil,
};

local function getDB()
    if (not _G.LanternMythicTrackerDB) then _G.LanternMythicTrackerDB = {}; end
    local db = _G.LanternMythicTrackerDB;
    for k, v in pairs(DEFAULTS) do
        if (db[k] == nil) then
            -- Deep copy table defaults so each saved DB gets its own table
            if (type(v) == "table") then
                local copy = {};
                for dk, dv in pairs(v) do copy[dk] = dv; end
                db[k] = copy;
            else
                db[k] = v;
            end
        end
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
-- Init / Enable / Disable
-------------------------------------------------------------------------------

function ST:Init()
    getDB();
end

function ST:Enable()
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

function ST:Disable()
    if (ST.DisableEngine) then
        ST:DisableEngine();
    end

    ST.trackedPlayers = {};
    ST.excludedPlayers = {};
end

-------------------------------------------------------------------------------
-- Bootstrap: Lantern module or standalone
-------------------------------------------------------------------------------

local Lantern = _G.Lantern;
local hasLantern = Lantern and Lantern.NewModule;

-- Both paths use ADDON_LOADED to ensure all TOC files are loaded first.
-- Without this, Lantern:RegisterModule() fires OnEnable immediately
-- (Lantern.ready is already true), but Engine.lua / Display.lua haven't
-- loaded yet so ST.EnableEngine would be nil.

local loader = CreateFrame("Frame");
loader:RegisterEvent("ADDON_LOADED");
loader:SetScript("OnEvent", function(self, event, addonName)
    if (addonName ~= ADDON_NAME) then return; end
    self:UnregisterEvent("ADDON_LOADED");

    if (hasLantern) then
        -- Running as a Lantern module
        local module = Lantern:NewModule("MythicTracker", {
            title = "Mythic+ Tracker",
            desc = "Tracks party member spell cooldowns (interrupts, defensives, major CDs).",
            skipOptions = true,
            defaultEnabled = true,
        });

        ST.module = module;

        function module:OnInit()
            ST:Init();
        end

        function module:OnEnable()
            ST:Enable();
        end

        function module:OnDisable()
            ST:Disable();
        end

        Lantern:RegisterModule(module);
    else
        -- Standalone mode
        ST:Init();
        ST:Enable();
    end
end);
