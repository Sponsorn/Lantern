local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local UX = Lantern.UX;
local T = UX and UX.Theme;
if (not T) then return; end

local module = Lantern.modules["UIAnchors"];
if (not module) then return; end
local L = Lantern.L;

local moduleEnabled = Lantern.moduleEnabled;
local moduleToggle = Lantern.moduleToggle;

local ANCHOR_DEFS = Lantern.UI_ANCHORS;

-- Convert between pixels and percentage for the sliders
local function getScreenSize()
    local w, h = GetPhysicalScreenSize();
    return w or 1920, h or 1080;
end

module.widgetOptions = function()
    local refreshPage = Lantern.refreshPage;

    local function isDisabled()
        return not moduleEnabled("UIAnchors");
    end

    local widgets = {
        moduleToggle("UIAnchors", L["ENABLE"], L["UIANCHORS_ENABLE_DESC"]),

        {
            type = "execute",
            label = L["UIANCHORS_SHOW_ANCHORS"],
            desc = L["UIANCHORS_SHOW_ANCHORS_DESC"],
            disabled = isDisabled,
            func = function()
                module:ToggleAnchors();
            end,
        },

        {
            type = "execute",
            label = L["UIANCHORS_OPEN_WEAKAURAS"],
            desc = L["UIANCHORS_OPEN_WEAKAURAS_DESC"],
            disabled = isDisabled,
            hidden = function()
                return not (C_AddOns.IsAddOnLoaded("WeakAuras") or C_AddOns.IsAddOnLoaded("M33kAuras"));
            end,
            func = function()
                local cmd = SlashCmdList["M33kAuras"] or SlashCmdList["WEAKAURAS"];
                if (cmd) then cmd(""); end
            end,
        },

        {
            type = "callout",
            text = L["UIANCHORS_CALLOUT_INFO"],
            severity = "info",
            hidden = isDisabled,
        },
    };

    -- Per-anchor collapsible groups
    for _, def in ipairs(ANCHOR_DEFS) do
        local anchorId = def.id;

        local function isAnchorDisabled()
            return isDisabled() or not module:IsAnchorEnabled(anchorId);
        end

        local sw, sh = getScreenSize();
        local halfW = math.floor(sw / 2);
        local halfH = math.floor(sh / 2);

        local children = {
            -- Enable toggle
            {
                type = "toggle",
                label = L["UIANCHORS_ANCHOR_ENABLE"],
                desc = L["UIANCHORS_ANCHOR_ENABLE_DESC"],
                disabled = isDisabled,
                get = function() return module:IsAnchorEnabled(anchorId); end,
                set = function(val)
                    module:SetAnchorEnabled(anchorId, val);
                    if (refreshPage) then refreshPage(); end
                end,
            },

            -- Frame name label
            {
                type = "label",
                text = string.format(L["UIANCHORS_FRAME_NAME"], "|cffe08f2e" .. def.frameName .. "|r"),
                hidden = function() return not module:IsAnchorEnabled(anchorId); end,
            },

            -- X position (pixels from center)
            {
                type = "range",
                label = L["UIANCHORS_POS_X"],
                desc = L["UIANCHORS_POS_X_DESC"],
                min = -halfW, max = halfW, step = 1, default = math.floor(def.defaultPos.xPct * sw),
                disabled = isAnchorDisabled,
                get = function()
                    local xPct = module:GetAnchorPosition(anchorId);
                    return math.floor(xPct * sw);
                end,
                set = function(val)
                    local _, yPct = module:GetAnchorPosition(anchorId);
                    module:SaveAnchorPosition(anchorId, val / sw, yPct);
                    module:RepositionAllAnchors();
                end,
            },

            -- Y position (pixels from center)
            {
                type = "range",
                label = L["UIANCHORS_POS_Y"],
                desc = L["UIANCHORS_POS_Y_DESC"],
                min = -halfH, max = halfH, step = 1, default = math.floor(def.defaultPos.yPct * sh),
                disabled = isAnchorDisabled,
                get = function()
                    local _, yPct = module:GetAnchorPosition(anchorId);
                    return math.floor(yPct * sh);
                end,
                set = function(val)
                    local xPct = module:GetAnchorPosition(anchorId);
                    module:SaveAnchorPosition(anchorId, xPct, val / sh);
                    module:RepositionAllAnchors();
                end,
            },

            -- Reset position
            {
                type = "execute",
                label = L["UIANCHORS_RESET_POSITION"],
                desc = L["UIANCHORS_RESET_POSITION_DESC"],
                disabled = isAnchorDisabled,
                func = function()
                    module:ResetAnchorPosition(anchorId);
                    if (refreshPage) then refreshPage(); end
                end,
            },
        };

        table.insert(widgets, {
            type = "group",
            text = def.label,
            children = children,
        });
    end

    -- Reset All
    table.insert(widgets, { type = "divider" });
    table.insert(widgets, {
        type = "execute",
        label = L["UIANCHORS_RESET_ALL"],
        desc = L["UIANCHORS_RESET_ALL_DESC"],
        disabled = isDisabled,
        confirm = L["UIANCHORS_RESET_ALL_CONFIRM"],
        func = function()
            module:ResetAllPositions();
            if (refreshPage) then refreshPage(); end
        end,
    });

    return widgets;
end
