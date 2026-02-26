local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local LanternUX = _G.LanternUX;
local T = LanternUX and LanternUX.Theme;
if (not T) then return; end

local module = Lantern.modules["CombatTimer"];
if (not module) then return; end
local L = Lantern.L;

local moduleEnabled = Lantern.moduleEnabled;
local moduleToggle = Lantern.moduleToggle;

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
        [""] = L["FONT_OUTLINE_NONE"],
        ["OUTLINE"] = L["FONT_OUTLINE_OUTLINE"],
        ["THICKOUTLINE"] = L["FONT_OUTLINE_THICK"],
        ["MONOCHROME"] = L["FONT_OUTLINE_MONO"],
        ["OUTLINE, MONOCHROME"] = L["FONT_OUTLINE_OUTLINE_MONO"],
    };
    local outlineSorting = { "", "OUTLINE", "THICKOUTLINE", "MONOCHROME", "OUTLINE, MONOCHROME" };

    local function isPreviewActive()
        return module.IsPreviewActive and module:IsPreviewActive() or false;
    end

    return {
        moduleToggle("CombatTimer", L["ENABLE"], L["COMBATTIMER_ENABLE_DESC"]),
        {
            type = "toggle",
            label = L["SHARED_PREVIEW"],
            desc = L["COMBATTIMER_PREVIEW_DESC"],
            disabled = isDisabled,
            get = function() return isPreviewActive(); end,
            set = function(val)
                if (module.SetPreviewMode) then module:SetPreviewMode(val); end
            end,
        },
        {
            type = "group",
            text = L["SHARED_GROUP_DISPLAY"],
            expanded = true,
            children = {
                {
                    type = "select",
                    label = L["SHARED_FONT"],
                    desc = L["COMBATTIMER_FONT_DESC"],
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
                    desc = L["COMBATTIMER_FONT_SIZE_DESC"],
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
                    label = L["SHARED_FONT_OUTLINE"],
                    desc = L["COMBATTIMER_FONT_OUTLINE_DESC"],
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
                    label = L["SHARED_FONT_COLOR"],
                    desc = L["COMBATTIMER_FONT_COLOR_DESC"],
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
                    label = L["COMBATTIMER_STICKY_DURATION"],
                    desc = L["COMBATTIMER_STICKY_DURATION_DESC"],
                    min = 0, max = 30, step = 1, default = 5,
                    disabled = isDisabled,
                    get = function() return db().stickyDuration; end,
                    set = function(val) db().stickyDuration = val; end,
                },
            },
        },
        {
            type = "group",
            text = L["SHARED_GROUP_POSITION"],
            children = {
                {
                    type = "toggle",
                    label = L["SHARED_LOCK_POSITION"],
                    desc = L["COMBATTIMER_LOCK_POSITION_DESC"],
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
                    desc = L["COMBATTIMER_RESET_POSITION_DESC"],
                    disabled = isDisabled,
                    func = function()
                        if (module.ResetPosition) then module:ResetPosition(); end
                    end,
                },
            },
        },
    };
end
