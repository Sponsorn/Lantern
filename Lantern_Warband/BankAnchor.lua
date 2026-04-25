local Lantern = _G.Lantern;
if (not Lantern or not Lantern.modules or not Lantern.modules.Warband) then return; end

local Warband = Lantern.modules.Warband;

local BankAnchor = {};
Warband.BankAnchor = BankAnchor;

-- State
local isBaganator = false;
local currentBankView = nil;
local anchorListeners = {};
local tabListeners = {};
local bankPanelHooked = false;

-- Baganator names its bank view frames "Baganator_<single|category>ViewBankViewFrame<skinKey>".
-- The skin key suffix is dynamic, so we discover frames by name pattern at PLAYER_LOGIN.
local BAGANATOR_FRAME_PATTERNS = {
    "^Baganator_SingleViewBankViewFrame",
    "^Baganator_CategoryViewBankViewFrame",
};
local discoveredFrames = {};

-------------------------------------------------------------------------------
-- Internal helpers
-------------------------------------------------------------------------------

local function safeCall(fn, context)
    if (type(fn) ~= "function") then return; end
    local success, err = pcall(fn);
    if (not success) then
        print("|cffe08f2eLantern error|r in " .. (context or "unknown") .. ": " .. tostring(err));
    end
end

local function FireAnchorChanged()
    for _, fn in ipairs(anchorListeners) do
        safeCall(fn, "BankAnchor anchor listener");
    end
end

local function FireTabChanged()
    for _, fn in ipairs(tabListeners) do
        safeCall(fn, "BankAnchor tab listener");
    end
end

local function IsBaganatorBankView(frame)
    if (not frame or type(frame.GetName) ~= "function") then return false; end
    local ok, name = pcall(frame.GetName, frame);
    if (not ok or type(name) ~= "string") then return false; end
    local nameMatches = false;
    for _, pattern in ipairs(BAGANATOR_FRAME_PATTERNS) do
        if (name:match(pattern)) then
            nameMatches = true;
            break;
        end
    end
    if (not nameMatches) then return false; end
    -- Filter out child widgets (CloseButton, ClearButton, etc.) that share the parent's name prefix.
    -- Real bank view frames inherit BaganatorItemViewCommonBankViewMixin which adds these methods.
    return type(frame.UpdateViewToWarband) == "function" and type(frame.UpdateViewToCharacter) == "function";
end

local function DiscoverBaganatorFrames()
    discoveredFrames = {};
    local frame = EnumerateFrames();
    while (frame) do
        if (IsBaganatorBankView(frame)) then
            table.insert(discoveredFrames, frame);
        end
        frame = EnumerateFrames(frame);
    end
end

local function ResolveBaganatorView()
    -- Pick the first discovered frame that is currently shown; fall back to first that exists
    local fallback = nil;
    for _, frame in ipairs(discoveredFrames) do
        if (frame:IsShown()) then
            return frame;
        end
        if (not fallback) then
            fallback = frame;
        end
    end
    return fallback;
end

local function HookBaganatorViewOnShow()
    for _, frame in ipairs(discoveredFrames) do
        if (not frame._lanternBankAnchorHooked) then
            frame:HookScript("OnShow", function(self)
                if (currentBankView ~= self) then
                    currentBankView = self;
                    FireAnchorChanged();
                end
            end);
            frame._lanternBankAnchorHooked = true;
        end
    end
end

local function HookBankPanelTabChange()
    if (bankPanelHooked) then return; end
    if (not BankFrame or not BankFrame.BankPanel) then return; end
    hooksecurefunc(BankFrame.BankPanel, "SetBankType", function()
        FireTabChanged();
    end);
    bankPanelHooked = true;
end

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------

function BankAnchor:IsBaganatorActive()
    return isBaganator;
end

function BankAnchor:GetBankParent()
    if (isBaganator) then
        local view = currentBankView or ResolveBaganatorView();
        if (view) then return view; end
    end
    return BankFrame;
end

function BankAnchor:GetButtonAnchorTarget()
    if (isBaganator) then
        local view = currentBankView or ResolveBaganatorView();
        if (view) then
            -- Anchor to the leftmost Baganator title-bar button so we sit to the left of all of them.
            -- Hidden buttons still resolve their position via the anchor chain, so they're valid targets.
            return view.TransferButton or view.SortButton or view.CustomiseButton or view.CloseButton;
        end
    end
    return nil;
end

function BankAnchor:GetPanelAnchorTarget()
    return self:GetBankParent();
end

function BankAnchor:IsAccountBankActive()
    -- Read BankPanel directly: BankFrame:GetActiveBankType() returns nil when BankPanel is hidden,
    -- which happens in Baganator mode even though Baganator still calls SetBankType correctly.
    local panel = BankFrame and BankFrame.BankPanel;
    if (not panel or not panel.GetActiveBankType) then return false; end
    return panel:GetActiveBankType() == Enum.BankType.Account;
end

function BankAnchor:RegisterAnchorChangedListener(fn)
    table.insert(anchorListeners, fn);
end

function BankAnchor:RegisterTabChangedListener(fn)
    table.insert(tabListeners, fn);
end

-------------------------------------------------------------------------------
-- Initialization
-------------------------------------------------------------------------------

local function DiscoverAndHookBaganator()
    if (not isBaganator) then return; end
    DiscoverBaganatorFrames();
    HookBaganatorViewOnShow();
    local newView = ResolveBaganatorView();
    if (newView ~= currentBankView) then
        currentBankView = newView;
        FireAnchorChanged();
    end
end

local function Initialize()
    isBaganator = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Baganator") or false;

    -- BankFrame.BankPanel is created at game load; hook now if available, otherwise consumers call EnsureBankPanelHook from their BANKFRAME_OPENED handler
    HookBankPanelTabChange();
end

function BankAnchor:EnsureBankPanelHook()
    HookBankPanelTabChange();
    -- If Baganator's PLAYER_LOGIN handler ran after ours, OR if discovery was incomplete because
    -- a third-party addon's frame errored out mid-iteration, we may not have a view yet.
    -- Retry now that the bank has opened — frames are guaranteed to exist by this point.
    if (isBaganator and not currentBankView) then
        DiscoverAndHookBaganator();
    end
end

-- Re-detect if Baganator loads after us
local addonLoadedFrame = CreateFrame("Frame", "LanternWarband_BankAnchor_AddonLoaded");
addonLoadedFrame:RegisterEvent("ADDON_LOADED");
addonLoadedFrame:SetScript("OnEvent", function(self, event, addonName)
    if (addonName == "Baganator" and not isBaganator) then
        isBaganator = true;
        DiscoverAndHookBaganator();
        FireAnchorChanged();
    end
end);

-- Baganator creates its bank view frames in its own PLAYER_LOGIN handler.
-- Defer our frame discovery until after that fires so we find them with the correct skin-suffix names.
local playerLoginFrame = CreateFrame("Frame", "LanternWarband_BankAnchor_PlayerLogin");
playerLoginFrame:RegisterEvent("PLAYER_LOGIN");
playerLoginFrame:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN");
    DiscoverAndHookBaganator();
end);

Initialize();
