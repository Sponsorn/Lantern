local ADDON_NAME = "Lantern_Warband";
local Lantern = _G.Lantern;
if (not Lantern) then return; end

local Warband = Lantern:NewModule("Warband", {
    title = "Warband",
    desc = "Manage character groups with automated banking features.",
});

-- Default settings
local DEFAULTS = {
    enabled = true,
    autoDeposit = true,
    groups = {},
    characterGroups = {}, -- Maps character name to group name
};

local function ensureDB(self)
    if (not _G.LanternWarbandDB) then
        _G.LanternWarbandDB = {};
    end
    self.db = _G.LanternWarbandDB;

    -- Initialize defaults (skip tables to preserve saved data)
    for k, v in pairs(DEFAULTS) do
        if (self.db[k] == nil) then
            if (type(v) ~= "table") then
                self.db[k] = v;
            end
        end
    end

    -- Ensure groups table exists
    if (type(self.db.groups) ~= "table") then
        self.db.groups = {};
    end

    -- Ensure characterGroups table exists
    if (type(self.db.characterGroups) ~= "table") then
        self.db.characterGroups = {};
    end
end

local function getCurrentCharacterGroup(self)
    local key = Lantern:GetCharacterKey();
    if (not key) then return nil; end

    local groupName = self.db.characterGroups[key];
    if (not groupName) then return nil; end

    return self.db.groups[groupName];
end

local function getPlayerGold()
    return GetMoney and GetMoney() or 0;
end

local function depositToWarbank(amount)
    if (not C_Bank or not C_Bank.CanUseBank or not C_Bank.DepositMoney) then
        return false;
    end

    if (not C_Bank.CanUseBank(Enum.BankType.Account)) then
        return false;
    end

    C_Bank.DepositMoney(Enum.BankType.Account, amount);
    return true;
end

local function withdrawFromWarbank(amount)
    if (not C_Bank or not C_Bank.CanUseBank or not C_Bank.WithdrawMoney) then
        return false;
    end

    if (not C_Bank.CanUseBank(Enum.BankType.Account)) then
        return false;
    end

    C_Bank.WithdrawMoney(Enum.BankType.Account, amount);
    return true;
end

local function calculateDepositAmount(self)
    local group = getCurrentCharacterGroup(self);
    if (not group or not group.goldThreshold) then
        return 0;
    end

    local currentGold = getPlayerGold();
    local threshold = group.goldThreshold;

    if (currentGold <= threshold) then
        return 0;
    end

    return currentGold - threshold;
end

local function calculateWithdrawAmount(self)
    local group = getCurrentCharacterGroup(self);
    if (not group or not group.goldThreshold or group.goldThreshold == 0) then
        return 0;
    end

    local currentGold = getPlayerGold();
    local threshold = group.goldThreshold;

    -- Only withdraw if below threshold
    if (currentGold >= threshold) then
        return 0;
    end

    return threshold - currentGold;
end

local function handleBankOpened(self)
    if (not self.db or not self.db.autoDeposit or not self.enabled) then
        return;
    end

    -- Wait a frame to ensure bank is fully loaded
    C_Timer.After(0.5, function()
        local group = getCurrentCharacterGroup(self);
        if (not group) then
            return;
        end

        -- Check if we need to deposit
        local depositAmount = calculateDepositAmount(self);
        if (depositAmount > 0) then
            local success = depositToWarbank(depositAmount);
            if (success) then
                local formatted = Lantern:Convert("money:format_gold_thousands", depositAmount) or "0";
                Lantern:Print(string.format("Deposited %s gold to warbank.", formatted));
            end
            return;
        end

        -- Check if we need to withdraw
        local withdrawAmount = calculateWithdrawAmount(self);
        if (withdrawAmount > 0) then
            local success = withdrawFromWarbank(withdrawAmount);
            if (success) then
                local formatted = Lantern:Convert("money:format_gold_thousands", withdrawAmount) or "0";
                Lantern:Print(string.format("Withdrew %s gold from warbank.", formatted));
            end
        end
    end);
end

function Warband:OnInit()
    -- Don't initialize DB here - SavedVariables haven't loaded yet
    -- DB will be initialized in ADDON_LOADED event
end

function Warband:OnEnable()
    -- Ensure DB is initialized when module is enabled
    ensureDB(self);

    -- Register events for bank interaction
    self.addon:ModuleRegisterEvent(self, "BANKFRAME_OPENED", function(module)
        handleBankOpened(module);
    end);
end

function Warband:OnDisable()
    -- Events are automatically unregistered by the core module system
end

-- Public API for managing groups
function Warband:CreateGroup(groupName, goldThreshold)
    if (not groupName or groupName == "") then return false; end

    ensureDB(self);

    self.db.groups[groupName] = {
        name = groupName,
        goldThreshold = goldThreshold or 100000, -- Default 10g in copper
        members = {},
    };

    return true;
end

function Warband:DeleteGroup(groupName)
    if (not groupName or not self.db.groups[groupName]) then
        return false;
    end

    -- Remove all character assignments to this group
    for charKey, assignedGroup in pairs(self.db.characterGroups) do
        if (assignedGroup == groupName) then
            self.db.characterGroups[charKey] = nil;
        end
    end

    self.db.groups[groupName] = nil;
    return true;
end

function Warband:RenameGroup(oldName, newName)
    if (not oldName or not newName) then
        return false;
    end

    if (not self.db.groups[oldName]) then
        return false;
    end

    if (self.db.groups[newName]) then
        return false;
    end

    -- Copy group to new name
    self.db.groups[newName] = self.db.groups[oldName];
    self.db.groups[newName].name = newName;

    -- Update character assignments
    for charKey, groupName in pairs(self.db.characterGroups) do
        if (groupName == oldName) then
            self.db.characterGroups[charKey] = newName;
        end
    end

    -- Delete old group
    self.db.groups[oldName] = nil;

    return true;
end

function Warband:AssignCharacterToGroup(characterKey, groupName)
    if (not characterKey or characterKey == "") then return false; end
    if (not groupName or not self.db.groups[groupName]) then return false; end

    -- First, remove from old group if assigned to one
    local oldGroupName = self.db.characterGroups[characterKey];
    if (oldGroupName and oldGroupName ~= groupName) then
        local oldGroup = self.db.groups[oldGroupName];
        if (oldGroup and oldGroup.members) then
            for i = #oldGroup.members, 1, -1 do
                if (oldGroup.members[i] == characterKey) then
                    table.remove(oldGroup.members, i);
                end
            end
        end
    end

    -- Now assign to new group
    self.db.characterGroups[characterKey] = groupName;

    -- Add to group members if not already there
    local group = self.db.groups[groupName];
    if (not group.members) then
        group.members = {};
    end

    local found = false;
    for _, member in ipairs(group.members) do
        if (member == characterKey) then
            found = true;
            break;
        end
    end

    if (not found) then
        table.insert(group.members, characterKey);
    end

    return true;
end

function Warband:RemoveCharacterFromGroup(characterKey)
    if (not characterKey) then return false; end

    local groupName = self.db.characterGroups[characterKey];
    if (not groupName) then return false; end

    -- Remove from characterGroups
    self.db.characterGroups[characterKey] = nil;

    -- Remove from group members
    local group = self.db.groups[groupName];
    if (group and group.members) then
        for i = #group.members, 1, -1 do
            if (group.members[i] == characterKey) then
                table.remove(group.members, i);
            end
        end
    end

    return true;
end

function Warband:GetCurrentCharacter()
    return Lantern:GetCharacterKey();
end

function Warband:GetCharacterGroup(characterKey)
    if (not characterKey) then
        characterKey = Lantern:GetCharacterKey();
    end

    local groupName = self.db.characterGroups[characterKey];
    if (not groupName) then return nil; end

    return self.db.groups[groupName];
end

function Warband:SetGroupGoldThreshold(groupName, threshold)
    if (not groupName or not self.db.groups[groupName]) then
        return false;
    end

    local thresholdNum = tonumber(threshold);
    if (not thresholdNum or thresholdNum < 0) then
        return false;
    end

    self.db.groups[groupName].goldThreshold = thresholdNum;
    return true;
end

function Warband:GetAllGroups()
    local groups = {};
    for name, group in pairs(self.db.groups or {}) do
        table.insert(groups, group);
    end
    return groups;
end

-- Register the module
Lantern:RegisterModule(Warband);

-- Listen for our own ADDON_LOADED to refresh options after SavedVariables load
local frame = CreateFrame("Frame");
frame:RegisterEvent("ADDON_LOADED");
frame:SetScript("OnEvent", function(_, event, addonName)
    if (addonName ~= ADDON_NAME) then return; end

    -- SavedVariables are now loaded, initialize database
    ensureDB(Warband);

    -- Small delay to refresh the options UI
    C_Timer.After(0.1, function()
        if (not Warband or not Warband.GetOptions) then
            return;
        end

        local AceConfig = LibStub and LibStub("AceConfig-3.0", true);
        local AceConfigRegistry = LibStub and LibStub("AceConfigRegistry-3.0", true);

        if (not AceConfig or not AceConfigRegistry) then
            return;
        end

        local key = "module_Warband";
        local newOptions = Warband:GetOptions();

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
                    get = function() return Warband.enabled; end,
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
    end);
end);
