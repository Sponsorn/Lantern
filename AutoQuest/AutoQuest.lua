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
    skipNPCs = {},
};

local function shouldPause()
    return IsShiftKeyDown();
end

local function ensureDB(self)
    self.db = self.addon.db.autoQuest or {};
    self.addon.db.autoQuest = self.db;
    for k, v in pairs(DEFAULTS) do
        if (self.db[k] == nil) then
            self.db[k] = (type(v) == "table") and {} or v;
        end
    end
end

local function parseNPCIDFromGUID(guid)
    if (not guid) then return; end
    local typeBits, _, _, _, _, npcID = strsplit("-", guid);
    if (typeBits ~= "Creature" and typeBits ~= "Vehicle" and typeBits ~= "Vignette") then
        return;
    end
    npcID = tonumber(npcID);
    if (npcID and npcID > 0) then
        return npcID;
    end
end

function module:GetCurrentNPCInfo()
    local unit = (UnitExists("npc") and "npc") or (UnitExists("target") and "target") or nil;
    if (not unit or UnitIsPlayer(unit)) then
        return;
    end
    local guid = UnitGUID(unit);
    local npcID = parseNPCIDFromGUID(guid);
    if (not npcID) then return; end
    local name = UnitName(unit);
    return npcID, name;
end

function module:IsNPCSkipped(npcID)
    return npcID and self.db.skipNPCs and self.db.skipNPCs[npcID] or false;
end

function module:AddSkippedNPC(npcID, name)
    npcID = tonumber(npcID);
    if (not npcID) then return; end
    self.db.skipNPCs = self.db.skipNPCs or {};
    self.db.skipNPCs[npcID] = name or true;
end

function module:RemoveSkippedNPC(npcID)
    npcID = tonumber(npcID);
    if (not npcID or not self.db.skipNPCs) then return; end
    self.db.skipNPCs[npcID] = nil;
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
    self.addon:ModuleRegisterEvent(self, "QUEST_DETAIL", self.OnQuestDetail);
    self.addon:ModuleRegisterEvent(self, "QUEST_PROGRESS", self.OnQuestProgress);
    self.addon:ModuleRegisterEvent(self, "QUEST_COMPLETE", self.OnQuestComplete);
end

local function handleAvailableQuests(self)
    local npcID = self:GetCurrentNPCInfo();
    if (self:IsNPCSkipped(npcID)) then return; end
    if (not self.db.autoAccept or shouldPause()) then return; end
    if (C_GossipInfo and C_GossipInfo.GetAvailableQuests) then
        local quests = C_GossipInfo.GetAvailableQuests();
        for _, q in ipairs(quests or {}) do
            if (q and q.questID and not q.repeatable and not q.isTrivial) then
                C_GossipInfo.SelectAvailableQuest(q.questID);
            end
        end
    end
end

local function handleActiveQuests(self)
    local npcID = self:GetCurrentNPCInfo();
    if (self:IsNPCSkipped(npcID)) then return; end
    if (not self.db.autoTurnIn or shouldPause()) then return; end
    if (C_GossipInfo and C_GossipInfo.GetActiveQuests) then
        local quests = C_GossipInfo.GetActiveQuests();
        for _, q in ipairs(quests or {}) do
            if (q and q.questID and q.isComplete) then
                C_GossipInfo.SelectActiveQuest(q.questID);
            end
        end
    end
end

function module:OnGossipShow()
    handleAvailableQuests(self);
    handleActiveQuests(self);
end

function module:OnQuestDetail()
    local npcID = self:GetCurrentNPCInfo();
    if (self:IsNPCSkipped(npcID)) then return; end
    if (shouldPause() or not self.db.autoAccept) then return; end
    if (QuestGetAutoAccept() or QuestIsFromAreaTrigger()) then
        AcknowledgeAutoAcceptQuest();
    else
        AcceptQuest();
    end
end

function module:OnQuestProgress()
    local npcID = self:GetCurrentNPCInfo();
    if (self:IsNPCSkipped(npcID)) then return; end
    if (shouldPause() or not self.db.autoTurnIn) then return; end
    if (IsQuestCompletable()) then
        CompleteQuest();
    end
end

function module:OnQuestComplete()
    local npcID = self:GetCurrentNPCInfo();
    if (self:IsNPCSkipped(npcID)) then return; end
    if (shouldPause() or not self.db.autoTurnIn) then return; end
    local numChoices = GetNumQuestChoices() or 0;
    if (numChoices == 0) then
        GetQuestReward(1);
    elseif (numChoices == 1 and self.db.autoSelectSingleReward) then
        GetQuestReward(1);
    end
end

Lantern:RegisterModule(module);
