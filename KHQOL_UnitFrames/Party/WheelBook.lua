local _,package=...
if not package.loadParty then return end
local K=_G.KHQOL
local M=K.modules.partyFrames
local layers=K.WindowLayers

local function sharedBook()
  local range=K.modules.range
  return range and range.OpenSpellBookPanel and range
end

function M:CloseStandaloneWheelBook()
  if self.standaloneWheelBook then self.standaloneWheelBook:Hide() end
end

function M:SyncStandaloneWheelBook()
  local button=self.standaloneWheelButton
  if not button then return false end
  local book,root=self.standaloneWheelHost,self.standaloneWheelRoot
  local panel=self.standaloneWheelBook
  local show=not sharedBook() and layers:PlaceOnSpellBook(button,book,root,20)
    and (not panel or layers:PlaceOnSpellBook(panel,book,root,30))
  button:SetShown(show)
  if not show then self:CloseStandaloneWheelBook() end
  return show
end

function M:AttachStandaloneWheelBook()
  if sharedBook() or not K.db or not layers:OutsideCombat() then return end
  local book,root=layers:SpellBook()
  if not book then
    if self.standaloneWheelButton then self.standaloneWheelButton:Hide() end
    self:CloseStandaloneWheelBook()
    return
  end
  if not self.standaloneWheelButton then
    local button=K.UI:CreateButton(UIParent,"KHQOL 스킬 설정",0,0,144,function()
      if self.standaloneWheelBook and self.standaloneWheelBook:IsShown() then self:CloseStandaloneWheelBook()
      else self:OpenWheelSpellBook() end
    end)
    button:SetSize(144,28);button:SetClampedToScreen(true);button:Hide()
    self.standaloneWheelButton=button
  end
  if self.standaloneWheelHost~=book or self.standaloneWheelRoot~=root then
    self:CloseStandaloneWheelBook();self.standaloneWheelHost,self.standaloneWheelRoot=book,root
    local button=self.standaloneWheelButton
    button:ClearAllPoints();button:SetPoint("TOPRIGHT",book,"TOPRIGHT",-30,-80)
    layers:WatchSpellBook(self,book,root,function() self:CloseStandaloneWheelBook();self:SyncStandaloneWheelBook() end)
  end
  return self:SyncStandaloneWheelBook()
end

function M:OpenWheelSpellBook()
  local range=sharedBook()
  if range then return range:OpenSpellBookPanel("wheel") end
  if not layers:OutsideCombat() then
    self.wheelBookMessage="전투 종료 후 스킬북 등록창을 여세요.";self:RefreshBookWheel();return false
  end
  layers:OpenSpellBook()
  if not self:AttachStandaloneWheelBook() then
    K:ProfileMessage("게임 마법책을 연 뒤 휠 주문 등록을 다시 누르세요.");return false
  end
  local panel=self.standaloneWheelBook
  if not panel then
    panel=CreateFrame("Frame","KHQOLPartyWheelBookPanel",UIParent,"BackdropTemplate")
    panel.khqolSpellBookPanel=true;panel:SetSize(310,412);panel:SetClampedToScreen(true);panel:Hide()
    K.UI:Surface(panel,1)
    panel.title=K.UI:CreateLabel(panel,"KHQOL 스킬 설정",12,-12);panel.title:SetWidth(245)
    panel.wheelTab=K.UI:CreateButton(panel,"휠 클릭 시전",12,-42,286,function() end);K.UI:SetButtonSelected(panel.wheelTab,true)
    local view=CreateFrame("ScrollFrame",nil,panel);view:SetPoint("TOPLEFT",0,-80);view:SetPoint("BOTTOMRIGHT",0,8);view:EnableMouseWheel(true)
    local body=CreateFrame("Frame",nil,view);body:SetSize(310,326);body:SetPoint("TOPLEFT",0,0);view:SetScrollChild(body)
    panel.wheelBody,panel.wheelViewport=body,view;self:BuildBookWheel(body)
    view:SetScript("OnMouseWheel",function(_,delta) K.UI:CloseDropdown();view:SetVerticalScroll(math.max(0,math.min(math.max(0,body:GetHeight()-view:GetHeight()),view:GetVerticalScroll()-delta*34))) end)
    local close=K.UI:CreateButton(panel,"X",272,-8,26,function() self:CloseStandaloneWheelBook() end)
    close.navigationOnly=true
    panel:SetScript("OnHide",function() K.UI:CloseDropdown() end)
    self.standaloneWheelBook=panel
    if UISpecialFrames then UISpecialFrames[#UISpecialFrames+1]="KHQOLPartyWheelBookPanel" end
  end
  if not self:SyncStandaloneWheelBook() then return false end
  panel:ClearAllPoints();panel:SetPoint("TOPLEFT",self.standaloneWheelHost,"TOPRIGHT",8,-35)
  self.wheelBookPanel=panel.wheelBody;self:RefreshBookWheel();panel:Show()
  return true
end

local events=CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent",function(_,event,name)
  if event~="ADDON_LOADED" or name=="Blizzard_PlayerSpells" or name=="Blizzard_SpellBook" then
    M:AttachStandaloneWheelBook()
  end
end)
