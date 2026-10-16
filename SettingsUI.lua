local _, KHQOL = ...
local UI, T = KHQOL.UI, KHQOL.UI.Theme
local N=UI.SettingsNavigation
-- Compact only navigation and the general module grid; retain control sizes.
local defaultRowStep = T.RowHeight + T.RowGap
local menuRowStep = T.ButtonHeight + math.max(0, defaultRowStep - T.ButtonHeight) / 2
local moduleRowStep = T.RowHeight + T.RowGap
local registry=UI.SettingsRegistry
registry:ConnectModules()
local pages=registry.pages
local moduleGroups=registry.moduleGroups
UI.Pages=pages

StaticPopupDialogs.KHQOL_RESET_MODULE = {
  text="현재 프로필의 %s\n\n설정을 기본값으로 복원하시겠습니까?",
  button1=ACCEPT,button2=CANCEL,OnAccept=function(_,data) UI:AcceptModuleReset(data) end,
  timeout=0,whileDead=1,hideOnEscape=1,
}
StaticPopupDialogs.KHQOL_RESET_ALL = {
  text="KHQOL 전체 설정을 초기화하시겠습니까?\n모든 프로필, 캐릭터별 선택, 노트와 등록한 버프를 포함한 KHQOL 데이터가 삭제되고 UI가 다시 로드됩니다.",
  button1=ACCEPT,button2=CANCEL,OnAccept=function(_,data)
    if not UI:IsCurrentConfirmation(data) then return end
    KHQOL.LabLock:RequestFullReset(function()
    KHQOL.profileResetting=true
    KHQOLDB=nil; ForeverClockDB=nil; ForeverBuffReminderDB=nil; ForeverWeaponGuideDB=nil
    KHQOLResourceSwingDB=nil; CampfireAlertDB=nil; FRangeDB=nil; KHQOLCursorTrailCharDB=nil
    KHQOLLabDB=nil; KHQOLPartyCharDB=nil
    ReloadUI()
    end)
  end,timeout=0,whileDead=1,hideOnEscape=1,
}
StaticPopupDialogs.KHQOL_DELETE_PROFILE={
  text="프로필 '%s'를 삭제하시겠습니까?\n이 프로필을 사용하는 모든 캐릭터는 기본 프로필로 변경됩니다.\n노트와 ToDo 데이터는 유지합니다.",
  button1="삭제",button2=CANCEL,OnAccept=function(_,data)
    if not UI:IsCurrentConfirmation(data) then return end
    local ok,message=KHQOL:DeleteProfile(data.name)
    if not ok then KHQOL:ProfileMessage(message) end
  end,timeout=0,whileDead=1,hideOnEscape=1,
}
local function profileSettings(content,y)
  local b=UI:CreateBuilder(content,y); b:Section("프로필 관리")
  UI:CreateDescription(content,"현재 캐릭터: "..(KHQOL.profileCharacter or ""),0,b.y)
  b.y=b.y-26
  local active=b:Dropdown("활성 프로필",function() return KHQOL:GetProfileOptions() end,function() return KHQOL:GetCurrentProfileName() end,function(name)
    local ok,message=KHQOL:SelectProfile(name);if not ok then KHQOL:ProfileMessage(message) end
  end)
  local remove=b:Dropdown("프로필 삭제",function() return KHQOL:GetProfileOptions(true) end,function() return "" end,function(name)
    if name=="" then return end
    local ok,message=KHQOL:CanChangeProfile();if not ok then KHQOL:ProfileMessage(message);return end
    StaticPopup_Show("KHQOL_DELETE_PROFILE",name,nil,UI:Confirmation({name=name}))
  end)
  active.profileCommand=true;remove.profileCommand=true
  local input=b:Edit("새 프로필 이름",nil,nil);input:SetMaxLetters(24)
  local function create(duplicate)
    local ok,message=KHQOL:CreateProfile(input:GetText(),duplicate)
    if ok then input:SetText("");input:ClearFocus() else KHQOL:ProfileMessage(message) end
  end
  b:Flush()
  local fresh=b:Button("기본값으로 생성",function() create(false) end)
  local duplicate=b:Button("현재 프로필 복사",function() create(true) end)
  b:Description("같은 프로필을 선택한 캐릭터는 설정을 공유합니다. 생성·복사 후 새 프로필로 전환합니다.",true)
  b:Description("노트·ToDo·등록 버프·직업별 기준 주문은 유지합니다. 전투 중에는 프로필 변경이 제한됩니다.",true)
  b:Description("공용 데이터: 노트·체크리스트·NPC/발동/버프 등록 목록. 기본창 위치와 설정창 크기·위치·편집기 표시 선호는 계정 공용이며 프로필에 포함되지 않습니다. 기존 배율·불투명도 저장 정책은 유지합니다.",true)
  b:Section("프로필 백업 및 복원")
  local export=b:Button("프로필 내보내기",function() KHQOL.ProfileTransfer:OpenWindow("export") end)
  local import=b:Button("프로필 가져오기",function() KHQOL.ProfileTransfer:OpenWindow("import") end)
  export.navigationOnly=true;import.navigationOnly=true
  b:Description("설정만 문자열로 백업합니다. 검사 후 새 프로필로 추가하며 기존 프로필과 현재 선택은 유지합니다.",true)
  b:Description(KHQOL.ProfileTransfer.scopeNotice,true)
  function KHQOL:RefreshProfileControls() active:Refresh(); remove:Refresh() end
  content.profileControls={active=active,remove=remove,input=input,fresh=fresh,duplicate=duplicate,export=export,import=import}
  return b.y
end
local function generalSettings(content,y)
  local b=UI:CreateBuilder(content,y)
  b:Section("모듈 관리")
  b:Description("변경 즉시 적용 · 파일 저장은 /reload · 로그아웃 시",true)
  local gap=T.ColumnGap
  content.moduleControls={}
  for _,group in ipairs(moduleGroups) do
    b:Section(group.title)
    for _,item in ipairs(group.items) do
      local key,name,isGeneral=item[1],item[2],item[3]
      local checkbox=b:Checkbox(name,
        function() return isGeneral and KHQOL.modules.general:GetDB()[key] or (not isGeneral and KHQOL:GetEnabled(key)) end,
        function(on) if isGeneral then KHQOL.modules.general:SetConvenienceEnabled(key,on) else KHQOL:SetEnabled(key,on) end end)
      checkbox.text:SetWordWrap(false)
      local meta=registry.modules[key] or (isGeneral and registry.groups.convenience.general)
      if meta then
        UI:AttachTooltip(checkbox,name,meta.description)
        checkbox.layoutLabelReserve=T.ButtonHeight+T.RowGap
        local cell=b.activeCell
        local shortcut=UI:CreateButton(content,"→",cell.x+cell.width-T.ButtonHeight,cell.top,T.ButtonHeight,function() KHQOL:OpenModule(isGeneral and "generalConvenience" or key) end)
        shortcut.navigationOnly=true
        shortcut.tooltipTitle="설정 바로가기";shortcut.tooltipDescription=""
      end
      content.moduleControls[key]=checkbox
    end
    b:Flush()
  end
  b.y=KHQOL.modules.general:BuildGlobalSettings(content,b.y)
  b:Section("미니맵")
  b:Checkbox("KHQOL 미니맵 버튼 표시",function() return KHQOL.db.minimap.show end,function(on) KHQOL.db.minimap.show=on; KHQOL:UpdateMinimapButton() end)
  b:Description("KHQOL·Note 미니맵 버튼은 위치 편집 없이 왼쪽 버튼으로 끌어 이동합니다.",true)
  b:Button("미니맵 버튼 위치 초기화",function() KHQOL.db.minimap.angle=225; KHQOL:UpdateMinimapButton() end,210)
  b:Section("기타")
  b:Checkbox("설정 잠금",function() return KHQOL.db.locked end,function(on) KHQOL.db.locked=on end)
  b:Checkbox("디버그 모드",function() return KHQOL.db.debug end,function(on) KHQOL.db.debug=on end)
  b:Section("초기화")
  b:Description("모든 모듈의 설정과 데이터를 기본값으로 복원합니다.")
  b:Button("전체 데이터 초기화",function() StaticPopup_Show("KHQOL_RESET_ALL",nil,nil,UI:Confirmation()) end,180)
  return b.y
end
function KHQOL:CreateSettings()
  if self.settings then return self.settings end
  local f=CreateFrame("Frame","KHQOLSettingsFrame",UIParent,"BackdropTemplate")
  local preferences=N:Preferences()
  f:SetSize(tonumber(preferences.width) or T.WindowWidth,tonumber(preferences.height) or T.WindowHeight); f:SetPoint("CENTER"); f:SetFrameStrata("DIALOG")
  f:SetClampedToScreen(true); f:SetMovable(true);
  f:SetResizable(true);if f.SetResizeBounds then f:SetResizeBounds(650,480,1600,1200) elseif f.SetMinResize then f:SetMinResize(650,480) end; f:EnableMouse(true); f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart",f.StartMoving); f:SetScript("OnDragStop",function(self)
    self:StopMovingOrSizing();KHQOL.PositionStore:SaveSettingsWindow(self)
  end)
  f:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12,insets={left=4,right=4,top=4,bottom=4}})
  UI:Surface(f,1)
  local texture=f:CreateTexture(nil,"BACKGROUND",nil,1); texture:SetAllPoints(); texture:SetTexture("Interface\\AddOns\\KHQOL\\Media\\SettingsGrain.tga"); texture:SetAlpha(.24)
  f.backgroundTexture=texture
  f:Hide(); self.settings=f
  function f:FitScreen()
    local db=KHQOL.db.settingsWindow or {scale=100,opacity=100}
    local requested=math.max(80,math.min(120,tonumber(db.scale) or 100))/100
    local scale=math.min(requested,(UIParent:GetWidth()-24)/self:GetWidth(),(UIParent:GetHeight()-24)/self:GetHeight())
    self:SetScale(math.max(.1,scale)); self:SetAlpha(1)
    local opacity=math.max(20,math.min(100,tonumber(db.opacity) or 100))/100
    self:SetBackdropColor(T.Background[1],T.Background[2],T.Background[3],opacity)
    texture:SetAlpha(.24*opacity)
    KHQOL.PositionStore:ApplySettingsWindow(self)
    if self.scaleControl then self.scaleControl:Refresh() end
    if self.opacityControl then self.opacityControl:Refresh() end
  end
  f:RegisterEvent("DISPLAY_SIZE_CHANGED"); f:RegisterEvent("UI_SCALE_CHANGED")
  f:SetScript("OnEvent",function(self) self:FitScreen() end)
  f:SetScript("OnShow",function(self) self:FitScreen(); self:RefreshActivePage() end); f:FitScreen()
  SlashCmdList.KHQOLRESOURCESWING=function()
    if f:IsShown() and f.page=="bars" and KHQOL.BarsSettings.selected=="resource" then f:Hide() else KHQOL:ShowSettings("resourceSwing") end
  end
  UI:CreateLabel(f,"KHQOL",T.WindowPadding,-17,T.TitleFontSize):SetWidth(120)
  UI:CreateDescription(f,"v"..self.VERSION,T.WindowPadding,-42):SetWidth(120)
  local profile=UI:CreateButton(f,"프로필",T.SidebarWidth+T.ContentPadding,-46,330,function() f:ShowPage("profiles") end)
  profile.navigationOnly=true
  profile.Refresh=function()
    profile:SetText("프로필: "..KHQOL:GetCurrentProfileName()); profile:SetWidth(T.SidebarWidth-36)
  end
  profile:GetFontString():SetJustifyH("LEFT"); profile:GetFontString():SetWidth(306)
  profile:ClearAllPoints();profile:SetPoint("BOTTOMLEFT",18,140);profile:SetWidth(T.SidebarWidth-36)
  profile:GetFontString():SetWidth(T.SidebarWidth-60)
  profile:Refresh(); f.profileShortcut=profile
  f.pageTitle=UI:CreateLabel(f,"일반",T.SidebarWidth+T.ContentPadding,-22,20); f.pageTitle:SetWidth(math.max(150,f:GetWidth()-T.SidebarWidth-200))
  f.pageTitle:SetTextColor(unpack(T.FocusAccent))
  local edit=UI:CreateButton(f,"위치 편집",T.WindowWidth-182,-20,112,function() KHQOL.PositionEditor:Enter() end)
  edit.navigationOnly=true
  local close=UI:CreateButton(f,"X",T.WindowWidth-52,-20,32,function() f:Hide() end); close:SetWidth(32)
  edit:ClearAllPoints();edit:SetPoint("TOPRIGHT",-70,-20)
  close:ClearAllPoints();close:SetPoint("TOPRIGHT",-20,-20)
  N:BuildSearch(f,T.SidebarWidth+T.ContentPadding,-55,math.max(250,f:GetWidth()-T.SidebarWidth-58))
  if UISpecialFrames then table.insert(UISpecialFrames,"KHQOLSettingsFrame") end
  local divider=f:CreateTexture(nil,"ARTWORK"); divider:SetColorTexture(unpack(T.Divider))
  divider:SetPoint("TOPLEFT",T.SidebarWidth,-54); divider:SetPoint("BOTTOMLEFT",T.SidebarWidth,18); divider:SetWidth(1)
  local scroll=CreateFrame("ScrollFrame",nil,f,"UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT",T.SidebarWidth+T.ContentPadding,-94); scroll:SetPoint("BOTTOMRIGHT",-38,58)
  local child=CreateFrame("Frame",nil,scroll); child:SetWidth(T.ContentWidth); child:SetHeight(1); scroll:SetScrollChild(child)
  f.scroll=scroll; f.child=child; f.pageCache={}; f.menuButtons={}
  local groupHeaderHeight=34+T.RowGap+T.ButtonHeight+T.SectionGap
  local moduleHeaderHeight=34+T.RowGap
  f.groupHeaders={}
  for _,definition in ipairs(pages) do
    local key=definition[1]
    if registry.groups[key] then
      local header=CreateFrame("Frame",nil,f)
      header:SetPoint("TOPLEFT",T.SidebarWidth+T.ContentPadding,-94)
      header:SetWidth(T.ContentWidth);header:SetHeight(groupHeaderHeight);header:Hide()
      f.groupHeaders[key]=header;f[key.."Header"]=header
    end
  end
  local moduleHeader=CreateFrame("Frame",nil,f);f.moduleHeader=moduleHeader
  moduleHeader:SetPoint("TOPLEFT",T.SidebarWidth+T.ContentPadding,-94-groupHeaderHeight)
  moduleHeader:SetSize(T.ContentWidth,moduleHeaderHeight);moduleHeader:Hide()
  moduleHeader.description=UI:CreateDescription(moduleHeader,"",0,-6)
  moduleHeader.description:SetWidth(T.ContentWidth-124)
  moduleHeader.toggle=UI:CreateCheckbox(moduleHeader,"모듈 사용",T.ContentWidth-108,0,
    function() return f.currentModuleKey and KHQOL:GetEnabled(f.currentModuleKey) or false end,
    function(on)
      if f.currentModuleKey then KHQOL:SetEnabled(f.currentModuleKey,on) end
    end)
  moduleHeader.toggle.ignoreModuleEnabled=true;moduleHeader.toggle.text:SetWidth(76)
  UI:CreateDivider(moduleHeader,-34)
  function f:SetModuleSubHeader(header)
    if self.moduleSubHeader and self.moduleSubHeader~=header then self.moduleSubHeader:Hide() end
    self.moduleSubHeader=header
    if header then
      if header:GetParent()~=self then header:SetParent(self) end
      header:SetWidth(child:GetWidth());header:Show();UI:Refresh(header)
    end
  end
  function f:SetPageScrollLayout(key)
    local grouped=registry.groups[key]~=nil and (key~="labs" or KHQOL.LabLock:IsUnlocked())
    for id,header in pairs(self.groupHeaders) do header:SetShown(id==key and grouped) end
    moduleHeader:SetShown(grouped)
    local headerHeight=grouped and key~="unitFrames" and self.groupHeaders[key]:GetHeight() or 0
    if key=="unitFrames" and self.groupHeaders[key] then self.groupHeaders[key]:Hide() end
    moduleHeader:ClearAllPoints(); moduleHeader:SetPoint("TOPLEFT",T.SidebarWidth+T.ContentPadding,-94-headerHeight)
    local sub=self.moduleSubHeader;local subHeight=grouped and sub and sub:GetHeight() or 0
    if sub then
      sub:SetShown(grouped)
      sub:ClearAllPoints();sub:SetPoint("TOPLEFT",T.SidebarWidth+T.ContentPadding,-94-headerHeight-moduleHeaderHeight)
    end
    scroll:ClearAllPoints()
    scroll:SetPoint("TOPLEFT",T.SidebarWidth+T.ContentPadding,-94-(grouped and headerHeight+moduleHeaderHeight+subHeight or 0))
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
  local footer=UI:CreateButton(f,"모듈 설정 초기화",0,0,180,function()
    if f.resetModuleKey then UI:RequestModuleReset(f.resetModuleKey) end
  end)
  footer:ClearAllPoints(); footer:SetPoint("BOTTOMRIGHT",-38,18)
  f.resetButton=footer
  function f:SetActiveSettingsModule(key,name)
    self.resetModuleKey=key;self.resetModuleName=name;footer:SetShown(key~=nil)
  end
  function f:SetModuleHeader(meta)
    if meta and meta.group=="labs" and not KHQOL.LabLock:IsUnlocked() then meta=nil end
    self.currentModuleKey=meta and meta.key
    self.currentRoute={module=self.currentModuleKey or meta and meta.id=="general" and "generalConvenience" or self.page or "general"}
    moduleHeader.moduleKey=self.currentModuleKey
    self:SetActiveSettingsModule(meta and meta.key,meta and meta.title)
    moduleHeader.description:SetText(meta and meta.description or "")
    moduleHeader.toggle:SetShown(self.currentModuleKey~=nil)
    if KHQOL.modules.frameInspector then
      KHQOL.modules.frameInspector:SetPageActive(meta and meta.group=="labs" and meta.id=="inspector" or false)
    end
    UI:Refresh(moduleHeader)
  end
  function f:RefreshModuleState()
    UI:Refresh(moduleHeader)
    if self.pageCache.general then UI:Refresh(self.pageCache.general) end
    self:RefreshActivePage()
  end
  function f:RefreshActivePage()
    local content=self.activeContent; if not content then return end
    if content.RefreshTab then content:RefreshTab() end
    if content.Reflow then content:Reflow() end
    UI:Refresh(content)
    UI:Refresh(moduleHeader)
    if self.groupHeaders[self.page] then UI:Refresh(self.groupHeaders[self.page]) end
    if self.moduleSubHeader then UI:Refresh(self.moduleSubHeader) end
    self:UpdateContentHeight()
  end
  local hint=UI:CreateDescription(f,"변경 즉시 적용 · 파일 저장은 /reload · 로그아웃 시",T.SidebarWidth+T.ContentPadding,0)
  hint:ClearAllPoints(); hint:SetPoint("BOTTOMLEFT",T.SidebarWidth+T.ContentPadding,24); hint:SetWidth(300)
  local relock=UI:CreateButton(f,"다시 잠그기",0,0,120,function() KHQOL.LabLock:Relock() end,
    function() return KHQOL.LabLock:IsUnlocked() end)
  relock:ClearAllPoints();relock:SetPoint("BOTTOMLEFT",T.SidebarWidth+T.ContentPadding,18);relock:Hide();f.labLockButton=relock
  local groups={unitFrames=KHQOL.UnitFrameSettings,partyFrames=KHQOL.PartyFrameSettings,bars=KHQOL.BarsSettings,alerts=KHQOL.AlertSettings,labs=KHQOL.LabSettings,
    interface=KHQOL.InterfaceSettings,convenience=KHQOL.ConvenienceSettings,quest=KHQOL.QuestSettings}
  function f:ShowPage(key)
    if self.buildingPage then return end
    local pageKey,requestedTab=registry:Resolve(key);key=pageKey
    local definition
    for _,item in ipairs(pages) do if item[1]==key then definition=item;break end end
    N:CancelSearch(self);UI:CloseDropdown()
    if self.activeContent then UI:CancelInputs(self.activeContent);self.activeContent:Hide() end
    profile:Refresh()
    self.page=key;self.pageName=definition[2];self.pageTitle:SetText(definition[2])
    local header=self.groupHeaders[key]
    if header then header:SetWidth(child:GetWidth());if header.ReflowTabs then header:ReflowTabs() end end
    self:SetModuleSubHeader(nil)
    self:SetPageScrollLayout(key);self:SetModuleHeader(nil);scroll:SetVerticalScroll(0)
    for menuKey,menuButton in pairs(self.menuButtons) do UI:SetButtonSelected(menuButton,menuKey==key) end
    local locked=key=="labs" and not KHQOL.LabLock:IsUnlocked()
    local cacheKey=locked and "labsLocked" or key
    relock:SetShown(key=="labs" and not locked);hint:SetShown(key~="labs")
    local content=self.pageCache[cacheKey]
    if not content then
      content=CreateFrame("Frame",nil,child);content.settingsRoute={module=key};content:Hide();content:SetPoint("TOPLEFT");content:SetWidth(child:GetWidth())
      content:SetHeight(math.max(1,scroll:GetHeight()))
      self.buildingPage=true
      local ok,y=pcall(function()
        if locked then return KHQOL.LabLock:BuildLockedSettings(content,0)
        elseif key=="general" then return generalSettings(content,UI:CreatePage(content,definition[2],definition[3]))
        elseif key=="profiles" then return profileSettings(content,UI:CreatePage(content,definition[2],definition[3]))
        else
          local header=self.groupHeaders[key]
          local tabY=UI:CreatePage(header,definition[2],definition[3])-T.RowGap
          return groups[key]:BuildSettings(content,0,header,tabY)
        end
      end)
      self.buildingPage=nil
      if not ok then
        -- Failed/unfinished pages must never become selectable cached pages.
        for _,button in pairs(content.tabButtons or {}) do button:Hide();button:SetParent(content) end
        content:Hide()
        error(y,0)
      end
      content.contentHeight=-y+T.ContentPadding
      self.pageCache[cacheKey]=content
    end
    self.activeContent=content
    if content:GetWidth()~=child:GetWidth() then content:SetWidth(child:GetWidth()) end
    if groups[key] and not locked then content.SelectSettingsTab(requestedTab or groups[key].selected) end
    -- Resolve geometry before showing the body, then refresh text while visible.
    -- A single next-frame pass covers the initial ScrollFrame/font layout too.
    self:UpdateContentHeight();content:Show();self:RefreshActivePage()
    self.pageDisplayGeneration=(self.pageDisplayGeneration or 0)+1
    local displayGeneration=self.pageDisplayGeneration
    local profileGeneration=KHQOL.profileGeneration
    if C_Timer and C_Timer.After then C_Timer.After(0,function()
      if self:IsShown() and self.activeContent==content and content:IsShown()
        and self.pageDisplayGeneration==displayGeneration and KHQOL.profileGeneration==profileGeneration then
        self:RefreshActivePage()
        if scroll.UpdateScrollChildRect then scroll:UpdateScrollChildRect() end
      end
    end) end
  end
  local navigation=CreateFrame("ScrollFrame",nil,f)
  navigation:SetPoint("TOPLEFT",10,-76); navigation:SetPoint("BOTTOMLEFT",10,182); navigation:SetWidth(T.SidebarWidth-20)
  local menuContent=CreateFrame("Frame",nil,navigation); menuContent:SetWidth(T.SidebarWidth-20); menuContent:SetHeight(600); navigation:SetScrollChild(menuContent)
  navigation:EnableMouseWheel(true); navigation:SetScript("OnMouseWheel",function(self,delta)
    self:SetVerticalScroll(math.max(0,math.min(math.max(0,menuContent:GetHeight()-self:GetHeight()),self:GetVerticalScroll()-delta*36)))
  end)
  local menuY=0
  for i, definition in ipairs(pages) do
    local key=definition[1]
    local b=UI:CreateButton(menuContent,definition[2],0,menuY,T.SidebarWidth-28,function() f:ShowPage(key) end)
    b.navigationOnly=true
    b:SetWidth(T.SidebarWidth-28)
    b:GetFontString():SetJustifyH("LEFT"); f.menuButtons[key]=b
    menuY=menuY-menuRowStep
    if key=="general" or key=="quest" then
      local line=menuContent:CreateTexture(nil,"ARTWORK"); line:SetColorTexture(unpack(T.Divider))
      -- Equal clear space above and below each group separator.
      local gap=T.SectionGap+T.RowGap/2
      local lineY=menuY+menuRowStep-T.ButtonHeight-gap
      line:SetPoint("TOPLEFT",0,lineY); line:SetSize(T.SidebarWidth-36,1)
      menuY=lineY-1-gap
    end
  end
  menuContent:SetHeight(-menuY+4)
  local appearance=CreateFrame("Frame",nil,f); appearance:SetPoint("BOTTOMLEFT",18,18); appearance:SetSize(T.SidebarWidth-36,116)
  local function settings() KHQOL.db.settingsWindow=KHQOL.db.settingsWindow or {scale=100,opacity=100}; return KHQOL.db.settingsWindow end
  local function slider(title,top,key,min,max)
    local c=UI:CreateSlider(appearance,title,key=="opacity" and "설정창 배경의 불투명도만 변경합니다. 글자와 조작부는 선명하게 유지합니다." or "설정창 전체의 글자와 컨트롤 크기에 함께 적용됩니다.",0,top,min,max,10,function() return settings()[key] end,function(v) settings()[key]=v; f:FitScreen() end,function(v) return v.."%" end)
    c:SetWidth(88); c.numberBox:ClearAllPoints(); c.numberBox:SetPoint("TOPLEFT",102,top-20); c.numberBox:SetWidth(62)
    return c
  end
  f.opacityControl=slider("투명도",0,"opacity",20,100)
  f.scaleControl=slider("배율",-60,"scale",80,120)
  appearance:HookScript("OnShow",function() UI:Refresh(appearance) end)
  local grip=CreateFrame("Button",nil,f);grip:SetSize(18,18);grip:SetPoint("BOTTOMRIGHT",-4,4)
  local art=grip:CreateTexture(nil,"OVERLAY");art:SetAllPoints(grip);art:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
  f.resizeGrip=grip
  function f:FinishResize()
    self:StopMovingOrSizing();self.resizing=nil
    self.resizeSerial=(self.resizeSerial or 0)+1;self.resizeQueued=nil
    preferences.width=KHQOL.PositionStore:Round(self:GetWidth());preferences.height=KHQOL.PositionStore:Round(self:GetHeight())
    self:FitScreen();self:Reflow()
  end
  grip:SetScript("OnMouseDown",function(_,button) if button=="LeftButton" then UI:CancelInputs(f);UI:CloseDropdown();N:CancelSearch(f);f.resizing=true;f:StartSizing("BOTTOMRIGHT") end end)
  grip:SetScript("OnMouseUp",function() f:FinishResize() end)
  UI:AttachTooltip(grip,"설정창 크기","오른쪽 아래 모서리를 드래그합니다. 창 크기·선택 페이지·편집기 표시 선호는 계정 공용입니다.")
  function f:Reflow()
    if self.reflowing then return end;self.reflowing=true
    local width=math.max(320,self:GetWidth()-T.SidebarWidth-T.ContentPadding-40)
    child:SetWidth(width)
    self.pageTitle:SetWidth(math.max(150,self:GetWidth()-T.SidebarWidth-210));self.pageTitle:SetFont(UI:Font(),16,"")
    self.searchBox:SetWidth(width+2)
    local header=self.groupHeaders[self.page]
    if header then header:SetWidth(width);if header.ReflowTabs then header:ReflowTabs() end end
    moduleHeader:SetWidth(width);moduleHeader.description:SetWidth(width-124)
    moduleHeader.toggle:ClearAllPoints();moduleHeader.toggle:SetPoint("TOPLEFT",width-108,0)
    if self.moduleSubHeader then self.moduleSubHeader:SetWidth(width) end
    local content=self.activeContent
    if content then
      content:SetWidth(width)
      local panel=content.activePanel
      if panel then
        panel:SetWidth(width);UI:ReflowRegisteredPanels(panel)
        if panel.Reflow then panel:Reflow() end
      else UI:ReflowRegisteredPanels(content) end
      if content.Reflow then content:Reflow() end
    end
    self:SetPageScrollLayout(self.page or "general")
    if self.resizing then
      UI:RefreshLayoutOnly(content)
      if self.moduleSubHeader then UI:RefreshLayoutOnly(self.moduleSubHeader) end
      self:UpdateContentHeight()
    else self:RefreshActivePage() end
    self.reflowing=nil
  end
  function f:RequestResizeLayout()
    if not self.resizing or not C_Timer or not C_Timer.After then self:Reflow();return end
    if self.resizeQueued then return end
    self.resizeQueued=true;local serial=self.resizeSerial or 0
    C_Timer.After(.03,function()
      if serial~=(self.resizeSerial or 0) then return end
      self.resizeQueued=nil
      if self.resizing and self:IsShown() then self:Reflow() end
    end)
  end
  f:HookScript("OnSizeChanged",function() f:RequestResizeLayout() end)
  f:SetScript("OnHide",function()
    if f.resizing then f:FinishResize() end
    UI:CancelInputs(f);UI:CloseColorPicker(); UI:CloseDropdown();N:CancelSearch(f);GameTooltip:Hide()
  end)
  f:Reflow()
end
function KHQOL:ShowSettings(key)
  if not self.settings then return end
  if self.PositionEditor and self.PositionEditor.active then return end
  if type(key)=="table" then return N:Open(key) end
  self.settings:Show(); self.settings:ShowPage(key or "general")
end
