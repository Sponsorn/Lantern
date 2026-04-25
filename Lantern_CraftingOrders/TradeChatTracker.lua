local ADDON_NAME, ns = ...;
local Lantern = _G.Lantern;
if (not Lantern) then return; end

local CraftingOrders = Lantern.modules and Lantern.modules.CraftingOrders;
if (not CraftingOrders) then return; end

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local DEFAULT_INCLUDE = { "LF", "LFC", "WTB", "recraft" };
local DEFAULT_EXCLUDE = { "LFW", "WTS", "LF work" };

local PROFESSION_KEYWORDS = {
    ["alc"]             = "Alchemy",
    ["alchemist"]       = "Alchemy",
    ["alchemy"]         = "Alchemy",
    ["bs"]              = "Blacksmithing",
    ["blacksmith"]      = "Blacksmithing",
    ["blacksmithing"]   = "Blacksmithing",
    ["cook"]            = "Cooking",
    ["cooking"]         = "Cooking",
    ["chef"]            = "Cooking",
    ["enchant"]         = "Enchanting",
    ["enchanter"]       = "Enchanting",
    ["enchanting"]      = "Enchanting",
    ["eng"]             = "Engineering",
    ["engineer"]        = "Engineering",
    ["engineering"]     = "Engineering",
    ["inscription"]     = "Inscription",
    ["inscriptionist"]  = "Inscription",
    ["scribe"]          = "Inscription",
    ["jc"]              = "Jewelcrafting",
    ["jewelcraft"]      = "Jewelcrafting",
    ["jewelcrafting"]   = "Jewelcrafting",
    ["jewelcrafter"]    = "Jewelcrafting",
    ["lw"]              = "Leatherworking",
    ["leatherwork"]     = "Leatherworking",
    ["leatherworking"]  = "Leatherworking",
    ["leatherworker"]   = "Leatherworking",
    ["tailor"]          = "Tailoring",
    ["tailoring"]       = "Tailoring",
};

-------------------------------------------------------------------------------
-- Database
-------------------------------------------------------------------------------

local function ensureTradeChatDB()
    local db = CraftingOrders:GetHistoryDB();
    if (not db.tradeChat) then
        db.tradeChat = {};
    end
    local tc = db.tradeChat;
    if (tc.enabled == nil) then tc.enabled = false; end
    if (tc.retentionDays == nil) then tc.retentionDays = 30; end
    if (not tc.includeKeywords) then
        tc.includeKeywords = {};
        for _, kw in ipairs(DEFAULT_INCLUDE) do
            table.insert(tc.includeKeywords, kw);
        end
    end
    if (not tc.excludeKeywords) then
        tc.excludeKeywords = {};
        for _, kw in ipairs(DEFAULT_EXCLUDE) do
            table.insert(tc.excludeKeywords, kw);
        end
    end
    if (not tc.buckets) then tc.buckets = {}; end
    return tc;
end

-------------------------------------------------------------------------------
-- Keyword matching
-------------------------------------------------------------------------------

-- Word-boundary-aware check: keyword must be at start/end of message
-- or surrounded by space, punctuation, or bracket characters.
local BOUNDARY_PATTERN = "[%s%p]";

local function isWordBoundary(msg, pos)
    if (pos < 1 or pos > #msg) then return true; end
    return msg:sub(pos, pos):match(BOUNDARY_PATTERN) ~= nil;
end

local function containsKeyword(msg, keyword)
    local kwLower = keyword:lower();
    local kwLen = #kwLower;
    local startPos = 1;
    while (true) do
        local found = msg:find(kwLower, startPos, true);
        if (not found) then return false; end
        local before = found - 1;
        local after = found + kwLen;
        if (isWordBoundary(msg, before) and isWordBoundary(msg, after)) then
            return true;
        end
        startPos = found + 1;
    end
end

local function matchesExclude(msg, excludeList)
    for _, kw in ipairs(excludeList) do
        if (containsKeyword(msg, kw)) then return true; end
    end
    return false;
end

local function matchesInclude(msg, includeList)
    for _, kw in ipairs(includeList) do
        if (containsKeyword(msg, kw)) then return true; end
    end
    return false;
end

local function detectProfession(msg)
    -- Split message into words and check each against profession map
    for word in msg:gmatch("[%w]+") do
        local prof = PROFESSION_KEYWORDS[word:lower()];
        if (prof) then return prof; end
    end
    return nil;
end

-------------------------------------------------------------------------------
-- Bucket storage
-------------------------------------------------------------------------------

local function getRealmTimeComponents()
    local offset = CraftingOrders:GetServerTimeOffset();
    local now = GetServerTime();
    local realmTime = now + offset;
    local dateStr = date("!%Y-%m-%d", realmTime);
    local hour = tonumber(date("!%H", realmTime));
    return dateStr, hour;
end

local function incrementBucket(tc, profession)
    local dateStr, hour = getRealmTimeComponents();
    if (not tc.buckets[dateStr]) then
        tc.buckets[dateStr] = {};
    end
    local dayBuckets = tc.buckets[dateStr];
    if (not dayBuckets[hour]) then
        dayBuckets[hour] = { total = 0, professions = {} };
    end
    local bucket = dayBuckets[hour];
    bucket.total = bucket.total + 1;
    if (profession) then
        bucket.professions[profession] = (bucket.professions[profession] or 0) + 1;
    end
end

local function pruneBuckets(tc)
    local offset = CraftingOrders:GetServerTimeOffset();
    local now = GetServerTime();
    local realmTime = now + offset;
    local cutoff = realmTime - (tc.retentionDays * 86400);
    local cutoffDate = date("!%Y-%m-%d", cutoff);
    for dateKey in pairs(tc.buckets) do
        if (dateKey < cutoffDate) then
            tc.buckets[dateKey] = nil;
        end
    end
end

-------------------------------------------------------------------------------
-- Chat listener
-------------------------------------------------------------------------------

local listenerFrame;

local function OnChatMsgChannel(_, _, msg, _, _, channelName, _, _, _, _, channelBaseName)
    -- In arena environments, chat args can arrive as "secret" values that
    -- cannot be indexed without throwing a taint error. Bail before touching them.
    if (issecretvalue(msg) or issecretvalue(channelBaseName)) then return; end

    -- channelBaseName is "Trade - City" or "Trade (Services) - City"
    -- Match anything starting with "Trade"
    if (not channelBaseName or channelBaseName:sub(1, 5) ~= "Trade") then return; end

    local tc = ensureTradeChatDB();
    local msgLower = msg:lower();

    -- Exclude check first
    if (matchesExclude(msgLower, tc.excludeKeywords)) then return; end

    -- Include check
    if (not matchesInclude(msgLower, tc.includeKeywords)) then return; end

    -- Detect profession
    local profession = detectProfession(msgLower);

    -- Record
    incrementBucket(tc, profession);
end

local pendingAction; -- "register" or "unregister", deferred until combat ends
local combatFrame;

local function ApplyListenerState(action)
    if (not listenerFrame) then
        listenerFrame = CreateFrame("Frame", "LanternCO_TradeChatListener");
    end
    if (action == "register") then
        listenerFrame:RegisterEvent("CHAT_MSG_CHANNEL");
        listenerFrame:SetScript("OnEvent", OnChatMsgChannel);
    else
        listenerFrame:UnregisterEvent("CHAT_MSG_CHANNEL");
        listenerFrame:SetScript("OnEvent", nil);
    end
end

local function DeferUntilCombatEnds(action)
    pendingAction = action;
    if (not combatFrame) then
        combatFrame = CreateFrame("Frame", "LanternCO_TradeChatCombat");
        combatFrame:SetScript("OnEvent", function(self)
            self:UnregisterEvent("PLAYER_REGEN_ENABLED");
            if (pendingAction) then
                ApplyListenerState(pendingAction);
                pendingAction = nil;
            end
        end);
    end
    combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
end

local function RegisterListener()
    if (InCombatLockdown()) then
        DeferUntilCombatEnds("register");
        return;
    end
    pendingAction = nil;
    ApplyListenerState("register");
end

local function UnregisterListener()
    if (InCombatLockdown()) then
        DeferUntilCombatEnds("unregister");
        return;
    end
    pendingAction = nil;
    if (not listenerFrame) then return; end
    ApplyListenerState("unregister");
end

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------

function CraftingOrders:IsTradeChatEnabled()
    local tc = ensureTradeChatDB();
    return tc.enabled;
end

function CraftingOrders:SetTradeChatEnabled(enabled)
    local tc = ensureTradeChatDB();
    tc.enabled = enabled;
    if (enabled) then
        pruneBuckets(tc);
        RegisterListener();
    else
        UnregisterListener();
    end
end

function CraftingOrders:GetTradeChatRetention()
    local tc = ensureTradeChatDB();
    return tc.retentionDays;
end

function CraftingOrders:SetTradeChatRetention(days)
    local tc = ensureTradeChatDB();
    tc.retentionDays = days;
    pruneBuckets(tc);
end

function CraftingOrders:GetTradeChatKeywords()
    local tc = ensureTradeChatDB();
    return { include = tc.includeKeywords, exclude = tc.excludeKeywords };
end

function CraftingOrders:AddTradeChatKeyword(list, word)
    if (not word or word == "") then return false; end
    local tc = ensureTradeChatDB();
    local target = (list == "exclude") and tc.excludeKeywords or tc.includeKeywords;
    -- Check for duplicates (case-insensitive)
    local wordLower = word:lower();
    for _, existing in ipairs(target) do
        if (existing:lower() == wordLower) then return false; end
    end
    table.insert(target, word);
    return true;
end

function CraftingOrders:RemoveTradeChatKeyword(list, word)
    if (not word) then return; end
    local tc = ensureTradeChatDB();
    local target = (list == "exclude") and tc.excludeKeywords or tc.includeKeywords;
    local wordLower = word:lower();
    for i = #target, 1, -1 do
        if (target[i]:lower() == wordLower) then
            table.remove(target, i);
            return;
        end
    end
end

-- Suspend/resume without persisting the enabled state to the DB.
-- Called by CraftingOrders:OnDisable() / OnEnable() to tie the listener
-- to the module lifecycle.
function CraftingOrders:SuspendTradeChat()
    UnregisterListener();
end

function CraftingOrders:ResumeTradeChat()
    local tc = ensureTradeChatDB();
    if (tc.enabled) then
        pruneBuckets(tc);
        RegisterListener();
    end
end

function CraftingOrders:GetTradeChatHeatMapData(since)
    local tc = ensureTradeChatDB();
    local grid = {};
    local professions = {};
    local maxTotal = 0;

    for day = 0, 6 do
        grid[day] = {};
        professions[day] = {};
        for hour = 0, 23 do
            grid[day][hour] = 0;
            professions[day][hour] = {};
        end
    end

    local offset = CraftingOrders:GetServerTimeOffset();
    local sinceDate = since and date("!%Y-%m-%d", since + offset) or nil;

    for dateKey, dayBuckets in pairs(tc.buckets) do
        if (not sinceDate or dateKey >= sinceDate) then
            local y, m, d = dateKey:match("(%d+)-(%d+)-(%d+)");
            if (y) then
                -- Day of week via Tomohiko Sakamoto's algorithm (avoids time()/date() timezone mismatch)
                local yn, mn, dn = tonumber(y), tonumber(m), tonumber(d);
                local t = { 0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4 };
                if (mn < 3) then yn = yn - 1; end
                local wday = (yn + math.floor(yn / 4) - math.floor(yn / 100) + math.floor(yn / 400) + t[mn] + dn) % 7;
                -- Result: 0=Sun, 1=Mon, ..., 6=Sat (matches date("%w") convention)
                for hour, bucket in pairs(dayBuckets) do
                    if (type(hour) == "number") then
                        grid[wday][hour] = grid[wday][hour] + bucket.total;
                        if (grid[wday][hour] > maxTotal) then
                            maxTotal = grid[wday][hour];
                        end
                        for prof, count in pairs(bucket.professions) do
                            professions[wday][hour][prof] = (professions[wday][hour][prof] or 0) + count;
                        end
                    end
                end
            end
        end
    end

    return {
        grid = grid,
        professions = professions,
        maxTotal = maxTotal,
    };
end

-------------------------------------------------------------------------------
-- Initialize on load
-------------------------------------------------------------------------------

local function InitTradeChat()
    local tc = ensureTradeChatDB();
    if (tc.enabled) then
        pruneBuckets(tc);
        RegisterListener();
    end
end

-- Initialize on PLAYER_LOGIN (DB is available by then)
local initFrame = CreateFrame("Frame", "LanternCO_TradeChatInit");
initFrame:RegisterEvent("PLAYER_LOGIN");
initFrame:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN");
    InitTradeChat();
end);
