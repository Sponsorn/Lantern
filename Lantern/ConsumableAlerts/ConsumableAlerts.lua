local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end
local L = Lantern.L;

local UX = Lantern.UX;
local GetFontPath = Lantern.utils.GetFontPath;
local SafeSetFont = Lantern.utils.SafeSetFont;

local module = Lantern:NewModule("ConsumableAlerts", {
    title = L["CONSUMABLEALERTS_TITLE"],
    desc = L["CONSUMABLEALERTS_DESC"],
    defaultEnabled = false,
    skipOptions = true,
});

-------------------------------------------------------------------------------
-- Spell Table
-------------------------------------------------------------------------------

local CONSUMABLE_SPELLS = {
    -- Feasts
    [1259656] = { label = "Blooming Feast",                category = "feast" },
    [1259657] = { label = "Quel'dorei Medley",             category = "feast" },
    [1259658] = { label = "Harandar Celebration",           category = "feast" },
    [1259659] = { label = "Silvermoon Parade",              category = "feast" },
    [1278909] = { label = "Hearty Blooming Feast",          category = "feast" },
    [1278915] = { label = "Hearty Quel'dorei Medley",       category = "feast" },
    [1278929] = { label = "Hearty Harandar Celebration",    category = "feast" },
    [1278895] = { label = "Hearty Silvermoon Parade",       category = "feast" },
    -- Cauldrons
    [1240019] = { label = "Cauldron of Sin'dorei Flasks",   category = "cauldron" },
    [1240225] = { label = "Voidlight Potion Cauldron",      category = "cauldron" },
    -- Warlock
    [29893]   = { label = "Soulwell",                       category = "warlock" },
    -- Repair
    [199109]  = { label = "Auto-Hammer",                    category = "repair" },
    [67826]   = { label = "Jeeves",                         category = "repair" },
};

local DEFAULTS = {
    font = "Roboto Semi Bold",
    fontSize = 18,
    fontOutline = "OUTLINE",
    color = { r = 1, g = 1, b = 1 },
    fadeDuration = 4,
    soundEnabled = false,
    soundName = "RaidWarning",
    locked = true,
    pos = nil,
    suppress = {
        combat   = true,
        feast    = false,
        feastMinMinutes = 10,
        warlock  = false,
        warlockMinStones = 3,
        repair   = false,
        repairMinDurability = 90,
    },
};

-------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------

local container;         -- anchor frame (invisible, draggable)
local activeLines = {};  -- { fontString, startTime, duration }
local pool = {};         -- recycled FontStrings
local previewMode = false;
local previewTimer = nil;

local DEFAULT_FONT = "Roboto Semi Bold";

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function ensureDB(self)
    self.db = Lantern.utils.InitModuleDB(self.addon, "consumableAlerts", DEFAULTS);
end

local function getFontPath(db)
    return GetFontPath(db.font or DEFAULT_FONT);
end

-------------------------------------------------------------------------------
-- Notification Pool
-------------------------------------------------------------------------------

local function acquireLine(db)
    local fs = table.remove(pool);
    if (not fs) then
        fs = container:CreateFontString(nil, "OVERLAY");
        fs:SetShadowOffset(1, -1);
        fs:SetShadowColor(0, 0, 0, 0.8);
    end
    -- Always set font before any SetText call
    local d = db or DEFAULTS;
    SafeSetFont(fs, getFontPath(d), d.fontSize or DEFAULTS.fontSize, d.fontOutline or DEFAULTS.fontOutline);
    local r, g, b = d.color.r, d.color.g, d.color.b;
    fs:SetTextColor(r, g, b, 1);
    fs:SetAlpha(1);
    fs:Show();
    return fs;
end

local function releaseLine(fs)
    fs:Hide();
    fs:SetText("");
    table.insert(pool, fs);
end

local function layoutLines(db)
    local fontPath = getFontPath(db);
    local fontSize = db.fontSize or DEFAULTS.fontSize;
    local outline = db.fontOutline or DEFAULTS.fontOutline;
    local r, g, b = db.color.r, db.color.g, db.color.b;
    local spacing = fontSize + 4;

    for i, entry in ipairs(activeLines) do
        local fs = entry.fontString;
        SafeSetFont(fs, fontPath, fontSize, outline);
        fs:SetTextColor(r, g, b, 1);
        fs:ClearAllPoints();
        fs:SetPoint("TOP", container, "TOP", 0, -(i - 1) * spacing);
    end
end

-------------------------------------------------------------------------------
-- Frame Creation
-------------------------------------------------------------------------------

local function createFrame(self)
    if (container) then return; end

    container = CreateFrame("Frame", "Lantern_ConsumableAlerts", UIParent, "BackdropTemplate");
    container:SetSize(400, 1); -- width for text, height grows with content
    container:SetPoint("TOP", UIParent, "TOP", 0, -120);
    container:SetFrameStrata("HIGH");

    if (UX and UX.MakeDraggable) then
        UX.MakeDraggable(container, {
            getPos    = function() return self.db and self.db.pos; end,
            setPos    = function(pos) if (self.db) then self.db.pos = pos; end end,
            getLocked = function() return self.db and self.db.locked; end,
            setLocked = function(val) if (self.db) then self.db.locked = val; end end,
            defaultPoint = { "TOP", UIParent, "TOP", 0, -120 },
        });
    end

    container:SetScript("OnUpdate", function(_, elapsed)
        if (#activeLines == 0) then return; end

        local db = self.db or DEFAULTS;
        local now = GetTime();
        local changed = false;

        for i = #activeLines, 1, -1 do
            local entry = activeLines[i];
            local age = now - entry.startTime;
            local dur = entry.duration;

            if (age >= dur) then
                releaseLine(entry.fontString);
                table.remove(activeLines, i);
                changed = true;
            else
                -- Hold for first 60%, then fade
                local holdTime = dur * 0.6;
                if (age <= holdTime) then
                    entry.fontString:SetAlpha(1);
                else
                    local fadeProgress = (age - holdTime) / (dur - holdTime);
                    entry.fontString:SetAlpha(1 - fadeProgress);
                end
            end
        end

        if (changed) then
            layoutLines(db);
        end
    end);
end

-------------------------------------------------------------------------------
-- Public: Push Notification
-------------------------------------------------------------------------------

local function pushNotification(self, text)
    if (not container) then createFrame(self); end
    local db = self.db or DEFAULTS;

    local fs = acquireLine(db);
    fs:SetText(text);

    table.insert(activeLines, {
        fontString = fs,
        startTime  = GetTime(),
        duration   = db.fadeDuration or DEFAULTS.fadeDuration,
    });

    layoutLines(db);

    -- Sound on first notification only (if none are active yet)
    if (#activeLines == 1 and db.soundEnabled) then
        local media = LibStub and LibStub("LibSharedMedia-3.0", true);
        if (media) then
            local sound = media:Fetch("sound", db.soundName or "RaidWarning");
            if (sound) then pcall(PlaySoundFile, sound, "Master"); end
        end
    end
end

-------------------------------------------------------------------------------
-- Suppression
-------------------------------------------------------------------------------

local function shouldSuppress(db, category)
    local s = db.suppress;
    if (not s) then return false; end

    if (s.combat and C_InstanceEncounter and C_InstanceEncounter.IsEncounterInProgress()) then
        return true;
    end

    if (category == "feast" and s.feast) then
        for i = 1, 40 do
            local aura = C_UnitAuras.GetBuffDataByIndex("player", i);
            if (not aura) then break; end
            if (not issecretvalue(aura.name) and aura.name == "Well Fed" and aura.expirationTime) then
                local remaining = aura.expirationTime - GetTime();
                if (remaining > (s.feastMinMinutes or 10) * 60) then
                    return true;
                end
            end
        end
    elseif (category == "warlock" and s.warlock) then
        local count = C_Item.GetItemCount(5512, false, true); -- Healthstone
        if (count >= (s.warlockMinStones or 3)) then
            return true;
        end
    elseif (category == "repair" and s.repair) then
        local minDurability = 1;
        for i = 1, 18 do
            local cur, mx = GetInventoryItemDurability(i);
            if (cur and mx and mx > 0) then
                minDurability = min(minDurability, cur / mx);
            end
        end
        if (minDurability >= (s.repairMinDurability or 90) / 100) then
            return true;
        end
    end

    return false;
end

-------------------------------------------------------------------------------
-- Addon Communication
-------------------------------------------------------------------------------

local COMM_PREFIX = "LanternCA";
local COMM_VERSION = 1;

local function broadcastConsumable(spellID)
    if (not IsInGroup()) then return; end
    local channel = IsInRaid() and "RAID" or "PARTY";
    C_ChatInfo.SendAddonMessage(COMM_PREFIX, tostring(COMM_VERSION) .. ":" .. tostring(spellID), channel);
end

-------------------------------------------------------------------------------
-- Event Handlers
-------------------------------------------------------------------------------

local function OnSpellCastSucceeded(self, unit, castGUID, spellID)
    if (not spellID) then return; end
    if (unit ~= "player") then return; end

    local info = CONSUMABLE_SPELLS[spellID];
    if (not info) then return; end
    if (not IsInGroup()) then return; end

    broadcastConsumable(spellID);
end

local function OnAddonMessage(self, prefix, message, channel, sender)
    if (prefix ~= COMM_PREFIX) then return; end

    -- Parse message: "version:spellID"
    local version, spellIDStr = strsplit(":", message, 2);
    if (not version or not spellIDStr) then return; end
    if (tonumber(version) ~= COMM_VERSION) then return; end

    local spellID = tonumber(spellIDStr);
    if (not spellID) then return; end

    local info = CONSUMABLE_SPELLS[spellID];
    if (not info) then return; end

    -- Strip realm from sender name for display
    local caster = Ambiguate(sender, "short");

    local db = self.db or DEFAULTS;
    if (shouldSuppress(db, info.category)) then return; end

    pushNotification(self, string.format(L["CONSUMABLEALERTS_PLACED"], caster, info.label));
end

-------------------------------------------------------------------------------
-- Preview Mode
-------------------------------------------------------------------------------

local PREVIEW_LINES = {
    "Playername placed Hearty Harandar Celebration",
    "Othername placed Cauldron of Sin'dorei Flasks",
};

function module:SetPreviewMode(enabled)
    previewMode = enabled;
    if (previewTimer) then previewTimer:Cancel(); previewTimer = nil; end

    if (enabled) then
        if (not container) then createFrame(self); end
        ensureDB(self);

        -- Clear existing lines
        for i = #activeLines, 1, -1 do
            releaseLine(activeLines[i].fontString);
            table.remove(activeLines, i);
        end

        -- Push preview lines
        for _, text in ipairs(PREVIEW_LINES) do
            local fs = acquireLine(self.db);
            fs:SetText(text);
            table.insert(activeLines, {
                fontString = fs,
                startTime  = GetTime(),
                duration   = 999, -- don't auto-fade during preview
            });
        end
        layoutLines(self.db);

        -- Auto-disable when settings panel closes
        previewTimer = C_Timer.NewTicker(0.5, function()
            if (not previewMode) then return; end
            local panel = Lantern._uxPanel;
            if (panel and panel._frame and not panel._frame:IsShown()) then
                module:SetPreviewMode(false);
            end
        end);
    else
        for i = #activeLines, 1, -1 do
            releaseLine(activeLines[i].fontString);
            table.remove(activeLines, i);
        end
    end
end

function module:IsPreviewActive()
    return previewMode;
end

-------------------------------------------------------------------------------
-- Exported Methods (called from WidgetOptions.lua)
-------------------------------------------------------------------------------

function module:RefreshFont()
    if (not container or #activeLines == 0) then return; end
    ensureDB(self);
    layoutLines(self.db);
end

function module:GetFrame()
    return container;
end

function module:UpdateLock()
    if (not container) then return; end
    container:UpdateLock();
end

function module:ResetPosition()
    if (not container) then return; end
    container:ResetPosition();
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
    container:RestorePosition();
    container:UpdateLock();

    if (self.db and self.db.anchorTo and self.db.anchorTo ~= "none") then
        Lantern:ApplyAnchorBinding({
            frame = container,
            getAnchorId = function() return self.db.anchorTo or "none"; end,
            setAnchorId = function(id) self.db.anchorTo = id; end,
            getOffsetX = function() return self.db.anchorOffsetX or 0; end,
            getOffsetY = function() return self.db.anchorOffsetY or 0; end,
        });
    end

    -- Register addon message prefix (safe to call multiple times)
    C_ChatInfo.RegisterAddonMessagePrefix(COMM_PREFIX);

    -- Watch only our own casts via RegisterUnitEvent, then broadcast to group
    if (not self._unitEventFrame) then
        self._unitEventFrame = CreateFrame("Frame", "Lantern_ConsumableAlerts_UnitEvents");
        self._unitEventFrame:SetScript("OnEvent", function(_, event, unit, castGUID, spellID)
            if (not self.enabled) then return; end
            OnSpellCastSucceeded(self, unit, castGUID, spellID);
        end);
    end
    self._unitEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player");

    -- Listen for broadcasts from other group members
    self.addon:ModuleRegisterEvent(self, "CHAT_MSG_ADDON", function(_, event, prefix, message, channel, sender)
        if (not self.enabled) then return; end
        OnAddonMessage(self, prefix, message, channel, sender);
    end);
end

function module:OnDisable()
    -- Unregister unit event frame
    if (self._unitEventFrame) then
        self._unitEventFrame:UnregisterAllEvents();
    end
    -- Clear active lines
    for i = #activeLines, 1, -1 do
        releaseLine(activeLines[i].fontString);
        table.remove(activeLines, i);
    end
    previewMode = false;
    if (previewTimer) then previewTimer:Cancel(); previewTimer = nil; end
end

Lantern:RegisterModule(module);
