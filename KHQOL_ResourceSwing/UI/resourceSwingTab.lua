local KHQOL=_G.KHQOL
local UI=KHQOL.UI
KHQOL.BarsSettings:RegisterTab("resource",nil,function(content,y) return KHQOL.modules.resourceSwing:BuildSettings(content,y) end)
