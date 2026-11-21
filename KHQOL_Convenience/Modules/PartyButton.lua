local K=_G.KHQOL
local M=K.modules.generalConvenience
local chat=K.modules.chatAutomation
local calls=K.modules.chatEnhancement
local call=K.PublicCall
local PU=K.PositionUtils
local home,instance=LE_PARTY_CATEGORY_HOME or 1,LE_PARTY_CATEGORY_INSTANCE or 2
local default={enabled=false,inheritGreeting=true,greeting="안녕하세요!",farewell="수고하셨습니다!",size=42,opacity=100,
  position={point="CENTER",relativePoint="CENTER",x=220,y=-160}}
local P={}
M.partyControl=P
M.defaults.partyButton=default

local media="Interface\\AddOns\\KHQOL_Convenience\\Media\\"
local icons={
  solo=media.."party_tab_add_member.tga",
  party=media.."party_tab_members.tga",
  leader=media.."party_tab_marker.tga",
  raid=media.."party_tab_group.tga",
}
local coords={0,68/128,0,70/128}
local labels={PARTY="일반 파티",RAID="공격대",INSTANCE_CHAT="인스턴스 그룹"}

function P:GetDB() return M:GetDB().partyButton end

function P:Appearance()
  local cfg=self:GetDB()
  local size=K.IsPublicNumber(cfg.size) and math.max(24,math.min(96,cfg.size)) or default.size
  local opacity=K.IsPublicNumber(cfg.opacity) and math.max(10,math.min(100,cfg.opacity)) or default.opacity
  return size,opacity/100
end

function P:GetMessage(key)
  local config=self:GetDB()
  if key=="greeting" and config.inheritGreeting then
    local old=chat:GetGreeting()
    if old~="" then return old end
  end
  return chat:ValidateText(config[key],255,255) or default[key]
end

function P:SetMessage(key,value)
  local clean,reason=chat:ValidateText(value,255,255)
  if not clean then M:Message(reason);return end
  local config=self:GetDB()
  config[key]=clean
  if key=="greeting" then config.inheritGreeting=false end
end

function P:ReadMode()
  local inInstance=call(IsInGroup,instance)
  if inInstance==true then
    local raid=call(IsInRaid,instance)==true
    local leader=call(UnitIsGroupLeader,"player",instance)==true
    return leader and "leader" or raid and "raid" or "party","INSTANCE_CHAT",instance,false
  end
  if inInstance~=false then return end
  local grouped,raid=call(IsInGroup,home),call(IsInRaid,home)
  if grouped==false and raid==false then return "solo",nil,nil,true end
  if grouped~=true or type(raid)~="boolean" then return end
  local count=call(GetNumGroupMembers,home)
  local capacity=raid and 40 or 5
  if not K.IsPublicNumber(count) or count<2 or count>capacity or count%1~=0 then return end
  local leader=call(UnitIsGroupLeader,"player",home)
  if count<capacity and type(leader)~="boolean" then return end
  return leader==true and "leader" or raid and "raid" or "party",raid and "RAID" or "PARTY",home,
    leader==true and count<capacity
end

function P:InviteTarget()
  local exists=call(UnitExists,"target")
  if exists==false then M:Message("대상이 없습니다.");return end
  if exists~=true or call(UnitIsPlayer,"target")~=true or call(UnitIsFriend,"player","target")~=true
    or call(UnitIsUnit,"target","player")~=false then
    M:Message("초대할 수 있는 우호 플레이어를 선택해 주세요.");return
  end
  local info=C_PartyInfo
  if type(info and info.InviteUnit)~="function" then M:Message("파티 초대 API를 사용할 수 없습니다.");return end
  if call(IsInGroup,home)==true and call(info.CanInvite)~=true then
    M:Message("현재 초대 권한을 확인할 수 없습니다.");return
  end
  if call(UnitInAnyGroup,"target",home)~=false or call(UnitInAnyGroup,"target",instance)~=false then
    M:Message("대상이 이미 그룹에 속했거나 그룹 상태를 확인할 수 없습니다.");return
  end
  local name=calls:ReadUnitWhisperName("target")
  if not name then M:Message("초대할 대상의 전체 이름을 확인할 수 없습니다.");return end
  local status=calls:SubmitPartyInvite(name)
  if status=="ok" then K.UsageDiagnostics:Emit("feature.party.execute","request","click") end
  if status~="ok" and status~="recent" then M:Message("파티 초대 요청을 보낼 수 없습니다.") end
end

function P:LeaveAfterFarewell(channel,category,delay)
  local ticket={category=category,profile=K.profileGeneration}
  self.leaveRequest=ticket
  local function leave()
    if self.leaveRequest~=ticket then return end
    local _,latest,group=self:ReadMode()
    if not self:GetDB().enabled or ticket.profile~=K.profileGeneration or latest~=channel or group~=category then
      self.leaveRequest=nil;return
    end
    local api=C_PartyInfo and C_PartyInfo.LeaveParty
    local usageStatus=K.ReadPublicAPI(api,category)
    if usageStatus=="ok" or usageStatus=="error" then K.UsageDiagnostics:Emit("feature.party.execute","request","click") end
    if usageStatus~="ok" then
      M:Message("탈퇴 요청이 차단되었습니다. 우클릭으로 기본 파티 메뉴를 열어 탈퇴할 수 있습니다.")
    end
    C_Timer.After(2,function() if P.leaveRequest==ticket then P.leaveRequest=nil end end)
  end
  if delay then C_Timer.After(1,leave) else leave() end
end

function P:OpenPartyMenu(button)
  local which,unit="SELF","player"
  if call(UnitExists,"target")==true and call(UnitIsUnit,"target","player")==false
    and call(UnitIsPlayer,"target")==true and call(UnitIsFriend,"player","target")==true then
    local raidStatus,raidIndex=K.ReadPublicAPI(UnitInRaid,"target")
    if raidStatus=="ok" and K.IsPublicNumber(raidIndex) and raidIndex>0 then
      which,unit="RAID_PLAYER","target"
    elseif raidStatus=="ok" and raidIndex==nil then
      local party=call(UnitInParty,"target")
      if type(party)=="boolean" then which,unit=party and "PARTY" or "PLAYER","target" end
    end
  end
  if K.ReadPublicAPI(UnitPopup_OpenMenu,which,{unit=unit,ownerFrame=button,
    fromPlayerFrame=unit=="player",fromTargetFrame=unit=="target"})~="ok" then
    M:Message("기본 파티 메뉴를 열 수 없습니다.")
  end
end

function P:Click(button,mouseButton)
  if not self:GetDB().enabled or K.PositionEditor.active or button.positionMoving then return end
  if mouseButton=="RightButton" then self:OpenPartyMenu(button);return end
  if mouseButton~="LeftButton" or button.altPress or call(IsAltKeyDown)==true or self.leaveRequest then return end
  local mode,channel,category,canInvite=self:ReadMode()
  if mode~=button.mode or channel~=button.channel or canInvite~=button.canInvite then self:Refresh();return end
  local leaving=call(IsShiftKeyDown)==true
  if not leaving and canInvite then self:InviteTarget();return end
  if not channel then return end
  local leave=C_PartyInfo and C_PartyInfo.LeaveParty
  if leaving and type(leave)~="function" then M:Message("파티 탈퇴 API를 사용할 수 없습니다.");return end
  local message=self:GetMessage(leaving and "farewell" or "greeting")
  if not leaving and message=="" then return end
  -- Submit chat on the click. The leave ticket only applies to this group.
  if message~="" then
    local status=chat:SendGroupMessage(message,channel,not leaving and "manual" or nil)
    if status=="ok" then K.UsageDiagnostics:Emit("feature.party.chat_request","request","click");if not leaving then K.UsageDiagnostics:Emit("feature.party.execute","request","click") end end
    if status=="duplicate" then M:Message("현재 그룹원에게 같은 인사를 이미 요청했습니다.");return end
    if status=="recent" then return end
    if status~="ok" then
      if status=="restricted" and chat:OpenGroupDraft(message,channel) then
        K.UsageDiagnostics:Emit("feature.party.draft","draft","click")
        M:Message(leaving and "작별 인사를 채팅창에 입력했습니다. 직접 전송한 뒤 그룹을 나가 주세요." or "인사를 채팅창에 입력했습니다. Enter로 전송하세요.")
      else
        M:Message(leaving and "작별 인사를 요청할 수 없어 그룹에 남았습니다." or "인사를 전송할 수 없습니다.")
      end
      return
    end
  end
  if leaving then self:LeaveAfterFarewell(channel,category,message~="") end
end

function P:Refresh()
  local button=self.button
  if not button then return end
  local config=self:GetDB()
  local mode,channel,_,canInvite=self:ReadMode()
  if self.leaveRequest and call(IsInGroup,self.leaveRequest.category)==false then self.leaveRequest=nil end
  if button.mode~=mode then
    if icons[mode] then button.icon:SetTexture(icons[mode]) end
  end
  button.mode,button.channel,button.canInvite=mode,channel,canInvite
  if not config.enabled or not mode then K.PositionStore:FinishFrameDrag(button) end
  button:SetShown(config.enabled and mode~=nil)
  if GameTooltip:IsOwned(button) then
    if button:IsShown() then self:Tooltip(button) else GameTooltip:Hide() end
  end
end

function P:Tooltip(button)
  GameTooltip:SetOwner(button,"ANCHOR_RIGHT")
  if not button.channel then
    GameTooltip:SetText("파티 초대")
  else
    GameTooltip:SetText(labels[button.channel] or "파티")
  end
  GameTooltip:AddLine(button.canInvite and "좌클릭 · 선택한 우호 플레이어 초대" or "좌클릭 · 인사",1,1,1,true)
  if button.channel then GameTooltip:AddLine("Shift+좌클릭 · 작별 인사 후 탈퇴",1,1,1,true) end
  GameTooltip:AddLine("우클릭 · 선택한 아군 또는 내 파티 메뉴",1,1,1,true)
  GameTooltip:AddLine("Alt+드래그 · 위치 이동",1,1,1,true)
  GameTooltip:Show()
end

function P:ApplyPosition()
  if self.button then PU.ApplyPoint(self.button,self:GetDB().position) end
end

function P:ResetPosition()
  K.ReplaceProfileValue(self:GetDB().position,default.position)
  self:ApplyPosition()
end

function P:AddPositionTarget(list)
  local config=self:GetDB()
  if not config.enabled or not self.button then return end
  local icon=icons[self.button.mode] or icons.solo
  local size,alpha=self:Appearance()
  local target=PU:Add(list,"partyButton","generalConvenience","파티 버튼",self.button,PU:PointWriter(config.position),nil,
    function() self:ApplyPosition() end,
    {sample="파티 버튼",settingsRoute={module="convenienceParty",section="파티 버튼"},
      art={{texture=icon,width=size*68/70,height=size,texCoord=coords,alpha=alpha}}})
  if target then PU:ConfigureResets({target},function(t,point) point(t,function() return self:GetDB().position end,default.position) end) end
end

function P:Configure()
  if not self.button then
    local button=CreateFrame("Button",nil,UIParent)
    button:SetMovable(true)
    button:SetClampedToScreen(true)
    button.icon=button:CreateTexture(nil,"ARTWORK")
    button.icon:SetAllPoints()
    button.icon:SetTexCoord(unpack(coords))
    local highlight=button:CreateTexture(nil,"HIGHLIGHT")
    highlight:SetAllPoints();highlight:SetColorTexture(1,.82,0,.12)
    button:RegisterForClicks("LeftButtonUp","RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetScript("OnMouseDown",function(frame,key) if key=="LeftButton" then frame.altPress=call(IsAltKeyDown)==true end end)
    button:SetScript("OnDragStart",function(frame)
      if not frame.altPress or K.PositionEditor.active or not self:GetDB().enabled then return end
      frame.positionMoving=true;frame:StartMoving()
    end)
    button:SetScript("OnDragStop",function(frame)
      if not frame.positionMoving then return end
      frame.positionMoving=nil
      local store=K.PositionStore
      if store:Point(frame,self:GetDB().position) then store:Committed(function() self:ApplyPosition() end)
      else self:ApplyPosition() end
    end)
    button:SetScript("OnClick",function(frame,key) self:Click(frame,key) end)
    button:SetScript("OnEnter",function(frame) self:Tooltip(frame) end)
    button:SetScript("OnLeave",function(frame) if GameTooltip:IsOwned(frame) then GameTooltip:Hide() end end)
    self.button=button
    local events=CreateFrame("Frame")
    for _,event in ipairs({"PLAYER_ENTERING_WORLD","PLAYER_LEAVING_WORLD","GROUP_ROSTER_UPDATE","GROUP_JOINED","GROUP_LEFT","PARTY_LEADER_CHANGED",
        "PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED"}) do
      pcall(events.RegisterEvent,events,event)
    end
    events:SetScript("OnEvent",function(_,event,category)
      local leave=self.leaveRequest
      if leave and (event=="PLAYER_LEAVING_WORLD" or (event=="GROUP_LEFT" or event=="GROUP_JOINED")
        and (not K.IsPublicNumber(category) or category==leave.category)) then self.leaveRequest=nil end
      self:Refresh()
      if not self.updateQueued then
        self.updateQueued=true
        C_Timer.After(0,function() self.updateQueued=nil;self:Refresh() end)
      end
    end)
  end
  local size,alpha=self:Appearance()
  self.button:SetSize(size*68/70,size);self.button:SetAlpha(alpha)
  if not self:GetDB().enabled then self.leaveRequest=nil end
  self:ApplyPosition()
  self:Refresh()
end
