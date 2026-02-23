local ADDON_NAME = "Lantern_Warband";
local L = select(2, ...).L;
local Lantern = _G.Lantern;
if (not Lantern or not Lantern.modules or not Lantern.modules.Warband) then return; end

local Warband = Lantern.modules.Warband;

-- Shared utility functions
local function formatGold(copper)
    return Lantern:Convert("money:format_gold", copper) or "0";
end

local function formatGoldThousands(copper)
    return Lantern:Convert("money:format_gold_thousands", copper) or "0";
end

local function parseGold(str)
    return Lantern:Convert("money:parse_gold", str);
end

local function formatTimeAgo(timestamp)
    if (not timestamp) then return L["WARBAND_TIME_NEVER"]; end
    local now = time();
    local diff = now - timestamp;

    if (diff < 60) then
        return L["WARBAND_TIME_JUST_NOW"];
    elseif (diff < 3600) then
        local mins = math.floor(diff / 60);
        return string.format(L["WARBAND_TIME_MINUTES_AGO"], mins);
    elseif (diff < 86400) then
        local hours = math.floor(diff / 3600);
        return string.format(L["WARBAND_TIME_HOURS_AGO"], hours);
    else
        local days = math.floor(diff / 86400);
        return string.format(L["WARBAND_TIME_DAYS_AGO"], days);
    end
end

-- Export utilities for other options files
Warband._optionsUtils = {
    formatGold = formatGold,
    formatGoldThousands = formatGoldThousands,
    parseGold = parseGold,
    formatTimeAgo = formatTimeAgo,
};

