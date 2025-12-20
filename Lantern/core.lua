local ADDON_NAME, Lantern = ...;

_G.Lantern = Lantern;
Lantern.name = ADDON_NAME;
Lantern.modules = Lantern.modules or {};
Lantern._pendingModules = Lantern._pendingModules or {};
Lantern.eventHandlers = Lantern.eventHandlers or {};
Lantern.messageHandlers = Lantern.messageHandlers or {};

local tinsert = table.insert;

function Lantern:SetupDB()
    if (not _G.LanternDB) then
        _G.LanternDB = {
            modules = {},
        };
    end
    self.db = _G.LanternDB;
    self.db.modules = self.db.modules or {};
    self.db.minimap = self.db.minimap or {};
    self.db.options = self.db.options or {};
end

function Lantern:NewModule(name, opts)
    local module = {
        name = name,
        enabled = true,
        opts = opts or {},
        addon = self,
        _events = {},
        _messages = {},
    };
    setmetatable(module, { __index = self });
    return module;
end

function Lantern:RegisterModule(module)
    if (not module or not module.name) then
        return;
    end
    if (not self.db) then
        self:SetupDB();
    end
    self.modules[module.name] = module;
    self.db.modules = self.db.modules or {};
    if (self.db.modules[module.name] == nil) then
        self.db.modules[module.name] = true;
    end
    module.enabled = self.db.modules[module.name];
    if (self.ready and module.enabled) then
        if (module.OnInit) then module:OnInit(); end
        if (module.OnEnable) then module:OnEnable(); end
    else
        table.insert(self._pendingModules, module);
    end
end

function Lantern:EnableModule(name)
    local module = self.modules[name];
    if (module and not module.enabled) then
        module.enabled = true;
        self.db.modules[name] = true;
        if (module.OnEnable) then module:OnEnable(); end
    end
end

function Lantern:DisableModule(name)
    local module = self.modules[name];
    if (module and module.enabled) then
        module.enabled = false;
        self.db.modules[name] = false;
        if (module.OnDisable) then module:OnDisable(); end
        if (module._events) then
            for event in pairs(module._events) do
                self.eventFrame:UnregisterEvent(event);
            end
            module._events = {};
        end
    end
end

function Lantern:RegisterEvent(event, handler)
    if (not self.eventFrame) then
        self.eventFrame = CreateFrame("Frame");
        self.eventFrame:SetScript("OnEvent", function(_, ev, ...)
            local listeners = Lantern.eventHandlers[ev];
            if (listeners) then
                for i = 1, #listeners do
                    listeners[i](ev, ...);
                end
            end
        end);
    end
    self.eventHandlers[event] = self.eventHandlers[event] or {};
    tinsert(self.eventHandlers[event], handler);
    self.eventFrame:RegisterEvent(event);
end

function Lantern:ModuleRegisterEvent(module, event, handler)
    module._events[event] = true;
    self:RegisterEvent(event, function(ev, ...) if module.enabled then handler(module, ev, ...) end end);
end

function Lantern:RegisterMessage(message, handler)
    self.messageHandlers[message] = self.messageHandlers[message] or {};
    tinsert(self.messageHandlers[message], handler);
end

function Lantern:SendMessage(message, ...)
    local handlers = self.messageHandlers[message];
    if (handlers) then
        for i = 1, #handlers do
            handlers[i](message, ...);
        end
    end
end

Lantern:RegisterEvent("ADDON_LOADED", function(event, name)
    if (name ~= ADDON_NAME) then return; end
    Lantern:SetupDB();
    Lantern.ready = true;
    local pending = Lantern._pendingModules;
    Lantern._pendingModules = {};
    for _, module in ipairs(pending) do
        if (module.enabled) then
            if (module.OnInit) then module:OnInit(); end
            if (module.OnEnable) then module:OnEnable(); end
        end
    end
end);
