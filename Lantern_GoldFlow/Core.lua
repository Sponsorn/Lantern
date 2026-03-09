local ADDON_NAME, ns = ...;
local Lantern = _G.Lantern;
if (not Lantern) then return; end

local module = Lantern:NewModule("GoldFlow", {
    title = "GoldFlow",
    desc = "Economic data tracker for the Lantern companion app.",
    defaultEnabled = true,
});

ns.module = module;

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local DB_VERSION = 1;
local MAX_TRANSACTIONS = 1000;

-------------------------------------------------------------------------------
-- Database
-------------------------------------------------------------------------------

local function EnsureDB()
    -- Always re-read the global in case WoW replaced it after SavedVariables load.
    local db = _G.GoldFlowDB;
    if (not db) then
        db = {};
        _G.GoldFlowDB = db;
    end

    db.version = db.version or DB_VERSION;
    db.lastUpdated = db.lastUpdated or 0;
    db.characters = db.characters or {};
    db.transactions = db.transactions or {};
    db.warbandGold = db.warbandGold or 0;
    db.accountBankItems = db.accountBankItems or {};
    db.settings = db.settings or {};
    db.lastSyncedTimestamp = db.lastSyncedTimestamp or 0;

    local s = db.settings;
    if (s.scanInventory == nil) then s.scanInventory = true; end
    if (s.scanProfessions == nil) then s.scanProfessions = true; end
    if (s.trackTransactions == nil) then s.trackTransactions = true; end
    if (s.trackListings == nil) then s.trackListings = true; end

    module.db = db;

    -- Trim transactions older than lastSyncedTimestamp (once per session)
    if (not module._trimmedThisSession and db.lastSyncedTimestamp > 0 and #db.transactions > 0) then
        module._trimmedThisSession = true;
        local trimmed = {};
        for _, tx in ipairs(db.transactions) do
            if (tx.timestamp and tx.timestamp >= db.lastSyncedTimestamp) then
                table.insert(trimmed, tx);
            end
        end
        db.transactions = trimmed;
    end
end

-------------------------------------------------------------------------------
-- Character Helpers
-------------------------------------------------------------------------------

local function GetCharKey()
    local name = UnitName("player");
    local realm = GetRealmName();
    if (not name or not realm) then return nil; end
    return name .. "-" .. realm;
end

local function EnsureCharacter()
    local key = GetCharKey();
    if (not key) then return nil; end

    local db = module.db;
    if (not db.characters[key]) then
        local name = UnitName("player");
        local realm = GetRealmName();
        local realmSlug = (GetNormalizedRealmName() or ""):lower();
        local _, classFile = UnitClass("player");

        db.characters[key] = {
            name = name,
            realm = realm,
            realmSlug = realmSlug,
            class = classFile,
            gold = 0,
            lastSeen = 0,
            professions = {},
            inventory = {
                bags = {},
                bank = {},
            },
            listings = {},
        };
    end

    return db.characters[key];
end

-------------------------------------------------------------------------------
-- Transaction Helpers
-------------------------------------------------------------------------------

local function AddTransaction(tx)
    if (not tx) then return; end
    local db = module.db;
    if (not db or not db.settings.trackTransactions) then return; end

    tx.timestamp = tx.timestamp or GetServerTime();
    tx.character = tx.character or GetCharKey();

    table.insert(db.transactions, 1, tx);

    -- Trim to max
    while (#db.transactions > MAX_TRANSACTIONS) do
        table.remove(db.transactions);
    end
end

-------------------------------------------------------------------------------
-- Utility
-------------------------------------------------------------------------------

local function UpdateTimestamp()
    if (module.db) then
        module.db.lastUpdated = GetServerTime();
    end
end

local function Setting(key)
    if (module.db and module.db.settings and module.db.settings[key] ~= nil) then
        return module.db.settings[key];
    end
    return true;
end

-------------------------------------------------------------------------------
-- Expose helpers for other files
-------------------------------------------------------------------------------

module.EnsureDB = EnsureDB;
module.GetCharKey = GetCharKey;
module.EnsureCharacter = EnsureCharacter;
module.AddTransaction = AddTransaction;
module.UpdateTimestamp = UpdateTimestamp;
module.Setting = Setting;
module.DB_VERSION = DB_VERSION;
module.MAX_TRANSACTIONS = MAX_TRANSACTIONS;

-------------------------------------------------------------------------------
-- Lifecycle
-------------------------------------------------------------------------------

function module:OnEnable()
    -- Don't call EnsureDB here — SavedVariables may not be loaded yet if
    -- initializeModule runs during file execution. Defer to OnInit or first use.
    self.RegisterScannerEvents(self);
    self.RegisterTransactionEvents(self);
    self.RegisterListingEvents(self);
    if (self.RegisterBuyListEvents) then
        self.RegisterBuyListEvents(self);
    end

    -- PLAYER_ENTERING_WORLD may have already fired before this external addon
    -- registered for it. Do a delayed initial scan as a safety net.
    C_Timer.After(2, function()
        if (not self.enabled) then return; end
        if (not self._initialScanDone) then
            self:OnPlayerEnteringWorld();
        end
    end);
end

function module:OnDisable()
    -- Events are auto-unregistered by the core framework.
end

-------------------------------------------------------------------------------
-- Commands
-------------------------------------------------------------------------------

function module:ForceSave()
    UpdateTimestamp();
    Lantern:Print("GoldFlow data synced.");
end

function module:ClearData()
    StaticPopup_Show("GOLDFLOW_CONFIRM_CLEAR");
end

StaticPopupDialogs["GOLDFLOW_CONFIRM_CLEAR"] = {
    text = "Reset ALL GoldFlow data? This cannot be undone.",
    button1 = YES,
    button2 = NO,
    OnAccept = function()
        _G.GoldFlowDB = nil;
        EnsureDB();
        Lantern:Print("GoldFlow data has been reset.");
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
};
