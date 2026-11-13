local KHQOL=_G.KHQOL
local M=KHQOL.modules.professions
local HUD=KHQOL.HUDText
local positions=KHQOL.PositionUtils

function M:GetDB()
  local modules=KHQOL.db.modules
  modules.professions=KHQOL.MergeDefaults(modules.professions or {},self.defaults,"types")
  return modules.professions
end

local BASIC = { [164]=true, [165]=true, [171]=true, [182]=true, [186]=true, [197]=true, [202]=true, [333]=true, [393]=true }
local SECONDARY = { [129]=true, [185]=true, [356]=true }
local call=KHQOL.PublicCall
local function aidAttributes(info)
  if not KHQOL.IsPublicValue(info) or type(info)~="table" then return end
  local name,rank,maxRank,id,header=call(function() return info.name,info.rank,info.maxRank,info.skillID,info.isHeader end)
  if id~=129 or header~=false or type(name)~="string" or name=="" then return end
  if not KHQOL.IsPublicValue(rank) or type(rank)~="number" or rank~=rank or rank<0 then return end
  if not KHQOL.IsPublicValue(maxRank) or type(maxRank)~="number" or maxRank~=maxRank or maxRank<=0 or maxRank==math.huge then return end
  return {name=name,skill=rank,maxSkill=maxRank}
end
function M:FindFirstAid()
  -- The namespaced API also reads a skill inside a collapsed header without
  -- changing the player's skill-list state. Older clients keep their fallback.
  if C_SkillInfo then
    local aid=aidAttributes(call(C_SkillInfo.GetSkillLineInfoByID,129))
    if aid then return aid end
    local count=call(C_SkillInfo.GetNumSkillLines)
    if type(count)=="number" and count>=0 and count<=1000 and count==math.floor(count) then
      for index=1,count do
        aid=aidAttributes(call(C_SkillInfo.GetSkillLineInfo,index))
        if aid then return aid end
      end
    end
  end
  local count=call(GetNumSkillLines)
  if type(count)=="number" and count>=0 and count<=1000 and count==math.floor(count) then
    for index=1,count do
      local name,header,_,rank,_,_,maxRank=call(GetSkillLineInfo,index)
      if type(name)=="string" and header==false and (name=="응급치료" or name=="응급 치료" or name=="First Aid")
        and type(rank)=="number" and rank>=0 and type(maxRank)=="number" and maxRank>0 then
        return {name=name,skill=rank,maxSkill=maxRank}
      end
    end
  end
end
local FALLBACK_ICONS = {
  [164]="Interface\\Icons\\Trade_BlackSmithing", [165]="Interface\\Icons\\Trade_LeatherWorking",
  [171]="Interface\\Icons\\Trade_Alchemy", [182]="Interface\\Icons\\Trade_Herbalism",
  [185]="Interface\\Icons\\INV_Misc_Food_15", [186]="Interface\\Icons\\Trade_Mining",
  [197]="Interface\\Icons\\Trade_Tailoring", [202]="Interface\\Icons\\Trade_Engineering",
  [333]="Interface\\Icons\\Trade_Engraving", [356]="Interface\\Icons\\Trade_Fishing",
  [393]="Interface\\Icons\\Trade_Skinning", [129]="Interface\\Icons\\Spell_Holy_SealOfSacrifice",
}

local function Font(region, size) region:SetFont(HUD.FONT_PATH, size, "OUTLINE") end
local function MakeCell(parent)
  local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
  HUD.MakeBackdrop(b, .95, .73, .15, .90)
  -- Keep the gold border for the overall panel; individual cells use a quiet
  -- gray divider so several professions do not look like nested buttons.
  b:SetBackdropBorderColor(.28, .28, .28, .90)
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.skill = b:CreateFontString(nil, "OVERLAY"); b.skill:SetPoint("BOTTOM", 0, 3); Font(b.skill, 11)
  b:SetScript("OnEnter", function(self)
    if not self.data then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(self.data.name, 1, .82, .18)
    GameTooltip:AddLine("숙련도: " .. (self.data.skillText or "-"), 1, 1, 1)
    GameTooltip:AddLine("좌클릭: 전문기술 열기", .8, .8, .8); GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  b:SetScript("OnClick", function(self) if self.data then M:OpenProfession(self.data) end end)
  return b
end

function M:ScanProfessions()
  local found, seen = {}, {}
  if type(GetProfessions) == "function" and type(GetProfessionInfo) == "function" then
    local p1, p2, _, fishing, cooking, firstAid = GetProfessions()
    local slots = { {p1,"basic"}, {p2,"basic"}, {cooking,"secondary"}, {fishing,"secondary"}, {firstAid,"secondary"} }
    for _, slot in ipairs(slots) do
      if slot[1] then
        local name, icon, skill, maxSkill, _, _, skillLineID = GetProfessionInfo(slot[1])
        if name and skillLineID and not seen[skillLineID] and ((slot[2] == "basic" and BASIC[skillLineID]) or (slot[2] == "secondary" and SECONDARY[skillLineID])) then
          seen[skillLineID] = true
          found[#found + 1] = { name=name, icon=icon or FALLBACK_ICONS[skillLineID] or "Interface\\Icons\\INV_Misc_QuestionMark", skill=skill, maxSkill=maxSkill, skillLineID=skillLineID, category=slot[2], openMode="C_TradeSkillUI.OpenTradeSkill", openID=skillLineID }
        end
      end
    end
  end
  -- Forever can omit First Aid from GetProfessions().  Its skill line still
  -- appears in the character skill list, so use that list as a safe fallback.
  if not seen[129] then
    local aid=self:FindFirstAid()
    if aid then
      seen[129]=true
      found[#found+1]={name=aid.name,icon=FALLBACK_ICONS[129],skill=aid.skill,maxSkill=aid.maxSkill,
        skillLineID=129,category="secondary",openMode="C_TradeSkillUI.OpenTradeSkill",openID=129}
    end
  end
  local basic, secondary = {}, {}
  for _, data in ipairs(found) do
    data.skillText = (data.skill and data.maxSkill and data.maxSkill > 0) and (data.skill .. "/" .. data.maxSkill) or "-"
    local target = data.category == "basic" and basic or secondary
    if #target < (data.category == "basic" and 2 or 3) then target[#target + 1] = data end
  end
  self.professionData = { basic=basic, secondary=secondary }
  self:RememberProfessionOrder()
  if self.professionsPanel:IsShown() then self:RenderProfessions() end
  if self.settingsPanel and self.settingsPanel:IsVisible() then KHQOL.UI:Refresh(self.settingsPanel) end
end

function M:OpenProfession(data)
  -- Opening is deliberately one-way.  The game's own ESC/X controls close
  -- the native profession window; an extension-panel click never closes it.
  -- This also keeps the protected API call inside the original mouse click.
  if C_TradeSkillUI and type(C_TradeSkillUI.OpenTradeSkill) == "function" then
    local ok = pcall(C_TradeSkillUI.OpenTradeSkill, data.skillLineID)
    if ok then return end
  end
  KHQOL:ProfileMessage((data.name or "전문기술") .. " 창 열기 API를 확인할 수 없습니다.")
end


function M:RememberProfessionOrder()
  local order=self:GetDB().order
  local data=self.professionData
  if not data then return end
  local known={}
  for _,group in ipairs({BASIC,SECONDARY}) do
    for id in pairs(group) do known[id]=true end
  end
  local ordered,seen={},{}
  local function append(id)
    if known[id] and not seen[id] then
      ordered[#ordered+1]=id;seen[id]=true
    end
  end
  -- Preserve the relative order of learned and previously learned skills.
  for _,id in ipairs(order) do append(id) end
  for _,group in ipairs({data.basic,data.secondary}) do
    for _,entry in ipairs(group) do append(entry.skillLineID) end
  end
  self:GetDB().order=ordered
end

function M:OrderedProfessions()
  local data=self.professionData or {basic={},secondary={}}
  local byID,items={},{}
  for _,group in ipairs({data.basic,data.secondary}) do
    for _,entry in ipairs(group) do byID[entry.skillLineID]=entry end
  end
  for _,id in ipairs(self:GetDB().order) do
    if byID[id] then
      items[#items+1]=byID[id]
      byID[id]=nil
    end
  end
  return items,#data.basic,#data.secondary
end

function M:MoveProfession(slot,id)
  local order=self:GetDB().order
  local selected=self:OrderedProfessions()[slot]
  if not selected or selected.skillLineID==id then return end
  local from,to
  for index,saved in ipairs(order) do
    if saved==selected.skillLineID then from=index end
    if saved==id then to=index end
  end
  if from and to then order[from],order[to]=order[to],order[from] end
  self:RenderProfessions()
end

local arrows={left="◀",right="▶",up="▲",down="▼"}
local panelPoints={left={"TOPRIGHT","TOPLEFT",-6,0},right={"TOPLEFT","TOPRIGHT",6,0},
  up={"BOTTOM","TOP",0,6},down={"TOP","BOTTOM",0,-6}}
local opposite={left="right",right="left",up="down",down="up"}
function M:AnchorPanel()
  local button,panel=self.professionsButton,self.professionsPanel
  local direction=self:GetDB().direction
  if not panelPoints[direction] then direction="right" end
  local x,y,w,h=positions.Rect(button)
  local cx,cy,sw,sh=KHQOL.PositionStore:Screen()
  if x and cx then
    local room={
      left=x-w/2-(cx-sw/2),right=cx+sw/2-(x+w/2),
      up=cy+sh/2-(y+h/2),down=y-h/2-(cy-sh/2),
    }
    local size=(direction=="left" or direction=="right") and panel:GetWidth() or panel:GetHeight()
    if room[direction]<size+6 and room[opposite[direction]]>room[direction] then direction=opposite[direction] end
  end
  local point=panelPoints[direction]
  panel:ClearAllPoints()
  panel:SetPoint(point[1],button,point[2],point[3],point[4])
  button.label:SetText("전문기술 "..arrows[direction])
  HUD:SyncStyledText(button.label)
end

function M:RenderProfessions()
  local panel,cfg=self.professionsPanel,self:GetDB()
  local items,basic,secondary=self:OrderedProfessions()
  local size=cfg.iconSize
  local gap=math.max(2,math.min(16,math.floor(cfg.cellGap)))
  local padding,inset=6,4
  local outside=cfg.skillPosition=="outside"
  local cellWidth=size+2*inset
  local textHeight=0
  for _,button in ipairs(panel.cells) do button:Hide();button.data=nil end
  panel:SetBackdropColor(.015,.015,.015,cfg.backgroundAlpha)
  panel:SetBackdropBorderColor(.95,.73,.15,.9*cfg.backgroundAlpha/.92)
  panel.empty:SetShown(#items==0)
  if #items==0 then panel:SetSize(180,48);self:AnchorPanel();return end

  for i,entry in ipairs(items) do
    local cell=panel.cells[i]
    cell.skill:ClearAllPoints()
    if outside then cell.skill:SetPoint("TOP",cell.icon,"BOTTOM",0,-3)
    else cell.skill:SetPoint("BOTTOM",cell.icon,"BOTTOM",0,2) end
    cell.skill:SetText(entry.skillText)
    cell.skill:SetShown(cfg.showSkill)
    HUD:ApplyTextStyle(cell.skill,cfg.skillFontSize,cfg.style)
    if cfg.showSkill then
      cellWidth=math.max(cellWidth,cell.skill:GetUnboundedStringWidth()+2*inset)
      textHeight=math.max(textHeight,cell.skill:GetStringHeight())
    end
  end
  local aboveIcon=not outside and math.max(0,textHeight+2-size) or 0
  local belowIcon=outside and cfg.showSkill and textHeight+3 or 0
  local cellHeight=size+2*inset+aboveIcon+belowIcon
  local cols,rows=0,0
  for i,entry in ipairs(items) do
    local index=i-basic
    local row,col
    -- Keep the previous grid for the initial order. A changed order swaps
    -- entries between the same slots, including primary and secondary slots.
    if cfg.layout=="vertical" then
      row=i<=basic and 1 or ((basic>0 and 1 or 0)+(index==3 and 2 or 1))
      if i<=basic then col=basic==1 and 1.5 or i
      elseif index==3 or secondary==1 then col=1.5
      else col=index end
    else
      row=(i<=basic or basic==0) and 1 or 2
      col=i<=basic and i or index
    end
    cols,rows=math.max(cols,math.ceil(col)),math.max(rows,row)
    local cell=panel.cells[i]
    cell:ClearAllPoints();cell:SetSize(cellWidth,cellHeight)
    cell:SetPoint("TOPLEFT",padding+(col-1)*(cellWidth+gap),-padding-(row-1)*(cellHeight+gap))
    cell:SetBackdropColor(.015,.015,.015,.90*cfg.backgroundAlpha/.92)
    cell:SetBackdropBorderColor(.28,.28,.28,.90*cfg.backgroundAlpha/.92)
    cell.icon:ClearAllPoints();cell.icon:SetPoint("TOP",cell,"TOP",0,-inset-aboveIcon)
    cell.icon:SetSize(size,size);cell.icon:SetTexture(entry.icon)
    cell.data=entry;cell:Show()
  end
  panel:SetSize(cols*cellWidth+(cols-1)*gap+2*padding,rows*cellHeight+(rows-1)*gap+2*padding)
  self:AnchorPanel()
end

function M:ApplySettings()
  local button,panel,cfg=self.professionsButton,self.professionsPanel,self:GetDB()
  HUD:ApplyTextStyle(button.label,cfg.fontSize,cfg.style)
  button.label:SetText("전문기술 ▶")
  button:SetSize(math.max(84,button.label:GetStringWidth()+12),math.max(24,button.label:GetStringHeight()+6))
  positions.ApplyPoint(button,cfg.position)
  self:AnchorPanel()
  button:SetShown(cfg.enabled)
  local alpha=cfg.locked and 0 or .9
  button:SetBackdropColor(.015,.015,.015,alpha);button:SetBackdropBorderColor(.95,.73,.15,alpha)
  if not cfg.enabled then panel:Hide();return end
  if not self.professionData then self:ScanProfessions()
  else self:RememberProfessionOrder() end
  if panel:IsShown() then self:RenderProfessions() end
end

function M:ToggleProfessions()
  local panel=self.professionsPanel
  if not self:GetDB().enabled or KHQOL.PositionEditor.active then return end
  if panel:IsShown() then panel:Hide();return end
  if not self.professionData then self:ScanProfessions() end
  self:RenderProfessions()
  panel:Show()
end

function M:FinishDrag()
  local button=self.professionsButton
  if not button or not button.positionMoving then return end
  button.positionMoving=nil
  button.suppressClick=true
  KHQOL.PositionStore:Point(button,self:GetDB().position)
  KHQOL.PositionStore:Committed(function() self:ApplySettings() end)
end

local panelName="KHQOLProfessionsPanel"
function M:Initialize()
  local button=CreateFrame("Button","KHQOLProfessionsButton",UIParent,"BackdropTemplate")
  HUD.MakeBackdrop(button,.95,.73,.15,.90)
  button.label=button:CreateFontString(nil,"OVERLAY");button.label:SetPoint("CENTER")
  button:SetMovable(true);button:SetClampedToScreen(true);button:EnableMouse(true)
  button:RegisterForClicks("LeftButtonUp");button:RegisterForDrag("LeftButton")
  button:SetScript("OnMouseDown",function(f) f.suppressClick=nil end)
  button:SetScript("OnDragStart",function(f)
    if M:GetDB().locked or KHQOL.PositionEditor.active then return end
    f.positionMoving=true;f:StartMoving()
  end)
  button:SetScript("OnDragStop",function() M:FinishDrag() end)
  button:SetScript("OnClick",function(f) if not f.suppressClick then M:ToggleProfessions() end end)

  local panel=CreateFrame("Frame",panelName,UIParent,"BackdropTemplate")
  panel:SetClampedToScreen(true)
  HUD.MakeBackdrop(panel,.95,.73,.15,.92)
  KHQOL.WindowLayers:RegisterWindow(panel)
  panel.cells={};for i=1,5 do panel.cells[i]=MakeCell(panel) end
  panel.empty=panel:CreateFontString(nil,"OVERLAY");Font(panel.empty,12)
  panel.empty:SetPoint("CENTER");panel.empty:SetText("배운 전문기술이 없습니다.")
  panel:Hide()
  -- Use the native special-window list without replacing any ESC binding.
  if UISpecialFrames then table.insert(UISpecialFrames,panelName) end
  if panel.EnableKeyboard and panel.SetPropagateKeyboardInput then
    panel:EnableKeyboard(true)
    panel:SetPropagateKeyboardInput(true)
    panel:SetScript("OnKeyDown",function(f,key)
      if call(InCombatLockdown)~=false then return end
      -- Let edit boxes keep their own cancel behavior. In combat the native
      -- special-window list handles closing without protected keyboard calls.
      local close=key=="ESCAPE" and not call(GetCurrentKeyBoardFocus)
        and not KHQOL.WindowLayers:ModalShown() and not KHQOL.PositionEditor.active
      f:SetPropagateKeyboardInput(not close)
      if close then
        f:Hide()
        C_Timer.After(0,function()
          if call(InCombatLockdown)==false then f:SetPropagateKeyboardInput(true) end
        end)
      end
    end)
  end
  panel:SetScript("OnHide",function()
    for _,cell in ipairs(panel.cells) do if GameTooltip:IsOwned(cell) then GameTooltip:Hide() end end
  end)
  self.professionsButton,self.professionsPanel=button,panel

  local events=CreateFrame("Frame")
  events:RegisterEvent("SKILL_LINES_CHANGED")
  events:RegisterEvent("PLAYER_ENTERING_WORLD")
  events:RegisterEvent("DISPLAY_SIZE_CHANGED")
  events:RegisterEvent("UI_SCALE_CHANGED")
  events:RegisterEvent("PLAYER_REGEN_ENABLED")
  events:SetScript("OnEvent",function(_,event)
    if event=="PLAYER_REGEN_ENABLED" then
      if panel.SetPropagateKeyboardInput then panel:SetPropagateKeyboardInput(true) end
      return
    end
    if event=="DISPLAY_SIZE_CHANGED" or event=="UI_SCALE_CHANGED" then self:AnchorPanel();return end
    if self.scanQueued then return end
    self.scanQueued=true
    C_Timer.After(.15,function()
      self.scanQueued=nil
      self:ScanProfessions()
    end)
  end)
  self:ApplySettings()
end

function M:PrintProfessionDebug()
  if not self.professionsPanel then return end
  self:ScanProfessions()
  KHQOL:ProfileMessage("전문기술 목록")
  for _,entry in ipairs(self:OrderedProfessions()) do
    KHQOL:ProfileMessage(string.format("%s | %s | ID %d",entry.name,entry.skillText,entry.skillLineID))
  end
end

function M:PositionTargets()
  local list={}
  local cfg=self:GetDB()
  if not cfg.enabled then return list end
  local button,panel=self.professionsButton,self.professionsPanel
  local function apply() self:ApplySettings() end
  positions:Add(list,"professions","professions","전문기술 버튼",button,positions:PointWriter(cfg.position),positions:Lock(cfg),apply)
  positions:ConfigureResets(list,function(target,point)
    point(target,function() return self:GetDB().position end,self.defaults.position)
  end)
  if panel:IsShown() then
    positions:Add(list,"professions.panel","professions","전문기술 목록",panel,nil,nil,apply,{parentID="professions",linked=true})
  end
  return list
end
