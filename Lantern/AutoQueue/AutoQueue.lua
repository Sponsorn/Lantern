local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local module = Lantern:NewModule("AutoQueue", {
    title = "Auto Queue",
    desc = "Automatically accept role checks using your LFG role selection.",
    skipOptions = true,
});

local DEFAULTS = {
    active = true,
    announce = true,
};

local function ensureDB(self)
    -- Ensure parent db exists
    if (not self.addon.db) then
        return;
    end
    -- Initialize autoQueue table if it doesn't exist
    if (not self.addon.db.autoQueue) then
        self.addon.db.autoQueue = {};
    end
    -- Always reference the addon's autoQueue table directly
    self.db = self.addon.db.autoQueue;

    for k, v in pairs(DEFAULTS) do
        if (self.db[k] == nil) then
            self.db[k] = v;
        end
    end
end

local function shouldPause()
    return Lantern:IsModifierDown();
end

function module:OnInit()
    ensureDB(self);
end

function module:OnEnable()
    ensureDB(self);
    self.addon:ModuleRegisterEvent(self, "LFG_ROLE_CHECK_SHOW", self.OnRoleCheckShow);
end

function module:OnRoleCheckShow()
    if (not self.enabled or not self.db.active or shouldPause()) then return; end
    CompleteLFGRoleCheck(true);
    if (self.db.announce) then
        Lantern:Print("Auto-accepted role check.");
    end
end

Lantern:RegisterModule(module);
