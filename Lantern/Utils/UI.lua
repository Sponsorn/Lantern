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

function UI.RegisterRightButtonWidget()
    local AceGUI = LibStub and LibStub("AceGUI-3.0", true);
    if (not AceGUI) then return; end

    local Type, Version = "LanternRightButton", 1;
    if ((AceGUI:GetWidgetVersion(Type) or 0) >= Version) then return; end

    local PlaySound = PlaySound;
    local CreateFrame = CreateFrame;
    local UIParent = UIParent;

    local function Button_OnClick(frame, ...)
        AceGUI:ClearFocus();
        PlaySound(852);
        frame.obj:Fire("OnClick", ...);
    end

    local function updateButtonWidth(self)
        local textWidth = self.text:GetStringWidth() + 30;
        local maxWidth = self.frame:GetWidth();
        if (maxWidth and maxWidth > 0) then
            textWidth = math.min(textWidth, maxWidth);
        end
        self.button:SetWidth(textWidth);
    end

    local methods = {
        OnAcquire = function(self)
            self:SetHeight(24);
            self:SetWidth(200);
            self:SetDisabled(false);
            self:SetAutoWidth(true);
            self:SetText();
        end,
        SetText = function(self, text)
            self.text:SetText(text);
            updateButtonWidth(self);
        end,
        SetAutoWidth = function(self, autoWidth)
            self.autoWidth = autoWidth and true or false;
            updateButtonWidth(self);
        end,
        SetDisabled = function(self, disabled)
            self.disabled = disabled;
            if (disabled) then
                self.button:Disable();
            else
                self.button:Enable();
            end
        end,
        SetWidth = function(self, width)
            self.frame:SetWidth(width);
            updateButtonWidth(self);
        end,
        SetHeight = function(self, height)
            self.frame:SetHeight(height);
            self.button:SetHeight(height);
        end,
    };

    local function Constructor()
        local name = "LanternRightButton" .. AceGUI:GetNextWidgetNum(Type);
        local frame = CreateFrame("Frame", name, UIParent);
        frame:Hide();

        local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate");
        button:SetPoint("RIGHT", frame, "RIGHT", 0, 0);
        button:SetPoint("TOP", frame, "TOP", 0, 0);
        button:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0);
        button:SetScript("OnClick", Button_OnClick);

        local text = button:GetFontString();
        text:ClearAllPoints();
        text:SetPoint("TOPLEFT", 15, -1);
        text:SetPoint("BOTTOMRIGHT", -15, 1);
        text:SetJustifyV("MIDDLE");

        local widget = {
            frame = frame,
            button = button,
            text = text,
            type = Type,
        };

        button.obj = widget;

        for method, func in pairs(methods) do
            widget[method] = func;
        end

        return AceGUI:RegisterAsWidget(widget);
    end

    AceGUI:RegisterWidgetType(Type, Constructor, Version);
end

local function registerInlineButtonRowWidget(typeName, buttonTextValue)
    local AceGUI = LibStub and LibStub("AceGUI-3.0", true);
    if (not AceGUI) then return; end

    local Type, Version = typeName, 1;
    if ((AceGUI:GetWidgetVersion(Type) or 0) >= Version) then return; end

    local PlaySound = PlaySound;
    local CreateFrame = CreateFrame;
    local UIParent = UIParent;

    local function Button_OnClick(frame, ...)
        AceGUI:ClearFocus();
        PlaySound(852);
        frame.obj:Fire("OnClick", ...);
    end

    local function updateLayout(self)
        local buttonTextWidth = self.buttonText:GetStringWidth() + 30;
        local maxWidth = self.frame:GetWidth();
        if (maxWidth and maxWidth > 0) then
            buttonTextWidth = math.min(buttonTextWidth, maxWidth);
        end
        self.button:SetWidth(buttonTextWidth);
    end

    local methods = {
        OnAcquire = function(self)
            self:SetHeight(24);
            self:SetWidth(200);
            self:SetDisabled(false);
            self:SetText();
        end,
        SetText = function(self, text)
            self.label:SetText(text);
            updateLayout(self);
        end,
        SetDisabled = function(self, disabled)
            self.disabled = disabled;
            if (disabled) then
                self.button:Disable();
            else
                self.button:Enable();
            end
        end,
        SetWidth = function(self, width)
            self.frame:SetWidth(width);
            updateLayout(self);
        end,
        SetHeight = function(self, height)
            self.frame:SetHeight(height);
            self.button:SetHeight(height);
        end,
    };

    local function Constructor()
        local name = Type .. AceGUI:GetNextWidgetNum(Type);
        local frame = CreateFrame("Frame", name, UIParent);
        frame:Hide();

        local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate");
        button:SetPoint("RIGHT", frame, "RIGHT", 0, 0);
        button:SetPoint("TOP", frame, "TOP", 0, 0);
        button:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0);
        button:SetScript("OnClick", Button_OnClick);

        local buttonText = button:GetFontString();
        buttonText:SetText(buttonTextValue or "Action");
        buttonText:ClearAllPoints();
        buttonText:SetPoint("TOPLEFT", 15, -1);
        buttonText:SetPoint("BOTTOMRIGHT", -15, 1);
        buttonText:SetJustifyV("MIDDLE");

        local label = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
        label:SetPoint("LEFT", frame, "LEFT", 0, 0);
        label:SetPoint("RIGHT", button, "LEFT", -10, 0);
        label:SetJustifyH("LEFT");
        label:SetJustifyV("MIDDLE");

        local widget = {
            frame = frame,
            button = button,
            buttonText = buttonText,
            label = label,
            type = Type,
        };

        button.obj = widget;

        for method, func in pairs(methods) do
            widget[method] = func;
        end

        return AceGUI:RegisterAsWidget(widget);
    end

    AceGUI:RegisterWidgetType(Type, Constructor, Version);
end

function UI.RegisterInlineButtonRowWidgets()
    registerInlineButtonRowWidget("LanternInlineButtonRow", "Add to block list");
    registerInlineButtonRowWidget("LanternInlineRemoveButtonRow", "Remove");
end

function UI.RegisterDividerWidget()
    local AceGUI = LibStub and LibStub("AceGUI-3.0", true);
    if (not AceGUI) then return; end

    local Type, Version = "LanternDivider", 1;
    if ((AceGUI:GetWidgetVersion(Type) or 0) >= Version) then return; end

    local CreateFrame = CreateFrame;
    local UIParent = UIParent;

    local function updateLineWidth(self)
        local width = self.frame:GetWidth();
        if (not width or width <= 0) then
            return;
        end
        self.line:SetWidth(math.max(40, width * 0.5));
    end

    local methods = {
        OnAcquire = function(self)
            self:SetHeight(8);
            self:SetWidth(200);
        end,
        SetWidth = function(self, width)
            self.frame:SetWidth(width);
            updateLineWidth(self);
        end,
        SetHeight = function(self, height)
            self.frame:SetHeight(height);
        end,
        SetText = function() end,
        SetFontObject = function() end,
    };

    local function Constructor()
        local frame = CreateFrame("Frame", nil, UIParent);
        frame:Hide();

        local line = frame:CreateTexture(nil, "ARTWORK");
        line:SetPoint("CENTER", frame, "CENTER", 0, 0);
        line:SetHeight(1);
        line:SetColorTexture(0.7, 0.6, 0.3, 0.8);

        local widget = {
            frame = frame,
            line = line,
            type = Type,
        };

        for method, func in pairs(methods) do
            widget[method] = func;
        end

        return AceGUI:RegisterAsWidget(widget);
    end

    AceGUI:RegisterWidgetType(Type, Constructor, Version);
end
