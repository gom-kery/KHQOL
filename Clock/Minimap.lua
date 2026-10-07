local _, KHQOL = ...
local FC = KHQOL.modules.clock
local L = FC.L

function FC:UpdateMinimapPosition()
  local button, angle = self.minimapButton, math.rad(self.db.minimap.angle or 225)
  local radius = math.max(20, Minimap:GetWidth() / 2 + 6)
  local x, y = math.cos(angle) * radius, math.sin(angle) * radius
  button:ClearAllPoints(); button:SetPoint("CENTER", Minimap, "CENTER", -x, y)
end

function FC:CreateMinimapButton()
  local b = CreateFrame("Button", "ForeverClockMinimapButton", Minimap)
  b:SetSize(31, 31); b:SetFrameStrata("MEDIUM"); b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  local background = b:CreateTexture(nil, "BACKGROUND"); background:SetTexture("Interface\\Minimap\\MiniMap-TrackingBackground"); background:SetAllPoints(b)
  local icon = b:CreateTexture(nil, "ARTWORK"); icon:SetTexture("Interface\\Icons\\INV_Misc_PocketWatch_01"); icon:SetSize(18, 18); icon:SetPoint("CENTER"); icon:SetTexCoord(0.08, 0.92, 0.08, 0.92); b.icon = icon
  b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  b:SetScript("OnClick", function(_, button) if button == "LeftButton" then FC:ToggleSettings() else FC:ToggleHUD() end end)
  b:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT"); GameTooltip:SetText(L.TITLE); GameTooltip:AddLine(L.LEFT_CLICK, 1, 1, 1); GameTooltip:AddLine(L.RIGHT_CLICK, 1, 1, 1); GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  b:SetMovable(true); b:RegisterForDrag("LeftButton")
  b:SetScript("OnDragStart", function(self) self.dragging = true end)
  b:SetScript("OnDragStop", function(self) self.dragging = nil end)
  b:SetScript("OnUpdate", function(self)
    if not self.dragging then return end
    local mx, my = Minimap:GetCenter(); local cx, cy = GetCursorPosition(); local scale = UIParent:GetEffectiveScale()
    cx, cy = cx / scale, cy / scale
    FC.db.minimap.angle = math.deg(math.atan2(cy - my, cx - mx))
    FC:UpdateMinimapPosition()
  end)
  self.minimapButton = b; self:UpdateMinimapPosition()
end
