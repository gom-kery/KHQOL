local FBR = _G.ForeverBuffReminder

local MINIMAP_ICON_TEXTURE = "Interface\\AddOns\\ForeverBuffReminder\\Media\\ForeverBuffReminder-Minimap-BR.png"

local function createFrame(frameType, name, parent, template)
    if template then
        local ok, frame = pcall(CreateFrame, frameType, name, parent, template)
        if ok then return frame end
    end
    return CreateFrame(frameType, name, parent)
end

function FBR:CreateAlertUI()
    if self.anchor then return end
    local db = ForeverBuffReminderDB
    local anchor = createFrame("Frame", "ForeverBuffReminderAnchor", UIParent, "BackdropTemplate")
    anchor:SetSize(140, 36)
    anchor:SetPoint(db.position.point, UIParent, db.position.point, db.position.x, db.position.y)
    anchor:SetMovable(true); anchor:EnableMouse(not db.locked); anchor:RegisterForDrag("LeftButton")
    anchor:SetScript("OnDragStart", anchor.StartMoving)
    anchor:SetScript("OnDragStop", function(frame)
        frame:StopMovingOrSizing()
        local point, _, _, x, y = frame:GetPoint(1)
        db.position.point, db.position.x, db.position.y = point, math.floor(x + 0.5), math.floor(y + 0.5)
    end)
    if anchor.SetBackdrop then
        anchor:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12 })
        anchor:SetBackdropColor(0.15, 0.15, 0.15, 0.8); anchor:SetBackdropBorderColor(1, 0.72, 0.15, 1)
    end
    anchor.label = anchor:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    anchor.label:SetPoint("CENTER"); anchor.label:SetText("FBR 이동 위치")
    if db.locked then anchor:Hide() end
    self.anchor = anchor

    local container = CreateFrame("Frame", nil, UIParent)
    container:SetPoint("CENTER", anchor, "CENTER", 0, 0)
    container:SetSize(1, 1)
    self.alertContainer = container
    self.alertFrames = {}
end

function FBR:CreateMinimapButton()
    if self.minimapButton then return end

    local button = CreateFrame("Button", "ForeverBuffReminderMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -2, 2)
    button:SetFrameStrata("MEDIUM")
    button:RegisterForClicks("LeftButtonUp")
    button:SetNormalTexture(MINIMAP_ICON_TEXTURE)
    button:SetHighlightTexture(MINIMAP_ICON_TEXTURE, "ADD")
    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "LeftButton" then FBR:ToggleSettings() end
    end)
    button:SetScript("OnEnter", function(frame)
        GameTooltip:SetOwner(frame, "ANCHOR_LEFT")
        GameTooltip:SetText("ForeverBuffReminder")
        GameTooltip:AddLine("좌클릭: 설정창 열기", 1, 0.82, 0)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    self.minimapButton = button
end

function FBR:SetLocked(locked)
    ForeverBuffReminderDB.locked = locked
    self.anchor:EnableMouse(not locked)
    if locked then self.anchor:Hide() else self.anchor:Show() end
    if self.RefreshSettings then self:RefreshSettings() end
end

function FBR:CreateAlertFrame(index)
    local frame = createFrame("Frame", nil, self.alertContainer, "BackdropTemplate")
    frame:SetSize(self.DEFAULT_ICON_SIZE, self.DEFAULT_ICON_SIZE)
    frame.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetAllPoints(frame)
    -- Four plain outer lines avoid the nested decorative border of action-button art.
    frame.glowFrame = CreateFrame("Frame", nil, frame)
    frame.glowFrame:SetPoint("TOPLEFT", -4, 4); frame.glowFrame:SetPoint("BOTTOMRIGHT", 4, -4)
    frame.glowParts = {}
    local function addGlowEdge(pointA, pointB, width, height)
        local part = frame.glowFrame:CreateTexture(nil, "OVERLAY")
        part:SetColorTexture(1, 1, 1, 1)
        part:SetPoint(pointA, frame.glowFrame, pointA, 0, 0)
        part:SetPoint(pointB, frame.glowFrame, pointB, 0, 0)
        if width then part:SetWidth(width) end
        if height then part:SetHeight(height) end
        frame.glowParts[#frame.glowParts + 1] = part
    end
    addGlowEdge("TOPLEFT", "TOPRIGHT", nil, 3)
    addGlowEdge("BOTTOMLEFT", "BOTTOMRIGHT", nil, 3)
    addGlowEdge("TOPLEFT", "BOTTOMLEFT", 3, nil)
    addGlowEdge("TOPRIGHT", "BOTTOMRIGHT", 3, nil)
    frame.time = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    frame.time:SetPoint("CENTER", 0, -1); frame.time:SetTextColor(1, 1, 1, 1)
    frame.time:SetShadowOffset(1, -1)
    frame.glow = frame.glowFrame:CreateAnimationGroup()
    frame.glow:SetLooping("REPEAT")
    -- Explicit orders are required: animations with the same default order
    -- can run together and cancel each other's alpha, making the glow vanish.
    local fadeIn = frame.glow:CreateAnimation("Alpha"); fadeIn:SetOrder(1); fadeIn:SetFromAlpha(0.35); fadeIn:SetToAlpha(1); fadeIn:SetDuration(0.45); fadeIn:SetSmoothing("IN_OUT")
    local fadeOut = frame.glow:CreateAnimation("Alpha"); fadeOut:SetOrder(2); fadeOut:SetFromAlpha(1); fadeOut:SetToAlpha(0.35); fadeOut:SetDuration(0.45); fadeOut:SetSmoothing("IN_OUT")
    frame:Hide()
    self.alertFrames[index] = frame
    return frame
end

function FBR:ShowAlerts(alerts)
    local size = tonumber(ForeverBuffReminderDB.iconSize) or self.DEFAULT_ICON_SIZE
    local gap = 8
    local direction = ForeverBuffReminderDB.layoutDirection or "RIGHT"
    local horizontal = direction == "RIGHT" or direction == "LEFT"
    local availableSpace = horizontal and UIParent:GetWidth() or UIParent:GetHeight()
    local perLine = math.max(1, math.floor((availableSpace - 40) / (size + gap)))
    for index, alert in ipairs(alerts) do
        local frame = self.alertFrames[index] or self:CreateAlertFrame(index)
        local line, position = math.floor((index - 1) / perLine), (index - 1) % perLine
        local x, y
        if horizontal then
            x = (direction == "LEFT" and -position or position) * (size + gap)
            y = -line * (size + gap)
        else
            x = line * (size + gap)
            y = (direction == "UP" and position or -position) * (size + gap)
        end
        frame:ClearAllPoints(); frame:SetPoint("TOPLEFT", self.alertContainer, "CENTER", x, y)
        frame:SetSize(size, size); frame.icon:SetTexture(alert.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        local expiring = alert.state == "EXPIRING"
        local missing = alert.state == "MISSING"
        -- Missing buffs are intentionally quiet and grey. Only expiring buffs pulse.
        if frame.icon.SetDesaturated then frame.icon:SetDesaturated(missing) end
        frame.icon:SetVertexColor(missing and 0.62 or 1, missing and 0.62 or 1, missing and 0.62 or 1, 1)
        for _, part in ipairs(frame.glowParts) do part:SetColorTexture(1, 1, 1, 1) end
        frame.glowFrame:SetShown(expiring)
        frame.time:SetText(alert.state == "EXPIRING" and tostring(math.max(1, math.floor(alert.remaining or 0))) or "")
        frame:Show()
        if expiring and not frame.glow:IsPlaying() then frame.glow:Play()
        elseif not expiring and frame.glow:IsPlaying() then frame.glow:Stop() end
    end
    for index = #alerts + 1, #self.alertFrames do
        local frame = self.alertFrames[index]; frame:Hide(); if frame.glow:IsPlaying() then frame.glow:Stop() end
    end
    self:StartCountdownIfNeeded(alerts)
end
