local ADDON_NAME, Lantern = ...;

local LDB = LibStub and LibStub("LibDataBroker-1.1", true);
local LDBIcon = LibStub and LibStub("LibDBIcon-1.0", true);

local MINIMAP_OBJECT_NAME = "Lantern";
local DEFAULT_ICON = "Interface\\AddOns\\Lantern\\Media\\Images\\Icons\\lantern-core-icon64.blp";
local CURSEFORGE_CRAFTING_ORDERS = "https://www.curseforge.com/wow/addons/lantern-craftingorders";
local CURSEFORGE_WARBAND = "https://www.curseforge.com/wow/addons/lantern-warband";
local LINK_POPUP_NAME = "LanternCopyLinkDialog";

local function hasMinimapLibs()
    return LDB and LDBIcon;
end

-------------------------------------------------------------------------------
-- Combat Lockdown Handling for Options
-------------------------------------------------------------------------------

local combatFrame = CreateFrame("Frame", "Lantern_CombatFrame");
combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
combatFrame:SetScript("OnEvent", function()
    if (Lantern._pendingSettingsPanel) then
        Lantern._pendingSettingsPanel = false;
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

function Lantern:ApplyMinimapStyle()
    if (not hasMinimapLibs()) then return; end
    local clean = self.db.minimap and self.db.minimap.modern;
    if (clean) then
        LDBIcon:RemoveButtonBorder(MINIMAP_OBJECT_NAME);
        LDBIcon:RemoveButtonBackground(MINIMAP_OBJECT_NAME);
        LDBIcon:SetButtonIcon(MINIMAP_OBJECT_NAME, nil, 24);
        local btn = LDBIcon:GetMinimapButton(MINIMAP_OBJECT_NAME);
        if (btn) then
            local hl = btn:GetHighlightTexture();
            if (hl) then hl:Hide(); end
            if (not btn._lanternHover) then
                local hover = btn:CreateTexture(nil, "BACKGROUND", nil, 1);
                hover:SetTexture("Interface\\Cooldown\\starburst");
                hover:SetSize(32, 32);
                hover:Hide();
                hover:SetPoint("CENTER", 0, -4);
                hover:SetVertexColor(1.0, 0.65, 0.2); -- warm lantern glow
                hover:SetAlpha(0.6);
                hover:SetBlendMode("ADD");
                btn._lanternHover = hover;
                btn:HookScript("OnEnter", function() hover:Show(); end);
                btn:HookScript("OnLeave", function() hover:Hide(); end);
            end
        end
    else
        LDBIcon:ResetButtonBorder(MINIMAP_OBJECT_NAME);
        LDBIcon:ResetButtonBackground(MINIMAP_OBJECT_NAME);
        LDBIcon:ResetButtonIcon(MINIMAP_OBJECT_NAME);
        LDBIcon:ResetButtonHighlightTexture(MINIMAP_OBJECT_NAME);
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
                    if (SettingsPanel and SettingsPanel:IsShown()) then
                        HideUIPanel(SettingsPanel);
                    else
                        Lantern:OpenOptions();
                    end
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
    self:ApplyMinimapStyle();
    self.minimapInitialized = true;
end

-------------------------------------------------------------------------------
-- Blizzard Settings stub (ESC > Options > Addons > Lantern)
-------------------------------------------------------------------------------

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

local function createSplashFrame()
    local frame = CreateFrame("Frame", "LanternSettingsSplash");
    frame:SetSize(600, 400);
    frame:Hide();

    local icon = frame:CreateTexture("LanternSettingsSplash_Icon", "ARTWORK");
    icon:SetSize(96, 96);
    icon:SetPoint("TOPLEFT", 12, -32);
    icon:SetTexture("Interface\\AddOns\\Lantern\\Media\\Images\\Icons\\lantern-core-icon128.blp");

    local title = frame:CreateFontString("LanternSettingsSplash_Title", "ARTWORK", "GameFontNormalLarge");
    title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, -4);
    title:SetText("Lantern");

    local version = getAddonVersion();
    local versionLabel = frame:CreateFontString("LanternSettingsSplash_Version", "ARTWORK", "GameFontHighlight");
    versionLabel:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6);
    versionLabel:SetText(string.format("Version: %s", version));

    local authorLabel = frame:CreateFontString("LanternSettingsSplash_Author", "ARTWORK", "GameFontHighlight");
    authorLabel:SetPoint("TOPLEFT", versionLabel, "BOTTOMLEFT", 0, -8);
    authorLabel:SetText("Author: Dede in-game / Sponsorn on curseforge & github");

    local thanks = frame:CreateFontString("LanternSettingsSplash_Thanks", "ARTWORK", "GameFontHighlight");
    thanks:SetPoint("TOPLEFT", authorLabel, "BOTTOMLEFT", 0, -8);
    thanks:SetText("Special Thanks to copyrighters for making me pull my thumb out.");

    -- Open Settings button
    local openBtn = CreateFrame("Button", "LanternSettingsSplash_OpenBtn", frame, "UIPanelButtonTemplate");
    openBtn:SetSize(160, 28);
    openBtn:SetPoint("TOPLEFT", thanks, "BOTTOMLEFT", 0, -16);
    openBtn:SetText("Open Settings");
    openBtn:SetScript("OnClick", function()
        if (SettingsPanel and SettingsPanel:IsShown()) then
            HideUIPanel(SettingsPanel);
        end
        Lantern:OpenOptions();
    end);

    -- Available modules section
    local modulesTitle = frame:CreateFontString("LanternSettingsSplash_ModTitle", "ARTWORK", "GameFontNormalLarge");
    modulesTitle:SetPoint("TOPLEFT", openBtn, "BOTTOMLEFT", 0, -18);
    modulesTitle:SetText("Available modules");

    local modulesLine = frame:CreateTexture("LanternSettingsSplash_ModLine", "ARTWORK");
    modulesLine:SetPoint("TOPLEFT", modulesTitle, "BOTTOMLEFT", 0, -6);
    modulesLine:SetSize(520, 1);
    modulesLine:SetColorTexture(0.7, 0.6, 0.3, 0.9);

    local craftingDesc = frame:CreateFontString("LanternSettingsSplash_CraftDesc", "ARTWORK", "GameFontHighlight");
    craftingDesc:SetPoint("TOPLEFT", modulesLine, "BOTTOMLEFT", 0, -10);
    craftingDesc:SetJustifyH("LEFT");
    craftingDesc:SetWidth(520);
    craftingDesc:SetWordWrap(true);
    craftingDesc:SetText("Crafting Orders: announces guild order activity, personal order alerts, and a Complete + Whisper button.");

    local craftBtn = CreateFrame("Button", "LanternSettingsSplash_CraftBtn", frame, "UIPanelButtonTemplate");
    craftBtn:SetSize(120, 24);
    craftBtn:SetPoint("TOPLEFT", craftingDesc, "BOTTOMLEFT", 0, -10);
    local hasCraftingOrders = C_AddOns and C_AddOns.IsAddOnLoaded
        and C_AddOns.IsAddOnLoaded("Lantern_CraftingOrders");
    if (hasCraftingOrders) then
        craftBtn:SetText("Already enabled");
        craftBtn:SetEnabled(false);
    else
        craftBtn:SetText("CurseForge");
        craftBtn:SetScript("OnClick", function()
            showLinkPopup(CURSEFORGE_CRAFTING_ORDERS);
        end);
    end

    local warbandDesc = frame:CreateFontString("LanternSettingsSplash_WarbDesc", "ARTWORK", "GameFontHighlight");
    warbandDesc:SetPoint("TOPLEFT", craftBtn, "BOTTOMLEFT", 0, -16);
    warbandDesc:SetJustifyH("LEFT");
    warbandDesc:SetWidth(520);
    warbandDesc:SetWordWrap(true);
    warbandDesc:SetText("Warband: organize characters into groups with automated gold balancing to/from warbank when opening a bank.");

    local warbandBtn = CreateFrame("Button", "LanternSettingsSplash_WarbBtn", frame, "UIPanelButtonTemplate");
    warbandBtn:SetSize(120, 24);
    warbandBtn:SetPoint("TOPLEFT", warbandDesc, "BOTTOMLEFT", 0, -10);
    local hasWarband = C_AddOns and C_AddOns.IsAddOnLoaded
        and C_AddOns.IsAddOnLoaded("Lantern_Warband");
    if (hasWarband) then
        warbandBtn:SetText("Already enabled");
        warbandBtn:SetEnabled(false);
    else
        warbandBtn:SetText("CurseForge");
        warbandBtn:SetScript("OnClick", function()
            showLinkPopup(CURSEFORGE_WARBAND);
        end);
    end

    return frame;
end

function Lantern:SetupOptions()
    if (self.optionsInitialized) then return; end

    -- Register Blizzard Settings stub category
    if (Settings and Settings.RegisterCanvasLayoutCategory) then
        local splashFrame = createSplashFrame();
        local category = Settings.RegisterCanvasLayoutCategory(splashFrame, "Lantern");
        category.ID = "Lantern";
        Settings.RegisterAddOnCategory(category);
        self.splashCategoryID = category.ID;
        self.optionsPanel = splashFrame;
    end

    self.optionsInitialized = true;
end

function Lantern:OpenOptions()
    -- Defer opening options if in combat (Settings panel is protected)
    if (InCombatLockdown()) then
        if (not self._pendingSettingsPanel) then
            self._pendingSettingsPanel = true;
            Lantern:Print("Options will open after combat.");
        end
        return;
    end

    if (not self.optionsInitialized) then
        self:SetupOptions();
    end

    -- Options.lua overrides this method when LanternUX is available.
    -- This base version opens the Blizzard Settings stub as fallback.
    if (Settings and Settings.OpenToCategory) then
        Settings.OpenToCategory("Lantern");
    end
end

Lantern:RegisterEvent("PLAYER_LOGIN", function()
    if (not Lantern.db) then
        Lantern:SetupDB();
    end
    Lantern:EnsureUIState();
    Lantern:SetupOptions();
    Lantern:InitMinimap();
end);
