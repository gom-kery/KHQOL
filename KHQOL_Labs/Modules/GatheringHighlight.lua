local K=_G.KHQOL
local H,J=K.modules.objectHighlight,K.SoftTargetJournal
local G={unit="softinteract",cursorIDs={}}
H.gathering=G
local call,public=K.PublicCall,K.IsPublicValue
local defaults={questSparkles=true,gatherEnabled=false,size=100,alpha=.8,offsetX=0,offsetY=-60,showInCombat=false,
  categories={herb={enabled=true,effect="imageCross",color={.55,1,.65}},ore={enabled=true,effect="imageCross",color={1,.75,.25}},chest={enabled=true,effect="imageCross",color={.4,.8,1}}}}
H.defaults=defaults
function H:GetDB()
  K.db.modules.objectHighlight=K.MergeDefaults(K.db.modules.objectHighlight or {},defaults,"tables")
  local db=K.db.modules.objectHighlight
  db.offsetX=math.max(-200,math.min(200,K.IsPublicNumber(db.offsetX) and db.offsetX or defaults.offsetX))
  db.offsetY=math.max(-200,math.min(100,K.IsPublicNumber(db.offsetY) and db.offsetY or defaults.offsetY))
  return db
end
local cursors={GatherHerbs="herb",Mine="ore",LootAll="loot",Pickup="generic",PickLock="generic",Interact="generic",GamepadInteract="generic",
  Quest="quest",QuestRepeatable="quest",QuestTurnIn="quest",QuestInteract="quest",CampaignQuest="quest",Important="quest",Recurring="quest",Wrapper="quest",
  Mail="service",Speak="service",Buy="service",Trainer="service",Taxi="service",Innkeeper="service",Repair="service",Stablemaster="service",Fishing="bobber"}
local function number(v) return K.IsPublicNumber(v) end
local function text(v) return public(v) and type(v)=="string" end
function G:Notify()
  local status=self:GetStatus()
  if status==self.lastStatus then return end
  self.lastStatus=status
  if H.RefreshStatus then H:RefreshStatus() end
end
function G:Supported()
  return type(UnitIsGameObject)=="function" and type(UnitGUID)=="function" and type(UnitName)=="function"
    and type(SetUnitCursorTexture)=="function" and C_NamePlate and type(C_NamePlate.GetNamePlateForUnit)=="function"
    and C_QuestLog and type(C_QuestLog.UnitIsRelatedToActiveQuest)=="function"
    and UIParent and type(UIParent.CreateLine)=="function"
    and C_Timer and type(C_Timer.NewTicker)=="function"
end
function G:ObjectID(guid)
  if not text(guid) or #guid>160 then return end
  local id=tonumber(guid:match("^GameObject%-%d+%-%d+%-%d+%-%d+%-(%d+)%-%x+$"))
  if number(id) and id>0 then return id end
end
function G:Probe()
  if self.probe then return true end
  local frame=CreateFrame("Frame",nil,UIParent);frame:Hide()
  self.probe=frame:CreateTexture(nil,"ARTWORK")
  for name,kind in pairs(cursors) do
    for _,prefix in ipairs({"","Unable"}) do
      local path="Interface\\Cursor\\"..prefix..name
      local id=call(GetFileIDFromPath,path) or call(GetFileIDFromPath,path..".blp")
      if number(id) and id>0 then self.cursorIDs[id]={kind=kind,blocked=prefix~=""} end
    end
  end
  return true
end
function G:ReadCursor()
  self:Probe()
  if call(SetUnitCursorTexture,self.probe,self.unit,nil,true)~=true then return end
  local texture=call(self.probe.GetTexture,self.probe)
  local atlas=call(self.probe.GetAtlas,self.probe)
  local entry=number(texture) and self.cursorIDs[texture]
  if entry then return entry.kind,entry.blocked end
  local value=text(atlas) and atlas or text(texture) and texture
  if not value or #value>256 then return end
  value=value:lower();local blocked=value:find("unable",1,true)~=nil
  -- Exact cursor suffixes or atlas tokens, never arbitrary object-name guesses.
  local tokens={}
  for token in value:gmatch("[a-z]+") do tokens[token]=true end
  local leaf=value:match("([^\\/]+)$") or value;leaf=leaf:gsub("%.blp$","")
  tokens[leaf]=true
  for name,kind in pairs(cursors) do
    local key=name:lower()
    if tokens[key] or tokens["unable"..key] then return kind,blocked end
  end
end
function G:Containers()
  local d=K.LabLock:GetStorage()
  if type(d.gatheringContainers)~="table" then d.gatheringContainers={} end
  return d.gatheringContainers
end
function G:Classify(guid,cursor,blocked)
  if cursor==nil then cursor,blocked=self:ReadCursor() end
  local quest=call(C_QuestLog and C_QuestLog.UnitIsRelatedToActiveQuest,self.unit)
  if quest~=false or cursor=="quest" or cursor=="service" or cursor=="bobber" then return nil,blocked,"퀘스트/서비스/미확인 대상 제외" end
  local id=self:ObjectID(guid)
  if id==35591 then return nil,blocked,"낚시 찌 제외" end
  if id==529161 or id==573022 or id==529148 or id==29784 then return nil,blocked,"모닥불 제외" end
  if cursor=="herb" or cursor=="ore" then return cursor,blocked,"채집 커서" end
  if cursor=="loot" then return "chest",blocked,"게임 전리품 커서" end
  local learned=id and self:Containers()[id]
  if cursor=="generic" and type(learned)=="table" and learned.proof=="matched-gameobject-loot" then return "chest",blocked,"검증된 전리품 출처 ID" end
  return nil,blocked,"분류 근거 부족"
end
function G:LearnContainer()
  if not self.active or call(UnitIsGameObject,self.unit)~=true then return end
  local guid=call(UnitGUID,self.unit);local id=self:ObjectID(guid)
  if not id or id==35591 or id==529161 or id==573022 or id==529148 or id==29784
    or call(C_QuestLog and C_QuestLog.UnitIsRelatedToActiveQuest,self.unit)~=false then return end
  local cursor=self:ReadCursor()
  if cursor~="generic" and cursor~="loot" then return end
  local name=call(UnitName,self.unit)
  if not text(name) or #name>256 then return end
  local lowerName=name:lower()
  local hint=false
  for _,word in ipairs({"상자","궤짝","보물","chest","coffer","strongbox","coffre","truhe"}) do
    if lowerName:find(word,1,true) then hint=true;break end
  end
  if not hint then return end -- A name is supplementary, never proof by itself.
  local count=call(GetNumLootItems)
  if not number(count) or count<1 or count>100 then return end
  for slot=1,count do
    local sources={pcall(GetLootSourceInfo,slot)}
    if sources[1] then
      for index=2,#sources,2 do
        local source,quantity=sources[index],sources[index+1]
        if text(source) and source==guid and number(quantity) and quantity>0 then
          self:Containers()[id]={proof="matched-gameobject-loot"};self.cache=nil;return
        end
      end
    end
  end
end
function G:ReadState(blocked)
  local range=call(UnitIsInInteractRange,self.unit)
  if range==false then return "far",.35 end
  if range~=true then return "unknown",.3 end
  if blocked then return "locked",.45 end
  return "ready",1
end
function G:Hide()
  if self.frame then K.ObjectHighlightEffects:Stop(self.frame);self.frame:Hide();self.frame:ClearAllPoints() end
  self.plate=nil;self.kind=nil;self.interaction=nil
end
function G:ResolveTarget(guid)
  local plate=call(C_NamePlate and C_NamePlate.GetNamePlateForUnit,self.unit)
  if not plate and self.alias and call(UnitIsGameObject,self.alias)==true and call(UnitGUID,self.alias)==guid then
    plate=call(C_NamePlate.GetNamePlateForUnit,self.alias)
  end
  if not plate then return nil,"오브젝트 이름표를 찾지 못함" end
  if call(plate.IsForbidden,plate)~=false then return nil,"접근할 수 없는 이름표" end
  if call(plate.IsShown,plate)~=true then return nil,"이름표가 숨겨져 있음" end
  if K.GraphicsJournal.compat.combat() and call(plate.IsProtected,plate)~=false then return nil,"전투 중 보호된 이름표" end
  return plate
end
function G:Present(plate,kind,blocked)
  if not self.frame then
    self.frame=CreateFrame("Frame",nil,UIParent);self.frame:EnableMouse(false)
    if type(self.frame.CreateLine)~="function" then self.frame:Hide();self.stage="render";self.status="효과 Line API 미지원";return end
    self.frame:SetSize(1,1)
    self.frame:SetScript("OnHide",function(f) K.ObjectHighlightEffects:Stop(f) end)
  end
  local db=H:GetDB();local config=db.categories[kind]
  local state,scale=self:ReadState(blocked)
  local color=config.color
  if state=="locked" then color={.55,.55,.55} end
  local size=tonumber(db.size) or 100;size=math.max(40,math.min(240,size))
  local alpha=tonumber(db.alpha) or .8;alpha=math.max(.1,math.min(1,alpha))*scale
  local ok,shown=pcall(function()
    if self.plate and self.plate~=plate then K.ObjectHighlightEffects:Stop(self.frame) end
    self.frame:ClearAllPoints();self.frame:SetPoint("CENTER",plate,"CENTER",db.offsetX,db.offsetY)
    return K.ObjectHighlightEffects:Render(self.frame,config.effect,size,color,alpha)
  end)
  if not ok or shown~=true then
    self:Hide();self.stage="render";self.status="효과 API 호출 실패 또는 미지원 효과 설정"
    if not ok and public(shown) and type(shown)=="string" then
      self.lastRenderError=shown:gsub("[\r\n]"," "):sub(1,400)
    elseif ok then self.lastRenderError="등록되지 않은 효과 또는 표시 실패" end
    return false
  end
  self.frame:Show();self.plate=plate;self.kind=kind;self.interaction=state
  return true
end
function G:Tick()
  if not self.active then return end
  if call(UnitIsGameObject,self.unit)~=true then
    self:Hide();self.cache=nil
    if self.ticker then self.ticker:Cancel();self.ticker=nil end
    self.stage="soft-target";self.status="현재 Soft Target 오브젝트를 확인할 수 없음"
    self:Notify();return
  end
  if not self.ticker then self.ticker=C_Timer.NewTicker(.2,function() G:Tick() end) end
  local db=H:GetDB()
  if not db.showInCombat and K.GraphicsJournal.compat.combat() then
    self:Hide();self.stage="combat";self.status="설정에 따라 전투 중 숨김";self:Notify();return
  end
  local guid=call(UnitGUID,self.unit)
  if not text(guid) then self:Hide();self.stage="guid";self.status="오브젝트 GUID를 읽을 수 없음";self:Notify();return end
  local quest=call(C_QuestLog and C_QuestLog.UnitIsRelatedToActiveQuest,self.unit)
  if quest~=false then
    self:Hide();self.cache=nil;self.stage="quest"
    self.status=quest==true and "퀘스트 관련 오브젝트 제외" or "퀘스트 관련 여부를 공개 정보로 확인할 수 없음"
    self:Notify();return
  end
  local cursor,cursorBlocked=self:ReadCursor()
  local kind,blocked,reason
  -- Cache classification only until an object/cursor/quest event invalidates it.
  if self.cache and self.cache.guid==guid and self.cache.cursor==cursor and self.cache.blocked==cursorBlocked then kind,blocked,reason=self.cache.kind,self.cache.blocked,self.cache.reason
  else
    kind,blocked,reason=self:Classify(guid,cursor,cursorBlocked);self.cache={guid=guid,kind=kind,blocked=blocked,reason=reason,cursor=cursor}
  end
  local config=kind and db.categories[kind]
  if not config then self:Hide();self.stage="classification";self.status=reason or "분류 근거 부족";self:Notify();return end
  if not config.enabled then self:Hide();self.stage="category";self.status="해당 종류의 강조 설정 OFF: "..kind;self:Notify();return end
  local plate,why=self:ResolveTarget(guid)
  if self.presentedGUID and self.presentedGUID~=guid and self.frame then K.ObjectHighlightEffects:Stop(self.frame) end
  self.presentedGUID=guid
  if not plate then self:Hide();self.stage="nameplate";self.status=(reason or "분류됨").." · "..(why or "이름표 확인 실패")
  elseif not self:Present(plate,kind,blocked) then self:Notify();return
  else self.stage="shown";self.status=reason or "표시 중" end
  self:Notify()
end
function G:StopTracking()
  self.active=false;self.cache=nil;self.alias=nil
  self.stage="stopped"
  if self.ticker then self.ticker:Cancel();self.ticker=nil end
  if self.events then self.events:UnregisterAllEvents() end
  self:Hide()
end
function G:Sync()
  self:StopTracking();J.applyPending=nil
  local db=H:GetDB()
  local any=false;for _,kind in ipairs({"herb","ore","chest"}) do if db.categories[kind].enabled then any=true end end
  if not K:CanRunModule("objectHighlight") or not db.gatherEnabled or not any then
    J:Restore();self.stage="settings";self.status="모듈/실험실/채집 사용/종류 설정 중 하나가 OFF";self:Notify();return
  end
  if not self:Supported() then J:Restore();self.stage="api";self.status="필수 Soft Target/퀘스트/Line/타이머 API 미지원";self:Notify();return end
  if not J:Acquire(self) then self.stage="cvar";self.status=J.status;self:Notify();return end
  self.active=true
  if not self.events then
    self.events=CreateFrame("Frame")
    self.events:SetScript("OnEvent",function(_,event,unit)
      if event=="LOOT_OPENED" then G:LearnContainer()
      elseif event=="PLAYER_LEAVING_WORLD" then G.alias=nil;G:Hide();if G.ticker then G.ticker:Cancel();G.ticker=nil end;return
      elseif event=="NAME_PLATE_UNIT_ADDED" then
        if public(unit) and type(unit)=="string" and call(UnitIsGameObject,unit)==true then
          local guid,soft=call(UnitGUID,unit),call(UnitGUID,G.unit)
          if text(guid) and text(soft) and guid==soft then G.alias=unit end
        end
      elseif event=="NAME_PLATE_UNIT_REMOVED" then if public(unit) and unit==G.alias then G.alias=nil;G:Hide() end end
      G.cache=nil;G:Tick()
    end)
  end
  for _,event in ipairs({"PLAYER_SOFT_INTERACT_CHANGED","WORLD_CURSOR_TOOLTIP_UPDATE","NAME_PLATE_UNIT_ADDED","NAME_PLATE_UNIT_REMOVED",
    "PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED","PLAYER_ENTERING_WORLD","PLAYER_LEAVING_WORLD","QUEST_LOG_UPDATE","LOOT_OPENED"}) do
    local ok=pcall(self.events.RegisterEvent,self.events,event)
    if not ok and event=="PLAYER_SOFT_INTERACT_CHANGED" then
      self:StopTracking();J:Restore();self.status="필수 Soft Target 변경 이벤트 미지원";self:Notify();return
    end
  end
  self:Tick()
end
function G:GetStatus()
  return (J.status or "Soft Target 미적용").."\nAPI: "..(self:Supported() and "필수 함수 있음 (인게임 동작 확인 필요)" or "미지원/확인 불가")
    .."\n현재 종류: "..(self.kind or "없음").." · 상호작용: "..(self.interaction or "미확인")
    .."\n단계: "..(self.stage or "미확인").." · "..(self.status or "")
end
