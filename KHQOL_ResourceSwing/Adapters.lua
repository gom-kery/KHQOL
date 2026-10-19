local K=_G.KHQOL
local R=K.ModuleRegistry
local function initialize(m) if m and m.Initialize then m:Initialize() end end
local function enable(m,on) if m and m.SetEnabled then m:SetEnabled(on) end end
R:Register("resourceSwing",{variable="KHQOLResourceSwingDB",setEnabled=function(m,on)
  if m.SetEnabled then m:SetEnabled(on)
  else
    if KHQOLResourceSwingDB then KHQOLResourceSwingDB.enabled=on and true or false end
    if KHQOLResourceSwingFrame then KHQOLResourceSwingFrame:SetShown(on) end
  end
  local cast=K.modules.castBar
  if cast and cast.frame then cast:ApplyLayout();cast:RefreshControls() end
end})
do local spec=R.entries.resourceSwing
  if not spec.positions then spec.positions=function(m,focus,K) local provider=K.PositionProviders.resourceSwing;return provider and provider(focus,K) or {} end end
  spec.applyProfile=function(m,K)
  if KHQOLResourceSwingFrame then m:ApplyProfile() end
  end
  spec.dragFrames=function(m,K) return {_G.KHQOLResourceSwingFrame,m.comboFrame} end
end
