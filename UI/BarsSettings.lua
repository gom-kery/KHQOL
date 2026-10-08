local _, KHQOL = ...
local Bars={tabs={},selected="environment"}
KHQOL.BarsSettings=Bars
-- A tab may supply a native builder or a link to its existing settings page.
-- Registration order determines tab order; existing feature modules stay intact.
function Bars:RegisterTab(id,title,build,page)
  self.tabs[#self.tabs+1]={id=id,title=title,build=build,page=page}
end
local function environment(content,y)
  local E,UI=KHQOL.modules.environmentTimer,KHQOL.UI
  local db=E:GetDB(); local b=UI:CreateBuilder(content,y)
  E.settingsContent=content
  local function enabled() return E:IsEnabled() end
  local function check(title,key,group,available)
    group=group or db
    return b:Checkbox(title,function() return group[key] end,function(v) group[key]=v; E:Changed() end,available or enabled)
  end
  local function slider(title,key,lo,hi,step,available)
    return b:Slider(title,lo,hi,step or 1,function() return db[key] end,function(v) db[key]=v; E:Changed() end,
      function(v) return string.format(step and step<1 and "%.2f" or "%d",v) end,available or enabled)
  end
  local function dropdown(title,key,options,available)
    return b:Dropdown(title,options,function() return db[key] end,function(v) db[key]=v; E:Changed() end,available or enabled)
  end
  b:Section("환경 타이머")
  b:Checkbox("환경 타이머 사용",enabled,function(v) KHQOL:SetEnabled("environmentTimer",v); UI:Refresh(content) end)
  b:Flush(); b:Description("표시 대상")
  check("호흡","BREATH",db.timers); check("피로도","EXHAUSTION",db.timers); check("죽은척 하기","FEIGNDEATH",db.timers)
  b:Section("표시 형태")
  dropdown("표시 형태","style",{{value="horizontal",text="가로형"},{value="vertical",text="세로형"},{value="hud",text="HUD형"}})
  b:Flush()
  local function bar() return enabled() and db.style~="hud" end
  local function vertical() return enabled() and db.style=="vertical" end
  local function hud() return enabled() and db.style=="hud" end
  slider("폭","width",40,800,1,bar); slider("높이","height",8,500,1,bar)
  slider("배율","scale",.5,2,.05,bar)
  dropdown("세로 채우는 방향","direction",{{value="up",text="아래 → 위"},{value="down",text="위 → 아래"}},vertical)
  slider("HUD 전체 크기","hudSize",100,600,1,hud); slider("HUD 바 두께","hudThickness",2,30,1,hud)
  slider("HUD 좌우 간격","hudGap",80,800,1,hud); slider("투명도","alpha",.1,1,.05)
  b:Description("HUD는 하나의 그룹으로 이동합니다. 세 번째 활성 타이머는 아래쪽 텍스트로 표시됩니다.")
  b:Section("위치")
  b:Button("위치 잠금 해제",function() E.unlocked=true; E:Changed() end,nil,enabled)
  b:Button("위치 잠금",function() E:SavePosition(); E.unlocked=false; E:Changed() end,nil,enabled)
  slider("X 위치","x",-3000,3000); slider("Y 위치","y",-3000,3000)
  b:Button("위치 기본값 복원",function() db.x,db.y=E.defaults.x,E.defaults.y; E:Changed() end,nil,enabled)
  b:Description("잠금 해제 상태에서는 타이머가 없어도 이동용 예시가 표시됩니다. 위치는 즉시 저장됩니다.")
  b:Section("텍스트")
  dropdown("텍스트 형식","textFormat",{
    {value="custom",text="표시 옵션 조합"},{value="name_time",text="호흡 42초"},{value="time",text="42초"},
    {value="name_percent",text="호흡 70%"},{value="percent",text="70%"},{value="name_time_percent",text="호흡 42초 (70%)"}})
  b:Flush()
  local function custom() return enabled() and db.textFormat=="custom" end
  check("타이머 이름","showName",nil,custom); check("남은 시간","showTime",nil,custom); check("퍼센트","showPercent",nil,custom)
  b:Section("상태 및 경고")
  slider("주의 시작 (%)","caution",1,100); slider("위험 시작 (%)","danger",0,99)
  slider("긴급 시작 (초)","critical",0,120)
  b:Flush(); check("긴급 시 중앙 경고","centerWarning"); check("긴급 시 경고음","sound")
  b:Description("긴급은 실제 남은 초를 기준으로 가장 먼저 판정합니다. 경고음은 타이머가 시작된 뒤 최초 긴급 진입 시 한 번 재생합니다.")
  b:Button("환경 타이머 설정 초기화",function()
    for key,value in pairs(E.defaults) do
      if type(value)=="table" then for k,v in pairs(value) do db[key][k]=v end else db[key]=value end
    end
    E:Changed()
  end,nil,enabled)
  return b.y
end
Bars:RegisterTab("experience","경험치",function(content,y)
  local b=KHQOL.UI:CreateBuilder(content,y)
  b:Section("경험치")
  b:Description("경험치 설정을 통합할 공간입니다. 현재 버전에서는 기존 경험치 표시 동작을 유지합니다.")
  return b.y
end)
Bars:RegisterTab("cast","시전",nil,"castBar")
Bars:RegisterTab("resource","리소스/스윙",nil,"resourceSwing")
Bars:RegisterTab("environment","환경",environment)
function Bars:BuildSettings(content,y)
  local UI,T=KHQOL.UI,KHQOL.UI.Theme
  local buttons,panels={},{}
  local panelY=y-T.ButtonHeight-T.SectionGap
  local function select(id)
    self.selected=id
    for _,tab in ipairs(self.tabs) do
      local active=tab.id==id
      UI:SetButtonSelected(buttons[tab.id],active); panels[tab.id]:SetShown(active)
      if active then
        content.contentHeight=-panelY+panels[tab.id].contentHeight+T.ContentPadding
        UI:Refresh(panels[tab.id])
      end
    end
    if KHQOL.settings and KHQOL.settings.activeContent==content then KHQOL.settings:UpdateContentHeight() end
  end
  local width=(T.ContentWidth-(#self.tabs-1)*T.RowGap)/#self.tabs
  for i,tab in ipairs(self.tabs) do
    local id=tab.id
    buttons[id]=UI:CreateButton(content,tab.title,(i-1)*(width+T.RowGap),y,width,function()
      select(id)
      if KHQOL.settings then KHQOL.settings.scroll:SetVerticalScroll(0) end
    end)
    local panel=CreateFrame("Frame",nil,content); panel:SetPoint("TOPLEFT",0,panelY); panel:SetWidth(T.ContentWidth)
    panels[id]=panel
    local bottom
    if tab.build then bottom=tab.build(panel,0)
    else
      local b=UI:CreateBuilder(panel,0); b:Section(tab.title)
      b:Description("기존 설정 페이지에서 이 기능을 관리합니다.")
      b:Button(tab.title.." 설정 열기",function() KHQOL:ShowSettings(tab.page) end)
      bottom=b.y
    end
    panel.contentHeight=-bottom; panel:SetHeight(math.max(1,-bottom)); panel:Hide()
  end
  content:SetScript("OnShow",function() select(self.selected) end)
  select(self.selected)
  return -content.contentHeight+T.ContentPadding
end
