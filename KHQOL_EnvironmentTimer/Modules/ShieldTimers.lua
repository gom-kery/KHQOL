local K=_G.KHQOL
local E=K.modules.environmentTimer
local call,number=K.PublicCall,K.IsPublicNumber
E.shieldSpecs={{key="SHIELD_PRIEST",spell=17,title="사제 보호막"},{key="SHIELD_MANA",spell=1463,title="마나 보호막"},
  {key="SHIELD_ICE",spell=11426,title="얼음 보호막"},{key="SHIELD_SACRIFICE",spell=7812,title="희생 보호막"}}
E.shieldKeys={};E.defaults.shieldTimers=false;E.defaults.shieldAbsorb=true
for _,spec in ipairs(E.shieldSpecs) do
  E.shieldKeys[spec.key]=true;E.order[#E.order+1]=spec.key;E.names[spec.key]=spec.title;E.defaults.timers[spec.key]=true
end
function E:TimerEnabled(timer)
  return self.db.timers[timer]==true and (not self.shieldKeys[timer] or self.db.shieldTimers==true
    and (self.db.shieldCombat or call(InCombatLockdown)==false))
end
function E:SyncShieldEvents()
  local enabled=self:IsEnabled() and self.db.shieldTimers
  for _,event in ipairs({"UNIT_AURA","UNIT_ABSORB_AMOUNT_CHANGED","PLAYER_DEAD","PLAYER_ALIVE","SPELL_DATA_LOAD_RESULT"}) do
    if enabled then call(self.events.RegisterEvent,self.events,event) else self.events:UnregisterEvent(event) end
  end
end
function E:ClearShields()
  for key in pairs(self.shieldKeys) do self.active[key]=nil end
end
function E:ShieldAmounts()
  local total=self.db.shieldAbsorb and call(UnitGetTotalAbsorbs,"player")
  local label=number(total) and total>=0 and ("전체 흡수 "..tostring(math.floor(total+.5))) or "전체 흡수 -"
  local first=true
  for _,spec in ipairs(self.shieldSpecs) do
    local data=self.active[spec.key]
    if data then
      -- UnitGetTotalAbsorbs is a sum, never pretend it is a per-spell value.
      data.absorbText=self.db.shieldAbsorb and first and label or nil;first=false
    end
  end
end
function E:RefreshShields()
  self:SyncShieldEvents()
  if not self:IsEnabled() or not self.db.shieldTimers or call(UnitIsDeadOrGhost,"player")==true then self:ClearShields();return end
  local registered={}
  for _,spec in ipairs(self.shieldSpecs) do registered[spec.spell]={name=K:GetSpellDetails(spec.spell)} end
  local observations=K.AuraReader:ReadNamed(registered);local now=call(GetTime)
  if not number(now) then self:ClearShields();self.shieldUnavailable=true;return end
  self.shieldUnavailable=nil
  local found={}
  for _,spec in ipairs(self.shieldSpecs) do
    local a=observations[spec.spell]
    if self.db.timers[spec.key] then
      if a and a.state=="ACTIVE" then
        if number(a.duration) and a.duration>0
          and number(a.expirationTime) and a.expirationTime>now then
          local remaining=(a.expirationTime-now)*1000
          found[spec.key]={source="aura",label=registered[spec.spell].name or spec.title,value=remaining,maximum=a.duration*1000,
            expires=a.expirationTime,rate=-1,ready=true,noWarnings=true,state="NORMAL"}
        end
      elseif not a or a.state=="UNKNOWN" then self.shieldUnavailable=true end
    end
  end
  self:ClearShields();for key,data in pairs(found) do self.active[key]=data end
  self:ShieldAmounts()
end
