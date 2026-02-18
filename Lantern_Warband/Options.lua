local ADDON_NAME = "Lantern_Warband";
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
    if (not timestamp) then return "Never"; end
    local now = time();
    local diff = now - timestamp;

    if (diff < 60) then
        return "Just now";
    elseif (diff < 3600) then
        local mins = math.floor(diff / 60);
        return mins .. "m ago";
    elseif (diff < 86400) then
        local hours = math.floor(diff / 3600);
        return hours .. "h ago";
    else
        local days = math.floor(diff / 86400);
        return days .. "d ago";
    end
end

-- Export utilities for other options files
Warband._optionsUtils = {
    formatGold = formatGold,
    formatGoldThousands = formatGoldThousands,
    parseGold = parseGold,
    formatTimeAgo = formatTimeAgo,
};

