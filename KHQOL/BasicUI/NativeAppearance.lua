local _,KHQOL=...
local call=KHQOL.PublicCall
local finite=KHQOL.IsPublicNumber
local Native={}
KHQOL.NativeAppearance=Native
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
function Native:Write(owner,f,key,value)
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
function Native:Release(owner)
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
Native.Read=read
