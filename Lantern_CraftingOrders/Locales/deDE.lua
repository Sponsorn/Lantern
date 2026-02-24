local ADDON_NAME, ns = ...;
ns:RegisterLocale("deDE", {

    -- Shared
    -- ENABLE                                      = "Enable",

    ---------------------------------------------------------------------------
    -- Module metadata (CraftingOrders.lua)
    ---------------------------------------------------------------------------

    -- CO_TITLE                                    = "Crafting Orders",
    -- CO_DESC                                     = "Notify about guild crafting order placements and completions.",

    ---------------------------------------------------------------------------
    -- CraftingOrders.lua: format helpers
    ---------------------------------------------------------------------------

    -- CO_COMMISSION_PREFIX                         = ", commission: ",
    -- CO_PERSONAL_ORDER_MSG                        = "New personal crafting order received.",
    -- CO_COMPLETE_WHISPER_BTN                      = "Complete + Whisper",
    -- CO_MSG_DEBUG_UNLOCKED                        = "Crafting Orders: debug options unlocked.",
    -- CO_MSG_DEBUG_WOULD_SEND                      = "Crafting Orders: would have sent: %s",
    -- CO_MSG_FALLBACK_PRINT                        = "Crafting Orders: %s",

    ---------------------------------------------------------------------------
    -- CraftingOrders.lua: Outline values
    ---------------------------------------------------------------------------

    -- CO_OUTLINE_NONE                              = "None",
    -- CO_OUTLINE_OUTLINE                           = "Outline",
    -- CO_OUTLINE_THICK                             = "Thick Outline",
    -- CO_OUTLINE_MONO                              = "Monochrome",
    -- CO_OUTLINE_OUTLINE_MONO                      = "Outline + Monochrome",

    ---------------------------------------------------------------------------
    -- WidgetOptions.lua: Guild Orders page
    ---------------------------------------------------------------------------

    -- CO_GUILD_DESCRIPTION                         = "Automatically announce guild crafting orders in guild chat when you place or fulfill them.",
    -- CO_GUILD_ORDERS_BTN                          = "Guild Orders",
    -- CO_GUILD_ORDERS_BTN_DESC                     = "Click 5 times to unlock debug.",

    -- Order Placed section
    -- CO_ORDER_PLACED_HEADER                       = "Order Placed",
    -- CO_ANNOUNCE_PLACED                           = "Announce placed orders",
    -- CO_ANNOUNCE_PLACED_DESC                      = "Post a message in guild chat when you place a guild crafting order.",
    -- CO_MESSAGE_FORMAT                            = "Message format",
    -- CO_PLACED_FORMAT_DESC                        = "Tags: {item} {tip}",
    -- CO_PREVIEW_PREFIX                            = "Preview: ",

    -- Order Fulfilled section
    -- CO_ORDER_FULFILLED_HEADER                    = "Order Fulfilled",
    -- CO_ANNOUNCE_FULFILLED                        = "Announce fulfilled orders",
    -- CO_ANNOUNCE_FULFILLED_DESC                   = "Post a message in guild chat when you fulfill a guild crafting order.",
    -- CO_FULFILLED_FORMAT_DESC                     = "Tags: {item} {who} {tip}",

    -- Debug toggle
    -- CO_DEBUG_LABEL                               = "Debug (print only)",
    -- CO_DEBUG_DESC                                = "When enabled, guild messages are printed to chat instead of being sent.",

    -- Tag Details section
    -- CO_TAG_DETAILS_HEADER                        = "Tag Details",
    -- CO_TAG_DETAILS_TEXT                           = "{item} = item link\n{who} = customer name\n{tip} = commission",

    ---------------------------------------------------------------------------
    -- WidgetOptions.lua: Personal Orders page
    ---------------------------------------------------------------------------

    -- CO_PERSONAL_DESCRIPTION                      = "Get notified when you receive personal crafting orders.",

    -- Personal Order Received section
    -- CO_PERSONAL_RECEIVED_HEADER                  = "Personal Order Received",
    -- CO_ENABLE_NOTIFICATION                       = "Enable notification",
    -- CO_ENABLE_NOTIFICATION_DESC                  = "Show a notification when you receive a personal crafting order.",

    -- Sound section
    -- CO_SOUND_HEADER                              = "Sound",
    -- CO_PLAY_SOUND                                = "Play sound",
    -- CO_PLAY_SOUND_DESC                           = "Play a sound when a personal crafting order is received.",
    -- CO_SOUND_SELECT                              = "Sound",
    -- CO_SOUND_SELECT_DESC                         = "Sound to play when a personal crafting order is received. Click the speaker icon to preview.",

    -- Notification Appearance section
    -- CO_APPEARANCE_HEADER                         = "Notification Appearance",
    -- CO_FONT                                      = "Font",
    -- CO_FONT_DESC                                 = "Font used for the notification text.",
    -- CO_FONT_SIZE                                 = "Font size",
    -- CO_FONT_SIZE_DESC                            = "Size of the notification text.",
    -- CO_FONT_OUTLINE                              = "Font outline",
    -- CO_FONT_OUTLINE_DESC                         = "Outline style for the notification text.",
    -- CO_TEXT_COLOR                                 = "Text color",
    -- CO_TEXT_COLOR_DESC                            = "Color of the notification text.",
    -- CO_DURATION                                  = "Duration",
    -- CO_DURATION_DESC                             = "How long the notification is shown (seconds).",
    -- CO_TEST_NOTIFICATION                         = "Test notification",
    -- CO_TEST_NOTIFICATION_DESC                    = "Show a test notification with the current settings.",

    -- Crafting Window section
    -- CO_CRAFTING_WINDOW_HEADER                    = "Crafting Window",
    -- CO_SHOW_WHISPER_BTN                          = "Show Complete + Whisper button",
    -- CO_SHOW_WHISPER_BTN_DESC                     = "Add a button to the crafting order view that completes the order and whispers the customer.",
    -- CO_WHISPER_MESSAGE                           = "Whisper message",
    -- CO_WHISPER_MESSAGE_DESC                      = "Use {name} and {item} as placeholders.",

    ---------------------------------------------------------------------------
    -- WidgetOptions.lua: uxPages registration
    ---------------------------------------------------------------------------

    -- CO_PAGE_GUILD                                = "Guild Orders",
    -- CO_PAGE_GUILD_TITLE                          = "Guild Orders",
    -- CO_PAGE_GUILD_DESC                           = "Announce guild crafting orders.",
    -- CO_PAGE_PERSONAL                             = "Personal Orders",
    -- CO_PAGE_PERSONAL_TITLE                       = "Personal Orders",
    -- CO_PAGE_PERSONAL_DESC                        = "Personal order notifications.",
});
