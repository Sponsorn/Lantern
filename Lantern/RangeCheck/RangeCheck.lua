local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local module = Lantern:NewModule("RangeCheck", {
    title = "Range Check",
    desc = "Display distance to your target with color-coded range brackets.",
    skipOptions = true,
    defaultEnabled = false,
});

local DEFAULTS = {
    combatOnly = false,
    fontSize = 16,
    locked = true,
    pos = nil,
};

local LibRangeCheck = LibStub and LibStub("LibRangeCheck-3.0", true);
local frame, rangeText;
local UPDATE_INTERVAL = 0.1;
local timeSinceUpdate = 0;

local COLOR_MELEE  = { r = 0.2, g = 1.0, b = 0.2 };
local COLOR_MID    = { r = 1.0, g = 0.8, b = 0.0 };
local COLOR_FAR    = { r = 1.0, g = 0.2, b = 0.2 };

local function ensureDB(self)
    if (not self.addon.db) then return; end
    if (not self.addon.db.rangeCheck) then
        self.addon.db.rangeCheck = {};
    end
    self.db = self.addon.db.rangeCheck;
    for k, v in pairs(DEFAULTS) do
        if (self.db[k] == nil) then
            self.db[k] = v;
        end
    end
end

local function getRangeColor(minRange, maxRange)
    local range = maxRange or minRange or 100;
    if (range <= 8) then
        return COLOR_MELEE;
    elseif (range <= 30) then
        return COLOR_MID;
    else
        return COLOR_FAR;
    end
end

local function createFrame(self)
    if (frame) then return; end

    frame = CreateFrame("Frame", "Lantern_RangeCheck", UIParent);
    frame:SetSize(80, 24);
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, -100);
    frame:SetMovable(true);
    frame:SetClampedToScreen(true);
    frame:Hide();

    frame:SetScript("OnMouseDown", function(_, button)
        if (button == "LeftButton" and frame:IsMovable()) then
            frame:StartMoving();
        end
    end);
    frame:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing();
        local db = Lantern.db and Lantern.db.rangeCheck;
        if (db) then
            local point, _, relPoint, x, y = frame:GetPoint();
            db.pos = { point = point, relPoint = relPoint, x = x, y = y };
        end
    end);

    rangeText = frame:CreateFontString(nil, "ARTWORK");
    rangeText:SetFont("Fonts\\FRIZQT__.TTF", DEFAULTS.fontSize, "OUTLINE");
    rangeText:SetPoint("CENTER");
    rangeText:SetTextColor(1, 1, 1, 1);

    frame:SetScript("OnUpdate", function(_, delta)
        timeSinceUpdate = timeSinceUpdate + delta;
        if (timeSinceUpdate < UPDATE_INTERVAL) then return; end
        timeSinceUpdate = 0;

        if (not LibRangeCheck) then
            frame:Hide();
            return;
        end

        if (not UnitExists("target") or UnitIsDeadOrGhost("target")) then
            frame:Hide();
            return;
        end

        local db = Lantern.db and Lantern.db.rangeCheck;
        if (db and db.combatOnly and not InCombatLockdown()) then
            frame:Hide();
            return;
        end

        local minRange, maxRange = LibRangeCheck:GetRange("target");
        if (not minRange and not maxRange) then
            frame:Hide();
            return;
        end

        local displayText;
        if (minRange and maxRange) then
            displayText = string.format("%d-%d yd", minRange, maxRange);
        elseif (minRange) then
            displayText = string.format("%d+ yd", minRange);
        elseif (maxRange) then
            displayText = string.format("<%d yd", maxRange);
        end

        local color = getRangeColor(minRange, maxRange);
        rangeText:SetText(displayText);
        rangeText:SetTextColor(color.r, color.g, color.b, 1);
        frame:Show();
    end);
end

function module:RefreshFont()
    if (not rangeText) then return; end
    local size = (self.db and self.db.fontSize) or DEFAULTS.fontSize;
    rangeText:SetFont("Fonts\\FRIZQT__.TTF", size, "OUTLINE");
end

function module:UpdateLock()
    if (not frame) then return; end
    local locked = self.db and self.db.locked;
    frame:SetMovable(not locked);
    frame:EnableMouse(not locked);
end

function module:ResetPosition()
    if (not frame) then return; end
    frame:ClearAllPoints();
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, -100);
    if (self.db) then self.db.pos = nil; end
end

function module:RestorePosition()
    if (not frame or not self.db or not self.db.pos) then return; end
    local p = self.db.pos;
    frame:ClearAllPoints();
    frame:SetPoint(p.point, UIParent, p.relPoint, p.x, p.y);
end

function module:OnInit()
    ensureDB(self);
    if (not LibRangeCheck) then
        Lantern:Print("RangeCheck: LibRangeCheck-3.0 not found. Module disabled.");
    end
end

function module:OnEnable()
    ensureDB(self);
    if (not LibRangeCheck) then return; end

    createFrame(self);
    self:RestorePosition();
    self:UpdateLock();
    self:RefreshFont();

    self.addon:ModuleRegisterEvent(self, "PLAYER_TARGET_CHANGED", function()
        if (not self.enabled or not frame) then return; end
        if (UnitExists("target")) then
            timeSinceUpdate = UPDATE_INTERVAL;
        else
            frame:Hide();
        end
    end);
end

function module:OnDisable()
    if (frame) then frame:Hide(); end
end

Lantern:RegisterModule(module);
