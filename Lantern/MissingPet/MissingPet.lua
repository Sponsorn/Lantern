local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true);

local module = Lantern:NewModule("MissingPet", {
    title = "Missing Pet",
    desc = "Displays a warning when your pet is missing or set to passive.",
    skipOptions = true,
});

local DEFAULTS = {
    warningText = "Pet Missing!",
    passiveText = "Pet is PASSIVE!",
    framePosition = nil,
    showMissing = true,
    showPassive = true,
    locked = true,
    hideWhenMounted = true,
    hideInRestZone = false,
    dismountDelay = 5,
    animationStyle = "bounce",
    font = "Friz Quadrata TT",
    fontSize = 24,
    fontOutline = "OUTLINE",
    missingColor = { r = 1, g = 0.2, b = 0.2 },  -- Red
    passiveColor = { r = 1, g = 0.6, b = 0 },    -- Orange
    soundEnabled = false,
    soundName = "RaidWarning",
    soundRepeat = false,
    soundInterval = 5,
};

-------------------------------------------------------------------------------
-- Combat Lockdown Handling
-------------------------------------------------------------------------------

local pendingUpdate = nil;

local combatFrame = CreateFrame("Frame");
combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
combatFrame:SetScript("OnEvent", function(self, event)
    if (event == "PLAYER_REGEN_ENABLED" and pendingUpdate) then
        pendingUpdate();
        pendingUpdate = nil;
    end
end);

local function SafeUpdateUI(updateFn)
    if (InCombatLockdown()) then
        pendingUpdate = updateFn;
    else
        updateFn();
    end
end

-------------------------------------------------------------------------------
-- Pet Detection
-------------------------------------------------------------------------------

-- Class IDs: 3=Hunter, 6=DeathKnight, 8=Mage, 9=Warlock
-- Spec IDs: 252=Unholy DK, 253/254/255=Hunter specs, 64=Frost Mage, 265/266/267=Warlock specs
local PET_CLASS_IDS = {
    [3] = true,   -- Hunter (all specs)
    [9] = true,   -- Warlock (all specs)
};

local PET_SPEC_IDS = {
    [252] = true, -- Unholy Death Knight
    -- Note: Frost Mage (64) Water Elemental is talent-dependent, excluded for simplicity
};

local function IsPetClass()
    local _, _, classID = UnitClass("player");

    -- Check if class always has pets
    if (PET_CLASS_IDS[classID]) then
        return true;
    end

    -- Check if current spec has pets
    local specIndex = GetSpecialization();
    if (specIndex) then
        local specID = GetSpecializationInfo(specIndex);
        if (specID and PET_SPEC_IDS[specID]) then
            return true;
        end
    end

    return false;
end

local function IsPetOnPassive()
    if (not UnitExists("pet") or not PetHasActionBar()) then
        return false;
    end
    for slot = 1, (NUM_PET_ACTION_SLOTS or 10) do
        local name, _, isToken, isActive = GetPetActionInfo(slot);
        if (isToken and name == "PET_MODE_PASSIVE" and isActive) then
            return true;
        end
    end
    return false;
end

local function HasPet()
    return UnitExists("pet");
end

-- Warlock Grimoire of Sacrifice (talent 108503, spellID 196099) - sacrifices pet for power
-- When active, the player intentionally has no pet
local GRIMOIRE_OF_SACRIFICE_SPELL_ID = 196099;

local function HasGrimoireOfSacrifice()
    if (C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID) then
        local auraInfo = C_UnitAuras.GetPlayerAuraBySpellID(GRIMOIRE_OF_SACRIFICE_SPELL_ID);
        return auraInfo ~= nil;
    end
    -- Fallback for older API
    if (AuraUtil and AuraUtil.FindAuraBySpellID) then
        return AuraUtil.FindAuraBySpellID("player", GRIMOIRE_OF_SACRIFICE_SPELL_ID) ~= nil;
    end
    return false;
end

-------------------------------------------------------------------------------
-- Warning Frame
-------------------------------------------------------------------------------

local warningFrame = nil;
local warningText = nil;
local dismountTimer = nil;
local waitingAfterDismount = false;
local soundTimer = nil;

local function GetFontPath(fontName)
    if (LSM) then
        local path = LSM:Fetch("font", fontName);
        if (path) then return path; end
    end
    -- Fallback to default WoW font
    return "Fonts\\FRIZQT__.TTF";
end

-- Always get fresh database reference
local function getDB()
    return Lantern.db and Lantern.db.missingPet;
end

-------------------------------------------------------------------------------
-- Sound
-------------------------------------------------------------------------------

local function PlayWarningSound()
    local db = getDB();
    if (not db or not db.soundEnabled) then return; end
    if (not LSM) then return; end

    local sound = LSM:Fetch("sound", db.soundName or "RaidWarning");
    if (not sound) then return; end

    local soundId = tonumber(sound);
    if (soundId and PlaySound) then
        PlaySound(soundId, "Master");
    elseif (PlaySoundFile) then
        PlaySoundFile(sound, "Master");
    end
end

local function StopSoundTimer()
    if (soundTimer) then
        soundTimer:Cancel();
        soundTimer = nil;
    end
end

local function StartSoundTimer()
    StopSoundTimer();

    local db = getDB();
    if (not db or not db.soundEnabled) then return; end

    -- Play immediately
    PlayWarningSound();

    -- Set up repeat timer if enabled
    if (db.soundRepeat) then
        local interval = db.soundInterval or 5;
        if (interval > 0) then
            soundTimer = C_Timer.NewTicker(interval, PlayWarningSound);
        end
    end
end

local function UpdateWarningFont()
    if (not warningText) then return; end
    local db = getDB();
    if (not db) then return; end

    local fontPath = GetFontPath(db.font or DEFAULTS.font);
    local fontSize = db.fontSize or DEFAULTS.fontSize;
    local fontOutline = db.fontOutline or DEFAULTS.fontOutline;

    warningText:SetFont(fontPath, fontSize, fontOutline);
end

local function CreateWarningFrame()
    if (warningFrame) then return; end

    warningFrame = CreateFrame("Frame", "LanternMissingPetFrame", UIParent);
    warningFrame:SetSize(300, 50);
    warningFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 200);
    warningFrame:SetFrameStrata("MEDIUM");
    warningFrame:SetFrameLevel(1);
    warningFrame:EnableMouse(true);
    warningFrame:SetMovable(true);

    warningText = warningFrame:CreateFontString(nil, "OVERLAY");
    warningText:SetPoint("CENTER", warningFrame, "CENTER", 0, 0);
    warningText:SetTextColor(1, 0.2, 0.2, 1);
    warningText:SetShadowOffset(2, -2);
    warningText:SetShadowColor(0, 0, 0, 0.8);

    -- Apply font settings
    UpdateWarningFont();

    -- Drag functionality
    warningFrame:RegisterForDrag("LeftButton");
    warningFrame:SetScript("OnDragStart", function(self)
        local db = getDB();
        if (db and (not db.locked or IsShiftKeyDown())) then
            self:StartMoving();
        end
    end);
    warningFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing();
        -- Save position
        local db = getDB();
        if (db) then
            local point, _, relativePoint, x, y = self:GetPoint();
            db.framePosition = {
                point = point,
                relativePoint = relativePoint,
                x = x,
                y = y,
            };
        end
    end);

    warningFrame:Hide();
end

local function RestoreFramePosition()
    if (not warningFrame) then return; end
    local db = getDB();
    if (db and db.framePosition) then
        local pos = db.framePosition;
        warningFrame:ClearAllPoints();
        warningFrame:SetPoint(pos.point or "CENTER", UIParent, pos.relativePoint or "CENTER", pos.x or 0, pos.y or 200);
    end
end

local function UpdateFrameLock()
    -- Mouse must stay enabled for Shift+drag to work when locked
    -- The OnDragStart handler controls whether movement is allowed
    if (not warningFrame) then return; end
    warningFrame:EnableMouse(true);
end

-------------------------------------------------------------------------------
-- Update Logic
-------------------------------------------------------------------------------

local function ShouldHideWarning()
    -- Not a pet class/spec (e.g., Blood DK, Frost DK, most classes)
    if (not IsPetClass()) then
        return true;
    end

    -- Warlock with Grimoire of Sacrifice active (intentionally no pet)
    if (HasGrimoireOfSacrifice()) then
        return true;
    end

    -- Player is dead/ghost
    if (UnitIsDeadOrGhost("player")) then
        return true;
    end

    -- Always hide during combat
    if (UnitAffectingCombat("player")) then
        return true;
    end

    local db = getDB();
    if (not db) then return true; end

    -- Mounted, on taxi, or in vehicle
    if (db.hideWhenMounted) then
        if (IsMounted() or UnitOnTaxi("player") or UnitHasVehicleUI("player")) then
            return true;
        end
    end

    -- In rest zone
    if (db.hideInRestZone and IsResting()) then
        return true;
    end

    -- Waiting after dismount
    if (waitingAfterDismount) then
        return true;
    end

    return false;
end

local function GetWarningState()
    local db = getDB();
    if (not db) then return nil, nil; end

    -- Check for passive first (pet exists but is passive)
    if (db.showPassive and HasPet() and IsPetOnPassive()) then
        return "passive", db.passiveText or DEFAULTS.passiveText;
    end

    -- Check for missing pet
    if (db.showMissing and not HasPet()) then
        return "missing", db.warningText or DEFAULTS.warningText;
    end

    return nil, nil;
end

local currentState = nil;

local function UpdatePetStatus()
    if (not module.enabled) then
        if (warningFrame) then
            warningFrame:Hide();
            if (warningText) then
                Lantern:StopTextAnimation(warningText);
            end
        end
        StopSoundTimer();
        return;
    end

    CreateWarningFrame();

    local function doUpdate()
        if (ShouldHideWarning()) then
            warningFrame:Hide();
            if (warningText) then
                Lantern:StopTextAnimation(warningText);
            end
            StopSoundTimer();
            currentState = nil;
            return;
        end

        local state, text = GetWarningState();
        if (state and text) then
            warningText:SetText(text);

            -- Apply color based on state
            local db = getDB();
            if (state == "passive") then
                local c = db and db.passiveColor or DEFAULTS.passiveColor;
                warningText:SetTextColor(c.r, c.g, c.b, 1);
            else
                local c = db and db.missingColor or DEFAULTS.missingColor;
                warningText:SetTextColor(c.r, c.g, c.b, 1);
            end

            warningFrame:Show();

            -- Only restart animation and sound if state changed
            if (state ~= currentState) then
                local animStyle = db and db.animationStyle or DEFAULTS.animationStyle;
                Lantern:ApplyTextAnimation(warningText, animStyle);
                StartSoundTimer();
                currentState = state;
            end
        else
            warningFrame:Hide();
            if (warningText) then
                Lantern:StopTextAnimation(warningText);
            end
            StopSoundTimer();
            currentState = nil;
        end
    end

    SafeUpdateUI(doUpdate);
end

-------------------------------------------------------------------------------
-- Dismount Delay Handling
-------------------------------------------------------------------------------

local function SchedulePostDismountCheck()
    if (dismountTimer) then
        dismountTimer:Cancel();
        dismountTimer = nil;
    end

    local db = getDB();
    local delay = db and db.dismountDelay or DEFAULTS.dismountDelay;

    if (delay > 0) then
        waitingAfterDismount = true;
        dismountTimer = C_Timer.NewTimer(delay, function()
            dismountTimer = nil;
            waitingAfterDismount = false;
            UpdatePetStatus();
        end);
    else
        waitingAfterDismount = false;
    end

    UpdatePetStatus();
end

local function OnMountChanged()
    local db = getDB();
    if (not db or not db.hideWhenMounted) then
        UpdatePetStatus();
        return;
    end

    -- Check if we just dismounted
    if (not IsMounted() and not UnitOnTaxi("player") and not UnitHasVehicleUI("player")) then
        SchedulePostDismountCheck();
    else
        -- Mounted - cancel any pending timer and hide immediately
        if (dismountTimer) then
            dismountTimer:Cancel();
            dismountTimer = nil;
        end
        waitingAfterDismount = false;
        UpdatePetStatus();
    end
end

-------------------------------------------------------------------------------
-- Public API for Options
-------------------------------------------------------------------------------

function module:ResetPosition()
    if (not warningFrame) then return; end
    warningFrame:ClearAllPoints();
    warningFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 200);
    local db = getDB();
    if (db) then
        db.framePosition = nil;
    end
end

function module:RefreshAnimation()
    if (not warningText or not warningFrame or not warningFrame:IsShown()) then
        return;
    end
    local db = getDB();
    local animStyle = db and db.animationStyle or DEFAULTS.animationStyle;
    Lantern:StopTextAnimation(warningText);
    Lantern:ApplyTextAnimation(warningText, animStyle);
end

function module:RefreshWarning()
    currentState = nil; -- Force state refresh
    UpdatePetStatus();
end

function module:RefreshFont()
    UpdateWarningFont();
end

function module:UpdateLock()
    UpdateFrameLock();
end

-------------------------------------------------------------------------------
-- Module Lifecycle
-------------------------------------------------------------------------------

local function ensureDB()
    if (not Lantern.db) then return; end
    if (not Lantern.db.missingPet) then
        Lantern.db.missingPet = {};
    end
    local db = Lantern.db.missingPet;

    for k, v in pairs(DEFAULTS) do
        if (db[k] == nil) then
            db[k] = v;
        end
    end
end

function module:OnInit()
    ensureDB();
    CreateWarningFrame();
    RestoreFramePosition();
    UpdateFrameLock();
end

function module:OnEnable()
    ensureDB();

    -- Pet status events
    self.addon:ModuleRegisterEvent(self, "UNIT_PET", self.OnUnitPet);
    self.addon:ModuleRegisterEvent(self, "PET_BAR_UPDATE", self.OnPetBarUpdate);
    self.addon:ModuleRegisterEvent(self, "PLAYER_ENTERING_WORLD", self.OnPlayerEnteringWorld);

    -- Mount/vehicle events
    self.addon:ModuleRegisterEvent(self, "PLAYER_MOUNT_DISPLAY_CHANGED", self.OnMountChanged);
    self.addon:ModuleRegisterEvent(self, "UNIT_ENTERED_VEHICLE", self.OnVehicleChanged);
    self.addon:ModuleRegisterEvent(self, "UNIT_EXITED_VEHICLE", self.OnVehicleChanged);

    -- Rest zone events
    self.addon:ModuleRegisterEvent(self, "PLAYER_UPDATE_RESTING", self.OnRestingChanged);

    -- Combat events
    self.addon:ModuleRegisterEvent(self, "PLAYER_REGEN_DISABLED", self.OnCombatStart);
    self.addon:ModuleRegisterEvent(self, "PLAYER_REGEN_ENABLED", self.OnCombatEnd);

    -- Resurrection events
    self.addon:ModuleRegisterEvent(self, "PLAYER_ALIVE", self.OnPlayerAlive);
    self.addon:ModuleRegisterEvent(self, "PLAYER_UNGHOST", self.OnPlayerAlive);

    -- Register LSM callback to refresh font when fonts are registered (uses CallbackHandler)
    if (LSM and LSM.RegisterCallback) then
        LSM.RegisterCallback(module, "LibSharedMedia_Registered", function(_, mediaType, key)
            if (mediaType == "font") then
                UpdateWarningFont();
            end
        end);
        LSM.RegisterCallback(module, "LibSharedMedia_SetGlobal", function(_, mediaType)
            if (mediaType == "font") then
                UpdateWarningFont();
            end
        end);
    end

    -- Initial update
    UpdatePetStatus();
end

function module:OnDisable()
    -- Cancel any pending timers
    if (dismountTimer) then
        dismountTimer:Cancel();
        dismountTimer = nil;
    end
    StopSoundTimer();
    waitingAfterDismount = false;
    pendingUpdate = nil;

    -- Unregister LSM callbacks
    if (LSM and LSM.UnregisterCallback) then
        LSM.UnregisterCallback(module, "LibSharedMedia_Registered");
        LSM.UnregisterCallback(module, "LibSharedMedia_SetGlobal");
    end

    -- Hide the warning
    if (warningFrame) then
        warningFrame:Hide();
    end
    if (warningText) then
        Lantern:StopTextAnimation(warningText);
    end
    currentState = nil;
end

-------------------------------------------------------------------------------
-- Event Handlers
-------------------------------------------------------------------------------

function module:OnUnitPet(event, unit)
    if (unit == "player") then
        UpdatePetStatus();
    end
end

function module:OnPetBarUpdate()
    UpdatePetStatus();
end

function module:OnPlayerEnteringWorld()
    -- Short delay to let pet state and fonts settle
    C_Timer.After(0.5, function()
        if (module.enabled) then
            UpdateWarningFont(); -- Refresh font in case other addons registered fonts
            UpdatePetStatus();
        end
    end);
end

function module:OnMountChanged()
    OnMountChanged();
end

function module:OnVehicleChanged(event, unit)
    if (unit == "player") then
        OnMountChanged();
    end
end

function module:OnRestingChanged()
    UpdatePetStatus();
end

function module:OnCombatStart()
    -- Immediately hide warning and stop sound when entering combat
    if (warningFrame) then
        warningFrame:Hide();
    end
    if (warningText) then
        Lantern:StopTextAnimation(warningText);
    end
    StopSoundTimer();
    currentState = nil;
end

function module:OnCombatEnd()
    -- Re-evaluate warning state when leaving combat
    UpdatePetStatus();
end

function module:OnPlayerAlive()
    UpdatePetStatus();
end

Lantern:RegisterModule(module);
