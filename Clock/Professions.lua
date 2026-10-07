local _, KHQOL = ...
local FC = KHQOL.modules.clock

local BASIC = { [164]=true, [165]=true, [171]=true, [182]=true, [186]=true, [197]=true, [202]=true, [333]=true, [393]=true }
local SECONDARY = { [129]=true, [185]=true, [356]=true }
local FALLBACK_ICONS = {
  [164]="Interface\\Icons\\Trade_BlackSmithing", [165]="Interface\\Icons\\Trade_LeatherWorking",
  [171]="Interface\\Icons\\Trade_Alchemy", [182]="Interface\\Icons\\Trade_Herbalism",
  [185]="Interface\\Icons\\INV_Misc_Food_15", [186]="Interface\\Icons\\Trade_Mining",
  [197]="Interface\\Icons\\Trade_Tailoring", [202]="Interface\\Icons\\Trade_Engineering",
  [333]="Interface\\Icons\\Trade_Engraving", [356]="Interface\\Icons\\Trade_Fishing",
  [393]="Interface\\Icons\\Trade_Skinning", [129]="Interface\\Icons\\Spell_Holy_SealOfSacrifice",
}

local function Font(region, size) region:SetFont(FC.FONT_PATH, size, "OUTLINE") end
local function MakeCell(parent)
  local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
  FC.MakeBackdrop(b, .95, .73, .15, .90)
  -- Keep the gold border for the overall panel; individual cells use a quiet
  -- gray divider so several professions do not look like nested buttons.
  b:SetBackdropBorderColor(.28, .28, .28, .90)
  b.icon = b:CreateTexture(nil, "ARTWORK"); b.icon:SetPoint("TOP", 0, -4)
  b.skill = b:CreateFontString(nil, "OVERLAY"); b.skill:SetPoint("BOTTOM", 0, 3); Font(b.skill, 11)
  b:SetScript("OnEnter", function(self)
    if not self.data then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(self.data.name, 1, .82, .18)
    GameTooltip:AddLine("숙련도: " .. (self.data.skillText or "-"), 1, 1, 1)
    GameTooltip:AddLine("좌클릭: 전문기술 열기", .8, .8, .8); GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  b:SetScript("OnClick", function(self) if self.data then FC:OpenProfession(self.data) end end)
  return b
end

function FC:ScanProfessions()
  local found, seen = {}, {}
  if type(GetProfessions) == "function" and type(GetProfessionInfo) == "function" then
    local p1, p2, _, fishing, cooking, firstAid = GetProfessions()
    local slots = { {p1,"basic"}, {p2,"basic"}, {cooking,"secondary"}, {fishing,"secondary"}, {firstAid,"secondary"} }
    for _, slot in ipairs(slots) do
      if slot[1] then
        local name, icon, skill, maxSkill, _, _, skillLineID = GetProfessionInfo(slot[1])
        if name and skillLineID and not seen[skillLineID] and ((slot[2] == "basic" and BASIC[skillLineID]) or (slot[2] == "secondary" and SECONDARY[skillLineID])) then
          seen[skillLineID] = true
          found[#found + 1] = { name=name, icon=icon or FALLBACK_ICONS[skillLineID] or "Interface\\Icons\\INV_Misc_QuestionMark", skill=skill, maxSkill=maxSkill, skillLineID=skillLineID, category=slot[2], openMode="C_TradeSkillUI.OpenTradeSkill", openID=skillLineID }
        end
      end
    end
  end
  -- Forever can omit First Aid from GetProfessions().  Its skill line still
  -- appears in the character skill list, so use that list as a safe fallback.
  if not seen[129] and type(GetNumSkillLines) == "function" and type(GetSkillLineInfo) == "function" then
    for index = 1, GetNumSkillLines() do
      local name, isHeader, _, rank, _, _, maxRank = GetSkillLineInfo(index)
      if name and not isHeader and (name == "응급치료" or name == "응급 치료" or name == "First Aid") then
        seen[129] = true
        found[#found + 1] = { name=name, icon=FALLBACK_ICONS[129], skill=rank, maxSkill=maxRank, skillLineID=129, category="secondary", openMode="C_TradeSkillUI.OpenTradeSkill", openID=129 }
        break
      end
    end
  end
  local basic, secondary = {}, {}
  for _, data in ipairs(found) do
    data.skillText = (data.skill and data.maxSkill and data.maxSkill > 0) and (data.skill .. "/" .. data.maxSkill) or "-"
    local target = data.category == "basic" and basic or secondary
    if #target < (data.category == "basic" and 2 or 3) then target[#target + 1] = data end
  end
  self.professionData = { basic=basic, secondary=secondary }
  if self.professionsPanel and self.professionsPanel:IsShown() then self:RenderProfessions() end
end

function FC:OpenProfession(data)
  -- Opening is deliberately one-way.  The game's own ESC/X controls close
  -- the native profession window; an extension-panel click never closes it.
  -- This also keeps the protected API call inside the original mouse click.
  if C_TradeSkillUI and type(C_TradeSkillUI.OpenTradeSkill) == "function" then
    local ok = pcall(C_TradeSkillUI.OpenTradeSkill, data.skillLineID)
    if ok then return end
  end
  self:Print((data.name or "전문기술") .. ": 이 클라이언트에서는 전문기술 창 열기 API를 확인하지 못했습니다.")
end

function FC:UpdateProfessionAnchor()
  local button, panel, clock = self.professionsButton, self.professionsPanel, self.clockFrame
  if not button or not panel or not clock or not clock.timeText then return end
  local cfg = self.db.modules.professions
  cfg.position = cfg.position or { x = 160, y = 0 }
  button:ClearAllPoints(); button:SetPoint("CENTER", clock, "CENTER", cfg.position.x or 160, cfg.position.y or 0)
  local x, y = cfg.position.x or 0, cfg.position.y or 0
  local direction = math.abs(x) > math.abs(y) and (x < 0 and "left" or "right") or (y < 0 and "down" or "up")
  panel:ClearAllPoints()
  if direction == "left" then panel:SetPoint("TOPRIGHT", button, "TOPLEFT", -6, 0)
  elseif direction == "down" then panel:SetPoint("TOP", button, "BOTTOM", 0, -6)
  elseif direction == "up" then panel:SetPoint("BOTTOM", button, "TOP", 0, 6)
  else panel:SetPoint("TOPLEFT", button, "TOPRIGHT", 6, 0) end
  button.label:SetText("전문기술 " .. (direction == "left" and "◀" or (direction == "down" and "▼" or (direction == "up" and "▲" or "▶"))))
  self:SyncStyledText(button.label)
end

function FC:UpdateProfessionsVisibility()
  local enabled = self.db and self.db.enabled and self.db.modules.professions and self.db.modules.professions.enabled
  if self.professionsButton then
    self.professionsButton:SetShown(enabled)
    self.professionsButton:SetBackdropColor(.015, .015, .015, self.db.locked and 0 or .90)
    self.professionsButton:SetBackdropBorderColor(.95, .73, .15, self.db.locked and 0 or .90)
  end
  if self.professionsPanel and not enabled then self.professionsPanel:Hide() end
end

function FC:ApplyProfessionFont()
  if not self.db or not self.db.modules.professions then return end
  local size = self.db.modules.professions.fontSize or self.db.moduleFontSize
  local style = self:GetTextStyle("professions")
  if self.professionsButton and self.professionsButton.label then self:ApplyTextStyle(self.professionsButton.label, size, style) end
  if self.professionsPanel then
    for _, cell in ipairs(self.professionsPanel.cells or {}) do self:ApplyTextStyle(cell.skill, math.max(10, size - 2), style) end
  end
end

function FC:RenderProfessions()
  local panel, cfg = self.professionsPanel, self.db.modules.professions
  if not panel then return end
  local data = self.professionData or { basic={}, secondary={} }
  local items = {}; for _, d in ipairs(data.basic) do items[#items+1]=d end; for _, d in ipairs(data.secondary) do items[#items+1]=d end
  local size, gap, cell = cfg.iconSize, 8, cfg.iconSize + 22
  for i=1,#panel.cells do panel.cells[i]:Hide(); panel.cells[i].data=nil end
  if #items == 0 then
    panel.empty:SetText("배운 전문기술이 없습니다."); panel.empty:Show(); panel:SetSize(180, 48); self:UpdateProfessionAnchor(); return
  end
  panel.empty:Hide()
  local positions, width, height = {}, 0, 0
  if cfg.layout == "vertical" then
    for i=1,#items do
      local secondaryIndex = i - #data.basic
      local row = i <= #data.basic and 1 or (secondaryIndex == 3 and 3 or 2)
      local col
      if i <= #data.basic then col = #data.basic == 1 and 1.5 or i
      elseif secondaryIndex == 3 or (#data.secondary == 1) then col = 1.5
      else col = secondaryIndex end
      positions[i] = {row=row,col=col}; width=math.max(width, math.ceil(col)); height=math.max(height,row)
    end
  else
    for i=1,#items do
      local row = i <= #data.basic and 1 or 2
      local col = i <= #data.basic and i or i - #data.basic
      positions[i] = {row=row,col=col}; width=math.max(width,col); height=math.max(height,row)
    end
  end
  panel:SetSize(width * cell + (width + 1) * gap, height * cell + (height + 1) * gap)
  for i, d in ipairs(items) do
    local b = panel.cells[i]; local pos = positions[i]
    b:ClearAllPoints(); b:SetSize(cell, cell); b:SetPoint("TOPLEFT", gap + (pos.col - 1) * (cell + gap), -gap - (pos.row - 1) * (cell + gap))
    b.icon:SetSize(size, size); b.icon:SetTexture(d.icon); self:ApplyTextStyle(b.skill, math.max(10, (cfg.fontSize or self.db.moduleFontSize) - 2), self:GetTextStyle("professions")); b.skill:SetShown(cfg.showSkill); b.skill:SetText(d.skillText); self:SyncStyledText(b.skill); b.data=d; b:Show()
  end
  self:UpdateProfessionAnchor()
end

function FC:ToggleProfessions()
  local panel = self.professionsPanel
  if not panel or not self.db.modules.professions.enabled then return end
  -- The same A button is a true toggle: once the extension panel is open,
  -- do not scan or rebuild it again; close it immediately instead.
  if panel:IsShown() then
    panel:Hide()
    self:UpdateProfessionAnchor()
    return
  end
  self:ScanProfessions()
  self:RenderProfessions()
  panel:Show()
end

function FC:CreateProfessions()
  local button = CreateFrame("Button", "ForeverClockProfessionsButton", self.clockFrame, "BackdropTemplate")
  button:SetSize(84, 24); FC.MakeBackdrop(button, .95, .73, .15, .90)
  button.label = button:CreateFontString(nil, "OVERLAY"); button.label:SetPoint("CENTER"); self:ApplyTextStyle(button.label, self.db.modules.professions.fontSize or self.db.moduleFontSize, self:GetTextStyle("professions")); button.label:SetText("전문기술 ▼"); self:SyncStyledText(button.label)
  button:SetMovable(true); button:SetClampedToScreen(true); button:EnableMouse(true)
  button:SetScript("OnMouseDown", function(self, mouseButton)
    if mouseButton == "LeftButton" and not FC.db.locked then self.dragX, self.dragY = GetCursorPosition(); self:StartMoving() end
  end)
  button:SetScript("OnMouseUp", function(self, mouseButton)
    if mouseButton == "LeftButton" and not FC.db.locked then
      local x, y = GetCursorPosition(); self.didDrag = math.abs(x - (self.dragX or x)) > 5 or math.abs(y - (self.dragY or y)) > 5; self:StopMovingOrSizing()
      if self.didDrag then
        local clockX, clockY = FC.clockFrame:GetCenter(); local buttonX, buttonY = self:GetCenter()
        FC.db.modules.professions.position = { x = math.floor(buttonX - clockX + .5), y = math.floor(buttonY - clockY + .5) }
        FC:UpdateProfessionAnchor()
      end
    end
  end)
  button:SetScript("OnClick", function(self) if self.didDrag then self.didDrag = nil; return end; FC:ToggleProfessions() end)
  local panel = CreateFrame("Frame", "ForeverClockProfessionsPanel", UIParent, "BackdropTemplate")
  panel:SetFrameStrata("DIALOG"); panel:SetClampedToScreen(true); FC.MakeBackdrop(panel, .95, .73, .15, .92)
  panel.cells = {}; for i=1,5 do panel.cells[i]=MakeCell(panel) end
  panel.empty = panel:CreateFontString(nil,"OVERLAY"); Font(panel.empty, 12); panel.empty:SetPoint("CENTER")
  panel:Hide(); self.professionsButton, self.professionsPanel = button, panel
  self:ScanProfessions(); self:ApplyProfessionFont(); self:UpdateProfessionAnchor(); self:UpdateProfessionsVisibility()
end

function FC:PrintProfessionDebug()
  self:ScanProfessions(); self:Print("[Professions]")
  local data = self.professionData or { basic={}, secondary={} }
  for _, group in ipairs({data.basic, data.secondary}) do for _, d in ipairs(group) do
    self:Print(string.format("%s | %s | SkillLineID: %s | Icon: %s | Open: %s(%s)", d.name, d.skillText, d.skillLineID, tostring(d.icon), d.openMode, d.openID))
  end end
end
