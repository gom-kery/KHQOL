local _, KHQOL = ...
local CFA = KHQOL.modules.campfire

-- Campfire-only compatibility reader. Never forward restricted values to UI.
-- Contract: aura,status; present/absent are known, all other states uncertain.
local function field(value,kind)
    if not KHQOL.IsPublicValue(value) then error("Unreadable aura field") end
    if value~=nil and kind and type(value)~=kind then error("Invalid aura field") end
    if kind=="number" and value~=nil and (value~=value or math.abs(value)==math.huge) then error("Invalid aura number") end
    return value
end
local function NormalizeAura(first,icon,count,dispelType,duration,expirationTime,sourceUnit,_,_,spellId)
    if first==nil then return nil end
    field(first)
    if type(first)=="table" then
        local a=first
        first=field(a.name,"string")
        icon=field(a.icon) or field(a.iconFileID)
        count=field(a.applications,"number") or field(a.count,"number")
        duration=field(a.duration,"number"); expirationTime=field(a.expirationTime,"number")
        sourceUnit=field(a.sourceUnit,"string")
        spellId=field(a.spellId,"number") or field(a.spellID,"number")
    else
        first=field(first,"string"); icon=field(icon); count=field(count,"number")
        dispelType=field(dispelType,"string"); duration=field(duration,"number")
        expirationTime=field(expirationTime,"number"); sourceUnit=field(sourceUnit,"string")
        spellId=field(spellId,"number")
    end
    if icon~=nil and type(icon)~="number" and type(icon)~="string" then error("Invalid aura icon") end
    return {name=first,icon=icon,applications=count,dispelType=dispelType,
        duration=duration,expirationTime=expirationTime,sourceUnit=sourceUnit,spellId=spellId}
end
local function read(fn,modern,...)
    local function normalize(...)
        local status,a,b,c,d,e,f,g,h,i,j=KHQOL.ReadPublicAPI(fn,...)
        if status~="ok" then return nil,status end
        if modern and a~=nil and type(a)~="table" then return nil,"unreadable" end
        return NormalizeAura(a,b,c,d,e,f,g,h,i,j),a==nil and "absent" or "present"
    end
    -- Protect normalization/field access, not only the API call itself.
    local ok,a,status=pcall(normalize,...)
    if ok then return a,status end
    return nil,"unreadable"
end
local function scan(fn,spellID)
    local auras={}
    for index=1,80 do
        local aura,status=read(fn,C_UnitAuras and fn==C_UnitAuras.GetAuraDataByIndex,"player",index,"HELPFUL")
        if status=="absent" then
            if spellID then return nil,"absent" end
            return auras,"absent"
        end
        if status~="present" then return nil,status end
        if not aura.spellId then return nil,"unreadable" end
        if spellID then
            if aura.spellId==spellID then return aura,"present" end
        else auras[#auras+1]=aura end
    end
    -- A capped scan does not prove that the requested aura is absent.
    return nil,"unreadable"
end
function CFA:GetPlayerAura(spellID)
    if not KHQOL.IsPublicValue(spellID) or type(spellID)~="number" or spellID<=0 then return nil,"unreadable" end
    local api=C_UnitAuras
    if api and type(api.GetPlayerAuraBySpellID)=="function" then
        -- Forever generated declaration: one SpellIdentifier, no unit argument.
        local aura,status=read(api.GetPlayerAuraBySpellID,true,spellID)
        if status=="present" then aura.spellId=aura.spellId or spellID; return aura,status end
        if status~="absent" then return nil,status end
    end
    if AuraUtil and type(AuraUtil.FindAuraBySpellID)=="function" then
        local aura,status=read(AuraUtil.FindAuraBySpellID,false,spellID,"player","HELPFUL")
        if status=="present" then aura.spellId=aura.spellId or spellID; return aura,status end
        if status~="absent" then return nil,status end
    end
    if api and type(api.GetAuraDataByIndex)=="function" then return scan(api.GetAuraDataByIndex,spellID) end
    if type(UnitAura)=="function" then return scan(UnitAura,spellID) end
    -- A successful targeted lookup can prove absence even without a scan API.
    if (api and type(api.GetPlayerAuraBySpellID)=="function") or
       (AuraUtil and type(AuraUtil.FindAuraBySpellID)=="function") then return nil,"absent" end
    return nil,"missing"
end
function CFA:HasPlayerAura(spellID)
    local aura,status=self:GetPlayerAura(spellID)
    if status=="present" or status=="absent" then return aura~=nil,status end
    return nil,status
end
function CFA:HasAnyCampBenefit()
    local uncertain
    for _,spellID in ipairs(self.SPELLS.CAMP_BENEFITS) do
        local aura,status=self:GetPlayerAura(spellID)
        if aura then return aura,"present" end
        if status~="absent" then uncertain=status end
    end
    return nil,uncertain or "absent"
end
function CFA:GetAllPlayerBuffs()
    local api=C_UnitAuras
    local fn=api and api.GetAuraDataByIndex or UnitAura
    if type(fn)~="function" then return {},"missing" end
    local auras,status=scan(fn)
    return auras or {},status
end
