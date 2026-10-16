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
  elseif key=="font" then
    local status,path,size,flags=KHQOL.ReadPublicAPI(f.GetFont,f)
    if status=="ok" and (type(path)=="string" or type(path)=="number") and finite(size) then return {path,size,flags or ""} end
  elseif key=="shadowColor" then
    local status,r,g,b,a=KHQOL.ReadPublicAPI(f.GetShadowColor,f)
    if status=="ok" and finite(r) and finite(g) and finite(b) and finite(a) then return {r,g,b,a} end
  elseif key=="shadowOffset" then
    local status,x,y=KHQOL.ReadPublicAPI(f.GetShadowOffset,f)
    if status=="ok" and finite(x) and finite(y) then return {x,y} end
  elseif key=="justify" then return call(f.GetJustifyH,f) end
end
local function set(f,key,v)
  if key=="texture" then
    if v[1] then
      if KHQOL.ReadPublicAPI(f.SetAtlas,f,v[1],false)~="ok" then return false end
    elseif KHQOL.ReadPublicAPI(f.SetTexture,f,v[2] or nil)~="ok" then return false end
    return KHQOL.ReadPublicAPI(f.SetTexCoord,f,unpack(v[3]))=="ok"
  elseif key=="hit" then return KHQOL.ReadPublicAPI(f.SetHitRectInsets,f,unpack(v))=="ok"
  elseif key=="font" then return KHQOL.ReadPublicAPI(f.SetFont,f,unpack(v))=="ok"
  elseif key=="shadowColor" then return KHQOL.ReadPublicAPI(f.SetShadowColor,f,unpack(v))=="ok"
  elseif key=="shadowOffset" then return KHQOL.ReadPublicAPI(f.SetShadowOffset,f,unpack(v))=="ok"
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
  if equal(current,record.last) and equal(value,record.requested) then return true end
  if not equal(current,value) and not set(f,key,value) then self.propertyDeferred=true; self.pending=true; return false end
  record.last=read(f,key) or value
  record.requested=value
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
function M:ReleaseFont(owner,f)
  local keys=owner.decor and owner.decor[f]
  if keys and keys.font then
    local isolated={decor={[f]={font=keys.font}}}
    self:ReleaseDecor(isolated)
    if not isolated.decor[f] or not isolated.decor[f].font then keys.font=nil end
  end
  local geometry=owner.records and owner.records[f]
  if geometry and geometry.height then
    local isolated={records={[f]={height=geometry.height}}};self:Release(isolated)
    if not isolated.records or not isolated.records[f] or not isolated.records[f].height then geometry.height=nil end
  end
end
function M:CanDecor(f,key)
  if not f then return true end
  if read(f,key)~=nil then return true end
  self.propertyDeferred=true; self.pending=true; return false
end
function M:HealthTextFlags(flags)
  flags=type(flags)=="string" and flags or ""
  return flags:find("MONOCHROME",1,true) and "THICKOUTLINE,MONOCHROME" or "THICKOUTLINE"
end
function M:ApplyHealthTextContrast(owner,bar,unit)
  local cfg=self:GetDB()[unit]
  local active=self:IsEnabled() and not editing() and (owner.compactActive or cfg.healthColorMode~="default")
  local state=owner.healthTextStyle
  if not active then if state and not combat() then self:ReleaseDecor(state) end;return end
  if combat() then self.pending=true;return end
  if not state then state={};owner.healthTextStyle=state end
  for _,key in ipairs({"TextString","LeftText","RightText","HealthBarText"}) do
    local text=bar[key]
    if text then
      local font=read(text,"font")
      if font then self:WriteDecor(state,text,"font",{font[1],font[2],self:HealthTextFlags(font[3])}) end
      if read(text,"shadowColor") then self:WriteDecor(state,text,"shadowColor",{0,0,0,1}) end
      if read(text,"shadowOffset") then self:WriteDecor(state,text,"shadowOffset",{1,-1}) end
    end
  end
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
    healthMask=hm,powerMask=pm,healthContainer=health,
    level=root.LevelText or root.levelText,hitText=unit=="pet" and _G.PetHitIndicator or nil,
    nativeThreat=root.threatIndicator or (unit=="pet" and _G.PetFrameFlash),
    attackTexture=unit=="pet" and _G.PetAttackModeTexture or nil,auxiliary=true}
end
-- These packets are opaque restoration data, not readable color/UV values.
-- GetStatusBarColor/GetTexCoord can return secrets; their C setters explicitly
-- accept secrets while tainted. Never compare or calculate packet contents.
local function packet(fn,...)
  if type(fn)~="function" then return end
  local function pack(...) return {n=select("#",...),...} end
  local result=pack(pcall(fn,...));if not result[1] then return end
  local values={n=result.n-1}
  for i=2,result.n do values[i-1]=result[i] end
  return values
end
local function colorValues(bar)
  local values=packet(bar.GetStatusBarColor,bar)
  if not values or values.n<3 then return end
  for i=1,3 do if type(values[i])~="number" then return end end
  return values
end
local function fillValues(texture)
  local atlas=call(texture.GetAtlas,texture)
  local asset=call(texture.GetTexture,texture)
  local coords=packet(texture.GetTexCoord,texture)
  if not atlas and not asset or not coords or coords.n~=4 and coords.n~=8 then return end
  for i=1,coords.n do if type(coords[i])~="number" then return end end
  return {atlas=atlas,asset=asset,coords=coords}
end
local palette={green={0,161/255,24/255},yellow={245/255,190/255,0},red={217/255,79/255,56/255},hostile={134/255,0,0},gray={99/255,99/255,99/255}}
local classPalette=KHQOL.ClassColors
function M:FightingPlayer(unit)
  if call(UnitAffectingCombat,unit)~=true then return false end
  -- A creature fighting somebody else is not necessarily fighting this player.
  local threat=call(UnitThreatSituation,"player",unit)
  if finite(threat) and threat>=0 then return true end
  return call(UnitIsUnit,unit.."target","player")==true or call(UnitIsUnit,unit.."target","pet")==true
end
function M:HealthColor(db,unit)
  local mode=db.healthColorMode
  local conditionalUnit=unit=="target" or unit=="targettarget" or unit=="focus"
  if mode=="custom" then
    local c=type(db.healthColor)=="table" and db.healthColor or {}
    return number(c.r,0,0,1),number(c.g,1,0,1),number(c.b,0,0,1)
  elseif conditionalUnit then
    if mode~="reaction" then return unpack(palette.green) end
    local isPlayer=call(UnitIsPlayer,unit)
    if isPlayer==true then
      local r,g,b=self:ClassColor(unit);if r then return r,g,b end
      return unpack(palette.green)
    end
    if isPlayer~=false then return unpack(palette.green) end
    local reaction=call(UnitReaction,unit,"player")
    if finite(reaction) then
      if reaction>=5 then return unpack(palette.green) end
      if reaction==4 then
        -- Target-of-target keeps the explicit neutral/yellow policy.
        if unit~="targettarget" then
          if call(UnitIsTapDenied,unit)==true then return unpack(palette.gray) end
          if self:FightingPlayer(unit) then return unpack(palette.red) end
        end
        return unpack(palette.yellow)
      end
      if reaction>=1 then
        if call(UnitIsTapDenied,unit)==true then return unpack(palette.gray) end
        return unpack(unit=="target" and palette.hostile or palette.red)
      end
    end
    -- Missing or restricted disposition is not evidence of hostility.
    return unpack(palette.green)
  elseif mode=="class" then
    local r,g,b=self:ClassColor(unit);if r then return r,g,b end
  end
  if db.compact then
    if call(UnitIsConnected,unit)==false then return .5,.5,.5 end
    return 0,1,0 -- Native health atlas bakes green into its pixels.
  end
end
function M:ApplyBarColor(owner,bar,p,unit,kind,r,g,b)
  if owner.colorWriting then return end
  local function refresh()
    if kind=="health" then M:ApplyHealthColor(owner,p,unit)
    else M:CropNativeFill(p.owner,p.power,"power") end
  end
  if not owner.colorScriptHook and type(bar.HookScript)=="function" then
    owner.colorScriptHook=true
    -- XML may retain a native callback reference rather than looking up the
    -- globally hooked function. Follow the actual bar script as well, without
    -- touching its value, min/max, currValue or native text updater.
    bar:HookScript("OnValueChanged",function()
      if M:IsEnabled() then refresh() end
    end)
    bar:HookScript("OnShow",function()
      if M:IsEnabled() then refresh() end
    end)
  end
  if not owner.colorHook and type(bar.SetStatusBarColor)=="function" then
    owner.colorHook=true
    hooksecurefunc(bar,"SetStatusBarColor",function(_,...)
      if owner.colorWriting or not owner.colorActive then return end
      owner.nativeColor=colorValues(bar)
      owner.nativeVertex={n=select("#",...),...}
      if M:IsEnabled() then refresh() end
    end)
  end
  if r then
    local texture=call(bar.GetStatusBarTexture,bar)
    if not texture then return end
    if not owner.colorActive then
      owner.nativeColor=colorValues(bar);owner.nativeFill=fillValues(texture)
      owner.nativeVertex=packet(texture.GetVertexColor,texture)
      if not owner.nativeColor or not owner.nativeFill then self.pending=true;self.propertyDeferred=true;return end
    elseif owner.fillTexture~=texture then
      owner.nativeFill=fillValues(texture);owner.nativeVertex=packet(texture.GetVertexColor,texture)
    end
    if not owner.nativeFill then self.pending=true;return end
    owner.fillTexture=texture;owner.fillHooks=owner.fillHooks or {}
    if not owner.fillHooks[texture] then
      owner.fillHooks[texture]=true
      for _,method in ipairs({"SetTexture","SetAtlas"}) do
        if type(texture[method])=="function" then hooksecurefunc(texture,method,function()
          if owner.colorWriting or not owner.colorActive then return end
          if call(bar.GetStatusBarTexture,bar)~=texture then return end
          owner.nativeFill=fillValues(texture)
          if M:IsEnabled() then refresh() end
        end) end
      end
      if type(texture.SetVertexColor)=="function" then hooksecurefunc(texture,"SetVertexColor",function(_,...)
        if owner.colorWriting or not owner.colorActive then return end
        if call(bar.GetStatusBarTexture,bar)~=texture then return end
        -- Forward-only restoration packet. Do not inspect secret RGB values.
        owner.nativeVertex={n=select("#",...),...}
        if M:IsEnabled() then refresh() end
      end) end
    end
    owner.colorActive=true
    owner.colorWriting=true
    local ok=pcall(function()
      texture:SetTexture(WHITE);texture:SetTexCoord(0,1,0,1)
      bar:SetStatusBarColor(r,g,b,1)
      if texture.SetVertexColor then texture:SetVertexColor(r,g,b,1) end
    end)
    owner.colorWriting=false
    if ok then owner.lastColor={r,g,b,1} else self.pending=true;self.propertyDeferred=true end
  elseif owner.colorActive then
    owner.colorWriting=true
    local ok=pcall(function()
      local original=owner.nativeFill;local texture=owner.fillTexture
      if original and texture then
        if original.atlas then texture:SetAtlas(original.atlas,false) else texture:SetTexture(original.asset) end
        texture:SetTexCoord(unpack(original.coords,1,original.coords.n))
      end
      if owner.nativeColor then bar:SetStatusBarColor(unpack(owner.nativeColor,1,owner.nativeColor.n)) end
      if owner.nativeVertex and texture and texture.SetVertexColor then texture:SetVertexColor(unpack(owner.nativeVertex,1,owner.nativeVertex.n)) end
    end)
    owner.colorWriting=false
    if ok then owner.colorActive=false;owner.nativeFill=nil;owner.nativeColor=nil;owner.nativeVertex=nil
    else self.pending=true;self.propertyDeferred=true end
  end
end
function M:ApplyHealthColor(owner,p,unit)
  local r,g,b
  if self:IsEnabled() and not editing() then r,g,b=self:HealthColor(self:GetDB()[unit],unit) end
  self:ApplyBarColor(owner,p.health,p,unit,"health",r,g,b)
  if owner.healthDisplay and owner.compactActive and r then
    owner.healthDisplay:SetStatusBarColor(r,g,b,1)
    self:HideNativeDecoration(owner,call(p.health.GetStatusBarTexture,p.health))
  end
end
function M:UpdateUnitValues(unit)
  local owner=self.units and self.units[unit]; if not owner then return end
  local p=owner.parts
  self:ApplyHealthColor(owner,p,unit)
  self:ApplyLabelColors(owner,p,unit)
  self:SyncHealthDisplay(owner,p)
  self:UpdateBarText(owner,p.health,unit,"health"); self:UpdateBarText(owner,p.power,unit,"power")
end
function M:BottomFrame()
  local f=_G.TotemFrame
  -- Screenshot matches the native round TotemButton + Duration arrangement.
  -- Confirm the native API/mixin and PlayerFrame parent at runtime. Other HUD
  -- containers and custom summon trackers are deliberately not candidates.
  if not f or type(GetTotemInfo)~="function" then return end
  if not (type(f.Update)=="function" or type(TotemFrame_Update)=="function") then return end
  local parent=call(f.GetParent,f)
  for _=1,16 do
    if parent==_G.PlayerFrame then return f end
    if not parent or parent==UIParent then return end
    parent=call(parent.GetParent,parent)
  end
end
function M:ApplyBottom()
  if self.bottomApplying then return end
  self.bottomApplying=true
  local ok,err=pcall(self.ApplyBottomNow,self)
  self.bottomApplying=false
  if not ok then error(err,0) end
  self:RefreshBottomPreview()
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
  owner.layoutHooks=owner.layoutHooks or {}
  local parent=call(f.GetParent,f)
  for _=1,16 do
    if not parent or parent==UIParent or parent==PlayerFrame then break end
    if type(parent.Layout)=="function" and not owner.layoutHooks[parent] then
      owner.layoutHooks[parent]=true;hooksecurefunc(parent,"Layout",function() if M:IsEnabled() then M:ApplyBottom() end end)
    end
    parent=call(parent.GetParent,parent)
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
  for _,unit in ipairs({"target","focus"}) do
    local token=unit;local root=token=="target" and TargetFrame or FocusFrame
    if root and not self.decorHooks[root] then
      self.decorHooks[root]=true
      for _,method in ipairs({"CheckClassification","SetSmallSize"}) do
        if type(root[method])=="function" then hooksecurefunc(root,method,function() if M:IsEnabled() then M:ApplyUnits(token) end end) end
      end
    end
  end
  -- Native function post-hooks avoid competing on each color setter and never
  -- replace a Blizzard function. Hooks are registered at most once.
  for _,name in ipairs({"UnitFrameHealthBar_Update","UnitFrameHealthBar_OnValueChanged"}) do
    if type(_G[name])=="function" and not self.decorHooks[name] then
      self.decorHooks[name]=true
      hooksecurefunc(name,function(bar)
        if not M:IsEnabled() then return end
        for _,unit in ipairs(M.unitTokens) do
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

-- Read only the class token. UnitClass's localized name can be secret while
-- its token is public; rejecting all returns together loses a usable token.
function M:ClassToken(unit)
  local token=call(function()
    if type(UnitClassBase)=="function" then return (UnitClassBase(unit)) end
  end)
  if type(token)=="string" and token~="" then return token end
  token=call(function()
    if type(UnitClass)=="function" then local _,class=UnitClass(unit); return class end
  end)
  if type(token)=="string" and token~="" then return token end
end
function M:ClassColor(unit)
  local token=self:ClassToken(unit); if not token then return end
  if classPalette[token] then return unpack(classPalette[token]) end
  local function rgb(c)
    if not c then return end
    local r,g,b=call(function() return c.r,c.g,c.b end)
    if not finite(r) or not finite(g) or not finite(b) then
      r,g,b=call(function() if type(c.GetRGB)=="function" then return c:GetRGB() end end)
    end
    if finite(r) and finite(g) and finite(b) and r>=0 and r<=1 and g>=0 and g<=1 and b>=0 and b<=1 then return r,g,b end
  end
  local r,g,b=rgb(call(C_ClassColor and C_ClassColor.GetClassColor,token))
  if r then return r,g,b end
  return rgb(RAID_CLASS_COLORS and RAID_CLASS_COLORS[token])
end
function M:CropNativeFill(owner,bar,kind)
  if kind~="power" then return end
  local p=owner.parts;if not p then return end
  p.owner=owner;owner.powerStyle=owner.powerStyle or {}
  local r,g,b
  if owner.compactActive and self:IsEnabled() and not editing() then
    local token=call(function() local _,v=UnitPowerType(p.unit);return v end)
    local id=call(function() return (UnitPowerType(p.unit)) end)
    local color=PowerBarColor and (PowerBarColor[token] or PowerBarColor[id])
    if color then r,g,b=call(function() return color.r,color.g,color.b end) end
    if not finite(r) or not finite(g) or not finite(b) then r=nil end
  end
  self:ApplyBarColor(owner.powerStyle,bar,p,p.unit,"power",r,g,b)
end
function M:LabelSize(unit,kind)
  local saved=self:GetDB()[unit][kind.."Size"]
  if public(saved) and finite(saved) then return number(saved,12,8,30) end
  local p=self:UnitParts(unit); local f=p and p[kind]
  local _,size=call(f and f.GetFont,f)
  return finite(size) and number(size,12,8,30) or 12
end
function M:ApplyLabelColors(owner,p,unit)
  if unit~="player" and unit~="target" then return end
  owner.labelColors=owner.labelColors or {}
  local db=self:GetDB()[unit]
  for _,kind in ipairs({"name","level"}) do
    local f=p[kind]
    if f and type(f.SetTextColor)=="function" then
      local state=owner.labelColors[f] or {};owner.labelColors[f]=state
      if not state.hooked then
        state.hooked=true
        hooksecurefunc(f,"SetTextColor",function(_,...)
          if state.writing or not state.active then return end
          state.original={n=select("#",...),...}
          M:ApplyLabelColors(owner,owner.parts,unit)
        end)
      end
      local active=self:IsEnabled() and not editing() and db[kind.."ColorMode"]=="custom"
      if active and not state.active then state.original=packet(f.GetTextColor,f);active=state.original~=nil end
      state.writing=true
      if active then
        local c=db[kind.."Color"] or {};state.active=true
        pcall(f.SetTextColor,f,number(c.r,1,0,1),number(c.g,1,0,1),number(c.b,1,0,1),1)
      elseif state.active then
        if pcall(f.SetTextColor,f,unpack(state.original,1,state.original.n)) then state.active=false;state.original=nil end
      end
      state.writing=false
    end
  end
end
function M:ApplyLabels(owner,p,unit,width,showPower)
  if owner.labelWriting then return end
  if combat() then self.pending=true;return end
  owner.labelHooks=owner.labelHooks or {}
  for _,kind in ipairs({"name","level"}) do
    local f=p[kind]
    if f and not owner.labelHooks[f] then
      owner.labelHooks[f]=true
      local function refresh()
        if owner.labelWriting or not owner.compactActive or not M:IsEnabled() then return end
        if combat() then M.pending=true;return end
        local width,_,_,_,_,power=M:CompactLayout(M:GetDB()[unit])
        M:ApplyLabels(owner,p,unit,width,power)
      end
      for _,method in ipairs({"SetPoint","SetWidth","SetJustifyH","SetFont"}) do
        if type(f[method])=="function" then hooksecurefunc(f,method,refresh) end
      end
    end
  end
  owner.labelWriting=true
  local ok,err=pcall(self.ApplyLabelsNow,self,owner,p,unit,width,showPower)
  owner.labelWriting=false
  if not ok then error(err,0) end
end
function M:ApplyLabelsNow(owner,p,unit,width,showPower)
  local db=self:GetDB()[unit]
  local health=owner.healthDisplay or p.health
  for _,kind in ipairs({"name","level"}) do
    local f=p[kind]
    if f then
      local side=db[kind.."Side"]=="RIGHT" and "RIGHT" or "LEFT"
      local pos=db[kind.."Position"]
      local x=number(db[kind.."X"],0,-100,100)
      local y=number(db[kind.."Y"],0,-100,100)
      local point,relative,rp
      if pos=="left" then point="RIGHT"; relative=health;rp="LEFT";side="RIGHT";x=x-4
      elseif pos=="right" then point="LEFT";relative=health;rp="RIGHT";side="LEFT";x=x+4
      else
        if kind~="name" or pos=="inside" then x=x+(side=="RIGHT" and -4 or 4) end
        if pos=="inside" then point=side;relative=health;rp=side
        elseif pos=="below" then point="TOP"..side;relative=showPower and p.power or health;rp="BOTTOM"..side;y=y-2
        else point="BOTTOM"..side;relative=health;rp="TOP"..side;y=y+2 end
      end
      self:Write(owner,f,"points",{{point,relative,rp,x,y}})
      self:WriteDecor(owner,f,"justify",side)
      if kind=="name" then
        local reserve=(pos=="above" or pos=="below") and 0 or 8
        if p.level and db.namePosition==db.levelPosition and db.nameSide~=db.levelSide then
          reserve=math.max(42,self:LabelSize(unit,"level")*3+8)
        end
        self:Write(owner,f,"width",math.max(20,width-reserve))
      end
      if db[kind.."Size"]~=nil then
        local native=read(f,"font")
        if native then
          local size=self:LabelSize(unit,kind)
          self:WriteDecor(owner,f,"font",{native[1],size,native[3]})
          self:Write(owner,f,"height",size+4)
        end
      else self:ReleaseFont(owner,f) end
    end
  end
  if p.context and p.context.HighLevelTexture and p.level then
    self:Write(owner,p.context.HighLevelTexture,"points",{{"CENTER",p.level,"CENTER",0,0}})
  end
end
function M:ApplyOutline(owner,p,width,hh,ph,gap,showPower)
  if not owner.outline then
    owner.outline={}
    for i=1,8 do
      local t=p.root:CreateTexture(nil,"OVERLAY",nil,6);t:SetColorTexture(.06,.06,.06,1)
      if type(t.SetSnapToPixelGrid)=="function" then t:SetSnapToPixelGrid(true) end
      if type(t.SetTexelSnappingBias)=="function" then t:SetTexelSnappingBias(0) end
      owner.outline[i]=t
    end
  end
  local scale=call(p.root.GetEffectiveScale,p.root)
  local px=finite(scale) and scale>0 and 1/scale or 1
  for index,bar in ipairs({owner.healthDisplay or p.health,p.power}) do
    local height=index==1 and hh or ph
    local a,b,c,d=unpack(owner.outline,(index-1)*4+1,index*4)
    for _,t in ipairs({a,b,c,d}) do t:ClearAllPoints();t:SetShown(self:GetDB()[p.unit].borderStyle=="thin" and (index==1 or showPower)) end
    a:SetPoint("TOPLEFT",bar,"TOPLEFT",0,0);a:SetSize(width,px)
    b:SetPoint("BOTTOMLEFT",bar,"BOTTOMLEFT",0,0);b:SetSize(width,px)
    c:SetPoint("TOPLEFT",bar,"TOPLEFT",0,0);c:SetSize(px,height)
    d:SetPoint("TOPRIGHT",bar,"TOPRIGHT",0,0);d:SetSize(px,height)
  end
end
function M:HideNativeDecoration(owner,f)
  if not f or owner.artWriting then return end
  owner.artHooks=owner.artHooks or {};owner.artAlpha=owner.artAlpha or {}
  if not owner.artAlpha[f] then
    local original=packet(f.GetAlpha,f)
    if not original or original.n~=1 or type(original[1])~="number" then self.pending=true;return end
    owner.artAlpha[f]=original
  end
  if not owner.artHooks[f] then
    owner.artHooks[f]=true
    local function changed(capture)
      if not owner.compactActive or owner.artWriting or not M:IsEnabled() then return end
      if capture then
        local current=packet(f.GetAlpha,f)
        if current and current.n==1 and type(current[1])=="number" then owner.artAlpha[f]=current end
      end
      owner.artWriting=true;pcall(f.SetAlpha,f,0);owner.artWriting=false
    end
    if type(f.SetAlpha)=="function" then hooksecurefunc(f,"SetAlpha",function() changed(true) end) end
    -- Vertex tint and base opacity can be independent. Hide after its pulse,
    -- but never replace the saved base opacity with our already-hidden zero.
    if call(f.GetObjectType,f)=="Texture" and type(f.SetVertexColor)=="function" then hooksecurefunc(f,"SetVertexColor",function() changed(false) end) end
  end
  owner.artWriting=true
  local ok=pcall(f.SetAlpha,f,0);owner.artWriting=false
  if not ok then self.pending=true;self.propertyDeferred=true end
end
function M:ReleaseNativeDecorations(owner)
  owner.artWriting=true
  for f,original in pairs(owner.artAlpha or {}) do
    if pcall(f.SetAlpha,f,unpack(original,1,original.n)) then owner.artAlpha[f]=nil
    else self.pending=true;self.propertyDeferred=true end
  end
  owner.artWriting=false
end
function M:ApplyStateDecorations(owner,p,unit)
  if not owner.compactActive or not self:IsEnabled() then return end
  if p.main then self:HideNativeDecoration(owner,p.main.StatusTexture);self:HideNativeDecoration(owner,p.main.HitIndicator) end
  self:HideNativeDecoration(owner,p.nativeThreat or p.root.threatIndicator or p.container and (p.container.FrameFlash or p.container.Flash))
  self:HideNativeDecoration(owner,p.attackTexture)
  -- The native loss animation starts at the previous total health and can
  -- cover the entire solid fill for 0.4 seconds. Its timing/value logic stays
  -- native; only its presentation is suppressed while compact is active.
  if unit=="player" then self:HideNativeDecoration(owner,p.health.AnimatedLossBar or p.healthContainer.PlayerFrameHealthBarAnimatedLoss) end
  if p.hitText then self:HideNativeDecoration(owner,p.hitText) end
  if unit=="player" and p.context then
    self:HideNativeDecoration(owner,p.context.PlayerPortraitCornerIcon)
  end
  if unit=="target" and p.context then
    self:HideNativeDecoration(owner,p.context.QuestIcon)
    self:HideNativeDecoration(owner,p.context.RareIcon)
  end
  if owner.raidMarker then self:UpdatePlayerMarker(owner,p) end
end
function M:ApplyCombo(owner,p,unit)
  if unit~="target" then return end
  owner.comboOwner=owner.comboOwner or {}
  local f=_G.ComboFrame
  local active=self:IsEnabled() and owner.compactActive and self:GetDB().target.hideDefaultCombo and
    f and call(f.GetParent,f)==p.root
  owner.comboHidden=active and true or false
  if not active then self:Release(owner.comboOwner);return end
  if not owner.comboHook then
    owner.comboHook=true
    hooksecurefunc(f,"SetAlpha",function()
      if not owner.comboHidden or owner.comboWriting or not M:IsEnabled() then return end
      owner.comboWriting=true;M:Write(owner.comboOwner,f,"alpha",0);owner.comboWriting=false
    end)
  end
  owner.comboWriting=true;self:Write(owner.comboOwner,f,"alpha",0);owner.comboWriting=false
end
function M:ApplyCompactLayout(owner,p,unit,on)
  if combat() then self.pending=true;return end
  p.unit=unit
  if not on then
    owner.compactActive=false
    self:CompactThreat(owner,p,false)
    self:ReleaseNativeDecorations(owner)
    self:Release(owner);self:ReleaseDecor(owner)
    self:CropNativeFill(owner,p.power,"power")
    if owner.rectOwners then for _,state in pairs(owner.rectOwners) do self:ReleaseDecor(state) end end
    if owner.background then owner.background:Hide() end
    if owner.raidMarker then owner.raidMarker:Hide() end
    if owner.healthDisplay then owner.healthDisplay:Hide() end
    owner.healthVisibilityPending=nil
    for _,t in ipairs(owner.outline or {}) do t:Hide() end
    self:ApplyCombo(owner,p,unit);return
  end
  for _,f in ipairs({p.root,p.healthContainer,p.health,p.power}) do
    for _,key in ipairs({"width","height","points"}) do
      if not B:CanRead(f,key) then self.pending=true;self.propertyDeferred=true;return end
    end
  end
  local mirrored=unit=="target" or unit=="focus"
  if not self:CanDecor(p.root,"hit") or not mirrored and not self:CanDecor(p.healthMask,"texture") or not self:CanDecor(p.powerMask,"texture") then return end
  local db=self:GetDB()[unit]
  local width,height,gap,hh,ph,showPower=self:CompactLayout(db)
  local left,top=p.auxiliary and 4 or 16,p.auxiliary and -16 or -40
  owner.compactActive=true;owner.compactWidth=width;owner.compactHeight=height
  self:Write(owner,p.root,"width",width+(p.auxiliary and 8 or 32))
  self:Write(owner,p.root,"height",height+(p.auxiliary and 4 or 48))
  self:HideNativeDecoration(owner,p.portrait);self:HideNativeDecoration(owner,p.decoration)
  if p.container then
    for _,key in ipairs({"FrameTexture","VehicleFrameTexture","AlternatePowerFrameTexture","BossPortraitFrameTexture"}) do self:HideNativeDecoration(owner,p.container[key]) end
  end
  if p.main then
    self:Write(owner,p.main.LevelBackgroundCircle,"alpha",0)
    self:HideNativeDecoration(owner,p.main.ReputationColor)
    self:Write(owner,p.main.PvpBackgroundCircle,"points",{{"CENTER",p.root,"TOPLEFT",3,-30}})
  end
  if not mirrored then
    self:Write(owner,p.healthContainer,"points",{{"TOPLEFT",p.root,"TOPLEFT",left,top}})
    self:Write(owner,p.healthContainer,"width",width);self:Write(owner,p.healthContainer,"height",hh)
    if p.healthContainer~=p.health then self:Write(owner,p.health,"points",{{"TOPLEFT",p.healthContainer,"TOPLEFT",0,0}}) end
    self:Write(owner,p.health,"width",width);self:Write(owner,p.health,"height",hh)
  end
  if not p.auxiliary then
    for _,key in ipairs({"PlayerFrameHealthBarAnimatedLoss","PlayerFrameTempMaxHealthLoss"}) do
      if p.healthContainer[key] then self:Write(owner,p.healthContainer[key],"height",hh) end
    end
  end
  self:PrepareHealthDisplay(owner,p,unit,width,hh,left,top)
  self:Write(owner,p.power,"points",{{"TOPLEFT",owner.healthDisplay or p.healthContainer,"BOTTOMLEFT",0,-gap}})
  self:Write(owner,p.power,"width",width);self:Write(owner,p.power,"height",ph)
  if not owner.background then owner.background=p.root:CreateTexture(nil,"BACKGROUND",nil,-8);owner.background:SetColorTexture(.04,.04,.04,1) end
  owner.background:ClearAllPoints();owner.background:SetPoint("TOPLEFT",owner.healthDisplay or p.health,"TOPLEFT",0,0)
  owner.background:SetSize(width,hh);owner.background:SetAlpha(number(db.borderAlpha,.85,0,1));owner.background:Show()
  if not mirrored then self:SquareMask(owner,p.healthMask,p.healthContainer,width,hh) end
  self:SquareMask(owner,p.powerMask,p.power,width,ph)
  self:WriteDecor(owner,p.root,"hit",p.auxiliary and {0,0,0,0} or {16,16,24,24})
  self:ApplyLabels(owner,p,unit,width,showPower)
  self:ApplyOutline(owner,p,width,hh,ph,gap,showPower)
  self:CropNativeFill(owner,p.power,"power")
  self:ApplyStateDecorations(owner,p,unit)
  self:ApplyStatusPositions(owner,p,unit)
  self:CompactThreat(owner,p,false)
  self:ApplyCombo(owner,p,unit)
end
local shapeKeys={"width","height","healthHeight","powerHeight","showPower","gap","borderAlpha","borderStyle",
  "healthColorMode","healthColor","namePosition","nameSide","nameX","nameY","nameSize",
  "levelPosition","levelSide","levelX","levelY","levelSize","health","power","textSize",
  "nameColorMode","nameColor","levelColorMode","levelColor"}
function M:ResetShape(unit)
  local db=self:GetDB()[unit];if not db then return end
  for _,key in ipairs(shapeKeys) do
    local value=self.defaults[unit][key]
    db[key]=type(value)=="table" and KHQOL.MergeDefaults({},value,"tables") or value
  end
  self:ApplySettings()
end
function M:CopyPlayerShape(unit)
  if unit=="player" then return end
  local db=self:GetDB();local p=self:UnitParts(unit)
  for _,key in ipairs(shapeKeys) do
    -- Color policy remains unit-specific; do not copy an owner's class to a pet.
    if key~="healthColorMode" and key~="healthColor" and (key:sub(1,5)~="level" or p and p.level) then
      db[unit][key]=db.player[key]
    end
  end
  self:ApplySettings()
end
function M:EnergySupport()
  -- GetPowerRegen exposes a rate, not a natural-regeneration phase/source.
  -- Neither resource-change events nor a +20 delta identify natural ticks.
  -- No verified Forever timing API is available: preserve preference, create
  -- no timer/animation, and never manufacture a two-second server heartbeat.
  return false,"지원 보류: Forever의 자연 기력 회복 주기·기준 시점을 공개 API로 확인하지 못했습니다. 임의의 2초 표시를 만들지 않습니다."
end
function M:ApplyFramePosition(owner,p)
  if owner.positionWriting then return end
  if combat() then self.pending=true;return end
  owner.positionOwner=owner.positionOwner or {}
  if not owner.positionHook and type(p.root.SetPoint)=="function" then
    owner.positionHook=true
    hooksecurefunc(p.root,"SetPoint",function()
      if not owner.positionWriting and M:IsEnabled() then M:ApplyFramePosition(owner,owner.parts) end
    end)
  end
  local db=self:GetDB().targettarget
  local x,y=number(db.frameX,0,-1000,1000),number(db.frameY,0,-1000,1000)
  owner.positionWriting=true
  if not self:IsEnabled() or editing() or x==0 and y==0 then
    self:Release(owner.positionOwner)
  else
    local count=call(p.root.GetNumPoints,p.root);local points={}
    if type(count)~="number" or count<1 or count>32 then
      self.pending=true;self.propertyDeferred=true
    else
      for i=1,count do
        local status,point,relative,rp,px,py=KHQOL.ReadPublicAPI(p.root.GetPoint,p.root,i)
        if status~="ok" or not finite(px) or not finite(py) then points=nil;break end
        points[i]={point,relative,rp,px,py}
      end
      if points then
        local record=owner.positionOwner.records and owner.positionOwner.records[p.root] and owner.positionOwner.records[p.root].points
        local baseline=record and equal(points,record.last) and record.original or points
        local shifted={}
        for i,q in ipairs(baseline) do shifted[i]={q[1],q[2],q[3],q[4]+x,q[5]+y} end
        self:Write(owner.positionOwner,p.root,"points",shifted)
      else self.pending=true;self.propertyDeferred=true end
    end
  end
  owner.positionWriting=false
end
function M:PositionProxy()
  local p=self:UnitParts("targettarget")
  if not p or not self:IsEnabled() or combat() or editing() then return end
  local x,y=call(p.root.GetCenter,p.root)
  local scale=call(p.root.GetEffectiveScale,p.root);local parentScale=call(UIParent.GetEffectiveScale,UIParent)
  local w,h=call(p.root.GetSize,p.root)
  if not finite(x) or not finite(y) or not finite(scale) or not finite(parentScale) or parentScale<=0 or not finite(w) or not finite(h) then return end
  local ratio=scale/parentScale
  if ratio<=0 then return end
  if not self.positionProxy then self.positionProxy=CreateFrame("Frame",nil,UIParent);self.positionProxy:EnableMouse(false);self.positionProxy:Hide() end
  local proxy=self.positionProxy;proxy:ClearAllPoints();proxy:SetPoint("CENTER",UIParent,"BOTTOMLEFT",x*ratio,y*ratio);proxy:SetSize(w*ratio,h*ratio)
  return proxy,ratio
end
function M:UpdatePlayerMarker(owner,p)
  local marker=owner.raidMarker;if not marker then return end
  local index=call(GetRaidTargetIndex,p.unit or "player")
  if not owner.compactActive or not self:IsEnabled() or not finite(index) or index<1 or index>8 then marker:Hide();return end
  local column,row=(index-1)%4,math.floor((index-1)/4)
  marker:SetTexCoord(column/4,(column+1)/4,row/4,(row+1)/4);marker:Show()
end
function M:StatusOffset(unit,kind,axis)
  local db=self:GetDB()[unit]
  return number(db[kind..axis],0,-600,600)+number(db["status"..axis],0,-200,200)
end
function M:SetStatusOffset(unit,kind,axis,value)
  local db=self:GetDB()[unit]
  db[kind..axis]=KHQOL.PositionStore:Round(number(value,0,-400,400))-number(db["status"..axis],0,-200,200)
  self:ApplySettings()
end
function M:ResetStatusOffset(unit,kind)
  local db=self:GetDB()[unit]
  db[kind.."X"]=-number(db.statusX,0,-200,200);db[kind.."Y"]=-number(db.statusY,0,-200,200)
  self:ApplySettings()
end
function M:ApplyStatusPositions(owner,p,unit)
  if combat() then self.pending=true;return end
  local db=self:GetDB()[unit]
  local bar=owner.healthDisplay or p.health
  local function position(f,key,point,relativePoint,x,y)
    if not f then return end
    self:Write(owner,f,"points",{{point,bar,relativePoint,x+self:StatusOffset(unit,key,"X"),y+self:StatusOffset(unit,key,"Y")}})
  end
  if unit=="player" and p.context then
    local rest=p.context.PlayerRestLoop
    position(rest,"rest","TOPRIGHT","TOPLEFT",-2,14)
    self:Write(owner,rest,"width",14);self:Write(owner,rest,"height",14)
    if rest then self:Write(owner,rest.RestTexture,"width",14);self:Write(owner,rest.RestTexture,"height",14) end
    position(p.context.AttackIcon,"combat","TOP","BOTTOMLEFT",14,3)
  end
  local nativeMarker=p.context and p.context.RaidTargetIcon or p.root.RaidTargetIcon
  if nativeMarker then position(nativeMarker,"marker","BOTTOM","TOP",0,4)
  else
    if not owner.raidMarker then
      owner.raidMarker=p.root:CreateTexture(nil,"OVERLAY",nil,7)
      owner.raidMarker:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons");owner.raidMarker:SetSize(18,18)
    end
    local marker=owner.raidMarker;marker:ClearAllPoints()
    marker:SetPoint("BOTTOM",bar,"TOP",self:StatusOffset(unit,"marker","X"),4+self:StatusOffset(unit,"marker","Y"))
    self:UpdatePlayerMarker(owner,p)
  end
end
function M:SetLabelAnchor(unit,kind,suffix,value)
  if (kind~="name" and kind~="level") or (suffix~="Position" and suffix~="Side") then return end
  local db=self:GetDB()[unit];if not db then return end
  if db[kind..suffix]~=value then
    db[kind..suffix]=value
    if kind=="name" then db.nameX=0;db.nameY=0 end
  end
  self:ApplySettings()
end
function M:ResetLabel(kind,unit)
  unit=unit or "player";if kind~="name" and kind~="level" then return end
  local db=self:GetDB()[unit]
  for _,suffix in ipairs({"Position","Side","X","Y","Size"}) do db[kind..suffix]=self.defaults[unit][kind..suffix] end
  self:ApplySettings()
end
function M:StopBottomPreview()
  self.bottomPreviewParent=nil;self.bottomPreviewGeneration=nil
  if self.bottomPreview then self.bottomPreview:Hide() end
end
function M:SetBottomPreview(parent,on)
  self:StopBottomPreview()
  if on then self.bottomPreviewParent=parent;self.bottomPreviewGeneration=KHQOL.profileGeneration;self:RefreshBottomPreview() end
end
function M:RefreshBottomPreview()
  local parent=self.bottomPreviewParent
  if not parent then return end
  if not self:IsEnabled() or not self:GetDB().player.compact or editing() or
    self.bottomPreviewGeneration~=KHQOL.profileGeneration or call(parent.IsShown,parent)~=true then self:StopBottomPreview();return end
  local p=self:UnitParts("player");if not p or call(p.root.IsShown,p.root)~=true then self:StopBottomPreview();return end
  local frame=self.bottomPreview
  if not frame then
    frame=CreateFrame("Frame",nil,UIParent);self.bottomPreview=frame
    frame:EnableMouse(false);frame:SetFrameStrata("TOOLTIP")
    frame.edges={}
    for i=1,4 do local t=frame:CreateTexture(nil,"OVERLAY");t:SetColorTexture(.45,.85,.75,1);frame.edges[i]=t end
    local a,b,c,d=unpack(frame.edges)
    a:SetPoint("TOPLEFT");a:SetPoint("TOPRIGHT");a:SetHeight(1)
    b:SetPoint("BOTTOMLEFT");b:SetPoint("BOTTOMRIGHT");b:SetHeight(1)
    c:SetPoint("TOPLEFT");c:SetPoint("BOTTOMLEFT");c:SetWidth(1)
    d:SetPoint("TOPRIGHT");d:SetPoint("BOTTOMRIGHT");d:SetWidth(1)
    frame.marker=frame:CreateTexture(nil,"OVERLAY");frame.marker:SetColorTexture(1,.85,.3,1);frame.marker:SetSize(4,4);frame.marker:SetPoint("CENTER",frame,"TOPLEFT",0,0)
    frame.icon=frame:CreateTexture(nil,"ARTWORK");frame.icon:SetTexture("Interface\\Icons\\Spell_Nature_StoneClawTotem");frame.icon:SetSize(28,28);frame.icon:SetPoint("TOPLEFT",4,-4)
    frame.label=frame:CreateFontString(nil,"OVERLAY");frame.label:SetFont(KHQOL.UI:Font(),12,"OUTLINE");frame.label:SetPoint("BOTTOMLEFT",frame,"TOPLEFT",0,3)
  end
  local native=self:BottomFrame();local shown=native and call(native.IsShown,native)==true
  frame:ClearAllPoints()
  if shown then frame:SetAllPoints(native);frame.icon:Hide();frame.label:SetText(combat() and "토템 현재 위치 · 전투 후 이동" or "토템 현재 위치")
  else
    frame:SetSize(37,45);frame.icon:Show();frame.label:SetText("토템 위치 예시 · 실제 표시 아님")
    if native then frame:SetPoint("TOPLEFT",native,"TOPLEFT",0,0)
    else local db=self:GetDB().player;frame:SetPoint("TOPRIGHT",p.root,"BOTTOMRIGHT",number(db.bottomX,0,-100,100),20+number(db.bottomY,0,-100,100)) end
  end
  frame:Show()
end
