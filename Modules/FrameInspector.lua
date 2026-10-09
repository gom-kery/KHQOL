local _, KHQOL = ...
local I={enabled=false,elapsed=0}
KHQOL.modules.frameInspector=I
local function call(object,method,...)
  if not object or type(object[method])~="function" then return end
  local ok,a,b,c,d,e=pcall(object[method],object,...)
  if ok then return a,b,c,d,e end
end
local function text(value)
  if value==nil then return "(없음)" end
  local ok,result=pcall(function()
    if type(value)=="number" then return string.format("%.2f",value):gsub("0+$",""):gsub("%.$","") end
    return tostring(value)
  end)
  return ok and result or "(보호된 값)"
end
local function name(f) return text(call(f,"GetName") or call(f,"GetDebugName")) end
function I:Describe(f)
  if not f then return "마우스를 확인할 Blizzard 창 위에 올리세요." end
  local parent=call(f,"GetParent")
  local lines={"Frame: "..text(call(f,"GetName")),"DebugName: "..text(call(f,"GetDebugName")),
    "Parent: "..name(parent),"Strata: "..text(call(f,"GetFrameStrata")),"Level: "..text(call(f,"GetFrameLevel")),
    "Size: "..text(call(f,"GetWidth")).." x "..text(call(f,"GetHeight")),
    "MouseEnabled: "..text(call(f,"IsMouseEnabled")),"Movable: "..text(call(f,"IsMovable"))}
  local count=call(f,"GetNumPoints")
  if type(count)=="number" then
    for index=1,math.min(count,16) do
      local p,relative,rp,x,y=call(f,"GetPoint",index)
      lines[#lines+1]="Anchor "..index..": "..text(p).."; RelativeTo: "..name(relative).."; RelativePoint: "..text(rp).."; X: "..text(x).."; Y: "..text(y)
    end
  end
  lines[#lines+1]="Parent chain:"
  local current=f
  for depth=1,16 do
    if not current then break end
    lines[#lines+1]=depth..". "..name(current)
    local nextParent=call(current,"GetParent")
    if nextParent==current then break end
    current=nextParent
  end
  lines[#lines+1]="API: "..(self.api or "(사용 불가)")
  if GetBuildInfo then
    local version,build,_,interface=GetBuildInfo()
    lines[#lines+1]="Client: "..text(version).." / "..text(build).." / "..text(interface)
  end
  return table.concat(lines,"\n")
end
function I:Sample()
  local f
  self.api=nil
  if type(GetMouseFoci)=="function" then
    local ok,foci=pcall(GetMouseFoci)
    if ok and type(foci)=="table" then f=foci[1]; self.api="GetMouseFoci" end
  elseif type(GetMouseFocus)=="function" then
    local ok,focus=pcall(GetMouseFocus)
    if ok then f=focus; self.api="GetMouseFocus" end
  end
  -- Keep the last external sample available while clicking Copy in KHQOL.
  local current=f
  for _=1,32 do
    if not current then break end
    if current==KHQOL.settings then return end
    local p=call(current,"GetParent")
    if p==current then break end
    current=p
  end
  local ok,result=pcall(self.Describe,self,f)
  self.snapshot=ok and result or "프레임 정보가 보호되어 읽을 수 없습니다."
  self:UpdateInformation(self.snapshot)
end
function I:SetEnabled(on)
  self.enabled=on and true or false; self.elapsed=0
  if self.toggle then self.toggle:Refresh() end
  if not self.content then return end
  self.content:SetScript("OnUpdate",nil)
  if self.enabled and self.content:IsShown() then
    self:Sample()
    self.content:SetScript("OnUpdate",function(_,elapsed)
      I.elapsed=I.elapsed+elapsed
      if I.elapsed>=.25 then I.elapsed=0; I:Sample() end
    end)
  end
end
local function addonAPI(method)
  return C_AddOns and C_AddOns[method] or _G[method]
end
function I:HasFrameStack()
  if type(FrameStackTooltip_Toggle)=="function" then return true end
  local getInfo=addonAPI("GetAddOnInfo")
  if type(getInfo)=="function" then
    local ok,info=pcall(getInfo,"Blizzard_DebugTools")
    return ok and info~=nil
  end
  return false
end
function I:OpenFrameStack()
  if InCombatLockdown and InCombatLockdown() then return end
  if type(FrameStackTooltip_Toggle)~="function" then
    local load=addonAPI("LoadAddOn")
    if type(load)=="function" then pcall(load,"Blizzard_DebugTools") end
  end
  if type(FrameStackTooltip_Toggle)=="function" then pcall(FrameStackTooltip_Toggle,false,true,true)
  elseif self.info then self:UpdateInformation("이 클라이언트에서 Frame Stack을 실행할 수 없습니다.") end
end
function I:UpdateInformation(value)
  if not self.info then return end
  -- Remove the previous height before measuring a longer wrapped snapshot.
  self.info:SetHeight(0)
  self.info:SetText(value)
  local height=math.max(18,self.info:GetStringHeight())
  self.info:SetHeight(height)
  if self.content and self.infoY then
    self.content:SetHeight(-self.infoY+height+KHQOL.UI.Theme.ContentPadding)
  end
  if self.actions then KHQOL.UI:Refresh(self.actions) end
end
function I:EnsureFixedControls()
  if self.actions or not KHQOL.settings then return end
  local UI,T=KHQOL.UI,KHQOL.UI.Theme
  local settings=KHQOL.settings
  self.toggle=UI:CreateCheckbox(settings.moduleHeader,"프레임 인스펙터 활성화",T.ContentWidth-250,0,
    function() return I.enabled end,function(on) I:SetEnabled(on) end)
  self.toggle.ignoreModuleEnabled=true; self.toggle.text:SetWidth(216); self.toggle:Hide()
  local actions=CreateFrame("Frame",nil,settings)
  self.actions=actions
  actions:SetPoint("BOTTOMLEFT",settings,"BOTTOMLEFT",T.SidebarWidth+T.ContentPadding,58)
  actions:SetSize(T.ContentWidth,64); actions:Hide()
  UI:CreateButton(actions,"현재 정보 복사",0,0,180,function() I:CopyInformation() end,
    function() return I.snapshot~=nil end)
  UI:CreateButton(actions,"Frame Stack 열기",T.ContentWidth/2,0,190,function() I:OpenFrameStack() end,
    function() return not (InCombatLockdown and InCombatLockdown()) and I:HasFrameStack() end)
  local hint=UI:CreateDescription(actions,"복사 창에서 Ctrl+C · Esc로 닫기. Frame Stack 닫기: /fstack",0,-34)
  hint:SetWidth(T.ContentWidth); hint:SetJustifyV("TOP")
  actions:RegisterEvent("PLAYER_REGEN_DISABLED"); actions:RegisterEvent("PLAYER_REGEN_ENABLED")
  actions:SetScript("OnEvent",function() UI:Refresh(actions) end)
  -- Copy is a fixed overlay over the viewport, never below the scroll content.
  local overlay=CreateFrame("Frame",nil,settings,"BackdropTemplate")
  overlay:SetPoint("TOPLEFT",settings.scroll,"TOPLEFT",0,0)
  overlay:SetPoint("BOTTOMRIGHT",settings.scroll,"BOTTOMRIGHT",0,0)
  overlay:SetFrameLevel(settings.scroll:GetFrameLevel()+10)
  UI:Surface(overlay); overlay:Hide(); self.copyOverlay=overlay
  local box=UI:CreateEditBox(overlay,8,-8,T.ContentWidth-16)
  box:ClearAllPoints(); box:SetPoint("TOPLEFT",8,-8); box:SetPoint("BOTTOMRIGHT",-8,8)
  box:SetMultiLine(true); box:SetMaxLetters(0); self.copyBox=box
  box:SetScript("OnEscapePressed",function() box:ClearFocus(); overlay:Hide() end)
  box:SetScript("OnEnterPressed",function() box:ClearFocus() end)
end
function I:CopyInformation()
  if not self.copyBox or not self.snapshot then return end
  self.copyOverlay:Show(); self.copyBox:SetText(self.snapshot)
  self.copyBox:SetFocus(); self.copyBox:HighlightText()
end
function I:SetPageActive(active)
  self:EnsureFixedControls()
  local settings=KHQOL.settings
  if not settings or not self.actions then return end
  self.toggle:SetShown(active); self.actions:SetShown(active)
  settings.moduleHeader.description:SetWidth(KHQOL.UI.Theme.ContentWidth-(active and 264 or 124))
  settings.scroll:SetPoint("BOTTOMRIGHT",-38,active and 136 or 58)
  if not active then
    self:SetEnabled(false); self.copyBox:ClearFocus(); self.copyOverlay:Hide()
  end
  KHQOL.UI:Refresh(self.actions)
  if settings.activeContent then settings:UpdateContentHeight() end
end
function I:BuildSettings(content,y)
  local UI,T=KHQOL.UI,KHQOL.UI.Theme
  self.content=content; self:EnsureFixedControls()
  local b=UI:CreateBuilder(content,y)
  b:Description("확인할 창 위에 마우스를 올리세요. KHQOL 위에서는 마지막 정보를 유지합니다. 페이지를 닫으면 검사기가 꺼집니다.")
  b:Section("현재 Frame")
  self.infoY=b.y
  self.info=UI:CreateDescription(content,self.snapshot or "마우스를 확인할 Blizzard 창 위에 올리세요.",0,b.y)
  self.info:SetWidth(T.ContentWidth); self.info:SetJustifyV("TOP")
  self:UpdateInformation(self.snapshot or "마우스를 확인할 Blizzard 창 위에 올리세요.")
  content:HookScript("OnHide",function()
    I:SetEnabled(false)
    if I.copyBox then I.copyBox:ClearFocus(); I.copyOverlay:Hide() end
  end)
  content:HookScript("OnShow",function() if I.toggle then I.toggle:Refresh() end end)
  return -content:GetHeight()
end
