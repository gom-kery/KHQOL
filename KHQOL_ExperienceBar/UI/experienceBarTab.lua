local KHQOL=_G.KHQOL
local UI=KHQOL.UI
KHQOL.BarsSettings:RegisterTab("experience",nil,function(content,y) return KHQOL.modules.experienceBar:BuildSettings(content,y) end)
