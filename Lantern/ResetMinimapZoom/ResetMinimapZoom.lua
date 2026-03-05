local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end
local L = Lantern.L;

local module = Lantern:NewModule("ResetMinimapZoom", {
    title = L["RESETMINIMAPZOOM_TITLE"],
    desc = L["RESETMINIMAPZOOM_DESC"],
    defaultEnabled = false,
    DEFAULTS = { delay = 15 },
});

local pendingTimer;

local function cancelTimer()
    if (pendingTimer) then
        pendingTimer:Cancel();
        pendingTimer = nil;
    end
end

function module:OnEnable()
    self.addon:ModuleRegisterEvent(self, "MINIMAP_UPDATE_ZOOM", self.OnZoomChanged);
end

function module:OnDisable()
    cancelTimer();
end

function module:OnZoomChanged()
    if (not self.enabled) then return; end

    local zoom = Minimap:GetZoom();
    if (zoom == 0) then
        cancelTimer();
        return;
    end

    cancelTimer();

    local db = self.addon.db.resetMinimapZoom or {};
    local delay = db.delay or 15;

    pendingTimer = C_Timer.NewTimer(delay, function()
        pendingTimer = nil;
        if (not module.enabled) then return; end
        if (Minimap:GetZoom() > 0) then
            Minimap:SetZoom(0);
        end
    end);
end

Lantern:RegisterModule(module);
