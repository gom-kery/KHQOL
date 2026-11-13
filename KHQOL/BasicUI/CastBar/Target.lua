local _,KHQOL=...
KHQOL = assert(_G.KHQOL, "Install and enable the KHQOL core addon.")
local C=KHQOL.modules.castBar
local call=KHQOL.PublicCall
local position,layers=KHQOL.NativePosition,KHQOL.WindowLayers
local function finite(v) return KHQOL.IsPublicNumber(v) end
local function editing() return call(EditModeManagerFrame and EditModeManagerFrame.IsShown,EditModeManagerFrame)==true end
local function activeUnits()
  local unit=KHQOL.modules.unitFrames
  if unit and unit:IsEnabled() then return unit end
end
function C:TargetFrame()
  local root=_G.TargetFrame
  if not layers:Readable(root) then return end
  local frame=call(function() return root.spellbar end) or _G.TargetFrameSpellBar
  if not layers:Readable(frame) or type(frame.SetPoint)~="function" or type(frame.GetPoint)~="function" then return end
  return frame,root
end
function C:TargetBase()
  local f,root=self:TargetFrame();if not f then return end
  local cfg=self:GetDB().targetPosition
  if editing() then return end
  local controlled=self:IsEnabled() and cfg.enabled
  local U=activeUnits()
  local target=U and U:GetDB().target
  local category=not controlled and U and U:TargetAuraCategory()
  local a=category and target.auras[category]
  local above=a and a.enabled and a.position=="above"
  if not controlled and not above then return end
  if controlled then
    -- The selected position must not depend on native smallSize/haveToT or
    -- aura geometry, which may be restricted after the cast starts.
    local parts=U and U:UnitParts("target")
    local owner=U and U.units and U.units.target
    local bar=parts and (target.showPower~=false and parts.power or owner and owner.healthDisplay or parts.health)
    return f,bar or root,0,-10,cfg.x,cfg.y,true
  end
  -- Native default when auras are above. Never taint buffsOnTop or call the
  -- native AdjustPosition/update function from addon execution.
  local status,small,tot=KHQOL.ReadPublicAPI(function() return root.smallSize,root.haveToT end)
  if status~="ok" then return end
  local x,y=small and 38 or 43,small and 3 or 5
  if tot then
    y=small and -48 or -46
    if call(InputUtil and InputUtil.IsGamepadUIEnabled)==true then x=small and 118 or 123 end
  end
  return f,root,x,y,0,0,false
end

local function targetGeometry(f,relative,x,y,dx,dy)
  local rx,ry=call(relative.GetCenter,relative)
  local rw,rh=call(relative.GetSize,relative)
  local rs,fs=call(relative.GetEffectiveScale,relative),call(f.GetEffectiveScale,f)
  local ps=call(UIParent.GetEffectiveScale,UIParent)
  if not finite(rx) or not finite(ry) or not finite(rw) or not finite(rh)
    or not finite(rs) or rs<=0 or not finite(fs) or fs<=0 or not finite(ps) or ps<=0 then return end
  local ratio=rs/ps
  return (rx-rw/2+x+dx)*ratio,(ry-rh/2+y+dy)*ratio,fs/ps,ratio
end

function C:ApplyTargetPosition()
  if self.targetApplying then return end
  if not layers:OutsideCombat() then
    self.targetPending=true
    if self.targetDisplay and (not self:IsEnabled() or not self.db.targetPosition.enabled) then
      self:SyncTargetCastVisibility(self.targetDisplay)
    end
    return
  end
  self.targetApplying=true
  local ok,err=pcall(function()
    local f,root=self:TargetFrame();local state=self.targetOwner
    local frame,relative,x,y,dx,dy,controlled=self:TargetBase()
    if state and (state.frame~=f or not frame or controlled) then
      if not position.Release(self,state) then self.targetPending=true;return end
      self.targetOwner=nil;state=nil
    end
    if controlled then
      local left,top,scale=targetGeometry(frame,relative,x,y,dx,dy)
      if left then
        self.targetPending=not self:ApplyTargetCastDisplay(frame,root,left,top,scale)
      else
        if self.targetDisplay and self.targetDisplay.source~=frame then self:ReleaseTargetCastDisplay() end
        self.targetPending=true
      end
      return
    end
    self:ReleaseTargetCastDisplay()
    if not frame then self.targetPending=self.targetDisplay~=nil;return end
    if not state then
      self.targetOwners=self.targetOwners or setmetatable({}, {__mode="k"})
      state=self.targetOwners[frame]
      if not state then
        state={frame=frame};self.targetOwners[frame]=state
        state.canApply=function() return C.targetOwner==state and (C:IsEnabled() or activeUnits()~=nil) end
        local function reapply() if C.targetOwner==state then C:ApplyTargetPosition() end end
        position.Hook(self,state,reapply)
        frame:HookScript("OnShow",reapply)
        if type(frame.AdjustPosition)=="function" then hooksecurefunc(frame,"AdjustPosition",reapply) end
      end
      self.targetOwner=state
    end
    local fs=call(frame.GetEffectiveScale,frame);local rs=call(relative.GetEffectiveScale,relative)
    if not finite(fs) or fs<=0 or not finite(rs) or rs<=0 then self.targetPending=true;return end
    self.targetPending=not position.Write(self,state,{{"TOPLEFT",relative,"BOTTOMLEFT",(x+dx)*rs/fs,(y+dy)*rs/fs}})
  end)
  self.targetApplying=false
  if not ok then
    self:ReleaseTargetCastDisplay()
    self.targetPending=true;self.targetPositionReason="게임이 대상 시전바 위치 변경을 제한했습니다. 전투 종료 후 다시 적용합니다."
  elseif not self.targetPending then self.targetPositionReason=nil end
end
function C:TargetPositionPreview()
  if call(InCombatLockdown)==true or editing() then return end
  local f,relative,x,y,dx,dy,controlled=self:TargetBase();if not controlled then return end
  local left,top,scale,ratio=targetGeometry(f,relative,x,y,dx,dy)
  if not left then return end
  local style=self:GetDB().targetStyle
  local width=math.max(1,style.appearance.width-(style.icon.enabled and style.icon.size+2 or 0))*scale
  local height=style.appearance.height*scale
  local cx,cy=left+width/2,top-height/2
  if not self.targetProxy then self.targetProxy=CreateFrame("Frame",nil,UIParent);self.targetProxy:EnableMouse(false);self.targetProxy:Hide() end
  local p=self.targetProxy;p:ClearAllPoints();p:SetPoint("CENTER",UIParent,"BOTTOMLEFT",cx,cy);p:SetSize(width,height)
  local cfg=self:GetDB().targetPosition
  return {id="cast.target",name="대상 시전바",key="castBar",frame=p,sample="대상 시전바 · 위치 예시",sampleSize=12,
    write=function(a,b) cfg.x=math.max(-1000,math.min(1000,KHQOL.PositionStore:Round(cfg.x+a/ratio)));cfg.y=math.max(-1000,math.min(1000,KHQOL.PositionStore:Round(cfg.y+b/ratio))) end,
    apply=function() C:ApplyTargetPosition() end,
    resetPoint={point="CENTER",relativePoint="BOTTOMLEFT",x=cx-cfg.x*ratio,y=cy-cfg.y*ratio},resetPhysical=true,
    resetWrite=function() cfg.x=0;cfg.y=0 end}
end
