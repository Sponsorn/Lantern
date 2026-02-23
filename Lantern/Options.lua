local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end
local LanternUX = _G.LanternUX;
if (not LanternUX or not LanternUX.CreatePanel) then return; end

local T = LanternUX.Theme;
if (not T) then return; end

local L = Lantern.L;

-------------------------------------------------------------------------------
-- Create panel
-------------------------------------------------------------------------------

local panel = LanternUX:CreatePanel({
    name    = "LanternSettingsPanel",
    title   = "Lantern",
    icon    = "Interface\\AddOns\\Lantern\\Media\\Images\\Icons\\lantern-core-icon64.blp",
    version = C_AddOns and C_AddOns.GetAddOnMetadata("Lantern", "Version") or "",
});

Lantern._uxPanel = panel;

-------------------------------------------------------------------------------
-- Core module mapping
-------------------------------------------------------------------------------

local CORE_KEY = {
    AutoQuest            = "autoQuest",
    AutoQueue            = "autoQueue",
    AutoRepair           = "autoRepair",
    AutoSell             = "autoSell",
    ChatFilter           = "chatFilter",
    CursorRing           = "cursorRing",
    DeleteConfirm        = "deleteConfirm",
    DisableAutoAddSpells = "disableAutoAddSpells",
    MissingPet           = "missingPet",
    AutoPlaystyle        = "autoPlaystyle",
    FasterLoot           = "fasterLoot",
    DisableLootWarnings  = "disableLootWarnings",
    AutoKeystone         = "autoKeystone",
    ReleaseProtection    = "releaseProtection",
    CombatTimer          = "combatTimer",
    CombatAlert          = "combatAlert",
    RangeCheck           = "rangeCheck",
    Tooltip              = "tooltip",
};

-- Ordered categories: each entry is { key, label, moduleNames }
-- Modules within each category are alphabetical.
local MODULE_CATEGORIES = {
    {
        key   = "general",
        label = L["CATEGORY_GENERAL"],
        modules = {
            "AutoRepair", "AutoSell", "ChatFilter", "CursorRing",
            "DeleteConfirm", "DisableAutoAddSpells", "DisableLootWarnings", "Tooltip",
        },
    },
    {
        key   = "dungeons",
        label = L["CATEGORY_DUNGEONS"],
        modules = {
            "AutoKeystone", "AutoPlaystyle", "AutoQueue",
            "CombatAlert", "CombatTimer", "MissingPet", "RangeCheck", "ReleaseProtection",
        },
    },
    {
        key   = "questing",
        label = L["CATEGORY_QUESTING"],
        modules = {
            "AutoQuest", "FasterLoot",
        },
    },
};

-------------------------------------------------------------------------------
-- Custom option definitions
-------------------------------------------------------------------------------

local function moduleEnabled(name)
    local m = Lantern.modules and Lantern.modules[name];
    return m and m.enabled;
end

local function moduleToggle(name, label, desc)
    return {
        type = "toggle",
        label = label or L["ENABLE"],
        desc = desc,
        get = function() return moduleEnabled(name); end,
        set = function(val)
            if (val) then
                Lantern:EnableModule(name);
            else
                Lantern:DisableModule(name);
            end
        end,
    };
end

local CUSTOM_OPTIONS = {};

CUSTOM_OPTIONS["general"] = function()
    local modifierValues = {
        shift = L["MODIFIER_SHIFT"],
        ctrl  = L["MODIFIER_CTRL"],
        alt   = L["MODIFIER_ALT"],
    };
    local modifierSorting = { "shift", "ctrl", "alt" };

    return {
        {
            type = "toggle",
            label = L["GENERAL_MINIMAP_SHOW"],
            desc = L["GENERAL_MINIMAP_SHOW_DESC"],
            get = function() return not (Lantern.db.minimap and Lantern.db.minimap.hide); end,
            set = function(val) Lantern:ToggleMinimapIcon(val); end,
        },
        {
            type = "toggle",
            label = L["GENERAL_MINIMAP_MODERN"],
            desc = L["GENERAL_MINIMAP_MODERN_DESC"],
            disabled = function() return Lantern.db.minimap and Lantern.db.minimap.hide; end,
            get = function() return Lantern.db.minimap and Lantern.db.minimap.modern or false; end,
            set = function(val)
                Lantern.db.minimap = Lantern.db.minimap or {};
                Lantern.db.minimap.modern = val;
                Lantern:ApplyMinimapStyle();
            end,
        },
        {
            type = "select",
            label = L["GENERAL_PAUSE_MODIFIER"],
            desc = L["GENERAL_PAUSE_MODIFIER_DESC"],
            values = modifierValues,
            sorting = modifierSorting,
            get = function()
                return Lantern.db.options and Lantern.db.options.pauseModifier or "shift";
            end,
            set = function(val)
                Lantern.db.options = Lantern.db.options or {};
                Lantern.db.options.pauseModifier = val;
            end,
        },
    };
end

CUSTOM_OPTIONS["deleteConfirm"] = function()
    return {
        moduleToggle("DeleteConfirm", L["ENABLE"], L["DELETECONFIRM_ENABLE_DESC"]),
    };
end

CUSTOM_OPTIONS["disableAutoAddSpells"] = function()
    return {
        moduleToggle("DisableAutoAddSpells", L["ENABLE"], L["DISABLEAUTOADD_ENABLE_DESC"]),
    };
end

CUSTOM_OPTIONS["autoQueue"] = function()
    local function db()
        Lantern.db.autoQueue = Lantern.db.autoQueue or {};
        local defaults = { active = true, announce = true };
        for k, v in pairs(defaults) do
            if (Lantern.db.autoQueue[k] == nil) then
                Lantern.db.autoQueue[k] = v;
            end
        end
        return Lantern.db.autoQueue;
    end

    local isDisabled = function()
        return not moduleEnabled("AutoQueue");
    end

    return {
        moduleToggle("AutoQueue", L["ENABLE"], L["AUTOQUEUE_ENABLE_DESC"]),
        {
            type = "toggle",
            label = L["AUTOQUEUE_AUTO_ACCEPT"],
            desc = L["AUTOQUEUE_AUTO_ACCEPT_DESC"],
            disabled = isDisabled,
            get = function() return db().active; end,
            set = function(val) db().active = val and true or false; end,
        },
        {
            type = "toggle",
            label = L["AUTOQUEUE_ANNOUNCE"],
            desc = L["AUTOQUEUE_ANNOUNCE_DESC"],
            disabled = isDisabled,
            get = function() return db().announce; end,
            set = function(val) db().announce = val and true or false; end,
        },
        {
            type = "callout",
            text = format(L["AUTOQUEUE_CALLOUT"], Lantern:GetModifierName()),
            severity = "notice",
        },
    };
end

CUSTOM_OPTIONS["fasterLoot"] = function()
    return {
        moduleToggle("FasterLoot", L["ENABLE"], format(L["FASTERLOOT_ENABLE_DESC"], Lantern:GetModifierName())),
    };
end

CUSTOM_OPTIONS["autoKeystone"] = function()
    return {
        moduleToggle("AutoKeystone", L["ENABLE"], format(L["AUTOKEYSTONE_ENABLE_DESC"], Lantern:GetModifierName())),
    };
end

CUSTOM_OPTIONS["releaseProtection"] = function()
    local function db()
        Lantern.db.releaseProtection = Lantern.db.releaseProtection or {};
        return Lantern.db.releaseProtection;
    end

    local isDisabled = function()
        return not moduleEnabled("ReleaseProtection");
    end

    local modeValues = {
        always    = L["RELEASEPROTECT_MODE_ALWAYS"],
        instances = L["RELEASEPROTECT_MODE_INSTANCES"],
        custom    = L["RELEASEPROTECT_MODE_CUSTOM"],
    };
    local modeSorting = { "always", "instances", "custom" };

    local isCustomDisabled = function()
        return isDisabled() or db().mode ~= "custom";
    end

    return {
        moduleToggle("ReleaseProtection", L["ENABLE"], format(L["RELEASEPROTECT_ENABLE_DESC"], Lantern:GetModifierName())),
        {
            type = "toggle",
            label = L["RELEASEPROTECT_SKIP_SOLO"],
            desc = L["RELEASEPROTECT_SKIP_SOLO_DESC"],
            disabled = isDisabled,
            get = function() return db().skipSolo; end,
            set = function(val) db().skipSolo = val; end,
        },
        {
            type = "select",
            label = L["RELEASEPROTECT_ACTIVE_IN"],
            desc = L["RELEASEPROTECT_ACTIVE_IN_DESC"],
            values = modeValues,
            sorting = modeSorting,
            disabled = isDisabled,
            get = function() return db().mode or "always"; end,
            set = function(val)
                db().mode = val;
                if (Lantern._uxPanel and Lantern._uxPanel.RefreshCurrentPage) then
                    Lantern._uxPanel:RefreshCurrentPage();
                end
            end,
        },
        {
            type = "range",
            label = L["RELEASEPROTECT_HOLD_DURATION"],
            desc = L["RELEASEPROTECT_HOLD_DURATION_DESC"],
            min = 0.5,
            max = 5,
            step = 0.5,
            disabled = isDisabled,
            get = function() return db().holdDuration or 1.0; end,
            set = function(val) db().holdDuration = val; end,
            format = "%.1fs",
        },
        {
            type = "group",
            text = L["RELEASEPROTECT_INSTANCE_TYPES"],
            expanded = true,
            stateKey = "releaseProtectionTypes",
            hidden = function() return db().mode ~= "custom"; end,
            children = {
                {
                    type = "toggle",
                    label = L["RELEASEPROTECT_OPEN_WORLD"],
                    desc = L["RELEASEPROTECT_OPEN_WORLD_DESC"],
                    disabled = isCustomDisabled,
                    get = function() return db().openWorld ~= false; end,
                    set = function(val) db().openWorld = val; end,
                },
                {
                    type = "toggle",
                    label = L["RELEASEPROTECT_DUNGEONS"],
                    desc = L["RELEASEPROTECT_DUNGEONS_DESC"],
                    disabled = isCustomDisabled,
                    get = function() return db().dungeons ~= false; end,
                    set = function(val) db().dungeons = val; end,
                },
                {
                    type = "toggle",
                    label = L["RELEASEPROTECT_MYTHICPLUS"],
                    desc = L["RELEASEPROTECT_MYTHICPLUS_DESC"],
                    disabled = isCustomDisabled,
                    get = function() return db().mythicPlus ~= false; end,
                    set = function(val) db().mythicPlus = val; end,
                },
                {
                    type = "toggle",
                    label = L["RELEASEPROTECT_RAIDS"],
                    desc = L["RELEASEPROTECT_RAIDS_DESC"],
                    disabled = isCustomDisabled,
                    get = function() return db().raids ~= false; end,
                    set = function(val) db().raids = val; end,
                },
                {
                    type = "toggle",
                    label = L["RELEASEPROTECT_SCENARIOS"],
                    desc = L["RELEASEPROTECT_SCENARIOS_DESC"],
                    disabled = isCustomDisabled,
                    get = function() return db().scenarios ~= false; end,
                    set = function(val) db().scenarios = val; end,
                },
                {
                    type = "toggle",
                    label = L["RELEASEPROTECT_DELVES"],
                    desc = L["RELEASEPROTECT_DELVES_DESC"],
                    disabled = isCustomDisabled,
                    get = function() return db().delves ~= false; end,
                    set = function(val) db().delves = val; end,
                },
                {
                    type = "toggle",
                    label = L["RELEASEPROTECT_ARENAS"],
                    desc = L["RELEASEPROTECT_ARENAS_DESC"],
                    disabled = isCustomDisabled,
                    get = function() return db().arenas ~= false; end,
                    set = function(val) db().arenas = val; end,
                },
                {
                    type = "toggle",
                    label = L["RELEASEPROTECT_BATTLEGROUNDS"],
                    desc = L["RELEASEPROTECT_BATTLEGROUNDS_DESC"],
                    disabled = isCustomDisabled,
                    get = function() return db().battlegrounds ~= false; end,
                    set = function(val) db().battlegrounds = val; end,
                },
            },
        },
    };
end

-------------------------------------------------------------------------------
-- AutoRepair custom options
-------------------------------------------------------------------------------

CUSTOM_OPTIONS["autoRepair"] = function()
    local function db()
        Lantern.db.autoRepair = Lantern.db.autoRepair or {};
        local defaults = { source = "personal" };
        for k, v in pairs(defaults) do
            if (Lantern.db.autoRepair[k] == nil) then
                Lantern.db.autoRepair[k] = v;
            end
        end
        return Lantern.db.autoRepair;
    end

    local isDisabled = function()
        return not moduleEnabled("AutoRepair");
    end

    local sourceValues = {
        personal    = L["AUTOREPAIR_SOURCE_PERSONAL"],
        guild_first = L["AUTOREPAIR_SOURCE_GUILD_FIRST"],
        guild_only  = L["AUTOREPAIR_SOURCE_GUILD_ONLY"],
    };
    local sourceSorting = { "personal", "guild_first", "guild_only" };

    return {
        moduleToggle("AutoRepair", L["ENABLE"], L["AUTOREPAIR_ENABLE_DESC"]),
        {
            type = "select",
            label = L["AUTOREPAIR_SOURCE"],
            desc = L["AUTOREPAIR_SOURCE_DESC"],
            values = sourceValues,
            sorting = sourceSorting,
            disabled = isDisabled,
            get = function() return db().source; end,
            set = function(val) db().source = val; end,
        },
        {
            type = "callout",
            text = format(L["AUTOREPAIR_CALLOUT"], Lantern:GetModifierName()),
            severity = "notice",
        },
    };
end

-------------------------------------------------------------------------------
-- Splash / Home content
-------------------------------------------------------------------------------

local linkPopup;

local function showLinkPopup(link)
    if (not linkPopup) then
        local POPUP_W, POPUP_H = 340, 110;
        local panelFrame = panel._frame;

        local overlay = CreateFrame("Frame", "LanternUX_LinkOverlay", panelFrame);
        overlay:SetAllPoints();
        overlay:SetFrameLevel(panelFrame:GetFrameLevel() + 50);
        overlay:EnableMouse(true);
        overlay:SetScript("OnMouseDown", function() overlay:Hide(); end);

        local bg = overlay:CreateTexture(nil, "BACKGROUND");
        bg:SetAllPoints();
        bg:SetColorTexture(0, 0, 0, 0.5);

        local popup = CreateFrame("Frame", "LanternUX_LinkPopup", overlay, "BackdropTemplate");
        popup:SetSize(POPUP_W, POPUP_H);
        popup:SetPoint("CENTER", panelFrame, "CENTER", 0, 40);
        popup:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        });
        popup:SetBackdropColor(unpack(T.bg));
        popup:SetBackdropBorderColor(unpack(T.border));
        popup:EnableMouse(true);

        -- Title
        local title = popup:CreateFontString(nil, "ARTWORK", T.fontBody);
        title:SetPoint("TOPLEFT", popup, "TOPLEFT", 14, -14);
        title:SetText(L["SPLASH_COPY_LINK"]);
        title:SetTextColor(unpack(T.textBright));

        -- Close button (X)
        local closeBtn = CreateFrame("Button", "LanternUX_LinkCloseBtn", popup);
        closeBtn:SetSize(20, 20);
        closeBtn:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -8, -8);
        local closeTxt = closeBtn:CreateFontString(nil, "ARTWORK", T.fontBody);
        closeTxt:SetPoint("CENTER");
        closeTxt:SetText("x");
        closeTxt:SetTextColor(unpack(T.text));
        closeBtn:SetScript("OnEnter", function() closeTxt:SetTextColor(unpack(T.textBright)); end);
        closeBtn:SetScript("OnLeave", function() closeTxt:SetTextColor(unpack(T.text)); end);
        closeBtn:SetScript("OnClick", function() overlay:Hide(); end);

        -- Edit box
        local editBox = CreateFrame("EditBox", "LanternUX_LinkEditBox", popup, "BackdropTemplate");
        editBox:SetSize(POPUP_W - 28, 26);
        editBox:SetPoint("TOPLEFT", popup, "TOPLEFT", 14, -40);
        editBox:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        });
        editBox:SetBackdropColor(unpack(T.inputBg));
        editBox:SetBackdropBorderColor(unpack(T.inputBorder));
        editBox:SetFontObject(T.fontSmall);
        editBox:SetTextColor(unpack(T.text));
        editBox:SetTextInsets(6, 6, 0, 0);
        editBox:SetAutoFocus(false);
        editBox:SetMaxLetters(0);

        editBox:SetScript("OnEscapePressed", function() overlay:Hide(); end);
        editBox:SetScript("OnEnterPressed", function() overlay:Hide(); end);
        editBox:SetScript("OnKeyUp", function(_, key)
            if (IsControlKeyDown() and (key == "C" or key == "X")) then
                overlay:Hide();
            end
        end);

        -- Hint text
        local hint = popup:CreateFontString(nil, "ARTWORK", T.fontSmall);
        hint:SetPoint("TOPLEFT", editBox, "BOTTOMLEFT", 2, -8);
        hint:SetText(L["SPLASH_COPY_HINT"]);
        hint:SetTextColor(unpack(T.textDim));

        overlay._editBox = editBox;
        linkPopup = overlay;
    end

    linkPopup._editBox:SetText(link or "");
    linkPopup:Show();
    linkPopup._editBox:SetFocus();
    linkPopup._editBox:HighlightText();
end

local COMPANION_ADDONS = {
    {
        addonName = "Lantern_CraftingOrders",
        label     = L["COMPANION_CO_LABEL"],
        desc      = L["COMPANION_CO_DESC"],
        url       = "https://www.curseforge.com/wow/addons/lantern-craftingorders",
    },
    {
        addonName = "Lantern_Warband",
        label     = L["COMPANION_WARBAND_LABEL"],
        desc      = L["COMPANION_WARBAND_DESC"],
        url       = "https://www.curseforge.com/wow/addons/lantern-warband",
    },
};

local COMPANION_COL_WIDTH = 255;
local COMPANION_COL_GAP   = 24;

local splashFrame;
local splashToggles = {};

local function PopulateSplashModules()
    if (not splashFrame) then return; end

    local y = splashFrame._contentStartY;

    -- Hide all previously-shown cached elements
    for _, elem in pairs(splashToggles) do
        if (elem.Hide) then elem:Hide(); end
    end

    for catIdx, category in ipairs(MODULE_CATEGORIES) do
        -- Category header
        local headerKey = catIdx .. "_header";
        local header = splashToggles[headerKey];
        if (not header) then
            header = splashFrame:CreateFontString(nil, "ARTWORK", T.fontBody);
            splashToggles[headerKey] = header;
        end
        header:ClearAllPoints();
        header:SetPoint("TOPLEFT", splashFrame, "TOPLEFT", 28, y);
        header:SetText(category.label);
        header:SetTextColor(unpack(T.textBright));
        header:Show();

        -- Category divider
        local divKey = catIdx .. "_divider";
        local div = splashToggles[divKey];
        if (not div) then
            div = splashFrame:CreateTexture(nil, "ARTWORK");
            div:SetHeight(1);
            splashToggles[divKey] = div;
        end
        div:ClearAllPoints();
        div:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -6);
        div:SetPoint("RIGHT", splashFrame, "RIGHT", -28, 0);
        div:SetColorTexture(unpack(T.divider));
        div:Show();

        y = y - 26;

        -- Modules in this category (2-column layout)
        local col = 0;
        local COL_OFFSET = 254;  -- x offset for second column

        for _, moduleName in ipairs(category.modules) do
            local mod = Lantern.modules[moduleName];
            if (mod) then
                local displayName = (mod.opts and mod.opts.title) or moduleName;
                local pageKey = CORE_KEY[moduleName];
                local xBase = 36 + col * COL_OFFSET;

                -- Status dot
                local dotKey = catIdx .. "_" .. moduleName .. "_dot";
                local dot = splashToggles[dotKey];
                if (not dot) then
                    dot = splashFrame:CreateTexture(nil, "ARTWORK");
                    dot:SetSize(8, 8);
                    dot:SetTexture("Interface\\Buttons\\WHITE8x8");
                    splashToggles[dotKey] = dot;
                end
                dot:ClearAllPoints();
                dot:SetPoint("TOPLEFT", splashFrame, "TOPLEFT", xBase, y - 2);
                if (mod.enabled) then
                    dot:SetColorTexture(unpack(T.enabled));
                else
                    dot:SetColorTexture(unpack(T.disabledDot));
                end
                dot:Show();

                -- Clickable module label (Button frame for click support)
                local labelKey = catIdx .. "_" .. moduleName .. "_label";
                local btn = splashToggles[labelKey];
                if (not btn) then
                    btn = CreateFrame("Button", "LanternSplash_ModuleBtn_" .. moduleName, splashFrame);
                    local btnText = btn:CreateFontString(nil, "ARTWORK", T.fontBody);
                    btnText:SetPoint("LEFT");
                    btnText:SetJustifyH("LEFT");
                    btn._text = btnText;
                    splashToggles[labelKey] = btn;

                    btn:SetScript("OnEnter", function(self)
                        self._text:SetTextColor(unpack(T.accent));
                    end);
                    btn:SetScript("OnLeave", function(self)
                        self._text:SetTextColor(unpack(T.text));
                    end);
                end

                btn._text:SetText(displayName);
                btn._text:SetTextColor(unpack(T.text));

                -- Update click handler each time (pageKey is stable but closure is cheap)
                btn:SetScript("OnClick", function()
                    if (pageKey) then
                        panel:SelectPage(pageKey);
                    end
                end);

                btn:ClearAllPoints();
                btn:SetPoint("TOPLEFT", splashFrame, "TOPLEFT", xBase + 14, y);
                -- Size the button to fit the text
                local textWidth = btn._text:GetStringWidth() or 100;
                btn:SetSize(textWidth + 4, 16);
                btn:Show();

                col = col + 1;
                if (col >= 2) then
                    col = 0;
                    y = y - 22;
                end
            end
        end

        -- Advance y after a partial (odd-count) row
        if (col > 0) then
            y = y - 22;
        end

        -- Spacing between categories
        y = y - 10;
    end

    -- Companion addons section (show addons that are not loaded)
    -- "not loaded" = not installed OR installed but disabled
    local hasAnyCompanion = false;
    for _, info in ipairs(COMPANION_ADDONS) do
        local loaded = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded(info.addonName);
        if (not loaded) then
            hasAnyCompanion = true;
            break;
        end
    end

    if (hasAnyCompanion and splashFrame._companionHeader) then
        -- Position header below categorized module list
        y = y - 12;
        splashFrame._companionHeader:ClearAllPoints();
        splashFrame._companionHeader:SetPoint("TOPLEFT", splashFrame, "TOPLEFT", 28, y);
        splashFrame._companionHeader:Show();

        splashFrame._companionDivider:ClearAllPoints();
        splashFrame._companionDivider:SetPoint("TOPLEFT", splashFrame._companionHeader, "BOTTOMLEFT", 0, -6);
        splashFrame._companionDivider:SetPoint("RIGHT", splashFrame, "RIGHT", -28, 0);
        splashFrame._companionDivider:Show();

        y = y - 30;

        -- Position companion rows in a 2-column grid
        local col = 0;       -- 0 = left, 1 = right
        local rowMaxH = 0;   -- tallest cell in current row pair

        for idx, info in ipairs(COMPANION_ADDONS) do
            local loaded = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded(info.addonName);
            local cell = splashFrame._companionRows[idx];
            if (cell) then
                if (loaded) then
                    cell.frame:Hide();
                else
                    -- Determine if installed but disabled vs not installed
                    local installed = C_AddOns and C_AddOns.GetAddOnInfo and C_AddOns.GetAddOnInfo(info.addonName) ~= nil;

                    if (installed) then
                        -- Installed but disabled — show muted button
                        cell.btnText:SetText(L["SPLASH_DISABLED"]);
                        cell.btnText:SetTextColor(unpack(T.disabledText));
                        cell.btn:SetBackdropColor(unpack(T.disabledBg));
                        cell.btn:SetBackdropBorderColor(unpack(T.disabled));
                        cell.btn:SetScript("OnEnter", nil);
                        cell.btn:SetScript("OnLeave", nil);
                        cell.btn:SetScript("OnClick", nil);
                    else
                        -- Not installed — show CurseForge link
                        cell.btnText:SetText(L["SPLASH_CURSEFORGE"]);
                        cell.btnText:SetTextColor(unpack(T.buttonText));
                        cell.btn:SetBackdropColor(unpack(T.buttonBg));
                        cell.btn:SetBackdropBorderColor(unpack(T.buttonBorder));
                        cell.btn:SetScript("OnEnter", function(self)
                            self:SetBackdropColor(unpack(T.buttonHover));
                            self:SetBackdropBorderColor(unpack(T.inputFocus));
                        end);
                        cell.btn:SetScript("OnLeave", function(self)
                            self:SetBackdropColor(unpack(T.buttonBg));
                            self:SetBackdropBorderColor(unpack(T.buttonBorder));
                        end);
                        cell.btn:SetScript("OnClick", function()
                            showLinkPopup(cell.url);
                        end);
                    end

                    local xOffset = 32 + col * (COMPANION_COL_WIDTH + COMPANION_COL_GAP);
                    cell.frame:ClearAllPoints();
                    cell.frame:SetPoint("TOPLEFT", splashFrame, "TOPLEFT", xOffset, y);
                    cell.frame:Show();

                    if (cell.height > rowMaxH) then rowMaxH = cell.height; end

                    col = col + 1;
                    if (col >= 2) then
                        y = y - rowMaxH - 12;
                        col = 0;
                        rowMaxH = 0;
                    end
                end
            end
        end

        -- Advance y after a partial (odd-count) row
        if (col > 0) then
            y = y - rowMaxH - 12;
        end
    elseif (splashFrame._companionHeader) then
        splashFrame._companionHeader:Hide();
        splashFrame._companionDivider:Hide();
        for _, row in ipairs(splashFrame._companionRows) do
            row.frame:Hide();
        end
    end

    -- Update scroll content height so overflow is scrollable
    if (splashFrame._scroll) then
        splashFrame._scroll:UpdateContentHeight(math.abs(y) + 20);
    end
end

local function CreateSplashContent(parent)
    local scroll = LanternUX.CreateScrollContainer(parent);
    local f = scroll.scrollChild;

    scroll.scrollFrame:SetScript("OnSizeChanged", function(_, w)
        f:SetWidth(w);
    end);

    local y = -28;

    -- Icon
    local icon = f:CreateTexture(nil, "ARTWORK");
    icon:SetSize(48, 48);
    icon:SetPoint("TOPLEFT", f, "TOPLEFT", 28, y);
    icon:SetTexture("Interface\\AddOns\\Lantern\\Media\\Images\\Icons\\lantern-core-icon128.blp");

    -- Title
    local title = f:CreateFontString(nil, "ARTWORK", T.fontHeading);
    title:SetPoint("LEFT", icon, "RIGHT", 12, 6);
    title:SetText("Lantern");
    title:SetTextColor(unpack(T.textBright));

    -- Version
    local ver = "";
    if (C_AddOns and C_AddOns.GetAddOnMetadata) then
        ver = C_AddOns.GetAddOnMetadata("Lantern", "Version") or "";
    end
    local verText = f:CreateFontString(nil, "ARTWORK", T.fontSmall);
    verText:SetPoint("LEFT", title, "RIGHT", 8, 0);
    verText:SetText("v" .. ver);
    verText:SetTextColor(unpack(T.textDim));

    -- Description
    local desc = f:CreateFontString(nil, "ARTWORK", T.fontBody);
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10);
    desc:SetWidth(540);
    desc:SetJustifyH("LEFT");
    desc:SetWordWrap(true);
    desc:SetText(L["SPLASH_DESC"]);
    desc:SetTextColor(unpack(T.splashText));

    -- Status legend
    local legendY = -118;
    local legendX = 36;

    local enabledDot = f:CreateTexture(nil, "ARTWORK");
    enabledDot:SetSize(6, 6);
    enabledDot:SetPoint("TOPLEFT", f, "TOPLEFT", legendX, legendY - 1);
    enabledDot:SetColorTexture(unpack(T.enabled));

    local enabledLabel = f:CreateFontString(nil, "ARTWORK", T.fontSmall);
    enabledLabel:SetPoint("LEFT", enabledDot, "RIGHT", 5, 0);
    enabledLabel:SetText(L["SPLASH_ENABLED"]);
    enabledLabel:SetTextColor(unpack(T.textDim));

    local disabledDot = f:CreateTexture(nil, "ARTWORK");
    disabledDot:SetSize(6, 6);
    disabledDot:SetPoint("LEFT", enabledLabel, "RIGHT", 12, 0);
    disabledDot:SetColorTexture(unpack(T.disabledDot));

    local disabledLabel = f:CreateFontString(nil, "ARTWORK", T.fontSmall);
    disabledLabel:SetPoint("LEFT", disabledDot, "RIGHT", 5, 0);
    disabledLabel:SetText(L["SPLASH_DISABLED"]);
    disabledLabel:SetTextColor(unpack(T.textDim));

    -- Content starts below description + legend; categories are positioned dynamically
    f._contentStartY = -140;
    f._catHeaders = {};
    f._catDividers = {};

    -- Companion addons section (created below modules, positioned dynamically by PopulateSplashModules)
    -- We create the elements here but position them in PopulateSplashModules since
    -- the Y offset depends on how many modules are listed above.
    local companionHeader = f:CreateFontString(nil, "ARTWORK", T.fontBody);
    companionHeader:SetText(L["SPLASH_COMPANION_HEADER"]);
    companionHeader:SetTextColor(unpack(T.textBright));
    companionHeader:Hide();
    f._companionHeader = companionHeader;

    local companionDivider = f:CreateTexture(nil, "ARTWORK");
    companionDivider:SetHeight(1);
    companionDivider:SetColorTexture(unpack(T.divider));
    companionDivider:Hide();
    f._companionDivider = companionDivider;

    f._companionRows = {};

    for i, info in ipairs(COMPANION_ADDONS) do
        local row = CreateFrame("Frame", "LanternUX_CompanionRow_" .. i, f);
        row:SetWidth(COMPANION_COL_WIDTH);

        -- Description text
        local rowDesc = row:CreateFontString(nil, "ARTWORK", T.fontBody);
        rowDesc:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0);
        rowDesc:SetWidth(COMPANION_COL_WIDTH);
        rowDesc:SetJustifyH("LEFT");
        rowDesc:SetWordWrap(true);
        rowDesc:SetText(info.label .. ": " .. info.desc);
        rowDesc:SetTextColor(unpack(T.splashText));

        -- CurseForge button
        local btn = CreateFrame("Button", "LanternUX_CompanionBtn_" .. i, row, "BackdropTemplate");
        btn:SetSize(100, 22);
        btn:SetPoint("TOPLEFT", rowDesc, "BOTTOMLEFT", 0, -6);
        btn:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        });
        btn:SetBackdropColor(unpack(T.buttonBg));
        btn:SetBackdropBorderColor(unpack(T.buttonBorder));

        local btnText = btn:CreateFontString(nil, "ARTWORK", T.fontSmall);
        btnText:SetPoint("CENTER");
        btnText:SetText(L["SPLASH_CURSEFORGE"]);
        btnText:SetTextColor(unpack(T.buttonText));

        btn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(unpack(T.buttonHover));
            self:SetBackdropBorderColor(unpack(T.inputFocus));
        end);
        btn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(unpack(T.buttonBg));
            self:SetBackdropBorderColor(unpack(T.buttonBorder));
        end);
        btn:SetScript("OnClick", function()
            showLinkPopup(info.url);
        end);

        local textHeight = math.max(14, rowDesc:GetStringHeight() or 0);
        local totalHeight = textHeight + 6 + 22;
        row:SetHeight(totalHeight);

        f._companionRows[i] = { frame = row, height = totalHeight, btn = btn, btnText = btnText, url = info.url };
    end

    f._scroll = scroll;
    splashFrame = f;
    return scroll.scrollFrame;
end

-------------------------------------------------------------------------------
-- Register pages on PLAYER_LOGIN (all addons loaded by then)
-------------------------------------------------------------------------------

local loginFrame = CreateFrame("Frame", "LanternUX_LoginFrame");
loginFrame:RegisterEvent("PLAYER_LOGIN");
loginFrame:SetScript("OnEvent", function()
    -- Home (splash page with module status)
    panel:AddPage("home", {
        label = L["PAGE_HOME"],
        frame = CreateSplashContent,
        onShow = PopulateSplashModules,
    });

    -- General settings page (addon-level settings, not a module)
    panel:AddPage("general_settings", {
        label   = L["SECTION_GENERAL"],
        title   = L["SECTION_GENERAL"],
        description = L["SECTION_GENERAL_DESC"],
        widgets = CUSTOM_OPTIONS["general"],
    });

    -- Category-based module pages
    panel:AddSection("modules", L["SECTION_MODULES"]);
    for _, category in ipairs(MODULE_CATEGORIES) do
        panel:AddSidebarGroup(category.key, {
            label   = category.label,
            section = "modules",
        });
        for _, moduleName in ipairs(category.modules) do
            local mod = Lantern.modules[moduleName];
            if (mod) then
                local key = CORE_KEY[moduleName];
                local optionsFn = mod.widgetOptions or CUSTOM_OPTIONS[key];
                panel:AddPage(key, {
                    label        = (mod.opts and mod.opts.title) or moduleName,
                    section      = "modules",
                    sidebarGroup = category.key,
                    title        = (mod.opts and mod.opts.title) or moduleName,
                    description  = mod.opts and mod.opts.desc,
                    widgets      = optionsFn or nil,
                });
            end
        end
    end

    -- External modules (Warband, CraftingOrders, etc.)
    local external = {};
    for name, mod in pairs(Lantern.modules or {}) do
        if (not CORE_KEY[name] and not (mod.opts and mod.opts.skipOptions)) then
            table.insert(external, name);
        end
    end
    table.sort(external);

    if (#external > 0) then
        panel:AddSection("addons", L["SECTION_ADDONS"]);
        for _, moduleName in ipairs(external) do
            local mod = Lantern.modules[moduleName];
            if (mod.uxPages) then
                local groupKey = "addon_" .. moduleName:lower();
                panel:AddSidebarGroup(groupKey, {
                    label   = (mod.opts and mod.opts.title) or moduleName,
                    section = "addons",
                });
                for _, pageInfo in ipairs(mod.uxPages) do
                    pageInfo.opts.section = "addons";
                    pageInfo.opts.sidebarGroup = groupKey;
                    panel:AddPage(pageInfo.key, pageInfo.opts);
                end
            else
                panel:AddPage("module_" .. moduleName, {
                    label     = (mod.opts and mod.opts.title) or moduleName,
                    section   = "addons",
                });
            end
        end
    end
end);

-------------------------------------------------------------------------------
-- Override Lantern:OpenOptions()
-------------------------------------------------------------------------------

function Lantern:OpenOptions()
    -- SetupOptions touches protected Blizzard UI; defer if in combat and not initialized.
    if (not self.optionsInitialized and InCombatLockdown()) then
        self._pendingSettingsPanel = true;
        Lantern:Print(L["MSG_OPTIONS_AFTER_COMBAT"]);
        return;
    end

    if (not self.optionsInitialized) then
        self:SetupOptions();
    end

    self._pendingSettingsPanel = false;
    panel:Toggle();
end

-------------------------------------------------------------------------------
-- Handle deferred open after combat ends
-------------------------------------------------------------------------------

local combatFrame = CreateFrame("Frame", "LanternUX_CombatFrame");
combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
combatFrame:SetScript("OnEvent", function()
    if (Lantern._pendingSettingsPanel) then
        Lantern._pendingSettingsPanel = false;
        C_Timer.After(0.1, function()
            Lantern:OpenOptions();
        end);
    end
end);
