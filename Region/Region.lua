local ADDON_NAME, addon = ...;

function addon:GetRegion()
    local portal = GetCVar and GetCVar("portal");
    if (portal == "public-test") then
        portal = "US"; -- PTR uses US resets
    end
    if (not portal or #portal ~= 2) then
        local regionID = GetCurrentRegion and GetCurrentRegion();
        portal = (regionID and ({ "US", "KR", "EU", "TW", "CN" })[regionID]) or portal;
    end
    if (portal and #portal == 2) then
        return portal:upper();
    end
end
