local _, KHQOL = ...
local General = KHQOL.modules.general

local defaults = {
  centerTextScale = 100, autoSellJunk = false, autoConfirmDestroy = false, chatEnhancement = false,
  autoRepair = false, useGuildFunds = false, declinePartyInvites = false, declineGuildInvites = false,
}

function General:GetDB()
  KHQOL.db.general = KHQOL.db.general or {}
  KHQOL.MergeDefaults(KHQOL.db.general, defaults)
  return KHQOL.db.general
end

function General:ApplyCenterTextScale()
  local frame = _G.UIErrorsFrame
  if frame and frame.SetScale then frame:SetScale((self:GetDB().centerTextScale or 100) / 100) end
end

-- Forever exposes C_Container tables; older clients return positional values.
-- Missing/secret data never qualifies an item for automatic sale.
local function secret(value) return type(issecretvalue) == "function" and issecretvalue(value) end
local publicCall = KHQOL.PublicCall
local function containerAPI(name)
  if C_Container and type(C_Container[name]) == "function" then return C_Container[name] end
  return _G[name]
end
local function validNumber(value)
  return not secret(value) and type(value) == "number" and value == value and value < math.huge and value >= 0
end
local BAG_INFO_KEYS = {"stackCount", "isLocked", "quality", "hyperlink", "hasNoValue", "itemID"}
local INVITE_OPTIONS = {party="declinePartyInvites", guild="declineGuildInvites"}
local function ReadBagItemInfo(bag, slot)
  local fn = containerAPI("GetContainerItemInfo")
  if type(fn) ~= "function" then return nil, false end
  local ok, icon, count, locked, quality, readable, loot, link, filtered, noValue, id = pcall(fn, bag, slot)
  if not ok or secret(icon) then return nil, false end
  if icon == nil then return nil, true end -- Successfully read an empty slot.
  local info
  if type(icon) == "table" then
    info = { stackCount=icon.stackCount, isLocked=icon.isLocked, quality=icon.quality,
      hyperlink=icon.hyperlink, hasNoValue=icon.hasNoValue, itemID=icon.itemID }
  else
    info = { stackCount=count, isLocked=locked, quality=quality,
      hyperlink=link, hasNoValue=noValue, itemID=id }
  end
  for _, key in ipairs(BAG_INFO_KEYS) do
    if secret(info[key]) then return nil, false end
  end
  return info, true
end
local function GetBagItemInfo(bag,slot)
  local ok,info,readable=pcall(ReadBagItemInfo,bag,slot)
  if ok then return info,readable end
  return nil,false
end
local function IsNonQuestItem(bag, slot)
  local quest, id = publicCall(containerAPI("GetContainerItemQuestInfo"), bag, slot)
  if type(quest) == "table" then
    if secret(quest.isQuestItem) or secret(quest.questID) then return false end
    return quest.isQuestItem == false and quest.questID == nil
  end
  -- Old APIs may use nil for both non-quest and unavailable data: skip those.
  return quest == false and id == nil
end
local function ReadSaleCandidate(bag, slot)
  local info = GetBagItemInfo(bag, slot)
  if not info or info.quality ~= 0 or info.isLocked ~= false or info.hasNoValue ~= false then return end
  if not validNumber(info.stackCount) or info.stackCount < 1 or info.stackCount % 1 ~= 0 then return end
  if type(info.hyperlink) ~= "string" or info.hyperlink == "" then return end
  if not IsNonQuestItem(bag, slot) then return end
  if C_Item and type(C_Item.IsItemDataCachedByID) == "function"
    and publicCall(C_Item.IsItemDataCachedByID, info.hyperlink) ~= true then return end
  local itemAPI = C_Item and C_Item.GetItemInfo or GetItemInfo
  local name, link, quality, level, minLevel, kind, subtype, stack, equip, texture, price, classID, subclassID, bindType = publicCall(itemAPI, info.hyperlink)
  if type(name) ~= "string" or name == "" or quality ~= 0 or not validNumber(price) or price <= 0 or price % 1 ~= 0 then return end
  -- Quest class (12) and quest-bound items (bind type 4) are also excluded.
  if not validNumber(classID) or classID == 12 or not validNumber(bindType) or bindType == 4 then return end
  info.bag, info.slot, info.price = bag, slot, price
  return info
end
local function GetSaleCandidate(bag,slot)
  local ok,candidate=pcall(ReadSaleCandidate,bag,slot)
  if ok then return candidate end -- Unreadable fields cannot authorize a sale.
end
local function ForEachBagItem(callback)
  -- Only backpack + equipped bags (Forever 0..4), never bank/keyring slots.
  local lastBag = validNumber(NUM_BAG_SLOTS) and NUM_BAG_SLOTS or 4
  for bag = 0, math.min(lastBag, 4) do
    local count = publicCall(containerAPI("GetContainerNumSlots"), bag)
    if validNumber(count) and count % 1 == 0 then
      for slot = 1, count do callback(bag, slot) end
    end
  end
end
local function MerchantIsOpen()
  local frame = _G.MerchantFrame
  return frame and publicCall(frame.IsShown, frame) == true
end

local function CancelDeferred(owner)
  if owner and owner.timer and owner.timer.Cancel then owner.timer:Cancel() end
end
local function DeferOnce(owner, callback)
  local function run() owner.timer = nil; callback() end
  if C_Timer and type(C_Timer.NewTimer) == "function" then
    local ok, timer = pcall(C_Timer.NewTimer, 0, run)
    if ok then owner.timer = timer end
  elseif C_Timer and type(C_Timer.After) == "function" then
    pcall(C_Timer.After, 0, run)
  end
end

function General:TryAutoRepair(visit)
  if not visit or self.merchantVisit ~= visit or visit.repairAttempted or not self.junkMerchantOpen then return end
  if self:GetDB().autoRepair ~= true or not MerchantIsOpen() then return end
  visit.repairAttempted = true -- One decision/call per visit, including failures.
  if type(RepairAllItems) ~= "function" or publicCall(CanMerchantRepair) ~= true then return end
  local cost, needed = publicCall(GetRepairAllCost)
  if needed ~= true or not validNumber(cost) or cost <= 0 or cost % 1 ~= 0 then return end
  local guild = false
  if self:GetDB().useGuildFunds == true and publicCall(IsInGuild) == true and publicCall(CanGuildBankRepair) == true then
    local balance = publicCall(GetGuildBankMoney)
    local allowance = publicCall(GetGuildBankWithdrawMoney)
    -- Forever's native guild repair button treats -1 as unlimited, still
    -- bounded by the actual bank balance. Unknown data uses personal funds.
    guild = validNumber(balance) and balance >= cost
      and (allowance == -1 or (validNumber(allowance) and allowance >= cost))
  end
  if not guild then
    local money = publicCall(GetMoney)
    if not validNumber(money) or money < cost then return end
  end
  if not MerchantIsOpen() or self.merchantVisit ~= visit or self:GetDB().autoRepair ~= true then return end
  -- This API has no success return. Never follow a guild attempt with a
  -- second personal repair: a missing response is not proof of failure.
  pcall(RepairAllItems, guild)
end

function General:CloseMerchantWork()
  local visit = self.merchantVisit
  self.merchantVisit = nil; self.junkMerchantOpen = false
  CancelDeferred(visit); self:CancelJunkSale()
end

function General:CancelInviteDecline(kind)
  local pending = self.inviteDeclines and self.inviteDeclines[kind]
  if self.inviteDeclines then self.inviteDeclines[kind] = nil end
  CancelDeferred(pending)
end

function General:QueueInviteDecline(kind, inviter, guildName)
  local module=KHQOL.modules.generalConvenience
  if module then module:QueueInvite(kind,inviter,guildName) end
end
local function SellBagItem(bag, slot)
  if not MerchantIsOpen() then return false end
  local fn = containerAPI("UseContainerItem")
  if type(fn) ~= "function" then return false end
  -- The API has no success return. Confirmation happens before the next sale.
  return pcall(fn, bag, slot)
end

function General:CancelJunkSale()
  local state = self.junkSale
  self.junkSale = nil
  if state and state.timer and state.timer.Cancel then state.timer:Cancel() end
end

local function SaleIsActive(state)
  return General.junkSale == state and General.junkMerchantOpen
    and General:GetDB().autoSellJunk == true and MerchantIsOpen()
end
local function ScheduleSale(state, delay, callback)
  if General.junkSale ~= state then return end
  local function run()
    state.timer = nil
    if General.junkSale ~= state then return end
    if not SaleIsActive(state) then General:CancelJunkSale(); return end
    callback()
  end
  if C_Timer and type(C_Timer.NewTimer) == "function" then
    state.timer = C_Timer.NewTimer(delay, run)
  elseif C_Timer and type(C_Timer.After) == "function" then
    C_Timer.After(delay, run) -- Session identity makes uncancellable callbacks inert.
  else
    General:CancelJunkSale()
  end
end

function General:ProcessJunkSale(state)
  if not SaleIsActive(state) then self:CancelJunkSale(); return end
  if state.pending then
    local pending = state.pending
    local info, known = GetBagItemInfo(pending.bag, pending.slot)
    if not known then self:CancelJunkSale(); return end
    if info then
      -- Never retry UseContainerItem. Wait at most .75s for the original sale.
      pending.checks = pending.checks + 1
      if pending.checks >= 5 then self:CancelJunkSale(); return end
      ScheduleSale(state, .15, function() General:ProcessJunkSale(state) end)
      return
    end
    local amount = pending.price * pending.stackCount
    local money = publicCall(GetMoney)
    -- Sum vendor prices of emptied slots; money only corroborates each sale.
    -- Repairs, purchases or other income cannot inflate the reported amount.
    if not validNumber(money) or not validNumber(pending.money) or money - pending.money ~= amount then
      state.reportReliable = false
    end
    state.total = state.total + amount
    state.pending = nil
  end
  while state.index <= #state.queue do
    local queued = state.queue[state.index]
    state.index = state.index + 1
    local item = GetSaleCandidate(queued.bag, queued.slot)
    if item and item.hyperlink == queued.hyperlink and item.stackCount == queued.stackCount then
      item.money, item.checks = publicCall(GetMoney), 0
      if not SellBagItem(item.bag, item.slot) then self:CancelJunkSale(); return end
      state.pending = item
      ScheduleSale(state, .15, function() General:ProcessJunkSale(state) end)
      return
    end
  end
  self:CancelJunkSale()

  -- All sale confirmations finish before any repair deduction.
  self:TryAutoRepair(self.merchantVisit)
end

function General:StartJunkSale()
  if self.junkMerchantOpen then return end -- One snapshot per merchant visit.
  self.junkMerchantOpen = true
  local visit = {}; self.merchantVisit = visit
  if self:GetDB().autoSellJunk ~= true then
    if self:GetDB().autoRepair == true then
      DeferOnce(visit, function() General:TryAutoRepair(visit) end)
    end
    return
  end
  local state = { queue={}, index=1, total=0, reportReliable=true }
  self.junkSale = state
  -- Merchant UI can process MERCHANT_SHOW after this frame; defer one turn.
  ScheduleSale(state, 0, function()
    ForEachBagItem(function(bag, slot)
      local item = GetSaleCandidate(bag, slot)
      if item then state.queue[#state.queue + 1] = item end
    end)
    General:ProcessJunkSale(state)
  end)
end

-- Only fill the typed item-destruction confirmation; never accept the dialog.
-- Camelot uses DELETE_GOOD_ITEM and the localized DELETE_ITEM_CONFIRM_STRING.
function General:FillDestroyConfirmation(dialog)
  if not self:GetDB().autoConfirmDestroy or not dialog or dialog.which~="DELETE_GOOD_ITEM" then return end
  if not dialog:IsShown() or type(DELETE_ITEM_CONFIRM_STRING)~="string" or DELETE_ITEM_CONFIRM_STRING=="" then return end
  local definition=StaticPopupDialogs and StaticPopupDialogs[dialog.which]
  if definition and definition.editBoxSecureText then return end
  local box=dialog.GetEditBox and dialog:GetEditBox() or dialog.editBox or dialog.EditBox
  if not box or not box:IsShown() or type(box.SetText)~="function" then return end
  if box:GetText()~="" then return end
  box:SetText(DELETE_ITEM_CONFIRM_STRING)
  -- Blizzard's existing OnTextChanged handler enables Yes after validation.
end
function General:InitializeDestroyConfirmation()
  if self.destroyConfirmationHooked or type(StaticPopup_OnShow)~="function" then return end
  self.destroyConfirmationHooked=true
  hooksecurefunc("StaticPopup_OnShow",function(dialog) General:FillDestroyConfirmation(dialog) end)
end

function General:Initialize()
  if self.initialized then self:ApplyCenterTextScale(); return end
  self.initialized = true; self:GetDB(); self:ApplyCenterTextScale()
  self:InitializeDestroyConfirmation()
  local events = CreateFrame("Frame")
  events:RegisterEvent("PLAYER_ENTERING_WORLD")
  events:RegisterEvent("ADDON_LOADED")
  events:RegisterEvent("MERCHANT_SHOW")
  events:RegisterEvent("MERCHANT_CLOSED")
  for _, event in ipairs({"PARTY_INVITE_REQUEST", "PARTY_INVITE_CANCEL", "GUILD_INVITE_REQUEST", "GUILD_INVITE_CANCEL"}) do
    -- Some older builds do not expose all invite events.
    if not C_EventUtils or type(C_EventUtils.IsEventValid) ~= "function" or publicCall(C_EventUtils.IsEventValid, event) == true then
      pcall(events.RegisterEvent, events, event)
    end
  end
  events:SetScript("OnEvent", function(_, event, inviter, guildName)
    if event == "ADDON_LOADED" then
      if inviter=="Blizzard_StaticPopup" or inviter=="Blizzard_StaticPopup_Game" then General:InitializeDestroyConfirmation() end
    elseif event == "MERCHANT_SHOW" then General:StartJunkSale()
    elseif event == "MERCHANT_CLOSED" then General:CloseMerchantWork()
    elseif event == "PARTY_INVITE_REQUEST" then General:QueueInviteDecline("party", inviter)
    elseif event == "GUILD_INVITE_REQUEST" then General:QueueInviteDecline("guild", inviter, guildName)
    elseif event == "PARTY_INVITE_CANCEL" then General:CancelInviteDecline("party")
    elseif event == "GUILD_INVITE_CANCEL" then General:CancelInviteDecline("guild")
    elseif event == "PLAYER_ENTERING_WORLD" then
      General:CloseMerchantWork(); General:CancelInviteDecline("party"); General:CancelInviteDecline("guild"); General:ApplyCenterTextScale()
    end
  end)
end

-- Shared settings action for the General grid and Convenience detail page.
-- Preserve the existing cancellation side effects when an option is turned OFF.
function General:SetConvenienceEnabled(key,on)
  self:GetDB()[key]=on
  if key=="chatEnhancement" and KHQOL.modules.chatEnhancement then KHQOL.modules.chatEnhancement:ApplySettings() end
  if not on then
    if key=="autoSellJunk" then self:CancelJunkSale()
    elseif key=="autoRepair" then CancelDeferred(self.merchantVisit)
    elseif key=="declinePartyInvites" then self:CancelInviteDecline("party")
    elseif key=="declineGuildInvites" then self:CancelInviteDecline("guild") end
  end
end
function General:BuildGlobalSettings(parent,y)
  local b=KHQOL.UI:CreateBuilder(parent,y)
  b:Section("전역 설정")
  b:Slider("중앙 알림 텍스트 크기", 75, 200, 5, function() return General:GetDB().centerTextScale end, function(value) General:GetDB().centerTextScale=value; General:ApplyCenterTextScale() end, function(value) return value .. "%" end, nil, "화면 중앙에 표시되는 오류 및 진행 메시지의 크기입니다.")
  return b.y
end

function General:BuildSettings(parent,y)
  return KHQOL.modules.generalConvenience:BuildSettings(parent,y)
end
