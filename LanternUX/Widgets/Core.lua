local ADDON_NAME = ...;

_G.LanternUX = _G.LanternUX or {};

-------------------------------------------------------------------------------
-- Theme
-------------------------------------------------------------------------------

local T = {
    -- Core
    bg           = { 0.06, 0.06, 0.07, 1.0 },
    border       = { 0.18, 0.18, 0.20, 1.0 },
    text         = { 0.72, 0.72, 0.72, 1.0 },
    textBright   = { 1.0,  1.0,  1.0,  1.0 },
    textDim      = { 0.52, 0.52, 0.54, 1.0 },
    sectionLabel = { 0.50, 0.50, 0.53, 1.0 },
    accent       = { 0.88, 0.56, 0.18, 1.0 },
    accentDim    = { 0.88, 0.56, 0.18, 0.40 },
    hover        = { 1.0,  1.0,  1.0,  0.08 },
    divider      = { 0.20, 0.20, 0.22, 0.5 },
    -- Toggle/checkbox
    checkBorder  = { 0.35, 0.35, 0.38, 1.0 },
    checkInner   = { 0.10, 0.10, 0.12, 1.0 },
    checkHover   = { 0.42, 0.42, 0.45, 1.0 },
    -- Toggle switch
    toggleTrack     = { 0.20, 0.20, 0.22, 1.0 },
    toggleTrackOn   = { 0.88, 0.56, 0.18, 0.85 },
    toggleThumb     = { 0.60, 0.60, 0.62, 1.0 },
    toggleThumbOn   = { 1.0,  1.0,  1.0,  1.0 },
    toggleTrackDis  = { 0.15, 0.15, 0.17, 1.0 },
    toggleThumbDis  = { 0.35, 0.35, 0.37, 1.0 },
    -- Scrollbar
    scrollTrack     = { 0.14, 0.14, 0.16, 0.3 },
    scrollThumb     = { 0.40, 0.40, 0.44, 0.6 },
    -- Section cards
    cardBg          = { 1.0, 1.0, 1.0, 0.035 },
    cardBorder      = { 1.0, 1.0, 1.0, 0.10 },
    -- Disabled
    disabled     = { 0.30, 0.30, 0.30, 1.0 },
    disabledText = { 0.45, 0.45, 0.45, 1.0 },
    disabledBg   = { 0.08, 0.08, 0.08, 1.0 },
    -- Panel shell
    sidebar      = { 0.09, 0.09, 0.10, 1.0 },
    titleBar     = { 0.09, 0.09, 0.10, 1.0 },
    selected     = { 0.88, 0.56, 0.18, 0.10 },
    accentBar    = { 0.88, 0.56, 0.18, 0.80 },
    splashText   = { 0.60, 0.60, 0.60, 1.0 },
    enabled      = { 0.40, 0.67, 0.40, 1.0 },
    disabledDot  = { 0.67, 0.40, 0.40, 1.0 },
    -- Callout
    calloutInfo    = { 0.40, 0.65, 0.90 },
    calloutNotice  = { 0.88, 0.56, 0.18 },
    calloutWarning = { 0.90, 0.35, 0.30 },
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
    dropdownItem = { 1.0,  1.0,  1.0,  0.08 },
    -- Danger / destructive
    dangerBg     = { 0.35, 0.10, 0.10, 1.0 },
    dangerBorder = { 0.60, 0.15, 0.15, 1.0 },
    dangerText   = { 1.0,  0.40, 0.40, 1.0 },
};

LanternUX.Theme = T;

-------------------------------------------------------------------------------
-- Fonts
-------------------------------------------------------------------------------

local FONT_DIR = "Interface\\AddOns\\LanternUX\\Fonts\\";
T.fontPathThin      = FONT_DIR .. "Roboto-Thin.ttf";
T.fontPathLight     = FONT_DIR .. "Roboto-Light.ttf";
T.fontPathRegular   = FONT_DIR .. "Roboto-Regular.ttf";
T.fontPathBold      = FONT_DIR .. "Roboto-Bold.ttf";
T.fontPathExtraBold = FONT_DIR .. "Roboto-ExtraBold.ttf";

local heading = CreateFont("LanternUX_Heading");
heading:SetFont(T.fontPathRegular, 16, "");

local body = CreateFont("LanternUX_Body");
body:SetFont(T.fontPathRegular, 12, "");

local small = CreateFont("LanternUX_BodySmall");
small:SetFont(T.fontPathRegular, 10, "");

local bodyBold = CreateFont("LanternUX_BodyBold");
bodyBold:SetFont(T.fontPathBold, 12, "OUTLINE");

local smallBold = CreateFont("LanternUX_BodySmallBold");
smallBold:SetFont(T.fontPathBold, 10, "OUTLINE");

T.fontHeading   = "LanternUX_Heading";
T.fontBody      = "LanternUX_Body";
T.fontSmall     = "LanternUX_BodySmall";
T.fontBodyBold  = "LanternUX_BodyBold";
T.fontSmallBold = "LanternUX_BodySmallBold";

-------------------------------------------------------------------------------
-- Shared internal table
-------------------------------------------------------------------------------

local _W = {};
LanternUX._W = _W;

_W.T = T;

-------------------------------------------------------------------------------
-- Frame naming helper (counter-based unique names for /fstack)
-------------------------------------------------------------------------------

local nameCounter = 0;
local function NextName(prefix)
    nameCounter = nameCounter + 1;
    return prefix .. nameCounter;
end
_W.NextName = NextName;

-------------------------------------------------------------------------------
-- Widget pools
-------------------------------------------------------------------------------

local pools = {};
_W.pools = pools;

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
_W.AcquireWidget = AcquireWidget;

local function RegisterWidget(widgetType, widget)
    pools[widgetType] = pools[widgetType] or {};
    widget._inUse = true;
    table.insert(pools[widgetType], widget);
end
_W.RegisterWidget = RegisterWidget;

local function ReleaseAll()
    -- Close any open dropdown (hook set by Select.lua)
    if (_W.closeDropdown) then _W.closeDropdown(); end

    for _, pool in pairs(pools) do
        for _, w in ipairs(pool) do
            w._inUse = false;
            w.frame:SetScript("OnUpdate", nil);
            w.frame:Hide();
            w.frame:ClearAllPoints();
        end
    end
end
_W.ReleaseAll = ReleaseAll;

-------------------------------------------------------------------------------
-- Shared helpers
-------------------------------------------------------------------------------

local function ClampValue(val, min, max, step)
    if (step and step > 0) then
        val = math.floor((val - min) / step + 0.5) * step + min;
    end
    return math.max(min, math.min(max, val));
end
_W.ClampValue = ClampValue;

local function FormatValue(val, isPercent)
    if (isPercent) then
        return string.format("%d%%", math.floor(val * 100 + 0.5));
    end
    local s = string.format("%.2f", val);
    s = s:gsub("%.?0+$", "");
    return s;
end
_W.FormatValue = FormatValue;

-------------------------------------------------------------------------------
-- Description panel API
-------------------------------------------------------------------------------

local descClearTimer;

local function ShowDescription(label, desc)
    if (descClearTimer) then descClearTimer:Cancel(); descClearTimer = nil; end
    local dp = _G.LanternUX and _G.LanternUX.descPanel;
    if (not dp or not desc or desc == "") then return; end
    dp._title:SetText(label or "");
    dp._text:SetText(desc);
end
_W.ShowDescription = ShowDescription;

local function ClearDescription()
    if (descClearTimer) then descClearTimer:Cancel(); end
    descClearTimer = C_Timer.NewTimer(0, function()
        descClearTimer = nil;
        local dp = _G.LanternUX and _G.LanternUX.descPanel;
        if (not dp) then return; end
        dp._title:SetText(dp._defaultTitle or "");
        dp._text:SetText(dp._defaultDesc or "");
    end);
end
_W.ClearDescription = ClearDescription;

local function SetDefaultDescription(title, desc)
    local dp = _G.LanternUX and _G.LanternUX.descPanel;
    if (not dp) then return; end
    dp._defaultTitle = title or "";
    dp._defaultDesc = desc or "";
    dp._title:SetText(title or "");
    dp._text:SetText(desc or "");
end
_W.SetDefaultDescription = SetDefaultDescription;

-------------------------------------------------------------------------------
-- EvalDisabled (shared by all stateful widgets)
-------------------------------------------------------------------------------

local function EvalDisabled(w)
    local disabled = false;
    if (w._disabledFn) then
        if (type(w._disabledFn) == "function") then
            disabled = w._disabledFn();
        else
            disabled = w._disabledFn;
        end
    end
    w._disabled = disabled;
    return disabled;
end
_W.EvalDisabled = EvalDisabled;

-------------------------------------------------------------------------------
-- Widget factory + refresh registries
-------------------------------------------------------------------------------

_W.factories = {};
_W.refreshers = {};

-- Mutable shared state (accessed by widget files via _W.fieldName)
_W.currentPageKey = nil;
_W.closeDropdown = nil;
_W.activeInputBox = nil;
_W.groupStates = {};
_W.lastRenderArgs = {};
_W.widgetPositionMap = {};

local function RefreshActiveWidgets()
    for widgetType, pool in pairs(pools) do
        local refresher = _W.refreshers[widgetType];
        if (refresher) then
            for _, w in ipairs(pool) do
                if (w._inUse) then
                    refresher(w);
                end
            end
        end
    end
end
_W.RefreshActiveWidgets = RefreshActiveWidgets;
