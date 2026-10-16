local K=_G.KHQOL
local R=K.ModuleRegistry
local function initialize(m) if m and m.Initialize then m:Initialize() end end
local function enable(m,on) if m and m.SetEnabled then m:SetEnabled(on) end end
R:Register("tooltip",{profile=true,setEnabled=enable,defaults=function(m) return m and m.defaults or {} end,initialize=initialize})
R:Register("weaponGuide",{owner="tooltip"})
do local spec=R.entries.tooltip
  if not spec.positions then spec.positions=function(m,focus,K) local provider=K.PositionProviders.tooltip;return provider and provider(focus,K) or {} end end
  spec.afterApplyProfile=function(m,K)
  m:RefreshVisibleTooltip()
  end
end
do local spec=R.entries.weaponGuide
end
