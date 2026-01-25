local ADDON_NAME = "Lantern_Warband";
local Lantern = _G.Lantern;
if (not Lantern or not Lantern.modules or not Lantern.modules.Warband) then return; end

local Warband = Lantern.modules.Warband;

-- Build warehousing tab options (only on Retail with account bank)
function Warband:BuildWarehousingOptions(whArgs, refreshOptions)
    if (not Enum or not Enum.BagIndex or not Enum.BagIndex.AccountBankTab_1 or not self.Warehousing) then
        return;
    end

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
