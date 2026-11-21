local K,F=_G.KHQOL,_G.ForeverBuffReminder
local Food=F.Food
local call,number=K.PublicCall,K.IsPublicNumber
-- Confirmed by the user's full item tooltip (2026-11-19): item 4592,
-- 10s eating, +5% experience from kills, no conjured label. Other foods are
-- accepted only from a complete, public tooltip in the running client.
Food.verified[4592]={nonConjured=true,killXP=5,seconds=10,source="user-tooltip-2026-11-19-item4592"}
local function clean(s)
  return type(s)=="string" and s:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r",""):gsub("%s+",""):lower() or ""
end
function Food:TooltipText(data)
  local status,text=K.ReadPublicAPI(function()
    if type(data)~="table" or type(data.lines)~="table" or #data.lines==0 then return end
    local out={}
    for _,line in ipairs(data.lines) do
      for _,key in ipairs({"leftText","rightText"}) do
        local value=line[key]
        if not K.IsPublicValue(value) then error("unreadable tooltip") end
        if type(value)=="string" then out[#out+1]=value end
      end
    end
    return table.concat(out," ")
  end)
  return status=="ok" and text or nil
end
function Food:IsXPText(text)
  local s=clean(text)
  local percent=tonumber(s:match("경험치.-([%d%.]+)%%") or s:match("experience.-([%d%.]+)%%"))
  if percent~=5 then return false end
  return (s:find("처치",1,true) and s:find("경험치",1,true) and s:find("5%",1,true)
      and (s:find("증가",1,true) or s:find("추가",1,true)))
    or (s:find("experience",1,true) and s:find("kills",1,true) and s:find("5%",1,true) and s:find("increas",1,true)) or false
end
function Food:Evidence(id)
  local info,message=self:Info(id)
  if not info then
    if message=="아이템 정보를 불러오는 중입니다." then
      local _,_,_,_,_,class,subclass=call(C_Item and C_Item.GetItemInfoInstant,id)
      if not number(class) or class==0 and (not number(subclass) or subclass==5) then
        self.itemRequests=self.itemRequests or {}
        self.itemAttempts=self.itemAttempts or {}
        if not self.itemAttempts[id] then
          self.itemAttempts[id]=true
          if K.ReadPublicAPI(C_Item and C_Item.RequestLoadItemDataByID,id)=="ok" then self.itemRequests[id]=true end
        end
      end
    end
    return
  end
  local cached=self.verified[id]
  if cached then return self:Verified(id) end
  local text=self:TooltipText(call(C_TooltipInfo and C_TooltipInfo.GetItemByID,id))
  if not text or not self:IsXPText(text) then return end
  local normalized=clean(text)
  local conjured=clean(ITEM_CONJURED or "")
  if normalized:find("창조",1,true) or normalized:find("conjured",1,true) or conjured~="" and normalized:find(conjured,1,true) then return end
  local seconds=tonumber(normalized:match("(%d+)초이상") or normalized:match("atleast(%d+)sec"))
  if not number(seconds) or seconds<=0 or seconds>60 then return end
  local _,useSpell=call(C_Item and C_Item.GetItemSpell or GetItemSpell,id)
  self.verified[id]={nonConjured=true,killXP=5,seconds=seconds,source="live-public-item-tooltip",useSpell=number(useSpell) and useSpell or nil}
  return self.verified[id]
end
function Food:BagCandidates()
  local api=C_Container;local ids={};local seen={};self.bagStock={}
  if not api then return ids end
  for bag=0,(NUM_BAG_SLOTS or 4) do
    local slots=call(api.GetContainerNumSlots,bag)
    if number(slots) and slots>=0 and slots<=100 then
      for slot=1,slots do
        local item=call(api.GetContainerItemInfo,bag,slot)
        local id=call(function() return item and item.itemID end)
        if number(id) then
          local locked=call(function() return item.isLocked end)
          local state=self.bagStock[id] or {found=true,unlocked=false}
          if locked==false then state.unlocked=true end;self.bagStock[id]=state
        end
        if number(id) and not seen[id] then
          seen[id]=true
          if self:Evidence(id) then ids[#ids+1]=id end
        end
      end
    end
  end
  table.sort(ids);return ids
end
function Food:ReadObservation()
  if self.observation then return self.observation end
  local list=K.AuraReader:Snapshot()
  local result={fed={state="UNKNOWN"},eating={state="MISSING"}}
  if not list then self.observation=result;return result end
  result.fed={state="MISSING"}
  local eatingName=K:GetSpellDetails(435)
  local candidateName=K:GetSpellDetails(1249519)
  local useName=self.selected and select(1,call(C_Item and C_Item.GetItemSpell or GetItemSpell,self.selected))
  for _,a in ipairs(list) do
    local fedName=a.name=="포만감" or a.name=="Well Fed"
      or candidateName and (candidateName=="포만감" or candidateName=="Well Fed") and a.name==candidateName
    if not fedName and a.instance and C_TooltipInfo and C_TooltipInfo.GetUnitBuffByAuraInstanceID then
      fedName=self:IsXPText(self:TooltipText(call(C_TooltipInfo.GetUnitBuffByAuraInstanceID,"player",a.instance)))
    end
    if fedName then result.fed={state="ACTIVE",duration=a.duration,expirationTime=a.expirationTime,id=a.id,icon=a.icon} end
    if a.id==435 or eatingName and a.name==eatingName or useName and a.name==useName then
      if number(a.duration) and a.duration>0 and number(a.expirationTime) then
        result.eating={state="ACTIVE",duration=a.duration,expirationTime=a.expirationTime,id=a.id}
      else result.eating={state="UNKNOWN"} end
    end
  end
  self.observation=result;return result
end
