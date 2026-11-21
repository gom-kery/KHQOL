-- Optional local diagnostics, protocol 1. No SavedVariables, counters, polling or network.
local _,K=...
local C=K.UsageControlIDs
local D={API=1,revision=13}
K.UsageDiagnostics=D
local listeners,count,generation={},0,0
local bound=setmetatable({}, {__mode="k"})
local pending=setmetatable({}, {__mode="k"})
local color,position
local fields={"module","tab","unit","part","category","castUnit","section"}
local paths={click=true,drag=true,input=true,arrow=true,unknown=true}
local reasons={explicit=true,escape=true,combat=true,profile=true,navigation=true,hidden=true,world=true,
  validation=true,apply=true,unavailable=true,unknown=true}
local phases={change=true,start=true,save=true,changed=true,cancel=true,unconfirmed=true,request=true,
  execute=true,draft=true,processed=true,display=true}
local features={
  ["feature.food.request"]="buffReminder",["feature.food.used"]="buffReminder",["feature.food.well_fed"]="buffReminder",
  ["feature.profession.guide"]="professions",["feature.profession.note_request"]="professions",
  ["feature.profession.note_added"]="professions",["feature.profession.navigate"]="professions",
  ["feature.position.start"]="_core",["feature.position.save"]="_core",["feature.position.changed"]="_core",
  ["feature.position.cancel"]="_core",["feature.position.unconfirmed"]="_core",
  ["feature.quest.manual"]="questNavigator",["feature.party.execute"]="generalConvenience",
  ["feature.party.chat_request"]="generalConvenience",["feature.party.draft"]="generalConvenience",
  ["feature.thanks.click"]="generalConvenience",["feature.thanks.draft"]="generalConvenience",
  ["feature.thanks.send_request"]="generalConvenience",["feature.sell.processed"]="general",
  ["feature.sell.unconfirmed"]="general",["feature.repair.request"]="general",
  ["feature.campfire.display"]="campfire",["feature.campfire.complete"]="campfire",
  ["feature.buff.display"]="procAlert"}
local modules={"clock","todo","experienceBar","castBar","tooltip","threat","cursorTrail","range",
  "resourceSwing","environmentTimer","combatStatus","npcAlert","pvpAlert","campfire","questNavigator",
  "unitFrames","partyFrames","basicUI","buffReminder","procAlert","objectHighlight","minimap"}
local settings={};for id,meta in pairs(C.definitions) do settings[id]=meta.owner end
for _,id in ipairs(modules) do settings["setting.module."..id]=id end
for _,id in ipairs({"autoSellJunk","autoRepair","autoConfirmDestroy","chatEnhancement"}) do settings["setting.general."..id]="general" end
local function public(v) return K.IsPublicValue(v) end
local function pack(...) return {n=select("#",...),...} end
local function read(get)
  if type(get)~="function" then return nil end
  local r=pack(pcall(get));if not r[1] or r.n>9 then return nil end
  for i=2,r.n do
    local v=r[i];if not public(v) then return nil end
    local t=type(v)
    if t~="nil" and t~="number" and t~="boolean" and t~="string" then return nil end
    if t=="number" and (v~=v or math.abs(v)==math.huge) then return nil end
    if t=="string" and #v>8192 then return nil end
  end
  return r
end
local function different(a,b)
  if not a or not b then return nil end
  if a.n~=b.n then return true end
  for i=2,a.n do if type(a[i])~=type(b[i]) or a[i]~=b[i] then return true end end
  return false
end
local function ownerExists(owner) return owner=="_core" or K.ModuleRegistry and K.ModuleRegistry.entries[owner]~=nil end
function D:Listening() return count>0 end
function D:Ticket() return count>0 and generation or nil end
function D:Matches(ticket) return count>0 and type(ticket)=="number" and ticket==generation end
function D:Subscribe(owner,callback,protocol)
  if protocol~=1 or type(owner)~="table" or type(callback)~="function" then return false end
  if not listeners[owner] then if count>=8 then return false end;count=count+1 end
  if listeners[owner]~=callback then generation=generation+1 end
  listeners[owner]=callback;return true
end
function D:Unsubscribe(owner)
  if listeners[owner] then listeners[owner]=nil;count=count-1;generation=generation+1 end
  if count==0 then generation=generation+1;pending=setmetatable({}, {__mode="k"});bound=setmetatable({}, {__mode="k"});color=nil;position=nil end
end
function D:Supports(id)
  if (id=="feature.profession.note_added" or id=="feature.profession.navigate") and not K.modules.clock then return false end
  local control=C.definitions[id]
  if control and control.kind=="color" and not self:ColorSupported() then return false end
  local owner=settings[id] or features[id];return owner and ownerExists(owner) or false
end
function D:Capabilities()
  local out={};for id in pairs(settings) do if self:Supports(id) then out[id]=true end end
  for id in pairs(features) do if self:Supports(id) then out[id]=true end end
  return out
end
function D:Emit(id,phase,path,reason,changed)
  if count==0 then return end
  -- All data crossing this boundary is closed and static. No values or arbitrary strings.
  if not public(id) or not public(phase) or not public(path) or not public(reason) or not public(changed) then return end
  if not (settings[id] or features[id]) or not phases[phase] or path and not paths[path] or reason and not reasons[reason] then return end
  if changed~=nil and type(changed)~="boolean" then return end
  for _,callback in pairs(listeners) do pcall(callback,id,phase,path or "unknown",reason,changed) end
end
local function resolve(control)
  local b=bound[control];if not b then return nil end
  if b.resolve then local ok,id=pcall(b.resolve);return ok and settings[id] and id or nil end
  if b.context=="partyLayout" then
    local module=K.modules.partyFrames;local key=module and module.editedLayout or "party"
    local id=b.id.."."..key;return settings[id] and id or nil
  elseif b.context=="clockSide" then
    local parent=control
    for _=1,24 do
      if not parent then break end
      local key=parent.sideTargetKey
      if key then local id=b.id.."."..key;return settings[id] and id or nil end
      parent=parent:GetParent()
    end
    return nil
  end
  return b.id
end
local function bind(control,title,get)
  local route=control and control.settingsRoute
  if not route or type(get)~="function" or type(title)~="string" or not public(title) then return end
  if route.scope and type(route.scope)=="string" and route.scope:find("등록 목록",1,true) and not control.khqolStaticSetting then return end
  local item=K.UI and K.UI.SettingsNavigation and K.UI.SettingsNavigation.controls[control]
  title=item and item.logicalTitle or title
  local key={}
  for _,field in ipairs(fields) do local v=route[field];if v~=nil and (not public(v) or type(v)~="string" or #v>256) then return end;key[#key+1]=v or "" end
  key[#key+1]=title
  local meta=C.bindings[table.concat(key,"|")]
  local alias=C.aliases[(route.module or "").."|"..title]
  if meta and meta.kind=="check" and control:GetObjectType()~="CheckButton" and alias then meta=alias end
  meta=meta or alias
  if meta then bound[control]={id=meta.id,get=get,context=meta.context,kind=meta.kind} end
end
function D:Bind(control,title,get)
  if count==0 then return end
  pcall(bind,control,title,get)
end
function D:BindModule(control,get,resolver)
  if count==0 then return end
  if control and type(get)=="function" and type(resolver)=="function" then bound[control]={get=get,resolve=resolver,kind="check"} end
end
function D:ControlID(control)
  if count==0 then return nil end
  local ok,id=pcall(resolve,control);return ok and id or nil
end
local function begin(control,path,keep)
  if keep and pending[control] then return end
  pending[control]=nil
  if K.profileApplying or K.profileClosingEditors then return end
  local b=bound[control];local id=resolve(control)
  if not b or not id then return end
  local values=read(b.get)
  if values then pending[control]={id=id,values=values,path=paths[path] and path or "unknown",ticket=generation,profile=K.profileGeneration} end
end
function D:Begin(control,path,keep)
  if count==0 then return end
  pcall(begin,control,path,keep)
end
local function finish(control)
  local p=pending[control];pending[control]=nil
  if not p or p.ticket~=generation or p.profile~=K.profileGeneration or K.profileApplying or K.profileClosingEditors or resolve(control)~=p.id then return end
  local b=bound[control];local changed=b and different(p.values,read(b.get))
  if changed then D:Emit(p.id,"change",p.path,nil,true) end
end
function D:Finish(control)
  if count==0 then return end
  pcall(finish,control)
end
function D:Cancel(control) if count>0 and control then pending[control]=nil end end
function D:SliderValue(control,userInput)
  if count==0 then return end
  local down=K.PublicCall(IsMouseButtonDown,"LeftButton")
  if down==true or K.IsPublicValue(userInput) and userInput==true then self:Begin(control,"drag",true) end
end
local function okay(picker)
  return picker and (picker.OkayButton or picker.Footer and picker.Footer.OkayButton or _G.ColorPickerOkayButton)
end
local colorHooked=setmetatable({}, {__mode="k"})
function D:ColorSupported() return okay(ColorPickerFrame)~=nil end
function D:ColorCancel(control)
  if count==0 or not control then return end
  self:Cancel(control);if color and color.control==control then color=nil end
end
function D:CloseColor()
  if count==0 then return end
  if color then self:Cancel(color.control);color=nil end
end
function D:ColorOpen(control,picker)
  if count==0 or not control or not okay(picker) then return end
  local ok=pcall(function()
    self:Begin(control,"click");if not pending[control] then return end
    color={control=control,picker=picker,ticket=generation}
    local button=okay(picker)
    if not colorHooked[button] then
      button:HookScript("OnClick",function()
        if count==0 or not color or color.picker~=picker then return end
        local current=color;color=nil
        if current.ticket==generation then D:Finish(current.control) end
      end);colorHooked[button]=true
    end
    if not colorHooked[picker] then
      picker:HookScript("OnHide",function()
        if count==0 or not color or color.picker~=picker then return end
        local current=color
        -- Native OK hides before its post-click observer. Keep only this one turn open.
        if C_Timer and C_Timer.After then C_Timer.After(0,function()
          if count>0 and color==current then D:ColorCancel(current.control) end
        end) else D:ColorCancel(current.control) end
      end);colorHooked[picker]=true
    end
  end)
  if not ok then self:ColorCancel(control) end
end
function D:PositionStart(editor)
  if count==0 then return end
  pcall(function()
    local session={editor=editor,ticket=generation,reads={},touched={},unknown=false}
    for _,h in ipairs(editor.handles or {}) do if h.target then session.reads[h.target]=read(h.target.usageRead) end end
    position=session;self:Emit("feature.position.start","start","click")
  end)
end
function D:PositionCall(editor,kind,target,fn,...)
  -- Called in the same order as the original writers. No subscriber: exact direct invocation.
  if count==0 or not position or position.editor~=editor then return fn(...) end
  if target and (kind=="write" or kind=="reset") then position.touched[target]=true end
  local result=pack(pcall(fn,...))
  if not result[1] then
    self:Emit("feature.position.unconfirmed","unconfirmed","unknown","apply")
    position=nil;error(result[2],0)
  end
  if K.IsPublicValue(result[2]) and result[2]==false then position.failed=true end
  return unpack(result,2,result.n)
end
function D:PositionEnd(editor,save,reason)
  if count==0 then return end
  pcall(function()
    local s=position;position=nil
    if not s or s.editor~=editor or s.ticket~=generation then return end
    if not save then self:Emit("feature.position.cancel","cancel","click",reasons[reason] and reason or "unknown");return end
    if s.failed then self:Emit("feature.position.unconfirmed","unconfirmed","unknown","apply");return end
    local changed,unknown=false,false
    for target in pairs(s.touched) do
      local different_=different(s.reads[target],read(target.usageRead))
      if different_==nil then unknown=true elseif different_ then changed=true end
    end
    self:Emit("feature.position.save","save","click",nil,changed)
    if changed then self:Emit("feature.position.changed","changed","click",nil,true)
    elseif unknown then self:Emit("feature.position.unconfirmed","unconfirmed","unknown","unavailable") end
  end)
end
