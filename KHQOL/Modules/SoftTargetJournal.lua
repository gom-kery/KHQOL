local _,K=...
local J={active=false}
K.SoftTargetJournal=J
local public=K.IsPublicValue
local desired={SoftTargetInteract="3",SoftTargetNameplateInteract="1",SoftTargetInteractRange="15",SoftTargetInteractArc="2",
  SoftTargetInteractOnlyInRange="0",SoftTargetInteractRangeIsHard="0",SoftTargetIconGameObject="1",nameplateGameObjectMaxDistance="60"}
local order={"SoftTargetInteract","SoftTargetNameplateInteract","SoftTargetInteractRange","SoftTargetInteractArc",
  "SoftTargetInteractOnlyInRange","SoftTargetInteractRangeIsHard","SoftTargetIconGameObject","nameplateGameObjectMaxDistance"}
local required={SoftTargetInteract=true,SoftTargetNameplateInteract=true,SoftTargetIconGameObject=true}
local lower={};for _,name in ipairs(order) do lower[name:lower()]=name end
local function scalar(v)
  if not public(v) or (type(v)~="string" and type(v)~="number") then return end
  local n=tonumber(v)
  if not K.IsPublicNumber(n) or n<0 or n>1000000 then return end
  return tostring(n)
end
local function api(name) return C_CVar and C_CVar[name] or _G[name] end
function J:Read(name) return scalar(K.PublicCall(api("GetCVar"),name)) end
function J:GetState()
  local d=K.LabLock:GetStorage()
  if type(d.softTargetJournal)~="table" then d.softTargetJournal={} end
  if type(d.softTargetJournal.records)~="table" then d.softTargetJournal.records={} end
  return d.softTargetJournal
end
function J:HasRecords() return next(self:GetState().records)~=nil end
function J:Conflict()
  local fn=C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
  return K.PublicCall(fn,"Lueur") -- nil is unknown, never permission to write.
end
function J:Notify()
  if self.owner and self.owner.Notify then self.owner:Notify() end
  K.LabLock:OnGraphicsSettled()
end
function J:Watch()
  local watch=self.active or self:HasRecords()
  for _,event in ipairs({"CVAR_UPDATE","ADDON_LOADED","PLAYER_REGEN_ENABLED","PLAYER_ENTERING_WORLD","PLAYER_LOGOUT"}) do
    if watch then pcall(self.events.RegisterEvent,self.events,event) else self.events:UnregisterEvent(event) end
  end
end
function J:Write(name,value)
  if K.GraphicsJournal.compat.combat() then return false end
  if not K.GraphicsJournal.compat.writable(name) then return false end
  self.writing=true
  local ok,result=pcall(api("SetCVar"),name,value)
  self.writing=false
  return ok and public(result) and result~=false and self:Read(name)==value
end
function J:Restore()
  self.active=false
  if not self:HasRecords() then self.pending=nil;self:Watch();return true end
  if self:Conflict()~=false then
    self.status="Lueur 충돌/로드 상태 확인 불가 · Soft Target 복원 기록 보존";self.pending=true;self:Watch();self:Notify();return false
  end
  if K.GraphicsJournal.compat.combat() then
    self.status="Soft Target 복원 대기 · 전투 종료 후 처리";self.pending=true;self:Watch();self:Notify();return false
  end
  local records=self:GetState().records
  local skipped={}
  for _,name in ipairs(order) do
    local record=records[name]
    if record then
      local original=type(record)=="table" and scalar(record.original)
      local written=type(record)=="table" and scalar(record.lastWritten)
      local current=self:Read(name)
      if original and written and current then
        if current==original then records[name]=nil
        elseif current~=written then records[name]=nil;skipped[#skipped+1]=name
        elseif self:Write(name,original) then records[name]=nil end
      end
    end
  end
  self.pending=self:HasRecords()
  self.status=self.pending and "Soft Target 복원 미완료 · 기록 보존" or "Soft Target 변경 설정 복원 완료"
  if #skipped>0 then self.status=self.status.." · 외부 변경 유지: "..table.concat(skipped,", ") end
  self:Watch();self:Notify();return not self.pending
end
function J:Acquire(owner)
  self.owner=owner
  self.degraded=false
  if self:Conflict()~=false then self:Restore();self.status="Lueur 충돌/로드 상태 확인 불가 · 채집 강조 중지";return false end
  if K.GraphicsJournal.compat.combat() then self.status="Soft Target 적용 대기 · 전투 종료 후 처리";self.applyPending=true;self:Watch();self.events:RegisterEvent("PLAYER_REGEN_ENABLED");return false end
  local plan,warnings={},{}
  for _,name in ipairs(order) do
    local current=self:Read(name)
    if not current then
      if required[name] or self:GetState().records[name] then
        self:Restore();self.status="Soft Target CVar 읽기 불가: "..name;return false
      end
      warnings[#warnings+1]=name.." 읽기 불가 · 기존 게임 설정 유지"
    else
      local target=desired[name]
      if name=="nameplateGameObjectMaxDistance" and tonumber(current)>60 then target=current end
      local enforce=true
      if current~=target then
        local writable,why=K.GraphicsJournal.compat.writable(name)
        if not writable then
          if required[name] then
            self:Restore();self.status="Soft Target CVar 쓰기 불가: "..name.." ("..(why or "보호 상태 확인 실패")..")";return false
          end
          target=current;enforce=false
          warnings[#warnings+1]=name.."="..current.." 유지 (변경 불가)"
        end
      end
      plan[#plan+1]={name=name,current=current,target=target,enforce=enforce}
    end
  end
  local records=self:GetState().records
  -- Capture intentions for ALL planned writes before mutating any global CVar.
  for _,item in ipairs(plan) do
    local record=records[item.name]
    if record and (type(record)~="table" or not scalar(record.original) or not scalar(record.lastWritten)) then
      self.status="Soft Target 복원 기록 확인 실패";self:Watch();return false
    end
    if record and item.current~=record.lastWritten and item.current~=record.original then
      self:Restore();self.status="Soft Target 외부 변경 감지 · 사용 토글로 명시적으로 다시 적용하세요.";return false
    end
  end
  for _,item in ipairs(plan) do
    if item.current~=item.target then
      records[item.name]=records[item.name] or {original=item.current}
      records[item.name].lastWritten=item.target
    end
  end
  self.expected={};self.applyPending=nil
  for _,item in ipairs(plan) do if item.enforce then self.expected[item.name]=item.target end end
  for _,item in ipairs(plan) do
    if item.current~=item.target and not self:Write(item.name,item.target) then
      self:Restore();self.status="Soft Target 쓰기 실패 · 가능한 설정 복원/실패 기록 보존: "..item.name;return false
    end
  end
  for _,item in ipairs(plan) do
    if item.enforce and self:Read(item.name)~=item.target then self:Restore();self.status="Soft Target 적용 확인 실패";return false end
  end
  self.active=true;self.pending=nil;self.degraded=#warnings>0
  self.status="Soft Target 적용 · 현재 선택된 오브젝트 한 개만 확인"
  if #warnings>0 then self.status=self.status.."\n범위·각도 등 제한: "..table.concat(warnings,"; ") end
  self:Watch();return true
end
function J:Suspend(reason)
  self.applyPending=nil
  if self.owner then self.owner:StopTracking() end
  self:Restore();self.status=reason.." · "..(self.status or "");self:Notify()
end
J.events=CreateFrame("Frame")
J.events:SetScript("OnEvent",function(_,event,name)
  if event=="CVAR_UPDATE" and not J.writing and public(name) and type(name)=="string" then
    local key=lower[name:lower()]
    if key and J.active and J.expected[key]~=nil and J:Read(key)~=J.expected[key] then J:Suspend("외부 CVar 변경 감지 · 자동 재적용 중지") end
  elseif event=="ADDON_LOADED" and name=="Lueur" then J:Suspend("Lueur 동시 로드 감지")
  elseif event=="PLAYER_LOGOUT" then J:Suspend("로그아웃 복원")
  elseif event=="PLAYER_REGEN_ENABLED" or event=="PLAYER_ENTERING_WORLD" then
    if J.pending then J:Restore()
    elseif J.applyPending and J.owner then J.applyPending=nil;J.owner:Sync() end
  end
end)
