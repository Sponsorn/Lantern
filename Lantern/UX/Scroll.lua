local ADDON_NAME = ...;

-------------------------------------------------------------------------------
-- Scroll container (fully standalone, no _W dependency)
-------------------------------------------------------------------------------

local SCROLL_STEP           = 40;
local SCROLL_BLEND          = 0.15;
local SCROLL_SNAP_THRESHOLD = 0.5;

-- Scrollbar auto-hide
local SCROLLBAR_FADE_DELAY = 1.0;
local SCROLLBAR_FADE_BLEND = 0.12;
local SCROLLBAR_FADE_SNAP  = 0.02;

local T = LanternUX.Theme;

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
    trackBg:SetColorTexture(unpack(T.scrollTrack));
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
    thumbBg:SetColorTexture(unpack(T.scrollThumb));
    thumb:Hide();

    ---------------------------------------------------------------------------
    -- Scrollbar fade state
    ---------------------------------------------------------------------------

    local scrollbarAlpha = 0;
    local scrollbarTarget = 0;
    local scrollbarFadeTimer = nil;
    local contentNeedsScroll = false;

    local function OnUpdate_ScrollbarFade(_, elapsed)
        local step = math.min(1, SCROLLBAR_FADE_BLEND * elapsed * 60);
        scrollbarAlpha = scrollbarAlpha + (scrollbarTarget - scrollbarAlpha) * step;
        if (math.abs(scrollbarAlpha - scrollbarTarget) < SCROLLBAR_FADE_SNAP) then
            scrollbarAlpha = scrollbarTarget;
            track:SetScript("OnUpdate", nil);
            if (scrollbarAlpha <= 0) then
                track:Hide();
                thumb:Hide();
            end
        end
        track:SetAlpha(scrollbarAlpha);
        thumb:SetAlpha(scrollbarAlpha);
    end

    local function ShowScrollbar()
        if (not contentNeedsScroll) then return; end
        scrollbarTarget = 1;
        -- Cancel any pending fade timer
        if (scrollbarFadeTimer) then scrollbarFadeTimer:Cancel(); scrollbarFadeTimer = nil; end
        -- Show at current alpha if hidden
        if (not track:IsShown()) then
            scrollbarAlpha = 0;
            track:SetAlpha(0);
            thumb:SetAlpha(0);
            track:Show();
            thumb:Show();
        end
        -- Start fade-in animation
        track:SetScript("OnUpdate", OnUpdate_ScrollbarFade);
        -- Schedule fade-out after delay
        scrollbarFadeTimer = C_Timer.NewTimer(SCROLLBAR_FADE_DELAY, function()
            scrollbarFadeTimer = nil;
            scrollbarTarget = 0;
            track:SetScript("OnUpdate", OnUpdate_ScrollbarFade);
        end);
    end
    container.ShowScrollbar = ShowScrollbar;

    ---------------------------------------------------------------------------
    -- Thumb drag
    ---------------------------------------------------------------------------

    local isDragging = false;
    local dragStartY, dragStartScroll;

    thumb:SetScript("OnMouseDown", function(_, button)
        if (button ~= "LeftButton") then return; end
        isDragging = true;
        dragStartY = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale();
        dragStartScroll = scrollFrame:GetVerticalScroll();
        -- Keep scrollbar visible during drag
        if (scrollbarFadeTimer) then scrollbarFadeTimer:Cancel(); scrollbarFadeTimer = nil; end
        scrollbarTarget = 1;
        scrollbarAlpha = 1;
        track:SetAlpha(1);
        thumb:SetAlpha(1);
        track:SetScript("OnUpdate", nil);
    end);

    thumb:SetScript("OnMouseUp", function()
        isDragging = false;
        ShowScrollbar();  -- restart fade timer
    end);

    -- Also stop drag if mouse is released outside the thumb
    scrollFrame:HookScript("OnMouseUp", function()
        if (isDragging) then
            isDragging = false;
            ShowScrollbar();
        end
    end);
    track:SetScript("OnMouseUp", function()
        isDragging = false;
        ShowScrollbar();
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

    -- Mouse wheel scrolling
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local maxScroll = self:GetVerticalScrollRange();
        scrollTarget = scrollTarget - (delta * SCROLL_STEP);
        scrollTarget = math.max(0, math.min(scrollTarget, maxScroll));
        self:SetScript("OnUpdate", OnUpdate_SmoothScroll);
        ShowScrollbar();
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
        ShowScrollbar();
    end);

    container.scrollFrame = scrollFrame;
    container.scrollChild = scrollChild;
    container.track = track;
    container.thumb = thumb;

    function container:UpdateThumb()
        local visibleHeight = self.scrollFrame:GetHeight();
        local contentHeight = self.scrollChild:GetHeight();

        if (contentHeight <= visibleHeight or contentHeight <= 0) then
            -- No scrolling needed — hide immediately
            contentNeedsScroll = false;
            if (scrollbarFadeTimer) then scrollbarFadeTimer:Cancel(); scrollbarFadeTimer = nil; end
            scrollbarTarget = 0;
            scrollbarAlpha = 0;
            self.track:Hide();
            self.thumb:Hide();
            self.track:SetScript("OnUpdate", nil);
            return;
        end

        contentNeedsScroll = true;

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
        -- Reset fade state
        if (scrollbarFadeTimer) then scrollbarFadeTimer:Cancel(); scrollbarFadeTimer = nil; end
        scrollbarTarget = 0;
        scrollbarAlpha = 0;
        self.track:Hide();
        self.thumb:Hide();
        self.track:SetScript("OnUpdate", nil);
        -- Defer thumb update to next frame (dimensions need to settle)
        C_Timer.After(0, function()
            self:UpdateThumb();
            -- Show scrollbar briefly if content is scrollable
            if (contentNeedsScroll) then
                ShowScrollbar();
            end
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
        ShowScrollbar();
    end

    function container:Reset()
        self.scrollFrame:SetVerticalScroll(0);
        scrollTarget = 0;
        self.scrollFrame:SetScript("OnUpdate", nil);
        -- Reset fade state
        if (scrollbarFadeTimer) then scrollbarFadeTimer:Cancel(); scrollbarFadeTimer = nil; end
        contentNeedsScroll = false;
        scrollbarTarget = 0;
        scrollbarAlpha = 0;
        self.track:Hide();
        self.thumb:Hide();
        self.track:SetScript("OnUpdate", nil);
    end

    function container:RestoreScroll(pos)
        local maxScroll = self.scrollFrame:GetVerticalScrollRange();
        local clamped = math.min(pos, math.max(0, maxScroll));
        self.scrollFrame:SetVerticalScroll(clamped);
        scrollTarget = clamped;
        self.scrollFrame:SetScript("OnUpdate", nil);
        C_Timer.After(0, function()
            self:UpdateThumb();
            if (contentNeedsScroll) then
                ShowScrollbar();
            end
        end);
    end

    return container;
end

-------------------------------------------------------------------------------
-- Export
-------------------------------------------------------------------------------

LanternUX.CreateScrollContainer = CreateScrollContainer;
