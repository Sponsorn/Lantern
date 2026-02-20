local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local module = Lantern:NewModule("DeathRelease", {
    title = "Death Release Protection",
    desc = "Require holding Alt for 1 second before releasing spirit to prevent accidental clicks.",
    skipOptions = true,
});

local HOLD_DURATION = 1.0;
local blocker, holdStart;

local function createBlocker()
    if (blocker) then return; end

    blocker = CreateFrame("Frame", "Lantern_DeathReleaseBlocker", UIParent);
    blocker:SetFrameStrata("DIALOG");
    blocker:SetFrameLevel(1000);
    blocker:EnableMouse(true);
    blocker:Hide();

    local text = blocker:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
    text:SetPoint("CENTER");
    text:SetTextColor(1, 0.8, 0, 1);
    blocker._text = text;

    blocker:SetScript("OnUpdate", function()
        if (not IsAltKeyDown()) then
            holdStart = nil;
            blocker._text:SetText("Hold Alt to release");
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
            blocker._text:SetText(string.format("Hold Alt... %.1fs", remaining));
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
        blocker._text:SetText("Hold Alt to release");
    end
end

function module:OnEnable()
    createBlocker();

    self.addon:ModuleRegisterEvent(self, "PLAYER_DEAD", function()
        if (not self.enabled) then return; end
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
