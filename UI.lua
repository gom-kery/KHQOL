local _, KHQOL = ...
KHQOL.UI = KHQOL.UI or {}
local UI = KHQOL.UI

-- Settings-only theme. Gameplay frames keep their own fonts, sizes and colors.
UI.Theme = {
  WindowWidth = 900, WindowHeight = 700, WindowPadding = 18,
  SidebarWidth = 200, ContentPadding = 20, ContentWidth = 640,
  HeaderGap = 20, SectionGap = 14, RowGap = 8, RowHeight = 28,
  ControlHeight = 26, ButtonHeight = 26, DropdownHeight = 26, EditBoxHeight = 26,
  CheckboxSize = 26, CheckboxLabelGap = 8, SliderWidth = 110, DropdownWidth = 280,
  SliderRowHeight = 60, DropdownRowHeight = 60, ColorRowHeight = 60,
  ColumnGap = 20,
  TitleFontSize = 22, SectionFontSize = 14, LabelFontSize = 13, DescriptionFontSize = 12,
  DisabledAlpha = .45,
  TextPrimary = { .92, .92, .92, 1 }, TextSecondary = { .68, .68, .68, 1 },
  Accent = { .90, .90, .90, 1 }, AccentHex = "e6e6e6", Disabled = { .45, .45, .45, 1 },
  -- Restrained color for settings hierarchy; gray button surfaces stay unchanged.
  FocusAccent = { 114/255, 173/255, 165/255, 1 },
  Warning = { 1, .3, .25, 1 }, Divider = { .29, .29, .29, .60 },
  Background = { .065, .065, .065, 1 }, Border = { .36, .36, .36, 1 },
  ButtonBackground = { .13, .13, .13, 1 }, ButtonHover = { .20, .20, .20, 1 },
  ButtonPushed = { .08, .08, .08, 1 }, ButtonSelected = { .24, .24, .24, 1 },
  ButtonDisabled = { .09, .09, .09, 1 }, HoverBorder = { .72, .72, .72, 1 },
  PushedBorder = { .56, .56, .56, 1 }, Highlight = { 1, 1, 1, .08 },
  CheckboxOff = { .18, .18, .18, 1 }, CheckboxDisabledOn = { .40, .40, .40, 1 },
  CheckboxOnText = { .10, .10, .10, 1 }, CheckboxOffText = { .76, .76, .76, 1 },
  SliderTrack = { .30, .30, .30, 1 }, CellFill = { .35, .35, .35, .045 },
  CellLine = { .35, .35, .35, .12 },
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
  fs:SetTextColor(unpack(T.FocusAccent)); self:CreateDivider(parent, y - 24)
  return y - 36
end
function UI:CreatePage(parent, title, description, getter, setter)
  -- Keep glyphs below the viewport edge and align captions with checkbox labels.
  self:CreateDescription(parent, description, 0, -6):SetWidth(T.ContentWidth-110)
  local enable
  if getter and setter then
    enable=self:CreateCheckbox(parent,"모듈 사용",T.ContentWidth-108,0,getter,setter)
    enable.text:SetWidth(76); enable.ignoreModuleEnabled=true; enable:Refresh()
  end
  self:CreateDivider(parent,-34)
  return -34,enable
end
-- These skins are used only by settings controls and the position editor.
function UI:Surface(frame, opacity)
  if not frame.SetBackdrop and Mixin and BackdropTemplateMixin then Mixin(frame,BackdropTemplateMixin) end
  if not frame.SetBackdrop then return end
  frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
  frame:SetBackdropColor(T.Background[1],T.Background[2],T.Background[3],opacity or .98)
  frame:SetBackdropBorderColor(unpack(T.Border))
end
function UI:GetButtonFonts()
  if not self.buttonFonts then
    self.buttonFonts={}
    for key,color in pairs({Normal=T.TextPrimary,Highlight=T.Accent,Disabled=T.Disabled}) do
      local font=CreateFont("KHQOLSettingsButton"..key)
      font:SetFont(self:Font(),T.LabelFontSize,""); font:SetTextColor(unpack(color))
      self.buttonFonts[key]=font
    end
  end
  return self.buttonFonts
end
function UI:UpdateButtonSkin(button)
  local enabled=button:IsEnabled()
  local selected=button.khqolSelected
  local fill=not enabled and T.ButtonDisabled or button.khqolPressed and T.ButtonPushed
    or selected and T.ButtonSelected or button.khqolHovered and T.ButtonHover or T.ButtonBackground
  local border=not enabled and T.Border or button.khqolPressed and T.PushedBorder
    or selected and T.FocusAccent or button.khqolHovered and T.HoverBorder or T.Border
  button:SetBackdropColor(unpack(fill)); button:SetBackdropBorderColor(unpack(border))
  local color=not enabled and T.Disabled or selected and T.FocusAccent or T.TextPrimary
  button:GetFontString():SetTextColor(unpack(color))
end
function UI:SetButtonSelected(button,selected)
  button.khqolSelected=selected and true or false
  self:UpdateButtonSkin(button)
end
function UI:SkinButton(button)
  if button.khqolSkinned then return end
  button.khqolSkinned=true
  -- Plain KHQOL-owned buttons deliberately inherit no UIPanel red slices or scripts.
  local fs=button:CreateFontString(nil,"OVERLAY")
  fs:SetFont(self:Font(),T.LabelFontSize,""); fs:SetPoint("CENTER")
  button:SetFontString(fs)
  local fonts=self:GetButtonFonts()
  button:SetNormalFontObject(fonts.Normal); button:SetHighlightFontObject(fonts.Highlight)
  button:SetDisabledFontObject(fonts.Disabled)
  button:SetNormalTexture(""); button:SetPushedTexture(""); button:SetDisabledTexture("")
  self:Surface(button,.96)
  button:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
  local highlight=button:GetHighlightTexture()
  if highlight then highlight:ClearAllPoints(); highlight:SetAllPoints(button); highlight:SetVertexColor(unpack(T.Highlight)) end
  button:HookScript("OnEnter",function(self) self.khqolHovered=true; UI:UpdateButtonSkin(self) end)
  button:HookScript("OnLeave",function(self) self.khqolHovered=false; self.khqolPressed=false; UI:UpdateButtonSkin(self) end)
  button:HookScript("OnMouseDown",function(self) self.khqolPressed=self:IsEnabled(); UI:UpdateButtonSkin(self) end)
  button:HookScript("OnMouseUp",function(self) self.khqolPressed=false; UI:UpdateButtonSkin(self) end)
  button:HookScript("OnShow",function(self) self.khqolHovered=false; self.khqolPressed=false; UI:UpdateButtonSkin(self) end)
  button:HookScript("OnEnable",function(self) UI:UpdateButtonSkin(self) end)
  button:HookScript("OnDisable",function(self) self.khqolHovered=false; self.khqolPressed=false; UI:UpdateButtonSkin(self) end)
  self:UpdateButtonSkin(button)
end
function UI:CellBackground(parent,x,y,width,height)
  local bg=parent:CreateTexture(nil,"BACKGROUND"); bg:SetPoint("TOPLEFT",x-4,y+5)
  bg:SetSize(width+8,height-3); bg:SetColorTexture(unpack(T.CellFill))
  local line=parent:CreateTexture(nil,"BACKGROUND"); line:SetPoint("TOPLEFT",x,y-height+6)
  line:SetSize(width,1); line:SetColorTexture(unpack(T.CellLine))
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
  if control.khqolSkinned then self:UpdateButtonSkin(control) end
  if control.disabledHint then control.disabledHint:SetShown(not enabled) end
  for _, fs in ipairs(labels or {}) do fs:SetAlpha(enabled and 1 or T.DisabledAlpha) end
  for _, fs in ipairs(control.uiLabels or {}) do fs:SetAlpha(enabled and 1 or T.DisabledAlpha) end
  if not enabled and control.menu then control.menu:Hide() end
  return enabled
end
function UI:RegisterControl(parent, control)
  parent.uiControls = parent.uiControls or {}; table.insert(parent.uiControls, control)
  local hint=CreateFrame("Frame",nil,control); hint:SetAllPoints(control); hint:EnableMouse(true); hint:Hide()
  hint:SetScript("OnEnter",function(self)
    GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText("사용할 수 없는 설정",unpack(T.Accent))
    local p=control:GetParent(); local disabledModule=false
    while p do if p.moduleKey and not KHQOL:GetEnabled(p.moduleKey) then disabledModule=true; break end; p=p:GetParent() end
    GameTooltip:AddLine(disabledModule and "상단의 모듈 사용을 먼저 켜세요." or "연결된 기능을 켜거나 해당 표시 모드를 선택하면 변경할 수 있습니다.",T.TextSecondary[1],T.TextSecondary[2],T.TextSecondary[3],true); GameTooltip:Show()
  end)
  hint:SetScript("OnLeave",function() GameTooltip:Hide() end); control.disabledHint=hint
  return control
end
function UI:Refresh(parent)
  for _, control in ipairs(parent.uiControls or {}) do if control.Refresh then control:Refresh() end end
  for _, child in ipairs({parent:GetChildren()}) do if child.uiControls then self:Refresh(child) end end
end
function UI:Changed(parent)
  if KHQOL.settings and KHQOL.settings.activeContent then self:Refresh(KHQOL.settings.activeContent)
  else self:Refresh(parent) end
  if KHQOL.SaveCurrentProfile then KHQOL:SaveCurrentProfile() end
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
  local b = CreateFrame("CheckButton", nil, parent, "BackdropTemplate")
  b:SetSize(T.CheckboxSize, T.CheckboxSize); b:SetPoint("TOPLEFT", x, y)
  b.text = self:CreateLabel(b, text, T.CheckboxSize + T.CheckboxLabelGap, -6)
  b.text:SetWidth(math.max(40, (parent:GetWidth() > 0 and parent:GetWidth() or T.ContentWidth) - x - T.CheckboxSize - T.CheckboxLabelGap))
  b.label = b.text
  b:SetNormalTexture("Interface\\Buttons\\WHITE8X8"); b:GetNormalTexture():SetVertexColor(unpack(T.CheckboxOff))
  b:SetDisabledTexture("Interface\\Buttons\\WHITE8X8"); b:GetDisabledTexture():SetVertexColor(unpack(T.CheckboxOff))
  b:SetCheckedTexture("Interface\\Buttons\\WHITE8X8"); b:GetCheckedTexture():SetVertexColor(unpack(T.FocusAccent))
  b:SetPushedTexture(""); b:SetHighlightTexture("Interface\\Buttons\\WHITE8X8"); b:GetHighlightTexture():SetVertexColor(unpack(T.Highlight))
  b.state=b:CreateFontString(nil,"OVERLAY"); b.state:SetPoint("CENTER"); b.state:SetFont(UI:Font(),9,"")
  if b.SetDisabledCheckedTexture then
    b:SetDisabledCheckedTexture(b:GetCheckedTexture():GetTexture())
    local disabled=b:GetDisabledCheckedTexture(); if disabled then disabled:SetVertexColor(unpack(T.CheckboxDisabledOn)) end
  end
  b.Refresh = function()
    local on=getter() and true or false; b:SetChecked(on); b.state:SetText(on and "ON" or "OFF")
    b.state:SetTextColor(unpack(on and T.CheckboxOnText or T.CheckboxOffText))
    UI:ApplyAvailability(b, enabled)
  end
  b:SetScript("OnClick", function()
    if UI:IsAvailable(b, enabled) then setter(b:GetChecked() and true or false); UI:Changed(parent) end
  end)
  self:RegisterControl(parent, b); b:Refresh(); return b
end
function UI:CreateButton(parent, text, x, y, width, click, enabled)
  local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
  b:SetSize(width or 150, T.ButtonHeight); b:SetPoint("TOPLEFT", x, y)
  self:SkinButton(b); b:SetText(text)
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
  local slider = CreateFrame("Slider", name, parent)
  slider:SetOrientation("HORIZONTAL")
  local track=slider:CreateTexture(nil,"BACKGROUND"); track:SetPoint("LEFT"); track:SetPoint("RIGHT"); track:SetHeight(4); track:SetColorTexture(unpack(T.SliderTrack))
  local thumb=slider:CreateTexture(nil,"OVERLAY"); thumb:SetSize(10,16); thumb:SetColorTexture(unpack(T.FocusAccent)); slider:SetThumbTexture(thumb)
  slider:SetPoint("TOPLEFT", x, y - 24); slider:SetSize(T.SliderWidth, 18)
  slider:SetMinMaxValues(min, max); slider:SetValueStep(step)
  if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
  for _, suffix in ipairs({"Low", "High", "Text"}) do
    local fs = _G[name .. suffix]; if fs then fs:SetText("") end
  end
  format = format or tostring
  local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate,BackdropTemplate")
  box:SetPoint("TOPLEFT", x + T.SliderWidth + 14, y - 20); box:SetSize(86, T.EditBoxHeight)
  for _,region in ipairs({box:GetRegions()}) do if region:GetObjectType()=="Texture" then region:SetAlpha(0) end end
  UI:Surface(box)
  box:SetAutoFocus(false); box:SetFont(self:Font(), T.LabelFontSize, ""); box:SetTextInsets(6,6,0,0)
  -- Numeric text must not depend on inherited input-template presentation.
  box:SetTextColor(unpack(T.TextPrimary)); box:SetJustifyH("LEFT"); box:SetJustifyV("MIDDLE")
  box:SetText(format(getter()))
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
  -- Nested settings panels may first appear after their controls were created.
  -- Refresh on visibility changes too, while retaining a focused user draft.
  box:HookScript("OnShow", function() slider:Refresh() end)
  self:RegisterControl(parent, slider); slider:Refresh(); return slider
end
function UI:CloseDropdown()
  if self.openDropdown then self.openDropdown:Hide(); self.openDropdown = nil end
end
function UI:CreateDropdown(parent, x, y, width, options, getter, setter, enabled)
  width = width or T.DropdownWidth
  local optionSource=type(options)=="function" and options or nil
  if optionSource then options=optionSource() end
  local b
  local function unavailable(option)
    return not UI:IsAvailable(b, enabled) or option.disabled == true or (type(option.disabled) == "function" and option.disabled())
  end
  b = self:CreateButton(parent, "", x, y, width, function()
    if b.menu and b.menu:IsShown() then UI:CloseDropdown(); return end
    UI:CloseDropdown()
    if not b.menu then
      -- Popup belongs to the window, outside the clipped ScrollFrame.
      local popupParent=KHQOL.PositionEditor and KHQOL.PositionEditor.active and KHQOL.PositionEditor.toolbar or KHQOL.settings or UIParent
      local menu = CreateFrame("Frame", nil, popupParent, "BackdropTemplate")
      menu:SetPoint("TOPLEFT", b, "BOTTOMLEFT", 0, -2)
      menu:SetFrameStrata("FULLSCREEN_DIALOG"); menu:SetClampedToScreen(true); menu:EnableMouse(true)
      UI:Surface(menu)
      menu:SetBackdropColor(.04,.04,.04,.98); b.menu = menu; b.rows = {}
      local viewport=CreateFrame("ScrollFrame",nil,menu)
      viewport:SetPoint("TOPLEFT",4,-4)
      local list=CreateFrame("Frame",nil,viewport); viewport:SetScrollChild(list)
      b.menuViewport=viewport; b.menuList=list
      viewport:EnableMouseWheel(true)
      viewport:SetScript("OnMouseWheel",function(_,delta)
        local maximum=math.max(0,list:GetHeight()-viewport:GetHeight())
        viewport:SetVerticalScroll(math.max(0,math.min(maximum,viewport:GetVerticalScroll()-delta*(T.ControlHeight+2))))
      end)
      menu:Hide()
    end
    b:Refresh(); b.menuViewport:SetVerticalScroll(0); b.menu:Show(); UI.openDropdown = b.menu
  end, enabled)
  b.Refresh = function()
    if optionSource then options=optionSource() end
    local value = getter(); local selected = "선택"
    local menuWidth=100
    for i, option in ipairs(options) do
      if option.value == value then selected = option.text end
      b:GetFontString():SetText(option.text)
      menuWidth=math.max(menuWidth,math.ceil(b:GetFontString():GetStringWidth())+(option.icon and 70 or 48))
      if b.rows then
        local row=b.rows[i]
        if not row then
          row=CreateFrame("Button",nil,b.menuList,"BackdropTemplate"); UI:SkinButton(row)
          row:SetPoint("TOPLEFT",0,-(i-1)*(T.ControlHeight+2))
          row.radio=UI:CreateLabel(row,"○",6,-5); row.radio:SetWidth(18)
          row.icon=row:CreateTexture(nil,"ARTWORK"); row.icon:SetSize(16,16); row.icon:SetPoint("LEFT",28,0)
          row.text=UI:CreateLabel(row,"",28,-5)
          row:SetScript("OnClick",function()
            if not row.option or unavailable(row.option) then return end
            setter(row.option.value); UI:CloseDropdown(); UI:Changed(parent)
          end)
          b.rows[i]=row
        end
        row.option=option; row.text:SetText(option.text); row:Show()
        row.icon:SetShown(option.icon~=nil); if option.icon then row.icon:SetTexture(option.icon) end
        row.text:ClearAllPoints(); row.text:SetPoint("TOPLEFT",option.icon and 50 or 28,-5)
        row:SetEnabled(not unavailable(option)); row:EnableMouse(not unavailable(option))
        row:SetAlpha(unavailable(option) and T.DisabledAlpha or 1)
        UI:SetButtonSelected(row,option.value==value)
        row.radio:SetText(option.value==value and "●" or "○")
        row.radio:SetTextColor(unpack(option.value==value and T.FocusAccent or T.TextSecondary))
      end
    end
    if b.rows then
      for i,row in ipairs(b.rows) do
        row:SetSize(menuWidth-8,T.ControlHeight); row.text:SetWidth(menuWidth-(row.option and row.option.icon and 62 or 40))
        if i>#options then row.option=nil; row:Hide() end
      end
      local contentHeight=#options*(T.ControlHeight+2)
      local visibleHeight=math.min(contentHeight,336,math.max(84,UIParent:GetHeight()-80))
      b.menuViewport:SetSize(menuWidth-8,visibleHeight); b.menuList:SetSize(menuWidth-8,contentHeight)
      b.menu:SetSize(menuWidth,visibleHeight+8)
      b.menuViewport:SetVerticalScroll(math.min(b.menuViewport:GetVerticalScroll(),math.max(0,contentHeight-visibleHeight)))
    end
    b:SetText(selected .. "  ▼")
    b:SetWidth(width)
    UI:ApplyAvailability(b, enabled)
  end
  b:Refresh(); return b
end
function UI:OpenColorPicker(getter, setter, refresh, captureRestore, supportsOpacity)
  local picker = ColorPickerFrame; if not picker or not picker.GetColorRGB then return end
  local r, g, b, a = getter(); a = a or 1
  local restore = captureRestore and captureRestore(); local initializing = true
  local generation=KHQOL.profileGeneration
  local function apply()
    if initializing or generation~=KHQOL.profileGeneration then return end
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
    if generation~=KHQOL.profileGeneration then return end
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
  titleLabel:SetWidth((T.ContentWidth-T.ColumnGap)/2)
  b:SetWidth(math.ceil(b:GetFontString():GetStringWidth())+48)
  b:GetFontString():ClearAllPoints(); b:GetFontString():SetPoint("LEFT", 32, 0); b:GetFontString():SetPoint("RIGHT", -8, 0)
  b.Refresh = function()
    local r,g,bl = getter(); b.swatch:SetColorTexture(r,g,bl,1); UI:ApplyAvailability(b, enabled, {titleLabel})
  end
  b:Refresh(); return b
end
function UI:CreateEditBox(parent, x, y, width, getter, setter, enabled)
  local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate,BackdropTemplate")
  box:SetSize(width or T.DropdownWidth, T.EditBoxHeight); box:SetPoint("TOPLEFT", x, y)
  for _,region in ipairs({box:GetRegions()}) do if region:GetObjectType()=="Texture" then region:SetAlpha(0) end end
  UI:Surface(box)
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
    UI:CellBackground(parent,x,self.rowY,width,height)
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
    local x,y=self:Cell("field",2,T.ColorRowHeight)
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
