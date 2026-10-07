local _, KHQOL = ...
local QN = KHQOL.modules.questNavigator
QN.VERSION = "0.1.5"
QN.defaults = {
  autoTrack=true, preferSameRegion=false, showArrow=true, arrowSize=64, arrowAlpha=1, arrowTilt=55,
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
  KHQOL.MergeDefaults(db,self.defaults,"types")
  db.arrowSize=clamp(db.arrowSize,32,128,64); db.arrowAlpha=clamp(db.arrowAlpha,.1,1,1)
  db.arrowTilt=clamp(db.arrowTilt,0,70,55)
  db.positionX=clamp(db.positionX,-10000,10000,0); db.positionY=clamp(db.positionY,-10000,10000,180)
  db.arrowUpdateInterval=clamp(db.arrowUpdateInterval,.05,.5,.10)
  db.distanceUpdateInterval=clamp(db.distanceUpdateInterval,.1,1,.25)
  db.smoothingFactor=clamp(db.smoothingFactor,.01,1,.25)
  if db.progressMode~="numeric" and db.progressMode~="text" then db.progressMode="numeric" end
  if db.distanceUnit~="yards" and db.distanceUnit~="meters" then db.distanceUnit="yards" end
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
function QN:OnEvent(event, questID)
  if not self.active then return end
  if event=="SUPER_TRACKING_CHANGED" then
    if self.settingSuperTrack then return end
    local id=self:GetTrackedQuest()
    -- A user selection wins during the completion pause; clearing a turned-in
    -- quest does not cancel the queued next-quest selection.
    if self.phase then
      if (id and id~=self.completedQuestID) or self:OtherNavigationActive() then
        self:CancelTransition(); self:AdoptQuest(id)
      end
    elseif not id and self.currentQuestID and not self:OtherNavigationActive() then
      -- Blizzard may synchronously clear SuperTrack BEFORE delivering our
      -- QUEST_TURNED_IN handler. Keep the old ID through this debounce window.
      self:MarkDirty(true)
    else self:AdoptQuest(id) end
  elseif event=="QUEST_TURNED_IN" and QN.IsID(questID) and questID==self.currentQuestID then
    self:BeginCompletion(questID)
  end
  if event=="PLAYER_ENTERING_WORLD" or event=="ZONE_CHANGED_NEW_AREA" or event=="ZONE_CHANGED" then
    self.sizeMapID=nil
  end
  local waypointOnly=event=="QUEST_POI_UPDATE" or event=="SUPER_TRACKING_PATH_UPDATED" or event=="ZONE_CHANGED" or event=="ZONE_CHANGED_NEW_AREA" or event=="SUPER_TRACKING_CHANGED"
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
  self.currentRotation=nil; self.state="IDLE"; self.arrowElapsed=0; self.distanceElapsed=0
  self:ApplyLayout(); self:Render()
  if not self.active then return end
  for _,event in ipairs(EVENTS) do
    -- All names are present in Forever source. Also check the running beta build.
    local valid=QN.Call(C_EventUtils and C_EventUtils.IsEventValid,event)
    if not QN.IsFalse(valid) then QN.Call(self.events.RegisterEvent,self.events,event) end
  end
  self:RefreshQuest(); self:UpdateDriver()
end
function QN:Changed(key)
  if self.dragging and (key=="locked" or key=="position") then self:SavePosition() end
  self:ApplyLayout()
  if not self.active then return end
  if key=="progressMode" then self:RefreshProgress() end
  if not self.phase and self.currentQuestID and self.state~="COMPLETED" then self:UpdateNavigation(true,true) end
  self:Render(); self:UpdateDriver()
end
-- Explicit developer inspection only; release operation never emits chat output.
function QN:GetDebugSnapshot()
  return {
    version=self.VERSION, state=self.state, currentQuestID=self.currentQuestID,
    targetQuestID=self.targetQuestID, lastCompletedQuestID=self.lastCompletedQuestID,
    playerMapID=self.playerMapID, targetMapID=self.targetMapID, waypointSource=self.waypointSource,
    playerX=self.playerX, playerY=self.playerY, targetX=self.targetX, targetY=self.targetY,
    distanceSq=self.distanceSq, playerFacing=self.playerFacing, targetAngle=self.targetAngle,
    relativeAngle=self.relativeAngle, currentRotation=self.currentRotation,
  }
end
