local K=assert(_G.KHQOL, "Install and enable the KHQOL core addon.")
local FC,N=K.modules.clock,K.Navigation
local call=K.PublicCall
local TEMPLATE="KHQOLNoteMapPinTemplate"
local function combat() return call(InCombatLockdown)==true end
function FC:TodoMapPinsEnabled()
  return self:IsTodoCoordinateEnabled() and self:GetTodoNavigationOptions().mapPins==true
end
function FC:OpenTodoPinMenu(pin,mapID)
  if not (self:TodoMapPinsEnabled() or self:TodoMinimapPinsEnabled()) or combat() then return end
  local pages,generation=self.db.todo.pages,K.profileGeneration
  local map,id=not pin.noteMiniMap and pin:GetMap() or nil,pin.noteID
  local displayMap=map and call(map.GetMapID,map)
  local ticket=self:CreateTodoPinRouteTicket(id)
  local position,total=self:TodoPinRoutePosition(id,mapID)
  local guidance=self.todoPinGuidance
  local drawing=self:GetTodoRouteDrawing()
  local entries={}
  local function routeAction(label,action)
    entries[#entries+1]={label=label,action=action}
  end
  if ticket then
    routeAction("여기로 안내 시작","start")
    if guidance then
      routeAction(guidance.paused and "경로 안내 재개" or "경로 안내 일시 정지",guidance.paused and "resume" or "pause")
      if guidance.index>1 then routeAction("이전 경유지","previous") end
      routeAction("다음 경유지","next");routeAction("경로 안내 중지","stop")
    end
    if drawing then routeAction("경로 그리기 완료","drawDone")
    else
      if not ticket.item.done then routeAction("새 경로 그리기","drawNew") end
      if ticket.route then routeAction("선택 경로 이어그리기","drawContinue") end
    end
    if position then
      if position>1 then routeAction("경로 순서 앞으로","up") end
      if position<total then routeAction("경로 순서 뒤로","down") end
      routeAction("경로에서 제외","remove")
    else routeAction("경로에 추가 (마지막)","add") end
  end
  if #entries>0 then entries[#entries+1]={separator=true} end
  local deletionEntries={
    {label="해당 핀 삭제",tickets=self:CreateTodoCoordinateDeleteSet("pin",pin.noteID,mapID)},
    {label="지도 내 핀 삭제",tickets=self:CreateTodoCoordinateDeleteSet("map",nil,mapID)},
    {label="전체 핀 삭제",tickets=self:CreateTodoCoordinateDeleteSet("all")},
  }
  for _,entry in ipairs(deletionEntries) do entries[#entries+1]=entry end
  local function perform(entry)
    if not (FC:TodoMapPinsEnabled() or FC:TodoMinimapPinsEnabled()) or combat() or pages~=FC.db.todo.pages or generation~=K.profileGeneration or
      pin.notePages~=pages or pin.noteID~=id or (map and (call(pin.GetMap,pin)~=map or call(map.IsShown,map)~=true or
      call(map.GetMapID,map)~=displayMap)) or (pin.noteMiniMap and call(pin.IsShown,pin)~=true) then
      FC:NoteCoordinateMessage("항목이나 지도가 변경되었습니다. 핀 메뉴를 다시 여세요.");return
    end
    local ok
    if entry.action=="start" then ok=FC:StartTodoPinGuidance(ticket)
    elseif entry.action=="drawDone" then ok=FC:FinishTodoRouteDrawing(false,drawing)
    elseif entry.action=="drawNew" or entry.action=="drawContinue" then
      if FC:ValidateTodoPinRouteTicket(ticket) then
        ok=FC:BeginTodoRouteDrawing(entry.action=="drawNew")
        if ok then ok=FC:AddTodoDrawingPin(id,FC.todoRouteDrawing) end
      end
    elseif entry.action=="stop" or entry.action=="pause" or entry.action=="resume" or entry.action=="next" or entry.action=="previous" then
      ok=FC:ControlTodoPinGuidance(entry.action,guidance)
    elseif entry.action then ok=FC:ChangeTodoPinRoute(ticket,entry.action)
    else ok=FC:DeleteTodoCoordinateSet(entry.tickets) end
    if not ok then
      FC:NoteCoordinateMessage("항목이나 경로가 변경되었습니다. 핀 메뉴를 다시 여세요.")
    end
  end
  if MenuUtil and type(MenuUtil.CreateContextMenu)=="function" then
    MenuUtil.CreateContextMenu(pin,function(_,menu)
      menu:CreateTitle(position and ((ticket.route.name or "경로").." · "..position.." / "..total) or "Forever Note")
      for _,entry in ipairs(entries) do
        if entry.separator then
          if type(menu.CreateDivider)=="function" then menu:CreateDivider() else menu:CreateTitle("삭제") end
        else local selected=entry;menu:CreateButton(selected.label,function() perform(selected) end) end
      end
    end)
  elseif type(UIDropDownMenu_Initialize)=="function" and type(ToggleDropDownMenu)=="function" and
    type(UIDropDownMenu_CreateInfo)=="function" and type(UIDropDownMenu_AddButton)=="function" then
    self.todoPinMenu=self.todoPinMenu or CreateFrame("Frame","KHQOLNotePinMenu",UIParent,"UIDropDownMenuTemplate")
    UIDropDownMenu_Initialize(self.todoPinMenu,function()
      for _,entry in ipairs(entries) do
        local selected=entry;local info=UIDropDownMenu_CreateInfo();info.text=selected.label;info.notCheckable=true
        if entry.separator then info.text="──────────";info.isTitle=true;info.disabled=true
        else info.func=function() perform(selected) end end
        UIDropDownMenu_AddButton(info)
      end
    end,"MENU")
    ToggleDropDownMenu(1,nil,self.todoPinMenu,"cursor",0,0)
  else self:NoteCoordinateMessage("이 클라이언트에서 핀 메뉴를 열 수 없습니다. 노트에서 항목을 삭제하세요.") end
end
function FC:OnTodoMapCanvasClick(map,button,x,y)
  local drawing=self:GetTodoRouteDrawing()
  if button~="RightButton" or call(IsShiftKeyDown)~=true or call(IsControlKeyDown)==true or call(IsAltKeyDown)==true or
    not self:TodoMapPinsEnabled() or (not self:GetTodoNavigationOptions().shiftClick and not drawing) then return false end
  if combat() then self:NoteCoordinateMessage("전투 종료 후 지도 좌표를 추가할 수 있습니다.");return true end
  if drawing and not self:CanAddTodoDrawingPin(drawing) then return true end
  local id=call(map.GetMapID,map)
  id,x,y=self:ResolveTodoMapClick(id,x,y)
  local info=self:GetTodoMapInfo(id)
  if not info or not N.ValidPoint(id,x,y) then self:NoteCoordinateMessage("클릭한 지도의 지역·좌표를 확인할 수 없습니다.");return true end
  local label=string.format("%s %.1f, %.1f",info.name,x*100,y*100)
  local item,why=self:AddTodoCoordinate(id,x,y,label)
  if not item then self:NoteCoordinateMessage(why) end
  if item and drawing then self:AddTodoDrawingPin(item.id,drawing) end
  return true -- Consume only Shift+right click, preserving ordinary map zoom.
end
function FC:RefreshTodoMapPins()
  self:InstallNoteCoordinateCommands()
  self:InstallTodoMapPins()
  self:GetTodoPinLineOptions()
  self:GetTodoMapPinPoints(true)
  if self.todoPinGuidance and not combat() then self:ValidateTodoPinGuidance() end
  self:RefreshTodoMinimapPins()
  self:UpdateTodoArrivalDriver()
  local provider=self.todoMapProvider
  local map=provider and provider.owningMap
  if map and call(map.IsShown,map)==true then provider:RefreshAllData() end
  self:UpdateTodoRouteDrawingBar()
end
function FC:InstallTodoMapPins()
  if not self.todoMapEvents then
    self.todoMapEvents=CreateFrame("Frame")
    for _,event in ipairs({"ADDON_LOADED","PLAYER_REGEN_ENABLED","PLAYER_REGEN_DISABLED","PLAYER_ENTERING_WORLD","ZONE_CHANGED_NEW_AREA","MINIMAP_UPDATE_ZOOM","CVAR_UPDATE"}) do
      self.todoMapEvents:RegisterEvent(event)
    end
    self.todoMapEvents:SetScript("OnEvent",function(_,event,addon)
      if event=="CVAR_UPDATE" then
        -- Only minimap rotation is read by these pins. Other settings cannot
        -- invalidate note coordinates, native map pins or route line geometry.
        if K.IsPublicValue(addon) and type(addon)=="string" and addon:lower():gsub("_","")=="rotateminimap" then FC:RefreshTodoMinimapPins() end
        return
      end
      if event~="ADDON_LOADED" or addon=="Blizzard_WorldMap" or addon=="Blizzard_MapCanvas" then
        if event=="PLAYER_ENTERING_WORLD" or event=="ZONE_CHANGED_NEW_AREA" then FC:InvalidateTodoMapGeometry() end
        FC:RefreshTodoMapPins()
      end
    end)
  end
  local map=WorldMapFrame
  if self.todoMapProvider then return end
  if combat() then self.todoMapPinsReason="전투 종료 후 지도 핀을 적용합니다.";return end
  if not map or type(map.AcquirePin)~="function" or type(map.RemoveAllPinsByTemplate)~="function" or
    type(map.AddDataProvider)~="function" or type(map.AddCanvasClickHandler)~="function" or
    type(MapCanvasDataProviderMixin)~="table" or type(MapCanvasPinMixin)~="table" or type(CreateFromMixins)~="function" then
    self.todoMapPinsReason="기본 세계지도가 로드되면 지도 핀 지원을 확인합니다.";return
  end
  local provider=CreateFromMixins(MapCanvasDataProviderMixin)
  function provider:RemoveAllData()
    FC:HideTodoPinLines(self,true)
    self:GetMap():RemoveAllPinsByTemplate(TEMPLATE);self.notePins={};self.noteSnapshot=nil
  end
  function provider:RefreshAllData()
    if combat() then
      for _,pin in ipairs(self.notePins or {}) do call(pin.Hide,pin) end
      FC:HideTodoPinLines(self,true)
      self.noteSnapshot=nil
      FC.todoMapPinsReason="전투 종료 후 지도 핀을 갱신합니다.";return
    end
    local ok=pcall(function()
      if not FC:TodoMapPinsEnabled() then self:RemoveAllData();return end
      FC:EnsureTodoNavigationIDs()
      local current=call(self:GetMap().GetMapID,self:GetMap())
      local entries={}
      for _,entry in ipairs(FC:GetTodoMapPinPoints()) do
        local x,y=FC:ProjectTodoPoint(entry.point,current)
        if x then entries[#entries+1]={id=entry.id,x=x,y=y,label=entry.label,point=entry.point} end
      end
      local previous=self.noteSnapshot
      local same=previous and previous.mapID==current and #previous==#entries
      if same then for i,e in ipairs(entries) do
        local old=previous[i];if old.id~=e.id or old.x~=e.x or old.y~=e.y or old.label~=e.label or old.point.mapID~=e.point.mapID then same=false;break end
      end end
      if same then
        local numbers=FC:GetTodoRouteNumberLookup();for _,pin in ipairs(self.notePins or {}) do FC:UpdateTodoPinNumber(pin,numbers) end
        FC:RefreshTodoPinLines(self,previous);return
      end
      self:RemoveAllData()
      for _,e in ipairs(entries) do
        if N.ValidPoint(current,e.x,e.y) then self.notePins[#self.notePins+1]=self:GetMap():AcquirePin(TEMPLATE,e.id,{x=e.x,y=e.y}) end
      end
      entries.mapID=current;self.noteSnapshot=entries
      FC:RefreshTodoPinLines(self,entries)
    end)
    if not ok then FC:HideTodoPinLines(self,true);self:GetMap():RemoveAllPinsByTemplate(TEMPLATE);self.notePins={};self.noteSnapshot=nil end
    FC.todoMapPinsReason=not ok and "게임이 노트 지도 핀 표시를 지원하지 않거나 제한했습니다." or nil
  end
  function provider:OnShow() self:RefreshAllData();FC:UpdateTodoArrivalDriver();FC:UpdateTodoRouteDrawingBar() end
  function provider:OnCanvasScaleChanged() FC:UpdateTodoPinLines(self) end
  function provider:OnCanvasSizeChanged() FC:UpdateTodoPinLines(self) end
  -- Panning moves/clips the shared canvas; no per-dot writes are necessary.
  function provider:OnHide()
    FC:HideTodoPinLines(self,true)
    if not combat() then self:RemoveAllData() end
    if FC.todoPinMenu then call(FC.todoPinMenu.Hide,FC.todoPinMenu) end
    FC:UpdateTodoArrivalDriver()
    if FC.todoRouteDrawingBar then FC.todoRouteDrawingBar:Hide() end
  end
  local ok=pcall(map.AddDataProvider,map,provider)
  if not ok then self.todoMapPinsReason="이 클라이언트에서 노트 지도 핀 공급자를 등록할 수 없습니다.";return end
  self.todoMapProvider=provider
  local status=K.ReadPublicAPI(map.AddCanvasClickHandler,map,function(owningMap,button,x,y) return FC:OnTodoMapCanvasClick(owningMap,button,x,y) end,10)
  self.todoMapPinsReason=status~="ok" and "지도 클릭 등록이 제한되어 명령어·체크리스트로 좌표를 추가하세요." or nil
end
KHQOLNoteMapPinMixin={}
local Pin=KHQOLNoteMapPinMixin
function Pin:OnLoad()
  self:UseFrameLevelType("PIN_FRAME_LEVEL_TOPMOST");self:SetScalingLimits(1,1,1)
  self:SetIgnoreGlobalPinScale(true);self:SetAlphaLimits(1,1,1)
  self:SetIgnoreParentAlpha(true)
end
function Pin:OnAcquired(id,p)
  self.noteID=id;self.notePages=FC.db.todo.pages;self:SetAlpha(1);self:SetPosition(p.x,p.y)
  -- Reassert the original logo on pooled pins. No opaque minimap highlight
  -- overlay: that texture can cover the logo with a black square/blue ring.
  self:SetSize(26,26)
  if self.Icon then
    self.Icon:SetTexture("Interface\\AddOns\\KHQOL\\Media\\kh-qol-minimap-button.tga")
    self.Icon:SetVertexColor(1,1,1,1);self.Icon:SetAlpha(1)
    self.Icon:SetTexCoord(0,1,0,1);self.Icon:SetDesaturated(false);self.Icon:SetBlendMode("BLEND")
  end
  FC:UpdateTodoPinNumber(self)
end
function Pin:ShouldMouseButtonBePassthrough() return false end
function Pin:OnMouseClickAction(button)
  if not FC:TodoMapPinsEnabled() or self.notePages~=FC.db.todo.pages then return end
  local item=FC:FindTodoWaypoint(self.noteID);if not item or (item.done and not FC:TodoPinRoutePosition(item.id)) then return end
  local x,y=FC:ProjectTodoPoint(item.waypoint,call(self:GetMap().GetMapID,self:GetMap()))
  if not x or not N.ValidPoint(1,x,y) then return end
  if button=="LeftButton" then
    if FC:GetTodoRouteDrawing() then FC:AddTodoDrawingPin(item.id)
    elseif FC:GetTodoNavigationOptions().enabled then FC:TrackTodoWaypoint(item)
    else FC:NoteCoordinateMessage("길 안내는 편의 기능 > 노트 > 네비게이션 연결을 켜세요.") end
  elseif button=="RightButton" and call(IsShiftKeyDown)~=true then
    if combat() then FC:NoteCoordinateMessage("전투 종료 후 핀 메뉴를 사용할 수 있습니다.");return end
    self:OnMouseLeave();FC:OpenTodoPinMenu(self,item.waypoint.mapID)
  end
end
function Pin:OnMouseEnter()
  FC:ShowTodoPinTooltip(self)
end
function FC:ShowTodoPinTooltip(pin)
  if pin.notePages~=self.db.todo.pages then return end
  local item,page=self:FindTodoWaypoint(pin.noteID);local p=item and item.waypoint
  if not p or not N.ValidPoint(p.mapID,p.x,p.y) or not GameTooltip then return end
  local info=FC:GetTodoMapInfo(p.mapID)
  pcall(function()
    GameTooltip:SetOwner(pin,"ANCHOR_RIGHT");GameTooltip:SetText(N.IsText(p.label) and p.label or "노트 위치",.45,.8,.75)
    GameTooltip:AddLine(string.format("%s · %.2f, %.2f",info and info.name or "지도",p.x*100,p.y*100),1,1,1)
    GameTooltip:AddLine("Forever Note · "..(page.title or "노트"),.7,.7,.7)
    local position,total=FC:TodoPinRoutePosition(item.id,p.mapID)
    GameTooltip:AddLine(position and ("경로 "..position.." / "..total.." · 핀 메뉴에서 순서 변경") or "일반 핀 · 핀 메뉴에서 경로에 추가",.7,.7,.7)
    GameTooltip:AddLine(FC:GetTodoRouteDrawing() and "좌클릭: 경로에 추가 · 우클릭: 핀 메뉴" or "좌클릭: 길 안내 · 우클릭: 핀 메뉴",1,.82,0);GameTooltip:Show()
  end)
end
function Pin:OnMouseLeave() if GameTooltip and call(GameTooltip.GetOwner,GameTooltip)==self then GameTooltip:Hide() end end
function Pin:OnReleased()
  self:OnMouseLeave();self.noteID=nil;self.notePages=nil
  if self.RouteNumber then self.RouteNumber:Hide();self.todoRouteNumber=nil end
  if MapCanvasPinMixin then MapCanvasPinMixin.OnReleased(self) end
end
