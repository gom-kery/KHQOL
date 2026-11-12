local _,K=...
local R=K.ModuleRegistry
local providers=K.PositionProviders
R:Register("basicUI",{
  profile=true,setEnabled=function(m,on) m:SetEnabled(on) end,
  defaults=function(m) return m.defaults end,
})
R:Register("frameMover",{
  always=true,initialize=function(m) m:Initialize() end,positions=function(m,focus) return providers.frameMover(focus) end,
})
R:Register("castBar",{
  profile=true,setEnabled=function(m,on) m:SetEnabled(on) end,defaults=function(m) return m.defaults end,
  migrateSettings=function(m,settings) m:MigrateSettings(settings) end,
  positions=function(m,focus) return providers.castBar(focus) end,dragFrames=function(m) return {m.frame} end,
  afterApplyProfile=function(m) m:GetDB();m:ApplyLayout();m:RefreshControls() end,
})
