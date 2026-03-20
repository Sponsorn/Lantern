local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end
local L = Lantern.L;

local module = Lantern:NewModule("AutoQueue", {
    title = L["AUTOQUEUE_TITLE"],
    desc = L["AUTOQUEUE_DESC"],
    defaultEnabled = false,
    skipOptions = true,
});

local DEFAULTS = {
    active = true,
    announce = true,
    autoAcceptInvite = false,
    oneClickSignUp = false,
};

local function ensureDB(self)
    self.db = Lantern.utils.InitModuleDB(self.addon, "autoQueue", DEFAULTS);
end

local function shouldPause()
    return Lantern:IsModifierDown();
end

--------------------------------------------------------------------------------
-- Auto-accept group invite hook
--------------------------------------------------------------------------------

local function OnInviteDialogShow(dialog, resultID)
    if (not module.enabled or not module.db.autoAcceptInvite or shouldPause()) then return; end
    if (dialog.informational) then return; end

    C_LFGList.AcceptInvite(resultID);
    StaticPopupSpecial_Hide(dialog);

    if (module.db.announce) then
        Lantern:Print(L["AUTOQUEUE_MSG_INVITE_ACCEPTED"]);
    end
end

--------------------------------------------------------------------------------
-- One-click sign-up hooks
--------------------------------------------------------------------------------

-- Step 1: Click a group row → immediately call SignUp (skips clicking the
-- Sign Up button at the bottom of the search panel)
local function OnSearchEntryClick(entry, button)
    if (not module.enabled or not module.db.oneClickSignUp or shouldPause()) then return; end
    if (button == "RightButton") then return; end

    local panel = LFGListFrame and LFGListFrame.SearchPanel;
    if (not panel or not panel.SignUpButton or not panel.SignUpButton:IsEnabled()) then return; end
    if (not LFGListSearchPanelUtil_CanSelectResult or not LFGListSearchPanelUtil_CanSelectResult(entry.resultID)) then return; end

    if (panel.selectedResult ~= entry.resultID) then
        LFGListSearchPanel_SelectResult(panel, entry.resultID);
    end
    LFGListSearchPanel_SignUp(panel);
end

-- Step 2: When the role/note confirmation dialog appears, auto-click SignUp
local function OnApplicationDialogShow(dialog, resultID)
    if (not module.enabled or not module.db.oneClickSignUp or shouldPause()) then return; end

    -- Ensure at least one role is selected; fall back to first available
    local tankSelected = dialog.TankButton:IsShown() and dialog.TankButton.CheckButton:GetChecked();
    local healerSelected = dialog.HealerButton:IsShown() and dialog.HealerButton.CheckButton:GetChecked();
    local dpsSelected = dialog.DamagerButton:IsShown() and dialog.DamagerButton.CheckButton:GetChecked();

    if (not tankSelected and not healerSelected and not dpsSelected) then
        if (dialog.TankButton:IsShown()) then
            dialog.TankButton.CheckButton:SetChecked(true);
        elseif (dialog.HealerButton:IsShown()) then
            dialog.HealerButton.CheckButton:SetChecked(true);
        elseif (dialog.DamagerButton:IsShown()) then
            dialog.DamagerButton.CheckButton:SetChecked(true);
        end
    end

    LFGListApplicationDialogSignUpButton_OnClick(dialog.SignUpButton);

    if (module.db.announce) then
        Lantern:Print(L["AUTOQUEUE_MSG_SIGNUP_SKIPPED"]);
    end
end

--------------------------------------------------------------------------------
-- Lifecycle
--------------------------------------------------------------------------------

function module:OnInit()
    ensureDB(self);
end

function module:OnEnable()
    ensureDB(self);
    self.addon:ModuleRegisterEvent(self, "LFG_ROLE_CHECK_SHOW", self.OnRoleCheckShow);

    if (not self._inviteHooked and LFGListInviteDialog_Show) then
        hooksecurefunc("LFGListInviteDialog_Show", OnInviteDialogShow);
        self._inviteHooked = true;
    end

    if (not self._entryClickHooked and LFGListSearchEntry_OnClick) then
        hooksecurefunc("LFGListSearchEntry_OnClick", OnSearchEntryClick);
        self._entryClickHooked = true;
    end

    if (not self._signUpHooked and LFGListApplicationDialog_Show) then
        hooksecurefunc("LFGListApplicationDialog_Show", OnApplicationDialogShow);
        self._signUpHooked = true;
    end
end

function module:OnRoleCheckShow()
    if (not self.enabled or not self.db.active or shouldPause()) then return; end
    CompleteLFGRoleCheck(true);
    if (self.db.announce) then
        Lantern:Print(L["AUTOQUEUE_MSG_ACCEPTED"]);
    end
end

Lantern:RegisterModule(module);
