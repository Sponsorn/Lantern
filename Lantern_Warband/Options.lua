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
            allowDeposit = true,
            allowWithdraw = true,
        };
    else
        -- Ensure fields exist if upgrading from old version
        if (self._newGroupTemp.allowDeposit == nil) then
            self._newGroupTemp.allowDeposit = true;
        end
        if (self._newGroupTemp.allowWithdraw == nil) then
            self._newGroupTemp.allowWithdraw = true;
        end
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
                defaultThresholdHeader = {
                    order = 3,
                    type = "header",
                    name = "Ungrouped Characters",
                },
                useDefaultThreshold = {
                    order = 4,
                    type = "toggle",
                    name = "Use default threshold for ungrouped characters",
                    desc = "Apply a default gold threshold to characters not assigned to any group.",
                    width = "full",
                    get = function()
                        return self.db and self.db.useDefaultThreshold;
                    end,
                    set = function(_, val)
                        if (self.db) then
                            self.db.useDefaultThreshold = val and true or false;
                        end
                    end,
                },
                defaultThreshold = {
                    order = 5,
                    type = "input",
                    name = "Default gold threshold",
                    desc = "Gold threshold for characters not in any group. The addon will automatically balance to this amount.",
                    width = "normal",
                    disabled = function()
                        return not (self.db and self.db.useDefaultThreshold);
                    end,
                    get = function()
                        local val = self.db and self.db.defaultThreshold or 1000000000;
                        return formatGoldThousands(val);
                    end,
                    set = function(_, val)
                        local amount = parseGold(val);
                        if (amount and amount >= 0) then
                            self.db.defaultThreshold = amount;
                        end
                    end,
                },
                currentCharHeader = {
                    order = 6,
                    type = "header",
                    name = "Current Character",
                },
                currentChar = {
                    order = 7,
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
                            local thresholdText = "";
                            if (self.db and self.db.useDefaultThreshold) then
                                thresholdText = string.format("\n|cff00ff00Default threshold:|r %s gold", formatGoldThousands(self.db.defaultThreshold or 1000000));
                            end
                            return string.format("|cff00ff00Current character:|r %s\n|cffff0000Not assigned to any group|r%s", key or "Unknown", thresholdText);
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
        warehousing = {
            order = 4,
            type = "group",
            name = "Warehousing",
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
                                popup.EditBox:SetFocus();
                            end,
                            EditBoxOnEnterPressed = function(popup)
                                local parent = popup:GetParent();
                                StaticPopup_OnClick(parent, 1); -- Simulate clicking button1 (OK)
                            end,
                            EditBoxOnEscapePressed = function(popup)
                                local parent = popup:GetParent();
                                parent:Hide();
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
                    desc = "Change the gold threshold for this group. Set to 0 to deposit all gold (deposit-only mode).",
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
                                popup.EditBox:SetFocus();
                            end,
                            EditBoxOnEnterPressed = function(popup)
                                local parent = popup:GetParent();
                                StaticPopup_OnClick(parent, 1); -- Simulate clicking button1 (OK)
                            end,
                            EditBoxOnEscapePressed = function(popup)
                                local parent = popup:GetParent();
                                parent:Hide();
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
                thresholdBreak2 = {
                    order = 3.2,
                    type = "description",
                    name = "",
                    width = "full",
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

    -- Build warehousing tab (only on Retail with account bank)
    if (Enum and Enum.BagIndex and Enum.BagIndex.AccountBankTab_1 and self.Warehousing) then
        local whArgs = options.warehousing.args;

        whArgs.desc = {
            order = 1,
            type = "description",
            name = "Create item groups and move them between your bags and the warband bank. Open the warband bank and click the Warehousing button to execute.",
            fontSize = "medium",
        };

        -- Temporary storage for new group creation
        if (not self._warehousingTemp) then
            self._warehousingTemp = {
                newGroupName = "",
                itemInput = "",
                resolvedItemID = nil,
                resolvedItemName = nil,
            };
        end

        whArgs.createHeader = {
            order = 2,
            type = "header",
            name = "Create Group",
        };

        whArgs.newGroupName = {
            order = 3,
            type = "input",
            name = "Group name",
            desc = "Enter a name for the new warehousing group.",
            width = "double",
            get = function()
                return self._warehousingTemp.newGroupName or "";
            end,
            set = function(_, val)
                self._warehousingTemp.newGroupName = val or "";
            end,
        };

        whArgs.createGroup = {
            order = 4,
            type = "execute",
            name = "Create",
            desc = "Create a new warehousing group",
            func = function()
                local name = self._warehousingTemp.newGroupName;
                if (not name or name == "") then
                    Lantern:Print("Please enter a group name.");
                    return;
                end

                local success = self.Warehousing:CreateGroup(name);
                if (success) then
                    Lantern:Print("Created warehousing group '" .. name .. "'.");
                    self._warehousingTemp.newGroupName = "";
                    refreshOptions(self);
                else
                    Lantern:Print("Group '" .. name .. "' already exists.");
                end
            end,
        };

        -- List existing groups
        local groups = self.Warehousing:GetAllGroups();
        local sortedNames = {};
        for name, _ in pairs(groups) do
            table.insert(sortedNames, name);
        end
        table.sort(sortedNames, function(a, b) return a:lower() < b:lower(); end);

        local groupOrder = 10;
        for _, groupName in ipairs(sortedNames) do
            local group = groups[groupName];
            local groupKey = "whgroup_" .. groupName:gsub("[^%w]", "_");

            local itemCount = 0;
            if (group.items) then
                for _ in pairs(group.items) do
                    itemCount = itemCount + 1;
                end
            end

            whArgs[groupKey] = {
                order = groupOrder,
                type = "group",
                name = string.format("%s (%d items)", groupName, itemCount),
                args = {
                    limitInput = {
                        order = 1,
                        type = "input",
                        name = "Limit per item",
                        desc = "Target quantity of each item to keep in bags.",
                        width = "normal",
                        get = function()
                            local g = self.Warehousing:GetGroup(groupName);
                            return tostring(g and g.limit or 20);
                        end,
                        set = function(_, val)
                            local num = tonumber(val);
                            if (num and num >= 0) then
                                self.Warehousing:SetGroupLimit(groupName, math.floor(num));
                            end
                        end,
                    },
                    depositMode = {
                        order = 2,
                        type = "select",
                        name = "Deposit mode",
                        desc = "Controls how 'Move to Warbank' behaves.",
                        width = "normal",
                        values = {
                            all = "Deposit all",
                            keep_limit = "Keep limit in bags",
                        },
                        get = function()
                            local g = self.Warehousing:GetGroup(groupName);
                            return g and g.depositMode or "all";
                        end,
                        set = function(_, val)
                            self.Warehousing:SetGroupDepositMode(groupName, val);
                        end,
                    },
                    addItemHeader = {
                        order = 10,
                        type = "header",
                        name = "Add Item",
                    },
                    addItemDropdown = {
                        order = 11,
                        type = "select",
                        name = "From bags",
                        desc = "Select an item currently in your bags (items already in a group are hidden).",
                        width = "double",
                        values = function()
                            local ungrouped = self.Warehousing:GetUngroupedInventoryItems();
                            local vals = { [""] = "Select an item..." };
                            for itemID, data in pairs(ungrouped) do
                                local label = data.name ~= "" and data.name or ("Item " .. itemID);
                                vals[tostring(itemID)] = string.format("%s (x%d)", label, data.count);
                            end
                            return vals;
                        end,
                        get = function() return ""; end,
                        set = function(_, val)
                            if (val == "") then return; end
                            local itemID = tonumber(val);
                            if (not itemID) then return; end
                            local itemName = C_Item.GetItemNameByID(itemID) or ("Item " .. itemID);
                            self.Warehousing:AddItemToGroup(groupName, itemID, itemName);
                            Lantern:Print(string.format("Added %s to group '%s'.", itemName, groupName));
                            refreshOptions(self);
                        end,
                    },
                    addItemInput = {
                        order = 12,
                        type = "input",
                        name = "Item ID or link",
                        desc = "Enter an item ID or Shift+Click an item to add it.",
                        width = "double",
                        get = function()
                            return self._warehousingTemp.itemInput or "";
                        end,
                        set = function(_, val)
                            self._warehousingTemp.itemInput = val or "";
                            self._warehousingTemp.resolvedItemID = nil;
                            self._warehousingTemp.resolvedItemName = nil;

                            if (val and val ~= "") then
                                local itemID = val:match("item:(%d+)");
                                if (not itemID) then
                                    itemID = val:match("^%s*(%d+)%s*$");
                                end
                                if (itemID) then
                                    itemID = tonumber(itemID);
                                    local itemName = C_Item.GetItemNameByID(itemID);
                                    if (itemName) then
                                        self._warehousingTemp.resolvedItemID = itemID;
                                        self._warehousingTemp.resolvedItemName = itemName;
                                    else
                                        self._warehousingTemp.resolvedItemID = itemID;
                                        local item = Item:CreateFromItemID(itemID);
                                        item:ContinueOnItemLoad(function()
                                            self._warehousingTemp.resolvedItemName = C_Item.GetItemNameByID(itemID);
                                        end);
                                    end
                                end
                            end
                        end,
                    },
                    addItemButton = {
                        order = 13,
                        type = "execute",
                        name = "Add",
                        desc = "Add the item specified above to this group",
                        width = "half",
                        func = function()
                            local itemID = self._warehousingTemp.resolvedItemID;
                            if (not itemID) then
                                Lantern:Print("Please enter a valid item ID or item link.");
                                return;
                            end
                            local itemName = self._warehousingTemp.resolvedItemName
                                or C_Item.GetItemNameByID(itemID)
                                or ("Item " .. itemID);
                            self.Warehousing:AddItemToGroup(groupName, itemID, itemName);
                            Lantern:Print(string.format("Added %s to group '%s'.", itemName, groupName));
                            self._warehousingTemp.itemInput = "";
                            self._warehousingTemp.resolvedItemID = nil;
                            self._warehousingTemp.resolvedItemName = nil;
                            refreshOptions(self);
                        end,
                    },
                    itemsHeader = {
                        order = 20,
                        type = "header",
                        name = "Items",
                    },
                },
            };

            -- Add existing items to the group's options
            local itemOrder = 21;
            local hasItems = false;

            if (group.items) then
                -- Sort items by name
                local sortedItems = {};
                for itemID, itemName in pairs(group.items) do
                    table.insert(sortedItems, { id = itemID, name = itemName });
                end
                table.sort(sortedItems, function(a, b)
                    return (a.name or ""):lower() < (b.name or ""):lower();
                end);

                for _, item in ipairs(sortedItems) do
                    hasItems = true;
                    local itemKey = "item_" .. item.id;

                    whArgs[groupKey].args[itemKey .. "_desc"] = {
                        order = itemOrder,
                        type = "description",
                        name = function()
                            local icon = C_Item.GetItemIconByID(item.id);
                            local iconStr = icon and ("|T" .. icon .. ":16|t ") or "";
                            local displayName = item.name ~= "" and item.name or ("Item " .. item.id);
                            return iconStr .. displayName;
                        end,
                        fontSize = "medium",
                        width = "double",
                    };

                    whArgs[groupKey].args[itemKey .. "_remove"] = {
                        order = itemOrder + 0.01,
                        type = "execute",
                        name = "Remove",
                        desc = "Remove this item from the group",
                        width = "half",
                        func = function()
                            self.Warehousing:RemoveItemFromGroup(groupName, item.id);
                            local displayName = item.name ~= "" and item.name or ("Item " .. item.id);
                            Lantern:Print(string.format("Removed %s from group '%s'.", displayName, groupName));
                            refreshOptions(self);
                        end,
                    };

                    itemOrder = itemOrder + 1;
                end
            end

            if (not hasItems) then
                whArgs[groupKey].args.noItems = {
                    order = 21,
                    type = "description",
                    name = "No items in this group yet.",
                    fontSize = "medium",
                };
            end

            -- Delete group section
            whArgs[groupKey].args.deleteHeader = {
                order = 100,
                type = "header",
                name = "",
            };

            whArgs[groupKey].args.deleteGroup = {
                order = 101,
                type = "execute",
                name = "Delete Group",
                desc = "Delete this warehousing group",
                confirm = true,
                confirmText = "Are you sure you want to delete the group '" .. groupName .. "'?",
                func = function()
                    self.Warehousing:DeleteGroup(groupName);
                    Lantern:Print("Deleted warehousing group '" .. groupName .. "'.");
                    refreshOptions(self);
                end,
            };

            groupOrder = groupOrder + 1;
        end

        if (#sortedNames == 0) then
            whArgs.noGroups = {
                order = 10,
                type = "description",
                name = "No warehousing groups defined yet. Create one above.",
                fontSize = "medium",
            };
        end
    end

    return options;
end
