local KHQOL = _G.KHQOL
local UI,T=KHQOL.UI,KHQOL.UI.Theme
local function layout(...) return UI:CreateDetailLayout(...) end
local barModes={{value="default",text="기본 표시"},{value="hide",text="항상 숨김"},{value="hover",text="마우스 오버 시 표시"}}
local textModes={{value="default",text="기본 설정 따름"},{value="hide",text="숨김"},{value="current",text="현재값"},{value="both",text="현재값 / 최대값"},{value="percent",text="백분율"},{value="currentPercent",text="현재값 + 백분율"}}
function KHQOL.modules.basicUI:BuildSettings(parent,y)
  local M=self; local l=layout(parent,y,"basicUI")
  local function db() return M:GetDB() end
  l:Description("전투 중 변경은 전투 종료 후 적용합니다.",function() return M.pending==true end)
  l:Section("가방·메뉴바")
  -- Shared builder fields use two columns and refresh preserves their width.
  local f=CreateFrame("Frame",nil,l.page); f:SetWidth(parent:GetWidth())
  local b=UI:CreateBuilder(f,0)
  local bags=b:Dropdown("가방 버튼 표시 방식",barModes,function() return db().bags end,function(v) db().bags=v; M:ApplySettings() end,function() return _G.BagsBar~=nil end)
  local micro=b:Dropdown("메뉴바 표시 방식",barModes,function() return db().micro end,function(v) db().micro=v; M:ApplySettings() end,function() return _G.MicroMenu~=nil end)
  UI:AttachTooltip(bags,"가방 버튼 표시 방식","마우스 오버 모드에서는 버튼 영역에 마우스를 올리면 표시합니다.")
  UI:AttachTooltip(micro,"메뉴바 표시 방식","마우스 오버 모드에서는 메뉴 영역에 마우스를 올리면 표시합니다.")
  -- The detail layout owns this fixed two-column row.
  l:Fields(f,-b.y)
  l:Slider("공통 숨김 지연",0,2,.1,function() return db().hideDelay end,function(v) db().hideDelay=v; M:ApplySettings() end,function(v) return string.format("%.1f초",v) end,function() return db().bags=="hover" or db().micro=="hover" end)
  l:Description("상단 모듈 사용과 하단 모듈 초기화는 가방·메뉴바에 적용됩니다. 기본창 이동은 아래 별도 스위치와 위치 초기화를 사용합니다.")
  local mover=CreateFrame("Frame",nil,l.page); mover:SetWidth(parent:GetWidth())
  l:Fields(mover,-KHQOL.modules.frameMover:BuildSettings(mover,0))
  return l:Finish()
end
function KHQOL.modules.unitFrames:BuildSettings(parent,y)
  local M=self;local N=UI.SettingsNavigation;local prefs=N:Preferences()
  local l=layout(parent,y,"unitFrames");local selected=prefs.unit or "player";local selectedPart=prefs.part or "basic"
  if not M.defaults[selected] then selected="player" end
  local auraCategory=prefs.auraCategory or "friendlyPlayer"
  local supports={basic=true,bars=true,labels=true,status=true}
  local function supportedPart(part,unit) return supports[part] or part=="auras" and (unit=="player" or unit=="target") or part=="class" and unit=="player" end
  if not supportedPart(selectedPart,selected) then selectedPart="basic" end
  parent.selectedUnit=selected;parent.selectedPart=selectedPart;parent.selectedAuraCategory=auraCategory
  parent.settingsRoute={module="unitFrames"}
  local units={{value="player",text="플레이어"},{value="target",text="대상"},{value="pet",text="소환수"},{value="targettarget",text="대상의 대상"},{value="focus",text="주시대상"}}
  local positions={{value="above",text="위"},{value="inside",text="내부"},{value="below",text="아래"},{value="left",text="왼쪽(외부)"},{value="right",text="오른쪽(외부)"}}
  local sides={{value="LEFT",text="왼쪽 구석"},{value="RIGHT",text="오른쪽 구석"}}
  local growths={{value="RIGHT_UP",text="오른쪽 이후 위로"},{value="RIGHT_DOWN",text="오른쪽 이후 아래로"},{value="LEFT_UP",text="왼쪽 이후 위로"},{value="LEFT_DOWN",text="왼쪽 이후 아래로"}}
  local function db() return M:GetDB() end
  l:Description(function()
    if KHQOL.LabLock:IsExperimental("unitFrames") and not KHQOL.LabLock:IsUnlocked() then return "실험실 잠금 · 설정은 보관되어 있습니다. 실험실에서 잠금을 해제하면 적용할 수 있습니다." end
    if not KHQOL:GetEnabled("unitFrames") then return "모듈 OFF · 설정 탐색은 가능하며 기능은 자동 활성화되지 않습니다. 저장: 현재 프로필." end
    return "저장: 현재 프로필 · 없는 유닛의 값은 유지하며 해당 부품이 나타나면 적용합니다."
  end)
  l:Description("전투 중 크기·배치 변경은 종료 후 적용합니다. 공개 원본값이 확인되지 않으면 적용을 보류합니다.",function() return M.pending==true end)
  local header=CreateFrame("Frame",nil,parent);header:SetWidth(parent:GetWidth());header:SetHeight(2*(T.ButtonHeight+T.RowGap))
  header.moduleKey="unitFrames";parent.fixedHeader=header;parent.unitTabButtons={}
  local function selectUnit(v,quiet)
    if not M.defaults[v] then return end
    N:RememberScroll(KHQOL.settings)
    UI:CancelInputs(parent);UI:CloseColorPicker();M:StopBottomPreview();selected=v
    if not supportedPart(selectedPart,v) then selectedPart="basic" end
    prefs.unit=selected;prefs.part=selectedPart;parent.selectedUnit=selected;parent.selectedPart=selectedPart
    if KHQOL.settings then KHQOL.settings.currentRoute=N:UnitRoute(selected,selectedPart,auraCategory) end
    if KHQOL.settings then KHQOL.settings.pageTitle:SetText(N:Path(N:UnitRoute(selected,selectedPart,auraCategory))) end
    if quiet then return end
    UI:Refresh(parent);UI:Refresh(header);UI:QueueDisplayRefresh(parent)
    if KHQOL.settings and KHQOL.settings.moduleSubHeader==header then N:RestoreScroll(KHQOL.settings) end
  end
  parent.SelectUnitTab=selectUnit
  function parent:SelectUnitPart(unit,part,category)
    N:RememberScroll(KHQOL.settings)
    if unit and M.defaults[unit] then selectUnit(unit,true) end
    if part and supportedPart(part,selected) then selectedPart=part end
    if category=="friendlyPlayer" or category=="attackableNPC" then auraCategory=category;prefs.auraCategory=category end
    prefs.part=selectedPart;self.selectedPart=selectedPart;self.selectedAuraCategory=auraCategory
    UI:CancelInputs(parent);UI:CloseColorPicker();M:StopBottomPreview();UI:Refresh(parent);UI:Refresh(header)
    UI:QueueDisplayRefresh(parent)
    if KHQOL.settings then KHQOL.settings.currentRoute=N:UnitRoute(selected,selectedPart,auraCategory);KHQOL.settings.pageTitle:SetText(N:Path(N:UnitRoute(selected,selectedPart,auraCategory)));KHQOL.settings:SetPageScrollLayout("unitFrames");N:RestoreScroll(KHQOL.settings) end
  end
  parent.SelectAuraCategory=function(category)
    if category~="friendlyPlayer" and category~="attackableNPC" then return end
    N:RememberScroll(KHQOL.settings)
    UI:CancelInputs(parent);UI:CloseColorPicker();auraCategory=category;prefs.auraCategory=category;parent.selectedAuraCategory=category;UI:Refresh(parent);UI:QueueDisplayRefresh(parent)
    if KHQOL.settings then KHQOL.settings.currentRoute=N:UnitRoute(selected,selectedPart,auraCategory);KHQOL.settings.pageTitle:SetText(N:Path(N:UnitRoute(selected,selectedPart,auraCategory)));N:RestoreScroll(KHQOL.settings) end
  end
  local x=0
  local measure=header:CreateFontString(nil,"OVERLAY");measure:SetFont(UI:Font(),T.LabelFontSize,"")
  for _,entry in ipairs(units) do
    local u=entry.value;measure:SetText(entry.text);local width=math.ceil(measure:GetStringWidth())+24
    local button=UI:CreateButton(header,entry.text,x,0,width,function() selectUnit(u) end)
    button.ignoreModuleEnabled=true;button.navigationOnly=true
    button.Refresh=function() UI:SetButtonSelected(button,selected==u);UI:ApplyAvailability(button) end
    button:Refresh();parent.unitTabButtons[u]=button;x=x+width+T.RowGap
  end
  measure:Hide()
  parent.partTabButtons={}
  for _,id in ipairs({"basic","bars","labels","status","auras","class"}) do
    local part=id;local button=UI:CreateButton(header,N.parts[part],0,-T.ButtonHeight-T.RowGap,160,function() parent:SelectUnitPart(nil,part) end)
    button.ignoreModuleEnabled=true
    button.Refresh=function() button:SetShown(supportedPart(part,selected));UI:SetButtonSelected(button,selectedPart==part) end
    button.navigationOnly=true
    parent.partTabButtons[part]=button
  end
  local function headerLayout()
    local top=0
    for _,buttons in ipairs({parent.unitTabButtons,parent.partTabButtons}) do
      local left=0;local order=buttons==parent.unitTabButtons and M.unitTokens or {"basic","bars","labels","status","auras","class"}
      for _,id in ipairs(order) do
        local button=buttons[id]
        if buttons==parent.unitTabButtons or supportedPart(id,selected) then
          local width=button:GetWidth()
          if left>0 and left+width>header:GetWidth() then left=0;top=top-T.ButtonHeight-T.RowGap end
          button:ClearAllPoints();button:SetPoint("TOPLEFT",left,top);left=left+width+T.RowGap
        end
      end
      top=top-T.ButtonHeight-T.RowGap
    end
    header:SetHeight(-top)
  end
  local sentinel=CreateFrame("Frame",nil,header);sentinel.Refresh=headerLayout;sentinel.layoutRefresh=true;UI:RegisterControl(header,sentinel)
  header:HookScript("OnSizeChanged",function() if not header.layingOut then header.layingOut=true;headerLayout();header.layingOut=nil end end)
  for _,unit in ipairs(M.unitTokens) do
    local u=unit
    local function visible() return selected==u end
    local function parts() return M:UnitParts(u) end
    local function available() return parts()~=nil end
    local function compact() return available() and db()[u].compact end
    local function has(kind) local p=parts();return compact() and p[kind]~=nil end
    local part="basic";local category
    local function field()
      local f=CreateFrame("Frame",nil,l.page);f:SetWidth(parent:GetWidth());f.settingsRoute={module="unitFrames",unit=u,part=part,category=category};return f,UI:CreateBuilder(f,0)
    end
    local function finish(f,b,extra)
      local p=f.settingsRoute.part;b:Flush();l:Fields(f,-b.y,function() return visible() and selectedPart==p and (not extra or extra()) end)
    end
    local function shown(p) return function() return visible() and selectedPart==p end end
    l.controlRoute={module="unitFrames",unit=u,part="basic"}
    local compactControl=l:Check("간결한 프레임 사용",function() return db()[u].compact end,function(v) db()[u].compact=v;M:ApplySettings() end,shown("basic"),"기본 클릭·메뉴·표시 조건을 유지합니다. 실험실 잠금 해제는 필요하지 않습니다. 전투 중 배치 변경은 종료 후 적용하며 지원되는 기본 부품에 적용합니다.",nil,available)
    compactControl:GetParent().settingsRoute={module="unitFrames",unit=u,part="basic"}
    N:Attach(compactControl:GetParent(),compactControl,"간결한 프레임 사용",function() return db()[u].compact end,function(v) db()[u].compact=v;M:ApplySettings() end,available)
    l:Description(u=="targettarget" and "프레임 위치는 아래 좌표 또는 드래그 이동으로 조절합니다. 0 px는 기본 대상 프레임에 연결된 원래 위치입니다." or "프레임 전체 위치는 게임의 기본 편집 모드를 사용합니다. 아래 좌표는 글자·상태 표시의 미세 보정입니다.",shown("basic"))
    if u=="targettarget" then
      local row,builder=field()
      for _,axis in ipairs({"X","Y"}) do
        local a=axis
        builder:Slider("프레임 "..a.." 위치 보정",-1000,1000,1,function() return db()[u]["frame"..a] end,function(v) db()[u]["frame"..a]=v;M:ApplySettings() end,function(v) return v.." px" end,available)
      end
      builder:Button("프레임 드래그 이동",function() KHQOL.PositionEditor:Enter("unitFrames.targettarget") end,nil,available)
      builder:Button("프레임 위치 초기화",function() db()[u].frameX=0;db()[u].frameY=0;M:ApplySettings() end,nil,available)
      finish(row,builder)
    end
    if u~="targettarget" then
      local row,builder=field()
      builder:Button("전체 프레임 위치 이동",function() M:OpenNativePositionEditor() end,nil,available)
      builder:Description("전체 프레임 이동은 기본 게임 편집 모드를 사용합니다. 아래 부품 이동은 KHQOL 위치 편집기로 연결됩니다.",true)
      finish(row,builder)
    end
    l:Description(function()
      local w,h,g,hp,mp,power=M:CompactLayout(db()[u])
      return string.format("현재 프로필 · 폭 %d / 전체 높이 %d / 체력 %d / 자원 %s · 크기는 체력·자원에서 조절합니다.",w,h,hp,power and tostring(mp) or "숨김")
    end,shown("basic"))
    part="bars"
    local f,b=field()
    b:Description("전체 높이 = 정보 영역 16 + 체력 높이 + (자원 표시 시 간격 + 자원 높이). 전체 높이 변경은 두 바 높이를 함께 조절합니다.",true)
    b:Slider("프레임 폭",60,400,1,function() return db()[u].width end,function(v) db()[u].width=v;M:ApplySettings() end,function(v) return v.." px" end,compact)
    b:Slider("전체 높이",24,236,1,function() return select(2,M:CompactLayout(db()[u])) end,function(v) M:SetTotalHeight(u,v) end,function(v) return v.." px" end,compact)
    b:Slider("체력 바 높이",8,100,1,function() return select(4,M:CompactLayout(db()[u])) end,function(v) M:SetBarHeight(u,"health",v) end,function(v) return v.." px" end,compact)
    b:Checkbox("자원 바 표시",function() return db()[u].showPower~=false end,function(v) db()[u].showPower=v;M:ApplySettings() end,available)
    b:Slider("자원 바 높이",4,100,1,function() return select(5,M:CompactLayout(db()[u])) end,function(v) M:SetBarHeight(u,"power",v) end,function(v) return v.." px" end,function() return compact() and db()[u].showPower~=false end)
    b:Slider("바 사이 간격",0,20,1,function() return db()[u].gap end,function(v) db()[u].gap=v;M:ApplySettings() end,function(v) return v.." px" end,function() return compact() and db()[u].showPower~=false end)
    local modes={{value="default",text="기본색"}}
    if u=="player" then modes[#modes+1]={value="class",text="직업색"}
    elseif u=="target" or u=="targettarget" or u=="focus" then
      modes[#modes+1]={value="reaction",text="관계·직업색"}
      modes[#modes+1]={value="class",text="직업색",disabled=true}
    end
    modes[#modes+1]={value="custom",text="사용자 지정색"}
    local mode=b:Dropdown("체력 바 색상",modes,function() return db()[u].healthColorMode end,function(v) db()[u].healthColorMode=v;M:ApplySettings() end,available)
    local conditional=u=="target" or u=="targettarget" or u=="focus"
    UI:AttachTooltip(mode,"체력 바 색상",conditional and ("기본색: 모두 #00A118. 관계·직업색: 플레이어 직업색, 아군 NPC #00A118, 중립 #F5BE00, 적군 "..(u=="target" and "#860000" or "#D94F38")..", 다른 사람에게 선점된 적군 #636363."..(u=="targettarget" and " 대상의 대상의 중립 NPC는 노란색을 유지합니다." or " 중립 NPC도 나와 전투 중이면 #D94F38, 다른 사람에게 선점되면 회색입니다.")) or "기본·간결한 프레임 모두 지원합니다. 직업색의 클래스 토큰/RGB가 공개적으로 확인되지 않으면 기본 표시를 유지합니다.")
    b:Color("사용자 지정색",function() local c=db()[u].healthColor;return c.r,c.g,c.b,1 end,function(r,g,bl) local c=db()[u].healthColor;c.r,c.g,c.b=r,g,bl;M:ApplySettings() end,function() return available() and db()[u].healthColorMode=="custom" end)
    b:Slider("체력 바 배경 불투명도",0,1,.1,function() return db()[u].borderAlpha end,function(v) db()[u].borderAlpha=v;M:ApplySettings() end,function(v) return string.format("%d%%",v*100) end,compact,"체력의 빈 영역을 포함합니다. 이름·레벨 주변의 큰 배경은 제거하며 자원 자체 배경은 유지합니다.")
    b:Dropdown("사각 테두리",{{value="none",text="없음"},{value="thin",text="얇은 사각선"}},function() return db()[u].borderStyle end,function(v) db()[u].borderStyle=v;M:ApplySettings() end,compact)
    finish(f,b)
    part="status"
    do
      local row,builder=field()
      if u=="player" or u=="target" then
        local icons=u=="player" and {{"rest","휴식 상태"},{"combat","전투 상태"},{"marker","대상 징표"}} or {{"marker","대상 징표"}}
        for _,entry in ipairs(icons) do
          local kind,title=entry[1],entry[2]
          builder:Description(title)
          for _,axis in ipairs({"X","Y"}) do
            local a=axis
            builder:Slider(title.." "..a.." 위치 보정",-400,400,1,function() return M:StatusOffset(u,kind,a) end,function(v) M:SetStatusOffset(u,kind,a,v) end,function(v) return v.." px" end,compact)
          end
          builder:Button(title.." 드래그 이동",function() KHQOL.PositionEditor:Enter("unitFrames."..u.."."..kind) end,nil,compact)
          builder:Button(title.." 위치 초기화",function() M:ResetStatusOffset(u,kind) end,nil,compact)
          builder:Flush()
        end
        builder:Description(u=="player" and "휴식·전투·징표를 각각 이동합니다. 표시 조건은 기본 게임이 유지합니다." or "대상 징표를 개별 이동합니다. 이 기본 대상 프레임에는 플레이어의 휴식·전투 아이콘이 없습니다.",true)
      else
        builder:Description("상태·징표 · 대상 표시기")
        for _,axis in ipairs({"X","Y"}) do
          local a=axis
          builder:Slider("상태·징표 "..a.." 위치 보정",-200,200,1,function() return db()[u]["status"..a] end,function(v) db()[u]["status"..a]=v;M:ApplySettings() end,function(v) return v.." px" end,compact)
        end
        builder:Button("상태·징표 드래그 이동",function() KHQOL.PositionEditor:Enter("unitFrames."..u..".status") end,nil,compact)
      end
      builder:Button("상태·징표 위치 초기화",function()
        for _,key in ipairs({"status","rest","combat","marker"}) do if db()[u][key.."X"]~=nil then db()[u][key.."X"]=0;db()[u][key.."Y"]=0 end end
        M:ApplySettings()
      end,nil,compact)
      finish(row,builder)
    end
    if u=="target" then
      local row,builder=field()
      local function marks() return M:MonsterMarkSettings() end
      builder:Description("몬스터 마크",true)
      builder:Checkbox("퀘스트 몬스터 마크",function() return marks().quest end,function(v) marks().quest=v;M:ApplySettings() end,compact)
      builder:Checkbox("정예·희귀 몬스터 마크",function() return marks().classification end,function(v) marks().classification=v;M:ApplySettings() end,compact)
      builder:Slider("몬스터 마크 크기",8,40,1,function() return marks().size end,function(v) marks().size=v;M:ApplySettings() end,function(v) return v.." px" end,compact)
      builder:Flush()
      for _,axis in ipairs({"x","y"}) do local a=axis
        builder:Slider("몬스터 마크 "..a:upper().." 위치 보정",-400,400,1,function() return marks()[a] end,function(v) marks()[a]=v;M:ApplySettings() end,function(v) return v.." px" end,compact)
      end
      builder:Button("몬스터 마크 드래그 이동",function() KHQOL.PositionEditor:Enter("unitFrames.target.monster") end,nil,compact)
      builder:Button("몬스터 마크 위치 초기화",function() marks().x=0;marks().y=0;M:ApplySettings() end,nil,compact)
      builder:Description("간결한 대상 프레임 왼쪽에 표시합니다. 퀘스트 대상은 게임의 공개 판정을 따르며 정예는 금색, 희귀·희귀 정예는 은색 용 마크입니다. 판정·아이콘 API 미지원/접근 제한 시 해당 마크를 생략합니다.",true)
      finish(row,builder)
    end
    part="labels"
    for _,kind in ipairs({"name","level"}) do
      local k=kind;local title=k=="name" and "이름" or "레벨";local row,builder=field()
      local function enabled() return has(k) end
      builder:Dropdown(title.." 위치",positions,function() return db()[u][k.."Position"] end,function(v) UI:CancelInputs(row);M:SetLabelAnchor(u,k,"Position",v) end,enabled)
      builder:Dropdown(title.." 구석 정렬",sides,function() return db()[u][k.."Side"] end,function(v) UI:CancelInputs(row);M:SetLabelAnchor(u,k,"Side",v) end,function()
        if not enabled() then return false end
        return k~="name" or db()[u].namePosition=="above" or db()[u].namePosition=="below"
      end)
      builder:Slider(title.." 글자 크기",8,30,1,function() return M:LabelSize(u,k) end,function(v) db()[u][k.."Size"]=v;M:ApplySettings() end,function(v) return v.." px" end,enabled,"기존 폰트 경로·효과를 유지하며 수치 글자와 독립적으로 조정합니다. 기본 부품이 없으면 사용하지 않습니다.")
      builder:Button(title.." 위치·글자 초기화",function() M:ResetLabel(k,u) end,nil,enabled)
      builder:Button(title.." 드래그 이동",function() KHQOL.PositionEditor:Enter("unitFrames."..u.."."..k) end,nil,enabled)
      if u=="player" or u=="target" then
        builder:Dropdown(title.." 색상",{{value="default",text="기본색"},{value="custom",text="사용자 지정색"}},function() return db()[u][k.."ColorMode"] end,function(v) db()[u][k.."ColorMode"]=v;M:ApplySettings() end,available)
        builder:Color(title.." 색 선택",function() local c=db()[u][k.."Color"];return c.r,c.g,c.b,1 end,function(r,g,bl) db()[u][k.."Color"]={r=r,g=g,b=bl};M:ApplySettings() end,function() return available() and db()[u][k.."ColorMode"]=="custom" end)
      end
      for _,axis in ipairs({"X","Y"}) do
        local a=axis
        builder:Slider(title.." "..a.." 위치 보정",-100,100,1,function() return db()[u][k..a] end,function(v) db()[u][k..a]=v;M:ApplySettings() end,function(v) return v.." px" end,enabled,"선택한 바/구석 앵커에 대한 보정. Enter 확정·ESC 취소.")
      end
      finish(row,builder,function() local p=parts();return not p or p[k]~=nil end)
    end
    l:Description("이 기본 프레임에는 별도 레벨 글자가 없습니다. 레벨 옵션은 적용하지 않으며 이름·수치 등 기존 정보는 유지합니다.",function() local p=parts();return visible() and selectedPart=="labels" and p and not p.level end)
    part="bars"
    f,b=field()
    b:Description("자원 바 OFF: 자원 높이와 간격은 사용하지 않습니다. 수치 설정은 기존 저장값을 유지합니다.",true)
    b:Dropdown("체력 수치 표시 방식",textModes,function() return db()[u].health end,function(v) db()[u].health=v;M:ApplySettings() end,available)
    b:Dropdown("자원 수치 표시 방식",textModes,function() return db()[u].power end,function(v) db()[u].power=v;M:ApplySettings() end,available)
    b:Slider("체력·자원 수치 글자 크기",8,24,1,function() return db()[u].textSize end,function(v) db()[u].textSize=v;M:ApplySettings() end,function(v) return v.." px" end,available,"직접 선택한 수치에 적용합니다. 기본 설정 따름은 게임 글꼴을 유지합니다.")
    finish(f,b)
    part="auras"
    if u=="player" then
      for _,kind in ipairs({"buffs","debuffs"}) do
        local k=kind;local title=k=="buffs" and "플레이어 버프" or "플레이어 디버프";local row,builder=field()
        local function cfg() return db().player.auras[k] end
        local function supported() return M:PlayerAuraFrame(k)~=nil end
        local function on() return supported() and cfg().enabled end
        builder:Description(title.." · 내 캐릭터의 기본 아이콘")
        builder:Checkbox(title.." 위치 설정 사용",function() return cfg().enabled end,function(v) cfg().enabled=v;M:ApplySettings() end,supported)
        builder:Slider(title.." 아이콘 크기",8,64,1,function() return cfg().size end,function(v) cfg().size=v;M:ApplySettings() end,function(v) return v.." px" end,on)
        builder:Dropdown(title.." 위치",{{value="above",text="위"},{value="below",text="아래"}},function() return cfg().position end,function(v) cfg().position=v;M:ApplySettings() end,on)
        builder:Checkbox(title.." 행·확장 설정 사용",function() return cfg().layoutEnabled end,function(v) cfg().layoutEnabled=v;M:ApplySettings() end,on)
        local function flow() return on() and cfg().layoutEnabled end
        builder:Slider(title.." 행당 개수",3,10,1,function() return cfg().perRow end,function(v) cfg().perRow=v;M:ApplySettings() end,function(v) return v.." 개" end,flow)
        builder:Slider(title.." 최대 행 수",1,4,1,function() return cfg().maxRows end,function(v) cfg().maxRows=v;M:ApplySettings() end,function(v) return v.." 행" end,flow)
        builder:Dropdown(title.." 확장 방향",growths,function() return cfg().growth end,function(v) cfg().growth=v;M:ApplySettings() end,flow)
        builder:Description("표시 한도 = 행당 개수 × 최대 행 수. 기본 게임이 제공하는 아이콘·숨김 조건·타이머는 유지합니다.",true)
        for _,axis in ipairs({"x","y"}) do local a=axis
          builder:Slider(title.." "..a:upper().." 위치 보정",-300,300,1,function() return cfg()[a] end,function(v) cfg()[a]=v;M:ApplySettings() end,function(v) return v.." px" end,on)
        end
        builder:Button(title.." 드래그 이동",function() KHQOL.PositionEditor:Enter("unitFrames.player."..k) end,nil,on)
        builder:Button(title.." 설정 초기화",function() db().player.auras[k]=KHQOL.MergeDefaults({},M.defaults.player.auras[k],"tables");M:ApplySettings() end,nil,supported)
        finish(row,builder)
      end
      l:Description("내 캐릭터의 버프·디버프를 각각 이동합니다. 기본 게임의 목록·타이머·숨김 조건은 유지합니다. 드래그 화면의 예시 아이콘에는 실제 효과가 없습니다.",shown("auras"))
      part="class"
      f,b=field()
      for _,axis in ipairs({"X","Y"}) do
        local a=axis
        b:Slider("토템·임시 소환 "..a.." 보정",-100,100,1,function() return db().player["bottom"..a] end,function(v) db().player["bottom"..a]=v;M:ApplySettings() end,function(v) return v.." px" end,function() return compact() and M:BottomFrame()~=nil end,"플레이어 하위 배치 컨테이너에 있는 기본 토템·임시 소환 표시를 이동합니다. 0 px는 기존 위치입니다.")
      end
      local previewField=f
      b:Checkbox("토템 현재 위치 확인",function() return M.bottomPreviewParent==previewField end,function(on) M:SetBottomPreview(previewField,on) end,compact)
      b:Button("토템 위치 초기화",function() db().player.bottomX=0;db().player.bottomY=0;M:ApplySettings() end,nil,compact)
      b:Button("토템·임시 소환 드래그 이동",function() KHQOL.PositionEditor:Enter("unitFrames.player.totems") end,nil,function() return compact() and M:BottomFrame()~=nil end)
      previewField:HookScript("OnHide",function() if M.bottomPreviewParent==previewField then M:StopBottomPreview() end end)
      UI:RegisterDraft(previewField,function() if M.bottomPreviewParent==previewField then M:StopBottomPreview() end end)
      finish(f,b)
      l:Description("실제 표시가 있으면 현재 경계를, 없으면 클릭 없는 예시 아이콘을 표시합니다. 예시는 타이머·실제 토템이 아닙니다.",visible)
      l.controlRoute={module="unitFrames",unit=u,part="class"}
      l:Check("기력 회복 표시 — 도적 / 표범 드루이드",function() return db().player.showEnergyTick end,function(v) db().player.showEnergyTick=v;M:ApplySettings() end,shown("class"),"캐릭터 기력 바 아래 부착 기능입니다. 공개 회복 주기·기준 시점이 확인될 때만 지원하며 ResourceSwing과 독립적으로 저장합니다.",nil,function() return compact() and M:EnergySupport() end)
      l:Description(function() local _,reason=M:EnergySupport();return reason end,shown("class"))
    elseif u=="target" then
      part="status"
      l.controlRoute={module="unitFrames",unit=u,part="status"}
      l:Check("기본 대상 콤보 포인트 숨김",function() return db().target.hideDefaultCombo end,function(v) db().target.hideDefaultCombo=v;M:ApplySettings() end,shown("status"),"간결한 대상 프레임에서 기본 ComboFrame의 화면 표시만 숨깁니다. KHQOL 자원/스윙바 콤보와 독립적입니다.",nil,compact)
      part="auras"
      local row,builder=field()
      builder:Dropdown("대상 버프·디버프 적용 유형",{{value="friendlyPlayer",text="선택한 아군 플레이어"},{value="attackableNPC",text="선택한 공격 가능한 NPC"}},function() return auraCategory end,parent.SelectAuraCategory,available)
      finish(row,builder)
      l:Description(function()
        local current=M:TargetAuraCategory()
        if not current then return "현재 선택한 대상은 두 유형에 해당하지 않습니다. 여기서 저장한 값은 해당 유형의 대상을 선택할 때 적용됩니다." end
        if current~=auraCategory then return "현재 대상과 선택한 적용 유형이 다릅니다. 해당 유형의 대상을 선택하면 저장한 위치가 적용됩니다." end
        return "현재 대상과 적용 유형이 일치합니다. 아래 설정 사용을 켜면 크기·위치가 적용됩니다."
      end,shown("auras"))
      for _,entry in ipairs({{"friendlyPlayer","아군 대상 플레이어"},{"attackableNPC","공격 가능한 대상 NPC"}}) do
        local auraType,title=entry[1],entry[2];category=auraType;local row,builder=field();local category=auraType
        local function cfg() return db().target.auras[category] end
        local function supported() return M:TargetAuraContainer()~=nil end
        local function on() return supported() and cfg().enabled end
        builder:Description(title.." · 선택한 대상에 적용")
        builder:Checkbox("대상 버프·디버프 설정 사용",function() return cfg().enabled end,function(v) cfg().enabled=v;M:ApplySettings() end,supported)
        builder:Checkbox("버프 표시",function() return cfg().showBuffs end,function(v) cfg().showBuffs=v;M:ApplySettings() end,on)
        builder:Checkbox("디버프 표시",function() return cfg().showDebuffs end,function(v) cfg().showDebuffs=v;M:ApplySettings() end,on)
        builder:Slider("버프·디버프 아이콘 크기",8,64,1,function() return cfg().size end,function(v) cfg().size=v;M:ApplySettings() end,function(v) return v.." px" end,on)
        builder:Checkbox("버프·디버프 개별 위치 사용",function() return cfg().separatePositions end,function(v) M:SetSeparateTargetAuras(category,v) end,on)
        builder:Dropdown("버프·디버프 공통 위치",{{value="above",text="위"},{value="below",text="아래"}},function() return cfg().position end,function(v) cfg().position=v;M:ApplySettings() end,function() return on() and not cfg().separatePositions end)
        builder:Checkbox("행·확장 설정 사용",function() return cfg().layoutEnabled end,function(v) cfg().layoutEnabled=v;M:ApplySettings() end,on)
        local function flow() return on() and cfg().layoutEnabled end
        for _,kind in ipairs({"buffs","debuffs"}) do
          local k=kind;local caption=k=="buffs" and "버프" or "디버프"
          builder:Slider(caption.." 행당 개수",3,10,1,function() return cfg()[k].perRow end,function(v) cfg()[k].perRow=v;M:ApplySettings() end,function(v) return v.." 개" end,flow)
          builder:Slider(caption.." 최대 행 수",1,4,1,function() return cfg()[k].maxRows end,function(v) cfg()[k].maxRows=v;M:ApplySettings() end,function(v) return v.." 행" end,flow)
          builder:Dropdown(caption.." 확장 방향",growths,function() return cfg()[k].growth end,function(v) cfg()[k].growth=v;M:ApplySettings() end,flow)
        end
        builder:Description("버프·디버프의 행과 방향을 각각 지정합니다. 한도는 행당 개수 × 최대 행 수입니다. 기존 그룹 위치와 기본 게임의 필터·타이머를 유지합니다.",true)
        for _,axis in ipairs({"x","y"}) do
          local a=axis
          builder:Slider("버프·디버프 공통 "..a:upper().." 위치 보정",-300,300,1,function() return cfg()[a] end,function(v) cfg()[a]=v;M:ApplySettings() end,function(v) return v.." px" end,function() return on() and not cfg().separatePositions end)
        end
        builder:Button("버프·디버프 공통 드래그 이동",function() KHQOL.PositionEditor:Enter("unitFrames.target.auras."..category) end,nil,function() return on() and not cfg().separatePositions end)
        local function separate() return on() and cfg().separatePositions end
        for _,kind in ipairs({"buffs","debuffs"}) do
          local k=kind;local title=k=="buffs" and "대상 버프" or "대상 디버프"
          builder:Flush();builder:Description(title.." 개별 위치")
          builder:Dropdown(title.." 위치",{{value="above",text="위"},{value="below",text="아래"}},function() return M:TargetAuraPosition(cfg(),k) end,function(v) M:SetTargetAuraPosition(category,k,"position",v) end,separate)
          for index,axis in ipairs({"x","y"}) do local a,i=axis,index
            builder:Slider(title.." "..a:upper().." 위치 보정",-300,300,1,function() return select(i+1,M:TargetAuraPosition(cfg(),k)) end,function(v) M:SetTargetAuraPosition(category,k,a,v) end,function(v) return v.." px" end,separate)
          end
          builder:Button(title.." 드래그 이동",function() KHQOL.PositionEditor:Enter("unitFrames.target.auras."..category.."."..k) end,nil,separate)
          builder:Button(title.." 위치 초기화",function() local item=cfg()[k];item.position="below";item.x=0;item.y=k=="debuffs" and -23 or 0;M:ApplySettings() end,nil,separate)
        end
        builder:Button("버프/디버프 설정 초기화",function() db().target.auras[category]=KHQOL.MergeDefaults({},M.defaults.target.auras[category],"tables");M:ApplySettings() end,nil,supported)
        finish(row,builder,function() return auraCategory==category end)
      end
      l:Description("선택한 대상 유형의 설정 사용을 켜면 적용됩니다. 내 캐릭터의 버프·디버프는 플레이어 탭에서 조절합니다. 기존 공통 위치는 보존됩니다. 개별 위치 사용을 켜면 버프와 디버프를 각각 이동합니다. 행·확장 설정은 별도로 유지합니다. 전투 중 변경은 종료 후 적용합니다.",shown("auras"))
      l:Description(function() return M.auraLayoutUnavailable or "" end,function() return visible() and selectedPart=="auras" and M.auraLayoutUnavailable~=nil end)
      l:Description("이 클라이언트의 기본 버프·디버프 설정 API를 확인할 수 없어 해당 조절을 보류합니다.",function() return visible() and selectedPart=="auras" and not M:TargetAuraContainer() end)
    end
    category=nil;part="basic"
    f,b=field()
    if u~="player" then b:Button("플레이어 모양 설정 복사",function() M:CopyPlayerShape(u) end,nil,available) end
    b:Description("복사: 크기·바 간격·글자·앵커·상태 보정. 제외: 색상 정책, 전체 프레임 위치와 토템·오라 등 전용 기능. 현재 프로필에 저장합니다.",true)
    b:Button("선택한 유닛의 모양 초기화",function() M:ResetShape(u) end,nil,available)
    finish(f,b)
    l:Description("이 클라이언트의 기본 프레임 구조를 확인할 수 없어 적용을 보류합니다.",function() return visible() and not available() end)
  end
  parent.unitLayout=l;headerLayout()
  return l:Finish()
end
