local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local function deleteConfirmModule()
    return Lantern.modules and Lantern.modules.DeleteConfirm;
end

function Lantern:BuildDeleteConfirmOptions()
    return {
        desc = {
            order = 0,
            type = "description",
            name = "Hides the delete input box and enables the confirm button on delete popups.",
            fontSize = "medium",
        },
        enabled = {
            order = 1,
            type = "toggle",
            name = "Enable",
            desc = "Replace typing DELETE with a confirm button (Shift pauses).",
            width = "full",
            get = function()
                local m = deleteConfirmModule();
                return m and m.enabled;
            end,
            set = function(_, val)
                if val then
                    Lantern:EnableModule("DeleteConfirm");
                else
                    Lantern:DisableModule("DeleteConfirm");
                end
            end,
        },
    };
end
