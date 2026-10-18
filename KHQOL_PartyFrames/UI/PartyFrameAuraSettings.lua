local _,K=...
K=assert(_G.KHQOL,"Install and enable the KHQOL core addon.")
local M=K.modules.partyFrames
local UI=K.UI
local T=UI.Theme
local function integer(v) return string.format("%d",v) end
-- This page alone tries compact headers and inline color rows. The shared
-- controls still own input, color cancellation, availability and navigation.
local function accordion(b,content,title,key)
 b:Flush();content.khqolSection=title
 UI.disclosureStates=UI.disclosureStates or {}
 local id="partyFrames/auras/"..key
 if UI.disclosureStates[id]==nil then UI.disclosureStates[id]=true end
 local group={id=id,builder=b,parent=b.currentDisclosure,title=title}
 local function refresh()
  group.toggle:SetText(UI.disclosureStates[id] and "▼" or "▶")
 end
 local function changed()
  refresh();b:Reflow()
  if K.settings then K.settings:UpdateContentHeight() end
 end
 function group:Expand()
  if self.parent then self.parent:Expand() end
  UI.disclosureStates[id]=true;changed()
 end
 local x,y,width=b:Cell("auraHeading",1,T.SectionGap+T.ButtonHeight+T.RowGap)
 local row=CreateFrame("Frame",nil,content);row:SetPoint("TOPLEFT",x,y-T.SectionGap);row:SetSize(width,T.ButtonHeight)
 row:EnableMouse(false);row.settingsNoIndex=true
 local toggle=UI:CreateButton(row,"",0,0,T.ButtonHeight,function()
  UI:CloseDropdown();UI:CloseColorPicker()
  UI.disclosureStates[id]=not UI.disclosureStates[id];changed()
 end)
 toggle:SetSize(T.ButtonHeight,T.ButtonHeight)
 local fs=toggle:GetFontString();fs:SetWidth(T.ButtonHeight);fs:SetWordWrap(false);fs:SetJustifyH("CENTER")
 local label=UI:CreateLabel(row,title,T.ButtonHeight+T.RowGap,-6,T.SectionFontSize)
 label:SetWidth(math.max(1,width-T.ButtonHeight-T.RowGap))
 toggle.ignoreModuleEnabled=true;toggle.navigationOnly=true
 group.row=row;group.label=label
 group.toggle=toggle;toggle.settingsDisclosure=group
 local original=toggle.Refresh
 toggle.Refresh=function() original();refresh() end
 b:Track(row,x,y-T.SectionGap,function(region,w)
  region:SetWidth(w);label:SetWidth(math.max(1,w-T.ButtonHeight-T.RowGap))
 end)
 b.activeCell.full=true
 UI:AttachTooltip(toggle,title,"클릭하여 설정 항목을 접거나 펼칩니다.")
 content.auraAccordions[#content.auraAccordions+1]=group
 toggle:Refresh();b:Flush();b.currentDisclosure=group
 return group
end
local function inlineColor(b,content,title,get,set,field)
 local x,y,width=b:Cell(field and "field" or "auraColor",2,field and T.DropdownRowHeight or T.RowHeight+T.RowGap)
 local top=field and y-24 or y
 local row=CreateFrame("Frame",nil,content);row:SetPoint("TOPLEFT",x,top);row:SetSize(width,T.ButtonHeight)
 row.settingsNoIndex=true;row.settingsDisclosure=b.currentDisclosure
 local label=UI:CreateLabel(row,title,0,-6);local labelWidth=math.max(44,label:GetStringWidth())
 label:SetWidth(labelWidth);label:SetWordWrap(false)
 local control=UI:CreateColorPicker(row,"",labelWidth+8,24,get,set,nil,nil,true)
 control.inlineLabel=label;control.inlineRow=row
 local original=control.Refresh
 control.Refresh=function() original();UI:ApplyAvailability(control,nil,{label}) end
 control.settingsDisclosure=b.currentDisclosure
 b:Track(row,x,top,function(region,w) region:SetWidth(w) end)
 if UI.SettingsNavigation then UI.SettingsNavigation:Attach(content,control,title,get,set,nil,"색과 투명도를 변경합니다.") end
 UI:AttachTooltip(control,title,"색과 투명도를 변경합니다.")
 control:Refresh();b.lastControl,b.lastTitle=control,title
 return control
end
function M:RefreshEffectPreview()
 local content=self.auraContent;local box=content and content.effectPreview
 if not box then return end
 local db=self:GetDB();local width=box:GetWidth();local gap=16
 local columns=width>=460 and 2 or 1;local w=math.max(100,(width-gap*(columns-1))/columns)
 local h=math.max(58,2*db.fontSize+10+(db.showPower and db.powerHeight or 0))
 local top,bottom=0,-h;local a=db.debuffs
 if a.enabled then
  local rows=math.ceil(a.count/math.min(a.count,a.perRow));local ah=rows*a.size+(rows-1)*a.gap
  local at=a.position=="TOP" and a.y+2+ah or a.position=="BOTTOM" and -h+a.y-2 or a.position=="CENTER" and -h/2+a.y+ah/2 or a.y
  top=math.max(top,at);bottom=math.min(bottom,at-ah)
 end
 local pitch=top-bottom+18
 local d={width=w,height=h};box.cells=box.cells or {}
 local normal={name="정상 · 기본색"}
 for i=1,6 do
  local entry=i==1 and normal or self.debuffTypes[i-1]
  local c=box.cells[i]
  if not c then c=CreateFrame("Frame",nil,box);c:EnableMouse(false);self:CreateVisuals(c);box.cells[i]=c end
  self:StyleButton(c,d,db);c:ClearAllPoints()
  c:SetPoint("TOPLEFT",box,"TOPLEFT",((i-1)%columns)*(w+gap),-math.floor((i-1)/columns)*pitch-top)
  c.health:SetMinMaxValues(0,100);c.health:SetValue(70);c.health:SetStatusBarColor(.2,.55,.3,1);c.health:SetAlpha(1)
  c.power:SetMinMaxValues(0,100);c.power:SetValue(60);c.power:SetStatusBarColor(.2,.4,.85,1)
  c.nameText:SetText(entry.name.." · 예시");c.healthText:SetText(db.showHealth and "700" or "")
  c.leaderText:SetText("");c.stateText:SetText("");c.marker:SetAlpha(0);c.roleIcon:SetAlpha(0);c.deadShade:SetAlpha(0)
  self:PreviewEffects(c,db,entry.key,self.effectPreviewShield or 25,70)
  self:PreviewDebuffs(c,db.debuffs);c:Show()
 end
 box:SetHeight(math.ceil(6/columns)*pitch)
end
function M:BuildAuraSettings(content,y)
 content.settingsFieldTwoColumnWidth=480
 content.settingsCompactDisclosures=true
 local b=UI:CreateBuilder(content,y)
 content.settingsRoute={module="partyFrames",tab="auras",scope="계정 공용 프레임 프로필"}
 self.auraContent=content
 content.auraAccordions={}
 local scope=b:Description("",true)
 content.uiControls[#content.uiControls+1]={Refresh=function()
  scope:SetText("프레임 프로필: "..M:ActiveFrameProfile().." · 파티·10·20·40인 공통")
  M:RefreshEffectPreview()
 end}
 self.auraStatusLabel=b:Description("",true)
 local function cfg() return M:GetDB() end
 local function aura(key,value) cfg().debuffs[key]=value;M:RequestApply() end
 accordion(b,content,"디버프 아이콘","icons")
 b:Checkbox("파티원 디버프 표시",function() return cfg().debuffs.enabled end,function(v) aura("enabled",v) end)
 b.activeCell.full=true
 b:Flush()
 b:Slider("디버프 한 줄 개수",1,12,1,function() return cfg().debuffs.perRow end,function(v) aura("perRow",v) end,integer)
 b:Slider("디버프 최대 개수",1,12,1,function() return cfg().debuffs.count end,function(v) aura("count",v) end,integer)
 b:Slider("디버프 크기",8,48,1,function() return cfg().debuffs.size end,function(v) aura("size",v) end,integer)
 b:Slider("디버프 간격",0,20,1,function() return cfg().debuffs.gap end,function(v) aura("gap",v) end,integer)
 b:Dropdown("디버프 위치",M.debuffPositions,function() return cfg().debuffs.position end,function(v) aura("position",v) end)
 b:Flush()
 b:Slider("디버프 X 좌표",-300,300,1,function() return cfg().debuffs.x end,function(v) aura("x",v) end,integer)
 b:Slider("디버프 Y 좌표",-300,300,1,function() return cfg().debuffs.y end,function(v) aura("y",v) end,integer)
 b:EndDisclosure()
 accordion(b,content,"디버프 별 체력 색상","tint")
 b:Checkbox("디버프 별 체력 색상 변경",function() return cfg().debuffTint.enabled end,function(v) cfg().debuffTint.enabled=v;M:RequestApply() end)
 b.activeCell.full=true
 b:Description("체력 색을 디버프 색으로 표시.")
 b:Flush()
 local names={};for _,entry in ipairs(M.debuffTypes) do names[entry.key]=entry.name end
 for _,kind in ipairs({"Curse","Disease","Magic","Bleed","Poison"}) do
  local key=kind
  inlineColor(b,content,names[key],function()
   local c=cfg().debuffTint.colors[key];return c.r,c.g,c.b,c.a
  end,function(r,g,blue,a)
   local c=cfg().debuffTint.colors[key];c.r,c.g,c.b,c.a=r,g,blue,a;M:RequestApply()
  end)
 end
 local rx,ry,rw=b:Cell("auraColor",2,T.RowHeight+T.RowGap)
 UI:CreateButton(content,"기본값 복원",rx,ry,rw,function()
  local d=cfg().debuffTint.colors
  for _,entry in ipairs(M.debuffTypes) do
   local c,default=d[entry.key],M.defaults.debuffTint.colors[entry.key]
   c.r,c.g,c.b,c.a=default.r,default.g,default.b,default.a
  end
  M:RequestApply()
 end)
 b:EndDisclosure()
 accordion(b,content,"보호막 오버레이","absorb")
 b:Checkbox("보호막 오버레이 표시",function() return cfg().absorb.enabled end,function(v) cfg().absorb.enabled=v;M:RequestApply() end)
 b.activeCell.full=true
 b:Flush()
 b:Dropdown("보호막 텍스처",M.absorbTextures,function() return cfg().absorb.texture end,function(v) cfg().absorb.texture=v;M:RequestApply() end)
 inlineColor(b,content,"흡수 무늬",function()
  local c=cfg().absorb.color;return c.r,c.g,c.b,c.a
 end,function(r,g,blue,a) local c=cfg().absorb.color;c.r,c.g,c.b,c.a=r,g,blue,a;M:RequestApply() end,true)
 b:EndDisclosure()
 b:Section("디버프·보호막 미리보기")
 local slider=b:Slider("예시 보호막 비율",0,100,5,function() return M.effectPreviewShield or 25 end,function(v) M.effectPreviewShield=v;M:RefreshEffectPreview();M:RefreshLivePreview() end,function(v) return integer(v).."%" end)
 slider.ignoreModuleEnabled=true;slider.navigationOnly=true
 slider.numberBox.ignoreModuleEnabled=true;slider:Refresh()
 b:Description("실제 캐릭터에게 효과를 걸지 않는 예시입니다. 정상과 다섯 디버프 색, 보호막 텍스처를 함께 확인합니다. 색·아이콘·보호막의 사용 스위치와 현재 설정을 반영합니다.",true)
 local x,top,width=b:Cell("effectPreview",1,232)
 local preview=CreateFrame("Frame",nil,content);preview:SetPoint("TOPLEFT",x,top);preview:SetWidth(width);preview:SetHeight(228);preview:EnableMouse(false)
 content.effectPreview=preview
 b:Track(preview,x,top,function(region,w) region:SetWidth(w);M:RefreshEffectPreview() end)
 M:RefreshEffectPreview()
 return b.y
end
