local _, KHQOL = ...
local QN=KHQOL.modules.questNavigator
function QN:BuildSettings(content,y)
  local UI,T=KHQOL.UI,KHQOL.UI.Theme
  local db=self:GetDB(); local b=UI:CreateBuilder(content,y)
  local function check(title,key,available)
    return b:Checkbox(title,function() return db[key] end,function(v) db[key]=v; self:Changed(key) end,available)
  end
  b:Section("위치")
  check("위치 잠금","locked")
  b:Description("위치 잠금을 해제하면 이동 모드가 켜집니다. 표시된 영역을 드래그하세요.")
  b:Button("위치 초기화",function() self:ResetPosition() end)
  content:HookScript("OnHide",function()
    if self.db and not self.db.locked then self.db.locked=true; self:Changed("locked") end
  end)
  b:Section("추적")
  check("완료 후 다음 퀘스트 자동 선택","autoTrack")
  check("같은 지역 퀘스트 우선","preferSameRegion",function() return db.autoTrack end)
  b:Description("자동 선택: 초록(회색 포함) → 노랑 → 주황 → 빨강 → 던전. 같은 순위에서는 가까운 퀘스트를 선택합니다.")
  b:Description("같은 지역 우선은 난이도 순위가 같은 후보 중 현재 지도와 목적지 지도 ID가 같은 퀘스트를 우선합니다.")
  b:Section("화살표")
  check("방향 화살표 표시","showArrow"); check("부드러운 회전","smoothRotation",function() return db.showArrow end)
  b:Slider("화살표 크기",32,128,1,function() return db.arrowSize end,function(v) db.arrowSize=v; self:Changed("arrowSize") end,function(v) return v.." px" end,function() return db.showArrow end)
  b:Slider("화살표 눕힘 각도",0,70,5,function() return db.arrowTilt end,function(v) db.arrowTilt=v; self:Changed("arrowTilt") end,function(v) return v.."°" end,function() return db.showArrow end,"0°는 기존 모양이며, 값이 클수록 바닥에 놓인 것처럼 눕혀 보입니다. 기본 55°.")
  b:Slider("화살표 투명도",.1,1,.05,function() return db.arrowAlpha end,function(v) db.arrowAlpha=v; self:Changed("arrowAlpha") end,function(v) return string.format("%d%%",math.floor(v*100+.5)) end,function() return db.showArrow end)
  b:Section("표시")
  check("거리 표시","showDistance")
  b:Dropdown("거리 단위",{{value="yards",text="야드 (yd)"},{value="meters",text="미터 (m)"}},function() return db.distanceUnit end,function(v) db.distanceUnit=v; self:Changed("distanceUnit") end,function() return db.showDistance end)
  check("퀘스트 이름 표시","showTitle"); check("진행도 표시","showProgress")
  b:Dropdown("진행도 표시 방식",{{value="numeric",text="숫자만"},{value="text",text="목표 텍스트 + 숫자"}},function() return db.progressMode end,function(v) db.progressMode=v; self:Changed("progressMode") end,function() return db.showProgress end)
  b:Section("고급")
  local advanced=CreateFrame("Frame",nil,content); advanced:SetWidth(T.ContentWidth)
  local expanded=false
  local toggle
  local function updateAdvanced()
    advanced:SetShown(expanded)
    toggle:SetText(expanded and "고급 옵션 접기" or "고급 옵션 펼치기")
    content.contentHeight=-b.y+T.ContentPadding+(expanded and advanced:GetHeight() or 0)
    if KHQOL.settings and KHQOL.settings.activeContent==content then KHQOL.settings:UpdateContentHeight() end
  end
  toggle=b:Button("고급 옵션 펼치기",function() expanded=not expanded; updateAdvanced() end)
  b:Flush(); advanced:SetPoint("TOPLEFT",0,b.y)
  local a=UI:CreateBuilder(advanced,0)
  a:Slider("화살표 갱신 주기",.05,.5,.05,function() return db.arrowUpdateInterval end,function(v) db.arrowUpdateInterval=v; self:Changed("arrowUpdateInterval") end,function(v) return string.format("%.2f초",v) end,nil,"작은 값일수록 회전 반응이 빠릅니다. 기본 0.10초.")
  a:Slider("거리 갱신 주기",.1,1,.05,function() return db.distanceUpdateInterval end,function(v) db.distanceUpdateInterval=v; self:Changed("distanceUpdateInterval") end,function(v) return string.format("%.2f초",v) end,nil,"거리 표시는 선택 단위의 정수 값이 달라질 때 갱신합니다. 기본 0.25초.")
  advanced:SetHeight(-a.y+T.RowGap); advanced:Hide()
  return b.y
end
