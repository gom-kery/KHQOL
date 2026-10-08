local _, KHQOL = ...
local UI,T=KHQOL.UI,KHQOL.UI.Theme
local A=KHQOL.AlertSettings
local Interface={tabs={},selected="cursor",RegisterTab=A.RegisterTab,BuildSettings=A.BuildSettings}
KHQOL.InterfaceSettings=Interface

-- Settings adapters only: reuse module builders, live databases and panels.
function UI:BuildModuleTab(content,key,title,description,build)
  content.moduleKey=key
  local y=self:CreatePage(content,title,description,function() return KHQOL:GetEnabled(key) end,function(on)
    KHQOL:SetEnabled(key,on); UI:Refresh(content)
  end)
  local bottom=build(content,y)
  local refresh=content.RefreshTab
  function content:RefreshTab()
    if refresh then refresh(self) end
    if KHQOL.settings then KHQOL.settings:SetActiveSettingsModule(key,title) end
  end
  return bottom
end
function UI:EmbedModulePanel(content,panel,y,refresh)
  if not panel then return y end
  panel:SetParent(content);panel:ClearAllPoints();panel:SetPoint("TOPLEFT",0,y)
  panel:SetScale(1);panel:SetWidth(T.ContentWidth);panel:SetFrameStrata("DIALOG")
  local function resize() content:SetHeight(-y+panel:GetHeight()) end
  panel:HookScript("OnSizeChanged",resize)
  function content:RefreshTab() if refresh then refresh() end;resize() end
  content:RefreshTab();panel:Show();UI:Refresh(panel)
  return -content:GetHeight()
end
local function register(id,title,key,description,build)
  Interface:RegisterTab(id,title,function(content)
    return UI:BuildModuleTab(content,key,title,description,build or function(panel,y)
      return KHQOL.modules[key]:BuildSettings(panel,y)
    end)
  end)
end
register("cursor","Cursor","cursorTrail","마우스 이동 경로에 잔상을 표시합니다.")
register("range","Range","range","선택한 대상의 사거리 상태를 표시합니다.",function(content,y)
  local fr=KHQOL.modules.range
  if not fr.Settings.panel then fr.Settings:Create() end
  return UI:EmbedModulePanel(content,fr.Settings.panel,y,function() fr:UpdateSettings() end)
end)
register("threat","Threat","threat","현재 선택한 적에 대한 내 어그로를 화면 원하는 위치에 표시합니다.")
register("tooltip","Tooltip","tooltip","툴팁의 위치, 표시 방식 및 무기 전문가 안내를 조정합니다.")
