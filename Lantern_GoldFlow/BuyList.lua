local ADDON_NAME, ns = ...;
local Lantern = _G.Lantern;
if (not Lantern) then return; end

local module = ns.module;
if (not module) then return; end

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local AUCTIONATOR_LIST_NAME = "LanternGold";
local CALLER_ID = "Lantern_GoldFlow";
local REMINDER_FRAME_NAME = "LGF_WarbankReminder";

-------------------------------------------------------------------------------
-- Buy List Helpers
-------------------------------------------------------------------------------

local function GetCurrentRealmBuyList()
    local db = module.db;
    if (not db or not db.crossRealmBuyList) then return nil; end
    local realm = GetRealmName();
    return db.crossRealmBuyList[realm];
end

local function GetAllBuyListItems()
    local db = module.db;
    if (not db or not db.crossRealmBuyList) then return {}; end
    local all = {};
    for realm, items in pairs(db.crossRealmBuyList) do
        for _, item in ipairs(items) do
            item._buyRealm = realm;
            table.insert(all, item);
        end
    end
    return all;
end

local function RemoveFromBuyList(itemID)
    local db = module.db;
    if (not db or not db.crossRealmBuyList) then return; end
    local realm = GetRealmName();
    local list = db.crossRealmBuyList[realm];
    if (not list) then return; end
    for i = #list, 1, -1 do
        if (list[i].itemId == itemID) then
            table.remove(list, i);
        end
    end
end

-------------------------------------------------------------------------------
-- Auctionator Integration
-------------------------------------------------------------------------------

local function HasAuctionator()
    return Auctionator and Auctionator.API and Auctionator.API.v1
        and Auctionator.API.v1.CreateShoppingList;
end

local function CreateAuctionatorList()
    if (not HasAuctionator()) then
        Lantern:Print("Auctionator is not installed.");
        return;
    end

    local buyList = GetCurrentRealmBuyList();
    if (not buyList or #buyList == 0) then
        Lantern:Print("No buy list items for this realm.");
        return;
    end

    local searchStrings = {};
    for _, item in ipairs(buyList) do
        local term = {
            searchString = item.itemName or "",
            isExact = true,
        };
        if (item.maxBuyPrice and item.maxBuyPrice > 0) then
            term.maxPrice = math.floor(item.maxBuyPrice / 10000);
        end
        local ok, str = pcall(Auctionator.API.v1.ConvertToSearchString, CALLER_ID, term);
        if (ok and str) then
            table.insert(searchStrings, str);
        end
    end

    if (#searchStrings == 0) then
        Lantern:Print("No valid items for Auctionator list.");
        return;
    end

    Auctionator.API.v1.CreateShoppingList(CALLER_ID, AUCTIONATOR_LIST_NAME, searchStrings);
    Lantern:Print("Auctionator shopping list updated with " .. #searchStrings .. " items.");
end

module.CreateAuctionatorList = CreateAuctionatorList;
module.MarkItemPurchased = MarkItemPurchased;

-------------------------------------------------------------------------------
-- Warband Bank Reminder Frame
-------------------------------------------------------------------------------

local reminderFrame = nil;

local function FormatGold(copper)
    local gold = math.floor((copper or 0) / 10000);
    if (gold >= 1000000) then
        return string.format("%.1fm g", gold / 1000000);
    elseif (gold >= 1000) then
        return string.format("%.1fk g", gold / 1000);
    end
    return gold .. "g";
end

local function CreateReminderFrame()
    if (reminderFrame) then return reminderFrame; end

    local f = CreateFrame("Frame", REMINDER_FRAME_NAME, UIParent, "BackdropTemplate");
    f:SetSize(280, 100);
    f:SetPoint("TOPLEFT", BankFrame, "TOPRIGHT", 8, 0);
    f:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    });
    f:SetBackdropColor(0.1, 0.1, 0.1, 0.9);
    f:SetBackdropBorderColor(0.6, 0.5, 0.2, 1);
    f:SetFrameStrata("DIALOG");

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
    title:SetPoint("TOPLEFT", 10, -8);
    title:SetText("GoldFlow Buy List");
    title:SetTextColor(0.9, 0.8, 0.3);
    f.title = title;

    local content = f:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    content:SetPoint("TOPLEFT", 10, -28);
    content:SetPoint("RIGHT", f, "RIGHT", -10, 0);
    content:SetJustifyH("LEFT");
    content:SetJustifyV("TOP");
    content:SetSpacing(2);
    f.content = content;

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton");
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", 2, 2);
    close:SetScript("OnClick", function() f:Hide(); end);

    f:Hide();
    reminderFrame = f;
    return f;
end

local function ShowReminderFrame()
    local allItems = GetAllBuyListItems();
    if (#allItems == 0) then
        if (reminderFrame) then reminderFrame:Hide(); end
        return;
    end

    -- Group by sell realm
    local byRealm = {};
    for _, item in ipairs(allItems) do
        local sellRealm = item.sellRealm or "Unknown";
        byRealm[sellRealm] = byRealm[sellRealm] or {};
        table.insert(byRealm[sellRealm], item);
    end

    local lines = {};
    for realm, items in pairs(byRealm) do
        table.insert(lines, "|cffffd100Move to " .. realm .. ":|r");
        for _, item in ipairs(items) do
            local name = item.itemName or ("Item " .. (item.itemId or "?"));
            local sellPrice = item.sellPrice and (" (sell for ~" .. FormatGold(item.sellPrice) .. ")") or "";
            table.insert(lines, "  - " .. name .. sellPrice);
        end
    end

    local f = CreateReminderFrame();
    f.content:SetText(table.concat(lines, "\n"));

    -- Resize to fit content
    local textHeight = f.content:GetStringHeight() or 20;
    f:SetHeight(textHeight + 44);
    f:Show();
end

local function HideReminderFrame()
    if (reminderFrame) then reminderFrame:Hide(); end
end

-------------------------------------------------------------------------------
-- Auto-clear Purchased Items
-------------------------------------------------------------------------------

local function CheckPurchasedItems()
    local buyList = GetCurrentRealmBuyList();
    if (not buyList or #buyList == 0) then return; end

    for i = #buyList, 1, -1 do
        local item = buyList[i];
        if (item.purchased) then
            table.remove(buyList, i);
        end
    end
end

local function MarkItemPurchased(itemID)
    local buyList = GetCurrentRealmBuyList();
    if (not buyList) then return; end
    for _, item in ipairs(buyList) do
        if (item.itemId == itemID) then
            item.purchased = true;
        end
    end
end

-------------------------------------------------------------------------------
-- Event Registration
-------------------------------------------------------------------------------

function module.RegisterBuyListEvents(self)
    -- BANKFRAME_OPENED and AUCTION_HOUSE_SHOW are already registered by
    -- Scanner.lua and Listings.lua. ModuleRegisterEvent only allows one handler
    -- per event per module, so we hook into the existing handlers instead.
    self.addon:ModuleRegisterEvent(self, "BANKFRAME_CLOSED", self.OnBankClosedBuyList);
end

-------------------------------------------------------------------------------
-- Event Handlers (called from existing handlers in Scanner.lua / Listings.lua)
-------------------------------------------------------------------------------

function module:CheckBuyListOnBankOpened()
    C_Timer.After(0.1, function()
        if (not module.enabled) then return; end
        if (BankFrame and BankFrame.GetActiveBankType
            and BankFrame:GetActiveBankType() == Enum.BankType.Account) then
            ShowReminderFrame();
        end
    end);
end

function module:OnBankClosedBuyList()
    HideReminderFrame();
end

function module:CheckBuyListOnAuctionHouseShow()
    local buyList = GetCurrentRealmBuyList();
    if (not buyList or #buyList == 0) then return; end
    if (HasAuctionator()) then
        CreateAuctionatorList();
    end
end

-------------------------------------------------------------------------------
-- Slash Command
-------------------------------------------------------------------------------

-- Register /lg buylist through Lantern's message system
Lantern:RegisterMessage("GOLDFLOW_BUYLIST", function()
    CreateAuctionatorList();
end);

-- Also support direct /gf buylist
SLASH_GOLDFLOW_BUYLIST1 = "/gf";
SlashCmdList["GOLDFLOW_BUYLIST"] = function(msg)
    local cmd = (msg or ""):lower():trim();
    if (cmd == "buylist") then
        CreateAuctionatorList();
    elseif (cmd == "reminder") then
        ShowReminderFrame();
    else
        Lantern:Print("GoldFlow commands: /gf buylist | /gf reminder");
    end
end
