local _, KHQOL = ...
local N=KHQOL.modules.npcAlert
N.defaults={banner=true,bannerDuration=3,bannerScale=1,bannerAlpha=1,sound=true,reAlertCooldown=10,
  indicator={enabled=true,size=56,radius=180,alpha=1}}
N.activeNPCs,N.unitGUIDs,N.cooldowns,N.queue,N.pending={},{},{},{},{}
N.sequence=0; N.generation=0
N.colors={NORMAL={1,.48,.08},HIGH={1,.15,.12},CRITICAL={.75,.02,.04}}
N.levels={NORMAL=1,HIGH=2,CRITICAL=3}
N.labels={NORMAL="보통",HIGH="높음",CRITICAL="치명적"}
function N.Readable(v) return not (issecretvalue and issecretvalue(v)) end
function N.Number(v) if N.Readable(v) and type(v)=="number" and v==v and math.abs(v)<math.huge then return v end end
function N.Text(v) if N.Readable(v) and type(v)=="string" then return v end end
function N.Call(fn,...)
  if type(fn)~="function" then return end
  local ok,v=pcall(fn,...); if ok and N.Readable(v) then return v end
end
local function id(v) return N.Number(v) and v>0 and v%1==0 and v<=2147483647 end
local function bounded(v,default,lo,hi) return math.max(lo,math.min(hi,N.Number(v) or default)) end
function N:GetDB()
  local db=KHQOL.db.modules.npcAlert
  if type(db)~="table" then db={}; KHQOL.db.modules.npcAlert=db end
  KHQOL.MergeDefaults(db,self.defaults,"types")
  db.reAlertCooldown=bounded(db.reAlertCooldown,10,1,300)
  db.bannerDuration=bounded(db.bannerDuration,3,1,10)
  db.bannerScale=bounded(db.bannerScale,1,.5,2); db.bannerAlpha=bounded(db.bannerAlpha,1,.1,1)
  local d=db.indicator; d.size=bounded(d.size,56,24,128); d.radius=bounded(d.radius,180,40,500); d.alpha=bounded(d.alpha,1,.1,1)
  self.db=db; return db
end
function N:GetData()
  local db=KHQOL.db
  if type(db.globalData)~="table" then db.globalData={} end
  if type(db.globalData.npcAlert)~="table" then db.globalData.npcAlert={entries={},nextID=1} end
  local data=db.globalData.npcAlert
  if type(data.entries)~="table" then data.entries={} end
  if not id(data.nextID) then data.nextID=1 end
  return data
end
function N:Normalize(r)
  if type(r)~="table" or not id(r.mapID) then return end
  if r.npcID~=nil and not id(r.npcID) then return end
  r.name=type(r.name)=="string" and r.name or ""
  if not r.npcID and r.name=="" then return end
  r.dangerLevel=self.levels[r.dangerLevel] and r.dangerLevel or "HIGH"
  for _,key in ipairs({"enabled","showBanner","showIndicator","sound"}) do r[key]=r[key]~=false end
  return r
end
function N:IsEnabled() return KHQOL.db and KHQOL:GetEnabled("npcAlert") end
function N:NPCID(guid)
  guid=self.Text(guid); if not guid then return end
  -- Validate the complete modern GUID schema, not byte offsets/substrings.
  local kind,zero,server,instance,zone,npc,spawn=guid:match("^([A-Za-z]+)%-(%d+)%-(%d+)%-(%d+)%-(%d+)%-(%d+)%-(%x+)$")
  if (kind=="Creature" or kind=="Vehicle") and spawn then
    local value=tonumber(npc); if id(value) then return value end
  end
end
function N:CurrentMap()
  local map=self.Call(C_Map and C_Map.GetBestMapForUnit,"player")
  if not id(map) then return end
  local info=self.Call(C_Map and C_Map.GetMapInfo,map)
  local name
  if type(info)=="table" then name=self.Text(info.name) end
  return map,name or self.Text(self.Call(GetZoneText)) or "지역명 확인 불가"
end
function N:CreateFrames()
  if self.frame then return end
  local root=CreateFrame("Frame","KHQOLNPCAlertFrame",UIParent); self.frame=root; root:EnableMouse(false)
  root:SetSize(1,1); root:SetPoint("CENTER",UIParent,"CENTER")
  local banner=CreateFrame("Frame",nil,UIParent); self.banner=banner
  banner:SetSize(380,78); banner:SetPoint("CENTER",UIParent,"CENTER",0,165); banner:SetFrameStrata("HIGH"); banner:EnableMouse(false)
  local bg=banner:CreateTexture(nil,"BACKGROUND"); bg:SetAllPoints(); bg:SetColorTexture(0,0,0,.75)
  self.borders={}
  for i=1,4 do self.borders[i]=banner:CreateTexture(nil,"BORDER"); self.borders[i]:SetTexture("Interface\\Buttons\\WHITE8X8") end
  self.borders[1]:SetPoint("TOPLEFT"); self.borders[1]:SetPoint("TOPRIGHT"); self.borders[1]:SetHeight(2)
  self.borders[2]:SetPoint("BOTTOMLEFT"); self.borders[2]:SetPoint("BOTTOMRIGHT"); self.borders[2]:SetHeight(2)
  self.borders[3]:SetPoint("TOPLEFT"); self.borders[3]:SetPoint("BOTTOMLEFT"); self.borders[3]:SetWidth(2)
  self.borders[4]:SetPoint("TOPRIGHT"); self.borders[4]:SetPoint("BOTTOMRIGHT"); self.borders[4]:SetWidth(2)
  banner.icon=banner:CreateTexture(nil,"ARTWORK"); banner.icon:SetSize(30,30); banner.icon:SetPoint("LEFT",16,0)
  banner.icon:SetTexture("Interface\\Icons\\Ability_Rogue_Ambush")
  banner.title=banner:CreateFontString(nil,"OVERLAY","GameFontHighlight"); banner.title:SetFont(KHQOL.UI:Font(),19,"OUTLINE")
  banner.title:SetPoint("TOPLEFT",58,-14); banner.title:SetWidth(306); banner.title:SetJustifyH("LEFT")
  banner.name=banner:CreateFontString(nil,"OVERLAY","GameFontHighlight"); banner.name:SetFont(KHQOL.UI:Font(),17,"OUTLINE")
  banner.name:SetPoint("TOPLEFT",58,-43); banner.name:SetWidth(306); banner.name:SetJustifyH("LEFT")
  local indicator=CreateFrame("Frame",nil,UIParent); self.indicator=indicator
  indicator:SetFrameStrata("HIGH"); indicator:EnableMouse(false)
  indicator.arrow=indicator:CreateTexture(nil,"ARTWORK"); indicator.arrow:SetAllPoints()
  indicator.arrow:SetTexture("Interface\\AddOns\\KHQOL\\Media\\QuestNavigator\\Arrow.tga")
  indicator.name=indicator:CreateFontString(nil,"OVERLAY","GameFontHighlight"); indicator.name:SetFont(KHQOL.UI:Font(),12,"OUTLINE")
  indicator.name:SetPoint("TOP",indicator,"BOTTOM",0,-4); indicator.name:SetWidth(200)
  local fade=indicator:CreateAnimationGroup(); local a=fade:CreateAnimation("Alpha")
  a:SetFromAlpha(1); a:SetToAlpha(0); a:SetDuration(.2)
  fade:SetScript("OnFinished",function() indicator:Hide(); indicator:SetAlpha(self.db.indicator.alpha); self.fading=false end)
  self.fade=fade; banner:Hide(); indicator:Hide(); root:Hide()
  self.update=function(_,dt)
    self.elapsed=(self.elapsed or 0)+dt
    if self.elapsed>=.1 then self.elapsed=0; self:RenderIndicator() end
  end
end
function N:PlayWarning(r)
  if self.db.sound and r.sound and PlaySound then pcall(PlaySound,SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959,"Master") end
end
function N:ShowBanner(r)
  self.bannerSerial=(self.bannerSerial or 0)+1
  local serial=self.bannerSerial; local c=self.colors[r.dangerLevel]
  self.banner:SetScale(self.db.bannerScale); self.banner:SetAlpha(self.db.bannerAlpha)
  self.banner.title:SetText("위험 NPC 발견 · "..self.labels[r.dangerLevel]); self.banner.title:SetTextColor(unpack(c))
  self.banner.name:SetText(r.name); self.banner.icon:SetVertexColor(unpack(c))
  for _,border in ipairs(self.borders) do border:SetVertexColor(unpack(c)) end
  self.banner:Show()
  C_Timer.After(self.db.bannerDuration,function()
    if serial~=self.bannerSerial then return end
    self.banner:Hide()
    if #self.queue>0 and self:IsEnabled() then self:ShowBanner(table.remove(self.queue,1)) end
  end)
end
function N:Warn(enemy)
  local now=GetTime(); local last=self.cooldowns[enemy.guid]
  if last and now-last<self.db.reAlertCooldown then return end
  self.cooldowns[enemy.guid]=now
  local r={name=enemy.name,dangerLevel=enemy.record.dangerLevel,sound=enemy.record.sound}
  self:PlayWarning(r)
  if self.db.banner and enemy.record.showBanner then
    if self.banner:IsShown() then if #self.queue<8 then self.queue[#self.queue+1]=r end
    else self:ShowBanner(r) end
  end
  -- Bound runtime cooldown history without idle polling.
  local count=0
  for guid,time in pairs(self.cooldowns) do
    if now-time>300 then self.cooldowns[guid]=nil else count=count+1 end
  end
  if count>256 then
    local oldest,stamp
    for guid,time in pairs(self.cooldowns) do if not stamp or time<stamp then oldest,stamp=guid,time end end
    if oldest then self.cooldowns[oldest]=nil end
  end
end
function N:RemoveUnit(unit)
  self.pending[unit]=nil
  local guid=self.unitGUIDs[unit]; self.unitGUIDs[unit]=nil
  local enemy=guid and self.activeNPCs[guid]
  if enemy then
    enemy.units[unit]=nil
    if not next(enemy.units) then self.activeNPCs[guid]=nil end
  end
end
function N:Detect(unit,retry)
  if not self:IsEnabled() or self.inWorld==false or not self.hasEntries or not self.Text(unit) then return end
  if unit~="target" and unit~="mouseover" and not unit:match("^nameplate%d+$") then return end
  local guid=self.Text(self.Call(UnitGUID,unit))
  if self.unitGUIDs[unit] and self.unitGUIDs[unit]~=guid then self:RemoveUnit(unit) end
  local npcID=self:NPCID(guid)
  if not npcID then
    -- Some clients announce plates before exposing their GUID. Bounded retries.
    if not retry and unit:match("^nameplate%d+$") then
      local ticket={}; self.pending[unit]=ticket; local generation=self.generation
      for _,delay in ipairs({.1,.3,.7}) do
        C_Timer.After(delay,function()
          if generation==self.generation and self.pending[unit]==ticket and self:IsEnabled() then
            self:Detect(unit,true); self:RenderIndicator()
            if delay==.7 then self.pending[unit]=nil end
          end
        end)
      end
    end
    return
  end
  local name=self.Text(self.Call(UnitName,unit))
  local record=self.byID[npcID] or (name and self.byName[name])
  if not record then self:RemoveUnit(unit); return end
  self.pending[unit]=nil
  local enemy=self.activeNPCs[guid]
  if not enemy then
    self.sequence=self.sequence+1
    enemy={guid=guid,npcID=npcID,name=record.name~="" and record.name or name or ("NPC "..npcID),
      record=record,firstSeen=GetTime(),order=self.sequence,units={}}
    local previous=self.previousActive and self.previousActive[guid]
    if previous then enemy.firstSeen=previous.firstSeen; enemy.order=previous.order end
    self.activeNPCs[guid]=enemy; if not previous then self:Warn(enemy) end
  end
  enemy.units[unit]=true; self.unitGUIDs[unit]=guid
end
function N:PlateOffset(unit,guid)
  -- Never alter a nameplate or use world/Navigator coordinates.
  local ok,dx,dy=pcall(function()
    if self.Call(UnitGUID,unit)~=guid then return end
    local plate=self.Call(C_NamePlate and C_NamePlate.GetNamePlateForUnit,unit)
    if not plate or self.Call(plate.IsForbidden,plate) or not self.Call(plate.IsShown,plate) then return end
    local x,y=plate:GetCenter(); local cx,cy=UIParent:GetCenter()
    local ps,us=plate:GetEffectiveScale(),UIParent:GetEffectiveScale()
    if not self.Number(x) or not self.Number(y) or not self.Number(cx) or not self.Number(cy) or not self.Number(ps) or not self.Number(us) or us<=0 then return end
    x,y=x*ps/us-cx,y*ps/us-cy
    if math.abs(x)>UIParent:GetWidth()/2 or math.abs(y)>UIParent:GetHeight()/2 or x*x+y*y<1 then return end
    return x,y
  end)
  if ok then return dx,dy end
end
function N:SelectIndicator()
  local best,bx,by,bd
  for guid,enemy in pairs(self.activeNPCs) do
    if enemy.record.showIndicator then
      for unit in pairs(enemy.units) do
        if unit:match("^nameplate%d+$") then
          local dx,dy=self:PlateOffset(unit,guid)
          if dx and dy then
            local d=dx*dx+dy*dy; local level=self.levels[enemy.record.dangerLevel]
            if not best or level>self.levels[best.record.dangerLevel] or
              level==self.levels[best.record.dangerLevel] and (d<bd or d==bd and enemy.order<best.order) then
              best,bx,by,bd=enemy,dx,dy,d
            end
          end
        end
      end
    end
  end
  return best,bx,by
end
function N:HideIndicator(immediate)
  self.selected=nil
  if immediate then self.fade:Stop(); self.fading=false; self.indicator:Hide()
  elseif self.indicator:IsShown() and not self.fading then self.fading=true; self.fade:Play() end
end
function N:DrawIndicator(enemy,dx,dy)
  local angle=math.atan2(dy,dx); local d=self.db.indicator; local c=self.colors[enemy.record.dangerLevel]
  local ok=pcall(function()
    self.indicator.arrow:SetRotation(angle-math.pi/2)
    self.indicator:ClearAllPoints(); self.indicator:SetPoint("CENTER",UIParent,"CENTER",math.cos(angle)*d.radius,math.sin(angle)*d.radius)
  end)
  if not ok then self:HideIndicator(true); return end
  self.fade:Stop(); self.fading=false; self.selected=enemy.guid
  self.indicator:SetSize(d.size,d.size); self.indicator:SetAlpha(d.alpha)
  self.indicator.arrow:SetVertexColor(unpack(c)); self.indicator.name:SetText(enemy.name); self.indicator.name:SetTextColor(unpack(c)); self.indicator:Show()
end
function N:RenderIndicator()
  if not self.frame then return end
  if not self:IsEnabled() then self:HideIndicator(true); self.frame:SetScript("OnUpdate",nil); self.frame:Hide(); return end
  local run=false
  if self.testing then
    self:DrawIndicator({guid="TEST",name="테스트 위험 NPC",record={dangerLevel="HIGH"}},1,1)
  elseif self.db.indicator.enabled then
    -- Revalidate only currently tracked tokens, never scan the world per tick.
    local remove={}
    for unit,guid in pairs(self.unitGUIDs) do
      if self.Text(self.Call(UnitGUID,unit))~=guid then remove[#remove+1]=unit end
    end
    for _,unit in ipairs(remove) do self:RemoveUnit(unit) end
    local enemy,dx,dy=self:SelectIndicator()
    if enemy then self:DrawIndicator(enemy,dx,dy) else self:HideIndicator(false) end
    for _,e in pairs(self.activeNPCs) do
      if e.record.showIndicator then for unit in pairs(e.units) do if unit:match("^nameplate%d+$") then run=true; break end end end
    end
  else self:HideIndicator(true) end
  self.frame:SetScript("OnUpdate",run and self.update or nil); self.frame:SetShown(run)
end
local scanEvents={"NAME_PLATE_UNIT_ADDED","NAME_PLATE_UNIT_REMOVED","PLAYER_TARGET_CHANGED","UPDATE_MOUSEOVER_UNIT","UNIT_NAME_UPDATE"}
local zoneEvents={"PLAYER_ENTERING_WORLD","ZONE_CHANGED_NEW_AREA","ZONE_CHANGED","ZONE_CHANGED_INDOORS","PLAYER_LEAVING_WORLD"}
function N:ClearVisuals()
  self.testing=false; self.testSerial=(self.testSerial or 0)+1; self.bannerSerial=(self.bannerSerial or 0)+1
  self.queue={}; self.banner:Hide(); self:HideIndicator(true); self.frame:SetScript("OnUpdate",nil); self.frame:Hide()
end
function N:RefreshMap(quiet)
  local previous,map=self.activeNPCs,self.mapID
  self.generation=self.generation+1; self.pending={}; self.activeNPCs={}; self.unitGUIDs={}
  self:ClearVisuals(); self.mapID,self.mapName=self:CurrentMap(); self.byID={}; self.byName={}
  self.previousActive=map==self.mapID and previous or nil
  local keys={}; for key in pairs(self:GetData().entries) do if id(key) then keys[#keys+1]=key end end; table.sort(keys)
  for _,key in ipairs(keys) do
    local r=self:GetData().entries[key]
    if self:Normalize(r) and r.enabled and r.mapID==self.mapID then
      local index=r.npcID and self.byID or self.byName; local k=r.npcID or r.name
      if not index[k] then index[k]=r end
    end
  end
  self.hasEntries=next(self.byID)~=nil or next(self.byName)~=nil
  for _,event in ipairs(scanEvents) do self.events:UnregisterEvent(event) end
  if self:IsEnabled() and self.hasEntries then
    for _,event in ipairs(scanEvents) do pcall(self.events.RegisterEvent,self.events,event) end
    -- A one-time bounded priming scan includes already-visible plates.
    for i=1,100 do local unit="nameplate"..i; if self.Call(UnitExists,unit) then self:Detect(unit) end end
    self:Detect("target"); self:Detect("mouseover")
  end
  self:RenderIndicator()
  self.previousActive=nil
  if self.settingsContent then KHQOL.UI:Refresh(self.settingsContent) end
end
function N:SetEnabled(on)
  self:GetDB(); self:CreateFrames(); self.cooldowns={}; self.activeNPCs={}; self.inWorld=true
  for _,event in ipairs(zoneEvents) do self.events:UnregisterEvent(event) end
  for _,event in ipairs(scanEvents) do self.events:UnregisterEvent(event) end
  if on then for _,event in ipairs(zoneEvents) do pcall(self.events.RegisterEvent,self.events,event) end end
  self:RefreshMap()
end
function N:Changed()
  self:GetDB(); self:RefreshMap()
  if KHQOL.SaveCurrentProfile then KHQOL:SaveCurrentProfile() end
end
function N:Test()
  if not self:IsEnabled() then return end
  self:ClearVisuals(); self.testing=true; local serial=self.testSerial
  self:ShowBanner({name="테스트 위험 NPC",dangerLevel="HIGH"}); self:PlayWarning({sound=true}); self:RenderIndicator()
  C_Timer.After(5,function() if serial==self.testSerial then self:StopTest() end end)
end
function N:StopTest()
  if not self.testing then return end
  self:ClearVisuals(); self:RenderIndicator()
end
N.events=CreateFrame("Frame")
N.events:SetScript("OnEvent",function(_,event,unit)
  if not N:IsEnabled() then return end
  if event=="PLAYER_LEAVING_WORLD" then
    N.inWorld=false
    N.generation=N.generation+1; N.activeNPCs={}; N.unitGUIDs={}; N.pending={}; N:ClearVisuals(); return
  end
  if event=="PLAYER_ENTERING_WORLD" or event:match("^ZONE_CHANGED") then N.inWorld=true; N:RefreshMap(); return end
  if event=="PLAYER_TARGET_CHANGED" then N:Detect("target")
  elseif event=="UPDATE_MOUSEOVER_UNIT" then N:Detect("mouseover")
  elseif N.Text(unit) then
    if event=="NAME_PLATE_UNIT_REMOVED" then N:RemoveUnit(unit) else N:Detect(unit) end
  end
  N:RenderIndicator()
end)
