local KHQOL=_G.KHQOL
local UI=KHQOL.UI
KHQOL.AlertSettings:RegisterTab("combat",nil,function(content,y) return KHQOL.modules.combatStatus:BuildSettings(content,y) end)
