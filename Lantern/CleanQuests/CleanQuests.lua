local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local MAX_LOGIN_WARNINGS = 5;

local module = Lantern:NewModule("CleanQuests", {
    title = "Clean Tracked Quests",
    desc = "Detects hidden tracked quests that may cause FPS issues.",
    skipOptions = true,
});

local function cleanQuestsDB()
    Lantern.db.cleanQuests = Lantern.db.cleanQuests or {};
    local defaults = { warnOnLogin = true, loginWarnCount = 0, autoClean = false, autoCleanAnnounce = true };
    for k, v in pairs(defaults) do
        if (Lantern.db.cleanQuests[k] == nil) then
            Lantern.db.cleanQuests[k] = v;
        end
    end
    return Lantern.db.cleanQuests;
end

local function GetHiddenTrackedQuests()
    local hidden = {};
    local numEntries = C_QuestLog.GetNumQuestLogEntries();
    for i = 1, numEntries do
        local info = C_QuestLog.GetInfo(i);
        if (info and not info.isHeader and info.isHidden) then
            local questID = info.questID;
            if (questID) then
                table.insert(hidden, questID);
            end
        end
    end
    return hidden;
end

function module:RunCleanup(silent)
    local hidden = GetHiddenTrackedQuests();
    if (#hidden == 0) then
        if (not silent) then
            Lantern:Print("No hidden tracked quests found.");
        end
        return;
    end
    for _, questID in ipairs(hidden) do
        C_QuestLog.RemoveQuestWatch(questID);
    end
    if (not silent) then
        Lantern:Print(string.format("Cleaned %d hidden tracked quest(s).", #hidden));
    end
end

function module:OnPlayerLogin()
    C_Timer.After(3, function()
        if (not module.enabled) then return; end
        local db = cleanQuestsDB();

        if (db.autoClean) then
            local silent = not db.autoCleanAnnounce;
            module:RunCleanup(silent);
            return;
        end

        if (not db.warnOnLogin) then return; end
        if (db.loginWarnCount >= MAX_LOGIN_WARNINGS) then return; end

        local hidden = GetHiddenTrackedQuests();
        if (#hidden == 0) then return; end

        local remaining = MAX_LOGIN_WARNINGS - db.loginWarnCount;
        db.loginWarnCount = db.loginWarnCount + 1;

        Lantern:Print(string.format(
            "This message will be shown %d more time(s), you can disable it in options. Detected %d hidden tracked quest(s) (may cause FPS issues). Type %s or open the options panel to get more information.",
            remaining,
            #hidden,
            "|cff00ff00/lantern clean|r"
        ));
    end);
end

function module:OnCleanMessage()
    if (not module.enabled) then
        Lantern:Print("Clean Tracked Quests module is disabled. Enable it in options.");
        return;
    end
    module:RunCleanup();
end

function module:OnEnable()
    self.addon:ModuleRegisterEvent(self, "PLAYER_LOGIN", self.OnPlayerLogin);
    self.addon:RegisterMessage("LANTERN_CLEAN_QUESTS", function()
        module:OnCleanMessage();
    end);
end

function module:OnDisable()
    -- Events auto-unregistered; message listener is lightweight
end

Lantern:RegisterModule(module);
