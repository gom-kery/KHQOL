local K=_G.KHQOL
local M=K.modules.generalConvenience
local call=K.PublicCall
local function integer(n,min,max)
  return K.IsPublicNumber(n) and n%1==0 and n>=min and n<=max
end

function M:IsCharacterBag(bag)
  return integer(bag,0,4)
end

function M:ReadBagSlot(bag,slot)
  if not self:IsCharacterBag(bag) or not integer(slot,1,1000) then return end
  local status,info=K.ReadPublicAPI(C_Container and C_Container.GetContainerItemInfo,bag,slot)
  if status~="ok" then return end
  if info==nil then return nil,true end
  if type(info)~="table" then return end
  local id,link,count,locked=call(function()
    return info.itemID,info.hyperlink,info.stackCount,info.isLocked
  end)
  if not integer(id,1,2147483647) or type(link)~="string" or link=="" or not integer(count,1,1000000) then return end
  return {id=id,link=link,count=count,locked=locked,bag=bag,slot=slot},true
end

function M:GetProtectedItems()
  local db=K.db
  if not db then return end
  if type(db.globalData)~="table" then db.globalData={} end
  local global=db.globalData
  if type(global.protectedBagItems)~="table" then global.protectedBagItems={} end
  return global.protectedBagItems
end

function M:IsProtectedBagItem(id)
  if not integer(id,1,2147483647) then return false end
  local items=K.db and K.db.globalData and K.db.globalData.protectedBagItems
  return type(items)=="table" and items[id]~=nil
end

function M:NotifyBagItem(message)
  if UIErrorsFrame and UIErrorsFrame.AddMessage then
    UIErrorsFrame:AddMessage(message,1,.65,.15)
  elseif DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("KHQOL · "..message)
  end
end

function M:SetBagItemProtection(id,link)
  if not integer(id,1,2147483647) then return end
  if link~=nil and (type(link)~="string" or tonumber(link:match("|Hitem:(%d+)"))~=id) then return end
  local items=self:GetProtectedItems()
  if not items then return end
  local label=link or items[id]
  if not label then return end
  items[id]=link
  if self.ValidateTrashDialog then self:ValidateTrashDialog() end
  if self.WarnProtectedMail then self:WarnProtectedMail() end
  if self.protectionPanel then K.UI:Refresh(self.protectionPanel) end
  if GameTooltip and GameTooltip:IsShown() then
    local owner=call(GameTooltip.GetOwner,GameTooltip)
    local bag,slot=self:BagItemButtonSlot(owner)
    local item=self:ReadBagSlot(bag,slot)
    if item and item.id==id then
      call(GameTooltip.SetBagItem,GameTooltip,bag,slot)
      GameTooltip:Show()
    end
  end
  local prefix=link and "아이템 보호 적용 · " or "아이템 보호 해제 · "
  self:NotifyBagItem(prefix..(label:match("|h(%b[])|h") or tostring(id)))
  if UIErrorsFrame and UIErrorsFrame.AddMessage and DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("KHQOL · "..prefix..label)
  end
end

-- Both native and Baganator live buttons resolve a container and slot.
-- Require a recognized live bag ancestor, so cached characters, the bank,
-- equipped gear and lookalike tooltip buttons cannot enroll a bag item.
function M:BagItemButtonSlot(button)
  if not K.WindowLayers:Readable(button) or call(button.IsVisible,button)~=true then return end
  local bag=call(button.GetBagID,button)
  if bag==nil then bag=call(function() return button.BGR and button.BGR.itemLocation and button.BGR.itemLocation.bagID end) end
  local slot=call(button.GetID,button)
  if not self:IsCharacterBag(bag) or not integer(slot,1,1000) then return end
  local parent=call(button.GetParent,button)
  for _=1,12 do
    if not parent or parent==UIParent or not K.WindowLayers:Readable(parent) then return end
    local name=call(parent.GetName,parent)
    if type(name)=="string" then
      if name=="ContainerFrameCombinedBags" or name:match("^ContainerFrame%d+$") then return bag,slot end
      if name:match("^Baganator_SingleViewBackpackViewFrame") or name:match("^Baganator_CategoryViewBackpackViewFrame") then
        if call(function() return parent.isLive end)==true then return bag,slot end
        return
      end
    end
    parent=call(parent.GetParent,parent)
  end
end

function M:ToggleHoveredBagProtection()
  if K.PositionEditor.active or not K.WindowLayers:OutsideCombat() then
    self:NotifyBagItem("전투 또는 위치 편집 중에는 아이템 보호를 변경할 수 없습니다.");return
  end
  if call(CursorHasItem)~=false then
    self:NotifyBagItem("커서의 아이템을 가방에 내려놓은 뒤 보호를 변경해 주세요.");return
  end
  local foci=call(GetMouseFoci)
  local button=type(foci)=="table" and foci[1] or call(GetMouseFocus)
  local bag,slot
  for _=1,4 do
    if not K.WindowLayers:Readable(button) then break end
    bag,slot=self:BagItemButtonSlot(button)
    if bag then break end
    button=call(button.GetParent,button)
  end
  local item=self:ReadBagSlot(bag,slot)
  if not item then self:NotifyBagItem("캐릭터 가방의 아이템 위에서 보호 단축키를 누르세요.");return end
  local link
  if not self:IsProtectedBagItem(item.id) then link=item.link end
  self:SetBagItemProtection(item.id,link)
end

function M:WarnProtectedMail()
  if not SendMailFrame or call(SendMailFrame.IsVisible,SendMailFrame)~=true then self.warnedMail=nil;return end
  local found={}
  for index=1,ATTACHMENTS_MAX_SEND or 12 do
    local _,id=call(GetSendMailItem,index)
    if not integer(id,1,2147483647) then
      local link=call(GetSendMailItemLink,index)
      id=type(link)=="string" and tonumber(link:match("|Hitem:(%d+)")) or nil
    end
    if self:IsProtectedBagItem(id) then found[id]=true end
  end
  for id in pairs(found) do
    if not self.warnedMail or not self.warnedMail[id] then
      self:NotifyBagItem("보호 아이템이 우편에 첨부되었습니다. 발송 전에 직접 제거하세요.")
      break
    end
  end
  self.warnedMail=found
end

function M:InitializeBagProtection()
  if self.protectionEventFrame then return end
  local events=CreateFrame("Frame")
  self.protectionEventFrame=events
  for _,event in ipairs({"MAIL_SEND_INFO_UPDATE","MAIL_CLOSED"}) do pcall(events.RegisterEvent,events,event) end
  events:SetScript("OnEvent",function(_,event)
    if event=="MAIL_CLOSED" then self.warnedMail=nil else self:WarnProtectedMail() end
  end)
  local tooltipType=Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item
  if TooltipDataProcessor and type(TooltipDataProcessor.AddTooltipPostCall)=="function" and tooltipType then
    TooltipDataProcessor.AddTooltipPostCall(tooltipType,function(tooltip,data)
      if tooltip~=GameTooltip or type(data)~="table" or not K.IsPublicValue(data) then return end
      local id=call(function() return data.id end)
      if not self:IsProtectedBagItem(id) then return end
      local bag,slot=self:BagItemButtonSlot(call(tooltip.GetOwner,tooltip))
      local item=self:ReadBagSlot(bag,slot)
      if item and item.id==id then
        tooltip:AddLine("|TInterface\\Buttons\\LockButton-Locked-Up:15:15:0:0|t KHQOL 아이템 보호 · 같은 아이템 ID 전체",1,.79,.26)
      end
    end)
  end
end

BINDING_NAME_KHQOL_TOGGLE_BAG_ITEM_PROTECTION="가방 아이템 보호 / 해제"
function KHQOL_ToggleBagItemProtection() M:ToggleHoveredBagProtection() end
