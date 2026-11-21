local U=_G.KHQOLDevUsage
local hooked=setmetatable({}, {__mode="k"})
local controls=setmetatable({}, {__mode="k"})
local windows=setmetatable({}, {__mode="k"})
local knownModules={};for _,key in ipairs(U.modules) do knownModules[key]=true end
local function hook(object,method,fn)
  if not object or type(object[method])~="function" or type(hooksecurefunc)~="function" then return false end
  local set=hooked[object] or {};hooked[object]=set
  if set[method] then return true end
  local ok=pcall(hooksecurefunc,object,method,U:Guard(fn))
  if ok then set[method]=true else U:Error("hook") end
  return ok
end
local function script(frame,event,key,fn)
  if not frame or type(frame.HookScript)~="function" then return false end
  local set=hooked[frame] or {};hooked[frame]=set
  key=event..":"..key;if set[key] then return true end
  local ok=pcall(frame.HookScript,frame,event,U:Guard(fn))
  if ok then set[key]=true else U:Error("hook") end
  return ok
end
local function value(getter)
  local ok,v=pcall(getter)
  if not ok or not U.IsPublic(v) then return nil,false end
  local kind=type(v)
  if kind=="number" then return v,v==v and math.abs(v)<math.huge end
  if kind=="boolean" then return v,true end
  if kind=="string" and #v<=128 then return v,true end
  return nil,false
end
local function validContext()
  local K=_G.KHQOL
  return U:Enabled() and not U.paused and K and not K.profileApplying and not K.profileClosingEditors
end
local function begin(record,path)
  record.pending=nil
  if not validContext() then return end
  local id=record.resolve and record.resolve() or record.id
  if not id or not U.catalog[id] then return end
  if U:IsBridgeID(id) then return end
  local v,ok=value(record.get)
  if ok then record.pending={value=v,id=id,path=path,generation=_G.KHQOL.profileGeneration,epoch=U.epoch} end
end
local function finish(record)
  local p=record.pending;record.pending=nil
  if not p or not validContext() or p.epoch~=U.epoch or p.generation~=_G.KHQOL.profileGeneration then return end
  local id=record.resolve and record.resolve() or record.id
  if id~=p.id then return end
  local v,ok=value(record.get)
  if ok and type(v)==type(p.value) and v~=p.value then U:Counter(p.id,p.path) end
end
function U:CancelInputs() for _,record in pairs(controls) do record.pending=nil end end
local function bindInput(box,record)
  if not box then return end
  script(box,"OnEditFocusGained","usage.begin",function() begin(record,"input") end)
  script(box,"OnEnterPressed","usage.finish",function() finish(record) end)
  script(box,"OnEditFocusLost","usage.finish",function()
    -- Enter clears focus while cancelFocus is set; its own post handler settles once.
    if not box.cancelFocus then finish(record) end
  end)
  script(box,"OnEscapePressed","usage.cancel",function() record.pending=nil end)
  script(box,"OnHide","usage.cancel",function() record.pending=nil end)
  hook(box,"CancelEdit",function() record.pending=nil end)
end
local function label(record,control)
  local regions={control.text or control.tooltipLabel}
  for _,region in ipairs(control.uiLabels or {}) do regions[#regions+1]=region end
  for _,region in ipairs(regions) do
    local area=region and region.khqolTooltipArea
    if area and control.ToggleFromLabel then
      script(area,"OnMouseDown","usage.begin",function(_,button) if button=="LeftButton" then begin(record,"click") end end)
      hook(control,"ToggleFromLabel",function() finish(record) end)
    end
  end
end
function U:BindControl(control,id,kind,get,resolve)
  if not control or type(get)~="function" or not id or not self.catalog[id] then return end
  local record=controls[control]
  if record then
    record.id=id;record.get=get;record.resolve=resolve
    if not resolve then self.available[id]=true;self:Touch(id) end
    label(record,control);return
  end
  record={id=id,get=get,resolve=resolve};controls[control]=record
  if not resolve then self.available[id]=true;self:Touch(id) end
  if kind=="check" then
    script(control,"OnMouseDown","usage.begin",function(_,button) if button=="LeftButton" then begin(record,"click") end end)
    script(control,"OnClick","usage.finish",function() finish(record) end)
    label(record,control)
  elseif kind=="slider" then
    script(control,"OnMouseDown","usage.begin",function(_,button) if button=="LeftButton" then begin(record,"drag") end end)
    script(control,"OnMouseUp","usage.finish",function(_,button) if button=="LeftButton" then finish(record) end end)
    bindInput(control.numberBox,record)
  elseif kind=="dropdown" then
    local function rows()
      for _,row in ipairs(control.rows or {}) do
        script(row,"OnMouseDown","usage.begin",function(_,button) if button=="LeftButton" then begin(record,"click") end end)
        script(row,"OnClick","usage.finish",function() finish(record) end)
      end
    end
    hook(control,"Refresh",rows);rows()
  elseif kind=="input" then bindInput(control,record) end
  script(control,"OnHide","usage.cancel",function() record.pending=nil end)
  hook(control,"Refresh",function() label(record,control) end)
end
function U:AttachControl(parent,control,title,get)
  local K=_G.KHQOL;local N=K and K.UI and K.UI.SettingsNavigation
  if not N or type(get)~="function" or type(title)~="string" or not self.IsPublic(title) then return end
  local route=N:Context(parent);local module=route and route.module
  -- No search item ID, section text, user registration label or dynamic value becomes a metric key.
  local binding=self.IsPublic(module) and type(module)=="string" and self.bindings[module.."/"..title]
  if binding then self:BindControl(control,binding.id,binding.kind,get) end
end
function U:CurrentMenu()
  local K=_G.KHQOL;local s=K and K.settings
  if not s or not s:IsShown() or not self.pages[s.page] and not (K.UI.SettingsRegistry and K.UI.SettingsRegistry.screens) then return nil end
  local R=K.UI.SettingsRegistry
  if R and R.screens then
    local view=R:ScreenFor(s.currentRoute or {page=s.page})
    local group,tab=view.logicalGroup,view.logicalTab
    local panel=s.activeContent and s.activeContent.activePanel
    if view.id=="common" or view.id=="modules" then return "menu.general" end
    if view.id=="profiles" then return "menu.profiles" end
    if view.id=="labs" then
      group="labs";tab=K.LabSettings and K.LabSettings.selected
      if not K.LabLock:IsUnlocked() then return "menu.labs" end
    end
    local id=group and tab and "menu."..group.."."..tab
    if id=="menu.convenience.buff" then id="menu.labs.buff" end
    if id=="menu.unitFrames.units" and panel and panel.selectedUnit and panel.selectedPart then
      local deep=id.."."..panel.selectedUnit.."."..panel.selectedPart
      if panel.selectedUnit=="target" and panel.selectedPart=="auras" and panel.selectedAuraCategory then deep=deep.."."..panel.selectedAuraCategory end
      if self.catalog[deep] then return deep end
    elseif id=="menu.bars.cast" and panel and panel.selectedCastUnit then
      local deep=id.."."..panel.selectedCastUnit;if self.catalog[deep] then return deep end
    end
    return id and self.catalog[id] and id or nil
  end
  local group=K.UI.SettingsGroups and K.UI.SettingsGroups[s.page]
  local tab=group and group.selected
  local id=type(tab)=="string" and "menu."..s.page.."."..tab
  -- Preserve historical Buff Reminder visit counters after its package move.
  if id=="menu.convenience.buff" then id="menu.labs.buff" end
  local panel=s.activeContent and s.activeContent.activePanel
  if id=="menu.unitFrames.units" and panel and type(panel.selectedUnit)=="string" and type(panel.selectedPart)=="string" then
    local deep=id.."."..panel.selectedUnit.."."..panel.selectedPart
    if panel.selectedUnit=="target" and panel.selectedPart=="auras" and type(panel.selectedAuraCategory)=="string" then deep=deep.."."..panel.selectedAuraCategory end
    if self.catalog[deep] then return deep end
  elseif id=="menu.bars.cast" and panel and type(panel.selectedCastUnit)=="string" then
    local deep=id.."."..panel.selectedCastUnit;if self.catalog[deep] then return deep end
  end
  if id and self.catalog[id] and s.activeContent and s.activeContent.activePanel then return id end
  return "menu."..s.page
end
function U:QueueNavigation(user,force)
  if not self:Enabled() then return end
  local ticket=self.navigationTicket
  if ticket then if user then ticket.user=true elseif force then ticket.user=false end;return end
  ticket={epoch=self.epoch,user=user==true};self.navigationTicket=ticket
  local callback=self:Guard(function()
    if U.navigationTicket~=ticket or ticket.epoch~=U.epoch then return end
    U.navigationTicket=nil
    local K=_G.KHQOL
    if K and not K.profileApplying and not K.profileClosingEditors then U:SetMenu(U:CurrentMenu(),ticket.user) end
  end)
  if C_Timer and C_Timer.After then C_Timer.After(0,callback)
  else self.navigationTicket=nil;self.timerUnavailable=true end -- Final page cannot be coalesced safely without a timer.
end
local function navButton(button)
  script(button,"OnClick","usage.navigation",function() U:QueueNavigation(true) end)
end
function U:Discover()
  local K=_G.KHQOL;local s=K and K.settings;local N=K and K.UI and K.UI.SettingsNavigation
  if not s or not N then return end
  if self.enrolled~=N then for control,item in pairs(N.controls or {}) do
    -- Only these fields locate a pre-approved binding. Item ID/title never enter saved data.
    self:AttachControl(control:GetParent(),control,item.logicalTitle or item.title,item.read)
  end;self.enrolled=N end
  for _,button in pairs(s.menuButtons or {}) do navButton(button) end
  for _,content in pairs(s.pageCache or {}) do
    for _,button in pairs(content.tabButtons or {}) do navButton(button) end
    hook(content,"SelectSettingsTab",function() U:QueueNavigation(false) end)
    for _,panel in pairs(content.tabPanels or {}) do
      for _,field in ipairs({"unitTabButtons","partTabButtons","castButtons"}) do
        for _,button in pairs(panel[field] or {}) do navButton(button) end
      end
      hook(panel,"SelectUnitPart",function() U:QueueNavigation(false) end)
      hook(panel,"SelectCastUnit",function() U:QueueNavigation(false) end)
      hook(panel,"SelectAuraCategory",function() U:QueueNavigation(true) end)
    end
  end
  local current=self:CurrentMenu();if current then self.available[current]=true end
  local common=s.pageCache and (s.pageCache.settings and s.pageCache.settings.tabPanels and s.pageCache.settings.tabPanels.modules or s.pageCache.general)
  for key,control in pairs(common and common.moduleControls or {}) do
    local id=knownModules[key] and "setting.module."..key or "setting.general."..key
    if self.catalog[id] then
      local item=N.controls[control]
      if item and item.read then self:BindControl(control,id,"check",item.read) end
    end
  end
  if s.moduleHeader and s.moduleHeader.toggle then
    local function resolve()
      local t=s.currentModuleMeta and s.currentModuleMeta.toggle
      if t and U.catalog[t.metric] then return t.metric end
      local key=s.currentModuleKey;return knownModules[key] and "setting.module."..key
    end
    -- The resolver is evaluated at gesture start and finish, never saved as a label.
    self:BindControl(s.moduleHeader.toggle,"setting.module.clock","check",function()
      local t=s.currentModuleMeta and s.currentModuleMeta.toggle
      if t then return t.get() end
      return K:GetEnabled(s.currentModuleKey)
    end,resolve)
  end
end
function U:BindSettings()
  local K=_G.KHQOL;local s=K and K.settings
  if not s then return end
  hook(s,"ShowPage",function()
    U:Discover()
    U:QueueNavigation(false)
    -- A profile or refresh may reselect the page. Only explicit UI gesture hooks count visits.
  end)
  script(s,"OnShow","usage.navigation",function() U:QueueNavigation(true) end)
  script(s,"OnHide","usage.close",function()
    U.navigationTicket=nil;U:SetMenu(nil,false);U:CancelInputs()
  end)
  self:Discover()
  if self.bridge then self:EnrollBridgeControls() end
end
function U:ObserveWindow(object,field,id,action)
  local frame=object and object[field]
  if not frame or windows[frame] then return end
  windows[frame]=true
  script(frame,"OnShow","usage.window",function() if validContext() then U:Counter(id) end end)
  if action and frame:IsShown() and validContext() then self:Counter(id) end
end
function U:BindFeatures()
  local K=_G.KHQOL;local modules=K and K.modules or {}
  local clock,convenience,npc=modules.clock,modules.generalConvenience,modules.npcAlert
  local professions=modules.professions
  if hook(clock,"ToggleTodo",function(self) U:ObserveWindow(self,"todoFrame","feature.note.open",true) end) then
    self.available["feature.note.open"]=true;self:ObserveWindow(clock,"todoFrame","feature.note.open",false)
    hook(clock,"CreateTodo",function(self) U:ObserveWindow(self,"todoFrame","feature.note.open",false) end)
  end
  if hook(professions,"ToggleProfessions",function(self) U:ObserveWindow(self,"professionsPanel","feature.professions.open",true) end) then
    self.available["feature.professions.open"]=true
    self:ObserveWindow(professions,"professionsPanel","feature.professions.open",false)
  end
  local thanks=convenience and convenience.buffThanks
  if hook(thanks,"Show",function(self)
    if not validContext() or K.PositionEditor and K.PositionEditor.active then return end
    local entry=self.alerts and self.alerts[#self.alerts]
    if entry and entry.button and entry.button:IsShown() then U:Counter("feature.thanks.display") end
  end) then self.available["feature.thanks.display"]=true end
  if hook(npc,"ShowBanner",function(self)
    if validContext() and not (K.PositionEditor and K.PositionEditor.active) and self.banner and self.banner:IsShown() then
      U:Counter("feature.npc.display")
    end
  end) then self.available["feature.npc.display"]=true end
  local party=convenience and convenience.partyControl
  if type(UnitPopup_OpenMenu)=="function" and hook(party,"OpenPartyMenu",function()
    if validContext() and type(UnitPopup_OpenMenu)=="function" then U:Counter("feature.party.menu_request") end
  end) then
    self.available["feature.party.menu_request"]=true
  end
  local editor=K and K.PositionEditor
  self.editorActive=editor and editor.active==true or false
  if hook(editor,"Enter",function(self)
    if not self.active or U.editorActive then return end
    U.editorActive=true;U:Counter("feature.position.start")
  end) then
    self.available["feature.position.start"]=true
    hook(editor,"Finish",function(self) if not self.active then U.editorActive=false end end)
  end
end
function U:CheckAFK()
  self.afkSupported=false
  if self.afkEvent and type(UnitIsAFK)=="function" then
    local ok,on=pcall(UnitIsAFK,"player")
    if ok and self.IsPublic(on) and type(on)=="boolean" then self.afkSupported=true;self:Pause(on);return end
  end
  -- Unknown AFK data is not treated as a confirmed active state transition.
end
function U:ActiveDays()
  if not self:Enabled() or self.paused then return end
  local K=_G.KHQOL;local R=K and K.ModuleRegistry
  if not R then return end
  for _,key in ipairs({"clock","experienceBar","castBar","tooltip","threat"}) do
    local id="feature.active."..key;local state=R.states[key]
    if R.entries[key] and state then
      self.available[id]=true;self:Touch(id)
      -- A module marked running after Dispatch plus saved preference is a capability-day, not a render count.
      if state.running==true and K:GetEnabled(key) and not K.profileApplying then self:Counter(id,nil,true) end
    end
  end
end
function U:MarkCoverage()
  for id,on in pairs(self.available or {}) do if on then self:Touch(id) end end
end
function U:Connect()
  if not self:Enabled() then return end
  self:CheckAFK()
  self:ConnectBridge()
  local K=_G.KHQOL
  if not K or not K.UI or not K.UI.SettingsNavigation or not K.ModuleRegistry then return end
  local N=K.UI.SettingsNavigation
  hook(N,"Attach",function(_,parent,control,title,get) U:AttachControl(parent,control,title,get) end)
  hook(K,"CreateSettings",function() U:BindSettings() end)
  hook(K,"ShowSettings",function()
    if validContext() and not (K.PositionEditor and K.PositionEditor.active) then U:BindSettings();U:QueueNavigation(true) end
  end)
  hook(N,"Open",function(_,_,_,restoreOnly)
    U:BindSettings();U:QueueNavigation(restoreOnly~=true,restoreOnly==true)
  end)
  hook(K.ModuleRegistry,"Dispatch",function() U:ActiveDays() end)
  hook(K,"ApplyProfileModules",function()
    U:CancelInputs();U:ActiveDays()
  end)
  hook(K,"SelectProfile",function() U:CancelInputs();U:ActiveDays() end)
  self:BindSettings();self:BindFeatures();self:ActiveDays()
  local s=K.settings
  if s then
    for page in pairs(self.pages) do
      local present=false
      for _,definition in ipairs(K.UI.SettingsRegistry.legacyPages or K.UI.SettingsRegistry.pages) do if definition[1]==page then present=true;break end end
      self.available["menu."..page]=present and C_Timer and type(C_Timer.After)=="function" or false
      local group=K.UI.SettingsGroups and K.UI.SettingsGroups[page]
      for _,tab in ipairs(group and group.tabs or {}) do
        local id="menu."..page.."."..tab.id
        if id=="menu.convenience.buff" then id="menu.labs.buff" end
        if self.catalog[id] then self.available[id]=true end
      end
    end
  end
  for key in pairs(knownModules) do
    if K.ModuleRegistry.entries[key] then self.available["setting.module."..key]=true end
  end
  self:MarkCoverage()
  if not self.currentMenu then self:QueueNavigation(true) end
end
