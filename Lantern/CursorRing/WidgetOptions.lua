local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local LanternUX = _G.LanternUX;
local T = LanternUX and LanternUX.Theme;
if (not T) then return; end

local module = Lantern.modules["CursorRing"];
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
        ring = "Circle",
        thin_ring = "Thin Circle",
    };
    local shapeSorting = { "ring", "thin_ring" };

    local castStyleValues = {
        segments = "Segments",
        fill = "Fill",
        swipe = "Swipe",
    };
    local castStyleSorting = { "segments", "fill", "swipe" };

    return {
        -- Enable
        moduleToggle("CursorRing", "Enable", "Enable or disable the Cursor Ring & Trail module."),

        -- Preview
        {
            type = "toggle",
            label = "Preview",
            desc = "Show all visual elements on the cursor for real-time editing. Automatically disables when the settings panel is closed.",
            disabled = isDisabled,
            get = function() return isPreviewActive(); end,
            set = function(val) refreshModule("SetPreviewMode", val); end,
        },

        -----------------------------------------------------------------------
        -- General
        -----------------------------------------------------------------------
        {
            type = "group",
            text = "General",
            expanded = true,
            children = {
                {
                    type = "toggle",
                    label = "Show Out of Combat",
                    desc = "Show the cursor ring outside of combat and instances.",
                    disabled = isDisabled,
                    get = function() return cursorRingDB().showOutOfCombat; end,
                    set = function(val)
                        cursorRingDB().showOutOfCombat = val;
                        refreshModule("UpdateVisibility");
                    end,
                },
                {
                    type = "range",
                    label = "Combat Opacity",
                    desc = "Ring opacity while in combat or instanced content.",
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
                    label = "Out of Combat Opacity",
                    desc = "Ring opacity outside of combat.",
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
            text = "Ring 1 (Outer)",
            children = {
                {
                    type = "toggle",
                    label = "Enable Ring 1",
                    desc = "Show the outer ring.",
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
                    label = "Shape",
                    desc = "Ring shape.",
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
                    label = "Color",
                    desc = "Ring 1 color.",
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
                    label = "Size",
                    desc = "Ring 1 size in pixels.",
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
            text = "Ring 2 (Inner)",
            children = {
                {
                    type = "toggle",
                    label = "Enable Ring 2",
                    desc = "Show the inner ring.",
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
                    label = "Shape",
                    desc = "Ring shape.",
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
                    label = "Color",
                    desc = "Ring 2 color.",
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
                    label = "Size",
                    desc = "Ring 2 size in pixels.",
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
            text = "Center Dot",
            children = {
                {
                    type = "toggle",
                    label = "Enable Dot",
                    desc = "Show a small dot at the center of the cursor rings.",
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
                    label = "Color",
                    desc = "Dot color.",
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
                    label = "Size",
                    desc = "Dot size in pixels.",
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
            text = "Cast Effect",
            children = {
                {
                    type = "toggle",
                    label = "Enable Cast Effect",
                    desc = "Show a visual effect during spell casting and channeling.",
                    disabled = isDisabled,
                    get = function() return cursorRingDB().castEnabled; end,
                    set = function(val)
                        cursorRingDB().castEnabled = val;
                    end,
                },
                {
                    type = "select",
                    label = "Style",
                    desc = "Segments: arc lights up progressively. Fill: shape scales from center. Swipe: cooldown sweep (can run simultaneously with GCD).",
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
                    label = "Color",
                    desc = "Cast effect color.",
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
                    label = "Swipe Offset",
                    desc = "Pixel offset for the cast swipe ring outside the GCD ring. Only applies to Swipe style.",
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
            text = "GCD Indicator",
            children = {
                {
                    type = "toggle",
                    label = "Enable GCD",
                    desc = "Show a cooldown swipe for the global cooldown.",
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
                    label = "Color",
                    desc = "GCD swipe color.",
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
                    label = "Offset",
                    desc = "Pixel offset for the GCD ring outside Ring 1.",
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
            text = "Mouse Trail",
            children = {
                {
                    type = "toggle",
                    label = "Enable Trail",
                    desc = "Show a fading trail behind the cursor.",
                    disabled = isDisabled,
                    get = function() return cursorRingDB().trailEnabled; end,
                    set = function(val)
                        cursorRingDB().trailEnabled = val;
                        refreshModule("EnsureTrail");
                    end,
                },
                {
                    type = "select",
                    label = "Style",
                    desc = "Trail display style. Glow: fading sparkly trail. Line: continuous thin ribbon. Thick Line: wide ribbon. Dots: spaced-out fading dots. Custom: manual settings.",
                    values = {
                        glow = "Glow",
                        line = "Line",
                        thickline = "Thick Line",
                        dots = "Dots",
                        custom = "Custom",
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
                        if (panel and panel.refreshPage) then panel:refreshPage(); end
                    end,
                },
                {
                    type = "select",
                    label = "Color",
                    desc = "Trail color preset. Class Color uses your current class color automatically. Rainbow, Ember, and Ocean are multi-color gradients. Custom lets you pick any color below.",
                    values = {
                        custom  = "Custom",
                        class   = "Class Color",
                        gold    = "Lantern Gold",
                        arcane  = "Arcane",
                        fel     = "Fel",
                        fire    = "Fire",
                        frost   = "Frost",
                        holy    = "Holy",
                        shadow  = "Shadow",
                        rainbow = "Rainbow",
                        ember   = "Ember",
                        ocean   = "Ocean",
                    },
                    sorting = { "custom", "class", "gold", "arcane", "fel", "fire", "frost", "holy", "shadow", "rainbow", "ember", "ocean" },
                    disabled = function() return isDisabled() or (not isPreviewActive() and not cursorRingDB().trailEnabled); end,
                    get = function() return cursorRingDB().trailColorPreset or "custom"; end,
                    set = function(val)
                        cursorRingDB().trailColorPreset = val;
                        local panel = Lantern._uxPanel;
                        if (panel and panel.refreshPage) then panel:refreshPage(); end
                    end,
                },
                {
                    type = "color",
                    label = "Custom Color",
                    desc = "Trail color (only used when Color is set to Custom).",
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
                    label = "Duration",
                    desc = "How long trail points last before fading.",
                    min = 0.1, max = 2.0, step = 0.05, default = 0.4,
                    disabled = function() return isDisabled() or (not isPreviewActive() and not cursorRingDB().trailEnabled); end,
                    get = function() return cursorRingDB().trailDuration; end,
                    set = function(val)
                        cursorRingDB().trailDuration = val;
                    end,
                },
                {
                    type = "range",
                    label = "Max Points",
                    desc = "Number of trail dots in the pool. Higher values create longer trails but use more memory.",
                    min = 5, max = 200, step = 1, default = 20,
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
                    label = "Dot Size",
                    desc = "Size of each trail dot in pixels.",
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
                    label = "Dot Spacing",
                    desc = "Minimum distance in pixels before a new trail dot is placed. Lower values create a denser, more continuous trail.",
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
                    label = "Shrink with Age",
                    desc = "Trail dots shrink as they fade out. Disable for a uniform-width trail.",
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
                    label = "Taper with Distance",
                    desc = "Trail dots shrink and fade toward the tail, creating a tapered brush-stroke effect.",
                    disabled = function() return isDisabled() or (not isPreviewActive() and not cursorRingDB().trailEnabled); end,
                    get = function() return cursorRingDB().trailShrinkDistance; end,
                    set = function(val)
                        local d = cursorRingDB();
                        d.trailShrinkDistance = val;
                        d.trailStyle = "custom";
                    end,
                },
            },
        },
    };
end
