local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end
local L = Lantern.L;

local module = Lantern:NewModule("ReleaseProtection", {
    title = L["RELEASEPROTECT_TITLE"],
    desc = L["RELEASEPROTECT_DESC"],
    defaultEnabled = false,
});

local DEFAULTS = {
    mode = "always", -- always, instances, custom
    openWorld = true,
    dungeons = true,
    raids = true,
    scenarios = true,
    delves = true,
    mythicPlus = true,
    arenas = true,
    battlegrounds = true,
    holdDuration = 1.0,
    skipSolo = false,
};

local function db()
    Lantern.db.releaseProtection = Lantern.db.releaseProtection or {};
    for k, v in pairs(DEFAULTS) do
        if (Lantern.db.releaseProtection[k] == nil) then
            Lantern.db.releaseProtection[k] = v;
        end
    end
    return Lantern.db.releaseProtection;
end

local function shouldProtect()
    local d = db();

    if (d.skipSolo and not IsInGroup()) then return false; end

    local mode = d.mode;

    if (mode == "always") then return true; end

    local inInstance, instanceType = IsInInstance();
    if (not inInstance) then return d.openWorld; end

    if (mode == "instances") then return true; end

    -- Custom mode: check per-type toggles
    if (instanceType == "party") then
        local _, _, difficultyID = GetInstanceInfo();
        if (difficultyID == 8) then
            return d.mythicPlus;
        end
        return d.dungeons;
    elseif (instanceType == "raid") then
        return d.raids;
    elseif (instanceType == "scenario") then
        local _, _, difficultyID = GetInstanceInfo();
        if (difficultyID == 208) then
            return d.delves;
        end
        return d.scenarios;
    elseif (instanceType == "arena") then
        return d.arenas;
    elseif (instanceType == "pvp") then
        return d.battlegrounds;
    end

    return false;
end

-------------------------------------------------------------------------------
-- Overlay
-------------------------------------------------------------------------------

local overlay, overlayLabel;
local holdStart;
local unlocked;

local function createOverlay(parent)
    if (overlay) then return; end

    overlay = CreateFrame("Button", "Lantern_ReleaseOverlay", parent);
    overlay:SetAllPoints();
    overlay:SetFrameStrata("DIALOG");
    overlay:RegisterForClicks("AnyUp", "AnyDown");
    overlay:SetScript("OnClick", function() end);
    overlay:Hide();

    local bg = overlay:CreateTexture(nil, "BACKGROUND");
    bg:SetAllPoints();
    bg:SetColorTexture(0.1, 0.1, 0.1, 1);

    overlayLabel = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    overlayLabel:SetPoint("CENTER");
    overlayLabel:SetTextColor(1, 0.65, 0);

    -- OnUpdate runs only while overlay is visible (WoW skips hidden frames)
    overlay:SetScript("OnUpdate", function()
        if (unlocked) then
            overlay:Hide();
            return;
        end

        local dur = db().holdDuration or 1.0;
        local modName = Lantern:GetModifierName();

        if (Lantern:IsModifierDown()) then
            if (not holdStart) then
                holdStart = GetTime();
            end

            local elapsed = GetTime() - holdStart;
            if (elapsed >= dur) then
                unlocked = true;
                overlay:Hide();
            else
                overlayLabel:SetText(string.format(L["RELEASEPROTECT_HOLD_PROGRESS"], modName, dur - elapsed));
            end
        else
            holdStart = nil;
            overlayLabel:SetText(string.format(L["RELEASEPROTECT_HOLD_PROMPT"], modName, dur));
        end
    end);
end

local function showOverlay()
    local visible, popup = StaticPopup_Visible("DEATH");
    if (not visible or not popup) then return; end

    local releaseBtn = popup.GetButton and popup:GetButton(1);
    if (not releaseBtn) then return; end

    createOverlay(releaseBtn);

    holdStart = nil;
    unlocked = false;

    local dur = db().holdDuration or 1.0;
    overlayLabel:SetText(string.format(L["RELEASEPROTECT_HOLD_PROMPT"], Lantern:GetModifierName(), dur));
    overlay:Show();
end

local function hideOverlay()
    holdStart = nil;
    unlocked = false;
    if (overlay) then overlay:Hide(); end
end

-------------------------------------------------------------------------------
-- Lifecycle
-------------------------------------------------------------------------------

function module:OnEnable()
    self.addon:ModuleRegisterEvent(self, "PLAYER_DEAD", function()
        if (not self.enabled) then return; end
        if (not shouldProtect()) then return; end
        C_Timer.After(0.1, showOverlay);
    end);

    self.addon:ModuleRegisterEvent(self, "PLAYER_ALIVE", hideOverlay);
    self.addon:ModuleRegisterEvent(self, "PLAYER_UNGHOST", hideOverlay);
end

function module:OnDisable()
    hideOverlay();
end

Lantern:RegisterModule(module);
