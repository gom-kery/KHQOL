local KHQOL=_G.KHQOL
local PU=KHQOL.PositionUtils
local function applyPoint(frame,p) return PU.ApplyPoint(frame,p) end
KHQOL.PositionProviders.clock=function(focus)
  local self=KHQOL
  local m=self.modules
  local fc=m.clock
  local list={}
  local function add(...) return PU:Add(list,...) end
  local function pointWriter(...) return PU:PointWriter(...) end
  local function lock(...) return PU:Lock(...) end
  local function clockApply() fc:ApplyClock();fc:ApplyLayout() end
  if fc.db then
    add("clock","clock","Clock · 시간",fc.clockFrame,pointWriter(fc.db.position),lock(fc.db),clockApply,{bounds=function(x,y)
      return x,y,fc.clockFrame.timeText:GetStringWidth()+8,fc.clockFrame.timeText:GetStringHeight()+8
    end})
    for _,key in ipairs({"date","weekday","money","performance","guild"}) do
      local cfg=fc.db.modules[key]
      if cfg.enabled then
        local names={date="날짜",weekday="요일",money="소지금",performance="FPS / 지연시간",guild="길드 접속"}
        add("clock."..key,"clock","Clock · "..names[key],fc.modules[key],pointWriter(cfg.position),lock(fc.db),clockApply,{parentID="clock",sample=key=="guild" and "길드 접속" or nil})
      end
    end
    for _,entry in ipairs({{"alert","중앙 알림",fc.alertMessageFrame},{"tools","알람 / 타이머",fc.clockToolsFrame},{"timerBar","타이머 바",fc.timerBarFrame},{"stopwatch","스톱워치",fc.stopwatchFrame}}) do
      local key=entry[1]; local frame=entry[3]
      add("clock."..key,"clock","Clock · "..entry[2],frame,function(dx,dy)
        local positions=fc.db.clockTools.positions
        if not positions then positions={}; fc.db.clockTools.positions=positions end
        if not positions[key] then
          local status,point,relative,relativePoint,x,y=self.ReadPublicAPI(frame.GetPoint,frame,1)
          if status~="ok" or (relative and relative~=UIParent) or type(point)~="string" or type(relativePoint)~="string"
            or not self.PositionStore:Number(x) or not self.PositionStore:Number(y) then return end
          positions[key]={point=point,relativePoint=relativePoint,x=x,y=y}
        end
        pointWriter(positions[key])(dx,dy)
      end,lock(fc.db.clockTools,key=="timerBar" and "timerBarLocked" or "positionLocked"),function() self:ApplyEditorPositions() end,
      {alwaysSave=true,exactBounds=key=="tools" or key=="timerBar"})
    end
  end
  PU:ConfigureResets(list,function(t,point)
    if t.id=="clock" then point(t,function() return fc.db.position end,fc.DEFAULTS.position)
    else
      local key=t.id:match("^clock%.(.+)$")
      if key and fc.db.modules[key] then point(t,function() return fc.db.modules[key].position end,fc.DEFAULTS.modules[key].position,{x="x",y="y"})
      elseif key and fc.ClockToolPositions[key] then
        point(t,function() local d=fc.db.clockTools;d.positions=d.positions or {};d.positions[key]=d.positions[key] or {};return d.positions[key] end,fc.ClockToolPositions[key])
      end
    end
  end)
  return list
end
KHQOL.PositionProviders.todo=function(focus)
  local self=KHQOL
  local E,m=self.PositionEditor,self.modules
  local fc=m.clock
  local list={}
  local function add(...) return PU:Add(list,...) end
  local function pointWriter(...) return PU:PointWriter(...) end
  local function lock(...) return PU:Lock(...) end
  if fc.db then
    local p=fc.db.todo.window
    local note=fc.todoFrame or E:Virtual("note",p,p.width or 430,p.height or 310)
    add("note","todo","Forever Note",note,pointWriter(p),lock(p,"positionLocked"),function() if fc.todoFrame then applyPoint(fc.todoFrame,p) end end,{bounds=function(x,y,w,h)
      local children={}
      if fc.todoFrame then
        if fc.todoFrame.favoriteList then children[#children+1]=fc.todoFrame.favoriteList end
        if fc.todoFrame.pageJump then children[#children+1]=fc.todoFrame.pageJump end
      end
      return KHQOL.PositionStore:Bounds(note,x,y,w,h,children)
    end})
  end
  PU:ConfigureResets(list,function(t,point)
    point(t,function() return fc.db.todo.window end,fc.DEFAULTS.todo.window)
  end)
  return list
end
