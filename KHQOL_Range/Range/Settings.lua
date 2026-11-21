local _, KHQOL = ...
KHQOL = assert(_G.KHQOL, "Install and enable the KHQOL core addon.")
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
  b:Section("표시 방식")
  b:Dropdown("표시 방식",{{value="skills",text="스킬 유효 거리"},{value="distance",text="대상 거리"}},
    function() return FR.db.displayMode end,function(mode) FR:SetDisplayMode(mode) end)
  b:Flush()
  local distance=CreateFrame("Frame",nil,panel)
  distance:SetWidth(panel:GetWidth());distance.settingsRoute={module="range",section="대상 거리"}
  FR.Distance:BuildSettings(distance)
  b:Block(distance,function() distance.uiBuilder:Reflow();return distance:GetHeight() end,
    function() return FR.db.displayMode=="distance" or FR.db.mouseover.mode=="distance" end)
  local function skillsMode() return FR.db.displayMode=="skills" end
  b:Section("사거리 기준 주문")
  local function spellField(title,getter,setter)
    local x,y,width=b:Cell("spell",2,104)
    UI:CreateLabel(panel,title,x,y):SetWidth(width)
    local input=UI:CreateEditBox(panel,x,y-24,width-88,getter,nil,skillsMode)
    input:SetScript("OnEnterPressed",function(self) if skillsMode() then setter(self:GetText()) end;self:ClearFocus();self:Refresh() end)
    local apply=UI:CreateButton(panel,"적용",x+width-72,y-24,72,function() if skillsMode() then setter(input:GetText()) end;input:ClearFocus() end,skillsMode)
    input.applyButton=apply
    local info=UI:CreateDescription(panel,"",x,y-62); info:SetWidth(width)
    return input,info
  end
  self.meleeSpell,self.meleeInfo=spellField("근거리 판정 주문",function() return FR.db.meleeSpellID or FR.db.hunterMeleeSpellID or "" end,function(v) FR:SetMeleeSpell(v) end)
  self.rangeSpell,self.rangeInfo=spellField("원거리 판정 주문",function() return FR.db.rangedSpellID or FR.db.rangeSpellID or "" end,function(v) FR:SetRangeSpell(v) end)
  b:Flush()
  self.bookRegister=b:Button("스킬북에서 등록",function() FR:OpenSpellBookPanel() end,180,skillsMode)
  self.registrationResult=b:Description("",true)
  b.cells[#b.cells].visible=function() return FR.registrationMessage~=nil and FR.registrationMessage~="" end
  local weaponStart=#b.cells+1
  do
    b:Section("원거리 무기 판정")
    b:Checkbox("근거리 공격도 가능으로 판정",function() return FR.db.hunterMeleeAsAttack end,function(v) FR.db.hunterMeleeAsAttack=v; FR:RefreshDisplay(true) end)
    b:Checkbox("데드존 감지 사용",function() return FR.db.deadZoneEnabled end,function(v) FR.db.deadZoneEnabled=v; FR:RefreshDisplay(true) end)
  end
  for i=weaponStart,#b.cells do b.cells[i].visible=function() return FR.Range:UsesRangedWeapon()==true end end
  b:Section("마우스오버 거리 측정")
  local function mouseoverEnabled() return FR.db.mouseover.enabled end
  local function refreshMouseover() FR:RefreshDisplay();FR:SyncUpdates();FR:UpdateSettings() end
  b:Checkbox("마우스오버 거리 측정 사용",function() return FR.db.mouseover.enabled end,function(v) FR.db.mouseover.enabled=v; refreshMouseover() end)
  b:Dropdown("마우스오버 표시 방식",{{value="skills",text="텍스트 표시"},{value="distance",text="숫자 표시"}},
    function() return FR.db.mouseover.mode end,function(v) FR.db.mouseover.mode=v;refreshMouseover() end,mouseoverEnabled)
  b:Flush()
  local px,py,pw=b:Cell("dropdown",2,UI.Theme.DropdownRowHeight)
  local positionLabel=UI:CreateLabel(panel,"표시 위치",px,py);positionLabel:SetWidth(pw)
  local position=UI:CreateDropdown(panel,px,py-24,pw,{{value="BELOW",text="툴팁 아래"},{value="LEFT",text="툴팁 왼쪽"},{value="CURSOR",text="커서 옆"}},function() return FR.db.mouseover.position end,function(v) FR.db.mouseover.position=v; refreshMouseover() end,mouseoverEnabled)
  position.uiLabels={positionLabel};position:Refresh()
  local rx,ry=b:Cell("dropdown",2,UI.Theme.DropdownRowHeight)
  local reset=UI:CreateButton(panel,"마우스오버 위치 초기화",rx,ry-24,180,function() FR.db.mouseover.x,FR.db.mouseover.y=0,0;refreshMouseover() end,mouseoverEnabled)
  local x=b:Slider("X 위치 보정",-100,200,1,function() return FR.db.mouseover.x end,function(v) FR.db.mouseover.x=v; refreshMouseover() end,nil,mouseoverEnabled)
  local y=b:Slider("Y 위치 보정",-100,100,1,function() return FR.db.mouseover.y end,function(v) FR.db.mouseover.y=v; refreshMouseover() end,nil,mouseoverEnabled)
  local function textEnabled() return mouseoverEnabled() and FR.db.mouseover.mode~="distance" end
  local messages={}
  for index,entry in ipairs({{"availableText","공격가능 문구"},{"unavailableText","공격불가 문구"}}) do
    local key,title=entry[1],entry[2]
    local input=b:Edit(title,function() return FR.db.mouseover[key] end,function(v)
      v=v:gsub("^%s+",""):gsub("%s+$","")
      FR.db.mouseover[key]=FR:LimitMouseoverText(v~="" and v or FR.defaults.mouseover[key]);refreshMouseover()
    end,textEnabled)
    input:SetMaxLetters(8);messages[index]=input
  end
  local font=b:Slider("글자 크기",10,40,1,function() return FR.db.mouseover.fontSize end,function(v) FR.db.mouseover.fontSize=v;refreshMouseover() end,function(v) return v.." px" end,mouseoverEnabled)
  self.mouseoverControls={position=position,reset=reset,x=x,y=y,font=font,available=messages[1],unavailable=messages[2]}
  local legacyStart=#b.cells+1
  b:Section("위치")
  b:PositionLock("위치 잠금",function() return FR.db.locked end,function(v) FR:ToggleLock(v) end)
  b:Slider("X 위치",-1000,1000,1,function() return FR.db.x end,function(v) FR:SetNumber("x",v,-1000,1000) end)
  b:Slider("Y 위치",-1000,1000,1,function() return FR.db.y end,function(v) FR:SetNumber("y",v,-1000,1000) end)
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
  self.shape=b:Edit("특수 문자",function() return FR.db.shape end,function(v)
    FR.db.shape=v~="" and v or "\226\150\160"; FR:RefreshDisplay(true)
  end,function() return not stateTextEnabled() end)
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
  for i=legacyStart,#b.cells do b.cells[i].visible=function() return FR.db.displayMode=="skills" end end
  b:BeginDisclosure("고급 / 확인","range-diagnostics",2)
  b:Button("표시 테스트",function() FR:CycleTest() end,nil,function() return FR.db.displayMode=="skills" end)
  local api=b:Button("API 상태",function() FR.Range:DescribeAPI() end)
  b:EndDisclosure();b:Reflow()
  panel:SetHeight(-(b.reflowBottom or b.y)); panel:HookScript("OnShow",function() FR:UpdateSettings() end)
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
      label:SetText(id and ((name or "조회 불가").." ("..id..")") or "미등록")
    end
    if Settings.registrationResult then Settings.registrationResult:SetText(self.registrationMessage or "") end
    self.Distance:UpdateMeasurementLabel(self.distanceState)
    UI:Refresh(Settings.panel)
    local builder=Settings.panel.uiBuilder
    if builder then builder:Reflow();Settings.panel:SetHeight(-(builder.reflowBottom or builder.y)) end
  end
  if self.RefreshSpellBookPanel then self:RefreshSpellBookPanel() end
end
function FR:OpenSettings() KHQOL:ShowSettings("range") end

local function read(fn,...) return KHQOL.PublicCall(fn,...) end
local function validID(id) return KHQOL.IsPublicValue(id) and type(id)=="number" and id>0 and id<2147483648 and id==math.floor(id) end
local layers=KHQOL.WindowLayers
local function outsideCombat() return layers:OutsideCombat() end
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
  if p.wheelBody then KHQOL.modules.partyFrames:RefreshBookWheel() end
  if rebuild or not self.bookOptions then self.bookOptions=self:GetBookCandidates() end
  p.selection:Refresh()
  p.meleeButton:Refresh();p.rangedButton:Refresh()
  local selected,message=self:ValidateReferenceSpell(self.bookSelected)
  p.selectedName:SetText(selected and selected.name or "스킬명 또는 SpellID 입력")
  p.icon:SetTexture(selected and selected.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
  p.message:SetText(self.registrationMessage or (self.bookSelected and message) or "")
  if not KHQOL:GetEnabled("range") then p.message:SetText("사거리 모듈을 켠 후 기준 주문을 등록하세요.")
  elseif self.db.displayMode~="skills" then p.message:SetText("스킬 유효 거리 모드에서 기준 주문을 등록하세요.") end
  for _,slot in ipairs({"melee","ranged"}) do
    local id=self.db and self.db[slot.."SpellID"]
    local name=id and (self.Range:GetSpellInfo(id) or self.db[slot.."SpellName"])
    p[slot.."Info"]:SetText((slot=="melee" and "근거리: " or "원거리: ")..(id and ((name or "조회 불가").." ("..id..")") or "미등록"))
  end
  if p.ReflowBook then p:ReflowBook() end
end
function FR:CloseSpellBookPanel()
  if self.bookPanel then
    local menu=KHQOL.UI.openDropdown;local wheel=self.bookPanel.wheelBody
    if menu and (menu==self.bookPanel.selection.menu or wheel and wheel.modifier and menu==wheel.modifier.menu) then KHQOL.UI:CloseDropdown() end
    self.bookPanel:Hide();self.bookPanel.input:ClearFocus()
  end
end
function FR:SyncSpellBook()
  if not self.bookButton then return false end
  local show=layers:PlaceOnSpellBook(self.bookButton,self.bookHost,self.bookRoot,20)
    and layers:PlaceOnSpellBook(self.bookPanel,self.bookHost,self.bookRoot,30)
  self.bookButton:SetShown(show)
  if not show then self:CloseSpellBookPanel() end
  return show
end
function FR:TryAttachSpellBook()
  if not self.db or not KHQOL.db or not outsideCombat() then return end
  local host,root=layers:SpellBook()
  if not host then self:CloseSpellBookPanel();if self.bookButton then self.bookButton:Hide() end;return end
  local UI=KHQOL.UI
  if not self.bookButton then
    local button=UI:CreateButton(UIParent,"KHQOL 스킬 설정",0,0,144,function()
      if FR.bookPanel:IsShown() then FR:CloseSpellBookPanel()
      else FR:OpenSpellBookPanel() end
    end)
    self.bookButton=button;button:SetSize(144,28);button:SetFrameStrata("DIALOG");button:SetClampedToScreen(true)
    local p=CreateFrame("Frame","KHQOLRangeBookRegistration",UIParent,"BackdropTemplate")
    self.bookPanel=p;p.uiControls={};p.khqolSpellBookPanel=true;p:SetSize(310,412);p:SetFrameStrata("DIALOG");p:SetClampedToScreen(true)
    p:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    p:SetBackdropColor(unpack(UI.Theme.Background));p:SetBackdropBorderColor(unpack(UI.Theme.Border))
    p.title=UI:CreateLabel(p,"KHQOL 스킬 설정",12,-12);p.title:SetWidth(245)
    UI:CreateButton(p,"X",272,-8,26,function() FR:CloseSpellBookPanel() end)
    p.rangeBody=CreateFrame("Frame",nil,p);p.rangeBody:SetSize(310,366)
    local party=KHQOL.modules.partyFrames
    local kinds={"range"}
    if KHQOL.ModuleRegistry.entries.partyFrames and party and party.BuildBookWheel then
      p.wheelBody=CreateFrame("Frame",nil,p);p.wheelBody:SetSize(310,326);p.wheelBody:Hide()
      p.rangeTab=UI:CreateButton(p,"사거리 설정",12,-42,143,function() FR:SelectBookTab("range") end)
      p.wheelTab=UI:CreateButton(p,"휠 클릭 시전",155,-42,143,function() FR:SelectBookTab("wheel") end)
      p.rangeTab:SetSize(143,UI.Theme.ButtonHeight);p.wheelTab:SetSize(143,UI.Theme.ButtonHeight)
      p.wheelTab:ClearAllPoints();p.wheelTab:SetPoint("LEFT",p.rangeTab,"RIGHT",0,0)
      party:BuildBookWheel(p.wheelBody)
      kinds[2]="wheel"
    end
    local body=p.rangeBody
    p.selection=UI:CreateDropdown(body,12,-42,286,function() return FR.bookOptions or {} end,
      function() return FR.bookSelected end,function(id) FR.bookSelected=id;FR.registrationMessage=nil;FR:RefreshSpellBookPanel() end)
    p.icon=body:CreateTexture(nil,"ARTWORK");p.icon:SetSize(30,30);p.icon:SetPoint("TOPLEFT",12,-84)
    p.selectedName=UI:CreateDescription(body,"",50,-84);p.selectedName:SetWidth(248)
    p.input=UI:CreateEditBox(body,12,-128,190)
    p.lookup=UI:CreateButton(body,"조회",214,-128,84,function()
      local item,message=FR:ValidateReferenceSpell(p.input:GetText())
      FR.bookSelected=item and item.id or nil;FR.registrationMessage=message;FR:RefreshSpellBookPanel()
    end)
    for _,entry in ipairs({{"melee","근거리로 등록",12},{"ranged","원거리로 등록",161}}) do
      local slot=entry[1]
      local button=UI:CreateButton(body,entry[2],entry[3],-171,137,function()
        if read(GetCursorInfo)~=nil then FR:ReceiveBookSpell(slot) else FR:RegisterBookSelection(slot) end
      end,function() return KHQOL:GetEnabled("range") and FR.db.displayMode=="skills" and outsideCombat() end)
      p[slot.."Button"]=button
      button:SetScript("OnReceiveDrag",function() FR:ReceiveBookSpell(slot) end)
    end
    p.meleeInfo=UI:CreateDescription(body,"",12,-216);p.meleeInfo:SetWidth(286)
    p.rangedInfo=UI:CreateDescription(body,"",12,-253);p.rangedInfo:SetWidth(286)
    p.message=UI:CreateDescription(body,"",12,-296);p.message:SetWidth(286)
    for _,kind in ipairs(kinds) do
      local child=p[kind.."Body"]
      local view=CreateFrame("ScrollFrame",nil,p)
      view:SetPoint("TOPLEFT",0,p.wheelBody and -80 or -42);view:SetPoint("BOTTOMRIGHT",0,8)
      child:SetParent(view);child:ClearAllPoints();child:SetPoint("TOPLEFT",0,0);view:SetScrollChild(child)
      p[kind.."Viewport"]=view;view:EnableMouseWheel(true)
      view:SetScript("OnMouseWheel",function(_,delta)
        UI:CloseDropdown();view:SetVerticalScroll(math.max(0,math.min(math.max(0,child:GetHeight()-view:GetHeight()),view:GetVerticalScroll()-delta*34)))
      end)
    end
    function p:ReflowBook()
      local top=-8
      local function place(control,x,y) control:ClearAllPoints();control:SetPoint("TOPLEFT",x,y) end
      place(self.selection,12,top);top=top-self.selection:GetHeight()-12
      place(self.icon,12,top);place(self.selectedName,50,top)
      top=top-math.max(30,self.selectedName:GetStringHeight())-12
      place(self.input,12,top);place(self.lookup,214,top);top=top-40
      place(self.meleeButton,12,top);place(self.rangedButton,161,top);top=top-40
      for _,label in ipairs({self.meleeInfo,self.rangedInfo,self.message}) do
        label:SetWidth(286);place(label,12,top);top=top-math.max(18,label:GetStringHeight())-10
      end
      self.rangeBody:SetHeight(math.max(326,-top+8))
      local view=self.rangeViewport
      view:SetVerticalScroll(math.min(view:GetVerticalScroll(),math.max(0,self.rangeBody:GetHeight()-view:GetHeight())))
    end
    p:SetScript("OnHide",function()
      p.input:ClearFocus();local menu=UI.openDropdown
      if menu and (menu==p.selection.menu or p.wheelBody and menu==p.wheelBody.modifier.menu) then UI:CloseDropdown() end
    end)
    p:Hide();button:Hide()
  end
  if self.bookHost~=host or self.bookRoot~=root then
    self:CloseSpellBookPanel();self.bookHost,self.bookRoot=host,root
    self.bookButton:ClearAllPoints()
    local search=read(function() return host.SearchBox end)
    if layers:Readable(search) then self.bookButton:SetPoint("TOPRIGHT",search,"BOTTOMRIGHT",0,-10)
    else self.bookButton:SetPoint("TOPRIGHT",host,"TOPRIGHT",-30,-80) end
    self.bookPanel:ClearAllPoints();self.bookPanel:SetPoint("TOPLEFT",host,"TOPRIGHT",8,-80)
    layers:WatchSpellBook(self,host,root,function() self:CloseSpellBookPanel();self:SyncSpellBook() end)
  end
  self:SyncSpellBook()
end
function FR:SelectBookTab(tab)
  local p=self.bookPanel;if not p then return end
  self.bookTab=tab=="wheel" and p.wheelBody and "wheel" or "range"
  KHQOL.UI:CloseDropdown();p.input:ClearFocus()
  local range=self.bookTab=="range"
  p.rangeBody:SetShown(range);p.rangeViewport:SetShown(range)
  if p.wheelBody then
    p.wheelBody:SetShown(not range);p.wheelViewport:SetShown(not range)
    KHQOL.UI:SetButtonSelected(p.rangeTab,range);KHQOL.UI:SetButtonSelected(p.wheelTab,not range)
  end
  KHQOL.UI:Refresh(p);self:RefreshSpellBookPanel()
end
function FR:OpenSpellBookPanel(tab)
  if not KHQOL.db or not self.db then return false end
  local party=KHQOL.modules.partyFrames
  if tab=="wheel" and (not KHQOL.ModuleRegistry.entries.partyFrames or not party or not party.BuildBookWheel) then return false end
  if not outsideCombat() then self:Print("전투 종료 후 스킬북 등록창을 여세요.");return false end
  layers:OpenSpellBook()
  self:TryAttachSpellBook()
  if not self:SyncSpellBook() then self:Print("게임 스킬북을 연 뒤 옆의 KHQOL 버튼을 누르세요.");return false end
  self.registrationMessage=nil;self.bookPanel:Show();self:SelectBookTab(tab or "range");KHQOL.UI:Refresh(self.bookPanel);self:RefreshSpellBookPanel(true)
  return true
end
