local KHQOL=_G.KHQOL
local UI=KHQOL.UI
local Interface,Units,Quest=KHQOL.InterfaceSettings,KHQOL.UnitFrameSettings,KHQOL.QuestSettings
Interface:RegisterTab("cursor",nil,function(content,y) return KHQOL.modules.cursorTrail:BuildSettings(content,y) end)
