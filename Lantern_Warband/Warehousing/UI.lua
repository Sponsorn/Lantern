local Lantern = _G.Lantern;
if (not Lantern or not Lantern.modules or not Lantern.modules.Warband) then return; end
if (not Enum or not Enum.BagIndex or not Enum.BagIndex.AccountBankTab_1) then return; end

local Warband = Lantern.modules.Warband;
local Warehousing = Warband.Warehousing;
local Engine = Warband.WarehousingEngine;

if (not Warehousing or not Engine) then return; end

local WarehousingUI = {};
Warband.WarehousingUI = WarehousingUI;

-- Frame references
local bankButton = nil;
local panel = nil;
local scrollFrame = nil;
local scrollChild = nil;
local progressBar = nil;
local progressText = nil;
local depositBtn = nil;
local restockBtn = nil;
local groupRows = {};

-- State
local selectedGroups = {};
local operationsRunning = false;
local progressResetTimer = nil;

local function GetCharKey()
    return Lantern:GetCharacterKey();
end

local function LoadSelectedGroups()
    local charKey = GetCharKey();
    if (Warband.db and Warband.db.warehousing and Warband.db.warehousing.selectedGroupsByChar and Warband.db.warehousing.selectedGroupsByChar[charKey]) then
        selectedGroups = Warband.db.warehousing.selectedGroupsByChar[charKey];
    else
        selectedGroups = {};
    end
end

local function SaveSelectedGroups()
    if (not Warband.db) then return; end
    if (not Warband.db.warehousing) then
        Warband.db.warehousing = {};
    end
    if (not Warband.db.warehousing.selectedGroupsByChar) then
        Warband.db.warehousing.selectedGroupsByChar = {};
    end
    local charKey = GetCharKey();
    Warband.db.warehousing.selectedGroupsByChar[charKey] = selectedGroups;
end

local function SavePanelOpen(isOpen)
    if (not Warband.db) then return; end
    if (not Warband.db.warehousing) then
        Warband.db.warehousing = {};
    end
    Warband.db.warehousing.panelOpen = isOpen;
end

local function IsPanelOpenSaved()
    return Warband.db and Warband.db.warehousing and Warband.db.warehousing.panelOpen;
end

local function SetActionButtonsEnabled(enabled)
    if (depositBtn) then depositBtn:SetEnabled(enabled); end
    if (restockBtn) then restockBtn:SetEnabled(enabled); end
end

local function UpdateStatus(text)
    if (progressText) then
        progressText:SetText(text or "");
    end
    if (progressBar) then
        if (text and text ~= "") then
            progressBar:Show();
        elseif (not operationsRunning) then
            progressBar:Hide();
        end
    end
end

local function SetProgress(successCount, max, failCount)
    if (not progressBar) then return; end
    progressBar:SetMinMaxValues(0, max or 1);
    progressBar:SetValue(successCount or 0);
    -- Color: green normal, yellow if some failures, red if all failed
    if (failCount and failCount > 0) then
        if ((successCount or 0) == 0) then
            progressBar:SetStatusBarColor(0.8, 0.2, 0.2, 0.9);
        else
            progressBar:SetStatusBarColor(0.9, 0.7, 0.2, 0.9);
        end
    else
        progressBar:SetStatusBarColor(0.4, 0.8, 0.4, 0.9);
    end
    progressBar:Show();
end

local function ResetProgress()
    if (progressResetTimer) then
        progressResetTimer:Cancel();
        progressResetTimer = nil;
    end
    if (not progressBar) then return; end
    progressBar:SetMinMaxValues(0, 1);
    progressBar:SetValue(0);
    progressBar:SetStatusBarColor(0.4, 0.8, 0.4, 0.9);
    progressBar:Hide();
    UpdateStatus("");
end

local function GetSelectedGroupNames()
    local names = {};
    for name, selected in pairs(selectedGroups) do
        if (selected) then
            table.insert(names, name);
        end
    end
    table.sort(names, function(a, b) return a:lower() < b:lower(); end);
    return names;
end

local function RunOperations(operations, actionLabel)
    if (#operations == 0) then
        UpdateStatus("No items to move.");
        Lantern:Print(string.format("Warehousing: %s - nothing to move.", actionLabel));
        return;
    end

    -- Cancel any pending reset timer from a previous run
    if (progressResetTimer) then
        progressResetTimer:Cancel();
        progressResetTimer = nil;
    end

    operationsRunning = true;
    SetActionButtonsEnabled(false);

    -- Calculate total individual items to move for granular progress
    local totalItems = 0;
    for _, op in ipairs(operations) do
        totalItems = totalItems + op.amount;
    end

    local movedItems = 0;
    local failedOps = 0;
    local opMoveCounted = {};  -- per-operation: how many items were counted via onMoveComplete
    local batchSize = 10;  -- matches MAX_MOVES_PER_BATCH in engine

    local function formatStatus(suffix)
        local totalBatches = math.max(1, math.ceil(totalItems / batchSize));
        local currentBatch = math.min(math.floor(movedItems / batchSize) + 1, totalBatches);
        if (movedItems >= totalItems and totalItems > 0) then
            currentBatch = totalBatches;
        end
        local msg = string.format("%s: Batch %d/%d, Items %d/%d",
            actionLabel, currentBatch, totalBatches, movedItems, totalItems);
        if (failedOps > 0) then
            msg = msg .. string.format(" (%d failed)", failedOps);
        end
        if (suffix) then
            msg = msg .. suffix;
        end
        return msg;
    end

    SetProgress(0, totalItems, 0);
    UpdateStatus(formatStatus("..."));

    local started = Engine:Start(operations, {
        onStart = function(count)
            SetProgress(0, totalItems, 0);
            UpdateStatus(formatStatus("..."));
        end,
        onMoveComplete = function(opIndex, moveCount)
            opMoveCounted[opIndex] = (opMoveCounted[opIndex] or 0) + moveCount;
            movedItems = movedItems + moveCount;
            SetProgress(movedItems, totalItems, failedOps);
            UpdateStatus(formatStatus("..."));
        end,
        onOperationComplete = function(index, success, reason)
            if (success) then
                -- Credit any moves not yet counted by onMoveComplete
                -- (happens when secondary check confirms before all polls complete)
                local counted = opMoveCounted[index] or 0;
                local actual = operations[index].amount;
                local uncounted = actual - counted;
                if (uncounted > 0) then
                    movedItems = movedItems + uncounted;
                    opMoveCounted[index] = actual;
                end
            else
                failedOps = failedOps + 1;
                -- Reduce totalItems target by the failed operation's unmoved amount
                local counted = opMoveCounted[index] or 0;
                totalItems = totalItems - (operations[index].amount - counted);
            end
            SetProgress(movedItems, totalItems, failedOps);
            UpdateStatus(formatStatus("..."));
        end,
        onComplete = function(results)
            operationsRunning = false;
            SetActionButtonsEnabled(true);
            SetProgress(movedItems, totalItems, failedOps);
            UpdateStatus(formatStatus());
            -- Auto-hide progress bar after 4 seconds
            progressResetTimer = C_Timer.NewTimer(4, function()
                progressResetTimer = nil;
                ResetProgress();
            end);
        end,
        onStop = function(reason, doneCount, total, results)
            operationsRunning = false;
            SetActionButtonsEnabled(true);
            SetProgress(movedItems, totalItems, failedOps);
            UpdateStatus(string.format("Stopped: %s (%d/%d)", reason, movedItems, totalItems));
            -- Auto-hide progress bar after 4 seconds
            progressResetTimer = C_Timer.NewTimer(4, function()
                progressResetTimer = nil;
                ResetProgress();
            end);
        end,
    });

    if (not started) then
        operationsRunning = false;
        SetActionButtonsEnabled(true);
        ResetProgress();
        UpdateStatus("Failed: bank not accessible.");
    end
end

local function ClearGroupRows()
    for _, row in ipairs(groupRows) do
        row.frame:Hide();
        row.frame:SetParent(nil);
    end
    groupRows = {};
end

local function CreateGroupRow(parent, index, groupName, group)
    local ROW_HEIGHT = 36;
    local ROW_WIDTH = 250;

    local frame = CreateFrame("Frame", nil, parent);
    frame:SetSize(ROW_WIDTH, ROW_HEIGHT);
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -(index - 1) * ROW_HEIGHT);
    frame:EnableMouse(true);

    -- Background
    local bg = frame:CreateTexture(nil, "BACKGROUND");
    bg:SetAllPoints();
    bg:SetColorTexture(1, 1, 1, (index % 2 == 0) and 0.04 or 0.0);

    -- Hover highlight
    local hover = frame:CreateTexture(nil, "HIGHLIGHT");
    hover:SetAllPoints();
    hover:SetColorTexture(1, 1, 1, 0.08);

    -- Checkbox
    local checkbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate");
    checkbox:SetSize(24, 24);
    checkbox:SetPoint("LEFT", frame, "LEFT", 2, 0);
    checkbox:SetChecked(selectedGroups[groupName] ~= false);
    checkbox:SetScript("OnClick", function(self)
        selectedGroups[groupName] = self:GetChecked() and true or false;
        SaveSelectedGroups();
    end);

    -- Click anywhere on the row to toggle
    frame:SetScript("OnMouseUp", function(_, button)
        if (button == "LeftButton") then
            local checked = not checkbox:GetChecked();
            checkbox:SetChecked(checked);
            selectedGroups[groupName] = checked;
            SaveSelectedGroups();
        end
    end);

    -- Group name
    local nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    nameText:SetPoint("LEFT", checkbox, "RIGHT", 2, 4);
    nameText:SetPoint("RIGHT", frame, "RIGHT", -4, 0);
    nameText:SetJustifyH("LEFT");
    nameText:SetText(groupName);

    -- Info line
    local itemCount = 0;
    if (group.items) then
        for _ in pairs(group.items) do
            itemCount = itemCount + 1;
        end
    end

    local modeText = (group.depositMode == "all") and "deposit all" or "keep " .. group.limit;
    local infoText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
    infoText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -1);
    infoText:SetJustifyH("LEFT");
    infoText:SetTextColor(0.7, 0.7, 0.7);
    infoText:SetText(string.format("%d item%s, %s", itemCount, itemCount == 1 and "" or "s", modeText));

    local row = {
        frame = frame,
        checkbox = checkbox,
        groupName = groupName,
    };
    table.insert(groupRows, row);
    return row;
end

local function SavePanelPosition(frame)
    local point, _, relativePoint, x, y = frame:GetPoint(1);
    if (Warband.db and Warband.db.warehousing) then
        Warband.db.warehousing.panelPosition = {
            point = point,
            relativePoint = relativePoint,
            x = x,
            y = y,
        };
    end
end

local function ResetPanelPosition(frame)
    frame:ClearAllPoints();
    frame:SetPoint("TOPRIGHT", BankFrame, "TOPRIGHT", 345, 0);
    if (Warband.db and Warband.db.warehousing) then
        Warband.db.warehousing.panelPosition = nil;
    end
end

local function CreatePanel()
    if (panel) then return panel; end

    local frame = CreateFrame("Frame", "LanternWarehousingPanel", UIParent, "ButtonFrameTemplate");
    frame:SetSize(300, 400);
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
    frame:SetPortraitToAsset("Interface\\Icons\\achievement_guildperk_mobilebanking");
    frame:SetTitle("Warehousing");

    -- Restore saved position or use default
    local saved = Warband.db and Warband.db.warehousing and Warband.db.warehousing.panelPosition;
    if (saved and saved.point) then
        frame:SetPoint(saved.point, UIParent, saved.relativePoint, saved.x, saved.y);
    else
        frame:SetPoint("TOPRIGHT", BankFrame, "TOPRIGHT", 345, 0);
    end

    -- Hook close button to stop engine and save state
    frame.CloseButton:SetScript("OnClick", function()
        if (Engine:IsRunning()) then
            Engine:Stop("Cancelled");
        end
        WarehousingUI:Hide();
    end);

    -- Options (cogwheel) button next to close button
    local optionsBtn = CreateFrame("Button", nil, frame, "UIPanelSquareButton");
    optionsBtn:SetSize(20, 20);
    optionsBtn:SetPoint("RIGHT", frame.CloseButton, "LEFT", 2, 0);
    optionsBtn:SetFrameLevel(1020);
    optionsBtn:SetFrameStrata("MEDIUM");
    -- Hide template icon; use a child frame to guarantee the gear draws on top
    if (optionsBtn.icon) then optionsBtn.icon:Hide(); end
    local iconFrame = CreateFrame("Frame", nil, optionsBtn);
    iconFrame:SetAllPoints();
    iconFrame:SetFrameLevel(optionsBtn:GetFrameLevel() + 1);
    local gearTex = iconFrame:CreateTexture(nil, "ARTWORK");
    gearTex:SetTexture("Interface\\Buttons\\UI-OptionsButton");
    gearTex:SetSize(12, 12);
    gearTex:SetPoint("CENTER");
    optionsBtn:SetScript("OnClick", function()
        local AceConfigDialog = LibStub and LibStub("AceConfigDialog-3.0", true);
        if (AceConfigDialog) then
            AceConfigDialog:Open("module_Warband");
        end
    end);
    optionsBtn:SetScript("OnEnter", function(btn)
        GameTooltip:SetOwner(btn, "ANCHOR_TOP");
        GameTooltip:SetText("Warehousing Options");
        GameTooltip:AddLine("Open Lantern > Warband settings.", 1, 1, 1, true);
        GameTooltip:Show();
    end);
    optionsBtn:SetScript("OnLeave", function() GameTooltip:Hide(); end);

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

    -- Adjust Inset to leave room for bottom buttons
    frame.Inset:ClearAllPoints();
    frame.Inset:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -60);
    frame.Inset:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -6, 56);

    -- Scroll frame inside the Inset content area
    scrollFrame = CreateFrame("ScrollFrame", nil, frame.Inset, "UIPanelScrollFrameTemplate");
    scrollFrame:SetPoint("TOPLEFT", frame.Inset, "TOPLEFT", 6, -4);
    scrollFrame:SetPoint("BOTTOMRIGHT", frame.Inset, "BOTTOMRIGHT", -22, 4);

    scrollChild = CreateFrame("Frame", nil, scrollFrame);
    scrollChild:SetSize(250, 1);
    scrollFrame:SetScrollChild(scrollChild);

    -- Action buttons below the Inset
    depositBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate");
    depositBtn:SetSize(130, 22);
    depositBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 14, 30);
    depositBtn:SetText("< Warbank");
    depositBtn:SetScript("OnClick", function()
        local names = GetSelectedGroupNames();
        if (#names == 0) then
            UpdateStatus("No groups selected.");
            return;
        end
        local allOps = {};
        for _, name in ipairs(names) do
            local ops = Warehousing:ComputeDeposit(name);
            for _, op in ipairs(ops) do
                table.insert(allOps, op);
            end
        end
        RunOperations(allOps, "Deposit");
    end);
    depositBtn:SetScript("OnEnter", function(btn)
        GameTooltip:SetOwner(btn, "ANCHOR_TOP");
        GameTooltip:SetText("Deposit to Warbank");
        GameTooltip:AddLine("Move items from selected groups to warbank.", 1, 1, 1, true);
        GameTooltip:Show();
    end);
    depositBtn:SetScript("OnLeave", function() GameTooltip:Hide(); end);

    restockBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate");
    restockBtn:SetSize(130, 22);
    restockBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -14, 30);
    restockBtn:SetText("> Inventory");
    restockBtn:SetScript("OnClick", function()
        local names = GetSelectedGroupNames();
        if (#names == 0) then
            UpdateStatus("No groups selected.");
            return;
        end
        local allOps = {};
        for _, name in ipairs(names) do
            local ops = Warehousing:ComputeRestock(name);
            for _, op in ipairs(ops) do
                table.insert(allOps, op);
            end
        end
        RunOperations(allOps, "Restock");
    end);
    restockBtn:SetScript("OnEnter", function(btn)
        GameTooltip:SetOwner(btn, "ANCHOR_TOP");
        GameTooltip:SetText("Restock from Warbank");
        GameTooltip:AddLine("Withdraw items for selected groups until limit is met.", 1, 1, 1, true);
        GameTooltip:Show();
    end);
    restockBtn:SetScript("OnLeave", function() GameTooltip:Hide(); end);

    -- Progress bar below buttons (casting bar style)
    progressBar = CreateFrame("StatusBar", nil, frame);
    progressBar:SetSize(272, 14);
    progressBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 14, 14);
    progressBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -14, 14);
    progressBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8");
    progressBar:GetStatusBarTexture():SetDrawLayer("BORDER");
    progressBar:SetStatusBarColor(0.4, 0.8, 0.4, 0.9);
    progressBar:SetMinMaxValues(0, 1);
    progressBar:SetValue(0);
    progressBar:Hide();

    local progressBg = progressBar:CreateTexture(nil, "BACKGROUND", nil, 2);
    progressBg:SetAtlas("ui-castingbar-background");
    progressBg:SetPoint("TOPLEFT", -1, 1);
    progressBg:SetPoint("BOTTOMRIGHT", 1, -1);

    local progressBorder = progressBar:CreateTexture(nil, "ARTWORK", nil, 4);
    progressBorder:SetAtlas("ui-castingbar-frame");
    progressBorder:SetPoint("TOPLEFT", -2, 2);
    progressBorder:SetPoint("BOTTOMRIGHT", 2, -2);

    progressText = progressBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
    progressText:SetAllPoints();
    progressText:SetJustifyH("CENTER");
    progressText:SetJustifyV("MIDDLE");
    progressText:SetText("");

    -- ESC to close
    table.insert(UISpecialFrames, "LanternWarehousingPanel");

    panel = frame;
    return frame;
end

local function PopulatePanel()
    ClearGroupRows();
    LoadSelectedGroups();

    local groups = Warehousing:GetAllGroups();

    -- Sort group names alphabetically
    local sortedNames = {};
    for name, _ in pairs(groups) do
        table.insert(sortedNames, name);
    end
    table.sort(sortedNames, function(a, b) return a:lower() < b:lower(); end);

    if (#sortedNames == 0) then
        local noGroupsText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal");
        noGroupsText:SetPoint("TOP", scrollChild, "TOP", 0, -20);
        noGroupsText:SetText("No groups defined.");
        noGroupsText:SetTextColor(0.7, 0.7, 0.7);

        local hintText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
        hintText:SetPoint("TOP", noGroupsText, "BOTTOM", 0, -8);
        hintText:SetText("Create groups in\nLantern > Warband > Warehousing");
        hintText:SetTextColor(0.5, 0.5, 0.5);
        hintText:SetJustifyH("CENTER");

        -- Store as a pseudo-row for cleanup
        table.insert(groupRows, {
            frame = CreateFrame("Frame", nil, scrollChild),
            _textRefs = { noGroupsText, hintText },
        });
        groupRows[#groupRows].frame:SetSize(1, 1);
        groupRows[#groupRows].frame:SetPoint("TOPLEFT");

        scrollChild:SetHeight(80);
        ResetProgress();
        return;
    end

    -- Default all groups to selected if not explicitly deselected
    for _, name in ipairs(sortedNames) do
        if (selectedGroups[name] == nil) then
            selectedGroups[name] = true;
        end
    end
    SaveSelectedGroups();

    for i, name in ipairs(sortedNames) do
        CreateGroupRow(scrollChild, i, name, groups[name]);
    end

    scrollChild:SetHeight(#sortedNames * 36);

    if (not operationsRunning) then
        ResetProgress();
    end
end

function WarehousingUI:ShowPanel()
    local frame = CreatePanel();
    PopulatePanel();
    frame:Show();
    SavePanelOpen(true);
end

function WarehousingUI:Hide()
    if (panel) then
        panel:Hide();
    end
    SavePanelOpen(false);
end

function WarehousingUI:Toggle()
    if (panel and panel:IsShown()) then
        self:Hide();
    else
        self:ShowPanel();
    end
end

-- Bank button creation and visibility
local function IsAccountBankActive()
    if (not BankFrame or not BankFrame.GetActiveBankType) then return false; end
    return BankFrame:GetActiveBankType() == Enum.BankType.Account;
end

local function UpdateButtonVisibility()
    if (not bankButton) then return; end
    if (not Warband.enabled) then
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

    bankButton = CreateFrame("Button", "LanternWarehousingBankButton", BankFrame, "UIPanelButtonTemplate");
    bankButton:SetSize(100, 22);
    bankButton:SetFrameStrata("MEDIUM");
    bankButton:SetFrameLevel(510);
    bankButton:SetPoint("TOPRIGHT", BankFrame, "TOPRIGHT", -60, 0);
    bankButton:SetText("Warehousing");
    bankButton:SetScript("OnClick", function()
        WarehousingUI:Toggle();
    end);
    bankButton:SetScript("OnEnter", function(btn)
        GameTooltip:SetOwner(btn, "ANCHOR_RIGHT");
        GameTooltip:SetText("Lantern Warehousing");
        GameTooltip:AddLine("Move items between inventory and warbank by group.", 1, 1, 1, true);
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
    if (BankFrame.BankPanel._lanternHooked) then return; end

    hooksecurefunc(BankFrame.BankPanel, "SetBankType", function()
        UpdateButtonVisibility();
        -- Show/hide panel based on tab and saved state
        if (IsAccountBankActive() and IsPanelOpenSaved()) then
            WarehousingUI:ShowPanel();
        elseif (not IsAccountBankActive() and panel and panel:IsShown()) then
            panel:Hide();
        end
    end);
    BankFrame.BankPanel._lanternHooked = true;
end

-- Hook into bank frame events
local bankEventFrame = CreateFrame("Frame");
bankEventFrame:RegisterEvent("BANKFRAME_OPENED");
bankEventFrame:RegisterEvent("BANKFRAME_CLOSED");
bankEventFrame:SetScript("OnEvent", function(_, event)
    if (event == "BANKFRAME_OPENED") then
        C_Timer.After(0.1, function()
            if (not Warband.enabled) then return; end
            CreateBankButton();
            HookBankPanel();
            UpdateButtonVisibility();
            -- Restore panel if it was open last time
            if (IsAccountBankActive() and IsPanelOpenSaved()) then
                WarehousingUI:ShowPanel();
            end
        end);
    elseif (event == "BANKFRAME_CLOSED") then
        if (bankButton) then
            bankButton:Hide();
        end
        -- Stop engine if running
        if (Engine:IsRunning()) then
            Engine:Stop("Bank closed");
        end
        -- Hide panel (without changing saved state)
        if (panel) then
            panel:Hide();
        end
    end
end);
