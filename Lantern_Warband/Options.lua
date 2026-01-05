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
        set = function(_, val) self._newGroupTemp.name = val or ""; end,
    };

    groupsArgs.newGroupThreshold = {
        order = 3,
        type = "range",
        name = "Gold threshold",
        desc = function()
            local val = tonumber(self._newGroupTemp.threshold) or 0;
            local copper = val * 10000;
            return string.format("Amount of gold to keep on character. The addon will automatically balance to this amount. Set to 0 to disable auto-balance for this group.\n\n|cff00ff00Current: %s gold|r", formatGoldThousands(copper));
        end,
        width = "double",
        min = 0,
        max = 500000,
        step = 5000,
        bigStep = 10000,
        get = function()
            local val = tonumber(self._newGroupTemp.threshold);
            return val or 100000;
        end,
        set = function(_, val)
            self._newGroupTemp.threshold = tostring(math.floor(val));
        end,
    };

    groupsArgs.newGroupThresholdCustom = {
        order = 4,
        type = "input",
        name = "Custom amount",
        desc = "Enter a custom gold amount if you need a value outside the slider range",
        width = "normal",
        get = function() return self._newGroupTemp.threshold or "100000"; end,
        set = function(_, val)
            local num = tonumber(val);
            if (num and num >= 0) then
                self._newGroupTemp.threshold = tostring(math.floor(num));
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

    groupsArgs.existingGroupsHeader = {
        order = 10,
        type = "header",
        name = "Existing Groups",
    };

    -- List existing groups
    local groups = self:GetAllGroups();
    if (#groups == 0) then
        groupsArgs.noGroups = {
            order = 11,
            type = "description",
            name = "No groups created yet. Create a group above to get started.",
            fontSize = "medium",
        };
    else
        table.sort(groups, function(a, b) return a.name < b.name; end);

        local order = 20;
        for _, group in ipairs(groups) do
            local groupKey = "group_" .. group.name:gsub("[^%w]", "_");

            groupsArgs[groupKey] = {
                order = order,
                type = "group",
                name = group.name,
                inline = true,
                args = {
                    thresholdSlider = {
                        order = 1,
                        type = "range",
                        name = "Gold threshold",
                        desc = function()
                            return string.format("Amount of gold to keep on characters. The addon will automatically balance to this amount. Set to 0 to disable auto-balance.\n\n|cff00ff00Current: %s gold|r", formatGoldThousands(group.goldThreshold or 0));
                        end,
                        width = "double",
                        min = 0,
                        max = 500000,
                        step = 5000,
                        bigStep = 10000,
                        get = function()
                            local copper = group.goldThreshold or 0;
                            local gold = math.floor(copper / 10000);
                            return gold;
                        end,
                        set = function(_, val)
                            local copper = val * 10000;
                            self:SetGroupGoldThreshold(group.name, copper);
                        end,
                    },
                    thresholdCustom = {
                        order = 2,
                        type = "input",
                        name = "Custom amount",
                        desc = "Enter a custom gold amount if you need a value outside the slider range",
                        width = "normal",
                        get = function()
                            return formatGoldThousands(group.goldThreshold or 0);
                        end,
                        set = function(_, val)
                            local amount = parseGold(val);
                            if (amount and amount >= 0) then
                                self:SetGroupGoldThreshold(group.name, amount);
                                Lantern:Print("Updated threshold for '" .. group.name .. "' to " .. formatGoldThousands(amount) .. " gold.");
                            end
                        end,
                    },
                    memberCount = {
                        order = 3,
                        type = "description",
                        name = function()
                            local count = group.members and #group.members or 0;
                            return string.format("|cff00ff00Members:|r %d", count);
                        end,
                    },
                    deleteGroup = {
                        order = 4,
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
                    },
                },
            };

            order = order + 1;
        end
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
