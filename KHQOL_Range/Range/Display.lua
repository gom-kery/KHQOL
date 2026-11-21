local ADDON, KHQOL = ...
KHQOL = assert(_G.KHQOL, "Install and enable the KHQOL core addon.")
local FR = KHQOL.modules.range

local Display = {}
FR.Display = Display

function Display:Create()
  if self.frame then return end
  local frame = CreateFrame("Frame", "FRangeIndicator", UIParent)
  frame:SetSize(260, 72)
  frame:SetFrameStrata("HIGH")
  frame:SetClampedToScreen(true)
  frame:EnableMouse(false)
  frame:RegisterForDrag("LeftButton")
  frame:SetMovable(true)
  frame:SetScript("OnDragStart", function(f)
    local numeric=FR.db.displayMode=="distance"
    local cfg=numeric and FR.db.distance or FR.db
    if not cfg.locked and not KHQOL.PositionEditor.active then f.positionMoving=true;f:StartMoving() end
  end)
  frame:SetScript("OnDragStop", function(f)
    f:StopMovingOrSizing();f.positionMoving=nil
    local _, _, _, x, y = f:GetPoint(1)
    local cfg=FR.db.displayMode=="distance" and FR.db.distance or FR.db
    if not KHQOL.IsPublicNumber(x) or not KHQOL.IsPublicNumber(y) then return end
    cfg.x,cfg.y=math.floor(x+.5),math.floor(y+.5)
    FR:RefreshDisplay(true)
    KHQOL.PositionStore:Committed()
    if FR.UpdateSettings then FR:UpdateSettings() end
  end)

  frame.shadows = {}
  for i = 1, 8 do
    local shadow = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    shadow:SetPoint("CENTER")
    frame.shadows[i] = shadow
  end
  -- Explicit layers keep the coloured glyph above every custom outline copy,
  -- regardless of the client's font batching or region creation order.
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
  if FR.db.displayMode=="distance" then self:DistanceLayout(force);return end
  self.frame.main:ClearAllPoints();self.frame.main:SetPoint("CENTER")
  local db, frame = FR.db, self.frame
  self.lastDistanceLayout=nil;self.lastDistanceText=nil;self.lastDistanceColor=nil
  frame:SetSize(260,72)
  frame.main:ClearAllPoints();frame.main:SetPoint("CENTER")
  local text = self:GetStateText(self.state)
  local font = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
  -- The coloured copies provide the complete outline, including thickness 0.
  -- A built-in black OUTLINE would ignore the selected colour and thickness.
  frame.main:SetFont(font, db.size, "")
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

function Display:DistanceLayout(force)
  local cfg,frame=FR.db.distance,self.frame
  local key=table.concat({cfg.size,cfg.x,cfg.y,tostring(cfg.locked)},"|")
  if not force and self.lastDistanceLayout==key then return end
  for _,shadow in ipairs(frame.shadows) do shadow:Hide() end
  frame:SetSize(400,FR.Distance:FrameHeight(cfg.size))
  frame.main:SetFont(KHQOL.UI:Font(),cfg.size,"OUTLINE")
  frame.main:ClearAllPoints()
  frame.main:SetPoint("CENTER");frame.main:SetJustifyH("CENTER")
  frame:EnableMouse(not cfg.locked)
  self.lastLayoutKey=nil
  if not frame.positionMoving then
    frame:ClearAllPoints();frame:SetPoint("CENTER",UIParent,"CENTER",cfg.x,cfg.y)
  end
  self.lastDistanceLayout=key
end

function Display:ShowDistance(result,force)
  FR.Distance:UpdateMeasurementLabel(result)
  local frame=self.frame
  if not frame then return end
  if not result then self:Hide();return end
  self:DistanceLayout(force)
  local text=FR.Distance:Format(result)
  if text~=self.lastDistanceText then frame.main:SetText(text);self.lastDistanceText=text end
  local color=FR.Distance:Color(result)
  local previous=self.lastDistanceColor
  if force or not previous or previous[1]~=color[1] or previous[2]~=color[2] or previous[3]~=color[3] or previous[4]~=color[4] then
    frame.main:SetTextColor(unpack(color));self.lastDistanceColor={unpack(color)}
  end
  if not frame:IsShown() then frame:Show() end
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
  self.lastDistanceLayout=nil;self.lastDistanceText=nil;self.lastDistanceColor=nil
end
