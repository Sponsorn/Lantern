local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local UX = Lantern.UX;
local T = UX and UX.Theme;
if (not T) then return; end

local module = Lantern.modules["ConsumableAlerts"];
if (not module) then return; end
local L = Lantern.L;

local moduleEnabled = Lantern.moduleEnabled;
local moduleToggle = Lantern.moduleToggle;

module.widgetOptions = function()
    local function db()
        if (not Lantern.db) then Lantern.db = {}; end
        if (not Lantern.db.consumableAlerts) then Lantern.db.consumableAlerts = {}; end
        local d = Lantern.db.consumableAlerts;
        local defaults = {
            font = "Roboto Semi Bold", fontSize = 18, fontOutline = "OUTLINE",
            color = { r = 1, g = 1, b = 1 },
            fadeDuration = 4,
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
        return not moduleEnabled("ConsumableAlerts");
    end

    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true);

    local function getFontValues()
        local fonts = {};
        if (LSM) then
            for _, name in ipairs(LSM:List("font") or {}) do
                fonts[name] = name;
            end
        end
        if (not fonts["Roboto Semi Bold"]) then
            fonts["Roboto Semi Bold"] = "Roboto Semi Bold";
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
        moduleToggle("ConsumableAlerts", L["ENABLE"], L["CONSUMABLEALERTS_ENABLE_DESC"]),
        {
            type = "toggle",
            label = L["SHARED_PREVIEW"],
            desc = L["CONSUMABLEALERTS_PREVIEW_DESC"],
            disabled = isDisabled,
            get = function() return isPreviewActive(); end,
            set = function(val)
                if (module.SetPreviewMode) then module:SetPreviewMode(val); end
            end,
        },
        {
            type = "group",
            text = L["CONSUMABLEALERTS_GROUP_FONT"],
            expanded = true,
            children = {
                {
                    type = "select",
                    label = L["SHARED_FONT"],
                    desc = L["CONSUMABLEALERTS_FONT_DESC"],
                    values = getFontValues,
                    disabled = isDisabled,
                    get = function() return db().font or "Roboto Semi Bold"; end,
                    set = function(val)
                        db().font = val;
                        if (module.RefreshFont) then module:RefreshFont(); end
                    end,
                },
                {
                    type = "range",
                    label = L["SHARED_FONT_SIZE"],
                    desc = L["CONSUMABLEALERTS_FONT_SIZE_DESC"],
                    min = 10, max = 36, step = 1, default = 18,
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
                    desc = L["CONSUMABLEALERTS_FONT_OUTLINE_DESC"],
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
                    label = L["CONSUMABLEALERTS_FADE_DURATION"],
                    desc = L["CONSUMABLEALERTS_FADE_DURATION_DESC"],
                    min = 1, max = 10, step = 0.5, default = 4,
                    disabled = isDisabled,
                    get = function() return db().fadeDuration; end,
                    set = function(val) db().fadeDuration = val; end,
                },
                {
                    type = "color",
                    label = L["SHARED_FONT_COLOR"],
                    desc = L["CONSUMABLEALERTS_COLOR_DESC"],
                    disabled = isDisabled,
                    get = function()
                        local c = db().color;
                        return c.r, c.g, c.b;
                    end,
                    set = function(r, g, b)
                        db().color = { r = r, g = g, b = b };
                        if (module.RefreshFont) then module:RefreshFont(); end
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
                    desc = L["CONSUMABLEALERTS_PLAY_SOUND_DESC"],
                    disabled = isDisabled,
                    get = function() return db().soundEnabled; end,
                    set = function(val) db().soundEnabled = val; end,
                },
                {
                    type = "select",
                    label = L["SHARED_SOUND_SELECT"],
                    desc = L["CONSUMABLEALERTS_SOUND_SELECT_DESC"],
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
            children = (function()
                local children = {};
                local anchorWidgets = Lantern:GetAnchorWidgets({
                    frame = module.GetFrame and module:GetFrame(),
                    getAnchorId = function() return db().anchorTo or "none"; end,
                    setAnchorId = function(id) db().anchorTo = id; end,
                    getOffsetX = function() return db().anchorOffsetX or 0; end,
                    setOffsetX = function(val) db().anchorOffsetX = val; end,
                    getOffsetY = function() return db().anchorOffsetY or 0; end,
                    setOffsetY = function(val) db().anchorOffsetY = val; end,
                    isDisabled = isDisabled,
                });
                for _, w in ipairs(anchorWidgets) do table.insert(children, w); end
                table.insert(children, {
                    type = "toggle",
                    label = L["SHARED_LOCK_POSITION"],
                    desc = L["CONSUMABLEALERTS_LOCK_POSITION_DESC"],
                    disabled = isDisabled,
                    hidden = function() local id = db().anchorTo; return id and id ~= "none"; end,
                    get = function() return db().locked; end,
                    set = function(val)
                        db().locked = val;
                        if (module.UpdateLock) then module:UpdateLock(); end
                    end,
                });
                table.insert(children, {
                    type = "execute",
                    label = L["SHARED_RESET_POSITION"],
                    desc = L["CONSUMABLEALERTS_RESET_POSITION_DESC"],
                    disabled = isDisabled,
                    hidden = function() local id = db().anchorTo; return id and id ~= "none"; end,
                    func = function()
                        if (module.ResetPosition) then module:ResetPosition(); end
                    end,
                });
                return children;
            end)(),
        },
    };
end
