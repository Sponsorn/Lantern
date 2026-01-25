local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local function autoQueueModule()
    return Lantern.modules and Lantern.modules.AutoQueue;
end

local function autoQueueDB()
    Lantern.db.autoQueue = Lantern.db.autoQueue or {};
    local defaults = { active = true, announce = true };
    for k, v in pairs(defaults) do
        if (Lantern.db.autoQueue[k] == nil) then
            Lantern.db.autoQueue[k] = v;
        end
    end
    return Lantern.db.autoQueue;
end

local function autoQueueDisabled()
    local m = autoQueueModule();
    return not (m and m.enabled);
end

function Lantern:BuildAutoQueueOptions()
    return {
        desc = {
            order = 0,
            type = "description",
            name = "Auto-accepts LFG role checks using your roles set in the LFG tool; hold Shift to pause.",
            fontSize = "medium",
        },
        enabled = {
            order = 1,
            type = "toggle",
            name = "Enable",
            desc = "Enable or disable Auto Queue.",
            width = "full",
            get = function()
                local m = autoQueueModule();
                return m and m.enabled;
            end,
            set = function(_, val)
                if val then
                    Lantern:EnableModule("AutoQueue");
                else
                    Lantern:DisableModule("AutoQueue");
                end
            end,
        },
        active = {
            order = 2,
            type = "toggle",
            name = "Auto-accept role checks",
            desc = "Accept LFG role checks automatically (Shift pauses).",
            width = "full",
            disabled = autoQueueDisabled,
            get = function()
                local db = autoQueueDB();
                return db.active;
            end,
            set = function(_, val)
                local db = autoQueueDB();
                db.active = val and true or false;
            end,
        },
        announce = {
            order = 3,
            type = "toggle",
            name = "Chat announce",
            desc = "Print a chat message when a role check is auto-accepted.",
            width = "full",
            disabled = autoQueueDisabled,
            get = function()
                local db = autoQueueDB();
                return db.announce;
            end,
            set = function(_, val)
                local db = autoQueueDB();
                db.announce = val and true or false;
            end,
        },
        note = {
            order = 4,
            type = "description",
            name = "Roles are set in the LFG tool. This will accept the role check using your current selection.",
            fontSize = "medium",
        },
    };
end
