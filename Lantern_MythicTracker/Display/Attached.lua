local ADDON_NAME, NS = ...;
local ST = NS.SpellTracker;
if (not ST) then return; end

-------------------------------------------------------------------------------
-- Attached mode — per-player containers on party frames
-------------------------------------------------------------------------------

function ST._GetOrCreateAttachedContainer(categoryKey, unitToken, parentFrame)
    if (not ST.attachedContainers[categoryKey]) then
        ST.attachedContainers[categoryKey] = {};
    end

    local existing = ST.attachedContainers[categoryKey][unitToken];
    if (existing and existing.frame) then
        return existing;
    end

    local catDB = ST:GetCategoryDB(categoryKey);
    local iconSize = catDB.iconSize;

    -- Parent to UIParent to avoid secure frame taint
    local container = CreateFrame("Frame", ST._FrameName("AttachedContainer"), UIParent);
    container:SetSize(iconSize, iconSize);
    container:SetFrameStrata("MEDIUM");
    container:SetFrameLevel(parentFrame:GetFrameLevel() + 10);

    -- Icon pool
    local iconPool = {};
    for i = 1, ST._ATTACHED_ICON_POOL_SIZE do
        iconPool[i] = ST._CreateSpellIcon(container, iconSize);
    end

    local entry = {
        frame    = container,
        iconPool = iconPool,
    };
    ST.attachedContainers[categoryKey][unitToken] = entry;
    return entry;
end

-------------------------------------------------------------------------------
-- Grow direction resolution
--
-- The grow direction controls which way icons extend from the anchor point.
-- It can be set explicitly ("left"/"right"/"up"/"down") or auto-derived
-- from the anchor name: LEFT-side anchors default to "left", RIGHT-side
-- to "right", TOP (without LEFT/RIGHT) to "up", BOTTOM to "down".
--
-- Each direction maps to (growLeft, growUp) which determines:
--   1. The container's attach corner (opposite of grow direction)
--   2. Which way icons fill within the container
-------------------------------------------------------------------------------

local GROW_MAP = {
    left  = { growLeft = true,  growUp = false },
    right = { growLeft = false, growUp = false },
    up    = { growLeft = false, growUp = true  },
    down  = { growLeft = false, growUp = false },
};

local function ResolveGrow(catDB)
    local grow = catDB.attachGrow;
    if (not grow) then
        local anchor = catDB.attachAnchor or "RIGHT";
        if (anchor:find("LEFT")) then
            grow = "left";
        elseif (anchor:find("RIGHT")) then
            grow = "right";
        elseif (anchor == "TOP") then
            grow = "up";
        elseif (anchor == "BOTTOM") then
            grow = "down";
        else
            grow = "right";
        end
    end
    return grow;
end

local function GetGrowDirections(catDB)
    local grow = ResolveGrow(catDB);
    local dir = GROW_MAP[grow] or GROW_MAP.right;
    return dir.growLeft, dir.growUp;
end

-- Container attach point derived from grow direction.
-- The container's origin corner (opposite of grow direction) touches the
-- party frame's anchor point, so the icons extend outward.
local function GetContainerPoint(growLeft, growUp)
    if (growLeft and growUp) then return "BOTTOMRIGHT"; end
    if (growLeft)            then return "TOPRIGHT"; end
    if (growUp)              then return "BOTTOMLEFT"; end
    return "TOPLEFT";
end

function ST._AnchorAttachedContainer(container, parentFrame, catDB)
    container.frame:ClearAllPoints();
    local anchor = catDB.attachAnchor or "RIGHT";
    local ox = catDB.attachOffsetX or 2;
    local oy = catDB.attachOffsetY or 0;
    local growLeft, growUp = GetGrowDirections(catDB);
    local containerPoint = GetContainerPoint(growLeft, growUp);

    -- No sign flipping — positive X = right, positive Y = up, always.
    container.frame:SetPoint(containerPoint, parentFrame, anchor, ox, oy);
end

function ST._RenderAttachedCategory(categoryKey)
    local catDB = ST:GetCategoryDB(categoryKey);
    local filter = catDB.filter or (ST:GetCategory(categoryKey) and ST:GetCategory(categoryKey).defaultFilter) or "all";
    local iconSize = catDB.iconSize;
    local spacing = catDB.iconSpacing;
    local nameToUnit = ST._BuildNameToUnitMap();
    local now = GetTime();

    -- Track which units we rendered so we can hide the rest
    local renderedUnits = {};

    for playerName, player in pairs(ST.trackedPlayers) do
        local isSelf = (playerName == ST.playerName);
        if (isSelf and not catDB.showSelf) then
            -- skip self
        else
            -- Collect this player's spells for this category
            local spells = ST._CollectPlayerCategorySpells(player, categoryKey, filter, catDB);

            if (#spells > 0) then
                local unitToken = nameToUnit[playerName];
                if (unitToken) then
                    local partyFrame = ST._GetPartyMemberFrame(unitToken);
                    if (partyFrame) then
                        renderedUnits[unitToken] = true;
                        local container = ST._GetOrCreateAttachedContainer(categoryKey, unitToken, partyFrame);

                        -- Re-anchor (party frames can move)
                        ST._AnchorAttachedContainer(container, partyFrame, catDB);

                        -- Resize icons to match current setting
                        for _, ico in ipairs(container.iconPool) do
                            ico:SetSize(iconSize, iconSize);
                            ico:Hide();
                        end

                        -- Render spell icons
                        local growLeft, growUp = GetGrowDirections(catDB);
                        local vertical = (catDB.attachOrientation == "vertical");
                        local maxPer = catDB.attachMaxPerRow or 6;
                        local primary = 0;   -- index along primary axis
                        local secondary = 0; -- index along wrap axis
                        for idx, spell in ipairs(spells) do
                            if (idx > ST._ATTACHED_ICON_POOL_SIZE) then break; end
                            local ico = container.iconPool[idx];
                            ico:ClearAllPoints();

                            local col, row;
                            if (vertical) then
                                col = secondary;
                                row = primary;
                            else
                                col = primary;
                                row = secondary;
                            end

                            local x = col * (iconSize + spacing);
                            local y = row * (iconSize + spacing);
                            local xSign = growLeft and -1 or 1;
                            local ySign = growUp and 1 or -1;
                            if (growLeft and growUp) then
                                ico:SetPoint("BOTTOMRIGHT", x * xSign, y * ySign);
                            elseif (growLeft) then
                                ico:SetPoint("TOPRIGHT", x * xSign, y * ySign);
                            elseif (growUp) then
                                ico:SetPoint("BOTTOMLEFT", x * xSign, y * ySign);
                            else
                                ico:SetPoint("TOPLEFT", x * xSign, y * ySign);
                            end

                            ST._ApplyIconState(ico, spell.state, spell.spellID, spell.cdEnd, spell.activeEnd, spell.baseCd, now);

                            ico:Show();
                            primary = primary + 1;
                            if (primary >= maxPer) then
                                primary = 0;
                                secondary = secondary + 1;
                            end
                        end

                        -- Resize container to fit icons
                        local numIcons = math.min(#spells, ST._ATTACHED_ICON_POOL_SIZE);
                        if (numIcons > 0) then
                            local primaryCount = math.min(numIcons, maxPer);
                            local secondaryCount = math.ceil(numIcons / maxPer);
                            local cols, rows;
                            if (vertical) then
                                cols = secondaryCount;
                                rows = primaryCount;
                            else
                                cols = primaryCount;
                                rows = secondaryCount;
                            end
                            container.frame:SetSize(
                                cols * (iconSize + spacing) - spacing,
                                rows * (iconSize + spacing) - spacing
                            );
                        end
                        container.frame:Show();
                    end
                end
            end
        end
    end

    -- Hide containers for units no longer shown
    if (ST.attachedContainers[categoryKey]) then
        for unitToken, container in pairs(ST.attachedContainers[categoryKey]) do
            if (not renderedUnits[unitToken] and container.frame) then
                container.frame:Hide();
            end
        end
    end
end

function ST._StackAttachedContainers()
    -- Group by unit + anchor so only same-anchor containers stack together
    local groups = {};  -- [unitToken.."|"..anchor] = { containers }

    for _, entry in ipairs(ST.categories) do
        local key = entry.key;
        local catDB = ST:GetCategoryDB(key);
        if (entry.config.enabled and catDB.attachMode == "party" and ST.attachedContainers[key]) then
            local anchor = catDB.attachAnchor or "RIGHT";
            local grow = ResolveGrow(catDB);
            for unitToken, container in pairs(ST.attachedContainers[key]) do
                if (container.frame and container.frame:IsShown()) then
                    local groupKey = unitToken .. "|" .. anchor .. "|" .. grow;
                    if (not groups[groupKey]) then
                        groups[groupKey] = {};
                    end
                    table.insert(groups[groupKey], {
                        key       = key,
                        container = container,
                        catDB     = catDB,
                    });
                end
            end
        end
    end

    -- Stack containers within each anchor group
    for _, containers in pairs(groups) do
        if (#containers > 1) then
            for i = 2, #containers do
                local prev = containers[i - 1];
                local curr = containers[i];

                local sp = curr.catDB.iconSpacing or 2;
                local gl, gu = GetGrowDirections(curr.catDB);

                curr.container.frame:ClearAllPoints();
                -- Stack along the grow direction (further outward from frame)
                if (gl and gu) then
                    curr.container.frame:SetPoint("BOTTOMRIGHT", prev.container.frame, "TOPLEFT", -sp, sp);
                elseif (gl) then
                    curr.container.frame:SetPoint("TOPRIGHT", prev.container.frame, "TOPLEFT", -sp, 0);
                elseif (gu) then
                    curr.container.frame:SetPoint("BOTTOMLEFT", prev.container.frame, "TOPLEFT", 0, sp);
                else
                    curr.container.frame:SetPoint("TOPLEFT", prev.container.frame, "TOPRIGHT", sp, 0);
                end
            end
        end
    end
end

function ST._HideAttachedContainers(categoryKey)
    if (categoryKey) then
        -- Hide containers for a specific category
        if (ST.attachedContainers[categoryKey]) then
            for _, container in pairs(ST.attachedContainers[categoryKey]) do
                if (container.frame) then container.frame:Hide(); end
            end
        end
    else
        -- Hide all attached containers
        for key, units in pairs(ST.attachedContainers) do
            for _, container in pairs(units) do
                if (container.frame) then container.frame:Hide(); end
            end
        end
    end
end

-- Public API (called by Options.lua)
function ST:HideAttachedContainers(categoryKey)
    ST._HideAttachedContainers(categoryKey);
end
