local ADDON, KHQOL = ...
local FWG = KHQOL.modules.weaponGuide

local RED, GOLD, WHITE, GREY = "|cffff4040", "|cffffd100", "|cffffffff", "|cffb0b0b0"

local function addLine(tooltip, text, wrap)
  tooltip:AddLine(text, 1, 1, 1, wrap)
  local name = tooltip:GetName()
  local line = name and _G[name .. "TextLeft" .. tooltip:NumLines()]
  if line then line:SetFont(STANDARD_TEXT_FONT, (ForeverWeaponGuideDB and ForeverWeaponGuideDB.fontSize) or 13, "") end
end

local function addGuide(tooltip, itemID)
  local decision = FWG:DecisionForItem(itemID)
  if not decision or tooltip.__FWGItemID == itemID then return end
  tooltip.__FWGItemID = itemID
  addLine(tooltip, RED .. "무기 숙련 미습득|r - " .. WHITE .. "비용 " .. FWG:FormatMoney(decision.cost.copper) .. "|r")
  local requirement = decision.cost.requiredLevel and ("요구 레벨: " .. decision.cost.requiredLevel) or "요구 레벨: 확인 필요"
  addLine(tooltip, GOLD .. "무기 전문가 위치|r - " .. WHITE .. requirement .. "|r")
  for _, trainer in ipairs(decision.trainers) do
    local line = "- " .. trainer.city .. " - " .. trainer.area .. " - " .. trainer.npc
    if trainer.mapID and trainer.x and trainer.y then line = line .. " " .. GREY .. string.format("(%.1f, %.1f)", trainer.x * 100, trainer.y * 100) .. "|r" end
    addLine(tooltip, WHITE .. line .. "|r", true)
  end
  tooltip:Show()
end

local function setFromTooltip(tooltip)
  tooltip.__FWGItemID = nil
  local _, link = tooltip:GetItem()
  local itemID = link and C_Item.GetItemInfoInstant(link)
  if itemID then addGuide(tooltip, itemID) end
end

if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item then
  TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
    tooltip.__FWGItemID = nil
    if data and data.id then addGuide(tooltip, data.id) end
  end)
else
  GameTooltip:HookScript("OnTooltipSetItem", setFromTooltip)
end
