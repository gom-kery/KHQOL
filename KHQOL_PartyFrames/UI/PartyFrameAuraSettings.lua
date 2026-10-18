local _,K=...
K=assert(_G.KHQOL,"Install and enable the KHQOL core addon.")
local M=K.modules.partyFrames
local UI=K.UI
local function integer(v) return string.format("%d",v) end
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
  self:PreviewEffects(c,db,entry.key,self.effectPreviewShield or 25)
  self:PreviewDebuffs(c,db.debuffs);c:Show()
 end
 box:SetHeight(math.ceil(6/columns)*pitch)
end
function M:BuildAuraSettings(content,y)
 local b=UI:CreateBuilder(content,y)
 content.settingsRoute={module="partyFrames",tab="auras",scope="계정 공용 프레임 프로필"}
 self.auraContent=content
 local scope=b:Description("",true)
 content.uiControls[#content.uiControls+1]={Refresh=function()
  scope:SetText("프레임 프로필: "..M:ActiveFrameProfile().." · 파티·10·20·40인 공통")
  M:RefreshEffectPreview()
 end}
 self.auraStatusLabel=b:Description("",true)
 local function cfg() return M:GetDB() end
 local function aura(key,value) cfg().debuffs[key]=value;M:RequestApply() end
 b:Section("디버프 아이콘")
 b:Checkbox("파티원 디버프 표시",function() return cfg().debuffs.enabled end,function(v) aura("enabled",v) end)
 b:Flush()
 b:Slider("디버프 최대 개수",1,12,1,function() return cfg().debuffs.count end,function(v) aura("count",v) end,integer)
 b:Slider("디버프 한 줄 개수",1,12,1,function() return cfg().debuffs.perRow end,function(v) aura("perRow",v) end,integer)
 b:Slider("디버프 크기",8,48,1,function() return cfg().debuffs.size end,function(v) aura("size",v) end,integer)
 b:Slider("디버프 간격",0,20,1,function() return cfg().debuffs.gap end,function(v) aura("gap",v) end,integer)
 b:Dropdown("디버프 위치",M.debuffPositions,function() return cfg().debuffs.position end,function(v) aura("position",v) end)
 b:Flush()
 b:Slider("디버프 X",-300,300,1,function() return cfg().debuffs.x end,function(v) aura("x",v) end,integer)
 b:Slider("디버프 Y",-300,300,1,function() return cfg().debuffs.y end,function(v) aura("y",v) end,integer)
 b:Description("게임 기본 디버프 표시기를 사용합니다. 아래 예시 아이콘으로 크기·간격·위치를 확인할 수 있습니다.",true)
 b:Section("디버프 종류별 체력 색상")
 b:Checkbox("디버프 종류에 따라 체력 색상 변경",function() return cfg().debuffTint.enabled end,function(v) cfg().debuffTint.enabled=v;M:RequestApply() end)
 b:Description("체력이 차 있는 부분에 색을 겹쳐 표시합니다. 여러 종류가 겹치면 게임 기본 디버프 우선순위에서 선택한 한 종류를 표시합니다. 디버프가 없어지면 기본 체력 색으로 돌아옵니다.",true)
 for _,entry in ipairs(M.debuffTypes) do
  local key=entry.key
  b:Color(entry.name.." 색·투명도",function()
   local c=cfg().debuffTint.colors[key];return c.r,c.g,c.b,c.a
  end,function(r,g,blue,a)
   local c=cfg().debuffTint.colors[key];c.r,c.g,c.b,c.a=r,g,blue,a;M:RequestApply()
  end,nil,nil,true)
 end
 b:Flush()
 b:Button("디버프 색상 기본값 복원",function()
  local d=cfg().debuffTint.colors
  for _,entry in ipairs(M.debuffTypes) do
   local c,default=d[entry.key],M.defaults.debuffTint.colors[entry.key]
   c.r,c.g,c.b,c.a=default.r,default.g,default.b,default.a
  end
  M:RequestApply()
 end)
 b:Description("기본색: 저주 #9600FF · 질병 #966400 · 마법 #3296FF · 독 #009600 · 출혈 #C80000. 각 색 버튼에서 색과 불투명도를 조절합니다.",true)
 b:Section("보호막 흡수량 오버레이")
 b:Checkbox("보호막 오버레이 표시",function() return cfg().absorb.enabled end,function(v) cfg().absorb.enabled=v;M:RequestApply() end)
 b:Flush()
 b:Dropdown("보호막 텍스처",M.absorbTextures,function() return cfg().absorb.texture end,function(v) cfg().absorb.texture=v;M:RequestApply() end)
 b:Color("보호막 색·투명도",function()
  local c=cfg().absorb.color;return c.r,c.g,c.b,c.a
 end,function(r,g,blue,a) local c=cfg().absorb.color;c.r,c.g,c.b,c.a=r,g,blue,a;M:RequestApply() end,nil,nil,true)
 b:Description("총 흡수량을 최대 체력에 대한 비율로 표시합니다. 체력 바 오른쪽 끝에서 왼쪽으로 겹치며 최대 체력보다 큰 보호막은 바 전체까지 표시합니다. 체력 수치 자체는 바뀌지 않습니다.",true)
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
