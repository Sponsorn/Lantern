local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local module = Lantern:NewModule("AutoSell", {
    title = "Auto Sell",
    desc = "Automatically sell junk and custom-listed items at merchants.",
    skipOptions = true,
});

local DEFAULTS = {
    sellGrays = true,
};

local function ensureDB(self)
    if (not self.addon.db) then
        return;
    end
    if (not self.addon.db.autoSell) then
        self.addon.db.autoSell = {};
    end
    self.db = self.addon.db.autoSell;

    for k, v in pairs(DEFAULTS) do
        if (self.db[k] == nil) then
            self.db[k] = v;
        end
    end
    if (type(self.db.globalList) ~= "table") then
        self.db.globalList = {};
    end
    if (type(self.db.characterLists) ~= "table") then
        self.db.characterLists = {};
    end
end

local function shouldPause()
    return Lantern:IsModifierDown();
end

local function getCharacterKey()
    return Lantern:GetCharacterKey();
end

local function getCharacterList(db)
    local key = getCharacterKey();
    if (not key) then return nil; end
    if (not db.characterLists[key]) then
        db.characterLists[key] = {};
    end
    return db.characterLists[key];
end

function module:IsInSellList(itemID)
    if (not self.db or not itemID) then return false; end
    if (self.db.globalList[itemID]) then return true; end
    local charList = getCharacterList(self.db);
    if (charList and charList[itemID]) then return true; end
    return false;
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
    if (not C_MerchantFrame or not C_MerchantFrame.IsSellAllJunkEnabled or not C_MerchantFrame.IsSellAllJunkEnabled()) then return; end

    local totalCopper = 0;
    local itemCount = 0;

    for bag = 0, NUM_BAG_SLOTS do
        local numSlots = C_Container.GetContainerNumSlots(bag);
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bag, slot);
            if (info and info.itemID and not info.isLocked and not info.hasNoValue) then
                local shouldSell = false;

                -- Check gray items
                if (self.db.sellGrays and info.quality == Enum.ItemQuality.Poor) then
                    shouldSell = true;
                end

                -- Check custom sell lists
                if (not shouldSell) then
                    shouldSell = self:IsInSellList(info.itemID);
                end

                if (shouldSell) then
                    local _, _, _, _, _, _, _, _, _, _, sellPrice = C_Item.GetItemInfo(info.itemID);
                    if (sellPrice and sellPrice > 0) then
                        totalCopper = totalCopper + (sellPrice * (info.stackCount or 1));
                        itemCount = itemCount + 1;
                        C_Container.UseContainerItem(bag, slot);
                    end
                end
            end
        end
    end

    if (itemCount > 0) then
        local costText = Lantern:Convert("money:format_copper", totalCopper);
        local plural = itemCount > 1 and "s" or "";
        Lantern:Print("Sold " .. itemCount .. " item" .. plural .. " for " .. costText .. ".");
    end
end

Lantern:RegisterModule(module);
