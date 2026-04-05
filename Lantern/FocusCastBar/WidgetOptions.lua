local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local LanternUX = _G.LanternUX;
local T = LanternUX and LanternUX.Theme;
if (not T) then return; end

local module = Lantern.modules["FocusCastBar"];
if (not module) then return; end
local L = Lantern.L;

local moduleEnabled = Lantern.moduleEnabled;
local moduleToggle = Lantern.moduleToggle;

module.widgetOptions = function()
    local function db()
        if (not Lantern.db) then Lantern.db = {}; end
        if (not Lantern.db.focusCastBar) then Lantern.db.focusCastBar = {}; end
        return Lantern.db.focusCastBar;
    end

    local isDisabled = function()
        return not moduleEnabled("FocusCastBar");
    end

    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true);

    local function getFontValues()
        local fonts = {};
        if (LSM) then
            for _, name in ipairs(LSM:List("font") or {}) do
                fonts[name] = name;
            end
        end
        if (not fonts["Roboto Light"]) then
            fonts["Roboto Light"] = "Roboto Light";
        end
        return fonts;
    end

    local function getSoundValues()
        if (Lantern.utils and Lantern.utils.RegisterMediaSounds) then
            Lantern.utils.RegisterMediaSounds(LSM);
        end
        local sounds = {};
        if (LSM) then
            for _, name in ipairs(LSM:List("sound") or {}) do
                sounds[name] = name;
            end
        end
        if (not sounds["RaidWarning"]) then
            sounds["RaidWarning"] = "RaidWarning";
        end
        return sounds;
    end

    local function onUpdate()
        if (module.UpdateDisplay) then module:UpdateDisplay(); end
    end

    local iconPositionValues = {
        ["LEFT"]   = L["FOCUSCASTBAR_ICON_POSITION_LEFT"],
        ["RIGHT"]  = L["FOCUSCASTBAR_ICON_POSITION_RIGHT"],
        ["TOP"]    = L["FOCUSCASTBAR_ICON_POSITION_TOP"],
        ["BOTTOM"] = L["FOCUSCASTBAR_ICON_POSITION_BOTTOM"],
    };
    local iconPositionSorting = { "LEFT", "RIGHT", "TOP", "BOTTOM" };

    return {
        moduleToggle("FocusCastBar", L["ENABLE"], L["FOCUSCASTBAR_ENABLE_DESC"]),
        {
            type = "toggle",
            label = L["SHARED_PREVIEW"],
            desc = L["FOCUSCASTBAR_PREVIEW_DESC"],
            disabled = isDisabled,
            get = function() return module.IsPreviewActive and module:IsPreviewActive() or false; end,
            set = function(val)
                if (module.SetPreviewMode) then module:SetPreviewMode(val); end
            end,
        },
        {
            type = "group",
            text = L["FOCUSCASTBAR_GROUP_APPEARANCE"],
            expanded = true,
            children = {
                {
                    type = "color",
                    label = L["FOCUSCASTBAR_BAR_READY_COLOR"],
                    desc = L["FOCUSCASTBAR_BAR_READY_COLOR_DESC"],
                    disabled = isDisabled,
                    get = function()
                        local c = db().barReadyColor or { r = 0.18, g = 0.54, b = 0.18 };
                        return c.r, c.g, c.b;
                    end,
                    set = function(r, g, b)
                        db().barReadyColor = { r = r, g = g, b = b };
                        onUpdate();
                    end,
                },
                {
                    type = "color",
                    label = L["FOCUSCASTBAR_BAR_CD_COLOR"],
                    desc = L["FOCUSCASTBAR_BAR_CD_COLOR_DESC"],
                    disabled = isDisabled,
                    get = function()
                        local c = db().barCdColor or { r = 0.70, g = 0.36, b = 0.13 };
                        return c.r, c.g, c.b;
                    end,
                    set = function(r, g, b)
                        db().barCdColor = { r = r, g = g, b = b };
                        onUpdate();
                    end,
                },
                {
                    type = "toggle",
                    label = L["FOCUSCASTBAR_HIGHLIGHT_IMPORTANT"],
                    desc = L["FOCUSCASTBAR_HIGHLIGHT_IMPORTANT_DESC"],
                    disabled = isDisabled,
                    get = function() return db().highlightImportant ~= false; end,
                    set = function(val) db().highlightImportant = val; onUpdate(); end,
                },
                {
                    type = "color",
                    label = L["FOCUSCASTBAR_IMPORTANT_COLOR"],
                    desc = L["FOCUSCASTBAR_IMPORTANT_COLOR_DESC"],
                    disabled = isDisabled,
                    get = function()
                        local c = db().importantColor or { r = 0.0, g = 0.8, b = 0.8 };
                        return c.r, c.g, c.b;
                    end,
                    set = function(r, g, b)
                        db().importantColor = { r = r, g = g, b = b };
                        onUpdate();
                    end,
                },
                {
                    type = "color",
                    label = L["FOCUSCASTBAR_NONINT_COLOR"],
                    desc = L["FOCUSCASTBAR_NONINT_COLOR_DESC"],
                    disabled = isDisabled,
                    get = function()
                        local c = db().nonIntColor or { r = 0.45, g = 0.45, b = 0.45 };
                        return c.r, c.g, c.b;
                    end,
                    set = function(r, g, b)
                        db().nonIntColor = { r = r, g = g, b = b };
                        onUpdate();
                    end,
                },
                {
                    type = "color",
                    label = L["FOCUSCASTBAR_BG_COLOR"],
                    desc = L["FOCUSCASTBAR_BG_COLOR_DESC"],
                    disabled = isDisabled,
                    get = function()
                        local c = db().bgColor or { r = 0.08, g = 0.08, b = 0.08 };
                        return c.r, c.g, c.b;
                    end,
                    set = function(r, g, b)
                        db().bgColor = { r = r, g = g, b = b };
                        onUpdate();
                    end,
                },
                {
                    type = "range",
                    label = L["FOCUSCASTBAR_BG_OPACITY"],
                    desc = L["FOCUSCASTBAR_BG_OPACITY_DESC"],
                    min = 0, max = 100, step = 1, default = 80,
                    disabled = isDisabled,
                    get = function()
                        local alpha = db().bgAlpha;
                        if (alpha == nil) then alpha = 0.8; end
                        return math.floor(alpha * 100 + 0.5);
                    end,
                    set = function(val)
                        db().bgAlpha = val / 100;
                        onUpdate();
                    end,
                },
                {
                    type = "select",
                    label = L["FOCUSCASTBAR_BAR_TEXTURE"],
                    desc = L["FOCUSCASTBAR_BAR_TEXTURE_DESC"],
                    values = function()
                        local textures = {};
                        if (LSM) then
                            for _, name in ipairs(LSM:List("statusbar") or {}) do
                                textures[name] = name;
                            end
                        end
                        return textures;
                    end,
                    disabled = isDisabled,
                    get = function() return db().barTexture or "Blizzard"; end,
                    set = function(val) db().barTexture = val; onUpdate(); end,
                },
            },
        },
        {
            type = "group",
            text = L["FOCUSCASTBAR_GROUP_ICON"],
            children = {
                {
                    type = "toggle",
                    label = L["FOCUSCASTBAR_SHOW_ICON"],
                    desc = L["FOCUSCASTBAR_SHOW_ICON_DESC"],
                    disabled = isDisabled,
                    get = function() return db().showIcon ~= false; end,
                    set = function(val)
                        db().showIcon = val;
                        onUpdate();
                    end,
                },
                {
                    type = "range",
                    label = L["FOCUSCASTBAR_ICON_SIZE"],
                    desc = L["FOCUSCASTBAR_ICON_SIZE_DESC"],
                    min = 16, max = 64, step = 1, default = 24,
                    disabled = isDisabled,
                    get = function() return db().iconSize or 24; end,
                    set = function(val)
                        db().iconSize = val;
                        onUpdate();
                    end,
                },
                {
                    type = "select",
                    label = L["FOCUSCASTBAR_ICON_POSITION"],
                    desc = L["FOCUSCASTBAR_ICON_POSITION_DESC"],
                    values = iconPositionValues,
                    sorting = iconPositionSorting,
                    disabled = isDisabled,
                    get = function() return db().iconPosition or "LEFT"; end,
                    set = function(val)
                        db().iconPosition = val;
                        onUpdate();
                    end,
                },
            },
        },
        {
            type = "group",
            text = L["FOCUSCASTBAR_GROUP_TEXT"],
            children = {
                {
                    type = "toggle",
                    label = L["FOCUSCASTBAR_SHOW_SPELL_NAME"],
                    desc = L["FOCUSCASTBAR_SHOW_SPELL_NAME_DESC"],
                    disabled = isDisabled,
                    get = function() return db().showSpellName ~= false; end,
                    set = function(val)
                        db().showSpellName = val;
                        onUpdate();
                    end,
                },
                {
                    type = "toggle",
                    label = L["FOCUSCASTBAR_SHOW_TIME"],
                    desc = L["FOCUSCASTBAR_SHOW_TIME_DESC"],
                    disabled = isDisabled,
                    get = function() return db().showTimeRemaining ~= false; end,
                    set = function(val)
                        db().showTimeRemaining = val;
                        onUpdate();
                    end,
                },
                {
                    type = "select",
                    label = L["SHARED_FONT"],
                    desc = L["FOCUSCASTBAR_FONT_DESC"],
                    values = getFontValues,
                    disabled = isDisabled,
                    get = function() return db().font or "Roboto Light"; end,
                    set = function(val)
                        db().font = val;
                        onUpdate();
                    end,
                },
                {
                    type = "range",
                    label = L["SHARED_FONT_SIZE"],
                    desc = L["FOCUSCASTBAR_FONT_SIZE_DESC"],
                    min = 8, max = 24, step = 1, default = 12,
                    disabled = isDisabled,
                    get = function() return db().fontSize or 12; end,
                    set = function(val)
                        db().fontSize = val;
                        onUpdate();
                    end,
                },
                {
                    type = "color",
                    label = L["FOCUSCASTBAR_TEXT_COLOR"],
                    desc = L["FOCUSCASTBAR_TEXT_COLOR_DESC"],
                    disabled = isDisabled,
                    get = function()
                        local c = db().textColor or { r = 1, g = 1, b = 1 };
                        return c.r, c.g, c.b;
                    end,
                    set = function(r, g, b)
                        db().textColor = { r = r, g = g, b = b };
                        onUpdate();
                    end,
                },
            },
        },
        {
            type = "group",
            text = L["FOCUSCASTBAR_GROUP_BEHAVIOR"],
            children = {
                {
                    type = "toggle",
                    label = L["FOCUSCASTBAR_SHOW_EMPOWER"],
                    desc = L["FOCUSCASTBAR_SHOW_EMPOWER_DESC"],
                    disabled = isDisabled,
                    get = function() return db().showEmpowerStages ~= false; end,
                    set = function(val)
                        db().showEmpowerStages = val;
                        onUpdate();
                    end,
                },
                {
                    type = "toggle",
                    label = L["FOCUSCASTBAR_HIDE_FRIENDLY"],
                    desc = L["FOCUSCASTBAR_HIDE_FRIENDLY_DESC"],
                    disabled = isDisabled,
                    get = function() return db().hideFriendlyCasts or false; end,
                    set = function(val) db().hideFriendlyCasts = val; end,
                },
                {
                    type = "toggle",
                    label = L["FOCUSCASTBAR_SHOW_SHIELD"],
                    desc = L["FOCUSCASTBAR_SHOW_SHIELD_DESC"],
                    disabled = isDisabled,
                    get = function() return db().showShieldIcon ~= false; end,
                    set = function(val) db().showShieldIcon = val; end,
                },
                {
                    type = "toggle",
                    label = L["FOCUSCASTBAR_COLOR_NONINT"],
                    desc = L["FOCUSCASTBAR_COLOR_NONINT_DESC"],
                    disabled = isDisabled,
                    get = function() return db().colorNonInterrupt ~= false; end,
                    set = function(val) db().colorNonInterrupt = val; end,
                },
                {
                    type = "toggle",
                    label = L["FOCUSCASTBAR_HIDE_ON_CD"],
                    desc = L["FOCUSCASTBAR_HIDE_ON_CD_DESC"],
                    disabled = isDisabled,
                    get = function() return db().hideOnCooldown or false; end,
                    set = function(val) db().hideOnCooldown = val; end,
                },
                {
                    type = "toggle",
                    label = L["FOCUSCASTBAR_SHOW_TICK"],
                    desc = L["FOCUSCASTBAR_SHOW_TICK_DESC"],
                    disabled = isDisabled,
                    get = function() return db().showInterruptTick ~= false; end,
                    set = function(val)
                        db().showInterruptTick = val;
                        onUpdate();
                    end,
                },
                {
                    type = "color",
                    label = L["FOCUSCASTBAR_TICK_COLOR"],
                    desc = L["FOCUSCASTBAR_TICK_COLOR_DESC"],
                    disabled = isDisabled,
                    get = function()
                        local c = db().tickColor or { r = 1, g = 1, b = 1 };
                        return c.r, c.g, c.b;
                    end,
                    set = function(r, g, b)
                        db().tickColor = { r = r, g = g, b = b };
                        onUpdate();
                    end,
                },
            },
        },
        {
            type = "group",
            text = L["FOCUSCASTBAR_GROUP_INSTANCES"],
            children = {
                {
                    type = "toggle",
                    label = L["FOCUSCASTBAR_INSTANCE_PARTY"],
                    disabled = isDisabled,
                    get = function()
                        local t = db().showInInstances;
                        return t and t.party ~= false or true;
                    end,
                    set = function(val)
                        local d = db();
                        if (not d.showInInstances) then d.showInInstances = {}; end
                        d.showInInstances.party = val;
                    end,
                },
                {
                    type = "toggle",
                    label = L["FOCUSCASTBAR_INSTANCE_RAID"],
                    disabled = isDisabled,
                    get = function()
                        local t = db().showInInstances;
                        return t and t.raid ~= false or true;
                    end,
                    set = function(val)
                        local d = db();
                        if (not d.showInInstances) then d.showInInstances = {}; end
                        d.showInInstances.raid = val;
                    end,
                },
                {
                    type = "toggle",
                    label = L["FOCUSCASTBAR_INSTANCE_ARENA"],
                    disabled = isDisabled,
                    get = function()
                        local t = db().showInInstances;
                        return t and t.arena ~= false or true;
                    end,
                    set = function(val)
                        local d = db();
                        if (not d.showInInstances) then d.showInInstances = {}; end
                        d.showInInstances.arena = val;
                    end,
                },
                {
                    type = "toggle",
                    label = L["FOCUSCASTBAR_INSTANCE_PVP"],
                    disabled = isDisabled,
                    get = function()
                        local t = db().showInInstances;
                        return (t and t.pvp) or false;
                    end,
                    set = function(val)
                        local d = db();
                        if (not d.showInInstances) then d.showInInstances = {}; end
                        d.showInInstances.pvp = val;
                    end,
                },
                {
                    type = "toggle",
                    label = L["FOCUSCASTBAR_INSTANCE_SCENARIO"],
                    disabled = isDisabled,
                    get = function()
                        local t = db().showInInstances;
                        return (t and t.scenario) or false;
                    end,
                    set = function(val)
                        local d = db();
                        if (not d.showInInstances) then d.showInInstances = {}; end
                        d.showInInstances.scenario = val;
                    end,
                },
                {
                    type = "toggle",
                    label = L["FOCUSCASTBAR_INSTANCE_NONE"],
                    disabled = isDisabled,
                    get = function()
                        local t = db().showInInstances;
                        return (t and t.none) or false;
                    end,
                    set = function(val)
                        local d = db();
                        if (not d.showInInstances) then d.showInInstances = {}; end
                        d.showInInstances.none = val;
                    end,
                },
            },
        },
        {
            type = "group",
            text = L["SHARED_GROUP_SOUND"],
            children = {
                {
                    type = "toggle",
                    label = L["SHARED_PLAY_SOUND"],
                    desc = L["FOCUSCASTBAR_PLAY_SOUND_DESC"],
                    disabled = isDisabled,
                    get = function() return db().soundEnabled or false; end,
                    set = function(val) db().soundEnabled = val; end,
                },
                {
                    type = "select",
                    label = L["SHARED_SOUND_SELECT"],
                    desc = L["FOCUSCASTBAR_SOUND_SELECT_DESC"],
                    values = getSoundValues,
                    disabled = function() return isDisabled() or not db().soundEnabled; end,
                    get = function() return db().soundName or "RaidWarning"; end,
                    set = function(val) db().soundName = val; end,
                    preview = function(key)
                        if (not LSM) then return; end
                        local sound = LSM:Fetch("sound", key);
                        if (sound) then pcall(PlaySoundFile, sound, "Master"); end
                    end,
                },
            },
        },
        {
            type = "group",
            text = L["SHARED_GROUP_POSITION"],
            children = {
                {
                    type = "toggle",
                    label = L["SHARED_LOCK_POSITION"],
                    desc = L["FOCUSCASTBAR_LOCK_POSITION_DESC"],
                    disabled = isDisabled,
                    get = function() return db().locked ~= false; end,
                    set = function(val)
                        db().locked = val;
                        if (module.UpdateLock) then module:UpdateLock(); end
                    end,
                },
                {
                    type = "execute",
                    label = L["SHARED_RESET_POSITION"],
                    desc = L["FOCUSCASTBAR_RESET_POSITION_DESC"],
                    disabled = isDisabled,
                    func = function()
                        if (module.ResetPosition) then module:ResetPosition(); end
                    end,
                },
            },
        },
    };
end
