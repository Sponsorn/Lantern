local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end
local L = Lantern.L;

local module = Lantern:NewModule("Tooltip", {
    title = L["TOOLTIP_TITLE"],
    desc = L["TOOLTIP_DESC"],
    defaultEnabled = false,
});

-------------------------------------------------------------------------------
-- DB helpers
-------------------------------------------------------------------------------

local DEFAULTS = {
    showMount       = true,
    showItemID      = true,
    showItemSpellID = true,
    showSpellID     = true,
    showNodeID      = true,
    copyOnCtrlC     = true,
};

local function db()
    Lantern.db.tooltip = Lantern.db.tooltip or {};
    for k, v in pairs(DEFAULTS) do
        if (Lantern.db.tooltip[k] == nil) then
            Lantern.db.tooltip[k] = v;
        end
    end
    return Lantern.db.tooltip;
end

-------------------------------------------------------------------------------
-- API references
-------------------------------------------------------------------------------

local GetMountFromSpell = C_MountJournal and C_MountJournal.GetMountFromSpell;
local GetMountInfoByID = C_MountJournal and C_MountJournal.GetMountInfoByID;
local GetAuraDataByIndex = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex;
local GetItemSpell = (C_Item and C_Item.GetItemSpell) or GetItemSpell;

local LanternUX = _G.LanternUX;
local T = LanternUX and LanternUX.Theme;

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function HasLine(tooltip, label)
    local name = tooltip:GetName();
    if (not name) then return false; end
    for i = 1, tooltip:NumLines() do
        local left = _G[name .. "TextLeft" .. i];
        if (left) then
            local text = left:GetText();
            if (text and text:find(label, 1, true)) then
                return true;
            end
        end
    end
    return false;
end

local function AddID(tooltip, label, id)
    if (issecretvalue and issecretvalue(id)) then return; end
    if (not id or id == 0) then return; end
    if (HasLine(tooltip, label)) then return; end
    tooltip:AddDoubleLine(label, tostring(id), 1, 0.82, 0, 1, 1, 1);
    tooltip:Show();
end

local function GetUnitMount(unit)
    if (not GetAuraDataByIndex or not GetMountFromSpell) then return nil; end

    local i = 1;
    while (true) do
        local aura = GetAuraDataByIndex(unit, i, "HELPFUL");
        if (not aura) then break; end

        local spellId = aura.spellId;
        if (spellId and not issecretvalue(spellId)) then
            local mountID = GetMountFromSpell(spellId);
            if (mountID) then
                local name = GetMountInfoByID(mountID);
                return name;
            end
        end
        i = i + 1;
    end
    return nil;
end

-------------------------------------------------------------------------------
-- Ctrl+C copy support
-------------------------------------------------------------------------------

local lastTooltipName = nil;
local lastTooltipEntries = {};  -- { {label, id}, ... }

local copyPopup;

local function CreateIDRow(parent, popup, index)
    local PAD = 12;
    local BTN_W = 54;
    local EDIT_H = 24;
    local LABEL_W = 56;

    local row = CreateFrame("Frame", "LanternTooltipCopyRow" .. index, parent);
    row:SetHeight(EDIT_H);
    row:SetPoint("LEFT", parent, "LEFT", PAD, 0);
    row:SetPoint("RIGHT", parent, "RIGHT", -PAD, 0);

    local label = row:CreateFontString(nil, "ARTWORK", T.fontSmall);
    label:SetPoint("LEFT", row, "LEFT", 0, 0);
    label:SetWidth(LABEL_W);
    label:SetJustifyH("LEFT");
    label:SetTextColor(1, 0.82, 0);
    row._label = label;

    local editBox = CreateFrame("EditBox", "LanternTooltipCopyEdit" .. index, row, "BackdropTemplate");
    editBox:SetHeight(EDIT_H);
    editBox:SetPoint("LEFT", label, "RIGHT", 4, 0);
    editBox:SetPoint("RIGHT", row, "RIGHT", -(BTN_W + 6), 0);
    editBox:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    });
    editBox:SetBackdropColor(unpack(T.inputBg));
    editBox:SetBackdropBorderColor(unpack(T.inputBorder));
    editBox:SetFontObject(T.fontSmall);
    editBox:SetTextColor(unpack(T.text));
    editBox:SetTextInsets(6, 6, 0, 0);
    editBox:SetAutoFocus(false);
    editBox:SetMaxLetters(0);
    editBox:SetScript("OnEscapePressed", function() popup:Hide(); end);
    editBox:SetScript("OnEnterPressed", function() popup:Hide(); end);
    editBox:SetScript("OnEditFocusGained", function(self) self:HighlightText(); end);
    editBox:SetScript("OnEditFocusLost", function(self) self:HighlightText(0, 0); end);
    editBox:SetScript("OnKeyUp", function(_, key)
        if (IsControlKeyDown() and (key == "C" or key == "X")) then
            popup:Hide();
        end
    end);
    row._editBox = editBox;

    local copyBtn = CreateFrame("Button", "LanternTooltipCopyBtn" .. index, row, "BackdropTemplate");
    copyBtn:SetSize(BTN_W, EDIT_H);
    copyBtn:SetPoint("RIGHT", row, "RIGHT", 0, 0);
    copyBtn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    });
    copyBtn:SetBackdropColor(unpack(T.inputBg));
    copyBtn:SetBackdropBorderColor(unpack(T.border));
    local btnText = copyBtn:CreateFontString(nil, "ARTWORK", T.fontSmall);
    btnText:SetPoint("CENTER");
    btnText:SetText(L["SELECT"]);
    btnText:SetTextColor(unpack(T.text));
    copyBtn:SetScript("OnEnter", function()
        copyBtn:SetBackdropBorderColor(unpack(T.textBright));
        btnText:SetTextColor(unpack(T.textBright));
    end);
    copyBtn:SetScript("OnLeave", function()
        copyBtn:SetBackdropBorderColor(unpack(T.border));
        btnText:SetTextColor(unpack(T.text));
    end);
    copyBtn:SetScript("OnClick", function()
        editBox:SetFocus();
    end);

    return row;
end

local function ShowCopyPopup(tooltipName, entries)
    if (not entries or #entries == 0) then return; end

    if (not copyPopup) then
        local POPUP_W = 300;
        local TITLE_H = 28;

        local popup = CreateFrame("Frame", "LanternTooltipCopyPopup", UIParent, "BackdropTemplate");
        popup:SetWidth(POPUP_W);
        popup:SetPoint("CENTER", UIParent, "CENTER", 0, 40);
        popup:SetFrameStrata("DIALOG");
        popup:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        });
        popup:SetBackdropColor(unpack(T.bg));
        popup:SetBackdropBorderColor(unpack(T.border));
        popup:EnableMouse(true);
        popup:EnableKeyboard(true);
        popup:SetPropagateKeyboardInput(true);
        popup:SetScript("OnKeyDown", function(self, key)
            if (key == "ESCAPE") then
                self:SetPropagateKeyboardInput(false);
                self:Hide();
            else
                self:SetPropagateKeyboardInput(true);
            end
        end);

        -- Title bar
        local titleBar = CreateFrame("Frame", "LanternTooltipCopyTitleBar", popup);
        titleBar:SetHeight(TITLE_H);
        titleBar:SetPoint("TOPLEFT");
        titleBar:SetPoint("TOPRIGHT");

        local title = titleBar:CreateFontString(nil, "ARTWORK", T.fontBody);
        title:SetPoint("LEFT", titleBar, "LEFT", 12, 0);
        title:SetPoint("RIGHT", titleBar, "RIGHT", -TITLE_H, 0);
        title:SetJustifyH("LEFT");
        title:SetWordWrap(false);
        title:SetTextColor(1, 0.82, 0);
        popup._title = title;

        -- Close X button (matches main panel)
        local closeBtn = CreateFrame("Button", "LanternTooltipCopyClose", titleBar);
        closeBtn:SetSize(TITLE_H, TITLE_H);
        closeBtn:SetPoint("TOPRIGHT");

        local closeIcon = closeBtn:CreateTexture(nil, "ARTWORK");
        closeIcon:SetAtlas("common-icon-redx");
        closeIcon:SetSize(12, 12);
        closeIcon:SetPoint("CENTER");
        closeIcon:SetDesaturated(true);
        closeIcon:SetVertexColor(unpack(T.textDim));

        local closeHover = closeBtn:CreateTexture(nil, "HIGHLIGHT");
        closeHover:SetAllPoints();
        closeHover:SetColorTexture(0.8, 0.2, 0.2, 0.15);

        closeBtn:SetScript("OnEnter", function() closeIcon:SetDesaturated(false); closeIcon:SetVertexColor(1, 1, 1); end);
        closeBtn:SetScript("OnLeave", function() closeIcon:SetDesaturated(true); closeIcon:SetVertexColor(unpack(T.textDim)); end);
        closeBtn:SetScript("OnClick", function() popup:Hide(); end);

        -- ID rows (create 2, show/hide as needed)
        local rows = {};
        for i = 1, 2 do
            local row = CreateIDRow(popup, popup, i);
            row:SetPoint("TOP", popup, "TOP", 0, -(TITLE_H + 8 + (i - 1) * 32));
            rows[i] = row;
        end
        popup._rows = rows;

        -- Info callout at bottom (matches LanternUX callout style)
        local infoColor = T.calloutInfo;
        local callout = CreateFrame("Frame", "LanternTooltipCopyHint", popup, "BackdropTemplate");
        callout:SetHeight(30);
        callout:SetPoint("BOTTOMLEFT", popup, "BOTTOMLEFT", 12, 8);
        callout:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -12, 8);
        callout:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" });
        callout:SetBackdropColor(infoColor[1], infoColor[2], infoColor[3], 0.06);

        local calloutBorder = callout:CreateTexture(nil, "ARTWORK");
        calloutBorder:SetWidth(3);
        calloutBorder:SetPoint("TOPLEFT");
        calloutBorder:SetPoint("BOTTOMLEFT");
        calloutBorder:SetColorTexture(infoColor[1], infoColor[2], infoColor[3], 1);

        local calloutText = callout:CreateFontString(nil, "ARTWORK", T.fontSmall);
        calloutText:SetPoint("TOPLEFT", callout, "TOPLEFT", 3 + 10, -8);
        calloutText:SetPoint("TOPRIGHT", callout, "TOPRIGHT", -10, -8);
        calloutText:SetJustifyH("LEFT");
        calloutText:SetWordWrap(true);
        calloutText:SetTextColor(unpack(T.text));
        calloutText:SetText(L["TOOLTIP_COPY_HINT"]);

        local textH = calloutText:GetStringHeight() or 14;
        callout:SetHeight(textH + 16);
        popup._callout = callout;

        copyPopup = popup;
    end

    -- Update title (truncates with ... if too long)
    copyPopup._title:SetText(tooltipName or "");

    -- Update rows
    local numRows = math.min(#entries, 2);
    for i = 1, 2 do
        local row = copyPopup._rows[i];
        local entry = entries[i];
        if (entry) then
            row._label:SetText(entry.label);
            row._editBox:SetText(tostring(entry.id));
            row:Show();
        else
            row:Hide();
        end
    end

    -- Adjust popup height (rows + callout)
    local calloutH = copyPopup._callout:GetHeight();
    copyPopup:SetHeight(28 + 8 + numRows * 32 + 4 + calloutH + 8);

    copyPopup:Show();
    copyPopup._rows[1]._editBox:SetFocus();
    copyPopup._rows[1]._editBox:HighlightText();
end

local copyFrame = nil;

local function SetupCopyHandler()
    if (copyFrame) then return; end

    copyFrame = CreateFrame("Frame", "LanternTooltipCopyFrame", UIParent);
    copyFrame:EnableKeyboard(false);
    copyFrame:SetPropagateKeyboardInput(true);

    -- Only enable keyboard listening outside combat
    GameTooltip:HookScript("OnShow", function()
        if (not InCombatLockdown()) then
            copyFrame:EnableKeyboard(true);
        end
    end);
    GameTooltip:HookScript("OnHide", function()
        if (not InCombatLockdown()) then
            copyFrame:EnableKeyboard(false);
        end
        lastTooltipName = nil;
        lastTooltipEntries = {};
    end);

    -- Re-enable keyboard copy when combat ends (if tooltip is still visible)
    copyFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
    copyFrame:SetScript("OnEvent", function(self)
        if (GameTooltip:IsShown()) then
            self:EnableKeyboard(true);
        end
    end);

    copyFrame:SetScript("OnKeyDown", function(self, key)
        if (InCombatLockdown()) then return; end

        self:SetPropagateKeyboardInput(true);

        if (not module.enabled) then return; end
        if (not db().copyOnCtrlC) then return; end

        if (key == "C" and IsControlKeyDown() and not IsShiftKeyDown()) then
            if (lastTooltipName and #lastTooltipEntries > 0) then
                ShowCopyPopup(lastTooltipName, lastTooltipEntries);
            end
        end
    end);
end

-------------------------------------------------------------------------------
-- Hook setup
-------------------------------------------------------------------------------

function module:OnEnable()
    if (self._hooked) then return; end
    self._hooked = true;

    if (not TooltipDataProcessor or not TooltipDataProcessor.AddTooltipPostCall) then return; end

    SetupCopyHandler();

    -- Main tooltip handler
    TooltipDataProcessor.AddTooltipPostCall(TooltipDataProcessor.AllTypes, function(tooltip, data)
        if (not module.enabled) then return; end
        if (not data) then return; end

        local ok, name = pcall(tooltip.GetName, tooltip);
        if (not ok or not name) then return; end

        local settings = db();
        local dataType = data.type;

        -- Player tooltips: mount name (skip in instances and combat — unit aura data is secret)
        local inInstance = IsInInstance();
        if (not inInstance and not InCombatLockdown() and dataType == Enum.TooltipDataType.Unit and tooltip.GetUnit) then
            local _, unit = tooltip:GetUnit();
            if (unit and UnitIsPlayer(unit) and settings.showMount) then
                local mountName = GetUnitMount(unit);
                if (mountName and not HasLine(tooltip, "Mount")) then
                    tooltip:AddDoubleLine("Mount", mountName, 1, 0.82, 0, 1, 1, 1);
                    tooltip:Show();
                end
            end
        end

        -- Item tooltips: ItemID + item use-effect SpellID
        if (dataType == Enum.TooltipDataType.Item or dataType == Enum.TooltipDataType.Toy) then
            if (settings.showItemID and data.id) then
                AddID(tooltip, "ItemID", data.id);
            end

            local itemSpellID;
            if (settings.showItemSpellID and data.id and GetItemSpell) then
                local _, spellID = GetItemSpell(data.id);
                if (spellID) then
                    AddID(tooltip, "SpellID", spellID);
                    itemSpellID = spellID;
                end
            end

            if (tooltip == GameTooltip and data.id) then
                local itemName = GetItemInfo(data.id);
                lastTooltipName = itemName or ("Item " .. data.id);
                lastTooltipEntries = {};
                if (settings.showItemID) then
                    lastTooltipEntries[#lastTooltipEntries + 1] = { label = "ItemID", id = data.id };
                end
                if (itemSpellID) then
                    lastTooltipEntries[#lastTooltipEntries + 1] = { label = "SpellID", id = itemSpellID };
                end

                if (settings.copyOnCtrlC and #lastTooltipEntries > 0
                    and not HasLine(tooltip, "Ctrl+C")) then
                    tooltip:AddLine(L["TOOLTIP_HINT_COPY"],
                        T.textDim[1], T.textDim[2], T.textDim[3]);
                    tooltip:Show();
                end
            end
        end

        -- Spell / aura tooltips: SpellID
        -- Skip Spell type when the owner is a talent button — EventRegistry
        -- handles those so SpellID and NodeID stay grouped together.
        if (settings.showSpellID) then
            local isTalent = false;
            if (dataType == Enum.TooltipDataType.Spell and tooltip.GetOwner) then
                local owner = tooltip:GetOwner();
                isTalent = owner and owner.GetNodeID;
            end

            if (not isTalent) then
                if (dataType == Enum.TooltipDataType.Spell
                    or dataType == Enum.TooltipDataType.UnitAura
                    or dataType == Enum.TooltipDataType.Totem) then
                    if (data.id and not (issecretvalue and issecretvalue(data.id))) then
                        AddID(tooltip, "SpellID", data.id);
                        if (tooltip == GameTooltip) then
                            local spellName = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(data.id);
                            lastTooltipName = spellName or ("Spell " .. data.id);
                            lastTooltipEntries = { { label = "SpellID", id = data.id } };

                            if (settings.copyOnCtrlC and not HasLine(tooltip, "Ctrl+C")) then
                                tooltip:AddLine(L["TOOLTIP_HINT_COPY"],
                                    T.textDim[1], T.textDim[2], T.textDim[3]);
                                tooltip:Show();
                            end
                        end
                    end
                end
            end
        end
    end);

    -- Talent tree tooltip: NodeID via EventRegistry
    if (EventRegistry and EventRegistry.RegisterCallback) then
        EventRegistry:RegisterCallback("TalentDisplay.TooltipCreated", function(_, button, tooltip)
            if (not module.enabled) then return; end
            local settings = db();

            local spellID;
            if (settings.showSpellID) then
                spellID = button.GetSpellID and button:GetSpellID();
                if (spellID) then
                    AddID(tooltip, "SpellID", spellID);
                end
            end

            local nodeID;
            if (settings.showNodeID) then
                nodeID = (button.GetNodeID and button:GetNodeID())
                    or (button.GetNodeInfo and button:GetNodeInfo() and button:GetNodeInfo().ID);
                if (nodeID) then
                    AddID(tooltip, "NodeID", nodeID);
                end
            end

            -- Build copy data
            if (spellID or nodeID) then
                local spellName = spellID and C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellID);
                lastTooltipName = spellName or "Talent";
                lastTooltipEntries = {};
                if (spellID) then
                    lastTooltipEntries[#lastTooltipEntries + 1] = { label = "SpellID", id = spellID };
                end
                if (nodeID) then
                    lastTooltipEntries[#lastTooltipEntries + 1] = { label = "NodeID", id = nodeID };
                end

                if (settings.copyOnCtrlC and not HasLine(tooltip, "Ctrl+C")) then
                    tooltip:AddLine(L["TOOLTIP_HINT_COPY"],
                        T.textDim[1], T.textDim[2], T.textDim[3]);
                    tooltip:Show();
                end
            end
        end, module);
    end
end

function module:OnDisable()
    -- Hooks remain but check module.enabled
end

Lantern:RegisterModule(module);
