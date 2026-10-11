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
    local f=row(T.SliderRowHeight,visible)
    UI:CreateSlider(f,title,"",0,0,min,max,step,get,set,format)
  end
  function L:Compare(title,kind,options,db,module)
    local f=row(T.DropdownRowHeight)
    local label=UI:CreateLabel(f,title,0,-6); label:SetWidth(170)
    local controls,captions={},{}
    for index,unit in ipairs({"player","target"}) do
      local u=unit
      captions[index]=UI:CreateLabel(f,u=="player" and "플레이어" or "대상",0,0)
      if kind=="compact" then
        controls[index]=UI:CreateCheckbox(f,"사용",0,0,function() return db()[u][kind] end,function(v) db()[u][kind]=v; module:ApplySettings() end,function() return module:UnitParts(u)~=nil end)
        controls[index].text:SetWidth(40)
      else
        controls[index]=UI:CreateDropdown(f,0,0,T.DropdownWidth,options,function() return db()[u][kind] end,function(v) db()[u][kind]=v; module:ApplySettings() end,function() return module:UnitParts(u)~=nil end)
      end
    end
    rows[#rows].flow=function(width)
      local wide=width>=560
      local labelWidth=wide and 170 or width; label:SetWidth(labelWidth)
      for index,c in ipairs(controls) do
        local x=wide and (180+(index-1)*(width-180+T.ColumnGap)/2) or T.ContentPadding
        local top=wide and -24 or (-28-(index-1)*T.DropdownRowHeight)
        c:ClearAllPoints(); c:SetPoint("TOPLEFT",x,top)
        if kind~="compact" then c:SetWidth(wide and (width-180-T.ColumnGap)/2 or math.min(T.DropdownWidth,width-T.ContentPadding)) end
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
  local sentinel=CreateFrame("Frame",nil,page); sentinel.Refresh=refresh; sentinel.ignoreModuleEnabled=true
  UI:RegisterControl(page,sentinel)
  function L:Finish() refresh(); return y-page:GetHeight() end
  return L
end
function KHQOL.modules.generalConvenience:BuildSettings(parent,y)
  local M=self; local general=KHQOL.modules.general
  local l=layout(parent,y,"generalConvenience")
  local function db() return M:GetDB() end
  local function get(key) return function() return db()[key] end end
  local function set(key) return function(value) db()[key]=value; M:ApplySettings() end end
  local function trackingSupported() return C_Minimap and type(C_Minimap.GetTrackingInfo)=="function" and type(C_Minimap.SetTracking)=="function" end
  local function itemSupported() return C_TooltipInfo and type(C_TooltipInfo.GetItemByID)=="function" and type(ITEM_SPELL_KNOWN)=="string" end
  l:Section("일반 편의")
  l:Description("이 묶음은 초대·채집·상점 확장·습득 표시만 관리합니다.")
  l:Check("일반 편의 사용",function() return KHQOL:GetEnabled("generalConvenience") end,function(on) KHQOL:SetEnabled("generalConvenience",on) end,nil,nil,true)
  l:Description("일반 편의가 비활성화되어 있습니다. 위의 사용 옵션으로 켤 수 있습니다.",function() return not M:IsEnabled() end)
  l:Section("초대 관리")
  l:Check("결투 요청 자동 거절",get("declineDuel"),set("declineDuel"),nil,"직접 결투 요청만 처리합니다. 펫 대전·대기열에는 영향을 주지 않습니다.",nil,function() return type(CancelDuel)=="function" and type(StaticPopup_FindVisible)=="function" end)
  l:Children({{"거절 채팅 알림",get("duelReport"),set("duelReport")}},get("declineDuel"))
  local function party() return general:GetDB().declinePartyInvites end
  local function guild() return general:GetDB().declineGuildInvites end
  l:Check("파티 초대 자동 거절",party,function(on) general:SetConvenienceEnabled("declinePartyInvites",on) end,nil,"친구·길드원 예외는 파티 초대에만 적용합니다. 명단 정보가 미로딩이면 최대 3회 확인 후 요청을 그대로 유지합니다. 그룹 찾기·대기열은 제외합니다.",nil,function() return type(DeclineGroup)=="function" and type(StaticPopup_FindVisible)=="function" end)
  l:Children({{"거절 채팅 알림",get("partyReport"),set("partyReport")},{"친구 허용",get("allowFriends"),set("allowFriends"),"게임 내 캐릭터 친구 목록에서 이름과 서버가 일치하는 친구입니다. Battle.net 친구는 포함하지 않습니다."},{"길드원 허용",get("allowGuild"),set("allowGuild"),"현재 로드된 길드 명단에서 이름과 서버가 일치하는 길드원입니다."}},party)
  l:Check("길드 초대 자동 거절",guild,function(on) general:SetConvenienceEnabled("declineGuildInvites",on) end,nil,nil,nil,function() return type(DeclineGuild)=="function" end)
  l:Children({{"거절 채팅 알림",get("guildReport"),set("guildReport")}},guild)
  l:Section("채집")
  l:Check("채집 추적 상태 유지",get("keepTracking"),set("keepTracking"),nil,"사용자가 선택한 채광·약초 추적을 부활 후 복원합니다. 직접 끈 추적은 복원하지 않으며 다른 주문 추적이 활성화되어 있으면 복원을 건너뜁니다.",nil,trackingSupported)
  l:Description("이 클라이언트에서는 필요한 채집 추적 API를 사용할 수 없습니다.",function() return not trackingSupported() end)
  l:Children({{"복원 채팅 알림",get("trackingReport"),set("trackingReport")}},get("keepTracking"))
  l:Section("상인·아이템")
  l:Check("상인 판매목록 확장",get("merchantExpanded"),set("merchantExpanded"),nil,"기본 상품 순서를 유지한 4열 × 5행입니다. 상점 변경 애드온과 충돌하면 적용하지 않습니다.")
  l:Description("상점 확장 적용 대기: 전투가 끝나면 적용합니다.",function() return M.merchantPending==true end)
  l:Description(function() return "상점 확장 미적용: "..(M.merchantUnavailable or "") end,function() return db().merchantExpanded and M.merchantUnavailable~=nil end)
  l:Check("이미 습득한 아이템 표시",get("knownItems"),set("knownItems"),nil,"도안은 기본 툴팁의 ‘이미 습득’ 판정, 탈것은 수집 API 또는 같은 기본 툴팁 판정을 사용합니다. 확인할 수 없는 아이템은 표시하지 않습니다.",nil,itemSupported)
  l:Description("이 클라이언트에서는 습득 판정에 필요한 기본 툴팁 API를 사용할 수 없습니다.",function() return not itemSupported() end)
  l:Children({{"도안",get("recipes"),set("recipes")},{"탈것",get("mounts"),set("mounts")}},get("knownItems"),"표시 대상")
  l:Children({{"가방",get("bags"),set("bags")},{"상점",get("merchant"),set("merchant")}},get("knownItems"),"표시 위치")
  return l:Finish()
end
local barModes={{value="default",text="기본 표시"},{value="hide",text="항상 숨김"},{value="hover",text="마우스 오버 시 표시"}}
local textModes={{value="default",text="기본 설정 따름"},{value="hide",text="숨김"},{value="current",text="현재값"},{value="both",text="현재값 / 최대값"},{value="percent",text="백분율"},{value="currentPercent",text="현재값 + 백분율"}}
function KHQOL.modules.basicUI:BuildSettings(parent,y)
  local M=self; local l=layout(parent,y,"basicUI")
  local function db() return M:GetDB() end
  local function set(key) return function(value) db()[key]=value; M:ApplySettings() end end
  l:Description("기본 UI가 비활성화되어 있습니다. 상단의 모듈 사용으로 켤 수 있습니다.",function() return not M:IsEnabled() end)
  l:Description("전투 중 변경은 전투 종료 후 적용합니다.",function() return M.pending==true end)
  l:Section("가방·메뉴바")
  l:Dropdown("가방 버튼 표시 방식",barModes,function() return db().bags end,set("bags"),nil,nil,function() return _G.BagsBar~=nil end)
  l:Dropdown("메뉴바 표시 방식",barModes,function() return db().micro end,set("micro"),nil,nil,function() return _G.MicroMenu~=nil end)
  l:Slider("공통 숨김 지연",0,2,.1,function() return db().hideDelay end,set("hideDelay"),function(v) return string.format("%.1f초",v) end,function() return db().bags=="hover" or db().micro=="hover" end)
  l:Section("유닛 프레임")
  l:Description("기본 프레임 구조를 확인할 수 없는 유닛의 설정은 사용할 수 없습니다.",function() return not M:UnitParts("player") or not M:UnitParts("target") end)
  l:Compare("간결한 프레임 사용","compact",nil,db,M)
  l:Compare("체력 수치 표시 방식","health",textModes,db,M)
  l:Compare("자원 수치 표시 방식","power",textModes,db,M)
  l:Description("공통 CVar를 바꾸지 않으며, 읽을 수 없는 수치는 표시하지 않습니다.")
  return l:Finish()
end
