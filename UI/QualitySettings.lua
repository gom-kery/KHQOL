local _, KHQOL = ...
local UI,T=KHQOL.UI,KHQOL.UI.Theme
-- One-column detail rows. Only short child checks share a row. Height changes
-- use the presenter's existing OnSizeChanged path, including cached tabs.
local function layout(parent,y,key)
  local rows={}; local page=CreateFrame("Frame",nil,parent)
  page:SetPoint("TOPLEFT",0,y); page:SetWidth(parent:GetWidth()); page.moduleKey=key
  local function row(height,visible,indent)
    local f=CreateFrame("Frame",nil,page); f:SetWidth(page:GetWidth()-(indent or 0)); f:SetHeight(height)
    rows[#rows+1]={frame=f,height=height,visible=visible,indent=indent or 0}; return f
  end
  local L={page=page}
  function L:Fields(frame,height)
    local f=row(height); frame:SetParent(f); frame:SetPoint("TOPLEFT",0,0); frame:SetHeight(height)
  end
  function L:Section(title)
    local f=row(T.SectionGap+36); UI:CreateSection(f,title,0)
  end
  function L:Description(text,visible)
    local f=row(T.RowHeight+T.RowGap,visible)
    local label=UI:CreateDescription(f,type(text)=="function" and text() or text,0,-6); label:SetWidth(f:GetWidth())
    rows[#rows].label=label
    if type(text)=="function" then rows[#rows].text=text end
  end
  function L:Check(title,get,set,visible,tooltip,ignore,enabled)
    local f=row(T.RowHeight+T.RowGap,visible)
    local c=UI:CreateCheckbox(f,title,0,0,get,set,enabled)
    c.ignoreModuleEnabled=ignore; c:Refresh(); UI:AttachTooltip(c,title,tooltip); return c
  end
  function L:Children(items,visible,label)
    local f=row(T.RowHeight+T.RowGap,visible,T.ContentPadding)
    local prefix=0
    if label then
      local text=UI:CreateLabel(f,label,0,-6); text:SetWidth(100); prefix=108
    end
    local controls={}
    for _,item in ipairs(items) do
      local c=UI:CreateCheckbox(f,item[1],0,0,item[2],item[3]); c.text:SetWidth(100)
      c.text:SetWidth(math.max(100,c.text:GetStringWidth()))
      UI:AttachTooltip(c,item[1],item[4]); controls[#controls+1]=c
    end
    rows[#rows].flow=function(width)
      local x,line=prefix,0
      for _,c in ipairs(controls) do
        local w=T.CheckboxSize+T.CheckboxLabelGap+c.text:GetStringWidth()+T.RowGap
        if x+w>width and x>prefix then line=line+1; x=prefix end
        c:ClearAllPoints(); c:SetPoint("TOPLEFT",x,-line*(T.RowHeight+T.RowGap)); x=x+w
      end
      return (line+1)*(T.RowHeight+T.RowGap)
    end
  end
  function L:Dropdown(title,options,get,set,visible,tooltip,enabled)
    local f=row(T.DropdownRowHeight,visible); UI:CreateLabel(f,title,0,0)
    local c=UI:CreateDropdown(f,0,-24,math.min(T.DropdownWidth,f:GetWidth()),options,get,set,enabled)
    UI:AttachTooltip(c,title,tooltip); return c
  end
  function L:Slider(title,min,max,step,get,set,format,visible)
    local f=row(T.SliderRowHeight)
    UI:CreateSlider(f,title,"",0,0,min,max,step,get,set,format,visible)
  end
  function L:Compare(title,kind,options,db,module)
    local f=row(T.DropdownRowHeight)
    local label=UI:CreateLabel(f,title,0,-6); label:SetWidth(170)
    local controls,captions={},{}
    for index,unit in ipairs({"player","target"}) do
      local u=unit
      captions[index]=UI:CreateLabel(f,u=="player" and "플레이어" or "대상",0,0)
      if kind=="compact" or kind=="showPower" then
        controls[index]=UI:CreateCheckbox(f,"사용",0,0,function() return kind=="showPower" and db()[u][kind]~=false or kind=="compact" and db()[u][kind] end,function(v) db()[u][kind]=v; module:ApplySettings() end,function() return module:UnitParts(u)~=nil end)
        controls[index].text:SetWidth(40)
      else
        controls[index]=UI:CreateDropdown(f,0,0,T.DropdownWidth,options,function() return db()[u][kind] end,function(v) db()[u][kind]=v; module:ApplySettings() end,function() return module:UnitParts(u)~=nil end)
      end
    end
    rows[#rows].flow=function(width)
      local wide=width>=560
      local labelWidth=wide and 170 or width; label:SetWidth(labelWidth)
      for index,c in ipairs(controls) do
        local x=wide and (180+(index-1)*(width-180+T.ColumnGap-T.ContentPadding)/2) or T.ContentPadding
        local top=wide and -24 or (-28-(index-1)*T.DropdownRowHeight)
        c:ClearAllPoints(); c:SetPoint("TOPLEFT",x,top)
        if kind~="compact" and kind~="showPower" then c.layoutWidth=wide and (width-180-T.ColumnGap-T.ContentPadding)/2 or math.min(T.DropdownWidth,width-T.ContentPadding); c:SetWidth(c.layoutWidth) end
        captions[index]:ClearAllPoints(); captions[index]:SetPoint("TOPLEFT",x,top+20)
        captions[index]:SetWidth(wide and (width-180-T.ColumnGap)/2 or width-T.ContentPadding)
      end
      return wide and T.DropdownRowHeight or (28+2*T.DropdownRowHeight)
    end
  end
  local function refresh()
    local top=0; local width=parent:GetWidth()
    page:SetWidth(width)
    for _,r in ipairs(rows) do
      local show=not r.visible or r.visible()
      r.frame:SetShown(show)
      if show then
        r.frame:ClearAllPoints(); r.frame:SetPoint("TOPLEFT",r.indent,top); r.frame:SetWidth(width-r.indent)
        local height=r.flow and r.flow(width-r.indent) or r.height
        if r.label then
          if r.text then r.label:SetText(r.text()) end
          r.label:SetWidth(width-r.indent); height=math.max(height,r.label:GetStringHeight()+T.RowGap)
        end
        r.frame:SetHeight(height); top=top-height
      end
    end
    page:SetHeight(math.max(1,-top)); parent:SetHeight(math.max(1,-y+page:GetHeight()))
  end
  local sentinel=CreateFrame("Frame",nil,page); sentinel.Refresh=refresh; sentinel.layoutRefresh=true; sentinel.ignoreModuleEnabled=true
  UI:RegisterControl(page,sentinel)
  function L:Finish() refresh(); return y-page:GetHeight() end
  return L
end
-- Stable cells keep subordinate controls in place when switches change.
-- Availability changes, never row visibility, so neighboring labels cannot shift.
function KHQOL.modules.generalConvenience:BuildSettings(parent,y)
  local M=self; local G=KHQOL.modules.general
  local function get(k) return function() return M:GetDB()[k] end end
  local function set(k) return function(v) M:GetDB()[k]=v; M:ApplySettings() end end
  local function legacy(k) return function() return G:GetDB()[k] end end
  local function legacySet(k) return function(v) G:SetConvenienceEnabled(k,v) end end
  local function supportedTracking() return C_Minimap and type(C_Minimap.GetTrackingInfo)=="function" and type(C_Minimap.SetTracking)=="function" end
  local function supportedItems() return C_TooltipInfo and type(C_TooltipInfo.GetItemByID)=="function" and type(ITEM_SPELL_KNOWN)=="string" end
  local function check(title,getter,setter,tip,enabled,children)
    return {title=title,get=getter,set=setter,tip=tip,enabled=enabled,children=children or {}}
  end
  local party,guild=legacy("declinePartyInvites"),legacy("declineGuildInvites")
  local sections={
    {title="대화창",items={check("기본 대화창 편의",legacy("chatEnhancement"),legacySet("chatEnhancement"),"대화 입력 커서 이동, 이전 대화 호출, 링크 툴팁 및 URL 복사를 개선합니다.")}},
    {title="아이템",items={
      check("아이템 파괴 자동 입력",legacy("autoConfirmDestroy"),legacySet("autoConfirmDestroy"),"파괴 확인 문구를 자동 입력합니다. 최종 확인은 직접 선택합니다."),
      check("잡템 자동 판매",legacy("autoSellJunk"),legacySet("autoSellJunk"),"상점에서 판매 가능한 회색 아이템을 판매합니다. 퀘스트 아이템과 불확실한 아이템은 제외합니다."),
      check("자동 수리",legacy("autoRepair"),legacySet("autoRepair"),"상점에서 수리 비용을 지불할 수 있을 때 수리합니다.",nil,{
        check("길드 자금 우선 사용",legacy("useGuildFunds"),function(v) G:GetDB().useGuildFunds=v end,"권한·잔액·한도가 충분하면 길드 자금으로, 부족하면 개인 골드로 수리합니다.")}),
      check("이미 습득한 아이템 표시",get("knownItems"),set("knownItems"),"습득 여부가 확인된 도안·탈것에 체크 표시합니다.",supportedItems,{
        check("도안",get("recipes"),set("recipes")),check("탈것",get("mounts"),set("mounts")),
        check("가방",get("bags"),set("bags")),check("상점",get("merchant"),set("merchant"))})}},
    {title="자동 거절",items={
      check("결투 요청",get("declineDuel"),set("declineDuel"),"결투 요청을 자동 거절합니다. 펫 대전·대기열은 제외합니다.",function() return type(CancelDuel)=="function" and type(StaticPopup_FindVisible)=="function" end),
      check("파티 초대",party,legacySet("declinePartyInvites"),"파티 초대를 자동 거절합니다. 명단을 확인할 수 없으면 초대를 유지합니다. 그룹 찾기·대기열은 제외합니다.",function() return type(DeclineGroup)=="function" and type(StaticPopup_FindVisible)=="function" end,{
        check("친구 허용",get("allowFriends"),set("allowFriends"),"게임 내 캐릭터 친구 목록 기준입니다. Battle.net 친구는 포함하지 않습니다."),
        check("길드원 허용",get("allowGuild"),set("allowGuild"))}),
      check("길드 초대",guild,legacySet("declineGuildInvites"),"길드 초대를 자동 거절합니다.",function() return type(DeclineGuild)=="function" end),
      check("거절 채팅 알림",get("declineReport"),set("declineReport"),"결투 요청·파티 초대·길드 초대의 거절 결과를 공통으로 대화창에 표시합니다.")}},
    {title="채집",items={check("채집 추적 상태 유지",get("keepTracking"),set("keepTracking"),"직접 선택한 채광·약초 추적을 부활 후 복원합니다. 직접 끈 추적은 복원하지 않습니다.",supportedTracking,{
      check("복원 채팅 알림",get("trackingReport"),set("trackingReport"))})}},
    {title="상점",items={check("상인 판매목록 확장",get("merchantExpanded"),set("merchantExpanded"),"기본 순서대로 4열 × 5행으로 확장합니다. 상점 변경 애드온과 충돌하면 적용하지 않습니다.")}},
  }
  local page=CreateFrame("Frame",nil,parent); page:SetPoint("TOPLEFT",0,y); page:SetWidth(parent:GetWidth())
  local step=T.RowHeight+T.RowGap
  for _,section in ipairs(sections) do
    section.frame=CreateFrame("Frame",nil,page); section.frame:SetWidth(page:GetWidth())
    UI:CreateSection(section.frame,section.title,0)
    section.measure={}
    for _,item in ipairs(section.items) do
      local cell=CreateFrame("Frame",nil,section.frame); cell:SetWidth(page:GetWidth()); item.cell=cell; item.controls={}
      section.measure[#section.measure+1]=item
      local c=UI:CreateCheckbox(cell,item.title,0,0,item.get,item.set,item.enabled)
      UI:AttachTooltip(c,item.title,item.tip); item.controls[1]=c
      for index,child in ipairs(item.children) do
        section.measure[#section.measure+1]=child
        local function enabled() return item.get() and (not item.enabled or item.enabled()) end
        local childColumn=item.title=="이미 습득한 아이템 표시" and (index-1)%2 or 0
        local childRow=item.title=="이미 습득한 아이템 표시" and math.floor((index-1)/2)+1 or index
        local control=UI:CreateCheckbox(cell,child.title,childColumn*100,-childRow*step,child.get,child.set,enabled)
        control.childColumn,control.childRow=childColumn,childRow
        UI:AttachTooltip(control,child.title,child.tip); item.controls[#item.controls+1]=control
      end
      cell:SetHeight((item.title=="이미 습득한 아이템 표시" and 3 or #item.controls)*step)
    end
  end
  local status=UI:CreateDescription(page,"",0,0)
  local function refresh()
    local top=0; local width=parent:GetWidth(); local reposition=page.gridWidth~=width; page.gridWidth=width; page:SetWidth(width)
    for _,section in ipairs(sections) do
      local f=section.frame; if reposition then f:ClearAllPoints(); f:SetPoint("TOPLEFT",0,top) end; f:SetWidth(width)
      local columns=2; section.columns=columns
      local cellWidth=(width-(columns-1)*T.ColumnGap)/columns
      local rowTop=-(T.SectionGap+36); local rowHeight=0
      for index,item in ipairs(section.items) do
        local column=(index-1)%columns
        if column==0 and index>1 then rowTop=rowTop-rowHeight; rowHeight=0 end
        if reposition then item.cell:ClearAllPoints(); item.cell:SetPoint("TOPLEFT",column*(cellWidth+T.ColumnGap),rowTop) end; item.cell:SetWidth(cellWidth)
        for _,control in ipairs(item.controls) do control.text:SetWidth((control.childColumn and item.title=="이미 습득한 아이템 표시" and (cellWidth-T.RowGap)/2 or cellWidth)-T.CheckboxSize-T.CheckboxLabelGap)
          if reposition and control.childColumn and item.title=="이미 습득한 아이템 표시" then control:ClearAllPoints(); control:SetPoint("TOPLEFT",control.childColumn*(cellWidth+T.RowGap)/2,-control.childRow*step) end end
        rowHeight=math.max(rowHeight,item.cell:GetHeight())
      end
      f:SetHeight(-rowTop+rowHeight); top=top-f:GetHeight()
    end
    local text=M.merchantPending and "상점 확장: 전투가 끝나면 적용합니다." or (M:GetDB().merchantExpanded and M.merchantUnavailable and "상점 확장 미적용: "..M.merchantUnavailable or "")
    if reposition then status:ClearAllPoints(); status:SetPoint("TOPLEFT",0,top-6) end; status:SetWidth(width); status:SetText(text)
    top=top-step*2 -- Reserve a stable two-line status area on OFF/ON.
    page:SetHeight(-top); parent:SetHeight(-y-top)
  end
  local sentinel=CreateFrame("Frame",nil,page); sentinel.Refresh=refresh; sentinel.layoutRefresh=true
  UI:RegisterControl(page,sentinel); refresh()
  parent.generalSections=sections
  return y-page:GetHeight()
end
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
  local M=self; local l=layout(parent,y,"unitFrames")
  local function db() return M:GetDB() end
  l:Description("전투 중이거나 기본 프레임 정보를 확인할 수 없으면 변경을 보류합니다. 전투 종료·다음 프레임 갱신에서 안전하게 적용합니다.",function() return M.pending==true end)
  l:Section("유닛 프레임")
  l:Compare("간결한 프레임 사용","compact",nil,db,M)
  l:Compare("자원 바 표시","showPower",nil,db,M)
  l:Compare("체력 수치 표시 방식","health",textModes,db,M)
  l:Compare("자원 수치 표시 방식","power",textModes,db,M)
  for _,unit in ipairs({"player","target"}) do
    local u=unit
    l:Section(u=="player" and "플레이어 크기" or "대상 크기")
    local f=CreateFrame("Frame",nil,l.page); f:SetWidth(parent:GetWidth())
    local b=UI:CreateBuilder(f,0)
    local function enabled() return db()[u].compact and M:UnitParts(u)~=nil end
    b:Slider("폭",120,400,5,function() return db()[u].width end,function(v) db()[u].width=v; M:ApplySettings() end,function(v) return v.." px" end,enabled,"간결한 프레임에만 적용됩니다. 프레임 위치는 유지합니다.")
    b:Slider("높이",24,236,1,function() return select(2,M:CompactLayout(db()[u])) end,function(v) M:SetTotalHeight(u,v) end,function(v) return v.." px" end,enabled,"이름·표시 중인 바·간격의 전체 높이입니다. 변경하면 체력/자원 높이를 함께 조정합니다. 자원 OFF에서는 체력만 포함합니다. 간결한 프레임에만 적용됩니다.")
    b:Slider("체력 바 높이",8,100,1,function() return select(4,M:CompactLayout(db()[u])) end,function(v) M:SetBarHeight(u,"health",v) end,function(v) return v.." px" end,enabled,"체력 바만 조정합니다. 간결한 프레임에만 적용됩니다.")
    b:Slider("자원 바 높이",4,100,1,function() return select(5,M:CompactLayout(db()[u])) end,function(v) M:SetBarHeight(u,"power",v) end,function(v) return v.." px" end,function() return enabled() and db()[u].showPower~=false end,"자원 표시 ON·간결한 프레임에서 조정합니다. OFF해도 설정 높이는 유지합니다.")
    b:Slider("체력·자원 사이 간격",0,20,1,function() return db()[u].gap end,function(v) db()[u].gap=v; M:ApplySettings() end,function(v) return v.." px" end,function() return enabled() and db()[u].showPower~=false end,"0 px에서는 체력 바 아래에 자원 바를 여백 없이 연결합니다. 자원 OFF 시 값은 유지합니다.")
    b:Slider("검은 테두리 투명도",0,1,.1,function() return db()[u].borderAlpha end,function(v) db()[u].borderAlpha=v; M:ApplySettings() end,function(v) return string.format("%d%%",v*100) end,enabled)
    b:Slider("체력·자원 글자 크기",8,24,1,function() return db()[u].textSize end,function(v) db()[u].textSize=v; M:ApplySettings() end,function(v) return v.." px" end,function() return M:UnitParts(u)~=nil end,"현재값·최대값·백분율 등 직접 선택한 수치에 적용합니다. 기본 설정 따름은 게임의 글꼴 설정을 유지합니다.")
    l:Fields(f,-b.y)
  end
  return l:Finish()
end
