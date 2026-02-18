local ADDON_NAME = ...;

local _W = LanternUX._W;
local T = _W.T;
local AcquireWidget = _W.AcquireWidget;
local RegisterWidget = _W.RegisterWidget;
local ShowDescription = _W.ShowDescription;
local ClearDescription = _W.ClearDescription;
local NextName = _W.NextName;

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local GROUP_HEADER_H   = 28;
local GROUP_ARROW_SIZE = 12;
local GROUP_ARROW_PAD  = 4;

-------------------------------------------------------------------------------
-- Create / Setup
-------------------------------------------------------------------------------

local function CreateGroup(parent)
    local w = AcquireWidget("group", parent);
    if (w) then return w; end

    w = {};
    local frame = CreateFrame("Button", NextName("LUX_Group_"), parent);
    frame:SetHeight(GROUP_HEADER_H);
    w.frame = frame;

    -- Arrow (Blizzard atlas: + when collapsed, - when expanded)
    local arrow = frame:CreateTexture(nil, "ARTWORK");
    arrow:SetSize(GROUP_ARROW_SIZE, GROUP_ARROW_SIZE);
    arrow:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 6);
    arrow:SetAtlas("ui-questtrackerbutton-secondary-expand");
    arrow:SetDesaturated(true);
    arrow:SetVertexColor(unpack(T.textDim));
    w._arrow = arrow;

    -- Label
    local text = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
    text:SetPoint("BOTTOMLEFT", arrow, "BOTTOMRIGHT", GROUP_ARROW_PAD, -1);
    text:SetJustifyH("LEFT");
    text:SetTextColor(unpack(T.textBright));
    w._text = text;

    -- Divider line
    local line = frame:CreateTexture(nil, "ARTWORK");
    line:SetHeight(1);
    line:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0);
    line:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0);
    line:SetColorTexture(unpack(T.divider));
    w._line = line;

    -- Helper: set arrow atlas based on expanded state
    local function SetArrowExpanded(expanded)
        if (expanded) then
            arrow:SetAtlas("ui-questtrackerbutton-secondary-collapse");
        else
            arrow:SetAtlas("ui-questtrackerbutton-secondary-expand");
        end
    end
    w._setArrowExpanded = SetArrowExpanded;

    -- State
    w._expanded = false;

    -- Hover
    frame:SetScript("OnEnter", function()
        w._text:SetTextColor(1, 1, 1, 1);
        w._arrow:SetVertexColor(unpack(T.textBright));
        ShowDescription(w._text:GetText(), w._desc_text);
    end);
    frame:SetScript("OnLeave", function()
        w._text:SetTextColor(unpack(T.textBright));
        w._arrow:SetVertexColor(unpack(T.textDim));
        ClearDescription();
    end);

    -- Click to toggle
    frame:SetScript("OnClick", function()
        w._expanded = not w._expanded;
        -- Save state
        if (w._stateKey) then
            _W.groupStates[w._stateKey] = w._expanded;
        end
        SetArrowExpanded(w._expanded);
        -- Re-layout the page
        if (w._reRender) then w._reRender(); end
    end);

    RegisterWidget("group", w);
    return w;
end

local function SetupGroup(w, parent, data, contentWidth)
    w.frame:SetParent(parent);
    w.frame:SetWidth(contentWidth);

    w._text:SetText(data.text or "");
    w._desc_text = data.desc;

    -- State key for per-session memory (use explicit stateKey if provided, for stable keys)
    w._stateKey = (_W.currentPageKey or "") .. ":" .. (data.stateKey or data.text or "");

    -- Resolve expanded state: saved > data default > collapsed
    if (_W.groupStates[w._stateKey] ~= nil) then
        w._expanded = _W.groupStates[w._stateKey];
    elseif (data.expanded) then
        w._expanded = true;
    else
        w._expanded = false;
    end

    -- Arrow orientation
    w._setArrowExpanded(w._expanded);

    w.height = GROUP_HEADER_H;
    w.frame:SetHeight(GROUP_HEADER_H);

    return w;
end

-------------------------------------------------------------------------------
-- Register
-------------------------------------------------------------------------------

_W.factories.group = { create = CreateGroup, setup = SetupGroup };
