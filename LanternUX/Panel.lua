local ADDON_NAME = ...;

local LanternUX = _G.LanternUX;
local T = LanternUX and LanternUX.Theme;
if (not T) then return; end

local AceGUI = LibStub and LibStub("AceGUI-3.0", true);
local AceConfigDialog = LibStub and LibStub("AceConfigDialog-3.0", true);

-------------------------------------------------------------------------------
-- Layout constants
-------------------------------------------------------------------------------

local DEFAULT_W       = 920;
local DEFAULT_H       = 580;
local SIDEBAR_W       = 200;
local TITLE_H         = 42;
local ITEM_H          = 30;
local SECTION_H       = 30;
local ACCENT_W        = 3;
local ITEM_PAD_LEFT   = 14;
local SIDEBAR_PAD_TOP = 8;
local DESC_PANEL_W    = 220;

local panelFrameCounter = 0;
local function NextPanelName(prefix)
    panelFrameCounter = panelFrameCounter + 1;
    return prefix .. panelFrameCounter;
end

-------------------------------------------------------------------------------
-- PanelMixin
-------------------------------------------------------------------------------

local PanelMixin = {};

function PanelMixin:AddSection(key, label)
    if (self._sectionMap[key]) then return; end
    self._sectionMap[key] = label;
    table.insert(self._sections, { key = key, label = label });
    self._sidebarDirty = true;
end

function PanelMixin:AddSidebarGroup(key, opts)
    if (self._sidebarGroupMap[key]) then return; end
    table.insert(self._sidebarGroups, { key = key, opts = opts });
    self._sidebarGroupMap[key] = opts;
    self._sidebarDirty = true;
end

function PanelMixin:AddPage(key, opts)
    if (self._pageMap[key]) then return; end
    self._pageMap[key] = opts;
    table.insert(self._pages, { key = key, opts = opts });
    self._sidebarDirty = true;
    if (self._OnPageAdded) then self:_OnPageAdded(); end
end

function PanelMixin:Show()
    if (not self._frame) then
        self:_Build();
    end
    if (self._sidebarDirty) then
        self:_BuildSidebar();
        self._sidebarDirty = false;
    end
    self._frame:Show();
end

function PanelMixin:Hide()
    if (self._frame) then
        self._frame:Hide();
    end
end

function PanelMixin:Toggle()
    if (self._frame and self._frame:IsShown()) then
        self:Hide();
    else
        self:Show();
    end
end

function PanelMixin:SelectPage(key)
    if (not self._frame) then return; end
    self:_SelectItem(key);
end

function PanelMixin:RefreshCurrentPage()
    local key = self._activeKey;
    if (not key) then return; end

    -- Preserve scroll position across refresh
    local savedScroll;
    if (self._customScroll) then
        savedScroll = self._customScroll.scrollFrame:GetVerticalScroll();
    end

    self._activeKey = nil;
    self:_SelectItem(key);

    -- Restore scroll position
    if (savedScroll and self._customScroll) then
        self._customScroll:RestoreScroll(savedScroll);
    end
end

function PanelMixin:GetFrame()
    return self._frame;
end

-------------------------------------------------------------------------------
-- Internal: sidebar button factories
-------------------------------------------------------------------------------

function PanelMixin:_CreateSidebarButton(parent, key, label, yOffset)
    local btn = CreateFrame("Button", NextPanelName("LUX_SidebarBtn_"), parent);
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

    local self_ = self;
    btn:SetScript("OnClick", function()
        self_:_SelectItem(key);
    end);

    self._buttons[key] = btn;
    return btn;
end

function PanelMixin:_CreateSectionHeader(parent, label, yOffset)
    local text = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
    text:SetPoint("TOPLEFT", parent, "TOPLEFT", ITEM_PAD_LEFT + ACCENT_W, -yOffset - 8);
    text:SetText(string.upper(label));
    text:SetTextColor(unpack(T.sectionLabel));
    text:SetJustifyH("LEFT");
    return text;
end

local GROUP_CHILD_PAD = 12;  -- extra left indent for child items

function PanelMixin:_GetGroupForPage(pageKey)
    local page = self._pageMap[pageKey];
    if (page and page.sidebarGroup and self._sidebarGroupMap[page.sidebarGroup]) then
        return page.sidebarGroup;
    end
    return nil;
end

function PanelMixin:_CreateSidebarGroupHeader(parent, groupKey, label, yOffset)
    local btn = CreateFrame("Button", NextPanelName("LUX_SidebarGroup_"), parent);
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
    text:SetPoint("RIGHT", btn, "RIGHT", -22, 0);

    -- Arrow on the right (matches Widgets/Group.lua style)
    local arrow = btn:CreateTexture(nil, "ARTWORK");
    arrow:SetSize(10, 10);
    arrow:SetPoint("RIGHT", -8, 0);
    arrow:SetAtlas("ui-questtrackerbutton-secondary-expand");
    arrow:SetDesaturated(true);
    arrow:SetVertexColor(unpack(T.textDim));
    btn._arrow = arrow;
    text:SetText(label);
    text:SetTextColor(unpack(T.text));
    text:SetJustifyH("LEFT");
    btn.label = text;

    btn._groupKey = groupKey;

    local self_ = self;
    btn:SetScript("OnClick", function()
        self_._expandedGroups[groupKey] = not self_._expandedGroups[groupKey];
        self_._sidebarDirty = true;
        self_:_BuildSidebar();
        self_._sidebarDirty = false;
    end);

    self._sidebarDropdowns[groupKey] = btn;
    return btn;
end

function PanelMixin:_UpdateGroupChevron(btn, expanded)
    if (not btn._arrow) then return; end
    if (expanded) then
        btn._arrow:SetAtlas("ui-questtrackerbutton-secondary-collapse");
    else
        btn._arrow:SetAtlas("ui-questtrackerbutton-secondary-expand");
    end
end

function PanelMixin:_CreateSidebarChildButton(parent, key, label, yOffset)
    local btn = CreateFrame("Button", NextPanelName("LUX_SidebarChild_"), parent);
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
    text:SetPoint("LEFT", ITEM_PAD_LEFT + ACCENT_W + GROUP_CHILD_PAD, 0);
    text:SetText(label);
    text:SetTextColor(unpack(T.text));
    text:SetJustifyH("LEFT");
    btn.label = text;

    local self_ = self;
    btn:SetScript("OnClick", function()
        self_:_SelectItem(key);
    end);

    self._buttons[key] = btn;
    return btn;
end

-------------------------------------------------------------------------------
-- Internal: sidebar selection
-------------------------------------------------------------------------------

function PanelMixin:_SelectItem(key)
    if (self._activeKey == key) then return; end
    self._activeKey = key;

    -- If a sidebar button is clicked during search, exit search mode
    if (self._ExitSearchOnSelect) then self:_ExitSearchOnSelect(); end

    -- Auto-expand the group containing the selected page
    local activeGroupKey = self:_GetGroupForPage(key);
    if (activeGroupKey and not self._expandedGroups[activeGroupKey]) then
        self._expandedGroups[activeGroupKey] = true;
        self._sidebarDirty = true;
        self:_BuildSidebar();
        self._sidebarDirty = false;
        return;  -- _BuildSidebar re-selects the active key
    end

    -- Regular sidebar buttons (includes child buttons)
    for k, btn in pairs(self._buttons) do
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

    -- Group headers: highlight if a child is active
    for gKey, btn in pairs(self._sidebarDropdowns) do
        if (gKey == activeGroupKey) then
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

    self:_ShowContent(key);
end

-------------------------------------------------------------------------------
-- Internal: content switching
-------------------------------------------------------------------------------

function PanelMixin:_HideAllContent()
    if (self._splashFrames) then
        for _, sf in pairs(self._splashFrames) do sf:Hide(); end
    end
    if (self._aceContainer and self._aceContainer.frame) then
        self._aceContainer.frame:Hide();
    end
    if (self._customScroll) then
        self._customScroll.scrollFrame:Hide();
        LanternUX.ReleaseAll();
    end
    if (self._descPanel) then self._descPanel:Hide(); end
end

function PanelMixin:_ShowContent(key)
    self:_HideAllContent();

    local page = self._pageMap[key];
    if (not page) then return; end

    -- Custom frame page
    if (page.frame) then
        if (not self._splashFrames) then self._splashFrames = {}; end
        if (not self._splashFrames[key]) then
            self._splashFrames[key] = page.frame(self._content);
        end
        self._splashFrames[key]:Show();
        -- Call onShow callback if present
        if (page.onShow) then page.onShow(); end
        return;
    end

    -- Widget page
    if (page.widgets and self._customScroll) then
        if (self._descPanel) then
            self._descPanel:Show();
            LanternUX.descPanel = self._descPanel;
        end
        self._customScroll.scrollFrame:Show();
        self._customScroll:Reset();
        local options = page.widgets();
        local headerInfo = nil;
        if (page.title) then
            headerInfo = { title = page.title, description = page.description };
        end
        LanternUX.RenderContent(self._customScroll, options, headerInfo, key);

        -- Search: scroll to widget if requested
        if (self._ConsumeScrollToWidget) then self:_ConsumeScrollToWidget(); end
        return;
    end

    -- AceConfig fallback page
    if (page.aceConfig and self._aceContainer and AceConfigDialog) then
        self._aceContainer.frame:Show();
        local aceConfig = page.aceConfig;
        C_Timer.After(0, function()
            if (not self._aceContainer or not self._aceContainer.frame:IsShown()) then return; end
            if (aceConfig.path) then
                AceConfigDialog:Open(aceConfig.appName, self._aceContainer, aceConfig.path);
            else
                AceConfigDialog:Open(aceConfig.appName, self._aceContainer);
            end
            C_Timer.After(0, function()
                if (self._aceContainer and self._aceContainer.DoLayout) then
                    self._aceContainer:DoLayout();
                end
            end);
        end);
        return;
    end
end

-------------------------------------------------------------------------------
-- Internal: build sidebar from registered pages/sections
-------------------------------------------------------------------------------

function PanelMixin:_BuildSidebar()
    if (not self._sidebar) then return; end

    -- Clear existing buttons, group headers, and section headers
    for _, btn in pairs(self._buttons) do
        btn:Hide();
    end
    self._buttons = {};

    for _, btn in pairs(self._sidebarDropdowns) do
        btn:Hide();
    end
    self._sidebarDropdowns = {};

    if (self._sectionHeaders) then
        for _, hdr in ipairs(self._sectionHeaders) do
            hdr:Hide();
        end
    end
    self._sectionHeaders = {};

    local sidebar = self._sidebarScrollChild or self._sidebar;
    local y = SIDEBAR_PAD_TOP;

    -- Helper: check if a page is assigned to a valid sidebar group
    local function isGrouped(entry)
        return entry.opts.sidebarGroup and self._sidebarGroupMap[entry.opts.sidebarGroup];
    end

    -- Helper: collect pages belonging to a sidebar group
    local function collectGroupPages(groupKey)
        local pages = {};
        for _, entry in ipairs(self._pages) do
            if (entry.opts.sidebarGroup == groupKey) then
                table.insert(pages, { key = entry.key, label = entry.opts.label or entry.key });
            end
        end
        return pages;
    end

    -- Helper: render a sidebar group (header + expandable children)
    local function renderGroup(groupKey, label)
        local pages = collectGroupPages(groupKey);
        if (#pages == 0) then return; end

        local hdr = self:_CreateSidebarGroupHeader(sidebar, groupKey, label, y);
        local expanded = self._expandedGroups[groupKey];
        self:_UpdateGroupChevron(hdr, expanded);
        y = y + ITEM_H;

        if (expanded) then
            for _, page in ipairs(pages) do
                self:_CreateSidebarChildButton(sidebar, page.key, page.label, y);
                y = y + ITEM_H;
            end
        end
    end

    -- Pages without a section (appear first, in registration order)
    for _, entry in ipairs(self._pages) do
        if (not entry.opts.section and not isGrouped(entry)) then
            self:_CreateSidebarButton(sidebar, entry.key, entry.opts.label or entry.key, y);
            y = y + ITEM_H;
        end
    end

    -- Sidebar groups without a section
    for _, group in ipairs(self._sidebarGroups) do
        if (not group.opts.section) then
            renderGroup(group.key, group.opts.label or group.key);
        end
    end

    -- Then each section + its pages + its groups
    for _, sec in ipairs(self._sections) do
        y = y + 4;
        local hdr = self:_CreateSectionHeader(sidebar, sec.label, y);
        table.insert(self._sectionHeaders, hdr);
        y = y + SECTION_H;

        -- Non-grouped pages in this section
        for _, entry in ipairs(self._pages) do
            if (entry.opts.section == sec.key and not isGrouped(entry)) then
                self:_CreateSidebarButton(sidebar, entry.key, entry.opts.label or entry.key, y);
                y = y + ITEM_H;
            end
        end

        -- Sidebar groups in this section
        for _, group in ipairs(self._sidebarGroups) do
            if (group.opts.section == sec.key) then
                renderGroup(group.key, group.opts.label or group.key);
            end
        end
    end

    -- Update sidebar scroll content height
    if (self._sidebarScroll) then
        self._sidebarScroll:UpdateContentHeight(y);
    end

    -- Select first page if none active, or re-select current
    if (self._activeKey and (self._buttons[self._activeKey] or self:_GetGroupForPage(self._activeKey))) then
        -- Force re-render by resetting activeKey
        local key = self._activeKey;
        self._activeKey = nil;
        self:_SelectItem(key);
    elseif (#self._pages > 0) then
        self:_SelectItem(self._pages[1].key);
    end
end

-------------------------------------------------------------------------------
-- Internal: build WoW frame (lazy, called once on first Show)
-------------------------------------------------------------------------------

function PanelMixin:_Build()
    if (self._frame) then return; end

    local config = self._config;
    local panelW = config.width or DEFAULT_W;
    local panelH = config.height or DEFAULT_H;

    -- Main frame
    local frame = CreateFrame("Frame", config.name, UIParent, "BackdropTemplate");
    frame:SetSize(panelW, panelH);
    frame:SetPoint("CENTER");
    frame:SetFrameStrata("DIALOG");
    frame:SetFrameLevel(100);
    frame:EnableMouse(true);
    frame:SetMovable(true);
    frame:SetClampedToScreen(true);
    frame:Hide();

    frame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    });
    frame:SetBackdropColor(unpack(T.bg));
    frame:SetBackdropBorderColor(unpack(T.border));

    self._frame = frame;

    ---------------------------------------------------------------------------
    -- Title bar
    ---------------------------------------------------------------------------

    local titleBar = CreateFrame("Frame", config.name .. "_TitleBar", frame);
    titleBar:SetHeight(TITLE_H);
    titleBar:SetPoint("TOPLEFT");
    titleBar:SetPoint("TOPRIGHT");
    titleBar:EnableMouse(true);
    titleBar:RegisterForDrag("LeftButton");
    titleBar:SetScript("OnDragStart", function() frame:StartMoving(); end);
    titleBar:SetScript("OnDragStop", function() frame:StopMovingOrSizing(); end);

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
    if (config.icon) then
        local icon = titleBar:CreateTexture(nil, "ARTWORK");
        icon:SetSize(22, 22);
        icon:SetPoint("LEFT", 14, 0);
        icon:SetTexture(config.icon);
        self._titleIcon = icon;
    end

    -- Title
    local titleText = titleBar:CreateFontString(nil, "ARTWORK", "GameFontNormal");
    if (self._titleIcon) then
        titleText:SetPoint("LEFT", self._titleIcon, "RIGHT", 8, 0);
    else
        titleText:SetPoint("LEFT", 14, 0);
    end
    titleText:SetText(config.title or "");
    titleText:SetTextColor(unpack(T.textBright));

    -- Version (subtle)
    if (config.version and config.version ~= "") then
        local verText = titleBar:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
        verText:SetPoint("LEFT", titleText, "RIGHT", 6, -1);
        verText:SetText("v" .. config.version);
        verText:SetTextColor(unpack(T.textDim));
    end

    -- Close button
    local closeBtn = CreateFrame("Button", config.name .. "_CloseBtn", titleBar);
    closeBtn:SetSize(TITLE_H, TITLE_H);
    closeBtn:SetPoint("TOPRIGHT");

    local closeIcon = closeBtn:CreateTexture(nil, "ARTWORK");
    closeIcon:SetAtlas("common-icon-redx");
    closeIcon:SetSize(16, 16);
    closeIcon:SetPoint("CENTER");
    closeIcon:SetDesaturated(true);
    closeIcon:SetVertexColor(unpack(T.text));

    local closeHover = closeBtn:CreateTexture(nil, "HIGHLIGHT");
    closeHover:SetAllPoints();
    closeHover:SetColorTexture(0.8, 0.2, 0.2, 0.15);

    closeBtn:SetScript("OnEnter", function() closeIcon:SetDesaturated(false); closeIcon:SetVertexColor(1, 1, 1); end);
    closeBtn:SetScript("OnLeave", function() closeIcon:SetDesaturated(true); closeIcon:SetVertexColor(unpack(T.textDim)); end);
    closeBtn:SetScript("OnClick", function() frame:Hide(); end);

    ---------------------------------------------------------------------------
    -- Sidebar
    ---------------------------------------------------------------------------

    local sidebar = CreateFrame("Frame", config.name .. "_Sidebar", frame);
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

    self._sidebar = sidebar;

    -- Hook: search input (added by Search.lua)
    if (self._BuildSearchInput) then self:_BuildSearchInput(sidebar); end

    -- Sidebar scroll area (below search input, scrollable)
    local sidebarScrollName = (config.name or "LanternUX") .. "SidebarScroll";
    local sidebarScrollArea = CreateFrame("Frame", sidebarScrollName, sidebar);
    sidebarScrollArea:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 0, -(self._sidebarTopOffset or 0));
    sidebarScrollArea:SetPoint("BOTTOMRIGHT", sidebar, "BOTTOMRIGHT", -1, 0);

    local sidebarScroll = LanternUX.CreateScrollContainer(sidebarScrollArea);
    self._sidebarScroll = sidebarScroll;
    self._sidebarScrollChild = sidebarScroll.scrollChild;

    -- Keep scrollChild width in sync with the scroll area
    sidebarScrollArea:SetScript("OnSizeChanged", function(_, w)
        sidebarScroll.scrollChild:SetWidth(w);
    end);

    -- Bottom fade overlay (hints at more content below)
    -- Parented to sidebar (not scroll area) so it layers above scroll content
    local FADE_H = 16;
    local fadeName = (config.name or "LanternUX") .. "SidebarFade";
    local fade = CreateFrame("Frame", fadeName, sidebar);
    fade:SetHeight(FADE_H);
    fade:SetPoint("BOTTOMLEFT", sidebar, "BOTTOMLEFT");
    fade:SetPoint("BOTTOMRIGHT", sidebar, "BOTTOMRIGHT", -1, 0);
    fade:SetFrameStrata("DIALOG");
    fade:SetFrameLevel(sidebarScroll.scrollFrame:GetFrameLevel() + 20);

    local fadeTex = fade:CreateTexture(nil, "OVERLAY");
    fadeTex:SetAllPoints();
    fadeTex:SetTexture("Interface\\Buttons\\WHITE8x8");
    fadeTex:SetGradient("VERTICAL",
        CreateColor(T.accent[1], T.accent[2], T.accent[3], 0.35),
        CreateColor(T.accent[1], T.accent[2], T.accent[3], 0)
    );

    fade:Hide();
    self._sidebarFade = fade;

    -- Hook UpdateThumb to also toggle fade visibility with smooth alpha
    local fadeTarget = 0;
    local FADE_BLEND = 0.12;
    local FADE_SNAP = 0.02;

    local function OnUpdate_Fade(_, elapsed)
        local current = fade:GetAlpha();
        local step = math.min(1, FADE_BLEND * elapsed * 60);
        local newAlpha = current + (fadeTarget - current) * step;
        if (math.abs(newAlpha - fadeTarget) < FADE_SNAP) then
            newAlpha = fadeTarget;
            fade:SetScript("OnUpdate", nil);
            if (newAlpha <= 0) then fade:Hide(); end
        end
        fade:SetAlpha(newAlpha);
    end

    local origUpdateThumb = sidebarScroll.UpdateThumb;
    sidebarScroll.UpdateThumb = function(self_scroll)
        origUpdateThumb(self_scroll);
        local sf = self_scroll.scrollFrame;
        local maxScroll = sf:GetVerticalScrollRange();
        local atBottom = (maxScroll <= 0) or (sf:GetVerticalScroll() >= maxScroll - 1);
        if (atBottom) then
            fadeTarget = 0;
            fade:SetScript("OnUpdate", OnUpdate_Fade);
        else
            fadeTarget = 1;
            if (not fade:IsShown()) then
                fade:SetAlpha(0);
                fade:Show();
            end
            fade:SetScript("OnUpdate", OnUpdate_Fade);
        end
    end

    ---------------------------------------------------------------------------
    -- Content area
    ---------------------------------------------------------------------------

    local content = CreateFrame("Frame", config.name .. "_Content", frame);
    content:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 1, 0);
    content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1);
    content:SetClipsChildren(true);
    self._content = content;

    -- Description panel (right side, for widget hover descriptions)
    local descPanel = CreateFrame("Frame", config.name .. "_DescPanel", content);
    descPanel:SetWidth(DESC_PANEL_W);
    descPanel:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, 0);
    descPanel:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 0);

    local descBorder = descPanel:CreateTexture(nil, "ARTWORK");
    descBorder:SetWidth(1);
    descBorder:SetPoint("TOPLEFT", descPanel, "TOPLEFT");
    descBorder:SetPoint("BOTTOMLEFT", descPanel, "BOTTOMLEFT");
    descBorder:SetColorTexture(unpack(T.divider));

    local descTitle = descPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal");
    descTitle:SetPoint("TOPLEFT", descPanel, "TOPLEFT", 16, -20);
    descTitle:SetPoint("RIGHT", descPanel, "RIGHT", -16, 0);
    descTitle:SetJustifyH("LEFT");
    descTitle:SetTextColor(unpack(T.textBright));
    descPanel._title = descTitle;

    local descText = descPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
    descText:SetPoint("TOPLEFT", descTitle, "BOTTOMLEFT", 0, -8);
    descText:SetPoint("RIGHT", descPanel, "RIGHT", -16, 0);
    descText:SetJustifyH("LEFT");
    descText:SetWordWrap(true);
    descText:SetSpacing(3);
    descText:SetTextColor(unpack(T.text));
    descPanel._text = descText;

    descPanel._defaultTitle = "";
    descPanel._defaultDesc = "";
    descPanel:Hide();
    self._descPanel = descPanel;

    -- AceGUI container for AceConfig fallback pages
    if (AceGUI and AceConfigDialog) then
        local aceContainer = AceGUI:Create("SimpleGroup");
        aceContainer:SetLayout("Fill");
        aceContainer.frame:SetParent(content);
        aceContainer.frame:ClearAllPoints();
        aceContainer.frame:SetPoint("TOPLEFT", content, "TOPLEFT", 4, -4);
        aceContainer.frame:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -4, 4);
        aceContainer.frame:Hide();
        self._aceContainer = aceContainer;
    end

    -- Custom scroll container for widget-based pages
    if (LanternUX and LanternUX.CreateScrollContainer) then
        local customScroll = LanternUX.CreateScrollContainer(content);
        -- Re-anchor to leave space for description panel
        customScroll.scrollFrame:ClearAllPoints();
        customScroll.scrollFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0);
        customScroll.scrollFrame:SetPoint("BOTTOMRIGHT", descPanel, "BOTTOMLEFT", 0, 0);
        customScroll.scrollFrame:Hide();
        self._customScroll = customScroll;
    end

    ---------------------------------------------------------------------------
    -- Lifecycle
    ---------------------------------------------------------------------------

    local self_ = self;

    frame:SetScript("OnShow", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPEN or 850);
        LanternUX.descPanel = self_._descPanel;
        -- Re-render current content (widgets were released on hide)
        if (self_._activeKey) then
            local page = self_._pageMap[self_._activeKey];
            if (page and page.onShow) then page.onShow(); end
            if (page and not page.frame) then
                self_:_ShowContent(self_._activeKey);
            end
        end
    end);

    frame:SetScript("OnHide", function()
        if (self_._aceContainer) then
            self_._aceContainer:ReleaseChildren();
            self_._aceContainer.frame:Hide();
        end
        if (self_._customScroll) then
            LanternUX.ReleaseAll();
            self_._customScroll.scrollFrame:Hide();
        end
        if (LanternUX.ResetGroupStates) then
            LanternUX.ResetGroupStates();
        end
        if (self_._descPanel) then self_._descPanel:Hide(); end
        -- Hook: reset search state (added by Search.lua)
        if (self_._ResetSearchState) then self_:_ResetSearchState(); end
        PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE or 851);
        -- Notify pages of hide (e.g., CursorRing preview cleanup)
        if (self_._activeKey) then
            local page = self_._pageMap[self_._activeKey];
            if (page and page.onHide) then page.onHide(); end
        end
    end);

    -- ESC to close
    if (config.name) then
        table.insert(UISpecialFrames, config.name);
    end
end

-------------------------------------------------------------------------------
-- Factory
-------------------------------------------------------------------------------

LanternUX._PanelMixin = PanelMixin;

function LanternUX:CreatePanel(config)
    local panel = setmetatable({
        _config           = config,
        _pages            = {},
        _pageMap          = {},
        _sections         = {},
        _sectionMap       = {},
        _sidebarGroups    = {},
        _sidebarGroupMap  = {},
        _buttons          = {},
        _sidebarDropdowns = {},
        _expandedGroups   = {},
        _frame            = nil,
        _activeKey        = nil,
        _sidebarDirty     = true,
        -- Search state (managed by Search.lua via mixin hooks):
        -- _searchActive, _preSearchKey, _searchIndex, _searchIndexDirty,
        -- _searchInput, _searchDebounce, _scrollToWidget, _sidebarTopOffset
    }, { __index = PanelMixin });
    return panel;
end
