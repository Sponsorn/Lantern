local ADDON_NAME = ...;
local Lantern = _G.Lantern;
if (not Lantern) then return; end

-------------------------------------------------------------------------------
-- Theme (shared reference from SettingsPanel)
-------------------------------------------------------------------------------

local T = {
    -- Core
    bg           = { 0.06, 0.06, 0.07, 0.95 },
    border       = { 0.18, 0.18, 0.20, 1.0 },
    text         = { 0.72, 0.72, 0.72, 1.0 },
    textBright   = { 1.0,  1.0,  1.0,  1.0 },
    textDim      = { 0.40, 0.40, 0.42, 1.0 },
    sectionLabel = { 0.42, 0.42, 0.45, 1.0 },
    accent       = { 0.88, 0.56, 0.18, 1.0 },
    accentDim    = { 0.88, 0.56, 0.18, 0.40 },
    hover        = { 1.0,  1.0,  1.0,  0.04 },
    divider      = { 0.20, 0.20, 0.22, 0.5 },
    -- Toggle/checkbox
    checkBorder  = { 0.35, 0.35, 0.38, 1.0 },
    checkInner   = { 0.10, 0.10, 0.12, 1.0 },
    checkHover   = { 0.42, 0.42, 0.45, 1.0 },
    -- Disabled
    disabled     = { 0.30, 0.30, 0.30, 1.0 },
    disabledText = { 0.40, 0.40, 0.40, 1.0 },
    -- Panel shell
    sidebar      = { 0.09, 0.09, 0.10, 1.0 },
    titleBar     = { 0.09, 0.09, 0.10, 1.0 },
    selected     = { 0.88, 0.56, 0.18, 0.10 },
    accentBar    = { 0.88, 0.56, 0.18, 0.80 },
    splashText   = { 0.60, 0.60, 0.60, 1.0 },
    enabled      = { 0.40, 0.67, 0.40, 1.0 },
    disabledDot  = { 0.67, 0.40, 0.40, 1.0 },
    -- Input/range
    inputBg      = { 0.10, 0.10, 0.12, 1.0 },
    inputBorder  = { 0.28, 0.28, 0.30, 1.0 },
    inputFocus   = { 0.88, 0.56, 0.18, 0.60 },
    -- Slider
    trackBg      = { 0.20, 0.20, 0.22, 1.0 },
    thumbBg      = { 0.88, 0.56, 0.18, 1.0 },
    thumbHover   = { 1.0,  0.70, 0.30, 1.0 },
    -- Button
    buttonBg     = { 0.14, 0.14, 0.16, 1.0 },
    buttonBorder = { 0.30, 0.30, 0.32, 1.0 },
    buttonHover  = { 0.20, 0.20, 0.22, 1.0 },
    buttonText   = { 0.80, 0.80, 0.80, 1.0 },
    -- Dropdown
    dropdownBg   = { 0.08, 0.08, 0.10, 0.98 },
    dropdownItem = { 1.0,  1.0,  1.0,  0.06 },
};

-------------------------------------------------------------------------------
-- Layout constants
-------------------------------------------------------------------------------

local CONTENT_PAD    = 20;
local WIDGET_GAP     = 6;
local TOGGLE_SIZE    = 16;
local TOGGLE_PAD     = 8;   -- gap between checkbox and label
local HEADER_HEIGHT  = 28;
local DIVIDER_HEIGHT = 16;
local DESC_PAD_BOT   = 4;

-------------------------------------------------------------------------------
-- Widget pools
-------------------------------------------------------------------------------

local pools = {};

local function AcquireWidget(widgetType, parent)
    pools[widgetType] = pools[widgetType] or {};
    local pool = pools[widgetType];

    for _, w in ipairs(pool) do
        if (not w._inUse) then
            w._inUse = true;
            w.frame:SetParent(parent);
            w.frame:Show();
            return w;
        end
    end

    return nil;  -- caller must create
end

local function ReleaseAll()
    for _, pool in pairs(pools) do
        for _, w in ipairs(pool) do
            w._inUse = false;
            w.frame:Hide();
            w.frame:ClearAllPoints();
        end
    end
end

local function RegisterWidget(widgetType, widget)
    pools[widgetType] = pools[widgetType] or {};
    widget._inUse = true;
    table.insert(pools[widgetType], widget);
end

-------------------------------------------------------------------------------
-- Toggle refresh (re-evaluates disabled + checked state on all active toggles)
-------------------------------------------------------------------------------

local function RefreshActiveToggles()
    for _, w in ipairs(pools["toggle"] or {}) do
        if (w._inUse) then
            -- Re-evaluate checked state
            if (w._getFn) then
                w._checked = w._getFn();
                if (w._checked) then w._mark:Show(); else w._mark:Hide(); end
            end

            -- Re-evaluate disabled state
            local disabled = false;
            if (w._disabledFn) then
                if (type(w._disabledFn) == "function") then
                    disabled = w._disabledFn();
                else
                    disabled = w._disabledFn;
                end
            end
            w._disabled = disabled;

            if (disabled) then
                w._boxBorder:SetColorTexture(unpack(T.disabled));
                w._boxInner:SetColorTexture(0.08, 0.08, 0.08, 1.0);
                w._mark:SetColorTexture(unpack(T.accentDim));
                w._label:SetTextColor(unpack(T.disabledText));
                if (w._desc and w._desc:IsShown()) then w._desc:SetTextColor(unpack(T.disabled)); end
            else
                w._boxBorder:SetColorTexture(unpack(T.checkBorder));
                w._boxInner:SetColorTexture(unpack(T.checkInner));
                w._mark:SetColorTexture(unpack(T.accent));
                w._label:SetTextColor(unpack(T.text));
                if (w._desc and w._desc:IsShown()) then w._desc:SetTextColor(unpack(T.textDim)); end
            end
        end
    end
end

-------------------------------------------------------------------------------
-- Widget: Toggle
-------------------------------------------------------------------------------

local function CreateToggle(parent)
    local w = AcquireWidget("toggle", parent);
    if (w) then return w; end

    w = {};
    local frame = CreateFrame("Button", nil, parent);
    frame:SetHeight(TOGGLE_SIZE + 4);
    w.frame = frame;

    -- Checkbox box
    local box = CreateFrame("Frame", nil, frame);
    box:SetSize(TOGGLE_SIZE, TOGGLE_SIZE);
    box:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -2);

    local boxBorder = box:CreateTexture(nil, "BORDER");
    boxBorder:SetAllPoints();
    boxBorder:SetColorTexture(unpack(T.checkBorder));
    w._boxBorder = boxBorder;

    local boxInner = box:CreateTexture(nil, "BACKGROUND");
    boxInner:SetPoint("TOPLEFT", 1, -1);
    boxInner:SetPoint("BOTTOMRIGHT", -1, 1);
    boxInner:SetColorTexture(unpack(T.checkInner));
    w._boxInner = boxInner;

    -- Checkmark (filled square when checked)
    local mark = box:CreateTexture(nil, "ARTWORK");
    mark:SetPoint("TOPLEFT", 3, -3);
    mark:SetPoint("BOTTOMRIGHT", -3, 3);
    mark:SetColorTexture(unpack(T.accent));
    mark:Hide();
    w._mark = mark;

    w._box = box;

    -- Label
    local label = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
    label:SetPoint("LEFT", box, "RIGHT", TOGGLE_PAD, 0);
    label:SetJustifyH("LEFT");
    label:SetTextColor(unpack(T.text));
    w._label = label;

    -- Description (below label, optional)
    local desc = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
    desc:SetPoint("TOPLEFT", box, "BOTTOMLEFT", 0, -4);
    desc:SetJustifyH("LEFT");
    desc:SetWordWrap(true);
    desc:SetTextColor(unpack(T.textDim));
    desc:Hide();
    w._desc = desc;

    -- State
    w._checked = false;
    w._disabled = false;

    -- Hover
    frame:SetScript("OnEnter", function()
        if (not w._disabled) then
            boxBorder:SetColorTexture(unpack(T.checkHover));
        end
    end);
    frame:SetScript("OnLeave", function()
        if (not w._disabled) then
            boxBorder:SetColorTexture(unpack(T.checkBorder));
        end
    end);

    -- Click
    frame:SetScript("OnClick", function()
        if (w._disabled) then return; end
        w._checked = not w._checked;
        if (w._checked) then
            w._mark:Show();
        else
            w._mark:Hide();
        end
        if (w._onSet) then
            w._onSet(w._checked);
        end
        -- Refresh all toggles so disabled states update immediately
        C_Timer.After(0, RefreshActiveToggles);
    end);

    RegisterWidget("toggle", w);
    return w;
end

local function SetupToggle(w, parent, data, contentWidth)
    w.frame:SetParent(parent);
    w.frame:SetWidth(contentWidth);

    -- Label
    w._label:SetText(data.label or "");

    -- Description
    if (data.desc) then
        w._desc:SetText(data.desc);
        w._desc:SetWidth(contentWidth - TOGGLE_SIZE - TOGGLE_PAD);
        w._desc:Show();
        -- Calculate height: toggle row + desc text + padding
        local descHeight = w._desc:GetStringHeight() or 14;
        w.frame:SetHeight(TOGGLE_SIZE + 4 + descHeight + 4);
        w.height = TOGGLE_SIZE + 4 + descHeight + 4;
    else
        w._desc:Hide();
        w.frame:SetHeight(TOGGLE_SIZE + 4);
        w.height = TOGGLE_SIZE + 4;
    end

    -- Checked state
    local checked = false;
    if (data.get) then
        checked = data.get();
    end
    w._checked = checked;
    if (checked) then w._mark:Show(); else w._mark:Hide(); end

    -- Store callbacks for refresh
    w._getFn = data.get;
    w._onSet = data.set;
    w._disabledFn = data.disabled;

    -- Disabled state
    local disabled = false;
    if (data.disabled) then
        if (type(data.disabled) == "function") then
            disabled = data.disabled();
        else
            disabled = data.disabled;
        end
    end
    w._disabled = disabled;

    if (disabled) then
        w._boxBorder:SetColorTexture(unpack(T.disabled));
        w._boxInner:SetColorTexture(0.08, 0.08, 0.08, 1.0);
        w._mark:SetColorTexture(unpack(T.accentDim));
        w._label:SetTextColor(unpack(T.disabledText));
        if (w._desc) then w._desc:SetTextColor(unpack(T.disabled)); end
    else
        w._boxBorder:SetColorTexture(unpack(T.checkBorder));
        w._boxInner:SetColorTexture(unpack(T.checkInner));
        w._mark:SetColorTexture(unpack(T.accent));
        w._label:SetTextColor(unpack(T.text));
        if (w._desc) then w._desc:SetTextColor(unpack(T.textDim)); end
    end

    return w;
end

-------------------------------------------------------------------------------
-- Widget: Label / Description
-------------------------------------------------------------------------------

local function CreateLabel(parent)
    local w = AcquireWidget("label", parent);
    if (w) then return w; end

    w = {};
    local frame = CreateFrame("Frame", nil, parent);
    frame:SetHeight(18);
    w.frame = frame;

    local text = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
    text:SetPoint("TOPLEFT");
    text:SetJustifyH("LEFT");
    text:SetWordWrap(true);
    text:SetTextColor(unpack(T.text));
    w._text = text;

    RegisterWidget("label", w);
    return w;
end

local function SetupLabel(w, parent, data, contentWidth)
    w.frame:SetParent(parent);
    w.frame:SetWidth(contentWidth);

    local fontSize = data.fontSize or "medium";
    if (fontSize == "small") then
        w._text:SetFontObject("GameFontHighlightSmall");
    elseif (fontSize == "large") then
        w._text:SetFontObject("GameFontNormalLarge");
    else
        w._text:SetFontObject("GameFontHighlight");
    end

    w._text:SetWidth(contentWidth);
    w._text:SetText(data.text or "");
    w._text:SetTextColor(unpack(data.color or T.text));

    local textHeight = w._text:GetStringHeight() or 14;
    w.frame:SetHeight(textHeight + DESC_PAD_BOT);
    w.height = textHeight + DESC_PAD_BOT;

    return w;
end

-------------------------------------------------------------------------------
-- Widget: Header
-------------------------------------------------------------------------------

local function CreateHeader(parent)
    local w = AcquireWidget("header", parent);
    if (w) then return w; end

    w = {};
    local frame = CreateFrame("Frame", nil, parent);
    frame:SetHeight(HEADER_HEIGHT);
    w.frame = frame;

    local text = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
    text:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 6);
    text:SetJustifyH("LEFT");
    text:SetTextColor(unpack(T.textBright));
    w._text = text;

    local line = frame:CreateTexture(nil, "ARTWORK");
    line:SetHeight(1);
    line:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0);
    line:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0);
    line:SetColorTexture(unpack(T.divider));
    w._line = line;

    w.height = HEADER_HEIGHT;

    RegisterWidget("header", w);
    return w;
end

local function SetupHeader(w, parent, data, contentWidth)
    w.frame:SetParent(parent);
    w.frame:SetWidth(contentWidth);
    w._text:SetText(data.text or "");
    return w;
end

-------------------------------------------------------------------------------
-- Widget: Divider
-------------------------------------------------------------------------------

local function CreateDivider(parent)
    local w = AcquireWidget("divider", parent);
    if (w) then return w; end

    w = {};
    local frame = CreateFrame("Frame", nil, parent);
    frame:SetHeight(DIVIDER_HEIGHT);
    w.frame = frame;

    local line = frame:CreateTexture(nil, "ARTWORK");
    line:SetHeight(1);
    line:SetPoint("LEFT", frame, "LEFT", 0, 0);
    line:SetPoint("RIGHT", frame, "RIGHT", 0, 0);
    line:SetColorTexture(unpack(T.divider));
    w._line = line;

    w.height = DIVIDER_HEIGHT;

    RegisterWidget("divider", w);
    return w;
end

local function SetupDivider(w, parent, data, contentWidth)
    w.frame:SetParent(parent);
    w.frame:SetWidth(contentWidth);
    return w;
end

-------------------------------------------------------------------------------
-- Scroll container
-------------------------------------------------------------------------------

local function CreateScrollContainer(parent)
    local container = {};

    local scrollFrame = CreateFrame("ScrollFrame", nil, parent);
    scrollFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0);
    scrollFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0);
    scrollFrame:EnableMouseWheel(true);

    local scrollChild = CreateFrame("Frame", nil, scrollFrame);
    scrollChild:SetWidth(1);  -- set properly on render
    scrollFrame:SetScrollChild(scrollChild);

    -- Mouse wheel scrolling
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll();
        local maxScroll = self:GetVerticalScrollRange();
        local step = 40;
        local newScroll = current - (delta * step);
        newScroll = math.max(0, math.min(newScroll, maxScroll));
        self:SetVerticalScroll(newScroll);
        -- Update scrollbar thumb
        if (container.UpdateThumb) then
            container:UpdateThumb();
        end
    end);

    -- Scrollbar track
    local track = CreateFrame("Frame", nil, scrollFrame);
    track:SetWidth(4);
    track:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", -2, -2);
    track:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", -2, 2);
    local trackBg = track:CreateTexture(nil, "BACKGROUND");
    trackBg:SetAllPoints();
    trackBg:SetColorTexture(0.14, 0.14, 0.16, 0.3);
    track:Hide();

    -- Scrollbar thumb
    local thumb = CreateFrame("Frame", nil, track);
    thumb:SetWidth(4);
    local thumbBg = thumb:CreateTexture(nil, "ARTWORK");
    thumbBg:SetAllPoints();
    thumbBg:SetColorTexture(0.40, 0.40, 0.44, 0.6);
    thumb:Hide();

    container.scrollFrame = scrollFrame;
    container.scrollChild = scrollChild;
    container.track = track;
    container.thumb = thumb;

    function container:UpdateThumb()
        local visibleHeight = self.scrollFrame:GetHeight();
        local contentHeight = self.scrollChild:GetHeight();

        if (contentHeight <= visibleHeight or contentHeight <= 0) then
            self.track:Hide();
            self.thumb:Hide();
            return;
        end

        self.track:Show();
        self.thumb:Show();

        local trackHeight = self.track:GetHeight();
        local thumbHeight = math.max(20, (visibleHeight / contentHeight) * trackHeight);
        self.thumb:SetHeight(thumbHeight);

        local scrollRange = self.scrollFrame:GetVerticalScrollRange();
        local currentScroll = self.scrollFrame:GetVerticalScroll();
        local scrollRatio = (scrollRange > 0) and (currentScroll / scrollRange) or 0;
        local thumbOffset = scrollRatio * (trackHeight - thumbHeight);

        self.thumb:ClearAllPoints();
        self.thumb:SetPoint("TOPLEFT", self.track, "TOPLEFT", 0, -thumbOffset);
    end

    function container:SetContentHeight(height)
        self.scrollChild:SetHeight(height);
        self.scrollFrame:SetVerticalScroll(0);
        -- Defer thumb update to next frame (dimensions need to settle)
        C_Timer.After(0, function()
            self:UpdateThumb();
        end);
    end

    function container:Reset()
        self.scrollFrame:SetVerticalScroll(0);
        self.track:Hide();
        self.thumb:Hide();
    end

    return container;
end

-------------------------------------------------------------------------------
-- Content renderer
-------------------------------------------------------------------------------

local widgetFactories = {
    toggle  = { create = CreateToggle,  setup = SetupToggle },
    label   = { create = CreateLabel,   setup = SetupLabel },
    description = { create = CreateLabel, setup = SetupLabel },
    header  = { create = CreateHeader,  setup = SetupHeader },
    divider = { create = CreateDivider, setup = SetupDivider },
};

local function RenderContent(scrollContainer, options, moduleName)
    ReleaseAll();

    local parent = scrollContainer.scrollChild;
    local scrollWidth = scrollContainer.scrollFrame:GetWidth();
    local contentWidth = scrollWidth - CONTENT_PAD * 2 - 10;  -- 10 for scrollbar space
    parent:SetWidth(scrollWidth);

    local y = -CONTENT_PAD;

    -- Module header (automatic for all modules)
    if (moduleName) then
        local mod = Lantern.modules[moduleName];
        if (mod) then
            local title = (mod.opts and mod.opts.title) or moduleName;
            local desc = mod.opts and mod.opts.desc;

            -- Title
            local titleW = CreateLabel(parent);
            SetupLabel(titleW, parent, {
                text = title,
                fontSize = "large",
                color = T.textBright,
            }, contentWidth);
            titleW.frame:ClearAllPoints();
            titleW.frame:SetPoint("TOPLEFT", parent, "TOPLEFT", CONTENT_PAD, y);
            y = y - (titleW.height or 20) - 2;

            -- Description
            if (desc) then
                local descW = CreateLabel(parent);
                SetupLabel(descW, parent, {
                    text = desc,
                    fontSize = "small",
                    color = T.textDim,
                }, contentWidth);
                descW.frame:ClearAllPoints();
                descW.frame:SetPoint("TOPLEFT", parent, "TOPLEFT", CONTENT_PAD, y);
                y = y - (descW.height or 14) - 2;
            end

            -- Divider after header
            local divW = CreateDivider(parent);
            SetupDivider(divW, parent, {}, contentWidth);
            divW.frame:ClearAllPoints();
            divW.frame:SetPoint("TOPLEFT", parent, "TOPLEFT", CONTENT_PAD, y);
            y = y - (divW.height or DIVIDER_HEIGHT);
        end
    end

    -- Render each option entry
    for _, data in ipairs(options) do
        local widgetType = data.type;
        local factory = widgetFactories[widgetType];

        if (factory) then
            -- Handle hidden
            local hidden = false;
            if (data.hidden) then
                if (type(data.hidden) == "function") then
                    hidden = data.hidden();
                else
                    hidden = data.hidden;
                end
            end

            if (not hidden) then
                local w = factory.create(parent);
                factory.setup(w, parent, data, contentWidth);
                w.frame:ClearAllPoints();
                w.frame:SetPoint("TOPLEFT", parent, "TOPLEFT", CONTENT_PAD, y);
                y = y - (w.height or 20) - WIDGET_GAP;
            end
        end
    end

    -- Set total content height
    local totalHeight = math.abs(y) + CONTENT_PAD;
    scrollContainer:SetContentHeight(totalHeight);
end

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------

-- Expose for SettingsPanel to use
_G.LanternUX = _G.LanternUX or {};
LanternUX.RenderContent = RenderContent;
LanternUX.ReleaseAll = ReleaseAll;
LanternUX.CreateScrollContainer = CreateScrollContainer;
LanternUX.Theme = T;
