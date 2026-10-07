local _, KHQOL = ...
local CastBar = KHQOL.modules.castBar
local function secret(value) return issecretvalue and issecretvalue(value) end
local function present(value) return secret(value) or value ~= nil end
local function number(value) return not secret(value) and type(value) == "number" end
local positions = { "inside_left", "inside_center", "inside_right", "outside_left", "outside_center", "outside_right" }
local fallback = { "inside_right", "outside_right", "inside_center", "outside_center", "inside_left", "outside_left" }
CastBar.positions = positions
CastBar.textures = {
  DEFAULT = "Interface\\TargetingFrame\\UI-StatusBar",
  FLAT = "Interface\\Buttons\\WHITE8X8",
  RAID = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill",
  SKILL = "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar",
}
CastBar.defaults = {
  appearance = { width=300, height=22, texture="DEFAULT", barColor={.95,.72,.2,1}, backgroundColor={.05,.05,.05,.85}, interruptedColor={.9,.15,.15,1} },
  icon = { enabled=true, position="left", size=22 },
  spellName = { enabled=true, position="inside_left", fontSize=12 },
  castTime = { enabled=true, position="inside_right", fontSize=12, format="remaining" },
  behavior = { direction="left_to_right", hideBlizzard=true },
  position = { mode="free", locked=true, free={point="CENTER",relativePoint="CENTER",x=0,y=-120}, resource={gap=4,matchWidth=true} },
}
local function oneOf(value, choices, default)
  for _, choice in ipairs(choices) do if value == choice then return value end end
  return default
end
local function clamp(value, lo, hi, default)
  if not number(value) or value ~= value or value == math.huge or value == -math.huge then value=default end
  return math.max(lo, math.min(hi, value))
end
function CastBar:ResolveTextPositionConflict(changedType, db)
  db = db or self.db
  if db.spellName.enabled and db.castTime.enabled and db.spellName.position == db.castTime.position then
    local keep = changedType == "castTime" and "castTime" or "spellName"
    local move = keep == "spellName" and "castTime" or "spellName"
    for _, id in ipairs(fallback) do
      if id ~= db[keep].position then db[move].position=id; break end
    end
  end
end
function CastBar:IsTextPositionAvailable(kind, id)
  local other = kind == "spellName" and self.db.castTime or self.db.spellName
  return not other.enabled or other.position ~= id
end
function CastBar:GetDB()
  local db = KHQOL.db.modules.castBar
  if type(db) ~= "table" then db={}; KHQOL.db.modules.castBar=db end
  KHQOL.MergeDefaults(db, self.defaults, "types")
  local a, p = db.appearance, db.position
  a.width=clamp(a.width,80,800,300); a.height=clamp(a.height,8,80,22)
  if not self.textures[a.texture] then a.texture="DEFAULT" end
  a.notInterruptibleColor=nil
  for _, key in ipairs({"barColor","backgroundColor","interruptedColor"}) do
    for i=1,4 do a[key][i]=clamp(a[key][i],0,1,self.defaults.appearance[key][i]) end
  end
  db.icon.position=oneOf(db.icon.position,{"left","right"},"left")
  db.icon.size=clamp(db.icon.size,8,80,22)
  for _, key in ipairs({"spellName","castTime"}) do
    db[key].position=oneOf(db[key].position,positions,self.defaults[key].position)
    db[key].fontSize=clamp(db[key].fontSize,8,32,12)
  end
  db.castTime.format=oneOf(db.castTime.format,{"remaining","total","remaining_total"},"remaining")
  db.behavior.direction=oneOf(db.behavior.direction,{"left_to_right","right_to_left"},"left_to_right")
  p.mode=oneOf(p.mode,{"free","resource_above","resource_below"},"free")
  local points={"CENTER","TOP","BOTTOM","LEFT","RIGHT","TOPLEFT","TOPRIGHT","BOTTOMLEFT","BOTTOMRIGHT"}
  p.free.point=oneOf(p.free.point,points,"CENTER"); p.free.relativePoint=oneOf(p.free.relativePoint,points,"CENTER")
  p.free.x=clamp(p.free.x,-3000,3000,0); p.free.y=clamp(p.free.y,-3000,3000,-120)
  p.resource.gap=clamp(p.resource.gap,0,20,4)
  self:ResolveTextPositionConflict(nil,db); self.db=db
  return db
end
function CastBar:IsEnabled() return KHQOL:GetEnabled("castBar") end
function CastBar:CreateBar()
  if self.frame then return end
  local frame=CreateFrame("Frame","KHQOLCastBarFrame",UIParent)
  frame:SetFrameStrata("MEDIUM"); frame:SetClampedToScreen(true); frame:SetMovable(true); frame:RegisterForDrag("LeftButton")
  local bar=CreateFrame("StatusBar",nil,frame); bar:SetMinMaxValues(0,1)
  local bg=bar:CreateTexture(nil,"BACKGROUND"); bg:SetAllPoints(bar); bg:SetTexture(self.textures.FLAT)
  local icon=frame:CreateTexture(nil,"ARTWORK"); icon:SetTexCoord(.07,.93,.07,.93)
  -- A sibling text layer stays above the status fill and icon.
  local textLayer=CreateFrame("Frame",nil,frame); textLayer:SetAllPoints(frame); textLayer:SetFrameLevel(bar:GetFrameLevel()+2)
  local name=textLayer:CreateFontString(nil,"OVERLAY","GameFontHighlight")
  name:SetWordWrap(false); name:SetNonSpaceWrap(false); name:SetMaxLines(1)
  local time=textLayer:CreateFontString(nil,"OVERLAY","GameFontHighlight")
  self.frame,self.bar,self.background,self.icon,self.nameText,self.timeText=frame,bar,bg,icon,name,time
  frame:SetScript("OnDragStart",function(f) if self:IsEnabled() and not self.db.position.locked and not self.linked then f:StartMoving() end end)
  frame:SetScript("OnDragStop",function(f)
    f:StopMovingOrSizing()
    if self.linked then return end
    local x,y=f:GetCenter(); local cx,cy=UIParent:GetCenter()
    if x and cx then
      local scale=f:GetEffectiveScale()/UIParent:GetEffectiveScale()
      local free=self.db.position.free
      free.point,free.relativePoint,free.x,free.y="CENTER","CENTER",x*scale-cx,y*scale-cy
      self:ApplyLayout(); self:RefreshControls()
    end
  end)
  self.updateCallback=function(_,elapsed) self:Tick(elapsed) end
  frame:SetScript("OnHide",function() frame:SetScript("OnUpdate",nil) end)
  frame:Hide()
end
function CastBar:AttachResource()
  local resource=KHQOLResourceSwingFrame
  if not resource or self.resource == resource then return end
  self.resource=resource
  for _, script in ipairs({"OnSizeChanged","OnShow","OnHide","OnDragStop"}) do
    resource:HookScript(script,function() if self.frame then self:ApplyLayout(); self:RefreshControls() end end)
  end
end
function CastBar:AnchorText(text, config)
  local outside=config.position:find("outside",1,true) == 1
  local side=config.position:match("_(%a+)$"):upper()
  local anchor=side == "CENTER" and (outside and "BOTTOM" or "CENTER") or (outside and "BOTTOM"..side or side)
  local relative=outside and (side == "CENTER" and "TOP" or "TOP"..side) or side
  text:ClearAllPoints(); text:SetPoint(anchor,self.bar,relative,side == "LEFT" and 4 or side == "RIGHT" and -4 or 0,outside and 3 or 0)
  text:SetJustifyH(side); text:SetFont((KHQOL.modules.clock and KHQOL.modules.clock.FONT_PATH) or STANDARD_TEXT_FONT,config.fontSize,"OUTLINE")
  text:SetShown(config.enabled)
end
function CastBar:ApplyLayout()
  if not self.frame then return end
  self:AttachResource()
  local db,a,p=self.db,self.db.appearance,self.db.position
  self.linked=p.mode ~= "free" and self.resource and self.resource:IsShown() and KHQOL:GetEnabled("resourceSwing") and (not KHQOLResourceSwingDB or KHQOLResourceSwingDB.enabled ~= false)
  local width=self.linked and p.resource.matchWidth and self.resource:GetWidth() or a.width
  local height=math.max(a.height,db.icon.enabled and db.icon.size or 0)
  self.frame:SetSize(width,height); self.frame:ClearAllPoints()
  if self.linked then
    local above=p.mode == "resource_above"
    self.frame:SetPoint(above and "BOTTOM" or "TOP",self.resource,above and "TOP" or "BOTTOM",0,above and p.resource.gap or -p.resource.gap)
  else local f=p.free; self.frame:SetPoint(f.point,UIParent,f.relativePoint,f.x,f.y) end
  self.frame:EnableMouse(not p.locked and not self.linked)
  local inset=db.icon.enabled and db.icon.size+2 or 0
  self.bar:ClearAllPoints(); self.bar:SetSize(math.max(1,width-inset),a.height)
  self.bar:SetPoint(db.icon.position == "left" and "RIGHT" or "LEFT",self.frame,db.icon.position == "left" and "RIGHT" or "LEFT",0,0)
  self.icon:ClearAllPoints(); self.icon:SetSize(db.icon.size,db.icon.size)
  self.icon:SetPoint(db.icon.position == "left" and "LEFT" or "RIGHT",self.frame,db.icon.position == "left" and "LEFT" or "RIGHT",0,0); self.icon:SetShown(db.icon.enabled)
  self.bar:SetStatusBarTexture(self.textures[a.texture]); self.bar:SetReverseFill(db.behavior.direction == "right_to_left")
  self.background:SetVertexColor(unpack(a.backgroundColor))
  self:AnchorText(self.nameText,db.spellName); self:AnchorText(self.timeText,db.castTime)
  if self.active and self.hideInteractionName then self.nameText:Hide() end
  local timeWidth=math.min(self.bar:GetWidth()*.45,db.castTime.fontSize*(db.castTime.format == "remaining_total" and 8 or 4))
  self.timeText:SetWidth(timeWidth)
  local sameBand=db.spellName.position:match("^(%a+)_") == db.castTime.position:match("^(%a+)_")
  local nameWidth=self.bar:GetWidth()-8
  if db.castTime.enabled and sameBand then
    if db.spellName.position:find("center",1,true) then nameWidth=self.bar:GetWidth()-2*(timeWidth+8)
    elseif db.castTime.position:find("center",1,true) then nameWidth=(self.bar:GetWidth()-timeWidth)/2-12
    else nameWidth=self.bar:GetWidth()-timeWidth-16 end
  end
  self.nameText:SetWidth(math.max(1,math.min(nameWidth,self.bar:GetWidth()*.65)))
  self:FitNameText()
  self:ApplyColor()
  if self.preview and not self.active then self:ShowPreview() end
end
function CastBar:SetNameText(value)
  -- Retain the original name so resizing never truncates an already-shortened name.
  self.displayName=value
  self:FitNameText()
end
function CastBar:FitNameText()
  if not self.nameText then return end
  local text=self.nameText
  local font=(KHQOL.modules.clock and KHQOL.modules.clock.FONT_PATH) or STANDARD_TEXT_FONT
  local size=self.db.spellName.fontSize
  local value=self.displayName
  text:SetFont(font,size,"OUTLINE")
  text:SetWordWrap(false); text:SetNonSpaceWrap(false); text:SetMaxLines(1)
  text:SetText(value)
  -- Protected text must remain in the native renderer; never inspect its bytes
  -- or branch on a protected measurement. The single-line width cap still applies.
  if secret(value) or type(value) ~= "string" or value == "" then return end
  local limit=math.max(1,math.min(text:GetWidth(),self.bar:GetWidth()*.65))
  local function measure(candidate)
    text:SetText(candidate)
    return text:GetUnboundedStringWidth()
  end
  local measured=measure(value)
  if not number(measured) then return end
  if measured <= limit then return end
  for reduction=1,2 do
    text:SetFont(font,math.max(6,size-reduction),"OUTLINE")
    measured=measure(value)
    if not number(measured) then return end
    if measured <= limit then return end
  end
  local ellipsis="…"
  local ellipsisWidth=measure(ellipsis)
  if not number(ellipsisWidth) then text:SetText(value); return end
  if ellipsisWidth > limit then text:SetText(""); return end
  -- UTF-8 character boundaries preserve Korean syllables and other multibyte names.
  local ends={}
  for i=1,#value do
    local nextByte=value:byte(i+1)
    if not nextByte or nextByte < 128 or nextByte >= 192 then ends[#ends+1]=i end
  end
  local low,high,best=0,#ends,""
  while low <= high do
    local mid=math.floor((low+high)/2)
    local prefix=mid == 0 and "" or value:sub(1,ends[mid])
    local width=measure(prefix..ellipsis)
    if not number(width) then text:SetText(value); return end
    if width <= limit then best=prefix; low=mid+1 else high=mid-1 end
  end
  text:SetText(best:gsub("%s+$","")..ellipsis)
end
function CastBar:ApplyColor()
  if not self.bar then return end
  local a=self.db.appearance
  local color=self.failed and a.interruptedColor or a.barColor
  self.bar:SetStatusBarColor(unpack(color))
end
function CastBar:UpdateTime(remaining,total)
  local format=self.db.castTime.format
  if format == "total" then self.timeText:SetFormattedText("%.1f",total)
  elseif format == "remaining_total" then self.timeText:SetFormattedText("%.1f / %.1f",remaining,total)
  else self.timeText:SetFormattedText("%.1f",remaining) end
end
function CastBar:Stop()
  self.generation=(self.generation or 0)+1
  self.active,self.failed,self.duration,self.startTime,self.endTime=nil,nil,nil,nil,nil
  self.hideInteractionName=nil
  self.nativeTimer=false; self.bar:SetMinMaxValues(0,1); self.bar:SetValue(0)
  self.frame:SetScript("OnUpdate",nil); self.frame:Hide()
  if self.preview and self:IsEnabled() then self:ShowPreview() end
end
function CastBar:ShowPreview()
  if not self.frame or self.active or not self.preview or not self:IsEnabled() then return end
  self.failed,self.notInterruptible=nil,nil
  self.hideInteractionName=nil; self.nameText:SetShown(self.db.spellName.enabled)
  self.bar:SetMinMaxValues(0,1); self.bar:SetValue(.55)
  self.icon:SetTexture("Interface\\Icons\\Spell_Fire_FlameBolt"); self:SetNameText("Fireball")
  self:UpdateTime(1.4,2.5); self:ApplyColor(); self.frame:SetScript("OnUpdate",nil); self.frame:Show()
end
function CastBar:SetPreview(on)
  self.preview=on and true or false
  if not self.active and not self.failed then if self.preview then self:ShowPreview() else self.frame:Hide() end end
end
function CastBar:IsOpeningCast(name,spellID,channel)
  -- Quest/world-object collection uses opening casts, not a learned combat
  -- skill. Never guess from the tooltip or hide ordinary gathering/channels.
  if channel then return false end
  if not secret(spellID) and (spellID==22810 or spellID==3365) then return true end
  if secret(name) or type(name)~="string" then return false end
  if name=="Opening - No Text" or name=="Opening" then return true end
  -- Localized clients may not expose the ID in UnitCastingInfo.
  for _,id in ipairs({22810,3365}) do
    local localized
    if C_Spell and type(C_Spell.GetSpellInfo)=="function" then
      local ok,info=pcall(C_Spell.GetSpellInfo,id)
      if ok and not secret(info) and type(info)=="table" then localized=info.name end
    elseif type(GetSpellInfo)=="function" then
      local ok,value=pcall(GetSpellInfo,id); if ok then localized=value end
    end
    if not secret(localized) and type(localized)=="string" and localized==name then return true end
  end
  return false
end
function CastBar:ReadCast(channel)
  local api=channel and UnitChannelInfo or UnitCastingInfo
  if type(api) ~= "function" then return end
  local name,display,texture,startMS,endMS,trade,castID,immune,spellID,barID,empowered
  if channel then
    local stages
    name,display,texture,startMS,endMS,trade,immune,spellID,empowered,stages,barID=api("player")
    if not secret(empowered) and empowered then return end
  else name,display,texture,startMS,endMS,trade,castID,immune,spellID,barID=api("player") end
  if not present(name) then return end
  return {name=name,texture=texture,startMS=startMS,endMS=endMS,castID=castID,barID=barID,immune=immune,channel=channel,hideName=self:IsOpeningCast(name,spellID,channel)}
end
function CastBar:Begin(info)
  if not info then return false end
  self.generation=(self.generation or 0)+1; self.failed=nil
  self.active=true; self.channel=info.channel; self.castID=info.castID; self.barID=info.barID
  self.hideInteractionName=info.hideName==true
  self.notInterruptible=not secret(info.immune) and info.immune == true
  self:SetNameText(self.hideInteractionName and "" or info.name); self.icon:SetTexture(info.texture)
  local durationAPI=info.channel and UnitChannelDuration or UnitCastingDuration
  self.duration=type(durationAPI) == "function" and durationAPI("player") or nil
  self.nativeTimer=false; self.startTime,self.endTime=nil,nil
  if self.duration and self.bar.SetTimerDuration and Enum and Enum.StatusBarTimerDirection then
    self.bar:SetTimerDuration(self.duration,Enum.StatusBarInterpolation.Immediate,info.channel and Enum.StatusBarTimerDirection.RemainingTime or Enum.StatusBarTimerDirection.ElapsedTime)
    self.nativeTimer=true
  elseif number(info.startMS) and number(info.endMS) and info.endMS > info.startMS then
    self.startTime,self.endTime=info.startMS/1000,info.endMS/1000
    self.bar:SetMinMaxValues(0,self.endTime-self.startTime)
  else
    -- Never guess a duration or perform arithmetic on protected timestamps.
    self.timingUnavailable=true; self.active=nil; self.frame:Hide(); self:ApplyBlizzard(); return false
  end
  self.timingUnavailable=nil; self:ApplyLayout(); self.frame:Show(); self:Tick(0)
  if self.active then self.frame:SetScript("OnUpdate",self.updateCallback) end
  self:ApplyBlizzard(); return true
end
function CastBar:Tick(elapsed)
  if not self.active then self.frame:SetScript("OnUpdate",nil); return end
  local remaining,total
  if self.nativeTimer then
    remaining,total=self.duration:GetRemainingDuration(),self.duration:GetTotalDuration()
  else
    total=self.endTime-self.startTime; remaining=math.max(0,self.endTime-GetTime())
    self.bar:SetValue(self.channel and remaining or math.min(total,math.max(0,GetTime()-self.startTime)))
  end
  -- Direct native formatting accepts secret numbers; no string.format, comparison
  -- or concatenation is performed on these values.
  self.textElapsed=(self.textElapsed or 0)+elapsed
  if elapsed == 0 or self.textElapsed >= .05 then self:UpdateTime(remaining,total); self.textElapsed=0 end
  if number(remaining) and remaining <= 0 then self:Stop() end
end
function CastBar:Matches(barID,castID)
  if present(barID) and present(self.barID) and not secret(barID) and not secret(self.barID) then return barID == self.barID end
  if present(castID) and present(self.castID) and not secret(castID) and not secret(self.castID) then return castID == self.castID end
  return true
end
function CastBar:Fail(label)
  if not self.active then return end
  self.active=nil; self.failed=true; self.duration=nil
  self.hideInteractionName=nil; self.nameText:SetShown(self.db.spellName.enabled)
  self.generation=(self.generation or 0)+1; local generation=self.generation
  self.frame:SetScript("OnUpdate",nil); self.bar:SetMinMaxValues(0,1); self.bar:SetValue(1)
  self:SetNameText(label); self.timeText:SetText(""); self:ApplyColor()
  C_Timer.After(.45,function() if self.generation == generation then self:Stop() end end)
end
function CastBar:Sync()
  if not self:IsEnabled() then return end
  local info=self:ReadCast(false) or self:ReadCast(true)
  if info then self:Begin(info) elseif not self.failed then self:Stop() end
end
function CastBar:QueueSync()
  -- Keep both the native deferred timing and the stale-callback guard. Each
  -- event retains its own callback; interrupt ordering must not be coalesced.
  local generation=self.generation
  C_Timer.After(0,function() if self.generation == generation and not self.failed then self:Sync() end end)
end
function CastBar:OnEvent(event,unit,castID,spellID,arg4,arg5)
  if event == "PLAYER_REGEN_ENABLED" then self:ApplyBlizzard(); return end
  if event == "PLAYER_ENTERING_WORLD" then self:AttachResource(); self:Sync(); self:ApplyBlizzard(); return end
  if not self:IsEnabled() or secret(unit) or unit ~= "player" then return end
  local channelStop=event == "UNIT_SPELLCAST_CHANNEL_STOP"
  local interrupted=event == "UNIT_SPELLCAST_INTERRUPTED"
  local barID
  if channelStop or interrupted then barID=arg5 else barID=arg4 end
  if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_DELAYED" then self:Begin(self:ReadCast(false)); return end
  if event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_CHANNEL_UPDATE" then self:Begin(self:ReadCast(true)); return end
  if event == "UNIT_SPELLCAST_INTERRUPTIBLE" or event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then
    if self.active then self.notInterruptible=event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE"; self:ApplyColor() end; return
  end
  if not self:Matches(barID,castID) then return end
  if interrupted or event == "UNIT_SPELLCAST_FAILED" then self:Fail(interrupted and "시전 중단" or "시전 실패")
  elseif channelStop then
    if self.channel and not self.failed then
      if not secret(arg4) and arg4 ~= nil then self:Fail("시전 중단") else self:Stop() end
    end
  elseif event == "UNIT_SPELLCAST_STOP" then
    if not self.channel and not self.failed then
      -- Some clients dispatch STOP before INTERRUPTED. Defer the hide by one
      -- tick so the failure event can preserve its brief status indication.
      self:QueueSync()
    end
  elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
    -- Channels can send SUCCEEDED at their start; STOP owns completion.
    if not self.channel and not self.failed then
      self:QueueSync()
    end
  end
end
function CastBar:ApplyBlizzard()
  if not self.frame then return end
  local bar=PlayerCastingBarFrame or CastingBarFrame
  if not bar then return end
  if not self.blizzardHooked or self.blizzardHooked ~= bar then
    self.blizzardHooked=bar
    bar:HookScript("OnShow",function() self:ApplyBlizzard() end)
  end
  -- No replacement methods, event removal, secure attributes, or reparenting.
  -- Protected frames are touched only outside combat; regen applies pending work.
  if InCombatLockdown() and bar:IsProtected() then self.blizzardPending=true; return end
  self.blizzardPending=nil
  local suppress=self:IsEnabled() and self.db.behavior.hideBlizzard and not self.timingUnavailable and (self.active or self.preview or (type(UnitCastingInfo) == "function" and type(UnitChannelInfo) == "function" and type(UnitCastingDuration) == "function" and self.bar.SetTimerDuration))
  if suppress then
    self.blizzardSuppressed=true; bar:Hide()
  elseif self.blizzardSuppressed then
    self.blizzardSuppressed=nil
    if bar.OnEvent then bar:OnEvent("PLAYER_ENTERING_WORLD") end
  end
end
function CastBar:RefreshControls()
  if self.controls then for _, control in ipairs(self.controls) do control:Refresh() end end
end
function CastBar:Changed(kind)
  self:ResolveTextPositionConflict(kind)
  self:ApplyLayout(); self:ApplyBlizzard(); self:RefreshControls()
  if self.active then self:Tick(0) end
end
function CastBar:ResetSettings()
  if KHQOL.settings then KHQOL.settings.castBarContent=nil end
  self:GetDB(); self:ApplyLayout(); self:ApplyBlizzard(); self:Sync()
end
function CastBar:Initialize()
  if self.initialized then return end
  self.initialized=true; self:GetDB(); self:CreateBar(); self:ApplyLayout()
  local events=CreateFrame("Frame"); self.events=events
  self.unsupportedEvents={}
  for _, event in ipairs({"UNIT_SPELLCAST_START","UNIT_SPELLCAST_DELAYED","UNIT_SPELLCAST_STOP","UNIT_SPELLCAST_SUCCEEDED","UNIT_SPELLCAST_INTERRUPTED","UNIT_SPELLCAST_FAILED","UNIT_SPELLCAST_CHANNEL_START","UNIT_SPELLCAST_CHANNEL_UPDATE","UNIT_SPELLCAST_CHANNEL_STOP","UNIT_SPELLCAST_INTERRUPTIBLE","UNIT_SPELLCAST_NOT_INTERRUPTIBLE"}) do
    if not pcall(events.RegisterUnitEvent,events,event,"player") then self.unsupportedEvents[#self.unsupportedEvents+1]=event end
  end
  events:RegisterEvent("PLAYER_ENTERING_WORLD"); events:RegisterEvent("PLAYER_REGEN_ENABLED")
  events:SetScript("OnEvent",function(_,...) self:OnEvent(...) end)
end
function CastBar:SetEnabled(enabled)
  self:Initialize()
  if enabled then self:Sync() else self.preview=false; self:Stop() end
  self:ApplyBlizzard()
end
