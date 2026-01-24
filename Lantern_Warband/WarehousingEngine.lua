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
local POLL_INTERVAL = 0.05;  -- 50ms polling
local BATCH_SETTLE_DELAY = 0.3;   -- delay after batch moves confirm before re-scanning
local MOVE_TIMEOUT_BASE = 2.0;    -- base timeout per batch
local MOVE_TIMEOUT_PER_ITEM = 0.2; -- extra time per individual move in batch
local MAX_MOVES_PER_BATCH = 10;    -- max cursor moves per batch (prevents mass-locking)
local MAX_OP_RETRIES = 3;          -- max retries per operation before permanent failure

-- Internal state
Engine.state = STATE_IDLE;
Engine.queue = {};
Engine.callbacks = nil;
Engine.eventFrame = nil;
Engine.pollTimer = nil;
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
    Engine.eventFrame:SetScript("OnEvent", function(_, event)
        if (event == "BANKFRAME_CLOSED") then
            Engine:Stop("Bank closed");
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

local function cancelPollTimer()
    if (Engine.pollTimer) then
        Engine.pollTimer:Cancel();
        Engine.pollTimer = nil;
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
    cancelPollTimer();
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

                        -- Find target slot (accounting for already-used slots in this batch)
                        local targetBag, targetSlot, targetAvailable =
                            self:FindTargetSlot(targetStart, targetEnd, op.itemID, self.usedTargetSlots);

                        if (targetBag) then
                            if (targetAvailable < moveCount) then
                                moveCount = targetAvailable;
                            end

                            -- Execute the move: PickupContainerItem for full stacks/single items,
                            -- SplitContainerItem for partial splits only
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

                                    -- Track this pending move
                                    local expectedEndQty = math.max(0, itemInfo.stackCount - moveCount);
                                    table.insert(self.pendingMoves, {
                                        sourceBag = srcSlot.bag,
                                        sourceSlot = srcSlot.slot,
                                        expectedEndQty = expectedEndQty,
                                        opIndex = opIndex,
                                        moveCount = moveCount,
                                    });

                                    -- Mark target slot as used
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
        -- Start polling for move completion
        self:StartPolling();
    elseif (not allOperationsHandled) then
        -- No moves succeeded but operations remain (items locked/unavailable)
        self.stallCount = (self.stallCount or 0) + 1;
        if (self.stallCount >= 3) then
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
            -- Retry after a short delay
            cancelPollTimer();
            self.pollTimer = C_Timer.NewTimer(0.3, function()
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

function Engine:StartPolling()
    cancelPollTimer();
    self.pollTimer = C_Timer.NewTimer(POLL_INTERVAL, function()
        self.pollTimer = nil;
        if (self.state ~= STATE_RUNNING) then return; end
        self:PollMoves();
    end);
end

function Engine:PollMoves()
    if (self.state ~= STATE_RUNNING) then return; end

    -- Check timeout (scales with batch size for non-stacked items)
    local moveTimeout = MOVE_TIMEOUT_BASE + (self.batchMoveCount or 0) * MOVE_TIMEOUT_PER_ITEM;
    local elapsed = GetTime() - self.batchStartTime;
    if (elapsed > moveTimeout) then
        -- Timeout: check each remaining move one last time
        for _, move in ipairs(self.pendingMoves) do
            local info = C_Container.GetContainerItemInfo(move.sourceBag, move.sourceSlot);
            local currentQty = info and info.stackCount or 0;
            if (currentQty <= move.expectedEndQty) then
                -- Move did complete, count it
                self.totalMoved[move.opIndex] = (self.totalMoved[move.opIndex] or 0) + move.moveCount;
                if (self.callbacks and self.callbacks.onMoveComplete) then
                    self.callbacks.onMoveComplete(move.opIndex, move.moveCount);
                end
            end
        end
        self.pendingMoves = {};
        -- Settle before re-scanning to let game state stabilize
        cancelPollTimer();
        self.pollTimer = C_Timer.NewTimer(BATCH_SETTLE_DELAY, function()
            self.pollTimer = nil;
            if (self.state ~= STATE_RUNNING) then return; end
            self:OnBatchComplete();
        end);
        return;
    end

    -- Check each pending move
    local stillPending = {};
    for _, move in ipairs(self.pendingMoves) do
        local info = C_Container.GetContainerItemInfo(move.sourceBag, move.sourceSlot);
        local currentQty = info and info.stackCount or 0;
        local isLocked = info and info.isLocked or false;

        if (currentQty <= move.expectedEndQty and not isLocked) then
            -- Move completed, track amount moved
            self.totalMoved[move.opIndex] = (self.totalMoved[move.opIndex] or 0) + move.moveCount;
            if (self.callbacks and self.callbacks.onMoveComplete) then
                self.callbacks.onMoveComplete(move.opIndex, move.moveCount);
            end
        else
            -- Still pending
            table.insert(stillPending, move);
        end
    end

    self.pendingMoves = stillPending;

    if (#stillPending == 0) then
        -- All moves confirmed; settle before re-scanning to let game state stabilize
        cancelPollTimer();
        self.pollTimer = C_Timer.NewTimer(BATCH_SETTLE_DELAY, function()
            self.pollTimer = nil;
            if (self.state ~= STATE_RUNNING) then return; end
            self:OnBatchComplete();
        end);
    else
        -- Keep polling
        self:StartPolling();
    end
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
        cancelPollTimer();
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
    cancelPollTimer();
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

function Engine:GetState()
    return self.state;
end

function Engine:GetProgress()
    local done = 0;
    for _ in pairs(self.operationsDone) do
        done = done + 1;
    end
    return done, #self.queue;
end

function Engine:IsRunning()
    return self.state == STATE_RUNNING;
end
