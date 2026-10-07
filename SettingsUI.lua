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
local pages = {{"general", "일반", "KHQOL 공통 설정 및 모듈 관리"}}
local modules = {}
for _, definition in ipairs(definitions) do
  if KHQOL.modules[definition[1]] then modules[#modules+1] = definition end
end
table.sort(modules, function(a,b) return a[2]:lower() < b[2]:lower() end)
for _, definition in ipairs(modules) do pages[#pages+1] = definition end
UI.Pages = pages

-- Reset only after confirmation. The original module initializers supply defaults.
local function resetModule(key)
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
  text="%s 모듈 설정을 기본값으로 복원하시겠습니까?\n확인하면 UI가 다시 로드됩니다.",
  button1=ACCEPT,button2=CANCEL,OnAccept=function(_,key) resetModule(key) end,
  timeout=0,whileDead=1,hideOnEscape=1,
}
StaticPopupDialogs.KHQOL_RESET_ALL = {
  text="KHQOL 전체 설정을 초기화하시겠습니까?\n노트와 등록한 버프를 포함한 모든 KHQOL 설정이 삭제되고 UI가 다시 로드됩니다.",
  button1=ACCEPT,button2=CANCEL,OnAccept=function()
    KHQOLDB=nil; ForeverClockDB=nil; ForeverBuffReminderDB=nil; ForeverWeaponGuideDB=nil
    KHQOLResourceSwingDB=nil; CampfireAlertDB=nil; FRangeDB=nil; KHQOLCursorTrailCharDB=nil
    ReloadUI()
  end,timeout=0,whileDead=1,hideOnEscape=1,
}
local function generalSettings(content,y)
  local b=UI:CreateBuilder(content,y)
  b:Section("모듈 관리")
  UI:CreateDescription(content,"설정은 변경 즉시 저장됩니다.",112,b.y+40)
  local rows=math.ceil(#modules/3)
  local top=b.y
  for index, definition in ipairs(modules) do
    local key, name = definition[1], definition[2]
    local column=math.floor((index-1)/rows); local row=(index-1)%rows
    local checkbox=UI:CreateCheckbox(content,name,column*208,top-row*moduleRowStep,function() return KHQOL:GetEnabled(key) end,function(on) KHQOL:SetEnabled(key,on) end)
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
local function campfireSettings(content,y)
  local cfa=KHQOL.modules.campfire
  local b=UI:CreateBuilder(content,y)
  b:Section("위치")
  b:Checkbox("위치 잠금",function() return cfa.db.locked end,function(on)
    cfa.db.locked=on
    if on then cfa:HideDiscovery()
    else cfa.ui.discovery:Show(); cfa.ui.complete:Hide(); cfa:ApplyLayout() end
  end)
  b:Description("위치 잠금을 해제하면 아이콘과 문구를 미리 보고 드래그로 이동할 수 있습니다.")
  b:Button("위치 초기화",function()
    cfa.db.position={point="CENTER",x=0,y=80}
    cfa.ui.root:ClearAllPoints(); cfa.ui.root:SetPoint("CENTER",UIParent,"CENTER",0,80)
  end)
  b:Section("알림 모양")
  b:Slider("아이콘 크기",100,140,5,function() return cfa.db.iconSize end,function(v) cfa.db.iconSize=v; cfa:ApplyLayout() end,function(v) return v.." px" end)
  b:Slider("글자 크기",40,70,5,function() return cfa.db.fontSize end,function(v) cfa.db.fontSize=v; cfa:ApplyLayout() end,function(v) return v.." px" end)
  b:Section("알림 문구")
  UI:CreateLabel(content,"표시할 문구",0,b.y); b.y=b.y-24
  local input=UI:CreateEditBox(content,0,b.y,360,function() return cfa.db.message or "모닥불 발견!" end,function(v) cfa.db.message=v; cfa:ApplyLayout() end)
  UI:CreateButton(content,"적용",376,b.y,86,function() cfa.db.message=input:GetText(); input:ClearFocus(); cfa:ApplyLayout() end)
  b.y=b.y-T.DropdownRowHeight+24
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
  f:SetBackdropColor(.025,.025,.03,.96); f:Hide(); self.settings=f
  SlashCmdList.KHQOLRESOURCESWING=function()
    if f:IsShown() and f.page=="resourceSwing" then f:Hide() else KHQOL:ShowSettings("resourceSwing") end
  end
  UI:CreateLabel(f,"KH-QOL 설정",T.WindowPadding,-16,T.TitleFontSize)
  local version=UI:CreateLabel(f,"v"..self.VERSION,0,-22,T.DescriptionFontSize)
  version:ClearAllPoints(); version:SetPoint("TOPRIGHT",-54,-22); version:SetWidth(84); version:SetJustifyH("RIGHT")
  local close=CreateFrame("Button",nil,f,"UIPanelCloseButton"); close:SetPoint("TOPRIGHT",-4,-4)
  if UISpecialFrames then table.insert(UISpecialFrames,"KHQOLSettingsFrame") end
  local divider=f:CreateTexture(nil,"ARTWORK"); divider:SetColorTexture(unpack(T.Divider))
  divider:SetPoint("TOPLEFT",T.SidebarWidth,-54); divider:SetPoint("BOTTOMLEFT",T.SidebarWidth,18); divider:SetWidth(1)
  local scroll=CreateFrame("ScrollFrame",nil,f,"UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT",T.SidebarWidth+T.ContentPadding,-66); scroll:SetPoint("BOTTOMRIGHT",-38,58)
  local child=CreateFrame("Frame",nil,scroll); child:SetWidth(T.ContentWidth); child:SetHeight(1); scroll:SetScrollChild(child)
  f.scroll=scroll; f.child=child; f.pageCache={}; f.menuButtons={}
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
    local definition
    for _, item in ipairs(pages) do if item[1]==key then definition=item; break end end
    if not definition then key="general"; definition=pages[1] end
    UI:CloseDropdown()
    if self.activeContent then self.activeContent:Hide() end
    self.page=key; self.pageName=definition[2]; footer:SetShown(key~="general"); scroll:SetVerticalScroll(0)
    for menuKey, menuButton in pairs(self.menuButtons) do
      menuButton:GetFontString():SetTextColor(unpack(menuKey==key and T.Accent or T.TextPrimary))
      if menuKey==key then menuButton:LockHighlight() else menuButton:UnlockHighlight() end
    end
    local content=self.pageCache[key]
    if not content then
      content=CreateFrame("Frame",nil,child); content:SetPoint("TOPLEFT"); content:SetWidth(T.ContentWidth)
      self.pageCache[key]=content
      local y
      if key=="general" then y=UI:CreatePage(content,definition[2],definition[3]); y=generalSettings(content,y)
      else
        content.moduleKey=key
        y=UI:CreatePage(content,definition[2],definition[3],function() return KHQOL:GetEnabled(key) end,function(on)
          KHQOL:SetEnabled(key,on); UI:Refresh(content)
        end)
        if key=="clock" then
          KHQOL.modules.clock:CreateHeaderHelp(content)
          y=embed(content,KHQOL.modules.clock.settingsFrame,y,function() KHQOL.modules.clock:RefreshSettings() end)
        elseif key=="buffReminder" then y=embed(content,ForeverBuffReminder.settings,y,function() ForeverBuffReminder:RefreshSettings() end)
        elseif key=="range" then
          local fr=KHQOL.modules.range; if not fr.Settings.panel then fr.Settings:Create() end
          y=embed(content,fr.Settings.panel,y,function() fr:UpdateSettings() end)
        elseif key=="resourceSwing" then y=embed(content,KHQOLResourceSwingOptions,y)
        elseif key=="campfire" then y=campfireSettings(content,y)
        elseif key=="todo" then
          local b=UI:CreateBuilder(content,y); b:Section("노트 사용")
          b:Description("시계 우클릭 또는 ForeverNote 미니맵 버튼으로 노트 창을 열고 닫을 수 있습니다.")
          b:Checkbox("ESC로 노트 닫기",function() return KHQOL.modules.clock.db.todo.closeOnEscape ~= false end,function(on)
            KHQOL.modules.clock.db.todo.closeOnEscape=on and true or false
            KHQOL.modules.clock:UpdateTodoEscapeBinding()
          end)
          b:Description("단축키는 게임 메뉴의 설정 > 단축키에서 지정할 수 있습니다. 노트 내용과 메모는 노트 창에서 직접 편집합니다."); y=b.y
        else y=KHQOL.modules[key]:BuildSettings(content,y) end
      end
      content.contentHeight=-y+T.ContentPadding
      if content.detailPanel then
        content.detailPanel:HookScript("OnSizeChanged",function() if f.activeContent==content then f:UpdateContentHeight() end end)
      end
    end
    self.activeContent=content; content:Show()
    if key=="clock" then KHQOL.modules.clock:RefreshSettings()
    elseif key=="buffReminder" then ForeverBuffReminder:RefreshSettings()
    elseif key=="range" then KHQOL.modules.range:UpdateSettings()
    elseif key=="castBar" then KHQOL.modules.castBar:ApplyLayout(); KHQOL.modules.castBar:RefreshControls() end
    UI:Refresh(content); self:UpdateContentHeight()
  end
  local menuY=-66
  for i, definition in ipairs(pages) do
    local key=definition[1]
    local b=UI:CreateButton(f,definition[2],14,menuY,T.SidebarWidth-28,function() f:ShowPage(key) end)
    b:SetWidth(T.SidebarWidth-28)
    b:GetFontString():SetJustifyH("LEFT"); f.menuButtons[key]=b
    menuY=menuY-(i==1 and defaultRowStep or menuRowStep)
    if i==1 then
      local line=f:CreateTexture(nil,"ARTWORK"); line:SetColorTexture(unpack(T.Divider))
      line:SetPoint("TOPLEFT",18,menuY+2); line:SetSize(T.SidebarWidth-36,1); menuY=menuY-16
    end
  end
  f:SetScript("OnHide",function() UI:CloseDropdown(); GameTooltip:Hide() end)
end
function KHQOL:ShowSettings(key)
  if not self.settings then return end
  self.settings:Show(); self.settings:ShowPage(key or "general")
end
