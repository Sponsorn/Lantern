local L = select(2, ...).L;
local Lantern = _G.Lantern;
if (not Lantern or not Lantern.modules or not Lantern.modules.Warband) then return; end
if (not Enum or not Enum.BagIndex or not Enum.BagIndex.AccountBankTab_1) then return; end

local Warband = Lantern.modules.Warband;
local Treatise = Warband.Treatise;

if (not Treatise) then return; end

local TreatiseUI = {};
Warband.TreatiseUI = TreatiseUI;

-------------------------------------------------------------------------------
-- Frame references & state
-------------------------------------------------------------------------------

local bankButton = nil;
local panel = nil;
local rows = {};
local takeBtn = nil;
local isTaking = false;

-------------------------------------------------------------------------------
-- DB helpers
-------------------------------------------------------------------------------

local function IsEnabled()
    return Warband.db and Warband.db.treatise and Warband.db.treatise.enabled;
end

local function SavePanelOpen(isOpen)
    if (not Warband.db or not Warband.db.treatise) then return; end
    Warband.db.treatise.panelOpen = isOpen;
end

local function IsPanelOpenSaved()
    return Warband.db and Warband.db.treatise and Warband.db.treatise.panelOpen;
end

-------------------------------------------------------------------------------
-- Row creation
-------------------------------------------------------------------------------

local ROW_HEIGHT = 24;
local ROW_WIDTH = 250;

local function ClearRows()
    for _, row in ipairs(rows) do
        row.frame:Hide();
        row.frame:SetParent(nil);
    end
    rows = {};
end

local function CreateRow(parent, index, entry)
    local frame = CreateFrame("Frame", "LanternTreatise_Row_" .. index, parent);
    frame:SetSize(ROW_WIDTH, ROW_HEIGHT);
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -(index - 1) * ROW_HEIGHT);
    frame:EnableMouse(true);

    -- Background (alternating)
    local bg = frame:CreateTexture(nil, "BACKGROUND");
    bg:SetAllPoints();
    bg:SetColorTexture(1, 1, 1, (index % 2 == 0) and 0.04 or 0.0);

    -- Hover highlight
    local hover = frame:CreateTexture(nil, "HIGHLIGHT");
    hover:SetAllPoints();
    hover:SetColorTexture(1, 1, 1, 0.06);

    -- Status indicator (left side)
    local indicator = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
    indicator:SetPoint("LEFT", frame, "LEFT", 6, 0);
    indicator:SetWidth(16);
    indicator:SetJustifyH("CENTER");

    -- Item icon
    local icon = frame:CreateTexture(nil, "ARTWORK");
    icon:SetSize(18, 18);
    icon:SetPoint("LEFT", frame, "LEFT", 24, 0);

    -- Profession name
    local nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    nameText:SetPoint("LEFT", icon, "RIGHT", 6, 0);
    nameText:SetJustifyH("LEFT");

    -- Count (right side)
    local countText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
    countText:SetPoint("RIGHT", frame, "RIGHT", -8, 0);
    countText:SetJustifyH("RIGHT");

    -- Set content based on entry state
    local itemTexture = C_Item.GetItemIconByID(entry.itemID);
    icon:SetTexture(itemTexture);

    countText:SetText(entry.count .. "x");

    if (entry.playerHas and entry.completedThisWeek) then
        -- Completed: dimmed with checkmark
        indicator:SetText(READY_CHECK_READY_TEXTURE);
        nameText:SetText("|cff666666" .. entry.name .. "|r");
        countText:SetTextColor(0.4, 0.4, 0.4);
        icon:SetDesaturated(true);
        icon:SetAlpha(0.5);
    elseif (entry.playerHas and not entry.completedThisWeek) then
        -- Player has profession, not completed: bright with arrow
        indicator:SetText("|cff00ff00>|r");
        nameText:SetText("|cffffffff" .. entry.name .. "|r");
        countText:SetTextColor(1, 1, 1);
        icon:SetDesaturated(false);
        icon:SetAlpha(1);
    else
        -- Player doesn't have this profession: grey
        indicator:SetText("");
        nameText:SetText("|cff555555" .. entry.name .. "|r");
        countText:SetTextColor(0.35, 0.35, 0.35);
        icon:SetDesaturated(true);
        icon:SetAlpha(0.4);
    end

    -- Tooltip on hover
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        GameTooltip:SetItemByID(entry.itemID);
        GameTooltip:Show();
    end);
    frame:SetScript("OnLeave", function() GameTooltip:Hide(); end);

    local row = { frame = frame };
    table.insert(rows, row);
    return row;
end

-------------------------------------------------------------------------------
-- Panel
-------------------------------------------------------------------------------

local function PopulatePanel()
    ClearRows();

    local status = Treatise:GetTreatiseStatus();
    local scrollChild = panel._scrollChild;

    for i, entry in ipairs(status) do
        CreateRow(scrollChild, i, entry);
    end

    scrollChild:SetHeight(#status * ROW_HEIGHT);

    -- Update take button state
    if (takeBtn) then
        local canTake = false;
        for _, entry in ipairs(status) do
            if (entry.playerHas and not entry.completedThisWeek and entry.count > 0) then
                canTake = true;
                break;
            end
        end
        takeBtn:SetEnabled(canTake and not isTaking);
    end
end

TreatiseUI._populatePanel = PopulatePanel;

local function SavePanelPosition(frame)
    local point, _, relativePoint, x, y = frame:GetPoint(1);
    if (Warband.db and Warband.db.treatise) then
        Warband.db.treatise.panelPosition = {
            point = point,
            relativePoint = relativePoint,
            x = x,
            y = y,
        };
    end
end

local function ResetPanelPosition(frame)
    frame:ClearAllPoints();
    frame:SetPoint("TOPLEFT", BankFrame, "TOPRIGHT", 10, 0);
    if (Warband.db and Warband.db.treatise) then
        Warband.db.treatise.panelPosition = nil;
    end
end

local function CreatePanel()
    if (panel) then return panel; end

    local frame = CreateFrame("Frame", "LanternTreatisePanel", UIParent, "ButtonFrameTemplate");
    frame:SetSize(300, 360);
    frame:SetMovable(true);
    frame:EnableMouse(true);
    frame:RegisterForDrag("LeftButton");
    frame:SetScript("OnDragStart", frame.StartMoving);
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing();
        SavePanelPosition(self);
    end);
    frame:SetClampedToScreen(true);
    frame:SetFrameStrata("MEDIUM");
    frame:SetFrameLevel(500);

    -- Set portrait and title
    frame:SetPortraitToAsset("Interface\\Icons\\inv_inscription_tradeskill01");
    frame:SetTitle(L["WARBAND_TREATISE_UI_TITLE"]);

    -- Restore saved position or use default
    local saved = Warband.db and Warband.db.treatise and Warband.db.treatise.panelPosition;
    if (saved and saved.point) then
        frame:SetPoint(saved.point, UIParent, saved.relativePoint, saved.x, saved.y);
    else
        frame:SetPoint("TOPLEFT", BankFrame, "TOPRIGHT", 10, 0);
    end

    -- Close button
    frame.CloseButton:SetScript("OnClick", function()
        TreatiseUI:Hide();
    end);

    -- Title bar drag and right-click reset
    if (frame.TitleContainer) then
        frame.TitleContainer:EnableMouse(true);
        frame.TitleContainer:RegisterForDrag("LeftButton");
        frame.TitleContainer:SetScript("OnDragStart", function()
            frame:StartMoving();
        end);
        frame.TitleContainer:SetScript("OnDragStop", function()
            frame:StopMovingOrSizing();
            SavePanelPosition(frame);
        end);
        frame.TitleContainer:SetScript("OnMouseUp", function(_, button)
            if (button == "RightButton") then
                ResetPanelPosition(frame);
            end
        end);
    end

    -- Adjust Inset to leave room for bottom button
    frame.Inset:ClearAllPoints();
    frame.Inset:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -60);
    frame.Inset:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -6, 40);

    -- Scroll frame inside the Inset
    local scrollFrame = CreateFrame("ScrollFrame", "LanternTreatise_ScrollFrame", frame.Inset, "UIPanelScrollFrameTemplate");
    scrollFrame:SetPoint("TOPLEFT", frame.Inset, "TOPLEFT", 6, -4);
    scrollFrame:SetPoint("BOTTOMRIGHT", frame.Inset, "BOTTOMRIGHT", -22, 4);

    local scrollChild = CreateFrame("Frame", "LanternTreatise_ScrollChild", scrollFrame);
    scrollChild:SetSize(ROW_WIDTH, 1);
    scrollFrame:SetScrollChild(scrollChild);

    frame._scrollChild = scrollChild;

    -- "Take 1 for each skill" button at bottom
    takeBtn = CreateFrame("Button", "LanternTreatise_TakeBtn", frame, "UIPanelButtonTemplate");
    takeBtn:SetSize(272, 22);
    takeBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 14, 14);
    takeBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -14, 14);
    takeBtn:SetText(L["WARBAND_TREATISE_UI_TAKE_BTN"]);
    takeBtn:SetScript("OnClick", function()
        TreatiseUI:TakeAll();
    end);
    takeBtn:SetScript("OnEnter", function(btn)
        GameTooltip:SetOwner(btn, "ANCHOR_TOP");
        GameTooltip:SetText(L["WARBAND_TREATISE_UI_TAKE_TOOLTIP"]);
        GameTooltip:AddLine(L["WARBAND_TREATISE_UI_TAKE_TOOLTIP_DESC"], 1, 1, 1, true);
        GameTooltip:Show();
    end);
    takeBtn:SetScript("OnLeave", function() GameTooltip:Hide(); end);

    -- ESC to close
    table.insert(UISpecialFrames, "LanternTreatisePanel");

    panel = frame;
    TreatiseUI._panel = panel;

    return frame;
end

-------------------------------------------------------------------------------
-- Take All
-------------------------------------------------------------------------------

function TreatiseUI:TakeAll()
    if (isTaking) then return; end

    local status = Treatise:GetTreatiseStatus();

    -- Build list of items to take
    local toTake = {};
    for _, entry in ipairs(status) do
        if (entry.playerHas and not entry.completedThisWeek and entry.count > 0 and #entry.slots > 0) then
            table.insert(toTake, entry);
        end
    end

    if (#toTake == 0) then
        Lantern:Print(L["WARBAND_TREATISE_MSG_TOOK_NONE"]);
        return;
    end

    isTaking = true;
    if (takeBtn) then takeBtn:SetEnabled(false); end

    local taken = {};
    local index = 1;

    local function takeNext()
        if (not isTaking) then return; end  -- cancelled (e.g. bank closed)
        if (index > #toTake) then
            -- Done
            isTaking = false;
            local count = #taken;
            local names = table.concat(taken, ", ");
            Lantern:Print(string.format(L["WARBAND_TREATISE_MSG_TOOK"], count, count == 1 and "" or "s", names));
            -- Refresh panel after a short delay for bag updates
            C_Timer.After(0.5, function()
                if (panel and panel:IsShown()) then
                    PopulatePanel();
                end
            end);
            return;
        end

        local entry = toTake[index];
        local firstSlot = entry.slots[1];

        -- Find a free bag slot
        local freeBag, freeSlot = Treatise:FindFreeBagSlot();
        if (not freeBag) then
            isTaking = false;
            if (takeBtn) then takeBtn:SetEnabled(true); end
            Lantern:Print(L["WARBAND_TREATISE_UI_NO_BAG_SPACE"]);
            if (#taken > 0) then
                local names = table.concat(taken, ", ");
                Lantern:Print(string.format(L["WARBAND_TREATISE_MSG_TOOK"], #taken, #taken == 1 and "" or "s", names));
            end
            return;
        end

        -- Pick up from warbank, place in bag
        C_Container.PickupContainerItem(firstSlot.bag, firstSlot.slot);
        if (GetCursorInfo() == "item") then
            C_Container.PickupContainerItem(freeBag, freeSlot);
            table.insert(taken, entry.name);
        else
            ClearCursor();
        end

        index = index + 1;
        C_Timer.After(0.3, takeNext);
    end

    takeNext();
end

-------------------------------------------------------------------------------
-- Show / Hide / Toggle
-------------------------------------------------------------------------------

function TreatiseUI:ShowPanel()
    local frame = CreatePanel();
    PopulatePanel();
    frame:Show();
    SavePanelOpen(true);
end

function TreatiseUI:Hide()
    if (panel) then
        panel:Hide();
    end
    SavePanelOpen(false);
end

function TreatiseUI:Toggle()
    if (panel and panel:IsShown()) then
        self:Hide();
    else
        self:ShowPanel();
    end
end

-------------------------------------------------------------------------------
-- Bank button & event handling
-------------------------------------------------------------------------------

local function IsAccountBankActive()
    if (not BankFrame or not BankFrame.GetActiveBankType) then return false; end
    return BankFrame:GetActiveBankType() == Enum.BankType.Account;
end

local function UpdateButtonVisibility()
    if (not bankButton) then return; end
    if (not Warband.enabled or not IsEnabled()) then
        bankButton:Hide();
        return;
    end
    if (Warband.bankOpen and IsAccountBankActive()) then
        bankButton:Show();
    else
        bankButton:Hide();
    end
end

local function CreateBankButton()
    if (bankButton) then return; end
    if (not BankFrame) then return; end

    bankButton = CreateFrame("Button", "LanternTreatiseBankButton", BankFrame, "UIPanelButtonTemplate");
    bankButton:SetSize(80, 22);
    bankButton:SetFrameStrata("MEDIUM");
    bankButton:SetFrameLevel(510);
    -- Position to the left of the Warehousing button
    local warehousingBtn = _G["LanternWarehousingBankButton"];
    if (warehousingBtn) then
        bankButton:SetPoint("RIGHT", warehousingBtn, "LEFT", -4, 0);
    else
        bankButton:SetPoint("TOPRIGHT", BankFrame, "TOPRIGHT", -60, 0);
    end
    bankButton:SetText(L["WARBAND_TREATISE_UI_BANK_BTN"]);
    bankButton:SetScript("OnClick", function()
        TreatiseUI:Toggle();
    end);
    bankButton:SetScript("OnEnter", function(btn)
        GameTooltip:SetOwner(btn, "ANCHOR_RIGHT");
        GameTooltip:SetText(L["WARBAND_TREATISE_UI_BANK_TOOLTIP"]);
        GameTooltip:AddLine(L["WARBAND_TREATISE_UI_BANK_TOOLTIP_DESC"], 1, 1, 1, true);
        GameTooltip:Show();
    end);
    bankButton:SetScript("OnLeave", function()
        GameTooltip:Hide();
    end);
    bankButton:Hide();
end

-- Hook BankFrame.BankPanel:SetBankType to detect tab switches
local function HookBankPanel()
    if (not BankFrame or not BankFrame.BankPanel) then return; end
    if (BankFrame.BankPanel._lanternTreatiseHooked) then return; end

    hooksecurefunc(BankFrame.BankPanel, "SetBankType", function()
        UpdateButtonVisibility();
        if (IsAccountBankActive() and IsPanelOpenSaved()) then
            TreatiseUI:ShowPanel();
        elseif (not IsAccountBankActive() and panel and panel:IsShown()) then
            panel:Hide();
        end
    end);
    BankFrame.BankPanel._lanternTreatiseHooked = true;
end

-- Bank frame events
local bankEventFrame = CreateFrame("Frame", "LanternTreatise_EventFrame");
bankEventFrame:RegisterEvent("BANKFRAME_OPENED");
bankEventFrame:RegisterEvent("BANKFRAME_CLOSED");
bankEventFrame:SetScript("OnEvent", function(_, event)
    if (event == "BANKFRAME_OPENED") then
        -- Slightly longer delay than Warehousing (0.1s) to ensure its button exists for anchoring
        C_Timer.After(0.2, function()
            if (not Warband.enabled or not IsEnabled()) then return; end
            CreateBankButton();
            HookBankPanel();
            UpdateButtonVisibility();
            -- Restore panel if it was open last time
            if (IsAccountBankActive() and IsPanelOpenSaved()) then
                TreatiseUI:ShowPanel();
            end
        end);
    elseif (event == "BANKFRAME_CLOSED") then
        if (bankButton) then
            bankButton:Hide();
        end
        -- Cancel any in-progress take operation
        if (isTaking) then
            isTaking = false;
            if (takeBtn) then takeBtn:SetEnabled(true); end
        end
        -- Hide panel (without changing saved state)
        if (panel) then
            panel:Hide();
        end
    end
end);
