local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local LanternUX = _G.LanternUX;
local T = LanternUX and LanternUX.Theme;
if (not T) then return; end

local module = Lantern.modules["CombatAlert"];
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
    local function db()
        if (not Lantern.db) then Lantern.db = {}; end
        if (not Lantern.db.combatAlert) then Lantern.db.combatAlert = {}; end
        local d = Lantern.db.combatAlert;
        local defaults = {
            showEnter = true, showLeave = true,
            enterText = "IN COMBAT", leaveText = "OUT OF COMBAT",
            enterColor = { r = 1, g = 0.2, b = 0.2 },
            leaveColor = { r = 0.2, g = 1, b = 0.2 },
            font = "Roboto Light", fontSize = 28, fontOutline = "OUTLINE",
            fadeDuration = 2.0,
            soundEnabled = false, soundName = "RaidWarning",
            locked = true,
        };
        for k, v in pairs(defaults) do
            if (d[k] == nil) then
                if (type(v) == "table") then
                    d[k] = { r = v.r, g = v.g, b = v.b };
                else
                    d[k] = v;
                end
            end
        end
        return d;
    end

    local isDisabled = function()
        return not moduleEnabled("CombatAlert");
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

    local outlineValues = {
        [""] = "None",
        ["OUTLINE"] = "Outline",
        ["THICKOUTLINE"] = "Thick Outline",
        ["MONOCHROME"] = "Monochrome",
        ["OUTLINE, MONOCHROME"] = "Outline + Mono",
    };
    local outlineSorting = { "", "OUTLINE", "THICKOUTLINE", "MONOCHROME", "OUTLINE, MONOCHROME" };

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

    local function isPreviewActive()
        return module.IsPreviewActive and module:IsPreviewActive() or false;
    end

    return {
        moduleToggle("CombatAlert", "Enable", "Show text alerts when entering/leaving combat."),
        {
            type = "toggle",
            label = "Preview",
            desc = "Loop enter/leave alerts on screen for real-time editing. Automatically disables when the settings panel is closed.",
            disabled = isDisabled,
            get = function() return isPreviewActive(); end,
            set = function(val)
                if (module.SetPreviewMode) then module:SetPreviewMode(val); end
            end,
        },
        {
            type = "group",
            text = "Combat Enter",
            expanded = true,
            children = {
                {
                    type = "toggle",
                    label = "Show Enter Alert",
                    desc = "Show an alert when entering combat.",
                    disabled = isDisabled,
                    get = function() return db().showEnter; end,
                    set = function(val) db().showEnter = val; end,
                },
                {
                    type = "input",
                    label = "Enter Text",
                    desc = "Text displayed when entering combat.",
                    disabled = isDisabled,
                    get = function() return db().enterText; end,
                    set = function(val) db().enterText = val; end,
                },
                {
                    type = "color",
                    label = "Enter Color",
                    desc = "Color of the combat enter text.",
                    disabled = isDisabled,
                    get = function()
                        local c = db().enterColor;
                        return c.r, c.g, c.b;
                    end,
                    set = function(r, g, b)
                        db().enterColor = { r = r, g = g, b = b };
                    end,
                },
            },
        },
        {
            type = "group",
            text = "Combat Leave",
            children = {
                {
                    type = "toggle",
                    label = "Show Leave Alert",
                    desc = "Show an alert when leaving combat.",
                    disabled = isDisabled,
                    get = function() return db().showLeave; end,
                    set = function(val) db().showLeave = val; end,
                },
                {
                    type = "input",
                    label = "Leave Text",
                    desc = "Text displayed when leaving combat.",
                    disabled = isDisabled,
                    get = function() return db().leaveText; end,
                    set = function(val) db().leaveText = val; end,
                },
                {
                    type = "color",
                    label = "Leave Color",
                    desc = "Color of the combat leave text.",
                    disabled = isDisabled,
                    get = function()
                        local c = db().leaveColor;
                        return c.r, c.g, c.b;
                    end,
                    set = function(r, g, b)
                        db().leaveColor = { r = r, g = g, b = b };
                    end,
                },
            },
        },
        {
            type = "group",
            text = "Font and Display Settings",
            children = {
                {
                    type = "select",
                    label = "Font",
                    desc = "Select the font for the alert text.",
                    values = getFontValues,
                    disabled = isDisabled,
                    get = function() return db().font or "Roboto Light"; end,
                    set = function(val)
                        db().font = val;
                        if (module.RefreshFont) then module:RefreshFont(); end
                    end,
                },
                {
                    type = "range",
                    label = "Font Size",
                    desc = "Size of the alert text.",
                    min = 14, max = 48, step = 1, default = 28,
                    disabled = isDisabled,
                    get = function() return db().fontSize; end,
                    set = function(val)
                        db().fontSize = val;
                        if (module.RefreshFont) then module:RefreshFont(); end
                    end,
                },
                {
                    type = "select",
                    label = "Font Outline",
                    desc = "Outline style for the alert text.",
                    values = outlineValues,
                    sorting = outlineSorting,
                    disabled = isDisabled,
                    get = function() return db().fontOutline or "OUTLINE"; end,
                    set = function(val)
                        db().fontOutline = val;
                        if (module.RefreshFont) then module:RefreshFont(); end
                    end,
                },
                {
                    type = "range",
                    label = "Fade Duration",
                    desc = "Total duration of the alert (hold + fade out) in seconds.",
                    min = 0.5, max = 5, step = 0.5, default = 2.0,
                    disabled = isDisabled,
                    get = function() return db().fadeDuration; end,
                    set = function(val) db().fadeDuration = val; end,
                },
            },
        },
        {
            type = "group",
            text = "Sound",
            children = {
                {
                    type = "toggle",
                    label = "Play Sound",
                    desc = "Play a sound when the alert is shown.",
                    disabled = isDisabled,
                    get = function() return db().soundEnabled; end,
                    set = function(val) db().soundEnabled = val; end,
                },
                {
                    type = "select",
                    label = "Sound",
                    desc = "Select the sound to play.",
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
            text = "Position",
            children = {
                {
                    type = "toggle",
                    label = "Lock Position",
                    desc = "Prevent the alert from being moved.",
                    disabled = isDisabled,
                    get = function() return db().locked; end,
                    set = function(val)
                        db().locked = val;
                        if (module.UpdateLock) then module:UpdateLock(); end
                    end,
                },
                {
                    type = "execute",
                    label = "Reset Position",
                    desc = "Reset the alert to its default position.",
                    disabled = isDisabled,
                    func = function()
                        if (module.ResetPosition) then module:ResetPosition(); end
                    end,
                },
            },
        },
    };
end
