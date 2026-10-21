local K=assert(_G.KHQOL,"Install and enable the KHQOL core addon.")
local FC,N=K.modules.clock,K.Navigation
local call=K.PublicCall
local R={MAX_PINS=128,MAX_DOTS=512,SPACING=6}
FC.NotePinRoutes=R
FC.DEFAULTS.todo.navigation.pinLines={visible=true,style="DOTTED",width=3,color={.1,1,1,1}}

function FC:GetTodoPinLineOptions()
  local options=self:GetTodoNavigationOptions().pinLines
  if not options.contrastVersion then
    local c=options.color or {}
    if options.width==2 and c[1]==1 and c[2]==.82 and c[3]==.15 and c[4]==.8 then
      options.width=3;options.color={.1,1,1,1}
    end
    options.contrastVersion=1
  end
  return options
end
function FC:GetTodoMapPinPoints(refresh)
  if refresh then self.todoPinPoints=nil;self.todoPinRevision=(self.todoPinRevision or 0)+1 end
  local route=self:GetTodoPinRoute(nil)
  local start,target=self:GetTodoPinRouteDisplayStart(route)
  local targetID,source=target and target.id,target and target.source
  if self.todoPinDisplayRoute~=route or self.todoPinDisplayStart~=start or self.todoPinDisplayTarget~=targetID or self.todoPinDisplaySource~=source then
    self.todoPinPoints=nil;self.todoPinRevision=(self.todoPinRevision or 0)+1
    self.todoPinDisplayRoute,self.todoPinDisplayStart,self.todoPinDisplayTarget,self.todoPinDisplaySource=route,start,targetID,source
  end
  if not self.todoPinPoints then
    local entries,items={},{}
    local guidance=self.todoPinGuidance
    local hiddenIDs,activeIDs={},{}
    if self:GetTodoRouteDrawing() and route then for _,id in ipairs(route.pinIDs) do activeIDs[id]=true end end
    if start and route then for i,id in ipairs(route.pinIDs) do
      if i<start then hiddenIDs[id]=true
      elseif guidance and guidance.route==route then activeIDs[id]=true end
    end end
    if targetID then activeIDs[targetID]=true end
    self:EachTodoTask(function(item,page)
      local p=item.waypoint
      if page.mode=="checklist" and type(item.id)=="string" and type(p)=="table" and N.ValidPoint(p.mapID,p.x,p.y) then items[item.id]=item end
      if page.mode=="checklist" and type(item.id)=="string" and not hiddenIDs[item.id] and ((not item.done and not self:IsTodoWaypointArrived(item)) or activeIDs[item.id]) and type(p)=="table" and N.ValidPoint(p.mapID,p.x,p.y) then
        entries[#entries+1]={id=item.id,label=p.label,point={mapID=p.mapID,x=p.x,y=p.y,label=p.label}}
      end
    end)
    self.todoPinPoints=entries
    self.todoPinItems=items
  end
  return self.todoPinPoints
end
function FC:GetTodoPinLineTarget()
  if not self:IsTodoCoordinateEnabled() then return end
  local target=N:GetActiveDestination()
  if target and (target.source=="ForeverNote" or target.source=="ForeverNoteRoute") and N.ValidPoint(target.mapID,target.x,target.y) then return target end
end
function FC:GetTodoPinRouteDisplayStart(route)
  if self.GetTodoRouteDrawing and self:GetTodoRouteDrawing() then return nil,nil end
  local target=self:GetTodoPinLineTarget()
  if route and target then
    if target.source=="ForeverNoteRoute" then
      local plan=self.todoPinGuidance
      if plan and plan.route==route and plan.ids[plan.index]==target.id then return plan.index,target end
    else
      for i,id in ipairs(route.pinIDs) do if id==target.id then return i,target end end
    end
  end
  return nil,target
end
function FC:RefreshTodoNavigationLine()
  local provider=self.todoMapProvider
  if provider and call(InCombatLockdown)~=true and call(provider:GetMap().IsShown,provider:GetMap())==true then
    -- A changed waypoint also changes which visited pins remain on the map.
    provider:RefreshAllData()
  end
  self:UpdateTodoArrivalDriver()
end
function FC:BuildTodoPinRouteSegments(entries,mapID)
  local route=self:GetTodoPinRoute(nil)
  local segments={}
  self:GetTodoMapPinPoints()
  local function connect(a,b,guide)
    if not a or not b or not self:TodoPointsShareWorld(a,b) then return end
    local ax,ay=self:ProjectTodoPoint(a,mapID);local bx,by=self:ProjectTodoPoint(b,mapID)
    if ax==nil or bx==nil then return end
    local x1,y1,x2,y2=self:ClipTodoMapSegment(ax,ay,bx,by)
    if x1 then segments[#segments+1]={from=a.id,to=b.id,x1=x1,y1=y1,x2=x2,y2=y2,guide=guide==true} end
  end
  local function point(id)
    local item=self.todoPinItems[id];local p=item and item.waypoint
    if p then return {id=id,mapID=p.mapID,x=p.x,y=p.y} end
  end
  -- During guidance, draw only current-to-future saved legs. The incoming
  -- saved leg is replaced by player-to-current, never drawn beside it.
  local start,target=self:GetTodoPinRouteDisplayStart(route)
  if route and route.visible~=false then
    for i=start or 1,math.min(#route.pinIDs,R.MAX_PINS)-1 do connect(point(route.pinIDs[i]),point(route.pinIDs[i+1]),false) end
  end
  -- Use the same destination as the arrow for both normal pin guidance and
  -- saved routes, including the approach from the player to the first pin.
  if target and (target.source~="ForeverNoteRoute" or not route or route.visible~=false) then
    local player=self:GetTodoPlayerPoint()
    if player then player.id="player";connect(player,{id=target.id,mapID=target.mapID,x=target.x,y=target.y},true) end
  end
  return segments
end
local function sameSegments(a,b)
  if not a or #a~=#b then return false end
  for i,s in ipairs(b) do
    local old=a[i]
    if old.from~=s.from or old.to~=s.to or old.x1~=s.x1 or old.y1~=s.y1 or old.x2~=s.x2 or old.y2~=s.y2 or old.guide~=s.guide then return false end
  end
  return true
end
function FC:HideTodoPinLines(provider,clear)
  local state=provider and provider.noteLineState
  if state then
    if state.root then state.root:Hide() end
    state.paint=nil;state.visibleDots=0
    if clear then state.segments=nil;state.mapID=nil end
  end
end
local function bounded(value,low,high,fallback)
  return N.IsNumber(value) and math.max(low,math.min(high,value)) or fallback
end
local function paint(provider)
  local state,map=provider.noteLineState,provider:GetMap()
  local options=FC:GetTodoPinLineOptions()
  if not FC:TodoMapPinsEnabled() or not options.visible or not state or not state.segments or #state.segments==0 or
    call(InCombatLockdown)==true or call(map.IsShown,map)~=true or call(map.GetMapID,map)~=state.mapID then
    FC:HideTodoPinLines(provider);return
  end
  local canvas=call(map.GetCanvas,map)
  local viewport=call(map.GetCanvasContainer,map)
  -- The native ScrollFrame clips every child of the same canvas used by pins.
  -- Require that relationship instead of guessing a different projection.
  if not canvas or not viewport or call(viewport.IsObjectType,viewport,"ScrollFrame")~=true or
    call(viewport.GetScrollChild,viewport)~=canvas then error("unsupported map canvas") end
  local width,height=call(canvas.GetWidth,canvas),call(canvas.GetHeight,canvas)
  local zoom=call(map.GetCanvasScale,map)
  if not N.IsNumber(width) or width<=0 or not N.IsNumber(height) or height<=0 or not N.IsNumber(zoom) or zoom<=0 then
    FC:HideTodoPinLines(provider);return
  end
  local color=type(options.color)=="table" and options.color or {}
  local r,g,b,alpha=bounded(color[1],0,1,.1),bounded(color[2],0,1,1),bounded(color[3],0,1,1),bounded(color[4],0,1,1)
  local thickness=bounded(options.width,1,6,3)
  local previous=state.paint
  if previous and state.canvas==canvas and previous.w==width and previous.h==height and previous.z==zoom and
    previous.r==r and previous.g==g and previous.b==b and previous.a==alpha and previous.t==thickness then return end
  if not state.root then
    state.root=CreateFrame("Frame",nil,canvas)
    state.root:EnableMouse(false);state.root:SetClipsChildren(true)
    state.pool={}
  end
  local root=state.root
  if state.canvas~=canvas then root:SetParent(canvas);root:ClearAllPoints();root:SetAllPoints(canvas);state.canvas=canvas end
  local level=call(canvas.GetFrameLevel,canvas)
  local pinLevel
  for _,pin in ipairs(provider.notePins or {}) do
    local value=call(pin.GetFrameLevel,pin)
    if N.IsNumber(value) then pinLevel=pinLevel and math.min(pinLevel,value) or value end
  end
  if not N.IsNumber(level) or (pinLevel and pinLevel<=level+1) then error("unsupported pin layer") end
  root:SetFrameLevel(pinLevel and pinLevel-1 or level+1)
  local extra,totalExtra={},0
  for i,s in ipairs(state.segments) do
    local dx,dy=(s.x2-s.x1)*width*zoom,(s.y2-s.y1)*height*zoom
    extra[i]=math.max(0,math.ceil(math.sqrt(dx*dx+dy*dy)/R.SPACING)-2)
    totalExtra=totalExtra+extra[i]
  end
  local budget=R.MAX_DOTS-3*#state.segments
  local used=0
  for i,s in ipairs(state.segments) do
    local cr,cg,cb,ca=r,g,b,alpha
    if s.guide then cr,cg,cb,ca=1,1,1,1 end
    local additional=totalExtra<=budget and extra[i] or math.floor(extra[i]*budget/totalExtra)
    local intervals=2+additional
    for index=0,intervals do
      used=used+1
      local dot=state.pool[used]
      if not dot then
        dot=root:CreateTexture(nil,"ARTWORK");dot.outline=root:CreateTexture(nil,"BACKGROUND")
        state.pool[used]=dot
      end
      local fraction=index/intervals
      local x,y=(s.x1+(s.x2-s.x1)*fraction)*width,-(s.y1+(s.y2-s.y1)*fraction)*height
      if dot.routeX~=x or dot.routeY~=y or dot.routeCanvas~=canvas then
        dot:ClearAllPoints();dot:SetPoint("CENTER",canvas,"TOPLEFT",x,y)
        dot.routeX,dot.routeY,dot.routeCanvas=x,y,canvas
      end
      if dot.routeZoom~=zoom or dot.routeThickness~=thickness then
        dot:SetSize(thickness/zoom,thickness/zoom)
        dot.outline:ClearAllPoints();dot.outline:SetPoint("CENTER",dot,"CENTER")
        dot.outline:SetSize((thickness+2)/zoom,(thickness+2)/zoom)
        dot.outline:SetColorTexture(0,0,0,.95)
        dot.routeZoom,dot.routeThickness=zoom,thickness
      end
      if dot.routeR~=cr or dot.routeG~=cg or dot.routeB~=cb or dot.routeAlpha~=ca then
        dot:SetColorTexture(cr,cg,cb,ca);dot.routeR,dot.routeG,dot.routeB,dot.routeAlpha=cr,cg,cb,ca
      end
      dot:Show();dot.outline:Show()
    end
  end
  for i=used+1,#state.pool do state.pool[i]:Hide();state.pool[i].outline:Hide() end
  state.visibleDots=used
  state.paint={w=width,h=height,z=zoom,r=r,g=g,b=b,a=alpha,t=thickness}
  root:Show()
end
function FC:UpdateTodoPinLines(provider)
  local ok,why=pcall(paint,provider)
  self.todoPinLinesReason=not ok and "이 클라이언트에서 핀 연결선을 표시할 수 없습니다. 핀과 노트는 유지됩니다." or nil
  if not ok then self:HideTodoPinLines(provider);provider.noteLineError=why else provider.noteLineError=nil end
end
function FC:RefreshTodoPinLines(provider,entries)
  local state=provider.noteLineState
  if not state then state={};provider.noteLineState=state end
  local mapID=call(provider:GetMap().GetMapID,provider:GetMap())
  local segments=self:BuildTodoPinRouteSegments(entries,mapID)
  if state.mapID~=mapID or not sameSegments(state.segments,segments) then state.segments=segments;state.mapID=mapID;state.paint=nil end
  self:UpdateTodoPinLines(provider)
end
