local ADDON_NAME = "Lantern_Warband";
local Lantern = _G.Lantern;
if (not Lantern or not Lantern.modules or not Lantern.modules.Warband) then return; end

local Warband = Lantern.modules.Warband;
local Layout = Lantern.optionsLayout;

-- Import shared utilities from Options.lua (must load after Options.lua)
local function getUtils()
    return Warband._optionsUtils;
end

-- Build groups tab options
function Warband:BuildGroupsOptions(groupsArgs, refreshOptions)
    local utils = getUtils();
    local formatGoldThousands = utils.formatGoldThousands;
    local parseGold = utils.parseGold;

    -- Add "Create New Group" section directly in Groups tab
    groupsArgs.newGroupHeader = {
        order = 1,
        type = "header",
        name = "Create New Group",
    };

    -- Helper function to trigger group creation
    local function triggerCreateGroup()
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

        local allowDeposit = self._newGroupTemp.allowDeposit;
        local allowWithdraw = self._newGroupTemp.allowWithdraw;

        self:CreateGroup(groupName, threshold, allowDeposit, allowWithdraw);
        Lantern:Print("Created group '" .. groupName .. "' with threshold of " .. formatGoldThousands(threshold) .. " gold.");

        -- Clear the inputs
        self._newGroupTemp.name = "";
        self._newGroupTemp.threshold = "100000";
        self._newGroupTemp.allowDeposit = true;
        self._newGroupTemp.allowWithdraw = true;

        -- Refresh options UI
        refreshOptions(self);
    end

    groupsArgs.newGroupName = {
        order = 2,
        type = "input",
        name = "Group name",
        desc = "Enter a name for the new group (e.g., 'Mains', 'Alts', 'Bankers')",
        width = "full",
        get = function() return self._newGroupTemp.name or ""; end,
        set = function(_, val)
            self._newGroupTemp.name = val or "";
            -- Trigger creation if user presses Enter after typing
            if val and val:find("\n") then
                self._newGroupTemp.name = val:gsub("\n", "");
                triggerCreateGroup();
            end
        end,
    };

    groupsArgs.newGroupThreshold = {
        order = 3,
        type = "input",
        name = "Gold threshold",
        desc = "Amount of gold to keep on character. The addon will automatically balance to this amount. Set to 0 to deposit all gold (deposit-only mode).",
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

    groupsArgs.newGroupBreak = {
        order = 3.1,
        type = "description",
        name = "",
        width = "full",
    };

    groupsArgs.newGroupAllowDeposit = {
        order = 3.2,
        type = "toggle",
        name = "Allow deposits",
        desc = "Allow depositing gold to warbank when over threshold",
        width = "normal",
        get = function()
            if (self._newGroupTemp.allowDeposit == nil) then
                return true;
            end
            return self._newGroupTemp.allowDeposit;
        end,
        set = function(_, val)
            self._newGroupTemp.allowDeposit = val and true or false;
        end,
    };

    groupsArgs.newGroupAllowWithdraw = {
        order = 3.3,
        type = "toggle",
        name = "Allow withdrawals",
        desc = "Allow withdrawing gold from warbank when below threshold",
        width = "normal",
        get = function()
            if (self._newGroupTemp.allowWithdraw == nil) then
                return true;
            end
            return self._newGroupTemp.allowWithdraw;
        end,
        set = function(_, val)
            self._newGroupTemp.allowWithdraw = val and true or false;
        end,
    };

    groupsArgs.createGroup = {
        order = 5,
        type = "execute",
        name = "Create Group",
        desc = "Create a new character group",
        func = function(info)
            triggerCreateGroup();
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
                allowDeposit = {
                    order = 3.3,
                    type = "toggle",
                    name = "Allow deposits",
                    desc = "Allow depositing gold to warbank when over threshold",
                    width = "normal",
                    get = function()
                        local freshGroup = self.db.groups[group.name];
                        -- Default to true for existing groups
                        if (freshGroup and freshGroup.allowDeposit ~= nil) then
                            return freshGroup.allowDeposit;
                        end
                        return true;
                    end,
                    set = function(_, val)
                        local freshGroup = self.db.groups[group.name];
                        if (freshGroup) then
                            freshGroup.allowDeposit = val and true or false;
                        end
                    end,
                },
                allowWithdraw = {
                    order = 3.4,
                    type = "toggle",
                    name = "Allow withdrawals",
                    desc = "Allow withdrawing gold from warbank when below threshold",
                    width = "normal",
                    get = function()
                        local freshGroup = self.db.groups[group.name];
                        -- Default to true for existing groups
                        if (freshGroup and freshGroup.allowWithdraw ~= nil) then
                            return freshGroup.allowWithdraw;
                        end
                        return true;
                    end,
                    set = function(_, val)
                        local freshGroup = self.db.groups[group.name];
                        if (freshGroup) then
                            freshGroup.allowWithdraw = val and true or false;
                        end
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

        -- Add editable fields using Layout helpers
        Layout.merge(groupsArgs[groupKey].args, Layout.editableField(2, "groupName", {
            label = "Group name",
            getValue = function() return group.name; end,
            buttonDesc = "Change the name of this group",
            onEdit = function()
                Layout.staticPopupInput("LANTERN_WARBAND_RENAME_GROUP", {
                    text = "Enter a new name for '" .. group.name .. "':",
                    initialValue = group.name,
                    onAccept = function(newName)
                        if (not newName or newName == "") then
                            Lantern:Print("Please enter a new name.");
                            return false;
                        end
                        if (newName == group.name) then
                            return;
                        end
                        if (self.db.groups[newName]) then
                            Lantern:Print("Group '" .. newName .. "' already exists.");
                            return false;
                        end

                        local oldName = group.name;
                        self:RenameGroup(oldName, newName);
                        Lantern:Print("Renamed group '" .. oldName .. "' to '" .. newName .. "'.");

                        -- Refresh options UI
                        refreshOptions(self);
                    end,
                });
                StaticPopup_Show("LANTERN_WARBAND_RENAME_GROUP");
            end,
        }));

        Layout.merge(groupsArgs[groupKey].args, Layout.editableField(3, "threshold", {
            label = "Gold threshold",
            getValue = function()
                local freshGroup = self.db.groups[group.name];
                return formatGoldThousands(freshGroup and freshGroup.goldThreshold or 0) .. " gold";
            end,
            buttonDesc = "Change the gold threshold for this group. Set to 0 to deposit all gold (deposit-only mode).",
            onEdit = function()
                local freshGroup = self.db.groups[group.name];
                local currentThreshold = formatGoldThousands(freshGroup and freshGroup.goldThreshold or 0);

                Layout.staticPopupInput("LANTERN_WARBAND_CHANGE_THRESHOLD", {
                    text = "Enter a new gold threshold for '" .. group.name .. "':",
                    initialValue = currentThreshold,
                    onAccept = function(val)
                        local amount = parseGold(val);
                        if (not amount) then
                            Lantern:Print("Please enter a valid gold amount.");
                            return false;
                        end
                        if (amount < 0) then
                            Lantern:Print("Gold amount must be 0 or greater.");
                            return false;
                        end

                        self:SetGroupGoldThreshold(group.name, amount);
                        Lantern:Print("Updated threshold for '" .. group.name .. "' to " .. formatGoldThousands(amount) .. " gold.");

                        -- Refresh options UI
                        refreshOptions(self);
                    end,
                });
                StaticPopup_Show("LANTERN_WARBAND_CHANGE_THRESHOLD");
            end,
        }));

        -- Add character members to this group's options
        if (group.members and #group.members > 0) then
            local formatTimeAgo = utils.formatTimeAgo;

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
end

-- Build characters tab options
function Warband:BuildCharactersOptions(charactersArgs, refreshOptions)
    local utils = getUtils();
    local formatGoldThousands = utils.formatGoldThousands;

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
                -- Split character key into name and realm
                local name, realm = charKey:match("^(.+)-(.+)$");
                local displayName = name and realm and (name .. " - " .. realm) or charKey;

                if (group) then
                    return string.format("|cff00ff00%s|r → %s (%s gold threshold)",
                        displayName,
                        groupName,
                        formatGoldThousands(group.goldThreshold or 0));
                else
                    return string.format("|cffff0000%s|r → %s (group not found)", displayName, groupName);
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
end
