local _, KHQOL = ...
local B=KHQOL.modules.basicUI
local M={experimental=true,Write=B.Write,Release=B.Release}; KHQOL.modules.unitFrames=M
local call,public=KHQOL.PublicCall,KHQOL.IsPublicValue
M.defaults={player={compact=false,health="default",power="default",width=200,height=58,gap=2,borderAlpha=.85,textSize=12},
 target={compact=false,health="default",power="default",width=200,height=58,gap=2,borderAlpha=.85,textSize=12}}
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
  return KHQOL.db.modules.unitFrames
end
function M:IsEnabled() return KHQOL:CanRunModule("unitFrames") end
local function combat() return call(InCombatLockdown)==true end
local function editing() return EditModeManagerFrame and call(EditModeManagerFrame.IsShown,EditModeManagerFrame)==true end
function M:UnitParts(unit)
  local root=unit=="player" and _G.PlayerFrame or _G.TargetFrame
  if not root then return end
  local content=unit=="player" and root.PlayerFrameContent or root.TargetFrameContent
  local main=content and (unit=="player" and content.PlayerFrameContentMain or content.TargetFrameContentMain)
  local container=unit=="player" and root.PlayerFrameContainer or root.TargetFrameContainer
  local health=main and main.HealthBarsContainer
  local power=main and (unit=="player" and main.ManaBarArea and main.ManaBarArea.ManaBar or main.ManaBar)
  if not main or not container or not health or not health.HealthBar or not power then return end
  return {root=root,main=main,container=container,healthContainer=health,health=health.HealthBar,power=power,
    name=unit=="player" and _G.PlayerName or main.Name,level=unit=="player" and _G.PlayerLevelText or main.LevelText,
    portrait=unit=="player" and container.PlayerPortrait or container.Portrait}
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
  local width=bounded(db.width,200,120,400)
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
  local mode=self:IsEnabled() and self:GetDB()[unit][kind] or "default"
  local state=owner.textOwners and owner.textOwners[kind]
  if state then
    if state.text then state.text:Hide() end
    if state.layer then state.layer:Hide() end
  end
  if mode=="default" or (kind=="power" and owner.powerHidden) then
    if state then self:Release(state) end
    return
  end
  owner.textOwners=owner.textOwners or {}
  if not state then
    state={}; owner.textOwners[kind]=state
  end
  if mode=="hide" then
    for _,key in ipairs({"TextString","LeftText","RightText","HealthBarText","ManaBarText"}) do
      if bar[key] then self:Write(state,bar[key],"alpha",0) end
    end
    return
  end
  if not state.layer then
    local parent=owner.parts and owner.parts.root or bar:GetParent()
    local layer=CreateFrame("Frame",nil,parent); state.layer=layer
    layer:SetAllPoints(bar); layer:EnableMouse(false)
    local barLevel,parentLevel=call(bar.GetFrameLevel,bar),call(parent.GetFrameLevel,parent)
    if valid(barLevel) and valid(parentLevel) then layer:SetFrameLevel(math.max(barLevel,parentLevel)+30) end
    local text=layer:CreateFontString(nil,"OVERLAY")
    -- Anchor geometry is resolved by the engine. Never copy secret GetWidth()
    -- results into a size setter, even after a secret text has been rendered.
    text:SetPoint("LEFT",bar,"LEFT",0,0); text:SetPoint("RIGHT",bar,"RIGHT",0,0)
    text:SetJustifyH("CENTER"); text:SetJustifyV("MIDDLE"); state.text=text
  end
  state.text:Hide(); state.layer:Hide()
  state.text:SetFont(KHQOL.UI:Font(),math.max(8,math.min(24,tonumber(self:GetDB()[unit].textSize) or 12)),"OUTLINE")
  state.text:SetTextColor(1,1,1,1)
  if not self:RenderValue(state.text,unit,kind,mode) then self:Release(state); return end
  for _,key in ipairs({"TextString","LeftText","RightText","HealthBarText","ManaBarText"}) do
    if bar[key] then self:Write(state,bar[key],"alpha",0) end
  end
  state.text:Show(); state.layer:SetShown(call(bar.IsShown,bar)==true)
end
-- Mirror the native threat flash onto rectangular compact edges. Native event,
-- color and pulse timing remain the source of truth; no threat values are read.
function M:CompactThreat(owner,p,on)
  owner.compactActive=on
  if not on and not owner.edges then return end
  if not owner.edges then
    owner.edges={}
    for i=1,4 do local t=p.root:CreateTexture(nil,"OVERLAY",nil,7); t:SetColorTexture(1,0,0,1); t:Hide(); owner.edges[i]=t end
  end
  local native=p.root.threatIndicator or p.container.FrameFlash or p.container.Flash
  if not native then return end
  if not owner.threatHook then
    owner.threatHook=true; owner.nativeThreat=native
    local function update(alpha)
      if not owner.compactActive then for _,t in ipairs(owner.edges) do t:Hide() end; return end
      local shown=call(native.IsShown,native)==true
      for _,t in ipairs(owner.edges) do t:SetShown(shown); if public(alpha) and type(alpha)=="number" then t:SetAlpha(alpha) end end
    end
    hooksecurefunc(native,"Show",function() update(owner.threatAlpha or 1) end)
    hooksecurefunc(native,"Hide",function() update(0) end)
    hooksecurefunc(native,"SetVertexColor",function(_,red,green,blue,alpha)
      if public(red) and public(green) and public(blue) and type(red)=="number" and type(green)=="number" and type(blue)=="number" then
        for _,t in ipairs(owner.edges) do t:SetVertexColor(red,green,blue) end
      end
    end)
    hooksecurefunc(native,"SetAlpha",function(_,alpha)
      if owner.threatWriting or not owner.compactActive then return end
      if public(alpha) and type(alpha)=="number" then owner.threatAlpha=alpha end
      update(alpha)
      owner.threatWriting=true; M:Write(owner,native,"alpha",0); owner.threatWriting=false
    end)
    owner.updateThreat=update
  end
  if on then
    local width,height=owner.compactWidth,owner.compactHeight
    local a,b,c,d=unpack(owner.edges)
    for _,t in ipairs(owner.edges) do t:ClearAllPoints() end
    a:SetPoint("TOPLEFT",p.root,"TOPLEFT",16,-24); a:SetSize(width,2)
    b:SetPoint("TOPLEFT",p.root,"TOPLEFT",16,-24-height+2); b:SetSize(width,2)
    c:SetPoint("TOPLEFT",p.root,"TOPLEFT",16,-24); c:SetSize(2,height)
    d:SetPoint("TOPLEFT",p.root,"TOPLEFT",16+width-2,-24); d:SetSize(2,height)
    if not owner.threatAlpha then owner.threatAlpha=call(native.GetAlpha,native) or 1 end
    owner.threatWriting=true; self:Write(owner,native,"alpha",0); owner.threatWriting=false
    owner.updateThreat(owner.threatAlpha)
  else
    for _,t in ipairs(owner.edges) do t:Hide() end
  end
end
function M:ApplyCompact(owner,p,unit,on)
  if combat() then self.pending=true; return end
  if not on then
    self:CompactThreat(owner,p,false)
    self:Release(owner); if owner.background then owner.background:Hide() end
    return
  end
  local db=self:GetDB()[unit]
  -- Do not create half a compact layout if its native baseline is unreadable.
  -- Public explicit dimensions may remain available when the resolved rect is secret.
  for _,entry in ipairs({{p.root,"width"},{p.root,"height"},{p.healthContainer,"width"},
    {p.healthContainer,"height"},{p.health,"width"},{p.health,"height"},
    {p.power,"width"},{p.power,"height"}}) do
    if not B:CanRead(entry[1],entry[2]) then self.propertyDeferred=true;self.pending=true;return end
  end
  local width,height,gap,healthHeight,powerHeight=self:CompactLayout(db)
  owner.compactWidth,owner.compactHeight=width,height
  if not owner.background then
    local t=p.root:CreateTexture(nil,"BACKGROUND",nil,-8)
    t:SetColorTexture(.04,.04,.04,1); t:SetPoint("TOPLEFT",p.root,16,-24); t:SetSize(width,height)
    owner.background=t
  end
  owner.background:SetSize(width,height); owner.background:SetAlpha(math.max(0,math.min(1,tonumber(db.borderAlpha) or .85))); owner.background:Show()
  self:Write(owner,p.root,"width",width+32); self:Write(owner,p.root,"height",height+48)
  self:Write(owner,p.portrait,"alpha",0)
  for _,key in ipairs({"FrameTexture","VehicleFrameTexture","AlternatePowerFrameTexture","BossPortraitFrameTexture"}) do self:Write(owner,p.container[key],"alpha",0) end
  self:Write(owner,p.main.LevelBackgroundCircle,"alpha",0)
  self:Write(owner,p.main.StatusTexture,"alpha",0)
  -- Expand real native bars into the former portrait space. Root anchors, scale,
  -- secure unit button, prediction children and external HUD anchors stay intact.
  self:Write(owner,p.healthContainer,"points",{{"TOPLEFT",p.root,"TOPLEFT",16,-40}})
  self:Write(owner,p.healthContainer,"width",width)
  self:Write(owner,p.health,"points",{{"TOPLEFT",p.healthContainer,"TOPLEFT",0,0}})
  self:Write(owner,p.health,"width",width)
  self:Write(owner,p.healthContainer,"height",healthHeight); self:Write(owner,p.health,"height",healthHeight)
  self:Write(owner,p.power,"points",{{"TOPLEFT",p.healthContainer,"BOTTOMLEFT",0,-gap}})
  self:Write(owner,p.power,"width",width)
  self:Write(owner,p.power,"height",powerHeight)
  self:Write(owner,p.name,"points",{{"TOPLEFT",p.root,"TOPLEFT",20,-26}})
  self:Write(owner,p.name,"width",width-42)
  self:Write(owner,p.level,"points",{{"TOPRIGHT",p.root,"TOPRIGHT",-20,-26}})
  self:Write(owner,p.main.PvpBackgroundCircle,"points",{{"CENTER",p.root,"TOPLEFT",3,-30}})
  if unit=="target" and p.root.TargetFrameContent.TargetFrameContentContextual then
    local context=p.root.TargetFrameContent.TargetFrameContentContextual
    self:Write(owner,context.PvpBackgroundCircle,"points",{{"CENTER",p.root,"TOPLEFT",3,-30}})
    self:Write(owner,context.HighLevelTexture,"points",{{"CENTER",p.level,"CENTER",0,0}})
  end
  if unit=="target" then
    self:Write(owner,p.main.ReputationColor,"points",{{"TOPLEFT",p.root,"TOPLEFT",16,-24}})
    self:Write(owner,p.main.ReputationColor,"width",width)
  end
  self:CompactThreat(owner,p,true)
  -- Masks cover prediction/absorb regions too, so resize them with the bars.
  if p.healthContainer.HealthBarMask then
    self:Write(owner,p.healthContainer.HealthBarMask,"points",{{"TOPLEFT",p.healthContainer,"TOPLEFT",0,0}})
    self:Write(owner,p.healthContainer.HealthBarMask,"width",width)
    self:Write(owner,p.healthContainer.HealthBarMask,"height",healthHeight)
  end
  if p.power.ManaBarMask then
    self:Write(owner,p.power.ManaBarMask,"points",{{"TOPLEFT",p.power,"TOPLEFT",0,0}})
    self:Write(owner,p.power.ManaBarMask,"width",width)
    self:Write(owner,p.power.ManaBarMask,"height",powerHeight)
  end
end
function M:ApplyPowerVisibility(owner,p,unit)
  if combat() then self.pending=true; return end
  local hide=self:IsEnabled() and not editing() and self:GetDB()[unit].showPower==false
  if hide then
    owner.powerOwner=owner.powerOwner or {}
    owner.powerHidden=self:Write(owner.powerOwner,p.power,"alpha",0)==true
    if owner.powerHidden and type(p.power.IsMouseMotionEnabled)=="function" and type(p.power.EnableMouseMotion)=="function" then
      self:Write(owner.powerOwner,p.power,"motion",false)
    end
  else
    if owner.powerOwner then self:Release(owner.powerOwner) end
    owner.powerHidden=false
  end
end
function M:ApplyUnits()
  if self.applyingUnits then return end
  self.applyingUnits=true
  local ok,err=pcall(self.ApplyUnitsNow,self)
  self.applyingUnits=false
  if not ok then error(err,0) end
end
function M:ApplyUnitsNow()
  self.propertyDeferred=false
  self.units=self.units or {}
  for _,unit in ipairs({"player","target"}) do
    local p=self:UnitParts(unit)
    if p then
      local owner=self.units[unit] or {}; self.units[unit]=owner; owner.parts=p
      local compact=self:IsEnabled() and self:GetDB()[unit].compact and not editing()
      self:ApplyCompact(owner,p,unit,compact)
      self:ApplyPowerVisibility(owner,p,unit)
      for _,kind in ipairs({"health","power"}) do
        local bar=p[kind]
        self:UpdateBarText(owner,bar,unit,kind)
        if not bar.khqolBasicTextHook and type(bar.UpdateTextStringWithValues)=="function" then
          bar.khqolBasicTextHook=true
          hooksecurefunc(bar,"UpdateTextStringWithValues",function() M:UpdateBarText(owner,bar,unit,kind) end)
        end
      end
      if not owner.eventHook then
        owner.eventHook=true
        p.root:HookScript("OnEvent",function(_,event)
          if M:IsEnabled() then M:ApplyUnits() end
        end)
        p.root:HookScript("OnShow",function() if M:IsEnabled() then M:ApplyUnits() end end)
      end
    end
  end
end
function M:ApplySettings()
  self:ApplyUnits(); if not combat() and not self.propertyDeferred then self.pending=nil end
end
function M:SetEnabled(on)
  self:Initialize(); self:ApplySettings()
end
function M:Initialize()
  if self.events then return end
  self.events=CreateFrame("Frame")
  for _,event in ipairs({"PLAYER_REGEN_ENABLED","PLAYER_ENTERING_WORLD","PLAYER_TARGET_CHANGED","UNIT_HEALTH","UNIT_MAXHEALTH","UNIT_POWER_UPDATE","UNIT_MAXPOWER","UNIT_DISPLAYPOWER","ADDON_LOADED"}) do pcall(self.events.RegisterEvent,self.events,event) end
  self.events:SetScript("OnEvent",function(_,event,unit)
    if event=="PLAYER_REGEN_ENABLED" or not unit or unit=="player" or unit=="target" or event=="ADDON_LOADED" then M:ApplySettings() end
  end)
  if EditModeManagerFrame then
    EditModeManagerFrame:HookScript("OnShow",function() M:ApplySettings() end)
    EditModeManagerFrame:HookScript("OnHide",function() M:ApplySettings() end)
  end
  if type(PlayerFrame_UpdatePlayerNameTextAnchor)=="function" then
    hooksecurefunc("PlayerFrame_UpdatePlayerNameTextAnchor",function() if M:IsEnabled() then M:ApplyUnits() end end)
  end
  if TargetFrame and type(TargetFrame.CheckClassification)=="function" then
    hooksecurefunc(TargetFrame,"CheckClassification",function() if M:IsEnabled() then M:ApplyUnits() end end)
  end
end
