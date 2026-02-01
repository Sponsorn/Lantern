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
    soundMissing = true,
    soundPassive = true,
    soundName = "RaidWarning",
    soundRepeat = false,
    soundInterval = 5,
    soundInCombat = false,
};

-------------------------------------------------------------------------------
-- Pet Detection
-------------------------------------------------------------------------------

-- Class IDs: 3=Hunter, 6=DeathKnight, 8=Mage, 9=Warlock
-- Spec IDs: 253=BM Hunter, 254=MM Hunter, 255=Survival Hunter

-- Pet summoning spell IDs (for classes where pets are talent/spec-dependent)
local RAISE_DEAD_SPELL_ID = 46584;       -- Unholy DK
local WATER_ELEMENTAL_SPELL_ID = 31687;  -- Frost Mage
local GRIMOIRE_OF_SACRIFICE_SPELL_ID = 196099; -- Warlock, when active, the player intentionally has no pet

-- MM Hunter talent node 104127 choices:
--   Avian Specialization (Entry 128710, Spell 466867) - NO pet
--   Unbreakable Bond (Entry 129619, Spell 1223323) - HAS pet
local MM_HUNTER_PET_NODE_ID = 104127;
local MM_HUNTER_PET_ENTRY_ID = 129619;  -- Unbreakable Bond

local function HasMMHunterPetTalent()
    local configID = C_ClassTalents and C_ClassTalents.GetActiveConfigID and C_ClassTalents.GetActiveConfigID();
    if (not configID) then return false; end

    local nodeInfo = C_Traits and C_Traits.GetNodeInfo and C_Traits.GetNodeInfo(configID, MM_HUNTER_PET_NODE_ID);
    if (nodeInfo and nodeInfo.activeEntry) then
        return nodeInfo.activeEntry.entryID == MM_HUNTER_PET_ENTRY_ID;
    end
    return false;
end

local function IsPetClass()
    local _, _, classID = UnitClass("player");

    -- Warlock (all specs have pets)
    if (classID == 9) then
        return true;
    end

    -- Hunter: BM and Survival always have pets, MM only with Unbreakable Bond talent
    if (classID == 3) then
        local specIndex = GetSpecialization();
        if (not specIndex) then
            -- No spec selected (low level) - assume no pet requirement
            return false;
        end
        local specID = GetSpecializationInfo(specIndex);
        if (specID == 254) then
            -- Marksmanship: check talent node for Unbreakable Bond
            return HasMMHunterPetTalent();
        end
        -- BM (253) or Survival (255) always have pets
        return true;
    end

    -- Death Knight with Raise Dead (Unholy baseline, talent for other specs)
    if (classID == 6 and IsPlayerSpell(RAISE_DEAD_SPELL_ID)) then
        return true;
    end

    -- Mage with Water Elemental (Frost talent)
    if (classID == 8 and IsSpellKnown(WATER_ELEMENTAL_SPELL_ID)) then
        return true;
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

local function HasGrimoireOfSacrifice()
    local auraInfo = C_UnitAuras.GetPlayerAuraBySpellID(GRIMOIRE_OF_SACRIFICE_SPELL_ID);
    return auraInfo ~= nil;
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

local function StartSoundTimer(state)
    StopSoundTimer();

    local db = getDB();
    if (not db or not db.soundEnabled) then return; end

    -- Check if sound is enabled for this specific state
    if (state == "missing" and not db.soundMissing) then return; end
    if (state == "passive" and not db.soundPassive) then return; end

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
    -- Player is dead/ghost
    if (UnitIsDeadOrGhost("player")) then
        return true;
    end

    -- Not a pet class/spec (e.g., Blood DK, Frost DK, most classes)
    if (not IsPetClass()) then
        return true;
    end

    -- Warlock with Grimoire of Sacrifice active (intentionally no pet)
    if (HasGrimoireOfSacrifice()) then
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

    -- No combat lockdown protection needed - our frame is not protected
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
            StartSoundTimer(state);
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

    -- Talent/spec change events (for MM Hunter pet talent, DK Raise Dead, Mage Water Elemental)
    self.addon:ModuleRegisterEvent(self, "TRAIT_CONFIG_UPDATED", self.OnTalentChanged);
    self.addon:ModuleRegisterEvent(self, "ACTIVE_COMBAT_CONFIG_CHANGED", self.OnTalentChanged);
    self.addon:ModuleRegisterEvent(self, "PLAYER_SPECIALIZATION_CHANGED", self.OnTalentChanged);

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
    -- Deferred re-check: pet bar info may not reflect the new stance immediately
    C_Timer.After(0.1, function()
        if (module.enabled) then
            UpdatePetStatus();
        end
    end);
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
    -- Stop sound when entering combat unless soundInCombat is enabled
    local db = getDB();
    if (not db or not db.soundInCombat) then
        StopSoundTimer();
    end
end

function module:OnCombatEnd()
    -- Re-evaluate warning state when leaving combat
    UpdatePetStatus();
end

function module:OnPlayerAlive()
    UpdatePetStatus();
end

function module:OnTalentChanged()
    UpdatePetStatus();
end

Lantern:RegisterModule(module);
