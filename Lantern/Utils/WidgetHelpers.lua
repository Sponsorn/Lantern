local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end
local L = Lantern.L;

function Lantern.moduleEnabled(name)
    local m = Lantern.modules and Lantern.modules[name];
    return m and m.enabled;
end

function Lantern.moduleToggle(name, label, desc)
    if (not desc) then
        local mod = Lantern.modules and Lantern.modules[name];
        local title = (mod and mod.opts and mod.opts.title) or name;
        desc = string.format(L["MODULE_ENABLE_DESC"], title);
    end
    return {
        type = "toggle",
        label = label or L["ENABLE"],
        desc = desc,
        get = function() return Lantern.moduleEnabled(name); end,
        set = function(val)
            if (val) then
                Lantern:EnableModule(name);
            else
                Lantern:DisableModule(name);
            end
            Lantern.refreshPage();
        end,
    };
end

function Lantern.refreshPage()
    local panel = Lantern._uxPanel;
    if (panel and panel.RefreshCurrentPage) then
        panel:RefreshCurrentPage();
    end
end
