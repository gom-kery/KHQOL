local K=_G.KHQOL
local R=K.ModuleRegistry
local function initialize(m) if m and m.Initialize then m:Initialize() end end
local function enable(m,on) if m and m.SetEnabled then m:SetEnabled(on) end end
R:Register("threat",{profile=true,setEnabled=enable,defaults=function(m) return m and m.defaults or {} end})
do local spec=R.entries.threat
  if not spec.positions then spec.positions=function(m,focus,K) local provider=K.PositionProviders.threat;return provider and provider(focus,K) or {} end end
  spec.applyProfile=function(m,K)
  if m.root then m:StopTest();m:ResetAggroAlert() end
  end
  spec.alertFrames=function(m,K)
  return {{frame=m.root,priority=70,allowed=function() return m.db.locked and not m.testing end}}
  end
  spec.handleCommand=function(m,message,K) m:HandleCommand(message) end
end
