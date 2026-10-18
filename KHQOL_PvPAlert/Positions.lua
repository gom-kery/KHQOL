local KHQOL=_G.KHQOL
local PU=KHQOL.PositionUtils
KHQOL.PositionProviders.pvpAlert=function(focus)
  local self=KHQOL
  local m=self.modules
  local list={}
  local function add(...) return PU:Add(list,...) end
  local function pointWriter(...) return PU:PointWriter(...) end
  local pa=m.pvpAlert
  if pa.db then add("pvp","pvpAlert","PvP Alert · 경고 / 보조 목록",pa.frame,pointWriter(pa.db),function() pa.moving=false; pa.frame:EnableMouse(false); pa.moveText:Hide() end,function() pa:ApplyLayout() end,{sample="상대 플레이어 · 주시 중"}) end
  PU:ConfigureResets(list,function(t,point)
    point(t,function() return m.pvpAlert.db end,{y=165})
  end)
  return list
end
