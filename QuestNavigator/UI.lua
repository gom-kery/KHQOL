local _, KHQOL = ...
local QN=KHQOL.modules.questNavigator
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
function QN:CreateHUD()
  local root=CreateFrame("Frame","KHQOLQuestNavigatorFrame",UIParent)
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
  local hint=label(handle,12,236); hint:SetPoint("BOTTOM",0,4); hint:SetText("Quest Navigator · 드래그 이동")
  handle:SetScript("OnDragStart",function() if self.active and not self.db.locked then self.dragging=true; root:StartMoving() end end)
  handle:SetScript("OnDragStop",function() self:SavePosition() end)
  self.root,self.hud,self.arrowContainer,self.arrow=root,hud,container,arrow
  self.arrowSides,self.arrowShadow=sides,shadow
  self.distanceText,self.titleText,self.objectiveText=distance,title,objective
  self.completionFrame,self.completionTitle,self.handle=complete,completeTitle,handle
  root:Hide(); hud:Hide(); handle:Hide()
end
function QN:SavePosition()
  if not self.dragging then return end
  self.root:StopMovingOrSizing(); self.dragging=nil
  local x,y=self.root:GetCenter(); local px,py=UIParent:GetCenter()
  if QN.IsNumber(x) and QN.IsNumber(y) and QN.IsNumber(px) and QN.IsNumber(py) then
    self.db.positionX=math.floor(x-px+.5); self.db.positionY=math.floor(y-py+.5)
  end
  self:ApplyLayout()
end
function QN:ResetPosition()
  self:SavePosition(); self.db.positionX=0; self.db.positionY=180; self:Changed("position")
end
function QN:ApplyLayout()
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
function QN:RotateTexture(rotation)
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
function QN:RenderArrow()
  self.arrowContainer:SetShown(self.active and self.state=="TRACKING" and self.db.showArrow and self.currentRotation~=nil and not self.atWaypoint)
end
function QN:RenderDistance()
  local text=""
  if self.state=="NO_WAYPOINT" then text="경로 없음"
  elseif self.state=="NAVIGATION_UNAVAILABLE" then text="경로 안내 불가"
  elseif self.state=="TRACKING" and self.db.showDistance then
    if self.distanceYards~=nil then
      local meters=self.db.distanceUnit=="meters"
      -- Convert the unrounded distance to avoid two rounds near unit boundaries.
      local value=meters and math.floor(math.sqrt(self.distanceSq)*.9144+.5) or self.distanceYards
      if self.lastDistanceValue~=value or self.lastDistanceUnit~=self.db.distanceUnit then
        self.lastDistanceValue=value; self.lastDistanceUnit=self.db.distanceUnit
        self.distanceLabel=value..(meters and " m" or " yd")
      end
    end
    text=self.distanceLabel or ""
  end
  -- Status remains readable even when the numeric-distance option is off.
  setText(self.distanceText,text)
  self.distanceText:SetShown(text~="" and self.state~="COMPLETED" and self.state~="SWITCHING")
end
function QN:Render()
  if not self.root then return end
  local shown=self.active and self.currentQuestID~=nil and self.state~="IDLE"
  self.root:SetShown(shown or (self.active and not self.db.locked))
  self.hud:SetShown(shown)
  local completed=self.state=="COMPLETED" or self.state=="SWITCHING"
  self.completionFrame:SetShown(shown and completed)
  setText(self.completionTitle,self.db.showTitle and (self.questTitle or "") or "")
  setText(self.titleText,self.questTitle or ""); setText(self.objectiveText,self.progressText or "")
  self.titleText:SetShown(shown and not completed and self.db.showTitle)
  self.objectiveText:SetShown(shown and not completed and self.db.showProgress)
  self:RenderArrow(); self:RenderDistance()
end
