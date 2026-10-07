local _, KHQOL = ...
local PA=KHQOL.modules.pvpAlert
PA.priority={IDLE=0,WATCHING=1,TARGETED=2,APPROACHING=3,CASTING=4}

function PA:RefreshPlayerName()
  local name=PA.Call(UnitName,"player")
  self.playerName=type(name)=="string" and name or nil
  local realm=PA.Call(GetRealmName)
  self.playerFullName=self.playerName and type(realm)=="string" and self.playerName.."-"..realm:gsub("%s","") or nil
end
function PA:IsTargetingPlayer(enemy)
  return PA.Yes(UnitExists,enemy.targetUnit) and PA.Yes(UnitIsUnit,enemy.targetUnit,"player")
end
function PA:IsCastAtPlayer(enemy)
  local target=PA.Call(UnitSpellTargetName,enemy.unit)
  if type(target)=="string" and target~="" then
    if target==self.playerName or target==self.playerFullName then return true,"direct" end
    -- Explicit contradictory cast target overrides current-target inference.
    return false,"other"
  end
  return self:IsTargetingPlayer(enemy),"target"
end
function PA:ReadCast(enemy,now)
  local cast=enemy.cast
  local previousName,previousStart,previousID=cast.spellName,cast.startTime,cast.castID
  local previouslyActive=cast.active
  cast.active=false
  for mode=1,2 do
    local fn=mode==1 and UnitCastingInfo or UnitChannelInfo
    if type(fn)=="function" then
      local ok,name,_,icon,startMS,endMS,_,arg7,arg8,arg9=pcall(fn,enemy.unit)
      if ok and PA.Readable(name) and type(name)=="string" and name~="" then
        local startTime,endTime=PA.Number(startMS),PA.Number(endMS)
        local atPlayer,evidence=self:IsCastAtPlayer(enemy)
        if atPlayer then
          startTime=startTime and startTime/1000 or nil
          endTime=endTime and endTime/1000 or nil
          if endTime and endTime<=now then return false end
          local castID=mode==1 and PA.Readable(arg7) and arg7 or nil
          if enemy.endedSpell==name and enemy.endedStart==startTime and enemy.endedID==castID then return false end
          cast.spellName=name
          cast.spellID=PA.Number(mode==1 and arg9 or arg8)
          cast.icon=PA.Readable(icon) and (type(icon)=="number" or type(icon)=="string") and icon or "Interface\\Icons\\INV_Misc_QuestionMark"
          cast.startTime=startTime; cast.endTime=endTime; cast.channel=mode==2
          cast.castID=castID
          if not previouslyActive or previousName~=name or previousStart~=startTime or previousID~=cast.castID or not cast.observedStart then cast.observedStart=now end
          cast.timed=startTime~=nil and endTime~=nil and endTime>startTime
          cast.active=true; enemy.castEvidence=evidence
          return true
        end
        return false
      end
    end
  end
  enemy.endedSpell=nil; enemy.endedStart=nil; enemy.endedID=nil
  return false
end
function PA:UpdateEnemy(enemy,now,checkRange)
  local targeting=self:IsTargetingPlayer(enemy)
  if targeting then
    if not enemy.targetStart then
      enemy.targetStart=now; enemy.confirmed=false
      if enemy.state~="CASTING" then self:SetState(enemy,"WATCHING") end
    end
    if not enemy.confirmed and now-enemy.targetStart+1e-6>=self.db.targetConfirmTime then
      enemy.confirmed=true
      if enemy.state~="CASTING" then self:SetState(enemy,"TARGETED") end
    end
  else
    enemy.targetStart=nil; enemy.confirmed=false
    enemy.lastRange=nil; enemy.currentRange=nil; enemy.approachScore=0
  end
  -- Direct spell-target evidence can warn even before target confirmation.
  if self:ReadCast(enemy,now) then self:SetState(enemy,"CASTING"); return end
  enemy.castEvidence=nil
  if not targeting then self:SetState(enemy,"IDLE"); return end
  if not enemy.confirmed then self:SetState(enemy,"WATCHING"); return end
  -- Restore the underlying targeted state after a cast; no range scans during casts.
  local state=enemy.approachScore>=self.db.approachConfirmScore and "APPROACHING" or "TARGETED"
  if checkRange then
    local range=self.Range:GetBucket(enemy.unit)
    enemy.currentRange=range
    if range then
      if enemy.lastRange then
        if range<enemy.lastRange then enemy.approachScore=math.min(enemy.approachScore+1,3)
        elseif range>enemy.lastRange then
          enemy.approachScore=math.max(0,math.min(enemy.approachScore-1,self.db.approachConfirmScore-1))
        end
      end
      enemy.lastRange=range
    else
      -- Do not bridge unreadable samples with invented closeness changes.
      enemy.lastRange=nil; enemy.approachScore=0
    end
    state=enemy.approachScore>=self.db.approachConfirmScore and "APPROACHING" or "TARGETED"
  end
  self:SetState(enemy,state)
end
function PA:IsVisibleThreat(enemy)
  if enemy.state=="CASTING" then return self.db.castingEnabled end
  if enemy.state=="APPROACHING" then return self.db.approachEnabled end
  -- WATCHING is the pending internal state and is never displayed early.
  if enemy.state=="TARGETED" then return self.db.watchingEnabled end
  return false
end
function PA:MoreDangerous(a,b)
  if not b then return true end
  local ap,bp=self.priority[a.state],self.priority[b.state]
  if ap~=bp then return ap>bp end
  if a.state=="CASTING" then
    local at,bt=a.cast.startTime or a.cast.observedStart or 0,b.cast.startTime or b.cast.observedStart or 0
    if at~=bt then return at>bt end
  end
  local ar,br=a.currentRange or 5,b.currentRange or 5
  if ar~=br then return ar<br end
  local at,bt=a.targetStart or math.huge,b.targetStart or math.huge
  if at~=bt then return at<bt end
  return a.order<b.order
end
function PA:SelectThreats()
  for i=1,4 do self.top[i]=nil end
  if not self:CanScan() then return end
  for _,enemy in pairs(self.enemies) do
    if self:IsVisibleThreat(enemy) then
      for i=1,4 do
        if self:MoreDangerous(enemy,self.top[i]) then
          for j=4,i+1,-1 do self.top[j]=self.top[j-1] end
          self.top[i]=enemy; break
        end
      end
    end
  end
end
function PA:AllowEffect(enemy,kind,now)
  local cooldown=kind=="CASTING" and 1 or kind=="APPROACHING" and 4 or 5
  local key=kind=="CASTING" and "casting" or kind=="APPROACHING" and "approaching" or "targeted"
  local last=enemy.lastAlert[key]
  if last and now-last<cooldown then return false end
  enemy.lastAlert[key]=now; return true
end
