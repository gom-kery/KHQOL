local _,K=...
local UI,R=K.UI,K.UI.SettingsRegistry
local names={unitFrames="UnitFrameSettings",partyFrames="PartyFrameSettings",bars="BarsSettings",
  alerts="AlertSettings",labs="LabSettings",interface="InterfaceSettings",convenience="ConvenienceSettings",quest="QuestSettings"}
for id,name in pairs(names) do K[name]=UI:NewSettingsGroup(id) end
R.groups.convenience.general.owner="generalConvenience"
local function pruneSettingsGroup(registry,id,group,active)
  local builders={}
  for _,tab in ipairs(group.tabs) do builders[tab.id]=true end
  for tab,meta in pairs(registry.groups[id]) do
    local owner=meta.key or meta.owner
    if not builders[tab] or owner and not K.ModuleRegistry.entries[owner] then registry.groups[id][tab]=nil
    else active[meta]=true end
  end
  for index=#registry.orders[id],1,-1 do
    if not registry.groups[id][registry.orders[id][index]] then table.remove(registry.orders[id],index) end
  end
  for index=#group.tabs,1,-1 do
    if not registry.groups[id][group.tabs[index].id] then table.remove(group.tabs,index) end
  end
  local seen={}
  for _,tab in ipairs(registry.orders[id]) do seen[tab]=true end
  for _,tab in ipairs(group.tabs) do
    if not seen[tab.id] then
      table.insert(registry.orders[id],tab.id);seen[tab.id]=true
    end
  end
  if not registry.groups[id][group.selected] then group.selected=registry.orders[id][1] end
end
local function prunePagesAndCommands(registry)
  local pages={general=true,profiles=true}
  for id,group in pairs(UI.SettingsGroups) do if #group.tabs>0 then pages[id]=true end end
  for index=#registry.pages,1,-1 do
    if not pages[registry.pages[index][1]] then table.remove(registry.pages,index) end
  end
  for key,target in pairs(registry.commands) do
    if not registry.routes[target] and not pages[target] then registry.commands[key]=nil end
  end
end
local function pruneModuleGroups(registry)
  for index=#registry.moduleGroups,1,-1 do
    local group=registry.moduleGroups[index]
    for item=#group.items,1,-1 do
      local entry=group.items[item]
      if entry[3] and not K.modules.general or not entry[3] and not K.ModuleRegistry.entries[entry[1]] then table.remove(group.items,item) end
    end
    if #group.items==0 then table.remove(registry.moduleGroups,index) end
  end
end
local function prunePositionAndSearch(registry)
  for key in pairs(registry.positionModules) do if not K.ModuleRegistry.entries[key] then registry.positionModules[key]=nil end end
  local navigation=UI.SettingsNavigation
  for id,item in pairs(navigation.items) do
    local key=item.route.module
    if K.ModuleOwners[key] and not K.ModuleRegistry.entries[key] then navigation.items[id]=nil
    else navigation:Register(item.route,item.logicalTitle or item.title,item.description,item.baseAliases or item.aliases) end
  end
end
function R:FinalizeInstallation()
  if self.installationFinalized then return end
  self:ConnectModules()
  if self.groups.convenience.chat and self.groups.convenience.professions then
    self.orders.convenience={"general","chat","party","professions","buff","highlight","note"}
  else
    self.orders.convenience={"general","buff","highlight","note"}
  end
  local active={}
  for id,group in pairs(UI.SettingsGroups) do pruneSettingsGroup(self,id,group,active) end
  for key,meta in pairs(self.modules) do if not active[meta] then self.modules[key]=nil end end
  for key,meta in pairs(self.routes) do if not active[meta] then self.routes[key]=nil end end
  prunePagesAndCommands(self)
  pruneModuleGroups(self)
  self:BuildScreens()
  prunePositionAndSearch(self)
  self.installationFinalized=true
end
