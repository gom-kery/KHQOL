local _, KHQOL = ...
KHQOL.modules = {}
KHQOL.VERSION = "1.11.1.1"
KHQOL.FONT_PATH = "Interface\\AddOns\\KHQOL\\Fonts\\IsamanruLight.ttf"
KHQOL.PositionProviders = {}
KHQOL.ProfileHooks = {}

-- Shared KHQOL health colors; native resource colors remain game-owned.
KHQOL.ClassColors={
  WARRIOR={179/255,154/255,123/255},PALADIN={209/255,138/255,170/255},
  HUNTER={152/255,181/255,117/255},ROGUE={196/255,199/255,122/255},PRIEST={222/255,223/255,218/255},
  SHAMAN={93/255,143/255,199/255},MAGE={132/255,191/255,209/255},
  WARLOCK={161/255,138/255,186/255},DRUID={214/255,154/255,101/255},
}

-- Explicit count preserves intermediate/trailing nil, false and zero.
-- The status is separate from API results. Table fields still need a protected
-- module-specific reader; success here is not proof of untainted access.
local function pack(...) return {n=select("#",...),...} end
function KHQOL.IsPublicValue(value)
  if type(issecretvalue)~="function" then return true end
  local ok,secret=pcall(issecretvalue,value)
  return ok and not secret
end
-- Settings and public geometry only. Secret status-bar values use native widgets.
function KHQOL.IsPublicNumber(value)
  return KHQOL.IsPublicValue(value) and type(value)=="number" and value==value and math.abs(value)<math.huge
end
function KHQOL.ReadPublicAPI(fn,...)
  if type(fn)~="function" then return "missing" end
  for i=1,select("#",...) do
    if not KHQOL.IsPublicValue(select(i,...)) then return "unreadable" end
  end
  local result=pack(pcall(fn,...))
  if not result[1] then return "error" end
  for i=2,result.n do
    if not KHQOL.IsPublicValue(result[i]) then return "unreadable" end
  end
  return "ok",unpack(result,2,result.n)
end
function KHQOL.PublicCall(fn,...)
  local result=pack(KHQOL.ReadPublicAPI(fn,...))
  if result[1]=="ok" then return unpack(result,2,result.n) end
end

-- Key-binding labels are read by Blizzard's standard binding UI.
-- Keep the binding action itself in Todo.lua so every entry point shares
-- ForeverNote's single ToggleTodo implementation.
BINDING_HEADER_KHQOL = "KHQOL"
BINDING_NAME_KHQOL_TOGGLE_FOREVER_NOTE = "ForeverNote 열기 / 닫기"

-- Preserve each legacy database's merge policy: missing values only by default,
-- repair table containers for "tables", and also repair scalar types for "types".
-- Default tables are copied so a saved profile never mutates shared defaults.
function KHQOL.MergeDefaults(target, source, policy)
  for key, value in pairs(source) do
    local saved = target[key]
    if type(value) == "table" then
      if saved == nil or (policy and type(saved) ~= "table") then
        saved = {}; target[key] = saved
      end
      if type(saved) == "table" then KHQOL.MergeDefaults(saved, value, policy) end
    elseif saved == nil or (policy == "types" and type(saved) ~= type(value)) then
      target[key] = value
    end
  end
  return target
end
_G.KHQOL = KHQOL
