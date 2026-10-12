local _, KHQOL = ...
local UI=KHQOL.UI
local E={pool={},active=false}
KHQOL.PositionEditor=E
local unpack=unpack
local function combat()
  return (InCombatLockdown and InCombatLockdown()) or (UnitAffectingCombat and UnitAffectingCombat("player"))
end
local function safe(frame)
  return KHQOL.PositionStore:Safe(frame)
end
local function center(frame)
  local x,y=frame:GetCenter(); local scale=frame:GetEffectiveScale()/UIParent:GetEffectiveScale()
  return (x or 0)*scale,(y or 0)*scale
end
function E:Message(message)
  if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff"..UI.Theme.AccentHex.."KHQOL:|r "..message) end
end
function E:CreateToolbar()
  if self.toolbar then return end
  local f=CreateFrame("Frame","KHQOLPositionEditorToolbar",UIParent,"BackdropTemplate")
  f:SetSize(520,192); f:SetPoint("TOP",0,-32); f:SetFrameStrata("FULLSCREEN_DIALOG"); f:SetFrameLevel(200)
  f:SetMovable(true); f:SetClampedToScreen(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart",f.StartMoving); f:SetScript("OnDragStop",f.StopMovingOrSizing)
  UI:Surface(f,1)
  UI:CreateLabel(f,"KHQOL · 위치 편집",14,-12,16)
  f.info=UI:CreateDescription(f,"테두리를 드래그하세요. ESC는 취소합니다.",14,-38); f.info:SetWidth(492)
  UI:CreateButton(f,"완료 / 잠금",14,-124,146,function() E:Finish(true) end)
  UI:CreateButton(f,"취소",174,-124,100,function() E:Finish(false) end)
  f.selection=UI:CreateDescription(f,"",14,-62);f.selection:SetWidth(492);f.selection:SetHeight(52)
  self.resetButton=UI:CreateButton(f,"선택 위치 초기화",290,-124,204,function() E:ResetSelection() end,function() return E.selected and not E.selected.target.linked end)
  self.settingsButton=UI:CreateButton(f,"완료 후 크기·모양 설정",14,-158,330,function()
    local key=E.selected and E.selected.target.key
    if E:Finish(true) and key then KHQOL:ShowSettings(key) end
  end,function() return E.selected and E.selected.target.key and (not E.selected.target.key or KHQOL.UI.SettingsRegistry.modules[E.selected.target.key]) end)
  f:EnableKeyboard(true); f:SetPropagateKeyboardInput(true)
  f:SetScript("OnKeyDown",function(self,key)
    self:SetPropagateKeyboardInput(key~="ESCAPE")
    if key=="ESCAPE" then E:Finish(false) end
  end)
  f:SetScript("OnHide",function() if E.active then E:Finish(false) end end)
  f:RegisterEvent("PLAYER_REGEN_DISABLED"); f:RegisterEvent("PLAYER_LOGOUT")
  f:RegisterEvent("PLAYER_ENTERING_WORLD");f:RegisterEvent("PLAYER_LEAVING_WORLD")
  f:RegisterEvent("UPDATE_SHAPESHIFT_FORM");f:RegisterEvent("UI_SCALE_CHANGED");f:RegisterEvent("DISPLAY_SIZE_CHANGED")
  f:SetScript("OnEvent",function(_,event)
    if E.active then E:Finish(false,event=="PLAYER_REGEN_DISABLED") end
  end)
  if UISpecialFrames then table.insert(UISpecialFrames,"KHQOLPositionEditorToolbar") end
  f:Hide(); self.toolbar=f
end
function E:SetHandleHighlight(h,on)
  h.focus:SetShown(on and true or false)
  h.focus:SetFrameLevel(h:GetFrameLevel()+2)
  h.caption:SetTextColor(unpack(on and UI.Theme.FocusAccent or UI.Theme.Accent))
  h.caption:SetFont(UI:Font(),on and 14 or 12,on and "OUTLINE" or "")
  h.caption:SetWidth(math.max(160,h.caption:GetStringWidth()+8))
end
function E:GetHandle(id)
  local h=self.pool[id]; if h then return h end
  h=CreateFrame("Frame",nil,UIParent,"BackdropTemplate")
  h:SetFrameStrata("FULLSCREEN_DIALOG"); h:SetFrameLevel(100)
  h:SetMovable(true); h:SetClampedToScreen(true); h:EnableMouse(false); h:RegisterForDrag("LeftButton")
  UI:Surface(h,.35); h:SetBackdropBorderColor(unpack(UI.Theme.Accent))
  h.caption=UI:CreateLabel(h,"",4,-3,12); h.caption:ClearAllPoints(); h.caption:SetPoint("BOTTOMLEFT",h,"TOPLEFT",0,3); h.caption:SetTextColor(unpack(UI.Theme.Accent))
  h.focus=CreateFrame("Frame",nil,h,"BackdropTemplate"); h.focus:SetAllPoints(h); h.focus:EnableMouse(false)
  h.focus:SetBackdrop({edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=2})
  h.focus:SetBackdropBorderColor(unpack(UI.Theme.FocusAccent)); h.focus:Hide()
  h.sample=UI:CreateDescription(h,"",4,-24); h.sample:SetJustifyH("CENTER")
  h.mirrors={}
  h.mirrorPool={}
  h.art={}
  h:SetScript("OnDragStart",function(self)
    if not E.active or combat() or self.target.linked then return end
    for _,other in ipairs(E.handles) do other:SetFrameLevel(other==self and 170 or 100) end
    E:Select(self); E.dragging=self; self:StartMoving()
  end)
  h:SetScript("OnMouseDown",function(self) if E.active then E:Select(self) end end)
  h:SetScript("OnDragStop",function(self) E:StopDrag(self) end)
  h:SetScript("OnEnter",function(self)
    if not E.active or not self.target then return end
    E:SetHandleHighlight(self,true)
    GameTooltip:SetOwner(self,"ANCHOR_TOP"); GameTooltip:SetText(self.target.name,unpack(UI.Theme.Accent))
    GameTooltip:AddLine(self.target.linked and "부모 요소와 함께 이동합니다. 연결 관계는 유지됩니다." or "드래그로 이동 · 완료 시 저장 및 잠금",.85,.88,.9,true); GameTooltip:Show()
  end)
  h:SetScript("OnLeave",function(self) E:SetHandleHighlight(self,E.selected==self); GameTooltip:Hide() end)
  h:SetScript("OnHide",function(self) E:SetHandleHighlight(self,false) end)
  h:Hide(); self.pool[id]=h; return h
end
function E:StopDrag(h)
  if not h or not h.target then return end
  h:StopMovingOrSizing(); if self.dragging==h then self.dragging=nil end
  local x,y=center(h); local parent=h.parentHandle
  if h.target.minimap then
    local mx,my=center(Minimap); local angle=math.atan2(y-my,x-mx)
    local radius=108*Minimap:GetEffectiveScale()/UIParent:GetEffectiveScale()
    x,y=mx+math.cos(angle)*radius,my+math.sin(angle)*radius
  end
  h:ClearAllPoints()
  if parent then local px,py=center(parent); h:SetPoint("CENTER",parent,"CENTER",x-px,y-py)
  else h:SetPoint("CENTER",UIParent,"BOTTOMLEFT",x,y) end
  if self.active then self:Select(h) end
end
function E:Select(handle)
  self.selected=handle
  for _,h in ipairs(self.handles or {}) do self:SetHandleHighlight(h,h==handle) end
  if not handle or not handle.target then self.toolbar.selection:SetText("편집 가능한 요소가 없습니다.");return end
  local x,y=center(handle);local cx,cy=UIParent:GetCenter();local t=handle.target
  local parent=handle.parentHandle and handle.parentHandle.target.name
  self.toolbar.selection:SetText(string.format("%s\n%s · 화면 중심 X %.0f / Y %.0f · 표시 %.0f × %.0f px",
    t.name,parent and ((t.linked and "연결: " or "부모: ")..parent) or "독립 위치",x-cx,y-cy,handle:GetWidth(),handle:GetHeight()))
  self.resetButton:Refresh();self.settingsButton:Refresh()
end
function E:ResetSelection()
  local h=self.selected;if not h or h.target.linked then return end
  self:StopDrag(self.dragging)
  local t=h.target;local x,y
  if t.minimap then
    local mx,my=center(Minimap);local radius=108*Minimap:GetEffectiveScale()/UIParent:GetEffectiveScale()
    x,y=mx+math.cos(math.rad(t.resetAngle))*radius,my+math.sin(math.rad(t.resetAngle))*radius
  elseif t.resetPoint then
    local p=t.resetPoint;local preview=self:Virtual("reset",p,t.frame:GetWidth(),t.frame:GetHeight())
    preview:SetScale(t.scale)
    if h.parentHandle then
      preview:ClearAllPoints();preview:SetPoint("CENTER",h.parentHandle,"CENTER",p.x/t.scale,p.y/t.scale)
    elseif t.resetPhysical then
      preview:ClearAllPoints();preview:SetPoint(p.point,UIParent,p.relativePoint,p.x/t.scale,p.y/t.scale)
    end
    x,y=center(preview)
    -- Handles may enclose a text/art union offset from the actual source center.
    local fx,fy=center(t.frame);x=x+h.originX-fx;y=y+h.originY-fy
  else self:Message("이 연결 요소의 위치는 부모 설정에서 초기화하세요.");return end
  h:ClearAllPoints()
  if h.parentHandle then
    local px,py=center(h.parentHandle);h:SetPoint("CENTER",h.parentHandle,"CENTER",x-px,y-py)
    h.resetRelativeX,h.resetRelativeY=x-px,y-py
  else h:SetPoint("CENTER",UIParent,"BOTTOMLEFT",x,y) end
  h.resetting=true;h.resetX,h.resetY=x,y;self:Select(h)
end
function E:IsCurrent()
  if self.generation~=KHQOL.profileGeneration or self.labUnlocked~=KHQOL.LabLock:IsUnlocked() then return false end
  for key,enabled in pairs(self.enabled or {}) do if KHQOL:GetEnabled(key)~=enabled then return false end end
  return true
end
-- A read-only rendering copy: no live alert/test functions, scripts or sounds.
-- The original frame keeps its anchors, visibility and state throughout editing.
function E:Mirror(h,frame)
  local used=0; local hx,hy=h.originX,h.originY
  local function visit(node,depth)
    if depth>5 or used>=100 or not safe(node) then return end
    if node~=frame and self.sources[node] then return end
    if node.GetRegions then
      for _,region in ipairs({node:GetRegions()}) do
        local kind=region:GetObjectType()
        if (kind=="Texture" or kind=="FontString") and region:IsShown() and not self.sources[region]
          and (kind~="FontString" or (region:GetText() and region:GetText()~="")) then
          local x,y=center(region); local w,ht=region:GetSize()
          local ratio=region:GetEffectiveScale()/UIParent:GetEffectiveScale()
          if w and ht and w>0 and ht>0 and math.abs(x-hx)<h:GetWidth() and math.abs(y-hy)<h:GetHeight() then
            used=used+1; local copy=h.mirrors[used]
            if not copy or copy:GetObjectType()~=kind then
              if copy then copy:Hide() end
              h.mirrorPool[used]=h.mirrorPool[used] or {}
              copy=h.mirrorPool[used][kind]
              if not copy then
                copy=kind=="Texture" and h:CreateTexture(nil,"ARTWORK") or h:CreateFontString(nil,"ARTWORK")
                h.mirrorPool[used][kind]=copy
              end
              h.mirrors[used]=copy
            end
            copy:ClearAllPoints(); copy:SetPoint("CENTER",h,"CENTER",x-hx,y-hy); copy:SetSize(w*ratio,ht*ratio)
            if kind=="Texture" then
              if region:GetTexture() then copy:SetTexture(region:GetTexture()) else copy:SetColorTexture(region:GetVertexColor()) end
              if region.GetTexCoord then copy:SetTexCoord(region:GetTexCoord()) end
              if region.GetVertexColor then copy:SetVertexColor(region:GetVertexColor()) end
            else
              local font,size,flags=region:GetFont(); copy:SetFont(font or UI:Font(),(size or 13)*ratio,flags or "")
              copy:SetText(region:GetText()); copy:SetTextColor(region:GetTextColor()); copy:SetJustifyH(region:GetJustifyH())
            end
            copy:SetAlpha(region:GetAlpha()); copy:Show()
          end
        end
      end
    end
    if node.GetChildren then for _,child in ipairs({node:GetChildren()}) do if child:IsShown() then visit(child,depth+1) end end end
  end
  if frame:IsVisible() then visit(frame,0) end
  for i=used+1,#h.mirrors do h.mirrors[i]:Hide() end
  for _,texture in ipairs(h.art) do texture:Hide() end
  if used==0 then
    for index,spec in ipairs(h.target.art or {}) do
      local texture=h.art[index] or h:CreateTexture(nil,"ARTWORK"); h.art[index]=texture
      texture:ClearAllPoints(); texture:SetPoint("CENTER",h,"CENTER",spec.x or 0,spec.y or 0)
      texture:SetSize(spec.width,spec.height); texture:SetTexture(spec.texture)
      texture:SetTexCoord(0,1,0,spec.crop or 1); texture:SetAlpha(1); texture:Show()
    end
  end
  h.sample:SetShown(used==0); h.sample:SetText(h.target.sample or "편집용 미리보기")
  h.sample:SetFont(UI:Font(),h.target.sampleSize or 12,"")
  h.sample:ClearAllPoints(); h.sample:SetPoint("CENTER",h,"CENTER",0,h.target.sampleY or 0)
end
function E:Enter(focus)
  if self.active then return true end
  if combat() then self:Message("전투 중에는 위치를 편집할 수 없습니다."); return false end
  if KHQOL.AlertLayout then KHQOL.AlertLayout:Suspend(true) end
  self:CreateToolbar(); UI:CloseDropdown(); GameTooltip:Hide()
  self.returnSettings=KHQOL.settings and KHQOL.settings:IsShown()
  self.targets=KHQOL:BuildPositionTargets(); self.sources={}; self.suppressed={}; self.handles={}; self.byID={}
  self.generation=KHQOL.profileGeneration
  self.labUnlocked=KHQOL.LabLock:IsUnlocked();self.enabled={}
  for key in pairs(KHQOL.db.enabled) do self.enabled[key]=KHQOL:GetEnabled(key) end
  for _,target in ipairs(self.targets) do if safe(target.frame) then self.sources[target.frame]=true end end
  for _,target in ipairs(self.targets) do
    if safe(target.frame) then
      local h=self:GetHandle(target.id); h.resetting=nil; h.target=target; target.handle=h
      local ratio=target.frame:GetEffectiveScale()/UIParent:GetEffectiveScale()
      local x,y=center(target.frame); local w,ht=target.frame:GetSize()
      if target.bounds then x,y,w,ht=target.bounds(x,y,w*ratio,ht*ratio) else w,ht=w*ratio,ht*ratio end
      h:SetSize(math.max(16,w),math.max(16,ht)); h:ClearAllPoints(); h:SetPoint("CENTER",UIParent,"BOTTOMLEFT",x,y)
      h.originX,h.originY=x,y; target.scale=ratio
      h.caption:SetText(target.name); self:SetHandleHighlight(h,false)
      h.sample:SetWidth(math.max(8,w-8)); h:SetFrameLevel(100); h:EnableMouse(true); h:Show()
      self.handles[#self.handles+1]=h; self.byID[target.id]=h
    end
  end
  for _,h in ipairs(self.handles) do
    local parent=self.byID[h.target.parentID]
    h.parentHandle=parent
    if parent then
      h.relativeX,h.relativeY=h.originX-parent.originX,h.originY-parent.originY
      h:ClearAllPoints(); h:SetPoint("CENTER",parent,"CENTER",h.relativeX,h.relativeY)
    end
    local ok=pcall(self.Mirror,self,h,h.target.mirror or h.target.frame)
    if not ok then
      for _,region in ipairs(h.mirrors) do region:Hide() end
      for _,region in ipairs(h.art) do region:Hide() end
      h.sample:SetText(h.target.sample or "편집용 미리보기"); h.sample:Show()
    end
  end
  -- Suppress original mouse input too: transparent old HUDs must not catch clicks.
  local function suppress(frame)
    if not safe(frame) or self.suppressed[frame] then return end
    self.suppressed[frame]={alpha=frame:GetAlpha(),mouse=frame.IsMouseEnabled and frame:IsMouseEnabled() or false}
    frame:SetAlpha(0); if frame.EnableMouse then frame:EnableMouse(false) end
    if frame.GetChildren then for _,child in ipairs({frame:GetChildren()}) do suppress(child) end end
  end
  for _,h in ipairs(self.handles) do
    suppress(h.target.frame)
    for _,frame in ipairs(h.target.suppress or {}) do suppress(frame) end
  end
  self.active=true
  if KHQOL.settings then KHQOL.settings:Hide() end
  self.toolbar.info:SetText("테두리를 드래그하세요. ESC는 취소합니다. ("..#self.handles.."개)")
  self.toolbar:SetScale(math.min(1,(UIParent:GetWidth()-24)/520)); UI:Refresh(self.toolbar); self.toolbar:Show()
  local selected
  for _,h in ipairs(self.handles) do if h.target.id==focus or h.target.key==focus then selected=selected or h end end
  self:Select(selected or self.handles[1])
  -- Exists only during editing; live HUD animations may write their own alpha.
  self.toolbar:SetScript("OnUpdate",function()
    if combat() or not self:IsCurrent() then self:Finish(false,combat()); return end
    for frame in pairs(self.suppressed) do if safe(frame) then frame:SetAlpha(0); if frame.EnableMouse then frame:EnableMouse(false) end end end
  end)
  return true
end
function E:Finish(save,combatExit)
  if not self.active then return end
  if save and (combat() or not self:IsCurrent()) then save=false end
  self:StopDrag(self.dragging)
  UI:CloseDropdown()
  self.active=false; self.toolbar:SetScript("OnUpdate",nil)
  -- Restore input/alpha first; applying module locks below decides final input.
  for frame,state in pairs(self.suppressed) do
    if safe(frame) then frame:SetAlpha(state.alpha); if frame.EnableMouse then frame:EnableMouse(state.mouse) end end
  end
  if save then
    for _,h in ipairs(self.handles) do
      local t=h.target; local x,y=center(h); local dx,dy=x-(h.resetting and h.resetX or h.originX),y-(h.resetting and h.resetY or h.originY)
      if h.resetting and t.resetWrite then t.resetWrite() end
      if h.parentHandle then
        local px,py=center(h.parentHandle)
        dx,dy=x-px-(h.resetting and h.resetRelativeX or h.relativeX),y-py-(h.resetting and h.resetRelativeY or h.relativeY)
      end
      if t.write and (t.alwaysSave or math.abs(dx)>.01 or math.abs(dy)>.01) then t.write(dx/t.scale,dy/t.scale) end
      if t.lock then t.lock() end
    end
    for _,h in ipairs(self.handles) do if h.target.apply then h.target.apply() end end
    if KHQOL.SaveCurrentProfile then KHQOL:SaveCurrentProfile() end
  end
  for _,h in ipairs(self.handles) do h:StopMovingOrSizing(); h:EnableMouse(false); h:Hide(); h.target=nil; h.parentHandle=nil end
  self.selected=nil;self.enabled=nil;self.targets=nil; self.suppressed=nil; self.sources=nil; self.handles=nil; self.byID=nil
  self.toolbar:StopMovingOrSizing(); self.toolbar:Hide(); GameTooltip:Hide()
  if combatExit then self:Message("전투가 시작되어 위치 편집을 취소했습니다.")
  elseif self.returnSettings and KHQOL.settings then
    KHQOL.settings:Show()
    if KHQOL.settings.activeContent then UI:Refresh(KHQOL.settings.activeContent); KHQOL.settings:UpdateContentHeight() end
  end
  self.returnSettings=nil
  if KHQOL.AlertLayout then KHQOL.AlertLayout:Suspend(false) end
  return save and true or false
end
