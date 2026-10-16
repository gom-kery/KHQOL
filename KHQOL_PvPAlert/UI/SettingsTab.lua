local KHQOL=_G.KHQOL
local UI=KHQOL.UI
KHQOL.AlertSettings:RegisterTab("pvp",nil,function(content,y) return KHQOL.modules.pvpAlert:BuildSettings(content,y) end)
