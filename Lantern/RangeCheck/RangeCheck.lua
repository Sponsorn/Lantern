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
    displayMode = "status",      -- "range" = numbers, "status" = In Range / Out of Range
    hideInRange = false,         -- hide display when target is in range (status mode only)
    inRangeText = "In Range",
    outOfRangeText = "Out of Range",
    inRangeColor = { r = 0.2, g = 1.0, b = 0.2 },
    outOfRangeColor = { r = 1.0, g = 0.2, b = 0.2 },
    animationStyle = "none",     -- status mode text animation
};

local LibRangeCheck = LibStub and LibStub("LibRangeCheck-3.0", true);
local frame, rangeText;
local UPDATE_INTERVAL = 0.1;
local timeSinceUpdate = 0;
local lastStatusState = nil; -- tracks "inRange" / "outOfRange" for animation changes

-- Range mode bracket colors (not user-configurable — range mode is numeric).
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

-- Direct spell range check per spec. Each entry maps specID -> { id, range }.
-- Uses C_Spell.IsSpellInRange() for binary in-range detection (status mode).
-- Spells chosen are baseline (not talent-dependent) and targeted on enemies.
local SPEC_SPELLS = {
    -- Warrior (melee 5yd)
    [71]  = { id = 1464,   range = 5 },   -- Arms: Slam
    [72]  = { id = 1464,   range = 5 },   -- Fury: Slam
    [73]  = { id = 23922,  range = 5 },   -- Protection: Shield Slam

    -- Death Knight (melee 5yd)
    [250] = { id = 316239, range = 5 },   -- Blood: Rune Strike
    [251] = { id = 316239, range = 5 },   -- Frost: Rune Strike
    [252] = { id = 316239, range = 5 },   -- Unholy: Rune Strike

    -- Paladin
    [65]  = { id = 20473,  range = 40 },  -- Holy: Holy Shock
    [66]  = { id = 35395,  range = 5 },   -- Protection: Crusader Strike
    [70]  = { id = 35395,  range = 5 },   -- Retribution: Crusader Strike

    -- Monk
    [268] = { id = 205523, range = 5 },   -- Brewmaster: Blackout Kick
    [269] = { id = 100780, range = 5 },   -- Windwalker: Tiger Palm
    [270] = { id = 117952, range = 40 },  -- Mistweaver: Crackling Jade Lightning

    -- Druid (Shred/Mangle require Cat/Bear form; nil return handled by fallback)
    [102] = { id = 5176,   range = 40 },  -- Balance: Wrath
    [103] = { id = 5221,   range = 5 },   -- Feral: Shred
    [104] = { id = 33917,  range = 5 },   -- Guardian: Mangle
    [105] = { id = 5176,   range = 40 },  -- Restoration: Wrath

    -- Rogue (melee 5yd)
    [259] = { id = 1752,   range = 5 },   -- Assassination: Sinister Strike
    [260] = { id = 1752,   range = 5 },   -- Outlaw: Sinister Strike
    [261] = { id = 1752,   range = 5 },   -- Subtlety: Sinister Strike

    -- Demon Hunter (Devourer detected at runtime)
    [577] = { id = 162794, range = 5 },   -- Havoc: Chaos Strike
    [581] = { id = 344859, range = 5 },   -- Vengeance: Demon's Bite

    -- Shaman
    [262] = { id = 188196, range = 40 },  -- Elemental: Lightning Bolt
    [263] = { id = 17364,  range = 5 },   -- Enhancement: Stormstrike
    [264] = { id = 188196, range = 40 },  -- Restoration: Lightning Bolt

    -- Hunter
    [253] = { id = 75,     range = 40 },  -- Beast Mastery: Auto Shot
    [254] = { id = 75,     range = 40 },  -- Marksmanship: Auto Shot
    [255] = { id = 186270, range = 5 },   -- Survival: Raptor Strike

    -- Mage (ranged 40yd)
    [62]  = { id = 44425,  range = 40 },  -- Arcane: Arcane Barrage
    [63]  = { id = 133,    range = 40 },  -- Fire: Fireball
    [64]  = { id = 116,    range = 40 },  -- Frost: Frostbolt

    -- Warlock (ranged 40yd)
    [265] = { id = 172,    range = 40 },  -- Affliction: Corruption
    [266] = { id = 686,    range = 40 },  -- Demonology: Shadow Bolt
    [267] = { id = 29722,  range = 40 },  -- Destruction: Incinerate

    -- Priest (ranged 40yd)
    [256] = { id = 585,    range = 40 },  -- Discipline: Smite
    [257] = { id = 585,    range = 40 },  -- Holy: Smite
    [258] = { id = 589,    range = 40 },  -- Shadow: Shadow Word: Pain

    -- Evoker (25yd)
    [1467] = { id = 362969, range = 25 }, -- Devastation: Azure Strike
    [1468] = { id = 362969, range = 25 }, -- Preservation: Azure Strike
    [1473] = { id = 362969, range = 25 }, -- Augmentation: Azure Strike
};

-- Devourer DH spell (runtime detection since spec ID may change).
local DEVOURER_SPELL = { id = 473662, range = 25 }; -- Consume (25 yards)

-- Cached spell info, refreshed on spec change.
local cachedSpell = nil;

local function refreshSpellCache()
    local specID = PlayerUtil and PlayerUtil.GetCurrentSpecID and PlayerUtil.GetCurrentSpecID();
    if (specID and SPEC_SPELLS[specID]) then
        cachedSpell = SPEC_SPELLS[specID];
        return;
    end
    -- Devourer DH: DH class + not Havoc/Vengeance = Devourer.
    if (specID and select(2, UnitClass("player")) == "DEMONHUNTER" and specID ~= 577 and specID ~= 581) then
        cachedSpell = DEVOURER_SPELL;
        return;
    end
    cachedSpell = nil;
end

-- Direct range check via C_Spell.IsSpellInRange.
-- Returns true (in range), false (out of range), or nil (unknown/wrong form).
local function checkSpellRange()
    if (not cachedSpell) then return nil; end
    return C_Spell.IsSpellInRange(cachedSpell.id, "target");
end

-- Operating range derived from cached spell, fallback 40.
local function getSpecMaxRange()
    if (cachedSpell) then return cachedSpell.range; end
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

        local mode = db and db.displayMode or "range";

        if (mode == "status") then
            -- Status mode uses harm spells; clear text for non-attackable targets.
            -- Never frame:Hide() inside status mode — it kills the OnUpdate loop
            -- and there's no external event to restart it when range changes.
            if (not UnitCanAttack("player", "target")) then
                rangeText:SetText("");
                if (lastStatusState) then
                    Lantern:StopTextAnimation(rangeText);
                    lastStatusState = nil;
                end
                return;
            end

            -- Direct spell check: binary in-range detection per spec.
            local inRange = checkSpellRange();

            if (inRange == nil and LibRangeCheck) then
                -- Fallback to LibRangeCheck when direct check unavailable
                -- (e.g. Druid in wrong form, or unknown spec).
                local threshold = getSpecMaxRange();
                local minR, maxR = LibRangeCheck:GetRange("target");
                if (minR or maxR) then
                    inRange = (maxR or minR or 100) <= threshold;
                end
            end

            if (inRange == nil) then
                rangeText:SetText("");
                if (lastStatusState) then
                    Lantern:StopTextAnimation(rangeText);
                    lastStatusState = nil;
                end
                return;
            end

            if (inRange) then
                if (db and db.hideInRange and not unlocked) then
                    rangeText:SetText("");
                    if (lastStatusState) then
                        Lantern:StopTextAnimation(rangeText);
                        lastStatusState = nil;
                    end
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
        else
            -- Range mode: use LibRangeCheck for distance brackets.
            if (not LibRangeCheck) then
                frame:Hide();
                return;
            end

            local minRange, maxRange = LibRangeCheck:GetRange("target");
            if (not minRange and not maxRange) then
                if (not unlocked) then frame:Hide(); end
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

function module:RefreshAnimation()
    if (not rangeText) then return; end
    lastStatusState = nil; -- Force re-apply on next update tick
end

function module:OnInit()
    ensureDB(self);
    refreshSpellCache();
end

function module:OnEnable()
    ensureDB(self);

    createFrame(self);
    frame:RestorePosition();
    frame:UpdateLock();
    self:RefreshFont();
    refreshSpellCache();

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

    self.addon:ModuleRegisterEvent(self, "PLAYER_SPECIALIZATION_CHANGED", function()
        refreshSpellCache();
    end);
end

function module:OnDisable()
    if (frame) then frame:Hide(); end
    if (rangeText) then
        Lantern:StopTextAnimation(rangeText);
    end
    lastStatusState = nil;
end

Lantern:RegisterModule(module);
