local _,K=...
local M=K.modules.generalConvenience
local call,public=K.PublicCall,K.IsPublicValue
-- Inventory IDs, not item-required character levels. Ammo is intentionally
-- excluded so its native stack count remains untouched.
local slots={
  [1]="Head",[2]="Neck",[3]="Shoulder",[4]="Shirt",[5]="Chest",[6]="Waist",
  [7]="Legs",[8]="Feet",[9]="Wrist",[10]="Hands",[11]="Finger0",[12]="Finger1",
  [13]="Trinket0",[14]="Trinket1",[15]="Back",[16]="MainHand",[17]="SecondaryHand",
  [18]="Ranged",[19]="Tabard",
}
function M:EquipmentLevelsSupported()
  return type(GetInventoryItemLink)=="function" and type(GetInventoryItemID)=="function" and
    (type(C_Item and C_Item.GetDetailedItemLevelInfo or GetDetailedItemLevelInfo)=="function" or
     type(C_Item and C_Item.GetItemInfo or GetItemInfo)=="function")
end
function M:RefreshEquipmentSlot(slot,request)
  local name=slots[slot];if not name then return end
  local button=_G["Character"..name.."Slot"];if not button then return end
  local label=button.khqolEquipmentLevel
  if label then label:Hide();label:SetText("") end
  self.equipmentPending=self.equipmentPending or {}
  self.equipmentPending[slot]=nil
  if not self:IsEnabled() or not self:GetDB().equipmentLevels or not self:EquipmentLevelsSupported() then return end
  local id=call(GetInventoryItemID,"player",slot)
  if not self.IsNumber(id) or id<=0 then return end
  local link=call(GetInventoryItemLink,"player",slot)
  if not public(link) or type(link)~="string" or link=="" then link=nil end
  local level
  if link then
    local detailed=C_Item and C_Item.GetDetailedItemLevelInfo or GetDetailedItemLevelInfo
    if type(detailed)=="function" then level=call(detailed,link)
    else
      local _,_,_,itemLevel=call(C_Item and C_Item.GetItemInfo or GetItemInfo,link)
      level=itemLevel
    end
  end
  if not self.IsNumber(level) or level<=0 then
    self.equipmentPending[slot]=id
    self.equipmentRequests=self.equipmentRequests or {}
    if request~=false and not self.equipmentRequests[id] and C_Item and type(C_Item.RequestLoadItemDataByID)=="function" then
      self.equipmentRequests[id]=true;call(C_Item.RequestLoadItemDataByID,id)
    end
    return
  end
  if not label then
    if call(InCombatLockdown)==true then self.equipmentLayoutPending=true;return end
    label=button:CreateFontString(nil,"OVERLAY",nil,7)
    label:SetFont((K.modules.clock and K.modules.clock.FONT_PATH) or STANDARD_TEXT_FONT,12,"OUTLINE")
    local icon=button.icon or button.Icon or _G["Character"..name.."SlotIconTexture"] or button
    label:SetPoint("TOP",icon,"TOP",0,-2);label:SetJustifyH("CENTER")
    label:SetTextColor(1,1,1,1);label:SetShadowColor(0,0,0,1);label:SetShadowOffset(1,-1)
    button.khqolEquipmentLevel=label
  end
  label:SetText(tostring(math.floor(level+.5)));label:Show()
end
function M:RefreshEquipmentLevels()
  self.equipmentPending={}
  for slot in pairs(slots) do self:RefreshEquipmentSlot(slot) end
end
function M:InstallEquipmentLevels()
  if CharacterFrame and not self.equipmentCharacterHooked then
    self.equipmentCharacterHooked=true
    CharacterFrame:HookScript("OnShow",function() M:RefreshEquipmentLevels() end)
  end
  if self.equipmentEvents then return end
  self.equipmentEvents=CreateFrame("Frame")
  for _,event in ipairs({"ADDON_LOADED","PLAYER_ENTERING_WORLD","PLAYER_EQUIPMENT_CHANGED","GET_ITEM_INFO_RECEIVED","ITEM_DATA_LOAD_RESULT","PLAYER_REGEN_ENABLED"}) do
    pcall(self.equipmentEvents.RegisterEvent,self.equipmentEvents,event)
  end
  self.equipmentEvents:SetScript("OnEvent",function(_,event,arg)
    if event=="ADDON_LOADED" then M:InstallEquipmentLevels()
    elseif event=="PLAYER_EQUIPMENT_CHANGED" then
      if K.IsPublicNumber(arg) then M:RefreshEquipmentSlot(arg) end
    elseif event=="PLAYER_ENTERING_WORLD" then M:RefreshEquipmentLevels()
    elseif event=="PLAYER_REGEN_ENABLED" then
      if M.equipmentLayoutPending then M.equipmentLayoutPending=nil;M:RefreshEquipmentLevels() end
    elseif M.IsNumber(arg) then
      if M.equipmentRequests then M.equipmentRequests[arg]=nil end
      local retry={}
      for slot,id in pairs(M.equipmentPending or {}) do if id==arg then retry[#retry+1]=slot end end
      -- Read the current slot/link again: a stale item callback must never put
      -- the previous item's level over a replacement or an empty slot.
      for _,slot in ipairs(retry) do M:RefreshEquipmentSlot(slot,false) end
    end
  end)
end
local initialize,apply=M.Initialize,M.ApplySettings
function M:Initialize() initialize(self);self:InstallEquipmentLevels() end
function M:ApplySettings() apply(self);self:InstallEquipmentLevels();self:RefreshEquipmentLevels() end
