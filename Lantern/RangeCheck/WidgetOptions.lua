local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local LanternUX = _G.LanternUX;
local T = LanternUX and LanternUX.Theme;
if (not T) then return; end

local module = Lantern.modules["RangeCheck"];
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
        font = "Roboto Light", fontSize = 16, fontOutline = "OUTLINE",
        combatOnly = false, locked = true, hideInRange = false,
        inRangeText = "In Range", outOfRangeText = "Out of Range",
        inRangeColor = { r = 0.2, g = 1.0, b = 0.2 },
        outOfRangeColor = { r = 1.0, g = 0.2, b = 0.2 },
        animationStyle = "none",
    };

    local function db()
        if (not Lantern.db) then Lantern.db = {}; end
        if (not Lantern.db.rangeCheck) then Lantern.db.rangeCheck = {}; end
        local d = Lantern.db.rangeCheck;
        for k, v in pairs(DEFAULTS) do
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
        return not moduleEnabled("RangeCheck");
    end

    local function refreshAnimation()
        if (module.RefreshAnimation) then module:RefreshAnimation(); end
    end

    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true);

    local function getFontValues()
        local fonts = {};
        if (LSM) then
            for _, name in ipairs(LSM:List("font") or {}) do
                fonts[name] = name;
            end
        end
        return fonts;
    end

    local outlineValues = {
        [""]              = L["FONT_OUTLINE_NONE"],
        ["OUTLINE"]       = L["FONT_OUTLINE_OUTLINE"],
        ["THICKOUTLINE"]  = L["FONT_OUTLINE_THICK"],
    };
    local outlineSorting = { "", "OUTLINE", "THICKOUTLINE" };

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

    return {
        moduleToggle("RangeCheck", L["ENABLE"], L["RANGECHECK_ENABLE_DESC"]),

        -----------------------------------------------------------------------
        -- Display
        -----------------------------------------------------------------------
        {
            type = "group",
            text = L["SHARED_GROUP_DISPLAY"],
            expanded = true,
            children = {
                {
                    type = "toggle",
                    label = L["RANGECHECK_HIDE_IN_RANGE"],
                    desc = L["RANGECHECK_HIDE_IN_RANGE_DESC"],
                    disabled = isDisabled,
                    get = function() return db().hideInRange; end,
                    set = function(val) db().hideInRange = val; end,
                },
                {
                    type = "toggle",
                    label = L["RANGECHECK_COMBAT_ONLY"],
                    desc = L["RANGECHECK_COMBAT_ONLY_DESC"],
                    disabled = isDisabled,
                    get = function() return db().combatOnly; end,
                    set = function(val) db().combatOnly = val; end,
                },
            },
        },

        -----------------------------------------------------------------------
        -- Status Text & Colors
        -----------------------------------------------------------------------
        {
            type = "group",
            text = L["RANGECHECK_GROUP_STATUS"],
            expanded = true,
            children = {
                {
                    type = "input",
                    label = L["RANGECHECK_IN_RANGE_TEXT"],
                    desc = L["RANGECHECK_IN_RANGE_TEXT_DESC"],
                    disabled = isDisabled,
                    get = function() return db().inRangeText or "In Range"; end,
                    set = function(val) db().inRangeText = val; end,
                },
                {
                    type = "input",
                    label = L["RANGECHECK_OUT_OF_RANGE_TEXT"],
                    desc = L["RANGECHECK_OUT_OF_RANGE_TEXT_DESC"],
                    disabled = isDisabled,
                    get = function() return db().outOfRangeText or "Out of Range"; end,
                    set = function(val) db().outOfRangeText = val; end,
                },
                {
                    type = "color",
                    label = L["RANGECHECK_IN_RANGE_COLOR"],
                    desc = L["RANGECHECK_IN_RANGE_COLOR_DESC"],
                    disabled = isDisabled,
                    get = function()
                        local c = db().inRangeColor or DEFAULTS.inRangeColor;
                        return c.r, c.g, c.b;
                    end,
                    set = function(r, g, b)
                        db().inRangeColor = { r = r, g = g, b = b };
                    end,
                },
                {
                    type = "color",
                    label = L["RANGECHECK_OUT_OF_RANGE_COLOR"],
                    desc = L["RANGECHECK_OUT_OF_RANGE_COLOR_DESC"],
                    disabled = isDisabled,
                    get = function()
                        local c = db().outOfRangeColor or DEFAULTS.outOfRangeColor;
                        return c.r, c.g, c.b;
                    end,
                    set = function(r, g, b)
                        db().outOfRangeColor = { r = r, g = g, b = b };
                    end,
                },
                {
                    type = "select",
                    label = L["SHARED_ANIMATION_STYLE"],
                    desc = L["RANGECHECK_ANIMATION_DESC"],
                    values = animationValues,
                    sorting = animationSorting,
                    disabled = isDisabled,
                    get = function() return db().animationStyle or "none"; end,
                    set = function(val) db().animationStyle = val; refreshAnimation(); end,
                },
            },
        },

        -----------------------------------------------------------------------
        -- Font
        -----------------------------------------------------------------------
        {
            type = "group",
            text = L["SHARED_FONT"],
            children = {
                {
                    type = "select",
                    label = L["SHARED_FONT"],
                    desc = L["RANGECHECK_FONT_DESC"],
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
                    desc = L["RANGECHECK_FONT_SIZE_DESC"],
                    min = 10, max = 36, step = 1, default = 16,
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
                    desc = L["RANGECHECK_FONT_OUTLINE_DESC"],
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
                    desc = L["RANGECHECK_LOCK_POSITION_DESC"],
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
                    desc = L["RANGECHECK_RESET_POSITION_DESC"],
                    disabled = isDisabled,
                    func = function()
                        if (module.ResetPosition) then module:ResetPosition(); end
                    end,
                },
            },
        },
    };
end
