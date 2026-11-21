local U=_G.KHQOLDevUsage
local C=_G.KHQOLDevUsageControlIDs
local expected={
  ["feature.food.request"]="request",["feature.food.used"]="execute",["feature.food.well_fed"]="execute",
  ["feature.profession.guide"]="display",["feature.profession.note_request"]="request",["feature.profession.note_added"]="execute",["feature.profession.navigate"]="execute",
  ["feature.position.start"]="start",["feature.position.save"]="save",["feature.position.changed"]="changed",
  ["feature.position.cancel"]="cancel",["feature.position.unconfirmed"]="unconfirmed",
  ["feature.quest.manual"]="change",["feature.party.execute"]="request",["feature.party.chat_request"]="request",
  ["feature.party.draft"]="draft",["feature.thanks.click"]="execute",["feature.thanks.draft"]="draft",
  ["feature.thanks.send_request"]="request",["feature.sell.processed"]="processed",
  ["feature.sell.unconfirmed"]="unconfirmed",["feature.repair.request"]="request",
  ["feature.campfire.display"]="display",["feature.campfire.complete"]="display",["feature.buff.display"]="display"}
function U:IsBridgeID(id) return self.selectedRoutes and self.selectedRoutes[id]=="bridge" end
function U:DisconnectBridge()
  local D=self.bridge
  self.bridge=nil;self.bridgeStatus="unavailable"
  if D and type(D.Unsubscribe)=="function" then pcall(D.Unsubscribe,D,self._bridgeOwner) end
  for id,route in pairs(self.selectedRoutes or {}) do
    if route=="bridge" then self.selectedRoutes[id]=nil;self.available[id]=false end
  end
end
function U:EnrollBridgeControls()
  local K=_G.KHQOL;local D=self.bridge
  local N=K and K.UI and K.UI.SettingsNavigation
  if not D or not N then return end
  for control,item in pairs(N.controls or {}) do
    D:Bind(control,item.logicalTitle or item.title,item.read)
    local id=D:ControlID(control)
    if id and self.catalog[id] and item.logicalTitle then self.catalog[id].label=N:Path(item.route,item.logicalTitle) end
  end
  local s=K.settings
  if not s then return end
  if s.moduleHeader and s.moduleHeader.toggle then
    D:BindModule(s.moduleHeader.toggle,function()
      local t=s.currentModuleMeta and s.currentModuleMeta.toggle
      if t then return t.get() end
      return s.currentModuleKey and K:GetEnabled(s.currentModuleKey) or false
    end,function()
      local t=s.currentModuleMeta and s.currentModuleMeta.toggle
      return t and t.metric or s.currentModuleKey and "setting.module."..s.currentModuleKey
    end)
  end
  local general=s.pageCache and (s.pageCache.settings and s.pageCache.settings.tabPanels and s.pageCache.settings.tabPanels.modules or s.pageCache.general)
  for key,control in pairs(general and general.moduleControls or {}) do
    local item=N.controls[control]
    local id=U.catalog["setting.module."..key] and "setting.module."..key or "setting.general."..key
    if item and item.read and U.catalog[id] then D:BindModule(control,item.read,function() return id end) end
  end
end
function U:ConnectBridge()
  if not self:Enabled() then return end
  self.selectedRoutes=self.selectedRoutes or {};self.available=self.available or {}
  local K=_G.KHQOL;local D=K and K.UsageDiagnostics
  if not D or D.API~=1 or type(D.Subscribe)~="function" or type(D.Capabilities)~="function" then
    self:DisconnectBridge();self.bridgeStatus=D and "protocol_mismatch" or "unavailable";return
  end
  if self.bridge~=D then
    self:DisconnectBridge();self._bridgeOwner=self._bridgeOwner or {}
    local epoch=self.epoch
    local callback=self:Guard(function(id,phase,path,reason,changed)
      if epoch~=U.epoch or U.bridge~=D or not U.IsPublic(id) or type(id)~="string" then return end
      local meta=U.catalog[id];if not meta then return end
      if meta.kind=="settings" then if phase~="change" or changed~=true then return end
      elseif expected[id]~=phase then return end
      if not D:Supports(id) then return end
      U.selectedRoutes[id]="bridge";U.available[id]=true
      U:Counter(id,path,false,reason,"bridge")
    end)
    local ok,accepted=pcall(D.Subscribe,D,self._bridgeOwner,callback,1)
    if not ok or accepted~=true then self.bridgeStatus="subscribe_failed";return end
    self.bridge=D
  end
  self.bridgeStatus="connected"
  local ok,capabilities=pcall(D.Capabilities,D)
  if ok and type(capabilities)=="table" then for id,on in pairs(capabilities) do
    if on==true and self.catalog[id] then self.selectedRoutes[id]="bridge";self.available[id]=true end
  end end
  self:EnrollBridgeControls()
end
