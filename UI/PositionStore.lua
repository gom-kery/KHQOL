local _, KHQOL = ...
-- Owned-frame geometry only. Keep each module's anchor and coordinate format.
local S={}
KHQOL.PositionStore=S
local anchors={CENTER=true,TOP=true,BOTTOM=true,LEFT=true,RIGHT=true,TOPLEFT=true,TOPRIGHT=true,BOTTOMLEFT=true,BOTTOMRIGHT=true}
function S:Number(v)
  return KHQOL.IsPublicValue(v) and type(v)=="number" and v==v and math.abs(v)<math.huge
end
function S:Safe(frame)
  if not frame or frame==UIParent then return false end
  for _,key in ipairs({"IsForbidden","IsProtected"}) do
    if frame[key] then
      local status,value=KHQOL.ReadPublicAPI(frame[key],frame)
      if status~="ok" or value~=false then return false end
    end
  end
  return true
end
function S:Point(frame,db,includeSize)
  if not self:Safe(frame) or not db then return false end
  frame:StopMovingOrSizing()
  local status,point,relative,relativePoint,x,y=KHQOL.ReadPublicAPI(frame.GetPoint,frame,1)
  if status~="ok" or (relative and relative~=UIParent) or not anchors[point] or not anchors[relativePoint] or not self:Number(x) or not self:Number(y) then return false end
  db.point,db.relativePoint,db.x,db.y=point,relativePoint,x,y
  if includeSize then
    local w,h=frame:GetSize()
    if self:Number(w) and self:Number(h) and w>0 and h>0 then db.width,db.height=w,h end
  end
  return true
end
function S:Center(frame)
  if not self:Safe(frame) then return end
  local status,x,y=KHQOL.ReadPublicAPI(frame.GetCenter,frame)
  local ss,scale=KHQOL.ReadPublicAPI(frame.GetEffectiveScale,frame)
  local ps,parentScale=KHQOL.ReadPublicAPI(UIParent.GetEffectiveScale,UIParent)
  if status~="ok" or ss~="ok" or ps~="ok" or not self:Number(x) or not self:Number(y) or not self:Number(scale) or not self:Number(parentScale) or parentScale<=0 then return end
  return x*scale/parentScale,y*scale/parentScale,scale/parentScale
end
function S:Committed(apply)
  if apply then apply() end
  if KHQOL.profileApplying or KHQOL.profileClosingEditors then return end
  if KHQOL.SaveCurrentProfile then KHQOL:SaveCurrentProfile() end
  local s=KHQOL.settings
  if s and s:IsShown() and not s.buildingPage then s:RefreshActivePage() end
end
function S:SaveSettingsWindow(frame)
  local x,y=self:Center(frame); if not x then return end
  local cx,cy=UIParent:GetCenter()
  KHQOL.db.toolWindows=KHQOL.db.toolWindows or {}
  KHQOL.db.toolWindows.settings={x=x-cx,y=y-cy}
end
function S:ApplySettingsWindow(frame)
  local p=KHQOL.db.toolWindows and KHQOL.db.toolWindows.settings
  if not p or not self:Number(p.x) or not self:Number(p.y) then return end
  local scale=frame:GetEffectiveScale()/UIParent:GetEffectiveScale()
  local maxX=math.max(0,(UIParent:GetWidth()-frame:GetWidth()*scale)/2)
  local maxY=math.max(0,(UIParent:GetHeight()-frame:GetHeight()*scale)/2)
  local x=math.max(-maxX,math.min(maxX,p.x));local y=math.max(-maxY,math.min(maxY,p.y))
  frame:ClearAllPoints();frame:SetPoint("CENTER",UIParent,"CENTER",x/scale,y/scale)
end

function S:FinishDrags(key)
  local m=KHQOL.modules
  local entries={{"range",m.range.Display.frame},{"castBar",m.castBar.frame},
    {"resourceSwing",_G.KHQOLResourceSwingFrame},{"resourceSwing",_G.KHQOLResourceSwingAmmoAnchor},
    {"resourceSwing",m.resourceSwing.comboFrame},{"buffReminder",_G.ForeverBuffReminder and ForeverBuffReminder.anchor},
    {"todo",m.clock.todoMinimapButton},{nil,KHQOL.minimapButton}}
  for _,entry in ipairs(entries) do
    local frame=entry[2]
    if (not key or key==entry[1]) and self:Safe(frame) and (frame.positionMoving or frame.dragging) then
      local stop=frame:GetScript("OnDragStop")
      if stop then stop(frame) else frame:StopMovingOrSizing() end
    end
  end
  local c=m.campfire
  if (not key or key=="campfire") and c.ui and c.ui.root.cfaMoving and c.StopPositionDrag then c:StopPositionDrag() end
end

-- Normalize related owned regions around a requested (possibly reset) center.
-- This keeps a reset preview's bounds from accidentally using old world coords.
function S:Bounds(frame,x,y,w,h,children)
  local ax,ay=self:Center(frame);local dx,dy=x-(ax or x),y-(ay or y)
  local left,bottom,right,top=x-w/2,y-h/2,x+w/2,y+h/2
  for _,child in ipairs(children or {}) do
    if self:Safe(child) and child:IsShown() then
      local l,b,cw,ch=child:GetRect();local ratio=child:GetEffectiveScale()/UIParent:GetEffectiveScale()
      if self:Number(l) and self:Number(b) and self:Number(cw) and self:Number(ch) then
        left=math.min(left,l*ratio+dx);bottom=math.min(bottom,b*ratio+dy)
        right=math.max(right,(l+cw)*ratio+dx);top=math.max(top,(b+ch)*ratio+dy)
      end
    end
  end
  return (left+right)/2,(bottom+top)/2,right-left,top-bottom
end
