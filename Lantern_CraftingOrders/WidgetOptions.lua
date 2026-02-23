local L = select(2, ...).L;
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
            text = L["CO_GUILD_DESCRIPTION"],
            fontSize = "medium",
        },
        {
            type = "execute",
            label = L["CO_GUILD_ORDERS_BTN"],
            desc = L["CO_GUILD_ORDERS_BTN_DESC"],
            func = function()
                CraftingOrders:HandleDebugUnlockClick();
                refreshPage();
            end,
        },

        -----------------------------------------------------------------------
        -- Order Placed
        -----------------------------------------------------------------------
        { type = "header", text = L["CO_ORDER_PLACED_HEADER"] },
        {
            type = "toggle",
            label = L["CO_ANNOUNCE_PLACED"],
            desc = L["CO_ANNOUNCE_PLACED_DESC"],
            get = function() return db.postPlacement; end,
            set = function(val)
                db.postPlacement = val and true or false;
            end,
        },
        {
            type = "input",
            label = L["CO_MESSAGE_FORMAT"],
            desc = L["CO_PLACED_FORMAT_DESC"],
            get = function() return db.guildPlacedMessage or ""; end,
            set = function(val)
                db.guildPlacedMessage = val or "";
                refreshPage();
            end,
        },
        {
            type = "description",
            text = L["CO_PREVIEW_PREFIX"] .. CraftingOrders._buildGuildPreview(db.guildPlacedMessage or "", false),
            fontSize = "small",
            color = T.textDim,
        },

        -----------------------------------------------------------------------
        -- Order Fulfilled
        -----------------------------------------------------------------------
        { type = "header", text = L["CO_ORDER_FULFILLED_HEADER"] },
        {
            type = "toggle",
            label = L["CO_ANNOUNCE_FULFILLED"],
            desc = L["CO_ANNOUNCE_FULFILLED_DESC"],
            get = function() return db.postFulfill; end,
            set = function(val)
                db.postFulfill = val and true or false;
            end,
        },
        {
            type = "input",
            label = L["CO_MESSAGE_FORMAT"],
            desc = L["CO_FULFILLED_FORMAT_DESC"],
            get = function() return db.guildFulfilledMessage or ""; end,
            set = function(val)
                db.guildFulfilledMessage = val or "";
                refreshPage();
            end,
        },
        {
            type = "description",
            text = L["CO_PREVIEW_PREFIX"] .. CraftingOrders._buildGuildPreview(db.guildFulfilledMessage or "", true),
            fontSize = "small",
            color = T.textDim,
        },

        -----------------------------------------------------------------------
        -- Debug toggle (hidden until unlocked)
        -----------------------------------------------------------------------
        {
            type = "toggle",
            label = L["CO_DEBUG_LABEL"],
            desc = L["CO_DEBUG_DESC"],
            hidden = function() return not CraftingOrders._debugUnlocked; end,
            get = function() return db.debugGuild; end,
            set = function(val)
                db.debugGuild = val and true or false;
            end,
        },

        -----------------------------------------------------------------------
        -- Tag Details
        -----------------------------------------------------------------------
        { type = "header", text = L["CO_TAG_DETAILS_HEADER"] },
        {
            type = "description",
            text = L["CO_TAG_DETAILS_TEXT"],
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
            text = L["CO_PERSONAL_DESCRIPTION"],
            fontSize = "medium",
        },

        -----------------------------------------------------------------------
        -- Personal Order Received
        -----------------------------------------------------------------------
        { type = "header", text = L["CO_PERSONAL_RECEIVED_HEADER"] },
        {
            type = "toggle",
            label = L["CO_ENABLE_NOTIFICATION"],
            desc = L["CO_ENABLE_NOTIFICATION_DESC"],
            get = function() return db.notifyPersonal; end,
            set = function(val)
                db.notifyPersonal = val and true or false;
                refreshPage();
            end,
        },

        -----------------------------------------------------------------------
        -- Sound
        -----------------------------------------------------------------------
        { type = "header", text = L["CO_SOUND_HEADER"] },
        {
            type = "toggle",
            label = L["CO_PLAY_SOUND"],
            desc = L["CO_PLAY_SOUND_DESC"],
            disabled = notifyDisabled,
            get = function() return db.personalSoundEnabled; end,
            set = function(val)
                db.personalSoundEnabled = val and true or false;
                refreshPage();
            end,
        },
        {
            type = "select",
            label = L["CO_SOUND_SELECT"],
            desc = L["CO_SOUND_SELECT_DESC"],
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
        { type = "header", text = L["CO_APPEARANCE_HEADER"] },
        {
            type = "select",
            label = L["CO_FONT"],
            desc = L["CO_FONT_DESC"],
            values = CraftingOrders._getFontValues,
            disabled = notifyDisabled,
            get = function() return db.personalFont or "Roboto Light"; end,
            set = function(val)
                db.personalFont = val;
            end,
        },
        {
            type = "range",
            label = L["CO_FONT_SIZE"],
            desc = L["CO_FONT_SIZE_DESC"],
            min = 12, max = 48, step = 1, default = 24,
            disabled = notifyDisabled,
            get = function() return db.personalFontSize or 24; end,
            set = function(val)
                db.personalFontSize = val;
            end,
        },
        {
            type = "select",
            label = L["CO_FONT_OUTLINE"],
            desc = L["CO_FONT_OUTLINE_DESC"],
            values = CraftingOrders._getOutlineValues,
            disabled = notifyDisabled,
            get = function() return db.personalFontOutline or "OUTLINE"; end,
            set = function(val)
                db.personalFontOutline = val;
            end,
        },
        {
            type = "color",
            label = L["CO_TEXT_COLOR"],
            desc = L["CO_TEXT_COLOR_DESC"],
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
            label = L["CO_DURATION"],
            desc = L["CO_DURATION_DESC"],
            min = 1, max = 15, step = 1, default = 5,
            disabled = notifyDisabled,
            get = function() return db.personalDuration or 5; end,
            set = function(val)
                db.personalDuration = val;
            end,
        },
        {
            type = "execute",
            label = L["CO_TEST_NOTIFICATION"],
            desc = L["CO_TEST_NOTIFICATION_DESC"],
            disabled = notifyDisabled,
            func = function()
                CraftingOrders:OutputMessage(CraftingOrders._formatPersonalOrderMessage());
                CraftingOrders._playPersonalSound();
            end,
        },

        -----------------------------------------------------------------------
        -- Crafting Window
        -----------------------------------------------------------------------
        { type = "header", text = L["CO_CRAFTING_WINDOW_HEADER"] },
        {
            type = "toggle",
            label = L["CO_SHOW_WHISPER_BTN"],
            desc = L["CO_SHOW_WHISPER_BTN_DESC"],
            get = function() return db.enableWhisperButton; end,
            set = function(val)
                db.enableWhisperButton = val and true or false;
                CraftingOrders:UpdateWhisperButton();
                refreshPage();
            end,
        },
        {
            type = "input",
            label = L["CO_WHISPER_MESSAGE"],
            desc = L["CO_WHISPER_MESSAGE_DESC"],
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
    { key = "craftingorders_guild",    opts = { label = L["CO_PAGE_GUILD"],    title = L["CO_PAGE_GUILD_TITLE"],    description = L["CO_PAGE_GUILD_DESC"],    widgets = guildWidgets } },
    { key = "craftingorders_personal", opts = { label = L["CO_PAGE_PERSONAL"], title = L["CO_PAGE_PERSONAL_TITLE"], description = L["CO_PAGE_PERSONAL_DESC"], widgets = personalWidgets } },
};
