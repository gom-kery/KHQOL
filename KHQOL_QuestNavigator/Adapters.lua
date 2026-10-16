local K=_G.KHQOL
local R=K.ModuleRegistry
local function initialize(m) if m and m.Initialize then m:Initialize() end end
local function enable(m,on) if m and m.SetEnabled then m:SetEnabled(on) end end
R:Register("questNavigator",{profile=true,setEnabled=enable,defaults=function(m) return m and m.defaults or {} end})
do local spec=R.entries.questNavigator
  if not spec.positions then spec.positions=function(m,focus,K) local provider=K.PositionProviders.questNavigator;return provider and provider(focus,K) or {} end end
  spec.handleCommand=function(m,message,K) m:HandleCommand(message) end
end
