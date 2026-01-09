local ADDON_NAME, Lantern = ...;

_G.Lantern = Lantern;
Lantern.name = ADDON_NAME;
Lantern.modules = Lantern.modules or {};
Lantern._pendingModules = Lantern._pendingModules or {};
Lantern.eventHandlers = Lantern.eventHandlers or {};
Lantern.messageHandlers = Lantern.messageHandlers or {};

local tinsert = table.insert;

-- Protected call wrapper for module callbacks
local function safeCall(fn, context, ...)
    if (type(fn) ~= "function") then return; end
    local success, err = pcall(fn, ...);
    if (not success) then
        local contextStr = context or "unknown";
        print("|cffe6c619Lantern error|r in " .. contextStr .. ": " .. tostring(err));
    end
    return success;
end

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
    self.db.characters = self.db.characters or {};
end

-- Character utility functions
function Lantern:GetCharacterKey()
    local name = UnitName("player");
    local realm = GetRealmName();
    if (not name or not realm) then return nil; end
    return string.format("%s-%s", name, realm);
end

function Lantern:UpdateCharacterLogin()
    local key = self:GetCharacterKey();
    if (not key) then return; end

    if (not self.db or not self.db.characters) then
        self:SetupDB();
    end

    self.db.characters[key] = self.db.characters[key] or {};
    self.db.characters[key].lastLogin = time();
    self.db.characters[key].name = UnitName("player");
    self.db.characters[key].realm = GetRealmName();
end

function Lantern:GetCharacterLastLogin(characterKey)
    if (not characterKey) then
        characterKey = self:GetCharacterKey();
    end

    if (not self.db or not self.db.characters or not self.db.characters[characterKey]) then
        return nil;
    end

    return self.db.characters[characterKey].lastLogin;
end

function Lantern:GetCharacterInfo(characterKey)
    if (not characterKey) then
        characterKey = self:GetCharacterKey();
    end

    if (not self.db or not self.db.characters) then
        return nil;
    end

    return self.db.characters[characterKey];
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
        if (module.OnInit) then
            safeCall(module.OnInit, "module " .. module.name .. " OnInit", module);
        end
        if (module.OnEnable) then
            safeCall(module.OnEnable, "module " .. module.name .. " OnEnable", module);
        end
    else
        table.insert(self._pendingModules, module);
    end
end

function Lantern:EnableModule(name)
    local module = self.modules[name];
    if (module and not module.enabled) then
        module.enabled = true;
        self.db.modules[name] = true;
        if (module.OnEnable) then
            safeCall(module.OnEnable, "module " .. name .. " OnEnable", module);
        end
    end
end

function Lantern:DisableModule(name)
    local module = self.modules[name];
    if (module and module.enabled) then
        module.enabled = false;
        self.db.modules[name] = false;
        if (module.OnDisable) then
            safeCall(module.OnDisable, "module " .. name .. " OnDisable", module);
        end
        -- Properly unregister all event handlers for this module
        if (module._events) then
            for event, handler in pairs(module._events) do
                self:UnregisterEvent(event, handler);
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
                    safeCall(listeners[i], "event " .. ev, ev, ...);
                end
            end
        end);
    end
    self.eventHandlers[event] = self.eventHandlers[event] or {};
    tinsert(self.eventHandlers[event], handler);
    self.eventFrame:RegisterEvent(event);
end

function Lantern:UnregisterEvent(event, handler)
    local listeners = self.eventHandlers[event];
    if (not listeners) then return; end

    for i = #listeners, 1, -1 do
        if (listeners[i] == handler) then
            table.remove(listeners, i);
        end
    end

    -- If no more listeners for this event, unregister from the frame
    if (#listeners == 0 and self.eventFrame) then
        self.eventFrame:UnregisterEvent(event);
    end
end

function Lantern:ModuleRegisterEvent(module, event, handler)
    if (module._events and module._events[event]) then
        return;
    end
    module._events = module._events or {};
    -- Store the wrapped handler so we can remove it later
    local wrappedHandler = function(ev, ...) if module.enabled then handler(module, ev, ...) end end;
    module._events[event] = wrappedHandler;
    self:RegisterEvent(event, wrappedHandler);
end

function Lantern:RegisterMessage(message, handler)
    self.messageHandlers[message] = self.messageHandlers[message] or {};
    tinsert(self.messageHandlers[message], handler);
end

function Lantern:SendMessage(message, ...)
    local handlers = self.messageHandlers[message];
    if (handlers) then
        for i = 1, #handlers do
            safeCall(handlers[i], "message " .. message, message, ...);
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
            if (module.OnInit) then
                safeCall(module.OnInit, "module " .. module.name .. " OnInit", module);
            end
            if (module.OnEnable) then
                safeCall(module.OnEnable, "module " .. module.name .. " OnEnable", module);
            end
        end
    end
end);

Lantern:RegisterEvent("PLAYER_LOGIN", function()
    Lantern:UpdateCharacterLogin();
end);
