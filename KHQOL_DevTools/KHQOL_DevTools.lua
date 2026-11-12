-- KHQOL DevTools v0.1.5.  Standalone: does not read or change KHQOL state.
local addonName = ...
local DevTools = CreateFrame("Frame")
_G.KHQOL_DevTools = DevTools
_G.BINDING_HEADER_KHQOL_DEVTOOLS = "KHQOL DevTools"
_G.BINDING_NAME_KHQOL_DEVTOOLS_CAPTURE_FRAME = "Capture frame under cursor"

local MAX_POINTS, MAX_PARENTS = 16, 16
local SAMPLE_SECONDS = 0.25
local defaults = { frameTracking = true, consoleEnabled = true, consolePaused = false, maxLogs = 100, positionMaxSamples = 60 }
local db, main, copyFrame, copyEdit, frameText, consoleText, positionText, positionSampler
local selectedTab, elapsed, latestFrame, latestAPI, consoleLogs = "Console", 0, nil, nil, {}
local writingDevToolsMessage = false
local positionSampling, positionElapsed, positionSamples = false, 0, {}
local refreshConsole, refreshFrames, refreshPosition, showCopy, setTab, updateTracking

-- Independent reproduction of KHQOL's restrained settings palette; no KHQOL UI dependency.
local function styleSurface(frame, alpha)
  if not frame or not frame.SetBackdrop then return end
  frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
  frame:SetBackdropColor(.065, .065, .065, alpha or 1)
  frame:SetBackdropBorderColor(.36, .36, .36, 1)
end

local function safe(object, method, ...)
  if not object or type(object[method]) ~= "function" then return nil end
  local ok, a, b, c, d, e = pcall(object[method], object, ...)
  if ok then return a, b, c, d, e end
end

local function value(v)
  if v == nil then return "(unavailable)" end
  local ok, result = pcall(function()
    if type(v) == "number" then
      return string.format("%.2f", v):gsub("0+$", ""):gsub("%.$", "")
    end
    return tostring(v)
  end)
  return ok and result or "(protected)"
end

local function frameName(frame)
  return value(safe(frame, "GetName") or safe(frame, "GetDebugName"))
end

local function printChat(message)
  if DEFAULT_CHAT_FRAME then
    writingDevToolsMessage = true
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffKHQOL DevTools:|r " .. message)
    writingDevToolsMessage = false
  end
end

local function trimLogs()
  local limit = tonumber(db.maxLogs) or defaults.maxLogs
  limit = math.max(10, math.min(500, math.floor(limit)))
  db.maxLogs = limit
  while #consoleLogs > limit do table.remove(consoleLogs, 1) end
end

local function timestamp()
  return date and date("%H:%M:%S") or "?"
end

local function addLog(message)
  if not db.consoleEnabled or db.consolePaused or type(message) ~= "string" or message == "" then return end
  local last = consoleLogs[#consoleLogs]
  -- Some clients dispatch the same system line to more than one chat frame.
  if last and last.message == message and last.at == timestamp() then return end
  consoleLogs[#consoleLogs + 1] = { at = timestamp(), message = message }
  trimLogs()
  if refreshConsole then refreshConsole() end
end

local function collectFocus()
  local focus, api
  if type(GetMouseFoci) == "function" then
    local ok, foci = pcall(GetMouseFoci)
    if ok and type(foci) == "table" then focus, api = foci[1], "GetMouseFoci" end
  end
  if not focus and type(GetMouseFocus) == "function" then
    local ok, result = pcall(GetMouseFocus)
    if ok then focus, api = result, "GetMouseFocus" end
  end
  -- Never replace an external sample with this addon's own panel or copy window.
  local current = focus
  for _ = 1, 32 do
    if not current then break end
    if current == main or current == copyFrame then return nil, api end
    local parent = safe(current, "GetParent")
    if parent == current then break end
    current = parent
  end
  return focus, api
end

local function describe(frame, api)
  if not frame then
    return "[KHQOL DevTools — Frame Inspector]\n\nNo inspectable frame is under the cursor. Move the cursor over a Blizzard or addon frame, then use the capture key."
  end
  local parent = safe(frame, "GetParent")
  local lines = {
    "[KHQOL DevTools — Frame Inspector]",
    "Client: WoW Forever",
    "Capture: " .. (date and date("%Y-%m-%d %H:%M:%S") or "(unavailable)"),
    "",
    "Frame: " .. value(safe(frame, "GetName")),
    "Debug Name: " .. value(safe(frame, "GetDebugName")),
    "Type: " .. value(safe(frame, "GetObjectType")),
    "Parent: " .. frameName(parent),
    "Size: " .. value(safe(frame, "GetWidth")) .. " x " .. value(safe(frame, "GetHeight")),
    "Strata: " .. value(safe(frame, "GetFrameStrata")),
    "Level: " .. value(safe(frame, "GetFrameLevel")),
    "Mouse Enabled: " .. value(safe(frame, "IsMouseEnabled")),
    "Movable: " .. value(safe(frame, "IsMovable")),
    "API Source: " .. value(api),
    "",
    "Anchors:"
  }
  local count = safe(frame, "GetNumPoints")
  if type(count) == "number" and count > 0 then
    for i = 1, math.min(count, MAX_POINTS) do
      local point, relative, relativePoint, x, y = safe(frame, "GetPoint", i)
      lines[#lines + 1] = string.format("%d. %s / %s / %s / %s / %s", i, value(point), frameName(relative), value(relativePoint), value(x), value(y))
    end
  else
    lines[#lines + 1] = "(none or unavailable)"
  end
  lines[#lines + 1] = ""
  lines[#lines + 1] = "Parent Chain:"
  local current = frame
  for depth = 1, MAX_PARENTS do
    if not current then break end
    lines[#lines + 1] = depth .. ". " .. frameName(current)
    local nextParent = safe(current, "GetParent")
    if nextParent == current then break end
    current = nextParent
  end
  if GetBuildInfo then
    local version, build, _, interface = GetBuildInfo()
    lines[#lines + 1] = ""
    lines[#lines + 1] = "Client Build: " .. value(version) .. " / " .. value(build) .. " / " .. value(interface)
  end
  return table.concat(lines, "\n")
end

local function createButton(parent, label, width, height, handler)
  local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  button:SetSize(width, height)
  button:SetText(label)
  button:SetScript("OnClick", handler)
  button:SetScript("OnEnter", function(self) self:SetAlpha(1) end)
  button:SetScript("OnLeave", function(self) self:SetAlpha(.9) end)
  button:SetAlpha(.9)
  return button
end

local function createScrollText(parent, x, y, width, height)
  local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", x, y)
  scroll:SetSize(width, height)
  local child = CreateFrame("Frame", nil, scroll)
  child:SetWidth(width - 28)
  child:SetHeight(1)
  scroll:SetScrollChild(child)
  local text = child:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  text:SetPoint("TOPLEFT", 4, -4)
  text:SetWidth(width - 36)
  text:SetJustifyH("LEFT")
  text:SetJustifyV("TOP")
  return text, child
end

showCopy = function(snapshot)
  copyEdit:SetText(snapshot or "")
  copyFrame:Show()
  copyEdit:SetFocus()
  copyEdit:HighlightText()
end

local function formatLogs(latestOnly)
  local lines = { "[KHQOL DevTools — Chat Output]", "Captured: " .. (date and date("%Y-%m-%d %H:%M:%S") or "(unavailable)"), "Classification: observed from CHAT_MSG_SYSTEM and/or the default chat frame; cannot prove a line came from /run.", "" }
  local first = latestOnly and math.max(1, #consoleLogs) or 1
  if #consoleLogs == 0 then lines[#lines + 1] = "(No captured chat output.)" end
  if #consoleLogs > 0 then
    for i = first, #consoleLogs do
      local item = consoleLogs[i]
      lines[#lines + 1] = "[" .. item.at .. "] " .. item.message
    end
  end
  return table.concat(lines, "\n")
end

local function callAPI(fn, ...)
  if type(fn) ~= "function" then return false, "(not available)" end
  local function pack(...) return { n = select("#", ...), ... } end
  local results = pack(pcall(fn, ...))
  if not results[1] then return false, results[2] end
  local values = { n = results.n - 1 }
  for i = 2, results.n do values[i - 1] = results[i] end
  return true, values
end

local function apiLine(label, fn, ...)
  if type(fn) ~= "function" then return label .. ": unavailable" end
  local ok, results = callAPI(fn, ...)
  if not ok then return label .. ": error — " .. value(results) end
  if results.n == 0 then return label .. ": called (no return values)" end
  local values = {}
  for i = 1, results.n do values[#values + 1] = value(results[i]) end
  return label .. ": " .. table.concat(values, " / ")
end

local function mapPositionLine(label, fn, mapID)
  if type(fn) ~= "function" then return label .. ": unavailable" end
  if type(mapID) ~= "number" then return label .. ": not called (no numeric Map ID)" end
  local ok, results = callAPI(fn, mapID, "player")
  if not ok then return label .. ": error — " .. value(results) end
  local point = results[1]
  local x, y = safe(point, "GetXY")
  if x ~= nil or y ~= nil then return label .. ": " .. value(x) .. " / " .. value(y) end
  return label .. ": " .. value(point)
end

local function getBestMapID()
  if not C_Map or type(C_Map.GetBestMapForUnit) ~= "function" then return nil end
  local ok, results = callAPI(C_Map.GetBestMapForUnit, "player")
  return ok and results[1] or nil
end

local function positionSnapshot()
  local mapID = getBestMapID()
  local lines = {
    "[KHQOL DevTools — Position Diagnostics]",
    "Capture: " .. (date and date("%Y-%m-%d %H:%M:%S") or "(unavailable)"),
    "Combat: " .. value(InCombatLockdown and InCombatLockdown() or false),
    "",
    "API Availability and Current Results:",
    apiLine("UnitPosition(player)", UnitPosition, "player"),
    apiLine("C_Map.GetBestMapForUnit(player)", C_Map and C_Map.GetBestMapForUnit, "player"),
    mapPositionLine("C_Map.GetPlayerMapPosition(mapID, player)", C_Map and C_Map.GetPlayerMapPosition, mapID),
    apiLine("GetPlayerMapPosition(player)", GetPlayerMapPosition, "player"),
    apiLine("GetPlayerFacing()", GetPlayerFacing),
    apiLine("GetUnitSpeed(player)", GetUnitSpeed, "player"),
    apiLine("GetInstanceInfo()", GetInstanceInfo),
    "",
    "Resolved Map ID: " .. value(mapID),
    "Note: Availability/call success does not prove dungeon usability, floor identity, or map-image calibration."
  }
  return table.concat(lines, "\n")
end

local function trimPositionSamples()
  local limit = tonumber(db.positionMaxSamples) or 60
  limit = math.max(10, math.min(120, math.floor(limit)))
  db.positionMaxSamples = limit
  while #positionSamples > limit do table.remove(positionSamples, 1) end
end

local function recordPositionSample()
  positionSamples[#positionSamples + 1] = { at = timestamp(), text = positionSnapshot() }
  trimPositionSamples()
  if refreshPosition then refreshPosition() end
end

local function formatPositionReport()
  local lines = { positionSnapshot(), "", "Position Samples (manual 1-second collection):" }
  if #positionSamples == 0 then
    lines[#lines + 1] = "(No samples. Use Start Sampling, move, then Stop Sampling.)"
  else
    for i, sample in ipairs(positionSamples) do
      lines[#lines + 1] = "\n=== Sample " .. i .. " — " .. sample.at .. " ===\n" .. sample.text
    end
  end
  return table.concat(lines, "\n")
end

local function setPositionSampling(on)
  positionSampling = on and true or false
  positionElapsed = 0
  if not positionSampler then return end
  positionSampler:SetScript("OnUpdate", nil)
  if positionSampling then
    recordPositionSample()
    positionSampler:SetScript("OnUpdate", function(_, delta)
      positionElapsed = positionElapsed + delta
      if positionElapsed < 1 then return end
      positionElapsed = 0
      recordPositionSample()
    end)
  end
  if main and main.positionSamplingButton then
    main.positionSamplingButton:SetText(positionSampling and "Stop Sampling" or "Start Sampling")
  end
  if refreshPosition then refreshPosition() end
end

refreshConsole = function()
  if not consoleText then return end
  local state = db.consoleEnabled and (db.consolePaused and "Paused" or "Collecting") or "Disabled"
  consoleText:SetText("Status: " .. state .. " | Stored: " .. #consoleLogs .. " / " .. db.maxLogs .. "\n\n" .. formatLogs(false))
  consoleText:GetParent():SetHeight(math.max(1, consoleText:GetStringHeight() + 12))
end

refreshFrames = function()
  if not frameText then return end
  frameText:SetText(describe(latestFrame, latestAPI))
  frameText:GetParent():SetHeight(math.max(1, frameText:GetStringHeight() + 12))
end

refreshPosition = function()
  if not positionText then return end
  local state = positionSampling and "Sampling every 1 second" or "Stopped (no background position polling)"
  positionText:SetText("Status: " .. state .. " | Samples: " .. #positionSamples .. " / " .. db.positionMaxSamples .. "\n\n" .. positionSnapshot())
  positionText:GetParent():SetHeight(math.max(1, positionText:GetStringHeight() + 12))
end

updateTracking = function()
  DevTools:SetScript("OnUpdate", nil)
  if db.frameTracking and main and main:IsShown() and selectedTab == "Frames" then
    DevTools:SetScript("OnUpdate", function(_, delta)
      elapsed = elapsed + delta
      if elapsed < SAMPLE_SECONDS then return end
      elapsed = 0
      latestFrame, latestAPI = collectFocus()
      refreshFrames()
    end)
  end
end

DevTools.CaptureFrame = function(self)
  -- Query at the binding event, before opening any DevTools UI.
  local frame, api = collectFocus()
  if not frame then frame, api = latestFrame, latestAPI end
  local snapshot = describe(frame, api)
  showCopy(snapshot)
end

setTab = function(tab)
  selectedTab = tab
  main.consolePanel:SetShown(tab == "Console")
  main.framesPanel:SetShown(tab == "Frames")
  main.positionPanel:SetShown(tab == "Position")
  main.consoleTab:SetEnabled(tab ~= "Console")
  main.framesTab:SetEnabled(tab ~= "Frames")
  main.positionTab:SetEnabled(tab ~= "Position")
  updateTracking()
  if tab == "Console" then refreshConsole() elseif tab == "Frames" then refreshFrames() else refreshPosition() end
end

local function buildUI()
  main = CreateFrame("Frame", "KHQOLDevToolsMainFrame", UIParent, "BasicFrameTemplateWithInset")
  main:SetSize(650, 470)
  main:SetPoint("CENTER")
  styleSurface(main)
  main:SetMovable(true); main:EnableMouse(true); main:RegisterForDrag("LeftButton")
  main:SetScript("OnDragStart", main.StartMoving)
  main:SetScript("OnDragStop", main.StopMovingOrSizing)
  main:SetScript("OnShow", updateTracking)
  main:SetScript("OnHide", function() updateTracking(); setPositionSampling(false) end)
  main.title = main:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  main.title:SetPoint("LEFT", main.TitleBg, "LEFT", 5, 0)
  main.title:SetText("KHQOL DevTools v0.1.5")
  main.title:SetTextColor(114/255, 173/255, 165/255, 1)
  main:Hide()

  main.consoleTab = createButton(main, "Console", 100, 24, function() setTab("Console") end)
  main.consoleTab:SetPoint("TOPLEFT", 14, -30)
  main.framesTab = createButton(main, "Frames", 100, 24, function() setTab("Frames") end)
  main.framesTab:SetPoint("LEFT", main.consoleTab, "RIGHT", 4, 0)
  main.positionTab = createButton(main, "Position", 100, 24, function() setTab("Position") end)
  main.positionTab:SetPoint("LEFT", main.framesTab, "RIGHT", 4, 0)

  main.consolePanel = CreateFrame("Frame", nil, main, "BackdropTemplate")
  main.consolePanel:SetPoint("TOPLEFT", 10, -62); main.consolePanel:SetPoint("BOTTOMRIGHT", -10, 10)
  styleSurface(main.consolePanel, .96)
  local enabled = createButton(main.consolePanel, "Enable/Disable", 110, 22, function() db.consoleEnabled = not db.consoleEnabled; refreshConsole() end)
  enabled:SetPoint("TOPLEFT", 4, -2)
  local paused = createButton(main.consolePanel, "Pause/Resume", 100, 22, function() db.consolePaused = not db.consolePaused; refreshConsole() end)
  paused:SetPoint("LEFT", enabled, "RIGHT", 5, 0)
  local latest = createButton(main.consolePanel, "Copy Latest", 100, 22, function() showCopy(formatLogs(true)) end)
  latest:SetPoint("LEFT", paused, "RIGHT", 5, 0)
  local all = createButton(main.consolePanel, "Copy All", 85, 22, function() showCopy(formatLogs(false)) end)
  all:SetPoint("LEFT", latest, "RIGHT", 5, 0)
  local clear = createButton(main.consolePanel, "Clear", 65, 22, function() consoleLogs = {}; refreshConsole() end)
  clear:SetPoint("LEFT", all, "RIGHT", 5, 0)
  local limit = createButton(main.consolePanel, "Limit: " .. db.maxLogs, 90, 22, function(self)
    local choices = { 10, 50, 100, 250, 500 }
    local nextIndex = 1
    for i, candidate in ipairs(choices) do if candidate == db.maxLogs then nextIndex = (i % #choices) + 1 break end end
    db.maxLogs = choices[nextIndex]; trimLogs(); self:SetText("Limit: " .. db.maxLogs); refreshConsole()
  end)
  limit:SetPoint("LEFT", clear, "RIGHT", 5, 0)
  local logs, child = createScrollText(main.consolePanel, 2, -30, 610, 350)
  consoleText = logs

  main.framesPanel = CreateFrame("Frame", nil, main, "BackdropTemplate")
  main.framesPanel:SetPoint("TOPLEFT", 10, -62); main.framesPanel:SetPoint("BOTTOMRIGHT", -10, 10)
  styleSurface(main.framesPanel, .96)
  local tracking = createButton(main.framesPanel, "Tracking On/Off", 115, 22, function() db.frameTracking = not db.frameTracking; updateTracking(); refreshFrames() end)
  tracking:SetPoint("TOPLEFT", 4, -2)
  local capture = createButton(main.framesPanel, "Capture & Copy", 120, 22, function() DevTools:CaptureFrame() end)
  capture:SetPoint("LEFT", tracking, "RIGHT", 5, 0)
  local stack = createButton(main.framesPanel, "Frame Stack", 100, 22, function()
    if InCombatLockdown and InCombatLockdown() then printChat("Frame Stack cannot be opened in combat."); return end
    if type(FrameStackTooltip_Toggle) ~= "function" and LoadAddOn then pcall(LoadAddOn, "Blizzard_DebugTools") end
    if type(FrameStackTooltip_Toggle) == "function" then pcall(FrameStackTooltip_Toggle, false, true, true) else printChat("Blizzard_DebugTools is unavailable on this client.") end
  end)
  stack:SetPoint("LEFT", capture, "RIGHT", 5, 0)
  local frames, framesChild = createScrollText(main.framesPanel, 2, -30, 610, 350)
  frameText = frames

  main.positionPanel = CreateFrame("Frame", nil, main, "BackdropTemplate")
  main.positionPanel:SetPoint("TOPLEFT", 10, -62); main.positionPanel:SetPoint("BOTTOMRIGHT", -10, 10)
  styleSurface(main.positionPanel, .96)
  local snapshot = createButton(main.positionPanel, "Snapshot & Copy", 120, 22, function() showCopy(positionSnapshot()) end)
  snapshot:SetPoint("TOPLEFT", 4, -2)
  local sampling = createButton(main.positionPanel, "Start Sampling", 110, 22, function(self)
    setPositionSampling(not positionSampling)
  end)
  main.positionSamplingButton = sampling
  sampling:SetPoint("LEFT", snapshot, "RIGHT", 5, 0)
  local copyReport = createButton(main.positionPanel, "Copy Full Report", 120, 22, function() showCopy(formatPositionReport()) end)
  copyReport:SetPoint("LEFT", sampling, "RIGHT", 5, 0)
  local clearSamples = createButton(main.positionPanel, "Clear", 65, 22, function() positionSamples = {}; refreshPosition() end)
  clearSamples:SetPoint("LEFT", copyReport, "RIGHT", 5, 0)
  local sampleLimit = createButton(main.positionPanel, "Limit: " .. db.positionMaxSamples, 90, 22, function(self)
    local choices = { 10, 30, 60, 120 }
    local nextIndex = 1
    for i, candidate in ipairs(choices) do if candidate == db.positionMaxSamples then nextIndex = (i % #choices) + 1 break end end
    db.positionMaxSamples = choices[nextIndex]; trimPositionSamples(); self:SetText("Limit: " .. db.positionMaxSamples); refreshPosition()
  end)
  sampleLimit:SetPoint("LEFT", clearSamples, "RIGHT", 5, 0)
  local position, positionChild = createScrollText(main.positionPanel, 2, -30, 610, 350)
  positionText = position
  positionSampler = CreateFrame("Frame")

  copyFrame = CreateFrame("Frame", "KHQOLDevToolsCopyFrame", UIParent, "BasicFrameTemplateWithInset")
  copyFrame:SetSize(680, 500); copyFrame:SetPoint("CENTER")
  copyFrame:SetFrameStrata("DIALOG")
  styleSurface(copyFrame)
  copyFrame.title = copyFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  copyFrame.title:SetPoint("LEFT", copyFrame.TitleBg, "LEFT", 5, 0); copyFrame.title:SetText("Copy to clipboard: Ctrl+C, then Esc")
  local scroll = CreateFrame("ScrollFrame", nil, copyFrame, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 16, -32); scroll:SetPoint("BOTTOMRIGHT", -32, 16)
  copyEdit = CreateFrame("EditBox", nil, scroll)
  copyEdit:SetMultiLine(true); copyEdit:SetAutoFocus(false); copyEdit:SetFontObject(ChatFontNormal)
  copyEdit:SetWidth(620); copyEdit:SetTextInsets(4, 4, 4, 4); copyEdit:SetMaxLetters(0)
  copyEdit:SetScript("OnEscapePressed", function(self) self:ClearFocus(); copyFrame:Hide() end)
  -- EditBox has no GetStringHeight on the Forever client. Keep a fixed, scrollable area.
  copyEdit:SetHeight(420)
  scroll:SetScrollChild(copyEdit)
  copyFrame:Hide()

  setTab("Console")
end

SLASH_KHQOLDEVTOOLS1 = "/khqoldev"
SLASH_KHQOLDEVTOOLS2 = "/devtools"
SlashCmdList.KHQOLDEVTOOLS = function(msg)
  msg = (msg or ""):lower()
  if msg == "capture" then DevTools:CaptureFrame(); return end
  if msg == "frames" then main:Show(); setTab("Frames"); return end
  if msg == "console" then main:Show(); setTab("Console"); return end
  if msg == "position" or msg == "pos" then main:Show(); setTab("Position"); return end
  if msg == "position report" then showCopy(formatPositionReport()); return end
  if msg == "clear" then consoleLogs = {}; refreshConsole(); return end
  if main:IsShown() then main:Hide() else main:Show() end
end

DevTools:RegisterEvent("ADDON_LOADED")
DevTools:SetScript("OnEvent", function(self, event, name)
  if event ~= "ADDON_LOADED" or name ~= addonName then return end
  KHQOL_DevToolsDB = KHQOL_DevToolsDB or {}
  db = KHQOL_DevToolsDB
  for key, default in pairs(defaults) do if db[key] == nil then db[key] = default end end
  buildUI()
  -- Some clients send print() through CHAT_MSG_SYSTEM; this is passive observation only.
  if ChatFrame_AddMessageEventFilter then
    ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", function(_, _, message) addLog(message); return false end)
  end
  -- Forever's /run print() can call the visible chat frame directly instead of firing CHAT_MSG_SYSTEM.
  -- hooksecurefunc observes the call after normal delivery and cannot replace or suppress it.
  if DEFAULT_CHAT_FRAME and hooksecurefunc then
    hooksecurefunc(DEFAULT_CHAT_FRAME, "AddMessage", function(_, message)
      if not writingDevToolsMessage then addLog(message) end
    end)
  else
    printChat("Chat frame observation is unavailable; Console collection is not supported by this client.")
  end
  printChat("Loaded. /khqoldev opens the tool; /khqoldev capture captures the current frame.")
end)
