local _, K = ...
local R=K.ModuleRegistry
-- Late module lookup is deliberate: some files replace Bootstrap placeholders.
local function initialize(m) if m and m.Initialize then m:Initialize() end end
local function enable(m,on) if m and m.SetEnabled then m:SetEnabled(on) end end
for _,id in ipairs({"tooltip","cursorTrail","castBar","combatStatus","questNavigator","threat",
  "pvpAlert","environmentTimer","experienceBar","procAlert","objectHighlight","npcAlert",
  "performanceMonitor","generalConvenience","basicUI","unitFrames"}) do
  local key=id
  local spec={profile=true,setEnabled=enable,defaults=function(m) return m and m.defaults or {} end}
  if id=="tooltip" or id=="cursorTrail" then spec.initialize=initialize end
  if id=="unitFrames" then
    spec.requires={"basicUI"}
    spec.positions=function(m,focus) return m:EditorTargets(focus) end
  end
  if id=="generalConvenience" then spec.always=true;spec.requires={"general"} end
  R:Register(key,spec)
end
R:Register("general",{always=true,initialize=initialize})
R:Register("frameMover",{always=true,initialize=initialize})
R:Register("chatEnhancement",{always=true,initialize=initialize})
R:Register("frameInspector",{setEnabled=enable})
R:Register("weaponGuide",{owner="tooltip"}) -- provider; old DB is migration-only
R:Register("clock",{variable="ForeverClockDB",setEnabled=function(m,on)
  if m and m.SetHUDShown then m:SetHUDShown(on) end
end})
R:Register("todo",{owner="clock",requires={"clock"},setEnabled=function(_,on)
  local fc=K.modules.clock
  if fc.todoFrame and not on then fc.todoFrame:Hide() end
  if fc.UpdateTodoMinimapButton then fc:UpdateTodoMinimapButton() end
  if fc.RefreshTodoNavigation then fc:RefreshTodoNavigation() end
end})
R:Register("range",{variable="FRangeDB",scope="character",setEnabled=enable})
R:Register("buffReminder",{variable="ForeverBuffReminderDB",setEnabled=function(_,on)
  local fbr=ForeverBuffReminder;if not fbr then return end
  fbr:UnregisterAllEvents()
  if on then
    for _,event in ipairs({"PLAYER_ENTERING_WORLD","UNIT_AURA","SPELL_DATA_LOAD_RESULT","PLAYER_REGEN_DISABLED",
      "PLAYER_REGEN_ENABLED","PLAYER_DEAD","PLAYER_ALIVE","PLAYER_TOTEM_UPDATE","WEAPON_ENCHANT_CHANGED"}) do fbr:RegisterEvent(event) end
  else
    -- Spell-data completion belongs to the registration/settings page too.
    fbr:RegisterEvent("SPELL_DATA_LOAD_RESULT");fbr.testMode=false
  end
  if on then fbr:RefreshAlerts()
  else
    fbr:StopCountdown()
    if fbr.HideAlerts then fbr:HideAlerts() elseif fbr.container then fbr.container:Hide() end
  end
end})
R:Register("resourceSwing",{variable="KHQOLResourceSwingDB",setEnabled=function(m,on)
  if m.SetEnabled then m:SetEnabled(on)
  else
    if KHQOLResourceSwingDB then KHQOLResourceSwingDB.enabled=on and true or false end
    if KHQOLResourceSwingFrame then KHQOLResourceSwingFrame:SetShown(on) end
  end
  local cast=K.modules.castBar
  if cast and cast.frame then cast:ApplyLayout();cast:RefreshControls() end
end})
R:Register("campfire",{variable="CampfireAlertDB",setEnabled=function(m,on)
  if not m then return end
  if m.events then
    m.events:UnregisterAllEvents()
    if on then
      for _,event in ipairs({"PLAYER_ENTERING_WORLD","UNIT_AURA","PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED"}) do m.events:RegisterEvent(event) end
    end
  end
  if not on then
    if m.CancelRediscovery then m:CancelRediscovery() end
    m:HideDiscovery()
  elseif m.ProcessAuras then m:ProcessAuras("khqol-enable") end
end})
