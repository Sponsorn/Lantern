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
    if (not module.Setting("trackListings")) then return; end

    self.addon:ModuleRegisterEvent(self, "AUCTION_HOUSE_SHOW", self.OnAuctionHouseShow);
    self.addon:ModuleRegisterEvent(self, "OWNED_AUCTIONS_UPDATED", self.OnOwnedAuctionsUpdated);
end

-------------------------------------------------------------------------------
-- Event Handlers
-------------------------------------------------------------------------------

function module:OnAuctionHouseShow()
    if (C_AuctionHouse and C_AuctionHouse.QueryOwnedAuctions) then
        C_AuctionHouse.QueryOwnedAuctions({});
    end
end

function module:OnOwnedAuctionsUpdated()
    if (not C_AuctionHouse or not C_AuctionHouse.GetNumOwnedAuctions) then return; end

    local char = module.EnsureCharacter();
    if (not char) then return; end

    local listings = {};
    local numAuctions = C_AuctionHouse.GetNumOwnedAuctions();

    for i = 1, numAuctions do
        local auction = C_AuctionHouse.GetOwnedAuctionInfo(i);
        if (auction) then
            local itemId = nil;
            if (auction.itemKey and auction.itemKey.itemID) then
                itemId = auction.itemKey.itemID;
            end

            table.insert(listings, {
                itemId = itemId,
                quantity = auction.quantity or 1,
                buyoutPerUnit = auction.buyoutAmount and auction.quantity and auction.quantity > 0
                    and math.floor(auction.buyoutAmount / auction.quantity) or auction.buyoutAmount,
                timeLeftIndex = auction.timeLeftSeconds and nil or auction.timeLeft,
                listedAt = auction.timeLeftSeconds
                    and (time() - (TIME_LEFT_DURATIONS[auction.timeLeft] or 172800) + (auction.timeLeftSeconds or 0))
                    or time(),
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
