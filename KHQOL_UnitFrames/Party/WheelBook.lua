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
    local button=K.UI:CreateButton(UIParent,"KHQOL\n설정",0,0,100,function()
      if self.standaloneWheelBook and self.standaloneWheelBook:IsShown() then self:CloseStandaloneWheelBook()
      else self:OpenWheelSpellBook() end
    end)
    button:SetSize(100,44);button:SetClampedToScreen(true);button:Hide()
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
    panel.khqolSpellBookPanel=true;panel:SetSize(310,340);panel:SetClampedToScreen(true);panel:Hide()
    K.UI:Surface(panel,1)
    self:BuildBookWheel(panel)
    local close=K.UI:CreateButton(panel,"X",272,24,28,function() self:CloseStandaloneWheelBook() end)
    close.navigationOnly=true
    self.standaloneWheelBook=panel
    if UISpecialFrames then UISpecialFrames[#UISpecialFrames+1]="KHQOLPartyWheelBookPanel" end
  end
  if not self:SyncStandaloneWheelBook() then return false end
  panel:ClearAllPoints();panel:SetPoint("TOPLEFT",self.standaloneWheelHost,"TOPRIGHT",8,-35)
  self.wheelBookPanel=panel;self:RefreshBookWheel();panel:Show()
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
