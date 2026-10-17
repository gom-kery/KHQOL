local _,K=...
local UI,T=K.UI,K.UI.Theme
local R=UI.SettingsRegistry
local N={items={},controls=setmetatable({}, {__mode="k"}),serial=0}
UI.SettingsNavigation=N
N.units={player="플레이어",target="대상",pet="소환수",targettarget="대상의 대상",focus="주시대상"}
N.parts={basic="기본",bars="체력·자원",labels="이름·레벨",status="상태·징표",auras="버프·디버프",class="직업 표시"}
function N:Preferences()
  K.db.toolWindows=K.db.toolWindows or {}
  K.db.toolWindows.preferences=K.db.toolWindows.preferences or {}
  return K.db.toolWindows.preferences
end
local function token(text) return (text or ""):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r",""):lower():gsub("%s+"," ") end
function N:ID(p,title) return table.concat({p.module or "general",p.tab or "",p.castUnit or "",p.unit or "",p.part or "",p.category or "",p.section or "",title or ""},"/") end
function N:Path(p,title)
  local meta=p.tab and R.groups.quest[p.tab] and p.module=="questNavigator" and R.groups.quest[p.tab] or R.modules[p.module] or R.routes[p.module]
  if p.tab and meta and meta.group and R.groups[meta.group] and R.groups[meta.group][p.tab] and R.groups[meta.group][p.tab].key==meta.key then meta=R.groups[meta.group][p.tab] end
  local page=p.page or meta and meta.group or "general";local name=page
  for _,v in ipairs(R.pages) do if v[1]==page then name=v[2];break end end
  local path={name}
  local titleText=meta and (meta.tabTitle or meta.title)
  if meta and page~="unitFrames" and (titleText~=name or p.tab and meta.sharedTabs) then path[#path+1]=titleText end
  if p.castUnit then path[#path+1]=self.units[p.castUnit] or p.castUnit end
  if p.unit then path[#path+1]=self.units[p.unit] or p.unit end
  if p.part then path[#path+1]=self.parts[p.part] or p.part end
  if p.category then path[#path+1]=p.category=="attackableNPC" and "공격 가능한 NPC" or "아군 플레이어" end
  if p.section and p.section~="" and p.section~=title then path[#path+1]=p.section end
  if title then path[#path+1]=title end
  return table.concat(path," > ")
end
function N:Scope(p,title)
  if p.scope and p.scope~="현재 프로필" then return p.scope end
  if p.module=="frameInspector" then return "세션 검사 · 페이지 종료 시 정지" end
  if p.module=="performanceMonitor" and p.section=="측정 로그" then return "세션 로그 · /reload 때 비움" end
  if p.module=="profiles" then return "계정 공용 프로필 · 캐릭터별 선택" end
  if p.module=="npcAlert" and (p.section=="등록된 위험 NPC" or p.section=="NPC 정보") then return "계정 공용 등록 목록" end
  if p.module=="procAlert" and (p.section=="등록된 버프" or p.section=="버프 정보") then return "계정 공용 등록 목록" end
  if p.module=="buffReminder" and (p.section=="버프 등록" or p.section=="등록한 버프") then return "계정 공용 직업별 등록 목록" end
  if p.module=="partyFrames" then return "계정 공용 프레임 프로필" end
  if p.module=="cursorTrail" and title=="색상" or p.module=="resourceSwing" and title=="자원 색상" then return "캐릭터 색 · 전체 프로필에도 캡처/적용" end
  return "현재 전체 프로필"
end
function N:ScrollID(route)
  local p={};for key,value in pairs(route or {}) do if key~="section" then p[key]=value end end
  return self:ID(p,"@scroll")
end
function N:RememberScroll(s)
  if not s or s.routeChanging or not s.scroll or not s.currentRoute then return end
  self.scrollPositions=self.scrollPositions or {}
  self.scrollPositions[self:ScrollID(s.currentRoute)]=s.scroll:GetVerticalScroll()
end
function N:RestoreScroll(s,route)
  if not s or s.routeChanging or not s.scroll then return end
  local value=(self.scrollPositions or {})[self:ScrollID(route or s.currentRoute)] or 0
  s:UpdateContentHeight()
  s.scroll:SetVerticalScroll(math.max(0,math.min(value,math.max(0,s.child:GetHeight()-s.scroll:GetHeight()))))
end
function N:Register(p,title,description,aliases)
  if not title or title=="" then return end
  local id=p.id or self:ID(p,title);local item=self.items[id]
  if not item then item={id=id,route=p,title=title};self.items[id]=item end
  item.description=description or item.description or "";item.aliases=aliases or item.aliases or ""
  item.path=self:Path(p,title);item.scope=self:Scope(p,title)
  item.words=token(item.path.." "..item.description.." "..item.aliases.." "..(p.module or ""))
  return item
end
function N:Context(parent)
  local current=parent
  for _=1,64 do
    if not current or current==UIParent then break end
    if current.settingsNoIndex then return end
    if current.settingsRoute then return current.settingsRoute end
    if current.settingsModuleKey then return {module=current.settingsModuleKey} end
    current=current:GetParent()
  end
end
function N:Attach(parent,control,title,get,set,enabled,description)
  local route=self:Context(parent);if not route or not title or title=="" then return end
  local p={};for key,value in pairs(route) do p[key]=value end
  if p.module=="range" and (title:find("판정 주문",1,true) or title:find("스킬북에서 등록",1,true)) then p.scope="캐릭터별" end
  if parent.khqolSection then p.section=parent.khqolSection end
  local item=self:Register(p,title,description)
  item.control=control;item.read=get;item.write=set;item.available=enabled
  if UI.SettingsRegistry.positionModules[p.module] then item.aliases=(item.aliases or "").." "..p.module end
  control.settingsItemID=item.id;control.settingsRoute=p;self.controls[control]=item
  UI:AttachTooltip(control,title,"저장: "..item.scope)
end
function N:Status(item)
  local p=item.route;local key=p.module
  if key and K.LabLock:IsExperimental(key) and not K.LabLock:IsUnlocked() then return "실험실 잠금" end
  local stateModule=key and K.modules[key]
  if key=="partyFrames" and stateModule and stateModule.Status and (stateModule.pending or stateModule.failure) then return stateModule:Status() end
  if (key=="unitFrames" or key=="basicUI") and stateModule and stateModule.pending==true then return "변경 보류 · 전투 종료 후 적용" end
  if key=="castBar" and stateModule and (stateModule.targetPending or stateModule.targetStylePending or stateModule.blizzardPending) then return stateModule.targetPositionReason or "변경 보류 · 안전한 시점에 적용" end
  if key and K.db.enabled[key]~=nil and not K:GetEnabled(key) and not (key=="basicUI" and item.scope=="계정 공용") then return "모듈 OFF" end
  if key=="unitFrames" then
    local m=K.modules.unitFrames
    if item.title:find("기력 회복",1,true) then return "지원 보류" end
    local parts=p.unit and m:UnitParts(p.unit)
    if p.unit and not parts then return "현재 유닛 부품 없음" end
    if parts and item.title:find("레벨",1,true) and not parts.level then return "기본 레벨 부품 없음" end
    if p.part=="auras" and p.unit=="player" then
      local kind=item.title:find("디버프",1,true) and "debuffs" or "buffs"
      if not m:PlayerAuraFrame(kind) then return "기본 오라 API 미지원" end
    end
    if m.pending then return "전투 종료 후 적용" end
  end
  local m=key and K.modules[key]
  if key=="partyFrames" and m and m.Status then return m:Status() end
  if key=="basicUI" and m and m.pending==true then return "저장됨 · 전투 종료 후 적용" end
  if key=="castBar" and m and (m.targetPending or m.targetStylePending or m.blizzardPending) then return m.targetPositionReason or "저장됨 · 안전한 시점에 적용 보류" end
  if item.control and not UI:IsAvailable(item.control,item.available) then return "연결된 기능·표시 조건 확인" end
  return item.scope
end
local aliases={
  ["크기"]="size font",["레벨"]="level",["이름"]="name",["위치"]="position anchor move",["체력"]="health hp",["색상"]="color colour",
  ["버프"]="buff aura",["디버프"]="debuff aura",["토템"]="totem",["시계"]="clock time",["수리"]="repair",["퀘스트"]="quest",["폭"]="width",
}
function N:Search(query)
  query=token(query);local found={};if query=="" then return found end
  for _,item in pairs(self.items) do
    local words=item.words
    for ko,en in pairs(aliases) do if words:find(ko,1,true) then words=words.." "..en end end
    local match=true
    for word in query:gmatch("%S+") do if not words:find(word,1,true) then match=false;break end end
    if match then found[#found+1]=item end
  end
  table.sort(found,function(a,b) return a.path<b.path end)
  return found
end
function N:CancelSearch(settings)
  self.serial=self.serial+1
  if settings and settings.searchResults then settings.searchResults:Hide() end
  if self.highlight then self.highlight:Hide() end
end
function N:Open(route,itemID,restoreOnly)
  if type(route)=="string" then route={module=route} end
  route=route or {module="general"}
  if K.PositionEditor and K.PositionEditor.active then return false end
  local s=K.settings;if not s then return false end
  self:CancelSearch(s);s:Show();s:ShowPage(route.module or route.page or "general")
  local content=s.activeContent
  if route.tab and content and content.SelectSettingsTab then content.SelectSettingsTab(route.tab) end
  if route.module=="castBar" then
    local cast=content and content.tabPanels and content.tabPanels.cast
    if cast and cast.SelectCastUnit then cast:SelectCastUnit(route.castUnit or cast.selectedCastUnit) end
  end
  local panel=content and content.tabPanels and content.tabPanels.units
  if route.module=="unitFrames" and panel and panel.SelectUnitPart then
    panel:SelectUnitPart(route.unit,route.part,route.category)
    s.pageTitle:SetText(self:Path({module="unitFrames",unit=panel.selectedUnit,part=panel.selectedPart}))
  end
  s:RefreshActivePage()
  if route.module=="clock" and route.sideTarget then
    local p=content and content.tabPanels and content.tabPanels.clock
    if p then p.sideTargetKey=route.sideTarget;K.modules.clock:RefreshSettings() end
  end
  local function belongs(control)
    local p=control
    for _=1,64 do if p==content then return true end;if not p or p==UIParent then return false end;p=p:GetParent() end
  end
  local item=itemID and self.items[itemID];local control=item and item.control
  if not control or not belongs(control) then
    for c,entry in pairs(self.controls) do
      if belongs(c) and ((itemID and entry.id==itemID) or (not restoreOnly and not itemID and route.section and entry.route.module==route.module and entry.route.section==route.section)) then
        item=entry;control=c;break
      end
    end
  end
  if control then
    local p=control
    for _=1,64 do
      if not p or p==UIParent then break end
      if p.settingsDisclosure then p.settingsDisclosure:Expand() end
      p=p:GetParent()
    end
    s:RefreshActivePage();s:Reflow()
  end
  local serial=self.serial;local generation=K.profileGeneration
  local function focus()
    if N.serial~=serial or K.profileGeneration~=generation or s.activeContent~=content or not s:IsShown() then return end
    s:RefreshActivePage()
    if s.scroll.UpdateScrollChildRect then s.scroll:UpdateScrollChildRect() end
    if control and control:IsVisible() then
      local top,bottom=s.child:GetTop(),control:GetTop()
      if top and bottom then
        s.scroll:SetVerticalScroll(math.max(0,math.min(math.max(0,s.child:GetHeight()-s.scroll:GetHeight()),top-bottom-12)))
      end
      local h=N.highlight
      if not h then h=CreateFrame("Frame",nil,s,"BackdropTemplate");UI:Surface(h,0);h:EnableMouse(false);N.highlight=h end
      h:SetParent(control);h:ClearAllPoints();h:SetPoint("TOPLEFT",-4,4);h:SetPoint("BOTTOMRIGHT",4,-4)
      h:SetFrameLevel(control:GetFrameLevel()+8);h:SetBackdropBorderColor(unpack(T.FocusAccent));h:Show()
      if C_Timer and C_Timer.After then C_Timer.After(1.4,function()
        if N.serial==serial and K.profileGeneration==generation then h:Hide() end
      end) end
    elseif not itemID then N:RestoreScroll(s,route) end
  end
  if C_Timer and C_Timer.After then C_Timer.After(0,focus) else focus() end
  s.currentRoute=route
  return true
end
-- IDs are explicit for unit parts; all other registered editor IDs use their
-- module route. No translated display-name parsing is used for navigation.
function N:EditorRoute(t)
  if t.settingsRoute then return t.settingsRoute end
  local id=t.id or "";local u,part=id:match("^unitFrames%.([^%.]+)%.([^%.]+)")
  if id=="unitFrames.targettarget" then u="targettarget";part="basic" end
  if u then
    local parts={name="labels",level="labels",status="status",rest="status",combat="status",marker="status",monster="status",buffs="auras",debuffs="auras",auras="auras",totems="class",basic="basic"}
    return {module="unitFrames",unit=u,part=parts[part] or "basic",category=id:match("%.auras%.([^%.]+)")}
  end
  if id=="settings.window" then return {module="general"} end
  local sections={clock="시간 글자·모양",["clock.professions"]="전문기술",["clock.professions.panel"]="전문기술",
    ["clock.alert"]="알람·타이머·스톱워치",["clock.tools"]="알람·타이머·스톱워치",["clock.stopwatch"]="알람·타이머·스톱워치",
    range="위치",["range.mouseover"]="마우스오버 거리 측정",["tooltip.position"]="배치 방식",
    resource="위치",ammo="탄약 / 영혼의 조각 위치",["resource.combo"]="콤보 포인트",cast="위치",["cast.target"]="대상 시전바 위치"}
  if sections[id] then return {module=t.settingsKey or t.key,section=sections[id],castUnit=id=="cast.target" and "target" or id=="cast" and "player" or nil} end
  local sides={ ["clock.date"]="date",["clock.weekday"]="weekday",["clock.money"]="money",["clock.performance"]="performance"}
  if sides[id] then return {module="clock",section="사이드 텍스트",sideTarget=sides[id]} end
  if t.key=="questNavigator" then return {module="questNavigator",tab="navigation"} end
  return {module=t.settingsKey or t.key or "general"}
end
function N:EditorMeta(t)
  t.settingsRoute=self:EditorRoute(t)
  local p=t.settingsRoute;local meta=R.modules[p.module]
  t.category=p.module=="unitFrames" and "유닛프레임" or meta and self:Path({page=meta.group}) or "기본창·도구창"
  t.group=p.unit and self.units[p.unit] or meta and meta.title or "도구창"
  t.groupID=(p.module or "general").."/"..(p.unit or "")
  t.largeWindow=t.id=="settings.window" or t.id:match("^basicUI%.")~=nil or t.id=="note" or t.id=="clock.tools" or t.id=="clock.professions.panel"
  t.representative=t.representative or not t.largeWindow and (p.module~="unitFrames" and not t.parentID or t.id=="unitFrames.targettarget")
  return t
end
function N:BuildSearch(s,x,y,width)
  local box=UI:CreateEditBox(s,x,y,width,nil,nil);box:SetMaxLetters(80)
  UI:AttachTooltip(box,"설정 검색","설정 이름·설명·별칭 검색. 예: 레벨 크기, 이름 위치, 자동 수리, quest width. 결과 선택으로 해당 항목에 이동합니다.")
  local pane=CreateFrame("Frame",nil,s,"BackdropTemplate");pane:SetFrameStrata("FULLSCREEN_DIALOG");pane:SetClampedToScreen(true);UI:Surface(pane,.98)
  pane:SetPoint("TOPLEFT",box,"BOTTOMLEFT",0,-4);pane:SetWidth(width);pane:Hide();s.searchResults=pane;s.searchBox=box
  local viewport=CreateFrame("ScrollFrame",nil,pane);viewport:SetPoint("TOPLEFT",6,-6);viewport:SetPoint("BOTTOMRIGHT",-6,6)
  local list=CreateFrame("Frame",nil,viewport);viewport:SetScrollChild(list);local rows={}
  viewport:EnableMouseWheel(true);viewport:SetScript("OnMouseWheel",function(_,delta)
    viewport:SetVerticalScroll(math.max(0,math.min(math.max(0,list:GetHeight()-viewport:GetHeight()),viewport:GetVerticalScroll()-delta*48)))
  end)
  local function changed()
    N:CancelSearch(s);if not s:IsShown() then return end
    local results=N:Search(box:GetText());if box:GetText()=="" then return end
    local width=math.max(260,math.min(680,s:GetWidth()-T.SidebarWidth-50));pane:SetWidth(width);list:SetWidth(width-12)
    local serial=N.serial;local generation=K.profileGeneration
    local listHeight=0
    for i,item in ipairs(results) do
      local row=rows[i]
      if not row then
        row=UI:CreateButton(list,"",0,-(i-1)*50,width-12,function(self)
          if self.searchSerial~=N.serial or self.searchGeneration~=K.profileGeneration or not s:IsShown() then return end
          N:Open(self.item.route,self.item.id)
        end);row.ignoreModuleEnabled=true;row.navigationOnly=true;rows[i]=row
        row.detail=UI:CreateDescription(row,"",8,-28);row:GetFontString():ClearAllPoints();row:GetFontString():SetPoint("TOPLEFT",8,-5)
        row:GetFontString():SetJustifyH("LEFT")
      end
      row.item=item;row.searchSerial=serial;row.searchGeneration=generation
      row:SetWidth(width-12);row:GetFontString():SetWidth(width-28);row:GetFontString():SetWordWrap(true);row.detail:SetWidth(width-28)
      row:SetText(item.path);row.detail:SetText(N:Status(item))
      local titleHeight=row:GetFontString():GetStringHeight()
      row.detail:ClearAllPoints();row.detail:SetPoint("TOPLEFT",8,-titleHeight-11)
      row:ClearAllPoints();row:SetPoint("TOPLEFT",0,-listHeight)
      row:SetHeight(math.max(48,titleHeight+row.detail:GetStringHeight()+20));listHeight=listHeight+row:GetHeight()+2;row:Show()
    end
    for i=#results+1,#rows do rows[i]:Hide() end
    list:SetHeight(math.max(50,listHeight));pane:SetHeight(math.min(310,math.max(62,listHeight+12)));viewport:SetVerticalScroll(0)
    if #results==0 then
      pane.empty=pane.empty or UI:CreateDescription(pane,"검색 결과가 없습니다.",12,-18);pane.empty:Show()
    elseif pane.empty then pane.empty:Hide() end
    pane:Show()
  end
  box:SetScript("OnTextChanged",changed)
  box:SetScript("OnEscapePressed",function() box:SetText("");box:ClearFocus();N:CancelSearch(s) end)
  box:SetScript("OnEnterPressed",function() local results=N:Search(box:GetText());if results[1] then N:Open(results[1].route,results[1].id) end;box:ClearFocus() end)
  box:HookScript("OnHide",function() N:CancelSearch(s) end)
  return box
end
