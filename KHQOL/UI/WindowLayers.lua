local _,K=...
local read=K.PublicCall
local L={windows=setmetatable({}, {__mode="k"}),books=setmetatable({}, {__mode="k"}),dialogs={}}
K.WindowLayers=L

L.order={BACKGROUND=1,LOW=2,MEDIUM=3,HIGH=4,DIALOG=5,FULLSCREEN=6,FULLSCREEN_DIALOG=7,TOOLTIP=8}
local aboveBook={"LOW","MEDIUM","HIGH","DIALOG","FULLSCREEN","FULLSCREEN_DIALOG"}

function L:OutsideCombat()
  return not InCombatLockdown or read(InCombatLockdown)==false
end

function L:Readable(frame)
  if not K.IsPublicValue(frame) or (type(frame)~="table" and type(frame)~="userdata") then return false end
  if canaccessobject and read(canaccessobject,frame)~=true then return false end
  if frame.IsForbidden and read(frame.IsForbidden,frame)~=false then return false end
  if frame.CanBeAccessedInContext and read(frame.CanBeAccessedInContext,frame)~=true then return false end
  return true
end

function L:ModalShown()
  for frame in pairs(self.dialogs) do
    if self:Readable(frame) and read(frame.IsVisible or frame.IsShown,frame)==true then return true end
  end
  return false
end

function L:RefreshWindow(frame)
  local modal=self:ModalShown()
  if not self:OutsideCombat() then
    self.pending=true
    if not modal or read(frame.IsProtected,frame)~=false then return end
  end
  local general=K.db and K.db.general
  local strata=not modal and general and general.windowOverlap=="KHQOL" and "FULLSCREEN" or "LOW"
  if frame:GetFrameStrata()~=strata then frame:SetFrameStrata(strata) end
end

function L:RegisterWindow(frame)
  if self.windows[frame] then return end
  self.windows[frame]=true
  frame:HookScript("OnShow",function() self:RefreshWindow(frame) end)
  self:RefreshWindow(frame)
end

function L:Refresh()
  for frame in pairs(self.windows) do self:RefreshWindow(frame) end
end

function L:WatchDialogs()
  if not self:OutsideCombat() then return end
  local function watch(frame)
    if self:Readable(frame) and not self.dialogs[frame] then
      self.dialogs[frame]=true
      read(frame.HookScript,frame,"OnShow",function() self:Refresh() end)
      read(frame.HookScript,frame,"OnHide",function() self:Refresh() end)
    end
  end
  for i=1,4 do watch(_G["StaticPopup"..i]) end
  watch(ColorPickerFrame)
end

function L:SpellBook()
  local root=PlayerSpellsFrame
  if self:Readable(root) then
    local book=read(function() return root.SpellBookFrame end)
    if self:Readable(book) then return book,root end
  end
  if self:Readable(SpellBookFrame) then return SpellBookFrame,SpellBookFrame end
end

function L:IsSpellBookVisible(book,root)
  if not self:Readable(book) or not self:Readable(root) then return false end
  if read(root.IsVisible or root.IsShown,root)~=true or read(book.IsVisible or book.IsShown,book)~=true then return false end
  if book~=root and root.GetTab then
    local spellTab=read(function() return root.spellBookTabID end)
    if spellTab~=nil then return read(root.GetTab,root)==spellTab end
  elseif book==root and read(function() return book.bookType end)==(BOOKTYPE_PET or "pet") then
    return false
  end
  return true
end

function L:PlaceOnSpellBook(frame,book,root,offset)
  if not self:OutsideCombat() or not self:IsSpellBookVisible(book,root) then return false end
  local bookLayer=self.order[read(book.GetFrameStrata,book)]
  local rootLayer=self.order[read(root.GetFrameStrata,root)]
  local layer=bookLayer and rootLayer and aboveBook[math.max(bookLayer,rootLayer)]
  if not layer then return false end
  if frame:GetFrameStrata()~=layer then frame:SetFrameStrata(layer) end
  if frame:GetFrameLevel()~=offset then frame:SetFrameLevel(offset) end
  return true
end

function L:WatchSpellBook(owner,book,root,callback)
  if not self:OutsideCombat() or not self:Readable(book) or not self:Readable(root) then return end
  local watch=self.books[owner]
  if not watch then watch={hooked=setmetatable({}, {__mode="k"})};self.books[owner]=watch end
  watch.book,watch.root,watch.callback=book,root,callback
  for _,frame in ipairs({root,book}) do
    if not watch.hooked[frame] then
      watch.hooked[frame]=true
      local function changed()
        if watch.book==frame or watch.root==frame then watch.callback() end
      end
      read(frame.HookScript,frame,"OnShow",changed)
      read(frame.HookScript,frame,"OnHide",changed)
      if frame==root and book~=root and type(root.SetTab)=="function" then
        read(hooksecurefunc,root,"SetTab",changed)
      elseif frame==root and book==root and type(SpellBookFrameTabButton_OnClick)=="function" and not watch.legacy then
        watch.legacy=true
        read(hooksecurefunc,"SpellBookFrameTabButton_OnClick",changed)
      end
    end
  end
end

function L:OpenSpellBook()
  if not self:OutsideCombat() then return end
  local book,root=self:SpellBook()
  if self:IsSpellBookVisible(book,root) then return end
  if PlayerSpellsUtil and type(PlayerSpellsUtil.OpenToSpellBookTab)=="function" then
    read(PlayerSpellsUtil.OpenToSpellBookTab)
  elseif type(ToggleSpellBook)=="function" then read(ToggleSpellBook,BOOKTYPE_SPELL or "spell")
  else read(TogglePlayerSpellsFrame) end
end

local events=CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent",function(_,event,name)
  if event=="PLAYER_LOGIN" or event=="ADDON_LOADED" then
    if event=="PLAYER_LOGIN" or name=="Blizzard_StaticPopup" or name=="Blizzard_StaticPopup_Game" or name=="Blizzard_ColorPicker" then
      L:WatchDialogs();L:Refresh()
    end
    return
  end
  if event=="PLAYER_REGEN_ENABLED" then L:WatchDialogs() end
  if event=="PLAYER_REGEN_ENABLED" and L.pending then L.pending=nil;L:Refresh() end
  for _,watch in pairs(L.books) do watch.callback() end
end)
