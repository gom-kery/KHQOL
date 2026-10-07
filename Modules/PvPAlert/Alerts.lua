local _, KHQOL = ...
local PA=KHQOL.modules.pvpAlert
local white="Interface\\Buttons\\WHITE8X8"
local colors={TARGETED={1,213/255,74/255},APPROACHING={1,159/255,47/255},CASTING={1,66/255,66/255}}
local labels={TARGETED="주시 중",APPROACHING="접근 중",CASTING="시전 → YOU"}
local icons={TARGETED="Interface\\Icons\\Spell_Shadow_DetectInvisibility",
  APPROACHING="Interface\\Icons\\Ability_Rogue_Ambush",CASTING="Interface\\Icons\\Spell_Fire_Fire"}
local ranges={[1]="근거리",[2]="중거리",[3]="원거리",[4]="사거리 밖"}

local function text(parent,size)
  local fs=parent:CreateFontString(nil,"OVERLAY","GameFontHighlight")
  fs:SetFont(KHQOL.UI:Font(),size,""); fs:SetJustifyH("LEFT"); fs:SetWordWrap(false)
  return fs
end
function PA:CreateAlerts()
  if self.frame then return end
  local root=CreateFrame("Frame","KHQOLPvPAlertFrame",UIParent)
  self.frame=root; root:SetSize(260,90); root:SetFrameStrata("HIGH")
  root:SetClampedToScreen(true); root:SetMovable(true); root:RegisterForDrag("LeftButton"); root:EnableMouse(false)
  local visual=CreateFrame("Frame",nil,root)
  self.visual=visual; visual:SetPoint("CENTER",root,"CENTER"); visual:SetSize(180,40)
  local background=visual:CreateTexture(nil,"BACKGROUND")
  self.background=background; background:SetAllPoints(); background:SetColorTexture(0,0,0,.60)
  self.borders={}
  for i=1,4 do self.borders[i]=visual:CreateTexture(nil,"BORDER"); self.borders[i]:SetTexture(white) end
  self.borders[1]:SetPoint("TOPLEFT"); self.borders[1]:SetPoint("TOPRIGHT"); self.borders[1]:SetHeight(1)
  self.borders[2]:SetPoint("BOTTOMLEFT"); self.borders[2]:SetPoint("BOTTOMRIGHT"); self.borders[2]:SetHeight(1)
  self.borders[3]:SetPoint("TOPLEFT"); self.borders[3]:SetPoint("BOTTOMLEFT"); self.borders[3]:SetWidth(1)
  self.borders[4]:SetPoint("TOPRIGHT"); self.borders[4]:SetPoint("BOTTOMRIGHT"); self.borders[4]:SetWidth(1)
  self.stateIcon=visual:CreateTexture(nil,"ARTWORK"); self.stateIcon:SetSize(14,14); self.stateIcon:SetPoint("TOPLEFT",10,-6)
  self.nameText=text(visual,14); self.nameText:SetPoint("TOPLEFT",30,-5)
  self.statusText=text(visual,12); self.statusText:SetPoint("TOPLEFT",30,-23)
  self.spellIcon=visual:CreateTexture(nil,"ARTWORK"); self.spellIcon:SetSize(28,28); self.spellIcon:SetPoint("TOPLEFT",10,-29)
  self.spellText=text(visual,14); self.spellText:SetPoint("TOPLEFT",46,-29); self.spellText:SetWidth(204)
  self.youText=text(visual,12); self.youText:SetText("→ YOU"); self.youText:SetPoint("TOPLEFT",46,-47)
  self.rangeText=text(visual,11); self.rangeText:SetPoint("TOPLEFT",78,-42); self.rangeText:SetWidth(112)
  self.pips={}
  for i=1,3 do
    local pip=visual:CreateTexture(nil,"ARTWORK"); pip:SetTexture(white); pip:SetSize(8,8); pip:SetPoint("TOPLEFT",30+(i-1)*14,-44)
    self.pips[i]=pip
  end
  self.bar=CreateFrame("StatusBar",nil,visual); self.bar:SetPoint("BOTTOMLEFT",10,20); self.bar:SetPoint("BOTTOMRIGHT",-10,20)
  self.bar:SetHeight(8); self.bar:SetStatusBarTexture(white); self.bar:SetMinMaxValues(0,1)
  local barBG=self.bar:CreateTexture(nil,"BACKGROUND"); barBG:SetAllPoints(); barBG:SetColorTexture(.15,.15,.15,.9)
  self.timeText=text(visual,11); self.timeText:SetPoint("BOTTOMRIGHT",-10,4); self.timeText:SetWidth(100); self.timeText:SetJustifyH("RIGHT")
  self.rows={}
  for i=1,self.SECONDARY_LIMIT do
    local row=CreateFrame("Frame",nil,visual); row:SetPoint("TOPLEFT",visual,"BOTTOMLEFT",0,-5-(i-1)*20); row:SetSize(260,18)
    row.icon=row:CreateTexture(nil,"ARTWORK"); row.icon:SetSize(12,12); row.icon:SetPoint("LEFT",8,0)
    row.text=text(row,11); row.text:SetPoint("LEFT",25,0); row.text:SetWidth(225)
    self.rows[i]=row
  end
  self.moveText=text(root,11); self.moveText:SetPoint("BOTTOM",root,"TOP",0,8); self.moveText:SetWidth(280)
  self.moveText:SetJustifyH("CENTER"); self.moveText:SetText("PvP Alert · 드래그 후 위치 이동 완료"); self.moveText:Hide()
  root:SetScript("OnDragStart",function(frame)
    if self.moving and not self.combat then self.dragging=true; frame:StartMoving() end
  end)
  root:SetScript("OnDragStop",function() self:SavePosition() end)
  self.visualCallback=function(_,dt) self:Animate(dt) end
  root:Hide()
end
function PA:ApplyLayout()
  if not self.frame or self.dragging then return end
  local db=self.db
  self.frame:ClearAllPoints(); self.frame:SetPoint(db.point,UIParent,db.relativePoint,db.x,db.y)
  self.frame:SetScale(db.scale); self.frame:SetAlpha(db.alpha)
  self.frame:EnableMouse(self.moving==true)
end
function PA:SavePosition()
  if not self.dragging then return end
  self.frame:StopMovingOrSizing(); self.dragging=false
  local x,y=self.frame:GetCenter()
  local ux,uy=UIParent:GetCenter()
  if x and y and ux and uy then
    local ratio=self.frame:GetEffectiveScale()/UIParent:GetEffectiveScale()
    self.db.point,self.db.relativePoint="CENTER","CENTER"
    self.db.x,self.db.y=(x-ux/ratio),(y-uy/ratio)
  end
  self:ApplyLayout()
  if self.settingsContent then KHQOL.UI:Refresh(self.settingsContent) end
end
function PA:SetMoving(on)
  if self.dragging then self:SavePosition() end
  self.moving=on and self:IsEnabled() and not self.combat or false
  if not self.frame then return end
  self.moveText:SetShown(self.moving); self.frame:EnableMouse(self.moving)
  if self.moving then self:Test("TARGETED",true)
  else self:StopTest() end
  if self.settingsContent then KHQOL.UI:Refresh(self.settingsContent) end
end
function PA:ResetPosition()
  self.db.point,self.db.relativePoint,self.db.x,self.db.y="CENTER","CENTER",0,165
  self:ApplyLayout(); if self.settingsContent then KHQOL.UI:Refresh(self.settingsContent) end
end
function PA:HideAlerts(immediate)
  if not self.frame then return end
  self.primary=nil; self.displayState=nil; self.displayCastStart=nil; self.displaySpell=nil
  if immediate then
    self.fade=nil; self.effect=nil; self.frame:SetScript("OnUpdate",nil)
    self.visual:SetScale(1); self.frame:Hide()
  elseif self.frame:IsShown() and (not self.fade or self.fade.direction~="out") then
    self.fade={direction="out",start=PA.Now(),duration=.25,from=self.frame:GetAlpha()}
    self.frame:SetScript("OnUpdate",self.visualCallback)
  end
end
function PA:PlayAlert(state)
  local db=self.db
  local sound=state=="CASTING" and db.castingSound or state=="APPROACHING" and db.approachSound or state=="TARGETED" and db.watchingSound
  if not sound then return end
  local kit=state=="CASTING" and (SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959)
    or (SOUNDKIT and SOUNDKIT.TELL_MESSAGE or 3081)
  if type(PlaySound)=="function" then pcall(PlaySound,kit,"Master") end
end
function PA:RenderPrimary(enemy,force,quiet)
  local state=enemy.state
  local cast=enemy.cast
  local changed=force or self.primary~=enemy or self.displayState~=state
    or (state=="CASTING" and (self.displayCastStart~=cast.startTime or self.displayCastID~=cast.castID or self.displaySpell~=cast.spellName))
  local now=PA.Now()
  self.primary=enemy
  if changed then
    self.displayState=state; self.displayCastStart=cast.startTime; self.displayCastID=cast.castID; self.displaySpell=cast.spellName
    self.effect=nil; self.fade=nil; self.visual:SetScale(1)
    self.frame:SetAlpha(self.db.alpha)
    local rgb=colors[state] or colors.TARGETED
    local isCast=state=="CASTING"; local approaching=state=="APPROACHING"
    self.visual:SetSize(isCast and 260 or approaching and 210 or 180,isCast and 90 or approaching and 60 or 40)
    self.background:SetShown(state~="TARGETED")
    for _,border in ipairs(self.borders) do border:SetVertexColor(unpack(rgb)); border:SetAlpha(.7); border:SetShown(state~="TARGETED") end
    self.stateIcon:SetTexture(icons[state]); self.stateIcon:SetVertexColor(unpack(rgb))
    self.nameText:SetWidth(self.visual:GetWidth()-40); self.nameText:SetTextColor(unpack(rgb))
    self.nameText:SetText(enemy.name or "Unknown")
    self.statusText:SetText(labels[state]); self.statusText:SetTextColor(unpack(rgb)); self.statusText:SetShown(not isCast)
    self.spellIcon:SetShown(isCast and self.db.showSpellIcon)
    self.spellText:SetShown(isCast); self.youText:SetShown(isCast)
    if isCast then
      self.spellIcon:SetTexture(cast.icon); self.spellText:SetText(cast.spellName or "주문")
      self.spellText:SetTextColor(1,1,1); self.youText:SetTextColor(unpack(rgb))
    end
    for _,pip in ipairs(self.pips) do pip:SetShown(approaching) end
    self.rangeText:SetShown(approaching)
    self.bar:SetShown(isCast and self.db.showCastBar and cast.timed)
    self.timeText:SetShown(isCast and self.db.showCastTime)
    self.bar:SetStatusBarColor(unpack(rgb)); self.lastTimeTenth=nil
    local effect=not quiet and (enemy.testing or self:AllowEffect(enemy,state,now))
    if effect then
      self:PlayAlert(state)
      if isCast or (approaching and self.db.approachPulse) then self.effect={state=state,start=now,duration=isCast and .35 or .30} end
      if state=="TARGETED" then self.fade={direction="in",start=now,duration=.15}; self.frame:SetAlpha(0) end
    else self.frame:SetAlpha(self.db.alpha) end
  else
    -- A name can arrive after registration without changing threat priority.
    if self.displayName~=enemy.name then self.nameText:SetText(enemy.name or "Unknown") end
  end
  self.displayName=enemy.name
  if state=="APPROACHING" then
    local range=enemy.currentRange
    local active=range==1 and 3 or range==2 and 2 or (range==3 or range==4) and 1 or 0
    for i,pip in ipairs(self.pips) do
      if i<=active then pip:SetVertexColor(1,159/255,47/255) else pip:SetVertexColor(.25,.25,.25) end
    end
    self.rangeText:SetText(ranges[range] or "거리 확인 불가")
  end
  self.frame:Show(); self:UpdateCastDisplay(now)
  local animate=self.effect or self.fade or (state=="CASTING" and cast.timed) or self.testing
  self.frame:SetScript("OnUpdate",animate and self.visualCallback or nil)
end
function PA:UpdateCastDisplay(now)
  local enemy=self.primary
  if not enemy or enemy.state~="CASTING" then return end
  local cast=enemy.cast
  if not cast.timed then
    self.timeText:SetText("시간 확인 불가"); return
  end
  local total=cast.endTime-cast.startTime
  local remaining=math.max(0,cast.endTime-now)
  self.bar:SetValue(math.min(1,remaining/total))
  local tenth=math.ceil(remaining*10-1e-6)
  if self.lastTimeTenth~=tenth then self.lastTimeTenth=tenth; self.timeText:SetText(string.format("%.1f",tenth/10)) end
  if remaining<=0 then
    if enemy.testing then self:StopTest()
    elseif self:CanScan() then
      -- Only this displayed cast is expired; no per-frame enemy scans.
      self:UpdateEnemy(enemy,now,false); self:SelectThreats(); self:RenderThreats()
    end
  end
end
function PA:RenderThreats()
  if self.testing then return end
  local primary=self.top[1]
  if not primary then self:HideAlerts(self.displayState=="CASTING"); return end
  self:RenderPrimary(primary)
  for i,row in ipairs(self.rows) do
    local enemy=self.top[i+1]
    row:SetShown(enemy~=nil)
    if enemy then
      if row.enemy~=enemy or row.state~=enemy.state or row.name~=enemy.name then
        row.enemy,row.state,row.name=enemy,enemy.state,enemy.name
        row.icon:SetTexture(icons[enemy.state]); row.text:SetText((enemy.name or "Unknown").."  "..labels[enemy.state])
        row.text:SetTextColor(unpack(colors[enemy.state])); row.icon:SetVertexColor(unpack(colors[enemy.state]))
      end
    end
  end
end
function PA:Animate(dt)
  local now=PA.Now()
  if self.testing and self.testExpires and now>=self.testExpires then self:StopTest(); return end
  if self.fade then
    local fade=self.fade; local t=math.min(1,(now-fade.start)/fade.duration)
    self.frame:SetAlpha(fade.direction=="in" and t*self.db.alpha or (1-t)*fade.from)
    if t>=1 then
      self.fade=nil
      if fade.direction=="out" then self:HideAlerts(true); return end
    end
  end
  if self.effect then
    local effect=self.effect; local t=math.min(1,(now-effect.start)/effect.duration)
    local scale
    if effect.state=="CASTING" then
      scale=1.2-.2*t
      for _,border in ipairs(self.borders) do border:SetAlpha(.55+.45*math.abs(math.cos(t*math.pi*2))) end
    else scale=t<.5 and .95+.2*t or 1.10-.10*t end
    self.visual:SetScale(scale)
    if t>=1 then
      self.effect=nil; self.visual:SetScale(1)
      for _,border in ipairs(self.borders) do border:SetAlpha(.7) end
    end
  end
  -- Presentation-only ticks; the scanner runs separately at 0.20 sec.
  self.visualElapsed=(self.visualElapsed or 0)+dt
  if self.visualElapsed>=.03 then self.visualElapsed=0; self:UpdateCastDisplay(now) end
  if not self.effect and not self.fade and not self.testing and (not self.primary or self.primary.state~="CASTING" or not self.primary.cast.timed) then
    self.frame:SetScript("OnUpdate",nil)
  end
end
function PA:Test(state,moving)
  if not self:IsEnabled() then return end
  if state=="WATCHING" then state="TARGETED" end
  local now=PA.Now()
  self.testing=true; self.testExpires=moving and nil or now+(state=="CASTING" and 2.5 or 4)
  self.testEnemy={name=state=="CASTING" and "TestMage" or "TestRogue",guid="TEST",state=state,
    currentRange=2,testing=true,lastAlert={},cast={active=state=="CASTING",spellName="변이",
    spellID=118,icon="Interface\\Icons\\Spell_Nature_Polymorph",startTime=now,endTime=now+2.5,timed=true}}
  self:RefreshLoop(); self:RenderTest(true,moving)
end
function PA:RenderTest(force,quiet)
  if not self.testEnemy then return end
  self:RenderPrimary(self.testEnemy,force,quiet)
  for _,row in ipairs(self.rows) do row:Hide() end
end
function PA:StopTest()
  if not self.testing then return end
  self.testing=false; self.testEnemy=nil; self.testExpires=nil
  self:ClearThreats(); self:HideAlerts(true); self:RefreshLoop()
  if self.moving then self:Test("TARGETED",true); return end
  if self:CanScan() then self:Scan() end
end
