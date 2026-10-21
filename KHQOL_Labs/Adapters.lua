local K=_G.KHQOL
local R=K.ModuleRegistry
local function initialize(m) if m and m.Initialize then m:Initialize() end end
local function enable(m,on) if m and m.SetEnabled then m:SetEnabled(on) end end
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
R:Register("procAlert",{profile=true,setEnabled=enable,defaults=function(m) return m and m.defaults or {} end})
R:Register("objectHighlight",{profile=true,setEnabled=enable,defaults=function(m) return m and m.defaults or {} end})
do local spec=R.entries.buffReminder
  if not spec.positions then spec.positions=function(m,focus,K) local provider=K.PositionProviders.buffReminder;return provider and provider(focus,K) or {} end end
  spec.applyProfile=function(m,K)
  local fbr=ForeverBuffReminder
  if not fbr or not fbr.anchor then return end
  fbr:StopCountdown();fbr.testMode=false;fbr:InitializeDatabase()
  fbr.anchor:ClearAllPoints();local p=ForeverBuffReminderDB.position
  fbr.anchor:SetPoint(p.point,UIParent,p.point,p.x,p.y);fbr:SetLocked(ForeverBuffReminderDB.locked)
  end
  spec.afterApplyProfile=function(m,K)
  local fbr=ForeverBuffReminder
  if fbr and fbr.anchor and not K:GetEnabled("buffReminder") then
    for _,frame in ipairs(fbr.alertFrames or {}) do frame:Hide() end
    fbr.anchor:Hide();fbr:StopCountdown()
  end
  end
  spec.dragFrames=function(m,K) return {_G.ForeverBuffReminder and ForeverBuffReminder.anchor} end
end
do local spec=R.entries.procAlert
  if not spec.positions then spec.positions=function(m,focus,K) local provider=K.PositionProviders.procAlert;return provider and provider(focus,K) or {} end end
end
do local spec=R.entries.objectHighlight
  if not spec.positions then spec.positions=function(m,focus,K) local provider=K.PositionProviders.objectHighlight;return provider and provider(focus,K) or {} end end
end
