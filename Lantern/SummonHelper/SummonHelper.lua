local ADDON_NAME, Lantern = ...;
if (not Lantern) then return; end
local L = Lantern.L;

local UX = Lantern.UX;

local module = Lantern:NewModule("SummonHelper", {
    title = L["SUMMONHELPER_TITLE"],
    desc = L["SUMMONHELPER_DESC"],
    defaultEnabled = false,
});

local RITUAL_OF_SUMMONING = 698;
local PORTAL_DURATION = 120;
local POLL_INTERVAL = 2;

local DEFAULTS = {
    showPortalPlaced = true,
    showSummonStarted = true,
    showRoster = true,
    rosterInstanceOnly = false,
    rosterRequireWarlock = false,
    soundEnabled = false,
    soundName = "RaidWarning",
    locked = true,
    pos = nil,
    -- Notification banner
    notifFont = "Roboto Extra Bold",
    notifFontSize = 18,
    notifFontOutline = "OUTLINE",
    notifDuration = 4,
    notifLocked = true,
    notifPos = nil,
    portalPlacedText = "%s placed a summoning portal!",
    summoningText = "%s received a summon!",
    acceptedText = "%s accepted the summon.",
    declinedText = "%s declined the summon.",
    -- Roster
    rosterFont = "Roboto Light",
    rosterFontSize = 12,
};

local GetFontPath = Lantern.utils.GetFontPath;
local SafeSetFont = Lantern.utils.SafeSetFont;

local pendingSummons = {};
local portalExpiry = 0;
local lastOutside = {};
local ticker = nil;
local dismissedByUser = false;

-- Notification banner
local notifFrame, notifText;
local notifFlashAt, notifFadeDuration;

local function getNotifDB()
    return module.db or DEFAULTS;
end

local function createNotifBanner()
    if (notifFrame) then return; end

    local db = getNotifDB();

    notifFrame = CreateFrame("Frame", "Lantern_SummonNotif", UIParent);
    notifFrame:SetSize(400, 40);
    notifFrame:SetFrameStrata("HIGH");
    notifFrame:Hide();

    -- Restore saved position or default
    local pos = db.notifPos;
    if (pos) then
        notifFrame:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4]);
    else
        notifFrame:SetPoint("TOP", UIParent, "TOP", 0, -100);
    end

    notifText = notifFrame:CreateFontString("Lantern_SummonNotif_Text", "OVERLAY");
    SafeSetFont(notifText, GetFontPath(db.notifFont or "Roboto Extra Bold"), db.notifFontSize or 18, db.notifFontOutline or "OUTLINE");
    notifText:SetPoint("CENTER");
    notifText:SetShadowOffset(1, -1);
    notifText:SetShadowColor(0, 0, 0, 0.8);

    notifFrame:SetScript("OnUpdate", function()
        if (not notifFlashAt) then return; end
        local elapsed = GetTime() - notifFlashAt;
        local dur = notifFadeDuration or 4;
        if (elapsed >= dur) then
            notifFrame:Hide();
            notifFlashAt = nil;
            return;
        end
        local holdPortion = 0.6;
        local holdTime = dur * holdPortion;
        if (elapsed <= holdTime) then
            notifFrame:SetAlpha(1);
        else
            local fadeProgress = (elapsed - holdTime) / (dur - holdTime);
            notifFrame:SetAlpha(1 - fadeProgress);
        end
    end);
end

local function showNotification(text, r, g, b)
    createNotifBanner();
    local db = getNotifDB();
    notifText:SetText(text);
    notifText:SetTextColor(r or 1, g or 1, b or 1, 1);
    notifFadeDuration = db.notifDuration or 4;
    notifFlashAt = GetTime();
    notifFrame:SetAlpha(1);
    notifFrame:Show();
end

-- Roster frame
local rosterFrame, titleText, portalText, collapseIndicator;
local rows = {};
local MAX_ROWS = 40;
local rosterCollapsed = true;

local function hideRoster()
    if (rosterFrame and not InCombatLockdown()) then rosterFrame:Hide(); end
end

local function ensureDB(self)
    self.db = Lantern.utils.InitModuleDB(self.addon, "summonHelper", DEFAULTS);
end

local function createRosterFrame(self)
    if (rosterFrame) then return; end

    local T = UX and UX.Theme;

    rosterFrame = CreateFrame("Frame", "Lantern_SummonRoster", UIParent, "BackdropTemplate");
    rosterFrame:SetSize(230, 40);
    rosterFrame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    });
    if (T) then
        rosterFrame:SetBackdropColor(T.bg[1], T.bg[2], T.bg[3], 0.92);
        rosterFrame:SetBackdropBorderColor(T.border[1], T.border[2], T.border[3], 1);
    else
        rosterFrame:SetBackdropColor(0.06, 0.06, 0.07, 0.92);
        rosterFrame:SetBackdropBorderColor(0.18, 0.18, 0.20, 1);
    end
    rosterFrame:SetFrameStrata("MEDIUM");
    rosterFrame:Hide();

    local rosterFontName = self.db and self.db.rosterFont or "Roboto Light";
    local rosterFontSize = self.db and self.db.rosterFontSize or 12;

    titleText = rosterFrame:CreateFontString("Lantern_SummonRoster_Title", "OVERLAY");
    SafeSetFont(titleText, GetFontPath(rosterFontName), rosterFontSize + 1, "");
    titleText:SetPoint("TOP", 0, -6);
    titleText:SetText(L["RAIDROSTER_HEADER"]);
    if (T) then
        titleText:SetTextColor(T.accent[1], T.accent[2], T.accent[3]);
    else
        titleText:SetTextColor(0.88, 0.56, 0.18);
    end

    -- Collapse/expand indicator (right side of title)
    collapseIndicator = rosterFrame:CreateFontString("Lantern_SummonRoster_Collapse", "OVERLAY");
    SafeSetFont(collapseIndicator, GetFontPath(rosterFontName), rosterFontSize, "");
    collapseIndicator:SetPoint("RIGHT", rosterFrame, "RIGHT", -8, 0);
    collapseIndicator:SetPoint("TOP", 0, -6);
    if (T) then
        collapseIndicator:SetTextColor(T.textDim[1], T.textDim[2], T.textDim[3]);
    else
        collapseIndicator:SetTextColor(0.52, 0.52, 0.54);
    end
    collapseIndicator:SetText("+");

    portalText = rosterFrame:CreateFontString("Lantern_SummonRoster_Portal", "OVERLAY");
    SafeSetFont(portalText, GetFontPath(rosterFontName), rosterFontSize, "");
    portalText:SetTextColor(0.6, 0.2, 1);
    portalText:Hide();

    -- Title-bar drag handle (only the title area is draggable)
    local dragHandle = CreateFrame("Frame", "Lantern_SummonRoster_DragHandle", rosterFrame);
    dragHandle:SetPoint("TOPLEFT", rosterFrame, "TOPLEFT", 0, 0);
    dragHandle:SetPoint("TOPRIGHT", rosterFrame, "TOPRIGHT", 0, 0);
    dragHandle:SetHeight(22);

    rosterFrame:SetMovable(true);
    rosterFrame:SetClampedToScreen(true);

    dragHandle:EnableMouse(true);
    dragHandle:RegisterForDrag("LeftButton");
    dragHandle:SetScript("OnDragStart", function()
        if (module.db and not module.db.locked) then
            rosterFrame:StartMoving();
        end
    end);
    dragHandle:SetScript("OnDragStop", function()
        rosterFrame:StopMovingOrSizing();
        local point, _, relPoint, x, y = rosterFrame:GetPoint();
        if (module.db) then
            module.db.pos = { point = point, relPoint = relPoint, x = x, y = y };
        end
    end);

    -- Left-click title to toggle collapse, right-click to dismiss
    dragHandle:SetScript("OnMouseUp", function(_, button)
        if (button == "LeftButton" and module.db and module.db.locked) then
            rosterCollapsed = not rosterCollapsed;
            updateRosterDisplay(lastOutside);
        elseif (button == "RightButton" and module.db and module.db.locked) then
            dismissedByUser = true;
            hideRoster();
        end
    end);

    -- Tooltip hint
    dragHandle:SetScript("OnEnter", function(f)
        if (module.db and module.db.locked) then
            GameTooltip:SetOwner(f, "ANCHOR_BOTTOM");
            GameTooltip:AddLine("Left-click to expand/collapse", 0.7, 0.7, 0.7);
            GameTooltip:AddLine("Right-click to close", 0.7, 0.7, 0.7);
            GameTooltip:Show();
        end
    end);
    dragHandle:SetScript("OnLeave", function()
        GameTooltip:Hide();
    end);

    -- "Unlocked" label (shown above frame when unlocked)
    local unlockLabel = rosterFrame:CreateFontString("Lantern_SummonRoster_UnlockLabel", "OVERLAY");
    if (T) then
        unlockLabel:SetFont(T.fontPathRegular, 10, "OUTLINE");
        unlockLabel:SetTextColor(T.accent[1], T.accent[2], T.accent[3], 0.8);
    else
        unlockLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE");
        unlockLabel:SetTextColor(0.88, 0.56, 0.18, 0.8);
    end
    unlockLabel:SetPoint("BOTTOM", rosterFrame, "TOP", 0, 4);
    unlockLabel:SetText("Unlocked - drag to move");
    unlockLabel:Hide();

    -- Position/lock helpers (match MakeDraggable API used by WidgetOptions)
    function rosterFrame:UpdateLock()
        local locked = module.db and module.db.locked;
        rosterFrame:SetMovable(not locked);
        unlockLabel:SetShown(not locked);
    end

    function rosterFrame:RestorePosition()
        local pos = module.db and module.db.pos;
        if (not pos) then return; end
        self:ClearAllPoints();
        self:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y);
    end

    function rosterFrame:ResetPosition()
        self:ClearAllPoints();
        self:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -200, -200);
        if (module.db) then module.db.pos = nil; end
    end

    for i = 1, MAX_ROWS do
        local row = CreateFrame("Button", "Lantern_SummonRoster_Row_" .. i, rosterFrame, "SecureActionButtonTemplate");
        row:SetHeight(16);
        row:SetPoint("TOPLEFT", 8, -22 - (i - 1) * 16);
        row:SetPoint("RIGHT", rosterFrame, "RIGHT", -8, 0);
        row:RegisterForClicks("AnyUp");
        row:SetAttribute("type1", "target");

        row.text = row:CreateFontString(nil, "OVERLAY");
        SafeSetFont(row.text, GetFontPath(rosterFontName), rosterFontSize, "");
        row.text:SetAllPoints();
        row.text:SetJustifyH("LEFT");
        if (T) then
            row.text:SetTextColor(T.text[1], T.text[2], T.text[3]);
        end

        row.highlight = row:CreateTexture(nil, "HIGHLIGHT");
        row.highlight:SetAllPoints();
        row.highlight:SetColorTexture(1, 1, 1, 0.06);

        row:Hide();
        rows[i] = row;
    end
end

local function updateRosterDisplay(outside)
    if (not rosterFrame) then return; end

    local locked = InCombatLockdown();

    -- Secure rows can't be shown/hidden during combat — only update text
    if (not locked) then
        for i = 1, MAX_ROWS do
            rows[i]:Hide();
            rows[i]:SetAttribute("unit", nil);
        end
    end
    portalText:Hide();

    if (#outside == 0) then
        if (module.db and module.db.locked) then
            hideRoster();
        end
        return;
    end

    titleText:SetText(L["RAIDROSTER_HEADER"] .. " (" .. #outside .. ")");

    -- Update collapse indicator
    if (collapseIndicator) then
        collapseIndicator:SetText(rosterCollapsed and "+" or "-");
    end

    -- When collapsed, only show the title bar
    if (rosterCollapsed) then
        if (not locked) then
            rosterFrame:SetHeight(22);
        end
    else
        for i, info in ipairs(outside) do
            if (i > MAX_ROWS) then break; end
            local color = info.class and C_ClassColor.GetClassColor(info.class);
            local nameText = color and color:WrapTextInColorCode(info.name) or info.name;

            -- Append status indicator
            if (info.offline) then
                nameText = nameText .. "  |cff666666Offline|r";
            elseif (info.summonStatus == Enum.SummonStatus.Pending) then
                nameText = nameText .. "  |cffffcc00Summoning...|r";
            elseif (info.summonStatus == Enum.SummonStatus.Accepted) then
                nameText = nameText .. "  |cff00ff00Accepted|r";
            elseif (info.summonStatus == Enum.SummonStatus.Declined) then
                nameText = nameText .. "  |cffff2020Declined|r";
            end

            rows[i].text:SetText(nameText);
            if (not locked) then
                rows[i]:SetAttribute("unit", info.unit);
                rows[i]:Show();
            end
        end

        local rowCount = math.min(#outside, MAX_ROWS);
        local height = 28 + rowCount * 16;

        if (GetTime() < portalExpiry) then
            portalText:SetText(L["RAIDROSTER_PORTAL_UP"]);
            portalText:SetPoint("TOPLEFT", 8, -22 - rowCount * 16);
            portalText:Show();
            height = height + 18;
        end

        if (not locked) then
            rosterFrame:SetHeight(height);
        end
    end
    if (not dismissedByUser and not locked) then
        rosterFrame:Show();
    end
end

local function scanRoster(self)
    if (not self.enabled or not IsInRaid()) then
        hideRoster();
        return;
    end
    if (not self.db.showRoster) then
        hideRoster();
        return;
    end

    -- Only show inside raid instances if option is enabled
    if (self.db.rosterInstanceOnly) then
        local _, instanceType = GetInstanceInfo();
        if (instanceType ~= "raid") then
            hideRoster();
            return;
        end
    end

    -- Check if warlock is required and present
    if (self.db.rosterRequireWarlock) then
        local hasWarlock = false;
        for i = 1, GetNumGroupMembers() do
            local _, className = UnitClass("raid" .. i);
            if (className == "WARLOCK") then
                hasWarlock = true;
                break;
            end
        end
        if (not hasWarlock) then
            hideRoster();
            return;
        end
    end

    local playerMap = C_Map.GetBestMapForUnit("player");
    if (not playerMap) then return; end

    local outside = {};

    -- In mythic raids (difficultyID 16), only groups 1-4 matter (20 players)
    local _, _, difficultyID = GetInstanceInfo();
    local isMythicRaid = (difficultyID == 16);

    for i = 1, GetNumGroupMembers() do
        local unit = "raid" .. i;
        if (UnitExists(unit) and not UnitIsUnit(unit, "player")) then
            -- Skip players in groups 5+ for mythic raids
            local skip = false;
            if (isMythicRaid) then
                local _, _, subgroup = GetRaidRosterInfo(i);
                if (subgroup and subgroup > 4) then
                    skip = true;
                end
            end

            if (not skip) then
            local name = UnitName(unit);
            if (name and not issecretvalue(name)) then
                local connected = UnitIsConnected(unit);
                local memberMap = connected and C_Map.GetBestMapForUnit(unit) or nil;
                local isOutside = false;
                local isOffline = not connected;

                if (isOffline) then
                    isOutside = true;
                elseif (not memberMap) then
                    isOutside = true;
                elseif (not issecretvalue(memberMap) and memberMap ~= playerMap) then
                    isOutside = true;
                end

                if (isOutside) then
                    local _, className = UnitClass(unit);
                    local summonStatus = C_IncomingSummon.IncomingSummonStatus(unit);
                    table.insert(outside, {
                        name = name,
                        class = className,
                        unit = unit,
                        summonStatus = summonStatus,
                        offline = isOffline,
                    });
                end
            end
            end -- not skip
        end
    end

    lastOutside = outside;
    updateRosterDisplay(outside);
end

-- Summon tracking
local function getGroupPrefix()
    if (IsInRaid()) then return "raid", GetNumGroupMembers();
    elseif (IsInGroup()) then return "party", GetNumSubgroupMembers();
    end
    return nil, 0;
end

local function scanSummons(self)
    local prefix, count = getGroupPrefix();
    if (not prefix) then return; end

    for i = 1, count do
        local unit = prefix .. i;
        if (UnitExists(unit)) then
            local hasSum = C_IncomingSummon.HasIncomingSummon(unit);
            local status = C_IncomingSummon.IncomingSummonStatus(unit);

            if (hasSum and status == Enum.SummonStatus.Pending and not pendingSummons[unit]) then
                pendingSummons[unit] = true;
                local name = UnitName(unit);
                if (name and not issecretvalue(name)) then
                    if (self.db.showSummonStarted) then
                        local text = (self.db.summoningText or DEFAULTS.summoningText):format(name);
                        showNotification(text, 1, 0.8, 0);
                    end
                    -- Only announce if we initiated the summon (target matches)
                    if (self.db.soundEnabled) then
                        local LSM = LibStub and LibStub("LibSharedMedia-3.0", true);
                        if (LSM) then
                            local sound = LSM:Fetch("sound", self.db.soundName or "RaidWarning");
                            if (sound) then pcall(PlaySoundFile, sound, "Master"); end
                        end
                    end
                end
            elseif (not hasSum or status ~= Enum.SummonStatus.Pending) then
                if (pendingSummons[unit]) then
                    local name = UnitName(unit);
                    if (name and not issecretvalue(name)) then
                        if (status == Enum.SummonStatus.Accepted) then
                            local text = (self.db.acceptedText or DEFAULTS.acceptedText):format(name);
                            showNotification(text, 0.2, 1, 0.2);
                        elseif (status == Enum.SummonStatus.Declined) then
                            local text = (self.db.declinedText or DEFAULTS.declinedText):format(name);
                            showNotification(text, 1, 0.2, 0.2);
                        end
                    end
                end
                pendingSummons[unit] = nil;
            end
        end
    end
end

-- Preview mode: show fake data when unlocked for positioning
local PREVIEW_DATA = {
    { name = "Thunderstrike", class = "WARRIOR" },
    { name = "Moonweaver", class = "DRUID" },
    { name = "Shadowbind", class = "WARLOCK" },
    { name = "Holybright", class = "PALADIN" },
    { name = "Frostwhisper", class = "MAGE" },
};

local function showPreview()
    if (not rosterFrame) then return; end
    portalExpiry = GetTime() + 9999;
    updateRosterDisplay(PREVIEW_DATA);
end

local function hidePreview()
    portalExpiry = 0;
    updateRosterDisplay(lastOutside);
end


-- Public methods for settings
function module:RefreshNotifFont()
    if (not notifText) then return; end
    local db = getNotifDB();
    SafeSetFont(notifText, GetFontPath(db.notifFont or "Roboto Extra Bold"), db.notifFontSize or 18, db.notifFontOutline or "OUTLINE");
end

function module:RefreshRosterFont()
    if (not rosterFrame) then return; end
    local fontName = self.db and self.db.rosterFont or "Roboto Light";
    local fontSize = self.db and self.db.rosterFontSize or 12;
    SafeSetFont(titleText, GetFontPath(fontName), fontSize + 1, "");
    SafeSetFont(portalText, GetFontPath(fontName), fontSize, "");
    for i = 1, MAX_ROWS do
        SafeSetFont(rows[i].text, GetFontPath(fontName), fontSize, "");
    end
end

function module:UpdateNotifLock()
    createNotifBanner();
    local db = getNotifDB();
    if (db.notifLocked) then
        notifFrame:SetMovable(false);
        notifFrame:EnableMouse(false);
        notifFrame:SetScript("OnDragStart", nil);
        notifFrame:SetScript("OnDragStop", nil);
        -- Hide if not actively showing a notification
        if (not notifFlashAt) then notifFrame:Hide(); end
    else
        notifFrame:SetMovable(true);
        notifFrame:EnableMouse(true);
        notifFrame:RegisterForDrag("LeftButton");
        notifFrame:SetScript("OnDragStart", function(f) f:StartMoving(); end);
        notifFrame:SetScript("OnDragStop", function(f)
            f:StopMovingOrSizing();
            local point, _, _, x, y = f:GetPoint();
            if (module.db) then
                module.db.notifPos = { point, point, x, y };
            end
        end);
        -- Show preview text for positioning
        notifText:SetText("Summon notification preview");
        notifText:SetTextColor(1, 1, 1, 1);
        notifFlashAt = nil;
        notifFrame:SetAlpha(1);
        notifFrame:Show();
    end
end

function module:ResetNotifPosition()
    createNotifBanner();
    if (self.db) then self.db.notifPos = nil; end
    notifFrame:ClearAllPoints();
    notifFrame:SetPoint("TOP", UIParent, "TOP", 0, -100);
end

function module:UpdateLock()
    if (not rosterFrame) then return; end
    rosterFrame:UpdateLock();
    if (self.db and not self.db.locked) then
        showPreview();
    else
        hidePreview();
    end
end

function module:ResetPosition()
    if (not rosterFrame) then return; end
    rosterFrame:ResetPosition();
end

function module:OnInit()
    ensureDB(self);
end

function module:OnEnable()
    ensureDB(self);
    wipe(pendingSummons);
    createRosterFrame(self);
    if (self.db.pos) then
        rosterFrame:RestorePosition();
    else
        rosterFrame:ResetPosition();
    end
    rosterFrame:UpdateLock();

    -- Detect Ritual of Summoning cast
    self.addon:ModuleRegisterEvent(self, "UNIT_SPELLCAST_SUCCEEDED", function(_, event, unit, _, spellID)
        if (issecretvalue(spellID) or spellID ~= RITUAL_OF_SUMMONING) then return; end
        portalExpiry = GetTime() + PORTAL_DURATION;
        if (not IsShiftKeyDown() and self.db.showPortalPlaced) then
            local caster = UnitName(unit);
            if (caster and not issecretvalue(caster)) then
                local text = (self.db.portalPlacedText or DEFAULTS.portalPlacedText):format(caster);
                showNotification(text, 0.6, 0.2, 1);
            end
        end
        dismissedByUser = false; -- Portal cast: re-show roster
        updateRosterDisplay(lastOutside);
    end);

    -- Detect summon status changes
    self.addon:ModuleRegisterEvent(self, "INCOMING_SUMMON_CHANGED", function()
        scanSummons(self);
        scanRoster(self);
    end);

    -- Roster scanning
    local function startTicker()
        if (not ticker) then
            ticker = C_Timer.NewTicker(POLL_INTERVAL, function()
                scanRoster(self);
            end);
        end
    end

    local function stopTicker()
        if (ticker) then
            ticker:Cancel();
            ticker = nil;
        end
    end

    self.addon:ModuleRegisterEvent(self, "GROUP_ROSTER_UPDATE", function()
        if (IsInRaid()) then
            dismissedByUser = false;
            startTicker();
            scanRoster(self);
        else
            stopTicker();
            hideRoster();
        end
    end);

    self.addon:ModuleRegisterEvent(self, "ZONE_CHANGED_NEW_AREA", function()
        if (IsInRaid()) then scanRoster(self); end
    end);

    self.addon:ModuleRegisterEvent(self, "PLAYER_REGEN_DISABLED", function()
        stopTicker();
        hideRoster();
    end);

    self.addon:ModuleRegisterEvent(self, "PLAYER_REGEN_ENABLED", function()
        if (IsInRaid()) then
            startTicker();
            scanRoster(self);
        end
    end);

    -- Only start ticker if already in a raid
    if (IsInRaid()) then
        startTicker();
        scanRoster(self);
    end
end

function module:OnDisable()
    if (ticker) then ticker:Cancel(); ticker = nil; end
    hideRoster();
    wipe(pendingSummons);
    portalExpiry = 0;
end

Lantern:RegisterModule(module);
