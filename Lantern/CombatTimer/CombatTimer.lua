local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local LanternUX = _G.LanternUX;
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true);

local DEFAULT_FONT_PATH = (LanternUX and LanternUX.Theme and LanternUX.Theme.fontPathLight)
    or "Fonts\\FRIZQT__.TTF";

local module = Lantern:NewModule("CombatTimer", {
    title = "Combat Timer",
    desc = "Display a timer showing how long you've been in combat.",
    skipOptions = true,
    defaultEnabled = false,
});

local DEFAULTS = {
    font = "Roboto Light",
    fontSize = 18,
    fontOutline = "OUTLINE",
    fontColor = { r = 1, g = 1, b = 1 },
    stickyDuration = 5,
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

local frame, timerText;
local combatStart, inCombat, stickyTimer;
local previewMode = false;
local previewTimer = nil;

local function ensureDB(self)
    if (not self.addon.db) then return; end
    if (not self.addon.db.combatTimer) then
        self.addon.db.combatTimer = {};
    end
    self.db = self.addon.db.combatTimer;
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

local function formatTime(seconds)
    local m = math.floor(seconds / 60);
    local s = math.floor(seconds % 60);
    return string.format("%d:%02d", m, s);
end

local function createFrame(self)
    if (frame) then return; end

    frame = CreateFrame("Frame", "Lantern_CombatTimer", UIParent, "BackdropTemplate");
    frame:SetSize(100, 30);
    frame:SetPoint("TOP", UIParent, "TOP", 0, -200);
    frame:Hide();

    timerText = frame:CreateFontString(nil, "ARTWORK");
    timerText:SetFont(GetFontPath(DEFAULTS.font), DEFAULTS.fontSize, DEFAULTS.fontOutline);
    timerText:SetPoint("CENTER");
    local c = (self.db and self.db.fontColor) or DEFAULTS.fontColor;
    timerText:SetTextColor(c.r, c.g, c.b, 1);
    timerText:SetText("0:00");

    if (LanternUX and LanternUX.MakeDraggable) then
        LanternUX.MakeDraggable(frame, {
            getPos    = function() return self.db and self.db.pos; end,
            setPos    = function(pos) if (self.db) then self.db.pos = pos; end end,
            getLocked = function() return self.db and self.db.locked; end,
            setLocked = function(val) if (self.db) then self.db.locked = val; end end,
            defaultPoint = { "TOP", UIParent, "TOP", 0, -200 },
            text = timerText,
            placeholder = "0:00",
        });
    end

    frame:SetScript("OnUpdate", function()
        if (previewMode) then return; end
        if (inCombat and combatStart) then
            local elapsed = GetTime() - combatStart;
            timerText:SetText(formatTime(elapsed));
        end
    end);
end

function module:RefreshFont()
    if (not timerText) then return; end
    local fontPath = GetFontPath((self.db and self.db.font) or DEFAULTS.font);
    local size = (self.db and self.db.fontSize) or DEFAULTS.fontSize;
    local outline = (self.db and self.db.fontOutline) or DEFAULTS.fontOutline;
    timerText:SetFont(fontPath, size, outline);
end

function module:RefreshColor()
    if (not timerText) then return; end
    local c = (self.db and self.db.fontColor) or DEFAULTS.fontColor;
    timerText:SetTextColor(c.r, c.g, c.b, 1);
end

function module:SetPreviewMode(enabled)
    previewMode = enabled;
    if (previewTimer) then previewTimer:Cancel(); previewTimer = nil; end

    if (enabled) then
        if (not frame) then createFrame(self); end
        self:RefreshFont();
        self:RefreshColor();
        timerText:SetText("3:42");
        frame:SetAlpha(1);
        frame:Show();

        -- Auto-disable when settings panel closes
        previewTimer = C_Timer.NewTicker(0.5, function()
            if (not previewMode) then return; end
            local panel = Lantern._uxPanel;
            if (panel and panel.frame and not panel.frame:IsShown()) then
                module:SetPreviewMode(false);
            end
        end);
    else
        if (frame and not inCombat) then
            local unlocked = self.db and not self.db.locked;
            if (not unlocked) then frame:Hide(); end
        end
    end
end

function module:IsPreviewActive()
    return previewMode;
end

function module:UpdateLock()
    if (not frame) then return; end
    frame:UpdateLock();
    -- When locking back, hide if not in combat
    if (self.db and self.db.locked and not inCombat) then
        frame:Hide();
    end
end

function module:ResetPosition()
    if (not frame) then return; end
    frame:ResetPosition();
end

function module:OnInit()
    ensureDB(self);
end

function module:OnEnable()
    ensureDB(self);
    createFrame(self);
    frame:RestorePosition();
    frame:UpdateLock();
    self:RefreshFont();

    self.addon:ModuleRegisterEvent(self, "PLAYER_REGEN_DISABLED", function()
        if (not self.enabled) then return; end
        inCombat = true;
        combatStart = GetTime();
        if (stickyTimer) then stickyTimer:Cancel(); stickyTimer = nil; end
        frame:SetAlpha(1);
        frame:Show();
    end);

    self.addon:ModuleRegisterEvent(self, "PLAYER_REGEN_ENABLED", function()
        if (not self.enabled) then return; end
        inCombat = false;
        local stickyDur = self.db and self.db.stickyDuration or DEFAULTS.stickyDuration;
        if (stickyDur > 0) then
            stickyTimer = C_Timer.NewTimer(stickyDur, function()
                local unlocked = self.db and not self.db.locked;
                if (not inCombat and frame and not unlocked) then
                    frame:Hide();
                end
                stickyTimer = nil;
            end);
        elseif (not (self.db and not self.db.locked)) then
            frame:Hide();
        end
    end);
end

function module:OnDisable()
    if (frame) then frame:Hide(); end
    inCombat = false;
    combatStart = nil;
    previewMode = false;
    if (stickyTimer) then stickyTimer:Cancel(); stickyTimer = nil; end
    if (previewTimer) then previewTimer:Cancel(); previewTimer = nil; end
end

Lantern:RegisterModule(module);
