local KHQOL=_G.KHQOL
local UI=KHQOL.UI
local Interface,Units,Quest=KHQOL.InterfaceSettings,KHQOL.UnitFrameSettings,KHQOL.QuestSettings
Quest:RegisterTab("tracker",nil,function(content,y) return KHQOL.modules.questNavigator:BuildSettings(content,y,"tracker") end)
Quest:RegisterTab("navigation",nil,function(content,y) return KHQOL.modules.questNavigator:BuildSettings(content,y,"navigation") end)
