local _, KHQOL = ...
local FR, UI = KHQOL.modules.range, KHQOL.UI
local Settings = {}; FR.Settings=Settings
function Settings:Create(parent)
  if self.panel then return self.panel end
  -- Integrated settings use the tab's own body. A separate UIParent panel
  -- has an independent shown state and rendering hierarchy after embedding.
  local panel=parent or CreateFrame("Frame","FRangeSettingsPanel",UIParent)
  panel:SetWidth(UI.Theme.ContentWidth)
  if not parent then panel:Hide() end
  self.panel=panel; _G.FRangeSettingsPanel=panel
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
  b:Checkbox("스킬 사거리 별 문구",function() return FR.db.stateText==true end,function(v)
    FR.db.stateText=v; FR:RefreshDisplay(true)
  end)
  local function stateTextEnabled() return FR.db.stateText==true end
  for _,entry in ipairs({{"available","사용 가능"},{"unavailable","사용 불가"}}) do
    local key,title=entry[1],entry[2]
    b:Edit(title,function() return FR.db.stateTexts[key] end,function(v)
      FR.db.stateTexts[key]=v~="" and FR:LimitMouseoverText(v) or FR.defaults.stateTexts[key]
      FR:RefreshDisplay(true)
    end,stateTextEnabled)
  end
  b:Description("스킬 사거리 별 문구 OFF 시 특수 문자를 사용합니다.")
  self.shape=b:Edit("특수 문자",function() return FR.db.shape end,function(v)
    FR.db.shape=v~="" and v or "\226\150\160"; FR:RefreshDisplay(true)
  end,function() return not stateTextEnabled() end)
  UI:AttachTooltip(self.shape,"특수 문자","문자를 입력하고 Enter를 눌러 적용합니다.")
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
  local function spellField(title,getter,setter)
    local x,y,width=b:Cell("spell",2,104)
    UI:CreateLabel(panel,title,x,y):SetWidth(width)
    local input=UI:CreateEditBox(panel,x,y-24,width-88,getter,setter)
    UI:CreateButton(panel,"적용",x+width-72,y-24,72,function() setter(input:GetText()); input:ClearFocus() end)
    local info=UI:CreateDescription(panel,"",x,y-62); info:SetWidth(width)
    return input,info
  end
  self.meleeSpell,self.meleeInfo=spellField("근거리 판정 주문",function() return FR.db.meleeSpellID or FR.db.hunterMeleeSpellID or "" end,function(v) FR:SetMeleeSpell(v) end)
  self.rangeSpell,self.rangeInfo=spellField("원거리 판정 주문",function() return FR.db.rangedSpellID or FR.db.rangeSpellID or "" end,function(v) FR:SetRangeSpell(v) end)
  b:Flush()
  b:Button("스킬북에서 등록",function() FR:OpenSpellBookPanel() end,180)
  self.registrationResult=b:Description("")
  b:Description("일반 직업: 하나라도 사거리 안이면 가능, 모두 밖이면 불가. 하나 이상 판정 불가이면 기존 미확인 처리. 빈 입력 적용은 해당 등록 해제입니다.")
  if hunter() then
    b:Section("사냥꾼 판정")
    b:Checkbox("근거리 공격도 가능으로 판정",function() return FR.db.hunterMeleeAsAttack end,function(v) FR.db.hunterMeleeAsAttack=v; FR:RefreshDisplay(true) end)
    b:Checkbox("데드존 감지 사용",function() return FR.db.deadZoneEnabled end,function(v) FR.db.deadZoneEnabled=v; FR:RefreshDisplay(true) end)
    b:Description("켜면 원거리 또는 근거리 주문 중 하나라도 사거리 안일 때 초록색입니다. 두 주문 모두 밖이면 기존 보수적 데드존 판정을 사용합니다. 꺼두면 기존 원거리 기준 방식입니다.")
    b:Description("랩터의 일격(2973 계열)은 습득한 날개 절단으로 확인합니다. 주문 검사가 불가능하면 별도의 5야드 검사를 사용합니다. 먼 거리에서는 빨강, 확인된 근거리에서는 초록입니다. 모든 검사가 불가능할 때만 판정 불가입니다.")
  end
  b:Section("고급 / 확인")
  local api=b:Button("API 상태",function() FR.Range:DescribeAPI() end)
  UI:AttachTooltip(api,"API 상태","클라이언트의 기존 사거리 API 진단 정보를 채팅에 표시합니다.")
  panel:SetHeight(-b.y); panel:HookScript("OnShow",function() FR:UpdateSettings() end)
  FR:UpdateSettings()
  return panel
end
function FR:UpdateSettings()
  if Settings.panel and self.db then
    for _,entry in ipairs({{"ranged","rangeInfo"},{"melee","meleeInfo"}}) do
      local slot,label=entry[1],Settings[entry[2]]
      local id=self.db[slot.."SpellID"]
      if not id then id=slot=="ranged" and self.db.rangeSpellID or self.db.hunterMeleeSpellID end
      local name=id and (self.Range:GetSpellInfo(id) or self.db[slot.."SpellName"])
      label:SetText(id and ("등록됨: "..(name or "조회 불가").." ("..id..")") or "미등록")
    end
    if Settings.registrationResult then Settings.registrationResult:SetText(self.registrationMessage or "") end
    UI:Refresh(Settings.panel)
  end
  if self.RefreshSpellBookPanel then self:RefreshSpellBookPanel() end
end
function FR:OpenSettings() KHQOL:ShowSettings("range") end

local function read(fn,...) return KHQOL.PublicCall(fn,...) end
local function validID(id) return KHQOL.IsPublicValue(id) and type(id)=="number" and id>0 and id<2147483648 and id==math.floor(id) end
-- Own UI only. No native spell click, drag, Mixin or protected attribute replaced.
local function bookHost()
  local modern=PlayerSpellsFrame and PlayerSpellsFrame.SpellBookFrame
  return modern or SpellBookFrame
end
local function outsideCombat()
  if type(InCombatLockdown)~="function" then return true end
  local status,on=KHQOL.ReadPublicAPI(InCombatLockdown)
  return status=="ok" and on==false
end
local function visible(frame)
  if not frame or (frame.IsForbidden and read(frame.IsForbidden,frame)~=false) then return false end
  return read(frame.IsVisible or frame.IsShown,frame)==true
end
function FR:GetBookCandidates()
  local ids,seen={},{}
  local function add(id)
    if validID(id) and not seen[id] then seen[id]=true;ids[#ids+1]=id end
  end
  local B=C_SpellBook;local bank=Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
  local modern=B and type(B.GetNumSpellBookSkillLines)=="function" and type(B.GetSpellBookSkillLineInfo)=="function"
    and type(B.GetSpellBookItemInfo)=="function" and KHQOL.IsPublicValue(bank) and bank~=nil
  local count=read(modern and B.GetNumSpellBookSkillLines or GetNumSpellTabs)
  if not KHQOL.IsPublicValue(count) or type(count)~="number" or count<1 or count>32 then return {} end
  for tab=1,count do
    local offset,size
    if modern then
      local line=read(B.GetSpellBookSkillLineInfo,tab)
      if self.Range.PublicField(line,"isGuild")~=true and self.Range.PublicField(line,"shouldHide")~=true then
        offset,size=self.Range.PublicField(line,"itemIndexOffset"),self.Range.PublicField(line,"numSpellBookItems")
      end
    else local _,_,o,n=read(GetSpellTabInfo,tab);offset,size=o,n end
    if KHQOL.IsPublicValue(offset) and KHQOL.IsPublicValue(size) and type(offset)=="number" and type(size)=="number"
      and offset>=0 and size>=0 and offset+size<=1024 then
      for index=offset+1,offset+size do
        if modern then
          local info=read(B.GetSpellBookItemInfo,index,bank)
          local kind=self.Range.PublicField(info,"itemType")
          local spellType=Enum and Enum.SpellBookItemType and Enum.SpellBookItemType.Spell
          if kind=="SPELL" or (KHQOL.IsPublicValue(spellType) and spellType~=nil and kind==spellType) then
            if self.Range.PublicField(info,"isPassive")==false then add(self.Range.PublicField(info,"spellID")) end
          end
        else
          local kind,id=read(GetSpellBookItemInfo,index,BOOKTYPE_SPELL or "spell")
          if kind=="SPELL" then add(id) end
        end
      end
    end
  end
  local options={}
  for _,id in ipairs(ids) do
    local item=self:ValidateReferenceSpell(id)
    if item then options[#options+1]={value=id,text=item.name.." ("..id..")",icon=item.icon} end
  end
  table.sort(options,function(a,b) return a.text<b.text end)
  return options
end
function FR:RegisterBookSelection(slot)
  if not validID(self.bookSelected) then
    self.registrationMessage="등록할 주문을 먼저 선택하거나 조회하세요."
    self:RefreshSpellBookPanel();return false
  end
  local ok,message=self:SetReferenceSpell(slot,self.bookSelected)
  self.registrationMessage=message;self:RefreshSpellBookPanel();return ok
end
function FR:RefreshSpellBookPanel(rebuild)
  local p=self.bookPanel;if not p or not p:IsShown() then return end
  if rebuild or not self.bookOptions then self.bookOptions=self:GetBookCandidates() end
  p.selection:Refresh()
  local selected,message=self:ValidateReferenceSpell(self.bookSelected)
  p.selectedName:SetText(selected and selected.name or "주문 선택 또는 SpellID 입력")
  p.icon:SetTexture(selected and selected.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
  p.message:SetText(self.registrationMessage or (self.bookSelected and message) or (#self.bookOptions==0 and "학습한 주문 목록 조회 불가. SpellID 직접 입력을 사용하세요." or "등록할 판정 주문을 선택하세요."))
  for _,slot in ipairs({"melee","ranged"}) do
    local id=self.db and self.db[slot.."SpellID"]
    local name=id and (self.Range:GetSpellInfo(id) or self.db[slot.."SpellName"])
    p[slot.."Info"]:SetText((slot=="melee" and "근거리: " or "원거리: ")..(id and ((name or "조회 불가").." ("..id..")") or "미등록"))
  end
end
function FR:CloseSpellBookPanel()
  if self.bookPanel then
    if KHQOL.UI.openDropdown==self.bookPanel.selection.menu then KHQOL.UI:CloseDropdown() end
    self.bookPanel:Hide();self.bookPanel.input:ClearFocus()
  end
end
function FR:SyncSpellBook(enabled)
  if not self.bookButton then return end
  if enabled==nil then enabled=KHQOL.db and KHQOL:GetEnabled("range") end
  local show=enabled and visible(self.bookHost)
  self.bookButton:SetShown(show and true or false)
  if not show then self:CloseSpellBookPanel() end
end
function FR:TryAttachSpellBook()
  if not self.db or not KHQOL.db or not KHQOL:GetEnabled("range") or not outsideCombat() then return end
  local host=bookHost();if not host then return end
  if host.IsForbidden and read(host.IsForbidden,host)~=false then return end
  local UI=KHQOL.UI
  if not self.bookButton then
    local button=UI:CreateButton(UIParent,"KHQOL",0,0,80,function()
      if FR.bookPanel:IsShown() then FR:CloseSpellBookPanel()
      else FR:OpenSpellBookPanel() end
    end)
    self.bookButton=button;button:SetFrameStrata("DIALOG");button:SetClampedToScreen(true)
    local p=CreateFrame("Frame","KHQOLRangeBookRegistration",UIParent,"BackdropTemplate")
    self.bookPanel=p;p.uiControls={};p:SetSize(310,366);p:SetFrameStrata("DIALOG");p:SetClampedToScreen(true)
    p:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    p:SetBackdropColor(unpack(UI.Theme.Background));p:SetBackdropBorderColor(unpack(UI.Theme.Border))
    UI:CreateLabel(p,"KHQOL 사거리 주문 등록",12,-12):SetWidth(245)
    UI:CreateButton(p,"X",272,-8,26,function() FR:CloseSpellBookPanel() end)
    p.selection=UI:CreateDropdown(p,12,-42,286,function() return FR.bookOptions or {} end,
      function() return FR.bookSelected end,function(id) FR.bookSelected=id;FR.registrationMessage=nil;FR:RefreshSpellBookPanel() end)
    p.icon=p:CreateTexture(nil,"ARTWORK");p.icon:SetSize(30,30);p.icon:SetPoint("TOPLEFT",12,-84)
    p.selectedName=UI:CreateDescription(p,"",50,-84);p.selectedName:SetWidth(248)
    p.input=UI:CreateEditBox(p,12,-128,190)
    UI:CreateButton(p,"조회",214,-128,84,function()
      local item,message=FR:ValidateReferenceSpell(p.input:GetText())
      FR.bookSelected=item and item.id or nil;FR.registrationMessage=message;FR:RefreshSpellBookPanel()
    end)
    UI:CreateButton(p,"근거리로 등록",12,-171,137,function() FR:RegisterBookSelection("melee") end)
    UI:CreateButton(p,"원거리로 등록",161,-171,137,function() FR:RegisterBookSelection("ranged") end)
    p.meleeInfo=UI:CreateDescription(p,"",12,-216);p.meleeInfo:SetWidth(286)
    p.rangedInfo=UI:CreateDescription(p,"",12,-253);p.rangedInfo:SetWidth(286)
    p.message=UI:CreateDescription(p,"",12,-296);p.message:SetWidth(286)
    p:SetScript("OnHide",function() p.input:ClearFocus();if UI.openDropdown==p.selection.menu then UI:CloseDropdown() end end)
    p:Hide();button:Hide()
  end
  self.bookHost=host
  self.bookButton:ClearAllPoints();self.bookButton:SetPoint("TOPLEFT",host,"TOPRIGHT",6,-30)
  self.bookPanel:ClearAllPoints();self.bookPanel:SetPoint("TOPLEFT",self.bookButton,"BOTTOMLEFT",0,-6)
  self.bookHooked=self.bookHooked or {}
  if not self.bookHooked[host] then
    self.bookHooked[host]=true
    host:HookScript("OnShow",function() FR:CloseSpellBookPanel();FR:TryAttachSpellBook();FR:SyncSpellBook() end)
    host:HookScript("OnHide",function() FR:CloseSpellBookPanel();FR:SyncSpellBook() end)
    local parent=PlayerSpellsFrame
    if parent and parent~=host and not self.bookHooked[parent] then
      self.bookHooked[parent]=true
      parent:HookScript("OnShow",function() FR:CloseSpellBookPanel();FR:TryAttachSpellBook();FR:SyncSpellBook() end)
      parent:HookScript("OnHide",function() FR:CloseSpellBookPanel();FR:SyncSpellBook(false) end)
    end
  end
  self:SyncSpellBook()
end
function FR:OpenSpellBookPanel()
  if not KHQOL.db or not KHQOL:GetEnabled("range") then return false end
  if not outsideCombat() then self:Print("전투 종료 후 스킬북 등록창을 여세요.");return false end
  local host=bookHost()
  if not visible(host) then
    -- Use a public opener only; never force-show/reparent the native book frame.
    if PlayerSpellsUtil and type(PlayerSpellsUtil.OpenToSpellBookTab)=="function" then pcall(PlayerSpellsUtil.OpenToSpellBookTab)
    elseif type(ToggleSpellBook)=="function" then pcall(ToggleSpellBook,BOOKTYPE_SPELL or "spell")
    elseif type(TogglePlayerSpellsFrame)=="function" then pcall(TogglePlayerSpellsFrame) end
  end
  self:TryAttachSpellBook()
  if not self.bookPanel or not visible(self.bookHost) then self:Print("게임 스킬북을 연 뒤 옆의 KHQOL 버튼을 누르세요.");return false end
  self.registrationMessage=nil;self.bookPanel:Show();KHQOL.UI:Refresh(self.bookPanel);self:RefreshSpellBookPanel(true)
  return true
end
