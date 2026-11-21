local _,K=...
local A=K.modules.nativeAlerts
local basic=K.modules.basicUI
local UI,T=K.UI,K.UI.Theme
local appearance=K.NativeAppearance
local call,read,number=K.PublicCall,K.ReadPublicAPI,K.IsPublicNumber
local buttons={{key="NeedButton",id=1,text="입찰"},{key="GreedButton",id=2,text="차비"},{key="PassButton",id=0,text="포기"}}
local textureMethods={"GetNormalTexture","GetPushedTexture","GetDisabledTexture","GetHighlightTexture"}

function A:LootSize(cfg) return 354*cfg.scale/100,80*cfg.scale/100 end

function A:LootSpacing(cfg)
  return math.max(self.spacing and self.spacing.original or 100,92*cfg.scale/100)
end

function A:MakeLootCard(frame)
  local panel=CreateFrame("Frame",nil,frame,"BackdropTemplate")
  panel:SetFrameLevel(math.max(0,frame:GetFrameLevel()-2));panel:EnableMouse(false)
  UI:Surface(panel,.97);panel:Hide()
  local name=frame:CreateFontString(nil,"OVERLAY","GameFontHighlight")
  local kind=frame:CreateFontString(nil,"OVERLAY","GameFontHighlight")
  for _,label in ipairs({name,kind}) do
    label:SetWordWrap(false);label:SetJustifyH("LEFT");label:Hide()
  end
  return {frame=frame,panel=panel,name=name,kind=kind,faces={}}
end

function A:LootButtonFace(card,button,text,scale)
  local face=card.faces[button]
  if not face then
    face=CreateFrame("Frame",nil,button,"BackdropTemplate")
    face:SetAllPoints(button);face:EnableMouse(false)
    UI:Surface(face)
    face.caption=face:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    face.caption:SetPoint("CENTER");face.caption:SetText(text)
    card.faces[button]=face
    button:HookScript("OnEnter",function()
      if face:IsShown() and call(button.IsEnabled,button)==true then face.caption:SetTextColor(unpack(T.Accent)) end
    end)
    button:HookScript("OnLeave",function()
      face.caption:SetTextColor(unpack(call(button.IsEnabled,button)==true and T.TextPrimary or T.Disabled))
    end)
  end
  face.caption:SetFont(UI:Font(),math.max(10,math.floor(T.LabelFontSize*scale+.5)),"")
  face.caption:SetTextColor(unpack(call(button.IsEnabled,button)==true and T.TextPrimary or T.Disabled))
  face:Show()
end

function A:ReleaseLootCard(card)
  card.id,card.itemID,card.requested=nil,nil,nil
  card.name:Hide();card.kind:Hide();card.panel:Hide()
  for _,face in pairs(card.faces) do face:Hide() end
  if not card.records and not next(card.decor or {}) then return end
  for frame in pairs(card.records or {}) do
    if not self:CanEdit(frame) then return end
  end
  for frame in pairs(card.decor or {}) do
    if not self:CanEdit(frame) then return end
  end
  basic:Release(card);appearance:Release(card)
end

local function itemType(id)
  local item=C_Item
  local itemID,kind,sub=call(item and item.GetItemInfoInstant,id)
  if type(sub)=="string" and sub~="" and sub~=kind then return sub,itemID end
  if type(kind)=="string" and kind~="" then return kind,itemID end
  local _,_,_,_,_,class,subclass=call(item and item.GetItemInfo,id)
  return (type(subclass)=="string" and subclass~="" and subclass) or (type(class)=="string" and class or nil),itemID
end

function A:UpdateLootType(card,itemID)
  local currentID=call(function() return card.frame.rollID end)
  if not card.id or currentID~=card.id or call(card.frame.IsShown,card.frame)~=true then return end
  if itemID and card.itemID and itemID~=card.itemID then return end
  local link=call(GetLootRollItemLink,card.id)
  if type(link)~="string" or link=="" then return end
  local id=tonumber(link:match("item:(%d+)"))
  if itemID and id and itemID~=id then return end
  local text,resolvedID=itemType(link)
  card.kind:SetText(text or "—")
  local width=call(card.kind.GetUnboundedStringWidth,card.kind) or card.kind:GetStringWidth()
  card.kind:SetWidth(math.min(108*card.scale,math.ceil(width)+2*card.scale))
  card.itemID=resolvedID or id
  if not text and card.itemID and card.itemID~=card.requested then
    card.requested=card.itemID
    call(C_Item and C_Item.RequestLoadItemDataByID,card.itemID)
  end
end

function A:UpdateLootTypes(itemID)
  for _,card in pairs(self.cards) do self:UpdateLootType(card,itemID) end
end

function A:SkinLootCard(frame,cfg)
  local id=call(function() return frame.rollID end)
  if not number(id) or call(frame.IsShown,frame)~=true or not self:CanEdit(frame) then return false end
  local status,_,name,_,quality,_,_,_,disenchant,_,_,_,_,transmog=read(GetLootRollItemInfo,id)
  local container=call(function() return frame.LootButtonContainer end)
  if status~="ok" or type(name)~="string" or name=="" or not number(quality) or disenchant==true or transmog~=false
    or not container or not frame.IconFrame or not frame.Timer or not frame.NeedRollAnim or not frame.NeedRollAnim.RollNumber then return false end
  local card=self.cards[frame]
  if not card then card=self:MakeLootCard(frame);self.cards[frame]=card end
  if card.id~=id then self:ReleaseLootCard(card) end
  local size=cfg.scale/100
  local w,h=self:LootSize(cfg)
  local icon,timer,anim=frame.IconFrame,frame.Timer,frame.NeedRollAnim
  local ops={}
  local function set(target,key,value) if target then ops[#ops+1]={target,key,value} end end
  local function anchor(target,p,relative,rp,x,y) set(target,"points",{{p,relative,rp,x*size,y*size}}) end
  local function dims(target,width,height) set(target,"width",width*size);set(target,"height",height*size) end
  set(frame,"width",w);set(frame,"height",h)
  for _,element in ipairs({"Background","Border","Name"}) do set(frame[element],"alpha",0) end
  -- Native icon and timer continue receiving their own tooltip and update scripts.
  anchor(icon,"TOPLEFT",frame,"TOPLEFT",12,-12)
  dims(icon,48,48);dims(icon.Icon,48,48);dims(icon.Border,55,55)
  anchor(timer,"BOTTOMLEFT",frame,"BOTTOMLEFT",8,2);dims(timer,338,6)
  anchor(anim,"CENTER",icon,"CENTER",0,0)
  set(container,"points",{{"TOPLEFT",frame,"TOPLEFT",0,0},{"BOTTOMRIGHT",frame,"BOTTOMRIGHT",0,0}})
  local animScale=.40*size
  local font={UI:Font(),cfg.fontSize*size/animScale,"OUTLINE"}
  local faces={}
  for i,spec in ipairs(buttons) do
    local button=container[spec.key]
    if not button or call(button.GetID,button)~=spec.id or not self:CanEdit(button) then return false end
    faces[i]=button
    -- This changes only the real button's geometry and artwork. Its native
    -- ID, mouse scripts, disabled reason and parent used by RollOnLoot stay intact.
    anchor(button,"BOTTOMLEFT",frame,"BOTTOMLEFT",76+(i-1)*90,14);dims(button,82,27)
    for _,method in ipairs(textureMethods) do set(call(button[method],button),"alpha",0) end
  end
  for _,op in ipairs(ops) do
    if not self:CanEdit(op[1]) or not basic:CanRead(op[1],op[2]) then return false end
  end
  if not appearance.Read(anim,"scale") or not appearance.Read(anim.RollNumber,"font") then return false end
  for _,op in ipairs(ops) do
    if not basic:Write(card,unpack(op)) then self:ReleaseLootCard(card);return false end
  end
  if not appearance:Write(card,anim,"scale",animScale) or not appearance:Write(card,anim.RollNumber,"font",font) then
    self:ReleaseLootCard(card);return false
  end
  local r,g,b=call(C_Item and C_Item.GetItemQualityColor,quality)
  if not number(r) or not number(g) or not number(b) then
    local color=ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
    r,g,b=color and color.r or 1,color and color.g or 1,color and color.b or 1
  end
  local labelSize=cfg.fontSize*size
  card.id,card.scale=id,size
  card.panel:ClearAllPoints();card.panel:SetPoint("TOPLEFT",frame,"TOPLEFT");card.panel:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",0,9*size)
  for _,label in ipairs({card.kind,card.name}) do label:SetFont(UI:Font(),labelSize,"OUTLINE");label:SetTextColor(r,g,b);label:ClearAllPoints() end
  card.kind:SetPoint("TOPLEFT",frame,"TOPLEFT",76*size,-11*size)
  card.kind:SetText("—");card.kind:SetWidth(17*size);self:UpdateLootType(card)
  card.name:SetPoint("TOPLEFT",card.kind,"TOPRIGHT",10*size,0)
  card.name:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-10*size,-11*size);card.name:SetText(name)
  card.kind:Show();card.name:Show();card.panel:Show()
  for i,button in ipairs(faces) do self:LootButtonFace(card,button,buttons[i].text,size) end
  return true
end

function A:ApplyLoot(enabled,cfg,container)
  local current=container and call(function() return container.reservedSize end)
  local spacing=self.spacing
  if number(current) and current>0 and (not spacing or spacing.container~=container) then
    spacing={container=container,original=current};self.spacing=spacing
  end
  if spacing and spacing.container==container and number(current) and current>0 and current~=spacing.last then spacing.original=current end
  local target=enabled and self:LootSpacing(cfg) or current
  if spacing and not enabled then target=spacing.original end
  local canUpdate=spacing and self:CanEdit(container) and type(GroupLootContainer_Update)=="function"
  local active=false
  local scaleSafe=enabled and spacing and number(current) and (target<=current or canUpdate)
  for i=1,4 do
    local frame=_G["GroupLootFrame"..i]
    if frame then
      local applied=scaleSafe and self:SkinLootCard(frame,cfg)
      if applied then active=true elseif self.cards[frame] then self:ReleaseLootCard(self.cards[frame]) end
    end
  end
  if canUpdate and number(current) then
    local desired=active and target or spacing.original
    if desired~=current then
      local status=read(function() container.reservedSize=desired;GroupLootContainer_Update(container) end)
      if status=="ok" then spacing.last=desired
      else
        pcall(function() container.reservedSize=current end)
        for _,card in pairs(self.cards) do self:ReleaseLootCard(card) end
      end
    elseif not active then spacing.last=nil end
  end
end

function A:WatchLootCards()
  for i=1,4 do
    local frame=_G["GroupLootFrame"..i]
    if frame and not self.watch[frame] then
      self.watch[frame]=true
      frame:HookScript("OnShow",function() if self:GetDB().roll.enabled then self:Queue() end end)
      frame:HookScript("OnHide",function()
        local card=self.cards[frame]
        if card then self:ReleaseLootCard(card);self:Queue() end
      end)
    end
  end
end
