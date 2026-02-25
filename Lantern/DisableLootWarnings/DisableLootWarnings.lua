local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end
local L = Lantern.L;

local module = Lantern:NewModule("DisableLootWarnings", {
    title = L["LOOTWARNINGS_TITLE"],
    desc = L["LOOTWARNINGS_DESC"],
    skipOptions = true,
    defaultEnabled = false,
});

local DEFAULTS = {
    lootRoll = true,
    bindOnPickup = true,
    merchantRefund = true,
    mailLock = true,
};

local function ensureDB(self)
    if (not self.addon.db) then return; end
    if (not self.addon.db.disableLootWarnings) then
        self.addon.db.disableLootWarnings = {};
    end
    self.db = self.addon.db.disableLootWarnings;
    for k, v in pairs(DEFAULTS) do
        if (self.db[k] == nil) then
            self.db[k] = v;
        end
    end
end

local function shouldPause()
    return Lantern:IsModifierDown();
end

function module:OnInit()
    ensureDB(self);
end

function module:OnEnable()
    ensureDB(self);

    self.addon:ModuleRegisterEvent(self, "CONFIRM_LOOT_ROLL", function(_, _, rollID, rollType)
        if (not self.db.lootRoll or shouldPause()) then return; end
        ConfirmLootRoll(rollID, rollType);
    end);

    self.addon:ModuleRegisterEvent(self, "LOOT_BIND_CONFIRM", function(_, _, slot)
        if (not self.db.bindOnPickup or shouldPause()) then return; end
        ConfirmLootSlot(slot);
    end);

    self.addon:ModuleRegisterEvent(self, "MERCHANT_CONFIRM_TRADE_TIMER_REMOVAL", function(_, _, itemLink)
        if (not self.db.merchantRefund or shouldPause()) then return; end
        SellCursorItem();
    end);

    self.addon:ModuleRegisterEvent(self, "MAIL_LOCK_SEND_ITEMS", function()
        if (not self.db.mailLock or shouldPause()) then return; end
        local popup = StaticPopup_FindVisible("MAIL_LOCK_SEND_ITEMS");
        if (popup) then
            local btn = popup.button1;
            if (btn) then btn:Click(); end
        end
    end);
end

Lantern:RegisterModule(module);
