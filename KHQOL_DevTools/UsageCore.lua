local U=_G.KHQOLDevUsage
local MAX=1000000000
local floor,min,max=math.floor,math.min,math.max
local paths={drag=true,arrow=true,input=true,click=true,unknown=true}
local reasons={explicit=true,escape=true,combat=true,profile=true,navigation=true,hidden=true,world=true,validation=true,apply=true,unavailable=true,unknown=true}
local codes={callback=true,hook=true,clock=true,dwell_capped=true,version_limit=true}
local function public(v)
  if type(issecretvalue)~="function" then return true end
  local ok,secret=pcall(issecretvalue,v);return ok and not secret
end
U.IsPublic=public
local function number(v,limit)
  if not public(v) or type(v)~="number" or v~=v or v<0 or v==math.huge then return 0 end
  return min(v,limit or MAX)
end
local function count(v) return floor(number(v)) end
local function plain(v) return public(v) and type(v)=="table" and getmetatable(v)==nil end
local function keys(t) local a={};for k in pairs(t) do a[#a+1]=k end;table.sort(a);return a end
local function dayKey(epoch) return date("!%Y-%m-%d",epoch) end
local function validDay(key)
  if type(key)~="string" or #key~=10 then return false end
  local y,m,d=key:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
  if not y then return false end
  y,m,d=tonumber(y),tonumber(m),tonumber(d)
  if y<2000 or y>2100 or m<1 or m>12 then return false end
  local days={31,(y%4==0 and (y%100~=0 or y%400==0)) and 29 or 28,31,30,31,30,31,31,30,31,30,31}
  return d>=1 and d<=days[m]
end
local function version(v)
  return public(v) and type(v)=="string" and #v<=32 and v:match("^%d+%.%d+%.%d+[%d.]*$") and v or "unavailable"
end
local function versionPair(v)
  if type(v)~="string" or #v>80 then return false end
  local a,b=v:match("^([^/]+)/([^/]+)$")
  return a and (a=="unavailable" or version(a)==a) and version(b)==b
end
local function blank(enabled)
  return {schema=U.SCHEMA,usageVersion=U.VERSION,catalogRevision=U.CATALOG_REVISION,enabled=enabled==true,
    days={},diagnostics={}}
end
-- Build from allowed fields instead of trusting, serializing or copying arbitrary saved data.
function U:Sanitize(raw)
  local out=blank(plain(raw) and raw.enabled==true)
  if not plain(raw) then return out end
  if plain(raw.diagnostics) then for code in pairs(codes) do
    if count(raw.diagnostics[code])>0 then out.diagnostics[code]=count(raw.diagnostics[code]) end
  end end
  local dates={}
  if plain(raw.days) then for key,v in pairs(raw.days) do
    if validDay(key) and plain(v) then dates[#dates+1]=key end
  end end
  table.sort(dates)
  for i=max(1,#dates-29),#dates do
    local key=dates[i];local src=raw.days[key]
    local d={menus={},settings={},features={},observed={},routes={},versions={},versionsLimited=src.versionsLimited==true,recordingSeconds=number(src.recordingSeconds,86400)}
    for id,meta in pairs(self.catalog) do
      local bucket=plain(src[meta.kind]) and src[meta.kind][id]
      if plain(src.observed) and src.observed[id]==true then d.observed[id]=true end
      if plain(src.routes) and plain(src.routes[id]) then
        local routes={};for _,route in ipairs({"direct","bridge"}) do if src.routes[id][route]==true then routes[route]=true end end
        if next(routes) then d.routes[id]=routes end
      end
      if plain(bucket) then
        if meta.kind=="menus" then d.menus[id]={visits=count(bucket.visits),validVisits=count(bucket.validVisits),seconds=number(bucket.seconds,86400)}
        elseif meta.kind=="settings" then
          local p={};for path in pairs(paths) do if plain(bucket.paths) and count(bucket.paths[path])>0 then p[path]=count(bucket.paths[path]) end end
          d.settings[id]={changes=count(bucket.changes),paths=p}
        else
          local why={};for reason in pairs(reasons) do if plain(bucket.reasons) and count(bucket.reasons[reason])>0 then why[reason]=count(bucket.reasons[reason]) end end
          d.features[id]={count=count(bucket.count),active=bucket.active==true,reasons=why}
        end
        -- A stored counter proves observation on this day even if its flag was damaged.
        d.observed[id]=true
      end
    end
    if plain(src.versions) then
      local versions={};for v,on in pairs(src.versions) do if on==true and versionPair(v) then versions[#versions+1]=v end end
      table.sort(versions);for j=1,min(8,#versions) do d.versions[versions[j]]=true end
      if #versions>8 then d.versionsLimited=true end
    end
    out.days[key]=d
  end
  if validDay(raw.firstDate) then out.firstDate=raw.firstDate end
  if validDay(raw.lastDate) then out.lastDate=raw.lastDate end
  if #dates>0 then
    if not out.firstDate or dates[1]<out.firstDate then out.firstDate=dates[1] end
    if not out.lastDate or dates[#dates]>out.lastDate then out.lastDate=dates[#dates] end
  end
  return out
end
function U:Now() return time() end
function U:Mono() return GetTime() end
function U:Enabled() return self.db and self.db.enabled==true and not self.future and not self.leaving end
function U:Error(code)
  if not self:Enabled() or not codes[code] then return end
  self.db.diagnostics[code]=min(MAX,(self.db.diagnostics[code] or 0)+1)
end
function U:Guard(fn)
  return function(...)
    if not U:Enabled() then return end
    local ok=pcall(fn,...);if not ok then U:Error("callback") end
  end
end
function U:Prune()
  if not self:Enabled() then return end
  local today=dayKey(self:Now());local oldest=dayKey((floor(self:Now()/86400)-29)*86400)
  for key in pairs(self.db.days) do if key<oldest or key>today then self.db.days[key]=nil end end
end
function U:Day(target,epoch)
  local key=dayKey(epoch);local d=target.days[key]
  if not d then d={menus={},settings={},features={},observed={},routes={},versions={},recordingSeconds=0};target.days[key]=d end
  if not target.firstDate or key<target.firstDate then target.firstDate=key end
  if not target.lastDate or key>target.lastDate then target.lastDate=key end
  local pair=version(_G.KHQOL and _G.KHQOL.VERSION).."/"..self.DEV_VERSION
  if not d.versions[pair] then
    local n=0;for _ in pairs(d.versions) do n=n+1 end
    if n<8 then d.versions[pair]=true
    else
      if not d.versionsLimited and target==self.db then self:Error("version_limit") end
      d.versionsLimited=true
    end
  end
  return d,key
end
function U:Touch(id)
  if not self:Enabled() or not self.catalog[id] then return end
  self:Prune()
  local d,key=self:Day(self.db,self:Now());d.observed[id]=true
  local route=self.selectedRoutes and self.selectedRoutes[id] or "direct"
  d.routes[id]=d.routes[id] or {};d.routes[id][route]=true
end
function U:Counter(id,path,active,reason,source)
  if not self:Enabled() or self.paused then return end
  local meta=self.catalog[id];if not meta or meta.kind=="menus" or meta.class=="HOLD" then return end
  source=source or "direct"
  local selected=self.selectedRoutes and self.selectedRoutes[id]
  if source=="bridge" then if selected~="bridge" or not self.bridge then return end
  elseif selected=="bridge" or meta.class=="BRIDGE" and meta.fallback~="DIRECT" then return end
  self:Touch(id);local d=self:Day(self.db,self:Now())
  if meta.kind=="settings" then
    local b=d.settings[id] or {changes=0,paths={}};d.settings[id]=b
    b.changes=min(MAX,b.changes+1);path=paths[path] and path or "unknown"
    b.paths[path]=min(MAX,(b.paths[path] or 0)+1)
  else
    local b=d.features[id] or {count=0,active=false,reasons={}};d.features[id]=b
    if active then b.active=true else b.count=min(MAX,b.count+1) end
    if reasons[reason] then b.reasons=b.reasons or {};b.reasons[reason]=min(MAX,(b.reasons[reason] or 0)+1) end
  end
end
local function menuBucket(d,id)
  local b=d.menus[id] or {visits=0,validVisits=0,seconds=0};d.menus[id]=b;d.observed[id]=true
  d.routes=d.routes or {};d.routes[id]=d.routes[id] or {};d.routes[id].direct=true;return b
end
local function split(start,finish,fn)
  while start<finish do
    local edge=min(finish,(floor(start/86400)+1)*86400)
    fn(start,edge-start);start=edge
  end
end
function U:Accrue(target,preview)
  local seg=self.segment
  if seg then
    local elapsed=max(0,self:Mono()-seg.mono);local total=min(1800,elapsed)
    if elapsed>1800 and not preview and not seg.capped then self:Error("dwell_capped");seg.capped=true end
    local seen={};for day,on in pairs(seg.visit.days) do seen[day]=on end
    split(seg.epoch+seg.recorded,seg.epoch+max(seg.recorded,total),function(at,seconds)
      local d,key=self:Day(target,at);local b=menuBucket(d,seg.id)
      b.seconds=min(86400,b.seconds+seconds)
      if not seen[key] then b.validVisits=min(MAX,b.validVisits+1);seen[key]=true end
    end)
    if not preview then seg.recorded=max(seg.recorded,total);seg.visit.days=seen end
  end
  local coverage=self.coverage
  if coverage then
    local total=max(coverage.recorded,self:Mono()-coverage.mono)
    -- No persistent event timestamps; retain daily coverage seconds only.
    total=min(31*86400,total)
    split(coverage.epoch+coverage.recorded,coverage.epoch+total,function(at,seconds)
      local d=self:Day(target,at);d.recordingSeconds=min(86400,d.recordingSeconds+seconds)
    end)
    if not preview then
      coverage.epoch=coverage.epoch+total;coverage.mono=self:Mono();coverage.recorded=0
    end
  end
end
function U:Flush()
  if not self:Enabled() then return end
  self:Accrue(self.db,false);self:Prune()
end
function U:SetMenu(id,user)
  if not self:Enabled() then return end
  if id and (not self.catalog[id] or self.catalog[id].kind~="menus") then id=nil end
  if id==self.currentMenu then return end
  self:Flush();self.segment=nil;self.currentMenu=id
  if not id or self.paused then return end
  self:Touch(id)
  local visit=(not user and self.lastVisit and self.lastVisit.id==id) and self.lastVisit or {id=id,days={}}
  self.lastVisit=visit
  if user then local d=self:Day(self.db,self:Now());local b=menuBucket(d,id);b.visits=min(MAX,b.visits+1) end
  self.segment={id=id,epoch=self:Now(),mono=self:Mono(),recorded=0,visit=visit}
end
function U:Pause(on)
  on=on==true;if on==self.paused then return end
  self:Flush();self.segment=nil;self.paused=on
  if self.CancelInputs then self:CancelInputs() end
  if not on and self.currentMenu then
    local visit=self.lastVisit
    if not visit or visit.id~=self.currentMenu then visit={id=self.currentMenu,days={}};self.lastVisit=visit end
    self.segment={id=self.currentMenu,epoch=self:Now(),mono=self:Mono(),recorded=0,
      visit=visit}
    if self.ActiveDays then self:ActiveDays() end
  end
end
function U:CancelScheduled()
  self.epoch=(self.epoch or 0)+1
  if self.midnight and self.midnight.Cancel then self.midnight:Cancel() end
  self.midnight=nil;self.navigationTicket=nil;self.connectTicket=nil
  if self.CancelInputs then self:CancelInputs() end
end
function U:ScheduleMidnight()
  if not self:Enabled() or not C_Timer then return end
  local generation=self.epoch;local delay=(floor(self:Now()/86400)+1)*86400-self:Now()+.05
  local callback=self:Guard(function()
    if generation~=U.epoch then return end
    U.midnight=nil;U:Flush()
    if U.MarkCoverage then U:MarkCoverage() end
    if U.ActiveDays then U:ActiveDays() end
    U:ScheduleMidnight()
  end)
  if C_Timer.NewTimer then self.midnight=C_Timer.NewTimer(delay,callback)
  elseif C_Timer.After then C_Timer.After(delay,callback) end
end
function U:SetRecording(on)
  if not self.db or self.future then return false end
  on=on==true;if on==self.db.enabled and not self.leaving then return true end
  if self:Enabled() then self:Flush() end
  if self.DisconnectBridge then self:DisconnectBridge() end
  self:CancelScheduled();self.segment=nil;self.coverage=nil;self.currentMenu=nil;self.lastVisit=nil
  self.leaving=nil;self.db.enabled=on;self.enrolled=nil
  if self.events then
    if on and self.afkEvent then pcall(self.events.RegisterEvent,self.events,"PLAYER_FLAGS_CHANGED")
    else self.events:UnregisterEvent("PLAYER_FLAGS_CHANGED") end
  end
  if on then
    self:Prune();self.coverage={epoch=self:Now(),mono=self:Mono(),recorded=0}
    self:Day(self.db,self:Now())
    if self.Connect then self:Connect() end
    self:ScheduleMidnight()
  end
  return true
end
function U:Reset(confirmed)
  if not confirmed or self.future or not self.db then return false end
  local on=self.db.enabled
  if self.DisconnectBridge then self:DisconnectBridge() end
  self:CancelScheduled();self.segment=nil;self.coverage=nil;self.currentMenu=nil;self.lastVisit=nil
  self.db=blank(false);_G.KHQOLDevUsageDB=self.db;self.leaving=nil
  if on then self:SetRecording(true) end
  return true
end
local function quote(s)
  return '"'..s:gsub('[%z\1-\31\\"]',function(c)
    local escaped={['"']='\\"',['\\']='\\\\',['\n']='\\n',['\r']='\\r',['\t']='\\t'}
    return escaped[c] or string.format("\\u%04x",string.byte(c))
  end)..'"'
end
function U:JSON(v)
  if type(v)=="string" then return quote(v) end
  if type(v)=="number" then assert(v==v and math.abs(v)<math.huge);return string.format("%.6f",v):gsub(",","."):gsub("0+$",""):gsub("%.$","") end
  if type(v)=="boolean" then return v and "true" or "false" end
  if v==nil then return "null" end
  assert(type(v)=="table")
  local items={}
  for _,key in ipairs(keys(v)) do items[#items+1]=quote(key)..":"..self:JSON(v[key]) end
  return "{"..table.concat(items,",").."}"
end
function U:Snapshot(range)
  range=range==7 and 7 or 30
  local data=self:Sanitize(self.future and {} or self.db)
  if self:Enabled() then self:Accrue(data,true) end
  local endDay=floor(self:Now()/86400);local days,totals={},{menus={},settings={},features={}}
  local instrumentation,observedVersions={},{}
  for id,meta in pairs(self.catalog) do
    local item={};for key,v in pairs(meta) do item[key]=v end
    item.available=self.available and self.available[id]==true or false;item.observedDays=0;item.observedRoutes={}
    item.selectedRoute=self.selectedRoutes and self.selectedRoutes[id] or item.available and "direct" or "unavailable"
    item.connected=item.available;item.inGame="NOT TESTED"
    item.verdict=meta.verdict or meta.class=="HOLD" and "HOLD" or meta.class=="LIMITED" and "LIMITED GO" or "GO"
    if item.selectedRoute=="direct" and meta.class=="BRIDGE" then item.verdict="LIMITED GO" end
    instrumentation[id]=item
  end
  for offset=range-1,0,-1 do
    local key=dayKey((endDay-offset)*86400);local d=data.days[key]
    days[key]=d or {recordingSeconds=0,observed={},routes={},versions={},menus={},settings={},features={},noData=true}
    if d then
      for pair in pairs(d.versions) do observedVersions[pair]=true end
      for id in pairs(d.observed) do instrumentation[id].observedDays=instrumentation[id].observedDays+1 end
      for id,routes in pairs(d.routes or {}) do for route in pairs(routes) do instrumentation[id].observedRoutes[route]=true end end
      for id,b in pairs(d.menus) do
        local t=totals.menus[id] or {visits=0,validVisits=0,seconds=0};totals.menus[id]=t
        t.visits=t.visits+b.visits;t.validVisits=t.validVisits+b.validVisits;t.seconds=t.seconds+b.seconds
      end
      for id,b in pairs(d.settings) do
        local t=totals.settings[id] or {changes=0,paths={}};totals.settings[id]=t;t.changes=t.changes+b.changes
        for path,n in pairs(b.paths) do t.paths[path]=(t.paths[path] or 0)+n end
      end
      for id,b in pairs(d.features) do
        local t=totals.features[id] or {count=0,activeDays=0,reasons={}};totals.features[id]=t
        t.count=t.count+b.count;if b.active then t.activeDays=t.activeDays+1 end
        for reason,n in pairs(b.reasons or {}) do t.reasons[reason]=(t.reasons[reason] or 0)+n end
      end
    end
  end
  for _,t in pairs(totals.menus) do t.averageSeconds=t.validVisits>0 and t.seconds/t.validVisits or 0 end
  return {schema=self.SCHEMA,usageVersion=self.VERSION,devToolsVersion=self.DEV_VERSION,catalogRevision=self.CATALOG_REVISION,
    currentInstallation={khqolVersion=version(_G.KHQOL and _G.KHQOL.VERSION),devToolsVersion=self.DEV_VERSION,bridgeProtocol=self.bridge and self.bridge.API or 0},
    range={days=range,from=dayKey((endDay-range+1)*86400),to=dayKey(endDay*86400),timeBasis="UTC"},
    collection={enabled=self:Enabled(),firstDate=data.firstDate,lastDate=data.lastDate,paused=self.paused==true,
      futureSchemaPreserved=self.future==true,khqolPresent=type(_G.KHQOL)=="table",
      afkSupported=self.afkSupported==true,backgroundSupported=false,bridgeStatus=self.bridgeStatus or "unavailable",
      bridgeProtocol=self.bridge and self.bridge.API or 0,inGame="NOT TESTED"},
    observedVersions=observedVersions,days=days,totals=totals,instrumentation=instrumentation,rules=self.rules,diagnostics=data.diagnostics}
end
function U:Export(range) return self:JSON(self:Snapshot(range)) end
function U:QueueConnect()
  if not self:Enabled() or self.connectTicket then return end
  if not C_Timer or type(C_Timer.After)~="function" then return end
  local ticket={epoch=self.epoch};self.connectTicket=ticket
  C_Timer.After(0,self:Guard(function()
    if U.connectTicket~=ticket or ticket.epoch~=U.epoch then return end
    U.connectTicket=nil;if U.Connect then U:Connect() end
  end))
end
function U:Initialize()
  if self.DisconnectBridge then self:DisconnectBridge() end
  local raw=_G.KHQOLDevUsageDB
  if plain(raw) and number(raw.schema)>self.SCHEMA then self.future=true;self.db=raw;return end
  self.db=self:Sanitize(raw);_G.KHQOLDevUsageDB=self.db
  self.epoch=(self.epoch or 0)+1;self.available={};self.selectedRoutes={};self.paused=false
  local on=self.db.enabled;self.db.enabled=false
  if on then self:SetRecording(true) end
end
local events=CreateFrame("Frame")
U.events=events
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_LOGOUT")
events:RegisterEvent("PLAYER_LEAVING_WORLD")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
U.afkEvent=pcall(events.RegisterEvent,events,"PLAYER_FLAGS_CHANGED")
events:UnregisterEvent("PLAYER_FLAGS_CHANGED")
events:SetScript("OnEvent",function(_,event,name)
  if event=="ADDON_LOADED" and name=="KHQOL_DevTools" then
    local ok=pcall(U.Initialize,U);if not ok then U.initializationFailed=true;U:Error("callback") end
    if U.RefreshPanel then U:RefreshPanel() end
    return
  end
  if event=="PLAYER_ENTERING_WORLD" and U.db and U.db.enabled and U.leaving then U.leaving=nil;U.db.enabled=false;U:SetRecording(true);return end
  if not U:Enabled() then return end
  local ok=pcall(function()
    if event=="PLAYER_LOGOUT" or event=="PLAYER_LEAVING_WORLD" then
      U:Flush();if U.DisconnectBridge then U:DisconnectBridge() end;U:CancelScheduled();U.segment=nil;U.coverage=nil;U.currentMenu=nil;U.leaving=true
    elseif event=="PLAYER_FLAGS_CHANGED" and (name=="player" or name==nil) then
      if U.CheckAFK then U:CheckAFK() end
    elseif event=="ADDON_LOADED" then
      -- Do not reconnect or touch UI while a protected Blizzard addon is loading.
      if U.IsPublic(name) and U.managedAddons[name] then U:QueueConnect() end
    elseif event=="PLAYER_LOGIN" or event=="PLAYER_ENTERING_WORLD" then
      if U.Connect then U:Connect() end
    end
  end)
  if not ok then U:Error("callback") end
end)
