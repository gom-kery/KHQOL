local _,K=...
local UI,T=K.UI,K.UI.Theme
local N=UI.SettingsNavigation
local L={entries={},order={}}
UI.PositionLocks=L
local function copy(p) local q={};for k,v in pairs(p or {}) do q[k]=v end;return q end
function UI:CreatePositionLock(parent,title,get,set,enabled,name,show)
  local route=copy(N:Context(parent));if parent.khqolSection then route.section=parent.khqolSection end
  if route.module=="experienceBar" or route.module=="environmentTimer" or route.module=="pvpAlert" or route.module=="procAlert" then
    route.scope="잠금은 현재 접속 · 좌표는 현재 전체 프로필"
  end
  if UI.SettingsRegistry.screens then route.screen=UI.SettingsRegistry:ScreenFor(route,title).id end
  local id=N:ID(route,title)
  local entry=L.entries[id]
  if entry and entry.source==parent then return entry.control end
  if entry then entry.holder:Hide();N.controls[entry.control]=nil end
  local replacing=entry~=nil
  local header=K.settings and K.settings.moduleHeader
  local holder=CreateFrame("Frame",nil,header or UIParent);holder:SetSize(108,T.RowHeight);holder.khqolPositionLockContainer=true;holder:Hide()
  holder.settingsRoute=route
  local c=UI:CreateCheckbox(holder,title,0,0,get,set,enabled)
  c.availabilityParent=parent;c.headerPositionLock=true;c.text:SetWidth(76)
  entry={id=id,route=route,title=title,name=name or (title~="위치 잠금" and title:gsub(" 위치 잠금$","") or UI.SettingsRegistry.modules[route.module] and UI.SettingsRegistry.modules[route.module].title or "위치"),control=c,holder=holder,source=parent,show=show,get=get,set=set,enabled=enabled}
  L.entries[id]=entry;if not replacing then L.order[#L.order+1]=id end
  entry.caption=UI:CreateLabel(holder,"",0,-5);entry.caption:SetJustifyH("RIGHT")
  local refresh=c.Refresh;c.Refresh=function() refresh();if K.PositionAnchors then K.PositionAnchors:Queue() end end
  UI:AttachTooltip(c,title,"잠금 OFF에서 현재 위치에 이동 테두리가 표시됩니다. 설정창을 닫고 왼쪽 버튼으로 드래그한 뒤 잠그세요.")
  return c
end
function L:Rows(route)
  local result={}
  for _,id in ipairs(self.order) do
    local entry=self.entries[id];local p=entry.route;local matches=p.module==route.module
    if matches and p.screen and route.screen and p.screen~=route.screen then matches=false end
    if matches and p.module=="range" then
      local distance=K.modules.range.db.displayMode=="distance"
      matches=distance==(entry.title=="거리 위치 잠금")
    elseif matches and p.module=="experienceBar" then matches=K.modules.experienceBar.db.mode=="horizontal" end
    for _,field in ipairs({"tab","unit","part","category","castUnit"}) do if p[field] and p[field]~=route[field] then matches=false end end
    if matches and (not entry.show or entry.show()) then result[#result+1]=entry end
  end
  return result
end
function L:Attach(s,header)
  s.positionLockHeader=CreateFrame("Frame",nil,s);s.positionLockHeader:SetSize(header:GetWidth(),0);s.positionLockHeader:Hide()
  function s:RefreshPositionLocks() self:LayoutModuleHeader() end
  function s:LayoutModuleHeader() L:Layout(self,header) end
end
function L:Layout(s,header)
  local rows=self:Rows(s.currentRoute or {});local active={}
  for _,entry in ipairs(rows) do active[entry]=true end
  for _,id in ipairs(self.order) do local e=self.entries[id];if not active[e] then e.holder:Hide() end end
  local width=header:GetWidth();local toggle=header.toggle;local description=header.description
  local lockHeader=s.positionLockHeader;lockHeader:SetWidth(width)
  local step=math.max(T.RowHeight,T.CheckboxSize)+T.RowGap
  local namesWidth=0
  if #rows>1 then
    for _,entry in ipairs(rows) do entry.caption:SetText(UI:DisplayRouteText(entry.route,entry.name));namesWidth=math.max(namesWidth,entry.caption:GetStringWidth()+12) end
  end
  namesWidth=math.min(namesWidth,math.max(80,width-132))
  local actionWidth=header.actionWidth or 108
  local actions=toggle:IsShown() and actionWidth or 0
  local custom=s.currentModuleMeta and s.currentModuleMeta.toggle
  local stacked=not custom and width<600 and description:IsShown() and description:GetText()~="" and actions>0
  description:SetWidth(math.max(80,width-(stacked and 0 or actions>0 and actions+16 or 0)))
  local textHeight=description:IsShown() and description:GetStringHeight() or 0
  local top=stacked and textHeight+18 or 0
  toggle:ClearAllPoints();toggle:SetPoint("TOPLEFT",width-actionWidth,-top)
  local y=0
  for _,entry in ipairs(rows) do
    local holder,c=entry.holder,entry.control
    if holder:GetParent()~=lockHeader then holder:SetParent(lockHeader) end
    holder:ClearAllPoints();holder:SetPoint("TOPLEFT",width-actionWidth,-y);holder:SetWidth(actionWidth);holder:Show()
    if c:GetParent()~=holder then c:SetParent(holder) end
    c:ClearAllPoints();c:SetPoint("TOPLEFT",0,0);c:Refresh()
    c.text:SetText("위치 잠금");c.text:SetWidth(76)
    for _,caption in ipairs(c.uiCaptions or {}) do if caption.region==c.text then caption.text="위치 잠금" end end
    entry.caption:SetShown(#rows>1);entry.caption:SetWidth(math.max(1,namesWidth-12))
    entry.caption:ClearAllPoints();entry.caption:SetPoint("TOPRIGHT",holder,"TOPLEFT",-12,-5)
    local height=math.max(T.RowHeight,#rows>1 and entry.caption:GetStringHeight()+10 or 0)
    holder:SetHeight(height);y=y+height+T.RowGap
  end
  header:SetHeight(math.max(42,top+(toggle:IsShown() and step or 0)+8,textHeight+20))
  lockHeader:SetHeight(#rows>0 and y+4 or 0);lockHeader:SetShown(#rows>0)
  s.positionLockRows=rows
end
