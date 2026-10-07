local _, KHQOL = ...
local Tooltip = KHQOL.modules.tooltip
local Info = { cache={}, pending={}, ttl=45, activeGUID=nil, queuedUnit=nil }
Tooltip.playerInfo=Info
local isSecret=Tooltip.IsSecretValue
local publicCall=Tooltip.PublicCall
local publicUnit=Tooltip.IsPublicUnit
local function guidFor(unit) return Tooltip:GetReadableGUID(unit) end
local slots={1,2,3,5,6,7,8,9,10,11,12,13,14,15,16,17,18}
local specNames={
  WARRIOR={"무기","분노","방어"}, PALADIN={"신성","보호","징벌"}, HUNTER={"야수","사격","생존"},
  ROGUE={"암살","전투","잠행"}, PRIEST={"수양","신성","암흑"}, SHAMAN={"정기","고양","복원"},
  MAGE={"비전","화염","냉기"}, WARLOCK={"고통","악마","파괴"}, DRUID={"조화","야성","회복"},
}
local function good(v) return not isSecret(v) and type(v)=="number" and v>0 end
local function inspectArgs(inspect,unit) return inspect and true or nil, false, inspect and unit or nil end

function Info:Read(unit,inspect)
  if not publicUnit(unit) then return end
  local talents={0,0,0}; local icons={}
  local inspected,zero,inspectUnit=inspectArgs(inspect,unit)
  if GetNumTalentTabs then
    local tabs=publicCall(GetNumTalentTabs,inspected,zero,inspectUnit) or publicCall(GetNumTalentTabs,inspected) or publicCall(GetNumTalentTabs) or 0
    if type(tabs)~="number" then return end
    for i=1,math.min(3,tabs) do
      local points; local icon
      if GetTalentTabInfo then
        local _,texture,value=publicCall(GetTalentTabInfo,i,inspected,zero,inspectUnit)
        icon=texture
        if type(value)=="number" then points=value end
      end
      if not points and GetNumTalents and GetTalentInfo then
        points=0
        local count=publicCall(GetNumTalents,i,inspected,zero,inspectUnit) or 0
        if type(count)~="number" then return end
        for talent=1,count do
          local _,_,_,_,rank=publicCall(GetTalentInfo,i,talent,inspected,zero,inspectUnit)
          if type(rank)=="number" then points=points+rank end
        end
      end
      talents[i]=type(points)=="number" and points or 0; icons[i]=icon
    end
  end
  local highest,index=0,nil
  for i=1,3 do if talents[i]>highest then highest,index=talents[i],i end end
  local _,classToken=publicCall(UnitClass,unit)
  local spec=index and specNames[classToken] and specNames[classToken][index] and {name=specNames[classToken][index],icon=icons[index]} or nil

  local total,count=0,0
  if GetInventoryItemLink and GetItemInfo then
    for _,slot in ipairs(slots) do
      local link=publicCall(GetInventoryItemLink,unit,slot)
      if link then
        local _,_,_,level=publicCall(GetItemInfo,link)
        if good(level) then total=total+level; count=count+1 end
      end
    end
  end
  local ilvl=count>0 and math.floor(total/count+.5) or nil
  if not spec and not good(ilvl) then return end
  return {spec=spec,points=talents,itemLevel=ilvl,timestamp=GetTime()}
end

function Info:RemoveInformationLines(tooltip)
  if not Tooltip:CanModifyTooltip(tooltip) then return end
  local name=tooltip.GetName and tooltip:GetName(); if not name then return end
  for i=tooltip:NumLines(),1,-1 do
    local line=_G[name.."TextLeft"..i]; local text=line and line:GetText()
    if text and (text:find("전문화:",1,true) or text:find("특성 :",1,true) or text:find("아이템 레벨:",1,true)) then
      local last=tooltip:NumLines()
      for row=i,last-1 do
        for _,side in ipairs({"TextLeft","TextRight"}) do
          local here=_G[name..side..row]; local nextLine=_G[name..side..(row+1)]
          if here and nextLine then
            here:SetText(nextLine:GetText() or "")
            local r,g,b,a=nextLine:GetTextColor(); if r then here:SetTextColor(r,g,b,a) end
          end
        end
      end
      for _,side in ipairs({"TextLeft","TextRight"}) do local tail=_G[name..side..last]; if tail then tail:SetText("") end end
    end
  end
end

function Info:Append(tooltip,guid,data)
  if not publicUnit(guid) or not Tooltip:CanModifyTooltip(tooltip) then return end
  if guidFor(Tooltip:GetReadableUnit(tooltip))~=guid then return end
  if not data or tooltip.__KHQOLInfoGUID==guid then return end
  self:RemoveInformationLines(tooltip)
  tooltip.__KHQOLInfoGUID=guid
  if data.spec then
    local icon=data.spec.icon and ("|T"..data.spec.icon..":14:14:0:0|t ") or ""
    local points=data.points or {0,0,0}
    tooltip:AddLine(string.format("전문화: %s|cffffffff%s|r (%d/%d/%d)",icon,data.spec.name,points[1] or 0,points[2] or 0,points[3] or 0),1,.82,0,true)
  end
  if good(data.itemLevel) then tooltip:AddLine("아이템 레벨: "..data.itemLevel,1,1,1,true) end
  tooltip:Show()
end

function Info:InspectUnit(guid)
  if not publicUnit(guid) then return end
  local pending=self.pending[guid]
  if pending and guidFor(pending.unit)==guid then return pending.unit end
  if InspectFrame and guidFor(InspectFrame.unit)==guid then return InspectFrame.unit end
  local unit=Tooltip:GetReadableUnit(GameTooltip)
  if guidFor(unit)==guid then return unit end
end

function Info:OnUnit(tooltip,unit)
  if not Tooltip:GetDB().showPlayerInfo or not publicUnit(unit) or not Tooltip:CanModifyTooltip(tooltip) then return end
  if publicCall(UnitIsPlayer,unit)~=true or publicCall(UnitIsFriend,"player",unit)~=true then return end
  local guid=guidFor(unit); if not guid then return end
  if guidFor(Tooltip:GetReadableUnit(tooltip))~=guid then return end
  if tooltip.__KHQOLInfoUnitGUID~=guid then
    tooltip.__KHQOLInfoUnitGUID=guid; tooltip.__KHQOLInfoGUID=nil
    -- Never leave the previous target's delayed inspection result visible.
    self:RemoveInformationLines(tooltip)
  end
  local cached=self.cache[guid]
  if cached and GetTime()-cached.timestamp<self.ttl then return self:Append(tooltip,guid,cached) end
  if publicCall(UnitIsUnit,unit,"player")==true then
    local data=self:Read(unit,false); if data then self.cache[guid]=data; self:Append(tooltip,guid,data) end
  elseif publicCall(CanInspect,unit)==true and NotifyInspect and not self.pending[guid] then
    -- Inspect APIs have one shared result buffer.  Queue hover changes rather
    -- than starting a second request that could overwrite the first result.
    if self.activeGUID and self.activeGUID~=guid then self.queuedUnit=unit; return end
    self.activeGUID=guid; self.pending[guid]={unit=unit,at=GetTime()}
    if not pcall(NotifyInspect,unit) then self.pending[guid]=nil; self.activeGUID=nil end
  end
end

function Info:Initialize()
  if self.init then return end
  self.init=true
  local f=CreateFrame("Frame"); f:RegisterEvent("INSPECT_READY")
  f:SetScript("OnEvent",function(_,_,guid)
    if not publicUnit(guid) or Info.activeGUID~=guid then return end
    local function finish()
      local current=Tooltip:GetReadableUnit(GameTooltip)
      local valid=Tooltip:CanModifyTooltip(GameTooltip) and guidFor(current)==guid
      if valid and InspectFrame then
        local inspectUnit=InspectFrame.unit
        if isSecret(inspectUnit) or (inspectUnit and guidFor(inspectUnit)~=guid) then valid=false end
      end
      local data=valid and Info:Read(current,true)
      Info.pending[guid]=nil; Info.activeGUID=nil
      if valid and data then Info.cache[guid]=data end
      if valid and data and GameTooltip:IsShown() then
        -- Update the existing tooltip instead of rebuilding it with SetUnit.
        -- Rebuilding briefly put the target above the later inspection rows.
        GameTooltip.__KHQOLInfoGUID=nil; Info:Append(GameTooltip,guid,data)
      end
      if ClearInspectPlayer then ClearInspectPlayer() end
      local latest=Tooltip:GetReadableUnit(GameTooltip)
      Info.queuedUnit=nil
      if latest and GameTooltip:IsShown() then Info:OnUnit(GameTooltip,latest) end
    end
    -- Forever fires INSPECT_READY slightly before talent ranks/icons are
    -- materialized.  Keep the inspect data briefly, then read the final state.
    if C_Timer and C_Timer.After then C_Timer.After(.15,finish) else finish() end
  end)
end
