local _, KHQOL = ...
local A={}
KHQOL.AuraReader=A
local function public(v) return KHQOL.IsPublicValue(v) end
local function number(v) return public(v) and type(v)=="number" and v==v and math.abs(v)<math.huge end
local function unknown() return {state="UNKNOWN"} end
function A:IsReadable(id)
  local secrets=C_Secrets
  local predicate=secrets and secrets.ShouldSpellAuraBeSecret
  if type(predicate)=="function" then
    local status,value=KHQOL.ReadPublicAPI(predicate,id)
    return status=="ok" and value==false
  end
  -- Older clients may expose only the global predicate. Without the per-spell
  -- classification it is safer to defer than to treat a protected nil as absent.
  predicate=secrets and secrets.ShouldAurasBeSecret
  if type(predicate)=="function" then
    local status,value=KHQOL.ReadPublicAPI(predicate)
    return status=="ok" and value==false
  end
  return true -- Legacy clients are still guarded at every value/API read below.
end
local function unpackAura(a)
  if not public(a) or type(a)~="table" then error("unreadable aura") end
  local id,name,helpful=a.spellId,a.name,a.isHelpful
  if not number(id) or not public(name) or not public(helpful) then error("unreadable identity") end
  return id,type(name)=="string" and name or nil,helpful~=false
end
local function observation(a)
  local d,e,icon=a.duration,a.expirationTime,a.icon
  if not number(d) or not number(e) or not public(icon) or d<0 or e<0 then return unknown() end
  if d==0 and e==0 then return {state="ACTIVE",duration=0,expirationTime=0,icon=icon} end
  local status,now=KHQOL.ReadPublicAPI(GetTime)
  if status~="ok" or not number(now) or d<=0 or e<=now then return unknown() end
  return {state="ACTIVE",duration=d,expirationTime=e,remaining=e-now,icon=icon}
end
-- A read occurs only on an existing aura event/deadline. Registered IDs are
-- queried directly, with one bounded legacy traversal for unresolved names/IDs.
-- A rejected modern read is UNKNOWN and is never retried via another API.
function A:Read(registered)
  local result,pending={},{}
  local direct=C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID
  local indexed=C_UnitAuras and C_UnitAuras.GetAuraDataByIndex
  local legacy=type(indexed)~="function" and UnitAura or nil
  for id,record in pairs(registered) do
    if number(id) and id>0 then
      if not self:IsReadable(id) then result[id]=unknown()
      elseif type(direct)=="function" then
        local status,a=KHQOL.ReadPublicAPI(direct,id)
        if status~="ok" then result[id]=unknown()
        elseif a==nil then
          if record.name and (type(indexed)=="function" or type(legacy)=="function") then pending[id]=record
          else result[id]={state="MISSING"} end
        else
          local ok,value=pcall(function()
            local auraID,_,helpful=unpackAura(a)
            if auraID~=id or not helpful then return unknown() end
            return observation(a)
          end)
          result[id]=ok and value or unknown()
        end
      else pending[id]=record end
    end
  end
  if not next(pending) then return result end
  local complete=false
  local ok=pcall(function()
    for i=1,255 do
      local a
      if type(indexed)=="function" then
        local status,value=KHQOL.ReadPublicAPI(indexed,"player",i,"HELPFUL")
        if status~="ok" then error("aura index unavailable") end
        a=value
      elseif type(legacy)=="function" then
        local status,name,icon,_,_,duration,expiration,_,_,_,id=KHQOL.ReadPublicAPI(legacy,"player",i,"HELPFUL")
        if status~="ok" then error("legacy aura unavailable") end
        if name~=nil then a={spellId=id,name=name,icon=icon,duration=duration,expirationTime=expiration} end
      else error("missing aura API") end
      if a==nil then complete=true;break end
      local id,name,helpful=unpackAura(a)
      if helpful then
        for wanted,record in pairs(pending) do
          if wanted==id or (record.name and record.name==name) then
            result[wanted]=self:IsReadable(id) and observation(a) or unknown()
          end
        end
      end
    end
  end)
  for id in pairs(pending) do
    if not result[id] then result[id]=(ok and complete) and {state="MISSING"} or unknown() end
  end
  return result
end
