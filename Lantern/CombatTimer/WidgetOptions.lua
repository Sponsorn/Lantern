local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local LanternUX = _G.LanternUX;
local T = LanternUX and LanternUX.Theme;
if (not T) then return; end

local module = Lantern.modules["CombatTimer"];
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
    local function db()
        if (not Lantern.db) then Lantern.db = {}; end
        if (not Lantern.db.combatTimer) then Lantern.db.combatTimer = {}; end
        local d = Lantern.db.combatTimer;
        local defaults = {
            font = "Roboto Light", fontSize = 18, fontOutline = "OUTLINE",
            fontColor = { r = 1, g = 1, b = 1 },
            stickyDuration = 5, locked = true,
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
        return not moduleEnabled("CombatTimer");
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
        [""] = "None",
        ["OUTLINE"] = "Outline",
        ["THICKOUTLINE"] = "Thick Outline",
        ["MONOCHROME"] = "Monochrome",
        ["OUTLINE, MONOCHROME"] = "Outline + Mono",
    };
    local outlineSorting = { "", "OUTLINE", "THICKOUTLINE", "MONOCHROME", "OUTLINE, MONOCHROME" };

    local function isPreviewActive()
        return module.IsPreviewActive and module:IsPreviewActive() or false;
    end

    return {
        moduleToggle("CombatTimer", "Enable", "Show a timer during combat."),
        {
            type = "toggle",
            label = "Preview",
            desc = "Show the timer on screen for real-time editing. Automatically disables when the settings panel is closed.",
            disabled = isDisabled,
            get = function() return isPreviewActive(); end,
            set = function(val)
                if (module.SetPreviewMode) then module:SetPreviewMode(val); end
            end,
        },
        {
            type = "group",
            text = "Display",
            expanded = true,
            children = {
                {
                    type = "select",
                    label = "Font",
                    desc = "Select the font for the timer text.",
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
                    desc = "Size of the timer text.",
                    min = 12, max = 48, step = 1, default = 18,
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
                    desc = "Outline style for the timer text.",
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
                    type = "color",
                    label = "Font Color",
                    desc = "Color of the timer text.",
                    disabled = isDisabled,
                    get = function()
                        local c = db().fontColor;
                        return c.r, c.g, c.b;
                    end,
                    set = function(r, g, b)
                        db().fontColor = { r = r, g = g, b = b };
                        if (module.RefreshColor) then module:RefreshColor(); end
                    end,
                },
                {
                    type = "range",
                    label = "Sticky Duration",
                    desc = "Seconds to keep showing the final time after combat ends. Set to 0 to hide immediately.",
                    min = 0, max = 30, step = 1, default = 5,
                    disabled = isDisabled,
                    get = function() return db().stickyDuration; end,
                    set = function(val) db().stickyDuration = val; end,
                },
            },
        },
        {
            type = "group",
            text = "Position",
            children = {
                {
                    type = "toggle",
                    label = "Lock Position",
                    desc = "Prevent the timer from being moved.",
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
                    desc = "Reset the timer to its default position.",
                    disabled = isDisabled,
                    func = function()
                        if (module.ResetPosition) then module:ResetPosition(); end
                    end,
                },
            },
        },
    };
end
