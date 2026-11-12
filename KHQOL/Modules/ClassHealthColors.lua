local _,K=...
-- One exact palette for health fills only. Name/resource colors keep their
-- existing policy; no global Blizzard class-color table is mutated.
local hex={
  WARRIOR={"B38C63","DBAC79"},PALADIN={"DD7EA7","FF9ACD"},HUNTER={"9ABF68","BCE97F"},
  ROGUE={"E6DD5F","FFFF74"},PRIEST={"E6E6E6","FFFFFF"},SHAMAN={"0065C8","007BF4"},
  MAGE={"5FB8D8","74E0FF"},WARLOCK={"8575B5","A38FDD"},DRUID={"E67109","FF8A0B"},
}
local palettes={dark={},bright={}}
for token,values in pairs(hex) do
  for i,style in ipairs({"dark","bright"}) do
    local s=values[i]
    palettes[style][token]={tonumber(s:sub(1,2),16)/255,tonumber(s:sub(3,4),16)/255,tonumber(s:sub(5,6),16)/255}
  end
end
function K:GetClassHealthSettings()
  local modules=self.db.modules
  modules.unitFrames=type(modules.unitFrames)=="table" and modules.unitFrames or {}
  local db=modules.unitFrames
  db.classHealth=self.MergeDefaults(type(db.classHealth)=="table" and db.classHealth or {},{enabled=false,style="dark"},"types")
  if db.classHealth.style~="dark" and db.classHealth.style~="bright" then db.classHealth.style="dark" end
  return db.classHealth
end
function K:GetClassHealthColor(token)
  if not self.IsPublicValue(token) or type(token)~="string" then return end
  local db=self.db and self.db.modules and self.db.modules.unitFrames
  local cfg=db and db.classHealth
  if type(cfg)~="table" or cfg.enabled~=true then return end
  local palette=palettes[cfg.style=="bright" and "bright" or "dark"]
  if palette[token] then return unpack(palette[token]) end
end
function K:GetUnitClassToken(unit)
  local token=self.PublicCall(function()
    if type(UnitClassBase)=="function" then return (UnitClassBase(unit)) end
  end)
  if type(token)=="string" and token~="" then return token end
  token=self.PublicCall(function()
    if type(UnitClass)=="function" then local _,filename=UnitClass(unit);return filename end
  end)
  if type(token)=="string" and token~="" then return token end
end
function K:RefreshClassHealthColors()
  local unit=self.modules.unitFrames
  if unit and unit.ApplySettings then unit:ApplySettings() end
  local party=self.modules.partyFrames
  if party then
    if party.applied and party.RefreshAll then party:RefreshAll() end
    if party.RefreshLivePreview then party:RefreshLivePreview() end
  end
end
