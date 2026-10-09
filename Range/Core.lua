local ADDON, KHQOL = ...
local FR = KHQOL.modules.range

FR.name = ADDON
FR.testState, FR.testUntil = nil, 0

function FR:Print(message)
  DEFAULT_CHAT_FRAME:AddMessage("|cff4dff66[FRange]|r " .. tostring(message))
end

function FR:ParseSpell(input)
  input = tostring(input or ""):gsub("^%s+", ""):gsub("%s+$", "")
  local spellID = tonumber(input) or tonumber(input:match("spell:(%d+)"))
  if not spellID and input ~= "" and type(GetSpellInfo) == "function" then
    -- Exact name lookup is only a fallback after ID / Shift-click spell link.
    local knownID = select(7, GetSpellInfo(input))
    spellID = tonumber(knownID)
  end
  if not spellID then return nil end
  local name, resolvedID = self.Range:GetSpellInfo(spellID)
  return resolvedID or spellID, name
end

function FR:SetRangeSpell(input)
  local id, name = self:ParseSpell(input)
  if not id or not name then self:Print("Spell not found. Use a Spell ID or Shift-click a spell link."); return end
  if not self.Range:IsKnownSpell(id) then self:Print("That spell is not known by this character."); return end
  self.db.rangeSpellID, self.db.rangeSpellName = id, name
  self:Print("Registered range skill: " .. name .. " (" .. id .. ").")
  self:RefreshDisplay(true); self:UpdateSettings()
end

function FR:SetMeleeSpell(input)
  if tostring(input or ""):match("^%s*$") then
    self.db.hunterMeleeSpellID, self.db.hunterMeleeSpellName = nil, nil
    self:RefreshDisplay(true); self:UpdateSettings(); return
  end
  local id, name = self:ParseSpell(input)
  if not id or not name or not self.Range:IsKnownSpell(id) then self:Print("Melee reference spell was not accepted."); return end
  self.db.hunterMeleeSpellID, self.db.hunterMeleeSpellName = id, name; self:Print("Hunter melee reference: " .. name .. ".")
  self:RefreshDisplay(true); self:UpdateSettings()
end

function FR:CaptureCursorSpell()
  if type(GetCursorInfo) ~= "function" then self:Print("This client cannot read the cursor spell."); return end
  local kind, id = GetCursorInfo()
  if kind == "spell" and id then self:SetRangeSpell(tostring(id)); ClearCursor() else self:Print("Pick up a spell from the spellbook, then press Cursor spell.") end
end

function FR:SetNumber(key, value, minValue, maxValue)
  value = tonumber(value)
  if not value then return end
  self.db[key] = math.max(minValue, math.min(maxValue, math.floor(value + 0.5)))
  self:RefreshDisplay(true); self:UpdateSettings()
end

local function parseRGB(text)
  local r, g, b = tostring(text):match("^%s*([%d%.]+)%s*,%s*([%d%.]+)%s*,%s*([%d%.]+)%s*$")
  r, g, b = tonumber(r), tonumber(g), tonumber(b)
  if not r or not g or not b then return nil end
  return math.max(0, math.min(1, r)), math.max(0, math.min(1, g)), math.max(0, math.min(1, b))
end

function FR:SetColorText(state, text)
  local r, g, b = parseRGB(text)
  if not r then self:Print("Use color format: 0.00, 0.00, 0.00"); return end
  self:SetColor(state, r, g, b, 1); self:UpdateSettings()
end

function FR:SetOutlineColor(text)
  local r, g, b = parseRGB(text)
  if not r then self:Print("Use color format: 0.00, 0.00, 0.00"); return end
  local c = self.db.outline.color; c[1], c[2], c[3], c[4] = r, g, b, 1
  self:RefreshDisplay(true); self:UpdateSettings()
end

function FR:SetOutlineThickness(value)
  self.db.outline.thickness = math.max(0, math.min(4, math.floor((tonumber(value) or 1) + 0.5)))
  self:RefreshDisplay(true); self:UpdateSettings()
end

function FR:ToggleLock(force)
  self.db.locked = force == nil and not self.db.locked or force
  self:RefreshDisplay(true); self:UpdateSettings()
  self:Print(self.db.locked and "Indicator locked." or "Indicator unlocked. Drag it to move.")
end

function FR:CycleTest()
  local states = { "GREEN", "RED", "ORANGE" }
  local index = 0
  for i, state in ipairs(states) do if state == self.testState then index = i end end
  self.testState = states[index % #states + 1]
  self.testUntil = GetTime() + 3
  self:RefreshDisplay(true)
end

function FR:RefreshDisplay(force)
  if self.Mouseover then self.Mouseover:Update() end
  if _G.KHQOL and _G.KHQOL.db and not _G.KHQOL:GetEnabled("range") then if self.Display.frame then self.Display:Hide() end; return end
  if not self.Display.frame then return end
  if self.testState and GetTime() < self.testUntil then self.Display:ShowState(self.testState, force); return end
  self.testState = nil
  local state = self.Range:GetTargetState()
  if state then self.Display:ShowState(state, force) else self.Display:Hide() end
end

function FR:OnEvent(event, ...)
  if event == "PLAYER_LOGIN" then
    self:InitializeDB(); self.Display:Create(); self.Mouseover:Initialize()
    if select(2,UnitClass("player"))=="HUNTER" then self.Range:PrepareHunterRangeItems() end
    self:RefreshDisplay(true)
  else
    if event == "SPELLS_CHANGED" or event == "ACTIONBAR_SLOT_CHANGED" or event == "ACTIONBAR_PAGE_CHANGED" or event == "UPDATE_BONUS_ACTIONBAR" then
      self.Range:ClearActionSlotCache()
    end
    self:RefreshDisplay()
  end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
eventFrame:RegisterEvent("UNIT_TARGET")
eventFrame:RegisterEvent("SPELLS_CHANGED")
eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
eventFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
eventFrame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
eventFrame:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
eventFrame:SetScript("OnEvent", function(_, event, ...) FR:OnEvent(event, ...) end)

local elapsed = 0
local function updateRange(_, delta)
  elapsed = elapsed + delta
  if elapsed < 0.08 then return end
  elapsed = 0
  if FR.db then FR:RefreshDisplay() end
end
eventFrame:SetScript("OnUpdate", updateRange)

function FR:SetEnabled(enabled)
  if not enabled and self.Mouseover then self.Mouseover:Hide() end
  -- Retain cache-invalidation events while disabled, so re-enabling uses the
  -- current action bar. Only the idle polling callback is detached.
  eventFrame:SetScript("OnUpdate", enabled and updateRange or nil)
  if self.Display and self.Display.frame then
    self.Display.frame:SetShown(enabled)
    if enabled and self.RefreshDisplay then self:RefreshDisplay(true) end
  end
end

SLASH_FRANGE1 = "/frange"
SlashCmdList.FRANGE = function(message)
  local command = (message or ""):lower():match("^%s*(%S*)")
  if command == "" then if _G.KHQOL and _G.KHQOL.OpenModule then _G.KHQOL:OpenModule("range") else FR:OpenSettings() end
  elseif command == "test" then FR:CycleTest()
  elseif command == "lock" then FR:ToggleLock(true)
  elseif command == "unlock" then FR:ToggleLock(false)
  elseif command == "reset" then FR:ResetDB(); FR:Print("Character settings reset.")
  elseif command == "api" then FR.Range:DescribeAPI()
  else FR:Print("/frange, /frange test, /frange lock, /frange unlock, /frange reset, /frange api") end
end
