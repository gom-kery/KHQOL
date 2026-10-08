local _, KHQOL = ...
local E = KHQOL.modules.environmentTimer
local order = {"BREATH", "EXHAUSTION", "FEIGNDEATH"}
local names = {BREATH="호흡", EXHAUSTION="피로도", FEIGNDEATH="죽은척 하기"}
local warnings = {BREATH="호흡 부족!", EXHAUSTION="피로도 위험!", FEIGNDEATH="죽은척 하기"}
local colors = {NORMAL={.1,.75,.9}, CAUTION={1,.85,.15}, DANGER={1,.45,.08}, CRITICAL={1,.12,.12}}
local flat = "Interface\\Buttons\\WHITE8X8"
E.defaults = {
  timers={BREATH=true,EXHAUSTION=true,FEIGNDEATH=true}, style="horizontal",
  x=0,y=-180,width=280,height=24,scale=1,alpha=1,direction="up",
  hudSize=260,hudThickness=8,hudGap=280,
  showName=true,showTime=true,showPercent=true,textFormat="custom",
  caution=50,danger=25,critical=10,centerWarning=true,sound=true,
}
E.active, E.native = {}, {}
local function numeric(v)
  return not (issecretvalue and issecretvalue(v)) and type(v)=="number" and v==v and v~=math.huge and v~=-math.huge
end
local function paused(v) return v==true or (numeric(v) and v>0) end
local function clamp(v,lo,hi) return math.max(lo,math.min(hi,v)) end
function E:GetDB()
  local db=KHQOL.db.modules.environmentTimer
  if type(db)~="table" then db={}; KHQOL.db.modules.environmentTimer=db end
  KHQOL.MergeDefaults(db,self.defaults,"types")
  local bounds={x={-3000,3000},y={-3000,3000},width={40,800},height={8,500},scale={.5,2},alpha={.1,1},
    hudSize={100,600},hudThickness={2,30},hudGap={80,800},caution={1,100},danger={0,99},critical={0,120}}
  for key,range in pairs(bounds) do db[key]=clamp(numeric(db[key]) and db[key] or self.defaults[key],range[1],range[2]) end
  db.danger=math.min(db.danger,db.caution-1)
  if db.style~="horizontal" and db.style~="vertical" and db.style~="hud" then db.style="horizontal" end
  if db.direction~="up" and db.direction~="down" then db.direction="up" end
  local formats={custom=true,name_time=true,time=true,name_percent=true,percent=true,name_time_percent=true}
  if not formats[db.textFormat] then db.textFormat="custom" end
  self.db=db; return db
end
function E:IsEnabled() return KHQOL.db and KHQOL:GetEnabled("environmentTimer") end
function E:Handles(timer) return self:IsEnabled() and names[timer] and self.db.timers[timer] and self.active[timer]~=nil end
function E:GetState(value, maximum)
  if value/1000<=self.db.critical then return "CRITICAL" end
  local percent=value/maximum*100
  if percent<=self.db.danger then return "DANGER" end
  if percent<=self.db.caution then return "CAUTION" end
  return "NORMAL"
end
function E:Text(timer, data)
  local db=self.db
  local name,time,percent=db.showName,db.showTime,db.showPercent
  if db.textFormat~="custom" then
    name=db.textFormat:find("name",1,true)~=nil
    time=db.textFormat:find("time",1,true)~=nil
    percent=db.textFormat:find("percent",1,true)~=nil
  end
  local result=name and names[timer] or ""
  if time then result=result..(result~="" and " " or "")..math.ceil(data.value/1000).."초" end
  if percent then
    local p=math.floor(data.value/data.maximum*100+.5).."%"
    result=result..(time and " ("..p..")" or ((result~="" and " " or "")..p))
  end
  return result
end
function E:Start(timer,value,maximum,rate,isPaused,label)
  if not self:IsEnabled() or not names[timer] then return end
  -- Invalid or restricted values must never suppress Blizzard's own display.
  if not numeric(value) or not numeric(maximum) or maximum<=0 then self.active[timer]=nil; return end
  local old=self.active[timer]
  self.active[timer]={value=clamp(value,0,maximum),maximum=maximum,rate=numeric(rate) and rate or -1,
    paused=paused(isPaused),label=label,state=old and old.state,sounded=old and old.sounded or false}
end
function E:Rescan()
  local previous=self.active; self.active={}
  if not self:IsEnabled() or not GetMirrorTimerInfo then return end
  for i=1,(MIRRORTIMER_NUMTIMERS or 3) do
    local ok,t,v,m,r,p,l=pcall(GetMirrorTimerInfo,i)
    if ok and names[t] then self.active[t]=previous[t]; self:Start(t,v,m,r,p,l) end
  end
end
-- Preserve the native timer's event registrations, OnUpdate, timer identity and
-- visibility lifecycle. Only its presentation is suppressed, per owned type.
-- Keeping it running also permits immediate restoration without replayed events.
function E:SyncNativeFrame(f)
  local owns=self:Handles(f.timer or f.timerType)
  local saved=self.native[f]
  if owns then
    if not saved then saved={alpha=f:GetAlpha(),mouse=f:IsMouseEnabled()}; self.native[f]=saved end
    f:SetAlpha(0); f:EnableMouse(false)
  elseif saved then
    self.native[f]=nil; f:SetAlpha(saved.alpha); f:EnableMouse(saved.mouse)
  end
end
function E:AttachNative(f)
  if not f or self.hooked[f] then return end
  self.hooked[f]=true
  f:HookScript("OnShow",function(frame) self:SyncNativeFrame(frame) end)
  f:HookScript("OnEvent",function(frame) self:SyncNativeFrame(frame) end)
  if f.Setup and hooksecurefunc then hooksecurefunc(f,"Setup",function(frame) self:SyncNativeFrame(frame) end) end
end
function E:SyncNative()
  for i=1,(MIRRORTIMER_NUMTIMERS or 3) do self:AttachNative(_G["MirrorTimer"..i]) end
  local container=MirrorTimerContainer
  if container and container.mirrorTimers then for _,f in ipairs(container.mirrorTimers) do self:AttachNative(f) end end
  for f in pairs(self.hooked) do self:SyncNativeFrame(f) end
end
local function pulse(frame,duration)
  local ag=frame:CreateAnimationGroup(); ag:SetLooping("BOUNCE")
  local a=ag:CreateAnimation("Alpha"); a:SetFromAlpha(1); a:SetToAlpha(.35); a:SetDuration(duration)
  return ag
end
function E:CreateFrames()
  if self.frame then return end
  local f=CreateFrame("Frame","KHQOLEnvironmentTimerFrame",UIParent)
  self.frame=f; self.rows={}; self.hooked={}
  f:SetFrameStrata("MEDIUM"); f:SetMovable(true); f:SetClampedToScreen(true); f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart",function(frame) if self.unlocked then self.dragging=true; frame:StartMoving() end end)
  f:SetScript("OnDragStop",function() self:SavePosition() end)
  for i=1,3 do
    local row=CreateFrame("Frame",nil,f); row:EnableMouse(false)
    row.bar=CreateFrame("StatusBar",nil,row); row.bar:SetStatusBarTexture(flat); row.bar:EnableMouse(false)
    row.bg=row.bar:CreateTexture(nil,"BACKGROUND"); row.bg:SetAllPoints(); row.bg:SetTexture(flat); row.bg:SetVertexColor(.03,.04,.05,.8)
    row.glow=row:CreateTexture(nil,"BACKGROUND"); row.glow:SetTexture("Interface\\AddOns\\KHQOL\\CursorTrail\\Media\\SoftGlow.tga")
    row.glow:SetPoint("TOPLEFT",-8,8); row.glow:SetPoint("BOTTOMRIGHT",8,-8)
    -- StatusBar is a child frame; keep text above its fill in a sibling layer.
    row.textLayer=CreateFrame("Frame",nil,row); row.textLayer:SetAllPoints(row)
    row.textLayer:SetFrameLevel(row.bar:GetFrameLevel()+2); row.textLayer:EnableMouse(false)
    row.text=row.textLayer:CreateFontString(nil,"OVERLAY","GameFontHighlight"); row.text:SetFont(KHQOL.UI:Font(),13,"OUTLINE")
    row.segments={}
    for j=1,32 do
      local bg=row:CreateTexture(nil,"BACKGROUND"); bg:SetTexture(flat); bg:SetVertexColor(.03,.04,.05,.8)
      local fill=row:CreateTexture(nil,"ARTWORK"); fill:SetTexture(flat)
      local glow=row:CreateTexture(nil,"BACKGROUND"); glow:SetTexture("Interface\\AddOns\\KHQOL\\CursorTrail\\Media\\SoftGlow.tga")
      row.segments[j]={bg=bg,fill=fill,glow=glow}
    end
    row.slow=pulse(row,1); row.fast=pulse(row,.3); self.rows[i]=row
  end
  local warning=CreateFrame("Frame","KHQOLEnvironmentWarningFrame",UIParent)
  warning:SetSize(560,180); warning:SetPoint("CENTER",UIParent,"CENTER",0,80); warning:SetFrameStrata("HIGH"); warning:EnableMouse(false)
  warning.text=warning:CreateFontString(nil,"OVERLAY","GameFontHighlight"); warning.text:SetAllPoints(); warning.text:SetFont(KHQOL.UI:Font(),24,"OUTLINE"); warning.text:SetTextColor(1,.15,.1)
  warning:Hide(); self.warning=warning
  self.moveText=f:CreateFontString(nil,"OVERLAY","GameFontHighlight"); self.moveText:SetPoint("TOP",0,22); self.moveText:SetText("환경 타이머 · 그룹을 드래그하여 이동")
  self.update=function(_,elapsed)
    self.elapsed=(self.elapsed or 0)+elapsed
    if self.elapsed>=.05 then local dt=self.elapsed; self.elapsed=0; self:Render(dt) end
  end
  f:Hide()
  if hooksecurefunc and type(MirrorTimer_Show)=="function" then
    hooksecurefunc("MirrorTimer_Show",function() self:SyncNative() end)
  end
end
function E:SavePosition()
  if not self.dragging then return end
  self.frame:StopMovingOrSizing(); self.dragging=nil
  local x,y=self.frame:GetCenter(); local cx,cy=UIParent:GetCenter()
  local scale=self.frame:GetEffectiveScale()/UIParent:GetEffectiveScale()
  if x and cx then self.db.x,self.db.y=x*scale-cx,y*scale-cy end
  self:Changed()
end
function E:Layout(count)
  local db,f=self.db,self.frame
  local hud=db.style=="hud"
  f:SetScale(hud and 1 or db.scale); f:SetAlpha(db.alpha)
  f:ClearAllPoints(); f:SetPoint("CENTER",UIParent,"CENTER",db.x/(hud and 1 or db.scale),db.y/(hud and 1 or db.scale))
  if hud then f:SetSize(db.hudGap+db.hudSize*.4+db.hudThickness+480,db.hudSize+100)
  else f:SetSize(db.width,db.height*count+32*(count-1)) end
  f:EnableMouse(self.unlocked==true); self.moveText:SetShown(self.unlocked==true)
  for i,row in ipairs(self.rows) do
    row:ClearAllPoints(); row.text:ClearAllPoints()
    local arc=hud and i<=2
    row.bar:SetShown(not hud); row.glow:SetShown(false)
    if arc then
      local sign=i==1 and -1 or 1
      row:SetAllPoints(f)
      row.text:SetPoint(i==1 and "RIGHT" or "LEFT",f,"CENTER",sign*(db.hudGap/2+db.hudThickness),-db.hudSize/2-16); row.text:SetWidth(240)
      row.text:SetJustifyH(i==1 and "RIGHT" or "LEFT")
      for j,s in ipairs(row.segments) do
        local t=(j-.5)/32
        local x=sign*(db.hudGap/2+math.sin(math.pi*t)*db.hudSize*.2)
        for _,texture in ipairs({s.bg,s.fill}) do
          texture:ClearAllPoints(); texture:SetPoint("CENTER",f,"CENTER",x,db.hudSize*(t-.5))
          texture:SetSize(db.hudThickness,db.hudSize/32+1); texture:Show()
        end
        s.glow:ClearAllPoints(); s.glow:SetPoint("CENTER",f,"CENTER",x,db.hudSize*(t-.5))
        s.glow:SetSize(db.hudThickness+12,db.hudSize/32+12); s.glow:Hide()
      end
    else
      row:SetSize(hud and f:GetWidth() or db.width,hud and 28 or db.height)
      if hud then row:SetPoint("CENTER",f,"CENTER",0,-db.hudSize/2-48)
      else row:SetPoint("TOPLEFT",f,"TOPLEFT",0,-(i-1)*(db.height+32)) end
      row.bar:SetAllPoints(row); row.bar:SetOrientation(db.style=="vertical" and "VERTICAL" or "HORIZONTAL")
      row.bar:SetReverseFill(db.style=="vertical" and db.direction=="down")
      row.text:SetPoint(db.style=="vertical" and "BOTTOM" or "CENTER",row,db.style=="vertical" and "TOP" or "CENTER",0,db.style=="vertical" and 4 or 0)
      row.text:SetWidth(math.max(db.width,240))
      row.text:SetJustifyH("CENTER")
      for _,s in ipairs(row.segments) do s.bg:Hide(); s.fill:Hide(); s.glow:Hide() end
    end
  end
end
function E:Visual(row,timer,data,index)
  local state=data.state; local color=colors[state]
  if row.state~=state then
    row.slow:Stop(); row.fast:Stop(); row:SetAlpha(1)
    if state=="DANGER" then row.slow:Play() elseif state=="CRITICAL" then row.fast:Play() end
    row.state=state
  end
  row.text:SetText(self:Text(timer,data)); row.text:SetTextColor(unpack(color))
  row.bar:SetMinMaxValues(0,data.maximum); row.bar:SetValue(data.value); row.bar:SetStatusBarColor(unpack(color))
  row.glow:SetVertexColor(color[1],color[2],color[3],.3)
  row.glow:SetShown(state=="CAUTION" and self.db.style~="hud")
  if self.db.style=="hud" and index<=2 then
    local fraction=data.value/data.maximum
    for j,s in ipairs(row.segments) do
      s.fill:SetVertexColor(color[1],color[2],color[3],state=="CAUTION" and .85 or 1)
      s.fill:SetAlpha(clamp(fraction*32-j+1,0,1))
      s.bg:SetVertexColor(color[1],color[2],color[3],state=="CAUTION" and .35 or .15)
      s.glow:SetVertexColor(color[1],color[2],color[3],.2); s.glow:SetShown(state=="CAUTION")
    end
  end
  row:Show()
end
function E:Render(elapsed)
  if not self.frame then return end
  local visible,warning={},{}
  if self:IsEnabled() then
    for priority,timer in ipairs(order) do
      local data=self.active[timer]
      if data and self.db.timers[timer] then
        if not data.paused then
          local ok,value=false,nil
          if GetMirrorTimerProgress then ok,value=pcall(GetMirrorTimerProgress,timer) end
          if ok and numeric(value) then data.value=clamp(value,0,data.maximum)
          else data.value=clamp(data.value+(elapsed or 0)*1000*data.rate,0,data.maximum) end
        end
        data.state=self:GetState(data.value,data.maximum)
        if data.state=="CRITICAL" then
          if not data.sounded then
            data.sounded=true
            if self.db.sound and PlaySoundFile then PlaySoundFile("Interface\\AddOns\\KHQOL\\Media\\aggro.wav","Master") end
          end
          if self.db.centerWarning then warning[#warning+1]=warnings[timer].."\n"..math.ceil(data.value/1000).."초" end
        end
        visible[#visible+1]={timer=timer,data=data,priority=priority}
      end
    end
  end
  table.sort(visible,function(a,b)
    if (a.data.state=="CRITICAL")~=(b.data.state=="CRITICAL") then return a.data.state=="CRITICAL" end
    return a.priority<b.priority
  end)
  local count=#visible
  if count==0 and self.unlocked and self:IsEnabled() then
    visible[1]={timer="BREATH",data={value=1,maximum=1,state="NORMAL"}}; count=1
  end
  if self.layoutCount~=count then self.layoutCount=count; self:Layout(math.max(1,count)) end
  for i,row in ipairs(self.rows) do
    local item=visible[i]
    if item then self:Visual(row,item.timer,item.data,i)
    else row:Hide(); row.slow:Stop(); row.fast:Stop(); row.state=nil end
  end
  self.warning.text:SetText(table.concat(warning,"\n")); self.warning:SetShown(#warning>0)
  self.frame:SetShown(count>0)
  local running=false
  for timer in pairs(self.active) do if self:Handles(timer) then running=true; break end end
  self.frame:SetScript("OnUpdate",running and self.update or nil)
  self:SyncNative()
end
function E:Changed()
  self:GetDB(); self:Rescan(); self.layoutCount=nil; self:Render(0)
  if self.settingsContent then KHQOL.UI:Refresh(self.settingsContent) end
end
function E:SetEnabled(enabled)
  if self.dragging then self:SavePosition() end
  self:GetDB(); self:CreateFrames()
  if not enabled then self.unlocked=false end
  self:Rescan(); self.layoutCount=nil; self:Render(0)
end
local events=CreateFrame("Frame")
for _,event in ipairs({"PLAYER_ENTERING_WORLD","MIRROR_TIMER_START","MIRROR_TIMER_STOP","MIRROR_TIMER_PAUSE","ADDON_LOADED"}) do events:RegisterEvent(event) end
events:SetScript("OnEvent",function(_,event,...)
  if not KHQOL.db or not E.frame then return end
  if event=="MIRROR_TIMER_START" then E:Start(...)
  elseif event=="MIRROR_TIMER_STOP" then local timer=...; E.active[timer]=nil
  elseif event=="MIRROR_TIMER_PAUSE" then
    local timer,p=...
    if type(timer)=="string" then if E.active[timer] then E.active[timer].paused=paused(p) end
    else for _,data in pairs(E.active) do data.paused=paused(timer) end end
  elseif event=="PLAYER_ENTERING_WORLD" then E:Rescan()
  end
  E:Render(0)
end)
