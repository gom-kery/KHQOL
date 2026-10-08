local _, KHQOL = ...
local A={tabs={},selected="npc"}
KHQOL.AlertSettings=A
function A:RegisterTab(id,title,build) self.tabs[#self.tabs+1]={id=id,title=title,build=build} end
-- Shared presentation only; gameplay and profile ownership stay with each module.
function A:BuildSettings(content,y,host,tabY)
  local UI,T=KHQOL.UI,KHQOL.UI.Theme
  local buttons,panels={},{}
  content.tabPanels,content.tabButtons=panels,buttons
  local function updateHeight(panel)
    content.contentHeight=-y+panel:GetHeight()+T.ContentPadding
    if KHQOL.settings and KHQOL.settings.activeContent==content then KHQOL.settings:UpdateContentHeight() end
  end
  local function selectTab(id)
    if not panels[id] then return end
    UI:CloseDropdown(); self.selected=id
    for _,tab in ipairs(self.tabs) do
      UI:SetButtonSelected(buttons[tab.id],tab.id==id)
      if tab.id~=id then panels[tab.id]:Hide() end
    end
    local panel=panels[id]; panel:Show()
    if panel.RefreshTab then panel:RefreshTab() end
    UI:Refresh(panel); updateHeight(panel)
    if KHQOL.settings and KHQOL.settings.activeContent==content then KHQOL.settings.scroll:SetVerticalScroll(0) end
  end
  content.SelectAlertTab=selectTab
  local x=0
  local width=(T.ContentWidth-(#self.tabs-1)*T.RowGap)/#self.tabs
  for _,tab in ipairs(self.tabs) do
    local id=tab.id
    buttons[id]=UI:CreateButton(host,tab.title,x,tabY,width,function() selectTab(id) end)
    x=x+buttons[id]:GetWidth()+T.RowGap
    local panel=CreateFrame("Frame",nil,content); panel:SetPoint("TOPLEFT",0,y); panel:SetWidth(T.ContentWidth); panel:Hide()
    panels[id]=panel
    local bottom=tab.build(panel,0); panel:SetHeight(math.max(1,-bottom))
    panel:HookScript("OnSizeChanged",function() if self.selected==id then updateHeight(panel) end end)
  end
  content:SetScript("OnShow",function() selectTab(self.selected) end)
  selectTab(self.selected)
  return -content.contentHeight+T.ContentPadding
end
