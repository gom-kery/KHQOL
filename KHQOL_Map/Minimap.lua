local _, A = ...
local M = { }
A.Minimap = M
local function MailLayoutSize(frame) return A:Pack(frame.fixedWidth,frame.fixedHeight) end
local function SetMailLayoutSize(frame,width,height) frame.fixedWidth,frame.fixedHeight=width,height end
local conflicts = { "KHminimap", "BasicMinimap", "EllesmereUI", "EllesmereUIMinimap", "EllesmereUI_Minimap", "EUI_Minimap",
    "Mappy", "MappyContinued", "SexyMap", "Chinchilla", "ElvUI", "Tukui", "ForeverUI" }

function M:Bounds()
    local w, h = UIParent:GetWidth(), UIParent:GetHeight()
    if not A:Number(w) or not A:Number(h) or w <= 0 or h <= 0 then return end
    return w, h
end

function M:Initialize()
    local _, _, _, interface = GetBuildInfo()
    self.supported = not A:IsSecret(interface) and interface == 16001 and MinimapCluster and
        MinimapCluster.MinimapContainer and MinimapCluster.ZoneTextButton and
        MinimapCluster.Tracking and MinimapCluster.IndicatorFrame and Minimap and
        type(MinimapCluster.UpdateMinimapConfig) == "function" and type(Minimap.SetMaskTexture) == "function"
    if not self.supported then return end
    self.container = MinimapCluster.MinimapContainer
    -- Forever exposes SetMaskTexture, but no GetMaskTexture. Observe writes and
    -- ask the verified native config function to establish a public baseline.
    hooksecurefunc(Minimap, "SetMaskTexture", function(_, asset)
        if A:IsSecret(asset) then self.maskUnknown = true; return end
        self.maskUnknown = nil
        self.mask = asset
        if A.writing == 0 and self.active then self.foreignMask = true; A:Request() end
    end)
    hooksecurefunc(MinimapCluster, "UpdateMinimapConfig", function()
        self.foreignMask = nil
        if self.journal then
            self.journal:Rebase(Minimap, "mask")
            self.journal:Rebase(self.container, "size")
            if MinimapBackdrop then self.journal:Rebase(MinimapBackdrop, "size") end
        end
        if self.active then A:Request() end
    end)
    for _, method in ipairs({"SetEditModeScale", "SetHeaderUnderneath", "ApplySystemAnchor"}) do
        if type(MinimapCluster[method]) == "function" then
            local nativeMethod = method
            hooksecurefunc(MinimapCluster, method, function()
                if self.journal then
                    if nativeMethod == "SetEditModeScale" then
                        self.journal:Rebase(self.container, "scale")
                        if QueueStatusButton then self.journal:Rebase(QueueStatusButton, "points") end
                        if MinimapCluster.DielFrame then
                            self.journal:Rebase(MinimapCluster.DielFrame, "scale")
                            self.journal:Rebase(MinimapCluster.DielFrame, "points")
                        end
                    elseif nativeMethod == "ApplySystemAnchor" then self.journal:Rebase(MinimapCluster, "points")
                    else
                        self.journal:Rebase(self.container, "points")
                        for _, f in ipairs({MinimapCluster.ZoneTextButton, MinimapCluster.IndicatorFrame,
                            AddonCompartmentFrame}) do self.journal:Rebase(f, "points") end
                    end
                end
                if self.active then A:Request() end
            end)
        end
    end
    if QueueStatusButton and type(QueueStatusButton.UpdateDefaultAnchor) == "function" then
        hooksecurefunc(QueueStatusButton, "UpdateDefaultAnchor", function()
            if self.journal then self.journal:Rebase(QueueStatusButton, "points") end
            if self.active then A:Request() end
        end)
    end
    hooksecurefunc(MinimapCluster, "SetScale", function()
        if self.active and A.writing == 0 then A:Request() end
    end)
    if EventRegistry and EventRegistry.RegisterCallback then
        -- The native queue callback stores a function reference before our
        -- hooks are installed; observe the scale event as well as the method.
        EventRegistry:RegisterCallback("Minimap.OnScaleUpdated", function()
            if self.journal then
                self.journal:Rebase(self.container, "scale")
                if QueueStatusButton then self.journal:Rebase(QueueStatusButton, "points") end
            end
            if self.active then A:Request() end
        end, self)
        EventRegistry:RegisterCallback("EditMode.Enter", function()
            A.editing = true
            self:StopDrag()
            A:Request()
        end, self)
        EventRegistry:RegisterCallback("EditMode.Exit", function()
            A.editing = false
            A:Request(true)
        end, self)
    end
    -- The native OnMouseUp handles the circle. Only add the four square corners.
    -- No click forwarding, script replacement, or reading MINIMAP_PING payloads.
    Minimap:HookScript("OnMouseUp", function(frame, button)
        if not self.active or A.db.shape ~= "SQUARE" or not A:Accessible(frame, true) then return end
        local x, y = GetCursorPosition()
        local cx, cy, scale, w, h = frame:GetCenter()
        scale, w, h = frame:GetEffectiveScale(), frame:GetWidth(), frame:GetHeight()
        if not (A:Number(x) and A:Number(y) and A:Number(cx) and A:Number(cy) and
            A:Number(scale) and scale > 0 and A:Number(w) and A:Number(h)) then return end
        x, y = x / scale - cx, y / scale - cy
        if math.abs(x) <= w / 2 and math.abs(y) <= h / 2 and x*x + y*y >= (w/2)^2 then
            frame:PingLocation(x, y)
        end
    end)
    self:CreateDecor()
    self:CreateElements()
end

function M:CreateElements()
    self.hidden = CreateFrame("Frame", nil, UIParent)
    self.hidden.ignoreInLayout = true; self.hidden:Hide()
    local tracking = MinimapCluster.Tracking and MinimapCluster.Tracking.Button
    if A:Accessible(tracking,true) then
        self.trackingArt = tracking:CreateTexture(nil,"OVERLAY")
        self.trackingArt:SetAllPoints(tracking)
        self.trackingArt:SetTexture("Interface\\AddOns\\KHQOL_Map\\Media\\Tracking.tga")
        self.trackingArt:Hide()
    end
    self.elementHandles = {}
    for _, key in ipairs({"tracking","diel","mail"}) do
        local element = key == "tracking" and tracking or key=="diel" and MinimapCluster.DielFrame or MinimapCluster.IndicatorFrame
        if A:Accessible(element,true) then
            local id = key
            local handle = CreateFrame("Button",nil,element)
            handle:SetAllPoints(element); handle:SetFrameStrata("DIALOG"); handle:RegisterForDrag("LeftButton")
            local bg = handle:CreateTexture(nil,"BACKGROUND"); bg:SetAllPoints(); bg:SetColorTexture(0.1,0.25,0.3,0.45)
            local text = handle:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
            text:SetAllPoints(); text:SetText("이동")
            handle:SetScript("OnDragStart",function()
                if not self.active or A.db.locked or A.editing or InCombatLockdown() then return end
                self.elementDragging = id
                handle:SetScript("OnUpdate",function()
                    if InCombatLockdown() or not self.active then self:StopDrag(); return end
                    self:MoveElement(id)
                end)
            end)
            handle:SetScript("OnDragStop",function()
                self:StopDrag(); A:Request()
            end)
            handle:SetScript("OnEnter",function(frame)
                GameTooltip:SetOwner(frame,"ANCHOR_RIGHT")
                GameTooltip:SetText((id=="tracking" and "추적 버튼" or id=="diel" and "낮밤 표시" or "우편 표시") .. " · 드래그하여 이동")
                GameTooltip:AddLine("설정에서 위치를 잠그면 원래 기능을 사용할 수 있습니다.",0.9,0.9,0.9); GameTooltip:Show()
            end)
            handle:SetScript("OnLeave",function() GameTooltip:Hide() end)
            handle:Hide(); self.elementHandles[id] = handle
        end
    end
    local hover = CreateFrame("Frame",nil,Minimap)
    hover:SetPoint("CENTER",Minimap,"CENTER",0,0)
    hover:SetFrameLevel(20)
    self.zoneCanPropagate = type(hover.SetPropagateMouseClicks)=="function" and type(hover.SetPropagateMouseMotion)=="function"
    hover:EnableMouse(self.zoneCanPropagate)
    if self.zoneCanPropagate then hover:SetPropagateMouseClicks(true); hover:SetPropagateMouseMotion(true) end
    local function Enter() self.zoneHovered=true; self:UpdateZone() end
    local function Leave() self.zoneHovered=false; self:UpdateZone() end
    hover:SetScript("OnEnter",Enter); hover:SetScript("OnLeave",Leave)
    if not self.zoneCanPropagate then Minimap:HookScript("OnEnter",Enter); Minimap:HookScript("OnLeave",Leave) end
    self.zoneLabel=hover:CreateFontString(nil,"OVERLAY","GameFontNormal")
    self.zoneLabel:SetJustifyH("CENTER"); self.zoneLabel:SetMaxLines(1)
    self.zoneHover=hover; hover:Hide(); self.zoneLabel:Hide()
    self.zoneEvents=CreateFrame("Frame")
    for _, event in ipairs({"ZONE_CHANGED","ZONE_CHANGED_INDOORS","ZONE_CHANGED_NEW_AREA"}) do self.zoneEvents:RegisterEvent(event) end
    self.zoneEvents:SetScript("OnEvent",function() if self.active then self:UpdateZone() end end)
end

function M:UpdateZone()
    if not self.zoneLabel then return end
    local enabled=self.active and A.db.zone and not A.editing
    local text=type(GetMinimapZoneText)=="function" and GetMinimapZoneText() or MinimapZoneText and MinimapZoneText:GetText()
    if A:IsSecret(text) or type(text)~="string" then text="" end
    self.zoneLabel:SetText(text)
    local scale=A.db.zoneScale/100
    self.zoneLabel:SetScale(scale)
    self.zoneLabel:SetWidth(math.max(40,((self.displaySize or A.db.size)-12)/scale))
    self.zoneLabel:ClearAllPoints()
    if A.db.zoneLocation=="INSIDE" then self.zoneLabel:SetPoint("TOP",Minimap,"TOP",0,-6)
    else self.zoneLabel:SetPoint("BOTTOM",Minimap,"TOP",0,5) end
    self.zoneHover:SetSize(self.displaySize or A.db.size,self.displaySize or A.db.size)
    self.zoneHover:SetShown(enabled==true)
    self.zoneLabel:SetShown(enabled and self.zoneHovered==true)
end

function M:Park(frame)
    if not frame then return true end
    if not A:CanAnchor(frame) then return false end
    local level=type(frame.GetFrameLevel)=="function" and A:Read(frame,A.get.level)
    if level and not self.journal:Capture(frame,"level") then return false end
    if not self.journal:Set(frame,"parent",self.hidden) then return false end
    if level and not self.journal:Set(frame,"level",level[1]) then return false end
    return true
end

function M:PlaceElement(key,frame)
    if not A:Accessible(frame,true) then return false end
    local us,fs,ms=UIParent:GetEffectiveScale(),frame:GetEffectiveScale(),Minimap:GetEffectiveScale()
    if not (A:Number(us) and A:Number(fs) and A:Number(ms) and us>0 and fs>0 and ms>0) then return false end
    local p=A.db.elementPositions[key]
    local half=(self.displaySize or A.db.size)*ms/us/2
    local x,y=0,-half-27
    if key=="tracking" then x,y=half+22,half-16 end
    if key=="mail" then x,y=-half+16,-half-18 end
    if p then x,y=p.x,p.y end
    local w,h=self:Bounds()
    local cx,cy=Minimap:GetCenter()
    if not w or not A:Number(cx) or not A:Number(cy) then return false end
    cx,cy=cx*ms/us,cy*ms/us
    if self.centerUI then cx,cy=self.centerUI.x,self.centerUI.y end
    local fw,fh=frame:GetSize()
    if not A:Number(fw) or not A:Number(fh) then return false end
    local marginX,marginY=math.max(24,fw*fs/us/2),math.max(24,fh*fs/us/2)
    x,y=A:Clamp(cx+x,marginX,math.max(marginX,w-marginX))-cx,A:Clamp(cy+y,marginY,math.max(marginY,h-marginY))-cy
    return self.journal:Set(frame,"points",1,"CENTER",Minimap,"CENTER",x*us/fs,y*us/fs)
end

function M:MoveElement(key)
    if not self.active or not self.journal or A.db.locked or A.editing or InCombatLockdown() then return end
    local x,y=GetCursorPosition()
    local us,ms=UIParent:GetEffectiveScale(),Minimap:GetEffectiveScale()
    local cx,cy=Minimap:GetCenter()
    local w,h=self:Bounds()
    if not w or not (A:Number(x) and A:Number(y) and A:Number(us) and A:Number(ms) and A:Number(cx) and A:Number(cy) and us>0) then return end
    x,y=A:Clamp(x/us,24,math.max(24,w-24)),A:Clamp(y/us,24,math.max(24,h-24))
    A.db.elementPositions[key]={x=x-cx*ms/us,y=y-cy*ms/us}
    local target=key=="tracking" and MinimapCluster.Tracking or key=="diel" and MinimapCluster.DielFrame or MinimapCluster.IndicatorFrame
    if not self:PlaceElement(key,target) then self.yielded=true; self:StopDrag(); A:Request() end
end

function M:ApplyElements()
    local c,j=MinimapCluster,self.journal
    local scale=A.db.elementScale/100
    if A.db.locked or (self.elementDragging and not A.db.elements[self.elementDragging]) then self:StopDrag() end
    if not (self:Park(c.ZoneTextButton) and self:Park(GameTimeFrame) and self:Park(TimeManagerClockButton)) then return false end
    local tracking=c.Tracking and c.Tracking.Button
    if tracking then
        for _, region in ipairs({tracking.StateTexture,tracking.AddTexture,c.Tracking.Background}) do
            if not self:Park(region) then return false end
        end
        if not j:Set(c.Tracking,"size",26,26) or not j:Set(tracking,"size",26,26) or
            not j:Set(c.Tracking,"scale",scale) or not j:Set(tracking,"scale",1) then return false end
        if self.trackingArt then self.trackingArt:SetShown(A.db.elements.tracking) end
    end
    if not self:PlaceElement("tracking",c.Tracking) then return false end
    if c.DielFrame and (not j:Set(c.DielFrame,"scale",scale) or not self:PlaceElement("diel",c.DielFrame)) then return false end
    local indicator=c.IndicatorFrame
    if indicator then
        -- The native mail event runs Layout() on this fixed-size container.
        -- Keep its public layout dimensions in step with the smaller envelope.
        if not j:Write(indicator,"mailLayoutSize",MailLayoutSize,SetMailLayoutSize,29,21) or
            not j:Set(indicator,"size",29,21) or not j:Set(indicator,"scale",scale) then return false end
        local mail=indicator.MailFrame
        if mail and (not j:Set(mail,"size",29,21) or
            (mail.MailIcon and not j:Set(mail.MailIcon,"size",29,21))) then return false end
        if not self:PlaceElement("mail",indicator) then return false end
    end
    for _,item in ipairs({{"tracking",c.Tracking,tracking},{"diel",c.DielFrame},{"mail",indicator,indicator and indicator.MailFrame}}) do
        local key,frame,button=item[1],item[2],item[3]
        if frame then
            if not j:Capture(frame,"alpha") then return false end
            local alpha=j.byFrame[frame].alpha.old[1]
            if not j:Set(frame,"alpha",A.db.elements[key] and alpha or 0) then return false end
            if button then
                if not j:Capture(button,"mouse") then return false end
                local mouse=j.byFrame[button].mouse.old[1]
                if not j:Set(button,"mouse",A.db.elements[key] and mouse or false) then return false end
            end
        end
    end
    for key,handle in pairs(self.elementHandles) do handle:SetShown(not A.db.locked and A.db.elements[key]) end
    self:UpdateZone()
    return true
end

function M:CreateDecor()
    self.border = CreateFrame("Frame", nil, Minimap)
    self.border:SetAllPoints(Minimap)
    self.border:EnableMouse(false)
    self.lines = {}
    for i = 1, 96 do self.lines[i] = self.border:CreateLine(nil, "OVERLAY") end
    self.border:Hide()
    local handle = CreateFrame("Button", nil, Minimap)
    handle:SetSize(200, 22)
    handle:SetClampedToScreen(true)
    handle:SetPoint("BOTTOM", Minimap, "TOP", 0, 34)
    local bg = handle:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(); bg:SetColorTexture(0.10, 0.11, 0.13, 0.96)
    local label = handle:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetAllPoints(); label:SetText("드래그하여 미니맵 이동")
    handle:RegisterForDrag("LeftButton")
    handle:SetScript("OnDragStart", function()
        if InCombatLockdown() or A.editing or A.db.locked or not self.active then return end
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        local cx, cy = MinimapCluster:GetCenter()
        local cs = MinimapCluster:GetEffectiveScale()
        if not (A:Number(x) and A:Number(y) and A:Number(scale) and scale > 0 and
            A:Number(cx) and A:Number(cy) and A:Number(cs)) then return end
        self.drag = {x = x / scale, y = y / scale, cx = cx * cs / scale, cy = cy * cs / scale}
        handle:SetScript("OnUpdate", function()
            if InCombatLockdown() or not self.drag then self:StopDrag(); return end
            local px, py = GetCursorPosition()
            if not A:Number(px) or not A:Number(py) then return end
            local nx, ny = self.drag.cx + px / scale - self.drag.x, self.drag.cy + py / scale - self.drag.y
            if self:MoveTo(nx, ny, true) then
                A.Buttons:PositionToggle()
                if A.Buttons.open then A.Buttons:Layout() end
            end
        end)
    end)
    handle:SetScript("OnDragStop", function() self:StopDrag(); A:Request() end)
    handle:Hide()
    self.handle = handle
end

function M:StopDrag()
    self.drag = nil
    if self.handle then self.handle:SetScript("OnUpdate", nil) end
    self.elementDragging=nil
    for _, handle in pairs(self.elementHandles or {}) do handle:SetScript("OnUpdate",nil) end
end

function M:MoveTo(x, y, save)
    local w, h = self:Bounds()
    if not w or not self.journal then return false end
    local margin = self.displaySize / 2
    x, y = A:Clamp(x, margin, math.max(margin, w - margin)), A:Clamp(y, margin, math.max(margin, h - margin))
    local cs, us = MinimapCluster:GetEffectiveScale(), UIParent:GetEffectiveScale()
    if not A:Number(cs) or not A:Number(us) or cs <= 0 or us <= 0 then return false end
    local scale = cs / us
    local ok = self.journal:Set(MinimapCluster, "points", 1, "CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)
    if ok then self.centerUI={x=x,y=y} end
    if save and ok then A.db.position = {x = x / w, y = y / h} end
    return ok
end

function M:DrawBorder()
    local size, color = self.displaySize, A.db.border
    for i, line in ipairs(self.lines) do
        line:Hide()
        local x1, y1, x2, y2
        if A.db.shape == "SQUARE" and i <= 4 then
            local corners = {{-1,-1,1,-1}, {1,-1,1,1}, {1,1,-1,1}, {-1,1,-1,-1}}
            local c = corners[i]
            x1, y1, x2, y2 = c[1]*size/2, c[2]*size/2, c[3]*size/2, c[4]*size/2
        elseif A.db.shape == "ROUND" then
            local a, b = (i-1)*math.pi/48, i*math.pi/48
            x1, y1, x2, y2 = math.cos(a)*size/2, math.sin(a)*size/2, math.cos(b)*size/2, math.sin(b)*size/2
        end
        if x1 then
            line:SetStartPoint("CENTER", self.border, x1, y1); line:SetEndPoint("CENTER", self.border, x2, y2)
            line:SetThickness(1); line:SetColorTexture(color.r, color.g, color.b, 1); line:Show()
        end
    end
    self.border:Show()
end

function M:Release()
    self:StopDrag()
    self.active = false
    self.centerUI=nil
    if self.border then self.border:Hide(); self.handle:Hide() end
    if self.trackingArt then self.trackingArt:Hide() end
    if self.zoneHover then self.zoneHover:Hide(); self.zoneLabel:Hide(); self.zoneHovered=false end
    for _, handle in pairs(self.elementHandles or {}) do handle:Hide() end
    if self.journal and not self.journal:Restore() then return false end
    self.journal = nil
    if self.provider and GetMinimapShape == self.provider then _G.GetMinimapShape = self.oldProvider end
    self.provider = nil
    return true
end

function M:Apply()
    A.messages.appearance = nil
    if not A.enabled or not A.db.appearance then
        self.yielded = nil
        if not self:Release() then A.messages.appearance = "외형 복원 대기: 프레임 접근·앵커 제한을 확인하세요." end
        self.foreignMask = nil
        return
    end
    if not self.supported then
        A.messages.appearance = "현재 클라이언트의 미니맵 구조를 확인할 수 없어 외형을 보류합니다."
        return
    end
    local conflict = A:FindConflict(conflicts) or A:EnhanceConflict({"enableSquareMinimap", "enableSquareMinimapLayout",
        "enableSquareMinimapBorder", "enableSquareMinimapBackground", "enableSquareMinimapStats", "enableMinimapClusterScale"})
    if conflict then
        self:Release()
        A.messages.appearance = conflict .. " 감지: 외형 적용을 보류합니다."
        return
    end
    if A.editing then
        self:Release()
        A.messages.appearance = "게임 편집 모드 종료 후 KHQOL_Map 위치·외형을 적용합니다."
        return
    end
    if self.foreignMask or (self.provider and GetMinimapShape ~= self.provider) then self.yielded = true end
    if self.yielded then
        self:Release()
        A.messages.appearance = "다른 외형 변경 감지: 외형을 껐다 켜기 전에 충돌을 확인하세요."
        return
    end
    if not self.active and self.journal and not self:Release() then return end
    if not self.active and GetMinimapShape then
        A.messages.appearance = "다른 미니맵 모양 제공자가 있어 외형을 보류합니다."
        return
    end
    if not (A:Accessible(Minimap, true) and A:Accessible(MinimapCluster, true) and
        A:Accessible(self.container, true)) then
        A.messages.appearance = "미니맵의 보호·접근 상태를 확인할 수 없어 변경을 보류합니다."
        return
    end
    local cs, us = MinimapCluster:GetEffectiveScale(), UIParent:GetEffectiveScale()
    local parent = MinimapCluster:GetParent()
    if not A:Number(cs) or not A:Number(us) or us <= 0 or math.abs(cs/us - 1) > 0.001 or
        A:IsSecret(parent) or parent ~= UIParent then
        self:Release()
        A.messages.appearance = "다른 미니맵 배율·컨테이너 사용 감지: 외형을 보류합니다."
        return
    end
    if not self.active then
        if self.journal and not self:Release() then return end
        MinimapCluster:UpdateMinimapConfig()
        if not self.mask or self.maskUnknown then
            A.messages.appearance = "기본 마스크를 확인할 수 없어 외형을 보류합니다."
            return
        end
        self.journal = A:NewJournal()
        self.oldProvider = GetMinimapShape
        self.provider = function() return A.db.shape end
        _G.GetMinimapShape = self.provider
        self.active = true
    end
    local w, h = self:Bounds()
    if not w then return end
    self.displaySize = math.min(A.db.size, math.max(180, math.floor(math.min(w, h) - 128)))
    local j, size, ok = self.journal, self.displaySize, true
    local function Set(frame, key, ...)
        if frame and A:Accessible(frame, true) and not j:Set(frame, key, ...) then ok = false end
    end
    Set(MinimapCluster,"clamped",false)
    Set(self.container, "scale", 1)
    Set(self.container, "size", size, size)
    Set(self.container, "points", 1, "CENTER", MinimapCluster, "CENTER", 0, 0)
    Set(Minimap, "size", size, size)
    Set(Minimap, "scale", 1)
    Set(Minimap, "points", 1, "CENTER", self.container, "CENTER", 0, 0)
    Set(MinimapBackdrop, "size", size, size)
    local asset = A.db.shape == "SQUARE" and "Interface\\Buttons\\WHITE8X8" or "ui-hud-minimap-frame-generic-mask"
    if not j:Write(Minimap, "mask", function() return A:Pack(self.mask) end,
        function(f, v) f:SetMaskTexture(v) end, asset) then ok = false end
    Set(MinimapCompassTexture, "alpha", 0)
    Set(MinimapCompassTextureUnderlay, "alpha", 0)
    Set(Minimap.ZoomIn, "points", 1, "BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", -3, 21)
    Set(Minimap.ZoomOut, "points", 1, "BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", -3, 3)
    Set(Minimap.ZoomHitArea, "points", 1, "BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 0, 0)
    if MinimapBackdrop then
        Set(MinimapBackdrop.ExternalEventURLButton, "points", 1, "BOTTOMRIGHT", Minimap, "BOTTOMLEFT", -6, 6)
    end
    if QueueStatusButton and A:Accessible(QueueStatusButton, true) and QueueStatusButton.IsInDefaultPosition then
        local nativePosition = QueueStatusButton:IsInDefaultPosition()
        if not A:IsSecret(nativePosition) and nativePosition then
            Set(QueueStatusButton, "points", 1, "TOPRIGHT", Minimap, "BOTTOMRIGHT", 0, -6)
        end
    end
    local p = A.db.position
    if not self:MoveTo(p and p.x*w or w - size/2 - 56, p and p.y*h or h - size/2 - 72) then ok = false end
    if not self:ApplyElements() then ok=false end
    if not ok then self.yielded = true; self:Release(); A.messages.appearance = "다른 배치 또는 접근 제한 감지: 외형을 보류합니다."; return end
    self:DrawBorder()
    self.handle:SetWidth(math.max(180, size))
    self.handle:SetShown(not A.db.locked)
end
