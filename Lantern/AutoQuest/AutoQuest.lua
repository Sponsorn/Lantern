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
    if (IsShiftKeyDown()) then return true; end
    return false;
end

-------------------------------------------------------------------------------
-- Combat Lockdown Handling
-------------------------------------------------------------------------------

local pendingActions = {}

local combatFrame = CreateFrame("Frame")
combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
combatFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_ENABLED" then
        -- Process any pending actions now that combat has ended
        for i, action in ipairs(pendingActions) do
            local success, err = pcall(action.func, unpack(action.args or {}))
            if not success and err then
                -- Silently ignore - the quest dialog may have closed
            end
        end
        wipe(pendingActions)
    end
end)

-- Safely call a function, deferring if in combat lockdown
local function SafeCall(func, ...)
    if InCombatLockdown() then
        table.insert(pendingActions, { func = func, args = {...} })
        return false
    else
        local success, err = pcall(func, ...)
        return success
    end
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

local function ensureDB(self)
    -- Ensure parent db exists
    if (not self.addon.db) then
        return;
    end
    -- Initialize autoQuest table if it doesn't exist
    if (not self.addon.db.autoQuest) then
        self.addon.db.autoQuest = {};
    end
    -- Always reference the addon's autoQuest table directly
    self.db = self.addon.db.autoQuest;

    for k, v in pairs(DEFAULTS) do
        if (self.db[k] == nil) then self.db[k] = v; end
    end
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
    if (not self.db.autoAccept or shouldPause() or self:IsCurrentNPCBlocked()) then return; end
    if (C_GossipInfo and C_GossipInfo.GetAvailableQuests) then
        local quests = C_GossipInfo.GetAvailableQuests();
        for _, q in ipairs(quests or {}) do
            if (q and q.questID and not self:IsQuestBlocked(q.questID)) then
                SafeCall(C_GossipInfo.SelectAvailableQuest, q.questID);
                return; -- Process one quest per event; next GOSSIP_SHOW handles remaining
            end
        end
    end
end

local function handleActiveQuests(self)
    if (not self.db.autoTurnIn or shouldPause() or self:IsCurrentNPCBlocked()) then return; end
    if (C_GossipInfo and C_GossipInfo.GetActiveQuests) then
        local quests = C_GossipInfo.GetActiveQuests();
        for _, q in ipairs(quests or {}) do
            if (q and q.questID and (q.isComplete or isQuestReadyForTurnIn(q.questID)) and not self:IsQuestBlocked(q.questID)) then
                SafeCall(C_GossipInfo.SelectActiveQuest, q.questID);
                return; -- Process one quest per event; next GOSSIP_SHOW handles remaining
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
    if (self.db.autoTurnIn and GetNumActiveQuests and GetActiveTitle and SelectActiveQuest) then
        local count = GetNumActiveQuests() or 0;
        for i = 1, count do
            local questID = GetActiveQuestID and GetActiveQuestID(i);
            local title, _, _, isComplete = GetActiveTitle(i);
            local ready = isComplete or isQuestReadyForTurnIn(questID);
            if (ready and not self:IsQuestNameBlocked(title)) then
                SafeCall(SelectActiveQuest, i);
                return; -- Process one quest per event; next QUEST_GREETING handles remaining
            end
        end
    end
    if (self.db.autoAccept and GetNumAvailableQuests and GetAvailableTitle and SelectAvailableQuest) then
        local count = GetNumAvailableQuests() or 0;
        for i = 1, count do
            local title = GetAvailableTitle(i);
            if (not self:IsQuestNameBlocked(title)) then
                SafeCall(SelectAvailableQuest, i);
                return; -- Process one quest per event; next QUEST_GREETING handles remaining
            end
        end
    end
end

function module:OnQuestDetail()
    if (shouldPause() or not self.db.autoAccept or self:IsCurrentNPCBlocked()) then return; end
    local questID = GetQuestID and GetQuestID();
    if (self:IsQuestBlocked(questID)) then return; end
    local title = GetTitleText and GetTitleText();
    -- Capture NPC key before accepting quest (in case dialog closes)
    local npcKey = self:GetCurrentNPCKey();
    if (QuestGetAutoAccept() or QuestIsFromAreaTrigger()) then
        SafeCall(AcknowledgeAutoAcceptQuest);
    else
        SafeCall(AcceptQuest);
    end
    -- Store NPC key temporarily for logging
    self._lastNPCKey = npcKey;
    self:LogAutomatedQuest(title, questID);
end

function module:OnQuestProgress()
    if (shouldPause() or not self.db.autoTurnIn or self:IsCurrentNPCBlocked()) then return; end
    local questID = GetQuestID and GetQuestID();
    if (IsQuestCompletable() or isQuestReadyForTurnIn(questID)) then
        if (self:IsQuestBlocked(questID)) then return; end
        local title = GetTitleText and GetTitleText();
        -- Capture NPC key before completing quest (in case dialog closes)
        local npcKey = self:GetCurrentNPCKey();
        SafeCall(CompleteQuest);
        -- Store NPC key temporarily for logging
        self._lastNPCKey = npcKey;
        self:LogAutomatedQuest(title, questID);
    end
end

function module:OnQuestComplete()
    if (shouldPause() or not self.db.autoTurnIn or self:IsCurrentNPCBlocked()) then return; end
    local numChoices = GetNumQuestChoices() or 0;
    local questID = GetQuestID and GetQuestID();
    if (self:IsQuestBlocked(questID)) then return; end
    local title = GetTitleText and GetTitleText();
    -- Capture NPC key before getting quest reward (in case dialog closes)
    local npcKey = self:GetCurrentNPCKey();
    if (numChoices == 0) then
        SafeCall(GetQuestReward, 1);
        -- Store NPC key temporarily for logging
        self._lastNPCKey = npcKey;
        self:LogAutomatedQuest(title, questID);
    elseif (numChoices == 1 and self.db.autoSelectSingleReward) then
        SafeCall(GetQuestReward, 1);
        -- Store NPC key temporarily for logging
        self._lastNPCKey = npcKey;
        self:LogAutomatedQuest(title, questID);
    end
end

Lantern:RegisterModule(module);
