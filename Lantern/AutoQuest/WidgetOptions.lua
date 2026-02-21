local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local LanternUX = _G.LanternUX;
local T = LanternUX and LanternUX.Theme;
if (not T) then return; end

local module = Lantern.modules["AutoQuest"];
if (not module) then return; end

local function moduleEnabled(name)
    local m = Lantern.modules and Lantern.modules[name];
    return m and m.enabled;
end

local function moduleToggle(name, label, desc)
    return {
        type = "toggle",
        label = label or "Enable",
        desc = desc,
        get = function() return moduleEnabled(name); end,
        set = function(val)
            if (val) then
                Lantern:EnableModule(name);
            else
                Lantern:DisableModule(name);
            end
        end,
    };
end

module.widgetOptions = function()
    local function db()
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
        if (type(Lantern.db.autoQuest.blockedQuestNames) ~= "table") then
            Lantern.db.autoQuest.blockedQuestNames = {};
        end
        if (type(Lantern.db.autoQuest.recentAutomated) ~= "table") then
            Lantern.db.autoQuest.recentAutomated = {};
        end
        return Lantern.db.autoQuest;
    end

    local isDisabled = function()
        return not moduleEnabled("AutoQuest");
    end

    local function getModule()
        return Lantern.modules and Lantern.modules.AutoQuest;
    end

    local function refreshPage()
        local panel = Lantern._uxPanel;
        if (panel and panel.RefreshCurrentPage) then
            panel:RefreshCurrentPage();
        end
    end

    local function getCurrentZone()
        return Lantern.utils and Lantern.utils.GetCurrentZoneName
            and Lantern.utils.GetCurrentZoneName() or nil;
    end

    local function extractZone(key)
        return key and key:match("^.+%s%-%s(.+)$") or nil;
    end

    local function buildZoneValues(sourceTable, isQuestMode)
        local opts = { all = "All zones", current = "Current zone" };
        if (isQuestMode) then
            for _, entry in pairs(sourceTable) do
                if (type(entry) == "table" and entry.npcKey) then
                    local zone = extractZone(entry.npcKey);
                    if (zone and zone ~= "") then opts[zone] = zone; end
                end
            end
        else
            for key in pairs(sourceTable) do
                local zone = extractZone(key);
                if (zone and zone ~= "") then opts[zone] = zone; end
            end
        end
        return opts;
    end

    local function buildZoneSorting(sourceTable, isQuestMode)
        local zones, seen = {}, {};
        if (isQuestMode) then
            for _, entry in pairs(sourceTable) do
                if (type(entry) == "table" and entry.npcKey) then
                    local zone = extractZone(entry.npcKey);
                    if (zone and zone ~= "" and not seen[zone]) then
                        seen[zone] = true;
                        table.insert(zones, zone);
                    end
                end
            end
        else
            for key in pairs(sourceTable) do
                local zone = extractZone(key);
                if (zone and zone ~= "" and not seen[zone]) then
                    seen[zone] = true;
                    table.insert(zones, zone);
                end
            end
        end
        table.sort(zones);
        local order = { "all", "current" };
        for _, zone in ipairs(zones) do table.insert(order, zone); end
        return order;
    end

    local function resolveFilterZone(filterKey)
        if (filterKey == "all") then return nil; end
        if (filterKey == "current") then return getCurrentZone() or ""; end
        return filterKey;
    end

    local function isQuestBlockedById(id)
        if (not id) then return false; end
        local d = db();
        return d.blockedQuests[tostring(id)] ~= nil or d.blockedQuests[tonumber(id) or id] ~= nil;
    end

    local widgets = {};

    ---------------------------------------------------------------------------
    -- Toggles
    ---------------------------------------------------------------------------
    table.insert(widgets, moduleToggle("AutoQuest", "Enable", "Enable or disable Auto Quest."));
    table.insert(widgets, {
        type = "toggle",
        label = "Auto-accept quests",
        desc = "Automatically accept quests from NPCs.",
        disabled = isDisabled,
        get = function() return db().autoAccept; end,
        set = function(val) db().autoAccept = val and true or false; end,
    });
    table.insert(widgets, {
        type = "toggle",
        label = "Auto turn-in quests",
        desc = "Automatically turn in completed quests to NPCs.",
        disabled = isDisabled,
        get = function() return db().autoTurnIn; end,
        set = function(val) db().autoTurnIn = val and true or false; end,
    });
    table.insert(widgets, {
        type = "toggle",
        label = "Auto select single reward",
        desc = "If a quest offers only one reward, auto-select it.",
        disabled = isDisabled,
        get = function() return db().autoSelectSingleReward; end,
        set = function(val) db().autoSelectSingleReward = val and true or false; end,
    });
    table.insert(widgets, {
        type = "toggle",
        label = "Skip trivial quests",
        desc = "Don't auto-accept quests that are gray (trivial/low-level).",
        disabled = isDisabled,
        get = function() return db().skipTrivialQuests; end,
        set = function(val) db().skipTrivialQuests = val and true or false; end,
    });
    table.insert(widgets, {
        type = "description",
        text = "Hold " .. Lantern:GetModifierName() .. " to temporarily pause auto-accept and auto turn-in.",
        fontSize = "small",
        color = T.textDim,
    });

    ---------------------------------------------------------------------------
    -- Divider between toggles and lists
    ---------------------------------------------------------------------------
    table.insert(widgets, { type = "divider" });

    ---------------------------------------------------------------------------
    -- Blocked NPCs
    ---------------------------------------------------------------------------
    local d = db();
    table.insert(widgets, {
        type = "description",
        text = "Note: other quest automation addons (QuickQuest, Plumber, etc.) may bypass the blocklist.",
        fontSize = "small",
        color = T.textDim,
    });
    table.insert(widgets, {
        type = "execute",
        label = "Add current NPC to blocklist",
        desc = "Talk to an NPC, then click this button to block them from auto-quest automation.",
        disabled = isDisabled,
        func = function()
            local m = getModule();
            if (not m or not m.GetCurrentNPCKey) then return; end
            local key = m:GetCurrentNPCKey();
            if (not key) then
                Lantern:Print("No NPC found. Talk to an NPC first.");
                return;
            end
            db().blockedNPCs[key] = true;
            Lantern:Print("Blocked NPC: " .. key);
            refreshPage();
        end,
    });
    table.insert(widgets, {
        type = "select",
        label = "Zone filter",
        desc = "Filter blocked NPCs by zone.",
        disabled = isDisabled,
        values = function() return buildZoneValues(db().blockedNPCs, false); end,
        sorting = function() return buildZoneSorting(db().blockedNPCs, false); end,
        get = function()
            local f = db().blockedNPCFilter;
            return (f == nil) and "current" or f;
        end,
        set = function(val)
            db().blockedNPCFilter = val;
            refreshPage();
        end,
    });

    -- Build filtered NPC list
    local npcFilter = db().blockedNPCFilter;
    if (npcFilter == nil) then npcFilter = "current"; end
    local showAllNPCs = (npcFilter == "all");
    local npcFilterZone = resolveFilterZone(npcFilter);
    local npcKeys = {};
    for key in pairs(d.blockedNPCs) do
        if (showAllNPCs) then
            table.insert(npcKeys, key);
        else
            local zone = extractZone(key);
            if (npcFilterZone == "" or zone == npcFilterZone) then
                table.insert(npcKeys, key);
            end
        end
    end
    table.sort(npcKeys);

    -- Blocked NPCs group with count
    local npcGroupChildren = {};
    if (#npcKeys == 0) then
        local emptyMsg = (showAllNPCs or npcFilterZone == "")
            and "No NPCs blocked yet -- target an NPC and click the button above to add one."
            or ("No NPCs blocked in " .. (npcFilterZone or "") .. ".");
        table.insert(npcGroupChildren, {
            type = "description",
            text = emptyMsg,
            fontSize = "small",
            color = T.textDim,
        });
    else
        for _, key in ipairs(npcKeys) do
            table.insert(npcGroupChildren, {
                type = "label_action",
                text = key,
                buttonLabel = "Remove",
                desc = "Remove " .. key .. " from the blocklist.",
                confirm = "Remove?",
                disabled = isDisabled,
                func = function()
                    db().blockedNPCs[key] = nil;
                    refreshPage();
                end,
            });
        end
    end
    table.insert(widgets, {
        type = "group",
        text = "Blocked NPCs (" .. #npcKeys .. ")",
        expanded = true,
        stateKey = "blockedNPCs",
        children = npcGroupChildren,
    });

    ---------------------------------------------------------------------------
    -- Blocked Quests
    ---------------------------------------------------------------------------
    table.insert(widgets, { type = "header", text = "Blocked Quests" });
    table.insert(widgets, {
        type = "description",
        text = "Blocked quests won't be auto-accepted or auto-turned in.",
        fontSize = "small",
        color = T.textDim,
    });
    table.insert(widgets, {
        type = "select",
        label = "Zone filter",
        desc = "Filter blocked quests by zone.",
        disabled = isDisabled,
        values = function() return buildZoneValues(db().blockedQuests, true); end,
        sorting = function() return buildZoneSorting(db().blockedQuests, true); end,
        get = function()
            local f = db().blockedQuestFilter;
            return (f == nil) and "current" or f;
        end,
        set = function(val)
            db().blockedQuestFilter = val;
            refreshPage();
        end,
    });

    -- Build filtered quest list grouped by NPC
    local questFilter = db().blockedQuestFilter;
    if (questFilter == nil) then questFilter = "current"; end
    local showAllQuests = (questFilter == "all");
    local questFilterZone = resolveFilterZone(questFilter);

    local filteredEntries = {};
    for id, raw in pairs(d.blockedQuests) do
        local name, npcKey;
        if (type(raw) == "table") then
            name = raw.name;
            npcKey = raw.npcKey;
        elseif (type(raw) == "string") then
            name = raw;
        end
        local zone = npcKey and extractZone(npcKey) or nil;
        if (showAllQuests or (zone and zone == questFilterZone) or (not zone and (questFilterZone == "" or showAllQuests))) then
            table.insert(filteredEntries, { id = id, name = name, npcKey = npcKey });
        end
    end

    if (#filteredEntries == 0) then
        local emptyMsg = (showAllQuests or questFilterZone == "")
            and "No quests blocked yet -- quests auto-accepted from blocked NPCs will appear here."
            or ("No quests blocked in " .. (questFilterZone or "") .. ".");
        table.insert(widgets, {
            type = "description",
            text = emptyMsg,
            fontSize = "small",
            color = T.textDim,
        });
    else
        -- Group by NPC name
        local questGroups = {};
        for _, entry in ipairs(filteredEntries) do
            local npcName = entry.npcKey;
            if (npcName and npcName:find(" %-%s")) then
                npcName = npcName:match("^(.-)%s%-%s.+$") or npcName;
            end
            if (not npcName or npcName == "") then
                npcName = "Unknown NPC";
            end
            questGroups[npcName] = questGroups[npcName] or {};
            table.insert(questGroups[npcName], entry);
        end

        local npcNames = {};
        for npcName in pairs(questGroups) do table.insert(npcNames, npcName); end
        table.sort(npcNames);

        for _, npcName in ipairs(npcNames) do
            local group = questGroups[npcName];
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

            local questChildren = {};
            for _, entry in ipairs(group) do
                local label;
                if (type(entry.name) == "string" and entry.name ~= "") then
                    label = string.format("%s (ID: %s)", entry.name, tostring(entry.id));
                else
                    label = string.format("Quest ID: %s", tostring(entry.id));
                end
                table.insert(questChildren, {
                    type = "label_action",
                    text = label,
                    buttonLabel = "Remove",
                    desc = "Unblock this quest.",
                    confirm = "Remove?",
                    disabled = isDisabled,
                    func = function()
                        local blockedQuests = db().blockedQuests;
                        blockedQuests[entry.id] = nil;
                        if (entry.name) then
                            local names = db().blockedQuestNames;
                            names[entry.name] = nil;
                        end
                        refreshPage();
                    end,
                });
            end

            table.insert(widgets, {
                type = "group",
                text = npcName .. " (" .. #group .. ")",
                expanded = true,
                stateKey = "questNpc:" .. npcName,
                children = questChildren,
            });
        end
    end

    ---------------------------------------------------------------------------
    -- Recent Automated Quests
    ---------------------------------------------------------------------------
    local recentList = d.recentAutomated or {};
    local recentChildren = {};

    if (#recentList == 0) then
        table.insert(recentChildren, {
            type = "description",
            text = "No automated quests yet.",
            fontSize = "small",
            color = T.textDim,
        });
    else
        for i = 1, math.min(#recentList, 5) do
            local entry = recentList[i];
            if (entry) then
                local label = entry.name or "Unknown Quest";
                if (entry.questID) then
                    label = string.format("%s (ID: %s)", label, tostring(entry.questID));
                end
                local alreadyBlocked = entry.questID and isQuestBlockedById(entry.questID);
                table.insert(recentChildren, {
                    type = "label_action",
                    text = label,
                    buttonLabel = alreadyBlocked and "Blocked" or "Block Quest",
                    desc = "Block this quest from future automation.",
                    disabled = function() return isDisabled() or alreadyBlocked; end,
                    func = function()
                        if (entry.questID) then
                            local blockedQuests = db().blockedQuests;
                            local blockedNames = db().blockedQuestNames;
                            blockedQuests[tostring(entry.questID)] = {
                                name = entry.name or true,
                                npcKey = entry.npcKey,
                            };
                            if (entry.name) then
                                blockedNames[entry.name] = true;
                            end
                            refreshPage();
                        end
                    end,
                });
                -- Show NPC info inline below the quest entry
                if (entry.npcKey) then
                    table.insert(recentChildren, {
                        type = "description",
                        text = "NPC: " .. entry.npcKey,
                        fontSize = "small",
                        color = T.textDim,
                    });
                end
            end
        end
    end

    local recentCount = math.min(#recentList, 5);
    table.insert(widgets, {
        type = "group",
        text = "Recent automated quests (" .. recentCount .. ")",
        expanded = true,
        stateKey = "recentQuests",
        children = recentChildren,
    });

    return widgets;
end
