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
    showEnter = true,
    showLeave = true,
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

local banner, label;
local flashAt, flashLength;
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
    if (banner) then return; end

    banner = CreateFrame("Frame", "Lantern_CombatAlert", UIParent, "BackdropTemplate");
    banner:SetSize(400, 50);
    banner:SetPoint("CENTER", UIParent, "CENTER", 0, 200);
    banner:SetFrameStrata("HIGH");
    banner:Hide();

    label = banner:CreateFontString(nil, "ARTWORK");
    label:SetFont(GetFontPath(DEFAULTS.font), DEFAULTS.fontSize, DEFAULTS.fontOutline);
    label:SetPoint("CENTER");
    label:SetShadowOffset(2, -2);
    label:SetShadowColor(0, 0, 0, 0.8);

    if (LanternUX and LanternUX.MakeDraggable) then
        LanternUX.MakeDraggable(banner, {
            getPos    = function() return self.db and self.db.pos; end,
            setPos    = function(pos) if (self.db) then self.db.pos = pos; end end,
            getLocked = function() return self.db and self.db.locked; end,
            setLocked = function(val) if (self.db) then self.db.locked = val; end end,
            defaultPoint = { "CENTER", UIParent, "CENTER", 0, 200 },
            text = label,
            placeholder = DEFAULTS.enterText,
        });
    end

    banner:SetScript("OnUpdate", function()
        if (not flashAt) then return; end

        local elapsed = GetTime() - flashAt;
        local dur = flashLength or DEFAULTS.fadeDuration;

        if (elapsed >= dur) then
            banner:Hide();
            flashAt = nil;
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
            banner:SetAlpha(1);
        else
            local fadeProgress = (elapsed - holdTime) / (dur - holdTime);
            banner:SetAlpha(1 - fadeProgress);
        end
    end);
end

local function flash(text, color, db)
    if (not banner) then createFrame(module); end

    local fontName = (db and db.font) or DEFAULTS.font;
    local size = (db and db.fontSize) or DEFAULTS.fontSize;
    local outline = (db and db.fontOutline) or DEFAULTS.fontOutline;
    label:SetFont(GetFontPath(fontName), size, outline);
    label:SetText(text);
    label:SetTextColor(color.r, color.g, color.b, 1);

    flashLength = (db and db.fadeDuration) or DEFAULTS.fadeDuration;
    flashAt = GetTime();
    banner:SetAlpha(1);
    banner:Show();

    -- Play sound if enabled (skip during preview)
    if (not previewMode and db and db.soundEnabled) then
        local media = LibStub and LibStub("LibSharedMedia-3.0", true);
        if (media) then
            local sound = media:Fetch("sound", db.soundName or "RaidWarning");
            if (sound) then
                pcall(PlaySoundFile, sound, "Master");
            end
        end
    end
end

function module:RefreshFont()
    if (not label) then return; end
    local fontPath = GetFontPath((self.db and self.db.font) or DEFAULTS.font);
    local size = (self.db and self.db.fontSize) or DEFAULTS.fontSize;
    local outline = (self.db and self.db.fontOutline) or DEFAULTS.fontOutline;
    label:SetFont(fontPath, size, outline);
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
    flash(text, color, self.db);
end

function module:SetPreviewMode(enabled)
    previewMode = enabled;
    if (previewTimer) then previewTimer:Cancel(); previewTimer = nil; end

    if (enabled) then
        if (not banner) then createFrame(self); end
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
        flashAt = nil;
        if (banner) then banner:Hide(); end
    end
end

function module:IsPreviewActive()
    return previewMode;
end

function module:UpdateLock()
    if (not banner) then return; end
    banner:UpdateLock();
    -- When locking back, hide if no flash is playing
    if (self.db and self.db.locked and not flashAt) then
        banner:Hide();
    end
end

function module:ResetPosition()
    if (not banner) then return; end
    banner:ResetPosition();
end

function module:OnInit()
    ensureDB(self);
end

function module:OnEnable()
    ensureDB(self);
    createFrame(self);
    banner:RestorePosition();
    banner:UpdateLock();

    self.addon:ModuleRegisterEvent(self, "PLAYER_REGEN_DISABLED", function()
        if (not self.enabled) then return; end
        if (self.db and self.db.showEnter == false) then return; end
        local text = self.db.enterText or DEFAULTS.enterText;
        local color = self.db.enterColor or DEFAULTS.enterColor;
        flash(text, color, self.db);
    end);

    self.addon:ModuleRegisterEvent(self, "PLAYER_REGEN_ENABLED", function()
        if (not self.enabled) then return; end
        if (self.db and self.db.showLeave == false) then return; end
        local text = self.db.leaveText or DEFAULTS.leaveText;
        local color = self.db.leaveColor or DEFAULTS.leaveColor;
        flash(text, color, self.db);
    end);
end

function module:OnDisable()
    if (banner) then banner:Hide(); end
    flashAt = nil;
    previewMode = false;
    if (previewTimer) then previewTimer:Cancel(); previewTimer = nil; end
end

Lantern:RegisterModule(module);
