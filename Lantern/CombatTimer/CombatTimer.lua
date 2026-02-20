local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local LanternUX = _G.LanternUX;

local module = Lantern:NewModule("CombatTimer", {
    title = "Combat Timer",
    desc = "Display a timer showing how long you've been in combat.",
    skipOptions = true,
    defaultEnabled = false,
});

local DEFAULTS = {
    fontSize = 18,
    stickyDuration = 5,
    locked = true,
    pos = nil,
};

local frame, timerText;
local combatStart, inCombat, stickyTimer;

local function ensureDB(self)
    if (not self.addon.db) then return; end
    if (not self.addon.db.combatTimer) then
        self.addon.db.combatTimer = {};
    end
    self.db = self.addon.db.combatTimer;
    for k, v in pairs(DEFAULTS) do
        if (self.db[k] == nil) then
            self.db[k] = v;
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
    timerText:SetFont("Fonts\\FRIZQT__.TTF", DEFAULTS.fontSize, "OUTLINE");
    timerText:SetPoint("CENTER");
    timerText:SetTextColor(1, 1, 1, 1);
    timerText:SetText("0:00");

    if (LanternUX and LanternUX.MakeDraggable) then
        LanternUX.MakeDraggable(frame, {
            getPos    = function() return self.db and self.db.pos; end,
            setPos    = function(pos) if (self.db) then self.db.pos = pos; end end,
            getLocked = function() return self.db and self.db.locked; end,
            defaultPoint = { "TOP", UIParent, "TOP", 0, -200 },
            text = timerText,
            placeholder = "0:00",
        });
    end

    frame:SetScript("OnUpdate", function()
        if (inCombat and combatStart) then
            local elapsed = GetTime() - combatStart;
            timerText:SetText(formatTime(elapsed));
        end
    end);
end

function module:RefreshFont()
    if (not timerText) then return; end
    local size = (self.db and self.db.fontSize) or DEFAULTS.fontSize;
    timerText:SetFont("Fonts\\FRIZQT__.TTF", size, "OUTLINE");
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
        local unlocked = self.db and not self.db.locked;
        if (stickyDur > 0) then
            stickyTimer = C_Timer.NewTimer(stickyDur, function()
                if (not inCombat and frame and not unlocked) then
                    frame:Hide();
                end
                stickyTimer = nil;
            end);
        elseif (not unlocked) then
            frame:Hide();
        end
    end);
end

function module:OnDisable()
    if (frame) then frame:Hide(); end
    inCombat = false;
    combatStart = nil;
    if (stickyTimer) then stickyTimer:Cancel(); stickyTimer = nil; end
end

Lantern:RegisterModule(module);
