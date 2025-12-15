local ADDON_NAME, addon = ...;

local CET_OFFSET_SECONDS = 3600; -- CET is UTC+1 (ignores CEST for simplicity)

local function GetDailyResetHourCET()
    local region = addon.GetRegion and addon:GetRegion();
    if (region == "US") then
        return 16; -- 16:00 CET for US region reset
    end
    return 5; -- 05:00 CET for EU and default
end

function addon:GetLastDailyResetEpoch(now)
    local nowSec = now or GetServerTime();
    local resetSeconds = GetQuestResetTime and GetQuestResetTime();
    if (resetSeconds and resetSeconds > 0 and resetSeconds <= (24 * 60 * 60 + 30)) then
        local nextReset = nowSec + resetSeconds;
        return nextReset - 24 * 60 * 60;
    end

    local resetHourCET = GetDailyResetHourCET();
    local nowCET = nowSec + CET_OFFSET_SECONDS;
    local days = math.floor(nowCET / 86400);
    local todaysResetCET = days * 86400 + resetHourCET * 3600;
    local lastResetCET = todaysResetCET;
    if (nowCET < todaysResetCET) then
        lastResetCET = todaysResetCET - 86400;
    end
    return lastResetCET - CET_OFFSET_SECONDS;
end

addon.GetDailyResetHourCET = GetDailyResetHourCET;
