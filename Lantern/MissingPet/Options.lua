local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true);
local Layout = Lantern.optionsLayout;

local function missingPetModule()
    return Lantern.modules and Lantern.modules.MissingPet;
end

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
    soundName = "RaidWarning",
    soundRepeat = false,
    soundInterval = 5,
};

local function missingPetDB()
    if (not Lantern.db) then
        Lantern.db = {};
    end
    if (not Lantern.db.missingPet) then
        Lantern.db.missingPet = {};
    end
    local db = Lantern.db.missingPet;
    for k, v in pairs(DEFAULTS) do
        if (db[k] == nil) then
            db[k] = v;
        end
    end
    return db;
end

local function missingPetDisabled()
    local m = missingPetModule();
    return not (m and m.enabled);
end

local function getAnimationOptions()
    local options = {
        { value = "none", label = "None (static)" },
        { value = "bounce", label = "Bounce" },
        { value = "pulse", label = "Pulse" },
        { value = "fade", label = "Fade" },
        { value = "shake", label = "Shake" },
        { value = "glow", label = "Glow" },
        { value = "heartbeat", label = "Heartbeat" },
    };
    return options;
end

local function getFontValues()
    local fonts = {};
    if (LSM) then
        for _, name in ipairs(LSM:List("font") or {}) do
            fonts[name] = name;
        end
    end
    -- Ensure default is available
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

local function getSoundValues()
    -- Register custom Lantern sounds
    if (Lantern.utils and Lantern.utils.RegisterMediaSounds) then
        Lantern.utils.RegisterMediaSounds(LSM);
    end
    local sounds = {};
    if (LSM) then
        for _, name in ipairs(LSM:List("sound") or {}) do
            sounds[name] = name;
        end
    end
    -- Ensure default is available
    if (not sounds["RaidWarning"]) then
        sounds["RaidWarning"] = "RaidWarning";
    end
    return sounds;
end

-- Helper to refresh warning on change
local function refreshWarning()
    local m = missingPetModule();
    if (m and m.RefreshWarning) then
        m:RefreshWarning();
    end
end

local function refreshAnimation()
    local m = missingPetModule();
    if (m and m.RefreshAnimation) then
        m:RefreshAnimation();
    end
end

local function refreshFont()
    local m = missingPetModule();
    if (m and m.RefreshFont) then
        m:RefreshFont();
    end
end

function Lantern:BuildMissingPetOptions()
    local args = {};

    -- Description
    args.desc = Layout.description(0, "Displays a warning when your pet is missing or set to passive. Works for Hunters, Warlocks, Death Knights, and Mages with pets.");

    -- Enable toggle (full width)
    args.enabled = {
        order = 1,
        type = "toggle",
        name = "Enable",
        desc = "Enable or disable the Missing Pet warning.",
        width = "full",
        get = function()
            local m = missingPetModule();
            return m and m.enabled;
        end,
        set = function(_, val)
            if (val) then
                Lantern:EnableModule("MissingPet");
            else
                Lantern:DisableModule("MissingPet");
            end
        end,
    };

    -- Warning Settings section
    args.warningHeader = Layout.header(10, "Warning Settings");

    -- Row 1: Show toggles side by side (micro-ordering: 11.00, 11.01)
    args.showMissing = {
        order = 11.00,
        type = "toggle",
        name = "Show Missing Warning",
        desc = "Display a warning when your pet is dismissed or dead.",
        width = "normal",
        disabled = missingPetDisabled,
        get = function()
            local db = missingPetDB();
            return db.showMissing;
        end,
        set = function(_, val)
            local db = missingPetDB();
            db.showMissing = val and true or false;
            refreshWarning();
        end,
    };

    args.showPassive = {
        order = 11.01,
        type = "toggle",
        name = "Show Passive Warning",
        desc = "Display a warning when your pet is set to passive mode.",
        width = "normal",
        disabled = missingPetDisabled,
        get = function()
            local db = missingPetDB();
            return db.showPassive;
        end,
        set = function(_, val)
            local db = missingPetDB();
            db.showPassive = val and true or false;
            refreshWarning();
        end,
    };

    -- Spacer to force new line
    args.spacer1 = Layout.spacer(11.99);

    -- Row 2: Text inputs side by side (micro-ordering: 12.00, 12.01)
    args.warningText = {
        order = 12.00,
        type = "input",
        name = "Missing Text",
        desc = "Text to display when your pet is missing.",
        width = "normal",
        disabled = missingPetDisabled,
        get = function()
            local db = missingPetDB();
            return db.warningText or "Pet Missing!";
        end,
        set = function(_, val)
            local db = missingPetDB();
            db.warningText = val;
            refreshWarning();
        end,
    };

    args.passiveText = {
        order = 12.01,
        type = "input",
        name = "Passive Text",
        desc = "Text to display when your pet is set to passive.",
        width = "normal",
        disabled = missingPetDisabled,
        get = function()
            local db = missingPetDB();
            return db.passiveText or "Pet is PASSIVE!";
        end,
        set = function(_, val)
            local db = missingPetDB();
            db.passiveText = val;
            refreshWarning();
        end,
    };

    -- Spacer to force new line
    args.spacer2 = Layout.spacer(12.99);

    -- Row 3: Colors side by side (micro-ordering: 13.00, 13.01)
    args.missingColor = {
        order = 13.00,
        type = "color",
        name = "Missing Color",
        desc = "Color for the missing pet warning text.",
        width = "normal",
        disabled = missingPetDisabled,
        get = function()
            local db = missingPetDB();
            local c = db.missingColor or { r = 1, g = 0.2, b = 0.2 };
            return c.r, c.g, c.b;
        end,
        set = function(_, r, g, b)
            local db = missingPetDB();
            db.missingColor = { r = r, g = g, b = b };
            refreshWarning();
        end,
    };

    args.passiveColor = {
        order = 13.01,
        type = "color",
        name = "Passive Color",
        desc = "Color for the passive pet warning text.",
        width = "normal",
        disabled = missingPetDisabled,
        get = function()
            local db = missingPetDB();
            local c = db.passiveColor or { r = 1, g = 0.6, b = 0 };
            return c.r, c.g, c.b;
        end,
        set = function(_, r, g, b)
            local db = missingPetDB();
            db.passiveColor = { r = r, g = g, b = b };
            refreshWarning();
        end,
    };

    -- Spacer to force new line
    args.spacer3 = Layout.spacer(13.99);

    -- Animation (full width since it's alone on its row)
    args.animationStyle = {
        order = 14,
        type = "select",
        name = "Animation Style",
        desc = "Choose how the warning text animates.",
        width = "double",
        disabled = missingPetDisabled,
        values = function()
            local vals = {};
            for _, opt in ipairs(getAnimationOptions()) do
                vals[opt.value] = opt.label;
            end
            return vals;
        end,
        sorting = function()
            local order = {};
            for _, opt in ipairs(getAnimationOptions()) do
                table.insert(order, opt.value);
            end
            return order;
        end,
        get = function()
            local db = missingPetDB();
            return db.animationStyle or "bounce";
        end,
        set = function(_, val)
            local db = missingPetDB();
            db.animationStyle = val;
            refreshAnimation();
        end,
    };

    -- Font Settings section
    args.fontHeader = Layout.header(20, "Font Settings");

    -- Row: Font and Font Size side by side (micro-ordering: 21.00, 21.01)
    args.font = {
        order = 21.00,
        type = "select",
        name = "Font",
        desc = "Select the font for the warning text.",
        width = "normal",
        disabled = missingPetDisabled,
        itemControl = "DDI-Font",
        values = getFontValues,
        get = function()
            local db = missingPetDB();
            return db.font or "Friz Quadrata TT";
        end,
        set = function(_, val)
            local db = missingPetDB();
            db.font = val;
            refreshFont();
        end,
    };

    args.fontSize = {
        order = 21.01,
        type = "range",
        name = "Font Size",
        desc = "Size of the warning text.",
        width = "normal",
        min = 12,
        max = 72,
        step = 1,
        disabled = missingPetDisabled,
        get = function()
            local db = missingPetDB();
            return db.fontSize or 24;
        end,
        set = function(_, val)
            local db = missingPetDB();
            db.fontSize = val;
            refreshFont();
        end,
    };

    -- Spacer to force new line
    args.spacer4 = Layout.spacer(21.99);

    -- Font outline (alone on its row)
    args.fontOutline = {
        order = 22,
        type = "select",
        name = "Font Outline",
        desc = "Outline style for the warning text.",
        width = "double",
        disabled = missingPetDisabled,
        values = getOutlineValues,
        get = function()
            local db = missingPetDB();
            return db.fontOutline or "OUTLINE";
        end,
        set = function(_, val)
            local db = missingPetDB();
            db.fontOutline = val;
            refreshFont();
        end,
    };

    -- Position section
    args.positionHeader = Layout.header(30, "Position");

    -- Row: Lock and Reset side by side (micro-ordering: 31.00, 31.01)
    args.locked = {
        order = 31.00,
        type = "toggle",
        name = "Lock Position",
        desc = "When locked, the warning cannot be moved. Hold Shift to move even when locked.",
        width = "normal",
        disabled = missingPetDisabled,
        get = function()
            local db = missingPetDB();
            return db.locked;
        end,
        set = function(_, val)
            local db = missingPetDB();
            db.locked = val and true or false;
            local m = missingPetModule();
            if (m and m.UpdateLock) then
                m:UpdateLock();
            end
        end,
    };

    args.resetPosition = {
        order = 31.01,
        type = "execute",
        name = "Reset Position",
        desc = "Reset the warning frame position to the center of the screen.",
        width = "normal",
        disabled = missingPetDisabled,
        func = function()
            local m = missingPetModule();
            if (m and m.ResetPosition) then
                m:ResetPosition();
            end
        end,
    };

    -- Visibility section
    args.visibilityHeader = Layout.header(40, "Visibility");

    -- Row: Hide toggles side by side (micro-ordering: 41.00, 41.01)
    args.hideWhenMounted = {
        order = 41.00,
        type = "toggle",
        name = "Hide When Mounted",
        desc = "Hide the warning while mounted, on a taxi, or in a vehicle.",
        width = "normal",
        disabled = missingPetDisabled,
        get = function()
            local db = missingPetDB();
            return db.hideWhenMounted;
        end,
        set = function(_, val)
            local db = missingPetDB();
            db.hideWhenMounted = val and true or false;
            refreshWarning();
        end,
    };

    args.hideInRestZone = {
        order = 41.01,
        type = "toggle",
        name = "Hide In Rest Zones",
        desc = "Hide the warning while in a rest zone (cities and inns).",
        width = "normal",
        disabled = missingPetDisabled,
        get = function()
            local db = missingPetDB();
            return db.hideInRestZone;
        end,
        set = function(_, val)
            local db = missingPetDB();
            db.hideInRestZone = val and true or false;
            refreshWarning();
        end,
    };

    -- Spacer to force new line
    args.spacer5 = Layout.spacer(41.99);

    -- Dismount delay (alone since it's conditional)
    args.dismountDelay = {
        order = 42,
        type = "range",
        name = "Dismount Delay",
        desc = "Seconds to wait after dismounting before showing warning. Set to 0 to show immediately.",
        width = "double",
        min = 0,
        max = 10,
        step = 0.5,
        disabled = function()
            local db = missingPetDB();
            return missingPetDisabled() or not db.hideWhenMounted;
        end,
        get = function()
            local db = missingPetDB();
            return db.dismountDelay or 5;
        end,
        set = function(_, val)
            local db = missingPetDB();
            db.dismountDelay = val;
        end,
    };

    -- Sound section
    args.soundHeader = Layout.header(50, "Sound");

    -- Row: Sound toggles side by side (micro-ordering: 51.00, 51.01)
    args.soundEnabled = {
        order = 51.00,
        type = "toggle",
        name = "Play Sound",
        desc = "Play a sound when the warning is displayed.",
        width = "normal",
        disabled = missingPetDisabled,
        get = function()
            local db = missingPetDB();
            return db.soundEnabled;
        end,
        set = function(_, val)
            local db = missingPetDB();
            db.soundEnabled = val and true or false;
        end,
    };

    args.soundRepeat = {
        order = 51.01,
        type = "toggle",
        name = "Repeat Sound",
        desc = "Repeat the sound at regular intervals while the warning is displayed.",
        width = "normal",
        disabled = function()
            local db = missingPetDB();
            return missingPetDisabled() or not db.soundEnabled;
        end,
        get = function()
            local db = missingPetDB();
            return db.soundRepeat;
        end,
        set = function(_, val)
            local db = missingPetDB();
            db.soundRepeat = val and true or false;
        end,
    };

    -- Spacer to force new line
    args.spacer6 = Layout.spacer(51.99);

    -- Row: Sound name and interval side by side (micro-ordering: 52.00, 52.01)
    args.soundName = {
        order = 52.00,
        type = "select",
        name = "Sound",
        desc = "Select the sound to play.",
        width = "normal",
        disabled = function()
            local db = missingPetDB();
            return missingPetDisabled() or not db.soundEnabled;
        end,
        values = getSoundValues,
        itemControl = "DDI-Sound",
        get = function()
            local db = missingPetDB();
            return db.soundName or "RaidWarning";
        end,
        set = function(_, val)
            local db = missingPetDB();
            db.soundName = val;
        end,
    };

    args.soundInterval = {
        order = 52.01,
        type = "range",
        name = "Repeat Interval",
        desc = "Seconds between sound repeats.",
        width = "normal",
        min = 1,
        max = 30,
        step = 1,
        disabled = function()
            local db = missingPetDB();
            return missingPetDisabled() or not db.soundEnabled or not db.soundRepeat;
        end,
        get = function()
            local db = missingPetDB();
            return db.soundInterval or 5;
        end,
        set = function(_, val)
            local db = missingPetDB();
            db.soundInterval = val;
        end,
    };

    return args;
end
