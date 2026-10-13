local _, KHQOL = ...
local PA = KHQOL.modules.pvpAlert
PA.VERSION = "0.1"
PA.UPDATE_INTERVAL = .20
PA.SECONDARY_LIMIT = 3
PA.defaults = {
  enabled=true, onlyOutOfCombat=true,
  watchingEnabled=true, watchingSound=false, targetConfirmTime=.4,
  approachEnabled=true, approachSound=true, approachPulse=true, approachConfirmScore=2,
  castingEnabled=true, castingSound=true, showSpellIcon=true, showCastBar=true, showCastTime=true,
  scale=1, alpha=1, point="CENTER", relativePoint="CENTER", x=0, y=165, debug=false,
}
PA.enemies, PA.unitGUIDs, PA.pending, PA.cooldowns = {}, {}, {}, {}
PA.top = {} -- bounded, reusable selection buffer (primary + three secondary)
PA.sequence = 0
local points = {CENTER=true, TOP=true, BOTTOM=true, LEFT=true, RIGHT=true,
  TOPLEFT=true, TOPRIGHT=true, BOTTOMLEFT=true, BOTTOMRIGHT=true}

function PA.Readable(value)
  return not (type(issecretvalue)=="function" and issecretvalue(value))
end
function PA.Number(value)
  if PA.Readable(value) and type(value)=="number" and value==value and value~=math.huge and value~=-math.huge then return value end
end
-- Capability checks also protect against Forever builds returning restricted data.
function PA.Call(fn, ...)
  if type(fn)~="function" then return nil end
  local ok, value = pcall(fn, ...)
  if ok and PA.Readable(value) then return value end
end
function PA.Yes(fn, ...)
  local value=PA.Call(fn, ...)
  return value==true or value==1
end
function PA.Now() return PA.Number(PA.Call(GetTime)) or 0 end

function PA:GetDB()
  local db=KHQOL.db.modules.pvpAlert
  if type(db)~="table" then db={}; KHQOL.db.modules.pvpAlert=db end
  KHQOL.MergeDefaults(db,self.defaults,"types")
  local function clamp(key,lo,hi)
    db[key]=math.max(lo,math.min(hi,PA.Number(db[key]) or self.defaults[key]))
  end
  clamp("targetConfirmTime",.1,2); clamp("approachConfirmScore",1,3)
  db.approachConfirmScore=math.floor(db.approachConfirmScore+.5)
  clamp("scale",.5,2); clamp("alpha",.1,1); clamp("x",-5000,5000); clamp("y",-5000,5000)
  if not points[db.point] then db.point="CENTER" end
  if not points[db.relativePoint] then db.relativePoint="CENTER" end
  -- KHQOL's common module switch is authoritative. Mirror it for a complete DB.
  db.enabled=KHQOL:GetEnabled("pvpAlert")
  self.db=db; return db
end
function PA:IsEnabled()
  return KHQOL.db and KHQOL:GetEnabled("pvpAlert") and self.db and self.db.enabled
end
function PA:CanScan()
  if not self:IsEnabled() or self.inWorld==false or self.testing then return false end
  if self.db.onlyOutOfCombat then
    local combat=PA.Call(UnitAffectingCombat,"player")
    if self.combat or combat==true or combat==1 or combat==nil then return false end
  end
  return true
end
function PA:Print(message)
  if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffffd54a[PvPAlert]|r "..message) end
end
function PA:SetState(enemy,state)
  if enemy.state==state then return end
  if self.db.debug then
    self:Print((enemy.name or "Unknown").." "..enemy.state.." → "..state..
      (state=="CASTING" and enemy.cast.spellName and " | Spell: "..enemy.cast.spellName or ""))
  end
  enemy.state=state
end
function PA:ResetEnemy(enemy)
  enemy.targetStart=nil; enemy.confirmed=false
  enemy.lastRange=nil; enemy.currentRange=nil; enemy.approachScore=0
  enemy.cast.active=false; enemy.castEvidence=nil
  self:SetState(enemy,"IDLE")
end
function PA:ClearThreats()
  for _,enemy in pairs(self.enemies) do self:ResetEnemy(enemy) end
  for i=1,4 do self.top[i]=nil end
end
function PA:RefreshLoop()
  local run=self:CanScan() and (next(self.enemies)~=nil or next(self.pending)~=nil)
  if run then
    if not self.loopRunning then
      self.loopRunning=true; self.elapsed=0
      self.events:SetScript("OnUpdate",self.scanCallback)
    end
  else
    self.loopRunning=false; self.events:SetScript("OnUpdate",nil)
  end
end
function PA:RefreshActivity()
  if not self:CanScan() then
    self:ClearThreats()
    if not self.testing and not self.moving then self:HideAlerts(true) end
  end
  self:RefreshLoop()
  if self:CanScan() then self:Scan() end
end
function PA:Changed()
  self:GetDB(); self:ApplyLayout()
  self.displayState=nil -- rebuild presentation when options change in place
  if self.testing then self:RenderTest(true,true) else self:RefreshActivity() end
  if self.settingsContent then KHQOL.UI:Refresh(self.settingsContent) end
end
function PA:SetEnabled(enabled)
  if not self.initialized then self:Initialize() end
  self.db.enabled=enabled and true or false
  if not enabled then
    self:StopTest(); self:SetMoving(false); self:ClearScanner(); self:HideAlerts(true)
  else self:PrimeNameplates() end
  self:RefreshActivity()
end
function PA:Initialize()
  if self.initialized then return end
  self.initialized=true; self.inWorld=true; self:GetDB()
  self:RefreshPlayerName(); self.Range:Rebuild(); self:CreateAlerts(); self:ApplyLayout()
  self.combat=PA.Yes(UnitAffectingCombat,"player")
  self.events=CreateFrame("Frame")
  self.scanCallback=function(_,dt)
    self.elapsed=self.elapsed+dt
    if self.elapsed<self.UPDATE_INTERVAL then return end
    self.elapsed=self.elapsed % self.UPDATE_INTERVAL -- no catch-up burst after a hitch
    self:Scan()
  end
  self.unsupportedEvents={}
  for _,event in ipairs({"NAME_PLATE_UNIT_ADDED","NAME_PLATE_UNIT_REMOVED",
    "PLAYER_ENTERING_WORLD","PLAYER_LEAVING_WORLD","PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED",
    "UNIT_TARGET","UNIT_FACTION","UNIT_FLAGS","UNIT_NAME_UPDATE","SPELLS_CHANGED","PLAYER_LEVEL_UP",
    "UNIT_SPELLCAST_START","UNIT_SPELLCAST_STOP","UNIT_SPELLCAST_FAILED","UNIT_SPELLCAST_INTERRUPTED",
    "UNIT_SPELLCAST_DELAYED","UNIT_SPELLCAST_SUCCEEDED","UNIT_SPELLCAST_CHANNEL_START",
    "UNIT_SPELLCAST_CHANNEL_UPDATE","UNIT_SPELLCAST_CHANNEL_STOP"}) do
    if not pcall(self.events.RegisterEvent,self.events,event) then self.unsupportedEvents[#self.unsupportedEvents+1]=event end
  end
  self.events:SetScript("OnEvent",function(_,event,unit,castID) self:OnEvent(event,unit,castID) end)
end
