local _,K=...
K = assert(_G.KHQOL, "Install and enable the KHQOL core addon.")
local M=K.modules.partyFrames
local call=K.PublicCall
function M:ReceiveWheelSpell(direction)
  if call(InCombatLockdown)==true then self.wheelBookMessage="전투 종료 후 스킬을 등록하세요.";self:RefreshBookWheel();return false end
  local kind,_,_,id=call(GetCursorInfo)
  if kind~="spell" or not K.IsPublicNumber(id) or id<=0 or id~=math.floor(id) then
    self.wheelBookMessage="마법책에서 배운 스킬을 끌어 놓으세요.";self:RefreshBookWheel();return false
  end
  local ok=self:SetWheelSpell(direction,id)
  self.wheelBookMessage=ok and "등록했습니다. 프레임 안 휠 시전 사용을 켜세요." or self.inputReason
  if ok and type(ClearCursor)=="function" then ClearCursor() end
  self:RefreshBookWheel();return ok
end
function M:RefreshBookWheel()
  local p=self.wheelBookPanel;if not p then return end
  for _,direction in ipairs({"up","down"}) do
    p[direction.."Info"]:SetText(self:SpellLabel(direction))
    local id=self:GetCharacterDB()[direction];local info=call(C_Spell and C_Spell.GetSpellInfo,id)
    local icon=type(info)=="table" and call(function() return info.iconID end)
    p[direction.."Icon"]:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
  end
  p.message:SetText(self.wheelBookMessage or self.inputReason or "등록칸에 마법책 스킬을 끌어 놓으세요. 주문과 등급은 캐릭터별로 저장합니다.")
  if p.enabled then p.enabled:Refresh() end
  if p.ReflowWheel then p:ReflowWheel() end
end
function M:BuildBookWheel(p)
  local UI=K.UI;self.wheelBookPanel=p;p.settingsNoIndex=true
  local class=call(UnitClass,"player")
  p.caption=UI:CreateDescription(p,(type(class)=="string" and class or "현재 직업").." · 현재 캐릭터의 휠 주문",12,-4);p.caption:SetWidth(286)
  local function editable() return call(InCombatLockdown)~=true end
  p.enabled=UI:CreateCheckbox(p,"프레임 안 휠 시전 사용",12,-34,function() return M:GetCharacterDB().wheelEnabled end,function(v) M:GetCharacterDB().wheelEnabled=v;M:RequestApply() end,editable)
  UI:AttachTooltip(p.enabled,"파티·공격대 프레임 전용","이 모듈이 만든 파티·공격대 프레임에만 적용합니다. 별도의 기본 플레이어·대상 프레임과 일반 휠 단축키에는 적용하지 않습니다. 게임의 마우스를 올려 시전 옵션과 별개입니다.")
  for i,direction in ipairs({"up","down"}) do
    local which=direction;local top=-78-(i-1)*96
    local title=i==1 and "휠 업 · 스킬 끌어 놓기" or "휠 다운 · 스킬 끌어 놓기"
    local button=UI:CreateButton(p,title,12,top,210,function() M:ReceiveWheelSpell(which) end,editable)
    button:SetScript("OnReceiveDrag",function() M:ReceiveWheelSpell(which) end)
    UI:AttachTooltip(button,title,"마법책에서 배운 주문을 이 칸에 끌어 놓으면 해당 등급을 등록합니다.")
    p[direction.."Button"]=button
    p[direction.."Clear"]=UI:CreateButton(p,"해제",230,top,68,function()
      M:SetWheelSpell(which,0);M.wheelBookMessage="해당 방향의 주문을 해제했습니다.";M:RefreshBookWheel()
    end,editable)
    local icon=p:CreateTexture(nil,"ARTWORK");icon:SetSize(24,24);icon:SetPoint("TOPLEFT",12,top-36);p[direction.."Icon"]=icon
    local label=UI:CreateDescription(p,"",44,top-36);label:SetWidth(254);p[direction.."Info"]=label
  end
  p.message=UI:CreateDescription(p,"",12,-274);p.message:SetWidth(286)
  function p:ReflowWheel()
    local top=-4-self.caption:GetStringHeight()-12
    self.enabled:ClearAllPoints();self.enabled:SetPoint("TOPLEFT",12,top);self.enabled.text:SetWidth(252)
    top=top-math.max(34,self.enabled.text:GetStringHeight()+12)-10
    for _,direction in ipairs({"up","down"}) do
      local button,clear=self[direction.."Button"],self[direction.."Clear"]
      button:ClearAllPoints();button:SetPoint("TOPLEFT",12,top)
      clear:ClearAllPoints();clear:SetPoint("TOPLEFT",230,top)
      top=top-math.max(button:GetHeight(),clear:GetHeight())-10
      local icon,label=self[direction.."Icon"],self[direction.."Info"]
      icon:ClearAllPoints();icon:SetPoint("TOPLEFT",12,top)
      label:ClearAllPoints();label:SetPoint("TOPLEFT",44,top);label:SetWidth(254)
      top=top-math.max(24,label:GetStringHeight())-14
    end
    self.message:ClearAllPoints();self.message:SetPoint("TOPLEFT",12,top);self.message:SetWidth(286)
    self:SetHeight(math.max(326,-top+self.message:GetStringHeight()+12))
  end
  self:RefreshBookWheel()
end
