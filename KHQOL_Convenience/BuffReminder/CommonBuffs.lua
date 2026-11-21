local K,F=_G.KHQOL,_G.ForeverBuffReminder
local call,number=K.PublicCall,K.IsPublicNumber
F.commonSpecs={{key="wellFed",id=1249519,name="포만감",icon="Interface\\Icons\\INV_Misc_Food_15"},
  {key="rested",id=429959,name="충분한 휴식",icon=133662}}
function F:InitCommonDefaults()
  for _,token in ipairs(self.CLASS_TOKENS) do
    local data=ForeverBuffReminderDB.classes[token]
    data.common=type(data.common)=="table" and data.common or {}
    K.MergeDefaults(data.common,{wellFed=true,rested=true},"types")
  end
  ForeverBuffReminderDB.sleepingBag=K.MergeDefaults(type(ForeverBuffReminderDB.sleepingBag)=="table" and ForeverBuffReminderDB.sleepingBag or {},
    {enabled=true,placement="BELOW",expiryAlert=true},"types")
  if ForeverBuffReminderDB.sleepingBag.placement~="ABOVE" then ForeverBuffReminderDB.sleepingBag.placement="BELOW" end
  if ForeverBuffReminderDB.food.placement~="BELOW" then ForeverBuffReminderDB.food.placement="ABOVE" end
end
function F:CommonConfig(selected)
  local token=selected and ForeverBuffReminderDB.selectedClass or self:GetCurrentClass()
  local data=ForeverBuffReminderDB.classes[token]
  return data and data.common or {}
end
function F:IsCommonDuplicate(id)
  local cfg=self:CommonConfig()
  if cfg.rested and id==429959 then return true end
  if cfg.wellFed then
    if id==self.observedWellFedID then return true end
    local name=self:GetSpellDetails(id)
    return name=="포만감" or name=="Well Fed"
  end
end
function F:RelevantSpellData(id)
  if not number(id) then return false end
  if self.pendingSpellIDs and self.pendingSpellIDs[id] then return true end
  for _,spec in ipairs(self.commonSpecs) do if spec.id==id then return true end end
  if id==435 then return true end
  for _,token in ipairs({self:GetCurrentClass(),ForeverBuffReminderDB.selectedClass}) do
    local data=ForeverBuffReminderDB.classes[token]
    for _,buff in ipairs(data and data.buffs or {}) do if buff.spellID==id then return true end end
  end
  return self.castRanks and self.castRanks[id]~=nil or false
end
function F:QueueSpellRefresh()
  local generation=K.profileGeneration or 0
  if self.spellRefreshQueued and self.spellRefreshQueued.profile==generation then return end
  local ticket={profile=generation};self.spellRefreshQueued=ticket
  C_Timer.After(.1,function()
    if F.spellRefreshQueued~=ticket then return end
    F.spellRefreshQueued=nil
    if ticket.profile~=(K.profileGeneration or 0) then return end
    F.Food.observation=nil;F.castRanks=nil
    if F.settings and F.settings:IsVisible() then F:RefreshSettings() end
    F:RefreshAlerts()
  end)
end
function F:SyncCommon()
  if self.testMode and self.Sleep then self.Sleep:HideExpiry() end
  local enabled=K:GetEnabled("buffReminder") and self:CommonConfig().rested and ForeverBuffReminderDB.sleepingBag.enabled
  if not self.bedEvents then
    self.bedEvents=CreateFrame("Frame")
    self.bedEvents:SetScript("OnEvent",function(_,event)
      if F.Sleep and (event=="PLAYER_STARTED_MOVING" or event=="PLAYER_STOPPED_MOVING") then
        F.Sleep:Movement(event=="PLAYER_STARTED_MOVING");F:RefreshAlerts();return
      end
      if F.bedQueued then return end
      F.bedQueued=true
      C_Timer.After(.1,function()
        F.bedQueued=nil;F.bedStock=nil
        if K:GetEnabled("buffReminder") then F:RefreshAlerts() end
      end)
    end)
  end
  if enabled then
    self.bedEvents:RegisterEvent("BAG_UPDATE_DELAYED");self.bedEvents:RegisterEvent("ITEM_LOCK_CHANGED")
    if self.bedProfile~=K.profileGeneration then self.bedStock=nil;self.bedProfile=K.profileGeneration end
    if not self.bedStock then
      local count,usable=self.Food:Stock(211527)
      self.bedStock={count=count,usable=usable}
    end
  else self.bedEvents:UnregisterAllEvents();self.bedStock=nil end
  if self.Sleep and self.Sleep:Enabled() then
    self.bedEvents:RegisterEvent("PLAYER_STARTED_MOVING");self.bedEvents:RegisterEvent("PLAYER_STOPPED_MOVING")
  end
end
function F:StopCommon()
  if self.bedEvents then self.bedEvents:UnregisterAllEvents() end
  self.bedStock=nil
  if self.Sleep then self.Sleep:Stop() end
end
function F:AppendCommonAlerts(alerts,food,batch,schedule)
  local common=self:CommonConfig()
  local resting=batch[1331671] and batch[1331671].state=="ACTIVE"
  local restCount=self.Sleep and self.Sleep:ReadCount(batch)
  -- UNKNOWN is not evidence of absence. Combat can make an existing aura unreadable.
  local rested=batch[429959]
  local showBed=call(InCombatLockdown)==false and call(UnitAffectingCombat,"player")==false
    and rested and rested.state=="MISSING" and restCount==0
  local fed=common.wellFed and self.Food:ReadObservation().fed
  if fed and fed.state=="ACTIVE" then
    self.observedWellFedID=fed.id
    if number(fed.icon) or type(fed.icon)=="string" then self.observedWellFedIcon=fed.icon end
  end
  local function append(spec,observed)
    if not common[spec.key] or not observed then return end
    local state,remaining=observed.state,nil
    if spec.key=="rested" then
      if not showBed then return end
      state=resting and "RESTING" or "MISSING"
    elseif state=="ACTIVE" then
      if number(observed.expirationTime) and observed.expirationTime>0 then
        local now=call(GetTime);if not number(now) then return end
        remaining=observed.expirationTime-now
        if remaining<=0 then return end
        if remaining<=self:GetThreshold() then state="EXPIRING";schedule(.5)
        else schedule(remaining-self:GetThreshold());return end
      else return end
    end
    if state~="MISSING" and state~="EXPIRING" and state~="RESTING" and state~="PENDING" then return end
    local _,icon=self:GetSpellDetails(spec.id)
    if spec.key=="wellFed" then
      local name=self:GetSpellDetails(spec.id)
      icon=self.observedWellFedIcon or ((name=="포만감" or name=="Well Fed") and icon or nil)
    end
    local alert={key="common."..spec.key,state=state,remaining=remaining,name=spec.name,icon=icon or spec.icon,noGlow=spec.key=="rested",muted=state=="PENDING"}
    if spec.key=="wellFed" and food then alert.progress=food.progress;food.progress=nil end
    alerts[#alerts+1]=alert
  end
  append(self.commonSpecs[1],fed)
  append(self.commonSpecs[2],batch[429959])
  if food then
    food.utility=true;food.utilityOf="common.wellFed";food.placement=ForeverBuffReminderDB.food.placement
    alerts[#alerts+1]=food
  end
  local stock=self.bedStock
  if common.rested and showBed and stock and stock.count>0 then
    alerts[#alerts+1]={key="sleepingBag",state=resting and "RESTING" or "MISSING",name="아늑한 침낭",icon=133662,noGlow=true,
      item=not resting and stock.usable and 211527 or nil,castUnit="player",utility=true,utilityOf="common.rested",placement=ForeverBuffReminderDB.sleepingBag.placement}
  end
end
function F:BuildCommonSettings(b)
  for _,spec in ipairs(self.commonSpecs) do
    local key=spec.key
    local title=key=="wellFed" and "포만감 (처치 5%)" or "침낭 버프"
    local get=function() return self:CommonConfig(true)[key] end
    local c=b:Checkbox(title,get,function(v)
      self:CommonConfig(true)[key]=v;self:RefreshAlerts()
    end)
    c.khqolStaticSetting=true;K.UsageDiagnostics:Bind(c,title,get)
  end
end
function F:BuildBedSettings(b)
  b:Section("충분한 휴식·침낭")
  b:Checkbox("침낭 버프 만료 알림",function() return ForeverBuffReminderDB.sleepingBag.expiryAlert end,function(v)
    ForeverBuffReminderDB.sleepingBag.expiryAlert=v;self:RefreshAlerts()
  end)
  b:Description("충분한 휴식의 남은 시간을 확인할 수 있을 때 만료 2분 전 한 번 메시지를 표시합니다. 침낭 아이콘 사용과 별개로 동작합니다.")
  b:Checkbox("침낭 아이콘 사용",function() return ForeverBuffReminderDB.sleepingBag.enabled end,function(v)
    ForeverBuffReminderDB.sleepingBag.enabled=v;self:RefreshAlerts()
  end)
  b:Dropdown("침낭 아이콘 위치",{{value="ABOVE",text="충분한 휴식 위"},{value="BELOW",text="충분한 휴식 아래"}},
    function() return ForeverBuffReminderDB.sleepingBag.placement end,function(v)
      ForeverBuffReminderDB.sleepingBag.placement=v;self:RefreshAlerts()
    end)
  b:Description("비전투 중 충분한 휴식이 없다고 확인되고 침낭을 보유하면 아이콘을 표시합니다. 잠긴 아이콘을 클릭하면 현재 위치에 설치합니다. 버프 보유·확인 불가·전투 중에는 침낭 아이콘을 숨깁니다. 휴식 진행은 1분 구간 3개로 표시하며 추정 시간은 약으로 구분합니다.",true)
end
