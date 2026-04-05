local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end
local L = Lantern.L;

local LanternUX = _G.LanternUX;
local GetFontPath = Lantern.utils.GetFontPath;
local SafeSetFont = Lantern.utils.SafeSetFont;

local INTERRUPT_SPELLS = Lantern.INTERRUPT_SPELLS;

local module = Lantern:NewModule("FocusCastBar", {
    title = L["FOCUSCASTBAR_TITLE"],
    desc = L["FOCUSCASTBAR_DESC"],
    defaultEnabled = false,
    skipOptions = true,
});

local DEFAULTS = {
    locked = true, width = 250, height = 24, pos = nil,
    barReadyColor = { r = 0.18, g = 0.54, b = 0.18 },
    barCdColor = { r = 0.70, g = 0.36, b = 0.13 },
    nonIntColor = { r = 0.45, g = 0.45, b = 0.45 },
    bgColor = { r = 0.08, g = 0.08, b = 0.08 },
    bgAlpha = 0.8,
    textColor = { r = 1, g = 1, b = 1 },
    tickColor = { r = 1, g = 1, b = 1 },
    barReadyUseClassColor = false, barCdUseClassColor = false,
    nonIntUseClassColor = false, textUseClassColor = false, tickUseClassColor = false,
    showIcon = true, iconSize = 24, iconPosition = "LEFT",
    showSpellName = true, showTimeRemaining = true, font = nil, fontSize = 12,
    showEmpowerStages = true, hideFriendlyCasts = false, showShieldIcon = true,
    colorNonInterrupt = true, hideOnCooldown = false, showInterruptTick = true,
    showInInstances = { party = true, raid = true, arena = true, pvp = false, scenario = false, none = false },
    soundEnabled = false, soundName = nil,
};

-------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------

local castBarFrame;
local progressBar, interruptBar;
local iconFrame, shieldIcon, textFrame;
local spellNameText, timeText;
local tickTexture;
local borderFrame;

local isCasting = false;
local isChanneling = false;
local castEndTime = 0;
local castStartTime = 0;
local castDuration = 0;
local instanceAllowed = false;

local cachedInterruptSpellId = nil;
local cachedSpecId = nil;

local UPDATE_INTERVAL = 1 / 30; -- ~30 fps
local lastUpdate = 0;

local DEFAULT_FONT = "Fonts\\FRIZQT__.TTF";

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function getColor(db, key, classKey)
    if (db[classKey]) then
        local _, class = UnitClass("player");
        local color = C_ClassColor.GetClassColor(class);
        if (color) then
            return color.r, color.g, color.b;
        end
    end
    local c = db[key];
    return c.r, c.g, c.b;
end

local function getFontPath(db)
    if (db.font) then
        return GetFontPath(db.font);
    end
    return DEFAULT_FONT;
end

local function ensureDB(self)
    self.db = Lantern.utils.InitModuleDB(self.addon, "focusCastBar", DEFAULTS);
end

-------------------------------------------------------------------------------
-- Interrupt Intelligence
-------------------------------------------------------------------------------

local function GetInterruptSpellId()
    local specId = GetSpecializationInfo(GetSpecialization() or 0);
    if (not specId) then
        cachedInterruptSpellId = nil;
        cachedSpecId = nil;
        return nil;
    end
    if (specId == cachedSpecId and cachedInterruptSpellId ~= nil) then
        return cachedInterruptSpellId;
    end
    cachedSpecId = specId;
    local _, class = UnitClass("player");
    local classTable = INTERRUPT_SPELLS and INTERRUPT_SPELLS[class];
    cachedInterruptSpellId = classTable and classTable[specId] or false;
    return cachedInterruptSpellId or nil;
end

-------------------------------------------------------------------------------
-- Frame Creation
-------------------------------------------------------------------------------

local function UpdateLayout(db)
    if (not castBarFrame) then return; end

    local w = db.width or DEFAULTS.width;
    local h = db.height or DEFAULTS.height;
    local iconSz = db.iconSize or DEFAULTS.iconSize;
    local showIc = db.showIcon ~= false;

    castBarFrame:SetSize(w + (showIc and iconSz or 0), h);

    -- Background
    castBarFrame.bg:SetVertexColor(db.bgColor.r, db.bgColor.g, db.bgColor.b, db.bgAlpha or DEFAULTS.bgAlpha);

    -- Progress bar
    progressBar:ClearAllPoints();
    if (showIc and db.iconPosition == "LEFT") then
        progressBar:SetPoint("TOPLEFT", castBarFrame, "TOPLEFT", iconSz, 0);
        progressBar:SetPoint("BOTTOMRIGHT", castBarFrame, "BOTTOMRIGHT", 0, 0);
    elseif (showIc and db.iconPosition == "RIGHT") then
        progressBar:SetPoint("TOPLEFT", castBarFrame, "TOPLEFT", 0, 0);
        progressBar:SetPoint("BOTTOMRIGHT", castBarFrame, "BOTTOMRIGHT", -iconSz, 0);
    else
        progressBar:SetPoint("TOPLEFT", castBarFrame, "TOPLEFT", 0, 0);
        progressBar:SetPoint("BOTTOMRIGHT", castBarFrame, "BOTTOMRIGHT", 0, 0);
    end

    -- Interrupt bar (same size as progress bar)
    interruptBar:ClearAllPoints();
    interruptBar:SetAllPoints(progressBar);

    -- Icon
    if (showIc) then
        iconFrame:SetSize(iconSz, iconSz);
        iconFrame:ClearAllPoints();
        if (db.iconPosition == "RIGHT") then
            iconFrame:SetPoint("LEFT", progressBar, "RIGHT", 0, 0);
        else
            iconFrame:SetPoint("RIGHT", progressBar, "LEFT", 0, 0);
        end
        iconFrame:Show();
    else
        iconFrame:Hide();
    end

    -- Shield icon
    shieldIcon:SetSize(iconSz * 0.6, iconSz * 0.6);
    shieldIcon:ClearAllPoints();
    shieldIcon:SetPoint("TOP", castBarFrame, "BOTTOM", 0, -2);

    -- Border
    borderFrame:ClearAllPoints();
    borderFrame:SetAllPoints(progressBar);

    -- Text
    local fontPath = getFontPath(db);
    local fontSize = db.fontSize or DEFAULTS.fontSize;
    SafeSetFont(spellNameText, fontPath, fontSize, "OUTLINE");
    SafeSetFont(timeText, fontPath, fontSize, "OUTLINE");

    local tr, tg, tb = getColor(db, "textColor", "textUseClassColor");
    spellNameText:SetTextColor(tr, tg, tb);
    timeText:SetTextColor(tr, tg, tb);

    spellNameText:SetShown(db.showSpellName ~= false);
    timeText:SetShown(db.showTimeRemaining ~= false);

    -- Tick texture
    local tickR, tickG, tickB = getColor(db, "tickColor", "tickUseClassColor");
    tickTexture:SetColorTexture(tickR, tickG, tickB, 1);
    tickTexture:SetSize(2, h);
end

local function createFrame(self)
    if (castBarFrame) then return; end

    -- Main container
    castBarFrame = CreateFrame("Frame", "Lantern_FocusCastBar", UIParent, "BackdropTemplate");
    castBarFrame:SetSize(DEFAULTS.width + DEFAULTS.iconSize, DEFAULTS.height);
    castBarFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -150);
    castBarFrame:SetFrameStrata("MEDIUM");
    castBarFrame:Hide();

    -- Background
    castBarFrame.bg = castBarFrame:CreateTexture("Lantern_FocusCastBar_BG", "BACKGROUND");
    castBarFrame.bg:SetAllPoints(castBarFrame);
    castBarFrame.bg:SetColorTexture(DEFAULTS.bgColor.r, DEFAULTS.bgColor.g, DEFAULTS.bgColor.b, DEFAULTS.bgAlpha);

    -- Progress bar (StatusBar)
    progressBar = CreateFrame("StatusBar", "Lantern_FocusCastBar_Progress", castBarFrame);
    progressBar:SetMinMaxValues(0, 1);
    progressBar:SetValue(0);
    progressBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");
    progressBar:SetStatusBarColor(0.18, 0.54, 0.18);

    -- Interrupt bar (invisible, used for tick positioning)
    interruptBar = CreateFrame("StatusBar", "Lantern_FocusCastBar_Interrupt", castBarFrame);
    interruptBar:SetMinMaxValues(0, 1);
    interruptBar:SetValue(0);
    interruptBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");
    interruptBar:SetAlpha(0); -- Invisible

    -- Tick texture (anchored to interrupt bar fill edge)
    tickTexture = interruptBar:CreateTexture("Lantern_FocusCastBar_Tick", "OVERLAY");
    tickTexture:SetColorTexture(1, 1, 1, 1);
    tickTexture:SetSize(2, DEFAULTS.height);
    tickTexture:SetPoint("LEFT", interruptBar:GetStatusBarTexture(), "RIGHT", 0, 0);
    tickTexture:Hide();

    -- Icon frame
    iconFrame = CreateFrame("Frame", "Lantern_FocusCastBar_Icon", castBarFrame);
    iconFrame:SetSize(DEFAULTS.iconSize, DEFAULTS.iconSize);
    iconFrame.tex = iconFrame:CreateTexture("Lantern_FocusCastBar_IconTex", "ARTWORK");
    iconFrame.tex:SetAllPoints();
    iconFrame.tex:SetTexCoord(0.07, 0.93, 0.07, 0.93);

    -- Shield icon (non-interruptible indicator)
    shieldIcon = castBarFrame:CreateTexture("Lantern_FocusCastBar_Shield", "OVERLAY");
    shieldIcon:SetAtlas("nameplates-InterruptShield");
    shieldIcon:SetSize(14, 14);
    shieldIcon:SetPoint("TOP", castBarFrame, "BOTTOM", 0, -2);
    shieldIcon:Hide();

    -- Border frame
    borderFrame = CreateFrame("Frame", "Lantern_FocusCastBar_Border", castBarFrame, "BackdropTemplate");
    borderFrame:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    });
    borderFrame:SetBackdropBorderColor(0, 0, 0, 0.6);

    -- Text frame (overlay on progress bar)
    textFrame = CreateFrame("Frame", "Lantern_FocusCastBar_Text", progressBar);
    textFrame:SetAllPoints();
    textFrame:SetFrameLevel(progressBar:GetFrameLevel() + 2);

    spellNameText = textFrame:CreateFontString("Lantern_FocusCastBar_SpellName", "OVERLAY");
    spellNameText:SetPoint("LEFT", textFrame, "LEFT", 4, 0);
    spellNameText:SetPoint("RIGHT", textFrame, "RIGHT", -50, 0);
    spellNameText:SetJustifyH("LEFT");
    spellNameText:SetWordWrap(false);
    SafeSetFont(spellNameText, DEFAULT_FONT, DEFAULTS.fontSize, "OUTLINE");

    timeText = textFrame:CreateFontString("Lantern_FocusCastBar_TimeText", "OVERLAY");
    timeText:SetPoint("RIGHT", textFrame, "RIGHT", -4, 0);
    timeText:SetJustifyH("RIGHT");
    SafeSetFont(timeText, DEFAULT_FONT, DEFAULTS.fontSize, "OUTLINE");

    -- MakeDraggable
    if (LanternUX and LanternUX.MakeDraggable) then
        LanternUX.MakeDraggable(castBarFrame, {
            getPos    = function() return self.db and self.db.pos; end,
            setPos    = function(pos) if (self.db) then self.db.pos = pos; end end,
            getLocked = function() return self.db and self.db.locked; end,
            setLocked = function(val) if (self.db) then self.db.locked = val; end end,
            defaultPoint = { "CENTER", UIParent, "CENTER", 0, -150 },
        });
    end

    -- OnUpdate for bar color, time text, tick position
    castBarFrame:SetScript("OnUpdate", function(_, elapsed)
        lastUpdate = lastUpdate + elapsed;
        if (lastUpdate < UPDATE_INTERVAL) then return; end
        lastUpdate = 0;

        if (not isCasting and not isChanneling) then return; end

        local db = self.db or DEFAULTS;
        local now = GetTime();

        -- Update time remaining text
        if (db.showTimeRemaining ~= false) then
            local remaining;
            if (isCasting) then
                remaining = castEndTime - now;
            elseif (isChanneling) then
                remaining = castEndTime - now;
            end
            if (remaining and remaining > 0) then
                timeText:SetText(string.format("%.1f", remaining));
            else
                timeText:SetText("");
            end
        end

        -- Update progress bar value
        if (isCasting) then
            local progress = (now - castStartTime) / castDuration;
            progressBar:SetValue(math.min(progress, 1));
        elseif (isChanneling) then
            local progress = (castEndTime - now) / castDuration;
            progressBar:SetValue(math.max(progress, 0));
        end

        -- Update bar color based on interrupt cooldown
        local spellId = GetInterruptSpellId();
        if (spellId) then
            local cdDuration = C_Spell.GetSpellCooldownDuration(spellId);
            if (cdDuration) then
                local isReady = cdDuration:IsZero();
                local rR, rG, rB = getColor(db, "barReadyColor", "barReadyUseClassColor");
                local cR, cG, cB = getColor(db, "barCdColor", "barCdUseClassColor");
                if (isReady) then
                    progressBar:SetStatusBarColor(rR, rG, rB);
                else
                    progressBar:SetStatusBarColor(cR, cG, cB);
                end

                -- Hide on CD option
                if (db.hideOnCooldown and not isReady) then
                    castBarFrame:Hide();
                    return;
                end
            end
        end

        -- Update interrupt tick
        if (db.showInterruptTick ~= false and spellId) then
            local cdDuration = C_Spell.GetSpellCooldownDuration(spellId);
            if (cdDuration and not cdDuration:IsZero()) then
                local cdRemaining = cdDuration:GetSeconds();
                if (castDuration > 0 and cdRemaining > 0 and cdRemaining < castDuration) then
                    local tickProgress = cdRemaining / castDuration;
                    interruptBar:SetValue(tickProgress);
                    tickTexture:Show();
                else
                    tickTexture:Hide();
                end
            else
                tickTexture:Hide();
            end
        else
            tickTexture:Hide();
        end
    end);
end

-------------------------------------------------------------------------------
-- Cast Tracking
-------------------------------------------------------------------------------

local function StartCast(self)
    local db = self.db or DEFAULTS;
    if (not instanceAllowed) then return; end
    if (not castBarFrame) then createFrame(self); end

    local name, text, texture, startTimeMs, endTimeMs, isTradeSkill, castID, notInterruptible, spellId = UnitCastingInfo("focus");
    if (not name) then return; end

    -- Hide for friendly targets if option set
    if (db.hideFriendlyCasts and UnitIsFriend("player", "focus")) then return; end

    local durationMs = UnitCastingDuration("focus");
    if (not durationMs or durationMs <= 0) then return; end
    local duration = durationMs / 1000;

    isCasting = true;
    isChanneling = false;
    castStartTime = startTimeMs / 1000;
    castEndTime = endTimeMs / 1000;
    castDuration = duration;

    progressBar:SetMinMaxValues(0, 1);
    progressBar:SetValue(0);
    interruptBar:SetMinMaxValues(0, 1);
    interruptBar:SetValue(0);

    -- Icon
    if (db.showIcon ~= false and texture) then
        iconFrame.tex:SetTexture(texture);
        iconFrame:Show();
    else
        iconFrame:Hide();
    end

    -- Spell name
    if (db.showSpellName ~= false) then
        spellNameText:SetText(name);
    end

    -- Shield icon & non-interruptible coloring
    -- notInterruptible is a SECRET value: pass directly, never store or compare
    if (db.showShieldIcon) then
        shieldIcon:SetAlphaFromBoolean(notInterruptible);
    else
        shieldIcon:SetAlpha(0);
    end

    if (db.colorNonInterrupt) then
        local nR, nG, nB = getColor(db, "nonIntColor", "nonIntUseClassColor");
        progressBar:GetStatusBarTexture():SetVertexColorFromBoolean(notInterruptible, nR, nG, nB, 1);
    end

    castBarFrame:Show();
end

local function StartChannel(self)
    local db = self.db or DEFAULTS;
    if (not instanceAllowed) then return; end
    if (not castBarFrame) then createFrame(self); end

    local name, text, texture, startTimeMs, endTimeMs, isTradeSkill, notInterruptible, spellId, _, numStages = UnitChannelInfo("focus");
    if (not name) then return; end

    -- Hide for friendly targets if option set
    if (db.hideFriendlyCasts and UnitIsFriend("player", "focus")) then return; end

    local durationMs = UnitChannelDuration("focus");
    if (not durationMs or durationMs <= 0) then return; end
    local duration = durationMs / 1000;

    isCasting = false;
    isChanneling = true;
    castStartTime = startTimeMs / 1000;
    castEndTime = endTimeMs / 1000;
    castDuration = duration;

    progressBar:SetMinMaxValues(0, 1);
    progressBar:SetValue(1);
    interruptBar:SetMinMaxValues(0, 1);
    interruptBar:SetValue(0);

    -- Icon
    if (db.showIcon ~= false and texture) then
        iconFrame.tex:SetTexture(texture);
        iconFrame:Show();
    else
        iconFrame:Hide();
    end

    -- Spell name
    if (db.showSpellName ~= false) then
        spellNameText:SetText(name);
    end

    -- Shield icon & non-interruptible coloring (SECRET value)
    if (db.showShieldIcon) then
        shieldIcon:SetAlphaFromBoolean(notInterruptible);
    else
        shieldIcon:SetAlpha(0);
    end

    if (db.colorNonInterrupt) then
        local nR, nG, nB = getColor(db, "nonIntColor", "nonIntUseClassColor");
        progressBar:GetStatusBarTexture():SetVertexColorFromBoolean(notInterruptible, nR, nG, nB, 1);
    end

    castBarFrame:Show();
end

local function StopCast()
    isCasting = false;
    isChanneling = false;
    castEndTime = 0;
    castStartTime = 0;
    castDuration = 0;
    if (castBarFrame) then
        castBarFrame:Hide();
    end
    if (shieldIcon) then
        shieldIcon:SetAlpha(0);
    end
    if (tickTexture) then
        tickTexture:Hide();
    end
end

local function CheckFocusCast(self)
    StopCast();
    if (not UnitExists("focus")) then return; end

    -- Check for active cast first, then channel
    local name = UnitCastingInfo("focus");
    if (name) then
        StartCast(self);
        return;
    end

    name = UnitChannelInfo("focus");
    if (name) then
        StartChannel(self);
    end
end

-------------------------------------------------------------------------------
-- Instance Filtering
-------------------------------------------------------------------------------

local function UpdateInstanceFilter(self)
    local db = self.db or DEFAULTS;
    local _, instanceType = GetInstanceInfo();
    local filter = db.showInInstances or DEFAULTS.showInInstances;
    instanceAllowed = filter[instanceType] or false;

    -- If not allowed, hide the bar
    if (not instanceAllowed) then
        StopCast();
    end
end

-------------------------------------------------------------------------------
-- Unit Event Frame
-- ModuleRegisterEvent uses frame:RegisterEvent() which fires for ALL units.
-- UNIT_SPELLCAST_* events must be filtered to "focus" only via RegisterUnitEvent.
-------------------------------------------------------------------------------

local unitEventFrame;

local function CreateUnitEventFrame(self)
    if (unitEventFrame) then return; end

    unitEventFrame = CreateFrame("Frame", "Lantern_FocusCastBar_UnitEvents");
    unitEventFrame:SetScript("OnEvent", function(_, event, unit, ...)
        if (not self.enabled) then return; end
        if (not instanceAllowed) then return; end

        if (event == "UNIT_SPELLCAST_START") then
            StartCast(self);
        elseif (event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED") then
            StopCast();
        elseif (event == "UNIT_SPELLCAST_CHANNEL_START") then
            StartChannel(self);
        elseif (event == "UNIT_SPELLCAST_CHANNEL_STOP") then
            StopCast();
        elseif (event == "UNIT_SPELLCAST_DELAYED" or event == "UNIT_SPELLCAST_CHANNEL_UPDATE") then
            -- Recheck current cast/channel for updated times
            CheckFocusCast(self);
        elseif (event == "UNIT_SPELLCAST_INTERRUPTIBLE" or event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE") then
            -- Shield state changed, re-read cast info
            if (isCasting) then
                StartCast(self);
            elseif (isChanneling) then
                StartChannel(self);
            end
        elseif (event == "UNIT_SPELLCAST_EMPOWER_START") then
            StartChannel(self);
        elseif (event == "UNIT_SPELLCAST_EMPOWER_STOP") then
            StopCast();
        elseif (event == "UNIT_SPELLCAST_EMPOWER_UPDATE") then
            CheckFocusCast(self);
        end
    end);
end

local function RegisterUnitEvents()
    if (not unitEventFrame) then return; end
    unitEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", "focus");
    unitEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "focus");
    unitEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "focus");
    unitEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "focus");
    unitEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "focus");
    unitEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "focus");
    unitEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_DELAYED", "focus");
    unitEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", "focus");
    unitEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTIBLE", "focus");
    unitEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", "focus");
    unitEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_START", "focus");
    unitEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_STOP", "focus");
    unitEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_UPDATE", "focus");
end

local function UnregisterUnitEvents()
    if (not unitEventFrame) then return; end
    unitEventFrame:UnregisterAllEvents();
end

-------------------------------------------------------------------------------
-- Module Lifecycle
-------------------------------------------------------------------------------

function module:OnInit()
    ensureDB(self);
end

function module:OnEnable()
    ensureDB(self);
    createFrame(self);
    UpdateLayout(self.db);

    castBarFrame:RestorePosition();
    castBarFrame:UpdateLock();

    -- Create and register unit events on a dedicated frame
    CreateUnitEventFrame(self);
    RegisterUnitEvents();

    -- Non-unit events via ModuleRegisterEvent (auto-unregistered on disable)
    self.addon:ModuleRegisterEvent(self, "PLAYER_ENTERING_WORLD", function()
        UpdateInstanceFilter(self);
        CheckFocusCast(self);
    end);

    self.addon:ModuleRegisterEvent(self, "PLAYER_SPECIALIZATION_CHANGED", function()
        cachedInterruptSpellId = nil;
        cachedSpecId = nil;
    end);

    self.addon:ModuleRegisterEvent(self, "PLAYER_FOCUS_CHANGED", function()
        CheckFocusCast(self);
    end);

    -- Initial state
    UpdateInstanceFilter(self);
    CheckFocusCast(self);
end

function module:OnDisable()
    UnregisterUnitEvents();
    StopCast();
    if (castBarFrame) then
        castBarFrame:Hide();
    end
end

-------------------------------------------------------------------------------
-- Exported Methods (called from WidgetOptions.lua)
-------------------------------------------------------------------------------

function module:UpdateDisplay()
    if (not castBarFrame) then return; end
    ensureDB(self);
    UpdateLayout(self.db);
end

function module:UpdateLock()
    if (not castBarFrame) then return; end
    castBarFrame:UpdateLock();
    -- When locking back, hide if not casting
    if (self.db and self.db.locked and not isCasting and not isChanneling) then
        castBarFrame:Hide();
    end
end

function module:ResetPosition()
    if (not castBarFrame) then return; end
    castBarFrame:ResetPosition();
end

Lantern:RegisterModule(module);
