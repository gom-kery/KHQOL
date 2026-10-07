local _, KHQOL = ...
local FC = KHQOL.modules.clock
local L = FC.L

local function Button(parent, text, width, onClick)
  local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  button:SetSize(width, 26); button:SetText(text); button:RegisterForClicks("LeftButtonUp")
  button:GetFontString():SetFont(FC.FONT_PATH, 14, "OUTLINE")
  button:SetWidth(math.max(width or 22, button:GetTextWidth() + 20))
  button:SetScript("OnClick", onClick)
  return button
end

local function FitButton(button, minimum)
  button:SetWidth(math.max(minimum or 30, button:GetTextWidth() + 20))
end

local function SetEditBoxBorderAlpha(editBox, alpha)
  for _, region in ipairs({ editBox:GetRegions() }) do
    if region:GetObjectType() == "Texture" then region:SetAlpha(alpha) end
  end
end

local function HideMainEditorBorder(editBox)
  for _, region in ipairs({ editBox:GetRegions() }) do
    -- The beta client resolves template texture paths to numeric file IDs, so
    -- matching source paths is unreliable.  This EditBox uses the custom
    -- cursor below; safely hide all template texture regions to remove its box.
    if region:GetObjectType() == "Texture" and region ~= editBox.fcCursor then region:Hide() end
  end
end

local function UpdateScrollBar(scroll, contentHeight)
  local bar = scroll.ScrollBar or scroll.scrollBar
  if not bar then return end
  bar:SetShown(contentHeight > scroll:GetHeight() + 1)
end

StaticPopupDialogs["FOREVERCLOCK_GROUP_TO_TEXT"] = {
  text = "그룹 체크리스트를 텍스트로 바꾸면 그룹 구조가 해제됩니다. 계속할까요?",
  button1 = "변환",
  button2 = "취소",
  OnAccept = function() FC:ToggleTodoMode(true) end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
}

function FC:GetTodoPage()
  local todo = self.db.todo
  if #todo.pages == 0 then todo.pages[1] = { title = "", text = "" } end
  todo.currentPage = math.max(1, math.min(todo.currentPage or 1, #todo.pages))
  return todo.pages[todo.currentPage]
end

function FC:SaveTodoPage()
  if not self.todoFrame or self.todoFrame.loading then return end
  local page = self:GetTodoPage()
  page.title = self.todoFrame.title:GetText()
  if (page.mode or "text") == "text" then page.text = self.todoFrame.editor:GetText() end
end

function FC:ApplyTodoAppearance()
  local f = self.todoFrame
  if not f then return end
  local alpha = self.db.todo.backgroundAlpha
  if alpha == nil then alpha = self.db.todo.transparent and 0.18 or 0.95; self.db.todo.backgroundAlpha = alpha end
  local edges = alpha > 0.05 and math.min(0.95, alpha + 0.1) or 0
  f:SetBackdropColor(0.015, 0.015, 0.015, alpha)
  f:SetBackdropBorderColor(1, 0.78, 0.18, edges)
  f.editorBorder:SetBackdropColor(0.01, 0.01, 0.01, alpha * 0.86)
  f.editorBorder:SetBackdropBorderColor(0.72, 0.56, 0.2, edges * 0.86)
  f.headerLine:SetAlpha(edges * 0.55)
  f.contentLine:SetAlpha(edges * 0.25)
  SetEditBoxBorderAlpha(f.title, edges)
  HideMainEditorBorder(f.editor)
  for _, row in ipairs(f.checkRows or {}) do SetEditBoxBorderAlpha(row.edit, edges) end
  for _, header in ipairs(f.groupHeaders or {}) do SetEditBoxBorderAlpha(header.title, edges) end
  local percent = math.floor(alpha * 100 + 0.5)
  if f.opacitySlider and math.floor(f.opacitySlider:GetValue() + 0.5) ~= percent then
    f.updatingOpacity = true; f.opacitySlider:SetValue(percent); f.updatingOpacity = nil
  end
  if f.opacityValue then f.opacityValue:SetText(percent .. "%") end
end

function FC:UpdateTodoPlaceholder()
  local f = self.todoFrame
  if not f or not f.placeholder then return end
  f.placeholder:SetShown((f.editor:GetText() or "") == "" and f.textScroll:IsShown() and not f.editor:HasFocus())
  if f.titlePlaceholder then f.titlePlaceholder:SetShown((f.title:GetText() or "") == "" and not f.title:HasFocus()) end
end

function FC:UpdateTodoEditorSize()
  local f = self.todoFrame
  if not f then return end
  f.editor:SetWidth(math.max(100, f.textScroll:GetWidth() - 6))
  f.checkChild:SetWidth(math.max(100, f.checkScroll:GetWidth()))
  local _, lines = (f.editor:GetText() or ""):gsub("\n", "")
  local textHeight = math.max(1, lines + 1) * ((self.db.todo.fontSize or 14) + 8) + 16
  f.editor:SetHeight(math.max(f.textScroll:GetHeight(), textHeight))
  f.textScroll:UpdateScrollChildRect()
  f.checkScroll:UpdateScrollChildRect()
  UpdateScrollBar(f.textScroll, textHeight)
  UpdateScrollBar(f.checkScroll, f.checkChild:GetHeight())
end

function FC:UpdateTodoMinimumSize()
  local f = self.todoFrame
  if not f or not f.SetResizeBounds then return end
  -- Header, editor toolbar, footer, and four readable content rows.
  local minimumHeight = 158 + ((self.db.todo.fontSize or 15) + 8) * 4 + 16
  local minimumWidth = 440
  f:SetResizeBounds(minimumWidth, minimumHeight)
  if f:GetWidth() < minimumWidth or f:GetHeight() < minimumHeight then
    f:SetSize(math.max(minimumWidth, f:GetWidth()), math.max(minimumHeight, f:GetHeight()))
  end
end

function FC:ApplyTodoFontSize()
  local f, size = self.todoFrame, self.db.todo.fontSize or 14
  if not f then return end
  f.title:SetFont(FC.FONT_PATH, size + 1, "OUTLINE")
  f.editor:SetFont(FC.FONT_PATH, size, "")
  for _, row in ipairs(f.checkRows or {}) do row.edit:SetFont(FC.FONT_PATH, size, "") end
  for _, header in ipairs(f.groupHeaders or {}) do header.title:SetFont(FC.FONT_PATH, size + 1, "OUTLINE") end
  f.fontValue:SetText(size .. " px")
  f.fontValue:SetFont(FC.FONT_PATH, 15, "OUTLINE")
  f.fontValue:SetTextColor(1, 0.84, 0.18, 1)
  self:UpdateTodoMinimumSize()
end

function FC:ChangeTodoFontSize(delta)
  self.db.todo.fontSize = math.max(15, math.min(30, (self.db.todo.fontSize or 15) + delta))
  if self.todoFrame and self.todoFrame.fontSlider then self.todoFrame.fontSlider:SetValue(self.db.todo.fontSize) else self:ApplyTodoFontSize(); self:UpdateTodoEditorSize() end
end

function FC:EnsureTodoGroups(page)
  if not page.individualTasks then page.individualTasks = page.tasks or {}; page.tasks = nil end
  page.groups = page.groups or {}
  page.activeGroup = math.max(1, math.min(page.activeGroup or 1, math.max(1, #page.groups)))
end

function FC:RefreshTodoChecklist()
  local f, page = self.todoFrame, self:GetTodoPage()
  self:EnsureTodoGroups(page)
  local y, headerIndex, taskIndex = 0, 1, 1
  local rowHeight = math.max(30, (self.db.todo.fontSize or 14) + 10)
  local headerHeight = math.max(30, (self.db.todo.fontSize or 14) + 9)
  local displayGroups = {}
  if #page.individualTasks > 0 then displayGroups[#displayGroups + 1] = { tasks = page.individualTasks, individual = true, index = 0 } end
  for index, group in ipairs(page.groups) do displayGroups[#displayGroups + 1] = { tasks = group.tasks, group = group, index = index } end
  for _, entry in ipairs(displayGroups) do
    local group, groupIndex = entry.group or entry, entry.index
    local header
    if not entry.individual then header = f.groupHeaders[headerIndex] end
    if not entry.individual and not header then
      header = CreateFrame("Frame", nil, f.checkChild); header:SetHeight(headerHeight)
      header.toggle = Button(header, "▼", 22, function() local page = FC:GetTodoPage(); page.activeGroup = header.groupIndex; local group = page.groups[header.groupIndex]; group.collapsed = not group.collapsed; FC:RefreshTodo() end); header.toggle:SetPoint("LEFT", header, "LEFT", 0, 0)
      header.title = CreateFrame("EditBox", nil, header, "InputBoxTemplate"); header.title:SetPoint("LEFT", header.toggle, "RIGHT", 2, 0); header.title:SetHeight(headerHeight - 4); header.title:SetAutoFocus(false); header.title:SetFont(FC.FONT_PATH, FC.db.todo.fontSize + 1, "OUTLINE")
      header.add = Button(header, "+", 22, function() local group = FC:GetTodoPage().groups[header.groupIndex]; group.tasks[#group.tasks + 1] = { text = "", done = false }; group.collapsed = false; FC:RefreshTodo() end); header.add:SetPoint("RIGHT", header, "RIGHT", -28, 0)
      header.delete = Button(header, "×", 24, function() local page = FC:GetTodoPage(); if #page.groups > 1 then table.remove(page.groups, header.groupIndex); page.activeGroup = math.min(page.activeGroup or 1, #page.groups); FC:RefreshTodo() end end); header.delete:SetPoint("RIGHT", header, "RIGHT", 0, 0); header.delete:GetFontString():SetFont(FC.FONT_PATH, 16, "OUTLINE")
      header.title:SetPoint("RIGHT", header.add, "LEFT", -3, 0)
      header.title:SetScript("OnTextChanged", function(self, userInput) if userInput then local group = FC:GetTodoPage().groups[self.groupIndex]; if group then group.title = self:GetText() end end end)
      header.title:SetScript("OnEditFocusGained", function(self) FC:GetTodoPage().activeGroup = self.groupIndex end)
      f.groupHeaders[headerIndex] = header
    end
    if not entry.individual then
      header.groupIndex = groupIndex; header.title.groupIndex = groupIndex; header.title:SetText(group.title or L.GROUP_DEFAULT); header.toggle:SetText(group.collapsed and "▶" or "▼"); header.delete:SetShown(#page.groups > 1)
      header:SetHeight(headerHeight); header.title:SetHeight(headerHeight - 4); header:ClearAllPoints(); header:SetPoint("TOPLEFT", f.checkChild, "TOPLEFT", 2, -y); header:SetPoint("TOPRIGHT", f.checkChild, "TOPRIGHT", -2, -y); header:Show(); y = y + headerHeight + 3; headerIndex = headerIndex + 1
    end
    if not group.collapsed then
      for index, task in ipairs(entry.tasks) do
        local row = f.checkRows[taskIndex]
        if not row then
          row = CreateFrame("Frame", nil, f.checkChild); row:SetHeight(rowHeight)
          row.check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate"); row.check:SetPoint("LEFT", row, "LEFT", 12, 0)
          row.delete = Button(row, "×", 26, function() local page = FC:GetTodoPage(); local tasks = row.individual and page.individualTasks or page.groups[row.groupIndex].tasks; table.remove(tasks, row.taskIndex); FC:RefreshTodo() end); row.delete:SetPoint("RIGHT", row, "RIGHT", -1, 0); row.delete:GetFontString():SetFont(FC.FONT_PATH, 18, "OUTLINE")
          row.edit = CreateFrame("EditBox", nil, row, "InputBoxTemplate"); row.edit:SetPoint("LEFT", row.check, "RIGHT", 1, 0); row.edit:SetPoint("RIGHT", row.delete, "LEFT", -3, 0); row.edit:SetHeight(rowHeight - 4); row.edit:SetAutoFocus(false)
          row.edit:SetScript("OnTextChanged", function(self, userInput) if userInput then local page = FC:GetTodoPage(); local tasks = self.individual and page.individualTasks or page.groups[self.groupIndex].tasks; local task = tasks and tasks[self.taskIndex]; if task then task.text = self:GetText() end end end)
          row.edit:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
          row.strike = row:CreateTexture(nil, "OVERLAY"); row.strike:SetHeight(1); row.strike:SetPoint("LEFT", row.edit, "LEFT", 1, 0); row.strike:SetPoint("RIGHT", row.edit, "RIGHT", -1, 0); row.strike:SetColorTexture(0.75, 0.75, 0.75, 0.85)
          row.check:SetScript("OnClick", function(self) local page = FC:GetTodoPage(); local tasks = self.individual and page.individualTasks or page.groups[self.groupIndex].tasks; local task = table.remove(tasks, self.taskIndex); task.done = self:GetChecked() and true or false; if task.done then table.insert(tasks, task) else table.insert(tasks, 1, task) end; FC:RefreshTodo() end)
          f.checkRows[taskIndex] = row
        end
        row.individual, row.groupIndex, row.taskIndex = entry.individual, groupIndex, index; row.check.individual, row.check.groupIndex, row.check.taskIndex = entry.individual, groupIndex, index; row.edit.individual, row.edit.groupIndex, row.edit.taskIndex = entry.individual, groupIndex, index
        row:SetHeight(rowHeight); row.edit:SetHeight(rowHeight - 4); row:ClearAllPoints(); row:SetPoint("TOPLEFT", f.checkChild, "TOPLEFT", 2, -y); row:SetPoint("TOPRIGHT", f.checkChild, "TOPRIGHT", -2, -y); row.check:SetChecked(task.done); row.edit:SetText(task.text or ""); row.edit:SetFont(FC.FONT_PATH, self.db.todo.fontSize or 15, ""); row.edit:SetTextColor(task.done and 0.55 or 1, task.done and 0.55 or 1, task.done and 0.55 or 1); row.strike:SetShown(task.done); row:Show(); y = y + rowHeight + 1; taskIndex = taskIndex + 1
      end
    end
  end
  for index = headerIndex, #f.groupHeaders do f.groupHeaders[index]:Hide() end
  for index = taskIndex, #f.checkRows do f.checkRows[index]:Hide() end
  f.checkChild:SetHeight(math.max(1, y + 4)); f.checkScroll:UpdateScrollChildRect(); UpdateScrollBar(f.checkScroll, f.checkChild:GetHeight())
end

function FC:RefreshTodo()
  local f, page = self.todoFrame, self:GetTodoPage()
  local checklist = page.mode == "checklist"
  f.loading = true
  f.title:SetText(page.title or L.TODO); f.editor:SetText(page.text or "")
  f.textScroll:SetShown(not checklist); f.checkScroll:SetShown(checklist); f.addTask:SetShown(checklist); f.addGroup:SetShown(checklist); f.mode:SetText(checklist and L.TEXT_MODE or L.CHECKLIST_MODE)
  f.pageLabel:SetText(L.PAGE .. " " .. self.db.todo.currentPage .. " / " .. #self.db.todo.pages)
  if f.favorites then f.favorites:SetText(page.favorite and "★" or "☆") end
  f.previous:SetEnabled(self.db.todo.currentPage > 1); f.next:SetEnabled(self.db.todo.currentPage < #self.db.todo.pages); f.delete:SetEnabled(#self.db.todo.pages > 1)
  f.loading = nil
  self:UpdateTodoEditorSize(); if checklist then self:RefreshTodoChecklist() end; self:ApplyTodoFontSize(); f.fontSlider:SetValue(self.db.todo.fontSize or 14); self:ApplyTodoAppearance(); self:UpdateTodoPlaceholder(); FitButton(f.mode); FitButton(f.new); FitButton(f.delete); FitButton(f.addTask); FitButton(f.addGroup)
  if self.RefreshTodoFavorites then self:RefreshTodoFavorites() end
end

function FC:RefreshTodoFavorites()
  local f = self.todoFrame
  if not f or not f.favoriteList then return end
  local y, count = -5, 0
  for index, page in ipairs(self.db.todo.pages) do
    if page.favorite then
      count = count + 1
      local row = f.favoriteRows[count]
      if not row then
        row = Button(f.favoriteChild, "", 172, function(self)
          FC:SaveTodoPage(); FC.db.todo.currentPage = self.pageIndex; f.favoriteList:Hide(); FC:RefreshTodo()
        end)
        f.favoriteRows[count] = row
      end
      row.pageIndex = index
      row:SetText((page.title and page.title ~= "" and page.title) or (L.PAGE .. " " .. index))
      row:ClearAllPoints(); row:SetPoint("TOPLEFT", f.favoriteChild, "TOPLEFT", 3, y); row:Show(); y = y - 29
    end
  end
  for index = count + 1, #f.favoriteRows do f.favoriteRows[index]:Hide() end
  f.favoriteChild:SetHeight(math.max(1, -y + 5)); f.favoriteScroll:UpdateScrollChildRect(); UpdateScrollBar(f.favoriteScroll, f.favoriteChild:GetHeight())
  f.favoriteEmpty:SetShown(count == 0)
end

function FC:SaveTodoWindow()
  local f = self.todoFrame; local point, _, relativePoint, x, y = f:GetPoint(1)
  self.db.todo.window = { point = point, relativePoint = relativePoint, x = x, y = y, width = f:GetWidth(), height = f:GetHeight() }
end

-- Register only the note frame with Blizzard's built-in Escape handling.
-- This deliberately avoids a global Escape hook, so chat, edit boxes, popups,
-- and other KHQOL/Blizzard windows retain their normal behavior.
function FC:UpdateTodoEscapeBinding()
  if not UISpecialFrames then return end
  for index = #UISpecialFrames, 1, -1 do
    if UISpecialFrames[index] == "ForeverClockTodoFrame" then table.remove(UISpecialFrames, index) end
  end
  if self.db and self.db.todo and self.db.todo.closeOnEscape ~= false then
    table.insert(UISpecialFrames, "ForeverClockTodoFrame")
  end
end

function FC:UpdateTodoMinimapButton()
  local button = self.todoMinimapButton
  if not button or not self.db or not self.db.todo then return end
  local minimap = self.db.todo.minimap
  local angle = math.rad(minimap.angle or 135)
  button:ClearAllPoints()
  button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * 108, math.sin(angle) * 108)
  local enabled = not (KHQOL and KHQOL.db and KHQOL.GetEnabled) or KHQOL:GetEnabled("todo")
  button:SetShown(minimap.show ~= false and enabled)
end

function FC:CreateTodoMinimapButton()
  if self.todoMinimapButton then self:UpdateTodoMinimapButton(); return end
  local button = CreateFrame("Button", "ForeverNoteMinimapButton", Minimap)
  button:SetSize(32, 32)
  button:RegisterForClicks("LeftButtonUp")
  button:RegisterForDrag("LeftButton")
  button:SetMovable(true)
  local icon = button:CreateTexture(nil, "BACKGROUND")
  icon:SetTexture("Interface\\Icons\\INV_Misc_Note_01")
  icon:SetAllPoints(button)
  local border = button:CreateTexture(nil, "OVERLAY")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetAllPoints(button)
  button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  button:SetScript("OnClick", function() FC:ToggleTodo() end)
  button:SetScript("OnDragStart", function(self) self:StartMoving() end)
  button:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local x, y = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    x, y = x / scale, y / scale
    local mx, my = Minimap:GetCenter()
    FC.db.todo.minimap.angle = math.deg(math.atan2(y - my, x - mx))
    FC:UpdateTodoMinimapButton()
  end)
  button:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("ForeverNote", 1, 0.82, 0.25)
    GameTooltip:AddLine("좌클릭: 노트 열기 / 닫기", 1, 1, 1)
    GameTooltip:Show()
  end)
  button:SetScript("OnLeave", function() GameTooltip:Hide() end)
  self.todoMinimapButton = button
  self:UpdateTodoMinimapButton()
end

function FC:ToggleTodoMode(confirmed)
  local page = self:GetTodoPage(); self:SaveTodoPage()
  if page.mode == "checklist" then
    self:EnsureTodoGroups(page)
    if #page.groups > 0 and not confirmed then
      StaticPopup_Show("FOREVERCLOCK_GROUP_TO_TEXT")
      return
    end
    local lines = {}
    for _, task in ipairs(page.individualTasks or {}) do lines[#lines + 1] = (task.done and "[x] " or "[ ] ") .. (task.text or "") end
    for _, group in ipairs(page.groups) do
      for _, task in ipairs(group.tasks) do lines[#lines + 1] = (task.done and "[x] " or "[ ] ") .. (task.text or "") end
    end
    page.text, page.mode = table.concat(lines, "\n"), "text"
  else
    local tasks = {}
    for line in (page.text or ""):gmatch("[^\r\n]+") do
      local marker, text = line:match("^%s*%[([ xX])%]%s*(.*)$")
      tasks[#tasks + 1] = { text = text or line, done = marker and marker:lower() == "x" or false }
    end
    if #tasks == 0 then tasks[1] = { text = "", done = false } end
    page.individualTasks, page.groups, page.tasks, page.activeGroup = tasks, {}, nil, 1
    page.mode = "checklist"
  end
  self:RefreshTodo()
end

function FC:CreateTodo()
  local saved = self.db.todo.window
  self.db.todo.tabSpaces = 8
  local f = CreateFrame("Frame", "ForeverClockTodoFrame", UIParent, "BackdropTemplate")
  f:SetSize(saved.width or 430, saved.height or 310); f:SetPoint(saved.point or "CENTER", UIParent, saved.relativePoint or "CENTER", saved.x or 0, saved.y or 0)
  f:SetFrameStrata("DIALOG"); f:SetToplevel(true); f:SetClampedToScreen(true); f:SetMovable(true); f:SetResizable(true)
  if f.SetResizeBounds then f:SetResizeBounds(440, 270) end
  self.MakeBackdrop(f, 1, 0.78, 0.18, 0.95); self.todoFrame = f
  f:EnableMouse(true)
  f:SetScript("OnMouseDown", function(self, button)
    local focus = GetMouseFocus and GetMouseFocus() or (GetMouseFoci and GetMouseFoci())
    if button == "LeftButton" and focus == self then self:StartMoving(); self.isBlankDragging = true end
  end)
  f:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" and self.isBlankDragging then self:StopMovingOrSizing(); self.isBlankDragging = nil; FC:SaveTodoWindow() end
  end)
  -- This invisible layer receives drags only on blank background; controls created
  -- afterward remain above it and keep their normal click/input behavior.
  f:SetScript("OnMouseDown", nil); f:SetScript("OnMouseUp", nil)
  local drag = CreateFrame("Button", nil, f); drag:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -6); drag:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -6); drag:SetHeight(28); drag:SetFrameLevel(f:GetFrameLevel() + 1); drag:RegisterForClicks("LeftButtonUp")
  drag:SetScript("OnMouseDown", function(_, button) if button == "LeftButton" then f:StartMoving() end end); drag:SetScript("OnMouseUp", function(_, button) if button == "LeftButton" then f:StopMovingOrSizing(); FC:SaveTodoWindow() end end)
  local heading = f:CreateFontString(nil, "OVERLAY", "GameFontNormal"); heading:SetPoint("LEFT", drag, "LEFT", 5, 0); heading:SetFont(FC.FONT_PATH, 15, "OUTLINE"); heading:SetText("Forever Note")
  f.close = Button(f, "×", 28, function() FC:SaveTodoPage(); FC:SaveTodoWindow(); f:Hide() end); f.close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -14, -8); f.close:SetFrameLevel(f:GetFrameLevel() + 4); f.close:GetFontString():SetFont(FC.FONT_PATH, 20, "OUTLINE")
  f.favorite = Button(f, "★", 30, function() f.favoriteList:SetShown(not f.favoriteList:IsShown()); FC:RefreshTodoFavorites() end); f.favorite:SetPoint("RIGHT", f.close, "LEFT", -6, 0); f.favorite:SetFrameLevel(f:GetFrameLevel() + 3); f.favorite:GetFontString():SetFont(FC.FONT_PATH, 20, "OUTLINE")
  f.mode = Button(f, "", 60, function() FC:ToggleTodoMode() end); f.mode:SetPoint("TOPLEFT", f, "TOPLEFT", 142, -6); f.mode:SetFrameLevel(f:GetFrameLevel() + 3)
  f.headerLine = f:CreateTexture(nil, "ARTWORK"); f.headerLine:SetHeight(1); f.headerLine:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -36); f.headerLine:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -36); f.headerLine:SetColorTexture(0.8, 0.65, 0.25, 0.5)
  f.delete = Button(f, L.DELETE, 60, function() if #FC.db.todo.pages > 1 then table.remove(FC.db.todo.pages, FC.db.todo.currentPage); FC.db.todo.currentPage = math.min(FC.db.todo.currentPage, #FC.db.todo.pages); FC:RefreshTodo() end end); f.delete:SetPoint("TOPRIGHT", f, "TOPRIGHT", -14, -42)
  f.new = Button(f, L.NEW, 78, function() FC:SaveTodoPage(); table.insert(FC.db.todo.pages, FC.db.todo.currentPage + 1, { title = "", text = "" }); FC.db.todo.currentPage = FC.db.todo.currentPage + 1; FC:RefreshTodo(); f.title:SetFocus() end); f.new:SetPoint("RIGHT", f.delete, "LEFT", -4, 0)
  f.title = CreateFrame("EditBox", nil, f, "InputBoxTemplate"); f.title:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -42); f.title:SetPoint("RIGHT", f.new, "LEFT", -6, 0); f.title:SetHeight(24); f.title:SetAutoFocus(false); f.title:SetMaxLetters(80); f.title:SetFont(FC.FONT_PATH, 15, "OUTLINE")
  f.title:SetScript("OnTextChanged", function(_, userInput) if userInput then FC:SaveTodoPage() end; FC:UpdateTodoPlaceholder() end); f.title:SetScript("OnEnterPressed", function(self) self:ClearFocus() end); f.title:SetScript("OnEditFocusGained", function(self) f.lastEditBox = self; FC:UpdateTodoPlaceholder() end); f.title:SetScript("OnEditFocusLost", function() FC:UpdateTodoPlaceholder() end)
  f.titlePlaceholder = f:CreateFontString(nil, "OVERLAY"); f.titlePlaceholder:SetPoint("LEFT", f.title, "LEFT", 5, 0); f.titlePlaceholder:SetFont(FC.FONT_PATH, 13, ""); f.titlePlaceholder:SetText("타이틀을 입력해주세요"); f.titlePlaceholder:SetTextColor(0.58, 0.58, 0.58, 1)
  f.contentLine = f:CreateTexture(nil, "ARTWORK"); f.contentLine:SetHeight(1); f.contentLine:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -76); f.contentLine:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -76); f.contentLine:SetColorTexture(0.8, 0.65, 0.25, 0.22)
  f.editorBorder = CreateFrame("Frame", nil, f, "BackdropTemplate"); f.editorBorder:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -82); f.editorBorder:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 36); self.MakeBackdrop(f.editorBorder, 0.72, 0.56, 0.2, 0.82)
  f.textScroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate"); f.textScroll:SetPoint("TOPLEFT", f.editorBorder, "TOPLEFT", 6, -34); f.textScroll:SetPoint("BOTTOMRIGHT", f.editorBorder, "BOTTOMRIGHT", -6, 6); f.textScroll:EnableMouse(true)
  f.editor = CreateFrame("EditBox", nil, f.textScroll, "InputBoxTemplate"); f.editor:SetMultiLine(true); f.editor:SetAutoFocus(false); f.editor:SetFont(FC.FONT_PATH, 14, ""); f.editor:SetTextColor(1, 1, 1); f.editor:SetHighlightColor(1, 0.82, 0.15, 0.55); f.editor:SetJustifyH("LEFT"); f.editor:SetJustifyV("TOP"); f.editor:SetHeight(1200); f.editor:SetPoint("TOPLEFT", f.textScroll, "TOPLEFT", 0, 0)
  f.editor:EnableMouse(true); if f.editor.SetMouseClickEnabled then f.editor:SetMouseClickEnabled(true) end; f.editor:EnableKeyboard(true); f.editor:SetTextInsets(4, 4, 3, 3)
  if f.editor.SetBlinkSpeed then f.editor:SetBlinkSpeed(0.5) end
  -- InputBoxTemplate's native cursor is not reliably rendered in this beta's
  -- multi-line scroll child. Mirror the cursor location provided by the client.
  f.editorCursor = f.editor:CreateTexture(nil, "OVERLAY"); f.editor.fcCursor = f.editorCursor; f.editorCursor:SetColorTexture(1, 1, 1, 1); f.editorCursor:SetWidth(2); f.editorCursor:Hide()
  local cursorPulse = f.editorCursor:CreateAnimationGroup(); cursorPulse:SetLooping("REPEAT")
  local cursorFadeOut = cursorPulse:CreateAnimation("Alpha"); cursorFadeOut:SetFromAlpha(1); cursorFadeOut:SetToAlpha(0.15); cursorFadeOut:SetDuration(0.5)
  local cursorFadeIn = cursorPulse:CreateAnimation("Alpha"); cursorFadeIn:SetFromAlpha(0.15); cursorFadeIn:SetToAlpha(1); cursorFadeIn:SetDuration(0.5)
  f.editorCursorPulse = cursorPulse
  -- Keep the EditBox's native mouse behavior: it handles cursor placement,
  -- text-range selection, and drag-copy correctly.
  -- Hook instead of replacing InputBoxTemplate scripts.  The template owns
  -- native caret placement and mouse text-selection behavior.
  f.editor:HookScript("OnEditFocusGained", function(self) f.lastEditBox = self; if self.SetBlinkSpeed then self:SetBlinkSpeed(0.5) end; f.editorCursor:Show(); if not f.editorCursorPulse:IsPlaying() then f.editorCursorPulse:Play() end; FC:UpdateTodoPlaceholder() end)
  f.editor:HookScript("OnMouseDown", function(self, button)
    if button ~= "LeftButton" then return end
    if not self:HasFocus() then self:SetFocus() end
    f.dragSelectionStart = self:GetCursorPosition()
    f.dragStartX, f.dragStartY = GetCursorPosition()
  end)
  f.editor:HookScript("OnMouseUp", function(self, button)
    if button ~= "LeftButton" or f.dragSelectionStart == nil then return end
    local x, y = GetCursorPosition()
    local moved = math.abs(x - (f.dragStartX or x)) > 3 or math.abs(y - (f.dragStartY or y)) > 3
    if moved then
      local finish = self:GetCursorPosition()
      if finish ~= f.dragSelectionStart then
        self:HighlightText(math.min(f.dragSelectionStart, finish), math.max(f.dragSelectionStart, finish))
      else
        -- Some Forever beta builds do not update an EditBox selection while
        -- the button is held.  Preserve usable drag-to-copy as a fallback.
        self:HighlightText(0, -1)
      end
    end
    f.dragSelectionStart = nil
  end)
  f.editor:HookScript("OnEditFocusLost", function() f.editorCursorPulse:Stop(); f.editorCursor:Hide(); FC:UpdateTodoPlaceholder() end)
  f.editor:HookScript("OnCursorChanged", function(_, x, y, width, height)
    f.editorCursor:ClearAllPoints(); f.editorCursor:SetPoint("TOPLEFT", f.editor, "TOPLEFT", x, -y); f.editorCursor:SetSize(math.max(2, width or 2), math.max(14, height or 14))
  end)
  f.editor:HookScript("OnTextChanged", function(_, userInput) if userInput then FC:SaveTodoPage() end; FC:UpdateTodoPlaceholder(); FC:UpdateTodoEditorSize() end); f.editor:SetScript("OnEscapePressed", function(self) self:ClearFocus() end); f.editor:SetScript("OnTabPressed", function(self) self:Insert((" "):rep(8)) end); f.textScroll:SetScrollChild(f.editor)
  f.placeholder = f.textScroll:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); f.placeholder:SetPoint("TOPLEFT", f.textScroll, "TOPLEFT", 5, -5); f.placeholder:SetFont(FC.FONT_PATH, 13, ""); f.placeholder:SetText(L.TODO_PLACEHOLDER); f.placeholder:SetTextColor(0.55, 0.55, 0.55)
  f.checkScroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate"); f.checkScroll:SetPoint("TOPLEFT", f.editorBorder, "TOPLEFT", 6, -34); f.checkScroll:SetPoint("BOTTOMRIGHT", f.editorBorder, "BOTTOMRIGHT", -6, 6)
  f.checkChild = CreateFrame("Frame", nil, f.checkScroll); f.checkChild:SetWidth(360); f.checkChild:SetHeight(1); f.checkScroll:SetScrollChild(f.checkChild); f.checkRows = {}; f.groupHeaders = {}
  f.addGroup = Button(f, L.ADD_GROUP, 80, function() local page = FC:GetTodoPage(); FC:EnsureTodoGroups(page); page.groups[#page.groups + 1] = { title = L.GROUP_DEFAULT, tasks = {} }; page.activeGroup = #page.groups; FC:RefreshTodo() end); f.addGroup:SetPoint("TOPLEFT", f.editorBorder, "TOPLEFT", 8, -6)
  f.addTask = Button(f, L.ADD_TASK, 80, function() local page = FC:GetTodoPage(); FC:EnsureTodoGroups(page); page.individualTasks[#page.individualTasks + 1] = { text = "", done = false }; FC:RefreshTodo() end); f.addTask:SetPoint("LEFT", f.addGroup, "RIGHT", 4, 0)
  f.fontSlider = CreateFrame("Slider", nil, f)
  f.fontSlider:SetSize(90, 14); f.fontSlider:SetOrientation("HORIZONTAL"); f.fontSlider:SetPoint("LEFT", f.addTask, "RIGHT", 12, 0); f.fontSlider:SetMinMaxValues(15, 30); f.fontSlider:SetValueStep(1); f.fontSlider:SetObeyStepOnDrag(true)
  local track = f.fontSlider:CreateTexture(nil, "BACKGROUND"); track:SetPoint("LEFT", f.fontSlider, "LEFT", 0, 0); track:SetPoint("RIGHT", f.fontSlider, "RIGHT", 0, 0); track:SetHeight(5); track:SetColorTexture(1, 1, 1, 0.8)
  local thumb = f.fontSlider:CreateTexture(nil, "OVERLAY"); thumb:SetSize(5, 18); thumb:SetColorTexture(1, 0.82, 0.15, 1); f.fontSlider:SetThumbTexture(thumb)
  f.fontSlider:SetScript("OnValueChanged", function(_, value) if FC.db then FC.db.todo.fontSize = math.floor(value + 0.5); FC:ApplyTodoFontSize(); FC:UpdateTodoEditorSize() end end)
  f.fontValue = f.fontSlider:CreateFontString(nil, "OVERLAY"); f.fontValue:SetPoint("LEFT", f.fontSlider, "RIGHT", 8, 0); f.fontValue:SetFont(FC.FONT_PATH, 14, "OUTLINE"); f.fontValue:SetTextColor(1, 0.84, 0.18, 1)
  local opacityLabel = f:CreateFontString(nil, "OVERLAY"); opacityLabel:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 14, 13); opacityLabel:SetFont(FC.FONT_PATH, 13, "OUTLINE"); opacityLabel:SetText("투명도"); opacityLabel:SetTextColor(1, 0.84, 0.18, 1)
  f.opacitySlider = CreateFrame("Slider", nil, f); f.opacitySlider:SetSize(65, 14); f.opacitySlider:SetOrientation("HORIZONTAL"); f.opacitySlider:SetPoint("LEFT", opacityLabel, "RIGHT", 8, 0); f.opacitySlider:SetMinMaxValues(10, 95); f.opacitySlider:SetValueStep(5); f.opacitySlider:SetObeyStepOnDrag(true)
  local opacityTrack = f.opacitySlider:CreateTexture(nil, "BACKGROUND"); opacityTrack:SetPoint("LEFT", f.opacitySlider, "LEFT", 0, 0); opacityTrack:SetPoint("RIGHT", f.opacitySlider, "RIGHT", 0, 0); opacityTrack:SetHeight(5); opacityTrack:SetColorTexture(1, 1, 1, 0.8)
  local opacityThumb = f.opacitySlider:CreateTexture(nil, "OVERLAY"); opacityThumb:SetSize(5, 18); opacityThumb:SetColorTexture(1, 0.82, 0.15, 1); f.opacitySlider:SetThumbTexture(opacityThumb)
  f.opacityValue = f.opacitySlider:CreateFontString(nil, "OVERLAY"); f.opacityValue:SetPoint("LEFT", f.opacitySlider, "RIGHT", 7, 0); f.opacityValue:SetFont(FC.FONT_PATH, 13, "OUTLINE"); f.opacityValue:SetTextColor(1, 1, 1, 1)
  f.opacitySlider:SetScript("OnValueChanged", function(_, value) if FC.db and not f.updatingOpacity then FC.db.todo.backgroundAlpha = math.floor(value + 0.5) / 100; FC:ApplyTodoAppearance() end end)
  f.nav = CreateFrame("Frame", nil, f); f.nav:SetSize(198, 28); f.nav:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -12, 8)
  f.previous = Button(f, "<", 24, function() FC:SaveTodoPage(); FC.db.todo.currentPage = math.max(1, FC.db.todo.currentPage - 1); FC:RefreshTodo() end); f.previous:SetPoint("LEFT", f.nav, "LEFT", 0, 0)
  f.pageLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); f.pageLabel:SetPoint("LEFT", f.previous, "RIGHT", 8, 0); f.pageLabel:SetWidth(120); f.pageLabel:SetJustifyH("CENTER"); f.pageLabel:SetWordWrap(false); f.pageLabel:SetFont(FC.FONT_PATH, 13, "OUTLINE")
  f.next = Button(f, ">", 24, function() FC:SaveTodoPage(); FC.db.todo.currentPage = math.min(#FC.db.todo.pages, FC.db.todo.currentPage + 1); FC:RefreshTodo() end); f.next:SetPoint("RIGHT", f.nav, "RIGHT", 0, 0)
  f.pageButton = CreateFrame("Button", nil, f.nav); f.pageButton:SetPoint("LEFT", f.pageLabel, "LEFT", 0, 0); f.pageButton:SetSize(120, 26); f.pageButton:RegisterForClicks("LeftButtonUp")
  f.pageButton:SetScript("OnClick", function()
    f.pageJump:SetShown(not f.pageJump:IsShown())
    if f.pageJump:IsShown() then f.jumpInput:SetText(FC.db.todo.currentPage); f.jumpInput:SetFocus(); f.jumpInput:HighlightText() end
  end)
  f.pageJump = CreateFrame("Frame", nil, f, "BackdropTemplate"); f.pageJump:SetSize(132, 32); f.pageJump:SetPoint("TOPRIGHT", f.nav, "BOTTOMRIGHT", 0, -4); f.pageJump:SetFrameStrata("DIALOG"); FC.MakeBackdrop(f.pageJump, 0.95, 0.73, 0.15, 0.92)
  f.jumpInput = CreateFrame("EditBox", nil, f.pageJump, "InputBoxTemplate"); f.jumpInput:SetPoint("LEFT", f.pageJump, "LEFT", 7, 0); f.jumpInput:SetSize(58, 24); f.jumpInput:SetAutoFocus(false); f.jumpInput:SetNumeric(true); f.jumpInput:SetFont(FC.FONT_PATH, 14, "OUTLINE")
  local function GoToPage()
    local target = tonumber(f.jumpInput:GetText())
    target = target and math.floor(target) or nil
    if target and target >= 1 and target <= #FC.db.todo.pages then
      FC:SaveTodoPage(); FC.db.todo.currentPage = target; f.jumpInput:ClearFocus(); f.pageJump:Hide(); FC:RefreshTodo()
    end
  end
  f.jumpInput:SetScript("OnEnterPressed", function() GoToPage() end)
  f.jumpGo = Button(f.pageJump, "이동", 48, function() GoToPage() end); f.jumpGo:SetPoint("RIGHT", f.pageJump, "RIGHT", -5, 0)
  f.pageJump:Hide()
  f.favorites = Button(f, "☆", 30, function() local page = FC:GetTodoPage(); page.favorite = not page.favorite; FC:RefreshTodo() end); f.favorites:SetPoint("TOPRIGHT", f.editorBorder, "TOPRIGHT", -7, -5); f.favorites:GetFontString():SetFont(FC.FONT_PATH, 18, "OUTLINE")
  f.favoriteList = CreateFrame("Frame", nil, f, "BackdropTemplate"); f.favoriteList:SetSize(208, 304); f.favoriteList:SetPoint("TOPLEFT", f, "TOPRIGHT", 6, -8); f.favoriteList:SetFrameStrata("DIALOG"); f.favoriteList:SetFrameLevel(f:GetFrameLevel() + 10); FC.MakeBackdrop(f.favoriteList, 0.95, 0.73, 0.15, 0.92)
  f.favoriteScroll = CreateFrame("ScrollFrame", nil, f.favoriteList, "UIPanelScrollFrameTemplate"); f.favoriteScroll:SetPoint("TOPLEFT", f.favoriteList, "TOPLEFT", 4, -4); f.favoriteScroll:SetPoint("BOTTOMRIGHT", f.favoriteList, "BOTTOMRIGHT", -20, 4)
  f.favoriteChild = CreateFrame("Frame", nil, f.favoriteScroll); f.favoriteChild:SetWidth(190); f.favoriteChild:SetHeight(1); f.favoriteScroll:SetScrollChild(f.favoriteChild); f.favoriteRows = {}
  f.favoriteEmpty = f.favoriteList:CreateFontString(nil, "OVERLAY"); f.favoriteEmpty:SetPoint("CENTER"); f.favoriteEmpty:SetFont(FC.FONT_PATH, 14, "OUTLINE"); f.favoriteEmpty:SetText("즐겨찾기 없음"); f.favoriteEmpty:SetTextColor(0.75, 0.75, 0.75, 1)
  f.favoriteList:Hide()
  local grip = CreateFrame("Button", nil, f); grip:SetSize(18, 18); grip:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, 2); local gripTexture = grip:CreateTexture(nil, "OVERLAY"); gripTexture:SetAllPoints(); gripTexture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
  grip:SetScript("OnMouseDown", function() f:StartSizing("BOTTOMRIGHT") end); grip:SetScript("OnMouseUp", function() f:StopMovingOrSizing(); FC:SaveTodoWindow(); FC:UpdateTodoEditorSize() end)
  self:UpdateTodoMinimumSize()
  f:SetScript("OnSizeChanged", function() FC:UpdateTodoEditorSize() end); f:SetScript("OnHide", function() FC:SaveTodoPage(); FC:SaveTodoWindow() end); f:Hide()
  self:UpdateTodoEscapeBinding()
end

function FC:ToggleTodo()
  if not self.todoFrame then self:CreateTodo() end
  if self.todoFrame:IsShown() then self:SaveTodoPage(); self:SaveTodoWindow(); self.todoFrame:Hide() else self.todoFrame:Show(); self:RefreshTodo() end
end

-- The binding action, the dedicated minimap button, and Clock's right-click
-- all route through ToggleTodo so open/close behavior cannot diverge.
function KHQOL_ToggleForeverNote()
  local clock = KHQOL and KHQOL.modules and KHQOL.modules.clock
  if clock and clock.ToggleTodo then clock:ToggleTodo() end
end
