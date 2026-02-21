local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local LanternUX = _G.LanternUX;
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true);
local DEFAULT_FONT_PATH = (LanternUX and LanternUX.Theme and LanternUX.Theme.fontPathLight)
    or "Fonts\\FRIZQT__.TTF";

local function GetFontPath(fontName)
    if (LSM) then
        local path = LSM:Fetch("font", fontName);
        if (path) then return path; end
    end
    return DEFAULT_FONT_PATH;
end

local module = Lantern:NewModule("RangeCheck", {
    title = "Range Check",
    desc = "Display distance to your target with color-coded range brackets.",
    defaultEnabled = false,
});

local DEFAULTS = {
    font = "Roboto Light",
    fontSize = 16,
    fontOutline = "OUTLINE",
    combatOnly = false,
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

-- Spec operating range: the range at which the spec is designed to fight.
-- Melee specs use 5 yards, Evoker/Devourer use 25, ranged specs use 40.
local SPEC_RANGE = {
    -- Warrior
    [71] = 5, [72] = 5, [73] = 5,
    -- Death Knight
    [250] = 5, [251] = 5, [252] = 5,
    -- Paladin (Holy = 40 by default)
    [66] = 5, [70] = 5,
    -- Monk (Mistweaver = 40 by default)
    [268] = 5, [269] = 5,
    -- Druid (Balance/Resto = 40 by default)
    [103] = 5, [104] = 5,
    -- Rogue
    [259] = 5, [260] = 5, [261] = 5,
    -- Demon Hunter (Havoc/Vengeance melee, Devourer handled below)
    [577] = 5, [581] = 5,
    -- Shaman (Ele/Resto = 40 by default)
    [263] = 5,
    -- Hunter (BM/MM = 40 by default)
    [255] = 5,
    -- Evoker (all specs 25 yards)
    [1467] = 25, [1468] = 25, [1473] = 25,
};

local function getSpecMaxRange()
    local specID = PlayerUtil and PlayerUtil.GetCurrentSpecID and PlayerUtil.GetCurrentSpecID();
    if (specID and SPEC_RANGE[specID]) then
        return SPEC_RANGE[specID];
    end
    -- Devourer DH: 3rd DH spec, not in table because spec ID may change.
    -- Detect at runtime: DH class + not Havoc/Vengeance = Devourer (25 yards).
    if (specID and select(2, UnitClass("player")) == "DEMONHUNTER" and specID ~= 577 and specID ~= 581) then
        return 25;
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
    rangeText:SetFont(GetFontPath(DEFAULTS.font), DEFAULTS.fontSize, DEFAULTS.fontOutline);
    rangeText:SetPoint("CENTER");
    rangeText:SetShadowOffset(1, -1);
    rangeText:SetShadowColor(0, 0, 0, 0.8);
    rangeText:SetTextColor(1, 1, 1, 1);

    if (LanternUX and LanternUX.MakeDraggable) then
        LanternUX.MakeDraggable(frame, {
            getPos    = function() return self.db and self.db.pos; end,
            setPos    = function(pos) if (self.db) then self.db.pos = pos; end end,
            getLocked = function() return self.db and self.db.locked; end,
            setLocked = function(val) if (self.db) then self.db.locked = val; end end,
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
                    rangeText:SetText("");
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
    local fontPath = GetFontPath((self.db and self.db.font) or DEFAULTS.font);
    local size = (self.db and self.db.fontSize) or DEFAULTS.fontSize;
    local outline = (self.db and self.db.fontOutline) or DEFAULTS.fontOutline;
    rangeText:SetFont(fontPath, size, outline);
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
