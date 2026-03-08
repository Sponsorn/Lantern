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
local GetInboxText = GetInboxText;
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
    if (not module.Setting("trackTransactions")) then return; end

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
    if (not pendingPost) then return; end

    module.AddTransaction({
        type = "list",
        itemID = pendingPost.itemID,
        quantity = pendingPost.quantity,
        unitPrice = pendingPost.unitPrice,
        buyout = pendingPost.buyout,
    });

    pendingPost = nil;
end

function module:OnCommodityPurchased()
    if (not pendingCommodity) then return; end

    -- Estimate price from commodity search results if available
    local unitPrice = nil;
    if (C_AuctionHouse and C_AuctionHouse.GetCommoditySearchResultInfo) then
        local numResults = C_AuctionHouse.GetNumCommoditySearchResults(pendingCommodity.itemID) or 0;
        if (numResults > 0) then
            local result = C_AuctionHouse.GetCommoditySearchResultInfo(pendingCommodity.itemID, 1);
            if (result) then
                unitPrice = result.unitPrice;
            end
        end
    end

    module.AddTransaction({
        type = "buy",
        itemID = pendingCommodity.itemID,
        quantity = pendingCommodity.quantity,
        unitPrice = unitPrice,
    });

    pendingCommodity = nil;
end

function module:OnAuctionPurchaseCompleted(_, auctionID)
    module.AddTransaction({
        type = "buy",
        auctionID = auctionID,
    });
end

-------------------------------------------------------------------------------
-- Mail Processing
-------------------------------------------------------------------------------

local processedMailKeys = {};

local function ProcessAuctionMail(mailIndex, money)
    -- GetInboxText returns: packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, hasItem, wasRead, wasReturned, textCreated, canReply, isGM, itemTextCreated, isInvoice
    local _, _, _, _, _, _, _, _, _, _, _, _, _, _, isInvoice = GetInboxText(mailIndex);

    if (isInvoice) then
        local invoiceType, itemName, playerName, bid, buyout, deposit, consignment, moneyDelay, etaHour, etaMin, count = GetInboxInvoiceInfo(mailIndex);

        -- Skip temporary seller invoices (pending sales)
        if (invoiceType == "seller_temp_invoice") then return; end

        if (invoiceType == "seller") then
            module.AddTransaction({
                type = "sale",
                itemName = itemName,
                buyer = playerName,
                buyout = buyout,
                deposit = deposit,
                consignment = consignment,
                quantity = count,
            });
        elseif (invoiceType == "buyer") then
            module.AddTransaction({
                type = "buy",
                itemName = itemName,
                seller = playerName,
                buyout = buyout,
                bid = bid,
                quantity = count,
            });
        end
    else
        -- Check for expired/returned auctions: has attachments but no money
        local _, _, _, _, mailMoney, _, _, hasItem = GetInboxHeaderInfo(mailIndex);
        if (hasItem and (not mailMoney or mailMoney == 0)) then
            local _, _, _, subject = GetInboxHeaderInfo(mailIndex);
            module.AddTransaction({
                type = "expired",
                subject = subject,
            });
        end
    end
end

function module:OnMailInboxUpdate()
    if (not module.Setting("trackTransactions")) then return; end

    local numItems = GetInboxNumItems();
    for i = 1, numItems do
        local _, _, sender, subject, money, _, daysLeft = GetInboxHeaderInfo(i);

        -- Build a key to avoid processing the same mail twice per session
        local mailKey = (subject or "") .. ":" .. tostring(money or 0) .. ":" .. tostring(daysLeft or 0);
        if (not processedMailKeys[mailKey]) then
            processedMailKeys[mailKey] = true;
            ProcessAuctionMail(i, money);
        end
    end
end
