local _,K=...
local A={roots={},cards={},recipes={},watch={},recipePositions={}}
K.modules.nativeAlerts=A
local call,read,finite=K.PublicCall,K.ReadPublicAPI,K.IsPublicNumber
local points,appearance=K.NativePosition,K.NativeAppearance
local UI,PU=K.UI,K.PositionUtils

local function bounded(value,low,high,default)
  return finite(value) and math.max(low,math.min(high,value)) or default
end
local function savedPoint(p)
  if type(p)=="table" and finite(p.x) and finite(p.y) then return p end
end

function A:GetDB()
  local db=K.db.nativeAlerts
  if type(db)~="table" then db={};K.db.nativeAlerts=db end
  K.MergeDefaults(db,{roll={enabled=false,locked=true,scale=100,fontSize=15},alerts={enabled=false,locked=true,recipeScale=100}},"types")
  db.roll.scale=bounded(db.roll.scale,70,150,100)
  db.roll.fontSize=bounded(db.roll.fontSize,11,22,15)
  db.alerts.recipeScale=bounded(db.alerts.recipeScale,60,150,100)
  return db
end

function A:CanEdit(frame)
  if not K.IsPublicValue(frame) or (type(frame)~="table" and type(frame)~="userdata") or not K.PositionStore:Safe(frame) then return false end
  if canaccessobject and call(canaccessobject,frame)~=true then return false end
  if frame.CanBeAccessedInContext and call(frame.CanBeAccessedInContext,frame)~=true then return false end
  for _,key in ipairs({"HasSecretValues","IsAnchoringRestricted","IsAnchoringSecret"}) do
    if frame[key] and call(frame[key],frame)~=false then return false end
  end
  return true
end

function A:Queue()
  if self.queued then return end
  self.queued=true
  C_Timer.After(0,function() self.queued=nil;self:Apply() end)
end

function A:Root(frame)
  if not self:CanEdit(frame) or not points.Read(frame) then return end
  local state=self.roots[frame]
  if not state then
    state={frame=frame}
    hooksecurefunc(frame,"SetPoint",function()
      if state.positionOwned and not self.applying and not state.positionWriting then self:Queue() end
    end)
    self.roots[frame]=state
  end
  return state
end

function A:WriteRoot(frame,point,relativePoint,x,y)
  local state=self:Root(frame)
  if state and not state.positionOwned then
    local cx,cy=K.PositionStore:Screen()
    local nx=call(frame.GetCenter,frame)
    local ny=call(point=="BOTTOM" and frame.GetBottom or frame.GetTop,frame)
    local scale,base=call(frame.GetEffectiveScale,frame),call(UIParent.GetEffectiveScale,UIParent)
    if cx and finite(nx) and finite(ny) and finite(scale) and finite(base) and base>0 then
      state.defaultAnchor={x=nx*scale/base-cx,y=ny*scale/base-cy}
    end
  end
  return state and points:WriteTracked(state,{{n=5,point,UIParent,relativePoint,x,y}})
end

function A:ReleaseRoot(frame)
  local state=frame and self.roots[frame]
  return not state or not state.positionOwned or (self:CanEdit(frame) and points:ReleaseTracked(state))
end

function A:AlertAncestor(alert,loot)
  local systems=call(function() return alert.alertFrameSubSystems end)
  if type(systems)~="table" or call(function() return alert.baseAnchorFrame end)~=alert then return end
  for _,system in ipairs(systems) do
    if type(system)=="table" and type(system.AdjustAnchors)=="function" then
      local anchor=call(function() return system.anchorFrame end)
      if anchor==loot and (not system.GetAlertContainer or call(system.GetAlertContainer,system)==alert) then return system end
    end
  end
end

function A:DetachLootAnchor(alert,loot,wanted)
  local owned=self.detached
  if owned then
    local current=call(function() return owned.system.anchorFrame end)
    if wanted and owned.alert==alert and owned.loot==loot and current==self.hiddenAnchor
      and self:AlertAncestor(alert,self.hiddenAnchor)==owned.system then return true end
    if current==self.hiddenAnchor and read(function() owned.system.anchorFrame=owned.loot end)~="ok" then return false end
    self.detached=nil
  end
  if not wanted then return true end
  local system=self:AlertAncestor(alert,loot)
  if not system then return false end
  if not self.hiddenAnchor then self.hiddenAnchor=CreateFrame("Frame",nil,UIParent);self.hiddenAnchor:Hide() end
  if read(function() system.anchorFrame=self.hiddenAnchor end)~="ok" then return false end
  self.detached={system=system,alert=alert,loot=loot}
  return true
end

-- Known queued systems from the Camelot source comparison. No child walk,
-- global replacement or quality filtering: the client owns banner creation.
function A:BannerFrames(alert)
  local frames={}
  for _,name in ipairs({"NewRecipeLearnedAlertSystem","LootAlertSystem","LootUpgradeAlertSystem"}) do
    local system=_G[name]
    local pool=call(function() return system and system.alertFramePool end)
    if type(pool)=="table" and type(pool.EnumerateActive)=="function"
      and (not system.GetAlertContainer or call(system.GetAlertContainer,system)==alert) then
      local active=call(function()
        local list={};for frame in pool:EnumerateActive() do list[frame]=true end;return list
      end)
      if type(active)=="table" then for frame in pairs(active) do frames[frame]=true end end
    end
  end
  return frames
end

function A:ScaleRecipes(scale)
  if scale then
    local active=self:BannerFrames(_G.AlertFrame)
    for frame in pairs(active) do
      if self:CanEdit(frame) then
        local owner=self.recipes[frame] or {}
        self.recipes[frame]=owner
        local saved=owner.decor and owner.decor[frame] and owner.decor[frame].scale
        local current=appearance.Read(frame,"scale")
        local original=saved and current==saved.last and saved.original or current
        if original then appearance:Write(owner,frame,"scale",original*scale) end
        if not self.watch[frame] then
          frame:HookScript("OnHide",function() self:Queue() end)
          self.watch[frame]=true
        end
      end
    end
    for frame,owner in pairs(self.recipes) do
      if not active[frame] and self:CanEdit(frame) then
        appearance:Release(owner)
        if not next(owner.decor or {}) then self.recipes[frame]=nil end
      end
    end
  else
    for frame,owner in pairs(self.recipes) do
      if self:CanEdit(frame) then appearance:Release(owner) end
      if not next(owner.decor or {}) then self.recipes[frame]=nil end
    end
  end
end


-- Queued recipe banners can follow a native/external anchor which is not the
-- moved AlertFrame. Keep correct native stacks intact; only repair that gap.
local function reaches(frame,target)
  local visited={}
  for _=1,32 do
    if frame==target then return true end
    if not frame or frame==UIParent or visited[frame] then return false end
    visited[frame]=true
    local anchors=K.IsPublicValue(frame) and call(points.Read,frame)
    if not anchors or #anchors~=1 then return false end
    frame=anchors[1][2]
  end
  return false
end

function A:ReleaseRecipePosition(frame)
  local state=self.recipePositions[frame]
  if not state then return end
  if not self:CanEdit(frame) then return end
  local current=points.Read(frame)
  if not current then return end
  if #current==0 then
    -- Native pool reset already cleared the banner. Never resurrect its old anchor.
    state.positionOwned=nil;state.originalPoints=nil;state.lastPoints=nil;state.requestedPoints=nil
  else points:ReleaseTracked(state) end
  if not state.positionOwned then self.recipePositions[frame]=nil end
end

function A:PositionRecipes(alert)
  if not K.db or self.positioningRecipes then return end
  local cfg=self:GetDB().alerts
  if not cfg.enabled and not next(self.recipePositions) then return end
  if call(InCombatLockdown)~=false then self.pending=true;return end
  local position=cfg.enabled and savedPoint(cfg.position)
  local editing=EditModeManagerFrame and call(EditModeManagerFrame.IsShown,EditModeManagerFrame)==true
  if editing or not position or not alert then
    for frame in pairs(self.recipePositions) do self:ReleaseRecipePosition(frame) end
    self.recipePositionFallback=nil;return
  end
  self.positioningRecipes=true
  local active=self:BannerFrames(alert)
  for frame in pairs(self.recipePositions) do if not active[frame] then self:ReleaseRecipePosition(frame) end end
  local head,heads
  heads=0
  self.recipePositionFallback=nil
  for frame in pairs(active) do
    local anchors=K.IsPublicValue(frame) and call(points.Read,frame)
    if anchors and #anchors==1 and not active[anchors[1][2]] then head=frame;heads=heads+1 end
  end
  local root=self.roots[alert]
  local native=self:CanEdit(alert) and points.Read(alert)
  local rootAligned=self:CanEdit(alert) and root and root.positionOwned and native and #native==1
    and native[1][1]=="TOP" and native[1][2]==UIParent and native[1][3]=="CENTER"
    and native[1][4]==position.x and native[1][5]==position.y
  if heads==1 and rootAligned and reaches(head,alert) then
    for frame in pairs(self.recipePositions) do self:ReleaseRecipePosition(frame) end
    self.recipePositionFallback=nil
  elseif heads==1 and self:CanEdit(head) then
    if not self.recipeAnchor then
      self.recipeAnchor=CreateFrame("Frame",nil,UIParent);self.recipeAnchor:SetSize(1,1);self.recipeAnchor:Hide()
    end
    -- UIParent coordinates preserve the saved editor origin at every recipe scale.
    -- The standard native gap is 10px; anchor the banner at zero local offset.
    self.recipeAnchor:ClearAllPoints();self.recipeAnchor:SetPoint("CENTER",UIParent,"CENTER",position.x,position.y+10)
    local state=self:Root(head)
    if state then
      self.recipePositions[head]=state
      if points:WriteTracked(state,{{n=5,"BOTTOM",self.recipeAnchor,"CENTER",0,0}}) then
        self.recipePositionFallback=true
      end
      if not self.watch[head] then head:HookScript("OnHide",function() self:Queue() end);self.watch[head]=true end
    end
    -- The game owns the ordering; later recipe banners still follow this head.
    for frame in pairs(self.recipePositions) do if frame~=head then self:ReleaseRecipePosition(frame) end end
  end
  self.positioningRecipes=nil
end

function A:WatchNative()
  local alert,loot=_G.AlertFrame,_G.GroupLootContainer
  if alert and not self.watch[alert] and type(alert.AddAlertFrame)=="function" and type(alert.UpdateAnchors)=="function" then
    self.watch[alert]=true
    hooksecurefunc(alert,"AddAlertFrame",function(_,frame)
      if not K.db or not self:GetDB().alerts.enabled then return end
      local system=call(function() return frame.queue end)
      local scale=self:GetDB().alerts.recipeScale
      if system and (system==_G.NewRecipeLearnedAlertSystem or system==_G.LootAlertSystem or system==_G.LootUpgradeAlertSystem) and scale~=100 and call(InCombatLockdown)==false then
        self:ScaleRecipes(scale/100)
        call(alert.UpdateAnchors,alert)
      end
      self:Queue()
    end)
    hooksecurefunc(alert,"UpdateAnchors",function() self:PositionRecipes(alert) end)
  end
  if loot and not self.watch[loot] then
    loot:HookScript("OnShow",function() self:Queue() end)
    loot:HookScript("OnHide",function() self:Queue() end)
    self.watch[loot]=true
  end
  self:WatchLootCards()
end

function A:CanUseRoll(cfg)
  return cfg.enabled and call(InputUtil and InputUtil.IsGamepadUIEnabled)==false
end

function A:Apply()
  if not K.db or self.applying then return end
  if call(InCombatLockdown)~=false then self.pending=true;return end
  self.applying=true
  local db=self:GetDB()
  self:WatchNative()
  local alert,loot=_G.AlertFrame,_G.GroupLootContainer
  local editing=EditModeManagerFrame and call(EditModeManagerFrame.IsShown,EditModeManagerFrame)==true
  local useRoll=not editing and self:CanUseRoll(db.roll)
  local useAlert=not editing and db.alerts.enabled
  local lootPoint=useRoll and savedPoint(db.roll.position)
  local alertPoint=useAlert and savedPoint(db.alerts.position)
  local needRefresh=useAlert or useRoll or self.detached or next(self.recipes) or next(self.recipePositions) or (alert and self.roots[alert] and self.roots[alert].positionOwned)
  local supported=(not lootPoint or self:CanEdit(loot)) and (not alertPoint or self:CanEdit(alert))
  local separated=supported and self:DetachLootAnchor(alert,loot,loot and (lootPoint or alertPoint))
  if not separated then self:DetachLootAnchor(alert,loot,false) end
  self:ApplyLoot(useRoll,db.roll,loot)
  local moved=true
  if separated and lootPoint then moved=self:WriteRoot(loot,"BOTTOM","CENTER",lootPoint.x,lootPoint.y)
  else self:ReleaseRoot(loot) end
  if separated and moved and alertPoint then moved=self:WriteRoot(alert,"TOP","CENTER",alertPoint.x,alertPoint.y)
  else self:ReleaseRoot(alert) end
  if not moved then
    self:ReleaseRoot(loot);self:ReleaseRoot(alert);self:DetachLootAnchor(alert,loot,false)
  end
  self.anchorUnavailable=(lootPoint or alertPoint) and (not separated or not moved) and true or nil
  self:ScaleRecipes(useAlert and db.alerts.recipeScale~=100 and db.alerts.recipeScale/100 or nil)
  self:PositionRecipes(alert)
  if alert and needRefresh then call(alert.UpdateAnchors,alert) end
  self.pending=nil;self.applying=nil
end

function A:Initialize()
  local events=CreateFrame("Frame")
  for _,name in ipairs({"PLAYER_LOGIN","PLAYER_ENTERING_WORLD","PLAYER_REGEN_ENABLED","ADDON_LOADED","START_LOOT_ROLL",
    "GET_ITEM_INFO_RECEIVED","ITEM_DATA_LOAD_RESULT","UI_SCALE_CHANGED","DISPLAY_SIZE_CHANGED"}) do pcall(events.RegisterEvent,events,name) end
  events:SetScript("OnEvent",function(_,event,itemID,ready)
    if event=="GET_ITEM_INFO_RECEIVED" or event=="ITEM_DATA_LOAD_RESULT" then
      if ready==true and finite(itemID) then self:UpdateLootTypes(itemID) end
    else self:Queue() end
  end)
  if EditModeManagerFrame then
    EditModeManagerFrame:HookScript("OnShow",function() self:Apply() end)
    EditModeManagerFrame:HookScript("OnHide",function() self:Queue() end)
  end
  self:Apply()
end

function A:Reset(key,positionOnly)
  local db=self:GetDB()
  db[key].position=nil
  if not positionOnly then
    db[key].enabled=false
    if key=="roll" then db.roll.scale,db.roll.fontSize=100,15 else db.alerts.recipeScale=100 end
  end
  self:Apply()
end

function A:PositionTargets()
  local list={}
  local cx,cy,w,h=K.PositionStore:Screen()
  if not cx then return list end
  local db=self:GetDB()
  for _,entry in ipairs({{"roll","주사위 굴림","전리품 주사위",_G.GroupLootContainer},
    {"alerts","알림","도안·아이템 획득 알림",_G.AlertFrame}}) do
    local key,section,title,native=unpack(entry)
    local cfg=db[key]
    if cfg.enabled then
      local nWidth,nHeight,offset
      if key=="roll" then
        nWidth,nHeight=self:LootSize(cfg)
        offset=self:LootSpacing(cfg)/2
      else nWidth,nHeight=312*cfg.recipeScale/100,89*cfg.recipeScale/100;offset=nHeight/2+10 end
      local state=native and self.roots[native]
      local x,y=cx,key=="roll" and h*.25 or 138
      if native then
        local nx=call(native.GetCenter,native)
        local ny=call(key=="roll" and native.GetBottom or native.GetTop,native)
        local scale,base=call(native.GetEffectiveScale,native),call(UIParent.GetEffectiveScale,UIParent)
        if finite(nx) and finite(ny) and finite(scale) and finite(base) and base>0 then x,y=nx*scale/base,ny*scale/base end
      end
      local fromDefault={x=x-cx,y=y-cy}
      local original=state and state.originalPoints and state.originalPoints[1]
      if state and state.positionOwned and original and key=="alerts" and (original[2]==UIParent or not original[2])
        and original[1]=="BOTTOM" and (original[3]=="BOTTOM" or not original[3]) then
        fromDefault={x=original[4] or 0,y=(original[5] or 128)+10-cy}
      elseif state and state.defaultAnchor then fromDefault=state.defaultAnchor end
      if state and not state.positionOwned and not PU.describing then state.defaultAnchor=fromDefault end
      local position=savedPoint(cfg.position) or {x=x-cx,y=y-cy}
      local id="basicUI."..key
      local t=PU:Sample(list,id,nil,title,cx+position.x,cy+position.y+offset,nWidth,nHeight,nil,function() self:Apply() end,
        {settingsRoute={module="basicUI",section=section,scope="계정 공용"},sample=title,exactBounds=true,resetPhysical=true,
          resetPoint={point="CENTER",relativePoint="BOTTOMLEFT",x=cx+fromDefault.x,y=cy+fromDefault.y+offset},
          resetWrite=function() cfg.position=nil end})
      t.lock=function() cfg.locked=true end
      t.write=function()
        local hx,hy=call(t.handle.GetCenter,t.handle)
        if finite(hx) and finite(hy) then cfg.position={x=K.PositionStore:Round(hx-cx),y=K.PositionStore:Round(hy-cy-offset)} end
      end
    end
  end
  return list
end

function A:BuildSettings(layout,parent)
  local function section(key,title,checkbox)
    local cfg=function() return self:GetDB()[key] end
    layout:Section(title)
    if key=="alerts" then layout.disclosures[#layout.disclosures].label:SetText("도안·아이템 획득 알림");for _,v in ipairs(layout.disclosures[#layout.disclosures].row.uiCaptions or {}) do if v.region==layout.disclosures[#layout.disclosures].label then v.text="도안·아이템 획득 알림" end end end
    layout.controlRoute={module="basicUI",section=title,scope="계정 공용"}
    local use=layout:Check(checkbox,function() return cfg().enabled end,function(v) cfg().enabled=v;self:Apply() end,
      nil,"계정 공용 설정",true)
    if key=="alerts" then use.text:SetText("도안·아이템 획득 알림 위치·크기 변경");for _,v in ipairs(use.uiCaptions or {}) do if v.region==use.text then v.text="도안·아이템 획득 알림 위치·크기 변경" end end end
    local controls=CreateFrame("Frame",nil,layout.page);controls:SetWidth(parent:GetWidth())
    controls.settingsRoute=layout.controlRoute
    local b=UI:CreateBuilder(controls,0)
    local function enabled() return cfg().enabled end
    local lock=b:PositionLock(key=="roll" and "주사위 굴림 위치 잠금" or "도안 습득 알림 위치 잠금",function() return cfg().locked end,function(v) cfg().locked=v end,enabled,key=="roll" and "주사위 굴림" or "도안·아이템 획득 알림")
    lock.ignoreModuleEnabled=true;lock.positionTargets={"basicUI."..key}
    local function slider(label,field,lo,hi,unit)
      local slider=b:Slider(label,lo,hi,1,function() return cfg()[field] end,
        function(v) cfg()[field]=v;self:Apply() end,function(v) return v..unit end,enabled)
      if field=="recipeScale" then slider.tooltipLabel:SetText("도안·아이템 획득 알림 크기") end
      slider.ignoreModuleEnabled=true
    end
    if key=="roll" then
      slider("창 크기","scale",70,150,"%");slider("글자 크기","fontSize",11,22," px")
    else slider("도안 습득 알림 크기","recipeScale",60,150,"%") end
    b:Flush()
    for _,item in ipairs({{key=="roll" and "주사위 위치 초기화" or "공통 알림 위치 초기화",function() self:Reset(key,true) end},
      {title.." 설정 초기화",function() self:Reset(key) end}}) do
      local control=b:Button(item[1],item[2],nil,item[3]);control.ignoreModuleEnabled=true
      if key=="alerts" then control:SetText(item[1]=="공통 알림 위치 초기화" and "도안·아이템 획득 알림 위치 초기화" or "도안·아이템 획득 알림 설정 초기화") end
    end
    b:Flush();layout:Fields(controls,-b.y)
    layout:Description(function() return self.pending and "전투 종료 후 변경을 적용합니다." or
      self.anchorUnavailable and (self.recipePositionFallback and "도안 알림에는 저장 위치를 적용했습니다. 다른 기본 알림 위치는 현재 변경할 수 없습니다." or "현재 기본 좌표를 읽을 수 없어 기본 위치를 사용합니다.") or "" end,
      function() return self.pending or self.anchorUnavailable end)
    layout:EndSection();layout.controlRoute=nil
  end
  section("roll","주사위 굴림","주사위 굴림 외형 변경")
  section("alerts","알림","기본 알림 위치·크기 변경")
end
