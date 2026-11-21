local FBR = _G.ForeverBuffReminder

local MINIMAP_ICON_TEXTURE = "Interface\\AddOns\\KHQOL\\Media\\kh-qol-minimap-button.tga"

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
    anchor:SetScript("OnDragStart",function(frame) frame.positionMoving=true;frame:StartMoving();self:RefreshAlerts() end)
    anchor:SetScript("OnDragStop", function(frame)
        frame:StopMovingOrSizing();frame.positionMoving=nil
        local point, _, _, x, y = frame:GetPoint(1)
        db.position.point, db.position.x, db.position.y = point, math.floor(x + 0.5), math.floor(y + 0.5)
        KHQOL.PositionStore:Committed()
        self:RefreshAlerts()
    end)
    if anchor.SetBackdrop then
        anchor:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12 })
        anchor:SetBackdropColor(0.15, 0.15, 0.15, 0.8); anchor:SetBackdropBorderColor(1, 0.72, 0.15, 1)
    end
    anchor.label = anchor:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    anchor.label:SetPoint("CENTER"); anchor.label:SetText("버프 유지 알림 · 이동")
    if db.locked then anchor:Hide() end
    self.anchor = anchor

    local container = CreateFrame("Frame", nil, UIParent)
    container:SetPoint("CENTER", anchor, "CENTER", 0, 0)
    container:SetSize(1, 1)
    self.alertContainer = container
    self.alertFrames = {}
    self.alertActions = {}
    local editor=KHQOL.PositionEditor
    for _,method in ipairs({"Enter","Finish"}) do
        hooksecurefunc(editor,method,function() self:RefreshAlerts() end)
    end
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
    self:RefreshAlerts()
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

function FBR:SyncAlertAction(index,alert,x,y,size,combat)
    local action=self.alertActions[index]
    local usable=alert and (alert.cast or alert.item) and x and ForeverBuffReminderDB.locked and not self.testMode
        and not KHQOL.PositionEditor.active and KHQOL.PublicCall(UnitIsDeadOrGhost,"player")==false
    if combat then
        if action and action.key then
            local matches=usable and not action.item and action.key==alert.key and action.cast==alert.cast and action.item==alert.item and action.unit==alert.castUnit
                and action.icon==alert.icon and action.x==x and action.y==y and action.size==size
            action.cover:SetShown(not matches)
        end
        return
    end
    if not usable then
        if action then action.key=nil;action.button:Hide();action.cover:Hide() end
        return
    end
    if not action then
        local button=CreateFrame("Button",nil,UIParent,"SecureActionButtonTemplate")
        button:RegisterForClicks("LeftButtonUp");button:SetAttribute("useOnKeyDown",false)
        local cover=CreateFrame("Button",nil,UIParent)
        cover:EnableMouse(true)
        local level=self.alertContainer:GetFrameLevel()+3
        button:SetFrameLevel(level);cover:SetFrameLevel(level+1)
        action={button=button,cover=cover};self.alertActions[index]=action
        button:SetScript("PreClick",function() if action.item and action.key=="food" then FBR.Food:Click(action) end end)
    end
    if action.key~=alert.key or action.cast~=alert.cast or action.item~=alert.item or action.unit~=alert.castUnit then
        action.button:SetAttribute("type1",alert.item and "item" or "spell")
        action.button:SetAttribute("item1",alert.item and ("item:"..alert.item) or nil)
        action.button:SetAttribute("spell1",alert.cast)
        action.button:SetAttribute("unit",alert.castUnit)
    end
    if action.x~=x or action.y~=y or action.size~=size then
        for _,frame in ipairs({action.button,action.cover}) do
            frame:ClearAllPoints();frame:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",x,y)
            frame:SetSize(size,size)
        end
    end
    action.key,action.cast,action.item,action.unit,action.icon=alert.key,alert.cast,alert.item,alert.castUnit,alert.icon
    action.x,action.y,action.size=x,y,size
    action.button:Show();action.cover:Hide()
end

function FBR:ShowAlerts(alerts)
    local size = tonumber(ForeverBuffReminderDB.iconSize) or self.DEFAULT_ICON_SIZE
    local gap = 8
    local direction = ForeverBuffReminderDB.layoutDirection or "RIGHT"
    local horizontal = direction == "RIGHT" or direction == "LEFT"
    local step=size+gap
    local parents,above,below={ },0,0
    for _,alert in ipairs(alerts) do if not alert.utility then parents[alert.key]=true end end
    for _,alert in ipairs(alerts) do
      if alert.utility and parents[alert.utilityOf] then
        if alert.placement=="ABOVE" then above=1 else below=1 end
      end
    end
    -- Reserve vertical cells for companions, including vertical/wrapped layouts.
    local rowStep=step*(1+above+below)
    local availableSpace = horizontal and UIParent:GetWidth() or UIParent:GetHeight()
    local perLine = math.max(1, math.floor((availableSpace - 40) / (horizontal and step or rowStep)))
    local normal,total=0,0
    for _,alert in ipairs(alerts) do if not alert.utility then total=total+1 end end
    local utilitySlots={ABOVE=0,BELOW=0}
    local extent=math.max(0,math.min(total,perLine)-1)*rowStep
    local topY=not horizontal and direction=="UP" and extent or 0
    local bottomY=horizontal and -math.max(0,math.ceil(total/perLine)-1)*rowStep or direction=="DOWN" and -extent or 0
    local layout={}
    for _,alert in ipairs(alerts) do
      local x,y
      if alert.utility then
        local side=alert.placement=="ABOVE" and "ABOVE" or "BELOW"
        x=utilitySlots[side]*(size+gap);utilitySlots[side]=utilitySlots[side]+1
        y=side=="ABOVE" and topY+step*(above+1) or bottomY-step*(below+1)
      else
        local line,position=math.floor(normal/perLine),normal%perLine;normal=normal+1
        if horizontal then x=(direction=="LEFT" and -position or position)*step;y=-line*rowStep
        else x=line*step;y=(direction=="UP" and position or -position)*rowStep end
      end
      layout[alert.key]={x=x,y=y}
    end
    local combat=KHQOL.PublicCall(InCombatLockdown)==true
    local cx,cy=KHQOL.PositionStore:Center(self.anchor)
    local slots,last=alerts,#alerts
    if combat then
        slots,last={},0
        local reserved={}
        for index,action in pairs(self.alertActions) do if action.key then reserved[action.key]=index end end
        local other={}
        for _,alert in ipairs(alerts) do
            local index=reserved[alert.key]
            if index and not slots[index] then slots[index]=alert;last=math.max(last,index)
            else other[#other+1]=alert end
        end
        local index=1
        for _,alert in ipairs(other) do
            while slots[index] do index=index+1 end
            slots[index]=alert;last=math.max(last,index)
        end
    end
    if combat and cx and cy and above+below==0 then
      local occupied,fixed={},{}
      local function point(x,y) return string.format("%.2f:%.2f",x,y) end
      for index,alert in pairs(slots) do
        local action=self.alertActions[index]
        if action and action.key==alert.key and action.x and action.y then
          local p={x=action.x-cx,y=action.y-cy};layout[alert.key]=p;fixed[alert.key]=true
          if not alert.utility then occupied[point(p.x,p.y)]=true end
        end
      end
      local nextSlot=0
      for _,alert in ipairs(alerts) do if not alert.utility and not fixed[alert.key] then
        local x,y
        repeat
          local line,position=math.floor(nextSlot/perLine),nextSlot%perLine;nextSlot=nextSlot+1
          if horizontal then x=(direction=="LEFT" and -position or position)*step;y=-line*rowStep
          else x=line*step;y=(direction=="UP" and position or -position)*rowStep end
        until not occupied[point(x,y)]
        layout[alert.key]={x=x,y=y};occupied[point(x,y)]=true
      end end
    end
    -- Resolve against final parent positions, after combat slot preservation.
    -- Only visual frames move here; protected item buttons remain covered in combat.
    for _,alert in ipairs(alerts) do
      local parent=alert.utilityOf and layout[alert.utilityOf]
      if alert.utility and parent then
        layout[alert.key]={x=parent.x,y=parent.y+(alert.placement=="ABOVE" and step or -step)}
      end
    end
    local bottom=0
    for index=1,math.max(last,#self.alertFrames) do
        local alert=slots[index]
        if not alert then
            local frame=self.alertFrames[index]
            if frame then frame:Hide();if frame.glow:IsPlaying() then frame.glow:Stop() end end
            self:SyncAlertAction(index,nil,nil,nil,nil,combat)
        else
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
            x,y=layout[alert.key].x,layout[alert.key].y
            bottom=math.min(bottom,y)
            frame:ClearAllPoints(); frame:SetPoint("TOPLEFT", self.alertContainer, "CENTER", x, y)
            frame:SetSize(size, size); frame.icon:SetTexture(alert.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            local expiring = alert.state == "EXPIRING"
            local missing = alert.state == "MISSING" or alert.muted==true
            -- Missing and expiring effects have separate, mutually exclusive owners.
            if frame.icon.SetDesaturated then frame.icon:SetDesaturated(missing) end
            frame.icon:SetVertexColor(missing and 0.62 or 1, missing and 0.62 or 1, missing and 0.62 or 1, 1)
            for _, part in ipairs(frame.glowParts) do part:SetColorTexture(1, 1, 1, 1) end
            self:MissingGlow(frame,alert)
            self.Food:Render(frame,alert)
            frame.glowFrame:SetShown(expiring)
            frame.time:SetText(alert.state == "EXPIRING" and tostring(math.max(1, math.floor(alert.remaining or 0))) or "")
            frame:Show()
            self:SyncAlertAction(index,alert,cx and cx+x,cy and cy+y,size,combat)
            if expiring and not frame.glow:IsPlaying() then frame.glow:Play()
            elseif not expiring and frame.glow:IsPlaying() then frame.glow:Stop() end
        end
    end
    if self.Sleep then self.Sleep:Render(bottom,size) end
end

function FBR:HideAlerts()
    local combat=KHQOL.PublicCall(InCombatLockdown)==true
    self.Food:Stop()
    self:StopCommon()
    for index, frame in pairs(self.alertFrames or {}) do
        self:StopMissingGlow(frame)
        frame:Hide()
        if frame.glow and frame.glow:IsPlaying() then frame.glow:Stop() end
        self:SyncAlertAction(index,nil,nil,nil,nil,combat)
    end
end
