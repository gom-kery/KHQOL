local K=_G.KHQOL
local R=K.ModuleRegistry
local function initialize(m) if m and m.Initialize then m:Initialize() end end
local function enable(m,on) if m and m.SetEnabled then m:SetEnabled(on) end end
R:Register("pvpAlert",{profile=true,setEnabled=enable,defaults=function(m) return m and m.defaults or {} end})
do local spec=R.entries.pvpAlert
  if not spec.positions then spec.positions=function(m,focus,K) local provider=K.PositionProviders.pvpAlert;return provider and provider(focus,K) or {} end end
  spec.applyProfile=function(m,K)
  if m.frame then m:SetMoving(false);m:StopTest() end
  end
  spec.closeEditors=function(m,K) if m.moving then m:SetMoving(false) end end
  spec.alertFrames=function(m,K)
  return {{frame=m.frame,priority=80,allowed=function() return not m.moving end}}
  end
end
