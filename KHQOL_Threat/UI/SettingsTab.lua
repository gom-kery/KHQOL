local KHQOL=_G.KHQOL
local UI=KHQOL.UI
KHQOL.AlertSettings:RegisterTab("threat",nil,function(content,y) return KHQOL.modules.threat:BuildSettings(content,y) end)
