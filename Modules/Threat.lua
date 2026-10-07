local _, KHQOL = ...
local Threat = KHQOL.modules.threat
local INTERVAL = .20
local AGGRO_SOUND_THRESHOLD = 95
local AGGRO_SOUND = "Interface\\AddOns\\KHQOL\\Media\\aggro.wav"
local COLORS = {{.3,1,.4}, {1,.85,.1}, {1,.5,.1}, {1,.15,.15}}
local ICONS = {
  caution="Interface\\AddOns\\KHQOL\\Media\\threat-caution-yellow",
  danger="Interface\\AddOns\\KHQOL\\Media\\threat-danger-orange",
  aggro="Interface\\AddOns\\KHQOL\\Media\\threat-aggro-red",
}
local MODES = {value=true, percent=true, both=true}
local ROLE_KEYS = {TANK="instanceTankEnabled", DAMAGER="instanceDamageEnabled", HEALER="instanceHealerEnabled"}
local POINTS = {CENTER=true,TOP=true,BOTTOM=true,LEFT=true,RIGHT=true,TOPLEFT=true,TOPRIGHT=true,BOTTOMLEFT=true,BOTTOMRIGHT=true}

Threat.defaults = {
  displayMode="percent", percentDisplayVersion=1, fontSize=15,
  colorByStatus=true, soloPetEnabled=true, locked=true,
  showTargetName=true, showThreatHint=true,
  iconEnabled=true, iconSize=18, iconPosition="LEFT", showCautionIcon=false,
  aggroSoundEnabled=true,
  instanceTankEnabled=false, instanceDamageEnabled=true, instanceHealerEnabled=true,
  instanceRole="AUTO",
  position={point="CENTER",relativePoint="CENTER",x=0,y=-120},
}
local function readable(value)
  if type(issecretvalue)=="function" then
    local ok, secret=pcall(issecretvalue,value)
    if not ok or secret then return false end
  end
  if type(canaccessvalue)=="function" then
    local ok, accessible=pcall(canaccessvalue,value)
    if not ok or not accessible then return false end
  end
  return true
end
local function number(value)
  if not readable(value) or type(value)~="number" then return nil end
  if value~=value or value==math.huge or value==-math.huge or value<0 then return nil end
  return value
end
local function status(value)
  value=number(value)
  if value and value<=3 and value==math.floor(value) then return value end
end
local function call(fn,...)
  if type(fn)~="function" then return nil end
  local ok,value=pcall(fn,...)
  if ok and readable(value) then return value end
end
local function yes(fn,...) return call(fn,...)==true end
-- Some predicate APIs use nil for a negative result. Distinguish that from
-- an absent API, call failure, or restricted result instead of requiring false.
local function predicate(fn,...)
  if type(fn)~="function" then return nil,false end
  local ok,value=pcall(fn,...)
  if not ok or not readable(value) then return nil,false end
  if value==nil or value==false then return false,true end
  if value==true then return true,true end
  return nil,false
end
local function clamp(v,low,high,default)
  v=number(v) or default
  return math.max(low,math.min(high,v))
end
-- Screen coordinates may be negative; threat readings may not.
local function offset(v,low,high,default)
  if not readable(v) or type(v)~="number" or v~=v or v==math.huge or v==-math.huge then v=default end
  return math.max(low,math.min(high,v))
end
function Threat:GetDB()
  local db=KHQOL.db.modules.threat
  if type(db)~="table" then db={}; KHQOL.db.modules.threat=db end
  -- Seed a missing independent size once from the previously displayed font
  -- size. Fresh profiles use 18; an explicit saved icon size is never replaced.
  local oldIconSize,oldFontSize=db.iconSize,number(db.fontSize)
  -- Migrate the existing cumulative-number HUD once. Capture the marker before
  -- default merging so missing fields do not disguise an older installation.
  local migrate=db.percentDisplayVersion~=1
  KHQOL.MergeDefaults(db,self.defaults,"types")
  if migrate then db.displayMode="percent"; db.percentDisplayVersion=1 end
  if not MODES[db.displayMode] then db.displayMode="percent" end
  db.fontSize=clamp(db.fontSize,10,24,15)
  if oldIconSize==nil and oldFontSize then db.iconSize=oldFontSize end
  db.iconSize=math.floor(clamp(db.iconSize,12,32,18)+.5)
  if db.iconPosition~="LEFT" and db.iconPosition~="TOP" then db.iconPosition="LEFT" end
  if db.instanceRole~="AUTO" and not ROLE_KEYS[db.instanceRole] then db.instanceRole="AUTO" end
  local p=db.position
  if not POINTS[p.point] then p.point="CENTER" end
  if not POINTS[p.relativePoint] then p.relativePoint="CENTER" end
  p.x=offset(p.x,-5000,5000,0); p.y=offset(p.y,-5000,5000,-120)
  self.db=db; return db
end
function Threat:IsEnabled() return KHQOL.db and KHQOL:GetEnabled("threat") end
function Threat:Capabilities()
  self.detailAPI=type(UnitDetailedThreatSituation)=="function"
  self.timerAPI=C_Timer and type(C_Timer.NewTicker)=="function" or false
end
function Threat:Eligible()
  self.inRaid=yes(IsInRaid)
  self.inGroup=yes(IsInGroup) or self.inRaid
  if not self.inGroup then self.inGroup=(number(call(GetNumGroupMembers)) or 0)>1 end
  local class
  if type(UnitClass)=="function" then
    local ok,_,token=pcall(UnitClass,"player")
    if ok and readable(token) and type(token)=="string" then class=token end
  end
  self.class=class or "UNKNOWN"
  self.pet=yes(UnitExists,"pet")
  local validPet=self.pet and not yes(UnitIsDeadOrGhost,"pet")
  return self.inGroup or (self.db.soloPetEnabled and validPet and (class=="HUNTER" or class=="WARLOCK")) or false
end
function Threat:ResolveRole()
  if ROLE_KEYS[self.db.instanceRole] then return self.db.instanceRole,"MANUAL" end
  local role=call(UnitGroupRolesAssigned,"player")
  if type(role)=="string" and ROLE_KEYS[role] then return role,"GROUP" end
  -- An unassigned party role may still be resolved from the active spec.
  -- Guard both older globals and the modern namespace used by some clients.
  local api=type(C_SpecializationInfo)=="table" and C_SpecializationInfo or nil
  local spec=number(call(GetSpecialization or (api and api.GetSpecialization)))
  if spec and spec>=1 and spec==math.floor(spec) then
    role=call(GetSpecializationRole,spec)
    if type(role)=="string" and ROLE_KEYS[role] then return role,"SPEC" end
    local getInfo=GetSpecializationInfo or (api and api.GetSpecializationInfo)
    if type(getInfo)=="function" then
      local ok,_,_,_,_,specRole=pcall(getInfo,spec)
      if ok and readable(specRole) and type(specRole)=="string" and ROLE_KEYS[specRole] then return specRole,"SPEC" end
    end
  end
  return "NONE","UNKNOWN"
end
function Threat:RefreshRoleFilter()
  local previousRole,previousType=self.playerRole,self.instanceType
  self.instanceType="none"
  if type(IsInInstance)=="function" then
    local ok,inside,kind=pcall(IsInInstance)
    if ok and readable(inside) and inside==true and readable(kind) and type(kind)=="string" then self.instanceType=kind end
  end
  self.inRoleInstance=self.instanceType=="party" or self.instanceType=="raid"
  self.playerRole,self.roleSource=self:ResolveRole()
  self.roleAllowed=true
  if self.inRoleInstance then
    local key=ROLE_KEYS[self.playerRole]
    if key then self.roleAllowed=self.db[key]==true
    else
      -- With every role selected there is no filter. Otherwise an unknown
      -- role must not accidentally enable a tank's alerts as a guessed DPS.
      self.roleAllowed=self.db.instanceTankEnabled and self.db.instanceDamageEnabled and self.db.instanceHealerEnabled
    end
  end
  if previousRole~=self.playerRole or previousType~=self.instanceType then self:ResetAggroAlert() end
  self.active=self:IsEnabled() and self.inWorld and self.eligible and self.detailAPI and self.roleAllowed or false
end
function Threat:IsHostileNPC(unit)
  if not yes(UnitExists,unit) then return false,"NO_TARGET" end
  if not yes(UnitCanAttack,"player",unit) then return false,"NOT_ATTACKABLE" end
  local player,known=predicate(UnitIsPlayer,unit)
  if not known then return false,"IDENTITY_UNAVAILABLE" end
  if player then return false,"PLAYER_TARGET" end
  local same,knownSelf=predicate(UnitIsUnit,"player",unit)
  if not knownSelf then return false,"IDENTITY_UNAVAILABLE" end
  if same then return false,"SELF_TARGET" end
  local reaction=number(call(UnitReaction,unit,"player"))
  -- Neutral NPCs (reaction 4) are legitimate combat targets. Verified
  -- attackability is sufficient when reaction itself is unavailable.
  if reaction and reaction>4 then return false,"FRIENDLY_TARGET" end
  if yes(UnitIsDeadOrGhost,unit) then return false,"DEAD_TARGET" end
  return true
end

-- Five documented returns are decoded only if the signature is plausible.
-- No arbitrary /100 conversion: value is the API's raw Threat unit. Runtime
-- availability and scale on Forever remain subject to in-game verification.
-- Optional 'out' reuses the single HUD result table on every tick.
function Threat:GetThreatInfo(unit,out)
  out=out or {}
  out.status=nil; out.percent=nil; out.rawPercent=nil; out.value=nil
  out.isTanking=nil; out.percentBasis=nil; out.available=false
  if type(UnitDetailedThreatSituation)=="function" then
    local ok,tanking,s,scaled,raw,value=pcall(UnitDetailedThreatSituation,"player",unit)
    if ok and (not readable(tanking) or type(tanking)=="boolean" or tanking==nil) then
      -- A restricted flag must not discard independently readable numbers.
      if readable(tanking) then out.isTanking=tanking end
      out.status=status(s)
      out.percent=number(scaled); out.rawPercent=number(raw); out.value=number(value)
      -- Raw percent compares against the current tank. Mixing it with scaled
      -- percent would make the meaning of 100% change while playing.
      if out.percent~=nil then out.percentBasis="scaled" end
    end
  end
  if out.status==nil then out.status=status(call(UnitThreatSituation,"player",unit)) end
  -- A status alone cannot be converted into a made-up number or percentage.
  out.available=out.value~=nil or out.percent~=nil
  return out
end
function Threat:Format(info)
  local value=info.value and string.format("%.0f",info.value) or nil
  -- Never round a reading below the pull threshold up to 100%.
  local percent=info.percent and string.format("%d%%",math.floor(math.min(100,info.percent))) or nil
  if self.db.displayMode=="percent" then return percent end
  if self.db.displayMode=="both" and value and percent then return value.." · "..percent end
  return value or percent
end
function Threat:Risk(info)
  if info.isTanking==true or info.status==2 or info.status==3 then return 3,"어그로 보유 중" end
  if info.percent~=nil and info.percentBasis=="scaled" then
    local p=info.percent
    if p>=100 then return 3,"어그로 전환 기준 도달" end
    if p>=90 then return 2,"위험 · 어그로 전환 100%" end
    if p>=70 then return 1,"주의 · 어그로 전환 100%" end
    return 0,"여유 · 어그로 전환 100%"
  end
  -- If only cumulative threat is available, retain API status colors but do
  -- not invent a threshold or turn raw percent into scaled percent.
  return info.status,"전환 비율 확인 불가"
end
function Threat:Color(info)
  if not self.db.colorByStatus then return 1,1,1 end
  local s=self:Risk(info)
  local c=s~=nil and COLORS[s+1] or nil
  if c then return c[1],c[2],c[3] end
  return 1,1,1
end
function Threat:IconPath(info)
  if not self.db.iconEnabled then return end
  if info.isTanking==true or info.status==2 or info.status==3 then return ICONS.aggro end
  local risk=self:Risk(info)
  if risk and risk>=2 then return ICONS.danger end
  if risk==1 and self.db.showCautionIcon then return ICONS.caution end
end
function Threat:ResetAggroAlert()
  self.alertState=nil; self.alertGUID=nil
end
function Threat:UpdateAggroAlert(info)
  if not self.db.aggroSoundEnabled then self:ResetAggroAlert(); return end
  -- Track only live, continuous samples of the same selected enemy. Target
  -- events reset this state even if the client's GUID is unavailable/secret.
  local guid=call(UnitGUID,"target")
  if type(guid)~="string" then guid=nil end
  if guid and self.alertGUID and guid~=self.alertGUID then self:ResetAggroAlert() end
  self.alertGUID=guid
  local holding=info.isTanking==true or info.status==2 or info.status==3
  -- Only the HUD's scaled percentage has the pull-threshold meaning. Raw
  -- threat or raw percent cannot substitute when that reading is unavailable.
  local percent=info.percentBasis=="scaled" and number(info.percent) or nil
  if percent==nil then self:ResetAggroAlert(); return end
  local above=percent>=AGGRO_SOUND_THRESHOLD
  local previous=self.alertState
  -- Latch the whole >=95% range, including ownership, before playback. An
  -- initial owned sample stays silent; a jump from below 95% still counts.
  self.alertState=(above or holding) and "ABOVE" or "BELOW"
  if above and previous~="ABOVE" and (previous=="BELOW" or not holding) and type(PlaySoundFile)=="function" then
    -- Dialog uses WoW's dialogue volume; never change the user's sound CVars.
    pcall(PlaySoundFile,AGGRO_SOUND,"Dialog")
  end
end
-- A single, non-secure HUD owned by UIParent. No nameplate frame is consulted
-- or altered, so another addon can replace/hide its own bars independently.
function Threat:CreateFrames()
  if self.root then return end
  local root=CreateFrame("Frame","KHQOLThreatHUD",UIParent)
  root:SetSize(280,88); root:SetFrameStrata("HIGH")
  root:SetClampedToScreen(true); root:SetMovable(true)
  root:EnableMouse(false); root:Hide()
  self.root=root
  self.info={}
  self.testInfo={status=0,testLevel=1,value=156,percent=78,rawPercent=86,percentBasis="scaled",available=true}

  local name=root:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  name:SetPoint("TOP",root,"TOP",0,-8); name:SetWidth(260)
  name:SetJustifyH("CENTER"); name:SetWordWrap(false)
  local text=root:CreateFontString(nil,"OVERLAY","GameFontHighlight")
  text:SetPoint("CENTER",root,"CENTER",0,0); text:SetJustifyH("CENTER")
  local hint=root:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  hint:SetPoint("BOTTOM",root,"BOTTOM",0,8); hint:SetJustifyH("CENTER")
  self.nameText,self.text,self.hint=name,text,hint
  local icon=root:CreateTexture(nil,"OVERLAY")
  -- The supplied 30x30 pixels are padded into a 32x32 RGBA game texture.
  -- Sample only the original image; no art is resized or recolored on disk.
  icon:SetTexCoord(1/32,31/32,1/32,31/32); icon:Hide()
  self.icon=icon
  local preview=root:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  preview:SetPoint("BOTTOM",root,"BOTTOM",0,-8); preview:SetJustifyH("CENTER"); preview:Hide()
  self.previewText=preview

  local anchor=CreateFrame("Frame",nil,root,"BackdropTemplate")
  anchor:SetAllPoints(root); anchor:SetFrameStrata("HIGH")
  anchor:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12})
  anchor:SetBackdropColor(.03,.03,.03,.8)
  anchor:SetFrameLevel(root:GetFrameLevel())
  anchor:EnableMouse(true); anchor:RegisterForDrag("LeftButton")
  anchor:SetScript("OnDragStart",function()
    if self:IsEnabled() and not self.db.locked then self.dragging=true; root:StartMoving() end
  end)
  anchor:SetScript("OnDragStop",function() self:SavePosition(); self:RefreshControls() end)
  anchor:Hide(); self.anchor=anchor
end
function Threat:ApplyLayout()
  if not self.root then return end
  if not self.dragging then
    local p=self.db.position
    self.root:ClearAllPoints(); self.root:SetPoint(p.point,UIParent,p.relativePoint,p.x,p.y)
  end
  local font=STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
  if KHQOL.UI and KHQOL.UI.Font then font=KHQOL.UI:Font() or font end
  self.text:SetFont(font,self.db.fontSize,"OUTLINE")
  self.nameText:SetFont(font,12,"OUTLINE"); self.hint:SetFont(font,11,"OUTLINE")
  self.previewText:SetFont(font,11,"OUTLINE")
  self.icon:SetSize(self.db.iconSize,self.db.iconSize)
  self.icon:ClearAllPoints()
  self.nameText:ClearAllPoints()
  local gap=math.max(2,math.floor(self.db.iconSize*.2+.5))
  if self.db.iconEnabled and self.db.iconPosition=="TOP" then
    self.icon:SetPoint("BOTTOM",self.text,"TOP",0,gap)
    -- Reserve the upper lane even while the alert is hidden. The number and
    -- name must not jump or collide when the risk changes during polling.
    self.nameText:SetPoint("BOTTOM",self.icon,"TOP",0,6)
    local top=self.db.fontSize/2+gap+self.db.iconSize+(self.db.showTargetName and 20 or 0)+8
    self.root:SetHeight(math.max(88,top*2))
  else
    self.icon:SetPoint("RIGHT",self.text,"LEFT",-gap,0)
    self.root:SetHeight(88)
    self.nameText:SetPoint("TOP",self.root,"TOP",0,-8)
  end
  -- Keep the existing lower message/preview positions when the upper lane
  -- expands. The selected text's center and saved HUD coordinates are fixed.
  self.hint:ClearAllPoints(); self.hint:SetPoint("BOTTOM",self.root,"CENTER",0,-36)
  self.previewText:ClearAllPoints(); self.previewText:SetPoint("BOTTOM",self.root,"CENTER",0,-52)
  self.anchor:SetShown(self:IsEnabled() and not self.db.locked)
end
function Threat:RefreshControls()
  if KHQOL.settings and KHQOL.settings.activeContent then KHQOL.UI:Refresh(KHQOL.settings.activeContent) end
end
function Threat:SavePosition()
  if not self.dragging then return end
  self.root:StopMovingOrSizing(); self.dragging=false
  local x,y=self.root:GetCenter(); local cx,cy=UIParent:GetCenter()
  if x and y and cx and cy then
    local scale=self.root:GetEffectiveScale()/UIParent:GetEffectiveScale()
    self.db.position={point="CENTER",relativePoint="CENTER",x=x*scale-cx,y=y*scale-cy}
  end
  self:ApplyLayout()
end
function Threat:ResetPosition()
  if self.dragging then self.root:StopMovingOrSizing(); self.dragging=false end
  self.db.position={point="CENTER",relativePoint="CENTER",x=0,y=-120}
  self:Changed()
end
function Threat:HideHUD()
  self:ResetAggroAlert()
  if not self.root then return end
  self.text:SetText(""); self.nameText:SetText(""); self.hint:SetText("")
  self.icon:Hide(); self.previewText:Hide()
  self.root:Hide()
end
function Threat:ShowInfo(info,name,hint,previewLabel)
  local text=info.available and self:Format(info) or nil
  if not text then return false end
  self.text:SetText(text); self.text:SetTextColor(self:Color(info))
  self.nameText:SetText(name); self.hint:SetText(hint or "")
  self.nameText:SetShown(self.db.showTargetName)
  self.hint:SetShown(self.db.showThreatHint)
  -- Keep synthetic data identifiable even when the target-name option is off.
  self.previewText:SetText(previewLabel or "")
  self.previewText:SetShown(previewLabel~=nil and not self.db.showTargetName)
  local path=self:IconPath(info)
  if path then
    if path~=self.iconPath then self.icon:SetTexture(path); self.iconPath=path end
    self.icon:Show()
  else self.icon:Hide() end
  self.root:Show(); return true
end
function Threat:SelectedUnit()
  -- The user explicitly chose the current target, never mouseover or a
  -- remembered nameplate token. Clearing/changing target immediately refreshes.
  local valid,reason=self:IsHostileNPC("target")
  if valid then return "target" end
  return nil,reason
end
function Threat:ShouldPoll()
  return self.active and self.combat and not self.testing and self:SelectedUnit()~=nil
end
function Threat:UpdateHUD()
  if not self:IsEnabled() then self.hiddenReason="MODULE_OFF"; self:HideHUD(); return end
  if not self.inWorld then self.hiddenReason="OUT_OF_WORLD"; self:HideHUD(); return end
  -- Placement and test mode must remain visible above the settings window.
  local strata=(self.testing or not self.db.locked) and "FULLSCREEN_DIALOG" or "HIGH"
  self.root:SetFrameStrata(strata); self.anchor:SetFrameStrata(strata)
  if self.testing then
    self:ResetAggroAlert()
    self.hiddenReason="TEST_PREVIEW"
    self:ShowInfo(self.testInfo,"테스트 대상 (가상 데이터)","테스트 · "..({"여유","주의","위험","어그로 보유"})[self.testInfo.testLevel+1],"테스트 · 가상 데이터")
    return
  end
  local unit,reason=self:SelectedUnit()
  if not self.eligible then self.hiddenReason="GROUP_OR_PET_REQUIRED"
  elseif not self.roleAllowed then self.hiddenReason=self.playerRole=="NONE" and "INSTANCE_ROLE_UNKNOWN" or "INSTANCE_ROLE_DISABLED"
  elseif not self.detailAPI then self.hiddenReason="THREAT_API_UNAVAILABLE"
  elseif not self.combat then self.hiddenReason="OUT_OF_COMBAT"
  elseif not unit then self.hiddenReason=reason
  else self.hiddenReason="NO_THREAT_DATA" end
  if self.active and self.combat and unit then
    local info=self:GetThreatInfo("target",self.info)
    local name=call(UnitName,"target")
    if type(name)~="string" then name="현재 대상" end
    local _,hint=self:Risk(info)
    if not self.db.locked then hint="위치 이동 · 드래그 후 잠금" end
    if self:ShowInfo(info,name,hint) then self.hiddenReason="VISIBLE"; self:UpdateAggroAlert(info); return end
    if self.db.displayMode=="percent" and info.percent==nil then self.hiddenReason="SCALED_PERCENT_UNAVAILABLE" end
  end
  self:ResetAggroAlert()
  if not self.db.locked then
    self:ShowInfo(self.testInfo,"위치 미리보기 (가상 데이터)","KHQOL Threat · 드래그로 이동","위치 미리보기 · 가상 데이터")
  else self:HideHUD() end
end
function Threat:StopTicker()
  if self.ticker then self.ticker:Cancel(); self.ticker=nil end
end
function Threat:Tick()
  self:RefreshRoleFilter()
  if not self:ShouldPoll() then self:StopTicker(); self:UpdateHUD(); return end
  self:UpdateHUD()
end
function Threat:RefreshLoop()
  self:RefreshRoleFilter()
  if not self:ShouldPoll() then self:StopTicker(); self:UpdateHUD(); return end
  self:UpdateHUD()
  if self.timerAPI and not self.ticker then self.ticker=C_Timer.NewTicker(INTERVAL,function() self:Tick() end) end
end
function Threat:RefreshState()
  self:Capabilities(); self.eligible=self:Eligible()
  self:RefreshLoop()
end
function Threat:Changed()
  self:GetDB()
  if self.db.locked and self.dragging then self:SavePosition() end
  self:ApplyLayout(); self:RefreshState()
end
function Threat:SetEnabled(enabled)
  if not self.initialized then self:Initialize() end
  if self.dragging then self:SavePosition() end
  self:GetDB(); self.combat=yes(UnitAffectingCombat,"player")
  if not enabled then self.testing=false; self.debug=false end
  self:ApplyLayout(); self:RefreshState()
end

local function printLine(message)
  if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00KHQOL Threat:|r "..message) end
end
local function debugValue(value)
  if not readable(value) then return "<restricted>" end
  if value==nil then return "nil" end
  if type(value)=="number" or type(value)=="boolean" or type(value)=="string" then return tostring(value) end
  return "<unexpected type>"
end
function Threat:PrintStatus()
  self:RefreshState()
  local function yn(v) return v and "YES" or "NO" end
  printLine("Version: "..KHQOL.VERSION.." / Threat Module: "..(self:IsEnabled() and "ON" or "OFF").." / Display: SCREEN / Source: TARGET")
  printLine("In Group: "..yn(self.inGroup).." / In Raid: "..yn(self.inRaid).." / Class: "..self.class.." / Pet: "..yn(self.pet))
  printLine("Active: "..yn(self.active).." / Combat: "..yn(self.combat).." / Hostile Target: "..yn(self:SelectedUnit()).." / Ticker: "..(self.ticker and "RUNNING" or "STOPPED"))
  printLine("API: Detailed="..yn(self.detailAPI)..", Status="..yn(type(UnitThreatSituation)=="function")..", Ticker="..yn(self.timerAPI))
  printLine(string.format("Icon: %s / Size=%d / Position=%s / Caution=%s",yn(self.db.iconEnabled),self.db.iconSize,self.db.iconPosition,yn(self.db.showCautionIcon)))
  printLine("Aggro Voice: "..yn(self.db.aggroSoundEnabled).." / Threshold: "..AGGRO_SOUND_THRESHOLD.."% / Channel: Dialog (WoW dialogue volume)")
  printLine("Instance: "..self.instanceType.." / Role: "..self.playerRole.." ("..self.roleSource..") / Role Allowed: "..yn(self.roleAllowed))
  printLine("Instance Roles: TANK="..yn(self.db.instanceTankEnabled)..", DAMAGER="..yn(self.db.instanceDamageEnabled)..", HEALER="..yn(self.db.instanceHealerEnabled))
  local p=self.db.position
  printLine(string.format("Position: %s / X=%.0f / Y=%.0f / Locked=%s / Test=%s",p.point,p.x,p.y,yn(self.db.locked),yn(self.testing)))
  printLine("DisplayReason: "..(self.hiddenReason or "UNKNOWN"))
end
function Threat:DebugSnapshot()
  local unit="target"
  printLine("[Debug] Unit: target")
  local valid,reason=self:IsHostileNPC(unit)
  printLine("Target: Exists="..debugValue(call(UnitExists,unit)).." / CanAttack="..debugValue(call(UnitCanAttack,"player",unit)).." / IsPlayer="..debugValue(call(UnitIsPlayer,unit)).." / Reaction="..debugValue(call(UnitReaction,unit,"player")))
  printLine("TargetFilter: "..(valid and "PASS" or reason or "UNKNOWN").." / DisplayReason: "..(self.hiddenReason or "UNKNOWN"))
  if type(UnitDetailedThreatSituation)~="function" then printLine("UnitDetailedThreatSituation: unavailable"); return end
  local ok,tanking,s,scaled,raw,value=pcall(UnitDetailedThreatSituation,"player",unit)
  if not ok then printLine("Threat API call failed"); return end
  printLine("IsTanking="..debugValue(tanking).." / ThreatStatus="..debugValue(s))
  printLine("ScaledPercent="..debugValue(scaled).." / RawPercent="..debugValue(raw).." / ThreatValue(API raw units)="..debugValue(value))
  local info=self:GetThreatInfo(unit)
  printLine("PercentageSource: "..(info.percentBasis or "NONE"))
  printLine("Display: "..(self:IsHostileNPC(unit) and info.available and self:Format(info) or "HIDDEN"))
end
function Threat:HandleCommand(message)
  local command=(message or ""):lower():match("^%s*threat%s+(%S+)")
  if not command then KHQOL:OpenModule("threat")
  elseif command=="status" then self:PrintStatus()
  elseif command=="test" then
    local argument=(message or ""):lower():match("^%s*threat%s+test%s+(%S+)")
    if argument then
      local level=tonumber(argument)
      if not level or not self:TestStatus(level) then printLine("모듈을 켠 상태에서 /khqol threat test [0|1|2|3]을 사용하세요.") end
    else self:ToggleTest() end
  elseif command=="unlock" then self.db.locked=false; self:Changed(); self:RefreshControls()
  elseif command=="lock" then self.db.locked=true; self:Changed(); self:RefreshControls()
  elseif command=="reset" then self:ResetPosition(); self:RefreshControls()
  elseif command=="debug" then
    self.debug=not self.debug; printLine("Debug "..(self.debug and "ON" or "OFF"))
    if self.debug then self:DebugSnapshot() end
  else printLine("/khqol threat [status|test|unlock|lock|reset|debug]") end
end
function Threat:ToggleTest()
  if not self:IsEnabled() then printLine("먼저 Threat 모듈을 켜세요."); return end
  self.testing=not self.testing; self:RefreshLoop()
end
function Threat:TestStatus(s)
  s=number(s)
  if not self:IsEnabled() or not s or s>3 or s~=math.floor(s) then return false end
  self.testInfo.testLevel=s; self.testInfo.status=s==3 and 3 or 0; self.testInfo.isTanking=s==3
  self.testInfo.percent=({35,78,95,100})[s+1]
  self.testing=true; self:RefreshLoop()
  return true
end
function Threat:StopTest() self.testing=false end

function Threat:BuildSettings(content,y)
  local db=self:GetDB(); local b=KHQOL.UI:CreateBuilder(content,y)
  local function change(key,v) db[key]=v; self:Changed() end
  b:Section("위치")
  b:Checkbox("위치 잠금",function() return db.locked end,function(v) change("locked",v) end)
  b:Description("잠금을 풀면 이동 영역이 표시됩니다. 원하는 곳으로 드래그한 뒤 다시 잠그세요.")
  local function setCoordinate(axis,v)
    v=tonumber(v)
    if v and v==v and v~=math.huge and v~=-math.huge then
      if self.dragging then self:SavePosition() end
      db.position[axis]=math.max(-5000,math.min(5000,v)); self:Changed()
    end
  end
  b:Edit("X 위치 (Enter로 저장)",function() return string.format("%.0f",db.position.x) end,function(v) setCoordinate("x",v) end)
  b:Edit("Y 위치 (Enter로 저장)",function() return string.format("%.0f",db.position.y) end,function(v) setCoordinate("y",v) end)
  b:Button("위치 초기화",function() self:ResetPosition(); self:RefreshControls() end)
  b:Description("기본 위치는 화면 중앙에서 아래 120입니다. X는 오른쪽, Y는 위쪽이 양수입니다.")
  b:Section("어그로 표시")
  b:Description("현재 선택한 적 한 마리에 대한 내 Threat를 화면 독립 표시창에 보여줍니다.")
  b:Dropdown("표시 방식",{{value="percent",text="퍼센트 (권장)"},{value="value",text="누적 수치"},{value="both",text="수치 + 퍼센트"}},function() return db.displayMode end,function(v) change("displayMode",v) end)
  b:Slider("글씨 크기",10,24,1,function() return db.fontSize end,function(v) change("fontSize",v) end,function(v) return v.." px" end)
  b:Checkbox("어그로 위험도 색상",function() return db.colorByStatus end,function(v) change("colorByStatus",v) end)
  b:Checkbox("대상명 표시",function() return db.showTargetName end,function(v) change("showTargetName",v) end)
  b:Checkbox("하단 어그로 안내 표시",function() return db.showThreatHint end,function(v) change("showThreatHint",v) end)
  b:Description("100%는 어그로 전환 기준입니다. 70%부터 주의(노랑), 90%부터 위험(주황), 어그로 보유 중은 빨강입니다.")
  b:Description("70%와 90%는 안내 구간입니다. 게임의 전환 비율을 확인할 수 없으면 퍼센트 표시를 숨깁니다.")
  b:Section("인스턴스 내 위협 수치 설정")
  local function roleCheckbox(title,key)
    local theme=KHQOL.UI.Theme
    local x,y,width=b:Cell("instance-role",3,theme.RowHeight+theme.RowGap)
    local control=KHQOL.UI:CreateCheckbox(content,title,x,y,function() return db[key] end,function(v) change(key,v) end)
    control.text:SetWidth(width-theme.CheckboxSize-theme.CheckboxLabelGap)
  end
  roleCheckbox("탱","instanceTankEnabled")
  roleCheckbox("딜","instanceDamageEnabled")
  roleCheckbox("힐","instanceHealerEnabled")
  b:Description("던전·레이드에서 체크한 역할일 때만 위협 수치·아이콘·음성을 사용합니다. 기본은 탱 OFF, 딜·힐 ON입니다.")
  b:Dropdown("역할 판정",{{value="AUTO",text="자동 (파티 역할 / 전문화)"},{value="TANK",text="탱"},{value="DAMAGER",text="딜"},{value="HEALER",text="힐"}},function() return db.instanceRole end,function(v) change("instanceRole",v) end)
  b:Description("자동 인식이 안 되면 역할을 직접 선택하세요. 역할 미확인 시에는 숨기며, 세 역할을 모두 체크하면 표시합니다.")
  b:Description("필드의 기존 표시 조건은 유지합니다. 위치 미리보기와 가상 테스트는 역할 설정과 관계없이 사용할 수 있습니다.")
  b:Section("위협 수준 알림")
  b:Checkbox("위협 아이콘 표시",function() return db.iconEnabled end,function(v) change("iconEnabled",v) end)
  b:Checkbox("주의 단계에서도 아이콘 표시",function() return db.showCautionIcon end,function(v) change("showCautionIcon",v) end,function() return db.iconEnabled end)
  b:Slider("아이콘 크기",12,32,1,function() return db.iconSize end,function(v) change("iconSize",v) end,function(v) return v.." px" end,function() return db.iconEnabled end)
  b:Dropdown("아이콘 위치",{{value="LEFT",text="수치 앞"},{value="TOP",text="수치 위"}},function() return db.iconPosition end,function(v) change("iconPosition",v) end,function() return db.iconEnabled end)
  b:Description("기본은 위험 + 어그로 보유 단계입니다. 주의 단계는 선택할 수 있으며, 여유 단계에서는 아이콘을 숨깁니다.")
  b:Checkbox("어그로 95% 경고 음성",function() return db.aggroSoundEnabled end,function(v) change("aggroSoundEnabled",v) end)
  b:Description("전투 중 95% 이상 도달 시 한 번 재생합니다. 처음부터 어그로를 보유한 경우와 가상 테스트는 제외합니다.")
  b:Description("음량은 와우 소리 설정의 대화 음량으로 조절합니다. 95% 미만으로 내려갔다가 다시 도달하면 재생합니다.")
  b:Section("솔로 표시")
  b:Flush()
  KHQOL.UI:CreateCheckbox(content,"사냥꾼 / 흑마법사 + 소환수 보유 시 활성",0,b.y,function() return db.soloPetEnabled end,function(v) change("soloPetEnabled",v) end)
  b.y=b.y-KHQOL.UI.Theme.RowHeight-KHQOL.UI.Theme.RowGap
  b:Description("파티/공격대 또는 허용된 솔로 펫 조건에서 전투 중에만 실제 데이터를 갱신합니다.")
  b:Section("테스트 / 진단")
  b:Button("어그로 표시 테스트 / 종료",function() self:ToggleTest() end)
  b:Button("현재 상태 출력",function() self:PrintStatus() end)
  for s=0,3 do
    local testStatus=s
    b:Button(({"여유","주의","위험","어그로 보유"})[s+1].." 표시 테스트",function() self:TestStatus(testStatus) end)
  end
  b:Description("테스트는 실제 표시 위치에 가상 데이터를 띄웁니다. 테스트 중 실제 Threat 조회와 반복 갱신은 중지합니다.")
  b:Description("퍼센트는 게임의 어그로 전환 기준 대비 비율입니다. 진단: /khqol threat debug. 누적 수치는 API 원시 단위입니다.")
  content:HookScript("OnHide",function()
    if self.dragging then self:SavePosition() end
    db.locked=true; self.testing=false; self:Changed()
  end)
  return b.y
end
function Threat:OnEvent(event,unit)
  if not readable(unit) then return end
  if event=="PLAYER_REGEN_DISABLED" then self:ResetAggroAlert(); self.combat=true; self:StopTest(); self:RefreshState()
  elseif event=="PLAYER_REGEN_ENABLED" then self:ResetAggroAlert(); self.combat=false; self:StopTest(); self:StopTicker(); self:UpdateHUD()
  elseif event=="PLAYER_LEAVING_WORLD" then
    if self.dragging then self:SavePosition() end
    self.inWorld=false; self.active=false; self:StopTest(); self:StopTicker(); self:HideHUD()
  elseif event=="PLAYER_ENTERING_WORLD" then
    self:ResetAggroAlert()
    self.inWorld=true; self.combat=yes(UnitAffectingCombat,"player"); self:RefreshState()
  elseif event=="GROUP_ROSTER_UPDATE" or event=="UNIT_PET" or (event=="UNIT_FLAGS" and unit=="pet") then self:RefreshState()
  elseif event=="PLAYER_ROLES_ASSIGNED" or event=="ROLE_CHANGED_INFORM" or event=="PLAYER_SPECIALIZATION_CHANGED" or event=="ACTIVE_TALENT_GROUP_CHANGED" or event=="PLAYER_TALENT_UPDATE" or event=="ZONE_CHANGED_NEW_AREA" then self:RefreshState()
  elseif event=="PLAYER_TARGET_CHANGED" then
    self:ResetAggroAlert()
    if self.debug then self:DebugSnapshot() end
    self:RefreshLoop()
  elseif (event=="UNIT_FACTION" or event=="UNIT_FLAGS") and unit=="target" then self:RefreshLoop()
  end
end
function Threat:Initialize()
  if self.initialized then return end
  self.initialized=true; self.inWorld=true; self:GetDB(); self:CreateFrames(); self:ApplyLayout()
  self.combat=yes(UnitAffectingCombat,"player")
  local frame=CreateFrame("Frame"); self.events=frame
  for _,event in ipairs({"PLAYER_ENTERING_WORLD","PLAYER_LEAVING_WORLD","GROUP_ROSTER_UPDATE","UNIT_PET","UNIT_FLAGS","PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED","UNIT_FACTION","PLAYER_TARGET_CHANGED","PLAYER_ROLES_ASSIGNED","ROLE_CHANGED_INFORM","PLAYER_SPECIALIZATION_CHANGED","ACTIVE_TALENT_GROUP_CHANGED","PLAYER_TALENT_UPDATE","ZONE_CHANGED_NEW_AREA"}) do
    pcall(frame.RegisterEvent,frame,event)
  end
  frame:SetScript("OnEvent",function(_,event,unit) self:OnEvent(event,unit) end)
  self:RefreshState()
end
