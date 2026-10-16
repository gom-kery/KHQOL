local KHQOL=_G.KHQOL
local PU=KHQOL.PositionUtils
local call=KHQOL.PublicCall
local finite,rect=KHQOL.IsPublicNumber,PU.Rect
local function applyPoint(frame,p) return PU.ApplyPoint(frame,p) end
KHQOL.PositionProviders.pvpAlert=function(focus)
  local self=KHQOL
  local E,m=self.PositionEditor,self.modules
  local fc=m.clock
  local list={}
  local function add(...) return PU:Add(list,...) end
  local function pointWriter(...) return PU:PointWriter(...) end
  local function lock(...) return PU:Lock(...) end
  local function clockApply() fc:ApplyClock();fc:ApplyLayout() end
  local pa=m.pvpAlert
  if pa.db then add("pvp","pvpAlert","PvP Alert · 경고 / 보조 목록",pa.frame,pointWriter(pa.db),function() pa.moving=false; pa.frame:EnableMouse(false); pa.moveText:Hide() end,function() pa:ApplyLayout() end,{sample="상대 플레이어 · 주시 중"}) end
  PU:ConfigureResets(list,function(t,point)
    point(t,function() return m.pvpAlert.db end,{y=165})
  end)
  return list
end
