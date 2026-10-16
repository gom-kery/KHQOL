local KHQOL=_G.KHQOL
local PU=KHQOL.PositionUtils
local call=KHQOL.PublicCall
local finite,rect=KHQOL.IsPublicNumber,PU.Rect
local function applyPoint(frame,p) return PU.ApplyPoint(frame,p) end
KHQOL.PositionProviders.experienceBar=function(focus)
  local self=KHQOL
  local E,m=self.PositionEditor,self.modules
  local fc=m.clock
  local list={}
  local function add(...) return PU:Add(list,...) end
  local function pointWriter(...) return PU:PointWriter(...) end
  local function lock(...) return PU:Lock(...) end
  local function clockApply() fc:ApplyClock();fc:ApplyLayout() end
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
