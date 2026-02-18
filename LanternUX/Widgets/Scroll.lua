local ADDON_NAME = ...;

-------------------------------------------------------------------------------
-- Scroll container (fully standalone, no _W dependency)
-------------------------------------------------------------------------------

local SCROLL_STEP           = 40;
local SCROLL_BLEND          = 0.15;
local SCROLL_SNAP_THRESHOLD = 0.5;

local scrollCounter = 0;
local function NextScrollName(prefix)
    scrollCounter = scrollCounter + 1;
    return prefix .. scrollCounter;
end

local function CreateScrollContainer(parent)
    local container = {};
    local scrollTarget = 0;

    local scrollFrame = CreateFrame("ScrollFrame", NextScrollName("LUX_Scroll_"), parent);
    scrollFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0);
    scrollFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0);
    scrollFrame:EnableMouseWheel(true);

    local scrollChild = CreateFrame("Frame", NextScrollName("LUX_ScrollChild_"), scrollFrame);
    scrollChild:SetWidth(1);  -- set properly on render
    scrollFrame:SetScrollChild(scrollChild);

    -- Smooth scroll OnUpdate (set/removed dynamically)
    local function OnUpdate_SmoothScroll(self, elapsed)
        local current = self:GetVerticalScroll();
        local amount = math.min(1, SCROLL_BLEND * elapsed * 60);
        local newPos = current + (scrollTarget - current) * amount;

        local diff = math.abs(newPos - scrollTarget);
        if (diff < SCROLL_SNAP_THRESHOLD) then
            newPos = scrollTarget;
            self:SetScript("OnUpdate", nil);
        end

        self:SetVerticalScroll(newPos);
        container:UpdateThumb();
    end

    -- Mouse wheel scrolling
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local maxScroll = self:GetVerticalScrollRange();
        scrollTarget = scrollTarget - (delta * SCROLL_STEP);
        scrollTarget = math.max(0, math.min(scrollTarget, maxScroll));
        self:SetScript("OnUpdate", OnUpdate_SmoothScroll);
    end);

    -- Scrollbar track (wider hit area for clicking, narrow visual)
    local track = CreateFrame("Frame", NextScrollName("LUX_ScrollTrack_"), scrollFrame);
    track:SetWidth(12);
    track:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", 0, -2);
    track:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", 0, 2);
    track:EnableMouse(true);
    local trackBg = track:CreateTexture(nil, "BACKGROUND");
    trackBg:SetWidth(4);
    trackBg:SetPoint("TOP");
    trackBg:SetPoint("BOTTOM");
    trackBg:SetPoint("RIGHT", -2, 0);
    trackBg:SetColorTexture(0.14, 0.14, 0.16, 0.3);
    track:Hide();

    -- Scrollbar thumb (wider hit area, narrow visual)
    local thumb = CreateFrame("Frame", NextScrollName("LUX_ScrollThumb_"), track);
    thumb:SetWidth(12);
    thumb:EnableMouse(true);
    thumb:SetMovable(true);
    local thumbBg = thumb:CreateTexture(nil, "ARTWORK");
    thumbBg:SetWidth(4);
    thumbBg:SetPoint("TOP");
    thumbBg:SetPoint("BOTTOM");
    thumbBg:SetPoint("RIGHT", -2, 0);
    thumbBg:SetColorTexture(0.40, 0.40, 0.44, 0.6);
    thumb:Hide();

    -- Thumb drag
    local isDragging = false;
    local dragStartY, dragStartScroll;

    thumb:SetScript("OnMouseDown", function(_, button)
        if (button ~= "LeftButton") then return; end
        isDragging = true;
        dragStartY = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale();
        dragStartScroll = scrollFrame:GetVerticalScroll();
    end);

    thumb:SetScript("OnMouseUp", function()
        isDragging = false;
    end);

    -- Also stop drag if mouse is released outside the thumb
    scrollFrame:HookScript("OnMouseUp", function()
        isDragging = false;
    end);
    track:SetScript("OnMouseUp", function()
        isDragging = false;
    end);

    thumb:SetScript("OnUpdate", function()
        if (not isDragging) then return; end
        local cursorY = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale();
        local deltaY = dragStartY - cursorY;
        local trackHeight = track:GetHeight();
        local thumbHeight = thumb:GetHeight();
        local scrollRange = scrollFrame:GetVerticalScrollRange();
        if (trackHeight <= thumbHeight or scrollRange <= 0) then return; end
        local scrollPerPixel = scrollRange / (trackHeight - thumbHeight);
        local newScroll = math.max(0, math.min(dragStartScroll + deltaY * scrollPerPixel, scrollRange));
        scrollTarget = newScroll;
        scrollFrame:SetVerticalScroll(newScroll);
        container:UpdateThumb();
    end);

    -- Track click to jump
    track:SetScript("OnMouseDown", function(_, button)
        if (button ~= "LeftButton") then return; end
        local cursorY = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale();
        local trackTop = track:GetTop();
        local trackHeight = track:GetHeight();
        if (not trackTop or trackHeight <= 0) then return; end
        local clickRatio = (trackTop - cursorY) / trackHeight;
        clickRatio = math.max(0, math.min(clickRatio, 1));
        local scrollRange = scrollFrame:GetVerticalScrollRange();
        scrollTarget = clickRatio * scrollRange;
        scrollFrame:SetScript("OnUpdate", OnUpdate_SmoothScroll);
    end);

    container.scrollFrame = scrollFrame;
    container.scrollChild = scrollChild;
    container.track = track;
    container.thumb = thumb;

    function container:UpdateThumb()
        local visibleHeight = self.scrollFrame:GetHeight();
        local contentHeight = self.scrollChild:GetHeight();

        if (contentHeight <= visibleHeight or contentHeight <= 0) then
            self.track:Hide();
            self.thumb:Hide();
            return;
        end

        self.track:Show();
        self.thumb:Show();

        local trackHeight = self.track:GetHeight();
        local thumbHeight = math.max(20, (visibleHeight / contentHeight) * trackHeight);
        self.thumb:SetHeight(thumbHeight);

        local scrollRange = self.scrollFrame:GetVerticalScrollRange();
        local currentScroll = self.scrollFrame:GetVerticalScroll();
        local scrollRatio = (scrollRange > 0) and (currentScroll / scrollRange) or 0;
        local thumbOffset = scrollRatio * (trackHeight - thumbHeight);

        self.thumb:ClearAllPoints();
        self.thumb:SetPoint("TOPLEFT", self.track, "TOPLEFT", 0, -thumbOffset);
    end

    function container:SetContentHeight(height)
        self.scrollChild:SetHeight(height);
        self.scrollFrame:SetVerticalScroll(0);
        scrollTarget = 0;
        self.scrollFrame:SetScript("OnUpdate", nil);
        -- Defer thumb update to next frame (dimensions need to settle)
        C_Timer.After(0, function()
            self:UpdateThumb();
        end);
    end

    function container:UpdateContentHeight(height)
        self.scrollChild:SetHeight(height);
        -- Clamp current scroll to new range
        local visibleHeight = self.scrollFrame:GetHeight();
        local maxScroll = math.max(0, height - visibleHeight);
        local current = math.min(self.scrollFrame:GetVerticalScroll(), maxScroll);
        self.scrollFrame:SetVerticalScroll(current);
        scrollTarget = current;
        self.scrollFrame:SetScript("OnUpdate", nil);
        C_Timer.After(0, function()
            self:UpdateThumb();
        end);
    end

    function container:ScrollToY(targetY)
        local visibleHeight = self.scrollFrame:GetHeight();
        local contentHeight = self.scrollChild:GetHeight();
        local maxScroll = math.max(0, contentHeight - visibleHeight);
        -- Position target at ~30% from top of visible area
        local desired = math.max(0, targetY - visibleHeight * 0.3);
        scrollTarget = math.min(desired, maxScroll);
        self.scrollFrame:SetScript("OnUpdate", OnUpdate_SmoothScroll);
    end

    function container:Reset()
        self.scrollFrame:SetVerticalScroll(0);
        scrollTarget = 0;
        self.scrollFrame:SetScript("OnUpdate", nil);
        self.track:Hide();
        self.thumb:Hide();
    end

    function container:RestoreScroll(pos)
        local maxScroll = self.scrollFrame:GetVerticalScrollRange();
        local clamped = math.min(pos, math.max(0, maxScroll));
        self.scrollFrame:SetVerticalScroll(clamped);
        scrollTarget = clamped;
        self.scrollFrame:SetScript("OnUpdate", nil);
        C_Timer.After(0, function()
            self:UpdateThumb();
        end);
    end

    return container;
end

-------------------------------------------------------------------------------
-- Export
-------------------------------------------------------------------------------

LanternUX.CreateScrollContainer = CreateScrollContainer;
