local ADDON_NAME = "Lantern_Warband";
local Lantern = _G.Lantern;
if (not Lantern or not Lantern.modules or not Lantern.modules.Warband) then return; end

local Warband = Lantern.modules.Warband;

local function formatGold(copper)
    return Lantern:Convert("money:format_gold", copper) or "0";
end

local function formatGoldThousands(copper)
    return Lantern:Convert("money:format_gold_thousands", copper) or "0";
end

local function parseGold(str)
    return Lantern:Convert("money:parse_gold", str);
end

local function refreshOptions(self)
    -- Force options rebuild by re-registering the module options
    local AceConfig = LibStub and LibStub("AceConfig-3.0", true);
    local AceConfigRegistry = LibStub and LibStub("AceConfigRegistry-3.0", true);

    if (AceConfig and AceConfigRegistry and self.GetOptions) then
        local key = "module_Warband";
        local newOptions = self:GetOptions();

        -- Build the wrapped group
        local group = {
            type = "group",
            name = "Warband",
            childGroups = "tree",
            args = {
                enabled = {
                    order = 0,
                    type = "toggle",
                    name = "Enable",
                    width = "full",
                    get = function()
                        return self.enabled;
                    end,
                    set = function(_, val)
                        if (val) then
                            Lantern:EnableModule("Warband");
                        else
                            Lantern:DisableModule("Warband");
                        end
                    end,
                },
            },
        };

        -- Merge new options
        for k, v in pairs(newOptions) do
            group.args[k] = v;
        end

        AceConfig:RegisterOptionsTable(key, group);
        AceConfigRegistry:NotifyChange(key);
    end
end

function Warband:GetOptions()
    -- Ensure database is initialized before building options
    if (not self.db) then
        if (not _G.LanternWarbandDB) then
            _G.LanternWarbandDB = {};
        end
        self.db = _G.LanternWarbandDB;
    end

    -- Temporary storage for new group creation
    if (not self._newGroupTemp) then
        self._newGroupTemp = {
            name = "",
            threshold = "100000",
        };
    end

    local options = {
        general = {
            order = 1,
            type = "group",
            name = "General",
            args = {
                desc = {
                    order = 1,
                    type = "description",
                    name = "Manage character groups and automated banking. Create groups with gold thresholds, and when you open a bank, the addon will automatically balance your gold to match the threshold (deposit excess or withdraw if below).",
                    fontSize = "medium",
                },
                autoDeposit = {
                    order = 2,
                    type = "toggle",
                    name = "Auto-balance gold with warbank",
                    desc = "Automatically deposit excess gold or withdraw if below threshold when opening a bank.",
                    width = "full",
                    get = function()
                        return self.db and self.db.autoDeposit;
                    end,
                    set = function(_, val)
                        if (self.db) then
                            self.db.autoDeposit = val and true or false;
                        end
                    end,
                },
                currentChar = {
                    order = 3,
                    type = "description",
                    name = function()
                        local key = self:GetCurrentCharacter();
                        local group = self:GetCharacterGroup();
                        if (group) then
                            return string.format("|cff00ff00Current character:|r %s\n|cff00ff00Group:|r %s\n|cff00ff00Gold threshold:|r %s gold",
                                key or "Unknown",
                                group.name or "None",
                                formatGoldThousands(group.goldThreshold or 0));
                        else
                            return string.format("|cff00ff00Current character:|r %s\n|cffff0000Not assigned to any group|r", key or "Unknown");
                        end
                    end,
                    fontSize = "medium",
                },
            },
        },
        groups = {
            order = 2,
            type = "group",
            name = "Groups",
            args = {},
        },
        characters = {
            order = 3,
            type = "group",
            name = "Characters",
            args = {},
        },
    };

    -- Build groups tab
    local groupsArgs = options.groups.args;

    -- Add "Create New Group" section directly in Groups tab
    groupsArgs.newGroupHeader = {
        order = 1,
        type = "header",
        name = "Create New Group",
    };

    groupsArgs.newGroupName = {
        order = 2,
        type = "input",
        name = "Group name",
        desc = "Enter a name for the new group (e.g., 'Mains', 'Alts', 'Bankers')",
        width = "full",
        get = function() return self._newGroupTemp.name or ""; end,
        set = function(_, val)
            self._newGroupTemp.name = val or "";
        end,
    };

    groupsArgs.newGroupThreshold = {
        order = 3,
        type = "input",
        name = "Gold threshold",
        desc = "Amount of gold to keep on character. The addon will automatically balance to this amount. Set to 0 to disable auto-balance for this group.",
        width = "normal",
        get = function()
            local val = tonumber(self._newGroupTemp.threshold) or 100000;
            local copper = val * 10000;
            return formatGoldThousands(copper);
        end,
        set = function(_, val)
            local amount = parseGold(val);
            if (amount and amount >= 0) then
                local gold = math.floor(amount / 10000);
                self._newGroupTemp.threshold = tostring(gold);
            end
        end,
    };

    groupsArgs.createGroup = {
        order = 5,
        type = "execute",
        name = "Create Group",
        desc = "Create a new character group",
        func = function(info)
            local groupName = self._newGroupTemp.name;
            local thresholdStr = self._newGroupTemp.threshold;
            local threshold = parseGold(thresholdStr);

            if (not groupName or groupName == "") then
                Lantern:Print("Please enter a group name.");
                return;
            end

            if (not threshold) then
                Lantern:Print("Please enter a valid gold amount.");
                return;
            end

            if (self.db.groups[groupName]) then
                Lantern:Print("Group '" .. groupName .. "' already exists.");
                return;
            end

            self:CreateGroup(groupName, threshold);
            Lantern:Print("Created group '" .. groupName .. "' with threshold of " .. formatGoldThousands(threshold) .. " gold.");

            -- Clear the inputs
            self._newGroupTemp.name = "";
            self._newGroupTemp.threshold = "100000";

            -- Refresh options UI
            refreshOptions(self);
        end,
    };

    -- List existing groups
    local groups = self:GetAllGroups();
    table.sort(groups, function(a, b)
        return (a.name or ""):lower() < (b.name or ""):lower();
    end);

    local order = 20;
    for _, group in ipairs(groups) do
        local groupKey = "group_" .. group.name:gsub("[^%w]", "_");
        local memberCount = group.members and #group.members or 0;

        -- Temporary storage for group rename
        if (not self._renameTemp) then
            self._renameTemp = {};
        end
        if (not self._renameTemp[group.name]) then
            self._renameTemp[group.name] = group.name;
        end

        groupsArgs[groupKey] = {
            order = order,
            type = "group",
            name = string.format("%s - %d member%s", group.name, memberCount, memberCount == 1 and "" or "s"),
            args = {
                settingsHeader = {
                    order = 1,
                    type = "header",
                    name = "Group Settings",
                },
                groupNameDisplay = {
                    order = 2,
                    type = "description",
                    name = function()
                        return "|cff00ff00Group name:|r " .. group.name;
                    end,
                    fontSize = "medium",
                    width = "double",
                },
                groupNameChange = {
                    order = 2.1,
                    type = "execute",
                    name = "Change",
                    desc = "Change the name of this group",
                    width = "half",
                    func = function()
                        -- Use StaticPopup for the dialog
                        StaticPopupDialogs["LANTERN_WARBAND_RENAME_GROUP"] = {
                            text = "Enter a new name for '" .. group.name .. "':",
                            button1 = "OK",
                            button2 = "Cancel",
                            hasEditBox = true,
                            OnShow = function(popup)
                                popup.EditBox:SetText(group.name);
                                popup.EditBox:HighlightText();
                            end,
                            OnAccept = function(popup)
                                local newName = popup.EditBox:GetText();
                                if (not newName or newName == "") then
                                    Lantern:Print("Please enter a new name.");
                                    return;
                                end
                                if (newName == group.name) then
                                    return;
                                end
                                if (self.db.groups[newName]) then
                                    Lantern:Print("Group '" .. newName .. "' already exists.");
                                    return;
                                end

                                local oldName = group.name;
                                self:RenameGroup(oldName, newName);
                                Lantern:Print("Renamed group '" .. oldName .. "' to '" .. newName .. "'.");

                                -- Refresh options UI
                                refreshOptions(self);
                            end,
                            timeout = 0,
                            whileDead = true,
                            hideOnEscape = true,
                            preferredIndex = 3,
                        };
                        StaticPopup_Show("LANTERN_WARBAND_RENAME_GROUP");
                    end,
                },
                groupNameBreak = {
                    order = 2.2,
                    type = "description",
                    name = "",
                    width = "full",
                },
                thresholdDisplay = {
                    order = 3,
                    type = "description",
                    name = function()
                        local freshGroup = self.db.groups[group.name];
                        return "|cff00ff00Gold threshold:|r " .. formatGoldThousands(freshGroup and freshGroup.goldThreshold or 0) .. " gold";
                    end,
                    fontSize = "medium",
                    width = "double",
                },
                thresholdChange = {
                    order = 3.1,
                    type = "execute",
                    name = "Change",
                    desc = "Change the gold threshold for this group",
                    width = "half",
                    func = function()
                        local freshGroup = self.db.groups[group.name];
                        local currentThreshold = formatGoldThousands(freshGroup and freshGroup.goldThreshold or 0);

                        -- Use StaticPopup for the dialog
                        StaticPopupDialogs["LANTERN_WARBAND_CHANGE_THRESHOLD"] = {
                            text = "Enter a new gold threshold for '" .. group.name .. "':",
                            button1 = "OK",
                            button2 = "Cancel",
                            hasEditBox = true,
                            OnShow = function(popup)
                                popup.EditBox:SetText(currentThreshold);
                                popup.EditBox:HighlightText();
                            end,
                            OnAccept = function(popup)
                                local val = popup.EditBox:GetText();
                                local amount = parseGold(val);
                                if (not amount) then
                                    Lantern:Print("Please enter a valid gold amount.");
                                    return;
                                end
                                if (amount < 0) then
                                    Lantern:Print("Gold amount must be 0 or greater.");
                                    return;
                                end

                                self:SetGroupGoldThreshold(group.name, amount);
                                Lantern:Print("Updated threshold for '" .. group.name .. "' to " .. formatGoldThousands(amount) .. " gold.");

                                -- Refresh options UI
                                refreshOptions(self);
                            end,
                            timeout = 0,
                            whileDead = true,
                            hideOnEscape = true,
                            preferredIndex = 3,
                        };
                        StaticPopup_Show("LANTERN_WARBAND_CHANGE_THRESHOLD");
                    end,
                },
                addCharHeader = {
                    order = 20,
                    type = "header",
                    name = "Add Character",
                },
                addCurrentChar = {
                    order = 21,
                    type = "execute",
                    name = "Add Current Character",
                    desc = "Add the current character to this group",
                    func = function()
                        local currentChar = self:GetCurrentCharacter();
                        if (not currentChar) then
                            Lantern:Print("Could not get current character.");
                            return;
                        end

                        local currentGroup = self:GetCharacterGroup(currentChar);
                        if (currentGroup and currentGroup.name == group.name) then
                            Lantern:Print(currentChar .. " is already in group '" .. group.name .. "'.");
                            return;
                        end

                        self:AssignCharacterToGroup(currentChar, group.name);
                        Lantern:Print("Added " .. currentChar .. " to group '" .. group.name .. "'.");

                        -- Refresh options UI
                        refreshOptions(self);
                    end,
                },
            },
        };

        -- Add character members to this group's options
        if (group.members and #group.members > 0) then
            -- Helper function to format time ago
            local function formatTimeAgo(timestamp)
                if (not timestamp) then return "Never"; end
                local now = time();
                local diff = now - timestamp;

                if (diff < 60) then
                    return "Just now";
                elseif (diff < 3600) then
                    local mins = math.floor(diff / 60);
                    return mins .. "m ago";
                elseif (diff < 86400) then
                    local hours = math.floor(diff / 3600);
                    return hours .. "h ago";
                else
                    local days = math.floor(diff / 86400);
                    return days .. "d ago";
                end
            end

            -- Build member table header
            groupsArgs[groupKey].args.memberTableHeader = {
                order = 30,
                type = "header",
                name = "Members",
            };

            local memberOrder = 31;
            for _, memberKey in ipairs(group.members) do
                local lastLogin = Lantern:GetCharacterLastLogin(memberKey);
                local timeAgo = formatTimeAgo(lastLogin);

                -- Column 1: Character name (left, takes more space)
                groupsArgs[groupKey].args["member_name_" .. memberOrder] = {
                    order = memberOrder,
                    type = "description",
                    name = memberKey,
                    fontSize = "medium",
                    width = "normal",
                };

                -- Column 2: Last login (middle)
                groupsArgs[groupKey].args["member_login_" .. memberOrder] = {
                    order = memberOrder + 0.01,
                    type = "description",
                    name = timeAgo,
                    fontSize = "medium",
                    width = "normal",
                };

                -- Column 3: Remove button (right)
                groupsArgs[groupKey].args["member_remove_" .. memberOrder] = {
                    order = memberOrder + 0.02,
                    type = "execute",
                    name = "Remove",
                    desc = "Remove " .. memberKey .. " from this group",
                    width = "half",
                    func = function()
                        self:RemoveCharacterFromGroup(memberKey);
                        Lantern:Print("Removed " .. memberKey .. " from group '" .. group.name .. "'.");

                        -- Refresh options UI
                        refreshOptions(self);
                    end,
                };

                memberOrder = memberOrder + 1;
            end
        else
            groupsArgs[groupKey].args.noMembers = {
                order = 30,
                type = "description",
                name = "No members in this group yet.",
                fontSize = "medium",
            };
        end

        -- Add delete section at the end
        groupsArgs[groupKey].args.deleteHeader = {
            order = 100,
            type = "header",
            name = "Delete",
        };

        groupsArgs[groupKey].args.deleteGroup = {
            order = 101,
            type = "execute",
            name = "Delete Group",
            desc = "Delete this group (characters will be unassigned)",
            confirm = true,
            confirmText = "Are you sure you want to delete this group?",
            func = function()
                self:DeleteGroup(group.name);
                Lantern:Print("Deleted group '" .. group.name .. "'.");

                -- Refresh options UI
                refreshOptions(self);
            end,
        };

        order = order + 1;
    end

    -- Build characters tab
    local charactersArgs = options.characters.args;

    charactersArgs.desc = {
        order = 1,
        type = "description",
        name = "Assign characters to groups. Characters in a group will automatically balance their gold to the threshold when opening a bank (deposit excess or withdraw if below).",
        fontSize = "medium",
    };

    charactersArgs.currentCharHeader = {
        order = 2,
        type = "header",
        name = "Current Character",
    };

    local currentChar = self:GetCurrentCharacter();
    local currentGroup = self:GetCharacterGroup();

    charactersArgs.assignCurrent = {
        order = 3,
        type = "select",
        name = "Assign to group",
        desc = "Assign current character to a group",
        width = "double",
        values = function()
            local vals = { [""] = "None" };
            for name, _ in pairs(self.db.groups or {}) do
                vals[name] = name;
            end
            return vals;
        end,
        get = function()
            return currentGroup and currentGroup.name or "";
        end,
        set = function(_, val)
            if (val == "") then
                self:RemoveCharacterFromGroup(currentChar);
                Lantern:Print("Removed " .. currentChar .. " from groups.");
            else
                self:AssignCharacterToGroup(currentChar, val);
                Lantern:Print("Assigned " .. currentChar .. " to group '" .. val .. "'.");
            end

            -- Refresh options UI
            refreshOptions(self);
        end,
    };

    charactersArgs.allCharsHeader = {
        order = 10,
        type = "header",
        name = "All Characters",
    };

    -- List all assigned characters
    local hasChars = false;
    local order = 20;

    for charKey, groupName in pairs(self.db.characterGroups or {}) do
        hasChars = true;
        local group = self.db.groups[groupName];

        charactersArgs["char_" .. order] = {
            order = order,
            type = "description",
            name = function()
                if (group) then
                    return string.format("|cff00ff00%s|r → %s (%s gold threshold)",
                        charKey,
                        groupName,
                        formatGoldThousands(group.goldThreshold or 0));
                else
                    return string.format("|cffff0000%s|r → %s (group not found)", charKey, groupName);
                end
            end,
            fontSize = "medium",
        };

        order = order + 1;
    end

    if (not hasChars) then
        charactersArgs.noChars = {
            order = 11,
            type = "description",
            name = "No characters assigned to groups yet.",
            fontSize = "medium",
        };
    end

    return options;
end
