local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local module = Lantern:NewModule("AutoKeystone", {
    title = "Auto Keystone",
    desc = "Automatically slot your Mythic+ keystone when the Challenge Mode UI opens.",
    skipOptions = true,
});

local function shouldPause()
    return Lantern:IsModifierDown();
end

function module:OnEnable()
    self.addon:ModuleRegisterEvent(self, "CHALLENGE_MODE_KEYSTONE_RECEPTABLE_OPEN", function()
        if (not self.enabled or shouldPause()) then return; end

        C_Timer.After(0.1, function()
            local mapID = C_ChallengeMode.GetActiveChallengeMapID();
            if (mapID) then return; end

            -- Scan bags for keystone
            for bag = 0, 4 do
                local numSlots = C_Container.GetContainerNumSlots(bag);
                for slot = 1, numSlots do
                    local info = C_Container.GetContainerItemInfo(bag, slot);
                    if (info and info.itemID) then
                        local _, _, _, _, _, classID, subclassID = C_Item.GetItemInfoInstant(info.itemID);
                        -- Class 15 (Miscellaneous), Subclass 0 (Junk) covers keystones
                        -- Also check known keystone item IDs
                        if (info.itemID == 180653 or info.itemID == 187786 or info.itemID == 158923 or info.itemID == 151086) then
                            C_Container.PickupContainerItem(bag, slot);
                            if (CursorHasItem()) then
                                C_ChallengeMode.SlotKeystone();
                            end
                            return;
                        end
                    end
                end
            end
        end);
    end);
end

Lantern:RegisterModule(module);
