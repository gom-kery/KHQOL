local U=_G.KHQOLDevUsage
local Dev=_G.KHQOL_DevTools
local range,full=7,false
local panel,text,toggle,period,view
local function lineValue(snapshot,id)
  local meta=snapshot.instrumentation[id]
  if meta.observedDays==0 then
    return meta.class=="HOLD" and "보류 · 미계측" or meta.connected and "연결됨 · 관찰 자료 없음" or "미연결 · 미계측"
  end
  local b=snapshot.totals[meta.kind][id]
  if meta.kind=="menus" then
    b=b or {};return string.format("%d회 · 누적 %.1f초 · 평균 %.1f초 / 유효 표본 %d",b.visits or 0,b.seconds or 0,b.averageSeconds or 0,b.validVisits or 0)
  elseif meta.kind=="settings" then return string.format("%d회",b and b.changes or 0)
  elseif id:find("feature.active.",1,true)==1 then return string.format("%d일",b and b.activeDays or 0)
  else return string.format("%d회",b and b.count or 0) end
end
function U:FormatReport(snapshot,all)
  local lines={"Usage Analytics v"..self.VERSION.." · DevTools v"..self.DEV_VERSION.." · 스키마 "..self.SCHEMA,
    "상태: "..(self.future and "상위 스키마 보존 · 기록/초기화 불가" or snapshot.collection.enabled and (snapshot.collection.paused and "기록 ON · AFK 일시 중단" or "기록 ON") or "기록 OFF · 기존 통계 보존"),
    snapshot.range.from.." ~ "..snapshot.range.to.." (UTC, 오늘 포함)",
    "현재 KHQOL: "..snapshot.currentInstallation.khqolVersion.." · 수집 기간: "..(snapshot.collection.firstDate or "없음").." ~ "..(snapshot.collection.lastDate or "없음"),
    snapshot.collection.khqolPresent and ("진단 연결: "..snapshot.collection.bridgeStatus.." · 전체 조회에서 지표별 경로/제한 확인") or "KHQOL 미설치 · 사용 계측 미지원; 기존 개발 도구는 독립 사용 가능",
    snapshot.collection.afkSupported and "AFK 상태 확인 가능 · AFK 체류 제외" or "AFK 상태 확인 불가 · 체류 해석 제한",
    "게임 창 비활성 시간 제외 불가 · 연속 체류 최대 30분 · 인게임 검증 대기",
    "통계는 메모리에 집계되며 정상 로그아웃·/reload 때 파일에 저장됩니다.",
    ""}
  local observedDays,coverage=0,0
  for _,d in pairs(snapshot.days) do if not d.noData then observedDays=observedDays+1 end;coverage=coverage+(d.recordingSeconds or 0) end
  lines[#lines+1]=string.format("집계 날짜 %d/%d · 기록 ON 관찰 시간 %.1f분 (AFK 포함; 전체 날짜 완전 관찰 아님)",observedDays,snapshot.range.days,coverage/60)
  if observedDays==0 then lines[#lines+1]="빈 데이터: 기록을 켠 뒤 지원되는 기능을 사용하세요. 미계측은 0회와 구분됩니다." end
  local function section(kind,title,field,predicate)
    lines[#lines+1]="";lines[#lines+1]=title
    local ids={}
    for id,meta in pairs(snapshot.instrumentation) do
      if meta.kind==kind and (not predicate or predicate(id)) then
        local b=snapshot.totals[kind][id];local n=b and b[field] or 0
        if all or meta.observedDays>0 and n>0 then ids[#ids+1]=id end
      end
    end
    table.sort(ids,function(a,b)
      local aa=snapshot.totals[kind][a];local bb=snapshot.totals[kind][b]
      local av,bv=aa and aa[field] or 0,bb and bb[field] or 0
      if av==bv then return a<b end;return av>bv
    end)
    if #ids==0 then lines[#lines+1]="(지원 범위 내 기록된 사용 없음 · 전체 조회에서 미계측/0회 확인)" end
    for i=1,(all and #ids or math.min(5,#ids)) do
      local id=ids[i];local meta=snapshot.instrumentation[id]
      local method=meta.selectedRoute=="bridge" and "BRIDGE" or meta.selectedRoute=="direct" and "DIRECT" or meta.class
      lines[#lines+1]=meta.label.." ["..method.."] : "..lineValue(snapshot,id)
      if all then
        lines[#lines+1]="  "..id.." · 관찰 날짜 "..meta.observedDays.." · "..(meta.available and "현재 연결" or "현재 미연결")
        lines[#lines+1]="  "..meta.verdict.." (정적·모의 기준) · 인게임 "..meta.inGame
        if meta.limit~="" then lines[#lines+1]="  제한: "..meta.limit end
      end
    end
  end
  section("menus",all and "메뉴별 방문·누적·평균 체류" or "메뉴 방문 TOP 5","visits")
  section("settings",all and "설정 변경 전체" or "설정 변경 TOP 5","changes")
  section("features",all and "실제 기능 전체" or "실제 기능 사용 TOP 5","count",function(id) return not id:find("feature.active.",1,true) end)
  section("features","지속 기능 사용 날짜 (계정 공용 · 캐릭터 수 아님)","activeDays",function(id) return id:find("feature.active.",1,true)==1 end)
  if all then
    lines[#lines+1]="\n날짜별 기록 ON 관찰 시간"
    local days={};for key in pairs(snapshot.days) do days[#days+1]=key end;table.sort(days)
    for _,key in ipairs(days) do
      local d=snapshot.days[key]
      lines[#lines+1]=key.." : "..(d.noData and "데이터 없음 (OFF/미접속/보관 종료 구분 불가)" or string.format("%.1f분; 나머지 시간은 미관찰",d.recordingSeconds/60))
    end
    lines[#lines+1]="\n집계 규칙"
    local keys={};for key in pairs(self.rules) do keys[#keys+1]=key end;table.sort(keys)
    for _,key in ipairs(keys) do lines[#lines+1]=key..": "..tostring(self.rules[key]) end
  end
  return table.concat(lines,"\n")
end
function U:RefreshPanel()
  if not panel then return end
  if not self.db then text:SetText("사용 통계 준비 중");return end
  local ok,report=pcall(function() return self:FormatReport(self:Snapshot(range),full) end)
  text:SetText(ok and report or "통계 조회 불가 (제한된 오류 코드: UI_VIEW). 원본 오류·인자는 저장하지 않습니다.")
  text:GetParent():SetHeight(math.max(1,text:GetStringHeight()+12))
  toggle:SetText(self:Enabled() and "기록: ON" or "기록: OFF")
  toggle:SetEnabled(not self.future)
  period:SetText("최근 "..range.."일")
  view:SetText(full and "요약 보기" or "전체 조회")
end
function Dev:BuildUsagePanel(main,button,scrollText,copy,setTab,style)
  if main.usagePanel then return end
  panel=CreateFrame("Frame",nil,main,"BackdropTemplate");main.usagePanel=panel
  panel:SetPoint("TOPLEFT",10,-62);panel:SetPoint("BOTTOMRIGHT",-10,10);style(panel,.96)
  toggle=button(panel,"기록: OFF",100,24,function()
    local ok=pcall(U.SetRecording,U,not U:Enabled());if not ok then U:Error("callback") end
    U:RefreshPanel()
  end);toggle:SetPoint("TOPLEFT",4,-4)
  period=button(panel,"최근 7일",90,24,function() range=range==7 and 30 or 7;U:RefreshPanel() end)
  period:SetPoint("LEFT",toggle,"RIGHT",5,0)
  view=button(panel,"전체 조회",100,24,function() full=not full;U:RefreshPanel() end)
  view:SetPoint("LEFT",period,"RIGHT",5,0)
  local export=button(panel,"JSON 복사",110,24,function()
    local ok,result=pcall(U.Export,U,range)
    if ok then copy(result) else text:SetText("JSON 생성 불가 (UI_EXPORT). 잘린 결과를 내보내지 않았습니다.") end
  end);export:SetPoint("LEFT",view,"RIGHT",5,0)
  local refresh=button(panel,"새로고침",90,24,function() U:RefreshPanel() end)
  refresh:SetPoint("LEFT",export,"RIGHT",5,0)
  local confirmation,confirmationEpoch
  local function requestReset()
    if U.future then return end
    if not confirmation then
      confirmation=CreateFrame("Frame",nil,panel,"BackdropTemplate")
      main.usageResetDialog=confirmation
      confirmation:SetSize(390,150);confirmation:SetPoint("CENTER")
      confirmation:SetFrameStrata("DIALOG");confirmation:EnableMouse(true);style(confirmation,1)
      local message=confirmation:CreateFontString(nil,"ARTWORK","GameFontHighlight")
      message:SetPoint("TOPLEFT",18,-20);message:SetWidth(354)
      message:SetText("사용 통계만 모두 삭제할까요?\n현재 기록 ON/OFF는 유지됩니다.\nON이면 지금부터 새 관찰을 시작합니다.")
      confirmation.confirmButton=button(confirmation,"통계 삭제",120,24,function()
        local epoch=confirmationEpoch;confirmation:Hide()
        if epoch and epoch==U.epoch then U:Reset(true) end
        U:RefreshPanel()
      end)
      confirmation.confirmButton:SetPoint("BOTTOMLEFT",42,18)
      confirmation.cancelButton=button(confirmation,"취소",120,24,function() confirmation:Hide() end)
      confirmation.cancelButton:SetPoint("BOTTOMRIGHT",-42,18)
      confirmation:SetScript("OnHide",function() confirmationEpoch=nil end)
      confirmation:Hide()
    end
    confirmationEpoch=U.epoch;confirmation:Show()
  end
  local reset=button(panel,"통계 초기화…",120,24,requestReset);reset:SetPoint("TOPLEFT",4,-34)
  local note=panel:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
  note:SetPoint("LEFT",reset,"RIGHT",8,0);note:SetWidth(450);note:SetJustifyH("LEFT")
  note:SetText("초기화는 확인 후 실행 · 현재 기록 ON/OFF 유지")
  text=scrollText(panel,2,-66,610,310)
  panel:HookScript("OnShow",function() U:RefreshPanel() end)
  panel:HookScript("OnHide",function() if confirmation then confirmation:Hide() end end)
  U:RefreshPanel()
end
