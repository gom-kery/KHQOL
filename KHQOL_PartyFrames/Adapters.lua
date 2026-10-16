local K=_G.KHQOL
local R=K.ModuleRegistry
local function initialize(m) if m and m.Initialize then m:Initialize() end end
local function enable(m,on) if m and m.SetEnabled then m:SetEnabled(on) end end
do local spec=R.entries.partyFrames
  if not spec.positions then spec.positions=function(m,focus,K) local provider=K.PositionProviders.partyFrames;return provider and provider(focus,K) or {} end end
  spec.availability=function(m,K) local supported,reason=m:Capabilities();if not supported then return "unsupported",reason end end
end
