local ADDON_NAME = ...;

-------------------------------------------------------------------------------
-- LanternUX.MakeDraggable
--
-- Turns a frame into a draggable, lockable display with position persistence.
-- The frame MUST inherit BackdropTemplate (pass it in CreateFrame).
--
-- Usage:
--   local frame = CreateFrame("Frame", "MyFrame", UIParent, "BackdropTemplate")
--   LanternUX.MakeDraggable(frame, {
--       getPos       = function() return db.pos end,
--       setPos       = function(pos) db.pos = pos end,
--       getLocked    = function() return db.locked end,
--       defaultPoint = { "CENTER", UIParent, "CENTER", 0, -100 },
--       text         = myFontString,   -- optional: FontString for placeholder
--       placeholder  = "0-40 yd",      -- optional: text shown when unlocked
--   })
--
-- Adds to frame:
--   frame:UpdateLock()      -- apply lock/unlock state (call after changing locked)
--   frame:RestorePosition() -- restore saved position from getPos()
--   frame:ResetPosition()   -- reset to defaultPoint and clear saved pos
-------------------------------------------------------------------------------

local T = LanternUX.Theme;

-- Registry of all draggable frames for auto-lock on panel close
local draggableFrames = {};

function LanternUX.LockAllDraggables()
    for _, entry in ipairs(draggableFrames) do
        local frame = entry.frame;
        local setLocked = entry.setLocked;
        local getLocked = entry.getLocked;
        if (not getLocked()) then
            setLocked(true);
            frame:UpdateLock();
        end
    end
end

local UNLOCK_BACKDROP = {
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
    insets   = { left = 0, right = 0, top = 0, bottom = 0 },
};

local PAD = 6;

function LanternUX.MakeDraggable(frame, config)
    assert(frame and config, "MakeDraggable: frame and config required");
    assert(config.getPos and config.setPos and config.getLocked and config.setLocked, "MakeDraggable: getPos, setPos, getLocked, setLocked required");
    assert(config.defaultPoint, "MakeDraggable: defaultPoint required");

    -- Register for auto-lock on panel close
    table.insert(draggableFrames, {
        frame = frame,
        getLocked = config.getLocked,
        setLocked = config.setLocked,
    });

    local dp = config.defaultPoint;

    -- Store original size so we can add/remove padding on lock toggle
    local baseW, baseH = frame:GetSize();

    -- "Unlocked" label (shown above frame when unlocked)
    local unlockLabel = frame:CreateFontString(nil, "OVERLAY");
    unlockLabel:SetFont(T.fontPathRegular, 10, "OUTLINE");
    unlockLabel:SetPoint("BOTTOM", frame, "TOP", 0, 4);
    unlockLabel:SetText("Unlocked - drag to move");
    unlockLabel:SetTextColor(T.accent[1], T.accent[2], T.accent[3], 0.8);
    unlockLabel:Hide();

    -- Base setup
    frame:SetMovable(true);
    frame:SetClampedToScreen(true);

    -- Drag handlers
    frame:SetScript("OnMouseDown", function(_, button)
        if (button == "LeftButton" and frame:IsMovable()) then
            frame:StartMoving();
        end
    end);

    frame:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing();
        local point, _, relPoint, x, y = frame:GetPoint();
        config.setPos({ point = point, relPoint = relPoint, x = x, y = y });
    end);

    -- Saved text state (captured on unlock, restored on lock)
    local savedText, savedR, savedG, savedB, savedA;

    -- UpdateLock: toggle movable state + backdrop visibility
    function frame:UpdateLock()
        local locked = config.getLocked();
        self:SetMovable(not locked);
        self:EnableMouse(not locked);

        if (not locked) then
            self:SetSize(baseW + PAD * 2, baseH + PAD * 2);
            self:SetBackdrop(UNLOCK_BACKDROP);
            self:SetBackdropColor(T.bg[1], T.bg[2], T.bg[3], 0.85);
            self:SetBackdropBorderColor(T.accent[1], T.accent[2], T.accent[3], 0.6);
            if (config.text and config.placeholder) then
                savedText = config.text:GetText();
                savedR, savedG, savedB, savedA = config.text:GetTextColor();
                config.text:SetText(config.placeholder);
                config.text:SetTextColor(T.textDim[1], T.textDim[2], T.textDim[3], 1);
            end
            unlockLabel:Show();
            self:SetAlpha(1);
            self:Show();
        else
            self:SetSize(baseW, baseH);
            self:SetBackdrop(nil);
            if (config.text and savedText) then
                config.text:SetText(savedText);
                config.text:SetTextColor(savedR, savedG, savedB, savedA);
            end
            unlockLabel:Hide();
        end
    end

    -- RestorePosition: apply saved position from DB
    function frame:RestorePosition()
        local pos = config.getPos();
        if (not pos) then return; end
        self:ClearAllPoints();
        self:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y);
    end

    -- ResetPosition: revert to default and clear saved pos
    function frame:ResetPosition()
        self:ClearAllPoints();
        self:SetPoint(dp[1], dp[2], dp[3], dp[4], dp[5]);
        config.setPos(nil);
    end
end
