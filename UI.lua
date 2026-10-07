local _, KHQOL = ...
KHQOL.UI = KHQOL.UI or {}
local UI = KHQOL.UI

-- Settings-only theme. Gameplay frames keep their own fonts, sizes and colors.
UI.Theme = {
  WindowWidth = 860, WindowHeight = 640, WindowPadding = 18,
  SidebarWidth = 180, ContentPadding = 22, ContentWidth = 600,
  HeaderGap = 20, SectionGap = 24, RowGap = 12, RowHeight = 28,
  ControlHeight = 26, ButtonHeight = 26, DropdownHeight = 26, EditBoxHeight = 26,
  CheckboxSize = 26, CheckboxLabelGap = 8, SliderWidth = 110, DropdownWidth = 280,
  SliderRowHeight = 60, DropdownRowHeight = 60, ColorRowHeight = 60,
  ColumnGap = 24,
  TitleFontSize = 22, SectionFontSize = 16, LabelFontSize = 13, DescriptionFontSize = 12,
  DisabledAlpha = .45,
  TextPrimary = { .94, .94, .94, 1 }, TextSecondary = { .68, .70, .73, 1 },
  Accent = { 1, .82, .25, 1 }, Disabled = { .45, .45, .45, 1 },
  Warning = { 1, .3, .25, 1 }, Divider = { .32, .34, .37, .65 },
}
local T = UI.Theme
function UI:Font() return KHQOL.modules.clock.FONT_PATH or STANDARD_TEXT_FONT end
function UI:CreateLabel(parent, text, x, y, size)
  local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  fs:SetPoint("TOPLEFT", x or 0, y or 0); fs:SetFont(self:Font(), size or T.LabelFontSize, "")
  fs:SetTextColor(unpack(T.TextPrimary)); fs:SetJustifyH("LEFT"); fs:SetText(text or "")
  fs:SetWidth(math.max(40, (parent:GetWidth() > 0 and parent:GetWidth() or T.ContentWidth) - (x or 0)))
  return fs
end
function UI:CreateDescription(parent, text, x, y)
  local fs = self:CreateLabel(parent, text, x, y, T.DescriptionFontSize)
  fs:SetTextColor(unpack(T.TextSecondary)); fs:SetWordWrap(true); return fs
end
function UI:CreateDivider(parent, y)
  local line = parent:CreateTexture(nil, "ARTWORK")
  line:SetColorTexture(unpack(T.Divider)); line:SetPoint("TOPLEFT", 0, y)
  line:SetPoint("TOPRIGHT", 0, y); line:SetHeight(1); return line
end
function UI:CreateSection(parent, text, y)
  y = y - T.SectionGap
  local fs = self:CreateLabel(parent, text, 0, y, T.SectionFontSize)
  fs:SetTextColor(unpack(T.Accent)); self:CreateDivider(parent, y - 24)
  return y - 40
end
function UI:CreatePage(parent, title, description, getter, setter)
  self:CreateLabel(parent, title, 0, 0, T.TitleFontSize)
  self:CreateDescription(parent, description, 0, -32)
  local enable
  if getter and setter then
    enable = self:CreateCheckbox(parent, "모듈 사용", 0, -64, getter, setter)
    enable.ignoreModuleEnabled = true; enable:Refresh()
  end
  self:CreateDivider(parent, -104)
  return -104, enable
end
function UI:IsAvailable(control, predicate)
  if predicate and not predicate() then return false end
  if control.ignoreModuleEnabled then return true end
  local parent = control:GetParent()
  while parent do
    if parent.moduleKey then return KHQOL:GetEnabled(parent.moduleKey) end
    parent = parent:GetParent()
  end
  return true
end
function UI:ApplyAvailability(control, predicate, labels)
  local enabled = self:IsAvailable(control, predicate)
  control:SetAlpha(enabled and 1 or T.DisabledAlpha)
  if control.SetEnabled then control:SetEnabled(enabled) end
  control:EnableMouse(enabled)
  for _, fs in ipairs(labels or {}) do fs:SetAlpha(enabled and 1 or T.DisabledAlpha) end
  for _, fs in ipairs(control.uiLabels or {}) do fs:SetAlpha(enabled and 1 or T.DisabledAlpha) end
  if not enabled and control.menu then control.menu:Hide() end
  return enabled
end
function UI:RegisterControl(parent, control)
  parent.uiControls = parent.uiControls or {}; table.insert(parent.uiControls, control)
  return control
end
function UI:Refresh(parent)
  for _, control in ipairs(parent.uiControls or {}) do if control.Refresh then control:Refresh() end end
  for _, child in ipairs({parent:GetChildren()}) do if child.uiControls then self:Refresh(child) end end
end
function UI:Changed(parent)
  if KHQOL.settings and KHQOL.settings.activeContent then self:Refresh(KHQOL.settings.activeContent)
  else self:Refresh(parent) end
end
function UI:AttachTooltip(control, title, description)
  if not description or description == "" then return end
  control:HookScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(title, unpack(T.Accent))
    GameTooltip:AddLine(description, .94, .94, .94, true); GameTooltip:Show()
  end)
  control:HookScript("OnLeave", function() GameTooltip:Hide() end)
end
function UI:CreateCheckbox(parent, text, x, y, getter, setter, enabled)
  local b = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  b:SetSize(T.CheckboxSize, T.CheckboxSize); b:SetPoint("TOPLEFT", x, y)
  b.text = self:CreateLabel(b, text, T.CheckboxSize + T.CheckboxLabelGap, -6)
  b.text:SetWidth(math.max(40, (parent:GetWidth() > 0 and parent:GetWidth() or T.ContentWidth) - x - T.CheckboxSize - T.CheckboxLabelGap))
  b.label = b.text
  b.Refresh = function() b:SetChecked(getter() and true or false); UI:ApplyAvailability(b, enabled) end
  b:SetScript("OnClick", function()
    if UI:IsAvailable(b, enabled) then setter(b:GetChecked() and true or false); UI:Changed(parent) end
  end)
  self:RegisterControl(parent, b); b:Refresh(); return b
end
function UI:CreateButton(parent, text, x, y, width, click, enabled)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(width or 150, T.ButtonHeight); b:SetPoint("TOPLEFT", x, y); b:SetText(text)
  b:GetFontString():SetFont(self:Font(), T.LabelFontSize, "")
  -- Explicit widths are caps, not padding; sidebar buttons opt back into a fixed width.
  b:SetWidth(math.min(width or T.ContentWidth, math.ceil(b:GetFontString():GetStringWidth()) + 24))
  b.Refresh = function() UI:ApplyAvailability(b, enabled) end
  b:SetScript("OnClick", function(self, mouseButton)
    if UI:IsAvailable(b, enabled) then click(self, mouseButton); UI:Changed(parent) end
  end)
  self:RegisterControl(parent, b); b:Refresh(); return b
end
local serial = 0
function UI:CreateSlider(parent, title, description, x, y, min, max, step, getter, setter, format, enabled)
  local titleLabel = self:CreateLabel(parent, title, x, y)
  titleLabel:SetWidth((T.ContentWidth-T.ColumnGap)/2)
  serial = serial + 1
  local name = "KHQOLSettingsSlider" .. serial
  local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
  slider:SetPoint("TOPLEFT", x, y - 24); slider:SetSize(T.SliderWidth, 18)
  slider:SetMinMaxValues(min, max); slider:SetValueStep(step)
  if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
  for _, suffix in ipairs({"Low", "High", "Text"}) do
    local fs = _G[name .. suffix]; if fs then fs:SetText("") end
  end
  format = format or tostring
  local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
  box:SetPoint("TOPLEFT", x + T.SliderWidth + 14, y - 20); box:SetSize(86, T.EditBoxHeight)
  box:SetAutoFocus(false); box:SetFont(self:Font(), T.LabelFontSize, ""); box:SetTextInsets(6,6,0,0)
  slider.numberBox = box
  local function rounded(value)
    return math.max(min, math.min(max, min + math.floor((value-min)/step+.5)*step))
  end
  local function commit()
    if not UI:IsAvailable(slider, enabled) then box:SetText(format(getter())); return end
    local raw = box:GetText():match("^%s*(.-)%s*$")
    local numeric = raw:gsub("%%", ""):gsub("px", ""):gsub("초", "")
    local value = tonumber(numeric)
    if raw == "기본" and min <= 0 and max >= 0 and format(0) == "기본" then value = 0 end
    if value and value == value and value ~= math.huge and value ~= -math.huge then
      -- Fractional opacity controls display percentages; other ranges retain their units.
      if max <= 1 and tostring(format(getter())):find("%", 1, true) then value = value / 100 end
      setter(rounded(value)); slider:Refresh(); UI:Changed(parent)
    end
    box:SetText(format(getter()))
  end
  box:SetScript("OnEnterPressed", function() commit(); box.cancelFocus=true; box:ClearFocus(); box.cancelFocus=nil end)
  box:SetScript("OnEscapePressed", function() box.cancelFocus=true; box:ClearFocus(); box.cancelFocus=nil; box:SetText(format(getter())) end)
  box:SetScript("OnEditFocusLost", function() if not box.cancelFocus then commit() end end)
  box:SetScript("OnEditFocusGained", function() box:HighlightText() end)
  slider.Refresh = function()
    slider.setting = true; slider:SetValue(getter()); slider.setting = false
    if not box:HasFocus() then box:SetText(format(getter())) end
    UI:ApplyAvailability(slider, enabled, {titleLabel}); UI:ApplyAvailability(box, enabled)
  end
  slider:SetScript("OnValueChanged", function(_, value)
    if slider.setting or not UI:IsAvailable(slider, enabled) then return end
    setter(rounded(value)); box:SetText(format(getter())); UI:Changed(parent)
  end)
  self:AttachTooltip(slider, title, description)
  self:AttachTooltip(box, title, "수치를 직접 입력한 후 Enter를 누르면 적용됩니다. Esc는 입력을 취소합니다.")
  self:RegisterControl(parent, slider); slider:Refresh(); return slider
end
function UI:CloseDropdown()
  if self.openDropdown then self.openDropdown:Hide(); self.openDropdown = nil end
end
function UI:CreateDropdown(parent, x, y, width, options, getter, setter, enabled)
  width = width or T.DropdownWidth
  local b
  local function unavailable(option)
    return not UI:IsAvailable(b, enabled) or option.disabled == true or (type(option.disabled) == "function" and option.disabled())
  end
  b = self:CreateButton(parent, "", x, y, width, function()
    if b.menu and b.menu:IsShown() then UI:CloseDropdown(); return end
    UI:CloseDropdown()
    if not b.menu then
      -- Popup belongs to the window, outside the clipped ScrollFrame.
      local menu = CreateFrame("Frame", nil, KHQOL.settings or UIParent, "BackdropTemplate")
      local menuWidth = 100
      for _, option in ipairs(options) do
        b:GetFontString():SetText(option.text)
        menuWidth = math.max(menuWidth, math.ceil(b:GetFontString():GetStringWidth()) + 48)
      end
      menu:SetPoint("TOPLEFT", b, "BOTTOMLEFT", 0, -2); menu:SetSize(menuWidth, #options * (T.ControlHeight + 2) + 8)
      menu:SetFrameStrata("FULLSCREEN_DIALOG"); menu:SetClampedToScreen(true); menu:EnableMouse(true)
      menu:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", edgeSize=10, insets={left=3,right=3,top=3,bottom=3}})
      menu:SetBackdropColor(.04,.04,.04,.98); b.menu = menu; b.rows = {}
      for i, option in ipairs(options) do
        local choice = option
        local row = CreateFrame("Button", nil, menu)
        row:SetPoint("TOPLEFT", 4, -4-(i-1)*(T.ControlHeight+2)); row:SetSize(menuWidth-8,T.ControlHeight)
        row.radio = UI:CreateLabel(row,"○",6,-5); row.radio:SetWidth(18)
        row.text = UI:CreateLabel(row,choice.text,28,-5); row.text:SetWidth(menuWidth-40)
        local highlight=row:CreateTexture(nil,"HIGHLIGHT"); highlight:SetAllPoints(); highlight:SetColorTexture(1,1,1,.08)
        row:SetScript("OnClick", function()
          if unavailable(choice) then return end
          setter(choice.value); UI:CloseDropdown(); UI:Changed(parent)
        end)
        b.rows[i] = row
      end
      menu:Hide()
    end
    b:Refresh(); b.menu:Show(); UI.openDropdown = b.menu
  end, enabled)
  b.Refresh = function()
    local value = getter(); local selected = "선택"
    for i, option in ipairs(options) do
      if option.value == value then selected = option.text end
      if b.rows then
        local row=b.rows[i]; row:SetEnabled(not unavailable(option)); row:EnableMouse(not unavailable(option))
        row:SetAlpha(unavailable(option) and T.DisabledAlpha or 1)
        row.radio:SetText(option.value==value and "●" or "○")
        row.radio:SetTextColor(unpack(option.value==value and T.Accent or T.TextSecondary))
      end
    end
    b:SetText(selected .. "  ▼")
    b:SetWidth(math.min(width, math.ceil(b:GetFontString():GetStringWidth())+24))
    UI:ApplyAvailability(b, enabled)
  end
  b:Refresh(); return b
end
function UI:OpenColorPicker(getter, setter, refresh, captureRestore, supportsOpacity)
  local picker = ColorPickerFrame; if not picker or not picker.GetColorRGB then return end
  local r, g, b, a = getter(); a = a or 1
  local restore = captureRestore and captureRestore(); local initializing = true
  local function apply()
    if initializing then return end
    local nr, ng, nb = picker:GetColorRGB(); local alpha = a
    if supportsOpacity then
      if picker.GetColorAlpha then alpha = picker:GetColorAlpha()
      elseif OpacitySliderFrame then alpha = 1 - OpacitySliderFrame:GetValue() end
      alpha = math.max(0, math.min(1, alpha))
      setter(nr, ng, nb, alpha)
    else setter(nr, ng, nb) end
    if refresh then refresh() end
  end
  local function cancel()
    if restore then restore() elseif supportsOpacity then setter(r,g,b,a) else setter(r,g,b) end
    if refresh then refresh() end
  end
  picker:Hide()
  if picker.SetupColorPickerAndShow then
    picker:SetupColorPickerAndShow({r=r,g=g,b=b,opacity=a,hasOpacity=supportsOpacity and true or false,swatchFunc=apply,opacityFunc=supportsOpacity and apply or nil,cancelFunc=cancel})
  elseif picker.SetColorRGB then
    picker.func=nil; picker.swatchFunc=nil; picker.opacityFunc=nil; picker.cancelFunc=nil
    picker.hasOpacity=supportsOpacity and true or false; picker.opacity=1-a; picker.previousValues={r=r,g=g,b=b,a=a}
    picker:SetColorRGB(r,g,b); if supportsOpacity and OpacitySliderFrame then OpacitySliderFrame:SetValue(1-a) end
    picker.func=apply; picker.swatchFunc=apply; picker.opacityFunc=supportsOpacity and apply or nil; picker.cancelFunc=cancel; picker:Show()
  end
  initializing = false
end
function UI:CreateColorPicker(parent, title, x, y, getter, setter, enabled, captureRestore, supportsOpacity)
  local titleLabel = self:CreateLabel(parent, title, x, y)
  local b
  b = self:CreateButton(parent, "색상 선택", x, y-24, 150, function()
    UI:OpenColorPicker(getter, setter, function() UI:Changed(parent) end, captureRestore, supportsOpacity)
  end, enabled)
  b.swatch = b:CreateTexture(nil, "OVERLAY"); b.swatch:SetSize(18, 18); b.swatch:SetPoint("LEFT", 8, 0)
  titleLabel:SetWidth((T.ContentWidth-2*T.ColumnGap)/3)
  b:SetWidth(math.ceil(b:GetFontString():GetStringWidth())+48)
  b:GetFontString():ClearAllPoints(); b:GetFontString():SetPoint("LEFT", 32, 0); b:GetFontString():SetPoint("RIGHT", -8, 0)
  b.Refresh = function()
    local r,g,bl = getter(); b.swatch:SetColorTexture(r,g,bl,1); UI:ApplyAvailability(b, enabled, {titleLabel})
  end
  b:Refresh(); return b
end
function UI:CreateEditBox(parent, x, y, width, getter, setter, enabled)
  local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
  box:SetSize(width or T.DropdownWidth, T.EditBoxHeight); box:SetPoint("TOPLEFT", x, y)
  box:SetAutoFocus(false); box:SetFont(self:Font(), T.LabelFontSize, ""); box:SetTextInsets(8,8,0,0)
  box:SetScript("OnEscapePressed", function(self) self:ClearFocus(); self:Refresh() end)
  box:SetScript("OnEnterPressed", function(self)
    if setter and UI:IsAvailable(box, enabled) then setter(self:GetText()) end
    self:ClearFocus(); UI:Changed(parent)
  end)
  box.Refresh = function()
    if getter and not box:HasFocus() then box:SetText(tostring(getter() or "")) end
    UI:ApplyAvailability(box, enabled)
  end
  self:RegisterControl(parent, box); box:Refresh(); return box
end
function UI:CreatePreviewBox(parent, x, y, width, lines, fontSize)
  local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  box:SetPoint("TOPLEFT", x, y); box:SetSize(width, math.max(82, #lines*24+24))
  box:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=10,insets={left=4,right=4,top=4,bottom=4}})
  box:SetBackdropColor(.04,.04,.04,.95)
  for i, text in ipairs(lines) do local row=self:CreateLabel(box,text,12,-12-(i-1)*24,fontSize or T.LabelFontSize); row:SetWidth(width-24) end
  return box
end
function UI:CreateBuilder(parent, y)
  local builder = {parent=parent, y=y or 0}
  function builder:Flush() self.rowKind=nil; self.rowCount=0 end
  function builder:Cell(kind,columns,height)
    if self.rowKind~=kind or self.rowCount>=columns or self.y~=self.rowBottom then
      self.rowKind=kind; self.rowCount=0; self.rowY=self.y
      self.y=self.y-height; self.rowBottom=self.y
    end
    local width=(T.ContentWidth-(columns-1)*T.ColumnGap)/columns
    local x=self.rowCount*(width+T.ColumnGap); self.rowCount=self.rowCount+1
    return x,self.rowY,width
  end
  function builder:Section(title) self:Flush(); self.y=UI:CreateSection(parent,title,self.y) end
  function builder:Checkbox(title,getter,setter,enabled)
    local x,y,width=self:Cell("check",2,T.RowHeight+T.RowGap)
    local control=UI:CreateCheckbox(parent,title,x,y,getter,setter,enabled)
    control.text:SetWidth(width-T.CheckboxSize-T.CheckboxLabelGap); return control
  end
  function builder:Slider(title,min,max,step,getter,setter,format,enabled,description)
    local x,y=self:Cell("field",2,T.SliderRowHeight)
    return UI:CreateSlider(parent,title,description or "",x,y,min,max,step,getter,setter,format,enabled)
  end
  function builder:Dropdown(title,options,getter,setter,enabled)
    if self.rowKind=="color" and self.rowCount==1 and self.y==self.rowBottom then self.rowKind="field" end
    local x,y,width=self:Cell("field",2,T.DropdownRowHeight)
    local label=UI:CreateLabel(parent,title,x,y); label:SetWidth(width)
    local control=UI:CreateDropdown(parent,x,y-24,width,options,getter,setter,enabled)
    control.uiLabels={label}; control:Refresh(); return control
  end
  function builder:Edit(title,getter,setter,enabled)
    local x,y,width=self:Cell("field",2,T.DropdownRowHeight)
    local label=UI:CreateLabel(parent,title,x,y); label:SetWidth(width)
    local control=UI:CreateEditBox(parent,x,y-24,width,getter,setter,enabled)
    control.uiLabels={label}; control:Refresh(); return control
  end
  function builder:Color(title,getter,setter,enabled,restore,alpha)
    local pair=self.rowKind=="field" and self.rowCount==1 and self.y==self.rowBottom
    local x,y=self:Cell(pair and "field" or "color",pair and 2 or 3,T.ColorRowHeight)
    return UI:CreateColorPicker(parent,title,x,y,getter,setter,enabled,restore,alpha)
  end
  function builder:Button(title,callback,width,enabled)
    local x,y,cellWidth=self:Cell("button",2,T.RowHeight+T.RowGap)
    return UI:CreateButton(parent,title,x,y,math.min(width or cellWidth,cellWidth),callback,enabled)
  end
  function builder:Description(text)
    self:Flush()
    local fs=UI:CreateDescription(parent,text,0,self.y); self.y=self.y-math.max(18,fs:GetStringHeight())-T.RowGap; return fs
  end
  return builder
end
