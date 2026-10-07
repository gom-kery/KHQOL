local _, KHQOL = ...
local Tooltip = KHQOL.modules.tooltip
local IDs = {}

function IDs:IsEnabled()
  local mode = Tooltip:GetDB().idDisplayMode
  return mode == "ALWAYS" or (mode == "SHIFT" and IsShiftKeyDown and IsShiftKeyDown())
end

function IDs:GetLines(context)
  local db, lines = Tooltip:GetDB(), {}
  if context.itemID and db.itemID then lines[#lines + 1] = "Item ID: " .. context.itemID end
  if context.spellID and db.spellID then lines[#lines + 1] = "Spell ID: " .. context.spellID end
  if context.npcID and db.npcID then lines[#lines + 1] = "NPC ID: " .. context.npcID end
  if context.questID and db.questID then lines[#lines + 1] = "Quest ID: " .. context.questID end
  return lines
end

Tooltip:RegisterProvider("ids", IDs)
