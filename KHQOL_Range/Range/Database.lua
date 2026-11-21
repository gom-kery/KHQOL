local ADDON, KHQOL = ...
KHQOL = assert(_G.KHQOL, "Install and enable the KHQOL core addon.")
local FR = KHQOL.modules.range

FR.defaults = {
  displayMode = "skills",
  distance = {format="range",measurement="auto",unit="m",showUnit=true,size=28,maxMeters=80,bucketSize=4,singleStep=1,colorRanges={},nextColorRangeID=1,
    x=0,y=120,locked=true,
    thresholds={nearMax=5,deadMin=5,deadMax=8,rangedMin=5,rangedMax=30},
    colors={near={.15,1,.20,1},dead={1,.55,.05,1},ranged={.30,.75,1,1},far={1,.18,.18,1},neutral={.8,.8,.8,1}}},
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
    mode = "skills",
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
-- User-facing distances are integers in the selected m/yd unit. Keep the
-- effective thresholds identical to their displayed values after conversion.
function FR:NormalizeDistanceIntegers(d)
  d=d or self.db.distance
  local multiplier=d.unit=="yd" and 1 or .9144
  for key in pairs(self.defaults.distance.thresholds) do
    local value=math.max(0,math.min(200,math.floor(d.thresholds[key]*multiplier+.5)))
    d.thresholds[key]=value/multiplier
  end
  local cap=d.maxMeters/(d.unit=="yd" and .9144 or 1)
  d.maxMeters=math.max(45,math.min(80,math.floor(cap/5+.5)*5))*(d.unit=="yd" and .9144 or 1)
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
  if FRangeDB.displayMode~="distance" then FRangeDB.displayMode="skills" end
  FRangeDB.distance=KHQOL.MergeDefaults(type(FRangeDB.distance)=="table" and FRangeDB.distance or {},self.defaults.distance,"types")
  local d=FRangeDB.distance
  -- Retain fixed coordinates. The old cursor-target display becomes an
  -- independent numeric mouseover display, only once per saved profile.
  if d.cursor==true then
    FRangeDB.mouseover.enabled=true;FRangeDB.mouseover.mode="distance";FRangeDB.mouseover.position="CURSOR"
  end
  d.cursor=nil
  if d.format~="single" then d.format="range" end
  if d.measurement~="exact" then d.measurement="auto" end
  if d.unit~="yd" then d.unit="m" end
  d.size=math.floor(coordinate(d.size,28,20,40)+.5)
  d.maxMeters=coordinate(d.maxMeters,80,45*.9144,80)
  d.bucketSize=math.floor(coordinate(d.bucketSize,4,1,10)+.5)
  d.singleStep=math.floor(coordinate(d.singleStep,1,1,5)+.5)
  if self.Distance.NormalizeColorRanges then self.Distance:NormalizeColorRanges(d) end
  d.x=math.floor(coordinate(d.x,0,-3000,3000)+.5);d.y=math.floor(coordinate(d.y,120,-3000,3000)+.5)
  local t=d.thresholds
  for key,value in pairs(self.defaults.distance.thresholds) do t[key]=coordinate(t[key],value,0,d.unit=="yd" and 200 or 200/.9144) end
  t.deadMax=math.max(t.deadMin,t.deadMax)
  t.rangedMin=math.max(t.nearMax,t.rangedMin)
  t.rangedMax=math.max(t.rangedMin,t.rangedMax)
  self:NormalizeDistanceIntegers(d)
  for key,color in pairs(self.defaults.distance.colors) do
    for i=1,4 do d.colors[key][i]=coordinate(d.colors[key][i],color[i],0,1) end
  end
  local options=FRangeDB.mouseover
  if options.mode~="distance" then options.mode="skills" end
  if options.position~="LEFT" and options.position~="CURSOR" then options.position="BELOW" end
  options.fontSize=math.floor(coordinate(options.fontSize,22,10,40)+.5)
  options.x=coordinate(options.x,0,-100,200); options.y=coordinate(options.y,-8,-100,100)
  options.availableText=self:LimitMouseoverText(options.availableText)
  options.unavailableText=self:LimitMouseoverText(options.unavailableText)
  -- The repeat-length control was removed in v0.1.6. Keep the indicator
  -- consistent for existing characters that had a custom saved length.
  FRangeDB.length = 1
  -- Character-owned references: missing keys only; retain every legacy value.
  if FRangeDB.rangedSpellID==nil then FRangeDB.rangedSpellID=FRangeDB.rangeSpellID end
  if FRangeDB.rangedSpellName==nil then FRangeDB.rangedSpellName=FRangeDB.rangeSpellName end
  if select(2,UnitClass("player"))=="HUNTER" then
    if FRangeDB.meleeSpellID==nil then FRangeDB.meleeSpellID=FRangeDB.hunterMeleeSpellID end
    if FRangeDB.meleeSpellName==nil then FRangeDB.meleeSpellName=FRangeDB.hunterMeleeSpellName end
  end
  self.db = FRangeDB
  if self.Distance then self.Distance:Invalidate() end
end

function FR:ResetDB()
  FRangeDB = KHQOL.MergeDefaults({}, self.defaults)
  self:InitializeDB()
  if self.RefreshDisplay then self:RefreshDisplay(true) end
  if self.UpdateSettings then self:UpdateSettings() end
end

function FR:SetColor(key, r, g, b, a)
  local color = self.db.colors[key]
  if not color then return end
  color[1], color[2], color[3], color[4] = r, g, b, a or 1
  self:RefreshDisplay(true)
end
