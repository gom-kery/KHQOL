local _, KHQOL = ...
local P = KHQOL.modules.procAlert
local media = "Interface\\AddOns\\KHQOL\\Media\\EnvironmentHUD\\"
local priorities = {HIGH=30,NORMAL=20,LOW=10}
local sides = {"LEFT","RIGHT"}
P.defaults = {hud={scale=1,alpha=1,x=0,y=-180,spacing=280,size=260},animation=true}
P.active = {}
local function safe(v) return not (issecretvalue and issecretvalue(v)) end
local function number(v) return safe(v) and type(v)=="number" and v==v and math.abs(v)<math.huge end
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
function P:GetDB()
  local db=KHQOL.db.modules.procAlert
  if type(db)~="table" then db={}; KHQOL.db.modules.procAlert=db end
  KHQOL.MergeDefaults(db,self.defaults,"types")
  local bounds={scale={.5,2},alpha={.1,1},x={-3000,3000},y={-3000,3000},spacing={80,800},size={100,600}}
  for k,r in pairs(bounds) do db.hud[k]=clamp(number(db.hud[k]) and db.hud[k] or self.defaults.hud[k],r[1],r[2]) end
  self.db=db; return db
end
function P:GetBuffs(class)
  -- User registrations stay account-wide, outside profile snapshots.
  local db=KHQOL.db
  if type(db.globalData)~="table" then db.globalData={} end
  if type(db.globalData.procAlert)~="table" then db.globalData.procAlert={classes={}} end
  local data=db.globalData.procAlert
  if type(data.classes)~="table" then data.classes={} end
  class=class or select(2,UnitClass("player")) or "WARRIOR"
  if type(data.classes[class])~="table" then data.classes[class]={buffs={}} end
  if type(data.classes[class].buffs)~="table" then data.classes[class].buffs={} end
  return data.classes[class].buffs
end
function P:IsEnabled() return KHQOL:CanRunModule("procAlert") end
function P:Normalize(buff,id)
  if type(buff)~="table" or not number(id) or id<=0 or id~=math.floor(id) then return end
  buff.spellID=id
  buff.side=buff.side=="RIGHT" and "RIGHT" or "LEFT"
  buff.slot=1 -- v0.1 materializes only slot 1; side and slot remain distinct.
  buff.priority=priorities[buff.priority] and buff.priority or "NORMAL"
  buff.enabled=buff.enabled~=false
  buff.showIcon=buff.showIcon~=false; buff.showTime=buff.showTime~=false; buff.showName=buff.showName==true
  buff.name=type(buff.name)=="string" and buff.name or tostring(id)
  if type(buff.color)~="table" then buff.color={r=.1,g=.6,b=1,a=1} end
  for _,key in ipairs({"r","g","b","a"}) do buff.color[key]=clamp(number(buff.color[key]) and buff.color[key] or 1,0,1) end
  return buff
end
function P:GetSpellDetails(id)
  -- Existing safe helper supports C_Spell and the legacy spell API.
  return ForeverBuffReminder:GetSpellDetails(id)
end
local function readAura(a,id)
  if a==nil then return end
  if not safe(a) or type(a)~="table" or not number(a.spellId) then error("Unreadable aura identity") end
  if a.spellId~=id then return end
  if not safe(a.isHelpful) then error("Unreadable aura kind") end
  if a.isHelpful==false then return end
  for _,key in ipairs({"duration","expirationTime"}) do
    if not safe(a[key]) or (a[key]~=nil and not number(a[key])) then error("Unreadable aura time") end
  end
  if not safe(a.icon) then error("Unreadable aura icon") end
  return {duration=a.duration or 0,expirationTime=a.expirationTime or 0,icon=a.icon}
end
function P:ReadAuras(buffs)
  if not self:IsEnabled() then return {} end
  local found,unresolved,unknown={},{},{}
  for id,b in pairs(buffs) do
    if self:Normalize(b,id) and b.enabled then
      local api=C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID
      if type(api)=="function" then
        local status,a=KHQOL.ReadPublicAPI(api,id)
        if status=="ok" then
          local ok,value=pcall(readAura,a,id)
          if ok then found[id]=value else unknown[id]=true end
        else unknown[id]=true end -- Never bypass a rejected/restricted modern read.
      else unresolved[id]=true end
    end
  end
  if next(unresolved) then
    -- One bounded event-driven traversal for all older-client registrations.
    local complete=false
    local ok=pcall(function()
      for i=1,255 do
        local a
        if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
          a=C_UnitAuras.GetAuraDataByIndex("player",i,"HELPFUL")
        elseif UnitAura then
          local name,icon,_,_,duration,expiration,_,_,_,id=UnitAura("player",i,"HELPFUL")
          if not safe(name) then error("Unreadable aura name") end
          if not name then complete=true;break end
          a={spellId=id,icon=icon,duration=duration,expirationTime=expiration}
        else error("No supported Aura API") end
        if not safe(a) then error("Unreadable aura") end
        if not a then complete=true;break end
        if not number(a.spellId) then error("Unreadable aura identity") end
        if unresolved[a.spellId] then found[a.spellId]=readAura(a,a.spellId) end
      end
    end)
    if not ok or not complete then
      for id in pairs(unresolved) do unknown[id]=true end
    end
  end
  self.apiUnavailable=next(unknown)~=nil
  return found,unknown
end
function P:Scan()
  if not self:IsEnabled() or not self.inCombat then self.active={}; return end
  local buffs=self:GetBuffs(); local found,unknown=self:ReadAuras(buffs); local now=GetTime()
  local active={}
  for id,a in pairs(found) do
    local old=self.active[id]
    local continued=old and (old.expirationTime<=0 or old.expirationTime>now)
    a.started=continued and old.started or now; a.id=id; a.buff=buffs[id]
    active[id]=a
  end
  -- Uncertainty is not an aura removal; only keep an already verified live aura.
  for id in pairs(unknown or {}) do
    local old=self.active[id]
    if old and (old.expirationTime<=0 or old.expirationTime>now) and buffs[id] and buffs[id].enabled then active[id]=old end
  end
  self.active=active
end
function P:Winners(now)
  local winners={LEFT={},RIGHT={}}
  for _,a in pairs(self.active) do
    if a.expirationTime<=0 or a.expirationTime>now then
      local b=a.buff; local old=winners[b.side][b.slot]
      local function before()
        local ap,bp=priorities[b.priority],priorities[old.buff.priority]
        if ap~=bp then return ap>bp end
        if a.started~=old.started then return a.started<old.started end
        return a.id<old.id
      end
      if not old or before() then winners[b.side][b.slot]=a end
    end
  end
  return winners
end
local function animation(row,from,to,finished)
  local group=row:CreateAnimationGroup()
  local a=group:CreateAnimation("Alpha"); a:SetFromAlpha(from); a:SetToAlpha(to); a:SetDuration(.15)
  group:SetScript("OnFinished",finished)
  return group
end
function P:CreateFrames()
  if self.frame then return end
  local f=CreateFrame("Frame","KHQOLProcAlertFrame",UIParent); self.frame=f
  f:SetFrameStrata("MEDIUM"); f:SetMovable(true); f:SetClampedToScreen(true); f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart",function(frame) if self.unlocked then self.dragging=true; frame:StartMoving() end end)
  f:SetScript("OnDragStop",function() self:SavePosition() end)
  f.move=f:CreateFontString(nil,"OVERLAY","GameFontHighlight")
  f.move:SetPoint("TOP",0,20); f.move:SetText("발동 알림 · 그룹을 드래그하여 이동")
  f.background=f:CreateTexture(nil,"BACKGROUND"); f.background:SetAllPoints(); f.background:SetColorTexture(.1,.6,.65,.08)
  self.slots={}
  for _,side in ipairs(sides) do
    self.slots[side]={}
    for slot=1,1 do
      local row=CreateFrame("Frame",nil,f); self.slots[side][slot]=row; row:EnableMouse(false)
      row.empty=row:CreateTexture(nil,"BACKGROUND")
      row.frame=row:CreateTexture(nil,"ARTWORK",nil,-1)
      row.fill=row:CreateTexture(nil,"ARTWORK",nil,0)
      row.caps=row:CreateTexture(nil,"OVERLAY",nil,0)
      row.glow=row:CreateTexture(nil,"OVERLAY",nil,1)
      row.icon=row:CreateTexture(nil,"OVERLAY"); row.icon:SetSize(30,30); row.icon:SetPoint("TOP",row,"BOTTOM",0,-4)
      row.name=row:CreateFontString(nil,"OVERLAY","GameFontHighlight")
      row.name:SetFont(KHQOL.UI:Font(),13,"OUTLINE"); row.name:SetPoint("TOP",row.icon,"BOTTOM",0,-4); row.name:SetWidth(220)
      row.time=row:CreateFontString(nil,"OVERLAY","GameFontHighlight")
      row.time:SetFont(KHQOL.UI:Font(),15,"OUTLINE"); row.time:SetPoint("TOP",row.name,"BOTTOM",0,-4)
      row.fadeIn=animation(row,0,1,function() row:SetAlpha(1) end)
      row.fadeOut=animation(row,1,0,function() row:Hide(); row:SetAlpha(1); row.fading=nil; row.current=nil end)
      row:Hide()
    end
  end
  self.update=function(_,elapsed)
    self.elapsed=(self.elapsed or 0)+elapsed
    if self.elapsed>=.05 then self.elapsed=0; self:Render() end
  end
  f:Hide()
end
function P:Layout()
  local d,f=self.db.hud,self.frame
  f:SetScale(d.scale); f:SetAlpha(d.alpha)
  if not self.dragging then f:ClearAllPoints(); f:SetPoint("CENTER",UIParent,"CENTER",d.x/d.scale,d.y/d.scale) end
  local width=d.size*128/420
  f:SetSize(math.max(480,d.spacing+2*width*104/128+32),d.size*464/420+130)
  f:EnableMouse(self.unlocked==true); f.move:SetShown(self.unlocked==true); f.background:SetShown(self.unlocked==true)
  for _,side in ipairs(sides) do
    for slot,row in ipairs(self.slots[side]) do
      local left=side=="LEFT"; local sign=left and -1 or 1; local asset=left and "left" or "right"
      row.u0=(left and 96 or 288)/512; row.u1=(left and 224 or 416)/512
      row.width=width; row.fillHeight=d.size
      row:ClearAllPoints(); row:SetSize(width,d.size*464/420)
      row:SetPoint("CENTER",f,"CENTER",sign*(d.spacing/2+width*40/128+(slot-1)*width),35)
      for _,key in ipairs({"empty","frame","caps"}) do
        row[key]:SetAllPoints(row); row[key]:SetTexCoord(row.u0,row.u1,24/512,488/512)
      end
      for _,key in ipairs({"empty","fill","caps","glow"}) do row[key]:SetTexture(media.."khqol_envhud_"..asset.."_"..(key=="caps" and "endcaps" or key)..".tga") end
      row.frame:SetTexture(media.."khqol_envhud_right_frame.tga")
      if left then row.frame:SetTexCoord(416/512,288/512,24/512,488/512) end
    end
  end
end
function P:Visual(row,a,now)
  local b,c=a.buff,a.buff.color
  local remaining=a.expirationTime>0 and math.max(0,a.expirationTime-now) or nil
  local fraction=remaining and a.duration>0 and clamp(remaining/a.duration,0,1) or 1
  for _,key in ipairs({"fill","glow"}) do
    local t=row[key]; t:ClearAllPoints(); t:SetPoint("BOTTOM",row,"CENTER",0,-row.fillHeight/2)
    t:SetSize(row.width,math.max(.001,row.fillHeight*fraction))
    t:SetTexCoord(row.u0,row.u1,(466-420*fraction)/512,466/512)
    t:SetVertexColor(c.r,c.g,c.b,c.a*(key=="glow" and .3 or 1)); t:SetShown(fraction>0)
  end
  row.icon:SetTexture(a.icon or b.icon or "Interface\\Icons\\INV_Misc_QuestionMark"); row.icon:SetShown(b.showIcon)
  row.name:SetText(b.showName and b.name or "")
  row.name:ClearAllPoints(); row.name:SetPoint("TOP",row,"BOTTOM",0,b.showIcon and -38 or -4)
  row.time:SetText(b.showTime and remaining and (remaining>=10 and string.format("%d",math.ceil(remaining)) or string.format("%.1f",remaining)) or "")
  row.time:SetTextColor(c.r,c.g,c.b)
  if row.current~=a.id or row.fading then
    row.fadeOut:Stop(); row.fadeIn:Stop(); row.fading=nil; row.current=a.id; row:SetAlpha(1); row:Show()
    if self.db.animation then row.fadeIn:Play() end
  else row:Show() end
end
function P:HideRow(row,immediate)
  if immediate or not self.db.animation then
    row.fadeIn:Stop(); row.fadeOut:Stop(); row:Hide(); row:SetAlpha(1); row.current=nil; row.fading=nil
  elseif row:IsShown() and not row.fading then
    row.fadeIn:Stop(); row.fading=true; row.fadeOut:Play()
  end
end
function P:Preview(now)
  if not self:IsEnabled() then return {LEFT={},RIGHT={}} end
  local result={LEFT={},RIGHT={}}
  for i,side in ipairs(sides) do
    local b={name=i==1 and "왼쪽 테스트" or "오른쪽 테스트",showIcon=true,showName=true,showTime=true,
      color=i==1 and {r=.1,g=.55,b=1,a=1} or {r=1,g=.45,b=.08,a=1}}
    result[side][1]={id=-i,buff=b,duration=self.testUntil and 8 or 0,expirationTime=self.testUntil or 0,icon=136170}
  end
  return result
end
function P:Render()
  if not self.frame then return end
  local now=GetTime(); local enabled=self:IsEnabled()
  if self.testUntil and now>=self.testUntil then self.testUntil=nil end
  local preview=enabled and (self.testUntil or self.unlocked)
  local winners=preview and self:Preview(now) or self:Winners(now)
  local updating,visible=false,false
  for _,side in ipairs(sides) do
    for slot,row in ipairs(self.slots[side]) do
      local a=enabled and winners[side][slot]
      if a then
        self:Visual(row,a,now); visible=true
        if a.expirationTime>0 then updating=true end
      else self:HideRow(row,not enabled or not self.inCombat and not preview) end
      if row:IsShown() then visible=true end
    end
  end
  -- Fade groups run independently; no idle timer or aura polling.
  self.frame:SetScript("OnUpdate",updating and self.update or nil)
  self.frame:SetShown(visible or preview and true or false)
end
function P:SavePosition()
  if not self.dragging then return end
  self.frame:StopMovingOrSizing(); self.dragging=nil
  local x,y=self.frame:GetCenter(); local cx,cy=UIParent:GetCenter()
  local scale=self.frame:GetEffectiveScale()/UIParent:GetEffectiveScale()
  if x and cx then self.db.hud.x,self.db.hud.y=clamp(x*scale-cx,-3000,3000),clamp(y*scale-cy,-3000,3000) end
  self:Changed()
  if self.settingsContent then KHQOL.UI:Refresh(self.settingsContent) end
end
function P:Changed()
  if not KHQOL.LabLock:IsUnlocked() then return end
  self:GetDB(); self:CreateFrames(); self:Layout(); self:Scan(); self:Render()
  if KHQOL.SaveCurrentProfile then KHQOL:SaveCurrentProfile() end
end
function P:Test()
  if not self:IsEnabled() then return end
  self.testUntil=GetTime()+8; self:Render()
end
function P:SetUnlocked(on)
  self:SavePosition(); self.unlocked=on and self:IsEnabled() or false; self:Layout(); self:Render()
end
function P:SetEnabled(on)
  on=on and self:IsEnabled()
  self:GetDB(); self:CreateFrames(); self:SavePosition()
  self.unlocked=false; self.testUntil=nil; self.active={}; self.elapsed=0
  self.events:UnregisterEvent("UNIT_AURA")
  self.events:UnregisterEvent("PLAYER_REGEN_DISABLED"); self.events:UnregisterEvent("PLAYER_REGEN_ENABLED")
  self.events:UnregisterEvent("PLAYER_ENTERING_WORLD")
  self.inCombat=on and UnitAffectingCombat("player") and true or false
  if on then
    self.events:RegisterEvent("PLAYER_REGEN_DISABLED"); self.events:RegisterEvent("PLAYER_REGEN_ENABLED")
    self.events:RegisterEvent("PLAYER_ENTERING_WORLD")
    if self.inCombat then self.events:RegisterUnitEvent("UNIT_AURA","player") end
  end
  self:Layout(); self:Scan(); self:Render()
end
P.events=CreateFrame("Frame")
P.events:SetScript("OnEvent",function(_,event,unit)
  if not P:IsEnabled() then P.active={};P.testUntil=nil;P:Render();return end
  if event=="UNIT_AURA" and unit~="player" then return end
  if event=="PLAYER_REGEN_DISABLED" or event=="PLAYER_ENTERING_WORLD" then
    P.inCombat=event=="PLAYER_REGEN_DISABLED" or UnitAffectingCombat("player") and true or false
    if P.inCombat then P.events:RegisterUnitEvent("UNIT_AURA","player") else P.events:UnregisterEvent("UNIT_AURA") end
    P.testUntil=nil
  elseif event=="PLAYER_REGEN_ENABLED" then
    P.inCombat=false; P.testUntil=nil; P.events:UnregisterEvent("UNIT_AURA")
  end
  P:Scan(); P:Render()
end)
