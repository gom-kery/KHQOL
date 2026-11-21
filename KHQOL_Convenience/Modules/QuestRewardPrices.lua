local K=_G.KHQOL
local M=K.modules.generalConvenience
local call=K.PublicCall
local P={coins={},waiting={},requested={}}

local function shown(frame)
  return frame and call(frame.IsVisible,frame)==true
end

function P:Clear()
  for _,coin in pairs(self.coins) do coin:Hide() end
  self.waiting={}
end

function P:Refresh()
  self:Clear()
  local info=QuestInfoFrame
  if not M:GetDB().questRewardBestPrice or not shown(QuestFrame) or not info or info.questLog or info.mapView
    or not (shown(QuestFrameDetailPanel) or shown(QuestFrameRewardPanel)) then
    self.questID=nil;self.requested={}
    return
  end
  local id,count=call(GetQuestID),call(GetNumQuestChoices)
  if not K.IsPublicNumber(id) or id<=0 or not K.IsPublicNumber(count) or count<2 or count>100 or count%1~=0 then return end
  if id~=self.questID then self.questID=id;self.requested={} end
  local rewards=info.rewardsFrame
  if not rewards or rewards~=QuestInfoRewardsFrame or not shown(rewards) or type(rewards.RewardButtons)~="table" then return end
  local buttons={}
  for _,button in ipairs(rewards.RewardButtons) do
    if shown(button) and button.questID==id and button.type=="choice" and button.objectType=="item" then
      local index=call(button.GetID,button)
      if K.IsPublicNumber(index) then buttons[index]=button end
    end
  end
  local highest,complete,prices=0,true,{}
  for index=1,count do
    local kind=call(GetQuestItemInfoLootType,"choice",index)
    if kind==0 then
      local _,_,quantity,_,_,itemID=call(GetQuestItemInfo,"choice",index)
      local button=buttons[index]
      if not button or not K.IsPublicNumber(quantity) or quantity<1 or quantity%1~=0
        or not K.IsPublicNumber(itemID) or itemID<1 or itemID%1~=0 then complete=false
      else
        local link=call(GetQuestItemLink,"choice",index)
        local linkID=type(link)=="string" and tonumber(link:match("|Hitem:(%d+)"))
        if linkID and linkID~=itemID then return end
        local _,_,_,_,_,_,_,_,_,_,sellPrice=call(C_Item and C_Item.GetItemInfo,linkID and link or itemID)
        if K.IsPublicNumber(sellPrice) and sellPrice>=0 then
          prices[button]=sellPrice*quantity;highest=math.max(highest,prices[button])
        else
          complete=false;self.waiting[itemID]=true
          if not self.requested[itemID] then
            self.requested[itemID]=true
            call(C_Item and C_Item.RequestLoadItemDataByID,itemID)
          end
        end
      end
    elseif kind~=1 then complete=false end
  end
  if not complete or highest<=0 then return end
  for button,price in pairs(prices) do
    if price==highest then
      local coin=self.coins[button]
      if not coin then
        coin=button:CreateTexture(nil,"OVERLAY",nil,7)
        coin:SetTexture("Interface\\MoneyFrame\\UI-GoldIcon");coin:SetSize(13,13)
        -- NameFrame art extends past the visible reward row in the stock template.
        coin:SetPoint("TOPRIGHT",button,"TOPRIGHT",-6,-4)
        self.coins[button]=coin
      end
      coin:Show()
    end
  end
end

function P:Queue()
  if self.queued then return end
  local ticket={};self.queued=ticket
  C_Timer.After(0,function()
    if P.queued~=ticket then return end
    P.queued=nil;P:Refresh()
  end)
end

function P:Install()
  if self.hooked or type(QuestInfo_ShowRewards)~="function" or not QuestFrame then return end
  self.hooked=true
  hooksecurefunc("QuestInfo_ShowRewards",function() self:Clear();self:Queue() end)
  for _,frame in ipairs({QuestFrame,QuestFrameDetailPanel,QuestFrameRewardPanel}) do
    frame:HookScript("OnHide",function() self:Clear();self.queued=nil end)
  end
end

function M:RefreshQuestRewardPrices()
  if not self:GetDB().questRewardBestPrice then
    P:Clear();P.queued=nil;P.questID=nil;P.requested={}
    return
  end
  if not P.events then
    P.events=CreateFrame("Frame")
    for _,event in ipairs({"ADDON_LOADED","QUEST_DETAIL","QUEST_COMPLETE","QUEST_ITEM_UPDATE","GET_ITEM_INFO_RECEIVED","ITEM_DATA_LOAD_RESULT"}) do
      pcall(P.events.RegisterEvent,P.events,event)
    end
    P.events:SetScript("OnEvent",function(_,event,arg)
      if event=="ADDON_LOADED" then P:Install();return end
      if not M:GetDB().questRewardBestPrice then return end
      if event=="GET_ITEM_INFO_RECEIVED" or event=="ITEM_DATA_LOAD_RESULT" then
        if K.IsPublicNumber(arg) and P.waiting[arg] then P:Queue() end
      else P:Clear();P:Queue() end
    end)
  end
  P:Install();P:Queue()
end
