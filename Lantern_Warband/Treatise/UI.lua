local L = select(2, ...).L;
local Lantern = _G.Lantern;
if (not Lantern or not Lantern.modules or not Lantern.modules.Warband) then return; end
if (not Enum or not Enum.BagIndex or not Enum.BagIndex.AccountBankTab_1) then return; end

local Warband = Lantern.modules.Warband;
local Treatise = Warband.Treatise;

if (not Treatise) then return; end

-------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------

local bankButton = nil;
local isTaking = false;

local function IsEnabled()
    return Warband.db and Warband.db.treatise and Warband.db.treatise.enabled;
end

-------------------------------------------------------------------------------
-- Take treatises
-------------------------------------------------------------------------------

local TAKE_TIMEOUT = 5;   -- seconds before giving up on a single item
local MAX_RETRIES = 3;    -- max retries per item if locked

local takeState = nil;    -- current take operation state
local takeEventFrame = CreateFrame("Frame", "LanternTreatise_TakeFrame");

local function finishTake(message)
    isTaking = false;
    if (bankButton) then bankButton:SetEnabled(true); end
    takeEventFrame:UnregisterEvent("ITEM_LOCK_CHANGED");
    if (takeState and takeState.timeoutTicker) then
        takeState.timeoutTicker:Cancel();
    end
    if (message) then
        Lantern:Print(message);
    end
    takeState = nil;
end

local function reportTaken(taken)
    if (#taken > 0) then
        local count = #taken;
        local names = table.concat(taken, ", ");
        Lantern:Print(string.format(L["WARBAND_TREATISE_MSG_TOOK"], count, count == 1 and "" or "s", names));
    end
end

local takeNext;  -- forward declaration

local function attemptPickup()
    if (not takeState or not isTaking) then return; end

    local entry = takeState.toTake[takeState.index];
    local firstSlot = entry.slots[1];

    -- Check if item is locked (still mid-operation)
    local info = C_Container.GetContainerItemInfo(firstSlot.bag, firstSlot.slot);
    if (not info) then
        -- Item gone (already moved), skip to next
        takeState.index = takeState.index + 1;
        takeNext();
        return;
    end
    if (info.isLocked) then
        takeState.retries = takeState.retries + 1;
        if (takeState.retries > MAX_RETRIES) then
            -- Skip this item, move on
            takeState.index = takeState.index + 1;
            takeNext();
        end
        -- Otherwise wait for ITEM_LOCK_CHANGED to retry
        return;
    end

    -- Find free bag slot
    local freeBag, freeSlot = Treatise:FindFreeBagSlot();
    if (not freeBag) then
        finishTake(L["WARBAND_TREATISE_UI_NO_BAG_SPACE"]);
        reportTaken(takeState.taken);
        return;
    end

    -- Set up state to wait for completion
    takeState.phase = "picking";
    takeState.srcBag = firstSlot.bag;
    takeState.srcSlot = firstSlot.slot;
    takeState.dstBag = freeBag;
    takeState.dstSlot = freeSlot;

    -- Pick up or split
    if (info.stackCount > 1) then
        C_Container.SplitContainerItem(firstSlot.bag, firstSlot.slot, 1);
    else
        C_Container.PickupContainerItem(firstSlot.bag, firstSlot.slot);
    end

    -- For single stacks, the cursor may be ready immediately
    if (GetCursorInfo() == "item") then
        takeState.phase = "placing";
        C_Container.PickupContainerItem(freeBag, freeSlot);
        table.insert(takeState.taken, entry.name);
        -- Wait for ITEM_LOCK_CHANGED to confirm placement before next
        return;
    end
    -- Otherwise wait for ITEM_LOCK_CHANGED (split is async for warbank)
end

takeNext = function()
    if (not takeState or not isTaking) then return; end

    if (takeState.index > #takeState.toTake) then
        local taken = takeState.taken;
        finishTake(nil);
        reportTaken(taken);
        return;
    end

    takeState.retries = 0;
    takeState.phase = "idle";

    -- Reset timeout for this item
    if (takeState.timeoutTicker) then
        takeState.timeoutTicker:Cancel();
    end
    takeState.timeoutTicker = C_Timer.NewTimer(TAKE_TIMEOUT, function()
        if (not takeState or not isTaking) then return; end
        -- Timed out on this item, skip it
        ClearCursor();
        takeState.index = takeState.index + 1;
        takeNext();
    end);

    attemptPickup();
end

takeEventFrame:SetScript("OnEvent", function(_, event)
    if (event ~= "ITEM_LOCK_CHANGED" or not takeState or not isTaking) then return; end

    if (takeState.phase == "picking") then
        -- Only act when cursor actually has the item (ignore stale events)
        if (GetCursorInfo() ~= "item") then return; end
        takeState.phase = "placing";
        C_Container.PickupContainerItem(takeState.dstBag, takeState.dstSlot);
        local entry = takeState.toTake[takeState.index];
        table.insert(takeState.taken, entry.name);
        -- Wait for cursor to clear confirming placement
    elseif (takeState.phase == "placing") then
        -- Only advance when cursor is clear (item actually placed)
        if (GetCursorInfo() ~= nil) then return; end
        if (takeState.timeoutTicker) then
            takeState.timeoutTicker:Cancel();
        end
        takeState.index = takeState.index + 1;
        takeState.phase = "idle";
        -- Small delay to let the UI settle
        C_Timer.After(0.1, takeNext);
    end
end);

local function TakeAll()
    if (isTaking) then return; end

    local status = Treatise:GetTreatiseStatus();
    local inBags = Treatise:GetInventoryTreatises();

    -- Build list of items to take
    local toTake = {};
    for _, entry in ipairs(status) do
        if (entry.playerHas and not entry.completedThisWeek and not inBags[entry.itemID] and entry.count > 0 and #entry.slots > 0) then
            table.insert(toTake, entry);
        end
    end

    if (#toTake == 0) then
        local allDone = true;
        for _, entry in ipairs(status) do
            if (entry.playerHas and not entry.completedThisWeek) then
                allDone = false;
                break;
            end
        end
        Lantern:Print(allDone and L["WARBAND_TREATISE_MSG_ALL_DONE"] or L["WARBAND_TREATISE_MSG_TOOK_NONE"]);
        return;
    end

    isTaking = true;
    if (bankButton) then bankButton:SetEnabled(false); end

    takeState = {
        toTake = toTake,
        taken = {},
        index = 1,
        retries = 0,
        phase = "idle",
        timeoutTicker = nil,
    };

    takeEventFrame:RegisterEvent("ITEM_LOCK_CHANGED");
    takeNext();
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
        TakeAll();
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

local function HookBankPanel()
    if (not BankFrame or not BankFrame.BankPanel) then return; end
    if (BankFrame.BankPanel._lanternTreatiseHooked) then return; end

    hooksecurefunc(BankFrame.BankPanel, "SetBankType", function()
        UpdateButtonVisibility();
    end);
    BankFrame.BankPanel._lanternTreatiseHooked = true;
end

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
        end);
    elseif (event == "BANKFRAME_CLOSED") then
        if (bankButton) then
            bankButton:Hide();
        end
        if (isTaking) then
            ClearCursor();
            local taken = takeState and takeState.taken or {};
            finishTake(nil);
            reportTaken(taken);
        end
    end
end);
