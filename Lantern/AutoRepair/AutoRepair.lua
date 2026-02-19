local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local module = Lantern:NewModule("AutoRepair", {
    title = "Auto Repair",
    desc = "Automatically repair gear at merchants.",
    skipOptions = true,
});

local DEFAULTS = {
    source = "personal", -- "personal", "guild_first", "guild_only"
};

local function ensureDB(self)
    if (not self.addon.db) then
        return;
    end
    if (not self.addon.db.autoRepair) then
        self.addon.db.autoRepair = {};
    end
    self.db = self.addon.db.autoRepair;

    for k, v in pairs(DEFAULTS) do
        if (self.db[k] == nil) then
            self.db[k] = v;
        end
    end
end

local function shouldPause()
    return Lantern:IsModifierDown();
end

local function canUseGuildRepair(repairCost)
    if (not IsInGuild()) then return false; end
    if (not CanGuildBankRepair()) then return false; end
    local available = GetGuildBankWithdrawMoney();
    -- -1 means unlimited withdrawal
    if (available == -1) then return true; end
    return available >= repairCost;
end

function module:OnInit()
    ensureDB(self);
end

function module:OnEnable()
    ensureDB(self);
    self.addon:ModuleRegisterEvent(self, "MERCHANT_SHOW", self.OnMerchantShow);
end

function module:OnMerchantShow()
    if (not self.enabled or shouldPause()) then return; end
    if (not CanMerchantRepair()) then return; end

    local repairCost, canRepair = GetRepairAllCost();
    if (not canRepair or repairCost <= 0) then return; end

    local source = self.db.source or "personal";
    local costText = Lantern:Convert("money:format_copper", repairCost);
    local useGuild = (source ~= "personal") and canUseGuildRepair(repairCost);

    if (source == "guild_only" and not useGuild) then
        Lantern:Print("Cannot repair: guild funds unavailable.");
        return;
    end

    if (useGuild) then
        RepairAllItems(true);
        Lantern:Print("Repaired for " .. costText .. " (guild funds).");
    elseif (GetMoney() >= repairCost) then
        RepairAllItems(false);
        Lantern:Print("Repaired for " .. costText .. ".");
    else
        Lantern:Print("Cannot repair: not enough gold (" .. costText .. " needed).");
    end
end

Lantern:RegisterModule(module);
