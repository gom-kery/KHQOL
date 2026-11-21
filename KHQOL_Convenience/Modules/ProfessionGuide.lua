local K=_G.KHQOL
local M=K.modules.professions
local G={epoch=0,hooked=setmetatable({}, {__mode="k"})}
M.guide=G
local call,number=K.PublicCall,K.IsPublicNumber
local function integer(v) return number(v) and v>=0 and v==math.floor(v) end
local function text(v) return K.IsPublicValue(v) and type(v)=="string" end
function G:Enabled() return M:GetDB().rankGuide.enabled==true end
function G:Message(s) K:ProfileMessage(s) end
function G:Metric(id,phase) K.UsageDiagnostics:Emit("feature.profession."..id,phase,"click") end
function G:Learned(id)
  for _,group in pairs(M.professionData or {}) do for _,entry in ipairs(group) do if entry.skillLineID==id then return entry end end end
end
function G:State(id)
  local catalog=M.rankCatalog.professions[id]
  local learned=not catalog and self:Learned(id)
  local state={id=id,catalog=catalog,name=catalog and catalog.name or learned and learned.name,status=catalog and "unknown" or "unsupported"}
  local level=call(UnitLevel,"player");if integer(level) and level>0 then state.level=level end
  local rank,maximum,hasInfo
  if C_SkillInfo and type(C_SkillInfo.GetSkillLineInfoByID)=="function" then
    local status,info=K.ReadPublicAPI(C_SkillInfo.GetSkillLineInfoByID,id)
    if status~="ok" then return state end
    if info~=nil then
      if not K.IsPublicValue(info) or type(info)~="table" then return state end
      local skillID,header
      skillID=call(function() return info.skillID end)
      header=call(function() return info.isHeader end)
      if skillID~=id or header~=false then return state end
      hasInfo=true
      rank=call(function() return info.rank end)
      maximum=call(function() return info.maxRank end)
    end
  end
  if rank==nil and not hasInfo then
    local entry=self:Learned(id)
    if entry then rank,maximum=entry.skill,entry.maxSkill end
  end
  -- Both APIs expose base rank separately from temporary/racial/equipment
  -- modifiers. Never add those modifiers, or infer a tier from current rank.
  if integer(rank) then state.skill=rank end
  if integer(maximum) and maximum>0 then state.maximum=maximum end
  if not state.maximum then return state end
  if state.skill and rank>maximum then state.skill=nil end
  if not catalog then return state end
  for index,tier in ipairs(catalog.ranks) do
    if maximum==tier.maximum then
      state.tier=tier;state.next=catalog.ranks[index+1]
      state.status=tier.id==4 and maximum==300 and "final" or state.next and "next" or "unsupported";return state
    end
  end
  state.status="unknown_cap";return state
end
function G:Candidates(state)
  local result,seen={},{}
  local faction=call(UnitFactionGroup,"player")
  faction=faction=="Alliance" and "alliance" or faction=="Horde" and "horde" or nil
  for _,acquisition in ipairs(state.next and state.next.candidates or {}) do
    local p=M.rankCatalog.locations[acquisition.npc]
    if p and (acquisition.side=="both" or faction and acquisition.side==faction) then
      local key=p.id..":"..acquisition.kind..":"..tostring(acquisition.ref or 0)
      if not seen[key] then
        seen[key]=true;result[#result+1]={id=key,point=p,method=acquisition,priority=(acquisition.side==faction and 0 or 2)+(p.mapID and M.rankCatalog.maps[p.mapID] and M.rankCatalog.maps[p.mapID].city and 0 or 1)}
      end
    end
  end
  table.sort(result,function(a,b) if a.priority~=b.priority then return a.priority<b.priority end;return a.id<b.id end)
  return result
end
function G:Point(candidate)
  local p=candidate.point;local expected=p.mapID and M.rankCatalog.maps[p.mapID]
  if p.locationStatus~="VERIFIED" or not expected or not number(p.x) or not number(p.y) then return nil,"좌표 또는 원문 지도 기준 미확인" end
  if p.x<0 or p.x>100 or p.y<0 or p.y>100 then return nil,"좌표 범위 미확인" end
  local status,info=K.ReadPublicAPI(C_Map and C_Map.GetMapInfo,p.mapID)
  if status~="ok" or not K.IsPublicValue(info) or type(info)~="table" then return nil,"클라이언트 지도 확인 불가" end
  local mapID,name,mapType=call(function() return info.mapID,info.name,info.mapType end)
  local types=Enum and Enum.UIMapType
  if mapID~=p.mapID or name~=expected.name or not types or (mapType~=types.Zone and mapType~=types.City) then return nil,"원문과 클라이언트의 지도 ID·이름·종류가 일치하지 않음" end
  return {mapID=p.mapID,x=p.x/100,y=p.y/100}
end
function G:NoteReason()
  local fc=K.modules.clock
  if not fc or not fc.AddTodoCoordinate or not fc.IsTodoCoordinateEnabled then return "ForeverNote 모듈을 설치하고 노트 사용을 켜세요." end
  if not fc:IsTodoCoordinateEnabled() then return "편의 기능에서 노트 사용을 먼저 켜세요." end
  if call(InCombatLockdown)==true then return "전투 종료 후 위치를 등록하세요." end
end
function G:Ticket(owner,id)
  local view=self:Presentation(id);local state=view.state
  if not self:Enabled() or not view.showPlaces then return nil,view end
  return {owner=owner,id=id,maximum=state.maximum,nextID=state.next.id,generation=K.profileGeneration,epoch=self.epoch,signature=view.signature,faction=view.faction},view
end
function G:Validate(t)
  if not t or not self:Enabled() or t.generation~=K.profileGeneration or t.epoch~=self.epoch then return nil end
  if t.owner and (call(t.owner.IsVisible,t.owner)~=true or t.owner.guideID and t.owner.guideID()~=t.id) then return nil end
  local view=self:Presentation(t.id);local state=view.state
  if not view.showPlaces or view.signature~=t.signature or view.faction~=t.faction or state.maximum~=t.maximum or not state.next or state.next.id~=t.nextID then return nil end
  return state,view
end
function G:Request(owner,id)
  if self.tooltipOwner==owner then self:ShowTooltip(owner,id,false) end
  local ticket,requested=self:Ticket(owner,id)
  -- Preserve the existing meaning: an explicit attempt, including a refusal.
  if self:Enabled() and requested.state.next then self:Metric("note_request","request") end
  if not ticket then self:CloseMenu();return false end
  local reason=self:NoteReason();if reason then self:Message(reason);return false end
  local state,view=self:Validate(ticket)
  if not state then self:Message("현재 전문기술 안내를 다시 열어 주세요.");return false end
  if view.registrable==0 then
    self:Message(view.places[1].reason or "현재 습득처의 좌표를 확인할 수 없습니다.");return false
  end
  if #view.places==1 then return self:Register(ticket,view.places[1].candidate.id) end
  self:ChooseCandidates(owner,ticket,view.places);return true
end
function G:Register(ticket,candidateID)
  local state,view=self:Validate(ticket)
  if not state then self:CloseMenu();self:Message("전문기술·다음 단계 또는 프로필이 바뀌었습니다. 안내를 다시 여세요.");return false end
  local reason=self:NoteReason();if reason then self:Message(reason);return false end
  local candidate
  for _,place in ipairs(view.places) do if place.candidate.id==candidateID then candidate=place.candidate;break end end
  if not candidate then return false end
  local p,error_=self:Point(candidate);if not p then self:Message(error_);return false end
  local fc=K.modules.clock
  local label=state.name.." · "..state.next.name.." · "..candidate.point.name
  local item,why=fc:AddTodoCoordinate(p.mapID,p.x,p.y,label)
  if not item then self:Message(why or "노트 등록 실패");return false end
  if why=="duplicate" then
    self:Message("같은 지도·좌표·메모의 노트가 이미 있습니다. 기존 항목을 유지합니다.")
    self:ShowNoteResult(ticket.owner,item,ticket);return item,"duplicate"
  end
  local live=false
  fc:EachTodoTask(function(value) if value==item and value.waypoint and value.waypoint.mapID==p.mapID and value.waypoint.x==p.x and value.waypoint.y==p.y then live=true end end)
  if not live then self:Message("노트 항목 생성을 확인할 수 없습니다.");return false end
  self:Metric("note_added","execute");self:Message("ForeverNote 좌표 목록에 추가했습니다. 길 안내는 메뉴에서 직접 시작하세요.")
  self:ShowNoteResult(ticket.owner,item,ticket);return item,"created"
end
function G:Navigate(ticket)
  local fc=K.modules.clock
  if not self:Enabled() or self:NoteReason() or not fc or not ticket or not fc:ValidateTodoPinRouteTicket(ticket) then self:Message("노트·프로필·좌표 상태를 다시 확인하세요.");return false end
  if not fc:StartTodoPinGuidance(ticket) then return false end
  self:Metric("navigate","execute");return true
end
function G:Refresh()
  if not self:Enabled() then return end
  self:AttachNative()
  if self.menuTicket then
    local _,view=self:Validate(self.menuTicket)
    if not view or self:NoteReason() or view.registrable==0 then self:CloseMenu() end
  end
  if self.tooltipOwner and self.tooltipOwner:IsVisible() then
    local id=self.tooltipOwner.guideID and self.tooltipOwner.guideID() or self.tooltipID
    if id then self:ShowTooltip(self.tooltipOwner,id,false) else self:Leave(self.tooltipOwner) end
  elseif self.tooltipOwner then self:Leave(self.tooltipOwner) end
end
function G:Configure()
  local on=self:Enabled()
  if not self.events then
    self.events=CreateFrame("Frame")
    self.events:SetScript("OnEvent",function(_,event,addon)
      if not G:Enabled() then return end
      if event=="ADDON_LOADED" and addon~="Blizzard_Professions" then return end
      if event=="PLAYER_REGEN_DISABLED" then G:HideNative();G:CloseMenu();return end
      if G.queued then return end
      local ticket={};G.queued=ticket;local epoch=G.epoch;local generation=K.profileGeneration
      C_Timer.After(0,function()
        if G.queued~=ticket then return end
        G.queued=nil;if epoch==G.epoch and generation==K.profileGeneration and G:Enabled() then G:Refresh() end
      end)
    end)
  end
  if self.on~=on or self.generation~=K.profileGeneration then
    self.on=on;self.generation=K.profileGeneration;self.epoch=self.epoch+1;self.queued=nil
    self.events:UnregisterAllEvents()
    if on then for _,event in ipairs({"ADDON_LOADED","SKILL_LINES_CHANGED","PLAYER_LEVEL_UP","TRADE_SKILL_SHOW","TRADE_SKILL_LIST_UPDATE","TRADE_SKILL_DATA_SOURCE_CHANGED","TRADE_SKILL_CLOSE","PLAYER_REGEN_ENABLED","PLAYER_REGEN_DISABLED"}) do call(self.events.RegisterEvent,self.events,event) end end
    self:CloseMenu();self:Leave(self.tooltipOwner);if not on then self:HideNative() end
  end
  if on then self:Refresh() end
end
