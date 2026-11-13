local K=_G.KHQOL
local R=K.ModuleRegistry
R:Register("clock",{variable="ForeverClockDB",setEnabled=function(m,on)
  if m and m.SetHUDShown then m:SetHUDShown(on) end
end})
R:Register("todo",{owner="clock",requires={"clock"},setEnabled=function(_,on)
  local fc=K.modules.clock
  if fc.todoFrame and not on then fc.todoFrame:Hide() end
  if fc.UpdateTodoMinimapButton then fc:UpdateTodoMinimapButton() end
  if fc.RefreshTodoNavigation then fc:RefreshTodoNavigation() end
end})
do local spec=R.entries.clock
  if not spec.positions then spec.positions=function(m,focus,K) local provider=K.PositionProviders.clock;return provider and provider(focus,K) or {} end end
  spec.applyProfile=function(m,K)
  if not m.initialized then return end
  m.db=ForeverClockDB;m:ApplyAll()
  if m.todoFrame then
    local p=m.db.todo.window
    m.todoFrame:ClearAllPoints();m.todoFrame:SetPoint(p.point,UIParent,p.relativePoint,p.x,p.y)
    m.todoFrame:SetSize(p.width,p.height);m:UpdateTodoEscapeBinding();m:RefreshTodo()
  end
  m:UpdateTodoMinimapButton();K.NavigationUI:Configure(K:GetNavigationSettings());m:RefreshTodoNavigation()
  if m.RefreshClockTools then m:RefreshClockTools() end
  end
  spec.closeEditors=function(m,K)
  local fc=m
  if fc and fc.db then
    for _,entry in ipairs({{"tools",fc.clockToolsFrame},{"timerBar",fc.timerBarFrame},{"stopwatch",fc.stopwatchFrame},{"alert",fc.alertMessageFrame}}) do
      if entry[2] and entry[2].positionMoving then fc:SaveClockTool(entry[2],entry[1]) end
    end
    if fc.todoFrame and fc.todoFrame:IsShown() then fc.todoFrame:StopMovingOrSizing();fc:SaveTodoWindow() end
    if fc.clockFrame and fc.clockFrame.dragStartX then
      fc.clockFrame:StopMovingOrSizing();K.PositionStore:Point(fc.clockFrame,fc.db.position)
      fc.clockFrame.dragStartX,fc.clockFrame.dragStartY=nil,nil
    end
    for key,frame in pairs(fc.modules or {}) do
      if frame.dragStartX then frame:StopMovingOrSizing();fc:SetModulePosition(key,frame);frame.dragStartX,frame.dragStartY=nil,nil end
    end
  end

  end
  spec.editorPositions=function(m,K)
    if not m.db then return end
    local positions=m.db.clockTools.positions or {}
    local point=K.PositionUtils.ApplyPoint
    local defaults=m.ClockToolPositions
    point(m.alertMessageFrame,positions.alert or defaults.alert);point(m.clockToolsFrame,positions.tools or defaults.tools)
    point(m.stopwatchFrame,positions.stopwatch or defaults.stopwatch);point(m.timerBarFrame,positions.timerBar or defaults.timerBar)
  end
  spec.finishDrags=function(m)
    for _,entry in ipairs({{"tools",m.clockToolsFrame},{"timerBar",m.timerBarFrame},{"stopwatch",m.stopwatchFrame},{"alert",m.alertMessageFrame}}) do
      if entry[2] and entry[2].positionMoving then m:SaveClockTool(entry[2],entry[1]) end
    end
  end
  spec.alertFrames=function(m,K)
  return {{frame=m.alertMessageFrame,priority=20,allowed=function() return not m.alertMessageFrame.isTest end}}
  end
end
do local spec=R.entries.todo
  if not spec.positions then spec.positions=function(m,focus,K) local provider=K.PositionProviders.todo;return provider and provider(focus,K) or {} end end
  spec.dragFrames=function(m,K) return {K.modules.clock.todoMinimapButton} end
end
