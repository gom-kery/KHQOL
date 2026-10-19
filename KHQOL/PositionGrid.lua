local _, K = ...
local UI=K.UI
local G={lines={}}
K.PositionGrid=G
local MIN,MAX,STEP,DEFAULT=8,128,4,32
local function preferences() return UI.SettingsNavigation:Preferences() end
function G:Enabled() return preferences().editorGrid~=false end
function G:Spacing()
  local value=preferences().editorGridSpacing
  if not K.PositionStore:Number(value) then return DEFAULT end
  return math.max(MIN,math.min(MAX,MIN+math.floor((value-MIN)/STEP+.5)*STEP))
end
function G:Hide()
  if self.frame then self.frame:Hide() end
end
function G:Refresh()
  local cx,cy,w,h,scale=K.PositionStore:Screen()
  if not K.PositionEditor.active or not self:Enabled() or not cx then self:Hide();return end
  if not self.frame then
    local f=CreateFrame("Frame","KHQOLPositionEditorGrid",UIParent)
    f:SetAllPoints(UIParent);f:SetFrameStrata("FULLSCREEN_DIALOG");f:SetFrameLevel(50)
    f:EnableMouse(false);f:EnableMouseWheel(false)
    self.frame=f
  end
  local spacing=self:Spacing();local key=table.concat({w,h,scale,spacing},":")
  if self.renderKey~=key then
    local used=0;local pixel=1/scale
    local function line(vertical,offset,axis)
      used=used+1
      local t=self.lines[used] or self.frame:CreateTexture(nil,"ARTWORK");self.lines[used]=t
      t:ClearAllPoints();t:SetPoint("CENTER",self.frame,"CENTER",vertical and offset or 0,vertical and 0 or offset)
      local thickness=pixel*(axis and 2 or 1)
      t:SetSize(vertical and thickness or w,vertical and h or thickness)
      if axis then t:SetColorTexture(UI.Theme.FocusAccent[1],UI.Theme.FocusAccent[2],UI.Theme.FocusAccent[3],.5)
      else t:SetColorTexture(.5,.7,.72,.2) end
      t:Show()
    end
    line(true,0,true);line(false,0,true)
    for i=1,math.floor(w/(2*spacing)) do line(true,i*spacing);line(true,-i*spacing) end
    for i=1,math.floor(h/(2*spacing)) do line(false,i*spacing);line(false,-i*spacing) end
    for i=used+1,#self.lines do self.lines[i]:Hide() end
    self.lineCount=used;self.renderKey=key
  end
  self.frame:Show()
end
function G:RefreshControls()
  local e=K.PositionEditor
  if e.gridToggle then e.gridToggle:Refresh();e.gridSlider:Refresh() end
end
function G:SetEnabled(on)
  if not K.PositionEditor.active then return end
  preferences().editorGrid=on and true or false
  self:Refresh();self:RefreshControls()
end
function G:SetSpacing(value)
  if not K.PositionEditor.active or not K.PositionStore:Number(value) then return end
  preferences().editorGridSpacing=math.max(MIN,math.min(MAX,MIN+math.floor((value-MIN)/STEP+.5)*STEP))
  self:Refresh();self:RefreshControls()
end
function G:CreateControls(e,f)
  -- View preferences bypass profile commits and never write the position draft.
  local toggle=UI:CreateCheckbox(f,"격자 표시",84,-406,function() return G:Enabled() end,function(on) G:SetEnabled(on) end)
  toggle.text:SetWidth(160)
  toggle:SetScript("OnClick",function(self) G:SetEnabled(self:GetChecked()) end)
  function toggle:ToggleFromLabel() G:SetEnabled(not G:Enabled()) end
  UI:AttachTooltip(toggle,"격자 표시","화면 중앙을 기준으로 위치를 맞출 격자를 표시합니다. 다음 편집에서도 선택을 유지합니다.")
  e.gridToggle=toggle
  local title=UI:CreateLabel(f,"격자 간격",300,-390)
  local value=UI:CreateLabel(f,"",460,-390);value:SetWidth(112);value:SetJustifyH("RIGHT")
  local low=UI:CreateLabel(f,"좁게",290,-416);low:SetWidth(40)
  local high=UI:CreateLabel(f,"넓게",535,-416);high:SetWidth(40)
  local slider=CreateFrame("Slider",nil,f);slider:SetPoint("TOPLEFT",335,-410);slider:SetSize(190,24)
  slider:SetOrientation("HORIZONTAL");slider:SetMinMaxValues(MIN,MAX);slider:SetValueStep(STEP)
  if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
  local track=slider:CreateTexture(nil,"BACKGROUND");track:SetPoint("LEFT");track:SetPoint("RIGHT");track:SetHeight(4);track:SetColorTexture(unpack(UI.Theme.SliderTrack))
  local thumb=slider:CreateTexture(nil,"OVERLAY");thumb:SetSize(10,16);thumb:SetColorTexture(unpack(UI.Theme.FocusAccent));slider:SetThumbTexture(thumb)
  slider.Refresh=function()
    slider.setting=true;slider:SetValue(G:Spacing());slider.setting=false
    value:SetText(G:Spacing().." UI px")
    UI:ApplyAvailability(slider,function() return e.active and G:Enabled() end,{title,value,low,high})
  end
  slider:SetScript("OnValueChanged",function(_,v)
    if not slider.setting and e.active and G:Enabled() then G:SetSpacing(v) end
  end)
  UI:AttachTooltip(slider,"격자 간격","8~128 UI px · 4 UI px 단위. 왼쪽은 좁게, 오른쪽은 넓게 표시합니다.")
  UI:RegisterControl(f,slider);slider:Refresh();e.gridSlider=slider
end
