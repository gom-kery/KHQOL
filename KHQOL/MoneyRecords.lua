local _,K=...
local call=K.PublicCall

function K:GetCharacterRecordIdentity()
  local guid=call(UnitGUID,"player")
  local realm=call(GetRealmName)
  local faction=call(function() return (UnitFactionGroup("player")) end)
  if type(guid)~="string" or guid=="" or type(realm)~="string" or realm==""
    or type(faction)~="string" or faction=="" then return end
  return guid,realm,faction
end

function K:GetCharacterRecordName()
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
  local guid,realm,faction=self:GetCharacterRecordIdentity()
  local amount=call(GetMoney)
  local display=self:GetCharacterRecordName()
  if not guid or type(display)~="string" or display=="" or not self.IsPublicNumber(amount) or amount<0 then return end
  local class=call(function() return select(2,UnitClass("player")) end)
  self.db.globalData=self.db.globalData or {}
  local global=self.db.globalData
  global.characterMoney=global.characterMoney or {}
  global.characterMoney[guid]={realm=realm,faction=faction,name=display,class=class,copper=amount}
end

function K:ShowCharacterMoney(frame)
  local guid,realm,faction=self:GetCharacterRecordIdentity()
  local records=self.db and self.db.globalData and self.db.globalData.characterMoney
  local amount=call(GetMoney)
  local total=self.IsPublicNumber(amount) and amount>=0 and amount or 0
  local rows={}
  if guid and records then
    for id,record in pairs(records) do
      if type(id)=="string" and id~=guid and type(record)=="table" and record.realm==realm and record.faction==faction
        and type(record.name)=="string" and self.IsPublicNumber(record.copper) and record.copper>=0 then
        rows[#rows+1]=record
        total=total+record.copper
      end
    end
  end
  table.sort(rows,function(a,b) return a.name<b.name end)
  local measure=self.moneyColumnMeasure
  if not measure then
    measure=UIParent:CreateFontString(nil,"ARTWORK","GameTooltipText")
    measure:Hide();self.moneyColumnMeasure=measure
  end
  local widths,display={0,0,0},{}
  for i,row in ipairs(rows) do
    local parts={self.HUDText.MoneyParts(row.copper)}
    display[i]={parts=parts,widths={}}
    for j,part in ipairs(parts) do
      measure:SetText(part)
      local width=measure:GetStringWidth()
      display[i].widths[j]=width;widths[j]=math.max(widths[j],width)
    end
  end
  GameTooltip:SetOwner(frame,"ANCHOR_BOTTOM")
  GameTooltip:SetText("서버 합계 소지금 : "..self.HUDText.FormatMoney(total))
  if #rows==0 then GameTooltip:AddLine("기록된 부캐가 없습니다.",.8,.8,.8) end
  for i,row in ipairs(rows) do
    local color=RAID_CLASS_COLORS and RAID_CLASS_COLORS[row.class]
    local cell=display[i]
    for j,part in ipairs(cell.parts) do
      local padding=math.floor(widths[j]-cell.widths[j]+.5)
      if padding>0 then cell.parts[j]="|TInterface\\AddOns\\KHQOL\\Media\\MoneyColumnSpacer.tga:1:"..padding.."|t"..part end
    end
    GameTooltip:AddDoubleLine(row.name,table.concat(cell.parts,"  "),
      color and color.r or 1,color and color.g or 1,color and color.b or 1,1,1,1)
  end
  GameTooltip:Show()
end

local events=CreateFrame("Frame")
for _,event in ipairs({"PLAYER_ENTERING_WORLD","PLAYER_MONEY","PLAYER_FACTION_CHANGED"}) do
  pcall(events.RegisterEvent,events,event)
end
events:SetScript("OnEvent",function() K:RecordCharacterMoney() end)
