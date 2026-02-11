local ADDON_NAME = ...;
local Lantern = _G.Lantern;
if (not Lantern) then return; end

local LanternUX = _G.LanternUX;
local T = LanternUX and LanternUX.Theme;
if (not T) then return; end

local AceGUI = LibStub and LibStub("AceGUI-3.0", true);
local AceConfigDialog = LibStub and LibStub("AceConfigDialog-3.0", true);
if (not AceGUI or not AceConfigDialog) then return; end

-------------------------------------------------------------------------------
-- Layout
-------------------------------------------------------------------------------

local PANEL_W         = 840;
local PANEL_H         = 580;
local SIDEBAR_W       = 200;
local TITLE_H         = 42;
local ITEM_H          = 30;
local SECTION_H       = 30;
local ACCENT_W        = 3;
local ITEM_PAD_LEFT   = 14;
local SIDEBAR_PAD_TOP = 8;

-------------------------------------------------------------------------------
-- Core module mapping
-------------------------------------------------------------------------------

-- module.name → key in Lantern:BuildOptions().args
local CORE_KEY = {
    AutoQuest            = "autoQuest",
    AutoQueue            = "autoQueue",
    CursorRing           = "cursorRing",
    DeleteConfirm        = "deleteConfirm",
    DisableAutoAddSpells = "disableAutoAddSpells",
    MissingPet           = "missingPet",
};

local CORE_ORDER = {
    "AutoQuest", "AutoQueue", "CursorRing",
    "DeleteConfirm", "DisableAutoAddSpells", "MissingPet",
};

-------------------------------------------------------------------------------
-- Custom option definitions (Phase 2 — replaces AceConfig for simple modules)
-------------------------------------------------------------------------------

local function moduleEnabled(name)
    local m = Lantern.modules and Lantern.modules[name];
    return m and m.enabled;
end

local function moduleToggle(name, label, desc)
    return {
        type = "toggle",
        label = label or "Enable",
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
    return {
        {
            type = "toggle",
            label = "Show minimap icon",
            desc = "Show or hide the Lantern minimap button.",
            get = function() return not (Lantern.db.minimap and Lantern.db.minimap.hide); end,
            set = function(val) Lantern:ToggleMinimapIcon(val); end,
        },
    };
end

CUSTOM_OPTIONS["deleteConfirm"] = function()
    return {
        moduleToggle("DeleteConfirm", "Enable", "Replace typing DELETE with a confirm button (Shift pauses)."),
    };
end

CUSTOM_OPTIONS["disableAutoAddSpells"] = function()
    return {
        moduleToggle("DisableAutoAddSpells", "Enable", "Disable auto-adding spells to the action bar."),
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
        moduleToggle("AutoQueue", "Enable", "Enable or disable Auto Queue."),
        {
            type = "toggle",
            label = "Auto-accept role checks",
            desc = "Accept LFG role checks automatically (Shift pauses).",
            disabled = isDisabled,
            get = function() return db().active; end,
            set = function(val) db().active = val and true or false; end,
        },
        {
            type = "toggle",
            label = "Chat announce",
            desc = "Print a chat message when a role check is auto-accepted.",
            disabled = isDisabled,
            get = function() return db().announce; end,
            set = function(val) db().announce = val and true or false; end,
        },
        {
            type = "description",
            text = "Roles are set in the LFG tool. This will accept the role check using your current selection.",
            fontSize = "small",
            color = T.textDim,
        },
    };
end

-------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------

local panel;
local buttons     = {};
local activeKey   = nil;
local aceContainer;
local customScroll;
local splashFrame;
local itemData    = {};  -- key → { appName, path }

-- Forward declarations
local PopulateSplashModules;

-------------------------------------------------------------------------------
-- Content switching
-------------------------------------------------------------------------------

local function ShowContent(key)
    if (splashFrame) then splashFrame:Hide(); end
    if (aceContainer and aceContainer.frame) then aceContainer.frame:Hide(); end
    if (customScroll) then
        customScroll.scrollFrame:Hide();
        LanternUX.ReleaseAll();
    end

    if (key == "home") then
        if (splashFrame) then splashFrame:Show(); end
        PopulateSplashModules();
        return;
    end

    local data = itemData[key];
    if (not data) then return; end

    -- Check if this module has custom widget options
    local optionsFn = CUSTOM_OPTIONS[key];
    if (optionsFn and customScroll) then
        customScroll.scrollFrame:Show();
        customScroll:Reset();
        local options = optionsFn();
        LanternUX.RenderContent(customScroll, options, data.moduleName);
        return;
    end

    -- Fall back to AceConfig
    if (not aceContainer or not AceConfigDialog) then return; end

    aceContainer.frame:Show();

    -- Defer Open by one frame so the container has valid dimensions.
    C_Timer.After(0, function()
        if (not aceContainer or not aceContainer.frame:IsShown()) then return; end

        if (data.path) then
            AceConfigDialog:Open(data.appName, aceContainer, data.path);
        else
            AceConfigDialog:Open(data.appName, aceContainer);
        end

        C_Timer.After(0, function()
            if (aceContainer and aceContainer.DoLayout) then
                aceContainer:DoLayout();
            end
        end);
    end);
end

-------------------------------------------------------------------------------
-- Sidebar selection
-------------------------------------------------------------------------------

local function SelectItem(key)
    if (activeKey == key) then return; end
    activeKey = key;

    for k, btn in pairs(buttons) do
        local sel = (k == key);
        if (sel) then
            btn.bg:SetColorTexture(unpack(T.selected));
            btn.bg:Show();
            btn.bar:Show();
            btn.label:SetTextColor(unpack(T.textBright));
        else
            btn.bg:Hide();
            btn.bar:Hide();
            btn.label:SetTextColor(unpack(T.text));
        end
    end

    ShowContent(key);
end

-------------------------------------------------------------------------------
-- Sidebar factories
-------------------------------------------------------------------------------

local function CreateSidebarButton(parent, key, label, yOffset)
    local btn = CreateFrame("Button", nil, parent);
    btn:SetHeight(ITEM_H);
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -yOffset);
    btn:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -1, -yOffset);

    local bg = btn:CreateTexture(nil, "BACKGROUND");
    bg:SetAllPoints();
    bg:SetColorTexture(unpack(T.selected));
    bg:Hide();
    btn.bg = bg;

    local bar = btn:CreateTexture(nil, "ARTWORK");
    bar:SetWidth(ACCENT_W);
    bar:SetPoint("TOPLEFT");
    bar:SetPoint("BOTTOMLEFT");
    bar:SetColorTexture(unpack(T.accentBar));
    bar:Hide();
    btn.bar = bar;

    local hover = btn:CreateTexture(nil, "HIGHLIGHT");
    hover:SetAllPoints();
    hover:SetColorTexture(unpack(T.hover));

    local text = btn:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
    text:SetPoint("LEFT", ITEM_PAD_LEFT + ACCENT_W, 0);
    text:SetText(label);
    text:SetTextColor(unpack(T.text));
    text:SetJustifyH("LEFT");
    btn.label = text;

    btn:SetScript("OnClick", function()
        SelectItem(key);
    end);

    buttons[key] = btn;
    return btn;
end

local function CreateSectionHeader(parent, label, yOffset)
    local text = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
    text:SetPoint("TOPLEFT", parent, "TOPLEFT", ITEM_PAD_LEFT + ACCENT_W, -yOffset - 8);
    text:SetText(string.upper(label));
    text:SetTextColor(unpack(T.sectionLabel));
    text:SetJustifyH("LEFT");
    return text;
end

-------------------------------------------------------------------------------
-- Splash / Home content
-------------------------------------------------------------------------------

local function CreateSplashContent(parent)
    local f = CreateFrame("Frame", nil, parent);
    f:SetAllPoints();

    local y = -28;

    -- Icon
    local icon = f:CreateTexture(nil, "ARTWORK");
    icon:SetSize(48, 48);
    icon:SetPoint("TOPLEFT", f, "TOPLEFT", 28, y);
    icon:SetTexture("Interface\\AddOns\\Lantern\\Media\\Images\\Icons\\lantern-core-icon128.blp");

    -- Title
    local title = f:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
    title:SetPoint("LEFT", icon, "RIGHT", 12, 6);
    title:SetText("Lantern");
    title:SetTextColor(unpack(T.textBright));

    -- Version
    local ver = "";
    if (C_AddOns and C_AddOns.GetAddOnMetadata) then
        ver = C_AddOns.GetAddOnMetadata("Lantern", "Version") or "";
    end
    local verText = f:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
    verText:SetPoint("LEFT", title, "RIGHT", 8, -1);
    verText:SetText("v" .. ver);
    verText:SetTextColor(unpack(T.textDim));

    -- Description
    local desc = f:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
    desc:SetPoint("TOPLEFT", icon, "BOTTOMLEFT", 0, -16);
    desc:SetWidth(540);
    desc:SetJustifyH("LEFT");
    desc:SetWordWrap(true);
    desc:SetText("A modular quality-of-life addon for World of Warcraft.\nSelect a module from the sidebar to configure it.");
    desc:SetTextColor(unpack(T.splashText));

    -- Module status header
    local statusHeader = f:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
    statusHeader:SetPoint("TOPLEFT", f, "TOPLEFT", 28, -160);
    statusHeader:SetText("Loaded Modules");
    statusHeader:SetTextColor(unpack(T.textBright));

    local divider = f:CreateTexture(nil, "ARTWORK");
    divider:SetHeight(1);
    divider:SetPoint("TOPLEFT", statusHeader, "BOTTOMLEFT", 0, -6);
    divider:SetPoint("RIGHT", f, "RIGHT", -28, 0);
    divider:SetColorTexture(unpack(T.divider));

    f._moduleListY = -190;
    f._moduleLabels = {};
    f._moduleDots = {};

    return f;
end

PopulateSplashModules = function()
    if (not splashFrame) then return; end

    local names = {};
    for name, _ in pairs(Lantern.modules or {}) do
        table.insert(names, name);
    end
    table.sort(names);

    local y = splashFrame._moduleListY;

    for i, name in ipairs(names) do
        local dot = splashFrame._moduleDots[i];
        local label = splashFrame._moduleLabels[i];

        if (not dot) then
            dot = splashFrame:CreateTexture(nil, "ARTWORK");
            dot:SetSize(8, 8);
            dot:SetTexture("Interface\\Buttons\\WHITE8x8");
            splashFrame._moduleDots[i] = dot;
        end

        if (not label) then
            label = splashFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
            splashFrame._moduleLabels[i] = label;
        end

        local mod = Lantern.modules[name];
        local displayName = (mod.opts and mod.opts.title) or name;

        dot:ClearAllPoints();
        dot:SetPoint("TOPLEFT", splashFrame, "TOPLEFT", 32, y - 2);
        if (mod.enabled) then
            dot:SetColorTexture(unpack(T.enabled));
        else
            dot:SetColorTexture(unpack(T.disabledDot));
        end
        dot:Show();

        label:ClearAllPoints();
        label:SetPoint("TOPLEFT", splashFrame, "TOPLEFT", 46, y);
        label:SetJustifyH("LEFT");
        label:SetTextColor(unpack(T.text));
        label:SetText(displayName);
        label:Show();

        y = y - 24;
    end

    for i = #names + 1, #splashFrame._moduleLabels do
        if (splashFrame._moduleDots[i]) then splashFrame._moduleDots[i]:Hide(); end
        splashFrame._moduleLabels[i]:Hide();
    end
end

-------------------------------------------------------------------------------
-- Populate sidebar
-------------------------------------------------------------------------------

local function PopulateSidebar()
    if (not panel or not panel.sidebar) then return; end

    local sidebar = panel.sidebar;
    local y = SIDEBAR_PAD_TOP;

    -- Home
    CreateSidebarButton(sidebar, "home", "Home", y);
    y = y + ITEM_H;

    -- General
    itemData["general"] = {
        appName = "Lantern_General",
        path = "general",
    };
    CreateSidebarButton(sidebar, "general", "General", y);
    y = y + ITEM_H;

    -- Modules header
    y = y + 4;
    CreateSectionHeader(sidebar, "Modules", y);
    y = y + SECTION_H;

    -- Core modules in defined order
    for _, moduleName in ipairs(CORE_ORDER) do
        local mod = Lantern.modules[moduleName];
        if (mod) then
            local key = CORE_KEY[moduleName];
            local label = (mod.opts and mod.opts.title) or moduleName;

            itemData[key] = {
                appName = "Lantern_General",
                path = key,
                moduleName = moduleName,
            };

            CreateSidebarButton(sidebar, key, label, y);
            y = y + ITEM_H;
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
        y = y + 4;
        CreateSectionHeader(sidebar, "Addons", y);
        y = y + SECTION_H;

        for _, moduleName in ipairs(external) do
            local mod = Lantern.modules[moduleName];
            local label = (mod.opts and mod.opts.title) or moduleName;
            local key = "module_" .. moduleName;

            itemData[key] = {
                appName = key,
            };

            CreateSidebarButton(sidebar, key, label, y);
            y = y + ITEM_H;
        end
    end
end

-------------------------------------------------------------------------------
-- Panel creation
-------------------------------------------------------------------------------

local function CreatePanel()
    if (panel) then return panel; end

    -- Main frame
    panel = CreateFrame("Frame", "LanternSettingsPanel", UIParent, "BackdropTemplate");
    panel:SetSize(PANEL_W, PANEL_H);
    panel:SetPoint("CENTER");
    panel:SetFrameStrata("DIALOG");
    panel:SetFrameLevel(100);
    panel:EnableMouse(true);
    panel:SetMovable(true);
    panel:SetClampedToScreen(true);
    panel:Hide();

    panel:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    });
    panel:SetBackdropColor(unpack(T.bg));
    panel:SetBackdropBorderColor(unpack(T.border));

    ---------------------------------------------------------------------------
    -- Title bar
    ---------------------------------------------------------------------------

    local titleBar = CreateFrame("Frame", nil, panel);
    titleBar:SetHeight(TITLE_H);
    titleBar:SetPoint("TOPLEFT");
    titleBar:SetPoint("TOPRIGHT");
    titleBar:EnableMouse(true);
    titleBar:RegisterForDrag("LeftButton");
    titleBar:SetScript("OnDragStart", function() panel:StartMoving(); end);
    titleBar:SetScript("OnDragStop", function() panel:StopMovingOrSizing(); end);

    local titleBg = titleBar:CreateTexture(nil, "BACKGROUND");
    titleBg:SetAllPoints();
    titleBg:SetColorTexture(unpack(T.titleBar));

    -- Bottom border (amber glow from center, fading to border color at edges)
    local borderLeft = titleBar:CreateTexture(nil, "ARTWORK");
    borderLeft:SetHeight(1);
    borderLeft:SetPoint("BOTTOMLEFT", titleBar, "BOTTOMLEFT");
    borderLeft:SetPoint("BOTTOMRIGHT", titleBar, "BOTTOM");
    borderLeft:SetTexture("Interface\\Buttons\\WHITE8x8");
    borderLeft:SetGradient("HORIZONTAL",
        CreateColor(T.border[1], T.border[2], T.border[3], T.border[4]),
        CreateColor(T.accent[1], T.accent[2], T.accent[3], 0.60)
    );

    local borderRight = titleBar:CreateTexture(nil, "ARTWORK");
    borderRight:SetHeight(1);
    borderRight:SetPoint("BOTTOMLEFT", titleBar, "BOTTOM");
    borderRight:SetPoint("BOTTOMRIGHT", titleBar, "BOTTOMRIGHT");
    borderRight:SetTexture("Interface\\Buttons\\WHITE8x8");
    borderRight:SetGradient("HORIZONTAL",
        CreateColor(T.accent[1], T.accent[2], T.accent[3], 0.60),
        CreateColor(T.border[1], T.border[2], T.border[3], T.border[4])
    );

    -- Icon
    local icon = titleBar:CreateTexture(nil, "ARTWORK");
    icon:SetSize(22, 22);
    icon:SetPoint("LEFT", 14, 0);
    icon:SetTexture("Interface\\AddOns\\Lantern\\Media\\Images\\Icons\\lantern-core-icon64.blp");

    -- Title
    local titleText = titleBar:CreateFontString(nil, "ARTWORK", "GameFontNormal");
    titleText:SetPoint("LEFT", icon, "RIGHT", 8, 0);
    titleText:SetText("Lantern");
    titleText:SetTextColor(unpack(T.textBright));

    -- Version (subtle)
    local ver = "";
    if (C_AddOns and C_AddOns.GetAddOnMetadata) then
        ver = C_AddOns.GetAddOnMetadata("Lantern", "Version") or "";
    end
    if (ver ~= "") then
        local verText = titleBar:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
        verText:SetPoint("LEFT", titleText, "RIGHT", 6, -1);
        verText:SetText("v" .. ver);
        verText:SetTextColor(unpack(T.textDim));
    end

    -- Close button
    local closeBtn = CreateFrame("Button", nil, titleBar);
    closeBtn:SetSize(TITLE_H, TITLE_H);
    closeBtn:SetPoint("TOPRIGHT");

    local closeText = closeBtn:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
    closeText:SetPoint("CENTER", 0, 0);
    closeText:SetText("\195\151");  -- × character
    closeText:SetTextColor(unpack(T.textDim));

    local closeHover = closeBtn:CreateTexture(nil, "HIGHLIGHT");
    closeHover:SetAllPoints();
    closeHover:SetColorTexture(0.8, 0.2, 0.2, 0.15);

    closeBtn:SetScript("OnEnter", function() closeText:SetTextColor(1, 1, 1); end);
    closeBtn:SetScript("OnLeave", function() closeText:SetTextColor(unpack(T.textDim)); end);
    closeBtn:SetScript("OnClick", function() panel:Hide(); end);

    ---------------------------------------------------------------------------
    -- Sidebar
    ---------------------------------------------------------------------------

    local sidebar = CreateFrame("Frame", nil, panel);
    sidebar:SetWidth(SIDEBAR_W);
    sidebar:SetPoint("TOPLEFT", 0, -TITLE_H);
    sidebar:SetPoint("BOTTOMLEFT");

    local sidebarBg = sidebar:CreateTexture(nil, "BACKGROUND");
    sidebarBg:SetAllPoints();
    sidebarBg:SetColorTexture(unpack(T.sidebar));

    -- Right border
    local sidebarBorder = sidebar:CreateTexture(nil, "ARTWORK");
    sidebarBorder:SetWidth(1);
    sidebarBorder:SetPoint("TOPRIGHT", sidebar, "TOPRIGHT");
    sidebarBorder:SetPoint("BOTTOMRIGHT", sidebar, "BOTTOMRIGHT");
    sidebarBorder:SetColorTexture(unpack(T.border));

    panel.sidebar = sidebar;

    ---------------------------------------------------------------------------
    -- Content area
    ---------------------------------------------------------------------------

    local content = CreateFrame("Frame", nil, panel);
    content:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 1, 0);
    content:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -1, 1);
    content:SetClipsChildren(true);
    panel.content = content;

    -- Splash content (Home page)
    splashFrame = CreateSplashContent(content);

    -- AceGUI container for module options (fallback for complex modules)
    aceContainer = AceGUI:Create("SimpleGroup");
    aceContainer:SetLayout("Fill");
    aceContainer.frame:SetParent(content);
    aceContainer.frame:ClearAllPoints();
    aceContainer.frame:SetPoint("TOPLEFT", content, "TOPLEFT", 4, -4);
    aceContainer.frame:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -4, 4);
    aceContainer.frame:Hide();

    -- Custom scroll container for widget-based options
    if (LanternUX and LanternUX.CreateScrollContainer) then
        customScroll = LanternUX.CreateScrollContainer(content);
        customScroll.scrollFrame:Hide();
    end

    ---------------------------------------------------------------------------
    -- Sidebar items
    ---------------------------------------------------------------------------

    PopulateSidebar();

    ---------------------------------------------------------------------------
    -- Lifecycle
    ---------------------------------------------------------------------------

    panel:SetScript("OnShow", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPEN or 850);
        if (activeKey == "home" or not activeKey) then
            PopulateSplashModules();
        end
        -- Re-render current content (widgets were released on hide)
        if (activeKey and activeKey ~= "home") then
            ShowContent(activeKey);
        end
    end);

    panel:SetScript("OnHide", function()
        if (aceContainer) then
            aceContainer:ReleaseChildren();
            aceContainer.frame:Hide();
        end
        if (customScroll) then
            LanternUX.ReleaseAll();
            customScroll.scrollFrame:Hide();
        end
        PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE or 851);
    end);

    -- ESC to close
    table.insert(UISpecialFrames, "LanternSettingsPanel");

    -- Default to home on first open
    if (not activeKey) then
        SelectItem("home");
    end

    return panel;
end

-------------------------------------------------------------------------------
-- Integration with Lantern
-------------------------------------------------------------------------------

local function OpenSettingsPanel()
    if (not panel) then
        if (not Lantern.optionsInitialized) then
            Lantern:SetupOptions();
        end
        CreatePanel();
    end

    if (panel:IsShown()) then
        panel:Hide();
    else
        panel:Show();
    end
end

-- Override Lantern:OpenOptions() to use the custom panel.
function Lantern:OpenOptions()
    -- SetupOptions touches protected Blizzard UI; defer if in combat and not initialized.
    if (not self.optionsInitialized and InCombatLockdown()) then
        self._pendingSettingsPanel = true;
        Lantern:Print("Options will open after combat.");
        return;
    end

    if (not self.optionsInitialized) then
        self:SetupOptions();
    end

    self._pendingSettingsPanel = false;
    OpenSettingsPanel();
end

-- Handle deferred open after combat ends.
local combatFrame = CreateFrame("Frame");
combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
combatFrame:SetScript("OnEvent", function()
    if (Lantern._pendingSettingsPanel) then
        Lantern._pendingSettingsPanel = false;
        C_Timer.After(0.1, function()
            Lantern:OpenOptions();
        end);
    end
end);
