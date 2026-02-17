local ADDON_NAME = "Lantern_Warband";
local Lantern = _G.Lantern;
if (not Lantern or not Lantern.modules or not Lantern.modules.Warband) then return; end

local LanternUX = _G.LanternUX;
if (not LanternUX or not LanternUX.Theme) then return; end

local Warband = Lantern.modules.Warband;
local T = LanternUX.Theme;

-------------------------------------------------------------------------------
-- Utilities
-------------------------------------------------------------------------------

local function getUtils()
    return Warband._optionsUtils;
end

local function refreshPage()
    if (Lantern._uxPanel and Lantern._uxPanel.RefreshCurrentPage) then
        Lantern._uxPanel:RefreshCurrentPage();
    end
end

-------------------------------------------------------------------------------
-- General Tab
-------------------------------------------------------------------------------

local function generalWidgets()
    local utils = getUtils();
    local formatGoldThousands = utils.formatGoldThousands;
    local parseGold = utils.parseGold;

    local widgets = {
        {
            type = "description",
            text = "Manage character groups and automated banking. Create groups with gold thresholds, and when you open a bank, the addon will automatically balance your gold to match the threshold (deposit excess or withdraw if below).",
            fontSize = "medium",
        },
        {
            type = "toggle",
            label = "Auto-balance gold with warbank",
            desc = "Automatically deposit excess gold or withdraw if below threshold when opening a bank.",
            get = function()
                return Warband.db and Warband.db.autoDeposit;
            end,
            set = function(val)
                if (Warband.db) then
                    Warband.db.autoDeposit = val and true or false;
                end
            end,
        },
        { type = "header", text = "Ungrouped Characters" },
        {
            type = "toggle",
            label = "Use default threshold for ungrouped characters",
            desc = "Apply a default gold threshold to characters not assigned to any group.",
            get = function()
                return Warband.db and Warband.db.useDefaultThreshold;
            end,
            set = function(val)
                if (Warband.db) then
                    Warband.db.useDefaultThreshold = val and true or false;
                end
                refreshPage();
            end,
        },
        {
            type = "input",
            label = "Default gold threshold",
            desc = "Gold threshold for characters not in any group. The addon will automatically balance to this amount.",
            disabled = function()
                return not (Warband.db and Warband.db.useDefaultThreshold);
            end,
            get = function()
                local val = Warband.db and Warband.db.defaultThreshold or 1000000000;
                return formatGoldThousands(val);
            end,
            set = function(val)
                local amount = parseGold(val);
                if (amount and amount >= 0) then
                    Warband.db.defaultThreshold = amount;
                end
            end,
        },
        { type = "header", text = "Current Character" },
    };

    -- Dynamic current character info
    local key = Warband:GetCurrentCharacter();
    local group = Warband:GetCharacterGroup();
    local infoText;
    if (group) then
        infoText = string.format("|cff00ff00Current character:|r %s\n|cff00ff00Group:|r %s\n|cff00ff00Gold threshold:|r %s gold",
            key or "Unknown",
            group.name or "None",
            formatGoldThousands(group.goldThreshold or 0));
    else
        local thresholdText = "";
        if (Warband.db and Warband.db.useDefaultThreshold) then
            thresholdText = string.format("\n|cff00ff00Default threshold:|r %s gold", formatGoldThousands(Warband.db.defaultThreshold or 1000000));
        end
        infoText = string.format("|cff00ff00Current character:|r %s\n|cffff0000Not assigned to any group|r%s", key or "Unknown", thresholdText);
    end

    table.insert(widgets, {
        type = "label",
        text = infoText,
    });

    return widgets;
end

-------------------------------------------------------------------------------
-- Groups Tab
-------------------------------------------------------------------------------

local function groupsWidgets()
    local utils = getUtils();
    local formatGoldThousands = utils.formatGoldThousands;
    local parseGold = utils.parseGold;
    local formatTimeAgo = utils.formatTimeAgo;

    -- Ensure temp state exists
    if (not Warband._newGroupTemp) then
        Warband._newGroupTemp = {
            name = "",
            threshold = "100000",
            allowDeposit = true,
            allowWithdraw = true,
        };
    end

    local widgets = {};

    ---------------------------------------------------------------------------
    -- Create New Group section
    ---------------------------------------------------------------------------

    table.insert(widgets, { type = "header", text = "Create New Group" });

    table.insert(widgets, {
        type = "input",
        label = "Group name",
        desc = "Enter a name for the new group (e.g., 'Mains', 'Alts', 'Bankers')",
        get = function() return Warband._newGroupTemp.name or ""; end,
        set = function(val)
            Warband._newGroupTemp.name = val or "";
        end,
    });

    table.insert(widgets, {
        type = "input",
        label = "Gold threshold",
        desc = "Amount of gold to keep on character. Set to 0 to deposit all gold (deposit-only mode).",
        get = function()
            local val = tonumber(Warband._newGroupTemp.threshold) or 100000;
            local copper = val * 10000;
            return formatGoldThousands(copper);
        end,
        set = function(val)
            local amount = parseGold(val);
            if (amount and amount >= 0) then
                local gold = math.floor(amount / 10000);
                Warband._newGroupTemp.threshold = tostring(gold);
            end
        end,
    });

    table.insert(widgets, {
        type = "toggle",
        label = "Allow deposits",
        desc = "Allow depositing gold to warbank when over threshold.",
        get = function()
            if (Warband._newGroupTemp.allowDeposit == nil) then return true; end
            return Warband._newGroupTemp.allowDeposit;
        end,
        set = function(val)
            Warband._newGroupTemp.allowDeposit = val and true or false;
        end,
    });

    table.insert(widgets, {
        type = "toggle",
        label = "Allow withdrawals",
        desc = "Allow withdrawing gold from warbank when below threshold.",
        get = function()
            if (Warband._newGroupTemp.allowWithdraw == nil) then return true; end
            return Warband._newGroupTemp.allowWithdraw;
        end,
        set = function(val)
            Warband._newGroupTemp.allowWithdraw = val and true or false;
        end,
    });

    table.insert(widgets, {
        type = "execute",
        label = "Create Group",
        desc = "Create a new character group with the settings above.",
        func = function()
            local groupName = Warband._newGroupTemp.name;
            local thresholdStr = Warband._newGroupTemp.threshold;
            local threshold = parseGold(thresholdStr);

            if (not groupName or groupName == "") then
                Lantern:Print("Please enter a group name.");
                return;
            end

            if (not threshold) then
                Lantern:Print("Please enter a valid gold amount.");
                return;
            end

            if (Warband.db.groups[groupName]) then
                Lantern:Print("Group '" .. groupName .. "' already exists.");
                return;
            end

            local allowDeposit = Warband._newGroupTemp.allowDeposit;
            local allowWithdraw = Warband._newGroupTemp.allowWithdraw;

            Warband:CreateGroup(groupName, threshold, allowDeposit, allowWithdraw);
            Lantern:Print("Created group '" .. groupName .. "' with threshold of " .. formatGoldThousands(threshold) .. " gold.");

            -- Clear inputs
            Warband._newGroupTemp.name = "";
            Warband._newGroupTemp.threshold = "100000";
            Warband._newGroupTemp.allowDeposit = true;
            Warband._newGroupTemp.allowWithdraw = true;

            refreshPage();
        end,
    });

    ---------------------------------------------------------------------------
    -- Existing Groups
    ---------------------------------------------------------------------------

    local groups = Warband:GetAllGroups();
    table.sort(groups, function(a, b)
        return (a.name or ""):lower() < (b.name or ""):lower();
    end);

    for _, group in ipairs(groups) do
        local memberCount = group.members and #group.members or 0;
        local groupLabel = string.format("%s - %d member%s", group.name, memberCount, memberCount == 1 and "" or "s");

        local children = {};

        -- Group name (editable)
        table.insert(children, {
            type = "input",
            label = "Group name",
            desc = "Change the name of this group. Press Enter to confirm.",
            get = function() return group.name; end,
            set = function(val)
                if (not val or val == "") then
                    Lantern:Print("Please enter a new name.");
                    return;
                end
                if (val == group.name) then return; end
                if (Warband.db.groups[val]) then
                    Lantern:Print("Group '" .. val .. "' already exists.");
                    return;
                end

                local oldName = group.name;
                Warband:RenameGroup(oldName, val);
                Lantern:Print("Renamed group '" .. oldName .. "' to '" .. val .. "'.");
                refreshPage();
            end,
        });

        -- Gold threshold (editable)
        table.insert(children, {
            type = "input",
            label = "Gold threshold",
            desc = "Change the gold threshold for this group. Set to 0 to deposit all gold (deposit-only mode).",
            get = function()
                local freshGroup = Warband.db.groups[group.name];
                return formatGoldThousands(freshGroup and freshGroup.goldThreshold or 0);
            end,
            set = function(val)
                local amount = parseGold(val);
                if (not amount) then
                    Lantern:Print("Please enter a valid gold amount.");
                    return;
                end
                if (amount < 0) then
                    Lantern:Print("Gold amount must be 0 or greater.");
                    return;
                end

                Warband:SetGroupGoldThreshold(group.name, amount);
                Lantern:Print("Updated threshold for '" .. group.name .. "' to " .. formatGoldThousands(amount) .. " gold.");
                refreshPage();
            end,
        });

        -- Allow deposits
        table.insert(children, {
            type = "toggle",
            label = "Allow deposits",
            desc = "Allow depositing gold to warbank when over threshold.",
            get = function()
                local freshGroup = Warband.db.groups[group.name];
                if (freshGroup and freshGroup.allowDeposit ~= nil) then
                    return freshGroup.allowDeposit;
                end
                return true;
            end,
            set = function(val)
                local freshGroup = Warband.db.groups[group.name];
                if (freshGroup) then
                    freshGroup.allowDeposit = val and true or false;
                end
            end,
        });

        -- Allow withdrawals
        table.insert(children, {
            type = "toggle",
            label = "Allow withdrawals",
            desc = "Allow withdrawing gold from warbank when below threshold.",
            get = function()
                local freshGroup = Warband.db.groups[group.name];
                if (freshGroup and freshGroup.allowWithdraw ~= nil) then
                    return freshGroup.allowWithdraw;
                end
                return true;
            end,
            set = function(val)
                local freshGroup = Warband.db.groups[group.name];
                if (freshGroup) then
                    freshGroup.allowWithdraw = val and true or false;
                end
            end,
        });

        -- Members
        table.insert(children, { type = "header", text = "Members" });

        if (group.members and #group.members > 0) then
            for _, memberKey in ipairs(group.members) do
                local lastLogin = Lantern:GetCharacterLastLogin(memberKey);
                local timeAgo = formatTimeAgo(lastLogin);

                table.insert(children, {
                    type = "label_action",
                    text = memberKey .. "  |cff888888(" .. timeAgo .. ")|r",
                    buttonLabel = "Remove",
                    desc = "Remove " .. memberKey .. " from this group.",
                    confirm = "Remove " .. memberKey .. " from '" .. group.name .. "'?",
                    func = function()
                        Warband:RemoveCharacterFromGroup(memberKey);
                        Lantern:Print("Removed " .. memberKey .. " from group '" .. group.name .. "'.");
                        refreshPage();
                    end,
                });
            end
        else
            table.insert(children, {
                type = "description",
                text = "No members in this group yet.",
                fontSize = "small",
                color = T.textDim,
            });
        end

        -- Add current character button
        table.insert(children, {
            type = "execute",
            label = "Add Current Character",
            desc = "Add the current character to this group.",
            func = function()
                local currentChar = Warband:GetCurrentCharacter();
                if (not currentChar) then
                    Lantern:Print("Could not get current character.");
                    return;
                end

                local currentGroup = Warband:GetCharacterGroup(currentChar);
                if (currentGroup and currentGroup.name == group.name) then
                    Lantern:Print(currentChar .. " is already in group '" .. group.name .. "'.");
                    return;
                end

                Warband:AssignCharacterToGroup(currentChar, group.name);
                Lantern:Print("Added " .. currentChar .. " to group '" .. group.name .. "'.");
                refreshPage();
            end,
        });

        -- Delete group
        table.insert(children, { type = "divider" });

        table.insert(children, {
            type = "execute",
            label = "Delete Group",
            desc = "Delete this group. Characters will be unassigned.",
            confirm = "Are you sure you want to delete '" .. group.name .. "'?",
            func = function()
                Warband:DeleteGroup(group.name);
                Lantern:Print("Deleted group '" .. group.name .. "'.");
                refreshPage();
            end,
        });

        table.insert(widgets, {
            type = "group",
            text = groupLabel,
            children = children,
        });
    end

    if (#groups == 0) then
        table.insert(widgets, { type = "divider" });
        table.insert(widgets, {
            type = "description",
            text = "No groups created yet. Use the form above to create your first group.",
            fontSize = "small",
            color = T.textDim,
        });
    end

    return widgets;
end

-------------------------------------------------------------------------------
-- Characters Tab
-------------------------------------------------------------------------------

local function charactersWidgets()
    local utils = getUtils();
    local formatGoldThousands = utils.formatGoldThousands;

    local widgets = {
        {
            type = "description",
            text = "Assign characters to groups. Characters in a group will automatically balance their gold to the threshold when opening a bank.",
            fontSize = "medium",
        },
        { type = "header", text = "Current Character" },
    };

    -- Build group values for dropdown
    local groupValues = { [""] = "None" };
    local groupSorting = { "" };
    local sortedNames = {};
    for name, _ in pairs(Warband.db.groups or {}) do
        table.insert(sortedNames, name);
    end
    table.sort(sortedNames);
    for _, name in ipairs(sortedNames) do
        groupValues[name] = name;
        table.insert(groupSorting, name);
    end

    local currentChar = Warband:GetCurrentCharacter();
    local currentGroup = Warband:GetCharacterGroup();

    table.insert(widgets, {
        type = "select",
        label = "Assign to group",
        desc = "Assign the current character to a group.",
        values = groupValues,
        sorting = groupSorting,
        get = function()
            return currentGroup and currentGroup.name or "";
        end,
        set = function(val)
            if (val == "") then
                Warband:RemoveCharacterFromGroup(currentChar);
                Lantern:Print("Removed " .. currentChar .. " from groups.");
            else
                Warband:AssignCharacterToGroup(currentChar, val);
                Lantern:Print("Assigned " .. currentChar .. " to group '" .. val .. "'.");
            end
            refreshPage();
        end,
    });

    table.insert(widgets, { type = "header", text = "All Characters" });

    -- List all assigned characters
    local hasChars = false;
    local charEntries = {};

    for charKey, groupName in pairs(Warband.db.characterGroups or {}) do
        hasChars = true;
        table.insert(charEntries, { key = charKey, groupName = groupName });
    end

    table.sort(charEntries, function(a, b) return a.key < b.key; end);

    for _, entry in ipairs(charEntries) do
        local group = Warband.db.groups[entry.groupName];
        local name, realm = entry.key:match("^(.+)-(.+)$");
        local displayName = name and realm and (name .. " - " .. realm) or entry.key;

        local text;
        if (group) then
            text = string.format("|cff00ff00%s|r  ->  %s (%s gold threshold)",
                displayName,
                entry.groupName,
                formatGoldThousands(group.goldThreshold or 0));
        else
            text = string.format("|cffff0000%s|r  ->  %s (group not found)", displayName, entry.groupName);
        end

        table.insert(widgets, {
            type = "label",
            text = text,
        });
    end

    if (not hasChars) then
        table.insert(widgets, {
            type = "description",
            text = "No characters assigned yet.",
            fontSize = "small",
            color = T.textDim,
        });
    end

    return widgets;
end

-------------------------------------------------------------------------------
-- Warehousing Tab
-------------------------------------------------------------------------------

local function warehousingWidgets()
    local Warehousing = Warband.Warehousing;
    local WarehousingUI = Warband.WarehousingUI;

    -- Guard: Warehousing requires Retail bank tabs
    if (not Warehousing or not Enum or not Enum.BagIndex or not Enum.BagIndex.AccountBankTab_1) then
        return {
            {
                type = "description",
                text = "Warehousing is not available in this version of the game.",
                fontSize = "medium",
                color = T.textDim,
            },
        };
    end

    -- Sync bank UI after mutations
    local function syncBankUI()
        if (WarehousingUI and WarehousingUI._populatePanel) then
            WarehousingUI._populatePanel();
        end
    end

    -- Ensure temp state for new group name
    if (not Warband._newWHGroupTemp) then
        Warband._newWHGroupTemp = { name = "" };
    end

    local widgets = {
        {
            type = "description",
            text = "Organize warbank items into groups and move them between your bags and the warband bank. Create groups, assign items, and configure deposit/restock rules.",
            fontSize = "medium",
        },
    };

    ---------------------------------------------------------------------------
    -- Create New Group section
    ---------------------------------------------------------------------------

    table.insert(widgets, { type = "header", text = "Create New Group" });

    table.insert(widgets, {
        type = "input",
        label = "Group name",
        desc = "Enter a name for the new warehousing group.",
        get = function() return Warband._newWHGroupTemp.name or ""; end,
        set = function(val)
            Warband._newWHGroupTemp.name = val or "";
        end,
    });

    table.insert(widgets, {
        type = "execute",
        label = "Create Group",
        desc = "Create a new warehousing group with the name above.",
        func = function()
            local name = Warband._newWHGroupTemp.name;
            if (not name or name == "") then
                Lantern:Print("Please enter a group name.");
                return;
            end

            local success = Warehousing:CreateGroup(name);
            if (success) then
                Lantern:Print("Created warehousing group '" .. name .. "'.");
                Warband._newWHGroupTemp.name = "";
                syncBankUI();
                refreshPage();
            else
                Lantern:Print("Group '" .. name .. "' already exists.");
            end
        end,
    });

    ---------------------------------------------------------------------------
    -- Existing Groups
    ---------------------------------------------------------------------------

    local allGroups = Warehousing:GetAllGroups();
    local sortedNames = {};
    for name, _ in pairs(allGroups) do
        table.insert(sortedNames, name);
    end
    table.sort(sortedNames, function(a, b) return a:lower() < b:lower(); end);

    for _, groupName in ipairs(sortedNames) do
        local group = allGroups[groupName];
        if (group) then
            local itemCount = 0;
            if (group.items) then
                for _ in pairs(group.items) do
                    itemCount = itemCount + 1;
                end
            end

            local groupLabel = string.format("%s (%d item%s)", groupName, itemCount, itemCount == 1 and "" or "s");
            local children = {};

            -- Temp state for add-item input per group
            if (not Warband._whAddItemTemp) then Warband._whAddItemTemp = {}; end
            if (not Warband._whAddItemTemp[groupName]) then Warband._whAddItemTemp[groupName] = ""; end

            -------------------------------------------------------------------
            -- Deposit section
            -------------------------------------------------------------------

            table.insert(children, { type = "header", text = "Deposit" });

            table.insert(children, {
                type = "toggle",
                label = "Enable deposit",
                desc = "Deposit items from your bags into the warbank when visiting the bank.",
                get = function()
                    local g = Warehousing:GetGroup(groupName);
                    return g and g.depositEnabled;
                end,
                set = function(val)
                    local g = Warehousing:GetGroup(groupName);
                    if (g) then
                        g.depositEnabled = val and true or false;
                        syncBankUI();
                        refreshPage();
                    end
                end,
            });

            table.insert(children, {
                type = "toggle",
                label = "Deposit all",
                desc = "Deposit all items in your bags (ignoring quantity limit). Disable to deposit a specific quantity.",
                disabled = function()
                    local g = Warehousing:GetGroup(groupName);
                    return not (g and g.depositEnabled);
                end,
                get = function()
                    local g = Warehousing:GetGroup(groupName);
                    return g and g.depositAll;
                end,
                set = function(val)
                    local g = Warehousing:GetGroup(groupName);
                    if (g) then
                        g.depositAll = val and true or false;
                        syncBankUI();
                        refreshPage();
                    end
                end,
            });

            table.insert(children, {
                type = "input",
                label = "Deposit quantity",
                desc = "Maximum number of items to deposit per visit. Only used when 'Deposit all' is off.",
                disabled = function()
                    local g = Warehousing:GetGroup(groupName);
                    return not (g and g.depositEnabled) or (g and g.depositAll);
                end,
                get = function()
                    local g = Warehousing:GetGroup(groupName);
                    return tostring(g and g.depositLimit or 0);
                end,
                set = function(val)
                    local num = tonumber(val);
                    if (num and num >= 0) then
                        Warehousing:SetGroupDepositLimit(groupName, math.floor(num));
                        syncBankUI();
                    end
                end,
            });

            -------------------------------------------------------------------
            -- Restock section
            -------------------------------------------------------------------

            table.insert(children, { type = "header", text = "Restock" });

            table.insert(children, {
                type = "toggle",
                label = "Enable restock",
                desc = "Withdraw items from the warbank to your bags when visiting the bank.",
                get = function()
                    local g = Warehousing:GetGroup(groupName);
                    return g and g.restockEnabled;
                end,
                set = function(val)
                    local g = Warehousing:GetGroup(groupName);
                    if (g) then
                        g.restockEnabled = val and true or false;
                        syncBankUI();
                        refreshPage();
                    end
                end,
            });

            table.insert(children, {
                type = "toggle",
                label = "Restock all",
                desc = "Withdraw all available items from the warbank. Disable to restock up to a specific quantity.",
                disabled = function()
                    local g = Warehousing:GetGroup(groupName);
                    return not (g and g.restockEnabled);
                end,
                get = function()
                    local g = Warehousing:GetGroup(groupName);
                    return g and g.restockAll;
                end,
                set = function(val)
                    local g = Warehousing:GetGroup(groupName);
                    if (g) then
                        g.restockAll = val and true or false;
                        syncBankUI();
                        refreshPage();
                    end
                end,
            });

            table.insert(children, {
                type = "input",
                label = "Restock quantity",
                desc = "Target number of items to keep in your bags. Only used when 'Restock all' is off.",
                disabled = function()
                    local g = Warehousing:GetGroup(groupName);
                    return not (g and g.restockEnabled) or (g and g.restockAll);
                end,
                get = function()
                    local g = Warehousing:GetGroup(groupName);
                    return tostring(g and g.restockLimit or 0);
                end,
                set = function(val)
                    local num = tonumber(val);
                    if (num and num >= 0) then
                        Warehousing:SetGroupRestockLimit(groupName, math.floor(num));
                        syncBankUI();
                    end
                end,
            });

            -------------------------------------------------------------------
            -- Keep section
            -------------------------------------------------------------------

            table.insert(children, { type = "header", text = "Keep" });

            table.insert(children, {
                type = "toggle",
                label = "Enable keep minimum",
                desc = "Keep a minimum quantity in the source location. When depositing, keeps at least this many in your bags. When restocking, keeps at least this many in the warbank.",
                get = function()
                    local g = Warehousing:GetGroup(groupName);
                    return g and g.keepEnabled;
                end,
                set = function(val)
                    local g = Warehousing:GetGroup(groupName);
                    if (g) then
                        g.keepEnabled = val and true or false;
                        syncBankUI();
                        refreshPage();
                    end
                end,
            });

            table.insert(children, {
                type = "input",
                label = "Keep quantity",
                desc = "Minimum number of items to keep in the source location.",
                disabled = function()
                    local g = Warehousing:GetGroup(groupName);
                    return not (g and g.keepEnabled);
                end,
                get = function()
                    local g = Warehousing:GetGroup(groupName);
                    return tostring(g and g.keepLimit or 0);
                end,
                set = function(val)
                    local num = tonumber(val);
                    if (num and num >= 0) then
                        Warehousing:SetGroupKeepLimit(groupName, math.floor(num));
                        syncBankUI();
                    end
                end,
            });

            -------------------------------------------------------------------
            -- Add Item section
            -------------------------------------------------------------------

            table.insert(children, { type = "header", text = "Add Item" });

            table.insert(children, {
                type = "input",
                label = "Item ID or item link",
                desc = "Enter an item ID (e.g. 12345) or paste an item link to add it to this group.",
                get = function() return Warband._whAddItemTemp[groupName] or ""; end,
                set = function(val)
                    local itemID = val:match("item:(%d+)");
                    if (not itemID) then
                        itemID = val:match("^%s*(%d+)%s*$");
                    end
                    if (itemID) then
                        itemID = tonumber(itemID);
                        local itemName = C_Item.GetItemNameByID(itemID) or "";
                        Warehousing:AddItemToGroup(groupName, itemID, itemName);
                        local displayName = itemName ~= "" and itemName or ("Item " .. itemID);
                        Lantern:Print(string.format("Added %s to '%s'.", displayName, groupName));
                        Warband._whAddItemTemp[groupName] = "";
                        syncBankUI();
                        refreshPage();
                    else
                        Warband._whAddItemTemp[groupName] = val;
                        Lantern:Print("Invalid item ID or link.");
                    end
                end,
            });

            -------------------------------------------------------------------
            -- Items list
            -------------------------------------------------------------------

            table.insert(children, {
                type = "header",
                text = string.format("Items (%d)", itemCount),
            });

            -- Sort items by name
            local sortedItems = {};
            if (group.items) then
                for itemID, itemName in pairs(group.items) do
                    table.insert(sortedItems, { id = itemID, name = itemName });
                end
                table.sort(sortedItems, function(a, b)
                    return (a.name or ""):lower() < (b.name or ""):lower();
                end);
            end

            if (#sortedItems > 0) then
                for _, item in ipairs(sortedItems) do
                    table.insert(children, {
                        type = "item_row",
                        itemID = item.id,
                        itemName = item.name,
                        desc = "Remove this item from the group.",
                        confirm = "Remove?",
                        func = function()
                            Warehousing:RemoveItemFromGroup(groupName, item.id);
                            local displayName = C_Item.GetItemNameByID(item.id) or ("Item " .. item.id);
                            Lantern:Print(string.format("Removed %s from '%s'.", displayName, groupName));
                            syncBankUI();
                            refreshPage();
                        end,
                    });
                end
            else
                table.insert(children, {
                    type = "description",
                    text = "No items yet. Enter an item ID or paste an item link above.",
                    fontSize = "small",
                    color = T.textDim,
                });
            end

            -------------------------------------------------------------------
            -- Delete Group
            -------------------------------------------------------------------

            table.insert(children, { type = "divider" });

            table.insert(children, {
                type = "execute",
                label = "Delete Group",
                desc = "Delete this warehousing group and all its items.",
                confirm = "Delete '" .. groupName .. "'?",
                func = function()
                    Warehousing:DeleteGroup(groupName);
                    Lantern:Print("Deleted warehousing group '" .. groupName .. "'.");
                    syncBankUI();
                    refreshPage();
                end,
            });

            -------------------------------------------------------------------
            -- Add group widget
            -------------------------------------------------------------------

            table.insert(widgets, {
                type = "group",
                text = groupLabel,
                desc = "Expand to manage items and rules for this group.",
                children = children,
            });
        end
    end

    -- Empty state
    if (#sortedNames == 0) then
        table.insert(widgets, { type = "divider" });
        table.insert(widgets, {
            type = "description",
            text = "No warehousing groups created yet. Use the form above to create your first group.",
            fontSize = "small",
            color = T.textDim,
        });
    end

    return widgets;
end

-------------------------------------------------------------------------------
-- Register uxPages
-------------------------------------------------------------------------------

Warband.uxPages = {
    { key = "warband_general",      opts = { label = "General",      title = "General",      description = "Core warband settings.",                             widgets = generalWidgets } },
    { key = "warband_groups",       opts = { label = "Groups",       title = "Groups",       description = "Create and manage character groups.",                 widgets = groupsWidgets } },
    { key = "warband_characters",   opts = { label = "Characters",   title = "Characters",   description = "Assign characters to groups.",                       widgets = charactersWidgets } },
    { key = "warband_warehousing",  opts = { label = "Warehousing",  title = "Warehousing",  description = "Warbank item management.",                           widgets = warehousingWidgets } },
};
