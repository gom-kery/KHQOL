local K=_G.KHQOL
local CFA=K.modules.campfire
local function field(v)
  if not K.IsPublicValue(v) then return {status="secret"} end
  if v==nil then return {status="none"} end
  if not K.IsPublicNumber(v) then return {status="invalid"} end
  return {status="number",value=v}
end
function CFA:ReadCampfirePosition(objectID)
  local row={objectID=objectID,coordinateSystem="unverified",calculable=false}
  if type(ClosestGameObjectPosition)~="function" then row.status="missing-api";return row end
  local ok,x,y,d=pcall(ClosestGameObjectPosition,objectID)
  if not ok then row.status="call-error";return row end
  -- Never compare, stringify, format or do arithmetic on raw API returns.
  row.x,row.y,row.distance=field(x),field(y),field(d)
  if row.x.status=="secret" or row.y.status=="secret" or row.distance.status=="secret" then row.status="secret"
  elseif row.x.status=="none" and row.y.status=="none" and row.distance.status=="none" then row.status="no-returns"
  elseif row.x.status=="number" and row.y.status=="number" and row.distance.status=="number" then row.status="coordinate-system-unverified"
  else row.status="partial-or-invalid" end
  return row
end
function CFA:ReadCampfirePositions()
  local rows={}
  for _,id in ipairs(self.CAMPFIRE_GAMEOBJECT_IDS) do rows[#rows+1]=self:ReadCampfirePosition(id) end
  self.lastPositionSnapshot=rows
  return rows
end
local function display(value)
  if not value then return "none" end
  if value.status=="number" then return string.format("%.4f",value.value) end
  return value.status
end
function CFA:DiagnoseCampfireCoordinates(label)
  label=type(label)=="string" and label or "sample"
  label=label:gsub("[%z\1-\31\127|]",""):sub(1,64)
  local snapshot={label=label,rows=self:ReadCampfirePositions(),coordinateSystem="unverified",calculable=false}
  local okFacing,facing=false,nil
  if type(GetPlayerFacing)=="function" then okFacing,facing=pcall(GetPlayerFacing) end
  snapshot.facing=okFacing and field(facing) or {status="missing-or-error"}
  -- Read raw player outputs individually so a secret fourth field cannot leak.
  if type(UnitPosition)=="function" then
    local ok,x,y,z,instance=pcall(UnitPosition,"player")
    if ok then snapshot.player={x=field(x),y=field(y),z=field(z),instance=field(instance)} end
  end
  local samples=self.coordinateSamples or {};self.coordinateSamples=samples
  samples[#samples+1]=snapshot
  if #samples>12 then table.remove(samples,1) end
  self:Print("좌표 진단 ["..label.."] · 좌표계 확인 필요 · 방향 계산/화살표 보류")
  for _,row in ipairs(snapshot.rows) do
    self:Print("Object "..row.objectID.." · "..row.status.." · X="..display(row.x).." Y="..display(row.y).." D="..display(row.distance))
  end
  self:Print("플레이어 방향="..display(snapshot.facing))
  local p=snapshot.player
  self:Print(p and ("플레이어 위치 X="..display(p.x).." Y="..display(p.y).." Z="..display(p.z).." instance="..display(p.instance)) or "플레이어 위치 API 없음/호출 실패")
  return snapshot
end
function CFA:PrintCoordinateSamples()
  self:Print("보관된 진단 표본 "..#(self.coordinateSamples or {}).."개 (이번 세션만, 최근 12개)")
  for _,sample in ipairs(self.coordinateSamples or {}) do
    self:Print("["..sample.label.."] 방향="..display(sample.facing))
    for _,row in ipairs(sample.rows) do self:Print("Object "..row.objectID.." "..row.status.." X="..display(row.x).." Y="..display(row.y).." D="..display(row.distance)) end
  end
end
