local K=assert(_G.KHQOL, "Install and enable the KHQOL core addon.")
local FC=K.modules.clock
local N=K.Navigation
local function trim(t) return t:match("^%s*(.-)%s*$") end
function FC:NoteCoordinateMessage(text)
  if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff72ada5Forever Note:|r "..text) end
end
function FC:IsTodoCoordinateEnabled()
  return self.db and self.db.todo and K.db and K:GetEnabled("todo")==true
end
function FC:FindTodoWaypoint(id)
  local found,pageFound,listFound,indexFound
  for _,page in ipairs(self.db and self.db.todo and self.db.todo.pages or {}) do
    local function visit(list)
      for index,item in ipairs(list or {}) do
        if type(item)=="table" and item.id==id and type(item.waypoint)=="table" then
          found,pageFound,listFound,indexFound=item,page,list,index
        end
      end
    end
    visit(page.individualTasks or page.tasks)
    for _,group in ipairs(page.groups or {}) do visit(group.tasks) end
  end
  return found,pageFound,listFound,indexFound
end
local function decimal(value)
  return (string.format("%.5f",value*100):gsub("0+$",""):gsub("%.$",""))
end
function FC:CommitTodoCoordinateChange()
  if self.todoFrame then self:RefreshTodo() else self:RefreshTodoNavigation() end
end
function FC:AddTodoCoordinate(mapID,x,y,label)
  if not self:IsTodoCoordinateEnabled() then return nil,"편의 기능에서 노트 사용을 먼저 켜세요." end
  if not N.ValidPoint(mapID,x,y) or not self:GetTodoMapInfo(mapID) then return nil,"지역 또는 좌표를 확인할 수 없습니다." end
  if not N.IsText(label) or #label>512 or label:find("[\r\n]") then return nil,"메모는 줄바꿈 없이 512바이트 이내로 입력하세요." end
  label=trim(label);if label=="" then label="노트 위치" end
  -- Only our dedicated checklist is reused. Never convert/overwrite a user's
  -- text page merely because its title also happens to be '좌표'.
  local page
  for _,p in ipairs(self.db.todo.pages or {}) do if p.coordinatePage==true and p.mode=="checklist" then page=p;break end end
  if not page then
    page={title="좌표",mode="checklist",coordinatePage=true,individualTasks={},groups={},text=""}
    self.db.todo.pages[#self.db.todo.pages+1]=page
  end
  self:EnsureTodoGroups(page)
  local item={text="/way #"..mapID.." "..decimal(x).." "..decimal(y).." "..label,done=false,
    waypoint={mapID=mapID,x=x,y=y,label=label,mapSelector="#"..mapID}}
  page.individualTasks[#page.individualTasks+1]=item
  self:CommitTodoCoordinateChange()
  return item
end
function FC:ParseNoteCoordinateCommand(message)
  if not N.IsText(message) or #message>2048 then return nil end
  local command,body=trim(message):match("^(%S+)%s+(.+)$")
  if not command or command:lower()~="way" then return nil end
  -- Numeric mapID is accepted only when three leading numbers are supplied.
  -- #mapID remains the unambiguous form when a memo itself starts with a number.
  local map,x,y,label=body:match("^(%d+)%s+(%S+)%s+(%S+)%s*(.*)$")
  if map and tonumber(x)~=nil and tonumber(y)~=nil then
    map=tonumber(map)
    if not self:GetTodoMapInfo(map) then return nil end
    local px,py,text=self:ParseTodoWaypoint("/way #"..map.." "..x.." "..y.." "..label)
    if not N.ValidPoint(map,px,py) then return nil end
    return map,px,py,text
  end
  local px,py,text,explicit=self:ParseTodoWaypoint("/way "..body)
  local id=explicit or N.Call(C_Map and C_Map.GetBestMapForUnit,"player")
  if N.ValidPoint(id,px,py) and self:GetTodoMapInfo(id) then return id,px,py,text end
end
function FC:NoteCoordinateCommand(message)
  if not N.IsText(message) then return end
  if trim(message)=="" then
    if self:IsTodoCoordinateEnabled() then self:ToggleTodo() else self:NoteCoordinateMessage("편의 기능에서 노트 사용을 먼저 켜세요.") end
    return
  end
  local map,x,y,label=self:ParseNoteCoordinateCommand(message)
  if not map then
    self:NoteCoordinateMessage("/nt way X Y 메모 · /노트 way mapID X Y 메모 · /nt way 지역명 X Y 메모 (좌표 0~100, 동명 지역은 #mapID)")
    return
  end
  local item,why=self:AddTodoCoordinate(map,x,y,label)
  if not item then self:NoteCoordinateMessage(why);return end
  local info=self:GetTodoMapInfo(map)
  self:NoteCoordinateMessage("좌표 목록에 추가: "..info.name.." "..decimal(x)..", "..decimal(y).." · "..item.waypoint.label)
  if self.todoMapPinsReason then self:NoteCoordinateMessage(self.todoMapPinsReason) end
end
function FC:CreateTodoCoordinateTicket(id)
  local item=self:FindTodoWaypoint(id)
  if not item then return end
  local p=item.waypoint
  return {id=id,item=item,pages=self.db.todo.pages,generation=K.profileGeneration,text=item.text,done=item.done==true,mapID=p.mapID,x=p.x,y=p.y}
end
function FC:DeleteTodoCoordinate(ticket)
  if type(ticket)~="table" or not self:IsTodoCoordinateEnabled() or ticket.pages~=self.db.todo.pages or ticket.generation~=K.profileGeneration then return false end
  local item,_,list,index=self:FindTodoWaypoint(ticket.id)
  local p=item and item.waypoint
  if not p or item~=ticket.item or item.text~=ticket.text or (item.done==true)~=ticket.done or p.mapID~=ticket.mapID or p.x~=ticket.x or p.y~=ticket.y then return false end
  table.remove(list,index)
  -- RefreshSelection drops only this missing manual destination; do not call
  -- ClearManualDestination(), which would unpause every other source as well.
  self:CommitTodoCoordinateChange()
  return true
end
function FC:InstallNoteCoordinateCommands()
  if self.noteCommandsInstalled then return end
  self.noteCommandsInstalled=true
  SLASH_KHQOLNOTECOORD1,SLASH_KHQOLNOTECOORD2="/nt","/노트"
  SlashCmdList.KHQOLNOTECOORD=function(message) FC:NoteCoordinateCommand(message) end
end

-- A context menu snapshots the exact KHQOL checklist entries in its scope.
-- Validate every entry before deleting any; never include native/other addon pins.
function FC:CreateTodoCoordinateDeleteSet(scope,id,mapID)
  local tickets={}
  self:EachTodoTask(function(item,page)
    local p=item.waypoint
    if page.mode=="checklist" and not item.done and type(p)=="table" and N.ValidPoint(p.mapID,p.x,p.y) and
      (scope=="all" or (scope=="map" and p.mapID==mapID) or (scope=="pin" and item.id==id)) then
      tickets[#tickets+1]=self:CreateTodoCoordinateTicket(item.id)
    end
  end)
  return tickets
end
function FC:DeleteTodoCoordinateSet(tickets)
  if not self:IsTodoCoordinateEnabled() or N.Call(InCombatLockdown)==true or type(tickets)~="table" or #tickets==0 then return false end
  for _,ticket in ipairs(tickets) do
    local item,page=self:FindTodoWaypoint(ticket.id);local p=item and item.waypoint
    if ticket.pages~=self.db.todo.pages or ticket.generation~=K.profileGeneration or not p or page.mode~="checklist" or
      item~=ticket.item or item.text~=ticket.text or (item.done==true)~=ticket.done or p.mapID~=ticket.mapID or p.x~=ticket.x or p.y~=ticket.y then return false end
  end
  for _,ticket in ipairs(tickets) do
    local _,_,list,index=self:FindTodoWaypoint(ticket.id);table.remove(list,index)
  end
  self:CommitTodoCoordinateChange()
  return true
end
function FC:IsTodoWaypointArrived(item)
  return self:GetTodoNavigationOptions().hideArrived==true and type(item.waypoint)=="table" and item.waypoint.arrived==true
end
function FC:ResetTodoArrivedPins()
  self:EachTodoTask(function(item) if type(item.waypoint)=="table" then item.waypoint.arrived=nil end end)
  self:CommitTodoCoordinateChange()
end
function FC:CheckTodoPinArrival()
  if N.Call(InCombatLockdown)==true or not self:TodoMapPinsEnabled() or not self:GetTodoNavigationOptions().hideArrived then return end
  local map,x,y=N:GetPlayerPosition()
  if not map or not N:ReadMapSize() then return end
  local width,height=N.mapWidth,N.mapHeight
  local changed=false
  self:EachTodoTask(function(item,page)
    local p=item.waypoint
    if page.mode=="checklist" and not item.done and type(p)=="table" and not p.arrived and p.mapID==map and N.ValidPoint(p.mapID,p.x,p.y) then
      local dx,dy=(p.x-x)*width,(p.y-y)*height
      if dx*dx+dy*dy<=100 then p.arrived=true;changed=true end -- 10 yards, no item deletion/completion.
    end
  end)
  if changed then self:CommitTodoCoordinateChange() end
end
function FC:UpdateTodoArrivalDriver()
  local pending=false
  local running=self.todoPinGuidance and not self.todoPinGuidance.paused
  local provider=self.todoMapProvider
  local target=self:GetTodoPinLineTarget()
  local mapLine=target and self:TodoMapPinsEnabled() and self:GetTodoPinLineOptions().visible and
    N.Call(provider and provider.GetMap,provider)
  mapLine=mapLine and N.Call(mapLine.IsShown,mapLine)==true and target.source=="ForeverNote"
  if running or mapLine then pending=true end
  if self:TodoMapPinsEnabled() and self:GetTodoNavigationOptions().hideArrived or self:TodoMinimapPinsEnabled() or running then
    self:EachTodoTask(function(item,page)
      local p=item.waypoint
      if page.mode=="checklist" and not item.done and type(p)=="table" and not self:IsTodoWaypointArrived(item) and N.ValidPoint(p.mapID,p.x,p.y) then pending=true end
    end)
  end
  if not self.todoArrivalDriver then
    if not pending then return end
    self.todoArrivalDriver=CreateFrame("Frame")
  end
  local driver=self.todoArrivalDriver
  if not pending then driver:SetScript("OnUpdate",nil);driver.elapsed=0;driver.noteLineTarget=nil;return end
  driver.noteLineTarget=target
  if driver:GetScript("OnUpdate") then return end
  driver.elapsed=0
  driver:SetScript("OnUpdate",function(frame,elapsed)
    frame.elapsed=frame.elapsed+elapsed
    frame.arrivalElapsed=(frame.arrivalElapsed or 0)+elapsed
    if frame.elapsed<.1 then return end
    frame.elapsed=frame.elapsed%.1
    FC:UpdateTodoPinGuidance();FC:RefreshTodoMinimapPins()
    if frame.arrivalElapsed>=.5 then frame.arrivalElapsed=0;FC:CheckTodoPinArrival() end
    local provider=FC.todoMapProvider
    local target=FC:GetTodoPinLineTarget()
    local paused=FC.todoPinGuidance and FC.todoPinGuidance.paused
    if not paused and (target or frame.noteLineTarget) and FC:TodoMapPinsEnabled() and FC:GetTodoPinLineOptions().visible and
      provider and N.Call(provider:GetMap().IsShown,provider:GetMap())==true then
      if frame.noteLineTarget~=target then FC:RefreshTodoNavigationLine()
      else FC:RefreshTodoPinLines(provider,provider.noteSnapshot) end
    end
    if frame.noteLineTarget~=target then FC:UpdateTodoArrivalDriver() end
  end)
end
