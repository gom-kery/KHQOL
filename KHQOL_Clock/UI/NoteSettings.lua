local KHQOL=_G.KHQOL
local UI=KHQOL.UI
local function noteSettings(content,y)
  local b=UI:CreateBuilder(content,y); b:Section("노트 사용")
  b:Description("노트 본문·체크리스트·완료 상태는 계정 공용이며 노트 창에서 편집합니다. 아래 표시·모양 설정은 현재 전체 프로필에 저장합니다. 노트 닫기는 내용 되돌리기가 아닙니다.",true)
  b:Button("노트 열기",function() local fc=KHQOL.modules.clock;if not fc.todoFrame or not fc.todoFrame:IsShown() then fc:ToggleTodo() end end)
  b:Description("시계 우클릭 · ForeverNote 미니맵 · 게임 메뉴 > 단축키. 본문·체크리스트는 노트 창에서 편집합니다.",true)
  b:Section("위치")
  b:Checkbox("위치 잠금",function() return KHQOL.modules.clock.db.todo.window.positionLocked end,function(v) KHQOL.modules.clock.db.todo.window.positionLocked=v end)

  b:Section("창 크기·모양")
  b:Description("노트 우측 하단을 드래그해 크기 조절. 창의 위치·크기·글자·불투명도는 현재 프로필에 저장합니다.",true)
  b:Slider("글자 크기",15,30,1,function() return KHQOL.modules.clock.db.todo.fontSize end,function(v) KHQOL.modules.clock:SetTodoFontSize(v) end,function(v) return v.." px" end)
  b:Slider("배경 불투명도",10,95,5,function() return math.floor((KHQOL.modules.clock.db.todo.backgroundAlpha or .85)*100+.5) end,function(v) KHQOL.modules.clock:SetTodoOpacity(v) end,function(v) return v.."%" end)
  b:Section("열기·닫기")
  b:Checkbox("노트 미니맵 버튼 표시",function() return KHQOL.modules.clock.db.todo.minimap.show~=false end,function(v) KHQOL.modules.clock.db.todo.minimap.show=v;KHQOL.modules.clock:UpdateTodoMinimapButton() end)
  b:Description("노트 미니맵 버튼은 위치 편집 없이 왼쪽 버튼으로 끌어 이동합니다.",true)
  b:Checkbox("ESC로 노트 닫기",function() return KHQOL.modules.clock.db.todo.closeOnEscape ~= false end,function(on)
    KHQOL.modules.clock.db.todo.closeOnEscape=on and true or false
    KHQOL.modules.clock:UpdateTodoEscapeBinding()
  end)
  b:Section("체크리스트 네비게이션")
  local fc=KHQOL.modules.clock
  local function changed() fc:RefreshTodoNavigation(); if fc.todoFrame then fc:RefreshTodo() end end
  b:Checkbox("네비게이션 연결",function() return fc:GetTodoNavigationOptions().enabled end,function(on)
    fc:GetTodoNavigationOptions().enabled=on; changed()
  end)
  local function connected() return fc:GetTodoNavigationOptions().enabled end
  b:Checkbox("완료 시 다음 위치 자동 안내",function() return fc:GetTodoNavigationOptions().autoAdvance end,function(on)
    fc:GetTodoNavigationOptions().autoAdvance=on; changed()
  end,connected)
  b:Checkbox("좌표 항목에 ▶ 버튼 표시",function() return fc:GetTodoNavigationOptions().showTrackButton end,function(on)
    fc:GetTodoNavigationOptions().showTrackButton=on; changed()
  end,connected)
  b:Description("체크리스트에 /way 46 73 희귀몹, /way 오그리마 59 44 메모 또는 /way #1454 58.8 43.8 메모 입력. 지역명은 클라이언트 지도 이름과 일치해야 합니다. 지역 생략 시 현재 지역이며 희귀몹 확인 @46,73도 지원합니다.")
  b:Description("잘못된 지역명·mapID는 좌표로 등록하지 않습니다. 동명 지역은 #mapID로 구분하세요. 자동 안내는 퀘스트가 우선이며, 노트는 현재 지도에서 비교 가능한 좌표를 안내합니다. ▶ 수동 안내 후 AUTO로 복귀합니다.")
  b:Section("노트 지도 좌표")
  b:Checkbox("세계지도에 노트 좌표 핀 표시",function() return fc:GetTodoNavigationOptions().mapPins end,function(on)
    fc:GetTodoNavigationOptions().mapPins=on;changed()
  end)
  b:Checkbox("미니맵에 노트 좌표 핀 표시",function() return fc:GetTodoNavigationOptions().minimapPins~=false end,function(on)
    fc:GetTodoNavigationOptions().minimapPins=on;changed()
  end)
  b:Checkbox("지도 Shift+우클릭으로 좌표 추가",function() return fc:GetTodoNavigationOptions().shiftClick end,function(on)
    fc:GetTodoNavigationOptions().shiftClick=on;changed()
  end,function() return fc:GetTodoNavigationOptions().mapPins end)
  b:Checkbox("도착한 핀 숨기기",function() return fc:GetTodoNavigationOptions().hideArrived end,function(on)
    fc:GetTodoNavigationOptions().hideArrived=on;changed()
  end)
  b:Button("도착한 핀 다시 표시",function() fc:ResetTodoArrivedPins() end)
  local function linesChanged() fc:RefreshTodoMapPins() end
  b:Checkbox("핀 연결선 표시",function() return fc:GetTodoNavigationOptions().pinLines.visible end,function(on)
    fc:GetTodoNavigationOptions().pinLines.visible=on;linesChanged()
  end,function() return fc:GetTodoNavigationOptions().mapPins end)
  local function linesAvailable() return fc:GetTodoNavigationOptions().mapPins and fc:GetTodoNavigationOptions().pinLines.visible end
  b:Color("연결선 색상·투명도",function() return unpack(fc:GetTodoNavigationOptions().pinLines.color) end,function(r,g,blue,alpha)
    fc:GetTodoNavigationOptions().pinLines.color={r,g,blue,alpha or 1};linesChanged()
  end,linesAvailable,nil,true)
  b:Slider("연결선 두께",1,6,1,function() return fc:GetTodoNavigationOptions().pinLines.width end,function(value)
    fc:GetTodoNavigationOptions().pinLines.width=value;linesChanged()
  end,function(value) return value.." px" end,linesAvailable)
  b:Description("새 경로 그리기를 시작하면 Shift+우클릭으로 찍는 새 핀이 순서대로 자동 등록됩니다. 기존 핀도 좌클릭 한 번으로 추가합니다. 지도에서 그리기 완료 또는 안내 시작을 누르세요. 선택 경로의 핀에는 순번을 표시합니다.",true)
  b:Description("밝은 청록색 3px 점선에 검정 외곽선을 표시합니다. 지역·대륙·전체 지도에서 핀을 확인할 수 있습니다. 미니맵은 주변 핀과 현재 안내 중인 핀(범위 밖은 가장자리)을 표시합니다.",true)
  b:Description("핀 우클릭 → 여기로 안내 시작: 선택한 핀부터 경로 끝까지 안내합니다. 안내 중에는 지나온 핀·구간을 숨기고 내 위치 → 현재 경유지를 흰 선, 이후 경로를 설정한 색상으로 표시합니다. 저장된 순서는 유지하며 경로에 없는 핀은 바로 안내합니다.",true)
  local lineHint="이름 있는 경로와 핀 순서는 계정 공용, 선 모양은 현재 프로필에 저장합니다. 기존 공용 경로는 기본 경로로 유지합니다."
  local lineStatus=b:Description(lineHint,true)
  content.uiControls[#content.uiControls+1]={Refresh=function() lineStatus:SetText(fc.todoPinLinesReason or fc.todoPinRouteReason or lineHint) end}
  b:Section("저장된 경로")
  b:Description("경로는 최대 32개까지 계정 공용으로 저장합니다. 편집은 즉시 반영되며 프로필을 바꿔도 유지합니다. 경로 삭제는 핀과 노트를 삭제하지 않습니다.",true)
  local function route() return fc:GetTodoPinRoute(nil) end
  local function editable() return fc:IsTodoCoordinateEnabled() and KHQOL.PublicCall(InCombatLockdown)~=true end
  local function hasRoute() return editable() and route()~=nil end
  b:Dropdown("저장된 경로 선택",function() return fc:GetTodoPinRouteOptions() end,function() local r=route();return r and r.id or "" end,
    function(id) fc:SelectTodoPinRoute(id) end,editable)
  local nameEdit
  nameEdit=b:Edit("경로 이름",function() local r=route();return r and r.name or "" end,function(name)
    local r=route()
    if r and (not nameEdit.routeID or nameEdit.routeID==r.id) and (not nameEdit.routeGeneration or nameEdit.routeGeneration==KHQOL.profileGeneration) then
      fc:RenameTodoPinRoute(r.id,name)
    else fc:NoteCoordinateMessage("경로가 변경되었습니다. 이름을 다시 입력하세요.") end
  end,hasRoute)
  nameEdit:HookScript("OnEditFocusGained",function(self) local r=route();self.routeID=r and r.id;self.routeGeneration=KHQOL.profileGeneration end)
  b:Button("새 경로 그리기",function() fc:BeginTodoRouteDrawing(true) end,nil,editable)
  b:Button("선택 경로 이어그리기",function() fc:BeginTodoRouteDrawing(false) end,nil,hasRoute)
  b:Button("그리기 완료",function() fc:FinishTodoRouteDrawing(false,fc.todoRouteDrawing) end,nil,function() return fc:GetTodoRouteDrawing()~=nil end)
  b:Button("경로 저장",function() local r=route();if r then fc:SaveTodoPinRoute(r.id) end end,nil,hasRoute)
  b:Button("선택 경로 삭제",function() local r=route();if r then fc:DeleteTodoPinRoute(r.id) end end,nil,hasRoute)
  b:Checkbox("선택 경로 표시",function() local r=route();return r and r.visible~=false or false end,function(on)
    local r=route();if r then r.visible=on;fc:RefreshTodoRouteView() end
  end,hasRoute)
  b:Checkbox("선택 경로 안내 사용",function() local r=route();return r and r.navigationEnabled~=false or false end,function(on)
    local r=route();if r then r.navigationEnabled=on;if not on and fc.todoPinGuidance and fc.todoPinGuidance.routeID==r.id then fc:StopTodoPinGuidance(true,"경로 안내 사용 해제") end end
  end,hasRoute)
  b:Dropdown("추가할 핀",function() return fc:GetTodoRoutePinOptions(false) end,function() return fc.todoRouteAddPin or "" end,
    function(id) fc.todoRouteAddPin=id end,hasRoute)
  b:Button("선택한 핀 추가",function() local t=fc:CreateTodoPinRouteTicket(fc.todoRouteAddPin);if t then fc:ChangeTodoPinRoute(t,"add") end end,nil,
    function() return hasRoute() and fc.todoRouteAddPin and fc:FindTodoWaypoint(fc.todoRouteAddPin)~=nil and not fc:TodoPinRoutePosition(fc.todoRouteAddPin) end)
  b:Dropdown("편집할 경유지",function() return fc:GetTodoRoutePinOptions(true) end,function() return fc.todoRouteSelectedPin or "" end,
    function(id) fc.todoRouteSelectedPin=id end,hasRoute)
  local function member() return hasRoute() and fc.todoRouteSelectedPin and fc:TodoPinRoutePosition(fc.todoRouteSelectedPin)~=nil end
  local function move(action) local t=fc:CreateTodoPinRouteTicket(fc.todoRouteSelectedPin);if t then fc:ChangeTodoPinRoute(t,action) end end
  b:Button("경유지 순서 앞으로",function() move("up") end,nil,function() return member() and fc:TodoPinRoutePosition(fc.todoRouteSelectedPin)>1 end)
  b:Button("경유지 순서 뒤로",function() move("down") end,nil,function() if not member() then return false end;local i,n=fc:TodoPinRoutePosition(fc.todoRouteSelectedPin);return i<n end)
  b:Button("선택 경유지 제외",function() move("remove") end,nil,member)
  b:Section("경로 안내")
  local function canStart() local r=route();return editable() and r and r.navigationEnabled~=false and #r.pinIDs>0 and #r.pinIDs<=128 end
  local function active() return editable() and fc.todoPinGuidance~=nil end
  b:Button("처음부터 안내",function() fc:StartTodoSavedRoute("first") end,nil,canStart)
  b:Button("가까운 경유지부터 안내",function() fc:StartTodoSavedRoute("nearest") end,nil,canStart)
  b:Button("일시 정지 / 재개",function() local p=fc.todoPinGuidance;if p then fc:ControlTodoPinGuidance(p.paused and "resume" or "pause",p) end end,nil,active)
  b:Button("경로 안내 종료",function() fc:ControlTodoPinGuidance("stop",fc.todoPinGuidance) end,nil,active)
  b:Button("이전 경유지",function() fc:ControlTodoPinGuidance("previous",fc.todoPinGuidance) end,nil,function() return active() and fc.todoPinGuidance.index>1 end)
  b:Button("다음 경유지",function() fc:ControlTodoPinGuidance("next",fc.todoPinGuidance) end,nil,active)
  b:Slider("경유지 도착 반경",3,50,1,function() return fc:GetTodoRouteNavigationOptions().arrivalRadius end,
    function(v) fc:GetTodoRouteNavigationOptions().arrivalRadius=v end,function(v) return v.." yd" end)
  b:Checkbox("경로 이탈 알림",function() return fc:GetTodoRouteNavigationOptions().deviationEnabled end,
    function(on) fc:GetTodoRouteNavigationOptions().deviationEnabled=on end)
  b:Slider("경로 이탈 거리",20,1000,10,function() return fc:GetTodoRouteNavigationOptions().deviationThreshold end,
    function(v) fc:GetTodoRouteNavigationOptions().deviationThreshold=v end,function(v) return v.." yd" end,function() return fc:GetTodoRouteNavigationOptions().deviationEnabled end)
  local routeStatus=b:Description(fc:GetTodoRouteStatus(),true)
  content.uiControls[#content.uiControls+1]={Refresh=function() routeStatus:SetText(fc:GetTodoRouteStatus()) end}
  b:Description("거리 확인이 가능할 때만 자동 도착·이탈을 판정합니다. 위치를 확인할 수 없으면 다음/이전으로 수동 이동하세요. 일시 정지 중에는 자동 전환하지 않습니다. 종료하면 기존 수동 목적지 또는 퀘스트 안내로 돌아갑니다.",true)
  b:Description("등록한 경유지를 잇는 안내입니다. 도로 자동 탐색·안전 경로 보장·비행편·선박 경로 계산은 제공하지 않습니다.",true)
  b:Description("26px KHQOL 원본 아이콘과 선택 경로의 순번으로 좌표를 표시합니다. 그리기 중에는 새 핀과 클릭한 기존 핀이 경로에 이어집니다. 완료하면 일반 핀 좌클릭 길 안내·우클릭 메뉴로 돌아갑니다. 메모는 노트에서 변경합니다.",true)
  b:Description("핀 메뉴: 해당 핀 삭제 / 지도 내 핀 삭제 / 전체 핀 삭제. 미완료 노트 좌표 항목도 함께 삭제하며 되돌리기 창은 없습니다. 도착하여 숨긴 핀도 삭제 범위에 포함됩니다. 기본 지도 핀·다른 애드온 핀은 유지합니다.",true)
  b:Description("도착한 핀 숨기기 ON: 일반 핀은 같은 지도에서 10야드 이내 도착 시 숨깁니다. 경로 안내 중에는 현재·남은 경유지만 표시하고, 이전 경유지를 선택하면 해당 구간을 다시 표시합니다. 노트 안내 대상이 없으면 전체 경로 선을 표시하며 핀은 기존 숨김 설정을 따릅니다. 노트 내용·완료 체크는 바꾸지 않습니다.",true)
  b:Description("/nt way 46 73 메모 · /노트 way 1454 59 44 메모 · /nt way 오그리마 59 44 메모. 명령어·지도 추가는 별도의 ‘좌표’ 체크리스트에 저장합니다. 동명 지역·숫자로 시작하는 메모는 #mapID를 사용하세요.",true)
  b:Description("일반 우클릭·기본 핀은 유지합니다. 전투 중 지도 편집·갱신은 보류합니다. 지역·대륙·전체 지도와 미니맵에서 표시하며, 공개 좌표를 확인할 수 없는 경우 해당 표시만 보류하고 저장된 핀과 경로를 유지합니다.",true)
  b:Description("단축키는 게임 메뉴의 설정 > 단축키에서 지정할 수 있습니다. 노트 내용과 메모는 노트 창에서 직접 편집합니다."); return b.y
end
KHQOL.ConvenienceSettings:RegisterTab("note",nil,noteSettings)
