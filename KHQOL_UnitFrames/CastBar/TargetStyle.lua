local _,K=...
K = assert(_G.KHQOL, "Install and enable the KHQOL core addon.")
local C=K.modules.castBar
local U,B=K.modules.unitFrames,K.modules.basicUI
local call=K.PublicCall
local WHITE="Interface\\Buttons\\WHITE8X8"
function C:TargetStyleEnabled()
  return self:IsEnabled() and self:GetDB().targetPosition.enabled and
    call(EditModeManagerFrame and EditModeManagerFrame.IsShown,EditModeManagerFrame)~=true
end
local function color(frame)
  local status,r,g,b,a=K.ReadPublicAPI(frame.GetStatusBarColor,frame)
  if status=="ok" and K.IsPublicNumber(r) and K.IsPublicNumber(g) and K.IsPublicNumber(b) and K.IsPublicNumber(a) then return {r,g,b,a} end
end
local function same(a,b)
  if not a or not b then return false end
  for i=1,4 do if a[i]~=b[i] then return false end end
  return true
end
local function fill(texture)
  local ts,t=K.ReadPublicAPI(texture.GetTexture,texture)
  local ats,atlas=K.ReadPublicAPI(texture.GetAtlas,texture)
  local cs,a,b,c,d,e,f,g,h=K.ReadPublicAPI(texture.GetTexCoord,texture)
  if ts~="ok" or (ats~="ok" and ats~="missing") or cs~="ok" then return end
  if atlas~=nil and type(atlas)~="string" then return end
  if t~=nil and type(t)~="string" and not K.IsPublicNumber(t) then return end
  local coords={a,b,c,d,e,f,g,h}
  if #coords~=4 and #coords~=8 then return end
  for _,v in ipairs(coords) do if not K.IsPublicNumber(v) then return end end
  return {atlas=atlas,texture=t,coords=coords}
end
local function sameFill(a,b)
  if not a or not b or a.texture~=b.texture or a.atlas~=b.atlas or #a.coords~=#b.coords then return false end
  for i,v in ipairs(a.coords) do if v~=b.coords[i] then return false end end
  return true
end
local function writeFill(texture,value)
  local status
  if value.atlas then status=K.ReadPublicAPI(texture.SetAtlas,texture,value.atlas,false)
  else status=K.ReadPublicAPI(texture.SetTexture,texture,value.texture) end
  return status=="ok" and K.ReadPublicAPI(texture.SetTexCoord,texture,unpack(value.coords))=="ok"
end
function C:PaintTargetStyle(owner)
  if not owner or not owner.active or not self:TargetStyleEnabled() or owner.painting then return end
  owner.painting=true
  -- Only artwork is changed here. Native cast values, durations and private
  -- cast state are never read, compared, copied or replaced.
  local ok=pcall(function()
    local f=owner.frame;local db=self:GetDB().targetStyle;local current=color(f)
    if current and not same(current,owner.lastColor) then owner.originalColor=current end
    local texture=call(f.GetStatusBarTexture,f)
    if texture then
      local now=fill(texture)
      if now and not sameFill(now,owner.lastFill) then owner.originalFill=now end
      local desired={texture=self.textures[db.appearance.texture],coords={0,0,0,1,1,0,1,1}}
      -- A private native color/atlas is not a reason to interpret its value.
      -- Keep the last public restore snapshot and send only our own public
      -- artwork to the texture setter. Never use private cast data in Lua.
      if owner.originalFill and writeFill(texture,desired) then owner.lastFill=fill(texture) or desired end
    end
    local desired=owner.interrupted and db.appearance.interruptedColor or db.appearance.barColor
    if owner.originalColor and K.ReadPublicAPI(f.SetStatusBarColor,f,unpack(desired))=="ok" then owner.lastColor=color(f) or {unpack(desired)} end
  end)
  owner.painting=false
  if not ok then self.targetStylePending=true end
end
function C:ReleaseTargetStyle(owner)
  if not owner then return end
  owner.active=false
  if owner.background then owner.background:Hide() end
  B:Release(owner);U:ReleaseDecor(owner)
  local texture=call(owner.frame.GetStatusBarTexture,owner.frame)
  if texture and sameFill(fill(texture),owner.lastFill) and owner.originalFill then writeFill(texture,owner.originalFill) end
  if same(color(owner.frame),owner.lastColor) and owner.originalColor then
    K.ReadPublicAPI(owner.frame.SetStatusBarColor,owner.frame,unpack(owner.originalColor))
  end
  owner.lastColor=nil;owner.originalColor=nil;owner.lastFill=nil;owner.originalFill=nil;owner.interrupted=nil
end
function C:ApplyTargetStyle()
  -- Geometry/font changes are deferred even for an unprotected bar. The art
  -- hooks below keep the already-installed style through native combat casts.
  if call(InCombatLockdown)==true then self.targetStylePending=true;return end
  local frame=self:TargetFrame();local owner=self.targetStyleOwner
  if owner and owner.frame~=frame then self:ReleaseTargetStyle(owner);self.targetStyleOwner=nil;owner=nil end
  if not frame or not self:TargetStyleEnabled() then self:ReleaseTargetStyle(owner);self.targetStylePending=nil;return end
  if not owner then
    owner={frame=frame};self.targetStyleOwner=owner
    owner.background=frame:CreateTexture(nil,"BACKGROUND",nil,-1)
    owner.background:SetTexture(WHITE);owner.background:SetAllPoints(frame)
    local function paint() C:PaintTargetStyle(owner) end
    -- Post-hooks only: never invoke/replace the native update, SetUnit, event
    -- handler or OnUpdate. Cast/channel secrecy stays in Blizzard's engine.
    if type(frame.UpdateBarFillTexture)=="function" then
      hooksecurefunc(frame,"UpdateBarFillTexture",function() owner.interrupted=nil;paint() end)
    end
    if type(frame.PlayInterruptAnims)=="function" then
      hooksecurefunc(frame,"PlayInterruptAnims",function() owner.interrupted=true;paint() end)
    end
    if type(frame.SetLook)=="function" then
      hooksecurefunc(frame,"SetLook",function() if owner.active then C:ApplyTargetPosition() end end)
    end
  end
  owner.active=true
  local db=self:GetDB().targetStyle;local a=db.appearance
  local inset=db.icon.enabled and db.icon.size+2 or 0
  local width=math.max(1,a.width-inset)
  B:Write(owner,frame,"width",width);B:Write(owner,frame,"height",a.height)
  for _,key in ipairs({"Border","BorderShield","BarBorder","TextBorder","Background","Spark","Flash"}) do
    if frame[key] then B:Write(owner,frame[key],"alpha",0) end
  end
  owner.background:SetVertexColor(unpack(a.backgroundColor));owner.background:Show()
  if frame.Icon then
    B:Write(owner,frame.Icon,"width",db.icon.size);B:Write(owner,frame.Icon,"height",db.icon.size)
    local left=db.icon.position=="left"
    B:Write(owner,frame.Icon,"points",{{left and "RIGHT" or "LEFT",frame,left and "LEFT" or "RIGHT",left and -2 or 2,0}})
    B:Write(owner,frame.Icon,"alpha",db.icon.enabled and 1 or 0)
  end
  local function text(region,cfg,maximum)
    if not region then return end
    local outside=cfg.position:find("outside",1,true)==1
    local side=cfg.position:match("_(%a+)$"):upper()
    local anchor=side=="CENTER" and (outside and "BOTTOM" or "CENTER") or (outside and "BOTTOM"..side or side)
    local relative=outside and (side=="CENTER" and "TOP" or "TOP"..side) or side
    B:Write(owner,region,"points",{{anchor,frame,relative,side=="LEFT" and 4 or side=="RIGHT" and -4 or 0,outside and 3 or 0}})
    B:Write(owner,region,"width",maximum);B:Write(owner,region,"height",cfg.fontSize+6)
    B:Write(owner,region,"alpha",cfg.enabled and 1 or 0)
    U:WriteDecor(owner,region,"font",{K.FONT_PATH or STANDARD_TEXT_FONT,cfg.fontSize,"OUTLINE"})
    U:WriteDecor(owner,region,"justify",side)
  end
  text(frame.Text,db.spellName,math.max(1,width*.65))
  text(frame.CastTimeText,self:GetDB().castTime,math.max(1,width*.3))
  self:PaintTargetStyle(owner);self.targetStylePending=nil
end
