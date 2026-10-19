local _, KHQOL = ...
local UI=KHQOL.UI
local N=UI.SettingsNavigation
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
  local x,y=KHQOL.PositionStore:Center(frame)
  return x,y
end
function E:Message(message)
  if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff"..UI.Theme.AccentHex.."KHQOL:|r "..message) end
end
function E:CreateToolbar()
  if self.toolbar then return end
  local f=CreateFrame("Frame","KHQOLPositionEditorToolbar",UIParent,"BackdropTemplate")
  f:SetSize(650,458); f:SetPoint("TOP",0,-32); f:SetFrameStrata("FULLSCREEN_DIALOG"); f:SetFrameLevel(200)
  f:SetMovable(true); f:SetClampedToScreen(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart",f.StartMoving); f:SetScript("OnDragStop",f.StopMovingOrSizing)
  UI:Surface(f,1)
  f.title=UI:CreateLabel(f,"KHQOL · 위치 편집",14,-12,UI.Theme.PageTitleSize);f.title:SetWidth(622);f.title:SetJustifyH("CENTER")
  f.info=UI:CreateDescription(f,"테두리를 드래그하세요. ESC는 취소합니다.",14,-38); f.info:SetWidth(622);f.info:SetHeight(28);f.info:SetJustifyH("CENTER")
  self.doneButton=UI:CreateButton(f,"완료 / 잠금",84,-78,146,function() E:Finish(true) end)
  self.cancelButton=UI:CreateButton(f,"취소",246,-78,100,function() E:Finish(false) end)
  self.resetButton=UI:CreateButton(f,"선택 위치 초기화",362,-78,204,function() E:ResetSelection() end,function() return E.selected and not E.selected.target.linked end)
  self.doneButton:SetWidth(146);self.cancelButton:SetWidth(100);self.resetButton:SetWidth(204)
  for _,button in ipairs({self.doneButton,self.cancelButton,self.resetButton}) do button:GetFontString():SetJustifyH("CENTER") end
  local preferences=N:Preferences()
  self.mode=preferences.editorMode or "representative"
  self.filter=preferences.editorFilter or "hud";self.groupFilter="all";self.query=""
  local mode=UI:CreateDropdown(f,14,-118,300,{
    {value="representative",text="대표 프레임"},{value="group",text="선택 그룹"},
    {value="part",text="선택 부품 (한 개 보기)"},{value="all",text="전체 부품"}},
    function() return E.mode end,function(v) E:SetMode(v) end)
  self.modePicker=mode
  self.categoryPicker=UI:CreateDropdown(f,330,-118,306,function()
    local options={{value="hud",text="HUD만"},{value="windows",text="기본창·도구창"},{value="all",text="모든 분류"}}
    local seen={};for _,h in ipairs(E.handles or {}) do local c=h.target.category;if not seen[c] then seen[c]=true;options[#options+1]={value=c,text=c} end end
    return options
  end,function() return E.filter end,function(v) E.filter=v;E.groupFilter="all";preferences.editorFilter=v;E:RefreshList();E:Select(E.selected) end)
  self.searchBox=UI:CreateEditBox(f,14,-152,300,nil,nil)
  UI:AttachTooltip(self.searchBox,"편집 대상 찾기","등록된 편집 대상의 분류·유닛·부품 이름을 검색합니다. 설정값은 변경하지 않습니다.")
  self.searchBox:SetScript("OnTextChanged",function(box) E.query=box:GetText():lower();E:RefreshList() end)
  self.searchBox:SetScript("OnEscapePressed",function(box) box:SetText("");box:ClearFocus() end)
  self.groupPicker=UI:CreateDropdown(f,330,-152,306,function()
    local options={{value="all",text="모든 유닛·그룹"}};local seen={}
    for _,h in ipairs(E.handles or {}) do local t=h.target
      if E:MatchesFilter(t) and not seen[t.groupID] then seen[t.groupID]=true;options[#options+1]={value=t.groupID,text=t.category.." > "..t.group} end
    end
    return options
  end,function() return E.groupFilter end,function(v) E.groupFilter=v;E:RefreshList() end)
  local viewport=CreateFrame("ScrollFrame",nil,f);viewport:SetPoint("TOPLEFT",14,-188);viewport:SetSize(622,112)
  local list=CreateFrame("Frame",nil,viewport);list:SetWidth(622);viewport:SetScrollChild(list)
  self.listViewport=viewport;self.listBody=list;self.listRows={}
  viewport:EnableMouseWheel(true);viewport:SetScript("OnMouseWheel",function(_,delta)
    viewport:SetVerticalScroll(math.max(0,math.min(math.max(0,list:GetHeight()-viewport:GetHeight()),viewport:GetVerticalScroll()-delta*28)))
  end)
  f.coordinateHint=UI:CreateDescription(f,"화면 중앙 (0, 0) · 선택한 테두리 중심 · 오른쪽 +X / 위쪽 +Y · UI px",14,-310);f.coordinateHint:SetWidth(622);f.coordinateHint:SetHeight(28);f.coordinateHint:SetJustifyH("CENTER")
  self.xInput=UI:CreateEditBox(f,139,-344,84,function() return E:CoordinateText("x") end,function(v) E:SetCoordinate("x",tonumber(v)) end,function() return E.selected and not E.selected.target.linked end)
  self.yInput=UI:CreateEditBox(f,265,-344,84,function() return E:CoordinateText("y") end,function(v) E:SetCoordinate("y",tonumber(v)) end,function() return E.selected and not E.selected.target.linked end)
  for _,box in ipairs({self.xInput,self.yInput}) do UI:AttachTooltip(box,"화면 좌표","화면 중앙이 (0, 0)입니다. 선택한 프레임 테두리 중심의 UI px 좌표를 입력하세요. 화면 밖 입력은 화면 안으로 조정합니다.") end
  f.xLabel=UI:CreateLabel(f,"X",115,-350);f.xLabel:SetWidth(16);f.xLabel:SetJustifyH("CENTER")
  f.yLabel=UI:CreateLabel(f,"Y",241,-350);f.yLabel:SetWidth(16);f.yLabel:SetJustifyH("CENTER")
  for _,v in ipairs({{"←",-1,0},{"→",1,0},{"↑",0,1},{"↓",0,-1}}) do
    local value=v
    local button=UI:CreateButton(f,value[1],373+(#(self.nudgeButtons or {}))*42,-344,36,function() E:Nudge(value[2],value[3]) end,function() return E.selected and not E.selected.target.linked end)
    self.nudgeButtons=self.nudgeButtons or {};self.nudgeButtons[#self.nudgeButtons+1]=button
  end
  KHQOL.PositionGrid:CreateControls(self,f)
  f:EnableKeyboard(true); f:SetPropagateKeyboardInput(true)
  f:SetScript("OnKeyDown",function(self,key)
    self:SetPropagateKeyboardInput(key~="ESCAPE")
    if key=="ESCAPE" then E:Finish(false) end
  end)
  f:SetScript("OnHide",function() if E.active then E:Finish(false) end end)
  f:RegisterEvent("PLAYER_REGEN_DISABLED"); f:RegisterEvent("PLAYER_REGEN_ENABLED"); f:RegisterEvent("PLAYER_LOGOUT")
  f:RegisterEvent("PLAYER_ENTERING_WORLD");f:RegisterEvent("PLAYER_LEAVING_WORLD")
  f:RegisterEvent("UPDATE_SHAPESHIFT_FORM");f:RegisterEvent("UI_SCALE_CHANGED");f:RegisterEvent("DISPLAY_SIZE_CHANGED")
  f:SetScript("OnEvent",function(_,event)
    if event=="PLAYER_REGEN_ENABLED" then E:RestorePendingAlphas();return end
    if E.active then E:Finish(false,event=="PLAYER_REGEN_DISABLED") end
  end)
  if UISpecialFrames then table.insert(UISpecialFrames,"KHQOLPositionEditorToolbar") end
  f:Hide(); self.toolbar=f
end
function E:SetHandleHighlight(h,on)
  h.focus:SetShown(on and true or false)
  h.focus:SetFrameLevel(h:GetFrameLevel()+(h.target and h.target.rootVisual and 8 or 2))
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
    E:SetHandleHighlight(self,true);self.caption:Show();if self.mirrorCount==0 then self.sample:Show() end
    GameTooltip:SetOwner(self,"ANCHOR_TOP"); GameTooltip:SetText(self.target.name,unpack(UI.Theme.Accent))
    GameTooltip:AddLine(self.target.linked and "부모 요소와 함께 이동합니다. 연결 관계는 유지됩니다." or "드래그로 이동 · 완료 시 저장 및 잠금",.85,.88,.9,true); GameTooltip:Show()
  end)
  h:SetScript("OnLeave",function(self) E:SetHandleHighlight(self,E.selected==self);self.caption:SetShown(E.selected==self);self.sample:SetShown(E.selected==self and self.mirrorCount==0);GameTooltip:Hide() end)
  h:SetScript("OnHide",function(self) E:SetHandleHighlight(self,false) end)
  h:Hide(); self.pool[id]=h; return h
end
function E:StopDrag(h)
  if not h or not h.target then return end
  h:StopMovingOrSizing(); if self.dragging==h then self.dragging=nil end
  local x,y=center(h); if not x then return end; local parent=h.parentHandle
  if h.target.minimap then
    local mx,my=center(Minimap); if not mx then return end; local angle=math.atan2(y-my,x-mx)
    local radius=108*Minimap:GetEffectiveScale()/UIParent:GetEffectiveScale()
    x,y=mx+math.cos(angle)*radius,my+math.sin(angle)*radius
  end
  local px,py;if parent then px,py=center(parent);if not px then return end end
  h:ClearAllPoints()
  if parent then h:SetPoint("CENTER",parent,"CENTER",x-px,y-py)
  else h:SetPoint("CENTER",UIParent,"BOTTOMLEFT",x,y) end
  if self.active then self:Select(h) end
end
function E:MatchesFilter(t)
  if self.filter=="hud" then return not t.largeWindow end
  if self.filter=="windows" then return t.largeWindow end
  return self.filter=="all" or t.category==self.filter
end
function E:SetMode(mode)
  self.mode=mode;self.onlySelected=mode=="part"
  N:Preferences().editorMode=mode;self:Select(self.selected)
end
function E:ListLabel(target,path)
  if self.groupFilter==target.groupID then
    local prefix=target.category.." > "..target.group.." > "
    if path:sub(1,#prefix)==prefix then return path:sub(#prefix+1) end
    if not UI.SettingsRegistry.modules[target.settingsRoute.module] then return target.name end
  end
  return path
end
function E:RefreshList()
  if not self.listBody then return end
  local count=0;local query=self.query or ""
  for _,h in ipairs(self.handles or {}) do
    local t=h.target;local path=N:Path(t.settingsRoute).." > "..t.name
    local match=true;for word in query:gmatch("%S+") do if not (path.." "..t.id):lower():find(word,1,true) then match=false;break end end
    if self:MatchesFilter(t) and (self.groupFilter=="all" or self.groupFilter==t.groupID) and match then
      count=count+1;local row=self.listRows[count]
      if not row then
        row=UI:CreateButton(self.listBody,"",0,-(count-1)*28,622,function(button)
          if not E.active or not button.handle or button.generation~=E.generation then return end
          E:StopDrag(E.dragging);E:Select(button.handle)
          if E.mode=="representative" and not button.handle.target.representative then E:SetMode("part") end
        end);self.listRows[count]=row
      end
      row.handle=h;row.generation=self.generation;row.fullPath=path
      row:SetText(self:ListLabel(t,path)..(t.linked and " · 연결/읽기 전용" or ""));row:SetWidth(622)
      row.tooltipDescription=nil
      UI:AttachTooltip(row,"편집 대상",path)
      row:GetFontString():SetWidth(606);row:GetFontString():SetJustifyH("CENTER");row:Show();UI:SetButtonSelected(row,h==E.selected)
    end
  end
  for i=count+1,#self.listRows do self.listRows[i].handle=nil;self.listRows[i]:Hide() end
  self.listBody:SetHeight(math.max(1,count*28))
  self.listViewport:SetVerticalScroll(math.min(self.listViewport:GetVerticalScroll(),math.max(0,self.listBody:GetHeight()-self.listViewport:GetHeight())))
  if self.groupPicker then self.groupPicker:Refresh() end
end
function E:Coordinate(axis)
  local h=self.selected;if not h then return 0 end
  local x,y=center(h);local cx,cy=KHQOL.PositionStore:Screen();if not x or not cx then return end
  return axis=="x" and x-cx or y-cy
end
function E:CoordinateText(axis)
  local value=self:Coordinate(axis);return value and string.format("%.1f",value) or "—"
end
function E:RefreshCoordinates()
  for axis,box in pairs({x=self.xInput,y=self.yInput}) do
    if box and not box:HasFocus() then
      local text=self:CoordinateText(axis);if box:GetText()~=text then box:SetText(text) end
    end
  end
end
function E:SetCoordinate(axis,value)
  local h=self.selected
  if not self.active or not h or h.target.linked or (axis~="x" and axis~="y") or not KHQOL.PositionStore:Number(value) then return end
  local current=self:Coordinate(axis);local cx,cy,w,ht=KHQOL.PositionStore:Screen();if current==nil or not cx then return end
  local _,_,ratio=KHQOL.PositionStore:Center(h);if not ratio then return end
  local limit=math.max(0,((axis=="x" and w or ht)-(axis=="x" and h:GetWidth() or h:GetHeight())*ratio)/2)
  value=math.max(-limit,math.min(limit,value))
  self:Nudge(axis=="x" and value-current or 0,axis=="y" and value-current or 0)
end
function E:Nudge(dx,dy)
  local h=self.selected;if not self.active or not h or h.target.linked or combat() then return end
  self:StopDrag(self.dragging);local x,y=center(h);if not x then return end
  local px,py;if h.parentHandle then px,py=center(h.parentHandle);if not px then return end end
  h:ClearAllPoints()
  if h.parentHandle then h:SetPoint("CENTER",h.parentHandle,"CENTER",x-px+dx,y-py+dy)
  else h:SetPoint("CENTER",UIParent,"BOTTOMLEFT",x+dx,y+dy) end
  self:Select(h)
end
function E:Select(handle)
  self.selected=handle
  for _,h in ipairs(self.handles or {}) do
    local related=handle and h.target.groupID==handle.target.groupID
    local show=self:MatchesFilter(h.target) and (self.mode=="all" or self.mode=="group" and related or self.mode=="part" and h==handle or self.mode=="representative" and h.target.representative)
    if h==handle and (self.mode=="group" or self.mode=="part") then show=true end
    self:SetHandleHighlight(h,h==handle);h:SetFrameLevel(h==handle and 180 or 100)
    h:SetShown(show);h:EnableMouse(show)
    h.caption:SetShown(show and h==handle);h.sample:SetShown(show and h==handle and h.mirrorCount==0)
  end
  self:UpdateSuppression()
  self.resetButton:Refresh()
  for _,button in ipairs(self.nudgeButtons or {}) do button:Refresh() end
  if self.modePicker then self.modePicker:Refresh() end
  if self.categoryPicker then self.categoryPicker:Refresh() end
  if self.xInput then self.xInput:Refresh();self.yInput:Refresh() end
  self:RefreshList()
end
function E:UpdateSuppression()
  for frame,state in pairs(self.suppressed or {}) do
    local hide=false
    for h in pairs(state.handles or {}) do if h:IsShown() and (not state.alphaOnly or h.previewReady) then hide=true;break end end
    if state.alphaOnly then
      local status,current=KHQOL.ReadPublicAPI(frame.GetAlpha,frame)
      if status=="ok" and KHQOL.IsPublicNumber(current) then
        if current~=state.last then state.alpha=current end
        local wanted=hide and 0 or state.alpha
        if current==wanted or KHQOL.ReadPublicAPI(frame.SetAlpha,frame,wanted)=="ok" then state.last=wanted end
      end
    elseif safe(frame) then frame:SetAlpha(hide and 0 or state.alpha);if frame.EnableMouse then frame:EnableMouse(not hide and state.mouse) end end
  end
  for _,h in ipairs(self.handles or {}) do
    if h.nativeBlocker then
      local show=h:IsShown() and h.previewReady and h.target.blockOriginal and h.target.blockOriginal()
      h.nativeBlocker:SetShown(show and true or false);h.nativeBlocker:EnableMouse(show and true or false)
    end
  end
end
function E:RestoreAlpha(frame,state)
  local status,current=KHQOL.ReadPublicAPI(frame.GetAlpha,frame)
  if status~="ok" or not KHQOL.IsPublicNumber(current) then return false end
  if current~=state.last or current==state.alpha then return true end
  return KHQOL.ReadPublicAPI(frame.SetAlpha,frame,state.alpha)=="ok"
end
function E:RestorePendingAlphas()
  for frame,state in pairs(self.pendingAlphaRestores or {}) do
    if self:RestoreAlpha(frame,state) then self.pendingAlphaRestores[frame]=nil end
  end
end
function E:ResetSelection()
  local h=self.selected;if not h or h.target.linked then return end
  self:StopDrag(self.dragging)
  local t=h.target;local x,y
  if t.minimap then
    local mx,my=center(Minimap);if not mx then return end;local radius=108*Minimap:GetEffectiveScale()/UIParent:GetEffectiveScale()
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
    local fx,fy=center(t.frame);if not x or not fx then return end;x=x+h.originX-fx;y=y+h.originY-fy
  else self:Message("이 연결 요소의 위치는 부모 설정에서 초기화하세요.");return end
  local px,py;if h.parentHandle then px,py=center(h.parentHandle);if not px then return end end
  h:ClearAllPoints()
  if h.parentHandle then
    h:SetPoint("CENTER",h.parentHandle,"CENTER",x-px,y-py)
    h.resetRelativeX,h.resetRelativeY=x-px,y-py
  else h:SetPoint("CENTER",UIParent,"BOTTOMLEFT",x,y) end
  h.resetting=true;h.resetX,h.resetY=x,y;self:Select(h)
end
function E:IsCurrent()
  if self.generation~=KHQOL.profileGeneration or self.labUnlocked~=KHQOL.LabLock:IsUnlocked() then return false end
  for key,enabled in pairs(self.enabled or {}) do if KHQOL:GetEnabled(key)~=enabled then return false end end
  for _,target in ipairs(self.targets or {}) do if target.current and not target.current() then return false end end
  return true
end
-- A read-only rendering copy: no live alert/test functions, scripts or sounds.
-- Native anchors, visibility flags and unit state stay unchanged. Root
-- previews can separately suppress opacity while the copied bars are shown.
function E:Mirror(h,frame)
  h.previewReady=nil
  if h.unitPreview then h.unitPreview:Hide() end
  if h.target.render then
    for _,region in ipairs(h.mirrors) do region:Hide() end
    for _,region in ipairs(h.art) do region:Hide() end
    h.previewReady=h.target.render(h)==true
    h.mirrorCount=h.previewReady and 1 or 0
    h.sample:SetShown(not h.previewReady)
    if h.previewReady then return end
  end
  local used=0; local hx,hy=h.originX,h.originY
  local function visit(node,depth)
    if depth>5 or used>=100 or not safe(node) then return end
    if node~=frame and self.sources[node] then return end
    if node.GetRegions then
      for _,region in ipairs({node:GetRegions()}) do
        local kind=region:GetObjectType()
        if (kind=="Texture" or kind=="FontString") and region:IsShown() and not self.sources[region]
          and (kind~="FontString" or (region:GetText() and region:GetText()~="")) then
          local x,y,ratio=KHQOL.PositionStore:Center(region); local _,w,ht=KHQOL.ReadPublicAPI(region.GetSize,region)
          if x and KHQOL.PositionStore:Number(w) and KHQOL.PositionStore:Number(ht) and w>0 and ht>0 and math.abs(x-hx)<h:GetWidth() and math.abs(y-hy)<h:GetHeight() then
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
      texture:SetSize(spec.width,spec.height)
      if spec.atlas then texture:SetTexture(nil);pcall(texture.SetAtlas,texture,spec.atlas,false) else texture:SetTexture(spec.texture) end
      texture:SetTexCoord(unpack(spec.texCoord or {0,1,0,spec.crop or 1})); texture:SetAlpha(1); texture:Show()
    end
  end
  h.mirrorCount=used
  h.sample:SetShown(used==0); h.sample:SetText(h.target.sample or "편집용 미리보기")
  h.sample:SetFont(UI:Font(),h.target.sampleSize or 12,"")
  h.sample:SetJustifyH(h.target.sampleJustify or "CENTER")
  h.sample:ClearAllPoints(); h.sample:SetPoint("CENTER",h,"CENTER",0,h.target.sampleY or 0)
end
function E:Enter(focus,entryMode)
  if self.active then return true end
  self:RestorePendingAlphas()
  if EditModeManagerFrame and KHQOL.PublicCall(EditModeManagerFrame.IsShown,EditModeManagerFrame)==true then self:Message("기본 게임 편집 모드를 닫은 후 KHQOL 위치 편집을 열어 주세요.");return false end
  if combat() then self:Message("전투 중에는 위치를 편집할 수 없습니다."); return false end
  if KHQOL.AlertLayout then KHQOL.AlertLayout:Suspend(true) end
  self:CreateToolbar(); UI:CancelDrafts(); UI:CloseDropdown(); GameTooltip:Hide()
  self.returnSettings=KHQOL.settings and KHQOL.settings:IsShown()
  self.scope=entryMode=="unitRoots" and "unitRoots" or nil
  self.targets=KHQOL:BuildPositionTargets(focus,self.scope);
  for _,t in ipairs(self.targets) do N:EditorMeta(t) end
  self.mode=self.scope=="unitRoots" and "all" or entryMode=="group" and "group" or focus and "part" or N:Preferences().editorMode or "representative";self.onlySelected=self.mode=="part"
  N:RememberScroll(KHQOL.settings)
  self.returnRoute=KHQOL.settings and KHQOL.settings.currentRoute
   self.sources={}; self.suppressed={}; self.handles={}; self.byID={}
  self.generation=KHQOL.profileGeneration
  self.labUnlocked=KHQOL.LabLock:IsUnlocked();self.enabled={}
  for key in pairs(KHQOL.db.enabled) do self.enabled[key]=KHQOL:GetEnabled(key) end
  for _,target in ipairs(self.targets) do if safe(target.frame) then self.sources[target.frame]=true end end
  for _,target in ipairs(self.targets) do
    if safe(target.frame) then
      local h=self:GetHandle(target.id); h.resetting=nil; h.target=target; target.handle=h
      local x,y,ratio=KHQOL.PositionStore:Center(target.frame)
      local status,w,ht=KHQOL.ReadPublicAPI(target.frame.GetSize,target.frame)
      if x and ratio>0 and status=="ok" and KHQOL.PositionStore:Number(w) and KHQOL.PositionStore:Number(ht) then
        if target.bounds then x,y,w,ht=target.bounds(x,y,w*ratio,ht*ratio) else w,ht=w*ratio,ht*ratio end
        if KHQOL.PositionStore:Number(x) and KHQOL.PositionStore:Number(y) and KHQOL.PositionStore:Number(w) and KHQOL.PositionStore:Number(ht) then
          if not target.exactBounds and (not target.art or #target.art==0) then
            w=math.max(w,math.min(360,#(target.sample or "")*4+16));ht=math.max(ht,28)
          end
          local minimum=target.exactBounds and 1 or 16
          h:SetSize(math.max(minimum,w),math.max(minimum,ht)); h:ClearAllPoints(); h:SetPoint("CENTER",UIParent,"BOTTOMLEFT",x,y)
          h.originX,h.originY=x,y; target.scale=ratio
          h.caption:SetText(target.name); self:SetHandleHighlight(h,false)
          h.sample:SetWidth(math.max(target.art and #target.art>0 and 160 or 8,w-8)); h:SetFrameLevel(100); h:EnableMouse(true); h:Show()
          self.handles[#self.handles+1]=h; self.byID[target.id]=h
      end
      end
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
      h.previewReady=nil
      h.mirrorCount=0
      if h.unitPreview then h.unitPreview:Hide() end
      for _,region in ipairs(h.mirrors) do region:Hide() end
      for _,region in ipairs(h.art) do region:Hide() end
      h.sample:SetText(h.target.sample or "편집용 미리보기"); h.sample:Show()
    end
    local rect=h.target.inputBlockRect
    if rect then
      if not h.nativeBlocker then
        h.nativeBlocker=CreateFrame("Frame",nil,UIParent);h.nativeBlocker:SetFrameStrata("FULLSCREEN_DIALOG");h.nativeBlocker:SetFrameLevel(90)
        h.nativeBlocker:SetScript("OnMouseDown",function() if E.active and h.target then E:Select(h) end end)
      end
      h.nativeBlocker:ClearAllPoints();h.nativeBlocker:SetPoint("CENTER",UIParent,"BOTTOMLEFT",rect.x,rect.y)
      h.nativeBlocker:SetSize(rect.width,rect.height);h.nativeBlocker:Hide();h.nativeBlocker:EnableMouse(false)
    end
  end
  -- Suppress original mouse input too: transparent old HUDs must not catch clicks.
  local function suppress(frame,h)
    if not safe(frame) then return end
    self.suppressed[frame]=self.suppressed[frame] or {alpha=frame:GetAlpha(),mouse=frame.IsMouseEnabled and frame:IsMouseEnabled() or false,handles={}}
    self.suppressed[frame].handles[h]=true
    if frame.GetChildren then for _,child in ipairs({frame:GetChildren()}) do suppress(child,h) end end
  end
  for _,h in ipairs(self.handles) do
    suppress(h.target.frame,h)
    for _,frame in ipairs(h.target.suppress or {}) do suppress(frame,h) end
    for _,frame in ipairs(h.target.suppressAlpha or {}) do
      local status,alpha=KHQOL.ReadPublicAPI(frame.GetAlpha,frame)
      if status=="ok" and KHQOL.IsPublicNumber(alpha) then
        self.suppressed[frame]=self.suppressed[frame] or {alpha=alpha,last=alpha,alphaOnly=true,handles={}}
        self.suppressed[frame].handles[h]=true
      end
    end
  end
  self.active=true
  if KHQOL.settings then KHQOL.settings:Hide() end
  self.toolbar.title:SetText(self.scope=="unitRoots" and "KHQOL · 유닛 프레임 위치 이동" or "KHQOL · 위치 편집")
  self.toolbar.info:SetText(self.scope=="unitRoots" and "간결한 프레임을 켠 유닛의 테두리를 드래그하세요. 완료 시 저장 · ESC 취소" or "목록에서 대상을 고르고 테두리를 드래그하세요. ESC는 취소합니다. ("..#self.handles.."개)")
  self.toolbar:SetScale(math.min(.9,(UIParent:GetWidth()-24)/650,(UIParent:GetHeight()-24)/458)); UI:Refresh(self.toolbar); self.toolbar:Show()
  KHQOL.PositionGrid:Refresh();KHQOL.PositionGrid:RefreshControls()
  local selected
  for _,h in ipairs(self.handles) do if h.target.id==focus or h.target.key==focus then selected=selected or h end end
  selected=selected or self.handles[1]
  if focus and selected then
    self.filter=entryMode=="group" and "all" or selected.target.largeWindow and "windows" or "hud"
    self.query="";self.groupFilter=entryMode=="group" and selected.target.groupID or "all";self.searchBox:SetText("")
  elseif not focus then
    self.groupFilter="all";self.query="";self.searchBox:SetText("")
  end
  self:Select(selected)
  -- Exists only during editing; live HUD animations may write their own alpha.
  self.toolbar:SetScript("OnUpdate",function()
    if combat() or not self:IsCurrent() or KHQOL.PublicCall(EditModeManagerFrame and EditModeManagerFrame.IsShown,EditModeManagerFrame)==true then self:Finish(false,combat()); return end
    self:UpdateSuppression()
    if self.dragging then self:RefreshCoordinates() end
  end)
  return true
end
function E:Finish(save,combatExit)
  if not self.active then return end
  if save and (combat() or not self:IsCurrent()) then save=false end
  self:StopDrag(self.dragging)
  -- Validate the entire draft before any writer or reset callback runs.
  if save then
    for _,h in ipairs(self.handles) do
      if not center(h) or (h.parentHandle and not center(h.parentHandle)) then save=false;break end
    end
  end
  UI:CloseDropdown()
  self.active=false; self.toolbar:SetScript("OnUpdate",nil)
  KHQOL.PositionGrid:Hide()
  -- Restore input/alpha first; applying module locks below decides final input.
  for frame,state in pairs(self.suppressed) do
    if state.alphaOnly then
      if not self:RestoreAlpha(frame,state) then
        self.pendingAlphaRestores=self.pendingAlphaRestores or {};self.pendingAlphaRestores[frame]=state
      end
    elseif safe(frame) then frame:SetAlpha(state.alpha); if frame.EnableMouse then frame:EnableMouse(state.mouse) end end
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
  for _,h in ipairs(self.handles) do
    if h.nativeBlocker then h.nativeBlocker:Hide();h.nativeBlocker:EnableMouse(false) end
    h:StopMovingOrSizing();h:EnableMouse(false);h:Hide();h.target=nil;h.parentHandle=nil;h.previewReady=nil
  end
  self.selected=nil;self.enabled=nil;self.targets=nil; self.suppressed=nil; self.sources=nil; self.handles=nil; self.byID=nil;self.scope=nil
  self.toolbar:StopMovingOrSizing(); self.toolbar:Hide(); GameTooltip:Hide()
  if combatExit then self:Message("전투가 시작되어 위치 편집을 취소했습니다.")
  elseif self.returnSettings and KHQOL.settings then
    if self.returnRoute then N:Open(self.returnRoute,nil,true) else KHQOL.settings:Show() end
    if KHQOL.settings.activeContent then UI:Refresh(KHQOL.settings.activeContent); KHQOL.settings:UpdateContentHeight() end
  end
  self.returnSettings=nil;self.returnRoute=nil
  if KHQOL.AlertLayout then KHQOL.AlertLayout:Suspend(false) end
  return save and true or false
end
