local _, KHQOL = ...
local UI, T = KHQOL.UI, KHQOL.UI.Theme
-- Compact only navigation and the general module grid; retain control sizes.
local defaultRowStep = T.RowHeight + T.RowGap
local menuRowStep = T.ButtonHeight + math.max(0, defaultRowStep - T.ButtonHeight) / 2
local moduleRowStep = T.CheckboxSize + math.max(0, defaultRowStep - T.CheckboxSize) / 3
local definitions = {
  {"clock", "Clock", "시간, 날짜, 요일 및 HUD 정보를 표시합니다."},
  {"todo", "Note", "화면의 노트 창에서 할 일과 메모를 관리합니다."},
  {"buffReminder", "Buff Reminder", "버프가 없거나 만료되기 전에 화면에 알립니다."},
  {"range", "Range", "선택한 대상의 사거리 상태를 표시합니다."},
  {"tooltip", "Tooltip", "툴팁의 위치, 표시 방식 및 무기 전문가 안내를 조정합니다."},
  {"resourceSwing", "Resource Swing", "자원과 무기 스윙 바를 표시합니다."},
  {"campfire", "Campfire", "근처 모닥불과 야영 효과를 알립니다."},
  {"cursorTrail", "Cursor Trail", "마우스 이동 경로에 잔상을 표시합니다."},
  {"castBar", "Cast Bar", "플레이어의 주문 시전을 표시합니다."},
  {"combatStatus", "Combat Status", "전투 시작과 종료를 검 애니메이션으로 알립니다."},
  {"questNavigator", "Quest Navigator", "추적 중인 퀘스트의 목표·반납 위치를 안내하고 다음 퀘스트를 선택합니다."},
  {"threat", "Threat", "현재 선택한 적에 대한 내 어그로를 화면 원하는 위치에 표시합니다."},
  {"pvpAlert", "PvP Alert", "적 플레이어의 주시, 접근, 나를 향한 시전을 단계적으로 알립니다. 기본적으로 비전투 중에만 동작합니다."},
}
local pages = {
  {"general", "일반", "KHQOL 공통 설정 및 모듈 관리"},
  {"profiles", "프로필", "계정 공용 프로필 및 캐릭터별 사용 프로필 관리"},
  {"bars", "바 설정", "바 계열 기능과 환경 타이머를 관리합니다."},
  {"alerts", "알림", "NPC, 전투, 모닥불, 버프 및 PvP 알림을 관리합니다."},
  {"labs", "실험실", "개발 중이나 정상적으로 동작되지 않는 기능입니다."},
}
local alertTabs={npcAlert="npc",combatStatus="combat",campfire="campfire",buffReminder="buff",pvpAlert="pvp"}
local modules = {}
for _, definition in ipairs(definitions) do
  if KHQOL.modules[definition[1]] then modules[#modules+1] = definition end
end
table.sort(modules, function(a,b) return a[2]:lower() < b[2]:lower() end)
for _, definition in ipairs(modules) do
  if definition[1]~="castBar" and definition[1]~="resourceSwing" and not alertTabs[definition[1]] then pages[#pages+1] = definition end
end
UI.Pages = pages

-- Reset only after confirmation. The original module initializers supply defaults.
local function resetModule(key)
  if KHQOL.ResetProfileModule then
    local ok,message=KHQOL:ResetProfileModule(key)
    if not ok then KHQOL:ProfileMessage(message) end
    return
  end
  local legacy = {clock="ForeverClockDB",buffReminder="ForeverBuffReminderDB",range="FRangeDB",resourceSwing="KHQOLResourceSwingDB",campfire="CampfireAlertDB"}
  if key == "clock" then
    local todo = ForeverClockDB and ForeverClockDB.todo
    ForeverClockDB = todo and {todo=todo} or nil
  elseif key == "todo" then
    if ForeverClockDB then ForeverClockDB.todo = nil end
  elseif legacy[key] then _G[legacy[key]] = nil
  elseif key == "cursorTrail" then KHQOLCursorTrailCharDB = nil end
  KHQOL.db.modules[key] = nil
  KHQOL.db.migrated[key] = key == "tooltip" and true or nil
  ReloadUI()
end
StaticPopupDialogs.KHQOL_RESET_MODULE = {
  text="현재 프로필의 %s 모듈 설정을 기본값으로 복원하시겠습니까?\n노트 내용, ToDo 완료 상태와 등록한 버프는 유지합니다.",
  button1=ACCEPT,button2=CANCEL,OnAccept=function(_,key) resetModule(key) end,
  timeout=0,whileDead=1,hideOnEscape=1,
}
StaticPopupDialogs.KHQOL_RESET_ALL = {
  text="KHQOL 전체 설정을 초기화하시겠습니까?\n모든 프로필, 캐릭터별 선택, 노트와 등록한 버프를 포함한 KHQOL 데이터가 삭제되고 UI가 다시 로드됩니다.",
  button1=ACCEPT,button2=CANCEL,OnAccept=function()
    KHQOL.profileResetting=true
    KHQOLDB=nil; ForeverClockDB=nil; ForeverBuffReminderDB=nil; ForeverWeaponGuideDB=nil
    KHQOLResourceSwingDB=nil; CampfireAlertDB=nil; FRangeDB=nil; KHQOLCursorTrailCharDB=nil
    ReloadUI()
  end,timeout=0,whileDead=1,hideOnEscape=1,
}
StaticPopupDialogs.KHQOL_DELETE_PROFILE={
  text="프로필 '%s'를 삭제하시겠습니까?\n이 프로필을 사용하는 모든 캐릭터는 기본 프로필로 변경됩니다.\n노트와 ToDo 데이터는 유지합니다.",
  button1="삭제",button2=CANCEL,OnAccept=function(_,name)
    local ok,message=KHQOL:DeleteProfile(name)
    if not ok then KHQOL:ProfileMessage(message) end
  end,timeout=0,whileDead=1,hideOnEscape=1,
}
local function profileSettings(content,y)
  local b=UI:CreateBuilder(content,y); b:Section("프로필 관리")
  UI:CreateDescription(content,"현재 캐릭터: "..(KHQOL.profileCharacter or ""),0,b.y)
  b.y=b.y-26
  local width=(T.ContentWidth-T.ColumnGap)/2
  local right=width+T.ColumnGap
  local function strip(x,y)
    local texture=content:CreateTexture(nil,"BACKGROUND")
    texture:SetPoint("TOPLEFT",x,y+5); texture:SetSize(width,36); texture:SetColorTexture(1,1,1,.035)
  end
  strip(0,b.y); strip(right,b.y)
  local label=UI:CreateLabel(content,"활성 프로필",8,b.y-6); label:SetWidth(92)
  local active=UI:CreateDropdown(content,104,b.y,width-112,function() return KHQOL:GetProfileOptions() end,
    function() return KHQOL:GetCurrentProfileName() end,function(name)
      local ok,message=KHQOL:SelectProfile(name); if not ok then KHQOL:ProfileMessage(message) end
    end)
  label=UI:CreateLabel(content,"프로필 삭제",right+8,b.y-6); label:SetWidth(92)
  local remove=UI:CreateDropdown(content,right+104,b.y,width-112,function() return KHQOL:GetProfileOptions(true) end,
    function() return "" end,function(name)
      if name=="" then return end
      local ok,message=KHQOL:CanChangeProfile()
      if not ok then KHQOL:ProfileMessage(message); return end
      StaticPopup_Show("KHQOL_DELETE_PROFILE",name,nil,name)
    end)
  b.y=b.y-42; strip(0,b.y); strip(right,b.y)
  label=UI:CreateLabel(content,"새 프로필 이름",8,b.y-6); label:SetWidth(96)
  local input=UI:CreateEditBox(content,104,b.y,width-112,nil,nil)
  input:SetMaxLetters(24)
  local function create(duplicate)
    local ok,message=KHQOL:CreateProfile(input:GetText(),duplicate)
    if ok then input:SetText(""); input:ClearFocus() else KHQOL:ProfileMessage(message) end
  end
  local fresh=UI:CreateButton(content,"기본값으로 생성",right+8,b.y,132,function() create(false) end)
  local duplicate=UI:CreateButton(content,"현재 프로필 복사",right+148,b.y,132,function() create(true) end)
  b.y=b.y-44
  local hint=UI:CreateDescription(content,"같은 프로필을 선택한 캐릭터는 설정을 공유합니다. 생성·복사 후 새 프로필로 전환합니다.",0,b.y)
  hint:SetWidth(T.ContentWidth); b.y=b.y-math.max(18,hint:GetStringHeight())-8
  hint=UI:CreateDescription(content,"노트·ToDo·등록 버프·직업별 기준 주문은 유지합니다. 전투 중에는 프로필 변경이 제한됩니다.",0,b.y)
  hint:SetWidth(T.ContentWidth); b.y=b.y-math.max(18,hint:GetStringHeight())-8
  function KHQOL:RefreshProfileControls() active:Refresh(); remove:Refresh() end
  content.profileControls={active=active,remove=remove,input=input,fresh=fresh,duplicate=duplicate}
  return b.y
end
local function generalSettings(content,y)
  local b=UI:CreateBuilder(content,y)
  b:Section("화면 요소 위치")
  b:Button("통합 위치 편집",function() KHQOL.PositionEditor:Enter() end)
  b:Description("활성화된 화면 요소를 함께 이동합니다. 완료하면 저장·잠금, 취소 또는 ESC는 변경 전 상태를 유지합니다.")
  b:Section("모듈 관리")
  UI:CreateDescription(content,"설정은 변경 즉시 저장됩니다.",112,b.y+40)
  local rows=math.ceil(#modules/2)
  local top=b.y
  for index, definition in ipairs(modules) do
    local key, name = definition[1], definition[2]
    local column=math.floor((index-1)/rows); local row=(index-1)%rows
    local checkbox=UI:CreateCheckbox(content,name,column*((T.ContentWidth+T.ColumnGap)/2),top-row*moduleRowStep,function() return KHQOL:GetEnabled(key) end,function(on) KHQOL:SetEnabled(key,on) end)
    checkbox.text:SetWidth(150)
  end
  b.y=top-rows*moduleRowStep
  b.y=KHQOL.modules.general:BuildSettings(content,b.y)
  b:Section("미니맵")
  b:Checkbox("KHQOL 미니맵 버튼 표시",function() return KHQOL.db.minimap.show end,function(on) KHQOL.db.minimap.show=on; KHQOL:UpdateMinimapButton() end)
  b:Button("미니맵 버튼 위치 초기화",function() KHQOL.db.minimap.angle=225; KHQOL:UpdateMinimapButton() end,210)
  b:Section("기타")
  b:Checkbox("설정 잠금",function() return KHQOL.db.locked end,function(on) KHQOL.db.locked=on end)
  b:Checkbox("디버그 모드",function() return KHQOL.db.debug end,function(on) KHQOL.db.debug=on end)
  b:Section("초기화")
  b:Description("모든 모듈의 설정과 데이터를 기본값으로 복원합니다.")
  b:Button("전체 설정 초기화",function() StaticPopup_Show("KHQOL_RESET_ALL") end,180)
  return b.y
end
local function embed(content,panel,y,refresh)
  if not panel then return y end
  panel:SetParent(content); panel:ClearAllPoints(); panel:SetPoint("TOPLEFT",0,y)
  panel:SetScale(1); panel:SetWidth(T.ContentWidth); panel:SetFrameStrata("DIALOG")
  content.detailPanel=panel; content.detailY=y
  if refresh then refresh() end
  panel:Show(); UI:Refresh(panel)
  return y-panel:GetHeight()
end
function KHQOL:CreateSettings()
  local f=CreateFrame("Frame","KHQOLSettingsFrame",UIParent,"BackdropTemplate")
  f:SetSize(T.WindowWidth,T.WindowHeight); f:SetPoint("CENTER"); f:SetFrameStrata("DIALOG")
  f:SetClampedToScreen(true); f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart",f.StartMoving); f:SetScript("OnDragStop",f.StopMovingOrSizing)
  f:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12,insets={left=4,right=4,top=4,bottom=4}})
  UI:Surface(f,1)
  local texture=f:CreateTexture(nil,"BACKGROUND",nil,1); texture:SetAllPoints(); texture:SetTexture("Interface\\AddOns\\KHQOL\\Media\\SettingsGrain.tga"); texture:SetAlpha(.24)
  f:Hide(); self.settings=f
  function f:FitScreen()
    local scale=math.min(1,(UIParent:GetWidth()-24)/T.WindowWidth,(UIParent:GetHeight()-24)/T.WindowHeight)
    self:SetScale(math.max(.1,scale))
  end
  f:RegisterEvent("DISPLAY_SIZE_CHANGED"); f:RegisterEvent("UI_SCALE_CHANGED")
  f:SetScript("OnEvent",function(self) self:FitScreen() end)
  f:SetScript("OnShow",function(self) self:FitScreen() end); f:FitScreen()
  SlashCmdList.KHQOLRESOURCESWING=function()
    if f:IsShown() and f.page=="bars" and KHQOL.BarsSettings.selected=="resource" then f:Hide() else KHQOL:ShowSettings("resourceSwing") end
  end
  UI:CreateLabel(f,"KHQOL",T.WindowPadding,-17,T.TitleFontSize):SetWidth(120)
  UI:CreateDescription(f,"v"..self.VERSION,T.WindowPadding,-42):SetWidth(120)
  f.pageTitle=UI:CreateLabel(f,"일반",T.SidebarWidth+T.ContentPadding,-22,20); f.pageTitle:SetWidth(330)
  f.pageTitle:SetTextColor(unpack(T.FocusAccent))
  local edit=UI:CreateButton(f,"위치 편집",T.WindowWidth-182,-20,112,function() KHQOL.PositionEditor:Enter() end)
  local close=UI:CreateButton(f,"X",T.WindowWidth-52,-20,32,function() f:Hide() end); close:SetWidth(32)
  if UISpecialFrames then table.insert(UISpecialFrames,"KHQOLSettingsFrame") end
  local divider=f:CreateTexture(nil,"ARTWORK"); divider:SetColorTexture(unpack(T.Divider))
  divider:SetPoint("TOPLEFT",T.SidebarWidth,-54); divider:SetPoint("BOTTOMLEFT",T.SidebarWidth,18); divider:SetWidth(1)
  local scroll=CreateFrame("ScrollFrame",nil,f,"UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT",T.SidebarWidth+T.ContentPadding,-66); scroll:SetPoint("BOTTOMRIGHT",-38,58)
  local child=CreateFrame("Frame",nil,scroll); child:SetWidth(T.ContentWidth); child:SetHeight(1); scroll:SetScrollChild(child)
  f.scroll=scroll; f.child=child; f.pageCache={}; f.menuButtons={}
  -- Bars navigation is a sibling of the scroll viewport, so it remains fixed.
  local barsHeader=CreateFrame("Frame",nil,f)
  barsHeader:SetPoint("TOPLEFT",T.SidebarWidth+T.ContentPadding,-66)
  barsHeader:SetWidth(T.ContentWidth)
  local barsHeaderHeight=34+T.RowGap+T.ButtonHeight+T.SectionGap
  barsHeader:SetHeight(barsHeaderHeight); barsHeader:Hide(); f.barsHeader=barsHeader
  local alertsHeader=CreateFrame("Frame",nil,f)
  alertsHeader:SetPoint("TOPLEFT",T.SidebarWidth+T.ContentPadding,-66)
  alertsHeader:SetWidth(T.ContentWidth); alertsHeader:SetHeight(barsHeaderHeight); alertsHeader:Hide()
  f.alertsHeader=alertsHeader
  local labsHeader=CreateFrame("Frame",nil,f)
  labsHeader:SetPoint("TOPLEFT",T.SidebarWidth+T.ContentPadding,-66)
  labsHeader:SetWidth(T.ContentWidth); labsHeader:SetHeight(barsHeaderHeight); labsHeader:Hide()
  f.labsHeader=labsHeader
  function f:SetPageScrollLayout(key)
    local bars=key=="bars" or key=="alerts" or key=="labs"
    barsHeader:SetShown(key=="bars"); alertsHeader:SetShown(key=="alerts"); labsHeader:SetShown(key=="labs")
    scroll:ClearAllPoints()
    scroll:SetPoint("TOPLEFT",T.SidebarWidth+T.ContentPadding,-66-(bars and barsHeaderHeight or 0))
    scroll:SetPoint("BOTTOMRIGHT",-38,58)
  end
  function f:UpdateContentHeight()
    local page=self.activeContent; if not page then return end
    local height=page.contentHeight or 1
    if page.detailPanel then height=-page.detailY+page.detailPanel:GetHeight()+T.ContentPadding end
    height=math.max(scroll:GetHeight(),height); page:SetHeight(height); child:SetHeight(height)
    local maximum=math.max(0,height-scroll:GetHeight())
    scroll:SetVerticalScroll(math.max(0,math.min(maximum,scroll:GetVerticalScroll())))
    if scroll.ScrollBar then scroll.ScrollBar:SetShown(maximum>1) end
  end
  scroll:EnableMouseWheel(true)
  scroll:SetScript("OnMouseWheel",function(_,delta)
    UI:CloseDropdown()
    local maximum=math.max(0,child:GetHeight()-scroll:GetHeight())
    scroll:SetVerticalScroll(math.max(0,math.min(maximum,scroll:GetVerticalScroll()-delta*(T.RowHeight+T.RowGap))))
  end)
  scroll:HookScript("OnSizeChanged",function() if f.activeContent then f:UpdateContentHeight() end end)
  local footer=UI:CreateButton(f,"모듈 설정 초기화",0,0,180,function() StaticPopup_Show("KHQOL_RESET_MODULE",f.pageName,nil,f.page) end)
  footer:ClearAllPoints(); footer:SetPoint("BOTTOMRIGHT",-38,18)
  local hint=UI:CreateDescription(f,"설정은 변경 즉시 저장됩니다.",T.SidebarWidth+T.ContentPadding,0)
  hint:ClearAllPoints(); hint:SetPoint("BOTTOMLEFT",T.SidebarWidth+T.ContentPadding,24); hint:SetWidth(300)
  function f:ShowPage(key)
    -- Preserve old slash/minimap/API entry points without separate pages.
    local requestedTab=key=="castBar" and "cast" or key=="resourceSwing" and "resource"
    local requestedAlert=alertTabs[key]
    if requestedTab then key="bars"
    elseif requestedAlert then key="alerts"
    elseif key=="procAlert" then key="labs"; requestedAlert="proc" end
    local definition
    for _, item in ipairs(pages) do if item[1]==key then definition=item; break end end
    if not definition then key="general"; definition=pages[1] end
    UI:CloseDropdown()
    if self.activeContent then self.activeContent:Hide() end
    self.page=key; self.pageName=definition[2]; self.pageTitle:SetText(definition[2])
    self:SetPageScrollLayout(key)
    footer:SetShown(key~="general" and key~="profiles" and key~="bars" and key~="alerts" and key~="labs"); scroll:SetVerticalScroll(0)
    for menuKey, menuButton in pairs(self.menuButtons) do
      UI:SetButtonSelected(menuButton,menuKey==key)
    end
    local content=self.pageCache[key]
    if not content then
      content=CreateFrame("Frame",nil,child); content:SetPoint("TOPLEFT"); content:SetWidth(T.ContentWidth)
      self.pageCache[key]=content
      local y
      if key=="general" then y=UI:CreatePage(content,definition[2],definition[3]); y=generalSettings(content,y)
      elseif key=="profiles" then y=UI:CreatePage(content,definition[2],definition[3]); y=profileSettings(content,y)
      elseif key=="bars" then
        local tabY=UI:CreatePage(barsHeader,definition[2],definition[3])-T.RowGap
        y=KHQOL.BarsSettings:BuildSettings(content,0,barsHeader,tabY)
      elseif key=="alerts" then
        local tabY=UI:CreatePage(alertsHeader,definition[2],definition[3])-T.RowGap
        y=KHQOL.AlertSettings:BuildSettings(content,0,alertsHeader,tabY)
      elseif key=="labs" then
        local tabY=UI:CreatePage(labsHeader,definition[2],definition[3])-T.RowGap
        y=KHQOL.LabSettings:BuildSettings(content,0,labsHeader,tabY)
      else
        content.moduleKey=key
        y=UI:CreatePage(content,definition[2],definition[3],function() return KHQOL:GetEnabled(key) end,function(on)
          KHQOL:SetEnabled(key,on); UI:Refresh(content)
        end)
        if key=="clock" then
          KHQOL.modules.clock:CreateHeaderHelp(content)
          y=embed(content,KHQOL.modules.clock.settingsFrame,y,function() KHQOL.modules.clock:RefreshSettings() end)
        elseif key=="range" then
          local fr=KHQOL.modules.range; if not fr.Settings.panel then fr.Settings:Create() end
          y=embed(content,fr.Settings.panel,y,function() fr:UpdateSettings() end)
        elseif key=="todo" then
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
          b:Description("단축키는 게임 메뉴의 설정 > 단축키에서 지정할 수 있습니다. 노트 내용과 메모는 노트 창에서 직접 편집합니다."); y=b.y
        else y=KHQOL.modules[key]:BuildSettings(content,y) end
      end
      content.contentHeight=-y+T.ContentPadding
      if content.detailPanel then
        content.detailPanel:HookScript("OnSizeChanged",function() if f.activeContent==content then f:UpdateContentHeight() end end)
      end
    end
    self.activeContent=content; content:Show()
    if requestedTab then content.SelectBarsTab(requestedTab) end
    if requestedAlert then content.SelectAlertTab(requestedAlert) end
    if key=="clock" then KHQOL.modules.clock:RefreshSettings()
    elseif key=="range" then KHQOL.modules.range:UpdateSettings() end
    UI:Refresh(content); self:UpdateContentHeight()
  end
  local navigation=CreateFrame("ScrollFrame",nil,f)
  navigation:SetPoint("TOPLEFT",10,-76); navigation:SetPoint("BOTTOMLEFT",10,58); navigation:SetWidth(T.SidebarWidth-20)
  local menuContent=CreateFrame("Frame",nil,navigation); menuContent:SetWidth(T.SidebarWidth-20); menuContent:SetHeight(600); navigation:SetScrollChild(menuContent)
  navigation:EnableMouseWheel(true); navigation:SetScript("OnMouseWheel",function(self,delta)
    self:SetVerticalScroll(math.max(0,math.min(math.max(0,menuContent:GetHeight()-self:GetHeight()),self:GetVerticalScroll()-delta*36)))
  end)
  local menuY=0
  for i, definition in ipairs(pages) do
    local key=definition[1]
    local b=UI:CreateButton(menuContent,definition[2],0,menuY,T.SidebarWidth-28,function() f:ShowPage(key) end)
    b:SetWidth(T.SidebarWidth-28)
    b:GetFontString():SetJustifyH("LEFT"); f.menuButtons[key]=b
    menuY=menuY-(i==2 and defaultRowStep or menuRowStep)
    if i==2 then
      local line=menuContent:CreateTexture(nil,"ARTWORK"); line:SetColorTexture(unpack(T.Divider))
      line:SetPoint("TOPLEFT",0,menuY+2); line:SetSize(T.SidebarWidth-36,1); menuY=menuY-16
    end
  end
  menuContent:SetHeight(-menuY+4)
  f:SetScript("OnHide",function() UI:CloseDropdown(); GameTooltip:Hide() end)
end
function KHQOL:ShowSettings(key)
  if not self.settings then return end
  if self.PositionEditor and self.PositionEditor.active then return end
  self.settings:Show(); self.settings:ShowPage(key or "general")
end
