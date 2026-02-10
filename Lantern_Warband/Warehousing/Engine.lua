local Lantern = _G.Lantern;
if (not Lantern or not Lantern.modules or not Lantern.modules.Warband) then return; end
if (not Enum or not Enum.BagIndex or not Enum.BagIndex.AccountBankTab_1) then return; end

local Warband = Lantern.modules.Warband;

local Engine = {};
Warband.WarehousingEngine = Engine;

-- State constants
local STATE_IDLE = "IDLE";
local STATE_RUNNING = "RUNNING";
local STATE_COMPLETE = "COMPLETE";

-- Bag ranges
local INVENTORY_START = 0;
local INVENTORY_END = 4;
local WARBANK_TAB_START = Enum.BagIndex.AccountBankTab_1;
local WARBANK_TAB_END = Enum.BagIndex.AccountBankTab_5;

-- Timing
local SAFETY_POLL_INTERVAL = 0.5;         -- 500ms fallback poll (events are primary)
local BATCH_SETTLE_DELAY = 0.3;            -- delay after batch moves confirm before re-scanning
local MOVE_TIMEOUT_BASE = 5.0;             -- base timeout per batch (generous for warbank cross-realm)
local MOVE_TIMEOUT_PER_ITEM = 0.2;         -- extra time per individual move in batch
local USE_CONTAINER_CHECK_DELAY = 0.2;     -- detect silent UseContainerItem failures
local MAX_MOVES_PER_BATCH = 10;            -- max cursor moves per batch (prevents mass-locking)
local MAX_OP_RETRIES = 3;                  -- max retries per operation before permanent failure
local MAX_STALLS = 5;                      -- max stall cycles before failing remaining ops

-- Internal state
Engine.state = STATE_IDLE;
Engine.queue = {};
Engine.callbacks = nil;
Engine.eventFrame = nil;
Engine.pollTimer = nil;
Engine.safetyPollTimer = nil;
Engine.useContainerCheckTimer = nil;
Engine.results = {};
Engine.pendingMoves = {};
Engine.batchStartTime = 0;
Engine.operationsDone = {};
Engine.totalMoved = {};
Engine.usedTargetSlots = {};
Engine.batchMoveCount = 0;
Engine.opRetries = {};

local function ensureEventFrame()
    if (Engine.eventFrame) then return; end

    Engine.eventFrame = CreateFrame("Frame");
    Engine.eventFrame:Hide();
    Engine.eventFrame:SetScript("OnEvent", function(_, event, ...)
        if (event == "BANKFRAME_CLOSED") then
            Engine:Stop("Bank closed");
        elseif (event == "ITEM_LOCK_CHANGED") then
            Engine:OnItemLockChanged(...);
        elseif (event == "BAG_UPDATE") then
            Engine:OnBagUpdate(...);
        end
    end);
end

local function registerEvents()
    ensureEventFrame();
    Engine.eventFrame:RegisterEvent("BANKFRAME_CLOSED");
    Engine.eventFrame:Show();
end

local function unregisterEvents()
    if (not Engine.eventFrame) then return; end
    Engine.eventFrame:UnregisterAllEvents();
    Engine.eventFrame:Hide();
end

local function registerMoveEvents()
    if (not Engine.eventFrame) then return; end
    Engine.eventFrame:RegisterEvent("ITEM_LOCK_CHANGED");
    Engine.eventFrame:RegisterEvent("BAG_UPDATE");
end

local function unregisterMoveEvents()
    if (not Engine.eventFrame) then return; end
    Engine.eventFrame:UnregisterEvent("ITEM_LOCK_CHANGED");
    Engine.eventFrame:UnregisterEvent("BAG_UPDATE");
end

local function cancelAllTimers()
    if (Engine.pollTimer) then
        Engine.pollTimer:Cancel();
        Engine.pollTimer = nil;
    end
    if (Engine.safetyPollTimer) then
        Engine.safetyPollTimer:Cancel();
        Engine.safetyPollTimer = nil;
    end
    if (Engine.useContainerCheckTimer) then
        Engine.useContainerCheckTimer:Cancel();
        Engine.useContainerCheckTimer = nil;
    end
end

local function slotKey(bag, slot)
    return bag * 1000 + slot;
end

function Engine:Start(operations, callbacks)
    if (self.state == STATE_RUNNING) then
        return false;
    end

    if (not operations or #operations == 0) then
        return false;
    end

    -- Verify bank is accessible
    if (not C_Bank or not C_Bank.CanUseBank or not C_Bank.CanUseBank(Enum.BankType.Account)) then
        return false;
    end

    self.queue = operations;
    self.callbacks = callbacks or {};
    self.results = {};
    self.operationsDone = {};
    self.totalMoved = {};
    self.opRetries = {};
    self.stallCount = 0;
    self.state = STATE_RUNNING;

    registerEvents();

    if (self.callbacks.onStart) then
        self.callbacks.onStart(#operations);
    end

    self:ProcessBatch();
    return true;
end

function Engine:Stop(reason)
    cancelAllTimers();
    unregisterMoveEvents();
    unregisterEvents();
    ClearCursor();

    local wasRunning = (self.state == STATE_RUNNING);
    self.state = STATE_IDLE;
    self.pendingMoves = {};
    self.totalMoved = {};
    self.usedTargetSlots = {};
    self.batchMoveCount = 0;
    self.opRetries = {};

    if (wasRunning and self.callbacks and self.callbacks.onStop) then
        local doneCount = 0;
        for _ in pairs(self.operationsDone) do
            doneCount = doneCount + 1;
        end
        self.callbacks.onStop(reason or "Stopped", doneCount, #self.queue, self.results);
    end
end

function Engine:FindTargetSlot(targetStart, targetEnd, itemID, usedSlots)
    -- Prefer stacking onto existing partial stacks first
    for bag = targetStart, targetEnd do
        local numSlots = C_Container.GetContainerNumSlots(bag);
        for slot = 1, numSlots do
            local key = slotKey(bag, slot);
            if (not usedSlots[key]) then
                local info = C_Container.GetContainerItemInfo(bag, slot);
                if (info and info.itemID == itemID and not info.isLocked) then
                    local maxStack = C_Item.GetItemMaxStackSizeByID(itemID) or 1;
                    local available = maxStack - info.stackCount;
                    if (available > 0) then
                        return bag, slot, available;
                    end
                end
            end
        end
    end

    -- Fall back to empty slot
    for bag = targetStart, targetEnd do
        local numSlots = C_Container.GetContainerNumSlots(bag);
        for slot = 1, numSlots do
            local key = slotKey(bag, slot);
            if (not usedSlots[key]) then
                local info = C_Container.GetContainerItemInfo(bag, slot);
                if (not info) then
                    return bag, slot, 999;
                end
            end
        end
    end

    return nil, nil, 0;
end

function Engine:ProcessBatch()
    if (self.state ~= STATE_RUNNING) then return; end

    -- Verify bank is still open
    if (not C_Bank or not C_Bank.CanUseBank(Enum.BankType.Account)) then
        self:Stop("Bank no longer accessible");
        return;
    end

    -- Clear cursor before batch
    if (GetCursorInfo()) then
        ClearCursor();
    end

    self.pendingMoves = {};
    self.usedTargetSlots = {};
    self.batchStartTime = GetTime();

    local anyMoveMade = false;
    local allOperationsHandled = true;
    local batchMoves = 0;
    local batchLimitHit = false;
    local anyOpRetrying = false;

    for opIndex, op in ipairs(self.queue) do
        if (batchLimitHit) then
            if (not self.operationsDone[opIndex]) then
                allOperationsHandled = false;
            end
        elseif (self.operationsDone[opIndex]) then
            -- Already completed in a previous batch
        else
            -- Calculate how much is left to move (accounting for previous batches)
            local remaining = op.amount - (self.totalMoved[opIndex] or 0);

            if (remaining <= 0) then
                -- Already moved enough from previous batches
                self.operationsDone[opIndex] = true;
                self.results[opIndex] = true;
                if (self.callbacks and self.callbacks.onOperationComplete) then
                    self.callbacks.onOperationComplete(opIndex, true);
                end
            else
                local targetStart, targetEnd;
                local validSourceStart, validSourceEnd;
                if (op.mode == "deposit") then
                    targetStart, targetEnd = WARBANK_TAB_START, WARBANK_TAB_END;
                    validSourceStart, validSourceEnd = INVENTORY_START, INVENTORY_END;
                else
                    targetStart, targetEnd = INVENTORY_START, INVENTORY_END;
                    validSourceStart, validSourceEnd = WARBANK_TAB_START, WARBANK_TAB_END;
                end

                -- Filter source slots to only those in the valid bag range for this mode
                local slots = {};
                for _, s in ipairs(op.sourceSlots) do
                    if (s.bag >= validSourceStart and s.bag <= validSourceEnd) then
                        table.insert(slots, { bag = s.bag, slot = s.slot, count = s.count });
                    end
                end
                table.sort(slots, function(a, b) return a.count > b.count; end);

                local opHadFailure = false;

                for _, srcSlot in ipairs(slots) do
                    if (remaining <= 0) then break; end
                    if (batchMoves >= MAX_MOVES_PER_BATCH) then
                        batchLimitHit = true;
                        allOperationsHandled = false;
                        break;
                    end

                    local itemInfo = C_Container.GetContainerItemInfo(srcSlot.bag, srcSlot.slot);
                    if (not itemInfo) then
                        -- Slot empty, skip
                    elseif (itemInfo.isLocked) then
                        -- Locked, will retry in next batch
                        allOperationsHandled = false;
                    elseif (itemInfo.itemID ~= op.itemID) then
                        -- Different item, skip
                    else
                        local moveCount = math.min(itemInfo.stackCount, remaining);
                        local isFullStackDeposit = (op.mode == "deposit" and moveCount >= itemInfo.stackCount);

                        if (isFullStackDeposit) then
                            -- Full-stack deposit: use UseContainerItem (server auto-targets)
                            C_Container.UseContainerItem(srcSlot.bag, srcSlot.slot, nil, Enum.BankType.Account, false);

                            anyMoveMade = true;
                            batchMoves = batchMoves + 1;
                            remaining = remaining - moveCount;

                            table.insert(self.pendingMoves, {
                                sourceBag = srcSlot.bag,
                                sourceSlot = srcSlot.slot,
                                expectedEndQty = 0,
                                opIndex = opIndex,
                                moveCount = moveCount,
                                itemID = itemInfo.itemID,
                                method = "use",
                                locked = false,
                            });
                        else
                            -- Partial deposits, all withdrawals: cursor-based
                            local targetBag, targetSlot, targetAvailable =
                                self:FindTargetSlot(targetStart, targetEnd, op.itemID, self.usedTargetSlots);

                            if (targetBag) then
                                if (targetAvailable < moveCount) then
                                    moveCount = targetAvailable;
                                end

                                if (moveCount >= itemInfo.stackCount) then
                                    C_Container.PickupContainerItem(srcSlot.bag, srcSlot.slot);
                                else
                                    C_Container.SplitContainerItem(srcSlot.bag, srcSlot.slot, moveCount);
                                end
                                if (GetCursorInfo() == "item") then
                                    C_Container.PickupContainerItem(targetBag, targetSlot);
                                    if (GetCursorInfo() ~= "item") then
                                        -- Move initiated successfully
                                        anyMoveMade = true;
                                        batchMoves = batchMoves + 1;
                                        remaining = remaining - moveCount;

                                        local expectedEndQty = math.max(0, itemInfo.stackCount - moveCount);
                                        table.insert(self.pendingMoves, {
                                            sourceBag = srcSlot.bag,
                                            sourceSlot = srcSlot.slot,
                                            expectedEndQty = expectedEndQty,
                                            opIndex = opIndex,
                                            moveCount = moveCount,
                                            itemID = itemInfo.itemID,
                                            method = "cursor",
                                            locked = false,
                                        });

                                        self.usedTargetSlots[slotKey(targetBag, targetSlot)] = true;
                                    else
                                        -- Placement rejected, clear cursor
                                        ClearCursor();
                                        opHadFailure = true;
                                        break;
                                    end
                                else
                                    ClearCursor();
                                    -- Source locked mid-split, retry later
                                    allOperationsHandled = false;
                                end
                            else
                                -- No target space available
                                opHadFailure = true;
                                break;
                            end
                        end
                    end
                end

                if (remaining > 0 and not opHadFailure and not batchLimitHit) then
                    allOperationsHandled = false;
                end

                if (opHadFailure and remaining > 0) then
                    ClearCursor();
                    self.opRetries[opIndex] = (self.opRetries[opIndex] or 0) + 1;
                    if (self.opRetries[opIndex] >= MAX_OP_RETRIES) then
                        -- Exceeded max retries, fail permanently
                        self.operationsDone[opIndex] = true;
                        self.results[opIndex] = false;
                        local dest = (op.mode == "deposit") and "warbank" or "inventory";
                        local reason = "No space in " .. dest;
                        Lantern:Print(string.format("Warehousing: Failed to %s %s - %s (after %d retries).",
                            op.mode == "deposit" and "deposit" or "withdraw",
                            op.itemName or ("item " .. tostring(op.itemID)),
                            reason, MAX_OP_RETRIES));
                        if (self.callbacks and self.callbacks.onOperationComplete) then
                            self.callbacks.onOperationComplete(opIndex, false, reason);
                        end
                    else
                        -- Retry in next batch
                        allOperationsHandled = false;
                        anyOpRetrying = true;
                    end
                end
            end
        end
    end

    if (anyMoveMade) then
        -- Reset stall counter on progress
        self.stallCount = 0;
        -- Store batch size for dynamic timeout calculation
        self.batchMoveCount = #self.pendingMoves;
        -- Register events for move confirmation + safety fallback
        registerMoveEvents();
        self:StartSafetyPoll();
        self:ScheduleUseContainerCheck();
    elseif (not allOperationsHandled) then
        -- No moves succeeded but operations remain (items locked/unavailable)
        -- Only count as stall if no operation is actively retrying due to failure
        if (not anyOpRetrying) then
            self.stallCount = (self.stallCount or 0) + 1;
        end
        if (self.stallCount >= MAX_STALLS and not anyOpRetrying) then
            -- Stalled too many times, fail remaining operations
            for opIndex, op in ipairs(self.queue) do
                if (not self.operationsDone[opIndex]) then
                    self.operationsDone[opIndex] = true;
                    self.results[opIndex] = false;
                    Lantern:Print(string.format("Warehousing: Failed to %s %s - items unavailable.",
                        op.mode == "deposit" and "deposit" or "withdraw",
                        op.itemName or ("item " .. tostring(op.itemID))));
                    if (self.callbacks and self.callbacks.onOperationComplete) then
                        self.callbacks.onOperationComplete(opIndex, false, "Items unavailable");
                    end
                end
            end
            self:Complete();
        else
            -- Retry with exponential backoff
            local backoffDelay = BATCH_SETTLE_DELAY * math.pow(2, (self.stallCount or 1) - 1);
            backoffDelay = math.min(backoffDelay, 5.0);
            cancelAllTimers();
            self.pollTimer = C_Timer.NewTimer(backoffDelay, function()
                self.pollTimer = nil;
                if (self.state ~= STATE_RUNNING) then return; end
                self:ProcessBatch();
            end);
        end
    else
        -- All operations handled
        self:Complete();
    end
end

function Engine:OnItemLockChanged(bagOrSlotIndex, slotIndex)
    if (self.state ~= STATE_RUNNING) then return; end
    if (not slotIndex) then return; end  -- Equipment slot, not a bag slot

    for _, move in ipairs(self.pendingMoves) do
        if (move.sourceBag == bagOrSlotIndex and move.sourceSlot == slotIndex) then
            local info = C_Container.GetContainerItemInfo(move.sourceBag, move.sourceSlot);
            if (info and info.isLocked) then
                move.locked = true;
            else
                self:CheckMoveCompletion(move);
            end
        end
    end

    self:CheckAllMovesResolved();
end

function Engine:OnBagUpdate(bagID)
    if (self.state ~= STATE_RUNNING) then return; end

    for _, move in ipairs(self.pendingMoves) do
        if (move.sourceBag == bagID) then
            self:CheckMoveCompletion(move);
        end
    end

    self:CheckAllMovesResolved();
end

function Engine:CheckMoveCompletion(move)
    if (move.confirmed or move.failed) then return; end

    local info = C_Container.GetContainerItemInfo(move.sourceBag, move.sourceSlot);
    local currentQty = info and info.stackCount or 0;
    local isLocked = info and info.isLocked or false;
    local currentItemID = info and info.itemID or nil;

    -- Don't confirm while locked
    if (isLocked) then return; end

    -- Identity check: different item now occupies the slot
    if (info and currentItemID ~= move.itemID) then
        if (move.expectedEndQty == 0) then
            move.confirmed = true;   -- Full stack moved, different item now in slot
        else
            move.failed = true;      -- Partial split lost, wrong item replaced it
        end
        return;
    end

    -- Standard check: unlocked and quantity reduced to expected or below
    if (currentQty <= move.expectedEndQty) then
        move.confirmed = true;
        return;
    end

    -- Was locked before but now unlocked with unchanged quantity = move failed
    if (move.locked and currentQty > move.expectedEndQty) then
        move.failed = true;
        return;
    end
end

function Engine:CheckAllMovesResolved()
    if (self.state ~= STATE_RUNNING) then return; end

    local stillPending = {};
    for _, move in ipairs(self.pendingMoves) do
        if (move.confirmed) then
            self.totalMoved[move.opIndex] = (self.totalMoved[move.opIndex] or 0) + move.moveCount;
            if (self.callbacks and self.callbacks.onMoveComplete) then
                self.callbacks.onMoveComplete(move.opIndex, move.moveCount);
            end
        elseif (move.failed) then
            -- Don't credit; will retry in next batch
        else
            table.insert(stillPending, move);
        end
    end

    self.pendingMoves = stillPending;

    if (#stillPending == 0) then
        -- All resolved; settle then proceed
        cancelAllTimers();
        unregisterMoveEvents();
        self.pollTimer = C_Timer.NewTimer(BATCH_SETTLE_DELAY, function()
            self.pollTimer = nil;
            if (self.state ~= STATE_RUNNING) then return; end
            self:OnBatchComplete();
        end);
    end
end

function Engine:StartSafetyPoll()
    self.safetyPollTimer = C_Timer.NewTicker(SAFETY_POLL_INTERVAL, function()
        if (self.state ~= STATE_RUNNING) then return; end

        -- Check timeout (scales with batch size)
        local moveTimeout = MOVE_TIMEOUT_BASE + (self.batchMoveCount or 0) * MOVE_TIMEOUT_PER_ITEM;
        local elapsed = GetTime() - self.batchStartTime;
        if (elapsed > moveTimeout) then
            -- Force-resolve all remaining moves
            for _, move in ipairs(self.pendingMoves) do
                if (not move.confirmed and not move.failed) then
                    self:CheckMoveCompletion(move);
                    if (not move.confirmed and not move.failed) then
                        local info = C_Container.GetContainerItemInfo(move.sourceBag, move.sourceSlot);
                        local currentQty = info and info.stackCount or 0;
                        if (currentQty <= move.expectedEndQty) then
                            move.confirmed = true;
                        else
                            move.failed = true;
                        end
                    end
                end
            end
            self:CheckAllMovesResolved();
            return;
        end

        -- Normal fallback check
        for _, move in ipairs(self.pendingMoves) do
            self:CheckMoveCompletion(move);
        end
        self:CheckAllMovesResolved();
    end);
end

function Engine:ScheduleUseContainerCheck()
    -- Only schedule if any move uses the UseContainerItem method
    local hasUseMethod = false;
    for _, move in ipairs(self.pendingMoves) do
        if (move.method == "use") then
            hasUseMethod = true;
            break;
        end
    end

    if (not hasUseMethod) then return; end

    self.useContainerCheckTimer = C_Timer.NewTimer(USE_CONTAINER_CHECK_DELAY, function()
        self.useContainerCheckTimer = nil;
        if (self.state ~= STATE_RUNNING) then return; end

        for _, move in ipairs(self.pendingMoves) do
            if (move.method == "use" and not move.confirmed and not move.failed) then
                local info = C_Container.GetContainerItemInfo(move.sourceBag, move.sourceSlot);
                -- Only mark as failed if item is still there, unlocked, same item, unchanged qty
                -- (proves UseContainerItem truly did nothing, e.g. warbank full)
                if (info and not info.isLocked and info.itemID == move.itemID and info.stackCount > move.expectedEndQty) then
                    move.failed = true;
                end
                -- If item is locked (in transit), gone, or qty reduced: move is in progress, leave pending
            end
        end
        self:CheckAllMovesResolved();
    end);
end

function Engine:OnBatchComplete()
    if (self.state ~= STATE_RUNNING) then return; end

    ClearCursor();

    -- Scan inventory once for secondary completion check
    local inventoryItems = Warband.Warehousing:ScanInventory();

    local needsMoreWork = false;

    for opIndex, op in ipairs(self.queue) do
        if (self.operationsDone[opIndex]) then
            -- Already handled
        else
            local moved = self.totalMoved[opIndex] or 0;
            local operationDone = false;

            -- Primary check: moved enough items
            if (moved >= op.amount) then
                operationDone = true;
            end

            -- Secondary check for withdraw: bag count already meets/exceeds limit
            if (not operationDone and op.mode == "withdraw" and op.limit and op.limit > 0) then
                local inventoryData = inventoryItems[op.itemID];
                local inventoryCount = inventoryData and inventoryData.total or 0;
                if (inventoryCount >= op.limit) then
                    operationDone = true;
                end
            end

            -- Secondary check for deposit: bag count at or below limit
            if (not operationDone and op.mode == "deposit") then
                local inventoryData = inventoryItems[op.itemID];
                local inventoryCount = inventoryData and inventoryData.total or 0;
                if (inventoryCount <= (op.limit or 0)) then
                    operationDone = true;
                end
            end

            if (operationDone) then
                self.operationsDone[opIndex] = true;
                self.results[opIndex] = true;
                if (self.callbacks and self.callbacks.onOperationComplete) then
                    self.callbacks.onOperationComplete(opIndex, true);
                end
            else
                needsMoreWork = true;
            end
        end
    end

    if (needsMoreWork) then
        -- Re-scan for fresh source slots before next batch
        cancelAllTimers();
        self.pollTimer = C_Timer.NewTimer(0.15, function()
            self.pollTimer = nil;
            if (self.state ~= STATE_RUNNING) then return; end

            -- Refresh source slots from live scan
            local inventoryItems = Warband.Warehousing:ScanInventory();
            local warbankItems = Warband.Warehousing:ScanWarbank();

            for opIndex, op in ipairs(self.queue) do
                if (not self.operationsDone[opIndex]) then
                    local remaining = op.amount - (self.totalMoved[opIndex] or 0);
                    if (op.mode == "deposit") then
                        local inventoryData = inventoryItems[op.itemID];
                        local allSlots = inventoryData and inventoryData.slots or {};
                        -- Only keep enough slots to cover remaining amount
                        local trimmed = {};
                        local covered = 0;
                        for _, s in ipairs(allSlots) do
                            if (covered >= remaining) then break; end
                            table.insert(trimmed, s);
                            covered = covered + s.count;
                        end
                        op.sourceSlots = trimmed;
                    else
                        local warbankData = warbankItems[op.itemID];
                        local allSlots = warbankData and warbankData.slots or {};
                        local trimmed = {};
                        local covered = 0;
                        for _, s in ipairs(allSlots) do
                            if (covered >= remaining) then break; end
                            table.insert(trimmed, s);
                            covered = covered + s.count;
                        end
                        op.sourceSlots = trimmed;
                    end
                end
            end

            self:ProcessBatch();
        end);
    else
        self:Complete();
    end
end

function Engine:Complete()
    cancelAllTimers();
    unregisterMoveEvents();
    unregisterEvents();

    self.state = STATE_COMPLETE;

    if (self.callbacks and self.callbacks.onComplete) then
        self.callbacks.onComplete(self.results);
    end

    self.state = STATE_IDLE;
    self.pendingMoves = {};
    self.totalMoved = {};
    self.usedTargetSlots = {};
    self.batchMoveCount = 0;
    self.opRetries = {};
end

function Engine:IsRunning()
    return self.state == STATE_RUNNING;
end
