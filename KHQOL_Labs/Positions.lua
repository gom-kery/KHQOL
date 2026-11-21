local KHQOL=_G.KHQOL
local PU=KHQOL.PositionUtils
local function applyPoint(frame,p) return PU.ApplyPoint(frame,p) end
KHQOL.PositionProviders.procAlert=function(focus)
  local self=KHQOL
  local m=self.modules
  local list={}
  local function add(...) return PU:Add(list,...) end
  local proc=m.procAlert
  if proc.db then add("proc","procAlert","발동 버프 · HUD",proc.frame,function(dx,dy)
    proc.db.hud.x=self.PositionStore:Round(proc.db.hud.x+dx*proc.db.hud.scale);proc.db.hud.y=self.PositionStore:Round(proc.db.hud.y+dy*proc.db.hud.scale)
  end,function() proc.unlocked=false;proc.testUntil=nil end,function() proc:Layout();proc:Render() end,{sample="발동 버프 미리보기"}) end
  PU:ConfigureResets(list,function(t,point)
    point(t,function() return m.procAlert.db.hud end,m.procAlert.defaults.hud,{x="x",y="y"});t.resetPhysical=true
  end)
  return list
end
