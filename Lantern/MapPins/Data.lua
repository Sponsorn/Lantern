local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local MapPinsData = {};
Lantern._mapPinsData = MapPinsData;

-------------------------------------------------------------------------------
-- Pin categories (scaffolded for expansion)
-------------------------------------------------------------------------------

MapPinsData.CATEGORIES = {
    trainers = {
        label = "MAPPINS_CAT_TRAINERS",
        atlas = "worldquest-icon-alchemy",
        defaultEnabled = true,
    },
    -- Future: vendors, mailboxes, portals, etc.
};

-------------------------------------------------------------------------------
-- Pin data indexed by uiMapID
-- Each pin: { x, y, name, category, atlas }
-- Coordinates sourced from Wowhead (divided by 100 to normalize to 0-1)
-- Zone IDs from Wowhead /way commands
-------------------------------------------------------------------------------

MapPinsData.PINS = {

    ---------------------------------------------------------------------------
    -- Silvermoon City (#15969)
    ---------------------------------------------------------------------------
    [15969] = {
        -- Alchemy
        { x = 0.470, y = 0.518, name = "Camberon",              category = "trainers", atlas = "worldquest-icon-alchemy" },
        { x = 0.732, y = 0.734, name = "Arcanist Sheynathren",  category = "trainers", atlas = "worldquest-icon-alchemy" },
        -- Blacksmithing
        { x = 0.436, y = 0.516, name = "Bemarrin",              category = "trainers", atlas = "worldquest-icon-blacksmithing" },
        { x = 0.696, y = 0.844, name = "Arathel Sunforge",      category = "trainers", atlas = "worldquest-icon-blacksmithing" },
        -- Enchanting
        { x = 0.480, y = 0.538, name = "Dolothos",              category = "trainers", atlas = "worldquest-icon-enchanting" },
        { x = 0.729, y = 0.717, name = "Magistrix Eredania",    category = "trainers", atlas = "worldquest-icon-enchanting" },
        -- Engineering
        { x = 0.435, y = 0.541, name = "Danwe",                 category = "trainers", atlas = "worldquest-icon-engineering" },
        { x = 0.693, y = 0.842, name = "Gloresse",              category = "trainers", atlas = "worldquest-icon-engineering" },
        -- Herbalism
        { x = 0.482, y = 0.516, name = "Botanist Nathera",      category = "trainers", atlas = "worldquest-icon-herbalism" },
        { x = 0.726, y = 0.736, name = "Botanist Tyniarrel",    category = "trainers", atlas = "worldquest-icon-herbalism" },
        -- Inscription
        { x = 0.469, y = 0.516, name = "Zantasia",              category = "trainers", atlas = "worldquest-icon-inscription" },
        -- Jewelcrafting
        { x = 0.482, y = 0.551, name = "Amin",                  category = "trainers", atlas = "worldquest-icon-jewelcrafting" },
        { x = 0.738, y = 0.712, name = "Aleinia",               category = "trainers", atlas = "worldquest-icon-jewelcrafting" },
        { x = 0.489, y = 0.542, name = "Kalinda",               category = "trainers", atlas = "worldquest-icon-jewelcrafting" },
        -- Leatherworking
        { x = 0.432, y = 0.558, name = "Talmar",                category = "trainers", atlas = "worldquest-icon-leatherworking" },
        -- Mining
        { x = 0.426, y = 0.528, name = "Belil",                 category = "trainers", atlas = "worldquest-icon-mining" },
        { x = 0.706, y = 0.826, name = "Saren",                 category = "trainers", atlas = "worldquest-icon-mining" },
        -- Skinning
        { x = 0.432, y = 0.556, name = "Tyn",                   category = "trainers", atlas = "worldquest-icon-skinning" },
        { x = 0.699, y = 0.810, name = "Mathreyn",              category = "trainers", atlas = "worldquest-icon-skinning" },
        -- Tailoring
        { x = 0.482, y = 0.540, name = "Galana",                category = "trainers", atlas = "worldquest-icon-tailoring" },
        { x = 0.733, y = 0.728, name = "Sempstress Ambershine", category = "trainers", atlas = "worldquest-icon-tailoring" },
        -- Cooking
        { x = 0.564, y = 0.698, name = "Sylann",                category = "trainers", atlas = "worldquest-icon-cooking" },
        -- Fishing
        { x = 0.447, y = 0.602, name = "Drathen",               category = "trainers", atlas = "worldquest-icon-fishing" },
    },

    ---------------------------------------------------------------------------
    -- Eversong Woods (#15968)
    ---------------------------------------------------------------------------
    [15968] = {
        -- Enchanting
        { x = 0.442, y = 0.462, name = "Rhys Duskfrost",        category = "trainers", atlas = "worldquest-icon-enchanting" },
        -- Fishing
        { x = 0.486, y = 0.760, name = "Melandra",              category = "trainers", atlas = "worldquest-icon-fishing" },
    },

    ---------------------------------------------------------------------------
    -- Harandar (#15355)
    ---------------------------------------------------------------------------
    [15355] = {
        -- Alchemy
        { x = 0.534, y = 0.498, name = "Noyen",                 category = "trainers", atlas = "worldquest-icon-alchemy" },
        -- Herbalism
        { x = 0.528, y = 0.502, name = "Monomo",                category = "trainers", atlas = "worldquest-icon-herbalism" },
        -- Inscription
        { x = 0.532, y = 0.556, name = "Rhys Duskfrost",        category = "trainers", atlas = "worldquest-icon-inscription" },
        -- Fishing
        { x = 0.522, y = 0.540, name = "Mowaia",                category = "trainers", atlas = "worldquest-icon-fishing" },
    },

    ---------------------------------------------------------------------------
    -- Zul'Aman (#15947)
    ---------------------------------------------------------------------------
    [15947] = {
        -- Skinning
        { x = 0.452, y = 0.696, name = "Kuvahn",                category = "trainers", atlas = "worldquest-icon-skinning" },
        -- Leatherworking
        { x = 0.452, y = 0.698, name = "Jan'zel",               category = "trainers", atlas = "worldquest-icon-leatherworking" },
        { x = 0.386, y = 0.238, name = "Zavahi",                category = "trainers", atlas = "worldquest-icon-leatherworking" },
        -- Tailoring
        { x = 0.386, y = 0.238, name = "Kalika",                category = "trainers", atlas = "worldquest-icon-tailoring" },
        -- Fishing
        { x = 0.486, y = 0.258, name = "Old Koko",              category = "trainers", atlas = "worldquest-icon-fishing" },
        { x = 0.382, y = 0.214, name = "Hav'kalo",              category = "trainers", atlas = "worldquest-icon-fishing" },
        { x = 0.462, y = 0.704, name = "Zel'kara the Spear",    category = "trainers", atlas = "worldquest-icon-fishing" },
    },

    ---------------------------------------------------------------------------
    -- Voidstorm (#15458)
    ---------------------------------------------------------------------------
    [15458] = {
        -- Blacksmithing
        { x = 0.514, y = 0.692, name = "Chrysalius",            category = "trainers", atlas = "worldquest-icon-blacksmithing" },
        -- Herbalism
        { x = 0.516, y = 0.680, name = "Botanist Karquist",     category = "trainers", atlas = "worldquest-icon-herbalism" },
        -- Fishing
        { x = 0.510, y = 0.686, name = "Rinnoa",                category = "trainers", atlas = "worldquest-icon-fishing" },
    },
};

-------------------------------------------------------------------------------
-- Lookup helper
-------------------------------------------------------------------------------

function MapPinsData:GetPinsForMap(mapID)
    return self.PINS[mapID];
end
