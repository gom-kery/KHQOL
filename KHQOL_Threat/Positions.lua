local KHQOL=_G.KHQOL
local PU=KHQOL.PositionUtils
local call=KHQOL.PublicCall
local finite,rect=KHQOL.IsPublicNumber,PU.Rect
local function applyPoint(frame,p) return PU.ApplyPoint(frame,p) end
KHQOL.PositionProviders.threat=function(focus)
  local self=KHQOL
  local E,m=self.PositionEditor,self.modules
  local fc=m.clock
  local list={}
  local function add(...) return PU:Add(list,...) end
  local function pointWriter(...) return PU:PointWriter(...) end
  local function lock(...) return PU:Lock(...) end
  local function clockApply() fc:ApplyClock();fc:ApplyLayout() end
  local th=m.threat
  if th.db then add("threat","threat","Threat · 위협 수준",th.root,pointWriter(th.db.position),lock(th.db),function() th:ApplyLayout() end,{sample="위협 수준 78%"}) end
  PU:ConfigureResets(list,function(t,point)
    point(t,function() return m.threat.db.position end,m.threat.defaults.position)
  end)
  return list
end
