local _,K=...
K = assert(_G.KHQOL, "Install and enable the KHQOL core addon.")
local M=K.modules.partyFrames
local call=K.PublicCall
M.layoutOptions={{value="party",text="파티 · 1~5인"},{value="raid10",text="10인 공격대 · 6~10인"},
  {value="raid20",text="20인 공격대 · 11~20인"},{value="raid40",text="40인 공격대 · 21~40인"}}
local titles={party="파티",raid10="10인 공격대",raid20="20인 공격대",raid40="40인 공격대"}
function M:SetEditedLayout(key)
  if not titles[key] then return end
  self.editedLayout=key;self:RefreshLivePreview()
  if self.settingsContent then K.UI:Refresh(self.settingsContent) end
end
function M:CloseLivePreview()
  self.livePreview=nil
  if self.livePreviewFrame then self.livePreviewFrame:Hide() end
  if self.previewToolbar and self.previewToolbar:IsShown() then self.previewToolbar:Hide() end
  if self.previewToolbar then self.previewToolbar:UnregisterAllEvents() end
end
local function anchorFraction(point)
  local x=point:find("LEFT",1,true) and 0 or point:find("RIGHT",1,true) and 1 or .5
  local y=point:find("BOTTOM",1,true) and 0 or point:find("TOP",1,true) and 1 or .5
  return x,y
end
function M:SavePreviewPosition()
  local f=self.livePreviewFrame;if not self.livePreview or not f then return false end
  f:StopMovingOrSizing()
  if call(InCombatLockdown)==true then self:CloseLivePreview();return false end
  local left,top=call(f.GetLeft,f),call(f.GetTop,f)
  local fs,ps=call(f.GetEffectiveScale,f),call(UIParent.GetEffectiveScale,UIParent)
  local w,h=call(f.GetWidth,f),call(f.GetHeight,f)
  if not K.IsPublicNumber(left) or not K.IsPublicNumber(top) or not K.IsPublicNumber(fs) or not K.IsPublicNumber(ps) or ps<=0 or not K.IsPublicNumber(w) or not K.IsPublicNumber(h) then return false end
  local d=self:GetDB()[self.editedLayout or "party"];local ax,ay=anchorFraction(d.point)
  d.x=K.PositionStore:Round((left+w*ax)*fs/ps-UIParent:GetWidth()*ax)
  d.y=K.PositionStore:Round((top-h*(1-ay))*fs/ps-UIParent:GetHeight()*ay)
  self:RequestApply();return true
end
local sampleClasses={"WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","SHAMAN","MAGE","WARLOCK","DRUID"}
local sampleDebuffs={"Spell_Shadow_ShadowWordPain","Spell_Frost_FrostNova","Spell_Nature_CorrosiveBreath"}
function M:PreviewDebuffs(c,cfg)
  if not c.sampleDebuffs then
    c.sampleDebuffs=CreateFrame("Frame",nil,c);c.sampleDebuffs:EnableMouse(false);c.sampleDebuffs.icons={}
  end
  local f=c.sampleDebuffs
  f:SetShown(cfg.enabled);if not cfg.enabled then return end
  local cols=math.min(cfg.count,cfg.perRow);local rows=math.ceil(cfg.count/cols)
  f:SetSize(cols*cfg.size+(cols-1)*cfg.gap,rows*cfg.size+(rows-1)*cfg.gap)
  self:AnchorDebuffs(f,c,cfg)
  for i=1,12 do
    local icon=f.icons[i]
    if i<=cfg.count then
      if not icon then icon=f:CreateTexture(nil,"OVERLAY");f.icons[i]=icon end
      icon:SetTexture("Interface\\Icons\\"..sampleDebuffs[(i-1)%#sampleDebuffs+1]);icon:SetSize(cfg.size,cfg.size)
      icon:ClearAllPoints()
      local y=math.floor((i-1)/cols)*(cfg.size+cfg.gap)
      local point=cfg.position=="TOP" and "BOTTOMLEFT" or "TOPLEFT"
      icon:SetPoint(point,f,point,((i-1)%cols)*(cfg.size+cfg.gap),cfg.position=="TOP" and y or -y);icon:Show()
    elseif icon then icon:Hide() end
  end
end
function M:RefreshLivePreview()
  if not self.livePreview then return end
  if call(InCombatLockdown)==true then self:CloseLivePreview();return end
  local f=self.livePreviewFrame;local key=self.editedLayout or "party";local db=self:GetDB();local d=db[key]
  if not f or not d then return end
  local raid=key~="party";local groups=self:MaxLayoutGroups(key);local count=groups*5
  f:StopMovingOrSizing();self:PlaceLayoutRoot(f,key,d,groups)
  f.cells=f.cells or {};f.groupLabels=f.groupLabels or {}
  for i=1,40 do
    local c=f.cells[i]
    if i<=count then
      if not c then c=CreateFrame("Frame",nil,f);c:EnableMouse(false);self:CreateVisuals(c);f.cells[i]=c end
      self:StyleButton(c,d,db)
      local group=math.ceil(i/5);local member=(i-1)%5
      local x,y,point=0,0,d.groupAnchor=="RIGHT" and "TOPRIGHT" or "TOPLEFT"
      if raid then x,y,point=self:GroupOffset(key,d,group-1,groups) end
      local mx=d.orientation=="HORIZONTAL" and member*(d.width+d.gap) or 0
      local my=d.orientation=="VERTICAL" and member*(d.height+d.gap) or 0
      c:ClearAllPoints();c:SetPoint(point,f,point,x+(d.groupAnchor=="RIGHT" and -mx or mx),y-my)
      -- Only fixed, public sample values are calculated for preview art.
      local fraction=({1,.75,.5,.25,.02})[(i-1)%5+1]
      local dead=i==5;local afk=i==4
      local color=self.classColors[sampleClasses[(i-1)%#sampleClasses+1]]
      local r,g,blue=unpack(color)
      if db.healthGradient then r=1+(r-1)*fraction;g=g*fraction;blue=blue*fraction end
      c.health:SetMinMaxValues(0,100);c.health:SetValue(fraction*100);c.health:SetStatusBarColor(r,g,blue);c.health:SetAlpha(1)
      c.deadShade:SetAlpha(dead and 1 or 0)
      c.power:SetMinMaxValues(0,100);c.power:SetValue(65);c.power:SetStatusBarColor(.2,.4,.85)
      c.nameText:SetText(i==1 and "플레이어" or "파티원 "..i)
      c.healthText:SetText(db.showHealth and not dead and not afk and tostring(math.floor(fraction*10000)) or "");c.healthText:SetAlpha(1)
      c.stateText:SetText(dead and "사망" or afk and "자리 비움" or "");c.leaderText:SetText(i==1 and "L" or "")
      local role=member==0 and "TANK" or member==1 and "HEALER" or "DAMAGER"
      c.roleIcon:SetAtlas(self.roleAtlases[role]);c.roleIcon:SetAlpha(db.showRole and not dead and 1 or 0)
      c.marker:SetTexCoord(0,.25,0,.5);c.marker:SetAlpha(db.showMarker and member==0 and 1 or 0)
      self:PreviewDebuffs(c,db.debuffs);c:Show()
    elseif c then c:Hide() end
  end
  for i=1,8 do
    local label=f.groupLabels[i]
    if raid and i<=groups then
      if not label then label=K.UI:CreateDescription(f,"",0,0);f.groupLabels[i]=label end
      local x,y,point=self:GroupOffset(key,d,i-1,groups)
      label:ClearAllPoints();label:SetPoint(point,f,point,x,y+18);label:SetWidth(d.width)
      label:SetJustifyH(d.groupAnchor=="RIGHT" and "RIGHT" or "LEFT");label:SetText(i.." 파티");label:Show()
    elseif label then label:Hide() end
  end
  self.previewToolbar.caption:SetText(titles[key].." 미리보기 · 예시 표시 · 끌어서 위치 이동");self.previewToolbar.selection:Refresh();f:Show()
end
function M:OpenLivePreview()
  if call(InCombatLockdown)==true then return false,"전투 종료 후 미리보기를 여세요." end
  if K.PositionEditor and K.PositionEditor.active then return false,"통합 위치 편집을 마친 뒤 미리보기를 여세요." end
  if not self.livePreviewFrame then
    local f=CreateFrame("Frame","KHQOLPartyLivePreview",UIParent);self.livePreviewFrame=f
    f:SetFrameStrata("MEDIUM");f:SetClampedToScreen(true);f:SetMovable(true);f:EnableMouse(true);f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart",function() if call(InCombatLockdown)~=true then f:StartMoving() end end)
    f:SetScript("OnDragStop",function() M:SavePreviewPosition() end)
    local bar=CreateFrame("Frame","KHQOLPartyPreviewToolbar",UIParent,"BackdropTemplate");self.previewToolbar=bar
    bar:SetSize(456,100);bar:SetPoint("TOP",UIParent,"TOP",0,-64);bar:SetFrameStrata("DIALOG");bar:SetClampedToScreen(true);bar:EnableMouse(true)
    bar:SetMovable(true);bar:RegisterForDrag("LeftButton");bar:SetScript("OnDragStart",bar.StartMoving);bar:SetScript("OnDragStop",bar.StopMovingOrSizing)
    K.UI:Surface(bar)
    bar.caption=K.UI:CreateDescription(bar,"",12,-10);bar.caption:SetWidth(432);bar.caption:SetJustifyH("CENTER")
    bar.selection=K.UI:CreateDropdown(bar,12,-40,248,self.layoutOptions,function() return M.editedLayout or "party" end,function(v) M:SetEditedLayout(v) end)
    bar.closeButton=K.UI:CreateButton(bar,"미리보기 종료",276,-40,168,function() M:CloseLivePreview() end)
    bar.closeButton:SetWidth(168)
    bar.closeButton:GetFontString():SetJustifyH("CENTER")
    bar.hint=K.UI:CreateDescription(bar,"설정 변경·드래그를 즉시 저장합니다. 전투 시작 시 종료합니다.",12,-76)
    bar.hint:SetWidth(432);bar.hint:SetJustifyH("CENTER")
    bar:SetScript("OnHide",function() if M.livePreview then M:CloseLivePreview() end end)
    bar:SetScript("OnEvent",function() M:CloseLivePreview() end)
    K.UI:RegisterDraft(bar,function() M:CloseLivePreview() end)
    if UISpecialFrames then table.insert(UISpecialFrames,"KHQOLPartyPreviewToolbar") end
    bar:Hide();f:Hide()
  end
  self.livePreview=true;self.previewToolbar:RegisterEvent("PLAYER_REGEN_DISABLED");self.previewToolbar:Show()
  K.ModuleRegistry:Own("partyFrames",self.previewToolbar,function() M:CloseLivePreview() end)
  self:RefreshLivePreview();return true
end
