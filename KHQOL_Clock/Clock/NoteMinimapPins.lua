local K=assert(_G.KHQOL,"Install and enable the KHQOL core addon.")
local FC,N=K.modules.clock,K.Navigation
local call=K.PublicCall
FC.DEFAULTS.todo.navigation.minimapPins=true
local function enabled() return FC:IsTodoCoordinateEnabled() and FC:GetTodoNavigationOptions().minimapPins~=false end
function FC:TodoMinimapPinsEnabled() return enabled() end
local function hide(state)
  if not state or state.hidden then return end
  for _,pin in ipairs(state and state.pool or {}) do pin:Hide() end
  state.snapshot=nil;state.hidden=true
end
local function createPin(state)
  local pin=CreateFrame("Button",nil,Minimap)
  pin.noteMiniMap=true;pin:SetSize(20,20);pin:SetFrameStrata("MEDIUM")
  pin:SetFrameLevel((call(Minimap.GetFrameLevel,Minimap) or 0)+8)
  pin:RegisterForClicks("LeftButtonUp","RightButtonUp")
  pin.Icon=pin:CreateTexture(nil,"ARTWORK");pin.Icon:SetAllPoints(pin)
  pin.Icon:SetTexture("Interface\\AddOns\\KHQOL\\Media\\kh-qol-minimap-button.tga")
  pin:SetScript("OnClick",function(self,button)
    if not enabled() or self.notePages~=FC.db.todo.pages then return end
    local item=FC:FindTodoWaypoint(self.noteID)
    if not item or ((item.done or FC:IsTodoWaypointArrived(item)) and not FC:TodoPinRoutePosition(item.id)) then return end
    if button=="RightButton" then FC:OpenTodoPinMenu(self,item.waypoint.mapID)
    elseif button=="LeftButton" then
      if FC:GetTodoRouteDrawing() and WorldMapFrame and call(WorldMapFrame.IsShown,WorldMapFrame)==true then FC:AddTodoDrawingPin(item.id)
      else FC:TrackTodoWaypoint(item) end
    end
  end)
  pin:SetScript("OnEnter",function(self) FC:ShowTodoPinTooltip(self) end)
  pin:SetScript("OnLeave",function(self)
    if GameTooltip and call(GameTooltip.GetOwner,GameTooltip)==self then GameTooltip:Hide() end
  end)
  state.pool[#state.pool+1]=pin;return pin
end
function FC:RefreshTodoMinimapPins()
  local state=self.todoMiniPinState
  if not enabled() or not Minimap or call(Minimap.IsShown,Minimap)~=true or call(InCombatLockdown)==true then hide(state);return end
  local player=self:GetTodoPlayerPoint()
  local radius=call(C_Minimap and C_Minimap.GetViewRadius)
  local w,h=call(Minimap.GetWidth,Minimap),call(Minimap.GetHeight,Minimap)
  if not player or not N.IsNumber(radius) or radius<=0 or not N.IsNumber(w) or w<=0 or not N.IsNumber(h) or h<=0 then
    hide(state);self.todoMiniPinReason="미니맵 위치·표시 반경을 확인할 수 없습니다.";return
  end
  local rotate=call(GetCVar,"rotateMinimap")=="1" and call(C_Minimap and C_Minimap.IsRotateMinimapIgnored)~=true
  local facing=rotate and call(GetPlayerFacing) or 0
  if not N.IsNumber(facing) then hide(state);return end
  local shape=call(GetMinimapShape) or "ROUND"
  local active=N:GetActiveDestination();local activeID=active and (active.source=="ForeverNote" or active.source=="ForeverNoteRoute") and active.id
  if not state then state={pool={}};self.todoMiniPinState=state end
  state.hidden=nil
  local key=table.concat({player.mapID,player.x,player.y,radius,w,h,facing,shape,self.todoPinRevision or 0,K.profileGeneration or 0,activeID or ""},":")
  if state.snapshot==key then return end
  state.snapshot=key;self.todoMiniPinReason=nil
  local numbers=self:GetTodoRouteNumberLookup()
  local candidates={}
  for _,entry in ipairs(self:GetTodoMapPinPoints()) do
    local dx,dy=self:GetTodoPointOffset(player,entry.point)
    if dx then
      local sq=dx*dx+dy*dy
      if sq<=(radius*.84)^2 or entry.id==activeID then candidates[#candidates+1]={entry=entry,dx=dx,dy=dy,sq=sq} end
    end
  end
  table.sort(candidates,function(a,b)
    if (a.entry.id==activeID)~=(b.entry.id==activeID) then return a.entry.id==activeID end
    return a.sq==b.sq and a.entry.id<b.entry.id or a.sq<b.sq
  end)
  local used=0
  for i=1,math.min(#candidates,128) do
    local c=candidates[i]
    local x=(c.dx*math.cos(facing)-c.dy*math.sin(facing))/radius
    local y=(c.dx*math.sin(facing)+c.dy*math.cos(facing))/radius
    -- A circle remains inside all native/custom mask shapes, including corners.
    local limit=shape=="SQUARE" and math.max(math.abs(x),math.abs(y)) or math.sqrt(x*x+y*y)
    if limit>.84 then x=x*.84/limit;y=y*.84/limit end
    used=used+1;local pin=state.pool[used] or createPin(state)
    pin.noteID=c.entry.id;pin.notePages=self.db.todo.pages
    self:UpdateTodoPinNumber(pin,numbers)
    pin:ClearAllPoints();pin:SetPoint("CENTER",Minimap,"CENTER",x*w/2,-y*h/2);pin:Show()
  end
  for i=used+1,#state.pool do state.pool[i]:Hide() end
end
