local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local LanternUX = _G.LanternUX;
local T = LanternUX and LanternUX.Theme;
if (not T) then return; end

local module = Lantern.modules["CombatAlert"];
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
        [""] = L["FONT_OUTLINE_NONE"],
        ["OUTLINE"] = L["FONT_OUTLINE_OUTLINE"],
        ["THICKOUTLINE"] = L["FONT_OUTLINE_THICK"],
        ["MONOCHROME"] = L["FONT_OUTLINE_MONO"],
        ["OUTLINE, MONOCHROME"] = L["FONT_OUTLINE_OUTLINE_MONO"],
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
        moduleToggle("CombatAlert", L["ENABLE"], L["COMBATALERT_ENABLE_DESC"]),
        {
            type = "toggle",
            label = L["SHARED_PREVIEW"],
            desc = L["COMBATALERT_PREVIEW_DESC"],
            disabled = isDisabled,
            get = function() return isPreviewActive(); end,
            set = function(val)
                if (module.SetPreviewMode) then module:SetPreviewMode(val); end
            end,
        },
        {
            type = "group",
            text = L["COMBATALERT_GROUP_ENTER"],
            expanded = true,
            children = {
                {
                    type = "toggle",
                    label = L["COMBATALERT_SHOW_ENTER"],
                    desc = L["COMBATALERT_SHOW_ENTER_DESC"],
                    disabled = isDisabled,
                    get = function() return db().showEnter; end,
                    set = function(val) db().showEnter = val; end,
                },
                {
                    type = "input",
                    label = L["COMBATALERT_ENTER_TEXT"],
                    desc = L["COMBATALERT_ENTER_TEXT_DESC"],
                    disabled = isDisabled,
                    get = function() return db().enterText; end,
                    set = function(val) db().enterText = val; end,
                },
                {
                    type = "color",
                    label = L["COMBATALERT_ENTER_COLOR"],
                    desc = L["COMBATALERT_ENTER_COLOR_DESC"],
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
            text = L["COMBATALERT_GROUP_LEAVE"],
            children = {
                {
                    type = "toggle",
                    label = L["COMBATALERT_SHOW_LEAVE"],
                    desc = L["COMBATALERT_SHOW_LEAVE_DESC"],
                    disabled = isDisabled,
                    get = function() return db().showLeave; end,
                    set = function(val) db().showLeave = val; end,
                },
                {
                    type = "input",
                    label = L["COMBATALERT_LEAVE_TEXT"],
                    desc = L["COMBATALERT_LEAVE_TEXT_DESC"],
                    disabled = isDisabled,
                    get = function() return db().leaveText; end,
                    set = function(val) db().leaveText = val; end,
                },
                {
                    type = "color",
                    label = L["COMBATALERT_LEAVE_COLOR"],
                    desc = L["COMBATALERT_LEAVE_COLOR_DESC"],
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
            text = L["COMBATALERT_GROUP_FONT"],
            children = {
                {
                    type = "select",
                    label = L["SHARED_FONT"],
                    desc = L["COMBATALERT_FONT_DESC"],
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
                    label = L["SHARED_FONT_SIZE"],
                    desc = L["COMBATALERT_FONT_SIZE_DESC"],
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
                    label = L["SHARED_FONT_OUTLINE"],
                    desc = L["COMBATALERT_FONT_OUTLINE_DESC"],
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
                    label = L["COMBATALERT_FADE_DURATION"],
                    desc = L["COMBATALERT_FADE_DURATION_DESC"],
                    min = 0.5, max = 5, step = 0.5, default = 2.0,
                    disabled = isDisabled,
                    get = function() return db().fadeDuration; end,
                    set = function(val) db().fadeDuration = val; end,
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
                    desc = L["COMBATALERT_PLAY_SOUND_DESC"],
                    disabled = isDisabled,
                    get = function() return db().soundEnabled; end,
                    set = function(val) db().soundEnabled = val; end,
                },
                {
                    type = "select",
                    label = L["SHARED_SOUND_SELECT"],
                    desc = L["COMBATALERT_SOUND_SELECT_DESC"],
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
                    desc = L["COMBATALERT_LOCK_POSITION_DESC"],
                    disabled = isDisabled,
                    get = function() return db().locked; end,
                    set = function(val)
                        db().locked = val;
                        if (module.UpdateLock) then module:UpdateLock(); end
                    end,
                },
                {
                    type = "execute",
                    label = L["SHARED_RESET_POSITION"],
                    desc = L["COMBATALERT_RESET_POSITION_DESC"],
                    disabled = isDisabled,
                    func = function()
                        if (module.ResetPosition) then module:ResetPosition(); end
                    end,
                },
            },
        },
    };
end
