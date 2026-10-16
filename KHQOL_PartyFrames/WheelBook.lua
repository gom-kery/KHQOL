local K=_G.KHQOL
local M=K.modules.partyFrames
local call=K.PublicCall
function M:OpenWheelSpellBook()
  local range=K.modules.range
  if range and range.OpenSpellBookPanel then return range:OpenSpellBookPanel("wheel") end
  if call(InCombatLockdown)==true then
    self.wheelBookMessage="전투 종료 후 스킬북 등록창을 여세요.";self:RefreshBookWheel();return false
  end
  local function host() return PlayerSpellsFrame and PlayerSpellsFrame.SpellBookFrame or SpellBookFrame end
  local book=host()
  if not book or call(book.IsShown,book)~=true then
    -- The same public native openers used by the existing Range integration.
    if PlayerSpellsUtil and type(PlayerSpellsUtil.OpenToSpellBookTab)=="function" then pcall(PlayerSpellsUtil.OpenToSpellBookTab)
    elseif type(ToggleSpellBook)=="function" then pcall(ToggleSpellBook,BOOKTYPE_SPELL or "spell")
    elseif type(TogglePlayerSpellsFrame)=="function" then pcall(TogglePlayerSpellsFrame) end
    book=host()
  end
  if not book or call(book.IsShown,book)~=true then
    K:ProfileMessage("게임 마법책을 연 뒤 휠 주문 등록을 다시 누르세요.");return false
  end
  local panel=self.standaloneWheelBook
  if not panel then
    panel=CreateFrame("Frame","KHQOLPartyWheelBookPanel",UIParent,"BackdropTemplate")
    panel:SetSize(310,340);panel:SetClampedToScreen(true);panel:SetFrameStrata("DIALOG")
    panel:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12})
    K.UI:Surface(panel,1)
    self:BuildBookWheel(panel)
    local close=K.UI:CreateButton(panel,"X",272,24,28,function() panel:Hide() end)
    close.navigationOnly=true
    self.standaloneWheelBook=panel
    if UISpecialFrames then UISpecialFrames[#UISpecialFrames+1]="KHQOLPartyWheelBookPanel" end
    panel:RegisterEvent("PLAYER_REGEN_DISABLED")
    panel:SetScript("OnEvent",function() panel:Hide() end)
  end
  if not book.khqolPartyWheelHideHook then
    book.khqolPartyWheelHideHook=true
    book:HookScript("OnHide",function() if M.standaloneWheelBook then M.standaloneWheelBook:Hide() end end)
  end
  panel:ClearAllPoints();panel:SetPoint("TOPLEFT",book,"TOPRIGHT",8,-35)
  self.wheelBookPanel=panel;self:RefreshBookWheel();panel:Show()
  return true
end
