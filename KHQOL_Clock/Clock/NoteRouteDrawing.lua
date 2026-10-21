local K=assert(_G.KHQOL,"Install and enable the KHQOL core addon.")
local FC,UI,call=K.modules.clock,K.UI,K.PublicCall
local function combat() return call(InCombatLockdown)==true end
function FC:GetTodoRouteDrawing()
  local d=self.todoRouteDrawing
  if d and (not self:IsTodoCoordinateEnabled() or not self:GetTodoNavigationOptions().mapPins or
    d.pages~=self.db.todo.pages or d.generation~=K.profileGeneration or self:GetTodoPinRoute(nil)~=d.route) then
    self.todoRouteDrawing=nil;self.todoPinPoints=nil
    if self.todoRouteDrawingBar then self.todoRouteDrawingBar:Hide() end
    return nil
  end
  return d
end
function FC:BeginTodoRouteDrawing(createNew,openMap)
  if combat() or not self:TodoMapPinsEnabled() then self:NoteCoordinateMessage("전투 종료 후 노트 사용·세계지도 핀 표시를 켜고 경로를 그리세요.");return false end
  local route
  if createNew then route=self:CreateTodoPinRoute() else route=self:GetTodoPinRoute(nil) end
  if not route then if not createNew then self:NoteCoordinateMessage("이어그릴 경로를 먼저 선택하세요.") end;return false end
  if #route.pinIDs>128 then self:NoteCoordinateMessage("이전 경로는 128개 이하로 정리한 뒤 이어그릴 수 있습니다.");return false end
  if self.todoPinGuidance then self:StopTodoPinGuidance(true,"경로 그리기 시작") end
  self.todoRouteDrawing={route=route,routeID=route.id,pages=self.db.todo.pages,generation=K.profileGeneration}
  self:RefreshTodoRouteView()
  if openMap~=false then
    if not WorldMapFrame or call(WorldMapFrame.IsShown,WorldMapFrame)~=true then
      if type(ToggleWorldMap)=="function" then call(ToggleWorldMap)
      elseif WorldMapFrame then call(WorldMapFrame.Show,WorldMapFrame) end
    end
    if WorldMapFrame and call(WorldMapFrame.IsShown,WorldMapFrame)==true and K.settings then K.settings:Hide() end
  end
  self:UpdateTodoRouteDrawingBar();return true
end
function FC:FinishTodoRouteDrawing(navigate,expected)
  local d=self:GetTodoRouteDrawing()
  if not d or expected and d~=expected then return false end
  if navigate and (combat() or #d.route.pinIDs==0 or d.route.navigationEnabled==false) then
    self:NoteCoordinateMessage("전투 종료 후 핀을 추가하고 선택 경로의 안내 사용을 켜세요.");return false
  end
  if navigate then return self:StartTodoSavedRoute("first") end
  self.todoRouteDrawing=nil;self:RefreshTodoRouteView()
  return true
end
function FC:CanAddTodoDrawingPin(expected)
  local d=self:GetTodoRouteDrawing()
  if not d or expected and expected~=d or combat() then return false end
  if #d.route.pinIDs>=128 then self:NoteCoordinateMessage("경로는 최대 128개 핀입니다. 그리기를 완료하거나 경유지를 제외하세요.");return false end
  return true
end
function FC:AddTodoDrawingPin(id,expected)
  local d=self:GetTodoRouteDrawing()
  if not d or expected and expected~=d or combat() then return false end
  if self:TodoPinRoutePosition(id) then self:NoteCoordinateMessage("이미 이 경로에 등록된 핀입니다.");return true end
  if not self:CanAddTodoDrawingPin(d) then return false end
  local ticket=self:CreateTodoPinRouteTicket(id)
  if not ticket or not self:ChangeTodoPinRoute(ticket,"add") then self:NoteCoordinateMessage("추가할 핀이나 경로가 바뀌었습니다. 다시 선택하세요.");return false end
  return true
end
function FC:GetTodoRouteNumberLookup()
  local route=self:GetTodoPinRoute(nil)
  local revision=route and route.revision;local count=route and #route.pinIDs or 0
  if self.todoNumberRoute~=route or self.todoNumberRevision~=revision or self.todoNumberCount~=count or not self.todoNumberLookup then
    local lookup={};for i,id in ipairs(route and route.pinIDs or {}) do lookup[id]=i end
    self.todoNumberLookup=lookup;self.todoNumberRoute,self.todoNumberRevision,self.todoNumberCount=route,revision,count
  end
  return self.todoNumberLookup
end
function FC:UpdateTodoPinNumber(pin,lookup)
  local number=(lookup or self:GetTodoRouteNumberLookup())[pin.noteID]
  if number and not pin.RouteNumber then
    local text=pin:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    text:SetFont(UI:Font(),pin.noteMiniMap and 10 or 12,"OUTLINE")
    text:SetPoint("CENTER",pin,"TOPRIGHT",-1,-2);text:SetTextColor(1,1,.75,1)
    pin.RouteNumber=text
  end
  if pin.RouteNumber and pin.todoRouteNumber~=number then
    pin.RouteNumber:SetText(number and tostring(number) or "");pin.RouteNumber:SetShown(number~=nil);pin.todoRouteNumber=number
  end
end
function FC:UpdateTodoRouteDrawingBar()
  local d=self:GetTodoRouteDrawing();local bar=self.todoRouteDrawingBar;local map=WorldMapFrame
  if not d or not map or call(map.IsShown,map)~=true then if bar then bar:Hide() end;return end
  if not bar then
    bar=CreateFrame("Frame","KHQOLNoteRouteDrawingBar",map,"BackdropTemplate")
    bar:SetSize(620,90);bar:EnableMouse(true)
    bar:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    bar:SetBackdropColor(.035,.045,.045,.95);bar:SetBackdropBorderColor(.45,.8,.75,1)
    bar.title=bar:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    bar.title:SetFont(UI:Font(),13,"");bar.title:SetPoint("TOPLEFT",10,-8);bar.title:SetJustifyH("LEFT");bar.title:SetWordWrap(false)
    bar.hint=bar:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    bar.hint:SetFont(UI:Font(),11,"");bar.hint:SetPoint("TOPLEFT",10,-30);bar.hint:SetJustifyH("LEFT");bar.hint:SetWordWrap(false)
    bar.hint:SetTextColor(.8,.85,.85,1)
    bar.done=UI:CreateButton(bar,"그리기 완료",0,0,100,function() FC:FinishTodoRouteDrawing(false,bar.session) end)
    bar.start=UI:CreateButton(bar,"안내 시작",0,0,88,function() FC:FinishTodoRouteDrawing(true,bar.session) end,
      function() local current=FC:GetTodoRouteDrawing();return current and #current.route.pinIDs>0 and current.route.navigationEnabled~=false and not combat() end)
    bar.done.navigationOnly=true;bar.start.navigationOnly=true
    self.todoRouteDrawingBar=bar
  end
  if bar:GetParent()~=map then bar:SetParent(map) end
  if not map.khqolRouteDrawingResize then
    map.khqolRouteDrawingResize=true
    map:HookScript("OnSizeChanged",function() if FC.todoRouteDrawingBar and FC.todoRouteDrawingBar:IsShown() then FC:UpdateTodoRouteDrawingBar() end end)
  end
  local width=call(map.GetWidth,map);width=type(width)=="number" and width>0 and math.min(620,math.max(260,width-24)) or 620
  bar:SetWidth(width);bar:ClearAllPoints();bar:SetPoint("BOTTOM",map,"BOTTOM",0,30)
  bar:SetFrameStrata(call(map.GetFrameStrata,map) or "HIGH")
  bar:SetFrameLevel((call(map.GetFrameLevel,map) or 0)+100);bar.session=d
  bar.title:SetWidth(width-20);bar.title:SetText("경로 그리기 · "..d.route.name.." · "..#d.route.pinIDs.." / 128개")
  bar.hint:SetWidth(width-20);bar.hint:SetText(combat() and "전투 종료 후 핀을 추가할 수 있습니다." or "Shift+우클릭: 새 핀 · 기존 핀 좌클릭: 경로에 추가")
  bar.done:ClearAllPoints();bar.done:SetPoint("BOTTOMRIGHT",bar,"BOTTOMRIGHT",-108,8)
  bar.start:ClearAllPoints();bar.start:SetPoint("BOTTOMRIGHT",bar,"BOTTOMRIGHT",-10,8)
  bar.done:Refresh();bar.start:Refresh();bar:Show()
end
