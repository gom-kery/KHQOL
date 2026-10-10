local _, KHQOL = ...
KHQOL.modules = {
  general = {}, clock = {}, todo = {}, buffReminder = {}, range = {}, tooltip = {}, weaponGuide = {}, resourceSwing = {}, campfire = {}, cursorTrail = {}, castBar = {}, combatStatus = {}, questNavigator = {}, threat = {}, pvpAlert = {},
}
KHQOL.modules.environmentTimer = {}
KHQOL.modules.experienceBar = {}
KHQOL.modules.procAlert = {experimental=true}
KHQOL.modules.npcAlert = {}
KHQOL.VERSION = "1.10.4.1"

-- Profile-owned modern modules share enable dispatch, not UI or position lists.
-- General/Todo, legacy stores, labs without settings and attached HUDs differ.
KHQOL.profileModuleKeys = {"tooltip","cursorTrail","castBar","combatStatus",
  "questNavigator","threat","pvpAlert","environmentTimer","experienceBar",
  "procAlert","objectHighlight","npcAlert"}
KHQOL.legacyProfileVariables = {clock="ForeverClockDB",buffReminder="ForeverBuffReminderDB",
  range="FRangeDB",resourceSwing="KHQOLResourceSwingDB",campfire="CampfireAlertDB"}

-- Explicit count preserves intermediate/trailing nil, false and zero.
-- The status is separate from API results. Table fields still need a protected
-- module-specific reader; success here is not proof of untainted access.
local function pack(...) return {n=select("#",...),...} end
function KHQOL.IsPublicValue(value)
  if type(issecretvalue)~="function" then return true end
  local ok,secret=pcall(issecretvalue,value)
  return ok and not secret
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
