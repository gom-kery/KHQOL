local _, KHQOL = ...
local PA=KHQOL.modules.pvpAlert
function PA:BuildSettings(content,y)
  if not self.initialized then self:Initialize() end
  local UI,db=KHQOL.UI,self:GetDB()
  self.settingsContent=content
  local b=UI:CreateBuilder(content,y)
  local function available() return self:IsEnabled() end
  local function checkbox(label,key)
    b:Checkbox(label,function() return db[key] end,function(value) db[key]=value; self:Changed() end,available)
  end
  local function slider(label,key,min,max,step,format)
    b:Slider(label,min,max,step,function() return db[key] end,function(value) db[key]=value; self:Changed() end,format,available)
  end
  b:Section("레이아웃")
  b:Slider("전체 크기",50,200,5,function() return db.scale*100 end,function(v) db.scale=v/100; self:Changed() end,function(v) return string.format("%d%%",v) end,available)
  b:Slider("투명도",10,100,5,function() return db.alpha*100 end,function(v) db.alpha=v/100; self:Changed() end,function(v) return string.format("%d%%",v) end,available)
  slider("X 위치","x",-3000,3000,1,function(v) return string.format("%.0f",v) end)
  slider("Y 위치","y",-2000,2000,1,function(v) return string.format("%.0f",v) end)
  b:Button("위치 이동 / 이동 완료",function() self:SetMoving(not self.moving) end,240,available)
  b:Button("위치 초기화",function() self:ResetPosition() end,180,available)
  b:Description("기본 위치는 화면 중앙 위 +165입니다. 설정 페이지를 닫거나 전투가 시작되면 위치가 잠깁니다.")
  b:Section("기본 동작")
  checkbox("비전투 중에만 동작","onlyOutOfCombat")
  b:Description("화면에 네임플레이트가 있는 적 플레이어만 감지합니다. NPC 및 중립 유닛은 제외합니다.")
  b:Section("주시 경고")
  checkbox("주시 경고 표시","watchingEnabled"); checkbox("주시 경고 소리","watchingSound")
  slider("타겟 확정 시간","targetConfirmTime",.1,2,.1,function(v) return string.format("%.1f초",v) end)
  b:Section("접근 경고")
  checkbox("접근 경고 표시","approachEnabled"); checkbox("접근 경고 소리","approachSound")
  checkbox("Pulse 효과","approachPulse")
  slider("접근 판정","approachConfirmScore",1,3,1,function(v) return string.format("%d단계",v) end)
  b:Section("시전 경고")
  checkbox("시전 경고 표시","castingEnabled"); checkbox("시전 경고 소리","castingSound")
  checkbox("주문 아이콘 표시","showSpellIcon"); checkbox("시전 바 표시","showCastBar"); checkbox("남은 시간 표시","showCastTime")
  b:Section("테스트")
  b:Button("테스트: WATCHING",function() self:Test("WATCHING") end,240,available)
  b:Button("테스트: APPROACHING",function() self:Test("APPROACHING") end,240,available)
  b:Button("테스트: CASTING",function() self:Test("CASTING") end,240,available)
  b:Description("CASTING은 2.5초 가상 시전으로 바와 남은 시간을 확인합니다.")
  b:Section("고급 / 진단")
  checkbox("디버그 모드","debug")
  b:Button("API 및 사거리 진단",function()
    self:Print("v"..self.VERSION.." | "..self.Range:Describe())
    for _,name in ipairs({"UnitGUID","UnitCastingInfo","UnitChannelInfo","UnitSpellTargetName","IsSpellInRange","CheckInteractDistance"}) do
      self:Print(name..": "..(type(_G[name])=="function" and "available" or "unavailable"))
    end
    self:Print("C_Spell range: "..tostring(C_Spell and type(C_Spell.IsSpellInRange)=="function" or false)..
      " | C_SpellBook range: "..tostring(C_SpellBook and type(C_SpellBook.IsSpellBookItemInRange)=="function" or false))
    self:Print("지원하지 않는 이벤트: "..(#self.unsupportedEvents==0 and "없음" or table.concat(self.unsupportedEvents,", ")))
  end,240,available)
  content:HookScript("OnShow",function() self.settingsContent=content end)
  content:HookScript("OnHide",function()
    if KHQOL.PositionEditor and KHQOL.PositionEditor.active then return end
    self:SetMoving(false); self:StopTest(); self.settingsContent=nil
  end)
  return b.y
end
