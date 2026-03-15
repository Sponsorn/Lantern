local ADDON_NAME, ns = ...;

-------------------------------------------------------------------------------
-- Icon Sets
-------------------------------------------------------------------------------

local ICON_SETS = {
    coins = {
        good    = "coin-gold",
        neutral = "coin-silver",
        bad     = "coin-copper",
    },
    checkmarks = {
        good    = "groupfinder-icon-greencheckmark",
        neutral = "common-radiobutton-dot",
        bad     = "groupfinder-icon-redx",
    },
    -- Quality crafting pip icons (hardcoded atlas names)
    -- TODO: verify atlas names in-game with:
    -- /dump C_TradeSkillUI.GetRecipeItemQualityInfo(recipeID, 1).iconSmall
    -- /dump C_TradeSkillUI.GetRecipeItemQualityInfo(recipeID, 2).iconSmall
    -- /dump C_TradeSkillUI.GetRecipeItemQualityInfo(recipeID, 3).iconSmall
    quality = {
        good    = "Professions-ChatIcon-Quality-Tier3",
        neutral = "Professions-ChatIcon-Quality-Tier2",
        bad     = "Professions-ChatIcon-Quality-Tier1",
    },
};

local ICON_SET_NAMES = {
    coins      = "Coins (Gold/Silver/Copper)",
    checkmarks = "Checkmarks",
    quality    = "Crafting Quality",
};

local ICON_SET_SORTING = { "coins", "checkmarks", "quality" };

-------------------------------------------------------------------------------
-- Rating function
-------------------------------------------------------------------------------

local function GetTipperRating(personalAvgTip, personalCount, thresholds, ratingOverride)
    -- Manual override takes priority
    if (ratingOverride == "good" or ratingOverride == "bad") then
        return ratingOverride;
    end
    -- No personal orders = unknown (neutral)
    if (personalCount == 0) then return "neutral"; end
    -- Threshold-based
    if (personalAvgTip <= thresholds.bad) then return "bad"; end
    if (personalAvgTip >= thresholds.good) then return "good"; end
    return "neutral";
end

-------------------------------------------------------------------------------
-- Icon helpers
-------------------------------------------------------------------------------

local function GetIconSet(db)
    local setName = db.tipperIconSet or "coins";
    return ICON_SETS[setName] or ICON_SETS.coins;
end

local function GetTipperAtlas(rating, db)
    local set = GetIconSet(db);
    return set[rating] or set.neutral;
end

local function GetTipperMarkup(rating, db, fontSize)
    local atlas = GetTipperAtlas(rating, db);
    local size = fontSize or 13;
    return CreateAtlasMarkup(atlas, size, size);
end

-------------------------------------------------------------------------------
-- Export to addon namespace
-------------------------------------------------------------------------------

ns.TipperRating = {
    GetTipperRating   = GetTipperRating,
    GetIconSet        = GetIconSet,
    GetTipperAtlas    = GetTipperAtlas,
    GetTipperMarkup   = GetTipperMarkup,
    ICON_SETS         = ICON_SETS,
    ICON_SET_NAMES    = ICON_SET_NAMES,
    ICON_SET_SORTING  = ICON_SET_SORTING,
};
