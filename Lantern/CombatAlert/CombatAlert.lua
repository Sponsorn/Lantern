local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local module = Lantern:NewModule("CombatAlert", {
    title = "Combat Alert",
    desc = "Show a fade-in/out text alert when entering or leaving combat.",
    skipOptions = true,
    defaultEnabled = false,
});

local DEFAULTS = {
    enterText = "IN COMBAT",
    leaveText = "OUT OF COMBAT",
    enterColor = { r = 1, g = 0.2, b = 0.2 },
    leaveColor = { r = 0.2, g = 1, b = 0.2 },
    fontSize = 28,
    fadeDuration = 2.0,
    soundEnabled = false,
    soundName = "RaidWarning",
};

local alertFrame, alertText;
local fadeStart, fadeDuration;

local function ensureDB(self)
    if (not self.addon.db) then return; end
    if (not self.addon.db.combatAlert) then
        self.addon.db.combatAlert = {};
    end
    self.db = self.addon.db.combatAlert;
    for k, v in pairs(DEFAULTS) do
        if (self.db[k] == nil) then
            if (type(v) == "table") then
                self.db[k] = { r = v.r, g = v.g, b = v.b };
            else
                self.db[k] = v;
            end
        end
    end
end

local function createFrame()
    if (alertFrame) then return; end

    alertFrame = CreateFrame("Frame", "Lantern_CombatAlert", UIParent);
    alertFrame:SetSize(400, 50);
    alertFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 200);
    alertFrame:SetFrameStrata("HIGH");
    alertFrame:Hide();

    alertText = alertFrame:CreateFontString(nil, "ARTWORK");
    alertText:SetFont("Fonts\\FRIZQT__.TTF", DEFAULTS.fontSize, "OUTLINE");
    alertText:SetPoint("CENTER");
    alertText:SetShadowOffset(2, -2);
    alertText:SetShadowColor(0, 0, 0, 0.8);

    alertFrame:SetScript("OnUpdate", function()
        if (not fadeStart) then return; end

        local elapsed = GetTime() - fadeStart;
        local dur = fadeDuration or DEFAULTS.fadeDuration;

        if (elapsed >= dur) then
            alertFrame:Hide();
            fadeStart = nil;
            return;
        end

        -- Hold for first 40%, then fade out
        local holdPortion = 0.4;
        local holdTime = dur * holdPortion;

        if (elapsed <= holdTime) then
            alertFrame:SetAlpha(1);
        else
            local fadeProgress = (elapsed - holdTime) / (dur - holdTime);
            alertFrame:SetAlpha(1 - fadeProgress);
        end
    end);
end

local function showAlert(text, color, db)
    if (not alertFrame) then createFrame(); end

    local size = (db and db.fontSize) or DEFAULTS.fontSize;
    alertText:SetFont("Fonts\\FRIZQT__.TTF", size, "OUTLINE");
    alertText:SetText(text);
    alertText:SetTextColor(color.r, color.g, color.b, 1);

    fadeDuration = (db and db.fadeDuration) or DEFAULTS.fadeDuration;
    fadeStart = GetTime();
    alertFrame:SetAlpha(1);
    alertFrame:Show();

    -- Play sound if enabled
    if (db and db.soundEnabled) then
        local LSM = LibStub and LibStub("LibSharedMedia-3.0", true);
        if (LSM) then
            local sound = LSM:Fetch("sound", db.soundName or "RaidWarning");
            if (sound) then
                pcall(PlaySoundFile, sound, "Master");
            end
        end
    end
end

function module:RefreshFont()
    if (not alertText) then return; end
    local size = (self.db and self.db.fontSize) or DEFAULTS.fontSize;
    alertText:SetFont("Fonts\\FRIZQT__.TTF", size, "OUTLINE");
end

function module:OnInit()
    ensureDB(self);
end

function module:OnEnable()
    ensureDB(self);
    createFrame();

    self.addon:ModuleRegisterEvent(self, "PLAYER_REGEN_DISABLED", function()
        if (not self.enabled) then return; end
        local text = self.db.enterText or DEFAULTS.enterText;
        local color = self.db.enterColor or DEFAULTS.enterColor;
        showAlert(text, color, self.db);
    end);

    self.addon:ModuleRegisterEvent(self, "PLAYER_REGEN_ENABLED", function()
        if (not self.enabled) then return; end
        local text = self.db.leaveText or DEFAULTS.leaveText;
        local color = self.db.leaveColor or DEFAULTS.leaveColor;
        showAlert(text, color, self.db);
    end);
end

function module:OnDisable()
    if (alertFrame) then alertFrame:Hide(); end
    fadeStart = nil;
end

Lantern:RegisterModule(module);
