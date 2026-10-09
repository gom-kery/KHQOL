local ADDON, KHQOL = ...
local FR = KHQOL.modules.range

FR.defaults = {
  rangeSpellID = nil,
  rangeSpellName = nil,
  hunterMeleeSpellID = nil,
  shape = "\226\150\160",
  length = 1,
  stateText = false,
  stateTexts = {available="공격 가능",unavailable="공격 불가",unknown="판정 불가"},
  size = 32,
  x = 0,
  y = 120,
  locked = true,
  deadZoneEnabled = true,
  hunterMeleeAsAttack = true,
  mouseover = {
    enabled = true,
    position = "BELOW",
    fontSize = 22,
    x = 0,
    y = -8,
    availableText = "공격 가능",
    unavailableText = "공격 불가",
  },
  colors = {
    GREEN = { 0.15, 1.00, 0.20, 1.00 },
    RED = { 1.00, 0.18, 0.18, 1.00 },
    ORANGE = { 1.00, 0.55, 0.05, 1.00 },
  },
  outline = {
    enabled = true,
    color = { 0, 0, 0, 1 },
    thickness = 1,
  },
}

function FR:LimitMouseoverText(value)
  local letters={}
  for letter in tostring(value or ""):gmatch("[%z\1-\127\194-\244][\128-\191]*") do
    letters[#letters+1]=letter; if #letters==8 then break end
  end
  return table.concat(letters)
end
local function coordinate(value,default,min,max)
  value=tonumber(value)
  if not value or value~=value or value==math.huge or value==-math.huge then value=default end
  return math.max(min,math.min(max,value))
end
function FR:InitializeDB()
  if KHQOL.InitializeProfiles then KHQOL:InitializeProfiles() end
  if type(FRangeDB) ~= "table" then FRangeDB = {} end
  local old=FRangeDB.mouseover
  if type(old)=="table" and old.gap~=nil then
    local gap=coordinate(old.gap,8,0,30)
    if old.position=="LEFT" then old.x=coordinate(old.x,0,-500,500)-gap
    else old.y=coordinate(old.y,0,-500,500)-gap end
    old.gap=nil -- one-time fold into the matching anchor offset
  end
  KHQOL.MergeDefaults(FRangeDB, self.defaults)
  local options=FRangeDB.mouseover
  options.x=coordinate(options.x,0,-100,200); options.y=coordinate(options.y,-8,-100,100)
  options.availableText=self:LimitMouseoverText(options.availableText)
  options.unavailableText=self:LimitMouseoverText(options.unavailableText)
  -- The repeat-length control was removed in v0.1.6. Keep the indicator
  -- consistent for existing characters that had a custom saved length.
  FRangeDB.length = 1
  self.db = FRangeDB
end

function FR:ResetDB()
  FRangeDB = KHQOL.MergeDefaults({}, self.defaults)
  self.db = FRangeDB
  if self.RefreshDisplay then self:RefreshDisplay(true) end
  if self.UpdateSettings then self:UpdateSettings() end
end

function FR:SetColor(key, r, g, b, a)
  local color = self.db.colors[key]
  if not color then return end
  color[1], color[2], color[3], color[4] = r, g, b, a or 1
  self:RefreshDisplay(true)
end
