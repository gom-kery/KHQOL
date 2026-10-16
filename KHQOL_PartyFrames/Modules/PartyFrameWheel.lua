local _, K = ...
K = assert(_G.KHQOL, "Install and enable the KHQOL core addon.")
local M=K.modules.partyFrames
local call=K.PublicCall
M.wheelEnterSnippet=[[
self:ClearBindings()
self:SetAttribute("kh-entered",true)
if self:IsVisible() and self:GetAttribute("unit") and self:GetAttribute("kh-wheel") then
  if self:GetAttribute("kh-up") then self:SetBindingClick(true,"MOUSEWHEELUP",self:GetName().."WheelUp","LeftButton") end
  if self:GetAttribute("kh-down") then self:SetBindingClick(true,"MOUSEWHEELDOWN",self:GetName().."WheelDown","LeftButton") end
end
]]
M.wheelLeaveSnippet=[[self:ClearBindings();self:SetAttribute("kh-entered",nil)]]
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
function M:SetWheelSpell(direction,value)
  if direction~="up" and direction~="down" then return false end
  local id,reason=self:ResolveSpell(value)
  if id==nil then self.inputReason=reason;self:RefreshStatus();return false end
  self:GetCharacterDB()[direction]=id;self.inputReason=nil;self:RequestApply()
  self:RefreshBookWheel();if self.profileContent then self.profileContent:RefreshTab() end
  return true
end
function M:SpellLabel(direction)
  local id=self:GetCharacterDB()[direction]
  local label="미등록 · 기존 단축키 유지"
  if K.IsPublicNumber(id) and id>0 then
    local info=call(C_Spell and C_Spell.GetSpellInfo,id)
    local name=info and call(function() return info.name end) or "확인되지 않은 주문"
    local rank=call(C_Spell and C_Spell.GetSpellSubtext,id)
    label=(type(name)=="string" and name or "확인되지 않은 주문")..(type(rank)=="string" and rank~="" and " ("..rank..")" or "").." · ID "..id
  end
  if self.pending then
    local applied=self.wheelApplied or {};local current=applied.enabled and applied[direction] or 0
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
  local up,down=0,0
  if char.wheelEnabled then
    local conflict=self:WheelConflict()
    if conflict then self.wheelReason=conflict.." 감지 · 휠 적용 보류"
    else
      local ur,dr
      up,ur=self:ResolveSpell(char.up);down,dr=self:ResolveSpell(char.down)
      if not up or not down then self.wheelReason=ur or dr end
      up=up or 0;down=down or 0
    end
  end
  self.wheelApplied={enabled=char.wheelEnabled and (up>0 or down>0),up=up,down=down}
  for _,b in ipairs(self.buttons) do
    b:SetAttribute("_onenter",self.wheelEnterSnippet);b:SetAttribute("_onleave",self.wheelLeaveSnippet);b:SetAttribute("_onhide",self.wheelLeaveSnippet)
    b:SetAttribute("refreshUnitChange",[[if not self:GetAttribute("unit") then self:ClearBindings();self:SetAttribute("kh-entered",nil) end]])
    b:SetAttribute("kh-wheel",self.wheelApplied.enabled);b:SetAttribute("kh-up",up>0);b:SetAttribute("kh-down",down>0)
    b.WheelUp:SetAttribute("spell",up>0 and tostring(up) or nil);b.WheelDown:SetAttribute("spell",down>0 and tostring(down) or nil)
    if b:GetAttribute("kh-entered") and self.applied then b:Execute(self.wheelEnterSnippet) end
  end
end
function M:OpenClickSettings()
  if call(InCombatLockdown)==true then return false,"전투 종료 후 게임 클릭 시전 설정을 열어 주세요." end
  if type(ClickBindingFrame_LoadUI)=="function" then ClickBindingFrame_LoadUI() end
  if C_AddOns and type(C_AddOns.LoadAddOn)=="function" then call(C_AddOns.LoadAddOn,"Blizzard_ClickBindingUI") end
  if ClickBindingFrame and type(SetUIPanelShown)=="function" then SetUIPanelShown(ClickBindingFrame,true);return true end
  return false,"게임 클릭 시전 설정 UI 미지원"
end
