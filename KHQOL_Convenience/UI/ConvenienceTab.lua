local KHQOL=_G.KHQOL
local UI=KHQOL.UI
KHQOL.ConvenienceSettings:RegisterTab("general",nil,function(content,y)
  content.moduleKey=nil
  return KHQOL.modules.generalConvenience:BuildSettings(content,y)
end)
