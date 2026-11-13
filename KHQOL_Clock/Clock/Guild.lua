local K=_G.KHQOL
local FC=K.modules.clock
local call=K.PublicCall
local rosterEvents={"PLAYER_ENTERING_WORLD","PLAYER_GUILD_UPDATE","GUILD_ROSTER_UPDATE","CLUB_ADDED","CLUB_REMOVED",
  "CLUB_MEMBERS_UPDATED","CLUB_MEMBER_ADDED","CLUB_MEMBER_REMOVED","CLUB_MEMBER_UPDATED","CLUB_MEMBER_PRESENCE_UPDATED"}

function FC:GuildTooltipLimit()
  local value=self.db.modules.guild.tooltipLimit
  return K.IsPublicNumber(value) and math.max(1,math.min(1000,math.floor(value))) or 15
end

function FC:ShowGuildTooltip(frame)
  local roster=self.guildRoster
  if not roster or not frame:IsVisible() or K.PositionEditor.active or frame.dragStartX then return end
  local tip=self.guildTooltip
  tip.title:SetText("길드 접속 "..#roster.."명")
  local width=tip.title:GetStringWidth()
  local top=8+tip.title:GetStringHeight()+4
  local levelWidth,nameWidth=0,0
  local count=0
  if #roster<self:GuildTooltipLimit() then
    count=#roster
    for index,member in ipairs(roster) do
      local row=tip.rows[index]
      if not row then
        row={level=tip:CreateFontString(nil,"ARTWORK","GameTooltipText"),
          name=tip:CreateFontString(nil,"ARTWORK","GameTooltipText")}
        row.level:SetJustifyH("RIGHT")
        row.name:SetJustifyH("LEFT")
        tip.rows[index]=row
      end
      local color=member.class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[member.class]
      local r,g,b=.9,.9,.9
      if color then r,g,b=color.r,color.g,color.b end
      row.level:SetText(tostring(member.level or "?"));row.level:SetTextColor(r,g,b)
      row.name:SetText(member.name);row.name:SetTextColor(r,g,b)
      levelWidth=math.max(levelWidth,row.level:GetStringWidth())
      nameWidth=math.max(nameWidth,row.name:GetStringWidth())
    end
    width=math.max(width,levelWidth+8+nameWidth)
  else
    tip.hint:SetText(self.guildClickReady and "클릭하여 길드창에서 확인" or "기본 길드 버튼에서 확인")
    width=math.max(width,tip.hint:GetStringWidth())
    top=top+tip.hint:GetStringHeight()
  end
  tip.hint:SetShown(#roster>=self:GuildTooltipLimit())
  tip.hint:ClearAllPoints();tip.hint:SetPoint("TOPLEFT",tip.title,"BOTTOMLEFT",0,-4)
  for index,row in ipairs(tip.rows) do
    local shown=index<=count
    row.level:SetShown(shown);row.name:SetShown(shown)
    if shown then
      row.level:ClearAllPoints();row.level:SetPoint("TOPRIGHT",tip,"TOPLEFT",8+levelWidth,-top)
      row.name:ClearAllPoints();row.name:SetPoint("TOPLEFT",tip,"TOPLEFT",16+levelWidth,-top)
      top=top+math.max(row.level:GetStringHeight(),row.name:GetStringHeight())+1
    end
  end
  tip:SetSize(width+16,top+8)
  tip:ClearAllPoints();tip:SetPoint("TOP",frame,"BOTTOM",0,-4)
  tip:Show()
end

function FC:UpdateGuildClick()
  local button,frame=self.guildClick,self.modules.guild
  if not button or call(InCombatLockdown)==true then return end
  if frame.dragStartX then return end
  if K.PositionEditor.active then self.guildTooltip:Hide() end
  local delegate=_G.GuildMicroButton
  local scriptedInput=Enum and Enum.ForbiddenAspect and Enum.ForbiddenAspect.ScriptedInput
  local x,y,width,height=K.PositionUtils.Rect(frame)
  local cx,cy=K.PositionStore:Screen()
  local ready=delegate and not K.PositionEditor.active and frame:IsVisible() and self.guildRoster
    and x and cx and call(delegate.HasAccessConstraints,delegate)==false
    and scriptedInput and call(delegate.HasAnyForbiddenAspects,delegate,scriptedInput)==false
  self.guildClickReady=ready and true or false
  if not ready then button:Hide();return end
  if button:GetAttribute("clickbutton1")~=delegate then button:SetAttribute("clickbutton1",delegate) end
  button:ClearAllPoints();button:SetPoint("CENTER",UIParent,"CENTER",x-cx,y-cy)
  button:SetSize(width,height)
  button:SetFrameStrata(frame:GetFrameStrata())
  button:SetFrameLevel(frame:GetFrameLevel()+1)
  button:Show()
end

function FC:UpdateGuildDisplay()
  local frame,cfg=self.modules.guild,self.db.modules.guild
  local alpha=cfg.background and .68 or 0
  frame:SetBackdropColor(.015,.015,.015,alpha)
  frame:SetBackdropBorderColor(.95,.73,.15,not self.db.locked and .68 or alpha)
  local roster=self.guildRoster
  frame:SetShown(self.guildWatching and roster~=nil)
  if not roster then
    self.guildTooltip:Hide()
    self:UpdateGuildClick()
    return
  end
  frame.text:SetText((cfg.showTitle and "길드 " or "")..#roster)
  self:SyncStyledText(frame.text)
  frame:SetWidth(math.max(28,frame.text:GetStringWidth()+16))
  self:UpdateGuildClick()
  if self.guildTooltip:IsShown() then self:ShowGuildTooltip(frame) end
end

function FC:RefreshGuildRoster(eventClub)
  local club=call(IsInGuild)==true and C_Club and call(C_Club.GetGuildClubId) or nil
  if club and club==self.removedGuild then
    self.guildClub,self.guildRoster=nil,nil
    self:UpdateGuildDisplay()
    return
  end
  self.removedGuild=nil
  local changed=club~=self.guildClub
  if changed then self.guildClub,self.guildRoster=club,nil end
  if not club then self:UpdateGuildDisplay();return end
  if not changed and eventClub~=nil and eventClub~=club then return end
  if changed then
    call(C_Club.FocusMembers,club)
    call(C_GuildInfo and C_GuildInfo.GuildRoster)
  end
  if call(C_Club.AreMembersReady,club)~=true then
    self.guildRoster=nil;self:UpdateGuildDisplay();return
  end
  local ids=call(C_Club.GetClubMembers,club)
  local states=Enum and Enum.ClubMemberPresence
  if type(ids)~="table" or #ids==0 or not states then
    self.guildRoster=nil;self:UpdateGuildDisplay();return
  end
  local roster,seen={},{}
  local selfIncluded=false
  for _,id in ipairs(ids) do
    local info=call(C_Club.GetMemberInfo,club,id)
    local presence=info and call(function() return info.presence end)
    if presence==nil then
      self.guildRoster=nil;self:UpdateGuildDisplay();return
    end
    if presence==states.Online or presence==states.Away or presence==states.Busy then
      local guid=call(function() return info.guid end)
      if type(guid)~="string" or guid=="" then guid=id end
      local isSelf=call(function() return info.isSelf end)==true
      if not seen[guid] and not (isSelf and selfIncluded) then
        seen[guid]=true
        selfIncluded=selfIncluded or isSelf
        local name=call(function() return info.name end)
        local level=call(function() return info.level end)
        local classID=call(function() return info.classID end)
        local classInfo=classID and call(C_CreatureInfo and C_CreatureInfo.GetClassInfo,classID)
        local class=classInfo and call(function() return classInfo.classFile end)
        roster[#roster+1]={name=type(name)=="string" and name or "이름 확인 중",level=level,class=class}
      end
    end
  end
  table.sort(roster,function(a,b) return a.name<b.name end)
  self.guildRoster=roster
  self:UpdateGuildDisplay()
end

function FC:ConfigureGuildDisplay()
  local watching=self.db.enabled and self.db.modules.guild.enabled
  if watching~=self.guildWatching then
    self.guildWatching=watching
    self.guildEvents:UnregisterAllEvents()
    if watching then
      for _,event in ipairs(rosterEvents) do pcall(self.guildEvents.RegisterEvent,self.guildEvents,event) end
      self:RefreshGuildRoster()
      return
    end
    self.guildClub,self.guildRoster,self.removedGuild=nil,nil,nil
  end
  self:UpdateGuildDisplay()
end

function FC:SetupGuildDisplay(frame)
  frame:Hide()
  local tip=CreateFrame("Frame",nil,UIParent,"BackdropTemplate")
  FC.MakeBackdrop(tip,.95,.73,.15,.94)
  tip:SetFrameStrata("TOOLTIP");tip:SetClampedToScreen(true);tip:EnableMouse(false);tip:Hide()
  tip.title=tip:CreateFontString(nil,"ARTWORK","GameTooltipHeaderText")
  tip.title:SetPoint("TOPLEFT",tip,"TOPLEFT",8,-8);tip.title:SetTextColor(1,.82,.18)
  tip.hint=tip:CreateFontString(nil,"ARTWORK","GameTooltipText");tip.hint:SetTextColor(.8,.8,.8)
  tip.rows={}
  self.guildTooltip=tip

  self.guildEvents=CreateFrame("Frame")
  self.guildEvents:SetScript("OnEvent",function(_,event,first)
    local club
    if event:find("^CLUB_") and K.IsPublicValue(first) then club=first end
    if event=="CLUB_REMOVED" and club and club==self.guildClub then
      self.removedGuild,self.guildClub,self.guildRoster=club,nil,nil
    elseif (event=="CLUB_ADDED" and club==self.removedGuild) or event=="PLAYER_GUILD_UPDATE" then
      self.removedGuild=nil
    end
    self:RefreshGuildRoster(club)
  end)
  frame:SetScript("OnEnter",function(f) self:ShowGuildTooltip(f) end)
  local function leave() tip:Hide() end
  frame:SetScript("OnLeave",leave)
  frame:SetScript("OnHide",leave)
  frame:HookScript("OnMouseDown",leave)

  -- Keep the protected hit area separate from the movable clock HUD.
  local button=CreateFrame("Button",nil,UIParent,"SecureActionButtonTemplate,SecureHandlerStateTemplate")
  button:Hide();button:RegisterForClicks("LeftButtonUp");button:SetAttribute("useOnKeyDown",false)
  button:SetAttribute("_onstate-khqolcombat",[[
    if newstate == "combat" then
      self:SetAttribute("type1", nil)
      self:Hide()
    end
  ]])
  RegisterStateDriver(button,"khqolcombat","[combat] combat; idle")
  button:SetScript("OnEnter",function() self:ShowGuildTooltip(frame) end)
  button:SetScript("OnLeave",leave)
  button:SetScript("OnHide",leave)
  -- The overlay is also the hardware click target, so leave it in place
  -- until release while the unlocked clock module moves underneath it.
  button:SetScript("OnMouseDown",function(b,key)
    if key~="LeftButton" or call(InCombatLockdown)==true or K.PositionEditor.active then return end
    b.pressX,b.pressY=GetCursorPosition()
    frame:GetScript("OnMouseDown")(frame,key)
  end)
  button:SetScript("OnMouseUp",function(_,key)
    frame:GetScript("OnMouseUp")(frame,key)
    self:UpdateGuildClick()
  end)
  button:SetScript("PreClick",function(b,key)
    if call(InCombatLockdown)==true then return end
    local x,y=GetCursorPosition()
    local club=call(IsInGuild)==true and C_Club and call(C_Club.GetGuildClubId)
    local clicked=key=="LeftButton" and b.pressX and math.abs(x-b.pressX)<=5 and math.abs(y-b.pressY)<=5
      and not frame.didDrag and not K.PositionEditor.active and frame:IsVisible() and self.guildClickReady
      and club and club==self.guildClub
    b.pressX,b.pressY=nil,nil
    b:SetAttribute("type1",clicked and "click" or nil)
  end)
  button:SetScript("PostClick",function(b)
    if call(InCombatLockdown)~=true then b:SetAttribute("type1",nil) end
  end)
  self.guildClick=button
  local inputEvents=CreateFrame("Frame")
  for _,event in ipairs({"PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED","DISPLAY_SIZE_CHANGED","UI_SCALE_CHANGED"}) do
    inputEvents:RegisterEvent(event)
  end
  inputEvents:SetScript("OnEvent",function(_,event)
    if event=="PLAYER_REGEN_DISABLED" then
      button.pressX,button.pressY=nil,nil
      if frame.dragStartX then
        frame:StopMovingOrSizing()
        frame.dragStartX,frame.dragStartY=nil,nil
        self:ApplyLayout()
      end
    else
      self:UpdateGuildClick()
    end
  end)
  hooksecurefunc(K.PositionEditor,"Enter",function() self:UpdateGuildClick() end)
  hooksecurefunc(K.PositionEditor,"Finish",function() self:UpdateGuildClick() end)
end
