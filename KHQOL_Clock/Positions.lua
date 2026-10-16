local KHQOL=_G.KHQOL
local PU=KHQOL.PositionUtils
local call=KHQOL.PublicCall
local finite,rect=KHQOL.IsPublicNumber,PU.Rect
local function applyPoint(frame,p) return PU.ApplyPoint(frame,p) end
KHQOL.PositionProviders.clock=function(focus)
  local self=KHQOL
  local E,m=self.PositionEditor,self.modules
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
    for _,key in ipairs({"date","weekday","money","performance","professions"}) do
      local cfg=fc.db.modules[key]
      if cfg.enabled then
        local names={date="날짜",weekday="요일",money="소지금",performance="FPS / 지연시간",professions="전문기술"}
        add("clock."..key,"clock","Clock · "..names[key],key=="professions" and fc.professionsButton or fc.modules[key],pointWriter(cfg.position),lock(fc.db),clockApply,{parentID="clock"})
      end
    end
    if fc.db.modules.professions.enabled and fc.professionsPanel and fc.professionsPanel:IsShown() then
      add("clock.professions.panel","clock","Clock · 전문기술 목록 (연결)",fc.professionsPanel,nil,lock(fc.db),clockApply,{parentID="clock.professions",linked=true})
    end
    for _,entry in ipairs({{"alert","중앙 알림",fc.alertMessageFrame,560,64},{"tools","알람 / 타이머",fc.clockToolsFrame,390,282},{"stopwatch","스톱워치",fc.stopwatchFrame,300,58}}) do
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
      end,lock(fc.db.clockTools,"positionLocked"),function() self:ApplyEditorPositions() end,{alwaysSave=true})
    end
  end
  PU:ConfigureResets(list,function(t,point)
    if t.id=="clock" then point(t,function() return fc.db.position end,fc.DEFAULTS.position)
    else
      local key=t.id:match("^clock%.(.+)$")
      if key and fc.db.modules[key] then point(t,function() return fc.db.modules[key].position end,fc.DEFAULTS.modules[key].position,{x="x",y="y"})
      elseif key=="alert" or key=="tools" or key=="stopwatch" then
        point(t,function() local d=fc.db.clockTools;d.positions=d.positions or {};d.positions[key]=d.positions[key] or {};return d.positions[key] end,{y=key=="alert" and 160 or key=="tools" and -80 or 110})
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
  local function clockApply() fc:ApplyClock();fc:ApplyLayout() end
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
