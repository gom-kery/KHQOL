local _, KHQOL = ...
KHQOL.AlertSettings=KHQOL.UI:NewSettingsGroup("alerts")

KHQOL.AlertSettings:RegisterTab("threat",nil,function(content,y) return KHQOL.modules.threat:BuildSettings(content,y) end)
