local ADDON_NAME, addon = ...;
if (not addon) then return; end

addon.optionsLayout = addon.optionsLayout or {};
local Layout = addon.optionsLayout;

-------------------------------------------------------------------------------
-- Width Constants
-- Reference for AceConfig width values:
--   "full" = 100% (1 item per row)
--   "double" = ~66% (1-2 items per row)
--   "normal" = ~50% (2 items per row)
--   "half" = ~25% (4 items per row)
--   Numeric values: 2 = ~66%, 1.5 = ~50%, 1 = ~33%
-------------------------------------------------------------------------------
Layout.WIDTH = {
    FULL = "full",
    DOUBLE = "double",
    NORMAL = "normal",
    HALF = "half",
    -- Numeric widths for finer control
    TWO_THIRDS = 2,
    ONE_HALF = 1.5,
    ONE_THIRD = 1,
};

-------------------------------------------------------------------------------
-- Spacer (forces new line)
-- Use between rows to ensure proper line breaks
-------------------------------------------------------------------------------
function Layout.spacer(order, key)
    return {
        order = order,
        type = "description",
        name = "",
        width = "full",
    };
end

-------------------------------------------------------------------------------
-- Section Header
-- Creates a full-width header to separate option sections
-------------------------------------------------------------------------------
function Layout.header(order, name)
    return {
        order = order,
        type = "header",
        name = name,
    };
end

-------------------------------------------------------------------------------
-- Visual Divider
-- Uses the custom LanternDivider widget for visual separation
-------------------------------------------------------------------------------
function Layout.divider(order, hidden)
    return {
        order = order,
        type = "description",
        name = "",
        width = "full",
        control = "LanternDivider",
        hidden = hidden,
    };
end

-------------------------------------------------------------------------------
-- Description Text
-------------------------------------------------------------------------------
function Layout.description(order, text, opts)
    opts = opts or {};
    return {
        order = order,
        type = "description",
        name = text,
        width = opts.width or "full",
        fontSize = opts.fontSize or "medium",
        hidden = opts.hidden,
    };
end

-------------------------------------------------------------------------------
-- Control Builder
-- Builds an AceConfig control definition with standard properties
-------------------------------------------------------------------------------
function Layout.buildControl(order, opts, getDB, setDB)
    local controlType = opts.type or "toggle";

    local base = {
        order = order,
        type = controlType,
        name = opts.name or opts.key,
        desc = opts.desc,
        width = opts.width or "normal",
        disabled = opts.disabled,
        hidden = opts.hidden,
    };

    -- Add get/set if getDB/setDB provided and key exists
    if (getDB and setDB and opts.key) then
        base.get = function()
            local db = getDB();
            return db and db[opts.key];
        end;
        base.set = function(_, val)
            local db = getDB();
            if (db) then
                db[opts.key] = val;
                if (opts.onChange) then opts.onChange(val); end
            end
        end;
    elseif (opts.get) then
        base.get = opts.get;
        base.set = opts.set;
    end

    -- Type-specific properties
    if (controlType == "range") then
        base.min = opts.min or 0;
        base.max = opts.max or 100;
        base.step = opts.step or 1;
        base.softMin = opts.softMin;
        base.softMax = opts.softMax;
        base.bigStep = opts.bigStep;
        base.isPercent = opts.isPercent;
    elseif (controlType == "select") then
        base.values = opts.values;
        base.sorting = opts.sorting;
        base.itemControl = opts.itemControl;
        base.style = opts.style;
    elseif (controlType == "color") then
        base.hasAlpha = opts.hasAlpha;
        -- Color pickers need special get/set handling for r,g,b,a
        if (getDB and opts.key) then
            base.get = function()
                local db = getDB();
                if (db and db[opts.key]) then
                    local c = db[opts.key];
                    return c.r, c.g, c.b, c.a;
                end
                return 1, 1, 1, 1;
            end;
            base.set = function(_, r, g, b, a)
                local db = getDB();
                if (db) then
                    db[opts.key] = { r = r, g = g, b = b, a = a };
                    if (opts.onChange) then opts.onChange(r, g, b, a); end
                end
            end;
        end
    elseif (controlType == "execute") then
        base.func = opts.func;
        base.image = opts.image;
        base.imageWidth = opts.imageWidth;
        base.imageHeight = opts.imageHeight;
        base.control = opts.control;
    elseif (controlType == "input") then
        base.multiline = opts.multiline;
        base.pattern = opts.pattern;
        base.usage = opts.usage;
    end

    return base;
end

-------------------------------------------------------------------------------
-- Row Builder (Warband micro-ordering pattern)
-- Creates multiple items on the same row using micro-ordering (0.01 increments)
-- Items with close order values appear on the same row in AceConfig
--
-- Usage:
--   local row = Layout.row(10, {
--       { type = "toggle", key = "opt1", name = "Option 1", width = "normal" },
--       { type = "toggle", key = "opt2", name = "Option 2", width = "normal" },
--   }, getDBFunc);
--   for k, v in pairs(row) do args[k] = v; end
-------------------------------------------------------------------------------
function Layout.row(baseOrder, items, getDB, setDB)
    local args = {};
    for i, item in ipairs(items) do
        local order = baseOrder + (i - 1) * 0.01;
        local key = item.key or ("item_" .. i);
        args[key] = Layout.buildControl(order, item, getDB, setDB);
    end
    return args;
end

-------------------------------------------------------------------------------
-- Merge helper
-- Merges items from source table into destination table
-- Useful for adding row results to args
-------------------------------------------------------------------------------
function Layout.merge(dest, source)
    for k, v in pairs(source) do
        dest[k] = v;
    end
    return dest;
end

-------------------------------------------------------------------------------
-- Convenience Control Builders
-- These create individual controls with proper defaults
-------------------------------------------------------------------------------
function Layout.toggle(order, key, opts)
    opts = opts or {};
    opts.key = key;
    opts.type = "toggle";
    return Layout.buildControl(order, opts);
end

function Layout.input(order, key, opts)
    opts = opts or {};
    opts.key = key;
    opts.type = "input";
    return Layout.buildControl(order, opts);
end

function Layout.select(order, key, opts)
    opts = opts or {};
    opts.key = key;
    opts.type = "select";
    return Layout.buildControl(order, opts);
end

function Layout.range(order, key, opts)
    opts = opts or {};
    opts.key = key;
    opts.type = "range";
    return Layout.buildControl(order, opts);
end

function Layout.color(order, key, opts)
    opts = opts or {};
    opts.key = key;
    opts.type = "color";
    return Layout.buildControl(order, opts);
end

function Layout.execute(order, key, opts)
    opts = opts or {};
    opts.key = key;
    opts.type = "execute";
    return Layout.buildControl(order, opts);
end
