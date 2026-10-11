local _, KHQOL = ...
local B=KHQOL.modules.basicUI
local M={Write=B.Write,Release=B.Release}; KHQOL.modules.unitFrames=M
local call,public=KHQOL.PublicCall,KHQOL.IsPublicValue
M.defaults={player={compact=false,health="default",power="default",width=200,height=58},
 target={compact=false,health="default",power="default",width=200,height=58}}
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
function M:IsEnabled() return KHQOL.db and KHQOL:GetEnabled("unitFrames") end
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
function M:FormatValue(unit,kind,mode)
  if mode=="hide" or mode=="default" or call(UnitExists,unit)~=true then return "" end
  local current,maximum
  if kind=="health" then current=call(UnitHealth,unit); maximum=call(UnitHealthMax,unit)
  else
    local powerType=call(UnitPowerType,unit)
    if not valid(powerType) then return "" end
    current=call(UnitPower,unit,powerType); maximum=call(UnitPowerMax,unit,powerType)
  end
  if not valid(current) or not valid(maximum) or maximum<=0 then return "" end
  local value=string.format("%.0f",current); local max=string.format("%.0f",maximum)
  local percent=string.format("%.0f%%",math.min(100,current/maximum*100))
  if mode=="current" then return value elseif mode=="both" then return value.." / "..max
  elseif mode=="percent" then return percent elseif mode=="currentPercent" then return value.." ("..percent..")" end
  return ""
end
function M:UpdateBarText(owner,bar,unit,kind)
  if self.updatingText then return end
  self.updatingText=true
  local mode=self:IsEnabled() and self:GetDB()[unit][kind] or "default"
  owner.textOwners=owner.textOwners or {}; local state=owner.textOwners[kind]
  if not state then
    state={}; owner.textOwners[kind]=state
    local text=bar:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    text:SetPoint("CENTER",bar,"CENTER"); text:SetWidth(bar:GetWidth()); state.text=text
  end
  state.text:Hide()
  if mode=="default" then
    self:Release(state)
  else
    for _,key in ipairs({"TextString","LeftText","RightText","HealthBarText","ManaBarText"}) do
      if bar[key] then self:Write(state,bar[key],"alpha",0) end
    end
    state.text:SetWidth(bar:GetWidth()); state.text:SetText(self:FormatValue(unit,kind,mode)); state.text:Show()
  end
  self.updatingText=false
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
  local width=math.max(120,math.min(400,tonumber(db.width) or 200))
  local height=math.max(44,math.min(120,tonumber(db.height) or 58))
  local healthHeight=math.floor((height-18)*.6); local powerHeight=height-18-healthHeight
  owner.compactWidth,owner.compactHeight=width,height
  if not owner.background then
    local t=p.root:CreateTexture(nil,"BACKGROUND",nil,-8)
    t:SetColorTexture(.04,.04,.04,.85); t:SetPoint("TOPLEFT",p.root,16,-24); t:SetSize(width,height)
    owner.background=t
  end
  owner.background:SetSize(width,height); owner.background:Show()
  self:Write(owner,p.root,"width",width+32); self:Write(owner,p.root,"height",height+48)
  self:Write(owner,p.portrait,"alpha",0)
  for _,key in ipairs({"FrameTexture","VehicleFrameTexture","AlternatePowerFrameTexture","BossPortraitFrameTexture"}) do self:Write(owner,p.container[key],"alpha",0) end
  self:Write(owner,p.main.LevelBackgroundCircle,"alpha",0)
  self:Write(owner,p.main.StatusTexture,"alpha",0)
  -- Expand real native bars into the former portrait space. Root anchors, scale,
  -- secure unit button, prediction children and external HUD anchors stay intact.
  self:Write(owner,p.healthContainer,"points",{{"TOPLEFT",p.root,"TOPLEFT",16,-40}})
  self:Write(owner,p.healthContainer,"width",width)
  self:Write(owner,p.health,"width",width)
  self:Write(owner,p.healthContainer,"height",healthHeight); self:Write(owner,p.health,"height",healthHeight)
  self:Write(owner,p.power,"points",{{"TOPLEFT",p.healthContainer,"BOTTOMLEFT",0,-2}})
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
    self:Write(owner,p.power.ManaBarMask,"height",p.power:GetHeight())
  end
end
function M:ApplyUnits()
  if self.applyingUnits then return end
  self.applyingUnits=true
  self.units=self.units or {}
  for _,unit in ipairs({"player","target"}) do
    local p=self:UnitParts(unit)
    if p then
      local owner=self.units[unit] or {}; self.units[unit]=owner; owner.parts=p
      local compact=self:IsEnabled() and self:GetDB()[unit].compact and not editing()
      self:ApplyCompact(owner,p,unit,compact)
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
  self.applyingUnits=false
end
function M:ApplySettings()
  self:ApplyUnits(); if not combat() then self.pending=nil end
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
