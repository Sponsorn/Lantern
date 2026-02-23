local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local module = Lantern:NewModule("Tooltip", {
    title = "Tooltip",
    desc = "Enhances tooltips with IDs and mount names.",
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
    if (not id or id == 0) then return; end
    if (HasLine(tooltip, label)) then return; end
    tooltip:AddDoubleLine(label, tostring(id), T.textBright[1], T.textBright[2], T.textBright[3], 1, 1, 1);
    tooltip:Show();
end

local function GetUnitMount(unit)
    if (not GetAuraDataByIndex or not GetMountFromSpell) then return nil; end

    local i = 1;
    while (true) do
        local aura = GetAuraDataByIndex(unit, i, "HELPFUL");
        if (not aura) then break; end

        local mountID = GetMountFromSpell(aura.spellId);
        if (mountID) then
            local name = GetMountInfoByID(mountID);
            return name;
        end
        i = i + 1;
    end
    return nil;
end

-------------------------------------------------------------------------------
-- Ctrl+C copy support
-------------------------------------------------------------------------------

local lastTooltipID = nil;
local lastTooltipLabel = nil;
local secondTooltipID = nil;
local secondTooltipLabel = nil;

local function CopyToClipboard(text)
    if (not text) then return; end
    local editBox = ChatFrame1EditBox;
    if (not editBox) then return; end

    local wasFocused = editBox:HasFocus();
    local oldText = editBox:GetText();

    editBox:SetText(tostring(text));
    editBox:HighlightText();
    editBox:SetFocus();

    C_Timer.After(0.1, function()
        if (not wasFocused) then
            editBox:SetText(oldText or "");
            editBox:ClearFocus();
        end
    end);
end

local copyFrame = nil;

local function SetupCopyHandler()
    if (copyFrame) then return; end

    copyFrame = CreateFrame("Frame", "LanternTooltipCopyFrame", UIParent);
    copyFrame:EnableKeyboard(false);
    copyFrame:SetPropagateKeyboardInput(true);

    GameTooltip:HookScript("OnShow", function()
        copyFrame:EnableKeyboard(true);
    end);
    GameTooltip:HookScript("OnHide", function()
        copyFrame:EnableKeyboard(false);
        lastTooltipID = nil;
        lastTooltipLabel = nil;
        secondTooltipID = nil;
        secondTooltipLabel = nil;
    end);

    copyFrame:SetScript("OnKeyDown", function(self, key)
        self:SetPropagateKeyboardInput(true);

        if (not module.enabled) then return; end
        if (not db().copyOnCtrlC) then return; end

        if (key == "C" and IsControlKeyDown()) then
            local id, label;
            if (IsShiftKeyDown() and secondTooltipID) then
                id = secondTooltipID;
                label = secondTooltipLabel;
            elseif (not IsShiftKeyDown() and lastTooltipID) then
                id = lastTooltipID;
                label = lastTooltipLabel;
            end

            if (id) then
                CopyToClipboard(id);
                Lantern:Print(label .. " " .. id .. " copied.");
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

        -- Player tooltips: mount name (skip in instances — unit values are secret)
        local inInstance = IsInInstance();
        if (not inInstance and dataType == Enum.TooltipDataType.Unit and tooltip.GetUnit) then
            local _, unit = tooltip:GetUnit();
            if (unit and UnitIsPlayer(unit) and settings.showMount) then
                local mountName = GetUnitMount(unit);
                if (mountName and not HasLine(tooltip, "Mount")) then
                    tooltip:AddDoubleLine("Mount", mountName, T.textBright[1], T.textBright[2], T.textBright[3], 1, 1, 1);
                    tooltip:Show();
                end
            end
        end

        -- Item tooltips: ItemID + item use-effect SpellID
        if (dataType == Enum.TooltipDataType.Item or dataType == Enum.TooltipDataType.Toy) then
            if (settings.showItemID and data.id) then
                AddID(tooltip, "ItemID", data.id);
                if (tooltip == GameTooltip) then
                    lastTooltipID = data.id;
                    lastTooltipLabel = "ItemID";
                end
            end

            local hasSpellID = false;
            if (settings.showItemSpellID and data.id and GetItemSpell) then
                local spellName, spellID = GetItemSpell(data.id);
                if (spellID) then
                    AddID(tooltip, "SpellID", spellID);
                    hasSpellID = true;
                    if (tooltip == GameTooltip) then
                        secondTooltipID = spellID;
                        secondTooltipLabel = "SpellID";
                    end
                end
            end

            if (tooltip == GameTooltip and settings.copyOnCtrlC and lastTooltipID
                and not HasLine(tooltip, "Ctrl+C")) then
                if (hasSpellID) then
                    tooltip:AddLine("Ctrl+C ItemID  |  Ctrl+Shift+C SpellID",
                        T.textDim[1], T.textDim[2], T.textDim[3]);
                else
                    tooltip:AddLine("Ctrl+C to copy",
                        T.textDim[1], T.textDim[2], T.textDim[3]);
                end
                tooltip:Show();
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
                    if (data.id) then
                        AddID(tooltip, "SpellID", data.id);
                        if (tooltip == GameTooltip) then
                            lastTooltipID = data.id;
                            lastTooltipLabel = "SpellID";

                            if (settings.copyOnCtrlC and not HasLine(tooltip, "Ctrl+C")) then
                                tooltip:AddLine("Ctrl+C to copy",
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

            if (settings.showSpellID) then
                local spellID = button.GetSpellID and button:GetSpellID();
                if (spellID) then
                    AddID(tooltip, "SpellID", spellID);
                    lastTooltipID = spellID;
                    lastTooltipLabel = "SpellID";
                end
            end

            if (settings.showNodeID) then
                local nodeID = (button.GetNodeID and button:GetNodeID())
                    or (button.GetNodeInfo and button:GetNodeInfo() and button:GetNodeInfo().ID);
                if (nodeID) then
                    AddID(tooltip, "NodeID", nodeID);
                end
            end

            if (settings.copyOnCtrlC and lastTooltipID and not HasLine(tooltip, "Ctrl+C")) then
                tooltip:AddLine("Ctrl+C to copy",
                    T.textDim[1], T.textDim[2], T.textDim[3]);
                tooltip:Show();
            end
        end, module);
    end
end

function module:OnDisable()
    -- Hooks remain but check module.enabled
end

Lantern:RegisterModule(module);
