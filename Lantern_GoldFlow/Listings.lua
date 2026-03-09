local ADDON_NAME, ns = ...;
local Lantern = _G.Lantern;
if (not Lantern) then return; end

local module = ns.module;
if (not module) then return; end

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local TIME_LEFT_DURATIONS = {
    [0] = 1800,    -- 30 minutes
    [1] = 7200,    -- 2 hours
    [2] = 43200,   -- 12 hours
    [3] = 172800,  -- 48 hours
};

-------------------------------------------------------------------------------
-- Registration
-------------------------------------------------------------------------------

function module.RegisterListingEvents(self)
    self.addon:ModuleRegisterEvent(self, "AUCTION_HOUSE_SHOW", self.OnAuctionHouseShow);
    self.addon:ModuleRegisterEvent(self, "OWNED_AUCTIONS_UPDATED", self.OnOwnedAuctionsUpdated);
end

-------------------------------------------------------------------------------
-- Event Handlers
-------------------------------------------------------------------------------

function module:OnAuctionHouseShow()
    if (module.Setting("trackListings")) then
        if (C_AuctionHouse and C_AuctionHouse.QueryOwnedAuctions) then
            C_AuctionHouse.QueryOwnedAuctions({});
        end
    end
    if (self.CheckBuyListOnAuctionHouseShow) then
        self:CheckBuyListOnAuctionHouseShow();
    end
end

function module:OnOwnedAuctionsUpdated()
    if (not module.Setting("trackListings")) then return; end
    if (not C_AuctionHouse or not C_AuctionHouse.GetNumOwnedAuctions) then return; end

    local char = module.EnsureCharacter();
    if (not char) then return; end

    local listings = {};
    local numAuctions = C_AuctionHouse.GetNumOwnedAuctions();

    for i = 1, numAuctions do
        local auction = C_AuctionHouse.GetOwnedAuctionInfo(i);
        if (auction) then
            local itemID = auction.itemKey and auction.itemKey.itemID or 0;
            local quantity = auction.quantity or 1;
            local buyoutAmount = auction.buyoutAmount or 0;
            local buyoutPerUnit = (quantity > 0) and math.floor(buyoutAmount / quantity) or 0;
            local timeLeftSeconds = auction.timeLeftSeconds or 0;
            local timeLeftIndex = auction.timeLeft or 3;

            local totalDuration = TIME_LEFT_DURATIONS[timeLeftIndex] or 172800;
            local listedAt = GetServerTime() - (totalDuration - timeLeftSeconds);

            table.insert(listings, {
                itemId = itemID,
                quantity = quantity,
                buyoutPerUnit = buyoutPerUnit,
                timeLeftIndex = timeLeftIndex,
                listedAt = listedAt,
            });
        end
    end

    char.listings = listings;
    module.UpdateTimestamp();
end

-------------------------------------------------------------------------------
-- Register module with Lantern core
-------------------------------------------------------------------------------

Lantern:RegisterModule(module);
