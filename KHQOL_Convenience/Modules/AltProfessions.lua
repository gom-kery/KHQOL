local K=_G.KHQOL
local M=K.modules.professions
local UI,H=K.UI,K.UI.Theme
local call=K.PublicCall
local windowName="KHQOLAltProfessionWindow"
-- Keep the detail view dormant until saved character data includes known recipes.
local learnedRecipeDetailsAvailable=false

local function records()
  return K.db and K.db.globalData and K.db.globalData.characterProfessions
end

function M:RecordProfessions(found,complete,aidReady,skillChange)
  local guid,realm,faction=K:GetCharacterRecordIdentity()
  local name=K:GetCharacterRecordName()
  if not K.db or not guid or type(name)~="string" or name=="" then return end
  if self.professionRecordGUID~=guid then
    self.professionRecordGUID=guid
    self.pendingProfessionRemovals={}
  end
  K.db.globalData=K.db.globalData or {}
  local global=K.db.globalData
  if type(global.characterProfessions)~="table" then global.characterProfessions={} end
  local old=global.characterProfessions[guid]
  local skills,pending={},self.pendingProfessionRemovals
  for _,entry in ipairs(found) do
    skills[entry.skillLineID]={name=entry.name,skill=entry.skill,maxSkill=entry.maxSkill}
    pending[entry.skillLineID]=nil
  end
  local needsVerify=false
  for id,entry in pairs(old and old.skills or {}) do
    if not skills[id] then
      -- A transient empty login read does not confirm unlearning. Two
      -- complete reads after the skill update are required to remove a row.
      if complete and (id~=129 or aidReady) and skillChange then
        if pending[id] then pending[id]=nil
        else pending[id]=true;skills[id]=entry;needsVerify=true end
      else
        pending[id]=nil;skills[id]=entry
      end
    end
  end
  local _,class=call(UnitClass,"player")
  global.characterProfessions[guid]={realm=realm,faction=faction,name=name,skills=skills,class=class or old and old.class}
  if self.altProfessionWindow and self.altProfessionWindow:IsShown() then self:RenderAltProfessionWindow() end
  return needsVerify
end

function M:GetAltProfessionRows()
  local guid,realm,faction=K:GetCharacterRecordIdentity()
  local rows={}
  if not guid then return rows end
  local showSecondary=self:GetDB().showAltSecondaryProfessions
  local money=K.db.globalData and K.db.globalData.characterMoney
  for id,character in pairs(records() or {}) do
    if id~=guid and type(character)=="table" and character.realm==realm and character.faction==faction
      and type(character.name)=="string" and type(character.skills)=="table" then
      local class=character.class or money and money[id] and money[id].class
      for skillID,skill in pairs(character.skills) do
        if (showSecondary or not self:IsSecondaryProfession(skillID))
          and type(skill)=="table" and type(skill.name)=="string" and K.IsPublicNumber(skill.skill)
          and K.IsPublicNumber(skill.maxSkill) then
          rows[#rows+1]={name=character.name,profession=skill.name,skill=skill.skill.."/"..skill.maxSkill,
            rank=skill.skill,skillID=skillID,guid=id,class=class}
        end
      end
    end
  end
  table.sort(rows,function(a,b)
    if a.name~=b.name then return a.name<b.name end
    return a.profession<b.profession
  end)
  return rows
end

function M:CreateAltProfessionButton(panel)
  local button=CreateFrame("Button",nil,panel,"BackdropTemplate")
  K.HUDText.MakeBackdrop(button,.28,.28,.28,.90)
  button.icon=button:CreateTexture(nil,"ARTWORK")
  button.icon:SetPoint("CENTER")
  button.icon:SetTexture("Interface\\Icons\\Trade_Engineering")
  button:RegisterForClicks("LeftButtonUp")
  button:SetScript("OnClick",function()
    local cfg=M:GetDB()
    if not cfg.enabled or not cfg.showAltProfessions or K.PositionEditor.active then return end
    M:CreateAltProfessionWindow()
    M:RenderAltProfessionWindow()
    M.altProfessionWindow:Show()
    M.altProfessionWindow:Raise()
  end)
  button:SetScript("OnEnter",function(frame)
    GameTooltip:SetOwner(frame,"ANCHOR_RIGHT")
    GameTooltip:SetText("전문기술 목록")
    GameTooltip:AddLine("같은 서버·진영의 마지막 기록",.8,.8,.8)
    GameTooltip:Show()
  end)
  local function hide(frame) if GameTooltip:IsOwned(frame) then GameTooltip:Hide() end end
  button:SetScript("OnLeave",hide);button:SetScript("OnHide",hide)
  button:Hide()
  return button
end

local rowHeight,maxRows,contentWidth=26,9,440
local headers={"캐릭터명","전문기술","숙련"}
local detailHeaders={"도안·기술","필요 숙련","숙련 조건"}
local summaryWidths={176,156,82}
local detailWidths={250,74,90}
local function columns(parent,y,widths,labels)
  local result,x={},7
  for i,width in ipairs(widths) do
    local text=UI:CreateLabel(parent,labels and labels[i] or "",x,y,H.LabelFontSize)
    text:SetWidth(width);text:SetWordWrap(false);text:SetMaxLines(1)
    if labels then text:SetTextColor(unpack(H.FocusAccent)) end
    result[i]=text
    x=x+width+6
  end
  return result
end

local function layoutColumns(labels,widths,parent)
  local x=7
  for i,label in ipairs(labels) do
    label:ClearAllPoints()
    label:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-6)
    label:SetWidth(widths[i])
    x=x+widths[i]+6
  end
end

function M:OpenAltProfessionDetail(entry)
  local frame=self.altProfessionWindow
  if not learnedRecipeDetailsAvailable or not entry then return end
  frame.selected=entry
  frame.summaryOffset=frame.scroll:GetVerticalScroll()
  self:RenderAltProfessionWindow(0)
end

function M:CreateAltProfessionWindow()
  if self.altProfessionWindow then return end
  local frame=CreateFrame("Frame",windowName,UIParent,"BackdropTemplate")
  self.altProfessionWindow=frame
  frame:SetSize(contentWidth+24,132);frame:SetPoint("CENTER");frame:SetClampedToScreen(true);frame:SetToplevel(true)
  frame:EnableMouse(true);frame:SetMovable(true);frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart",function(f) f:StartMoving() end)
  frame:SetScript("OnDragStop",function(f) f:StopMovingOrSizing() end)
  UI:Surface(frame);K.WindowLayers:RegisterWindow(frame)
  UI:CreateLabel(frame,"전문기술 목록",12,-13,H.SectionFontSize)
  frame.close=UI:CreateButton(frame,"닫기",0,0,60,function() frame:Hide() end)
  frame.back=UI:CreateButton(frame,"목록",0,0,60,function()
    frame.selected=nil
    M:RenderAltProfessionWindow(frame.summaryOffset or 0)
  end)
  frame.close:ClearAllPoints();frame.close:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-12,-8)
  frame.back:ClearAllPoints();frame.back:SetPoint("RIGHT",frame.close,"LEFT",-6,0)
  frame.subtitle=UI:CreateDescription(frame,"",12,-43)
  frame.subtitle:SetWidth(contentWidth)
  local header=CreateFrame("Frame",nil,frame,"BackdropTemplate")
  UI:Surface(header);header:SetSize(contentWidth,27)
  frame.header=header
  frame.headers=columns(header,-6,summaryWidths,headers)

  local scroll=CreateFrame("ScrollFrame",nil,frame)
  scroll:SetPoint("TOPLEFT",header,"BOTTOMLEFT",0,-2);scroll:SetSize(contentWidth,1)
  local body=CreateFrame("Frame",nil,scroll)
  body:SetSize(contentWidth,1);scroll:SetScrollChild(body)
  local slider=CreateFrame("Slider",nil,frame)
  slider:SetPoint("TOPLEFT",scroll,"TOPRIGHT",5,0);slider:SetSize(9,1)
  slider:SetOrientation("VERTICAL");slider:SetMinMaxValues(0,0);slider:SetValueStep(1)
  local track=slider:CreateTexture(nil,"BACKGROUND");track:SetAllPoints();track:SetColorTexture(unpack(H.SliderTrack))
  local thumb=slider:CreateTexture(nil,"OVERLAY");thumb:SetSize(10,28);thumb:SetColorTexture(unpack(H.FocusAccent))
  slider:SetThumbTexture(thumb)
  slider:SetScript("OnValueChanged",function(_,value)
    scroll:SetVerticalScroll(value)
    M:PaintAltProfessionRows()
  end)
  scroll:EnableMouseWheel(true)
  scroll:SetScript("OnMouseWheel",function(_,delta)
    slider:SetValue(math.max(0,math.min(frame.maxScroll or 0,scroll:GetVerticalScroll()-delta*rowHeight*2)))
  end)
  frame.scroll,frame.body,frame.slider,frame.rows=scroll,body,slider,{}
  frame.empty=UI:CreateDescription(frame,"",0,0)
  frame.empty:ClearAllPoints();frame.empty:SetPoint("TOPLEFT",header,"BOTTOMLEFT",7,-8)
  frame.empty:SetWidth(contentWidth-14)
  frame.requested={}
  frame:SetScript("OnEvent",function(_,event,spell)
    if event~="SPELL_DATA_LOAD_RESULT" or not frame.selected or not frame.requested[spell] or frame.paintQueued then return end
    frame.paintQueued=true
    C_Timer.After(0,function()
      frame.paintQueued=nil
      if frame:IsShown() and frame.selected then M:PaintAltProfessionRows() end
    end)
  end)
  frame:SetScript("OnHide",function()
    frame:UnregisterEvent("SPELL_DATA_LOAD_RESULT")
    frame.selected=nil
  end)
  if UISpecialFrames then table.insert(UISpecialFrames,windowName) end
  frame:Hide()
end

function M:RenderAltProfessionWindow(offset)
  local frame=self.altProfessionWindow
  local rows=self:GetAltProfessionRows()
  if frame.selected then
    local previous=frame.selected
    frame.selected=nil
    for _,row in ipairs(rows) do
      if row.guid==previous.guid and row.skillID==previous.skillID then frame.selected=row;break end
    end
  end
  local selected=frame.selected
  if selected then rows=self.recipeCatalog[selected.skillID] or {} end
  local hasRows=#rows>0
  local overflow=#rows>maxRows
  local listHeight=math.min(#rows,maxRows)*rowHeight
  if not hasRows then listHeight=34 end
  local top=selected and 78 or 45
  frame:SetSize(contentWidth+24+(overflow and 14 or 0),top+27+2+listHeight+10)
  frame.header:ClearAllPoints();frame.header:SetPoint("TOPLEFT",12,-top)
  frame.back:SetShown(selected~=nil)
  frame.subtitle:SetShown(selected~=nil)
  if selected then
    frame.subtitle:SetText(selected.name.." · "..selected.profession.." · "..selected.skill.."\n저장된 숙련도 기준 · 습득 여부 미확인")
    frame:RegisterEvent("SPELL_DATA_LOAD_RESULT")
  else frame:UnregisterEvent("SPELL_DATA_LOAD_RESULT") end
  local widths=selected and detailWidths or summaryWidths
  layoutColumns(frame.headers,widths,frame.header)
  for i,text in ipairs(frame.headers) do text:SetText((selected and detailHeaders or headers)[i]) end
  frame.displayRows=rows
  frame.body:SetHeight(math.max(1,#rows*rowHeight))
  frame.scroll:SetHeight(listHeight)
  frame.slider:SetHeight(listHeight)
  frame.maxScroll=math.max(0,#rows*rowHeight-listHeight)
  frame.slider:SetMinMaxValues(0,frame.maxScroll);frame.slider:SetShown(overflow)
  offset=math.max(0,math.min(offset or frame.scroll:GetVerticalScroll(),frame.maxScroll))
  frame.slider:SetValue(offset);frame.scroll:SetVerticalScroll(offset)
  frame.empty:SetText(selected and "이 전문기술의 도안·기술 자료가 없습니다." or "부캐로 한 번 접속하면 전문기술이 표시됩니다.")
  frame.empty:SetShown(not hasRows)
  self:PaintAltProfessionRows()
end

function M:PaintAltProfessionRows()
  local frame=self.altProfessionWindow
  local rows=frame.displayRows or {}
  local selected=frame.selected
  local widths=selected and detailWidths or summaryWidths
  local first=math.floor(frame.scroll:GetVerticalScroll()/rowHeight)+1
  local count=math.max(0,math.min(maxRows+1,#rows-first+1))
  for i=1,count do
    local index=first+i-1
    local entry=rows[index]
    local row=frame.rows[i]
    if not row then
      row=CreateFrame("Frame",nil,frame.body)
      row:SetSize(contentWidth,rowHeight)
      row.fill=row:CreateTexture(nil,"BACKGROUND");row.fill:SetAllPoints()
      row.columns=columns(row,-6,summaryWidths)
      row.open=CreateFrame("Button",nil,row)
      row.open:SetPoint("TOPLEFT",row,"TOPLEFT",summaryWidths[1]+10,0)
      row.open:SetPoint("BOTTOMRIGHT")
      row.open:RegisterForClicks("LeftButtonUp")
      local highlight=row.open:CreateTexture(nil,"HIGHLIGHT")
      highlight:SetAllPoints();highlight:SetColorTexture(1,1,1,.12)
      row.open:SetScript("OnClick",function() M:OpenAltProfessionDetail(row.entry) end)
      frame.rows[i]=row
    end
    row:ClearAllPoints();row:SetPoint("TOPLEFT",frame.body,"TOPLEFT",0,-(index-1)*rowHeight)
    row.fill:SetColorTexture(1,1,1,index%2==0 and .06 or .025)
    layoutColumns(row.columns,widths,row)
    row.entry=entry
    row.open:SetShown(learnedRecipeDetailsAvailable and selected==nil)
    if selected then
      local spell,required=entry[1],entry[2]
      local name=call(C_Spell and C_Spell.GetSpellName,spell)
      if not name and not frame.requested[spell] then
        frame.requested[spell]=true
        call(C_Spell and C_Spell.RequestLoadSpellData,spell)
      end
      row.columns[1]:SetText(name or ("주문 #"..spell))
      row.columns[1]:SetTextColor(unpack(H.TextPrimary))
      row.columns[2]:SetText(tostring(required));row.columns[2]:SetTextColor(unpack(H.TextPrimary))
      local meets=selected.rank>=required
      row.columns[3]:SetText(meets and "충족" or "부족")
      row.columns[3]:SetTextColor(unpack(meets and H.FocusAccent or H.TextSecondary))
    else
      row.columns[1]:SetText(entry.name);row.columns[2]:SetText(entry.profession);row.columns[3]:SetText(entry.skill)
      local classColor=RAID_CLASS_COLORS and RAID_CLASS_COLORS[entry.class]
      if classColor then row.columns[1]:SetTextColor(classColor.r,classColor.g,classColor.b)
      else row.columns[1]:SetTextColor(unpack(H.TextPrimary)) end
      local color=learnedRecipeDetailsAvailable and H.FocusAccent or H.TextPrimary
      row.columns[2]:SetTextColor(unpack(color));row.columns[3]:SetTextColor(unpack(color))
    end
    row:Show()
  end
  for i=count+1,#frame.rows do frame.rows[i]:Hide() end
end
