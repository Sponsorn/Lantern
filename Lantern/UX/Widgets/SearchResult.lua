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

local SEARCH_RESULT_H = 32;

-------------------------------------------------------------------------------
-- Create / Setup
-------------------------------------------------------------------------------

local function CreateSearchResult(parent)
    local w = AcquireWidget("searchResult", parent);
    if (w) then return w; end

    w = {};
    local frame = CreateFrame("Button", NextName("LUX_SearchResult_"), parent);
    frame:SetHeight(SEARCH_RESULT_H);
    w.frame = frame;

    -- Hover highlight background
    local bg = frame:CreateTexture(nil, "BACKGROUND");
    bg:SetAllPoints();
    bg:SetColorTexture(0, 0, 0, 0);
    w._bg = bg;

    -- Label (left)
    local label = frame:CreateFontString(nil, "ARTWORK", T.fontBody);
    label:SetPoint("LEFT", frame, "LEFT", 0, 0);
    label:SetJustifyH("LEFT");
    label:SetTextColor(unpack(T.text));
    w._label = label;

    -- Breadcrumb (right, dim)
    local breadcrumb = frame:CreateFontString(nil, "ARTWORK", T.fontSmall);
    breadcrumb:SetPoint("RIGHT", frame, "RIGHT", 0, 0);
    breadcrumb:SetJustifyH("RIGHT");
    breadcrumb:SetTextColor(unpack(T.textDim));
    w._breadcrumb = breadcrumb;

    -- Hover
    frame:SetScript("OnEnter", function()
        bg:SetColorTexture(unpack(T.hover));
        w._label:SetTextColor(unpack(T.textBright));
        ShowDescription(w._label:GetText(), w._desc_text);
    end);
    frame:SetScript("OnLeave", function()
        bg:SetColorTexture(0, 0, 0, 0);
        w._label:SetTextColor(unpack(T.text));
        ClearDescription();
    end);

    -- Click
    frame:SetScript("OnClick", function()
        if (w._onClick) then w._onClick(); end
    end);

    RegisterWidget("searchResult", w);
    return w;
end

local function SetupSearchResult(w, parent, data, contentWidth)
    w.frame:SetParent(parent);
    w.frame:SetWidth(contentWidth);

    w._label:SetText(data.label or "");
    w._breadcrumb:SetText(data.breadcrumb or "");
    w._desc_text = data.desc;
    w._onClick = data.onClick;

    -- Ensure label doesn't overlap breadcrumb
    local breadcrumbWidth = w._breadcrumb:GetStringWidth() or 0;
    w._label:ClearAllPoints();
    w._label:SetPoint("LEFT", w.frame, "LEFT", 0, 0);
    w._label:SetPoint("RIGHT", w.frame, "RIGHT", -(breadcrumbWidth + 12), 0);

    w.frame:SetHeight(SEARCH_RESULT_H);
    w.height = SEARCH_RESULT_H;

    return w;
end

-------------------------------------------------------------------------------
-- Register
-------------------------------------------------------------------------------

_W.factories.searchResult = { create = CreateSearchResult, setup = SetupSearchResult };
