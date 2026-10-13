local _, KHQOL = ...
-- Runtime-only source selection and geometry. No module APIs, DBs or frames.
local N={sources={},state="IDLE"}
KHQOL.Navigation=N
function N.IsSecret(v) return issecretvalue and issecretvalue(v) or false end
function N.IsNumber(v)
  return not N.IsSecret(v) and type(v)=="number" and v==v and v~=math.huge and v~=-math.huge
end
function N.IsID(v) return N.IsNumber(v) and v>0 and v%1==0 end
function N.IsText(v) return not N.IsSecret(v) and type(v)=="string" end
function N.IsTable(v) return not N.IsSecret(v) and type(v)=="table" end
function N.Call(fn,...)
  if type(fn)~="function" then return nil end
  local ok,a,b,c=pcall(fn,...); if ok then return a,b,c end
end
function N.ValidPoint(map,x,y)
  return N.IsID(map) and N.IsNumber(x) and N.IsNumber(y) and x>=0 and x<=1 and y>=0 and y<=1
end
local PI,TAU=math.pi,2*math.pi
function N.Normalize(angle) return angle%TAU end
function N.SmoothAngle(current,target,factor)
  if current==nil then return N.Normalize(target) end
  local delta=(target-current+PI)%TAU-PI
  return N.Normalize(current+delta*factor)
end
-- Map axes: east positive X, south positive Y. Facing: north zero, CCW.
function N.Direction(dx,dy,facing)
  local target=N.Normalize(math.atan2(-dx,-dy))
  return target,N.Normalize(target-facing)
end
function N:RegisterSource(source,options)
  if not N.IsText(source) or source=="" then return nil end
  if not self.sources[source] then self.sources[source]={destinations={}} end
  local s=self.sources[source]
  if options then for k,v in pairs(options) do s[k]=v end end
  return s
end
local function validDestination(d,source)
  return N.IsText(source) and source~="" and N.IsTable(d) and N.IsText(d.source) and d.source==source and
    (N.IsID(d.id) or (N.IsText(d.id) and d.id~="")) and N.IsText(d.label) and
    (N.ValidPoint(d.mapID,d.x,d.y) or (d.mapID==nil and d.x==nil and d.y==nil))
end
function N:SetSourceDestinations(source,destinations,options)
  local s=self:RegisterSource(source); if not s then return end
  local result={}
  if N.IsTable(destinations) then
    for _,d in ipairs(destinations) do if validDestination(d,source) then result[#result+1]=d end end
  end
  -- Replace the whole source snapshot; never append stale event candidates.
  local previous=self.activeDestination
  s.destinations=result
  if options and options.pauseOnRemoval and previous and previous.source==source then
    local found=false
    for _,d in ipairs(result) do if d.id==previous.id then found=true; break end end
    if not found then s.paused=true end
  end
  if self.selectionManaged then self:RefreshSelection() end
end
function N:GetSourceDestinations(source)
  local s=self.sources[source]; return s and s.destinations or {}
end
function N:GetActiveDestination() return self.activeDestination end
function N:Clear(preserveRotation)
  self.activeDestination=nil; self.activeSource=nil
  if not preserveRotation then self.currentRotation=nil end
  self.distanceYards=nil; self.distanceSq=nil; self.atWaypoint=false
  self.playerX=nil; self.playerY=nil; self.rotationFailed=nil
  self.playerFacing=nil; self.targetAngle=nil; self.relativeAngle=nil
  self.state="IDLE"
end
function N:SetActiveDestination(destination,preserveRotation)
  self:Clear(preserveRotation)
  if destination and validDestination(destination,destination.source) then
    self:RegisterSource(destination.source); self.activeDestination=destination; self.activeSource=destination.source
    self.state="NO_WAYPOINT"
  end
end
function N:GetPlayerPosition()
  self.playerMapID=N.Call(C_Map and C_Map.GetBestMapForUnit,"player")
  self.playerX,self.playerY=nil,nil
  if not N.IsID(self.playerMapID) then return nil end
  local position=N.Call(C_Map and C_Map.GetPlayerMapPosition,self.playerMapID,"player")
  if not N.IsTable(position) then return nil end
  local x,y
  if type(position.GetXY)=="function" then x,y=N.Call(position.GetXY,position)
  else x,y=position.x,position.y end
  if not N.ValidPoint(self.playerMapID,x,y) then return nil end
  self.playerX,self.playerY=x,y; return self.playerMapID,x,y
end
function N:ReadMapSize()
  if self.sizeMapID~=self.playerMapID then
    self.sizeMapID=self.playerMapID
    self.mapWidth,self.mapHeight=N.Call(C_Map and C_Map.GetMapWorldSize,self.playerMapID)
  end
  return N.IsNumber(self.mapWidth) and self.mapWidth>0 and N.IsNumber(self.mapHeight) and self.mapHeight>0
end
function N:InvalidateMap() self.sizeMapID=nil end
function N:GetOffset(destination)
  if not destination or not N.ValidPoint(destination.mapID,destination.x,destination.y) then return nil end
  if not self:GetPlayerPosition() or self.playerMapID~=destination.mapID or not self:ReadMapSize() then return nil end
  return (destination.x-self.playerX)*self.mapWidth,(destination.y-self.playerY)*self.mapHeight
end
function N:GetDistance(destination)
  local dx,dy=self:GetOffset(destination)
  if dx==nil then return nil end
  local sq=dx*dx+dy*dy
  if N.IsNumber(sq) then return math.sqrt(sq),sq end
end
function N:GetDirection(destination)
  local dx,dy=self:GetOffset(destination)
  if dx==nil or dx*dx+dy*dy<=.01 then return nil end
  return N.Normalize(math.atan2(-dx,-dy))
end
function N:GetRelativeDirection(destination)
  local target=self:GetDirection(destination); local facing=N.Call(GetPlayerFacing)
  if target~=nil and N.IsNumber(facing) then return N.Normalize(target-facing) end
end
local function hints(d)
  local m=N.IsTable(d.metadata) and d.metadata.navigation
  return N.IsTable(m) and m or {}
end
local function idBefore(a,b)
  if type(a)==type(b) then return a<b end
  return tostring(a)<tostring(b)
end
function N:GetNearestDestination(source,excludedID,preferSameRegion)
  local best,bestSq,bestRank,bestLocal
  local playerMap=N.Call(C_Map and C_Map.GetBestMapForUnit,"player")
  local positionRead,positionValid,playerX,playerY,width,height
  for _,d in ipairs(self:GetSourceDestinations(source)) do
    if d.id~=excludedID then
      local h=hints(d)
      -- Sources may supply a native distance metric, including cross-map ranges.
      -- Missing coordinates are allowed for such a candidate, never for geometry.
      local sq=h.distanceSq
      if not N.IsNumber(sq) and N.IsID(playerMap) and N.ValidPoint(d.mapID,d.x,d.y) and d.mapID==playerMap then
        -- Read geometry once per selection, not once per checklist candidate.
        if not positionRead then
          positionRead=true
          local map,x,y=self:GetPlayerPosition()
          positionValid=map==playerMap and self:ReadMapSize()
          playerX,playerY,width,height=x,y,self.mapWidth,self.mapHeight
        end
        if positionValid then
          local dx,dy=(d.x-playerX)*width,(d.y-playerY)*height
          sq=dx*dx+dy*dy
        end
      end
      local rank=N.IsNumber(h.priority) and h.priority or 1
      local isLocal=preferSameRegion and N.IsID(playerMap) and d.mapID==playerMap or false
      if N.IsNumber(sq) and (sq>0 or (sq==0 and self.sources[source] and self.sources[source].allowZero)) and (not best or rank<bestRank or (rank==bestRank and
        ((isLocal and not bestLocal) or (isLocal==bestLocal and
        (sq<bestSq or (sq==bestSq and idBefore(d.id,best.id))))))) then
        best,bestSq,bestRank,bestLocal=d,sq,rank,isLocal
      end
    end
  end
  return best
end
function N:Refresh(rotate,distance,options)
  if rotate==nil and distance==nil then self:RefreshSelection() end
  options=options or {}
  local d=self.activeDestination
  self.distanceYards=nil; self.distanceSq=nil; self.playerFacing=nil
  self.targetAngle=nil; self.relativeAngle=nil
  if not d then self.state="IDLE"
  elseif not N.ValidPoint(d.mapID,d.x,d.y) then self.state="NO_WAYPOINT"
  elseif not self:GetPlayerPosition() or self.playerMapID~=d.mapID then self.state="NAVIGATION_UNAVAILABLE"
  else
    self.playerFacing=N.Call(GetPlayerFacing)
    if not N.IsNumber(self.playerFacing) or not self:ReadMapSize() then self.state="NAVIGATION_UNAVAILABLE"
    else
      local dx=(d.x-self.playerX)*self.mapWidth
      local dy=(d.y-self.playerY)*self.mapHeight
      local sq=dx*dx+dy*dy
      if not N.IsNumber(sq) then self.state="NAVIGATION_UNAVAILABLE"
      else
        self.state="TRACKING"; self.distanceSq=sq
        if sq>.01 then
          self.targetAngle,self.relativeAngle=N.Direction(dx,dy,self.playerFacing)
          if rotate and options.showArrow then
            self.currentRotation=N.SmoothAngle(self.currentRotation,self.relativeAngle,options.smoothRotation and options.smoothingFactor or 1)
          end
        end
        self.atWaypoint=sq<=.01
        if distance then self.distanceYards=math.floor(math.sqrt(sq)+.5) end
      end
    end
  end
  if self.state~="TRACKING" then self.currentRotation=nil; self.atWaypoint=false end
  return self.state
end


function N:SetSourceEnabled(source,enabled)
  local s=self:RegisterSource(source); if not s then return end
  s.enabled=enabled==true; self.selectionManaged=true
  if not s.enabled then
    s.focus=nil; s.hold=nil; s.paused=nil; s.destinations={}
    if self.manual and self.manual.source==source then self.manual=nil end
  end
  self:RefreshSelection()
end
function N:SetSourceFocus(source,destination,preserveRotation)
  local s=self:RegisterSource(source); if not s then return end
  s.focus=destination and validDestination(destination,source) and destination or nil
  self.selectionManaged=true
  self:RefreshSelection(preserveRotation,true)
end
function N:SetSourceHold(source,hold)
  local s=self:RegisterSource(source); if not s then return end
  s.hold=hold==true; self.selectionManaged=true; self:RefreshSelection()
end
function N:FindDestination(source,id)
  for _,d in ipairs(self:GetSourceDestinations(source)) do if d.id==id then return d end end
end
function N:SetManualDestination(source,id)
  local s=self.sources[source]; local d=self:FindDestination(source,id)
  if not s or s.enabled==false or not d or not N.ValidPoint(d.mapID,d.x,d.y) then return false end
  self.manual={source=source,id=id}; s.paused=nil; self.selectionManaged=true
  self:RefreshSelection(); return true
end
function N:ClearManualDestination()
  self.manual=nil
  for _,s in pairs(self.sources) do s.paused=nil end
  self:RefreshSelection()
end
function N:HasAutoPause()
  for _,s in pairs(self.sources) do if s.enabled~=false and s.paused then return true end end
  return false
end
function N:RefreshSelection(preserveRotation,forceFocus)
  if not self.selectionManaged then return end
  local chosen,source
  if self.manual then
    local s=self.sources[self.manual.source]
    chosen=s and s.enabled~=false and self:FindDestination(self.manual.source,self.manual.id) or nil
    if chosen and N.ValidPoint(chosen.mapID,chosen.x,chosen.y) then source=chosen.source
    else self.manual=nil; chosen=nil end
  end
  if not source then
    local order={}
    for key,s in pairs(self.sources) do if s.enabled~=false then order[#order+1]=key end end
    table.sort(order,function(a,b)
      local pa,pb=self.sources[a].priority or 100,self.sources[b].priority or 100
      return pa<pb or (pa==pb and a<b)
    end)
    for _,key in ipairs(order) do
      local s=self.sources[key]
      if s.hold then source=key; break end
      local d=s.focus
      if not d and s.autoSelect and not s.paused then d=self:GetNearestDestination(key) end
      if d then chosen,source=d,key; break end
    end
  end
  local old=self.activeDestination
  local changed=self.activeSource~=source or (old and old.id)~=(chosen and chosen.id) or
    (old and old.mapID)~=(chosen and chosen.mapID) or (old and old.x)~=(chosen and chosen.x) or
    (old and old.y)~=(chosen and chosen.y)
  if changed or (forceFocus and not self.manual and chosen and self.sources[source].focus==chosen) then
    self:SetActiveDestination(chosen,preserveRotation)
  else self.activeDestination=chosen end
  self.activeSource=source
  if self.OnSelectionChanged then self:OnSelectionChanged(changed) end
end
