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
-- Event Handler
-------------------------------------------------------------------------------

local function OnSpellCastSucceeded(self, unit, castGUID, spellID)
    if (not spellID) then return; end
    if (C_Secrets and C_Secrets.ShouldUnitSpellCastingBeSecret(unit)) then return; end
    if (InCombatLockdown()) then return; end

    local _, instanceType = GetInstanceInfo();
    if (instanceType ~= "party" and instanceType ~= "raid") then return; end

    local info = CONSUMABLE_SPELLS[spellID];
    if (not info) then return; end

    local caster = UnitName(unit);
    if (not caster) then return; end

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

    self.addon:ModuleRegisterEvent(self, "UNIT_SPELLCAST_SUCCEEDED", function(_, event, unit, castGUID, spellID)
        if (not self.enabled) then return; end
        OnSpellCastSucceeded(self, unit, castGUID, spellID);
    end);
end

function module:OnDisable()
    -- Clear active lines
    for i = #activeLines, 1, -1 do
        releaseLine(activeLines[i].fontString);
        table.remove(activeLines, i);
    end
    previewMode = false;
    if (previewTimer) then previewTimer:Cancel(); previewTimer = nil; end
end

Lantern:RegisterModule(module);
