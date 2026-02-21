local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local LanternUX = _G.LanternUX;
local FONT_PATH = (LanternUX and LanternUX.Theme and LanternUX.Theme.fontPathLight)
    or FONT_PATH;

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
    displayMode = "range",  -- "range" = numbers, "status" = In Range / Out of Range
    hideInRange = false,    -- hide display when target is in range (status mode only)
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

local function getSpecMaxRange()
    if (not LibRangeCheck) then return 40; end
    -- Use harmNoItemsRC (spell-only checkers, sorted descending by range)
    -- harmRC includes item-based checks that can reach 80-100+ yards
    local checkers = LibRangeCheck.harmNoItemsRC;
    if (checkers and #checkers > 0) then
        return checkers[1].range;
    end
    return 40;
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

    frame = CreateFrame("Frame", "Lantern_RangeCheck", UIParent, "BackdropTemplate");
    frame:SetSize(80, 24);
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, -100);
    frame:Hide();

    rangeText = frame:CreateFontString(nil, "ARTWORK");
    rangeText:SetFont(FONT_PATH, DEFAULTS.fontSize, "OUTLINE");
    rangeText:SetPoint("CENTER");
    rangeText:SetTextColor(1, 1, 1, 1);

    if (LanternUX and LanternUX.MakeDraggable) then
        LanternUX.MakeDraggable(frame, {
            getPos    = function() return self.db and self.db.pos; end,
            setPos    = function(pos) if (self.db) then self.db.pos = pos; end end,
            getLocked = function() return self.db and self.db.locked; end,
            defaultPoint = { "CENTER", UIParent, "CENTER", 0, -100 },
            text = rangeText,
            placeholder = "0-40 yd",
        });
    end

    frame:SetScript("OnUpdate", function(_, delta)
        timeSinceUpdate = timeSinceUpdate + delta;
        if (timeSinceUpdate < UPDATE_INTERVAL) then return; end
        timeSinceUpdate = 0;

        if (not LibRangeCheck) then
            frame:Hide();
            return;
        end

        local db = self.db;
        local unlocked = db and not db.locked;

        if (not UnitExists("target") or UnitIsDeadOrGhost("target")) then
            if (not unlocked) then frame:Hide(); end
            return;
        end

        if (db and db.combatOnly and not InCombatLockdown() and not unlocked) then
            frame:Hide();
            return;
        end

        local minRange, maxRange = LibRangeCheck:GetRange("target");
        if (not minRange and not maxRange) then
            if (not unlocked) then frame:Hide(); end
            return;
        end

        local mode = db and db.displayMode or "range";

        if (mode == "status") then
            local threshold = getSpecMaxRange();
            local effectiveRange = maxRange or minRange or 100;
            if (effectiveRange <= threshold) then
                if (db and db.hideInRange and not unlocked) then
                    frame:Hide();
                    return;
                end
                rangeText:SetText("In Range");
                rangeText:SetTextColor(COLOR_MELEE.r, COLOR_MELEE.g, COLOR_MELEE.b, 1);
            else
                rangeText:SetText("Out of Range");
                rangeText:SetTextColor(COLOR_FAR.r, COLOR_FAR.g, COLOR_FAR.b, 1);
            end
        else
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
        end

        frame:Show();
    end);
end

function module:RefreshFont()
    if (not rangeText) then return; end
    local size = (self.db and self.db.fontSize) or DEFAULTS.fontSize;
    rangeText:SetFont(FONT_PATH, size, "OUTLINE");
end

function module:UpdateLock()
    if (not frame) then return; end
    frame:UpdateLock();
    -- When locking back, hide if no target
    if (self.db and self.db.locked and not UnitExists("target")) then
        frame:Hide();
    end
end

function module:ResetPosition()
    if (not frame) then return; end
    frame:ResetPosition();
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
    frame:RestorePosition();
    frame:UpdateLock();
    self:RefreshFont();

    self.addon:ModuleRegisterEvent(self, "PLAYER_TARGET_CHANGED", function()
        if (not self.enabled or not frame) then return; end
        if (UnitExists("target")) then
            timeSinceUpdate = UPDATE_INTERVAL;
            frame:Show();
        else
            frame:Hide();
        end
    end);
end

function module:OnDisable()
    if (frame) then frame:Hide(); end
end

Lantern:RegisterModule(module);
