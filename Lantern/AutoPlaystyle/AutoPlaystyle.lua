local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end
local L = Lantern.L;

local module = Lantern:NewModule("AutoPlaystyle", {
    title = L["AUTOPLAYSTYLE_TITLE"],
    desc = L["AUTOPLAYSTYLE_DESC"],
});

local function ensureDB(self)
    if (not self.addon.db) then return; end
    if (not self.addon.db.autoPlaystyle) then
        self.addon.db.autoPlaystyle = {};
    end
    self.db = self.addon.db.autoPlaystyle;

    if (self.db.playstyle == nil) then
        self.db.playstyle = 3; -- Enum.LFGEntryGeneralPlaystyle.FunSerious
    end
end

function module:OnInit()
    ensureDB(self);
end

function module:OnEnable()
    ensureDB(self);
    self:SetupHooks();
end

function module:OnDisable()
    -- hooksecurefunc hooks cannot be removed; we check self.enabled inside them
end

-------------------------------------------------------------------------------
-- Hooks
-------------------------------------------------------------------------------

function module:SetupHooks()
    if (self._hooked) then return; end

    -- Blizzard_GroupFinder is demand-loaded (opens when player opens Group Finder)
    if (type(LFGListEntryCreation_Show) == "function") then
        self:InstallHooks();
    else
        self.addon:ModuleRegisterEvent(self, "ADDON_LOADED", self.OnAddonLoaded);
    end
end

function module:OnAddonLoaded(event, name)
    if (name == "Blizzard_GroupFinder" and not self._hooked) then
        self:InstallHooks();
    end
end

function module:InstallHooks()
    if (self._hooked) then return; end
    self._hooked = true;

    -- Hook the listing dialog show (new listing flow).
    -- Fires AFTER Blizzard's code, so the activity is already selected.
    hooksecurefunc("LFGListEntryCreation_Show", function(entryCreation)
        if (not module.enabled) then return; end
        module:ApplyPlaystyle(entryCreation);
    end);

    -- Hook activity selection (handles manual dungeon pick).
    hooksecurefunc("LFGListEntryCreation_Select", function(entryCreation, filters, categoryID, groupID, activityID)
        if (not module.enabled) then return; end
        if (not activityID) then return; end
        local activityInfo = C_LFGList.GetActivityInfoTable(activityID);
        if (not activityInfo or not activityInfo.isMythicPlusActivity) then return; end
        module:ApplyPlaystyle(entryCreation);
    end);
end

-------------------------------------------------------------------------------
-- Playstyle auto-selection
-------------------------------------------------------------------------------

local PLAYSTYLE_GLOBALS = {
    "GROUP_FINDER_GENERAL_PLAYSTYLE1",
    "GROUP_FINDER_GENERAL_PLAYSTYLE2",
    "GROUP_FINDER_GENERAL_PLAYSTYLE3",
    "GROUP_FINDER_GENERAL_PLAYSTYLE4",
};

function module:ApplyPlaystyle(entryCreation)
    if (not entryCreation) then return; end

    local playstyle = self.db.playstyle;
    if (not playstyle or playstyle < 1 or playstyle > 4) then return; end

    -- Set playstyle on the frame table (read by "List Group" button)
    entryCreation.generalPlaystyle = playstyle;

    -- Update the dropdown's visual text to match
    local dropdown = entryCreation.PlayStyleDropdown;
    if (dropdown and dropdown.SetText) then
        local text = _G[PLAYSTYLE_GLOBALS[playstyle]];
        if (text) then
            dropdown:SetText(text);
        end
    end
end

Lantern:RegisterModule(module);
