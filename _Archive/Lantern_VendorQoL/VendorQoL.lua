local Lantern = _G.Lantern;
local AceGUI = LibStub and LibStub("AceGUI-3.0", true);

-- Abort early if the core addon is not available.
if (not Lantern) then return; end

local VendorQoL = Lantern:NewModule("VendorQoL", {
    title = "Vendor QoL",
    desc = "Vendor QoL improvements and filtering.",
    enableLabel = "Enable Vendor QoL",
});

local DEFAULTS = {
    enableVendorFiltering = false,
    activeFilterId = 1,
    preserveFilterSelection = true,
    hideKnownCollectibles = false,
    showOnlyUsableItems = false,
};

local function isArmor(item)
    return item and item.classID == LE_ITEM_CLASS_ARMOR;
end

local function isWeapon(item)
    return item and item.classID == LE_ITEM_CLASS_WEAPON;
end

local function isCosmetic(item)
    if (not item) then return false; end
    return item.classID == LE_ITEM_CLASS_ARMOR
        and (item.itemSubType == "Cosmetic" or item.itemType == "Cosmetic");
end

local function isConsumable(item)
    return item and item.classID == LE_ITEM_CLASS_CONSUMABLE;
end

local function isTradeskill(item)
    if (not item) then
        return false;
    end
    if (item.classID == 20 or item.itemType == "Housing") then
        return false;
    end
    return item.classID == LE_ITEM_CLASS_TRADEGOODS
        or item.classID == 7
        or item.itemType == "Tradeskill"
        or item.itemType == "Trade Goods";
end

local function isDecor(item)
    return item and item.classID == 20 and item.subClassID == 0;
end

local function isToy(item)
    if (not item or not item.itemID) then return false; end
    if (C_ToyBox and C_ToyBox.GetToyInfo) then
        local name = C_ToyBox.GetToyInfo(item.itemID);
        if (name) then
            return true;
        end
    end
    return item.itemType == "Toy" or item.itemSubType == "Toy";
end

local function isMount(item)
    if (not item or not item.itemID) then return false; end
    if (C_MountJournal and C_MountJournal.GetMountFromItem) then
        local mountID = C_MountJournal.GetMountFromItem(item.itemID);
        if (mountID) then
            return true;
        end
    end
    if (item.itemSubType == "Mount") then
        return true;
    end
    return item.itemType == "Miscellaneous" and item.itemSubType == "Mount";
end

local FILTERS = {
    {
        id = 1,
        label = "All items",
        icon = "Interface\\Icons\\INV_Misc_QuestionMark",
        predicate = function()
            return true;
        end,
    },
    {
        id = 2,
        label = "Armor",
        icon = "Interface\\Icons\\INV_Chest_Cloth_17",
        predicate = function(item)
            return isArmor(item);
        end,
    },
    {
        id = 3,
        label = "Weapons",
        icon = "Interface\\Icons\\INV_Sword_04",
        predicate = function(item)
            return isWeapon(item);
        end,
    },
    {
        id = 4,
        label = "Cosmetics",
        icon = "Interface\\Icons\\INV_Misc_Bag_10_Blue",
        predicate = function(item)
            return isCosmetic(item);
        end,
    },
    {
        id = 5,
        label = "Consumables",
        icon = "Interface\\Icons\\INV_Potion_93",
        predicate = function(item)
            return isConsumable(item);
        end,
    },
    {
        id = 6,
        label = "Tradeskill",
        icon = "Interface\\Icons\\INV_TradeskillItem_03",
        predicate = function(item)
            return isTradeskill(item);
        end,
    },
    {
        id = 7,
        label = "Decor",
        icon = "Interface\\Icons\\INV_Misc_HouseToy_01",
        predicate = function(item)
            return isDecor(item);
        end,
    },
    {
        id = 8,
        label = "Toys",
        icon = "Interface\\Icons\\INV_Misc_Toy_10",
        predicate = function(item)
            return isToy(item);
        end,
    },
    {
        id = 9,
        label = "Mounts",
        icon = "Interface\\Icons\\Ability_Mount",
        predicate = function(item)
            return isMount(item);
        end,
    },
    {
        id = 10,
        label = "Misc",
        icon = "Interface\\Icons\\INV_Misc_QuestionMark",
        predicate = function(item)
            if (not item) then return false; end
            return not isArmor(item)
                and not isWeapon(item)
                and not isCosmetic(item)
                and not isConsumable(item)
                and not isTradeskill(item)
                and not isDecor(item)
                and not isToy(item)
                and not isMount(item);
        end,
    },
};

local function ensureDB(self)
    _G.LanternVendorQoLDB = _G.LanternVendorQoLDB or {};
    self.db = _G.LanternVendorQoLDB;
    for k, v in pairs(DEFAULTS) do
        if (self.db[k] == nil) then
            self.db[k] = v;
        end
    end
    local valid = false;
    for _, filter in ipairs(FILTERS) do
        if (filter.id == self.db.activeFilterId) then
            valid = true;
            break;
        end
    end
    if (not valid) then
        self.db.activeFilterId = FILTERS[1].id;
    end
end

local function buildFilterValues()
    local values = {};
    for _, filter in ipairs(FILTERS) do
        values[filter.id] = filter.label;
    end
    return values;
end

local function buildFilterIndex()
    local index = {};
    for i, filter in ipairs(FILTERS) do
        index[filter.id] = i;
    end
    return index;
end

function VendorQoL:EnsureVendorUI()
    if (self._vendorPanel) then return; end
    if (not MerchantFrame or not AceGUI) then return; end

    local panel = AceGUI:Create("InlineGroup");
    panel:SetTitle("Vendor Filters");
    panel:SetLayout("Flow");
    panel:SetWidth(240);
    panel:SetHeight(300);
    panel.frame:SetParent(MerchantFrame);
    panel.frame:SetPoint("TOPLEFT", MerchantFrame, "TOPRIGHT", 12, -6);
    panel.frame:SetFrameStrata("DIALOG");
    local backdrop = CreateFrame("Frame", nil, panel.frame, "BackdropTemplate");
    backdrop:SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 0, 0);
    backdrop:SetPoint("BOTTOMRIGHT", panel.frame, "BOTTOMRIGHT", 0, 0);
    backdrop:SetFrameLevel(panel.frame:GetFrameLevel() - 1);
    backdrop:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    });
    backdrop:SetBackdropColor(0.1, 0.1, 0.1, 0.95);
    panel.frame:Show();

    local resetButton = AceGUI:Create("Button");
    resetButton:SetText("Reset filters");
    resetButton:SetFullWidth(true);
    resetButton:SetCallback("OnClick", function()
        if (not VendorQoL.db) then return; end
        VendorQoL.db.activeFilterId = FILTERS[1].id;
        VendorQoL:ApplyVendorFilter();
        VendorQoL:UpdateFilterIcons();
    end);
    panel:AddChild(resetButton);

    local filterIndex = buildFilterIndex();
    local buttonOrder = { 2, 3, 4, 5, 6, 7, 8, 9, 10 };
    local iconGroup = AceGUI:Create("SimpleGroup");
    iconGroup:SetLayout("Flow");
    iconGroup:SetFullWidth(true);
    panel:AddChild(iconGroup);

    self._vendorFilterIcons = {};
    for _, filterId in ipairs(buttonOrder) do
        local filter = FILTERS[filterIndex[filterId]];
        if (filter) then
            local icon = AceGUI:Create("Icon");
            icon:SetImage(filter.icon);
            icon:SetImageSize(18, 18);
            icon:SetLabel(filter.label);
            icon:SetRelativeWidth(0.33);
            icon:SetCallback("OnClick", function()
                if (not VendorQoL.db) then return; end
                VendorQoL.db.activeFilterId = filter.id;
                VendorQoL:ApplyVendorFilter();
                VendorQoL:UpdateFilterIcons();
            end);
            self._vendorFilterIcons[filter.id] = {
                widget = icon,
                labelText = filter.label,
            };
            iconGroup:AddChild(icon);
        end
    end

    local known = AceGUI:Create("CheckBox");
    known:SetLabel("Hide known collectibles");
    known:SetValue(self.db and self.db.hideKnownCollectibles or false);
    known:SetCallback("OnValueChanged", function(_, _, value)
        if (not VendorQoL.db) then return; end
        VendorQoL.db.hideKnownCollectibles = value and true or false;
        VendorQoL:ApplyVendorFilter();
    end);
    panel:AddChild(known);

    local usable = AceGUI:Create("CheckBox");
    usable:SetLabel("Show only usable items");
    usable:SetValue(self.db and self.db.showOnlyUsableItems or false);
    usable:SetCallback("OnValueChanged", function(_, _, value)
        if (not VendorQoL.db) then return; end
        VendorQoL.db.showOnlyUsableItems = value and true or false;
        VendorQoL:ApplyVendorFilter();
    end);
    panel:AddChild(usable);

    self._vendorPanel = panel;
    self._vendorFilterIconGroup = iconGroup;
    self._vendorBackdrop = backdrop;
    self:UpdateFilterIcons();
end

local function buildItemData(merchantIndex)
    local link = GetMerchantItemLink(merchantIndex);
    if (not link) then return; end
    return VendorQoL:BuildItemDataFromLink(link);
end

function VendorQoL:BuildItemDataFromLink(link)
    if (not link) then return; end
    local itemID, itemType, itemSubType, equipLoc, _, classID, subClassID;
    if (C_Item and C_Item.GetItemInfoInstant) then
        itemID, itemType, itemSubType, equipLoc, _, classID, subClassID = C_Item.GetItemInfoInstant(link);
    elseif (GetItemInfoInstant) then
        itemID, itemType, itemSubType, equipLoc, _, classID, subClassID = GetItemInfoInstant(link);
    end

    local isKnown = false;
    if (itemID) then
        if (C_MountJournal and C_MountJournal.GetMountFromItem) then
            local mountID = C_MountJournal.GetMountFromItem(itemID);
            if (mountID and C_MountJournal.GetMountInfoByID) then
                local _, _, _, _, _, _, _, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(mountID);
                isKnown = isCollected or false;
            end
        end
        if (not isKnown and C_PetJournal and C_PetJournal.GetPetInfoByItemID) then
            local petID = C_PetJournal.GetPetInfoByItemID(itemID);
            if (petID) then
                isKnown = true;
            end
        end
        if (not isKnown and PlayerHasToy) then
            isKnown = PlayerHasToy(itemID) or false;
        end
    end

    local isUsable = nil;
    if (itemID or link) then
        if (IsUsableItem) then
            isUsable = IsUsableItem(link or itemID);
        end
    end

    return {
        link = link,
        itemID = itemID,
        itemType = itemType,
        itemSubType = itemSubType,
        classID = classID,
        subClassID = subClassID,
        equipLoc = equipLoc,
        isKnown = isKnown,
        isUsable = isUsable,
    };
end

function VendorQoL:GetActiveFilter()
    if (not self.db) then return; end
    local activeId = tonumber(self.db.activeFilterId) or self.db.activeFilterId;
    for _, filter in ipairs(FILTERS) do
        if (filter.id == activeId) then
            return filter;
        end
    end
end

function VendorQoL:BuildFilteredList()
    local active = self:GetActiveFilter();
    if (not active or not active.predicate) then
        self._filteredMerchantIndices = nil;
        return;
    end
    if (active.id == FILTERS[1].id and not self:HasExtraFilters()) then
        self._filteredMerchantIndices = nil;
        return;
    end

    local filtered = {};
    local total = GetMerchantNumItems();
    for i = 1, total do
        local itemData = buildItemData(i);
        if (itemData and self:ItemPassesFilters(itemData, active)) then
            filtered[#filtered + 1] = i;
        end
    end
    self._filteredMerchantIndices = filtered;
end

function VendorQoL:ApplyVendorFilter()
    self:BuildFilteredList();
    if (MerchantFrame and MerchantFrame:IsShown() and MerchantFrame_Update) then
        MerchantFrame_Update();
        self:ApplyToMerchantFrame();
    end
end

function VendorQoL:ApplyVisibilityFilter()
    if (not MerchantFrame or not MerchantFrame.page) then return; end
    local filtering = self:ShouldFilterMerchant();
    local active = self:GetActiveFilter();
    local filtered = self._filteredMerchantIndices;
    local perPage = MERCHANT_ITEMS_PER_PAGE or 10;
    local pageOffset = (MerchantFrame.page - 1) * perPage;
    for i = 1, perPage do
        local frame = _G["MerchantItem" .. i];
        if (frame) then
            local index = pageOffset + i;
            local mappedIndex = filtering and filtered and filtered[index] or index;
            local link = mappedIndex and GetMerchantItemLink(mappedIndex) or nil;
            local show = true;
            if (filtering) then
                show = false;
                if (link and active and active.predicate) then
                    local itemData = self:BuildItemDataFromLink(link);
                    if (itemData and self:ItemPassesFilters(itemData, active)) then
                        show = true;
                    end
                end
            end
            frame:SetShown(show);
        end
    end
end

function VendorQoL:UpdateFilterIcons()
    if (not self._vendorFilterIcons or not self.db) then return; end
    local activeId = tonumber(self.db.activeFilterId) or self.db.activeFilterId;
    for id, entry in pairs(self._vendorFilterIcons) do
        local widget = entry.widget;
        if (widget and widget.frame and widget.label) then
            local isActive = (activeId == id);
            local baseText = entry.labelText or "";
            widget.label:SetText(isActive and ("|cffffff00" .. baseText .. "|r") or baseText);
        end
    end
end

function VendorQoL:UpdateVendorUI()
    if (not self.db or not self.db.enableVendorFiltering) then
        if (self._vendorPanel) then
            self._vendorPanel.frame:Hide();
        end
        return;
    end
    self:EnsureVendorUI();
    if (self._vendorPanel) then
        if (MerchantFrame and MerchantFrame.GetHeight) then
            self._vendorPanel.frame:SetHeight(MerchantFrame:GetHeight());
        end
        self:UpdateFilterIcons();
        self._vendorPanel.frame:Show();
    end
end

function VendorQoL:HookMerchantFrame()
    if (self._merchantHooked) then return; end
    if (not MerchantFrame_Update or not hooksecurefunc) then return; end
    hooksecurefunc("MerchantFrame_Update", function()
        VendorQoL:ApplyToMerchantFrame();
    end);
    self._merchantHooked = true;
end

function VendorQoL:ShouldFilterMerchant()
    if (not self.db or not self.db.enableVendorFiltering) then return false; end
    local active = self:GetActiveFilter();
    if (not active or not active.predicate) then return false; end
    if (active.id ~= FILTERS[1].id) then
        return true;
    end
    return self:HasExtraFilters();
end

function VendorQoL:HasExtraFilters()
    if (not self.db) then return false; end
    return self.db.hideKnownCollectibles or self.db.showOnlyUsableItems;
end

function VendorQoL:ItemPassesFilters(itemData, active)
    if (not itemData or not active or not active.predicate) then
        return false;
    end
    if (not active.predicate(itemData)) then
        return false;
    end
    if (self.db) then
        if (self.db.hideKnownCollectibles and itemData.isKnown) then
            return false;
        end
        if (self.db.showOnlyUsableItems and itemData.isUsable == false) then
            return false;
        end
    end
    return true;
end

function VendorQoL:ApplyToMerchantFrame()
    if (not MerchantFrame or not MerchantFrame:IsShown()) then return; end
    if (MerchantFrame.selectedTab and MerchantFrame.selectedTab == 2) then return; end
    if (not self:ShouldFilterMerchant()) then return; end

    local filtered = self._filteredMerchantIndices;
    if (not filtered) then
        return;
    end

    local total = #filtered;
    local perPage = MERCHANT_ITEMS_PER_PAGE or 10;
    local maxPage = math.max(1, math.ceil(total / perPage));
    if (not MerchantFrame.page or MerchantFrame.page < 1) then
        MerchantFrame.page = 1;
    end
    if (MerchantFrame.page > maxPage) then
        MerchantFrame.page = maxPage;
    end

    local startIndex = (MerchantFrame.page - 1) * perPage;
    for i = 1, perPage do
        local button = _G["MerchantItem" .. i];
        local itemButton = _G["MerchantItem" .. i .. "ItemButton"];
        local index = filtered[startIndex + i];
        if (index) then
            if (button) then
                button:Show();
            end
            if (itemButton) then
                itemButton:SetID(index);
                if (MerchantFrameItem_Update) then
                    MerchantFrameItem_Update(i);
                end
            end
        else
            if (button) then
                button:Hide();
            end
        end
    end

    if (MerchantPageText) then
        MerchantPageText:SetFormattedText(MERCHANT_PAGE_NUMBER, MerchantFrame.page, maxPage);
    end
    if (MerchantPrevPageButton and MerchantNextPageButton) then
        MerchantPrevPageButton:SetEnabled(MerchantFrame.page > 1);
        MerchantNextPageButton:SetEnabled(MerchantFrame.page < maxPage);
    end
end

function VendorQoL:GetOptions()
    ensureDB(self);
    return {
        general = {
            order = 1,
            type = "group",
            name = "General",
            args = {
                enableVendorFiltering = {
                    order = 1,
                    type = "toggle",
                    name = "Enable vendor filtering",
                    width = "full",
                    get = function() return self.db.enableVendorFiltering; end,
                    set = function(_, value)
                        self.db.enableVendorFiltering = value and true or false;
                        self:UpdateVendorUI();
                    end,
                },
                enableVendorFilteringInfo = {
                    order = 1.1,
                    type = "description",
                    name = "Scaffold only. Vendor filtering rules will be added here.",
                    fontSize = "small",
                },
                preserveFilterSelection = {
                    order = 2,
                    type = "toggle",
                    name = "Preserve filter selection",
                    desc = "Keep the last chosen filter when closing and reopening the vendor.",
                    width = "full",
                    get = function() return self.db.preserveFilterSelection; end,
                    set = function(_, value)
                        self.db.preserveFilterSelection = value and true or false;
                    end,
                },
            },
        },
    };
end

function VendorQoL:OnInit()
    ensureDB(self);
end

function VendorQoL:OnEnable()
    ensureDB(self);
    self.addon:ModuleRegisterEvent(self, "MERCHANT_SHOW", function()
        self:HookMerchantFrame();
        self:UpdateVendorUI();
    end);
    self.addon:ModuleRegisterEvent(self, "MERCHANT_CLOSED", function()
        if (self._vendorPanel) then
            self._vendorPanel.frame:Hide();
        end
        if (self.db and not self.db.preserveFilterSelection) then
            self.db.activeFilterId = FILTERS[1].id;
        end
        self._filteredMerchantIndices = nil;
    end);
    self:UpdateVendorUI();
end

function VendorQoL:OnDisable()
    self._merchantHooked = nil;
    self._merchantUpdateWrapper = nil;
    if (self._vendorPanel and self._vendorPanel.Release) then
        self._vendorPanel:Release();
        self._vendorPanel = nil;
        self._vendorFilterDropdown = nil;
        self._vendorBackdrop = nil;
    end
end

Lantern:RegisterModule(VendorQoL);
