local _, KHQOL = ...
KHQOL = assert(_G.KHQOL, "Install and enable the KHQOL core addon.")
local M = {}; KHQOL.modules.generalConvenience = M
local call, public = KHQOL.PublicCall, KHQOL.IsPublicValue
M.defaults = {
  declineDuel=false, declineReport=true,
  allowFriends=true, allowGuild=true, keepTracking=false, trackingReport=false,
  merchantExpanded=false, knownItems=false, recipes=true, mounts=true, bags=true, merchant=true,
  equipmentLevels=true,
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
function M:GetTrackingStates()
  local key=KHQOL.profileCharacter or KHQOL:GetProfileCharacterKey()
  if not key then return {} end
  -- Reuse the existing personal-data store (Range spells / cursor color).
  -- Profile copies change options, never another character's tracking choice.
  KHQOL.db.globalData=KHQOL.db.globalData or {}
  local global=KHQOL.db.globalData
  global.profileCharacters=global.profileCharacters or {}
  global.profileCharacters[key]=global.profileCharacters[key] or {}
  local character=global.profileCharacters[key]
  character.gatherTracking=character.gatherTracking or {}
  return character.gatherTracking
end
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
function M:QueueInvite(kind,inviter,guild)
  if not self:InviteEnabled(kind) or not public(inviter) or type(inviter)~="string" or inviter=="" then return end
  if kind=="guild" and (not public(guild) or type(guild)~="string" or guild=="") then return end
  if kind=="party" and self:IsAllowedParty(inviter) then return end
  local general=KHQOL.modules.general
  general.inviteDeclines=general.inviteDeclines or {}
  local old=general.inviteDeclines[kind]
  if old and old.inviter==inviter and old.guildName==guild then return end
  general:CancelInviteDecline(kind)
  local pending={inviter=inviter,guildName=guild}; general.inviteDeclines[kind]=pending
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
    if not frame or call(frame.IsShown,frame)~=true then return end
    if kind=="guild" and (not public(frame.inviter) or frame.inviter~=inviter) then return end
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
    -- Retain the token until cancellation/end/new inviter to absorb duplicates.
  end
  self:Later(pending,0,attempt)
end
-- C_Minimap's public structure contains spellID and a per-index active boolean.
-- Resolve the localized names as well, since Camelot may report rank variants.
local gatherSpells={2383,2580}
function M:ReadTracking()
  if not C_Minimap or type(C_Minimap.GetTrackingInfo)~="function" or type(C_Minimap.SetTracking)~="function" then return end
  local count=call(C_Minimap.GetNumTrackingTypes); if not number(count) then return end
  local names={}
  for _,id in ipairs(gatherSpells) do
    local name=C_Spell and call(C_Spell.GetSpellName,id)
    if type(name)=="string" then names[name]=true end
  end
  local states,indices,other={},{},false
  for i=1,count do
    local info=call(C_Minimap.GetTrackingInfo,i)
    if type(info)~="table" or not public(info.active) or not public(info.name) or not public(info.spellID) then return end
    local id=info.spellID
    if id==2383 or id==2580 or names[info.name] then
      -- Presence in the native tracking list is the learned/available gate.
      local key=info.name; states[key]=info.active==true; indices[key]=i
    elseif info.active and number(id) and id>0 then other=true end
  end
  return states,indices,other
end
function M:RecordTracking(manual)
  if not self:IsEnabled() or not self:GetDB().keepTracking or self.restoring then return end
  if not manual and (self.trackingPending or call(UnitIsDeadOrGhost,"player")==true) then return end
  local states=self:ReadTracking(); if not states then return end
  local saved=self:GetTrackingStates()
  for key in pairs(saved) do saved[key]=nil end
  for key,value in pairs(states) do saved[key]=value end
  if manual then cancel(self.trackingPending); self.trackingPending=nil end
end
function M:StopTracking() cancel(self.trackingPending); self.trackingPending=nil; cancel(self.trackingRecord); self.trackingRecord=nil end
function M:TryRestoreTracking()
  local pending=self.trackingPending
  if not pending or not self:IsEnabled() or not self:GetDB().keepTracking then return end
  if self.worldLeaving or call(UnitIsDeadOrGhost,"player")==true or call(InCombatLockdown)==true or call(UnitCastingInfo,"player") or call(UnitChannelInfo,"player") then return end
  local states,indices,other=self:ReadTracking()
  if not states then return end
  -- A different spell-based track selected while waiting takes precedence.
  if other then self:RecordTracking(true); return end
  pending.attempts=pending.attempts+1
  self.restoring=true
  local changed=false
  for key,wanted in pairs(self:GetTrackingStates()) do
    if wanted==true and indices[key] and states[key]==false then
      local ok=pcall(C_Minimap.SetTracking,indices[key],true); changed=changed or ok
    end
  end
  self.restoring=false
  local after=self:ReadTracking(); local matches=after~=nil
  for key,wanted in pairs(self:GetTrackingStates()) do
    if wanted and indices[key] and (not after or after[key]~=true) then matches=false end
  end
  if matches then
    self.trackingPending=nil
    if changed and self:GetDB().trackingReport then self:Message("채집 추적 상태 복원") end
  elseif pending.attempts<3 then
    self:Later(pending,1,function() M:TryRestoreTracking() end)
  else self.trackingPending=nil end
end
function M:BeginRestoreTracking()
  if not self:IsEnabled() or not self:GetDB().keepTracking then return end
  if not self.trackingPending then self.trackingPending={attempts=0} end
  local pending=self.trackingPending
  if not pending.timer then self:Later(pending,.3,function() M:TryRestoreTracking() end) end
end
function M:ApplySettings()
  self:GetDB()
  for _,kind in ipairs({"party","guild","duel"}) do
    if not self:InviteEnabled(kind) then KHQOL.modules.general:CancelInviteDecline(kind) end
  end
  if not self:IsEnabled() or not self:GetDB().keepTracking then self:StopTracking()
  elseif not self.trackingWasEnabled then self:RecordTracking(true) end
  self.trackingWasEnabled=self:IsEnabled() and self:GetDB().keepTracking
  if self.ApplyMerchant then self:ApplyMerchant() end
  if self.RefreshKnownItems then self.knownCache={}; self:RefreshKnownItems() end
end
function M:SetEnabled(on)
  on=true -- Internal lifecycle only; each feature owns its switch.
  self:Initialize()
  self:StopTracking()
  -- Login/profile reapplication must not replace an existing saved selection.
  self.trackingWasEnabled=on and self:GetDB().keepTracking and next(self:GetTrackingStates())~=nil
  for _,kind in ipairs({"party","guild","duel"}) do KHQOL.modules.general:CancelInviteDecline(kind) end
  self.events:UnregisterAllEvents()
  if on then
    for _,event in ipairs({"FRIENDLIST_UPDATE","GUILD_ROSTER_UPDATE","DUEL_REQUESTED","DUEL_FINISHED","PLAYER_DEAD","PLAYER_ALIVE","PLAYER_UNGHOST","PLAYER_LEAVING_WORLD","PLAYER_ENTERING_WORLD","MINIMAP_UPDATE_TRACKING","PLAYER_REGEN_ENABLED","UNIT_SPELLCAST_STOP","UNIT_SPELLCAST_SUCCEEDED","MERCHANT_SHOW","MERCHANT_CLOSED","MERCHANT_UPDATE","BAG_UPDATE_DELAYED","GET_ITEM_INFO_RECEIVED","SPELLS_CHANGED","NEW_MOUNT_ADDED","COMPANION_LEARNED","SKILL_LINES_CHANGED"}) do
      pcall(self.events.RegisterEvent,self.events,event)
    end
  end
  self:ApplySettings()
  if not on and self.merchantPending then self.events:RegisterEvent("PLAYER_REGEN_ENABLED") end
  if self.trackingWasEnabled then self:BeginRestoreTracking() end
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
    elseif event=="PLAYER_DEAD" then M:BeginRestoreTracking()
    elseif event=="PLAYER_ALIVE" or event=="PLAYER_UNGHOST" then M:BeginRestoreTracking()
    elseif event=="PLAYER_LEAVING_WORLD" then M.worldLeaving=true; M:BeginRestoreTracking()
    elseif event=="MINIMAP_UPDATE_TRACKING" then
      if M.trackingPending and not M.restoring and call(UnitIsDeadOrGhost,"player")==false then
        local states,indices,other=M:ReadTracking()
        local changed=other
        for key,active in pairs(states or {}) do if active and M:GetTrackingStates()[key]~=true then changed=true end end
        if changed then M:RecordTracking(true) end
      else M:RecordTracking() end
    elseif event=="PLAYER_REGEN_ENABLED" or event=="UNIT_SPELLCAST_STOP" then M:TryRestoreTracking(); if M.ApplyMerchant then M:ApplyMerchant() end
    elseif event=="UNIT_SPELLCAST_SUCCEEDED" and arg=="player" then
      local states=M:ReadTracking()
      local name=C_Spell and call(C_Spell.GetSpellName,spellID)
      if states and name and states[name]~=nil then
        cancel(M.trackingRecord); M.trackingRecord={}
        M:Later(M.trackingRecord,0,function() M:RecordTracking(true) end)
      end
    elseif event=="PLAYER_ENTERING_WORLD" then
      M.worldLeaving=nil; M.knownCache={}; if next(M:GetTrackingStates()) then M:BeginRestoreTracking() else M:RecordTracking() end
    elseif event=="MERCHANT_SHOW" then if M.ApplyMerchant then M:ApplyMerchant() end
    elseif event=="MERCHANT_CLOSED" then
      KHQOL.modules.general:CloseMerchantWork()
    else M.knownCache={} end
    if M.RefreshKnownItems then M:RefreshKnownItems() end
  end)
  if C_Minimap then
    local function selectionChanged()
      if not M:IsEnabled() or not M:GetDB().keepTracking or M.restoring then return end
      -- Explicit SetTracking also catches a manual OFF while resurrection waits.
      cancel(M.trackingRecord); M.trackingRecord={}
      M:Later(M.trackingRecord,0,function() M:RecordTracking(true) end)
    end
    for _,key in ipairs({"SetTracking","ClearAllTracking"}) do
      if type(C_Minimap[key])=="function" then hooksecurefunc(C_Minimap,key,selectionChanged) end
    end
  end
end
