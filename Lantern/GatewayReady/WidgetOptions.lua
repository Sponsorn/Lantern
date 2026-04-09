local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local UX = Lantern.UX;
local T = UX and UX.Theme;
if (not T) then return; end

local module = Lantern.modules["GatewayReady"];
if (not module) then return; end
local L = Lantern.L;

local moduleEnabled = Lantern.moduleEnabled;
local moduleToggle = Lantern.moduleToggle;

module.widgetOptions = function()
    local function db()
        if (not Lantern.db) then Lantern.db = {}; end
        if (not Lantern.db.gatewayReady) then Lantern.db.gatewayReady = {}; end
        local d = Lantern.db.gatewayReady;
        local defaults = {
            combatOnly = true,
            font = "Roboto Light", fontSize = 28, fontOutline = "OUTLINE",
            color = { r = 0.61, g = 0.35, b = 0.71 },
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
        return not moduleEnabled("GatewayReady");
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
        return module and module.IsPreviewActive and module:IsPreviewActive() or false;
    end

    return {
        moduleToggle("GatewayReady", L["ENABLE"], L["GATEWAYREADY_ENABLE_DESC"]),
        {
            type = "execute",
            label = isPreviewActive() and L["SHARED_PREVIEW"] .. " (Stop)" or L["SHARED_PREVIEW"],
            disabled = isDisabled,
            func = function()
                if (module and module.SetPreviewMode) then
                    module:SetPreviewMode(not isPreviewActive());
                    local panel = Lantern._uxPanel;
                    if (panel and panel.RefreshCurrentPage) then panel:RefreshCurrentPage(); end
                end
            end,
        },
        {
            type = "toggle",
            label = L["GATEWAYREADY_COMBAT_ONLY"],
            desc = L["GATEWAYREADY_COMBAT_ONLY_DESC"],
            disabled = isDisabled,
            get = function() return db().combatOnly; end,
            set = function(val) db().combatOnly = val; end,
        },
        {
            type = "color",
            label = L["SHARED_FONT_COLOR"],
            disabled = isDisabled,
            get = function()
                local c = db().color;
                return c.r, c.g, c.b;
            end,
            set = function(r, g, b)
                db().color = { r = r, g = g, b = b };
            end,
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
                    desc = L["COMBATALERT_LOCK_POSITION_DESC"],
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
                    desc = L["COMBATALERT_RESET_POSITION_DESC"],
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
