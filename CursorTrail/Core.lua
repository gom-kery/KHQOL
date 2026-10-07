local _, KHQOL = ...
local CursorTrail = KHQOL.modules.cursorTrail
local GLOW_SIZE = 1.8

local function updatePoint(point, db, progress, position)
  -- Oldest -> newest position tapers even points born in the same update.
  local remaining = 1 - progress
  local taper = .12 + .88 * math.sqrt(position or 1)
  local size = math.max(.5, db.size * GLOW_SIZE * taper * remaining)
  point:SetSize(size, size)
  local color = CursorTrail:GetColor()
  point.texture:SetVertexColor(color.r, color.g, color.b, 1)
  point.texture:SetAlpha(db.alpha * remaining ^ 2 * (.25 + .75 * (position or 1)))
end

local defaults = {
  enabled = true,
  length = 12,
  size = 10,
  spacing = 4.5,
  duration = .35,
  alpha = .70,
}

local function clamp(value, minimum, maximum)
  return math.max(minimum, math.min(maximum, value))
end

function CursorTrail:GetDB()
  local db = KHQOL.db.modules.cursorTrail
  if type(db) ~= "table" then db = {}; KHQOL.db.modules.cursorTrail = db end
  -- Preserve the previous size-derived interval when upgrading saved settings.
  if db.spacing == nil then db.spacing = math.max(3, (tonumber(db.size) or defaults.size) * .45) end
  KHQOL.MergeDefaults(db, defaults, "tables")
  db.length = clamp(math.floor(tonumber(db.length) or defaults.length), 1, 40)
  db.size = clamp(tonumber(db.size) or defaults.size, 4, 32)
  db.spacing = clamp(tonumber(db.spacing) or defaults.spacing, 1, 20)
  db.duration = clamp(tonumber(db.duration) or defaults.duration, .10, 2)
  db.alpha = clamp(tonumber(db.alpha) or defaults.alpha, .10, 1)
  return db
end

local function validColor(color)
  return type(color) == "table" and type(color.r) == "number" and type(color.g) == "number" and type(color.b) == "number"
end

function CursorTrail:GetColorDB()
  if type(KHQOLCursorTrailCharDB) ~= "table" then KHQOLCursorTrailCharDB = {} end
  local char = KHQOLCursorTrailCharDB
  if char.color ~= nil and not validColor(char.color) then char.color = nil end
  local db = self:GetDB()
  if not db.colorMigrationComplete then
    -- Old releases only saved an account-wide RGB value, not edit history.
    -- Import a non-default legacy color once, into the first upgraded character.
    local old = db.color
    if not char.color and validColor(old) and
       (math.abs(old.r - .80) > .00001 or math.abs(old.g - .92) > .00001 or math.abs(old.b - 1) > .00001) then
      char.color = {r=old.r, g=old.g, b=old.b}
    end
    db.colorMigrationComplete = true
  end
  return char
end

function CursorTrail:GetColor()
  if self.color then return self.color end
  local saved = self:GetColorDB().color
  if saved then self.color = saved
  else
    local _, class = UnitClass("player")
    local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    self.color = color and {r=color.r, g=color.g, b=color.b} or {r=1, g=1, b=1}
  end
  return self.color
end

function CursorTrail:SetColor(r, g, b)
  local char = self:GetColorDB()
  char.color = r and {r=clamp(r,0,1), g=clamp(g,0,1), b=clamp(b,0,1)} or nil
  self.color = nil
  self:ApplyAppearance()
end

function CursorTrail:CaptureColorRestore()
  local saved = self:GetColorDB().color
  local r, g, b
  if saved then r, g, b = saved.r, saved.g, saved.b end
  return function() self:SetColor(r, g, b) end
end

function CursorTrail:CreatePoint()
  local frame = CreateFrame("Frame", nil, UIParent)
  frame:SetSize(1, 1)
  frame:SetFrameStrata("TOOLTIP")
  frame:EnableMouse(false)
  local texture = frame:CreateTexture(nil, "OVERLAY")
  texture:SetAllPoints(frame)
  texture:SetTexture("Interface\\AddOns\\KHQOL\\CursorTrail\\Media\\SoftGlow.tga")
  texture:SetBlendMode("ADD")
  frame.texture = texture
  frame:Hide()
  return frame
end

function CursorTrail:EnsurePool(db)
  db = db or self:GetDB()
  self.pool = self.pool or {}
  self.active = self.active or {}
  while #self.pool + #self.active < db.length do table.insert(self.pool, self:CreatePoint()) end
  while #self.pool + #self.active > db.length and #self.pool > 0 do
    local point = table.remove(self.pool); point:Hide()
  end
  while #self.pool + #self.active > db.length and #self.active > 0 do
    local point = table.remove(self.active, 1)
    point:Hide()
  end
end

function CursorTrail:ApplyAppearance()
  local db = self:GetDB()
  if not self.pool then return end
  for _, point in ipairs(self.pool) do
    updatePoint(point, db, 0)
  end
  self:UpdateActive(db, GetTime())
end

function CursorTrail:UpdateActive(db, now)
  local count = #self.active
  for index, point in ipairs(self.active) do
    local position = count > 1 and (index - 1) / (count - 1) or 1
    updatePoint(point, db, clamp((now - point.born) / db.duration, 0, 1), position)
  end
end

function CursorTrail:ReleaseAt(index)
  local point = table.remove(self.active, index)
  if point then point:Hide(); table.insert(self.pool, point) end
end

function CursorTrail:Clear()
  while self.active and #self.active > 0 do self:ReleaseAt(#self.active) end
end

function CursorTrail:Acquire(db)
  self:EnsurePool(db)
  if #self.pool == 0 then self:ReleaseAt(1) end
  return table.remove(self.pool)
end

function CursorTrail:AddPoint(x, y, now, db)
  -- TrackCursor shares this update's validated settings across every sample.
  db = db or self:GetDB()
  local point = self:Acquire(db)
  if not point then return end
  point:ClearAllPoints()
  point:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
  updatePoint(point, db, 0)
  point.born = now
  point:Show()
  table.insert(self.active, point)
end

function CursorTrail:OnUpdate()
  local db = self:GetDB()
  local now = GetTime()
  for index = #self.active, 1, -1 do
    local point = self.active[index]
    local progress = (now - point.born) / db.duration
    if progress >= 1 then self:ReleaseAt(index)
    end
  end
  self:TrackCursor(db, now)
  self:UpdateActive(db, now)
end

function CursorTrail:TrackCursor(db, now)
  local px, py = GetCursorPosition()
  local scale = UIParent:GetEffectiveScale()
  if not scale or scale == 0 then return end
  local x, y = px / scale, py / scale
  if not self.lastX then self.lastX, self.lastY = x, y; return end
  local threshold = db.spacing
  local dx, dy = x - self.lastX, y - self.lastY
  local distance = math.sqrt(dx * dx + dy * dy)
  if distance < threshold then return end
  local steps = math.floor(distance / threshold)
  local ux, uy = dx / distance, dy / distance
  local startX, startY = self.lastX, self.lastY
  -- Keep only the newest samples on large jumps. Do not defer old samples
  -- into later updates after the real cursor has already stopped moving.
  local first = math.max(1, steps - db.length + 1)
  for step = first, steps do
    self:AddPoint(startX + ux * threshold * step, startY + uy * threshold * step, now, db)
  end
  self.lastX, self.lastY = startX + ux * threshold * steps, startY + uy * threshold * steps
end

function CursorTrail:SetSpacing(value)
  self:GetDB().spacing = clamp(value, 1, 20)
  self.lastX, self.lastY = nil, nil
end

function CursorTrail:SetEnabled(enabled)
  if not self.tracker then return end
  self.lastX, self.lastY = nil, nil
  if enabled then self:EnsurePool(); self.tracker:SetScript("OnUpdate", function() self:OnUpdate() end)
  else self.tracker:SetScript("OnUpdate", nil); self:Clear() end
end

function CursorTrail:Initialize()
  if not self.tracker then self.tracker = CreateFrame("Frame", nil, UIParent); self.tracker:EnableMouse(false) end
  self:EnsurePool()
  self:ApplyAppearance()
  self:SetEnabled(KHQOL:GetEnabled("cursorTrail"))
end

function CursorTrail:ResetSettings()
  KHQOLCursorTrailCharDB = {}; self.color = nil
  self:GetDB(); self:EnsurePool(); self:ApplyAppearance(); self.lastX, self.lastY = nil, nil
end
