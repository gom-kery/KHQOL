local _, KHQOL = ...
local M = { records = {}, byFrame = {} }
KHQOL.modules.frameMover = M
-- Verified Camelot source: Gethe/wow-ui-source @ 15666a6e67938a1ab5caf041406464251db111ca.
-- Talents and Spellbook are pages of ONE PlayerSpellsFrame, not separate windows.
M.registry = {
  Map = { name="WorldMapFrame", addon="Blizzard_WorldMap" },
  Character = { name="CharacterFrame", addon="Blizzard_UIPanels_Game" },
  Talents = { name="PlayerSpellsFrame", addon="Blizzard_PlayerSpells" },
  Spellbook = { name="PlayerSpellsFrame", addon="Blizzard_PlayerSpells" },
  Macro = { name="MacroFrame", addon="Blizzard_MacroUI" },
}
local function combat() return InCombatLockdown and InCombatLockdown() end
local function anchors(f)
  local points = {}
  for i=1,f:GetNumPoints() do points[i]={f:GetPoint(i)} end
  return points
end
local function keyFor(r)
  if r.name ~= "PlayerSpellsFrame" then return r.key end
  local f=r.frame
  local tab=f.GetTab and f:GetTab()
  if f.spellBookTabID and tab==f.spellBookTabID then return "Spellbook" end
  if f.talentTabID and tab==f.talentTabID then return "Talents" end
  -- Specialization is deliberately outside this five-target whitelist.
end
function M:GetDB()
  if type(KHQOL.db.frameMover)~="table" then KHQOL.db.frameMover={} end
  local db=KHQOL.db.frameMover
  if db.enabled==nil then db.enabled=false end
  if db.modifier~="SHIFT" and db.modifier~="CTRL" and db.modifier~="ALT" then db.modifier="SHIFT" end
  if type(db.positions)~="table" then db.positions={} end
  return db
end
function M:ModifierDown()
  local key=self:GetDB().modifier
  if key=="CTRL" then return IsControlKeyDown() end
  if key=="ALT" then return IsAltKeyDown() end
  return IsShiftKeyDown()
end
function M:Backup(r)
  if r.original then return true end
  local points=anchors(r.frame)
  if #points==0 then return false end
  r.original=points
  r.movable=r.frame:IsMovable()
  r.clamped=r.frame:IsClampedToScreen()
  r.userPlaced=r.frame:IsUserPlaced()
  return true
end
function M:Restore(r)
  if not r.original or not r.controlled then return end
  local f=r.frame
  r.applying=true
  f:ClearAllPoints()
  for _,p in ipairs(r.original) do f:SetPoint(p[1],p[2],p[3],p[4],p[5]) end
  -- SetUserPlaced requires a movable or resizable frame. Saved-position
  -- restoration after reload may reach here without any drag in this session.
  f:SetMovable(true)
  f:SetUserPlaced(r.userPlaced)
  f:SetMovable(r.movable); f:SetClampedToScreen(r.clamped)
  r.applying=nil; r.controlled=nil; r.appliedKey=nil
end
local function validPosition(p)
  return type(p)=="table" and p.point=="CENTER" and p.relativePoint=="BOTTOMLEFT"
    and type(p.x)=="number" and type(p.y)=="number" and p.x==p.x and p.y==p.y
    and math.abs(p.x)<100000 and math.abs(p.y)<100000
end
local function mapLocked(f)
  return combat() and (not f.IsProtected or f:IsProtected())
end
local function rectInParent(f)
  if not f.GetRect then return end
  local left,bottom,width,height=f:GetRect()
  if not left or not bottom or not width or not height then return end
  local scale=f:GetEffectiveScale()/UIParent:GetEffectiveScale()
  return left*scale,bottom*scale,(left+width)*scale,(bottom+height)*scale
end
function M:ClampMap(r)
  local f=r.frame
  if r.name~="WorldMapFrame" or not f:IsShown() or mapLocked(f) then return end
  local left,bottom,right,top=rectInParent(f)
  local sl,sb,sr,st=rectInParent(UIParent)
  if not left or not sl then return end
  local quest=f.QuestLog
  if quest and quest:IsShown() then
    local ql,qb,qr,qt=rectInParent(quest)
    if ql then left=math.min(left,ql);bottom=math.min(bottom,qb);right=math.max(right,qr);top=math.max(top,qt) end
  end
  -- The root already includes the quest width; union also covers client layouts
  -- with a side panel extending outside it. All values use UIParent units.
  local function correction(lo,hi,screenLo,screenHi)
    if hi-lo>screenHi-screenLo then return screenLo-lo end
    if lo<screenLo then return screenLo-lo end
    if hi>screenHi then return screenHi-hi end
    return 0
  end
  local dx=correction(left,right,sl,sr)
  local dy=correction(bottom,top,sb,st)
  if math.abs(dx)<.01 and math.abs(dy)<.01 then return end
  local x,y=f:GetCenter();if not x or not y then return end
  local scale=f:GetEffectiveScale()/UIParent:GetEffectiveScale()
  f:ClearAllPoints();f:SetPoint("CENTER",UIParent,"BOTTOMLEFT",x*scale+dx-sl,y*scale+dy-sb)
  -- Keep the user's saved CENTER position; clamp it again for each final size.
end
function M:Apply(r)
  if r.applying or r.moving then return end
  if combat() and (r.name~="WorldMapFrame" or mapLocked(r.frame) or not self:GetDB().enabled) then self.pending=true; return end
  local db=self:GetDB()
  local key=keyFor(r)
  if not db.enabled or not key then
    r.handle:Hide(); self:Restore(r); return
  end
  if not self:Backup(r) then return end
  local p=db.positions[key]
  if r.appliedKey and r.appliedKey~=key then self:Restore(r) end
  r.handle:Show()
  if validPosition(p) then
    r.controlled=true; r.appliedKey=key; r.applying=true
    r.frame:ClearAllPoints()
    r.frame:SetPoint(p.point,UIParent,p.relativePoint,p.x,p.y)
    self:ClampMap(r)
    r.applying=nil
  end
end
function M:Stop(r, save)
  if not r.moving then return end
  if combat() then r.stopPending=true; self.pending=true; return end
  local key=r.dragKey
  r.applying=true
  r.frame:StopMovingOrSizing()
  -- Do not let WoW persist this addon-owned position in its layout cache.
  r.frame:SetUserPlaced(r.userPlaced)
  r.moving=nil; r.dragKey=nil; r.stopPending=nil
  local db=self:GetDB()
  if save and db.enabled and key then
    local x,y=r.frame:GetCenter()
    local scale=r.frame:GetEffectiveScale()/UIParent:GetEffectiveScale()
    if x and y then
      local p={point="CENTER",relativePoint="BOTTOMLEFT",x=x*scale,y=y*scale}
      if validPosition(p) then
        db.positions[key]=p; r.appliedKey=key
        r.frame:ClearAllPoints(); r.frame:SetPoint(p.point,UIParent,p.relativePoint,p.x,p.y)
      end
    end
  end
  r.applying=nil
  self:Apply(r)
end
function M:Register(key,entry)
  local f=_G[entry.name]
  if not f or self.byFrame[f] then return end
  if combat() then self.pending=true; return end
  -- Reject a mismatched client hierarchy instead of moving an internal panel.
  if type(f.GetParent)~="function" or f:GetParent()~=UIParent then return end
  local r={frame=f,key=key,name=entry.name}
  self.byFrame[f]=r; self.records[#self.records+1]=r
  -- A narrow, invisible title-bar handle leaves inventory/spell/macro drag scripts intact.
  local h=CreateFrame("Frame",nil,f)
  r.handle=h
  h:SetPoint("TOPLEFT",f,"TOPLEFT",65,-4)
  h:SetPoint("TOPRIGHT",f,"TOPRIGHT",-75,-4)
  h:SetHeight(24); h:SetFrameLevel(f:GetFrameLevel()+5)
  h:EnableMouse(true); h:RegisterForDrag("LeftButton"); h:Hide()
  h:SetScript("OnDragStart",function()
    if combat() or not M:GetDB().enabled or not M:ModifierDown() then return end
    local current=keyFor(r)
    if not current or not M:Backup(r) then return end
    r.controlled=true; r.moving=true; r.dragKey=current; r.appliedKey=current
    f:SetMovable(true); f:SetClampedToScreen(true); f:StartMoving()
  end)
  h:SetScript("OnDragStop",function() M:Stop(r,true) end)
  h:SetScript("OnHide",function() M:Stop(r,true) end)
  f:HookScript("OnShow",function() M:Apply(r) end)
  f:HookScript("OnHide",function() M:Stop(r,true) end)
  -- Only whitelist frames; never hook UIParent or change UIPanel attributes.
  -- Blizzard's panel manager can re-anchor after OnShow or on maximize/tab changes.
  hooksecurefunc(f,"SetPoint",function()
    if not r.applying and not r.moving and KHQOL.db and M:GetDB().enabled then M:Apply(r) end
  end)
  if entry.name=="PlayerSpellsFrame" and type(f.SetTab)=="function" then
    hooksecurefunc(f,"SetTab",function() M:Apply(r) end)
  end
  if entry.name=="WorldMapFrame" then
    f:HookScript("OnSizeChanged",function() M:Apply(r) end)
    -- Post-hooks run after Blizzard has sized the quest panel and re-anchored
    -- the UIPanel. No timers, size overrides or Blizzard script replacement.
    for _,method in ipairs({"SetQuestLogPanelShown","SetDisplayState","SynchronizeDisplayState"}) do
      if type(f[method])=="function" then hooksecurefunc(f,method,function() M:Apply(r) end) end
    end
  end
end
function M:Refresh()
  if not KHQOL.db then return end
  if combat() then self.pending=true; return end
  self.pending=nil
  -- OFF never creates handles or changes unregistered Blizzard frames.
  if self:GetDB().enabled then
    for key,entry in pairs(self.registry) do self:Register(key,entry) end
  end
  for _,r in ipairs(self.records) do
    if r.stopPending then self:Stop(r,false) end
    self:Apply(r)
  end
end
function M:ResetPositions()
  self:GetDB().positions={}
  if combat() then self.resetPending=true; self.pending=true; return end
  self.resetPending=nil
  for _,r in ipairs(self.records) do self:Stop(r,false); self:Restore(r) end
  self:Refresh()
end
function M:SetEnabled(on)
  self:GetDB().enabled=on and true or false
  if not on then self:ResetPositions() end
  self:Refresh()
end
function M:Initialize()
  if self.initialized then self:Refresh(); return end
  self.initialized=true; self:GetDB(); self:Refresh()
  local events=CreateFrame("Frame")
  for _,event in ipairs({"ADDON_LOADED","PLAYER_LOGIN","PLAYER_ENTERING_WORLD","PLAYER_REGEN_ENABLED","UI_SCALE_CHANGED","DISPLAY_SIZE_CHANGED"}) do events:RegisterEvent(event) end
  events:SetScript("OnEvent",function(_,event,addon)
    if event=="ADDON_LOADED" then
      local relevant=false
      for _,entry in pairs(M.registry) do if addon==entry.addon then relevant=true; break end end
      if not relevant then return end
    end
    if M.resetPending and not combat() then M:ResetPositions() else M:Refresh() end
  end)
  self.events=events
end
function M:BuildSettings(content,y)
  local b=KHQOL.UI:CreateBuilder(content,y)
  b:Section("Blizzard 기본 프레임 이동")
  b:Description("Blizzard 기본 창의 제목 표시줄을 지정한 보조키와 함께 드래그하여 이동합니다. 지도·캐릭터창·특성·마법책·매크로창을 지원합니다.")
  b:Checkbox("Blizzard 기본 프레임 이동",function() return M:GetDB().enabled end,function(on) M:SetEnabled(on) end)
  b:Dropdown("이동 키 (+ 드래그)",{{value="SHIFT",text="Shift"},{value="CTRL",text="Ctrl"},{value="ALT",text="Alt"}},
    function() return M:GetDB().modifier end,function(v) M:GetDB().modifier=v end)
  b:Button("모든 프레임 위치 초기화",function() M:ResetPositions() end)
  b:Description("OFF 시 저장 위치를 삭제하고 기본 위치로 복원합니다. 전투 중 이동은 차단되며 초기화·복원은 전투 종료 후 적용합니다.")
  return b.y
end
