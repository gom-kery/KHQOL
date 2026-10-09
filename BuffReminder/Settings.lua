local _, KHQOL = ...
local FBR, UI = _G.ForeverBuffReminder, KHQOL.UI
local T = UI.Theme
local function moveBuff(buffs,fromIndex,toIndex)
  if toIndex<1 or toIndex>#buffs then return end
  buffs[fromIndex],buffs[toIndex]=buffs[toIndex],buffs[fromIndex]
end
function FBR:CreateSettingsUI(parent)
  if self.settings then return self.settings end
  if not parent then
    KHQOL:ShowSettings("buffReminder")
    return self.settings
  end
  -- Use the owning tab itself, including dynamic list rows and Shaman options.
  local panel=parent
  panel:SetWidth(T.ContentWidth); self.settings=panel
  _G.ForeverBuffReminderSettings=panel
  local b=UI:CreateBuilder(panel)
  b:Section("위치")
  b:Checkbox("위치 잠금",function() return ForeverBuffReminderDB.locked end,function(value) FBR:SetLocked(value) end)
  b:Section("알림 모양")
  panel.directionNames={RIGHT="오른쪽",LEFT="왼쪽",UP="위로",DOWN="아래로"}
  local directions={}
  for _,direction in ipairs({"RIGHT","LEFT","UP","DOWN"}) do directions[#directions+1]={value=direction,text=panel.directionNames[direction]} end
  panel.directionDropdown=b:Dropdown("정렬 방향",directions,function() return ForeverBuffReminderDB.layoutDirection end,function(value)
    ForeverBuffReminderDB.layoutDirection=value; FBR:RefreshSettings(); FBR:RefreshAlerts()
  end)
  panel.slider=b:Slider("아이콘 크기",60,100,1,function() return ForeverBuffReminderDB.iconSize end,function(value)
    ForeverBuffReminderDB.iconSize=value; FBR:RefreshAlerts()
  end,function(value) return value.." px" end)
  b:Section("버프 설정")
  local classes={}
  for _,token in ipairs(self.CLASS_TOKENS) do classes[#classes+1]={value=token,text=self.CLASS_NAMES[token]} end
  panel.dropdown=b:Dropdown("직업 선택",classes,function() return ForeverBuffReminderDB.selectedClass end,function(token)
    ForeverBuffReminderDB.selectedClass=token; FBR:RefreshSettings()
  end)
  b:Section("버프 등록")
  b:Description("Spell ID 또는 기존에 지원하는 주문 이름을 입력합니다. Spell ID를 권장합니다.")
  panel.input=UI:CreateEditBox(panel,0,b.y,360)
  local add=UI:CreateButton(panel,"버프 추가",376,b.y,110,function() FBR:AddBuffFromInput() end)
  panel.input:SetScript("OnEnterPressed",function(box) FBR:AddBuffFromInput(); box:ClearFocus() end)
  panel.addError=UI:CreateLabel(panel,"",0,b.y-34,T.DescriptionFontSize)
  panel.addError:SetTextColor(unpack(T.Warning)); panel.addError:Hide()
  b.y=b.y-62
  function FBR:SetAddError(message)
    panel.addError:SetText(message or ""); panel.addError:SetShown(message and message~="")
  end
  function FBR:AddBuffFromInput()
    if KHQOL.db and not KHQOL:GetEnabled("buffReminder") then return end
    local item,err=FBR:ResolveSpellInput(panel.input:GetText())
    if not item then FBR:SetAddError(err); return end
    local buffs=FBR:GetSelectedClassData().buffs
    for _,saved in ipairs(buffs) do if saved.spellID==item.spellID then FBR:SetAddError("이미 등록된 Spell ID입니다."); return end end
    buffs[#buffs+1]={spellID=item.spellID,enabled=true,displayMode="ALWAYS"}
    panel.input:SetText(""); FBR:SetAddError(nil); FBR:RefreshSettings(); FBR:RefreshAlerts()
  end
  b:Section("등록한 버프")
  panel.listTop=b.y; panel.rows={}
  for i=1,11 do
    local index=i
    local row=CreateFrame("Frame",nil,panel); row:SetSize(T.ContentWidth,T.RowHeight)
    row:SetPoint("TOPLEFT",0,panel.listTop-(i-1)*(T.RowHeight+T.RowGap))
    row.down=UI:CreateButton(row,"▼",0,0,28,function()
      moveBuff(FBR:GetSelectedClassData().buffs,index,index+1); FBR:RefreshSettings(); FBR:RefreshAlerts()
    end,function() return index<#FBR:GetSelectedClassData().buffs end)
    row.up=UI:CreateButton(row,"▲",32,0,28,function()
      moveBuff(FBR:GetSelectedClassData().buffs,index,index-1); FBR:RefreshSettings(); FBR:RefreshAlerts()
    end,function() return index>1 end)
    row.check=UI:CreateCheckbox(row,"",68,0,function() return row.buff and row.buff.enabled end,function(v)
      if row.buff then row.buff.enabled=v; FBR:RefreshAlerts() end
    end)
    row.icon=row:CreateTexture(nil,"ARTWORK"); row.icon:SetSize(20,20); row.icon:SetPoint("TOPLEFT",100,-3)
    row.name=UI:CreateLabel(row,"",128,-6); row.name:SetWidth(210); row.name:SetWordWrap(false)
    row:EnableMouse(true)
    row:SetScript("OnEnter",function(self)
      if not self.buff then return end
      local name=FBR:GetSpellDetails(self.buff.spellID)
      GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText(name or "확인 불가 주문")
      GameTooltip:AddLine("Spell ID: "..self.buff.spellID,1,1,1); GameTooltip:Show()
    end)
    row:SetScript("OnLeave",function() GameTooltip:Hide() end)
    UI:AttachTooltip(row.check,"버프 알림","체크하면 이 버프가 없거나 만료되기 전에 알립니다.")
    row.mode=UI:CreateDropdown(row,352,0,136,{{value="ALWAYS",text="항상"},{value="COMBAT",text="전투 중"}},function() return row.buff and row.buff.displayMode or "ALWAYS" end,function(v)
      if row.buff then row.buff.displayMode=v; FBR:RefreshSettings(); FBR:RefreshAlerts() end
    end)
    row.delete=UI:CreateButton(row,"삭제",496,0,100,function()
      table.remove(FBR:GetSelectedClassData().buffs,index); FBR:RefreshSettings(); FBR:RefreshAlerts()
    end)
    row:Hide(); panel.rows[i]=row
  end
  local special=CreateFrame("Frame",nil,panel); special:SetSize(T.ContentWidth,138); panel.shamanSpecial=special
  local sb=UI:CreateBuilder(special); sb:Section("주술사 무기 / 토템"); special.buttons={}
  for i,definition in ipairs({
    {group="weapon",key="mainHand",label="주무기"},{group="weapon",key="offHand",label="보조무기"},
    {group="totems",key="EARTH",label="대지"},{group="totems",key="FIRE",label="불"},
    {group="totems",key="WATER",label="물"},{group="totems",key="AIR",label="바람"},
  }) do
    local entry=definition
    local control=UI:CreateButton(special,entry.label,(i-1)*98,sb.y,90,function(self,mouseButton)
      if entry.group=="totems" and mouseButton=="RightButton" then FBR:OpenTotemSelectionMenu(entry.key,self); return end
      local setting=FBR:GetShamanSpecialSettings()[entry.group][entry.key]
      setting.enabled=not setting.enabled; FBR:RefreshSettings(); FBR:RefreshAlerts()
    end)
    control:RegisterForClicks("LeftButtonUp","RightButtonUp"); control.entry=entry
    local refresh=control.Refresh
    control.Refresh=function()
      refresh()
      UI:SetButtonSelected(control,FBR:GetShamanSpecialSettings()[entry.group][entry.key].enabled)
    end
    special.buttons[#special.buttons+1]=control
  end
  UI:CreateDescription(special,"토템 버튼을 우클릭하면 기존 주문 선택 메뉴를 엽니다.",0,sb.y-40)
  local menu
  menu=UI:CreateDropdown(panel,0,0,300,function()
    local key=menu and menu.totemKey
    local choices,order,options={},{},{}
    for _,spellID in ipairs(FBR.SHAMAN_TOTEM_SPELLS[key] or {}) do
      if FBR:IsKnownSpell(spellID) then
        local name,icon=FBR:GetSpellDetails(spellID)
        if name then
          if not choices[name] then order[#order+1]=name end
          choices[name]={spellID=spellID,icon=icon}
        end
      end
    end
    for _,name in ipairs(order) do
      local choice=choices[name]
      options[#options+1]={value=choice.spellID,text=name.." ("..choice.spellID..")",icon=choice.icon}
    end
    if #options==0 then options[1]={text="습득한 토템 주문이 없습니다.",disabled=true} end
    return options
  end,function()
    local key=menu and menu.totemKey
    return key and FBR:GetShamanSpecialSettings().totems[key].spellID
  end,function(id)
    local setting=FBR:GetShamanSpecialSettings().totems[menu.totemKey]
    setting.spellID=id; setting.enabled=true; FBR:RefreshSettings(); FBR:RefreshAlerts()
  end)
  menu:Hide(); panel.totemMenu=menu
  self:RefreshSettings()
  return panel
end
function FBR:OpenTotemSelectionMenu(key,anchor)
  local menu=self.settings.totemMenu; menu.totemKey=key
  menu:ClearAllPoints(); menu:SetPoint("TOPLEFT",anchor,"BOTTOMLEFT",0,0)
  menu:GetScript("OnClick")(menu)
end
function FBR:RefreshSettings()
  if not self.settings then return end
  local panel=self.settings
  local token=ForeverBuffReminderDB.selectedClass or self:GetCurrentClass() or self.CLASS_TOKENS[1]
  ForeverBuffReminderDB.selectedClass=token
  ForeverBuffReminderDB.layoutDirection=ForeverBuffReminderDB.layoutDirection or "RIGHT"
  local buffs=self:GetSelectedClassData().buffs
  for i,row in ipairs(panel.rows) do
    row.buff=buffs[i]
    if row.buff then
      local buff=row.buff; local name,icon=self:GetSpellDetails(buff.spellID)
      row.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
      row.name:SetText((name or "확인 불가 주문").."  |cff999999("..buff.spellID..")|r")
      buff.displayMode=buff.displayMode or "ALWAYS"; row:Show()
    else row:Hide() end
  end
  local listBottom=panel.listTop-math.min(#buffs,#panel.rows)*(T.RowHeight+T.RowGap)
  local showSpecial=token=="SHAMAN" or self:GetCurrentClass()=="SHAMAN"
  panel.shamanSpecial:ClearAllPoints(); panel.shamanSpecial:SetPoint("TOPLEFT",0,listBottom)
  panel.shamanSpecial:SetShown(showSpecial)
  panel:SetHeight(-listBottom+(showSpecial and panel.shamanSpecial:GetHeight() or T.ContentPadding))
  UI:Refresh(panel)
end
function FBR:ToggleSettings()
  ForeverBuffReminderDB.selectedClass=self:GetCurrentClass() or self.CLASS_TOKENS[1]
  KHQOL:ShowSettings("buffReminder")
end
