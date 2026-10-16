local K=_G.KHQOL
local R=K.ModuleRegistry
local function initialize(m) if m and m.Initialize then m:Initialize() end end
local function enable(m,on) if m and m.SetEnabled then m:SetEnabled(on) end end
R:Register("cursorTrail",{profile=true,setEnabled=enable,defaults=function(m) return m and m.defaults or {} end,initialize=initialize})
do local spec=R.entries.cursorTrail
  if not spec.positions then spec.positions=function(m,focus,K) local provider=K.PositionProviders.cursorTrail;return provider and provider(focus,K) or {} end end
  spec.applyProfile=function(m,K)
  if m.tracker then m.color=nil;m:ApplyAppearance() end
  end
end
