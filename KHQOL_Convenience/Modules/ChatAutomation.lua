local _, K = ...
K = assert(_G.KHQOL, "Install and enable KHQOL.")
local A = { channels={"SAY","PARTY","GUILD","RAID"} }
K.modules.chatAutomation = A
local labels={SAY="일반",PARTY="파티",GUILD="길드",RAID="공격대"}
local supported={SAY=true,PARTY=true,GUILD=true,RAID=true}
local HOME=LE_PARTY_CATEGORY_HOME or 1
local INSTANCE=LE_PARTY_CATEGORY_INSTANCE or 2
local function secret(v) return type(issecretvalue)=="function" and issecretvalue(v) end
local function call(fn,...)
  if type(fn)~="function" then return end
  local r={pcall(fn,...)}
  if not r[1] then return end
  for i=2,8 do if secret(r[i]) then return end end
  return unpack(r,2,8)
end
local function text(v) return not secret(v) and type(v)=="string" end
local function trim(v) return v:gsub("^[ \t\r\n]+",""):gsub("[ \t\r\n]+$","") end
-- Strict Unicode scalar decoding: Lua 5.1 compatible, no utf8/strlenutf8 dependency.
local function nextUTF8(s,i)
  local a,b,c,d=s:byte(i,i+3)
  if not a then return end
  if a<128 then return i+1 end
  local n=a>=194 and a<=223 and 2 or a>=224 and a<=239 and 3 or a>=240 and a<=244 and 4
  if not n then return end
  if not b or b<128 or b>191 then return end
  if n>=3 and (not c or c<128 or c>191) then return end
  if n==4 and (not d or d<128 or d>191) then return end
  if (a==224 and b<160) or (a==237 and b>159) or (a==240 and b<144) or (a==244 and b>143) then return end
  return i+n
end
function A:ValidateText(value,maxChars,maxBytes)
  if not text(value) or #value>4096 then return nil,"올바른 UTF-8 문자열을 입력하세요." end
  value=trim(value)
  if value:find("[%z\1-\31\127|]") then return nil,"제어 문자와 | 색상·링크 코드는 사용할 수 없습니다." end
  local i,count=1,0
  while i<=#value do
    i=nextUTF8(value,i)
    if not i then return nil,"올바르지 않은 UTF-8 문자열입니다." end
    count=count+1
  end
  if count>maxChars then return nil,maxChars.."글자까지 입력할 수 있습니다." end
  if maxBytes and #value>maxBytes then return nil,maxBytes.."바이트까지 입력할 수 있습니다." end
  if value:sub(1,1)=="/" then return nil,"/로 시작하는 문구는 사용할 수 없습니다." end
  return value
end
function A:GetDB() return K.modules.general:GetDB() end
function A:GetCharacterData()
  local key=K.profileCharacter or call(K.GetProfileCharacterKey,K)
  if not text(key) or key=="" or not K.db then return end
  -- Same account-global, realm-qualified storage pattern as gatherTracking.
  local global=K.db.globalData
  if global==nil then global={};K.db.globalData=global end
  if type(global)~="table" then return end
  if global.profileCharacters==nil then global.profileCharacters={} end
  if type(global.profileCharacters)~="table" then return end
  local character=global.profileCharacters[key]
  if character==nil then character={};global.profileCharacters[key]=character end
  if type(character)~="table" then return end
  if character.chatAutomation==nil then character.chatAutomation={prefixes={},greeting=""} end
  local data=character.chatAutomation
  if type(data)~="table" then return end
  if data.prefixes==nil then data.prefixes={} end
  if type(data.prefixes)~="table" then return end
  return data
end
function A:Message(value)
  if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffffd54aKHQOL 대화창:|r "..value) end
end
function A:GetPrefix(channel)
  local data=self:GetCharacterData()
  return self:ValidateText(data and data.prefixes[channel] or "",10) or ""
end
function A:SetPrefix(channel,value)
  if not supported[channel] then return false end
  local clean,err=self:ValidateText(value,10)
  local data=self:GetCharacterData()
  if not clean or not data then self:Message(err or "캐릭터 정보를 확인할 수 없습니다.");return false end
  data.prefixes[channel]=clean
  return true
end
function A:GetGreeting()
  local data=self:GetCharacterData()
  return self:ValidateText(data and data.greeting or "",255,255) or ""
end
function A:SetGreeting(value)
  local clean,err=self:ValidateText(value,255,255)
  local data=self:GetCharacterData()
  if not clean or not data then self:Message(err or "캐릭터 정보를 확인할 수 없습니다.");return false end
  data.greeting=clean;return true
end
function A:ResetPrefixes()
  local data=self:GetCharacterData();if not data then return end
  for _,channel in ipairs(self.channels) do data.prefixes[channel]="" end
end
function A:Slash(value)
  if not text(value) then return end
  value=trim(value)
  if value=="" then
    for _,channel in ipairs(self.channels) do self:Message(labels[channel]..": "..self:GetPrefix(channel)) end
    self:Message("/말머리 일반·파티·길드·공격대 내용 · /말머리 리셋 · 사용 ON/OFF는 설정에서 변경")
  elseif value=="리셋" then self:ResetPrefixes();self:Message("모든 말머리를 초기화했습니다.")
  else
    local name,body=value:match("^([^ \t]+)[ \t]*(.*)$")
    for _,channel in ipairs(self.channels) do
      if labels[channel]==name then
        if self:SetPrefix(channel,body) then self:Message(name.." 말머리: "..self:GetPrefix(channel)) end
        return
      end
    end
    self:Message("/말머리 일반·파티·길드·공격대 내용 · /말머리 리셋")
  end
end
-- Keep UTF-8 and entire WoW links/texture tokens intact at the byte limit.
-- Reserve a reset for an open color so clipping cannot color subsequent chat.
function A:ClipMessage(value,budget)
  local out,i,used,color={},1,0,false
  while i<=#value do
    local finish=nextUTF8(value,i)
    local newColor=color
    if value:sub(i,i)=="|" then
      local tag=value:sub(i+1,i+1)
      if tag=="H" then
        local a=value:find("|h",i+2,true);local b=a and value:find("|h",a+2,true)
        finish=b and b+2
      elseif tag=="T" or tag=="A" then
        local e=value:find(tag=="T" and "|t" or "|a",i+2,true);finish=e and e+2
      elseif tag=="c" then
        local named=value:match("^|cn[%w_]+:",i)
        if named then finish=i+#named
        elseif value:sub(i+2,i+9):match("^%x%x%x%x%x%x%x%x$") then finish=i+10
        else return end
        newColor=true
      elseif tag=="r" then finish=i+2;newColor=false
      elseif tag=="|" then finish=i+2
      else return end -- Unknown/malformed control syntax: do not rewrite it.
    end
    if not finish then return end
    local size=finish-i
    if used+size+(newColor and 2 or 0)>budget then break end
    out[#out+1]=value:sub(i,finish-1);used=used+size;color=newColor;i=finish
  end
  if color then out[#out+1]="|r" end
  return table.concat(out)
end
function A:PrepareMessage(value,channel)
  if not text(channel) or not supported[channel] or not text(value) or #value>8192 or value==""
    or value:match("^[ \t]*/") or not value:find("[^ \t\r\n]") then return value end
  local prefix=self:GetDB().chatPrefixes and self:GetPrefix(channel) or ""
  if prefix~="" and value~=prefix and value:sub(1,#prefix+1)~=prefix.." " then
    local body=self:ClipMessage(value,255-#prefix-1)
    if value:find("|H",1,true) and body~=value then
      return value,"링크 전체를 보존하기 위해 이번 메시지의 말머리를 생략했습니다."
    end
    if body and body~="" then return prefix.." "..body end
    return value,"링크·제어 문자열을 보존하기 위해 이번 메시지의 말머리를 생략했습니다."
  end
  return value:find("|H",1,true) and value or self:ClipMessage(value,255) or value
end
function A:PreSend(box)
  if not (K.db and K.db.general and K.db.general.chatPrefixes==true) or not box or call(box.IsForbidden,box)==true then return end
  if call(InCombatLockdown)==true and call(box.IsProtected,box)==true then return end
  local channel=call(box.GetChatType,box) or call(box.GetAttribute,box,"chatType")
  if not text(channel) or not supported[channel] then return end
  local value=call(box.GetText,box)
  if not text(value) then return end
  local prepared,notice=self:PrepareMessage(value,channel)
  if notice then self:Message(notice) end
  if prepared~=value then call(box.SetText,box,prepared) end
end
function A:ReadRoster(channel)
  local category=channel=="INSTANCE_CHAT" and INSTANCE or HOME
  local raid=call(IsInRaid,category)
  if type(raid)~="boolean" then return end
  local n=call(GetNumGroupMembers,category)
  if type(n)~="number" or n%1~=0 or n<2 or n>40 then return end
  local members={}
  for index=0,n-1 do
    local unit=raid and "raid"..(index+1) or (index==0 and "player" or "party"..index)
    local guid=call(UnitGUID,unit)
    if not text(guid) or guid=="" or members[guid] then return end
    members[guid]=true
  end
  return members
end
function A:ReadGroup()
  local grouped,raid=call(IsInGroup,HOME),call(IsInRaid,HOME)
  if grouped==false and raid==false then return "solo" end
  if grouped~=true or type(raid)~="boolean" or call(IsInGroup,INSTANCE)~=false then return end
  if self:ReadRoster(raid and "RAID" or "PARTY") then return raid and "raid" or "party" end
end
function A:Baseline()
  self.pendingJoin=nil;self.pendingLeave=nil;self.pendingGreeting=nil
  local state=self:ReadGroup()
  self.groupActive=state=="party" or state=="raid"
  self.soloArmed=state=="solo"
end
function A:SendGroupMessage(message,channel,greetingOrigin)
  local sender=C_ChatInfo and C_ChatInfo.SendChatMessage
  if type(sender)~="function" then return "missing" end
  if call(C_ChatInfo.InChatMessagingLockdown)~=false then return "restricted" end
  local body=self:PrepareMessage(message,channel)
  local previous,record
  if greetingOrigin then
    self.greetingsSent=self.greetingsSent or {}
    previous=self.greetingsSent[channel]
    local members,now=self:ReadRoster(channel),call(GetTime)
    if previous and previous.body==body then
      if members and previous.members then
        local newcomer=false
        for guid in pairs(members) do if not previous.members[guid] then newcomer=true;break end end
        if not newcomer then return "duplicate" end
      elseif type(now)=="number" and type(previous.at)=="number" and now-previous.at<2 then return "recent" end
    end
    record={body=body,members=members,at=now}
    self.greetingsSent[channel]=record
  end
  local status,result=K.ReadPublicAPI(sender,body,channel)
  if status=="ok" and result==false then
    if record and self.greetingsSent[channel]==record then self.greetingsSent[channel]=previous end
    return "error"
  end
  return status
end

function A:OpenGroupDraft(message,channel)
  local util=ChatFrameUtil
  if not util or type(util.OpenChat)~="function" then return false end
  for _,getBox in ipairs({"GetActiveWindow","ChooseBoxForSend"}) do
    local status,box=K.ReadPublicAPI(util[getBox])
    if status~="ok" or (box and call(box.GetText,box)~="") then return false end
  end
  local commands={PARTY=SLASH_PARTY1 or "/p",RAID=SLASH_RAID1 or "/raid",INSTANCE_CHAT=SLASH_INSTANCE_CHAT1 or "/instance"}
  return commands[channel] and K.ReadPublicAPI(util.OpenChat,commands[channel].." "..message)=="ok"
end

function A:ObserveGroup()
  if not self.inWorld then return end
  local state=self:ReadGroup()
  if not state then
    if self.soloArmed and not self.pendingJoin and call(IsInGroup,HOME)==true then self.pendingJoin=call(GetTime) end
    return -- Unknown data never creates a leave/join edge.
  end
  if state=="solo" then
    if self.pendingLeave then self.groupActive=false;self.soloArmed=true;self.pendingLeave=nil end
    self.pendingJoin=nil;return
  end
  if self.groupActive then return end -- Adds, removals, leader change, conversion.
  if not self.soloArmed then self.groupActive=true;return end -- Login recovery.
  local started,now=self.pendingJoin,call(GetTime)
  self.groupActive=true;self.soloArmed=false;self.pendingJoin=nil
  if started and (type(now)~="number" or now-started>10) then return end
  local db=self:GetDB()
  if not db.chatAutoGreeting or (state=="raid" and not db.chatRaidGreeting) then return end
  local channel=state=="raid" and "RAID" or "PARTY"
  local ticket={}
  self.pendingGreeting=ticket
  C_Timer.After(1.5,function()
    if self.pendingGreeting~=ticket then return end
    self.pendingGreeting=nil
    local options=self:GetDB()
    if not self.inWorld or not options.chatAutoGreeting or (state=="raid" and not options.chatRaidGreeting)
      or self:ReadGroup()~=state then return end
    local greeting=self:GetGreeting()
    if greeting~="" then self:SendGroupMessage(greeting,channel,"automatic") end
  end)
end
function A:OnEvent(event,category)
  if event=="ADDON_LOADED" then self:RegisterPreSend();return end
  if event=="PLAYER_LEAVING_WORLD" then self.inWorld=false;self.worldTicket=nil;self.pendingJoin=nil;self.pendingGreeting=nil;return end
  if event=="PLAYER_ENTERING_WORLD" then
    self.inWorld=false;self:Baseline()
    if self:GetDB().chatAutoGreeting~=true then self.inWorld=true;self.worldTicket=nil;return end
    local ticket={};self.worldTicket=ticket
    -- Two baseline samples suppress the initial restore/loading event stream.
    -- This bounded settle is NOT the deduplication mechanism; groupActive is.
    if C_Timer and type(C_Timer.After)=="function" then
      C_Timer.After(2,function()
        if A.worldTicket~=ticket then return end
        A:Baseline();A.inWorld=true;A.worldTicket=nil
      end)
    end
    return -- Without a timer, fail closed rather than greet during restoration.
  end
  if self.greetingsSent then
    if (event=="GROUP_LEFT" and not secret(category) and category==HOME) or call(IsInGroup,HOME)==false then
      self.greetingsSent.PARTY=nil;self.greetingsSent.RAID=nil
    end
    if (event=="GROUP_LEFT" and not secret(category) and category==INSTANCE) or call(IsInGroup,INSTANCE)==false then
      self.greetingsSent.INSTANCE_CHAT=nil
    end
  end
  if not self.inWorld then return end
  if event=="GROUP_LEFT" then
    if secret(category) or category~=HOME then return end
    self.pendingLeave=true;self.pendingJoin=nil;self.pendingGreeting=nil
  elseif event=="GROUP_JOINED" then
    if secret(category) or category~=HOME then return end
    if self.groupActive then self.pendingLeave=nil end
    if self.soloArmed and not self.pendingJoin then self.pendingJoin=call(GetTime) end
  end
  self:ObserveGroup()
end
function A:ApplySettings()
  self:Baseline() -- Turning ON / changing profile while grouped is never a join.
end
function A:RegisterPreSend()
  if self.preSendSupported then return end
  if ChatFrameEditBoxMixin and type(ChatFrameEditBoxMixin.OnPreSendText)=="function"
    and EventRegistry and type(EventRegistry.RegisterCallback)=="function" then
    EventRegistry:RegisterCallback("ChatFrame.OnEditBoxPreSendText",function(_,box) A:PreSend(box) end,self)
    self.preSendSupported=true
    if self.events then self.events:UnregisterEvent("ADDON_LOADED") end
  end
end
function A:Initialize()
  if self.initialized then return end
  self.initialized=true
  SLASH_KHQOLPREFIX1="/말머리"
  SlashCmdList.KHQOLPREFIX=function(value) A:Slash(value) end
  self.events=CreateFrame("Frame")
  self.events:RegisterEvent("PLAYER_ENTERING_WORLD");self.events:RegisterEvent("PLAYER_LEAVING_WORLD")
  self.events:RegisterEvent("ADDON_LOADED");self:RegisterPreSend()
  for _,event in ipairs({"GROUP_ROSTER_UPDATE","GROUP_JOINED","GROUP_LEFT"}) do
    pcall(self.events.RegisterEvent,self.events,event)
  end
  self.events:SetScript("OnEvent",function(_,event,...) A:OnEvent(event,...) end)
  self:ApplySettings()
end
