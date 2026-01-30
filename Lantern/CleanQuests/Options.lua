local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local function cleanQuestsModule()
    return Lantern.modules and Lantern.modules.CleanQuests;
end

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

local function cleanQuestsDisabled()
    local m = cleanQuestsModule();
    return not (m and m.enabled);
end

function Lantern:BuildCleanQuestsOptions()
    return {
        desc = {
            order = 0,
            type = "description",
            name = "Detects hidden tracked quests (a Blizzard bug that can cause FPS drops) and provides cleanup. Use |cff00ff00/lantern clean|r to remove hidden tracked quests.\n\nOriginal discovery by Dramatic-Fortune-416 on Reddit.",
            fontSize = "medium",
        },
        enabled = {
            order = 1,
            type = "toggle",
            name = "Enable",
            desc = "Enable or disable Clean Tracked Quests.",
            width = "full",
            get = function()
                local m = cleanQuestsModule();
                return m and m.enabled;
            end,
            set = function(_, val)
                if val then
                    Lantern:EnableModule("CleanQuests");
                else
                    Lantern:DisableModule("CleanQuests");
                end
            end,
        },
        warnOnLogin = {
            order = 2,
            type = "toggle",
            name = "Warn on login",
            desc = "Show a warning in chat when hidden tracked quests are detected at login (up to 5 times).",
            width = "full",
            disabled = function()
                local db = cleanQuestsDB();
                return cleanQuestsDisabled() or db.autoClean;
            end,
            get = function()
                local db = cleanQuestsDB();
                return db.warnOnLogin;
            end,
            set = function(_, val)
                local db = cleanQuestsDB();
                db.warnOnLogin = val and true or false;
            end,
        },
        autoClean = {
            order = 3,
            type = "toggle",
            name = "Auto-clean on login",
            desc = "Automatically remove hidden tracked quests when logging in.",
            width = "full",
            disabled = cleanQuestsDisabled,
            get = function()
                local db = cleanQuestsDB();
                return db.autoClean;
            end,
            set = function(_, val)
                local db = cleanQuestsDB();
                db.autoClean = val and true or false;
            end,
        },
        autoCleanAnnounce = {
            order = 4,
            type = "toggle",
            name = "Chat announcement",
            desc = "Print a message in chat when quests are auto-cleaned on login.",
            width = "full",
            disabled = function()
                local db = cleanQuestsDB();
                return cleanQuestsDisabled() or not db.autoClean;
            end,
            get = function()
                local db = cleanQuestsDB();
                return db.autoCleanAnnounce;
            end,
            set = function(_, val)
                local db = cleanQuestsDB();
                db.autoCleanAnnounce = val and true or false;
            end,
        },
        cleanupHeader = {
            order = 5,
            type = "header",
            name = "Cleanup",
        },
        cleanupNote = {
            order = 6,
            type = "description",
            name = "Only hidden quests are affected. Your visible tracked quests will not be changed.",
            fontSize = "medium",
        },
        cleanup = {
            order = 7,
            type = "execute",
            name = "Clean hidden tracked quests",
            desc = "Remove all hidden quests from the objective tracker.",
            disabled = cleanQuestsDisabled,
            func = function()
                local m = cleanQuestsModule();
                if (m and m.RunCleanup) then
                    m:RunCleanup();
                end
            end,
        },
    };
end
