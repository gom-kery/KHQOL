local _,KHQOL=...
KHQOL = assert(_G.KHQOL, "Install and enable the KHQOL core addon.")
local M=KHQOL.modules.unitFrames
local call=KHQOL.PublicCall
local methods={maxBuffs={"GetMaxBuffs","SetMaxBuffs"},maxDebuffs={"GetMaxDebuffs","SetMaxDebuffs"},
 small={"GetSmallAuraSize","SetSmallAuraSize"},large={"GetLargeAuraSize","SetLargeAuraSize"}}
local function finite(v) return KHQOL.IsPublicValue(v) and type(v)=="number" and v==v and math.abs(v)<math.huge end
function M:AuraLayout(cfg)
  local n=finite(cfg and cfg.perRow) and cfg.perRow or 8
  local rows=finite(cfg and cfg.maxRows) and cfg.maxRows or 4
  n=math.max(3,math.min(10,math.floor(n)));rows=math.max(1,math.min(4,math.floor(rows)))
  local growth=cfg and cfg.growth or "RIGHT_DOWN"
  local left=growth=="LEFT_UP" or growth=="LEFT_DOWN"
  local up=growth=="RIGHT_UP" or growth=="LEFT_UP"
  return n,rows,left,up,(up and "BOTTOM" or "TOP")..(left and "RIGHT" or "LEFT")
end
local mirror={"IsFlowLayoutMirroredVertically","SetFlowLayoutMirroredVertically"}
local function pairFor(key) return key=="mirror" and mirror or methods[key] end
local function valid(key,v) return key=="mirror" and type(v)=="boolean" or key~="mirror" and finite(v) end
local function nativePoints(f)
  local n=call(f.GetNumPoints,f);if not finite(n) or n<0 or n>32 or n~=math.floor(n) then return end
  local points={}
  for i=1,n do
    local status,p,r,rp,x,y=KHQOL.ReadPublicAPI(f.GetPoint,f,i);if status~="ok" then return end
    points[i]={n=5,p,r,rp,x,y}
  end
  return points
end
local function samePoints(a,b)
  if not a or not b or #a~=#b then return false end
  for i,point in ipairs(a) do
    if point.n~=b[i].n then return false end
    for j=1,point.n do if point[j]~=b[i][j] then return false end end
  end
  return true
end
-- AuraContainer anchors can resolve to secret geometry. Capture the PUBLIC
-- native SetPoint arguments, rather than comparing resolved secret coordinates.
function M:HookAuraPosition(state,reapply)
  if state.positionHook then return end
  state.positionHook=true;state.originalPoints=nativePoints(state.frame)
  hooksecurefunc(state.frame,"SetPoint",function(f,...)
    if state.positionWriting or state.releasing then return end
    local point={n=select("#",...),...}
    for i=1,point.n do if not KHQOL.IsPublicValue(point[i]) then
      state.originalPoints=nil;state.positionOwned=nil;M.pending=true;M.propertyDeferred=true;return
    end end
    if type(point[1])~="string" then return end
    state.originalPoints={point}
    local active
    if state.canApply then active=state.canApply() else active=M:IsEnabled() end
    if active then reapply() end
  end)
end
function M:WriteAuraPosition(state,points)
  if not state.originalPoints then self.pending=true;self.propertyDeferred=true;return false end
  state.positionWriting=true
  state.positionOwned=true
  local ok=pcall(function()
    state.frame:ClearAllPoints()
    for _,p in ipairs(points) do state.frame:SetPoint(unpack(p,1,p.n or 5)) end
  end)
  state.positionWriting=false
  if not ok then self.pending=true;self.propertyDeferred=true end
  return ok
end
function M:ReleaseAuraPosition(state)
  if state.positionOwned and state.originalPoints then
    state.positionWriting=true
    local ok=pcall(function() state.frame:ClearAllPoints();for _,p in ipairs(state.originalPoints) do state.frame:SetPoint(unpack(p,1,p.n or 5)) end end)
    state.positionWriting=false
    if ok then state.positionOwned=nil else self.pending=true;self.propertyDeferred=true end
  end
end
function M:TargetAuraContainer(p)
  p=p or self:UnitParts("target")
  local f=p and p.context and p.context.Auras
  if not f then return end
  for _,pair in pairs(methods) do if type(f[pair[1]])~="function" or type(f[pair[2]])~="function" then return end end
  return f
end
function M:TargetAuraCategory()
  local player=call(UnitIsPlayer,"target")
  if player==true and call(UnitIsFriend,"player","target")==true then return "friendlyPlayer" end
  if player==false and call(UnitCanAttack,"player","target")==true then return "attackableNPC" end
end
local function property(owner,f,key,value)
  local pair=pairFor(key);local current=call(f[pair[1]],f)
  if not valid(key,current) then return false end
  local record=owner.properties[key]
  if not record then record={original=current};owner.properties[key]=record
  elseif current~=record.last then record.original=current end
  if current~=value and KHQOL.ReadPublicAPI(f[pair[2]],f,value)~="ok" then return false end
  record.last=value;return true
end
function M:ReleaseTargetAuras(state)
  if not state then return end
  local f=state.frame
  state.releasing=true
  for key,record in pairs(state.properties) do
    local pair=pairFor(key);local current=call(f[pair[1]],f)
    if valid(key,current) then
      if current~=record.last or KHQOL.ReadPublicAPI(f[pair[2]],f,record.original)=="ok" then state.properties[key]=nil end
    else self.pending=true;self.propertyDeferred=true end
  end
  self:ReleaseAuraPosition(state);state.releasing=false
  self:Release(state)
end
function M:ApplyTargetAuras(owner,p)
  if owner.auraApplying then return end
  local fighting=call(InCombatLockdown)==true
  if not fighting then self.auraAppliedSettings=KHQOL.MergeDefaults({},self:GetDB().target.auras,"tables") end
  owner.auraApplying=true
  local ok,err=pcall(function()
    local f=M:TargetAuraContainer(p)
    local state=owner.auraOwner
    if state and state.frame~=f then M:ReleaseTargetAuras(state);state=nil;owner.auraOwner=nil end
    if not f then return end
    if not owner.auraHooks then
      owner.auraHooks=true
      for _,method in ipairs({"ConfigureAuraContainer","AnchorAuraContainer"}) do
        if type(p.root[method])=="function" then hooksecurefunc(p.root,method,function()
          if M:IsEnabled() then M:ApplyTargetAuras(owner,owner.parts) end
        end) end
      end
    end
    local category=M:TargetAuraCategory();local settings=M.auraAppliedSettings
    if not settings then M.pending=true;return end
    if not fighting then M:PrepareTargetAuraLayouts(owner,p,settings) end
    local cfg=category and settings[category]
    if not M:IsEnabled() or call(EditModeManagerFrame and EditModeManagerFrame.IsShown,EditModeManagerFrame)==true or not cfg or not cfg.enabled then
      M:SetTargetAuraLayoutsActive(owner,nil)
      if fighting then M.pending=true;return end
      M:ReleaseTargetAuras(state);return
    end
    if not state then state={frame=f,properties={}};owner.auraOwner=state end
    M:HookAuraPosition(state,function() M:ApplyTargetAuras(owner,owner.parts) end)
    local defaults=TargetFrameAuraContainerDefaults or {}
    local buffs=finite(defaults.MaxBuffs) and defaults.MaxBuffs or 32
    local debuffs=finite(defaults.MaxDebuffs) and defaults.MaxDebuffs or 16
    local size=math.max(8,math.min(64,tonumber(cfg.size) or 20))
    local split=(cfg.layoutEnabled or cfg.separatePositions) and owner.auraLayouts and owner.auraLayouts[category]
    M:SetTargetAuraLayoutsActive(owner,split and category or nil)
    -- Inbound delegates execute in the client's secure partition. Enforce both
    -- sizes even when the target first appears after combat has already begun.
    for key,value in pairs({maxBuffs=not split and cfg.showBuffs and buffs or 0,maxDebuffs=not split and cfg.showDebuffs and debuffs or 0,small=size,large=size}) do
      if not property(state,f,key,value) then M.pending=true;M.propertyDeferred=true end
    end
    if fighting then M.pending=true;return end
    local bar=owner.compactActive and owner.healthDisplay or p.health
    if cfg.position~="above" and M:GetDB().target.showPower~=false then bar=p.power end
    local above=cfg.position=="above"
    if type(f[mirror[1]])=="function" and type(f[mirror[2]])=="function" and not property(state,f,"mirror",above) then M.pending=true;M.propertyDeferred=true end
    local x=math.max(-300,math.min(300,tonumber(cfg.x) or 0));local y=math.max(-300,math.min(300,tonumber(cfg.y) or 0))
    M:WriteAuraPosition(state,{{above and "BOTTOMLEFT" or "TOPLEFT",bar,above and "TOPLEFT" or "BOTTOMLEFT",x,y+(above and 4 or -4)}})
  end)
  owner.auraApplying=false
  if not ok then error(err,0) end
  local cast=KHQOL.modules.castBar
  if cast and cast.ApplyTargetPosition then cast:ApplyTargetPosition() end
end
function M:TargetAuraPosition(cfg,kind)
  local item=cfg[kind] or {}
  return item.position or cfg.position or "below",finite(item.x) and item.x or cfg.x or 0,finite(item.y) and item.y or cfg.y or 0
end
function M:SetTargetAuraPosition(category,kind,key,value)
  local cfg=self:GetDB().target.auras[category]
  if not cfg or (kind~="buffs" and kind~="debuffs") then return end
  cfg[kind]=cfg[kind] or {};cfg[kind][key]=key=="position" and value or KHQOL.PositionStore:Round(value)
  self:ApplySettings()
end
function M:SetSeparateTargetAuras(category,on)
  local cfg=self:GetDB().target.auras[category];if not cfg then return end
  if on then
    local first=category=="friendlyPlayer" and "buffs" or "debuffs"
    for _,kind in ipairs({"buffs","debuffs"}) do
      local item=cfg[kind];item.position=item.position or cfg.position
      if item.x==nil then item.x=cfg.x or 0 end
      if item.y==nil then item.y=(cfg.y or 0)+(kind~=first and (cfg.position=="above" and 1 or -1)*((cfg.size or 20)+3) or 0) end
    end
  end
  cfg.separatePositions=on and true or false;self:ApplySettings()
end
function M:SetTargetAuraLayoutsActive(owner,category)
  for key,layouts in pairs(owner.auraLayouts or {}) do
    for _,f in pairs(layouts) do
      if key==category then
        KHQOL.ReadPublicAPI(f.SetPlayerIsTarget,f,call(UnitIsUnit,"player","target")==true)
      end
      if KHQOL.ReadPublicAPI(f.SetEnabled,f,key==category)~="ok" then M.pending=true;M.propertyDeferred=true end
    end
  end
end
function M:RefreshTargetAuraLayouts()
  local owner=self.units and self.units.target
  for _,layouts in pairs(owner and owner.auraLayouts or {}) do
    for _,f in pairs(layouts) do
      -- UpdateAllAuras is an explicitly exposed secure inbound delegate on the
      -- verified template; no aura records cross into addon execution.
      if KHQOL.ReadPublicAPI(f.UpdateAllAuras,f)~="ok" then self.pending=true;self.propertyDeferred=true end
    end
  end
end
function M:PrepareTargetAuraLayouts(owner,p,settings)
  owner.auraLayouts=owner.auraLayouts or {}
  local native=self:TargetAuraContainer(p)
  if not native or not AnchorUtil or not AnchorUtil.FlowDirection then return end
  for category,cfg in pairs(settings) do
    if cfg.enabled and (cfg.layoutEnabled or cfg.separatePositions) then
      local layouts=owner.auraLayouts[category]
      if not layouts then
        local created={};local ok=pcall(function()
          for _,kind in ipairs({"buffs","debuffs"}) do
            local f=CreateFrame("AuraContainer",nil,p.root,"KHQOLNativeTargetAuraLayoutTemplate");created[kind]=f
            for _,method in ipairs({"SetEnabled","SetUnit","SetMaxBuffs","SetMaxDebuffs","SetSmallAuraSize","SetLargeAuraSize","SetFlowLayoutGrowthDirection","SetFlowLayoutAnchorPoint","SetFlowLayoutMaximumLineSize","SetNumConstrainedFlowLayoutLines"}) do assert(type(f[method])=="function") end
            f:SetEnabled(false);f:SetUnit("target")
          end
        end)
        if ok then layouts=created;owner.auraLayouts[category]=layouts;self.auraLayoutUnavailable=nil
        else
          for _,f in pairs(created) do if f.SetEnabled then pcall(f.SetEnabled,f,false) end;if f.Hide then pcall(f.Hide,f) end end
          self.auraLayoutUnavailable="기본 오라 행 배치 기능을 확인할 수 없어 기존 배치를 유지합니다."
        end
      end
      if layouts then
        local size=math.max(8,math.min(64,tonumber(cfg.size) or 20))
        local first=category=="friendlyPlayer" and "buffs" or "debuffs";local second=first=="buffs" and "debuffs" or "buffs"
        for _,kind in ipairs({first,second}) do
          local position,x,y=self:TargetAuraPosition(cfg,kind)
          if not cfg.separatePositions then position,x,y=cfg.position,cfg.x or 0,cfg.y or 0 end
          local above=position=="above"
          local bar=owner.compactActive and owner.healthDisplay or p.health
          if not above and self:GetDB().target.showPower~=false then bar=p.power end
          local flow=cfg.layoutEnabled and cfg[kind] or {perRow=8,maxRows=kind=="buffs" and 4 or 2,growth=above and "RIGHT_UP" or "RIGHT_DOWN"}
          local f=layouts[kind];local n,rows,left,up,point=self:AuraLayout(flow)
          f:SetMaxBuffs(kind=="buffs" and cfg.showBuffs and n*rows or 0)
          f:SetMaxDebuffs(kind=="debuffs" and cfg.showDebuffs and n*rows or 0)
          f:SetSmallAuraSize(size);f:SetLargeAuraSize(size)
          f:SetTargetIsFriendly(category=="friendlyPlayer");f:SetPlayerIsTarget(false)
          f:SetShowAuraCount(call(native.ShouldShowAuraCount,native)==true)
          f:SetFlowLayoutAnchorPoint(point)
          f:SetFlowLayoutGrowthDirection(left and AnchorUtil.FlowDirection.Left or AnchorUtil.FlowDirection.Right,up and AnchorUtil.FlowDirection.Up or AnchorUtil.FlowDirection.Down)
          f:SetFlowLayoutMaximumLineSize(n*size+(n-1)*3);f:SetConstrainedFlowLayoutLineSize(n*size+(n-1)*3);f:SetNumConstrainedFlowLayoutLines(0)
          f:ClearAllPoints()
          x=math.max(-300,math.min(300,tonumber(x) or 0));y=math.max(-300,math.min(300,tonumber(y) or 0))
          if cfg.separatePositions or kind==first then
            y=y+(above and 4 or -4)+(above and not up and size or not above and up and -size or 0)
            f:SetPoint(point,bar,(above and "TOP" or "BOTTOM")..(left and "RIGHT" or "LEFT"),x,y)
          else
            -- The engine resolves the first group's secret size. Lua does not
            -- query visible aura counts, private groups or resolved geometry.
            local _,_,firstLeft=self:AuraLayout(cfg[first])
            f:SetPoint((above and "BOTTOM" or "TOP")..(left and "RIGHT" or "LEFT"),layouts[first],(above and "TOP" or "BOTTOM")..(firstLeft and "RIGHT" or "LEFT"),0,above and 3 or -3)
          end
        end
      end
    end
  end
end
function M:PlayerAuraFrame(kind)
  local f=kind=="buffs" and _G.BuffFrame or kind=="debuffs" and _G.DebuffFrame
  if not f or not f.AuraContainer or type(f.GetScale)~="function" or type(f.SetScale)~="function" or type(f.UpdateGridLayout)~="function" then return end
  if f.IsForbidden and call(f.IsForbidden,f)~=false then return end
  return f
end
function M:ReleasePlayerAura(state)
  self:ReleasePlayerAuraLayout(state)
  state.releasing=true;self:ReleaseAuraPosition(state)
  if state.scaleOwned and finite(state.originalScale) then
    state.scaleWriting=true;local ok=pcall(state.frame.SetScale,state.frame,state.originalScale);state.scaleWriting=false
    if ok then state.scaleOwned=nil else self.pending=true;self.propertyDeferred=true end
  end
  state.releasing=false
end
function M:ReleasePlayerAuraLayout(state)
  if not state.gridOriginal then return end
  local f=state.frame;local c=f.AuraContainer
  for key,value in pairs(state.gridOriginal) do
    local current=key=="maxAuras" and f.maxAuras or c[key]
    if KHQOL.IsPublicValue(current) and current==state.gridLastFields[key] then
      if key=="maxAuras" then f.maxAuras=value else c[key]=value end
    end
  end
  state.gridWriting=true
  for button,alpha in pairs(state.gridAlphas or {}) do
    pcall(button.SetAlpha,button,alpha)
    local points=state.gridPoints and state.gridPoints[button]
    if points then pcall(function() button:ClearAllPoints();for _,point in ipairs(points) do button:SetPoint(unpack(point,1,point.n)) end end) end
  end
  state.gridWriting=false
  state.gridOriginal=nil;state.gridAlphas=nil
  -- This routine has no aura lookup; it restores ordinary native anchor rules.
  if type(f.UpdateAuraContainerAnchor)=="function" then pcall(f.UpdateAuraContainerAnchor,f) end
end
function M:ApplyPlayerAuraLayout(state,cfg)
  local f=state.frame;local c=f.AuraContainer
  if not cfg.layoutEnabled then self:ReleasePlayerAuraLayout(state);return end
  if not KHQOL.IsPublicValue(f.auraFrames) or type(f.auraFrames)~="table" or not finite(c.iconScale) then
    self.playerAuraLayoutUnavailable="기본 플레이어 오라 배치를 확인할 수 없어 행·확장 조절을 보류합니다.";return
  end
  local n,rows,left,up,point=self:AuraLayout(cfg)
  if not state.gridOriginal then
    if not finite(f.maxAuras) then return end
    for _,key in ipairs({"iconStride","isHorizontal","addIconsToRight","addIconsToTop"}) do
      if not KHQOL.IsPublicValue(c[key]) or key=="iconStride" and not finite(c[key]) or key~="iconStride" and type(c[key])~="boolean" then
        self.playerAuraLayoutUnavailable="기본 플레이어 오라 배치값을 확인할 수 없어 행·확장 조절을 보류합니다.";return
      end
    end
    state.gridOriginal={maxAuras=f.maxAuras,iconStride=c.iconStride,isHorizontal=c.isHorizontal,addIconsToRight=c.addIconsToRight,addIconsToTop=c.addIconsToTop}
    state.gridAlphas={};state.gridPoints={};state.gridLastPoints={};state.gridAlphaHooks=state.gridAlphaHooks or {}
  end
  local capacity=math.min(state.gridOriginal.maxAuras,n*rows)
  if state.gridLastFields then
    for key,last in pairs(state.gridLastFields) do
      local current=key=="maxAuras" and f.maxAuras or c[key]
      local number=key=="maxAuras" or key=="iconStride"
      local valid=number and finite(current) or not number and KHQOL.IsPublicValue(current) and type(current)=="boolean"
      if valid and current~=last then state.gridOriginal[key]=current end
    end
    capacity=math.min(state.gridOriginal.maxAuras,n*rows)
  end
  state.gridCapacity=capacity;state.gridWriting=true
  c.iconStride=n;c.isHorizontal=true;c.addIconsToRight=not left;c.addIconsToTop=up;f.maxAuras=capacity
  state.gridLastFields={maxAuras=capacity,iconStride=n,isHorizontal=true,addIconsToRight=not left,addIconsToTop=up}
  -- Only fixed, public legacy player buttons are touched. No hasValidInfo,
  -- aura record, duration, instance ID, private anchor or pool inspection.
  for index=1,state.gridOriginal.maxAuras do
    local button=f.auraFrames[index]
    if KHQOL.IsPublicValue(button) and button and KHQOL.PositionStore:Safe(button) then
      if state.gridAlphas[button]==nil then state.gridAlphas[button]=call(button.GetAlpha,button) or 1 end
      local points=nativePoints(button)
      if points and not samePoints(points,state.gridLastPoints[button]) then state.gridPoints[button]=points end
      if not state.gridAlphaHooks[button] then
        state.gridAlphaHooks[button]=true
        local slot=index
        hooksecurefunc(button,"SetAlpha",function(frame,value)
          if state.gridWriting or not state.gridOriginal then return end
          if finite(value) then state.gridAlphas[frame]=value end
          if slot>state.gridCapacity then state.gridWriting=true;frame:SetAlpha(0);state.gridWriting=false end
        end)
      end
      local col=(index-1)%n;local row=math.floor((index-1)/n)
      button:ClearAllPoints();button:SetPoint(point,c,point,(left and -1 or 1)*col*35,(up and 1 or -1)*row*45)
      state.gridLastPoints[button]=nativePoints(button)
      button:SetAlpha(index<=capacity and state.gridAlphas[button] or 0)
    end
  end
  state.gridWriting=false
  if type(f.UpdateSize)=="function" then pcall(f.UpdateSize,f,30,40,n,5,c.iconScale,true,capacity) end
  if type(f.UpdateAuraContainerAnchor)=="function" then pcall(f.UpdateAuraContainerAnchor,f) end
  self.playerAuraLayoutUnavailable=nil
end
function M:ApplyPlayerAuras(owner,p)
  if owner.playerAuraApplying then return end
  if call(InCombatLockdown)==true then self.pending=true;return end
  owner.playerAuraApplying=true
  local ok,err=pcall(function()
    owner.playerAuraOwners=owner.playerAuraOwners or {}
    for _,kind in ipairs({"buffs","debuffs"}) do
      local k=kind;local f=M:PlayerAuraFrame(k);local state=owner.playerAuraOwners[k]
      if state and state.frame~=f then M:ReleasePlayerAura(state);owner.playerAuraOwners[k]=nil;state=nil end
      if f then
        if not state then
          state={frame=f};owner.playerAuraOwners[k]=state
          M:HookAuraPosition(state,function() M:ApplyPlayerAuras(owner,owner.parts) end)
          hooksecurefunc(f,"SetScale",function(_,value)
            if state.scaleWriting or state.releasing then return end
            if finite(value) and value>0 then state.originalScale=value
            else state.originalScale=nil;state.scaleOwned=nil;M.pending=true;M.propertyDeferred=true;return end
            if M:IsEnabled() then M:ApplyPlayerAuras(owner,owner.parts) end
          end)
          hooksecurefunc(f,"UpdateGridLayout",function() if M:IsEnabled() then M:ApplyPlayerAuras(owner,owner.parts) end end)
        end
        local cfg=M:GetDB().player.auras[k]
        if not M:IsEnabled() or call(EditModeManagerFrame and EditModeManagerFrame.IsShown,EditModeManagerFrame)==true or not cfg.enabled then
          M:ReleasePlayerAura(state)
        else
          M:ApplyPlayerAuraLayout(state,cfg)
          local bar=owner.compactActive and owner.healthDisplay or p.health
          local above=cfg.position=="above"
          if not above and M:GetDB().player.showPower~=false then bar=p.power end
          local nativeScale=call(f.GetScale,f);local iconScale=f.AuraContainer.iconScale
          local parent=call(f.GetParent,f)
          local ps=parent and call(parent.GetEffectiveScale,parent);local bs=call(bar.GetEffectiveScale,bar)
          if finite(nativeScale) and nativeScale>0 and finite(iconScale) and iconScale>0 and finite(ps) and ps>0 and finite(bs) and bs>0 then
            if not state.scaleOwned then state.originalScale=nativeScale end
            local scale=math.max(8,math.min(64,tonumber(cfg.size) or 20))*bs/(30*iconScale*ps)
            state.scaleOwned=true
            state.scaleWriting=true;local written=pcall(f.SetScale,f,scale);state.scaleWriting=false
            if written then state.scaleOwned=true else M.pending=true;M.propertyDeferred=true end
          else M.pending=true;M.propertyDeferred=true end
          local x=math.max(-300,math.min(300,tonumber(cfg.x) or 0));local y=math.max(-300,math.min(300,tonumber(cfg.y) or 0))
          -- SetPoint offsets belong to the scaled aura frame. Store coordinates
          -- in player-bar units so slider movement and preview drag agree.
          local as=call(f.GetEffectiveScale,f)
          if finite(as) and as>0 and finite(bs) and bs>0 then
            local _,_,left=M:AuraLayout(cfg)
            local side=cfg.layoutEnabled and left and "RIGHT" or "LEFT"
            M:WriteAuraPosition(state,{{(above and "BOTTOM" or "TOP")..side,bar,(above and "TOP" or "BOTTOM")..side,x*bs/as,(y+(above and 4 or -4))*bs/as}})
          else M.pending=true;M.propertyDeferred=true end
        end
      end
    end
  end)
  owner.playerAuraApplying=false
  if not ok then error(err,0) end
end
