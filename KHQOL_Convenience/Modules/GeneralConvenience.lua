local _, KHQOL = ...
KHQOL = assert(_G.KHQOL, "Install and enable the KHQOL core addon.")
local M = {}; KHQOL.modules.generalConvenience = M
local call, public = KHQOL.PublicCall, KHQOL.IsPublicValue
M.defaults = {
  declineDuel=false, declineReport=true,
  allowFriends=true, allowGuild=true,
  merchantExpanded=false, knownItems=false, recipes=true, mounts=true, bags=true, merchant=true,
  equipmentLevels=true,questRewardBestPrice=false,
}
function M:GetDB()
  local old=KHQOL.db.modules.generalConvenience
  if old and old.declineReport==nil and (old.duelReport~=nil or old.partyReport~=nil or old.guildReport~=nil) then
    old.declineReport=old.duelReport~=false or old.partyReport~=false or old.guildReport~=false
  end
  if old then old.duelReport=nil; old.partyReport=nil; old.guildReport=nil end
  KHQOL.db.modules.generalConvenience=KHQOL.MergeDefaults(KHQOL.db.modules.generalConvenience or {},self.defaults,"tables")
  return KHQOL.db.modules.generalConvenience
end
function M:IsEnabled() return KHQOL.db~=nil end
function M:Message(text) if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("[KHQOL] "..text) end end
local function number(v) return public(v) and type(v)=="number" and v==v and v>=0 and v<math.huge end
M.IsNumber=number
local function cancel(owner)
  if owner and owner.timer and owner.timer.Cancel then owner.timer:Cancel() end
  if owner then owner.cancelled=true end
end
function M:Later(owner,delay,fn)
  if C_Timer and C_Timer.NewTimer then
    owner.timer=C_Timer.NewTimer(delay,function() owner.timer=nil; if not owner.cancelled then fn() end end)
  end
end
local function normalized(name)
  if not public(name) or type(name)~="string" then return end
  local n,r=name:match("^([^%-]+)%-(.+)$")
  n=n or name; r=r or call(GetRealmName)
  if type(r)~="string" then return end
  return n:lower().."-"..r:gsub("%s",""):lower()
end
function M:IsAllowedParty(inviter)
  local db=self:GetDB(); local wanted=normalized(inviter)
  if not wanted then return false end
  local incomplete=false
  -- Character friends only. Battle.net identities are deliberately not guessed.
  if db.allowFriends and C_FriendList then
    local count=call(C_FriendList.GetNumFriends)
    if number(count) then
      if count==0 and not self.friendsReady then incomplete=true end
      for i=1,count do
        local info=call(C_FriendList.GetFriendInfoByIndex,i)
        if type(info)=="table" and normalized(info.name)==wanted then return true end
        if type(info)~="table" or not normalized(info.name) then incomplete=true end
      end
    else incomplete=true end
  elseif db.allowFriends then incomplete=true
  end
  if db.allowGuild and call(IsInGuild)~=false then
    local count=call(GetNumGuildMembers)
    if number(count) then
      if count==0 and not self.guildReady then incomplete=true end
      for i=1,count do
        local name=normalized(call(GetGuildRosterInfo,i))
        if name==wanted then return true end
        if not name then incomplete=true end
      end
    else incomplete=true end
  end
  if incomplete then return nil end
  return false
end
local inviteKeys={party="declinePartyInvites",guild="declineGuildInvites"}
local dialogs={party="PARTY_INVITE",duel="DUEL_REQUESTED"}
-- All request kinds share declineReport.
function M:InviteEnabled(kind)
  return self:IsEnabled() and (kind=="duel" and self:GetDB().declineDuel or
    kind~="duel" and KHQOL.modules.general:GetDB()[inviteKeys[kind]]==true)
end
function M:WatchGuildInviteFrame()
  local frame=_G.GuildInviteFrame
  if frame and self.guildInviteFrame~=frame then
    self.guildInviteFrame=frame
    self.guildInviteRevision=(self.guildInviteRevision or 0)+1
    local function change()
      if self.guildInviteFrame==frame then self.guildInviteRevision=self.guildInviteRevision+1 end
    end
    frame:HookScript("OnShow",change);frame:HookScript("OnHide",change)
  end
  return frame
end
function M:QueueInvite(kind,inviter,guild)
  if not self:InviteEnabled(kind) or not public(inviter) or type(inviter)~="string" or inviter=="" then return end
  if kind=="guild" and (not public(guild) or type(guild)~="string" or guild=="") then return end
  if kind=="party" and self:IsAllowedParty(inviter) then return end
  local general=KHQOL.modules.general
  general.inviteDeclines=general.inviteDeclines or {}
  local old=general.inviteDeclines[kind]
  local frame=kind=="guild" and self:WatchGuildInviteFrame()
  local revision=frame and self.guildInviteRevision
  if old and old.inviter==inviter and old.guildName==guild
    and (kind~="guild" or (not old.completed and old.revision==revision)) then return end
  general:CancelInviteDecline(kind)
  local matching=frame and call(frame.IsShown,frame)==true and public(frame.inviter) and frame.inviter==inviter
  local pending={inviter=inviter,guildName=guild,revision=revision,wasVisible=matching}
  general.inviteDeclines[kind]=pending
  local function attempt()
    if general.inviteDeclines[kind]~=pending or not M:InviteEnabled(kind) then return end
    if kind=="party" then
      local allowed=M:IsAllowedParty(inviter)
      if allowed==true then return end
      if allowed==nil then
        pending.attempts=(pending.attempts or 0)+1
        if pending.attempts<=3 then
          if C_FriendList then call(C_FriendList.ShowFriends) end
          if C_GuildInfo then call(C_GuildInfo.GuildRoster) end
          M:Later(pending,1,attempt)
        end
        return -- Preserve an invite rather than guess an exception failure.
      end
    end
    local frame=kind=="guild" and _G.GuildInviteFrame or call(StaticPopup_FindVisible,dialogs[kind])
    -- An event without a live native request is insufficient authorization.
    -- Native blocking settings, LFG and queues never generate synthetic notices.
    if not frame or call(frame.IsShown,frame)~=true then
      if kind=="guild" then general:CancelInviteDecline(kind) end
      return
    end
    if kind=="guild" and (not public(frame.inviter) or frame.inviter~=inviter
      or (pending.wasVisible and pending.revision~=M.guildInviteRevision)
      or (type(frame.guildName)=="string" and not public(frame.guildName))
      or (type(frame.guildName)=="string" and frame.guildName~=guild)) then
      general:CancelInviteDecline(kind);return
    end
    local accepted=kind=="party" and frame.inviteAccepted or kind=="guild" and frame.accepted
    if not public(accepted) or accepted then return end
    local fn=kind=="party" and DeclineGroup or kind=="guild" and DeclineGuild or CancelDuel
    if type(fn)~="function" then return end
    local ok
    if kind=="duel" then
      ok=pcall(fn); if ok then pcall(StaticPopup_Hide,dialogs[kind]) end
    elseif type(call(frame.GetScript,frame,"OnHide"))=="function" then
      -- PARTY_INVITE/GuildInviteFrame OnHide is the one native decline path.
      ok=pcall(frame.Hide,frame)
    end
    if ok and call(frame.IsShown,frame)==false then
      pending.completed=true
      if M:GetDB().declineReport then M:Message(({party="파티",guild="길드",duel="결투"})[kind].." 요청 거절: "..inviter) end
    end
    -- Keep the pending token across duplicate events before the popup closes.
    -- A completed guild token never suppresses another invitation.
  end
  self:Later(pending,0,attempt)
end
function M:ApplySettings()
  self:GetDB()
  self.partyControl:Configure()
  self.buffThanks:Configure()
  self:RefreshQuestRewardPrices()
  for _,kind in ipairs({"party","guild","duel"}) do
    if not self:InviteEnabled(kind) then KHQOL.modules.general:CancelInviteDecline(kind) end
  end
  if self.ApplyMerchant then self:ApplyMerchant() end
  if self.RefreshKnownItems then self.knownCache={}; self:RefreshKnownItems() end
end
function M:SetEnabled(on)
  on=true -- Internal lifecycle only; each feature owns its switch.
  self:Initialize()
  self:InitializeBagProtection()
  self:InitializeBagTrash()
  for _,kind in ipairs({"party","guild","duel"}) do KHQOL.modules.general:CancelInviteDecline(kind) end
  self.events:UnregisterAllEvents()
  if on then
    for _,event in ipairs({"FRIENDLIST_UPDATE","GUILD_ROSTER_UPDATE","DUEL_REQUESTED","DUEL_FINISHED","PLAYER_REGEN_ENABLED","MERCHANT_SHOW","MERCHANT_CLOSED","MERCHANT_UPDATE","BAG_UPDATE_DELAYED","GET_ITEM_INFO_RECEIVED","SPELLS_CHANGED","NEW_MOUNT_ADDED","COMPANION_LEARNED","SKILL_LINES_CHANGED"}) do
      pcall(self.events.RegisterEvent,self.events,event)
    end
  end
  self:ApplySettings()
  self:RefreshBagTrash()
  if not on and self.merchantPending then self.events:RegisterEvent("PLAYER_REGEN_ENABLED") end
end
function M:Initialize()
  if self.events then return end
  self.events=CreateFrame("Frame")
  self.events:SetScript("OnEvent",function(_,event,arg,castGUID,spellID)
    if event=="PLAYER_REGEN_ENABLED" and not M:IsEnabled() and M.merchantPending then
      M:ApplyMerchant(); M.events:UnregisterEvent("PLAYER_REGEN_ENABLED"); return
    end
    if not M:IsEnabled() then return end
    if event=="FRIENDLIST_UPDATE" then M.friendsReady=true
    elseif event=="GUILD_ROSTER_UPDATE" then M.guildReady=true
    elseif event=="DUEL_REQUESTED" then M:QueueInvite("duel",arg)
    elseif event=="DUEL_FINISHED" then KHQOL.modules.general:CancelInviteDecline("duel")
    elseif event=="PLAYER_REGEN_ENABLED" then if M.ApplyMerchant then M:ApplyMerchant() end
    elseif event=="MERCHANT_SHOW" then if M.ApplyMerchant then M:ApplyMerchant() end
    elseif event=="MERCHANT_CLOSED" then
      KHQOL.modules.general:CloseMerchantWork()
    else M.knownCache={} end
    if M.RefreshKnownItems then M:RefreshKnownItems() end
  end)
end
