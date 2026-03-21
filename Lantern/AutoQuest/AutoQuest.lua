local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end
local L = Lantern.L;

local module = Lantern:NewModule("AutoQuest", {
    title = L["AUTOQUEST_TITLE"],
    desc = L["AUTOQUEST_DESC"],
    defaultEnabled = true,
    skipOptions = true, -- options are shown under Lantern > General Options instead
});

local DEFAULTS = {
    autoAccept = true,
    autoTurnIn = true,
    autoSelectSingleReward = true,
    autoSelectSingleGossip = true,
    skipTrivialQuests = false,
};

local EXCLUDED_INSTANCE_MAPS = {
    [2513] = true, -- Tainted by quest automation
};

local BLOCKED_NPC_IDS = {
    [256203] = true, -- Lady Liadrin (weekly quest selection)
};

local function shouldPause()
    return Lantern:IsModifierDown() or InCombatLockdown();
end

local function isExcludedMap()
    local instanceID = select(8, GetInstanceInfo());
    return instanceID and EXCLUDED_INSTANCE_MAPS[instanceID] or false;
end

local function isQuestReadyForTurnIn(questID)
    if (not questID) then return false; end
    if (C_QuestLog and C_QuestLog.ReadyForTurnIn and C_QuestLog.ReadyForTurnIn(questID)) then
        return true;
    end
    if (C_QuestLog and C_QuestLog.IsComplete and C_QuestLog.IsComplete(questID)) then
        return true;
    end
    return false;
end

local function isQuestTrivial(questID)
    if (not questID) then return false; end
    if (C_QuestLog and C_QuestLog.IsQuestTrivial) then
        return C_QuestLog.IsQuestTrivial(questID);
    end
    return false;
end

local function ensureDB(self)
    self.db = Lantern.utils.InitModuleDB(self.addon, "autoQuest", DEFAULTS);
    if (not self.db) then return; end
    if (type(self.db.blockedNPCs) ~= "table") then
        self.db.blockedNPCs = {};
    end
    if (type(self.db.blockedQuests) ~= "table") then
        self.db.blockedQuests = {};
    end
    if (type(self.db.blockedQuestNames) ~= "table") then
        self.db.blockedQuestNames = {};
    end
    if (next(self.db.blockedQuestNames) == nil) then
        for _, value in pairs(self.db.blockedQuests) do
            if (type(value) == "string" and value ~= "") then
                self.db.blockedQuestNames[value] = true;
            elseif (type(value) == "table" and type(value.name) == "string" and value.name ~= "") then
                self.db.blockedQuestNames[value.name] = true;
            end
        end
    end
    if (type(self.db.recentAutomated) ~= "table") then
        self.db.recentAutomated = {};
    end
end

function module:OnInit()
    ensureDB(self);
end

function module:OnEnable()
    ensureDB(self);
    self.addon:ModuleRegisterEvent(self, "GOSSIP_SHOW", self.OnGossipShow);
    self.addon:ModuleRegisterEvent(self, "QUEST_GREETING", self.OnQuestGreeting);
    self.addon:ModuleRegisterEvent(self, "QUEST_DETAIL", self.OnQuestDetail);
    self.addon:ModuleRegisterEvent(self, "QUEST_PROGRESS", self.OnQuestProgress);
    self.addon:ModuleRegisterEvent(self, "QUEST_COMPLETE", self.OnQuestComplete);
end

function module:GetCurrentNPCKey()
    local unit = "npc";
    if (not (UnitExists and UnitExists(unit))) then
        unit = "target";
    end
    if (not (UnitExists and UnitExists(unit))) then
        return nil;
    end
    if (UnitIsPlayer and UnitIsPlayer(unit)) then
        return nil;
    end
    local name = UnitName and UnitName(unit);
    if (not name or name == "") then
        return nil;
    end
    local zone = GetZoneText and GetZoneText() or "";
    if (zone == "") then
        zone = "Unknown Zone";
    end
    return string.format("%s - %s", name, zone);
end

function module:IsCurrentNPCBlocked()
    -- Check hardcoded NPC ID blocklist (check both units since "npc" can be the player)
    for _, unit in ipairs({"npc", "target"}) do
        if (UnitExists(unit) and not UnitIsPlayer(unit)) then
            local guid = UnitGUID(unit);
            if (guid) then
                local npcID = select(6, strsplit("-", guid));
                if (npcID and BLOCKED_NPC_IDS[tonumber(npcID)]) then
                    return true;
                end
            end
        end
    end
    -- Check user-configured NPC blocklist
    local key = self:GetCurrentNPCKey();
    if (not key) then return false; end
    return self.db and self.db.blockedNPCs and self.db.blockedNPCs[key] or false;
end

function module:IsQuestBlocked(questID)
    if (not questID) then return false; end
    local list = self.db and self.db.blockedQuests;
    if (not list) then return false; end
    local id = tonumber(questID) or questID;
    if (list[id]) then return true; end
    local idStr = tostring(id);
    return list[idStr] and true or false;
end

function module:IsQuestNameBlocked(name)
    if (not name or name == "") then return false; end
    local list = self.db and self.db.blockedQuests;
    if (not list) then return false; end
    local names = self.db and self.db.blockedQuestNames;
    if (names and names[name]) then
        return true;
    end
    for _, value in pairs(list) do
        if (value == name) then
            return true;
        end
        if (type(value) == "table" and value.name == name) then
            return true;
        end
    end
    return false;
end

function module:LogAutomatedQuest(questName, questID)
    if (not questName or questName == "") then
        return;
    end
    local list = self.db and self.db.recentAutomated;
    if (type(list) ~= "table") then
        list = {};
        self.db.recentAutomated = list;
    end
    if (questID) then
        local id = tonumber(questID) or questID;
        local idStr = tostring(id);
        for i = #list, 1, -1 do
            local entry = list[i];
            if (entry and (entry.questID == id or entry.questID == idStr)) then
                table.remove(list, i);
            end
        end
    end
    -- Use cached NPC key if current one is nil (dialog may have closed)
    local npcKey = self:GetCurrentNPCKey() or self._lastNPCKey;
    table.insert(list, 1, {
        name = questName,
        questID = questID,
        npcKey = npcKey,
        time = GetServerTime and GetServerTime() or time(),
    });
    -- Clear the cached NPC key
    self._lastNPCKey = nil;
    for i = #list, 6, -1 do
        list[i] = nil;
    end
end

local function handleAvailableQuests(self)
    if (not self.db.autoAccept or shouldPause() or isExcludedMap() or self:IsCurrentNPCBlocked()) then return; end
    if (C_GossipInfo and C_GossipInfo.GetAvailableQuests) then
        local quests = C_GossipInfo.GetAvailableQuests();
        for _, q in ipairs(quests or {}) do
            if (q and q.questID and not self:IsQuestBlocked(q.questID)) then
                -- Skip trivial quests if option enabled
                if (self.db.skipTrivialQuests and (q.isTrivial or isQuestTrivial(q.questID))) then
                    -- Skip this quest
                else
                    C_GossipInfo.SelectAvailableQuest(q.questID);
                    return; -- Process one quest per event; next GOSSIP_SHOW handles remaining
                end
            end
        end
    end
end

local function handleActiveQuests(self)
    if (not self.db.autoTurnIn or shouldPause() or isExcludedMap() or self:IsCurrentNPCBlocked()) then return; end
    if (C_GossipInfo and C_GossipInfo.GetActiveQuests) then
        local quests = C_GossipInfo.GetActiveQuests();
        for _, q in ipairs(quests or {}) do
            if (q and q.questID and (q.isComplete or isQuestReadyForTurnIn(q.questID)) and not self:IsQuestBlocked(q.questID)) then
                C_GossipInfo.SelectActiveQuest(q.questID);
                return; -- Process one quest per event; next GOSSIP_SHOW handles remaining
            end
        end
    end
end

function module:OnGossipShow()
    handleAvailableQuests(self);
    handleActiveQuests(self);

    -- Auto-select single gossip option to progress through dialog chains
    if (not self.db.autoSelectSingleGossip) then return; end
    if (shouldPause() or self:IsCurrentNPCBlocked()) then return; end
    local numAvail = C_GossipInfo.GetNumAvailableQuests and C_GossipInfo.GetNumAvailableQuests() or 0;
    local numActive = C_GossipInfo.GetNumActiveQuests and C_GossipInfo.GetNumActiveQuests() or 0;
    if (numAvail > 0 or numActive > 0) then return; end
    local options = C_GossipInfo.GetOptions and C_GossipInfo.GetOptions();
    if (options and #options == 1 and options[1].gossipOptionID) then
        C_GossipInfo.SelectOption(options[1].gossipOptionID);
    end
end

function module:OnQuestGreeting()
    if (shouldPause() or isExcludedMap() or self:IsCurrentNPCBlocked()) then return; end
    if (self.db.autoTurnIn and GetNumActiveQuests and GetActiveTitle and SelectActiveQuest) then
        local count = GetNumActiveQuests() or 0;
        for i = 1, count do
            local questID = GetActiveQuestID and GetActiveQuestID(i);
            local title, _, _, isComplete = GetActiveTitle(i);
            local ready = isComplete or isQuestReadyForTurnIn(questID);
            if (ready and not self:IsQuestNameBlocked(title)) then
                SelectActiveQuest(i);
                return; -- Process one quest per event; next QUEST_GREETING handles remaining
            end
        end
    end
    if (self.db.autoAccept and GetNumAvailableQuests and GetAvailableTitle and SelectAvailableQuest) then
        local count = GetNumAvailableQuests() or 0;
        for i = 1, count do
            local title = GetAvailableTitle(i);
            if (not self:IsQuestNameBlocked(title)) then
                SelectAvailableQuest(i);
                return; -- Process one quest per event; next QUEST_GREETING handles remaining
            end
        end
    end
end

function module:OnQuestDetail()
    if (shouldPause() or not self.db.autoAccept or isExcludedMap() or self:IsCurrentNPCBlocked()) then return; end
    local questID = GetQuestID and GetQuestID();
    if (self:IsQuestBlocked(questID)) then return; end
    if (self.db.skipTrivialQuests and isQuestTrivial(questID)) then return; end
    local title = GetTitleText and GetTitleText();
    -- Capture NPC key before accepting quest (in case dialog closes)
    local npcKey = self:GetCurrentNPCKey();
    if (QuestGetAutoAccept() or QuestIsFromAreaTrigger()) then
        AcknowledgeAutoAcceptQuest();
    else
        AcceptQuest();
    end
    -- Store NPC key temporarily for logging
    self._lastNPCKey = npcKey;
    self:LogAutomatedQuest(title, questID);
end

function module:OnQuestProgress()
    if (shouldPause() or not self.db.autoTurnIn or isExcludedMap() or self:IsCurrentNPCBlocked()) then return; end
    local questID = GetQuestID and GetQuestID();
    if (IsQuestCompletable() or isQuestReadyForTurnIn(questID)) then
        if (self:IsQuestBlocked(questID)) then return; end
        local title = GetTitleText and GetTitleText();
        -- Capture NPC key before completing quest (in case dialog closes)
        local npcKey = self:GetCurrentNPCKey();
        CompleteQuest();
        -- Store NPC key temporarily for logging
        self._lastNPCKey = npcKey;
        self:LogAutomatedQuest(title, questID);
    end
end

function module:OnQuestComplete()
    if (shouldPause() or not self.db.autoTurnIn or isExcludedMap() or self:IsCurrentNPCBlocked()) then return; end
    local numChoices = GetNumQuestChoices() or 0;
    local questID = GetQuestID and GetQuestID();
    if (self:IsQuestBlocked(questID)) then return; end
    local title = GetTitleText and GetTitleText();
    -- Capture NPC key before getting quest reward (in case dialog closes)
    local npcKey = self:GetCurrentNPCKey();
    if (numChoices == 0) then
        GetQuestReward(1);
        -- Store NPC key temporarily for logging
        self._lastNPCKey = npcKey;
        self:LogAutomatedQuest(title, questID);
    elseif (numChoices == 1 and self.db.autoSelectSingleReward) then
        GetQuestReward(1);
        -- Store NPC key temporarily for logging
        self._lastNPCKey = npcKey;
        self:LogAutomatedQuest(title, questID);
    end
end

Lantern:RegisterModule(module);
