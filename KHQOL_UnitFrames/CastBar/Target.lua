local _,KHQOL=...
KHQOL = assert(_G.KHQOL, "Install and enable the KHQOL core addon.")
local C=KHQOL.modules.castBar
local U=KHQOL.modules.unitFrames
local call=KHQOL.PublicCall
local function finite(v) return KHQOL.IsPublicNumber(v) end
local function editing() return call(EditModeManagerFrame and EditModeManagerFrame.IsShown,EditModeManagerFrame)==true end
function C:TargetFrame()
  local root=_G.TargetFrame;local frame=root and (root.spellbar or _G.TargetFrameSpellBar)
  if not frame or type(frame.SetPoint)~="function" or type(frame.GetPoint)~="function" then return end
  return frame,root
end
function C:TargetBase()
  local f,root=self:TargetFrame();if not f then return end
  local cfg=self:GetDB().targetPosition
  local controlled=self:IsEnabled() and cfg.enabled and not editing()
  local category=U:TargetAuraCategory();local a=category and U:GetDB().target.auras[category]
  local above=U:IsEnabled() and not editing() and a and a.enabled and a.position=="above"
  if not controlled and not above then return end
  local parts=U:UnitParts("target");local owner=U.units and U.units.target
  if controlled then
    -- The selected position must not depend on native smallSize/haveToT or
    -- aura geometry, which may be restricted after the cast starts.
    local bar=parts and (U:GetDB().target.showPower~=false and parts.power or owner and owner.healthDisplay or parts.health)
    return f,bar or root,0,-10,cfg.x,cfg.y,true
  end
  -- Native default when auras are above. Never taint buffsOnTop or call the
  -- native AdjustPosition/update function from addon execution.
  local small,tot=root.smallSize,root.haveToT
  if not KHQOL.IsPublicValue(small) or not KHQOL.IsPublicValue(tot) then return end
  local x,y=small and 38 or 43,small and 3 or 5
  if tot then
    y=small and -48 or -46
    if call(InputUtil and InputUtil.IsGamepadUIEnabled)==true then x=small and 118 or 123 end
  end
  return f,root,x,y,controlled and cfg.x or 0,controlled and cfg.y or 0,controlled
end
function C:ApplyTargetPosition()
  if self.targetApplying then return end
  local current=self:TargetFrame()
  -- An explicitly unprotected native bar may keep its saved anchor in combat.
  -- Protected/unknown bars defer; never force a protected geometry operation.
  if call(InCombatLockdown)==true and (not current or call(current.IsProtected,current)~=false) then self.targetPending=true;return end
  self.targetApplying=true
  local ok,err=pcall(function()
    self:ApplyTargetStyle()
    local f=self:TargetFrame();local state=self.targetOwner
    if state and state.frame~=f then U:ReleaseAuraPosition(state);self.targetOwner=nil;state=nil end
    local frame,relative,x,y,dx,dy=self:TargetBase()
    if not frame then if state then U:ReleaseAuraPosition(state) end;self.targetPending=nil;return end
    if not state then
      state={frame=frame,canApply=function() return C:IsEnabled() or U:IsEnabled() end};self.targetOwner=state
      U:HookAuraPosition(state,function() C:ApplyTargetPosition() end)
      frame:HookScript("OnShow",function() C:ApplyTargetPosition() end)
      if type(frame.AdjustPosition)=="function" then hooksecurefunc(frame,"AdjustPosition",function() C:ApplyTargetPosition() end) end
    end
    local fs=call(frame.GetEffectiveScale,frame);local rs=call(relative.GetEffectiveScale,relative)
    if not finite(fs) or fs<=0 or not finite(rs) or rs<=0 then self.targetPending=true;return end
    self.targetPending=not U:WriteAuraPosition(state,{{"TOPLEFT",relative,"BOTTOMLEFT",(x+dx)*rs/fs,(y+dy)*rs/fs}})
  end)
  self.targetApplying=false
  if not ok then self.targetPending=true;self.targetPositionReason="게임이 대상 시전바 위치 변경을 제한했습니다. 전투 종료 후 다시 적용합니다."
  elseif not self.targetPending then self.targetPositionReason=nil end
end
function C:TargetPositionPreview()
  if call(InCombatLockdown)==true or editing() then return end
  local f,relative,x,y,dx,dy,controlled=self:TargetBase();if not controlled then return end
  local rx,ry=call(relative.GetCenter,relative);local rw,rh=call(relative.GetSize,relative)
  local rs=call(relative.GetEffectiveScale,relative);local fs=call(f.GetEffectiveScale,f);local ps=call(UIParent.GetEffectiveScale,UIParent)
  if not finite(rx) or not finite(ry) or not finite(rw) or not finite(rh) or not finite(rs) or rs<=0 or not finite(fs) or fs<=0 or not finite(ps) or ps<=0 then return end
  local w=call(f.GetWidth,f,true);local h=call(f.GetHeight,f,true)
  if not finite(w) or w<=0 then w=200 end;if not finite(h) or h<=0 then h=20 end
  local ratio=rs/ps;local width,height=w*fs/ps,h*fs/ps
  local cx,cy=(rx-rw/2+x+dx)*ratio+width/2,(ry-rh/2+y+dy)*ratio-height/2
  if not self.targetProxy then self.targetProxy=CreateFrame("Frame",nil,UIParent);self.targetProxy:EnableMouse(false);self.targetProxy:Hide() end
  local p=self.targetProxy;p:ClearAllPoints();p:SetPoint("CENTER",UIParent,"BOTTOMLEFT",cx,cy);p:SetSize(width,height)
  local cfg=self:GetDB().targetPosition
  return {id="cast.target",name="대상 시전바",key="castBar",frame=p,sample="대상 시전바 · 위치 예시",sampleSize=12,
    write=function(a,b) cfg.x=math.max(-1000,math.min(1000,KHQOL.PositionStore:Round(cfg.x+a/ratio)));cfg.y=math.max(-1000,math.min(1000,KHQOL.PositionStore:Round(cfg.y+b/ratio))) end,
    apply=function() C:ApplyTargetPosition() end,
    resetPoint={point="CENTER",relativePoint="BOTTOMLEFT",x=cx-cfg.x*ratio,y=cy-cfg.y*ratio},resetPhysical=true,
    resetWrite=function() cfg.x=0;cfg.y=0 end}
end
