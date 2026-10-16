local _,K=...
local M=K.modules.partyFrames
local UI=K.UI
local function integer(v) return string.format("%d",v) end
local function message(ok,why)
  M.inputReason=not ok and why or nil;M:RefreshStatus()
end
local function refreshProfiles()
  if M.profileContent then UI:Refresh(M.profileContent) end
  if M.settingsContent then UI:Refresh(M.settingsContent) end
  if M.commonContent then UI:Refresh(M.commonContent) end
end
K.PartyFrameSettings=UI:NewSettingsGroup("partyFrames")
StaticPopupDialogs.KHQOL_DELETE_PARTY_PROFILE={text="파티·공격대 프로필 '%s'를 삭제하시겠습니까?",button1="삭제",button2=CANCEL,
  OnAccept=function(_,data)
    if not data or data.generation~=K.profileGeneration or data.store~=M:GetCharacterDB().frameProfiles then return end
    message(M:DeleteFrameProfile(data.name));refreshProfiles()
  end,timeout=0,whileDead=1,hideOnEscape=1}
function M:BuildRoleSettings(content,y)
  local b=UI:CreateBuilder(content,y)
  content.settingsRoute={module="partyFrames",tab="roles",scope="캐릭터별 프레임 프로필"}
  self.profileNotice=b:Description("",true)
  b:Section("클릭 시전")
  b:Button("마법책에서 휠 주문 등록",function() K.modules.range:OpenSpellBookPanel("wheel") end)
  b:Button("게임 클릭 시전 설정",function() message(M:OpenClickSettings()) end,nil,function() return K.PublicCall(InCombatLockdown)~=true end)
  content.settingsRoute={module="partyFrames",tab="roles",scope="캐릭터별"}
  b:Checkbox("프레임 안 휠 시전 사용",function() return M:GetCharacterDB().wheelEnabled end,function(v) M:GetCharacterDB().wheelEnabled=v;M:RequestApply() end)
  for _,direction in ipairs({"up","down"}) do
    local which=direction
    b:Edit(direction=="up" and "휠 업 주문 이름 / ID" or "휠 다운 주문 이름 / ID",function() local id=M:GetCharacterDB()[which];return id>0 and tostring(id) or "" end,function(v) M:SetWheelSpell(which,v);content:RefreshTab() end)
    content[direction.."SpellLabel"]=b:Description(self:SpellLabel(direction),true)
  end
  b:Description("마법책의 KHQOL 설정 → 휠 클릭 시전에서 스킬을 위·아래 등록칸으로 끌어 놓으세요. 주문은 캐릭터별로 저장하며 역할 프로필을 변경해도 유지합니다. 입력란을 비우면 해당 방향 등록을 해제합니다.",true)
  b:Description("휠 시전은 이 모듈의 파티·공격대 프레임 전용입니다. 별도의 기본 플레이어 프레임에는 연결되지 않으며 게임의 마우스를 올려 시전 옵션과 별개입니다.",true)
  function content:RefreshTab()
    self.upSpellLabel:SetText(M:SpellLabel("up"));self.downSpellLabel:SetText(M:SpellLabel("down"));M:RefreshStatus()
  end
  content.settingsRoute={module="partyFrames",tab="roles",scope="캐릭터별 프레임 프로필"}
  b:Section("역할 프로필")
  b:Description("탱커·딜러·힐러별로 표시와 배치를 저장합니다. 각 프로필에는 파티와 10·20·40인 공격대 설정이 함께 들어 있습니다.",true)
  local profiles=b:Dropdown("사용할 프레임 프로필",function() return M:FrameProfileOptions() end,function() return M:ActiveFrameProfile() end,function(name)
    message(M:SelectFrameProfile(name));refreshProfiles()
  end)
  profiles.profileCommand=true
  b:Checkbox("역할에 따라 탱커·딜러·힐러 프로필 자동 선택",function() return M:GetCharacterDB().autoRoleProfile==true end,function(v)
    M:CloseLivePreview();M:GetCharacterDB().autoRoleProfile=v;M:RequestApply();refreshProfiles()
  end)
  local input=b:Edit("새 프레임 프로필 이름",nil,nil);input:SetMaxLetters(24)
  local function create(duplicate)
    local ok,why=M:CreateFrameProfile(input:GetText(),duplicate);message(ok,why)
    if ok then input:SetText("");input:ClearFocus();refreshProfiles() end
  end
  b:Flush();b:Button("현재 프레임 프로필 복사",function() create(true) end);b:Button("기본값으로 생성",function() create(false) end)
  local remove=b:Dropdown("프레임 프로필 삭제",function() return M:FrameProfileOptions(true) end,function() return "" end,function(name)
    if name=="" then return end
    local ok,why=M:CanChangeFrameProfile();if not ok then message(ok,why);return end
    StaticPopup_Show("KHQOL_DELETE_PARTY_PROFILE",name,nil,{name=name,generation=K.profileGeneration,store=M:GetCharacterDB().frameProfiles})
  end)
  remove.profileCommand=true
  b:Description("프레임 프로필은 캐릭터별로 저장하며 KHQOL 전체 프로필과 별도로 유지합니다. 자동 선택은 게임의 지정 역할을 사용하고, 역할이 없으면 직접 선택한 프로필을 사용합니다. 프로필 생성·선택·삭제는 전투 종료 후 가능합니다.",true)
  b:Description("모듈 사용 여부는 KHQOL 전체 프로필에 저장합니다. 휠 주문은 캐릭터별로 저장하며 역할 프로필을 바꾸어도 유지합니다.",true)
  self.profileContent=content;content.profileControls={active=profiles,input=input,remove=remove}
  return b.y
end
function M:BuildSettings(content,y)
  local b=UI:CreateBuilder(content,y)
  content.settingsRoute={module="partyFrames",tab="frames",scope="캐릭터별 프레임 프로필"}
  b:Section("크기·위치·배치")
  self.statusLabel=b:Description("",true)
  b:Dropdown("편집할 프레임",self.layoutOptions,function() return M.editedLayout or "party" end,function(v) M:SetEditedLayout(v) end)
  local preview=b:Button("미리보기",function() if M.livePreview then M:CloseLivePreview() else message(M:OpenLivePreview()) end end)
  preview.ignoreModuleEnabled=true;preview.navigationOnly=true;content.previewButton=preview
  b:Description("설정창을 열어 둔 채 미리보기를 보며 조절하세요. 미리보기 프레임을 끌면 위치가 바로 저장됩니다.",true)
  local function get(key) return M:GetDB()[M.editedLayout or "party"][key] end
  local function write(key,value) M:GetDB()[M.editedLayout or "party"][key]=value;M:RequestApply() end
  local function raid() return (M.editedLayout or "party")~="party" end
  b:Slider("프레임 폭",80,320,1,function() return get("width") end,function(v) write("width",v) end,integer)
  b:Slider("프레임 높이",28,100,1,function() return get("height") end,function(v) write("height",v) end,integer)
  b:Slider("인원 사이 간격",0,24,1,function() return get("gap") end,function(v) write("gap",v) end,integer)
  b:Dropdown("프레임 정렬",{{value="VERTICAL",text="세로"},{value="HORIZONTAL",text="가로"}},function() return get("orientation") end,function(v) write("orientation",v) end)
  b:Dropdown("기준점",self.anchorOptions,function() return get("point") end,function(v) M:SetLayoutAnchor(M.editedLayout or "party",v) end)
  b:Dropdown("1파티 정렬 기준",{{value="LEFT",text="왼쪽 · 1 2 3 →"},{value="RIGHT",text="오른쪽 · ← 3 2 1"}},function() return get("groupAnchor") end,function(v) write("groupAnchor",v) end)
  b:Slider("X 좌표",-3000,3000,1,function() return get("x") end,function(v) write("x",v) end,integer)
  b:Slider("Y 좌표",-3000,3000,1,function() return get("y") end,function(v) write("y",v) end,integer)
  b:Description("좌표는 선택한 화면 기준점에서의 거리입니다. X는 오른쪽, Y는 위쪽이 +입니다. 기준점을 바꾸면 X·Y를 0으로 맞춥니다. 오른쪽 위 + 오른쪽 정렬 + X 0으로 화면 오른쪽 끝에 붙일 수 있습니다.",true)
  b:Dropdown("한 줄의 하위 그룹 수",function()
    local options={};for i=1,M:MaxLayoutGroups(M.editedLayout or "party") do options[#options+1]={value=i,text=tostring(i)} end;return options
  end,function() return get("groupsPerRow") or 1 end,function(v) write("groupsPerRow",v) end,raid)
  b:Slider("파티 사이 가로 간격",0,100,1,function() return get("groupGapX") or 0 end,function(v) write("groupGapX",v) end,integer,raid)
  b:Slider("파티 사이 세로 간격",0,100,1,function() return get("groupGapY") or 0 end,function(v) write("groupGapY",v) end,integer,raid)
  b:Description("공격대 인원에 따라 6~10인 → 10인, 11~20인 → 20인, 21~40인 → 40인 설정을 자동 적용합니다. 5인 이하의 공격대도 10인 설정을 사용합니다. 빈 파티 자리는 줄여 배치하며 실제 파티 번호는 유지합니다. 전투 중 배치 변경은 전투 종료 후 적용합니다.",true)
  self.settingsContent=content
  return b.y
end
function M:BuildCommonSettings(content,y)
  local b=UI:CreateBuilder(content,y)
  content.settingsRoute={module="partyFrames",tab="common",scope="캐릭터별 프레임 프로필"}
  local function set(key,value) M:GetDB()[key]=value;M:RequestApply() end
  self.commonStatusLabel=b:Description("",true)
  b:Section("공통 표시")
  b:Description("아래 표시는 현재 역할 프로필의 파티와 10·20·40인 공격대에 공통으로 적용합니다. 프로필 탭에서 프로필을 선택하거나 복사할 수 있습니다.",true)
  b:Checkbox("솔로에서도 표시",function() return M:GetDB().showSolo end,function(v) set("showSolo",v) end)
  b:Slider("글자 크기",10,24,1,function() return M:GetDB().fontSize end,function(v) set("fontSize",v) end,integer)
  b:Section("체력·자원 바")
  b:Color("체력 바 배경 색·투명도",function() local c=M:GetDB().background;return c.r,c.g,c.b,c.a end,function(r,g,blue,a)
    set("background",{r=r,g=g,b=blue,a=a})
  end,nil,nil,true)
  b:Checkbox("체력 수치 표시",function() return M:GetDB().showHealth end,function(v) set("showHealth",v) end)
  b:Checkbox("낮은 체력일수록 빨간색으로 표시",function() return M:GetDB().healthGradient end,function(v) set("healthGradient",v) end)
  b:Description("체력은 직업 색에서 빨간색(#FF0000)으로 변하고, 사망 시 #353535로 표시합니다. 사망·자리 비움·오프라인 문구는 체력 수치를 꺼도 표시합니다.",true)
  b:Checkbox("자원 바 표시",function() return M:GetDB().showPower end,function(v) set("showPower",v) end)
  b:Slider("자원 바 높이",1,24,1,function() return M:GetDB().powerHeight end,function(v) set("powerHeight",v) end,integer)
  local function placement(title,key,sized)
    b:Section(title)
    local function read(field) return M:GetDB()[key][field] end
    local function change(field,value) M:GetDB()[key][field]=value;M:RequestApply() end
    b:Dropdown(title.." 기준점",M.anchorOptions,function() return read("point") end,function(v) change("point",v) end)
    if sized then b:Slider(title.." 크기",8,40,1,function() return read("size") end,function(v) change("size",v) end,integer) end
    b:Slider(title.." X",-300,300,1,function() return read("x") end,function(v) change("x",v) end,integer)
    b:Slider(title.." Y",-300,300,1,function() return read("y") end,function(v) change("y",v) end,integer)
  end
  placement("닉네임 위치","namePosition")
  placement("체력 텍스트 위치","healthPosition")
  b:Checkbox("대상 징표 표시",function() return M:GetDB().showMarker end,function(v) set("showMarker",v) end)
  placement("대상 징표","markerPosition",true)
  b:Checkbox("역할 마크 표시",function() return M:GetDB().showRole end,function(v) set("showRole",v) end)
  placement("역할 마크","rolePosition",true)
  b:Section("디버프 위치")
  local function aura(key,value) M:GetDB().debuffs[key]=value;M:RequestApply() end
  local function ag(key) return M:GetDB().debuffs[key] end
  b:Checkbox("파티원 디버프 표시",function() return ag("enabled") end,function(v) aura("enabled",v) end)
  b:Slider("디버프 최대 개수",1,12,1,function() return ag("count") end,function(v) aura("count",v) end,integer)
  b:Slider("디버프 크기",8,48,1,function() return ag("size") end,function(v) aura("size",v) end,integer)
  b:Slider("디버프 한 줄 개수",1,12,1,function() return ag("perRow") end,function(v) aura("perRow",v) end,integer)
  b:Slider("디버프 간격",0,20,1,function() return ag("gap") end,function(v) aura("gap",v) end,integer)
  b:Dropdown("디버프 위치",M.debuffPositions,function() return ag("position") end,function(v) aura("position",v) end)
  b:Slider("디버프 X",-300,300,1,function() return ag("x") end,function(v) aura("x",v) end,integer)
  b:Slider("디버프 Y",-300,300,1,function() return ag("y") end,function(v) aura("y",v) end,integer)
  b:Description("게임 기본 디버프 표시기를 사용합니다. 미리보기에는 배치 확인용 예시 아이콘이 나타납니다.",true)
  self.commonContent=content
  return b.y
end
K.ModuleRegistry:Register("partyFrames",{
  profile=true,defaultEnabled=false,defaults=function(m) return m.defaults end,
  initialize=function(m) m:Initialize() end,setEnabled=function(m,on) m:SetEnabled(on) end,
  profileChanged=function(m) m:CancelPreview() end,applyProfile=function(m) m:GetDB() end,
  resetProfile=function(m) m:ResetFrameProfile() end,
  resetScope=function() return "현재 파티·공격대 역할 프로필의 표시·배치를 초기화합니다. 다른 역할 프로필과 캐릭터 휠 주문은 유지합니다." end,
  positions=function(m) return m:PositionTargets() end,
  settings={group="partyFrames",id="common",title="파티·공격대",tabTitle="공통",description="1인 플레이어부터 최대 40인 공격대까지 지원합니다",
    commands={"party","raid"},positions=false,build=function(content,y) return M:BuildCommonSettings(content,y) end,
    subtabs={{id="frames",title="파티·공격대",description="파티·공격대 크기·위치·배치를 설정합니다.",build=function(content,y) return M:BuildSettings(content,y) end},
      {id="roles",title="프로필",description="클릭 시전과 탱커·딜러·힐러별 프레임 프로필을 설정합니다.",build=function(content,y) return M:BuildRoleSettings(content,y) end}},
    search={{title="파티·공격대 공통 표시",description="체력·자원·이름·징표·역할 마크·디버프 위치",aliases="health power name marker aura 공통",route={tab="common"}},
      {title="파티·공격대 프레임",description="솔로 표시, 기준점, 미리보기, 체력·징표·디버프와 10·20·40인 배치",aliases="party raid solo 파티 공격대 솔로",route={tab="frames"}},
      {title="역할 프로필",description="파티·공격대 전용 프로필과 역할 자동 선택",aliases="role profile tank healer dps 탱 딜 힐",route={tab="roles"}},
      {title="프레임 전용 휠 시전",description="마법책 드래그로 휠 업·다운 주문 등록",aliases="wheel 휠 클릭 시전 클릭 캐스팅",route={tab="roles",scope="캐릭터별"}}}},
})
