local _, KHQOL = ...
local UI,T=KHQOL.UI,KHQOL.UI.Theme
local R=UI.SettingsRegistry

-- One presenter owns tab state, cached bodies and dynamic body heights.
local Group={}
function UI:NewSettingsGroup(id)
  return setmetatable({id=id,tabs={},selected=assert(R.orders[id])[1]}, {__index=Group})
end
function Group:RegisterTab(id,title,build)
  local meta=assert(R.groups[self.id][id],"Unknown KHQOL settings tab: "..id)
  self.tabs[#self.tabs+1]={id=id,title=meta.title,build=build,meta=meta}
end
function Group:BuildSettings(content,y,host,tabY)
  host=host or content;tabY=tabY or y
  local bodyY=host==content and y-T.ButtonHeight-T.SectionGap or y
  local buttons,panels={},{}
  content.tabPanels,content.tabButtons=panels,buttons
  -- Compatibility aliases for existing callers; internal code uses neutral names.
  if self.id=="bars" then content.barsPanels=panels;content.tabHeader=host end
  local function updateHeight(panel)
    content.contentHeight=-bodyY+panel:GetHeight()+T.ContentPadding
    if KHQOL.settings and KHQOL.settings.activeContent==content then KHQOL.settings:UpdateContentHeight() end
  end
  local function selectTab(id)
    local panel=panels[id];if not panel then return end
    UI:CloseDropdown();self.selected=id
    for _,tab in ipairs(self.tabs) do
      UI:SetButtonSelected(buttons[tab.id],tab.id==id)
      if tab.id~=id then panels[tab.id]:Hide() end
    end
    if panel.RefreshTab then panel:RefreshTab() end
    UI:Refresh(panel);panel:Show();updateHeight(panel)
    if KHQOL.settings then
      local meta=R.groups[self.id][id]
      KHQOL.settings:SetModuleHeader(meta)
      if KHQOL.settings.activeContent==content then KHQOL.settings.scroll:SetVerticalScroll(0) end
    end
  end
  content.SelectSettingsTab=selectTab
  content.SelectAlertTab=selectTab;content.SelectBarsTab=selectTab
  local x=0;local width=(T.ContentWidth-(#self.tabs-1)*T.RowGap)/#self.tabs
  for _,tab in ipairs(self.tabs) do
    local id=tab.id
    buttons[id]=UI:CreateButton(host,tab.title,x,tabY,width,function() selectTab(id) end)
    x=x+buttons[id]:GetWidth()+T.RowGap
    local panel=CreateFrame("Frame",nil,content);panel:SetPoint("TOPLEFT",0,bodyY);panel:SetWidth(T.ContentWidth);panel:Hide()
    panel.moduleKey=tab.meta.key;panel.uiControls={};panels[id]=panel
    local bottom=tab.build(panel,0);panel:SetHeight(math.max(1,-bottom))
    panel:HookScript("OnSizeChanged",function() if self.selected==id then updateHeight(panel) end end)
  end
  selectTab(self.selected)
  return -content.contentHeight+T.ContentPadding
end
function UI:EmbedModulePanel(content,panel,y,refresh)
  if not panel then return y end
  panel:SetParent(content);panel:ClearAllPoints();panel:SetPoint("TOPLEFT",0,y)
  panel:SetScale(1);panel:SetWidth(T.ContentWidth);panel:SetFrameStrata("DIALOG")
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
  content.moduleKey=key;return build(content,0)
end
function UI:RefreshSettingsViews()
  local s=KHQOL.settings;if not s then return end
  for _,content in pairs(s.pageCache) do self:Refresh(content) end
  local fc=KHQOL.modules.clock;local fbr=ForeverBuffReminder;local fr=KHQOL.modules.range
  if fc.RefreshSettings then fc:RefreshSettings() end
  if fbr.RefreshSettings then fbr:RefreshSettings() end
  if fr.UpdateSettings then fr:UpdateSettings() end
  s:ShowPage(s.page or "general")
end
function UI:RequestModuleReset(key)
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
