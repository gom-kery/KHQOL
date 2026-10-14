local _, KHQOL = ...
local M=KHQOL.modules.generalConvenience
local call,public=KHQOL.PublicCall,KHQOL.IsPublicValue
local function sameWidth(a,b)
  return M.IsNumber(a) and M.IsNumber(b) and math.abs(a-b)<=.01
end
local function points(frame)
  local result={}; for i=1,frame:GetNumPoints() do result[i]={frame:GetPoint(i)} end; return result
end
local function same(a,b)
  if #a~=#b then return false end
  for i=1,#a do for j=1,5 do if a[i][j]~=b[i][j] then return false end end end
  return true
end
local function setpoints(frame,list)
  frame:ClearAllPoints(); for _,p in ipairs(list) do frame:SetPoint(unpack(p)) end
end
local function merchantOpen() return MerchantFrame and call(MerchantFrame.IsShown,MerchantFrame)==true end
local conflicts={"Leatrix_Plus","Leatrix_Plus_Forever","WideMerchant","ExtendedVendorUI","BuyEmAll","ElvUI"}
function M:MerchantBorderSource()
  local border=MerchantFrameBottomLeftBorder;if not border then return end
  local width,height=call(border.GetWidth,border),call(border.GetHeight,border)
  local alpha=call(border.GetAlpha,border)
  if not self.IsNumber(width) or width<60 or not self.IsNumber(height) or height<=0 or not self.IsNumber(alpha) or alpha>1 then return end
  local status,atlas=KHQOL.ReadPublicAPI(border.GetAtlas,border)
  if status=="unreadable" or status=="error" then return end
  local texture,coords
  if atlas~=nil then
    if type(atlas)~="string" or atlas=="" then return end
    -- GetTexCoord() may be local to an atlas. SetTexture() needs the packed
    -- file's coordinates, otherwise other atlas elements become visible.
    local info=call(C_Texture and C_Texture.GetAtlasInfo or GetAtlasInfo,atlas)
    if type(info)~="table" then return end
    local file,filename,left,right,top,bottom=call(function()
      return info.file,info.filename,info.leftTexCoord,info.rightTexCoord,info.topTexCoord,info.bottomTexCoord
    end)
    texture=file or filename
    coords={left,top,left,bottom,right,top,right,bottom}
  else
    texture=call(border.GetTexture,border);coords={call(border.GetTexCoord,border)}
  end
  if type(texture)~="string" and not (self.IsNumber(texture) and texture>0) then return end
  if texture=="" or #coords~=8 then return end
  for i=1,8 do local v=coords[i];if not self.IsNumber(v) or v>1 then return end end
  return {texture=texture,coords=coords,width=width,height=height,alpha=alpha}
end
function M:MerchantSupported()
  if not MerchantFrame or not MerchantItem12 or type(MerchantFrame_Update)~="function" then return false,"상점 UI가 아직 로드되지 않았습니다." end
  for _,name in ipairs(conflicts) do
    if C_AddOns and call(C_AddOns.IsAddOnLoaded,name)==true then return false,name.."와 상점 영역이 겹칩니다." end
  end
  local width=call(MerchantFrame.GetWidth,MerchantFrame)
  if not M.IsNumber(width) then return false,"상점 폭 정보를 확인할 수 없습니다." end
  if self.merchantOwner and self.merchantOwner.lastWidth and not sameWidth(width,self.merchantOwner.lastWidth) then
    return false,"상점 폭 "..tostring(MerchantFrame:GetWidth()).." (KHQOL 적용값 "..tostring(self.merchantOwner.lastWidth).."). 변경 주체를 확인할 수 없습니다."
  end
  if not self.merchantOwner and not sameWidth(width,336) then return false,"상점 폭 "..tostring(width).." (기본 336). 변경 주체를 확인할 수 없습니다." end
  if self.merchantOwner and MerchantFrame.selectedTab==1 then
    for i,p in pairs(self.merchantOwner.lastSlots or {}) do
      if not same(points(_G["MerchantItem"..i]),p) then return false,"상점 슬롯 MerchantItem"..i.."의 위치가 변경되었습니다. 변경 주체를 확인할 수 없습니다." end
    end
  end

  if MERCHANT_ITEMS_PER_PAGE~=10 and not self.merchantOwner then return false,"상점 페이지 크기 "..tostring(MERCHANT_ITEMS_PER_PAGE).." (기본 10). 변경 주체를 확인할 수 없습니다." end
  for i=13,20 do
    local frame=_G["MerchantItem"..i]
    if frame and frame~= (self.extraMerchantItems and self.extraMerchantItems[i]) then return false,"다른 애드온의 확장 상점 슬롯을 감지했습니다." end
  end
  if MerchantFrameBottomLeftBorder and not self:MerchantBorderSource() then return false,"상점 하단 장식의 원본 이미지 정보를 확인할 수 없습니다." end
  return true
end
function M:CreateMerchantExtras()
  self.extraMerchantItems=self.extraMerchantItems or {}
  for i=13,20 do
    if not self.extraMerchantItems[i] then
      local frame=CreateFrame("Frame","MerchantItem"..i,MerchantFrame,"MerchantItemTemplate")
      self.extraMerchantItems[i]=frame; frame:Hide()
    end
  end
end
function M:MerchantLayout(expanded)
  if not MerchantFrame then return end
  if expanded then
    local source=MerchantFrameBottomLeftBorder and self:MerchantBorderSource()
    if MerchantFrameBottomLeftBorder and not source then return end
    local owner=self.merchantOwner
    if not owner then
      owner={width=MerchantFrame:GetWidth(),slots={}}; self.merchantOwner=owner
      for i=11,12 do owner.slots[i]=points(_G["MerchantItem"..i]) end
      if source then owner.borderAlpha=source.alpha end
    end
    self:CreateMerchantExtras()
    -- ButtonFrameTemplate's NineSlice adjusts edges without scaling corners.
    MerchantFrame:SetWidth(owner.width+330); owner.lastWidth=MerchantFrame:GetWidth()
    for i=11,20 do
      local n=i-11; local frame=_G["MerchantItem"..i]
      frame:ClearAllPoints(); frame:SetPoint("TOPLEFT",MerchantItem1,"TOPLEFT",330+(n%2)*165,-math.floor(n/2)*52)
      if i<=12 then owner.lastSlots=owner.lastSlots or {}; owner.lastSlots[i]=points(frame) end
      frame:Show()
    end
    if source then
      MerchantFrameBottomLeftBorder:SetAlpha(0)
      self.merchantBottomSlices=self.merchantBottomSlices or {}
      local ulx,uly,llx,lly,urx,ury,lrx,lry=unpack(source.coords)
      local body=source.width-30
      -- Preserve the complete button area. Only a one-pixel empty strip near
      -- its right edge is extended; the original right cap keeps its size.
      local ranges={{0,body/source.width},{(body-1)/source.width,body/source.width},{body/source.width,1}}
      local widths={body,330,30}
      for i,range in ipairs(ranges) do
        local t=self.merchantBottomSlices[i] or MerchantFrame:CreateTexture(nil,"OVERLAY")
        self.merchantBottomSlices[i]=t
        local a,b=range[1],range[2]
        t:SetTexture(source.texture)
        t:SetTexCoord(ulx+(urx-ulx)*a,uly+(ury-uly)*a,
          llx+(lrx-llx)*a,lly+(lry-lly)*a,
          ulx+(urx-ulx)*b,uly+(ury-uly)*b,
          llx+(lrx-llx)*b,lly+(lry-lly)*b)
        t:ClearAllPoints();t:SetSize(widths[i],source.height)
        if i==1 then t:SetPoint("TOPLEFT",MerchantFrameBottomLeftBorder,"TOPLEFT",0,0)
        else t:SetPoint("TOPLEFT",self.merchantBottomSlices[i-1],"TOPRIGHT",0,0) end
        t:Show()
      end
    end
  else
    local owner=self.merchantOwner
    if owner then
      if sameWidth(call(MerchantFrame.GetWidth,MerchantFrame),owner.lastWidth) then MerchantFrame:SetWidth(owner.width) end
      for i=11,12 do
        local frame=_G["MerchantItem"..i]
        if owner.lastSlots and same(points(frame),owner.lastSlots[i]) then setpoints(frame,owner.slots[i]) end
      end
      if MerchantFrameBottomLeftBorder and MerchantFrameBottomLeftBorder:GetAlpha()==0 then MerchantFrameBottomLeftBorder:SetAlpha(owner.borderAlpha or 1) end
      self.merchantOwner=nil
    end
    for _,frame in pairs(self.extraMerchantItems or {}) do frame:Hide() end
    for _,t in ipairs(self.merchantBottomSlices or {}) do t:Hide() end
  end
end
function M:ClearEmptyMerchantSlots()
  if not MerchantFrame or MerchantFrame.selectedTab~=1 then return end
  local count=call(GetMerchantNumItems); if not self.IsNumber(count) then return end
  for i=1,MERCHANT_ITEMS_PER_PAGE do
    local b=_G["MerchantItem"..i.."ItemButton"]
    if b and (b.hasItem~=true or ((MerchantFrame.page-1)*MERCHANT_ITEMS_PER_PAGE+i)>count) then
      b:SetID(0); b.hasItem=nil; b.link=nil; b.name=nil; b.texture=nil; b.price=nil; b.extendedCost=nil; b.showNonrefundablePrompt=nil
      b:Hide(); if b.khqolKnownCheck then b.khqolKnownCheck:Hide() end
    end
  end
end
function M:ApplyMerchant()
  if self.applyingMerchant or not MerchantFrame then return end
  if call(InCombatLockdown)==true then self.merchantPending=true; return end
  self.merchantPending=nil; self.applyingMerchant=true
  local supported,why=self:MerchantSupported()
  self.merchantUnavailable=not supported and why or nil
  local expanded=self:IsEnabled() and self:GetDB().merchantExpanded and supported and MerchantFrame.selectedTab==1
  local size=expanded and 20 or 10
  local owned=self.merchantOwner~=nil
  if owned and MERCHANT_ITEMS_PER_PAGE~=20 then
    self.merchantUnavailable="상점 페이지 크기 "..tostring(MERCHANT_ITEMS_PER_PAGE).." (KHQOL 적용값 20). 변경 주체를 확인할 수 없습니다."
    self:MerchantLayout(false); self.applyingMerchant=false; return
  end
  -- Never write another addon's page size when we do not own this layout.
  if supported or owned then
    if expanded then self:CreateMerchantExtras() end
    local previous=MERCHANT_ITEMS_PER_PAGE
    local previousPage=MerchantFrame.page
    if previous~=size then
      if type(MerchantFrame_CloseStackSplitFrame)=="function" then MerchantFrame_CloseStackSplitFrame() end
      local first=((MerchantFrame.page or 1)-1)*previous+1
      MerchantFrame.page=math.floor((first-1)/size)+1
      MERCHANT_ITEMS_PER_PAGE=size
    end
    local count=call(GetMerchantNumItems)
    if self.IsNumber(count) then MerchantFrame.page=math.max(1,math.min(MerchantFrame.page or 1,math.max(1,math.ceil(count/size)))) end
    if (previous~=size or previousPage~=MerchantFrame.page) and merchantOpen() then MerchantFrame_Update() end
    self:MerchantLayout(expanded)
    self:ClearEmptyMerchantSlots()
  end
  self.applyingMerchant=false
end

local function strip(text)
  if not public(text) or type(text)~="string" then return end
  return text:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
end
function M:KnownItem(id)
  if not self.IsNumber(id) or id<=0 then return end
  self.knownCache=self.knownCache or {}
  -- Only positive determinations are cached; missing tooltip/item data retries
  -- on the native data-ready events, never on a high-frequency polling loop.
  if self.knownCache[id] then return self.knownCache[id] end
  local api=C_Item and C_Item.GetItemInfo or GetItemInfo
  local name,link,quality,level,min,kind,sub,stack,equip,icon,price,classID,subID=call(api,id)
  if not name then return end
  local db=self:GetDB(); local category
  if classID==9 and db.recipes then category="recipe" end
  local mountID=C_MountJournal and call(C_MountJournal.GetMountFromItem,id)
  if db.mounts and self.IsNumber(mountID) and mountID>0 then
    local mountName,spell,tex,active,usable,source,favorite,specific,faction,hide,collected=call(C_MountJournal.GetMountInfoByID,mountID)
    if collected==true then self.knownCache[id]="mount"; return "mount" end
    if collected==false then return end
  end
  if db.mounts and classID==15 and subID==5 then category="mount" end
  if not category or not C_TooltipInfo or type(C_TooltipInfo.GetItemByID)~="function" or type(ITEM_SPELL_KNOWN)~="string" then return end
  local ok,known=pcall(function()
    local data=call(C_TooltipInfo.GetItemByID,id)
    if type(data)~="table" or not public(data.lines) or type(data.lines)~="table" then return end
    for _,line in ipairs(data.lines) do
      if public(line) and type(line)=="table" and strip(line.leftText)==strip(ITEM_SPELL_KNOWN) then return true end
    end
  end)
  if ok and known then self.knownCache[id]=category; return category end
end
function M:MarkItem(button,id,on)
  if not button then return end
  if button.khqolKnownCheck then button.khqolKnownCheck:Hide() end
  if not on or not self:KnownItem(id) then return end
  if not button.khqolKnownCheck then
    local t=button:CreateTexture(nil,"OVERLAY",nil,7)
    t:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready"); t:SetSize(16,16); t:SetPoint("TOPLEFT",2,-2)
    button.khqolKnownCheck=t
    button:HookScript("OnHide",function() t:Hide() end)
    self.markedButtons=self.markedButtons or setmetatable({}, {__mode="k"}); self.markedButtons[button]=true
  end
  button.khqolKnownCheck:Show()
end
function M:MarkBag(frame)
  if not frame or type(frame.EnumerateValidItems)~="function" then return end
  local on=self:IsEnabled() and self:GetDB().knownItems and self:GetDB().bags
  for _,button in frame:EnumerateValidItems() do
    local bag=call(button.GetBagID,button); local slot=call(button.GetID,button)
    local id=C_Container and call(C_Container.GetContainerItemID,bag,slot)
    self:MarkItem(button,id,on)
  end
end
function M:RefreshKnownItems()
  local db=self:GetDB(); local on=self:IsEnabled() and db.knownItems
  for button in pairs(self.markedButtons or {}) do button.khqolKnownCheck:Hide() end
  if not on then return end
  if merchantOpen() and MerchantFrame.selectedTab==1 and db.merchant then
    for i=1,MERCHANT_ITEMS_PER_PAGE or 10 do
      local b=_G["MerchantItem"..i.."ItemButton"]
      if b and b.hasItem then self:MarkItem(b,call(GetMerchantItemID,b:GetID()),true) end
    end
  end
  if ContainerFrameCombinedBags and ContainerFrameCombinedBags:IsShown() then self:MarkBag(ContainerFrameCombinedBags) end
  for i=1,NUM_CONTAINER_FRAMES or 13 do
    local frame=_G["ContainerFrame"..i]
    if frame and frame:IsShown() then self:MarkBag(frame) end
  end
end
function M:InstallItemHooks()
  if not self.merchantHooked and type(MerchantFrame_Update)=="function" then
    self.merchantHooked=true
    hooksecurefunc("MerchantFrame_Update",function() M:ApplyMerchant(); M:RefreshKnownItems() end)
  end
  if not self.bagHooked and ContainerFrameMixin and type(ContainerFrameMixin.UpdateItems)=="function" then
    self.bagHooked=true
    hooksecurefunc(ContainerFrameMixin,"UpdateItems",function(frame) M:MarkBag(frame) end)
  end
end
local initialize=M.Initialize
function M:Initialize()
  initialize(self); self:InstallItemHooks()
  if self.itemLoadEvents then return end
  self.itemLoadEvents=CreateFrame("Frame"); self.itemLoadEvents:RegisterEvent("ADDON_LOADED")
  self.itemLoadEvents:SetScript("OnEvent",function() M:InstallItemHooks() end)
end
