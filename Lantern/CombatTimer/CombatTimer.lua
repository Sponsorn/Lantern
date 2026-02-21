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

local clock, clockLabel;
local startedAt, active, lingerTimer;
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

local function formatClock(seconds)
    local m = math.floor(seconds / 60);
    local s = math.floor(seconds % 60);
    return string.format("%d:%02d", m, s);
end

local function createFrame(self)
    if (clock) then return; end

    clock = CreateFrame("Frame", "Lantern_CombatTimer", UIParent, "BackdropTemplate");
    clock:SetSize(100, 30);
    clock:SetPoint("TOP", UIParent, "TOP", 0, -200);
    clock:Hide();

    clockLabel = clock:CreateFontString(nil, "ARTWORK");
    clockLabel:SetFont(GetFontPath(DEFAULTS.font), DEFAULTS.fontSize, DEFAULTS.fontOutline);
    clockLabel:SetPoint("CENTER");
    local c = (self.db and self.db.fontColor) or DEFAULTS.fontColor;
    clockLabel:SetTextColor(c.r, c.g, c.b, 1);
    clockLabel:SetText("0:00");

    if (LanternUX and LanternUX.MakeDraggable) then
        LanternUX.MakeDraggable(clock, {
            getPos    = function() return self.db and self.db.pos; end,
            setPos    = function(pos) if (self.db) then self.db.pos = pos; end end,
            getLocked = function() return self.db and self.db.locked; end,
            setLocked = function(val) if (self.db) then self.db.locked = val; end end,
            defaultPoint = { "TOP", UIParent, "TOP", 0, -200 },
            text = clockLabel,
            placeholder = "0:00",
        });
    end

    clock:SetScript("OnUpdate", function()
        if (previewMode) then return; end
        if (active and startedAt) then
            local elapsed = GetTime() - startedAt;
            clockLabel:SetText(formatClock(elapsed));
        end
    end);
end

function module:RefreshFont()
    if (not clockLabel) then return; end
    local fontPath = GetFontPath((self.db and self.db.font) or DEFAULTS.font);
    local size = (self.db and self.db.fontSize) or DEFAULTS.fontSize;
    local outline = (self.db and self.db.fontOutline) or DEFAULTS.fontOutline;
    clockLabel:SetFont(fontPath, size, outline);
end

function module:RefreshColor()
    if (not clockLabel) then return; end
    local c = (self.db and self.db.fontColor) or DEFAULTS.fontColor;
    clockLabel:SetTextColor(c.r, c.g, c.b, 1);
end

function module:SetPreviewMode(enabled)
    previewMode = enabled;
    if (previewTimer) then previewTimer:Cancel(); previewTimer = nil; end

    if (enabled) then
        if (not clock) then createFrame(self); end
        self:RefreshFont();
        self:RefreshColor();
        clockLabel:SetText("3:42");
        clock:SetAlpha(1);
        clock:Show();

        -- Auto-disable when settings panel closes
        previewTimer = C_Timer.NewTicker(0.5, function()
            if (not previewMode) then return; end
            local panel = Lantern._uxPanel;
            if (panel and panel.frame and not panel.frame:IsShown()) then
                module:SetPreviewMode(false);
            end
        end);
    else
        if (clock and not active) then
            local unlocked = self.db and not self.db.locked;
            if (not unlocked) then clock:Hide(); end
        end
    end
end

function module:IsPreviewActive()
    return previewMode;
end

function module:UpdateLock()
    if (not clock) then return; end
    clock:UpdateLock();
    -- When locking back, hide if not in combat
    if (self.db and self.db.locked and not active) then
        clock:Hide();
    end
end

function module:ResetPosition()
    if (not clock) then return; end
    clock:ResetPosition();
end

function module:OnInit()
    ensureDB(self);
end

function module:OnEnable()
    ensureDB(self);
    createFrame(self);
    clock:RestorePosition();
    clock:UpdateLock();
    self:RefreshFont();

    self.addon:ModuleRegisterEvent(self, "PLAYER_REGEN_DISABLED", function()
        if (not self.enabled) then return; end
        active = true;
        startedAt = GetTime();
        if (lingerTimer) then lingerTimer:Cancel(); lingerTimer = nil; end
        clock:SetAlpha(1);
        clock:Show();
    end);

    self.addon:ModuleRegisterEvent(self, "PLAYER_REGEN_ENABLED", function()
        if (not self.enabled) then return; end
        active = false;
        local stickyDur = self.db and self.db.stickyDuration or DEFAULTS.stickyDuration;
        if (stickyDur > 0) then
            lingerTimer = C_Timer.NewTimer(stickyDur, function()
                local unlocked = self.db and not self.db.locked;
                if (not active and clock and not unlocked) then
                    clock:Hide();
                end
                lingerTimer = nil;
            end);
        elseif (not (self.db and not self.db.locked)) then
            clock:Hide();
        end
    end);
end

function module:OnDisable()
    if (clock) then clock:Hide(); end
    active = false;
    startedAt = nil;
    previewMode = false;
    if (lingerTimer) then lingerTimer:Cancel(); lingerTimer = nil; end
    if (previewTimer) then previewTimer:Cancel(); previewTimer = nil; end
end

Lantern:RegisterModule(module);
