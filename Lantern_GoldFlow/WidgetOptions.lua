local ADDON_NAME, ns = ...;
local Lantern = _G.Lantern;
if (not Lantern or not Lantern.modules or not Lantern.modules.GoldFlow) then return; end

local LanternUX = _G.LanternUX;
if (not LanternUX or not LanternUX.Theme) then return; end

local module = Lantern.modules.GoldFlow;
local T = LanternUX.Theme;

local refreshPage = Lantern.refreshPage;

-------------------------------------------------------------------------------
-- Widget Options
-------------------------------------------------------------------------------

module.widgetOptions = function()
    local db = module.db or {};
    local settings = db.settings or {};

    local widgets = {};

    -- Enable toggle
    table.insert(widgets, {
        type = "toggle",
        label = "Enable GoldFlow",
        desc = "Enable or disable the GoldFlow data collector.",
        get = function()
            return module.enabled;
        end,
        set = function(val)
            if (val) then
                Lantern:EnableModule("GoldFlow");
            else
                Lantern:DisableModule("GoldFlow");
            end
            refreshPage();
        end,
    });

    -- Scanning header
    table.insert(widgets, { type = "header", text = "Scanning" });

    table.insert(widgets, {
        type = "toggle",
        label = "Scan Inventory",
        desc = "Track bag, bank, and warband bank item quantities.",
        disabled = function() return not module.enabled; end,
        get = function() return settings.scanInventory ~= false; end,
        set = function(val)
            settings.scanInventory = val and true or false;
        end,
    });

    table.insert(widgets, {
        type = "toggle",
        label = "Scan Professions",
        desc = "Track profession skill levels and known recipes.",
        disabled = function() return not module.enabled; end,
        get = function() return settings.scanProfessions ~= false; end,
        set = function(val)
            settings.scanProfessions = val and true or false;
        end,
    });

    table.insert(widgets, {
        type = "toggle",
        label = "Track Transactions",
        desc = "Record auction house purchases, sales, and expired listings.",
        disabled = function() return not module.enabled; end,
        get = function() return settings.trackTransactions ~= false; end,
        set = function(val)
            settings.trackTransactions = val and true or false;
        end,
    });

    table.insert(widgets, {
        type = "toggle",
        label = "Track Listings",
        desc = "Snapshot your active auction house listings when visiting the AH.",
        disabled = function() return not module.enabled; end,
        get = function() return settings.trackListings ~= false; end,
        set = function(val)
            settings.trackListings = val and true or false;
        end,
    });

    -- Data header
    table.insert(widgets, { type = "header", text = "Data" });

    -- Summary description
    local charCount = 0;
    local totalGold = 0;
    local charLines = {};

    for key, char in pairs(db.characters or {}) do
        charCount = charCount + 1;
        local gold = char.gold or 0;
        totalGold = totalGold + gold;
        local formatted = Lantern:Convert("money:format_copper", gold);
        table.insert(charLines, string.format("  %s: %s", key, formatted or "0g"));
    end

    table.sort(charLines);

    local warbandGold = db.warbandGold or 0;
    local warbandFormatted = Lantern:Convert("money:format_copper", warbandGold);
    local grandTotal = totalGold + warbandGold;
    local grandFormatted = Lantern:Convert("money:format_copper", grandTotal);
    local txCount = db.transactions and #db.transactions or 0;

    local lastUpdated = db.lastUpdated or 0;
    local lastUpdatedText = "Never";
    if (lastUpdated > 0) then
        lastUpdatedText = date("%Y-%m-%d %H:%M:%S", lastUpdated);
    end

    local lines = {};
    table.insert(lines, string.format("|cff00ff00Characters:|r %d", charCount));
    for _, line in ipairs(charLines) do
        table.insert(lines, line);
    end
    table.insert(lines, string.format("|cff00ff00Warband Gold:|r %s", warbandFormatted or "0g"));
    table.insert(lines, string.format("|cff00ff00Total Gold:|r %s", grandFormatted or "0g"));
    table.insert(lines, string.format("|cff00ff00Transactions:|r %d", txCount));
    table.insert(lines, string.format("|cff00ff00Last Updated:|r %s", lastUpdatedText));

    table.insert(widgets, {
        type = "description",
        text = table.concat(lines, "\n"),
        fontSize = "medium",
    });

    -- Force Sync button
    table.insert(widgets, {
        type = "execute",
        label = "Force Sync",
        desc = "Update the last-modified timestamp so the companion app picks up current data.",
        disabled = function() return not module.enabled; end,
        func = function()
            module:ForceSave();
            refreshPage();
        end,
    });

    -- Reset Data button
    table.insert(widgets, {
        type = "execute",
        label = "Reset Data",
        desc = "Erase all GoldFlow saved data and start fresh.",
        danger = true,
        disabled = function() return not module.enabled; end,
        func = function()
            module:ClearData();
        end,
    });

    return widgets;
end
