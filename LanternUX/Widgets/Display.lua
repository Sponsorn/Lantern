local ADDON_NAME = ...;

local _W = LanternUX._W;
local T = _W.T;
local AcquireWidget = _W.AcquireWidget;
local RegisterWidget = _W.RegisterWidget;
local NextName = _W.NextName;

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local HEADER_HEIGHT  = 28;
local DIVIDER_HEIGHT = 16;
local DESC_PAD_BOT   = 4;

-------------------------------------------------------------------------------
-- Widget: Label / Description
-------------------------------------------------------------------------------

local function CreateLabel(parent)
    local w = AcquireWidget("label", parent);
    if (w) then return w; end

    w = {};
    local frame = CreateFrame("Frame", NextName("LUX_Label_"), parent);
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
    local frame = CreateFrame("Frame", NextName("LUX_Header_"), parent);
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
    local frame = CreateFrame("Frame", NextName("LUX_Divider_"), parent);
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
-- Register
-------------------------------------------------------------------------------

_W.factories.label       = { create = CreateLabel,   setup = SetupLabel };
_W.factories.description = { create = CreateLabel,   setup = SetupLabel };
_W.factories.header      = { create = CreateHeader,  setup = SetupHeader };
_W.factories.divider     = { create = CreateDivider, setup = SetupDivider };
