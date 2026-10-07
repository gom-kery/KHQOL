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
function QN:IsQuestReadyForTurnIn(id)
  if not QN.IsID(id) then return nil end
  local api=C_QuestLog
  local ready=QN.Call(api and api.ReadyForTurnIn,id)
  if QN.IsTrue(ready) or QN.IsFalse(ready) then return ready end
  ready=QN.Call(api and api.IsComplete,id)
  if QN.IsTrue(ready) or QN.IsFalse(ready) then return ready end
end
function QN:IsComplete(id) return self:IsQuestReadyForTurnIn(id) end
function QN:GetTrackedQuests(force)
  if self.trackedLoaded and not force and not self.trackedDirty then return self.trackedQuestIDs end
  local ids={}
  local api=C_QuestLog
  local count=QN.Call(api and api.GetNumQuestWatches)
  self.watchSource="unavailable"
  if QN.IsNumber(count) and count>=0 and count%1==0 and count<=1000 and
     api and type(api.GetQuestIDForQuestWatchIndex)=="function" then
    self.watchSource="questWatch"
    for i=1,count do
      local id=QN.Call(api.GetQuestIDForQuestWatchIndex,i)
      if QN.IsID(id) then ids[id]=true end
    end
  end
  local worldCount=QN.Call(api and api.GetNumWorldQuestWatches)
  if QN.IsNumber(worldCount) and worldCount>=0 and worldCount%1==0 and worldCount<=1000 and
     api and type(api.GetQuestIDForWorldQuestWatchIndex)=="function" then
    for i=1,worldCount do
      local id=QN.Call(api.GetQuestIDForWorldQuestWatchIndex,i)
      if QN.IsID(id) then ids[id]=true end
    end
    self.watchSource=self.watchSource=="unavailable" and "worldQuestWatch" or "questWatch+worldQuestWatch"
  end
  -- The synchronous event payload wins if the native list is one event behind.
  self.watchOverrides=self.watchOverrides or {}
  for id,added in pairs(self.watchOverrides) do
    if (ids[id]==true)==added then self.watchOverrides[id]=nil
    elseif added then ids[id]=true else ids[id]=nil end
  end
  self.trackedQuestIDs=ids; self.trackedLoaded=true; self.trackedDirty=false
  return ids
end
function QN:WatchChanged(id,added)
  local ids=self:GetTrackedQuests()
  if QN.IsID(id) and (QN.IsTrue(added) or QN.IsFalse(added)) then
    self.watchOverrides[id]=added
    ids[id]=added and true or nil
  else self:GetTrackedQuests(true) end
end
function QN:GetCandidateInfo(id)
  local api=C_QuestLog
  local index=QN.Call(api and api.GetLogIndexForQuestID,id)
  local info=QN.IsID(index) and QN.Call(api and api.GetInfo,index) or nil
  if QN.IsTable(info) and QN.IsID(info.questID) and info.questID==id and QN.IsFalse(info.isHeader) then return info end
  return {}
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
  local tracked=self:GetTrackedQuests(true)
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
  -- Enumerate only watch IDs; never walk, expand or select quest-log rows.
  for id in pairs(tracked) do
    if id~=excludedID then
      if not QN.IsFalse(QN.Call(api and api.IsOnQuest,id)) and QN.IsFalse(self:IsComplete(id)) then
        local sq,onContinent=QN.Call(api and api.GetDistanceSqToQuest,id)
        if QN.IsNumber(sq) and sq>0 and QN.IsTrue(onContinent) then
          local rank=self:GetQuestPriority(id,self:GetCandidateInfo(id),playerLevel)
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
function QN:ClearNavigation(preserveRotation)
  self.targetMapID,self.targetX,self.targetY,self.waypointSource=nil,nil,nil,nil
  if not preserveRotation then self.currentRotation=nil end
  self.distanceYards=nil; self.distanceSq=nil; self.atWaypoint=false
  self.lastDistanceValue=nil; self.lastDistanceUnit=nil; self.distanceLabel=nil
  self.playerX=nil; self.playerY=nil; self.rotationFailed=nil
  self.playerFacing=nil; self.targetAngle=nil; self.relativeAngle=nil
  self.navigationMode="NONE"; self.locationReason=nil
end
function QN:GetTurnInWaypoint(id)
  -- Read a new native location after ReadyForTurnIn. Never carry the objective
  -- target across this boundary. An unchanged former objective is ambiguous.
  self.locationReason="noNativeLocation"
  local function accept(map,x,y)
    if not validPoint(map,x,y) then return false end
    if map==self.objectiveMapID and x==self.objectiveX and y==self.objectiveY then
      self.locationReason="unchangedObjective"; return false
    end
    self.locationReason="nativeReadyQuest"; return true
  end
  local api=C_QuestLog
  local map,x,y=QN.Call(api and api.GetNextWaypoint,id)
  if accept(map,x,y) then return map,x,y,"turnin:waypoint" end
  map=QN.Call(C_Map and C_Map.GetBestMapForUnit,"player")
  if not QN.IsID(map) then return nil end
  x,y=QN.Call(api and api.GetNextWaypointForMap,id,map)
  if accept(map,x,y) then return map,x,y,"turnin:mapWaypoint" end
  local pois=self:GetMapQuestPOIs(map)
  if pois then
    for _,info in ipairs(pois) do
      if validQuestPOI(info) and info.questID==id and accept(map,info.x,info.y) then
        return map,info.x,info.y,"turnin:questPOI"
      end
    end
  end
end
function QN:RefreshQuestData()
  local id=self.currentQuestID
  self:ClearNavigation(true); self.targetQuestID=id; self.progressText=""
  self.readyForTurnIn=nil
  if id then self.readyForTurnIn=self:IsQuestReadyForTurnIn(id) end
  if not id then self.questTitle=nil; return end
  local title=QN.Call(C_QuestLog and C_QuestLog.GetTitleForQuestID,id)
  self.questTitle=QN.IsText(title) and title~="" and title or ("퀘스트 #"..id)
  if QN.IsTrue(self.readyForTurnIn) then
    self.navigationMode="TURN_IN_LOCATION"
    self.targetMapID,self.targetX,self.targetY,self.waypointSource=self:GetTurnInWaypoint(id)
    self.progressText="반납 가능"
  elseif QN.IsFalse(self.readyForTurnIn) then
    self.navigationMode="OBJECTIVE_LOCATION"
    self.targetMapID,self.targetX,self.targetY,self.waypointSource=self:GetWaypoint(id)
    if self.targetMapID then self.objectiveMapID,self.objectiveX,self.objectiveY=self.targetMapID,self.targetX,self.targetY end
    self.locationReason=self.targetMapID and "nativeObjective" or "noNativeLocation"
    self:RefreshProgress()
  else self.locationReason="unknownCompletion" end
end
function QN:AdoptQuest(id,manual)
  if id and QN.IsFalse(QN.Call(C_QuestLog and C_QuestLog.IsOnQuest,id)) then id=nil end
  if id~=self.currentQuestID then
    self.objectiveMapID,self.objectiveX,self.objectiveY=nil,nil,nil
    self.manualTurnIn=false
  end
  if manual then self.removedSelectedQuestID=nil end
  self.currentRotation=nil; self.currentQuestID=id; self.manualSelection=manual==true
  self:RefreshQuestData()
  if QN.IsFalse(self.readyForTurnIn) then
    self.manualTurnIn=false
    if self.lastCompletedQuestID==id then self.lastCompletedQuestID=nil end
  end
  if manual and QN.IsTrue(self.readyForTurnIn) then self.manualTurnIn=true end
  if not id then self.state="IDLE"; self:Render(); self:UpdateDriver(); return end
  self.state="TRACKING"; self:UpdateNavigation(true,true); self:Render(); self:UpdateDriver()
end
function QN:RefreshQuest()
  if not self.active then return end
  self:GetTrackedQuests()
  if self.phase then return end
  local tracked=self:GetTrackedQuest()
  if tracked and QN.IsFalse(QN.Call(C_QuestLog and C_QuestLog.IsOnQuest,tracked)) then tracked=nil end
  local id=self.currentQuestID
  if tracked~=id then self:AdoptQuest(tracked,true); self.removedSelectedQuestID=nil; return end
  self.removedSelectedQuestID=nil
  if not id then self.state="IDLE"; self:Render(); return end
  self:RefreshQuestData()
  if QN.IsFalse(self.readyForTurnIn) then
    self.manualTurnIn=false
    if self.lastCompletedQuestID==id then self.lastCompletedQuestID=nil end
  elseif QN.IsTrue(self.readyForTurnIn) and self.db.autoTrack and
      self.db.completionBehavior=="next" and not self.manualTurnIn and self.lastCompletedQuestID~=id then
    self:BeginCompletion(id); return
  end
  self:UpdateNavigation(false,true); self:Render()
end
function QN:RefreshWaypoint()
  if self.phase or not self.currentQuestID then return end
  -- Completion is cached by quest events; route events never scan the log.
  self:ClearNavigation(true); self.targetQuestID=self.currentQuestID
  if QN.IsTrue(self.readyForTurnIn) then
    self.navigationMode="TURN_IN_LOCATION"
    self.targetMapID,self.targetX,self.targetY,self.waypointSource=self:GetTurnInWaypoint(self.currentQuestID)
  elseif QN.IsFalse(self.readyForTurnIn) then
    self.navigationMode="OBJECTIVE_LOCATION"
    self.targetMapID,self.targetX,self.targetY,self.waypointSource=self:GetWaypoint(self.currentQuestID)
    if self.targetMapID then self.objectiveMapID,self.objectiveX,self.objectiveY=self.targetMapID,self.targetX,self.targetY end
    self.locationReason=self.targetMapID and "nativeObjective" or "noNativeLocation"
  end
  if not QN.IsNumber(self.mapWidth) or not QN.IsNumber(self.mapHeight) then self.sizeMapID=nil end
  self:UpdateNavigation(false,true)
end
function QN:CancelTransition()
  self.phase=nil; self.phaseElapsed=0; self.completedQuestID=nil; self.fadeInRemaining=nil
  self.transitionTurnedIn=nil; self.completionTitleText=nil
  if self.hud then self.hud:SetAlpha(1) end
end
function QN:BeginCompletion(id,turnedIn,title)
  if self.phase or (not turnedIn and self.lastCompletedQuestID==id) then return end
  self.lastCompletedQuestID=id; self.completedQuestID=id; self.transitionTurnedIn=turnedIn==true
  self.completionTitleText=title or self.questTitle or ("퀘스트 #"..id)
  self:ClearNavigation()
  self.state="COMPLETED"; self.phase="hold"; self.phaseElapsed=0; self.fadeInRemaining=nil
  self.hud:SetAlpha(1); self:Render(); self:UpdateDriver()
end
function QN:QuestTurnedIn(id)
  self:WatchChanged(id,false)
  if self.transitionTurnedIn and self.completedQuestID==id then return end
  if id~=self.currentQuestID and id~=self.completedQuestID and id~=self.removedSelectedQuestID then return end
  local title=self.questTitle or self.completionTitleText
  local tracked=self:GetTrackedQuest()
  self:CancelTransition(); self:AdoptQuest(nil)
  self.removedSelectedQuestID=nil
  -- Clear only this returned quest, never a newer manual selection or user pin.
  if tracked==id then
    self.settingSuperTrack=true; QN.Call(C_SuperTrack and C_SuperTrack.SetSuperTrackedQuestID,0); self.settingSuperTrack=nil
  elseif tracked or self:OtherNavigationActive() then self:AdoptQuest(tracked,true); return end
  if self.db.autoTrack then self:BeginCompletion(id,true,title) end
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
  local completed,turnedIn=self.completedQuestID,self.transitionTurnedIn
  self:CancelTransition()
  local tracked=self:GetTrackedQuest()
  if (tracked and tracked~=completed) or self:OtherNavigationActive() then self:AdoptQuest(tracked,true); return end
  local chosen=self.db.autoTrack and self:FindClosestQuest(completed) or nil
  if chosen then
    self.settingSuperTrack=true
    QN.Call(C_SuperTrack and C_SuperTrack.SetSuperTrackedQuestID,chosen)
    self.settingSuperTrack=nil
    chosen=self:GetTrackedQuest()
  else chosen=not turnedIn and tracked or nil end
  if turnedIn and chosen==completed then chosen=nil end
  self:AdoptQuest(chosen,chosen==completed)
  if self.currentQuestID and not self.phase then self.hud:SetAlpha(0); self.fadeInRemaining=.15 end
  self:UpdateDriver()
end
