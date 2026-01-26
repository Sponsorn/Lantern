local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local function autoQuestModule()
    return Lantern.modules and Lantern.modules.AutoQuest;
end

local function autoQuestDB()
    Lantern.db.autoQuest = Lantern.db.autoQuest or {};
    local defaults = { autoAccept = true, autoTurnIn = true, autoSelectSingleReward = true, skipTrivialQuests = false };
    for k, v in pairs(defaults) do
        if (Lantern.db.autoQuest[k] == nil) then
            Lantern.db.autoQuest[k] = v;
        end
    end
    if (type(Lantern.db.autoQuest.blockedNPCs) ~= "table") then
        Lantern.db.autoQuest.blockedNPCs = {};
    end
    if (type(Lantern.db.autoQuest.blockedQuests) ~= "table") then
        Lantern.db.autoQuest.blockedQuests = {};
    end
    if (Lantern.db.autoQuest.blockedNPCFilter == nil) then
        Lantern.db.autoQuest.blockedNPCFilter = "current";
    end
    return Lantern.db.autoQuest;
end

local function autoQuestBlockedList()
    local db = autoQuestDB();
    db.blockedNPCs = db.blockedNPCs or {};
    return db.blockedNPCs;
end

local function autoQuestBlockedQuestList()
    local db = autoQuestDB();
    db.blockedQuests = db.blockedQuests or {};
    return db.blockedQuests;
end

local function autoQuestBlockedQuestNames()
    local db = autoQuestDB();
    db.blockedQuestNames = db.blockedQuestNames or {};
    return db.blockedQuestNames;
end

local function autoQuestRecentList()
    local db = autoQuestDB();
    db.recentAutomated = db.recentAutomated or {};
    return db.recentAutomated;
end

local function autoQuestBlockedFilter()
    local db = autoQuestDB();
    if (db.blockedNPCFilter == nil) then
        db.blockedNPCFilter = "current";
    end
    return db.blockedNPCFilter;
end

local function autoQuestDisabled()
    local m = autoQuestModule();
    return not (m and m.enabled);
end

local function clearTable(t)
    if (wipe) then
        wipe(t);
        return;
    end
    for k in pairs(t) do
        t[k] = nil;
    end
end

local useRowDividers = true;

local function makeDivider(order, hidden)
    if (not useRowDividers) then
        return nil;
    end
    return {
        order = order,
        type = "description",
        name = "",
        width = "full",
        control = "LanternDivider",
        hidden = hidden,
    };
end

function Lantern:BuildAutoQuestOptions()
    local args = {};

    local function notifyOptionsChange()
        Lantern:NotifyOptionsChange();
    end

    local function getRecentEntry(index)
        local list = autoQuestRecentList();
        return list[index];
    end

    local function isQuestBlockedById(id)
        if (not id) then return false; end
        local list = autoQuestBlockedQuestList();
        return list[tostring(id)] ~= nil or list[tonumber(id) or id] ~= nil;
    end

    local function recentQuestLabel(index)
        return function()
            local entry = getRecentEntry(index);
            if (not entry) then return ""; end
            local label = entry.name or "Unknown Quest";
            if (entry.questID) then
                label = string.format("%s (ID: %s)", label, tostring(entry.questID));
            end
            return label;
        end
    end

    local function recentNpcLabel(index)
        return function()
            local entry = getRecentEntry(index);
            if (not entry or not entry.npcKey) then return ""; end
            return entry.npcKey;
        end
    end

    local function recentHidden(index)
        return function()
            return not getRecentEntry(index);
        end
    end

    local function hasRecent()
        return getRecentEntry(1) ~= nil;
    end

    local function buildZoneOptions()
        local opts = {
            all = "All zones",
            current = "Current zone",
        };
        local list = autoQuestBlockedList();
        for key in pairs(list) do
            local zone = key:match("^.+%s%-%s(.+)$");
            if (zone and zone ~= "") then
                opts[zone] = zone;
            end
        end
        return opts;
    end

    local function buildZoneSorting()
        local list = autoQuestBlockedList();
        local zones = {};
        local seen = {};
        for key in pairs(list) do
            local zone = key:match("^.+%s%-%s(.+)$");
            if (zone and zone ~= "" and not seen[zone]) then
                seen[zone] = true;
                table.insert(zones, zone);
            end
        end
        table.sort(zones);
        local order = { "all", "current" };
        for _, zone in ipairs(zones) do
            table.insert(order, zone);
        end
        return order;
    end

    local function rebuildArgs()
        clearTable(args);

        args.desc = {
            order = 0,
            type = "description",
            name = "Automatically accepts and turns in quests; hold Shift to pause.",
            fontSize = "medium",
        };
        args.enabled = {
            order = 1,
            type = "toggle",
            name = "Enable",
            desc = "Enable or disable Auto Quest.",
            width = "full",
            get = function()
                local m = autoQuestModule();
                return m and m.enabled;
            end,
            set = function(_, val)
                if val then
                    Lantern:EnableModule("AutoQuest");
                else
                    Lantern:DisableModule("AutoQuest");
                end
            end,
        };
        args.autoAccept = {
            order = 2,
            type = "toggle",
            name = "Auto-accept quests",
            desc = "Automatically accept quests from NPCs.",
            width = "full",
            disabled = autoQuestDisabled,
            get = function()
                local db = autoQuestDB();
                return db.autoAccept;
            end,
            set = function(_, val)
                local db = autoQuestDB();
                db.autoAccept = val and true or false;
            end,
        };
        args.autoTurnIn = {
            order = 3,
            type = "toggle",
            name = "Auto turn-in quests",
            desc = "Automatically turn in completed quests to NPCs.",
            width = "full",
            disabled = autoQuestDisabled,
            get = function()
                local db = autoQuestDB();
                return db.autoTurnIn;
            end,
            set = function(_, val)
                local db = autoQuestDB();
                db.autoTurnIn = val and true or false;
            end,
        };
        args.autoSelectSingleReward = {
            order = 4,
            type = "toggle",
            name = "Auto select single reward",
            desc = "If a quest offers only one reward, auto-select it.",
            width = "full",
            disabled = autoQuestDisabled,
            get = function()
                local db = autoQuestDB();
                return db.autoSelectSingleReward;
            end,
            set = function(_, val)
                local db = autoQuestDB();
                db.autoSelectSingleReward = val and true or false;
            end,
        };
        args.skipTrivialQuests = {
            order = 5,
            type = "toggle",
            name = "Skip trivial quests",
            desc = "Don't auto-accept quests that are gray (trivial/low-level).",
            width = "full",
            disabled = autoQuestDisabled,
            get = function()
                local db = autoQuestDB();
                return db.skipTrivialQuests;
            end,
            set = function(_, val)
                local db = autoQuestDB();
                db.skipTrivialQuests = val and true or false;
            end,
        };

        args.blockedNpcHeader = {
            order = 10,
            type = "header",
            name = "Blocked NPCs",
        };
        args.blocklistInfo = {
            order = 10.1,
            type = "description",
            name = "Note: other quest automation addons (QuickQuest, Plumber, etc.) may bypass the blocklist.",
            fontSize = "small",
        };
        args.blockedNpcAdd = {
            order = 11,
            type = "execute",
            name = "Add current NPC to blocklist",
            width = "full",
            func = function()
                local module = autoQuestModule();
                if (not module or not module.GetCurrentNPCKey) then return; end
                local key = module:GetCurrentNPCKey();
                if (not key) then
                    Lantern:Print("No NPC found. Talk to an NPC first.");
                    return;
                end
                local list = autoQuestBlockedList();
                list[key] = true;
                rebuildArgs();
                notifyOptionsChange();
            end,
        };
        args.blockedNpcHelp = {
            order = 12,
            type = "description",
            name = "Blocked NPCs won't be auto-accepted or auto-turned in.",
            fontSize = "medium",
        };
        args.blockedNpcFilter = {
            order = 13,
            type = "select",
            name = "Zone filter",
            width = "full",
            values = buildZoneOptions,
            sorting = buildZoneSorting,
            get = function()
                return autoQuestBlockedFilter();
            end,
            set = function(_, val)
                local db = autoQuestDB();
                db.blockedNPCFilter = val;
                rebuildArgs();
                notifyOptionsChange();
            end,
        };

        local list = autoQuestBlockedList();
        local currentZone = Lantern.utils and Lantern.utils.GetCurrentZoneName
            and Lantern.utils.GetCurrentZoneName()
            or nil;
        local filter = autoQuestBlockedFilter();
        local showAll = filter == "all";
        local filterZone = currentZone or "";
        if (filter ~= "current" and filter ~= "all") then
            filterZone = filter;
        end
        local keys = {};
        for key in pairs(list) do
            local zone = key:match("^.+%s%-%s(.+)$");
            if (showAll or filterZone == "" or zone == filterZone) then
                table.insert(keys, key);
            end
        end
        table.sort(keys);
        if (#keys == 0) then
            args.blockedNpcEmpty = {
                order = 14,
                type = "description",
                name = (showAll or filterZone == "")
                    and "No NPCs are blocked."
                    or ("No NPCs are blocked in " .. filterZone .. "."),
                fontSize = "medium",
            };
        else
            local order = 20;
            for i, key in ipairs(keys) do
                args["npc_label_" .. order] = {
                    order = order,
                    type = "description",
                    name = key,
                    width = "double",
                };
                args["npc_remove_" .. order] = {
                    order = order + 0.01,
                    type = "execute",
                    name = "Remove",
                    width = "half",
                    func = function()
                        list[key] = nil;
                        rebuildArgs();
                        notifyOptionsChange();
                    end,
                };
                if (useRowDividers and i < #keys) then
                    args["npc_divider_" .. order] = makeDivider(order + 0.5);
                end
                order = order + 1;
            end
        end

        args.blockedQuestHeader = {
            order = 80,
            type = "header",
            name = "Blocked quests",
        };
        args.blockedQuestHelp = {
            order = 81,
            type = "description",
            name = "Blocked quests won't be auto-accepted or auto-turned in.",
            fontSize = "medium",
        };

        -- Build zone filter options for blocked quests
        local function buildQuestZoneOptions()
            local opts = {
                all = "All zones",
                current = "Current zone",
            };
            local blockedList = autoQuestBlockedQuestList();
            for _, entry in pairs(blockedList) do
                if (type(entry) == "table" and entry.npcKey) then
                    local zone = entry.npcKey:match("^.+%s%-%s(.+)$");
                    if (zone and zone ~= "") then
                        opts[zone] = zone;
                    end
                end
            end
            return opts;
        end

        local function buildQuestZoneSorting()
            local zones = {};
            local seen = {};
            local blockedList = autoQuestBlockedQuestList();
            for _, entry in pairs(blockedList) do
                if (type(entry) == "table" and entry.npcKey) then
                    local zone = entry.npcKey:match("^.+%s%-%s(.+)$");
                    if (zone and zone ~= "" and not seen[zone]) then
                        seen[zone] = true;
                        table.insert(zones, zone);
                    end
                end
            end
            table.sort(zones);
            local order = { "all", "current" };
            for _, zone in ipairs(zones) do
                table.insert(order, zone);
            end
            return order;
        end

        local function getQuestZoneFilter()
            local db = autoQuestDB();
            if (db.blockedQuestFilter == nil) then
                db.blockedQuestFilter = "current";
            end
            return db.blockedQuestFilter;
        end

        args.blockedQuestFilter = {
            order = 82,
            type = "select",
            name = "Zone filter",
            width = "full",
            values = buildQuestZoneOptions,
            sorting = buildQuestZoneSorting,
            get = getQuestZoneFilter,
            set = function(_, val)
                local db = autoQuestDB();
                db.blockedQuestFilter = val;
                rebuildArgs();
                notifyOptionsChange();
            end,
        };

        local blockedList = autoQuestBlockedQuestList();
        local questZoneFilter = getQuestZoneFilter();
        local currentZone = Lantern.utils and Lantern.utils.GetCurrentZoneName
            and Lantern.utils.GetCurrentZoneName()
            or nil;
        local showAllQuests = (questZoneFilter == "all");
        local questZone = currentZone or "";
        if (questZoneFilter ~= "current" and questZoneFilter ~= "all") then
            questZone = questZoneFilter;
        end
        local ids = {};
        for id in pairs(blockedList) do
            table.insert(ids, id);
        end
        table.sort(ids, function(a, b)
            local an = tonumber(a);
            local bn = tonumber(b);
            if (an and bn) then
                return an < bn;
            end
            return tostring(a) < tostring(b);
        end);
        if (#ids == 0) then
            args.blockedQuestEmpty = {
                order = 83,
                type = "description",
                name = (not showAllQuests and questZone ~= "") and ("No quests are blocked in " .. questZone .. ".") or "No quests are blocked.",
                fontSize = "medium",
            };
        else
            local entries = {};
            for _, id in ipairs(ids) do
                local raw = blockedList[id];
                local name = nil;
                local npcKey = nil;
                if (type(raw) == "table") then
                    name = raw.name;
                    npcKey = raw.npcKey;
                elseif (type(raw) == "string") then
                    name = raw;
                end
                local zone = npcKey and npcKey:match("^.+%s%-%s(.+)$") or nil;
                if (showAllQuests or (zone and zone == questZone)) then
                    table.insert(entries, {
                        id = id,
                        name = name,
                        npcKey = npcKey,
                    });
                end
            end
            if (#entries == 0) then
                args.blockedQuestEmpty = {
                    order = 82,
                    type = "description",
                    name = questZone ~= "" and ("No quests are blocked in " .. questZone .. ".") or "No quests are blocked.",
                    fontSize = "medium",
                };
            end
            local groups = {};
            for _, entry in ipairs(entries) do
                local npcName = entry.npcKey;
                if (npcName and npcName:find(" %-%s")) then
                    npcName = npcName:match("^(.-)%s%-%s.+$") or npcName;
                end
                if (not npcName or npcName == "") then
                    npcName = "Unknown NPC";
                end
                groups[npcName] = groups[npcName] or {};
                table.insert(groups[npcName], entry);
            end
            local npcNames = {};
            for npcName in pairs(groups) do
                table.insert(npcNames, npcName);
            end
            table.sort(npcNames);
            local order = 90;
            for i, npcName in ipairs(npcNames) do
                args["quest_npc_" .. order] = {
                    order = order,
                    type = "description",
                    name = npcName,
                    fontSize = "medium",
                };
                order = order + 1;
                local group = groups[npcName];
                table.sort(group, function(a, b)
                    local aName = a.name or "";
                    local bName = b.name or "";
                    if (aName ~= bName) then
                        if (aName == "") then return false; end
                        if (bName == "") then return true; end
                        return aName < bName;
                    end
                    return tostring(a.id) < tostring(b.id);
                end);
                for _, entry in ipairs(group) do
                    local label = entry.name;
                    if (type(label) == "string" and label ~= "") then
                        label = string.format("    %s (ID: %s)", label, tostring(entry.id));
                    else
                        label = string.format("    Quest ID: %s", tostring(entry.id));
                    end
                    args["quest_row_" .. order] = {
                        order = order,
                        type = "execute",
                        name = label,
                        width = "full",
                        control = "LanternInlineRemoveButtonRow",
                        func = function()
                            blockedList[entry.id] = nil;
                            if (entry.name) then
                                local names = autoQuestBlockedQuestNames();
                                names[entry.name] = nil;
                            end
                            rebuildArgs();
                            notifyOptionsChange();
                        end,
                    };
                    order = order + 1;
                end
                if (useRowDividers and i < #npcNames) then
                    args["quest_divider_" .. order] = makeDivider(order + 0.5);
                    order = order + 1;
                end
            end
        end

        args.recentHeader = {
            order = 30,
            type = "header",
            name = "Recent automated quests",
        };
        args.recentDesc = {
            order = 31,
            type = "description",
            name = "Your 5 most recent automated quests.",
            fontSize = "medium",
        };
        args.recentEmpty = {
            order = 32,
            type = "description",
            name = "No automated quests yet.",
            fontSize = "medium",
            hidden = function() return hasRecent(); end,
        };

        local function addRecentBlock(entry)
            if (entry and entry.questID) then
                local list = autoQuestBlockedQuestList();
                local names = autoQuestBlockedQuestNames();
                list[tostring(entry.questID)] = {
                    name = entry.name or true,
                    npcKey = entry.npcKey,
                };
                if (entry.name) then
                    names[entry.name] = true;
                end
                rebuildArgs();
                notifyOptionsChange();
            end
        end

        local function addRecentEntry(index, baseOrder)
            local entry = getRecentEntry(index);
            local added = entry and entry.questID and isQuestBlockedById(entry.questID);
            args["recent_entry_" .. index] = {
                order = baseOrder,
                type = "execute",
                name = recentQuestLabel(index),
                width = "full",
                control = added and "LanternInlineButtonRowAdded" or "LanternInlineButtonRow",
                hidden = recentHidden(index),
                disabled = function()
                    return not (entry and entry.questID) or added;
                end,
                func = function()
                    addRecentBlock(getRecentEntry(index));
                end,
            };
            args["recent_npc_" .. index] = {
                order = baseOrder + 0.01,
                type = "description",
                name = recentNpcLabel(index),
                width = "full",
                fontSize = "small",
                hidden = recentHidden(index),
            };
            if (useRowDividers and index < 5) then
                args["recent_divider_" .. index] = makeDivider(baseOrder + 0.02, function()
                    return recentHidden(index)() or recentHidden(index + 1)();
                end);
            end
        end

        local base = 40;
        for i = 1, 5 do
            addRecentEntry(i, base);
            base = base + 1;
        end
    end

    if (Lantern.utils and Lantern.utils.RegisterOptionsRebuilder) then
        Lantern.utils.RegisterOptionsRebuilder("autoQuest", rebuildArgs);
    end

    rebuildArgs();
    return args;
end
