local _, KHQOL = ...
local FR, UI = KHQOL.modules.range, KHQOL.UI
local Settings = {}; FR.Settings=Settings
function Settings:Create()
  if self.panel then return end
  local panel=CreateFrame("Frame","FRangeSettingsPanel",UIParent)
  panel:SetWidth(UI.Theme.ContentWidth); panel:Hide(); self.panel=panel
  local b=UI:CreateBuilder(panel)
  b:Section("위치")
  b:Checkbox("위치 잠금",function() return FR.db.locked end,function(v) FR:ToggleLock(v) end)
  b:Slider("X 위치",-1000,1000,1,function() return FR.db.x end,function(v) FR:SetNumber("x",v,-1000,1000) end)
  b:Slider("Y 위치",-1000,1000,1,function() return FR.db.y end,function(v) FR:SetNumber("y",v,-1000,1000) end)
  b:Button("표시 테스트",function() FR:CycleTest() end)
  b:Section("마우스오버 거리 측정")
  local function mouseoverEnabled() return FR.db.mouseover.enabled end
  local function refreshMouseover() FR.Mouseover:Update(); UI:Refresh(panel) end
  b:Checkbox("적 툴팁에 표시",function() return FR.db.mouseover.enabled end,function(v) FR.db.mouseover.enabled=v; refreshMouseover() end)
  b:Flush()
  local row=b.y; b.y=b.y-UI.Theme.DropdownRowHeight
  local positionLabel=UI:CreateLabel(panel,"표시 위치",0,row)
  local position=UI:CreateDropdown(panel,0,row-24,288,{{value="BELOW",text="툴팁 아래"},{value="LEFT",text="툴팁 왼쪽"}},function() return FR.db.mouseover.position end,function(v) FR.db.mouseover.position=v; refreshMouseover() end,mouseoverEnabled)
  position.uiLabels={positionLabel}; position:Refresh()
  local reset=UI:CreateButton(panel,"메시지 위치 초기화",312,row,180,function() FR.db.mouseover.x,FR.db.mouseover.y=0,0; refreshMouseover() end,mouseoverEnabled)
  local x=b:Slider("X 위치 보정",-100,200,1,function() return FR.db.mouseover.x end,function(v) FR.db.mouseover.x=v; refreshMouseover() end,nil,mouseoverEnabled)
  local y=b:Slider("Y 위치 보정",-100,100,1,function() return FR.db.mouseover.y end,function(v) FR.db.mouseover.y=v; refreshMouseover() end,nil,mouseoverEnabled)
  b:Flush()
  row=b.y; b.y=b.y-UI.Theme.DropdownRowHeight
  local messages={}
  for index,entry in ipairs({{"availableText","공격가능 문구"},{"unavailableText","공격불가 문구"}}) do
    local key,title=entry[1],entry[2]
    local column=(index-1)*208
    local label=UI:CreateLabel(panel,title,column,row); label:SetWidth(184)
    local input=UI:CreateEditBox(panel,column,row-24,184,function() return FR.db.mouseover[key] end,function(v)
      v=v:gsub("^%s+",""):gsub("%s+$","")
      FR.db.mouseover[key]=FR:LimitMouseoverText(v~="" and v or FR.defaults.mouseover[key]); refreshMouseover()
    end,mouseoverEnabled)
    input.uiLabels={label}; input:SetMaxLetters(8); input:Refresh(); messages[index]=input
  end
  local font=UI:CreateSlider(panel,"글자 크기","",416,row,10,40,1,function() return FR.db.mouseover.fontSize end,function(v) FR.db.mouseover.fontSize=v; refreshMouseover() end,function(v) return v.." px" end,mouseoverEnabled)
  font.numberBox:SetWidth(58) -- fit the third 184px column, without changing shared sliders
  self.mouseoverControls={position=position,reset=reset,x=x,y=y,font=font,available=messages[1],unavailable=messages[2]}
  b:Description("문구는 한글 포함 최대 8자입니다. Enter로 적용하며 빈 입력은 기본 문구로 복원합니다. X +는 오른쪽, Y +는 위쪽입니다. 사망한 대상은 표시하지 않습니다.")
  b:Description("아래 사거리 기준 주문을 사용합니다. 초록: 공격 가능 / 빨강: 공격 불가 / 노랑: 판정 불가. 재사용 대기시간, 자원, 시야는 확인하지 않습니다.")
  b:Section("표시 모양")
  self.shape=b:Edit("표시 문자",function() return FR.db.shape end,function(v)
    FR.db.shape=v~="" and v or "\226\150\160"; FR:RefreshDisplay(true)
  end)
  UI:AttachTooltip(self.shape,"표시 문자","문자를 입력하고 Enter를 눌러 적용합니다.")
  b:Slider("크기",10,80,1,function() return FR.db.size end,function(v) FR:SetNumber("size",v,10,80) end,function(v) return v.." px" end)
  b:Section("외곽선")
  b:Checkbox("외곽선 표시",function() return FR.db.outline.enabled end,function(v) FR.db.outline.enabled=v; FR:RefreshDisplay(true) end)
  local function outlineEnabled() return FR.db.outline.enabled end
  b:Slider("외곽선 두께",0,4,1,function() return FR.db.outline.thickness end,function(v) FR:SetOutlineThickness(v) end,nil,outlineEnabled)
  b:Color("외곽선 색상",function() return unpack(FR.db.outline.color) end,function(r,g,bl)
    local c=FR.db.outline.color; c[1],c[2],c[3],c[4]=r,g,bl,1; FR:RefreshDisplay(true)
  end,outlineEnabled)
  b:Section("색상")
  for _,definition in ipairs({{"GREEN","사거리 안"},{"RED","사거리 밖"},{"ORANGE","데드존"}}) do
    local key,title=definition[1],definition[2]
    b:Color(title,function() return unpack(FR.db.colors[key]) end,function(r,g,bl) FR:SetColor(key,r,g,bl,1) end)
  end
  b:Section("사거리 기준 주문")
  local function hunter() return select(2,UnitClass("player"))=="HUNTER" end
  b:Description("주문 ID 또는 스킬명을 입력하고 Enter 또는 적용 버튼을 누릅니다.")
  if hunter() then
    local function spellField(title,getter,setter)
      local x,y,width=b:Cell("spell",2,104)
      UI:CreateLabel(panel,title,x,y):SetWidth(width)
      local input=UI:CreateEditBox(panel,x,y-24,width-88,getter,setter)
      UI:CreateButton(panel,"적용",x+width-72,y-24,72,function() setter(input:GetText()); input:ClearFocus() end)
      local info=UI:CreateDescription(panel,"",x,y-62); info:SetWidth(width)
      return input,info
    end
    self.rangeSpell,self.rangeInfo=spellField("원거리 기준 주문",function() return FR.db.rangeSpellID or "" end,function(v) FR:SetRangeSpell(v) end)
    self.meleeSpell,self.meleeInfo=spellField("근거리 기준 주문",function() return FR.db.hunterMeleeSpellID or "" end,function(v) FR:SetMeleeSpell(v) end)
    b:Section("사냥꾼 판정")
    b:Checkbox("근거리 공격도 가능으로 판정",function() return FR.db.hunterMeleeAsAttack end,function(v) FR.db.hunterMeleeAsAttack=v; FR:RefreshDisplay(true) end)
    b:Checkbox("데드존 감지 사용",function() return FR.db.deadZoneEnabled end,function(v) FR.db.deadZoneEnabled=v; FR:RefreshDisplay(true) end)
    b:Description("켜면 원거리 또는 근거리 주문 중 하나라도 사거리 안일 때 초록색입니다. 두 주문 모두 밖이면 기존 보수적 데드존 판정을 사용합니다. 꺼두면 기존 원거리 기준 방식입니다.")
    b:Description("랩터의 일격(2973 계열)은 습득한 날개 절단으로 확인합니다. 주문 검사가 불가능하면 별도의 5야드 검사를 사용합니다. 먼 거리에서는 빨강, 확인된 근거리에서는 초록입니다. 모든 검사가 불가능할 때만 판정 불가입니다.")
  else
    self.rangeSpell=UI:CreateEditBox(panel,0,b.y,360,function() return FR.db.rangeSpellID or "" end,function(v) FR:SetRangeSpell(v) end)
    UI:CreateButton(panel,"적용",376,b.y,86,function() FR:SetRangeSpell(self.rangeSpell:GetText()); self.rangeSpell:ClearFocus() end)
    b.y=b.y-40; self.rangeInfo=b:Description("")
  end
  b:Section("고급 / 확인")
  local api=b:Button("API 상태",function() FR.Range:DescribeAPI() end)
  UI:AttachTooltip(api,"API 상태","클라이언트의 기존 사거리 API 진단 정보를 채팅에 표시합니다.")
  panel:SetHeight(-b.y); self.panel:SetScript("OnShow",function() FR:UpdateSettings() end)
  FR:UpdateSettings()
end
function FR:UpdateSettings()
  if not Settings.panel or not self.db then return end
  Settings.rangeInfo:SetText(self.db.rangeSpellName and ("등록됨: "..self.db.rangeSpellName.." ("..self.db.rangeSpellID..")") or "등록된 사거리 주문이 없습니다.")
  if Settings.meleeInfo then
    local id=self.db.hunterMeleeSpellID
    local name=id and (self.Range:GetSpellInfo(id) or self.db.hunterMeleeSpellName)
    Settings.meleeInfo:SetText(id and ("등록됨: "..(name or "확인 불가").." ("..id..")") or "미등록: 기존 자동 탐색")
  end
  UI:Refresh(Settings.panel)
end
function FR:OpenSettings() KHQOL:ShowSettings("range") end
