local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end

local UX = Lantern.UX;
if (not UX) then return; end

local module = Lantern.modules["SummonHelper"];
if (not module) then return; end
local L = Lantern.L;

local moduleEnabled = Lantern.moduleEnabled;
local moduleToggle = Lantern.moduleToggle;

module.widgetOptions = function()
    local function db()
        if (not Lantern.db) then Lantern.db = {}; end
        if (not Lantern.db.summonHelper) then Lantern.db.summonHelper = {}; end
        local d = Lantern.db.summonHelper;
        local defaults = {
            showPortalPlaced = true,
            showSummonStarted = true,
            showRoster = true,
            rosterInstanceOnly = false,
            rosterRequireWarlock = false,
            soundEnabled = false,
            soundName = "RaidWarning",
            locked = true,
            notifFont = "Roboto Extra Bold",
            notifFontSize = 18,
            notifFontOutline = "OUTLINE",
            notifDuration = 4,
            notifLocked = true,
            portalPlacedText = "%s placed a summoning portal!",
            summoningText = "%s received a summon!",
            acceptedText = "%s accepted the summon.",
            declinedText = "%s declined the summon.",
            rosterFont = "Roboto Light",
            rosterFontSize = 12,
        };
        for k, v in pairs(defaults) do
            if (d[k] == nil) then d[k] = v; end
        end
        return d;
    end

    local isDisabled = function()
        return not moduleEnabled("SummonHelper");
    end

    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true);

    local function getFontValues()
        local fonts = {};
        if (LSM) then
            for _, name in ipairs(LSM:List("font") or {}) do
                fonts[name] = name;
            end
        end
        if (not fonts["Roboto Light"]) then
            fonts["Roboto Light"] = "Roboto Light";
        end
        if (not fonts["Roboto Extra Bold"]) then
            fonts["Roboto Extra Bold"] = "Roboto Extra Bold";
        end
        return fonts;
    end

    local outlineValues = {
        [""] = L["FONT_OUTLINE_NONE"],
        ["OUTLINE"] = L["FONT_OUTLINE_OUTLINE"],
        ["THICKOUTLINE"] = L["FONT_OUTLINE_THICK"],
        ["MONOCHROME"] = L["FONT_OUTLINE_MONO"],
        ["OUTLINE, MONOCHROME"] = L["FONT_OUTLINE_OUTLINE_MONO"],
    };
    local outlineSorting = { "", "OUTLINE", "THICKOUTLINE", "MONOCHROME", "OUTLINE, MONOCHROME" };

    local function getSoundValues()
        if (Lantern.utils and Lantern.utils.RegisterMediaSounds) then
            Lantern.utils.RegisterMediaSounds(LSM);
        end
        local sounds = {};
        if (LSM) then
            for _, name in ipairs(LSM:List("sound") or {}) do
                sounds[name] = name;
            end
        end
        if (not sounds["RaidWarning"]) then
            sounds["RaidWarning"] = "RaidWarning";
        end
        return sounds;
    end

    return {
        moduleToggle("SummonHelper", L["ENABLE"], L["SUMMONHELPER_ENABLE_DESC"]),
        {
            type = "group",
            text = L["SUMMONHELPER_GROUP_CHAT"],
            expanded = true,
            children = {
                {
                    type = "toggle",
                    label = L["SUMMONHELPER_SHOW_PORTAL"],
                    desc = L["SUMMONHELPER_SHOW_PORTAL_DESC"],
                    disabled = isDisabled,
                    get = function() return db().showPortalPlaced; end,
                    set = function(val) db().showPortalPlaced = val; end,
                },
                {
                    type = "toggle",
                    label = L["SUMMONHELPER_SHOW_SUMMON"],
                    desc = L["SUMMONHELPER_SHOW_SUMMON_DESC"],
                    disabled = isDisabled,
                    get = function() return db().showSummonStarted; end,
                    set = function(val) db().showSummonStarted = val; end,
                },
            },
        },
        {
            type = "group",
            text = L["SUMMONHELPER_GROUP_NOTIF_TEXT"],
            children = {
                {
                    type = "input",
                    label = L["SUMMONHELPER_PORTAL_PLACED_TEXT"],
                    desc = L["SUMMONHELPER_PORTAL_PLACED_TEXT_DESC"],
                    disabled = isDisabled,
                    get = function() return db().portalPlacedText; end,
                    set = function(val) db().portalPlacedText = val; end,
                },
                {
                    type = "input",
                    label = L["SUMMONHELPER_SUMMONING_TEXT"],
                    desc = L["SUMMONHELPER_SUMMONING_TEXT_DESC"],
                    disabled = isDisabled,
                    get = function() return db().summoningText; end,
                    set = function(val) db().summoningText = val; end,
                },
                {
                    type = "input",
                    label = L["SUMMONHELPER_ACCEPTED_TEXT"],
                    desc = L["SUMMONHELPER_ACCEPTED_TEXT_DESC"],
                    disabled = isDisabled,
                    get = function() return db().acceptedText; end,
                    set = function(val) db().acceptedText = val; end,
                },
                {
                    type = "input",
                    label = L["SUMMONHELPER_DECLINED_TEXT"],
                    desc = L["SUMMONHELPER_DECLINED_TEXT_DESC"],
                    disabled = isDisabled,
                    get = function() return db().declinedText; end,
                    set = function(val) db().declinedText = val; end,
                },
            },
        },
        {
            type = "group",
            text = L["SUMMONHELPER_GROUP_NOTIF_STYLE"],
            children = {
                {
                    type = "select",
                    label = L["SHARED_FONT"],
                    values = getFontValues,
                    disabled = isDisabled,
                    get = function() return db().notifFont or "Roboto Extra Bold"; end,
                    set = function(val)
                        db().notifFont = val;
                        if (module.RefreshNotifFont) then module:RefreshNotifFont(); end
                    end,
                },
                {
                    type = "range",
                    label = L["SHARED_FONT_SIZE"],
                    min = 10, max = 36, step = 1, default = 18,
                    disabled = isDisabled,
                    get = function() return db().notifFontSize; end,
                    set = function(val)
                        db().notifFontSize = val;
                        if (module.RefreshNotifFont) then module:RefreshNotifFont(); end
                    end,
                },
                {
                    type = "select",
                    label = L["SHARED_FONT_OUTLINE"],
                    values = outlineValues,
                    sorting = outlineSorting,
                    disabled = isDisabled,
                    get = function() return db().notifFontOutline or "OUTLINE"; end,
                    set = function(val)
                        db().notifFontOutline = val;
                        if (module.RefreshNotifFont) then module:RefreshNotifFont(); end
                    end,
                },
                {
                    type = "range",
                    label = L["SUMMONHELPER_NOTIF_DURATION"],
                    desc = L["SUMMONHELPER_NOTIF_DURATION_DESC"],
                    min = 1, max = 10, step = 0.5, default = 4,
                    disabled = isDisabled,
                    get = function() return db().notifDuration; end,
                    set = function(val) db().notifDuration = val; end,
                },
            },
        },
        {
            type = "group",
            text = L["SUMMONHELPER_GROUP_NOTIF_POSITION"],
            children = {
                {
                    type = "toggle",
                    label = L["SHARED_LOCK_POSITION"],
                    disabled = isDisabled,
                    get = function() return db().notifLocked; end,
                    set = function(val)
                        db().notifLocked = val;
                        if (module.UpdateNotifLock) then module:UpdateNotifLock(); end
                    end,
                },
                {
                    type = "execute",
                    label = L["SHARED_RESET_POSITION"],
                    disabled = isDisabled,
                    func = function()
                        if (module.ResetNotifPosition) then module:ResetNotifPosition(); end
                    end,
                },
            },
        },
        {
            type = "group",
            text = L["SUMMONHELPER_GROUP_ROSTER"],
            expanded = true,
            children = {
                {
                    type = "toggle",
                    label = L["RAIDROSTER_TITLE"],
                    desc = L["RAIDROSTER_DESC"],
                    disabled = isDisabled,
                    get = function() return db().showRoster; end,
                    set = function(val) db().showRoster = val; end,
                },
                {
                    type = "toggle",
                    label = L["SUMMONHELPER_INSTANCE_ONLY"],
                    desc = L["SUMMONHELPER_INSTANCE_ONLY_DESC"],
                    disabled = function() return isDisabled() or not db().showRoster; end,
                    get = function() return db().rosterInstanceOnly; end,
                    set = function(val) db().rosterInstanceOnly = val; end,
                },
                {
                    type = "toggle",
                    label = L["SUMMONHELPER_REQUIRE_WARLOCK"],
                    desc = L["SUMMONHELPER_REQUIRE_WARLOCK_DESC"],
                    disabled = function() return isDisabled() or not db().showRoster; end,
                    get = function() return db().rosterRequireWarlock; end,
                    set = function(val) db().rosterRequireWarlock = val; end,
                },
                {
                    type = "select",
                    label = L["SHARED_FONT"],
                    values = getFontValues,
                    disabled = function() return isDisabled() or not db().showRoster; end,
                    get = function() return db().rosterFont or "Roboto Light"; end,
                    set = function(val)
                        db().rosterFont = val;
                        if (module.RefreshRosterFont) then module:RefreshRosterFont(); end
                    end,
                },
                {
                    type = "range",
                    label = L["SHARED_FONT_SIZE"],
                    min = 8, max = 20, step = 1, default = 12,
                    disabled = function() return isDisabled() or not db().showRoster; end,
                    get = function() return db().rosterFontSize; end,
                    set = function(val)
                        db().rosterFontSize = val;
                        if (module.RefreshRosterFont) then module:RefreshRosterFont(); end
                    end,
                },
            },
        },
        {
            type = "group",
            text = L["SHARED_GROUP_SOUND"],
            children = {
                {
                    type = "toggle",
                    label = L["SHARED_PLAY_SOUND"],
                    desc = L["COMBATALERT_PLAY_SOUND_DESC"],
                    disabled = isDisabled,
                    get = function() return db().soundEnabled; end,
                    set = function(val) db().soundEnabled = val; end,
                },
                {
                    type = "select",
                    label = L["SHARED_SOUND_SELECT"],
                    desc = L["COMBATALERT_SOUND_SELECT_DESC"],
                    values = getSoundValues,
                    disabled = function() return isDisabled() or not db().soundEnabled; end,
                    get = function() return db().soundName or "RaidWarning"; end,
                    set = function(val) db().soundName = val; end,
                    preview = function(key)
                        if (not LSM) then return; end
                        local sound = LSM:Fetch("sound", key);
                        if (sound) then pcall(PlaySoundFile, sound, "Master"); end
                    end,
                },
            },
        },
        {
            type = "group",
            text = L["SUMMONHELPER_GROUP_ROSTER_POSITION"],
            children = {
                {
                    type = "toggle",
                    label = L["SHARED_LOCK_POSITION"],
                    desc = L["COMBATALERT_LOCK_POSITION_DESC"],
                    disabled = isDisabled,
                    get = function() return db().locked; end,
                    set = function(val)
                        db().locked = val;
                        if (module.UpdateLock) then module:UpdateLock(); end
                    end,
                },
                {
                    type = "execute",
                    label = L["SHARED_RESET_POSITION"],
                    desc = L["COMBATALERT_RESET_POSITION_DESC"],
                    disabled = isDisabled,
                    func = function()
                        if (module.ResetPosition) then module:ResetPosition(); end
                    end,
                },
            },
        },
    };
end
