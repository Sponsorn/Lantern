local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local LanternUX = _G.LanternUX;
local fontHeading = (LanternUX and LanternUX.Theme and LanternUX.Theme.fontHeading)
    or "GameFontNormalLarge";

local module = Lantern:NewModule("DeathRelease", {
    title = "Death Release Protection",
    desc = "Require holding your pause modifier for 1 second before releasing spirit to prevent accidental clicks.",
    defaultEnabled = false,
});

local DEFAULTS = {
    mode = "always", -- always, instances, custom
    openWorld = true,
    dungeons = true,
    raids = true,
    scenarios = true,
    mythicPlus = true,
    arenas = true,
    battlegrounds = true,
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
    local mode = d.mode;

    if (mode == "always") then return true; end

    local inInstance, instanceType = IsInInstance();
    if (not inInstance) then return d.openWorld; end

    if (mode == "instances") then return true; end

    -- Custom mode: check per-type toggles
    if (instanceType == "party") then
        -- Check for M+ specifically
        local _, _, difficultyID = GetInstanceInfo();
        if (difficultyID == 8) then
            return d.mythicPlus;
        end
        return d.dungeons;
    elseif (instanceType == "raid") then
        return d.raids;
    elseif (instanceType == "scenario") then
        return d.scenarios;
    elseif (instanceType == "arena") then
        return d.arenas;
    elseif (instanceType == "pvp") then
        return d.battlegrounds;
    end

    return false;
end

local HOLD_DURATION = 1.0;
local blocker, holdStart;

local function createBlocker()
    if (blocker) then return; end

    blocker = CreateFrame("Frame", "Lantern_DeathReleaseBlocker", UIParent);
    blocker:SetFrameStrata("DIALOG");
    blocker:SetFrameLevel(1000);
    blocker:EnableMouse(true);
    blocker:Hide();

    local text = blocker:CreateFontString(nil, "ARTWORK", fontHeading);
    text:SetPoint("CENTER");
    text:SetTextColor(1, 0.8, 0, 1);
    blocker._text = text;

    blocker:SetScript("OnUpdate", function()
        local modName = Lantern:GetModifierName();
        if (not Lantern:IsModifierDown()) then
            holdStart = nil;
            blocker._text:SetText("Hold " .. modName .. " to release");
            return;
        end

        if (not holdStart) then
            holdStart = GetTime();
        end

        local held = GetTime() - holdStart;
        if (held >= HOLD_DURATION) then
            blocker:Hide();
            holdStart = nil;
        else
            local remaining = HOLD_DURATION - held;
            blocker._text:SetText(string.format("Hold " .. modName .. "... %.1fs", remaining));
        end
    end);
end

local function positionBlocker()
    if (not blocker) then return; end

    local popup = StaticPopup_FindVisible("DEATH") or StaticPopup_FindVisible("RELEASE_SPIRIT");
    if (not popup) then
        blocker:Hide();
        return;
    end

    local btn = popup.button1;
    if (btn and btn:IsShown()) then
        blocker:ClearAllPoints();
        blocker:SetAllPoints(btn);
        blocker:Show();
        holdStart = nil;
        blocker._text:SetText("Hold " .. Lantern:GetModifierName() .. " to release");
    end
end

function module:OnEnable()
    createBlocker();

    self.addon:ModuleRegisterEvent(self, "PLAYER_DEAD", function()
        if (not self.enabled) then return; end
        if (not shouldProtect()) then return; end
        C_Timer.After(0.2, positionBlocker);
    end);

    self.addon:ModuleRegisterEvent(self, "PLAYER_ALIVE", function()
        if (blocker) then blocker:Hide(); end
        holdStart = nil;
    end);

    self.addon:ModuleRegisterEvent(self, "PLAYER_UNGHOST", function()
        if (blocker) then blocker:Hide(); end
        holdStart = nil;
    end);
end

function module:OnDisable()
    if (blocker) then blocker:Hide(); end
    holdStart = nil;
end

Lantern:RegisterModule(module);
