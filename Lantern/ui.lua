local ADDON_NAME, Lantern = ...;

local LDB = LibStub and LibStub("LibDataBroker-1.1", true);
local LDBIcon = LibStub and LibStub("LibDBIcon-1.0", true);
local AceConfig = LibStub and LibStub("AceConfig-3.0", true);
local AceConfigDialog = LibStub and LibStub("AceConfigDialog-3.0", true);
local AceConfigRegistry = LibStub and LibStub("AceConfigRegistry-3.0", true);

local MINIMAP_OBJECT_NAME = "Lantern";
local DEFAULT_ICON = "Interface\\AddOns\\Lantern\\Media\\Images\\Icons\\lantern-core-icon64.blp";
local CURSEFORGE_CRAFTING_ORDERS = "https://www.curseforge.com/wow/addons/lantern-craftingorders";
local CURSEFORGE_WARBAND = "https://www.curseforge.com/wow/addons/lantern-warband";
local LINK_POPUP_NAME = "LanternCopyLinkDialog";

local function hasMinimapLibs()
    return LDB and LDBIcon;
end

local function hasOptionsLibs()
    return AceConfig and AceConfigDialog;
end

-------------------------------------------------------------------------------
-- Combat Lockdown Handling for Options
-------------------------------------------------------------------------------

local pendingOpenOptions = false;

local combatFrame = CreateFrame("Frame");
combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
combatFrame:SetScript("OnEvent", function(self, event)
    if (event == "PLAYER_REGEN_ENABLED" and pendingOpenOptions) then
        pendingOpenOptions = false;
        -- Small delay to ensure UI is ready after combat
        C_Timer.After(0.1, function()
            Lantern:OpenOptions();
        end);
    end
end);

local function ensureLinkPopup()
    if (StaticPopupDialogs[LINK_POPUP_NAME]) then return; end
    StaticPopupDialogs[LINK_POPUP_NAME] = {
        text = "CTRL-C to copy link",
        button1 = CLOSE,
        OnShow = function(dialog, data)
            local function hidePopup()
                dialog:Hide();
            end
            local editBox = dialog.GetEditBox and dialog:GetEditBox() or dialog.editBox;
            editBox:SetScript("OnEscapePressed", hidePopup);
            editBox:SetScript("OnEnterPressed", hidePopup);
            editBox:SetScript("OnKeyUp", function(_, key)
                if (IsControlKeyDown() and (key == "C" or key == "X")) then
                    hidePopup();
                end
            end);
            editBox:SetMaxLetters(0);
            editBox:SetText(data or "");
            editBox:HighlightText();
        end,
        hasEditBox = true,
        editBoxWidth = 260,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    };
end

local function showLinkPopup(link)
    ensureLinkPopup();
    StaticPopup_Show(LINK_POPUP_NAME, nil, nil, link);
end

function Lantern:NotifyOptionsChange()
    local panel = self.optionsPanel;
    local optionsVisible = false;
    if (panel and panel.IsShown and panel:IsShown()) then
        optionsVisible = true;
    elseif (SettingsPanel and SettingsPanel.IsShown and SettingsPanel:IsShown()) then
        optionsVisible = true;
    elseif (InterfaceOptionsFrame and InterfaceOptionsFrame.IsShown and InterfaceOptionsFrame:IsShown()) then
        optionsVisible = true;
    end
    if (not optionsVisible) then
        return;
    end
    if (AceConfigRegistry) then
        AceConfigRegistry:NotifyChange(ADDON_NAME .. "_General");
    end
end

function Lantern:EnsureUIState()
    self.db.minimap = self.db.minimap or {};
    self.db.options = self.db.options or {};
end

function Lantern:ToggleMinimapIcon(show)
    if (not hasMinimapLibs()) then return; end
    if (show == nil) then
        show = self.db.minimap.hide;
        show = not show;
    end
    self.db.minimap.hide = not show;
    if (show) then
        LDBIcon:Show(MINIMAP_OBJECT_NAME);
    else
        LDBIcon:Hide(MINIMAP_OBJECT_NAME);
    end
end

function Lantern:InitMinimap()
    if (self.minimapInitialized or not hasMinimapLibs()) then return; end

    self.ldbObject = self.ldbObject or LDB:NewDataObject(MINIMAP_OBJECT_NAME, {
        type = "launcher",
        icon = DEFAULT_ICON,
        label = ADDON_NAME,
        OnClick = function(_, button)
            if (button == "LeftButton") then
                if (IsShiftKeyDown()) then
                    ReloadUI();
                else
                    Lantern:OpenOptions();
                end
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("Lantern");
            tooltip:AddLine("Left-click: Open options", 1, 1, 1);
            tooltip:AddLine("Shift+Left-click: Reload UI", 1, 1, 1);
        end,
    });

    LDBIcon:Register(MINIMAP_OBJECT_NAME, self.ldbObject, self.db.minimap);
    LDBIcon:AddButtonToCompartment(MINIMAP_OBJECT_NAME);
    self.minimapInitialized = true;
end

local function makeModuleOptionKey(name)
    return "module_" .. tostring(name or "");
end

local function moduleToggle(name)
    return function(_, val)
        if (val) then
            Lantern:EnableModule(name);
        else
            Lantern:DisableModule(name);
        end
    end
end

local function moduleToggleGetter(name)
    return function()
        local module = Lantern.modules[name];
        return module and module.enabled;
    end
end

function Lantern:RegisterModuleOptions(module)
    if (not module or not module.name or not self.options) then return; end
    if (module.opts and module.opts.skipOptions) then return; end
    local key = makeModuleOptionKey(module.name);
    if (self._registeredOptionKeys and self._registeredOptionKeys[key]) then return; end
    self._registeredOptionKeys = self._registeredOptionKeys or {};

    local label = (module.opts and module.opts.title) or module.name;
    local desc = module.opts and module.opts.desc;

    local childGroups = (module.opts and module.opts.childGroups) or "tree";
    local group = {
        type = "group",
        name = label,
        childGroups = childGroups,
        args = {
            enabled = nil,
        },
    };
    local enableLabel = (module.opts and module.opts.enableLabel) or "Enable";
    group.args.enabled = {
        order = 0,
        type = "toggle",
        name = enableLabel,
        desc = desc,
        width = "full",
        get = moduleToggleGetter(module.name),
        set = moduleToggle(module.name),
    };
    -- Allow modules to contribute additional options.
    local extraArgs;
    if (module.GetOptions) then
        extraArgs = module:GetOptions();
    elseif (module.opts and module.opts.options) then
        extraArgs = module.opts.options;
    end
    if (type(extraArgs) == "table") then
            for k, v in pairs(extraArgs) do
                group.args[k] = v;
            end
        end

        if (AceConfig and AceConfigDialog) then
            AceConfig:RegisterOptionsTable(key, group);
            AceConfigDialog:AddToBlizOptions(key, label, ADDON_NAME);
            self._registeredOptionKeys[key] = true;
        end
    end

function Lantern:RegisterAllModuleOptions()
    if (not self.options) then return; end
    for name, module in pairs(self.modules or {}) do
        self:RegisterModuleOptions(module);
    end
end

-- Hook module registration so options stay in sync.
if (not Lantern._originalRegisterModuleForUI) then
    Lantern._originalRegisterModuleForUI = Lantern.RegisterModule;
    function Lantern:RegisterModule(module)
        Lantern._originalRegisterModuleForUI(self, module);
        if (self.optionsInitialized) then
            self:RegisterModuleOptions(module);
        end
    end
end

function Lantern:BuildOptions()
    if (self.options) then return self.options; end

    self.options = {
        type = "group",
        name = "General Options",
        args = {
            general = {
                type = "group",
                name = "General",
                inline = true,
                args = {
                    minimap = {
                        type = "toggle",
                        name = "Show minimap icon",
                        get = function() return not (Lantern.db.minimap and Lantern.db.minimap.hide); end,
                        set = function(_, val) Lantern:ToggleMinimapIcon(val); end,
                        width = "full",
                    },
                },
            },
            autoQuest = {
                type = "group",
                name = "Auto Quest",
                args = self.BuildAutoQuestOptions and self:BuildAutoQuestOptions() or {},
            },
            autoQueue = {
                type = "group",
                name = "Auto Queue",
                args = self.BuildAutoQueueOptions and self:BuildAutoQueueOptions() or {},
            },
            deleteConfirm = {
                type = "group",
                name = "Delete Confirm",
                args = self.BuildDeleteConfirmOptions and self:BuildDeleteConfirmOptions() or {},
            },
            disableAutoAddSpells = {
                type = "group",
                name = "Disable Auto Add Spells",
                args = self.BuildDisableAutoAddSpellsOptions and self:BuildDisableAutoAddSpellsOptions() or {},
            },
            missingPet = {
                type = "group",
                name = "Missing Pet",
                args = self.BuildMissingPetOptions and self:BuildMissingPetOptions() or {},
            },
            cleanQuests = {
                type = "group",
                name = "Clean Tracked Quests",
                args = self.BuildCleanQuestsOptions and self:BuildCleanQuestsOptions() or {},
            },
            -- Module placeholders added at runtime via RegisterModuleOptions.
        },
    };
    return self.options;
end

local function decorateSplash(panel)
    if (not panel or panel._lanternSplashDecorated) then return; end
    panel._lanternSplashDecorated = true;
    panel.name = "Lantern";

    local function getAddonVersion()
        local meta;
        if (C_AddOns and C_AddOns.GetAddOnMetadata) then
            meta = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or C_AddOns.GetAddOnMetadata("Lantern", "Version");
        end
        if (not meta and GetAddOnMetadata) then
            meta = GetAddOnMetadata(ADDON_NAME, "Version") or GetAddOnMetadata("Lantern", "Version");
        end
        return meta or "unknown";
    end

    local icon = panel:CreateTexture(nil, "ARTWORK");
    icon:SetSize(96, 96);
    icon:SetPoint("TOPLEFT", 12, -32);
    icon:SetTexture("Interface\\AddOns\\Lantern\\Media\\Images\\Icons\\lantern-core-icon128.blp");

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
    title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, -4);


    local version = getAddonVersion();
    local versionLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
    versionLabel:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6);
    versionLabel:SetText(string.format("Version: %s", version));

    local authorLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
    authorLabel:SetPoint("TOPLEFT", versionLabel, "BOTTOMLEFT", 0, -8);
    authorLabel:SetText("Author: Dede in-game / Sponsorn on curseforge & github");

    local thanks = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
    thanks:SetPoint("TOPLEFT", authorLabel, "BOTTOMLEFT", 0, -8);
    thanks:SetText("Special Thanks to copyrighters for making me pull my thumb out.");

    local modulesTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
    modulesTitle:SetPoint("TOPLEFT", thanks, "BOTTOMLEFT", 0, -18);
    modulesTitle:SetText("Available modules");

    local modulesLine = panel:CreateTexture(nil, "ARTWORK");
    modulesLine:SetPoint("TOPLEFT", modulesTitle, "BOTTOMLEFT", 0, -6);
    modulesLine:SetSize(520, 1);
    modulesLine:SetColorTexture(0.7, 0.6, 0.3, 0.9);

    local craftingDesc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
    craftingDesc:SetPoint("TOPLEFT", modulesLine, "BOTTOMLEFT", 0, -10);
    craftingDesc:SetJustifyH("LEFT");
    craftingDesc:SetWidth(520);
    craftingDesc:SetWordWrap(true);
    craftingDesc:SetText("Crafting Orders: announces guild order activity, personal order alerts, and a Complete + Whisper button.");

    local curseForgeButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate");
    curseForgeButton:SetSize(120, 24);
    curseForgeButton:SetPoint("TOPLEFT", craftingDesc, "BOTTOMLEFT", 0, -10);
    local craftingAddonName = "Lantern_CraftingOrders";
    local hasCraftingOrders = C_AddOns and C_AddOns.IsAddOnLoaded
        and C_AddOns.IsAddOnLoaded(craftingAddonName);
    if (hasCraftingOrders) then
        curseForgeButton:SetText("Already enabled");
        curseForgeButton:SetEnabled(false);
    else
        curseForgeButton:SetText("CurseForge");
        curseForgeButton:SetScript("OnClick", function()
            showLinkPopup(CURSEFORGE_CRAFTING_ORDERS);
        end);
    end

    local warbandDesc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
    warbandDesc:SetPoint("TOPLEFT", curseForgeButton, "BOTTOMLEFT", 0, -16);
    warbandDesc:SetJustifyH("LEFT");
    warbandDesc:SetWidth(520);
    warbandDesc:SetWordWrap(true);
    warbandDesc:SetText("Warband: organize characters into groups with automated gold balancing to/from warbank when opening a bank.");

    local curseForgeButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate");
    curseForgeButton:SetSize(120, 24);
    curseForgeButton:SetPoint("TOPLEFT", warbandDesc, "BOTTOMLEFT", 0, -10);
    local warbandAddonName = "Lantern_Warband";
    local hasWarband = C_AddOns and C_AddOns.IsAddOnLoaded
        and C_AddOns.IsAddOnLoaded(warbandAddonName);
    if (hasWarband) then
        curseForgeButton:SetText("Already enabled");
        curseForgeButton:SetEnabled(false);
    else
        curseForgeButton:SetText("CurseForge");
        curseForgeButton:SetScript("OnClick", function()
            showLinkPopup(CURSEFORGE_WARBAND);
        end);
    end
end

function Lantern:SetupOptions()
    if (self.optionsInitialized or not hasOptionsLibs()) then return; end
    if (Lantern.utils and Lantern.utils.ui and Lantern.utils.ui.RegisterRightButtonWidget) then
        Lantern.utils.ui.RegisterRightButtonWidget();
    end
    if (Lantern.utils and Lantern.utils.ui and Lantern.utils.ui.RegisterInlineButtonRowWidgets) then
        Lantern.utils.ui.RegisterInlineButtonRowWidgets();
    end
    if (Lantern.utils and Lantern.utils.ui and Lantern.utils.ui.RegisterDividerWidget) then
        Lantern.utils.ui.RegisterDividerWidget();
    end
    local generalOptions = self:BuildOptions();
    AceConfig:RegisterOptionsTable(ADDON_NAME .. "_General", generalOptions);

    -- Root category (parent) so children can nest under "Lantern".
    local rootOptions = {
        type = "group",
        name = "Lantern",
        args = {},
    };
    AceConfig:RegisterOptionsTable(ADDON_NAME .. "_Root", rootOptions);
    local rootPanel, rootCategoryID = AceConfigDialog:AddToBlizOptions(ADDON_NAME .. "_Root", "Lantern");
    decorateSplash(rootPanel);
    self.optionsPanel = rootPanel;
    self.optionsPanelName = (rootPanel and (rootPanel.name or rootPanel.ID)) or ADDON_NAME;

    -- General options entry nested under Lantern.
    AceConfigDialog:AddToBlizOptions(ADDON_NAME .. "_General", "General Options", "Lantern");

    -- Settings API (Dragonflight+)
    -- AddToBlizOptions already surfaces categories in the modern Settings UI, so
    -- just capture the category ID if it's available instead of registering a duplicate root.
    if (Settings and Settings.OpenToCategory and not self.splashCategoryID) then
        if (rootCategoryID) then
            self.splashCategoryID = rootCategoryID;
        elseif (rootPanel and rootPanel.GetCategoryID) then
            self.splashCategoryID = rootPanel:GetCategoryID();
        end
    end

    self.optionsInitialized = true;
    self:RegisterAllModuleOptions();
end

function Lantern:OpenOptions()
    if (not hasOptionsLibs()) then
        Lantern:Print("Options unavailable: AceConfig/AceGUI not loaded.");
        return;
    end

    -- Defer opening options if in combat (Settings panel is protected)
    if (InCombatLockdown()) then
        if (not pendingOpenOptions) then
            pendingOpenOptions = true;
            Lantern:Print("Options will open after combat.");
        end
        return;
    end

    if (not self.optionsInitialized) then
        self:SetupOptions();
    end
    local function tryOpenSettings()
        if not (Settings and Settings.OpenToCategory) then
            return false;
        end
        local function settingsShown()
            return SettingsPanel and SettingsPanel.IsShown and SettingsPanel:IsShown();
        end

        local catId = self.splashCategoryID;
        if (not catId and self.optionsPanel and self.optionsPanel.GetCategoryID) then
            catId = self.optionsPanel:GetCategoryID();
        end

        if (catId) then
            if (SettingsPanel and SettingsPanel.OpenToCategory) then
                pcall(SettingsPanel.OpenToCategory, SettingsPanel, catId);
                if (settingsShown()) then return true; end
            end
            pcall(Settings.OpenToCategory, catId);
            if (settingsShown()) then return true; end
        end

        if (Settings.GetCategory) then
            local category = Settings.GetCategory(self.optionsPanelName or "Lantern");
            if (category) then
                if (SettingsPanel and SettingsPanel.OpenToCategory) then
                    pcall(SettingsPanel.OpenToCategory, SettingsPanel, category);
                    if (settingsShown()) then return true; end
                end
                pcall(Settings.OpenToCategory, category);
                if (settingsShown()) then return true; end
            end
        end

        return false;
    end

    -- Prefer Blizzard Settings (10.0+) if available, fallback to Interface Options, then AceConfigDialog frame.
    if (tryOpenSettings()) then
        return;
    end
    Lantern:Print("Options unavailable: Blizzard Settings panel not accessible.");
end

Lantern:RegisterEvent("PLAYER_LOGIN", function()
    if (not Lantern.db) then
        Lantern:SetupDB();
    end
    Lantern:EnsureUIState();
    Lantern:SetupOptions();
    Lantern:InitMinimap();
end);

local function refreshZoneOptions()
    if (Lantern.optionsInitialized) then
        if (Lantern.utils and Lantern.utils.RunOptionsRebuilder) then
            Lantern.utils.RunOptionsRebuilder("autoQuest");
        end
        Lantern:NotifyOptionsChange();
    end
end

Lantern:RegisterEvent("ZONE_CHANGED_NEW_AREA", refreshZoneOptions);
Lantern:RegisterEvent("ZONE_CHANGED_INDOORS", refreshZoneOptions);
Lantern:RegisterEvent("ZONE_CHANGED", refreshZoneOptions);
