local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

function Lantern:BuildDisableAutoAddSpellsOptions()
    return {
        desc = {
            order = 0,
            type = "description",
            name = "Prevents spells from being auto-added to your action bars.",
            fontSize = "medium",
        },
        enabled = {
            order = 1,
            type = "toggle",
            name = "Enable",
            desc = "Disable auto-adding spells to the action bar.",
            width = "full",
            get = function()
                local m = Lantern.modules and Lantern.modules.DisableAutoAddSpells;
                return m and m.enabled;
            end,
            set = function(_, val)
                if val then
                    Lantern:EnableModule("DisableAutoAddSpells");
                else
                    Lantern:DisableModule("DisableAutoAddSpells");
                end
            end,
        },
    };
end
