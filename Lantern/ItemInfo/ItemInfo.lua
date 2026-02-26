local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local L = Lantern.L;

local module = Lantern:NewModule("ItemInfo", {
    title = L["ITEMINFO_TITLE"],
    desc = L["ITEMINFO_DESC"],
    defaultEnabled = false,
});

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local DEFAULTS = {
    showIlvlCharacter = true,
    showIlvlBags = true,
    showMissingEnchants = true,
    showMissingGems = true,
    showUpgradeArrow = true,
};

-- Slots that can be enchanted in Midnight (expansion 10)
local ENCHANTABLE_SLOTS = {
    [5]  = true, -- Chest
    [7]  = true, -- Legs
    [8]  = true, -- Feet
    [9]  = true, -- Wrist
    [11] = true, -- Finger1
    [12] = true, -- Finger2
    [15] = true, -- Back
    [16] = true, -- MainHand
};

local hooksRegistered = false;
local inspectHooked = false;
local overlayCount = 0;

-- Which side of the character panel each slot sits on
-- "left" slots show info to the RIGHT, "right" slots show info to the LEFT
local SLOT_SIDE = {
    [1]  = "left",  -- Head
    [2]  = "left",  -- Neck
    [3]  = "left",  -- Shoulder
    [15] = "left",  -- Back
    [5]  = "left",  -- Chest
    [9]  = "left",  -- Wrist
    [10] = "right", -- Hands
    [6]  = "right", -- Waist
    [7]  = "right", -- Legs
    [8]  = "right", -- Feet
    [11] = "right", -- Finger1
    [12] = "right", -- Finger2
    [13] = "right", -- Trinket1
    [14] = "right", -- Trinket2
    [16] = "left",  -- MainHand
    [17] = "right", -- OffHand
};

local MAX_SOCKETS = 4;

-- Maps equip location strings to inventory slot IDs for upgrade comparison
local EQUIPLOC_SLOTS = {
    INVTYPE_HEAD            = { 1 },
    INVTYPE_NECK            = { 2 },
    INVTYPE_SHOULDER        = { 3 },
    INVTYPE_CHEST           = { 5 },
    INVTYPE_ROBE            = { 5 },
    INVTYPE_WAIST           = { 6 },
    INVTYPE_LEGS            = { 7 },
    INVTYPE_FEET            = { 8 },
    INVTYPE_WRIST           = { 9 },
    INVTYPE_HAND            = { 10 },
    INVTYPE_FINGER          = { 11, 12 },
    INVTYPE_TRINKET         = { 13, 14 },
    INVTYPE_CLOAK           = { 15 },
    INVTYPE_WEAPON          = { 16, 17 },
    INVTYPE_WEAPONMAINHAND  = { 16 },
    INVTYPE_2HWEAPON        = { 16 },
    INVTYPE_RANGED          = { 16 },
    INVTYPE_SHIELD          = { 17 },
    INVTYPE_HOLDABLE        = { 17 },
    INVTYPE_WEAPONOFFHAND   = { 17 },
};

-------------------------------------------------------------------------------
-- Database
-------------------------------------------------------------------------------

local function db()
    Lantern.db.itemInfo = Lantern.db.itemInfo or {};
    for k, v in pairs(DEFAULTS) do
        if (Lantern.db.itemInfo[k] == nil) then
            Lantern.db.itemInfo[k] = v;
        end
    end
    return Lantern.db.itemInfo;
end

-------------------------------------------------------------------------------
-- Overlay Creation (Equipment — beside the slot)
-------------------------------------------------------------------------------

local function GetEquipOverlay(button)
    if (button._liiOverlay) then return button._liiOverlay; end

    local slotID = button:GetID();
    local side = SLOT_SIDE[slotID] or "left";

    overlayCount = overlayCount + 1;
    local f = CreateFrame("Frame", "LII_EqOverlay_" .. overlayCount, button);
    f:SetSize(60, button:GetHeight());
    f:SetFrameLevel(button:GetFrameLevel() + 2);

    if (side == "left") then
        -- Frame sits to the RIGHT of the slot button
        f:SetPoint("LEFT", button, "RIGHT", 2, 0);
    else
        -- Frame sits to the LEFT of the slot button
        f:SetPoint("RIGHT", button, "LEFT", -2, 0);
    end
    f._side = side;

    -- Item level (bottom, near the slot edge)
    local ilvl = f:CreateFontString(nil, "OVERLAY");
    ilvl:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE");
    if (side == "left") then
        ilvl:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 2, 2);
    else
        ilvl:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, 2);
    end
    f._ilvl = ilvl;

    -- Missing enchant warning (top, near the slot edge)
    local enchant = f:CreateFontString(nil, "OVERLAY");
    enchant:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE");
    enchant:SetTextColor(1, 0.2, 0.2);
    enchant:SetText("E");
    enchant:Hide();
    if (side == "left") then
        enchant:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -2);
    else
        enchant:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2);
    end
    f._enchant = enchant;

    -- Socket icon textures (beside the ilvl text)
    f._sockets = {};
    for i = 1, MAX_SOCKETS do
        local tex = f:CreateTexture(nil, "OVERLAY");
        tex:SetSize(14, 14);
        tex:Hide();
        f._sockets[i] = tex;
    end
    -- Anchor sockets relative to ilvl text
    if (side == "left") then
        f._sockets[1]:SetPoint("LEFT", ilvl, "RIGHT", 3, 1);
        for i = 2, MAX_SOCKETS do
            f._sockets[i]:SetPoint("LEFT", f._sockets[i - 1], "RIGHT", 2, 0);
        end
    else
        f._sockets[1]:SetPoint("RIGHT", ilvl, "LEFT", -3, 1);
        for i = 2, MAX_SOCKETS do
            f._sockets[i]:SetPoint("RIGHT", f._sockets[i - 1], "LEFT", -2, 0);
        end
    end

    button._liiOverlay = f;
    return f;
end

local function GetContainerOverlay(button)
    if (button._liiOverlay) then return button._liiOverlay; end

    overlayCount = overlayCount + 1;
    local f = CreateFrame("Frame", "LII_CnOverlay_" .. overlayCount, button);
    f:SetAllPoints();
    f:SetFrameLevel(button:GetFrameLevel() + 2);

    local ilvl = f:CreateFontString(nil, "OVERLAY");
    ilvl:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE");
    ilvl:SetPoint("BOTTOMRIGHT", -2, 2);
    f._ilvl = ilvl;

    local arrow = f:CreateTexture(nil, "OVERLAY");
    arrow:SetAtlas("bags-greenarrow");
    arrow:SetSize(12, 12);
    arrow:SetPoint("TOPLEFT", 1, -1);
    arrow:Hide();
    f._upgradeArrow = arrow;

    button._liiOverlay = f;
    return f;
end

local function HideOverlay(button)
    if (button._liiOverlay) then
        button._liiOverlay:Hide();
        if (button._liiOverlay._upgradeArrow) then
            button._liiOverlay._upgradeArrow:Hide();
        end
    end
end

-------------------------------------------------------------------------------
-- Item Info Helpers
-------------------------------------------------------------------------------

local function HasEnchant(link)
    if (not link) then return false; end
    local enchantID = link:match("item:%d+:(%d+)");
    return enchantID and enchantID ~= "0" and enchantID ~= "";
end

-- Returns a list of socket entries: { icon = "texture", empty = bool } per socket
local function GetSocketData(unit, slotID)
    local data = C_TooltipInfo.GetInventoryItem(unit, slotID);
    if (not data or not data.lines) then return nil; end
    local sockets = {};
    for _, line in ipairs(data.lines) do
        if (line.type == 3) then
            if (line.gemIcon) then
                sockets[#sockets + 1] = { icon = line.gemIcon, empty = false };
            else
                local socketType = line.socketType or "Red";
                local tex = "Interface\\ItemSocketingFrame\\UI-EmptySocket-" .. socketType;
                sockets[#sockets + 1] = { icon = tex, empty = true };
            end
        end
    end
    return (#sockets > 0) and sockets or nil;
end

local function IsEquipment(link)
    if (not link) then return false; end
    local _, _, _, _, _, classID = C_Item.GetItemInfoInstant(link);
    return classID == Enum.ItemClass.Weapon or classID == Enum.ItemClass.Armor;
end

local function GetIlvlAndQuality(link)
    if (not link) then return nil, nil; end
    local effectiveILvl = C_Item.GetDetailedItemLevelInfo(link);
    if (not effectiveILvl or effectiveILvl <= 1) then return nil, nil; end
    local _, _, quality = GetItemInfo(link);
    return effectiveILvl, quality;
end

local function SetIlvlText(fontString, ilvl, quality)
    fontString:SetText(ilvl);
    if (quality and ITEM_QUALITY_COLORS[quality]) then
        local c = ITEM_QUALITY_COLORS[quality];
        fontString:SetTextColor(c.r, c.g, c.b);
    else
        fontString:SetTextColor(1, 1, 1);
    end
    fontString:Show();
end

local function IsUpgrade(link)
    if (not link) then return false; end

    local _, _, _, equipLoc = C_Item.GetItemInfoInstant(link);
    if (not equipLoc or equipLoc == "") then return false; end

    local slots = EQUIPLOC_SLOTS[equipLoc];
    if (not slots) then return false; end

    if (not IsEquippableItem(link)) then return false; end

    local itemIlvl = C_Item.GetDetailedItemLevelInfo(link);
    if (not itemIlvl or itemIlvl <= 1) then return false; end

    local lowestIlvl = nil;
    local hasEmptySlot = false;

    for _, slotID in ipairs(slots) do
        local equippedLink = GetInventoryItemLink("player", slotID);
        if (not equippedLink) then
            hasEmptySlot = true;
        else
            local equippedIlvl = C_Item.GetDetailedItemLevelInfo(equippedLink);
            if (equippedIlvl) then
                if (not lowestIlvl or equippedIlvl < lowestIlvl) then
                    lowestIlvl = equippedIlvl;
                end
            end
        end
    end

    if (hasEmptySlot) then return true; end
    if (lowestIlvl and itemIlvl > lowestIlvl) then return true; end

    return false;
end

-------------------------------------------------------------------------------
-- Equipment Slot Update (Character / Inspect)
-------------------------------------------------------------------------------

local function UpdateEquipmentSlot(button, unit)
    if (not module.enabled) then
        HideOverlay(button);
        return;
    end

    local slotID = button:GetID();
    if (not slotID or slotID == 0 or slotID == 4 or slotID == 19) then
        HideOverlay(button);
        return;
    end

    local link = GetInventoryItemLink(unit, slotID);
    if (not link) then
        HideOverlay(button);
        return;
    end

    local d = db();
    local showIlvl = d.showIlvlCharacter;
    local showEnchant = d.showMissingEnchants;
    local showGems = d.showMissingGems;

    if (not showIlvl and not showEnchant and not showGems) then
        HideOverlay(button);
        return;
    end

    local overlay = GetEquipOverlay(button);
    overlay:Show();

    -- Item level
    if (showIlvl) then
        local ilvl, quality = GetIlvlAndQuality(link);
        if (ilvl) then
            SetIlvlText(overlay._ilvl, ilvl, quality);
        else
            overlay._ilvl:Hide();
        end
    else
        overlay._ilvl:Hide();
    end

    -- Missing enchant
    if (showEnchant and ENCHANTABLE_SLOTS[slotID]) then
        local unitLevel = UnitLevel(unit);
        local isMaxLevel = unitLevel and IsLevelAtEffectiveMaxLevel(unitLevel);
        if (isMaxLevel and not HasEnchant(link)) then
            overlay._enchant:Show();
        else
            overlay._enchant:Hide();
        end
    else
        overlay._enchant:Hide();
    end

    -- Socket icons
    local sockets = overlay._sockets;
    if (showGems) then
        local socketData = GetSocketData(unit, slotID);
        if (socketData) then
            for i = 1, MAX_SOCKETS do
                local tex = sockets[i];
                local data = socketData[i];
                if (data) then
                    tex:SetTexture(data.icon);
                    if (data.empty) then
                        tex:SetVertexColor(1, 0.2, 0.2);
                    else
                        tex:SetVertexColor(1, 1, 1);
                    end
                    tex:Show();
                else
                    tex:Hide();
                end
            end
        else
            for i = 1, MAX_SOCKETS do
                sockets[i]:Hide();
            end
        end
    else
        for i = 1, MAX_SOCKETS do
            sockets[i]:Hide();
        end
    end
end

-------------------------------------------------------------------------------
-- Container Item Update (Bags / Bank / Loot / Flyout)
-------------------------------------------------------------------------------

local function UpdateContainerButton(button, link)
    if (not module.enabled or not db().showIlvlBags) then
        HideOverlay(button);
        return;
    end

    if (not link or not IsEquipment(link)) then
        HideOverlay(button);
        return;
    end

    local ilvl, quality = GetIlvlAndQuality(link);
    if (not ilvl) then
        HideOverlay(button);
        return;
    end

    local overlay = GetContainerOverlay(button);
    overlay:Show();
    SetIlvlText(overlay._ilvl, ilvl, quality);

    if (overlay._upgradeArrow) then
        if (db().showUpgradeArrow and IsUpgrade(link)) then
            overlay._upgradeArrow:Show();
        else
            overlay._upgradeArrow:Hide();
        end
    end
end

-------------------------------------------------------------------------------
-- Hook Registration
-------------------------------------------------------------------------------

local function TryHookInspect()
    if (inspectHooked) then return; end
    if (not InspectPaperDollItemSlotButton_Update) then return; end

    hooksecurefunc("InspectPaperDollItemSlotButton_Update", function(button)
        if (not module.enabled) then return; end
        local unit = InspectFrame and InspectFrame.unit;
        if (unit) then
            UpdateEquipmentSlot(button, unit);
        end
    end);
    inspectHooked = true;
end

local function RegisterHooks()
    ---------------------------------------------------------------------------
    -- Character panel
    ---------------------------------------------------------------------------
    hooksecurefunc("PaperDollItemSlotButton_Update", function(button)
        UpdateEquipmentSlot(button, "player");
    end);

    ---------------------------------------------------------------------------
    -- Inspect panel (LoadOnDemand)
    ---------------------------------------------------------------------------
    if (C_AddOns.IsAddOnLoaded("Blizzard_InspectUI")) then
        TryHookInspect();
    elseif (EventUtil and EventUtil.ContinueOnAddOnLoaded) then
        EventUtil.ContinueOnAddOnLoaded("Blizzard_InspectUI", TryHookInspect);
    end

    ---------------------------------------------------------------------------
    -- Bags (individual frames + combined bags view)
    -- Must hook frame instances directly — Mixin() copies methods at creation
    -- time so hooking the prototype table has no effect on existing frames.
    ---------------------------------------------------------------------------
    local function OnBagUpdateItems(frame)
        if (not module.enabled) then return; end
        if (not frame.EnumerateValidItems) then return; end
        for _, button in frame:EnumerateValidItems() do
            local bag = button.GetBagID and button:GetBagID();
            local slot = button:GetID();
            if (bag and slot and slot > 0) then
                local info = C_Container.GetContainerItemInfo(bag, slot);
                local link = info and info.hyperlink;
                UpdateContainerButton(button, link);
            end
        end
    end

    -- Combined bags view
    if (ContainerFrameCombinedBags) then
        hooksecurefunc(ContainerFrameCombinedBags, "UpdateItems", OnBagUpdateItems);
    end

    -- Individual bag frames
    local container = ContainerFrameContainer or UIParent;
    if (container.ContainerFrames) then
        for _, frame in ipairs(container.ContainerFrames) do
            hooksecurefunc(frame, "UpdateItems", OnBagUpdateItems);
        end
    end

    ---------------------------------------------------------------------------
    -- Bank
    ---------------------------------------------------------------------------
    if (BankPanelItemButtonMixin) then
        hooksecurefunc(BankPanelItemButtonMixin, "Refresh", function(self)
            if (not module.enabled or not db().showIlvlBags) then
                HideOverlay(self);
                return;
            end
            local loc = self.GetItemLocation and self:GetItemLocation();
            if (not loc or not C_Item.DoesItemExist(loc)) then
                HideOverlay(self);
                return;
            end
            local link = C_Item.GetItemLink(loc);
            UpdateContainerButton(self, link);
        end);
    end

    ---------------------------------------------------------------------------
    -- Equipment flyout
    ---------------------------------------------------------------------------
    if (EquipmentFlyout_DisplayButton) then
        hooksecurefunc("EquipmentFlyout_DisplayButton", function(button, paperDollItemSlot)
            if (not module.enabled or not db().showIlvlBags) then
                HideOverlay(button);
                return;
            end
            local location = button.location;
            if (not location) then
                HideOverlay(button);
                return;
            end
            local player, bank, bags, voidStorage, slot, bag = EquipmentManager_UnpackLocation(location);
            local link;
            if (bags and bag and slot) then
                local info = C_Container.GetContainerItemInfo(bag, slot);
                link = info and info.hyperlink;
            elseif (player and slot) then
                link = GetInventoryItemLink("player", slot);
            end
            UpdateContainerButton(button, link);
        end);
    end

    ---------------------------------------------------------------------------
    -- Loot
    ---------------------------------------------------------------------------
    if (LootFrameElementMixin) then
        hooksecurefunc(LootFrameElementMixin, "Init", function(self, data)
            if (not module.enabled or not db().showIlvlBags) then
                HideOverlay(self);
                return;
            end
            local slotIndex = data and data.slotIndex;
            if (not slotIndex) then
                HideOverlay(self);
                return;
            end
            local link = GetLootSlotLink(slotIndex);
            UpdateContainerButton(self, link);
        end);
    end
end

-------------------------------------------------------------------------------
-- Module Lifecycle
-------------------------------------------------------------------------------

function module:OnInit()
    db();
end

function module:OnEnable()
    if (not hooksRegistered) then
        RegisterHooks();
        hooksRegistered = true;
    end
end

function module:OnDisable()
    -- Hooks persist but early-return when module.enabled is false
end

Lantern:RegisterModule(module);
