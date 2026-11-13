local K=_G.KHQOL
local R=K.UI.SettingsRegistry
local group=K.ConvenienceSettings
local common=R.groups.convenience.general
common.key="generalConvenience"
common.title="공통"
common.family="일반 편의"
common.hideToggle=true
R.modules.generalConvenience=common
group:RegisterTab("general",nil,function(content,y)
  return K.modules.generalConvenience:BuildSettings(content,y,false)
end)
