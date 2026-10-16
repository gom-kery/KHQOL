local _, KHQOL = ...
local CastBar=KHQOL.modules.castBar
local positionLabels={inside_left="바 내부 - 왼쪽",inside_center="바 내부 - 중앙",inside_right="바 내부 - 오른쪽",outside_left="바 외부 - 왼쪽",outside_center="바 외부 - 중앙",outside_right="바 외부 - 오른쪽"}
function CastBar:BuildPlayerSettings(content,y)
  local UI,db=KHQOL.UI,self:GetDB()
  local b=UI:CreateBuilder(content,y)
  local controls={}; self.controls=controls
  local function add(control) controls[#controls+1]=control; return control end
  local function enabled() return self:IsEnabled() end
  local function checkbox(title,group,key,kind,available)
    return add(b:Checkbox(title,function() return group[key] end,function(v) group[key]=v; self:Changed(kind) end,available or enabled))
  end
  local function slider(title,group,key,min,max,available)
    return add(b:Slider(title,min,max,1,function() return group[key] end,function(v) group[key]=v; self:Changed() end,function(v) return tostring(math.floor(v+.5)) end,available or enabled))
  end
  local function dropdown(title,group,key,options,kind,available)
    return add(b:Dropdown(title,options,function() return group[key] end,function(v) group[key]=v; self:Changed(kind) end,available or enabled))
  end
  local function color(title,key)
    return add(b:Color(title,function() return unpack(db.appearance[key]) end,function(r,g,bl,a)
      local c=db.appearance[key]; c[1],c[2],c[3]=r,g,bl; if a~=nil then c[4]=a end; self:Changed()
    end,enabled,nil,key=="barColor" or key=="backgroundColor"))
  end
  local function textPosition(kind)
    local options={}
    for _,id in ipairs(self.positions) do
      local position=id
      options[#options+1]={value=position,text=positionLabels[position],disabled=function() return not self:IsTextPositionAvailable(kind,position) end}
    end
    dropdown("표시 위치",db[kind],"position",options,kind,function() return enabled() and db[kind].enabled end)
  end
  b:Section("동작")
  dropdown("진행 방향",db.behavior,"direction",{{value="left_to_right",text="왼쪽 → 오른쪽"},{value="right_to_left",text="오른쪽 → 왼쪽"}})
  checkbox("Blizzard 시전 바 숨김",db.behavior,"hideBlizzard")
  b:Section("위치")
  dropdown("배치 기준",db.position,"mode",{{value="free",text="독립 배치"},{value="resource_above",text="ResourceSwing 위"},{value="resource_below",text="ResourceSwing 아래"}})
  local function freeEnabled() return enabled() and not self.linked end
  checkbox("위치 잠금",db.position,"locked",nil,freeEnabled)
  slider("X 위치",db.position.free,"x",-3000,3000,freeEnabled)
  slider("Y 위치",db.position.free,"y",-3000,3000,freeEnabled)
  local function resourceEnabled() return enabled() and db.position.mode~="free" end
  checkbox("ResourceSwing 폭에 맞춤",db.position.resource,"matchWidth",nil,resourceEnabled)
  slider("간격",db.position.resource,"gap",0,20,resourceEnabled)
  b:Description("ResourceSwing이 꺼지면 저장된 독립 위치를 사용합니다.")
  add(b:Button("위치 초기화",function()
    local p=db.position; p.free.point,p.free.relativePoint,p.free.x,p.free.y="CENTER","CENTER",0,-120
    p.resource.gap=4; self:Changed()
  end,180,enabled))
  add(b:Button("플레이어 시전바 드래그 이동",function() KHQOL.PositionEditor:Enter("cast") end,nil,freeEnabled))
  add(b:Button("미리보기 켜기 / 끄기",function() self:SetPreview(not self.preview) end,210,enabled))
  content:SetScript("OnHide",function()
    if KHQOL.PositionEditor and KHQOL.PositionEditor.active then return end
    self.controls=nil; if self.frame then self:SetPreview(false) end
  end)
  content:SetScript("OnShow",function() self.controls=controls; self:ApplyLayout(); self:RefreshControls() end)
  b:Section("바 모양")
  slider("높이",db.appearance,"height",8,80)
  slider("폭",db.appearance,"width",80,800,function() return enabled() and not (self.linked and db.position.resource.matchWidth) end)
  dropdown("텍스처",db.appearance,"texture",{{value="DEFAULT",text="Blizzard 기본"},{value="FLAT",text="단색"},{value="RAID",text="Raid"},{value="SKILL",text="Skill"}})
  b:Flush()
  color("바 색상","barColor"); color("배경 색상","backgroundColor"); color("시전 중단 색상","interruptedColor")
  b:Section("아이콘")
  checkbox("스킬 아이콘 표시",db.icon,"enabled")
  local function iconEnabled() return enabled() and db.icon.enabled end
  dropdown("아이콘 위치",db.icon,"position",{{value="left",text="왼쪽"},{value="right",text="오른쪽"}},nil,iconEnabled)
  slider("아이콘 크기",db.icon,"size",8,80,iconEnabled)
  b:Section("스킬명")
  checkbox("스킬명 표시",db.spellName,"enabled","spellName"); textPosition("spellName")
  slider("글자 크기",db.spellName,"fontSize",8,32,function() return enabled() and db.spellName.enabled end)
  b:Section("시전 시간")
  checkbox("시전 시간 표시",db.castTime,"enabled","castTime")
  dropdown("표시 형식",db.castTime,"format",{{value="remaining",text="남은 시간"},{value="total",text="전체 시간"},{value="remaining_total",text="남은 시간 / 전체 시간"}},nil,function() return enabled() and db.castTime.enabled end)
  textPosition("castTime")
  slider("글자 크기",db.castTime,"fontSize",8,32,function() return enabled() and db.castTime.enabled end)
  b:Flush();return b.y
end

function CastBar:BuildTargetSettings(content,y)
  local UI=KHQOL.UI;local b=UI:CreateBuilder(content,y)
  local function enabled() return self:IsEnabled() end
  b:Section("대상 시전바")
  local function targetAvailable() return enabled() and self:TargetFrame()~=nil end
  local function targetEnabled() return targetAvailable() and self:GetDB().targetPosition.enabled end
  b:Checkbox("KHQOL 대상 시전바 사용",function() return self:GetDB().targetPosition.enabled end,function(v) self:GetDB().targetPosition.enabled=v;self:ApplyTargetPosition() end,targetAvailable)
  for _,axis in ipairs({"x","y"}) do local a=axis
    b:Slider("대상 시전바 "..a:upper().." 위치 보정",-1000,1000,1,function() return self:GetDB().targetPosition[a] end,function(v) self:GetDB().targetPosition[a]=v;self:ApplyTargetPosition() end,function(v) return v.." px" end,targetEnabled)
  end
  b:Button("대상 시전바 드래그 이동",function() KHQOL.PositionEditor:Enter("cast.target") end,nil,targetEnabled)
  b:Button("대상 시전바 위치 초기화",function() local p=self:GetDB().targetPosition;p.x=0;p.y=0;self:ApplyTargetPosition() end,nil,targetAvailable)
  b:Description("플레이어 탭의 폭·높이·텍스처·바/배경/중단 색상·아이콘·스킬명 모양을 함께 사용합니다. 대상 체력·자원 바 아래를 기준으로 이동합니다. 시전 진행·채널 방향·시간 문구는 게임의 기본 처리를 유지하며, 기본 시간 영역이 없는 클라이언트에는 시간 문구를 추가하지 않습니다. 전투 중 모양 변경은 종료 후 적용합니다.",true)
  b:Flush();return b.y
end
function CastBar:BuildSettings(content,y)
  local UI,T=KHQOL.UI,KHQOL.UI.Theme
  local prefs=UI.SettingsNavigation:Preferences()
  local selected=prefs.castUnit=="target" and "target" or "player"
  local header=CreateFrame("Frame",nil,content);header:SetSize(content:GetWidth(),T.ButtonHeight+T.RowGap)
  content.fixedHeader=header;content.castPanels={};content.castButtons={};self.settingsPanel=content
  for _,kind in ipairs({"player","target"}) do
    local panel=CreateFrame("Frame",nil,content);panel:SetPoint("TOPLEFT",0,y);panel:SetWidth(content:GetWidth());panel:Hide()
    panel.settingsRoute={module="castBar",castUnit=kind};content.castPanels[kind]=panel
    local bottom=kind=="player" and self:BuildPlayerSettings(panel,0) or self:BuildTargetSettings(panel,0)
    panel:SetHeight(math.max(1,-bottom))
    panel:HookScript("OnSizeChanged",function() if selected==kind then content:SetHeight(-y+panel:GetHeight()) end end)
  end
  function content:SelectCastUnit(kind)
    if kind~="player" and kind~="target" then return end
    local changed=self.selectedCastUnit~=kind
    if changed then UI:CancelInputs(self);UI:CloseColorPicker();UI:CloseDropdown() end
    selected=kind;prefs.castUnit=kind;self.selectedCastUnit=kind
    for id,panel in pairs(self.castPanels) do if id~=kind then panel:Hide() end end
    local panel=self.castPanels[kind];panel:Show();panel:SetWidth(self:GetWidth())
    UI:ReflowRegisteredPanels(panel);UI:Refresh(panel);self:SetHeight(-y+panel:GetHeight())
    for id,button in pairs(self.castButtons) do UI:SetButtonSelected(button,id==kind) end
    local settings=KHQOL.settings
    if settings and settings.activeContent and settings.activeContent.activePanel==self then
      settings.currentRoute={module="castBar",castUnit=kind};settings.pageTitle:SetText(UI.SettingsNavigation:Path(settings.currentRoute))
      settings:SetPageScrollLayout("bars");settings:UpdateContentHeight()
      if changed then settings.scroll:SetVerticalScroll(0) end
    end
  end
  local x=0
  for _,entry in ipairs({{"player","플레이어"},{"target","대상"}}) do
    local kind=entry[1];local button=UI:CreateButton(header,entry[2],x,0,140,function() content:SelectCastUnit(kind) end)
    button.ignoreModuleEnabled=true;button.navigationOnly=true;content.castButtons[kind]=button;x=x+button:GetWidth()+T.RowGap
  end
  function content:RefreshTab() self:SelectCastUnit(selected) end
  content:HookScript("OnSizeChanged",function() local panel=content.castPanels[selected];if panel:GetWidth()~=content:GetWidth() then panel:SetWidth(content:GetWidth()) end end)
  content:SelectCastUnit(selected)
  return -content:GetHeight()
end
