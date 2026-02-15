local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

-- Detection approach (taint laundering, mob interrupt correlation, inspect
-- system) inspired by MythicInterruptTracker by KinderLine.

local utils = Lantern.utils;
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true);

-------------------------------------------------------------------------------
-- Interrupt Spell Database
--
-- Single source of truth organized by class. First entry per class is the
-- default/primary interrupt. INTERRUPT_SPELLS (flat spellID lookup) and
-- DEFAULT_CLASS_KICK are derived automatically.
-------------------------------------------------------------------------------

local CLASS_KICKS = {
    -- Death Knight
    DEATHKNIGHT = {
        { id = 47528,  cd = 15, icon = 237527 },   -- Mind Freeze
    },
    -- Demon Hunter
    DEMONHUNTER = {
        { id = 183752, cd = 15, icon = 1305153 },  -- Disrupt
    },
    -- Druid
    DRUID = {
        { id = 106839, cd = 15, icon = 236946 },   -- Skull Bash (Feral / Guardian)
        { id = 78675,  cd = 60, icon = 236748 },   -- Solar Beam (Balance)
    },
    -- Evoker
    EVOKER = {
        { id = 351338, cd = 40, icon = 4622468 },  -- Quell
    },
    -- Hunter
    HUNTER = {
        { id = 147362, cd = 24, icon = 249170 },   -- Counter Shot (BM / MM)
        { id = 187707, cd = 15, icon = 1376045 },  -- Muzzle (Survival)
    },
    -- Mage
    MAGE = {
        { id = 2139,   cd = 24, icon = 135856 },   -- Counterspell
    },
    -- Monk
    MONK = {
        { id = 116705, cd = 15, icon = 608940 },   -- Spear Hand Strike
    },
    -- Paladin
    PALADIN = {
        { id = 96231,  cd = 15, icon = 523893 },   -- Rebuke
    },
    -- Priest
    PRIEST = {
        { id = 15487,  cd = 45, icon = 458230 },   -- Silence (Shadow only)
    },
    -- Rogue
    ROGUE = {
        { id = 1766,   cd = 15, icon = 132219 },   -- Kick
    },
    -- Shaman
    SHAMAN = {
        { id = 57994,  cd = 12, icon = 136018 },   -- Wind Shear
    },
    -- Warlock
    WARLOCK = {
        { id = 19647,   cd = 24, icon = 136174 },  -- Spell Lock (Felhunter)
        { id = 132409,  cd = 24, icon = 136174 },  -- Spell Lock (Felhunter alt ID)
        { id = 119914,  cd = 30, icon = 132316 },  -- Axe Toss (Felguard)
        { id = 1276467, cd = 25, icon = 136217 },  -- Fel Ravager (Felguard ability)
    },
    -- Warrior
    WARRIOR = {
        { id = 6552,   cd = 15, icon = 132938 },   -- Pummel
    },
};

-- Flat spellID lookup and class defaults (derived from CLASS_KICKS)
local INTERRUPT_SPELLS = {};
local DEFAULT_CLASS_KICK = {};
for class, spells in pairs(CLASS_KICKS) do
    for _, spell in ipairs(spells) do
        INTERRUPT_SPELLS[spell.id] = spell;
    end
    local primary = spells[1];
    DEFAULT_CLASS_KICK[class] = { spellID = primary.id, cd = primary.cd };
end

-- Spec-specific interrupt overrides (specID → override)
local SPEC_OVERRIDES = {
    [255] = { spellID = 187707, cd = 15 },                -- Survival Hunter: Muzzle
    [264] = { spellID = 57994,  cd = 30 },                -- Resto Shaman: Wind Shear at 30s
    [266] = { spellID = 119914, cd = 30, isPet = true },  -- Demo Warlock: Axe Toss (pet)
};

-- Specs that lose their interrupt entirely
local SPECS_WITHOUT_INTERRUPT = {
    [256] = true,  -- Discipline Priest
    [257] = true,  -- Holy Priest
    [105] = true,  -- Restoration Druid
    [65]  = true,  -- Holy Paladin
};

-- Talents that permanently reduce an interrupt's base cooldown
local TALENT_CD_MODIFIERS = {
    [388039] = { affectsSpell = 147362, reduction = 2 },   -- Lone Survivor (Hunter)
    [371016] = { affectsSpell = 351338, reduction = 20 },  -- Imposing Presence (Evoker)
};

-- Talents that reduce cooldown only on a successful interrupt
local TALENT_KICK_BONUSES = {
    [378848] = { reduction = 3 },  -- Coldthirst (DK)
};

-- Spell ID aliases (some abilities fire different IDs in different contexts)
local SPELL_ID_ALIASES = {
    [1276467] = 132409,
};

-- Healer specs that keep their interrupt
local HEALER_HAS_KICK = {
    SHAMAN = true,
};

-------------------------------------------------------------------------------
-- Module Defaults & State
-------------------------------------------------------------------------------

local DEFAULTS = {
    displayMode     = "bar",
    locked          = false,
    barPosition     = nil,
    minimalPosition = nil,
    barWidth        = 220,
    barHeight       = 28,
    barAlpha        = 0.9,
    growUp          = false,
    showSelf        = true,
    sortMode        = "remaining",
    selfOnTop       = false,
    font            = "Friz Quadrata TT",
    fontOutline     = "OUTLINE",
};

local db;

-- Player info
local playerClass, playerName;
local playerKickSpell, playerKickBaseCd;
local playerKickCdEnd = 0;
local playerKickIsPet = false;

-- Party tracking
local trackedPlayers = {};      -- name → { class, spellID, baseCd, cdEnd, lastKickTime, kickBonus }
local excludedPlayers = {};     -- name → true (healers without kicks, etc.)
local recentCasts = {};         -- name → GetTime() (for mob interrupt correlation)

-- Preview
local previewActive = false;
local previewTimer = nil;

-- Inspect
local inspectPending = {};
local inspectInProgress = false;
local inspectCurrentUnit = nil;
local inspectedNames = {};

-- UI references
local barFrame, barTitle;
local compactFrame, compactTitle;
local barPool = {};
local compactPool = {};
local refreshTimer;
local lastJoinBroadcast = 0;

-- Constants
local SOLID_TEXTURE = "Interface\\BUTTONS\\WHITE8X8";
local COMM_PREFIX = "LIT";

-- Forward declarations
local RefreshPartyWatchers, RefreshDisplay;
local IdentifyPlayerKick, BroadcastJoin;
local RegisterPartyByClass, PruneTrackedPlayers;
local DeactivatePreview;

-------------------------------------------------------------------------------
-- Taint Laundering
--
-- Party member spellIDs arrive tainted in UNIT_SPELLCAST_SUCCEEDED.
-- A StatusBar's OnValueChanged callback receives a clean copy from the
-- C++ engine, which strips taint. We use this to recover the real spellID.
-- These frames MUST be created at file scope (clean load-time context).
-------------------------------------------------------------------------------

local _launderResult = nil;
local _launderFrame = CreateFrame("StatusBar");
_launderFrame:SetMinMaxValues(0, 9999999);
_launderFrame:SetScript("OnValueChanged", function(_, val)
    _launderResult = val;
end);

local function LaunderSpellID(taintedID)
    _launderResult = nil;
    _launderFrame:SetValue(0);
    pcall(_launderFrame.SetValue, _launderFrame, taintedID);
    return _launderResult;
end

-- Pre-created watcher frames for party units (must be at file scope)
local _partyWatchers = {};
local _petWatchers = {};
for i = 1, 4 do
    _partyWatchers[i] = CreateFrame("Frame");
    _petWatchers[i] = CreateFrame("Frame");
end

-------------------------------------------------------------------------------
-- Database
-------------------------------------------------------------------------------

local function getDB()
    if (not Lantern.db) then Lantern.db = {}; end
    if (not Lantern.db.interruptTracker) then
        Lantern.db.interruptTracker = {};
    end
    db = Lantern.db.interruptTracker;
    for k, v in pairs(DEFAULTS) do
        if (db[k] == nil) then
            db[k] = v;
        end
    end
    return db;
end

local function GetFontPath(fontName)
    if (LSM) then
        local path = LSM:Fetch("font", fontName);
        if (path) then return path; end
    end
    return "Fonts\\FRIZQT__.TTF";
end

-------------------------------------------------------------------------------
-- Player Kick Identification
--
-- Determines which interrupt spell the current player has available,
-- accounting for spec overrides and spec-specific removal.
-------------------------------------------------------------------------------

IdentifyPlayerKick = function()
    playerKickSpell = nil;
    playerKickIsPet = false;
    playerKickBaseCd = nil;

    local specIndex = GetSpecialization();
    local specID;
    if (specIndex) then
        specID = GetSpecializationInfo(specIndex);
    end

    if (specID and SPECS_WITHOUT_INTERRUPT[specID]) then
        return;
    end

    if (specID and SPEC_OVERRIDES[specID]) then
        local override = SPEC_OVERRIDES[specID];
        playerKickSpell = override.spellID;
        playerKickBaseCd = override.cd;
        playerKickIsPet = override.isPet or false;
        return;
    end

    local candidates = CLASS_KICKS[playerClass];
    if (not candidates) then return; end

    for _, entry in ipairs(candidates) do
        local sid = entry.id;
        if (IsSpellKnown(sid) or IsSpellKnown(sid, true)) then
            playerKickSpell = sid;
            break;
        end
        local ok, result = pcall(IsPlayerSpell, sid);
        if (ok and result) then
            playerKickSpell = sid;
            break;
        end
    end

    if (playerKickSpell and not playerKickBaseCd) then
        local spell = INTERRUPT_SPELLS[playerKickSpell];
        if (spell) then
            playerKickBaseCd = spell.cd;
        end
    end
end;

-------------------------------------------------------------------------------
-- Communication
--
-- Simple addon message protocol. Sends a single JOIN announcement so
-- other Lantern clients can pre-register the player's interrupt info.
-- No per-kick broadcasts — detection is passive via taint laundering.
-------------------------------------------------------------------------------

local function SendMessage(payload)
    if (IsInGroup(LE_PARTY_CATEGORY_INSTANCE)) then
        local ok = pcall(C_ChatInfo.SendAddonMessage, COMM_PREFIX, payload, "INSTANCE_CHAT");
        if (ok) then return; end
    end
    if (IsInGroup(LE_PARTY_CATEGORY_HOME)) then
        local ok = pcall(C_ChatInfo.SendAddonMessage, COMM_PREFIX, payload, "PARTY");
        if (ok) then return; end
    end
end

BroadcastJoin = function()
    if (not playerClass or not playerKickSpell) then return; end
    local now = GetTime();
    if (now - lastJoinBroadcast < 3) then return; end
    lastJoinBroadcast = now;

    -- Try to read real CD from spellbook for accuracy
    if (not playerKickIsPet and IsSpellKnown(playerKickSpell)) then
        local ok, cdInfo = pcall(C_Spell.GetSpellCooldown, playerKickSpell);
        if (ok and cdInfo) then
            local ok2, dur = pcall(function()
                if (cdInfo.duration and cdInfo.duration > 1.5) then
                    return cdInfo.duration;
                end
            end);
            if (ok2 and dur) then
                playerKickBaseCd = tonumber(string.format("%.1f", dur));
            end
        end
    end

    local cd = playerKickBaseCd
        or (INTERRUPT_SPELLS[playerKickSpell] and INTERRUPT_SPELLS[playerKickSpell].cd)
        or 15;
    SendMessage("J:" .. playerClass .. ":" .. playerKickSpell .. ":" .. cd);
end;

local function HandleAddonMessage(event, prefix, message, channel, sender)
    if (prefix ~= COMM_PREFIX) then return; end
    local shortName = Ambiguate(sender, "short");
    if (shortName == playerName) then return; end

    local cmd, arg1, arg2, arg3 = strsplit(":", message);

    if (cmd == "J") then
        local cls = arg1;
        local sid = tonumber(arg2);
        local cd = tonumber(arg3);
        if (not cls or not DEFAULT_CLASS_KICK[cls] or not sid or not INTERRUPT_SPELLS[sid]) then
            return;
        end
        if (not trackedPlayers[shortName]) then
            trackedPlayers[shortName] = {};
        end
        local entry = trackedPlayers[shortName];
        entry.class = cls;
        entry.spellID = sid;
        entry.cdEnd = entry.cdEnd or 0;
        if (cd and cd > 0) then
            entry.baseCd = cd;
        end
        BroadcastJoin();
    end
end

-------------------------------------------------------------------------------
-- Party Kick Detection
--
-- When a party member casts an interrupt, the taint-laundered spellID
-- is matched against our spell registry to record the cooldown.
-------------------------------------------------------------------------------

local function RecordPartyKick(unit, spellID, name)
    if (not name or excludedPlayers[name]) then return; end

    local resolvedID = SPELL_ID_ALIASES[spellID] or spellID;
    local spell = INTERRUPT_SPELLS[resolvedID];
    if (not spell) then return; end

    local now = GetTime();

    if (trackedPlayers[name]) then
        local entry = trackedPlayers[name];
        entry.cdEnd = now + (entry.baseCd or spell.cd);
        entry.lastKickTime = now;
    else
        local ok, _, cls = pcall(UnitClass, unit);
        if (not ok or not cls or not DEFAULT_CLASS_KICK[cls]) then return; end

        local role = UnitGroupRolesAssigned(unit);
        if (role == "HEALER" and not HEALER_HAS_KICK[cls]) then
            excludedPlayers[name] = true;
            return;
        end

        trackedPlayers[name] = {
            class = cls,
            spellID = resolvedID,
            baseCd = spell.cd,
            cdEnd = now + spell.cd,
            lastKickTime = now,
        };
    end
end

RefreshPartyWatchers = function()
    for i = 1, 4 do
        _partyWatchers[i]:UnregisterAllEvents();
        _petWatchers[i]:UnregisterAllEvents();

        local unit = "party" .. i;
        if (UnitExists(unit)) then
            -- Watch party member casts
            _partyWatchers[i]:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", unit);
            _partyWatchers[i]:SetScript("OnEvent", function(_, _, _, _, taintedSpellID)
                local cleanUnit = "party" .. i;
                local name = UnitName(cleanUnit);
                if (name) then
                    recentCasts[name] = GetTime();
                end

                local cleanID = LaunderSpellID(taintedSpellID);
                if (cleanID and INTERRUPT_SPELLS[cleanID]) then
                    RecordPartyKick(cleanUnit, cleanID, name);
                end
            end);

            -- Watch party member pets
            local petUnit = "partypet" .. i;
            if (UnitExists(petUnit)) then
                _petWatchers[i]:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", petUnit);
                _petWatchers[i]:SetScript("OnEvent", function(_, _, _, _, taintedSpellID)
                    local ownerUnit = "party" .. i;
                    local name = UnitName(ownerUnit);
                    if (name) then
                        recentCasts[name] = GetTime();
                    end

                    local cleanID = LaunderSpellID(taintedSpellID);
                    if (cleanID and INTERRUPT_SPELLS[cleanID]) then
                        RecordPartyKick(ownerUnit, cleanID, name);
                    end
                end);
            end
        end
    end
end;

RegisterPartyByClass = function()
    for i = 1, 4 do
        local u = "party" .. i;
        if (UnitExists(u)) then
            local name = UnitName(u);
            local _, cls = UnitClass(u);
            if (name and cls and DEFAULT_CLASS_KICK[cls]
                and not trackedPlayers[name]
                and not excludedPlayers[name]) then
                local role = UnitGroupRolesAssigned(u);
                if (not (role == "HEALER" and not HEALER_HAS_KICK[cls])) then
                    local kick = DEFAULT_CLASS_KICK[cls];
                    trackedPlayers[name] = {
                        class = cls,
                        spellID = kick.spellID,
                        baseCd = kick.cd,
                        cdEnd = 0,
                    };
                end
            end
        end
    end
end;

PruneTrackedPlayers = function()
    if (previewActive) then return; end

    local active = {};
    for i = 1, 4 do
        local u = "party" .. i;
        if (UnitExists(u)) then
            active[UnitName(u)] = true;
        end
    end

    for name in pairs(trackedPlayers) do
        if (not active[name]) then trackedPlayers[name] = nil; end
    end
    for name in pairs(excludedPlayers) do
        if (not active[name]) then
            excludedPlayers[name] = nil;
            inspectedNames[name] = nil;
        end
    end
    for name in pairs(inspectedNames) do
        if (not active[name]) then inspectedNames[name] = nil; end
    end

    BroadcastJoin();
end;

-------------------------------------------------------------------------------
-- Mob Interrupt Correlation
--
-- When an enemy's cast is interrupted, we correlate it with the most
-- recent party member cast (within a 0.5s window) to attribute the kick.
-- This catches interrupts that the taint laundering might miss.
-------------------------------------------------------------------------------

local function CorrelateInterrupt(unit)
    local now = GetTime();
    local closest, closestDelta = nil, 999;

    for name, ts in pairs(recentCasts) do
        local delta = now - ts;
        if (delta > 1.0) then
            recentCasts[name] = nil;
        elseif (delta < closestDelta) then
            closestDelta = delta;
            closest = name;
        end
    end

    if (not closest or closestDelta >= 0.5) then return; end

    if (trackedPlayers[closest]) then
        local entry = trackedPlayers[closest];
        -- Apply on-kick talent bonus if applicable
        if (entry.kickBonus) then
            local adjusted = entry.cdEnd - entry.kickBonus;
            entry.cdEnd = math.max(adjusted, now);
        end
    else
        if (excludedPlayers[closest]) then return; end
        for idx = 1, 4 do
            local u = "party" .. idx;
            if (UnitExists(u) and UnitName(u) == closest) then
                local _, cls = UnitClass(u);
                local role = UnitGroupRolesAssigned(u);
                if (cls and DEFAULT_CLASS_KICK[cls]
                    and not (role == "HEALER" and not HEALER_HAS_KICK[cls])) then
                    local kick = DEFAULT_CLASS_KICK[cls];
                    trackedPlayers[closest] = {
                        class = cls,
                        spellID = kick.spellID,
                        baseCd = kick.cd,
                        cdEnd = now + kick.cd,
                    };
                end
                break;
            end
        end
    end
end

-- Mob interrupt detection frames (file scope for clean context)
local _mobFrame = CreateFrame("Frame");
_mobFrame:SetScript("OnEvent", function(_, _, unit)
    CorrelateInterrupt(unit);
end);

local _npCastFrames = {};
local _npFrame = CreateFrame("Frame");
_npFrame:SetScript("OnEvent", function(_, event, unit)
    if (event == "NAME_PLATE_UNIT_ADDED") then
        if (not _npCastFrames[unit]) then
            _npCastFrames[unit] = CreateFrame("Frame");
        end
        _npCastFrames[unit]:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", unit);
        _npCastFrames[unit]:SetScript("OnEvent", function(_, _, u)
            CorrelateInterrupt(u);
        end);
    elseif (event == "NAME_PLATE_UNIT_REMOVED") then
        if (_npCastFrames[unit]) then
            _npCastFrames[unit]:UnregisterAllEvents();
        end
    end
end);

-------------------------------------------------------------------------------
-- Own Kick Tracking
--
-- The player's own spellIDs are not tainted, so we can look them up directly.
-- Pet spells may still be tainted, so we launder those.
-------------------------------------------------------------------------------

local _selfFrame = CreateFrame("Frame");
_selfFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "pet");
_selfFrame:SetScript("OnEvent", function(_, _, unit, _, spellID)
    if (unit == "pet") then
        local directMatch = INTERRUPT_SPELLS[spellID];
        local cleanID = LaunderSpellID(spellID);
        local launderedMatch = cleanID and INTERRUPT_SPELLS[cleanID];
        local matchedID = (directMatch and spellID) or (launderedMatch and cleanID);

        if (matchedID and playerKickSpell and matchedID == playerKickSpell) then
            local cd = playerKickBaseCd or INTERRUPT_SPELLS[matchedID].cd;
            playerKickCdEnd = GetTime() + cd;
        end
    else
        if (not INTERRUPT_SPELLS[spellID]) then return; end
        if (playerKickSpell and spellID == playerKickSpell) then
            local cd = playerKickBaseCd or INTERRUPT_SPELLS[spellID].cd;
            playerKickCdEnd = GetTime() + cd;
        end
    end
end);

local function CachePlayerCooldown()
    if (not playerKickSpell or playerKickIsPet) then return; end
    if (not IsSpellKnown(playerKickSpell)) then return; end

    local ok, cdInfo = pcall(C_Spell.GetSpellCooldown, playerKickSpell);
    if (not ok or not cdInfo) then return; end
    local ok2, dur = pcall(function()
        if (cdInfo.duration and cdInfo.duration > 1.5) then
            return cdInfo.duration;
        end
    end);
    if (ok2 and dur) then
        playerKickBaseCd = tonumber(string.format("%.1f", dur));
    end
end

-------------------------------------------------------------------------------
-- Inspect System
--
-- After joining a group, we inspect party members one at a time to
-- determine their spec (for overrides) and scan talents for CD modifiers.
-------------------------------------------------------------------------------

local function ApplyInspectResults(unit)
    local name = UnitName(unit);
    if (not name) then return; end

    local entry = trackedPlayers[name];
    if (not entry) then
        inspectedNames[name] = true;
        return;
    end

    -- Check spec for overrides or removal
    local specID = GetInspectSpecialization(unit);
    if (specID and specID > 0) then
        if (SPECS_WITHOUT_INTERRUPT[specID]) then
            trackedPlayers[name] = nil;
            excludedPlayers[name] = true;
            inspectedNames[name] = true;
            return;
        end

        local override = SPEC_OVERRIDES[specID];
        if (override) then
            entry.spellID = override.spellID;
            entry.baseCd = override.cd;
        end
    end

    -- Scan talent tree for CD modifiers
    local configID = -1;
    local ok, configInfo = pcall(C_Traits.GetConfigInfo, configID);
    if (not ok or not configInfo or not configInfo.treeIDs or #configInfo.treeIDs == 0) then
        inspectedNames[name] = true;
        return;
    end

    local ok2, nodeIDs = pcall(C_Traits.GetTreeNodes, configInfo.treeIDs[1]);
    if (not ok2 or not nodeIDs) then
        inspectedNames[name] = true;
        return;
    end

    for _, nodeID in ipairs(nodeIDs) do
        local ok3, nodeInfo = pcall(C_Traits.GetNodeInfo, configID, nodeID);
        if (ok3 and nodeInfo and nodeInfo.activeEntry
            and nodeInfo.activeRank and nodeInfo.activeRank > 0) then
            local entryID = nodeInfo.activeEntry.entryID;
            if (entryID) then
                local ok4, entryInfo = pcall(C_Traits.GetEntryInfo, configID, entryID);
                if (ok4 and entryInfo and entryInfo.definitionID) then
                    local ok5, defInfo = pcall(C_Traits.GetDefinitionInfo, entryInfo.definitionID);
                    if (ok5 and defInfo and defInfo.spellID) then
                        local cdMod = TALENT_CD_MODIFIERS[defInfo.spellID];
                        if (cdMod and cdMod.affectsSpell == entry.spellID) then
                            entry.baseCd = math.max(1, entry.baseCd - cdMod.reduction);
                        end
                        local kickMod = TALENT_KICK_BONUSES[defInfo.spellID];
                        if (kickMod) then
                            entry.kickBonus = kickMod.reduction;
                        end
                    end
                end
            end
        end
    end

    inspectedNames[name] = true;
end

local function ProcessNextInspect()
    if (inspectInProgress) then return; end
    while (#inspectPending > 0) do
        local unit = table.remove(inspectPending, 1);
        if (UnitExists(unit) and UnitIsConnected(unit)) then
            local name = UnitName(unit);
            if (name and not inspectedNames[name]) then
                inspectInProgress = true;
                inspectCurrentUnit = unit;
                NotifyInspect(unit);
                return;
            end
        end
    end
end

local function QueueInspects()
    inspectPending = {};
    for i = 1, 4 do
        local u = "party" .. i;
        if (UnitExists(u)) then
            local name = UnitName(u);
            if (name and not inspectedNames[name]) then
                table.insert(inspectPending, u);
            end
        end
    end
    ProcessNextInspect();
end

-------------------------------------------------------------------------------
-- UI: Bar Mode
-------------------------------------------------------------------------------

local function SaveBarPosition()
    if (not barFrame or not db) then return; end
    local point, _, relativePoint, x, y = barFrame:GetPoint();
    db.barPosition = { point = point, relativePoint = relativePoint, x = x, y = y };
end

local function RestoreBarPosition()
    if (not barFrame or not db or not db.barPosition) then return; end
    local p = db.barPosition;
    barFrame:ClearAllPoints();
    barFrame:SetPoint(p.point or "CENTER", UIParent, p.relativePoint or "CENTER", p.x or 400, p.y or 0);
end

local function BuildBarFrame()
    if (barFrame) then return; end
    getDB();

    barFrame = CreateFrame("Frame", "LanternInterruptTracker", UIParent);
    barFrame:SetSize(db.barWidth, 200);
    barFrame:SetPoint("CENTER", UIParent, "CENTER", 400, 0);
    barFrame:SetFrameStrata("MEDIUM");
    barFrame:SetClampedToScreen(true);
    barFrame:SetMovable(true);
    barFrame:EnableMouse(true);
    barFrame:RegisterForDrag("LeftButton");
    barFrame:SetScript("OnDragStart", function(self)
        if (not db.locked or IsShiftKeyDown()) then
            self:StartMoving();
        end
    end);
    barFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing();
        SaveBarPosition();
    end);
    barFrame:SetAlpha(db.barAlpha);

    barTitle = CreateFrame("Frame", nil, barFrame);
    barTitle:SetHeight(18);
    barTitle:SetPoint("BOTTOMLEFT", barFrame, "TOPLEFT", 0, 2);
    barTitle:SetPoint("BOTTOMRIGHT", barFrame, "TOPRIGHT", 0, 2);
    barTitle:EnableMouse(true);
    barTitle:RegisterForDrag("LeftButton");
    barTitle:SetScript("OnDragStart", function()
        barFrame:StartMoving();
    end);
    barTitle:SetScript("OnDragStop", function()
        barFrame:StopMovingOrSizing();
        SaveBarPosition();
    end);

    local barTitleBg = barTitle:CreateTexture(nil, "BACKGROUND");
    barTitleBg:SetAllPoints();
    barTitleBg:SetTexture(SOLID_TEXTURE);
    barTitleBg:SetVertexColor(0.1, 0.1, 0.1, 0.8);

    local barTitleText = barTitle:CreateFontString(nil, "OVERLAY");
    barTitleText:SetFont(GetFontPath(db.font), 12, db.fontOutline or "OUTLINE");
    barTitleText:SetPoint("CENTER", 0, 0);
    barTitleText:SetText("|cFFe6c619Interrupts (unlocked)|r");
    barTitle.text = barTitleText;

    if (db.locked) then barTitle:Hide(); end

    local bh = math.max(12, db.barHeight);
    local iconSize = bh;
    local barW = math.max(60, db.barWidth - iconSize);
    local nameFontSize = math.max(9, math.floor(bh * 0.45));
    local cdFontSize = math.max(10, math.floor(bh * 0.55));

    for i = 1, 5 do
        local yOff = db.growUp
            and ((i - 1) * (bh + 1))
            or (-((i - 1) * (bh + 1)));

        local row = CreateFrame("Frame", nil, barFrame);
        row:SetSize(iconSize + barW, bh);
        if (db.growUp) then
            row:SetPoint("BOTTOMLEFT", 0, yOff);
        else
            row:SetPoint("TOPLEFT", 0, yOff);
        end

        local ico = row:CreateTexture(nil, "ARTWORK");
        ico:SetSize(iconSize, bh);
        ico:SetPoint("LEFT", 0, 0);
        ico:SetTexCoord(0.08, 0.92, 0.08, 0.92);
        row.icon = ico;

        local barBg = row:CreateTexture(nil, "BACKGROUND");
        barBg:SetPoint("TOPLEFT", iconSize, 0);
        barBg:SetPoint("BOTTOMRIGHT", 0, 0);
        barBg:SetTexture(SOLID_TEXTURE);
        barBg:SetVertexColor(0.15, 0.15, 0.15, 1);
        row.barBg = barBg;

        local sb = CreateFrame("StatusBar", nil, row);
        sb:SetPoint("TOPLEFT", iconSize, 0);
        sb:SetPoint("BOTTOMRIGHT", 0, 0);
        sb:SetStatusBarTexture(SOLID_TEXTURE);
        sb:SetStatusBarColor(1, 1, 1, 0.85);
        sb:SetMinMaxValues(0, 1);
        sb:SetValue(0);
        sb:SetFrameLevel(row:GetFrameLevel() + 1);
        row.cdBar = sb;

        local overlay = CreateFrame("Frame", nil, row);
        overlay:SetPoint("TOPLEFT", iconSize, 0);
        overlay:SetPoint("BOTTOMRIGHT", 0, 0);
        overlay:SetFrameLevel(sb:GetFrameLevel() + 1);
        row.overlay = overlay;

        local nameStr = overlay:CreateFontString(nil, "OVERLAY");
        nameStr:SetFont(GetFontPath(db.font), nameFontSize, db.fontOutline or "OUTLINE");
        nameStr:SetPoint("LEFT", 6, 0);
        nameStr:SetJustifyH("LEFT");
        nameStr:SetWidth(barW - 50);
        nameStr:SetWordWrap(false);
        nameStr:SetShadowOffset(1, -1);
        nameStr:SetShadowColor(0, 0, 0, 1);
        row.nameText = nameStr;

        local cdStr = overlay:CreateFontString(nil, "OVERLAY");
        cdStr:SetFont(GetFontPath(db.font), cdFontSize, db.fontOutline or "OUTLINE");
        cdStr:SetPoint("RIGHT", -6, 0);
        cdStr:SetShadowOffset(1, -1);
        cdStr:SetShadowColor(0, 0, 0, 1);
        row.cdText = cdStr;

        row:Hide();
        barPool[i] = row;
    end

    RestoreBarPosition();
    barFrame:Hide();
end

-------------------------------------------------------------------------------
-- UI: Compact Mode
-------------------------------------------------------------------------------

local function SaveCompactPosition()
    if (not compactFrame or not db) then return; end
    local point, _, relativePoint, x, y = compactFrame:GetPoint();
    db.minimalPosition = { point = point, relativePoint = relativePoint, x = x, y = y };
end

local function RestoreCompactPosition()
    if (not compactFrame or not db or not db.minimalPosition) then return; end
    local p = db.minimalPosition;
    compactFrame:ClearAllPoints();
    compactFrame:SetPoint(p.point or "CENTER", UIParent, p.relativePoint or "CENTER", p.x or 400, p.y or 0);
end

local function BuildCompactFrame()
    if (compactFrame) then return; end
    getDB();

    compactFrame = CreateFrame("Frame", "LanternInterruptTrackerCompact", UIParent);
    compactFrame:SetSize(160, 100);
    compactFrame:SetPoint("CENTER", UIParent, "CENTER", 400, 0);
    compactFrame:SetFrameStrata("MEDIUM");
    compactFrame:SetClampedToScreen(true);
    compactFrame:SetMovable(true);
    compactFrame:EnableMouse(true);
    compactFrame:RegisterForDrag("LeftButton");
    compactFrame:SetScript("OnDragStart", function(self)
        if (not db.locked or IsShiftKeyDown()) then
            self:StartMoving();
        end
    end);
    compactFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing();
        SaveCompactPosition();
    end);
    compactFrame:SetAlpha(db.barAlpha);

    compactTitle = CreateFrame("Frame", nil, compactFrame);
    compactTitle:SetHeight(16);
    compactTitle:SetPoint("BOTTOMLEFT", compactFrame, "TOPLEFT", 0, 2);
    compactTitle:SetPoint("BOTTOMRIGHT", compactFrame, "TOPRIGHT", 0, 2);
    compactTitle:EnableMouse(true);
    compactTitle:RegisterForDrag("LeftButton");
    compactTitle:SetScript("OnDragStart", function()
        compactFrame:StartMoving();
    end);
    compactTitle:SetScript("OnDragStop", function()
        compactFrame:StopMovingOrSizing();
        SaveCompactPosition();
    end);

    local compactTitleBg = compactTitle:CreateTexture(nil, "BACKGROUND");
    compactTitleBg:SetAllPoints();
    compactTitleBg:SetTexture(SOLID_TEXTURE);
    compactTitleBg:SetVertexColor(0.1, 0.1, 0.1, 0.8);

    local compactTitleText = compactTitle:CreateFontString(nil, "OVERLAY");
    compactTitleText:SetFont(GetFontPath(db.font), 11, db.fontOutline or "OUTLINE");
    compactTitleText:SetPoint("CENTER", 0, 0);
    compactTitleText:SetText("|cFFe6c619Interrupts (unlocked)|r");
    compactTitle.text = compactTitleText;

    if (db.locked) then compactTitle:Hide(); end

    local rowH = 18;
    for i = 1, 5 do
        local row = CreateFrame("Frame", nil, compactFrame);
        row:SetSize(160, rowH);
        row:SetPoint("TOPLEFT", 4, -((i - 1) * rowH + 4));

        local ico = row:CreateTexture(nil, "ARTWORK");
        ico:SetSize(16, 16);
        ico:SetPoint("LEFT", 0, 0);
        ico:SetTexCoord(0.08, 0.92, 0.08, 0.92);
        row.icon = ico;

        local nameStr = row:CreateFontString(nil, "OVERLAY");
        nameStr:SetFont(GetFontPath(db.font), 11, db.fontOutline or "OUTLINE");
        nameStr:SetPoint("LEFT", ico, "RIGHT", 4, 0);
        nameStr:SetWidth(80);
        nameStr:SetJustifyH("LEFT");
        nameStr:SetWordWrap(false);
        nameStr:SetShadowOffset(1, -1);
        nameStr:SetShadowColor(0, 0, 0, 1);
        row.nameText = nameStr;

        local statusStr = row:CreateFontString(nil, "OVERLAY");
        statusStr:SetFont(GetFontPath(db.font), 11, db.fontOutline or "OUTLINE");
        statusStr:SetPoint("LEFT", ico, "RIGHT", 88, 0);
        statusStr:SetShadowOffset(1, -1);
        statusStr:SetShadowColor(0, 0, 0, 1);
        row.statusText = statusStr;

        row:Hide();
        compactPool[i] = row;
    end

    RestoreCompactPosition();
    compactFrame:Hide();
end

-------------------------------------------------------------------------------
-- Bar Layout
--
-- Called when bar-related settings change (width, height, growUp, lock,
-- font). Updates dimensions, positions, and fonts of all bar pool rows.
-------------------------------------------------------------------------------

local function RefreshBarLayout()
    if (not barFrame) then return; end
    getDB();

    local fontPath = GetFontPath(db.font);
    local outline = db.fontOutline or "OUTLINE";
    local bh = math.max(12, db.barHeight);
    local iconSize = bh;
    local barW = math.max(60, db.barWidth - iconSize);
    local showTitle = not db.locked;
    local nameFontSize = math.max(9, math.floor(bh * 0.45));
    local cdFontSize = math.max(10, math.floor(bh * 0.55));

    barFrame:SetWidth(db.barWidth);
    barFrame:SetAlpha(db.barAlpha);

    if (barTitle) then
        if (barTitle.text) then barTitle.text:SetFont(fontPath, 12, outline); end
        if (showTitle) then barTitle:Show(); else barTitle:Hide(); end
    end

    for i = 1, 5 do
        local bar = barPool[i];
        if (bar) then
            bar:SetSize(iconSize + barW, bh);
            bar.icon:SetSize(iconSize, bh);

            bar:ClearAllPoints();
            local yOff = db.growUp
                and ((i - 1) * (bh + 1))
                or (-((i - 1) * (bh + 1)));
            if (db.growUp) then
                bar:SetPoint("BOTTOMLEFT", 0, yOff);
            else
                bar:SetPoint("TOPLEFT", 0, yOff);
            end

            bar.barBg:ClearAllPoints();
            bar.barBg:SetPoint("TOPLEFT", iconSize, 0);
            bar.barBg:SetPoint("BOTTOMRIGHT", 0, 0);

            bar.cdBar:ClearAllPoints();
            bar.cdBar:SetPoint("TOPLEFT", iconSize, 0);
            bar.cdBar:SetPoint("BOTTOMRIGHT", 0, 0);

            if (bar.overlay) then
                bar.overlay:ClearAllPoints();
                bar.overlay:SetPoint("TOPLEFT", iconSize, 0);
                bar.overlay:SetPoint("BOTTOMRIGHT", 0, 0);
            end

            bar.nameText:SetWidth(barW - 50);
            bar.nameText:SetFont(fontPath, nameFontSize, outline);
            bar.cdText:SetFont(fontPath, cdFontSize, outline);
        end
    end

    -- Compact frame title + row repositioning
    if (compactFrame) then
        local compactShowTitle = not db.locked;
        local rowH = 18;

        if (compactTitle) then
            if (compactTitle.text) then compactTitle.text:SetFont(fontPath, 11, outline); end
            if (compactShowTitle) then compactTitle:Show(); else compactTitle:Hide(); end
        end

        for i = 1, 5 do
            local row = compactPool[i];
            if (row) then
                row:ClearAllPoints();
                row:SetPoint("TOPLEFT", 4, -((i - 1) * rowH + 4));
                row.nameText:SetFont(fontPath, 11, outline);
                row.statusText:SetFont(fontPath, 11, outline);
            end
        end
    end
end

-------------------------------------------------------------------------------
-- Display Logic
-------------------------------------------------------------------------------

local function CollectSortedEntries()
    getDB();
    local entries = {};
    local now = GetTime();

    -- Self entry
    if (db.showSelf and playerKickSpell and INTERRUPT_SPELLS[playerKickSpell]) then
        local spell = INTERRUPT_SPELLS[playerKickSpell];
        local remaining = 0;

        if (playerKickCdEnd > now) then
            remaining = playerKickCdEnd - now;
            -- Try precise API for own non-pet spells (values may be tainted)
            if (not playerKickIsPet and IsSpellKnown(playerKickSpell)) then
                local ok, cdInfo = pcall(C_Spell.GetSpellCooldown, playerKickSpell);
                if (ok and cdInfo) then
                    local ok2, precise = pcall(function()
                        if (cdInfo.duration and cdInfo.duration > 0 and cdInfo.startTime) then
                            return math.max(0, (cdInfo.startTime + cdInfo.duration) - GetTime());
                        end
                    end);
                    if (ok2 and precise) then
                        remaining = precise;
                    end
                end
            end
        end

        table.insert(entries, {
            name = playerName or "You",
            class = playerClass,
            spellID = playerKickSpell,
            baseCd = playerKickBaseCd or spell.cd,
            remaining = remaining,
            isSelf = true,
        });
    end

    -- Party entries
    for name, info in pairs(trackedPlayers) do
        local remaining = 0;
        if (info.cdEnd > now) then
            remaining = info.cdEnd - now;
        end
        local fallbackCd = info.baseCd
            or (INTERRUPT_SPELLS[info.spellID] and INTERRUPT_SPELLS[info.spellID].cd)
            or 15;
        table.insert(entries, {
            name = name,
            class = info.class,
            spellID = info.spellID,
            baseCd = fallbackCd,
            remaining = remaining,
            isSelf = false,
        });
    end

    -- Self on top (if enabled)
    -- Then ready players first, then by sort mode
    local selfOnTop = db.selfOnTop;
    local sortByBaseCd = (db.sortMode == "basecd");

    table.sort(entries, function(a, b)
        if (selfOnTop) then
            if (a.isSelf ~= b.isSelf) then return a.isSelf; end
        end
        local aReady = (a.remaining <= 0);
        local bReady = (b.remaining <= 0);
        if (aReady ~= bReady) then return aReady; end
        if (sortByBaseCd) then
            return a.baseCd < b.baseCd;
        end
        return a.remaining < b.remaining;
    end);

    return entries;
end

local function RenderBarMode()
    if (not barFrame) then return; end
    getDB();

    local entries = CollectSortedEntries();
    local bh = math.max(12, db.barHeight);

    for i = 1, 5 do
        local bar = barPool[i];
        local entry = entries[i];

        if (entry) then
            bar:Show();

            local spell = INTERRUPT_SPELLS[entry.spellID];
            if (spell) then
                if (entry.isSelf and not playerKickIsPet) then
                    local ok, tex = pcall(C_Spell.GetSpellTexture, entry.spellID);
                    bar.icon:SetTexture((ok and tex) or spell.icon);
                else
                    bar.icon:SetTexture(spell.icon);
                end
            end

            local cr, cg, cb = utils.GetClassColor(entry.class);

            bar.nameText:SetText("|cFFFFFFFF" .. entry.name .. "|r");

            if (entry.remaining > 0.5) then
                bar.cdBar:SetMinMaxValues(0, entry.baseCd);
                bar.cdBar:SetValue(entry.remaining);
                bar.cdBar:SetStatusBarColor(cr, cg, cb, 0.85);
                bar.barBg:SetVertexColor(cr * 0.25, cg * 0.25, cb * 0.25, 1);
                local fmt = entry.remaining < 5 and "%.1f" or "%.0f";
                bar.cdText:SetText(string.format(fmt, entry.remaining));
                bar.cdText:SetTextColor(1, 1, 1);
            else
                bar.cdBar:SetMinMaxValues(0, 1);
                bar.cdBar:SetValue(0);
                bar.barBg:SetVertexColor(cr, cg, cb, 1);
                bar.cdText:SetText("READY");
                bar.cdText:SetTextColor(0.2, 1.0, 0.2);
            end
        else
            bar:Hide();
        end
    end

    local numVisible = math.min(#entries, 5);
    if (numVisible > 0) then
        barFrame:SetHeight(numVisible * (bh + 1) + 2);
    end
end

local function RenderCompactMode()
    if (not compactFrame) then return; end
    getDB();

    local entries = CollectSortedEntries();
    local rowH = 18;

    for i = 1, 5 do
        local row = compactPool[i];
        local entry = entries[i];

        if (entry) then
            row:Show();

            local spell = INTERRUPT_SPELLS[entry.spellID];
            if (spell) then
                if (entry.isSelf and not playerKickIsPet) then
                    local ok, tex = pcall(C_Spell.GetSpellTexture, entry.spellID);
                    row.icon:SetTexture((ok and tex) or spell.icon);
                else
                    row.icon:SetTexture(spell.icon);
                end
            end

            local cr, cg, cb = utils.GetClassColor(entry.class);
            row.nameText:SetText(entry.name);
            row.nameText:SetTextColor(cr, cg, cb);

            if (entry.remaining > 0.5) then
                local fmt = entry.remaining < 5 and "%.1f" or "%.0f";
                row.statusText:SetText(string.format(fmt, entry.remaining));
                row.statusText:SetTextColor(1, 1, 1);
            else
                row.statusText:SetText("READY");
                row.statusText:SetTextColor(0.2, 1.0, 0.2);
            end
        else
            row:Hide();
        end
    end

    local numVisible = math.min(#entries, 5);
    if (numVisible > 0) then
        compactFrame:SetHeight(numVisible * rowH + 8);
    end
end

RefreshDisplay = function()
    getDB();

    -- Auto-disable preview when settings panel closes
    if (previewActive) then
        local panelOpen = false;
        if (SettingsPanel and SettingsPanel:IsShown()) then panelOpen = true; end
        local uxPanel = _G["LanternSettingsPanel"];
        if (uxPanel and uxPanel:IsShown()) then panelOpen = true; end
        if (not panelOpen) then
            DeactivatePreview();
            return;
        end
    end

    if (db.displayMode == "minimal") then
        RenderCompactMode();
    else
        RenderBarMode();
    end
end;

local function ShouldBeVisible()
    if (previewActive) then return true; end
    return IsInGroup() and not IsInRaid();
end

local function UpdateVisibility()
    getDB();
    local show = ShouldBeVisible();

    if (db.displayMode == "minimal") then
        if (barFrame) then barFrame:Hide(); end
        if (show) then
            BuildCompactFrame();
            compactFrame:Show();
        elseif (compactFrame) then
            compactFrame:Hide();
        end
    else
        if (compactFrame) then compactFrame:Hide(); end
        if (show) then
            BuildBarFrame();
            barFrame:Show();
        elseif (barFrame) then
            barFrame:Hide();
        end
    end
end

local function SwitchDisplayMode(mode)
    getDB();
    db.displayMode = mode;
    UpdateVisibility();
end

-------------------------------------------------------------------------------
-- Preview Mode
-------------------------------------------------------------------------------

local PREVIEW_PLAYERS = {
    { name = "Korvas",     class = "DEMONHUNTER", spellID = 183752, baseCd = 15 },
    { name = "Brightwing", class = "DRUID",       spellID = 106839, baseCd = 15 },
    { name = "Drakthul",   class = "DEATHKNIGHT", spellID = 47528,  baseCd = 15 },
    { name = "Zulara",     class = "SHAMAN",      spellID = 57994,  baseCd = 12 },
};

local function ActivatePreview()
    previewActive = true;
    trackedPlayers = {};
    for _, fake in ipairs(PREVIEW_PLAYERS) do
        trackedPlayers[fake.name] = {
            class = fake.class,
            spellID = fake.spellID,
            baseCd = fake.baseCd,
            cdEnd = 0,
        };
    end

    UpdateVisibility();

    if (previewTimer) then previewTimer:Cancel(); end
    previewTimer = C_Timer.NewTicker(2, function()
        if (not previewActive) then
            if (previewTimer) then previewTimer:Cancel(); previewTimer = nil; end
            return;
        end
        local now = GetTime();
        for _, info in pairs(trackedPlayers) do
            if (info.cdEnd < now and math.random() < 0.3) then
                info.cdEnd = now + info.baseCd;
            end
        end
    end);
end

DeactivatePreview = function()
    previewActive = false;
    if (previewTimer) then previewTimer:Cancel(); previewTimer = nil; end
    trackedPlayers = {};
    if (IsInGroup() and not IsInRaid()) then
        RegisterPartyByClass();
    end
    UpdateVisibility();
end

-------------------------------------------------------------------------------
-- Module Definition
-------------------------------------------------------------------------------

local module = Lantern:NewModule("InterruptTracker", {
    title = "Interrupt Tracker",
    desc = "Tracks party member interrupt cooldowns in non-raid groups.",
    skipOptions = true,
    defaultEnabled = false,
});

function module:OnInit()
    getDB();
end

function module:OnEnable()
    getDB();

    local _, cls = UnitClass("player");
    playerClass = cls;
    playerName = UnitName("player");

    C_ChatInfo.RegisterAddonMessagePrefix(COMM_PREFIX);
    IdentifyPlayerKick();

    self.addon:ModuleRegisterEvent(self, "GROUP_ROSTER_UPDATE", self.OnGroupChanged);
    self.addon:ModuleRegisterEvent(self, "PLAYER_ENTERING_WORLD", self.OnZoneTransition);
    self.addon:ModuleRegisterEvent(self, "SPELL_UPDATE_COOLDOWN", self.OnCooldownUpdate);
    self.addon:ModuleRegisterEvent(self, "SPELLS_CHANGED", self.OnSpellbookChanged);
    self.addon:ModuleRegisterEvent(self, "PLAYER_REGEN_ENABLED", self.OnCombatEnd);
    self.addon:ModuleRegisterEvent(self, "PLAYER_SPECIALIZATION_CHANGED", self.OnSpecChanged);
    self.addon:ModuleRegisterEvent(self, "UNIT_PET", self.OnPetChanged);
    self.addon:ModuleRegisterEvent(self, "ROLE_CHANGED_INFORM", self.OnRoleChanged);
    self.addon:ModuleRegisterEvent(self, "CHAT_MSG_ADDON", HandleAddonMessage);
    self.addon:ModuleRegisterEvent(self, "INSPECT_READY", self.OnInspectReady);

    _mobFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "target", "focus");
    _npFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED");
    _npFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED");

    BuildBarFrame();
    BuildCompactFrame();
    RefreshPartyWatchers();
    RegisterPartyByClass();

    if (refreshTimer) then refreshTimer:Cancel(); end
    refreshTimer = C_Timer.NewTicker(0.1, RefreshDisplay);

    if (LSM and LSM.RegisterCallback) then
        LSM.RegisterCallback(module, "LibSharedMedia_Registered", function(_, mediaType)
            if (mediaType == "font") then module:RefreshFont(); end
        end);
        LSM.RegisterCallback(module, "LibSharedMedia_SetGlobal", function(_, mediaType)
            if (mediaType == "font") then module:RefreshFont(); end
        end);
    end

    UpdateVisibility();

    C_Timer.After(2, function()
        if (module.enabled) then
            BroadcastJoin();
            QueueInspects();
        end
    end);
end

function module:OnDisable()
    if (LSM and LSM.UnregisterCallback) then
        LSM.UnregisterCallback(module, "LibSharedMedia_Registered");
        LSM.UnregisterCallback(module, "LibSharedMedia_SetGlobal");
    end

    if (refreshTimer) then refreshTimer:Cancel(); refreshTimer = nil; end

    if (previewActive) then
        previewActive = false;
        if (previewTimer) then previewTimer:Cancel(); previewTimer = nil; end
    end

    for i = 1, 4 do
        _partyWatchers[i]:UnregisterAllEvents();
        _petWatchers[i]:UnregisterAllEvents();
    end

    _mobFrame:UnregisterAllEvents();
    _npFrame:UnregisterAllEvents();
    for _, f in pairs(_npCastFrames) do
        f:UnregisterAllEvents();
    end

    if (barFrame) then barFrame:Hide(); end
    if (compactFrame) then compactFrame:Hide(); end

    trackedPlayers = {};
    excludedPlayers = {};
    inspectedNames = {};
    inspectPending = {};
    inspectInProgress = false;
    recentCasts = {};
end

-------------------------------------------------------------------------------
-- Event Handlers
-------------------------------------------------------------------------------

function module:OnGroupChanged()
    PruneTrackedPlayers();
    RefreshPartyWatchers();
    RegisterPartyByClass();
    UpdateVisibility();
    C_Timer.After(1, function()
        if (module.enabled) then QueueInspects(); end
    end);
end

function module:OnZoneTransition()
    C_ChatInfo.RegisterAddonMessagePrefix(COMM_PREFIX);
    RefreshPartyWatchers();
    RegisterPartyByClass();
    UpdateVisibility();
    C_Timer.After(1, function()
        if (module.enabled) then RegisterPartyByClass(); end
    end);
    C_Timer.After(2, function()
        if (module.enabled) then QueueInspects(); end
    end);
    C_Timer.After(3, function()
        if (module.enabled) then
            IdentifyPlayerKick();
            BroadcastJoin();
            RegisterPartyByClass();
        end
    end);
end

function module:OnCooldownUpdate()
    CachePlayerCooldown();
end

function module:OnSpellbookChanged()
    IdentifyPlayerKick();
    BroadcastJoin();
end

function module:OnCombatEnd()
    CachePlayerCooldown();
end

function module:OnSpecChanged(event, changedUnit)
    if (changedUnit == "player") then
        IdentifyPlayerKick();
        BroadcastJoin();
        return;
    end
    if (changedUnit) then
        local name = UnitName(changedUnit);
        if (name) then
            inspectedNames[name] = nil;
            excludedPlayers[name] = nil;
            local _, cls = UnitClass(changedUnit);
            if (cls and DEFAULT_CLASS_KICK[cls]) then
                local kick = DEFAULT_CLASS_KICK[cls];
                trackedPlayers[name] = {
                    class = cls,
                    spellID = kick.spellID,
                    baseCd = kick.cd,
                    cdEnd = 0,
                };
            end
            C_Timer.After(1, function()
                if (module.enabled) then QueueInspects(); end
            end);
        end
    end
end

function module:OnPetChanged()
    RefreshPartyWatchers();
end

function module:OnRoleChanged()
    for i = 1, 4 do
        local u = "party" .. i;
        if (UnitExists(u)) then
            local name = UnitName(u);
            local _, cls = UnitClass(u);
            local role = UnitGroupRolesAssigned(u);
            if (name and role == "HEALER" and not HEALER_HAS_KICK[cls] and trackedPlayers[name]) then
                trackedPlayers[name] = nil;
                excludedPlayers[name] = true;
            end
        end
    end
end

function module:OnInspectReady()
    if (inspectInProgress and inspectCurrentUnit) then
        pcall(ApplyInspectResults, inspectCurrentUnit);
        ClearInspectPlayer();
        inspectInProgress = false;
        inspectCurrentUnit = nil;
        C_Timer.After(0.5, ProcessNextInspect);
    end
end

-------------------------------------------------------------------------------
-- Public API (for Options)
-------------------------------------------------------------------------------

function module:SetPreviewMode(enabled)
    if (enabled) then
        ActivatePreview();
    else
        DeactivatePreview();
    end
end

function module:IsPreviewActive()
    return previewActive;
end

function module:SetDisplayMode(mode)
    SwitchDisplayMode(mode);
end

function module:ResetBarPosition()
    if (barFrame) then
        barFrame:ClearAllPoints();
        barFrame:SetPoint("CENTER", UIParent, "CENTER", 400, 0);
        db.barPosition = nil;
    end
end

function module:ResetCompactPosition()
    if (compactFrame) then
        compactFrame:ClearAllPoints();
        compactFrame:SetPoint("CENTER", UIParent, "CENTER", 400, 0);
        db.minimalPosition = nil;
    end
end

function module:RefreshFont()
    RefreshBarLayout();

    getDB();
    local fontPath = GetFontPath(db.font);
    local outline = db.fontOutline or "OUTLINE";

    for i = 1, 5 do
        if (compactPool[i]) then
            if (compactPool[i].nameText) then compactPool[i].nameText:SetFont(fontPath, 11, outline); end
            if (compactPool[i].statusText) then compactPool[i].statusText:SetFont(fontPath, 11, outline); end
        end
    end
end

function module:RefreshDisplay()
    getDB();
    RefreshBarLayout();
    UpdateVisibility();
end

Lantern:RegisterModule(module);
