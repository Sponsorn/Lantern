local ADDON_NAME, ns = ...;
local locale = GetLocale();
local L = {};
ns.L = L;

function ns:RegisterLocale(loc, strings)
    if (loc == "enUS") then
        for k, v in pairs(strings) do
            L[k] = v;
        end
    elseif (loc == locale) then
        for k, v in pairs(strings) do
            if (v ~= "") then L[k] = v; end
        end
    end
end
