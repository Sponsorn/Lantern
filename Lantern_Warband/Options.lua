local ADDON_NAME = "Lantern_Warband";
local Lantern = _G.Lantern;
if (not Lantern or not Lantern.modules or not Lantern.modules.Warband) then return; end

local Warband = Lantern.modules.Warband;

-- Shared utility functions
local function formatGold(copper)
    return Lantern:Convert("money:format_gold", copper) or "0";
end

local function formatGoldThousands(copper)
    return Lantern:Convert("money:format_gold_thousands", copper) or "0";
end

local function parseGold(str)
    return Lantern:Convert("money:parse_gold", str);
end

local function formatTimeAgo(timestamp)
    if (not timestamp) then return "Never"; end
    local now = time();
    local diff = now - timestamp;

    if (diff < 60) then
        return "Just now";
    elseif (diff < 3600) then
        local mins = math.floor(diff / 60);
        return mins .. "m ago";
    elseif (diff < 86400) then
        local hours = math.floor(diff / 3600);
        return hours .. "h ago";
    else
        local days = math.floor(diff / 86400);
        return days .. "d ago";
    end
end

-- Export utilities for other options files
Warband._optionsUtils = {
    formatGold = formatGold,
    formatGoldThousands = formatGoldThousands,
    parseGold = parseGold,
    formatTimeAgo = formatTimeAgo,
};

-- Force options rebuild by re-registering the module options
local function refreshOptions(self)
    local AceConfig = LibStub and LibStub("AceConfig-3.0", true);
    local AceConfigRegistry = LibStub and LibStub("AceConfigRegistry-3.0", true);

    if (AceConfig and AceConfigRegistry and self.GetOptions) then
        local key = "module_Warband";
        local newOptions = self:GetOptions();

        -- Build the wrapped group
        local group = {
            type = "group",
            name = "Warband",
            childGroups = "tree",
            args = {
                enabled = {
                    order = 0,
                    type = "toggle",
                    name = "Enable",
                    width = "full",
                    get = function()
                        return self.enabled;
                    end,
                    set = function(_, val)
                        if (val) then
                            Lantern:EnableModule("Warband");
                        else
                            Lantern:DisableModule("Warband");
                        end
                    end,
                },
            },
        };

        -- Merge new options
        for k, v in pairs(newOptions) do
            group.args[k] = v;
        end

        AceConfig:RegisterOptionsTable(key, group);
        AceConfigRegistry:NotifyChange(key);
    end
end

function Warband:GetOptions()
    -- Ensure database is initialized before building options
    if (not self.db) then
        if (not _G.LanternWarbandDB) then
            _G.LanternWarbandDB = {};
        end
        self.db = _G.LanternWarbandDB;
    end

    -- Temporary storage for new group creation
    if (not self._newGroupTemp) then
        self._newGroupTemp = {
            name = "",
            threshold = "100000",
            allowDeposit = true,
            allowWithdraw = true,
        };
    else
        -- Ensure fields exist if upgrading from old version
        if (self._newGroupTemp.allowDeposit == nil) then
            self._newGroupTemp.allowDeposit = true;
        end
        if (self._newGroupTemp.allowWithdraw == nil) then
            self._newGroupTemp.allowWithdraw = true;
        end
    end

    local options = {
        general = {
            order = 1,
            type = "group",
            name = "General",
            args = {
                desc = {
                    order = 1,
                    type = "description",
                    name = "Manage character groups and automated banking. Create groups with gold thresholds, and when you open a bank, the addon will automatically balance your gold to match the threshold (deposit excess or withdraw if below).",
                    fontSize = "medium",
                },
                autoDeposit = {
                    order = 2,
                    type = "toggle",
                    name = "Auto-balance gold with warbank",
                    desc = "Automatically deposit excess gold or withdraw if below threshold when opening a bank.",
                    width = "full",
                    get = function()
                        return self.db and self.db.autoDeposit;
                    end,
                    set = function(_, val)
                        if (self.db) then
                            self.db.autoDeposit = val and true or false;
                        end
                    end,
                },
                defaultThresholdHeader = {
                    order = 3,
                    type = "header",
                    name = "Ungrouped Characters",
                },
                useDefaultThreshold = {
                    order = 4,
                    type = "toggle",
                    name = "Use default threshold for ungrouped characters",
                    desc = "Apply a default gold threshold to characters not assigned to any group.",
                    width = "full",
                    get = function()
                        return self.db and self.db.useDefaultThreshold;
                    end,
                    set = function(_, val)
                        if (self.db) then
                            self.db.useDefaultThreshold = val and true or false;
                        end
                    end,
                },
                defaultThreshold = {
                    order = 5,
                    type = "input",
                    name = "Default gold threshold",
                    desc = "Gold threshold for characters not in any group. The addon will automatically balance to this amount.",
                    width = "normal",
                    disabled = function()
                        return not (self.db and self.db.useDefaultThreshold);
                    end,
                    get = function()
                        local val = self.db and self.db.defaultThreshold or 1000000000;
                        return formatGoldThousands(val);
                    end,
                    set = function(_, val)
                        local amount = parseGold(val);
                        if (amount and amount >= 0) then
                            self.db.defaultThreshold = amount;
                        end
                    end,
                },
                currentCharHeader = {
                    order = 6,
                    type = "header",
                    name = "Current Character",
                },
                currentChar = {
                    order = 7,
                    type = "description",
                    name = function()
                        local key = self:GetCurrentCharacter();
                        local group = self:GetCharacterGroup();
                        if (group) then
                            return string.format("|cff00ff00Current character:|r %s\n|cff00ff00Group:|r %s\n|cff00ff00Gold threshold:|r %s gold",
                                key or "Unknown",
                                group.name or "None",
                                formatGoldThousands(group.goldThreshold or 0));
                        else
                            local thresholdText = "";
                            if (self.db and self.db.useDefaultThreshold) then
                                thresholdText = string.format("\n|cff00ff00Default threshold:|r %s gold", formatGoldThousands(self.db.defaultThreshold or 1000000));
                            end
                            return string.format("|cff00ff00Current character:|r %s\n|cffff0000Not assigned to any group|r%s", key or "Unknown", thresholdText);
                        end
                    end,
                    fontSize = "medium",
                },
            },
        },
        groups = {
            order = 2,
            type = "group",
            name = "Groups",
            args = {},
        },
        characters = {
            order = 3,
            type = "group",
            name = "Characters",
            args = {},
        },
        warehousing = {
            order = 4,
            type = "group",
            name = "Warehousing",
            args = {},
        },
    };

    -- Build tabs using separate option builder files
    if (self.BuildGroupsOptions) then
        self:BuildGroupsOptions(options.groups.args, refreshOptions);
    end

    if (self.BuildCharactersOptions) then
        self:BuildCharactersOptions(options.characters.args, refreshOptions);
    end

    if (self.BuildWarehousingOptions) then
        self:BuildWarehousingOptions(options.warehousing.args, refreshOptions);
    end

    return options;
end
