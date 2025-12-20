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
    if (shouldPause() or not self.db.autoAccept) then return; end
    if (QuestGetAutoAccept() or QuestIsFromAreaTrigger()) then
        AcknowledgeAutoAcceptQuest();
    else
        AcceptQuest();
    end
end

function module:OnQuestProgress()
    if (shouldPause() or not self.db.autoTurnIn) then return; end
    if (IsQuestCompletable()) then
        CompleteQuest();
    end
end

function module:OnQuestComplete()
    if (shouldPause() or not self.db.autoTurnIn) then return; end
    local numChoices = GetNumQuestChoices() or 0;
    if (numChoices == 0) then
        GetQuestReward(1);
    elseif (numChoices == 1 and self.db.autoSelectSingleReward) then
        GetQuestReward(1);
    end
end

Lantern:RegisterModule(module);
