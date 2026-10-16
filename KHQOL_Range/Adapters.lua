local K=_G.KHQOL
local R=K.ModuleRegistry
local function initialize(m) if m and m.Initialize then m:Initialize() end end
local function enable(m,on) if m and m.SetEnabled then m:SetEnabled(on) end end
R:Register("range",{variable="FRangeDB",scope="character",setEnabled=enable})
do local spec=R.entries.range
  if not spec.positions then spec.positions=function(m,focus,K) local provider=K.PositionProviders.range;return provider and provider(focus,K) or {} end end
  spec.applyProfile=function(m,K)
  if not m.db then return end
  m:InitializeDB();m.testState=nil;m.Range:ClearActionSlotCache();m.Display:ApplyLayout(true);m:RefreshDisplay(true)
  end
  spec.dragFrames=function(m,K) return {m.Display and m.Display.frame} end
end
