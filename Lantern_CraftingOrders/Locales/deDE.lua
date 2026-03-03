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
    -- CO_SOUND_BACKGROUND                          = "Play when game is in background",
    -- CO_SOUND_BACKGROUND_DESC                     = "Temporarily enables background sound so the notification is audible even when the game is not in focus.",

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

    ---------------------------------------------------------------------------
    -- Analytics
    ---------------------------------------------------------------------------

    -- CO_ANALYTICS_TITLE                           = "Crafting Orders Analytics",
    -- CO_ANALYTICS_BTN                             = "Analytics",
    -- CO_ANALYTICS_BTN_DESC                        = "Open crafting order analytics.",

    -- Tabs
    -- CO_TAB_CUSTOMERS                             = "Customers",
    -- CO_TAB_ITEMS                                 = "Items",
    -- CO_TAB_DASHBOARD                             = "Dashboard",
    -- CO_TAB_ORDERS                                = "Orders",
    -- CO_TAB_FILTERS                               = "Filters",

    -- Column headers
    -- CO_COL_CUSTOMER                              = "Customer",
    -- CO_COL_ORDERS                                = "Orders",
    -- CO_COL_TOTAL_TIPS                            = "Total Tips",
    -- CO_COL_AVG_TIP                               = "Avg Tip",
    -- CO_COL_LAST_ORDER                            = "Last Order",
    -- CO_COL_ITEM                                  = "Item",
    -- CO_COL_CRAFTS                                = "Crafts",
    -- CO_COL_REVENUE                               = "Revenue",
    -- CO_COL_CUSTOMERS                             = "Customers",
    -- CO_COL_TIP                                   = "Tip",
    -- CO_COL_TYPE                                  = "Type",
    -- CO_COL_DATE                                  = "Date",

    -- Dashboard
    -- CO_DASH_TOTAL_ORDERS                         = "Total Orders",
    -- CO_DASH_TOTAL_TIPS                           = "Total Tips Earned",
    -- CO_DASH_AVG_TIP                              = "Average Tip",
    -- CO_DASH_THIS_WEEK                            = "This Week",
    -- CO_DASH_THIS_MONTH                           = "This Month",
    -- CO_DASH_TOP_CUSTOMERS                        = "Top 5 Customers",
    -- CO_DASH_TOP_ITEMS                            = "Top 5 Items",
    -- CO_DASH_NO_DATA                              = "No orders recorded yet.",

    -- Orders page
    -- CO_ORDERS_REMOVE                             = "Remove",

    -- Filters page
    -- CO_FILTERS_DESC                              = "Excluded customers are hidden from all analytics pages.",
    -- CO_FILTERS_ADD                               = "Add",
    -- CO_FILTERS_REMOVE                            = "Remove",
    -- CO_FILTERS_EMPTY                             = "No customers excluded.",

    -- Character filter
    -- CO_FILTER_CURRENT                            = "Current Character",
    -- CO_FILTER_ALL                                = "All Characters",

    -- Time formatting
    -- CO_TIME_JUST_NOW                             = "Just now",
    -- CO_TIME_MINUTES_AGO                          = "%dm ago",
    -- CO_TIME_HOURS_AGO                            = "%dh ago",
    -- CO_TIME_DAYS_AGO                             = "%dd ago",

    -- Settings: Order History section
    -- CO_HISTORY_HEADER                            = "Order History",
    -- CO_TRACK_HISTORY                             = "Track order history",
    -- CO_TRACK_HISTORY_DESC                        = "Record fulfilled crafting orders for analytics.",
    -- CO_HISTORY_COUNT                             = "%d orders recorded.",
    -- CO_OPEN_ANALYTICS                            = "Open Analytics",
    -- CO_OPEN_ANALYTICS_DESC                       = "Open the crafting orders analytics window.",
    -- CO_CLEAR_HISTORY                             = "Clear History",
    -- CO_CLEAR_HISTORY_DESC                        = "Delete all recorded order history for the current character.",
    -- CO_CLEAR_HISTORY_CONFIRM                     = "Are you sure you want to delete all order history for this character? This cannot be undone.",
    -- CO_MAX_ORDERS                                = "Max orders to keep",
    -- CO_MAX_ORDERS_DESC                           = "Maximum number of orders to store per character. Oldest orders are removed first.",

    -- Repeat customer indicator
    -- CO_REPEAT_CUSTOMER                           = "Repeat",
    -- CO_NEW_CUSTOMER                              = "New",
});
