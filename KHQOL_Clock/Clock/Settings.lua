local _, KHQOL = ...
KHQOL = assert(_G.KHQOL, "Install and enable the KHQOL core addon.")
local FC, UI = KHQOL.modules.clock, KHQOL.UI
local L = FC.L
local targetNames = {common="공통",date="날짜",money="소지금",weekday="요일",performance="FPS / 지연시간",professions="전문기술"}
local effects = {{value="NONE",text="없음"},{value="OUTLINE",text="외곽선"},{value="THICKOUTLINE",text="두꺼운 외곽선"},{value="SHADOW",text="그림자"}}

function FC:GetSideFontSize(target)
  return target == "common" and self.db.moduleFontSize or (self.db.modules[target].fontSize or self.db.moduleFontSize)
end
function FC:SetSideFontSize(target, size)
  if target == "common" then self.db.moduleFontSize = size else self.db.modules[target].fontSize = size end
  self:ApplyLayout(); self:UpdateDate(); self:UpdateWeekday(); self:UpdateMoney(); self:UpdatePerformance(); if self.ApplyProfessionFont then self:ApplyProfessionFont() end
end
function FC:ApplyTextStyleTarget(target)
  if target == "clock" then self:ApplyClock()
  else
    self:ApplyLayout(); self:UpdateDate(); self:UpdateWeekday(); self:UpdateMoney(); self:UpdatePerformance()
    if self.ApplyProfessionFont then self:ApplyProfessionFont() end
  end
end
function FC:CreateSettings(parent)
  if self.settingsFrame then return self.settingsFrame end
  if not parent then
    KHQOL:ShowSettings("clock")
    return self.settingsFrame
  end
  -- Build in the actual scroll/tab body; never reparent a UIParent panel.
  local f=parent
  f:SetWidth(UI.Theme.ContentWidth); self.settingsFrame=f
  _G.ForeverClockSettingsFrame=f
  local b=UI:CreateBuilder(f)
  local function style(target)
    b:Color("글자 색상",function() return unpack(FC:GetTextStyle(target()).color) end,function(r,g,bl,a)
      local key=target(); FC:SetTextStyleValue(key,"color",{r,g,bl,a}); FC:ApplyTextStyleTarget(key)
    end,nil,nil,true)
    b:Dropdown("텍스트 효과",effects,function() return FC:GetTextStyle(target()).effect end,function(v)
      local key=target(); FC:SetTextStyleValue(key,"effect",v); FC:ApplyTextStyleTarget(key)
    end)
  end
  b:Section("표시 정보")
  for _,item in ipairs({{"performance",L.PERFORMANCE},{"date",L.DATE},{"weekday",L.WEEKDAY},{"money",L.MONEY}}) do
    local key,title=item[1],item[2]
    b:Checkbox(title,function() return FC.db.modules[key].enabled end,function(v)
      FC.db.modules[key].enabled=v; FC:ApplyLayout()
      if key=="performance" then FC:UpdateTimers()
      elseif key=="date" then FC:UpdateDate()
      elseif key=="weekday" then FC:UpdateWeekday() end
    end)
  end
  b:Dropdown("날짜 형식",{{value="YMD",text="년 / 월 / 일"},{value="MD",text="월 / 일"}},function() return FC.db.modules.date.format end,function(v) FC.db.modules.date.format=v; FC:UpdateDate() end,function() return FC.db.modules.date.enabled end)
  b:Dropdown("요일 언어",{{value="ko",text=L.WEEKDAY_KO},{value="en",text=L.WEEKDAY_EN}},function() return FC.db.modules.weekday.language end,function(v) FC.db.modules.weekday.language=v; FC:UpdateWeekday() end,function() return FC.db.modules.weekday.enabled end)
  for _,item in ipairs({{"gold",L.GOLD},{"silver",L.SILVER},{"copper",L.COPPER}}) do
    local unit,title=item[1],item[2]
    b:Checkbox(title,function() return FC.db.modules.money.units[unit] end,function(v) FC.db.modules.money.units[unit]=v; FC:UpdateMoney() end,function() return FC.db.modules.money.enabled end)
  end
  b:Section("위치")
  b:Checkbox("위치 잠금",function() return FC.db.locked end,function(v) FC.db.locked=v; FC:ApplyClock(); FC:ApplyLayout() end)

  b:Section("시간 글자·모양")
  b:Slider("글자 크기",24,80,1,function() return FC.db.fontSize end,function(v) FC.db.fontSize=v; FC:ApplyClock() end,function(v) return v.." px" end)
  style(function() return "clock" end)
  b:Section("사이드 텍스트")
  f.sideTargetKey="common"
  local targets={}
  for _,key in ipairs({"common","date","money","weekday","performance","professions"}) do targets[#targets+1]={value=key,text=targetNames[key]} end
  b:Dropdown("설정 대상",targets,function() return f.sideTargetKey end,function(v) f.sideTargetKey=v; FC:RefreshSettings() end)
  b:Slider("글자 크기",10,28,1,function() return FC:GetSideFontSize(f.sideTargetKey) end,function(v) FC:SetSideFontSize(f.sideTargetKey,v) end,function(v) return v.." px" end)
  style(function() return f.sideTargetKey end)
  b:Section("전문기술")
  b:Checkbox("전문기술 버튼 표시",function() return FC.db.modules.professions.enabled end,function(v) FC.db.modules.professions.enabled=v; FC:UpdateProfessionsVisibility() end)
  local function professionsEnabled() return FC.db.modules.professions.enabled end
  b:Dropdown("배치 방향",{{value="horizontal",text="가로형"},{value="vertical",text="세로형"}},function() return FC.db.modules.professions.layout end,function(v) FC.db.modules.professions.layout=v; FC:RenderProfessions() end,professionsEnabled)
  b:Slider("아이콘 크기",24,56,1,function() return FC.db.modules.professions.iconSize end,function(v)
    FC.db.modules.professions.iconSize=v; if FC.professionsPanel and FC.professionsPanel:IsShown() then FC:RenderProfessions() end
  end,function(v) return v.." px" end,professionsEnabled)
  b:Checkbox("숙련도 표시",function() return FC.db.modules.professions.showSkill end,function(v)
    FC.db.modules.professions.showSkill=v; if FC.professionsPanel and FC.professionsPanel:IsShown() then FC:RenderProfessions() end
  end,professionsEnabled)
  b:Section("알람·타이머·스톱워치")
  b:Description("도구는 각 창의 시작·정지·초기화 동작을 사용합니다. 설정창을 닫아도 실행 중인 도구는 계속됩니다. 알람 문구는 공용 내용이며 전체 프로필을 바꾸어도 유지합니다.",true)
  for _,entry in ipairs({{"알람 열기","alarm"},{"타이머 열기","timer"},{"스톱워치 열기","stopwatch"}}) do
    local mode=entry[2]
    b:Button(entry[1],function()
      if mode=="stopwatch" then FC.stopwatchFrame:Show()
      else FC.clockToolsFrame:SelectMode(mode);FC.clockToolsFrame:Show() end
    end)
  end
  b:Checkbox("도구 창 위치 잠금",function() return FC.db.clockTools.positionLocked end,function(v) FC.db.clockTools.positionLocked=v end)
  b:Description("시간 HUD와 도구 창은 독립 위치입니다. 직접 드래그와 통합 편집 모두 현재 프로필에 저장합니다. 중앙 테스트 알림은 Alt+드래그로 이동합니다.",true)
  f:SetHeight(-b.y); self:RefreshSettings()
  return f
end
function FC:RefreshSettings()
  if not self.settingsFrame or self.refreshingSettings then return end
  self.refreshingSettings=true; UI:Refresh(self.settingsFrame); self.refreshingSettings=false
end
function FC:ToggleSettings() KHQOL:ShowSettings("clock") end
