local _, K = ...
-- Connections only: modules retain ownership of their frames and databases.
local R={entries={},order={},states={},pending={},revision=0}
K.ModuleRegistry=R
K.profileModuleKeys={}; K.legacyProfileVariables={}
function R:Register(id, spec)
  assert(type(id)=="string" and id:match("^[%a][%w_]*$"),"Invalid KHQOL module ID")
  assert(type(spec)=="table","Missing KHQOL module specification")
  if self.entries[id] then
    assert(self.entries[id]==spec,"Duplicate KHQOL module ID: "..id)
    return spec
  end
  self.entries[id]=spec;self.order[#self.order+1]=id
  self.states[id]={initialized=false,running=false,epoch=0,resources={}}
  if spec.profile then K.profileModuleKeys[#K.profileModuleKeys+1]=id end
  if spec.variable then K.legacyProfileVariables[id]=spec.variable end
  if spec.defaultEnabled~=nil and K.defaults then
    if K.defaults.enabled[id]==nil then K.defaults.enabled[id]=spec.defaultEnabled end
    if K.db and K.db.enabled[id]==nil then K.db.enabled[id]=spec.defaultEnabled end
  end
  self.revision=self.revision+1
  return spec
end
function R:Module(id) return K.modules[id] end
function R:Validate()
  local visiting,done={},{}
  local function visit(id)
    if done[id] then return end
    assert(not visiting[id],"KHQOL dependency cycle: "..id)
    local spec=assert(self.entries[id],"Missing KHQOL dependency: "..id)
    visiting[id]=true
    for _,dependency in ipairs(spec.requires or {}) do visit(dependency) end
    -- Optional dependencies order initialization only when installed.
    for _,dependency in ipairs(spec.optional or {}) do if self.entries[dependency] then visit(dependency) end end
    visiting[id]=nil;done[id]=true
  end
  for _,id in ipairs(self.order) do visit(id) end
  return true
end
function R:Initialize(id)
  local spec=assert(self.entries[id],"Unknown KHQOL module: "..id)
  local state=self.states[id]
  if state.initialized then return end
  assert(not state.initializing,"KHQOL initialization cycle: "..id)
  state.initializing=true
  local ok,message=pcall(function()
    for _,dependency in ipairs(spec.requires or {}) do self:Initialize(dependency) end
    for _,dependency in ipairs(spec.optional or {}) do if self.entries[dependency] then self:Initialize(dependency) end end
    if spec.initialize then spec.initialize(self:Module(id),K) end
  end)
  state.initializing=nil
  if not ok then error(message,0) end
  state.initialized=true
end
function R:CanRun(id, requested)
  local spec=self.entries[id]
  if not spec then return false end
  if spec.always then return true end
  if not requested then return false end
  if K.LabLock and K.LabLock:IsExperimental(id) and not K.LabLock:IsUnlocked() then return false end
  return not spec.canRun or spec.canRun(self:Module(id),K)~=false
end
-- Only resources explicitly enrolled by their owner may be cleaned here.
function R:Own(id, token, cleanup)
  assert(type(cleanup)=="function","Missing resource cleanup")
  self.states[id].resources[token]=cleanup
  return token
end
function R:Release(id, token)
  self.states[id].resources[token]=nil
end
function R:CancelWork(id)
  local state=self.states[id]
  state.epoch=state.epoch+1;self.pending[id]=nil
  local resources=state.resources;state.resources={}
  local firstError
  for token,cleanup in pairs(resources) do
    local ok,message=pcall(cleanup,token)
    if not ok then firstError=firstError or message end
  end
  self:UpdateCombatEvent()
  if firstError then error(firstError,0) end
end
function R:Dispatch(id, requested)
  local spec=self.entries[id];if not spec then return false end
  self:Initialize(id)
  local state=self.states[id];local running=self:CanRun(id,requested)
  if not running then self:CancelWork(id) end
  -- Reapplication must reach legacy adapters: it also refreshes changed settings.
  if spec.setEnabled then spec.setEnabled(self:Module(id),running,K) end
  state.running=running
  return true
end
function R:IsRunning(id) return self.states[id] and self.states[id].running or false end
function R:UpdateCombatEvent()
  if self.combatEvents then
    if next(self.pending) then self.combatEvents:RegisterEvent("PLAYER_REGEN_ENABLED")
    else self.combatEvents:UnregisterEvent("PLAYER_REGEN_ENABLED") end
  end
end
function R:CancelDeferred(id)
  self.pending[id]=nil;self:UpdateCombatEvent()
end
-- A single latest request per owner. Read DB in apply; never capture settings.
-- Restore requests may run OFF, but still expire on a profile/epoch change.
function R:Defer(id, apply, restore)
  local state=assert(self.states[id],"Unknown deferred owner")
  assert(type(apply)=="function","Missing deferred callback")
  if not restore and not self:CanRun(id,K:GetEnabled(id)) then return false end
  self.pending[id]={apply=apply,restore=restore,generation=K.profileGeneration,epoch=state.epoch}
  if not self.combatEvents then
    self.combatEvents=CreateFrame("Frame")
    self.combatEvents:SetScript("OnEvent",function() R:FlushCombat() end)
  end
  self:UpdateCombatEvent()
  return true
end
function R:FlushCombat()
  if (InCombatLockdown and InCombatLockdown()) or (UnitAffectingCombat and UnitAffectingCombat("player")) then return end
  local pending=self.pending;self.pending={}
  self:UpdateCombatEvent()
  local firstError
  for _,id in ipairs(self.order) do
    local work=pending[id];local state=self.states[id]
    if work and work.generation==K.profileGeneration and work.epoch==state.epoch
      and (work.restore or self:CanRun(id,K:GetEnabled(id))) then
      local ok,message=pcall(work.apply,self:Module(id),K)
      if not ok then firstError=firstError or message end
    end
  end
  if firstError then error(firstError,0) end
end
function R:ProfileChanged()
  for _,id in ipairs(self.order) do
    self:CancelWork(id)
    local spec=self.entries[id]
    if spec.profileChanged then spec.profileChanged(self:Module(id),K) end
  end
end
function R:DefaultSettings(id)
  local spec=self.entries[id]
  local value=spec.defaults and spec.defaults(self:Module(id),K) or {}
  return K.CopyProfileValue(value)
end
function R:CaptureSettings(id)
  local spec=self.entries[id]
  return K.CopyProfileValue(spec.capture and spec.capture(self:Module(id),K)
    or K.db.modules and K.db.modules[id])
end
function R:RestoreSettings(id, value)
  local spec=self.entries[id]
  if spec.restore then return spec.restore(self:Module(id),value,K) end
  local target=type(K.db.modules[id])=="table" and K.db.modules[id] or {}
  local source=K.CopyProfileValue(value or {})
  K.PreserveUnknownProfileValue(target,source,self:DefaultSettings(id))
  K.db.modules[id]=K.ReplaceProfileValue(target,source)
end
function R:ApplyProfileConnections()
  for _,id in ipairs(self.order) do
    local spec=self.entries[id]
    if spec.applyProfile then spec.applyProfile(self:Module(id),K) end
  end
end
function R:PositionTargets(focus, add)
  for _,id in ipairs(self.order) do
    local spec=self.entries[id]
    if spec.positions and self:CanRun(id,K:GetEnabled(id)) then
      for _,target in ipairs(spec.positions(self:Module(id),focus,K) or {}) do
        target.key=id
        add(target.id,id,target.name,target.frame,target.write,target.lock,target.apply,target)
      end
    end
  end
end
