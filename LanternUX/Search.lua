local ADDON_NAME = ...;

local LanternUX = _G.LanternUX;
if (not LanternUX or not LanternUX._PanelMixin) then return; end

local T = LanternUX.Theme;
local PanelMixin = LanternUX._PanelMixin;

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local SEARCH_INPUT_H  = 24;
local SEARCH_PAD_TOP  = 8;
local SEARCH_PAD_BOT  = 6;
local SEARCH_PAD_LR   = 10;
local SEARCH_TOTAL_H  = SEARCH_PAD_TOP + SEARCH_INPUT_H + SEARCH_PAD_BOT;
local SEARCH_DEBOUNCE = 0.15;

-- Searchable widget types (have user-visible labels)
local SEARCHABLE_TYPES = {
    toggle = true, range = true, select = true,
    execute = true, input = true, color = true,
};

-------------------------------------------------------------------------------
-- Search input (created during _Build via hook)
-------------------------------------------------------------------------------

function PanelMixin:_BuildSearchInput(sidebar)
    self._sidebarTopOffset = SEARCH_TOTAL_H;

    local boxName = (self._config.name or "LanternUX") .. "SearchInput";
    local searchBox = CreateFrame("EditBox", boxName, sidebar, "BackdropTemplate");
    searchBox:SetHeight(SEARCH_INPUT_H);
    searchBox:SetPoint("TOPLEFT", sidebar, "TOPLEFT", SEARCH_PAD_LR, -SEARCH_PAD_TOP);
    searchBox:SetPoint("TOPRIGHT", sidebar, "TOPRIGHT", -SEARCH_PAD_LR - 1, -SEARCH_PAD_TOP);
    searchBox:SetAutoFocus(false);
    searchBox:SetFontObject(T.fontSmall);
    searchBox:SetTextInsets(20, 6, 0, 0);
    searchBox:SetMaxLetters(64);

    searchBox:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    });
    searchBox:SetBackdropColor(T.inputBg[1], T.inputBg[2], T.inputBg[3], T.inputBg[4]);
    searchBox:SetBackdropBorderColor(T.inputBorder[1], T.inputBorder[2], T.inputBorder[3], T.inputBorder[4]);
    searchBox:SetTextColor(unpack(T.text));

    -- Magnifying glass icon
    local searchIcon = searchBox:CreateTexture(nil, "ARTWORK");
    searchIcon:SetSize(12, 12);
    searchIcon:SetPoint("LEFT", 5, 0);
    searchIcon:SetAtlas("common-search-magnifyingglass");
    searchIcon:SetDesaturated(true);
    searchIcon:SetVertexColor(unpack(T.textDim));

    -- Placeholder text
    local placeholder = searchBox:CreateFontString(nil, "ARTWORK");
    placeholder:SetFontObject(T.fontSmall);
    placeholder:SetPoint("LEFT", 20, 0);
    placeholder:SetText("Search...");
    placeholder:SetTextColor(T.textDim[1], T.textDim[2], T.textDim[3], 0.6);

    -- Placeholder visibility
    searchBox:SetScript("OnEditFocusGained", function(self_)
        self_:SetBackdropBorderColor(T.inputFocus[1], T.inputFocus[2], T.inputFocus[3], T.inputFocus[4]);
        if (self_:GetText() == "") then placeholder:Hide(); end
    end);
    searchBox:SetScript("OnEditFocusLost", function(self_)
        self_:SetBackdropBorderColor(T.inputBorder[1], T.inputBorder[2], T.inputBorder[3], T.inputBorder[4]);
        if (self_:GetText() == "") then placeholder:Show(); end
    end);

    -- Debounced text change
    local panel = self;
    searchBox:SetScript("OnTextChanged", function(self_, userInput)
        if (not userInput) then return; end
        local text = self_:GetText();
        if (text == "") then placeholder:Show(); else placeholder:Hide(); end

        if (panel._searchDebounce) then
            panel._searchDebounce:Cancel();
        end
        panel._searchDebounce = C_Timer.NewTimer(SEARCH_DEBOUNCE, function()
            panel._searchDebounce = nil;
            panel:_OnSearchChanged(self_:GetText());
        end);
    end);

    -- ESC clears search
    searchBox:SetScript("OnEscapePressed", function(self_)
        self_:SetText("");
        self_:ClearFocus();
        placeholder:Show();
        panel:_OnSearchChanged("");
    end);

    -- Enter clears focus but keeps results
    searchBox:SetScript("OnEnterPressed", function(self_)
        self_:ClearFocus();
    end);

    self._searchInput = searchBox;
end

-------------------------------------------------------------------------------
-- Index building
-------------------------------------------------------------------------------

function PanelMixin:_OnPageAdded()
    self._searchIndexDirty = true;
end

function PanelMixin:_BuildSearchIndex()
    local index = {};

    for _, entry in ipairs(self._pages) do
        local page = entry.opts;
        if (page.widgets) then
            local pageKey = entry.key;
            local pageLabel = page.label or pageKey;

            local ok, options = pcall(page.widgets);
            if (ok and options) then
                -- depth: renderer only supports one level of groups (nested groups are skipped)
                local function walk(widgets, groupPath, groupTexts, depth)
                    for _, data in ipairs(widgets) do
                        local wType = data.type;
                        if (SEARCHABLE_TYPES[wType]) then
                            local label = data.label or "";
                            if (label ~= "") then
                                local widgetKey = (groupPath or "") .. ":" .. label;
                                table.insert(index, {
                                    pageKey    = pageKey,
                                    pageLabel  = pageLabel,
                                    label      = label,
                                    desc       = data.desc or "",
                                    groupPath  = groupPath or "",
                                    groupTexts = groupTexts and { unpack(groupTexts) } or {},
                                    widgetKey  = widgetKey,
                                });
                            end
                        elseif (wType == "group" and data.children and (depth or 0) < 1) then
                            local newGroupTexts = groupTexts and { unpack(groupTexts) } or {};
                            table.insert(newGroupTexts, data.text or "");
                            walk(data.children, data.text or "", newGroupTexts, (depth or 0) + 1);
                        end
                    end
                end

                walk(options, nil, nil, 0);
            end
        end
    end

    self._searchIndex = index;
    self._searchIndexDirty = false;
end

-------------------------------------------------------------------------------
-- Search execution
-------------------------------------------------------------------------------

function PanelMixin:_RunSearch(query)
    if (not self._searchIndex) then return {}; end

    local q = query:lower();
    local results = {};

    for _, entry in ipairs(self._searchIndex) do
        local labelMatch = entry.label:lower():find(q, 1, true);
        local descMatch = entry.desc:lower():find(q, 1, true);
        local pageMatch = entry.pageLabel:lower():find(q, 1, true);

        if (labelMatch or descMatch or pageMatch) then
            table.insert(results, entry);
        end
    end

    return results;
end

function PanelMixin:_RenderSearchResults(results)
    if (not self._customScroll) then return; end

    -- Group results by page
    local byPage = {};
    local pageOrder = {};
    for _, entry in ipairs(results) do
        if (not byPage[entry.pageKey]) then
            byPage[entry.pageKey] = { label = entry.pageLabel, items = {} };
            table.insert(pageOrder, entry.pageKey);
        end
        table.insert(byPage[entry.pageKey].items, entry);
    end

    -- Build widget options array
    local options = {};
    local self_ = self;

    if (#results == 0) then
        table.insert(options, {
            type = "label",
            text = "No matching settings found.",
            fontSize = "medium",
            color = T.textDim,
        });
    else
        for _, pageKey in ipairs(pageOrder) do
            local group = byPage[pageKey];

            table.insert(options, {
                type = "header",
                text = group.label,
            });

            for _, entry in ipairs(group.items) do
                local breadcrumb;
                if (entry.groupPath and entry.groupPath ~= "") then
                    breadcrumb = entry.pageLabel .. " > " .. entry.groupPath;
                else
                    breadcrumb = entry.pageLabel;
                end

                table.insert(options, {
                    type = "searchResult",
                    label = entry.label,
                    breadcrumb = breadcrumb,
                    desc = entry.desc,
                    onClick = function()
                        self_:_NavigateToWidget(entry);
                    end,
                });
            end
        end
    end

    -- Hide other content types, then show search results
    self:_HideAllContent();

    -- Show description panel + scroll container
    if (self._descPanel) then
        self._descPanel:Show();
        LanternUX.descPanel = self._descPanel;
    end
    self._customScroll.scrollFrame:Show();
    self._customScroll:Reset();

    LanternUX.RenderContent(self._customScroll, options, nil, "_search");
end

-------------------------------------------------------------------------------
-- Search mode transitions
-------------------------------------------------------------------------------

function PanelMixin:_OnSearchChanged(query)
    if (not query or query == "") then
        if (self._searchActive) then
            self._searchActive = false;
            self:_SetSidebarDimmed(false);
            if (self._preSearchKey) then
                local key = self._preSearchKey;
                self._preSearchKey = nil;
                self._activeKey = nil;
                self:_SelectItem(key);
            end
        end
        return;
    end

    if (not self._searchActive) then
        self._searchActive = true;
        self._preSearchKey = self._activeKey;
        self:_SetSidebarDimmed(true);
    end

    if (self._searchIndexDirty or not self._searchIndex) then
        self:_BuildSearchIndex();
    end

    local results = self:_RunSearch(query);
    self:_RenderSearchResults(results);
end

function PanelMixin:_SetSidebarDimmed(dimmed)
    local alpha = dimmed and 0.4 or 1.0;
    for _, btn in pairs(self._buttons) do
        btn:SetAlpha(alpha);
    end
    for _, btn in pairs(self._sidebarDropdowns) do
        btn:SetAlpha(alpha);
    end
    if (self._sectionHeaders) then
        for _, hdr in ipairs(self._sectionHeaders) do
            hdr:SetAlpha(alpha);
        end
    end
end

function PanelMixin:_ExitSearchOnSelect()
    if (not self._searchActive) then return; end
    self._searchActive = false;
    self._preSearchKey = nil;
    self:_SetSidebarDimmed(false);
    if (self._searchInput) then
        self._searchInput:SetText("");
        self._searchInput:ClearFocus();
    end
end

function PanelMixin:_ResetSearchState()
    if (self._searchInput) then
        self._searchInput:SetText("");
        self._searchInput:ClearFocus();
    end
    if (self._searchDebounce) then
        self._searchDebounce:Cancel();
        self._searchDebounce = nil;
    end
    self._searchActive = false;
    self._preSearchKey = nil;
    self._scrollToWidget = nil;
    self:_SetSidebarDimmed(false);
end

-------------------------------------------------------------------------------
-- Navigation (click a search result)
-------------------------------------------------------------------------------

function PanelMixin:_NavigateToWidget(entry)
    if (self._searchInput) then
        self._searchInput:SetText("");
        self._searchInput:ClearFocus();
    end

    self._searchActive = false;
    self._preSearchKey = nil;
    self:_SetSidebarDimmed(false);

    if (entry.groupTexts and #entry.groupTexts > 0) then
        LanternUX.ExpandGroups(entry.pageKey, entry.groupTexts);
    end

    self._scrollToWidget = entry.widgetKey;

    self._activeKey = nil;
    self:_SelectItem(entry.pageKey);
end

function PanelMixin:_ConsumeScrollToWidget()
    if (not self._scrollToWidget) then return; end

    local targetKey = self._scrollToWidget;
    self._scrollToWidget = nil;
    local scroll = self._customScroll;

    -- Defer 2 frames for layout to settle
    C_Timer.After(0, function()
        C_Timer.After(0, function()
            local posMap = LanternUX.widgetPositionMap;
            if (posMap and posMap[targetKey] and scroll) then
                scroll:ScrollToY(posMap[targetKey]);
            end
        end);
    end);
end
