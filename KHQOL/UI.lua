local _, KHQOL = ...
KHQOL.UI = KHQOL.UI or {}
local UI = KHQOL.UI

-- Settings-only theme. Gameplay frames keep their own fonts, sizes and colors.
UI.Theme = {
  WindowWidth = 900, WindowHeight = 700, WindowPadding = 18,
  SidebarWidth = 200, ContentPadding = 20, ContentWidth = 640,
  HeaderGap = 20, SectionGap = 14, RowGap = 8, RowHeight = 28,
  ControlHeight = 26, ButtonHeight = 26, DropdownHeight = 26, EditBoxHeight = 26,
  CheckboxSize = 26, CheckboxLabelGap = 8, SliderWidth = 110, DropdownWidth = 280, DropdownMinWidth = 140,
  SliderRowHeight = 60, DropdownRowHeight = 60, ColorRowHeight = 60,
  ColumnGap = 20,
  TitleFontSize = 22, PageTitleSize = 18, StatusFontSize = 12, StateFontSize = 10,
  FormMaxWidth = 880, FieldColumnMin = 310, FieldTwoColumnWidth = 640, CheckTwoColumnWidth = 540,
  SectionFontSize = 14, LabelFontSize = 13, DescriptionFontSize = 12,
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
  SliderTrack = { .30, .30, .30, 1 }, CellFill = { .35, .35, .35, 0 },
  CellLine = { .35, .35, .35, 0 },
}
local T = UI.Theme
-- Register only parents/controls created by KHQOL. Never enumerate UIParent:
-- standalone spellbook buttons live there alongside forbidden Blizzard dialogs.
UI.refreshParents=setmetatable({}, {__mode="k"})
local function refreshSafe(frame)
  if not frame or frame==UIParent then return false end
  if frame.IsForbidden then
    local status,forbidden=KHQOL.ReadPublicAPI(frame.IsForbidden,frame)
    if status~="ok" or forbidden~=false then return false end
  end
  return true
end
function UI:RegisterRefreshParent(parent)
  if refreshSafe(parent) and not self.refreshParents[parent] then
    self.refreshParents[parent]=true
    self.refreshVersion=(self.refreshVersion or 0)+1
    if type(parent.SetParent)=="function" then
      local previous=KHQOL.PublicCall(parent.GetParent,parent)
      hooksecurefunc(parent,"SetParent",function(_,nextParent)
        if previous~=nextParent then previous=nextParent;UI.refreshVersion=(UI.refreshVersion or 0)+1 end
      end)
    end
  end
end
function UI:RefreshParentsFor(parent)
  self.refreshCache=self.refreshCache or setmetatable({}, {__mode="k"})
  local cached=self.refreshCache[parent]
  if cached and cached.version==self.refreshVersion then return cached.parents end
  local parents={}
  for candidate in pairs(self.refreshParents) do
    local current=candidate
    for depth=1,64 do
      if not refreshSafe(current) then break end
      if current==parent then parents[#parents+1]={frame=candidate,depth=depth};break end
      local status,nextParent=KHQOL.ReadPublicAPI(current.GetParent,current)
      if status~="ok" or nextParent==current then break end
      current=nextParent
    end
  end
  table.sort(parents,function(a,b) return a.depth<b.depth end)
  self.refreshCache[parent]={version=self.refreshVersion,parents=parents}
  return parents
end
function UI:Font() return KHQOL.FONT_PATH or STANDARD_TEXT_FONT end
function UI:RegisterCaption(parent, region, size)
  self:RegisterRefreshParent(parent)
  parent.uiCaptions=parent.uiCaptions or {}
  local caption={region=region,text=region:GetText() or "",size=size}
  table.insert(parent.uiCaptions,caption)
  -- Keep dynamic row names/descriptions, including intentional empty text.
  hooksecurefunc(region,"SetText",function(_,text) caption.text=text or "" end)
end
function UI:CreateLabel(parent, text, x, y, size)
  local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  fs:SetPoint("TOPLEFT", x or 0, y or 0); fs:SetFont(self:Font(), size or T.LabelFontSize, "")
  fs:SetTextColor(unpack(T.TextPrimary)); fs:SetJustifyH("LEFT"); fs:SetWordWrap(true); fs:SetText(text or "")
  fs:SetWidth(math.max(40, (parent:GetWidth() > 0 and parent:GetWidth() or T.ContentWidth) - (x or 0)))
  self:RegisterCaption(parent,fs,size or T.LabelFontSize)
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
  fs:SetTextColor(unpack(T.TextPrimary))
  return y - 36
end
function UI:LayoutPageIntro(parent)
  local intro=parent.khqolPageIntro;if not intro then return -34 end
  local width=parent:GetWidth()>0 and parent:GetWidth() or T.ContentWidth
  intro.description:SetWidth(math.max(80,width-(intro.toggle and 124 or 0)))
  local height=math.max(34,intro.description:GetStringHeight()+14)
  intro.divider:ClearAllPoints();intro.divider:SetPoint("TOPLEFT",0,-height);intro.divider:SetWidth(width)
  if intro.toggle then intro.toggle:ClearAllPoints();intro.toggle:SetPoint("TOPLEFT",width-108,0) end
  return -height
end
function UI:CreatePage(parent,title,description,getter,setter)
  local intro={description=self:CreateDescription(parent,description,0,-6)}
  parent.khqolPageIntro=intro
  if getter and setter then
    intro.toggle=self:CreateCheckbox(parent,"모듈 사용",0,0,getter,setter)
    intro.toggle.text:SetWidth(76);intro.toggle.ignoreModuleEnabled=true;intro.toggle:Refresh()
  end
  intro.divider=self:CreateDivider(parent,-34)
  return self:LayoutPageIntro(parent),intro.toggle
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
  self:RegisterRefreshParent(button)
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
  local protected=control
  while protected do
    if (protected.labProtected or protected.moduleKey and KHQOL.LabLock:IsExperimental(protected.moduleKey)) and not KHQOL.LabLock:IsUnlocked() then return false end
    protected=protected:GetParent()
  end
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
  if control.text then control:SetAlpha(1);control.text:SetAlpha(1);if control.state then control.state:SetAlpha(enabled and 1 or T.DisabledAlpha) end end
  if control.khqolSkinned then self:UpdateButtonSkin(control) end
  if control.disabledHint then control.disabledHint:SetShown(not enabled) end
  for _, fs in ipairs(labels or {}) do fs:SetAlpha(1) end
  for _, fs in ipairs(control.uiLabels or {}) do fs:SetAlpha(1) end
  if not enabled and control.menu then control.menu:Hide() end
  return enabled
end
function UI:RegisterControl(parent, control)
  -- UIParent is a shared native root, not a KHQOL settings container.
  if parent==UIParent then parent=control end
  self:RegisterRefreshParent(parent)
  parent.uiControls = parent.uiControls or {}; table.insert(parent.uiControls, control)
  local hint=CreateFrame("Frame",nil,control); hint:SetAllPoints(control); hint:EnableMouse(true); hint:Hide()
  hint:SetScript("OnEnter",function(self)
    GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText("사용할 수 없는 설정",unpack(T.Accent))
    local p=control; local disabledModule=false; local labLocked=false
    while p do
      if (p.labProtected or p.moduleKey and KHQOL.LabLock:IsExperimental(p.moduleKey)) and not KHQOL.LabLock:IsUnlocked() then labLocked=true end
      if p.moduleKey and not KHQOL:GetEnabled(p.moduleKey) then disabledModule=true end
      p=p:GetParent()
    end
    GameTooltip:AddLine(labLocked and "실험실에서 접근 잠금을 먼저 해제하세요." or disabledModule and "상단의 모듈 사용을 먼저 켜세요." or "연결된 기능을 켜거나 해당 표시 모드를 선택하면 변경할 수 있습니다.",T.TextSecondary[1],T.TextSecondary[2],T.TextSecondary[3],true); GameTooltip:Show()
  end)
  hint:SetScript("OnLeave",function() GameTooltip:Hide() end); control.disabledHint=hint
  return control
end
function UI:Refresh(parent)
  if (self.settingDepth or 0)>0 then return end
  if not refreshSafe(parent) then return end
  local pending=self:RefreshParentsFor(parent)
  for _,item in ipairs(pending) do
    local owned=item.frame
    if refreshSafe(owned) and owned:IsVisible() then
      for _,control in ipairs(owned.uiControls or {}) do if control.layoutRefresh then control:Refresh() end end
    end
  end
  for _,item in ipairs(pending) do if item.frame:IsVisible() then self:RefreshOwned(item.frame) end end
  if self.ReflowSettingsRoot then self:ReflowSettingsRoot(parent) end
end
function UI:RefreshOwned(parent)
  if not self.refreshParents[parent] or not refreshSafe(parent) then return end
  for _, control in ipairs(parent.uiControls or {}) do if control.Refresh and not control.layoutRefresh then control:Refresh() end end
  for _, caption in ipairs(parent.uiCaptions or {}) do
    caption.region:SetFont(self:Font(),caption.size,"")
    caption.region:SetText(caption.text)
    local area=caption.region.khqolTooltipArea
    if area then area:SetSize(math.max(1,math.min(caption.region:GetWidth(),caption.region:GetStringWidth()+4)),math.max(1,caption.region:GetStringHeight())) end
  end
  -- Checkbox state and button text are not registered captions. Reapply their
  -- font/text after the owning frame is visible, alongside ordinary labels.
  if parent:IsVisible() and parent.GetRegions then
    for _,region in ipairs({parent:GetRegions()}) do
      if region:GetObjectType()=="FontString" then
        local font,size,flags=region:GetFont()
        local text=region:GetText()
        if font and size then region:SetFont(font,size,flags or "") end
        if text~=nil then region:SetText(text) end
      end
    end
  end
end
function UI:Changed(parent)
  if (self.settingDepth or 0)>0 then return end
  if KHQOL.profileApplying or KHQOL.profileClosingEditors then return end
  local active=KHQOL.settings and KHQOL.settings.activeContent
  local contained=false;local current=parent
  for _=1,64 do
    if current==active then contained=active~=nil;break end
    if not current or current==UIParent then break end
    current=current:GetParent()
  end
  if not contained then self:Refresh(parent) end
  if active then self:Refresh(active) end
  self:QueueDisplayRefresh(active or parent)
  if KHQOL.SaveCurrentProfile then KHQOL:SaveCurrentProfile() end
end
function UI:QueueDisplayRefresh(parent)
  if not parent or not C_Timer or not C_Timer.After then return end
  self.displayRefreshes=self.displayRefreshes or setmetatable({}, {__mode="k"})
  if self.displayRefreshes[parent] then return end
  local generation=KHQOL.profileGeneration;local ticket={};self.displayRefreshes[parent]=ticket
  C_Timer.After(0,function()
    if UI.displayRefreshes[parent]~=ticket then return end
    UI.displayRefreshes[parent]=nil
    if KHQOL.profileGeneration~=generation or not refreshSafe(parent) or not parent:IsVisible() then return end
    UI:Refresh(parent)
    local settings=KHQOL.settings
    if settings and settings.activeContent==parent and settings.scroll and settings.scroll.UpdateScrollChildRect then
      settings.scroll:UpdateScrollChildRect()
    end
  end)
end
-- A regular setting may invoke its module's own Changed/Save path. Commit
-- the profile and refresh once after that setter, rather than twice per click.
-- Profile commands and explicit action buttons intentionally do not use this.
function UI:CommitSetting(parent,setter,...)
  self.settingDepth=(self.settingDepth or 0)+1
  local ok,reason=pcall(setter,...)
  self.settingDepth=self.settingDepth-1
  if not ok then
    if self.settingDepth==0 then self:Refresh(parent) end
    error(reason,0)
  end
  if self.settingDepth==0 then self:Changed(parent) end
end
function UI:AttachTooltip(control, title, description)
  if not description or description=="" then return end
  if control.tooltipRegion then control:EnableMouse(true) end
  control.tooltipTitle=title
  control.tooltipDescription=control.tooltipDescription and (control.tooltipDescription.."\n"..description) or description
  if control.tooltipAttached then return end
  control.tooltipAttached=true
  local function enter(self)
    GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText(control.tooltipTitle or "설명",unpack(T.Accent))
    if control.tooltipDescription and control.tooltipDescription~="" then GameTooltip:AddLine(control.tooltipDescription,.94,.94,.94,true) end; GameTooltip:Show()
  end
  local function leave() GameTooltip:Hide() end
  control:HookScript("OnEnter",enter); control:HookScript("OnLeave",leave)
  if control.disabledHint then control.disabledHint:HookScript("OnEnter",function()
    GameTooltip:AddLine(control.tooltipDescription,.94,.94,.94,true); GameTooltip:Show()
  end); control.disabledHint:HookScript("OnLeave",leave) end
  local regions={control.tooltipLabel or control.text}
  for _,label in ipairs(control.uiLabels or {}) do regions[#regions+1]=label end
  for _,region in ipairs(regions) do
    if type(region)=="table" or type(region)=="userdata" then
      if region.GetObjectType and region:GetObjectType()=="FontString" then
        local area=CreateFrame("Frame",nil,region:GetParent());area:SetPoint("TOPLEFT",region,"TOPLEFT",0,0)
        area:SetSize(math.max(1,math.min(region:GetWidth(),region:GetStringWidth()+4)),math.max(1,region:GetStringHeight()))
        area:EnableMouse(true)
        region.khqolTooltipArea=area
        area:SetScript("OnEnter",enter); area:SetScript("OnLeave",leave)
        if control.ToggleFromLabel then
          area:SetScript("OnMouseDown",function(_,button) area.labelPressed=button=="LeftButton" end)
          area:SetScript("OnMouseUp",function(_,button)
            local pressed=area.labelPressed;area.labelPressed=nil
            if pressed and button=="LeftButton" then control:ToggleFromLabel() end
          end)
        end
      end
    end
  end
end
function UI:GridColumns(parent,items,shortcut)
  parent.gridMeasure=parent.gridMeasure or parent:CreateFontString(nil,"OVERLAY")
  local measure=parent.gridMeasure; measure:SetFont(self:Font(),T.LabelFontSize,"")
  local required=0
  for _,item in ipairs(items) do
    local hasShortcut=type(shortcut)=="function" and shortcut(item) or shortcut==true
    measure:SetText(item.title or item[2] or item[1]); required=math.max(required,measure:GetStringWidth()+T.CheckboxSize+T.CheckboxLabelGap+(hasShortcut and T.ButtonHeight+T.RowGap or 0))
  end
  measure:Hide()
  local width=parent:GetWidth()
  return (width-2*T.ColumnGap)/3>=required and 3 or 2
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
  b.state=b:CreateFontString(nil,"OVERLAY"); b.state:SetPoint("CENTER"); b.state:SetFont(UI:Font(),T.StateFontSize,"")
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
    if UI:IsAvailable(b, enabled) then UI:CommitSetting(parent,setter,b:GetChecked() and true or false) end
  end)
  function b:ToggleFromLabel()
    if UI:IsAvailable(b,enabled) then UI:CommitSetting(parent,setter,not getter()) end
  end
  self:RegisterControl(parent, b); b:Refresh(); return b
end
function UI:CreateButton(parent, text, x, y, width, click, enabled)
  local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
  b:SetSize(width or 150, T.ButtonHeight); b:SetPoint("TOPLEFT", x, y)
  self:SkinButton(b); b:SetText(text)
  hooksecurefunc(b,"SetText",function(_,value) text=value or "" end)
  -- Explicit widths are caps, not padding; sidebar buttons opt back into a fixed width.
  b:SetWidth(math.min(width or T.ContentWidth, math.ceil(b:GetFontString():GetStringWidth()) + 24))
  b.Refresh = function()
    UI:ApplyAvailability(b, enabled)
    b:SetText(text)
  end
  b:SetScript("OnClick", function(self, mouseButton)
    if UI:IsAvailable(b, enabled) then
      click(self,mouseButton)
      if not self.navigationOnly then UI:Changed(parent==UIParent and b or parent) end
    end
  end)
  self:RegisterControl(parent, b); b:Refresh(); return b
end
local serial = 0
function UI:CreateSlider(parent, title, description, x, y, min, max, step, getter, setter, format, enabled, normalize)
  local titleLabel = self:CreateLabel(parent, title, x, y)
  titleLabel:SetWidth(math.max(40,math.min((T.ContentWidth-T.ColumnGap)/2,parent:GetWidth()-(x or 0))))
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
  local rawFormat=format
  format=function(value)
    if step>=1 and KHQOL.IsPublicNumber(value) then
      value=value<0 and math.ceil(value-.5) or math.floor(value+.5)
    end
    return rawFormat(value)
  end
  local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate,BackdropTemplate")
  box:SetPoint("TOPLEFT", x + T.SliderWidth + 14, y - 20); box:SetSize(86, T.EditBoxHeight)
  for _,region in ipairs({box:GetRegions()}) do if region:GetObjectType()=="Texture" then region:SetAlpha(0) end end
  UI:Surface(box)
  box:HookScript("OnEditFocusGained",function() box:SetBackdropBorderColor(unpack(T.FocusAccent)) end)
  box:HookScript("OnEditFocusLost",function() box:SetBackdropBorderColor(unpack(T.Border)) end)
  box:SetAutoFocus(false); box:SetFont(self:Font(), T.LabelFontSize, ""); box:SetTextInsets(6,6,0,0)
  -- Numeric text must not depend on inherited input-template presentation.
  box:SetTextColor(unpack(T.TextPrimary)); box:SetJustifyH("LEFT"); box:SetJustifyV("MIDDLE")
  box:SetText(format(getter()))
  -- Cached EditBox glyphs can disappear after hidden rows are reparented.
  -- Idle values are drawn by an owned FontString; the native editor handles
  -- cursor/selection and typed drafts only while focused.
  local valueLayer=CreateFrame("Frame",nil,box);valueLayer:SetAllPoints(box);valueLayer:EnableMouse(false)
  valueLayer:SetFrameLevel(box:GetFrameLevel()+2)
  local valueText=valueLayer:CreateFontString(nil,"OVERLAY",nil,7)
  valueText:SetPoint("LEFT",box,"LEFT",6,0);valueText:SetPoint("RIGHT",box,"RIGHT",-6,0)
  valueText:SetFont(UI:Font(),T.LabelFontSize,"");valueText:SetTextColor(unpack(T.TextPrimary));valueText:SetJustifyH("LEFT");valueText:SetJustifyV("MIDDLE")
  box.valueText=valueText;box.valueLayer=valueLayer
  local function paintValue()
    local focused=box:HasFocus()
    valueLayer:SetFrameLevel(box:GetFrameLevel()+2)
    valueText:SetText(box:GetText());valueLayer:SetShown(not focused)
    box:SetTextColor(T.TextPrimary[1],T.TextPrimary[2],T.TextPrimary[3],focused and 1 or 0)
  end
  slider.numberBox = box
  local function rounded(value)
    if normalize then return normalize(value) end
    return math.max(min, math.min(max, min + math.floor((value-min)/step+.5)*step))
  end
  local feedback=self:CreateDescription(parent,"",x,y-52)
  feedback.khqolInputFeedback=true;feedback:Hide();slider.inputFeedback=feedback
  local function report(message,invalid)
    feedback:SetText(message or "");feedback:SetShown(message~=nil)
    feedback:SetTextColor(unpack(invalid and T.Warning or T.TextSecondary))
    UI:ReflowInputFeedback(parent)
  end
  local function commit()
    if not UI:IsAvailable(slider, enabled) then box:SetText(format(getter())); return end
    local raw = box:GetText():match("^%s*(.-)%s*$")
    local numeric = raw:gsub("%%", ""):gsub("px", ""):gsub("초", "")
    local value = tonumber(numeric)
    if raw == "기본" and min <= 0 and max >= 0 and format(0) == "기본" then value = 0 end
    if KHQOL.IsPublicNumber(value) then
      -- Fractional opacity controls display percentages; other ranges retain their units.
      if tostring(format(getter())):find("%",1,true) and tostring(format(1)):match("^100%%$") then value=value/100 end
      local normalized=rounded(value)
      UI:CommitSetting(parent,setter,normalized); slider:Refresh()
      if math.abs(normalized-value)>.0000001 then
        report("범위·간격에 맞춤: "..format(getter()),false)
      else report(nil) end
    else
      -- Some existing display formats include units the original parser does
      -- not accept (for example degrees). Merely leaving that unchanged
      -- display must not produce a new error; parsing/setter rules stay intact.
      if raw==tostring(format(getter())) then report(nil)
      else report("숫자를 입력하세요 · 기존 값 유지: "..format(getter()),true) end
    end
    box:SetText(format(getter()))
  end
  UI:BindInput(box,parent,function() box:SetText(format(getter())) end,commit)
  box:HookScript("OnEditFocusGained",function() report(nil) end)
  box:HookScript("OnTextChanged",paintValue)
  box:HookScript("OnEditFocusGained",paintValue);box:HookScript("OnEditFocusLost",paintValue)
  slider.Refresh = function()
    slider.setting = true; slider:SetValue(getter()); slider.setting = false
    -- A cached row can be shown at a different ScrollFrame position. Reset the
    -- EditBox font after that layout so its numeric glyphs are rebuilt too.
    box:SetFont(UI:Font(),T.LabelFontSize,"");valueText:SetFont(UI:Font(),T.LabelFontSize,"")
    box:SetJustifyH("LEFT");box:SetJustifyV("MIDDLE")
    if not box:HasFocus() then box:SetText(format(getter())) end
    paintValue()
    UI:ApplyAvailability(slider, enabled, {titleLabel}); UI:ApplyAvailability(box, enabled)
  end
  slider:SetScript("OnValueChanged", function(_, value)
    if slider.setting or not UI:IsAvailable(slider, enabled) then return end
    UI:CommitSetting(parent,setter,rounded(value)); box:SetText(format(getter()))
  end)
  slider.tooltipLabel=titleLabel
  self:AttachTooltip(slider, title, description)
  self:AttachTooltip(box, title, description)
  self:AttachTooltip(box, title, "범위: "..format(min).." ~ "..format(max).." · 간격: "..tostring(step)..". Enter·포커스 이동으로 적용, ESC로 취소합니다.")
  -- Nested settings panels may first appear after their controls were created.
  -- Refresh on visibility changes too, while retaining a focused user draft.
  box:HookScript("OnShow", function() slider:Refresh() end)
  self:RegisterControl(parent, slider); slider:Refresh(); return slider,box
end
-- Measure without a previous field width or wrapping affecting the next fit.
function UI:MeasureButtonText(button,text)
  local measure=button.khqolWidthMeasure
  if not measure then
    measure=button:CreateFontString(nil,"OVERLAY");measure:SetWordWrap(false);measure:Hide()
    button.khqolWidthMeasure=measure
  end
  measure:SetFont(button:GetFontString():GetFont());measure:SetText(text or "")
  return math.ceil(measure:GetStringWidth())
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
  b.navigationOnly=true -- Opening a list does not change a profile setting.
  b.khqolDropdown=true
  -- layoutWidth remains the available slot; only the visible button is compact.
  function b:FitDropdownWidth(available)
    if available then self.layoutWidth=available end
    local limit=math.max(1,math.min(T.DropdownWidth,self.layoutWidth or width))
    local fitted=math.min(limit,math.max(T.DropdownMinWidth,self.dropdownContentWidth or T.DropdownMinWidth))
    self:SetWidth(fitted)
    local text=self:GetFontString();text:SetWordWrap(true);text:SetWidth(math.max(1,fitted-20))
    self:SetHeight(math.max(T.DropdownHeight,text:GetStringHeight()+10))
  end
  b.Refresh = function()
    if optionSource then options=optionSource() end
    local value = getter(); local selected = "선택"
    local menuWidth=100;local buttonWidth=T.DropdownMinWidth
    local maximumMenuWidth=math.max(120,math.min(680,(KHQOL.settings or UIParent):GetWidth()-40))
    for i, option in ipairs(options) do
      if option.value == value then selected = option.text end
      menuWidth=math.max(menuWidth,UI:MeasureButtonText(b,option.text)+(option.icon and 70 or 48))
      buttonWidth=math.max(buttonWidth,UI:MeasureButtonText(b,option.text.."  ▼")+20)
      if b.rows then
        local row=b.rows[i]
        if not row then
          row=CreateFrame("Button",nil,b.menuList,"BackdropTemplate"); UI:SkinButton(row)
          row:SetPoint("TOPLEFT",0,0)
          row.radio=UI:CreateLabel(row,"○",6,-5); row.radio:SetWidth(18)
          row.icon=row:CreateTexture(nil,"ARTWORK"); row.icon:SetSize(16,16); row.icon:SetPoint("LEFT",28,0)
          row.text=UI:CreateLabel(row,"",28,-5)
          row:SetScript("OnClick",function()
            if not row.option or unavailable(row.option) then return end
            if b.profileCommand then setter(row.option.value);UI:Changed(parent)
            else UI:CommitSetting(parent,setter,row.option.value) end
            UI:CloseDropdown()
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
    menuWidth=math.min(maximumMenuWidth,menuWidth)
    if b.rows then
      for i,row in ipairs(b.rows) do
        row:SetSize(menuWidth-8,T.ControlHeight); row.text:SetWidth(menuWidth-(row.option and row.option.icon and 62 or 40))
        if i>#options then row.option=nil; row:Hide() end
      end
      local contentHeight=0
      for i,row in ipairs(b.rows) do if i<=#options then
        row:ClearAllPoints();row:SetPoint("TOPLEFT",0,-contentHeight)
        row.text:SetWordWrap(true);row:SetHeight(math.max(T.ControlHeight,row.text:GetStringHeight()+10))
        contentHeight=contentHeight+row:GetHeight()+2
      end end
      local visibleHeight=math.min(contentHeight,336,math.max(84,UIParent:GetHeight()-80))
      b.menuViewport:SetSize(menuWidth-8,visibleHeight); b.menuList:SetSize(menuWidth-8,contentHeight)
      b.menu:SetSize(menuWidth,visibleHeight+8)
      b.menuViewport:SetVerticalScroll(math.min(b.menuViewport:GetVerticalScroll(),math.max(0,contentHeight-visibleHeight)))
    end
    b:SetText(selected .. "  ▼")
    b.dropdownContentWidth=buttonWidth;b:FitDropdownWidth()
    UI:ApplyAvailability(b, enabled)
  end
  b:Refresh(); return b
end
function UI:OpenColorPicker(getter, setter, refresh, captureRestore, supportsOpacity)
  local picker = ColorPickerFrame; if not picker or not picker.GetColorRGB then return end
  local r, g, b, a = getter(); a = a or 1
  local restore = captureRestore and captureRestore(); local initializing = true
  UI:CloseColorPicker();UI.ownsColorPicker=true
  local token=UI.colorGeneration
  local generation=KHQOL.profileGeneration
  local function apply()
    if initializing or token~=UI.colorGeneration or generation~=KHQOL.profileGeneration then return end
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
    if token~=UI.colorGeneration or generation~=KHQOL.profileGeneration then return end
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
  b = self:CreateButton(parent, "변경", x, y-24, 150, function()
    UI:OpenColorPicker(getter, setter, function() UI:Changed(parent) end, captureRestore, supportsOpacity)
  end, enabled)
  b.swatch = b:CreateTexture(nil, "OVERLAY"); b.swatch:SetSize(18, 18); b.swatch:SetPoint("LEFT", 8, 0)
  titleLabel:SetWidth((T.ContentWidth-T.ColumnGap)/2)
  b:SetWidth(math.ceil(b:GetFontString():GetStringWidth())+48)
  b.layoutPreferredWidth=b:GetWidth();b:GetFontString():SetWordWrap(false)
  b.navigationOnly=true -- Only picker callbacks commit a selected color.
  b:GetFontString():ClearAllPoints(); b:GetFontString():SetPoint("LEFT", 32, 0); b:GetFontString():SetPoint("RIGHT", -8, 0)
  b.Refresh = function()
    local r,g,bl = getter(); b.swatch:SetColorTexture(r,g,bl,1); UI:ApplyAvailability(b, enabled, {titleLabel})
  end
  b:Refresh(); return b
end
function UI:RegisterDraft(parent,cancel)
  self.draftEditors=self.draftEditors or setmetatable({}, {__mode="k"})
  self.draftEditors[parent]=cancel
end
function UI:CancelDrafts()
  for _,cancel in pairs(self.draftEditors or {}) do cancel() end
end
function UI:CloseColorPicker()
  self.colorGeneration=(self.colorGeneration or 0)+1
  if self.ownsColorPicker and ColorPickerFrame then ColorPickerFrame:Hide() end
  self.ownsColorPicker=nil
end
function UI:CancelInputs(parent)
  for box in pairs(self.editInputs or {}) do
    local ancestor=box; local included=not parent
    for _=1,64 do
      if ancestor==parent then included=true; break end
      if not ancestor or ancestor==UIParent then break end
      ancestor=ancestor:GetParent()
    end
    if included and box.CancelEdit then box:CancelEdit() end
  end
end
function UI:BindInput(box,parent,restore,commit)
  self.editInputs=self.editInputs or setmetatable({}, {__mode="k"})
  self.editInputs[box]=true
  function box:CancelEdit()
    self.cancelFocus=true; self:ClearFocus(); restore(); self.cancelFocus=nil
  end
  box:SetScript("OnEditFocusGained",function(self)
    self.editGeneration=KHQOL.profileGeneration; self:HighlightText()
  end)
  local function apply()
    if box.cancelFocus then return end
    if box.editGeneration~=nil and box.editGeneration~=KHQOL.profileGeneration then restore();return end
    commit(); restore()
  end
  box:SetScript("OnEnterPressed",function(self) apply(); self.cancelFocus=true;self:ClearFocus();self.cancelFocus=nil end)
  box:SetScript("OnEscapePressed",function(self) self:CancelEdit() end)
  box:SetScript("OnEditFocusLost",apply)
  box:HookScript("OnHide",function(self) self:CancelEdit() end)
  UI:AttachTooltip(box,"입력 확정","Enter 또는 다른 항목 클릭: 적용. ESC·창 닫기·프로필 전환: 미확정 입력 취소.")
  if box.SetBackdropBorderColor then
    box:HookScript("OnEditFocusGained",function() box:SetBackdropBorderColor(unpack(T.FocusAccent)) end)
    box:HookScript("OnEditFocusLost",function() box:SetBackdropBorderColor(unpack(T.Border)) end)
  end
end
function UI:CreateEditBox(parent, x, y, width, getter, setter, enabled)
  local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate,BackdropTemplate")
  box:SetSize(width or T.DropdownWidth, T.EditBoxHeight); box:SetPoint("TOPLEFT", x, y)
  for _,region in ipairs({box:GetRegions()}) do if region:GetObjectType()=="Texture" then region:SetAlpha(0) end end
  UI:Surface(box)
  box:HookScript("OnEditFocusGained",function() box:SetBackdropBorderColor(unpack(T.FocusAccent)) end)
  box:HookScript("OnEditFocusLost",function() box:SetBackdropBorderColor(unpack(T.Border)) end)
  box:SetAutoFocus(false); box:SetFont(self:Font(), T.LabelFontSize, ""); box:SetTextInsets(8,8,0,0)
  box:SetTextColor(unpack(T.TextPrimary))
  local function restore() if getter then box:SetText(tostring(getter() or "")) end end
  if getter and setter then
    UI:BindInput(box,parent,restore,function()
      if UI:IsAvailable(box,enabled) then UI:CommitSetting(parent,setter,box:GetText()) end
    end)
  else
    -- Explicit lookup/registration fields have their own apply action.
    if getter then
      self.editInputs=self.editInputs or setmetatable({}, {__mode="k"});self.editInputs[box]=true
      function box:CancelEdit() self:ClearFocus();restore() end
      box:HookScript("OnHide",function(self) self:CancelEdit() end)
    end
    box:SetScript("OnEscapePressed",function(self) if self.CancelEdit then self:CancelEdit() else self:ClearFocus();restore() end end)
    box:SetScript("OnEnterPressed",function(self) if setter then setter(self:GetText()) end;self:ClearFocus() end)
  end
  box.Refresh = function()
    if not box:HasFocus() then restore() end
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
  self:RegisterRefreshParent(parent)
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
  function builder:Section(title)
    self:Flush(); self.y=UI:CreateSection(parent,title,self.y)
    local hint=CreateFrame("Frame",nil,parent); hint:SetPoint("TOPLEFT",0,self.y+36); hint:SetSize(parent:GetWidth(),24); hint:EnableMouse(false);hint.tooltipRegion=true
    self.lastControl,self.lastTitle=hint,title
    local root=parent
    while root and root~=UIParent and not root.settingsModuleKey do root=root:GetParent() end
    local key=root and root.settingsModuleKey
    if key and title:find("위치",1,true) and not root.positionShortcut and UI.SettingsRegistry.positionModules[key] then
      root.positionShortcut=true
      local button=self:Button("통합 위치 편집",function() KHQOL.PositionEditor:Enter(key,"group") end)
      button.navigationOnly=true
      self:Flush()
    end
  end
  function builder:Checkbox(title,getter,setter,enabled)
    local x,y,width=self:Cell("check",2,T.RowHeight+T.RowGap)
    local control=UI:CreateCheckbox(parent,title,x,y,getter,setter,enabled)
    control.text:SetWidth(width-T.CheckboxSize-T.CheckboxLabelGap); self.lastControl,self.lastTitle=control,title; return control
  end
  function builder:Slider(title,min,max,step,getter,setter,format,enabled,description,normalize)
    local x,y=self:Cell("field",2,T.SliderRowHeight)
    local control,box=UI:CreateSlider(parent,title,description or "",x,y,min,max,step,getter,setter,format,enabled,normalize)
    self.lastControl,self.lastTitle=control,title; return control,box
  end
  function builder:Dropdown(title,options,getter,setter,enabled)
    if self.rowKind=="color" and self.rowCount==1 and self.y==self.rowBottom then self.rowKind="field" end
    local x,y,width=self:Cell("field",2,T.DropdownRowHeight)
    local label=UI:CreateLabel(parent,title,x,y); label:SetWidth(width)
    local control=UI:CreateDropdown(parent,x,y-24,width,options,getter,setter,enabled)
    control.uiLabels={label}; control:Refresh(); self.lastControl,self.lastTitle=control,title; return control
  end
  function builder:Edit(title,getter,setter,enabled)
    local x,y,width=self:Cell("field",2,T.DropdownRowHeight)
    local label=UI:CreateLabel(parent,title,x,y); label:SetWidth(width)
    local control=UI:CreateEditBox(parent,x,y-24,width,getter,setter,enabled)
    control.uiLabels={label}; control:Refresh(); self.lastControl,self.lastTitle=control,title; return control
  end
  function builder:Color(title,getter,setter,enabled,restore,alpha)
    local x,y=self:Cell("field",2,T.ColorRowHeight)
    local control=UI:CreateColorPicker(parent,title,x,y,getter,setter,enabled,restore,alpha)
    self.lastControl,self.lastTitle=control,title; return control
  end
  function builder:Button(title,callback,width,enabled)
    local x,y,cellWidth=self:Cell("button",2,T.RowHeight+T.RowGap)
    local control=UI:CreateButton(parent,title,x,y,math.min(width or cellWidth,cellWidth),callback,enabled)
    self.lastControl,self.lastTitle=control,title; return control
  end
  function builder:Description(text,important)
    if not important and self.lastControl then UI:AttachTooltip(self.lastControl,self.lastTitle,text); return self.lastControl end
    self:Flush()
    local fs=UI:CreateDescription(parent,text,0,self.y); self.y=self.y-math.max(18,fs:GetStringHeight())-T.RowGap; return fs
  end
  return builder
end

-- Settings-only helpers. No persistent storage or gameplay callbacks.
function UI:ReflowInputFeedback(parent)
  if parent.uiBuilders and not parent.buildersReflowing then parent.uiBuilders[1]:Reflow() end
  local s=KHQOL.settings
  if s and s.activeContent then self:RefreshLayoutOnly(s.activeContent);s:UpdateContentHeight() end
end
local function sameRecord(a,b)
  if type(a)~=type(b) then return false end
  if type(a)~="table" then return a==b end
  for k,v in pairs(a) do if not sameRecord(v,b[k]) then return false end end
  for k in pairs(b) do if a[k]==nil then return false end end
  return true
end
StaticPopupDialogs.KHQOL_DELETE_SHARED_RECORD={
  text="%s\n\n계정 공용 등록 항목을 삭제합니다. 다른 캐릭터·전체 프로필에서도 이 항목을 사용하지 못합니다. 표시·모양 설정은 유지합니다.",
  button1="삭제",button2=CANCEL,timeout=0,whileDead=1,hideOnEscape=1,
  OnAccept=function(_,data)
    if not UI:IsCurrentConfirmation(data) then return end
    if not data.available() or data.resolve()~=data.record or not sameRecord(data.snapshot,data.record) then
      KHQOL:ProfileMessage("대상이나 편집 상태가 변경되었습니다. 목록에서 삭제 대상을 다시 확인하세요.");return
    end
    data.remove()
  end,
}
function UI:ConfirmRecordDeletion(name,resolve,remove,available)
  local record=resolve();if not record then return end
  local safeName=tostring(name or "이름 확인 불가"):gsub("|","||"):gsub("[%c]"," ")
  StaticPopup_Show("KHQOL_DELETE_SHARED_RECORD",safeName,nil,self:Confirmation({
    record=record,snapshot=KHQOL.CopyProfileValue(record),resolve=resolve,remove=remove,available=available,
  }))
end
