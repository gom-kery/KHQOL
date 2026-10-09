local _, KHQOL = ...
local UI=KHQOL.UI
local Interface=UI:NewSettingsGroup("interface")
KHQOL.InterfaceSettings=Interface
Interface:RegisterTab("cursor",nil,function(content,y) return KHQOL.modules.cursorTrail:BuildSettings(content,y) end)
Interface:RegisterTab("range",nil,function(content,y)
  local fr=KHQOL.modules.range
  if not fr.Settings.panel then fr.Settings:Create() end
  return UI:EmbedModulePanel(content,fr.Settings.panel,y,function() fr:UpdateSettings() end)
end)
Interface:RegisterTab("threat",nil,function(content,y) return KHQOL.modules.threat:BuildSettings(content,y) end)
Interface:RegisterTab("tooltip",nil,function(content,y) return KHQOL.modules.tooltip:BuildSettings(content,y) end)
