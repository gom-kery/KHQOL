local _,K=...
local UI,N=K.UI,K.UI.SettingsNavigation
local A={pool={},active={}}
K.PositionAnchors=A
local function call(fn,...) return K.PublicCall(fn,...) end
local function combat() return not K.WindowLayers:OutsideCombat() end
function A:Unlocked(e,closing)
  if not K.db or K.profileApplying or not closing and K.profileClosingEditors then return false end
  local available=e.headless and (e.independent or K:CanRunModule(e.route.module)) and (not e.enabled or call(e.enabled)==true) or not e.headless and UI:IsAvailable(e.control,e.enabled)
  return e.get and call(e.get)==false and available and (not e.show or call(e.show)==true)
end
function A:Entries()
  local result,seen={},{}
  local function key(e) local p=e.route;return table.concat({p.module or '',p.unit or '',p.part or '',p.castUnit or '',e.title or ''},'|') end
  local L=UI.PositionLocks
  for _,id in ipairs(L.order) do local e=L.entries[id];result[#result+1]=e;seen[key(e)]=true end
  local function add(route,title,get,enabled,ids,independent)
    local e={route=route,title=title,get=get,enabled=enabled,control={positionTargets=ids},headless=true,independent=independent}
    if not seen[key(e)] then result[#result+1]=e;seen[key(e)]=true end
  end
  local m=K.modules
  if m.unitFrames then for _,unit in ipairs(m.unitFrames.unitTokens) do for _,part in ipairs({'basic','labels','status','auras'}) do
    local u,p=unit,part
    add({module='unitFrames',unit=u,part=p},'위치 잠금',function() return m.unitFrames:GetDB()[u].positionLocks[p] end,function() return m.unitFrames:PositionPartAvailable(u,p) end)
  end end end
  if m.clock and m.clock.db then
    add({module='clock'},'위치 잠금',function() return m.clock.db.locked end)
  end
  if m.experienceBar then add({module='experienceBar'},'위치 잠금',function() return not m.experienceBar.unlocked end,function() return m.experienceBar.db.mode=='horizontal' end) end
  if m.environmentTimer and m.environmentTimer.db then
    add({module='environmentTimer'},'위치 잠금',function() return not m.environmentTimer.unlocked end)
  end
  if m.castBar then
    add({module='castBar',castUnit='player'},'위치 잠금',function() return m.castBar:GetDB().position.locked end,function() return not m.castBar.linked end)
    add({module='castBar',castUnit='target'},'대상 시전바 위치 잠금',function() return m.castBar:GetDB().targetPosition.locked end,function() return m.castBar:GetDB().targetPosition.enabled end)
  end
  if m.generalConvenience then add({module='generalConvenience'},'위치 잠금',function() return m.generalConvenience:GetDB().bagTrash.locked end,function() local d=m.generalConvenience:GetDB().bagTrash;return d.enabled and d.mode=='free' end,{'bagTrash'}) end
  if m.range and m.range.db then
    add({module='range'},'위치 잠금',function() return m.range.db.locked end,function() return m.range.db.displayMode~='distance' end,{'range'})
    add({module='range'},'거리 위치 잠금',function() return m.range.db.distance.locked end,function() return m.range.db.displayMode=='distance' end,{'range.distance'})
  end
  if m.npcAlert then add({module='npcAlert'},'위치 잠금',function() return m.npcAlert:GetDB().locked end,function() return m.npcAlert:GetDB().banner end) end
  if m.partyFrames then
    for _,kind in ipairs({'party','raid'}) do local k=kind
      add({module='partyFrames',tab='frames'},k=='party' and '파티 위치 잠금' or '공격대 위치 잠금',function() return m.partyFrames:GetDB().positionLocks[k] end,nil,{'partyFrames.'..k})
    end
  end
  if m.nativeAlerts then for _,v in ipairs({{'roll','주사위 굴림 위치 잠금'},{'alerts','도안 습득 알림 위치 잠금'}}) do
    local k,title=v[1],v[2];add({module='basicUI'},title,function() return m.nativeAlerts:GetDB()[k].locked end,function() return m.nativeAlerts:GetDB()[k].enabled end,{'basicUI.'..k},true)
  end end
  return result
end
function A:Matches(e,t)
  local ids=e.control.positionTargets
  if ids then for _,id in ipairs(ids) do if t.id==id then return true end end;return false end
  local p=e.route
  if p.module=='generalConvenience' then return e.title=='위치 잠금' and t.id=='bagTrash' end
  if p.module=='unitFrames' and p.part=='status' and (p.unit=='player' or p.unit=='target') and t.id=='unitFrames.'..p.unit..'.status' and not t.anchorFallback then return false end
  if p.module=='clock' then
    local tool=t.id=='clock.tools' or t.id=='clock.timerBar' or t.id=='clock.alert' or t.id=='clock.stopwatch'
    return (e.title~='위치 잠금')==tool
  end
  if p.module=='resourceSwing' then return (e.title:find('콤보',1,true)~=nil)==(t.id=='resource.combo') end
  if p.module=='unitFrames' and p.part=='class' then return t.id=='ammo' end
  N:EditorMeta(t)
  local r=t.settingsRoute
  if not r or r.module~=p.module then return false end
  for _,key in ipairs({'tab','unit','part','category','castUnit'}) do if p[key] and r[key]~=p[key] then return false end end
  return true
end
function A:Targets(e)
  local owner=e.route.module
  local list={}
  if owner=='basicUI' then owner='nativeAlerts' end
  local focus
  if owner=='partyFrames' then focus='partyFrames.anchor.'..(e.title=='파티 위치 잠금' and 'party' or K.modules.partyFrames:AnchorRaidLayout()) end
  if owner=='unitFrames' and e.route.unit=='target' and e.route.part=='auras' then focus='unitFrames.target.auras.'..(N:Preferences().auraCategory or 'friendlyPlayer') end
  K.ModuleRegistry:PositionTargets(focus,function(...) K.PositionUtils:Add(list,...) end,owner)
  if owner=='todo' or owner=='questNavigator' then K:AddNavigationPositionTarget(list,owner) end
  local result={}
  for _,t in ipairs(list) do if t.write and not t.linked and not t.readOnly and self:Matches(e,t) then result[#result+1]=t end end
  return result
end
function A:Frame(id)
  local h=self.pool[id];if h then return h end
  h=CreateFrame('Frame',nil,UIParent,'BackdropTemplate');self.pool[id]=h
  h:SetFrameStrata('HIGH');h:SetFrameLevel(140);h:SetClampedToScreen(true);h:SetMovable(true);h:EnableMouse(true)
  h:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=1})
  h:SetBackdropColor(0,.25,.24,.16);h:SetBackdropBorderColor(.25,1,.85,1)
  h.caption=h:CreateFontString(nil,'OVERLAY');h.caption:SetFont(UI:Font(),12,'OUTLINE');h.caption:SetPoint('BOTTOMLEFT',h,'TOPLEFT',0,3);h.caption:SetWordWrap(false)
  h:RegisterForDrag('LeftButton')
  h:SetScript('OnDragStart',function() A:Start(h) end)
  h:SetScript('OnDragStop',function() if A.drag and A.drag.frame==h then A:StopDrag() end end)
  h:SetScript('OnHide',function() if A.drag and A.drag.frame==h then A:StopDrag(true) end end)
  h:SetScript('OnEnter',function()
    if not h.target then return end
    GameTooltip:SetOwner(h,'ANCHOR_RIGHT');GameTooltip:SetText(h.target.name)
    GameTooltip:AddLine('왼쪽 버튼으로 드래그 · 놓으면 저장\n설정의 위치 잠금 ON으로 종료',1,1,1,true);GameTooltip:Show()
  end)
  h:SetScript('OnLeave',function() if GameTooltip:IsOwned(h) then GameTooltip:Hide() end end)
  h:Hide();return h
end
function A:Start(h)
  if combat() or call(CursorHasItem)==true or K.PositionEditor.active or self.drag or not h.entry or not self:Unlocked(h.entry) then return false end
  local x,y=K.PositionStore:Center(h);if not x or not y then return false end
  local t=h.target
  if t.current and call(t.current)~=true then self:Queue();return false end
  self.drag={frame=h,target=t,entry=h.entry,generation=K.profileGeneration,x=x,y=y,ratio=h.ratio}
  h.positionMoving=true;h:StartMoving();GameTooltip:Hide();return true
end
function A:StopDrag(cancel)
  local d=self.drag;if not d then return end
  self.drag=nil;local h=d.frame;h.positionMoving=nil;h:StopMovingOrSizing()
  local x,y=K.PositionStore:Center(h)
  local valid=not cancel and not combat() and d.generation==K.profileGeneration and self:Unlocked(d.entry,true)
  if d.target.current and call(d.target.current)~=true then valid=false end
  if valid and x and y and d.ratio and d.ratio>0 and (math.abs(x-d.x)>.01 or math.abs(y-d.y)>.01) then
    local t=d.target;t.handle=h
    local ok=pcall(t.write,(x-d.x)/d.ratio,(y-d.y)/d.ratio)
    if ok then K.PositionStore:Committed(t.apply) end
  end
  self:Queue()
end
function A:FinishDrags(key)
  if self.drag and (not key or self.drag.entry.route.module==key or self.drag.target.key==key) then self:StopDrag() end
end
function A:HideAll()
  for _,h in pairs(self.pool) do h:Hide();h.entry=nil;h.target=nil end
  self.active={}
end
function A:Refresh()
  if not K.db or combat() or K.PositionEditor.active or K.profileApplying or K.profileClosingEditors or call(EditModeManagerFrame and EditModeManagerFrame.IsShown,EditModeManagerFrame)==true then
    self:StopDrag(true);self:HideAll();return
  end
  if self.drag then
    if self.drag.generation~=K.profileGeneration or not self:Unlocked(self.drag.entry) then self:StopDrag(true) end
    if self.drag then return end
  end
  local active={}
  for _,e in ipairs(self:Entries()) do
    if self:Unlocked(e) then
      for _,t in ipairs(self:Targets(e)) do
        if not active[t.id] then
          local x,y,w,h,ratio=K.PositionUtils.Rect(t.frame)
          if x and w and h and w>0 and h>0 then
            if t.bounds then x,y,w,h=t.bounds(x,y,w,h) end
            if K.IsPublicNumber(x) and K.IsPublicNumber(y) and K.IsPublicNumber(w) and K.IsPublicNumber(h) and w>0 and h>0 then
              local frame=self:Frame(t.id);frame.entry=e;frame.target=t;frame.ratio=ratio
              frame:ClearAllPoints();frame:SetPoint('CENTER',UIParent,'BOTTOMLEFT',x,y);frame:SetSize(math.max(22,w),math.max(20,h))
              frame.caption:SetText(t.name);frame.caption:SetWidth(0);frame.caption:SetWidth(math.max(160,frame.caption:GetStringWidth()+8));frame.caption:SetHeight(18)
              frame:Show();active[t.id]=frame
            end
          end
        end
      end
    end
  end
  for id,h in pairs(self.pool) do if not active[id] then h:Hide();h.entry=nil;h.target=nil end end
  self.active=active
end
function A:Queue()
  if self.queued then return end
  local ticket={};self.queued=ticket
  C_Timer.After(0,function() if A.queued==ticket then A.queued=nil;A:Refresh() end end)
end
A.events=CreateFrame('Frame')
for _,event in ipairs({'PLAYER_REGEN_DISABLED','PLAYER_REGEN_ENABLED','PLAYER_ENTERING_WORLD','PLAYER_LEAVING_WORLD','PLAYER_TARGET_CHANGED','PLAYER_FOCUS_CHANGED','UNIT_PET','ADDON_LOADED','UI_SCALE_CHANGED','DISPLAY_SIZE_CHANGED','GROUP_ROSTER_UPDATE','PLAYER_ROLES_ASSIGNED'}) do call(A.events.RegisterEvent,A.events,event) end
A.events:SetScript('OnEvent',function(_,event)
  if event=='PLAYER_REGEN_DISABLED' or event=='PLAYER_LEAVING_WORLD' then A.queued=nil;A:StopDrag(true);A.queued=nil;A:HideAll()
  else A:Queue() end
end)
hooksecurefunc(K.PositionEditor,'Enter',function() A:Queue() end)
hooksecurefunc(K.PositionEditor,'Finish',function() A:Queue() end)
