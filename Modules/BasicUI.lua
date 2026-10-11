local _, KHQOL = ...
local M={}; KHQOL.modules.basicUI=M
local call,public=KHQOL.PublicCall,KHQOL.IsPublicValue
M.defaults={bags="default",micro="default",hideDelay=.5,
  player={compact=false,health="default",power="default"},
  target={compact=false,health="default",power="default"}}
function M:GetDB()
  KHQOL.db.modules.basicUI=KHQOL.MergeDefaults(KHQOL.db.modules.basicUI or {},self.defaults,"tables")
  return KHQOL.db.modules.basicUI
end
function M:IsEnabled() return KHQOL.db and KHQOL:GetEnabled("basicUI") end
local function points(frame)
  local p={}; for i=1,frame:GetNumPoints() do p[i]={frame:GetPoint(i)} end; return p
end
local function equal(a,b)
  if a==b then return true end
  if type(a)~="table" or type(b)~="table" then return a==b end
  if a.GetObjectType or b.GetObjectType then return false end
  if #a~=#b then return false end
  for i=1,#a do if not equal(a[i],b[i]) then return false end end
  return true
end
local function applyPoints(frame,p)
  frame:ClearAllPoints(); for _,point in ipairs(p) do frame:SetPoint(unpack(point)) end
end
-- Each property has its own live baseline and last written value. External
-- changes become the new baseline; release never overwrites a later mutation.
local getters={alpha=function(f) return f:GetAlpha() end,width=function(f) return f:GetWidth() end,
  height=function(f) return f:GetHeight() end,points=points,mouse=function(f) return f:IsMouseEnabled() end}
local setters={alpha=function(f,v) f:SetAlpha(v) end,width=function(f,v) f:SetWidth(v) end,
  height=function(f,v) f:SetHeight(v) end,points=applyPoints,mouse=function(f,v) f:EnableMouse(v) end}
function M:Write(owner,frame,key,value)
  if not frame then return end
  owner.records=owner.records or {}; owner.records[frame]=owner.records[frame] or {}
  local record=owner.records[frame][key]; local current=getters[key](frame)
  if not record then record={original=current}; owner.records[frame][key]=record
  elseif not equal(current,record.last) then record.original=current end
  if not equal(current,value) then setters[key](frame,value) end
  record.last=getters[key](frame)
end
function M:Release(owner)
  for frame,keys in pairs(owner.records or {}) do
    for key,record in pairs(keys) do
      if equal(getters[key](frame),record.last) then setters[key](frame,record.original) end
    end
  end
  owner.records=nil
end
local function combat() return call(InCombatLockdown)==true end
local function editing() return EditModeManagerFrame and call(EditModeManagerFrame.IsShown,EditModeManagerFrame)==true end
local function cancel(owner)
  if owner.timer then owner.timer:Cancel(); owner.timer=nil end
  owner.generation=(owner.generation or 0)+1
end
function M:FadeBar(owner,hide)
  if combat() then self.pending=true; return end
  if hide then
    self:Write(owner,owner.frame,"alpha",0)
    local function disable(frame)
      if frame.EnableMouse and frame.IsMouseEnabled then M:Write(owner,frame,"mouse",false) end
      for _,child in ipairs({frame:GetChildren()}) do disable(child) end
    end
    disable(owner.frame)
  else self:Release(owner) end
  if owner.sensor then owner.sensor:SetShown(hide and owner.mode=="hover" and owner.frame:IsShown()) end
end
function M:BarEnter(owner)
  if owner.mode~="hover" or not self:IsEnabled() then return end
  cancel(owner); self:FadeBar(owner,false)
end
function M:BarLeave(owner)
  if owner.mode~="hover" or not self:IsEnabled() then return end
  cancel(owner); local generation=owner.generation
  local delay=tonumber(self:GetDB().hideDelay) or .5; delay=math.max(0,math.min(2,delay))
  if C_Timer and C_Timer.NewTimer then
    owner.timer=C_Timer.NewTimer(delay,function()
      owner.timer=nil
      if generation~=owner.generation or owner.mode~="hover" or not M:IsEnabled() then return end
      if call(MouseIsOver,owner.frame)~=true then M:FadeBar(owner,true) end
    end)
  end
end
function M:CreateBar(frame,key)
  if not frame then return end
  self.bars=self.bars or {}; local owner=self.bars[key]
  if owner then return owner end
  owner={frame=frame,key=key}; self.bars[key]=owner
  local sensor=CreateFrame("Frame",nil,UIParent); owner.sensor=sensor
  sensor:SetAllPoints(frame); sensor:SetFrameStrata(frame:GetFrameStrata()); sensor:SetFrameLevel(math.max(1,frame:GetFrameLevel()-1))
  sensor:EnableMouse(true); sensor:Hide()
  sensor:SetScript("OnEnter",function() M:BarEnter(owner) end)
  sensor:SetScript("OnLeave",function() M:BarLeave(owner) end)
  local function hookChildren(f)
    if f.HookScript and f.HasScript and f:HasScript("OnEnter") then
      f:HookScript("OnEnter",function() M:BarEnter(owner) end)
      f:HookScript("OnLeave",function() M:BarLeave(owner) end)
    end
    for _,child in ipairs({f:GetChildren()}) do hookChildren(child) end
  end
  hookChildren(frame)
  frame:HookScript("OnShow",function() if M:IsEnabled() then M:ApplyBars() end end)
  frame:HookScript("OnHide",function() sensor:Hide(); cancel(owner) end)
  return owner
end
function M:ApplyBars()
  if combat() then self.pending=true; return end
  local db=self:GetDB()
  local bags=self:CreateBar(_G.BagsBar,"bags")
  local micro=self:CreateBar(_G.MicroMenu,"micro")
  for _,owner in pairs(self.bars or {}) do
    local mode=self:IsEnabled() and not editing() and db[owner.key] or "default"
    if owner.mode~=mode then cancel(owner); self:Release(owner); owner.mode=mode end
    if mode=="default" then cancel(owner); self:FadeBar(owner,false)
    elseif mode=="hide" then self:FadeBar(owner,true)
    elseif mode=="hover" then
      self:FadeBar(owner,call(MouseIsOver,owner.frame)~=true)
    end
  end
end
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
function M:ApplyCompact(owner,p,unit,on)
  if combat() then self.pending=true; return end
  if not on then
    self:Release(owner); if owner.background then owner.background:Hide() end
    return
  end
  if not owner.background then
    local t=p.root:CreateTexture(nil,"BACKGROUND",nil,-8)
    t:SetColorTexture(.04,.04,.04,.85); t:SetPoint("TOPLEFT",p.root,16,-24); t:SetPoint("BOTTOMRIGHT",p.root,-16,24)
    owner.background=t
  end
  owner.background:Show()
  self:Write(owner,p.portrait,"alpha",0)
  for _,key in ipairs({"FrameTexture","VehicleFrameTexture","AlternatePowerFrameTexture","BossPortraitFrameTexture"}) do self:Write(owner,p.container[key],"alpha",0) end
  self:Write(owner,p.main.LevelBackgroundCircle,"alpha",0)
  -- Expand real native bars into the former portrait space. Root anchors, scale,
  -- secure unit button, prediction children and external HUD anchors stay intact.
  self:Write(owner,p.healthContainer,"points",{{"TOPLEFT",p.root,"TOPLEFT",16,-40}})
  self:Write(owner,p.healthContainer,"width",200)
  self:Write(owner,p.health,"width",200)
  self:Write(owner,p.power,"points",{{"TOPLEFT",p.healthContainer,"BOTTOMLEFT",0,-2}})
  self:Write(owner,p.power,"width",200)
  self:Write(owner,p.name,"points",{{"TOPLEFT",p.root,"TOPLEFT",20,-26}})
  self:Write(owner,p.name,"width",158)
  self:Write(owner,p.level,"points",{{"TOPRIGHT",p.root,"TOPRIGHT",-20,-26}})
  self:Write(owner,p.main.PvpBackgroundCircle,"points",{{"CENTER",p.root,"TOPLEFT",3,-30}})
  if unit=="target" and p.root.TargetFrameContent.TargetFrameContentContextual then
    local context=p.root.TargetFrameContent.TargetFrameContentContextual
    self:Write(owner,context.PvpBackgroundCircle,"points",{{"CENTER",p.root,"TOPLEFT",3,-30}})
    self:Write(owner,context.HighLevelTexture,"points",{{"CENTER",p.level,"CENTER",0,0}})
  end
  if unit=="target" then
    self:Write(owner,p.main.ReputationColor,"points",{{"TOPLEFT",p.root,"TOPLEFT",16,-24}})
    self:Write(owner,p.main.ReputationColor,"width",200)
  end
  -- Masks cover prediction/absorb regions too, so resize them with the bars.
  if p.healthContainer.HealthBarMask then
    self:Write(owner,p.healthContainer.HealthBarMask,"points",{{"TOPLEFT",p.healthContainer,"TOPLEFT",0,0}})
    self:Write(owner,p.healthContainer.HealthBarMask,"width",200)
    self:Write(owner,p.healthContainer.HealthBarMask,"height",20)
  end
  if p.power.ManaBarMask then
    self:Write(owner,p.power.ManaBarMask,"points",{{"TOPLEFT",p.power,"TOPLEFT",0,0}})
    self:Write(owner,p.power.ManaBarMask,"width",200)
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
  if self.applying then return end
  self.applying=true
  self:ApplyBars(); self:ApplyUnits()
  if not combat() then self.pending=nil end
  self.applying=false
end
function M:SetEnabled(on)
  self:Initialize()
  self.events:UnregisterAllEvents()
  for _,event in ipairs({"PLAYER_REGEN_ENABLED","ADDON_LOADED"}) do self.events:RegisterEvent(event) end
  if on then
    for _,event in ipairs({"PLAYER_ENTERING_WORLD","PLAYER_TARGET_CHANGED","UNIT_HEALTH","UNIT_MAXHEALTH","UNIT_POWER_UPDATE","UNIT_MAXPOWER","UNIT_DISPLAYPOWER"}) do pcall(self.events.RegisterEvent,self.events,event) end
  end
  for _,owner in pairs(self.bars or {}) do cancel(owner) end
  self:ApplySettings()
end
function M:Initialize()
  if self.events then return end
  self.events=CreateFrame("Frame")
  for _,event in ipairs({"PLAYER_REGEN_ENABLED","PLAYER_ENTERING_WORLD","PLAYER_TARGET_CHANGED","UNIT_HEALTH","UNIT_MAXHEALTH","UNIT_POWER_UPDATE","UNIT_MAXPOWER","UNIT_DISPLAYPOWER","ADDON_LOADED"}) do pcall(self.events.RegisterEvent,self.events,event) end
  self.events:SetScript("OnEvent",function(_,event,unit)
    if event=="PLAYER_REGEN_ENABLED" then M:ApplySettings()
    elseif M:IsEnabled() and (not unit or unit=="player" or unit=="target" or event=="ADDON_LOADED") then M:ApplySettings() end
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
