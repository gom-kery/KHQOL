local ADDON, KHQOL = ...
local FWG = KHQOL.modules.weaponGuide

FWG.VERSION = "0.2.2-beta"
FWG.SkillState = { KNOWN = "KNOWN", UNLEARNED = "UNLEARNED", UNKNOWN = "UNKNOWN" }
FWG.state = { knownSkills = {}, skillScanAvailable = false, classToken = nil, faction = nil, level = nil }

local function plain(value)
  return not (type(issecretvalue) == "function" and issecretvalue(value))
end

function FWG:Print(message)
  DEFAULT_CHAT_FRAME:AddMessage("|cffd9b300ForeverWeaponGuide:|r " .. tostring(message))
end

function FWG:RefreshCharacterState()
  local _, classToken = UnitClass("player")
  local faction = UnitFactionGroup("player")
  local level = UnitLevel("player")
  self.state.classToken = plain(classToken) and classToken or nil
  self.state.faction = plain(faction) and faction or nil
  self.state.level = plain(level) and level or nil
  self:ScanKnownSkills()
end

-- Forever's currently reported Mainline API does not document a weapon-skill list.
-- Legacy support is feature-detected. Absence means UNKNOWN, never UNLEARNED.
function FWG:ScanKnownSkills()
  self.state.knownSkills = {}
  self.state.skillScanAvailable = false
  -- Forever 1.60.1 exposes proficiency spells through the modern spell-book API.
  -- A direct spell query is not based on IsUsableItem and safely distinguishes known from unlearned.
  if C_SpellBook and type(C_SpellBook.IsSpellKnown) == "function" then
    local queried = false
    for key, weaponInfo in pairs(self.WEAPONS) do
      if weaponInfo.verified and weaponInfo.spellID then
        local known = C_SpellBook.IsSpellKnown(weaponInfo.spellID)
        if plain(known) and type(known) == "boolean" then
          self.state.knownSkills[key] = known
          queried = true
        end
      end
    end
    if queried then self.state.skillScanAvailable = true; return end
  end
  if type(GetNumSkillLines) ~= "function" or type(GetSkillLineInfo) ~= "function" then return end
  local count = GetNumSkillLines()
  if type(count) ~= "number" then return end
  local names = {}
  for _, weaponInfo in pairs(self.WEAPONS) do
    -- Skill-line labels are localized. Prefer the client-provided subtype label,
    -- with English only as a conservative fallback for clients without that API.
    local localized = type(GetItemSubClassInfo) == "function" and GetItemSubClassInfo(2, weaponInfo.itemSubClassID)
    names[localized or weaponInfo.name] = weaponInfo.key
  end
  for index = 1, count do
    local name, header, _, rank, _, _, maxRank = GetSkillLineInfo(index)
    if not header and plain(name) and names[name] and type(rank) == "number" and type(maxRank) == "number" then
      -- A visible skill line (including rank 0/low rank) is proof it is already learned.
      self.state.knownSkills[names[name]] = true
    end
  end
  self.state.skillScanAvailable = true
end

function FWG:GetSkillState(weaponKey)
  if not self.state.skillScanAvailable then return self.SkillState.UNKNOWN end
  if self.state.knownSkills[weaponKey] == true then return self.SkillState.KNOWN end
  -- This is only safe when the client has supplied a complete skill-line list.
  return self.SkillState.UNLEARNED
end

function FWG:IsClassEligible(weaponKey)
  local entries = self.CLASS_WEAPONS[self.state.classToken]
  local verification = self.ClassWeaponVerification[self.state.classToken]
  local record = verification and verification[weaponKey]
  return entries and entries[weaponKey] and record and record.verified or false
end

function FWG:DecisionForItem(itemID)
  if _G.KHQOL and _G.KHQOL.db and not _G.KHQOL:GetEnabled("weaponGuide") then return nil, "module-disabled" end
  local _, _, _, _, _, _, _, _, equipLoc, _, _, classID, subclassID = C_Item.GetItemInfo(itemID)
  if not classID or classID ~= 2 or not subclassID then return nil, "not-weapon" end
  local weaponInfo = self.WeaponBySubclass[subclassID]
  if not weaponInfo then return nil, "unsupported-subclass" end
  if not weaponInfo.verified then return nil, "weapon-data-unverified" end
  if not self:IsClassEligible(weaponInfo.key) then return nil, "class-ineligible-or-unverified" end
  local skillState = self:GetSkillState(weaponInfo.key)
  if skillState ~= self.SkillState.UNLEARNED then return nil, "skill-" .. string.lower(skillState) end
  local trainers = self:GetVerifiedTrainers(self.state.faction, weaponInfo.key)
  if #trainers == 0 then return nil, "no-verified-trainer" end
  return { itemID = itemID, weapon = weaponInfo, trainers = trainers, cost = self.TrainingCostData[weaponInfo.key] or self.TrainingCostData.default, equipLoc = equipLoc }, "show"
end

function FWG:FormatMoney(copper)
  if type(copper) ~= "number" then return "확인 필요" end
  local gold, remainder = math.floor(copper / 10000), copper % 10000
  local silver, c = math.floor(remainder / 100), remainder % 100
  local parts = {}
  if gold > 0 then parts[#parts + 1] = gold .. "골드" end
  if silver > 0 then parts[#parts + 1] = silver .. "실버" end
  if c > 0 or #parts == 0 then parts[#parts + 1] = c .. "코퍼" end
  return table.concat(parts, " ")
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_LEVEL_UP")
frame:RegisterEvent("SKILL_LINES_CHANGED")
frame:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_LOGIN" then
    ForeverWeaponGuideDB = type(ForeverWeaponGuideDB) == "table" and ForeverWeaponGuideDB or { version = 1, debug = false, fontSize = 13 }
    if ForeverWeaponGuideDB.debug == nil then ForeverWeaponGuideDB.debug = false end
    if ForeverWeaponGuideDB.fontSize == nil then ForeverWeaponGuideDB.fontSize = 13 end
  end
  FWG:RefreshCharacterState()
  if FWG.RefreshMapPins then FWG:RefreshMapPins() end
end)

SLASH_FOREVERWEAPONGUIDE1 = "/fwg"
SlashCmdList.FOREVERWEAPONGUIDE = function(input)
  local command = (input or ""):lower():match("^%s*(%S*)")
  if command == "" or command == "status" then
    FWG:Print("v" .. FWG.VERSION .. "; class=" .. tostring(FWG.state.classToken) .. "; faction=" .. tostring(FWG.state.faction) .. "; skill API=" .. (FWG.state.skillScanAvailable and "available" or "unavailable"))
  elseif command == "scan" then
    FWG:RefreshCharacterState(); FWG:Print("무기 숙련 캐시를 다시 조회했습니다.")
  elseif command == "debug" then
    ForeverWeaponGuideDB.debug = not ForeverWeaponGuideDB.debug; FWG:Print("디버그: " .. (ForeverWeaponGuideDB.debug and "ON" or "OFF"))
  elseif command == "trainers" then
    local count = 0; for _, t in ipairs(FWG.TRAINERS) do if t.faction == FWG.state.faction and t.verified then count = count + 1; FWG:Print(t.city .. " - " .. t.npc) end end
    if count == 0 then FWG:Print("현재 진영에는 Forever 검증 완료 무기전문가 데이터가 없습니다.") end
  elseif command == "item" then
    local _, link = GameTooltip:GetItem(); local itemID = link and C_Item.GetItemInfoInstant(link)
    local result, reason
    if itemID then result, reason = FWG:DecisionForItem(itemID) else reason = "no-item" end
    FWG:Print("ItemID=" .. tostring(itemID) .. "; FinalDecision=" .. (result and "SHOW" or "HIDE") .. "; Reason=" .. tostring(reason))
  elseif command == "test" then
    FWG:Print("정적 안전 모드: 미검증 Forever 데이터는 표시하지 않습니다. /fwg status로 API 상태를 확인하세요.")
  else
    FWG:Print("/fwg [status|scan|debug|test|trainers|item]")
  end
end
