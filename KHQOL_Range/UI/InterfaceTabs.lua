local KHQOL=_G.KHQOL
local UI=KHQOL.UI
local Interface,Units,Quest=KHQOL.InterfaceSettings,KHQOL.UnitFrameSettings,KHQOL.QuestSettings
Interface:RegisterTab("range",nil,function(content,y)
  local fr=KHQOL.modules.range
  local panel=fr.Settings:Create(content)
  if panel==content then
    function content:RefreshTab() fr:UpdateSettings() end
    content:RefreshTab()
    return -content:GetHeight()
  end
  -- Compatibility for a caller that created the old standalone panel first.
  return UI:EmbedModulePanel(content,panel,y,function()
    panel:SetFrameLevel(content:GetFrameLevel()+1)
    if not panel:IsShown() then panel:Show() end
    fr:UpdateSettings()
  end)
end)
