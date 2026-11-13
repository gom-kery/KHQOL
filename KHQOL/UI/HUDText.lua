local _,K=...
local HUD={FONT_PATH=K.FONT_PATH,moneyUnits={gold=true,silver=true,copper=true}}
K.HUDText=HUD

local ICON = "|TInterface\\MoneyFrame\\UI-GoldIcon:14:14:2:0|t"
local SILVER = "|TInterface\\MoneyFrame\\UI-SilverIcon:14:14:2:0|t"
local COPPER = "|TInterface\\MoneyFrame\\UI-CopperIcon:14:14:2:0|t"

function HUD.MakeBackdrop(frame, r, g, b, a)
  frame:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
  frame:SetBackdropColor(0.015, 0.015, 0.015, a or 0.84)
  frame:SetBackdropBorderColor(r or 1, g or 0.78, b or 0.18, 0.9)
end

function HUD:SyncStyledText(fontString)
  if not fontString then return end
  local overlay = fontString.khqolHUDBoldOverlay
  local point, relativeTo, relativePoint, x, y = fontString:GetPoint(1)
  if overlay then
    overlay:SetText(fontString:GetText() or "")
    overlay:SetShown(fontString:IsShown() and overlay.styleEnabled)
  end
  if point and overlay then
    overlay:ClearAllPoints()
    -- One full UI pixel is intentional: the prior sub-pixel offset could be
    -- rounded away by Forever's renderer and made Bold visually identical.
    overlay:SetPoint(point, relativeTo, relativePoint, (x or 0) + 1, y or 0)
  end
  for _, outline in ipairs(fontString.khqolHUDThickOutlines or {}) do
    outline:SetText(fontString:GetText() or "")
    outline:SetShown(fontString:IsShown() and outline.styleEnabled)
    if point then
      outline:ClearAllPoints()
      outline:SetPoint(point, relativeTo, relativePoint, (x or 0) + outline.offsetX, (y or 0) + outline.offsetY)
    end
  end
end

function HUD:ApplyTextStyle(fontString, size, style)
  if not fontString or not style then return end
  local effect = style.effect or "OUTLINE"
  local flags = effect == "OUTLINE" and "OUTLINE" or (effect == "THICKOUTLINE" and "THICKOUTLINE" or "")
  local color = style.color or { 1, 1, 1, 1 }
  fontString:SetFont(self.FONT_PATH, size, flags)
  fontString:SetTextColor(color[1] == nil and 1 or color[1], color[2] == nil and 1 or color[2], color[3] == nil and 1 or color[3], color[4] == nil and 1 or color[4])
  if effect == "SHADOW" then
    fontString:SetShadowColor(0, 0, 0, 0.9)
    fontString:SetShadowOffset(1, -1)
  else
    fontString:SetShadowColor(0, 0, 0, 0)
    fontString:SetShadowOffset(0, 0)
  end

  -- IsamanruLight has no bundled bold face.  A second, slightly offset copy
  -- gives a stable synthetic bold without replacing Korean glyph coverage.
  local overlay = fontString.khqolHUDBoldOverlay
  if style.bold and not overlay then
    overlay = fontString:GetParent():CreateFontString(nil, "OVERLAY")
    fontString.khqolHUDBoldOverlay = overlay
  end
  if overlay then
    overlay:SetFont(self.FONT_PATH, size, flags)
    overlay:SetTextColor(color[1] == nil and 1 or color[1], color[2] == nil and 1 or color[2], color[3] == nil and 1 or color[3], color[4] == nil and 1 or color[4])
    if effect == "SHADOW" then overlay:SetShadowColor(0, 0, 0, 0.9); overlay:SetShadowOffset(1, -1) else overlay:SetShadowColor(0, 0, 0, 0); overlay:SetShadowOffset(0, 0) end
    overlay.styleEnabled = style.bold and true or false
    overlay:SetShown(overlay.styleEnabled)
  end
  local thickOutlines = fontString.khqolHUDThickOutlines
  if effect == "THICKOUTLINE" and not thickOutlines then
    thickOutlines = {}
    for _, offset in ipairs({ { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 } }) do
      -- The helper copies must sit below the source text.  OVERLAY would draw
      -- their black glyph interiors on top of the coloured text.
      local outline = fontString:GetParent():CreateFontString(nil, "ARTWORK")
      outline.offsetX, outline.offsetY = offset[1], offset[2]
      thickOutlines[#thickOutlines + 1] = outline
    end
    fontString.khqolHUDThickOutlines = thickOutlines
  end
  for _, outline in ipairs(thickOutlines or {}) do
    -- Some Forever builds render THICKOUTLINE almost like OUTLINE.  Four
    -- one-pixel black copies make the selected effect reliably thicker.
    outline:SetFont(self.FONT_PATH, size, "OUTLINE")
    outline:SetTextColor(0, 0, 0, 0.9)
    outline:SetShadowColor(0, 0, 0, 0)
    outline:SetShadowOffset(0, 0)
    outline.styleEnabled = effect == "THICKOUTLINE"
    outline:SetShown(outline.styleEnabled)
  end
  self:SyncStyledText(fontString)
end

function HUD.FormatMoney(amount,units)
  local gold, silver, copper = math.floor(amount / 10000), math.floor((amount % 10000) / 100), amount % 100
  units = units or HUD.moneyUnits
  local pieces = {}
  if units.gold then pieces[#pieces + 1] = gold .. " " .. ICON end
  if units.silver then pieces[#pieces + 1] = silver .. " " .. SILVER end
  if units.copper then pieces[#pieces + 1] = copper .. " " .. COPPER end
  return table.concat(pieces,"  ")
end
