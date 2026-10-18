local KHQOL = _G.KHQOL
local UI,T=KHQOL.UI,KHQOL.UI.Theme
local function layout(...) return UI:CreateDetailLayout(...) end
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
      check("착용 아이템 레벨 표시",get("equipmentLevels"),set("equipmentLevels"),"캐릭터창의 착용 아이템 아이콘 안쪽 위 중앙에 아이템 레벨 숫자만 표시합니다. 빈 칸·탄약은 제외합니다.",function() return M:EquipmentLevelsSupported() end),
      check("아이템 파괴 자동 입력",legacy("autoConfirmDestroy"),legacySet("autoConfirmDestroy"),"파괴 확인 문구를 자동 입력합니다. 최종 확인은 직접 선택합니다."),
      check("잡템 자동 판매",legacy("autoSellJunk"),legacySet("autoSellJunk"),"상점에서 판매 가능한 회색 아이템을 판매합니다. 퀘스트 아이템과 불확실한 아이템은 제외합니다."),
      check("자동 수리",legacy("autoRepair"),legacySet("autoRepair"),"상점에서 수리 비용을 지불할 수 있을 때 수리합니다.",nil,{
        check("길드 자금 우선 사용",legacy("useGuildFunds"),function(v) G:GetDB().useGuildFunds=v end,"권한·잔액·한도가 충분하면 길드 자금으로, 부족하면 개인 골드로 수리합니다.")}),
      check("이미 습득한 아이템 표시",get("knownItems"),set("knownItems"),"습득 여부가 확인된 도안·탈것에 체크 표시합니다.",supportedItems,{
        check("도안",get("recipes"),set("recipes")),check("탈것",get("mounts"),set("mounts")),
        check("가방",get("bags"),set("bags")),check("상점",get("merchant"),set("merchant"))})}},
    {title="자동 거절",items={
      check("결투 요청",get("declineDuel"),set("declineDuel"),"결투 요청을 자동 거절합니다. 펫 대전·대기열은 제외합니다.",function() return type(CancelDuel)=="function" and type(StaticPopup_FindVisible)=="function" end),
      check("거절 채팅 알림",get("declineReport"),set("declineReport"),"결투 요청·파티 초대·길드 초대의 거절 결과를 공통으로 대화창에 표시합니다."),
      check("길드 초대",guild,legacySet("declineGuildInvites"),"길드 초대를 자동 거절합니다.",function() return type(DeclineGuild)=="function" end),
      check("파티 초대",party,legacySet("declinePartyInvites"),"파티 초대를 자동 거절합니다. 명단을 확인할 수 없으면 초대를 유지합니다. 그룹 찾기·대기열은 제외합니다.",function() return type(DeclineGroup)=="function" and type(StaticPopup_FindVisible)=="function" end,{
        check("친구 허용",get("allowFriends"),set("allowFriends"),"게임 내 캐릭터 친구 목록 기준입니다. Battle.net 친구는 포함하지 않습니다."),
        check("길드원 허용",get("allowGuild"),set("allowGuild"))})}},
    {title="채집",items={check("채집 추적 상태 유지",get("keepTracking"),set("keepTracking"),"직접 선택한 채광·약초 추적을 부활 후 복원합니다. 직접 끈 추적은 복원하지 않습니다.",supportedTracking,{
      check("복원 채팅 알림",get("trackingReport"),set("trackingReport"))})}},
    {title="상점",items={check("상인 판매목록 확장",get("merchantExpanded"),set("merchantExpanded"),"기본 순서대로 4열 × 5행으로 확장합니다. 상점 변경 애드온과 충돌하면 적용하지 않습니다.")}},
  }
  local page=CreateFrame("Frame",nil,parent); page:SetPoint("TOPLEFT",0,y); page:SetWidth(parent:GetWidth())
  local step=T.RowHeight+T.RowGap
  local refresh
  for _,section in ipairs(sections) do
    section.frame=CreateFrame("Frame",nil,page); section.frame:SetWidth(page:GetWidth())
    section.group=UI:CreateSettingsAccordion(section.frame,section.title,UI:SettingsAccordionID(parent,section.title),function() refresh();UI:RefreshAccordionLayout(parent) end,nil,true)
    section.group.row:SetPoint("TOPLEFT",0,-T.SectionGap)
    section.body=CreateFrame("Frame",nil,section.frame);section.body.settingsDisclosure=section.group
    section.body:SetWidth(page:GetWidth())
    section.measure={}
    for _,item in ipairs(section.items) do
      local cell=CreateFrame("Frame",nil,section.body); cell:SetWidth(page:GetWidth()); item.cell=cell; item.controls={}
      section.measure[#section.measure+1]=item
      local c=UI:CreateCheckbox(cell,item.title,0,0,item.get,item.set,item.enabled)
      UI:AttachTooltip(c,item.title,item.tip); item.controls[1]=c
      for index,child in ipairs(item.children) do
        section.measure[#section.measure+1]=child
        local function enabled() return item.get() and (not item.enabled or item.enabled()) end
        local childColumn=item.title=="이미 습득한 아이템 표시" and (index-1)%2 or 0
        local childRow=item.title=="이미 습득한 아이템 표시" and math.floor((index-1)/2)+1 or index
        if section.title=="자동 거절" then childColumn=index;childRow=0 end
        local control=UI:CreateCheckbox(cell,child.title,childColumn*100,-childRow*step,child.get,child.set,enabled)
        control.childColumn,control.childRow=childColumn,childRow
        UI:AttachTooltip(control,child.title,child.tip); item.controls[#item.controls+1]=control
      end
      cell:SetHeight((item.title=="이미 습득한 아이템 표시" and 3 or #item.controls)*step)
      if section.title=="자동 거절" then cell:SetHeight(step) end
    end
  end
  local status=UI:CreateDescription(page,"",0,0)
  refresh=function()
    local top=0; local width=math.min(T.FormMaxWidth,parent:GetWidth());page:SetWidth(width)
    for _,section in ipairs(sections) do
      local f=section.frame;f:ClearAllPoints();f:SetPoint("TOPLEFT",0,top);f:SetWidth(width)
      section.group.row:SetWidth(width);section.group:Refresh()
      local headerHeight=T.SectionGap+section.group.row:GetHeight()+T.RowGap
      section.body:SetPoint("TOPLEFT",0,-headerHeight);section.body:SetWidth(width)
      local expanded=UI.disclosureStates[section.group.id];section.body:SetShown(expanded)
      local columns=width<T.CheckTwoColumnWidth and 1 or 2
      for _,item in ipairs(section.items) do for _,control in ipairs(item.controls) do
        control.text:SetWidth(width)
        if control.text:GetStringWidth()+T.CheckboxSize+T.CheckboxLabelGap+T.ContentPadding>(width-T.ColumnGap)/2 then columns=1 end
      end end
      section.columns=columns
      local cellWidth=(width-(columns-1)*T.ColumnGap)/columns
      local rowTop=0;local rowHeight=0
      for index,item in ipairs(section.items) do
        local column=(index-1)%columns
        if column==0 and index>1 then rowTop=rowTop-rowHeight;rowHeight=0 end
        item.cell:ClearAllPoints();item.cell:SetPoint("TOPLEFT",column*(cellWidth+T.ColumnGap),rowTop);item.cell:SetWidth(cellWidth)
        local childTop=0
        for ci,control in ipairs(item.controls) do
          local indent=ci>1 and T.ContentPadding or 0
          control.text:SetWidth(math.max(40,cellWidth-indent-T.CheckboxSize-T.CheckboxLabelGap));control.text:SetWordWrap(true)
          control:ClearAllPoints();control:SetPoint("TOPLEFT",indent,childTop)
          childTop=childTop-math.max(step,control.text:GetStringHeight()+12)
        end
        item.cell:SetHeight(-childTop);rowHeight=math.max(rowHeight,-childTop)
      end
      section.body:SetHeight(-rowTop+rowHeight)
      f:SetHeight(headerHeight+(expanded and section.body:GetHeight() or 0));top=top-f:GetHeight()
    end
    local text=M.merchantPending and "상점 확장: 전투가 끝나면 적용합니다." or (M:GetDB().merchantExpanded and M.merchantUnavailable and "상점 확장 미적용: "..M.merchantUnavailable or "")
    status:ClearAllPoints();status:SetPoint("TOPLEFT",0,top-6); status:SetWidth(width); status:SetText(text)
    top=top-step*2 -- Reserve a stable two-line status area on OFF/ON.
    page:SetHeight(-top); parent:SetHeight(-y-top)
  end
  local sentinel=CreateFrame("Frame",nil,page); sentinel.Refresh=refresh; sentinel.layoutRefresh=true
  UI:RegisterControl(page,sentinel); refresh()
  parent.generalSections=sections
  return y-page:GetHeight()
end
