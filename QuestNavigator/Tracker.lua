local _, KHQOL = ...
local QN=KHQOL.modules.questNavigator
-- Quest-list presentation is independent of the navigation/watch cache below.
-- Verified against Gethe/wow-ui-source forever 15666a6 (1.60.1.70245).
local trackerDefaults={groupByRegion=true,collapsibleRegions=true,showDungeonTag=true,
  showEliteTag=true,collapsedRegions={},contentWidth=0}
local function inCombat() return QN.IsTrue(QN.Call(InCombatLockdown)) end
function QN:GetTrackerDB()
  local db=self:GetDB()
  if type(db.questTracker)~="table" then db.questTracker={} end
  local t=db.questTracker
  KHQOL.MergeDefaults(t,trackerDefaults,"types")
  local _,nativeSize=QN.Call(ObjectiveTrackerLineFont and ObjectiveTrackerLineFont.GetFont,ObjectiveTrackerLineFont)
  if not QN.IsNumber(t.fontSize) then t.fontSize=QN.IsNumber(nativeSize) and nativeSize or 12 end
  t.fontSize=math.max(10,math.min(20,t.fontSize))
  if not QN.IsNumber(t.contentWidth) or (t.contentWidth~=0 and (t.contentWidth<200 or t.contentWidth>500)) then t.contentWidth=0 end
  self.trackerDB=t; return t
end
function QN:GetTrackerWidth()
  local t=self.trackerDB or self:GetTrackerDB()
  if t.contentWidth>0 then return t.contentWidth end
  local m=self.objectiveModule
  local width=m and m:GetWidth()
  if QN.IsNumber(width) and width>0 then
    -- Capture the running client's actual default once, rather than resizing the container.
    t.contentWidth=math.max(200,math.min(500,math.floor(width-(m.blockOffsetX or 20)+.5)))
    return t.contentWidth
  end
  return 235 -- UI-only fallback before the load-on-demand Blizzard tracker exists.
end
function QN:GetTrackerQuestInfo(id,order)
  local api=C_QuestLog
  local index=QN.Call(api and api.GetLogIndexForQuestID,id)
  local info=QN.IsID(index) and QN.Call(api and api.GetInfo,index)
  if not QN.IsTable(info) then info={} end
  local headerIndex=QN.Call(api and api.GetHeaderIndexForQuest,id)
  local header=QN.IsID(headerIndex) and QN.Call(api and api.GetInfo,headerIndex)
  local name,key,regionOrder="기타","fallback:other",math.huge
  if QN.IsTable(header) and QN.IsTrue(header.isHeader) and QN.IsText(header.title) and header.title~="" then
    name=header.title; key="header:"..name; regionOrder=headerIndex
  end
  -- QuestInfo has no persistent header ID. Never persist the mutable row index.
  local level=info.difficultyLevel
  if not QN.IsNumber(level) or level<=0 then level=QN.Call(api and api.GetQuestDifficultyLevel,id) end
  if not QN.IsNumber(level) or level<=0 then level=info.level end
  if not QN.IsNumber(level) or level<=0 then level=nil end
  local tag=QN.Call(api and api.GetQuestTagInfo,id)
  local tags=Enum and Enum.QuestTag
  local dungeon=QN.IsTable(tag) and tags and QN.IsNumber(tag.tagID) and
    ((tags.Dungeon and tag.tagID==tags.Dungeon) or (tags.Heroic and tag.tagID==tags.Heroic)) or false
  return {id=id,order=order,level=level,region=name,regionKey=key,regionOrder=regionOrder,
    dungeon=dungeon,elite=QN.IsTrue(QN.Call(api and api.IsEliteQuest,id))}
end
function QN:GetTrackerTag(info)
  local t=self.trackerDB
  -- Dungeon classification always wins, even if its display option is disabled.
  if info.dungeon then return t.showDungeonTag and "D" or nil end
  if info.elite and t.showEliteTag then return "★" end
end
function QN:BuildTrackerGroups(infos)
  local groups,lookup,data={},{},{}
  for _,watch in ipairs(infos) do
    local id=watch.quest:GetID()
    local info=self:GetTrackerQuestInfo(id,watch.index)
    watch.khqolInfo=info; data[id]=info
    local key=self.trackerDB.groupByRegion and info.regionKey or "all"
    local group=lookup[key]
    if not group then
      group={key=key,name=info.region,order=info.regionOrder,watches={}}
      groups[#groups+1]=group; lookup[key]=group
    end
    group.order=math.min(group.order,info.regionOrder)
    group.watches[#group.watches+1]=watch
  end
  table.sort(groups,function(a,b)
    if a.order~=b.order then return a.order<b.order end
    return a.watches[1].index<b.watches[1].index
  end)
  for _,group in ipairs(groups) do
    table.sort(group.watches,function(a,b)
      local x,y=a.khqolInfo,b.khqolInfo
      if (x.level or math.huge)~=(y.level or math.huge) then return (x.level or math.huge)<(y.level or math.huge) end
      return x.order<y.order
    end)
    group.collapsed=self.trackerDB.groupByRegion and self.trackerDB.collapsibleRegions and
      self.trackerDB.collapsedRegions[group.key]==true or false
  end
  self.trackerGroups,self.trackerQuestData=groups,data
  return groups
end
local function rememberFont(fs)
  if not fs or fs.khqolTrackerFont then return end
  local path,size,flags=fs:GetFont()
  fs.khqolTrackerFont={path=path,size=size,flags=flags,spacing=fs:GetSpacing(),
    wrap=fs:CanWordWrap(),maxLines=fs:GetMaxLines(),object=fs:GetFontObject()}
end
local function restoreFont(fs)
  local old=fs and fs.khqolTrackerFont
  if not old then return end
  if old.object then fs:SetFontObject(old.object) else fs:SetFont(old.path,old.size,old.flags) end
  fs:SetSpacing(old.spacing)
  fs:SetWordWrap(old.wrap); fs:SetMaxLines(old.maxLines); fs.khqolTrackerFont=nil
end
function QN:StyleTrackerFont(fs)
  if not fs then return end
  rememberFont(fs)
  local old=fs.khqolTrackerFont
  fs:SetFont(old.path,self.trackerDB.fontSize,old.flags)
  fs:SetSpacing(math.max(0,self.trackerDB.fontSize-12)*.15)
  fs:SetWordWrap(true)
end
function QN:RestoreTrackerBlock(block)
  local old=block.khqolTrackerOriginal
  if not old then return end
  restoreFont(block.HeaderText)
  for _,line in pairs(block.usedLines or {}) do restoreFont(line.Text); restoreFont(line.Dash) end
  block.SetStringText,block.GetLine,block.FreeLine=old.SetStringText,old.GetLine,old.FreeLine
  block.fixedWidth,block.offsetX=old.fixedWidth,old.offsetX
  block.khqolTrackerOriginal=nil
end
function QN:StyleTrackerBlock(block)
  if block.khqolTrackerOriginal then return end
  local owner=self
  local old={SetStringText=block.SetStringText,GetLine=block.GetLine,FreeLine=block.FreeLine,
    fixedWidth=block.fixedWidth,offsetX=block.offsetX}
  block.khqolTrackerOriginal=old
  block.SetStringText=function(b,fs,text,full,...)
    owner:StyleTrackerFont(fs)
    if fs==b.HeaderText then
      local info=owner.trackerQuestData and owner.trackerQuestData[b.id]
      local title=QN.Call(C_QuestLog and C_QuestLog.GetTitleForQuestID,b.id)
      if info and QN.IsText(title) then
        local tag=owner:GetTrackerTag(info)
        title=(info.level and ("["..math.floor(info.level).."] ") or "")..
          (tag and ("["..tag.."] ") or "")..title
        -- Keep the exact native difficulty color (and CVar policy), without a second level prefix.
        local color=QN.IsText(text) and text:match("^(|c%x%x%x%x%x%x%x%x)")
        text=color and (color..title.."|r") or title
      end
      full=true -- HeaderButton follows the full wrapped HeaderText height.
    end
    return old.SetStringText(b,fs,text,full,...)
  end
  block.GetLine=function(b,...)
    local line=old.GetLine(b,...)
    owner:StyleTrackerFont(line.Text); owner:StyleTrackerFont(line.Dash)
    return line
  end
  block.FreeLine=function(b,line,...)
    restoreFont(line.Text); restoreFont(line.Dash)
    return old.FreeLine(b,line,...)
  end
end
function QN:HideTrackerRegions()
  for _,row in ipairs(self.trackerRegionRows or {}) do row:Hide() end
  self.trackerRegionCount=0; self.trackerRegionAnchor=nil
  self.trackerFirstRegionAtTop=false
end
function QN:RestoreTrackerBars()
  for bar,old in pairs(self.trackerBars or {}) do
    bar:SetWidth(old.width); bar.Bar:SetWidth(old.barWidth)
  end
  self.trackerBars={}
end
function QN:AddTrackerRegion(module,group)
  local count=(self.trackerRegionCount or 0)+1
  self.trackerRegionRows=self.trackerRegionRows or {}
  if count==1 then self.trackerFirstRegionAtTop=module.firstBlock==nil end
  local row=self.trackerRegionRows[count]
  if not row then
    row=CreateFrame("Button",nil,module.ContentsFrame)
    row.Text=row:CreateFontString(nil,"OVERLAY","ObjectiveTrackerHeaderFont")
    row.Text:SetPoint("TOPLEFT"); row.Text:SetPoint("RIGHT")
    row:RegisterForClicks("LeftButtonUp")
    row:SetScript("OnClick",function(button)
      if not self.trackerEnabled or not self.trackerDB.collapsibleRegions then return end
      local key=button.regionKey
      self.trackerDB.collapsedRegions[key]=not self.trackerDB.collapsedRegions[key]
      self:RequestTrackerLayout()
    end)
    self.trackerRegionRows[count]=row
  end
  row.regionKey=group.key
  local path,_,flags=row.Text:GetFont()
  row.Text:SetFont(path,self.trackerDB.fontSize+1,flags)
  row.Text:SetTextColor(1,119/255,95/255) -- Region header: #FF775F.
  row.Text:SetWordWrap(true); row.Text:SetMaxLines(0); row.Text:SetHeight(0)
  row.fixedWidth=true; row:SetWidth(self:GetTrackerWidth())
  row.offsetX=module:GetWidth()-self:GetTrackerWidth()
  module:AnchorBlock(row)
  row.Text:SetText((self.trackerDB.collapsibleRegions and (group.collapsed and "▶ " or "▼ ") or "")..group.name)
  row.height=math.max(self.trackerDB.fontSize+4,row.Text:GetStringHeight()+2)
  row:SetHeight(row.height)
  if not module:CanFitBlock(row) then module.hasTriedBlocks=true; module.hasSkippedBlocks=true; row:Hide(); return false end
  module.hasTriedBlocks=true; module.hasContents=true
  local _,offset=module:GetNextBlockAnchoring()
  module.contentsHeight=module.contentsHeight+row.height-offset
  -- Region rows never enter the native quest linked list / POI / gamepad iteration.
  self.trackerRegionAnchor=row; self.trackerRegionCount=count; row:Show()
  return true
end
function QN:RequestTrackerLayout()
  self.trackerPending=true
  if inCombat() then return end
  self:InstallObjectiveTracker()
  if self.objectiveModule then self.objectiveModule:MarkDirty() end
end
function QN:InstallObjectiveTracker()
  if inCombat() then self.trackerPending=true; return end
  local m=QuestObjectiveTracker
  if self.objectiveModule or not m then return end
  local required={"Update","BuildQuestWatchInfos","EnumQuestWatchData","GetBlock","LayoutBlock",
    "GetNextBlockAnchoring","OnFreeBlock","CheckCachedBlocks","AdjustSlideAnchor"}
  for _,name in ipairs(required) do if type(m[name])~="function" then self.trackerUnavailable=name; return end end
  local owner=self
  self.objectiveModule=m; self.trackerUnavailable=nil
  local old={lineSpacing=m.lineSpacing}; for _,name in ipairs(required) do old[name]=m[name] end
  self.trackerModuleOriginal=old
  m.Update=function(module,availableHeight,dirtyUpdate)
    -- No addon frame/font/item changes, even when another module requests a container layout.
    if inCombat() and (owner.trackerEnabled or owner.trackerDecorated) then
      owner.trackerPending=true
      return module:GetContentsHeight(),module:IsTruncated()
    end
    if not module:CanUpdate() and not module.parentContainer:IsCollapsed() then
      return old.Update(module,availableHeight,dirtyUpdate)
    end
    if dirtyUpdate and not module:IsDirty() and module:IsComplete() and
      module.contentsHeight<=availableHeight and not module:IsCollapsed() then
      return old.Update(module,availableHeight,dirtyUpdate)
    end
    owner:HideTrackerRegions()
    owner:RestoreTrackerBars()
    owner.trackerPending=false
    owner.trackerDB=owner:GetTrackerDB()
    module.lineSpacing=owner.trackerEnabled and math.max(2,old.lineSpacing+(owner.trackerDB.fontSize-12)*.25) or old.lineSpacing
    if not owner.trackerEnabled then
      module:EnumerateActiveBlocks(function(block) owner:RestoreTrackerBlock(block) end)
      owner.trackerDecorated=false
    end
    return old.Update(module,availableHeight,dirtyUpdate)
  end
  m.BuildQuestWatchInfos=function(module)
    if owner.trackerEnabled and inCombat() and owner.trackerVisibleWatchInfos then return owner.trackerVisibleWatchInfos end
    local infos=old.BuildQuestWatchInfos(module) -- Watch IDs + native ShouldDisplayQuest filter only.
    if not owner.trackerEnabled then return infos end
    local groups=owner:BuildTrackerGroups(infos)
    local sorted={}
    for _,group in ipairs(groups) do
      if not group.collapsed then for _,watch in ipairs(group.watches) do sorted[#sorted+1]=watch end end
    end
    owner.trackerVisibleWatchInfos=sorted -- Native gamepad navigation skips collapsed regions too.
    return sorted
  end
  m.EnumQuestWatchData=function(module,func)
    if not owner.trackerEnabled then return old.EnumQuestWatchData(module,func) end
    module:BuildQuestWatchInfos()
    for _,group in ipairs(owner.trackerGroups) do
      if owner.trackerDB.groupByRegion and not owner:AddTrackerRegion(module,group) then return end
      if not group.collapsed then
        for _,watch in ipairs(group.watches) do if not func(module,watch.quest) then return end end
      end
    end
  end
  m.GetNextBlockAnchoring=function(module)
    if owner.trackerEnabled and owner.trackerRegionAnchor then return owner.trackerRegionAnchor,module.fromBlockOffsetY,"BOTTOM" end
    return old.GetNextBlockAnchoring(module)
  end
  m.GetBlock=function(module,...)
    local block,existing=old.GetBlock(module,...)
    if owner.trackerEnabled and owner.trackerQuestData and owner.trackerQuestData[block.id] then
      owner:StyleTrackerBlock(block); owner.trackerDecorated=true
      block.fixedWidth=true; block:SetWidth(owner:GetTrackerWidth())
      block.offsetX=module:GetWidth()-owner:GetTrackerWidth()
      module:AnchorBlock(block) -- Width is resolved BEFORE native title/objective measurement.
    end
    return block,existing
  end
  m.LayoutBlock=function(module,block)
    if owner.trackerEnabled and block.khqolTrackerOriginal then
      -- Native rightEdgeOffset reserves item/find-group width for title AND every objective.
      -- Account for a button taller than a one-line quest, including its border/hotkey.
      for region in pairs(block.addedRegions or {}) do
        if region==block.ItemButton or region==block.rightEdgeFrame then block.height=math.max(block.height,region:GetHeight()+8) end
      end
      for _,line in pairs(block.usedLines or {}) do
        local bar=line.used and line.progressBar
        if bar and bar.Bar then
          owner.trackerBars[bar]={width=bar:GetWidth(),barWidth=bar.Bar:GetWidth()}
          local width=math.min(bar:GetWidth(),math.max(40,block:GetWidth()+block.rightEdgeOffset-18))
          bar:SetWidth(width); bar.Bar:SetWidth(math.max(20,width-12))
        end
      end
    end
    local result=old.LayoutBlock(module,block)
    if result then owner.trackerRegionAnchor=nil end
    return result
  end
  m.OnFreeBlock=function(module,block)
    owner:RestoreTrackerBlock(block)
    return old.OnFreeBlock(module,block)
  end
  m.CheckCachedBlocks=function(module,...)
    -- Do not reinsert turn-in/untracked animation ghosts outside their region or after unwatch.
    if owner.trackerEnabled then return end
    return old.CheckCachedBlocks(module,...)
  end
  m.AdjustSlideAnchor=function(module,offset)
    if owner.trackerEnabled and owner.trackerFirstRegionAtTop and (owner.trackerRegionCount or 0)>0 then
      local row=owner.trackerRegionRows[1]
      row:SetPoint("TOP",module.ContentsFrame,"TOP",0,offset+module.fromHeaderOffsetY)
      return
    end
    return old.AdjustSlideAnchor(module,offset)
  end
  self:GetTrackerWidth(); m:MarkDirty()
end
function QN:SetObjectiveTrackerEnabled(enabled)
  self:GetTrackerDB(); self.trackerEnabled=enabled==true
  if not self.trackerEvents then
    local frame=CreateFrame("Frame"); self.trackerEvents=frame
    frame:RegisterEvent("ADDON_LOADED"); frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:SetScript("OnEvent",function(_,event,name)
      if event=="ADDON_LOADED" and name~="Blizzard_ObjectiveTracker" then return end
      if event=="PLAYER_REGEN_ENABLED" and not self.trackerPending then return end
      self:RequestTrackerLayout()
    end)
  end
  self:RequestTrackerLayout()
end
function QN:PrintTrackerLayout()
  self:GetTrackerDB(); self:InstallObjectiveTracker()
  local function emit(text)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("KHQOL Quest Layout: "..text) end
  end
  local m=self.objectiveModule
  if not m then emit("Native tracker unavailable: "..(self.trackerUnavailable or "not loaded")); return end
  -- Read-only debug collection; no frames or watch state are changed.
  local groups=self:BuildTrackerGroups(self.trackerModuleOriginal.BuildQuestWatchInfos(m))
  local count=0; for _,group in ipairs(groups) do count=count+#group.watches end
  emit("Tracked Quests (native quest module): "..count)
  for _,group in ipairs(groups) do
    emit("["..group.name.."] Collapsed: "..(group.collapsed and "YES" or "NO"))
    for _,watch in ipairs(group.watches) do
      local i=watch.khqolInfo
      emit("Quest "..i.id.." / Level: "..(i.level or "UNKNOWN").." / Dungeon: "..(i.dungeon and "YES" or "NO")..
        " / Elite: "..(i.elite and "YES" or "NO").." / Tag: "..(self:GetTrackerTag(i) or "NONE"))
    end
  end
  emit("Font Size: "..self.trackerDB.fontSize.." / Content Width: "..self:GetTrackerWidth()..
    " / Pending Layout: "..(self.trackerPending and "YES" or "NO"))
end
function QN:GetTrackedQuest()
  local api=C_SuperTrack
  if QN.IsFalse(QN.Call(api and api.IsSuperTrackingQuest)) then return nil end
  local id=QN.Call(api and api.GetSuperTrackedQuestID)
  if QN.IsID(id) then return id end
end
function QN:OtherNavigationActive()
  local api=C_SuperTrack
  return QN.IsTrue(QN.Call(api and api.IsSuperTrackingAnything)) and not self:GetTrackedQuest()
end
function QN:IsQuestReadyForTurnIn(id)
  if not QN.IsID(id) then return nil end
  local api=C_QuestLog
  local ready=QN.Call(api and api.ReadyForTurnIn,id)
  if QN.IsTrue(ready) or QN.IsFalse(ready) then return ready end
  ready=QN.Call(api and api.IsComplete,id)
  if QN.IsTrue(ready) or QN.IsFalse(ready) then return ready end
end
function QN:IsComplete(id) return self:IsQuestReadyForTurnIn(id) end
function QN:GetTrackedQuests(force)
  if self.trackedLoaded and not force and not self.trackedDirty then return self.trackedQuestIDs end
  local ids={}
  local api=C_QuestLog
  local count=QN.Call(api and api.GetNumQuestWatches)
  self.watchSource="unavailable"
  if QN.IsNumber(count) and count>=0 and count%1==0 and count<=1000 and
     api and type(api.GetQuestIDForQuestWatchIndex)=="function" then
    self.watchSource="questWatch"
    for i=1,count do
      local id=QN.Call(api.GetQuestIDForQuestWatchIndex,i)
      if QN.IsID(id) then ids[id]=true end
    end
  end
  local worldCount=QN.Call(api and api.GetNumWorldQuestWatches)
  if QN.IsNumber(worldCount) and worldCount>=0 and worldCount%1==0 and worldCount<=1000 and
     api and type(api.GetQuestIDForWorldQuestWatchIndex)=="function" then
    for i=1,worldCount do
      local id=QN.Call(api.GetQuestIDForWorldQuestWatchIndex,i)
      if QN.IsID(id) then ids[id]=true end
    end
    self.watchSource=self.watchSource=="unavailable" and "worldQuestWatch" or "questWatch+worldQuestWatch"
  end
  -- The synchronous event payload wins if the native list is one event behind.
  self.watchOverrides=self.watchOverrides or {}
  for id,added in pairs(self.watchOverrides) do
    if (ids[id]==true)==added then self.watchOverrides[id]=nil
    elseif added then ids[id]=true else ids[id]=nil end
  end
  self.trackedQuestIDs=ids; self.trackedLoaded=true; self.trackedDirty=false
  return ids
end
function QN:WatchChanged(id,added)
  local ids=self:GetTrackedQuests()
  if QN.IsID(id) and (QN.IsTrue(added) or QN.IsFalse(added)) then
    self.watchOverrides[id]=added
    ids[id]=added and true or nil
  else self:GetTrackedQuests(true) end
end
function QN:GetCandidateInfo(id)
  local api=C_QuestLog
  local index=QN.Call(api and api.GetLogIndexForQuestID,id)
  local info=QN.IsID(index) and QN.Call(api and api.GetInfo,index) or nil
  if QN.IsTable(info) and QN.IsID(info.questID) and info.questID==id and QN.IsFalse(info.isHeader) then return info end
  return {}
end
local function validCoordinates(x,y)
  return QN.IsNumber(x) and QN.IsNumber(y) and x>=0 and x<=1 and y>=0 and y<=1
end
local function validPoint(map,x,y)
  return QN.IsID(map) and validCoordinates(x,y)
end
local function validQuestPOI(info)
  return QN.IsTable(info) and QN.IsID(info.questID) and
    not QN.IsSecret(info.isMapIndicatorQuest) and not QN.IsTrue(info.isMapIndicatorQuest) and
    validCoordinates(info.x,info.y)
end
function QN:GetMapQuestPOIs(map)
  if not QN.IsID(map) then return nil end
  local pois=QN.Call(C_QuestLog and C_QuestLog.GetQuestsOnMap,map)
  if QN.IsTable(pois) then return pois end
end
function QN:GetWaypoint(id,playerMap,poiLookup)
  if not QN.IsID(id) then return nil end
  local api=C_QuestLog
  local map,x,y=QN.Call(api and api.GetNextWaypoint,id)
  if validPoint(map,x,y) then return map,x,y,"waypoint" end
  playerMap=playerMap or QN.Call(C_Map and C_Map.GetBestMapForUnit,"player")
  if not QN.IsID(playerMap) then return nil end
  x,y=QN.Call(api and api.GetNextWaypointForMap,id,playerMap)
  if validPoint(playerMap,x,y) then return playerMap,x,y,"mapWaypoint" end
  -- A map quest marker can exist even when both waypoint APIs return nothing.
  -- Read only the matching quest's underlying coordinates, never display offsets
  -- or a user pin. The completion scan supplies a temporary lookup to stay O(n+m).
  if poiLookup then
    local info=poiLookup[id]
    if validQuestPOI(info) then return playerMap,info.x,info.y,"questPOI" end
  else
    local pois=self:GetMapQuestPOIs(playerMap)
    if pois then
      for _,info in ipairs(pois) do
        if validQuestPOI(info) and info.questID==id then return playerMap,info.x,info.y,"questPOI" end
      end
    end
  end
end
local COLOR_PRIORITIES={standard=1,trivial=1,difficult=2,verydifficult=3,impossible=4}
local function colorPriority(color)
  if not QN.IsTable(color) or not QN.IsTable(QuestDifficultyColors) then return nil end
  for key,priority in pairs(COLOR_PRIORITIES) do
    local reference=QuestDifficultyColors[key]
    if QN.IsTable(reference) and (color==reference or
      (QN.IsNumber(color.r) and QN.IsNumber(color.g) and QN.IsNumber(color.b) and
       QN.IsNumber(reference.r) and QN.IsNumber(reference.g) and QN.IsNumber(reference.b) and
       color.r==reference.r and color.g==reference.g and color.b==reference.b)) then return priority end
  end
end
function QN:GetQuestPriority(id,info,playerLevel)
  local api=C_QuestLog
  local tag=QN.Call(api and api.GetQuestTagInfo,id)
  if QN.IsTable(tag) and QN.IsNumber(tag.tagID) then
    local tags=QN.IsTable(Enum) and QN.IsTable(Enum.QuestTag) and Enum.QuestTag or nil
    local dungeon=tags and tags.Dungeon or nil
    local heroic=tags and tags.Heroic or nil
    -- Native tag IDs are retained for clients without the enum namespace.
    if not QN.IsID(dungeon) then dungeon=81 end
    if not QN.IsID(heroic) then heroic=85 end
    if tag.tagID==dungeon or tag.tagID==heroic then return 5 end
  end
  -- Use the same content difficulty as the native objective-tracker title.
  local difficulty=QN.Call(C_PlayerInfo and C_PlayerInfo.GetContentDifficultyQuestForPlayer,id)
  local relative=QN.IsTable(Enum) and QN.IsTable(Enum.RelativeContentDifficulty) and Enum.RelativeContentDifficulty or nil
  if QN.IsNumber(difficulty) and relative then
    if (QN.IsNumber(relative.Trivial) and difficulty==relative.Trivial) or
       (QN.IsNumber(relative.Easy) and difficulty==relative.Easy) then return 1 end
    if QN.IsNumber(relative.Fair) and difficulty==relative.Fair then return 2 end
    if QN.IsNumber(relative.Difficult) and difficulty==relative.Difficult then return 3 end
    if QN.IsNumber(relative.Impossible) and difficulty==relative.Impossible then return 4 end
  end
  local level=info.difficultyLevel
  if not QN.IsNumber(level) or level<=0 then level=QN.Call(api and api.GetQuestDifficultyLevel,id) end
  if not QN.IsNumber(level) or level<=0 then level=info.level end
  if not QN.IsNumber(level) or level<=0 then return 2 end
  local scaling=QN.IsTrue(info.isScaling)
  local priority=colorPriority(QN.Call(GetQuestDifficultyColor,level,scaling,id))
  if priority then return priority end
  if QN.IsNumber(playerLevel) and playerLevel>0 then
    local diff=level-playerLevel
    if diff>=5 then return 4 end
    if diff>=3 then return 3 end
    if diff>=(scaling and 0 or -4) then return 2 end
    return 1 -- Gray and green both occupy the easiest tier.
  end
  return 2 -- Unknown difficulty keeps the ordinary tier and distance ordering.
end
function QN:FindClosestQuest(excludedID)
  local api=C_QuestLog
  local tracked=self:GetTrackedQuests(true)
  local closest,minimum,priority,localQuest,localMinimum,localPriority=nil,math.huge,math.huge,nil,math.huge,math.huge
  local playerLevel=QN.Call(UnitEffectiveLevel,"player")
  if not QN.IsNumber(playerLevel) or playerLevel<=0 then playerLevel=QN.Call(UnitLevel,"player") end
  local playerMap=QN.Call(C_Map and C_Map.GetBestMapForUnit,"player")
  local poiLookup
  if self.db.preferSameRegion and QN.IsID(playerMap) then
    poiLookup={}
    local pois=self:GetMapQuestPOIs(playerMap)
    if pois then
      for _,info in ipairs(pois) do
        if validQuestPOI(info) and not poiLookup[info.questID] then poiLookup[info.questID]=info end
      end
    end
  end
  -- Enumerate only watch IDs; never walk, expand or select quest-log rows.
  for id in pairs(tracked) do
    if id~=excludedID then
      if not QN.IsFalse(QN.Call(api and api.IsOnQuest,id)) and QN.IsFalse(self:IsComplete(id)) then
        local sq,onContinent=QN.Call(api and api.GetDistanceSqToQuest,id)
        if QN.IsNumber(sq) and sq>0 and QN.IsTrue(onContinent) then
          local rank=self:GetQuestPriority(id,self:GetCandidateInfo(id),playerLevel)
          if rank<priority or (rank==priority and (sq<minimum or (sq==minimum and (not closest or id<closest)))) then
            closest,minimum,priority=id,sq,rank
          end
          if self.db.preferSameRegion and QN.IsID(playerMap) then
            local map=self:GetWaypoint(id,playerMap,poiLookup)
            if map==playerMap and (rank<localPriority or (rank==localPriority and
              (sq<localMinimum or (sq==localMinimum and (not localQuest or id<localQuest))))) then
              localQuest,localMinimum,localPriority=id,sq,rank
            end
          end
        end
      end
    end
  end
  if localQuest and localPriority==priority then return localQuest end
  return closest
end
local function objectiveLabel(text)
  -- Forever objective text can include the progress before or after the label.
  -- Strip only edge fractions; numbers and fractions inside names remain intact.
  local label=text:gsub("^%s*%d+%s*/%s*%d+%s*",""):gsub("%s*%d+%s*/%s*%d+%s*$","")
  label=label:gsub("^%s*:%s*",""):gsub("^%s*：%s*","")
  label=label:gsub("%s*:%s*$",""):gsub("%s*：%s*$","")
  return label:match("^%s*(.-)%s*$")
end
function QN:RefreshProgress()
  self.progressText=""
  if not self.currentQuestID then return end
  local objectives=QN.Call(C_QuestLog and C_QuestLog.GetQuestObjectives,self.currentQuestID)
  if not QN.IsTable(objectives) then return end
  for _,objective in ipairs(objectives) do
    if QN.IsTable(objective) and QN.IsFalse(objective.finished) then
      local n,total=objective.numFulfilled,objective.numRequired
      local text=QN.IsText(objective.text) and objective.text or ""
      -- finished is authoritative: some Forever objective types report 1 before
      -- completion. Never infer whole-quest completion from a numeric fraction.
      if QN.IsNumber(n) and QN.IsNumber(total) and n>=0 and total>0 then
        local numeric=string.format("%d / %d",math.floor(n),math.floor(total))
        if self.db.progressMode=="text" and text~="" then
          local label=objectiveLabel(text)
          self.progressText=label~="" and (label.." "..numeric) or numeric
        else self.progressText=numeric end
      else self.progressText=self.db.progressMode=="text" and text or "진행 중" end
      return
    end
  end
end
function QN:ClearNavigation(preserveRotation)
  self.targetMapID,self.targetX,self.targetY,self.waypointSource=nil,nil,nil,nil
  if not preserveRotation then self.currentRotation=nil end
  self.distanceYards=nil; self.distanceSq=nil; self.atWaypoint=false
  self.lastDistanceValue=nil; self.lastDistanceUnit=nil; self.distanceLabel=nil
  self.playerX=nil; self.playerY=nil; self.rotationFailed=nil
  self.playerFacing=nil; self.targetAngle=nil; self.relativeAngle=nil
  self.navigationMode="NONE"; self.locationReason=nil
end
function QN:GetTurnInWaypoint(id)
  -- Read a new native location after ReadyForTurnIn. Never carry the objective
  -- target across this boundary. An unchanged former objective is ambiguous.
  self.locationReason="noNativeLocation"
  local function accept(map,x,y)
    if not validPoint(map,x,y) then return false end
    if map==self.objectiveMapID and x==self.objectiveX and y==self.objectiveY then
      self.locationReason="unchangedObjective"; return false
    end
    self.locationReason="nativeReadyQuest"; return true
  end
  local api=C_QuestLog
  local map,x,y=QN.Call(api and api.GetNextWaypoint,id)
  if accept(map,x,y) then return map,x,y,"turnin:waypoint" end
  map=QN.Call(C_Map and C_Map.GetBestMapForUnit,"player")
  if not QN.IsID(map) then return nil end
  x,y=QN.Call(api and api.GetNextWaypointForMap,id,map)
  if accept(map,x,y) then return map,x,y,"turnin:mapWaypoint" end
  local pois=self:GetMapQuestPOIs(map)
  if pois then
    for _,info in ipairs(pois) do
      if validQuestPOI(info) and info.questID==id and accept(map,info.x,info.y) then
        return map,info.x,info.y,"turnin:questPOI"
      end
    end
  end
end
function QN:RefreshQuestData()
  local id=self.currentQuestID
  self:ClearNavigation(true); self.targetQuestID=id; self.progressText=""
  self.readyForTurnIn=nil
  if id then self.readyForTurnIn=self:IsQuestReadyForTurnIn(id) end
  if not id then self.questTitle=nil; return end
  local title=QN.Call(C_QuestLog and C_QuestLog.GetTitleForQuestID,id)
  self.questTitle=QN.IsText(title) and title~="" and title or ("퀘스트 #"..id)
  if QN.IsTrue(self.readyForTurnIn) then
    self.navigationMode="TURN_IN_LOCATION"
    self.targetMapID,self.targetX,self.targetY,self.waypointSource=self:GetTurnInWaypoint(id)
    self.progressText="반납 가능"
  elseif QN.IsFalse(self.readyForTurnIn) then
    self.navigationMode="OBJECTIVE_LOCATION"
    self.targetMapID,self.targetX,self.targetY,self.waypointSource=self:GetWaypoint(id)
    if self.targetMapID then self.objectiveMapID,self.objectiveX,self.objectiveY=self.targetMapID,self.targetX,self.targetY end
    self.locationReason=self.targetMapID and "nativeObjective" or "noNativeLocation"
    self:RefreshProgress()
  else self.locationReason="unknownCompletion" end
end
function QN:AdoptQuest(id,manual)
  if id and QN.IsFalse(QN.Call(C_QuestLog and C_QuestLog.IsOnQuest,id)) then id=nil end
  if id~=self.currentQuestID then
    self.objectiveMapID,self.objectiveX,self.objectiveY=nil,nil,nil
    self.manualTurnIn=false
  end
  if manual then self.removedSelectedQuestID=nil end
  self.currentRotation=nil; self.currentQuestID=id; self.manualSelection=manual==true
  self:RefreshQuestData()
  if QN.IsFalse(self.readyForTurnIn) then
    self.manualTurnIn=false
    if self.lastCompletedQuestID==id then self.lastCompletedQuestID=nil end
  end
  if manual and QN.IsTrue(self.readyForTurnIn) then self.manualTurnIn=true end
  if not id then self.state="IDLE"; self:Render(); self:UpdateDriver(); return end
  self.state="TRACKING"; self:UpdateNavigation(true,true); self:Render(); self:UpdateDriver()
end
function QN:RefreshQuest()
  if not self.active then return end
  self:GetTrackedQuests()
  if self.phase then return end
  local tracked=self:GetTrackedQuest()
  if tracked and QN.IsFalse(QN.Call(C_QuestLog and C_QuestLog.IsOnQuest,tracked)) then tracked=nil end
  local id=self.currentQuestID
  if tracked~=id then self:AdoptQuest(tracked,true); self.removedSelectedQuestID=nil; return end
  self.removedSelectedQuestID=nil
  if not id then self.state="IDLE"; self:Render(); return end
  self:RefreshQuestData()
  if QN.IsFalse(self.readyForTurnIn) then
    self.manualTurnIn=false
    if self.lastCompletedQuestID==id then self.lastCompletedQuestID=nil end
  elseif QN.IsTrue(self.readyForTurnIn) and self.db.autoTrack and
      self.db.completionBehavior=="next" and not self.manualTurnIn and self.lastCompletedQuestID~=id then
    self:BeginCompletion(id); return
  end
  self:UpdateNavigation(false,true); self:Render()
end
function QN:RefreshWaypoint()
  if self.phase or not self.currentQuestID then return end
  -- Completion is cached by quest events; route events never scan the log.
  self:ClearNavigation(true); self.targetQuestID=self.currentQuestID
  if QN.IsTrue(self.readyForTurnIn) then
    self.navigationMode="TURN_IN_LOCATION"
    self.targetMapID,self.targetX,self.targetY,self.waypointSource=self:GetTurnInWaypoint(self.currentQuestID)
  elseif QN.IsFalse(self.readyForTurnIn) then
    self.navigationMode="OBJECTIVE_LOCATION"
    self.targetMapID,self.targetX,self.targetY,self.waypointSource=self:GetWaypoint(self.currentQuestID)
    if self.targetMapID then self.objectiveMapID,self.objectiveX,self.objectiveY=self.targetMapID,self.targetX,self.targetY end
    self.locationReason=self.targetMapID and "nativeObjective" or "noNativeLocation"
  end
  if not QN.IsNumber(self.mapWidth) or not QN.IsNumber(self.mapHeight) then self.sizeMapID=nil end
  self:UpdateNavigation(false,true)
end
function QN:CancelTransition()
  self.phase=nil; self.phaseElapsed=0; self.completedQuestID=nil; self.fadeInRemaining=nil
  self.transitionTurnedIn=nil; self.completionTitleText=nil
  if self.hud then self.hud:SetAlpha(1) end
end
function QN:BeginCompletion(id,turnedIn,title)
  if self.phase or (not turnedIn and self.lastCompletedQuestID==id) then return end
  self.lastCompletedQuestID=id; self.completedQuestID=id; self.transitionTurnedIn=turnedIn==true
  self.completionTitleText=title or self.questTitle or ("퀘스트 #"..id)
  self:ClearNavigation()
  self.state="COMPLETED"; self.phase="hold"; self.phaseElapsed=0; self.fadeInRemaining=nil
  self.hud:SetAlpha(1); self:Render(); self:UpdateDriver()
end
function QN:QuestTurnedIn(id)
  self:WatchChanged(id,false)
  if self.transitionTurnedIn and self.completedQuestID==id then return end
  if id~=self.currentQuestID and id~=self.completedQuestID and id~=self.removedSelectedQuestID then return end
  local title=self.questTitle or self.completionTitleText
  local tracked=self:GetTrackedQuest()
  self:CancelTransition(); self:AdoptQuest(nil)
  self.removedSelectedQuestID=nil
  -- Clear only this returned quest, never a newer manual selection or user pin.
  if tracked==id then
    self.settingSuperTrack=true; QN.Call(C_SuperTrack and C_SuperTrack.SetSuperTrackedQuestID,0); self.settingSuperTrack=nil
  elseif tracked or self:OtherNavigationActive() then self:AdoptQuest(tracked,true); return end
  if self.db.autoTrack then self:BeginCompletion(id,true,title) end
end
function QN:AdvanceTransition(elapsed)
  self.phaseElapsed=self.phaseElapsed+elapsed
  if self.phase=="hold" and self.phaseElapsed>=.85 then
    self.phase="out"; self.phaseElapsed=0; self.state="SWITCHING"
  elseif self.phase=="out" then
    self.hud:SetAlpha(math.max(0,1-self.phaseElapsed/.15))
    if self.phaseElapsed>=.15 then self:FinishTransition() end
  end
end
function QN:FinishTransition()
  local completed,turnedIn=self.completedQuestID,self.transitionTurnedIn
  self:CancelTransition()
  local tracked=self:GetTrackedQuest()
  if (tracked and tracked~=completed) or self:OtherNavigationActive() then self:AdoptQuest(tracked,true); return end
  local chosen=self.db.autoTrack and self:FindClosestQuest(completed) or nil
  if chosen then
    self.settingSuperTrack=true
    QN.Call(C_SuperTrack and C_SuperTrack.SetSuperTrackedQuestID,chosen)
    self.settingSuperTrack=nil
    chosen=self:GetTrackedQuest()
  else chosen=not turnedIn and tracked or nil end
  if turnedIn and chosen==completed then chosen=nil end
  self:AdoptQuest(chosen,chosen==completed)
  if self.currentQuestID and not self.phase then self.hud:SetAlpha(0); self.fadeInRemaining=.15 end
  self:UpdateDriver()
end
