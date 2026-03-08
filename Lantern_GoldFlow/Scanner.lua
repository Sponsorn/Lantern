local ADDON_NAME, ns = ...;
local Lantern = _G.Lantern;
if (not Lantern) then return; end

local module = ns.module;
if (not module) then return; end

-------------------------------------------------------------------------------
-- Local references
-------------------------------------------------------------------------------

local C_Container = C_Container;
local C_TradeSkillUI = C_TradeSkillUI;
local GetProfessions = GetProfessions;
local GetProfessionInfo = GetProfessionInfo;
local C_Bank = C_Bank;
local GetMoney = GetMoney;

-------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------

local BAG_UPDATE_INTERVAL = 0.5;
local bagUpdateTimer = nil;
local recipesScannedThisSession = false;

-------------------------------------------------------------------------------
-- Registration
-------------------------------------------------------------------------------

function module.RegisterScannerEvents(self)
    self.addon:ModuleRegisterEvent(self, "PLAYER_ENTERING_WORLD", self.OnPlayerEnteringWorld);
    self.addon:ModuleRegisterEvent(self, "PLAYER_MONEY", self.OnPlayerMoney);
    self.addon:ModuleRegisterEvent(self, "ACCOUNT_MONEY", self.OnAccountMoney);
    self.addon:ModuleRegisterEvent(self, "BAG_UPDATE", self.OnBagUpdate);
    self.addon:ModuleRegisterEvent(self, "BANKFRAME_OPENED", self.OnBankOpened);
    self.addon:ModuleRegisterEvent(self, "TRADE_SKILL_SHOW", self.OnTradeSkillShow);
    self.addon:ModuleRegisterEvent(self, "TRADE_SKILL_LIST_UPDATE", self.OnTradeSkillListUpdate);
end

-------------------------------------------------------------------------------
-- Character Scan
-------------------------------------------------------------------------------

local function ScanCharacter()
    local char = module.EnsureCharacter();
    if (not char) then return; end

    local name = UnitName("player");
    local realm = GetRealmName();
    local _, classFile = UnitClass("player");

    char.name = name;
    char.realm = realm;
    char.realmSlug = GetNormalizedRealmName() or "";
    char.class = classFile;
    char.gold = GetMoney();
    char.lastSeen = GetServerTime();
end

-------------------------------------------------------------------------------
-- Warband Gold
-------------------------------------------------------------------------------

local function ScanWarbandGold()
    if (not C_Bank or not C_Bank.FetchDepositedMoney) then return; end
    local ok, amount = pcall(C_Bank.FetchDepositedMoney, Enum.BankType.Account);
    if (ok and amount) then
        module.db.warbandGold = amount;
    end
end

-------------------------------------------------------------------------------
-- Inventory Scanning
-------------------------------------------------------------------------------

local function ScanBags()
    if (not module.Setting("scanInventory")) then return; end

    local char = module.EnsureCharacter();
    if (not char) then return; end

    local bags = {};
    -- Backpack (0) through NumBags (4) + ReagentBag (5)
    for bagID = 0, 5 do
        local numSlots = C_Container.GetContainerNumSlots(bagID);
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bagID, slot);
            if (info and info.itemID) then
                bags[info.itemID] = (bags[info.itemID] or 0) + (info.stackCount or 1);
            end
        end
    end

    char.inventory = char.inventory or {};
    char.inventory.bags = bags;
    module.UpdateTimestamp();
end

local function ScanBank()
    if (not module.Setting("scanInventory")) then return; end

    local char = module.EnsureCharacter();
    if (not char) then return; end

    local bank = {};
    -- CharacterBankTab_1 (6) through CharacterBankTab_6 (11)
    for bagID = 6, 11 do
        local numSlots = C_Container.GetContainerNumSlots(bagID);
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bagID, slot);
            if (info and info.itemID) then
                bank[info.itemID] = (bank[info.itemID] or 0) + (info.stackCount or 1);
            end
        end
    end

    char.inventory = char.inventory or {};
    char.inventory.bank = bank;
    module.UpdateTimestamp();
end

local function ScanAccountBank()
    if (not module.Setting("scanInventory")) then return; end

    local items = {};
    -- AccountBankTab_1 (12) through AccountBankTab_5 (16)
    for bagID = 12, 16 do
        local numSlots = C_Container.GetContainerNumSlots(bagID);
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bagID, slot);
            if (info and info.itemID) then
                items[info.itemID] = (items[info.itemID] or 0) + (info.stackCount or 1);
            end
        end
    end

    module.db.accountBankItems = items;
    module.UpdateTimestamp();
end

-------------------------------------------------------------------------------
-- Profession Scanning
-------------------------------------------------------------------------------

local function ScanProfessionsBasic()
    if (not module.Setting("scanProfessions")) then return; end

    local char = module.EnsureCharacter();
    if (not char) then return; end

    local prof1, prof2, archaeology, fishing, cooking = GetProfessions();
    local professions = {};

    local indices = { prof1, prof2, archaeology, fishing, cooking };
    for _, idx in ipairs(indices) do
        if (idx) then
            local name, _, skillLevel, maxSkillLevel = GetProfessionInfo(idx);
            if (name) then
                table.insert(professions, {
                    name = name,
                    skillLevel = skillLevel or 0,
                    maxSkillLevel = maxSkillLevel or 0,
                    specialization = nil,
                    recipes = {},
                });
            end
        end
    end

    char.professions = professions;
    module.UpdateTimestamp();
end

local function ScanRecipes()
    if (not module.Setting("scanProfessions")) then return; end
    if (recipesScannedThisSession) then return; end
    if (not C_TradeSkillUI.IsTradeSkillReady or not C_TradeSkillUI.IsTradeSkillReady()) then return; end

    local char = module.EnsureCharacter();
    if (not char) then return; end

    local baseProfInfo = C_TradeSkillUI.GetBaseProfessionInfo and C_TradeSkillUI.GetBaseProfessionInfo();
    if (not baseProfInfo or not baseProfInfo.professionName) then return; end

    -- Find matching profession entry
    local profEntry = nil;
    for _, prof in ipairs(char.professions or {}) do
        if (prof.name == baseProfInfo.professionName) then
            profEntry = prof;
            break;
        end
    end
    if (not profEntry) then return; end

    profEntry.skillLevel = baseProfInfo.skillLevel or profEntry.skillLevel;
    profEntry.maxSkillLevel = baseProfInfo.maxSkillLevel or profEntry.maxSkillLevel;

    local recipeIDs = C_TradeSkillUI.GetFilteredRecipeIDs();
    if (not recipeIDs) then return; end

    local recipes = {};
    for _, recipeID in ipairs(recipeIDs) do
        local recipeInfo = C_TradeSkillUI.GetRecipeInfo(recipeID);
        if (recipeInfo and recipeInfo.learned) then
            local categories = {};
            if (recipeInfo.categoryID) then
                local catInfo = C_TradeSkillUI.GetCategoryInfo(recipeInfo.categoryID);
                if (catInfo and catInfo.name) then
                    table.insert(categories, catInfo.name);
                end
            end
            recipes[recipeID] = {
                rank = recipeInfo.unlockedRecipeLevel or 1,
                categories = categories,
            };
        end
    end

    profEntry.recipes = recipes;
    recipesScannedThisSession = true;
    module.UpdateTimestamp();
end

-------------------------------------------------------------------------------
-- Event Handlers
-------------------------------------------------------------------------------

function module:OnPlayerEnteringWorld()
    ScanCharacter();
    ScanWarbandGold();
    ScanBags();
    ScanProfessionsBasic();
end

function module:OnPlayerMoney()
    local char = module.EnsureCharacter();
    if (char) then
        char.gold = GetMoney();
        char.lastSeen = GetServerTime();
    end
    module.UpdateTimestamp();
end

function module:OnAccountMoney()
    ScanWarbandGold();
end

function module:OnBagUpdate()
    if (bagUpdateTimer) then return; end
    bagUpdateTimer = C_Timer.After(BAG_UPDATE_INTERVAL, function()
        bagUpdateTimer = nil;
        ScanBags();
    end);
end

function module:OnBankOpened()
    ScanBank();
    ScanAccountBank();
end

function module:OnTradeSkillShow()
    ScanProfessionsBasic();
end

function module:OnTradeSkillListUpdate()
    -- Defer recipe scan to avoid cascading UI invalidation
    -- (conflicts with addons like CraftScan that hook the trade skill data provider)
    if (recipesScannedThisSession) then return; end
    C_Timer.After(1, function()
        if (module.enabled and not recipesScannedThisSession) then
            ScanRecipes();
        end
    end);
end
