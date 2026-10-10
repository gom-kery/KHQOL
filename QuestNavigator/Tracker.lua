local _, KHQOL = ...
local QN=KHQOL.modules.questNavigator
local N,UI=KHQOL.Navigation,KHQOL.NavigationUI
-- Quest-list presentation is independent of the navigation/watch cache below.
-- Verified against Gethe/wow-ui-source forever 15666a6 (1.60.1.70245).
local trackerDefaults={groupByRegion=true,collapsibleRegions=true,showDungeonTag=true,
  showEliteTag=true,collapsedRegions={},contentWidth=0}
local function inCombat() return QN.IsTrue(QN.Call(InCombatLockdown)) end
QN.trackerDefaults = trackerDefaults
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
    -- Read the running client's default without changing the saved zero/default sentinel.
    return math.max(200,math.min(500,math.floor(width-(m.blockOffsetX or 20)+.5)))
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
    local id=watch.id
    watch={id=watch.id,index=watch.index,logIndex=watch.logIndex,title=watch.title} -- Own copy; never decorate shared watch data.
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
-- Addon-owned presentation. Never run a native tracker update from addon code,
-- replace its methods, mark its container dirty, or modify its watch/cache tables.
local function font(fs,size)
  local path,_,flags=ObjectiveTrackerLineFont:GetFont()
  fs:SetFont(path,size,flags); fs:SetWordWrap(true); fs:SetMaxLines(0)
end
function QN:CollectTrackerWatches()
  local api=C_QuestLog; local result={}
  local count=api.GetNumQuestWatches()
  if not QN.IsNumber(count) or count<0 or count>1000 or count%1~=0 then return result end
  for i=1,count do
    local id=api.GetQuestIDForQuestWatchIndex(i)
    if QN.IsID(id) then
      local index=api.GetLogIndexForQuestID(id)
      local info=QN.IsID(index) and api.GetInfo(index)
      local classification=C_QuestInfoSystem and C_QuestInfoSystem.GetQuestClassification(id)
      local campaign=Enum and Enum.QuestClassification and Enum.QuestClassification.Campaign
      -- The campaign/task/bounty sections remain native, rather than duplicated here.
      if QN.IsTable(info) and not QN.IsTrue(info.isHeader)
        and not QN.IsTrue(info.isTask) and not QN.IsTrue(info.isBounty)
        and not QN.IsTrue(api.IsQuestDisabledForSession and api.IsQuestDisabledForSession(id))
        and not (campaign and QN.IsNumber(classification) and classification==campaign) then
        result[#result+1]={id=id,index=i,logIndex=index,title=info.title}
      end
    end
  end
  return result
end
function QN:TrackerQuestClick(button,mouseButton)
  local id=button.questID
  if not self.trackerEnabled or not QN.IsID(id) then return end
  if ChatFrameUtil and ChatFrameUtil.TryInsertQuestLinkForQuestID(id) then return end
  if mouseButton=="RightButton" and MenuUtil and MenuUtil.CreateContextMenu then
    MenuUtil.CreateContextMenu(button,function(_,menu)
      menu:CreateTitle(C_QuestLog.GetTitleForQuestID(id) or "퀘스트")
      local selected=C_SuperTrack.GetSuperTrackedQuestID()==id
      menu:CreateButton(selected and (STOP_SUPER_TRACK_QUEST or "안내 중지") or (SUPER_TRACK_QUEST or "길 안내"),function()
        C_SuperTrack.SetSuperTrackedQuestID(selected and 0 or id)
      end)
      menu:CreateButton(OBJECTIVES_VIEW_IN_QUESTLOG or "퀘스트 보기",function() QuestMapFrame_OpenToQuestDetails(id) end)
      if not QuestUtil or not QuestUtil.CanRemoveQuestWatch or QuestUtil.CanRemoveQuestWatch() then
        menu:CreateButton(OBJECTIVES_STOP_TRACKING or "추적 해제",function() C_QuestLog.RemoveQuestWatch(id) end)
      end
      if C_QuestLog.IsPushableQuest and C_QuestLog.IsPushableQuest(id) and IsInGroup() then
        menu:CreateButton(SHARE_QUEST or "공유",function() QuestUtil.ShareQuest(id) end)
      end
      if QuestMapQuestOptions_AbandonQuest then
        menu:CreateButton(ABANDON_QUEST_ABBREV or "포기",function() QuestMapQuestOptions_AbandonQuest(id) end)
      end
    end)
  elseif IsModifiedClick and IsModifiedClick("QUESTWATCHTOGGLE") then
    if not QuestUtil or not QuestUtil.CanRemoveQuestWatch or QuestUtil.CanRemoveQuestWatch() then C_QuestLog.RemoveQuestWatch(id) end
  elseif button.popupType=="OFFER" and ShowQuestOffer then ShowQuestOffer(id)
  elseif button.popupType=="COMPLETE" and ShowQuestComplete then ShowQuestComplete(id)
  else
    local index=C_QuestLog.GetLogIndexForQuestID(id)
    local info=QN.IsID(index) and C_QuestLog.GetInfo(index)
    if QN.IsTable(info) and QN.IsTrue(info.isAutoComplete) and C_QuestLog.IsComplete(id) and ShowQuestComplete then ShowQuestComplete(id)
    elseif QuestMapFrame_OpenToQuestDetails then QuestMapFrame_OpenToQuestDetails(id) end
  end
end
function QN:CreateTrackerRow(index)
  local row=self.trackerRows[index]
  if row then return row end
  row=CreateFrame("Frame",nil,self.trackerScrollChild)
  row.Title=CreateFrame("Button",nil,row)
  row.Title.Text=row.Title:CreateFontString(nil,"OVERLAY","ObjectiveTrackerLineFont")
  row.Title.Text:SetAllPoints(); row.Title.Text:SetJustifyH("LEFT")
  row.Title:RegisterForClicks("LeftButtonUp","RightButtonUp")
  row.Title:SetScript("OnClick",function(button,mouseButton)
    if button.regionKey then
      if self.trackerEnabled and self.trackerDB.collapsibleRegions then
        local key=button.regionKey
        self.trackerDB.collapsedRegions[key]=not self.trackerDB.collapsedRegions[key]
        self:RequestTrackerLayout()
      end
    else self:TrackerQuestClick(button,mouseButton) end
  end)
  row.lines={}; row.bars={}; self.trackerRows[index]=row
  return row
end
function QN:UpdateTrackerStatus(row,id,complete,popupType)
  -- Own presentation only: never acquire a native POI/pin or register it with
  -- Blizzard's shared POI owner/highlight manager.
  if popupType=="OFFER" then return end
  local button=row.Status
  if not button then
    button=CreateFrame("Button",nil,row)
    button:SetSize(20,20); button:RegisterForClicks("LeftButtonUp","RightButtonUp")
    button.Background=button:CreateTexture(nil,"BACKGROUND")
    button.Background:SetPoint("CENTER"); button.Background:SetSize(32,32)
    button.Icon=button:CreateTexture(nil,"ARTWORK"); button.Icon:SetPoint("CENTER")
    local highlight=button:CreateTexture(nil,"HIGHLIGHT")
    highlight:SetAtlas("UI-QuestPoi-InnerGlow"); highlight:SetPoint("CENTER"); highlight:SetSize(32,32)
    button:SetHighlightTexture(highlight)
    button:SetScript("OnClick",function(b,mouseButton)
      if not self.trackerEnabled or not QN.IsID(b.questID) then return end
      if mouseButton=="RightButton" or (IsModifiedClick and IsModifiedClick("QUESTWATCHTOGGLE")) then
        self:TrackerQuestClick(b,mouseButton)
      elseif not (ChatFrameUtil and ChatFrameUtil.TryInsertQuestLinkForQuestID(b.questID)) then
        C_SuperTrack.SetSuperTrackedQuestID(b.questID)
      end
    end)
    row.Status=button
  end
  button.questID=id; button.popupType=popupType
  local selected=C_SuperTrack.GetSuperTrackedQuestID()==id
  button.Background:SetAtlas(selected and "UI-QuestPoi-QuestNumber-SuperTracked" or "UI-QuestPoi-QuestNumber")
  button.Icon:SetAtlas(complete and "UI-QuestIcon-TurnIn-Normal" or
    (selected and "Quest-In-Progress-Icon-Brown" or "Quest-In-Progress-Icon-yellow"),true)
  button:ClearAllPoints(); button:SetPoint("TOPRIGHT",row.Title,"TOPLEFT",-7,5)
  button:Show()
end
function QN:CreateTrackerItem(row)
  if row.Item then return row.Item end
  local b=CreateFrame("Button",nil,row,"SecureActionButtonTemplate")
  b:SetSize(28,28); b:RegisterForClicks("AnyUp","AnyDown")
  b:SetAttribute("type","item"); b:SetAttribute("useOnKeyDown",true)
  b.Icon=b:CreateTexture(nil,"ARTWORK"); b.Icon:SetAllPoints()
  b.Cooldown=CreateFrame("Cooldown",nil,b,"CooldownFrameTemplate"); b.Cooldown:SetAllPoints()
  b:SetScript("OnEnter",function(button)
    if button.logIndex and GameTooltip then
      self.trackerTooltipOwner=button
      GameTooltip:SetOwner(button,"ANCHOR_LEFT"); GameTooltip:SetQuestLogSpecialItem(button.logIndex); GameTooltip:Show()
    end
  end)
  b:SetScript("OnLeave",function(button)
    if GameTooltip and GameTooltip:IsOwned(button) then GameTooltip:Hide() end
    if self.trackerTooltipOwner==button then self.trackerTooltipOwner=nil end
  end)
  row.Item=b; return b
end
function QN:AddTrackerText(row,text,y,width,complete)
  if not QN.IsText(text) or text=="" then return y end
  local index=(row.lineCount or 0)+1; row.lineCount=index
  local fs=row.lines[index]
  if not fs then fs=row:CreateFontString(nil,"OVERLAY","ObjectiveTrackerLineFont"); fs:SetJustifyH("LEFT"); row.lines[index]=fs end
  font(fs,self.trackerDB.fontSize); fs:ClearAllPoints(); fs:SetPoint("TOPLEFT",row,"TOPLEFT",8,-y)
  fs:SetWidth(width-8); fs:SetHeight(0); fs:SetText(text)
  if complete then fs:SetTextColor(.6,.6,.6) else fs:SetTextColor(.8,.8,.8) end
  fs:Show(); return y+math.max(self.trackerDB.fontSize,fs:GetStringHeight())+3
end
function QN:RenderTrackerQuest(row,watch,width)
  local id,index=watch.id,watch.logIndex
  row.Title.questID=id; row.Title.regionKey=nil; row.Title.popupType=watch.popupType
  local info=self.trackerQuestData[id] or self:GetTrackerQuestInfo(id,watch.index)
  local tag=self:GetTrackerTag(info); local prefix=info.level and tostring(math.floor(info.level)) or nil
  if tag then prefix=prefix and (prefix.." "..tag) or tag end
  local title=C_QuestLog.GetTitleForQuestID(id)
  title=QN.IsText(title) and title or (QN.IsText(watch.title) and watch.title or "퀘스트")
  row.Title.Text:SetText((prefix and ("["..prefix.."] ") or "")..title)
  local nativeTitle=SetQuestTitleLevelAndDifficultyColor and SetQuestTitleLevelAndDifficultyColor(id,title)
  local colorCode=QN.IsText(nativeTitle) and nativeTitle:match("^(|c%x%x%x%x%x%x%x%x)")
  if colorCode then
    row.Title.Text:SetText(colorCode..row.Title.Text:GetText().."|r"); row.Title.Text:SetTextColor(1,1,1)
  elseif SetQuestTitleLevelAndDifficultyColor then row.Title.Text:SetTextColor(1,.82,0)
  else
    local color=info.level and GetQuestDifficultyColor and GetQuestDifficultyColor(info.level)
    if color then row.Title.Text:SetTextColor(color.r,color.g,color.b) else row.Title.Text:SetTextColor(1,.82,0) end
  end
  local link,texture,charges
  local complete=QN.IsTrue(C_QuestLog.IsComplete(id))
  if QN.IsID(index) and GetQuestLogSpecialItemInfo and not complete then link,texture,charges=GetQuestLogSpecialItemInfo(index) end
  local textWidth=width-(QN.IsText(link) and 36 or 0)
  font(row.Title.Text,self.trackerDB.fontSize)
  row.Title:ClearAllPoints(); row.Title:SetPoint("TOPLEFT"); row.Title:SetWidth(textWidth)
  row.Title.Text:SetHeight(0)
  local titleHeight=math.max(self.trackerDB.fontSize+2,row.Title.Text:GetStringHeight())
  row.Title:SetHeight(titleHeight)
  self:UpdateTrackerStatus(row,id,complete or watch.popupType=="COMPLETE",watch.popupType)
  local y=titleHeight+4
  if watch.popupType then
    y=self:AddTrackerText(row,watch.popupType=="OFFER" and (QUEST_WATCH_QUEST_READY or "퀘스트 수락 가능")
      or (QUEST_WATCH_CLICK_TO_COMPLETE or "클릭하여 완료"),y,textWidth)
  elseif complete then
    local text=GetQuestLogCompletionText and GetQuestLogCompletionText(index)
    y=self:AddTrackerText(row,QN.IsText(text) and text or (QUEST_WATCH_QUEST_COMPLETE or "완료"),y,textWidth,true)
  elseif QN.IsTrue(C_QuestLog.IsFailed and C_QuestLog.IsFailed(id)) then
    y=self:AddTrackerText(row,FAILED or "실패",y,textWidth)
  else
    local objectives=C_QuestLog.GetQuestObjectives and C_QuestLog.GetQuestObjectives(id)
    if QN.IsTable(objectives) then
      for objectiveIndex,objective in ipairs(objectives) do
        local text=objective.text
        if QN.IsID(index) and GetQuestLogLeaderBoard then
          local nativeText=GetQuestLogLeaderBoard(objectiveIndex,index,true)
          if QN.IsText(nativeText) then text=nativeText end
        end
        local percent
        if objective.type=="progressbar" and GetQuestProgressBarPercent then
          percent=GetQuestProgressBarPercent(id)
          if QN.IsNumber(percent) then text=(QN.IsText(text) and text or "진행도")..string.format(" (%.0f%%)",percent) end
        end
        y=self:AddTrackerText(row,text,y,textWidth,QN.IsTrue(objective.finished))
        if QN.IsNumber(percent) then
          row.barCount=(row.barCount or 0)+1
          local bar=row.bars[row.barCount]
          if not bar then
            bar=CreateFrame("StatusBar",nil,row); bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
            bar:SetStatusBarColor(.26,.42,1); bar:SetMinMaxValues(0,100); row.bars[row.barCount]=bar
          end
          bar:ClearAllPoints(); bar:SetPoint("TOPLEFT",row,"TOPLEFT",8,-y); bar:SetSize(textWidth-8,12)
          bar:SetValue(math.max(0,math.min(100,percent))); bar:Show(); y=y+16
        end
      end
    end
    local required=C_QuestLog.GetRequiredMoney and C_QuestLog.GetRequiredMoney(id)
    local money=GetMoney and GetMoney()
    if QN.IsNumber(required) and QN.IsNumber(money) and required>money and GetMoneyString then
      y=self:AddTrackerText(row,GetMoneyString(money).." / "..GetMoneyString(required),y,textWidth)
    end
  end
  if C_SuperTrack.GetSuperTrackedQuestID()==id and C_QuestLog.GetNextWaypointText then
    y=self:AddTrackerText(row,C_QuestLog.GetNextWaypointText(id),y,textWidth)
  end
  if QN.IsText(link) then
    local item=self:CreateTrackerItem(row)
    item:ClearAllPoints(); item:SetPoint("TOPRIGHT",row,"TOPRIGHT",0,0)
    item:SetAttribute("item",link); item.logIndex=index; item.Icon:SetTexture(texture)
    if GetQuestLogSpecialItemCooldown then
      local start,duration=GetQuestLogSpecialItemCooldown(index)
      if QN.IsNumber(start) and QN.IsNumber(duration) then item.Cooldown:SetCooldown(start,duration) end
    end
    item:Show(); y=math.max(y,36)
  elseif row.Item then row.Item:Hide(); row.Item:SetAttribute("item",nil); row.Item.logIndex=nil end
  return math.max(32,y+6)
end
function QN:RestoreNativeTrackerPresentation()
  for frame,alpha in pairs(self.trackerMasked or {}) do frame:SetAlpha(alpha) end
  self.trackerMasked={}
  for texture,shown in pairs(self.trackerHeaderDecorations or {}) do texture:SetShown(shown) end
  self.trackerHeaderDecorations={}
end
function QN:HideTrackerHeaderDecorations()
  if inCombat() then self.trackerPending=true; return end
  self.trackerHeaderDecorations=self.trackerHeaderDecorations or {}
  local function hide(texture)
    if not texture or not texture:IsObjectType("Texture") then return end
    if self.trackerHeaderDecorations[texture]==nil then
      -- IsShown preserves the texture's own state even when its header is hidden.
      self.trackerHeaderDecorations[texture]=texture:IsShown()
    end
    texture:Hide()
  end
  -- Explicit regions from the Forever container/module header templates. The
  -- primary Background atlas includes the gold border and end ornaments.
  -- Do not enumerate textures: buttons, quest icons and progress bars stay intact.
  local header=ObjectiveTrackerFrame and ObjectiveTrackerFrame.Header
  if header then hide(header.Background) end
  header=self.objectiveModule and self.objectiveModule.Header
  if header then hide(header.Background); hide(header.Shine); hide(header.Glow) end
end
function QN:MaskNativeTrackerFrame(frame)
  if self.trackerMasked[frame]==nil then self.trackerMasked[frame]=frame:GetAlpha() end
  frame:SetAlpha(0)
end
function QN:ScrollTracker(delta)
  if not self.trackerEnabled or not self.trackerScroll or inCombat() then return end
  self.trackerScroll:SetVerticalScroll(math.max(0,math.min(self.trackerScrollMax or 0,
    self.trackerScroll:GetVerticalScroll()-delta*self.trackerDB.fontSize*3)))
end
function QN:InstallObjectiveTracker()
  if self.trackerScroll or not self.trackerEnabled or inCombat() then return end
  local root,native=ObjectiveTrackerFrame,QuestObjectiveTracker
  if not root or not native or not native.ContentsFrame or not ObjectiveTrackerLineFont then return end
  self.objectiveModule=native -- Read-only reference; never call its Update/MarkDirty.
  self.trackerMasked={}; self.trackerRows={}
  local scroll=CreateFrame("ScrollFrame",nil,root)
  local child=CreateFrame("Frame",nil,scroll)
  child:SetSize(235,1); scroll:SetScrollChild(child)
  scroll:SetFrameLevel(native:GetFrameLevel()+20)
  scroll:EnableMouse(true); scroll:EnableMouseWheel(true)
  scroll:SetScript("OnMouseWheel",function(_,delta) self:ScrollTracker(delta) end)
  scroll:Hide(); self.trackerScroll=scroll; self.trackerScrollChild=child
  self.trackerCountLabel=root:CreateFontString(nil,"OVERLAY","ObjectiveTrackerHeaderFont")
  self.trackerCountLabel:Hide()
  -- These hooks only enqueue addon work. No native methods/data are changed in
  -- the hook; no native layout is requested by the eventual addon refresh.
  hooksecurefunc(root,"UpdateHeaderPosition",function() self:RequestTrackerLayout() end)
  native:HookScript("OnShow",function() self:RequestTrackerLayout() end)
  native:HookScript("OnHide",function() self:RequestTrackerLayout() end)
  if EventRegistry then
    EventRegistry:RegisterCallback("EditMode.Enter",function() self.trackerNativeEditing=true; self:RequestTrackerLayout() end,self)
    EventRegistry:RegisterCallback("EditMode.Exit",function() self.trackerNativeEditing=false; self:RequestTrackerLayout() end,self)
  end
end
function QN:RefreshObjectiveQuestCount()
  local text=ObjectiveTrackerFrame and ObjectiveTrackerFrame.Header and ObjectiveTrackerFrame.Header.Text
  local label=self.trackerCountLabel
  if not text or not label then return end
  local base=ObjectiveTrackerFrame.headerText
  if not QN.IsText(base) then base=text:GetText() end
  local _,count=C_QuestLog.GetNumQuestLogEntries()
  local max=Constants and Constants.QuestLogConsts and Constants.QuestLogConsts.MAXIMUM_NUM_QUESTS_LOG_CAN_ACCEPT
  if not QN.IsText(base) then return end
  label:ClearAllPoints(); label:SetPoint("TOPLEFT",text,"TOPLEFT")
  local path,size,flags=text:GetFont(); label:SetFont(path,size,flags)
  label:SetText(QN.IsNumber(count) and QN.IsID(max) and string.format("%s ( %d / %d )",base,count,max) or base)
  self:MaskNativeTrackerFrame(text); label:Show()
end
function QN:RenderObjectiveTracker()
  if inCombat() then self.trackerPending=true; return end
  if self.trackerTooltipOwner then
    if GameTooltip and GameTooltip:IsOwned(self.trackerTooltipOwner) then GameTooltip:Hide() end
    self.trackerTooltipOwner=nil
  end
  self.trackerPending=false
  if not self.trackerEnabled then
    self:RestoreNativeTrackerPresentation()
    if self.trackerScroll then self.trackerScroll:Hide(); self.trackerCountLabel:Hide() end
    if self.trackerEvents then self.trackerEvents:UnregisterAllEvents() end
    return
  end
  self:InstallObjectiveTracker()
  local native,scroll=self.objectiveModule,self.trackerScroll
  if not scroll then return end
  self:RestoreNativeTrackerPresentation()
  scroll:Hide(); self.trackerCountLabel:Hide()
  local root=ObjectiveTrackerFrame
  if self.trackerNativeEditing or (EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive()) then return end
  self:RefreshObjectiveQuestCount()
  self:HideTrackerHeaderDecorations()
  if root:IsCollapsed() or not native:IsShown() or (native.IsCollapsed and native:IsCollapsed()) then return end
  self:GetTrackerDB()
  local groups=self:BuildTrackerGroups(self:CollectTrackerWatches())
  local width=self:GetTrackerWidth()
  scroll:ClearAllPoints(); scroll:SetPoint("TOPRIGHT",native.ContentsFrame,"TOPRIGHT",0,0)
  -- Respect the native allocation: scenario and every other section keep their
  -- existing parents, anchors, heights, update methods and shared dirty driver.
  local viewport=math.max(1,native:GetHeight()-(native.Header and native.Header:GetHeight() or 26))
  -- A native POI extends 33px left of the title. Keep that space inside the
  -- clipping viewport while preserving the title's right edge and text width.
  local viewportWidth=math.max(width+36,native:GetWidth())
  scroll:SetSize(viewportWidth,viewport); self.trackerScrollChild:SetWidth(viewportWidth)
  local y,count=0,0
  local function row()
    -- Without a leading region row, leave room for the first icon's upper edge.
    if count==0 and (not self.trackerDB.groupByRegion or
      (GetNumAutoQuestPopUps and GetNumAutoQuestPopUps()>0)) then y=12 end
    count=count+1
    local r=self:CreateTrackerRow(count); r.lineCount=0; r.barCount=0
    for _,fs in ipairs(r.lines) do fs:Hide() end
    for _,bar in ipairs(r.bars) do bar:Hide() end
    if r.Item then r.Item:Hide(); r.Item:SetAttribute("item",nil); r.Item.logIndex=nil end
    if r.Status then r.Status:Hide(); r.Status.questID=nil; r.Status.popupType=nil end
    r:ClearAllPoints(); r:SetPoint("TOPRIGHT",self.trackerScrollChild,"TOPRIGHT",0,-y); r:SetWidth(width)
    return r
  end
  if GetNumAutoQuestPopUps and GetAutoQuestPopUp then
    for i=1,GetNumAutoQuestPopUps() do
      local id,kind=GetAutoQuestPopUp(i)
      if QN.IsID(id) and (kind=="OFFER" or kind=="COMPLETE") then
        local r=row(); local height=self:RenderTrackerQuest(r,{id=id,index=i,popupType=kind},width)
        r:SetHeight(height); r:Show(); y=y+height
      end
    end
  end
  for _,group in ipairs(groups) do
    if self.trackerDB.groupByRegion then
      local r=row(); local b=r.Title
      b.questID=nil; b.popupType=nil; b.regionKey=group.key
      font(b.Text,self.trackerDB.fontSize+1); b.Text:SetTextColor(1,119/255,95/255)
      b.Text:SetText((self.trackerDB.collapsibleRegions and (group.collapsed and "▶ " or "▼ ") or "")..group.name)
      b:ClearAllPoints(); b:SetPoint("TOPLEFT"); b:SetWidth(width); b.Text:SetHeight(0)
      local height=math.max(self.trackerDB.fontSize+5,b.Text:GetStringHeight()+4)
      b:SetHeight(height); r:SetHeight(height); r:Show(); y=y+height+4
    end
    if not group.collapsed then
      for _,watch in ipairs(group.watches) do
        local r=row(); local height=self:RenderTrackerQuest(r,watch,width)
        r:SetHeight(height); r:Show(); y=y+height
      end
    end
  end
  for i=count+1,#self.trackerRows do
    local r=self.trackerRows[i]; r:Hide()
    if r.Status then r.Status:Hide(); r.Status.questID=nil; r.Status.popupType=nil end
    if r.Item then r.Item:SetAttribute("item",nil); r.Item.logIndex=nil end
  end
  self.trackerScrollChild:SetHeight(math.max(1,y)); self.trackerScrollMax=math.max(0,y-viewport)
  scroll:SetVerticalScroll(math.min(self.trackerScrollMax,scroll:GetVerticalScroll()))
  self:MaskNativeTrackerFrame(native.ContentsFrame)
  scroll:Show(); self:RefreshObjectiveQuestCount()
end
function QN:RequestTrackerLayout()
  if not self.trackerEnabled then return end
  self.trackerPending=true
  if inCombat() or self.trackerScheduled then return end
  self.trackerScheduled=true
  local generation=self.trackerGeneration
  C_Timer.After(0,function()
    if generation~=self.trackerGeneration then return end
    self.trackerScheduled=false
    if self.trackerEnabled then self:RenderObjectiveTracker() end
  end)
end
function QN:SetObjectiveTrackerEnabled(enabled)
  self:GetTrackerDB(); self.trackerEnabled=enabled==true
  self.trackerGeneration=(self.trackerGeneration or 0)+1
  self.trackerScheduled=false; self.trackerPending=false
  if not self.trackerEvents and self.trackerEnabled then
    local f=CreateFrame("Frame"); self.trackerEvents=f
    f:SetScript("OnEvent",function(_,event,name)
      if event=="ADDON_LOADED" and name~="Blizzard_ObjectiveTracker" then return end
      if event=="PLAYER_REGEN_ENABLED" then self:RenderObjectiveTracker()
      else self:RequestTrackerLayout() end
    end)
  end
  local f=self.trackerEvents
  if f then
    f:UnregisterAllEvents()
    if self.trackerEnabled then
      for _,event in ipairs({"ADDON_LOADED","PLAYER_ENTERING_WORLD","QUEST_LOG_UPDATE","QUEST_WATCH_LIST_CHANGED",
        "QUEST_WATCH_UPDATE","QUEST_ACCEPTED","QUEST_REMOVED","QUEST_TURNED_IN","QUEST_AUTOCOMPLETE",
        "QUEST_POI_UPDATE","SUPER_TRACKING_CHANGED","PLAYER_MONEY","BAG_UPDATE_COOLDOWN","PLAYER_REGEN_ENABLED"}) do f:RegisterEvent(event) end
    elseif inCombat() and self.trackerScroll then
      -- Only restoration remains; no stale quest/profile work survives OFF.
      f:RegisterEvent("PLAYER_REGEN_ENABLED")
    end
  end
  if not self.trackerEnabled then self:RenderObjectiveTracker() else self:RequestTrackerLayout() end
end
function QN:PrintTrackerLayout()
  self:GetTrackerDB()
  local groups=self:BuildTrackerGroups(self:CollectTrackerWatches())
  if not DEFAULT_CHAT_FRAME then return end
  for _,group in ipairs(groups) do
    DEFAULT_CHAT_FRAME:AddMessage("KHQOL Quest Layout: ["..group.name.."] "..#group.watches.." / "..(group.collapsed and "CLOSED" or "OPEN"))
  end
  DEFAULT_CHAT_FRAME:AddMessage("KHQOL Quest Layout: addon-owned; font "..self.trackerDB.fontSize.." / width "..self:GetTrackerWidth())
end
