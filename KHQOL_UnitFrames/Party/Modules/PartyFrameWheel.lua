local _,package=...
if not package.loadParty then return end
local _, K = ...
K = assert(_G.KHQOL, "Install and enable the KHQOL core addon.")
local M=K.modules.partyFrames
local call=K.PublicCall
M.wheelEnterSnippet=[[
self:ClearBindings()
self:SetAttribute("kh-entered",true)
self:RunAttribute("kh-wheel-refresh")
]]
M.wheelRefreshSnippet=[[
self:ClearBindings()
if self:IsVisible() and self:GetAttribute("unit") and self:GetAttribute("kh-wheel") then
  local controller=self:GetFrameRef("kh-wheel-controller")
  local state=controller and controller:GetAttribute("state-khwheelmod")
  if state=="none" then
    if self:GetAttribute("kh-up") then self:SetBindingClick(true,"MOUSEWHEELUP",self:GetName().."WheelUp","LeftButton") end
    if self:GetAttribute("kh-down") then self:SetBindingClick(true,"MOUSEWHEELDOWN",self:GetName().."WheelDown","LeftButton") end
  elseif state=="shift" then
    if self:GetAttribute("kh-shiftUp") then self:SetBindingClick(true,"SHIFT-MOUSEWHEELUP",self:GetName().."ShiftWheelUp","LeftButton") end
    if self:GetAttribute("kh-shiftDown") then self:SetBindingClick(true,"SHIFT-MOUSEWHEELDOWN",self:GetName().."ShiftWheelDown","LeftButton") end
  end
end
]]
M.wheelLeaveSnippet=[[self:ClearBindings();self:SetAttribute("kh-entered",nil)]]
M.wheelModifierSnippet=[[
for i=1,45 do
  local button=self:GetFrameRef("button"..i)
  if button and button:GetAttribute("kh-entered") then button:RunAttribute("kh-wheel-refresh") end
end
]]
M.wheelModifiers={{value="none",text="없음"},{value="shift",text="Shift"}}
M.wheelSettingIDs={up="setting.partyFrames.roles.control063",down="setting.partyFrames.roles.control062",shiftUp="setting.partyFrames.shiftUp",shiftDown="setting.partyFrames.shiftDown"}
function M:WheelField(direction,modifier)
  if direction~="up" and direction~="down" then return nil end
  if modifier==nil or modifier=="none" then return direction end
  if modifier=="shift" then return direction=="up" and "shiftUp" or "shiftDown" end
end
function M:GetWheelSpell(direction,modifier)
  local key=self:WheelField(direction,modifier);return key and self:GetCharacterDB()[key] or 0
end
function M:GetWheelEditModifier() return self.wheelEditModifier=="shift" and "shift" or "none" end
function M:SetWheelEditModifier(value)
  if value~="none" and value~="shift" then return false end
  self.wheelEditModifier=value;self:RefreshBookWheel();return true
end
function M:ResolveSpell(value)
  if value~=nil and (not K.IsPublicValue(value) or (type(value)~="string" and type(value)~="number")) then return nil,"주문 입력을 확인할 수 없음" end
  local text=tostring(value or ""):match("^%s*(.-)%s*$")
  if text=="" or text=="0" then return 0 end
  if not C_Spell or type(C_Spell.GetSpellInfo)~="function" or not C_SpellBook or type(C_SpellBook.IsSpellKnown)~="function" then return nil,"주문 확인 API 미지원" end
  local input=tonumber(text) or text
  local info=call(C_Spell.GetSpellInfo,input)
  if type(info)~="table" then return nil,"주문 이름 또는 ID를 확인할 수 없음" end
  local ok,id,name=pcall(function() return info.spellID,info.name end)
  if not ok or not K.IsPublicNumber(id) or id<=0 or id~=math.floor(id) or not K.IsPublicValue(name) or type(name)~="string" then return nil,"주문 정보 접근 제한" end
  if type(input)=="number" and input~=id then return nil,"정확한 주문 ID가 일치하지 않음" end
  if call(C_SpellBook.IsSpellKnown,id,Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or nil)~=true then return nil,"현재 캐릭터가 배우지 않은 주문" end
  return id
end
function M:SetWheelSpell(direction,value,modifier,observe)
  local key=self:WheelField(direction,modifier);if not key then return false end
  local id,reason=self:ResolveSpell(value)
  if id==nil then self.inputReason=reason;self:RefreshStatus();return false end
  local char=self:GetCharacterDB();local changed=char[key]~=id
  char[key]=id;self.inputReason=nil;self:RequestApply()
  if observe and changed then K.UsageDiagnostics:Emit(self.wheelSettingIDs[key],"change","click",nil,true) end
  self:RefreshBookWheel();if self.profileContent then self.profileContent:RefreshTab() end
  return true
end
function M:SpellLabel(direction,modifier)
  local key=self:WheelField(direction,modifier);local id=self:GetWheelSpell(direction,modifier)
  local label="미등록 · 기존 단축키 유지"
  if K.IsPublicNumber(id) and id>0 then
    local info=call(C_Spell and C_Spell.GetSpellInfo,id)
    local name=info and call(function() return info.name end) or "확인되지 않은 주문"
    local rank=call(C_Spell and C_Spell.GetSpellSubtext,id)
    label=(type(name)=="string" and name or "확인되지 않은 주문")..(type(rank)=="string" and rank~="" and " ("..rank..")" or "").." · ID "..id
  end
  if self.pending then
    local applied=self.wheelApplied or {};local current=applied.enabled and applied[key] or 0
    return "저장: "..label.." / 현재 적용: "..(current>0 and "주문 ID "..current or "기존 단축키")
  end
  return label
end
function M:WheelConflict()
  for _,name in ipairs({"Clique","Clicked","HealBot","VuhDo","Cell"}) do
    if _G[name] or call(C_AddOns and C_AddOns.IsAddOnLoaded,name)==true then return name end
  end
  if type(ClickCastFrames)=="table" then return "외부 클릭 시전 시스템" end
end
function M:ApplyWheel()
  local char=self:GetCharacterDB();self.wheelReason=nil
  local applied={enabled=false,up=0,down=0,shiftUp=0,shiftDown=0}
  local conflict=char.wheelEnabled and self:WheelConflict()
  if conflict then self.wheelReason=conflict.." 감지 · 휠 적용 보류"
  elseif char.wheelEnabled then
    for _,key in ipairs({"up","down","shiftUp","shiftDown"}) do
      local id,why=self:ResolveSpell(char[key]);applied[key]=id or 0
      if why then self.wheelReason=self.wheelReason or why end
      if applied[key]>0 then applied.enabled=true end
    end
  end
  self.wheelApplied=applied
  if not self.wheelController then self.wheelController=CreateFrame("Frame",nil,self.root,"SecureHandlerStateTemplate") end
  local controller=self.wheelController
  controller:SetAttribute("_onstate-khwheelmod",self.wheelModifierSnippet)
  for i,b in ipairs(self.buttons) do
    controller:SetFrameRef("button"..i,b);b:SetFrameRef("kh-wheel-controller",controller)
    b:SetAttribute("kh-wheel-refresh",self.wheelRefreshSnippet)
    b:SetAttribute("_onenter",self.wheelEnterSnippet);b:SetAttribute("_onleave",self.wheelLeaveSnippet);b:SetAttribute("_onhide",self.wheelLeaveSnippet)
    b:SetAttribute("refreshUnitChange",[[if not self:GetAttribute("unit") then self:ClearBindings();self:SetAttribute("kh-entered",nil) end]])
    b:SetAttribute("kh-wheel",applied.enabled)
    for _,entry in ipairs({{"up","WheelUp"},{"down","WheelDown"},{"shiftUp","ShiftWheelUp"},{"shiftDown","ShiftWheelDown"}}) do
      local key,child=entry[1],b[entry[2]];local id=applied[key]
      b:SetAttribute("kh-"..key,child~=nil and id>0)
      if child then child:SetAttribute("spell",id>0 and tostring(id) or nil) end
    end
    if b:GetAttribute("kh-entered") and self.applied then b:Execute(self.wheelEnterSnippet) end
  end
  if applied.enabled then RegisterStateDriver(controller,"khwheelmod","[mod:ctrl] other; [mod:alt] other; [mod:shift] shift; none")
  else UnregisterStateDriver(controller,"khwheelmod") end
end
function M:OpenClickSettings()
  if call(InCombatLockdown)==true then return false,"전투 종료 후 게임 클릭 시전 설정을 열어 주세요." end
  if type(ClickBindingFrame_LoadUI)=="function" then call(ClickBindingFrame_LoadUI) end
  if not ClickBindingFrame and C_AddOns and type(C_AddOns.LoadAddOn)=="function" then call(C_AddOns.LoadAddOn,"Blizzard_ClickBindingUI") end
  if K.WindowLayers:Readable(ClickBindingFrame) and type(SetUIPanelShown)=="function" then
    local status=K.ReadPublicAPI(SetUIPanelShown,ClickBindingFrame,true)
    if status=="ok" and call(ClickBindingFrame.IsShown,ClickBindingFrame)==true then
      local range=K.modules.range;if range and range.CloseSpellBookPanel then range:CloseSpellBookPanel() end
      self:CloseStandaloneWheelBook();if K.settings then K.settings:Hide() end;return true
    end
  end
  return false,"게임 클릭 시전 설정 UI 미지원"
end
