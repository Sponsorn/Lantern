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

local UNLOCK_BACKDROP = {
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
    insets   = { left = 0, right = 0, top = 0, bottom = 0 },
};

local PAD = 6;

function LanternUX.MakeDraggable(frame, config)
    assert(frame and config, "MakeDraggable: frame and config required");
    assert(config.getPos and config.setPos and config.getLocked, "MakeDraggable: getPos, setPos, getLocked required");
    assert(config.defaultPoint, "MakeDraggable: defaultPoint required");

    local dp = config.defaultPoint;

    -- Store original size so we can add/remove padding on lock toggle
    local baseW, baseH = frame:GetSize();

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
                config.text:SetText(config.placeholder);
                config.text:SetTextColor(T.textDim[1], T.textDim[2], T.textDim[3], 1);
            end
            self:SetAlpha(1);
            self:Show();
        else
            self:SetSize(baseW, baseH);
            self:SetBackdrop(nil);
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
