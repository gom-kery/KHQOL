local _, KHQOL = ...
local X=KHQOL.modules.experienceBar
local flat="Interface\\Buttons\\WHITE8X8"
X.defaults={
  hideBlizzard=false,mode="horizontal",width=360,height=20,x=0,y=-220,scale=1,alpha=1,
  showLevel=true,showText=true,textMode="currentMaxPercent",textPosition="center",
  showRested=true,tooltip=true,hideAtMaxLevel=true,followReputation=false,
  color={.58,0,.55,1},backgroundColor={.04,.04,.06,.85},restedColor={0,.39,.88,.7},textColor={1,1,1,1},
  wrapHorizontalLength=220,wrapVerticalLength=48,wrapThickness=6,wrapOffset=4,wrapX=0,wrapY=0,
}
local function number(v)
  return not (issecretvalue and issecretvalue(v)) and type(v)=="number" and v==v and v~=math.huge and v~=-math.huge
end
local function clamp(v,lo,hi) return math.max(lo,math.min(hi,v)) end
local function read(fn,...)
  if type(fn)~="function" then return nil end
  local ok,v=pcall(fn,...); if ok then return v end
end
function X:GetDB()
  local db=KHQOL.db.modules.experienceBar
  if type(db)~="table" then db={}; KHQOL.db.modules.experienceBar=db end
  KHQOL.MergeDefaults(db,self.defaults,"types")
  local limits={width={120,1200},height={8,80},x={-3000,3000},y={-3000,3000},scale={.5,2},alpha={.1,1},
    wrapHorizontalLength={160,600},wrapVerticalLength={16,180},wrapThickness={2,16},wrapOffset={0,60},wrapX={-500,500},wrapY={-500,500}}
  for key,bounds in pairs(limits) do db[key]=clamp(number(db[key]) and db[key] or self.defaults[key],bounds[1],bounds[2]) end
  for _,key in ipairs({"color","backgroundColor","restedColor","textColor"}) do
    for i=1,4 do db[key][i]=clamp(number(db[key][i]) and db[key][i] or self.defaults[key][i],0,1) end
  end
  if db.mode~="horizontal" and db.mode~="wrapTop" and db.mode~="wrapBottom" then db.mode="horizontal" end
  local formats={percent=true,currentMax=true,remaining=true,currentMaxPercent=true}
  if not formats[db.textMode] then db.textMode="currentMaxPercent" end
  if db.textPosition~="left" and db.textPosition~="right" and db.textPosition~="center" then db.textPosition="center" end
  self.db=db; return db
end
function X:IsEnabled() return KHQOL.db and KHQOL:GetEnabled("experienceBar") end
function X:FormatNumber(value)
  local s=tostring(math.floor(value+.5)); local k
  repeat s,k=s:gsub("^(%d+)(%d%d%d)","%1,%2") until k==0
  return s
end
function X:GetCap()
  local rules=GameRulesUtil and GameRulesUtil.GetEffectiveMaxLevelForPlayer
  for _,fn in ipairs({rules or false,GetMaxPlayerLevel or false,GetMaxLevelForPlayerExpansion or false}) do
    local v=read(fn); if number(v) and v>0 then return v end
  end
  if number(MAX_PLAYER_LEVEL) and MAX_PLAYER_LEVEL>0 then return MAX_PLAYER_LEVEL end
  if type(MAX_PLAYER_LEVEL_TABLE)=="table" then
    local expansion=read(GetExpansionLevel)
    local cap=number(expansion) and MAX_PLAYER_LEVEL_TABLE[expansion]
    if number(cap) and cap>0 then return cap end
  end
end
function X:ReadReputation()
  if not self.db or not self.db.followReputation then return end
  local name,reaction,minimum,maximum,value
  if C_Reputation and type(C_Reputation.GetWatchedFactionData)=="function" then
    local d=read(C_Reputation.GetWatchedFactionData)
    if type(d)~="table" then return end
    name,reaction=d.name,d.reaction
    minimum,maximum,value=d.currentReactionThreshold,d.nextReactionThreshold,d.currentStanding
  elseif type(GetWatchedFactionInfo)=="function" then
    local ok
    ok,name,reaction,minimum,maximum,value=pcall(GetWatchedFactionInfo)
    if not ok then return end
  else return end
  if (issecretvalue and issecretvalue(name)) or type(name)~="string" or name==""
    or not number(reaction) or not number(minimum) or not number(maximum) or not number(value) or maximum<minimum then return end
  -- Reputation totals can start below zero or include previous standing tiers.
  -- Display progress within the current tier, just like the native bar.
  local span=maximum-minimum
  if span==0 and reaction<8 then return end
  value=span>0 and clamp(value-minimum,0,span) or 0
  maximum=span
  local standing=_G["FACTION_STANDING_LABEL"..reaction] or "평판"
  return {kind="reputation",name=name,standing=standing,value=value,maximum=maximum,
    remaining=maximum-value,percent=span>0 and value/span*100 or 100,
    rested=0,atCap=false,capped=span==0,highestStanding=reaction>=8}
end
function X:ReadData(newLevel)
  local reputation=self:ReadReputation()
  if reputation then self.data=reputation; return end
  local level=read(UnitLevel,"player")
  if number(newLevel) then level=newLevel end
  local value,maximum=read(UnitXP,"player"),read(UnitXPMax,"player")
  if not number(level) or level<1 or not number(value) or not number(maximum) or maximum<0 then self.data=nil; return end
  local rested=read(GetXPExhaustion)
  rested=number(rested) and math.max(0,rested) or 0
  local cap=self:GetCap()
  local atCap=read(IsPlayerAtEffectiveMaxLevel)==true or (cap and level>=cap) or maximum==0
  value=clamp(value,0,maximum)
  self.data={kind="experience",level=level,value=value,maximum=maximum,remaining=maximum-value,
    percent=maximum>0 and value/maximum*100 or 0,rested=rested,atCap=atCap and true or false}
end
function X:Text()
  local d,db=self.data,self.db
  if not d then return "" end
  if d.atCap then return "최대 레벨" end
  if d.kind=="reputation" and d.capped then return d.name.." · "..d.standing end
  local prefix=d.kind=="reputation" and (d.name.." · ") or ""
  local percent=string.format("%.1f%%",d.percent)
  if db.textMode=="percent" then return prefix..percent end
  if db.textMode=="remaining" then return prefix..self:FormatNumber(d.remaining).." 남음" end
  local result=self:FormatNumber(d.value).." / "..self:FormatNumber(d.maximum)
  return prefix..(db.textMode=="currentMaxPercent" and result.." ("..percent..")" or result)
end
-- Change only XP presentation; leave action bars, reputation and visibility
-- policies under Blizzard's control. Restore only state owned by this module.
function X:SyncNativeFrame(f)
  if self.nativeGuard then return end
  self.nativeGuard=true
  local saved=self.native[f]
  local container=self.nativeContainers and self.nativeContainers[f]
  local owns=not container or self:IsXPContainer(container)
  if self.db.hideBlizzard and owns then
    if not saved then
      saved={alpha=f:GetAlpha(),mouse=f.IsMouseEnabled and f:IsMouseEnabled(),
        click=f.IsMouseClickEnabled and f:IsMouseClickEnabled(),motion=f.IsMouseMotionEnabled and f:IsMouseMotionEnabled()}
      self.native[f]=saved
    end
    f:SetAlpha(0); if f.EnableMouse then f:EnableMouse(false) end
  elseif saved then
    self.native[f]=nil; f:SetAlpha(saved.alpha); if f.EnableMouse then f:EnableMouse(saved.mouse) end
    if f.SetMouseClickEnabled and saved.click~=nil then f:SetMouseClickEnabled(saved.click) end
    if f.SetMouseMotionEnabled and saved.motion~=nil then f:SetMouseMotionEnabled(saved.motion) end
  end
  self.nativeGuard=nil
end
function X:AttachNative(f,container)
  if not f then return end
  if container then self.nativeContainers[f]=container end
  if not self.hooked[f] then
    self.hooked[f]=true
    -- Regions can expose HookScript without supporting frame-only scripts.
    if f.HookScript and f.HasScript then
      if f:HasScript("OnShow") then f:HookScript("OnShow",function(frame) self:SyncNativeFrame(frame) end) end
      if f:HasScript("OnEvent") then f:HookScript("OnEvent",function(frame) self:SyncNativeFrame(frame) end) end
    end
    if hooksecurefunc then hooksecurefunc(f,"SetAlpha",function(frame) self:SyncNativeFrame(frame) end) end
  end
  if container and f.GetRegions then
    for _,region in ipairs({f:GetRegions()}) do self:AttachNative(region,container) end
  end
  if f.GetChildren then for _,child in ipairs({f:GetChildren()}) do self:AttachNative(child,container) end end
end
function X:IsXPBar(bar)
  if not bar then return false end
  if self.xpFrames[bar] then return true end
  local enum=StatusTrackingBarInfo and StatusTrackingBarInfo.BarsEnum
  if enum and enum.Experience and bar.barIndex==enum.Experience then return true end
  return ExpBarMixin and ExpBarMixin.GetLevelData and bar.GetLevelData==ExpBarMixin.GetLevelData or false
end
function X:IsXPContainer(container)
  local bar=read(container.GetShownBar,container)
  if bar then return self:IsXPBar(bar) end
  local enum=StatusTrackingBarInfo and StatusTrackingBarInfo.BarsEnum
  if enum and enum.Experience and container.shownBarIndex~=nil then return container.shownBarIndex==enum.Experience end
  -- Some variants put the outer artwork on the manager. Suppress that shared
  -- art only when every visible tracking bar belongs to XP.
  local xp=false
  for _,candidate in pairs(container.bars or {}) do
    if candidate.IsShown and candidate:IsShown() then
      if not self:IsXPBar(candidate) then return false end
      xp=true
    end
  end
  for _,child in ipairs(container.barContainers or {}) do
    if child.IsShown and child:IsShown() then
      if not self:IsXPContainer(child) then return false end
      xp=true
    end
  end
  return xp
end
function X:AttachTracking(container)
  if not container then return end
  self:AttachNative(container.ExperienceBar)
  if container.ExperienceBar then self.xpFrames[container.ExperienceBar]=true end
  for _,bar in pairs(container.bars or {}) do
    if self:IsXPBar(bar) then self.xpFrames[bar]=true; self:AttachNative(bar) end
  end
  local bar=read(container.GetBarFromTemplate,container,"ExpStatusBarTemplate")
  if bar then self.xpFrames[bar]=true; self:AttachNative(bar) end
  for _,key in ipairs({"MainMenuBarTextures","StandaloneTextures"}) do
    for _,region in ipairs(container[key] or {}) do self:AttachNative(region,container) end
  end
  -- Client variants keep their border/background outside the named art arrays,
  -- directly on the container or in decoration child frames. Hide those regions
  -- only while this container presents XP, without touching its alpha/fades.
  if container.GetRegions then
    for _,region in ipairs({container:GetRegions()}) do self:AttachNative(region,container) end
  end
  if container.GetChildren then
    local bars={}
    for _,candidate in pairs(container.bars or {}) do bars[candidate]=true end
    for _,child in ipairs({container:GetChildren()}) do
      if not bars[child] and not self:IsXPBar(child) and not child.bars and not child.barContainers then
        self:AttachNative(child,container)
      end
    end
  end
  if not self.trackingHooked[container] then
    self.trackingHooked[container]=true
    if container.HookScript and container.HasScript then
      if container:HasScript("OnShow") then container:HookScript("OnShow",function() self:SyncNative() end) end
      if container:HasScript("OnEvent") then container:HookScript("OnEvent",function() self:SyncNative() end) end
    end
    if hooksecurefunc then
      for _,method in ipairs({"UpdateBarsShown","InitializeBars","ApplyPendingBarToShow","SetShownBar","UpdateShownState","UseMainMenuBarArt"}) do
        if type(container[method])=="function" then hooksecurefunc(container,method,function() self:SyncNative() end) end
      end
    end
  end
end
function X:SyncNative()
  for _,name in ipairs({"MainMenuExpBar","MainMenuBarExpBar","ExperienceBar","ExhaustionTick"}) do self:AttachNative(_G[name]) end
  -- XP bars may be anonymous entries in a shared tracking container. Never
  -- suppress that container itself: reputation can reuse it after XP hides.
  for _,name in ipairs({"StatusTrackingBarManager","MainStatusTrackingBarContainer","SecondaryStatusTrackingBarContainer"}) do
    local container=_G[name]
    self:AttachTracking(container)
    if container then for _,child in ipairs(container.barContainers or {}) do self:AttachTracking(child) end end
  end
  for f in pairs(self.hooked) do self:SyncNativeFrame(f) end
end
function X:HideTooltip()
  if self.tooltipOwner and GameTooltip and GameTooltip:IsOwned(self.tooltipOwner) then GameTooltip:Hide() end
  self.tooltipOwner=nil
end
function X:ShowTooltip(owner)
  if not self.db.tooltip or self.unlocked or not self.data or not self.frame:IsShown() then return end
  local d=self.data; self.tooltipOwner=owner
  GameTooltip:SetOwner(owner,"ANCHOR_RIGHT")
  if d.kind=="reputation" then
    GameTooltip:SetText("평판 · "..d.name)
    GameTooltip:AddDoubleLine("평판 단계",d.standing)
    if not d.capped then GameTooltip:AddDoubleLine("현재 평판",self:FormatNumber(d.value).." / "..self:FormatNumber(d.maximum)) end
    GameTooltip:AddDoubleLine("진행률",string.format("%.1f%%",d.percent))
    if not d.capped then GameTooltip:AddDoubleLine(d.highestStanding and "최대 평판까지" or "다음 단계까지",self:FormatNumber(d.remaining)) end
  elseif d.atCap then GameTooltip:SetText("경험치 · Lv."..d.level); GameTooltip:AddLine("최대 레벨",1,1,1)
  else
    GameTooltip:SetText("경험치 · Lv."..d.level)
    GameTooltip:AddDoubleLine("현재 경험치",self:FormatNumber(d.value).." / "..self:FormatNumber(d.maximum))
    GameTooltip:AddDoubleLine("진행률",string.format("%.1f%%",d.percent))
    GameTooltip:AddDoubleLine("다음 레벨까지",self:FormatNumber(d.remaining))
    if d.rested>0 then GameTooltip:AddDoubleLine("휴식 경험치",self:FormatNumber(d.rested)) end
  end
  GameTooltip:Show()
end
function X:Mouse(frame,drag)
  frame:EnableMouse(drag and true or false)
  if frame.SetMouseClickEnabled and frame.SetMouseMotionEnabled then
    frame:SetMouseClickEnabled(drag and true or false)
    frame:SetMouseMotionEnabled(drag or self.db.tooltip)
  elseif frame.SetPropagateMouseClicks then
    frame:EnableMouse(drag or self.db.tooltip); frame:SetPropagateMouseClicks(not drag)
  end
  -- On older clients without click-through hover, gameplay input takes priority.
end
function X:WatchReputationSelection()
  if not hooksecurefunc then return end
  self.reputationHooks=self.reputationHooks or {}
  local function attach(owner,key)
    if not owner or type(owner[key])~="function" then return end
    local hooks=self.reputationHooks[owner]
    if not hooks then hooks={}; self.reputationHooks[owner]=hooks end
    if hooks[key] then return end
    hooks[key]=true
    -- Watching/unwatching need not change reputation points. Refresh after the
    -- native setter as well as UPDATE_FACTION, without modifying its selection.
    hooksecurefunc(owner,key,function() if self.db and self.frame then self:Update() end end)
  end
  attach(C_Reputation,"SetWatchedFactionByIndex"); attach(C_Reputation,"SetWatchedFactionByID")
  attach(_G,"SetWatchedFactionIndex")
end
function X:CreateFrames()
  self:WatchReputationSelection()
  if self.frame then return end
  self.native={}; self.hooked={}; self.nativeContainers={}; self.xpFrames={}; self.trackingHooked={}
  local f=CreateFrame("Frame","KHQOLExperienceBarFrame",UIParent)
  self.frame=f; self.segments={}
  f:SetFrameStrata("MEDIUM"); f:SetMovable(true); f:SetClampedToScreen(true); f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart",function(frame)
    if self.unlocked and self.db.mode=="horizontal" then self.dragging=true; self:HideTooltip(); frame:StartMoving() end
  end)
  f:SetScript("OnDragStop",function() self:SavePosition() end)
  f:SetScript("OnHide",function() self:HideTooltip() end)
  for i=1,2 do
    local s=CreateFrame("StatusBar",nil,f); s:SetStatusBarTexture(flat)
    s.bg=s:CreateTexture(nil,"BACKGROUND"); s.bg:SetAllPoints(); s.bg:SetTexture(flat)
    s.rested=s:CreateTexture(nil,"OVERLAY"); s.rested:SetTexture(flat)
    s:SetScript("OnEnter",function(owner) self:ShowTooltip(owner) end)
    s:SetScript("OnLeave",function() self:HideTooltip() end)
    self.segments[i]=s
  end
  -- Nine markers split the continuous XP path into ten equal blocks. Their
  -- layer sits above fills/rested XP, below the separate text frame.
  local markers=CreateFrame("Frame",nil,f); markers:SetAllPoints(f)
  markers:SetFrameLevel(self.segments[1]:GetFrameLevel()+1); markers:EnableMouse(false)
  self.markers={}
  for i=1,9 do
    local texture=markers:CreateTexture(nil,"ARTWORK"); texture:SetTexture(flat)
    texture:SetVertexColor(.12,.10,.08,1); self.markers[i]=texture
  end
  local layer=CreateFrame("Frame",nil,f); layer:SetAllPoints(f); layer:SetFrameLevel(self.segments[1]:GetFrameLevel()+3); layer:EnableMouse(false)
  self.levelText=layer:CreateFontString(nil,"OVERLAY","GameFontHighlight")
  self.xpText=layer:CreateFontString(nil,"OVERLAY","GameFontHighlight")
  for _,text in ipairs({self.levelText,self.xpText}) do
    text:SetFont(KHQOL.UI:Font(),13,"OUTLINE"); text:SetWordWrap(false); text:SetNonSpaceWrap(false); text:SetMaxLines(1)
  end
  self.guide=layer:CreateFontString(nil,"OVERLAY","GameFontHighlight"); self.guide:SetPoint("BOTTOM",f,"TOP",0,12)
  self.guide:SetText("경험치 바 · 드래그하여 이동")
  f:Hide()
  if PlayerFrame then
    PlayerFrame:HookScript("OnSizeChanged",function() if self.db and self.db.mode~="horizontal" then self:ApplyLayout(); self:Render() end end)
  end
end
function X:ApplyLayout()
  if not self.frame then return end
  local db,f=self.db,self.frame
  f:SetScale(db.scale); f:SetAlpha(db.alpha); f:ClearAllPoints()
  local wrap=db.mode~="horizontal"; local top=db.mode=="wrapTop"
  local first,second=self.segments[1],self.segments[2]
  first:ClearAllPoints(); second:ClearAllPoints()
  if wrap then
    local h,v,t=db.wrapHorizontalLength,db.wrapVerticalLength,db.wrapThickness
    f:SetSize(h+t,v)
    f:SetPoint(top and "TOPLEFT" or "BOTTOMLEFT",PlayerFrame or UIParent,top and "TOPLEFT" or "BOTTOMLEFT",
      -db.wrapOffset-t+db.wrapX,(top and db.wrapOffset+t or -db.wrapOffset-t)+db.wrapY)
    first:SetSize(t,v); first:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT"); first:SetOrientation("VERTICAL"); first:SetReverseFill(not top)
    first.length,first.vertical,first.reverse=v,true,not top
    second:SetSize(h,t); second:SetPoint(top and "TOPLEFT" or "BOTTOMLEFT",f,top and "TOPLEFT" or "BOTTOMLEFT",t,0)
    second:SetOrientation("HORIZONTAL"); second:SetReverseFill(false); second.length,second.vertical,second.reverse=h,false,false; second:Show()
  else
    f:SetSize(db.width,db.height); f:SetPoint("CENTER",UIParent,"CENTER",db.x/db.scale,db.y/db.scale)
    first:SetSize(db.width,db.height); first:SetPoint("TOPLEFT",f,"TOPLEFT"); first:SetOrientation("HORIZONTAL"); first:SetReverseFill(false)
    first.length,first.vertical,first.reverse=db.width,false,false; second:Hide()
  end
  self.levelText:ClearAllPoints(); self.xpText:ClearAllPoints(); self.levelText:SetWidth(52)
  if wrap then
    local edge,opposite=top and "TOPLEFT" or "BOTTOMLEFT",top and "BOTTOMLEFT" or "TOPLEFT"
    self.levelText:SetPoint(top and "BOTTOMRIGHT" or "TOPRIGHT",second,edge,-8,top and 4 or -4)
    self.xpText:SetPoint(opposite,second,edge,0,top and 4 or -4)
    self.xpText:SetWidth(db.wrapHorizontalLength); self.xpText:SetJustifyH("LEFT")
  else
    self.levelText:SetPoint("RIGHT",f,"LEFT",-8,0)
    self.xpText:SetPoint("LEFT",first,"LEFT",8,0); self.xpText:SetPoint("RIGHT",first,"RIGHT",-8,0)
    self.xpText:SetJustifyH(db.textPosition:upper())
  end
  self.levelText:SetJustifyH("RIGHT"); self.levelText:SetTextColor(unpack(db.textColor)); self.xpText:SetTextColor(unpack(db.textColor))
  f:EnableMouse(self.unlocked and not wrap or false); self.guide:SetShown(self.unlocked and not wrap or false)
  for _,s in ipairs(self.segments) do
    s:SetStatusBarColor(unpack(db.color)); s.bg:SetVertexColor(unpack(db.backgroundColor)); s.rested:SetVertexColor(unpack(db.restedColor))
    if self.unlocked then
      s:EnableMouse(false)
      if s.SetMouseClickEnabled then s:SetMouseClickEnabled(false) end
      if s.SetMouseMotionEnabled then s:SetMouseMotionEnabled(false) end
    else self:Mouse(s,false) end
  end
  self:LayoutMarkers()
end
function X:LayoutMarkers()
  local first,second=self.segments[1],self.segments[2]
  local wrap=self.db.mode~="horizontal"
  local total=first.length+(wrap and second.length or 0)
  -- One physical pixel keeps opaque markers legible without covering a block.
  local thickness=1/math.max(.1,self.frame:GetEffectiveScale())
  for i,marker in ipairs(self.markers) do
    local distance=total*i/10
    local segment=first
    if wrap and distance>=first.length then segment=second; distance=distance-first.length end
    marker:ClearAllPoints()
    if segment.vertical then
      local edge=segment.reverse and "TOPLEFT" or "BOTTOMLEFT"
      marker:SetPoint("CENTER",segment,edge,segment:GetWidth()/2,segment.reverse and -distance or distance)
      marker:SetSize(segment:GetWidth(),thickness)
    else
      marker:SetPoint("CENTER",segment,"LEFT",distance,0); marker:SetSize(thickness,segment:GetHeight())
    end
    marker:Show()
  end
end
-- Distribute a continuous interval over the vertical-then-horizontal path.
function X:SetSegment(s,offset,current,restEnd)
  local length=s.length
  s:SetMinMaxValues(0,length); s:SetValue(clamp(current-offset,0,length))
  local a,b=clamp(current-offset,0,length),clamp(restEnd-offset,0,length)
  s.rested:ClearAllPoints()
  if b>a and self.db.showRested then
    if s.vertical then
      local edge=s.reverse and "TOPLEFT" or "BOTTOMLEFT"
      s.rested:SetPoint(edge,s,edge,0,s.reverse and -a or a); s.rested:SetSize(s:GetWidth(),b-a)
    else s.rested:SetPoint("LEFT",s,"LEFT",a,0); s.rested:SetSize(b-a,s:GetHeight()) end
    s.rested:Show()
  else s.rested:Hide() end
end
function X:Render()
  if not self.frame then return end
  local db,d=self.db,self.data
  local visible=self:IsEnabled() and d and (not db.hideAtMaxLevel or not d.atCap)
  self.frame:SetShown(visible and true or false)
  if visible then
    local length=self.segments[1].length+(db.mode~="horizontal" and self.segments[2].length or 0)
    local fraction=d.maximum>0 and d.value/d.maximum or ((d.atCap or d.capped) and 1 or 0)
    local rest=d.maximum>0 and clamp((d.value+d.rested)/d.maximum,0,1) or fraction
    self:SetSegment(self.segments[1],0,length*fraction,length*rest)
    if db.mode~="horizontal" then self:SetSegment(self.segments[2],self.segments[1].length,length*fraction,length*rest) end
    self.levelText:SetText(d.kind=="reputation" and "" or ("Lv."..d.level)); self.levelText:SetShown(db.showLevel and d.kind~="reputation")
    self.xpText:SetText(self:Text()); self.xpText:SetShown(db.showText)
    if self.tooltipOwner then self:ShowTooltip(self.tooltipOwner) end
  end
end
function X:Update(newLevel)
  self:ReadData(newLevel); self:Render(); self:SyncNative()
end
function X:SavePosition()
  if not self.dragging then return end
  self.frame:StopMovingOrSizing(); self.dragging=nil
  local x,y=self.frame:GetCenter(); local cx,cy=UIParent:GetCenter()
  local scale=self.frame:GetEffectiveScale()/UIParent:GetEffectiveScale()
  if x and cx then self.db.x,self.db.y=x*scale-cx,y*scale-cy end
  self:Changed()
  if KHQOL.SaveCurrentProfile then KHQOL:SaveCurrentProfile() end
end
function X:Changed()
  if self.dragging then self:SavePosition(); return end
  self:GetDB(); if self.db.mode~="horizontal" then self.unlocked=false end
  self:HideTooltip(); self:ApplyLayout(); self:Update()
  if self.RefreshSettings then self:RefreshSettings() end
end
function X:SetEnabled()
  self:GetDB(); self:CreateFrames(); self.unlocked=false; self:HideTooltip(); self:ApplyLayout(); self:Update()
  if self.RefreshSettings then self:RefreshSettings() end
end
local events=CreateFrame("Frame")
for _,event in ipairs({"PLAYER_ENTERING_WORLD","PLAYER_XP_UPDATE","PLAYER_LEVEL_UP","UNIT_LEVEL","UPDATE_EXHAUSTION","PLAYER_UPDATE_RESTING","UPDATE_FACTION","FACTION_STANDING_CHANGED","ADDON_LOADED","UI_SCALE_CHANGED","DISPLAY_SIZE_CHANGED"}) do
  pcall(events.RegisterEvent,events,event)
end
events:SetScript("OnEvent",function(_,event,...)
  if not KHQOL.db or not X.frame then return end
  local arg=...
  if event=="ADDON_LOADED" then X:WatchReputationSelection() end
  if (event=="PLAYER_XP_UPDATE" or event=="UNIT_LEVEL") and arg and arg~="player" then return end
  if event=="PLAYER_LEVEL_UP" then
    X:Update(arg)
    if C_Timer and C_Timer.After then C_Timer.After(0,function() if X.frame then X:Update() end end) end
  elseif event=="UI_SCALE_CHANGED" or event=="DISPLAY_SIZE_CHANGED" then X:ApplyLayout(); X:Render()
  else X:Update() end
end)
