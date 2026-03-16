local ADDON_NAME, ns = ...;
local L = ns.L;

local T = _G.LanternUX and _G.LanternUX.Theme;
if (not T) then return; end

local frame;
local currentName;

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function FormatMoney(copper)
    if (not copper or copper == 0) then return "0g"; end
    local gold = math.floor(copper / 10000);
    if (gold >= 1000) then
        return string.format("%.1fk", gold / 1000);
    end
    return tostring(gold) .. "g";
end

local function FormatTimeAgo(ts)
    if (not ts or ts == 0) then return "---"; end
    local diff = time() - ts;
    if (diff < 3600) then return math.floor(diff / 60) .. "m ago"; end
    if (diff < 86400) then return math.floor(diff / 3600) .. "h ago"; end
    return math.floor(diff / 86400) .. "d ago";
end

-------------------------------------------------------------------------------
-- Build frame (once, lazy)
-------------------------------------------------------------------------------

local function EnsureFrame()
    if (frame) then return frame; end

    local FRAME_W = 260;
    local FRAME_H = 280;

    frame = CreateFrame("Frame", "LanternCO_CustomerInfo", UIParent, "BackdropTemplate");
    frame:SetSize(FRAME_W, FRAME_H);
    frame:SetFrameStrata("DIALOG");
    frame:SetClampedToScreen(true);
    frame:SetMovable(true);
    frame:EnableMouse(true);
    frame:RegisterForDrag("LeftButton");
    frame:SetScript("OnDragStart", function(self) self:StartMoving(); end);
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); end);
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 100);
    frame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    });
    frame:SetBackdropColor(T.bg[1], T.bg[2], T.bg[3], 0.95);
    frame:SetBackdropBorderColor(T.border[1], T.border[2], T.border[3], 1);
    frame:Hide();

    -- Title bar
    local titleBar = CreateFrame("Frame", "LanternCO_CITitle", frame);
    titleBar:SetHeight(28);
    titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0);
    titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0);
    local titleBg = titleBar:CreateTexture("LanternCO_CITitleBg", "BACKGROUND");
    titleBg:SetAllPoints();
    titleBg:SetColorTexture(T.titleBar[1], T.titleBar[2], T.titleBar[3], 1);

    local titleText = titleBar:CreateFontString("LanternCO_CITitleText", "OVERLAY");
    titleText:SetFontObject(T.fontBodyBold);
    titleText:SetPoint("LEFT", titleBar, "LEFT", 10, 0);
    titleText:SetTextColor(unpack(T.textBright));
    titleText:SetText(L["CO_CUSTOMER_INFO"] or "Customer Info");
    frame._titleText = titleText;

    -- Close button
    local closeBtn = CreateFrame("Button", "LanternCO_CIClose", titleBar);
    closeBtn:SetSize(28, 28);
    closeBtn:SetPoint("TOPRIGHT", titleBar, "TOPRIGHT", 0, 0);
    local closeLabel = closeBtn:CreateFontString("LanternCO_CICloseText", "OVERLAY");
    closeLabel:SetFontObject(T.fontBody);
    closeLabel:SetPoint("CENTER");
    closeLabel:SetText("x");
    closeLabel:SetTextColor(unpack(T.textDim));
    closeBtn:SetScript("OnClick", function() frame:Hide(); end);
    closeBtn:SetScript("OnEnter", function() closeLabel:SetTextColor(unpack(T.textBright)); end);
    closeBtn:SetScript("OnLeave", function() closeLabel:SetTextColor(unpack(T.textDim)); end);

    -- Content area
    local content = CreateFrame("Frame", "LanternCO_CIContent", frame);
    content:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 12, -8);
    content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 8);

    -- Player name + icon row
    local nameRow = content:CreateFontString("LanternCO_CIName", "OVERLAY");
    nameRow:SetFontObject(T.fontBodyBold);
    nameRow:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0);
    nameRow:SetTextColor(unpack(T.textBright));
    frame._nameRow = nameRow;

    -- Nickname label + input
    local nickLabel = content:CreateFontString("LanternCO_CINickLabel", "OVERLAY");
    nickLabel:SetFontObject(T.fontSmall);
    nickLabel:SetPoint("TOPLEFT", nameRow, "BOTTOMLEFT", 0, -12);
    nickLabel:SetText("Nickname:");
    nickLabel:SetTextColor(unpack(T.textDim));

    local nickInput = CreateFrame("EditBox", "LanternCO_CINickInput", content, "BackdropTemplate");
    nickInput:SetHeight(22);
    nickInput:SetPoint("TOPLEFT", nickLabel, "BOTTOMLEFT", 0, -4);
    nickInput:SetPoint("RIGHT", content, "RIGHT", 0, 0);
    nickInput:SetAutoFocus(false);
    nickInput:SetFontObject(T.fontBody);
    nickInput:SetTextInsets(6, 6, 0, 0);
    nickInput:SetMaxLetters(32);
    nickInput:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    });
    nickInput:SetBackdropColor(T.inputBg[1], T.inputBg[2], T.inputBg[3], 1);
    nickInput:SetBackdropBorderColor(T.inputBorder[1], T.inputBorder[2], T.inputBorder[3], 1);
    nickInput:SetTextColor(unpack(T.text));
    nickInput:SetScript("OnEditFocusGained", function(self)
        self:SetBackdropBorderColor(T.inputFocus[1], T.inputFocus[2], T.inputFocus[3], T.inputFocus[4]);
    end);
    nickInput:SetScript("OnEditFocusLost", function(self)
        self:SetBackdropBorderColor(T.inputBorder[1], T.inputBorder[2], T.inputBorder[3], 1);
    end);
    nickInput:SetScript("OnEnterPressed", function(self)
        local val = self:GetText();
        if (val == "") then val = nil; end
        if (currentName and ns.CustomerCache and ns.CustomerCache.UpdateMeta) then
            ns.CustomerCache.UpdateMeta(currentName, "nickname", val);
        end
        self:ClearFocus();
    end);
    nickInput:SetScript("OnEscapePressed", function(self) self:ClearFocus(); end);
    frame._nickInput = nickInput;

    -- Rating override label + buttons
    local ratingLabel = content:CreateFontString("LanternCO_CIRatingLabel", "OVERLAY");
    ratingLabel:SetFontObject(T.fontSmall);
    ratingLabel:SetPoint("TOPLEFT", nickInput, "BOTTOMLEFT", 0, -10);
    ratingLabel:SetText("Rating:");
    ratingLabel:SetTextColor(unpack(T.textDim));

    local RATING_OPTIONS = { { key = nil, label = "Auto" }, { key = "good", label = "Good" }, { key = "bad", label = "Bad" } };
    local ratingButtons = {};

    local btnX = 0;
    for i, opt in ipairs(RATING_OPTIONS) do
        local btn = CreateFrame("Button", "LanternCO_CIRating_" .. i, content, "BackdropTemplate");
        btn:SetSize(55, 22);
        btn:SetPoint("TOPLEFT", ratingLabel, "BOTTOMLEFT", btnX, -4);
        btn:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        });
        btn:SetBackdropColor(T.inputBg[1], T.inputBg[2], T.inputBg[3], 1);
        btn:SetBackdropBorderColor(T.inputBorder[1], T.inputBorder[2], T.inputBorder[3], 1);

        local label = btn:CreateFontString("LanternCO_CIRating_" .. i .. "_Text", "OVERLAY");
        label:SetFontObject(T.fontSmall);
        label:SetPoint("CENTER");
        label:SetText(opt.label);
        label:SetTextColor(unpack(T.text));
        btn._label = label;
        btn._key = opt.key;

        btn:SetScript("OnClick", function()
            if (currentName and ns.CustomerCache and ns.CustomerCache.UpdateMeta) then
                ns.CustomerCache.UpdateMeta(currentName, "ratingOverride", opt.key);
                -- Refresh the frame to show updated state
                if (ns.CustomerInfoFrame) then
                    ns.CustomerInfoFrame.ShowForCustomer(currentName);
                end
            end
        end);

        ratingButtons[i] = btn;
        btnX = btnX + 60;
    end
    frame._ratingButtons = ratingButtons;

    -- Stats section
    local statsLabel = content:CreateFontString("LanternCO_CIStats", "OVERLAY");
    statsLabel:SetFontObject(T.fontBody);
    statsLabel:SetPoint("TOPLEFT", ratingButtons[1], "BOTTOMLEFT", 0, -12);
    statsLabel:SetTextColor(unpack(T.text));
    statsLabel:SetJustifyH("LEFT");
    frame._statsLabel = statsLabel;

    -- Alt list section
    local altHeader = content:CreateFontString("LanternCO_CIAltHeader", "OVERLAY");
    altHeader:SetFontObject(T.fontSmall);
    altHeader:SetPoint("TOPLEFT", statsLabel, "BOTTOMLEFT", 0, -10);
    altHeader:SetText("Alts with same nickname:");
    altHeader:SetTextColor(unpack(T.textDim));
    frame._altHeader = altHeader;

    local altList = content:CreateFontString("LanternCO_CIAltList", "OVERLAY");
    altList:SetFontObject(T.fontBody);
    altList:SetPoint("TOPLEFT", altHeader, "BOTTOMLEFT", 0, -4);
    altList:SetPoint("RIGHT", content, "RIGHT", 0, 0);
    altList:SetTextColor(unpack(T.text));
    altList:SetJustifyH("LEFT");
    altList:SetWordWrap(true);
    frame._altList = altList;

    -- Click-outside-to-close overlay
    local overlay = CreateFrame("Button", "LanternCO_CIOverlay", UIParent);
    overlay:SetAllPoints(UIParent);
    overlay:SetFrameStrata("DIALOG");
    overlay:Hide();
    overlay:SetScript("OnClick", function() frame:Hide(); end);
    frame:SetScript("OnShow", function()
        overlay:SetFrameLevel(frame:GetFrameLevel() - 1);
        overlay:Show();
    end);
    frame:SetScript("OnHide", function()
        overlay:Hide();
        currentName = nil;
    end);

    return frame;
end

-------------------------------------------------------------------------------
-- Show for a specific customer
-------------------------------------------------------------------------------

local function ShowForCustomer(playerName)
    local f = EnsureFrame();
    currentName = playerName;

    local db = _G.LanternCraftingOrdersDB or {};
    local meta = db.customerMeta and db.customerMeta[playerName] or {};
    local cacheInfo = ns.CustomerCache and ns.CustomerCache.GetCustomerInfo(playerName);

    -- Name + tipper icon
    local nameText = playerName;
    if (cacheInfo and cacheInfo.rating and cacheInfo.rating ~= "none" and ns.TipperRating) then
        local markup = ns.TipperRating.GetTipperMarkup(cacheInfo.rating, db, 14);
        nameText = nameText .. "  " .. markup;
    end
    f._nameRow:SetText(nameText);

    -- Nickname
    f._nickInput:SetText(meta.nickname or "");

    -- Rating override buttons — highlight the active one
    local activeOverride = meta.ratingOverride;
    for _, btn in ipairs(f._ratingButtons) do
        if (btn._key == activeOverride) then
            btn:SetBackdropBorderColor(T.accent[1], T.accent[2], T.accent[3], 1);
            btn._label:SetTextColor(unpack(T.textBright));
        else
            btn:SetBackdropBorderColor(T.inputBorder[1], T.inputBorder[2], T.inputBorder[3], 1);
            btn._label:SetTextColor(unpack(T.text));
        end
    end

    -- Stats
    if (cacheInfo) then
        local lines = {};
        lines[#lines + 1] = "Orders: " .. (cacheInfo.count or 0) .. "  |  Tips: " .. FormatMoney(cacheInfo.totalTip or 0);
        lines[#lines + 1] = "Avg tip: " .. FormatMoney(cacheInfo.avgTip or 0) .. "  (personal: " .. FormatMoney(cacheInfo.personalAvgTip or 0) .. ")";
        f._statsLabel:SetText(table.concat(lines, "\n"));
    else
        f._statsLabel:SetText("No order history.");
    end

    -- Alt list
    local nickname = meta.nickname;
    if (nickname and nickname ~= "" and ns.CustomerCache and ns.CustomerCache.GetAltsForNickname) then
        local alts = ns.CustomerCache.GetAltsForNickname(nickname);
        -- Filter out the current player
        local filtered = {};
        for _, alt in ipairs(alts) do
            if (alt ~= playerName) then
                filtered[#filtered + 1] = alt;
            end
        end
        if (#filtered > 0) then
            f._altHeader:Show();
            f._altList:Show();
            f._altList:SetText(table.concat(filtered, ", "));
        else
            f._altHeader:Hide();
            f._altList:Hide();
        end
    else
        f._altHeader:Hide();
        f._altList:Hide();
    end

    f:Show();
end

-------------------------------------------------------------------------------
-- Export
-------------------------------------------------------------------------------

ns.CustomerInfoFrame = {
    ShowForCustomer = ShowForCustomer,
};
