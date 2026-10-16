local KHQOL=_G.KHQOL
local PU=KHQOL.PositionUtils
local call=KHQOL.PublicCall
local finite,rect=KHQOL.IsPublicNumber,PU.Rect
local function applyPoint(frame,p) return PU.ApplyPoint(frame,p) end
KHQOL.PositionProviders.campfire=function(focus)
  local self=KHQOL
  local E,m=self.PositionEditor,self.modules
  local fc=m.clock
  local list={}
  local function add(...) return PU:Add(list,...) end
  local function pointWriter(...) return PU:PointWriter(...) end
  local function lock(...) return PU:Lock(...) end
  local function clockApply() fc:ApplyClock();fc:ApplyLayout() end
  local cfa=m.campfire
  if cfa.ui then
    add("campfire","campfire","Campfire · 발견 / 진행",cfa.ui.root,pointWriter(cfa.db.position),lock(cfa.db),function() applyPoint(cfa.ui.root,cfa.db.position) end,{sample=cfa.db.message,sampleY=-28,art={{texture=cfa.ICON_FILE_ID,width=cfa.db.iconSize,height=cfa.db.iconSize,y=80}}})
    local complete=cfa.ui.complete
    add("campfire.complete","campfire","Campfire · 효과 획득",complete,function(dx,dy)
      cfa.db.completePosition=cfa.db.completePosition or {point="CENTER",x=0,y=80}
      pointWriter(cfa.db.completePosition)(dx,dy)
    end,lock(cfa.db),function() self:ApplyEditorPositions() end,{sample="야영 효과를 받았습니다!",bounds=function(x,y) return x,y,complete:GetStringWidth()+8,complete:GetStringHeight()+8 end})
  end
  PU:ConfigureResets(list,function(t,point)
    if t.id=="campfire" then point(t,function() return m.campfire.db.position end,m.campfire.defaults.position)
    else point(t,function() m.campfire.db.completePosition=m.campfire.db.completePosition or {};return m.campfire.db.completePosition end,{y=80}) end
  end)
  return list
end
