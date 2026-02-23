local ADDON_NAME = "Lantern_Warband";
local L = select(2, ...).L;
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
            text = L["WARBAND_GENERAL_DESCRIPTION"],
            fontSize = "medium",
        },
        {
            type = "toggle",
            label = L["WARBAND_AUTO_BALANCE"],
            desc = L["WARBAND_AUTO_BALANCE_DESC"],
            get = function()
                return Warband.db and Warband.db.autoDeposit;
            end,
            set = function(val)
                if (Warband.db) then
                    Warband.db.autoDeposit = val and true or false;
                end
            end,
        },
        { type = "header", text = L["WARBAND_UNGROUPED_HEADER"] },
        {
            type = "toggle",
            label = L["WARBAND_USE_DEFAULT_THRESHOLD"],
            desc = L["WARBAND_USE_DEFAULT_THRESHOLD_DESC"],
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
            label = L["WARBAND_DEFAULT_THRESHOLD"],
            desc = L["WARBAND_DEFAULT_THRESHOLD_DESC"],
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
        { type = "header", text = L["WARBAND_CURRENT_CHAR_HEADER"] },
    };

    -- Dynamic current character info
    local key = Warband:GetCurrentCharacter();
    local group = Warband:GetCharacterGroup();
    local infoText;
    if (group) then
        infoText = string.format("|cff00ff00%s|r %s\n|cff00ff00%s|r %s\n|cff00ff00%s|r %s",
            L["WARBAND_CURRENT_CHAR_LABEL"], key or L["WARBAND_UNKNOWN"],
            L["WARBAND_GROUP_LABEL"], group.name or L["WARBAND_NONE"],
            L["WARBAND_GOLD_THRESHOLD_LABEL"], string.format(L["WARBAND_GOLD_SUFFIX"], formatGoldThousands(group.goldThreshold or 0)));
    else
        local thresholdText = "";
        if (Warband.db and Warband.db.useDefaultThreshold) then
            thresholdText = string.format("\n|cff00ff00%s|r %s", L["WARBAND_DEFAULT_THRESHOLD_LABEL"], string.format(L["WARBAND_GOLD_SUFFIX"], formatGoldThousands(Warband.db.defaultThreshold or 1000000)));
        end
        infoText = string.format("|cff00ff00%s|r %s\n|cffff0000%s|r%s", L["WARBAND_CURRENT_CHAR_LABEL"], key or L["WARBAND_UNKNOWN"], L["WARBAND_NOT_ASSIGNED"], thresholdText);
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

    table.insert(widgets, { type = "header", text = L["WARBAND_CREATE_GROUP_HEADER"] });

    table.insert(widgets, {
        type = "input",
        label = L["WARBAND_GROUP_NAME"],
        desc = L["WARBAND_GROUP_NAME_DESC"],
        get = function() return Warband._newGroupTemp.name or ""; end,
        set = function(val)
            Warband._newGroupTemp.name = val or "";
        end,
    });

    table.insert(widgets, {
        type = "input",
        label = L["WARBAND_GOLD_THRESHOLD"],
        desc = L["WARBAND_GOLD_THRESHOLD_DESC"],
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
        label = L["WARBAND_ALLOW_DEPOSITS"],
        desc = L["WARBAND_ALLOW_DEPOSITS_DESC"],
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
        label = L["WARBAND_ALLOW_WITHDRAWALS"],
        desc = L["WARBAND_ALLOW_WITHDRAWALS_DESC"],
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
        label = L["WARBAND_CREATE_GROUP"],
        desc = L["WARBAND_CREATE_GROUP_DESC"],
        func = function()
            local groupName = Warband._newGroupTemp.name;
            local thresholdStr = Warband._newGroupTemp.threshold;
            local threshold = parseGold(thresholdStr);

            if (not groupName or groupName == "") then
                Lantern:Print(L["WARBAND_MSG_ENTER_NAME"]);
                return;
            end

            if (not threshold) then
                Lantern:Print(L["WARBAND_MSG_ENTER_VALID_GOLD"]);
                return;
            end

            if (Warband.db.groups[groupName]) then
                Lantern:Print(string.format(L["WARBAND_MSG_GROUP_EXISTS"], groupName));
                return;
            end

            local allowDeposit = Warband._newGroupTemp.allowDeposit;
            local allowWithdraw = Warband._newGroupTemp.allowWithdraw;

            Warband:CreateGroup(groupName, threshold, allowDeposit, allowWithdraw);
            Lantern:Print(string.format(L["WARBAND_MSG_CREATED_GROUP"], groupName, formatGoldThousands(threshold)));

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
        local groupLabel = string.format(L["WARBAND_GROUP_MEMBER_COUNT"], group.name, memberCount, memberCount == 1 and "" or "s");

        local children = {};

        -- Group name (editable)
        table.insert(children, {
            type = "input",
            label = L["WARBAND_GROUP_NAME"],
            desc = L["WARBAND_RENAME_GROUP_DESC"],
            get = function() return group.name; end,
            set = function(val)
                if (not val or val == "") then
                    Lantern:Print(L["WARBAND_MSG_ENTER_NEW_NAME"]);
                    return;
                end
                if (val == group.name) then return; end
                if (Warband.db.groups[val]) then
                    Lantern:Print(string.format(L["WARBAND_MSG_GROUP_EXISTS"], val));
                    return;
                end

                local oldName = group.name;
                Warband:RenameGroup(oldName, val);
                Lantern:Print(string.format(L["WARBAND_MSG_RENAMED_GROUP"], oldName, val));
                refreshPage();
            end,
        });

        -- Gold threshold (editable)
        table.insert(children, {
            type = "input",
            label = L["WARBAND_GOLD_THRESHOLD"],
            desc = L["WARBAND_EDIT_THRESHOLD_DESC"],
            get = function()
                local freshGroup = Warband.db.groups[group.name];
                return formatGoldThousands(freshGroup and freshGroup.goldThreshold or 0);
            end,
            set = function(val)
                local amount = parseGold(val);
                if (not amount) then
                    Lantern:Print(L["WARBAND_MSG_ENTER_VALID_GOLD"]);
                    return;
                end
                if (amount < 0) then
                    Lantern:Print(L["WARBAND_MSG_GOLD_NONNEGATIVE"]);
                    return;
                end

                Warband:SetGroupGoldThreshold(group.name, amount);
                Lantern:Print(string.format(L["WARBAND_MSG_UPDATED_THRESHOLD"], group.name, formatGoldThousands(amount)));
                refreshPage();
            end,
        });

        -- Allow deposits
        table.insert(children, {
            type = "toggle",
            label = L["WARBAND_ALLOW_DEPOSITS"],
            desc = L["WARBAND_ALLOW_DEPOSITS_DESC"],
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
            label = L["WARBAND_ALLOW_WITHDRAWALS"],
            desc = L["WARBAND_ALLOW_WITHDRAWALS_DESC"],
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
        table.insert(children, { type = "header", text = L["WARBAND_MEMBERS_HEADER"] });

        if (group.members and #group.members > 0) then
            for _, memberKey in ipairs(group.members) do
                local lastLogin = Lantern:GetCharacterLastLogin(memberKey);
                local timeAgo = formatTimeAgo(lastLogin);

                table.insert(children, {
                    type = "label_action",
                    text = memberKey .. "  |cff888888(" .. timeAgo .. ")|r",
                    buttonLabel = L["WARBAND_REMOVE"],
                    desc = string.format(L["WARBAND_REMOVE_MEMBER_DESC"], memberKey),
                    confirm = L["WARBAND_REMOVE_CONFIRM"],
                    func = function()
                        Warband:RemoveCharacterFromGroup(memberKey);
                        Lantern:Print(string.format(L["WARBAND_MSG_REMOVED_FROM_GROUP"], memberKey, group.name));
                        refreshPage();
                    end,
                });
            end
        else
            table.insert(children, {
                type = "description",
                text = L["WARBAND_NO_MEMBERS"],
                fontSize = "small",
                color = T.textDim,
            });
        end

        -- Add current character button
        table.insert(children, {
            type = "execute",
            label = L["WARBAND_ADD_CURRENT_CHAR"],
            desc = L["WARBAND_ADD_CURRENT_CHAR_DESC"],
            func = function()
                local currentChar = Warband:GetCurrentCharacter();
                if (not currentChar) then
                    Lantern:Print(L["WARBAND_MSG_CANNOT_GET_CHAR"]);
                    return;
                end

                local currentGroup = Warband:GetCharacterGroup(currentChar);
                if (currentGroup and currentGroup.name == group.name) then
                    Lantern:Print(string.format(L["WARBAND_MSG_ALREADY_IN_GROUP"], currentChar, group.name));
                    return;
                end

                Warband:AssignCharacterToGroup(currentChar, group.name);
                Lantern:Print(string.format(L["WARBAND_MSG_ADDED_TO_GROUP"], currentChar, group.name));
                refreshPage();
            end,
        });

        -- Delete group
        table.insert(children, { type = "divider" });

        table.insert(children, {
            type = "execute",
            label = L["WARBAND_DELETE_GROUP"],
            desc = L["WARBAND_DELETE_GROUP_DESC"],
            confirm = L["WARBAND_DELETE_CONFIRM"],
            func = function()
                Warband:DeleteGroup(group.name);
                Lantern:Print(string.format(L["WARBAND_MSG_DELETED_GROUP"], group.name));
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
            text = L["WARBAND_NO_GROUPS"],
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
            text = L["WARBAND_CHARS_DESCRIPTION"],
            fontSize = "medium",
        },
        { type = "header", text = L["WARBAND_CURRENT_CHAR_HEADER"] },
    };

    -- Build group values for dropdown
    local groupValues = { [""] = L["WARBAND_NONE"] };
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
        label = L["WARBAND_ASSIGN_TO_GROUP"],
        desc = L["WARBAND_ASSIGN_TO_GROUP_DESC"],
        values = groupValues,
        sorting = groupSorting,
        get = function()
            return currentGroup and currentGroup.name or "";
        end,
        set = function(val)
            if (val == "") then
                Warband:RemoveCharacterFromGroup(currentChar);
                Lantern:Print(string.format(L["WARBAND_MSG_REMOVED_FROM_GROUPS"], currentChar));
            else
                Warband:AssignCharacterToGroup(currentChar, val);
                Lantern:Print(string.format(L["WARBAND_MSG_ASSIGNED_TO_GROUP"], currentChar, val));
            end
            refreshPage();
        end,
    });

    table.insert(widgets, { type = "header", text = L["WARBAND_ALL_CHARS_HEADER"] });

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
            text = string.format("|cff00ff00%s|r  ->  %s (%s)",
                displayName,
                entry.groupName,
                string.format(L["WARBAND_CHAR_GROUP_THRESHOLD"], formatGoldThousands(group.goldThreshold or 0)));
        else
            text = string.format("|cffff0000%s|r  ->  %s (%s)", displayName, entry.groupName, L["WARBAND_CHAR_GROUP_NOT_FOUND"]);
        end

        table.insert(widgets, {
            type = "label",
            text = text,
        });
    end

    if (not hasChars) then
        table.insert(widgets, {
            type = "description",
            text = L["WARBAND_NO_CHARS_ASSIGNED"],
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
                text = L["WARBAND_WH_UNAVAILABLE"],
                fontSize = "medium",
                color = T.textDim,
            },
        };
    end

    -- Sync bank UI after mutations (only when bank panel is open)
    local function syncBankUI()
        if (WarehousingUI and WarehousingUI._populatePanel and WarehousingUI._panel and WarehousingUI._panel:IsShown()) then
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
            text = L["WARBAND_WH_DESCRIPTION"],
            fontSize = "medium",
        },
    };

    ---------------------------------------------------------------------------
    -- Create New Group section
    ---------------------------------------------------------------------------

    table.insert(widgets, { type = "header", text = L["WARBAND_WH_CREATE_GROUP_HEADER"] });

    table.insert(widgets, {
        type = "input",
        label = L["WARBAND_WH_GROUP_NAME"],
        desc = L["WARBAND_WH_GROUP_NAME_DESC"],
        get = function() return Warband._newWHGroupTemp.name or ""; end,
        set = function(val)
            Warband._newWHGroupTemp.name = val or "";
        end,
    });

    table.insert(widgets, {
        type = "execute",
        label = L["WARBAND_WH_CREATE_GROUP"],
        desc = L["WARBAND_WH_CREATE_GROUP_DESC"],
        func = function()
            local name = Warband._newWHGroupTemp.name;
            if (not name or name == "") then
                Lantern:Print(L["WARBAND_WH_MSG_ENTER_NAME"]);
                return;
            end

            local success = Warehousing:CreateGroup(name);
            if (success) then
                Lantern:Print(string.format(L["WARBAND_WH_MSG_CREATED_GROUP"], name));
                Warband._newWHGroupTemp.name = "";
                syncBankUI();
                refreshPage();
            else
                Lantern:Print(string.format(L["WARBAND_WH_MSG_GROUP_EXISTS"], name));
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

            local groupLabel = string.format(L["WARBAND_WH_GROUP_LABEL"], groupName, itemCount, itemCount == 1 and "" or "s");
            local children = {};

            -- Temp state for add-item input per group
            if (not Warband._whAddItemTemp) then Warband._whAddItemTemp = {}; end
            if (not Warband._whAddItemTemp[groupName]) then Warband._whAddItemTemp[groupName] = ""; end

            -------------------------------------------------------------------
            -- Deposit section
            -------------------------------------------------------------------

            table.insert(children, { type = "header", text = L["WARBAND_WH_DEPOSIT_HEADER"] });

            table.insert(children, {
                type = "toggle",
                label = L["WARBAND_WH_ENABLE_DEPOSIT"],
                desc = L["WARBAND_WH_ENABLE_DEPOSIT_DESC"],
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
                label = L["WARBAND_WH_DEPOSIT_ALL"],
                desc = L["WARBAND_WH_DEPOSIT_ALL_DESC"],
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
                label = L["WARBAND_WH_DEPOSIT_QTY"],
                desc = L["WARBAND_WH_DEPOSIT_QTY_DESC"],
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

            table.insert(children, { type = "header", text = L["WARBAND_WH_RESTOCK_HEADER"] });

            table.insert(children, {
                type = "toggle",
                label = L["WARBAND_WH_ENABLE_RESTOCK"],
                desc = L["WARBAND_WH_ENABLE_RESTOCK_DESC"],
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
                label = L["WARBAND_WH_RESTOCK_ALL"],
                desc = L["WARBAND_WH_RESTOCK_ALL_DESC"],
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
                label = L["WARBAND_WH_RESTOCK_QTY"],
                desc = L["WARBAND_WH_RESTOCK_QTY_DESC"],
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

            table.insert(children, { type = "header", text = L["WARBAND_WH_KEEP_HEADER"] });

            table.insert(children, {
                type = "toggle",
                label = L["WARBAND_WH_ENABLE_KEEP"],
                desc = L["WARBAND_WH_ENABLE_KEEP_DESC"],
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
                label = L["WARBAND_WH_KEEP_QTY"],
                desc = L["WARBAND_WH_KEEP_QTY_DESC"],
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

            table.insert(children, { type = "header", text = L["WARBAND_WH_ADD_ITEM_HEADER"] });

            table.insert(children, {
                type = "drop_slot",
                label = L["WARBAND_WH_DRAG_DROP"],
                desc = L["WARBAND_WH_DRAG_DROP_DESC"],
                onDrop = function(itemID)
                    local itemName = C_Item.GetItemNameByID(itemID) or "";
                    Warehousing:AddItemToGroup(groupName, itemID, itemName);
                    local displayName = itemName ~= "" and itemName or ("Item " .. itemID);
                    Lantern:Print(string.format(L["WARBAND_WH_MSG_ADDED_ITEM"], displayName, groupName));
                    -- Defer refresh so the drop handler finishes before widgets are rebuilt
                    C_Timer.After(0, function()
                        syncBankUI();
                        refreshPage();
                    end);
                end,
            });

            table.insert(children, {
                type = "input",
                label = L["WARBAND_WH_ITEM_ID_INPUT"],
                desc = L["WARBAND_WH_ITEM_ID_INPUT_DESC"],
                get = function() return Warband._whAddItemTemp[groupName] or ""; end,
                set = function(val)
                    if (not val or val:match("^%s*$")) then return; end
                    local itemID = val:match("^%s*(%d+)%s*$");
                    if (itemID) then
                        itemID = tonumber(itemID);
                        local itemName = C_Item.GetItemNameByID(itemID) or "";
                        Warehousing:AddItemToGroup(groupName, itemID, itemName);
                        local displayName = itemName ~= "" and itemName or ("Item " .. itemID);
                        Lantern:Print(string.format(L["WARBAND_WH_MSG_ADDED_ITEM"], displayName, groupName));
                        Warband._whAddItemTemp[groupName] = "";
                        syncBankUI();
                        refreshPage();
                    else
                        Warband._whAddItemTemp[groupName] = val;
                        Lantern:Print(L["WARBAND_WH_MSG_INVALID_ITEM_ID"]);
                    end
                end,
            });

            -------------------------------------------------------------------
            -- Items list
            -------------------------------------------------------------------

            table.insert(children, {
                type = "header",
                text = string.format(L["WARBAND_WH_ITEMS_HEADER"], itemCount),
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
                        desc = L["WARBAND_WH_REMOVE_ITEM_DESC"],
                        confirm = L["WARBAND_REMOVE_CONFIRM"],
                        func = function()
                            Warehousing:RemoveItemFromGroup(groupName, item.id);
                            local displayName = C_Item.GetItemNameByID(item.id) or ("Item " .. item.id);
                            Lantern:Print(string.format(L["WARBAND_WH_MSG_REMOVED_ITEM"], displayName, groupName));
                            syncBankUI();
                            refreshPage();
                        end,
                    });
                end
            else
                table.insert(children, {
                    type = "description",
                    text = L["WARBAND_WH_NO_ITEMS"],
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
                label = L["WARBAND_WH_DELETE_GROUP"],
                desc = L["WARBAND_WH_DELETE_GROUP_DESC"],
                confirm = L["WARBAND_WH_DELETE_CONFIRM"],
                func = function()
                    Warehousing:DeleteGroup(groupName);
                    Lantern:Print(string.format(L["WARBAND_WH_MSG_DELETED_GROUP"], groupName));
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
                stateKey = groupName,
                desc = L["WARBAND_WH_GROUP_DESC"],
                children = children,
            });
        end
    end

    -- Empty state
    if (#sortedNames == 0) then
        table.insert(widgets, { type = "divider" });
        table.insert(widgets, {
            type = "description",
            text = L["WARBAND_WH_NO_GROUPS"],
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
    { key = "warband_general",      opts = { label = L["WARBAND_PAGE_GENERAL"],      title = L["WARBAND_PAGE_GENERAL_TITLE"],      description = L["WARBAND_PAGE_GENERAL_DESC"],      widgets = generalWidgets } },
    { key = "warband_groups",       opts = { label = L["WARBAND_PAGE_GROUPS"],       title = L["WARBAND_PAGE_GROUPS_TITLE"],       description = L["WARBAND_PAGE_GROUPS_DESC"],       widgets = groupsWidgets } },
    { key = "warband_characters",   opts = { label = L["WARBAND_PAGE_CHARACTERS"],   title = L["WARBAND_PAGE_CHARACTERS_TITLE"],   description = L["WARBAND_PAGE_CHARACTERS_DESC"],   widgets = charactersWidgets } },
    { key = "warband_warehousing",  opts = { label = L["WARBAND_PAGE_WAREHOUSING"],  title = L["WARBAND_PAGE_WAREHOUSING_TITLE"],  description = L["WARBAND_PAGE_WAREHOUSING_DESC"],  widgets = warehousingWidgets } },
};
