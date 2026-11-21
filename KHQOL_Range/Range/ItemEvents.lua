local K=_G.KHQOL
local R=K.modules.range
function R:RangeItemEventRelevant(id)
  if not K.IsPublicNumber(id) then return false end
  if self.Distance.requested[id] or self.Range.weaponRequested and self.Range.weaponRequested[id] then return true end
  if not self.rangeItemIDs then
    self.rangeItemIDs={}
    for _,tiers in pairs(self.distanceItems) do for _,ids in pairs(tiers) do for _,item in ipairs(ids) do self.rangeItemIDs[item]=true end end end
    for _,item in ipairs(self.Range.meleeItemIDs or {}) do self.rangeItemIDs[item]=true end
  end
  return self.rangeItemIDs[id]==true
end
function R:QueueRangeItemEvent(id)
  if not self:RangeItemEventRelevant(id) or self.itemDataQueued and self.itemDataQueued.profile==K.profileGeneration then return end
  local ticket={profile=K.profileGeneration}
  self.itemDataQueued=ticket
  C_Timer.After(.1,function()
    if R.itemDataQueued~=ticket then return end
    R.itemDataQueued=nil
    if ticket.profile~=K.profileGeneration or not R.db or not K:GetEnabled("range") then return end
    R.Distance:Invalidate(true)
    R:RefreshDisplay()
    local dead=R.Distance.thresholdControls and R.Distance.thresholdControls.dead
    if dead and R.Settings.panel and R.Settings.panel:IsVisible() then
      for _,control in ipairs(dead.inputs) do control:Refresh() end
      dead.picker:Refresh()
    end
    R:SyncUpdates()
  end)
end
