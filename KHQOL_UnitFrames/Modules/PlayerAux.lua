local K=assert(_G.KHQOL)
local NS=K
local RS={}
K.PlayerAux=RS
RS.defaults={showAmmo=true,showSoulShards=true,showSoulShardLabel=true,soulShardMax=20,
 ammoTextPosition="RIGHT",ammoTextSize=12,ammoPriority=5,ammoLocked=false,
 ammoPoint="CENTER",ammoRelativePoint="CENTER",ammoX=0,ammoY=-120}
local db,ammoFrame,auxText,auxIcon
function RS:GetDB()
 KHQOLResourceSwingDB=K.MergeDefaults(KHQOLResourceSwingDB or {},self.defaults,"tables")
 db=KHQOLResourceSwingDB;return db
end
function RS:IsEnabled() return K:CanRunModule("unitFrames") end
function RS:IsWarlock() return select(2,K.PublicCall(UnitClass,"player"))=="WARLOCK" end
local function read(fn,...) return NS.PublicCall(fn,...) end
local function field(info,key)
    if not NS.IsPublicValue(info) or type(info)~="table" then return end
    local ok,value=pcall(function() return info[key] end)
    if ok and NS.IsPublicValue(value) then return value end
end
local function integer(v,min,max)
    return NS.IsPublicValue(v) and type(v)=="number" and v==v and v>=min and v<=max and v==math.floor(v)
end
local function bagTotal(itemID)
    local container=C_Container
    local slots=(container and container.GetContainerNumSlots) or GetContainerNumSlots
    local idFn=(container and container.GetContainerItemID) or GetContainerItemID
    local infoFn=(container and container.GetContainerItemInfo) or GetContainerItemInfo
    if type(slots)~="function" or type(idFn)~="function" or type(infoFn)~="function" then return end
    local last=NUM_BAG_SLOTS
    if not integer(last,1,20) then return end
    local reagent=Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag
    if integer(reagent,0,20) then last=math.max(last,reagent) end
    local total=0
    for bag=0,last do
        local count=read(slots,bag)
        if not integer(count,0,1000) then return end
        for slot=1,count do
            local status,id=NS.ReadPublicAPI(idFn,bag,slot)
            if status~="ok" then return end
            if id~=nil and not integer(id,1,2147483647) then return end
            if id==itemID then
                local quantity
                if container and container.GetContainerItemInfo then
                    quantity=field(read(infoFn,bag,slot),"stackCount")
                else
                    local _,n=read(infoFn,bag,slot);quantity=n
                end
                if not integer(quantity,0,1000000) then return end
                total=total+quantity
            end
        end
    end
    return total
end
function RS:GetCarriedItemCount(itemID)
    if not integer(itemID,1,2147483647) then return end
    local fn=(C_Item and C_Item.GetItemCount) or GetItemCount
    if type(fn)=="function" then
        -- Inventory only: no character/reagent/account bank, no charge counts.
        local n=read(fn,itemID,false,false,false,false)
        if integer(n,0,100000000) then return n end
        return nil
    end
    return bagTotal(itemID)
end

function RS:IsAmmoClass()
    local _,class=read(UnitClass,"player")
    return class=="ROGUE" or class=="WARRIOR" or class=="HUNTER"
end
function RS:GetAuxData()
    if not self:IsEnabled() then return nil,nil,nil,"MODULE_OFF" end
    local _,class=read(UnitClass,"player")
    if class=="WARLOCK" then
        if not db.showSoulShards then return nil,nil,nil,"DISABLED" end
        -- Candidate Classic item ID is accepted only after client metadata matches.
        -- A soulstone item/buff or Retail power value is never used as a substitute.
        local fn=(C_Item and C_Item.GetItemInfo) or GetItemInfo
        local name,_,_,_,_,_,_,_,_,icon=read(fn,6265)
        if name~="Soul Shard" and name~="영혼의 조각" and not (type(SOUL_SHARD)=="string" and name==SOUL_SHARD) then
            if C_Item and C_Item.RequestLoadItemDataByID and not RS.shardDataRequested then
                RS.shardDataRequested=true;pcall(C_Item.RequestLoadItemDataByID,6265)
            end
            return nil,nil,nil,"SHARD_ITEM_UNCONFIRMED"
        end
        local n=self:GetCarriedItemCount(6265)
        if n==nil or not icon then return nil,nil,nil,"ITEM_COUNT_UNREADABLE" end
        return "영혼의 조각",n,icon
    end
    if not self:IsAmmoClass() then return nil,nil,nil,"UNSUPPORTED_CLASS" end
    if not db.showAmmo then return nil,nil,nil,"DISABLED" end
    local uses=read(UnitUsesAmmo,"player")
    local needed=read(C_PaperDollInfo and C_PaperDollInfo.AmmoNeeded)
    if uses==false or needed==false then return nil,nil,nil,"NO_AMMO_REQUIRED" end
    if C_PaperDollInfo and type(C_PaperDollInfo.AmmoNeeded)=="function" and needed~=true then
        return nil,nil,nil,"AMMO_USAGE_UNCONFIRMED"
    end
    -- Older builds may lack UnitUsesAmmo. Only the existing Hunter fallback is kept.
    if uses~=true and not (type(UnitUsesAmmo)~="function" and class=="HUNTER") then return nil,nil,nil,"AMMO_USAGE_UNCONFIRMED" end
    local slotInfo=(C_PaperDollInfo and C_PaperDollInfo.GetInventorySlotInfo) or GetInventorySlotInfo
    local ammoSlot=read(slotInfo,"AmmoSlot")
    local rangedSlot=read(slotInfo,"RangedSlot")
    if not integer(ammoSlot,0,100) or not integer(rangedSlot,1,100) then return nil,nil,nil,"SLOTS_UNAVAILABLE" end
    local ranged=read(GetInventoryItemID,"player",rangedSlot)
    if not integer(ranged,1,2147483647) then return nil,nil,nil,"NO_RANGED_WEAPON" end
    local instant=(C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    local _,_,_,loc=read(instant,ranged)
    if loc=="INVTYPE_THROWN" then return nil,nil,nil,"THROWN_CONSUMPTION_UNCONFIRMED" end
    if loc~="INVTYPE_RANGED" and loc~="INVTYPE_RANGEDRIGHT" then return nil,nil,nil,"RANGED_WEAPON_UNCONFIRMED" end
    local id=read(GetInventoryItemID,"player",ammoSlot)
    if not integer(id,1,2147483647) then return nil,nil,nil,"NO_AMMO_ITEM" end
    local icon=read(GetInventoryItemTexture,"player",ammoSlot)
    local n=self:GetCarriedItemCount(id)
    if n==nil or not icon then return nil,nil,nil,"ITEM_COUNT_UNREADABLE" end
    return "",n,icon
end
function RS:CanShowAux()
    local _,class=read(UnitClass,"player")
    return db and self:IsEnabled() and ((class=="WARLOCK" and db.showSoulShards)
      or (self:IsAmmoClass() and db.showAmmo)) or false
end
local function updateAuxText()
    if not ammoFrame then return end
    local label,count,icon,reason=RS:GetAuxData()
    RS.auxStatus=reason;RS.auxCount=count
    local caption=label
    if label and RS:IsWarlock() and db.showSoulShardLabel==false then caption="" end
    auxText:SetText(caption and (caption=="" and tostring(count) or caption.." "..count) or "")
    if label then
        local width=auxText:GetStringWidth()
        if NS.IsPublicValue(width) and type(width)=="number" then ammoFrame:SetWidth(math.max(180,width+26)) end
    end
    auxIcon:SetTexture(icon);auxIcon:SetShown(label~=nil)
    ammoFrame:SetShown(label~=nil)
    RS:RefreshShardControls()
end
function RS:RefreshAux() updateAuxText() end

function RS:ApplyPosition()
 self:GetDB();if not ammoFrame then return end
 self:ConfigureEvents()
 if ammoFrame.positionMoving and (db.ammoLocked or not self:IsEnabled()) then ammoFrame:StopMovingOrSizing();ammoFrame.positionMoving=nil end
 local anchors={CENTER=true,TOP=true,BOTTOM=true,LEFT=true,RIGHT=true,TOPLEFT=true,TOPRIGHT=true,BOTTOMLEFT=true,BOTTOMRIGHT=true}
 local point=anchors[db.ammoPoint] and db.ammoPoint or "CENTER"
 local relative=anchors[db.ammoRelativePoint] and db.ammoRelativePoint or "CENTER"
 local x=K.IsPublicNumber(db.ammoX) and math.max(-20000,math.min(20000,db.ammoX)) or 0
 local y=K.IsPublicNumber(db.ammoY) and math.max(-20000,math.min(20000,db.ammoY)) or -120
 ammoFrame:ClearAllPoints();ammoFrame:SetPoint(point,UIParent,relative,x,y)
 auxText:SetFont(K.UI:Font(),integer(db.ammoTextSize,8,24) and db.ammoTextSize or 12,"OUTLINE")
 ammoFrame:EnableMouse(self:IsEnabled() and not db.ammoLocked)
 ammoFrame:SetBackdropColor(0,0,0,db.ammoLocked and 0 or .35)
 updateAuxText()
end
function RS:ConfigureEvents()
 if not self.events then return end
 self.events:UnregisterAllEvents()
 if self:IsEnabled() then
  for _,event in ipairs({"PLAYER_LOGIN","PLAYER_ENTERING_WORLD","GET_ITEM_INFO_RECEIVED","PLAYER_EQUIPMENT_CHANGED","UNIT_INVENTORY_CHANGED","BAG_UPDATE_DELAYED","WEAPON_SLOT_CHANGED","PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED"}) do self.events:RegisterEvent(event) end
 end
end
function RS:Initialize()
 self:GetDB()
 if not ammoFrame then
  ammoFrame=CreateFrame("Frame","KHQOLResourceSwingAmmoAnchor",UIParent,"BackdropTemplate");self.frame=ammoFrame
  ammoFrame:SetSize(180,22);ammoFrame:SetMovable(true);ammoFrame:SetClampedToScreen(true);ammoFrame:RegisterForDrag("LeftButton")
  ammoFrame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"})
  ammoFrame:SetScript("OnDragStart",function(f) if RS:IsEnabled() and not RS:GetDB().ammoLocked and not InCombatLockdown() then f.positionMoving=true;f:StartMoving() end end)
  ammoFrame:SetScript("OnDragStop",function(f)
   if not f.positionMoving then return end
   f:StopMovingOrSizing();f.positionMoving=nil
   local d=RS:GetDB();local position={};if K.PositionStore:Point(f,position) then
    d.ammoPoint,d.ammoRelativePoint,d.ammoX,d.ammoY=position.point,position.relativePoint,position.x,position.y
    K.PositionStore:Committed()
   end
  end)
  auxText=ammoFrame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall");self.text=auxText
  auxIcon=ammoFrame:CreateTexture(nil,"ARTWORK");auxIcon:SetSize(18,18);auxIcon:SetPoint("LEFT",ammoFrame,"LEFT",2,0)
  auxText:SetPoint("LEFT",auxIcon,"RIGHT",4,0);self:CreateShardControls(ammoFrame,auxIcon,auxText)
  self.events=CreateFrame("Frame")
  self.events:SetScript("OnEvent",function(_,event,unit)
   if event=="UNIT_INVENTORY_CHANGED" and unit~="player" then return end
   if event=="PLAYER_REGEN_DISABLED" and ammoFrame.positionMoving then ammoFrame:GetScript("OnDragStop")(ammoFrame) end
   RS:RefreshAux()
  end)
 end
 self:ConfigureEvents();self:ApplyPosition()
end
function RS:StopEditor()
 if self.shardLimitPanel then self.shardLimitPanel:Hide() end
 if ammoFrame and ammoFrame.positionMoving then ammoFrame:StopMovingOrSizing();ammoFrame.positionMoving=nil end
end
function RS:PositionTarget()
 if not self:CanShowAux() or not ammoFrame then return end
 local d=self:GetDB();local U=K.PositionUtils
 return {id="ammo",name="플레이어 · 탄약 / 영혼의 조각",frame=ammoFrame,
  settingsRoute={module="unitFrames",unit="player",part="class",section="보조 표시 위치"},
  write=U:PointWriter(d,"ammoX","ammoY"),lock=U:Lock(d,"ammoLocked"),apply=function() RS:ApplyPosition() end,
  sample="탄약 / 영혼의 조각",resetPoint={point="CENTER",relativePoint="CENTER",x=0,y=-120},
  resetWrite=function() d.ammoPoint,d.ammoRelativePoint,d.ammoX,d.ammoY="CENTER","CENTER",0,-120 end}
end
