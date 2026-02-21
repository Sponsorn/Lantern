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

utils._optionsRebuilders = utils._optionsRebuilders or {};

function utils.RegisterOptionsRebuilder(key, fn)
    if (type(key) ~= "string" or key == "" or type(fn) ~= "function") then
        return;
    end
    utils._optionsRebuilders[key] = fn;
end

function utils.RunOptionsRebuilder(key)
    local fn = utils._optionsRebuilders and utils._optionsRebuilders[key];
    if (type(fn) == "function") then
        fn();
    end
end

local function GetDailyResetHourCET(region)
    region = region or addon:GetRegion();
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
addon:RegisterConverter("region:normalize", normalizeRegionCode);

addon:RegisterConverter("time:to_iso8601", function(epoch)
    if (not epoch) then return; end
    return date("!%Y-%m-%dT%H:%M:%SZ", epoch);
end);

addon:RegisterConverter("time:seconds_to_clock", function(seconds)
    seconds = tonumber(seconds);
    if (not seconds or seconds < 0) then
        return "0:00";
    end
    local hours = math.floor(seconds / 3600);
    local minutes = math.floor((seconds % 3600) / 60);
    local secs = math.floor(seconds % 60);
    if (hours > 0) then
        return string.format("%d:%02d:%02d", hours, minutes, secs);
    end
    return string.format("%d:%02d", minutes, secs);
end);

addon:RegisterConverter("time:next_reset_epoch", function(now)
    local last = addon:GetLastDailyResetEpoch(now);
    return last and (last + 24 * 60 * 60) or nil;
end);

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

utils.normalizeRegionCode = normalizeRegionCode;
utils.GetDailyResetHourCET = GetDailyResetHourCET;

-- Patch LibRangeCheck-3.0 with spells missing from the upstream library.
-- The lib's spell tables are local, so we hook init() and inject checkers post-init.
-- When the upstream library adds these spells, the duplicate-range guard skips our entries.
do
    local LRC = LibStub and LibStub("LibRangeCheck-3.0", true);
    if (LRC) then
        local _, playerClass = UnitClass("player");

        -- Extra harm spells the library doesn't include yet (keyed by class)
        -- Uses C_Spell.IsSpellInRange (modern API) for tighter range detection
        local EXTRA_HARM = {
            DEATHKNIGHT = {
                { id = 49998, range = 5 },  -- Death Strike (Melee Range)
            },
            DEMONHUNTER = {
                { id = 473662, range = 25 }, -- Consume (Devourer) (25 yards)
                { id = 162243, range = 5 },  -- Demon's Bite (Havoc) (Melee Range)
            },
            HUNTER = {
                { id = 186270, range = 5 },  -- Raptor Strike (Survival) (Melee Range)
            },
            ROGUE = {
                { id = 1752, range = 5 },    -- Sinister Strike (Melee Range)
            },
            WARRIOR = {
                { id = 1464, range = 5 },    -- Slam (Arms/Fury) (Melee Range)
                { id = 23922, range = 5 },   -- Shield Slam (Protection) (Melee Range)
            },
        };

        local spells = EXTRA_HARM[playerClass];
        if (spells) then
            -- Sorted insert matching the lib's addChecker: descending range, skip duplicates
            local function inject(list, range, checker, info)
                for i = 1, #list do
                    if (list[i].range == range) then return; end
                    if (range > list[i].range) then
                        table.insert(list, i, { range = range, minRange = nil, checker = checker, info = info });
                        return;
                    end
                end
                table.insert(list, { range = range, minRange = nil, checker = checker, info = info });
            end

            local origInit = LRC.init;
            LRC.init = function(self, forced)
                origInit(self, forced);
                for _, spell in ipairs(spells) do
                    if (IsPlayerSpell(spell.id)) then
                        local spellID = spell.id; -- capture for closure
                        local checker = function(unit)
                            return C_Spell.IsSpellInRange(spellID, unit);
                        end;
                        local info = "spell:" .. spellID .. ":Lantern";
                        inject(self.harmRC, spell.range, checker, info);
                        inject(self.harmRCInCombat, spell.range, checker, info);
                        inject(self.harmNoItemsRC, spell.range, checker, info);
                        inject(self.harmNoItemsRCInCombat, spell.range, checker, info);
                    end
                end
            end;
        end
    end
end

function utils.GetClassColor(classToken)
    if (not classToken) then return 1, 1, 1; end
    local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken];
    if (color) then
        return color.r, color.g, color.b;
    end
    return 1, 1, 1;
end

-- Input validation helpers
function utils.ValidateString(str, maxLength)
    if (type(str) ~= "string") then return false; end
    if (str == "") then return false; end
    if (maxLength and #str > maxLength) then return false; end
    return true;
end

function utils.SanitizeString(str, maxLength)
    if (type(str) ~= "string") then return ""; end
    local sanitized = str:gsub("[%z\1-\31]", ""); -- Remove control characters
    if (maxLength and #sanitized > maxLength) then
        sanitized = sanitized:sub(1, maxLength);
    end
    return sanitized;
end

function utils.ValidateQuestID(questID)
    local num = tonumber(questID);
    if (not num) then return false; end
    if (num < 1 or num > 999999) then return false; end -- Reasonable quest ID range
    return true;
end
