local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true);
local Layout = Lantern.optionsLayout;

local function interruptTrackerModule()
    return Lantern.modules and Lantern.modules.InterruptTracker;
end

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

local function interruptTrackerDB()
    if (not Lantern.db) then Lantern.db = {}; end
    if (not Lantern.db.interruptTracker) then
        Lantern.db.interruptTracker = {};
    end
    local db = Lantern.db.interruptTracker;
    for k, v in pairs(DEFAULTS) do
        if (db[k] == nil) then
            db[k] = v;
        end
    end
    return db;
end

local function isDisabled()
    local m = interruptTrackerModule();
    return not (m and m.enabled);
end

local function isPreviewActive()
    local m = interruptTrackerModule();
    return m and m.IsPreviewActive and m:IsPreviewActive() or false;
end

local function refreshModule(method, ...)
    local m = interruptTrackerModule();
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

local function isBarModeDisabled()
    return isDisabled() or interruptTrackerDB().displayMode ~= "bar";
end

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

local function getOutlineValues()
    return {
        [""] = "None",
        ["OUTLINE"] = "Outline",
        ["THICKOUTLINE"] = "Thick Outline",
        ["MONOCHROME"] = "Monochrome",
        ["OUTLINE, MONOCHROME"] = "Outline + Monochrome",
    };
end

local function refreshFont()
    local m = interruptTrackerModule();
    if (m and m.RefreshFont) then
        m:RefreshFont();
    end
end

function Lantern:BuildInterruptTrackerOptions()
    local args = {};

    -- Description
    args.desc = Layout.description(0, "Tracks party member interrupt cooldowns in non-raid groups. Passively detects kicks via taint laundering and mob interrupt correlation. Optional addon sync with other Lantern users.");

    -- Enable toggle
    args.enabled = {
        order = 1,
        type = "toggle",
        name = "Enable",
        desc = "Enable or disable the Interrupt Tracker module.",
        width = "full",
        get = function()
            local m = interruptTrackerModule();
            return m and m.enabled;
        end,
        set = function(_, val)
            if (val) then
                Lantern:EnableModule("InterruptTracker");
            else
                Lantern:DisableModule("InterruptTracker");
            end
        end,
    };

    -- Preview toggle
    args.preview = {
        order = 2,
        type = "toggle",
        name = "Preview",
        desc = "Show the tracker with simulated party data. Useful for positioning and testing display modes.",
        width = "full",
        disabled = isDisabled,
        get = function()
            return isPreviewActive();
        end,
        set = function(_, val)
            refreshModule("SetPreviewMode", val);
        end,
    };

    ---------------------------------------------------------------------------
    -- Display
    ---------------------------------------------------------------------------
    args.displayHeader = Layout.header(5, "Display");

    args.displayMode = {
        order = 6.00,
        type = "select",
        name = "Display Mode",
        desc = "Bar: class-colored cooldown bars with icons. Minimal: compact rows with icon, name, and status.",
        width = "normal",
        values = displayModeValues,
        sorting = displayModeSorting,
        disabled = isDisabled,
        get = function() return interruptTrackerDB().displayMode; end,
        set = function(_, val)
            interruptTrackerDB().displayMode = val;
            refreshModule("SetDisplayMode", val);
        end,
    };

    args.showSelf = {
        order = 6.01,
        type = "toggle",
        name = "Show Self",
        desc = "Include your own interrupt in the tracker display.",
        width = "normal",
        disabled = isDisabled,
        get = function() return interruptTrackerDB().showSelf; end,
        set = function(_, val)
            interruptTrackerDB().showSelf = val;
            refreshModule("RefreshDisplay");
        end,
    };
    args.spacerDisplay = Layout.spacer(6.99);

    ---------------------------------------------------------------------------
    -- Sorting
    ---------------------------------------------------------------------------
    args.sortHeader = Layout.header(7, "Sorting");

    args.sortMode = {
        order = 8.00,
        type = "select",
        name = "Sort By",
        desc = "Lowest Remaining CD: players closest to being ready appear first. Lowest Base CD: players with shorter kick cooldowns always appear first.",
        width = "normal",
        values = sortModeValues,
        sorting = sortModeSorting,
        disabled = isDisabled,
        get = function() return interruptTrackerDB().sortMode; end,
        set = function(_, val)
            interruptTrackerDB().sortMode = val;
            refreshModule("RefreshDisplay");
        end,
    };

    args.selfOnTop = {
        order = 8.01,
        type = "toggle",
        name = "Self Always On Top",
        desc = "Always show your own interrupt at the top of the list, regardless of sort order.",
        width = "normal",
        disabled = isDisabled,
        get = function() return interruptTrackerDB().selfOnTop; end,
        set = function(_, val)
            interruptTrackerDB().selfOnTop = val;
            refreshModule("RefreshDisplay");
        end,
    };
    args.spacerSort = Layout.spacer(8.99);

    ---------------------------------------------------------------------------
    -- Bar Mode
    ---------------------------------------------------------------------------
    args.barHeader = Layout.header(10, "Bar Mode");

    args.barWidth = {
        order = 11.00,
        type = "range",
        name = "Width",
        desc = "Width of the bar display.",
        width = "normal",
        min = 120, max = 400, step = 1,
        disabled = isBarModeDisabled,
        get = function() return interruptTrackerDB().barWidth; end,
        set = function(_, val)
            interruptTrackerDB().barWidth = val;
            refreshModule("RefreshDisplay");
        end,
    };

    args.barHeight = {
        order = 11.01,
        type = "range",
        name = "Height",
        desc = "Height of each bar.",
        width = "normal",
        min = 16, max = 40, step = 1,
        disabled = isBarModeDisabled,
        get = function() return interruptTrackerDB().barHeight; end,
        set = function(_, val)
            interruptTrackerDB().barHeight = val;
            refreshModule("RefreshDisplay");
        end,
    };
    args.spacerBar1 = Layout.spacer(11.99);

    args.barAlpha = {
        order = 12.00,
        type = "range",
        name = "Opacity",
        desc = "Opacity of the tracker frame.",
        width = "normal",
        min = 0.3, max = 1.0, step = 0.05,
        isPercent = true,
        disabled = isBarModeDisabled,
        get = function() return interruptTrackerDB().barAlpha; end,
        set = function(_, val)
            interruptTrackerDB().barAlpha = val;
            refreshModule("RefreshDisplay");
        end,
    };
    args.spacerBar2 = Layout.spacer(12.99);

    args.growUp = {
        order = 13.00,
        type = "toggle",
        name = "Grow Upward",
        desc = "Bars grow upward from the anchor point instead of downward.",
        width = "normal",
        disabled = isBarModeDisabled,
        get = function() return interruptTrackerDB().growUp; end,
        set = function(_, val)
            interruptTrackerDB().growUp = val;
            refreshModule("RefreshDisplay");
        end,
    };

    ---------------------------------------------------------------------------
    -- Font Settings
    ---------------------------------------------------------------------------
    args.fontHeader = Layout.header(15, "Font Settings");

    args.font = {
        order = 16.00,
        type = "select",
        name = "Font",
        desc = "Select the font for the tracker text.",
        width = "normal",
        disabled = isDisabled,
        itemControl = "DDI-Font",
        values = getFontValues,
        get = function() return interruptTrackerDB().font or "Friz Quadrata TT"; end,
        set = function(_, val)
            interruptTrackerDB().font = val;
            refreshFont();
        end,
    };

    args.fontOutline = {
        order = 16.01,
        type = "select",
        name = "Font Outline",
        desc = "Outline style for the tracker text.",
        width = "normal",
        disabled = isDisabled,
        values = getOutlineValues,
        get = function() return interruptTrackerDB().fontOutline or "OUTLINE"; end,
        set = function(_, val)
            interruptTrackerDB().fontOutline = val;
            refreshFont();
        end,
    };

    ---------------------------------------------------------------------------
    -- Position
    ---------------------------------------------------------------------------
    args.positionHeader = Layout.header(20, "Position");

    args.locked = {
        order = 21.00,
        type = "toggle",
        name = "Lock Position",
        desc = "When locked, the frames cannot be moved. Hold Shift to move even when locked.",
        width = "normal",
        disabled = isDisabled,
        get = function() return interruptTrackerDB().locked; end,
        set = function(_, val)
            interruptTrackerDB().locked = val;
            refreshModule("RefreshDisplay");
        end,
    };
    args.spacerPos = Layout.spacer(21.99);

    args.resetBarPosition = {
        order = 22.00,
        type = "execute",
        name = "Reset Bar Position",
        desc = "Reset the bar mode frame position to center of screen.",
        width = "normal",
        disabled = isDisabled,
        func = function()
            refreshModule("ResetBarPosition");
        end,
    };

    args.resetMinimalPosition = {
        order = 22.01,
        type = "execute",
        name = "Reset Minimal Position",
        desc = "Reset the minimal mode frame position to center of screen.",
        width = "normal",
        disabled = isDisabled,
        func = function()
            refreshModule("ResetCompactPosition");
        end,
    };

    return args;
end
