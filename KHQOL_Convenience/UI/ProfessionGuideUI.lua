local K=_G.KHQOL
local M=K.modules.professions
local G=M.guide
local UI=K.UI
local call=K.PublicCall
local GREEN,RED,NEUTRAL="|cff55cc77","|cffff7777","|cffaaaaaa"
local function money(value)
  if not K.IsPublicNumber(value) or value<0 or value~=math.floor(value) then return nil end
  if value==0 then return "무료" end
  local result={}
  for _,unit in ipairs({{10000,"Gold"},{100,"Silver"},{1,"Copper"}}) do
    local amount=math.floor(value/unit[1]);value=value%unit[1]
    if amount>0 then result[#result+1]=amount.."|TInterface\\MoneyFrame\\UI-"..unit[2].."Icon:14:14:2:0|t" end
  end
  return table.concat(result," ")
end
local function numeric(current,maximum,condition)
  local color=condition.met==true and GREEN or condition.insufficient and RED or NEUTRAL
  local value=tostring(current or "-")..(maximum~=false and "/"..tostring(maximum or "-") or "")
  return color..value.." ("..condition.display..")|r"
end
function G:Leave(owner)
  if not owner or self.tooltipOwner==owner then
    if self.tooltipOwner and GameTooltip:IsOwned(self.tooltipOwner) then GameTooltip:Hide() end
    self.tooltipOwner=nil;self.tooltipID=nil
  end
end
function G:ShowTooltip(owner,id,count)
  if not self:Enabled() then return false end
  if self.menuTicket and (self.menuTicket.owner~=owner or self.menuTicket.id~=id or not self:Validate(self.menuTicket)) then self:CloseMenu() end
  local view=self:Presentation(id);local state=view.state
  GameTooltip:SetOwner(owner,"ANCHOR_RIGHT");GameTooltip:ClearLines()
  GameTooltip:SetText(state.name or "전문기술",1,.82,.18)
  GameTooltip:AddLine(" ")
  GameTooltip:AddLine("레벨 "..numeric(state.level,false,view.level),1,1,1,true)
  GameTooltip:AddLine("숙련 "..numeric(state.skill,state.maximum,view.skill),1,1,1,true)
  if state.status=="final" then
    GameTooltip:AddLine(" ");GameTooltip:AddLine("최종 숙련",.55,.85,.65)
  elseif not state.next then
    GameTooltip:AddLine(" ");GameTooltip:AddLine("다음 단계 정보 없음",.7,.7,.7)
  elseif view.eligible then
    GameTooltip:AddLine(" ");GameTooltip:AddLine(state.next.maximum.." 숙련",1,1,1)
    if view.trainerSummary then GameTooltip:AddLine("대도시 "..state.name.." 상급자",.85,.85,.85,true) end
    if view.showPlaces then
      for index,place in ipairs(view.places) do
        if index>1 then GameTooltip:AddLine(" ") end
        local c=place.candidate;local method=c.method
        GameTooltip:AddLine(place.label.." · "..c.point.name,.85,.85,.85,true)
        if method.kind=="book" then
          local price=money(method.price)
          GameTooltip:AddLine("'"..method.title.."'"..(price and " "..price or "").." 구입",.85,.85,.85,true)
        elseif method.kind=="quest" then GameTooltip:AddLine("퀘스트 '"..method.title.."'",.85,.85,.85,true) end
      end
      if view.canRegister then GameTooltip:AddLine(" ");GameTooltip:AddLine("우클릭: 포에버 노트 등록",.55,.8,.85,true) end
    end
  end
  GameTooltip:Show()
  if count~=false and self.tooltipOwner~=owner then self:Metric("guide","display") end
  self.tooltipOwner=owner;self.tooltipID=id;return true
end
function G:CreateIcon(parent,resolver)
  local b=UI:CreateButton(parent,"i",0,0,24,function() end)
  b.navigationOnly=true;b.settingsNoIndex=true;b.guideID=resolver;b:SetSize(24,24)
  b:RegisterForClicks("LeftButtonUp","RightButtonUp")
  b:SetScript("OnEnter",function() G:ShowTooltip(b,resolver(),true) end)
  b:SetScript("OnLeave",function() G:Leave(b) end)
  b:SetScript("OnClick",function(_,button)
    if not G:Enabled() then return end
    if button=="RightButton" then G:Request(b,resolver()) else G:ShowTooltip(b,resolver(),true) end
  end)
  b:HookScript("OnHide",function() G:Leave(b);if G.menuOwner==b then G:CloseMenu() end end)
  return b
end
function G:CloseMenu()
  if self.menuButton and UI.openDropdown==self.menuButton.menu then UI:CloseDropdown() end
  self.menuOwner=nil;self.menuSelect=nil;self.menuTicket=nil
end
function G:OpenMenu(owner,options,selected)
  self:CloseMenu()
  self.menuOwner=owner;self.menuOptions=options;self.menuSelect=selected
  if not self.menuButton then
    local b
    b=UI:CreateDropdown(UIParent,0,0,24,function() return G.menuOptions or {} end,function() end,function(value) if G.menuSelect then G.menuSelect(value) end end,function() return G:Enabled() end)
    b.menuNavigation=true;b.navigationOnly=true;b.popupParent=UIParent;b:Hide();self.menuButton=b
  end
  local b=self.menuButton;b:ClearAllPoints();b:SetPoint("TOPLEFT",owner,"TOPLEFT",0,0)
  b:GetScript("OnClick")(b,"LeftButton")
end
function G:ChooseCandidates(owner,ticket,places)
  local options={}
  for _,place in ipairs(places) do
    local c=place.candidate
    options[#options+1]={value=c.id,text=place.label.." · "..c.point.name..(not place.point and " (좌표 등록 불가)" or ""),disabled=place.point==nil}
  end
  self:OpenMenu(owner,options,function(id) G:Register(ticket,id) end)
  self.menuTicket=ticket
end
function G:ShowNoteResult(owner,item,guideTicket)
  if not owner then return end
  local fc=K.modules.clock
  local ticket=fc.CreateTodoPinRouteTicket and fc:CreateTodoPinRouteTicket(item.id)
  local generation=K.profileGeneration;local pages=fc.db.todo.pages
  self:OpenMenu(owner,{{value="navigate",text="등록된 노트 위치 길 안내",disabled=ticket==nil}},function(value)
    if generation~=K.profileGeneration or pages~=fc.db.todo.pages or not G:Enabled() then return end
    if guideTicket and not G:Validate(guideTicket) then G:CloseMenu();return end
    if value=="navigate" then G:Navigate(ticket) end
  end)
  self.menuTicket=guideTicket
end
function G:HideNative()
  if self.nativeIcon then self.nativeIcon:Hide() end
end
function G:NativeID()
  local info=call(C_TradeSkillUI and C_TradeSkillUI.GetBaseProfessionInfo)
  if not K.IsPublicValue(info) or type(info)~="table" then return nil end
  local id,parent=call(function() return info.professionID,info.parentProfessionID end)
  if M.rankCatalog.professions[id] then return id end
  if M.rankCatalog.professions[parent] then return parent end
end
function G:AttachNative()
  if not self:Enabled() then return self:HideNative() end
  if call(InCombatLockdown)==true then return self:HideNative() end
  local frame=_G.ProfessionsFrame
  if not K.WindowLayers:Readable(frame) then return self:HideNative() end
  if not self.hooked[frame] then
    self.hooked[frame]=true
    call(frame.HookScript,frame,"OnShow",function() if G:Enabled() then G:AttachNative() end end)
    call(frame.HookScript,frame,"OnHide",function() G:HideNative();G:CloseMenu() end)
  end
  local bar=call(function() return frame.CraftingPage and frame.CraftingPage.RankBar end)
  if not K.WindowLayers:Readable(bar) or call(bar.IsVisible,bar)~=true then return self:HideNative() end
  if call(C_TradeSkillUI and C_TradeSkillUI.IsTradeSkillLinked)==true or call(C_TradeSkillUI and C_TradeSkillUI.IsTradeSkillGuild)==true then return self:HideNative() end
  local id=self:NativeID();if not id or not self:Learned(id) then return self:HideNative() end
  if not self.nativeIcon then self.nativeIcon=self:CreateIcon(UIParent,function() return G:NativeID() end);self.nativeIcon:SetFrameStrata("HIGH") end
  self.nativeIcon:ClearAllPoints();self.nativeIcon:SetPoint("LEFT",bar,"RIGHT",8,0);self.nativeIcon:Show()
end
function G:BuildSettings(b)
  local function cfg() return M:GetDB().rankGuide end
  local function get(key) return function() return cfg()[key] end end
  local function set(key) return function(v) cfg()[key]=v;G:Configure() end end
  b:Section("숙련 단계 안내")
  b:Checkbox("숙련 단계 안내",get("enabled"),set("enabled"))
  b:Checkbox("습득 위치 표시",get("locations"),set("locations"),get("enabled"))
  b:Description("습득처 안내 아이콘 우클릭: 포에버 노트 등록. 등록 가능한 안내에서만 사용할 수 있습니다.")
end
