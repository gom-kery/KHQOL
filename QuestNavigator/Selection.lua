local _, KHQOL = ...
local QN=KHQOL.modules.questNavigator
local N,UI=KHQOL.Navigation,KHQOL.NavigationUI
-- Tracked IDs, candidate/waypoint queries and completion/selection state.
-- Tracker.lua owns list grouping/rendering and native presentation restoration.
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
    if not added then
      local remaining={}
      for _,d in ipairs(N:GetSourceDestinations("Quest")) do if d.id~=id then remaining[#remaining+1]=d end end
      N:SetSourceDestinations("Quest",remaining)
    end
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
  if type(poiLookup)=="function" then poiLookup=poiLookup() end
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
function QN:PublishCandidates(excludedID,force)
  if not self.db.autoTrack then N:SetSourceDestinations("Quest",{}); return end
  local api=C_QuestLog
  local tracked=self:GetTrackedQuests(force)
  local destinations={}
  local level,levelRead
  local playerMap=QN.Call(C_Map and C_Map.GetBestMapForUnit,"player")
  local poiLookup
  local function getPOILookup()
    if not poiLookup then
      poiLookup={}
      for _,info in ipairs(self:GetMapQuestPOIs(playerMap) or {}) do
        if validQuestPOI(info) and not poiLookup[info.questID] then poiLookup[info.questID]=info end
      end
    end
    return poiLookup
  end
  for id in pairs(tracked) do
    if id~=excludedID and not QN.IsFalse(QN.Call(api and api.IsOnQuest,id)) and QN.IsFalse(self:IsComplete(id)) then
      -- Keep the native quest distance/continent filter; map XY is not a substitute.
      local sq,onContinent=QN.Call(api and api.GetDistanceSqToQuest,id)
      if QN.IsNumber(sq) and sq>0 and QN.IsTrue(onContinent) then
        if not levelRead then
          level=QN.Call(UnitEffectiveLevel,"player")
          if not QN.IsNumber(level) or level<=0 then level=QN.Call(UnitLevel,"player") end
          levelRead=true
        end
        local info=self:GetCandidateInfo(id)
        local map,x,y,waypointSource=self:GetWaypoint(id,playerMap,getPOILookup)
        local title=QN.IsText(info.title) and info.title or ("퀘스트 #"..id)
        local d=self:BuildDestination(id,map,x,y,title)
        d.metadata.waypointSource=waypointSource; d.metadata.navigationMode="OBJECTIVE_LOCATION"
        d.metadata.navigation={distanceSq=sq,priority=self:GetQuestPriority(id,info,level)}
        destinations[#destinations+1]=d
      end
    end
  end
  N:SetSourceDestinations("Quest",destinations)
end
function QN:FindClosestQuest(excludedID)
  self:PublishCandidates(excludedID,true)
  local destination=N:GetNearestDestination("Quest",excludedID,self.db.preferSameRegion)
  return destination and destination.id or nil
end

local function objectiveLabel(text)
  local label=text:gsub("^%s*%d+%s*/%s*%d+%s*",""):gsub("%s*%d+%s*/%s*%d+%s*$","")
  label=label:gsub("^%s*:%s*",""):gsub("^%s*：%s*","")
  label=label:gsub("%s*:%s*$",""):gsub("%s*：%s*$","")
  return label:match("^%s*(.-)%s*$")
end
function QN:RefreshProgress()
  self.progressText=""
  if not self.selectedQuestID then return end
  local objectives=QN.Call(C_QuestLog and C_QuestLog.GetQuestObjectives,self.selectedQuestID)
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
  if not preserveRotation then N:SetSourceFocus("Quest",nil) end
  self.waypointSource=nil; self.navigationMode="NONE"; self.locationReason=nil
end
function QN:BuildDestination(id,map,x,y,title)
  return {source="Quest",id=id,mapID=map,x=x,y=y,label=title or self.questTitle or ("퀘스트 #"..id),
    metadata={questID=id,waypointSource=self.waypointSource,navigationMode=self.navigationMode}}
end
function QN:PublishActive(map,x,y)
  if self.selectedQuestID then N:SetSourceFocus("Quest",self:BuildDestination(self.selectedQuestID,map,x,y),true)
  else N:SetSourceFocus("Quest",nil,true) end
  self:SyncPresentation()
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
  local id=self.selectedQuestID
  self:ClearNavigation(true); self.progressText=""
  self.readyForTurnIn=nil
  if id then self.readyForTurnIn=self:IsQuestReadyForTurnIn(id) end
  if not id then self.questTitle=nil; self:PublishActive(); return end
  local title=QN.Call(C_QuestLog and C_QuestLog.GetTitleForQuestID,id)
  self.questTitle=QN.IsText(title) and title~="" and title or ("퀘스트 #"..id)
  local map,x,y
  if QN.IsTrue(self.readyForTurnIn) then
    self.navigationMode="TURN_IN_LOCATION"
    map,x,y,self.waypointSource=self:GetTurnInWaypoint(id)
    self.progressText="반납 가능"
  elseif QN.IsFalse(self.readyForTurnIn) then
    self.navigationMode="OBJECTIVE_LOCATION"
    map,x,y,self.waypointSource=self:GetWaypoint(id)
    if map then self.objectiveMapID,self.objectiveX,self.objectiveY=map,x,y end
    self.locationReason=map and "nativeObjective" or "noNativeLocation"
    self:RefreshProgress()
  else self.locationReason="unknownCompletion" end
  self:PublishActive(map,x,y)
end
function QN:AdoptQuest(id,manual)
  if id and QN.IsFalse(QN.Call(C_QuestLog and C_QuestLog.IsOnQuest,id)) then id=nil end
  if id~=self.selectedQuestID then
    self.objectiveMapID,self.objectiveX,self.objectiveY=nil,nil,nil
    self.manualTurnIn=false
  end
  if manual then self.removedSelectedQuestID=nil end
  N:SetSourceFocus("Quest",nil); self.selectedQuestID=id; self.manualSelection=manual==true
  self:RefreshQuestData()
  if QN.IsFalse(self.readyForTurnIn) then
    self.manualTurnIn=false
    if self.lastCompletedQuestID==id then self.lastCompletedQuestID=nil end
  end
  if manual and QN.IsTrue(self.readyForTurnIn) then self.manualTurnIn=true end
  if not id then UI:Render(); self:UpdateDriver(); return end
  if N.activeSource=="Quest" then UI:Refresh(true,true) end; UI:Render(); self:UpdateDriver()
end
function QN:RefreshQuest()
  if not self.active then return end
  self:GetTrackedQuests(); self:PublishCandidates(self.completedQuestID or self.selectedQuestID)
  if UI:IsTransitioning("Quest") then return end
  local tracked=self:GetTrackedQuest()
  if tracked and QN.IsFalse(QN.Call(C_QuestLog and C_QuestLog.IsOnQuest,tracked)) then tracked=nil end
  local id=self.selectedQuestID
  if tracked~=id then self:AdoptQuest(tracked,true); self.removedSelectedQuestID=nil; return end
  self.removedSelectedQuestID=nil
  if not id then UI:Render(); return end
  self:RefreshQuestData()
  if QN.IsFalse(self.readyForTurnIn) then
    self.manualTurnIn=false
    if self.lastCompletedQuestID==id then self.lastCompletedQuestID=nil end
  elseif QN.IsTrue(self.readyForTurnIn) and self.db.autoTrack and
      self.db.completionBehavior=="next" and not self.manualTurnIn and self.lastCompletedQuestID~=id then
    self:BeginCompletion(id); return
  end
  if N.activeSource=="Quest" then UI:Refresh(false,true) end; UI:Render()
end
function QN:RefreshWaypoint()
  if UI:IsTransitioning("Quest") or not self.selectedQuestID then return end
  -- Completion is cached by quest events; route events never scan the log.
  self:ClearNavigation(true)
  local map,x,y
  if QN.IsTrue(self.readyForTurnIn) then
    self.navigationMode="TURN_IN_LOCATION"
    map,x,y,self.waypointSource=self:GetTurnInWaypoint(self.selectedQuestID)
  elseif QN.IsFalse(self.readyForTurnIn) then
    self.navigationMode="OBJECTIVE_LOCATION"
    map,x,y,self.waypointSource=self:GetWaypoint(self.selectedQuestID)
    if map then self.objectiveMapID,self.objectiveX,self.objectiveY=map,x,y end
    self.locationReason=map and "nativeObjective" or "noNativeLocation"
  end
  self:PublishActive(map,x,y)
  if not QN.IsNumber(N.mapWidth) or not QN.IsNumber(N.mapHeight) then N:InvalidateMap() end
  if N.activeSource=="Quest" then UI:Refresh(false,true) end
end
function QN:CancelTransition()
  self.completedQuestID=nil; self.transitionTurnedIn=nil
  UI:CancelTransition("Quest"); N:SetSourceHold("Quest",false)
end

function QN:BeginCompletion(id,turnedIn,title)
  if UI:IsTransitioning("Quest") or (not turnedIn and self.lastCompletedQuestID==id) then return end
  self.lastCompletedQuestID=id; self.completedQuestID=id; self.transitionTurnedIn=turnedIn==true
  local label=title or self.questTitle or ("퀘스트 #"..id)
  self:ClearNavigation()
  N:SetSourceHold("Quest",true)
  UI:BeginTransition(label,function() self:FinishTransition() end,"Quest")
end

function QN:QuestTurnedIn(id)
  self:WatchChanged(id,false)
  if self.transitionTurnedIn and self.completedQuestID==id then return end
  if id~=self.selectedQuestID and id~=self.completedQuestID and id~=self.removedSelectedQuestID then return end
  local title=self.questTitle or UI.presentation.completionTitle
  local tracked=self:GetTrackedQuest()
  self:CancelTransition(); self:AdoptQuest(nil)
  self.removedSelectedQuestID=nil
  -- Clear only this returned quest, never a newer manual selection or user pin.
  if tracked==id then
    self.settingSuperTrack=true; QN.Call(C_SuperTrack and C_SuperTrack.SetSuperTrackedQuestID,0); self.settingSuperTrack=nil
  elseif tracked or self:OtherNavigationActive() then self:AdoptQuest(tracked,true); return end
  if self.db.autoTrack then self:BeginCompletion(id,true,title) end
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
  if self.selectedQuestID and not UI:IsTransitioning("Quest") then UI:FadeIn("Quest") end
  self:UpdateDriver()
end
