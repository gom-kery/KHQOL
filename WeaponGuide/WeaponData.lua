-- Static data deliberately separates Classic references from Forever-verified data.
-- Do not change verified to true without an in-game Forever Beta verification.
local ADDON, KHQOL = ...
local FWG = KHQOL.modules.weaponGuide
FWG.WeaponData = {}

local function weapon(key, name, subclass, skillLine, spellID, verified, source)
  return { key = key, name = name, itemClassID = 2, itemSubClassID = subclass, skillLineID = skillLine,
    spellID = spellID, source = source or "classic-reference", verified = verified or false }
end

-- Enum.ItemWeaponSubclass values are stable Mainline item metadata values.
FWG.WEAPONS = {
  AXE_1H = weapon("AXE_1H", "One-Handed Axe", 0, 44, 196, true, "forever-beta-public-reference"),
  AXE_2H = weapon("AXE_2H", "Two-Handed Axe", 1, 172, 197, true, "forever-beta-public-reference"),
  BOW = weapon("BOW", "Bow", 2, 45, 264, true, "forever-beta-public-reference"),
  GUN = weapon("GUN", "Gun", 3, 46, 266, true, "forever-beta-public-reference"),
  MACE_1H = weapon("MACE_1H", "One-Handed Mace", 4, 54, 198, true, "forever-beta-public-reference"),
  MACE_2H = weapon("MACE_2H", "Two-Handed Mace", 5, 160, 199, true, "forever-beta-public-reference"),
  POLEARM = weapon("POLEARM", "Polearm", 6, 229, 200, true, "forever-beta-public-reference"),
  SWORD_1H = weapon("SWORD_1H", "One-Handed Sword", 7, 43, 201, true, "forever-beta-public-reference"),
  -- Verified against Forever's item/spell data: spell 202 is the 2H Sword proficiency.
  SWORD_2H = weapon("SWORD_2H", "Two-Handed Sword", 8, 55, 202, true, "forever-beta-public-reference"),
  STAFF = weapon("STAFF", "Staff", 10, 136, 227, true, "forever-beta-public-reference"),
  FIST = weapon("FIST", "Fist Weapon", 13, 473, 15590, true, "forever-beta-public-reference"),
  DAGGER = weapon("DAGGER", "Dagger", 15, 173, 1180, true, "forever-beta-public-reference"),
  THROWN = weapon("THROWN", "Thrown", 16, 176, 2567, true, "forever-beta-public-reference"),
  CROSSBOW = weapon("CROSSBOW", "Crossbow", 18, 226, 5011, true, "forever-beta-public-reference"),
}

FWG.WeaponBySubclass = {}
for key, entry in pairs(FWG.WEAPONS) do FWG.WeaponBySubclass[entry.itemSubClassID] = entry end

-- Forever Beta public-reference class eligibility. Wands are excluded because no Weapon Master teaches them.
local function set(...) local out = {}; for i = 1, select("#", ...) do out[select(i, ...)] = true end; return out end
FWG.CLASS_WEAPONS = {
  WARRIOR = set("AXE_1H", "AXE_2H", "BOW", "GUN", "MACE_1H", "MACE_2H", "POLEARM", "SWORD_1H", "SWORD_2H", "STAFF", "FIST", "DAGGER", "THROWN", "CROSSBOW"),
  PALADIN = set("AXE_1H", "AXE_2H", "MACE_1H", "MACE_2H", "POLEARM", "SWORD_1H", "SWORD_2H"),
  HUNTER = set("AXE_1H", "AXE_2H", "BOW", "GUN", "POLEARM", "SWORD_1H", "SWORD_2H", "STAFF", "FIST", "DAGGER", "THROWN", "CROSSBOW"),
  ROGUE = set("AXE_1H", "BOW", "GUN", "MACE_1H", "SWORD_1H", "FIST", "DAGGER", "THROWN", "CROSSBOW"),
  PRIEST = set("MACE_1H", "STAFF", "DAGGER"),
  SHAMAN = set("AXE_1H", "AXE_2H", "MACE_1H", "MACE_2H", "STAFF", "FIST", "DAGGER"),
  MAGE = set("SWORD_1H", "STAFF", "DAGGER"),
  WARLOCK = set("SWORD_1H", "STAFF", "DAGGER"),
  DRUID = set("MACE_1H", "MACE_2H", "POLEARM", "STAFF", "DAGGER", "FIST"),
}

FWG.ClassWeaponMeta = { source = "forever-beta-public-reference", verified = true }
FWG.ClassWeaponVerification = {}
for classToken, weapons in pairs(FWG.CLASS_WEAPONS) do
  FWG.ClassWeaponVerification[classToken] = {}
  for weaponKey in pairs(weapons) do
    FWG.ClassWeaponVerification[classToken][weaponKey] = { verified = true, source = "forever-beta-public-reference" }
  end
end

-- Locations and NPC names are known Classic references only. Coordinates are intentionally nil:
-- no Forever uiMapID/coordinate pair has been verified for this release.
local function trainer(faction, city, area, npc, weapons)
  return { faction = faction, city = city, area = area, npc = npc, weapons = weapons,
    mapID = nil, x = nil, y = nil, npcID = nil, source = "forever-beta-public-reference", verified = true }
end
FWG.TRAINERS = {
  trainer("Alliance", "다르나서스", "전사의 정원", "Ilyenia Moonfire", set("BOW", "DAGGER", "FIST", "STAFF", "THROWN")),
  trainer("Alliance", "아이언포지", "군사 구역", "Bixi Wobblebonk", set("CROSSBOW", "DAGGER", "THROWN")),
  trainer("Alliance", "아이언포지", "군사 구역", "Buliwyf Stonehand", set("FIST", "GUN", "AXE_1H", "AXE_2H", "MACE_1H", "MACE_2H")),
  trainer("Alliance", "스톰윈드", "상업 지구", "Woo Ping", set("CROSSBOW", "DAGGER", "SWORD_1H", "SWORD_2H", "POLEARM", "STAFF")),
  trainer("Horde", "오그리마", "명예의 골짜기", "Hanashi", set("BOW", "AXE_1H", "AXE_2H", "STAFF", "THROWN")),
  trainer("Horde", "오그리마", "명예의 골짜기", "Sayoc", set("BOW", "DAGGER", "FIST", "AXE_1H", "AXE_2H", "STAFF", "THROWN")),
  trainer("Horde", "썬더 블러프", "낮은 길", "Ansekhwa", set("GUN", "MACE_1H", "MACE_2H", "STAFF")),
  { faction = "Horde", city = "언더시티", area = "전쟁 지구", npc = "Archibald", npcID = 11870,
    weapons = set("CROSSBOW", "DAGGER", "SWORD_1H", "SWORD_2H", "POLEARM"), mapID = nil, x = nil, y = nil,
    source = "forever-beta-public-reference", verified = true },
}

FWG.TrainingCostData = {
  default = { copper = 1000, requiredLevel = 1, source = "forever-beta-public-reference", verified = true },
  SWORD_2H = { copper = 1000, requiredLevel = 1, source = "forever-beta-public-reference", verified = true },
  POLEARM = { copper = 10000, requiredLevel = 20, source = "forever-beta-public-reference", verified = true },
}

function FWG:GetVerifiedTrainers(faction, weaponKey)
  local found = {}
  for _, trainerInfo in ipairs(self.TRAINERS) do
    if trainerInfo.verified and trainerInfo.faction == faction and trainerInfo.weapons[weaponKey] then
      found[#found + 1] = trainerInfo
    end
  end
  return found
end
