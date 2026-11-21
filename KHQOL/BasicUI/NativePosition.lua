local _,KHQOL=...
local call=KHQOL.PublicCall
local finite=KHQOL.IsPublicNumber
local Native={}
KHQOL.NativePosition=Native
local function nativePoints(f)
  local n=call(f.GetNumPoints,f);if not finite(n) or n<0 or n>32 or n~=math.floor(n) then return end
  local points={}
  for i=1,n do
    local status,p,r,rp,x,y=KHQOL.ReadPublicAPI(f.GetPoint,f,i);if status~="ok" then return end
    points[i]={n=5,p,r,rp,x,y}
  end
  return points
end
-- AuraContainer anchors can resolve to secret geometry. Capture the PUBLIC
-- native SetPoint arguments, rather than comparing resolved secret coordinates.
function Native:Hook(state,reapply)
  if state.positionHook then return end
  state.positionHook=true;state.originalPoints=nativePoints(state.frame)
  hooksecurefunc(state.frame,"SetPoint",function(f,...)
    if state.positionWriting or state.releasing then return end
    local point={n=select("#",...),...}
    for i=1,point.n do if not KHQOL.IsPublicValue(point[i]) then
      state.originalPoints=nil;state.positionOwned=nil;self.pending=true;self.propertyDeferred=true;return
    end end
    if type(point[1])~="string" then return end
    state.originalPoints={point}
    local active
    if state.canApply then active=state.canApply() else active=self:IsEnabled() end
    if active then reapply() end
  end)
end
function Native:Write(state,points)
  if not state.originalPoints then self.pending=true;self.propertyDeferred=true;return false end
  state.positionWriting=true
  state.positionOwned=true
  local ok=pcall(function()
    state.frame:ClearAllPoints()
    for _,p in ipairs(points) do state.frame:SetPoint(unpack(p,1,p.n or 5)) end
  end)
  state.positionWriting=false
  if not ok then self.pending=true;self.propertyDeferred=true end
  return ok
end
function Native:Release(state)
  if state.positionOwned and state.originalPoints then
    state.positionWriting=true
    local ok=pcall(function() state.frame:ClearAllPoints();for _,p in ipairs(state.originalPoints) do state.frame:SetPoint(unpack(p,1,p.n or 5)) end end)
    state.positionWriting=false
    if ok then state.positionOwned=nil else self.pending=true;self.propertyDeferred=true end
  end
  return not state.positionOwned
end
local function samePoints(a,b)
  if not a or not b or #a~=#b then return false end
  for i=1,#a do
    for j=1,5 do if a[i][j]~=b[i][j] then return false end end
  end
  return true
end

-- Managed roots can receive a batch of anchors from a native layout. Sample
-- after that layout finishes and leave a later external change in place.
function Native:WriteTracked(state,desired)
  local current=nativePoints(state.frame)
  if not current or #current==0 then return false end
  if samePoints(current,state.lastPoints) then
    if samePoints(desired,state.requestedPoints) then return true end
  else
    state.originalPoints=current
  end
  if not self:Write(state,desired) then return false end
  state.lastPoints=nativePoints(state.frame)
  state.requestedPoints=desired
  return state.lastPoints~=nil
end

function Native:ReleaseTracked(state)
  local current=nativePoints(state.frame)
  if not current then return false end
  if state.lastPoints and #current>0 and not samePoints(current,state.lastPoints) then state.positionOwned=nil end
  if not self:Release(state) then return false end
  state.lastPoints,state.requestedPoints=nil,nil
  return true
end
Native.Read=nativePoints
