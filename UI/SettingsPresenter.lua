local _, KHQOL = ...
local UI,T=KHQOL.UI,KHQOL.UI.Theme
local R=UI.SettingsRegistry

-- One presenter owns tab state, cached bodies and dynamic body heights.
local Group={}
UI.SettingsGroups={}
function UI:NewSettingsGroup(id)
  local group=setmetatable({id=id,tabs={},selected=assert(R.orders[id])[1]}, {__index=Group})
  self.SettingsGroups[id]=group
  return group
end
function Group:RegisterTab(id,title,build)
  local meta=assert(R.groups[self.id][id],"Unknown KHQOL settings tab: "..id)
  self.selected=self.selected or id
  self.tabs[#self.tabs+1]={id=id,title=meta.tabTitle or meta.title,build=build,meta=meta}
end
function Group:BuildSettings(content,y,host,tabY)
  if self.id=="labs" and not KHQOL.LabLock:IsUnlocked() then return KHQOL.LabLock:BuildLockedSettings(content,y) end
  host=host or content;tabY=tabY or y
  table.sort(self.tabs,function(a,b)
    local order=R.orders[self.id]; local ai,bi
    for i,id in ipairs(order) do if id==a.id then ai=i end; if id==b.id then bi=i end end
    return ai<bi
  end)
  local positions,height={},0
  local measure=host:CreateFontString(nil,"OVERLAY"); measure:SetFont(UI:Font(),T.LabelFontSize,"")
  local x,top=0,tabY
  for _,tab in ipairs(self.tabs) do
    if tab.meta.category then
      if x>0 then top=top-T.ButtonHeight-T.RowGap end
      local label=UI:CreateDescription(host,tab.meta.category,0,top)
      label:SetWidth(host:GetWidth()); top=top-22; x=0
    end
    measure:SetText(tab.title); local width=math.ceil(measure:GetStringWidth())+24
    if x>0 and x+width>host:GetWidth() then x=0;top=top-T.ButtonHeight-T.RowGap end
    positions[tab.id]={x=x,y=top,width=width}; x=x+width+T.RowGap
  end
  measure:Hide(); height=tabY-top+T.ButtonHeight+T.SectionGap
  local bodyY=host==content and y-height or y
  if host~=content then host:SetHeight(-tabY+height) end
  local buttons,panels={},{}
  content.tabsBuilding=true
  content.tabPanels,content.tabButtons=panels,buttons
  -- Compatibility aliases for existing callers; internal code uses neutral names.
  if self.id=="bars" then content.barsPanels=panels;content.tabHeader=host end
  local function updateHeight(panel)
    content.contentHeight=-bodyY+panel:GetHeight()+T.ContentPadding
    if KHQOL.settings and KHQOL.settings.activeContent==content then KHQOL.settings:UpdateContentHeight() end
  end
  local function selectTab(id)
    if content.tabsBuilding then return end
    if self.id=="labs" and not KHQOL.LabLock:IsUnlocked() then
      if KHQOL.settings then KHQOL.settings:ShowPage("labs") end
      return
    end
    local panel=panels[id];if not panel then return end
    UI:CloseDropdown();self.selected=id
    for _,tab in ipairs(self.tabs) do
      UI:SetButtonSelected(buttons[tab.id],tab.id==id)
      if tab.id~=id then panels[tab.id]:Hide() end
    end
    content.activePanel=panel;panel:Show()
    if panel:GetWidth()~=content:GetWidth() then panel:SetWidth(content:GetWidth()) end
    UI:ReflowRegisteredPanels(panel)
    if panel.RefreshTab then panel:RefreshTab() end
    updateHeight(panel);UI:Refresh(panel)
    if KHQOL.settings then
      KHQOL.settings:SetModuleSubHeader(panel.fixedHeader)
      KHQOL.settings:SetPageScrollLayout(self.id)
      local meta=R.groups[self.id][id]
      KHQOL.settings:SetModuleHeader(meta)
      if meta.sharedTabs then
        local p={module=meta.key,tab=id}
        KHQOL.settings.currentRoute=p;KHQOL.settings.pageTitle:SetText(UI.SettingsNavigation:Path(p))
      end
      if self.id=="quest" then
        local p={module="questNavigator",tab=id}
        KHQOL.settings.currentRoute=p;KHQOL.settings.pageTitle:SetText(UI.SettingsNavigation:Path(p))
      end
      if meta.key=="unitFrames" then
        local p={module="unitFrames",unit=panel.selectedUnit,part=panel.selectedPart,category=panel.selectedAuraCategory}
        KHQOL.settings.currentRoute=p;KHQOL.settings.pageTitle:SetText(UI.SettingsNavigation:Path(p))
      end
      if self.id=="bars" and meta.key=="castBar" then
        local p={module="castBar",castUnit=panel.selectedCastUnit}
        KHQOL.settings.currentRoute=p;KHQOL.settings.pageTitle:SetText(UI.SettingsNavigation:Path(p))
      end
      if KHQOL.settings.activeContent==content then KHQOL.settings.scroll:SetVerticalScroll(0) end
    end
  end
  content.SelectSettingsTab=selectTab
  content.SelectAlertTab=selectTab;content.SelectBarsTab=selectTab
  for _,tab in ipairs(self.tabs) do
    local id=tab.id
    local pos=positions[id]
    buttons[id]=UI:CreateButton(host,tab.title,pos.x,pos.y,pos.width,function() selectTab(id) end)
    buttons[id].navigationOnly=true
    local panel=CreateFrame("Frame",nil,content);panel:SetPoint("TOPLEFT",0,bodyY);panel:SetWidth(content:GetWidth());panel:Hide()
    panel.settingsModuleKey=tab.meta.key;panel.settingsRoute={module=tab.meta.key or tab.meta.id=="general" and "generalConvenience" or self.id,tab=(self.id=="quest" or tab.meta.sharedTabs) and id or nil}; panel.moduleKey=tab.meta.key;panel.uiControls={};panels[id]=panel
    panel:HookScript("OnSizeChanged",function() if self.selected==id then updateHeight(panel) end end)
  end
  -- Allocate every tab before a builder can trigger a refresh or selection.
  for _,tab in ipairs(self.tabs) do
    local panel=panels[tab.id]
    local bottom=tab.build(panel,0);panel:SetHeight(math.max(1,-bottom))
  end
  local selfGroup=self
  function host:ReflowTabs()
    local left,top=0,tabY
    for _,tab in ipairs(selfGroup.tabs) do
      local button=buttons[tab.id];local width=positions[tab.id].width
      if tab.meta.category then top=top-(left>0 and T.ButtonHeight+T.RowGap or 0)-22;left=0 end
      if left>0 and left+width>host:GetWidth() then left=0;top=top-T.ButtonHeight-T.RowGap end
      button:ClearAllPoints();button:SetPoint("TOPLEFT",left,top);left=left+width+T.RowGap
    end
    host:SetHeight(-top+T.ButtonHeight+T.SectionGap)
  end
  content.tabsBuilding=nil
  selectTab(self.selected)
  return -content.contentHeight+T.ContentPadding
end
function UI:EmbedModulePanel(content,panel,y,refresh)
  if not panel then return y end
  panel:SetParent(content);panel:ClearAllPoints();panel:SetPoint("TOPLEFT",0,y)
  panel:SetScale(1);panel:SetWidth(content:GetWidth());panel:SetFrameStrata("DIALOG")
  -- Legacy panels were created under UIParent before this tab existed.
  -- Put their regions and controls above the current settings body, including
  -- descendants whose old levels did not follow the reparented panel.
  local function raiseChildren(frame)
    local level=frame:GetFrameLevel()
    for _,child in ipairs({frame:GetChildren()}) do
      if child:GetFrameLevel()<=level then child:SetFrameLevel(level+1) end
      raiseChildren(child)
    end
  end
  local function resize() content:SetHeight(-y+panel:GetHeight()) end
  panel:HookScript("OnSizeChanged",resize)
  function content:RefreshTab()
    panel:SetFrameLevel(content:GetFrameLevel()+1)
    if refresh then refresh() end
    raiseChildren(panel)
    resize();UI:Refresh(panel)
    -- Showing the outer tab alone does not unhide an independently hidden child.
    if not panel:IsShown() then panel:Show() end
  end
  content:RefreshTab()
  return -content:GetHeight()
end
-- Kept as an external settings-builder entry point; headers now belong to host.
function UI:BuildModuleTab(content,key,title,description,build)
  if KHQOL.LabLock:IsExperimental(key) and not KHQOL.LabLock:IsUnlocked() then return KHQOL.LabLock:BuildLockedSettings(content,0) end
  content.moduleKey=key;return build(content,0)
end
function UI:RefreshSettingsViews()
  if KHQOL.settings and KHQOL.settings.FitScreen then KHQOL.settings:FitScreen() end
  local s=KHQOL.settings;if not s then return end
  -- Stable storage tables let cached controls read current values on next show.
  -- Reflow/refresh only the page which is actually visible.
  if s.activeContent then self:Refresh(s.activeContent) end
  local fc=KHQOL.modules.clock;local fbr=ForeverBuffReminder;local fr=KHQOL.modules.range
  if s.page=="interface" then
    local panel=s.activeContent and s.activeContent.activePanel
    if panel and panel.moduleKey=="clock" and fc.RefreshSettings then fc:RefreshSettings() end
    if panel and panel.moduleKey=="range" and fr.UpdateSettings then fr:UpdateSettings() end
  elseif s.page=="labs" and fbr and s.activeContent and s.activeContent.activePanel
    and s.activeContent.activePanel.moduleKey=="buffReminder" and fbr.RefreshSettings then fbr:RefreshSettings() end
  if UI.SettingsNavigation then UI.SettingsNavigation:CancelSearch(s) end
  local route=s.currentRoute
  s:ShowPage(s.page or "general")
  if route and route.tab and s.activeContent and s.activeContent.tabPanels and s.activeContent.tabPanels[route.tab] then s.activeContent.SelectSettingsTab(route.tab) end
end
function UI:RequestModuleReset(key)
  if KHQOL.LabLock:IsExperimental(key) and not KHQOL.LabLock:IsUnlocked() then return end
  local meta=R.modules[key];if not meta then return end
  StaticPopup_Show("KHQOL_RESET_MODULE",meta.title.." 모듈\n"..R:ResetScope(key),nil,
    {key=key,profile=KHQOL:GetCurrentProfileName(),generation=KHQOL.profileGeneration})
end
function UI:AcceptModuleReset(data)
  local key=type(data)=="table" and data.key or data
  if type(data)=="table" and (data.profile~=KHQOL:GetCurrentProfileName() or data.generation~=KHQOL.profileGeneration) then
    KHQOL:ProfileMessage("프로필이 변경되었습니다. 초기화 대상을 다시 확인하세요.");return
  end
  local ok,message=KHQOL:ResetProfileModule(key)
  if not ok then KHQOL:ProfileMessage(message) end
end

function UI:Confirmation(data)
  data=data or {};data.profile=KHQOL:GetCurrentProfileName();data.generation=KHQOL.profileGeneration
  return data
end
function UI:IsCurrentConfirmation(data)
  if type(data)~="table" or data.profile~=KHQOL:GetCurrentProfileName() or data.generation~=KHQOL.profileGeneration then
    KHQOL:ProfileMessage("프로필이 변경되었습니다. 대상을 다시 확인하세요.");return false
  end
  return true
end
