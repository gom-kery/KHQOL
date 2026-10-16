local _,K=...
K = assert(_G.KHQOL, "Install and enable the KHQOL core addon.")
local M=K.modules.partyFrames
local call=K.PublicCall
local roleNames={TANK="탱커",DAMAGER="딜러",HEALER="힐러"}
function M:FrameProfileStore()
  local char=self:GetCharacterDB()
  if type(char.frameProfiles)~="table" then char.frameProfiles={} end
  if not char.frameProfileSchema then
    -- One-time copy: retain the old KHQOL profile for rollback and do not touch
    -- another profile, character order, or forward-compatible saved field.
    local source=self:NormalizeDB(K.CopyProfileValue(K.db.modules.partyFrames))
    for _,name in ipairs({"기본","탱커","딜러","힐러"}) do
      if type(char.frameProfiles[name])~="table" then char.frameProfiles[name]=K.CopyProfileValue(source) end
    end
    char.frameProfileSchema=1
  end
  if type(char.frameProfiles["기본"])~="table" then char.frameProfiles["기본"]=self:NormalizeDB({}) end
  if type(char.frameProfile)~="string" or type(char.frameProfiles[char.frameProfile])~="table" then char.frameProfile="기본" end
  return char
end
function M:ActiveFrameProfile()
  local char=self:FrameProfileStore()
  if char.autoRoleProfile then
    local name=roleNames[call(UnitGroupRolesAssigned,"player")]
    if name and type(char.frameProfiles[name])=="table" then return name end
  end
  return char.frameProfile
end
function M:GetDB()
  local char=self:FrameProfileStore();local name=self:ActiveFrameProfile()
  char.frameProfiles[name]=self:NormalizeDB(char.frameProfiles[name])
  return char.frameProfiles[name]
end
function M:RaidLayoutKey()
  local n=call(GetNumGroupMembers)
  if not K.IsPublicNumber(n) or n<0 or n>40 then return "raid40" end
  return n<=10 and "raid10" or n<=20 and "raid20" or "raid40"
end
function M:FrameProfileOptions(deletable)
  local options={};local char=self:FrameProfileStore()
  if deletable then options[1]={value="",text="삭제할 프로필 선택"} end
  for name,value in pairs(char.frameProfiles) do
    if type(name)=="string" and type(value)=="table" and (not deletable or name~="기본") then options[#options+1]={value=name,text=name} end
  end
  table.sort(options,function(a,b) return a.value<b.value end);return options
end
function M:CanChangeFrameProfile()
  if call(InCombatLockdown)==true then return false,"전투 종료 후 프레임 프로필을 변경하세요." end
  if K.PositionEditor and K.PositionEditor.active then return false,"위치 편집을 마친 뒤 프로필을 변경하세요." end
  return true
end
function M:SelectFrameProfile(name)
  local ok,why=self:CanChangeFrameProfile();if not ok then return false,why end
  local char=self:FrameProfileStore();if type(char.frameProfiles[name])~="table" then return false,"프레임 프로필을 찾을 수 없습니다." end
  self:CloseLivePreview();char.frameProfile=name;char.autoRoleProfile=false;self.inputReason=nil;self:RequestApply();return true
end
function M:CreateFrameProfile(name,duplicate)
  local ok,why=self:CanChangeFrameProfile();if not ok then return false,why end
  if type(name)~="string" then return false,"프로필 이름을 입력하세요." end
  name=name:gsub("^[ \t\r\n]*",""):gsub("[ \t\r\n]*$","")
  local letters,invalid=0,false
  for i=1,#name do
    local byte=name:byte(i)
    if byte<128 or byte>=192 then letters=letters+1 end
    if byte<32 or byte==127 or byte==124 then invalid=true end
  end
  if name=="" or letters>24 or invalid then return false,"프로필 이름을 확인하세요. (최대 24자)" end
  local char=self:FrameProfileStore();if char.frameProfiles[name]~=nil then return false,"같은 이름의 프레임 프로필이 있습니다." end
  char.frameProfiles[name]=duplicate and K.CopyProfileValue(self:GetDB()) or self:NormalizeDB({})
  return self:SelectFrameProfile(name)
end
function M:DeleteFrameProfile(name)
  local ok,why=self:CanChangeFrameProfile();if not ok then return false,why end
  local char=self:FrameProfileStore()
  if name=="기본" or type(char.frameProfiles[name])~="table" then return false,"삭제할 프레임 프로필을 확인하세요." end
  self:CloseLivePreview();char.frameProfiles[name]=nil
  if char.frameProfile==name then char.frameProfile="기본" end
  if roleNames[call(UnitGroupRolesAssigned,"player")]==name then char.autoRoleProfile=false end
  self:RequestApply();return true
end
function M:ResetFrameProfile()
  local char=self:FrameProfileStore();local name=self:ActiveFrameProfile();local old=char.frameProfiles[name]
  local fresh=self:NormalizeDB({});K.PreserveUnknownProfileValue(old,fresh,self:NormalizeDB({}))
  char.frameProfiles[name]=fresh;self:CloseLivePreview();self:RequestApply()
end
