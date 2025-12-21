local ADDON_NAME = ...;
local Lantern = _G.Lantern;

-- Abort early if the core addon is not available.
if (not Lantern) then return; end

local LibSink = LibStub and LibStub("LibSink-2.0", true);

local CraftingOrders = Lantern:NewModule("CraftingOrders", {
    title = "Crafting Orders",
    desc = "Notify about guild crafting order placements and completions.",
});

local DEFAULTS = {
    postPlacement = true,
    postFulfill = true,
    notifyPersonal = true,
    debug = false,
};

local function ensureDB(self)
    self.db = self.addon.db.craftingOrders or {};
    self.addon.db.craftingOrders = self.db;
    for k, v in pairs(DEFAULTS) do
        if (self.db[k] == nil) then
            self.db[k] = v;
        end
    end
    self.db.sink = self.db.sink or {};
    if (LibSink) then
        LibSink:Embed(self);
        self:SetSinkStorage(self.db.sink);
        if (self.db.sink.sink20OutputSink == nil) then
            self.db.sink.sink20OutputSink = "RaidWarning";
        end
    end
end

function CraftingOrders:IsEnabled()
    return self.enabled;
end

local function stripRealm(name)
    if (type(name) ~= "string") then return name; end
    return name:gsub("%-[^%-]+$", "");
end

local function buildMessage(prefix, itemLink, who, tipGold, missingMats)
    local parts = { prefix, itemLink or "Unknown item" };
    if (who and who ~= "") then
        table.insert(parts, " for " .. who);
    end
    if (tipGold and tipGold > 0) then
        table.insert(parts, ", commission: " .. tostring(tipGold) .. "g");
    end
    if (missingMats) then
        table.insert(parts, " (missing mats)");
    end
    return table.concat(parts, "");
end

function CraftingOrders:OutputMessage(msg)
    if (self.db and self.db.debug) then
        Lantern:Print("Crafting Orders: " .. tostring(msg));
        return;
    end
    if (self.Pour) then
        self:Pour(msg);
        return;
    end
    if (SendChatMessage) then
        SendChatMessage(msg, "GUILD");
    else
        Lantern:Print("Crafting Orders: " .. tostring(msg));
    end
end

local function getOrderInfoByID(orderID)
    if (not orderID) then return nil; end
    if (C_CraftingOrders and C_CraftingOrders.GetOrderInfo) then
        local info = C_CraftingOrders.GetOrderInfo(orderID);
        if (info) then return info; end
    end
    local ordersPage = ProfessionsFrame and ProfessionsFrame.OrdersPage;
    local view = ordersPage and ordersPage.OrderView;
    if (view and view.order and view.order.orderID == orderID) then
        return view.order;
    end
    return nil;
end

local function isGuildOrderType(orderType)
    if (orderType == nil) then return false; end
    if (Enum and Enum.CraftingOrderType) then
        return orderType == Enum.CraftingOrderType.Guild;
    end
    return orderType == 2;
end

local function formatPersonalOrderMessage()
    return "New personal crafting order received.";
end

local function getPersonalOrderCount()
    if (not C_CraftingOrders) then return nil; end
    if (C_CraftingOrders.GetPersonalOrderCounts) then
        local count, _ = C_CraftingOrders.GetPersonalOrderCounts();
        if (type(count) == "number") then
            return count;
        end
        if (type(count) == "table") then
            return count.total or count.numOrders or count.count or count.open or count[1];
        end
    end
    if (C_CraftingOrders.GetPersonalOrders) then
        local orders = C_CraftingOrders.GetPersonalOrders();
        if (type(orders) == "table") then
            return #orders;
        end
    end
    return nil;
end

function CraftingOrders:HandlePlacement()
    if (not self.db or not self.db.postPlacement) then return; end
    local frame = ProfessionsCustomerOrdersFrame;
    if (not frame or not frame.Form) then return; end
    local form = frame.Form;
    if (not form.order or not form.transaction or not form.PaymentContainer) then return; end

    local isGuild = isGuildOrderType(form.order.orderType);
    if (not isGuild) then
        local dropdown = form.OrderRecipientDropdown;
        local text = dropdown and dropdown.GetText and dropdown:GetText() or "";
        if (text ~= "Guild Order") then
            return;
        end
    end

    local recipeID = form.transaction.GetRecipeID and form.transaction:GetRecipeID() or nil;
    local reagentInfo = form.transaction.CreateCraftingReagentInfoTbl
        and form.transaction:CreateCraftingReagentInfoTbl() or nil;
    local out = (C_TradeSkillUI and C_TradeSkillUI.GetRecipeOutputItemData and recipeID)
        and C_TradeSkillUI.GetRecipeOutputItemData(recipeID, reagentInfo) or nil;
    local itemLink = out and out.hyperlink or nil;

    local tip = 0;
    local tipBox = form.PaymentContainer.TipMoneyInputFrame
        and form.PaymentContainer.TipMoneyInputFrame.GoldBox;
    if (tipBox and tipBox.GetAmount) then
        tip = tipBox:GetAmount() or 0;
    end
    local missingMats = false;
    if (form.transaction.HasMetQuantityRequirements) then
        missingMats = not form.transaction:HasMetQuantityRequirements();
    end

    local msg = buildMessage("[Guild order placed]", itemLink, nil, tip, missingMats);
    if (SendChatMessage) then
        SendChatMessage(msg, "GUILD");
    else
        Lantern:Print("Crafting Orders: " .. tostring(msg));
    end
end

local function parseFulfillArgs(...)
    local a, b = ...;
    local orderID, result;
    if (type(a) == "number" and type(b) == "number") then
        if (a > b) then orderID, result = a, b else orderID, result = b, a end
    elseif (type(a) == "number" and b == nil) then
        orderID = a;
    else
        orderID = tonumber(a) or tonumber(b);
        result = tonumber(a) or tonumber(b);
    end
    return orderID, result;
end

local function isFulfillOk(result)
    if (result == nil) then return true; end
    if (Enum and Enum.CraftingOrderResult and type(result) == "number") then
        return result == Enum.CraftingOrderResult.Ok or result == 0;
    end
    return result == 0;
end

function CraftingOrders:HandleFulfillResponse(...)
    if (not self.db or not self.db.postFulfill) then return; end
    local orderID, result = parseFulfillArgs(...);
    if (not isFulfillOk(result)) then
        self._awaitingFulfill = false;
        return;
    end

    local info = getOrderInfoByID(orderID);
    local isGuild = info and isGuildOrderType(info.orderType);
    if (not isGuild) then
        self._awaitingFulfill = false;
        return;
    end

    local itemLink = info and (info.outputItemHyperlink or info.outputItemLink) or nil;
    local who = stripRealm(info and (info.customerName or info.recipient) or nil);
    local grossCopper = info and (info.tipAmount or info.tip) or 0;
    local cutCopper = info and (info.consortiumCut or info.consortiumFee or 0) or 0;
    local netCopper = math.max(grossCopper - cutCopper, 0);
    local tipGold = math.floor(netCopper / 10000);

    if (itemLink and who) then
        local msg = buildMessage("[Guild order fulfilled]", itemLink, who, tipGold, false);
        if (SendChatMessage) then
            SendChatMessage(msg, "GUILD");
        else
            Lantern:Print("Crafting Orders: " .. tostring(msg));
        end
        self._awaitingFulfill = false;
        return;
    end

    self._awaitingFulfill = true;
    self._awaitDeadline = GetTime() + 3;
end

function CraftingOrders:HandleSystemMessage(msg)
    if (not self._awaitingFulfill) then return; end
    if (self._awaitDeadline and GetTime() > self._awaitDeadline) then
        self._awaitingFulfill = false;
        return;
    end

    local text = tostring(msg or "");
    local orderType = text:match("filled a%s+(%a+)%s+crafting order");
    if (not orderType) then return; end

    if (orderType:lower() ~= "guild") then
        self._awaitingFulfill = false;
        return;
    end

    local itemLink = text:match("(|c%x+|Hitem:.-|h%[.-%]|h|r)");
    if (not itemLink) then
        local bracketed = text:match("%[(.-)%]");
        if (bracketed) then itemLink = "[" .. bracketed .. "]"; end
    end

    local who = text:match("for%s+(.+)%s+and%s+earned");
    if (who) then
        who = stripRealm(who:gsub("%s+$", ""));
    end

    local commissionText = text:match("earned a%s+(.+)%s+commission");
    local tipGold = 0;
    if (commissionText) then
        local digits = commissionText:gsub("[^%d]", "");
        tipGold = tonumber(digits) or 0;
    end

    local msg = buildMessage("[Guild order fulfilled]", itemLink, who, tipGold, false);
    if (SendChatMessage) then
        SendChatMessage(msg, "GUILD");
    else
        Lantern:Print("Crafting Orders: " .. tostring(msg));
    end
    self._awaitingFulfill = false;
end

function CraftingOrders:HandlePersonalOrderMessage(msg)
    if (not self.db or not self.db.notifyPersonal) then return; end
    if (not self._personalCountAvailable) then
        if (type(msg) == "string" and msg:find("received a new Personal Crafting Order", 1, true)) then
            self:OutputMessage(formatPersonalOrderMessage());
        end
    end
end

function CraftingOrders:HandlePersonalOrderCountUpdate()
    if (not self.db or not self.db.notifyPersonal) then return; end
    local count = getPersonalOrderCount();
    if (type(count) ~= "number") then
        self._personalCountAvailable = false;
        return;
    end
    self._personalCountAvailable = true;
    if (self._personalCount ~= nil and count > self._personalCount) then
        self:OutputMessage(formatPersonalOrderMessage());
    end
    self._personalCount = count;
end

function CraftingOrders:GetOptions()
    local outputOptions;
    if (LibSink and LibSink.GetSinkAce3OptionsDataTable) then
        outputOptions = LibSink.GetSinkAce3OptionsDataTable(self);
        outputOptions.order = 2;
    end

    return {
        general = {
            order = 1,
            type = "group",
            name = "General",
            args = {
                postPlacement = {
                    order = 1,
                    type = "toggle",
                    name = "Announce placed guild orders",
                    width = "full",
                    get = function() return self.db and self.db.postPlacement; end,
                    set = function(_, value)
                        self.db.postPlacement = value and true or false;
                    end,
                },
                postFulfill = {
                    order = 2,
                    type = "toggle",
                    name = "Announce fulfilled guild orders",
                    width = "full",
                    get = function() return self.db and self.db.postFulfill; end,
                    set = function(_, value)
                        self.db.postFulfill = value and true or false;
                    end,
                },
                notifyPersonal = {
                    order = 3,
                    type = "toggle",
                    name = "Notify on personal orders",
                    desc = "Show a notification when you receive a personal crafting order.",
                    width = "full",
                    get = function() return self.db and self.db.notifyPersonal; end,
                    set = function(_, value)
                        self.db.notifyPersonal = value and true or false;
                    end,
                },
                debug = {
                    order = 4,
                    type = "toggle",
                    name = "Debug (print only)",
                    desc = "When enabled, announcements are printed instead of sent to the chosen output.",
                    width = "full",
                    get = function() return self.db and self.db.debug; end,
                    set = function(_, value)
                        self.db.debug = value and true or false;
                    end,
                },
            },
        },
        output = outputOptions or {
            order = 2,
            type = "group",
            name = "Output",
            args = {
                desc = {
                    order = 1,
                    type = "description",
                    name = "LibSink-2.0 not available. Messages will be sent to guild chat.",
                    fontSize = "medium",
                },
            },
        },
    };
end

function CraftingOrders:OnInit()
    ensureDB(self);
end

function CraftingOrders:OnEnable()
    ensureDB(self);
    self._awaitingFulfill = false;
    self._awaitDeadline = 0;
    self._personalCount = getPersonalOrderCount();
    self._personalCountAvailable = self._personalCount ~= nil;
    self.addon:ModuleRegisterEvent(self, "CRAFTINGORDERS_ORDER_PLACEMENT_RESPONSE", function()
        self:HandlePlacement();
    end);
    self.addon:ModuleRegisterEvent(self, "CRAFTINGORDERS_FULFILL_ORDER_RESPONSE", function(_, _, ...)
        self:HandleFulfillResponse(...);
    end);
    self.addon:ModuleRegisterEvent(self, "CRAFTINGORDERS_UPDATE_PERSONAL_ORDER_COUNTS", function()
        self:HandlePersonalOrderCountUpdate();
    end);
    self.addon:ModuleRegisterEvent(self, "CHAT_MSG_SYSTEM", function(_, _, msg)
        self:HandleSystemMessage(msg);
        self:HandlePersonalOrderMessage(msg);
    end);
end

function CraftingOrders:OnDisable()
    self._awaitingFulfill = false;
    self._awaitDeadline = 0;
end

Lantern:RegisterModule(CraftingOrders);
