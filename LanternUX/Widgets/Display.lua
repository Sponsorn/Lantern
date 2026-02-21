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

    local text = frame:CreateFontString(nil, "ARTWORK", T.fontBody);
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
        w._text:SetFontObject(T.fontSmall);
    elseif (fontSize == "large") then
        w._text:SetFontObject(T.fontHeading);
    else
        w._text:SetFontObject(T.fontBody);
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

    local text = frame:CreateFontString(nil, "ARTWORK", T.fontBody);
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
-- Internal widget: Card background (for group children)
-------------------------------------------------------------------------------

local CARD_PAD = 10;  -- Padding around children

local cardPool = {};

local function AcquireCard(parent)
    for _, c in ipairs(cardPool) do
        if (not c._inUse) then
            c._inUse = true;
            c.frame:SetParent(parent);
            c.frame:Show();
            return c;
        end
    end

    local c = {};
    local frame = CreateFrame("Frame", NextName("LUX_Card_"), parent, "BackdropTemplate");
    frame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets   = { left = 3, right = 3, top = 3, bottom = 3 },
    });
    frame:SetBackdropColor(unpack(T.cardBg));
    frame:SetBackdropBorderColor(unpack(T.cardBorder));
    c.frame = frame;
    c._inUse = true;
    table.insert(cardPool, c);
    return c;
end

local function ReleaseCards()
    for _, c in ipairs(cardPool) do
        c._inUse = false;
        c.frame:Hide();
        c.frame:ClearAllPoints();
    end
end

_W.AcquireCard = AcquireCard;
_W.ReleaseCards = ReleaseCards;
_W.CARD_PAD = CARD_PAD;

-------------------------------------------------------------------------------
-- Widget: Callout (info / notice / warning)
-------------------------------------------------------------------------------

local CALLOUT_BORDER_W = 3;
local CALLOUT_PAD_H    = 10;  -- horizontal padding (left of text, after border)
local CALLOUT_PAD_V    = 8;   -- vertical padding

local CALLOUT_COLORS = {
    info    = T.calloutInfo,
    notice  = T.calloutNotice,
    warning = T.calloutWarning,
};

local function CreateCallout(parent)
    local w = AcquireWidget("callout", parent);
    if (w) then return w; end

    w = {};
    local frame = CreateFrame("Frame", NextName("LUX_Callout_"), parent, "BackdropTemplate");
    frame:SetHeight(30);
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
    });
    w.frame = frame;

    local border = frame:CreateTexture(nil, "ARTWORK");
    border:SetWidth(CALLOUT_BORDER_W);
    border:SetPoint("TOPLEFT");
    border:SetPoint("BOTTOMLEFT");
    w._border = border;

    local text = frame:CreateFontString(nil, "ARTWORK", T.fontBody);
    text:SetPoint("TOPLEFT", frame, "TOPLEFT", CALLOUT_BORDER_W + CALLOUT_PAD_H, -CALLOUT_PAD_V);
    text:SetJustifyH("LEFT");
    text:SetWordWrap(true);
    text:SetTextColor(unpack(T.text));
    w._text = text;

    RegisterWidget("callout", w);
    return w;
end

local function SetupCallout(w, parent, data, contentWidth)
    w.frame:SetParent(parent);
    w.frame:SetWidth(contentWidth);

    local severity = data.severity or "info";
    local color = CALLOUT_COLORS[severity] or CALLOUT_COLORS.info;

    -- Left border color
    w._border:SetColorTexture(color[1], color[2], color[3], 1);

    -- Tinted background
    w.frame:SetBackdropColor(color[1], color[2], color[3], 0.06);

    -- Text
    local textWidth = contentWidth - CALLOUT_BORDER_W - CALLOUT_PAD_H - CALLOUT_PAD_H;
    w._text:SetWidth(textWidth);
    w._text:SetText(data.text or "");

    local textHeight = w._text:GetStringHeight() or 14;
    local totalHeight = textHeight + CALLOUT_PAD_V * 2;
    w.frame:SetHeight(totalHeight);
    w.height = totalHeight;

    return w;
end

-------------------------------------------------------------------------------
-- Register
-------------------------------------------------------------------------------

_W.factories.label       = { create = CreateLabel,     setup = SetupLabel };
_W.factories.description = { create = CreateLabel,     setup = SetupLabel };
_W.factories.header      = { create = CreateHeader,    setup = SetupHeader };
_W.factories.divider     = { create = CreateDivider,   setup = SetupDivider };
_W.factories.callout     = { create = CreateCallout,   setup = SetupCallout };
