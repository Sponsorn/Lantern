local ADDON_NAME, addon = ...;

addon.utils = addon.utils or {};
addon.converters = addon.converters or {};

local utils = addon.utils;
local converters = addon.converters;

local function log(msg)
    print("|cffe08f2eLantern:|r " .. tostring(msg or ""));
end

local function printProxy(self, msg)
    if (self == addon) then
        log(msg);
    else
        log(self);
    end
end

utils.log = log;
addon.Print = printProxy;

local CET_OFFSET_SECONDS = 3600; -- CET is UTC+1 (ignores CEST for simplicity)
local REGION_BY_ID = { "US", "KR", "EU", "TW", "CN" };

local function normalizeRegionCode(region)
    if (region == "public-test") then
        return "US"; -- PTR uses US resets
    end
    if (type(region) == "string" and #region == 2) then
        return region:upper();
    end
end

function addon:GetRegion()
    local portal = GetCVar and GetCVar("portal");
    local normalized = normalizeRegionCode(portal);
    if (not normalized and GetCurrentRegion) then
        local regionID = GetCurrentRegion();
        normalized = regionID and REGION_BY_ID[regionID];
    end
    return normalized;
end

function utils.GetCurrentZoneName()
    local zone = GetZoneText and GetZoneText() or "";
    if (zone == "") then
        return nil;
    end
    return zone;
end

function utils.RegisterMediaSounds(lsm)
    if (not lsm or not lsm.Register) then return; end
    local mediaSounds = {
        { label = "Lantern: Auction Window Open", path = "Interface\\AddOns\\Lantern\\Media\\Sound\\AuctionWindowOpen.ogg" },
        { label = "Lantern: Auction Window Close", path = "Interface\\AddOns\\Lantern\\Media\\Sound\\AuctionWindowClose.ogg" },
        { label = "Lantern: Loot Coin Small", path = "Interface\\AddOns\\Lantern\\Media\\Sound\\LootCoinSmall.ogg" },
    };
    for _, entry in ipairs(mediaSounds) do
        lsm:Register("sound", entry.label, entry.path);
    end
end

-------------------------------------------------------------------------------
-- Secret Value Helpers (WoW 12.0+)
-------------------------------------------------------------------------------

local _issecretvalue = issecretvalue or function() return false; end;

function utils.IsSecret(val)
    return _issecretvalue(val);
end

-------------------------------------------------------------------------------
-- Class Color Helper
-------------------------------------------------------------------------------

local _classColorCache = {};

function utils.GetClassColor(classToken)
    if (not classToken) then
        local _, token = UnitClass("player");
        classToken = token;
    end
    if (not classToken) then return { r = 1, g = 1, b = 1 }; end
    local cached = _classColorCache[classToken];
    if (not cached) then
        local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken];
        if (color) then
            cached = { r = color.r, g = color.g, b = color.b };
        else
            cached = { r = 1, g = 1, b = 1 };
        end
        _classColorCache[classToken] = cached;
    end
    return cached;
end

-------------------------------------------------------------------------------
-- String Helpers
-------------------------------------------------------------------------------

function utils.StripRealm(name)
    if (type(name) ~= "string") then return name; end
    return name:gsub("%-[^%-]+$", "");
end

-------------------------------------------------------------------------------
-- Math Helpers
-------------------------------------------------------------------------------

function utils.Clamp01(v)
    if (v < 0) then return 0; end
    if (v > 1) then return 1; end
    return v;
end

-------------------------------------------------------------------------------
-- Font Helpers
-------------------------------------------------------------------------------

local _LSM = LibStub and LibStub("LibSharedMedia-3.0", true);
local _DEFAULT_FONT_PATH = (_G.LanternUX and _G.LanternUX.Theme and _G.LanternUX.Theme.fontPathLight)
    or "Fonts\\FRIZQT__.TTF";

function utils.GetFontPath(fontName)
    if (_LSM) then
        local path = _LSM:Fetch("font", fontName);
        if (path) then return path; end
    end
    return _DEFAULT_FONT_PATH;
end

-- Font object cache: keyed by "path|size|outline" to reuse across calls.
-- Using CreateFont + SetFontObject lets WoW manage late-loading font files
-- transparently, unlike direct SetFont which silently falls back to default.
local _fontObjects = {};
local _fontObjectCount = 0;

function utils.SafeSetFont(fontString, fontPath, size, outline)
    if (not fontString) then return; end
    outline = outline or "";
    local key = fontPath .. "|" .. size .. "|" .. outline;
    local fontObj = _fontObjects[key];
    if (not fontObj) then
        _fontObjectCount = _fontObjectCount + 1;
        fontObj = CreateFont("LanternFont_" .. _fontObjectCount);
        fontObj:SetFont(fontPath, size, outline);
        _fontObjects[key] = fontObj;
    end
    fontString:SetFontObject(fontObj);
end

local function GetDailyResetHourCET(region)
    region = region or addon:GetRegion();
    if (region == "US") then
        return 16; -- 16:00 CET for US region reset
    end
    return 5; -- 05:00 CET for EU and default
end

function addon:GetLastDailyResetEpoch(now, region)
    local nowSec = now or GetServerTime();
    if (not region) then
        local resetSeconds = GetQuestResetTime and GetQuestResetTime();
        if (resetSeconds and resetSeconds > 0 and resetSeconds <= (24 * 60 * 60 + 30)) then
            local nextReset = nowSec + resetSeconds;
            return nextReset - 24 * 60 * 60;
        end
    end

    local resetHourCET = GetDailyResetHourCET(region);
    local nowCET = nowSec + CET_OFFSET_SECONDS;
    local days = math.floor(nowCET / 86400);
    local todaysResetCET = days * 86400 + resetHourCET * 3600;
    local lastResetCET = todaysResetCET;
    if (nowCET < todaysResetCET) then
        lastResetCET = todaysResetCET - 86400;
    end
    return lastResetCET - CET_OFFSET_SECONDS;
end

function addon:GetNextWeeklyResetEpoch(now, region)
    local nowSec = now or GetServerTime();
    region = region or self:GetRegion();
    local lastDaily = self:GetLastDailyResetEpoch(nowSec, region);
    if (not lastDaily) then return nil; end
    local nextDaily = lastDaily + 86400;

    -- Weekly reset: Tuesday for US, Wednesday for EU
    -- date("!%w") returns 0=Sun, 1=Mon, 2=Tue, 3=Wed, ...
    local resetWday = (region == "US") and 2 or 3;

    -- Find the next occurrence of resetWday's daily reset
    local candidate = nextDaily;
    for _ = 1, 7 do
        local wday = tonumber(date("!%w", candidate));
        if (wday == resetWday) then
            return candidate;
        end
        candidate = candidate + 86400;
    end
    return nil;
end

-- Converter registry
function addon:RegisterConverter(name, fn)
    if (type(name) ~= "string" or name == "" or type(fn) ~= "function") then
        return;
    end
    converters[name] = fn;
end

function addon:Convert(name, ...)
    local fn = converters[name];
    if (type(fn) == "function") then
        return fn(...);
    end
end

-- Built-in converters
addon:RegisterConverter("money:format_copper", function(amount)
    local copper = tonumber(amount) or 0;
    if (copper <= 0) then return ""; end
    local gold = math.floor(copper / 10000);
    local silver = math.floor((copper % 10000) / 100);
    local coin = copper % 100;
    local function formatThousands(value)
        local str = tostring(value);
        local formatted, count = str:gsub("^(-?%d+)(%d%d%d)", "%1,%2");
        while (count > 0) do
            formatted, count = formatted:gsub("^(-?%d+)(%d%d%d)", "%1,%2");
        end
        return formatted;
    end
    local parts = {};
    if (gold > 0) then table.insert(parts, formatThousands(gold) .. "g"); end
    if (silver > 0) then table.insert(parts, silver .. "s"); end
    if (coin > 0) then table.insert(parts, coin .. "c"); end
    return table.concat(parts, " ");
end);

addon:RegisterConverter("money:parse_gold", function(goldStr)
    -- Strip commas before parsing
    local cleaned = tostring(goldStr):gsub(",", "");
    local num = tonumber(cleaned);
    if (not num or num < 0) then return nil; end
    return num * 10000; -- Convert gold to copper
end);

addon:RegisterConverter("money:format_gold", function(copper)
    local gold = math.floor((tonumber(copper) or 0) / 10000);
    return tostring(gold);
end);

addon:RegisterConverter("money:format_gold_thousands", function(copper)
    local gold = math.floor((tonumber(copper) or 0) / 10000);
    local str = tostring(gold);
    local formatted, count = str:gsub("^(-?%d+)(%d%d%d)", "%1,%2");
    while (count > 0) do
        formatted, count = formatted:gsub("^(-?%d+)(%d%d%d)", "%1,%2");
    end
    return formatted;
end);

-------------------------------------------------------------------------------
-- Database Initialization Helper
-------------------------------------------------------------------------------

function utils.InitModuleDB(addon, key, defaults)
    if (not addon.db) then return nil; end
    if (not addon.db[key]) then
        addon.db[key] = {};
    end
    local db = addon.db[key];
    if (defaults) then
        for k, v in pairs(defaults) do
            if (db[k] == nil) then
                if (type(v) == "table") then
                    local copy = {};
                    for ck, cv in pairs(v) do copy[ck] = cv; end
                    db[k] = copy;
                else
                    db[k] = v;
                end
            end
        end
    end
    return db;
end
