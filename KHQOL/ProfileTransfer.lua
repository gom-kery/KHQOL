local _, K = ...
-- Settings transport only. Never evaluates input or touches another saved scope.
local T = {formatVersion=1, scopeVersion=1, maxBytes=262144, maxText=350000,
  maxString=8192, maxNodes=30000, maxDepth=20}
K.ProfileTransfer=T
local floor,concat=math.floor,table.concat
local alphabet="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local digits={};for i=1,#alphabet do digits[alphabet:sub(i,i)]=i-1 end
local function fail(message) error(message,0) end
local function finite(v) return type(v)=="number" and v==v and math.abs(v)<math.huge end
local function utf8(s)
  local i,count=1,0
  while i<=#s do
    local a,b,c,d=s:byte(i,i+3);local n
    if a<128 then n=1
    elseif a>=194 and a<=223 and b and b>=128 and b<=191 then n=2
    elseif a>=224 and a<=239 and b and c and b>=128 and b<=191 and c>=128 and c<=191
      and (a~=224 or b>=160) and (a~=237 or b<=159) then n=3
    elseif a>=240 and a<=244 and b and c and d and b>=128 and b<=191 and c>=128 and c<=191
      and d>=128 and d<=191 and (a~=240 or b>=144) and (a~=244 or b<=143) then n=4 end
    if not n then return end
    count=count+1;i=i+n
  end
  return count
end
local function text(s,max)
  return type(s)=="string" and #s<=max and utf8(s) and not s:find("[%z\1-\8\11\12\14-\31\127]")
end
local function safeLabel(s) return (s:gsub("|","||"):gsub("[\r\n\t]"," ")) end
T.SafeLabel=safeLabel
-- Adler-32 detects accidental corruption, not authenticity or encryption.
local function checksum(s)
  local a,b=1,0
  for i=1,#s do a=(a+s:byte(i))%65521;b=(b+a)%65521 end
  return string.format("%08x",b*65536+a)
end
local function base64(s)
  local out={}
  for i=1,#s,3 do
    local a,b,c=s:byte(i,i+2);local n=a*65536+(b or 0)*256+(c or 0)
    out[#out+1]=alphabet:sub(floor(n/262144)+1,floor(n/262144)+1)
      ..alphabet:sub(floor(n/4096)%64+1,floor(n/4096)%64+1)
      ..(b and alphabet:sub(floor(n/64)%64+1,floor(n/64)%64+1) or "=")
      ..(c and alphabet:sub(n%64+1,n%64+1) or "=")
  end
  return concat(out)
end
local function unbase64(s)
  if #s%4~=0 or s:find("[^A-Za-z0-9+/=]") then fail("문자열 인코딩이 올바르지 않습니다.") end
  local out={}
  for i=1,#s,4 do
    local ca,cb,cc,cd=s:sub(i,i),s:sub(i+1,i+1),s:sub(i+2,i+2),s:sub(i+3,i+3)
    local a,b,c,d=digits[ca],digits[cb],digits[cc],digits[cd]
    if not a or not b or (not c and cc~="=") or (not d and cd~="=")
      or (cc=="=" and cd~="=") or ((cc=="=" or cd=="=") and i+3~=#s)
      or (cc=="=" and b%16~=0) or (cd=="=" and c and c%4~=0) then fail("문자열 인코딩이 손상되었습니다.") end
    local n=a*262144+b*4096+(c or 0)*64+(d or 0)
    out[#out+1]=string.char(floor(n/65536))
    if c then out[#out+1]=string.char(floor(n/256)%256) end
    if d then out[#out+1]=string.char(n%256) end
  end
  return concat(out)
end
-- Length-delimited, canonical typed data: booleans, finite numbers, UTF-8,
-- tables with string/integer keys. No Lua source, metatables or references.
function T:Encode(value)
  local out,seen,bytes,nodes={},{},0,0
  local function put(s) bytes=bytes+#s;if bytes>self.maxBytes then fail("프로필 데이터가 허용 크기(256 KiB)를 초과합니다.") end;out[#out+1]=s end
  local function encode(v,depth)
    nodes=nodes+1;if nodes>self.maxNodes or depth>self.maxDepth then fail("데이터 항목 또는 중첩 한도를 초과합니다.") end
    local kind=type(v)
    if kind=="boolean" then put(v and "b1" or "b0")
    elseif kind=="number" then
      if not finite(v) then fail("유효하지 않은 숫자입니다.") end
      local s=string.format("%.17g",v);put("d"..#s..":"..s)
    elseif kind=="string" then
      if not text(v,self.maxString) then fail("문자열 길이 또는 UTF-8 형식이 올바르지 않습니다.") end
      put("s"..#v..":"..v)
    elseif kind=="table" then
      if seen[v] or getmetatable(v) then fail("순환 참조 또는 객체는 내보낼 수 없습니다.") end
      seen[v]=true;local keys={}
      for k in pairs(v) do
        if not (type(k)=="string" and text(k,128) or finite(k) and k==floor(k) and math.abs(k)<=8192) then fail("허용되지 않은 테이블 키입니다.") end
        keys[#keys+1]=k;if #keys>8192 then fail("테이블 항목이 너무 많습니다.") end
      end
      table.sort(keys,function(a,b) if type(a)~=type(b) then return type(a)<type(b) end;return a<b end)
      put("t"..#keys..":")
      for _,key in ipairs(keys) do encode(key,depth+1);encode(v[key],depth+1) end
      seen[v]=nil
    else fail("설정에 허용되지 않은 데이터 타입입니다: "..kind) end
  end
  encode(value,0);return concat(out)
end
function T:Decode(raw)
  if #raw>self.maxBytes then fail("데이터 크기 한도를 초과합니다.") end
  local pos,nodes=1,0
  local function length(max)
    local stop=raw:find(":",pos,true)
    if not stop or stop-pos>7 then fail("데이터 길이 정보가 손상되었습니다.") end
    local s=raw:sub(pos,stop-1)
    if not s:match("^%d+$") then fail("유효하지 않은 길이 정보입니다.") end
    local n=tonumber(s);if not n or n>max then fail("데이터 길이 한도를 초과합니다.") end
    pos=stop+1;return n
  end
  local function decode(depth)
    nodes=nodes+1;if nodes>self.maxNodes or depth>self.maxDepth then fail("데이터 항목 또는 중첩 한도를 초과합니다.") end
    local tag=raw:sub(pos,pos);pos=pos+1
    if tag=="b" then
      local v=raw:sub(pos,pos);pos=pos+1
      if v~="0" and v~="1" then fail("Boolean 데이터가 손상되었습니다.") end
      return v=="1"
    elseif tag=="s" or tag=="d" then
      local n=length(tag=="s" and self.maxString or 32)
      if pos+n-1>#raw then fail("데이터가 잘렸습니다.") end
      local s=raw:sub(pos,pos+n-1);pos=pos+n
      if tag=="s" then if not text(s,self.maxString) then fail("유효하지 않은 UTF-8 문자열입니다.") end;return s end
      if not s:match("^[+%-]?%d+%.?%d*[eE]?[+%-]?%d*$") then fail("숫자 형식이 올바르지 않습니다.") end
      local v=tonumber(s);if not finite(v) then fail("유효하지 않은 숫자입니다.") end;return v
    elseif tag=="t" then
      local n=length(8192);local result={}
      for _=1,n do
        local key=decode(depth+1)
        if not (type(key)=="string" and #key<=128 or finite(key) and key==floor(key) and math.abs(key)<=8192) then fail("허용되지 않은 테이블 키입니다.") end
        if result[key]~=nil then fail("중복된 데이터 키입니다.") end
        result[key]=decode(depth+1)
      end
      return result
    end
    fail("알 수 없는 데이터 형식입니다.")
  end
  local value=decode(0);if pos~=#raw+1 then fail("데이터 뒤에 잘못된 내용이 있습니다.") end
  return value
end
function T:Pack(envelope)
  local raw=self:Encode(envelope)
  local result="KHQOL1:"..checksum(raw)..":"..base64(raw)
  if #result>self.maxText then fail("내보내기 문자열 크기 한도를 초과합니다.") end
  return result
end
function T:Unpack(value)
  if type(value)~="string" or #value>self.maxText then fail("문자열 크기 한도(350,000자)를 초과합니다.") end
  value=value:gsub("[ \t\r\n]","")
  local format,hash,encoded=value:match("^KHQOL(%d+):(%x%x%x%x%x%x%x%x):([A-Za-z0-9+/=]+)$")
  if not format then fail("KHQOL 프로필 문자열이 아니거나 일부가 누락되었습니다.") end
  if format~="1" then fail("지원하지 않는 프로필 포맷입니다. KHQOL 업데이트를 확인하세요.") end
  local raw=unbase64(encoded)
  if checksum(raw)~=hash:lower() then fail("검증값이 일치하지 않습니다. 문자열 전체를 다시 복사하세요.") end
  return self:Decode(raw)
end
local point={point="CENTER",relativePoint="CENTER",x=0,y=0}
-- Audited optional settings which only exist after first edit (not defaults).
function T:Schema()
  local schema=K:MakeDefaultProfile(true)
  schema.settings.modules.partyFrames=nil -- independent character role profiles
  schema.resourceColor={1,1,1,1};schema.cursorColor={color={r=1,g=1,b=1}}
  local clock=schema.legacy.clock
  if K.modules.clock then
  for _,key in ipairs({"date","weekday","money","performance","professions"}) do
    clock.modules[key].fontSize=14
    clock.textStyle[key]=K.CopyProfileValue(clock.textStyle.common)
  end
  clock.clockTools.positionLocked=true
  clock.todo.window.positionLocked=true;clock.todo.minimap.positionLocked=true
  clock.clockTools.positions={tools=K.CopyProfileValue(point),stopwatch=K.CopyProfileValue(point),alert=K.CopyProfileValue(point)}
  end
  local buff=schema.legacy.buffReminder
  buff.classes={SHAMAN={specials={weapon={mainHand={enabled=false},offHand={enabled=false}},
    totems={FIRE={enabled=false},EARTH={enabled=false},WATER={enabled=false},AIR={enabled=false}}}}}
  for _,key in ipairs(ForeverBuffReminder and ForeverBuffReminder.CLASS_TOKENS or {}) do buff.classes[key]=buff.classes[key] or {} end
  local env=schema.settings.modules.environmentTimer
  if env then env.hudTextPositions={BREATH={x=0,y=0},EXHAUSTION={x=0,y=0},FEIGNDEATH={x=0,y=0}} end
  if schema.settings.modules.questNavigator then schema.settings.modules.questNavigator.questTracker.fontSize=12 end
  schema.legacy.resourceSwing.comboLastColor={1,1,1,1}
  schema.legacy.campfire.completePosition=K.CopyProfileValue(point)
  for _,unit in pairs(schema.settings.modules.unitFrames or {}) do
    unit.showPower=true;unit.healthHeight=30;unit.powerHeight=12
  end
  return schema
end
local points={CENTER=true,TOP=true,BOTTOM=true,LEFT=true,RIGHT=true,TOPLEFT=true,TOPRIGHT=true,BOTTOMLEFT=true,BOTTOMRIGHT=true}
local strata={BACKGROUND=true,LOW=true,MEDIUM=true,HIGH=true,DIALOG=true}
local function validSetting(value,path,key,default)
  if type(value)=="string" then
    return text(value,4096) and (key~="point" and key~="relativePoint" or points[value])
      and (key~="frameStrata" or strata[value])
  end
  if type(value)~="number" then return true end
  if not finite(value) or math.abs(value)>1000000 then return false end
  if value==0 and default==0 then return true end -- documented default sentinels
  local name=type(key)=="string" and key:lower() or ""
  if path:lower():find("color",1,true) and (type(key)=="number" or key=="r" or key=="g" or key=="b" or key=="a") then return value>=0 and value<=1 end
  if name=="alpha" or name=="backgroundalpha" or name=="borderalpha" then return value>=0 and value<=1 end
  if name=="scale" then return value>0 and value<=1000 end
  if name:match("size$") and path~="profile.settings.modules.tooltip.textSize" then return value>0 and value<=512 end
  if name:match("width$") or name:match("height$") then return value>0 and value<=8192 end
  if name:match("interval$") then return value>0 and value<=60 end
  return true
end
local function leaves(value)
  if type(value)~="table" then return 1 end
  local n=0;for _,v in pairs(value) do n=n+leaves(v) end;return math.max(1,n)
end
-- Unknown settings are reported and omitted, never interpreted as live DB paths.
function T:Filter(source)
  self:Encode(source) -- bound traversal and reject cycles/objects before counting
  local report={normal=0,unsupported=0,review=0,details={}}
  local function reject(path,value,why)
    report.unsupported=report.unsupported+leaves(value)
    if #report.details<5 then report.details[#report.details+1]=safeLabel(path)..": "..why end
  end
  local function filter(value,schema,path,key)
    if schema==nil then reject(path,value,"현재 프로필 범위에서 제외");return end
    if type(value)~=type(schema) then reject(path,value,"타입 불일치");return end
    if type(schema)=="table" then
      local result={}
      for k,v in pairs(value) do
        local child=filter(v,schema[k],path.."."..tostring(k),k)
        if child~=nil then result[k]=child end
      end
      return result
    end
    if not validSetting(value,path,key,schema) then reject(path,value,"값 또는 범위 확인 필요");return end
    report.normal=report.normal+1;return value
  end
  return filter(source,self:Schema(),"profile"),report
end
local function client()
  local version,build,_,interface=K.PublicCall(GetBuildInfo)
  return {version=type(version)=="string" and version or "unknown",
    build=type(build)=="string" and build or "unknown",interface=finite(interface) and interface or 0}
end
local scopeNotice="노트·체크리스트, 공용 버프/NPC/발동 등록 목록, 캐릭터 기준 주문, 파티·공격대 역할 프로필·휠 주문, 실험실 잠금 정보와 계정 공용 창 선호는 제외됩니다."
T.scopeNotice=scopeNotice
function T:Export()
  local ok,result,report=pcall(function()
    if not K.profilesReady then fail("프로필 초기화를 기다려 주세요.") end
    local allowed,why=K:CanChangeProfile();if not allowed then fail(why) end
    -- Capture reads committed settings; do not save pages or change connections.
    local profile,counts=self:Filter(K:CaptureProfile())
    if counts.normal==0 then fail("내보낼 설정이 없습니다.") end
    local envelope={formatVersion=self.formatVersion,scopeVersion=self.scopeVersion,
      addonVersion=K.VERSION,profileName=K:GetCurrentProfileName(),sourceClient=client(),exportedSettings=profile}
    return self:Pack(envelope),counts
  end)
  if not ok then return nil,tostring(result) end
  return result,report
end
-- Kept separate from addonVersion so a future schema migration has one gateway.
function T:Migrate(envelope)
  if envelope.formatVersion~=self.formatVersion or envelope.scopeVersion~=self.scopeVersion then
    fail("현재 버전에서 변환할 수 없는 프로필 구조입니다. KHQOL 업데이트를 확인하세요.")
  end
  return envelope.exportedSettings
end
local tickets=setmetatable({}, {__mode="k"})
function T:Inspect(value)
  local ok,result=pcall(function()
    if not K.profilesReady then fail("프로필 초기화를 기다려 주세요.") end
    local envelope=self:Unpack(value)
    if type(envelope)~="table" or type(envelope.exportedSettings)~="table" or type(envelope.exportedSettings.settings)~="table"
      or not text(envelope.addonVersion,40) or not envelope.addonVersion:match("^%d+[%d%.]*$")
      or not text(envelope.profileName,96) or (utf8(envelope.profileName) or 0)==0 or utf8(envelope.profileName)>24
      or envelope.profileName:find("[|\r\n\t]") or type(envelope.sourceClient)~="table"
      or not text(envelope.sourceClient.version,80) or not text(envelope.sourceClient.build,80)
      or not finite(envelope.sourceClient.interface) then fail("프로필 메타데이터 또는 설정 구조가 올바르지 않습니다.") end
    local migrated=self:Migrate(envelope)
    -- Only a detached copy is migrated; live DB and saved snapshots are untouched.
    migrated=K.CopyProfileValue(migrated);K:MigrateProfileSettings(migrated.settings)
    local profile,report=self:Filter(migrated)
    if report.normal==0 then fail("현재 버전에서 사용할 수 있는 설정이 없습니다.") end
    local current=client()
    if envelope.addonVersion~=K.VERSION or current.interface~=envelope.sourceClient.interface
      or current.version~=envelope.sourceClient.version or current.build~=envelope.sourceClient.build then
      report.review=1;report.details[#report.details+1]="다른 애드온/게임 빌드: 해상도·API·직업별 기능은 적용 후 확인하세요."
    end
    local ticket={profileName=envelope.profileName,addonVersion=envelope.addonVersion,sourceClient=envelope.sourceClient,
      report=report,status=(report.review>0 or report.unsupported>0) and "부분 호환" or "정상"}
    tickets[ticket]={profile=profile,db=K.db,profiles=K.db.profiles,generation=K.profileGeneration,name=K:GetCurrentProfileName()}
    return ticket
  end)
  if not ok then return nil,tostring(result) end
  return result
end
function T:SuggestName(original)
  local suffix=" (가져옴)"
  for i=1,9999 do
    local ending=i==1 and suffix or " (가져옴 "..i..")"
    local limit=24-utf8(ending);local letters={}
    for letter in original:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
      if #letters==limit then break end;letters[#letters+1]=letter
    end
    local name=concat(letters)..ending
    if K.db.profiles[name]==nil then return name end
  end
  fail("가져온 프로필 이름을 만들 수 없습니다.")
end
function T:Import(ticket)
  local checked=tickets[ticket]
  if not checked then return false,"먼저 프로필 문자열을 검사하세요." end
  local allowed,why=K:CanChangeProfile();if not allowed then return false,why end
  if checked.db~=K.db or checked.profiles~=K.db.profiles or checked.generation~=K.profileGeneration or checked.name~=K:GetCurrentProfileName() then
    tickets[ticket]=nil;return false,"설정 상태가 바뀌었습니다. 문자열을 다시 검사하세요."
  end
  local ok,name=pcall(function()
    local proposed=self:SuggestName(ticket.profileName)
    local valid,message=K:ValidateProfileName(proposed);if not valid then fail(message) end
    local profile=K.CopyProfileValue(checked.profile)
    K.MergeDefaults(profile,K:MakeDefaultProfile(true))
    -- Single commit, no SaveCurrentProfile/SelectProfile or independent DB writes.
    K.db.profiles[valid]=profile
    return valid
  end)
  if not ok then return false,tostring(name) end
  tickets[ticket]=nil
  if K.RefreshProfileControls then K:RefreshProfileControls() end
  return true,name
end
function T:Discard(ticket) if ticket then tickets[ticket]=nil end end
