local _, KHQOL = ...
local CombatStatus = KHQOL.modules.combatStatus
local MEDIA = "Interface\\AddOns\\KHQOL\\Media\\CombatStatus\\"
local FADE_IN, MOVE, SWAP, PULSE, FADE_OUT = .10, .20, .10, .08, .30
local ANGLE = math.rad(45)
local COLOR_KEYS = {"enterColor","leaveColor"}
local POINTS = {CENTER=true,TOP=true,BOTTOM=true,LEFT=true,RIGHT=true,TOPLEFT=true,TOPRIGHT=true,BOTTOMLEFT=true,BOTTOMRIGHT=true}

CombatStatus.defaults = {
  showEnter=true, showLeave=true, showSwords=true, enterText="전투 시작", leaveText="전투 종료",
  enterColor={1,.15,.15}, leaveColor={.3,1,.4}, fontSize=60, swordWidth=56,
  displayDuration=1.2, fadeOut=true, showCombatDuration=false, locked=true,
  position={point="CENTER",relativePoint="CENTER",x=0,y=150},
}
local function clamp(value, low, high, default)
  if type(value)~="number" or value~=value or value==math.huge or value==-math.huge then value=default end
  return math.max(low,math.min(high,value))
end
function CombatStatus:GetDB()
  local db=KHQOL.db.modules.combatStatus
  if type(db)~="table" then db={}; KHQOL.db.modules.combatStatus=db end
  KHQOL.MergeDefaults(db,self.defaults,"types")
  db.fontSize=clamp(db.fontSize,40,80,60); db.swordWidth=clamp(db.swordWidth,20,160,56)
  db.displayDuration=clamp(db.displayDuration,.5,3,1.2)
  for _,key in ipairs(COLOR_KEYS) do
    for i=1,3 do db[key][i]=clamp(db[key][i],0,1,self.defaults[key][i]) end
  end
  local p=db.position
  if not POINTS[p.point] then p.point="CENTER" end
  if not POINTS[p.relativePoint] then p.relativePoint="CENTER" end
  p.x=clamp(p.x,-3000,3000,0); p.y=clamp(p.y,-3000,3000,150)
  self.db=db; return db
end
function CombatStatus:IsEnabled() return KHQOL:GetEnabled("combatStatus") end
function CombatStatus:ShouldShowMessage(kind)
  return kind=="enter" and self.db.showEnter or kind=="leave" and self.db.showLeave or false
end
function CombatStatus:ShouldShowSwords() return self.db.showSwords and self.resourcesOK end
function CombatStatus:DebugOnce(key, message)
  if not KHQOL.db.debug or self.warnings[key] then return end
  self.warnings[key]=true
  if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00KHQOL CombatStatus: "..message.."|r") end
end
function CombatStatus:LoadSword(texture, file)
  -- Texture APIs may report a bad file synchronously or load it asynchronously.
  -- Never use a texture-loading failure to abort module/other-module startup.
  local ok, result=pcall(texture.SetTexture,texture,MEDIA..file)
  if not ok or result==false or not texture:GetTexture() then
    self:DebugOnce(file,"검 리소스를 확인하세요: "..file)
    return false
  end
  texture:SetBlendMode("BLEND")
  -- Original 1024x1536 RGBA pixels occupy the top of a 1024x2048 TGA.
  -- Exclude transparent padding; displayed content remains exactly 2:3.
  texture:SetTexCoord(0,1,0,.75)
  return true
end
function CombatStatus:CreateFrames()
  if self.root then return end
  self.warnings={}; self.groups={}; self.sides={}
  local root=CreateFrame("Frame","KHQOLCombatStatusFrame",UIParent)
  root:SetSize(1,1); root:SetFrameStrata("HIGH")
  local visual=CreateFrame("Frame",nil,root); visual:SetAllPoints(root); visual:Hide()
  self.root,self.visual=root,visual
  local resourcesOK=true
  for i=1,2 do
    local side={sign=i==1 and -1 or 1}; self.sides[i]=side
    side.blue=visual:CreateTexture(nil,"ARTWORK",nil,i-1)
    side.red=visual:CreateTexture(nil,"ARTWORK",nil,i-1)
    side.textures={side.blue,side.red}
    local blueOK=self:LoadSword(side.blue,"Sword_Blue.tga")
    local redOK=self:LoadSword(side.red,"Sword_Red.tga")
    resourcesOK=resourcesOK and blueOK and redOK
    side.blue:Hide(); side.red:Hide()
  end
  self.resourcesOK=resourcesOK
  self.rotationSupported=true
  for _,side in ipairs(self.sides) do
    for _,texture in ipairs(side.textures) do
      if not texture.SetRotation or not pcall(texture.SetRotation,texture,0) then self.rotationSupported=false end
    end
  end
  if not self.rotationSupported then self:DebugOnce("rotation","회전 API를 사용할 수 없어 검의 이동과 색상 전환만 표시합니다.") end
  local text=visual:CreateFontString(nil,"OVERLAY","GameFontHighlight")
  text:SetJustifyH("CENTER"); text:SetWordWrap(false); self.text=text
  -- Separate drag anchor: fading/hiding the notification cannot hide the handle.
  local anchor=CreateFrame("Frame",nil,root,"BackdropTemplate")
  anchor:SetSize(220,44); anchor:SetPoint("CENTER",root,"CENTER",0,0)
  anchor:SetFrameStrata("DIALOG"); anchor:EnableMouse(true); anchor:RegisterForDrag("LeftButton")
  anchor:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12})
  anchor:SetBackdropColor(.05,.12,.2,.75)
  local label=anchor:CreateFontString(nil,"OVERLAY","GameFontHighlight")
  label:SetPoint("CENTER"); label:SetFont(KHQOL.UI:Font(),13,""); label:SetText("전투 상태 알림 · 드래그 이동")
  root:SetMovable(true); root:SetClampedToScreen(true)
  anchor:SetScript("OnDragStart",function()
    if self:IsEnabled() and not self.db.locked then self.dragging=true; root:StartMoving() end
  end)
  anchor:SetScript("OnDragStop",function() self:SavePosition() end)
  anchor:Hide(); self.anchor=anchor
  -- Create every group once, including hidden-color motion groups for reuse.
  local ok=pcall(function() self:CreateAnimations() end)
  self.nativeAnimations=ok
  if not ok then
    for _,group in ipairs(self.groups) do pcall(group.Stop,group) end
    self:DebugOnce("animation","기본 애니메이션 API를 사용할 수 없어 정적 알림을 표시합니다.")
  end
end
function CombatStatus:NewGroup(region)
  local group=region:CreateAnimationGroup()
  self.groups[#self.groups+1]=group
  group:SetLooping("NONE")
  return group
end
local function alpha(group, from, to, duration, order)
  local a=group:CreateAnimation("Alpha")
  a:SetOrder(order or 1); a:SetFromAlpha(from); a:SetToAlpha(to); a:SetDuration(duration)
  a:SetSmoothing("IN_OUT"); return a
end
function CombatStatus:CreateAnimations()
  self.fadeIn=self:NewGroup(self.visual)
  alpha(self.fadeIn,0,1,FADE_IN)
  self.fadeIn:SetScript("OnFinished",function()
    self.visual:SetAlpha(1)
    if not self:ShouldShowSwords() then self:StartHold()
    elseif self.kind=="enter" then self:StartMotion(true)
    else self:SwitchColor("blue"); self.phase="SWAP"; self.swap:Play() end
  end)
  self.swap=self:NewGroup(self.visual)
  local swap=self.swap:CreateAnimation("Animation"); swap:SetDuration(SWAP)
  self.swap:SetScript("OnFinished",function() self:StartMotion(false) end)
  for _,side in ipairs(self.sides) do
    side.motion={}
    for _,color in ipairs({"blue","red"}) do
      local group=self:NewGroup(side[color])
      local move=group:CreateAnimation("Translation")
      move:SetDuration(MOVE); move:SetSmoothing("IN_OUT"); move:SetOrder(1)
      local rotation
      if self.rotationSupported then
        rotation=group:CreateAnimation("Rotation")
        rotation:SetOrigin("CENTER",0,0); rotation:SetDuration(MOVE)
        rotation:SetSmoothing("IN_OUT"); rotation:SetOrder(1)
      end
      side.motion[color]={group=group,translation=move,rotation=rotation}
    end
  end
  -- This group sequences phases; native groups on each sword do the transforms.
  self.motionClock=self:NewGroup(self.visual)
  local clock=self.motionClock:CreateAnimation("Animation"); clock:SetDuration(MOVE)
  self.motionClock:SetScript("OnFinished",function()
    for _,side in ipairs(self.sides) do side.motion.blue.group:Stop(); side.motion.red.group:Stop() end
    self:SetPose(self.kind=="enter")
    if self.kind=="enter" then
      self:SwitchColor("red"); self.text:SetShown(self:ShouldShowMessage(self.kind)); self.phase="CLASH"; self.pulse:Play()
    else self:StartHold() end
  end)
  self.pulse=self:NewGroup(self.visual)
  alpha(self.pulse,1,.85,PULSE/2,1); alpha(self.pulse,.85,1,PULSE/2,2)
  self.pulse:SetScript("OnFinished",function() self.visual:SetAlpha(1); self:StartHold() end)
  self.hold=self:NewGroup(self.visual)
  self.holdAnimation=self.hold:CreateAnimation("Animation")
  self.hold:SetScript("OnFinished",function() self:StartFadeOut() end)
  self.fade=self:NewGroup(self.visual)
  alpha(self.fade,1,0,FADE_OUT)
  self.fade:SetScript("OnFinished",function() self:StopVisual() end)
end
function CombatStatus:SetPose(crossed)
  self.crossed=crossed
  local width=self.db.swordWidth; local scale=width/56
  for _,side in ipairs(self.sides) do
    local x=side.sign*(crossed and 10 or 45)*scale
    local angle=crossed and -side.sign*ANGLE or 0
    for _,texture in ipairs(side.textures) do
      texture:ClearAllPoints(); texture:SetPoint("CENTER",self.visual,"CENTER",x,0)
      texture:SetSize(width,width*1.5); texture:SetAlpha(1)
      if self.rotationSupported then texture:SetRotation(angle) end
    end
  end
end
function CombatStatus:SwitchColor(color)
  self.color=color
  for _,side in ipairs(self.sides) do
    side.blue:SetShown(self:ShouldShowSwords() and color=="blue")
    side.red:SetShown(self:ShouldShowSwords() and color=="red")
  end
end
function CombatStatus:StartMotion(entering)
  self.phase="MOTION"
  for _,side in ipairs(self.sides) do
    local motion=side.motion.blue
    motion.translation:SetOffset(side.sign*(entering and -35 or 35)*self.db.swordWidth/56,0)
    if motion.rotation then motion.rotation:SetDegrees(-side.sign*(entering and 45 or -45)) end
    motion.group:Play()
  end
  self.motionClock:Play()
end
function CombatStatus:StartHold()
  self.phase="HOLD"
  -- Display duration includes all time for which the message is visible.
  -- Default enter: .10+.20+1.20 = 1.50s; leave: 1.20s.
  local spent=not self:ShouldShowSwords() and FADE_IN or (self.kind=="enter" and PULSE or FADE_IN+SWAP+MOVE)
  local hold=math.max(0,self.db.displayDuration-spent-(self.db.fadeOut and FADE_OUT or 0))
  if hold>0 then self.holdAnimation:SetDuration(hold); self.hold:Play()
  else self:StartFadeOut() end
end
function CombatStatus:StartFadeOut()
  self.phase="FADE_OUT"
  if self.db.fadeOut then self.fade:Play() else self:StopVisual() end
end
function CombatStatus:StopVisual()
  self.generation=(self.generation or 0)+1
  self.phase="IDLE"; self.kind=nil
  if self.fallbackTimer then self.fallbackTimer:Cancel(); self.fallbackTimer=nil end
  if not self.visual then return end
  for _,group in ipairs(self.groups) do group:Stop() end
  self.visual:Hide(); self.visual:SetAlpha(1); self.text:Hide()
  self:SetPose(false)
  for _,side in ipairs(self.sides) do side.blue:Hide(); side.red:Hide() end
  if not self.anchor:IsShown() then self.root:Hide() end
end
function CombatStatus:RefreshMessage()
  if not self.kind then return end
  local db=self.db
  local message=self.kind=="enter" and db.enterText or db.leaveText
  if self.kind=="leave" and db.showCombatDuration and self.duration then
    local seconds=math.floor(math.max(0,self.duration))
    message=message..string.format(" · %02d:%02d",math.floor(seconds/60),seconds%60)
  end
  local color=self.kind=="enter" and db.enterColor or db.leaveColor
  self.text:SetText(message); self.text:SetTextColor(unpack(color))
end
function CombatStatus:Play(kind, duration, test)
  self:StopVisual()
  if not self:IsEnabled() or (not self:ShouldShowMessage(kind) and not self:ShouldShowSwords()) then return end
  self.kind,self.duration=kind,duration
  self:SetPose(kind=="leave"); self:SwitchColor(kind=="enter" and "blue" or "red")
  self:RefreshMessage(); self.text:SetShown(self:ShouldShowMessage(kind) and (kind=="leave" or not self:ShouldShowSwords()))
  self.root:Show(); self.visual:SetAlpha(1); self.visual:Show(); self.phase="FADE_IN"
  if self.nativeAnimations then self.fadeIn:Play()
  else
    -- No perpetual fallback update loop. A single cancellable timer hides text.
    self:SetPose(kind=="enter"); self:SwitchColor(kind=="enter" and "red" or "blue"); self.text:SetShown(self:ShouldShowMessage(kind))
    local generation=self.generation
    if C_Timer and C_Timer.NewTimer then
      self.fallbackTimer=C_Timer.NewTimer(self.db.displayDuration,function()
        if self.generation==generation then self:StopVisual() end
      end)
    else self:StopVisual(); self:DebugOnce("timer","알림 종료 타이머 API를 사용할 수 없습니다.") end
  end
end
function CombatStatus:Test(kind)
  -- Demo duration only; never mutate combatActive/combatStartTime.
  if self:IsEnabled() then self:Play(kind,kind=="leave" and 87 or nil,true) end
end
function CombatStatus:OnCombatEvent(event)
  if not self:IsEnabled() then return end
  if event=="PLAYER_REGEN_DISABLED" then
    if self.combatActive then return end
    self.combatStartTime=GetTime()
    self.combatActive=true; self:Play("enter")
  elseif event=="PLAYER_REGEN_ENABLED" then
    if not self.combatActive then return end
    local duration=self.combatStartTime and math.max(0,GetTime()-self.combatStartTime) or nil
    self.combatActive=false; self.combatStartTime=nil; self:Play("leave",duration)
  end
end
function CombatStatus:SavePosition()
  if not self.dragging then return end
  self.root:StopMovingOrSizing(); self.dragging=false
  local x,y=self.root:GetCenter(); local cx,cy=UIParent:GetCenter()
  if x and cx then
    local scale=self.root:GetEffectiveScale()/UIParent:GetEffectiveScale()
    self.db.position={point="CENTER",relativePoint="CENTER",x=x*scale-cx,y=y*scale-cy}
  end
  self:ApplyLayout()
end
function CombatStatus:ApplyLayout()
  if not self.root then return end
  local p=self.db.position
  if not self.dragging then self.root:ClearAllPoints(); self.root:SetPoint(p.point,UIParent,p.relativePoint,p.x,p.y) end
  self.text:SetFont(KHQOL.UI:Font(),self.db.fontSize,"OUTLINE")
  self.text:ClearAllPoints()
  if self:ShouldShowSwords() then self.text:SetPoint("TOP",self.visual,"CENTER",0,-self.db.swordWidth*1.5/2-18)
  else self.text:SetPoint("CENTER",self.visual,"CENTER",0,0) end
  self:SetPose(self.crossed or false); self:RefreshMessage()
  self.anchor:SetShown(self:IsEnabled() and not self.db.locked)
  self.root:SetShown(self.anchor:IsShown() or self.visual:IsShown())
end
function CombatStatus:Changed(key)
  if key=="locked" and self.db.locked then self:SavePosition() end
  -- Size changes during native transforms restart only the preview/visual,
  -- preserving combat recording and reusing the same groups and textures.
  local kind,duration=self.kind,self.duration
  self:ApplyLayout()
  if kind and (key=="swordWidth" or key=="displayDuration" or key=="fadeOut" or key=="showSwords"
    or key=="showEnter" and kind=="enter" or key=="showLeave" and kind=="leave") then self:Play(kind,duration,true) end
end
function CombatStatus:SetEnabled(enabled)
  self:GetDB(); self:CreateFrames()
  if not self.events then
    self.events=CreateFrame("Frame")
    self.events:SetScript("OnEvent",function(_,event) self:OnCombatEvent(event) end)
  end
  self:StopVisual()
  self.events:UnregisterAllEvents(); self.combatStartTime=nil
  -- One snapshot on enable avoids inventing a duration for reload mid-combat.
  self.combatActive=enabled and UnitAffectingCombat and UnitAffectingCombat("player") or false
  if enabled then self.events:RegisterEvent("PLAYER_REGEN_DISABLED"); self.events:RegisterEvent("PLAYER_REGEN_ENABLED")
  elseif self.dragging then self:SavePosition() end
  self:ApplyLayout()
end
function CombatStatus:BuildSettings(content,y)
  local db=self:GetDB(); local b=KHQOL.UI:CreateBuilder(content,y)
  local function check(title,key)
    return b:Checkbox(title,function() return db[key] end,function(v) db[key]=v; self:Changed(key) end)
  end
  local function message(title,key,flag)
    b:Edit(title,function() return db[key] end,function(v) db[key]=v; self:Changed(key) end,function() return db[flag] end)
  end
  local function color(title,key,flag)
    b:Color(title,function() return unpack(db[key]) end,function(r,g,bl) db[key]={r,g,bl}; self:Changed(key) end,function() return db[flag] end)
  end
  b:Section("위치")
  check("위치 잠금","locked")
  b:Description("잠금을 해제하면 이동 앵커를 드래그할 수 있습니다. 전투 알림은 잠금 상태와 관계없이 표시됩니다.")
  b:Button("위치 초기화",function()
    self:SavePosition(); db.position={point="CENTER",relativePoint="CENTER",x=0,y=150}; self:ApplyLayout()
  end)
  b:Section("전투 시작")
  check("문구 표시","showEnter"); message("문구 (Enter로 저장)","enterText","showEnter"); color("색상","enterColor","showEnter")
  b:Section("전투 종료")
  check("문구 표시","showLeave"); message("문구 (Enter로 저장)","leaveText","showLeave"); color("색상","leaveColor","showLeave")
  b:Section("공통 설정")
  b:Slider("글씨 크기",40,80,1,function() return db.fontSize end,function(v) db.fontSize=v; self:Changed("fontSize") end,function(v) return v.." px" end)
  b:Section("칼 애니메이션")
  check("칼 애니메이션 ON/OFF","showSwords")
  b:Slider("아이콘 크기",20,160,1,function() return db.swordWidth end,function(v) db.swordWidth=v; self:Changed("swordWidth") end,function(v) return v.." px" end,function() return db.showSwords end,"칼 아이콘의 폭입니다. 높이는 1.5배로 자동 계산합니다.")
  b:Description("문구 표시와 독립적으로 동작합니다. 칼을 끄면 문구만, 문구를 끄면 칼만 표시합니다.")
  b:Section("표시 시간 / 효과")
  b:Slider("표시 시간",.5,3,.1,function() return db.displayDuration end,function(v) db.displayDuration=v; self:Changed("displayDuration") end,function(v) return string.format("%.1f초",v) end,nil,"문구가 나타난 뒤 페이드 아웃을 포함한 시간입니다. 페이드 사용 시 종료 동작은 최소 0.7초가 필요합니다.")
  check("페이드 아웃","fadeOut"); check("전투 종료 시 전투 시간 표시","showCombatDuration")
  b:Section("테스트")
  b:Button("전투 시작 테스트",function() self:Test("enter") end)
  b:Button("전투 종료 테스트",function() self:Test("leave") end)
  b:Description("테스트는 실제 전투 상태와 시간 기록에 영향을 주지 않습니다. 전투 시간 표시를 켜면 종료 테스트에 01:27을 사용합니다.")
  return b.y
end
