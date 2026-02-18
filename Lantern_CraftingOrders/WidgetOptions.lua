local Lantern = _G.Lantern;
if (not Lantern or not Lantern.modules or not Lantern.modules.CraftingOrders) then return; end

local LanternUX = _G.LanternUX;
if (not LanternUX or not LanternUX.Theme) then return; end

local CraftingOrders = Lantern.modules.CraftingOrders;
local T = LanternUX.Theme;

-------------------------------------------------------------------------------
-- Utilities
-------------------------------------------------------------------------------

local function refreshPage()
    if (Lantern._uxPanel and Lantern._uxPanel.RefreshCurrentPage) then
        Lantern._uxPanel:RefreshCurrentPage();
    end
end

-------------------------------------------------------------------------------
-- Guild Orders page
-------------------------------------------------------------------------------

local function guildWidgets()
    local db = CraftingOrders.db;
    if (not db) then return {}; end

    local widgets = {
        {
            type = "description",
            text = "Automatically announce guild crafting orders in guild chat when you place or fulfill them.",
            fontSize = "medium",
        },
        {
            type = "execute",
            label = "Guild Orders",
            desc = "Click 5 times to unlock debug.",
            func = function()
                CraftingOrders:HandleDebugUnlockClick();
                refreshPage();
            end,
        },

        -----------------------------------------------------------------------
        -- Order Placed
        -----------------------------------------------------------------------
        { type = "header", text = "Order Placed" },
        {
            type = "toggle",
            label = "Announce placed orders",
            desc = "Post a message in guild chat when you place a guild crafting order.",
            get = function() return db.postPlacement; end,
            set = function(val)
                db.postPlacement = val and true or false;
            end,
        },
        {
            type = "input",
            label = "Message format",
            desc = "Tags: {item} {tip}",
            get = function() return db.guildPlacedMessage or ""; end,
            set = function(val)
                db.guildPlacedMessage = val or "";
                refreshPage();
            end,
        },
        {
            type = "description",
            text = "Preview: " .. CraftingOrders._buildGuildPreview(db.guildPlacedMessage or "", false),
            fontSize = "small",
            color = T.textDim,
        },

        -----------------------------------------------------------------------
        -- Order Fulfilled
        -----------------------------------------------------------------------
        { type = "header", text = "Order Fulfilled" },
        {
            type = "toggle",
            label = "Announce fulfilled orders",
            desc = "Post a message in guild chat when you fulfill a guild crafting order.",
            get = function() return db.postFulfill; end,
            set = function(val)
                db.postFulfill = val and true or false;
            end,
        },
        {
            type = "input",
            label = "Message format",
            desc = "Tags: {item} {who} {tip}",
            get = function() return db.guildFulfilledMessage or ""; end,
            set = function(val)
                db.guildFulfilledMessage = val or "";
                refreshPage();
            end,
        },
        {
            type = "description",
            text = "Preview: " .. CraftingOrders._buildGuildPreview(db.guildFulfilledMessage or "", true),
            fontSize = "small",
            color = T.textDim,
        },

        -----------------------------------------------------------------------
        -- Debug toggle (hidden until unlocked)
        -----------------------------------------------------------------------
        {
            type = "toggle",
            label = "Debug (print only)",
            desc = "When enabled, guild messages are printed to chat instead of being sent.",
            hidden = function() return not CraftingOrders._debugUnlocked; end,
            get = function() return db.debugGuild; end,
            set = function(val)
                db.debugGuild = val and true or false;
            end,
        },

        -----------------------------------------------------------------------
        -- Tag Details
        -----------------------------------------------------------------------
        { type = "header", text = "Tag Details" },
        {
            type = "description",
            text = "{item} = item link\n{who} = customer name\n{tip} = commission",
            fontSize = "medium",
        },
    };

    return widgets;
end

-------------------------------------------------------------------------------
-- Personal Orders page
-------------------------------------------------------------------------------

local function personalWidgets()
    local db = CraftingOrders.db;
    if (not db) then return {}; end

    local notifyDisabled = function() return not db.notifyPersonal; end;
    local soundDisabled = function() return not db.notifyPersonal or not db.personalSoundEnabled; end;

    local widgets = {
        {
            type = "description",
            text = "Get notified when you receive personal crafting orders.",
            fontSize = "medium",
        },

        -----------------------------------------------------------------------
        -- Personal Order Received
        -----------------------------------------------------------------------
        { type = "header", text = "Personal Order Received" },
        {
            type = "toggle",
            label = "Enable notification",
            desc = "Show a notification when you receive a personal crafting order.",
            get = function() return db.notifyPersonal; end,
            set = function(val)
                db.notifyPersonal = val and true or false;
                refreshPage();
            end,
        },

        -----------------------------------------------------------------------
        -- Sound
        -----------------------------------------------------------------------
        { type = "header", text = "Sound" },
        {
            type = "toggle",
            label = "Play sound",
            desc = "Play a sound when a personal crafting order is received.",
            disabled = notifyDisabled,
            get = function() return db.personalSoundEnabled; end,
            set = function(val)
                db.personalSoundEnabled = val and true or false;
                refreshPage();
            end,
        },
        {
            type = "select",
            label = "Sound",
            desc = "Sound to play when a personal crafting order is received. Click the speaker icon to preview.",
            values = CraftingOrders._getSoundValues,
            disabled = soundDisabled,
            get = function() return db.personalSoundName or "Lantern: Auction Window Open"; end,
            set = function(val)
                db.personalSoundName = val;
            end,
            preview = CraftingOrders._previewSound,
        },

        -----------------------------------------------------------------------
        -- Notification Appearance
        -----------------------------------------------------------------------
        { type = "header", text = "Notification Appearance" },
        {
            type = "select",
            label = "Font",
            desc = "Font used for the notification text.",
            values = CraftingOrders._getFontValues,
            disabled = notifyDisabled,
            get = function() return db.personalFont or "Friz Quadrata TT"; end,
            set = function(val)
                db.personalFont = val;
            end,
        },
        {
            type = "range",
            label = "Font size",
            desc = "Size of the notification text.",
            min = 12, max = 48, step = 1,
            disabled = notifyDisabled,
            get = function() return db.personalFontSize or 24; end,
            set = function(val)
                db.personalFontSize = val;
            end,
        },
        {
            type = "select",
            label = "Font outline",
            desc = "Outline style for the notification text.",
            values = CraftingOrders._getOutlineValues,
            disabled = notifyDisabled,
            get = function() return db.personalFontOutline or "OUTLINE"; end,
            set = function(val)
                db.personalFontOutline = val;
            end,
        },
        {
            type = "color",
            label = "Text color",
            desc = "Color of the notification text.",
            disabled = notifyDisabled,
            get = function()
                local c = db.personalColor or { r = 1, g = 1, b = 1 };
                return c.r, c.g, c.b;
            end,
            set = function(r, g, b)
                db.personalColor = { r = r, g = g, b = b };
            end,
        },
        {
            type = "range",
            label = "Duration",
            desc = "How long the notification is shown (seconds).",
            min = 1, max = 15, step = 1,
            disabled = notifyDisabled,
            get = function() return db.personalDuration or 5; end,
            set = function(val)
                db.personalDuration = val;
            end,
        },
        {
            type = "execute",
            label = "Test notification",
            desc = "Show a test notification with the current settings.",
            disabled = notifyDisabled,
            func = function()
                CraftingOrders:OutputMessage(CraftingOrders._formatPersonalOrderMessage());
                CraftingOrders._playPersonalSound();
            end,
        },

        -----------------------------------------------------------------------
        -- Crafting Window
        -----------------------------------------------------------------------
        { type = "header", text = "Crafting Window" },
        {
            type = "toggle",
            label = "Show Complete + Whisper button",
            desc = "Add a button to the crafting order view that completes the order and whispers the customer.",
            get = function() return db.enableWhisperButton; end,
            set = function(val)
                db.enableWhisperButton = val and true or false;
                CraftingOrders:UpdateWhisperButton();
                refreshPage();
            end,
        },
        {
            type = "input",
            label = "Whisper message",
            desc = "Use {name} and {item} as placeholders.",
            disabled = function() return not db.enableWhisperButton; end,
            get = function() return db.whisperMessage or ""; end,
            set = function(val)
                db.whisperMessage = val or "";
            end,
        },
    };

    return widgets;
end

-------------------------------------------------------------------------------
-- Register uxPages
-------------------------------------------------------------------------------

CraftingOrders.uxPages = {
    { key = "craftingorders_guild",    opts = { label = "Guild Orders",    title = "Guild Orders",    description = "Announce guild crafting orders.", widgets = guildWidgets } },
    { key = "craftingorders_personal", opts = { label = "Personal Orders", title = "Personal Orders", description = "Personal order notifications.",   widgets = personalWidgets } },
};
