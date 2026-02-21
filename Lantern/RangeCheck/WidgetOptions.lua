local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local LanternUX = _G.LanternUX;
local T = LanternUX and LanternUX.Theme;
if (not T) then return; end

local module = Lantern.modules["RangeCheck"];
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
        font = "Roboto Light", fontSize = 16, fontOutline = "OUTLINE",
        combatOnly = false, locked = true, displayMode = "range", hideInRange = false,
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

    local isStatusMode = function()
        return db().displayMode == "status";
    end

    local refreshPage = function()
        if (Lantern._uxPanel and Lantern._uxPanel.refreshPage) then
            Lantern._uxPanel:refreshPage();
        end
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
        [""]              = "None",
        ["OUTLINE"]       = "Outline",
        ["THICKOUTLINE"]  = "Thick Outline",
    };
    local outlineSorting = { "", "OUTLINE", "THICKOUTLINE" };

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

    return {
        moduleToggle("RangeCheck", "Enable", "Show distance to your current target."),

        -----------------------------------------------------------------------
        -- Display
        -----------------------------------------------------------------------
        {
            type = "group",
            text = "Display",
            expanded = true,
            children = {
                {
                    type = "select",
                    label = "Display Mode",
                    desc = "Range: show distance numbers. Status: show In Range / Out of Range.",
                    disabled = isDisabled,
                    values = {
                        range = "Range (numbers)",
                        status = "Status (in/out)",
                    },
                    sorting = { "range", "status" },
                    get = function() return db().displayMode; end,
                    set = function(val)
                        db().displayMode = val;
                        refreshAnimation();
                        refreshPage();
                    end,
                },
                {
                    type = "toggle",
                    label = "Hide When In Range",
                    desc = "Hide the display when your target is within range. Only shows when out of range.",
                    disabled = function() return isDisabled() or not isStatusMode(); end,
                    hidden = function() return not isStatusMode(); end,
                    get = function() return db().hideInRange; end,
                    set = function(val) db().hideInRange = val; end,
                },
                {
                    type = "toggle",
                    label = "Combat Only",
                    desc = "Only show range when in combat.",
                    disabled = isDisabled,
                    get = function() return db().combatOnly; end,
                    set = function(val) db().combatOnly = val; end,
                },
            },
        },

        -----------------------------------------------------------------------
        -- Status Mode Text & Colors
        -----------------------------------------------------------------------
        {
            type = "group",
            text = "Status Text",
            hidden = function() return not isStatusMode(); end,
            expanded = true,
            children = {
                {
                    type = "input",
                    label = "In Range Text",
                    desc = "Text to display when your target is within range.",
                    disabled = isDisabled,
                    get = function() return db().inRangeText or "In Range"; end,
                    set = function(val) db().inRangeText = val; end,
                },
                {
                    type = "input",
                    label = "Out of Range Text",
                    desc = "Text to display when your target is out of range.",
                    disabled = isDisabled,
                    get = function() return db().outOfRangeText or "Out of Range"; end,
                    set = function(val) db().outOfRangeText = val; end,
                },
                {
                    type = "color",
                    label = "In Range Color",
                    desc = "Color for the in-range text.",
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
                    label = "Out of Range Color",
                    desc = "Color for the out-of-range text.",
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
                    label = "Animation Style",
                    desc = "Choose how the status text animates on state change.",
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
            text = "Font",
            children = {
                {
                    type = "select",
                    label = "Font",
                    desc = "Select the font for the range text.",
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
                    desc = "Size of the range text.",
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
                    label = "Font Outline",
                    desc = "Outline style for the range text.",
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
            text = "Position",
            children = {
                {
                    type = "toggle",
                    label = "Lock Position",
                    desc = "Prevent the range display from being moved.",
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
                    desc = "Reset the range display to its default position.",
                    disabled = isDisabled,
                    func = function()
                        if (module.ResetPosition) then module:ResetPosition(); end
                    end,
                },
            },
        },
    };
end
