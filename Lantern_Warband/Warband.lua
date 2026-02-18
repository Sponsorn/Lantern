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
    useDefaultThreshold = false, -- Apply default threshold to ungrouped characters
    defaultThreshold = 1000000000, -- 100k gold default for ungrouped characters (in copper)
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

    -- Migrate old rules-based warehousing schema to groups
    if (type(self.db.warehousing) == "table" and self.db.warehousing.rules) then
        self.db.warehousing = { groups = {} };
    end
    -- Ensure new warehousing schema
    if (type(self.db.warehousing) ~= "table") then
        self.db.warehousing = { groups = {} };
    end
    if (type(self.db.warehousing.groups) ~= "table") then
        self.db.warehousing.groups = {};
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
    local threshold;
    local allowDeposit = true;

    if (group and group.goldThreshold ~= nil) then
        threshold = group.goldThreshold;
        -- Check if deposit is allowed for this group (default to true for existing groups)
        if (group.allowDeposit ~= nil) then
            allowDeposit = group.allowDeposit;
        end
    elseif (self.db.useDefaultThreshold) then
        -- Use default threshold for ungrouped characters if enabled
        threshold = self.db.defaultThreshold or 1000000000;
    else
        return 0;
    end

    if (not allowDeposit) then
        return 0;
    end

    local currentGold = getPlayerGold();

    -- If threshold is 0, deposit all gold
    if (threshold == 0) then
        return currentGold;
    end

    if (currentGold <= threshold) then
        return 0;
    end

    return currentGold - threshold;
end

local function calculateWithdrawAmount(self)
    local group = getCurrentCharacterGroup(self);
    local threshold;
    local allowWithdraw = true;

    if (group and group.goldThreshold ~= nil) then
        threshold = group.goldThreshold;
        -- Check if withdraw is allowed for this group (default to true for existing groups)
        if (group.allowWithdraw ~= nil) then
            allowWithdraw = group.allowWithdraw;
        end
    elseif (self.db.useDefaultThreshold) then
        -- Use default threshold for ungrouped characters if enabled
        threshold = self.db.defaultThreshold or 1000000000;
    else
        return 0;
    end

    if (not allowWithdraw) then
        return 0;
    end

    -- If threshold is 0, don't withdraw (deposit-only mode)
    if (threshold == 0) then
        return 0;
    end

    local currentGold = getPlayerGold();

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

        -- Skip if no group and default threshold is not enabled
        if (not group and not self.db.useDefaultThreshold) then
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
        module.bankOpen = true;
        handleBankOpened(module);
    end);

    self.addon:ModuleRegisterEvent(self, "BANKFRAME_CLOSED", function(module)
        module.bankOpen = false;
    end);
end

function Warband:OnDisable()
    -- Events are automatically unregistered by the core module system
end

-- Public API for managing groups
function Warband:CreateGroup(groupName, goldThreshold, allowDeposit, allowWithdraw)
    if (not groupName or groupName == "") then return false; end

    ensureDB(self);

    -- Handle boolean flags properly (false is a valid value)
    local finalAllowDeposit = true;
    if (allowDeposit ~= nil) then
        finalAllowDeposit = allowDeposit;
    end

    local finalAllowWithdraw = true;
    if (allowWithdraw ~= nil) then
        finalAllowWithdraw = allowWithdraw;
    end

    self.db.groups[groupName] = {
        name = groupName,
        goldThreshold = goldThreshold or 1000000000, -- Default 100k gold in copper
        members = {},
        allowDeposit = finalAllowDeposit,
        allowWithdraw = finalAllowWithdraw,
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
    if (thresholdNum == nil or thresholdNum < 0) then
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

-- Listen for our own ADDON_LOADED to initialize database after SavedVariables load
local frame = CreateFrame("Frame", "LanternWarband_LoadFrame");
frame:RegisterEvent("ADDON_LOADED");
frame:SetScript("OnEvent", function(_, event, addonName)
    if (addonName ~= ADDON_NAME) then return; end
    ensureDB(Warband);
end);
