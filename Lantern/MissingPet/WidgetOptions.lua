local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local LanternUX = _G.LanternUX;
local T = LanternUX and LanternUX.Theme;
if (not T) then return; end

local module = Lantern.modules["MissingPet"];
if (not module) then return; end
local L = Lantern.L;

local function moduleEnabled(name)
    local m = Lantern.modules and Lantern.modules[name];
    return m and m.enabled;
end

local function moduleToggle(name, label, desc)
    return {
        type = "toggle",
        label = label or L["ENABLE"],
        desc = desc,
        get = function() return moduleEnabled(name); end,
        set = function(val)
            if (val) then
                Lantern:EnableModule(name);
            else
                Lantern:DisableModule(name);
            end
        end,
    };
end

module.widgetOptions = function()
    local DEFAULTS = {
        warningText = "Pet Missing!",
        passiveText = "Pet is PASSIVE!",
        showMissing = true,
        showPassive = true,
        locked = true,
        hideWhenMounted = true,
        hideInRestZone = false,
        dismountDelay = 5,
        animationStyle = "bounce",
        font = "Roboto Light",
        fontSize = 24,
        fontOutline = "OUTLINE",
        missingColor = { r = 1, g = 0.2, b = 0.2 },
        passiveColor = { r = 1, g = 0.6, b = 0 },
        soundEnabled = false,
        soundMissing = true,
        soundPassive = true,
        soundName = "RaidWarning",
        soundRepeat = false,
        soundInterval = 5,
        soundInCombat = false,
    };

    local function mpDB()
        if (not Lantern.db) then Lantern.db = {}; end
        if (not Lantern.db.missingPet) then Lantern.db.missingPet = {}; end
        local db = Lantern.db.missingPet;
        for k, v in pairs(DEFAULTS) do
            if (db[k] == nil) then
                if (type(v) == "table") then
                    db[k] = { r = v.r, g = v.g, b = v.b };
                else
                    db[k] = v;
                end
            end
        end
        return db;
    end

    local function mpModule()
        return Lantern.modules and Lantern.modules.MissingPet;
    end

    local function isDisabled()
        return not moduleEnabled("MissingPet");
    end

    local function refreshWarning()
        local m = mpModule();
        if (m and m.RefreshWarning) then m:RefreshWarning(); end
    end

    local function refreshAnimation()
        local m = mpModule();
        if (m and m.RefreshAnimation) then m:RefreshAnimation(); end
    end

    local function refreshFont()
        local m = mpModule();
        if (m and m.RefreshFont) then m:RefreshFont(); end
    end

    local animationValues = {
        none = L["ANIMATION_NONE"],
        bounce = L["ANIMATION_BOUNCE"],
        pulse = L["ANIMATION_PULSE"],
        fade = L["ANIMATION_FADE"],
        shake = L["ANIMATION_SHAKE"],
        glow = L["ANIMATION_GLOW"],
        heartbeat = L["ANIMATION_HEARTBEAT"],
    };
    local animationSorting = { "none", "bounce", "pulse", "fade", "shake", "glow", "heartbeat" };

    local outlineValues = {
        [""] = L["FONT_OUTLINE_NONE"],
        ["OUTLINE"] = L["FONT_OUTLINE_OUTLINE"],
        ["THICKOUTLINE"] = L["FONT_OUTLINE_THICK"],
        ["MONOCHROME"] = L["FONT_OUTLINE_MONO"],
        ["OUTLINE, MONOCHROME"] = L["FONT_OUTLINE_OUTLINE_MONO"],
    };
    local outlineSorting = { "", "OUTLINE", "THICKOUTLINE", "MONOCHROME", "OUTLINE, MONOCHROME" };

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

    return {
        -- Enable
        moduleToggle("MissingPet", L["ENABLE"], L["MISSINGPET_ENABLE_DESC"]),

        -----------------------------------------------------------------------
        -- Warning Settings
        -----------------------------------------------------------------------
        {
            type = "group",
            text = L["MISSINGPET_GROUP_WARNING"],
            expanded = true,
            children = {
                {
                    type = "toggle",
                    label = L["MISSINGPET_SHOW_MISSING"],
                    desc = L["MISSINGPET_SHOW_MISSING_DESC"],
                    disabled = isDisabled,
                    get = function() return mpDB().showMissing; end,
                    set = function(val) mpDB().showMissing = val; refreshWarning(); end,
                },
                {
                    type = "toggle",
                    label = L["MISSINGPET_SHOW_PASSIVE"],
                    desc = L["MISSINGPET_SHOW_PASSIVE_DESC"],
                    disabled = isDisabled,
                    get = function() return mpDB().showPassive; end,
                    set = function(val) mpDB().showPassive = val; refreshWarning(); end,
                },
                {
                    type = "input",
                    label = L["MISSINGPET_MISSING_TEXT"],
                    desc = L["MISSINGPET_MISSING_TEXT_DESC"],
                    disabled = isDisabled,
                    get = function() return mpDB().warningText or "Pet Missing!"; end,
                    set = function(val) mpDB().warningText = val; refreshWarning(); end,
                },
                {
                    type = "input",
                    label = L["MISSINGPET_PASSIVE_TEXT"],
                    desc = L["MISSINGPET_PASSIVE_TEXT_DESC"],
                    disabled = isDisabled,
                    get = function() return mpDB().passiveText or "Pet is PASSIVE!"; end,
                    set = function(val) mpDB().passiveText = val; refreshWarning(); end,
                },
                {
                    type = "color",
                    label = L["MISSINGPET_MISSING_COLOR"],
                    desc = L["MISSINGPET_MISSING_COLOR_DESC"],
                    disabled = isDisabled,
                    get = function()
                        local c = mpDB().missingColor;
                        return c.r, c.g, c.b;
                    end,
                    set = function(r, g, b)
                        mpDB().missingColor = { r = r, g = g, b = b };
                        refreshWarning();
                    end,
                },
                {
                    type = "color",
                    label = L["MISSINGPET_PASSIVE_COLOR"],
                    desc = L["MISSINGPET_PASSIVE_COLOR_DESC"],
                    disabled = isDisabled,
                    get = function()
                        local c = mpDB().passiveColor;
                        return c.r, c.g, c.b;
                    end,
                    set = function(r, g, b)
                        mpDB().passiveColor = { r = r, g = g, b = b };
                        refreshWarning();
                    end,
                },
                {
                    type = "select",
                    label = L["SHARED_ANIMATION_STYLE"],
                    desc = L["MISSINGPET_ANIMATION_DESC"],
                    values = animationValues,
                    sorting = animationSorting,
                    disabled = isDisabled,
                    get = function() return mpDB().animationStyle or "bounce"; end,
                    set = function(val) mpDB().animationStyle = val; refreshAnimation(); end,
                },
            },
        },

        -----------------------------------------------------------------------
        -- Font Settings
        -----------------------------------------------------------------------
        {
            type = "group",
            text = L["MISSINGPET_GROUP_FONT"],
            children = {
                {
                    type = "select",
                    label = L["SHARED_FONT"],
                    desc = L["MISSINGPET_FONT_DESC"],
                    values = getFontValues,
                    disabled = isDisabled,
                    get = function() return mpDB().font or "Roboto Light"; end,
                    set = function(val) mpDB().font = val; refreshFont(); end,
                },
                {
                    type = "range",
                    label = L["SHARED_FONT_SIZE"],
                    desc = L["MISSINGPET_FONT_SIZE_DESC"],
                    min = 12, max = 72, step = 1, default = 24,
                    disabled = isDisabled,
                    get = function() return mpDB().fontSize or 24; end,
                    set = function(val) mpDB().fontSize = val; refreshFont(); end,
                },
                {
                    type = "select",
                    label = L["SHARED_FONT_OUTLINE"],
                    desc = L["MISSINGPET_FONT_OUTLINE_DESC"],
                    values = outlineValues,
                    sorting = outlineSorting,
                    disabled = isDisabled,
                    get = function() return mpDB().fontOutline or "OUTLINE"; end,
                    set = function(val) mpDB().fontOutline = val; refreshFont(); end,
                },
            },
        },

        -----------------------------------------------------------------------
        -- Position
        -----------------------------------------------------------------------
        {
            type = "group",
            text = L["SHARED_GROUP_POSITION"],
            children = {
                {
                    type = "toggle",
                    label = L["SHARED_LOCK_POSITION"],
                    desc = L["MISSINGPET_LOCK_POSITION_DESC"],
                    disabled = isDisabled,
                    get = function() return mpDB().locked; end,
                    set = function(val)
                        mpDB().locked = val;
                        local m = mpModule();
                        if (m and m.UpdateLock) then m:UpdateLock(); end
                    end,
                },
                {
                    type = "execute",
                    label = L["SHARED_RESET_POSITION"],
                    desc = L["MISSINGPET_RESET_POSITION_DESC"],
                    disabled = isDisabled,
                    func = function()
                        local m = mpModule();
                        if (m and m.ResetPosition) then m:ResetPosition(); end
                    end,
                },
            },
        },

        -----------------------------------------------------------------------
        -- Visibility
        -----------------------------------------------------------------------
        {
            type = "group",
            text = L["MISSINGPET_GROUP_VISIBILITY"],
            children = {
                {
                    type = "toggle",
                    label = L["MISSINGPET_HIDE_MOUNTED"],
                    desc = L["MISSINGPET_HIDE_MOUNTED_DESC"],
                    disabled = isDisabled,
                    get = function() return mpDB().hideWhenMounted; end,
                    set = function(val) mpDB().hideWhenMounted = val; refreshWarning(); end,
                },
                {
                    type = "toggle",
                    label = L["MISSINGPET_HIDE_REST"],
                    desc = L["MISSINGPET_HIDE_REST_DESC"],
                    disabled = isDisabled,
                    get = function() return mpDB().hideInRestZone; end,
                    set = function(val) mpDB().hideInRestZone = val; refreshWarning(); end,
                },
                {
                    type = "range",
                    label = L["MISSINGPET_DISMOUNT_DELAY"],
                    desc = L["MISSINGPET_DISMOUNT_DELAY_DESC"],
                    min = 0, max = 10, step = 0.5, default = 5,
                    disabled = function() return isDisabled() or not mpDB().hideWhenMounted; end,
                    get = function() return mpDB().dismountDelay or 5; end,
                    set = function(val) mpDB().dismountDelay = val; end,
                },
            },
        },

        -----------------------------------------------------------------------
        -- Sound
        -----------------------------------------------------------------------
        {
            type = "group",
            text = L["SHARED_GROUP_SOUND"],
            children = {
                {
                    type = "toggle",
                    label = L["SHARED_PLAY_SOUND"],
                    desc = L["MISSINGPET_PLAY_SOUND_DESC"],
                    disabled = isDisabled,
                    get = function() return mpDB().soundEnabled; end,
                    set = function(val) mpDB().soundEnabled = val; end,
                },
                {
                    type = "toggle",
                    label = L["MISSINGPET_SOUND_MISSING"],
                    desc = L["MISSINGPET_SOUND_MISSING_DESC"],
                    disabled = function() return isDisabled() or not mpDB().soundEnabled; end,
                    get = function() return mpDB().soundMissing; end,
                    set = function(val) mpDB().soundMissing = val; end,
                },
                {
                    type = "toggle",
                    label = L["MISSINGPET_SOUND_PASSIVE"],
                    desc = L["MISSINGPET_SOUND_PASSIVE_DESC"],
                    disabled = function() return isDisabled() or not mpDB().soundEnabled; end,
                    get = function() return mpDB().soundPassive; end,
                    set = function(val) mpDB().soundPassive = val; end,
                },
                {
                    type = "toggle",
                    label = L["MISSINGPET_SOUND_COMBAT"],
                    desc = L["MISSINGPET_SOUND_COMBAT_DESC"],
                    disabled = function() return isDisabled() or not mpDB().soundEnabled; end,
                    get = function() return mpDB().soundInCombat; end,
                    set = function(val) mpDB().soundInCombat = val; end,
                },
                {
                    type = "toggle",
                    label = L["MISSINGPET_SOUND_REPEAT"],
                    desc = L["MISSINGPET_SOUND_REPEAT_DESC"],
                    disabled = function() return isDisabled() or not mpDB().soundEnabled; end,
                    get = function() return mpDB().soundRepeat; end,
                    set = function(val) mpDB().soundRepeat = val; end,
                },
                {
                    type = "select",
                    label = L["SHARED_SOUND_SELECT"],
                    desc = L["MISSINGPET_SOUND_SELECT_DESC"],
                    values = getSoundValues,
                    disabled = function() return isDisabled() or not mpDB().soundEnabled; end,
                    get = function() return mpDB().soundName or "RaidWarning"; end,
                    set = function(val) mpDB().soundName = val; end,
                    preview = function(key)
                        if (not LSM) then return; end
                        local sound = LSM:Fetch("sound", key);
                        if (not sound) then return; end
                        -- Try PlaySoundFile first (handles file paths and numeric file IDs)
                        if (PlaySoundFile) then
                            local ok = pcall(PlaySoundFile, sound, "Master");
                            if (ok) then return; end
                        end
                        -- Fall back to PlaySound for sound kit IDs
                        local soundId = tonumber(sound);
                        if (soundId and PlaySound) then
                            pcall(PlaySound, soundId, "Master");
                        end
                    end,
                },
                {
                    type = "range",
                    label = L["MISSINGPET_REPEAT_INTERVAL"],
                    desc = L["MISSINGPET_REPEAT_INTERVAL_DESC"],
                    min = 1, max = 30, step = 1, default = 5,
                    disabled = function() return isDisabled() or not mpDB().soundEnabled or not mpDB().soundRepeat; end,
                    get = function() return mpDB().soundInterval or 5; end,
                    set = function(val) mpDB().soundInterval = val; end,
                },
            },
        },
    };
end
