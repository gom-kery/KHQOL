local _, KHQOL = ...
KHQOL = assert(_G.KHQOL, "Install and enable the KHQOL core addon.")
local QN=KHQOL.modules.questNavigator
function QN:BuildSettings(content,y,part)
  local UI,T=KHQOL.UI,KHQOL.UI.Theme
  local db=self:GetDB(); local b=UI:CreateBuilder(content,y)
  local function check(title,key,available)
    return b:Checkbox(title,function() return db[key] end,function(v) db[key]=v; self:Changed(key) end,available)
  end
  if part~="navigation" then
  b:Section("퀘스트 목록 표시")
  local tracker=self:GetTrackerDB()
  local function trackerCheck(title,key,available)
    return b:Checkbox(title,function() return tracker[key] end,function(v) tracker[key]=v; self:AutoRegionOptionsChanged(key) end,available)
  end
  trackerCheck("지역별 그룹화","groupByRegion")
  trackerCheck("지역 접기 / 펼치기 사용","collapsibleRegions",function() return tracker.groupByRegion end)
  b:Description("지역은 퀘스트 로그 순서로, 지역 안의 퀘스트는 낮은 레벨부터 표시합니다.")
  b:Flush()
  local auto=trackerCheck("지역 이동 시 현재 지역만 자동 펼치기","autoRegion",function() return tracker.groupByRegion and tracker.collapsibleRegions end)
  auto.text:SetWidth(T.ContentWidth-T.CheckboxSize-T.CheckboxLabelGap)
  local hint="설정한 시간만큼 머무르면 현재 지역 그룹만 펼칩니다. 해당 지역의 목록이 없으면 모두 접습니다. 던전에서는 던전명과 일치하는 그룹만 펼치며, 일치하는 던전 그룹을 확인할 수 없으면 기존 상태를 유지합니다. 다른 지역으로 이동하면 대기가 다시 시작됩니다. 수동 접기·펼치기는 다음 지역 이동까지 유지합니다."
  UI:AttachTooltip(auto,"지역 자동 펼치기",hint)
  -- A full-width checkbox avoids truncating this long option name.
  b:Flush()
  b:Slider("자동 전환 대기 시간",5,30,1,function() return tracker.autoRegionDelay end,function(v) tracker.autoRegionDelay=self:NormalizeRegionDelay(v); self:AutoRegionOptionsChanged("autoRegionDelay") end,function(v) return v.."초" end,function() return tracker.autoRegion and tracker.groupByRegion and tracker.collapsibleRegions end,hint,function(v) return self:NormalizeRegionDelay(v) end)
  b:Flush()
  trackerCheck("[D] 던전 표시","showDungeonTag")
  trackerCheck("[★] 정예 표시","showEliteTag")
  b:Slider("퀘스트 글씨 크기",10,20,1,function() return tracker.fontSize end,function(v) tracker.fontSize=v; self:RequestTrackerLayout() end,function(v) return v.." px" end)
  b:Slider("퀘스트 내용 표시 폭",200,500,1,function() return self:GetTrackerWidth() end,function(v) tracker.contentWidth=v; self:RequestTrackerLayout() end,function(v) return v.." px" end)
  b:Description("전투 중 목록 배치 변경은 전투가 끝난 뒤 적용합니다.",true)
  end
  if part=="tracker" then b:Flush();return b.y end
  b:Section("자동 선택·길 안내")
  b:Description("목록 그룹화는 퀘스트 목록 탭에서, 자동 길 안내는 이 탭에서 조정합니다. 아래 위치·크기는 화살표 HUD에만 적용합니다.",true)
  check("자동 퀘스트 선택","autoTrack")
  b:Description("자동 선택 대상은 게임의 목표 추적창에 등록된 퀘스트만 사용합니다.")
  b:Description("지역 자동 펼치기와 자동 퀘스트 선택을 함께 켜면, 지역 대기 후 해당 지역의 낮은 레벨 퀘스트부터 안내합니다. 같은 레벨이면 가까운 목표를 선택합니다. 이동 후 직접 선택한 퀘스트·사용자 핀·노트 수동 안내·반납 안내는 우선 유지합니다.",true)
  b:Dropdown("퀘스트 완료 후",{{value="turnin",text="반납 위치 안내"},{value="next",text="다음 추적 퀘스트 자동 선택"}},function() return db.completionBehavior end,function(v) db.completionBehavior=v; self:Changed("completionBehavior") end)
  b:Description("반납 안내는 현재 퀘스트를 유지하며, 실제 반납 후 자동 선택합니다. 자동 선택을 끄면 수동 안내만 유지합니다.")
  check("같은 지역 퀘스트 우선","preferSameRegion",function() return db.autoTrack end)
  b:Description("자동 선택: 초록(회색 포함) → 노랑 → 주황 → 빨강 → 던전. 같은 순위에서는 가까운 퀘스트를 선택합니다.")
  b:Description("같은 지역 우선은 난이도 순위가 같은 후보 중 현재 지도와 목적지 지도 ID가 같은 퀘스트를 우선합니다.")
  b:Section("안내 화살표 HUD 위치")
  check("위치 잠금","locked")

  b:Button("위치 초기화",function() self:ResetPosition() end)
  b:Description("기본 목표 추적기 목록의 위치는 변경하지 않습니다. 노트 길 안내와 공유하는 HUD입니다.",true)
  b:Section("안내 화살표 크기·모양")
  check("방향 화살표 표시","showArrow"); check("부드러운 회전","smoothRotation",function() return db.showArrow end)
  b:Slider("화살표 크기",32,128,1,function() return db.arrowSize end,function(v) db.arrowSize=v; self:Changed("arrowSize") end,function(v) return v.." px" end,function() return db.showArrow end)
  b:Slider("화살표 눕힘 각도",0,70,5,function() return db.arrowTilt end,function(v) db.arrowTilt=v; self:Changed("arrowTilt") end,function(v) return v.."°" end,function() return db.showArrow end,"0°는 기존 모양이며, 값이 클수록 바닥에 놓인 것처럼 눕혀 보입니다. 기본 55°.")
  b:Slider("화살표 투명도",.1,1,.05,function() return db.arrowAlpha end,function(v) db.arrowAlpha=v; self:Changed("arrowAlpha") end,function(v) return string.format("%d%%",math.floor(v*100+.5)) end,function() return db.showArrow end)
  b:Section("표시")
  check("거리 표시","showDistance")
  b:Dropdown("거리 단위",{{value="yards",text="야드 (yd)"},{value="meters",text="미터 (m)"}},function() return db.distanceUnit end,function(v) db.distanceUnit=v; self:Changed("distanceUnit") end,function() return db.showDistance end)
  check("퀘스트 이름 표시","showTitle"); check("진행도 표시","showProgress")
  b:Slider("퀘스트 이름 글자 크기",8,30,1,function() return db.titleFontSize end,function(v) db.titleFontSize=v;self:Changed("titleFontSize") end,function(v) return v.." px" end,function() return db.showTitle end)
  b:Slider("진행도 글자 크기",8,30,1,function() return db.progressFontSize end,function(v) db.progressFontSize=v;self:Changed("progressFontSize") end,function(v) return v.." px" end,function() return db.showProgress end)
  b:Dropdown("진행도 표시 방식",{{value="numeric",text="숫자만"},{value="text",text="목표 텍스트 + 숫자"}},function() return db.progressMode end,function(v) db.progressMode=v; self:Changed("progressMode") end,function() return db.showProgress end)
  b:BeginDisclosure("고급","quest-intervals",2)
  b:Slider("화살표 갱신 주기",.05,.5,.05,function() return db.arrowUpdateInterval end,function(v) db.arrowUpdateInterval=v; self:Changed("arrowUpdateInterval") end,function(v) return string.format("%.2f초",v) end,nil,"작은 값일수록 회전 반응이 빠릅니다. 기본 0.10초.")
  b:Slider("거리 갱신 주기",.1,1,.05,function() return db.distanceUpdateInterval end,function(v) db.distanceUpdateInterval=v; self:Changed("distanceUpdateInterval") end,function(v) return string.format("%.2f초",v) end,nil,"거리 표시는 선택 단위의 정수 값이 달라질 때 갱신합니다. 기본 0.25초.")
  b:EndDisclosure();b:Reflow()
  return b.reflowBottom or b.y
end
