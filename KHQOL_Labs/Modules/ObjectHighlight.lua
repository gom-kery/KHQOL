local addonName=...
local KHQOL=assert(_G.KHQOL,"Install and enable KHQOL.")
local H=KHQOL.GraphicsJournal
KHQOL.modules.objectHighlight=H
local c=H.compat
local settings,watched,public,scalar,api,read,writable,combat=c.settings,c.watched,c.public,c.scalar,c.api,c.read,c.writable,c.combat
function H:Apply()
  if not self:IsEnabled() then return self:Restore() end
  local conflict=self:Conflict()
  if conflict~=false then
    self.status=conflict and "적용 차단 · Forever Loot Sparkles가 로드되어 있습니다. 해당 애드온을 끄고 UI를 다시 로드하세요."
      or "적용 불가 · 중복 애드온 상태 확인 API를 사용할 수 없습니다."
    self:Watch(true);self:Notify();return false
  end
  if combat() then self:Defer("apply");return false end
  local plan,missing,failures={},{},{}
  for _,s in ipairs(settings) do
    local current,why=read(s.name)
    if not current then
      if s.required then failures[#failures+1]=s.name.." ("..why..")"
      else missing[#missing+1]=s.name end
    else
      local ok,reason=writable(s.name)
      if not ok then failures[#failures+1]=s.name.." ("..reason..")"
      else plan[#plan+1]={setting=s,current=current} end
    end
  end
  if #failures>0 then
    self:Restore()
    self.status="적용 실패 · "..table.concat(failures,", ")..(self:HasRestoreRecords() and "\n미복원 기록을 보존합니다." or "\n변경 기록은 안전하게 정리했습니다.")
    if self.restoreSkipped then self.status=self.status.."\n마지막 적용값과 다른 값은 유지했습니다: "..self.restoreSkipped end
    self:Watch(true);self:Notify();return false
  end
  local state=self:GetState()
  -- Capture the whole supported change set before the first mutation: graphics
  -- controls may change multiple related CVars in one operation.
  for _,item in ipairs(plan) do
    local s,current=item.setting,item.current
    if current~=s.value then
      local r=state.records[s.name]
      if not r then r={original=current};state.records[s.name]=r end
      if type(r)~="table" or not scalar(r.original) then
        failures[#failures+1]=s.name.." (복원 기록 확인 실패)";break
      end
      -- Persist intent before calling an API that could fail after changing it.
      r.lastWritten=s.value
    end
  end
  if #failures==0 then
    for _,item in ipairs(plan) do
      local s=item.setting
      if item.current~=s.value then
        local ok,why=self:Write(s.name,s.value)
        self.touched=true;state.mayNeedRestart=true
        if not ok then failures[#failures+1]=s.name.." ("..why..")";break end
      end
    end
  end
  -- Read back every supported input, including previously matching ones.
  if #failures==0 then
    for _,item in ipairs(plan) do
      if read(item.setting.name)~=item.setting.value then failures[#failures+1]=item.setting.name end
    end
  end
  if #failures>0 then
    local restored=self:Restore()
    self.status="적용 실패 · "..table.concat(failures,", ")..(restored and "\n복원 가능한 설정의 정리 완료." or "\n복원 미완료 · 기록을 보존합니다.")
    if self.restoreSkipped then self.status=self.status.."\n마지막 적용값과 다른 값은 유지했습니다: "..self.restoreSkipped end
    self:Watch(true);self:Notify();return false
  end
  self.status="지원 설정 적용 완료 ("..#plan.."/5) · 실제 오브젝트 반짝임은 인게임에서 확인하세요."
  if #missing>0 then self.status=self.status.."\n미지원·확인 불가 설정 생략: "..table.concat(missing,", ") end
  self:Watch(true);self:Notify();return true
end
function H:SetEnabled() return self:Sync() end
function H:ScheduleApply()
  self:CancelPending()
  if not self:IsEnabled() then return end
  local token=self.generation
  local function finish()
    if token~=H.generation then return end
    H.timer=nil
    -- Preferences and the developer lock may have changed since scheduling.
    if H:IsEnabled() then H:Apply() end
  end
  local timer=C_Timer and C_Timer.NewTimer
  if type(timer)=="function" then
    local ok,handle=pcall(timer,.35,finish)
    if ok then self.timer=handle;return end
  elseif C_Timer and type(C_Timer.After)=="function" then
    local ok=pcall(C_Timer.After,.35,finish);if ok then return end
  end
  self.status="자동 재적용 대기 불가 · 단발 지연 API를 사용할 수 없습니다. 사용 토글로 다시 적용하세요."
  self:Notify()
end
