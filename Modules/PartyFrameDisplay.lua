local _, K = ...
local M=K.modules.partyFrames
local call=K.PublicCall
local WHITE="Interface\\Buttons\\WHITE8X8"
local colors=K.ClassColors
M.classColors=colors
local events={"UNIT_HEALTH","UNIT_MAXHEALTH","UNIT_POWER_UPDATE","UNIT_MAXPOWER","UNIT_DISPLAYPOWER","UNIT_NAME_UPDATE","UNIT_CONNECTION","UNIT_FLAGS"}
local roleAtlases={TANK="roleicon-tiny-tank",HEALER="roleicon-tiny-healer",DAMAGER="roleicon-tiny-dps"}
M.roleAtlases=roleAtlases
local function raw(fn,...) if type(fn)~="function" then return false end;return pcall(fn,...) end
local function font(f,size)
  local path=call(GameFontHighlightSmall.GetFont,GameFontHighlightSmall)
  if path then f:SetFont(path,size,"OUTLINE") end
  f:SetTextColor(1,1,1,1);f:SetShadowColor(0,0,0,1);f:SetShadowOffset(1,-1)
end
function M:CreateVisuals(b)
  b.background=b:CreateTexture(nil,"BACKGROUND");b.background:SetAllPoints();b.background:SetColorTexture(.06,.07,.09,1)
  b.health=CreateFrame("StatusBar",nil,b);b.health:SetStatusBarTexture(WHITE);b.health:EnableMouse(false)
  b.deadShade=b.health:CreateTexture(nil,"OVERLAY");b.deadShade:SetAllPoints(b.health);b.deadShade:SetColorTexture(53/255,53/255,53/255,1);b.deadShade:SetAlpha(0)
  b.power=CreateFrame("StatusBar",nil,b);b.power:SetStatusBarTexture(WHITE);b.power:EnableMouse(false)
  b.labels=CreateFrame("Frame",nil,b);b.labels:SetAllPoints();b.labels:EnableMouse(false)
  for _,key in ipairs({"nameText","healthText","leaderText","stateText"}) do b[key]=b.labels:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall") end
  b.marker=b.labels:CreateTexture(nil,"OVERLAY");b.marker:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
  b.roleIcon=b.labels:CreateTexture(nil,"OVERLAY")
end
function M:OnButtonLoad(b)
  local h=b:GetParent();b.khqolKind=h.khqolKind
  b:EnableMouse(true);b:SetClampedToScreen(false)
  self:CreateVisuals(b)
  b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
  SecureUnitButton_OnLoad(b,nil,CompactUnitFrame_OpenMenu)
  b:SetAttribute("checkselfcast",false);b:SetAttribute("checkfocuscast",false);b:SetAttribute("checkmouseovercast",false)
  -- Keep Blizzard's inherited secure scripts intact. Addon XML scripts run
  -- insecurely and must never call SecureHandler_OnSimpleEvent directly.
  b:HookScript("OnShow",function() M:OnButtonShow(b) end)
  b:HookScript("OnHide",function() M:OnButtonHide(b) end)
  self.buttons[#self.buttons+1]=b
  self:StyleButton(b,self.visual[b.khqolKind])
end
function M:AnchorRegion(region,owner,position,width)
  region:ClearAllPoints();region:SetPoint(position.point,owner,position.point,position.x,position.y)
  if width then
    region:SetWidth(width);region:SetWordWrap(false)
    region:SetJustifyH(position.point:find("RIGHT",1,true) and "RIGHT" or position.point:find("LEFT",1,true) and "LEFT" or "CENTER")
  end
end
function M:StyleButton(b,d,visual)
  local db=visual or self.visual
  b:SetSize(d.width,d.height)
  local level=b:GetFrameLevel();b.health:SetFrameLevel(level+1);b.power:SetFrameLevel(level+1);b.labels:SetFrameLevel(level+3)
  local ph=db.showPower and db.powerHeight or 0
  b.health:ClearAllPoints();b.health:SetPoint("TOPLEFT",b,"TOPLEFT",1,-1);b.health:SetSize(d.width-2,d.height-2-ph)
  b.power:ClearAllPoints();b.power:SetPoint("BOTTOMLEFT",b,"BOTTOMLEFT",1,1);b.power:SetSize(d.width-2,db.powerHeight);b.power:SetAlpha(db.showPower and 1 or 0)
  local bg=db.background;b.background:SetColorTexture(bg.r,bg.g,bg.b,bg.a)
  for _,key in ipairs({"nameText","healthText","leaderText","stateText"}) do font(b[key],db.fontSize);b[key]:ClearAllPoints() end
  self:AnchorRegion(b.nameText,b.health,db.namePosition,d.width-10)
  self:AnchorRegion(b.healthText,b.health,db.healthPosition,d.width-db.rolePosition.size-14)
  self:AnchorRegion(b.stateText,b.health,db.healthPosition,d.width-10)
  b.leaderText:SetPoint("TOPRIGHT",b,"TOPRIGHT",-5,-3)
  self:AnchorRegion(b.marker,b.health,db.markerPosition);b.marker:SetSize(db.markerPosition.size,db.markerPosition.size)
  self:AnchorRegion(b.roleIcon,b.health,db.rolePosition);b.roleIcon:SetSize(db.rolePosition.size,db.rolePosition.size)
end
function M:SetFeatureReason(key,reason)
  self.featureReasons=self.featureReasons or {}
  if self.featureReasons[key]==reason then return end
  self.featureReasons[key]=reason
  if not self.applying then self:RefreshStatus() end
end
function M:PrepareHealthCurves()
  self.healthCurves=nil;self.deadOpaque=nil;self.deadTransparent=nil
  if type(CreateColor)=="function" and C_CurveUtil and type(C_CurveUtil.EvaluateColorFromBoolean)=="function" then
    self.deadOpaque=CreateColor(53/255,53/255,53/255,1);self.deadTransparent=CreateColor(53/255,53/255,53/255,0)
  end
  if not self.visual.healthGradient then return end
  local ok=pcall(function()
    assert(type(UnitHealthPercent)=="function" and C_CurveUtil and type(C_CurveUtil.CreateColorCurve)=="function" and type(CreateColor)=="function")
    local curves={}
    for token,color in pairs(colors) do
      local curve=C_CurveUtil.CreateColorCurve();curve:SetType(Enum.LuaCurveType.Linear)
      curve:AddPoint(0,CreateColor(1,0,0,1));curve:AddPoint(1,CreateColor(unpack(color)))
      curves[token]=curve
    end
    self.healthCurves=curves
  end)
  if not ok then self:SetFeatureReason("gradient","체력 그라데이션을 적용할 게임 색상 API를 확인할 수 없습니다.") end
end
function M:ApplyHealthColor(b,unit,token,dead)
  local color=colors[token] or {.2,.55,.3};b.health:SetStatusBarColor(unpack(color))
  local curve=self.healthCurves and self.healthCurves[token]
  if self.visual.healthGradient and curve then
    -- The engine evaluates the health percentage. Secret RGB components go
    -- directly from its color object into the status bar without Lua math.
    local ok=pcall(function() b.health:SetStatusBarColor(UnitHealthPercent(unit,true,curve):GetRGB()) end)
    if not ok then self:SetFeatureReason("gradientRuntime","현재 유닛의 체력 그라데이션 적용이 보류되었습니다.") end
  end
  b.deadShade:SetAlpha(dead==true and 1 or 0)
  if self.deadOpaque then
    pcall(function()
      local tint=C_CurveUtil.EvaluateColorFromBoolean(UnitIsDeadOrGhost(unit),self.deadOpaque,self.deadTransparent)
      b.deadShade:SetAlpha(select(4,tint:GetRGBA()))
    end)
  end
end
function M:ReadUnit(b)
  local unit=call(b.GetAttribute,b,"unit")
  if type(unit)=="string" and (unit=="player" or unit:match("^party[1-4]$") or unit:match("^raid%d+$")) then return unit end
end
function M:ConfigureUnitEvents(b)
  b:UnregisterAllEvents()
  b.khqolUnit=self:ReadUnit(b)
  if self.applied and b.khqolUnit and call(b.IsVisible,b)==true then
    for _,event in ipairs(events) do b:RegisterUnitEvent(event,b.khqolUnit) end
  end
  self:SyncDebuffUnit(b)
end
function M:OnUnitChanged(b,name)
  if not K.IsPublicValue(name) or name~="unit" or not b.health then return end
  self:ConfigureUnitEvents(b)
  if self.applied then self:RefreshButton(b) else self:ClearDisplay(b) end
  self:RefreshGroupTitle(b:GetParent())
end
function M:OnButtonShow(b)
  if not b.health then return end
  self:ConfigureUnitEvents(b)
  if self.applied then self:RefreshButton(b) end
  self:RefreshGroupTitle(b:GetParent())
end
function M:OnButtonHide(b)
  b:UnregisterAllEvents();b.khqolUnit=nil
  self:SyncDebuffUnit(b)
  self:RefreshGroupTitle(b:GetParent())
end
function M:RefreshGroupTitle(h)
  if not h or not h.title then return end
  local any=false
  if self.applied then for i=1,5 do
    local b=call(h.GetAttribute,h,"child"..i)
    if b and self:ReadUnit(b) and call(b.IsVisible,b)==true then any=true;break end
  end end
  h.title:SetAlpha(any and 1 or 0)
end
function M:ClearDisplay(b)
  for _,key in ipairs({"nameText","healthText","leaderText","stateText"}) do b[key]:SetText("") end
  b.health:SetAlpha(0);b.power:SetAlpha(0);b.marker:SetAlpha(0);b.roleIcon:SetAlpha(0);b.deadShade:SetAlpha(0)
end
function M:RefreshButton(b)
  if not self.applied then return end
  local unit=self:ReadUnit(b)
  if not unit or call(UnitExists,unit)~=true then self:ClearDisplay(b);return end
  b.khqolUnit=unit
  local db=self.visual
  -- Opaque health/power values are passed only to C widgets. Never branch on,
  -- compare, calculate, format in Lua, or stringify these returned values.
  local maxOK,max=raw(UnitHealthMax,unit);local healthOK,health=raw(UnitHealth,unit)
  local rangeOK,valueOK=false,false
  if maxOK then rangeOK=raw(b.health.SetMinMaxValues,b.health,0,max) end
  if healthOK then valueOK=raw(b.health.SetValue,b.health,health) end
  b.health:SetAlpha(rangeOK and valueOK and 1 or 0)
  local token=select(2,call(UnitClass,unit))
  local nameOK,name=raw(UnitName,unit)
  if nameOK then raw(b.nameText.SetText,b.nameText,name) else b.nameText:SetText("") end
  b.healthText:SetText("")
  if db.showHealth and healthOK then raw(b.healthText.SetText,b.healthText,health) end
  local connected=call(UnitIsConnected,unit);local dead=call(UnitIsDeadOrGhost,unit);local afk=call(UnitIsAFK,unit)
  self:ApplyHealthColor(b,unit,token,dead)
  b.stateText:SetText(connected==false and "오프라인" or dead==true and "사망" or afk==true and "자리 비움" or "")
  -- Use explicit public state booleans only; unreadable state stays blank.
  if connected==false or dead==true or afk==true then b.healthText:SetAlpha(0) else b.healthText:SetAlpha(1) end
  local powerID,powerToken=call(UnitPowerType,unit)
  local powerMaxOK,powerMax=raw(UnitPowerMax,unit,powerID);local powerOK,power=raw(UnitPower,unit,powerID)
  local pr,pv=false,false
  if powerMaxOK then pr=raw(b.power.SetMinMaxValues,b.power,0,powerMax) end
  if powerOK then pv=raw(b.power.SetValue,b.power,power) end
  b.power:SetAlpha(db.showPower and pr and pv and 1 or 0)
  local pc=PowerBarColor and PowerBarColor[powerToken or powerID]
  if pc and K.IsPublicNumber(pc.r) and K.IsPublicNumber(pc.g) and K.IsPublicNumber(pc.b) then b.power:SetStatusBarColor(pc.r,pc.g,pc.b) else b.power:SetStatusBarColor(.2,.4,.8) end
  local atlas=roleAtlases[call(UnitGroupRolesAssigned,unit)]
  if atlas then raw(b.roleIcon.SetAtlas,b.roleIcon,atlas) end
  b.roleIcon:SetAlpha(db.showRole and atlas and connected~=false and dead~=true and 1 or 0)
  b.leaderText:SetText(call(UnitIsGroupLeader,unit)==true and "L" or "")
  local marker=call(GetRaidTargetIndex,unit)
  if db.showMarker and K.IsPublicNumber(marker) and marker>=1 and marker<=8 and marker==math.floor(marker) then
    local col=(marker-1)%4;local row=math.floor((marker-1)/4)
    b.marker:SetTexCoord(col/4,(col+1)/4,row/2,(row+1)/2);b.marker:SetAlpha(1)
  else b.marker:SetAlpha(0) end
end
function M:RefreshAll()
  for _,b in ipairs(self.buttons) do
    self:ConfigureUnitEvents(b)
    if call(b.IsVisible,b)==true then self:RefreshButton(b) end
  end
  for _,h in ipairs(self.headers) do self:RefreshGroupTitle(h) end
end
