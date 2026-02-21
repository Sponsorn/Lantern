local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local module = Lantern:NewModule("DeathRelease", {
    title = "Release Protection",
    desc = "Require holding your pause modifier before releasing spirit to prevent accidental clicks.",
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
    Lantern.db.deathRelease = Lantern.db.deathRelease or {};
    for k, v in pairs(DEFAULTS) do
        if (Lantern.db.deathRelease[k] == nil) then
            Lantern.db.deathRelease[k] = v;
        end
    end
    return Lantern.db.deathRelease;
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

local blocker;
local timerLabel;
local pressStart = 0;
local isReady = false;

local function BuildBlocker(releaseBtn)
    if (blocker) then return blocker; end

    blocker = CreateFrame("Button", "Lantern_ReleaseBlocker", releaseBtn);
    blocker:SetAllPoints();
    blocker:SetFrameStrata("DIALOG");
    blocker:RegisterForClicks("AnyUp", "AnyDown");

    local bg = blocker:CreateTexture(nil, "BACKGROUND");
    bg:SetAllPoints();
    bg:SetColorTexture(0.1, 0.1, 0.1, 1);

    timerLabel = blocker:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
    timerLabel:SetPoint("CENTER");
    timerLabel:SetTextColor(1, 0.65, 0);
    local fontFile, fontSize, fontFlags = timerLabel:GetFont();
    timerLabel:SetFont(fontFile, fontSize * 0.7, fontFlags);

    blocker:SetScript("OnClick", function() end);

    return blocker;
end

local function TickTimer()
    if (isReady) then
        blocker:Hide();
        return;
    end

    local dur = db().holdDuration or 1.0;

    if (Lantern:IsModifierDown()) then
        if (pressStart == 0) then
            pressStart = GetTime();
        end

        local elapsed = GetTime() - pressStart;
        local left = dur - elapsed;

        if (left <= 0) then
            isReady = true;
            blocker:Hide();
        else
            timerLabel:SetText(string.format("Hold %s... %.1fs", Lantern:GetModifierName(), left));
        end
    else
        pressStart = 0;
        timerLabel:SetText(string.format("Hold %s (%.1fs)", Lantern:GetModifierName(), dur));
    end
end

local function ClearState()
    pressStart = 0;
    isReady = false;
    if (blocker) then
        blocker:SetScript("OnUpdate", nil);
        blocker:Hide();
    end
end

local function ActivateProtection()
    local visible, popup = StaticPopup_Visible("DEATH");
    if (not visible or not popup) then return; end

    local btn = popup.GetButton and popup:GetButton(1);
    if (not btn) then return; end

    BuildBlocker(btn);
    ClearState();

    local dur = db().holdDuration or 1.0;
    timerLabel:SetText(string.format("Hold %s (%.1fs)", Lantern:GetModifierName(), dur));
    blocker:Show();
    blocker:SetScript("OnUpdate", TickTimer);
end

function module:OnEnable()
    self.addon:ModuleRegisterEvent(self, "PLAYER_DEAD", function()
        if (not self.enabled) then return; end
        if (not shouldProtect()) then return; end
        C_Timer.After(0.1, ActivateProtection);
    end);

    self.addon:ModuleRegisterEvent(self, "PLAYER_ALIVE", ClearState);
    self.addon:ModuleRegisterEvent(self, "PLAYER_UNGHOST", ClearState);
end

function module:OnDisable()
    ClearState();
end

Lantern:RegisterModule(module);
