local KHQOL=_G.KHQOL
local UI=KHQOL.UI
KHQOL.BarsSettings:RegisterTab("cast",nil,function(content,y) return KHQOL.modules.castBar:BuildSettings(content,y) end)
