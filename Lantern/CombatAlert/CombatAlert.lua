local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local LanternUX = _G.LanternUX;
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true);

local DEFAULT_FONT_PATH = (LanternUX and LanternUX.Theme and LanternUX.Theme.fontPathLight)
    or "Fonts\\FRIZQT__.TTF";

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
    font = "Roboto Light",
    fontSize = 28,
    fontOutline = "OUTLINE",
    fadeDuration = 2.0,
    soundEnabled = false,
    soundName = "RaidWarning",
    locked = true,
    pos = nil,
};

local function GetFontPath(fontName)
    if (LSM) then
        local path = LSM:Fetch("font", fontName);
        if (path) then return path; end
    end
    return DEFAULT_FONT_PATH;
end

local alertFrame, alertText;
local fadeStart, fadeDuration;
local previewMode = false;
local previewTimer = nil;
local previewPhase = "enter";

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

local function createFrame(self)
    if (alertFrame) then return; end

    alertFrame = CreateFrame("Frame", "Lantern_CombatAlert", UIParent, "BackdropTemplate");
    alertFrame:SetSize(400, 50);
    alertFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 200);
    alertFrame:SetFrameStrata("HIGH");
    alertFrame:Hide();

    alertText = alertFrame:CreateFontString(nil, "ARTWORK");
    alertText:SetFont(GetFontPath(DEFAULTS.font), DEFAULTS.fontSize, DEFAULTS.fontOutline);
    alertText:SetPoint("CENTER");
    alertText:SetShadowOffset(2, -2);
    alertText:SetShadowColor(0, 0, 0, 0.8);

    if (LanternUX and LanternUX.MakeDraggable) then
        LanternUX.MakeDraggable(alertFrame, {
            getPos    = function() return self.db and self.db.pos; end,
            setPos    = function(pos) if (self.db) then self.db.pos = pos; end end,
            getLocked = function() return self.db and self.db.locked; end,
            defaultPoint = { "CENTER", UIParent, "CENTER", 0, 200 },
            text = alertText,
            placeholder = DEFAULTS.enterText,
        });
    end

    alertFrame:SetScript("OnUpdate", function()
        if (not fadeStart) then return; end

        local elapsed = GetTime() - fadeStart;
        local dur = fadeDuration or DEFAULTS.fadeDuration;

        if (elapsed >= dur) then
            alertFrame:Hide();
            fadeStart = nil;
            if (previewMode) then
                previewPhase = (previewPhase == "enter") and "leave" or "enter";
                C_Timer.After(0.3, function()
                    if (previewMode) then module:ShowPreviewAlert(); end
                end);
            end
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
    if (not alertFrame) then createFrame(module); end

    local fontName = (db and db.font) or DEFAULTS.font;
    local size = (db and db.fontSize) or DEFAULTS.fontSize;
    local outline = (db and db.fontOutline) or DEFAULTS.fontOutline;
    alertText:SetFont(GetFontPath(fontName), size, outline);
    alertText:SetText(text);
    alertText:SetTextColor(color.r, color.g, color.b, 1);

    fadeDuration = (db and db.fadeDuration) or DEFAULTS.fadeDuration;
    fadeStart = GetTime();
    alertFrame:SetAlpha(1);
    alertFrame:Show();

    -- Play sound if enabled (skip during preview)
    if (not previewMode and db and db.soundEnabled) then
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
    local fontPath = GetFontPath((self.db and self.db.font) or DEFAULTS.font);
    local size = (self.db and self.db.fontSize) or DEFAULTS.fontSize;
    local outline = (self.db and self.db.fontOutline) or DEFAULTS.fontOutline;
    alertText:SetFont(fontPath, size, outline);
end

function module:ShowPreviewAlert()
    if (not previewMode) then return; end
    local text, color;
    if (previewPhase == "enter") then
        text = (self.db and self.db.enterText) or DEFAULTS.enterText;
        color = (self.db and self.db.enterColor) or DEFAULTS.enterColor;
    else
        text = (self.db and self.db.leaveText) or DEFAULTS.leaveText;
        color = (self.db and self.db.leaveColor) or DEFAULTS.leaveColor;
    end
    showAlert(text, color, self.db);
end

function module:SetPreviewMode(enabled)
    previewMode = enabled;
    if (previewTimer) then previewTimer:Cancel(); previewTimer = nil; end

    if (enabled) then
        if (not alertFrame) then createFrame(self); end
        previewPhase = "enter";
        self:ShowPreviewAlert();

        -- Auto-disable when settings panel closes
        previewTimer = C_Timer.NewTicker(0.5, function()
            if (not previewMode) then return; end
            local panel = Lantern._uxPanel;
            if (panel and panel.frame and not panel.frame:IsShown()) then
                module:SetPreviewMode(false);
            end
        end);
    else
        fadeStart = nil;
        if (alertFrame) then alertFrame:Hide(); end
    end
end

function module:IsPreviewActive()
    return previewMode;
end

function module:UpdateLock()
    if (not alertFrame) then return; end
    alertFrame:UpdateLock();
end

function module:ResetPosition()
    if (not alertFrame) then return; end
    alertFrame:ResetPosition();
end

function module:OnInit()
    ensureDB(self);
end

function module:OnEnable()
    ensureDB(self);
    createFrame(self);
    alertFrame:RestorePosition();
    alertFrame:UpdateLock();

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
    previewMode = false;
    if (previewTimer) then previewTimer:Cancel(); previewTimer = nil; end
end

Lantern:RegisterModule(module);
