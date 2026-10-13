local ADDON, KHQOL = ...
local FR = KHQOL.modules.range

FR.Range = {}
local Range = FR.Range
Range.actionSlotCache = {}
Range.spellBookCache = {}
Range.spellBookIDs = {}
local function secret(value) return not KHQOL.IsPublicValue(value) end
local function publicField(info,key)
  if secret(info) or type(info)~="table" then return end
  local ok,value=pcall(function() return info[key] end)
  if ok and not secret(value) then return value end
end
Range.PublicField=publicField
local function modernBank()
  local bank=Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
  if not secret(bank) then return bank end
end
local function bookSpellID(index)
  if type(GetSpellBookItemInfo)=="function" then
    local ok,kind,id=pcall(GetSpellBookItemInfo,index,BOOKTYPE_SPELL or "spell")
    if ok and not secret(kind) and not secret(id) then
      if kind=="SPELL" and type(id)=="number" then return id,true end
      if kind~=nil and kind~="SPELL" then return nil,true end
    end
  end
  local bank=modernBank()
  if bank~=nil and C_SpellBook and type(C_SpellBook.GetSpellBookItemInfo)=="function" then
    local ok,info=pcall(C_SpellBook.GetSpellBookItemInfo,index,bank)
    if ok and not secret(info) and type(info)=="table" then
      local kind,id=publicField(info,"itemType"),publicField(info,"spellID")
      local spellType=Enum and Enum.SpellBookItemType and Enum.SpellBookItemType.Spell
      if not secret(kind) and not secret(id) and not secret(spellType) then
        if (kind=="SPELL" or (spellType~=nil and kind==spellType)) and type(id)=="number" then return id,true end
        if kind~=nil and kind~="SPELL" and kind~=spellType then return nil,true end
      end
    end
  end
  return nil,false
end

local function normalize(result)
  if secret(result) then return nil end
  if result == true or result == 1 then return true end
  if result == false or result == 0 then return false end
  return nil
end

local function protectedCall(fn, ...)
  if type(fn) ~= "function" then return nil end
  for i=1,select("#",...) do
    if secret(select(i,...)) then return nil end
  end
  local ok, value = pcall(fn, ...)
  if ok then return normalize(value) end
  return nil
end

function Range:GetSpellInfo(spellID)
  if secret(spellID) or not spellID then return nil end
  if C_Spell and type(C_Spell.GetSpellInfo) == "function" then
    local ok, info = pcall(C_Spell.GetSpellInfo, spellID)
    if ok and not secret(info) and type(info)=="table" then
      local name,id=publicField(info,"name"),publicField(info,"spellID")
      if type(name)=="string" then return name, id or spellID end
    end
  end
  if type(GetSpellInfo) == "function" then
    local ok, name = pcall(GetSpellInfo, spellID)
    if ok and not secret(name) and type(name)=="string" then return name, spellID end
  end
  return nil
end

function Range:IsKnownSpell(spellID)
  if not spellID then return false end
  local player=protectedCall(IsPlayerSpell,spellID)
  local known=protectedCall(IsSpellKnown,spellID)
  if player==true or known==true then return true end
  if player==false or known==false then
    -- A base-rank ID may be replaced by a learned higher rank in the book.
    local name=self:GetSpellInfo(spellID)
    return name and self:FindSpellBookIndex(spellID,name)~=nil or false
  end

  -- Older clients may not expose a reliable known-spell API. A resolved name is
  -- still accepted; the range wrapper will safely report unknown if it cannot check it.
  return self:GetSpellInfo(spellID) ~= nil
end

function Range:FindActionSlotForSpell(spellID)
  if not spellID or type(GetActionInfo) ~= "function" then return nil end
  local cached = self.actionSlotCache[spellID]
  if cached ~= nil then return cached or nil end
  -- This is optional compatibility only. The normal path never requires a spell
  -- to occupy an action-bar slot.
  for slot = 1, 180 do
    local ok, actionType, actionID = pcall(GetActionInfo, slot)
    if ok and not secret(actionType) and not secret(actionID) and actionType == "spell" and tonumber(actionID) == tonumber(spellID) then
      self.actionSlotCache[spellID] = slot
      return slot
    end
  end
  self.actionSlotCache[spellID] = false
  return nil
end

function Range:ClearActionSlotCache()
  self.actionSlotCache = {}
  self.spellBookCache = {}
  self.spellBookIDs = {}
end

function Range:IsActionInRangeFallback(spellID, unit)
  local slot = self:FindActionSlotForSpell(spellID)
  if not slot then return nil end
  if C_ActionBar and type(C_ActionBar.IsActionInRange) == "function" then
    local value = protectedCall(C_ActionBar.IsActionInRange, slot, unit)
    if value ~= nil then return value end
  end
  if type(IsActionInRange) == "function" then
    local value = protectedCall(IsActionInRange, slot, unit)
    if value ~= nil then return value end
  end
  return nil
end

-- Returns true (in range), false (out of range), or nil (API cannot decide).
-- nil is intentionally never treated as out of range.
function Range:IsSpellInRange(spellID, spellName, unit)
  if not unit or protectedCall(UnitExists, unit) ~= true then return nil end
  if type(issecretvalue)=="function" then
    if issecretvalue(spellID) then spellID=nil end
    if issecretvalue(spellName) then spellName=nil end
  end
  local bookIndex,learnedID=self:FindSpellBookIndex(spellID,spellName)
  if learnedID then spellID=learnedID end

  if C_Spell and type(C_Spell.IsSpellInRange) == "function" then
    local value = protectedCall(C_Spell.IsSpellInRange, spellID or spellName, unit)
    if value ~= nil then return value end
    if spellName then
      value=protectedCall(C_Spell.IsSpellInRange,spellName,unit)
      if value~=nil then return value end
    end
  end

  -- New clients can expose only C_SpellBook (no legacy spell-tab globals).
  local bank=modernBank()
  if bookIndex and bank~=nil and C_SpellBook and type(C_SpellBook.IsSpellBookItemInRange)=="function" then
    local value=protectedCall(C_SpellBook.IsSpellBookItemInRange,bookIndex,bank,unit)
    if value~=nil then return value end
  end

  if type(IsSpellInRange) == "function" then
    -- Name form takes (name, unit), NOT (name, bookType, unit).
    if spellName then
      local value = protectedCall(IsSpellInRange, spellName, unit)
      if value ~= nil then return value end
    end
    -- Numeric legacy arguments are SPELLBOOK INDICES, never spell IDs.
    local index=bookIndex
    if index then
      local value = protectedCall(IsSpellInRange, index, BOOKTYPE_SPELL or "spell", unit)
      if value ~= nil then return value end
    end
  end
  -- Last-resort only: use an existing matching action button if one exists.
  -- We never ask the player to place a spell on an action bar.
  local actionResult = self:IsActionInRangeFallback(spellID, unit)
  if actionResult ~= nil then return actionResult end
  return nil
end

function Range:FindSpellBookIndex(spellID,spellName)
  if not spellID and not spellName then return end
  local key=tostring(spellID or "")..":"..(spellName or "")
  if self.spellBookCache[key]~=nil then return self.spellBookCache[key] or nil,self.spellBookIDs[key] end
  local book=C_SpellBook
  local modes={}
  if type(GetNumSpellTabs)=="function" and type(GetSpellTabInfo)=="function" and type(GetSpellBookItemInfo)=="function" then modes[#modes+1]="legacy" end
  if modernBank()~=nil and book and type(book.GetNumSpellBookSkillLines)=="function" and type(book.GetSpellBookSkillLineInfo)=="function" and type(book.GetSpellBookItemInfo)=="function" then modes[#modes+1]="modern" end
  local complete=false
  for _,mode in ipairs(modes) do
    local ok,count=pcall(mode=="legacy" and GetNumSpellTabs or book.GetNumSpellBookSkillLines)
    if ok and not secret(count) and type(count)=="number" and count>0 and count<math.huge then
      local valid=true
      for tab=1,math.min(count,32) do
        local offset,size
        if mode=="legacy" then
          local success,_,_,o,s=pcall(GetSpellTabInfo,tab)
          if success then offset,size=o,s end
        else
          local success,info=pcall(book.GetSpellBookSkillLineInfo,tab)
          if success and not secret(info) and type(info)=="table" then offset,size=publicField(info,"itemIndexOffset"),publicField(info,"numSpellBookItems") end
        end
        if not secret(offset) and not secret(size) and type(offset)=="number" and type(size)=="number" and offset>=0 and size>=0 then
          for index=offset+1,math.min(offset+size,1024) do
            local id,readable=bookSpellID(index)
            if not readable then valid=false end
            if id and (id==spellID or (spellName and self:GetSpellInfo(id)==spellName)) then
              self.spellBookCache[key]=index; self.spellBookIDs[key]=id; return index,id
            end
          end
        else valid=false end
      end
      complete=complete or valid
    end
  end
  -- Don't cache transient/malformed/protected book metadata as an absent spell.
  if complete then self.spellBookCache[key]=false end
end

-- Independent 5-yard probes used by Classic/Forever range tools. These queries
-- don't use/consume an item, require it on an action bar, or inspect tooltip text.
local meleeItems={8149,15826,16308}
function Range:PrepareHunterRangeItems()
  if self.itemRequestsDone then return end
  local request=(C_Item and C_Item.RequestLoadItemDataByID) or GetItemInfo
  if type(request)=="function" then
    self.itemRequestsDone=true
    for _,id in ipairs(meleeItems) do pcall(request,id) end
  end
end
function Range:CheckMeleeItemRange(unit)
  self:PrepareHunterRangeItems()
  for _,id in ipairs(meleeItems) do
    local value=protectedCall(C_Item and C_Item.IsItemInRange,id,unit)
    if value==nil then value=protectedCall(IsItemInRange,id,unit) end
    if value~=nil then return value,nil,"ITEM_5YD:"..id end
  end
  return nil,"NO_MELEE_RANGE_API"
end

function Range:CheckReliableHunterSpell(id,unit)
  if id and self:IsKnownSpell(id) then
    local value=self:IsSpellInRange(id,self:GetSpellInfo(id),unit)
    if value~=nil then return value,nil,id end
  end
end
function Range:IsValidHostileTarget()
  return protectedCall(UnitExists,"target")==true
    and protectedCall(UnitIsDeadOrGhost,"target")==false
    and protectedCall(UnitCanAttack,"player","target")==true
end

function Range:CheckReferenceSpell(id,savedName,unit)
  if secret(id) or type(id)~="number" or id<=0 then return nil,"NO_SPELL" end
  if not self:IsKnownSpell(id) then return nil,"UNKNOWN_SPELL" end
  local name=self:GetSpellInfo(id) or savedName
  local result=self:IsSpellInRange(id,name,unit or "target")
  if result==nil then return nil,"UNSUPPORTED" end
  return result
end
function Range:CheckConfiguredSpell(unit)
  local db=FR.db
  local ranged=db.rangedSpellID or db.rangeSpellID
  if select(2,UnitClass("player"))=="HUNTER" then
    return self:CheckReferenceSpell(ranged,db.rangedSpellName or db.rangeSpellName,unit)
  end
  local configured,unknown=0,false
  for _,entry in ipairs({{db.meleeSpellID,db.meleeSpellName},{ranged,db.rangedSpellName or db.rangeSpellName}}) do
    local id=entry[1]
    if not secret(id) and type(id)=="number" and id>0 then
      configured=configured+1
      local value=self:CheckReferenceSpell(id,entry[2],unit)
      if value==true then return true end
      if value==nil then unknown=true end
    end
  end
  if configured==0 then return nil,"NO_SPELL" end
  if unknown then return nil,"UNSUPPORTED" end
  return false
end

function Range:FindDefaultHunterMeleeSpell()
  -- Spell IDs are preferred. Candidates are only used when the player knows them.
  local candidates = { 2974, 14267, 14268 } -- Wing Clip ranks; not ranged/escape/next-swing abilities
  for _, spellID in ipairs(candidates) do
    if self:IsKnownSpell(spellID) then return spellID end
  end
  return nil
end

local raptorRanks={ [2973]=true,[14260]=true,[14261]=true,[14262]=true,[14263]=true,[14264]=true,[14265]=true,[14266]=true }
function Range:CheckHunterMelee(unit)
  local id=FR.db.meleeSpellID or FR.db.hunterMeleeSpellID or self:FindDefaultHunterMeleeSpell()
  local name=id and self:GetSpellInfo(id)
  -- A queued next-swing spell may report activation range rather than melee
  -- reach. Preserve the registered ID, but verify reach with learned Wing Clip.
  if not raptorRanks[id] and not (name and name==self:GetSpellInfo(2973)) then
    local value,reason,source=self:CheckReliableHunterSpell(id,unit)
    if value~=nil then return value,reason,source end
  end
  -- Try all learned ranks, not just the first named base rank that returned nil.
  for _,candidate in ipairs({2974,14267,14268}) do
    if candidate~=id or raptorRanks[id] then
      local value,reason,source=self:CheckReliableHunterSpell(candidate,unit)
      if value~=nil then return value,reason,source end
    end
  end
  return self:CheckMeleeItemRange(unit)
end

-- With the hunter dual-reference option, either registered attack can be GREEN.
-- Neither spell in range is not necessarily a dead zone: retain the existing
-- conservative close-interaction gate before distinguishing ORANGE from RED.
function Range:GetHunterState(rangedInRange, unit)
  unit = unit or "target"
  if rangedInRange==true then return "GREEN" end
  local meleeAsAttack=FR.db.hunterMeleeAsAttack==true
  if rangedInRange==nil and not meleeAsAttack then return nil, "RANGED_UNSUPPORTED" end
  if not meleeAsAttack and not FR.db.deadZoneEnabled then return "RED" end

  local meleeInRange,meleeReason = self:CheckHunterMelee(unit)
  if meleeInRange == true then return meleeAsAttack and "GREEN" or "RED" end
  if rangedInRange==nil then return nil, "RANGED_UNSUPPORTED" end
  if meleeInRange == nil then
    -- A failed melee probe must not discard a confirmed ranged-out result when
    -- the target is also confirmed beyond the close bucket (and thus melee).
    if protectedCall(CheckInteractDistance,unit,3)==false then return "RED","BEYOND_MELEE_GATE" end
    if meleeAsAttack then return nil, meleeReason or "MELEE_UNSUPPORTED" end
    return "RED", "MELEE_UNSUPPORTED"
  end
  if not FR.db.deadZoneEnabled then return "RED" end

  if type(CheckInteractDistance) ~= "function" then return "RED", "NO_CLOSE_GATE" end
  local closeBucket = protectedCall(CheckInteractDistance, unit, 3)
  if closeBucket then return "ORANGE" end
  return "RED"
end

function Range:GetTargetState()
  if not self:IsValidHostileTarget() then return nil, "INVALID_TARGET" end
  local rangedInRange, reason = self:CheckConfiguredSpell()
  if select(2, UnitClass("player")) == "HUNTER" then
    return self:GetHunterState(rangedInRange)
  end
  if rangedInRange == nil then return nil, reason end
  return rangedInRange and "GREEN" or "RED"
end

function Range:DescribeAPI()
  local api = {}
  api[#api + 1] = (C_Spell and type(C_Spell.IsSpellInRange) == "function") and "C_Spell.IsSpellInRange: available" or "C_Spell.IsSpellInRange: unavailable"
  api[#api + 1] = type(IsSpellInRange) == "function" and "IsSpellInRange: available" or "IsSpellInRange: unavailable"
  api[#api + 1] = type(IsActionInRange) == "function" and "IsActionInRange: available (not required)" or "IsActionInRange: unavailable"
  api[#api + 1] = (C_ActionBar and type(C_ActionBar.IsActionInRange) == "function") and "C_ActionBar.IsActionInRange: available (optional fallback)" or "C_ActionBar.IsActionInRange: unavailable"
  api[#api + 1] = (C_SpellBook and type(C_SpellBook.IsSpellBookItemInRange)=="function") and "C_SpellBook range: available" or "C_SpellBook range: unavailable"
  api[#api + 1] = ((C_Item and type(C_Item.IsItemInRange)=="function") or type(IsItemInRange)=="function") and "5yd item range: available" or "5yd item range: unavailable"
  FR:Print(table.concat(api, " | "))
  if select(2,UnitClass("player"))=="HUNTER" then
    local function value(v) return v==true and "in" or v==false and "out" or "unknown" end
    for _,unit in ipairs({"target","mouseover"}) do
      if protectedCall(UnitExists,unit)==true then
        local ranged=self:CheckConfiguredSpell(unit)
        local melee,reason,source=self:CheckHunterMelee(unit)
        local state,stateReason=self:GetHunterState(ranged,unit)
        FR:Print(unit..": ranged="..value(ranged)..", melee="..value(melee)..", probe="..tostring(source or reason or "none")..", close="..value(protectedCall(CheckInteractDistance,unit,3))..", state="..tostring(state or stateReason or "unknown"))
      end
    end
  end
end
