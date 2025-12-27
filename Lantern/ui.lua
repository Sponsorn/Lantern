local ADDON_NAME, Lantern = ...;

local LDB = LibStub and LibStub("LibDataBroker-1.1", true);
local LDBIcon = LibStub and LibStub("LibDBIcon-1.0", true);
local AceConfig = LibStub and LibStub("AceConfig-3.0", true);
local AceConfigDialog = LibStub and LibStub("AceConfigDialog-3.0", true);
local AceConfigRegistry = LibStub and LibStub("AceConfigRegistry-3.0", true);

local MINIMAP_OBJECT_NAME = "Lantern";
local DEFAULT_ICON = "Interface\\AddOns\\Lantern\\Media\\Images\\Icons\\lantern-core-icon64.blp";
local CURSEFORGE_CRAFTING_ORDERS = "https://www.curseforge.com/wow/addons/lantern-craftingorders";
local LINK_POPUP_NAME = "LanternCopyLinkDialog";

local function hasMinimapLibs()
    return LDB and LDBIcon;
end

local function hasOptionsLibs()
    return AceConfig and AceConfigDialog;
end

local function ensureLinkPopup()
    if (StaticPopupDialogs[LINK_POPUP_NAME]) then return; end
    StaticPopupDialogs[LINK_POPUP_NAME] = {
        text = "CTRL-C to copy link",
        button1 = CLOSE,
        OnShow = function(dialog, data)
            local function hidePopup()
                dialog:Hide();
            end
            local editBox = dialog.GetEditBox and dialog:GetEditBox() or dialog.editBox;
            editBox:SetScript("OnEscapePressed", hidePopup);
            editBox:SetScript("OnEnterPressed", hidePopup);
            editBox:SetScript("OnKeyUp", function(_, key)
                if (IsControlKeyDown() and (key == "C" or key == "X")) then
                    hidePopup();
                end
            end);
            editBox:SetMaxLetters(0);
            editBox:SetText(data or "");
            editBox:HighlightText();
        end,
        hasEditBox = true,
        editBoxWidth = 260,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    };
end

local function showLinkPopup(link)
    ensureLinkPopup();
    StaticPopup_Show(LINK_POPUP_NAME, nil, nil, link);
end

function Lantern:EnsureUIState()
    self.db.minimap = self.db.minimap or {};
    self.db.options = self.db.options or {};
end

function Lantern:ToggleMinimapIcon(show)
    if (not hasMinimapLibs()) then return; end
    if (show == nil) then
        show = self.db.minimap.hide;
        show = not show;
    end
    self.db.minimap.hide = not show;
    if (show) then
        LDBIcon:Show(MINIMAP_OBJECT_NAME);
    else
        LDBIcon:Hide(MINIMAP_OBJECT_NAME);
    end
end

function Lantern:InitMinimap()
    if (self.minimapInitialized or not hasMinimapLibs()) then return; end

    self.ldbObject = self.ldbObject or LDB:NewDataObject(MINIMAP_OBJECT_NAME, {
        type = "launcher",
        icon = DEFAULT_ICON,
        label = ADDON_NAME,
        OnClick = function(_, button)
            if (button == "LeftButton") then
                if (IsShiftKeyDown()) then
                    ReloadUI();
                else
                    Lantern:OpenOptions();
                end
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("Lantern");
            tooltip:AddLine("Left-click: Open options", 1, 1, 1);
            tooltip:AddLine("Shift+Left-click: Reload UI", 1, 1, 1);
        end,
    });

    LDBIcon:Register(MINIMAP_OBJECT_NAME, self.ldbObject, self.db.minimap);
    self.minimapInitialized = true;
end

local function makeModuleOptionKey(name)
    return "module_" .. tostring(name or "");
end

local function moduleToggle(name)
    return function(_, val)
        if (val) then
            Lantern:EnableModule(name);
        else
            Lantern:DisableModule(name);
        end
    end
end

local function moduleToggleGetter(name)
    return function()
        local module = Lantern.modules[name];
        return module and module.enabled;
    end
end

function Lantern:RegisterModuleOptions(module)
    if (not module or not module.name or not self.options) then return; end
    if (module.opts and module.opts.skipOptions) then return; end
    local key = makeModuleOptionKey(module.name);
    if (self._registeredOptionKeys and self._registeredOptionKeys[key]) then return; end
    self._registeredOptionKeys = self._registeredOptionKeys or {};

    local label = (module.opts and module.opts.title) or module.name;
    local desc = module.opts and module.opts.desc;

    local childGroups = (module.opts and module.opts.childGroups) or "tree";
    local group = {
        type = "group",
        name = label,
        childGroups = childGroups,
        args = {
            enabled = nil,
        },
    };
    local enableLabel = (module.opts and module.opts.enableLabel) or "Enable";
    group.args.enabled = {
        order = 0,
        type = "toggle",
        name = enableLabel,
        desc = desc,
        width = "full",
        get = moduleToggleGetter(module.name),
        set = moduleToggle(module.name),
    };
    -- Allow modules to contribute additional options.
    local extraArgs;
    if (module.GetOptions) then
        extraArgs = module:GetOptions();
    elseif (module.opts and module.opts.options) then
        extraArgs = module.opts.options;
    end
    if (type(extraArgs) == "table") then
            for k, v in pairs(extraArgs) do
                group.args[k] = v;
            end
        end

        if (AceConfig and AceConfigDialog) then
            AceConfig:RegisterOptionsTable(key, group);
            AceConfigDialog:AddToBlizOptions(key, label, ADDON_NAME);
            self._registeredOptionKeys[key] = true;
        end
    end

function Lantern:RegisterAllModuleOptions()
    if (not self.options) then return; end
    for name, module in pairs(self.modules or {}) do
        self:RegisterModuleOptions(module);
    end
end

-- Hook module registration so options stay in sync.
if (not Lantern._originalRegisterModuleForUI) then
    Lantern._originalRegisterModuleForUI = Lantern.RegisterModule;
    function Lantern:RegisterModule(module)
        Lantern._originalRegisterModuleForUI(self, module);
        if (self.optionsInitialized) then
            self:RegisterModuleOptions(module);
        end
    end
end

function Lantern:BuildOptions()
    if (self.options) then return self.options; end
    local function notifyOptionsChange()
        if (AceConfigRegistry) then
            AceConfigRegistry:NotifyChange(ADDON_NAME .. "_General");
        end
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
    local function autoQuestModule()
        return Lantern.modules and Lantern.modules.AutoQuest;
    end
    local function autoQuestDB()
        Lantern.db.autoQuest = Lantern.db.autoQuest or {};
        local defaults = { autoAccept = true, autoTurnIn = true, autoSelectSingleReward = true };
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
    local useRowDividers = true;
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
    local function deleteConfirmModule()
        return Lantern.modules and Lantern.modules.DeleteConfirm;
    end
    local function deleteConfirmDB()
        Lantern.db.deleteConfirm = Lantern.db.deleteConfirm or {};
        return Lantern.db.deleteConfirm;
    end
    local function deleteConfirmDisabled()
        local m = deleteConfirmModule();
        return not (m and m.enabled);
    end

    self.options = {
        type = "group",
        name = "General Options",
        args = {
            general = {
                type = "group",
                name = "General",
                inline = true,
                args = {
                    minimap = {
                        type = "toggle",
                        name = "Show minimap icon",
                        get = function() return not (Lantern.db.minimap and Lantern.db.minimap.hide); end,
                        set = function(_, val) Lantern:ToggleMinimapIcon(val); end,
                        width = "full",
                    },
                },
            },
            autoQuest = {
                type = "group",
                name = "Auto Quest",
                args = (function()
                    local args = {};
                    local function getRecentEntry(index)
                        local list = autoQuestRecentList();
                        return list[index];
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

                        args.blockedNpcHeader = {
                            order = 10,
                            type = "header",
                            name = "Blocked NPCs",
                        };
                        args.blockedNpcAdd = {
                            order = 11,
                            type = "execute",
                            name = "Add current NPC to block list",
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
                        local currentZone = (GetZoneText and GetZoneText()) or "";
                        local filter = autoQuestBlockedFilter();
                        local showAll = filter == "all";
                        local filterZone = currentZone;
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

                        local blockedList = autoQuestBlockedQuestList();
                        local questZone = (GetZoneText and GetZoneText()) or "";
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
                                order = 82,
                                type = "description",
                                name = questZone ~= "" and ("No quests are blocked in " .. questZone .. ".") or "No quests are blocked.",
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
                                if (zone and zone == questZone) then
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
                                return;
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
                            args["recent_entry_" .. index] = {
                                order = baseOrder,
                                type = "execute",
                                name = recentQuestLabel(index),
                                width = "full",
                                control = "LanternInlineButtonRow",
                                hidden = recentHidden(index),
                                disabled = function()
                                    local entry = getRecentEntry(index);
                                    return not (entry and entry.questID);
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

                    rebuildArgs();
                    return args;
                end)(),
            },
            autoQueue = {
                type = "group",
                name = "Auto Queue",
                args = {
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
                },
            },
            deleteConfirm = {
                type = "group",
                name = "Delete Confirm",
                args = {
                    desc = {
                        order = 0,
                        type = "description",
                        name = "Hides the delete input box and enables the confirm button on delete popups.",
                        fontSize = "medium",
                    },
                    enabled = {
                        order = 1,
                        type = "toggle",
                        name = "Enable",
                        desc = "Replace typing DELETE with a confirm button (Shift pauses).",
                        width = "full",
                        get = function()
                            local m = deleteConfirmModule();
                            return m and m.enabled;
                        end,
                        set = function(_, val)
                            if val then
                                Lantern:EnableModule("DeleteConfirm");
                            else
                                Lantern:DisableModule("DeleteConfirm");
                            end
                        end,
                    },
                },
            },
            disableAutoAddSpells = {
                type = "group",
                name = "Disable Auto Add Spells",
                args = {
                    desc = {
                        order = 0,
                        type = "description",
                        name = "Prevents spells from being auto-added to your action bars.",
                        fontSize = "medium",
                    },
                    enabled = {
                        order = 1,
                        type = "toggle",
                        name = "Enable",
                        desc = "Disable auto-adding spells to the action bar.",
                        width = "full",
                        get = function()
                            local m = Lantern.modules and Lantern.modules.DisableAutoAddSpells;
                            return m and m.enabled;
                        end,
                        set = function(_, val)
                            if val then
                                Lantern:EnableModule("DisableAutoAddSpells");
                            else
                                Lantern:DisableModule("DisableAutoAddSpells");
                            end
                        end,
                    },
                },
            },
            -- Module placeholders added at runtime via RegisterModuleOptions.
        },
    };
    return self.options;
end

local function decorateSplash(panel)
    if (not panel or panel._lanternSplashDecorated) then return; end
    panel._lanternSplashDecorated = true;
    panel.name = "Lantern";

    local function getAddonVersion()
        local meta;
        if (C_AddOns and C_AddOns.GetAddOnMetadata) then
            meta = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or C_AddOns.GetAddOnMetadata("Lantern", "Version");
        end
        if (not meta and GetAddOnMetadata) then
            meta = GetAddOnMetadata(ADDON_NAME, "Version") or GetAddOnMetadata("Lantern", "Version");
        end
        return meta or "unknown";
    end

    local icon = panel:CreateTexture(nil, "ARTWORK");
    icon:SetSize(96, 96);
    icon:SetPoint("TOPLEFT", 12, -32);
    icon:SetTexture("Interface\\AddOns\\Lantern\\Media\\Images\\Icons\\lantern-core-icon128.blp");

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
    title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, -4);


    local version = getAddonVersion();
    local versionLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
    versionLabel:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6);
    versionLabel:SetText(string.format("Version: %s", version));

    local authorLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
    authorLabel:SetPoint("TOPLEFT", versionLabel, "BOTTOMLEFT", 0, -8);
    authorLabel:SetText("Author: Dede in-game / Sponsorn on curseforge & github");

    local thanks = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
    thanks:SetPoint("TOPLEFT", authorLabel, "BOTTOMLEFT", 0, -8);
    thanks:SetText("Special Thanks to copyrighters for making me pull my thumb out.");

    local modulesTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
    modulesTitle:SetPoint("TOPLEFT", thanks, "BOTTOMLEFT", 0, -18);
    modulesTitle:SetText("Available modules");

    local modulesLine = panel:CreateTexture(nil, "ARTWORK");
    modulesLine:SetPoint("TOPLEFT", modulesTitle, "BOTTOMLEFT", 0, -6);
    modulesLine:SetSize(520, 1);
    modulesLine:SetColorTexture(0.7, 0.6, 0.3, 0.9);

    local craftingDesc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
    craftingDesc:SetPoint("TOPLEFT", modulesLine, "BOTTOMLEFT", 0, -10);
    craftingDesc:SetJustifyH("LEFT");
    craftingDesc:SetWidth(520);
    craftingDesc:SetWordWrap(true);
    craftingDesc:SetText("Crafting Orders: announces guild order activity, personal order alerts, and a Complete + Whisper button.");

    local curseForgeButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate");
    curseForgeButton:SetSize(120, 24);
    curseForgeButton:SetPoint("TOPLEFT", craftingDesc, "BOTTOMLEFT", 0, -10);
    local craftingAddonName = "Lantern_CraftingOrders";
    local hasCraftingOrders = C_AddOns and C_AddOns.IsAddOnLoaded
        and C_AddOns.IsAddOnLoaded(craftingAddonName);
    if (hasCraftingOrders) then
        curseForgeButton:SetText("Already enabled");
        curseForgeButton:SetEnabled(false);
    else
        curseForgeButton:SetText("CurseForge");
        curseForgeButton:SetScript("OnClick", function()
            showLinkPopup(CURSEFORGE_CRAFTING_ORDERS);
        end);
    end
end

function Lantern:SetupOptions()
    if (self.optionsInitialized or not hasOptionsLibs()) then return; end
    if (Lantern.utils and Lantern.utils.ui and Lantern.utils.ui.RegisterRightButtonWidget) then
        Lantern.utils.ui.RegisterRightButtonWidget();
    end
    if (Lantern.utils and Lantern.utils.ui and Lantern.utils.ui.RegisterInlineButtonRowWidgets) then
        Lantern.utils.ui.RegisterInlineButtonRowWidgets();
    end
    if (Lantern.utils and Lantern.utils.ui and Lantern.utils.ui.RegisterDividerWidget) then
        Lantern.utils.ui.RegisterDividerWidget();
    end
    local generalOptions = self:BuildOptions();
    AceConfig:RegisterOptionsTable(ADDON_NAME .. "_General", generalOptions);

    -- Root category (parent) so children can nest under "Lantern".
    local rootOptions = {
        type = "group",
        name = "Lantern",
        args = {},
    };
    AceConfig:RegisterOptionsTable(ADDON_NAME .. "_Root", rootOptions);
    local rootPanel = AceConfigDialog:AddToBlizOptions(ADDON_NAME .. "_Root", "Lantern");
    decorateSplash(rootPanel);
    self.optionsPanel = rootPanel;
    self.optionsPanelName = (rootPanel and (rootPanel.name or rootPanel.ID)) or ADDON_NAME;

    -- General options entry nested under Lantern.
    AceConfigDialog:AddToBlizOptions(ADDON_NAME .. "_General", "General Options", "Lantern");

    -- Settings API (Dragonflight+)
    -- AddToBlizOptions already surfaces categories in the modern Settings UI, so
    -- just capture the category ID if it's available instead of registering a duplicate root.
    if (Settings and Settings.OpenToCategory and rootPanel and rootPanel.GetCategoryID) then
        self.splashCategoryID = rootPanel:GetCategoryID();
    end

    self.optionsInitialized = true;
    self:RegisterAllModuleOptions();
end

function Lantern:OpenOptions()
    if (not hasOptionsLibs()) then
        Lantern:Print("Options unavailable: AceConfig/AceGUI not loaded.");
        return;
    end
    if (not self.optionsInitialized) then
        self:SetupOptions();
    end
    -- Prefer Blizzard Settings (10.0+) if available, fallback to Interface Options, then AceConfigDialog frame.
    if (Settings and Settings.OpenToCategory) then
        if (self.splashCategoryID) then
            Settings.OpenToCategory(self.splashCategoryID);
            return;
        elseif (self.optionsPanel and self.optionsPanel.GetCategoryID) then
            local catId = self.optionsPanel:GetCategoryID();
            if (catId) then
                Settings.OpenToCategory(catId);
                return;
            end
        end
        Settings.OpenToCategory(self.optionsPanelName or ADDON_NAME);
        return;
    elseif (InterfaceOptionsFrame_OpenToCategory) then
        local panel = "LanternSplashPanel";
        if (self.optionsPanel) then
            panel = self.optionsPanel;
        end
        InterfaceOptionsFrame_OpenToCategory(panel);
        InterfaceOptionsFrame_OpenToCategory(panel); -- call twice to work around scroll offset
        return;
    end
    AceConfigDialog:Open(ADDON_NAME);
end

Lantern:RegisterEvent("PLAYER_LOGIN", function()
    if (not Lantern.db) then
        Lantern:SetupDB();
    end
    Lantern:EnsureUIState();
    Lantern:SetupOptions();
    Lantern:InitMinimap();
end);
