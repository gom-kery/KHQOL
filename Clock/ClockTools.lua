local _, KHQOL = ...
local FC = KHQOL.modules.clock
local CONTROL_TEXTURE_PATH = "Interface\\AddOns\\KHQOL\\Clock\\Textures\\"
local SOUND_PATH = "Interface\\AddOns\\KHQOL\\Clock\\Sounds\\"

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
local function MakeMovable(frame)
  frame:SetMovable(true); frame:EnableMouse(true)
  frame:SetScript("OnMouseDown", function(self, button) if button == "LeftButton" and not FC.db.clockTools.positionLocked then self:StartMoving() end end)
  frame:SetScript("OnMouseUp", function(self, button) if button == "LeftButton" then self:StopMovingOrSizing() end end)
end
local function Choices(first, last, step)
  local values = {}
  for n = first, last, step or 1 do values[#values + 1] = { n, string.format("%02d", n) } end
  return values
end
local function MenuButton(parent, width, choices, getValue, setValue)
  local button = NewButton(parent, "", width, function(self) self.menu:SetShown(not self.menu:IsShown()) end)
  local menu = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  menu:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -2); menu:SetWidth(width + 6); menu:SetFrameStrata("DIALOG")
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
  local settings = self.db.clockTools
  -- The tools ticker is created only while a timer, an alarm, or an
  -- auto-hiding alert needs time-based updates.  The controls themselves do
  -- not require a permanent 20-times-per-second update loop.
  local EnsureToolsTicker, StopToolsTickerIfIdle

  local messageLayer = CreateFrame("Frame", "ForeverClockAlertMessageFrame", UIParent)
  messageLayer:SetSize(560, 64); messageLayer:SetPoint("CENTER", UIParent, "CENTER", 0, 160); messageLayer:SetFrameStrata("HIGH")
  messageLayer:SetMovable(true)
  messageLayer:EnableMouse(false)
  messageLayer.text = messageLayer:CreateFontString(nil, "OVERLAY")
  messageLayer.text:SetPoint("CENTER"); messageLayer.text:SetJustifyH("CENTER")
  messageLayer:Hide()
  self.alertMessageFrame = messageLayer
  messageLayer:SetScript("OnMouseDown", function(layer, button)
    if button == "LeftButton" and not FC.db.clockTools.positionLocked and layer.isTest and IsAltKeyDown and IsAltKeyDown() then layer:StartMoving() end
  end)
  messageLayer:SetScript("OnMouseUp", function(layer, button)
    if button == "LeftButton" then layer:StopMovingOrSizing() end
  end)
  function self:ShowAlertMessage(message, isTest)
    local layer = self.alertMessageFrame
    if not layer then return end
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
  self.MakeBackdrop(stopwatch, 1, .78, .18, .95); MakeMovable(stopwatch)
  stopwatch.time = NewLabel(stopwatch, "00:00:00", 22); stopwatch.time:SetPoint("LEFT", 14, 0)
  stopwatch.start = IconButton(stopwatch, "play", 42, function()
    stopwatch.running = not stopwatch.running
    if stopwatch.running then stopwatch.startedAt = GetTime() - (stopwatch.elapsed or 0) end
    stopwatch.start:SetIcon(stopwatch.running and "pause" or "play")
  end); stopwatch.start:SetPoint("LEFT", stopwatch.time, "RIGHT", 16, 0)
  stopwatch.reset = IconButton(stopwatch, "reset", 42, function()
    stopwatch.running, stopwatch.elapsed = false, 0; stopwatch.time:SetText("00:00:00"); stopwatch.start:SetIcon("play")
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
    if stopwatch.running then stopwatch.elapsed = GetTime() - stopwatch.startedAt; stopwatch.time:SetText(Format(stopwatch.elapsed)) end
    if stopwatch.closeHideAt and GetTime() >= stopwatch.closeHideAt then stopwatch.closeHideAt = nil; stopwatch.close:Hide() end
  end)
  stopwatch:Hide()

  local f = CreateFrame("Frame", "ForeverClockToolsFrame", UIParent, "BackdropTemplate")
  f:SetSize(390, 282); f:SetPoint("CENTER", 0, -80); f:SetFrameStrata("DIALOG")
  self.MakeBackdrop(f, 1, .78, .18, .95); MakeMovable(f)
  local title = NewLabel(f, "알람 / 타이머", 17); title:SetPoint("TOPLEFT", 14, -12)
  f.stopwatchButton = WatchIconButton(f, function() stopwatch:SetShown(not stopwatch:IsShown()) end); f.stopwatchButton:SetPoint("TOPRIGHT", -42, -8)
  f.close = PlainCloseButton(f, function() f:Hide() end); f.close:SetPoint("TOPRIGHT", -9, -7)
  f.timerTab = NewButton(f, "타이머", 88, function() f:SelectMode("timer") end); f.timerTab:SetPoint("TOPLEFT", 16, -40)
  f.alarmTab = NewButton(f, "알람", 88, function() f:SelectMode("alarm") end); f.alarmTab:SetPoint("LEFT", f.timerTab, "RIGHT", 4, 0)

  f.timerLabel = NewLabel(f, "타이머(분:초)", 14); f.timerLabel:SetPoint("TOPLEFT", 16, -82)
  f.timerInput = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
  f.timerInput:SetPoint("LEFT", f.timerLabel, "RIGHT", 10, 0); f.timerInput:SetSize(38, 22); f.timerInput:SetNumeric(true); f.timerInput:SetMaxLetters(3); f.timerInput:SetAutoFocus(false); SetFont(f.timerInput, 14); f.timerInput:SetText(string.format("%02d", settings.timerMinutes or 5))
  f.timerColon = NewLabel(f, ":", 16); f.timerColon:SetPoint("LEFT", f.timerInput, "RIGHT", 1, 0)
  f.timerSecondsInput = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
  f.timerSecondsInput:SetPoint("LEFT", f.timerColon, "RIGHT", 1, 0); f.timerSecondsInput:SetSize(38, 22); f.timerSecondsInput:SetNumeric(true); f.timerSecondsInput:SetMaxLetters(2); f.timerSecondsInput:SetAutoFocus(false); SetFont(f.timerSecondsInput, 14); f.timerSecondsInput:SetText(string.format("%02d", settings.timerSeconds or 0))
  local function SetTimerStartState(running)
    f.timerStart:SetIcon(running and "pause" or "play")
  end
  f.timerStart = IconButton(f, "play", 48, function()
    if f.timerEndsAt then
      f.timerRemaining = math.max(0, f.timerEndsAt - GetTime())
      f.timerEndsAt = nil
      SetTimerStartState(false)
      if EnsureToolsTicker then EnsureToolsTicker() end
      return
    end
    local minutes = tonumber(f.timerInput:GetText()) or 0
    local seconds = math.min(59, tonumber(f.timerSecondsInput:GetText()) or 0)
    if f.timerRemaining and f.timerRemaining > 0 then f.timerEndsAt = GetTime() + f.timerRemaining
    elseif minutes > 0 or seconds > 0 then settings.timerMinutes, settings.timerSeconds = minutes, seconds; f.timerEndsAt = GetTime() + minutes * 60 + seconds
    else return end
    SetTimerStartState(true)
    if EnsureToolsTicker then EnsureToolsTicker() end
  end); f.timerStart:SetPoint("TOPRIGHT", -72, -75)
  f.timerReset = IconButton(f, "reset", 48, function()
    f.timerEndsAt, f.timerRemaining = nil, nil; SetTimerStartState(false); f.timerStatus:SetText("타이머: 00:00:00"); f.timerStatus:SetAlpha(1)
    if StopToolsTickerIfIdle then StopToolsTickerIfIdle() end
  end); f.timerReset:SetPoint("TOPRIGHT", -18, -75)
  f.timerStatus = NewLabel(f, "타이머: 00:00:00", 18); f.timerStatus:SetPoint("TOPLEFT", 16, -114)

  f.alarmLabel = NewLabel(f, "알람", 14); f.alarmLabel:SetPoint("TOPLEFT", 16, -82)
  f.formatToggle = NewButton(f, "", 46, function()
    settings.alarm24Hour = not settings.alarm24Hour
    if not settings.alarm24Hour and (settings.alarmHour or 1) > 12 then settings.alarmHour = ((settings.alarmHour - 1) % 12) + 1 end
    f:BuildAlarmHour()
  end); f.formatToggle:SetPoint("TOPLEFT", 78, -80)
  f.alarmStart = IconButton(f, "play", 48, function()
    f.alarmActive = not f.alarmActive; f.alarmFired = false; f.alarmStart:SetIcon(f.alarmActive and "pause" or "play")
    if f.alarmActive and EnsureToolsTicker then EnsureToolsTicker() elseif StopToolsTickerIfIdle then StopToolsTickerIfIdle() end
  end); f.alarmStart:SetPoint("TOPRIGHT", -72, -75)
  f.ampm = MenuButton(f, 72, { { "AM", "오전" }, { "PM", "오후" } }, function() return settings.alarmAMPM == "PM" and "오후" or "오전" end, function(v) settings.alarmAMPM = v end); f.ampm:SetPoint("TOPLEFT", 16, -114)
  f.minute = MenuButton(f, 58, Choices(0, 55, 5), function() return string.format("%02d", settings.alarmMinute or 0) end, function(v) settings.alarmMinute = v end)
  f.second = MenuButton(f, 58, Choices(0, 55, 5), function() return string.format("%02d", settings.alarmSecond or 0) end, function(v) settings.alarmSecond = v end)
  function f:BuildAlarmHour()
    if self.hour then self.hour:Hide(); self.hour.menu:Hide() end
    self.ampm:SetShown(not settings.alarm24Hour)
    self.hourButtons=self.hourButtons or {}
    local key=settings.alarm24Hour and "24" or "12"
    if not self.hourButtons[key] then
      self.hourButtons[key]=MenuButton(self, 58, Choices(settings.alarm24Hour and 0 or 1, settings.alarm24Hour and 23 or 12), function() return string.format("%02d", settings.alarmHour or 0) end, function(v) settings.alarmHour = v end)
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
  f.timerControls = { f.timerLabel, f.timerInput, f.timerColon, f.timerSecondsInput, f.timerStart, f.timerReset, f.timerStatus }
  f.alarmControls = { f.alarmLabel, f.formatToggle, f.alarmStart, f.ampm, f.minute, f.second, f.hour }
  function f:SelectMode(mode)
    self.activeMode = mode
    for _, control in ipairs(self.timerControls) do control:SetShown(mode == "timer") end
    for _, control in ipairs(self.alarmControls) do control:SetShown(mode == "alarm") end
    self.ampm:SetShown(mode == "alarm" and not settings.alarm24Hour)
    if self.hour and self.hour.menu then self.hour.menu:Hide() end
    self.timerTab:SetEnabled(mode ~= "timer")
    self.alarmTab:SetEnabled(mode ~= "alarm")
  end
  f:SelectMode("timer")
  f.messageCheck = NewCheck(f, "메시지", function(self) f.messageInput:SetEnabled(self:GetChecked()) end); f.messageCheck:SetPoint("TOPLEFT", 16, -188)
  f.soundCheck = NewCheck(f, "소리", function(self) settings.alarmSound = self:GetChecked() and true or false end); f.soundCheck:SetPoint("TOPLEFT", 126, -188); f.soundCheck:SetChecked(settings.alarmSound ~= false)
  f.soundMurloc = NewRadio(f, "멀록", function()
    settings.alarmSoundChoice = "murloc"; f.soundMurloc:SetChecked(true); f.soundAlarm:SetChecked(false)
  end); f.soundMurloc:SetPoint("CENTER", f.soundCheck, "CENTER", 80, 0)
  f.soundAlarm = NewRadio(f, "알람", function()
    settings.alarmSoundChoice = "alarm"; f.soundMurloc:SetChecked(false); f.soundAlarm:SetChecked(true)
  end); f.soundAlarm:SetPoint("CENTER", f.soundCheck, "CENTER", 142, 0)
  f.soundMurloc:SetChecked(settings.alarmSoundChoice == "murloc"); f.soundAlarm:SetChecked(settings.alarmSoundChoice ~= "murloc")
  f.alertSize = NewLabel(f, (settings.alertFontSize or 24) .. " px", 12); f.alertSize:SetPoint("CENTER", f.soundCheck, "CENTER", 213, 0)
  f.messageInput = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
  f.messageInput:SetPoint("TOPLEFT", 16, -224); f.messageInput:SetSize(230, 22); f.messageInput:SetMaxLetters(20); f.messageInput:SetAutoFocus(false); SetFont(f.messageInput, 14); f.messageInput:SetText(settings.alarmMessage or "")
  f.messageInput:SetScript("OnTextChanged", function(self) settings.alarmMessage = self:GetText() end)
  f.messageMinus = NewButton(f, "-", 30, function()
    settings.alertFontSize = math.max(20, (settings.alertFontSize or 24) - 2)
    f.alertSize:SetText(settings.alertFontSize .. " px")
  end); f.messageMinus:SetPoint("LEFT", f.messageInput, "RIGHT", 7, 0)
  f.messageTest = NewButton(f, "테스트", 56, function()
    if messageLayer:IsShown() and messageLayer.isTest then
      messageLayer.isTest = false; messageLayer:EnableMouse(false); messageLayer:Hide()
      if StopToolsTickerIfIdle then StopToolsTickerIfIdle() end
      return
    end
    local message = f.messageCheck:GetChecked() and f.messageInput:GetText() or "메시지 테스트"
    FC:ShowAlertMessage(message ~= "" and message or "메시지 테스트", true)
  end); f.messageTest:SetPoint("LEFT", f.messageMinus, "RIGHT", 4, 0)
  f.messagePlus = NewButton(f, "+", 30, function()
    settings.alertFontSize = math.min(48, (settings.alertFontSize or 24) + 2)
    f.alertSize:SetText(settings.alertFontSize .. " px")
  end); f.messagePlus:SetPoint("LEFT", f.messageTest, "RIGHT", 4, 0)
  f.messageCheck:SetChecked((settings.alarmMessage or "") ~= ""); f.messageInput:SetEnabled(f.messageCheck:GetChecked())
  local function Notify(defaultMessage)
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
    if messageLayer.hideAt and GetTime() >= messageLayer.hideAt then messageLayer.hideAt = nil; messageLayer:Hide() end
    if f.timerEndsAt then
      f.timerRemaining = math.max(0, f.timerEndsAt - GetTime()); f.timerStatus:SetText("타이머: " .. Format(f.timerRemaining)); f.timerStatus:SetAlpha(1)
      if f.timerRemaining <= 0 then f.timerEndsAt, f.timerRemaining = nil, nil; SetTimerStartState(false); Notify("타이머가 종료되었습니다.") end
    elseif f.timerRemaining and f.timerRemaining > 0 then
      f.timerStatus:SetText("타이머: " .. Format(f.timerRemaining) .. " (일시정지)"); f.timerStatus:SetAlpha(.45 + math.abs(math.sin(GetTime() * 4)) * .55)
    end
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
    local timerPaused = f.timerRemaining and f.timerRemaining > 0
    if f.timerEndsAt or timerPaused or f.alarmActive or messageLayer.hideAt then return end
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
  -- Rebuilding the tools frame (for example after a UI reload) must never
  -- leave an older ticker alive.
  if self.clockToolsTicker then self.clockToolsTicker:Cancel(); self.clockToolsTicker = nil end
  f:Hide(); self.clockToolsFrame, self.stopwatchFrame = f, stopwatch
end

function FC:ToggleClockTools()
  if self.clockToolsFrame then self.clockToolsFrame:SetShown(not self.clockToolsFrame:IsShown()) end
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
end
