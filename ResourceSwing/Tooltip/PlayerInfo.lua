local _, KHQOL = ...
local Tooltip = KHQOL.modules.tooltip
local Info = {cache={},pending={},ttl=45,serial=0,minInterval=2,timeout=4,
  applied=setmetatable({},{__mode="k"}),failedUntil={}}
Tooltip.playerInfo=Info
local isSecret=Tooltip.IsSecretValue
local publicCall=Tooltip.PublicCall
local publicUnit=Tooltip.IsPublicUnit
local function guidFor(unit) return Tooltip:GetReadableGUID(unit) end
local function number(v) return not isSecret(v) and type(v)=="number" and v==v and v~=math.huge and v~=-math.huge end
local function good(v) return number(v) and v>0 end
local function text(v) return not isSecret(v) and type(v)=="string" and v~="" end
local function texture(v) return text(v) and v or good(v) and v or nil end
local slots={1,2,3,5,6,7,8,9,10,11,12,13,14,15,16,17,18}
local specNames={
  WARRIOR={"무기","분노","방어"}, PALADIN={"신성","보호","징벌"}, HUNTER={"야수","사격","생존"},
  ROGUE={"암살","전투","잠행"}, PRIEST={"수양","신성","암흑"}, SHAMAN={"정기","고양","복원"},
  MAGE={"비전","화염","냉기"}, WARLOCK={"고통","악마","파괴"}, DRUID={"조화","야성","회복"},
}
function Info:Enabled() return Tooltip:IsEnabled() and Tooltip:GetDB().showPlayerInfo~=false end
function Info:ManualInspectOpen() return InspectFrame and publicCall(InspectFrame.IsShown,InspectFrame)==true end
function Info:ReadTalents(unit,inspect)
  local api=C_SpecializationInfo
  local _,classToken,classID=publicCall(UnitClass,unit)
  local group=publicCall(api and api.GetActiveSpecGroup,inspect==true,false)
  if not good(group) then group=nil end
  local count=publicCall(GetNumTalentTabs,inspect==true,false)
  if not number(count) and good(classID) then count=publicCall(api and api.GetNumSpecializationsForClassID,classID) end
  if not number(count) then count=specNames[classToken] and #specNames[classToken] or 0 end
  local talents,icons,names={0,0,0},{},{}
  local readPoints=false
  for i=1,math.min(3,count) do
    local _,name,_,icon,_,_,points=publicCall(api and api.GetSpecializationInfo,i,inspect==true,false,inspect and unit or nil,nil,group,classID)
    if not number(points) then
      -- Current compatibility wrapper returns id/name/description/icon/points.
      -- Older clients return name/icon/points. The fourth argument is a numeric
      -- talent group, never a unit token.
      local a,b,c,d,e=publicCall(GetTalentTabInfo,i,inspect==true,false,group)
      if number(a) then name,icon,points=b,d,e else name,icon,points=a,b,c end
    end
    if not number(points) and GetNumTalents and GetTalentInfo then
      local n=publicCall(GetNumTalents,i,inspect==true,false)
      if number(n) and n>=0 and n<=100 then
        points=0
        for talent=1,n do
          local _,_,_,_,rank=publicCall(GetTalentInfo,i,talent,inspect==true,false,group)
          if number(rank) then points=points+rank end
        end
      end
    end
    if number(points) and points>=0 then talents[i]=math.floor(points);readPoints=true end
    icons[i]=texture(icon); names[i]=text(name) and name or nil
  end
  local highest,index=0,nil
  for i=1,3 do if talents[i]>highest then highest,index=talents[i],i end end
  if index then
    local name=(specNames[classToken] and specNames[classToken][index]) or names[index]
    if name then return {name=name,icon=icons[index]},talents end
  end
  -- Clients using a selected specialization rather than invested talent trees.
  local id=inspect and publicCall(api and api.GetInspectSpecialization,unit)
  if good(id) then
    local _,name,_,icon=publicCall(GetSpecializationInfoForSpecID or GetSpecializationInfoByID,id)
    if text(name) then return {name=name,icon=texture(icon)},readPoints and talents or nil end
  elseif not inspect then
    local selected=publicCall(api and api.GetSpecialization,false,false)
    if good(selected) then
      local _,name,_,icon=publicCall(api.GetSpecializationInfo,selected,false,false)
      if text(name) then return {name=name,icon=texture(icon)},readPoints and talents or nil end
    end
  end
end
function Info:ReadItems(unit,inspect)
  -- Prefer the client's equipped inspection average when supplied. Classic
  -- variants may return zero, in which case retain the original slot average.
  local average=inspect and publicCall(C_PaperDollInfo and C_PaperDollInfo.GetInspectItemLevel,unit)
  if not inspect then local _,equipped=publicCall(GetAverageItemLevel);average=equipped end
  if good(average) then return math.floor(average+.5),false end
  local itemInfo=(C_Item and C_Item.GetItemInfo) or GetItemInfo
  if not GetInventoryItemLink or not itemInfo then return nil,true end
  local total,count,missing=0,0,false
  for _,slot in ipairs(slots) do
    local link=publicCall(GetInventoryItemLink,unit,slot)
    local id=publicCall(GetInventoryItemID,unit,slot)
    if text(link) then
      local _,_,_,level=publicCall(itemInfo,link)
      if good(level) then total=total+level;count=count+1
      else
        missing=true
        if not good(id) then id=publicCall(C_Item and C_Item.GetItemInfoInstant,link) end
        if good(id) then publicCall(C_Item and C_Item.RequestLoadItemDataByID,id) end
      end
    elseif good(id) then missing=true end
  end
  -- Never cache an average calculated from just the items that loaded first.
  return not missing and count>0 and math.floor(total/count+.5) or nil,missing or count==0
end
function Info:Read(unit,inspect)
  if not publicUnit(unit) then return end
  local spec,points=self:ReadTalents(unit,inspect)
  local ilvl,missing=self:ReadItems(unit,inspect)
  if not spec and not good(ilvl) then return end
  return {spec=spec,points=points,itemLevel=ilvl,timestamp=GetTime(),partial=not spec or missing}
end

function Info:RemoveInformationLines(tooltip)
  if not Tooltip:CanModifyTooltip(tooltip) then return end
  local name=tooltip.GetName and tooltip:GetName(); if not name then return end
  local removed=0
  for i=tooltip:NumLines(),1,-1 do
    local line=_G[name.."TextLeft"..i]; local text=line and line:GetText()
    if text and (text:find("전문화:",1,true) or text:find("특성 :",1,true) or text:find("아이템 레벨:",1,true)) then
      removed=removed+1
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
  if removed>0 then
    -- AddLine increases the native line count; reuse the rows just cleared
    -- when a delayed inspect result completes an earlier partial result.
    tooltip.__KHQOLInfoFreeRow=tooltip:NumLines()-removed+1
  end
end

function Info:Append(tooltip,guid,data)
  if not self:Enabled() or not publicUnit(guid) or not Tooltip:CanModifyTooltip(tooltip) then return end
  if guidFor(Tooltip:GetReadableUnit(tooltip))~=guid then return end
  if not data or (tooltip.__KHQOLInfoGUID==guid and self.applied[tooltip]==data) then return end
  self:RemoveInformationLines(tooltip)
  tooltip.__KHQOLInfoGUID=guid;self.applied[tooltip]=data
  local function addLine(value,r,g,b)
    local row=tooltip.__KHQOLInfoFreeRow
    local name=tooltip:GetName()
    local left=row and row<=tooltip:NumLines() and _G[name.."TextLeft"..row]
    local right=row and _G[name.."TextRight"..row]
    if left and (left:GetText() or "")=="" and (not right or (right:GetText() or "")=="") then
      left:SetText(value);left:SetTextColor(r,g,b,1);left:Show()
      if left.SetWordWrap then left:SetWordWrap(true) end
      if right then right:SetText("");right:Hide() end
      tooltip.__KHQOLInfoFreeRow=row+1
    else
      tooltip.__KHQOLInfoFreeRow=nil;tooltip:AddLine(value,r,g,b,true)
    end
  end
  if data.spec then
    local icon=data.spec.icon and ("|T"..data.spec.icon..":14:14:0:0|t ") or ""
    local points=data.points
    local distribution=points and string.format(" (%d/%d/%d)",points[1] or 0,points[2] or 0,points[3] or 0) or ""
    addLine("전문화: "..icon.."|cffffffff"..data.spec.name.."|r"..distribution,1,.82,0)
  end
  if good(data.itemLevel) then addLine("아이템 레벨: "..data.itemLevel,1,1,1) end
  Tooltip:ApplyTextSize(tooltip)
  tooltip:Show()
end
function Info:InspectUnit(guid)
  if not publicUnit(guid) then return end
  local pending=self.pending[guid]
  if pending and guidFor(pending.unit)==guid then return pending.unit end
  local unit=Tooltip:GetReadableUnit(GameTooltip)
  if guidFor(unit)==guid then return unit end
end
function Info:Cancel(clearOwned)
  local request=self.activeGUID and self.pending[self.activeGUID]
  self.serial=self.serial+1;self.activeGUID=nil;self.pending={};self.queuedUnit=nil;self.wakeSerial=nil
  -- A visible manual inspection owns the shared result buffer. A timeout or
  -- mismatched event does not prove that our request still owns it either.
  if clearOwned and request and request.ready and not self:ManualInspectOpen() then publicCall(ClearInspectPlayer) end
end
function Info:Wake(delay)
  if not self:Enabled() or self.wakeSerial==self.serial or not C_Timer or not C_Timer.After then return end
  local serial=self.serial;self.wakeSerial=serial
  C_Timer.After(delay,function()
    if self.serial~=serial then return end
    self.wakeSerial=nil
    if self:Enabled() and GameTooltip:IsShown() then
      local unit=Tooltip:GetReadableUnit(GameTooltip)
      if unit then self:OnUnit(GameTooltip,unit) end
    end
  end)
end
function Info:FinishInspect(request,attempt)
  if self.pending[request.guid]~=request or self.activeGUID~=request.guid then return end
  if not self:Enabled() or self:ManualInspectOpen() then self:Cancel(false);return end
  local unit=self:InspectUnit(request.guid)
  if not unit then self:Cancel(false);self:Wake(self.minInterval);return end
  local data=self:Read(unit,true)
  if data then
    data.retryAfter=GetTime()+5;self.cache[request.guid]=data
    if GameTooltip:IsShown() then self:Append(GameTooltip,request.guid,data) end
  end
  if (not data or data.partial) and attempt<4 and C_Timer and C_Timer.After then
    C_Timer.After(attempt*.2,function() self:FinishInspect(request,attempt+1) end)
    return
  end
  if not data then self.failedUntil[request.guid]=GetTime()+5 end
  self:Cancel(true);self:Wake(self.minInterval)
end
function Info:OnUnit(tooltip,unit)
  if not self:Enabled() or not publicUnit(unit) or not Tooltip:CanModifyTooltip(tooltip) then return end
  if publicCall(UnitIsPlayer,unit)~=true or publicCall(UnitIsFriend,"player",unit)~=true then return end
  local guid=guidFor(unit);if not guid or guidFor(Tooltip:GetReadableUnit(tooltip))~=guid then return end
  if tooltip.__KHQOLInfoUnitGUID~=guid then
    tooltip.__KHQOLInfoUnitGUID=guid;tooltip.__KHQOLInfoGUID=nil;self.applied[tooltip]=nil
    self:RemoveInformationLines(tooltip)
  end
  local now=GetTime();local cached=self.cache[guid]
  if cached and now-cached.timestamp<self.ttl then
    self:Append(tooltip,guid,cached)
    if not cached.partial or now<(cached.retryAfter or 0) then return end
  end
  if publicCall(UnitIsUnit,unit,"player")==true then
    if now<(self.failedUntil[guid] or 0) then return end
    local data=self:Read(unit,false)
    if data then data.retryAfter=now+2;self.cache[guid]=data;self:Append(tooltip,guid,data) end
    if not data then self.failedUntil[guid]=now+2 end
    return
  end
  if self:ManualInspectOpen() or publicCall(CanInspect,unit)~=true or type(NotifyInspect)~="function" then return end
  if self.activeGUID then
    local request=self.pending[self.activeGUID]
    if request and now-request.at>=self.timeout then self:Cancel(false)
    else self.queuedUnit=unit;return end
  end
  local wait=math.max((self.nextRequestAt or 0)-now,(self.failedUntil[guid] or 0)-now)
  if wait>0 then self:Wake(wait);return end
  local request={guid=guid,unit=unit,at=now}
  self.activeGUID=guid;self.pending[guid]=request;self.nextRequestAt=now+self.minInterval
  local ok=pcall(NotifyInspect,unit)
  if not ok then self.failedUntil[guid]=now+5;self:Cancel(false);return end
  if C_Timer and C_Timer.After then C_Timer.After(self.timeout,function()
    if self.pending[guid]==request then self:Cancel(false);self:Wake(self.minInterval) end
  end) end
end
function Info:Initialize()
  if self.init then return end
  self.init=true
  local f=CreateFrame("Frame");self.events=f;f:RegisterEvent("INSPECT_READY")
  f:SetScript("OnEvent",function(_,_,guid)
    if not publicUnit(guid) or not self.activeGUID then return end
    if self.activeGUID~=guid then self:Cancel(false);self:Wake(self.minInterval);return end
    local request=self.pending[guid]
    if not request or request.ready then return end
    request.ready=true
    if C_Timer and C_Timer.After then C_Timer.After(.15,function() self:FinishInspect(request,1) end)
    else self:FinishInspect(request,4) end
  end)
  GameTooltip:HookScript("OnHide",function() self:Cancel(true) end)
end
