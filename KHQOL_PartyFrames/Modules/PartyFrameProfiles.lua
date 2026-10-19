local _,K=...
K=assert(_G.KHQOL,"Install and enable the KHQOL core addon.")
local M=K.modules.partyFrames
local call=K.PublicCall
local roleNames={TANK="탱커",DAMAGER="딜러",HEALER="힐러"}
local legacyPresence=setmetatable({},{__mode="k"})

local function same(a,b,seen)
  if a==b then return true end
  if type(a)~=type(b) or type(a)~="table" then return false end
  seen=seen or {};if seen[a] then return seen[a]==b end;seen[a]=b
  for key,value in pairs(a) do if not same(value,b[key],seen) then return false end end
  for key in pairs(b) do if a[key]==nil then return false end end
  return true
end
local function prefix(text,limit)
  local result={}
  for letter in text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
    if #result==limit then break end;result[#result+1]=letter
  end
  return table.concat(result),#result
end
local function importName(profiles,name,value,character)
  if profiles[name]==nil or same(profiles[name],value) then return name end
  local owner=prefix(character,10)
  for index=1,9999 do
    local suffix=" ("..owner..(index>1 and " "..index or "")..")"
    local _,length=prefix(suffix,100)
    local candidate=prefix(name,math.max(1,24-length))..suffix
    if profiles[candidate]==nil or same(profiles[candidate],value) then return candidate end
  end
  error("파티·공격대의 기존 프로필을 구분할 이름이 부족합니다. 원본 설정을 보존했습니다.")
end
local function legacyStore(self)
  local char=self:GetCharacterDB()
  local existed=legacyPresence[char]
  if existed==nil then
    existed=type(char.frameProfiles)=="table" and next(char.frameProfiles)~=nil
    legacyPresence[char]=existed
  end
  if type(char.frameProfiles)~="table" then char.frameProfiles={} end
  if not char.frameProfileSchema then
    local source=self:NormalizeDB(K.CopyProfileValue(K.db.modules.partyFrames))
    for _,name in ipairs({"기본","탱커","딜러","힐러"}) do
      if type(char.frameProfiles[name])~="table" then char.frameProfiles[name]=K.CopyProfileValue(source) end
    end
    char.frameProfileSchema=1
  end
  if type(char.frameProfiles["기본"])~="table" then char.frameProfiles["기본"]=self:NormalizeDB({}) end
  if type(char.frameProfile)~="string" or type(char.frameProfiles[char.frameProfile])~="table" then char.frameProfile="기본" end
  return char,existed
end
local function importSelection(char,names,keepLegacy)
  char.sharedFrameProfile=names[char.frameProfile] or char.frameProfile
  if type(char.sharedFrameProfileRoles)~="table" then char.sharedFrameProfileRoles={} end
  for role,name in pairs(roleNames) do
    char.sharedFrameProfileRoles[role]=names[name] or (not keepLegacy and name or false)
  end
  char.sharedFrameProfileSchema=1
end
function M:FrameProfileStore()
  local char,hadProfiles=legacyStore(self)
  local character=K.profileCharacter or K:GetProfileCharacterKey()
  -- Do not attribute saved profiles to a guessed character during login.
  if not character then return char end
  if type(K.db.globalData)~="table" then K.db.globalData={} end
  local global=K.db.globalData
  if type(global.partyFrameProfiles)~="table" then global.partyFrameProfiles={} end
  local account=global.partyFrameProfiles
  if type(account.frameProfiles)~="table" then account.frameProfiles={} end
  if type(account.migratedCharacters)~="table" then account.migratedCharacters={} end
  local imported=account.migratedCharacters[character]
  if type(imported)~="table" then imported=nil end
  if not imported and char.sharedFrameProfileSchema~=1 then
    local planned={};for name,value in pairs(account.frameProfiles) do planned[name]=value end
    local names={}
    local source=self:NormalizeDB(K.CopyProfileValue(K.db.modules.partyFrames))
    local keepLegacy=hadProfiles or next(planned)==nil or not same(source,self:NormalizeDB({}))
    if keepLegacy then
      local order={};for name,value in pairs(char.frameProfiles) do
        if type(name)=="string" and type(value)=="table" then order[#order+1]=name end
      end
      table.sort(order)
      for _,name in ipairs(order) do
        local value=self:NormalizeDB(K.CopyProfileValue(char.frameProfiles[name]))
        local target=importName(planned,name,value,character)
        if planned[target]==nil then planned[target]=value end
        names[name]=target
      end
    end
    -- Commit only after all detached copies and conflict names succeeded.
    for name,value in pairs(planned) do if account.frameProfiles[name]==nil then account.frameProfiles[name]=value end end
    imported={schema=1,names=names}
    account.migratedCharacters[character]=imported
    importSelection(char,names,keepLegacy)
  elseif not imported then
    -- A deliberate account reset must not resurrect an already migrated backup.
    imported={schema=1,names={}};account.migratedCharacters[character]=imported
  elseif char.sharedFrameProfileSchema~=1 then
    local names=type(imported.names)=="table" and imported.names or {}
    importSelection(char,names,next(names)~=nil)
  end
  if type(char.sharedFrameProfileRoles)~="table" then char.sharedFrameProfileRoles={} end
  if type(account.frameProfiles["기본"])~="table" then account.frameProfiles["기본"]=self:NormalizeDB({}) end
  if type(char.sharedFrameProfile)~="string" or type(account.frameProfiles[char.sharedFrameProfile])~="table" then char.sharedFrameProfile="기본" end
  account.schema=1
  return account
end
function M:ActiveFrameProfile()
  local store=self:FrameProfileStore();local char=self:GetCharacterDB()
  if char.autoRoleProfile then
    local role=call(UnitGroupRolesAssigned,"player")
    local name=roleNames[role]
    if store~=char and char.sharedFrameProfileRoles[role]~=nil then name=char.sharedFrameProfileRoles[role] end
    if type(name)=="string" and type(store.frameProfiles[name])=="table" then return name end
  end
  return store==char and char.frameProfile or char.sharedFrameProfile
end
function M:GetDB()
  local store=self:FrameProfileStore();local name=self:ActiveFrameProfile()
  store.frameProfiles[name]=self:NormalizeDB(store.frameProfiles[name])
  return store.frameProfiles[name]
end
function M:RaidLayoutKey()
  local n=call(GetNumGroupMembers)
  if not K.IsPublicNumber(n) or n<0 or n>40 then return "raid40" end
  return n<=10 and "raid10" or n<=20 and "raid20" or "raid40"
end
function M:FrameProfileOptions(deletable)
  local options={};local store=self:FrameProfileStore()
  if deletable then options[1]={value="",text="삭제할 프로필 선택"} end
  for name,value in pairs(store.frameProfiles) do
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
  local store=self:FrameProfileStore();if type(store.frameProfiles[name])~="table" then return false,"프레임 프로필을 찾을 수 없습니다." end
  self:CloseLivePreview()
  local char=self:GetCharacterDB()
  if store==char then char.frameProfile=name else char.sharedFrameProfile=name end
  char.autoRoleProfile=false
  for role,canonical in pairs(roleNames) do
    if name==canonical and char.sharedFrameProfileRoles then char.sharedFrameProfileRoles[role]=name end
  end
  self.inputReason=nil;self:RequestApply();return true
end
function M:CreateFrameProfile(name,duplicate)
  local ok,why=self:CanChangeFrameProfile();if not ok then return false,why end
  if type(name)~="string" then return false,"프로필 이름을 입력하세요." end
  name=name:gsub("^[ \t\r\n]*",""):gsub("[ \t\r\n]*$","")
  local letters,invalid=0,false
  for i=1,#name do local byte=name:byte(i)
    if byte<128 or byte>=192 then letters=letters+1 end
    if byte<32 or byte==127 or byte==124 then invalid=true end
  end
  if name=="" or letters>24 or invalid then return false,"프로필 이름을 확인하세요. (최대 24자)" end
  local store=self:FrameProfileStore();if store.frameProfiles[name]~=nil then return false,"같은 이름의 프레임 프로필이 있습니다." end
  store.frameProfiles[name]=duplicate and K.CopyProfileValue(self:GetDB()) or self:NormalizeDB({})
  return self:SelectFrameProfile(name)
end
function M:DeleteFrameProfile(name)
  local ok,why=self:CanChangeFrameProfile();if not ok then return false,why end
  local store=self:FrameProfileStore()
  if name=="기본" or type(store.frameProfiles[name])~="table" then return false,"삭제할 프레임 프로필을 확인하세요." end
  local active=self:ActiveFrameProfile()
  self:CloseLivePreview();store.frameProfiles[name]=nil
  local char=self:GetCharacterDB()
  if store==char and char.frameProfile==name then char.frameProfile="기본" end
  if char.sharedFrameProfile==name then char.sharedFrameProfile="기본" end
  if active==name then char.autoRoleProfile=false end
  self:RequestApply();return true
end
function M:ResetFrameProfile()
  local store=self:FrameProfileStore();local name=self:ActiveFrameProfile();local old=store.frameProfiles[name]
  local fresh=self:NormalizeDB({});K.PreserveUnknownProfileValue(old,fresh,self:NormalizeDB({}))
  fresh.debuffs.excludeSpellIDs={} -- The dynamic ID map is a known setting.
  store.frameProfiles[name]=fresh;self:CloseLivePreview();self:RequestApply()
end
