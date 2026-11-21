local K=_G.KHQOL
local X=K.modules.experienceBar
local P={entries={},blocked={},revision=0}
X.questPreview=P
local call,public=K.PublicCall,K.IsPublicValue
local function number(v) return K.IsPublicNumber(v) end
local function id(v) return number(v) and v>0 and v%1==0 end
local function xp(v) return number(v) and v>=0 and v%1==0 and v<=1000000000 end
function P:Supported()
  local q=C_QuestLog
  return q and type(q.GetNumQuestLogEntries)=="function" and type(q.GetInfo)=="function"
    and type(q.IsOnQuest)=="function" and type(q.IsComplete)=="function"
    and type(q.IsQuestFlaggedCompleted)=="function" and type(q.IsRepeatableQuest)=="function"
    and type(GetQuestLogRewardXP)=="function" and C_Timer and type(C_Timer.After)=="function"
end
function P:Hide()
  for _,segment in ipairs(X.segments or {}) do if segment.questXP then segment.questXP:Hide() end end
end
function P:Sum()
  local total,count=0,0
  for questID,value in pairs(self.entries) do
    if not self.blocked[questID] then total=total+value;count=count+1 end
  end
  self.total,self.count=total,count
end
function P:Collect(allowSync)
  if not self.active then return end
  local q=C_QuestLog
  local count=call(q.GetNumQuestLogEntries)
  if not number(count) or count<0 or count>1000 or count%1~=0 then
    self.entries={};self.valid=false;self.status="퀘스트 로그를 확인할 수 없습니다.";self:Hide();return
  end
  local startXP,startLevel=call(UnitXP,"player"),call(UnitLevel,"player")
  local revision=self.revision
  local candidates,entries={},{}
  local function track(info,expectedID)
    if type(info)~="table" then return end
    local status,questID,header,task,bounty,hidden,internal=K.ReadPublicAPI(function()
      return info.questID,info.isHeader,info.isTask,info.isBounty,info.isHidden,info.isInternalOnly
    end)
    if status=="ok" and id(questID) and (not expectedID or questID==expectedID) then
      candidates[questID]=header==false and task~=true and bounty~=true and hidden~=true and internal~=true
    end
  end
  for index=1,count do track(call(q.GetInfo,index)) end
  -- Collapsed headers can hide log rows. Keep confirmed ordinary quest IDs
  -- and consult the watch list without changing the player's log selection.
  for questID in pairs(self.known) do
    if candidates[questID]==nil then candidates[questID]=true end
  end
  local watches=call(q.GetNumQuestWatches)
  if number(watches) and watches>=0 and watches<=1000 and watches%1==0 then
    for index=1,watches do
      local questID=call(q.GetQuestIDForQuestWatchIndex,index)
      if id(questID) and candidates[questID]==nil then
        local logIndex=call(q.GetLogIndexForQuestID,questID)
        if id(logIndex) then track(call(q.GetInfo,logIndex),questID) end
        if candidates[questID]==nil and call(q.IsQuestTask,questID)==false
          and call(q.IsQuestBounty,questID)==false and call(q.IsWorldQuest,questID)==false then
          candidates[questID]=true
        end
      end
    end
  end
  local known={}
  for questID,eligible in pairs(candidates) do
    if eligible and call(q.IsOnQuest,questID)==true then
      known[questID]=true
      -- Match the stock tracker even when ReadyForTurnIn has not updated.
      if not self.blocked[questID] and call(q.IsComplete,questID)==true then
        local rewarded=call(q.IsQuestFlaggedCompleted,questID)
        if rewarded==false or (rewarded==true and call(q.IsRepeatableQuest,questID)==true) then
          local reward=call(GetQuestLogRewardXP,questID)
          if xp(reward) and reward>0 then
            entries[questID]=reward
          elseif not self.requested[questID] and type(q.RequestLoadQuestByID)=="function" then
            self.requested[questID]=true
            call(q.RequestLoadQuestByID,questID)
          end
        end
      end
    end
  end
  local endXP,endLevel=call(UnitXP,"player"),call(UnitLevel,"player")
  local failed=not xp(startXP) or not id(startLevel) or startXP~=endXP or startLevel~=endLevel or revision~=self.revision
  if not failed then self.known=known;self.entries=entries;self:Sum() end
  self.valid=not failed
  if failed and allowSync and self.queued then self.allowSync=true end
  if allowSync and not failed then
    self.awaitLog=false;self.ambiguous=nil;self.syncedXP=endXP;self.syncedLevel=endLevel
  end
  self.status=failed and "퀘스트 로그가 변경되어 경험치 미리보기를 다시 확인합니다."
    or self.awaitLog and "경험치 변경 후 퀘스트 로그 동기화를 기다립니다."
    or ("완료·미반납 "..self.count.."개 · 예상 +"..X:FormatNumber(self.total).." XP")
  if not self.valid or self.awaitLog then self:Hide() end
end
function P:Queue(allowSync)
  if not self.active then return end
  self.allowSync=self.allowSync or allowSync
  if self.queued then return end
  local ticket={};self.queued=ticket
  C_Timer.After(0,function()
    if P.queued~=ticket or not P.active then return end
    P.queued=nil;local sync=P.allowSync;P.allowSync=nil
    local ok=pcall(P.Collect,P,sync)
    if not ok then P.valid=false;P.status="퀘스트 보상 조회 실패 · 미리보기 보류";P:Hide() end
    X:Update()
  end)
end
function P:ObserveXP(data,newLevel)
  if not self.active or not data or data.kind~="experience" then return end
  if (public(newLevel) and number(newLevel)) or (self.lastLevel and self.lastLevel~=data.level) then
    self.awaitLog=true;self.valid=false;self.status="레벨 변경 후 퀘스트 보상을 다시 확인합니다.";self:Hide()
    self:QueueXPRefresh()
  elseif self.lastXP and data.value~=self.lastXP then
    if self.syncedXP~=data.value or self.syncedLevel~=data.level then
      -- XP arrives before the turn-in event on some paths. Quarantine a
      -- matching reward while leaving unrelated completed quests visible.
      local gain=data.value-self.lastXP
      if self.dialog then self.awaitLog=true
      elseif gain>0 then
        for questID,reward in pairs(self.entries) do
          if reward==gain then
            self.ambiguous=self.ambiguous or {}
            self.ambiguous[questID]=true
          end
        end
      end
      self:QueueXPRefresh()
    end
  end
  self.lastXP,self.lastLevel=data.value,data.level
end
function P:QueueXPRefresh()
  if self.xpRefresh then return end
  local ticket={};self.xpRefresh=ticket
  C_Timer.After(.25,function()
    if P.xpRefresh~=ticket or not P.active then return end
    P.xpRefresh=nil
    P:Queue(true)
  end)
end
function P:Amount(data)
  local rewardPanel=QuestFrameRewardPanel
  if not self.active or not self.valid or self.awaitLog
    or (self.dialog and call(rewardPanel and rewardPanel.IsVisible,rewardPanel)~=false)
    or not data or data.kind~="experience"
    or data.atCap or not number(data.maximum) or data.maximum<=0 then return 0 end
  local amount=self.total or 0
  for questID in pairs(self.ambiguous or {}) do amount=amount-(self.entries[questID] or 0) end
  return amount
end
function P:Text(base,data)
  local amount=self:Amount(data)
  if amount<=0 then return base end
  if X.db.showQuestPreview then base=base..(base~="" and " " or "").."(+"..X:FormatNumber(amount).." 예상)" end
  if X.db.showQuestLevelPrediction and amount>=data.remaining then base=base.." · 레벨업 예상" end
  return base
end
function P:OnEvent(event,questID,second)
  if not self.active then return end
  self.revision=self.revision+1
  if event=="QUEST_TURNED_IN" or event=="QUEST_REMOVED" then
    if id(questID) then
      self.blocked[questID]=true;self.entries[questID]=nil;self.known[questID]=nil;self.requested[questID]=nil;self:Sum()
    end
    self.status="퀘스트 반납/제거 후 로그 동기화 대기"
    self:QueueXPRefresh();X:Render()
  elseif event=="QUEST_COMPLETE" then
    self.dialog=true;self.dialogXP=call(UnitXP,"player");self.dialogLevel=call(UnitLevel,"player")
    self:Hide();X:Render()
  elseif event=="QUEST_FINISHED" then
    local unchanged=self.dialog and self.dialogXP==call(UnitXP,"player") and self.dialogLevel==call(UnitLevel,"player")
    self.dialog=nil;self:Queue(unchanged)
  elseif event=="QUEST_ACCEPTED" then
    local accepted=id(second) and second or questID
    if id(accepted) and call(C_QuestLog.IsOnQuest,accepted)==true then
      self.blocked[accepted]=nil;self.requested[accepted]=nil
    end
    self:Queue(false)
  elseif event=="QUEST_LOG_UPDATE" or event=="PLAYER_ENTERING_WORLD" then
    self:Queue(true)
  else self:Queue(false) end
end
function P:Configure()
  local db=X.db
  local wanted=X:IsEnabled() and db.showQuestPreview==true
  local supported=self:Supported()
  if self.active and wanted and supported and self.configDB==db and self.generation==K.profileGeneration then return end
  self.active=false;self.queued=nil;self.allowSync=nil;self:Hide()
  self.xpRefresh=nil;self.known={};self.requested={}
  if self.events then self.events:UnregisterAllEvents() end
  self.entries={};self.total=0;self.count=0;self.valid=false;self.awaitLog=false;self.dialog=nil;self.ambiguous=nil
  self.lastXP,self.lastLevel=nil,nil;self.syncedXP,self.syncedLevel=nil,nil
  self.configDB=db;self.generation=K.profileGeneration
  if not wanted then self.status="완료 퀘스트 경험치 미리보기 OFF";return end
  if not supported then self.status="필수 Forever 퀘스트 보상/로그 API 미지원 · 미리보기 보류";return end
  self.active=true
  if not self.events then
    self.events=CreateFrame("Frame")
    self.events:SetScript("OnEvent",function(_,event,...) P:OnEvent(event,...) end)
  end
  for _,event in ipairs({"QUEST_LOG_UPDATE","QUEST_ACCEPTED","QUEST_TURNED_IN","QUEST_REMOVED","QUEST_COMPLETE","QUEST_FINISHED",
      "QUEST_DATA_LOAD_RESULT","QUEST_WATCH_UPDATE","QUEST_WATCH_LIST_CHANGED","QUEST_LOG_CRITERIA_UPDATE","PLAYER_ENTERING_WORLD"}) do
    local ok=pcall(self.events.RegisterEvent,self.events,event)
    if not ok and (event=="QUEST_LOG_UPDATE" or event=="QUEST_TURNED_IN" or event=="QUEST_COMPLETE") then
      self.active=false;self.events:UnregisterAllEvents();self.status="필수 퀘스트 동기화 이벤트 미지원";return
    end
  end
  self.status="완료 퀘스트 보상 확인 중";self:Queue(true)
end
