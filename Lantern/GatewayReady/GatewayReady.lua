local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end
local L = Lantern.L;

local UX = Lantern.UX;
local GetFontPath = Lantern.utils.GetFontPath;
local SafeSetFont = Lantern.utils.SafeSetFont;

local module = Lantern:NewModule("GatewayReady", {
    title = L["GATEWAYREADY_TITLE"],
    desc = L["GATEWAYREADY_DESC"],
    defaultEnabled = false,
});

local GATEWAY_ITEM_ID = 188152;
local POLL_INTERVAL = 0.1;

local DEFAULTS = {
    combatOnly = true,
    font = "Roboto Light",
    fontSize = 28,
    fontOutline = "OUTLINE",
    color = { r = 0.61, g = 0.35, b = 0.71 }, -- purple
    soundEnabled = false,
    soundName = "RaidWarning",
    locked = true,
    pos = nil,
};

local banner, label;
local ticker = nil;
local lastUsable = false;
local soundPlayed = false;

local function ensureDB(self)
    self.db = Lantern.utils.InitModuleDB(self.addon, "gatewayReady", DEFAULTS);
end

local previewMode = false;

local function createFrame(self)
    if (banner) then return; end

    banner = CreateFrame("Frame", "Lantern_GatewayReady", UIParent, "BackdropTemplate");
    banner:SetSize(400, 50);
    banner:SetPoint("CENTER", UIParent, "CENTER", 0, 200);
    banner:SetFrameStrata("HIGH");
    banner:Hide();

    label = banner:CreateFontString("Lantern_GatewayReady_Text", "ARTWORK");
    SafeSetFont(label, GetFontPath(DEFAULTS.font), DEFAULTS.fontSize, DEFAULTS.fontOutline);
    label:SetPoint("CENTER");
    label:SetShadowOffset(2, -2);
    label:SetShadowColor(0, 0, 0, 0.8);

    if (UX and UX.MakeDraggable) then
        UX.MakeDraggable(banner, {
            getPos    = function() return self.db and self.db.pos; end,
            setPos    = function(pos) if (self.db) then self.db.pos = pos; end end,
            getLocked = function() return self.db and self.db.locked; end,
            setLocked = function(val) if (self.db) then self.db.locked = val; end end,
            defaultPoint = { "CENTER", UIParent, "CENTER", 0, 200 },
            text = label,
            placeholder = L["GATEWAYREADY_TEXT"],
        });
    end

end

local function showAlert(self)
    if (not banner) then createFrame(self); end

    local db = self.db or DEFAULTS;
    local fontName = db.font or DEFAULTS.font;
    local size = db.fontSize or DEFAULTS.fontSize;
    local outline = db.fontOutline or DEFAULTS.fontOutline;
    SafeSetFont(label, GetFontPath(fontName), size, outline);
    label:SetText(L["GATEWAYREADY_TEXT"]);

    local color = db.color or DEFAULTS.color;
    label:SetTextColor(color.r, color.g, color.b, 1);

    banner:SetAlpha(1);
    banner:Show();

    if (not soundPlayed and db.soundEnabled) then
        local media = LibStub and LibStub("LibSharedMedia-3.0", true);
        if (media) then
            local sound = media:Fetch("sound", db.soundName or "RaidWarning");
            if (sound) then
                pcall(PlaySoundFile, sound, "Master");
            end
        end
        soundPlayed = true;
    end
end

local function hideAlert()
    if (banner) then
        banner:Hide();
    end
    soundPlayed = false;
end

local function checkGateway(self)
    if (not self.enabled) then return; end

    if (UnitIsDeadOrGhost("player")) then
        if (lastUsable) then hideAlert(); end
        lastUsable = false;
        return;
    end

    local count = C_Item.GetItemCount(GATEWAY_ITEM_ID);
    if (count == 0) then
        if (lastUsable) then hideAlert(); end
        lastUsable = false;
        return;
    end

    local db = self.db or DEFAULTS;
    if (db.combatOnly and not InCombatLockdown()) then
        if (lastUsable) then hideAlert(); end
        lastUsable = false;
        return;
    end

    local isUsable = C_Item.IsUsableItem(GATEWAY_ITEM_ID);

    if (isUsable) then
        showAlert(self);
    elseif (lastUsable) then
        hideAlert();
    end

    lastUsable = isUsable;
end

local function startPolling(self)
    if (ticker) then return; end
    ticker = C_Timer.NewTicker(POLL_INTERVAL, function()
        checkGateway(self);
    end);
end

local function stopPolling()
    if (ticker) then
        ticker:Cancel();
        ticker = nil;
    end
    lastUsable = false;
    hideAlert();
end

function module:RefreshFont()
    if (not label) then return; end
    local db = self.db or DEFAULTS;
    SafeSetFont(label, GetFontPath(db.font or DEFAULTS.font), db.fontSize or DEFAULTS.fontSize, db.fontOutline or DEFAULTS.fontOutline);
end

function module:GetFrame()
    return banner;
end

function module:SetPreviewMode(enabled)
    previewMode = enabled;
    if (not banner) then createFrame(self); end
    if (enabled) then
        local db = self.db or DEFAULTS;
        SafeSetFont(label, GetFontPath(db.font or DEFAULTS.font), db.fontSize or DEFAULTS.fontSize, db.fontOutline or DEFAULTS.fontOutline);
        label:SetText(L["GATEWAYREADY_TEXT"]);
        local color = db.color or DEFAULTS.color;
        label:SetTextColor(color.r, color.g, color.b, 1);
        banner:SetAlpha(1);
        banner:Show();
        -- Auto-disable preview when settings panel closes
        if (not self._previewTicker) then
            self._previewTicker = C_Timer.NewTicker(0.5, function()
                if (not previewMode) then
                    if (self._previewTicker) then self._previewTicker:Cancel(); self._previewTicker = nil; end
                    return;
                end
                local panel = Lantern._uxPanel;
                local shown = panel and panel._frame and panel._frame:IsShown();
                if (not shown) then
                    self:SetPreviewMode(false);
                end
            end);
        end
    else
        if (self._previewTicker) then self._previewTicker:Cancel(); self._previewTicker = nil; end
        banner:Hide();
    end
end

function module:IsPreviewActive()
    return previewMode;
end

function module:UpdateLock()
    if (not banner) then return; end
    banner:UpdateLock();
    if (self.db and self.db.locked and not lastUsable and not previewMode) then
        banner:Hide();
    end
end

function module:ResetPosition()
    if (not banner) then return; end
    banner:ResetPosition();
end

function module:OnInit()
    ensureDB(self);
end

function module:OnEnable()
    ensureDB(self);
    createFrame(self);
    banner:RestorePosition();
    banner:UpdateLock();

    if (self.db and self.db.anchorTo and self.db.anchorTo ~= "none") then
        Lantern:ApplyAnchorBinding({
            frame = banner,
            getAnchorId = function() return self.db.anchorTo or "none"; end,
            setAnchorId = function(id) self.db.anchorTo = id; end,
            getOffsetX = function() return self.db.anchorOffsetX or 0; end,
            getOffsetY = function() return self.db.anchorOffsetY or 0; end,
        });
    end

    self.addon:ModuleRegisterEvent(self, "PLAYER_REGEN_DISABLED", function()
        if (not self.enabled) then return; end
        if (self.db and self.db.combatOnly) then
            startPolling(self);
        end
    end);

    self.addon:ModuleRegisterEvent(self, "PLAYER_REGEN_ENABLED", function()
        if (self.db and self.db.combatOnly) then
            stopPolling();
        end
    end);

    -- If not combat-only, start polling immediately
    if (not self.db.combatOnly) then
        startPolling(self);
    end
end

function module:OnDisable()
    stopPolling();
    hideAlert();
end

Lantern:RegisterModule(module);
