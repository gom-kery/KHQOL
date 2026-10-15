local _, K = ...
local M={buttons={},headers={},nativeOwners={}}
K.modules.partyFrames=M
local R=K.ModuleRegistry
local call,number=K.PublicCall,K.IsPublicNumber
local function combat() return call(InCombatLockdown)==true end
local function bounded(v,d,lo,hi) return number(v) and math.max(lo,math.min(hi,v)) or d end
M.defaults={showSolo=true,showPower=true,showHealth=true,showRole=true,showMarker=true,fontSize=12,
  powerHeight=5,healthGradient=false,background={r=.06,g=.07,b=.09,a=1},
  namePosition={point="TOPLEFT",x=4,y=-2},healthPosition={point="BOTTOMRIGHT",x=-4,y=2},
  markerPosition={point="TOPRIGHT",x=-19,y=-2,size=14},rolePosition={point="BOTTOMLEFT",x=4,y=2,size=14},
  debuffs={enabled=false,count=5,size=18,perRow=5,gap=2,position="BOTTOM",x=0,y=0},
  party={width=144,height=46,gap=4,orientation="VERTICAL",point="TOPLEFT",x=34,y=-310},
  raid={width=112,height=40,gap=4,groupGap=14,groupsPerRow=8,orientation="VERTICAL",point="TOPLEFT",x=34,y=-310}}
function M:NormalizeDB(db)
  db=K.MergeDefaults(type(db)=="table" and db or {},self.defaults,"types")
  db.fontSize=bounded(db.fontSize,12,10,24)
  db.powerHeight=bounded(db.powerHeight,5,1,24)
  for _,key in ipairs({"r","g","b","a"}) do db.background[key]=bounded(db.background[key],self.defaults.background[key],0,1) end
  for _,key in ipairs({"namePosition","healthPosition","markerPosition","rolePosition"}) do
    local p,default=db[key],self.defaults[key]
    if not self:IsAnchorPoint(p.point) then p.point=default.point end
    p.x=bounded(p.x,default.x,-300,300);p.y=bounded(p.y,default.y,-300,300)
    if default.size then p.size=bounded(p.size,default.size,8,40) end
  end
  local a=db.debuffs
  a.count=math.floor(bounded(a.count,5,1,12));a.size=bounded(a.size,18,8,48)
  a.perRow=math.floor(bounded(a.perRow,5,1,12));a.gap=bounded(a.gap,2,0,20)
  a.x=bounded(a.x,0,-300,300);a.y=bounded(a.y,0,-300,300)
  if a.position~="TOP" and a.position~="LEFT" and a.position~="RIGHT" and a.position~="CENTER" then a.position="BOTTOM" end
  for _,kind in ipairs({"party","raid"}) do
    local d,default=db[kind],self.defaults[kind]
    local minimumHeight=2*db.fontSize+10+(db.showPower and db.powerHeight or 0)
    d.width=bounded(d.width,default.width,80,320);d.height=bounded(d.height,default.height,minimumHeight,100)
    d.gap=bounded(d.gap,4,0,24);d.x=bounded(d.x,34,-3000,3000);d.y=bounded(d.y,-310,-3000,3000)
    if d.orientation~="HORIZONTAL" then d.orientation="VERTICAL" end
    if not self:IsAnchorPoint(d.point) then d.point="TOPLEFT" end
    d.groupAnchor=d.groupAnchor=="RIGHT" and "RIGHT" or "LEFT"
  end
  db.raid.groupGap=bounded(db.raid.groupGap,14,0,50)
  db.raid.groupsPerRow=math.floor(bounded(db.raid.groupsPerRow,8,1,8))
  for _,key in ipairs({"raid10","raid20","raid40"}) do
    if type(db[key])~="table" then db[key]=K.CopyProfileValue(db.raid) end
    local d=K.MergeDefaults(db[key],db.raid,"types");db[key]=d
    local minimumHeight=2*db.fontSize+10+(db.showPower and db.powerHeight or 0)
    d.width=bounded(d.width,112,80,320);d.height=bounded(d.height,40,minimumHeight,100)
    d.gap=bounded(d.gap,4,0,24);d.groupGap=bounded(d.groupGap,14,0,50)
    d.groupsPerRow=math.floor(bounded(d.groupsPerRow,self:MaxLayoutGroups(key),1,self:MaxLayoutGroups(key)))
    d.x=bounded(d.x,34,-3000,3000);d.y=bounded(d.y,-310,-3000,3000)
    d.orientation=d.orientation=="HORIZONTAL" and "HORIZONTAL" or "VERTICAL"
    if not self:IsAnchorPoint(d.point) then d.point="TOPLEFT" end
    d.groupAnchor=d.groupAnchor=="RIGHT" and "RIGHT" or "LEFT"
    d.groupGapX=bounded(d.groupGapX,d.groupGap,0,100);d.groupGapY=bounded(d.groupGapY,d.groupGap,0,100)
  end
  return db
end
function M:GetDB()
  K.db.modules.partyFrames=self:NormalizeDB(K.db.modules.partyFrames)
  return K.db.modules.partyFrames
end
function M:GetCharacterDB()
  KHQOLPartyCharDB=K.MergeDefaults(type(KHQOLPartyCharDB)=="table" and KHQOLPartyCharDB or {},{wheelEnabled=false,up=0,down=0},"types")
  return KHQOLPartyCharDB
end
function M:Initialize()
  if self.events then return end
  self:GetDB();self:GetCharacterDB()
  self.events=CreateFrame("Frame")
  self.events:SetScript("OnEvent",function(_,event)
    if event=="SPELLS_CHANGED" or event=="PLAYER_REGEN_ENABLED" or event=="PLAYER_ENTERING_WORLD" or event=="ADDON_LOADED" then
      if self.desired or self.applied or next(self.nativeOwners) then self:RequestApply() end
    elseif event=="PLAYER_REGEN_DISABLED" then self:CloseLivePreview()
    elseif self.applied then
      if event=="GROUP_ROSTER_UPDATE" and (self.layoutKey~=self:RaidLayoutKey() or self.groupSignature~=self:RaidGroupSignature())
        or event=="PLAYER_ROLES_ASSIGNED" and self.appliedFrameProfile~=self:ActiveFrameProfile() then self:RequestApply() end
      self:RefreshAll()
      if not combat() then self:CheckNativeOwnership() end
    end
  end)
  if EventRegistry and type(EventRegistry.RegisterCallback)=="function" then
    EventRegistry:RegisterCallback("EditMode.Enter",function() M.editing=true;if M.desired or M.applied then M:RequestApply() end end,self)
    EventRegistry:RegisterCallback("EditMode.Exit",function() M.editing=false;if M.desired then M:RequestApply() end end,self)
  end
end
function M:ConfigureEvents()
  self.events:UnregisterAllEvents()
  if self.desired or self.applied or self.pending or next(self.nativeOwners) then
    for _,event in ipairs({"GROUP_ROSTER_UPDATE","PLAYER_ENTERING_WORLD","ADDON_LOADED","SPELLS_CHANGED","PLAYER_REGEN_ENABLED","PLAYER_REGEN_DISABLED","RAID_TARGET_UPDATE","PARTY_LEADER_CHANGED","PLAYER_ROLES_ASSIGNED"}) do self.events:RegisterEvent(event) end
    R:Own("partyFrames",self.events,function(f) f:UnregisterAllEvents() end)
  else R:Release("partyFrames",self.events) end
  for _,button in ipairs(self.buttons) do self:ConfigureUnitEvents(button) end
end
function M:SetEnabled(on)
  self.desired=on and true or false
  self:RequestApply()
end
function M:RequestApply()
  if not self.events then self:Initialize() end
  if self.applying then return end
  if combat() then
    self.pending=true
    R:Defer("partyFrames",function(m) m:ApplyLatest() end,not self.desired)
    self:ConfigureEvents()
    self:RefreshStatus()
    return
  end
  R:CancelDeferred("partyFrames")
  self:ApplyLatest()
end
function M:Capabilities()
  for _,name in ipairs({"SecureGroupHeader_Update","SecureUnitButton_OnLoad","SecureHandler_OnLoad","RegisterStateDriver","UnregisterStateDriver","ClearOverrideBindings","CompactUnitFrame_OpenMenu"}) do
    if type(_G[name])~="function" then return false,"필요한 게임 기능 없음: "..name end
  end
  if type(C_ClickBindings)~="table" or type(C_ClickBindings.GetBindingType)~="function" then return false,"게임 기본 클릭 시전 API 없음" end
  return true
end
function M:Prepare()
  if self.ready then return true end
  if C_AddOns and type(C_AddOns.LoadAddOn)=="function" then
    call(C_AddOns.LoadAddOn,"Blizzard_UnitFrame");call(C_AddOns.LoadAddOn,"Blizzard_CompactRaidFrames")
  end
  local supported,reason=self:Capabilities();if not supported then return false,reason end
  local ok,message=pcall(function()
    if not self.root then
      self.root=CreateFrame("Frame","KHQOLPartyFramesRoot",UIParent,"SecureFrameTemplate");self.root:Hide();self.root:EnableMouse(false)
      self.nativeGate=CreateFrame("Frame","KHQOLPartyNativeGate",UIParent,"SecureFrameTemplate");self.nativeGate:Hide();self.nativeGate:EnableMouse(false)
      -- Match UIParent's geometry, scale and level so implicit parent anchors
      -- and inherited native properties retain their coordinate space.
      self.nativeGate:SetAllPoints(UIParent);self.nativeGate:SetScale(1)
      local level=call(UIParent.GetFrameLevel,UIParent);if number(level) then self.nativeGate:SetFrameLevel(level) end
      local strata=call(UIParent.GetFrameStrata,UIParent);if type(strata)=="string" then self.nativeGate:SetFrameStrata(strata) end
      self.partyRoot=CreateFrame("Frame",nil,self.root,"SecureFrameTemplate");self.partyRoot:EnableMouse(false)
      self.raidRoot=CreateFrame("Frame",nil,self.root,"SecureFrameTemplate");self.raidRoot:EnableMouse(false)
    end
    if #self.headers==0 then
      for i=0,8 do
        local kind=i==0 and "party" or "raid"
        local header=CreateFrame("Frame","KHQOLPartyGroup"..i,i==0 and self.partyRoot or self.raidRoot,"SecureGroupHeaderTemplate")
        header.khqolKind=kind;header.khqolGroup=i
        self.headers[#self.headers+1]=header
        header:SetAttribute("_ignore",true)
        header:SetAttribute("template","KHQOLPartyUnitButtonTemplate");header:SetAttribute("templateType","Button")
        header:SetAttribute("sortMethod","INDEX");header:SetAttribute("sortDir","ASC")
        header:SetAttribute("point","TOP");header:SetAttribute("maxColumns",1);header:SetAttribute("unitsPerColumn",5)
        header:SetAttribute("showSolo",true);header:SetAttribute("showParty",false);header:SetAttribute("showRaid",false)
        header:SetAttribute("startingIndex",-4)
        header:SetAttribute("initialConfigFunction",[[self:SetWidth(self:GetParent():GetAttribute("kh-width"));self:SetHeight(self:GetParent():GetAttribute("kh-height"))]])
        header:SetAttribute("kh-width",self.visual[kind].width);header:SetAttribute("kh-height",self.visual[kind].height)
        header:SetAttribute("_ignore",nil)
        -- Trigger Blizzard's secure OnShow rather than invoking its roster
        -- function from addon Lua. This also creates valid restricted handles.
        local owner=header:GetParent()
        header:SetAlpha(0);header:SetParent(UIParent);header:Show();header:Hide();header:SetParent(owner);header:SetAlpha(1)
        assert(header:GetAttribute("child5"),"보안 그룹 버튼 준비 실패")
        header:SetAttribute("_ignore",true);header:SetAttribute("startingIndex",1);header:SetAttribute("showSolo",false)
        if i>0 then
          header:SetAttribute("showRaid",true);header:SetAttribute("groupFilter",tostring(i));header:SetAttribute("strictFiltering",false)
          header.title=header:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");header.title:SetPoint("BOTTOMLEFT",header,"TOPLEFT",0,3);header.title:SetText(i.." 파티")
        else header:SetAttribute("showParty",true);header:SetAttribute("showPlayer",true) end
        header:SetAttribute("_ignore",nil)
      end
    end
    assert(#self.buttons==45,"공통 유닛 버튼 준비 실패")
  end)
  if not ok then return false,"프레임 준비 실패: "..tostring(message) end
  self.ready=true;return true
end
function M:SuppressNative()
  local targets={PartyFrame,CompactRaidFrameContainer}
  if not targets[1] or not targets[2] then return false,"기본 파티·공격대 프레임을 찾을 수 없음" end
  for _,f in ipairs(targets) do
    if call(f.IsForbidden,f)~=false then return false,"기본 프레임 접근 제한" end
    local parent=call(f.GetParent,f)
    if self.nativeOwners[f] then
      if parent~=self.nativeGate then return false,"다른 애드온이 기본 프레임 부모를 변경함" end
    elseif parent~=UIParent then return false,"다른 UI가 기본 프레임 배치를 소유함" end
  end
  for _,f in ipairs(targets) do
    if not self.nativeOwners[f] then self.nativeOwners[f]={parent=UIParent} end
    if K.ReadPublicAPI(f.SetParent,f,self.nativeGate)~="ok" then return false,"기본 표시 억제 보류" end
  end
  return true
end
function M:RestoreNative()
  local done=true
  for f,record in pairs(self.nativeOwners) do
    local status,parent=K.ReadPublicAPI(f.GetParent,f)
    if status~="ok" then done=false
    elseif parent~=self.nativeGate then self.nativeOwners[f]=nil
    elseif K.ReadPublicAPI(f.SetParent,f,record.parent)=="ok" then self.nativeOwners[f]=nil
    else done=false end
  end
  return done
end
function M:CheckNativeOwnership()
  for f in pairs(self.nativeOwners) do
    if call(f.GetParent,f)~=self.nativeGate then self:RequestApply();return end
  end
end
function M:ClearWheel()
  for _,button in ipairs(self.buttons) do ClearOverrideBindings(button) end
end
function M:ApplyLatest()
  if combat() then self:RequestApply();return end
  if self.applying then return end
  self.applying=true;self.pending=nil;self.failure=nil
  local on=self.desired and not self.editing and call(EditModeManagerFrame and EditModeManagerFrame.IsShown,EditModeManagerFrame)~=true
  local ok,message=pcall(function()
    if #self.buttons>0 then self:ClearWheel() end
    if on then
      self.visual=K.CopyProfileValue(self:GetDB())
      self.layoutKey=self:RaidLayoutKey();self.appliedFrameProfile=self:ActiveFrameProfile()
      self.visual.raid=K.CopyProfileValue(self.visual[self.layoutKey])
      self.groupSignature=self:RaidGroupSignature();self.featureReasons={}
      self:PrepareHealthCurves()
      local ready,reason=self:Prepare();if not ready then error(reason,0) end
      self:ApplyLayout();self:ApplyWheel()
      local hidden,why=self:SuppressNative();if not hidden then error(why,0) end
      self.applied=true;self.root:Show();self:RefreshAll()
    else
      self.applied=false;self.wheelApplied={up=0,down=0,enabled=false}
      if self.root then self.root:Hide() end
      for _,h in ipairs(self.headers) do UnregisterStateDriver(h,"visibility");h:Hide();h:UnregisterAllEvents() end
      if not self:RestoreNative() then self.pending=true end
    end
  end)
  if not ok then
    self.failure=tostring(message);self.applied=false
    if self.root then self.root:Hide() end
    for _,h in ipairs(self.headers) do UnregisterStateDriver(h,"visibility");h:Hide();h:UnregisterAllEvents() end
    if #self.buttons>0 then self:ClearWheel() end
    self.wheelApplied={up=0,down=0,enabled=false}
    if not self:RestoreNative() then self.pending=true end
  end
  self.applying=nil
  if self.pending then R:Defer("partyFrames",function(m) m:ApplyLatest() end,true) end
  self:ConfigureEvents()
  self:RefreshLivePreview()
  self:RefreshStatus()
end
function M:RefreshStatus()
  local feature
  for _,value in pairs(self.featureReasons or {}) do feature=value;break end
  local notice=self.inputReason or self.failure or (self.pending and "전투 종료 후 변경을 적용합니다.") or self.wheelReason or feature or ""
  for _,key in ipairs({"statusLabel","commonStatusLabel","profileNotice"}) do if self[key] then self[key]:SetText(notice) end end
  for _,key in ipairs({"settingsContent","commonContent","profileContent"}) do
    local content=self[key]
    if content and content.uiBuilder and call(content.IsVisible,content)==true then content.uiBuilder:Reflow() end
  end
end
function M:Status()
  if self.failure then return "적용 실패 · "..(next(self.nativeOwners) and "기본 표시 복원 보류: " or "기본 표시 복원: ")..self.failure end
  if self.pending and not self.applied and next(self.nativeOwners) then return "기본 표시 복원 보류 · 다음 안전한 이벤트에서 자기 변경 복원을 재시도합니다." end
  if self.pending then
    local w=self.wheelApplied or {};local char=self:GetCharacterDB()
    return "변경 보류 · 모듈 현재 "..(self.applied and "ON" or "OFF").." / 저장 "..(self.desired and "ON" or "OFF")
      .." · 휠 현재 "..(w.enabled and "ON" or "OFF").." / 저장 "..(char.wheelEnabled and "ON" or "OFF").." (전투 종료 후 최신 주문 적용)"
  end
  if self.editing and self.desired then return "게임 편집 모드 · 자체 표시 잠시 해제 / 기본 표시 복원" end
  if not self.applied then return "현재 OFF · 기본 파티·공격대 표시 유지 · 휠 저장 "..(self:GetCharacterDB().wheelEnabled and "ON" or "OFF") end
  local w=self.wheelApplied or {}
  return "현재 ON · 휠 현재 "..(w.enabled and "ON" or "OFF").." / 저장 "..(self:GetCharacterDB().wheelEnabled and "ON" or "OFF")..(self.wheelReason and " · "..self.wheelReason or "")
end
function M:CancelPreview()
  self:CloseLivePreview()
  for _,f in pairs(self.previews or {}) do f:Hide() end
  if not combat() and #self.buttons>0 then self:ClearWheel() end
end
function M:PositionTargets()
  if not self.applied or combat() then return {} end
  local targets={};self.previews=self.previews or {}
  for _,kind in ipairs({"party","raid"}) do
    local layoutKey=kind=="raid" and self:RaidLayoutKey() or "party"
    local d=self:GetDB()[layoutKey];local f=self.previews[kind]
    if not f then f=CreateFrame("Frame",nil,UIParent);f:EnableMouse(false);f:Hide();self.previews[kind]=f end
    local groups=self:MaxLayoutGroups(layoutKey)
    local width,height=self:Extent(layoutKey,d,groups)
    self:PlaceLayoutRoot(f,layoutKey,d,groups)
    -- Editor art uses only public maximum-size samples for the selected tier.
    local art={}
    for group=1,groups do for member=1,5 do
      local gx,gy=0,0
      if kind=="raid" then gx,gy=self:GroupOffset(layoutKey,d,group-1,groups) end
      if d.groupAnchor=="RIGHT" then gx=width+gx-d.width end
      local mx=d.orientation=="HORIZONTAL" and (member-1)*(d.width+d.gap) or 0
      local my=d.orientation=="VERTICAL" and (member-1)*(d.height+d.gap) or 0
      if d.groupAnchor=="RIGHT" then mx=-mx end
      art[#art+1]={texture="Interface\\Buttons\\WHITE8X8",width=d.width-2,height=d.height-2,x=gx+mx+d.width/2-width/2,y=height/2+gy-my-d.height/2}
    end end
    local which=layoutKey
    local defaultPosition=self.defaults[kind]
    targets[#targets+1]={id="partyFrames."..kind,name=kind=="party" and "파티·솔로 프레임" or (groups*5).."인 공격대",frame=f,settingsRoute={module="partyFrames",tab="frames"},
      sample=kind=="party" and "플레이어 포함 최대 5인 미리보기" or "최대 "..(groups*5).."인 영역 미리보기",sampleY=-height/2-14,art=art,
      write=function(dx,dy) local p=M:GetDB()[which];p.x=K.PositionStore:Round(p.x+dx);p.y=K.PositionStore:Round(p.y+dy) end,
      apply=function() M:RequestApply() end,
      resetPoint={point="TOPLEFT",relativePoint="TOPLEFT",x=defaultPosition.x,y=defaultPosition.y},resetPhysical=true,
      resetWrite=function() local p=M:GetDB()[which];p.point="TOPLEFT";p.x=defaultPosition.x;p.y=defaultPosition.y end}
  end
  R:Own("partyFrames",self.previews,function() M:CancelPreview() end)
  return targets
end
