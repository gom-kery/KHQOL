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
  local ok,result=pcall(tostring,value)
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
  if self.info then self.info:SetText(self.snapshot) end
end
function I:SetEnabled(on)
  self.enabled=on and true or false; self.elapsed=0
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
  elseif self.info then self.info:SetText("이 클라이언트에서 Frame Stack을 실행할 수 없습니다.") end
end
function I:BuildSettings(content,y)
  local UI,T=KHQOL.UI,KHQOL.UI.Theme
  self.content=content
  local b=UI:CreateBuilder(content,y)
  b:Section("프레임 검사기")
  b:Checkbox("Frame Inspector 활성화",function() return I.enabled end,function(on) I:SetEnabled(on) end)
  b:Description("1. 확인할 Blizzard 창을 엽니다.\n2. 마우스를 창 위에 올립니다.\n3. 이름과 부모 경로를 확인합니다. KHQOL 위에서는 마지막 정보를 유지합니다.\n페이지를 닫거나 이동하면 검사기가 꺼집니다. Reload 후 기본 OFF입니다.")
  b:Section("현재 Frame")
  b:Flush()
  self.info=UI:CreateDescription(content,self.snapshot or "검사기를 활성화하세요.",0,b.y)
  self.info:SetWidth(T.ContentWidth); self.info:SetHeight(500)
  b.y=b.y-500-T.RowGap
  local copyBox
  b:Button("현재 정보 복사",function()
    copyBox:SetText(I.snapshot or ""); copyBox:Show(); copyBox:SetFocus(); copyBox:HighlightText()
  end,nil,function() return I.snapshot~=nil end)
  b:Button("Frame Stack 열기",function() I:OpenFrameStack() end,nil,function()
    return not (InCombatLockdown and InCombatLockdown()) and I:HasFrameStack()
  end)
  b:Description("복사 버튼을 누른 뒤 아래 입력창에서 Ctrl+C를 누르세요. Frame Stack은 Blizzard 기본 도구이며 닫기는 /fstack으로 가능합니다.")
  b:Flush()
  copyBox=UI:CreateEditBox(content,0,b.y,T.ContentWidth,function() return I.snapshot or "" end)
  copyBox:SetMultiLine(true); copyBox:SetHeight(260); copyBox:SetMaxLetters(0)
  copyBox:Hide(); b.y=b.y-260-T.SectionGap
  content:HookScript("OnHide",function() I:SetEnabled(false); copyBox:ClearFocus(); copyBox:Hide() end)
  content:HookScript("OnShow",function() UI:Refresh(content) end)
  return b.y
end
