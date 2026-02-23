local ADDON_NAME, Lantern = ...;
local locale = GetLocale();
local L = {};
Lantern.L = L;

function Lantern:RegisterLocale(loc, strings)
    if (loc == "enUS") then
        for k, v in pairs(strings) do
            L[k] = v;
        end
    elseif (loc == locale) then
        for k, v in pairs(strings) do
            L[k] = v;
        end
    end
end
