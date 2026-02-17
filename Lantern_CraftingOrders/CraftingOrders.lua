local ADDON_NAME = ...;
local Lantern = _G.Lantern;
local C_CraftingOrders = C_CraftingOrders;
local C_TradeSkillUI = C_TradeSkillUI;
local Enum = Enum;
local PlaySoundFile = PlaySoundFile;
local SendChatMessage = C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage;

-- Abort early if the core addon is not available.
if (not Lantern) then return; end

local LibSink = LibStub and LibStub("LibSink-2.0", true);
local LibSharedMedia = LibStub and LibStub("LibSharedMedia-3.0", true);

local CraftingOrders = Lantern:NewModule("CraftingOrders", {
    title = "Crafting Orders",
    desc = "Notify about guild crafting order placements and completions.",
});

local DEFAULTS = {
    postPlacement = true,
    postFulfill = true,
    guildPlacedMessage = "[Guild order placed] {item}, {tip}",
    guildFulfilledMessage = "[Guild order fulfilled] {item} for {who}, {tip}",
    debugGuild = false,
    notifyPersonal = true,
    personalSoundEnabled = true,
    personalSoundName = "Lantern: Auction Window Open",
    personalFont = "Friz Quadrata TT",
    personalFontSize = 24,
    personalFontOutline = "OUTLINE",
    personalColor = { r = 1, g = 1, b = 1 },  -- White
    personalDuration = 5,
    enableWhisperButton = true,
    whisperMessage = "Order complete! Thanks!",
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

local function formatGuildMessage(template, itemLink, who, tipCopper)
    local msg = tostring(template or "");
    local tipValue = Lantern and Lantern:Convert("money:format_copper", tipCopper) or "";
    local tipText = (tipValue ~= "") and (", commission: " .. tipValue) or "";
    msg = msg:gsub("{item}", itemLink or "Unknown item");
    msg = msg:gsub("{who}", who or "");
    msg = msg:gsub("{tip}", tipText);
    msg = msg:gsub("%s+", " ");
    msg = msg:gsub("%s+,", ",");
    msg = msg:gsub(",%s*,", ",");
    msg = msg:gsub(",%s*$", "");
    msg = msg:gsub("for%s*,", "for ");
    msg = msg:gsub("%s+$", "");
    return msg;
end

local function sendGuildMessage(msg)
    if (SendChatMessage) then
        SendChatMessage(msg, "GUILD");
    else
        Lantern:Print("Crafting Orders: " .. tostring(msg));
    end
end

local function buildGuildPreview(template, isFulfilled)
    local itemLink = "|cffffffff|Hitem:0:0:0:0:0:0:0:0:0|h[Sample Item]|h|r";
    local who = isFulfilled and "Customer" or "";
    local tip = 125000;
    return formatGuildMessage(template, itemLink, who, tip);
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

local function isPersonalOrderType(orderType)
    if (orderType == nil) then return false; end
    if (Enum and Enum.CraftingOrderType) then
        return orderType == Enum.CraftingOrderType.Personal;
    end
    return orderType == 0;
end

local function formatPersonalOrderMessage()
    return "New personal crafting order received.";
end

local function getSoundValues()
    if (Lantern.utils and Lantern.utils.RegisterMediaSounds) then
        Lantern.utils.RegisterMediaSounds(LibSharedMedia);
    end
    if (CraftingOrders._soundValues) then
        return CraftingOrders._soundValues;
    end
    if (not LibSharedMedia or not LibSharedMedia.List) then
        CraftingOrders._soundValues = { RaidWarning = "Raid warning" };
        return CraftingOrders._soundValues;
    end
    local values = {};
    for _, name in ipairs(LibSharedMedia:List("sound") or {}) do
        values[name] = name;
    end
    if (not values.RaidWarning) then
        values.RaidWarning = "Raid warning";
    end
    CraftingOrders._soundValues = values;
    return values;
end

local function playPersonalSound(self)
    if (not self.db or not self.db.personalSoundEnabled) then return; end
    if (not LibSharedMedia or not LibSharedMedia.Fetch) then return; end
    local sound = LibSharedMedia:Fetch("sound", self.db.personalSoundName or "RaidWarning");
    if (not sound) then return; end
    local soundId = tonumber(sound);
    if (soundId and PlaySound) then
        PlaySound(soundId, "Master");
        return;
    end
    if (PlaySoundFile) then
        PlaySoundFile(sound, "Master");
    end
end

-------------------------------------------------------------------------------
-- Custom Notification Frame
-------------------------------------------------------------------------------

local notificationFrame = nil;
local notificationText = nil;
local fadeOutTimer = nil;

local function GetFontPath(fontName)
    if (LibSharedMedia) then
        local path = LibSharedMedia:Fetch("font", fontName);
        if (path) then return path; end
    end
    return "Fonts\\FRIZQT__.TTF";
end

local function GetFontValues()
    local fonts = {};
    if (LibSharedMedia) then
        for _, name in ipairs(LibSharedMedia:List("font") or {}) do
            fonts[name] = name;
        end
    end
    if (not fonts["Friz Quadrata TT"]) then
        fonts["Friz Quadrata TT"] = "Friz Quadrata TT";
    end
    return fonts;
end

local function GetOutlineValues()
    return {
        [""] = "None",
        ["OUTLINE"] = "Outline",
        ["THICKOUTLINE"] = "Thick Outline",
        ["MONOCHROME"] = "Monochrome",
        ["OUTLINE, MONOCHROME"] = "Outline + Monochrome",
    };
end

local function CreateNotificationFrame()
    if (notificationFrame) then return; end

    notificationFrame = CreateFrame("Frame", "LanternCraftingOrdersNotification", UIParent);
    notificationFrame:SetSize(400, 50);
    notificationFrame:SetPoint("TOP", UIParent, "TOP", 0, -200);
    notificationFrame:SetFrameStrata("HIGH");
    notificationFrame:SetFrameLevel(100);

    notificationText = notificationFrame:CreateFontString(nil, "OVERLAY");
    notificationText:SetPoint("CENTER", notificationFrame, "CENTER", 0, 0);
    notificationText:SetShadowOffset(2, -2);
    notificationText:SetShadowColor(0, 0, 0, 0.8);

    notificationFrame:Hide();
end

local function UpdateNotificationFont(db)
    if (not notificationText) then return; end

    local fontPath = GetFontPath(db.personalFont or DEFAULTS.personalFont);
    local fontSize = db.personalFontSize or DEFAULTS.personalFontSize;
    local fontOutline = db.personalFontOutline or DEFAULTS.personalFontOutline;

    notificationText:SetFont(fontPath, fontSize, fontOutline);

    local c = db.personalColor or DEFAULTS.personalColor;
    notificationText:SetTextColor(c.r, c.g, c.b, 1);
end

local function ShowNotification(self, msg)
    CreateNotificationFrame();

    local db = self.db or DEFAULTS;
    UpdateNotificationFont(db);

    notificationText:SetText(msg);
    notificationFrame:SetAlpha(1);
    notificationFrame:Show();

    -- Cancel any existing fade timer
    if (fadeOutTimer) then
        fadeOutTimer:Cancel();
        fadeOutTimer = nil;
    end

    -- Fade out after configured duration
    local duration = db.personalDuration or DEFAULTS.personalDuration;
    fadeOutTimer = C_Timer.NewTimer(duration, function()
        -- Fade out animation
        local fadeTime = 1;
        local startTime = GetTime();
        notificationFrame:SetScript("OnUpdate", function(frame)
            local elapsed = GetTime() - startTime;
            local alpha = 1 - (elapsed / fadeTime);
            if (alpha <= 0) then
                frame:SetAlpha(0);
                frame:Hide();
                frame:SetScript("OnUpdate", nil);
            else
                frame:SetAlpha(alpha);
            end
        end);
        fadeOutTimer = nil;
    end);
end

function CraftingOrders:OutputMessage(msg)
    -- Use custom notification frame for personal order notifications
    ShowNotification(self, msg);
end

local function getPersonalOrderCount()
    if (not C_CraftingOrders or not C_CraftingOrders.GetPersonalOrdersInfo) then return nil; end
    local infos = C_CraftingOrders.GetPersonalOrdersInfo();
    if (type(infos) ~= "table") then return nil; end
    local total = 0;
    for _, info in ipairs(infos) do
        total = total + (info.numPersonalOrders or 0);
    end
    return total;
end

local function formatWhisperMessage(template, order)
    local msg = tostring(template or "");
    local itemLink = order and (order.outputItemHyperlink or order.outputItemLink) or "";
    local name = stripRealm(order and (order.customerName or order.recipient) or "") or "";
    msg = msg:gsub("{item}", itemLink ~= "" and itemLink or "your item");
    msg = msg:gsub("{name}", name ~= "" and name or "there");
    return msg;
end

local function getOrderView()
    local ordersPage = ProfessionsFrame and ProfessionsFrame.OrdersPage;
    return ordersPage and ordersPage.OrderView;
end

local function getCompleteButton(view)
    if (not view) then return nil; end

    -- Try OrderDetails.FulfillmentForm first (Midnight beta)
    if (view.OrderDetails and view.OrderDetails.FulfillmentForm) then
        local form = view.OrderDetails.FulfillmentForm;
        if (form.CompleteOrderButton) then
            return form.CompleteOrderButton;
        end
    end

    -- Try OrderDetails directly
    if (view.OrderDetails and view.OrderDetails.CompleteOrderButton) then
        return view.OrderDetails.CompleteOrderButton;
    end

    -- Fallback to view.CompleteOrderButton (old structure)
    return view.CompleteOrderButton;
end

local function getRightButton(view)
    if (not view) then return nil; end
    local button = getCompleteButton(view);
    if (button and button:IsShown()) then
        return button;
    end
    if (view.CreateOrderButton and view.CreateOrderButton:IsShown()) then
        return view.CreateOrderButton;
    end
    return button or view.CreateOrderButton;
end

function CraftingOrders:HandlePlacement()
    if (not self.db or not self.db.postPlacement) then return; end
    local frame = ProfessionsCustomerOrdersFrame;
    if (not frame or not frame.Form) then return; end
    local form = frame.Form;
    if (not form.order or not form.transaction or not form.PaymentContainer) then return; end

    if (not isGuildOrderType(form.order.orderType)) then
        return;
    end

    local recipeID = form.transaction.GetRecipeID and form.transaction:GetRecipeID() or nil;
    local reagentInfo = form.transaction.CreateCraftingReagentInfoTbl
        and form.transaction:CreateCraftingReagentInfoTbl() or nil;
    local out = (C_TradeSkillUI and C_TradeSkillUI.GetRecipeOutputItemData and recipeID)
        and C_TradeSkillUI.GetRecipeOutputItemData(recipeID, reagentInfo) or nil;
    local itemLink = out and out.hyperlink or nil;

    local tip = 0;
    local tipFrame = form.PaymentContainer.TipMoneyInputFrame;
    if (tipFrame and tipFrame.GetAmount) then
        tip = tipFrame:GetAmount() or 0;
    else
        local tipBox = tipFrame and tipFrame.GoldBox;
        if (tipBox and tipBox.GetAmount) then
            tip = (tipBox:GetAmount() or 0) * 10000;
        end
    end
    local msg = formatGuildMessage(self.db.guildPlacedMessage, itemLink, nil, tip);
    if (self.db.debugGuild) then
        Lantern:Print("Crafting Orders: would have sent: " .. tostring(msg));
        return;
    end
    sendGuildMessage(msg);
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
    local tipCopper = netCopper or 0;

    if (itemLink and who) then
        local msg = formatGuildMessage(self.db.guildFulfilledMessage, itemLink, who, tipCopper);
        if (self.db.debugGuild) then
            Lantern:Print("Crafting Orders: would have sent: " .. tostring(msg));
        else
            sendGuildMessage(msg);
        end
        self._awaitingFulfill = false;
        return;
    end

    -- Save partial info for the system message fallback handler
    self._awaitingFulfill = true;
    self._awaitDeadline = GetTime() + 3;
    self._awaitFulfillWho = who;
    self._awaitFulfillTip = tipCopper;
end

function CraftingOrders:HandleSystemMessage(msg)
    if (not self._awaitingFulfill) then return; end
    if (self._awaitDeadline and GetTime() > self._awaitDeadline) then
        self._awaitingFulfill = false;
        return;
    end

    local text = tostring(msg or "");

    -- Extract item link (locale-independent: uses escape sequences)
    local itemLink = text:match("(|c%x+|Hitem:.-|h%[.-%]|h|r)");
    if (not itemLink) then
        local bracketed = text:match("%[(.-)%]");
        if (bracketed) then itemLink = "[" .. bracketed .. "]"; end
    end

    -- If no item link found, this isn't a crafting order message
    if (not itemLink) then return; end

    -- Extract copper amount from any |cffffffff<amount>|r money string, or fallback to
    -- the saved order info. Commission details may not be parseable across locales.
    local tipCopper = self._awaitFulfillTip or 0;

    local fmtMsg = formatGuildMessage(self.db.guildFulfilledMessage, itemLink, self._awaitFulfillWho, tipCopper);
    if (self.db.debugGuild) then
        Lantern:Print("Crafting Orders: would have sent: " .. tostring(fmtMsg));
    else
        sendGuildMessage(fmtMsg);
    end
    self._awaitingFulfill = false;
    self._awaitFulfillWho = nil;
    self._awaitFulfillTip = nil;
end

function CraftingOrders:HandlePersonalOrderCountUpdate()
    if (not self.db or not self.db.notifyPersonal) then return; end
    local count = getPersonalOrderCount();
    if (type(count) ~= "number") then return; end
    if (self._personalCount ~= nil and count > self._personalCount) then
        self:OutputMessage(formatPersonalOrderMessage());
        playPersonalSound(self);
    end
    self._personalCount = count;
end

function CraftingOrders:HandleCompleteAndWhisper()
    local view = getOrderView();
    local button = getCompleteButton(view);
    local order = view and view.order;
    if (not view or not button or not button.IsEnabled or not button:IsEnabled()) then return; end
    if (not order or not isPersonalOrderType(order.orderType)) then return; end
    if (button.Click) then
        button:Click();
    end
    if (not self.db or not self.db.enableWhisperButton) then return; end
    local recipient = stripRealm(order.customerName or order.recipient);
    if (recipient and recipient ~= "" and SendChatMessage) then
        local msg = formatWhisperMessage(self.db.whisperMessage, order);
        if (msg ~= "") then
            SendChatMessage(msg, "WHISPER", nil, recipient);
        end
    end
end

function CraftingOrders:UpdateWhisperButton()
    local view = getOrderView();
    local button = view and view._lanternCompleteWhisperButton;
    if (not view or not button) then return; end
    if (not self.db or not self.db.enableWhisperButton) then
        button:Hide();
        return;
    end
    local order = view.order;
    local canUse = order and isPersonalOrderType(order.orderType);
    local baseButton = getCompleteButton(view);
    if (baseButton and baseButton.IsShown) then
        canUse = canUse and baseButton:IsShown();
    end
    if (baseButton and baseButton.IsEnabled) then
        canUse = canUse and baseButton:IsEnabled();
    end
    if (canUse) then
        button:Show();
        button:SetEnabled(true);
    else
        button:SetEnabled(false);
        button:Hide();
    end
end

function CraftingOrders:EnsureWhisperButton()
    local view = getOrderView();
    if (not view) then return; end

    -- Try to find the complete button (handles both old and Midnight beta structure)
    local baseButton = getCompleteButton(view);
    if (not baseButton) then
        return;
    end

    -- Don't recreate if it already exists
    if (view._lanternCompleteWhisperButton) then return; end

    local button = CreateFrame("Button", nil, view, "UIPanelButtonTemplate");
    button:SetText("Complete + Whisper");

    -- Set size based on base button
    local height = baseButton:GetHeight() or 22;
    local width = baseButton:GetWidth() or 120;
    button:SetHeight(height);
    button:SetWidth(width);

    if (button.SetFrameStrata) then
        button:SetFrameStrata("TOOLTIP");
    end
    if (button.SetFrameLevel and baseButton.GetFrameLevel) then
        button:SetFrameLevel(baseButton:GetFrameLevel() + 20);
    end

    button:ClearAllPoints();
    button:SetPoint("BOTTOM", baseButton, "TOP", 0, 2);
    button:SetScript("OnClick", function()
        self:HandleCompleteAndWhisper();
    end);

    view._lanternCompleteWhisperButton = button;

    if (view.HookScript) then
        view:HookScript("OnShow", function() self:UpdateWhisperButton(); end);
    end
    if (baseButton.HookScript) then
        baseButton:HookScript("OnEnable", function() self:UpdateWhisperButton(); end);
        baseButton:HookScript("OnDisable", function() self:UpdateWhisperButton(); end);
        baseButton:HookScript("OnShow", function() self:UpdateWhisperButton(); end);
        baseButton:HookScript("OnHide", function() self:UpdateWhisperButton(); end);
    end
    if (view.SetOrder and hooksecurefunc) then
        hooksecurefunc(view, "SetOrder", function() self:UpdateWhisperButton(); end);
    end
    if (view.SetOrderInfo and hooksecurefunc) then
        hooksecurefunc(view, "SetOrderInfo", function() self:UpdateWhisperButton(); end);
    end
end

function CraftingOrders:HandleDebugUnlockClick()
    self._debugClickCount = (self._debugClickCount or 0) + 1;
    if (self._debugClickCount >= 5) then
        self._debugClickCount = 0;
        self._debugUnlocked = true;
        Lantern:Print("Crafting Orders: debug options unlocked.");
    end
end

function CraftingOrders:GetOptions()
    local notifyDisabled = function() return not (self.db and self.db.notifyPersonal); end;

    return {
        general = {
            order = 1,
            type = "group",
            name = "Guild Orders",
            args = {
                moduleDesc = {
                    order = 0.5,
                    type = "description",
                    name = "Automatically announce guild crafting orders in guild chat when you place or fulfill them.",
                    fontSize = "medium",
                },
                guildHeader = {
                    order = 1,
                    type = "execute",
                    name = "Guild Orders",
                    desc = "Click 5 times to unlock debug.",
                    width = "full",
                    func = function()
                        self:HandleDebugUnlockClick();
                    end,
                },
                placedHeader = {
                    order = 2,
                    type = "header",
                    name = "Order placed",
                },
                postPlacement = {
                    order = 3,
                    type = "toggle",
                    name = "Announce placed orders",
                    width = "full",
                    get = function() return self.db and self.db.postPlacement; end,
                    set = function(_, value)
                        self.db.postPlacement = value and true or false;
                    end,
                },
                placedMessage = {
                    order = 4,
                    type = "input",
                    name = "Message",
                    desc = "Tags: {item} {tip}",
                    width = "full",
                    get = function() return self.db and self.db.guildPlacedMessage; end,
                    set = function(_, value)
                        self.db.guildPlacedMessage = value or "";
                    end,
                },
                placedPreview = {
                    order = 5,
                    type = "description",
                    name = function()
                        return "Preview: " .. buildGuildPreview(self.db and self.db.guildPlacedMessage or "", false);
                    end,
                    fontSize = "medium",
                },
                fulfilledHeader = {
                    order = 6,
                    type = "header",
                    name = "Order fulfilled",
                },
                postFulfill = {
                    order = 7,
                    type = "toggle",
                    name = "Announce fulfilled orders",
                    width = "full",
                    get = function() return self.db and self.db.postFulfill; end,
                    set = function(_, value)
                        self.db.postFulfill = value and true or false;
                    end,
                },
                fulfilledMessage = {
                    order = 8,
                    type = "input",
                    name = "Message",
                    desc = "Tags: {item} {who} {tip}",
                    width = "full",
                    get = function() return self.db and self.db.guildFulfilledMessage; end,
                    set = function(_, value)
                        self.db.guildFulfilledMessage = value or "";
                    end,
                },
                fulfilledPreview = {
                    order = 9,
                    type = "description",
                    name = function()
                        return "Preview: " .. buildGuildPreview(self.db and self.db.guildFulfilledMessage or "", true);
                    end,
                    fontSize = "medium",
                },
                debugGuild = {
                    order = 10,
                    type = "toggle",
                    name = "Debug (print only)",
                    desc = "When enabled, guild messages are printed instead of sent.",
                    width = "full",
                    hidden = function() return not self._debugUnlocked; end,
                    get = function() return self.db and self.db.debugGuild; end,
                    set = function(_, value)
                        self.db.debugGuild = value and true or false;
                    end,
                },
                tagHeader = {
                    order = 11,
                    type = "header",
                    name = "Tag details",
                },
                tagDetails = {
                    order = 12,
                    type = "description",
                    name = "{item} = item link\n{who} = customer name\n{tip} = commission",
                    fontSize = "medium",
                },
            },
        },
        personal = {
            order = 2,
            type = "group",
            name = "Personal Orders",
            args = {
                moduleDesc = {
                    order = 0.5,
                    type = "description",
                    name = "Get notified when you receive personal crafting orders.",
                    fontSize = "medium",
                },
                receivedHeader = {
                    order = 1,
                    type = "header",
                    name = "Personal order received",
                },
                enabled = {
                    order = 2,
                    type = "toggle",
                    name = "Enable notification",
                    width = "full",
                    get = function() return self.db and self.db.notifyPersonal; end,
                    set = function(_, value)
                        self.db.notifyPersonal = value and true or false;
                    end,
                },
                soundEnabled = {
                    order = 3,
                    type = "toggle",
                    name = "Play sound",
                    width = "normal",
                    disabled = notifyDisabled,
                    get = function() return self.db and self.db.personalSoundEnabled; end,
                    set = function(_, value)
                        self.db.personalSoundEnabled = value and true or false;
                    end,
                },
                soundName = {
                    order = 3.1,
                    type = "select",
                    name = "Sound",
                    width = "normal",
                    values = getSoundValues,
                    itemControl = "DDI-Sound",
                    disabled = function() return not (self.db and self.db.notifyPersonal and self.db.personalSoundEnabled); end,
                    get = function() return self.db and self.db.personalSoundName or "Lantern: Auction Window Open"; end,
                    set = function(_, value)
                        self.db.personalSoundName = value;
                    end,
                },
                fontHeader = {
                    order = 4,
                    type = "header",
                    name = "Notification Appearance",
                },
                font = {
                    order = 5,
                    type = "select",
                    name = "Font",
                    width = "normal",
                    disabled = notifyDisabled,
                    dialogControl = "LSM30_Font",
                    values = GetFontValues,
                    get = function() return self.db and self.db.personalFont or "Friz Quadrata TT"; end,
                    set = function(_, value)
                        self.db.personalFont = value;
                    end,
                },
                fontSize = {
                    order = 5.1,
                    type = "range",
                    name = "Font Size",
                    width = "normal",
                    min = 12,
                    max = 48,
                    step = 1,
                    disabled = notifyDisabled,
                    get = function() return self.db and self.db.personalFontSize or 24; end,
                    set = function(_, value)
                        self.db.personalFontSize = value;
                    end,
                },
                spacer1 = {
                    order = 5.99,
                    type = "description",
                    name = "",
                    width = "full",
                },
                fontOutline = {
                    order = 6,
                    type = "select",
                    name = "Font Outline",
                    width = "normal",
                    disabled = notifyDisabled,
                    values = GetOutlineValues,
                    get = function() return self.db and self.db.personalFontOutline or "OUTLINE"; end,
                    set = function(_, value)
                        self.db.personalFontOutline = value;
                    end,
                },
                color = {
                    order = 6.1,
                    type = "color",
                    name = "Text Color",
                    width = "normal",
                    disabled = notifyDisabled,
                    get = function()
                        local c = self.db and self.db.personalColor or DEFAULTS.personalColor;
                        return c.r, c.g, c.b;
                    end,
                    set = function(_, r, g, b)
                        self.db.personalColor = { r = r, g = g, b = b };
                    end,
                },
                spacer2 = {
                    order = 6.99,
                    type = "description",
                    name = "",
                    width = "full",
                },
                duration = {
                    order = 7,
                    type = "range",
                    name = "Duration",
                    desc = "How long the notification is shown (seconds).",
                    width = "normal",
                    min = 1,
                    max = 15,
                    step = 1,
                    disabled = notifyDisabled,
                    get = function() return self.db and self.db.personalDuration or 5; end,
                    set = function(_, value)
                        self.db.personalDuration = value;
                    end,
                },
                spacer3 = {
                    order = 7.99,
                    type = "description",
                    name = "",
                    width = "full",
                },
                testNotification = {
                    order = 8,
                    type = "execute",
                    name = "Test notification",
                    width = "normal",
                    disabled = notifyDisabled,
                    func = function()
                        self:OutputMessage(formatPersonalOrderMessage());
                        playPersonalSound(self);
                    end,
                },
                craftHeader = {
                    order = 10,
                    type = "header",
                    name = "Crafting window",
                },
                whisperButton = {
                    order = 11,
                    type = "toggle",
                    name = "Show Complete + Whisper button",
                    width = "full",
                    get = function() return self.db and self.db.enableWhisperButton; end,
                    set = function(_, value)
                        self.db.enableWhisperButton = value and true or false;
                        self:UpdateWhisperButton();
                    end,
                },
                whisperMessage = {
                    order = 12,
                    type = "input",
                    name = "Whisper message",
                    desc = "Use {name} and {item} as placeholders.",
                    width = "full",
                    disabled = function() return not (self.db and self.db.enableWhisperButton); end,
                    get = function() return self.db and self.db.whisperMessage; end,
                    set = function(_, value)
                        self.db.whisperMessage = value or "";
                    end,
                },
            },
        },
    };
end

function CraftingOrders:OnInit()
    ensureDB(self);
    self._debugUnlocked = false;
    if (self.db) then
        self.db.debugGuild = false;
    end
    if (Lantern.utils and Lantern.utils.RegisterMediaSounds) then
        Lantern.utils.RegisterMediaSounds(LibSharedMedia);
    end
end

function CraftingOrders:OnEnable()
    ensureDB(self);
    self._awaitingFulfill = false;
    self._awaitDeadline = 0;
    self._personalCount = getPersonalOrderCount();
    self:EnsureWhisperButton();
    self:UpdateWhisperButton();
    self.addon:ModuleRegisterEvent(self, "CRAFTINGORDERS_ORDER_PLACEMENT_RESPONSE", function()
        self:HandlePlacement();
    end);
    self.addon:ModuleRegisterEvent(self, "CRAFTINGORDERS_FULFILL_ORDER_RESPONSE", function(_, _, ...)
        self:HandleFulfillResponse(...);
    end);
    self.addon:ModuleRegisterEvent(self, "CRAFTINGORDERS_CLAIMED_ORDER_UPDATED", function()
        self:EnsureWhisperButton();
        self:UpdateWhisperButton();
    end);
    self.addon:ModuleRegisterEvent(self, "TRADE_SKILL_ITEM_CRAFTED_RESULT", function()
        self:EnsureWhisperButton();
        self:UpdateWhisperButton();
    end);
    self.addon:ModuleRegisterEvent(self, "CRAFTINGORDERS_UPDATE_PERSONAL_ORDER_COUNTS", function()
        self:HandlePersonalOrderCountUpdate();
    end);
    self.addon:ModuleRegisterEvent(self, "CHAT_MSG_SYSTEM", function(_, _, msg)
        if (IsInInstance()) then return; end
        self:HandleSystemMessage(msg);
    end);
    -- Hook ProfessionsFrame to create button when it becomes available
    if (ProfessionsFrame and ProfessionsFrame.HookScript) then
        ProfessionsFrame:HookScript("OnShow", function()
            self:EnsureWhisperButton();
            self:UpdateWhisperButton();
        end);
    end
end

function CraftingOrders:OnDisable()
    self._awaitingFulfill = false;
    self._awaitDeadline = 0;
    self._awaitFulfillWho = nil;
    self._awaitFulfillTip = nil;
end

Lantern:RegisterModule(CraftingOrders);
