local _, KHQOL = ...
local Tooltip = KHQOL.modules.tooltip
local WG = Tooltip.weaponGuide

WG.SkillState = { KNOWN = "KNOWN", UNLEARNED = "UNLEARNED", UNKNOWN = "UNKNOWN" }
WG.state = { knownSkills = {}, skillScanAvailable = false }

local function plain(value) return not (type(issecretvalue) == "function" and issecretvalue(value)) end

function WG:RefreshCharacterState()
  local _, classToken = UnitClass("player")
  self.state.classToken = plain(classToken) and classToken or nil
  local faction = UnitFactionGroup("player")
  self.state.faction = plain(faction) and faction or nil
  self:ScanKnownSkills()
end

function WG:ScanKnownSkills()
  self.state.knownSkills, self.state.skillScanAvailable = {}, false
  if C_SpellBook and type(C_SpellBook.IsSpellKnown) == "function" then
    local queried = false
    for key, weapon in pairs(self.WEAPONS) do
      if weapon.verified and weapon.spellID then
        local known = C_SpellBook.IsSpellKnown(weapon.spellID)
        if plain(known) and type(known) == "boolean" then self.state.knownSkills[key], queried = known, true end
      end
    end
    if queried then self.state.skillScanAvailable = true; return end
  end
  if type(GetNumSkillLines) ~= "function" or type(GetSkillLineInfo) ~= "function" then return end
  local names = {}
  for _, weapon in pairs(self.WEAPONS) do
    local localized = type(GetItemSubClassInfo) == "function" and GetItemSubClassInfo(2, weapon.itemSubClassID)
    names[localized or weapon.name] = weapon.key
  end
  for index = 1, GetNumSkillLines() do
    local name, header, _, rank, _, _, maxRank = GetSkillLineInfo(index)
    if not header and plain(name) and names[name] and type(rank) == "number" and type(maxRank) == "number" then self.state.knownSkills[names[name]] = true end
  end
  self.state.skillScanAvailable = true
end

function WG:GetSkillState(key)
  if not self.state.skillScanAvailable then return self.SkillState.UNKNOWN end
  return self.state.knownSkills[key] and self.SkillState.KNOWN or self.SkillState.UNLEARNED
end
function WG:IsClassEligible(key)
  local entries, verification = self.CLASS_WEAPONS[self.state.classToken], self.ClassWeaponVerification[self.state.classToken]
  return entries and entries[key] and verification and verification[key] and verification[key].verified or false
end
function WG:DecisionForItem(itemID)
  local _, _, _, _, _, _, _, _, equipLoc, _, _, classID, subclassID = C_Item.GetItemInfo(itemID)
  if classID ~= 2 or not subclassID then return nil end
  local weapon = self.WeaponBySubclass[subclassID]
  if not weapon or not weapon.verified or not self:IsClassEligible(weapon.key) or self:GetSkillState(weapon.key) ~= self.SkillState.UNLEARNED then return nil end
  local trainers = self:GetVerifiedTrainers(self.state.faction, weapon.key)
  if #trainers == 0 then return nil end
  return { weapon = weapon, trainers = trainers, cost = self.TrainingCostData[weapon.key] or self.TrainingCostData.default, equipLoc = equipLoc }
end
function WG:FormatMoney(copper)
  if type(copper) ~= "number" then return "확인 필요" end
  local gold, rest = math.floor(copper / 10000), copper % 10000
  local silver, coin = math.floor(rest / 100), rest % 100; local parts = {}
  if gold > 0 then parts[#parts + 1] = gold .. "골드" end
  if silver > 0 then parts[#parts + 1] = silver .. "실버" end
  if coin > 0 or #parts == 0 then parts[#parts + 1] = coin .. "코퍼" end
  return table.concat(parts, " ")
end
function WG:IsEnabled() return Tooltip:GetDB().weaponGuide ~= false end
function WG:GetLines(context)
  if not context.itemID then return nil end
  local decision = self:DecisionForItem(context.itemID)
  if not decision then return nil end
  local db, lines = Tooltip:GetDB(), { "|cffff4040무기 숙련 미습득|r - 비용: " .. self:FormatMoney(decision.cost.copper) }
  local level = decision.cost.requiredLevel and ("요구 레벨: " .. decision.cost.requiredLevel) or "요구 레벨: 확인 필요"
  for index, trainer in ipairs(decision.trainers) do
    lines[#lines + 1] = "|cffffd100무기 전문가:|r " .. trainer.city .. " - " .. trainer.npc
    if trainer.mapID and trainer.x and trainer.y then lines[#lines + 1] = string.format("|cffb0b0b0%.1f, %.1f|r", trainer.x * 100, trainer.y * 100) end
  end
  lines[#lines + 1] = level
  return lines
end
Tooltip:RegisterProvider("weaponGuide", WG)

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN"); events:RegisterEvent("PLAYER_ENTERING_WORLD"); events:RegisterEvent("PLAYER_LEVEL_UP"); events:RegisterEvent("SKILL_LINES_CHANGED")
events:SetScript("OnEvent", function() WG:RefreshCharacterState() end)
