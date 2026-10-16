local _, KHQOL = ...
KHQOL = assert(_G.KHQOL, "Install and enable the KHQOL core addon.")
local B=KHQOL.modules.basicUI
local M={Write=B.Write,Release=B.Release}; KHQOL.modules.unitFrames=M
local call,public=KHQOL.PublicCall,KHQOL.IsPublicValue
M.defaults={player={compact=false,health="default",power="default",width=200,height=58,gap=2,borderAlpha=.85,textSize=12,healthColorMode="default",healthColor={r=0,g=1,b=0},
 namePosition="above",nameX=0,nameY=0,levelPosition="above",levelX=0,levelY=0,bottomX=0,bottomY=0},
 target={compact=false,health="default",power="default",width=200,height=58,gap=2,borderAlpha=.85,textSize=12,healthColorMode="default",healthColor={r=1,g=0,b=0}},
 pet={compact=false,width=120,height=42,healthHeight=16,powerHeight=8},
 targettarget={compact=false,width=120,height=42,healthHeight=16,powerHeight=8,frameX=0,frameY=0},
 focus={compact=false,health="default",power="default",width=200,height=58}}
local appearanceDefaults={health="default",power="default",gap=2,borderAlpha=.85,textSize=12,
 healthColorMode="default",healthColor={r=0,g=1,b=0},borderStyle="none",
 namePosition="above",nameSide="LEFT",nameX=0,nameY=0,levelPosition="above",levelSide="RIGHT",levelX=0,levelY=0}
M.unitTokens={"player","target","pet","targettarget","focus"}
for _,unit in ipairs(M.unitTokens) do
  KHQOL.MergeDefaults(M.defaults[unit],appearanceDefaults,"tables")
  M.defaults[unit].markerX=0;M.defaults[unit].markerY=0
  M.defaults[unit].statusX=0;M.defaults[unit].statusY=0
end
M.defaults.player.restX=0;M.defaults.player.restY=0
M.defaults.player.combatX=0;M.defaults.player.combatY=0
for _,unit in ipairs({"player","target"}) do
  M.defaults[unit].nameColorMode="default";M.defaults[unit].nameColor={r=1,g=.82,b=0}
  M.defaults[unit].levelColorMode="default";M.defaults[unit].levelColor={r=1,g=1,b=1}
end
M.defaults.target.auras={friendlyPlayer={enabled=false,showBuffs=true,showDebuffs=true,size=20,position="below",x=0,y=0},
 attackableNPC={enabled=false,showBuffs=true,showDebuffs=true,size=20,position="below",x=0,y=0}}
M.defaults.player.auras={buffs={enabled=false,size=20,position="above",x=0,y=0},
 debuffs={enabled=false,size=20,position="below",x=0,y=-24}}
for _,cfg in pairs(M.defaults.player.auras) do
  cfg.layoutEnabled=false;cfg.perRow=8;cfg.maxRows=4;cfg.growth="RIGHT_DOWN"
end
for _,cfg in pairs(M.defaults.target.auras) do
  cfg.layoutEnabled=false;cfg.separatePositions=false
  cfg.buffs={perRow=8,maxRows=4,growth="RIGHT_DOWN"}
  cfg.debuffs={perRow=8,maxRows=2,growth="RIGHT_DOWN"}
end
M.defaults.player.showEnergyTick=false; M.defaults.target.hideDefaultCombo=false
function KHQOL:MigrateUnitFrameSettings(settings)
  settings.modules=settings.modules or {}; settings.enabled=settings.enabled or {}
  local old=type(settings.modules.basicUI)=="table" and settings.modules.basicUI or nil
  if not settings.modules.unitFrames and old and (old.player or old.target) then
    settings.modules.unitFrames={player=old.player,target=old.target}
    settings.enabled.unitFrames=settings.enabled.basicUI~=false
  end
  if old then old.player=nil; old.target=nil end
end
function M:GetDB()
  KHQOL:MigrateUnitFrameSettings(KHQOL.db)
  KHQOL.db.modules.unitFrames=KHQOL.MergeDefaults(KHQOL.db.modules.unitFrames or {},self.defaults,"tables")
  for _,unit in ipairs({"target","targettarget","focus"}) do
    local d=KHQOL.db.modules.unitFrames[unit]
    if d.healthColorMode=="red" or d.healthColorMode=="class" then d.healthColorMode="reaction" end
  end
  return KHQOL.db.modules.unitFrames
end
function M:IsEnabled() return KHQOL:CanRunModule("unitFrames") end
function M:OpenNativePositionEditor()
  -- The client's menu owns edit-mode activation. Avoid invoking an unverified
  -- protected toggle from an addon or committing a KHQOL draft during transfer.
  if KHQOL.PositionEditor and KHQOL.PositionEditor.active then KHQOL.PositionEditor:Finish(false) end
  if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("KHQOL: 전체 유닛프레임 이동은 ESC → 편집 모드에서 조절하세요. KHQOL 부품 위치는 각 드래그 이동 버튼을 사용합니다.") end
end
local function combat() return call(InCombatLockdown)==true end
local function editing() return EditModeManagerFrame and call(EditModeManagerFrame.IsShown,EditModeManagerFrame)==true end
function M:UnitParts(unit)
  if unit=="pet" or unit=="targettarget" then return self:AuxiliaryParts(unit) end
  local root=unit=="player" and _G.PlayerFrame or unit=="focus" and _G.FocusFrame or unit=="target" and _G.TargetFrame
  if not root then return end
  local content=unit=="player" and root.PlayerFrameContent or root.TargetFrameContent
  local main=content and (unit=="player" and content.PlayerFrameContentMain or content.TargetFrameContentMain)
  local container=unit=="player" and root.PlayerFrameContainer or root.TargetFrameContainer
  local health=main and main.HealthBarsContainer
  local power=main and (unit=="player" and main.ManaBarArea and main.ManaBarArea.ManaBar or main.ManaBar)
  if not main or not container or not health or not health.HealthBar or not power then return end
  return {root=root,main=main,container=container,healthContainer=health,health=health.HealthBar,power=power,
    name=unit=="player" and _G.PlayerName or main.Name,level=unit=="player" and _G.PlayerLevelText or main.LevelText,
    portrait=unit=="player" and container.PlayerPortrait or container.Portrait,
    context=content and (unit=="player" and content.PlayerFrameContentContextual or content.TargetFrameContentContextual),
    healthMask=health.HealthBarMask,powerMask=power.ManaBarMask}
end
local function valid(v) return public(v) and type(v)=="number" and v==v and v>=0 and v<math.huge end
local function bounded(v,fallback,low,high)
  local n=public(v) and tonumber(v) or nil
  if not valid(n) then n=fallback end
  return math.max(low,math.min(high,n))
end
-- Missing independent heights retain the exact legacy split. New fields are
-- written only when the user changes a height or resource visibility option.
function M:CompactLayout(db)
  local width=bounded(db.width,200,60,400)
  local gap=bounded(db.gap,2,0,20)
  local legacyHeight=math.max(bounded(db.height,58,44,120),36+gap)
  local legacyHealth=math.floor((legacyHeight-16-gap)*.6)
  local healthHeight=bounded(db.healthHeight,legacyHealth,8,100)
  local powerHeight=bounded(db.powerHeight,legacyHeight-16-gap-legacyHealth,4,100)
  local showPower=db.showPower~=false
  local height=16+healthHeight+(showPower and gap+powerHeight or 0)
  return width,height,gap,healthHeight,powerHeight,showPower
end
function M:SetBarHeight(unit,kind,value)
  local db=self:GetDB()[unit]
  local _,_,_,healthHeight,powerHeight=self:CompactLayout(db)
  db.healthHeight,db.powerHeight=healthHeight,powerHeight
  local key=kind=="health" and "healthHeight" or "powerHeight"
  db[key]=bounded(value,db[key],kind=="health" and 8 or 4,100)
  self:ApplySettings()
end
function M:SetTotalHeight(unit,value)
  local db=self:GetDB()[unit]
  local _,_,gap,healthHeight,powerHeight,showPower=self:CompactLayout(db)
  local height=bounded(value,16+healthHeight+(showPower and gap+powerHeight or 0),24,236)
  if showPower then
    local available=math.max(12,math.min(200,height-16-gap))
    healthHeight=math.max(8,math.min(100,math.floor(available*.6)))
    powerHeight=math.max(4,math.min(100,available-healthHeight))
    healthHeight=available-powerHeight
  else healthHeight=bounded(height-16,healthHeight,8,100) end
  db.height,db.healthHeight,db.powerHeight=height,healthHeight,powerHeight
  self:ApplySettings()
end
function M:FormatValue(unit,kind,mode)
  if mode=="hide" or mode=="default" or call(UnitExists,unit)~=true then return "" end
  if kind=="health" and call(UnitIsDeadOrGhost,unit)==true then return DEAD or "죽음" end
  local current,maximum
  if kind=="health" then current=call(UnitHealth,unit); maximum=call(UnitHealthMax,unit)
  else
    current=call(UnitPower,unit); maximum=call(UnitPowerMax,unit)
  end
  if not valid(current) or not valid(maximum) or maximum<=0 then return "" end
  local value=string.format("%.0f",current); local max=string.format("%.0f",maximum)
  local percent=string.format("%.0f%%",math.min(100,current/maximum*100))
  if mode=="current" then return value elseif mode=="both" then return value.." / "..max
  elseif mode=="percent" then return percent elseif mode=="currentPercent" then return value.." ("..percent..")" end
  return ""
end
-- Secret health/power values are passed only to the engine's text renderer.
-- Never perform Lua arithmetic, stringify, compare, or inspect protected values.
function M:RenderValue(text,unit,kind,mode)
  local ordinary=self:FormatValue(unit,kind,mode)
  if ordinary~="" then text:SetText(ordinary); return true end
  if mode=="hide" or mode=="default" or call(UnitExists,unit)~=true then return false end
  local function read(fn,...)
    if type(fn)~="function" then return false,nil end
    return pcall(fn,...)
  end
  local ok,current=read(kind=="health" and UnitHealth or UnitPower,unit)
  local maxOK,maximum=read(kind=="health" and UnitHealthMax or UnitPowerMax,unit)
  if not ok or type(current)~="number" then return false end
  if public(current) and public(maximum) then return false end -- invalid public numbers
  if mode=="current" then return pcall(text.SetFormattedText,text,"%.0f",current) end
  if mode=="both" then
    if not maxOK or type(maximum)~="number" then return false end
    return pcall(text.SetFormattedText,text,"%.0f / %.0f",current,maximum)
  end
  local curve=CurveConstants and CurveConstants.ScaleTo100
  if not curve then return false end
  local percentOK,percent
  if kind=="health" then percentOK,percent=read(UnitHealthPercent,unit,true,curve)
  else percentOK,percent=read(UnitPowerPercent,unit,nil,false,curve) end
  if not percentOK or type(percent)~="number" then return false end
  if mode=="percent" then return pcall(text.SetFormattedText,text,"%.0f%%",percent) end
  if mode=="currentPercent" then return pcall(text.SetFormattedText,text,"%.0f (%.0f%%)",current,percent) end
  return false
end
function M:UpdateBarText(owner,bar,unit,kind)
  if self.updatingText then return end
  self.updatingText=true
  local ok,err=pcall(self.UpdateBarTextNow,self,owner,bar,unit,kind)
  self.updatingText=false
  if not ok then error(err,0) end
end
function M:UpdateBarTextNow(owner,bar,unit,kind)
  if kind=="health" then self:ApplyHealthTextContrast(owner,bar,unit) end
  local mode=self:IsEnabled() and not editing() and self:GetDB()[unit][kind] or "default"
  if (unit=="target" or unit=="focus") and kind=="health" and self:IsEnabled() and not editing() then
    local p=owner.parts;local native=p and p.healthContainer and p.healthContainer.DeadText
    if native and (call(UnitIsDeadOrGhost,unit)==true or call(native.IsShown,native)==true) then
      mode="hide" -- Preserve the native localized death label; remove our 0.
    end
  end
  local state=owner.textOwners and owner.textOwners[kind]
  local mirrored=kind=="health" and owner.compactActive and owner.healthDisplay~=nil
  local visualBar=mirrored and owner.healthDisplay or bar
  if mirrored and state then self:Release(state) end
  if mirrored then self:SyncDisplayText(owner,owner.parts) end
  if state then
    if state.text then state.text:Hide() end
    if state.layer then state.layer:Hide() end
  end
  if mode=="default" or (kind=="power" and owner.powerHidden) then
    if state then self:Release(state) end
    if mirrored then self:SyncDisplayText(owner,owner.parts) end
    return
  end
  owner.textOwners=owner.textOwners or {}
  if not state then
    state={}; owner.textOwners[kind]=state
  end
  if mode=="hide" then
    for _,key in ipairs({"TextString","LeftText","RightText","HealthBarText","ManaBarText"}) do
      if bar[key] and not mirrored then self:Write(state,bar[key],"alpha",0) end
    end
    return
  end
  if not state.layer then
    local parent=owner.parts and owner.parts.root or bar:GetParent()
    local layer=CreateFrame("Frame",nil,parent); state.layer=layer
    layer:SetAllPoints(visualBar); layer:EnableMouse(false)
    local barLevel,parentLevel=call(bar.GetFrameLevel,bar),call(parent.GetFrameLevel,parent)
    if valid(barLevel) and valid(parentLevel) then layer:SetFrameLevel(math.max(barLevel,parentLevel)+30) end
    local text=layer:CreateFontString(nil,"OVERLAY")
    -- Anchor geometry is resolved by the engine. Never copy secret GetWidth()
    -- results into a size setter, even after a secret text has been rendered.
    text:SetPoint("LEFT",visualBar,"LEFT",0,0); text:SetPoint("RIGHT",visualBar,"RIGHT",0,0)
    text:SetJustifyH("CENTER"); text:SetJustifyV("MIDDLE"); state.text=text
  end
  if state.anchorBar~=visualBar and not combat() then
    state.anchorBar=visualBar;state.layer:SetAllPoints(visualBar);state.text:ClearAllPoints()
    state.text:SetPoint("LEFT",visualBar,"LEFT",0,0);state.text:SetPoint("RIGHT",visualBar,"RIGHT",0,0)
  end
  state.text:Hide(); state.layer:Hide()
  state.text:SetFont(KHQOL.UI:Font(),math.max(8,math.min(24,tonumber(self:GetDB()[unit].textSize) or 12)),kind=="health" and self:HealthTextFlags() or "OUTLINE")
  if kind=="health" then
    if state.text.SetShadowColor then state.text:SetShadowColor(0,0,0,1) end
    if state.text.SetShadowOffset then state.text:SetShadowOffset(1,-1) end
  end
  state.text:SetTextColor(1,1,1,1)
  if not self:RenderValue(state.text,unit,kind,mode) then self:Release(state); return end
  for _,key in ipairs({"TextString","LeftText","RightText","HealthBarText","ManaBarText"}) do
    if bar[key] and not mirrored then self:Write(state,bar[key],"alpha",0) end
  end
  state.text:Show(); state.layer:SetShown(call(bar.IsShown,bar)==true)
end
-- Compact frames suppress native threat art instead of drawing another frame.
function M:CompactThreat(owner,p,on)
  for _,texture in ipairs(owner.edges or {}) do texture:Hide() end
end
function M:ApplyCompact(owner,p,unit,on)
  return self:ApplyCompactLayout(owner,p,unit,on)
end
function M:ApplyPowerVisibility(owner,p,unit)
  if combat() then self.pending=true; return end
  local hide=self:IsEnabled() and not editing() and self:GetDB()[unit].showPower==false
  if hide then
    owner.powerOwner=owner.powerOwner or {}
    owner.powerOwner.compactActive=true
    self:HideNativeDecoration(owner.powerOwner,p.power)
    owner.powerHidden=owner.powerOwner.artAlpha and owner.powerOwner.artAlpha[p.power]~=nil or false
    if owner.powerHidden and type(p.power.IsMouseMotionEnabled)=="function" and type(p.power.EnableMouseMotion)=="function" then
      self:Write(owner.powerOwner,p.power,"motion",false)
    end
  else
    if owner.powerOwner then owner.powerOwner.compactActive=false;self:ReleaseNativeDecorations(owner.powerOwner);self:Release(owner.powerOwner) end
    owner.powerHidden=false
  end
end
function M:ApplyUnits(onlyUnit)
  if self.applyingUnits then return end
  self.applyingUnits=true
  local ok,err=pcall(self.ApplyUnitsNow,self,onlyUnit)
  self.applyingUnits=false
  if not ok then error(err,0) end
end
function M:ApplyUnitsNow(onlyUnit)
  self.propertyDeferred=false
  self.units=self.units or {}
  for _,unit in ipairs(self.unitTokens) do
    local p=(not onlyUnit or onlyUnit==unit) and self:UnitParts(unit)
    if p then
      local owner=self.units[unit] or {}; self.units[unit]=owner; owner.parts=p;p.owner=owner;p.unit=unit
      local compact=self:IsEnabled() and self:GetDB()[unit].compact and not editing()
      self:ApplyCompact(owner,p,unit,compact)
      if unit=="targettarget" then self:ApplyFramePosition(owner,p) end
      self:ApplyPowerVisibility(owner,p,unit); self:ApplyHealthColor(owner,p,unit)
      if unit=="target" then self:ApplyMonsterMarks(owner,p,true) end
      self:ApplyLabelColors(owner,p,unit)
      if unit=="target" then self:ApplyTargetAuras(owner,p) end
      if unit=="player" then self:ApplyPlayerAuras(owner,p) end
      for _,kind in ipairs({"health","power"}) do
        local bar=p[kind]
        self:UpdateBarText(owner,bar,unit,kind)
        owner.textHooks=owner.textHooks or {}
        if not owner.textHooks[bar] and type(bar.UpdateTextStringWithValues)=="function" then
          owner.textHooks[bar]=true
          hooksecurefunc(bar,"UpdateTextStringWithValues",function() M:UpdateBarText(owner,bar,unit,kind) end)
        end
      end
      if not owner.eventHook then
        owner.eventHook=true
        local hookUnit=unit
        p.root:HookScript("OnEvent",function(_,event)
          if M:IsEnabled() then M:UpdateUnitValues(hookUnit); M:ApplyStateDecorations(owner,p,hookUnit) end
        end)
        p.root:HookScript("OnShow",function() if M:IsEnabled() then M:ApplyUnits(hookUnit) end end)
        if unit=="target" then p.root:HookScript("OnHide",function() if M.monsterMarkFrame then M.monsterMarkFrame:Hide() end end) end
      end
    end
  end
end
function M:QueuePlayerLayout()
  if self.playerLayoutQueued or self.applyingUnits or not self:IsEnabled() then return end
  self.playerLayoutQueued=true
  local function apply()
    self.playerLayoutQueued=nil
    if not M:IsEnabled() then return end
    if combat() then M.pending=true;return end
    M:InitializePlayerLayoutHooks()
    M:ApplyUnits("player");M:ApplyBottom()
  end
  if C_Timer and C_Timer.After then C_Timer.After(0,apply) else apply() end
end
function M:InitializePlayerLayoutHooks()
  self.playerLayoutHooks=self.playerLayoutHooks or {}
  for _,name in ipairs({"PlayerFrame_UpdateArt","PlayerFrame_ToPlayerArt","PlayerFrame_ToVehicleArt"}) do
    if type(_G[name])=="function" and not self.playerLayoutHooks[name] then
      self.playerLayoutHooks[name]=true
      hooksecurefunc(name,function() M:QueuePlayerLayout() end)
    end
  end
  local root=_G.PlayerFrame
  if root and not self.playerLayoutHooks[root] then
    self.playerLayoutHooks[root]=true
    root:HookScript("OnShow",function() M:QueuePlayerLayout() end)
  end
end
function M:ApplySettings()
  self:InitializePlayerLayoutHooks()
  self:InitializeDecorHooks()
  self:ApplyUnits(); self:RefreshMonsterMarks();self:ApplyBottom(); if not combat() and not self.propertyDeferred then self.pending=nil end
end
function M:SetEnabled(on)
  self:Initialize(); self:ApplySettings();self:ConfigureEvents()
end
function M:ConfigureEvents()
  if not self.events then return end
  self.events:UnregisterAllEvents()
  if self:IsEnabled() then
    for _,event in ipairs({"PLAYER_REGEN_ENABLED","PLAYER_REGEN_DISABLED","PLAYER_ENTERING_WORLD","PLAYER_TARGET_CHANGED","PLAYER_FOCUS_CHANGED","UNIT_HEALTH","UNIT_MAXHEALTH","UNIT_POWER_UPDATE","UNIT_MAXPOWER","UNIT_DISPLAYPOWER","UNIT_FLAGS","UNIT_FACTION","UNIT_CONNECTION","UNIT_NAME_UPDATE","UNIT_PET","UNIT_TARGET","UNIT_THREAT_LIST_UPDATE","UNIT_THREAT_SITUATION_UPDATE","RAID_TARGET_UPDATE","PLAYER_UPDATE_RESTING","PLAYER_TOTEM_UPDATE","PLAYER_ALIVE","PLAYER_UNGHOST","ADDON_LOADED","UNIT_CLASSIFICATION_CHANGED","QUEST_LOG_UPDATE","QUEST_WATCH_UPDATE","QUEST_TURNED_IN"}) do pcall(self.events.RegisterEvent,self.events,event) end
  elseif self.pending then
    for _,event in ipairs({"PLAYER_REGEN_ENABLED","PLAYER_ENTERING_WORLD","ADDON_LOADED"}) do self.events:RegisterEvent(event) end
  end
end
function M:Initialize()
  if self.events then self:InitializeDecorHooks(); return end
  self.events=CreateFrame("Frame")
  self:InitializePlayerLayoutHooks()
  self:ConfigureEvents()
  self.events:SetScript("OnEvent",function(_,event,unit)
    if event=="PLAYER_REGEN_ENABLED" then if M.pending or M:IsEnabled() then M:ApplySettings() end;M:ConfigureEvents(); return end
    if not M:IsEnabled() then
      if M.pending and (event=="PLAYER_ENTERING_WORLD" or event=="ADDON_LOADED") then M:ApplySettings();M:ConfigureEvents() end
      return
    end
    if event=="UNIT_CLASSIFICATION_CHANGED" then
      if public(unit) and unit=="target" then M:RefreshMonsterMarks() end
    elseif event=="QUEST_LOG_UPDATE" or event=="QUEST_WATCH_UPDATE" or event=="QUEST_TURNED_IN" then M:RefreshMonsterMarks()
    elseif event=="UNIT_HEALTH" or event=="UNIT_MAXHEALTH" or event=="UNIT_POWER_UPDATE" or event=="UNIT_MAXPOWER" or event=="UNIT_FLAGS" or event=="UNIT_FACTION" or event=="UNIT_CONNECTION" then
      if public(unit) and (unit=="player" or unit=="target" or unit=="pet" or unit=="targettarget" or unit=="focus") then M:UpdateUnitValues(unit) end
    elseif event=="UNIT_DISPLAYPOWER" then
      if public(unit) and (unit=="player" or unit=="target" or unit=="pet" or unit=="targettarget" or unit=="focus") then M:ApplyUnits(unit) end
    elseif event=="UNIT_PET" then M:ApplyUnits("pet")
    elseif event=="UNIT_TARGET" then
      if public(unit) and unit=="target" then M:ApplyUnits("targettarget") end
      for _,token in ipairs({"target","targettarget","focus"}) do M:UpdateUnitValues(token) end
    elseif event=="PLAYER_TARGET_CHANGED" then M:ApplyUnits("target"); M:ApplyUnits("targettarget");M:RefreshTargetAuraLayouts()
    elseif event=="PLAYER_FOCUS_CHANGED" then M:ApplyUnits("focus")
    elseif event=="UNIT_THREAT_LIST_UPDATE" or event=="UNIT_THREAT_SITUATION_UPDATE" or event=="PLAYER_REGEN_DISABLED" then
      for _,token in ipairs({"target","targettarget","focus"}) do M:UpdateUnitValues(token) end
    elseif event=="RAID_TARGET_UPDATE" or event=="PLAYER_UPDATE_RESTING" then
      for token,owner in pairs(M.units or {}) do M:ApplyStateDecorations(owner,owner.parts,token) end
    elseif event=="PLAYER_TOTEM_UPDATE" then M:ApplyBottom()
    else M:ApplySettings();if event=="PLAYER_ENTERING_WORLD" or event=="ADDON_LOADED" then M:QueuePlayerLayout() end end
  end)
  self:InitializeDecorHooks()
  if EditModeManagerFrame then
    EditModeManagerFrame:HookScript("OnShow",function() M:ApplySettings() end)
    EditModeManagerFrame:HookScript("OnHide",function() M:ApplySettings() end)
  end
  if type(PlayerFrame_UpdatePlayerNameTextAnchor)=="function" then
    hooksecurefunc("PlayerFrame_UpdatePlayerNameTextAnchor",function() if M:IsEnabled() then M:ApplyUnits("player") end end)
  end
end
