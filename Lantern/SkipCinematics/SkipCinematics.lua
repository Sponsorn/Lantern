local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end
local L = Lantern.L;

local module = Lantern:NewModule("SkipCinematics", {
    title = L["SKIPCINEMATICS_TITLE"],
    desc = L["SKIPCINEMATICS_DESC"],
    defaultEnabled = false,
    skipOptions = true,
});

local DEFAULTS = {
    showMessage = true,
};

local function ensureDB(self)
    self.db = Lantern.utils.InitModuleDB(self.addon, "skipCinematics", DEFAULTS);
end

local function shouldPause()
    return Lantern:IsModifierDown();
end

function module:OnInit()
    ensureDB(self);
end

function module:OnEnable()
    ensureDB(self);
    self.addon:ModuleRegisterEvent(self, "PLAY_MOVIE", self.OnPlayMovie);
    self.addon:ModuleRegisterEvent(self, "CINEMATIC_START", self.OnCinematicStart);
end

function module:OnPlayMovie(_, movieID)
    if (not self.enabled or shouldPause()) then return; end
    MovieFrame:StopMovie();
    if (self.db.showMessage) then
        Lantern:Print(L["SKIPCINEMATICS_SKIPPED"]);
    end
end

function module:OnCinematicStart()
    if (not self.enabled or shouldPause()) then return; end
    if (CinematicFrame_CancelCinematic) then
        CinematicFrame_CancelCinematic();
    elseif (StopCinematic) then
        StopCinematic();
    end
    -- Handle scene system (slightly delayed to ensure scene state is ready)
    C_Timer.After(0.1, function()
        if (IsInCinematicScene and IsInCinematicScene() and CanCancelScene and CanCancelScene()) then
            CancelScene();
        end
    end);
    if (self.db.showMessage) then
        Lantern:Print(L["SKIPCINEMATICS_SKIPPED"]);
    end
end

Lantern:RegisterModule(module);
