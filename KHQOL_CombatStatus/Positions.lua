local KHQOL=_G.KHQOL
local PU=KHQOL.PositionUtils
local call=KHQOL.PublicCall
local finite,rect=KHQOL.IsPublicNumber,PU.Rect
local function applyPoint(frame,p) return PU.ApplyPoint(frame,p) end
KHQOL.PositionProviders.combatStatus=function(focus)
  local self=KHQOL
  local E,m=self.PositionEditor,self.modules
  local fc=m.clock
  local list={}
  local function add(...) return PU:Add(list,...) end
  local function pointWriter(...) return PU:PointWriter(...) end
  local function lock(...) return PU:Lock(...) end
  local function clockApply() fc:ApplyClock();fc:ApplyLayout() end
  local cs=m.combatStatus
  if cs.db then
    local width=cs.db.swordWidth;local showSwords=cs.db.showSwords
    local sample=cs.db.showEnter and cs.db.enterText or (cs.db.showLeave and cs.db.leaveText or "")
    local textWidth=math.max(cs.db.showEnter and #cs.db.enterText or 0,cs.db.showLeave and #cs.db.leaveText or 0)/3*cs.db.fontSize
    local art=showSwords and {{texture="Interface\\AddOns\\KHQOL_CombatStatus\\Media\\CombatStatus\\Sword_Blue.tga",width=width,height=width*1.5,crop=.75,x=-45*width/56},{texture="Interface\\AddOns\\KHQOL_CombatStatus\\Media\\CombatStatus\\Sword_Blue.tga",width=width,height=width*1.5,crop=.75,x=45*width/56}} or {}
    add("combat","combatStatus","Combat Status · 전투 알림",cs.root,pointWriter(cs.db.position),lock(cs.db),function() cs:ApplyLayout() end,
      {sample=sample,sampleSize=cs.db.fontSize,sampleY=showSwords and -width*.75-18 or 0,
       art=art,
       bounds=function(x,y) return x,y,math.max(220,showSwords and width*3 or 0,textWidth),(showSwords and width*1.5 or 0)+2*cs.db.fontSize+40 end})
  end
  PU:ConfigureResets(list,function(t,point)
    point(t,function() return m.combatStatus.db.position end,m.combatStatus.defaults.position)
  end)
  return list
end
