local ADDON_NAME, KHQOL = ...
KHQOL = assert(_G.KHQOL, "Install and enable the KHQOL core addon.")
local M=KHQOL.modules.performanceMonitor
M.defaults={closeOnEscape=false,width=440,height=340,x=0,y=0,interval=1}
local MAX_LOG=300
local function read(fn,...) return KHQOL.PublicCall(fn,...) end
local function number(v) return KHQOL.IsPublicValue(v) and type(v)=="number" and v==v and math.abs(v)<math.huge end
local function positive(v) return number(v) and v>=0 end
local function clamp(v,lo,hi) return math.max(lo,math.min(hi,v)) end
local function api(name) return C_AddOns and C_AddOns[name] or _G[name] end
local function fmt(v,unit) return number(v) and string.format("%.3f%s",v,unit or "") or "N/A" end
local function count(v) return positive(v) and string.format("%.0f",v) or "N/A" end
local function statusText(value)
  if value=="ok" then return "정상" end
  if value=="profiler-disabled" then return "클라이언트 CPU 측정 꺼짐" end
  if value=="waiting-for-second-sample" then return "두 번째 표본 대기" end
  if value=="API-unavailable-or-restricted" then return "클라이언트에서 읽기 불가" end
  if value and value:find("legacy-scriptProfile-off",1,true) then return "구형 CPU 측정 OFF · 안내 참조" end
  return "측정 대기"
end
local function ratio(part,total) return positive(part) and number(total) and total>0 and part/total*100 or nil end
local function escape(value) return tostring(value==nil and "N/A" or value):gsub("[\t\r\n|]"," ") end
local function special(name,on)
  if type(UISpecialFrames)~="table" then UISpecialFrames={} end
  for i=#UISpecialFrames,1,-1 do if UISpecialFrames[i]==name then table.remove(UISpecialFrames,i) end end
  if on then UISpecialFrames[#UISpecialFrames+1]=name end
end
-- The monitor belongs to Labs; its measurement scope remains ALL KHQOL addons.
local function measuredAddons()
  local names={"KHQOL"}
  for _,name in ipairs(KHQOL.PackageOrder) do
    for _,id in ipairs(KHQOL.Packages[name].modules) do
      if KHQOL.ModuleRegistry.entries[id] then names[#names+1]=name;break end
    end
  end
  return names
end
local function sumAddonMetric(fn,...)
  local total=0
  for _,name in ipairs(measuredAddons()) do
    local value=read(fn,name,...)
    if not positive(value) then return end
    total=total+value
  end
  return total
end
function M:GetDB()
  local db=KHQOL.db.modules.performanceMonitor
  if type(db)~="table" then db={};KHQOL.db.modules.performanceMonitor=db end
  KHQOL.MergeDefaults(db,self.defaults,"types")
  for key,bounds in pairs({width={360,1000},height={300,800},x={-5000,5000},y={-5000,5000},interval={1,10}}) do
    db[key]=clamp(number(db[key]) and db[key] or self.defaults[key],bounds[1],bounds[2])
  end
  self.db=db;return db
end
function M:ResetLog()
  self.logs={};self.logHead=0;self.logCount=0;self.sampleCount=0
  self.cpuSamplePeak=nil;self.memorySamplePeak=nil
end
function M:ReadCPU(snapshot,clock)
  local profiler=C_AddOnProfiler
  local metrics=Enum and Enum.AddOnProfilerMetric
  if profiler and type(profiler.GetAddOnMetric)=="function" and metrics then
    snapshot.mode="modern-ms/tick"
    local enabled=read(profiler.IsEnabled)
    if enabled==false then snapshot.cpuStatus="profiler-disabled";return end
    local any=false
    for key,name in pairs({recent="RecentAverageTime",session="SessionAverageTime",last="LastTime",peak="PeakTime",encounter="EncounterAverageTime",
      over1="CountTimeOver1Ms",over5="CountTimeOver5Ms",over10="CountTimeOver10Ms",over50="CountTimeOver50Ms",over100="CountTimeOver100Ms"}) do
      local metric=metrics[name]
      if number(metric) then
        local value=sumAddonMetric(profiler.GetAddOnMetric,metric)
        if positive(value) then snapshot[key]=value;any=true end
      end
    end
    local metric=metrics.RecentAverageTime
    local total=number(metric) and read(profiler.GetOverallMetric,metric)
    snapshot.cpuShare=ratio(snapshot.recent,total)
    snapshot.cpuStatus=any and "ok" or "API-unavailable-or-restricted"
    return
  end
  snapshot.mode="legacy-ms/s"
  local profiling=read(C_CVar and C_CVar.GetCVar or GetCVar,"scriptProfile")
  if profiling~="1" and profiling~=1 then
    snapshot.cpuStatus="legacy-scriptProfile-off (/console scriptProfile 1 then /reload)";self.previousCPU=nil;return
  end
  local status=KHQOL.ReadPublicAPI(UpdateAddOnCPUUsage)
  local cumulative=status=="ok" and sumAddonMetric(GetAddOnCPUUsage)
  if not positive(cumulative) then snapshot.cpuStatus="API-unavailable-or-restricted";self.previousCPU=nil;return end
  if self.previousCPU and number(clock) and clock>self.previousCPU.clock and cumulative>=self.previousCPU.value then
    snapshot.recent=(cumulative-self.previousCPU.value)/(clock-self.previousCPU.clock)
  end
  snapshot.cumulative=cumulative;snapshot.cpuStatus=snapshot.recent and "ok" or "waiting-for-second-sample"
  self.previousCPU=number(clock) and {value=cumulative,clock=clock} or nil
end
function M:ReadMemory(snapshot,clock)
  local refresh=not self.memory
  if number(clock) and self.memory then
    refresh=not number(self.memory.clock) or clock<self.memory.clock or clock-self.memory.clock>=5
  end
  if refresh then
    local memory={clock=clock,status="API-unavailable-or-restricted"}
    if KHQOL.ReadPublicAPI(UpdateAddOnMemoryUsage)=="ok" then
      local value=sumAddonMetric(GetAddOnMemoryUsage)
      if positive(value) then memory.kb=value;memory.status="ok" end
      local count=read(api("GetNumAddOns"));local total,complete=0,true
      if not number(count) or count<1 or count>10000 or count~=math.floor(count) then complete=false
      else
        for i=1,count do
          local name=read(api("GetAddOnInfo"),i)
          if type(name)~="string" then complete=false
          elseif not name:match("^Blizzard_") then
            local loaded=read(api("IsAddOnLoaded"),name)
            if loaded==true then
              local used=read(GetAddOnMemoryUsage,name)
              if positive(used) then total=total+used else complete=false end
            elseif loaded~=false then complete=false end
          end
        end
      end
      if complete then memory.share=ratio(memory.kb,total);memory.total=total end
    end
    self.memory=memory
  end
  snapshot.memoryKB=self.memory.kb;snapshot.memoryShare=self.memory.share
  snapshot.memoryStatus=self.memory.status
  snapshot.memoryAge=number(clock) and number(self.memory.clock) and math.max(0,clock-self.memory.clock) or nil
end
function M:Sample()
  if not self.enabled or not KHQOL.LabLock:IsUnlocked() then return end
  local clock=read(GetTime)
  local snapshot={clock=clock,combat=read(UnitAffectingCombat,"player"),fps=read(GetFramerate)}
  self:ReadCPU(snapshot,clock);self:ReadMemory(snapshot,clock)
  if self.lastMode and self.lastMode~=snapshot.mode then self.cpuSamplePeak=nil end
  self.lastMode=snapshot.mode
  if positive(snapshot.recent) then self.cpuSamplePeak=math.max(self.cpuSamplePeak or 0,snapshot.recent) end
  if positive(snapshot.memoryKB) then self.memorySamplePeak=math.max(self.memorySamplePeak or 0,snapshot.memoryKB) end
  self.logs=self.logs or {};self.logHead=(self.logHead or 0)%MAX_LOG+1
  self.logs[self.logHead]=snapshot;self.logCount=math.min(MAX_LOG,(self.logCount or 0)+1)
  self.sampleCount=(self.sampleCount or 0)+1;self.snapshot=snapshot
  self:Render()
end
function M:Render()
  if not self.info then return end
  local s=self.snapshot or {}
  local modern=s.mode=="modern-ms/tick"
  local unit=modern and " ms/tick" or " ms/s"
  local lines={"CPU 최근: "..fmt(s.recent,unit).."   전체 애드온 대비: "..fmt(s.cpuShare,"%"),
    modern and ("세션 평균: "..fmt(s.session,unit).."   모듈 최대 합 (상한): "..fmt(s.peak,unit)) or ("누적 CPU: "..fmt(s.cumulative," ms")),
    modern and ("최근 tick: "..fmt(s.last,unit).."   보스 평균: "..fmt(s.encounter,unit)) or "구형 CPU 측정: scriptProfile 1 + /reload 필요",
    modern and (">1/5/10/50/100ms: "..table.concat({count(s.over1),count(s.over5),count(s.over10),count(s.over50),count(s.over100)}," / ")) or "CPU 비율: 구형 API에서는 제공하지 않음",
    "메모리: "..fmt(number(s.memoryKB) and s.memoryKB/1024," MiB").."   애드온 대비: "..fmt(s.memoryShare,"%"),
    "기록 중 최대: CPU "..fmt(self.cpuSamplePeak,unit).." / "..fmt(number(self.memorySamplePeak) and self.memorySamplePeak/1024," MiB"),
    "FPS: "..fmt(s.fps).."   전투: "..(s.combat==true and "ON" or s.combat==false and "OFF" or "N/A"),
    "CPU 상태: "..statusText(s.cpuStatus),"메모리 상태: "..statusText(s.memoryStatus),
    "최근 "..(self.logCount or 0).." / 300개 · 메모리 갱신 5초 이상 간격",
    "비율은 전체 애드온 기준. PC 전체 CPU/RAM 점유율 아님."}
  self.info:SetText(table.concat(lines,"\n"))
  if self.updateContentLayout then self.updateContentLayout() end
end
function M:ExportLog()
  local version,build,_,interface=read(GetBuildInfo)
  local enabled={}
  for key in pairs(KHQOL.defaults.enabled) do if KHQOL.db.enabled[key]==true then enabled[#enabled+1]=key end end
  table.sort(enabled)
  local db=self:GetDB()
  local lines={"KHQOL performance monitor | version="..KHQOL.VERSION.." | build=monitor-fix",
    "Client="..escape(version).." Build="..escape(build).." Interface="..escape(interface),
    "Interval="..db.interval.."s MemoryInterval>=5s Samples="..(self.sampleCount or 0).." Retained="..(self.logCount or 0).."/300",
    "EnabledPreferences="..table.concat(enabled,",").." LabsUnlocked="..tostring(KHQOL.LabLock:IsUnlocked()),
    "CPU modern=ms/tick (recent=last 60 ticks), legacy=ms/s; memory=KiB; shares=all addons, NOT OS CPU/RAM.",
    "All loaded KHQOL addons are summed. Modern peak/counts sum per-addon metrics; peaks may occur at different times. Local peaks are sampled aggregate values. Monitor overhead is included. Memory can fall after GC.",
    "No module-level attribution. No character/realm names, notes, chat or registered spells included.",
    "uptime_s\tcombat\tfps\tcpu_mode\trecent\tsession\tlast\tpeak\tencounter\tover1\tover5\tover10\tover50\tover100\tcumulative_ms\tcpu_share_percent\tmemory_KiB\tmemory_share_percent\tmemory_age_s\tcpu_status\tmemory_status"}
  local keys={"clock","combat","fps","mode","recent","session","last","peak","encounter","over1","over5","over10","over50","over100","cumulative","cpuShare","memoryKB","memoryShare","memoryAge","cpuStatus","memoryStatus"}
  for i=1,self.logCount or 0 do
    local s=self.logs[((self.logHead-self.logCount+i-1)%MAX_LOG)+1];local row={}
    for _,key in ipairs(keys) do row[#row+1]=escape(s[key]) end
    lines[#lines+1]=table.concat(row,"\t")
  end
  return table.concat(lines,"\n")
end
function M:SaveWindow()
  local f=self.frame;local db=self:GetDB()
  local x,y=f:GetCenter();local cx,cy=UIParent:GetCenter()
  local scale=f:GetEffectiveScale()/UIParent:GetEffectiveScale()
  if number(x) and number(y) and number(cx) and number(cy) and number(scale) then db.x=x*scale-cx;db.y=y*scale-cy end
  db.width,db.height=f:GetWidth(),f:GetHeight()
  KHQOL.PositionStore:Committed()
end
function M:ApplyLayout()
  local f=self.frame;if not f then return end
  local db=self:GetDB();local screenW,screenH=UIParent:GetWidth(),UIParent:GetHeight()
  local maxW=math.max(100,math.min(1000,screenW-16));local maxH=math.max(100,math.min(800,screenH-16))
  local minW,minH=math.min(360,maxW),math.min(300,maxH)
  if f.SetResizeBounds then f:SetResizeBounds(minW,minH,maxW,maxH)
  else if f.SetMinResize then f:SetMinResize(minW,minH) end;if f.SetMaxResize then f:SetMaxResize(maxW,maxH) end end
  f:SetSize(clamp(db.width,minW,maxW),clamp(db.height,minH,maxH))
  local x=clamp(db.x,-screenW/2+f:GetWidth()/2,screenW/2-f:GetWidth()/2)
  local y=clamp(db.y,-screenH/2+f:GetHeight()/2,screenH/2-f:GetHeight()/2)
  f:ClearAllPoints();f:SetPoint("CENTER",UIParent,"CENTER",x,y)
  special("KHQOLPerformanceOverlay",db.closeOnEscape)
end
function M:Close()
  KHQOL:SetEnabled("performanceMonitor",false)
  KHQOL:SaveCurrentProfile()
end
function M:CopyLog()
  self:EnsureFrame()
  if not self.copyFrame then
    local UI=KHQOL.UI
    local f=CreateFrame("Frame","KHQOLPerformanceLogCopy",UIParent,"BackdropTemplate")
    self.copyFrame=f;f:Hide();UI:Surface(f);f:SetFrameStrata("FULLSCREEN_DIALOG");f:SetClampedToScreen(true);f:EnableMouse(true)
    local title=UI:CreateLabel(f,"측정 로그 · Ctrl+A → Ctrl+C · ESC로 닫기",12,-12)
    title:ClearAllPoints();title:SetPoint("TOPLEFT",12,-12);title:SetPoint("TOPRIGHT",-44,-12)
    local close=UI:CreateButton(f,"X",0,0,28,function() f:Hide() end)
    close:ClearAllPoints();close:SetPoint("TOPRIGHT",-8,-8)
    local scroll=CreateFrame("ScrollFrame",nil,f,"UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",12,-44);scroll:SetPoint("BOTTOMRIGHT",-32,12)
    local box=UI:CreateEditBox(f,0,0,520);self.copyBox=box
    box:SetParent(scroll);box:ClearAllPoints();box:SetPoint("TOPLEFT");box:SetMultiLine(true);box:SetMaxLetters(0)
    box:SetJustifyH("LEFT");box:SetJustifyV("TOP");scroll:SetScrollChild(box)
    local measure=box:CreateFontString(nil,"OVERLAY");measure:SetFont(UI:Font(),UI.Theme.LabelFontSize,"")
    measure:SetWordWrap(true);measure:Hide()
    box:SetScript("OnTextChanged",function()
      local lines=read(box.GetNumLines,box);local height
      if positive(lines) then height=lines*16+24
      else
        measure:SetWidth(math.max(40,box:GetWidth()-16));measure:SetText(box:GetText())
        height=measure:GetStringHeight()+24
      end
      box:SetHeight(math.max(scroll:GetHeight(),height))
    end)
    box:SetScript("OnEnterPressed",function() box:ClearFocus() end)
    box:SetScript("OnEscapePressed",function() f:Hide() end)
    f:SetScript("OnHide",function() box:ClearFocus() end)
    f.scroll=scroll;special("KHQOLPerformanceLogCopy",true)
  end
  local f=self.copyFrame;f:SetSize(math.min(720,UIParent:GetWidth()-20),math.min(520,UIParent:GetHeight()-20))
  f:ClearAllPoints();f:SetPoint("CENTER");self.copyBox:SetWidth(f:GetWidth()-48)
  self.copyBox:SetText(self:ExportLog());f.scroll:SetVerticalScroll(0);f:Show()
  self.copyBox:SetFocus();self.copyBox:HighlightText()
end
function M:EnsureFrame()
  if self.frame then return end
  local UI=KHQOL.UI
  local f=CreateFrame("Frame","KHQOLPerformanceOverlay",UIParent,"BackdropTemplate")
  self.frame=f;f:Hide();UI:Surface(f);f:SetFrameStrata("DIALOG");f:SetClampedToScreen(true)
  f:EnableMouse(true);f:SetMovable(true);f:SetResizable(true);f:RegisterForDrag("LeftButton")
  local title=UI:CreateLabel(f,"KHQOL 성능 모니터",12,-12,14)
  title:ClearAllPoints();title:SetPoint("TOPLEFT",12,-12);title:SetPoint("TOPRIGHT",-44,-12)
  local close=UI:CreateButton(f,"X",0,0,28,function() M:Close() end)
  close:ClearAllPoints();close:SetPoint("TOPRIGHT",-8,-8)
  local viewport=CreateFrame("ScrollFrame",nil,f)
  viewport:SetPoint("TOPLEFT",12,-44);viewport:SetPoint("BOTTOMRIGHT",-12,52)
  local body=CreateFrame("Frame",nil,viewport);viewport:SetScrollChild(body)
  self.info=UI:CreateLabel(body,"측정 대기",0,0,12);self.info:SetJustifyV("TOP")
  local function layout()
    body:SetWidth(math.max(60,f:GetWidth()-24));self.info:SetWidth(body:GetWidth());self.info:SetHeight(0)
    body:SetHeight(math.max(viewport:GetHeight(),self.info:GetStringHeight()+12))
  end
  f:SetScript("OnSizeChanged",layout);viewport:EnableMouseWheel(true)
  viewport:SetScript("OnMouseWheel",function(_,delta)
    viewport:SetVerticalScroll(clamp(viewport:GetVerticalScroll()-delta*24,0,math.max(0,body:GetHeight()-viewport:GetHeight())))
  end)
  self.updateContentLayout=layout
  local copy=UI:CreateButton(f,"로그 복사",0,0,108,function() M:CopyLog() end)
  copy:ClearAllPoints();copy:SetPoint("BOTTOMLEFT",12,12)
  local reset=UI:CreateButton(f,"기록 지우기",0,0,112,function() M:ResetLog();M:Render() end)
  reset:ClearAllPoints();reset:SetPoint("BOTTOMLEFT",copy,"BOTTOMRIGHT",8,0)
  local grip=UI:CreateButton(f,"◢",0,0,28,function() end);grip:ClearAllPoints();grip:SetPoint("BOTTOMRIGHT",-4,4)
  grip:SetScript("OnMouseDown",function(_,button) if button=="LeftButton" then f:StartSizing("BOTTOMRIGHT") end end)
  grip:SetScript("OnMouseUp",function() f:StopMovingOrSizing();M:SaveWindow() end)
  f:SetScript("OnDragStart",function() if not M:GetDB().positionLocked then f:StartMoving() end end)
  f:SetScript("OnDragStop",function() f:StopMovingOrSizing();M:SaveWindow() end)
  f:SetScript("OnHide",function()
    f:StopMovingOrSizing();M:StopSampling()
    if M.enabled then M:Close() end
  end)
  f:RegisterEvent("DISPLAY_SIZE_CHANGED");f:RegisterEvent("UI_SCALE_CHANGED")
  f:SetScript("OnEvent",function() if M.enabled then M:ApplyLayout() end end)
end
function M:StopSampling()
  if self.ticker then self.ticker:Cancel();self.ticker=nil end
  if self.frame then self.frame:SetScript("OnUpdate",nil) end
  if self.copyFrame then self.copyFrame:Hide() end
end
function M:SetEnabled(on)
  self:StopSampling();self.enabled=on and KHQOL.LabLock:IsUnlocked() or false
  self.previousCPU=nil;self.memory=nil
  if not self.enabled then
    if self.frame then self.frame:Hide() end
    special("KHQOLPerformanceOverlay",false);return
  end
  self:EnsureFrame();self:ApplyLayout();self.frame:Show();self:Sample()
  local interval=self:GetDB().interval
  local function tick()
    if not M.enabled or not KHQOL.LabLock:IsUnlocked() or not M.frame:IsShown() then M:StopSampling();return end
    M:Sample()
  end
  if C_Timer and type(C_Timer.NewTicker)=="function" then self.ticker=C_Timer.NewTicker(interval,tick)
  else
    local elapsed=0
    self.frame:SetScript("OnUpdate",function(_,delta) elapsed=elapsed+delta;if elapsed>=interval then elapsed=0;tick() end end)
  end
end
function M:BuildSettings(content,y)
  local UI=KHQOL.UI;local b=UI:CreateBuilder(content,y)
  self:GetDB()
  b:Description("상단의 모듈 사용을 켜면 설정창을 닫아도 오버레이와 측정이 유지됩니다. X 또는 ESC 닫기는 모듈을 OFF로 전환합니다.")
  b:Section("위치")
  b:Checkbox("위치 잠금",function() return M:GetDB().positionLocked end,function(v) M:GetDB().positionLocked=v end)

  b:Section("오버레이 창")
  b:Checkbox("ESC로 닫기",function() return M:GetDB().closeOnEscape end,function(v) M:GetDB().closeOnEscape=v;M:ApplyLayout() end)
  b:Description("기본 OFF. 창 배경 드래그로 이동, 우측 하단 ◢ 드래그로 크기 조절. 위치·크기는 프로필에 저장됩니다.")
  for _,item in ipairs({{"폭","width",360,1000},{"높이","height",300,800}}) do
    local key=item[2]
    b:Slider(item[1],item[3],item[4],10,function() return M:GetDB()[key] end,function(v) M:GetDB()[key]=v;M:ApplyLayout() end,function(v) return string.format("%d px",v) end)
  end
  b:Slider("CPU 갱신 간격",1,10,1,function() return M:GetDB().interval end,function(v)
    M:GetDB().interval=v;if M.enabled then M:SetEnabled(true) end
  end,function(v) return string.format("%d 초",v) end)
  b:Section("측정 로그")
  b:Button("로그 복사",function() M:CopyLog() end)
  b:Button("기록 지우기",function() M:ResetLog();M:Render() end)
  b:Description("최근 300개 기록 보관. 복사 창에서 Ctrl+A → Ctrl+C. 기록은 메모리에만 보관하며 /reload 시 비워집니다.")
  b:Section("값의 의미")
  b:Description("CPU는 설치된 KHQOL 공통 기반과 기능 애드온 처리 시간의 합입니다. 최대·지연 횟수는 모듈별 지표의 합이며 전체 동시 최대·횟수와 다를 수 있습니다. 최근 평균·세션 평균·최대·보스 평균·지연 횟수를 제공되는 API 범위에서 표시합니다. 값 확인 불가 시 N/A.")
  b:Description("메모리 비율은 로드된 외부 애드온 중 KHQOL 비중. 전체 값 확인 불가 시 비율 N/A. PC 전체 CPU/RAM 점유율과 다릅니다. 모니터 자체 비용 포함.")
  b:Description("CPU 기본 API 미지원 시 구형 CPU API를 사용합니다. scriptProfile이 OFF이면 안내만 표시하며 전역 설정을 자동 변경하지 않습니다.")
  b:Flush();return b.y
end
