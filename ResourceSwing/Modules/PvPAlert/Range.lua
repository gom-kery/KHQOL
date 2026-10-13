local _, KHQOL = ...
local PA=KHQOL.modules.pvpAlert
local R={probes={}}
PA.Range=R
-- Targeted harmful skills only; queued next-swing, ground/AoE and friendly skills
-- are deliberately absent. Learned spellbook ranks take precedence over base IDs.
local candidates={
  WARRIOR={1715,6552,694,2764}, ROGUE={1752,1766,1776,2094,1725,2764},
  HUNTER={2974,1495,5116,3044,1978,75}, MAGE={2136,116,133,118,2139},
  WARLOCK={686,172,5782,689,348}, PRIEST={585,589,8092,15407},
  PALADIN={853,20271,62124}, SHAMAN={8042,403,8050,8056},
  DRUID={5176,8921,339,5211,22568,5221},
}
local fallbackItems={8149,15826,16308} -- existing KHQOL's independent melee probes
local function normalize(value)
  if not PA.Readable(value) then return nil end
  if value==true or value==1 then return true end
  if value==false or value==0 then return false end
end
local function check(fn,...)
  return normalize(PA.Call(fn,...))
end
function R:SpellInfo(id)
  local info=PA.Call(C_Spell and C_Spell.GetSpellInfo,id)
  if type(info)=="table" then
    local name=info.name
    if PA.Readable(name) and type(name)=="string" then
      return name,PA.Number(info.minRange),PA.Number(info.maxRange),PA.Number(info.spellID) or id
    end
  end
  if type(GetSpellInfo)=="function" then
    local ok,name,_,_,_,minRange,maxRange=pcall(GetSpellInfo,id)
    if ok and PA.Readable(name) and type(name)=="string" then return name,PA.Number(minRange),PA.Number(maxRange),id end
  end
end
function R:AddProbe(id,index,modern,trusted)
  local name,minRange,maxRange,resolved=self:SpellInfo(id)
  if not name or not minRange or not maxRange or maxRange<=0 or maxRange>100 then return end
  if not trusted then
    local harmful
    if modern and index then harmful=check(C_SpellBook and C_SpellBook.IsSpellBookItemHarmful,index,self.bank) end
    if harmful==nil then harmful=check(C_Spell and C_Spell.IsSpellHarmful,resolved) end
    if harmful==nil then harmful=check(IsHarmfulSpell,name) end
    if harmful~=true then return end
    -- Dynamic discovery excludes next-swing/melee activation ranges. The trusted
    -- class list above supplies genuine targeted melee checks.
    if maxRange<=8 then return end
  end
  local bucket=maxRange<=8 and 1 or maxRange<=25 and 2 or 3
  local old=self.probes[bucket]
  -- Keep known unit-target class skills ahead of metadata-only discovery.
  -- A ground-target skill can have a maxRange yet reject all UnitToken probes.
  if old and old.trusted and not trusted then return end
  if not old or (trusted and not old.trusted) or maxRange>old.maxRange or (maxRange==old.maxRange and resolved>old.id) then
    self.probes[bucket]={id=resolved,name=name,minRange=minRange,maxRange=maxRange,index=index,modern=modern,trusted=trusted and true or false}
  end
end
function R:Rebuild()
  for bucket=1,3 do self.probes[bucket]=nil end
  self.byName={}; self.byID={}
  local class
  if type(UnitClass)=="function" then
    local ok,_,token=pcall(UnitClass,"player")
    if ok and PA.Readable(token) then class=token end
  end
  local wanted={}
  for _,id in ipairs(candidates[class] or {}) do
    local name=self:SpellInfo(id)
    if name then wanted[name]=true end
  end
  local bank=Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
  self.bank=PA.Readable(bank) and bank or nil
  local function consume(id,index,modern)
    if not id then return end
    local name=self:SpellInfo(id)
    if name then
      self.byID[id]={index=index,modern=modern}
      self.byName[name]={id=id,index=index,modern=modern}
      self:AddProbe(id,index,modern,wanted[name])
    end
  end
  local book=C_SpellBook
  if self.bank~=nil and book then
    local count=PA.Number(PA.Call(book.GetNumSpellBookSkillLines)) or 0
    for tab=1,math.min(count,32) do
      local info=PA.Call(book.GetSpellBookSkillLineInfo,tab)
      if type(info)=="table" then
        local offset,size=PA.Number(info.itemIndexOffset),PA.Number(info.numSpellBookItems)
        if offset and size and offset>=0 and size>=0 then
          for index=offset+1,math.min(offset+size,1024) do
            local item=PA.Call(book.GetSpellBookItemInfo,index,self.bank)
            if type(item)=="table" and not PA.Yes(book.IsSpellBookItemPassive,index,self.bank)
              and not PA.Yes(book.IsSpellBookItemOffSpec,index,self.bank) then
              consume(PA.Number(item.spellID),index,true)
            end
          end
        end
      end
    end
  end
  if type(GetSpellTabInfo)=="function" and type(GetSpellBookItemInfo)=="function" then
    local count=PA.Number(PA.Call(GetNumSpellTabs)) or 0
    for tab=1,math.min(count,32) do
      local ok,_,_,offset,size=pcall(GetSpellTabInfo,tab)
      offset,size=PA.Number(offset),PA.Number(size)
      if ok and offset and size and offset>=0 and size>=0 then
        for index=offset+1,math.min(offset+size,1024) do
          local success,kind,id=pcall(GetSpellBookItemInfo,index,BOOKTYPE_SPELL or "spell")
          if success and PA.Readable(kind) and kind=="SPELL" then consume(PA.Number(id),index,false) end
        end
      end
    end
  end
  for _,id in ipairs(candidates[class] or {}) do
    local name=self:SpellInfo(id)
    local learned=name and self.byName[name]
    if learned then self:AddProbe(learned.id,learned.index,learned.modern,true)
    elseif PA.Yes(IsPlayerSpell,id) or PA.Yes(IsSpellKnown,id)
      or (self.bank~=nil and PA.Yes(book and book.IsSpellInSpellBook,id,self.bank)) then self:AddProbe(id,nil,false,true) end
  end
  if not self.requestedItems then
    self.requestedItems=true
    local request=(C_Item and C_Item.RequestLoadItemDataByID) or GetItemInfo
    if type(request)=="function" then for _,id in ipairs(fallbackItems) do pcall(request,id) end end
  end
end
function R:SpellInRange(probe,unit)
  local value=check(C_Spell and C_Spell.IsSpellInRange,probe.id,unit)
  if value==nil then value=check(C_Spell and C_Spell.IsSpellInRange,probe.name,unit) end
  if value==nil and probe.index and probe.modern and self.bank~=nil then
    value=check(C_SpellBook and C_SpellBook.IsSpellBookItemInRange,probe.index,self.bank,unit)
  end
  if value==nil then value=check(IsSpellInRange,probe.name,unit) end
  if value==nil and probe.index and not probe.modern then
    -- The legacy numeric API takes a spellbook INDEX, never a spell ID.
    value=check(IsSpellInRange,probe.index,BOOKTYPE_SPELL or "spell",unit)
  end
  return value
end
function R:Near(unit)
  local probe=self.probes[1]
  local value=probe and self:SpellInRange(probe,unit)
  if value~=nil then return value end
  for _,id in ipairs(fallbackItems) do
    value=check(C_Item and C_Item.IsItemInRange,id,unit)
    if value==nil then value=check(IsItemInRange,id,unit) end
    if value~=nil then return value end
  end
end
function R:GetBucket(unit)
  if self:Near(unit)==true then return 1 end
  local medium=self.probes[2]
  if medium and self:SpellInRange(medium,unit)==true then return 2 end
  -- A shorter compatibility gate when a class has no targeted medium skill.
  local far=self.probes[3]
  local close
  if not medium or (far and far.minRange>0) then close=check(CheckInteractDistance,unit,3) end
  if not medium and close==true then return 2 end
  if far then
    local value=self:SpellInRange(far,unit)
    if value==true then return 3 end
    -- A hunter's minimum range must not masquerade as 'out'. The close gate
    -- proves separation beyond its minimum before accepting a false far probe.
    if value==false and (far.minRange==0 or (far.minRange<=8 and close==false)) then return 4 end
  end
  return nil -- never invent an 'out' sample from nil/unsupported probes
end
function R:Describe()
  local parts={}
  for bucket=1,3 do
    local probe=self.probes[bucket]
    parts[#parts+1]=({"near","medium","far"})[bucket].."="..(probe and probe.name or "fallback/unknown")
  end
  return table.concat(parts,", ")
end
