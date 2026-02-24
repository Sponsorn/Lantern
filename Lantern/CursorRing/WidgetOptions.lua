local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local LanternUX = _G.LanternUX;
local T = LanternUX and LanternUX.Theme;
if (not T) then return; end

local module = Lantern.modules["CursorRing"];
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
        showOutOfCombat = true,
        opacityInCombat = 1.0,
        opacityOutOfCombat = 1.0,
        ring1Enabled = true,
        ring1Size = 48,
        ring1Shape = "ring",
        ring1Color = { r = 1.0, g = 0.66, b = 0.0 },
        ring2Enabled = false,
        ring2Size = 32,
        ring2Shape = "thin_ring",
        ring2Color = { r = 1.0, g = 1.0, b = 1.0 },
        dotEnabled = false,
        dotColor = { r = 1.0, g = 1.0, b = 1.0 },
        dotSize = 8,
        castEnabled = true,
        castStyle = "segments",
        castColor = { r = 1.0, g = 0.66, b = 0.0 },
        castOffset = 8,
        gcdEnabled = false,
        gcdColor = { r = 0.0, g = 0.56, b = 0.91 },
        gcdOffset = 8,
        trailEnabled = false,
        trailStyle = "glow",
        trailDuration = 0.4,
        trailColor = { r = 1.0, g = 1.0, b = 1.0 },
        trailMaxPoints = 20,
        trailDotSize = 24,
        trailDotSpacing = 2,
        trailShrink = true,
        trailShrinkDistance = false,
        trailColorPreset = "custom",
    };

    local function cursorRingDB()
        if (not Lantern.db) then Lantern.db = {}; end
        if (not Lantern.db.cursorRing) then Lantern.db.cursorRing = {}; end
        local db = Lantern.db.cursorRing;
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

    local function cursorRingModule()
        return Lantern.modules and Lantern.modules.CursorRing;
    end

    local function isDisabled()
        local m = cursorRingModule();
        return not (m and m.enabled);
    end

    local function isPreviewActive()
        local m = cursorRingModule();
        return m and m.IsPreviewActive and m:IsPreviewActive() or false;
    end

    local function refreshModule(method, ...)
        local m = cursorRingModule();
        if (m and m[method]) then
            m[method](m, ...);
        end
    end

    local shapeValues = {
        ring = L["CURSORRING_SHAPE_CIRCLE"],
        thin_ring = L["CURSORRING_SHAPE_THIN"],
    };
    local shapeSorting = { "ring", "thin_ring" };

    local castStyleValues = {
        segments = L["CURSORRING_STYLE_SEGMENTS"],
        fill = L["CURSORRING_STYLE_FILL"],
        swipe = L["CURSORRING_STYLE_SWIPE"],
    };
    local castStyleSorting = { "segments", "fill", "swipe" };

    return {
        -- Enable
        moduleToggle("CursorRing", L["ENABLE"], L["CURSORRING_ENABLE_DESC"]),

        -- Preview
        {
            type = "execute",
            label = isPreviewActive() and L["CURSORRING_PREVIEW_STOP"] or L["CURSORRING_PREVIEW_START"],
            desc = L["CURSORRING_PREVIEW_DESC"],
            disabled = isDisabled,
            func = function()
                refreshModule("SetPreviewMode", not isPreviewActive());
                local panel = Lantern._uxPanel;
                if (panel and panel.RefreshCurrentPage) then panel:RefreshCurrentPage(); end
            end,
        },

        -----------------------------------------------------------------------
        -- General
        -----------------------------------------------------------------------
        {
            type = "group",
            text = L["CURSORRING_GROUP_GENERAL"],
            expanded = true,
            children = {
                {
                    type = "toggle",
                    label = L["CURSORRING_SHOW_OOC"],
                    desc = L["CURSORRING_SHOW_OOC_DESC"],
                    disabled = isDisabled,
                    get = function() return cursorRingDB().showOutOfCombat; end,
                    set = function(val)
                        cursorRingDB().showOutOfCombat = val;
                        refreshModule("UpdateVisibility");
                    end,
                },
                {
                    type = "range",
                    label = L["CURSORRING_COMBAT_OPACITY"],
                    desc = L["CURSORRING_COMBAT_OPACITY_DESC"],
                    min = 0, max = 1, step = 0.05, default = 1.0,
                    isPercent = true,
                    disabled = isDisabled,
                    get = function() return cursorRingDB().opacityInCombat; end,
                    set = function(val)
                        cursorRingDB().opacityInCombat = val;
                        refreshModule("UpdateVisibility");
                    end,
                },
                {
                    type = "range",
                    label = L["CURSORRING_OOC_OPACITY"],
                    desc = L["CURSORRING_OOC_OPACITY_DESC"],
                    min = 0, max = 1, step = 0.05, default = 1.0,
                    isPercent = true,
                    disabled = isDisabled,
                    get = function() return cursorRingDB().opacityOutOfCombat; end,
                    set = function(val)
                        cursorRingDB().opacityOutOfCombat = val;
                        refreshModule("UpdateVisibility");
                    end,
                },
            },
        },

        -----------------------------------------------------------------------
        -- Ring 1
        -----------------------------------------------------------------------
        {
            type = "group",
            text = L["CURSORRING_GROUP_RING1"],
            children = {
                {
                    type = "toggle",
                    label = L["CURSORRING_ENABLE_RING1"],
                    desc = L["CURSORRING_ENABLE_RING1_DESC"],
                    disabled = isDisabled,
                    get = function() return cursorRingDB().ring1Enabled; end,
                    set = function(val)
                        cursorRingDB().ring1Enabled = val;
                        refreshModule("UpdateRing", 1);
                        refreshModule("UpdateVisibility");
                    end,
                },
                {
                    type = "select",
                    label = L["CURSORRING_SHAPE"],
                    desc = L["CURSORRING_RING_SHAPE_DESC"],
                    values = shapeValues,
                    sorting = shapeSorting,
                    disabled = function() return isDisabled() or (not isPreviewActive() and not cursorRingDB().ring1Enabled); end,
                    get = function() return cursorRingDB().ring1Shape; end,
                    set = function(val)
                        cursorRingDB().ring1Shape = val;
                        refreshModule("UpdateRing", 1);
                        refreshModule("UpdateGCD");
                        refreshModule("UpdateCast");
                    end,
                },
                {
                    type = "color",
                    label = L["CURSORRING_COLOR"],
                    desc = L["CURSORRING_RING1_COLOR_DESC"],
                    disabled = function() return isDisabled() or (not isPreviewActive() and not cursorRingDB().ring1Enabled); end,
                    get = function()
                        local c = cursorRingDB().ring1Color;
                        return c.r, c.g, c.b;
                    end,
                    set = function(r, g, b)
                        cursorRingDB().ring1Color = { r = r, g = g, b = b };
                        refreshModule("UpdateRing", 1);
                    end,
                },
                {
                    type = "range",
                    label = L["CURSORRING_SIZE"],
                    desc = L["CURSORRING_RING1_SIZE_DESC"],
                    min = 16, max = 80, step = 0.01, bigStep = 2, default = 48,
                    disabled = function() return isDisabled() or (not isPreviewActive() and not cursorRingDB().ring1Enabled); end,
                    get = function() return cursorRingDB().ring1Size; end,
                    set = function(val)
                        cursorRingDB().ring1Size = val;
                        refreshModule("UpdateRing", 1);
                        refreshModule("UpdateGCD");
                        refreshModule("UpdateCast");
                    end,
                },
            },
        },

        -----------------------------------------------------------------------
        -- Ring 2
        -----------------------------------------------------------------------
        {
            type = "group",
            text = L["CURSORRING_GROUP_RING2"],
            children = {
                {
                    type = "toggle",
                    label = L["CURSORRING_ENABLE_RING2"],
                    desc = L["CURSORRING_ENABLE_RING2_DESC"],
                    disabled = isDisabled,
                    get = function() return cursorRingDB().ring2Enabled; end,
                    set = function(val)
                        cursorRingDB().ring2Enabled = val;
                        refreshModule("UpdateRing", 2);
                        refreshModule("UpdateVisibility");
                    end,
                },
                {
                    type = "select",
                    label = L["CURSORRING_SHAPE"],
                    desc = L["CURSORRING_RING_SHAPE_DESC"],
                    values = shapeValues,
                    sorting = shapeSorting,
                    disabled = function() return isDisabled() or (not isPreviewActive() and not cursorRingDB().ring2Enabled); end,
                    get = function() return cursorRingDB().ring2Shape; end,
                    set = function(val)
                        cursorRingDB().ring2Shape = val;
                        refreshModule("UpdateRing", 2);
                    end,
                },
                {
                    type = "color",
                    label = L["CURSORRING_COLOR"],
                    desc = L["CURSORRING_RING2_COLOR_DESC"],
                    disabled = function() return isDisabled() or (not isPreviewActive() and not cursorRingDB().ring2Enabled); end,
                    get = function()
                        local c = cursorRingDB().ring2Color;
                        return c.r, c.g, c.b;
                    end,
                    set = function(r, g, b)
                        cursorRingDB().ring2Color = { r = r, g = g, b = b };
                        refreshModule("UpdateRing", 2);
                    end,
                },
                {
                    type = "range",
                    label = L["CURSORRING_SIZE"],
                    desc = L["CURSORRING_RING2_SIZE_DESC"],
                    min = 16, max = 80, step = 0.01, bigStep = 2, default = 32,
                    disabled = function() return isDisabled() or (not isPreviewActive() and not cursorRingDB().ring2Enabled); end,
                    get = function() return cursorRingDB().ring2Size; end,
                    set = function(val)
                        cursorRingDB().ring2Size = val;
                        refreshModule("UpdateRing", 2);
                    end,
                },
            },
        },

        -----------------------------------------------------------------------
        -- Center Dot
        -----------------------------------------------------------------------
        {
            type = "group",
            text = L["CURSORRING_GROUP_DOT"],
            children = {
                {
                    type = "toggle",
                    label = L["CURSORRING_ENABLE_DOT"],
                    desc = L["CURSORRING_ENABLE_DOT_DESC"],
                    disabled = isDisabled,
                    get = function() return cursorRingDB().dotEnabled; end,
                    set = function(val)
                        cursorRingDB().dotEnabled = val;
                        refreshModule("UpdateDot");
                        refreshModule("UpdateVisibility");
                    end,
                },
                {
                    type = "color",
                    label = L["CURSORRING_COLOR"],
                    desc = L["CURSORRING_DOT_COLOR_DESC"],
                    disabled = function() return isDisabled() or (not isPreviewActive() and not cursorRingDB().dotEnabled); end,
                    get = function()
                        local c = cursorRingDB().dotColor;
                        return c.r, c.g, c.b;
                    end,
                    set = function(r, g, b)
                        cursorRingDB().dotColor = { r = r, g = g, b = b };
                        refreshModule("UpdateDot");
                    end,
                },
                {
                    type = "range",
                    label = L["CURSORRING_SIZE"],
                    desc = L["CURSORRING_DOT_SIZE_DESC"],
                    min = 2, max = 24, step = 1, default = 8,
                    disabled = function() return isDisabled() or (not isPreviewActive() and not cursorRingDB().dotEnabled); end,
                    get = function() return cursorRingDB().dotSize; end,
                    set = function(val)
                        cursorRingDB().dotSize = val;
                        refreshModule("UpdateDot");
                    end,
                },
            },
        },

        -----------------------------------------------------------------------
        -- Cast Effect
        -----------------------------------------------------------------------
        {
            type = "group",
            text = L["CURSORRING_GROUP_CAST"],
            children = {
                {
                    type = "toggle",
                    label = L["CURSORRING_ENABLE_CAST"],
                    desc = L["CURSORRING_ENABLE_CAST_DESC"],
                    disabled = isDisabled,
                    get = function() return cursorRingDB().castEnabled; end,
                    set = function(val)
                        cursorRingDB().castEnabled = val;
                    end,
                },
                {
                    type = "select",
                    label = L["CURSORRING_STYLE"],
                    desc = L["CURSORRING_CAST_STYLE_DESC"],
                    values = castStyleValues,
                    sorting = castStyleSorting,
                    disabled = function() return isDisabled() or (not isPreviewActive() and not cursorRingDB().castEnabled); end,
                    get = function() return cursorRingDB().castStyle; end,
                    set = function(val)
                        cursorRingDB().castStyle = val;
                        refreshModule("UpdateCast");
                    end,
                },
                {
                    type = "color",
                    label = L["CURSORRING_COLOR"],
                    desc = L["CURSORRING_CAST_COLOR_DESC"],
                    disabled = function() return isDisabled() or (not isPreviewActive() and not cursorRingDB().castEnabled); end,
                    get = function()
                        local c = cursorRingDB().castColor;
                        return c.r, c.g, c.b;
                    end,
                    set = function(r, g, b)
                        cursorRingDB().castColor = { r = r, g = g, b = b };
                        refreshModule("UpdateCast");
                    end,
                },
                {
                    type = "range",
                    label = L["CURSORRING_SWIPE_OFFSET"],
                    desc = L["CURSORRING_SWIPE_OFFSET_DESC"],
                    min = 0, max = 32, step = 0.01, bigStep = 0.5, default = 8,
                    disabled = function() return isDisabled() or (not isPreviewActive() and (not cursorRingDB().castEnabled or cursorRingDB().castStyle ~= "swipe")); end,
                    get = function() return cursorRingDB().castOffset; end,
                    set = function(val)
                        cursorRingDB().castOffset = val;
                        refreshModule("UpdateCast");
                    end,
                },
            },
        },

        -----------------------------------------------------------------------
        -- GCD
        -----------------------------------------------------------------------
        {
            type = "group",
            text = L["CURSORRING_GROUP_GCD"],
            children = {
                {
                    type = "toggle",
                    label = L["CURSORRING_ENABLE_GCD"],
                    desc = L["CURSORRING_ENABLE_GCD_DESC"],
                    disabled = isDisabled,
                    get = function() return cursorRingDB().gcdEnabled; end,
                    set = function(val)
                        cursorRingDB().gcdEnabled = val;
                        refreshModule("SetGCDEnabled", val);
                        refreshModule("UpdateGCD");
                    end,
                },
                {
                    type = "color",
                    label = L["CURSORRING_COLOR"],
                    desc = L["CURSORRING_GCD_COLOR_DESC"],
                    disabled = function() return isDisabled() or (not isPreviewActive() and not cursorRingDB().gcdEnabled); end,
                    get = function()
                        local c = cursorRingDB().gcdColor;
                        return c.r, c.g, c.b;
                    end,
                    set = function(r, g, b)
                        cursorRingDB().gcdColor = { r = r, g = g, b = b };
                        refreshModule("UpdateGCD");
                    end,
                },
                {
                    type = "range",
                    label = L["CURSORRING_OFFSET"],
                    desc = L["CURSORRING_GCD_OFFSET_DESC"],
                    min = 0, max = 32, step = 0.01, bigStep = 0.5, default = 8,
                    disabled = function() return isDisabled() or (not isPreviewActive() and not cursorRingDB().gcdEnabled); end,
                    get = function() return cursorRingDB().gcdOffset; end,
                    set = function(val)
                        cursorRingDB().gcdOffset = val;
                        refreshModule("UpdateGCD");
                        refreshModule("UpdateCast");
                    end,
                },
            },
        },

        -----------------------------------------------------------------------
        -- Trail
        -----------------------------------------------------------------------
        {
            type = "group",
            text = L["CURSORRING_GROUP_TRAIL"],
            children = {
                {
                    type = "toggle",
                    label = L["CURSORRING_ENABLE_TRAIL"],
                    desc = L["CURSORRING_ENABLE_TRAIL_DESC"],
                    disabled = isDisabled,
                    get = function() return cursorRingDB().trailEnabled; end,
                    set = function(val)
                        cursorRingDB().trailEnabled = val;
                        refreshModule("EnsureTrail");
                    end,
                },
                {
                    type = "select",
                    label = L["CURSORRING_STYLE"],
                    desc = L["CURSORRING_TRAIL_STYLE_DESC"],
                    values = {
                        glow = L["CURSORRING_TRAIL_GLOW"],
                        line = L["CURSORRING_TRAIL_LINE"],
                        thickline = L["CURSORRING_TRAIL_THICKLINE"],
                        dots = L["CURSORRING_TRAIL_DOTS"],
                        custom = L["CURSORRING_TRAIL_CUSTOM"],
                    },
                    sorting = { "glow", "line", "thickline", "dots", "custom" },
                    disabled = function() return isDisabled() or (not isPreviewActive() and not cursorRingDB().trailEnabled); end,
                    get = function() return cursorRingDB().trailStyle or "glow"; end,
                    set = function(val)
                        local d = cursorRingDB();
                        d.trailStyle = val;
                        local m = cursorRingModule();
                        local presets = m and m.TRAIL_STYLE_PRESETS;
                        local preset = presets and presets[val];
                        if (preset) then
                            d.trailMaxPoints = preset.maxPoints;
                            d.trailDotSize = preset.dotSize;
                            d.trailDotSpacing = preset.dotSpacing;
                            d.trailShrink = preset.shrink;
                            d.trailShrinkDistance = preset.shrinkDistance;
                        end
                        refreshModule("UpdateTrail");
                        refreshModule("EnsureTrail");
                        -- Refresh the page to update slider values
                        local panel = Lantern._uxPanel;
                        if (panel and panel.RefreshCurrentPage) then panel:RefreshCurrentPage(); end
                    end,
                },
                {
                    type = "select",
                    label = L["CURSORRING_COLOR"],
                    desc = L["CURSORRING_TRAIL_COLOR_DESC"],
                    values = {
                        custom  = L["CURSORRING_TRAIL_COLOR_CUSTOM"],
                        class   = L["CURSORRING_TRAIL_COLOR_CLASS"],
                        gold    = L["CURSORRING_TRAIL_COLOR_GOLD"],
                        arcane  = L["CURSORRING_TRAIL_COLOR_ARCANE"],
                        fel     = L["CURSORRING_TRAIL_COLOR_FEL"],
                        fire    = L["CURSORRING_TRAIL_COLOR_FIRE"],
                        frost   = L["CURSORRING_TRAIL_COLOR_FROST"],
                        holy    = L["CURSORRING_TRAIL_COLOR_HOLY"],
                        shadow  = L["CURSORRING_TRAIL_COLOR_SHADOW"],
                        rainbow = L["CURSORRING_TRAIL_COLOR_RAINBOW"],
                        alar    = L["CURSORRING_TRAIL_COLOR_ALAR"],
                        ember   = L["CURSORRING_TRAIL_COLOR_EMBER"],
                        ocean   = L["CURSORRING_TRAIL_COLOR_OCEAN"],
                    },
                    sorting = { "custom", "class", "gold", "arcane", "fel", "fire", "frost", "holy", "shadow", "rainbow", "alar", "ember", "ocean" },
                    disabled = function() return isDisabled() or (not isPreviewActive() and not cursorRingDB().trailEnabled); end,
                    get = function() return cursorRingDB().trailColorPreset or "custom"; end,
                    set = function(val)
                        cursorRingDB().trailColorPreset = val;
                        local panel = Lantern._uxPanel;
                        if (panel and panel.RefreshCurrentPage) then panel:RefreshCurrentPage(); end
                    end,
                },
                {
                    type = "color",
                    label = L["CURSORRING_CUSTOM_COLOR"],
                    desc = L["CURSORRING_CUSTOM_COLOR_DESC"],
                    disabled = function()
                        local d = cursorRingDB();
                        return isDisabled() or (not isPreviewActive() and not d.trailEnabled) or (d.trailColorPreset ~= "custom");
                    end,
                    get = function()
                        local c = cursorRingDB().trailColor;
                        return c.r, c.g, c.b;
                    end,
                    set = function(r, g, b)
                        cursorRingDB().trailColor = { r = r, g = g, b = b };
                    end,
                },
                {
                    type = "range",
                    label = L["CURSORRING_DURATION"],
                    desc = L["CURSORRING_DURATION_DESC"],
                    min = 0.1, max = 2.0, step = 0.05, default = 0.4,
                    disabled = function() return isDisabled() or (not isPreviewActive() and not cursorRingDB().trailEnabled); end,
                    get = function() return cursorRingDB().trailDuration; end,
                    set = function(val)
                        cursorRingDB().trailDuration = val;
                    end,
                },
                {
                    type = "range",
                    label = L["CURSORRING_MAX_POINTS"],
                    desc = L["CURSORRING_MAX_POINTS_DESC"],
                    min = 5, max = 400, step = 1, default = 20,
                    disabled = function() return isDisabled() or (not isPreviewActive() and not cursorRingDB().trailEnabled); end,
                    get = function() return cursorRingDB().trailMaxPoints or 20; end,
                    set = function(val)
                        local d = cursorRingDB();
                        d.trailMaxPoints = val;
                        d.trailStyle = "custom";
                        refreshModule("UpdateTrail");
                        refreshModule("EnsureTrail");
                    end,
                },
                {
                    type = "range",
                    label = L["CURSORRING_DOT_SIZE"],
                    desc = L["CURSORRING_DOT_SIZE_TRAIL_DESC"],
                    min = 4, max = 48, step = 1, default = 24,
                    disabled = function() return isDisabled() or (not isPreviewActive() and not cursorRingDB().trailEnabled); end,
                    get = function() return cursorRingDB().trailDotSize or 24; end,
                    set = function(val)
                        local d = cursorRingDB();
                        d.trailDotSize = val;
                        d.trailStyle = "custom";
                        refreshModule("UpdateTrail");
                    end,
                },
                {
                    type = "range",
                    label = L["CURSORRING_DOT_SPACING"],
                    desc = L["CURSORRING_DOT_SPACING_DESC"],
                    min = 1, max = 16, step = 1, default = 2,
                    disabled = function() return isDisabled() or (not isPreviewActive() and not cursorRingDB().trailEnabled); end,
                    get = function() return cursorRingDB().trailDotSpacing or 2; end,
                    set = function(val)
                        local d = cursorRingDB();
                        d.trailDotSpacing = val;
                        d.trailStyle = "custom";
                    end,
                },
                {
                    type = "toggle",
                    label = L["CURSORRING_SHRINK_AGE"],
                    desc = L["CURSORRING_SHRINK_AGE_DESC"],
                    disabled = function() return isDisabled() or (not isPreviewActive() and not cursorRingDB().trailEnabled); end,
                    get = function() return cursorRingDB().trailShrink; end,
                    set = function(val)
                        local d = cursorRingDB();
                        d.trailShrink = val;
                        d.trailStyle = "custom";
                    end,
                },
                {
                    type = "toggle",
                    label = L["CURSORRING_TAPER_DISTANCE"],
                    desc = L["CURSORRING_TAPER_DISTANCE_DESC"],
                    disabled = function() return isDisabled() or (not isPreviewActive() and not cursorRingDB().trailEnabled); end,
                    get = function() return cursorRingDB().trailShrinkDistance; end,
                    set = function(val)
                        local d = cursorRingDB();
                        d.trailShrinkDistance = val;
                        d.trailStyle = "custom";
                    end,
                },
                {
                    type = "select",
                    label = L["CURSORRING_SPARKLE"],
                    desc = L["CURSORRING_SPARKLE_DESC"],
                    values = {
                        off     = L["CURSORRING_SPARKLE_OFF"],
                        static  = L["CURSORRING_SPARKLE_STATIC"],
                        twinkle = L["CURSORRING_SPARKLE_TWINKLE"],
                    },
                    sorting = { "off", "static", "twinkle" },
                    disabled = function() return isDisabled() or (not isPreviewActive() and not cursorRingDB().trailEnabled); end,
                    get = function() return cursorRingDB().trailSparkle or "off"; end,
                    set = function(val) cursorRingDB().trailSparkle = val; end,
                },
                {
                    type = "callout",
                    text = L["CURSORRING_TRAIL_PERF_NOTE"],
                    severity = "info",
                },
            },
        },
    };
end
