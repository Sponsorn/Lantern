local ADDON_NAME, ns = ...;
local L = ns.L;

-------------------------------------------------------------------------------
-- Sender name filter (decorates player names in chat with tipper icons)
-------------------------------------------------------------------------------

local function SenderNameFilter(event, decoratedPlayerName, ...)
    local db = _G.LanternCraftingOrdersDB or {};
    if (not db.tipperEnabled or not db.chatDecoration) then return decoratedPlayerName; end

    -- Only decorate whispers and trade chat
    if (event ~= "CHAT_MSG_WHISPER" and event ~= "CHAT_MSG_WHISPER_INFORM"
        and event ~= "CHAT_MSG_CHANNEL") then
        return decoratedPlayerName;
    end

    -- Varargs layout: text, senderName, languageName, channelName, playerName2,
    --   specialFlags, zoneChannelID, channelIndex, channelBaseName, ...
    local text, senderName, _, _, _, _, _, _, channelBaseName = ...;

    -- For CHAT_MSG_CHANNEL, only decorate trade chat
    if (event == "CHAT_MSG_CHANNEL") then
        if (not channelBaseName or channelBaseName ~= "Trade") then
            return decoratedPlayerName;
        end
    end

    -- Use senderName (raw undecorated name) for cache lookup
    if (not senderName or not ns.CustomerCache) then return decoratedPlayerName; end
    local info = ns.CustomerCache.GetCustomerInfo(senderName);
    if (not info or not info.rating) then return decoratedPlayerName; end
    if (info.rating == "none") then return decoratedPlayerName; end
    if (info.rating == "neutral" and not db.showNeutralTipper) then return decoratedPlayerName; end

    -- Prepend icon
    if (not ns.TipperRating) then return decoratedPlayerName; end
    local _, chatFontSize = ChatFrame1:GetFont();
    local markup = ns.TipperRating.GetTipperMarkup(info.rating, db, chatFontSize);
    return markup .. " " .. decoratedPlayerName;
end

-------------------------------------------------------------------------------
-- Right-click menu — registered at load time (permanent, checks settings in callback)
-------------------------------------------------------------------------------

local MENU_TAGS = { "MENU_UNIT_FRIEND", "MENU_UNIT_PLAYER" };

for _, tag in ipairs(MENU_TAGS) do
    Menu.ModifyMenu(tag, function(owner, rootDescription, contextData)
        local db = _G.LanternCraftingOrdersDB or {};
        if (not db.tipperEnabled) then return; end
        if (db.chatMenuRestOnly and not IsResting()) then return; end

        local playerName = contextData.chatTarget or contextData.name;
        if (not playerName or playerName == "") then return; end
        -- Strip realm suffix for same-realm players (matches order storage format)
        playerName = Ambiguate(playerName, "short");

        rootDescription:CreateDivider();
        rootDescription:CreateTitle("Lantern: Crafting Orders");
        rootDescription:CreateButton(L["CO_CUSTOMER_INFO"] or "Customer Info", function()
            if (ns.CustomerInfoFrame) then
                ns.CustomerInfoFrame.ShowForCustomer(playerName);
            end
        end);
    end);
end

-------------------------------------------------------------------------------
-- Init (called from CraftingOrders:OnEnable — registers sender name filter)
-------------------------------------------------------------------------------

local senderFilterRegistered = false;

local function Init()
    local db = _G.LanternCraftingOrdersDB or {};
    if (not db.tipperEnabled) then return; end

    -- Sender name filter — register once, callback checks db.chatDecoration dynamically
    if (not senderFilterRegistered and ChatFrameUtil and ChatFrameUtil.AddSenderNameFilter) then
        ChatFrameUtil.AddSenderNameFilter(SenderNameFilter);
        senderFilterRegistered = true;
    end
end

-------------------------------------------------------------------------------
-- Export
-------------------------------------------------------------------------------

ns.ChatIntegration = {
    Init = Init,
};
