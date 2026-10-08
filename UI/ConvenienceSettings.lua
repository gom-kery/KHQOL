local _, KHQOL = ...
local UI=KHQOL.UI
local A=KHQOL.AlertSettings
local Convenience={tabs={},selected="general",RegisterTab=A.RegisterTab,BuildSettings=A.BuildSettings}
KHQOL.ConvenienceSettings=Convenience
local function noteSettings(content,y)
  local b=UI:CreateBuilder(content,y); b:Section("노트 사용")
  b:Description("시계 우클릭 또는 ForeverNote 미니맵 버튼으로 노트 창을 열고 닫을 수 있습니다.")
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
Convenience:RegisterTab("general","일반",function(content,y)
  y=UI:CreatePage(content,"일반","판매·수리·초대 관련 편의 기능을 설정합니다.")
  function content:RefreshTab()
    if KHQOL.settings then KHQOL.settings:SetActiveSettingsModule(nil) end
  end
  return KHQOL.modules.general:BuildSettings(content,y)
end)
local function register(id,title,key,description,build)
  Convenience:RegisterTab(id,title,function(content)
    return UI:BuildModuleTab(content,key,title,description,build)
  end)
end
register("clock","Clock","clock","시간, 날짜, 요일 및 HUD 정보를 표시합니다.",function(content,y)
  local fc=KHQOL.modules.clock
  fc:CreateHeaderHelp(content)
  return UI:EmbedModulePanel(content,fc.settingsFrame,y,function() fc:RefreshSettings() end)
end)
register("note","Note","todo","화면의 노트 창에서 할 일과 메모를 관리합니다.",noteSettings)
register("quest","Quest","questNavigator","추적 중인 퀘스트의 목표·반납 위치를 안내하고 다음 퀘스트를 선택합니다.",function(content,y)
  return KHQOL.modules.questNavigator:BuildSettings(content,y)
end)
