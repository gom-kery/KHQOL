local K=_G.KHQOL
local FR=K.modules.range
local D={requested={}}
FR.Distance=D
local call,number=K.PublicCall,K.IsPublicNumber
local boolean=FR.Range.ReadBoolean
local field=FR.Range.PublicField
local metersPerYard=.9144
D.metersPerYard=metersPerYard

function D:Invalidate(itemsOnly)
  self.items=nil
  if not itemsOnly then self.spells=nil end
end

function D:BuildItems()
  local item=C_Item
  self.items={friend={},harm={}}
  for relation,tiers in pairs(FR.distanceItems) do
    for yards,ids in pairs(tiers) do
      local probes={}
      for _,id in ipairs(ids) do
        local cached=boolean(item and item.IsItemDataCachedByID,id)
        if cached==nil then cached=type(call(item and item.GetItemInfo or GetItemInfo,id))=="string" end
        if cached and boolean(item and item.ItemHasRange or ItemHasRange,id)==true then
          probes[#probes+1]=id
          if #probes==2 then break end
        elseif not cached and not self.requested[id] then
          self.requested[id]=true
          call(item and item.RequestLoadItemDataByID,id)
        end
      end
      if #probes>0 then self.items[relation][#self.items[relation]+1]={yards=yards,ids=probes} end
    end
    table.sort(self.items[relation],function(a,b) return a.yards<b.yards end)
  end
end

function D:BuildSpells()
  local spells={friend={},harm={}}
  for _,option in ipairs(FR:GetBookCandidates()) do
    local id=option.value
    local info=call(C_Spell and C_Spell.GetSpellInfo,id)
    local minimum,maximum=field(info,"minRange"),field(info,"maxRange")
    if not number(minimum) or not number(maximum) then
      local _,_,_,_,lo,hi=call(GetSpellInfo,id)
      minimum,maximum=lo,hi
    end
    -- Zero-range/next-swing spells do not provide a numeric reach radius.
    if number(minimum) and number(maximum) and minimum>=0 and maximum>minimum and maximum<=200 then
      local relation
      if boolean(C_Spell and C_Spell.IsSpellHarmful or IsHarmfulSpell,id)==true then relation="harm"
      elseif boolean(C_Spell and C_Spell.IsSpellHelpful or IsHelpfulSpell,id)==true then relation="friend" end
      if relation then spells[relation][#spells[relation]+1]={id=id,name=option.text,lower=minimum,upper=maximum} end
    end
  end
  self.spells=spells
end

function D:Actual(unit)
  local square,checked=call(UnitDistanceSquared,unit)
  if checked==true and number(square) and square>=0 then return math.sqrt(square),"UnitDistanceSquared" end
  local px,py,pz,map=call(UnitPosition,"player")
  local x,y,z,targetMap=call(UnitPosition,unit)
  if not number(px) or not number(py) or not number(pz) or not number(map) or map<0
    or not number(x) or not number(y) or not number(z) or not number(targetMap) or map~=targetMap
    or (px==0 and py==0 and pz==0) or (x==0 and y==0 and z==0) then return end
  local squareDistance=(x-px)^2+(y-py)^2+(z-pz)^2
  if number(squareDistance) then return math.sqrt(squareDistance),"UnitPosition" end
end

local function lower(result,value,open)
  if not result.lower or value>result.lower then result.lower,result.lowerOpen=value,open
  elseif value==result.lower then result.lowerOpen=result.lowerOpen or open end
end
local function upper(result,value,open)
  if not result.upper or value<result.upper then result.upper,result.upperOpen=value,open
  elseif value==result.upper then result.upperOpen=result.upperOpen or open end
end
local function coherent(result)
  return not result.lower or not result.upper or result.lower<result.upper
    or (result.lower==result.upper and not result.lowerOpen and not result.upperOpen)
end

function D:Bounds(unit,relation)
  if not self.items then self:BuildItems() end
  if not self.spells then self:BuildSpells() end
  local result={kind="range",lower=0,lowerOpen=false,source="range checks"}
  local known=false
  for _,tier in ipairs(self.items[relation] or {}) do
    for _,id in ipairs(tier.ids) do
      local within=boolean(C_Item and C_Item.IsItemInRange,id,unit)
      if within==nil then within=boolean(IsItemInRange,id,unit) end
      if within~=nil then
        known=true
        if within then upper(result,tier.yards,false) else lower(result,tier.yards,true) end
        break
      end
    end
  end
  local minimumSpells={}
  for _,probe in ipairs(self.spells[relation] or {}) do
    local name=FR.Range:GetSpellInfo(probe.id)
    local within=FR.Range:IsSpellInRange(probe.id,name,unit)
    if within==true then
      known=true;lower(result,probe.lower,false);upper(result,probe.upper,false)
    elseif within==false then
      if probe.lower==0 then known=true;lower(result,probe.upper,true)
      else minimumSpells[#minimumSpells+1]=probe end
    end
  end
  -- A failed minimum-range spell alone cannot distinguish too close from too
  -- far. Only independent bounds can remove one side of that disjunction.
  for _,probe in ipairs(minimumSpells) do
    if result.lower and result.lower>=probe.lower then lower(result,probe.upper,true);known=true
    elseif result.upper and result.upper<=probe.upper then upper(result,probe.lower,false);known=true end
  end
  if not known or not coherent(result) then return {kind="unknown"} end
  return result
end

function D:Measure(unit)
  unit=unit or "target"
  if boolean(UnitExists,unit)~=true then return end
  -- A corpse must not fall through to the unknown-distance glyph.
  local dead=boolean(UnitIsDeadOrGhost,unit)
  if dead~=false then return end
  if boolean(UnitIsUnit,unit,"player")==true then return {kind="exact",value=0,self=true,source="self"} end
  if boolean(UnitIsVisible,unit)==false then return {kind="unknown"} end
  local value,source=self:Actual(unit)
  if number(value) and value>=0 then return {kind="exact",value=value,source=source} end
  if FR.db.distance.measurement=="exact" then return {kind="unknown",reason="exact-unavailable",source="public exact distance unavailable"} end
  local relation
  if boolean(UnitCanAttack,"player",unit)==true then relation="harm"
  elseif boolean(UnitCanAssist,"player",unit)==true then relation="friend" end
  return relation and self:Bounds(unit,relation) or {kind="unknown"}
end

function D:IsBeyond(result)
  local limit=self:DisplayCap()/self:Multiplier()
  if result.kind=="exact" then return result.value>limit+1e-7 end
  return result.kind=="range" and result.lower and (result.lower>limit+1e-7 or math.abs(result.lower-limit)<1e-7 and result.lowerOpen==true) or false
end

function D:DisplayCap()
  return math.max(45,math.min(80,math.floor(FR.db.distance.maxMeters/(FR.db.distance.unit=="yd" and metersPerYard or 1)+.5)))
end

function D:Multiplier()
  return FR.db.distance.unit=="m" and metersPerYard or 1
end

function D:SpellReference(slot,unit)
  local db=FR.db
  local id
  if slot=="melee" then id=db.meleeSpellID or db.hunterMeleeSpellID else id=db.rangedSpellID or db.rangeSpellID end
  if not number(id) or id<=0 then return end
  local info=call(C_Spell and C_Spell.GetSpellInfo,id)
  local maximum=field(info,"maxRange")
  if not number(maximum) then
    local _,_,_,_,_,legacyMax=call(GetSpellInfo,id);maximum=legacyMax
    if not number(maximum) then
      self.referenceRequests=self.referenceRequests or {}
      if not self.referenceRequests[id] then self.referenceRequests[id]=true;call(C_Spell and C_Spell.RequestLoadSpellData,id) end
    end
  end
  local within=FR.Range:CheckReferenceSpell(id,db[slot.."SpellName"],unit or "target")
  if not K.IsPublicValue(within) or within~=true and within~=false or not number(maximum) or maximum<=0 then within=nil end
  return {id=id,maximum=number(maximum) and maximum>0 and maximum or nil,within=within,
    name=field(info,"name") or db[slot.."SpellName"]}
end

function D:SpellReferenceText(unit)
  local parts={}
  for _,entry in ipairs({{"melee","근접"},{"ranged","원거리"}}) do
    local info=self:SpellReference(entry[1],unit)
    if info then
      local maximum=info.maximum and (" 최대 "..(info.maximum~=math.floor(info.maximum) and "~" or "")..math.ceil(info.maximum).."yd") or " 최대 미확인"
      local state=info.within==true and "안" or info.within==false and "밖" or "미확인"
      local color=info.within==true and "4dff66" or info.within==false and "ff4545" or "cccccc"
      parts[#parts+1]="|cff"..color..entry[2]..maximum.." · "..state.."|r"
    end
  end
  return #parts>0 and table.concat(parts,"  /  ") or "기준 주문 미등록 · 스킬 유효 거리에서 등록"
end

function D:FrameHeight(size) return size+16 end

function D:ThresholdValue(key)
  return math.floor(FR.db.distance.thresholds[key]*self:Multiplier()+.5)
end

function D:ReferenceState(result)
  if not result or result.kind=="unknown" then return "unknown" end
  local maximum=FR.db.distance.thresholds.rangedMax
  if result.kind=="exact" then return result.value<=maximum and "inside" or "outside" end
  if result.upper and result.upper<=maximum then return "inside" end
  if result.lower and (result.lower>maximum or result.lower==maximum and result.lowerOpen) then return "outside" end
  return "boundary"
end

function D:DisplayBounds(result)
  local cfg=FR.db.distance
  local multiplier=self:Multiplier()
  local lo,hi=result.lower,result.upper
  if result.kind=="exact" then lo,hi=result.value,result.value end
  local maximum=self:ThresholdValue("rangedMax")
  local step=cfg.bucketSize
  -- Expand to whole-number bins anchored at the configured ranged maximum.
  -- Never choose one small bin when the API spans two or more bins.
  local low=lo and math.max(0,maximum+1+math.floor((math.floor(lo*multiplier+1e-7)-(maximum+1))/step)*step)
  local high=hi and maximum+math.ceil((math.ceil(hi*multiplier-1e-7)-maximum)/step)*step
  if hi and hi<=cfg.thresholds.nearMax then high=math.min(high,self:ThresholdValue("nearMax")) end
  return low,high
end

function D:Format(result,unitToken)
  if not result or result.kind=="unknown" then return "-" end
  if result.self then return "0" end
  local cfg=FR.db.distance
  local unit=cfg.showUnit and (" "..cfg.unit) or ""
  local cap=self:DisplayCap()
  if self:IsBeyond(result) then return tostring(cap).."+"..unit end
  local text
  if result.kind=="exact" and cfg.format=="single" then
    local value=result.value*self:Multiplier()
    local step=cfg.singleStep or 1
    local rounded=math.floor(value/step+.5)*step
    local maximum=self:ThresholdValue("rangedMax")
    local state=self:ReferenceState(result)
    if state=="outside" and rounded<=maximum then rounded=(math.floor(maximum/step)+1)*step
    elseif state=="inside" and rounded>maximum then rounded=math.floor(maximum/step)*step end
    text=string.format("%.0f",math.min(cap,rounded))
  else
    local lo,hi=self:DisplayBounds(result)
    if cfg.format=="single" then
      local step=cfg.singleStep or 1;local factor=self:Multiplier()
      hi=result.upper and math.ceil(result.upper*factor/step-1e-7)*step
      lo=result.lower and math.max(0,math.floor(result.lower*factor/step+1e-7)*step)
      text=hi and ("~"..math.min(cap,hi)..(hi>cap and "+" or "")) or (string.format("%.0f",math.min(cap,lo or 0)).."+")
    elseif hi then text=string.format("%.0f~%.0f",math.min(cap,lo or 0),math.min(cap,hi))..(hi>cap and "+" or "")
    else text=string.format("%.0f",math.min(cap,lo or 0)).."+" end
  end
  if result.kind=="exact" and cfg.format=="single" then
    local value=result.value*self:Multiplier();text=string.format("%.0f",tonumber(text) or value)
  end
  text=text..unit
  return text
end

function D:ColorKey(result,unit)
  if not result or result.kind=="unknown" then return "neutral" end
  local lo,hi,loOpen,hiOpen
  if result.kind=="exact" then lo,hi=result.value,result.value
  else lo,hi,loOpen,hiOpen=result.lower,result.upper,result.lowerOpen,result.upperOpen end
  unit=unit or "target"
  local t=FR.db.distance.thresholds
  if hi and hi<=t.nearMax then return "near" end
  if self:IsBeyond(result) then return "far" end
  local weapon=FR.Range:UsesRangedWeapon()==true and boolean(UnitCanAttack,"player",unit)==true
  if weapon and FR.db.deadZoneEnabled then
    local aboveMin=lo and (lo>t.deadMin or lo==t.deadMin and loOpen)
    local belowMax=hi and (hi<t.deadMax or hi==t.deadMax and hiOpen)
    if aboveMin and belowMax and FR.Range:CheckWeaponMelee(unit)==false
      and FR.Range:CheckConfiguredSpell(unit)==false then return "dead" end
  end
  local threshold=weapon and FR.db.deadZoneEnabled and math.max(t.rangedMin,t.deadMax) or t.rangedMin
  if hi and hi<=t.rangedMax and lo and (lo>threshold or lo==threshold and (threshold>t.nearMax or loOpen)) then return "ranged" end
  return "neutral"
end

function FR:SetDisplayMode(mode)
  if mode~="distance" and mode~="skills" then return end
  K.PositionStore:FinishFrameDrag(self.Display.frame)
  self.db.displayMode=mode;self.testState=nil;D:Invalidate();self.Display:Hide()
  self:RefreshDisplay(true);self:UpdateSettings()
end

-- Thresholds stay in yards; edits use the currently selected measurement unit.
function D:SetThreshold(key,value)
  local n=tonumber(value)
  if not number(n) or n~=math.floor(n) or n<0 or n>200 then return false,"0~200 범위의 정수를 입력하세요." end
  local t=K.CopyProfileValue(FR.db.distance.thresholds)
  if t[key]==nil then return false end
  t[key]=n/self:Multiplier()
  if t.deadMin>t.deadMax or t.nearMax>t.rangedMin or t.rangedMin>t.rangedMax then
    return false,"근접 최대 ≤ 원거리 최소 ≤ 원거리 최대, 데드존 최소 ≤ 최대를 확인하세요."
  end
  FR.db.distance.thresholds=t
  FR:RefreshDisplay(true)
  return true
end

function D:BuildSettings(panel)
  local UI=K.UI
  local b=UI:CreateBuilder(panel,0)
  local function cfg() return FR.db.distance end
  local function changed() FR:RefreshDisplay(true) end
  local function set(key)
    return function(value)
      if key=="locked" then K.PositionStore:FinishFrameDrag(FR.Display.frame) end
      cfg()[key]=value;changed()
    end
  end
  local function get(key) return function() return cfg()[key] end end
  local function targetNumeric() return FR.db.displayMode=="distance" end
  b:Section("대상 거리")
  b:Dropdown("거리 측정 방식",{{value="auto",text="자동 · 추정 허용"},{value="exact",text="정확한 거리만 · 1단위"}},get("measurement"),function(v)
    cfg().measurement=v;if v=="exact" then cfg().format="single";cfg().singleStep=1 end
    changed();FR:UpdateSettings()
  end)
  b:Dropdown("거리 형식",{{value="range",text="범위"},{value="single",text="단일 값"}},get("format"),set("format"))
  b:Dropdown("거리 단위",{{value="m",text="m"},{value="yd",text="yd"},{value="none",text="미표시"}},
    function() return cfg().showUnit and cfg().unit or "none" end,function(value)
      cfg().showUnit=value~="none"
      if value~="none" then cfg().unit=value;FR:NormalizeDistanceIntegers() end
      changed();FR:UpdateSettings()
    end)
  b:Slider("거리 구간 간격",1,10,1,get("bucketSize"),set("bucketSize"),function(v) return tostring(v) end)
  b:Slider("단일 값 표시 간격",1,5,1,get("singleStep"),set("singleStep"),tostring,function() return cfg().format=="single" end)
  b:Description("1단위 측정은 '정확한 거리만'을 선택하세요. 게임이 정확한 거리를 공개하지 않는 대상은 -로 표시합니다. 자동 모드의 ~는 구간 추정이며 중간 거리를 임의로 만들지 않습니다.",true)
  self.measurementLabel=b:Description("현재 대상: 확인 중",true)
  b:Slider("최대 표시 거리 (45~80m)",45,80,5,get("maxMeters"),set("maxMeters"),function(v) return string.format("%.0f m",v) end)
  b.cells[#b.cells].visible=function() return cfg().unit=="m" end
  b:Flush()
  b:Slider("최대 표시 거리 (45~80yd)",45,80,5,
    function() return math.floor(cfg().maxMeters/metersPerYard+.5) end,
    function(v) cfg().maxMeters=v*metersPerYard;changed() end,
    function(v) return string.format("%.0f yd",v) end)
  b.cells[#b.cells].visible=function() return cfg().unit=="yd" end
  b:Slider("거리 글자 크기",20,40,1,get("size"),set("size"),function(v) return v.." px" end,targetNumeric)
  b:PositionLock("거리 위치 잠금",get("locked"),set("locked"),targetNumeric)
  b:Slider("거리 X 위치",-3000,3000,1,get("x"),set("x"),nil,targetNumeric)
  b:Slider("거리 Y 위치",-3000,3000,1,get("y"),set("y"),nil,targetNumeric)
  b:Button("거리 위치 초기화",function()
    K.PositionStore:FinishFrameDrag(FR.Display.frame)
    cfg().x,cfg().y=FR.defaults.distance.x,FR.defaults.distance.y;changed()
  end,nil,targetNumeric)
  b:Section("거리 색상")
  local colorHeader=b.disclosures[#b.disclosures]
  self.thresholdControls={}
  local feedback
  for _,entry in ipairs({{"near","근접","nearMax"},{"dead","원거리 무기 데드존","deadMin","deadMax"},
      {"ranged","원거리","rangedMin","rangedMax"},{"far","최대 거리"},{"neutral","중립·미확인"}}) do
    local key,title,first,second=unpack(entry)
    local row=CreateFrame("Frame",nil,panel);row:SetSize(panel:GetWidth(),44)
    local label=UI:CreateLabel(row,title,0,-6)
    local sep=UI:CreateLabel(row,key=="far" and "+" or "~",0,-6)
    if key=="neutral" then sep:Hide() end
    local inputs={}
    local enabled=key=="dead" and function() return FR.Range:UsesRangedWeapon()==true end or nil
    for _,fieldKey in ipairs({first,second}) do
      local function valueText()
        return tostring(D:ThresholdValue(fieldKey))
      end
      local input=UI:CreateEditBox(row,0,0,70,valueText,function(value)
        if tonumber(value)==tonumber(valueText()) then return end
        local ok,message=D:SetThreshold(fieldKey,value)
        if feedback then feedback:SetText(ok and "" or message) end
        UI:Refresh(panel)
      end,enabled)
      input:SetMaxLetters(12)
      inputs[#inputs+1]=input
      UI.SettingsNavigation:Attach(row,input,title..(second and (#inputs==1 and " 최소" or " 최대") or " 최대"),nil,nil,enabled)
    end
    local cap
    if key=="far" then
      cap=UI:CreateLabel(row,"",0,-6)
      local refresh=CreateFrame("Frame",nil,row)
      refresh.Refresh=function() cap:SetText(tostring(D:DisplayCap())) end
      UI:RegisterControl(row,refresh);refresh:Refresh()
    end
    local picker=UI:CreateColorPicker(row,"",0,24,function() return unpack(cfg().colors[key]) end,function(r,g,bl,a)
      cfg().colors[key]={r,g,bl,a or 1};changed()
    end,enabled,nil,true)
    UI.SettingsNavigation:Attach(row,picker,title.." 구간",nil,nil,enabled)
    local function fit()
      local width=row:GetWidth()
      local start=math.min(180,math.max(138,width*.28))
      local inputWidth=math.max(46,math.min(76,(width-start-picker:GetWidth()-48)/2))
      local minX=start
      local separatorX=minX+inputWidth+6
      local maxX=separatorX+18
      local pickerX=maxX+inputWidth+12
      label:SetWidth(start-12)
      if #inputs==2 then
        inputs[1]:ClearAllPoints();inputs[1]:SetPoint("TOPLEFT",minX,0);inputs[1]:SetWidth(inputWidth)
      end
      if #inputs>0 then
        local last=inputs[#inputs];last:ClearAllPoints();last:SetPoint("TOPLEFT",maxX,0);last:SetWidth(inputWidth)
      end
      if cap then
        cap:ClearAllPoints();cap:SetPoint("TOPLEFT",maxX,-6);cap:SetWidth(inputWidth)
        sep:ClearAllPoints();sep:SetPoint("TOPLEFT",maxX+inputWidth-8,-6)
      else
        sep:ClearAllPoints();sep:SetPoint("TOPLEFT",separatorX,-6)
      end
      picker:ClearAllPoints();picker:SetPoint("TOPLEFT",pickerX,0)
      return 44
    end
    self.thresholdControls[key]={row=row,inputs=inputs,separator=sep,picker=picker,label=label,cap=cap,fit=fit}
    fit()
  end
  self:BuildColorRows(b,panel,colorHeader)
  feedback=b:Description("",true)
  b.cells[#b.cells].visible=function() return feedback and feedback:GetText()~="" end
  b:Flush();b:Reflow()
end

function D:UpdateMeasurementLabel(result)
  local label=self.measurementLabel
  if not label then return end
  local text="현재 대상: 확인 불가"
  if result and result.kind=="exact" then text="현재 대상: 정확한 거리 · 설정한 표시 간격 적용"
  elseif result and result.reason=="exact-unavailable" then text="현재 대상: 1단위 측정 불가 · 정확한 거리 비공개/미지원"
  elseif result and result.kind=="range" then
    local unit=FR.db.distance.unit;local factor=self:Multiplier()
    local lo=result.lower and string.format("%.0f",math.floor(result.lower*factor)) or "0"
    local hi=result.upper and string.format("%.0f",math.ceil(result.upper*factor)) or "미확인"
    text="현재 대상: 범위 추정 ("..lo.." ~ "..hi.." "..unit..")"
  end
  if label:GetText()~=text then label:SetText(text) end
end
