local _, KHQOL = ...
local Lab=KHQOL.UI:NewSettingsGroup("labs")
KHQOL.LabSettings=Lab
local function proc(content,y)
  if not KHQOL.LabLock:IsUnlocked() then return KHQOL.LabLock:BuildLockedSettings(content,y) end
  local P,UI,T=KHQOL.modules.procAlert,KHQOL.UI,KHQOL.UI.Theme
  P:GetDB(); P.settingsContent=content; content.moduleKey="procAlert"
  local class=select(2,UnitClass("player")) or "WARRIOR"
  local b=UI:CreateBuilder(content,y)
  local function enabled() return P:IsEnabled() end
  b:Section("발동 알림")
  b:Description("등록한 버프가 전투 중 활성화되면 곡선형 HUD로 표시합니다.")
  b:Section("등록된 버프")
  local options={}
  for _,token in ipairs({"WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","SHAMAN","MAGE","WARLOCK","DRUID","DEATHKNIGHT","MONK","DEMONHUNTER","EVOKER"}) do
    if LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[token] then
      options[#options+1]={value=token,text=LOCALIZED_CLASS_NAMES_MALE[token]}
    end
  end
  if #options==0 then options={{value=class,text=class}} end
  local list=CreateFrame("Frame",nil,content); list:SetWidth(T.ContentWidth); list.uiControls={}
  local editor=CreateFrame("Frame",nil,content); editor:SetWidth(T.ContentWidth); editor:Hide()
  local lower=CreateFrame("Frame",nil,content); lower:SetWidth(T.ContentWidth)
  local rows,draft,original,editingClass={},nil,nil,nil
  local refreshList,reflow
  local function closeEditor()
    if ColorPickerFrame then ColorPickerFrame:Hide() end
    draft=nil; original=nil; editingClass=nil; editor:Hide()
    reflow()
  end
  b:Dropdown("클래스",options,function() return class end,function(v) class=v; closeEditor(); refreshList() end)
  local function openEditor(id)
    if ColorPickerFrame then ColorPickerFrame:Hide() end
    original=id; editingClass=class
    draft=id and KHQOL.CopyProfileValue(P:GetBuffs(class)[id]) or {
      spellID="",name="",enabled=true,side="LEFT",slot=1,color={r=.1,g=.6,b=1,a=1},priority="NORMAL",showIcon=true,showName=false,showTime=true}
    editor:Show(); UI:Refresh(editor); reflow()
  end
  b:Button("+ 버프 추가",function() openEditor() end,nil,enabled); b:Flush()
  local listY=b.y
  local e=UI:CreateBuilder(editor,0)
  local function editing() return draft~=nil and enabled() end
  local function field(key) return draft and draft[key] end
  local function set(key,v) if draft then draft[key]=v end end
  e:Section("버프 정보")
  local idInput=e:Edit("Spell ID",function() return field("spellID") end,function(v) set("spellID",v) end,editing)
  idInput:SetMaxLetters(10)
  local nameInput=e:Edit("버프 이름",function() return field("name") end,function(v) set("name",v) end,editing)
  nameInput:SetMaxLetters(100)
  idInput:HookScript("OnTextChanged",function(box,userInput) if userInput then set("spellID",box:GetText()) end end)
  nameInput:HookScript("OnTextChanged",function(box,userInput) if userInput then set("name",box:GetText()) end end)
  local message
  local function lookup()
    if not draft then return end
    draft.spellID=idInput:GetText(); draft.name=nameInput:GetText()
    local id=tonumber(draft.spellID)
    local name,icon
    if id and id>0 and id==math.floor(id) then name,icon=P:GetSpellDetails(id) end
    if name then draft.name=name; draft.icon=icon; message:SetText("주문 이름과 아이콘을 조회했습니다.")
    else message:SetText("주문 조회 실패: 기존 입력을 유지합니다. ID와 이름을 확인하세요.") end
    UI:Refresh(editor)
  end
  e:Button("이름 / 아이콘 조회",lookup,nil,editing)
  e:Flush()
  local icon=editor:CreateTexture(nil,"ARTWORK"); icon:SetSize(30,30); icon:SetPoint("TOPLEFT",0,e.y)
  message=UI:CreateDescription(editor,"Spell ID 입력 후 조회하세요. 자동 조회 실패 시 이름을 직접 입력할 수 있습니다.",42,e.y)
  message:SetWidth(T.ContentWidth-42); e.y=e.y-54
  editor.uiControls=editor.uiControls or {}
  editor.uiControls[#editor.uiControls+1]={Refresh=function() icon:SetTexture(draft and draft.icon or "Interface\\Icons\\INV_Misc_QuestionMark") end}
  e:Checkbox("사용",function() return field("enabled") end,function(v) set("enabled",v) end,editing)
  e:Dropdown("HUD 위치",{{value="LEFT",text="왼쪽"},{value="RIGHT",text="오른쪽"}},function() return field("side") end,function(v) set("side",v) end,editing)
  e:Dropdown("우선순위",{{value="HIGH",text="높음"},{value="NORMAL",text="보통"},{value="LOW",text="낮음"}},function() return field("priority") end,function(v) set("priority",v) end,editing)
  e:Color("HUD 색상",function()
    local c=draft and draft.color or {r=1,g=1,b=1,a=1}; return c.r,c.g,c.b,c.a
  end,function(r,g,b,a) if draft then draft.color={r=r,g=g,b=b,a=a} end end,editing,nil,true)
  e:Section("표시")
  for _,item in ipairs({{"showIcon","아이콘"},{"showName","버프 이름"},{"showTime","남은 시간"}}) do
    local key,title=item[1],item[2]
    e:Checkbox(title,function() return field(key) end,function(v) set(key,v) end,editing)
  end
  local function save()
    if not draft then return end
    local id=tonumber(idInput:GetText()); local name=nameInput:GetText()
    if not id or id<=0 or id~=math.floor(id) or id>2147483647 then message:SetText("유효한 양의 정수 Spell ID를 입력하세요."); return end
    local buffs=P:GetBuffs(editingClass)
    if buffs[id] and id~=original then message:SetText("이 클래스에 이미 등록된 Spell ID입니다."); return end
    local resolved,texture=P:GetSpellDetails(id)
    if resolved then name=resolved end
    if name=="" then message:SetText("주문 조회 실패: 버프 이름을 입력하세요."); return end
    local record=KHQOL.CopyProfileValue(draft)
    record.name=name; record.icon=texture or (tonumber(record.spellID)==id and record.icon or nil)
    P:Normalize(record,id)
    if original and original~=id then buffs[original]=nil end
    buffs[id]=record; closeEditor(); P:Changed(); refreshList()
  end
  e:Button("저장",save,nil,editing); e:Button("취소",closeEditor)
  e:Flush(); editor:SetHeight(-e.y+T.SectionGap)
  idInput:SetScript("OnEnterPressed",function() lookup(); idInput:ClearFocus() end)
  idInput:HookScript("OnEditFocusLost",lookup)
  local l=UI:CreateBuilder(lower,0)
  l:Section("HUD")
  l:Checkbox("위치 잠금",function() return not P.unlocked end,function(v) P:SetUnlocked(not v) end,enabled)
  local function slider(title,key,lo,hi,step)
    l:Slider(title,lo,hi,step,function() return P:GetDB().hud[key] end,function(v) P:GetDB().hud[key]=v; P:Changed() end,
      function(v) return string.format(step<1 and "%.2f" or "%d",v) end,enabled)
  end
  slider("전체 크기","scale",.5,2,.05); slider("곡선 높이","size",100,600,5)
  slider("좌우 간격","spacing",80,800,5); slider("투명도","alpha",.1,1,.05)
  slider("X 위치","x",-1500,1500,1); slider("Y 위치","y",-1000,1000,1)
  l:Button("위치 기본값 복원",function() local h=P:GetDB().hud; h.x=0; h.y=-180; h.spacing=280; P:Changed() end,nil,enabled)
  l:Section("표시")
  l:Checkbox("HUD 애니메이션",function() return P:GetDB().animation end,function(v) P:GetDB().animation=v; P:Changed() end,enabled)
  l:Description("아이콘·이름·남은 시간 및 색상은 버프별 편집에서 설정합니다. 시간 정보가 없으면 활성 상태만 표시합니다.")
  l:Section("충돌 / 우선순위")
  l:Description("각 방향에 하나를 표시합니다. 높은 우선순위 → 먼저 활성화 → 낮은 Spell ID 순으로 선택합니다. 표시 중인 버프가 끝나면 다음 활성 버프로 전환합니다.")
  l:Section("테스트")
  l:Button("HUD 테스트 (8초)",function() P:Test() end,nil,enabled)
  l:Button("테스트 종료",function() P.testUntil=nil; P:Render() end,nil,enabled)
  l:Section("기본값 복원")
  l:Description("현재 프로필의 HUD 설정과 애니메이션을 복원합니다. 클래스별 등록 버프는 유지합니다.")
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
    for id,record in pairs(P:GetBuffs(class)) do if P:Normalize(record,id) then records[#records+1]=record end end
    table.sort(records,function(a,b) return a.spellID<b.spellID end)
    for i,record in ipairs(records) do
      local row=rows[i]
      if not row then
        row=CreateFrame("Frame",nil,list); rows[i]=row; row.record=record; row:SetWidth(T.ContentWidth); row:SetHeight(82)
        row.icon=row:CreateTexture(nil,"ARTWORK"); row.icon:SetSize(28,28); row.icon:SetPoint("TOPLEFT",0,-6)
        row.check=UI:CreateCheckbox(row,"",40,-6,function() return row.record.enabled end,function(on) row.record.enabled=on; P:Changed() end,enabled)
        row.check.text:SetWidth(270)
        row.info=UI:CreateDescription(row,"",40,-36); row.info:SetWidth(T.ContentWidth-150)
        row.swatch=row:CreateTexture(nil,"ARTWORK"); row.swatch:SetSize(14,14); row.swatch:SetPoint("TOPRIGHT",-120,-12)
        UI:CreateButton(row,"편집",T.ContentWidth-102,-6,48,function() openEditor(row.record.spellID) end,enabled)
        UI:CreateButton(row,"삭제",T.ContentWidth-50,-6,48,function()
          P:GetBuffs(class)[row.record.spellID]=nil; closeEditor(); P:Changed(); refreshList()
        end,enabled)
      end
      row.record=record; row:ClearAllPoints(); row:SetPoint("TOPLEFT",0,-(i-1)*82)
      row.icon:SetTexture(record.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
      row.check.text:SetText(record.name)
      local labels={HIGH="높음",NORMAL="보통",LOW="낮음"}
      row.info:SetText("Spell ID: "..record.spellID.."\n"..(record.side=="LEFT" and "왼쪽" or "오른쪽").." HUD · 우선순위 "..labels[record.priority])
      local c=record.color; row.swatch:SetColorTexture(c.r,c.g,c.b,1); row:Show(); UI:Refresh(row)
    end
    for i=#records+1,#rows do rows[i]:Hide() end
    if not list.empty then list.empty=UI:CreateDescription(list,"등록된 버프가 없습니다. Spell ID로 버프를 추가하세요.",0,-6) end
    list.empty:SetShown(#records==0); list:SetHeight(math.max(40,#records*82)); reflow()
  end
  list.uiControls[1]={Refresh=refreshList}
  content:HookScript("OnHide",function() P:SetUnlocked(false); P.testUntil=nil; P:Render(); closeEditor() end)
  refreshList()
  return -content:GetHeight()
end
Lab:RegisterTab("proc",nil,proc)

Lab:RegisterTab("highlight",nil,function(content,y)
  if not KHQOL.LabLock:IsUnlocked() then return KHQOL.LabLock:BuildLockedSettings(content,y) end
  local H,UI=KHQOL.modules.objectHighlight,KHQOL.UI
  content.moduleKey="objectHighlight"
  local b=UI:CreateBuilder(content,y)
  b:Section("동작 설명")
  b:Description("전리품이 있는 퀘스트 오브젝트의 반짝임을 유지하도록 게임 그래픽 설정을 조정합니다. 반짝임 유지를 위해 일반·공격대 윤곽선 모드가 변경됩니다.")
  b:Section("주의사항")
  b:Description("개발 중인 실험 기능입니다. 클라이언트 또는 API 변경으로 동작하지 않을 수 있습니다.")
  b:Description("해제 후 효과가 사라지려면 게임 재시작이 필요할 수 있습니다. /reload만으로 해제 표시가 완료되지 않을 수 있습니다.")
  b:Description("Forever Loot Sparkles와 중복 사용할 수 없습니다. 해당 애드온이 로드되어 있으면 적용·복원을 보류하고 복원 기록을 유지합니다.")
  b:Section("현재 적용 상태")
  local statusY=b.y
  H.statusText=UI:CreateDescription(content,H:GetStatus(),0,statusY)
  H.statusText:SetWidth(UI.Theme.ContentWidth)
  function H:RefreshStatus()
    H.statusText:SetHeight(0);H.statusText:SetText(H:GetStatus())
    content:SetHeight(-statusY+math.max(54,H.statusText:GetStringHeight())+UI.Theme.ContentPadding)
  end
  content.uiControls[#content.uiControls+1]={Refresh=function() H:RefreshStatus() end}
  content.uiControls[#content.uiControls]:Refresh()
  return -content:GetHeight()
end)

Lab:RegisterTab("inspector",nil,function(content,y) return KHQOL.modules.frameInspector:BuildSettings(content,y) end)
