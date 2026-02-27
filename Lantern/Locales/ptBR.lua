local ADDON_NAME, Lantern = ...;
Lantern:RegisterLocale("ptBR", {

    -- Shared
    -- ENABLE                                  = "Enable",
    -- SHARED_FONT                             = "Font",
    -- SHARED_FONT_SIZE                        = "Font Size",
    -- SHARED_FONT_OUTLINE                     = "Font Outline",
    -- SHARED_FONT_COLOR                       = "Font Color",
    -- SHARED_GROUP_POSITION                   = "Position",
    -- SHARED_LOCK_POSITION                    = "Lock Position",
    -- SHARED_RESET_POSITION                   = "Reset Position",
    -- SHARED_GROUP_SOUND                      = "Sound",
    -- SHARED_SOUND_SELECT                     = "Sound",
    -- SHARED_PLAY_SOUND                       = "Play Sound",
    -- SHARED_PREVIEW                          = "Preview",
    -- SHARED_GROUP_DISPLAY                    = "Display",
    -- SHARED_ANIMATION_STYLE                  = "Animation Style",

    -- General settings
    -- GENERAL_MINIMAP_SHOW                    = "Show minimap icon",
    -- GENERAL_MINIMAP_SHOW_DESC               = "Show or hide the Lantern minimap button.",
    -- GENERAL_MINIMAP_MODERN                  = "Modern minimap icon",
    -- GENERAL_MINIMAP_MODERN_DESC             = "Remove the border and background from the minimap button for a modern look with a lantern glow on hover.",
    -- GENERAL_PAUSE_MODIFIER                  = "Pause modifier key",
    -- GENERAL_PAUSE_MODIFIER_DESC             = "Hold this key to temporarily pause auto-features (Auto Quest, Auto Queue, Auto Repair, etc.).",

    -- Modifier values (used in dropdowns)
    -- MODIFIER_SHIFT                          = "Shift",
    -- MODIFIER_CTRL                           = "Ctrl",
    -- MODIFIER_ALT                            = "Alt",

    -- Delete Confirm
    -- DELETECONFIRM_ENABLE_DESC               = "Replace typing DELETE with a confirm button (Shift pauses).",

    -- Disable Auto Add Spells
    -- DISABLEAUTOADD_ENABLE_DESC              = "Disable auto-adding spells to the action bar.",

    -- Auto Queue
    -- AUTOQUEUE_ENABLE_DESC                   = "Enable or disable Auto Queue.",
    -- AUTOQUEUE_AUTO_ACCEPT                   = "Auto-accept role checks",
    -- AUTOQUEUE_AUTO_ACCEPT_DESC              = "Accept LFG role checks automatically.",
    -- AUTOQUEUE_ANNOUNCE                      = "Chat announce",
    -- AUTOQUEUE_ANNOUNCE_DESC                 = "Print a chat message when a role check is auto-accepted.",
    -- AUTOQUEUE_CALLOUT                       = "Hold %s to temporarily pause. Roles are set in the LFG tool.",

    -- Faster Loot
    -- FASTERLOOT_ENABLE_DESC                  = "Instantly collect all loot when a loot window opens. Hold %s to pause.",

    -- Auto Keystone
    -- AUTOKEYSTONE_ENABLE_DESC                = "Auto-slot your keystone when opening the M+ UI. Hold %s to skip.",

    -- Release Protection
    -- RELEASEPROTECT_ENABLE_DESC              = "Require holding %s to release spirit (prevents accidental release).",
    -- RELEASEPROTECT_SKIP_SOLO                = "Skip when solo",
    -- RELEASEPROTECT_SKIP_SOLO_DESC           = "Disable protection when you are not in a group.",
    -- RELEASEPROTECT_ACTIVE_IN                = "Active in",
    -- RELEASEPROTECT_ACTIVE_IN_DESC           = "Always: protection everywhere. All instances: only inside dungeons, raids, and PvP. Custom: choose specific instance types.",
    -- RELEASEPROTECT_MODE_ALWAYS              = "Always",
    -- RELEASEPROTECT_MODE_INSTANCES           = "All instances",
    -- RELEASEPROTECT_MODE_CUSTOM              = "Custom",
    -- RELEASEPROTECT_HOLD_DURATION            = "Hold duration",
    -- RELEASEPROTECT_HOLD_DURATION_DESC       = "How long you need to hold the modifier key before the release button becomes active.",
    -- RELEASEPROTECT_INSTANCE_TYPES           = "Instance Types",
    -- RELEASEPROTECT_OPEN_WORLD               = "Open World",
    -- RELEASEPROTECT_OPEN_WORLD_DESC          = "Protect in the open world (not inside any instance).",
    -- RELEASEPROTECT_DUNGEONS                 = "Dungeons",
    -- RELEASEPROTECT_DUNGEONS_DESC            = "Protect in normal, heroic, and mythic dungeons.",
    -- RELEASEPROTECT_MYTHICPLUS               = "Mythic+",
    -- RELEASEPROTECT_MYTHICPLUS_DESC          = "Protect in Mythic+ keystones.",
    -- RELEASEPROTECT_RAIDS                    = "Raids",
    -- RELEASEPROTECT_RAIDS_DESC               = "Protect in all raid difficulties (LFR, Normal, Heroic, Mythic).",
    -- RELEASEPROTECT_SCENARIOS                = "Scenarios",
    -- RELEASEPROTECT_SCENARIOS_DESC           = "Protect in scenario instances.",
    -- RELEASEPROTECT_DELVES                   = "Delves",
    -- RELEASEPROTECT_DELVES_DESC              = "Protect in Delves.",
    -- RELEASEPROTECT_ARENAS                   = "Arenas",
    -- RELEASEPROTECT_ARENAS_DESC              = "Protect in PvP arenas.",
    -- RELEASEPROTECT_BATTLEGROUNDS            = "Battlegrounds",
    -- RELEASEPROTECT_BATTLEGROUNDS_DESC       = "Protect in PvP battlegrounds.",

    -- Auto Repair
    -- AUTOREPAIR_ENABLE_DESC                  = "Enable or disable Auto Repair.",
    -- AUTOREPAIR_SOURCE                       = "Repair source",
    -- AUTOREPAIR_SOURCE_DESC                  = "Personal gold: always use your own gold. Guild funds first: try guild bank, fall back to personal. Guild funds only: only use guild bank (warns if unavailable).",
    -- AUTOREPAIR_SOURCE_PERSONAL              = "Personal gold",
    -- AUTOREPAIR_SOURCE_GUILD_FIRST           = "Guild funds first",
    -- AUTOREPAIR_SOURCE_GUILD_ONLY            = "Guild funds only",
    -- AUTOREPAIR_CALLOUT                      = "Hold %s when opening a vendor to skip auto-repair.",

    -- Splash page
    -- SPLASH_DESC                             = "A modular quality-of-life addon for World of Warcraft.\nClick a module name to configure it, or click a status dot to toggle it.",
    -- SPLASH_ENABLED                          = "Enabled",
    -- SPLASH_DISABLED                         = "Disabled",
    -- SPLASH_CLICK_ENABLE                     = "Click to enable",
    -- SPLASH_CLICK_DISABLE                    = "Click to disable",
    -- SPLASH_COMPANION_HEADER                 = "Companion Addons",
    -- SPLASH_CURSEFORGE                       = "CurseForge",
    -- SPLASH_COPY_LINK                        = "Copy link",
    -- SPLASH_COPY_HINT                        = "Ctrl+C to copy, Escape to close",
    -- COPY                                    = "Copy",
    -- SELECT                                  = "Select",

    -- Companion addon descriptions
    -- COMPANION_CO_LABEL                      = "Crafting Orders",
    -- COMPANION_CO_DESC                       = "Announces guild order activity, personal order alerts, and a Complete + Whisper button.",
    -- COMPANION_WARBAND_LABEL                 = "Warband",
    -- COMPANION_WARBAND_DESC                  = "Organize characters into groups with automated gold balancing to/from warbank when opening a bank.",

    -- Section headers
    -- SECTION_MODULES                         = "Modules",
    -- SECTION_ADDONS                          = "Addons",

    -- General settings page
    -- SECTION_GENERAL                         = "General",
    -- SECTION_GENERAL_DESC                    = "Core addon settings.",

    -- Sidebar page labels
    -- PAGE_HOME                               = "Home",

    -- Category headers
    -- CATEGORY_GENERAL                        = "General",
    -- CATEGORY_DUNGEONS                       = "Dungeons & M+",
    -- CATEGORY_QUESTING                       = "Questing & World",

    -- Messages (Options.lua / ui.lua)
    -- MSG_OPTIONS_AFTER_COMBAT                = "Options will open after combat.",

    -- ui.lua: Minimap tooltip
    -- UI_MINIMAP_TITLE                        = "Lantern",
    -- UI_MINIMAP_LEFT_CLICK                   = "Left-click: Open options",
    -- UI_MINIMAP_SHIFT_CLICK                  = "Shift+Left-click: Reload UI",

    -- ui.lua: StaticPopup link dialog
    -- UI_COPY_LINK_PROMPT                     = "CTRL-C to copy link",

    -- ui.lua: Blizzard Settings stub
    -- UI_SETTINGS_VERSION                     = "Version: %s",
    -- UI_SETTINGS_AUTHOR                      = "Author: Dede in-game / Sponsorn on curseforge & github",
    -- UI_SETTINGS_THANKS                      = "Special Thanks to copyrighters for making me pull my thumb out.",
    -- UI_SETTINGS_OPEN                        = "Open Settings",
    -- UI_SETTINGS_AVAILABLE_MODULES           = "Available modules",
    -- UI_SETTINGS_CO_DESC                     = "Crafting Orders: announces guild order activity, personal order alerts, and a Complete + Whisper button.",
    -- UI_SETTINGS_ALREADY_ENABLED             = "Already enabled",
    -- UI_SETTINGS_WARBAND_DESC                = "Warband: organize characters into groups with automated gold balancing to/from warbank when opening a bank.",

    -- core.lua: Slash command
    -- MSG_MISSINGPET_NOT_FOUND                = "MissingPet module not found.",

    ---------------------------------------------------------------------------
    -- Phase 3: Module Metadata (title/desc)
    ---------------------------------------------------------------------------

    -- Auto Quest
    -- AUTOQUEST_TITLE                         = "Auto Quest",
    -- AUTOQUEST_DESC                          = "Automatically accept and turn-in quests.",

    -- Auto Queue
    -- AUTOQUEUE_TITLE                         = "Auto Queue",
    -- AUTOQUEUE_DESC                          = "Automatically accept role checks using your LFG role selection.",

    -- Auto Repair
    -- AUTOREPAIR_TITLE                        = "Auto Repair",
    -- AUTOREPAIR_DESC                         = "Automatically repair gear at merchants.",

    -- Auto Sell
    -- AUTOSELL_TITLE                          = "Auto Sell",
    -- AUTOSELL_DESC                           = "Automatically sell junk and custom-listed items at merchants.",

    -- Chat Filter
    -- CHATFILTER_TITLE                        = "Chat Filter",
    -- CHATFILTER_DESC                         = "Filters gold spam, boost ads, and unwanted messages from whispers and public channels.",

    -- Cursor Ring
    -- CURSORRING_TITLE                        = "Cursor Ring & Trail",
    -- CURSORRING_DESC                         = "Displays customizable ring(s) around the mouse cursor with cast/GCD indicators and an optional trail.",

    -- Delete Confirm
    -- DELETECONFIRM_TITLE                     = "Delete Confirm",
    -- DELETECONFIRM_DESC                      = "Hide delete input and enable the confirm button.",

    -- Disable Auto Add Spells
    -- DISABLEAUTOADD_TITLE                    = "Disable Auto Add Spells",
    -- DISABLEAUTOADD_DESC                     = "Stops spells from auto-adding to action bars.",

    -- Missing Pet
    -- MISSINGPET_TITLE                        = "Missing Pet",
    -- MISSINGPET_DESC                         = "Displays a warning when your pet is missing or set to passive.",

    -- Auto Playstyle
    -- AUTOPLAYSTYLE_TITLE                     = "Auto Playstyle",
    -- AUTOPLAYSTYLE_DESC                      = "Auto-selects your preferred playstyle when listing M+ groups in the Group Finder.",

    -- Faster Loot
    -- FASTERLOOT_TITLE                        = "Faster Loot",
    -- FASTERLOOT_DESC                         = "Instantly collect all loot when a loot window opens.",

    -- Auto Keystone
    -- AUTOKEYSTONE_TITLE                      = "Auto Keystone",
    -- AUTOKEYSTONE_DESC                       = "Automatically slot your Mythic+ keystone when the Challenge Mode UI opens.",

    -- Release Protection
    -- RELEASEPROTECT_TITLE                    = "Release Protection",
    -- RELEASEPROTECT_DESC                     = "Require holding your pause modifier before releasing spirit to prevent accidental clicks.",

    -- Combat Timer
    -- COMBATTIMER_TITLE                       = "Combat Timer",
    -- COMBATTIMER_DESC                        = "Display a timer showing how long you've been in combat.",

    -- Combat Alert
    -- COMBATALERT_TITLE                       = "Combat Alert",
    -- COMBATALERT_DESC                        = "Show a fade-in/out text alert when entering or leaving combat.",

    -- Range Check
    -- RANGECHECK_TITLE                        = "Range Check",
    -- RANGECHECK_DESC                         = "Display in-range or out-of-range status for your current target.",

    -- Tooltip
    -- TOOLTIP_TITLE                           = "Tooltip",
    -- TOOLTIP_DESC                            = "Enhances tooltips with IDs and mount names.",

    -- Item Info
    -- ITEMINFO_TITLE                          = "Item Info",
    -- ITEMINFO_DESC                           = "Shows item level, missing enchants, and gem sockets on equipment and bags.",
    -- ITEMINFO_ENABLE_DESC                    = "Enable the Item Info module.",
    -- ITEMINFO_SHOW_ILVL_CHARACTER            = "Item Level (Character)",
    -- ITEMINFO_SHOW_ILVL_CHARACTER_DESC       = "Show item level on equipment slots in the character and inspect panels.",
    -- ITEMINFO_SHOW_ILVL_BAGS                 = "Item Level (Bags)",
    -- ITEMINFO_SHOW_ILVL_BAGS_DESC            = "Show item level on equipment in bags, loot, bank, and equipment flyout.",
    -- ITEMINFO_SHOW_MISSING_ENCHANTS          = "Missing Enchants",
    -- ITEMINFO_SHOW_MISSING_ENCHANTS_DESC     = "Show a red indicator on equipment slots that are missing an enchant at max level.",
    -- ITEMINFO_SHOW_MISSING_GEMS              = "Missing Gems",
    -- ITEMINFO_SHOW_MISSING_GEMS_DESC         = "Show a red indicator on equipment slots that have empty gem sockets.",
    -- ITEMINFO_UPGRADE_ARROW                  = "Upgrade Arrow",
    -- ITEMINFO_UPGRADE_ARROW_DESC             = "Show a green arrow on bag items that are an upgrade over your currently equipped gear.",

    ---------------------------------------------------------------------------
    -- Phase 3: Module Print Messages
    ---------------------------------------------------------------------------

    -- Auto Queue messages
    -- AUTOQUEUE_MSG_ACCEPTED                  = "Auto-accepted role check.",

    -- Auto Repair messages
    -- AUTOREPAIR_MSG_GUILD_UNAVAILABLE        = "Cannot repair: guild funds unavailable.",
    -- AUTOREPAIR_MSG_REPAIRED_GUILD           = "Repaired for %s (guild funds).",
    -- AUTOREPAIR_MSG_REPAIRED                 = "Repaired for %s.",
    -- AUTOREPAIR_MSG_NOT_ENOUGH_GOLD          = "Cannot repair: not enough gold (%s needed).",

    -- Auto Sell messages
    -- AUTOSELL_MSG_SOLD_ITEMS                 = "Sold %d item(s) for %s.",

    -- Faster Loot messages
    -- FASTERLOOT_MSG_INV_FULL                 = "Inventory is full - some items could not be looted.",

    -- Chat Filter messages
    -- CHATFILTER_MSG_ACTIVE                   = "Chat Filter active with %d keywords.",
    -- CHATFILTER_MSG_KEYWORD_EXISTS           = "Keyword already in filter list.",
    -- CHATFILTER_MSG_KEYWORD_ADDED            = "Added \"%s\" to chat filter.",

    -- Auto Sell item messages
    -- AUTOSELL_MSG_ALREADY_IN_LIST            = "Item already in sell list.",
    -- AUTOSELL_MSG_ADDED_TO_LIST              = "Added %s to sell list.",
    -- AUTOSELL_MSG_INVALID_ITEM_ID            = "Invalid item ID.",

    -- Tooltip messages
    -- TOOLTIP_MSG_ID_COPIED                   = "%s %s copied.",

    -- Release Protection overlay text
    -- RELEASEPROTECT_HOLD_PROGRESS            = "Hold %s... %.1fs",
    -- RELEASEPROTECT_HOLD_PROMPT              = "Hold %s (%.1fs)",

    -- Auto Quest messages
    -- AUTOQUEST_MSG_NO_NPC                    = "No NPC found. Talk to an NPC first.",
    -- AUTOQUEST_MSG_BLOCKED_NPC               = "Blocked NPC: %s",

    ---------------------------------------------------------------------------
    -- Phase 3: AutoQuest WidgetOptions
    ---------------------------------------------------------------------------

    -- AUTOQUEST_ENABLE_DESC                   = "Enable or disable Auto Quest.",
    -- AUTOQUEST_AUTO_ACCEPT                   = "Auto-accept quests",
    -- AUTOQUEST_AUTO_ACCEPT_DESC              = "Automatically accept quests from NPCs.",
    -- AUTOQUEST_AUTO_TURNIN                   = "Auto turn-in quests",
    -- AUTOQUEST_AUTO_TURNIN_DESC              = "Automatically turn in completed quests to NPCs.",
    -- AUTOQUEST_SINGLE_REWARD                 = "Auto select single reward",
    -- AUTOQUEST_SINGLE_REWARD_DESC            = "If a quest offers only one reward, auto-select it.",
    -- AUTOQUEST_SINGLE_GOSSIP                 = "Auto-select single dialog option",
    -- AUTOQUEST_SINGLE_GOSSIP_DESC            = "Automatically select NPCs with only one dialog option to progress through dialog chains leading to quests.",
    -- AUTOQUEST_SKIP_TRIVIAL                  = "Skip trivial quests",
    -- AUTOQUEST_SKIP_TRIVIAL_DESC             = "Don't auto-accept quests that are gray (trivial/low-level).",
    -- AUTOQUEST_CALLOUT                       = "Hold %s to temporarily pause auto-accept and auto turn-in.",
    -- AUTOQUEST_ADDON_BYPASS_NOTE             = "Note: other quest automation addons (QuickQuest, Plumber, etc.) may bypass the blocklist.",
    -- AUTOQUEST_ADD_NPC                       = "Add current NPC to blocklist",
    -- AUTOQUEST_ADD_NPC_DESC                  = "Talk to an NPC, then click this button to block them from auto-quest automation.",
    -- AUTOQUEST_ZONE_FILTER                   = "Zone filter",
    -- AUTOQUEST_NPC_ZONE_FILTER_DESC          = "Filter blocked NPCs by zone.",
    -- AUTOQUEST_QUEST_ZONE_FILTER_DESC        = "Filter blocked quests by zone.",
    -- AUTOQUEST_ZONE_ALL                      = "All zones",
    -- AUTOQUEST_ZONE_CURRENT                  = "Current zone",
    -- AUTOQUEST_BLOCKED_NPCS                  = "Blocked NPCs (%d)",
    -- AUTOQUEST_NPC_EMPTY_ALL                 = "No NPCs blocked yet -- target an NPC and click the button above to add one.",
    -- AUTOQUEST_NPC_EMPTY_ZONE                = "No NPCs blocked in %s.",
    -- AUTOQUEST_REMOVE_NPC_DESC               = "Remove %s from the blocklist.",
    -- AUTOQUEST_BLOCKED_QUESTS_HEADER         = "Blocked Quests",
    -- AUTOQUEST_BLOCKED_QUESTS_NOTE           = "Blocked quests won't be auto-accepted or auto-turned in.",
    -- AUTOQUEST_QUEST_EMPTY_ALL               = "No quests blocked yet -- quests auto-accepted from blocked NPCs will appear here.",
    -- AUTOQUEST_QUEST_EMPTY_ZONE              = "No quests blocked in %s.",
    -- AUTOQUEST_UNKNOWN_NPC                   = "Unknown NPC",
    -- AUTOQUEST_QUEST_LABEL_WITH_ID           = "%s (ID: %s)",
    -- AUTOQUEST_QUEST_LABEL_ID_ONLY           = "Quest ID: %s",
    -- AUTOQUEST_UNBLOCK_DESC                  = "Unblock this quest.",
    -- AUTOQUEST_BLOCK_QUEST                   = "Block Quest",
    -- AUTOQUEST_BLOCKED                       = "Blocked",
    -- AUTOQUEST_BLOCK_DESC                    = "Block this quest from future automation.",
    -- AUTOQUEST_NPC_PREFIX                    = "NPC: %s",
    -- AUTOQUEST_NO_AUTOMATED                  = "No automated quests yet.",
    -- AUTOQUEST_RECENT_AUTOMATED              = "Recent automated quests (%d)",

    ---------------------------------------------------------------------------
    -- Phase 3: AutoSell WidgetOptions
    ---------------------------------------------------------------------------

    -- AUTOSELL_ENABLE_DESC                    = "Enable or disable Auto Sell.",
    -- AUTOSELL_SELL_GRAYS                     = "Sell gray items",
    -- AUTOSELL_SELL_GRAYS_DESC                = "Automatically sell all poor quality (gray) items.",
    -- AUTOSELL_CALLOUT                        = "Hold %s when opening a vendor to skip auto-sell.",
    -- AUTOSELL_DRAG_DROP                      = "Drag and drop:",
    -- AUTOSELL_DRAG_GLOBAL_DESC               = "Drag an item from your bags and drop it here to add it to the global sell list.",
    -- AUTOSELL_DRAG_CHAR_DESC                 = "Drag an item from your bags and drop it here to add it to this character's sell list.",
    -- AUTOSELL_ITEM_ID                        = "Item ID",
    -- AUTOSELL_ITEM_ID_GLOBAL_DESC            = "Enter an item ID to add to the global sell list.",
    -- AUTOSELL_ITEM_ID_CHAR_DESC              = "Enter an item ID to add to this character's sell list.",
    -- AUTOSELL_REMOVE_DESC                    = "Remove this item from the sell list.",
    -- AUTOSELL_GLOBAL_LIST                    = "Global Sell List (%d)",
    -- AUTOSELL_CHAR_LIST                      = "%s Sell List (%d)",
    -- AUTOSELL_CHAR_ONLY_NOTE                 = "Items in this list are only sold on this character.",
    -- AUTOSELL_EMPTY_GLOBAL                   = "No items in global sell list.",
    -- AUTOSELL_EMPTY_CHAR                     = "No items in character sell list.",

    ---------------------------------------------------------------------------
    -- Phase 3: CursorRing WidgetOptions
    ---------------------------------------------------------------------------

    -- CURSORRING_ENABLE_DESC                  = "Enable or disable the Cursor Ring & Trail module.",
    -- CURSORRING_PREVIEW_START                = "Start Preview",
    -- CURSORRING_PREVIEW_STOP                 = "Stop Preview",
    -- CURSORRING_PREVIEW_DESC                 = "Show all visual elements on the cursor for real-time editing. Automatically disables when the settings panel is closed.",
    -- CURSORRING_GROUP_GENERAL                = "General",
    -- CURSORRING_SHOW_OOC                     = "Show Out of Combat",
    -- CURSORRING_SHOW_OOC_DESC                = "Show the cursor ring outside of combat and instances.",
    -- CURSORRING_COMBAT_OPACITY               = "Combat Opacity",
    -- CURSORRING_COMBAT_OPACITY_DESC          = "Ring opacity while in combat or instanced content.",
    -- CURSORRING_OOC_OPACITY                  = "Out of Combat Opacity",
    -- CURSORRING_OOC_OPACITY_DESC             = "Ring opacity outside of combat.",
    -- CURSORRING_GROUP_RING1                  = "Ring 1 (Outer)",
    -- CURSORRING_ENABLE_RING1                 = "Enable Ring 1",
    -- CURSORRING_ENABLE_RING1_DESC            = "Show the outer ring.",
    -- CURSORRING_SHAPE                        = "Shape",
    -- CURSORRING_RING_SHAPE_DESC              = "Ring shape.",
    -- CURSORRING_SHwPE_CIRCLE                 = "Circle",
    -- CURSORRING_SHAPE_THIN                   = "Thin Circle",
    -- CURSORRING_COLOR                        = "Color",
    -- CURSORRING_RING1_COLOR_DESC             = "Ring 1 color.",
    -- CURSORRING_SIZE                         = "Size",
    -- CURSORRING_RING1_SIZE_DESC              = "Ring 1 size in pixels.",
    -- CURSORRING_GROUP_RING2                  = "Ring 2 (Inner)",
    -- CURSORRING_ENABLE_RING2                 = "Enable Ring 2",
    -- CURSORRING_ENABLE_RING2_DESC            = "Show the inner ring.",
    -- CURSORRING_RING2_COLOR_DESC             = "Ring 2 color.",
    -- CURSORRING_RING2_SIZE_DESC              = "Ring 2 size in pixels.",
    -- CURSORRING_GROUP_DOT                    = "Center Dot",
    -- CURSORRING_ENABLE_DOT                   = "Enable Dot",
    -- CURSORRING_ENABLE_DOT_DESC              = "Show a small dot at the center of the cursor rings.",
    -- CURSORRING_DOT_COLOR_DESC               = "Dot color.",
    -- CURSORRING_DOT_SIZE_DESC                = "Dot size in pixels.",
    -- CURSORRING_GROUP_CAST                   = "Cast Effect",
    -- CURSORRING_ENABLE_CAST                  = "Enable Cast Effect",
    -- CURSORRING_ENABLE_CAST_DESC             = "Show a visual effect during spell casting and channeling.",
    -- CURSORRING_STYLE                        = "Style",
    -- CURSORRING_CAST_STYLE_DESC              = "Segments: arc lights up progressively. Fill: shape scales from center. Swipe: cooldown sweep (can run simultaneously with GCD).",
    -- CURSORRING_STYLE_SEGMENTS               = "Segments",
    -- CURSORRING_STYLE_FILL                   = "Fill",
    -- CURSORRING_STYLE_SWIPE                  = "Swipe",
    -- CURSORRING_CAST_COLOR_DESC              = "Cast effect color.",
    -- CURSORRING_SWIPE_OFFSET                 = "Swipe Offset",
    -- CURSORRING_SWIPE_OFFSET_DESC            = "Pixel offset for the cast swipe ring outside the GCD ring. Only applies to Swipe style.",
    -- CURSORRING_GROUP_GCD                    = "GCD Indicator",
    -- CURSORRING_ENABLE_GCD                   = "Enable GCD",
    -- CURSORRING_ENABLE_GCD_DESC              = "Show a cooldown swipe for the global cooldown.",
    -- CURSORRING_GCD_COLOR_DESC               = "GCD swipe color.",
    -- CURSORRING_OFFSET                       = "Offset",
    -- CURSORRING_GCD_OFFSET_DESC              = "Pixel offset for the GCD ring outside Ring 1.",
    -- CURSORRING_GROUP_TRAIL                  = "Mouse Trail",
    -- CURSORRING_ENABLE_TRAIL                 = "Enable Trail",
    -- CURSORRING_ENABLE_TRAIL_DESC            = "Show a fading trail behind the cursor.",
    -- CURSORRING_TRAIL_STYLE_DESC             = "Trail display style. Glow: fading sparkly trail. Line: continuous thin ribbon. Thick Line: wide ribbon. Dots: spaced-out fading dots. Custom: manual settings.",
    -- CURSORRING_TRAIL_GLOW                   = "Glow",
    -- CURSORRING_TRAIL_LINE                   = "Line",
    -- CURSORRING_TRAIL_THICKLINE              = "Thick Line",
    -- CURSORRING_TRAIL_DOTS                   = "Dots",
    -- CURSORRING_TRAIL_CUSTOM                 = "Custom",
    -- CURSORRING_TRAIL_COLOR_DESC             = "Trail color preset. Class Color uses your current class color automatically. Rainbow, Ember, and Ocean are multi-color gradients. Custom lets you pick any color below.",
    -- CURSORRING_TRAIL_COLOR_CUSTOM           = "Custom",
    -- CURSORRING_TRAIL_COLOR_CLASS            = "Class Color",
    -- CURSORRING_TRAIL_COLOR_GOLD             = "Lantern Gold",
    -- CURSORRING_TRAIL_COLOR_ARCANE           = "Arcane",
    -- CURSORRING_TRAIL_COLOR_FEL              = "Fel",
    -- CURSORRING_TRAIL_COLOR_FIRE             = "Fire",
    -- CURSORRING_TRAIL_COLOR_FROST            = "Frost",
    -- CURSORRING_TRAIL_COLOR_HOLY             = "Holy",
    -- CURSORRING_TRAIL_COLOR_SHADOW           = "Shadow",
    -- CURSORRING_TRAIL_COLOR_RAINBOW          = "Rainbow",
    -- CURSORRING_TRAIL_COLOR_ALAR             = "Al'ar",
    -- CURSORRING_TRAIL_COLOR_EMBER            = "Ember",
    -- CURSORRING_TRAIL_COLOR_OCEAN            = "Ocean",
    -- CURSORRING_CUSTOM_COLOR                 = "Custom Color",
    -- CURSORRING_CUSTOM_COLOR_DESC            = "Trail color (only used when Color is set to Custom).",
    -- CURSORRING_DURATION                     = "Duration",
    -- CURSORRING_DURATION_DESC                = "How long trail points last before fading.",
    -- CURSORRING_MAX_POINTS                   = "Max Points",
    -- CURSORRING_MAX_POINTS_DESC              = "Number of trail dots in the pool. Higher values create longer trails but use more memory.",
    -- CURSORRING_DOT_SIZE                     = "Dot Size",
    -- CURSORRING_DOT_SIZE_TRAIL_DESC          = "Size of each trail dot in pixels.",
    -- CURSORRING_DOT_SPACING                  = "Dot Spacing",
    -- CURSORRING_DOT_SPACING_DESC             = "Minimum distance in pixels before a new trail dot is placed. Lower values create a denser, more continuous trail.",
    -- CURSORRING_SHRINK_AGE                   = "Shrink with Age",
    -- CURSORRING_SHRINK_AGE_DESC              = "Trail dots shrink as they fade out. Disable for a uniform-width trail.",
    -- CURSORRING_TAPER_DISTANCE               = "Taper with Distance",
    -- CURSORRING_TAPER_DISTANCE_DESC          = "Trail dots shrink and fade toward the tail, creating a tapered brush-stroke effect.",
    -- CURSORRING_SPARKLE                      = "Sparkle",
    -- CURSORRING_SPARKLE_DESC                 = "Adds small glinting particles along the trail as you move the cursor.",
    -- CURSORRING_SPARKLE_OFF                  = "Off",
    -- CURSORRING_SPARKLE_STATIC               = "Static",
    -- CURSORRING_SPARKLE_TWINKLE              = "Twinkle",
    -- CURSORRING_TRAIL_PERF_NOTE              = "The trail runs per-frame. More dots, sparkles, and effects will use more CPU.",

    ---------------------------------------------------------------------------
    -- Phase 3: MissingPet WidgetOptions
    ---------------------------------------------------------------------------

    -- MISSINGPET_ENABLE_DESC                  = "Enable or disable the Missing Pet warning.",
    -- MISSINGPET_GROUP_WARNING                = "Warning Settings",
    -- MISSINGPET_SHOW_MISSING                 = "Show Missing Warning",
    -- MISSINGPET_SHOW_MISSING_DESC            = "Display a warning when your pet is dismissed or dead.",
    -- MISSINGPET_SHOW_PASSIVE                 = "Show Passive Warning",
    -- MISSINGPET_SHOW_PASSIVE_DESC            = "Display a warning when your pet is set to passive mode.",
    -- MISSINGPET_MISSING_TEXT                 = "Missing Text",
    -- MISSINGPET_MISSING_TEXT_DESC            = "Text to display when your pet is missing.",
    -- MISSINGPET_PASSIVE_TEXT                 = "Passive Text",
    -- MISSINGPET_PASSIVE_TEXT_DESC            = "Text to display when your pet is set to passive.",
    -- MISSINGPET_MISSING_COLOR                = "Missing Color",
    -- MISSINGPET_MISSING_COLOR_DESC           = "Color for the missing pet warning text.",
    -- MISSINGPET_PASSIVE_COLOR                = "Passive Color",
    -- MISSINGPET_PASSIVE_COLOR_DESC           = "Color for the passive pet warning text.",
    -- MISSINGPET_ANIMATION_DESC               = "Choose how the warning text animates.",
    -- MISSINGPET_GROUP_FONT                   = "Font Settings",
    -- MISSINGPET_FONT_DESC                    = "Select the font for the warning text.",
    -- MISSINGPET_FONT_SIZE_DESC               = "Size of the warning text.",
    -- MISSINGPET_FONT_OUTLINE_DESC            = "Outline style for the warning text.",
    -- MISSINGPET_LOCK_POSITION_DESC           = "Prevent the warning from being moved.",
    -- MISSINGPET_RESET_POSITION_DESC          = "Reset the warning frame position to the center of the screen.",
    -- MISSINGPET_GROUP_VISIBILITY             = "Visibility",
    -- MISSINGPET_HIDE_MOUNTED                 = "Hide When Mounted",
    -- MISSINGPET_HIDE_MOUNTED_DESC            = "Hide the warning while mounted, on a taxi, or in a vehicle.",
    -- MISSINGPET_HIDE_REST                    = "Hide In Rest Zones",
    -- MISSINGPET_HIDE_REST_DESC               = "Hide the warning while in a rest zone (cities and inns).",
    -- MISSINGPET_DISMOUNT_DELAY               = "Dismount Delay",
    -- MISSINGPET_DISMOUNT_DELAY_DESC          = "Seconds to wait after dismounting before showing warning. Set to 0 to show immediately.",
    -- MISSINGPET_PLAY_SOUND_DESC              = "Play a sound when the warning is displayed.",
    -- MISSINGPET_SOUND_MISSING                = "Sound When Missing",
    -- MISSINGPET_SOUND_MISSING_DESC           = "Play sound when pet is missing.",
    -- MISSINGPET_SOUND_PASSIVE                = "Sound When Passive",
    -- MISSINGPET_SOUND_PASSIVE_DESC           = "Play sound when pet is set to passive.",
    -- MISSINGPET_SOUND_COMBAT                 = "Sound In Combat",
    -- MISSINGPET_SOUND_COMBAT_DESC            = "Continue playing sound while in combat. When disabled, sound stops when combat begins.",
    -- MISSINGPET_SOUND_REPEAT                 = "Repeat Sound",
    -- MISSINGPET_SOUND_REPEAT_DESC            = "Repeat the sound at regular intervals while the warning is displayed.",
    -- MISSINGPET_SOUND_SELECT_DESC            = "Select the sound to play. Click the speaker icon to preview.",
    -- MISSINGPET_REPEAT_INTERVAL              = "Repeat Interval",
    -- MISSINGPET_REPEAT_INTERVAL_DESC         = "Seconds between sound repeats.",

    ---------------------------------------------------------------------------
    -- Phase 3: CombatAlert WidgetOptions
    ---------------------------------------------------------------------------

    -- COMBATALERT_ENABLE_DESC                 = "Show text alerts when entering/leaving combat.",
    -- COMBATALERT_PREVIEW_DESC                = "Loop enter/leave alerts on screen for real-time editing. Automatically disables when the settings panel is closed.",
    -- COMBATALERT_GROUP_ENTER                 = "Combat Enter",
    -- COMBATALERT_SHOW_ENTER                  = "Show Enter Alert",
    -- COMBATALERT_SHOW_ENTER_DESC             = "Show an alert when entering combat.",
    -- COMBATALERT_ENTER_TEXT                   = "Enter Text",
    -- COMBATALERT_ENTER_TEXT_DESC             = "Text displayed when entering combat.",
    -- COMBATALERT_ENTER_COLOR                 = "Enter Color",
    -- COMBATALERT_ENTER_COLOR_DESC            = "Color of the combat enter text.",
    -- COMBATALERT_GROUP_LEAVE                 = "Combat Leave",
    -- COMBATALERT_SHOW_LEAVE                  = "Show Leave Alert",
    -- COMBATALERT_SHOW_LEAVE_DESC             = "Show an alert when leaving combat.",
    -- COMBATALERT_LEAVE_TEXT                   = "Leave Text",
    -- COMBATALERT_LEAVE_TEXT_DESC             = "Text displayed when leaving combat.",
    -- COMBATALERT_LEAVE_COLOR                 = "Leave Color",
    -- COMBATALERT_LEAVE_COLOR_DESC            = "Color of the combat leave text.",
    -- COMBATALERT_GROUP_FONT                  = "Font and Display Settings",
    -- COMBATALERT_FONT_DESC                   = "Select the font for the alert text.",
    -- COMBATALERT_FONT_SIZE_DESC              = "Size of the alert text.",
    -- COMBATALERT_FONT_OUTLINE_DESC           = "Outline style for the alert text.",
    -- COMBATALERT_FADE_DURATION               = "Fade Duration",
    -- COMBATALERT_FADE_DURATION_DESC          = "Total duration of the alert (hold + fade out) in seconds.",
    -- COMBATALERT_PLAY_SOUND_DESC             = "Play a sound when the alert is shown.",
    -- COMBATALERT_SOUND_SELECT_DESC           = "Select the sound to play.",
    -- COMBATALERT_LOCK_POSITION_DESC          = "Prevent the alert from being moved.",
    -- COMBATALERT_RESET_POSITION_DESC         = "Reset the alert to its default position.",

    ---------------------------------------------------------------------------
    -- Phase 3: CombatTimer WidgetOptions
    ---------------------------------------------------------------------------

    -- COMBATTIMER_ENABLE_DESC                 = "Show a timer during combat.",
    -- COMBATTIMER_PREVIEW_DESC                = "Show the timer on screen for real-time editing. Automatically disables when the settings panel is closed.",
    -- COMBATTIMER_FONT_DESC                   = "Select the font for the timer text.",
    -- COMBATTIMER_FONT_SIZE_DESC              = "Size of the timer text.",
    -- COMBATTIMER_FONT_OUTLINE_DESC           = "Outline style for the timer text.",
    -- COMBATTIMER_FONT_COLOR_DESC             = "Color of the timer text.",
    -- COMBATTIMER_STICKY_DURATION             = "Sticky Duration",
    -- COMBATTIMER_STICKY_DURATION_DESC        = "Seconds to keep showing the final time after combat ends. Set to 0 to hide immediately.",
    -- COMBATTIMER_LOCK_POSITION_DESC          = "Prevent the timer from being moved.",
    -- COMBATTIMER_RESET_POSITION_DESC         = "Reset the timer to its default position.",

    ---------------------------------------------------------------------------
    -- Phase 3: RangeCheck WidgetOptions
    ---------------------------------------------------------------------------

    -- RANGECHECK_ENABLE_DESC                  = "Show in-range or out-of-range status for your current target.",
    -- RANGECHECK_HIDE_IN_RANGE                = "Hide When In Range",
    -- RANGECHECK_HIDE_IN_RANGE_DESC           = "Hide the display when your target is within range. Only shows when out of range.",
    -- RANGECHECK_COMBAT_ONLY                  = "Combat Only",
    -- RANGECHECK_COMBAT_ONLY_DESC             = "Only show range when in combat.",
    -- RANGECHECK_GROUP_STATUS                 = "Status Text",
    -- RANGECHECK_IN_RANGE_TEXT                = "In Range Text",
    -- RANGECHECK_IN_RANGE_TEXT_DESC           = "Text to display when your target is within range.",
    -- RANGECHECK_OUT_OF_RANGE_TEXT            = "Out of Range Text",
    -- RANGECHECK_OUT_OF_RANGE_TEXT_DESC       = "Text to display when your target is out of range.",
    -- RANGECHECK_IN_RANGE_COLOR               = "In Range Color",
    -- RANGECHECK_IN_RANGE_COLOR_DESC          = "Color for the in-range text.",
    -- RANGECHECK_OUT_OF_RANGE_COLOR           = "Out of Range Color",
    -- RANGECHECK_OUT_OF_RANGE_COLOR_DESC      = "Color for the out-of-range text.",
    -- RANGECHECK_ANIMATION_DESC               = "Choose how the status text animates on state change.",
    -- RANGECHECK_FONT_DESC                    = "Select the font for the range text.",
    -- RANGECHECK_FONT_SIZE_DESC               = "Size of the range text.",
    -- RANGECHECK_FONT_OUTLINE_DESC            = "Outline style for the range text.",
    -- RANGECHECK_LOCK_POSITION_DESC           = "Prevent the range display from being moved.",
    -- RANGECHECK_RESET_POSITION_DESC          = "Reset the range display to its default position.",

    ---------------------------------------------------------------------------
    -- Phase 3: ChatFilter WidgetOptions
    ---------------------------------------------------------------------------

    -- CHATFILTER_ENABLE_DESC                  = "Enable or disable the Chat Filter.",
    -- CHATFILTER_LOGIN_MESSAGE                = "Login message",
    -- CHATFILTER_LOGIN_MESSAGE_DESC           = "Show a chat message on login confirming the filter is active.",
    -- CHATFILTER_ADD_KEYWORD                  = "Add keyword",
    -- CHATFILTER_ADD_KEYWORD_DESC             = "Enter a word or phrase to filter. Matching is case-insensitive.",
    -- CHATFILTER_KEYWORDS_GROUP               = "Keywords (%d)",
    -- CHATFILTER_NO_KEYWORDS                  = "No keywords configured.",
    -- CHATFILTER_REMOVE_KEYWORD_DESC          = "Remove \"%s\" from the filter list.",
    -- CHATFILTER_RESTORE_DEFAULTS             = "Restore default keywords",
    -- CHATFILTER_RESTORE_DEFAULTS_DESC        = "Reset the keyword list to the built-in defaults. This replaces all custom keywords.",
    -- CHATFILTER_RESTORE_CONFIRM              = "Restore?",

    ---------------------------------------------------------------------------
    -- Phase 3: Tooltip WidgetOptions
    ---------------------------------------------------------------------------

    -- TOOLTIP_ENABLE_DESC                     = "Enhance tooltips with extra information.",
    -- TOOLTIP_GROUP_PLAYER                    = "Player",
    -- TOOLTIP_MOUNT_NAME                      = "Mount name",
    -- TOOLTIP_MOUNT_NAME_DESC                 = "Show what mount a player is currently riding.",
    -- TOOLTIP_GROUP_ITEMS                     = "Items",
    -- TOOLTIP_ITEM_ID                         = "Item ID",
    -- TOOLTIP_ITEM_ID_DESC                    = "Show the item ID on item tooltips.",
    -- TOOLTIP_ITEM_SPELL_ID                   = "Item spell ID",
    -- TOOLTIP_ITEM_SPELL_ID_DESC              = "Show the use-effect spell ID on consumables and other items with on-use abilities.",
    -- TOOLTIP_GROUP_SPELLS                    = "Spells",
    -- TOOLTIP_SPELL_ID                        = "Spell ID",
    -- TOOLTIP_SPELL_ID_DESC                   = "Show the spell ID on spell, aura, and talent tooltips.",
    -- TOOLTIP_NODE_ID                         = "Node ID",
    -- TOOLTIP_NODE_ID_DESC                    = "Show the talent tree node ID on talent tooltips.",
    -- TOOLTIP_GROUP_COPY                      = "Copy",
    -- TOOLTIP_CTRL_C                          = "Ctrl+C to copy",
    -- TOOLTIP_CTRL_C_DESC                     = "Press Ctrl+C to copy the primary ID, or Ctrl+Shift+C to copy the secondary ID (e.g. an item's use-effect SpellID).",
    -- TOOLTIP_COMBAT_NOTE                     = "Tooltip enhancements are disabled in instances. Mount scanning and Ctrl+C copy are disabled during combat.",

    ---------------------------------------------------------------------------
    -- Phase 3: AutoPlaystyle WidgetOptions
    ---------------------------------------------------------------------------

    -- AUTOPLAYSTYLE_ENABLE_DESC               = "Auto-select playstyle when listing M+ groups.",
    -- AUTOPLAYSTYLE_PLAYSTYLE                 = "Playstyle",
    -- AUTOPLAYSTYLE_PLAYSTYLE_DESC            = "Auto-selects this playstyle when opening the Group Finder listing dialog for M+ dungeons.",

    ---------------------------------------------------------------------------
    -- Shared: Font outline values (used across multiple modules)
    ---------------------------------------------------------------------------

    -- FONT_OUTLINE_NONE                       = "None",
    -- FONT_OUTLINE_OUTLINE                    = "Outline",
    -- FONT_OUTLINE_THICK                      = "Thick Outline",
    -- FONT_OUTLINE_MONO                       = "Monochrome",
    -- FONT_OUTLINE_OUTLINE_MONO              = "Outline + Mono",

    ---------------------------------------------------------------------------
    -- Shared: Animation values (used across MissingPet, RangeCheck)
    ---------------------------------------------------------------------------

    -- ANIMATION_NONE                          = "None (static)",
    -- ANIMATION_BOUNCE                        = "Bounce",
    -- ANIMATION_PULSE                         = "Pulse",
    -- ANIMATION_FADE                          = "Fade",
    -- ANIMATION_SHAKE                         = "Shake",
    -- ANIMATION_GLOW                          = "Glow",
    -- ANIMATION_HEARTBEAT                     = "Heartbeat",

    ---------------------------------------------------------------------------
    -- Shared: Confirm/Remove labels
    ---------------------------------------------------------------------------

    -- SHARED_REMOVE                           = "Remove",
    -- SHARED_REMOVE_CONFIRM                   = "Remove?",

    ---------------------------------------------------------------------------
    -- Tooltip: in-game tooltip hint lines
    ---------------------------------------------------------------------------

    -- TOOLTIP_HINT_COPY                       = "Ctrl+C to copy",
    -- TOOLTIP_HINT_COPY_BOTH                  = "Ctrl+C ItemID  |  Ctrl+Shift+C SpellID",
    -- TOOLTIP_COPY_HINT                       = "Ctrl+C to copy, Esc to close",
});
