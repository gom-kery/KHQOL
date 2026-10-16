local _, KHQOL = ...
local H={experimental=true,defaults={},generation=0}
KHQOL.GraphicsJournal=H
-- Functional inputs are independently implemented; no reference addon code is embedded.
local settings={
  {name="outlineModeShowLootEffectWhenDisabled",value="1",required=true},
  {name="graphicsOutlineMode",value="0",required=true},
  {name="OutlineEngineMode",value="0"},
  {name="raidGraphicsOutlineMode",value="0"},
  {name="RAIDOutlineEngineMode",value="0"},
}
local watched={graphicsquality=true,raidgraphicsquality=true}
for _,s in ipairs(settings) do watched[s.name:lower()]=true end
local function public(value)
  if type(issecretvalue)=="function" then
    local ok,secret=pcall(issecretvalue,value);if not ok or type(secret)~="boolean" or secret then return false end
  end
  return true
end
local function scalar(value)
  if not public(value) or type(value)~="string" and type(value)~="number" then return end
  local s=tostring(value)
  -- Outline modes and the loot switch are bounded integer settings.
  if s:match("^[0-3]$") then return s end
end
local function api(name)
  return C_CVar and C_CVar[name] or _G[name]
end
local function read(name)
  local get=api("GetCVar")
  if type(get)~="function" then return nil,"읽기 API 없음" end
  local ok,value=pcall(get,name)
  return ok and scalar(value) or nil,not ok and "읽기 오류" or "지원되지 않거나 읽을 수 없는 값"
end
local function writable(name)
  if type(api("SetCVar"))~="function" then return false,"쓰기 API 없음" end
  local info=api("GetCVarInfo")
  if type(info)=="function" then
    local ok,v,_,_,_,locked,secure,readonly=pcall(info,name)
    if not ok or not public(v) or v==nil then return false,"설정 정보 확인 실패" end
    if type(v)=="table" then locked,secure,readonly=v.isLockedFromUser,v.isSecure,v.isReadOnly end
    local flags={locked,secure,readonly}
    for index=1,3 do
      local flag=flags[index]
      if not public(flag) or type(flag)~="boolean" or flag then return false,"보호되거나 확인할 수 없는 설정" end
    end
  end
  return true
end
local function combat()
  local checked=false
  local checks={InCombatLockdown,UnitAffectingCombat}
  for index=1,2 do
    local f=checks[index]
    if type(f)=="function" then
      checked=true;local ok,on=pcall(f,"player")
      if not ok or not public(on) or type(on)~="boolean" then return true end
      if on then return true end
    end
  end
  return not checked
end
function H:GetState()
  local d=KHQOL.LabLock:GetStorage()
  if type(d.objectHighlight)~="table" then d.objectHighlight={} end
  local s=d.objectHighlight
  if type(s.records)~="table" then s.records={} end
  return s
end
function H:HasRestoreRecords() return next(self:GetState().records)~=nil end
function H:IsEnabled() return KHQOL:CanRunModule("objectHighlight") end
function H:Conflict()
  local loaded=C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
  if type(loaded)=="function" then
    local ok,on=pcall(loaded,"ForeverLootSparkles")
    if not ok or not public(on) or type(on)~="boolean" then return nil end
    return on
  end
  if type(ForeverLootSparklesDB)=="table" and ForeverLootSparklesDB.enabled~=false then return true end
  return nil
end
function H:Notify()
  if self.RefreshStatus then self:RefreshStatus() end
  KHQOL.LabLock:OnGraphicsSettled()
end
function H:GetStatus()
  local status=self.status or "OFF · 그래픽 설정을 변경하지 않았습니다."
  if not KHQOL.LabLock:IsUnlocked() then status="실험실 잠금 · "..status end
  if self:GetState().mayNeedRestart then status=status.."\n시각 효과 해제에는 게임 재시작이 필요할 수 있습니다. /reload만으로 완료되지 않을 수 있습니다." end
  if self.eventUnavailable then status=status.."\n일부 변경·전투 이벤트를 사용할 수 없어 자동 처리가 제한됩니다." end
  return status
end
function H:CancelPending()
  self.generation=self.generation+1
  if self.timer and type(self.timer.Cancel)=="function" then pcall(self.timer.Cancel,self.timer) end
  self.timer=nil;self.pendingCombat=nil
end
function H:Watch(active)
  local f=self.events
  self.eventUnavailable=nil
  for _,event in ipairs({"CVAR_UPDATE","ADDON_LOADED"}) do
    if active then
      local ok=pcall(f.RegisterEvent,f,event);if not ok then self.eventUnavailable=true end
    else f:UnregisterEvent(event) end
  end
  if self.pendingCombat then
    local ok=pcall(f.RegisterEvent,f,"PLAYER_REGEN_ENABLED");if not ok then self.eventUnavailable=true end
  else f:UnregisterEvent("PLAYER_REGEN_ENABLED") end
end
function H:Defer(action)
  self.pendingCombat=action
  self.status=(action=="apply" and "적용" or "원래 설정 복원").." 대기 · 전투 종료 또는 전투 상태 확인 후 처리합니다."
  self:Watch(true);self:Notify()
end
function H:Write(name,value)
  local ok,why=writable(name);if not ok then return false,why end
  self.writing=true
  local called,result=pcall(api("SetCVar"),name,value)
  self.writing=false
  local current=read(name)
  self.ownWrites=self.ownWrites or {};self.ownWrites[name:lower()]=current
  return called and public(result) and result~=false and current==value,
    not called and "쓰기 오류" or "설정값 적용 확인 실패"
end
function H:Restore()
  self.restoreSkipped=nil
  local state=self:GetState();local records=state.records
  if not next(records) then
    self.status=self:IsEnabled() and self.status or "OFF · 복원할 그래픽 변경 기록이 없습니다."
    self:Watch(self:IsEnabled());self:Notify();return true
  end
  local conflict=self:Conflict()
  if conflict~=false then
    self.status=conflict and "복원 보류 · Forever Loot Sparkles를 끄고 UI를 다시 로드하세요. 복원 기록을 보존합니다."
      or "복원 보류 · 중복 애드온 상태 확인 API를 사용할 수 없습니다. 기록을 보존합니다."
    self:Watch(true);self:Notify();return false
  end
  if combat() then self:Defer("restore");return false end
  local failures,skipped={},{}
  -- Use only the known CVar list. Unknown/corrupt journal entries are retained.
  for _,s in ipairs(settings) do
    local r=records[s.name]
    if r then
      local original=type(r)=="table" and scalar(r.original)
      local applied=type(r)=="table" and scalar(r.lastWritten)
      local current=read(s.name)
      if not original or not applied or not current then failures[#failures+1]=s.name
      elseif current==original then records[s.name]=nil
      elseif current~=applied then
        -- Someone changed this setting after our last write. Keep their value.
        records[s.name]=nil;skipped[#skipped+1]=s.name
      else
        local ok=self:Write(s.name,original)
        if ok then records[s.name]=nil else failures[#failures+1]=s.name end
      end
    end
  end
  if next(records) then
    self.status="복원 미완료 · 기록을 보존합니다. "..table.concat(failures,", ")
  else
    self.status="OFF · KHQOL이 변경한 설정을 원래 값으로 복원했습니다."
    if #skipped>0 then self.restoreSkipped=table.concat(skipped,", ");self.status=self.status.."\n다른 곳에서 변경한 값은 유지했습니다: "..self.restoreSkipped end
  end
  self:Watch(self:IsEnabled() or next(records)~=nil);self:Notify()
  return next(records)==nil
end
H.compat={settings=settings,watched=watched,public=public,scalar=scalar,api=api,read=read,writable=writable,combat=combat}
function H:Sync()
  self:CancelPending()
  if self:IsEnabled() then return self:Apply() end
  return self:Restore()
end
H.events=CreateFrame("Frame")
H.events:SetScript("OnEvent",function(_,event,name)
  if event=="PLAYER_REGEN_ENABLED" then
    if H.pendingCombat then H:Sync() end
  elseif event=="ADDON_LOADED" and name=="ForeverLootSparkles" then
    H:CancelPending();H:Sync()
  elseif event=="CVAR_UPDATE" and not H.writing and public(name) and type(name)=="string" then
    local key=name:lower()
    if not watched[key] then return end
    if key=="graphicsquality" or key=="raidgraphicsquality" then H.ownWrites={}
    elseif H.ownWrites and H.ownWrites[key]~=nil then
      for _,s in ipairs(settings) do if s.name:lower()==key and read(s.name)==H.ownWrites[key] then return end end
      H.ownWrites[key]=nil
    end
    if not H:IsEnabled() then
      -- No recurring work: retry a failed restore only on a relevant user event.
      if H:HasRestoreRecords() then H:Restore() end
      return
    end
    if key~="graphicsquality" and key~="raidgraphicsquality" then
      for _,s in ipairs(settings) do if key==s.name:lower() and read(s.name)==s.value then return end end
    end
    H:ScheduleApply()
  end
end)

function KHQOL:RecoverDormantGraphics()
  -- Recovery is a legacy-loader responsibility; applying a feature still requires Labs.
  local journal=KHQOLLabDB and KHQOLLabDB.objectHighlight
  if not self.ModuleRegistry.entries.objectHighlight and type(journal)=="table" and type(journal.records)=="table" and next(journal.records) then H:Restore() end
end
