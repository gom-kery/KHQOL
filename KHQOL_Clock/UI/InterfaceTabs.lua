local KHQOL=_G.KHQOL
local UI=KHQOL.UI
local Interface,Units,Quest=KHQOL.InterfaceSettings,KHQOL.UnitFrameSettings,KHQOL.QuestSettings
Interface:RegisterTab("clock",nil,function(content,y)
  local fc=KHQOL.modules.clock
  fc:CreateSettings(content)
  function content:RefreshTab() fc:RefreshSettings() end
  content:RefreshTab()
  return -content:GetHeight()
end)
