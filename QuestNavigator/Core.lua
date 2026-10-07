local _, KHQOL = ...
local QN = KHQOL.modules.questNavigator
QN.VERSION = "0.2.0"
QN.defaults = {
  autoTrack=true, completionBehavior="turnin", preferSameRegion=false, showArrow=true, arrowSize=64, arrowAlpha=1, arrowTilt=55,
  smoothRotation=true, showDistance=true, showTitle=true, showProgress=true,
  progressMode="numeric", distanceUnit="yards", locked=true, positionX=0, positionY=180,
  arrowUpdateInterval=.10, distanceUpdateInterval=.25, smoothingFactor=.25,
}
-- Enable is owned only by KHQOLDB.enabled.questNavigator (no duplicate flag).
local EVENTS = {
  "PLAYER_ENTERING_WORLD", "QUEST_LOG_UPDATE", "QUEST_WATCH_UPDATE",
  "QUEST_WATCH_LIST_CHANGED", "QUEST_TURNED_IN", "QUEST_ACCEPTED", "QUEST_REMOVED",
  "QUEST_POI_UPDATE", "SUPER_TRACKING_CHANGED", "SUPER_TRACKING_PATH_UPDATED",
  "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED",
}
function QN.IsSecret(value) return issecretvalue and issecretvalue(value) or false end
function QN.IsNumber(value)
  return not QN.IsSecret(value) and type(value)=="number" and value==value and value~=math.huge and value~=-math.huge
end
function QN.IsID(value) return QN.IsNumber(value) and value>0 and value%1==0 end
function QN.IsText(value) return not QN.IsSecret(value) and type(value)=="string" end
function QN.IsTable(value) return not QN.IsSecret(value) and type(value)=="table" end
function QN.IsTrue(value) return not QN.IsSecret(value) and value==true end
function QN.IsFalse(value) return not QN.IsSecret(value) and value==false end
-- Guard missing bindings, beta data failures and protected calls at the boundary.
function QN.Call(fn, ...)
  if type(fn)~="function" then return nil end
  local ok, a, b, c = pcall(fn, ...)
  if ok then return a, b, c end
end
local function clamp(value, low, high, default)
  if not QN.IsNumber(value) then return default end
  return math.max(low, math.min(high, value))
end
function QN:GetDB()
  local db=KHQOL.db.modules.questNavigator
  if type(db)~="table" then db={}; KHQOL.db.modules.questNavigator=db end
  -- Existing explicit autoTrack=true profiles keep their old completion UX.
  if db.completionBehavior==nil then db.completionBehavior=db.autoTrack==true and "next" or "turnin" end
  KHQOL.MergeDefaults(db,self.defaults,"types")
  db.arrowSize=clamp(db.arrowSize,32,128,64); db.arrowAlpha=clamp(db.arrowAlpha,.1,1,1)
  db.arrowTilt=clamp(db.arrowTilt,0,70,55)
  db.positionX=clamp(db.positionX,-10000,10000,0); db.positionY=clamp(db.positionY,-10000,10000,180)
  db.arrowUpdateInterval=clamp(db.arrowUpdateInterval,.05,.5,.10)
  db.distanceUpdateInterval=clamp(db.distanceUpdateInterval,.1,1,.25)
  db.smoothingFactor=clamp(db.smoothingFactor,.01,1,.25)
  if db.progressMode~="numeric" and db.progressMode~="text" then db.progressMode="numeric" end
  if db.distanceUnit~="yards" and db.distanceUnit~="meters" then db.distanceUnit="yards" end
  if db.completionBehavior~="turnin" and db.completionBehavior~="next" then db.completionBehavior="turnin" end
  self.db=db; return db
end
function QN:IsEnabled() return self.active==true end
function QN:UpdateDriver()
  if not self.events then return end
  local moving=self.currentQuestID and self.state~="COMPLETED" and self.state~="IDLE"
  local running=self.active and (self.dirty or self.phase or self.fadeInRemaining or moving) and true or false
  if self.driverRunning~=running then
    self.driverRunning=running
    self.events:SetScript("OnUpdate",running and self.updateHandler or nil)
  end
end
function QN:MarkDirty(questChanged)
  if not self.active then return end
  if not self.dirty then self.dirtyElapsed=0 end
  self.dirty=true
  if questChanged then self.questDirty=true end
  self:UpdateDriver()
end
function QN:OnEvent(event, questID, added)
  if not self.active then return end
  if event=="QUEST_WATCH_LIST_CHANGED" then self:WatchChanged(questID,added)
  elseif event=="QUEST_REMOVED" and QN.IsID(questID) then
    self:WatchChanged(questID,false)
    if questID==self.currentQuestID then
      self.removedSelectedQuestID=questID
      self:CancelTransition(); self:AdoptQuest(nil)
    end
  elseif event=="QUEST_TURNED_IN" and QN.IsID(questID) then
    self:QuestTurnedIn(questID)
  elseif event=="SUPER_TRACKING_CHANGED" then
    if self.settingSuperTrack then return end
    local id=self:GetTrackedQuest()
    if id then self:CancelTransition(); self:AdoptQuest(id,true)
    elseif self:OtherNavigationActive() then self:CancelTransition(); self:AdoptQuest(nil,true)
    elseif not self.phase then self:MarkDirty(true) end
  end
  if event=="PLAYER_ENTERING_WORLD" or event=="ZONE_CHANGED_NEW_AREA" or event=="ZONE_CHANGED" then self.sizeMapID=nil end
  local waypointOnly=event=="QUEST_POI_UPDATE" or event=="SUPER_TRACKING_PATH_UPDATED" or event=="SUPER_TRACKING_CHANGED"
  if not waypointOnly then self.trackedDirty=true end
  self:MarkDirty(not waypointOnly)
end
function QN:OnUpdate(elapsed)
  if not self.active then return end
  if self.dirty then
    self.dirtyElapsed=self.dirtyElapsed+elapsed
    if self.dirtyElapsed>=.10 then
      local questChanged=self.questDirty
      self.dirty=false; self.questDirty=false
      if questChanged then self:RefreshQuest() else self:RefreshWaypoint() end
    end
  end
  if self.phase then self:AdvanceTransition(elapsed)
  elseif self.fadeInRemaining then
    self.fadeInRemaining=math.max(0,self.fadeInRemaining-elapsed)
    self.hud:SetAlpha(1-self.fadeInRemaining/.15)
    if self.fadeInRemaining==0 then self.fadeInRemaining=nil end
  end
  if not self.phase and self.currentQuestID and self.state~="COMPLETED" then
    self.arrowElapsed=self.arrowElapsed+elapsed; self.distanceElapsed=self.distanceElapsed+elapsed
    local arrowDue=self.db.showArrow and self.arrowElapsed>=self.db.arrowUpdateInterval
    local distanceDue=self.distanceElapsed>=self.db.distanceUpdateInterval
    if arrowDue or distanceDue then
      if arrowDue then self.arrowElapsed=self.arrowElapsed%self.db.arrowUpdateInterval end
      if distanceDue then self.distanceElapsed=self.distanceElapsed%self.db.distanceUpdateInterval end
      self:UpdateNavigation(arrowDue,distanceDue)
    end
  end
  self:UpdateDriver()
end
function QN:SetEnabled(enabled)
  self:GetDB()
  self:SetObjectiveTrackerEnabled(enabled)
  if not self.events then
    self.events=CreateFrame("Frame")
    self.updateHandler=function(_,elapsed) self:OnUpdate(elapsed) end
    self.events:SetScript("OnEvent",function(_,event,...) self:OnEvent(event,...) end)
    self:CreateHUD()
  end
  if self.dragging then self:SavePosition() end
  self.active=enabled and true or false
  self.events:UnregisterAllEvents(); self.events:SetScript("OnUpdate",nil)
  self.driverRunning=false
  self:CancelTransition(); self.dirty=false; self.questDirty=false; self.currentQuestID=nil; self.targetQuestID=nil
  self:ClearNavigation(); self.readyForTurnIn=nil; self.manualTurnIn=false; self.manualSelection=false
  self.objectiveMapID,self.objectiveX,self.objectiveY=nil,nil,nil
  self.removedSelectedQuestID=nil; self.trackedQuestIDs={}; self.watchOverrides={}; self.trackedLoaded=false; self.trackedDirty=true
  self.state="IDLE"; self.arrowElapsed=0; self.distanceElapsed=0
  self:ApplyLayout(); self:Render()
  if not self.active then return end
  for _,event in ipairs(EVENTS) do
    -- All names are present in Forever source. Also check the running beta build.
    local valid=QN.Call(C_EventUtils and C_EventUtils.IsEventValid,event)
    if not QN.IsFalse(valid) then QN.Call(self.events.RegisterEvent,self.events,event) end
  end
  self:GetTrackedQuests(true); self:AdoptQuest(self:GetTrackedQuest(),true); self:UpdateDriver()
end
function QN:Changed(key)
  if self.dragging and (key=="locked" or key=="position") then self:SavePosition() end
  self:ApplyLayout()
  if not self.active then return end
  if key=="completionBehavior" or key=="autoTrack" then
    self:CancelTransition(); self:RefreshQuest(); self:UpdateDriver(); return
  end
  if key=="progressMode" and not QN.IsTrue(self.readyForTurnIn) then self:RefreshProgress() end
  if not self.phase and self.currentQuestID and self.state~="COMPLETED" then self:UpdateNavigation(true,true) end
  self:Render(); self:UpdateDriver()
end
-- Explicit developer inspection only; release operation never emits chat output.
function QN:GetDebugSnapshot()
  self:GetDB()
  local tracked,ready,candidates={},{},{}
  for id in pairs(self:GetTrackedQuests(true)) do
    tracked[#tracked+1]=id
    local value=self:IsQuestReadyForTurnIn(id)
    ready[id]=value==nil and "UNKNOWN" or (value and "YES" or "NO")
    if QN.IsFalse(value) and not QN.IsFalse(QN.Call(C_QuestLog and C_QuestLog.IsOnQuest,id)) then
      local sq,onContinent=QN.Call(C_QuestLog and C_QuestLog.GetDistanceSqToQuest,id)
      if QN.IsNumber(sq) and sq>0 and QN.IsTrue(onContinent) then candidates[#candidates+1]=id end
    end
  end
  table.sort(tracked); table.sort(candidates)
  return {
    version=self.VERSION, state=self.state, currentQuestID=self.currentQuestID,
    completionBehavior=self.db and self.db.completionBehavior, navigationMode=self.navigationMode,
    readyForTurnIn=self.readyForTurnIn, watchSource=self.watchSource, trackedQuestIDs=tracked,
    trackedReadyForTurnIn=ready, autoCandidates=candidates,
    locationReason=self.locationReason, manualTurnIn=self.manualTurnIn,
    objectiveMapID=self.objectiveMapID, objectiveX=self.objectiveX, objectiveY=self.objectiveY,
    turnInMapID=self.navigationMode=="TURN_IN_LOCATION" and self.targetMapID or nil,
    turnInX=self.navigationMode=="TURN_IN_LOCATION" and self.targetX or nil,
    turnInY=self.navigationMode=="TURN_IN_LOCATION" and self.targetY or nil,
    targetQuestID=self.targetQuestID, lastCompletedQuestID=self.lastCompletedQuestID,
    playerMapID=self.playerMapID, targetMapID=self.targetMapID, waypointSource=self.waypointSource,
    playerX=self.playerX, playerY=self.playerY, targetX=self.targetX, targetY=self.targetY,
    distanceSq=self.distanceSq, playerFacing=self.playerFacing, targetAngle=self.targetAngle,
    relativeAngle=self.relativeAngle, currentRotation=self.currentRotation,
  }
end
function QN:HandleCommand(message)
  local command=(message or ""):lower():match("^%s*%S+%s+(%S+)")
  if command=="layout" then self:PrintTrackerLayout(); return end
  if command~="status" and command~="debug" then KHQOL:OpenModule("questNavigator"); return end
  local s=self:GetDebugSnapshot()
  local function emit(text)
    if DEFAULT_CHAT_FRAME and type(DEFAULT_CHAT_FRAME.AddMessage)=="function" then DEFAULT_CHAT_FRAME:AddMessage("KHQOL Quest: "..text) end
  end
  emit("Version: "..self.VERSION.." / Selected Quest: "..(s.currentQuestID or "NONE"))
  emit("Tracked: "..(#s.trackedQuestIDs>0 and table.concat(s.trackedQuestIDs,", ") or "NONE").." / Source: "..(s.watchSource or "unavailable"))
  for _,id in ipairs(s.trackedQuestIDs) do emit("ReadyForTurnIn: "..id.." = "..s.trackedReadyForTurnIn[id]) end
  emit("Completion Behavior: "..s.completionBehavior:upper().." / Auto Select: "..(self.db.autoTrack and "ON" or "OFF"))
  emit("Navigation Mode: "..(s.navigationMode or "NONE").." / Location: "..(s.locationReason or "NONE"))
  emit("Selected ReadyForTurnIn: "..(s.readyForTurnIn==nil and "UNKNOWN" or (s.readyForTurnIn and "YES" or "NO")))
  emit("Auto Candidates: "..(#s.autoCandidates>0 and table.concat(s.autoCandidates,", ") or "NONE"))
  if QN.IsID(s.targetMapID) and QN.IsNumber(s.targetX) and QN.IsNumber(s.targetY) then
    emit(string.format("Target Map: %d / XY: %.2f, %.2f",s.targetMapID,s.targetX*100,s.targetY*100))
  end
end
