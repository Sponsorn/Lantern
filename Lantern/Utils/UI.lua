local ADDON_NAME, addon = ...;

addon.utils = addon.utils or {};
addon.utils.ui = addon.utils.ui or {};

local UI = addon.utils.ui;

UI.Colors = UI.Colors or {
    normal = NORMAL_FONT_COLOR,
    highlight = HIGHLIGHT_FONT_COLOR,
    disabled = DISABLED_FONT_COLOR,
};

local function resolveVarType(defaultValue)
    if (Settings and Settings.VarType) then
        local valueType = type(defaultValue);
        if (valueType == "boolean") then
            return Settings.VarType.Boolean;
        elseif (valueType == "string") then
            return Settings.VarType.String;
        elseif (valueType == "number") then
            return Settings.VarType.Number;
        end
    end
    return type(defaultValue);
end

local function resolveDefaultValue(defaultValue)
    if (Settings and Settings.Default) then
        if (defaultValue == true) then
            return Settings.Default.True;
        elseif (defaultValue == false) then
            return Settings.Default.False;
        end
    end
    return defaultValue;
end

function UI.MakeSettingKey(prefix, key)
    return string.format("%s_%s", tostring(prefix or ADDON_NAME), tostring(key or ""));
end

function UI.FormatOptions(options)
    return function()
        local opts = options;
        if (type(opts) == "function") then
            opts = opts();
        end
        local container = Settings.CreateControlTextContainer();
        for _, option in ipairs(opts or {}) do
            container:Add(option.value, option.label);
        end
        return container:GetData();
    end
end

function UI.CreateCategory(name, parentCategory)
    if (not Settings or not Settings.RegisterVerticalLayoutCategory) then return; end
    local category, layout;
    if (parentCategory and Settings.RegisterVerticalLayoutSubcategory) then
        category, layout = Settings.RegisterVerticalLayoutSubcategory(parentCategory, name);
    else
        category, layout = Settings.RegisterVerticalLayoutCategory(name);
    end
    if (not layout and SettingsPanel and SettingsPanel.GetLayout and category) then
        layout = SettingsPanel:GetLayout(category);
    end
    return category, layout;
end

function UI.RegisterCategory(category)
    if (Settings and Settings.RegisterAddOnCategory and category) then
        Settings.RegisterAddOnCategory(category);
    end
end

function UI.CreateCheckbox(category, variable, settingKey, dbTable, label, defaultValue, tooltip)
    if (not Settings or not Settings.RegisterAddOnSetting) then return; end
    local setting = Settings.RegisterAddOnSetting(category, variable, settingKey, dbTable, resolveVarType(defaultValue), label, resolveDefaultValue(defaultValue));
    local initializer = Settings.CreateCheckbox(category, setting, tooltip);
    return initializer, setting;
end

function UI.CreateProxyCheckbox(category, variable, label, defaultValue, tooltip, getter, setter)
    if (not Settings or not Settings.RegisterProxySetting) then return; end
    local setting = Settings.RegisterProxySetting(category, variable, Settings.VarType.Boolean, label, resolveDefaultValue(defaultValue), getter, setter);
    local initializer = Settings.CreateCheckbox(category, setting, tooltip);
    return initializer, setting;
end

function UI.CreateDropdown(category, variable, settingKey, dbTable, label, defaultValue, options, tooltip)
    if (not Settings or not Settings.RegisterAddOnSetting) then return; end
    local setting = Settings.RegisterAddOnSetting(category, variable, settingKey, dbTable, resolveVarType(defaultValue), label, defaultValue);
    return Settings.CreateDropdown(category, setting, UI.FormatOptions(options), tooltip), setting;
end

local InputControlMixin = CreateFromMixins(SettingsControlMixin);

function InputControlMixin:Init(initializer)
    SettingsControlMixin.Init(self, initializer);

    local setting = initializer:GetSetting();
    self._setting = setting;

    if (not self.InputBox) then
        local box = CreateFrame("EditBox", nil, self, "InputBoxTemplate");
        box:SetAutoFocus(false);
        box:SetSize(200, 20);
        box:SetPoint("LEFT", self, "CENTER", -70, 0);
        box:SetScript("OnEscapePressed", function(editBox)
            editBox:ClearFocus();
        end);
        box:SetScript("OnEnter", function(editBox)
            local tooltip = editBox:GetParent().Tooltip;
            local onEnter = tooltip and tooltip:GetScript("OnEnter");
            if (onEnter) then
                onEnter(tooltip);
            end
        end);
        box:SetScript("OnLeave", function(editBox)
            local tooltip = editBox:GetParent().Tooltip;
            local onLeave = tooltip and tooltip:GetScript("OnLeave");
            if (onLeave) then
                onLeave(tooltip);
            end
        end);
        self.InputBox = box;
    end

    self.InputBox:SetText(setting:GetValue() or "");
    self.InputBox:SetScript("OnEnterPressed", function()
        self:ConfirmInput();
    end);
    self.InputBox:SetScript("OnEditFocusLost", function()
        self:ConfirmInput();
    end);

    if (not self.cbrHandles) then
        self.cbrHandles = Settings.CreateCallbackHandleContainer();
    else
        self.cbrHandles:Unregister();
    end

    self.cbrHandles:SetOnValueChangedCallback(setting:GetVariable(), self.OnSettingValueChanged, self);

    self:EvaluateState();
end

function InputControlMixin:OnSettingValueChanged(...)
    local text;
    for i = 1, select("#", ...) do
        local value = select(i, ...);
        if (type(value) == "table" and value.GetValue) then
            text = value:GetValue();
            break;
        elseif (type(value) == "string" or type(value) == "number") then
            text = value;
        end
    end
    if (text == nil) then
        text = "";
    end
    self.InputBox:SetText(tostring(text));
end

function InputControlMixin:ConfirmInput()
    local text = self.InputBox:GetText() or "";
    self._setting:SetValue(text);
    self.InputBox:ClearFocus();
end

function InputControlMixin:EvaluateState()
    SettingsControlMixin.EvaluateState(self);
    local enabled = true;
    if (SettingsControlMixin.IsEnabled) then
        enabled = SettingsControlMixin.IsEnabled(self);
    elseif (self.IsEnabled) then
        enabled = self:IsEnabled();
    end
    self.InputBox:SetEnabled(enabled);
    local color = enabled and HIGHLIGHT_FONT_COLOR or DISABLED_FONT_COLOR;
    self.InputBox:SetTextColor(color.r, color.g, color.b);
end

function InputControlMixin:Release()
    if (self.cbrHandles) then
        self.cbrHandles:Unregister();
    end
end

function UI.CreateInput(category, layout, variable, settingKey, dbTable, label, defaultValue, tooltip, width)
    if (not Settings or not Settings.RegisterAddOnSetting) then return; end
    local setting = Settings.RegisterAddOnSetting(category, variable, settingKey, dbTable, resolveVarType(defaultValue), label, defaultValue);
    local data = Settings.CreateSettingInitializerData(setting, nil, tooltip);
    local initializer = Settings.CreateElementInitializer("SettingsListElementTemplate", data);

    initializer.InitFrame = function(_, frame)
        SettingsListElementMixin.OnLoad(frame);
        frame:SetSize(280, 26);
        if (not frame._lanternInputMixin) then
            Mixin(frame, InputControlMixin);
            frame._lanternInputMixin = true;
        end
        frame:Init(initializer);
        if (width and frame.InputBox) then
            frame.InputBox:SetWidth(width);
        end
    end

    initializer.Resetter = function(_, frame)
        if (frame.Release) then
            frame:Release();
        end
    end

    initializer:AddSearchTags(label);
    return initializer, setting;
end
