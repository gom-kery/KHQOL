local _, KHQOL = ...
local UI, T = KHQOL.UI, KHQOL.UI.Theme
-- Compact only navigation and the general module grid; retain control sizes.
local defaultRowStep = T.RowHeight + T.RowGap
local menuRowStep = T.ButtonHeight + math.max(0, defaultRowStep - T.ButtonHeight) / 2
local moduleRowStep = T.RowHeight + T.RowGap
local registry=UI.SettingsRegistry
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
  button1=ACCEPT,button2=CANCEL,OnAccept=function()
    KHQOL.LabLock:RequestFullReset(function()
    KHQOL.profileResetting=true
    KHQOLDB=nil; ForeverClockDB=nil; ForeverBuffReminderDB=nil; ForeverWeaponGuideDB=nil
    KHQOLResourceSwingDB=nil; CampfireAlertDB=nil; FRangeDB=nil; KHQOLCursorTrailCharDB=nil
    KHQOLLabDB=nil
    ReloadUI()
    end)
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
  b:Description("설정은 변경 즉시 저장됩니다.")
  local gap=T.ColumnGap/2
  local width=(T.ContentWidth-2*gap)/3
  content.moduleControls={}
  for _,group in ipairs(moduleGroups) do
    b:Section(group.title)
    local top=b.y
    for index,item in ipairs(group.items) do
      local key,name,isGeneral=item[1],item[2],item[3]
      local column=(index-1)%3;local row=math.floor((index-1)/3)
      local checkbox=UI:CreateCheckbox(content,name,column*(width+gap),top-row*moduleRowStep,
        function() return isGeneral and KHQOL.modules.general:GetDB()[key] or (not isGeneral and KHQOL:GetEnabled(key)) end,
        function(on)
          if isGeneral then KHQOL.modules.general:SetConvenienceEnabled(key,on)
          else KHQOL:SetEnabled(key,on) end
        end)
      checkbox.text:SetWidth(width-T.CheckboxSize-T.CheckboxLabelGap)
      checkbox.text:SetWordWrap(false)
      if checkbox.text.SetNonSpaceWrap then checkbox.text:SetNonSpaceWrap(false) end
      content.moduleControls[key]=checkbox
    end
    b.y=top-math.ceil(#group.items/3)*moduleRowStep
  end
  b.y=KHQOL.modules.general:BuildGlobalSettings(content,b.y)
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
function KHQOL:CreateSettings()
  if self.settings then return self.settings end
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
  f:SetScript("OnShow",function(self) self:FitScreen(); self:RefreshActivePage() end); f:FitScreen()
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
  local groupHeaderHeight=34+T.RowGap+T.ButtonHeight+T.SectionGap
  local moduleHeaderHeight=34+T.RowGap
  f.groupHeaders={}
  for _,definition in ipairs(pages) do
    local key=definition[1]
    if registry.groups[key] then
      local header=CreateFrame("Frame",nil,f)
      header:SetPoint("TOPLEFT",T.SidebarWidth+T.ContentPadding,-66)
      header:SetWidth(T.ContentWidth);header:SetHeight(groupHeaderHeight);header:Hide()
      f.groupHeaders[key]=header;f[key.."Header"]=header
    end
  end
  local moduleHeader=CreateFrame("Frame",nil,f);f.moduleHeader=moduleHeader
  moduleHeader:SetPoint("TOPLEFT",T.SidebarWidth+T.ContentPadding,-66-groupHeaderHeight)
  moduleHeader:SetSize(T.ContentWidth,moduleHeaderHeight);moduleHeader:Hide()
  moduleHeader.description=UI:CreateDescription(moduleHeader,"",0,-6)
  moduleHeader.description:SetWidth(T.ContentWidth-124)
  moduleHeader.toggle=UI:CreateCheckbox(moduleHeader,"모듈 사용",T.ContentWidth-108,0,
    function() return f.currentModuleKey and KHQOL:GetEnabled(f.currentModuleKey) or false end,
    function(on)
      if f.currentModuleKey then KHQOL:SetEnabled(f.currentModuleKey,on);UI:Changed(f.activeContent or moduleHeader) end
    end)
  moduleHeader.toggle.ignoreModuleEnabled=true;moduleHeader.toggle.text:SetWidth(76)
  UI:CreateDivider(moduleHeader,-34)
  function f:SetPageScrollLayout(key)
    local grouped=registry.groups[key]~=nil and (key~="labs" or KHQOL.LabLock:IsUnlocked())
    for id,header in pairs(self.groupHeaders) do header:SetShown(id==key and grouped) end
    moduleHeader:SetShown(grouped)
    scroll:ClearAllPoints()
    scroll:SetPoint("TOPLEFT",T.SidebarWidth+T.ContentPadding,-66-(grouped and groupHeaderHeight+moduleHeaderHeight or 0))
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
    UI:Refresh(content)
    UI:Refresh(moduleHeader)
    if self.groupHeaders[self.page] then UI:Refresh(self.groupHeaders[self.page]) end
    self:UpdateContentHeight()
  end
  local hint=UI:CreateDescription(f,"설정은 변경 즉시 저장됩니다.",T.SidebarWidth+T.ContentPadding,0)
  hint:ClearAllPoints(); hint:SetPoint("BOTTOMLEFT",T.SidebarWidth+T.ContentPadding,24); hint:SetWidth(300)
  local relock=UI:CreateButton(f,"다시 잠그기",0,0,120,function() KHQOL.LabLock:Relock() end,
    function() return KHQOL.LabLock:IsUnlocked() end)
  relock:ClearAllPoints();relock:SetPoint("BOTTOMLEFT",T.SidebarWidth+T.ContentPadding,18);relock:Hide();f.labLockButton=relock
  local groups={bars=KHQOL.BarsSettings,alerts=KHQOL.AlertSettings,labs=KHQOL.LabSettings,
    interface=KHQOL.InterfaceSettings,convenience=KHQOL.ConvenienceSettings}
  function f:ShowPage(key)
    local pageKey,requestedTab=registry:Resolve(key);key=pageKey
    local definition
    for _,item in ipairs(pages) do if item[1]==key then definition=item;break end end
    UI:CloseDropdown()
    if self.activeContent then self.activeContent:Hide() end
    self.page=key;self.pageName=definition[2];self.pageTitle:SetText(definition[2])
    self:SetPageScrollLayout(key);self:SetModuleHeader(nil);scroll:SetVerticalScroll(0)
    for menuKey,menuButton in pairs(self.menuButtons) do UI:SetButtonSelected(menuButton,menuKey==key) end
    local locked=key=="labs" and not KHQOL.LabLock:IsUnlocked()
    local cacheKey=locked and "labsLocked" or key
    relock:SetShown(key=="labs" and not locked);hint:SetShown(key~="labs")
    local content=self.pageCache[cacheKey]
    if not content then
      content=CreateFrame("Frame",nil,child);content:Hide();content:SetPoint("TOPLEFT");content:SetWidth(T.ContentWidth)
      content:SetHeight(math.max(1,scroll:GetHeight()))
      self.pageCache[cacheKey]=content
      local y
      if locked then y=KHQOL.LabLock:BuildLockedSettings(content,0)
      elseif key=="general" then y=generalSettings(content,UI:CreatePage(content,definition[2],definition[3]))
      elseif key=="profiles" then y=profileSettings(content,UI:CreatePage(content,definition[2],definition[3]))
      else
        local header=self.groupHeaders[key]
        local tabY=UI:CreatePage(header,definition[2],definition[3])-T.RowGap
        y=groups[key]:BuildSettings(content,0,header,tabY)
      end
      content.contentHeight=-y+T.ContentPadding
    end
    self.activeContent=content
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
    menuY=menuY-menuRowStep
    if key=="general" or key=="labs" then
      local line=menuContent:CreateTexture(nil,"ARTWORK"); line:SetColorTexture(unpack(T.Divider))
      -- Equal clear space above and below each group separator.
      local gap=T.SectionGap+T.RowGap/2
      local lineY=menuY+menuRowStep-T.ButtonHeight-gap
      line:SetPoint("TOPLEFT",0,lineY); line:SetSize(T.SidebarWidth-36,1)
      menuY=lineY-1-gap
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
