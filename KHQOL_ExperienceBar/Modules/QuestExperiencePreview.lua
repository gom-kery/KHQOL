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
    and type(q.IsOnQuest)=="function" and type(q.ReadyForTurnIn)=="function" and type(q.IsComplete)=="function"
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
  local count,numQuests=call(q.GetNumQuestLogEntries)
  if not number(count) or count<0 or count>1000 or count%1~=0
    or not number(numQuests) or numQuests<0 or numQuests%1~=0 then
    self.entries={};self.valid=false;self.status="퀘스트 로그를 확인할 수 없습니다.";self:Hide();return
  end
  local startXP,startLevel=call(UnitXP,"player"),call(UnitLevel,"player")
  local revision=self.revision
  local entries,seen,logged={}, {}, {}
  local failed=false
  for index=1,count do
    local info=call(q.GetInfo,index) -- index is a log index, not a quest ID.
    local questID,header,task,bounty,hidden
    if type(info)=="table" then
      questID,header,task,bounty,hidden=call(function() return info.questID,info.isHeader,info.isTask,info.isBounty,info.isHidden end)
    end
    if header==false and id(questID) then logged[questID]=true end
    if header==nil then failed=true end
    if header==false and id(questID) and not seen[questID] then
      seen[questID]=true
      local onQuest=call(q.IsOnQuest,questID)
      if onQuest==false then self.blocked[questID]=nil end
      -- Headers, tasks, bounties and hidden/internal entries are not ordinary
      -- outstanding hand-ins. Unknown public state never qualifies a quest.
      if task==false and bounty==false and hidden==false and onQuest==true and not self.blocked[questID]
        and call(q.ReadyForTurnIn,questID)==true and call(q.IsComplete,questID)==true then
        local rewarded=call(q.IsQuestFlaggedCompleted,questID)
        local repeatable=call(q.IsRepeatableQuest,questID)
        if rewarded==false or (rewarded==true and repeatable==true) then
          -- Forever's own UI supplies a QUEST ID to this global API. Never
          -- select a quest or fall back to a selection-dependent no-arg call.
          local reward=call(GetQuestLogRewardXP,questID)
          if xp(reward) and reward>0 then entries[questID]=reward end
        end
      end
    end
  end
  for questID in pairs(self.blocked) do
    if not logged[questID] and call(q.IsOnQuest,questID)==false then self.blocked[questID]=nil end
  end
  local loggedCount=0;for _ in pairs(logged) do loggedCount=loggedCount+1 end
  if number(numQuests) and loggedCount<numQuests then failed=true end
  local endXP,endLevel=call(UnitXP,"player"),call(UnitLevel,"player")
  if not xp(startXP) or not id(startLevel) or startXP~=endXP or startLevel~=endLevel or revision~=self.revision then failed=true end
  self.entries=entries;self:Sum()
  self.valid=not failed
  if allowSync and not failed then
    self.awaitLog=false;self.syncedXP=endXP;self.syncedLevel=endLevel
  end
  self.status=failed and "퀘스트 로그 전체/일관성을 확인할 수 없어 미리보기를 보류합니다."
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
    self:Queue(false)
  elseif self.lastXP and data.value~=self.lastXP then
    -- XP can arrive BEFORE the turn-in/log event. Do not render old quest XP
    -- on top of newly awarded XP, even for one frame. A later log event, not
    -- elapsed time, authorizes reconciliation. A log-first snapshot is safe.
    if self.syncedXP~=data.value or self.syncedLevel~=data.level then
      self.awaitLog=true;self.status="경험치 변경 후 퀘스트 로그 동기화를 기다립니다.";self:Hide()
    end
  end
  self.lastXP,self.lastLevel=data.value,data.level
end
function P:Amount(data)
  if not self.active or not self.valid or self.awaitLog or self.dialog or not data or data.kind~="experience"
    or data.atCap or not number(data.maximum) or data.maximum<=0 then return 0 end
  return self.total or 0
end
function P:Text(base,data)
  local amount=self:Amount(data)
  if amount<=0 then return base end
  if X.db.showQuestXPText then base=base.." (+"..X:FormatNumber(amount).." 예상)" end
  if X.db.showQuestLevelPrediction and amount>=data.remaining then base=base.." · 레벨업 예상" end
  return base
end
function P:OnEvent(event,questID,second)
  if not self.active then return end
  self.revision=self.revision+1
  if event=="QUEST_TURNED_IN" or event=="QUEST_REMOVED" then
    self.awaitLog=true
    if id(questID) then self.blocked[questID]=true;self.entries[questID]=nil;self:Sum() end
    self:Hide();self.status="퀘스트 반납/제거 후 로그 동기화 대기"
    self:Queue(false);X:Render()
  elseif event=="QUEST_COMPLETE" then
    self.dialog=true;self.dialogXP=call(UnitXP,"player");self.dialogLevel=call(UnitLevel,"player")
    self:Hide();X:Render()
  elseif event=="QUEST_FINISHED" then
    local unchanged=self.dialog and self.dialogXP==call(UnitXP,"player") and self.dialogLevel==call(UnitLevel,"player")
    self.dialog=nil;self:Queue(unchanged)
  elseif event=="QUEST_ACCEPTED" then
    -- Payload is questLogIndex, questID. Clear only the second, verified ID.
    if id(second) then self.blocked[second]=nil end
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
  if self.events then self.events:UnregisterAllEvents() end
  self.entries={};self.total=0;self.count=0;self.valid=false;self.awaitLog=false;self.dialog=nil
  self.lastXP,self.lastLevel=nil,nil;self.syncedXP,self.syncedLevel=nil,nil
  self.configDB=db;self.generation=K.profileGeneration
  if not wanted then self.status="완료 퀘스트 경험치 미리보기 OFF";return end
  if not supported then self.status="필수 Forever 퀘스트 보상/로그 API 미지원 · 미리보기 보류";return end
  self.active=true
  if not self.events then
    self.events=CreateFrame("Frame")
    self.events:SetScript("OnEvent",function(_,event,...) P:OnEvent(event,...) end)
  end
  for _,event in ipairs({"QUEST_LOG_UPDATE","QUEST_ACCEPTED","QUEST_TURNED_IN","QUEST_REMOVED","QUEST_COMPLETE","QUEST_FINISHED","QUEST_DATA_LOAD_RESULT","PLAYER_ENTERING_WORLD"}) do
    local ok=pcall(self.events.RegisterEvent,self.events,event)
    if not ok and (event=="QUEST_LOG_UPDATE" or event=="QUEST_TURNED_IN" or event=="QUEST_COMPLETE") then
      self.active=false;self.events:UnregisterAllEvents();self.status="필수 퀘스트 동기화 이벤트 미지원";return
    end
  end
  self.status="완료 퀘스트 보상 확인 중";self:Queue(true)
end
