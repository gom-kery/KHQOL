local K=assert(_G.KHQOL,"Install and enable the KHQOL core addon.")
local FC,N=K.modules.clock,K.Navigation
local UI,call=K.NavigationUI,K.PublicCall
local SOURCE="ForeverNoteRoute"
FC.DEFAULTS.todo.navigation.routeControl={arrivalRadius=10,deviationEnabled=false,deviationThreshold=100}
local function combat() return call(InCombatLockdown)==true end
local function copyPoint(p) return {mapID=p.mapID,x=p.x,y=p.y} end
local function current(plan) return plan and FC.todoPinItems and FC.todoPinItems[plan.ids[plan.index]] end
function FC:GetTodoRouteNavigationOptions() return self:GetTodoNavigationOptions().routeControl end
function FC:GetTodoRouteStatus()
  local p=self.todoPinGuidance
  if not p then return self.todoPinGuidanceLast or "경로 안내 대기" end
  local item=current(p);local point=item and item.waypoint
  return (p.paused and "일시 정지 · " or "").."경유지 "..p.index.." / "..#p.ids.." — "..(point and point.label or "핀")..
    (p.waiting and " · 거리 확인 불가: 다음/이전 수동 이동" or p.offRoute and " · 경로 이탈: 현재 경유지 안내 유지" or "")
end
function FC:PresentTodoPinGuidance(force)
  local plan=self.todoPinGuidance
  if not plan then return end
  local item=current(plan);local p=item and item.waypoint
  if not p then return end
  local status=self:GetTodoRouteStatus()
  if force or status~=plan.lastStatus then
    plan.lastStatus=status
    UI:SetSourcePresentation(SOURCE,{progressText=status,moveHint="Navigation · 드래그 이동"})
  end
end
function FC:ApplyTodoRouteTarget()
  local plan=self.todoPinGuidance
  local item=current(plan);local p=item and item.waypoint
  if not p then return false end
  local r=plan.routeID and self:GetTodoPinRouteByID(plan.routeID)
  local label=r and r.name or "노트 핀 안내"
  if not UI.db then UI:Configure(K:GetNavigationSettings()) end
  N:RegisterSource(SOURCE,{priority=0,autoSelect=false,allowZero=true,
    getOffset=function(d) return FC:GetTodoPointOffset(FC:GetTodoPlayerPoint(),d) end,
    onRouteCancel=function(reason) if FC.todoPinGuidance then FC:StopTodoPinGuidance(false,reason or "안내 종료") end end})
  N:SetSourceEnabled(SOURCE,true);UI:SetClientEnabled(SOURCE,true)
  N:SetSourceDestinations(SOURCE,{{source=SOURCE,id=item.id,label=label,mapID=p.mapID,x=p.x,y=p.y,
    metadata={routeID=plan.routeID,checklistID=item.id,waypointIndex=plan.index,waypointCount=#plan.ids}}})
  self:PresentTodoPinGuidance(true)
  if not N:SetRouteOverride(SOURCE,item.id,plan.paused) then return false end
  UI:Refresh(true,true);UI:Render();return true
end
function FC:StopTodoPinGuidance(clear,reason)
  local plan=self.todoPinGuidance
  if not plan then return end
  self.todoPinGuidance=nil
  self.todoPinGuidanceLast=reason or "경로 안내 종료"
  if clear and N.routeOverride and N.routeOverride.source==SOURCE then N:ClearRouteOverride(reason) end
  N:SetSourceDestinations(SOURCE,{});N:SetSourceEnabled(SOURCE,false)
  if UI.db then UI:SetClientEnabled(SOURCE,false);UI:Refresh(true,true);UI:Render() end
  self:RefreshTodoMapPins()
end
local function routeUnchanged(plan)
  if plan.pages~=FC.db.todo.pages or plan.generation~=K.profileGeneration or not FC:IsTodoCoordinateEnabled() then return false end
  if plan.routeID then
    local r=FC:GetTodoPinRouteByID(plan.routeID)
    if not r or r~=plan.route or r.navigationEnabled==false or (r.revision or 0)~=plan.revision or #r.pinIDs~=#plan.ids then return false end
    for i,id in ipairs(plan.ids) do if r.pinIDs[i]~=id then return false end end
  end
  return true
end
function FC:StartTodoPinGuidance(ticket,mode)
  if not self:ValidateTodoPinRouteTicket(ticket) then return false end
  local route=self:GetTodoPinRoute(nil)
  local selected=self:TodoPinRoutePosition(ticket.id)
  if selected and (route.navigationEnabled==false or #route.pinIDs>128) then
    self:NoteCoordinateMessage(route.navigationEnabled==false and "선택 경로의 안내 사용을 켜세요." or "경로를 128개 이하로 정리한 뒤 안내하세요.");return false
  end
  self:GetTodoMapPinPoints()
  local ids={}
  if selected then for i,id in ipairs(route.pinIDs) do ids[i]=id end else ids[1]=ticket.id end
  local index=selected or 1
  local player=self:GetTodoPlayerPoint()
  if mode=="first" then index=1
  elseif mode=="nearest" and player then
    local best
    for i,id in ipairs(ids) do
      local item=self.todoPinItems[id];local dx,dy
      if item then dx,dy=self:GetTodoPointOffset(player,item.waypoint) end
      if dx and (not best or dx*dx+dy*dy<best) then index=i;best=dx*dx+dy*dy end
    end
  end
  local points={}
  for _,id in ipairs(ids) do
    local item=self.todoPinItems[id];local p=item and item.waypoint
    if not p then self:NoteCoordinateMessage("경로의 핀을 확인할 수 없습니다. 경유지를 다시 확인하세요.");return false end
    points[id]=copyPoint(p)
  end
  if self.todoPinGuidance then self:StopTodoPinGuidance(true,"경로 안내 다시 시작") end
  if self.todoRouteDrawing then self:FinishTodoRouteDrawing(false,self.todoRouteDrawing) end
  self.todoPinGuidance={routeID=selected and route.id or nil,route=selected and route or nil,revision=selected and route.revision or nil,
    ids=ids,index=index,points=points,pages=self.db.todo.pages,generation=K.profileGeneration,anchor=player and copyPoint(player),paused=false}
  self.todoPinGuidanceLast=nil
  if not self:ApplyTodoRouteTarget() then self:StopTodoPinGuidance(true,"안내 시작 실패");return false end
  self:RefreshTodoRouteView();return true
end
function FC:StartTodoSavedRoute(mode)
  if combat() then return false end
  local r=self:GetTodoPinRoute(nil)
  if not r or #r.pinIDs==0 then self:NoteCoordinateMessage("선택한 경로에 핀을 추가하세요.");return false end
  local ticket=self:CreateTodoPinRouteTicket(r.pinIDs[1])
  return ticket and self:StartTodoPinGuidance(ticket,mode or "first") or false
end
function FC:ControlTodoPinGuidance(action,expected)
  local p=self.todoPinGuidance
  if combat() or not p or expected and p~=expected or not self:ValidateTodoPinGuidance() then return false end
  if action=="stop" then self:StopTodoPinGuidance(true,"경로 안내 종료");return true end
  if action=="pause" then
    p.paused=true
  elseif action=="resume" then
    p.paused=false
  elseif action=="next" then
    if p.index>=#p.ids then self:StopTodoPinGuidance(true,"경로 완료");self:NoteCoordinateMessage("경로 안내를 완료했습니다.");return true end
    p.index=p.index+1
  elseif action=="previous" and p.index>1 then p.index=p.index-1
  else return false end
  p.waiting=nil;p.offRoute=nil
  if not self:ApplyTodoRouteTarget() then self:StopTodoPinGuidance(true,"경유지 변경 실패");return false end
  self:RefreshTodoRouteView();return true
end
local function deviation(plan,player,p)
  if not FC:GetTodoRouteNavigationOptions().deviationEnabled then return end
  local previous=plan.index>1 and plan.points[plan.ids[plan.index-1]] or plan.anchor
  if not previous then return end
  local ax,ay=FC:GetTodoPointOffset(previous,player)
  local bx,by=FC:GetTodoPointOffset(previous,p)
  if not ax or not bx then return end
  local length=bx*bx+by*by
  if length<.01 then return end
  local t=math.max(0,math.min(1,(ax*bx+ay*by)/length))
  local dx,dy=ax-bx*t,ay-by*t
  local threshold=FC:GetTodoRouteNavigationOptions().deviationThreshold
  threshold=N.IsNumber(threshold) and math.max(20,math.min(1000,threshold)) or 100
  return dx*dx+dy*dy>threshold*threshold
end
function FC:ValidateTodoPinGuidance()
  local plan=self.todoPinGuidance
  if not plan then return false end
  if not routeUnchanged(plan) or not N.routeOverride or N.routeOverride.source~=SOURCE then self:StopTodoPinGuidance(true,"경로 데이터·프로필 변경으로 안내 종료");return false end
  self:GetTodoMapPinPoints()
  for _,id in ipairs(plan.ids) do
    local item=self.todoPinItems[id];local p=item and item.waypoint;local expected=plan.points[id]
    if not p or p.mapID~=expected.mapID or p.x~=expected.x or p.y~=expected.y then self:StopTodoPinGuidance(true,"경유지 좌표 변경으로 안내 종료");return false end
  end
  return true
end
function FC:UpdateTodoPinGuidance()
  local plan=self.todoPinGuidance
  if not plan or combat() or not self:ValidateTodoPinGuidance() then return end
  if plan.paused then return end
  local player=self:GetTodoPlayerPoint()
  if not plan.anchor and player then plan.anchor=copyPoint(player) end
  local radius=self:GetTodoRouteNavigationOptions().arrivalRadius
  radius=N.IsNumber(radius) and math.max(3,math.min(50,radius)) or 10
  local advanced=false
  while plan.index<=#plan.ids do
    local p=current(plan).waypoint
    local dx,dy=self:GetTodoPointOffset(player,p)
    plan.waiting=dx==nil;plan.offRoute=not plan.waiting and deviation(plan,player,p) or nil
    if dx==nil or dx*dx+dy*dy>radius*radius then break end
    plan.index=plan.index+1;advanced=true
  end
  if plan.index>#plan.ids then
    self:StopTodoPinGuidance(true,"경로 완료");self:NoteCoordinateMessage("경로 안내를 완료했습니다.");return
  end
  if advanced then
    if not self:ApplyTodoRouteTarget() then self:StopTodoPinGuidance(true,"경유지 변경 실패");return end
    self:RefreshTodoRouteView()
  else self:PresentTodoPinGuidance(false) end
end
