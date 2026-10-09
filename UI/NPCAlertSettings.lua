local _, KHQOL = ...
local N,UI=KHQOL.modules.npcAlert,KHQOL.UI
local function build(content,y)
  local T=UI.Theme; N:GetDB(); N.settingsContent=content; content.moduleKey="npcAlert"
  local b=UI:CreateBuilder(content,y)
  local function enabled() return N:IsEnabled() end
  b:Section("NPC 알림")
  b:Description("등록한 위험 NPC가 현재 지역에서 감지되면 화면 경고와 위험 방향을 표시합니다.")
  b:Description("현재 클라이언트에 보이는 NamePlate·대상·마우스오버만 감지합니다. 비공개 정보는 감지할 수 없으며, 위치를 읽을 수 없으면 방향을 표시하지 않습니다.")
  b:Section("현재 지역")
  local region=b:Description("")
  content.uiControls[#content.uiControls+1]={Refresh=function()
    local map,name=N:CurrentMap(); region:SetText((name or "지역 확인 불가").." · Map ID: "..(map or "확인 불가"))
  end}
  b:Section("등록된 위험 NPC")
  local list=CreateFrame("Frame",nil,content); list:SetWidth(T.ContentWidth); list.uiControls={}
  local editor=CreateFrame("Frame",nil,content); editor:SetWidth(T.ContentWidth); editor:Hide()
  local lower=CreateFrame("Frame",nil,content); lower:SetWidth(T.ContentWidth)
  local rows,draft,editingID={},nil,nil
  local reflow,refreshList
  local function close() draft=nil; editingID=nil; editor:Hide(); reflow() end
  local function open(key)
    editingID=key
    draft=key and KHQOL.CopyProfileValue(N:GetData().entries[key]) or
      {mapID=N.mapID or "",npcID="",name="",enabled=true,dangerLevel="HIGH",showBanner=true,showIndicator=true,sound=true}
    if not draft.npcID then draft.npcID="" end
    editor:Show(); UI:Refresh(editor); reflow()
  end
  b:Button("+ NPC 추가",function() open() end,nil,enabled)
  b:Button("현재 Map ID 사용",function()
    local map=N:CurrentMap(); if not map then return end
    if not draft then open() end; draft.mapID=map; UI:Refresh(editor)
  end,nil,enabled)
  b:Flush(); local listY=b.y
  local e=UI:CreateBuilder(editor,0)
  local function editing() return draft~=nil and enabled() end
  local function field(title,key)
    local box=e:Edit(title,function() return draft and draft[key] end,function(v) if draft then draft[key]=v end end,editing)
    box:SetMaxLetters(key=="name" and 100 or 10)
    box:HookScript("OnTextChanged",function(input,user) if user and draft then draft[key]=input:GetText() end end)
    return box
  end
  e:Section("NPC 정보")
  local mapBox=field("Map ID","mapID"); local npcBox=field("NPC ID (선택)","npcID"); local nameBox=field("NPC 이름","name")
  e:Description("NPC ID를 입력하면 ID로만 판정합니다. ID를 비우면 이름으로 판정하므로 같은 이름의 다른 NPC를 감지할 수 있습니다.")
  e:Checkbox("사용",function() return draft and draft.enabled end,function(v) if draft then draft.enabled=v end end,editing)
  e:Dropdown("위험도",{{value="NORMAL",text="보통"},{value="HIGH",text="높음"},{value="CRITICAL",text="치명적"}},
    function() return draft and draft.dangerLevel end,function(v) if draft then draft.dangerLevel=v end end,editing)
  for _,item in ipairs({{"showBanner","중앙 위험 배너"},{"showIndicator","Danger Indicator"},{"sound","사운드"}}) do
    local key,title=item[1],item[2]
    e:Checkbox(title,function() return draft and draft[key] end,function(v) if draft then draft[key]=v end end,editing)
  end
  e:Flush(); local message=UI:CreateDescription(editor,"",0,e.y); e.y=e.y-44
  local function positive(text)
    local value=tonumber(text); if value and value>0 and value%1==0 and value<=2147483647 then return value end
  end
  e:Button("저장",function()
    if not draft then return end
    local map=positive(mapBox:GetText()); local raw=npcBox:GetText():match("^%s*(.-)%s*$")
    local npc=raw~="" and positive(raw) or nil
    local name=nameBox:GetText():gsub("^[ \t\r\n]+",""):gsub("[ \t\r\n]+$","")
    if not map then message:SetText("유효한 Map ID를 입력하세요."); return end
    if raw~="" and not npc then message:SetText("NPC ID는 양의 정수 또는 빈칸이어야 합니다."); return end
    if name=="" or name:find("[%z\1-\31|]") then message:SetText("표시할 NPC 이름을 입력하세요. 제어 문자와 |는 사용할 수 없습니다."); return end
    local data=N:GetData()
    for key,r in pairs(data.entries) do
      if key~=editingID and r.mapID==map and (npc and r.npcID==npc or not npc and not r.npcID and r.name==name) then
        message:SetText("같은 지역에 이미 등록된 NPC입니다."); return
      end
    end
    local record=KHQOL.CopyProfileValue(draft); record.mapID=map; record.npcID=npc; record.name=name; N:Normalize(record)
    local key=editingID
    if not key then key=data.nextID; while data.entries[key] do key=key+1 end; data.nextID=key+1 end
    data.entries[key]=record; close(); N:Changed(); refreshList()
  end,nil,editing)
  e:Button("취소",close); e:Flush(); editor:SetHeight(-e.y+T.SectionGap)
  local l=UI:CreateBuilder(lower,0)
  local function check(title,key,group)
    l:Checkbox(title,function() return group()[key] end,function(v) group()[key]=v; N:Changed() end,enabled)
  end
  local function db() return N:GetDB() end
  local function indicator() return N:GetDB().indicator end
  local function slider(title,key,lo,hi,step,group)
    l:Slider(title,lo,hi,step,function() return group()[key] end,function(v) group()[key]=v; N:Changed() end,
      function(v) return string.format(step<1 and "%.2f" or "%d",v) end,enabled)
  end
  l:Section("경고 설정")
  check("중앙 위험 배너 사용","banner",db)
  slider("배너 표시 시간","bannerDuration",1,10,1,db)
  slider("배너 크기","bannerScale",.5,2,.05,db); slider("배너 투명도","bannerAlpha",.1,1,.05,db)
  l:Section("Danger Indicator")
  check("위험 방향 표시","enabled",indicator)
  slider("크기","size",24,128,1,indicator); slider("중심 거리","radius",40,500,5,indicator)
  slider("투명도","alpha",.1,1,.05,indicator)
  l:Description("화면 중심에서 NamePlate 방향을 가리킵니다. 월드 위치나 야드 거리를 표시하지 않습니다.")
  l:Section("사운드")
  check("위험 NPC 발견 시 사운드","sound",db)
  l:Description("최초 발견 시 기존 경고 SOUNDKIT을 Master 채널로 한 번 재생합니다. NPC별 사운드 설정도 함께 적용합니다.")
  l:Section("반복 경고")
  slider("재경고 대기시간 (초)","reAlertCooldown",1,300,1,db)
  l:Description("같은 GUID가 계속 감지되면 재경고하지 않습니다. 사라졌다가 다시 감지된 경우에만 대기시간을 확인합니다.")
  l:Section("테스트")
  l:Button("NPC 경고 테스트",function() N:Test() end,nil,enabled)
  l:Button("테스트 종료",function() N:StopTest() end,nil,enabled)
  l:Description("오른쪽 위 방향의 HIGH NPC를 5초간 미리 봅니다. 테스트 배너·방향은 표시 옵션과 무관하게 미리 보며, 사운드는 전체 사운드 옵션을 따릅니다.")
  l:Section("기본값 복원")
  l:Description("현재 프로필의 경고 옵션만 복원합니다. 등록된 NPC 목록은 유지합니다.")
  lower:SetHeight(-l.y)
  reflow=function()
    list:ClearAllPoints(); list:SetPoint("TOPLEFT",0,listY)
    local nextY=listY-list:GetHeight()-T.SectionGap
    editor:ClearAllPoints(); editor:SetPoint("TOPLEFT",0,nextY)
    if editor:IsShown() then nextY=nextY-editor:GetHeight() end
    lower:ClearAllPoints(); lower:SetPoint("TOPLEFT",0,nextY)
    content:SetHeight(-nextY+lower:GetHeight()+T.ContentPadding)
  end
  refreshList=function()
    local records={}
    for key,r in pairs(N:GetData().entries) do if type(key)=="number" and N:Normalize(r) then records[#records+1]={key=key,r=r} end end
    table.sort(records,function(a,b) if a.r.mapID~=b.r.mapID then return a.r.mapID<b.r.mapID end; return a.key<b.key end)
    for i,item in ipairs(records) do
      local row=rows[i]
      if not row then
        row=CreateFrame("Frame",nil,list); rows[i]=row; row.record=item.r; row.key=item.key; row:SetSize(T.ContentWidth,102)
        row.check=UI:CreateCheckbox(row,"",0,-4,function() return row.record.enabled end,function(v) row.record.enabled=v; N:Changed() end,enabled)
        row.check.text:SetWidth(T.ContentWidth-160)
        row.check.text:SetWordWrap(false); row.check.text:SetHeight(T.LabelFontSize+6)
        row.info=UI:CreateDescription(row,"",34,-34); row.info:SetWidth(T.ContentWidth-150)
        row.color=row:CreateTexture(nil,"ARTWORK"); row.color:SetSize(12,12); row.color:SetPoint("TOPRIGHT",-120,-10)
        UI:CreateButton(row,"편집",T.ContentWidth-102,-4,48,function() message:SetText(""); open(row.key) end,enabled)
        UI:CreateButton(row,"삭제",T.ContentWidth-50,-4,48,function() N:GetData().entries[row.key]=nil; close(); N:Changed(); refreshList() end,enabled)
      end
      row.record=item.r; row.key=item.key; row:ClearAllPoints(); row:SetPoint("TOPLEFT",0,-(i-1)*102)
      local r=item.r; row.check.text:SetText(r.name)
      local function on(v) return v and "ON" or "OFF" end
      row.info:SetText("NPC ID: "..(r.npcID or "이름 기반").." · Map ID: "..r.mapID.." · 위험도: "..N.labels[r.dangerLevel]..
        "\n배너 "..on(r.showBanner).." · 방향 "..on(r.showIndicator).." · 사운드 "..on(r.sound))
      row.color:SetColorTexture(unpack(N.colors[r.dangerLevel])); row:Show(); UI:Refresh(row)
    end
    for i=#records+1,#rows do rows[i]:Hide() end
    if not list.empty then list.empty=UI:CreateDescription(list,"등록된 NPC가 없습니다. Map ID와 NPC ID 또는 이름으로 등록하세요.",0,-6) end
    list.empty:SetShown(#records==0); list:SetHeight(math.max(40,#records*102)); reflow()
  end
  list.uiControls[1]={Refresh=refreshList}
  content:HookScript("OnHide",function() if N.testing then N:StopTest() end; close() end)
  refreshList(); UI:Refresh(content)
  return -content:GetHeight()
end
KHQOL.AlertSettings:RegisterTab("npc",nil,build)
