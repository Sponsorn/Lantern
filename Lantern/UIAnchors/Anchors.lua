local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end
local L = Lantern.L;

-- Anchor definitions: each entry defines one named anchor frame.
-- Positions are percentage offsets from screen center (WoW coords: +x right, +y up).
-- previewType: "bar", "icon", or "text"
-- grow: "UP", "DOWN", "LEFT", "RIGHT", "HORIZONTAL"
-- All anchors default to DISABLED — users enable the ones they need.
Lantern.UI_ANCHORS = {
    {
        id = "barsLeft",
        frameName = "Lantern_Anchor_BarsLeft",
        label = L["UIANCHORS_ANCHOR_BARS_LEFT"],
        previewType = "bar",
        grow = "UP",
        defaultPos = { xPct = -0.16, yPct = -0.10 },
        defaultPreview = { count = 3, width = 200, height = 20, spacing = 3 },
    },
    {
        id = "barsRight",
        frameName = "Lantern_Anchor_BarsRight",
        label = L["UIANCHORS_ANCHOR_BARS_RIGHT"],
        previewType = "bar",
        grow = "UP",
        defaultPos = { xPct = 0.16, yPct = -0.10 },
        defaultPreview = { count = 3, width = 200, height = 20, spacing = 3 },
    },
    {
        id = "barsCenter",
        frameName = "Lantern_Anchor_BarsCenter",
        label = L["UIANCHORS_ANCHOR_BARS_CENTER"],
        previewType = "bar",
        grow = "DOWN",
        defaultPos = { xPct = 0, yPct = -0.15 },
        defaultPreview = { count = 3, width = 200, height = 20, spacing = 3 },
    },
    {
        id = "barsTop",
        frameName = "Lantern_Anchor_BarsTop",
        label = L["UIANCHORS_ANCHOR_BARS_TOP"],
        previewType = "bar",
        grow = "DOWN",
        defaultPos = { xPct = 0, yPct = 0.20 },
        defaultPreview = { count = 3, width = 200, height = 20, spacing = 3 },
    },
    {
        id = "iconsLeft",
        frameName = "Lantern_Anchor_IconsLeft",
        label = L["UIANCHORS_ANCHOR_ICONS_LEFT"],
        previewType = "icon",
        grow = "RIGHT",
        defaultPos = { xPct = -0.14, yPct = 0.10 },
        defaultPreview = { count = 3, width = 32, height = 32, spacing = 3 },
    },
    {
        id = "iconsRight",
        frameName = "Lantern_Anchor_IconsRight",
        label = L["UIANCHORS_ANCHOR_ICONS_RIGHT"],
        previewType = "icon",
        grow = "LEFT",
        defaultPos = { xPct = 0.14, yPct = 0.10 },
        defaultPreview = { count = 3, width = 32, height = 32, spacing = 3 },
    },
    {
        id = "iconsCenter",
        frameName = "Lantern_Anchor_IconsCenter",
        label = L["UIANCHORS_ANCHOR_ICONS_CENTER"],
        previewType = "icon",
        grow = "HORIZONTAL",
        defaultPos = { xPct = 0, yPct = 0.12 },
        defaultPreview = { count = 3, width = 32, height = 32, spacing = 3 },
    },
    {
        id = "textTop",
        frameName = "Lantern_Anchor_TextTop",
        label = L["UIANCHORS_ANCHOR_TEXT_TOP"],
        previewType = "text",
        grow = "DOWN",
        defaultPos = { xPct = 0, yPct = 0.08 },
        defaultPreview = { count = 3, width = 200, height = 16, spacing = 3 },
    },
    {
        id = "textBottom",
        frameName = "Lantern_Anchor_TextBottom",
        label = L["UIANCHORS_ANCHOR_TEXT_BOTTOM"],
        previewType = "text",
        grow = "UP",
        defaultPos = { xPct = 0, yPct = -0.22 },
        defaultPreview = { count = 3, width = 200, height = 16, spacing = 3 },
    },
    {
        id = "listLeft",
        frameName = "Lantern_Anchor_ListLeft",
        label = L["UIANCHORS_ANCHOR_LIST_LEFT"],
        previewType = "text",
        grow = "DOWN",
        defaultPos = { xPct = -0.17, yPct = 0.15 },
        defaultPreview = { count = 3, width = 200, height = 16, spacing = 3 },
    },
    {
        id = "listRight",
        frameName = "Lantern_Anchor_ListRight",
        label = L["UIANCHORS_ANCHOR_LIST_RIGHT"],
        previewType = "text",
        grow = "DOWN",
        defaultPos = { xPct = 0.17, yPct = 0.15 },
        defaultPreview = { count = 3, width = 200, height = 16, spacing = 3 },
    },
    {
        id = "notifications",
        frameName = "Lantern_Anchor_Notifications",
        label = L["UIANCHORS_ANCHOR_NOTIFICATIONS"],
        previewType = "text",
        grow = "DOWN",
        defaultPos = { xPct = 0, yPct = 0.25 },
        defaultPreview = { count = 3, width = 200, height = 16, spacing = 3 },
    },
};

-- Build lookup by ID for quick access
Lantern.UI_ANCHORS_BY_ID = {};
for _, def in ipairs(Lantern.UI_ANCHORS) do
    Lantern.UI_ANCHORS_BY_ID[def.id] = def;
end
