local ADDON, KHQOL = ...
local FR = KHQOL.modules.range

local Display = {}
FR.Display = Display

function Display:Create()
  local frame = CreateFrame("Frame", "FRangeIndicator", UIParent)
  frame:SetSize(260, 72)
  frame:SetFrameStrata("HIGH")
  frame:SetClampedToScreen(true)
  frame:EnableMouse(false)
  frame:RegisterForDrag("LeftButton")
  frame:SetMovable(true)
  frame:SetScript("OnDragStart", function(f) if not FR.db.locked then f:StartMoving() end end)
  frame:SetScript("OnDragStop", function(f)
    f:StopMovingOrSizing()
    local _, _, _, x, y = f:GetPoint(1)
    FR.db.x, FR.db.y = math.floor(x + 0.5), math.floor(y + 0.5)
    FR:RefreshDisplay(true)
    if FR.UpdateSettings then FR:UpdateSettings() end
  end)

  frame.shadows = {}
  for i = 1, 8 do
    local shadow = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    shadow:SetPoint("CENTER")
    frame.shadows[i] = shadow
  end
  -- Regions on the same draw layer render in creation order. Create the coloured
  -- main glyph after the black outline copies so it always remains on top.
  frame.main = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  frame.main:SetPoint("CENTER")
  frame.main:SetJustifyH("CENTER")
  frame:Hide()
  self.frame = frame
  self:ApplyLayout(true)
end

function Display:GetStateText(state)
  local db=FR.db
  if db.stateText~=true then return db.shape or "\226\150\160" end
  local key=state=="GREEN" and "available" or (state=="RED" and "unavailable" or "unknown")
  return db.stateTexts[key]
end

function Display:ApplyLayout(force)
  if not self.frame or not FR.db then return end
  local db, frame = FR.db, self.frame
  local text = self:GetStateText(self.state)
  local font = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
  local flags = db.outline.enabled and "OUTLINE" or ""
  frame.main:SetFont(font, db.size, flags)
  frame.main:SetText(text)
  frame:ClearAllPoints()
  frame:SetPoint("CENTER", UIParent, "CENTER", db.x, db.y)
  frame:EnableMouse(not db.locked)

  local thick = math.max(0, math.min(4, tonumber(db.outline.thickness) or 1))
  local offsets = { { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 }, { -1, -1 }, { -1, 1 }, { 1, -1 }, { 1, 1 } }
  for i, shadow in ipairs(frame.shadows) do
    shadow:ClearAllPoints()
    if db.outline.enabled and thick > 0 then
      local offset = offsets[i]
      shadow:SetPoint("CENTER", frame, "CENTER", offset[1] * thick, offset[2] * thick)
      shadow:SetFont(font, db.size, "")
      shadow:SetText(text)
      shadow:Show()
    else
      shadow:Hide()
    end
  end
  self.lastLayoutKey = nil
end

function Display:ShowState(state, force)
  if not self.frame then return end
  local db, frame = FR.db, self.frame
  local color = db.colors[state]
  if not color then frame:Hide(); return end
  -- table.concat accepts strings/numbers, not Booleans. Convert persisted
  -- checkbox settings so Test Display and normal updates share one safe cache key.
  local text=self:GetStateText(state)
  local key = table.concat({ state, text, db.size, db.x, db.y, tostring(db.locked), tostring(db.outline.enabled), db.outline.thickness, table.concat(color, ","), table.concat(db.outline.color, ",") }, "|")
  if force or key ~= self.lastLayoutKey then
    self.state=state
    self:ApplyLayout()
    frame.main:SetTextColor(color[1], color[2], color[3], color[4])
    for _, shadow in ipairs(frame.shadows) do shadow:SetTextColor(unpack(db.outline.color)) end
    self.lastLayoutKey = key
  end
  frame:Show()
end

function Display:Hide()
  if self.frame then self.frame:Hide() end
  self.lastLayoutKey = nil
end
