local _,K=...
local A=K.AuraReader
-- Event-driven consumers can inspect public aura identities together. A failed
-- modern read never falls through to another API and never proves absence.
function A:Snapshot()
  local api=C_UnitAuras and C_UnitAuras.GetAuraDataByIndex
  local legacy=not api and (UnitBuff or UnitAura)
  if type(api)~="function" and type(legacy)~="function" then return nil,"unavailable" end
  local list={}
  for index=1,255 do
    local status,a
    if api then status,a=K.ReadPublicAPI(api,"player",index,"HELPFUL")
    else
      local name,icon,count,kind,duration,expiration,caster,steal,personal,id
      status,name,icon,count,kind,duration,expiration,caster,steal,personal,id=K.ReadPublicAPI(legacy,"player",index,"HELPFUL")
      if name~=nil then a={spellId=id,name=name,icon=icon,duration=duration,expirationTime=expiration} end
    end
    if status~="ok" then return nil,"unreadable" end
    if a==nil then return list,"ok" end
    local ok,id,name,helpful=K.ReadPublicAPI(function() return a.spellId,a.name,a.isHelpful end)
    if ok~="ok" or not K.IsPublicNumber(id) or type(name)~="string" or not self:IsReadable(id) then return nil,"unreadable" end
    if helpful~=false then
      local _,duration,expiration,icon,instance=K.ReadPublicAPI(function() return a.duration,a.expirationTime,a.icon,a.auraInstanceID end)
      list[#list+1]={id=id,name=name,index=index,duration=duration,expirationTime=expiration,icon=icon,instance=instance}
    end
  end
  return nil,"incomplete"
end
