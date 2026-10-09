local _, KHQOL = ...
local Bars=KHQOL.UI:NewSettingsGroup("bars")
KHQOL.BarsSettings=Bars
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
  b:Flush(); b:Description("표시 대상")
  check("호흡","BREATH",db.timers); check("피로도","EXHAUSTION",db.timers); check("죽은척 하기","FEIGNDEATH",db.timers)
  b:Section("표시 형태")
  dropdown("표시 형태","style",{{value="horizontal",text="가로형"},{value="vertical",text="세로형"},{value="hud",text="HUD형"}})
  b:Flush()
  local function bar() return enabled() and db.style~="hud" end
  local function vertical() return enabled() and db.style=="vertical" end
  local function hud() return enabled() and db.style=="hud" end
  b:Section("위치")
  b:Button("위치 잠금 해제",function() E.unlocked=true; E:Changed() end,nil,enabled)
  b:Button("위치 잠금",function() E:SavePosition(); E.unlocked=false; E:Changed() end,nil,enabled)
  slider("X 위치","x",-3000,3000); slider("Y 위치","y",-3000,3000)
  b:Button("위치 기본값 복원",function() db.x,db.y=E.defaults.x,E.defaults.y; E:Changed() end,nil,enabled)
  b:Description("잠금 해제 상태에서는 타이머가 없어도 이동용 예시가 표시됩니다. 위치는 즉시 저장됩니다.")
  b:Section("모양 및 크기")
  slider("폭","width",40,800,1,bar); slider("높이","height",8,500,1,bar)
  slider("배율","scale",.5,2,.05,bar)
  dropdown("세로 채우는 방향","direction",{{value="up",text="아래 → 위"},{value="down",text="위 → 아래"}},vertical)
  slider("HUD 전체 크기","hudSize",100,600,1,hud); slider("HUD 바 두께","hudThickness",2,30,1,hud)
  slider("HUD 좌우 간격","hudGap",80,800,1,hud); slider("투명도","alpha",.1,1,.05)
  b:Description("HUD는 하나의 그룹으로 이동합니다. 세 번째 활성 타이머는 아래쪽 텍스트로 표시됩니다.")
  b:Section("텍스트")
  slider("HUD 텍스트 크기","hudTextSize",8,48,1,hud)
  b:Button("HUD 텍스트 위치 초기화",function() E:SavePosition(); db.hudTextPositions={}; E:Changed() end,nil,hud)
  b:Description("HUD형에서 위치 잠금을 해제하면 텍스트를 각각 드래그할 수 있습니다. 위치는 타이머별로 저장되며 HUD 그룹과 함께 이동합니다.")
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
  return b.y
end
Bars:RegisterTab("experience",nil,function(content,y)
  return KHQOL.modules.experienceBar:BuildSettings(content,y)
end)
Bars:RegisterTab("cast",nil,function(content,y)
  return KHQOL.modules.castBar:BuildSettings(content,y)
end)
Bars:RegisterTab("resource",nil,function(content,y)
  return KHQOL.modules.resourceSwing:BuildSettings(content,y)
end)
Bars:RegisterTab("environment",nil,environment)
