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
    desc = "Display in-range or out-of-range status for your current target.",
    defaultEnabled = false,
});

local DEFAULTS = {
    font = "Roboto Light",
    fontSize = 16,
    fontOutline = "OUTLINE",
    combatOnly = false,
    locked = true,
    pos = nil,
    hideInRange = false,
    inRangeText = "In Range",
    outOfRangeText = "Out of Range",
    inRangeColor = { r = 0.2, g = 1.0, b = 0.2 },
    outOfRangeColor = { r = 1.0, g = 0.2, b = 0.2 },
    animationStyle = "none",
};

local LibRangeCheck = LibStub and LibStub("LibRangeCheck-3.0", true);
local frame, rangeText;
local UPDATE_INTERVAL = 0.1;
local timeSinceUpdate = 0;
local lastStatusState = nil;

-------------------------------------------------------------------------------
-- Melee specs: direct C_Spell.IsSpellInRange (same approach as MeleeRangeIndicator).
-- Ranged specs: LibRangeCheck with per-spec max range threshold.
-------------------------------------------------------------------------------

local SPEC_SPELLS = {
    -- Paladin (Protection, Retribution)
    [66] = 96231, [70] = 96231,
    -- Death Knight (all specs)
    [250] = 316239, [251] = 316239, [252] = 316239,
    -- Demon Hunter (Havoc, Vengeance)
    [577] = 162794, [581] = 344859,
    -- Hunter (Survival)
    [255] = 186270,
    -- Druid (Feral, Guardian)
    [103] = 5221, [104] = 5221,
    -- Monk (Brewmaster, Windwalker)
    [268] = 205523, [269] = 205523,
    -- Warrior (Arms, Fury, Protection)
    [71] = 1464, [72] = 1464, [73] = 23922,
    -- Shaman (Enhancement)
    [263] = 17364,
    -- Rogue (all specs)
    [259] = 1752, [260] = 1752, [261] = 1752,
};

local SPEC_ITEMS = {
    -- Paladin (Holy) — melee healer, no melee attack spell; use 3yd item check.
    [65] = 42732, -- Everfrost Razor (3 yards)
};

local SPEC_RANGE = {
    -- Druid (Balance, Restoration)
    [102] = 40, [105] = 40,
    -- Monk (Mistweaver)
    [270] = 40,
    -- Shaman (Elemental, Restoration)
    [262] = 40, [264] = 40,
    -- Hunter (Beast Mastery, Marksmanship)
    [253] = 40, [254] = 40,
    -- Mage (all specs)
    [62] = 40, [63] = 40, [64] = 40,
    -- Warlock (all specs)
    [265] = 40, [266] = 40, [267] = 40,
    -- Priest (all specs)
    [256] = 40, [257] = 40, [258] = 40,
    -- Evoker (25yd)
    [1467] = 25, [1468] = 25, [1473] = 25,
};

local cachedMeleeSpell = nil;
local cachedMeleeItem = nil;
local cachedMaxRange = 40;

local function refreshMaxRange()
    local specID = PlayerUtil and PlayerUtil.GetCurrentSpecID and PlayerUtil.GetCurrentSpecID();

    -- Melee spec: use direct spell check.
    if (specID and SPEC_SPELLS[specID]) then
        cachedMeleeSpell = SPEC_SPELLS[specID];
        cachedMeleeItem = nil;
        cachedMaxRange = nil;
        return;
    end

    -- Melee spec with item check (no melee spell available).
    if (specID and SPEC_ITEMS[specID]) then
        cachedMeleeSpell = nil;
        cachedMeleeItem = SPEC_ITEMS[specID];
        cachedMaxRange = nil;
        return;
    end

    -- Ranged spec: use LibRangeCheck with threshold.
    cachedMeleeSpell = nil;
    cachedMeleeItem = nil;

    if (specID and SPEC_RANGE[specID]) then
        cachedMaxRange = SPEC_RANGE[specID];
        return;
    end

    -- Devourer DH: DH class + not Havoc/Vengeance = Devourer (25yd ranged).
    if (specID and select(2, UnitClass("player")) == "DEMONHUNTER" and specID ~= 577 and specID ~= 581) then
        cachedMaxRange = 25;
        return;
    end

    cachedMaxRange = 40;
end

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

local function clearStatus()
    rangeText:SetText("");
    if (lastStatusState) then
        Lantern:StopTextAnimation(rangeText);
        lastStatusState = nil;
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
            placeholder = "In Range",
        });
    end

    frame:SetScript("OnUpdate", function(_, delta)
        timeSinceUpdate = timeSinceUpdate + delta;
        if (timeSinceUpdate < UPDATE_INTERVAL) then return; end
        timeSinceUpdate = 0;

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

        -- Skip friendly targets
        if (not UnitCanAttack("player", "target")) then
            clearStatus();
            return;
        end

        -- Determine in-range status
        local inRange;

        if (cachedMeleeSpell) then
            -- Melee spec: direct spell range check (same as MeleeRangeIndicator)
            local result = C_Spell.IsSpellInRange(cachedMeleeSpell, "target");
            if (result == nil) then
                clearStatus();
                return;
            end
            inRange = result;
        elseif (cachedMeleeItem) then
            -- Melee spec without a melee spell (e.g. Holy Paladin): item range check
            local result = C_Item.IsItemInRange(cachedMeleeItem, "target");
            if (result == nil) then
                clearStatus();
                return;
            end
            inRange = result;
        else
            -- Ranged spec: LibRangeCheck with threshold
            if (not LibRangeCheck) then return; end

            local minR, maxR = LibRangeCheck:GetRange("target");
            if (not minR and not maxR) then
                clearStatus();
                return;
            end

            inRange = (maxR or minR or 100) <= cachedMaxRange;
        end

        if (inRange) then
            if (db and db.hideInRange and not unlocked) then
                clearStatus();
                return;
            end
            local c = db and db.inRangeColor or DEFAULTS.inRangeColor;
            rangeText:SetText(db and db.inRangeText or DEFAULTS.inRangeText);
            rangeText:SetTextColor(c.r, c.g, c.b, 1);
            if (lastStatusState ~= "inRange") then
                local anim = db and db.animationStyle or DEFAULTS.animationStyle;
                Lantern:StopTextAnimation(rangeText);
                if (anim ~= "none") then
                    Lantern:ApplyTextAnimation(rangeText, anim);
                end
                lastStatusState = "inRange";
            end
        else
            local c = db and db.outOfRangeColor or DEFAULTS.outOfRangeColor;
            rangeText:SetText(db and db.outOfRangeText or DEFAULTS.outOfRangeText);
            rangeText:SetTextColor(c.r, c.g, c.b, 1);
            if (lastStatusState ~= "outOfRange") then
                local anim = db and db.animationStyle or DEFAULTS.animationStyle;
                Lantern:StopTextAnimation(rangeText);
                if (anim ~= "none") then
                    Lantern:ApplyTextAnimation(rangeText, anim);
                end
                lastStatusState = "outOfRange";
            end
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
    if (self.db and self.db.locked and not UnitExists("target")) then
        frame:Hide();
    end
end

function module:ResetPosition()
    if (not frame) then return; end
    frame:ResetPosition();
end

function module:RefreshAnimation()
    if (not rangeText) then return; end
    lastStatusState = nil;
end

function module:OnInit()
    ensureDB(self);
    refreshMaxRange();
end

function module:OnEnable()
    ensureDB(self);

    createFrame(self);
    frame:RestorePosition();
    frame:UpdateLock();
    self:RefreshFont();
    refreshMaxRange();

    self.addon:ModuleRegisterEvent(self, "PLAYER_TARGET_CHANGED", function()
        if (not self.enabled or not frame) then return; end
        if (UnitExists("target")) then
            timeSinceUpdate = UPDATE_INTERVAL;
            frame:Show();
        else
            frame:Hide();
            if (rangeText) then
                Lantern:StopTextAnimation(rangeText);
            end
            lastStatusState = nil;
        end
    end);

    self.addon:ModuleRegisterEvent(self, "PLAYER_ENTERING_WORLD", function()
        refreshMaxRange();
    end);

    self.addon:ModuleRegisterEvent(self, "PLAYER_SPECIALIZATION_CHANGED", function()
        refreshMaxRange();
    end);

    -- Show immediately if player already has a target (e.g. after reload)
    if (UnitExists("target")) then
        timeSinceUpdate = UPDATE_INTERVAL;
        frame:Show();
    end
end

function module:OnDisable()
    if (frame) then frame:Hide(); end
    if (rangeText) then
        Lantern:StopTextAnimation(rangeText);
    end
    lastStatusState = nil;
end

Lantern:RegisterModule(module);
