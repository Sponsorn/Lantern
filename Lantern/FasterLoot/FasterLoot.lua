local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end
local L = Lantern.L;

local module = Lantern:NewModule("FasterLoot", {
    title = L["FASTERLOOT_TITLE"],
    desc = L["FASTERLOOT_DESC"],
    skipOptions = true,
});

local function shouldPause()
    return Lantern:IsModifierDown();
end

local inventoryFullWarned = false;

function module:OnEnable()
    self.addon:ModuleRegisterEvent(self, "LOOT_READY", self.OnLootReady);
    self.addon:ModuleRegisterEvent(self, "UI_ERROR_MESSAGE", self.OnUIError);
end

function module:OnLootReady()
    if (not self.enabled or shouldPause()) then return; end
    inventoryFullWarned = false;

    local numItems = GetNumLootItems();
    if (numItems == 0) then return; end

    for i = numItems, 1, -1 do
        LootSlot(i);
    end
end

function module:OnUIError(_, errorType, message)
    if (not self.enabled or inventoryFullWarned) then return; end
    if (message and message == ERR_INV_FULL) then
        Lantern:Print(L["FASTERLOOT_MSG_INV_FULL"]);
        inventoryFullWarned = true;
    end
end

Lantern:RegisterModule(module);
