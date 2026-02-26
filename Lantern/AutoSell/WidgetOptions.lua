local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local LanternUX = _G.LanternUX;
local T = LanternUX and LanternUX.Theme;
if (not T) then return; end

local module = Lantern.modules["AutoSell"];
if (not module) then return; end
local L = Lantern.L;

local moduleEnabled = Lantern.moduleEnabled;
local moduleToggle = Lantern.moduleToggle;

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

    local refreshPage = Lantern.refreshPage;

    local function addItem(list, itemID)
        if (not itemID) then return; end
        itemID = tonumber(itemID);
        if (not itemID) then return; end
        if (list[itemID]) then
            Lantern:Print(L["AUTOSELL_MSG_ALREADY_IN_LIST"]);
            return;
        end
        local itemName = C_Item.GetItemNameByID(itemID) or "";
        list[itemID] = itemName;
        local displayName = itemName ~= "" and itemName or ("Item " .. itemID);
        Lantern:Print(format(L["AUTOSELL_MSG_ADDED_TO_LIST"], displayName));
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
                text = listLabel,
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
                    desc = L["AUTOSELL_REMOVE_DESC"],
                    confirm = L["SHARED_REMOVE_CONFIRM"],
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
    table.insert(widgets, moduleToggle("AutoSell", L["ENABLE"], L["AUTOSELL_ENABLE_DESC"]));
    table.insert(widgets, {
        type = "toggle",
        label = L["AUTOSELL_SELL_GRAYS"],
        desc = L["AUTOSELL_SELL_GRAYS_DESC"],
        disabled = isDisabled,
        get = function() return db().sellGrays; end,
        set = function(val) db().sellGrays = val and true or false; end,
    });
    table.insert(widgets, {
        type = "callout",
        text = format(L["AUTOSELL_CALLOUT"], Lantern:GetModifierName()),
        severity = "notice",
    });

    ---------------------------------------------------------------------------
    -- Global Sell List
    ---------------------------------------------------------------------------
    local globalList = db().globalList;
    local globalItems = buildItemWidgets(globalList, L["AUTOSELL_EMPTY_GLOBAL"], isDisabled);

    local globalChildren = {};
    table.insert(globalChildren, {
        type = "drop_slot",
        label = L["AUTOSELL_DRAG_DROP"],
        desc = L["AUTOSELL_DRAG_GLOBAL_DESC"],
        disabled = isDisabled,
        onDrop = function(itemID)
            addItem(db().globalList, itemID);
        end,
    });
    table.insert(globalChildren, {
        type = "input",
        label = L["AUTOSELL_ITEM_ID"],
        desc = L["AUTOSELL_ITEM_ID_GLOBAL_DESC"],
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
                Lantern:Print(L["AUTOSELL_MSG_INVALID_ITEM_ID"]);
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
        text = format(L["AUTOSELL_GLOBAL_LIST"], globalCount),
        expanded = true,
        stateKey = "autoSellGlobal",
        children = globalChildren,
    });

    ---------------------------------------------------------------------------
    -- Character Sell List
    ---------------------------------------------------------------------------
    local cList = charList();
    local charItems = buildItemWidgets(cList, L["AUTOSELL_EMPTY_CHAR"], isDisabled);

    local charChildren = {};
    table.insert(charChildren, {
        type = "callout",
        text = L["AUTOSELL_CHAR_ONLY_NOTE"],
        severity = "info",
    });
    table.insert(charChildren, {
        type = "drop_slot",
        label = L["AUTOSELL_DRAG_DROP"],
        desc = L["AUTOSELL_DRAG_CHAR_DESC"],
        disabled = isDisabled,
        onDrop = function(itemID)
            addItem(charList(), itemID);
        end,
    });
    table.insert(charChildren, {
        type = "input",
        label = L["AUTOSELL_ITEM_ID"],
        desc = L["AUTOSELL_ITEM_ID_CHAR_DESC"],
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
                Lantern:Print(L["AUTOSELL_MSG_INVALID_ITEM_ID"]);
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
        text = format(L["AUTOSELL_CHAR_LIST"], charName, charCount),
        stateKey = "autoSellChar",
        children = charChildren,
    });

    return widgets;
end
