local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local module = Lantern:NewModule("AutoQuest", {
    title = "Auto Quest",
    desc = "Automatically accept/turn-in quests; hold Shift to pause.",
    skipOptions = true, -- options are shown under Lantern > General Options instead
});

local DEFAULTS = {
    autoAccept = true,
    autoTurnIn = true,
    autoSelectSingleReward = true,
};

local function shouldPause()
    return IsShiftKeyDown();
end

local function ensureDB(self)
    self.db = self.addon.db.autoQuest or {};
    self.addon.db.autoQuest = self.db;
    for k, v in pairs(DEFAULTS) do
        if (self.db[k] == nil) then self.db[k] = v; end
    end
    if (type(self.db.blockedNPCs) ~= "table") then
        self.db.blockedNPCs = {};
    end
    if (type(self.db.blockedQuests) ~= "table") then
        self.db.blockedQuests = {};
    end
    if (type(self.db.recentAutomated) ~= "table") then
        self.db.recentAutomated = {};
    end
end

function module:GetOptions()
    return {
        autoAccept = {
            type = "toggle",
            name = "Auto-accept quests",
            desc = "Automatically accept quests from NPCs.",
            width = "full",
            get = function() return module.db and module.db.autoAccept; end,
            set = function(_, val) module.db.autoAccept = val and true or false; end,
        },
        autoTurnIn = {
            type = "toggle",
            name = "Auto turn-in quests",
            desc = "Automatically turn in completed quests to NPCs.",
            width = "full",
            get = function() return module.db and module.db.autoTurnIn; end,
            set = function(_, val) module.db.autoTurnIn = val and true or false; end,
        },
        autoSelectSingleReward = {
            type = "toggle",
            name = "Auto select single reward",
            desc = "If a quest offers only one reward, auto-select it.",
            width = "full",
            get = function() return module.db and module.db.autoSelectSingleReward; end,
            set = function(_, val) module.db.autoSelectSingleReward = val and true or false; end,
        },
    };
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
    table.insert(list, 1, {
        name = questName,
        questID = questID,
        npcKey = self:GetCurrentNPCKey(),
        time = GetServerTime and GetServerTime() or time(),
    });
    for i = #list, 6, -1 do
        list[i] = nil;
    end
end

local function handleAvailableQuests(self)
    if (not self.db.autoAccept or shouldPause() or self:IsCurrentNPCBlocked()) then return; end
    if (C_GossipInfo and C_GossipInfo.GetAvailableQuests) then
        local quests = C_GossipInfo.GetAvailableQuests();
        for _, q in ipairs(quests or {}) do
            if (q and q.questID and not q.isTrivial and not self:IsQuestBlocked(q.questID)) then
                C_GossipInfo.SelectAvailableQuest(q.questID);
            end
        end
    end
end

local function handleActiveQuests(self)
    if (not self.db.autoTurnIn or shouldPause() or self:IsCurrentNPCBlocked()) then return; end
    if (C_GossipInfo and C_GossipInfo.GetActiveQuests) then
        local quests = C_GossipInfo.GetActiveQuests();
        for _, q in ipairs(quests or {}) do
            if (q and q.questID and q.isComplete and not self:IsQuestBlocked(q.questID)) then
                C_GossipInfo.SelectActiveQuest(q.questID);
            end
        end
    end
end

function module:OnGossipShow()
    handleAvailableQuests(self);
    handleActiveQuests(self);
end

function module:OnQuestGreeting()
    if (shouldPause()) then return; end
    if (self.db.autoAccept and GetNumAvailableQuests and GetAvailableTitle and SelectAvailableQuest) then
        local count = GetNumAvailableQuests() or 0;
        for i = 1, count do
            local title, _, isTrivial = GetAvailableTitle(i);
            if (not isTrivial and not self:IsQuestNameBlocked(title)) then
                SelectAvailableQuest(i);
            end
        end
    end
end

function module:OnQuestDetail()
    if (shouldPause() or not self.db.autoAccept or self:IsCurrentNPCBlocked()) then return; end
    local questID = GetQuestID and GetQuestID();
    if (self:IsQuestBlocked(questID)) then return; end
    local title = GetTitleText and GetTitleText();
    if (QuestGetAutoAccept() or QuestIsFromAreaTrigger()) then
        AcknowledgeAutoAcceptQuest();
    else
        AcceptQuest();
    end
    self:LogAutomatedQuest(title, questID);
end

function module:OnQuestProgress()
    if (shouldPause() or not self.db.autoTurnIn or self:IsCurrentNPCBlocked()) then return; end
    if (IsQuestCompletable()) then
        local questID = GetQuestID and GetQuestID();
        if (self:IsQuestBlocked(questID)) then return; end
        local title = GetTitleText and GetTitleText();
        CompleteQuest();
        self:LogAutomatedQuest(title, questID);
    end
end

function module:OnQuestComplete()
    if (shouldPause() or not self.db.autoTurnIn or self:IsCurrentNPCBlocked()) then return; end
    local numChoices = GetNumQuestChoices() or 0;
    local questID = GetQuestID and GetQuestID();
    if (self:IsQuestBlocked(questID)) then return; end
    local title = GetTitleText and GetTitleText();
    if (numChoices == 0) then
        GetQuestReward(1);
        self:LogAutomatedQuest(title, questID);
    elseif (numChoices == 1 and self.db.autoSelectSingleReward) then
        GetQuestReward(1);
        self:LogAutomatedQuest(title, questID);
    end
end

Lantern:RegisterModule(module);
