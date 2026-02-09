local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local Layout = Lantern.optionsLayout;

local function cursorRingModule()
    return Lantern.modules and Lantern.modules.CursorRing;
end

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
    trailDuration = 0.4,
    trailColor = { r = 1.0, g = 1.0, b = 1.0 },
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

local function isDisabled()
    local m = cursorRingModule();
    return not (m and m.enabled);
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

function Lantern:BuildCursorRingOptions()
    local args = {};

    -- Description
    args.desc = Layout.description(0, "Displays customizable ring(s) around the mouse cursor with cast/GCD indicators and an optional trail. Hold Shift to pause auto-features.");

    -- Enable toggle
    args.enabled = {
        order = 1,
        type = "toggle",
        name = "Enable",
        desc = "Enable or disable the Cursor Ring module.",
        width = "full",
        get = function()
            local m = cursorRingModule();
            return m and m.enabled;
        end,
        set = function(_, val)
            if (val) then
                Lantern:EnableModule("CursorRing");
            else
                Lantern:DisableModule("CursorRing");
            end
        end,
    };

    ---------------------------------------------------------------------------
    -- General
    ---------------------------------------------------------------------------
    args.generalHeader = Layout.header(5, "General");

    args.showOutOfCombat = {
        order = 6.00,
        type = "toggle",
        name = "Show Out of Combat",
        desc = "Show the cursor ring outside of combat and instances.",
        width = "normal",
        disabled = isDisabled,
        get = function() return cursorRingDB().showOutOfCombat; end,
        set = function(_, val)
            cursorRingDB().showOutOfCombat = val;
            refreshModule("UpdateVisibility");
        end,
    };
    args.spacerGeneral1 = Layout.spacer(6.99);

    args.opacityInCombat = {
        order = 7.00,
        type = "range",
        name = "Combat Opacity",
        desc = "Ring opacity while in combat or instanced content.",
        width = "normal",
        min = 0, max = 1, step = 0.05,
        isPercent = true,
        disabled = isDisabled,
        get = function() return cursorRingDB().opacityInCombat; end,
        set = function(_, val)
            cursorRingDB().opacityInCombat = val;
            refreshModule("UpdateVisibility");
        end,
    };

    args.opacityOutOfCombat = {
        order = 7.01,
        type = "range",
        name = "Out of Combat Opacity",
        desc = "Ring opacity outside of combat.",
        width = "normal",
        min = 0, max = 1, step = 0.05,
        isPercent = true,
        disabled = isDisabled,
        get = function() return cursorRingDB().opacityOutOfCombat; end,
        set = function(_, val)
            cursorRingDB().opacityOutOfCombat = val;
            refreshModule("UpdateVisibility");
        end,
    };
    args.spacerGeneral2 = Layout.spacer(7.99);

    ---------------------------------------------------------------------------
    -- Ring 1
    ---------------------------------------------------------------------------
    args.ring1Header = Layout.header(10, "Ring 1 (Outer)");

    args.ring1Enabled = {
        order = 11.00,
        type = "toggle",
        name = "Enable Ring 1",
        desc = "Show the outer ring.",
        width = "normal",
        disabled = isDisabled,
        get = function() return cursorRingDB().ring1Enabled; end,
        set = function(_, val)
            cursorRingDB().ring1Enabled = val;
            refreshModule("UpdateRing", 1);
            refreshModule("UpdateVisibility");
        end,
    };
    args.spacerRing1a = Layout.spacer(11.99);

    args.ring1Shape = {
        order = 12.00,
        type = "select",
        name = "Shape",
        desc = "Ring shape.",
        width = "normal",
        values = shapeValues,
        sorting = shapeSorting,
        disabled = function() return isDisabled() or not cursorRingDB().ring1Enabled; end,
        get = function() return cursorRingDB().ring1Shape; end,
        set = function(_, val)
            cursorRingDB().ring1Shape = val;
            refreshModule("UpdateRing", 1);
            refreshModule("UpdateGCD");
            refreshModule("UpdateCast");
        end,
    };

    args.ring1Color = {
        order = 12.01,
        type = "color",
        name = "Color",
        desc = "Ring 1 color.",
        width = "normal",
        disabled = function() return isDisabled() or not cursorRingDB().ring1Enabled; end,
        get = function()
            local c = cursorRingDB().ring1Color;
            return c.r, c.g, c.b;
        end,
        set = function(_, r, g, b)
            cursorRingDB().ring1Color = { r = r, g = g, b = b };
            refreshModule("UpdateRing", 1);
        end,
    };
    args.spacerRing1b = Layout.spacer(12.99);

    args.ring1Size = {
        order = 13.00,
        type = "range",
        name = "Size",
        desc = "Ring 1 size in pixels.",
        width = "double",
        min = 16, max = 256, step = 2,
        disabled = function() return isDisabled() or not cursorRingDB().ring1Enabled; end,
        get = function() return cursorRingDB().ring1Size; end,
        set = function(_, val)
            cursorRingDB().ring1Size = val;
            refreshModule("UpdateRing", 1);
            refreshModule("UpdateGCD");
            refreshModule("UpdateCast");
        end,
    };

    ---------------------------------------------------------------------------
    -- Ring 2
    ---------------------------------------------------------------------------
    args.ring2Header = Layout.header(20, "Ring 2 (Inner)");

    args.ring2Enabled = {
        order = 21.00,
        type = "toggle",
        name = "Enable Ring 2",
        desc = "Show the inner ring.",
        width = "normal",
        disabled = isDisabled,
        get = function() return cursorRingDB().ring2Enabled; end,
        set = function(_, val)
            cursorRingDB().ring2Enabled = val;
            refreshModule("UpdateRing", 2);
            refreshModule("UpdateVisibility");
        end,
    };
    args.spacerRing2a = Layout.spacer(21.99);

    args.ring2Shape = {
        order = 22.00,
        type = "select",
        name = "Shape",
        desc = "Ring shape.",
        width = "normal",
        values = shapeValues,
        sorting = shapeSorting,
        disabled = function() return isDisabled() or not cursorRingDB().ring2Enabled; end,
        get = function() return cursorRingDB().ring2Shape; end,
        set = function(_, val)
            cursorRingDB().ring2Shape = val;
            refreshModule("UpdateRing", 2);
        end,
    };

    args.ring2Color = {
        order = 22.01,
        type = "color",
        name = "Color",
        desc = "Ring 2 color.",
        width = "normal",
        disabled = function() return isDisabled() or not cursorRingDB().ring2Enabled; end,
        get = function()
            local c = cursorRingDB().ring2Color;
            return c.r, c.g, c.b;
        end,
        set = function(_, r, g, b)
            cursorRingDB().ring2Color = { r = r, g = g, b = b };
            refreshModule("UpdateRing", 2);
        end,
    };
    args.spacerRing2b = Layout.spacer(22.99);

    args.ring2Size = {
        order = 23.00,
        type = "range",
        name = "Size",
        desc = "Ring 2 size in pixels.",
        width = "double",
        min = 16, max = 256, step = 2,
        disabled = function() return isDisabled() or not cursorRingDB().ring2Enabled; end,
        get = function() return cursorRingDB().ring2Size; end,
        set = function(_, val)
            cursorRingDB().ring2Size = val;
            refreshModule("UpdateRing", 2);
        end,
    };

    ---------------------------------------------------------------------------
    -- Center Dot
    ---------------------------------------------------------------------------
    args.dotHeader = Layout.header(25, "Center Dot");

    args.dotEnabled = {
        order = 26.00,
        type = "toggle",
        name = "Enable Dot",
        desc = "Show a small dot at the center of the cursor rings.",
        width = "normal",
        disabled = isDisabled,
        get = function() return cursorRingDB().dotEnabled; end,
        set = function(_, val)
            cursorRingDB().dotEnabled = val;
            refreshModule("UpdateDot");
            refreshModule("UpdateVisibility");
        end,
    };
    args.spacerDot1 = Layout.spacer(26.99);

    args.dotColor = {
        order = 27.00,
        type = "color",
        name = "Color",
        desc = "Dot color.",
        width = "normal",
        disabled = function() return isDisabled() or not cursorRingDB().dotEnabled; end,
        get = function()
            local c = cursorRingDB().dotColor;
            return c.r, c.g, c.b;
        end,
        set = function(_, r, g, b)
            cursorRingDB().dotColor = { r = r, g = g, b = b };
            refreshModule("UpdateDot");
        end,
    };

    args.dotSize = {
        order = 27.01,
        type = "range",
        name = "Size",
        desc = "Dot size in pixels.",
        width = "normal",
        min = 2, max = 24, step = 1,
        disabled = function() return isDisabled() or not cursorRingDB().dotEnabled; end,
        get = function() return cursorRingDB().dotSize; end,
        set = function(_, val)
            cursorRingDB().dotSize = val;
            refreshModule("UpdateDot");
        end,
    };

    ---------------------------------------------------------------------------
    -- Cast Effect
    ---------------------------------------------------------------------------
    args.castHeader = Layout.header(30, "Cast Effect");

    args.castEnabled = {
        order = 31.00,
        type = "toggle",
        name = "Enable Cast Effect",
        desc = "Show a visual effect during spell casting and channeling.",
        width = "normal",
        disabled = isDisabled,
        get = function() return cursorRingDB().castEnabled; end,
        set = function(_, val)
            cursorRingDB().castEnabled = val;
        end,
    };
    args.spacerCast1 = Layout.spacer(31.99);

    args.castStyle = {
        order = 32.00,
        type = "select",
        name = "Style",
        desc = "Segments: arc lights up progressively. Fill: shape scales from center. Swipe: cooldown sweep (can run simultaneously with GCD).",
        width = "normal",
        values = castStyleValues,
        sorting = castStyleSorting,
        disabled = function() return isDisabled() or not cursorRingDB().castEnabled; end,
        get = function() return cursorRingDB().castStyle; end,
        set = function(_, val)
            cursorRingDB().castStyle = val;
            refreshModule("UpdateCast");
        end,
    };

    args.castColor = {
        order = 32.01,
        type = "color",
        name = "Color",
        desc = "Cast effect color.",
        width = "normal",
        disabled = function() return isDisabled() or not cursorRingDB().castEnabled; end,
        get = function()
            local c = cursorRingDB().castColor;
            return c.r, c.g, c.b;
        end,
        set = function(_, r, g, b)
            cursorRingDB().castColor = { r = r, g = g, b = b };
            refreshModule("UpdateCast");
        end,
    };
    args.spacerCast2 = Layout.spacer(32.99);

    args.castOffset = {
        order = 33.00,
        type = "range",
        name = "Swipe Offset",
        desc = "Pixel offset for the cast swipe ring outside the GCD ring. Only applies to Swipe style.",
        width = "double",
        min = 0, max = 32, step = 1,
        disabled = function() return isDisabled() or not cursorRingDB().castEnabled or cursorRingDB().castStyle ~= "swipe"; end,
        get = function() return cursorRingDB().castOffset; end,
        set = function(_, val)
            cursorRingDB().castOffset = val;
            refreshModule("UpdateCast");
        end,
    };

    ---------------------------------------------------------------------------
    -- GCD
    ---------------------------------------------------------------------------
    args.gcdHeader = Layout.header(40, "GCD Indicator");

    args.gcdEnabled = {
        order = 41.00,
        type = "toggle",
        name = "Enable GCD",
        desc = "Show a cooldown swipe for the global cooldown.",
        width = "normal",
        disabled = isDisabled,
        get = function() return cursorRingDB().gcdEnabled; end,
        set = function(_, val)
            cursorRingDB().gcdEnabled = val;
            refreshModule("SetGCDEnabled", val);
            refreshModule("UpdateGCD");
        end,
    };
    args.spacerGCD1 = Layout.spacer(41.99);

    args.gcdColor = {
        order = 42.00,
        type = "color",
        name = "Color",
        desc = "GCD swipe color.",
        width = "normal",
        disabled = function() return isDisabled() or not cursorRingDB().gcdEnabled; end,
        get = function()
            local c = cursorRingDB().gcdColor;
            return c.r, c.g, c.b;
        end,
        set = function(_, r, g, b)
            cursorRingDB().gcdColor = { r = r, g = g, b = b };
            refreshModule("UpdateGCD");
        end,
    };

    args.gcdOffset = {
        order = 42.01,
        type = "range",
        name = "Offset",
        desc = "Pixel offset for the GCD ring outside Ring 1.",
        width = "normal",
        min = 0, max = 32, step = 1,
        disabled = function() return isDisabled() or not cursorRingDB().gcdEnabled; end,
        get = function() return cursorRingDB().gcdOffset; end,
        set = function(_, val)
            cursorRingDB().gcdOffset = val;
            refreshModule("UpdateGCD");
            refreshModule("UpdateCast");
        end,
    };

    ---------------------------------------------------------------------------
    -- Trail
    ---------------------------------------------------------------------------
    args.trailHeader = Layout.header(50, "Mouse Trail");

    args.trailEnabled = {
        order = 51.00,
        type = "toggle",
        name = "Enable Trail",
        desc = "Show a fading trail behind the cursor.",
        width = "normal",
        disabled = isDisabled,
        get = function() return cursorRingDB().trailEnabled; end,
        set = function(_, val)
            cursorRingDB().trailEnabled = val;
            refreshModule("EnsureTrail");
        end,
    };
    args.trailNote = Layout.description(51.50, "The mouse trail may have a noticeable impact on performance, especially on lower-end systems.");
    args.spacerTrail1 = Layout.spacer(51.99);

    args.trailColor = {
        order = 52.00,
        type = "color",
        name = "Color",
        desc = "Trail color.",
        width = "normal",
        disabled = function() return isDisabled() or not cursorRingDB().trailEnabled; end,
        get = function()
            local c = cursorRingDB().trailColor;
            return c.r, c.g, c.b;
        end,
        set = function(_, r, g, b)
            cursorRingDB().trailColor = { r = r, g = g, b = b };
        end,
    };

    args.trailDuration = {
        order = 52.01,
        type = "range",
        name = "Duration",
        desc = "How long trail points last before fading.",
        width = "normal",
        min = 0.1, max = 2.0, step = 0.05,
        disabled = function() return isDisabled() or not cursorRingDB().trailEnabled; end,
        get = function() return cursorRingDB().trailDuration; end,
        set = function(_, val)
            cursorRingDB().trailDuration = val;
        end,
    };

    ---------------------------------------------------------------------------
    -- Preview
    ---------------------------------------------------------------------------
    args.previewHeader = Layout.header(60, "Preview");

    args.previewDesc = Layout.description(60.5, "Use these buttons to test the cast and GCD animations without being in combat.");

    args.testCast = {
        order = 61.00,
        type = "execute",
        name = "Test Cast",
        desc = "Simulate a 2.5 second cast.",
        width = "normal",
        disabled = function() return isDisabled() or not cursorRingDB().castEnabled; end,
        func = function()
            refreshModule("SetPreviewMode", true);
            refreshModule("TestCast", 2.5);
        end,
    };

    args.testGCD = {
        order = 61.01,
        type = "execute",
        name = "Test GCD",
        desc = "Simulate a 1.5 second GCD.",
        width = "normal",
        disabled = function() return isDisabled() or not cursorRingDB().gcdEnabled; end,
        func = function()
            refreshModule("SetPreviewMode", true);
            refreshModule("TestGCD", 1.5);
        end,
    };
    args.spacerPreview = Layout.spacer(61.99);

    args.testBoth = {
        order = 62.00,
        type = "execute",
        name = "Test Both",
        desc = "Simulate a GCD + cast simultaneously.",
        width = "normal",
        disabled = function()
            local db = cursorRingDB();
            return isDisabled() or (not db.castEnabled and not db.gcdEnabled);
        end,
        func = function()
            refreshModule("SetPreviewMode", true);
            refreshModule("TestBoth");
        end,
    };

    return args;
end
