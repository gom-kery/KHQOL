local K=_G.KHQOL
local R=K.ModuleRegistry
local function initialize(m) if m and m.Initialize then m:Initialize() end end
local function enable(m,on) if m and m.SetEnabled then m:SetEnabled(on) end end
R:Register("basicUI",{profile=true,setEnabled=enable,defaults=function(m) return m and m.defaults or {} end})
R:Register("frameMover",{always=true,initialize=initialize})
R:Register("unitFrames",{profile=true,setEnabled=enable,defaults=function(m) return m and m.defaults or {} end,requires={"basicUI"},positions=function(m,focus) return m:EditorTargets(focus) end,migrateSettings=function(m,settings,K) K:MigrateUnitFrameSettings(settings) end})
R:Register("castBar",{profile=true,setEnabled=enable,defaults=function(m) return m and m.defaults or {} end,migrateSettings=function(m,settings) m:MigrateSettings(settings) end})
do local spec=R.entries.basicUI
  if not spec.positions then spec.positions=function(m,focus,K) local provider=K.PositionProviders.basicUI;return provider and provider(focus,K) or {} end end
end
do local spec=R.entries.frameMover
  if not spec.positions then spec.positions=function(m,focus,K) local provider=K.PositionProviders.frameMover;return provider and provider(focus,K) or {} end end
end
do local spec=R.entries.unitFrames
  if not spec.positions then spec.positions=function(m,focus,K) local provider=K.PositionProviders.unitFrames;return provider and provider(focus,K) or {} end end
end
do local spec=R.entries.castBar
  if not spec.positions then spec.positions=function(m,focus,K) local provider=K.PositionProviders.castBar;return provider and provider(focus,K) or {} end end
  spec.afterApplyProfile=function(m,K)
  m:GetDB();m:ApplyLayout();m:RefreshControls()
  end
  spec.dragFrames=function(m,K) return {m.frame} end
end
