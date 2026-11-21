local K=_G.KHQOL
local R=K.ModuleRegistry
local function initialize(m) if m and m.Initialize then m:Initialize() end end
local function enable(m,on) if m and m.SetEnabled then m:SetEnabled(on) end end
K.modules.itemProtection={}
R:Register("itemProtection",{always=true,settings={group="labs",id="itemProtection",title="아이템 보호",
  description="보호 중인 아이템 목록과 보호 해제를 관리합니다.",hideToggle=true,hideReset=true,navigationOnly=true,
  build=function(content,y)
    local b=K.UI:CreateBuilder(content,y);b:Section("아이템 보호")
    local body=CreateFrame("Frame",nil,content);body:SetWidth(content:GetWidth())
    local layout=K.modules.generalConvenience:BuildBagProtectionSettings(body)
    b:Block(body,function() return layout(body:GetWidth()) end);return b.y
  end}})
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
  spec.positions=function(m)
    local targets=m:BagTrashPositionTarget()
    m.buffThanks:AddPositionTarget(targets)
    m.partyControl:AddPositionTarget(targets)
    return targets
  end
  spec.dragFrames=function(m) return {m.trashButton,m.partyControl.button} end
  spec.finishDrags=function(m) m.buffThanks:FinishDrag() end
end
do local spec=R.entries.chatEnhancement
  spec.applyProfile=function(m,K)
  m.pendingInvite=nil
  m:ApplySettings()
  end
end

local commonKeys={"autoSellJunk","autoConfirmDestroy","autoRepair","useGuildFunds","declinePartyInvites","declineGuildInvites","chatEnhancement"}
local partyKeys={"chatAltInvite","chatAutoGreeting","chatRaidGreeting"}
local function resetGeneral(keys)
  return function(_,profile,defaults)
    for _,key in ipairs(keys) do profile.settings.general[key]=defaults.settings.general[key] end
  end
end
R.entries.generalConvenience.resetProfile=function(_,profile,defaults)
  local modules=profile.settings.modules
  local party=modules.generalConvenience and modules.generalConvenience.partyButton
  modules.generalConvenience=K.CopyProfileValue(defaults.settings.modules.generalConvenience)
  if party then modules.generalConvenience.partyButton=party end
  resetGeneral(commonKeys)(nil,profile,defaults)
end
R.entries.generalConvenience.resetScope=function() return "현재 프로필의 가방·아이템, 상점·수리, 요청 자동 거절, 대화창 편의·버프 감사 알림 설정을 함께 복원합니다. 파티 버튼과 계정 공용 아이템 보호 목록은 유지합니다." end
R:Register("convenienceChat",{
  always=true,requires={"generalConvenience"},resetProfile=resetGeneral({"chatPrefixes"}),
  resetScope=function() return "현재 프로필의 말머리 사용 설정을 복원합니다. 캐릭터별 말머리 문구는 유지합니다." end,
  settings={group="convenience",id="chat",title="말머리",description="채널별 말머리를 설정합니다.",
    family="일반 편의",hideToggle=true,navigationOnly=true,build=function(content,y)
      return K.modules.generalConvenience:BuildSettings(content,y,"chat")
    end},
})
R:Register("convenienceParty",{
  always=true,requires={"generalConvenience"},resetProfile=function(_,profile,defaults)
    local modules=profile.settings.modules
    local enabled=modules.generalConvenience.partyButton.enabled
    local party=K.CopyProfileValue(defaults.settings.modules.generalConvenience.partyButton)
    party.enabled=enabled
    modules.generalConvenience.partyButton=party
    resetGeneral(partyKeys)(nil,profile,defaults)
  end,
  resetScope=function() return "현재 프로필의 파티 버튼 위치·메시지와 자동 인사 옵션을 복원합니다. 표시 설정과 캐릭터별 자동 인사 문구는 유지합니다." end,
  settings={group="convenience",id="party",title="파티",description="파티 버튼과 초대·자동 인사를 설정합니다.",
    family="일반 편의",hideToggle=true,navigationOnly=true,positions=true,build=function(content,y)
      return K.modules.generalConvenience:BuildSettings(content,y,"party")
    end},
})
R:Register("professions",{
  profile=true,always=true,initialize=initialize,defaults=function(m) return m.defaults end,
  restore=function(_,value)
    local modules=K.db.modules
    modules.professions=K.ReplaceProfileValue(type(modules.professions)=="table" and modules.professions or {},value or {})
  end,
  applyProfile=function(m) m:ApplySettings() end,
  profileChanged=function(m)
    if m.professionsPanel then m.professionsPanel:Hide() end
    if m.altProfessionWindow then m.altProfessionWindow:Hide() end
  end,
  finishDrags=function(m) m:FinishDrag() end,
  positions=function(m) return m:PositionTargets() end,
  resetProfile=function(_,profile,defaults)
    local cfg=K.CopyProfileValue(defaults.settings.modules.professions)
    cfg.enabled=profile.settings.modules.professions.enabled
    profile.settings.modules.professions=cfg
  end,
  settings={group="convenience",id="professions",title="전문기술",description="전문기술 버튼과 펼친 목록을 설정합니다.",
    family="일반 편의",navigationOnly=true,positions=true,commands={"professions"},
    toggle={label="전문기술 사용",metric="setting.professions.control009",
      get=function() return K.modules.professions:GetDB().enabled end,
      set=function(v) K.modules.professions:GetDB().enabled=v;K.modules.professions:ApplySettings() end},build=function(content,y)
      return K.modules.professions:BuildSettings(content,y)
    end},
})
