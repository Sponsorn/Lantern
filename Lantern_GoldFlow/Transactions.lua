local ADDON_NAME, ns = ...;
local Lantern = _G.Lantern;
if (not Lantern) then return; end

local module = ns.module;
if (not module) then return; end

-------------------------------------------------------------------------------
-- Local references
-------------------------------------------------------------------------------

local C_AuctionHouse = C_AuctionHouse;
local GetInboxNumItems = GetInboxNumItems;
local GetInboxHeaderInfo = GetInboxHeaderInfo;
local GetInboxInvoiceInfo = GetInboxInvoiceInfo;

-------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------

local pendingCommodity = nil;
local pendingPost = nil;

-------------------------------------------------------------------------------
-- Registration
-------------------------------------------------------------------------------

function module.RegisterTransactionEvents(self)
    self.addon:ModuleRegisterEvent(self, "COMMODITY_PURCHASE_SUCCEEDED", self.OnCommodityPurchased);
    self.addon:ModuleRegisterEvent(self, "AUCTION_HOUSE_PURCHASE_COMPLETED", self.OnAuctionPurchaseCompleted);
    self.addon:ModuleRegisterEvent(self, "AUCTION_HOUSE_AUCTION_CREATED", self.OnAuctionCreated);
    self.addon:ModuleRegisterEvent(self, "MAIL_INBOX_UPDATE", self.OnMailInboxUpdate);

    -- Hook commodity purchase confirmation
    if (not module._commodityHookInstalled and C_AuctionHouse and C_AuctionHouse.ConfirmCommoditiesPurchase) then
        hooksecurefunc(C_AuctionHouse, "ConfirmCommoditiesPurchase", function(itemID, quantity)
            pendingCommodity = {
                itemID = itemID,
                quantity = quantity,
            };
        end);
        module._commodityHookInstalled = true;
    end

    -- Hook posting
    if (not module._postHooksInstalled and C_AuctionHouse) then
        if (C_AuctionHouse.PostCommodity) then
            hooksecurefunc(C_AuctionHouse, "PostCommodity", function(item, duration, quantity, unitPrice)
                local ok, itemID = pcall(C_Item.GetItemID, item);
                pendingPost = {
                    itemID = ok and itemID or nil,
                    quantity = quantity,
                    unitPrice = unitPrice,
                };
            end);
        end

        if (C_AuctionHouse.PostItem) then
            hooksecurefunc(C_AuctionHouse, "PostItem", function(item, duration, quantity, bid, buyout)
                local ok, itemID = pcall(C_Item.GetItemID, item);
                pendingPost = {
                    itemID = ok and itemID or nil,
                    quantity = quantity,
                    buyout = buyout,
                };
            end);
        end

        module._postHooksInstalled = true;
    end
end

-------------------------------------------------------------------------------
-- AH Event Handlers
-------------------------------------------------------------------------------

function module:OnAuctionCreated()
    if (not module.Setting("trackTransactions")) then return; end
    if (not pendingPost) then return; end

    local p = pendingPost;
    local itemName = "Unknown";
    if (p.itemID and p.itemID > 0) then
        itemName = C_Item.GetItemNameByID(p.itemID) or "Unknown";
    end

    module.AddTransaction({
        type = "list",
        itemId = p.itemID or 0,
        itemName = itemName,
        quantity = p.quantity or 1,
        pricePerUnit = p.unitPrice or 0,
        totalPrice = (p.unitPrice or 0) * (p.quantity or 1),
    });

    pendingPost = nil;
end

function module:OnCommodityPurchased()
    if (not module.Setting("trackTransactions")) then return; end
    if (not pendingCommodity) then return; end

    local itemID = pendingCommodity.itemID;
    local quantity = pendingCommodity.quantity;
    pendingCommodity = nil;

    local itemName = C_Item.GetItemNameByID(itemID) or "Unknown";
    local unitPrice = 0;
    local totalPrice = 0;

    if (C_AuctionHouse.GetNumCommoditySearchResults) then
        local numResults = C_AuctionHouse.GetNumCommoditySearchResults(itemID) or 0;
        local remaining = quantity;
        for i = 1, numResults do
            local result = C_AuctionHouse.GetCommoditySearchResultInfo(itemID, i);
            if (result and remaining > 0) then
                local take = math.min(remaining, result.quantity);
                totalPrice = totalPrice + (take * result.unitPrice);
                remaining = remaining - take;
                if (remaining <= 0) then break; end
            end
        end
        if (quantity > 0) then
            unitPrice = math.floor(totalPrice / quantity);
        end
    end

    module.AddTransaction({
        type = "buy",
        itemId = itemID,
        itemName = itemName,
        quantity = quantity,
        pricePerUnit = unitPrice,
        totalPrice = totalPrice,
    });
end

function module:OnAuctionPurchaseCompleted(_, auctionID)
    if (not module.Setting("trackTransactions")) then return; end

    module.AddTransaction({
        type = "buy",
        itemId = 0,
        itemName = "Auction #" .. tostring(auctionID),
        quantity = 1,
        pricePerUnit = 0,
        totalPrice = 0,
    });
end

-------------------------------------------------------------------------------
-- Mail Processing
-------------------------------------------------------------------------------

function module:OnMailInboxUpdate()
    if (not module.Setting("trackTransactions")) then return; end

    local numItems = GetInboxNumItems();
    if (not numItems or numItems == 0) then return; end

    if (not module._processedMails) then
        module._processedMails = {};
    end

    for i = 1, numItems do
        local _, _, sender, subject, money, _, daysLeft = GetInboxHeaderInfo(i);
        if (subject) then
            local mailKey = format("%s:%d:%.2f", subject, money or 0, daysLeft or 0);
            if (not module._processedMails[mailKey]) then
                module._processedMails[mailKey] = true;
                module:ProcessAuctionMail(i, money);
            end
        end
    end
end

function module:ProcessAuctionMail(mailIndex, money)
    -- Try GetInboxInvoiceInfo directly — returns nil for non-AH mail, no side effects
    local invoiceType, itemName, playerName, bid, buyout, deposit, consignment, moneyDelay, etaHour, etaMin, count = GetInboxInvoiceInfo(mailIndex);

    if (invoiceType) then
        if (invoiceType == "seller_temp_invoice") then return; end

        if (invoiceType == "seller") then
            local qty = count or 1;
            local total = buyout or 0;
            local perUnit = (qty > 0) and math.floor(total / qty) or 0;

            module.AddTransaction({
                type = "sale",
                itemId = 0,
                itemName = itemName or "Unknown",
                quantity = qty,
                pricePerUnit = perUnit,
                totalPrice = total,
                deposit = deposit or 0,
                consignment = consignment or 0,
            });
        elseif (invoiceType == "buyer") then
            local qty = count or 1;
            local total = buyout or bid or 0;
            local perUnit = (qty > 0) and math.floor(total / qty) or 0;

            module.AddTransaction({
                type = "buy",
                itemId = 0,
                itemName = itemName or "Unknown",
                quantity = qty,
                pricePerUnit = perUnit,
                totalPrice = total,
            });
        end
        return;
    end

    -- Non-invoice mail with attachments and no money = likely expired/returned auction
    local _, _, _, _, _, _, _, numAttachments = GetInboxHeaderInfo(mailIndex);
    if (numAttachments and numAttachments > 0 and (not money or money == 0)) then
        local _, _, _, subject = GetInboxHeaderInfo(mailIndex);
        module.AddTransaction({
            type = "expired",
            itemId = 0,
            itemName = subject or "Unknown",
            quantity = numAttachments,
            pricePerUnit = 0,
            totalPrice = 0,
        });
    end
end
