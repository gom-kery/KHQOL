local _, KHQOL = ...
local M={}; KHQOL.modules.basicUI=M
local call,public=KHQOL.PublicCall,KHQOL.IsPublicValue
M.defaults={bags="default",micro="default",hideDelay=.5}
function M:GetDB()
  KHQOL.db.modules.basicUI=KHQOL.MergeDefaults(KHQOL.db.modules.basicUI or {},self.defaults,"tables")
  return KHQOL.db.modules.basicUI
end
function M:IsEnabled() return KHQOL.db and KHQOL:GetEnabled("basicUI") end
local function points(frame)
  local count=call(frame.GetNumPoints,frame)
  if type(count)~="number" or count<0 or count>32 or count~=math.floor(count) then return end
  local p={}
  for i=1,count do
    local status,point,relative,relativePoint,x,y=KHQOL.ReadPublicAPI(frame.GetPoint,frame,i)
    if status~="ok" then return end
    p[i]={point,relative,relativePoint,x,y}
  end
  return p
end
local function equal(a,b)
  if a==b then return true end
  if type(a)~="table" or type(b)~="table" then return a==b end
  if a.GetObjectType or b.GetObjectType then return false end
  if #a~=#b then return false end
  for i=1,#a do if not equal(a[i],b[i]) then return false end end
  return true
end
local function applyPoints(frame,p)
  frame:ClearAllPoints(); for _,point in ipairs(p) do frame:SetPoint(unpack(point)) end
end
-- Each property has its own live baseline and last written value. External
-- changes become the new baseline; release never overwrites a later mutation.
local getters={alpha=function(f) return f:GetAlpha() end,width=function(f) return f:GetWidth() end,
  height=function(f) return f:GetHeight() end,points=points,mouse=function(f) return f:IsMouseEnabled() end,
  motion=function(f) return f:IsMouseMotionEnabled() end}
local setters={alpha=function(f,v) f:SetAlpha(v) end,width=function(f,v) f:SetWidth(v) end,
  height=function(f,v) f:SetHeight(v) end,points=applyPoints,mouse=function(f,v) f:EnableMouse(v) end,
  motion=function(f,v) f:EnableMouseMotion(v) end}
local function readProperty(frame,key)
  local status,value
  if key=="width" or key=="height" then
    local getter=key=="width" and frame.GetWidth or frame.GetHeight
    -- Save the explicitly requested size, not a secret resolved anchor rect.
    status,value=KHQOL.ReadPublicAPI(getter,frame,true)
    if status=="error" then status,value=KHQOL.ReadPublicAPI(getter,frame) end
  else status,value=KHQOL.ReadPublicAPI(getters[key],frame) end
  if status~="ok" then return false end
  if key=="points" then return type(value)=="table",value end
  if key=="mouse" or key=="motion" then return type(value)=="boolean",value end
  return type(value)=="number" and value==value and math.abs(value)<math.huge,value
end
function M:CanRead(frame,key)
  return readProperty(frame,key)
end
function M:Write(owner,frame,key,value)
  if not frame then return true end
  local readable,current=readProperty(frame,key)
  if not readable then self.propertyDeferred=true; self.pending=true; return false end
  owner.records=owner.records or {}; owner.records[frame]=owner.records[frame] or {}
  local record=owner.records[frame][key]
  if not record then record={original=current}; owner.records[frame][key]=record
  elseif not equal(current,record.last) then record.original=current end
  if not equal(current,value) and KHQOL.ReadPublicAPI(setters[key],frame,value)~="ok" then
    self.propertyDeferred=true; self.pending=true; return false
  end
  readable,current=readProperty(frame,key)
  -- Last requested value is public even if native updates make it unreadable.
  record.last=readable and current or value
  return true
end
function M:Release(owner)
  for frame,keys in pairs(owner.records or {}) do
    for key,record in pairs(keys) do
      local readable,current=readProperty(frame,key)
      if not readable then
        self.propertyDeferred=true; self.pending=true
      elseif not equal(current,record.last) or KHQOL.ReadPublicAPI(setters[key],frame,record.original)=="ok" then
        keys[key]=nil
      else self.propertyDeferred=true; self.pending=true end
    end
    if not next(keys) then owner.records[frame]=nil end
  end
  if owner.records and not next(owner.records) then owner.records=nil end
end
local function combat() return call(InCombatLockdown)==true end
local function editing() return EditModeManagerFrame and call(EditModeManagerFrame.IsShown,EditModeManagerFrame)==true end
local function cancel(owner)
  if owner.timer then owner.timer:Cancel(); owner.timer=nil end
  owner.generation=(owner.generation or 0)+1
end
function M:FadeBar(owner,hide)
  if combat() then self.pending=true; return end
  if hide then
    self:Write(owner,owner.frame,"alpha",0)
    local function disable(frame)
      if frame.EnableMouse and frame.IsMouseEnabled then M:Write(owner,frame,"mouse",false) end
      for _,child in ipairs({frame:GetChildren()}) do disable(child) end
    end
    disable(owner.frame)
  else self:Release(owner) end
  if owner.sensor then owner.sensor:SetShown(hide and owner.mode=="hover" and owner.frame:IsShown()) end
end
function M:BarEnter(owner)
  if owner.mode~="hover" or not self:IsEnabled() then return end
  cancel(owner); self:FadeBar(owner,false)
end
function M:BarLeave(owner)
  if owner.mode~="hover" or not self:IsEnabled() then return end
  cancel(owner); local generation=owner.generation
  local delay=tonumber(self:GetDB().hideDelay) or .5; delay=math.max(0,math.min(2,delay))
  if C_Timer and C_Timer.NewTimer then
    owner.timer=C_Timer.NewTimer(delay,function()
      owner.timer=nil
      if generation~=owner.generation or owner.mode~="hover" or not M:IsEnabled() then return end
      if call(MouseIsOver,owner.frame)~=true then M:FadeBar(owner,true) end
    end)
  end
end
function M:CreateBar(frame,key)
  if not frame then return end
  self.bars=self.bars or {}; local owner=self.bars[key]
  if owner then return owner end
  owner={frame=frame,key=key}; self.bars[key]=owner
  local sensor=CreateFrame("Frame",nil,UIParent); owner.sensor=sensor
  sensor:SetAllPoints(frame); sensor:SetFrameStrata(frame:GetFrameStrata()); sensor:SetFrameLevel(math.max(1,frame:GetFrameLevel()-1))
  sensor:EnableMouse(true); sensor:Hide()
  sensor:SetScript("OnEnter",function() M:BarEnter(owner) end)
  sensor:SetScript("OnLeave",function() M:BarLeave(owner) end)
  local function hookChildren(f)
    if f.HookScript and f.HasScript and f:HasScript("OnEnter") then
      f:HookScript("OnEnter",function() M:BarEnter(owner) end)
      f:HookScript("OnLeave",function() M:BarLeave(owner) end)
    end
    for _,child in ipairs({f:GetChildren()}) do hookChildren(child) end
  end
  hookChildren(frame)
  frame:HookScript("OnShow",function() if M:IsEnabled() then M:ApplyBars() end end)
  frame:HookScript("OnHide",function() sensor:Hide(); cancel(owner) end)
  return owner
end
function M:ApplyBars()
  if combat() then self.pending=true; return end
  local db=self:GetDB()
  local bags=self:CreateBar(_G.BagsBar,"bags")
  local micro=self:CreateBar(_G.MicroMenu,"micro")
  for _,owner in pairs(self.bars or {}) do
    local mode=self:IsEnabled() and not editing() and db[owner.key] or "default"
    if owner.mode~=mode then cancel(owner); self:Release(owner); owner.mode=mode end
    if mode=="default" then cancel(owner); self:FadeBar(owner,false)
    elseif mode=="hide" then self:FadeBar(owner,true)
    elseif mode=="hover" then
      self:FadeBar(owner,call(MouseIsOver,owner.frame)~=true)
    end
  end
end
function M:ApplySettings()
  if self.applying then return end
  self.applying=true
  self.propertyDeferred=false
  self:ApplyBars()
  if not combat() and not self.propertyDeferred then self.pending=nil end
  self.applying=false
end
function M:SetEnabled(on)
  self:Initialize()
  self.events:UnregisterAllEvents()
  for _,event in ipairs({"PLAYER_REGEN_ENABLED","ADDON_LOADED"}) do self.events:RegisterEvent(event) end
  if on then
    for _,event in ipairs({"PLAYER_ENTERING_WORLD"}) do pcall(self.events.RegisterEvent,self.events,event) end
  end
  for _,owner in pairs(self.bars or {}) do cancel(owner) end
  self:ApplySettings()
end
function M:Initialize()
  if self.events then return end
  self.events=CreateFrame("Frame")
  for _,event in ipairs({"PLAYER_REGEN_ENABLED","PLAYER_ENTERING_WORLD","ADDON_LOADED"}) do pcall(self.events.RegisterEvent,self.events,event) end
  self.events:SetScript("OnEvent",function(_,event,unit)
    if event=="PLAYER_REGEN_ENABLED" then M:ApplySettings()
    elseif M:IsEnabled() and (not unit or unit=="player" or unit=="target" or event=="ADDON_LOADED") then M:ApplySettings() end
  end)
  if EditModeManagerFrame then
    EditModeManagerFrame:HookScript("OnShow",function() M:ApplySettings() end)
    EditModeManagerFrame:HookScript("OnHide",function() M:ApplySettings() end)
  end
end
