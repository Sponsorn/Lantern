local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end
local L = Lantern.L;

local module = Lantern:NewModule("DisableAutoAddSpells", {
    title = L["DISABLEAUTOADD_TITLE"],
    desc = L["DISABLEAUTOADD_DESC"],
    skipOptions = true,
});

local function removePushedSpell(_, _, _, slotIndex)
    if InCombatLockdown and InCombatLockdown() then return; end
    if ClearCursor then ClearCursor(); end
    if PickupAction and slotIndex then
        PickupAction(slotIndex);
    end
    if ClearCursor then ClearCursor(); end
end

function module:OnEnable()
    if IconIntroTracker then
        if (not self._origIconIntroRegisterEvent) then
            self._origIconIntroRegisterEvent = IconIntroTracker.RegisterEvent;
        end
        IconIntroTracker.RegisterEvent = function() end
        IconIntroTracker:UnregisterEvent("SPELL_PUSHED_TO_ACTIONBAR");
    end
    self.addon:ModuleRegisterEvent(self, "SPELL_PUSHED_TO_ACTIONBAR", removePushedSpell);
end

function module:OnDisable()
    if IconIntroTracker and self._origIconIntroRegisterEvent then
        IconIntroTracker.RegisterEvent = self._origIconIntroRegisterEvent;
        IconIntroTracker:RegisterEvent("SPELL_PUSHED_TO_ACTIONBAR");
    end
end

Lantern:RegisterModule(module);
