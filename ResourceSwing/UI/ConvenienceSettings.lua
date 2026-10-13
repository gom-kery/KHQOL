local _, KHQOL = ...
local UI=KHQOL.UI
local Convenience=UI:NewSettingsGroup("convenience")
KHQOL.ConvenienceSettings=Convenience
local function noteSettings(content,y)
  local b=UI:CreateBuilder(content,y); b:Section("노트 사용")
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
  b:Button("미니맵 위치 편집",function() KHQOL.PositionEditor:Enter("note.minimap") end)
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
  b:Description("단축키는 게임 메뉴의 설정 > 단축키에서 지정할 수 있습니다. 노트 내용과 메모는 노트 창에서 직접 편집합니다."); return b.y
end
Convenience:RegisterTab("general",nil,function(content,y)
  content.moduleKey=nil
  return KHQOL.modules.generalConvenience:BuildSettings(content,y)
end)
Convenience:RegisterTab("note",nil,noteSettings)
