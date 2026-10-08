local _, KHQOL = ...
local FC=KHQOL.modules.clock
local N,UI=KHQOL.Navigation,KHQOL.NavigationUI
FC.DEFAULTS.todo.navigation={enabled=false,autoAdvance=true,showTrackButton=true}
N:RegisterSource("ForeverNote",{priority=2,autoSelect=true,allowZero=true,enabled=false})

local function trim(text) return text:match("^%s*(.-)%s*$") end
local function coordinate(token)
  if type(token)~="string" or not (token:match("^%d+%.?%d*$") or token:match("^%.%d+$")) then return nil end
  local value=tonumber(token)
  if N.IsNumber(value) and value>=0 and value<=100 then return value/100 end
end
local function mapName(name) return trim(name):gsub("%s+"," ") end
function FC:GetTodoMapInfo(id)
  if not N.IsID(id) then return nil end
  local info=N.Call(C_Map and C_Map.GetMapInfo,id)
  if N.IsTable(info) and N.IsID(info.mapID) and info.mapID==id and N.IsText(info.name) and info.name~="" then return info end
end
function FC:ResolveTodoMapName(name)
  -- Build a localized name index on first explicit region input, never on update.
  -- Numeric IDs are validated separately; no range scan or external addon data.
  if not self.todoMapNames then
    local names,roots,seen={},{},{}
    local function add(info)
      if not N.IsTable(info) or not N.IsID(info.mapID) or not N.IsText(info.name) or info.name=="" then return end
      local key=mapName(info.name)
      names[key]=names[key] or {}; names[key][info.mapID]=true
    end
    local function ancestry(id)
      local visited={}
      for _=1,32 do
        if not N.IsID(id) or visited[id] then return end
        visited[id]=true
        local info=self:GetTodoMapInfo(id); if not info then return end
        add(info); seen[id]=true
        local parent=info.parentMapID
        if not N.IsID(parent) then roots[id]=true; return end
        id=parent
      end
    end
    -- Standard cosmic/world roots are queried only if this client knows them.
    ancestry(946); ancestry(947)
    ancestry(N.Call(C_Map and C_Map.GetFallbackWorldMapID))
    ancestry(N.Call(C_Map and C_Map.GetBestMapForUnit,"player"))
    local enumerated,complete=false,true
    for root in pairs(roots) do
      if seen[root] then
        local children=N.Call(C_Map and C_Map.GetMapChildrenInfo,root,nil,true)
        if N.IsTable(children) then
          if #children>0 then enumerated=true end
          for _,info in ipairs(children) do add(info) end
        else complete=false end
      end
    end
    -- Missing/uninitialized APIs must remain retryable on a later text edit.
    if complete and enumerated then self.todoMapNames=names end
    local matches=names[mapName(name)]
    local found
    for id in pairs(matches or {}) do if found then return nil,"ambiguous" end; found=id end
    return found and self:GetTodoMapInfo(found) and found or nil
  end
  local found
  for id in pairs(self.todoMapNames[mapName(name)] or {}) do if found then return nil,"ambiguous" end; found=id end
  return found and self:GetTodoMapInfo(found) and found or nil
end
function FC:ParseTodoWaypoint(text)
  if not N.IsText(text) then return nil end
  local x,y,label,map,selector
  local body=text:match("^%s*/way%s+(.-)%s*$")
  if body then
    local tokens={}; local offset=1
    while true do
      local first,last=body:find("%S+",offset); if not first then break end
      tokens[#tokens+1]={value=body:sub(first,last),first=first,last=last}; offset=last+1
    end
    local first=tokens[1] and tokens[1].value
    if not first then return nil end
    local nextToken
    if first:sub(1,1)=="#" then
      local id=first:match("^#(%d+)$")
      map=id and tonumber(id) or nil
      if not self:GetTodoMapInfo(map) then return nil end
      selector="#"..map; nextToken=2
    elseif tonumber(first)~=nil and tokens[2] and tonumber(tokens[2].value)~=nil then nextToken=1
    else
      -- The name may contain spaces. Coordinates terminate the region prefix.
      for i=#tokens-1,2,-1 do
        if coordinate(tokens[i].value)~=nil and coordinate(tokens[i+1].value)~=nil then
          local name=mapName(body:sub(1,tokens[i].first-1))
          local resolved,reason=self:ResolveTodoMapName(name)
          if reason=="ambiguous" then return nil end
          if resolved then selector,map,nextToken=name,resolved,i; break end
        end
      end
    end
    if not nextToken or not tokens[nextToken+1] then return nil end
    x,y=coordinate(tokens[nextToken].value),coordinate(tokens[nextToken+1].value)
    label=body:sub(tokens[nextToken+1].last+1)
  else
    label,x,y=text:match("^%s*(.-)%s*@([^,%s]+)%s*,%s*([^,%s]+)%s*$")
    x,y=coordinate(x),coordinate(y)
  end
  if x==nil or y==nil then return nil end
  label=trim(label or "")
  if label=="" then label="노트 위치" end
  return x,y,label,map,selector
end
function FC:EachTodoTask(callback)
  if not self.db or not self.db.todo then return end
  for _,page in ipairs(self.db.todo.pages or {}) do
    local function visit(tasks)
      for index,item in ipairs(tasks) do
        -- Older plain-string entries keep their text on migration.
        if type(item)=="string" then item={text=item,done=false}; tasks[index]=item end
        if type(item)=="table" then
          if item.done==nil and type(item.completed)=="boolean" then item.done=item.completed end
          callback(item,page)
        end
      end
    end
    visit(page.individualTasks or page.tasks or {})
    for _,group in ipairs(page.groups or {}) do visit(group.tasks or {}) end
  end
end
function FC:EnsureTodoNavigationIDs()
  local todo=self.db.todo; local used={}
  local nextID=N.IsID(todo.nextNavigationID) and todo.nextNavigationID or 1
  self:EachTodoTask(function(item)
    if type(item.waypoint)=="table" and type(item.id)=="string" then
      local numeric=tonumber(item.id:match("^fn:(%d+)$"))
      if numeric and numeric>=nextID then nextID=numeric+1 end
    end
  end)
  self:EachTodoTask(function(item)
    if type(item.waypoint)=="table" then
      if type(item.id)~="string" or item.id=="" or used[item.id] then
        while used["fn:"..nextID] do nextID=nextID+1 end
        item.id="fn:"..nextID; nextID=nextID+1
      end
      used[item.id]=true
      local numeric=tonumber(item.id:match("^fn:(%d+)$"))
      if numeric and numeric>=nextID then nextID=numeric+1 end
    end
  end)
  todo.nextNavigationID=nextID
end
function FC:UpdateTodoWaypoint(item,text,defer)
  item.text=text -- The editable original is never replaced by a parsed label.
  local x,y,label,explicitMap,selector=self:ParseTodoWaypoint(text)
  if x~=nil then
    local previous=item.waypoint
    local map=explicitMap or (type(previous)=="table" and not previous.mapSelector and previous.x==x and previous.y==y and previous.mapID) or
      N.Call(C_Map and C_Map.GetBestMapForUnit,"player")
    if N.ValidPoint(map,x,y) then item.waypoint={mapID=map,x=x,y=y,label=label,mapSelector=selector}
    else item.waypoint=nil end
  else item.waypoint=nil end
  if not defer then self:RefreshTodoNavigation() end
end
function FC:GetTodoNavigationOptions()
  local todo=self.db.todo
  todo.navigation=KHQOL.MergeDefaults(type(todo.navigation)=="table" and todo.navigation or {},self.DEFAULTS.todo.navigation,"types")
  return todo.navigation
end
function FC:RefreshTodoNavigation()
  if not self.db or not self.db.todo then return end
  local options=self:GetTodoNavigationOptions()
  if options.autoAdvance then N.sources.ForeverNote.paused=nil end
  local enabled=options.enabled and (not KHQOL.db or KHQOL:GetEnabled("todo")) and true or false
  if not UI.db then UI:Configure({}) end
  N:SetSourceEnabled("ForeverNote",enabled)
  UI:SetClientEnabled("ForeverNote",enabled)
  self:EnsureTodoNavigationIDs()
  if not enabled then
    if self.todoNavigationEvents then self.todoNavigationEvents:UnregisterAllEvents() end
    return
  end
  local destinations={}; local active=N:GetActiveDestination(); local completedActive=false
  self:EachTodoTask(function(item,page)
    local p=item.waypoint
    if page.mode=="checklist" and type(p)=="table" and N.ValidPoint(p.mapID,p.x,p.y) then
      if item.done then
        if active and active.source=="ForeverNote" and active.id==item.id then completedActive=true end
      else
        destinations[#destinations+1]={source="ForeverNote",id=item.id,label=p.label or item.text or "노트 위치",
          mapID=p.mapID,x=p.x,y=p.y,metadata={checklistID=item.id,pageTitle=page.title}}
      end
    end
  end)
  UI:SetSourcePresentation("ForeverNote",{progressText="Forever Note",moveHint="Navigation · 드래그 이동"})
  N:SetSourceDestinations("ForeverNote",destinations,{pauseOnRemoval=completedActive and not options.autoAdvance})
  if N.activeSource=="ForeverNote" then UI:Refresh(true,true) end
  UI:Render()
  if not self.todoNavigationEvents then
    self.todoNavigationEvents=CreateFrame("Frame")
    self.todoNavigationEvents:SetScript("OnEvent",function()
      UI:Schedule("source:ForeverNote",.1,function() N:InvalidateMap(); FC:RefreshTodoNavigation() end)
    end)
  end
  for _,event in ipairs({"PLAYER_ENTERING_WORLD","ZONE_CHANGED_NEW_AREA","ZONE_CHANGED"}) do
    if type(C_EventUtils)~="table" or type(C_EventUtils.IsEventValid)~="function" or N.Call(C_EventUtils.IsEventValid,event)~=false then
      N.Call(self.todoNavigationEvents.RegisterEvent,self.todoNavigationEvents,event)
    end
  end
end
function FC:TrackTodoWaypoint(item)
  if not self:GetTodoNavigationOptions().enabled then return end
  self:RefreshTodoNavigation()
  if not item.done and N:SetManualDestination("ForeverNote",item.id) then UI:Refresh(true,true); UI:Render() end
end
function FC:UpdateTodoNavigationRow(row,item)
  local options=self:GetTodoNavigationOptions()
  local p=item.waypoint
  local shown=options.enabled and options.showTrackButton and type(p)=="table" and N.ValidPoint(p.mapID,p.x,p.y)
  row.navigate.item=item; row.navigate:SetShown(shown)
  row.navigate:SetEnabled(not item.done)
  row.edit:ClearAllPoints(); row.edit:SetPoint("LEFT",row.check,"RIGHT",1,0)
  row.edit:SetPoint("RIGHT",shown and row.navigate or row.delete,"LEFT",-3,0)
end
function FC:RestoreTodoChecklistTask(page,text,done,used)
  local found
  local function find(tasks)
    for _,item in ipairs(tasks or {}) do
      if type(item)=="table" and item.text==text and not used[item] and not found then found=item end
    end
  end
  find(page.individualTasks or page.tasks)
  for _,group in ipairs(page.groups or {}) do find(group.tasks) end
  if found then used[found]=true; found.done=done; return found end
  local item={text=text,done=done}; self:UpdateTodoWaypoint(item,text,true); return item
end
