local _,addon=...
if not addon.loadUnitFrames then return end
local K=_G.KHQOL
local M=K.modules.unitFrames
local call=K.PublicCall
function M:SimpleAuraFrame(unit)
  local p=self:UnitParts(unit)
  local frame=p and ((p.context and p.context.Auras) or (p.root and (p.root.Auras or p.root.BuffFrame)))
  if frame and K.WindowLayers:Readable(frame) and type(frame.GetPoint)=='function' and type(frame.SetPoint)=='function' then return frame end
end
function M:PositionPartAvailable(unit,part)
  if not self:IsEnabled() then return false end
  local d=self:GetDB()[unit]
  if part~='auras' then return d.compact==true end
  if unit=='player' then
    for _,kind in ipairs({'buffs','debuffs'}) do if d.auras[kind].enabled and self:PlayerAuraFrame(kind) then return true end end
  elseif unit=='target' then
    if self:TargetAuraContainer() then for _,cfg in pairs(d.auras) do if cfg.enabled then return true end end end
  else return d.simpleAuras.enabled==true and self:SimpleAuraFrame(unit)~=nil end
  return false
end
function M:ApplySimpleAuraPosition(unit)
  self.simpleAuraOwners=self.simpleAuraOwners or {}
  local state=self.simpleAuraOwners[unit];local frame=self:SimpleAuraFrame(unit)
  local d=self:GetDB()[unit];local cfg=d.simpleAuras
  if not K.WindowLayers:OutsideCombat() then self.pending=true;return end
  if state and (state.frame~=frame or not self:IsEnabled() or not cfg.enabled) then self:ReleaseAuraPosition(state);self.simpleAuraOwners[unit]=nil;state=nil end
  if not self:IsEnabled() or not frame or not cfg.enabled or call(EditModeManagerFrame and EditModeManagerFrame.IsShown,EditModeManagerFrame)==true then return end
  if not state then state={frame=frame};self.simpleAuraOwners[unit]=state end
  self:HookAuraPosition(state,function() M:ApplySimpleAuraPosition(unit) end)
  local points=K.NativePosition.Read(frame)
  if not points or not points[1] then self.pending=true;return end
  local original=state.originalPoints or points
  local moved={}
  for i,p in ipairs(original) do local q={};for j=1,p.n or 5 do q[j]=p[j] end;q.n=p.n;moved[i]=q end
  moved[1][4]=(original[1][4] or 0)+cfg.x;moved[1][5]=(original[1][5] or 0)+cfg.y
  if not self:WriteAuraPosition(state,moved) then self.pending=true end
end
hooksecurefunc(M,'ApplySettingsNow',function()
  for _,unit in ipairs({'pet','targettarget','focus'}) do M:ApplySimpleAuraPosition(unit) end
  if K.PositionAnchors then K.PositionAnchors:Queue() end
end)
local original=M.PositionPreviews
function M:PositionPreviews(focus)
  local list=original(self,focus)
  if not self:IsEnabled() or not K.WindowLayers:OutsideCombat() then return list end
  local roots={};for _,t in ipairs(self:RootEditorTargets()) do roots[t.settingsRoute.unit]=t end
  local seen={};for _,t in ipairs(list) do seen[t.id]=true end
  for _,unit in ipairs(self.unitTokens) do
    local d=self:GetDB()[unit];local root=roots[unit]
    if d.compact and root and not self:UnitParts(unit) then
      local x,y,w,h=K.PositionUtils.Rect(root.frame)
      if x then
        for _,part in ipairs({'labels','status'}) do
          local key=part=='labels' and 'name' or 'status';local id='unitFrames.'..unit..'.'..key
          if not seen[id] then
            local ox,oy=d[key..'X'] or 0,d[key..'Y'] or 0
            local width,height=part=='labels' and math.max(80,w) or 24,part=='labels' and 20 or 24
            local baseX,baseY=x,part=='labels' and y+h/2+14 or y
            local p=K.PositionUtils:Preview('missingPart.'..id,{point='CENTER',relativePoint='BOTTOMLEFT',x=baseX+ox,y=baseY+oy},width,height)
            local cfg,k,limit=d,key,part=='labels' and 100 or 200
            list[#list+1]={id=id,name=(K.UI.SettingsNavigation.units[unit] or unit)..' · '..(part=='labels' and '이름 예시' or '상태·징표 예시'),frame=p,anchorFallback=true,
              settingsRoute={module='unitFrames',unit=unit,part=part},sample='유닛 없음 · 상대 위치 예시',
              write=function(dx,dy) cfg[k..'X']=math.max(-limit,math.min(limit,K.PositionStore:Round((cfg[k..'X'] or 0)+dx)));cfg[k..'Y']=math.max(-limit,math.min(limit,K.PositionStore:Round((cfg[k..'Y'] or 0)+dy))) end,
              apply=function() M:ApplySettings() end,resetWrite=function() cfg[k..'X']=0;cfg[k..'Y']=0 end}
          end
        end
      end
    end
  end
  for _,unit in ipairs({'pet','targettarget','focus'}) do
    local cfg=self:GetDB()[unit].simpleAuras;local frame=self:SimpleAuraFrame(unit)
    local x,y,w,h,r=K.PositionUtils.Rect(frame)
    if cfg.enabled and x and w>0 and h>0 then
      local proxy=K.PositionUtils:Preview('simpleAura.'..unit,{point='CENTER',relativePoint='BOTTOMLEFT',x=x,y=y},w,h)
      local t={id='unitFrames.'..unit..'.auras',name=(K.UI.SettingsNavigation.units[unit] or unit)..' · 버프·디버프',frame=proxy,
        settingsRoute={module='unitFrames',unit=unit,part='auras'},sample='버프·디버프 위치',
        write=function(dx,dy) cfg.x=math.max(-300,math.min(300,K.PositionStore:Round(cfg.x+dx/r)));cfg.y=math.max(-300,math.min(300,K.PositionStore:Round(cfg.y+dy/r))) end,
        apply=function() M:ApplySettings() end,resetWrite=function() cfg.x=0;cfg.y=0 end}
      list[#list+1]=t
    end
  end
  return list
end
