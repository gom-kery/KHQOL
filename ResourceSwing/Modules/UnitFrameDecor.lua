local _,KHQOL=...
local M=KHQOL.modules.unitFrames
local B=KHQOL.modules.basicUI
local call,public=KHQOL.PublicCall,KHQOL.IsPublicValue
local WHITE="Interface\\Buttons\\WHITE8X8"
local function finite(v) return type(v)=="number" and v==v and math.abs(v)<math.huge end
local function combat() return call(InCombatLockdown)==true end
local function editing() return EditModeManagerFrame and call(EditModeManagerFrame.IsShown,EditModeManagerFrame)==true end
local function number(v,default,low,high)
  if not public(v) or type(v)~="number" or v~=v or math.abs(v)==math.huge then v=default end
  return math.max(low,math.min(high,v))
end
local function equal(a,b)
  if a==b then return true end
  if type(a)~=type(b) then return false end
  if type(a)~="table" then return a==b end
  if a.GetObjectType or b.GetObjectType then return false end
  if #a~=#b then return false end
  for i=1,#a do if not equal(a[i],b[i]) then return false end end
  return true
end
-- This module owns texture/atlas/coordinates and hit insets explicitly. They
-- are not supported by basicUI's geometry Write/Release. Read every component
-- through the public API helper before making a snapshot or comparing it.
local function read(f,key)
  if key=="texture" then
    local ts,t=KHQOL.ReadPublicAPI(f.GetTexture,f)
    local as,a=KHQOL.ReadPublicAPI(f.GetAtlas,f)
    local cs,x1,x2,x3,x4,x5,x6,x7,x8=KHQOL.ReadPublicAPI(f.GetTexCoord,f)
    if ts~="ok" or (as~="ok" and as~="missing") or cs~="ok" then return end
    for _,v in ipairs({x1,x2,x3,x4}) do if type(v)~="number" or v~=v or math.abs(v)==math.huge then return end end
    if x1==nil or x2==nil or x3==nil or x4==nil then return end
    return {a or false,t or false,{x1,x2,x3,x4,x5,x6,x7,x8}}
  elseif key=="hit" then
    local status,l,r,t,b=KHQOL.ReadPublicAPI(f.GetHitRectInsets,f)
    if status~="ok" or not finite(l) or not finite(r) or not finite(t) or not finite(b) then return end
    return {l,r,t,b}
  elseif key=="justify" then return call(f.GetJustifyH,f) end
end
local function set(f,key,v)
  if key=="texture" then
    if v[1] then
      if KHQOL.ReadPublicAPI(f.SetAtlas,f,v[1],false)~="ok" then return false end
    elseif KHQOL.ReadPublicAPI(f.SetTexture,f,v[2] or nil)~="ok" then return false end
    return KHQOL.ReadPublicAPI(f.SetTexCoord,f,unpack(v[3]))=="ok"
  elseif key=="hit" then return KHQOL.ReadPublicAPI(f.SetHitRectInsets,f,unpack(v))=="ok"
  elseif key=="justify" then return KHQOL.ReadPublicAPI(f.SetJustifyH,f,v)=="ok" end
end
function M:WriteDecor(owner,f,key,value)
  if not f then return true end
  local current=read(f,key)
  if current==nil then self.propertyDeferred=true; self.pending=true; return false end
  owner.decor=owner.decor or {}; owner.decor[f]=owner.decor[f] or {}
  local record=owner.decor[f][key]
  if not record then record={original=current}; owner.decor[f][key]=record
  elseif not equal(current,record.last) then record.original=current end
  if not equal(current,value) and not set(f,key,value) then self.propertyDeferred=true; self.pending=true; return false end
  record.last=read(f,key) or value
  return true
end
function M:ReleaseDecor(owner)
  for f,keys in pairs(owner.decor or {}) do
    for key,record in pairs(keys) do
      local current=read(f,key)
      if current==nil then self.propertyDeferred=true; self.pending=true
      elseif not equal(current,record.last) or set(f,key,record.original) then keys[key]=nil
      else self.propertyDeferred=true; self.pending=true end
    end
    if not next(keys) then owner.decor[f]=nil end
  end
end
function M:CanDecor(f,key)
  if not f then return true end
  if read(f,key)~=nil then return true end
  self.propertyDeferred=true; self.pending=true; return false
end
function M:CanRectangular(p)
  return self:CanDecor(p.root,"hit") and self:CanDecor(p.name,"justify") and self:CanDecor(p.level,"justify")
    and self:CanDecor(p.healthContainer.HealthBarMask,"texture") and self:CanDecor(p.power.ManaBarMask,"texture")
    and (not p.name or B:CanRead(p.name,"points")) and (not p.level or B:CanRead(p.level,"points"))
end
local function squareTexture(self,owner,t)
  return self:WriteDecor(owner,t,"texture",{false,WHITE,{0,0,0,1,1,0,1,1}})
end
function M:SquareMask(owner,mask,bar,width,height)
  if not mask then return end
  squareTexture(self,owner,mask)
  self:Write(owner,mask,"points",{{"TOPLEFT",bar,"TOPLEFT",0,0}})
  self:Write(owner,mask,"width",width); self:Write(owner,mask,"height",height)
end
function M:ApplyRectangular(owner,p,hh,ph,width)
  -- Keep native mask attachments and prediction widths; change only mask
  -- imagery and bounds. Never calculate healing/absorb values ourselves.
  -- Native atlas fills carry their own colors, particularly for resources.
  -- Keep native fills in default mode; make the masks rectangular instead of
  -- substituting a white fill that would lose the native atlas's health hue.
  -- Custom health colors own a separate white texture record below.
  self:SquareMask(owner,p.healthContainer.HealthBarMask,p.healthContainer,width,hh)
  self:SquareMask(owner,p.power.ManaBarMask,p.power,width,ph)
  -- Resource atlases are already color encoded. Keep their texture/color;
  -- the native mask, bounds and prediction attachments are now rectangular.
  for _,key in ipairs({"PlayerFrameHealthBarAnimatedLoss","PlayerFrameTempMaxHealthLoss"}) do
    local bar=p.healthContainer[key]
    if bar then self:Write(owner,bar,"height",hh) end
  end
  self:WriteDecor(owner,p.root,"hit",{16,16,24,24})
end
function M:ApplyPlayerLabels(owner,p,db,showPower)
  for _,kind in ipairs({"name","level"}) do
    local f=p[kind]; local right=kind=="level"
    local side=right and "RIGHT" or "LEFT"
    local position=db[kind.."Position"]
    local x=number(db[kind.."X"],0,-100,100)+(right and -4 or 4)
    local y=number(db[kind.."Y"],0,-100,100)
    local point,relative,rp
    if position=="inside" then point=side; relative=p.health; rp=side
    elseif position=="below" then point="TOP"..side; relative=showPower and p.power or p.health; rp="BOTTOM"..side; y=y-2
    else point="TOP"..side; relative=p.health; rp="TOP"..side; y=y+14 end
    self:Write(owner,f,"points",{{point,relative,rp,x,y}})
    self:WriteDecor(owner,f,"justify",side)
  end
end
function M:ResetLabel(kind)
  if kind~="name" and kind~="level" then return end
  local db=self:GetDB().player; local defaults=self.defaults.player
  for _,suffix in ipairs({"Position","X","Y"}) do db[kind..suffix]=defaults[kind..suffix] end
  self:ApplySettings()
end
-- Pet and target-of-target use separate, smaller native schemas. Require
-- existing bars/name/portrait rather than pretending they have Player content.
function M:AuxiliaryParts(unit)
  local root,health,power,name,portrait,decoration,hm,pm
  if unit=="pet" then
    root=_G.PetFrame; if not root then return end
    health=root.healthbar or _G.PetFrameHealthBar
    power=root.manabar or _G.PetFrameManaBar
    name=_G.PetName or root.Name; portrait=root.Portrait or _G.PetPortrait
    decoration=root.FrameTexture or _G.PetFrameTexture
    hm=_G.PetFrameHealthBarMask or (health and health.HealthBarMask)
    pm=_G.PetFrameManaBarMask or (power and power.ManaBarMask)
  else
    root=_G.TargetFrame and _G.TargetFrame.totFrame or _G.TargetFrameToT
    if not root then return end
    health=root.HealthBar or root.healthbar; power=root.ManaBar or root.manabar
    name=root.Name or _G.TargetFrameToTTextureFrameName
    portrait=root.Portrait or _G.TargetFrameToTPortrait
    decoration=root.FrameTexture or _G.TargetFrameToTTextureFrameTexture
    hm=health and health.HealthBarMask; pm=power and power.ManaBarMask
  end
  if not health or not power or not name or not portrait or not decoration then return end
  if call(health.GetObjectType,health)~="StatusBar" or call(power.GetObjectType,power)~="StatusBar" then return end
  return {root=root,health=health,power=power,name=name,portrait=portrait,decoration=decoration,
    healthMask=hm,powerMask=pm,auxiliary=true}
end
function M:ApplyAuxiliary(owner,p,unit,on)
  if combat() then self.pending=true; return end
  if not on then self:Release(owner); self:ReleaseDecor(owner); if owner.background then owner.background:Hide() end; return end
  if not self:CanDecor(p.root,"hit") or not self:CanDecor(p.healthMask,"texture") or not self:CanDecor(p.powerMask,"texture") then return end
  for _,f in ipairs({p.root,p.health,p.power,p.name}) do
    if not B:CanRead(f,"width") or not B:CanRead(f,"height") or not B:CanRead(f,"points") then self.pending=true; self.propertyDeferred=true; return end
  end
  local width=120
  self:Write(owner,p.root,"width",128); self:Write(owner,p.root,"height",45)
  self:Write(owner,p.portrait,"alpha",0); self:Write(owner,p.decoration,"alpha",0)
  self:Write(owner,p.name,"points",{{"TOPLEFT",p.root,"TOPLEFT",4,-2}}); self:Write(owner,p.name,"width",width)
  self:Write(owner,p.health,"points",{{"TOPLEFT",p.root,"TOPLEFT",4,-16}})
  self:Write(owner,p.health,"width",width); self:Write(owner,p.health,"height",16)
  self:Write(owner,p.power,"points",{{"TOPLEFT",p.health,"BOTTOMLEFT",0,-2}})
  self:Write(owner,p.power,"width",width); self:Write(owner,p.power,"height",8)
  self:SquareMask(owner,p.healthMask,p.health,width,16); self:SquareMask(owner,p.powerMask,p.power,width,8)
  self:WriteDecor(owner,p.root,"hit",{0,0,0,0})
  if not owner.background then owner.background=p.root:CreateTexture(nil,"BACKGROUND",nil,-8); owner.background:SetColorTexture(.04,.04,.04,.85) end
  owner.background:ClearAllPoints(); owner.background:SetPoint("TOPLEFT",p.root,"TOPLEFT",4,-2); owner.background:SetSize(width,40); owner.background:Show()
  -- Do not hide the pet attack/happiness/status indicators or touch secure
  -- attributes, root anchors, visibility scripts, timers, debuffs or clicks.
end
local function colorValues(bar)
  local status,r,g,b,a=KHQOL.ReadPublicAPI(bar.GetStatusBarColor,bar)
  if status~="ok" or not finite(r) or not finite(g) or not finite(b) or (a~=nil and not finite(a)) then return end
  return {r,g,b,a or 1}
end
function M:HealthColor(db,unit)
  local mode=db.healthColorMode
  if mode=="custom" then
    local c=type(db.healthColor)=="table" and db.healthColor or {}
    return number(c.r,0,0,1),number(c.g,1,0,1),number(c.b,0,0,1)
  elseif mode=="red" and unit=="target" then return 1,0,0
  elseif mode=="class" and unit=="player" then
    local _,class=call(UnitClass,"player")
    if type(class)~="string" then return end
    local c=RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if not c then return end
    local ok,r,g,b=pcall(function() return c.r,c.g,c.b end)
    if ok and public(r) and public(g) and public(b) and finite(r) and finite(g) and finite(b) then return r,g,b end
  end
end
function M:ApplyHealthColor(owner,p,unit)
  if owner.colorWriting then return end
  local bar=p.health
  if not owner.colorHook and type(bar.SetStatusBarColor)=="function" then
    owner.colorHook=true
    hooksecurefunc(bar,"SetStatusBarColor",function()
      -- Observe native/external updates without immediately writing back from
      -- this setter. Reapply only after native update functions/events finish.
      if owner.colorWriting or not owner.colorActive then return end
      owner.nativeColor=colorValues(bar)
    end)
  end
  local r,g,b
  if self:IsEnabled() and not editing() then r,g,b=self:HealthColor(self:GetDB()[unit],unit) end
  if r then
    if not owner.colorActive then owner.nativeColor=colorValues(bar); if not owner.nativeColor then self.pending=true; self.propertyDeferred=true; return end end
    owner.colorActive=true; owner.colorDecor=owner.colorDecor or {}
    local texture=call(bar.GetStatusBarTexture,bar)
    if not texture or not squareTexture(self,owner.colorDecor,texture) then self.pending=true; self.propertyDeferred=true; return end
    owner.colorWriting=true
    local status=KHQOL.ReadPublicAPI(bar.SetStatusBarColor,bar,r,g,b,1)
    owner.colorWriting=false
    if status=="ok" then owner.lastColor={r,g,b,1} end
  elseif owner.colorActive then
    owner.colorActive=false; owner.colorWriting=true
    self:ReleaseDecor(owner.colorDecor or {})
    local current=colorValues(bar)
    -- Only restore if the bar still contains our last write. A newer external
    -- color is left alone. nativeColor is refreshed on every native setter.
    if not current then
      owner.colorWriting=false; owner.colorActive=true; self.pending=true; self.propertyDeferred=true; return
    end
    if equal(current,owner.lastColor) and owner.nativeColor then
      KHQOL.ReadPublicAPI(bar.SetStatusBarColor,bar,unpack(owner.nativeColor))
    end
    owner.colorWriting=false
    if type(UnitFrameHealthBar_Update)=="function" then pcall(UnitFrameHealthBar_Update,bar,unit) end
  elseif owner.colorDecor then self:ReleaseDecor(owner.colorDecor)
  end
end
function M:UpdateUnitValues(unit)
  local owner=self.units and self.units[unit]; if not owner or owner.parts.auxiliary then return end
  local p=owner.parts
  self:ApplyHealthColor(owner,p,unit)
  self:UpdateBarText(owner,p.health,unit,"health"); self:UpdateBarText(owner,p.power,unit,"power")
end
function M:BottomFrame()
  local f=_G.TotemFrame
  -- Screenshot matches the native round TotemButton + Duration arrangement.
  -- Confirm the native API/mixin and PlayerFrame parent at runtime. Other HUD
  -- containers and custom summon trackers are deliberately not candidates.
  if not f or call(f.GetParent,f)~=_G.PlayerFrame or type(GetTotemInfo)~="function" then return end
  if not (type(f.Update)=="function" or type(TotemFrame_Update)=="function") then return end
  return f
end
function M:ApplyBottom()
  if self.bottomApplying then return end
  self.bottomApplying=true
  local ok,err=pcall(self.ApplyBottomNow,self)
  self.bottomApplying=false
  if not ok then error(err,0) end
end
function M:ApplyBottomNow()
  if combat() then self.pending=true; return end
  local f=self:BottomFrame(); self.bottomOwner=self.bottomOwner or {}
  local owner=self.bottomOwner
  if not f then if owner.frame then self:Release(owner) end; return end
  owner.frame=f
  if not owner.hooked then
    owner.hooked=true
    f:HookScript("OnShow",function() if M:IsEnabled() then M:ApplyBottom() end end)
    if type(f.Update)=="function" then hooksecurefunc(f,"Update",function() if M:IsEnabled() then M:ApplyBottom() end end) end
  end
  local db=self:GetDB().player
  local x,y=number(db.bottomX,0,-100,100),number(db.bottomY,0,-100,100)
  if not self:IsEnabled() or editing() or not db.compact or (x==0 and y==0) then self:Release(owner); return end
  local count=call(f.GetNumPoints,f); if type(count)~="number" or count<1 or count>32 then self.pending=true; self.propertyDeferred=true; return end
  local points={}
  for i=1,count do
    local status,point,relative,rp,px,py=KHQOL.ReadPublicAPI(f.GetPoint,f,i)
    if status~="ok" or not finite(px) or not finite(py) then self.pending=true; self.propertyDeferred=true; return end
    points[i]={point,relative,rp,px,py}
  end
  local record=owner.records and owner.records[f] and owner.records[f].points
  local baseline=record and equal(points,record.last) and record.original or points
  local shifted={}
  for i,p in ipairs(baseline) do shifted[i]={p[1],p[2],p[3],p[4]+x,p[5]+y} end
  self:Write(owner,f,"points",shifted)
end
function M:InitializeDecorHooks()
  self.decorHooks=self.decorHooks or {}
  -- Native function post-hooks avoid competing on each color setter and never
  -- replace a Blizzard function. Hooks are registered at most once.
  for _,name in ipairs({"UnitFrameHealthBar_Update","UnitFrameHealthBar_OnValueChanged"}) do
    if type(_G[name])=="function" and not self.decorHooks[name] then
      self.decorHooks[name]=true
      hooksecurefunc(name,function(bar)
        if not M:IsEnabled() then return end
        for _,unit in ipairs({"player","target"}) do
          local owner=M.units and M.units[unit]
          if owner and owner.parts.health==bar then M:ApplyHealthColor(owner,owner.parts,unit); break end
        end
      end)
    end
  end
  if type(PlayerFrame_AdjustAttachments)=="function" and not self.decorHooks.bottom then
    self.decorHooks.bottom=true
    hooksecurefunc("PlayerFrame_AdjustAttachments",function() if M:IsEnabled() then M:ApplyBottom() end end)
  end
end
