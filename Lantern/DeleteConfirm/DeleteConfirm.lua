local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end
local L = Lantern.L;

-- Minimal delete helper: hide the DELETE input and enable the confirm button.
local module = Lantern:NewModule("DeleteConfirm", {
    title = L["DELETECONFIRM_TITLE"],
    desc = L["DELETECONFIRM_DESC"],
    skipOptions = true,
});

local function apply()
    local maxDialogs = _G.STATICPOPUP_NUMDIALOGS or 4;
    for i = 1, maxDialogs do
        local popup = _G["StaticPopup" .. i];
        if popup and popup:IsShown() then
            local edit = _G["StaticPopup" .. i .. "EditBox"];
            local btn = _G["StaticPopup" .. i .. "Button1"];
            if edit and edit:IsShown() then
                edit:SetText("");
                edit:Hide();
            end
            if btn then
                if btn.SetEnabled then
                    btn:SetEnabled(true);
                else
                    btn:Enable();
                end
            end
        end
    end
end

function module:OnEnable()
    self.addon:ModuleRegisterEvent(self, "DELETE_ITEM_CONFIRM", function()
        apply();
    end);
end

function module:OnDisable()
    -- no-op; default behavior resumes automatically
end

Lantern:RegisterModule(module);
