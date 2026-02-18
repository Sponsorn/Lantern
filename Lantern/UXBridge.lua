local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end
local LanternUX = _G.LanternUX;
if (not LanternUX or not LanternUX.CreatePanel) then return; end

local T = LanternUX.Theme;
if (not T) then return; end

-------------------------------------------------------------------------------
-- Core module mapping
-------------------------------------------------------------------------------

local CORE_KEY = {
    AutoQuest            = "autoQuest",
    AutoQueue            = "autoQueue",
    CursorRing           = "cursorRing",
    DeleteConfirm        = "deleteConfirm",
    DisableAutoAddSpells = "disableAutoAddSpells",
    InterruptTracker     = "interruptTracker",
    MissingPet           = "missingPet",
};

local CORE_ORDER = {
    "AutoQuest", "AutoQueue", "CursorRing",
    "DeleteConfirm", "DisableAutoAddSpells", "InterruptTracker", "MissingPet",
};

local QUICK_SETTINGS = {
    autoQueue = true,
    deleteConfirm = true,
    disableAutoAddSpells = true,
};

-------------------------------------------------------------------------------
-- Custom option definitions
-------------------------------------------------------------------------------

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

local CUSTOM_OPTIONS = {};

CUSTOM_OPTIONS["general"] = function()
    return {
        {
            type = "toggle",
            label = "Show minimap icon",
            desc = "Show or hide the Lantern minimap button.",
            get = function() return not (Lantern.db.minimap and Lantern.db.minimap.hide); end,
            set = function(val) Lantern:ToggleMinimapIcon(val); end,
        },
    };
end

CUSTOM_OPTIONS["deleteConfirm"] = function()
    return {
        moduleToggle("DeleteConfirm", "Enable", "Replace typing DELETE with a confirm button (Shift pauses)."),
    };
end

CUSTOM_OPTIONS["disableAutoAddSpells"] = function()
    return {
        moduleToggle("DisableAutoAddSpells", "Enable", "Disable auto-adding spells to the action bar."),
    };
end

-------------------------------------------------------------------------------
-- InterruptTracker custom options
-------------------------------------------------------------------------------

CUSTOM_OPTIONS["interruptTracker"] = function()
    local DEFAULTS = {
        displayMode     = "bar",
        locked          = false,
        barWidth        = 220,
        barHeight       = 28,
        barAlpha        = 0.9,
        growUp          = false,
        showSelf        = true,
        sortMode        = "remaining",
        selfOnTop       = false,
        font            = "Friz Quadrata TT",
        fontOutline     = "OUTLINE",
    };

    local function itDB()
        if (not Lantern.db) then Lantern.db = {}; end
        if (not Lantern.db.interruptTracker) then Lantern.db.interruptTracker = {}; end
        local db = Lantern.db.interruptTracker;
        for k, v in pairs(DEFAULTS) do
            if (db[k] == nil) then
                db[k] = v;
            end
        end
        return db;
    end

    local function itModule()
        return Lantern.modules and Lantern.modules.InterruptTracker;
    end

    local function isDisabled()
        return not moduleEnabled("InterruptTracker");
    end

    local function isBarModeDisabled()
        return isDisabled() or itDB().displayMode ~= "bar";
    end

    local function isPreviewActive()
        local m = itModule();
        return m and m.IsPreviewActive and m:IsPreviewActive() or false;
    end

    local function refreshModule(method, ...)
        local m = itModule();
        if (m and m[method]) then
            m[method](m, ...);
        end
    end

    local displayModeValues = {
        bar = "Bar",
        minimal = "Minimal",
    };
    local displayModeSorting = { "bar", "minimal" };

    local sortModeValues = {
        remaining = "Lowest Remaining CD",
        basecd = "Lowest Base CD",
    };
    local sortModeSorting = { "remaining", "basecd" };

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

    local function refreshFont()
        refreshModule("RefreshFont");
    end

    return {
        -- Enable
        moduleToggle("InterruptTracker", "Enable", "Enable or disable the Interrupt Tracker."),

        -- Preview
        {
            type = "toggle",
            label = "Preview",
            desc = "Show the tracker with simulated party data for positioning and testing.",
            disabled = isDisabled,
            get = function() return isPreviewActive(); end,
            set = function(val) refreshModule("SetPreviewMode", val); end,
        },

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
                    desc = "Bar: class-colored cooldown bars with icons. Minimal: compact rows with icon, name, and status.",
                    values = displayModeValues,
                    sorting = displayModeSorting,
                    disabled = isDisabled,
                    get = function() return itDB().displayMode; end,
                    set = function(val)
                        itDB().displayMode = val;
                        refreshModule("SetDisplayMode", val);
                    end,
                },
                {
                    type = "toggle",
                    label = "Show Self",
                    desc = "Include your own interrupt in the tracker display.",
                    disabled = isDisabled,
                    get = function() return itDB().showSelf; end,
                    set = function(val)
                        itDB().showSelf = val;
                        refreshModule("RefreshDisplay");
                    end,
                },
            },
        },

        -----------------------------------------------------------------------
        -- Sorting
        -----------------------------------------------------------------------
        {
            type = "group",
            text = "Sorting",
            children = {
                {
                    type = "select",
                    label = "Sort By",
                    desc = "Lowest Remaining CD: players closest to being ready appear first. Lowest Base CD: players with shorter kick cooldowns always appear first.",
                    values = sortModeValues,
                    sorting = sortModeSorting,
                    disabled = isDisabled,
                    get = function() return itDB().sortMode; end,
                    set = function(val)
                        itDB().sortMode = val;
                        refreshModule("RefreshDisplay");
                    end,
                },
                {
                    type = "toggle",
                    label = "Self Always On Top",
                    desc = "Always show your own interrupt at the top of the list, regardless of sort order.",
                    disabled = isDisabled,
                    get = function() return itDB().selfOnTop; end,
                    set = function(val)
                        itDB().selfOnTop = val;
                        refreshModule("RefreshDisplay");
                    end,
                },
            },
        },

        -----------------------------------------------------------------------
        -- Bar Mode
        -----------------------------------------------------------------------
        {
            type = "group",
            text = "Bar Mode",
            children = {
                {
                    type = "range",
                    label = "Width",
                    desc = "Width of the bar display.",
                    min = 120, max = 400, step = 1,
                    disabled = isBarModeDisabled,
                    get = function() return itDB().barWidth; end,
                    set = function(val)
                        itDB().barWidth = val;
                        refreshModule("RefreshDisplay");
                    end,
                },
                {
                    type = "range",
                    label = "Height",
                    desc = "Height of each bar.",
                    min = 16, max = 40, step = 1,
                    disabled = isBarModeDisabled,
                    get = function() return itDB().barHeight; end,
                    set = function(val)
                        itDB().barHeight = val;
                        refreshModule("RefreshDisplay");
                    end,
                },
                {
                    type = "range",
                    label = "Opacity",
                    desc = "Opacity of the tracker frame.",
                    min = 0.3, max = 1.0, step = 0.05,
                    isPercent = true,
                    disabled = isBarModeDisabled,
                    get = function() return itDB().barAlpha; end,
                    set = function(val)
                        itDB().barAlpha = val;
                        refreshModule("RefreshDisplay");
                    end,
                },
                {
                    type = "toggle",
                    label = "Grow Upward",
                    desc = "Bars grow upward from the anchor point instead of downward.",
                    disabled = isBarModeDisabled,
                    get = function() return itDB().growUp; end,
                    set = function(val)
                        itDB().growUp = val;
                        refreshModule("RefreshDisplay");
                    end,
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
                    desc = "Select the font for the tracker text.",
                    values = getFontValues,
                    disabled = isDisabled,
                    get = function() return itDB().font or "Friz Quadrata TT"; end,
                    set = function(val) itDB().font = val; refreshFont(); end,
                },
                {
                    type = "select",
                    label = "Font Outline",
                    desc = "Outline style for the tracker text.",
                    values = outlineValues,
                    sorting = outlineSorting,
                    disabled = isDisabled,
                    get = function() return itDB().fontOutline or "OUTLINE"; end,
                    set = function(val) itDB().fontOutline = val; refreshFont(); end,
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
                    desc = "When locked, the frames cannot be moved. Hold Shift to move even when locked.",
                    disabled = isDisabled,
                    get = function() return itDB().locked; end,
                    set = function(val) itDB().locked = val; refreshModule("RefreshDisplay"); end,
                },
                {
                    type = "execute",
                    label = "Reset Bar Position",
                    desc = "Reset the bar mode frame position to center of screen.",
                    disabled = isDisabled,
                    func = function() refreshModule("ResetBarPosition"); end,
                },
                {
                    type = "execute",
                    label = "Reset Minimal Position",
                    desc = "Reset the minimal mode frame position to center of screen.",
                    disabled = isDisabled,
                    func = function() refreshModule("ResetCompactPosition"); end,
                },
            },
        },
    };
end

CUSTOM_OPTIONS["autoQueue"] = function()
    local function db()
        Lantern.db.autoQueue = Lantern.db.autoQueue or {};
        local defaults = { active = true, announce = true };
        for k, v in pairs(defaults) do
            if (Lantern.db.autoQueue[k] == nil) then
                Lantern.db.autoQueue[k] = v;
            end
        end
        return Lantern.db.autoQueue;
    end

    local isDisabled = function()
        return not moduleEnabled("AutoQueue");
    end

    return {
        moduleToggle("AutoQueue", "Enable", "Enable or disable Auto Queue."),
        {
            type = "toggle",
            label = "Auto-accept role checks",
            desc = "Accept LFG role checks automatically (Shift pauses).",
            disabled = isDisabled,
            get = function() return db().active; end,
            set = function(val) db().active = val and true or false; end,
        },
        {
            type = "toggle",
            label = "Chat announce",
            desc = "Print a chat message when a role check is auto-accepted.",
            disabled = isDisabled,
            get = function() return db().announce; end,
            set = function(val) db().announce = val and true or false; end,
        },
        {
            type = "description",
            text = "Roles are set in the LFG tool. This will accept the role check using your current selection.",
            fontSize = "small",
            color = T.textDim,
        },
    };
end

-------------------------------------------------------------------------------
-- CursorRing custom options
-------------------------------------------------------------------------------

CUSTOM_OPTIONS["cursorRing"] = function()
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
        moduleToggle("CursorRing", "Enable", "Enable or disable the Cursor Ring module."),

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
                    min = 0, max = 1, step = 0.05,
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
                    min = 0, max = 1, step = 0.05,
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
                    min = 16, max = 80, step = 0.01, bigStep = 2,
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
                    min = 16, max = 80, step = 0.01, bigStep = 2,
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
                    min = 2, max = 24, step = 1,
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
                    min = 0, max = 32, step = 0.01, bigStep = 0.5,
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
                    min = 0, max = 32, step = 0.01, bigStep = 0.5,
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
                    type = "description",
                    text = "The mouse trail may have a noticeable impact on performance, especially on lower-end systems.",
                    fontSize = "small",
                    color = T.textDim,
                },
                {
                    type = "color",
                    label = "Color",
                    desc = "Trail color.",
                    disabled = function() return isDisabled() or (not isPreviewActive() and not cursorRingDB().trailEnabled); end,
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
                    min = 0.1, max = 2.0, step = 0.05,
                    disabled = function() return isDisabled() or (not isPreviewActive() and not cursorRingDB().trailEnabled); end,
                    get = function() return cursorRingDB().trailDuration; end,
                    set = function(val)
                        cursorRingDB().trailDuration = val;
                    end,
                },
            },
        },
    };
end

-------------------------------------------------------------------------------
-- Create panel
-------------------------------------------------------------------------------

local panel = LanternUX:CreatePanel({
    name    = "LanternSettingsPanel",
    title   = "Lantern",
    icon    = "Interface\\AddOns\\Lantern\\Media\\Images\\Icons\\lantern-core-icon64.blp",
    version = C_AddOns and C_AddOns.GetAddOnMetadata("Lantern", "Version") or "",
});

Lantern._uxPanel = panel;

-------------------------------------------------------------------------------
-- AutoQuest custom options
-------------------------------------------------------------------------------

CUSTOM_OPTIONS["autoQuest"] = function()
    local function db()
        Lantern.db.autoQuest = Lantern.db.autoQuest or {};
        local defaults = { autoAccept = true, autoTurnIn = true, autoSelectSingleReward = true, skipTrivialQuests = false };
        for k, v in pairs(defaults) do
            if (Lantern.db.autoQuest[k] == nil) then
                Lantern.db.autoQuest[k] = v;
            end
        end
        if (type(Lantern.db.autoQuest.blockedNPCs) ~= "table") then
            Lantern.db.autoQuest.blockedNPCs = {};
        end
        if (type(Lantern.db.autoQuest.blockedQuests) ~= "table") then
            Lantern.db.autoQuest.blockedQuests = {};
        end
        if (type(Lantern.db.autoQuest.blockedQuestNames) ~= "table") then
            Lantern.db.autoQuest.blockedQuestNames = {};
        end
        if (type(Lantern.db.autoQuest.recentAutomated) ~= "table") then
            Lantern.db.autoQuest.recentAutomated = {};
        end
        return Lantern.db.autoQuest;
    end

    local isDisabled = function()
        return not moduleEnabled("AutoQuest");
    end

    local function getModule()
        return Lantern.modules and Lantern.modules.AutoQuest;
    end

    local function refreshPage()
        if (panel and panel.RefreshCurrentPage) then
            panel:RefreshCurrentPage();
        end
    end

    local function getCurrentZone()
        return Lantern.utils and Lantern.utils.GetCurrentZoneName
            and Lantern.utils.GetCurrentZoneName() or nil;
    end

    local function extractZone(key)
        return key and key:match("^.+%s%-%s(.+)$") or nil;
    end

    local function buildZoneValues(sourceTable, isQuestMode)
        local opts = { all = "All zones", current = "Current zone" };
        if (isQuestMode) then
            for _, entry in pairs(sourceTable) do
                if (type(entry) == "table" and entry.npcKey) then
                    local zone = extractZone(entry.npcKey);
                    if (zone and zone ~= "") then opts[zone] = zone; end
                end
            end
        else
            for key in pairs(sourceTable) do
                local zone = extractZone(key);
                if (zone and zone ~= "") then opts[zone] = zone; end
            end
        end
        return opts;
    end

    local function buildZoneSorting(sourceTable, isQuestMode)
        local zones, seen = {}, {};
        if (isQuestMode) then
            for _, entry in pairs(sourceTable) do
                if (type(entry) == "table" and entry.npcKey) then
                    local zone = extractZone(entry.npcKey);
                    if (zone and zone ~= "" and not seen[zone]) then
                        seen[zone] = true;
                        table.insert(zones, zone);
                    end
                end
            end
        else
            for key in pairs(sourceTable) do
                local zone = extractZone(key);
                if (zone and zone ~= "" and not seen[zone]) then
                    seen[zone] = true;
                    table.insert(zones, zone);
                end
            end
        end
        table.sort(zones);
        local order = { "all", "current" };
        for _, zone in ipairs(zones) do table.insert(order, zone); end
        return order;
    end

    local function resolveFilterZone(filterKey)
        if (filterKey == "all") then return nil; end
        if (filterKey == "current") then return getCurrentZone() or ""; end
        return filterKey;
    end

    local function isQuestBlockedById(id)
        if (not id) then return false; end
        local d = db();
        return d.blockedQuests[tostring(id)] ~= nil or d.blockedQuests[tonumber(id) or id] ~= nil;
    end

    local widgets = {};

    ---------------------------------------------------------------------------
    -- Toggles
    ---------------------------------------------------------------------------
    table.insert(widgets, moduleToggle("AutoQuest", "Enable", "Enable or disable Auto Quest."));
    table.insert(widgets, {
        type = "toggle",
        label = "Auto-accept quests",
        desc = "Automatically accept quests from NPCs.",
        disabled = isDisabled,
        get = function() return db().autoAccept; end,
        set = function(val) db().autoAccept = val and true or false; end,
    });
    table.insert(widgets, {
        type = "toggle",
        label = "Auto turn-in quests",
        desc = "Automatically turn in completed quests to NPCs.",
        disabled = isDisabled,
        get = function() return db().autoTurnIn; end,
        set = function(val) db().autoTurnIn = val and true or false; end,
    });
    table.insert(widgets, {
        type = "toggle",
        label = "Auto select single reward",
        desc = "If a quest offers only one reward, auto-select it.",
        disabled = isDisabled,
        get = function() return db().autoSelectSingleReward; end,
        set = function(val) db().autoSelectSingleReward = val and true or false; end,
    });
    table.insert(widgets, {
        type = "toggle",
        label = "Skip trivial quests",
        desc = "Don't auto-accept quests that are gray (trivial/low-level).",
        disabled = isDisabled,
        get = function() return db().skipTrivialQuests; end,
        set = function(val) db().skipTrivialQuests = val and true or false; end,
    });
    table.insert(widgets, {
        type = "description",
        text = "Hold Shift to temporarily pause auto-accept and auto turn-in.",
        fontSize = "small",
        color = T.textDim,
    });

    ---------------------------------------------------------------------------
    -- Blocked NPCs
    ---------------------------------------------------------------------------
    local d = db();
    table.insert(widgets, { type = "header", text = "Blocked NPCs" });
    table.insert(widgets, {
        type = "description",
        text = "Note: other quest automation addons (QuickQuest, Plumber, etc.) may bypass the blocklist.",
        fontSize = "small",
        color = T.textDim,
    });
    table.insert(widgets, {
        type = "execute",
        label = "Add current NPC to blocklist",
        desc = "Talk to an NPC, then click this button to block them from auto-quest automation.",
        disabled = isDisabled,
        func = function()
            local m = getModule();
            if (not m or not m.GetCurrentNPCKey) then return; end
            local key = m:GetCurrentNPCKey();
            if (not key) then
                Lantern:Print("No NPC found. Talk to an NPC first.");
                return;
            end
            db().blockedNPCs[key] = true;
            Lantern:Print("Blocked NPC: " .. key);
            refreshPage();
        end,
    });
    table.insert(widgets, {
        type = "select",
        label = "Zone filter",
        desc = "Filter blocked NPCs by zone.",
        disabled = isDisabled,
        values = function() return buildZoneValues(db().blockedNPCs, false); end,
        sorting = function() return buildZoneSorting(db().blockedNPCs, false); end,
        get = function()
            local f = db().blockedNPCFilter;
            return (f == nil) and "current" or f;
        end,
        set = function(val)
            db().blockedNPCFilter = val;
            refreshPage();
        end,
    });

    -- Build filtered NPC list
    local npcFilter = db().blockedNPCFilter;
    if (npcFilter == nil) then npcFilter = "current"; end
    local showAllNPCs = (npcFilter == "all");
    local npcFilterZone = resolveFilterZone(npcFilter);
    local npcKeys = {};
    for key in pairs(d.blockedNPCs) do
        if (showAllNPCs) then
            table.insert(npcKeys, key);
        else
            local zone = extractZone(key);
            if (npcFilterZone == "" or zone == npcFilterZone) then
                table.insert(npcKeys, key);
            end
        end
    end
    table.sort(npcKeys);

    if (#npcKeys == 0) then
        local emptyMsg = (showAllNPCs or npcFilterZone == "")
            and "No NPCs are blocked."
            or ("No NPCs are blocked in " .. (npcFilterZone or "") .. ".");
        table.insert(widgets, {
            type = "description",
            text = emptyMsg,
            fontSize = "small",
            color = T.textDim,
        });
    else
        for _, key in ipairs(npcKeys) do
            table.insert(widgets, {
                type = "label_action",
                text = key,
                buttonLabel = "Remove",
                desc = "Remove " .. key .. " from the blocklist.",
                confirm = "Remove?",
                disabled = isDisabled,
                func = function()
                    db().blockedNPCs[key] = nil;
                    refreshPage();
                end,
            });
        end
    end

    ---------------------------------------------------------------------------
    -- Blocked Quests
    ---------------------------------------------------------------------------
    table.insert(widgets, { type = "header", text = "Blocked Quests" });
    table.insert(widgets, {
        type = "description",
        text = "Blocked quests won't be auto-accepted or auto-turned in.",
        fontSize = "small",
        color = T.textDim,
    });
    table.insert(widgets, {
        type = "select",
        label = "Zone filter",
        desc = "Filter blocked quests by zone.",
        disabled = isDisabled,
        values = function() return buildZoneValues(db().blockedQuests, true); end,
        sorting = function() return buildZoneSorting(db().blockedQuests, true); end,
        get = function()
            local f = db().blockedQuestFilter;
            return (f == nil) and "current" or f;
        end,
        set = function(val)
            db().blockedQuestFilter = val;
            refreshPage();
        end,
    });

    -- Build filtered quest list grouped by NPC
    local questFilter = db().blockedQuestFilter;
    if (questFilter == nil) then questFilter = "current"; end
    local showAllQuests = (questFilter == "all");
    local questFilterZone = resolveFilterZone(questFilter);

    local filteredEntries = {};
    for id, raw in pairs(d.blockedQuests) do
        local name, npcKey;
        if (type(raw) == "table") then
            name = raw.name;
            npcKey = raw.npcKey;
        elseif (type(raw) == "string") then
            name = raw;
        end
        local zone = npcKey and extractZone(npcKey) or nil;
        if (showAllQuests or (zone and zone == questFilterZone) or (not zone and (questFilterZone == "" or showAllQuests))) then
            table.insert(filteredEntries, { id = id, name = name, npcKey = npcKey });
        end
    end

    if (#filteredEntries == 0) then
        local emptyMsg = (showAllQuests or questFilterZone == "")
            and "No quests are blocked."
            or ("No quests are blocked in " .. (questFilterZone or "") .. ".");
        table.insert(widgets, {
            type = "description",
            text = emptyMsg,
            fontSize = "small",
            color = T.textDim,
        });
    else
        -- Group by NPC name
        local groups = {};
        for _, entry in ipairs(filteredEntries) do
            local npcName = entry.npcKey;
            if (npcName and npcName:find(" %-%s")) then
                npcName = npcName:match("^(.-)%s%-%s.+$") or npcName;
            end
            if (not npcName or npcName == "") then
                npcName = "Unknown NPC";
            end
            groups[npcName] = groups[npcName] or {};
            table.insert(groups[npcName], entry);
        end

        local npcNames = {};
        for npcName in pairs(groups) do table.insert(npcNames, npcName); end
        table.sort(npcNames);

        for _, npcName in ipairs(npcNames) do
            table.insert(widgets, {
                type = "label",
                text = npcName,
                fontSize = "medium",
                color = T.textBright,
            });

            local group = groups[npcName];
            table.sort(group, function(a, b)
                local aName = a.name or "";
                local bName = b.name or "";
                if (aName ~= bName) then
                    if (aName == "") then return false; end
                    if (bName == "") then return true; end
                    return aName < bName;
                end
                return tostring(a.id) < tostring(b.id);
            end);

            for _, entry in ipairs(group) do
                local label;
                if (type(entry.name) == "string" and entry.name ~= "") then
                    label = string.format("%s (ID: %s)", entry.name, tostring(entry.id));
                else
                    label = string.format("Quest ID: %s", tostring(entry.id));
                end
                table.insert(widgets, {
                    type = "label_action",
                    text = label,
                    buttonLabel = "Remove",
                    desc = "Unblock this quest.",
                    confirm = "Remove?",
                    disabled = isDisabled,
                    func = function()
                        local blockedQuests = db().blockedQuests;
                        blockedQuests[entry.id] = nil;
                        if (entry.name) then
                            local names = db().blockedQuestNames;
                            names[entry.name] = nil;
                        end
                        refreshPage();
                    end,
                });
            end
        end
    end

    ---------------------------------------------------------------------------
    -- Recent Automated Quests
    ---------------------------------------------------------------------------
    table.insert(widgets, { type = "header", text = "Recent automated quests" });
    table.insert(widgets, {
        type = "description",
        text = "Your 5 most recent automated quests. Use the button to block a quest from future automation.",
        fontSize = "small",
        color = T.textDim,
    });

    local recentList = d.recentAutomated or {};
    if (#recentList == 0) then
        table.insert(widgets, {
            type = "description",
            text = "No automated quests yet.",
            fontSize = "small",
            color = T.textDim,
        });
    else
        for i = 1, math.min(#recentList, 5) do
            local entry = recentList[i];
            if (entry) then
                local label = entry.name or "Unknown Quest";
                if (entry.questID) then
                    label = string.format("%s (ID: %s)", label, tostring(entry.questID));
                end
                local alreadyBlocked = entry.questID and isQuestBlockedById(entry.questID);
                local npcDesc = entry.npcKey and ("NPC: " .. entry.npcKey) or nil;
                table.insert(widgets, {
                    type = "label_action",
                    text = label,
                    buttonLabel = alreadyBlocked and "Blocked" or "Block Quest",
                    desc = npcDesc or "Block this quest from future automation.",
                    disabled = function() return isDisabled() or alreadyBlocked; end,
                    func = function()
                        if (entry.questID) then
                            local blockedQuests = db().blockedQuests;
                            local blockedNames = db().blockedQuestNames;
                            blockedQuests[tostring(entry.questID)] = {
                                name = entry.name or true,
                                npcKey = entry.npcKey,
                            };
                            if (entry.name) then
                                blockedNames[entry.name] = true;
                            end
                            refreshPage();
                        end
                    end,
                });
            end
        end
    end

    return widgets;
end

-------------------------------------------------------------------------------
-- MissingPet custom options
-------------------------------------------------------------------------------

CUSTOM_OPTIONS["missingPet"] = function()
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

-------------------------------------------------------------------------------
-- Splash / Home content
-------------------------------------------------------------------------------

local linkPopup;

local function showLinkPopup(link)
    if (not linkPopup) then
        local POPUP_W, POPUP_H = 340, 110;
        local panelFrame = panel._frame;

        local overlay = CreateFrame("Frame", "LanternUX_LinkOverlay", panelFrame);
        overlay:SetAllPoints();
        overlay:SetFrameLevel(panelFrame:GetFrameLevel() + 50);
        overlay:EnableMouse(true);
        overlay:SetScript("OnMouseDown", function() overlay:Hide(); end);

        local bg = overlay:CreateTexture(nil, "BACKGROUND");
        bg:SetAllPoints();
        bg:SetColorTexture(0, 0, 0, 0.5);

        local popup = CreateFrame("Frame", "LanternUX_LinkPopup", overlay, "BackdropTemplate");
        popup:SetSize(POPUP_W, POPUP_H);
        popup:SetPoint("CENTER", panelFrame, "CENTER", 0, 40);
        popup:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        });
        popup:SetBackdropColor(unpack(T.bg));
        popup:SetBackdropBorderColor(unpack(T.border));
        popup:EnableMouse(true);

        -- Title
        local title = popup:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
        title:SetPoint("TOPLEFT", popup, "TOPLEFT", 14, -14);
        title:SetText("Copy link");
        title:SetTextColor(unpack(T.textBright));

        -- Close button (X)
        local closeBtn = CreateFrame("Button", "LanternUX_LinkCloseBtn", popup);
        closeBtn:SetSize(20, 20);
        closeBtn:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -8, -8);
        local closeTxt = closeBtn:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
        closeTxt:SetPoint("CENTER");
        closeTxt:SetText("x");
        closeTxt:SetTextColor(unpack(T.text));
        closeBtn:SetScript("OnEnter", function() closeTxt:SetTextColor(unpack(T.textBright)); end);
        closeBtn:SetScript("OnLeave", function() closeTxt:SetTextColor(unpack(T.text)); end);
        closeBtn:SetScript("OnClick", function() overlay:Hide(); end);

        -- Edit box
        local editBox = CreateFrame("EditBox", "LanternUX_LinkEditBox", popup, "BackdropTemplate");
        editBox:SetSize(POPUP_W - 28, 26);
        editBox:SetPoint("TOPLEFT", popup, "TOPLEFT", 14, -40);
        editBox:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        });
        editBox:SetBackdropColor(unpack(T.inputBg));
        editBox:SetBackdropBorderColor(unpack(T.inputBorder));
        editBox:SetFontObject(GameFontHighlightSmall);
        editBox:SetTextColor(unpack(T.text));
        editBox:SetTextInsets(6, 6, 0, 0);
        editBox:SetAutoFocus(false);
        editBox:SetMaxLetters(0);

        editBox:SetScript("OnEscapePressed", function() overlay:Hide(); end);
        editBox:SetScript("OnEnterPressed", function() overlay:Hide(); end);
        editBox:SetScript("OnKeyUp", function(_, key)
            if (IsControlKeyDown() and (key == "C" or key == "X")) then
                overlay:Hide();
            end
        end);

        -- Hint text
        local hint = popup:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
        hint:SetPoint("TOPLEFT", editBox, "BOTTOMLEFT", 2, -8);
        hint:SetText("Ctrl+C to copy, Escape to close");
        hint:SetTextColor(unpack(T.textDim));

        overlay._editBox = editBox;
        linkPopup = overlay;
    end

    linkPopup._editBox:SetText(link or "");
    linkPopup:Show();
    linkPopup._editBox:SetFocus();
    linkPopup._editBox:HighlightText();
end

local COMPANION_ADDONS = {
    {
        addonName = "Lantern_CraftingOrders",
        label     = "Crafting Orders",
        desc      = "Announces guild order activity, personal order alerts, and a Complete + Whisper button.",
        url       = "https://www.curseforge.com/wow/addons/lantern-craftingorders",
    },
    {
        addonName = "Lantern_Warband",
        label     = "Warband",
        desc      = "Organize characters into groups with automated gold balancing to/from warbank when opening a bank.",
        url       = "https://www.curseforge.com/wow/addons/lantern-warband",
    },
};

local COMPANION_COL_WIDTH = 255;
local COMPANION_COL_GAP   = 24;

local splashFrame;

local function PopulateSplashModules()
    if (not splashFrame) then return; end

    local names = {};
    for name, _ in pairs(Lantern.modules or {}) do
        table.insert(names, name);
    end
    table.sort(names);

    local y = splashFrame._moduleListY;

    for i, name in ipairs(names) do
        local dot = splashFrame._moduleDots[i];
        local label = splashFrame._moduleLabels[i];

        if (not dot) then
            dot = splashFrame:CreateTexture(nil, "ARTWORK");
            dot:SetSize(8, 8);
            dot:SetTexture("Interface\\Buttons\\WHITE8x8");
            splashFrame._moduleDots[i] = dot;
        end

        if (not label) then
            label = splashFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
            splashFrame._moduleLabels[i] = label;
        end

        local mod = Lantern.modules[name];
        local displayName = (mod.opts and mod.opts.title) or name;

        dot:ClearAllPoints();
        dot:SetPoint("TOPLEFT", splashFrame, "TOPLEFT", 32, y - 2);
        if (mod.enabled) then
            dot:SetColorTexture(unpack(T.enabled));
        else
            dot:SetColorTexture(unpack(T.disabledDot));
        end
        dot:Show();

        label:ClearAllPoints();
        label:SetPoint("TOPLEFT", splashFrame, "TOPLEFT", 46, y);
        label:SetJustifyH("LEFT");
        label:SetTextColor(unpack(T.text));
        label:SetText(displayName);
        label:Show();

        y = y - 24;
    end

    for i = #names + 1, #splashFrame._moduleLabels do
        if (splashFrame._moduleDots[i]) then splashFrame._moduleDots[i]:Hide(); end
        splashFrame._moduleLabels[i]:Hide();
    end

    -- Companion addons section (show addons that are not loaded)
    -- "not loaded" = not installed OR installed but disabled
    local hasAnyCompanion = false;
    for _, info in ipairs(COMPANION_ADDONS) do
        local loaded = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded(info.addonName);
        if (not loaded) then
            hasAnyCompanion = true;
            break;
        end
    end

    if (hasAnyCompanion and splashFrame._companionHeader) then
        -- Position header below module list
        y = y - 12;
        splashFrame._companionHeader:ClearAllPoints();
        splashFrame._companionHeader:SetPoint("TOPLEFT", splashFrame, "TOPLEFT", 28, y);
        splashFrame._companionHeader:Show();

        splashFrame._companionDivider:ClearAllPoints();
        splashFrame._companionDivider:SetPoint("TOPLEFT", splashFrame._companionHeader, "BOTTOMLEFT", 0, -6);
        splashFrame._companionDivider:SetPoint("RIGHT", splashFrame, "RIGHT", -28, 0);
        splashFrame._companionDivider:Show();

        y = y - 30;

        -- Position companion rows in a 2-column grid
        local col = 0;       -- 0 = left, 1 = right
        local rowMaxH = 0;   -- tallest cell in current row pair

        for idx, info in ipairs(COMPANION_ADDONS) do
            local loaded = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded(info.addonName);
            local cell = splashFrame._companionRows[idx];
            if (cell) then
                if (loaded) then
                    cell.frame:Hide();
                else
                    -- Determine if installed but disabled vs not installed
                    local installed = C_AddOns and C_AddOns.GetAddOnInfo and C_AddOns.GetAddOnInfo(info.addonName) ~= nil;

                    if (installed) then
                        -- Installed but disabled — show muted button
                        cell.btnText:SetText("Disabled");
                        cell.btnText:SetTextColor(unpack(T.disabledText));
                        cell.btn:SetBackdropColor(unpack(T.disabledBg));
                        cell.btn:SetBackdropBorderColor(unpack(T.disabled));
                        cell.btn:SetScript("OnEnter", nil);
                        cell.btn:SetScript("OnLeave", nil);
                        cell.btn:SetScript("OnClick", nil);
                    else
                        -- Not installed — show CurseForge link
                        cell.btnText:SetText("CurseForge");
                        cell.btnText:SetTextColor(unpack(T.buttonText));
                        cell.btn:SetBackdropColor(unpack(T.buttonBg));
                        cell.btn:SetBackdropBorderColor(unpack(T.buttonBorder));
                        cell.btn:SetScript("OnEnter", function(self)
                            self:SetBackdropColor(unpack(T.buttonHover));
                            self:SetBackdropBorderColor(unpack(T.inputFocus));
                        end);
                        cell.btn:SetScript("OnLeave", function(self)
                            self:SetBackdropColor(unpack(T.buttonBg));
                            self:SetBackdropBorderColor(unpack(T.buttonBorder));
                        end);
                        cell.btn:SetScript("OnClick", function()
                            showLinkPopup(cell.url);
                        end);
                    end

                    local xOffset = 32 + col * (COMPANION_COL_WIDTH + COMPANION_COL_GAP);
                    cell.frame:ClearAllPoints();
                    cell.frame:SetPoint("TOPLEFT", splashFrame, "TOPLEFT", xOffset, y);
                    cell.frame:Show();

                    if (cell.height > rowMaxH) then rowMaxH = cell.height; end

                    col = col + 1;
                    if (col >= 2) then
                        y = y - rowMaxH - 12;
                        col = 0;
                        rowMaxH = 0;
                    end
                end
            end
        end

        -- Advance y after a partial (odd-count) row
        if (col > 0) then
            y = y - rowMaxH - 12;
        end
    elseif (splashFrame._companionHeader) then
        splashFrame._companionHeader:Hide();
        splashFrame._companionDivider:Hide();
        for _, row in ipairs(splashFrame._companionRows) do
            row.frame:Hide();
        end
    end
end

local function CreateSplashContent(parent)
    local f = CreateFrame("Frame", "LanternUX_Splash", parent);
    f:SetAllPoints();

    local y = -28;

    -- Icon
    local icon = f:CreateTexture(nil, "ARTWORK");
    icon:SetSize(48, 48);
    icon:SetPoint("TOPLEFT", f, "TOPLEFT", 28, y);
    icon:SetTexture("Interface\\AddOns\\Lantern\\Media\\Images\\Icons\\lantern-core-icon128.blp");

    -- Title
    local title = f:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
    title:SetPoint("LEFT", icon, "RIGHT", 12, 6);
    title:SetText("Lantern");
    title:SetTextColor(unpack(T.textBright));

    -- Version
    local ver = "";
    if (C_AddOns and C_AddOns.GetAddOnMetadata) then
        ver = C_AddOns.GetAddOnMetadata("Lantern", "Version") or "";
    end
    local verText = f:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
    verText:SetPoint("LEFT", title, "RIGHT", 8, -1);
    verText:SetText("v" .. ver);
    verText:SetTextColor(unpack(T.textDim));

    -- Description
    local desc = f:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
    desc:SetPoint("TOPLEFT", icon, "BOTTOMLEFT", 0, -16);
    desc:SetWidth(540);
    desc:SetJustifyH("LEFT");
    desc:SetWordWrap(true);
    desc:SetText("A modular quality-of-life addon for World of Warcraft.\nSelect a module from the sidebar to configure it.");
    desc:SetTextColor(unpack(T.splashText));

    -- Module status header
    local statusHeader = f:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
    statusHeader:SetPoint("TOPLEFT", f, "TOPLEFT", 28, -160);
    statusHeader:SetText("Loaded Modules");
    statusHeader:SetTextColor(unpack(T.textBright));

    local divider = f:CreateTexture(nil, "ARTWORK");
    divider:SetHeight(1);
    divider:SetPoint("TOPLEFT", statusHeader, "BOTTOMLEFT", 0, -6);
    divider:SetPoint("RIGHT", f, "RIGHT", -28, 0);
    divider:SetColorTexture(unpack(T.divider));

    f._moduleListY = -190;
    f._moduleLabels = {};
    f._moduleDots = {};

    -- Companion addons section (created below modules, positioned dynamically by PopulateSplashModules)
    -- We create the elements here but position them in PopulateSplashModules since
    -- the Y offset depends on how many modules are listed above.
    local companionHeader = f:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
    companionHeader:SetText("Companion Addons");
    companionHeader:SetTextColor(unpack(T.textBright));
    companionHeader:Hide();
    f._companionHeader = companionHeader;

    local companionDivider = f:CreateTexture(nil, "ARTWORK");
    companionDivider:SetHeight(1);
    companionDivider:SetColorTexture(unpack(T.divider));
    companionDivider:Hide();
    f._companionDivider = companionDivider;

    f._companionRows = {};

    for i, info in ipairs(COMPANION_ADDONS) do
        local row = CreateFrame("Frame", "LanternUX_CompanionRow_" .. i, f);
        row:SetWidth(COMPANION_COL_WIDTH);

        -- Description text
        local rowDesc = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
        rowDesc:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0);
        rowDesc:SetWidth(COMPANION_COL_WIDTH);
        rowDesc:SetJustifyH("LEFT");
        rowDesc:SetWordWrap(true);
        rowDesc:SetText(info.label .. ": " .. info.desc);
        rowDesc:SetTextColor(unpack(T.splashText));

        -- CurseForge button
        local btn = CreateFrame("Button", "LanternUX_CompanionBtn_" .. i, row, "BackdropTemplate");
        btn:SetSize(100, 22);
        btn:SetPoint("TOPLEFT", rowDesc, "BOTTOMLEFT", 0, -6);
        btn:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        });
        btn:SetBackdropColor(unpack(T.buttonBg));
        btn:SetBackdropBorderColor(unpack(T.buttonBorder));

        local btnText = btn:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
        btnText:SetPoint("CENTER");
        btnText:SetText("CurseForge");
        btnText:SetTextColor(unpack(T.buttonText));

        btn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(unpack(T.buttonHover));
            self:SetBackdropBorderColor(unpack(T.inputFocus));
        end);
        btn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(unpack(T.buttonBg));
            self:SetBackdropBorderColor(unpack(T.buttonBorder));
        end);
        btn:SetScript("OnClick", function()
            showLinkPopup(info.url);
        end);

        local textHeight = math.max(14, rowDesc:GetStringHeight() or 0);
        local totalHeight = textHeight + 6 + 22;
        row:SetHeight(totalHeight);

        f._companionRows[i] = { frame = row, height = totalHeight, btn = btn, btnText = btnText, url = info.url };
    end

    splashFrame = f;
    return f;
end

-------------------------------------------------------------------------------
-- Register pages on PLAYER_LOGIN (all addons loaded by then)
-------------------------------------------------------------------------------

local loginFrame = CreateFrame("Frame", "LanternUX_LoginFrame");
loginFrame:RegisterEvent("PLAYER_LOGIN");
loginFrame:SetScript("OnEvent", function()
    -- Home (splash page with module status)
    panel:AddPage("home", {
        label = "Home",
        frame = CreateSplashContent,
        onShow = PopulateSplashModules,
    });

    -- General
    panel:AddPage("general", {
        label   = "General",
        title   = "General",
        description = "Core addon settings.",
        widgets = CUSTOM_OPTIONS["general"],
    });

    -- Core modules section
    panel:AddSection("modules", "Modules");
    panel:AddSidebarGroup("quickSettings", {
        label   = "Quick Settings",
        section = "modules",
    });
    for _, moduleName in ipairs(CORE_ORDER) do
        local mod = Lantern.modules[moduleName];
        if (mod) then
            local key = CORE_KEY[moduleName];
            local optionsFn = CUSTOM_OPTIONS[key];
            panel:AddPage(key, {
                label        = (mod.opts and mod.opts.title) or moduleName,
                section      = "modules",
                sidebarGroup = QUICK_SETTINGS[key] and "quickSettings" or nil,
                title        = (mod.opts and mod.opts.title) or moduleName,
                description  = mod.opts and mod.opts.desc,
                widgets      = optionsFn or nil,
                aceConfig    = (not optionsFn) and { appName = "Lantern_General", path = key } or nil,
            });
        end
    end

    -- External modules (Warband, CraftingOrders, etc.)
    local external = {};
    for name, mod in pairs(Lantern.modules or {}) do
        if (not CORE_KEY[name] and not (mod.opts and mod.opts.skipOptions)) then
            table.insert(external, name);
        end
    end
    table.sort(external);

    if (#external > 0) then
        panel:AddSection("addons", "Addons");
        for _, moduleName in ipairs(external) do
            local mod = Lantern.modules[moduleName];
            if (mod.uxPages) then
                local groupKey = "addon_" .. moduleName:lower();
                panel:AddSidebarGroup(groupKey, {
                    label   = (mod.opts and mod.opts.title) or moduleName,
                    section = "addons",
                });
                for _, pageInfo in ipairs(mod.uxPages) do
                    pageInfo.opts.section = "addons";
                    pageInfo.opts.sidebarGroup = groupKey;
                    panel:AddPage(pageInfo.key, pageInfo.opts);
                end
            else
                panel:AddPage("module_" .. moduleName, {
                    label     = (mod.opts and mod.opts.title) or moduleName,
                    section   = "addons",
                    aceConfig = { appName = "module_" .. moduleName },
                });
            end
        end
    end
end);

-------------------------------------------------------------------------------
-- Override Lantern:OpenOptions()
-------------------------------------------------------------------------------

function Lantern:OpenOptions()
    -- SetupOptions touches protected Blizzard UI; defer if in combat and not initialized.
    if (not self.optionsInitialized and InCombatLockdown()) then
        self._pendingSettingsPanel = true;
        Lantern:Print("Options will open after combat.");
        return;
    end

    if (not self.optionsInitialized) then
        self:SetupOptions();
    end

    self._pendingSettingsPanel = false;
    panel:Toggle();
end

-------------------------------------------------------------------------------
-- Handle deferred open after combat ends
-------------------------------------------------------------------------------

local combatFrame = CreateFrame("Frame", "LanternUX_CombatFrame");
combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
combatFrame:SetScript("OnEvent", function()
    if (Lantern._pendingSettingsPanel) then
        Lantern._pendingSettingsPanel = false;
        C_Timer.After(0.1, function()
            Lantern:OpenOptions();
        end);
    end
end);
