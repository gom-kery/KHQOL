local K=_G.KHQOL
local R=K.ModuleRegistry
local function initialize(m) if m and m.Initialize then m:Initialize() end end
local function enable(m,on) if m and m.SetEnabled then m:SetEnabled(on) end end
R:Register("general",{always=true,initialize=initialize})
R:Register("generalConvenience",{profile=true,setEnabled=enable,defaults=function(m) return m and m.defaults or {} end,always=true,requires={"general"}})
R:Register("chatEnhancement",{always=true,initialize=initialize})
R:Register("chatAutomation",{always=true,requires={"general"},initialize=initialize,applyProfile=function(m) m:ApplySettings() end})
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
  m.pendingInvite=nil
  m:ApplySettings()
  end
end

local commonKeys={"autoSellJunk","autoConfirmDestroy","autoRepair","useGuildFunds","declinePartyInvites","declineGuildInvites"}
local chatKeys={"chatEnhancement","chatAltInvite","chatPrefixes","chatAutoGreeting","chatRaidGreeting"}
local function resetGeneral(keys)
  return function(_,profile,defaults)
    for _,key in ipairs(keys) do profile.settings.general[key]=defaults.settings.general[key] end
  end
end
R.entries.generalConvenience.resetProfile=function(_,profile,defaults)
  profile.settings.modules.generalConvenience=K.CopyProfileValue(defaults.settings.modules.generalConvenience)
  resetGeneral(commonKeys)(nil,profile,defaults)
end
R.entries.generalConvenience.resetScope=function() return "현재 프로필의 아이템·자동 거절·채집 설정을 복원합니다." end
R:Register("convenienceChat",{
  always=true,requires={"generalConvenience"},resetProfile=resetGeneral(chatKeys),
  resetScope=function() return "현재 프로필의 대화창·말머리·자동 인사 사용 설정을 복원합니다. 캐릭터별 문구는 유지합니다." end,
  settings={group="convenience",id="chat",title="말머리·자동 인사",description="대화창 편의와 캐릭터별 말머리·인사를 설정합니다.",
    family="일반 편의",hideToggle=true,navigationOnly=true,build=function(content,y)
      return K.modules.generalConvenience:BuildSettings(content,y,true)
    end},
})
R:Register("professions",{
  profile=true,always=true,initialize=initialize,defaults=function(m) return m.defaults end,
  restore=function(_,value)
    local modules=K.db.modules
    modules.professions=K.ReplaceProfileValue(type(modules.professions)=="table" and modules.professions or {},value or {})
  end,
  applyProfile=function(m) m:ApplySettings() end,
  profileChanged=function(m) if m.professionsPanel then m.professionsPanel:Hide() end end,
  finishDrags=function(m) m:FinishDrag() end,
  positions=function(m) return m:PositionTargets() end,
  resetProfile=function(_,profile,defaults)
    local cfg=K.CopyProfileValue(defaults.settings.modules.professions)
    cfg.enabled=profile.settings.modules.professions.enabled
    profile.settings.modules.professions=cfg
  end,
  settings={group="convenience",id="professions",title="전문기술",description="전문기술 버튼과 펼친 목록을 설정합니다.",
    family="일반 편의",hideToggle=true,navigationOnly=true,positions=true,commands={"professions"},build=function(content,y)
      return K.modules.professions:BuildSettings(content,y)
    end},
})
