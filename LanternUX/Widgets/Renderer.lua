local ADDON_NAME = ...;

local _W = LanternUX._W;
local T = _W.T;
local ReleaseAll = _W.ReleaseAll;
local SetDefaultDescription = _W.SetDefaultDescription;

-------------------------------------------------------------------------------
-- Layout constants (used only by the renderer)
-------------------------------------------------------------------------------

local CONTENT_PAD    = 20;
local WIDGET_GAP     = 8;
local DIVIDER_HEIGHT = 16;

-------------------------------------------------------------------------------
-- Renderer helpers
-------------------------------------------------------------------------------

-- Helper: check hidden flag
local function isHidden(data)
    if (not data.hidden) then return false; end
    if (type(data.hidden) == "function") then return data.hidden(); end
    return data.hidden;
end

-------------------------------------------------------------------------------
-- RenderContent
-------------------------------------------------------------------------------

local function RenderContent(scrollContainer, options, headerInfo, pageKey, preserveScroll)
    ReleaseAll();
    if (_W.ReleaseCards) then _W.ReleaseCards(); end
    wipe(_W.widgetPositionMap);

    _W.currentPageKey = pageKey or "";
    _W.lastRenderArgs = { scrollContainer = scrollContainer, options = options, headerInfo = headerInfo, pageKey = pageKey };

    local parent = scrollContainer.scrollChild;
    local scrollWidth = scrollContainer.scrollFrame:GetWidth();
    local contentWidth = scrollWidth - CONTENT_PAD * 2 - 10;  -- 10 for scrollbar space
    parent:SetWidth(scrollWidth);

    local y = -CONTENT_PAD;

    -- Reset description panel default
    SetDefaultDescription("", "");

    -- Content header (title + description + divider)
    if (headerInfo and headerInfo.title) then
        local title = headerInfo.title;
        local desc = headerInfo.description;

        -- Title
        local labelFactory = _W.factories.label;
        local titleW = labelFactory.create(parent);
        labelFactory.setup(titleW, parent, {
            text = title,
            fontSize = "large",
            color = T.textBright,
        }, contentWidth);
        titleW.frame:ClearAllPoints();
        titleW.frame:SetPoint("TOPLEFT", parent, "TOPLEFT", CONTENT_PAD, y);
        y = y - (titleW.height or 20) - 2;

        -- Description
        if (desc) then
            local descW = labelFactory.create(parent);
            labelFactory.setup(descW, parent, {
                text = desc,
                fontSize = "small",
                color = T.textDim,
            }, contentWidth);
            descW.frame:ClearAllPoints();
            descW.frame:SetPoint("TOPLEFT", parent, "TOPLEFT", CONTENT_PAD, y);
            y = y - (descW.height or 14) - 2;
        end

        -- Divider after header
        local dividerFactory = _W.factories.divider;
        local divW = dividerFactory.create(parent);
        dividerFactory.setup(divW, parent, {}, contentWidth);
        divW.frame:ClearAllPoints();
        divW.frame:SetPoint("TOPLEFT", parent, "TOPLEFT", CONTENT_PAD, y);
        y = y - (divW.height or DIVIDER_HEIGHT) - 8;
    end

    -- Render widgets
    local GROUP_INDENT = 14;
    local SECTION_MARGIN = 16;
    local widgetCount = 0;

    local function renderWidget(data, indent, groupPath)
        local factory = _W.factories[data.type];
        if (not factory or isHidden(data)) then return; end

        -- Extra top margin before section widgets (header, group) when not the first widget
        if (widgetCount > 0 and (data.type == "header" or data.type == "group")) then
            y = y - SECTION_MARGIN;
        end

        local xOffset = CONTENT_PAD + (indent or 0);
        local childWidth = contentWidth - (indent or 0);

        local w = factory.create(parent);
        factory.setup(w, parent, data, childWidth);
        w.frame:ClearAllPoints();
        w.frame:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, y);

        -- Track widget position for scroll-to-widget
        local widgetLabel = data.label or data.text or "";
        if (widgetLabel ~= "") then
            local widgetKey = (groupPath or "") .. ":" .. widgetLabel;
            _W.widgetPositionMap[widgetKey] = math.abs(y);
        end

        y = y - (w.height or 20) - WIDGET_GAP;
        widgetCount = widgetCount + 1;

        -- Group widgets need a re-render callback for expand/collapse
        if (data.type == "group") then
            w._reRender = function()
                local args = _W.lastRenderArgs;
                if (args.scrollContainer) then
                    RenderContent(args.scrollContainer, args.options, args.headerInfo, args.pageKey, true);
                end
            end;

            -- If expanded, render children inline (indented) with card background
            if (w._expanded and data.children) then
                local cardStartY = y;
                local childGroupPath = (data.text or "");
                for _, childData in ipairs(data.children) do
                    if (childData.type ~= "group") then
                        renderWidget(childData, GROUP_INDENT, childGroupPath);
                    end
                end
                -- Create card background behind children
                local cardH = math.abs(cardStartY - y);
                if (cardH > 0 and _W.AcquireCard) then
                    local cardPad = _W.CARD_PAD or 10;
                    local cardTopPad = 6;
                    local cardBotPad = 4;
                    local card = _W.AcquireCard(parent);
                    card.frame:ClearAllPoints();
                    card.frame:SetPoint("TOPLEFT", parent, "TOPLEFT", CONTENT_PAD + GROUP_INDENT - cardPad, cardStartY + cardTopPad);
                    card.frame:SetSize(contentWidth - GROUP_INDENT + cardPad * 2, cardH + cardTopPad + cardBotPad);
                    card.frame:SetFrameLevel(parent:GetFrameLevel());
                end
            end
        end
    end

    -- Render each option entry
    for _, data in ipairs(options) do
        renderWidget(data, nil, nil);
    end

    -- Set total content height
    local totalHeight = math.abs(y) + CONTENT_PAD;
    if (preserveScroll) then
        scrollContainer:UpdateContentHeight(totalHeight);
    else
        scrollContainer:SetContentHeight(totalHeight);
    end
end

-------------------------------------------------------------------------------
-- Group state management
-------------------------------------------------------------------------------

local function ResetGroupStates()
    wipe(_W.groupStates);
end

local function ExpandGroups(pageKey, groupTexts)
    for _, text in ipairs(groupTexts) do
        _W.groupStates[(pageKey or "") .. ":" .. text] = true;
    end
end

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------

LanternUX.RenderContent = RenderContent;
LanternUX.ReleaseAll = ReleaseAll;
LanternUX.ResetGroupStates = ResetGroupStates;
LanternUX.ExpandGroups = ExpandGroups;
LanternUX.widgetPositionMap = _W.widgetPositionMap;
