local ADDON_NAME, NS = ...;
local ST = NS.SpellTracker;
if (not ST) then return; end

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local FONT = "Fonts\\FRIZQT__.TTF";
local FRAME_WIDTH = 340;
local FRAME_NAME = "LanternMythicTrackerOptions";

-- Colors
local COLOR_BG          = { 0.08, 0.08, 0.08, 0.95 };
local COLOR_SECTION     = { 0.12, 0.12, 0.12, 1.0 };
local COLOR_ACCENT      = { 0.9, 0.77, 0.1 };
local COLOR_LABEL       = { 0.85, 0.85, 0.85 };
local COLOR_MUTED       = { 0.55, 0.55, 0.55 };
local COLOR_BTN         = { 0.18, 0.18, 0.18, 1.0 };
local COLOR_BTN_HOVER   = { 0.25, 0.25, 0.25, 1.0 };

-- Layout / filter / attach mode options
local LAYOUT_OPTIONS = { "bar", "icon" };
local LAYOUT_LABELS  = { bar = "Bar", icon = "Icon Grid" };
local FILTER_OPTIONS = { "all", "hide_ready", "active_only" };
local FILTER_LABELS  = { all = "Show All", hide_ready = "Hide Ready", active_only = "Active Only" };
local ATTACH_MODE_OPTIONS  = { "free", "party" };
local ATTACH_MODE_LABELS   = { free = "Free Floating", party = "Party Frames" };
local ATTACH_ANCHOR_OPTIONS = { "RIGHT", "LEFT", "BOTTOM" };
local ATTACH_ANCHOR_LABELS  = { RIGHT = "Right", LEFT = "Left", BOTTOM = "Bottom" };

local PADDING = 12;
local ROW_HEIGHT = 26;
local SLIDER_HEIGHT = 20;

-------------------------------------------------------------------------------
-- Widget Helpers (file-local factories)
-------------------------------------------------------------------------------

local function CreateSectionHeader(parent, text, yOff)
    local holder = CreateFrame("Frame", nil, parent);
    holder:SetPoint("TOPLEFT", PADDING, yOff);
    holder:SetPoint("TOPRIGHT", -PADDING, yOff);
    holder:SetHeight(24);

    local bg = holder:CreateTexture(nil, "BACKGROUND");
    bg:SetAllPoints();
    bg:SetTexture("Interface\\BUTTONS\\WHITE8X8");
    bg:SetVertexColor(unpack(COLOR_SECTION));

    local label = holder:CreateFontString(nil, "OVERLAY");
    label:SetFont(FONT, 13, "OUTLINE");
    label:SetPoint("LEFT", 8, 0);
    label:SetTextColor(unpack(COLOR_ACCENT));
    label:SetText(text);

    return holder, yOff - 28;
end

local function CreateCheckbox(parent, xOff, yOff, text, checked, onChange)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate");
    cb:SetPoint("TOPLEFT", xOff, yOff);
    cb:SetSize(22, 22);
    cb:SetChecked(checked);

    local label = cb:CreateFontString(nil, "OVERLAY");
    label:SetFont(FONT, 12);
    label:SetPoint("LEFT", cb, "RIGHT", 4, 0);
    label:SetTextColor(unpack(COLOR_LABEL));
    label:SetText(text);
    cb.label = label;

    cb:SetScript("OnClick", function(self)
        local val = self:GetChecked();
        if (onChange) then onChange(val); end
    end);

    return cb;
end

local function CreateCycleButton(parent, xOff, yOff, labelText, options, labels, currentValue, onChange)
    local holder = CreateFrame("Frame", nil, parent);
    holder:SetPoint("TOPLEFT", xOff, yOff);
    holder:SetSize(FRAME_WIDTH - PADDING * 2 - xOff + PADDING, ROW_HEIGHT);

    local label = holder:CreateFontString(nil, "OVERLAY");
    label:SetFont(FONT, 11);
    label:SetPoint("LEFT", 0, 0);
    label:SetTextColor(unpack(COLOR_MUTED));
    label:SetText(labelText);

    local btn = CreateFrame("Button", nil, holder);
    btn:SetPoint("LEFT", 70, 0);
    btn:SetSize(140, ROW_HEIGHT - 2);

    local btnBg = btn:CreateTexture(nil, "BACKGROUND");
    btnBg:SetAllPoints();
    btnBg:SetTexture("Interface\\BUTTONS\\WHITE8X8");
    btnBg:SetVertexColor(unpack(COLOR_BTN));

    local btnText = btn:CreateFontString(nil, "OVERLAY");
    btnText:SetFont(FONT, 11);
    btnText:SetPoint("CENTER", 0, 0);
    btnText:SetTextColor(unpack(COLOR_LABEL));
    btnText:SetText(labels[currentValue] or currentValue);
    btn.text = btnText;

    btn:SetScript("OnEnter", function() btnBg:SetVertexColor(unpack(COLOR_BTN_HOVER)); end);
    btn:SetScript("OnLeave", function() btnBg:SetVertexColor(unpack(COLOR_BTN)); end);

    btn:SetScript("OnClick", function()
        local currentIdx = 1;
        for i, opt in ipairs(options) do
            if (opt == currentValue) then currentIdx = i; break; end
        end
        local nextIdx = (currentIdx % #options) + 1;
        currentValue = options[nextIdx];
        btnText:SetText(labels[currentValue] or currentValue);
        if (onChange) then onChange(currentValue); end
    end);

    return holder;
end

local function CreateSlider(parent, xOff, yOff, labelText, minVal, maxVal, step, currentValue, onChange)
    -- Wrapper frame to contain everything cleanly
    local holder = CreateFrame("Frame", nil, parent);
    holder:SetPoint("TOPLEFT", xOff, yOff);
    holder:SetSize(FRAME_WIDTH - PADDING * 2 - xOff + PADDING, 40);

    local label = holder:CreateFontString(nil, "OVERLAY");
    label:SetFont(FONT, 11);
    label:SetPoint("TOPLEFT", 0, 0);
    label:SetTextColor(unpack(COLOR_MUTED));
    label:SetText(labelText);

    local slider = CreateFrame("Slider", nil, holder, "OptionsSliderTemplate");
    slider:SetPoint("TOPLEFT", 0, -16);
    slider:SetSize(180, SLIDER_HEIGHT);
    slider:SetMinMaxValues(minVal, maxVal);
    slider:SetValueStep(step or 1);
    slider:SetObeyStepOnDrag(true);
    slider:SetValue(currentValue);

    -- Hide built-in template labels (they overlap with our layout)
    slider.Text:SetText("");
    slider.Text:Hide();
    slider.Low:SetText("");
    slider.Low:Hide();
    slider.High:SetText("");
    slider.High:Hide();

    -- Our own value label
    local valueText = holder:CreateFontString(nil, "OVERLAY");
    valueText:SetFont(FONT, 11);
    valueText:SetPoint("LEFT", slider, "RIGHT", 8, 0);
    valueText:SetTextColor(unpack(COLOR_LABEL));
    valueText:SetText(math.floor(currentValue));
    holder.valueText = valueText;

    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5);
        valueText:SetText(value);
        if (onChange) then onChange(value); end
    end);

    return holder;
end

local function CreateActionButton(parent, xOff, yOff, text, width, onClick)
    local btn = CreateFrame("Button", nil, parent);
    btn:SetPoint("TOPLEFT", xOff, yOff);
    btn:SetSize(width, ROW_HEIGHT);

    local bg = btn:CreateTexture(nil, "BACKGROUND");
    bg:SetAllPoints();
    bg:SetTexture("Interface\\BUTTONS\\WHITE8X8");
    bg:SetVertexColor(unpack(COLOR_BTN));

    local btnText = btn:CreateFontString(nil, "OVERLAY");
    btnText:SetFont(FONT, 11);
    btnText:SetPoint("CENTER", 0, 0);
    btnText:SetTextColor(unpack(COLOR_LABEL));
    btnText:SetText(text);

    btn:SetScript("OnEnter", function() bg:SetVertexColor(unpack(COLOR_BTN_HOVER)); end);
    btn:SetScript("OnLeave", function() bg:SetVertexColor(unpack(COLOR_BTN)); end);
    btn:SetScript("OnClick", onClick);

    return btn;
end

-------------------------------------------------------------------------------
-- Options Frame
-------------------------------------------------------------------------------

local _optionsFrame = nil;
local _contentChildren = {};

local function DestroyContent()
    for _, child in ipairs(_contentChildren) do
        if (child.UnregisterAllEvents) then child:UnregisterAllEvents(); end
        child:Hide();
        child:SetParent(nil);
    end
    wipe(_contentChildren);
end

local function Track(widget)
    table.insert(_contentChildren, widget);
    return widget;
end

local function BuildCategorySection(content, catKey, yOff)
    local cat = ST:GetCategory(catKey);
    if (not cat) then return yOff; end
    local catDB = ST:GetCategoryDB(catKey);
    local label = cat.label or catKey;
    local defaultLayout = cat.defaultLayout or "bar";
    local defaultFilter = cat.defaultFilter or "all";

    local layout = catDB.layout or defaultLayout;
    local filter = catDB.filter or defaultFilter;

    -- Helper to destroy display frame and refresh (needed after layout type change)
    local function DestroyAndRefresh()
        local display = ST.displayFrames[catKey];
        if (display) then
            if (display.frame) then display.frame:Hide(); display.frame:SetParent(nil); end
            ST.displayFrames[catKey] = nil;
        end
        if (ST.HideAttachedContainers) then
            ST:HideAttachedContainers(catKey);
        end
        ST:RefreshDisplay();
    end

    -- Section header
    local header;
    header, yOff = CreateSectionHeader(content, label, yOff);
    Track(header);

    -- Enable
    Track(CreateCheckbox(content, PADDING + 4, yOff, "Enable", catDB.enabled, function(val)
        catDB.enabled = val;
        cat.enabled = val;
        ST:RefreshDisplay();
    end));
    yOff = yOff - ROW_HEIGHT;

    -- Layout cycle
    Track(CreateCycleButton(content, PADDING + 4, yOff, "Layout", LAYOUT_OPTIONS, LAYOUT_LABELS, layout, function(val)
        catDB.layout = val;
        DestroyAndRefresh();
        -- Rebuild settings frame to show/hide layout-specific controls
        if (_optionsFrame and _optionsFrame:IsShown()) then
            _optionsFrame:GetScript("OnShow")(_optionsFrame);
        end
    end));
    yOff = yOff - ROW_HEIGHT;

    -- Filter cycle
    Track(CreateCycleButton(content, PADDING + 4, yOff, "Filter", FILTER_OPTIONS, FILTER_LABELS, filter, function(val)
        catDB.filter = val;
        ST:RefreshDisplay();
    end));
    yOff = yOff - ROW_HEIGHT;

    -- Attach Mode cycle
    local attachMode = catDB.attachMode or "free";
    Track(CreateCycleButton(content, PADDING + 4, yOff, "Display", ATTACH_MODE_OPTIONS, ATTACH_MODE_LABELS, attachMode, function(val)
        catDB.attachMode = val;
        DestroyAndRefresh();
        -- Rebuild settings frame to show/hide attach-specific controls
        if (_optionsFrame and _optionsFrame:IsShown()) then
            _optionsFrame:GetScript("OnShow")(_optionsFrame);
        end
    end));
    yOff = yOff - ROW_HEIGHT;

    -- Attach-specific controls (only visible in party mode)
    if (attachMode == "party") then
        local attachAnchor = catDB.attachAnchor or "RIGHT";
        Track(CreateCycleButton(content, PADDING + 4, yOff, "Anchor", ATTACH_ANCHOR_OPTIONS, ATTACH_ANCHOR_LABELS, attachAnchor, function(val)
            catDB.attachAnchor = val;
            ST:RefreshDisplay();
        end));
        yOff = yOff - ROW_HEIGHT;

        Track(CreateSlider(content, PADDING + 4, yOff, "Offset X", -50, 50, 1, catDB.attachOffsetX or 2, function(val)
            catDB.attachOffsetX = val;
            ST:RefreshDisplay();
        end));
        yOff = yOff - 44;

        Track(CreateSlider(content, PADDING + 4, yOff, "Offset Y", -50, 50, 1, catDB.attachOffsetY or 0, function(val)
            catDB.attachOffsetY = val;
            ST:RefreshDisplay();
        end));
        yOff = yOff - 44;
    end

    -- Show Self + Self On Top (same row)
    Track(CreateCheckbox(content, PADDING + 4, yOff, "Show Self", catDB.showSelf, function(val)
        catDB.showSelf = val;
        ST:RefreshDisplay();
    end));
    Track(CreateCheckbox(content, PADDING + 140, yOff, "Self On Top", catDB.selfOnTop, function(val)
        catDB.selfOnTop = val;
        ST:RefreshDisplay();
    end));
    yOff = yOff - ROW_HEIGHT;

    -- Layout-specific controls (only relevant in free-floating mode)
    if (attachMode ~= "party") then
        if (layout == "bar") then
            Track(CreateSlider(content, PADDING + 4, yOff, "Bar Width", 120, 400, 1, catDB.barWidth, function(val)
                catDB.barWidth = val;
                ST:RefreshBarLayout(catKey);
                ST:RefreshDisplay();
            end));
            yOff = yOff - 44;

            Track(CreateSlider(content, PADDING + 4, yOff, "Bar Height", 16, 40, 1, catDB.barHeight, function(val)
                catDB.barHeight = val;
                DestroyAndRefresh();
            end));
            yOff = yOff - 44;

        elseif (layout == "icon") then
            Track(CreateSlider(content, PADDING + 4, yOff, "Icon Size", 16, 48, 1, catDB.iconSize, function(val)
                catDB.iconSize = val;
                ST:RefreshIconLayout(catKey);
            end));
            yOff = yOff - 44;

            Track(CreateCheckbox(content, PADDING + 4, yOff, "Show Names", catDB.showNames, function(val)
                catDB.showNames = val;
                ST:RefreshDisplay();
            end));
            yOff = yOff - ROW_HEIGHT;
        end

        -- Lock Position + Reset Position (same row)
        Track(CreateCheckbox(content, PADDING + 4, yOff, "Lock Position", catDB.locked, function(val)
            catDB.locked = val;
            local display = ST.displayFrames[catKey];
            if (display and display.title) then
                if (val) then display.title:Hide(); else display.title:Show(); end
            end
        end));
        Track(CreateActionButton(content, PADDING + 180, yOff, "Reset Position", 120, function()
            ST:ResetPosition(catKey);
            ST:Print(label .. " position reset.");
        end));
        yOff = yOff - ROW_HEIGHT;
    else
        -- Attached mode: icon size slider
        Track(CreateSlider(content, PADDING + 4, yOff, "Icon Size", 16, 48, 1, catDB.iconSize, function(val)
            catDB.iconSize = val;
            ST:RefreshDisplay();
        end));
        yOff = yOff - 44;
    end

    -- Spacing between sections
    yOff = yOff - 8;
    return yOff;
end

local function BuildContent()
    if (not _optionsFrame) then return; end
    local content = _optionsFrame.content;

    DestroyContent();

    local yOff = -8;

    for _, entry in ipairs(ST.categories) do
        yOff = BuildCategorySection(content, entry.key, yOff);
    end

    -- Preview button
    yOff = yOff - 4;
    local previewLabel = ST._previewActive and "Disable Preview" or "Toggle Preview";
    Track(CreateActionButton(content, PADDING, yOff, previewLabel, FRAME_WIDTH - (PADDING * 2), function()
        if (ST._previewActive) then
            ST:DeactivatePreview();
            ST:Print("Preview disabled.");
        else
            ST:ActivatePreview();
            ST:Print("Preview enabled.");
        end
        -- Rebuild to update button text
        if (_optionsFrame and _optionsFrame:IsShown()) then
            _optionsFrame:GetScript("OnShow")(_optionsFrame);
        end
    end));
    yOff = yOff - ROW_HEIGHT - PADDING;

    -- Resize frame to fit content
    local contentHeight = math.abs(yOff);
    content:SetHeight(contentHeight);
    _optionsFrame:SetHeight(30 + contentHeight + 4);
end

local function CreateOptionsFrame()
    if (_optionsFrame) then return _optionsFrame; end

    local frame = CreateFrame("Frame", FRAME_NAME, UIParent, "BackdropTemplate");
    frame:SetSize(FRAME_WIDTH, 400);
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 50);
    frame:SetFrameStrata("DIALOG");
    frame:SetClampedToScreen(true);
    frame:SetMovable(true);
    frame:EnableMouse(true);
    frame:SetBackdrop({
        bgFile   = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = 1,
    });
    frame:SetBackdropColor(unpack(COLOR_BG));
    frame:SetBackdropBorderColor(0.2, 0.2, 0.2, 1);

    -- Escape key closes the frame
    table.insert(UISpecialFrames, FRAME_NAME);

    -- Title bar (drag region)
    local titleBar = CreateFrame("Frame", nil, frame);
    titleBar:SetHeight(30);
    titleBar:SetPoint("TOPLEFT", 0, 0);
    titleBar:SetPoint("TOPRIGHT", 0, 0);
    titleBar:EnableMouse(true);
    titleBar:RegisterForDrag("LeftButton");
    titleBar:SetScript("OnDragStart", function() frame:StartMoving(); end);
    titleBar:SetScript("OnDragStop", function() frame:StopMovingOrSizing(); end);

    local titleBg = titleBar:CreateTexture(nil, "BACKGROUND");
    titleBg:SetAllPoints();
    titleBg:SetTexture("Interface\\BUTTONS\\WHITE8X8");
    titleBg:SetVertexColor(0.12, 0.12, 0.12, 1);

    local titleText = titleBar:CreateFontString(nil, "OVERLAY");
    titleText:SetFont(FONT, 14, "OUTLINE");
    titleText:SetPoint("LEFT", 12, 0);
    titleText:SetTextColor(unpack(COLOR_ACCENT));
    titleText:SetText("Mythic+ Tracker");

    -- Close button
    local closeBtn = CreateFrame("Button", nil, titleBar);
    closeBtn:SetSize(20, 20);
    closeBtn:SetPoint("RIGHT", -6, 0);

    local closeText = closeBtn:CreateFontString(nil, "OVERLAY");
    closeText:SetFont(FONT, 16);
    closeText:SetPoint("CENTER", 0, 0);
    closeText:SetTextColor(unpack(COLOR_MUTED));
    closeText:SetText("X");

    closeBtn:SetScript("OnEnter", function() closeText:SetTextColor(1, 1, 1); end);
    closeBtn:SetScript("OnLeave", function() closeText:SetTextColor(unpack(COLOR_MUTED)); end);
    closeBtn:SetScript("OnClick", function() frame:Hide(); end);

    -- Content area (height managed by BuildContent)
    local content = CreateFrame("Frame", nil, frame);
    content:SetPoint("TOPLEFT", 0, -30);
    content:SetPoint("TOPRIGHT", 0, -30);
    content:SetHeight(600);
    frame.content = content;

    -- Rebuild content every time the frame is shown
    frame:SetScript("OnShow", function()
        BuildContent();
    end);

    frame:Hide();
    _optionsFrame = frame;
    return frame;
end

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------

function ST:ToggleOptions()
    local frame = CreateOptionsFrame();
    if (frame:IsShown()) then
        frame:Hide();
    else
        frame:Show();
    end
end

-------------------------------------------------------------------------------
-- Slash Command: /lmt
-------------------------------------------------------------------------------

SLASH_LANTERNMYTHICTRACKER1 = "/lmt";
SlashCmdList["LANTERNMYTHICTRACKER"] = function(msg)
    msg = strtrim(msg or ""):lower();

    if (msg == "preview") then
        if (ST._previewActive) then
            ST:DeactivatePreview();
            ST:Print("Preview disabled.");
        else
            ST:ActivatePreview();
            ST:Print("Preview enabled.");
        end

    elseif (msg == "reset") then
        for _, entry in ipairs(ST.categories) do
            ST:ResetPosition(entry.key);
        end
        ST:Print("All positions reset.");

    elseif (msg == "lock") then
        -- Toggle lock on all categories
        local anyUnlocked = false;
        for _, entry in ipairs(ST.categories) do
            local catDB = ST:GetCategoryDB(entry.key);
            if (not catDB.locked) then anyUnlocked = true; break; end
        end
        local newState = anyUnlocked;
        for _, entry in ipairs(ST.categories) do
            local catDB = ST:GetCategoryDB(entry.key);
            catDB.locked = newState;
            local display = ST.displayFrames[entry.key];
            if (display and display.title) then
                if (newState) then display.title:Hide(); else display.title:Show(); end
            end
        end
        ST:Print(newState and "All categories locked." or "All categories unlocked.");

    else
        ST:ToggleOptions();
    end
end;
