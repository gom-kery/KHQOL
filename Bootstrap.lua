local _, KHQOL = ...
KHQOL.modules = {
  general = {}, clock = {}, todo = {}, buffReminder = {}, range = {}, tooltip = {}, weaponGuide = {}, resourceSwing = {}, campfire = {}, cursorTrail = {}, castBar = {}, combatStatus = {}, questNavigator = {}, threat = {}, pvpAlert = {},
}
KHQOL.VERSION = "1.9.5.5"

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
