local _, KHQOL = ...
local N=KHQOL.Navigation
local UI={presentation={},jobs={}}
KHQOL.NavigationUI=UI
UI.defaults={showArrow=true,arrowSize=64,arrowAlpha=1,arrowTilt=55,smoothRotation=true,
  showDistance=true,showTitle=true,showProgress=true,distanceUnit="yards",locked=true,
  positionX=0,positionY=180,arrowUpdateInterval=.10,distanceUpdateInterval=.25,smoothingFactor=.25}
local MEDIA="Interface\\AddOns\\KHQOL\\Media\\QuestNavigator\\"
local function setText(region,text)
  if region.qnText~=text then region.qnText=text; region:SetText(text) end
end
local function label(parent,size,width)
  local fs=parent:CreateFontString(nil,"OVERLAY","GameFontHighlight")
  fs:SetFont(KHQOL.UI:Font(),size,"OUTLINE"); fs:SetWidth(width)
  fs:SetWordWrap(false); fs:SetJustifyH("CENTER"); fs:SetHeight(size+6)
  return fs
end
function UI:CreateHUD()
  local root=CreateFrame("Frame","KHQOLQuestNavigatorFrame",UIParent)
  -- A hidden HUD cannot drive event debounce or recovery in the real client.
  self.driver=CreateFrame("Frame")
  self.updateHandler=function(_,elapsed) self:Update(elapsed) end
  root:SetSize(240,150); root:SetFrameStrata("MEDIUM"); root:SetMovable(true); root:SetClampedToScreen(true)
  local hud=CreateFrame("Frame",nil,root); hud:SetAllPoints(root)
  local container=CreateFrame("Frame",nil,hud); container:SetPoint("TOP",0,0)
  -- Reuse these regions: extrusion is screen-down while heading rotates in the
  -- projected plane. Back-to-front masks fill the side walls without gaps.
  local shadow=container:CreateTexture(nil,"BACKGROUND",nil,-1)
  shadow:SetTexture(MEDIA.."ArrowSide.tga","CLAMP","CLAMP","LINEAR"); shadow:SetAlpha(.25)
  local sides={}
  for i=18,1,-1 do
    sides[i]=container:CreateTexture(nil,"BACKGROUND")
    sides[i]:SetTexture(MEDIA.."ArrowSide.tga","CLAMP","CLAMP","LINEAR")
  end
  local arrow=container:CreateTexture(nil,"ARTWORK"); arrow:SetAllPoints(container); arrow:SetTexture(MEDIA.."Arrow.tga","CLAMP","CLAMP","LINEAR")
  local distance=label(hud,16,240); distance:SetPoint("TOP",container,"BOTTOM",0,-4)
  local title=label(hud,14,240); title:SetPoint("TOP",distance,"BOTTOM",0,-6)
  local objective=label(hud,12,240); objective:SetPoint("TOP",title,"BOTTOM",0,-2)
  objective:SetTextColor(.8,.85,.9)
  local complete=CreateFrame("Frame",nil,hud); complete:SetAllPoints(hud)
  local icon=complete:CreateTexture(nil,"ARTWORK"); icon:SetSize(56,56); icon:SetPoint("TOP",0,-4); icon:SetTexture(MEDIA.."Check.tga")
  local message=label(complete,18,240); message:SetPoint("TOP",icon,"BOTTOM",0,-10); message:SetTextColor(.4,1,.55); message:SetText("목표 완료!")
  local completeTitle=label(complete,13,240); completeTitle:SetPoint("TOP",message,"BOTTOM",0,-6)
  -- Independent move handle stays usable with no quest and during fades.
  local handle=CreateFrame("Frame",nil,root,"BackdropTemplate"); handle:SetAllPoints(root)
  handle:SetFrameStrata("DIALOG"); handle:EnableMouse(true); handle:RegisterForDrag("LeftButton")
  handle:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12})
  handle:SetBackdropColor(.05,.12,.2,.55)
  local hint=label(handle,12,236); hint:SetPoint("BOTTOM",0,4); hint:SetText(self.presentation.moveHint or "Navigation · 드래그 이동")
  self.moveHint=hint
  handle:SetScript("OnDragStart",function() if self.active and not self.db.locked then self.dragging=true; root:StartMoving() end end)
  handle:SetScript("OnDragStop",function() self:SavePosition() end)
  self.root,self.hud,self.arrowContainer,self.arrow=root,hud,container,arrow
  self.arrowSides,self.arrowShadow=sides,shadow
  self.distanceText,self.titleText,self.objectiveText=distance,title,objective
  self.completionFrame,self.completionTitle,self.handle=complete,completeTitle,handle
  root:Hide(); hud:Hide(); handle:Hide()
end
function UI:SavePosition()
  if not self.dragging then return end
  self.root:StopMovingOrSizing(); self.dragging=nil
  local x,y=self.root:GetCenter(); local px,py=UIParent:GetCenter()
  if N.IsNumber(x) and N.IsNumber(y) and N.IsNumber(px) and N.IsNumber(py) then
    self.db.positionX=math.floor(x-px+.5); self.db.positionY=math.floor(y-py+.5)
  end
  self:ApplyLayout()
end
function UI:ResetPosition()
  self:SavePosition(); self.db.positionX=0; self.db.positionY=180; self:ApplyLayout()
end
function UI:ApplyLayout()
  if not self.root then return end
  if not self.dragging then
    self.root:ClearAllPoints(); self.root:SetPoint("CENTER",UIParent,"CENTER",self.db.positionX,self.db.positionY)
  end
  self.projectionAvailable=type(self.arrow.SetTexCoord)=="function"
  local height=self.db.arrowSize*(self.projectionAvailable and math.cos(math.rad(self.db.arrowTilt)) or 1)
  local depthAvailable=self.projectionAvailable and type(self.arrowShadow.SetVertexColor)=="function"
  local depth=depthAvailable and self.db.arrowSize*.14*math.sin(math.rad(self.db.arrowTilt)) or 0
  self.sideDepth=depth; self.sideCount=math.min(18,math.ceil(depth))
  local gap=depth>0 and self.db.arrowSize/64*2.5 or 0
  self.root:SetHeight(math.max(height+depth+gap+86,126)) -- Also contain the completion title.
  self.arrowContainer:SetSize(self.db.arrowSize,height); self.arrowContainer:SetAlpha(self.db.arrowAlpha)
  self.arrow:SetAlpha(1)
  for i,side in ipairs(self.arrowSides) do
    side:SetShown(i<=self.sideCount)
    if i<=self.sideCount then
      side:ClearAllPoints(); side:SetPoint("TOP",self.arrowContainer,"TOP",0,-depth*i/self.sideCount)
      side:SetSize(self.db.arrowSize,height)
      local shade=1-.2*i/self.sideCount
      side:SetVertexColor(.56*shade,.30*shade,.055*shade,1)
    end
  end
  self.arrowShadow:SetShown(depth>0)
  if depth>0 then
    self.arrowShadow:ClearAllPoints()
    self.arrowShadow:SetPoint("TOP",self.arrowContainer,"TOP",self.db.arrowSize/64*1.5,-depth-gap)
    self.arrowShadow:SetSize(self.db.arrowSize,height); self.arrowShadow:SetVertexColor(0,0,0,1)
  end
  self.distanceText:ClearAllPoints(); self.distanceText:SetPoint("TOP",self.arrowContainer,"BOTTOM",0,-4-depth-gap)
  self.handle:SetShown(self.active and not self.db.locked)
  self:Render()
end
local function rotateUV(texture,c,s)
  return pcall(texture.SetTexCoord,texture,
    .5-c+s,.5-s-c, .5-c-s,.5-s+c,
    .5+c+s,.5+s-c, .5+c-s,.5+s+c)
end
function UI:RotateTexture(rotation)
  local ok
  if self.projectionAvailable then
    -- Rotate the image on its plane, then compress screen Y through the region
    -- height. Rotating an already flattened rectangle would tilt the plane too.
    -- UV corners are upper-left, lower-left, upper-right, lower-right.
    local c,s=math.cos(rotation)*.5,math.sin(rotation)*.5
    ok=rotateUV(self.arrow,c,s)
    for i=1,self.sideCount do
      local side=self.arrowSides[i]
      side:SetShown(ok and rotateUV(side,c,s))
    end
    if self.sideCount>0 then self.arrowShadow:SetShown(ok and rotateUV(self.arrowShadow,c,s)) end
  elseif type(self.arrow.SetRotation)=="function" then
    ok=pcall(self.arrow.SetRotation,self.arrow,rotation)
  end
  return ok
end
function UI:RenderArrow()
  self.arrowContainer:SetShown(self.active and self:GetState()=="TRACKING" and self.db.showArrow and N.currentRotation~=nil and not N.atWaypoint)
end
function UI:RenderDistance()
  local destination=N:GetActiveDestination()
  if destination~=self.distanceDestination then
    self.distanceDestination=destination; self:ResetDistanceLabel()
  end
  local text=""
  if self:GetState()=="NO_WAYPOINT" then text=self.presentation.noWaypointText or "경로 없음"
  elseif self:GetState()=="NAVIGATION_UNAVAILABLE" then text=self.presentation.unavailableText or "경로 안내 불가"
  elseif self:GetState()=="TRACKING" and self.db.showDistance then
    if N.distanceYards~=nil then
      local meters=self.db.distanceUnit=="meters"
      -- Convert the unrounded distance to avoid two rounds near unit boundaries.
      local value=meters and math.floor(math.sqrt(N.distanceSq)*.9144+.5) or N.distanceYards
      if self.lastDistanceValue~=value or self.lastDistanceUnit~=self.db.distanceUnit then
        self.lastDistanceValue=value; self.lastDistanceUnit=self.db.distanceUnit
        self.distanceLabel=value..(meters and " m" or " yd")
      end
    end
    text=self.distanceLabel or ""
  end
  -- Status remains readable even when the numeric-distance option is off.
  setText(self.distanceText,text)
  self.distanceText:SetShown(text~="" and self:GetState()~="COMPLETED" and self:GetState()~="SWITCHING")
end
function UI:Render()
  if not self.root then return end
  local destination=N:GetActiveDestination()
  local title=destination and destination.label or ""
  local shown=self.active and (destination~=nil or self.phase~=nil) and self:GetState()~="IDLE"
  self.root:SetShown(shown or (self.active and not self.db.locked))
  self.hud:SetShown(shown)
  local completed=self:GetState()=="COMPLETED" or self:GetState()=="SWITCHING"
  self.completionFrame:SetShown(shown and completed)
  setText(self.completionTitle,self.db.showTitle and (self.presentation.completionTitle or title) or "")
  setText(self.titleText,title); setText(self.objectiveText,self.presentation.progressText or "")
  self.titleText:SetShown(shown and not completed and self.db.showTitle)
  self.objectiveText:SetShown(shown and not completed and self.db.showProgress)
  self:RenderArrow(); self:RenderDistance()
end

-- Generic view data/configuration. DB ownership remains with the caller.
function UI:Configure(db,presentation)
  self.db=KHQOL.MergeDefaults(db or {},self.defaults,"types")
  self.presentation=presentation or self.presentation
  if not self.root then self:CreateHUD() end
end
function UI:SetPresentation(presentation)
  self.presentation=presentation or {}
  if self.moveHint then setText(self.moveHint,self.presentation.moveHint or "Navigation · 드래그 이동") end
  self:Render()
end
function UI:GetState()
  if self.phase then return self.phase=="hold" and "COMPLETED" or "SWITCHING" end
  return N.state
end
function UI:SetEnabled(enabled)
  self.active=enabled==true; self.jobs={}; self:CancelTransition()
  self.arrowElapsed=0; self.distanceElapsed=0
  self:ApplyLayout(); self:Render(); self:UpdateDriver()
end
function UI:ResetDistanceLabel()
  self.lastDistanceValue=nil; self.lastDistanceUnit=nil; self.distanceLabel=nil
end
function UI:Refresh(rotate,distance)
  local oldState=self:GetState()
  N:Refresh(rotate,distance,self.db)
  if rotate and self.db.showArrow and N.state=="TRACKING" and not N.atWaypoint then
    N.rotationFailed=not N.Call(self.RotateTexture,self,N.currentRotation)
  end
  if self.db.showArrow and N.rotationFailed and N.state=="TRACKING" then N.state="NAVIGATION_UNAVAILABLE" end
  if N.state~="TRACKING" then N.currentRotation=nil; N.atWaypoint=false end
  if distance or oldState~=self:GetState() then self:RenderDistance() end
  if oldState~=self:GetState() then self:Render() else self:RenderArrow() end
  self:UpdateDriver()
end
-- One coalesced callback per key; never reset an existing deadline on a storm.
function UI:Schedule(key,delay,callback)
  if not self.active or self.jobs[key] then return end
  self.jobs[key]={elapsed=0,delay=delay,callback=callback}; self:UpdateDriver()
end
function UI:CancelJob(key) self.jobs[key]=nil; self:UpdateDriver() end
function UI:IsTransitioning() return self.phase~=nil end
function UI:CancelTransition()
  self.phase=nil; self.phaseElapsed=0; self.fadeInRemaining=nil; self.onTransitionEnd=nil
  self.presentation.completionTitle=nil
  if self.hud then self.hud:SetAlpha(1) end
end
function UI:BeginTransition(title,onFinished)
  self.phase="hold"; self.phaseElapsed=0; self.fadeInRemaining=nil
  self.presentation.completionTitle=title; self.onTransitionEnd=onFinished
  self.hud:SetAlpha(1); self:Render(); self:UpdateDriver()
end
function UI:FadeIn()
  self.hud:SetAlpha(0); self.fadeInRemaining=.15; self:UpdateDriver()
end
function UI:UpdateDriver()
  if not self.root then return end
  local moving=N:GetActiveDestination() and self:GetState()~="COMPLETED" and self:GetState()~="IDLE"
  local running=self.active and (next(self.jobs) or self.phase or self.fadeInRemaining or moving) and true or false
  if self.driverRunning~=running then
    self.driverRunning=running
    self.driver:SetScript("OnUpdate",running and self.updateHandler or nil)
  end
end
function UI:Update(elapsed)
  if not self.active then return end
  for key,job in pairs(self.jobs) do
    job.elapsed=job.elapsed+elapsed
    if job.elapsed>=job.delay then
      self.jobs[key]=nil; job.callback()
    end
  end
  if self.phase then
    self.phaseElapsed=self.phaseElapsed+elapsed
    if self.phase=="hold" and self.phaseElapsed>=.85 then
      self.phase="out"; self.phaseElapsed=0
    elseif self.phase=="out" then
      self.hud:SetAlpha(math.max(0,1-self.phaseElapsed/.15))
      if self.phaseElapsed>=.15 then
        local finished=self.onTransitionEnd; self:CancelTransition()
        if finished then finished() end
      end
    end
  elseif self.fadeInRemaining then
    self.fadeInRemaining=math.max(0,self.fadeInRemaining-elapsed)
    self.hud:SetAlpha(1-self.fadeInRemaining/.15)
    if self.fadeInRemaining==0 then self.fadeInRemaining=nil end
  end
  if not self.phase and N:GetActiveDestination() then
    self.arrowElapsed=self.arrowElapsed+elapsed; self.distanceElapsed=self.distanceElapsed+elapsed
    local arrowDue=self.db.showArrow and self.arrowElapsed>=self.db.arrowUpdateInterval
    local distanceDue=self.distanceElapsed>=self.db.distanceUpdateInterval
    if arrowDue or distanceDue then
      if arrowDue then self.arrowElapsed=self.arrowElapsed%self.db.arrowUpdateInterval end
      if distanceDue then self.distanceElapsed=self.distanceElapsed%self.db.distanceUpdateInterval end
      self:Refresh(arrowDue,distanceDue)
    end
  end
  self:UpdateDriver()
end
