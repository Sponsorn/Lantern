local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end
local L = Lantern.L;

local module = Lantern:NewModule("UIAnchors", {
    title = L["UIANCHORS_TITLE"],
    desc = L["UIANCHORS_DESC"],
});

local ANCHOR_DEFS = Lantern.UI_ANCHORS;
local ANCHOR_BY_ID = Lantern.UI_ANCHORS_BY_ID;

local DEFAULTS = {};

local function ensureDB()
    module.db = Lantern.utils.InitModuleDB(Lantern, "uiAnchors", DEFAULTS);
    module.db.layouts = module.db.layouts or {};
    module.db.previews = module.db.previews or {};
end

-------------------------------------------------------------------------------
-- Position helpers
-------------------------------------------------------------------------------

local function getScreenSize()
    local w, h = GetPhysicalScreenSize();
    return w or 1920, h or 1080;
end

local function pctToPixels(xPct, yPct)
    local sw, sh = getScreenSize();
    return xPct * sw, yPct * sh;
end

-------------------------------------------------------------------------------
-- Per-anchor enable/disable (per layout)
-------------------------------------------------------------------------------

local function getLayoutData(anchorId)
    ensureDB();
    local layoutName = module.db.activeLayout or "Default";
    local layout = module.db.layouts[layoutName];
    return layout and layout[anchorId];
end

local function ensureLayoutEntry(anchorId)
    ensureDB();
    local layoutName = module.db.activeLayout or "Default";
    module.db.layouts[layoutName] = module.db.layouts[layoutName] or {};
    module.db.layouts[layoutName][anchorId] = module.db.layouts[layoutName][anchorId] or {};
    return module.db.layouts[layoutName][anchorId];
end

function module:IsAnchorEnabled(anchorId)
    local data = getLayoutData(anchorId);
    -- Default to DISABLED (false) — users opt in
    return data and data.enabled or false;
end

function module:SetAnchorEnabled(anchorId, enabled)
    local data = ensureLayoutEntry(anchorId);
    data.enabled = enabled;
    self:ApplyAnchorVisibility(anchorId);
    -- If anchors are currently shown, update visuals immediately
    if (module._anchorsVisible) then
        if (enabled and self.ShowAnchorVisuals) then
            self:ShowAnchorVisuals(anchorId);
        elseif (not enabled and self.HideAnchorVisuals) then
            self:HideAnchorVisuals(anchorId);
        end
    end
end

function module:ApplyAnchorVisibility(anchorId)
    local frame = self.frames[anchorId];
    if (not frame) then return; end
    if (self:IsAnchorEnabled(anchorId) and self.enabled) then
        frame:Show();
    else
        frame:Hide();
    end
end

function module:ApplyAllVisibility()
    for _, def in ipairs(ANCHOR_DEFS) do
        self:ApplyAnchorVisibility(def.id);
    end
end

-------------------------------------------------------------------------------
-- Position storage
-------------------------------------------------------------------------------

function module:GetAnchorPosition(anchorId)
    local data = getLayoutData(anchorId);
    if (data and data.xPct) then
        return data.xPct, data.yPct;
    end
    local def = ANCHOR_BY_ID[anchorId];
    if (def) then
        return def.defaultPos.xPct, def.defaultPos.yPct;
    end
    return 0, 0;
end

function module:SaveAnchorPosition(anchorId, xPct, yPct)
    local data = ensureLayoutEntry(anchorId);
    data.xPct = xPct;
    data.yPct = yPct;
end

function module:GetPreviewSettings(anchorId)
    ensureDB();
    local def = ANCHOR_BY_ID[anchorId];
    if (not def) then return { count = 3, width = 100, height = 20, spacing = 3 }; end
    local saved = self.db.previews[anchorId];
    if (saved) then
        return {
            count   = saved.count   or def.defaultPreview.count,
            width   = saved.width   or def.defaultPreview.width,
            height  = saved.height  or def.defaultPreview.height,
            spacing = saved.spacing or def.defaultPreview.spacing,
        };
    end
    return {
        count   = def.defaultPreview.count,
        width   = def.defaultPreview.width,
        height  = def.defaultPreview.height,
        spacing = def.defaultPreview.spacing,
    };
end

function module:SavePreviewSetting(anchorId, key, value)
    ensureDB();
    self.db.previews[anchorId] = self.db.previews[anchorId] or {};
    self.db.previews[anchorId][key] = value;
end

-------------------------------------------------------------------------------
-- Frame creation & positioning
-------------------------------------------------------------------------------

module.frames = {};

local function clampToScreen(xOff, yOff, margin)
    local sw, sh = getScreenSize();
    margin = margin or 0;
    local halfW, halfH = sw / 2, sh / 2;
    xOff = math.max(-halfW + margin, math.min(halfW - margin, xOff));
    yOff = math.max(-halfH + margin, math.min(halfH - margin, yOff));
    return xOff, yOff;
end

local function positionFrame(frame, anchorId)
    local xPct, yPct = module:GetAnchorPosition(anchorId);
    local xOff, yOff = pctToPixels(xPct, yPct);
    xOff, yOff = clampToScreen(xOff, yOff, 20);
    frame:ClearAllPoints();
    frame:SetPoint("CENTER", UIParent, "CENTER", xOff, yOff);
end

local function createAnchorFrame(def)
    local frame = CreateFrame("Frame", def.frameName, UIParent);
    frame:SetSize(1, 1);
    frame:SetFrameStrata("BACKGROUND");
    frame:Hide(); -- hidden until enabled
    frame.anchorId = def.id;
    frame.anchorDef = def;
    positionFrame(frame, def.id);
    module.frames[def.id] = frame;
    return frame;
end

function module:RepositionAllAnchors()
    for _, def in ipairs(ANCHOR_DEFS) do
        local frame = self.frames[def.id];
        if (frame) then
            positionFrame(frame, def.id);
        end
    end
end

function module:ResetAnchorPosition(anchorId)
    local data = getLayoutData(anchorId);
    if (data) then
        data.xPct = nil;
        data.yPct = nil;
    end
    local frame = self.frames[anchorId];
    if (frame) then
        positionFrame(frame, anchorId);
    end
end

function module:ResetAllPositions()
    ensureDB();
    local layoutName = self.db.activeLayout or "Default";
    local layout = self.db.layouts[layoutName];
    if (layout) then
        -- Clear positions but preserve enabled state
        for anchorId, data in pairs(layout) do
            data.xPct = nil;
            data.yPct = nil;
        end
    end
    self:RepositionAllAnchors();
end

-------------------------------------------------------------------------------
-- Public API — for other modules to consume anchors
-------------------------------------------------------------------------------

-- Returns the anchor frame if the anchor is enabled, nil otherwise.
function Lantern:GetAnchorFrame(anchorId)
    local mod = self.modules["UIAnchors"];
    if (not mod or not mod.enabled) then return nil; end
    if (not mod:IsAnchorEnabled(anchorId)) then return nil; end
    return mod.frames[anchorId];
end

-- Returns a list of { id, label, frameName } for enabled anchors.
-- Optional previewType filter: "bar", "icon", "text", or nil for all.
function Lantern:GetEnabledAnchors(previewType)
    local mod = self.modules["UIAnchors"];
    local result = {};
    if (not mod or not mod.enabled) then return result; end
    for _, def in ipairs(Lantern.UI_ANCHORS) do
        if (mod:IsAnchorEnabled(def.id)) then
            if (not previewType or def.previewType == previewType) then
                table.insert(result, {
                    id = def.id,
                    label = def.label,
                    frameName = def.frameName,
                });
            end
        end
    end
    return result;
end

-- Returns dropdown values/sorting tables for "Anchor to" selects.
function Lantern:GetAnchorDropdownValues(previewType)
    local values = { none = L["UIANCHORS_ANCHOR_NONE"] };
    local sorting = { "none" };
    local anchors = self:GetEnabledAnchors(previewType);
    for _, anchor in ipairs(anchors) do
        values[anchor.id] = anchor.label;
        table.insert(sorting, anchor.id);
    end
    return values, sorting;
end

-------------------------------------------------------------------------------
-- Anchor widget helpers for other modules
-------------------------------------------------------------------------------

-- Attaches a module's frame to an anchor, or restores free positioning.
-- config: { frame, getAnchorId, setAnchorId, getOffsetX, getOffsetY }
function Lantern:ApplyAnchorBinding(config)
    local anchorId = config.getAnchorId();
    local frame = config.frame;
    if (not frame) then return; end

    if (anchorId and anchorId ~= "none") then
        local anchorFrame = self:GetAnchorFrame(anchorId);
        if (anchorFrame) then
            local ox = config.getOffsetX and config.getOffsetX() or 0;
            local oy = config.getOffsetY and config.getOffsetY() or 0;
            frame:ClearAllPoints();
            frame:SetPoint("CENTER", anchorFrame, "CENTER", ox, oy);
            frame:SetMovable(false);
            frame:EnableMouse(false);
            return;
        end

        -- Anchor not available yet (module load order) — defer once
        local anchorMod = self.modules["UIAnchors"];
        if (anchorMod and anchorMod.enabled) then
            C_Timer.After(0, function()
                Lantern:ApplyAnchorBinding(config);
            end);
            return;
        end
        -- Anchor module disabled — fall through to free positioning
    end

    -- No anchor or anchor not available — restore free positioning
    frame:SetMovable(true);
    if (frame.RestorePosition) then
        frame:RestorePosition();
    end
end

-- Returns widget definitions for "Use anchor" toggle + dropdown.
-- Insert these into a module's Position group children.
-- config: { getAnchorId, setAnchorId, frame, previewType, isDisabled }
function Lantern:GetAnchorWidgets(config)
    local uiAnchorsModule = self.modules["UIAnchors"];

    return {
        -- Info text when UIAnchors module is disabled
        {
            type = "callout",
            text = L["UIANCHORS_MODULE_DISABLED_INFO"],
            severity = "info",
            hidden = function()
                return uiAnchorsModule and uiAnchorsModule.enabled;
            end,
        },

        -- "Use anchor" toggle
        {
            type = "toggle",
            label = L["UIANCHORS_USE_ANCHOR"],
            desc = L["UIANCHORS_USE_ANCHOR_DESC"],
            disabled = function()
                return (config.isDisabled and config.isDisabled())
                    or not uiAnchorsModule or not uiAnchorsModule.enabled;
            end,
            get = function()
                local id = config.getAnchorId();
                return id and id ~= "none";
            end,
            set = function(val)
                if (not val) then
                    config.setAnchorId("none");
                else
                    -- Default to first enabled anchor of matching type
                    local anchors = Lantern:GetEnabledAnchors(config.previewType);
                    if (#anchors > 0) then
                        config.setAnchorId(anchors[1].id);
                    end
                end
                Lantern:ApplyAnchorBinding(config);
                Lantern.refreshPage();
            end,
        },

        -- Anchor dropdown (only visible when "Use anchor" is on)
        {
            type = "select",
            label = L["UIANCHORS_SELECT_ANCHOR"],
            desc = L["UIANCHORS_SELECT_ANCHOR_DESC"],
            hidden = function()
                local id = config.getAnchorId();
                return not id or id == "none";
            end,
            disabled = function()
                return (config.isDisabled and config.isDisabled())
                    or not uiAnchorsModule or not uiAnchorsModule.enabled;
            end,
            values = function()
                local v = {};
                local anchors = Lantern:GetEnabledAnchors(config.previewType);
                for _, a in ipairs(anchors) do
                    v[a.id] = a.label;
                end
                return v;
            end,
            sorting = function()
                local s = {};
                local anchors = Lantern:GetEnabledAnchors(config.previewType);
                for _, a in ipairs(anchors) do
                    table.insert(s, a.id);
                end
                return s;
            end,
            get = function()
                return config.getAnchorId();
            end,
            set = function(val)
                config.setAnchorId(val);
                Lantern:ApplyAnchorBinding(config);
            end,
        },

        -- X offset (only visible when anchor is selected)
        {
            type = "range",
            label = L["UIANCHORS_OFFSET_X"],
            desc = L["UIANCHORS_OFFSET_X_DESC"],
            min = -200, max = 200, step = 1, bigStep = 5, default = 0,
            hidden = function()
                local id = config.getAnchorId();
                return not id or id == "none";
            end,
            disabled = function()
                return (config.isDisabled and config.isDisabled())
                    or not uiAnchorsModule or not uiAnchorsModule.enabled;
            end,
            get = function()
                return config.getOffsetX and config.getOffsetX() or 0;
            end,
            set = function(val)
                if (config.setOffsetX) then config.setOffsetX(val); end
                Lantern:ApplyAnchorBinding(config);
            end,
        },

        -- Y offset (only visible when anchor is selected)
        {
            type = "range",
            label = L["UIANCHORS_OFFSET_Y"],
            desc = L["UIANCHORS_OFFSET_Y_DESC"],
            min = -200, max = 200, step = 1, bigStep = 5, default = 0,
            hidden = function()
                local id = config.getAnchorId();
                return not id or id == "none";
            end,
            disabled = function()
                return (config.isDisabled and config.isDisabled())
                    or not uiAnchorsModule or not uiAnchorsModule.enabled;
            end,
            get = function()
                return config.getOffsetY and config.getOffsetY() or 0;
            end,
            set = function(val)
                if (config.setOffsetY) then config.setOffsetY(val); end
                Lantern:ApplyAnchorBinding(config);
            end,
        },

        -- Reset offset
        {
            type = "execute",
            label = L["UIANCHORS_RESET_OFFSET"],
            desc = L["UIANCHORS_RESET_OFFSET_DESC"],
            hidden = function()
                local id = config.getAnchorId();
                return not id or id == "none";
            end,
            disabled = function()
                return (config.isDisabled and config.isDisabled())
                    or not uiAnchorsModule or not uiAnchorsModule.enabled;
            end,
            func = function()
                if (config.setOffsetX) then config.setOffsetX(0); end
                if (config.setOffsetY) then config.setOffsetY(0); end
                Lantern:ApplyAnchorBinding(config);
                Lantern.refreshPage();
            end,
        },
    };
end

-------------------------------------------------------------------------------
-- Lifecycle
-------------------------------------------------------------------------------

function module:OnInit()
    ensureDB();
    for _, def in ipairs(ANCHOR_DEFS) do
        createAnchorFrame(def);
    end
end

function module:OnEnable()
    ensureDB();
    self:ApplyAllVisibility();
    self.addon:ModuleRegisterEvent(self, "DISPLAY_SIZE_CHANGED", self.OnDisplaySizeChanged);
end

function module:OnDisable()
    for _, frame in pairs(self.frames) do
        frame:Hide();
    end
end

function module:OnDisplaySizeChanged()
    self:RepositionAllAnchors();
end

Lantern:RegisterModule(module);
