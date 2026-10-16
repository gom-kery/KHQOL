local KHQOL=_G.KHQOL
local UI=KHQOL.UI
local Interface,Units,Quest=KHQOL.InterfaceSettings,KHQOL.UnitFrameSettings,KHQOL.QuestSettings
Interface:RegisterTab("tooltip",nil,function(content,y) return KHQOL.modules.tooltip:BuildSettings(content,y) end)
