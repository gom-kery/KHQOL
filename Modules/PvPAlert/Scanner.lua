local _, KHQOL = ...
local PA=KHQOL.modules.pvpAlert

function PA:IsEnemyPlayer(unit)
  if not PA.Yes(UnitExists,unit) or not PA.Yes(UnitIsPlayer,unit) or not PA.Yes(UnitCanAttack,"player",unit) then return false end
  if PA.Yes(UnitIsDeadOrGhost,unit) then return false end
  -- UnitCanAttack alone includes attackable neutral players. Reject known neutrals.
  local reaction=PA.Number(PA.Call(UnitReaction,unit,"player"))
  if reaction and reaction>=4 then return false end
  return true
end
function PA:RemoveUnit(unit)
  self.pending[unit]=nil
  local guid=self.unitGUIDs[unit]
  self.unitGUIDs[unit]=nil
  if guid then
    local enemy=self.enemies[guid]
    if enemy and enemy.unit==unit then
      -- Retain effect cooldowns briefly across plate visibility churn, by GUID.
      self.cooldowns[guid]={lastAlert=enemy.lastAlert, expires=PA.Now()+30}
      self.enemies[guid]=nil
    end
  end
end
function PA:AddUnit(unit,retry)
  if not self:IsEnabled() or type(unit)~="string" or not unit:match("^nameplate%d+$") then return end
  local guid=PA.Call(UnitGUID,unit)
  local old=self.unitGUIDs[unit]
  if old and old~=guid then self:RemoveUnit(unit) end
  if not PA.Yes(UnitExists,unit) or type(guid)~="string" or guid=="" then
    -- Forever can announce a plate before populating its unit. Bounded retries.
    if not retry then self.pending[unit]=PA.Now()+2 end
    return
  end
  if not self:IsEnemyPlayer(unit) then
    if PA.Call(UnitIsPlayer,unit)==nil or PA.Call(UnitCanAttack,"player",unit)==nil then
      if not retry then self.pending[unit]=PA.Now()+2 end
    else self.pending[unit]=nil end
    return
  end
  self.pending[unit]=nil
  local enemy=self.enemies[guid]
  if enemy then
    if enemy.unit~=unit then self.unitGUIDs[enemy.unit]=nil end
    enemy.unit=unit; enemy.targetUnit=unit.."target"
  else
    self.sequence=self.sequence+1
    local previous=self.cooldowns[guid]
    enemy={guid=guid,unit=unit,targetUnit=unit.."target",state="IDLE",order=self.sequence,
      confirmed=false,approachScore=0,cast={},lastAlert=previous and previous.lastAlert or {}}
    self.cooldowns[guid]=nil; self.enemies[guid]=enemy
  end
  enemy.name=PA.Call(UnitName,unit) or enemy.name or "Unknown"
  self.unitGUIDs[unit]=guid
end
function PA:ValidateEnemy(guid,enemy)
  if PA.Call(UnitGUID,enemy.unit)~=guid or not self:IsEnemyPlayer(enemy.unit) then
    local unit=enemy.unit
    self:RemoveUnit(unit)
    if PA.Yes(UnitExists,unit) then self.pending[unit]=PA.Now()+2 end
    return false
  end
  return true
end
function PA:ClearScanner()
  for unit in pairs(self.unitGUIDs) do self:RemoveUnit(unit) end
  for unit in pairs(self.pending) do self.pending[unit]=nil end
  self:RefreshLoop()
end
function PA:PrimeNameplates()
  if not self:IsEnabled() then return end
  local plates=PA.Call(C_NamePlate and C_NamePlate.GetNamePlates)
  if type(plates)=="table" then
    for _,plate in ipairs(plates) do
      if PA.Readable(plate) and type(plate)=="table" then
        local unit=plate.namePlateUnitToken
        if PA.Readable(unit) then self:AddUnit(unit) end
      end
    end
  end
  -- Some Forever plates do not carry namePlateUnitToken. Only at enable/world entry.
  for index=1,100 do
    local unit="nameplate"..index
    if PA.Yes(UnitExists,unit) then self:AddUnit(unit) end
  end
end
function PA:Scan()
  if not self:CanScan() then self:RefreshActivity(); return end
  local now=PA.Now()
  for unit,expires in pairs(self.pending) do
    self:AddUnit(unit,true)
    if now>=expires then self.pending[unit]=nil end
  end
  for guid,enemy in pairs(self.enemies) do
    if self:ValidateEnemy(guid,enemy) then self:UpdateEnemy(enemy,now,true) end
  end
  -- A bounded visibility cooldown cache expires even if no enemy returns.
  for guid,entry in pairs(self.cooldowns) do if now>=entry.expires then self.cooldowns[guid]=nil end end
  self:SelectThreats(); self:RenderThreats(); self:RefreshLoop()
end
local stopEvents={UNIT_SPELLCAST_STOP=true,UNIT_SPELLCAST_FAILED=true,UNIT_SPELLCAST_INTERRUPTED=true,UNIT_SPELLCAST_CHANNEL_STOP=true}
function PA:OnEvent(event,unit,castID)
  if not PA.Readable(unit) then return end
  if event=="PLAYER_LEAVING_WORLD" then
    self.inWorld=false; self:StopTest(); self:SetMoving(false); self:ClearScanner(); self:RefreshActivity(); return
  elseif event=="PLAYER_ENTERING_WORLD" then
    self.inWorld=true; self.combat=PA.Yes(UnitAffectingCombat,"player")
    self:RefreshPlayerName(); self:ClearScanner(); self:PrimeNameplates(); self:RefreshActivity(); return
  elseif event=="PLAYER_REGEN_DISABLED" or event=="PLAYER_REGEN_ENABLED" then
    self.combat=event=="PLAYER_REGEN_DISABLED"
    if self.combat then self:StopTest(); self:SetMoving(false) end
    self:RefreshActivity(); return
  elseif event=="SPELLS_CHANGED" or event=="PLAYER_LEVEL_UP" then
    self.Range:Rebuild()
    -- Provider boundaries changed: never compare samples from different providers.
    for _,enemy in pairs(self.enemies) do enemy.lastRange=nil; enemy.currentRange=nil; enemy.approachScore=0 end
    self:RefreshActivity(); return
  end
  if type(unit)~="string" then return end
  if event=="NAME_PLATE_UNIT_REMOVED" then
    self:RemoveUnit(unit)
    if not self.testing then self:SelectThreats(); self:RenderThreats() end
    self:RefreshLoop(); return
  elseif event=="NAME_PLATE_UNIT_ADDED" then
    self:AddUnit(unit); self:RefreshLoop()
  elseif event=="UNIT_FACTION" or event=="UNIT_FLAGS" then
    self:AddUnit(unit); self:RefreshLoop()
  end
  if not self:CanScan() then return end
  local guid=self.unitGUIDs[unit]
  local enemy=guid and self.enemies[guid]
  if not enemy or not self:ValidateEnemy(guid,enemy) then return end
  if event=="UNIT_NAME_UPDATE" then enemy.name=PA.Call(UnitName,unit) or enemy.name end
  if stopEvents[event] and enemy.cast.active then
    -- Ignore stale stop events for an earlier cast when an ID is supplied.
    if not PA.Readable(castID) or castID==nil or enemy.cast.castID==nil or castID==enemy.cast.castID then
      enemy.endedSpell=enemy.cast.spellName; enemy.endedStart=enemy.cast.startTime; enemy.endedID=enemy.cast.castID
    end
  elseif event=="UNIT_SPELLCAST_START" or event=="UNIT_SPELLCAST_CHANNEL_START" then
    enemy.endedSpell=nil; enemy.endedStart=nil; enemy.endedID=nil
  end
  self:UpdateEnemy(enemy,PA.Now(),false) -- events never trigger extra range probes
  self:SelectThreats(); self:RenderThreats(); self:RefreshLoop()
end
