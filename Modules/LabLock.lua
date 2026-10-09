local _, KHQOL = ...
local L = {}
KHQOL.LabLock=L
function L:GetStorage()
  if type(KHQOLLabDB)~="table" then KHQOLLabDB={} end
  if KHQOLLabDB.unlocked==nil then KHQOLLabDB.unlocked=false end
  return KHQOLLabDB
end
function L:IsUnlocked()
  local d,c=self:GetStorage(),KHQOL.LabCredentials
  return not self.fullResetPending and type(c)=="table" and type(c.digest)=="string" and #c.digest==64
    and d.unlocked==true and d.unlockVerifier==c.digest or false
end
function L:IsExperimental(key)
  local m=KHQOL.modules[key]
  return m and m.experimental==true or false
end
function KHQOL:CanRunModule(key)
  return self.db and self:GetEnabled(key) and (not L:IsExperimental(key) or L:IsUnlocked()) or false
end
function L:RefreshRuntime()
  if not KHQOL.db then return end
  local p,i,h=KHQOL.modules.procAlert,KHQOL.modules.frameInspector,KHQOL.modules.objectHighlight
  if p and p.SetEnabled then p:SetEnabled(KHQOL:CanRunModule("procAlert")) end
  if i and not self:IsUnlocked() then i:SetEnabled(false); if i.copyOverlay then i.copyOverlay:Hide(); i.copyBox:ClearFocus() end end
  if h then h:Sync() end
end
function L:RefreshUI()
  local s=KHQOL.settings
  if KHQOL.UI then KHQOL.UI:CloseDropdown() end
  if ColorPickerFrame then ColorPickerFrame:Hide() end
  if s then
    if s.page=="labs" then s:ShowPage("labs") else s:RefreshActivePage() end
  end
end
function L:Unlock(value)
  local c=KHQOL.LabCredentials
  if type(c)~="table" or type(c.digest)~="string" or #c.digest~=64 or type(c.salt)~="string" then return false,"개발자 코드가 아직 설정되지 않았습니다." end
  if self.fullResetPending then return false,"전체 초기화 작업이 대기 중입니다." end
  if type(value)~="string" or #value==0 or #value>128 then return false,"개발자 코드를 확인하세요." end
  local ok,digest=pcall(KHQOL.HashLabCode,KHQOL,c.salt.."\0"..value)
  value=nil
  if not ok or digest~=c.digest then return false,"코드가 일치하지 않습니다. 잠금을 유지합니다." end
  local d=self:GetStorage();d.unlocked=true;d.unlockVerifier=c.digest
  self:RefreshRuntime();self:RefreshUI()
  return true,"잠금을 해제했습니다."
end
function L:Relock()
  local d=self:GetStorage();d.unlocked=false;d.unlockVerifier=nil
  self:RefreshRuntime();self:RefreshUI()
  local h=KHQOL.modules.objectHighlight
  if h and h:GetState().mayNeedRestart and KHQOL.ProfileMessage then
    KHQOL:ProfileMessage("실험실을 잠갔습니다. "..h:GetStatus().." 효과가 사라지려면 게임 재시작이 필요할 수 있습니다.")
  end
end
function L:BuildLockedSettings(content,y)
  local UI=KHQOL.UI;local b=UI:CreateBuilder(content,y)
  b:Section("실험실 개발자 잠금")
  b:Description("실험 기능을 사용하려면 개발자 코드로 잠금을 해제하세요.")
  local box=b:Edit("개발자 코드",nil,nil)
  box:SetMaxLetters(128);box:SetPassword(true)
  b:Flush()
  local result
  local function unlock()
    local value=box:GetText();box:SetText("");box:ClearFocus()
    local ok,message=L:Unlock(value);value=nil
    if not ok then result:SetText(message) end
  end
  b:Button("잠금 해제",unlock,140);b:Flush()
  result=UI:CreateDescription(content,"",0,b.y);result:SetWidth(UI.Theme.ContentWidth)
  b.y=b.y-54
  box:SetScript("OnEnterPressed",unlock)
  box:SetScript("OnEscapePressed",function() box:SetText("");box:ClearFocus() end)
  content:HookScript("OnHide",function() box:SetText("");box:ClearFocus();result:SetText("") end)
  content.codeInput=box;content.codeResult=result
  return b.y
end
function L:RequestFullReset(complete)
  self.fullResetPending=true;self.resetComplete=complete;self.resetPreparing=true
  self:RefreshRuntime();self:RefreshUI()
  self.resetPreparing=nil
  self:OnGraphicsSettled()
end
function L:OnGraphicsSettled()
  if not self.fullResetPending or self.resetPreparing or self.resetFinishing then return end
  local h=KHQOL.modules.objectHighlight
  if h and h:HasRestoreRecords() then
    if KHQOL.ProfileMessage then KHQOL:ProfileMessage("전체 초기화 대기: "..h:GetStatus().." 복원 기록과 기존 데이터를 보존합니다.") end
    return
  end
  -- Other modules still need their databases while handling this combat event.
  -- Delete only on the next tick, after every event handler has finished.
  local function complete()
    self.resetFinishing=nil
    if not self.fullResetPending then return end
    if h and h:HasRestoreRecords() then return end
    if h and h:GetState().mayNeedRestart and KHQOL.ProfileMessage then
      KHQOL:ProfileMessage("그래픽 복원 기록을 정리하고 전체 설정을 초기화합니다. 반짝임 효과 해제에는 게임 재시작이 필요할 수 있습니다.")
    end
    local finish=self.resetComplete;self.resetComplete=nil;self.fullResetPending=nil
    if finish then finish() end
  end
  self.resetFinishing=true
  local after=C_Timer and C_Timer.After
  local ok=type(after)=="function" and pcall(after,0,complete)
  if not ok then
    self.resetFinishing=nil
    if KHQOL.ProfileMessage then KHQOL:ProfileMessage("전체 초기화를 완료할 단발 지연 API가 없습니다. 기존 데이터를 보존합니다.") end
  end
end
