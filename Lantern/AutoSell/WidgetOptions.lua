local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local LanternUX = _G.LanternUX;
local T = LanternUX and LanternUX.Theme;
if (not T) then return; end

local module = Lantern.modules["AutoSell"];
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
        Lantern.db.autoSell = Lantern.db.autoSell or {};
        if (Lantern.db.autoSell.sellGrays == nil) then
            Lantern.db.autoSell.sellGrays = true;
        end
        if (type(Lantern.db.autoSell.globalList) ~= "table") then
            Lantern.db.autoSell.globalList = {};
        end
        if (type(Lantern.db.autoSell.characterLists) ~= "table") then
            Lantern.db.autoSell.characterLists = {};
        end
        return Lantern.db.autoSell;
    end

    local function charKey()
        return Lantern:GetCharacterKey();
    end

    local function charList()
        local d = db();
        local key = charKey();
        if (not key) then return {}; end
        if (not d.characterLists[key]) then
            d.characterLists[key] = {};
        end
        return d.characterLists[key];
    end

    local isDisabled = function()
        return not moduleEnabled("AutoSell");
    end

    local function refreshPage()
        local panel = Lantern._uxPanel;
        if (panel and panel.RefreshCurrentPage) then
            panel:RefreshCurrentPage();
        end
    end

    local function addItem(list, itemID)
        if (not itemID) then return; end
        itemID = tonumber(itemID);
        if (not itemID) then return; end
        if (list[itemID]) then
            Lantern:Print("Item already in sell list.");
            return;
        end
        local itemName = C_Item.GetItemNameByID(itemID) or "";
        list[itemID] = itemName;
        local displayName = itemName ~= "" and itemName or ("Item " .. itemID);
        Lantern:Print("Added " .. displayName .. " to sell list.");
        C_Timer.After(0, refreshPage);
    end

    local function buildItemWidgets(list, listLabel, isDisabledFn)
        local widgets = {};
        local sortedItems = {};
        for itemID, itemName in pairs(list) do
            table.insert(sortedItems, { id = itemID, name = itemName });
        end
        table.sort(sortedItems, function(a, b)
            return (a.name or ""):lower() < (b.name or ""):lower();
        end);

        if (#sortedItems == 0) then
            table.insert(widgets, {
                type = "description",
                text = "No items in " .. listLabel .. ".",
                fontSize = "small",
                color = T.textDim,
            });
        else
            for _, item in ipairs(sortedItems) do
                local displayName = item.name;
                if (displayName and displayName ~= "") then
                    displayName = displayName .. " (" .. item.id .. ")";
                else
                    displayName = "Item " .. item.id;
                end
                table.insert(widgets, {
                    type = "item_row",
                    itemID = item.id,
                    itemName = displayName,
                    desc = "Remove this item from the sell list.",
                    confirm = "Remove?",
                    disabled = isDisabledFn,
                    func = function()
                        list[item.id] = nil;
                        refreshPage();
                    end,
                });
            end
        end
        return widgets;
    end

    -- Temp state for input fields
    Lantern._autoSellGlobalInput = Lantern._autoSellGlobalInput or "";
    Lantern._autoSellCharInput = Lantern._autoSellCharInput or "";

    local widgets = {};

    -- Enable + sell grays
    table.insert(widgets, moduleToggle("AutoSell", "Enable", "Enable or disable Auto Sell."));
    table.insert(widgets, {
        type = "toggle",
        label = "Sell gray items",
        desc = "Automatically sell all poor quality (gray) items.",
        disabled = isDisabled,
        get = function() return db().sellGrays; end,
        set = function(val) db().sellGrays = val and true or false; end,
    });
    table.insert(widgets, {
        type = "callout",
        text = "Hold " .. Lantern:GetModifierName() .. " when opening a vendor to skip auto-sell.",
        severity = "notice",
    });

    ---------------------------------------------------------------------------
    -- Global Sell List
    ---------------------------------------------------------------------------
    local globalList = db().globalList;
    local globalItems = buildItemWidgets(globalList, "global sell list", isDisabled);

    local globalChildren = {};
    table.insert(globalChildren, {
        type = "drop_slot",
        label = "Drag and drop:",
        desc = "Drag an item from your bags and drop it here to add it to the global sell list.",
        disabled = isDisabled,
        onDrop = function(itemID)
            addItem(db().globalList, itemID);
        end,
    });
    table.insert(globalChildren, {
        type = "input",
        label = "Item ID",
        desc = "Enter an item ID to add to the global sell list.",
        disabled = isDisabled,
        get = function() return Lantern._autoSellGlobalInput or ""; end,
        set = function(val)
            if (not val or val:match("^%s*$")) then return; end
            local itemID = val:match("^%s*(%d+)%s*$");
            if (itemID) then
                addItem(db().globalList, itemID);
                Lantern._autoSellGlobalInput = "";
            else
                Lantern._autoSellGlobalInput = val;
                Lantern:Print("Invalid item ID.");
            end
        end,
    });
    for _, w in ipairs(globalItems) do
        table.insert(globalChildren, w);
    end

    local globalCount = 0;
    for _ in pairs(globalList) do globalCount = globalCount + 1; end
    table.insert(widgets, {
        type = "group",
        text = "Global Sell List (" .. globalCount .. ")",
        expanded = true,
        stateKey = "autoSellGlobal",
        children = globalChildren,
    });

    ---------------------------------------------------------------------------
    -- Character Sell List
    ---------------------------------------------------------------------------
    local cList = charList();
    local charItems = buildItemWidgets(cList, "character sell list", isDisabled);

    local charChildren = {};
    table.insert(charChildren, {
        type = "callout",
        text = "Items in this list are only sold on this character.",
        severity = "info",
    });
    table.insert(charChildren, {
        type = "drop_slot",
        label = "Drag and drop:",
        desc = "Drag an item from your bags and drop it here to add it to this character's sell list.",
        disabled = isDisabled,
        onDrop = function(itemID)
            addItem(charList(), itemID);
        end,
    });
    table.insert(charChildren, {
        type = "input",
        label = "Item ID",
        desc = "Enter an item ID to add to this character's sell list.",
        disabled = isDisabled,
        get = function() return Lantern._autoSellCharInput or ""; end,
        set = function(val)
            if (not val or val:match("^%s*$")) then return; end
            local itemID = val:match("^%s*(%d+)%s*$");
            if (itemID) then
                addItem(charList(), itemID);
                Lantern._autoSellCharInput = "";
            else
                Lantern._autoSellCharInput = val;
                Lantern:Print("Invalid item ID.");
            end
        end,
    });
    for _, w in ipairs(charItems) do
        table.insert(charChildren, w);
    end

    local charCount = 0;
    for _ in pairs(cList) do charCount = charCount + 1; end
    local charName = charKey() or "Unknown";
    table.insert(widgets, {
        type = "group",
        text = charName .. " Sell List (" .. charCount .. ")",
        stateKey = "autoSellChar",
        children = charChildren,
    });

    return widgets;
end
