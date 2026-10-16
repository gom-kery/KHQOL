local KHQOL=_G.KHQOL
local UI=KHQOL.UI
local Interface,Units,Quest=KHQOL.InterfaceSettings,KHQOL.UnitFrameSettings,KHQOL.QuestSettings
Interface:RegisterTab("basic",nil,function(content,y) return KHQOL.modules.basicUI:BuildSettings(content,y) end)
Units:RegisterTab("units",nil,function(content,y) return KHQOL.modules.unitFrames:BuildSettings(content,y) end)
