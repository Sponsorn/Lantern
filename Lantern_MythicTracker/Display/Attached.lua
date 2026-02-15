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
    local container = CreateFrame("Frame", nil, UIParent);
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

function ST._AnchorAttachedContainer(container, parentFrame, catDB)
    container.frame:ClearAllPoints();
    local anchor = catDB.attachAnchor or "RIGHT";
    local ox = catDB.attachOffsetX or 2;
    local oy = catDB.attachOffsetY or 0;

    if (anchor == "LEFT") then
        container.frame:SetPoint("RIGHT", parentFrame, "LEFT", -ox, oy);
    elseif (anchor == "BOTTOM") then
        container.frame:SetPoint("TOP", parentFrame, "BOTTOM", ox, -oy);
    else  -- "RIGHT" (default)
        container.frame:SetPoint("LEFT", parentFrame, "RIGHT", ox, oy);
    end
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
            local spells = ST._CollectPlayerCategorySpells(player, categoryKey, filter);

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

                        -- Render spell icons (grow direction matches anchor side)
                        local anchor = catDB.attachAnchor or "RIGHT";
                        local growLeft = (anchor == "LEFT");
                        local x = 0;
                        for idx, spell in ipairs(spells) do
                            if (idx > ST._ATTACHED_ICON_POOL_SIZE) then break; end
                            local ico = container.iconPool[idx];
                            ico:ClearAllPoints();
                            if (growLeft) then
                                ico:SetPoint("TOPRIGHT", -x, 0);
                            else
                                ico:SetPoint("TOPLEFT", x, 0);
                            end

                            ST._ApplyIconState(ico, spell.state, spell.spellID, spell.cdEnd, spell.activeEnd, spell.baseCd, now);

                            ico:Show();
                            x = x + iconSize + spacing;
                        end

                        -- Resize container to fit icons
                        local numIcons = math.min(#spells, ST._ATTACHED_ICON_POOL_SIZE);
                        if (numIcons > 0) then
                            container.frame:SetSize(numIcons * (iconSize + spacing) - spacing, iconSize);
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
    -- Collect all attached category keys and group by anchor side
    local unitContainers = {};  -- [unitToken] = { { categoryKey, container }, ... }

    for _, entry in ipairs(ST.categories) do
        local key = entry.key;
        local catDB = ST:GetCategoryDB(key);
        if (entry.config.enabled and catDB.attachMode == "party" and ST.attachedContainers[key]) then
            for unitToken, container in pairs(ST.attachedContainers[key]) do
                if (container.frame and container.frame:IsShown()) then
                    if (not unitContainers[unitToken]) then
                        unitContainers[unitToken] = {};
                    end
                    table.insert(unitContainers[unitToken], {
                        key       = key,
                        container = container,
                        catDB     = catDB,
                    });
                end
            end
        end
    end

    -- Stack containers per unit
    for unitToken, containers in pairs(unitContainers) do
        if (#containers > 1) then
            local partyFrame = ST._GetPartyMemberFrame(unitToken);
            if (partyFrame) then
                -- First container anchors to party frame (already done), subsequent stack
                for i = 2, #containers do
                    local prev = containers[i - 1];
                    local curr = containers[i];
                    local growDir = curr.catDB.attachGrowDir or "DOWN";

                    local anchor = curr.catDB.attachAnchor or "RIGHT";
                    local sp = curr.catDB.iconSpacing or 2;

                    curr.container.frame:ClearAllPoints();
                    if (growDir == "RIGHT") then
                        if (anchor == "LEFT") then
                            curr.container.frame:SetPoint("TOPRIGHT", prev.container.frame, "TOPLEFT", -sp, 0);
                        else
                            curr.container.frame:SetPoint("TOPLEFT", prev.container.frame, "TOPRIGHT", sp, 0);
                        end
                    else  -- "DOWN"
                        if (anchor == "LEFT") then
                            curr.container.frame:SetPoint("TOPRIGHT", prev.container.frame, "BOTTOMRIGHT", 0, -sp);
                        else
                            curr.container.frame:SetPoint("TOPLEFT", prev.container.frame, "BOTTOMLEFT", 0, -sp);
                        end
                    end
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
