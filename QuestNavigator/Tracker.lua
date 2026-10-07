local _, KHQOL = ...
local QN=KHQOL.modules.questNavigator
function QN:GetTrackedQuest()
  local api=C_SuperTrack
  if QN.IsFalse(QN.Call(api and api.IsSuperTrackingQuest)) then return nil end
  local id=QN.Call(api and api.GetSuperTrackedQuestID)
  if QN.IsID(id) then return id end
end
function QN:OtherNavigationActive()
  local api=C_SuperTrack
  return QN.IsTrue(QN.Call(api and api.IsSuperTrackingAnything)) and not self:GetTrackedQuest()
end
function QN:IsComplete(id)
  return QN.Call(C_QuestLog and C_QuestLog.IsComplete,id)
end
local function validCoordinates(x,y)
  return QN.IsNumber(x) and QN.IsNumber(y) and x>=0 and x<=1 and y>=0 and y<=1
end
local function validPoint(map,x,y)
  return QN.IsID(map) and validCoordinates(x,y)
end
local function validQuestPOI(info)
  return QN.IsTable(info) and QN.IsID(info.questID) and
    not QN.IsSecret(info.isMapIndicatorQuest) and not QN.IsTrue(info.isMapIndicatorQuest) and
    validCoordinates(info.x,info.y)
end
function QN:GetMapQuestPOIs(map)
  if not QN.IsID(map) then return nil end
  local pois=QN.Call(C_QuestLog and C_QuestLog.GetQuestsOnMap,map)
  if QN.IsTable(pois) then return pois end
end
function QN:GetWaypoint(id,playerMap,poiLookup)
  if not QN.IsID(id) then return nil end
  local api=C_QuestLog
  local map,x,y=QN.Call(api and api.GetNextWaypoint,id)
  if validPoint(map,x,y) then return map,x,y,"waypoint" end
  playerMap=playerMap or QN.Call(C_Map and C_Map.GetBestMapForUnit,"player")
  if not QN.IsID(playerMap) then return nil end
  x,y=QN.Call(api and api.GetNextWaypointForMap,id,playerMap)
  if validPoint(playerMap,x,y) then return playerMap,x,y,"mapWaypoint" end
  -- A map quest marker can exist even when both waypoint APIs return nothing.
  -- Read only the matching quest's underlying coordinates, never display offsets
  -- or a user pin. The completion scan supplies a temporary lookup to stay O(n+m).
  if poiLookup then
    local info=poiLookup[id]
    if validQuestPOI(info) then return playerMap,info.x,info.y,"questPOI" end
  else
    local pois=self:GetMapQuestPOIs(playerMap)
    if pois then
      for _,info in ipairs(pois) do
        if validQuestPOI(info) and info.questID==id then return playerMap,info.x,info.y,"questPOI" end
      end
    end
  end
end
local COLOR_PRIORITIES={standard=1,trivial=1,difficult=2,verydifficult=3,impossible=4}
local function colorPriority(color)
  if not QN.IsTable(color) or not QN.IsTable(QuestDifficultyColors) then return nil end
  for key,priority in pairs(COLOR_PRIORITIES) do
    local reference=QuestDifficultyColors[key]
    if QN.IsTable(reference) and (color==reference or
      (QN.IsNumber(color.r) and QN.IsNumber(color.g) and QN.IsNumber(color.b) and
       QN.IsNumber(reference.r) and QN.IsNumber(reference.g) and QN.IsNumber(reference.b) and
       color.r==reference.r and color.g==reference.g and color.b==reference.b)) then return priority end
  end
end
function QN:GetQuestPriority(id,info,playerLevel)
  local api=C_QuestLog
  local tag=QN.Call(api and api.GetQuestTagInfo,id)
  if QN.IsTable(tag) and QN.IsNumber(tag.tagID) then
    local tags=QN.IsTable(Enum) and QN.IsTable(Enum.QuestTag) and Enum.QuestTag or nil
    local dungeon=tags and tags.Dungeon or nil
    local heroic=tags and tags.Heroic or nil
    -- Native tag IDs are retained for clients without the enum namespace.
    if not QN.IsID(dungeon) then dungeon=81 end
    if not QN.IsID(heroic) then heroic=85 end
    if tag.tagID==dungeon or tag.tagID==heroic then return 5 end
  end
  -- Use the same content difficulty as the native objective-tracker title.
  local difficulty=QN.Call(C_PlayerInfo and C_PlayerInfo.GetContentDifficultyQuestForPlayer,id)
  local relative=QN.IsTable(Enum) and QN.IsTable(Enum.RelativeContentDifficulty) and Enum.RelativeContentDifficulty or nil
  if QN.IsNumber(difficulty) and relative then
    if (QN.IsNumber(relative.Trivial) and difficulty==relative.Trivial) or
       (QN.IsNumber(relative.Easy) and difficulty==relative.Easy) then return 1 end
    if QN.IsNumber(relative.Fair) and difficulty==relative.Fair then return 2 end
    if QN.IsNumber(relative.Difficult) and difficulty==relative.Difficult then return 3 end
    if QN.IsNumber(relative.Impossible) and difficulty==relative.Impossible then return 4 end
  end
  local level=info.difficultyLevel
  if not QN.IsNumber(level) or level<=0 then level=QN.Call(api and api.GetQuestDifficultyLevel,id) end
  if not QN.IsNumber(level) or level<=0 then level=info.level end
  if not QN.IsNumber(level) or level<=0 then return 2 end
  local scaling=QN.IsTrue(info.isScaling)
  local priority=colorPriority(QN.Call(GetQuestDifficultyColor,level,scaling,id))
  if priority then return priority end
  if QN.IsNumber(playerLevel) and playerLevel>0 then
    local diff=level-playerLevel
    if diff>=5 then return 4 end
    if diff>=3 then return 3 end
    if diff>=(scaling and 0 or -4) then return 2 end
    return 1 -- Gray and green both occupy the easiest tier.
  end
  return 2 -- Unknown difficulty keeps the ordinary tier and distance ordering.
end
function QN:FindClosestQuest(excludedID)
  local api=C_QuestLog
  local count=QN.Call(api and api.GetNumQuestLogEntries)
  if not QN.IsNumber(count) or count<0 then return nil end
  local closest,minimum,priority,localQuest,localMinimum,localPriority=nil,math.huge,math.huge,nil,math.huge,math.huge
  local playerLevel=QN.Call(UnitEffectiveLevel,"player")
  if not QN.IsNumber(playerLevel) or playerLevel<=0 then playerLevel=QN.Call(UnitLevel,"player") end
  local playerMap=QN.Call(C_Map and C_Map.GetBestMapForUnit,"player")
  local poiLookup
  if self.db.preferSameRegion and QN.IsID(playerMap) then
    poiLookup={}
    local pois=self:GetMapQuestPOIs(playerMap)
    if pois then
      for _,info in ipairs(pois) do
        if validQuestPOI(info) and not poiLookup[info.questID] then poiLookup[info.questID]=info end
      end
    end
  end
  -- Single pass, constant retained state; no sorting, expansion or selection of
  -- Blizzard quest-log rows. Unknown completion/continent data is rejected.
  for index=1,math.floor(count) do
    local info=QN.Call(api and api.GetInfo,index)
    if QN.IsTable(info) and QN.IsFalse(info.isHeader) and QN.IsID(info.questID) and info.questID~=excludedID then
      local id=info.questID
      if QN.IsFalse(self:IsComplete(id)) then
        local sq,onContinent=QN.Call(api and api.GetDistanceSqToQuest,id)
        if QN.IsNumber(sq) and sq>0 and QN.IsTrue(onContinent) then
          local rank=self:GetQuestPriority(id,info,playerLevel)
          if rank<priority or (rank==priority and (sq<minimum or (sq==minimum and (not closest or id<closest)))) then
            closest,minimum,priority=id,sq,rank
          end
          if self.db.preferSameRegion and QN.IsID(playerMap) then
            local map=self:GetWaypoint(id,playerMap,poiLookup)
            if map==playerMap and (rank<localPriority or (rank==localPriority and
              (sq<localMinimum or (sq==localMinimum and (not localQuest or id<localQuest))))) then
              localQuest,localMinimum,localPriority=id,sq,rank
            end
          end
        end
      end
    end
  end
  if localQuest and localPriority==priority then return localQuest end
  return closest
end
local function objectiveLabel(text)
  -- Forever objective text can include the progress before or after the label.
  -- Strip only edge fractions; numbers and fractions inside names remain intact.
  local label=text:gsub("^%s*%d+%s*/%s*%d+%s*",""):gsub("%s*%d+%s*/%s*%d+%s*$","")
  label=label:gsub("^%s*:%s*",""):gsub("^%s*：%s*","")
  label=label:gsub("%s*:%s*$",""):gsub("%s*：%s*$","")
  return label:match("^%s*(.-)%s*$")
end
function QN:RefreshProgress()
  self.progressText=""
  if not self.currentQuestID then return end
  local objectives=QN.Call(C_QuestLog and C_QuestLog.GetQuestObjectives,self.currentQuestID)
  if not QN.IsTable(objectives) then return end
  for _,objective in ipairs(objectives) do
    if QN.IsTable(objective) and QN.IsFalse(objective.finished) then
      local n,total=objective.numFulfilled,objective.numRequired
      local text=QN.IsText(objective.text) and objective.text or ""
      -- finished is authoritative: some Forever objective types report 1 before
      -- completion. Never infer whole-quest completion from a numeric fraction.
      if QN.IsNumber(n) and QN.IsNumber(total) and n>=0 and total>0 then
        local numeric=string.format("%d / %d",math.floor(n),math.floor(total))
        if self.db.progressMode=="text" and text~="" then
          local label=objectiveLabel(text)
          self.progressText=label~="" and (label.." "..numeric) or numeric
        else self.progressText=numeric end
      else self.progressText=self.db.progressMode=="text" and text or "진행 중" end
      return
    end
  end
end
function QN:RefreshQuestData()
  local id=self.currentQuestID
  self.targetMapID,self.targetX,self.targetY,self.waypointSource=nil,nil,nil,nil
  self.targetQuestID=id
  if not id then return end
  local title=QN.Call(C_QuestLog and C_QuestLog.GetTitleForQuestID,id)
  self.questTitle=QN.IsText(title) and title~="" and title or ("퀘스트 #"..id)
  self.targetMapID,self.targetX,self.targetY,self.waypointSource=self:GetWaypoint(id)
  self:RefreshProgress()
end
function QN:AdoptQuest(id)
  self.currentQuestID=id; self.currentRotation=nil; self.distanceYards=nil; self.distanceSq=nil
  self.lastDistanceValue=nil; self.lastDistanceUnit=nil; self.distanceLabel=nil; self.playerX=nil; self.playerY=nil; self.rotationFailed=nil
  self:RefreshQuestData()
  if not id then self.state="IDLE"; self:Render(); self:UpdateDriver(); return end
  if QN.IsTrue(self:IsComplete(id)) then
    if self.lastCompletedQuestID~=id then self:BeginCompletion(id)
    else self.state="COMPLETED"; self:Render() end
  else
    if QN.IsFalse(self:IsComplete(id)) and self.lastCompletedQuestID==id then self.lastCompletedQuestID=nil end
    self.state="TRACKING"; self:UpdateNavigation(true,true); self:Render()
  end
  self:UpdateDriver()
end
function QN:RefreshQuest()
  if not self.active or self.phase then return end
  local tracked=self:GetTrackedQuest()
  local id=self.currentQuestID
  -- Check the remembered quest first. A turn-in may already have cleared the
  -- native supertrack; the explicit turn-in event handles that case too.
  if id and self.lastCompletedQuestID~=id and QN.IsTrue(self:IsComplete(id)) then
    self:BeginCompletion(id); return
  end
  if tracked and QN.IsFalse(QN.Call(C_QuestLog and C_QuestLog.IsOnQuest,tracked)) then tracked=nil end
  if tracked~=id then self:AdoptQuest(tracked); return end
  if not id then self.state="IDLE"; self:Render(); return end
  if QN.IsFalse(self:IsComplete(id)) and self.lastCompletedQuestID==id then self.lastCompletedQuestID=nil end
  self:RefreshQuestData()
  if QN.IsTrue(self:IsComplete(id)) then self.state="COMPLETED"; self:Render()
  else self:UpdateNavigation(false,false); self:Render() end
end
function QN:RefreshWaypoint()
  if self.phase or not self.currentQuestID or self.state=="COMPLETED" then return end
  self.targetMapID,self.targetX,self.targetY,self.waypointSource=self:GetWaypoint(self.currentQuestID)
  if not QN.IsNumber(self.mapWidth) or not QN.IsNumber(self.mapHeight) then self.sizeMapID=nil end
  self:UpdateNavigation(false,false)
end
function QN:CancelTransition()
  self.phase=nil; self.phaseElapsed=0; self.completedQuestID=nil; self.fadeInRemaining=nil
  if self.hud then self.hud:SetAlpha(1) end
end
function QN:BeginCompletion(id)
  if self.phase or self.lastCompletedQuestID==id then return end
  self.lastCompletedQuestID=id; self.completedQuestID=id
  self.state="COMPLETED"; self.phase="hold"; self.phaseElapsed=0; self.fadeInRemaining=nil
  self.hud:SetAlpha(1); self:Render(); self:UpdateDriver()
end
function QN:AdvanceTransition(elapsed)
  self.phaseElapsed=self.phaseElapsed+elapsed
  if self.phase=="hold" and self.phaseElapsed>=.85 then
    self.phase="out"; self.phaseElapsed=0; self.state="SWITCHING"
  elseif self.phase=="out" then
    self.hud:SetAlpha(math.max(0,1-self.phaseElapsed/.15))
    if self.phaseElapsed>=.15 then self:FinishTransition() end
  end
end
function QN:FinishTransition()
  local completed=self.completedQuestID
  self:CancelTransition()
  local chosen=self.db.autoTrack and self:FindClosestQuest(completed) or nil
  if chosen then
    self.settingSuperTrack=true
    QN.Call(C_SuperTrack and C_SuperTrack.SetSuperTrackedQuestID,chosen)
    self.settingSuperTrack=nil
    -- A protected/rejected write must not leave our HUD on a different quest.
    chosen=self:GetTrackedQuest()
  else chosen=self:GetTrackedQuest() end
  self:AdoptQuest(chosen)
  if self.currentQuestID and not self.phase then self.hud:SetAlpha(0); self.fadeInRemaining=.15 end
  self:UpdateDriver()
end
