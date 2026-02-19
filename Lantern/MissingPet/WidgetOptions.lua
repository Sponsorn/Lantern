local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local LanternUX = _G.LanternUX;
local T = LanternUX and LanternUX.Theme;
if (not T) then return; end

local module = Lantern.modules["MissingPet"];
if (not module) then return; end

local function moduleEnabled(name)
    local m = Lantern.modules and Lantern.modules[name];
    return m and m.enabled;
end

local function moduleToggle(name, label, desc)
    return {
        type = "toggle",
        label = label or "Enable",
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
        font = "Friz Quadrata TT",
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
        none = "None (static)",
        bounce = "Bounce",
        pulse = "Pulse",
        fade = "Fade",
        shake = "Shake",
        glow = "Glow",
        heartbeat = "Heartbeat",
    };
    local animationSorting = { "none", "bounce", "pulse", "fade", "shake", "glow", "heartbeat" };

    local outlineValues = {
        [""] = "None",
        ["OUTLINE"] = "Outline",
        ["THICKOUTLINE"] = "Thick Outline",
        ["MONOCHROME"] = "Monochrome",
        ["OUTLINE, MONOCHROME"] = "Outline + Mono",
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
        if (not fonts["Friz Quadrata TT"]) then
            fonts["Friz Quadrata TT"] = "Friz Quadrata TT";
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
        moduleToggle("MissingPet", "Enable", "Enable or disable the Missing Pet warning."),

        -----------------------------------------------------------------------
        -- Warning Settings
        -----------------------------------------------------------------------
        {
            type = "group",
            text = "Warning Settings",
            expanded = true,
            children = {
                {
                    type = "toggle",
                    label = "Show Missing Warning",
                    desc = "Display a warning when your pet is dismissed or dead.",
                    disabled = isDisabled,
                    get = function() return mpDB().showMissing; end,
                    set = function(val) mpDB().showMissing = val; refreshWarning(); end,
                },
                {
                    type = "toggle",
                    label = "Show Passive Warning",
                    desc = "Display a warning when your pet is set to passive mode.",
                    disabled = isDisabled,
                    get = function() return mpDB().showPassive; end,
                    set = function(val) mpDB().showPassive = val; refreshWarning(); end,
                },
                {
                    type = "input",
                    label = "Missing Text",
                    desc = "Text to display when your pet is missing.",
                    disabled = isDisabled,
                    get = function() return mpDB().warningText or "Pet Missing!"; end,
                    set = function(val) mpDB().warningText = val; refreshWarning(); end,
                },
                {
                    type = "input",
                    label = "Passive Text",
                    desc = "Text to display when your pet is set to passive.",
                    disabled = isDisabled,
                    get = function() return mpDB().passiveText or "Pet is PASSIVE!"; end,
                    set = function(val) mpDB().passiveText = val; refreshWarning(); end,
                },
                {
                    type = "color",
                    label = "Missing Color",
                    desc = "Color for the missing pet warning text.",
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
                    label = "Passive Color",
                    desc = "Color for the passive pet warning text.",
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
                    label = "Animation Style",
                    desc = "Choose how the warning text animates.",
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
            text = "Font Settings",
            children = {
                {
                    type = "select",
                    label = "Font",
                    desc = "Select the font for the warning text.",
                    values = getFontValues,
                    disabled = isDisabled,
                    get = function() return mpDB().font or "Friz Quadrata TT"; end,
                    set = function(val) mpDB().font = val; refreshFont(); end,
                },
                {
                    type = "range",
                    label = "Font Size",
                    desc = "Size of the warning text.",
                    min = 12, max = 72, step = 1,
                    disabled = isDisabled,
                    get = function() return mpDB().fontSize or 24; end,
                    set = function(val) mpDB().fontSize = val; refreshFont(); end,
                },
                {
                    type = "select",
                    label = "Font Outline",
                    desc = "Outline style for the warning text.",
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
            text = "Position",
            children = {
                {
                    type = "toggle",
                    label = "Lock Position",
                    desc = "When locked, the warning cannot be moved. Hold Shift to move even when locked.",
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
                    label = "Reset Position",
                    desc = "Reset the warning frame position to the center of the screen.",
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
            text = "Visibility",
            children = {
                {
                    type = "toggle",
                    label = "Hide When Mounted",
                    desc = "Hide the warning while mounted, on a taxi, or in a vehicle.",
                    disabled = isDisabled,
                    get = function() return mpDB().hideWhenMounted; end,
                    set = function(val) mpDB().hideWhenMounted = val; refreshWarning(); end,
                },
                {
                    type = "toggle",
                    label = "Hide In Rest Zones",
                    desc = "Hide the warning while in a rest zone (cities and inns).",
                    disabled = isDisabled,
                    get = function() return mpDB().hideInRestZone; end,
                    set = function(val) mpDB().hideInRestZone = val; refreshWarning(); end,
                },
                {
                    type = "range",
                    label = "Dismount Delay",
                    desc = "Seconds to wait after dismounting before showing warning. Set to 0 to show immediately.",
                    min = 0, max = 10, step = 0.5,
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
            text = "Sound",
            children = {
                {
                    type = "toggle",
                    label = "Play Sound",
                    desc = "Play a sound when the warning is displayed.",
                    disabled = isDisabled,
                    get = function() return mpDB().soundEnabled; end,
                    set = function(val) mpDB().soundEnabled = val; end,
                },
                {
                    type = "toggle",
                    label = "Sound When Missing",
                    desc = "Play sound when pet is missing.",
                    disabled = function() return isDisabled() or not mpDB().soundEnabled; end,
                    get = function() return mpDB().soundMissing; end,
                    set = function(val) mpDB().soundMissing = val; end,
                },
                {
                    type = "toggle",
                    label = "Sound When Passive",
                    desc = "Play sound when pet is set to passive.",
                    disabled = function() return isDisabled() or not mpDB().soundEnabled; end,
                    get = function() return mpDB().soundPassive; end,
                    set = function(val) mpDB().soundPassive = val; end,
                },
                {
                    type = "toggle",
                    label = "Sound In Combat",
                    desc = "Continue playing sound while in combat. When disabled, sound stops when combat begins.",
                    disabled = function() return isDisabled() or not mpDB().soundEnabled; end,
                    get = function() return mpDB().soundInCombat; end,
                    set = function(val) mpDB().soundInCombat = val; end,
                },
                {
                    type = "toggle",
                    label = "Repeat Sound",
                    desc = "Repeat the sound at regular intervals while the warning is displayed.",
                    disabled = function() return isDisabled() or not mpDB().soundEnabled; end,
                    get = function() return mpDB().soundRepeat; end,
                    set = function(val) mpDB().soundRepeat = val; end,
                },
                {
                    type = "select",
                    label = "Sound",
                    desc = "Select the sound to play. Click the speaker icon to preview.",
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
                    label = "Repeat Interval",
                    desc = "Seconds between sound repeats.",
                    min = 1, max = 30, step = 1,
                    disabled = function() return isDisabled() or not mpDB().soundEnabled or not mpDB().soundRepeat; end,
                    get = function() return mpDB().soundInterval or 5; end,
                    set = function(val) mpDB().soundInterval = val; end,
                },
            },
        },
    };
end
