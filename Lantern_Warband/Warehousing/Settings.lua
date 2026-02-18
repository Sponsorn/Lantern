local Lantern = _G.Lantern;
if (not Lantern or not Lantern.modules or not Lantern.modules.Warband) then return; end
if (not Enum or not Enum.BagIndex or not Enum.BagIndex.AccountBankTab_1) then return; end

local Warband = Lantern.modules.Warband;
local Warehousing = Warband.Warehousing;
local WarehousingUI = Warband.WarehousingUI;

if (not Warehousing or not WarehousingUI) then return; end

---------------------------------------------------------------------------
-- SETTINGS PANEL (two-panel layout: groups list on left, details on right)
-- Custom clean UI with dark semi-transparent background
---------------------------------------------------------------------------

-- Color palette
local COLORS = {
    background = { 0.03, 0.03, 0.03, 0.92 },
    border = { 0.3, 0.3, 0.3, 1.0 },
    titleBar = { 0.08, 0.08, 0.08, 1.0 },
    divider = { 0.3, 0.3, 0.3, 0.8 },
    selected = { 0.2, 0.4, 0.6, 0.6 },
    hover = { 1.0, 1.0, 1.0, 0.1 },
    gold = { 1.0, 0.82, 0.0 },
};

-- Settings panel state
local settingsPanel = nil;
local leftPanel = nil;
local rightPanel = nil;
local rightScrollFrame = nil;
local rightContentFrame = nil;
local groupListScrollFrame = nil;
local groupListContent = nil;
local groupButtons = {};
local selectedGroupName = nil;

-- Forward declarations
local PopulateGroupList;
local PopulateGroupDetails;
local SelectGroup;

local function CreateItemRow(parent, itemID, itemName, rowWidth, yOffset, onRemove)
    local ROW_HEIGHT = 22;
    local ICON_SIZE = 18;

    local row = CreateFrame("Frame", nil, parent);
    row:SetHeight(ROW_HEIGHT);
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, yOffset);
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -12, yOffset);

    -- Hover highlight
    local highlight = row:CreateTexture(nil, "BACKGROUND");
    highlight:SetAllPoints();
    highlight:SetColorTexture(1, 1, 1, 0.05);
    highlight:Hide();

    -- Icon
    local icon = row:CreateTexture(nil, "ARTWORK");
    icon:SetSize(ICON_SIZE, ICON_SIZE);
    icon:SetPoint("LEFT", row, "LEFT", 0, 0);
    local iconPath = C_Item.GetItemIconByID(itemID);
    if (iconPath) then
        icon:SetTexture(iconPath);
    else
        icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
        local item = Item:CreateFromItemID(itemID);
        item:ContinueOnItemLoad(function()
            local loadedIcon = C_Item.GetItemIconByID(itemID);
            if (loadedIcon and icon) then
                icon:SetTexture(loadedIcon);
            end
        end);
    end

    -- Remove button
    local removeBtn = CreateFrame("Button", nil, row);
    removeBtn:SetSize(16, 16);
    removeBtn:SetPoint("RIGHT", row, "RIGHT", 0, 0);
    removeBtn:SetNormalFontObject("GameFontNormalSmall");

    local removeTex = removeBtn:CreateTexture(nil, "ARTWORK");
    removeTex:SetSize(12, 12);
    removeTex:SetPoint("CENTER");
    removeTex:SetTexture("Interface\\Buttons\\UI-StopButton");
    removeTex:SetVertexColor(0.8, 0.2, 0.2);

    local removeHighlight = removeBtn:CreateTexture(nil, "HIGHLIGHT");
    removeHighlight:SetSize(12, 12);
    removeHighlight:SetPoint("CENTER");
    removeHighlight:SetTexture("Interface\\Buttons\\UI-StopButton");
    removeHighlight:SetVertexColor(1, 0.3, 0.3);
    removeHighlight:SetBlendMode("ADD");

    if (onRemove) then
        removeBtn:SetScript("OnClick", function()
            onRemove(itemID);
        end);
    end

    -- Item name (between icon and remove button)
    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
    nameText:SetPoint("LEFT", icon, "RIGHT", 6, 0);
    nameText:SetPoint("RIGHT", removeBtn, "LEFT", -4, 0);
    nameText:SetJustifyH("LEFT");
    nameText:SetWordWrap(false);

    local displayName = itemName or "";
    if (displayName == "") then
        displayName = C_Item.GetItemNameByID(itemID);
    end
    if (displayName and displayName ~= "") then
        nameText:SetText(displayName);
    else
        nameText:SetText("Loading...");
        local item = Item:CreateFromItemID(itemID);
        item:ContinueOnItemLoad(function()
            local loadedName = C_Item.GetItemNameByID(itemID);
            if (loadedName and nameText) then
                nameText:SetText(loadedName);
            end
        end);
    end

    -- Tooltip & hover for the whole row
    row:EnableMouse(true);
    row:SetScript("OnEnter", function(self)
        highlight:Show();
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        GameTooltip:SetItemByID(itemID);
        GameTooltip:Show();
    end);
    row:SetScript("OnLeave", function()
        highlight:Hide();
        GameTooltip:Hide();
    end);

    return row, ROW_HEIGHT;
end

local function ClearRightPanel()
    -- Destroy the content frame (which holds all dynamic elements including FontStrings and Textures)
    if (rightContentFrame) then
        rightContentFrame:Hide();
        rightContentFrame:SetParent(nil);
        rightContentFrame = nil;
    end
end

---------------------------------------------------------------------------
-- RIGHT PANEL: Group Details
---------------------------------------------------------------------------

PopulateGroupDetails = function()
    ClearRightPanel();

    if (not rightPanel or not rightScrollFrame) then return; end

    -- Create content frame as scroll child
    rightContentFrame = CreateFrame("Frame", nil, rightScrollFrame);
    rightContentFrame:SetWidth(344);
    rightContentFrame:SetHeight(1);
    rightScrollFrame:SetScrollChild(rightContentFrame);
    rightScrollFrame:SetVerticalScroll(0);

    if (not selectedGroupName) then
        -- No group selected - show hint
        local hint = rightContentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
        hint:SetPoint("TOP", rightContentFrame, "TOP", 0, -80);
        hint:SetText("Select a group from the list");
        hint:SetTextColor(0.5, 0.5, 0.5);
        rightContentFrame:SetHeight(200);
        return;
    end

    local groups = Warehousing:GetAllGroups();
    local group = groups[selectedGroupName];
    if (not group) then
        selectedGroupName = nil;
        PopulateGroupDetails();
        return;
    end

    local yOffset = -12;

    -- Group name header (gold color)
    local nameHeader = rightContentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
    nameHeader:SetPoint("TOPLEFT", rightContentFrame, "TOPLEFT", 12, yOffset);
    nameHeader:SetText(selectedGroupName);
    nameHeader:SetTextColor(unpack(COLORS.gold));

    -- Delete button
    local deleteBtn = CreateFrame("Button", nil, rightContentFrame, "UIPanelButtonTemplate");
    deleteBtn:SetSize(60, 22);
    deleteBtn:SetPoint("TOPRIGHT", rightContentFrame, "TOPRIGHT", -12, yOffset + 2);
    deleteBtn:SetText("Delete");
    deleteBtn:SetScript("OnClick", function()
        StaticPopupDialogs["LANTERN_DELETE_GROUP"] = {
            text = "Delete group '" .. selectedGroupName .. "'?",
            button1 = "Delete",
            button2 = "Cancel",
            OnAccept = function()
                local nameToDelete = selectedGroupName;
                Warehousing:DeleteGroup(nameToDelete);
                Lantern:Print("Deleted group '" .. nameToDelete .. "'.");
                selectedGroupName = nil;
                PopulateGroupList();
                PopulateGroupDetails();
                WarehousingUI._populatePanel();
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        };
        StaticPopup_Show("LANTERN_DELETE_GROUP");
    end);

    yOffset = yOffset - 32;

    -- Divider (simple colored line)
    local divider1 = rightContentFrame:CreateTexture(nil, "ARTWORK");
    divider1:SetHeight(1);
    divider1:SetPoint("TOPLEFT", rightContentFrame, "TOPLEFT", 12, yOffset);
    divider1:SetPoint("TOPRIGHT", rightContentFrame, "TOPRIGHT", -12, yOffset);
    divider1:SetColorTexture(unpack(COLORS.divider));

    yOffset = yOffset - 12;

    -- Helper to create a section with enable checkbox, optional "All" checkbox, and quantity input
    local function CreateSection(label, description, enabledField, allField, limitField, limitSetter)
        -- Enable checkbox + header
        local check = CreateFrame("CheckButton", nil, rightContentFrame, "UICheckButtonTemplate");
        check:SetSize(24, 24);
        check:SetPoint("TOPLEFT", rightContentFrame, "TOPLEFT", 8, yOffset);
        check:SetChecked(group[enabledField]);
        check:SetScript("OnClick", function(self)
            group[enabledField] = self:GetChecked() and true or false;
            PopulateGroupDetails();
            WarehousingUI._populatePanel();
        end);

        local headerText = rightContentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
        headerText:SetPoint("LEFT", check, "RIGHT", 2, 0);
        headerText:SetText(label);

        yOffset = yOffset - 24;

        -- Description
        local descText = rightContentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
        descText:SetPoint("TOPLEFT", rightContentFrame, "TOPLEFT", 34, yOffset);
        descText:SetPoint("TOPRIGHT", rightContentFrame, "TOPRIGHT", -4, yOffset);
        descText:SetJustifyH("LEFT");
        descText:SetWordWrap(true);
        descText:SetText(description);
        descText:SetTextColor(0.6, 0.6, 0.6);

        local descHeight = descText:GetStringHeight() or 14;
        yOffset = yOffset - descHeight - 6;

        if (group[enabledField]) then
            local isAll = allField and group[allField];

            if (allField) then
                -- "All" checkbox
                local allCheck = CreateFrame("CheckButton", nil, rightContentFrame, "UICheckButtonTemplate");
                allCheck:SetSize(24, 24);
                allCheck:SetPoint("TOPLEFT", rightContentFrame, "TOPLEFT", 30, yOffset);
                allCheck:SetChecked(group[allField]);
                allCheck:SetScript("OnClick", function(self)
                    group[allField] = self:GetChecked() and true or false;
                    PopulateGroupDetails();
                    WarehousingUI._populatePanel();
                end);

                local allLabel = rightContentFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
                allLabel:SetPoint("LEFT", allCheck, "RIGHT", 0, 0);
                allLabel:SetText("All");

                -- Quantity input on same line (disabled when All is checked)
                local inputLabel = rightContentFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
                inputLabel:SetPoint("LEFT", allLabel, "RIGHT", 20, 0);
                inputLabel:SetText("Quantity:");
                if (isAll) then
                    inputLabel:SetTextColor(0.4, 0.4, 0.4);
                end

                local input = CreateFrame("EditBox", nil, rightContentFrame, "InputBoxTemplate");
                input:SetSize(60, 20);
                input:SetPoint("LEFT", inputLabel, "RIGHT", 8, 0);
                input:SetAutoFocus(false);
                input:SetNumeric(true);
                input:SetText(tostring(group[limitField] or 0));
                input:SetEnabled(not isAll);
                if (isAll) then
                    input:SetTextColor(0.4, 0.4, 0.4);
                end
                input:SetScript("OnEnterPressed", function(self)
                    local val = tonumber(self:GetText());
                    if (val and val >= 0) then
                        Warehousing[limitSetter](Warehousing, selectedGroupName, math.floor(val));
                        WarehousingUI._populatePanel();
                    end
                    self:ClearFocus();
                end);
                input:SetScript("OnEscapePressed", function(self)
                    self:SetText(tostring(group[limitField] or 0));
                    self:ClearFocus();
                end);
            else
                -- Just quantity input (Keep section)
                local inputLabel = rightContentFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
                inputLabel:SetPoint("TOPLEFT", rightContentFrame, "TOPLEFT", 34, yOffset);
                inputLabel:SetText("Quantity:");

                local input = CreateFrame("EditBox", nil, rightContentFrame, "InputBoxTemplate");
                input:SetSize(60, 20);
                input:SetPoint("LEFT", inputLabel, "RIGHT", 8, 0);
                input:SetAutoFocus(false);
                input:SetNumeric(true);
                input:SetText(tostring(group[limitField] or 0));
                input:SetScript("OnEnterPressed", function(self)
                    local val = tonumber(self:GetText());
                    if (val and val >= 0) then
                        Warehousing[limitSetter](Warehousing, selectedGroupName, math.floor(val));
                        WarehousingUI._populatePanel();
                    end
                    self:ClearFocus();
                end);
                input:SetScript("OnEscapePressed", function(self)
                    self:SetText(tostring(group[limitField] or 0));
                    self:ClearFocus();
                end);
            end

            yOffset = yOffset - 26;
        end
    end

    -- Deposit section
    CreateSection(
        "Deposit",
        "How many items are deposited to the warband bank.",
        "depositEnabled", "depositAll", "depositLimit", "SetGroupDepositLimit"
    );

    yOffset = yOffset - 4;

    -- Restock section
    CreateSection(
        "Restock",
        "How many items are withdrawn to inventory.",
        "restockEnabled", "restockAll", "restockLimit", "SetGroupRestockLimit"
    );

    yOffset = yOffset - 4;

    -- Keep section
    CreateSection(
        "Keep",
        "Minimum quantity to keep in the source location. When depositing, keeps at least this many in your bags. When restocking, keeps at least this many in the warband bank.",
        "keepEnabled", nil, "keepLimit", "SetGroupKeepLimit"
    );

    yOffset = yOffset - 4;

    -- Divider (simple colored line)
    local divider2 = rightContentFrame:CreateTexture(nil, "ARTWORK");
    divider2:SetHeight(1);
    divider2:SetPoint("TOPLEFT", rightContentFrame, "TOPLEFT", 12, yOffset);
    divider2:SetPoint("TOPRIGHT", rightContentFrame, "TOPRIGHT", -12, yOffset);
    divider2:SetColorTexture(unpack(COLORS.divider));

    yOffset = yOffset - 16;

    -- Add item section (before items list)
    local addLabel = rightContentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    addLabel:SetPoint("TOPLEFT", rightContentFrame, "TOPLEFT", 12, yOffset);
    addLabel:SetText("Add Item");

    yOffset = yOffset - 20;

    -- Drop slot for drag-and-drop
    local SLOT_SIZE = 37;
    local dropSlotLabel = rightContentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
    dropSlotLabel:SetPoint("TOPLEFT", rightContentFrame, "TOPLEFT", 12, yOffset);
    dropSlotLabel:SetText("Drag & drop:");
    dropSlotLabel:SetTextColor(0.6, 0.6, 0.6);

    local dropSlot = CreateFrame("Button", nil, rightContentFrame);
    dropSlot:SetSize(SLOT_SIZE, SLOT_SIZE);
    dropSlot:SetPoint("LEFT", dropSlotLabel, "RIGHT", 8, 0);

    -- Slot background
    local slotBg = dropSlot:CreateTexture(nil, "BACKGROUND");
    slotBg:SetAllPoints();
    slotBg:SetTexture("Interface\\Buttons\\UI-EmptySlot-Disabled");
    slotBg:SetTexCoord(0.140625, 0.859375, 0.140625, 0.859375);

    -- Border
    local slotBorder = dropSlot:CreateTexture(nil, "BORDER");
    slotBorder:SetSize(SLOT_SIZE + 4, SLOT_SIZE + 4);
    slotBorder:SetPoint("CENTER");
    slotBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border");
    slotBorder:SetBlendMode("ADD");
    slotBorder:SetAlpha(0.4);

    -- Item icon (shown briefly after drop)
    local slotIcon = dropSlot:CreateTexture(nil, "ARTWORK");
    slotIcon:SetSize(SLOT_SIZE - 4, SLOT_SIZE - 4);
    slotIcon:SetPoint("CENTER");
    slotIcon:Hide();

    -- Plus icon overlay
    local plusIcon = dropSlot:CreateTexture(nil, "OVERLAY");
    plusIcon:SetSize(20, 20);
    plusIcon:SetPoint("CENTER");
    plusIcon:SetTexture("Interface\\PaperDollInfoFrame\\Character-Plus");
    plusIcon:SetAlpha(0.7);

    -- Highlight on hover
    local slotHighlight = dropSlot:CreateTexture(nil, "HIGHLIGHT");
    slotHighlight:SetAllPoints();
    slotHighlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square");
    slotHighlight:SetBlendMode("ADD");

    -- Helper to show feedback
    local function showDropFeedback(itemID)
        local iconPath = C_Item.GetItemIconByID(itemID);
        if (iconPath) then
            slotIcon:SetTexture(iconPath);
            slotIcon:Show();
            plusIcon:Hide();
            C_Timer.After(0.5, function()
                if (slotIcon) then
                    slotIcon:SetTexture(nil);
                    slotIcon:Hide();
                    plusIcon:Show();
                end
            end);
        end
    end

    -- Handle drop
    local function handleDrop()
        local cursorType, itemID = GetCursorInfo();
        if (cursorType == "item" and itemID) then
            ClearCursor();
            showDropFeedback(itemID);
            local itemName = C_Item.GetItemNameByID(itemID) or "";
            Warehousing:AddItemToGroup(selectedGroupName, itemID, itemName);
            local displayName = itemName ~= "" and itemName or ("Item " .. itemID);
            Lantern:Print(string.format("Added %s to '%s'.", displayName, selectedGroupName));
            PopulateGroupList();
            PopulateGroupDetails();
            WarehousingUI._populatePanel();
        end
    end

    dropSlot:SetScript("OnReceiveDrag", handleDrop);
    dropSlot:SetScript("OnClick", handleDrop);
    dropSlot:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        GameTooltip:AddLine("Drop Item Here", 1, 1, 1);
        GameTooltip:AddLine("Drag an item from your bags and drop it here to add it to this group.", nil, nil, nil, true);
        GameTooltip:Show();
    end);
    dropSlot:SetScript("OnLeave", function()
        GameTooltip:Hide();
    end);

    yOffset = yOffset - SLOT_SIZE - 8;

    local addHint = rightContentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
    addHint:SetPoint("TOPLEFT", rightContentFrame, "TOPLEFT", 12, yOffset);
    addHint:SetText("Enter item ID or drag and drop:");
    addHint:SetTextColor(0.6, 0.6, 0.6);

    yOffset = yOffset - 22;

    local addInputFrame = CreateFrame("EditBox", nil, rightContentFrame, "InputBoxTemplate");
    addInputFrame:SetSize(240, 20);
    addInputFrame:SetPoint("TOPLEFT", rightContentFrame, "TOPLEFT", 16, yOffset);
    addInputFrame:SetAutoFocus(false);
    addInputFrame:SetScript("OnEnterPressed", function(self)
        local text = self:GetText();
        if (text and text ~= "") then
            local itemID = text:match("^%s*(%d+)%s*$");
            if (itemID) then
                itemID = tonumber(itemID);
                local itemName = C_Item.GetItemNameByID(itemID) or "";
                Warehousing:AddItemToGroup(selectedGroupName, itemID, itemName);
                local displayName = itemName ~= "" and itemName or ("Item " .. itemID);
                Lantern:Print(string.format("Added %s to '%s'.", displayName, selectedGroupName));
                self:SetText("");
                PopulateGroupList();
                PopulateGroupDetails();
            else
                Lantern:Print("Invalid item ID.");
            end
        end
        self:ClearFocus();
    end);
    addInputFrame:SetScript("OnEscapePressed", function(self)
        self:SetText("");
        self:ClearFocus();
    end);

    local addBtn = CreateFrame("Button", nil, rightContentFrame, "UIPanelButtonTemplate");
    addBtn:SetSize(50, 22);
    addBtn:SetPoint("LEFT", addInputFrame, "RIGHT", 4, 0);
    addBtn:SetText("Add");
    addBtn:SetScript("OnClick", function()
        local text = addInputFrame:GetText();
        if (text and text ~= "") then
            local itemID = text:match("^%s*(%d+)%s*$");
            if (itemID) then
                itemID = tonumber(itemID);
                local itemName = C_Item.GetItemNameByID(itemID) or "";
                Warehousing:AddItemToGroup(selectedGroupName, itemID, itemName);
                local displayName = itemName ~= "" and itemName or ("Item " .. itemID);
                Lantern:Print(string.format("Added %s to '%s'.", displayName, selectedGroupName));
                addInputFrame:SetText("");
                PopulateGroupList();
                PopulateGroupDetails();
            else
                Lantern:Print("Invalid item ID.");
            end
        end
    end);

    yOffset = yOffset - 36;

    -- Items section
    local itemCount = 0;
    if (group.items) then
        for _ in pairs(group.items) do
            itemCount = itemCount + 1;
        end
    end

    local itemsLabel = rightContentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    itemsLabel:SetPoint("TOPLEFT", rightContentFrame, "TOPLEFT", 12, yOffset);
    itemsLabel:SetText(string.format("Items (%d)", itemCount));

    yOffset = yOffset - 22;

    -- Item rows list
    local sortedItems = {};
    if (group.items) then
        for itemID, itemName in pairs(group.items) do
            table.insert(sortedItems, { id = itemID, name = itemName });
        end
        table.sort(sortedItems, function(a, b)
            return (a.name or ""):lower() < (b.name or ""):lower();
        end);
    end

    if (#sortedItems == 0) then
        local noItems = rightContentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
        noItems:SetPoint("TOPLEFT", rightContentFrame, "TOPLEFT", 16, yOffset);
        noItems:SetText("No items yet. Drag an item or enter an ID above.");
        noItems:SetTextColor(0.5, 0.5, 0.5);
    else
        for _, item in ipairs(sortedItems) do
            local _, rowHeight = CreateItemRow(rightContentFrame, item.id, item.name, nil, yOffset, function(itemID)
                Warehousing:RemoveItemFromGroup(selectedGroupName, itemID);
                local displayName = C_Item.GetItemNameByID(itemID) or ("Item " .. itemID);
                Lantern:Print(string.format("Removed %s from '%s'.", displayName, selectedGroupName));
                PopulateGroupList();
                PopulateGroupDetails();
            end);
            yOffset = yOffset - rowHeight;
        end
    end

    -- Set scroll content height
    rightContentFrame:SetHeight(math.abs(yOffset) + 12);
end

---------------------------------------------------------------------------
-- LEFT PANEL: Group List (Simple ScrollFrame with manual buttons)
---------------------------------------------------------------------------

local function CreateGroupButton(parent, index)
    local ROW_HEIGHT = 24;

    local button = CreateFrame("Button", nil, parent);
    button:SetHeight(ROW_HEIGHT);
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -(index - 1) * ROW_HEIGHT);
    button:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -(index - 1) * ROW_HEIGHT);

    -- Background for hover/selected states
    local bg = button:CreateTexture(nil, "BACKGROUND");
    bg:SetAllPoints();
    bg:Hide();
    button.Background = bg;

    -- Label
    local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    label:SetPoint("LEFT", button, "LEFT", 12, 0);
    label:SetPoint("RIGHT", button, "RIGHT", -32, 0);
    label:SetJustifyH("LEFT");
    label:SetWordWrap(false);
    button.Label = label;

    -- Item count
    local count = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
    count:SetPoint("RIGHT", button, "RIGHT", -8, 0);
    count:SetTextColor(0.6, 0.6, 0.6);
    button.Count = count;

    -- State tracking
    button.groupName = nil;

    -- Update visual state
    function button:UpdateState()
        local isSelected = (selectedGroupName == self.groupName);
        if (isSelected) then
            self.Label:SetFontObject("GameFontHighlight");
            self.Background:SetColorTexture(unpack(COLORS.selected));
            self.Background:Show();
        else
            self.Label:SetFontObject("GameFontNormal");
            self.Background:Hide();
        end
    end

    -- Hover effects
    button:SetScript("OnEnter", function(self)
        if (selectedGroupName ~= self.groupName) then
            self.Background:SetColorTexture(unpack(COLORS.hover));
            self.Background:Show();
        end
    end);

    button:SetScript("OnLeave", function(self)
        if (selectedGroupName ~= self.groupName) then
            self.Background:Hide();
        end
    end);

    -- Click to select
    button:SetScript("OnClick", function(self)
        SelectGroup(self.groupName);
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
    end);

    return button;
end

SelectGroup = function(groupName)
    selectedGroupName = groupName;

    -- Update all visible buttons
    for _, button in ipairs(groupButtons) do
        if (button:IsShown() and button.UpdateState) then
            button:UpdateState();
        end
    end

    PopulateGroupDetails();
end

PopulateGroupList = function()
    if (not groupListContent) then return; end

    local groups = Warehousing:GetAllGroups();
    local sortedNames = {};
    for name, _ in pairs(groups) do
        table.insert(sortedNames, name);
    end
    table.sort(sortedNames, function(a, b) return a:lower() < b:lower(); end);

    -- Hide all existing buttons
    for _, button in ipairs(groupButtons) do
        button:Hide();
    end

    -- Create/reuse buttons for each group
    local ROW_HEIGHT = 24;
    for i, name in ipairs(sortedNames) do
        local button = groupButtons[i];
        if (not button) then
            button = CreateGroupButton(groupListContent, i);
            groupButtons[i] = button;
        end

        -- Position button
        button:ClearAllPoints();
        button:SetPoint("TOPLEFT", groupListContent, "TOPLEFT", 0, -(i - 1) * ROW_HEIGHT);
        button:SetPoint("TOPRIGHT", groupListContent, "TOPRIGHT", 0, -(i - 1) * ROW_HEIGHT);

        -- Set data
        button.groupName = name;
        button.Label:SetText(name);

        local itemCount = 0;
        if (groups[name].items) then
            for _ in pairs(groups[name].items) do
                itemCount = itemCount + 1;
            end
        end
        button.Count:SetText(tostring(itemCount));

        button:UpdateState();
        button:Show();
    end

    -- Update scroll content height
    local totalHeight = #sortedNames * ROW_HEIGHT;
    groupListContent:SetHeight(math.max(totalHeight, 1));

    -- Auto-select first group if none selected
    if (not selectedGroupName and #sortedNames > 0) then
        SelectGroup(sortedNames[1]);
    elseif (selectedGroupName and not groups[selectedGroupName]) then
        -- Selected group was deleted, select first
        if (#sortedNames > 0) then
            SelectGroup(sortedNames[1]);
        else
            selectedGroupName = nil;
            PopulateGroupDetails();
        end
    end
end

---------------------------------------------------------------------------
-- MAIN PANEL (Custom clean UI)
---------------------------------------------------------------------------

local function CreateSettingsPanel()
    if (settingsPanel) then return settingsPanel; end

    local PANEL_WIDTH = 560;
    local PANEL_HEIGHT = 540;
    local LEFT_WIDTH = 170;
    local TITLE_HEIGHT = 28;

    -- Main frame with BackdropTemplate
    local frame = CreateFrame("Frame", "LanternWarehousingSettingsPanel", UIParent, "BackdropTemplate");
    frame:SetSize(PANEL_WIDTH, PANEL_HEIGHT);
    frame:SetMovable(true);
    frame:EnableMouse(true);
    frame:RegisterForDrag("LeftButton");
    frame:SetScript("OnDragStart", frame.StartMoving);
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing();
    end);
    frame:SetClampedToScreen(true);
    frame:SetFrameStrata("HIGH");
    frame:SetFrameLevel(600);
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0);

    -- Dark semi-transparent backdrop
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    });
    frame:SetBackdropColor(unpack(COLORS.background));
    frame:SetBackdropBorderColor(unpack(COLORS.border));

    -- Close button (create first so we can anchor title bar to it)
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton");
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 2, 2);
    closeBtn:SetFrameLevel(frame:GetFrameLevel() + 10);
    closeBtn:SetScript("OnClick", function()
        frame:Hide();
        selectedGroupName = nil;
    end);
    frame.CloseButton = closeBtn;

    -- Title bar background (stop before close button)
    local titleBar = frame:CreateTexture(nil, "ARTWORK");
    titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1);
    titleBar:SetPoint("TOPRIGHT", closeBtn, "TOPLEFT", 0, -1);
    titleBar:SetHeight(TITLE_HEIGHT);
    titleBar:SetColorTexture(unpack(COLORS.titleBar));

    -- Title text
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    title:SetPoint("LEFT", titleBar, "LEFT", 10, 0);
    title:SetText("Warehousing Settings");
    frame.title = title;

    -- Make title bar draggable
    local titleDragArea = CreateFrame("Frame", nil, frame);
    titleDragArea:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0);
    titleDragArea:SetPoint("TOPRIGHT", closeBtn, "TOPLEFT", 0, 0);
    titleDragArea:SetHeight(TITLE_HEIGHT);
    titleDragArea:EnableMouse(true);
    titleDragArea:RegisterForDrag("LeftButton");
    titleDragArea:SetScript("OnDragStart", function()
        frame:StartMoving();
    end);
    titleDragArea:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing();
    end);

    -- Content area
    local content = CreateFrame("Frame", nil, frame);
    content:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -(TITLE_HEIGHT + 8));
    content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 8);

    -- Left panel
    leftPanel = CreateFrame("Frame", nil, content);
    leftPanel:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0);
    leftPanel:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 0, 0);
    leftPanel:SetWidth(LEFT_WIDTH);

    -- Left panel header (gold color)
    local leftHeader = leftPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    leftHeader:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 8, -4);
    leftHeader:SetText("Groups");
    leftHeader:SetTextColor(unpack(COLORS.gold));

    -- Create scroll frame for group list using UIPanelScrollFrameTemplate
    groupListScrollFrame = CreateFrame("ScrollFrame", nil, leftPanel, "UIPanelScrollFrameTemplate");
    groupListScrollFrame:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 0, -24);
    groupListScrollFrame:SetPoint("BOTTOMRIGHT", leftPanel, "BOTTOMRIGHT", -22, 40);

    -- Content frame that will be scrolled
    groupListContent = CreateFrame("Frame", nil, groupListScrollFrame);
    groupListContent:SetWidth(LEFT_WIDTH - 22);
    groupListContent:SetHeight(1); -- Will be updated dynamically
    groupListScrollFrame:SetScrollChild(groupListContent);

    -- New group button at bottom of left panel
    local newGroupBtn = CreateFrame("Button", nil, leftPanel, "UIPanelButtonTemplate");
    newGroupBtn:SetSize(LEFT_WIDTH - 8, 22);
    newGroupBtn:SetPoint("BOTTOMLEFT", leftPanel, "BOTTOMLEFT", 4, 8);
    newGroupBtn:SetText("New Group");
    newGroupBtn:SetScript("OnClick", function()
        StaticPopupDialogs["LANTERN_NEW_GROUP"] = {
            text = "Enter a name for the new group:",
            button1 = "Create",
            button2 = "Cancel",
            hasEditBox = true,
            editBoxWidth = 200,
            OnAccept = function(self)
                local name = self.EditBox:GetText();
                if (not name or name == "") then
                    Lantern:Print("Please enter a group name.");
                    return;
                end
                local success = Warehousing:CreateGroup(name);
                if (success) then
                    Lantern:Print("Created group '" .. name .. "'.");
                    PopulateGroupList();
                    SelectGroup(name);
                    WarehousingUI._populatePanel();
                else
                    Lantern:Print("Group '" .. name .. "' already exists.");
                end
            end,
            OnShow = function(self)
                self.EditBox:SetText("");
                self.EditBox:SetFocus();
            end,
            EditBoxOnEnterPressed = function(self)
                local parent = self:GetParent();
                local name = self:GetText();
                if (name and name ~= "") then
                    local success = Warehousing:CreateGroup(name);
                    if (success) then
                        Lantern:Print("Created group '" .. name .. "'.");
                        PopulateGroupList();
                        SelectGroup(name);
                        WarehousingUI._populatePanel();
                    else
                        Lantern:Print("Group '" .. name .. "' already exists.");
                    end
                    parent:Hide();
                end
            end,
            EditBoxOnEscapePressed = function(self)
                self:GetParent():Hide();
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        };
        StaticPopup_Show("LANTERN_NEW_GROUP");
    end);

    -- Vertical divider between left and right panels
    local vertDivider = content:CreateTexture(nil, "ARTWORK");
    vertDivider:SetWidth(1);
    vertDivider:SetPoint("TOPLEFT", leftPanel, "TOPRIGHT", 4, 0);
    vertDivider:SetPoint("BOTTOMLEFT", leftPanel, "BOTTOMRIGHT", 4, 0);
    vertDivider:SetColorTexture(unpack(COLORS.divider));

    -- Right panel
    rightPanel = CreateFrame("Frame", nil, content);
    rightPanel:SetPoint("TOPLEFT", leftPanel, "TOPRIGHT", 8, 0);
    rightPanel:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 0);

    -- Scroll frame for right panel content
    rightScrollFrame = CreateFrame("ScrollFrame", nil, rightPanel, "UIPanelScrollFrameTemplate");
    rightScrollFrame:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 0, 0);
    rightScrollFrame:SetPoint("BOTTOMRIGHT", rightPanel, "BOTTOMRIGHT", -22, 0);

    -- ESC to close
    table.insert(UISpecialFrames, "LanternWarehousingSettingsPanel");

    settingsPanel = frame;
    return frame;
end

local function PopulateSettingsPanel()
    PopulateGroupList();
    PopulateGroupDetails();
end

function WarehousingUI:ShowSettingsPanel()
    local frame = CreateSettingsPanel();
    PopulateSettingsPanel();
    frame:Show();
end

function WarehousingUI:HideSettingsPanel()
    if (settingsPanel) then
        settingsPanel:Hide();
        selectedGroupName = nil;
    end
end

function WarehousingUI:ToggleSettingsPanel()
    if (settingsPanel and settingsPanel:IsShown()) then
        self:HideSettingsPanel();
    else
        self:ShowSettingsPanel();
    end
end

-- Called by UI.lua when bank closes to clear editing state
function WarehousingUI:ClearSettingsState()
    selectedGroupName = nil;
    if (settingsPanel) then
        settingsPanel:Hide();
    end
end

