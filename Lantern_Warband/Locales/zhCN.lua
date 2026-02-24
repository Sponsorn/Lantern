local ADDON_NAME, ns = ...;
ns:RegisterLocale("zhCN", {

    -- Shared
    -- ENABLE                                      = "Enable",

    ---------------------------------------------------------------------------
    -- Module metadata (Warband.lua)
    ---------------------------------------------------------------------------

    -- WARBAND_TITLE                               = "Warband",
    -- WARBAND_DESC                                = "Manage character groups with automated banking features.",

    ---------------------------------------------------------------------------
    -- Print messages (Warband.lua)
    ---------------------------------------------------------------------------

    -- WARBAND_MSG_DEPOSITED                       = "Deposited %s gold to warbank.",
    -- WARBAND_MSG_WITHDREW                        = "Withdrew %s gold from warbank.",

    ---------------------------------------------------------------------------
    -- Options.lua: formatTimeAgo
    ---------------------------------------------------------------------------

    -- WARBAND_TIME_NEVER                          = "Never",
    -- WARBAND_TIME_JUST_NOW                       = "Just now",
    -- WARBAND_TIME_MINUTES_AGO                    = "%dm ago",
    -- WARBAND_TIME_HOURS_AGO                      = "%dh ago",
    -- WARBAND_TIME_DAYS_AGO                       = "%dd ago",

    ---------------------------------------------------------------------------
    -- WidgetOptions.lua: General tab
    ---------------------------------------------------------------------------

    -- WARBAND_GENERAL_DESCRIPTION                 = "Manage character groups and automated banking. Create groups with gold thresholds, and when you open a bank, the addon will automatically balance your gold to match the threshold (deposit excess or withdraw if below).",
    -- WARBAND_AUTO_BALANCE                        = "Auto-balance gold with warbank",
    -- WARBAND_AUTO_BALANCE_DESC                   = "Automatically deposit excess gold or withdraw if below threshold when opening a bank.",
    -- WARBAND_UNGROUPED_HEADER                    = "Ungrouped Characters",
    -- WARBAND_USE_DEFAULT_THRESHOLD               = "Use default threshold for ungrouped characters",
    -- WARBAND_USE_DEFAULT_THRESHOLD_DESC          = "Apply a default gold threshold to characters not assigned to any group.",
    -- WARBAND_DEFAULT_THRESHOLD                   = "Default gold threshold",
    -- WARBAND_DEFAULT_THRESHOLD_DESC              = "Gold threshold for characters not in any group. The addon will automatically balance to this amount.",
    -- WARBAND_CURRENT_CHAR_HEADER                 = "Current Character",
    -- WARBAND_CURRENT_CHAR_LABEL                  = "Current character:",
    -- WARBAND_GROUP_LABEL                         = "Group:",
    -- WARBAND_GOLD_THRESHOLD_LABEL                = "Gold threshold:",
    -- WARBAND_GOLD_SUFFIX                         = "%s gold",
    -- WARBAND_NOT_ASSIGNED                        = "Not assigned to any group",
    -- WARBAND_DEFAULT_THRESHOLD_LABEL             = "Default threshold:",
    -- WARBAND_UNKNOWN                             = "Unknown",

    ---------------------------------------------------------------------------
    -- WidgetOptions.lua: Groups tab
    ---------------------------------------------------------------------------

    -- WARBAND_CREATE_GROUP_HEADER                 = "Create New Group",
    -- WARBAND_GROUP_NAME                          = "Group name",
    -- WARBAND_GROUP_NAME_DESC                     = "Enter a name for the new group (e.g., 'Mains', 'Alts', 'Bankers')",
    -- WARBAND_GOLD_THRESHOLD                      = "Gold threshold",
    -- WARBAND_GOLD_THRESHOLD_DESC                 = "Amount of gold to keep on character. Set to 0 to deposit all gold (deposit-only mode).",
    -- WARBAND_ALLOW_DEPOSITS                      = "Allow deposits",
    -- WARBAND_ALLOW_DEPOSITS_DESC                 = "Allow depositing gold to warbank when over threshold.",
    -- WARBAND_ALLOW_WITHDRAWALS                   = "Allow withdrawals",
    -- WARBAND_ALLOW_WITHDRAWALS_DESC              = "Allow withdrawing gold from warbank when below threshold.",
    -- WARBAND_CREATE_GROUP                        = "Create Group",
    -- WARBAND_CREATE_GROUP_DESC                   = "Create a new character group with the settings above.",
    -- WARBAND_GROUP_MEMBER_COUNT                  = "%s - %d member%s",
    -- WARBAND_RENAME_GROUP_DESC                   = "Change the name of this group. Press Enter to confirm.",
    -- WARBAND_EDIT_THRESHOLD_DESC                 = "Change the gold threshold for this group. Set to 0 to deposit all gold (deposit-only mode).",
    -- WARBAND_MEMBERS_HEADER                      = "Members",
    -- WARBAND_REMOVE                              = "Remove",
    -- WARBAND_REMOVE_MEMBER_DESC                  = "Remove %s from this group.",
    -- WARBAND_REMOVE_CONFIRM                      = "Remove?",
    -- WARBAND_ADD_CURRENT_CHAR                    = "Add Current Character",
    -- WARBAND_ADD_CURRENT_CHAR_DESC               = "Add the current character to this group.",
    -- WARBAND_DELETE_GROUP                         = "Delete Group",
    -- WARBAND_DELETE_GROUP_DESC                    = "Delete this group. Characters will be unassigned.",
    -- WARBAND_DELETE_CONFIRM                      = "Delete?",
    -- WARBAND_NO_MEMBERS                          = "No members in this group yet.",
    -- WARBAND_NO_GROUPS                           = "No groups created yet. Use the form above to create your first group.",

    ---------------------------------------------------------------------------
    -- WidgetOptions.lua: Groups tab - print messages
    ---------------------------------------------------------------------------

    -- WARBAND_MSG_ENTER_NAME                      = "Please enter a group name.",
    -- WARBAND_MSG_ENTER_VALID_GOLD                = "Please enter a valid gold amount.",
    -- WARBAND_MSG_GROUP_EXISTS                     = "Group '%s' already exists.",
    -- WARBAND_MSG_CREATED_GROUP                   = "Created group '%s' with threshold of %s gold.",
    -- WARBAND_MSG_ENTER_NEW_NAME                  = "Please enter a new name.",
    -- WARBAND_MSG_RENAMED_GROUP                   = "Renamed group '%s' to '%s'.",
    -- WARBAND_MSG_GOLD_NONNEGATIVE                = "Gold amount must be 0 or greater.",
    -- WARBAND_MSG_UPDATED_THRESHOLD               = "Updated threshold for '%s' to %s gold.",
    -- WARBAND_MSG_REMOVED_FROM_GROUP              = "Removed %s from group '%s'.",
    -- WARBAND_MSG_CANNOT_GET_CHAR                 = "Could not get current character.",
    -- WARBAND_MSG_ALREADY_IN_GROUP                = "%s is already in group '%s'.",
    -- WARBAND_MSG_ADDED_TO_GROUP                  = "Added %s to group '%s'.",
    -- WARBAND_MSG_DELETED_GROUP                   = "Deleted group '%s'.",

    ---------------------------------------------------------------------------
    -- WidgetOptions.lua: Characters tab
    ---------------------------------------------------------------------------

    -- WARBAND_CHARS_DESCRIPTION                   = "Assign characters to groups. Characters in a group will automatically balance their gold to the threshold when opening a bank.",
    -- WARBAND_ASSIGN_TO_GROUP                     = "Assign to group",
    -- WARBAND_ASSIGN_TO_GROUP_DESC                = "Assign the current character to a group.",
    -- WARBAND_NONE                                = "None",
    -- WARBAND_ALL_CHARS_HEADER                    = "All Characters",
    -- WARBAND_CHAR_GROUP_THRESHOLD                = "%s gold threshold",
    -- WARBAND_CHAR_GROUP_NOT_FOUND                = "group not found",
    -- WARBAND_NO_CHARS_ASSIGNED                   = "No characters assigned yet.",

    -- Characters tab - print messages
    -- WARBAND_MSG_REMOVED_FROM_GROUPS             = "Removed %s from groups.",
    -- WARBAND_MSG_ASSIGNED_TO_GROUP               = "Assigned %s to group '%s'.",

    ---------------------------------------------------------------------------
    -- WidgetOptions.lua: Warehousing tab
    ---------------------------------------------------------------------------

    -- WARBAND_WH_UNAVAILABLE                      = "Warehousing is not available in this version of the game.",
    -- WARBAND_WH_DESCRIPTION                      = "Organize warbank items into groups and move them between your bags and the warband bank. Create groups, assign items, and configure deposit/restock rules.",
    -- WARBAND_WH_CREATE_GROUP_HEADER              = "Create New Group",
    -- WARBAND_WH_GROUP_NAME                       = "Group name",
    -- WARBAND_WH_GROUP_NAME_DESC                  = "Enter a name for the new warehousing group.",
    -- WARBAND_WH_CREATE_GROUP                     = "Create Group",
    -- WARBAND_WH_CREATE_GROUP_DESC                = "Create a new warehousing group with the name above.",
    -- WARBAND_WH_GROUP_LABEL                      = "%s (%d item%s)",
    -- WARBAND_WH_GROUP_DESC                       = "Expand to manage items and rules for this group.",

    -- Deposit section
    -- WARBAND_WH_DEPOSIT_HEADER                   = "Deposit",
    -- WARBAND_WH_ENABLE_DEPOSIT                   = "Enable deposit",
    -- WARBAND_WH_ENABLE_DEPOSIT_DESC              = "Deposit items from your bags into the warbank when visiting the bank.",
    -- WARBAND_WH_DEPOSIT_ALL                      = "Deposit all",
    -- WARBAND_WH_DEPOSIT_ALL_DESC                 = "Deposit all items in your bags (ignoring quantity limit). Disable to deposit a specific quantity.",
    -- WARBAND_WH_DEPOSIT_QTY                      = "Deposit quantity",
    -- WARBAND_WH_DEPOSIT_QTY_DESC                 = "Maximum number of items to deposit per visit. Only used when 'Deposit all' is off.",

    -- Restock section
    -- WARBAND_WH_RESTOCK_HEADER                   = "Restock",
    -- WARBAND_WH_ENABLE_RESTOCK                   = "Enable restock",
    -- WARBAND_WH_ENABLE_RESTOCK_DESC              = "Withdraw items from the warbank to your bags when visiting the bank.",
    -- WARBAND_WH_RESTOCK_ALL                      = "Restock all",
    -- WARBAND_WH_RESTOCK_ALL_DESC                 = "Withdraw all available items from the warbank. Disable to restock up to a specific quantity.",
    -- WARBAND_WH_RESTOCK_QTY                      = "Restock quantity",
    -- WARBAND_WH_RESTOCK_QTY_DESC                 = "Target number of items to keep in your bags. Only used when 'Restock all' is off.",

    -- Keep section
    -- WARBAND_WH_KEEP_HEADER                      = "Keep",
    -- WARBAND_WH_ENABLE_KEEP                      = "Enable keep minimum",
    -- WARBAND_WH_ENABLE_KEEP_DESC                 = "Keep a minimum quantity in the source location. When depositing, keeps at least this many in your bags. When restocking, keeps at least this many in the warbank.",
    -- WARBAND_WH_KEEP_QTY                         = "Keep quantity",
    -- WARBAND_WH_KEEP_QTY_DESC                    = "Minimum number of items to keep in the source location.",

    -- Add Item section
    -- WARBAND_WH_ADD_ITEM_HEADER                  = "Add Item",
    -- WARBAND_WH_DRAG_DROP                        = "Drag and drop:",
    -- WARBAND_WH_DRAG_DROP_DESC                   = "Drag an item from your bags and drop it here to add it to this group.",
    -- WARBAND_WH_ITEM_ID_INPUT                    = "Item ID or drag and drop",
    -- WARBAND_WH_ITEM_ID_INPUT_DESC               = "Enter an item ID (e.g. 12345) or drag an item from your bags into this field.",
    -- WARBAND_WH_ITEMS_HEADER                     = "Items (%d)",
    -- WARBAND_WH_REMOVE_ITEM_DESC                 = "Remove this item from the group.",
    -- WARBAND_WH_NO_ITEMS                         = "No items yet. Enter an item ID or paste an item link above.",

    -- Delete group
    -- WARBAND_WH_DELETE_GROUP                     = "Delete Group",
    -- WARBAND_WH_DELETE_GROUP_DESC                = "Delete this warehousing group and all its items.",
    -- WARBAND_WH_DELETE_CONFIRM                   = "Delete?",
    -- WARBAND_WH_NO_GROUPS                        = "No warehousing groups created yet. Use the form above to create your first group.",

    -- Warehousing print messages
    -- WARBAND_WH_MSG_ENTER_NAME                   = "Please enter a group name.",
    -- WARBAND_WH_MSG_CREATED_GROUP                = "Created warehousing group '%s'.",
    -- WARBAND_WH_MSG_GROUP_EXISTS                 = "Group '%s' already exists.",
    -- WARBAND_WH_MSG_ADDED_ITEM                   = "Added %s to '%s'.",
    -- WARBAND_WH_MSG_INVALID_ITEM_ID              = "Invalid item ID.",
    -- WARBAND_WH_MSG_REMOVED_ITEM                 = "Removed %s from '%s'.",
    -- WARBAND_WH_MSG_DELETED_GROUP                = "Deleted warehousing group '%s'.",

    ---------------------------------------------------------------------------
    -- WidgetOptions.lua: uxPages registration
    ---------------------------------------------------------------------------

    -- WARBAND_PAGE_GENERAL                        = "General",
    -- WARBAND_PAGE_GENERAL_TITLE                  = "General",
    -- WARBAND_PAGE_GENERAL_DESC                   = "Core warband settings.",
    -- WARBAND_PAGE_GROUPS                         = "Groups",
    -- WARBAND_PAGE_GROUPS_TITLE                   = "Groups",
    -- WARBAND_PAGE_GROUPS_DESC                    = "Create and manage character groups.",
    -- WARBAND_PAGE_CHARACTERS                     = "Characters",
    -- WARBAND_PAGE_CHARACTERS_TITLE               = "Characters",
    -- WARBAND_PAGE_CHARACTERS_DESC                = "Assign characters to groups.",
    -- WARBAND_PAGE_WAREHOUSING                    = "Warehousing",
    -- WARBAND_PAGE_WAREHOUSING_TITLE              = "Warehousing",
    -- WARBAND_PAGE_WAREHOUSING_DESC               = "Warbank item management.",

    ---------------------------------------------------------------------------
    -- Warehousing/Data.lua: print messages
    ---------------------------------------------------------------------------

    -- WARBAND_WH_MSG_SKIP_NOT_WARBOUND           = "Warehousing: Skipping %s (not warbound).",

    ---------------------------------------------------------------------------
    -- Warehousing/Engine.lua: print messages
    ---------------------------------------------------------------------------

    -- WARBAND_WH_MSG_FAILED_DEPOSIT              = "Warehousing: Failed to deposit %s - %s (after %d retries).",
    -- WARBAND_WH_MSG_FAILED_WITHDRAW             = "Warehousing: Failed to withdraw %s - %s (after %d retries).",
    -- WARBAND_WH_MSG_FAILED_UNAVAILABLE          = "Warehousing: Failed to %s %s - items unavailable.",

    -- Engine: no-space reason text
    -- WARBAND_WH_NO_SPACE_WARBANK                = "No space in warbank",
    -- WARBAND_WH_NO_SPACE_INVENTORY              = "No space in inventory",
    -- WARBAND_WH_ACTION_DEPOSIT                  = "deposit",
    -- WARBAND_WH_ACTION_WITHDRAW                 = "withdraw",

    ---------------------------------------------------------------------------
    -- Warehousing/UI.lua: UI strings
    ---------------------------------------------------------------------------

    -- WARBAND_WH_UI_TITLE                         = "Warehousing",
    -- WARBAND_WH_UI_SETTINGS                      = "Settings",
    -- WARBAND_WH_UI_SETTINGS_TOOLTIP              = "Warehousing Settings",
    -- WARBAND_WH_UI_SETTINGS_TOOLTIP_DESC         = "Create and manage groups.",
    -- WARBAND_WH_UI_DEPOSIT_BTN                   = "< Warbank",
    -- WARBAND_WH_UI_DEPOSIT_TOOLTIP               = "Deposit to Warbank",
    -- WARBAND_WH_UI_DEPOSIT_TOOLTIP_DESC          = "Move items from selected groups to warbank.",
    -- WARBAND_WH_UI_RESTOCK_BTN                   = "> Inventory",
    -- WARBAND_WH_UI_RESTOCK_TOOLTIP               = "Restock from Warbank",
    -- WARBAND_WH_UI_RESTOCK_TOOLTIP_DESC          = "Withdraw items for selected groups until limit is met.",
    -- WARBAND_WH_UI_NO_GROUPS_SELECTED            = "No groups selected.",
    -- WARBAND_WH_UI_NO_ITEMS_TO_MOVE              = "No items to move.",
    -- WARBAND_WH_UI_MSG_NOTHING_TO_MOVE           = "Warehousing: %s - nothing to move.",
    -- WARBAND_WH_UI_STATUS_FORMAT                 = "%s: Batch %d/%d, Items %d/%d",
    -- WARBAND_WH_UI_STATUS_FAILED                 = " (%d failed)",
    -- WARBAND_WH_UI_STOPPED                       = "Stopped: %s (%d/%d)",
    -- WARBAND_WH_UI_FAILED_BANK                   = "Failed: bank not accessible.",
    -- WARBAND_WH_UI_DISABLED                      = "Disabled",
    -- WARBAND_WH_UI_NO_GROUPS_DEFINED             = "No groups defined.",
    -- WARBAND_WH_UI_CLICK_SETTINGS                = "Click Settings above to create groups.",
    -- WARBAND_WH_UI_BANK_BTN                      = "Warehousing",
    -- WARBAND_WH_UI_BANK_TOOLTIP                  = "Lantern Warehousing",
    -- WARBAND_WH_UI_BANK_TOOLTIP_DESC             = "Move items between inventory and warbank by group.",
    -- WARBAND_WH_UI_ACTION_DEPOSIT                = "Deposit",
    -- WARBAND_WH_UI_ACTION_RESTOCK                = "Restock",
    -- WARBAND_WH_UI_ITEM_COUNT_MODE               = "%d item%s, %s",
    -- WARBAND_WH_UI_REASON_BANK_CLOSED            = "Bank closed",
    -- WARBAND_WH_UI_REASON_BANK_INACCESSIBLE      = "Bank no longer accessible",
    -- WARBAND_WH_UI_REASON_CANCELLED              = "Cancelled",
});
