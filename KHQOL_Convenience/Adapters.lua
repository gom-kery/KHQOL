local K=_G.KHQOL
local R=K.ModuleRegistry
local function initialize(m) if m and m.Initialize then m:Initialize() end end
local function enable(m,on) if m and m.SetEnabled then m:SetEnabled(on) end end
R:Register("general",{always=true,initialize=initialize})
R:Register("generalConvenience",{profile=true,setEnabled=enable,defaults=function(m) return m and m.defaults or {} end,always=true,requires={"general"}})
R:Register("chatEnhancement",{always=true,initialize=initialize})
do local spec=R.entries.general
  spec.applyProfile=function(m,K)
  if m.CloseMerchantWork then m:CloseMerchantWork() end
  if m.CancelInviteDecline then m:CancelInviteDecline("party");m:CancelInviteDecline("guild") end
  m:ApplyCenterTextScale()
  end
end
do local spec=R.entries.generalConvenience
  if not spec.positions then spec.positions=function(m,focus,K) local provider=K.PositionProviders.generalConvenience;return provider and provider(focus,K) or {} end end
end
do local spec=R.entries.chatEnhancement
  spec.applyProfile=function(m,K)
  m:ApplySettings()
  end
end
