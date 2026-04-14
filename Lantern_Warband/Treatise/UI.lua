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
-- Take treatises (delegates to Warehousing Engine for reliable moves)
-------------------------------------------------------------------------------

local function TakeAll()
    if (isTaking) then return; end

    local Engine = Warband.WarehousingEngine;
    if (not Engine) then
        Lantern:Print("Warehousing engine not available.");
        return;
    end

    local status = Treatise:GetTreatiseStatus();
    local inBags = Treatise:GetInventoryTreatises();

    -- Build withdraw operations for the engine
    local operations = {};
    for _, entry in ipairs(status) do
        if (entry.playerHas and not entry.completedThisWeek and not inBags[entry.itemID] and entry.count > 0 and #entry.slots > 0) then
            local sourceSlots = {};
            for _, s in ipairs(entry.slots) do
                table.insert(sourceSlots, { bag = s.bag, slot = s.slot, count = entry.count });
            end
            table.insert(operations, {
                itemID = entry.itemID,
                itemName = entry.name,
                mode = "withdraw",
                amount = 1,
                sourceSlots = sourceSlots,
            });
        end
    end

    if (#operations == 0) then
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

    local started = Engine:Start(operations, {
        onStop = function(reason, doneCount, totalCount, results)
            isTaking = false;
            if (bankButton) then bankButton:SetEnabled(true); end

            -- Collect names of successfully moved items
            local taken = {};
            for i, op in ipairs(operations) do
                if (results and results[i] == true) then
                    table.insert(taken, op.itemName);
                end
            end

            if (#taken > 0) then
                local count = #taken;
                local nameStr = table.concat(taken, ", ");
                Lantern:Print(string.format(L["WARBAND_TREATISE_MSG_TOOK"], count, count == 1 and "" or "s", nameStr));
            elseif (reason) then
                Lantern:Print(reason);
            end
        end,
    });

    if (not started) then
        isTaking = false;
        if (bankButton) then bankButton:SetEnabled(true); end
        Lantern:Print("Could not start — warehousing engine may be busy.");
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
        -- Engine handles its own BANKFRAME_CLOSED cleanup;
        -- just reset our button state
        if (isTaking) then
            isTaking = false;
            if (bankButton) then bankButton:SetEnabled(true); end
        end
    end
end);
