local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local LanternUX = _G.LanternUX;
local T = LanternUX and LanternUX.Theme;
if (not T) then return; end

local module = Lantern.modules["AutoPlaystyle"];
if (not module) then return; end
local L = Lantern.L;

local moduleEnabled = Lantern.moduleEnabled;
local moduleToggle = Lantern.moduleToggle;

local PLAYSTYLE_FALLBACKS = { "Learning", "Relaxed", "Competitive", "Carry Offered" };
local PLAYSTYLE_SORTING = { 1, 2, 3, 4 };

local function getPlaystyleValues()
    return {
        [1] = _G.GROUP_FINDER_GENERAL_PLAYSTYLE1 or PLAYSTYLE_FALLBACKS[1],
        [2] = _G.GROUP_FINDER_GENERAL_PLAYSTYLE2 or PLAYSTYLE_FALLBACKS[2],
        [3] = _G.GROUP_FINDER_GENERAL_PLAYSTYLE3 or PLAYSTYLE_FALLBACKS[3],
        [4] = _G.GROUP_FINDER_GENERAL_PLAYSTYLE4 or PLAYSTYLE_FALLBACKS[4],
    };
end

module.widgetOptions = function()
    local function db()
        Lantern.db.autoPlaystyle = Lantern.db.autoPlaystyle or {};
        return Lantern.db.autoPlaystyle;
    end

    local isDisabled = function()
        return not moduleEnabled("AutoPlaystyle");
    end

    return {
        moduleToggle("AutoPlaystyle", L["ENABLE"], L["AUTOPLAYSTYLE_ENABLE_DESC"]),
        {
            type = "select",
            label = L["AUTOPLAYSTYLE_PLAYSTYLE"],
            desc = L["AUTOPLAYSTYLE_PLAYSTYLE_DESC"],
            disabled = isDisabled,
            values = getPlaystyleValues(),
            sorting = PLAYSTYLE_SORTING,
            get = function() return db().playstyle or 3; end,
            set = function(val) db().playstyle = val; end,
        },
    };
end
