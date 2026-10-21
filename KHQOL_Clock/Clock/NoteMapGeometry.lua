local K=assert(_G.KHQOL,"Install and enable the KHQOL core addon.")
local FC,N=K.modules.clock,K.Navigation
local call=K.PublicCall
local bases={}
local function vector(x,y) return call(CreateVector2D,x,y) end
local function xy(p)
  if not p or N.IsSecret(p) then return end
  local x,y=call(p.GetXY,p)
  if N.IsNumber(x) and N.IsNumber(y) then return x,y end
end
-- Native world vectors are north/west axes. Map coordinates are east/south.
function FC:GetTodoMapBasis(mapID)
  if not N.IsID(mapID) or mapID==947 then return end
  if bases[mapID] then return bases[mapID] end
  local world,p=call(C_Map and C_Map.GetWorldPosFromMapPos,mapID,vector(.5,.5))
  local x,y=xy(p)
  local width,height=call(C_Map and C_Map.GetMapWorldSize,mapID)
  if N.IsNumber(world) and world>=0 and x and N.IsNumber(width) and width>0 and N.IsNumber(height) and height>0 then
    local b={world=world,top=x+height/2,left=y+width/2,width=width,height=height}
    local count=0;for _ in pairs(bases) do count=count+1 end
    if count>=128 then bases={} end
    bases[mapID]=b;return b
  end
end
function FC:InvalidateTodoMapGeometry() bases={} end
function FC:GetTodoWorldPoint(point)
  if type(point)~="table" or not N.ValidPoint(point.mapID,point.x,point.y) then return end
  local b=self:GetTodoMapBasis(point.mapID)
  if b then return b.world,b.top-point.y*b.height,b.left-point.x*b.width end
  local world,p=call(C_Map and C_Map.GetWorldPosFromMapPos,point.mapID,vector(point.x,point.y))
  local x,y=xy(p)
  if N.IsNumber(world) and world>=0 and x then return world,x,y end
end
-- Forever's two continent placements on Azeroth map 947. Numerical map
-- calibration also used by HereBeDragons (BSD); native rectangles take priority.
-- These are display transforms, never a connection across oceans/instances.
local azeroth={
  [0]={width=44688.53,height=29795.12,left=32601.03,top=9894.93},
  [1]={width=44878.66,height=29916.1,left=8723.96,top=14824.53},
}
function FC:ProjectTodoPoint(point,target)
  if type(point)~="table" or not N.ValidPoint(point.mapID,point.x,point.y) or not N.IsID(target) then return end
  if point.mapID==target then return point.x,point.y end
  local minX,maxX,minY,maxY=call(C_Map and C_Map.GetMapRectOnMap,point.mapID,target)
  if N.IsNumber(minX) and N.IsNumber(maxX) and N.IsNumber(minY) and N.IsNumber(maxY) and maxX>minX and maxY>minY then
    return minX+(maxX-minX)*point.x,minY+(maxY-minY)*point.y
  end
  local world,x,y=self:GetTodoWorldPoint(point)
  if not x then return end
  local b=target==947 and azeroth[world] or self:GetTodoMapBasis(target)
  if b and (target==947 or b.world==world) then return (b.left-y)/b.width,(b.top-x)/b.height end
  local result,p=call(C_Map and C_Map.GetMapPosFromWorldPos,world,vector(x,y),target)
  if result==target then return xy(p) end
end
function FC:GetTodoPlayerPoint()
  local map=call(C_Map and C_Map.GetBestMapForUnit,"player")
  if not N.IsID(map) then return end
  local x,y=xy(call(C_Map and C_Map.GetPlayerMapPosition,map,"player"))
  if N.ValidPoint(map,x,y) then return {mapID=map,x=x,y=y} end
end
function FC:GetTodoPointOffset(origin,target)
  if not origin or not target then return end
  if origin.mapID==target.mapID and N.ValidPoint(origin.mapID,origin.x,origin.y) and N.ValidPoint(target.mapID,target.x,target.y) then
    local basis=self:GetTodoMapBasis(origin.mapID)
    local w,h
    if basis then w,h=basis.width,basis.height else w,h=call(C_Map and C_Map.GetMapWorldSize,origin.mapID) end
    if N.IsNumber(w) and w>0 and N.IsNumber(h) and h>0 then return (target.x-origin.x)*w,(target.y-origin.y)*h end
  end
  local a,x,y=self:GetTodoWorldPoint(origin)
  local b,tx,ty=self:GetTodoWorldPoint(target)
  if x and tx and a==b then return y-ty,x-tx end
end
function FC:TodoPointsShareWorld(a,b)
  if a.mapID==b.mapID then return true end
  local w,x=self:GetTodoWorldPoint(a);local v,y=self:GetTodoWorldPoint(b)
  return x~=nil and y~=nil and w==v
end
function FC:ResolveTodoMapClick(mapID,x,y)
  if mapID~=947 then return mapID,x,y end
  local info=call(C_Map and C_Map.GetMapInfoAtPosition,mapID,x,y)
  if not info or not N.IsID(info.mapID) or info.mapID==947 then return end
  local minX,maxX,minY,maxY=call(C_Map and C_Map.GetMapRectOnMap,info and info.mapID,mapID)
  if info and N.IsNumber(minX) and N.IsNumber(maxX) and N.IsNumber(minY) and N.IsNumber(maxY) and maxX>minX and maxY>minY then
    local px,py=(x-minX)/(maxX-minX),(y-minY)/(maxY-minY)
    if N.ValidPoint(info.mapID,px,py) then return info.mapID,px,py end
  end
  local b=info and self:GetTodoMapBasis(info.mapID)
  local world=b and azeroth[b.world]
  if b and world then
    local px=(b.left-(world.left-x*world.width))/b.width
    local py=(b.top-(world.top-y*world.height))/b.height
    if N.ValidPoint(info.mapID,px,py) then return info.mapID,px,py end
  end
end
-- A segment may cross this zone while either endpoint is on another zone.
-- Clip geometry before allocating dots so off-map spans consume no pool.
function FC:ClipTodoMapSegment(x1,y1,x2,y2)
  if not (N.IsNumber(x1) and N.IsNumber(y1) and N.IsNumber(x2) and N.IsNumber(y2)) then return end
  local dx,dy=x2-x1,y2-y1
  if dx*dx+dy*dy<1e-16 then return end
  local low,high=0,1
  local function clip(p,q)
    if p==0 then return q>=0 end
    local t=q/p
    if p<0 then if t>high then return false end;low=math.max(low,t)
    else if t<low then return false end;high=math.min(high,t) end
    return true
  end
  if clip(-dx,x1) and clip(dx,1-x1) and clip(-dy,y1) and clip(dy,1-y1) and high-low>1e-10 then
    return x1+low*dx,y1+low*dy,x1+high*dx,y1+high*dy
  end
end
