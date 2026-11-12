local _, KHQOL = ...
KHQOL = assert(_G.KHQOL, "Install and enable the KHQOL core addon.")
local FC = KHQOL.modules.clock
local CONTROL_TEXTURE_PATH = "Interface\\AddOns\\KHQOL_Clock\\Clock\\Textures\\"
local SOUND_PATH = "Interface\\AddOns\\KHQOL_Clock\\Clock\\Sounds\\"

local function SetFont(region, size) region:SetFont(FC.FONT_PATH, size, "OUTLINE") end
local function NewButton(parent, text, width, onClick)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(width, 24); b:SetText(text); SetFont(b:GetFontString(), 13); b:SetScript("OnClick", onClick)
  return b
end
-- The bundled Korean font has no control glyphs. These controls are textures,
-- not text, so they never turn into missing-glyph squares.
local function IconButton(parent, kind, width, onClick)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(width, 24); b:SetText(""); b:SetScript("OnClick", onClick)
  local icon = b:CreateTexture(nil, "ARTWORK"); icon:SetPoint("CENTER"); b.icon = icon
  function b:SetIcon(newKind)
    self.icon:Hide()
    if self.barLeft then self.barLeft:Hide(); self.barRight:Hide() end
    if newKind == "play" or newKind == "pause" or newKind == "reset" then
      self.icon:SetTexture(CONTROL_TEXTURE_PATH .. newKind .. ".tga"); self.icon:SetSize(14, 14); self.icon:Show()
    elseif newKind == "watch" then
      self.icon:SetTexture("Interface\\Icons\\INV_Misc_PocketWatch_01"); self.icon:SetSize(18, 18); self.icon:Show()
    elseif newKind == "stop" then
      self.icon:SetColorTexture(1, .15, .12, 1); self.icon:SetSize(11, 11); self.icon:Show()
    end
  end
  b:SetIcon(kind)
  return b
end
local function PlainCloseButton(parent, onClick)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(22, 22); b:SetText("X"); SetFont(b:GetFontString(), 20); b:SetScript("OnClick", onClick)
  return b
end
local function WatchIconButton(parent, onClick)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(24, 24); b:SetScript("OnClick", onClick)
  local icon = b:CreateTexture(nil, "ARTWORK")
  icon:SetAllPoints(); icon:SetTexture("Interface\\Icons\\INV_Misc_PocketWatch_01")
  return b
end
local function NewLabel(parent, text, size)
  local l = parent:CreateFontString(nil, "OVERLAY"); SetFont(l, size or 14); l:SetText(text); return l
end
local function NewCheck(parent, text, onClick)
  local c = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  local label = c:CreateFontString(nil, "OVERLAY"); label:SetPoint("LEFT", c, "RIGHT", 1, 0); SetFont(label, 13); label:SetText(text)
  c:SetScript("OnClick", onClick); return c
end
local function NewRadio(parent, text, onClick)
  local r = CreateFrame("CheckButton", nil, parent, "UIRadioButtonTemplate")
  local label = r:CreateFontString(nil, "OVERLAY"); label:SetPoint("LEFT", r, "RIGHT", 1, 0); SetFont(label, 12); label:SetText(text)
  r:SetScript("OnClick", onClick)
  return r
end
local function Format(seconds)
  seconds = math.max(0, math.floor(seconds or 0))
  return string.format("%02d:%02d:%02d", math.floor(seconds / 3600), math.floor(seconds / 60) % 60, seconds % 60)
end
local TOOL_WIDTH,TOOL_HEIGHT=390,282
FC.ClockToolPositions={tools={y=-80},stopwatch={y=110},alert={y=160},timerBar={y=-120}}
function FC:NormalizeClockToolsScale(value)
  if not KHQOL.IsPublicNumber(value) then return 100 end
  return math.max(80,math.min(100,5*math.floor(value/5+.5)))
end
function FC:ApplyClockToolsSize()
  local f=self.clockToolsFrame
  if not f then return end
  local d=self.db.clockTools
  d.toolsScale=self:NormalizeClockToolsScale(d.toolsScale)
  local scale=d.toolsScale/100
  f.toolsContent:SetScale(scale)
  f:SetSize(TOOL_WIDTH*scale,TOOL_HEIGHT*scale)
end
function FC:ResetClockToolPosition(key)
  local frame=key=="timerBar" and self.timerBarFrame or key=="tools" and self.clockToolsFrame
  if not frame then return end
  local d=self.db.clockTools
  self:SaveClockTool(frame,key)
  if d.positions then d.positions[key]=nil end
  KHQOL.PositionStore:Committed(function() KHQOL.PositionUtils.ApplyPoint(frame,self.ClockToolPositions[key]) end)
end
function FC:SaveClockTool(frame,key)
  if not frame or not self.db or KHQOL.profileApplying then return end
  frame:StopMovingOrSizing()
  if not frame.positionMoving then return end
  frame.positionMoving=nil
  self.db.clockTools.positions=self.db.clockTools.positions or {}
  local positions=self.db.clockTools.positions
  local p=positions[key] or {}
  if KHQOL.PositionStore:Point(frame,p) then positions[key]=p;KHQOL.PositionStore:Committed() end
end
local function MakeMovable(frame,key)
  frame:SetMovable(true); frame:EnableMouse(true)
  frame:SetScript("OnMouseDown", function(self, button)
    local d=FC.db.clockTools
    local lockKey=key=="timerBar" and "timerBarLocked" or "positionLocked"
    if button=="LeftButton" and not d[lockKey] then self.positionMoving=true;self:StartMoving() end
  end)
  frame:SetScript("OnMouseUp", function(self, button) if button == "LeftButton" then FC:SaveClockTool(self,key) end end)
  frame:HookScript("OnHide",function(self) FC:SaveClockTool(self,key) end)
  frame:SetClampedToScreen(true)
end
local function Choices(first, last, step)
  local values = {}
  for n = first, last, step or 1 do values[#values + 1] = { n, string.format("%02d", n) } end
  return values
end
local function MenuButton(parent, width, choices, getValue, setValue)
  local button = NewButton(parent, "", width, function(self) self.menu:SetShown(not self.menu:IsShown()) end)
  local menu = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  menu:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -2); menu:SetWidth(width + 6);menu:SetClampedToScreen(true)
  FC.MakeBackdrop(menu, .95, .73, .15, .95)
  local y = -4
  for _, choice in ipairs(choices) do
    local selectedValue, selectedText = choice[1], choice[2]
    local row = NewButton(menu, selectedText, width - 2, function() setValue(selectedValue); menu:Hide(); button:SetText(getValue()) end)
    row:SetPoint("TOPLEFT", 4, y); y = y - 24
  end
  menu:SetHeight(-y + 2); menu:Hide(); button.menu = menu
  button.Refresh = function() button:SetText(getValue() .. " ▼") end
  button:Refresh()
  return button
end

function FC:CreateClockTools()
  if self.clockToolsFrame then return end
  local settings = self.db.clockTools
  -- The tools ticker is created only while a timer, an alarm, or an
  -- auto-hiding alert needs time-based updates.  The controls themselves do
  -- not require a permanent 20-times-per-second update loop.
  local EnsureToolsTicker, StopToolsTickerIfIdle, Notify

  local messageLayer = CreateFrame("Frame", "ForeverClockAlertMessageFrame", UIParent)
  messageLayer:SetSize(560, 64); messageLayer:SetPoint("CENTER", UIParent, "CENTER", 0, 160); messageLayer:SetFrameStrata("HIGH")
  messageLayer:SetMovable(true)
  messageLayer:EnableMouse(false)
  messageLayer.text = messageLayer:CreateFontString(nil, "OVERLAY")
  messageLayer.text:SetPoint("CENTER"); messageLayer.text:SetJustifyH("CENTER")
  messageLayer:Hide()
  self.alertMessageFrame = messageLayer
  messageLayer:SetScript("OnMouseDown", function(layer, button)
    if button == "LeftButton" and not FC.db.clockTools.positionLocked and layer.isTest and IsAltKeyDown and IsAltKeyDown() then layer.positionMoving=true;layer:StartMoving() end
  end)
  messageLayer:SetScript("OnMouseUp", function(layer, button)
    if button == "LeftButton" then FC:SaveClockTool(layer,"alert") end
  end)
  messageLayer:SetClampedToScreen(true)
  messageLayer:HookScript("OnHide",function(layer) FC:SaveClockTool(layer,"alert") end)
  function self:ShowAlertMessage(message, isTest)
    local layer = self.alertMessageFrame
    if not layer then return end
    if isTest and layer:IsShown() and not layer.isTest then return end
    layer.text:SetFont(self.FONT_PATH, settings.alertFontSize or 24, "OUTLINE")
    layer.text:SetText(message)
    layer.isTest = isTest and true or false
    layer.hideAt = layer.isTest and nil or (GetTime() + 4)
    layer:EnableMouse(layer.isTest)
    layer:Show()
    if EnsureToolsTicker then EnsureToolsTicker() end
  end

  -- Stopwatch remains a separate, independently movable popup.
  local stopwatch = CreateFrame("Frame", "ForeverClockStopwatchFrame", UIParent, "BackdropTemplate")
  stopwatch:SetSize(300, 58); stopwatch:SetPoint("CENTER", 0, 110); stopwatch:SetFrameStrata("DIALOG")
  self.MakeBackdrop(stopwatch, 1, .78, .18, .95); MakeMovable(stopwatch,"stopwatch")
  stopwatch.time = NewLabel(stopwatch, "00:00:00", 22); stopwatch.time:SetPoint("LEFT", 14, 0)
  stopwatch.displayedSeconds=0
  stopwatch.start = IconButton(stopwatch, "play", 42, function()
    stopwatch.running = not stopwatch.running
    if stopwatch.running then stopwatch.startedAt = GetTime() - (stopwatch.elapsed or 0) end
    stopwatch.start:SetIcon(stopwatch.running and "pause" or "play")
  end); stopwatch.start:SetPoint("LEFT", stopwatch.time, "RIGHT", 16, 0)
  stopwatch.reset = IconButton(stopwatch, "reset", 42, function()
    stopwatch.running, stopwatch.elapsed = false, 0; stopwatch.displayedSeconds=0; stopwatch.time:SetText("00:00:00"); stopwatch.start:SetIcon("play")
  end); stopwatch.reset:SetPoint("LEFT", stopwatch.start, "RIGHT", 5, 0)
  stopwatch.close = PlainCloseButton(stopwatch, function() stopwatch:Hide() end); stopwatch.close:SetPoint("RIGHT", -7, 0); stopwatch.close:Hide()
  local function UpdateStopwatchClose()
    -- OnLeave fires when moving into a child frame.  Mark a short deadline;
    -- the child OnEnter clears it before the close button can be hidden.
    stopwatch.closeHideAt = GetTime() + .12
  end
  stopwatch:SetScript("OnEnter", function() stopwatch.close:Show() end)
  stopwatch:SetScript("OnLeave", UpdateStopwatchClose)
  stopwatch.close:SetScript("OnEnter", function() stopwatch.closeHideAt = nil; stopwatch.close:Show() end)
  stopwatch.close:SetScript("OnLeave", UpdateStopwatchClose)
  stopwatch:SetScript("OnUpdate", function()
    if stopwatch.running then
      stopwatch.elapsed=GetTime()-stopwatch.startedAt
      local seconds=math.max(0,math.floor(stopwatch.elapsed))
      if seconds~=stopwatch.displayedSeconds then stopwatch.displayedSeconds=seconds;stopwatch.time:SetText(Format(seconds)) end
    end
    if stopwatch.closeHideAt and GetTime() >= stopwatch.closeHideAt then stopwatch.closeHideAt = nil; stopwatch.close:Hide() end
  end)
  stopwatch:Hide()
  KHQOL.WindowLayers:RegisterWindow(stopwatch)

  local f = CreateFrame("Frame", "ForeverClockToolsFrame", UIParent, "BackdropTemplate")
  f:SetSize(TOOL_WIDTH,TOOL_HEIGHT); f:SetPoint("CENTER", 0, -80); f:SetFrameStrata("DIALOG")
  KHQOL.WindowLayers:RegisterWindow(f)
  self.MakeBackdrop(f, 1, .78, .18, .95); MakeMovable(f,"tools")
  -- Scale only the artwork/controls. The outer frame keeps unscaled saved
  -- offsets, a matching hit rectangle, and the existing screen clamp.
  local body=CreateFrame("Frame",nil,f)
  body:SetSize(TOOL_WIDTH,TOOL_HEIGHT);body:SetPoint("CENTER",f,"CENTER");body:EnableMouse(false)
  f.toolsContent=body
  local title = NewLabel(body, "알람 / 타이머", 17); title:SetPoint("TOPLEFT", 14, -12)
  f.stopwatchButton = WatchIconButton(body, function() stopwatch:SetShown(not stopwatch:IsShown()) end); f.stopwatchButton:SetPoint("TOPRIGHT", -42, -8)
  f.close = PlainCloseButton(body, function() f:Hide() end); f.close:SetPoint("TOPRIGHT", -9, -7)
  f.timerTab = NewButton(body, "타이머", 88, function() f:SelectMode("timer") end); f.timerTab:SetPoint("TOPLEFT", 16, -40)
  f.alarmTab = NewButton(body, "알람", 88, function() f:SelectMode("alarm") end); f.alarmTab:SetPoint("LEFT", f.timerTab, "RIGHT", 4, 0)
  f.fold=NewButton(body,"접기",62,function() FC:SetClockTimerDisplay("bar") end);f.fold:SetPoint("TOPRIGHT",-73,-8)

  local bar=CreateFrame("Frame","ForeverClockTimerBar",UIParent,"BackdropTemplate")
  bar:SetSize(314,42);bar:SetPoint("CENTER",UIParent,"CENTER",0,-120);bar:SetFrameStrata("DIALOG")
  KHQOL.WindowLayers:RegisterWindow(bar)
  self.MakeBackdrop(bar,1,.78,.18,.95);MakeMovable(bar,"timerBar")
  bar.nameText=NewLabel(bar,"타이머",14);bar.nameText:SetPoint("LEFT",10,0);bar.nameText:SetWidth(54);bar.nameText:SetJustifyH("LEFT")
  bar.time=NewLabel(bar,"00:00",14);bar.time:SetPoint("LEFT",69,0);bar.time:SetWidth(72)
  bar.progress=CreateFrame("StatusBar",nil,bar);bar.progress:SetSize(52,10);bar.progress:SetPoint("LEFT",145,0)
  bar.progress:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8");bar.progress:SetStatusBarColor(.24,.76,.66);bar.progress:SetMinMaxValues(0,1);bar.progress:SetValue(0)
  local track=bar.progress:CreateTexture(nil,"BACKGROUND");track:SetAllPoints();track:SetColorTexture(.17,.21,.22,1)
  bar.pause=IconButton(bar,"play",28,function() f:ToggleTimer(false) end);bar.pause:SetPoint("LEFT",201,0);bar.pause:SetEnabled(false)
  bar.expand=NewButton(bar,"펼치기",52,function() FC:SetClockTimerDisplay("full") end);bar.expand:SetPoint("LEFT",232,0)
  bar.close=PlainCloseButton(bar,function() bar:Hide() end);bar.close:SetPoint("RIGHT",-5,0)

  f.timerLabel = NewLabel(body, "타이머(분:초)", 14); f.timerLabel:SetPoint("TOPLEFT", 16, -82)
  f.timerInput = CreateFrame("EditBox", nil, body, "InputBoxTemplate")
  f.timerInput:SetPoint("LEFT", f.timerLabel, "RIGHT", 10, 0); f.timerInput:SetSize(38, 22); f.timerInput:SetNumeric(true); f.timerInput:SetMaxLetters(3); f.timerInput:SetAutoFocus(false); SetFont(f.timerInput, 14); f.timerInput:SetText(string.format("%02d", settings.timerMinutes or 5))
  f.timerColon = NewLabel(body, ":", 16); f.timerColon:SetPoint("LEFT", f.timerInput, "RIGHT", 1, 0)
  f.timerSecondsInput = CreateFrame("EditBox", nil, body, "InputBoxTemplate")
  f.timerSecondsInput:SetPoint("LEFT", f.timerColon, "RIGHT", 1, 0); f.timerSecondsInput:SetSize(38, 22); f.timerSecondsInput:SetNumeric(true); f.timerSecondsInput:SetMaxLetters(2); f.timerSecondsInput:SetAutoFocus(false); SetFont(f.timerSecondsInput, 14); f.timerSecondsInput:SetText(string.format("%02d", settings.timerSeconds or 0))
  local function SetTimerStartState(running)
    f.timerStart:SetIcon(running and "pause" or "play")
    bar.pause:SetIcon(running and "pause" or "play")
    bar.pause:SetEnabled(running or (f.timerRemaining or 0)>0)
  end
  f.timerStart = IconButton(body,"play",48,function() f:ToggleTimer(true) end);f.timerStart:SetPoint("TOPRIGHT",-72,-75)
  f.timerReset = IconButton(body,"reset",48,function() f:ResetTimer() end);f.timerReset:SetPoint("TOPRIGHT",-18,-75)
  f.timerStatus = NewLabel(body,"타이머: 00:00:00",18);f.timerStatus:SetPoint("TOPLEFT",16,-114)
  f.timerFood=NewButton(body,"음식 15분",101,function()
    if not f:StartTimer(900,"음식") then f.timerNotice:SetText("초기화 후 시작하세요.") end
  end);f.timerFood:SetPoint("TOPLEFT",16,-143)
  f.timerNotice=NewLabel(body,"",12);f.timerNotice:SetPoint("LEFT",f.timerFood,"RIGHT",10,0);f.timerNotice:SetWidth(235);f.timerNotice:SetJustifyH("LEFT")
  local function setText(region,value) if region:GetText()~=value then region:SetText(value) end end
  function f:RenderTimer(now)
    local full=self:IsShown() and self.activeMode=="timer"
    local compact=bar:IsShown()
    if not full and not compact then return end
    now=now or GetTime()
    local remaining=self.timerEndsAt and math.max(0,self.timerEndsAt-now) or self.timerRemaining or 0
    local paused=not self.timerEndsAt and remaining>0
    local name=self.timerName or "타이머"
    local formatted=Format(remaining)
    if full then
      setText(self.timerStatus,name..": "..formatted..(paused and " (일시정지)" or ""))
      self.timerStatus:SetAlpha(paused and (.45+math.abs(math.sin(now*4))*.55) or 1)
    end
    if compact then
      setText(bar.nameText,name);setText(bar.time,remaining<3600 and formatted:sub(4) or formatted)
      bar.progress:SetValue(self.timerDuration and math.min(1,remaining/self.timerDuration) or 0)
    end
  end
  function f:StartTimer(duration,name)
    if self.timerEndsAt or (self.timerRemaining or 0)>0 or not KHQOL.IsPublicNumber(duration) or duration<=0 then return false end
    self.timerName,self.timerDuration=name,duration
    self.timerEndsAt,self.timerRemaining=GetTime()+duration,nil
    self.timerNotice:SetText("");SetTimerStartState(true);self:RenderTimer();EnsureToolsTicker()
    return true
  end
  function f:ResetTimer(keepTicker)
    self.timerEndsAt,self.timerRemaining,self.timerName,self.timerDuration=nil,nil,nil,nil
    self.timerNotice:SetText("");SetTimerStartState(false);self:RenderTimer()
    if not keepTicker then StopToolsTickerIfIdle() end
  end
  function f:ExpireTimer(now)
    if not self.timerEndsAt or now<self.timerEndsAt then return false end
    local name=self.timerName
    self:ResetTimer(true)
    Notify(name=="음식" and "음식 15분 타이머가 종료되었습니다." or "타이머가 종료되었습니다.")
    return true
  end
  function f:ToggleTimer(allowStart)
    local now=GetTime()
    if self.timerEndsAt then
      if self:ExpireTimer(now) then return end
      self.timerRemaining,self.timerEndsAt=self.timerEndsAt-now,nil
      SetTimerStartState(false);self:RenderTimer(now);StopToolsTickerIfIdle()
    elseif (self.timerRemaining or 0)>0 then
      self.timerEndsAt,self.timerRemaining=now+self.timerRemaining,nil
      self.timerNotice:SetText("");SetTimerStartState(true);self:RenderTimer(now);EnsureToolsTicker()
    elseif allowStart then
      local minutes=math.max(0,math.min(999,tonumber(self.timerInput:GetText()) or 0))
      local seconds=math.max(0,math.min(59,tonumber(self.timerSecondsInput:GetText()) or 0))
      if self:StartTimer(minutes*60+seconds,"타이머") then
        settings.timerMinutes,settings.timerSeconds=minutes,seconds
        if KHQOL.SaveCurrentProfile then KHQOL:SaveCurrentProfile() end
      end
    end
  end

  f.alarmLabel = NewLabel(body, "알람", 14); f.alarmLabel:SetPoint("TOPLEFT", 16, -82)
  f.formatToggle = NewButton(body, "", 46, function()
    settings.alarm24Hour = not settings.alarm24Hour
    if not settings.alarm24Hour and (settings.alarmHour or 1) > 12 then settings.alarmHour = ((settings.alarmHour - 1) % 12) + 1 end
    f:BuildAlarmHour()
  end); f.formatToggle:SetPoint("TOPLEFT", 78, -80)
  f.alarmStart = IconButton(body, "play", 48, function()
    f.alarmActive = not f.alarmActive; f.alarmFired = false; f.alarmStart:SetIcon(f.alarmActive and "pause" or "play")
    if f.alarmActive and EnsureToolsTicker then EnsureToolsTicker() elseif StopToolsTickerIfIdle then StopToolsTickerIfIdle() end
  end); f.alarmStart:SetPoint("TOPRIGHT", -72, -75)
  f.ampm = MenuButton(body, 72, { { "AM", "오전" }, { "PM", "오후" } }, function() return settings.alarmAMPM == "PM" and "오후" or "오전" end, function(v) settings.alarmAMPM = v end); f.ampm:SetPoint("TOPLEFT", 16, -114)
  f.minute = MenuButton(body, 58, Choices(0, 55, 5), function() return string.format("%02d", settings.alarmMinute or 0) end, function(v) settings.alarmMinute = v end)
  f.second = MenuButton(body, 58, Choices(0, 55, 5), function() return string.format("%02d", settings.alarmSecond or 0) end, function(v) settings.alarmSecond = v end)
  function f:BuildAlarmHour()
    if self.hour then self.hour:Hide(); self.hour.menu:Hide() end
    self.ampm:SetShown(not settings.alarm24Hour)
    self.hourButtons=self.hourButtons or {}
    local key=settings.alarm24Hour and "24" or "12"
    if not self.hourButtons[key] then
      self.hourButtons[key]=MenuButton(body, 58, Choices(settings.alarm24Hour and 0 or 1, settings.alarm24Hour and 23 or 12), function() return string.format("%02d", settings.alarmHour or 0) end, function(v) settings.alarmHour = v end)
    end
    self.hour=self.hourButtons[key]; self.hour:ClearAllPoints(); self.hour:Refresh(); self.hour:Show()
    if settings.alarm24Hour then self.hour:SetPoint("TOPLEFT", 16, -114) else self.hour:SetPoint("LEFT", self.ampm, "RIGHT", 6, 0) end
    self.minute:ClearAllPoints(); self.minute:SetPoint("LEFT", self.hour, "RIGHT", 6, 0)
    self.second:ClearAllPoints(); self.second:SetPoint("LEFT", self.minute, "RIGHT", 6, 0)
    self.formatToggle:SetText(settings.alarm24Hour and "24H" or "12H"); self.ampm:Refresh(); self.minute:Refresh(); self.second:Refresh()
    if self.alarmControls then
      self.alarmControls[7] = self.hour
      self.hour:SetShown(self.activeMode == "alarm")
    end
  end
  f:BuildAlarmHour()
  f.timerControls = { f.timerLabel, f.timerInput, f.timerColon, f.timerSecondsInput, f.timerStart, f.timerReset, f.timerStatus, f.timerFood, f.timerNotice, f.fold }
  f.alarmControls = { f.alarmLabel, f.formatToggle, f.alarmStart, f.ampm, f.minute, f.second, f.hour }
  function f:CloseAlarmMenus()
    for _,control in ipairs({self.ampm,self.hour,self.minute,self.second}) do control.menu:Hide() end
  end
  function f:SelectMode(mode)
    self.activeMode = mode
    for _, control in ipairs(self.timerControls) do control:SetShown(mode == "timer") end
    for _, control in ipairs(self.alarmControls) do control:SetShown(mode == "alarm") end
    self.ampm:SetShown(mode == "alarm" and not settings.alarm24Hour)
    self:CloseAlarmMenus()
    self.timerTab:SetEnabled(mode ~= "timer")
    self.alarmTab:SetEnabled(mode ~= "alarm")
    self:RenderTimer()
    if EnsureToolsTicker and mode=="timer" and (self.timerRemaining or 0)>0 and self:IsShown() then EnsureToolsTicker()
    elseif StopToolsTickerIfIdle then StopToolsTickerIfIdle() end
  end
  f:SelectMode("timer")
  f.messageCheck = NewCheck(body, "메시지", function(self) f.messageInput:SetEnabled(self:GetChecked()) end); f.messageCheck:SetPoint("TOPLEFT", 16, -188)
  f.soundCheck = NewCheck(body, "소리", function(self) settings.alarmSound = self:GetChecked() and true or false end); f.soundCheck:SetPoint("TOPLEFT", 126, -188); f.soundCheck:SetChecked(settings.alarmSound ~= false)
  f.soundMurloc = NewRadio(body, "멀록", function()
    settings.alarmSoundChoice = "murloc"; f.soundMurloc:SetChecked(true); f.soundAlarm:SetChecked(false)
  end); f.soundMurloc:SetPoint("CENTER", f.soundCheck, "CENTER", 80, 0)
  f.soundAlarm = NewRadio(body, "알람", function()
    settings.alarmSoundChoice = "alarm"; f.soundMurloc:SetChecked(false); f.soundAlarm:SetChecked(true)
  end); f.soundAlarm:SetPoint("CENTER", f.soundCheck, "CENTER", 142, 0)
  f.soundMurloc:SetChecked(settings.alarmSoundChoice == "murloc"); f.soundAlarm:SetChecked(settings.alarmSoundChoice ~= "murloc")
  f.alertSize = NewLabel(body, (settings.alertFontSize or 24) .. " px", 12); f.alertSize:SetPoint("CENTER", f.soundCheck, "CENTER", 213, 0)
  f.messageInput = CreateFrame("EditBox", nil, body, "InputBoxTemplate")
  f.messageInput:SetPoint("TOPLEFT", 16, -224); f.messageInput:SetSize(230, 22); f.messageInput:SetMaxLetters(20); f.messageInput:SetAutoFocus(false); SetFont(f.messageInput, 14); f.messageInput:SetText(settings.alarmMessage or "")
  f.messageInput:SetScript("OnTextChanged", function(self) settings.alarmMessage = self:GetText() end)
  f.messageMinus = NewButton(body, "-", 30, function()
    settings.alertFontSize = math.max(20, (settings.alertFontSize or 24) - 2)
    f.alertSize:SetText(settings.alertFontSize .. " px")
  end); f.messageMinus:SetPoint("LEFT", f.messageInput, "RIGHT", 7, 0)
  f.messageTest = NewButton(body, "테스트", 56, function()
    if messageLayer:IsShown() and messageLayer.isTest then
      messageLayer.isTest = false; messageLayer:EnableMouse(false); messageLayer:Hide()
      if StopToolsTickerIfIdle then StopToolsTickerIfIdle() end
      return
    end
    local message = f.messageCheck:GetChecked() and f.messageInput:GetText() or "메시지 테스트"
    FC:ShowAlertMessage(message ~= "" and message or "메시지 테스트", true)
  end); f.messageTest:SetPoint("LEFT", f.messageMinus, "RIGHT", 4, 0)
  f.messagePlus = NewButton(body, "+", 30, function()
    settings.alertFontSize = math.min(48, (settings.alertFontSize or 24) + 2)
    f.alertSize:SetText(settings.alertFontSize .. " px")
  end); f.messagePlus:SetPoint("LEFT", f.messageTest, "RIGHT", 4, 0)
  f.messageCheck:SetChecked((settings.alarmMessage or "") ~= ""); f.messageInput:SetEnabled(f.messageCheck:GetChecked())
  Notify=function(defaultMessage)
    local message = f.messageCheck:GetChecked() and f.messageInput:GetText() or defaultMessage
    if message == "" then message = defaultMessage end
    FC:Print(message)
    FC:ShowAlertMessage(message)
    if f.soundCheck:GetChecked() and PlaySoundFile then
      local sound = settings.alarmSoundChoice == "murloc" and "mMurlocAggroOld.ogg" or "AlarmClockWarning2.ogg"
      PlaySoundFile(SOUND_PATH .. sound, "Dialog")
    end
  end
  -- This ticker is deliberately independent of the visible window.  Timers
  -- and alarms must continue while the player closes the control panel.
  local function TickTools()
    local time=GetTime()
    if messageLayer.hideAt and time>=messageLayer.hideAt then messageLayer.hideAt=nil;messageLayer:Hide() end
    if not f:ExpireTimer(time) and (f.timerEndsAt or f.timerRemaining) then f:RenderTimer(time) end
    if f.alarmActive then
      local now, hour = date("*t"), settings.alarmHour or 0
      if not settings.alarm24Hour then hour = hour % 12; if settings.alarmAMPM == "PM" then hour = hour + 12 end end
      if now.hour == hour and now.min == (settings.alarmMinute or 0) and now.sec == (settings.alarmSecond or 0) and not f.alarmFired then
        f.alarmFired = true
        Notify("알람 시간입니다.")
      end
    end
    if StopToolsTickerIfIdle then StopToolsTickerIfIdle() end
  end
  StopToolsTickerIfIdle = function()
    local visiblePause=f:IsShown() and f.activeMode=="timer" and (f.timerRemaining or 0)>0
    if f.timerEndsAt or visiblePause or (f.alarmActive and not f.alarmFired) or messageLayer.hideAt then return end
    if FC.clockToolsTicker then
      FC.clockToolsTicker:Cancel()
      FC.clockToolsTicker = nil
    end
  end
  EnsureToolsTicker = function()
    if not FC.clockToolsTicker and C_Timer and C_Timer.NewTicker then
      FC.clockToolsTicker = C_Timer.NewTicker(0.1, TickTools)
    end
  end
  f:HookScript("OnHide",function()
    f:CloseAlarmMenus();f.timerInput:ClearFocus();f.timerSecondsInput:ClearFocus();f.messageInput:ClearFocus()
    StopToolsTickerIfIdle()
  end)
  f:HookScript("OnShow",function()
    f:RenderTimer()
    if f.activeMode=="timer" and (f.timerRemaining or 0)>0 then EnsureToolsTicker() end
  end)
  bar:HookScript("OnShow",function() f:RenderTimer() end)
  f:Hide();bar:Hide();self.clockToolsFrame,self.stopwatchFrame,self.timerBarFrame=f,stopwatch,bar
  self:ApplyClockToolsSize()
end

function FC:OpenClockTools(mode)
  local f,bar=self.clockToolsFrame,self.timerBarFrame
  if not f or not bar then return false end
  mode=mode or f.activeMode or "timer"
  if mode=="timer" and self.db.clockTools.timerDisplay=="bar" then
    f:SelectMode("timer");f:Hide();bar:Show()
  else
    bar:Hide();f:SelectMode(mode);f:Show()
  end
  f:RenderTimer()
  return true
end
function FC:SetClockTimerDisplay(mode)
  self.db.clockTools.timerDisplay=mode=="bar" and "bar" or "full"
  self:OpenClockTools("timer")
  KHQOL.PositionStore:Committed()
end
function FC:ToggleClockTools()
  local f,bar=self.clockToolsFrame,self.timerBarFrame
  if not f or not bar then return end
  if f:IsShown() or bar:IsShown() then f:Hide();bar:Hide() else self:OpenClockTools() end
end

function FC:RefreshClockTools()
  local f,settings=self.clockToolsFrame,self.db.clockTools
  if not f then return end
  f.timerInput:SetText(string.format("%02d",settings.timerMinutes or 5))
  f.timerSecondsInput:SetText(string.format("%02d",settings.timerSeconds or 0))
  f:BuildAlarmHour(); f:SelectMode(f.activeMode or "timer")
  f.soundCheck:SetChecked(settings.alarmSound~=false)
  f.soundMurloc:SetChecked(settings.alarmSoundChoice=="murloc"); f.soundAlarm:SetChecked(settings.alarmSoundChoice~="murloc")
  f.alertSize:SetText((settings.alertFontSize or 24).." px")
  self:ApplyClockToolsSize()
  if self.timerBarFrame:IsShown() or (f:IsShown() and f.activeMode=="timer") then self:OpenClockTools("timer") end
end
