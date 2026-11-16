local K=_G.KHQOL
local M=K.modules.generalConvenience
local UI,T=K.UI,K.UI.Theme
local fallbackColors={{.62,.62,.62},{1,1,1},{.12,1,0},{0,.44,.87},{.64,.21,.93}}

function M:BuildBagItemSettings(frame)
  self.protectionPanel=frame
  local function db() return self:GetDB().bagTrash end
  local function enabled() return db().enabled end
  local function free() return enabled() and db().mode=="free" end
  local function apply() self:RefreshBagTrash() end
  local function setMode(v)
    K.PositionStore:FinishFrameDrag(self.trashButton)
    db().mode=v;apply()
  end
  local label=UI:CreateLabel(frame,"가방 휴지통",0,0)
  local toggle=UI:CreateCheckbox(frame,"가방 휴지통 사용",0,0,enabled,function(v) db().enabled=v;apply() end)
  local mode=UI:CreateDropdown(frame,0,0,180,{{value="attached",text="가방 창에 붙이기"},{value="free",text="화면에 직접 배치"}},
    function() return db().mode end,setMode,enabled)
  UI.SettingsNavigation:Attach(frame,mode,"휴지통 배치",function() return db().mode end,setMode,enabled)
  local lock=UI:CreateCheckbox(frame,"위치 잠금",0,0,function() return db().locked end,function(v)
    K.PositionStore:FinishFrameDrag(self.trashButton);db().locked=v
  end,free)
  local move=UI:CreateButton(frame,"휴지통 위치 편집",0,0,150,function()
    if db().mode~="free" then
      local region=self.trashBaganatorButton and self.trashBaganatorButton:IsVisible() and self.trashBaganatorButton or self.trashButton
      local x,y=K.PositionStore:Center(region)
      local cx,cy=K.PositionStore:Screen()
      if x and cx and region:IsVisible() then
        db().position={point="CENTER",relativePoint="CENTER",x=x-cx,y=y-cy}
      end
      db().mode="free";apply();K:SaveCurrentProfile()
    end
    K.PositionEditor:Enter("bagTrash")
  end,enabled)
  move.navigationOnly=true
  local size,box=UI:CreateSlider(frame,"휴지통 아이콘 크기","",0,0,20,64,1,function() return db().size end,
    function(v) db().size=v;apply() end,function(v) return v.." px" end,enabled)
  local sizeLabel=size.tooltipLabel
  sizeLabel:SetWordWrap(false)
  local qualityTitle=UI:CreateLabel(frame,"확인 없이 파괴할 등급",0,0)
  local qualityChecks={}
  for i,quality in ipairs(self.bagTrashQualities) do
    local key,title=quality[1],quality[2]
    local check=UI:CreateCheckbox(frame,title,0,0,function() return db().qualities[key] end,
      function(v) db().qualities[key]=v end)
    local r,g,b=K.PublicCall(C_Item and C_Item.GetItemQualityColor,i-1)
    if not K.IsPublicNumber(r) or not K.IsPublicNumber(g) or not K.IsPublicNumber(b) then
      r,g,b=unpack(fallbackColors[i])
    end
    check.text:SetTextColor(r,g,b)
    qualityChecks[i]=check
  end
  local inactiveQuest=UI:CreateCheckbox(frame,"퀘스트 분류 일반 아이템도 즉시 파괴",0,0,
    function() return db().allowInactiveQuestItems end,function(v) db().allowInactiveQuestItems=v end)
  UI:AttachTooltip(inactiveQuest,"퀘스트 분류 일반 아이템도 즉시 파괴",
    "진행 중인 퀘스트와 연결되지 않은 것으로 확인된 아이템에만 적용합니다. 위에서 선택한 등급에 해당해야 합니다.")
  local fallback=UI:CreateDescription(frame,
    "비전투 중에는 선택한 등급을 놓는 순간 파괴를 시도합니다. 전투 중이거나 게임에서 추가 확인을 요구하면 기본 확인창을 사용합니다.",0,0)
  local protect=UI:CreateLabel(frame,"아이템 보호",0,0)
  local guide=UI:CreateDescription(frame,
    "게임 단축키 → KHQOL → 가방 아이템 보호 / 해제에 키를 지정하고 가방 아이템 위에서 누르세요. 결과는 채팅창에 표시되고 보호한 아이템은 툴팁과 목록에서 확인할 수 있습니다. 같은 아이템 ID 전체에 계정 공용으로 적용됩니다.",0,0)
  local limits=UI:CreateDescription(frame,
    "가방 휴지통과 KHQOL 자동 판매에서 제외합니다. 우편 첨부는 감지 후 경고합니다. 기본 상점 수동 판매·기본 일괄 판매·우편 첨부/발송·Baganator 판매/전송 버튼은 보호 목록으로 차단할 수 없습니다.",0,0)
  local selected
  local function options()
    local result={}
    for id,link in pairs(self:GetProtectedItems()) do
      local name=type(link)=="string" and link:match("|h%[(.-)%]|h") or tostring(id)
      result[#result+1]={value=id,text=(name or tostring(id)).." ("..id..")"}
    end
    table.sort(result,function(a,b) return a.text<b.text end)
    local caption=#result==0 and "보호한 아이템 없음" or ("보호 목록 (%d)"):format(#result)
    table.insert(result,1,{value=0,text=caption,disabled=true})
    return result
  end
  local function hasItems() return next(self:GetProtectedItems())~=nil end
  local function selection() return selected and self:IsProtectedBagItem(selected) and selected or 0 end
  local function selectItem(v) selected=v end
  local list=UI:CreateDropdown(frame,0,0,240,options,selection,selectItem,hasItems)
  UI.SettingsNavigation:Attach(frame,list,"보호 목록 관리",selection,selectItem,hasItems)
  local remove=UI:CreateButton(frame,"선택 보호 해제",0,0,145,function()
    local id=selected;selected=nil;self:SetBagItemProtection(id)
  end,function() return selected and self:IsProtectedBagItem(selected) end)

  local function put(region,x,y)
    region:ClearAllPoints();region:SetPoint("TOPLEFT",frame,"TOPLEFT",x,y)
  end
  local function paragraph(region,top,width)
    put(region,0,top);region:SetWidth(width);region:SetWordWrap(true)
    return top-math.max(18,region:GetStringHeight())-T.RowGap
  end
  return function(width)
    frame:SetWidth(width)
    local row=T.RowHeight+T.RowGap
    put(label,0,0)
    put(toggle,0,-25);put(mode,width*.5,-25);mode:FitDropdownWidth(width*.5)
    put(lock,0,-25-row);put(move,width*.5,-25-row)
    local top=-27-2*row
    put(sizeLabel,0,top);sizeLabel:SetWidth(width)
    put(size,0,top-24);put(box,T.SliderWidth+14,top-20)
    top=top-60
    put(qualityTitle,0,top);top=top-25
    for i,check in ipairs(qualityChecks) do
      local cell=width/5
      put(check,(i-1)*cell,top)
      check.text:SetWidth(math.max(22,cell-T.CheckboxSize-T.CheckboxLabelGap-3))
    end
    top=top-row
    put(inactiveQuest,0,top)
    inactiveQuest.text:SetWidth(width-T.CheckboxSize-T.CheckboxLabelGap)
    top=paragraph(fallback,top-math.max(row,inactiveQuest.text:GetStringHeight()+T.RowGap),width)
    put(protect,0,top);top=top-25
    top=paragraph(guide,top,width)
    top=paragraph(limits,top,width)
    put(list,0,top);list:FitDropdownWidth(width*.62)
    put(remove,width*.64,top)
    local height=-top+math.max(list:GetHeight(),remove:GetHeight())+T.RowGap
    frame:SetHeight(height)
    return height
  end
end
