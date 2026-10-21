local K=assert(_G.KHQOL,"Install and enable the KHQOL core addon.")
local FC,N=K.modules.clock,K.Navigation
local call=K.PublicCall
local MAX_ROUTES,MAX_PINS=32,128
local function validRoute(r) return type(r)=="table" and type(r.id)=="string" and type(r.pinIDs)=="table" end
local function editable() return FC:IsTodoCoordinateEnabled() and call(InCombatLockdown)~=true end
local function checkedName(name)
  if type(name)~="string" then return end
  name=name:match("^%s*(.-)%s*$")
  if name~="" and #name<=120 and not name:find("[\r\n]") then return name end
end
local function defaults(r)
  if type(r.name)~="string" or r.name=="" then r.name="기본 경로" end
  if r.visible==nil then r.visible=true end
  if r.navigationEnabled==nil then r.navigationEnabled=true end
  r.lineStyle=r.lineStyle or "DOTTED";r.revision=tonumber(r.revision) or 0
  return r
end
function FC:GetTodoRouteStore(create)
  local todo=self.db and self.db.todo
  if not todo then return end
  if todo.mapPinRoutes==nil and create then todo.mapPinRoutes={} end
  local store=todo.mapPinRoutes
  if type(store)~="table" then return end
  if store.schemaVersion~=nil and store.schemaVersion~=2 then
    self.todoPinRouteReason="이 버전에서 읽을 수 없는 경로 형식입니다. 원본 데이터는 유지합니다.";return
  end
  if not store.schemaVersion then
    local shared=store.shared
    if not validRoute(shared) then
      local keys,ids,seen={},{},{}
      for id,r in pairs(store) do
        if N.IsID(id) and type(r)=="table" and type(r.pinIDs)=="table" and #r.pinIDs>0 then keys[#keys+1]=id end
      end
      table.sort(keys)
      for _,id in ipairs(keys) do for _,pin in ipairs(store[id].pinIDs) do
        if type(pin)=="string" and not seen[pin] then ids[#ids+1]=pin;seen[pin]=true end
      end end
      if #ids>0 then shared={id="note-route:shared",pinIDs=ids,legacyMaps=keys};store.shared=shared end
    end
    store.routes={};store.order={};store.nextRouteID=1;store.schemaVersion=2
    if validRoute(shared) then
      defaults(shared);store.routes[shared.id]=shared;store.order[1]=shared.id;store.selectedRouteID=shared.id
    end
  end
  if type(store.routes)~="table" or type(store.order)~="table" then return end
  return store
end
function FC:GetTodoPinRoute(mapID,create)
  local store=self:GetTodoRouteStore(create)
  if not store then return end
  local route=store.routes[store.selectedRouteID or ""]
  if not validRoute(route) and create and editable() then return self:CreateTodoPinRoute("기본 경로") end
  if validRoute(route) then
    self.todoPinRouteReason=#route.pinIDs>MAX_PINS and "이전 경로는 모두 보존했습니다. 128개를 넘는 핀을 제외한 뒤 안내를 시작하세요." or nil
    return defaults(route)
  end
  self.todoPinRouteReason=nil
end
function FC:GetTodoPinRouteByID(id)
  local store=self:GetTodoRouteStore(false);local r=store and store.routes[id or ""]
  return validRoute(r) and defaults(r) or nil
end
function FC:GetTodoPinRouteOptions()
  local store=self:GetTodoRouteStore(false);local options={}
  for _,id in ipairs(store and store.order or {}) do
    local r=store.routes[id]
    if validRoute(r) then options[#options+1]={value=id,text=(r.name or "경로").." ("..#r.pinIDs..")"} end
  end
  if #options==0 then options[1]={value="",text="저장된 경로 없음"} end
  return options
end
function FC:RefreshTodoRouteView()
  self.todoPinPoints=nil
  if self.RefreshTodoMapPins then self:RefreshTodoMapPins() end
  if K.UI then K.UI:Refresh() end
end
function FC:SelectTodoPinRoute(id)
  if not editable() or not self:GetTodoPinRouteByID(id) then return false end
  local store=self:GetTodoRouteStore(false)
  if store.selectedRouteID==id then return true end
  if self.todoPinGuidance then self:StopTodoPinGuidance(true,"경로 선택 변경") end
  store.selectedRouteID=id;self.todoRouteSelectedPin=nil;self:RefreshTodoRouteView();return true
end
function FC:CreateTodoPinRoute(name)
  if not editable() then return end
  if name~=nil then
    name=checkedName(name)
    if not name then self:NoteCoordinateMessage("경로 이름은 한 줄, 120바이트 이내로 입력하세요.");return end
  end
  local store=self:GetTodoRouteStore(true)
  if not store then return end
  local count=0;for _,r in pairs(store.routes) do if validRoute(r) then count=count+1 end end
  if count>=MAX_ROUTES then self:NoteCoordinateMessage("경로는 최대 32개까지 저장할 수 있습니다.");return end
  local serial=tonumber(store.nextRouteID) or 1
  serial=math.max(1,math.floor(serial))
  while store.routes["note-route:"..serial] do serial=serial+1 end
  local id="note-route:"..serial
  local r=defaults({id=id,name=type(name)=="string" and name~="" and name or "새 경로 "..serial,pinIDs={}})
  store.nextRouteID=serial+1;store.routes[id]=r;store.order[#store.order+1]=id
  if self.todoPinGuidance then self:StopTodoPinGuidance(true,"새 경로 생성") end
  store.selectedRouteID=id;self.todoRouteSelectedPin=nil;return r
end
function FC:RenameTodoPinRoute(id,name)
  local r=self:GetTodoPinRouteByID(id)
  if not editable() or not r or type(name)~="string" then return false end
  name=checkedName(name)
  if not name then self:NoteCoordinateMessage("경로 이름은 한 줄, 120바이트 이내로 입력하세요.");return false end
  r.name=name
  if self.todoPinGuidance and self.todoPinGuidance.routeID==id then self:ApplyTodoRouteTarget() end
  self:RefreshTodoRouteView();return true
end
function FC:SaveTodoPinRoute(id)
  local r=self:GetTodoPinRouteByID(id)
  if not editable() or not r then return false end
  self:PruneTodoPinRoutes();r.savedAt=call(GetServerTime)
  self:NoteCoordinateMessage("경로 저장: "..r.name);return true
end
function FC:DeleteTodoPinRoute(id)
  local store=self:GetTodoRouteStore(false)
  if not editable() or not store or not self:GetTodoPinRouteByID(id) then return false end
  if self.todoPinGuidance and self.todoPinGuidance.routeID==id then self:StopTodoPinGuidance(true,"경로 삭제") end
  store.routes[id]=nil
  for i=#store.order,1,-1 do if store.order[i]==id then table.remove(store.order,i) end end
  if store.selectedRouteID==id then store.selectedRouteID=store.order[1] end
  self.todoRouteSelectedPin=nil;self:RefreshTodoRouteView();return true
end
function FC:TodoPinRoutePosition(id,mapID)
  local route=self:GetTodoPinRoute(mapID)
  if route then for i,pin in ipairs(route.pinIDs) do if pin==id then return i,#route.pinIDs end end end
end
function FC:PruneTodoPinRoutes()
  local store=self:GetTodoRouteStore(false)
  if not store then return end
  local live={}
  self:EachTodoTask(function(item,page)
    local p=item.waypoint
    if page.mode=="checklist" and type(item.id)=="string" and type(p)=="table" and N.ValidPoint(p.mapID,p.x,p.y) then live[item.id]=p.mapID end
  end)
  for _,route in pairs(store.routes) do if validRoute(route) then
    local write,seen,changed=1,{},false
    for _,id in ipairs(route.pinIDs) do
      if type(id)=="string" and live[id] and not seen[id] then
        route.pinIDs[write]=id;write=write+1;seen[id]=true
      else changed=true end
    end
    for i=#route.pinIDs,write,-1 do route.pinIDs[i]=nil end
    if changed then route.revision=(route.revision or 0)+1 end
    route.mapID=route.pinIDs[1] and live[route.pinIDs[1]] or nil
  end end
end
function FC:CreateTodoPinRouteTicket(id)
  local item,page=self:FindTodoWaypoint(id)
  if not item or page.mode~="checklist" or (item.done and not self:TodoPinRoutePosition(id)) then return end
  local t=self:CreateTodoCoordinateTicket(id)
  t.route=self:GetTodoPinRoute(nil);t.routeID=t.route and t.route.id;t.order={}
  for i,pin in ipairs(t.route and t.route.pinIDs or {}) do t.order[i]=pin end
  return t
end
function FC:ValidateTodoPinRouteTicket(t)
  if not editable() or type(t)~="table" or t.pages~=self.db.todo.pages or t.generation~=K.profileGeneration then return false end
  local item,page=self:FindTodoWaypoint(t.id);local p=item and item.waypoint
  if not p or item~=t.item or page.mode~="checklist" or (item.done and not self:TodoPinRoutePosition(t.id)) or item.text~=t.text or p.mapID~=t.mapID or p.x~=t.x or p.y~=t.y then return false end
  local r=self:GetTodoPinRoute(nil)
  if r~=t.route or type(t.order)~="table" or #(r and r.pinIDs or {})~=#t.order then return false end
  for i,pin in ipairs(t.order) do if r.pinIDs[i]~=pin then return false end end
  return true
end
function FC:ChangeTodoPinRoute(t,action)
  if not self:ValidateTodoPinRouteTicket(t) then return false end
  local r=self:GetTodoPinRoute(nil);local index=self:TodoPinRoutePosition(t.id)
  if action=="add" then
    if index then return false end
    if r and #r.pinIDs>=MAX_PINS then self:NoteCoordinateMessage("한 경로에는 최대 128개 핀을 지정할 수 있습니다.");return false end
    r=r or self:GetTodoPinRoute(nil,true);if not r then return false end
    r.pinIDs[#r.pinIDs+1]=t.id;r.mapID=r.mapID or t.mapID
  elseif index and action=="remove" then table.remove(r.pinIDs,index)
  elseif index and action=="up" and index>1 then r.pinIDs[index],r.pinIDs[index-1]=r.pinIDs[index-1],r.pinIDs[index]
  elseif index and action=="down" and index<#r.pinIDs then r.pinIDs[index],r.pinIDs[index+1]=r.pinIDs[index+1],r.pinIDs[index]
  else return false end
  r.revision=r.revision+1
  if self.todoPinGuidance and self.todoPinGuidance.routeID==r.id then self:StopTodoPinGuidance(true,"경유지 편집") end
  self:RefreshTodoRouteView();return true
end
function FC:GetTodoRoutePinOptions(onlyMembers)
  local r=self:GetTodoPinRoute(nil);local options={}
  if onlyMembers then
    for i,id in ipairs(r and r.pinIDs or {}) do
      local item=self:FindTodoWaypoint(id);local p=item and item.waypoint
      options[#options+1]={value=id,text=i.." · "..(p and p.label or "삭제된 핀")}
    end
  else
    self:EachTodoTask(function(item,page)
      local p=item.waypoint
      if page.mode=="checklist" and not item.done and type(p)=="table" and N.ValidPoint(p.mapID,p.x,p.y) and not self:TodoPinRoutePosition(item.id) then
        local info=self:GetTodoMapInfo(p.mapID)
        options[#options+1]={value=item.id,text=(p.label or "핀").." · "..(info and info.name or p.mapID)}
      end
    end)
  end
  if #options==0 then options[1]={value="",text=onlyMembers and "경유지 없음" or "추가할 핀 없음"} end
  return options
end
