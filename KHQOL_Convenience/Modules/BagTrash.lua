local K=_G.KHQOL
local M=K.modules.generalConvenience
local call=K.PublicCall
local PU=K.PositionUtils
local qualities={{"poor","하급"},{"common","일반"},{"uncommon","고급"},{"rare","희귀"},{"epic","영웅"}}
M.bagTrashQualities=qualities
local defaults={enabled=false,locked=true,size=60,mode="attached",allowInactiveQuestItems=false,
  position={point="CENTER",relativePoint="CENTER",x=220,y=-100},
  qualities={}}
for _,quality in ipairs(qualities) do defaults.qualities[quality[1]]=false end
M.defaults.bagTrash=defaults

local dialogs={"DELETE_ITEM","DELETE_QUEST_ITEM","DELETE_GOOD_ITEM","DELETE_GOOD_QUEST_ITEM",
  "DELETE_GOOD_ITEM_GAMEPAD","DELETE_GOOD_QUEST_ITEM_GAMEPAD"}
local function cursorLocation()
  local loc=call(C_Cursor and C_Cursor.GetCursorItem)
  if type(loc)~="table" or call(loc.IsBagAndSlot,loc)~=true then return end
  return loc,call(loc.GetBagAndSlot,loc)
end

local function cursorIdentity()
  local kind,id,link=call(GetCursorInfo)
  if kind~="item" or not K.IsPublicNumber(id) or id<1 or id%1~=0 or type(link)~="string" then return end
  local loc,bag,slot=cursorLocation()
  if not loc or not M:IsCharacterBag(bag) or not K.IsPublicNumber(slot) or slot<1 or slot%1~=0 then return end
  return {id=id,link=link,bag=bag,slot=slot}
end

local function sameCursor(a,b)
  return a and b and a.id==b.id and a.link==b.link and a.bag==b.bag and a.slot==b.slot
end

local function visibleTrashDialog()
  for _,which in ipairs(dialogs) do
    local popup=call(StaticPopup_FindVisible,which)
    if popup then return popup end
  end
end

-- Record the stock pickup and split calls after they finish. Split quantity
-- comes from their argument, never from the remaining stack in the bag.
function M:TrackTrashPickup(bag,slot,split)
  local held=cursorIdentity()
  if not held or held.bag~=bag or held.slot~=slot then self.trashPickup=nil;return end
  local item=self:ReadBagSlot(bag,slot)
  if not item or item.id~=held.id or item.link~=held.link or (split==nil and item.locked~=true) then
    self.trashPickup=nil;return
  end
  if split~=nil then
    if not K.IsPublicNumber(split) or split<1 or split%1~=0 then self.trashPickup=nil;return end
    held.count=split
  else
    held.count=item.count
  end
  held.split=split~=nil
  held.sourceCount=item.count
  self.trashPickup=held
end

function M:ReadTrashCursor()
  local held=cursorIdentity()
  if not held then return end
  local previous=self.trashPickup
  if sameCursor(held,previous) then
    local item=self:ReadBagSlot(held.bag,held.slot)
    if not item or item.id~=held.id or item.link~=held.link or item.count~=previous.sourceCount then return end
    if not previous.split and item.locked~=true then return end
    held.count=previous.count
    held.sourceCount=previous.sourceCount
    held.split=previous.split
  elseif call(C_Item and C_Item.GetItemMaxStackSizeByID,held.id)==1 then
    local item=self:ReadBagSlot(held.bag,held.slot)
    if not item or item.id~=held.id or item.link~=held.link or item.count~=1 or item.locked~=true then return end
    held.count=1
    held.sourceCount=1
  else
    return
  end
  local _,_,quality,_,_,_,_,_,_,_,_,classID,_,bind=call(C_Item and C_Item.GetItemInfo,held.link)
  if not K.IsPublicNumber(quality) or not K.IsPublicNumber(classID) or not K.IsPublicNumber(bind) then return end
  local quest=call(C_Container and C_Container.GetContainerItemQuestInfo,held.bag,held.slot)
  local isQuest,questID,isActive
  if type(quest)=="table" then
    isQuest,questID,isActive=call(function() return quest.isQuestItem,quest.questID,quest.isActive end)
  end
  if type(isQuest)~="boolean" then return end
  local linkedQuest=K.IsPublicNumber(questID) and questID>0 and questID%1==0
  local onQuest=linkedQuest and call(C_QuestLog and C_QuestLog.IsOnQuest,questID)
  local validQuestID=questID==nil or questID==0 or linkedQuest
  -- An explicit inactive state is required for the optional instant path.
  held.quest=(isQuest or linkedQuest) and (isActive==true
    or onQuest==true
    or (isQuest and isActive==nil))
  held.questRelated=held.quest or isQuest or linkedQuest or classID==12 or bind==4 or not validQuestID or isActive==true
  held.inactiveQuest=validQuestID and isActive==false and onQuest==false
  -- The default Hearthstone can be quest-classified without belonging to a
  -- quest. Only allow the ordinary path when the bag reports no quest link.
  held.hearthstone=held.id==6948 and validQuestID and not linkedQuest and
    (isActive==false or (isQuest==false and isActive==nil))
  held.quality=quality
  return held
end

function M:RememberTrashDialogClosed(frame)
  local pending=self.trashDialog
  if not pending or pending.frame~=frame then return end
  self.trashDialog=nil
  -- The confirmation click's post-hook also runs when Blizzard hid the popup.
  self.trashClosedDialog=pending
  C_Timer.After(0,function()
    if self.trashClosedDialog==pending then self.trashClosedDialog=nil end
  end)
end

function M:ValidateTrashDialog()
  local pending=self.trashDialog
  if not pending or not pending.frame then return end
  local held=self:ReadTrashCursor()
  if not self:GetDB().bagTrash.enabled or K.PositionEditor.active or not sameCursor(held,pending)
    or held.count~=pending.count or held.quest~=pending.quest or self:IsProtectedBagItem(pending.id) then
    self:RememberTrashDialogClosed(pending.frame)
    call(pending.frame.Hide,pending.frame)
  end
end

function M:ShowTrashConfirmation(held)
  if visibleTrashDialog() then return end
  local which
  if held.quest then which="DELETE_GOOD_QUEST_ITEM" else which="DELETE_GOOD_ITEM" end
  if held.quality<3 and not held.quest then which="DELETE_ITEM" end
  if not StaticPopupDialogs or not StaticPopupDialogs[which] then
    self:NotifyBagItem("기본 파괴 확인창을 열 수 없어 아이템을 보존했습니다.");return
  end
  -- The native dialog acts on the cursor. Passing a GUID could target the source stack.
  self.trashOpening=true
  local status,popup=K.ReadPublicAPI(StaticPopup_Show,which,held.link.." ×"..held.count)
  self.trashOpening=nil
  if status~="ok" or not popup then
    self:NotifyBagItem("기본 파괴 확인창을 열 수 없어 아이템을 보존했습니다.");return
  end
  held.frame=popup
  self.trashDialog=held
  self:ValidateTrashDialog()
end

function M:CheckCombatTrashConfirmation(frame,index)
  local held=self.trashDialog or self.trashClosedDialog
  if index~=1 or not held or held.frame~=frame or K.WindowLayers:OutsideCombat() then return end
  self.trashClosedDialog=nil
  -- Inspect only. Blizzard owns the click, and we never retry the deletion.
  C_Timer.After(.3,function()
    local item=self:ReadBagSlot(held.bag,held.slot)
    local original=held.sourceCount+(held.split and held.count or 0)
    if sameCursor(cursorIdentity(),held) or (item and item.link==held.link and item.count==original) then
      self:NotifyBagItem("전투 중 파괴가 확인되지 않았습니다. 커서와 가방의 아이템을 확인해 주세요.")
    end
  end)
end

function M:RequestTrashDeletion(held)
  self.trashRequest=held
  -- Try once, during the actual mouse release. This API has no success result.
  -- The game may open its own confirmation or reject the call.
  call(DeleteCursorItem)
  local popup=visibleTrashDialog()
  if popup then
    held.frame=popup;self.trashDialog=held
    self:ValidateTrashDialog()
  end
  C_Timer.After(0,function()
    self.trashRequest=nil
    local cfg=self:GetDB().bagTrash
    if held.frame or held.cursorChanged or not cfg.enabled or K.PositionEditor.active
      or call(CursorHasItem)~=true or self:IsProtectedBagItem(held.id) then return end
    local current=self:ReadTrashCursor()
    if sameCursor(current,held) and current.count==held.count then
      local native=visibleTrashDialog()
      if native then current.frame=native;self.trashDialog=current
      else self:ShowTrashConfirmation(current) end
    end
  end)
end

function M:ReceiveTrashDrop(dragged)
  local cfg=self:GetDB().bagTrash
  if not cfg.enabled or K.PositionEditor.active or self.trashButton.positionMoving then return end
  if InputUtil and call(InputUtil.IsGamepadUIEnabled)==true then
    self:NotifyBagItem("마우스로 가방 휴지통에 놓아 주세요.");return
  end
  if self.trashDialog or self.trashOpening or self.trashRequest or call(CursorHasItem)~=true then return end
  local cursor=cursorIdentity()
  if cursor and self:IsProtectedBagItem(cursor.id) then self:NotifyBagItem("보호 중인 아이템은 휴지통에서 파괴할 수 없습니다.");return end
  local held=self:ReadTrashCursor()
  if not held then self:NotifyBagItem("가방 아이템 또는 집은 수량을 확인할 수 없어 보존했습니다.");return end
  if visibleTrashDialog() then return end
  local grade=qualities[held.quality+1]
  local canSkip=not held.questRelated or held.hearthstone or (held.inactiveQuest and cfg.allowInactiveQuestItems==true)
  -- Combat drag-to-delete has not been verified on Forever. Use the native
  -- confirmation button for all combat drops, including the selected grades.
  if K.WindowLayers:OutsideCombat() and dragged and canSkip and grade
    and cfg.qualities[grade[1]]==true and type(DeleteCursorItem)=="function" then
    self:RequestTrashDeletion(held)
  else
    self:ShowTrashConfirmation(held)
  end
end

local function shown(frame)
  return frame and call(frame.IsVisible,frame)==true
end

function M:MakeTrashButton(parent)
  local b=CreateFrame("Button",nil,parent,"BackdropTemplate")
  b:EnableMouse(true)
  if type(b.SetPropagateMouseClicks)=="function" then b:SetPropagateMouseClicks(false) end
  K.HUDText.MakeBackdrop(b,.75,.57,.2,.9)
  b.icon=b:CreateTexture(nil,"ARTWORK")
  b.icon:SetTexture("Interface\\AddOns\\KHQOL_Convenience\\Media\\BagTrash.tga")
  b.icon:SetPoint("TOPLEFT",3,-3);b.icon:SetPoint("BOTTOMRIGHT",-3,3)
  b:RegisterForClicks("LeftButtonUp","RightButtonUp")
  b:SetScript("OnReceiveDrag",function() M:ReceiveTrashDrop(true) end)
  b:SetScript("OnClick",function(_,button)
    if button=="RightButton" then
      -- Finish this bag mouse event before building/reflowing the settings UI.
      if not M.trashSettingsQueued then
        M.trashSettingsQueued=true
        C_Timer.After(0,function() M.trashSettingsQueued=nil;M:OpenTrashSettings() end)
      end
    elseif button=="LeftButton" then M:ReceiveTrashDrop() end
  end)
  b:SetScript("OnEnter",function(frame)
    if K.PositionEditor.active then return end
    GameTooltip:SetOwner(frame,"ANCHOR_LEFT");GameTooltip:SetText("가방 휴지통")
    GameTooltip:AddLine("가방 아이템을 드래그해 놓으세요. 전투 중에는 기본 확인창을 사용합니다.",1,1,1,true)
    GameTooltip:Show()
  end)
  local function hideTip(frame) if GameTooltip:IsOwned(frame) then GameTooltip:Hide() end end
  b:SetScript("OnLeave",hideTip);b:SetScript("OnHide",hideTip)
  b:Hide()
  return b
end

function M:QueueTrashLayout()
  if not self.trashButton or self.trashLayoutQueued then return end
  self.trashLayoutQueued=true
  C_Timer.After(0,function()
    self.trashLayoutQueued=nil
    self:RefreshBagTrash()
  end)
end

function M:WatchBagTrashFrame(frame,watchCharacter)
  if not frame or self.trashFrames[frame] then return end
  self.trashFrames[frame]=true
  frame:HookScript("OnShow",function() self:QueueTrashLayout() end)
  frame:HookScript("OnHide",function() self:QueueTrashLayout() end)
  if watchCharacter and type(frame.UpdateForCharacter)=="function" then
    hooksecurefunc(frame,"UpdateForCharacter",function() self:QueueTrashLayout() end)
  end
end

function M:NativeTrashHost()
  self:WatchBagTrashFrame(ContainerFrameCombinedBags)
  local host=shown(ContainerFrameCombinedBags) and ContainerFrameCombinedBags or nil
  if ContainerFrameContainer and type(ContainerFrameContainer.ContainerFrames)=="table" then
    for _,frame in ipairs(ContainerFrameContainer.ContainerFrames) do
      self:WatchBagTrashFrame(frame)
      if not host and shown(frame) and self:IsCharacterBag(call(frame.GetID,frame)) then host=frame end
    end
  end
  for index=1,NUM_CONTAINER_FRAMES or 5 do
    local frame=_G["ContainerFrame"..index]
    self:WatchBagTrashFrame(frame)
    if not host and shown(frame) and self:IsCharacterBag(call(frame.GetID,frame)) then host=frame end
  end
  return host
end

function M:BaganatorBackpackVisible()
  if not Baganator or not Baganator.API then return false end
  local skins=Baganator.API.Skins
  local skin=skins and call(skins.GetCurrentSkin)
  local anyOpen=false
  for _,view in ipairs({"Single","Category"}) do
    local prefix="Baganator_"..view.."ViewBackpackViewFrame"
    local frame=_G[prefix..(type(skin)=="string" and skin or "blizzard")]
    self:WatchBagTrashFrame(frame,true)
    if shown(frame) and call(function() return frame.isLive end)==true then anyOpen=true end
  end
  return anyOpen
end

function M:RegisterBaganatorTrash()
  if self.trashRegion or not (Baganator and Baganator.API and Baganator.API.RegisterRegion) then return end
  local region=CreateFrame("Frame",nil,UIParent)
  local button=self:MakeTrashButton(region)
  button:SetAllPoints(region)
  region:Hide()
  if K.ReadPublicAPI(Baganator.API.RegisterRegion,"KHQOL 가방 휴지통","khqol_bag_trash","backpack","bottom_left",region)~="ok" then return end
  self.trashRegion,self.trashBaganatorButton=region,button
  for _,method in ipairs({"SetParent","SetPoint"}) do
    hooksecurefunc(region,method,function() self:QueueTrashLayout() end)
  end
end

function M:RefreshBagTrash()
  if not self.trashButton then return end
  local cfg=self:GetDB().bagTrash
  self:ValidateTrashDialog()
  local size=K.IsPublicNumber(cfg.size) and math.max(50,math.min(80,math.floor(cfg.size+.5))) or defaults.size
  cfg.size=size
  local button,region=self.trashButton,self.trashRegion
  local editing=K.PositionEditor.active
  local attached=cfg.enabled and cfg.mode~="free"
  local host=self:NativeTrashHost()
  local bgrOpen=self:BaganatorBackpackVisible()
  if region then
    local show=attached
    local changed=region:IsShown()~=show or region:GetWidth()~=size
    region:SetSize(size,size);region:SetShown(show)
    local parent=region:GetParent()
    local live=parent and parent~=UIParent and call(function() return parent.isLive end)==true
    if live then self:WatchBagTrashFrame(parent,true) end
    bgrOpen=bgrOpen or (live and shown(parent))
    self.trashBaganatorButton:SetShown(show and live and not editing)
    if changed then call(Baganator.API.RequestLayoutUpdate) end
  end
  local bgrVisible=shown(self.trashBaganatorButton)
  button:SetSize(size,size)
  local visible=false
  if cfg.mode=="free" then
    if not button.positionMoving then PU.ApplyPoint(button,cfg.position) end
    visible=host~=nil or bgrOpen or call(IsAnyStandardHeldBagOpen)==true
  elseif host then
    button:ClearAllPoints();button:SetPoint("TOPRIGHT",host,"TOPLEFT",-5,0)
    visible=not bgrVisible
  end
  visible=cfg.enabled and not editing and visible
  if not visible then K.PositionStore:FinishFrameDrag(button) end
  button:SetShown(visible)
end

function M:BagTrashPositionTarget()
  local list={}
  local cfg=self:GetDB().bagTrash
  if not cfg.enabled or cfg.mode~="free" then return list end
  PU:Add(list,"bagTrash","generalConvenience","가방 휴지통",self.trashButton,PU:PointWriter(cfg.position),
    PU:Lock(cfg),function() self:RefreshBagTrash() end,{sample="가방 휴지통",settingsRoute={module="generalConvenience",section="가방 휴지통"}})
  PU:ConfigureResets(list,function(target,point) point(target,function() return cfg.position end,defaults.position) end)
  return list
end

function M:InitializeBagTrash()
  if self.trashButton then return end
  self.trashFrames={}
  self.trashButton=self:MakeTrashButton(UIParent)
  self.trashButton:SetFrameStrata("DIALOG")
  self.trashButton:SetClampedToScreen(true);self.trashButton:SetMovable(true)
  self.trashButton:RegisterForDrag("LeftButton")
  self.trashButton:SetScript("OnDragStart",function(frame)
    local cfg=self:GetDB().bagTrash
    if cfg.mode=="free" and not cfg.locked and not K.PositionEditor.active
      and K.WindowLayers:OutsideCombat() and call(CursorHasItem)==false then
      frame.positionMoving=true;frame:StartMoving()
    end
  end)
  self.trashButton:SetScript("OnDragStop",function(frame)
    if not frame.positionMoving then return end
    frame.positionMoving=nil
    frame:StopMovingOrSizing()
    K.PositionStore:Point(frame,self:GetDB().bagTrash.position)
    K.PositionStore:Committed(function() self:RefreshBagTrash() end)
  end)

  self:RegisterBaganatorTrash()
  if type(StaticPopup_OnClick)=="function" then
    hooksecurefunc("StaticPopup_OnClick",function(frame,index) self:CheckCombatTrashConfirmation(frame,index) end)
  end
  if type(StaticPopup_OnHide)=="function" then
    hooksecurefunc("StaticPopup_OnHide",function(frame) self:RememberTrashDialogClosed(frame) end)
  end
  if C_Container and type(C_Container.PickupContainerItem)=="function" then
    hooksecurefunc(C_Container,"PickupContainerItem",function(bag,slot) self:TrackTrashPickup(bag,slot) end)
  end
  if C_Container and type(C_Container.SplitContainerItem)=="function" then
    hooksecurefunc(C_Container,"SplitContainerItem",function(bag,slot,count) self:TrackTrashPickup(bag,slot,count) end)
  end
  local events=CreateFrame("Frame")
  for _,event in ipairs({"CURSOR_CHANGED","ITEM_LOCK_CHANGED","BAG_UPDATE_DELAYED","PLAYER_LOGIN","PLAYER_ENTERING_WORLD","ADDON_LOADED",
      "PLAYER_REGEN_DISABLED","USE_COMBINED_BAGS_CHANGED"}) do
    pcall(events.RegisterEvent,events,event)
  end
  events:SetScript("OnEvent",function(_,event,addon)
    if event=="CURSOR_CHANGED" then
      self.trashPickup=nil
      if self.trashRequest then self.trashRequest.cursorChanged=true end
      -- An item-to-item swap can keep the cursor kind unchanged. Close a
      -- pending popup on any cursor replacement before the next input.
      local pending=self.trashDialog
      if pending and pending.frame then
        self:RememberTrashDialogClosed(pending.frame);call(pending.frame.Hide,pending.frame)
      end
    elseif event=="PLAYER_REGEN_DISABLED" then
      self:ValidateTrashDialog()
    elseif event=="BAG_UPDATE_DELAYED" then
      self:ValidateTrashDialog();self:QueueTrashLayout()
    elseif event=="ITEM_LOCK_CHANGED" then
      self:ValidateTrashDialog()
    elseif event~="ADDON_LOADED" or addon=="Baganator" or addon=="Blizzard_UIPanels_Game" then
      self:RegisterBaganatorTrash();self:QueueTrashLayout()
    end
  end)
  for _,name in ipairs({"OpenBag","OpenAllBags","CloseBag","CloseAllBags","ToggleBackpack","ToggleBag",
      "ToggleAllBags","ContainerFrame_GenerateFrame"}) do
    if type(_G[name])=="function" then hooksecurefunc(name,function() self:QueueTrashLayout() end) end
  end
  hooksecurefunc(K.PositionEditor,"Enter",function() self:ValidateTrashDialog();self:QueueTrashLayout() end)
  hooksecurefunc(K.PositionEditor,"Finish",function() self:RefreshBagTrash() end)
  self:RefreshBagTrash()
end
