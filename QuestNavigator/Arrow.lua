local _, KHQOL = ...
local QN=KHQOL.modules.questNavigator
local PI,TAU=math.pi,2*math.pi
function QN.Normalize(angle) return angle%TAU end
function QN.SmoothAngle(current,target,factor)
  if current==nil then return QN.Normalize(target) end
  local delta=(target-current+PI)%TAU-PI
  return QN.Normalize(current+delta*factor)
end
-- Map axes: east positive X, south positive Y. Facing: north zero, CCW.
-- Apply the map's actual width/height before atan2 (maps are not square).
function QN.Direction(dx,dy,facing)
  local target=QN.Normalize(math.atan2(-dx,-dy))
  return target,QN.Normalize(target-facing)
end
function QN:ReadPlayerPosition()
  self.playerMapID=QN.Call(C_Map and C_Map.GetBestMapForUnit,"player")
  self.playerX,self.playerY=nil,nil
  if not QN.IsID(self.playerMapID) then return false end
  local position=QN.Call(C_Map and C_Map.GetPlayerMapPosition,self.playerMapID,"player")
  if not QN.IsTable(position) then return false end
  local x,y
  if type(position.GetXY)=="function" then x,y=QN.Call(position.GetXY,position)
  else x,y=position.x,position.y end
  if not QN.IsNumber(x) or not QN.IsNumber(y) or x<0 or x>1 or y<0 or y>1 then return false end
  self.playerX,self.playerY=x,y; return true
end
function QN:ReadMapSize()
  if self.sizeMapID~=self.playerMapID then
    self.sizeMapID=self.playerMapID
    self.mapWidth,self.mapHeight=QN.Call(C_Map and C_Map.GetMapWorldSize,self.playerMapID)
  end
  return QN.IsNumber(self.mapWidth) and self.mapWidth>0 and QN.IsNumber(self.mapHeight) and self.mapHeight>0
end
function QN:UpdateNavigation(rotate,distance)
  local oldState=self.state
  self.distanceYards=nil; self.distanceSq=nil; self.playerFacing=nil
  self.targetAngle=nil; self.relativeAngle=nil
  if not self.targetMapID then self.state="NO_WAYPOINT"
  elseif not self:ReadPlayerPosition() or self.playerMapID~=self.targetMapID then self.state="NAVIGATION_UNAVAILABLE"
  else
    self.playerFacing=QN.Call(GetPlayerFacing)
    if not QN.IsNumber(self.playerFacing) or not self:ReadMapSize() then self.state="NAVIGATION_UNAVAILABLE"
    else
      local dx=(self.targetX-self.playerX)*self.mapWidth
      local dy=(self.targetY-self.playerY)*self.mapHeight
      local sq=dx*dx+dy*dy
      if not QN.IsNumber(sq) then self.state="NAVIGATION_UNAVAILABLE"
      else
        self.state="TRACKING"; self.distanceSq=sq
        -- Avoid arbitrary atan2(0,0) when standing on the waypoint.
        if sq>.01 then
          self.targetAngle,self.relativeAngle=QN.Direction(dx,dy,self.playerFacing)
          if rotate and self.db.showArrow then
            self.currentRotation=QN.SmoothAngle(self.currentRotation,self.relativeAngle,self.db.smoothRotation and self.db.smoothingFactor or 1)
            -- The renderer preserves the positive CCW direction on a tilted plane.
            local ok=QN.Call(self.RotateTexture,self,self.currentRotation)
            self.rotationFailed=not ok
          end
        end
        self.atWaypoint=sq<=.01
        if distance then self.distanceYards=math.floor(math.sqrt(sq)+.5) end
        if self.db.showArrow and self.rotationFailed then self.state="NAVIGATION_UNAVAILABLE" end
      end
    end
  end
  if self.state~="TRACKING" then self.currentRotation=nil; self.atWaypoint=false end
  if distance or oldState~=self.state then self:RenderDistance() end
  if oldState~=self.state then self:Render() else self:RenderArrow() end
end
