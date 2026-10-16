local K=_G.KHQOL
local R=K.ModuleRegistry
local function initialize(m) if m and m.Initialize then m:Initialize() end end
local function enable(m,on) if m and m.SetEnabled then m:SetEnabled(on) end end
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
do local spec=R.entries.campfire
  if not spec.positions then spec.positions=function(m,focus,K) local provider=K.PositionProviders.campfire;return provider and provider(focus,K) or {} end end
  spec.applyProfile=function(m,K)
  if not m.initialized then return end
  m:CancelRediscovery();m.rediscoveryUntil=nil;m.benefitAcquiredAt=nil
  m.db=CampfireAlertDB;m:HideDiscovery();m:ApplyLayout();m.ui.complete:Hide()
  local p=m.db.position;m.ui.root:ClearAllPoints();m.ui.root:SetPoint(p.point,UIParent,p.point,p.x,p.y)
  if not m.db.locked then m.ui.discovery:Show();m.ui.complete:Hide() end
  end
  spec.editorPositions=function(m,K) if m.db and m.ui then K.PositionUtils.ApplyPoint(m.ui.complete,m.db.completePosition or {y=80}) end end
  spec.alertFrames=function(m,K)
  if not m.ui then return {} end
  return {{frame=m.ui.root,priority=50,allowed=function() return m.db.locked and m.ui.discovery:IsVisible() end},
    {frame=m.ui.complete,priority=45,allowed=function() return m.db.locked end}}
  end
  spec.finishDrags=function(m,K) if m.ui and m.ui.root.cfaMoving and m.StopPositionDrag then m:StopPositionDrag() end end
end
