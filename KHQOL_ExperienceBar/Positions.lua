local KHQOL=_G.KHQOL
local PU=KHQOL.PositionUtils
KHQOL.PositionProviders.experienceBar=function(focus)
  local self=KHQOL
  local m=self.modules
  local list={}
  local function add(...) return PU:Add(list,...) end
  local xp=m.experienceBar
  if xp.db and xp.db.mode=="horizontal" then
    add("experience","experienceBar","경험치 바",xp.frame,function(dx,dy)
      xp.db.x=self.PositionStore:Round(xp.db.x+dx*xp.db.scale);xp.db.y=self.PositionStore:Round(xp.db.y+dy*xp.db.scale)
    end,function() xp.unlocked=false end,function() xp:ApplyLayout();xp:Update() end,{sample="경험치 / 평판"})
  end
  PU:ConfigureResets(list,function(t,point)
    point(t,function() return m.experienceBar.db end,m.experienceBar.defaults,{x="x",y="y"});t.resetPhysical=true
  end)
  return list
end
