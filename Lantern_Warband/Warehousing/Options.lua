local ADDON_NAME = "Lantern_Warband";
local Lantern = _G.Lantern;
if (not Lantern or not Lantern.modules or not Lantern.modules.Warband) then return; end

local Warband = Lantern.modules.Warband;

-- Build warehousing tab options (only on Retail with account bank)
function Warband:BuildWarehousingOptions(whArgs, refreshOptions)
    if (not Enum or not Enum.BagIndex or not Enum.BagIndex.AccountBankTab_1 or not self.Warehousing) then
        return;
    end

    whArgs.desc = {
        order = 1,
        type = "description",
        name = "Organize warbank items into groups and move them between your bags and the warband bank.\n\nWarehousing groups are managed directly through the warbank UI. \n\nOpen the warband bank and click the settings button on the Warehousing panel to get started with creating groups, add items, and configure settings.",
        fontSize = "medium",
    };

    whArgs.openSettings = {
        order = 2,
        type = "execute",
        name = "Open Warehousing Settings",
        desc = "Open the Warehousing settings panel",
        width = "double",
        func = function()
            if (SettingsPanel and SettingsPanel:IsShown()) then
                HideUIPanel(SettingsPanel);
            end
            self.WarehousingUI:ShowSettingsPanel();
        end,
    };
end
