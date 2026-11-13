local _,K=...
local call=K.PublicCall

local function identity()
  local guid=call(UnitGUID,"player")
  local realm=call(GetRealmName)
  local faction=call(function() return (UnitFactionGroup("player")) end)
  if type(guid)~="string" or guid=="" or type(realm)~="string" or realm==""
    or type(faction)~="string" or faction=="" then return end
  return guid,realm,faction
end

local function name()
  if call(RegionalUniqueNamesEnabled)==true then
    local full=call(NameUtil and NameUtil.GetUnmodifiedUnitFullName,"player")
    if type(full)=="string" and full~="" then return full end
    local first,surname=call(UnitName,"player")
    if type(first)=="string" then
      return type(surname)=="string" and surname~="" and first.." "..surname or first
    end
  end
  return call(function() return (UnitName("player")) end)
end

function K:RecordCharacterMoney()
  if not self.db then return end
  local guid,realm,faction=identity()
  local amount=call(GetMoney)
  local display=name()
  if not guid or type(display)~="string" or display=="" or not self.IsPublicNumber(amount) or amount<0 then return end
  local class=call(function() return select(2,UnitClass("player")) end)
  self.db.globalData=self.db.globalData or {}
  local global=self.db.globalData
  global.characterMoney=global.characterMoney or {}
  global.characterMoney[guid]={realm=realm,faction=faction,name=display,class=class,copper=amount}
end

function K:ShowCharacterMoney(frame)
  local guid,realm,faction=identity()
  local records=self.db and self.db.globalData and self.db.globalData.characterMoney
  local rows={}
  if guid and records then
    for id,record in pairs(records) do
      if type(id)=="string" and id~=guid and type(record)=="table" and record.realm==realm and record.faction==faction
        and type(record.name)=="string" and self.IsPublicNumber(record.copper) and record.copper>=0 then
        rows[#rows+1]=record
      end
    end
  end
  table.sort(rows,function(a,b) return a.name<b.name end)
  GameTooltip:SetOwner(frame,"ANCHOR_BOTTOM")
  GameTooltip:SetText("같은 서버·진영의 부캐 소지금")
  if #rows==0 then GameTooltip:AddLine("기록된 부캐가 없습니다.",.8,.8,.8) end
  for _,row in ipairs(rows) do
    local color=RAID_CLASS_COLORS and RAID_CLASS_COLORS[row.class]
    GameTooltip:AddDoubleLine(row.name,self.HUDText.FormatMoney(row.copper),
      color and color.r or 1,color and color.g or 1,color and color.b or 1,1,1,1)
  end
  GameTooltip:Show()
end

local events=CreateFrame("Frame")
for _,event in ipairs({"PLAYER_ENTERING_WORLD","PLAYER_MONEY","PLAYER_FACTION_CHANGED"}) do
  pcall(events.RegisterEvent,events,event)
end
events:SetScript("OnEvent",function() K:RecordCharacterMoney() end)
