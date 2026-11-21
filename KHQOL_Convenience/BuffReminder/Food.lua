local K,F=_G.KHQOL,_G.ForeverBuffReminder
local call,number=K.PublicCall,K.IsPublicNumber
local Food={verified={},generation=0}
F.Food=Food
-- FoodEvidence validates live item tooltips and observed player aura identities.
-- A verified row must supply nonConjured=true, killXP=5, eatingSpell,
-- wellFedSpell, seconds, and a versioned primary-source reference.
Food.eatingCandidate=435;Food.wellFedCandidate=1249519
function Food:Config() return ForeverBuffReminderDB.food end
function Food:Enabled() return F.initialized and K:GetEnabled("buffReminder") and self:Config().enabled==true end
function Food:Verified(id)
    local row=self.verified[id]
    return row and row.nonConjured==true and row.killXP==5 and number(row.seconds) and row.seconds>0 and row.source and row or nil
end
function Food:Info(id)
    if not number(id) or id<=0 or id~=math.floor(id) then return end
    local name,link,_,_,_,_,_,_,_,icon,_,class,subclass=call(C_Item and C_Item.GetItemInfo or GetItemInfo,id)
    if not K.IsPublicValue(name) or type(name)~="string" or name=="" then return nil,"아이템 정보를 불러오는 중입니다." end
    if not number(class) or not number(subclass) or class~=0 or subclass~=5 then return nil,"음식·음료 아이템만 지정할 수 있습니다." end
    if not K.IsPublicValue(icon) then icon=nil end
    return {id=id,name=name,icon=icon,link=K.IsPublicValue(link) and link or nil}
end
function Food:Select(raw,path)
    self.pending=nil
    local id=type(raw)=="number" and raw or type(raw)=="string" and tonumber(raw:match("item:(%d+)") or raw:match("^%s*(%d+)%s*$"))
    if not number(id) or id<=0 or id~=math.floor(id) then self.message="양의 아이템 ID 또는 아이템 링크를 입력하세요.";return false end
    local info,message=self:Info(id)
    if not info then
        self.message=message
        -- Completion only retries the same pending input in the same profile.
        if message=="아이템 정보를 불러오는 중입니다." then
            if self:Enabled() then self.pending={id=id,profile=K.profileGeneration,config=self:Config(),path=path} end
            call(C_Item and C_Item.RequestLoadItemDataByID,id)
        end
        return false
    end
    self.pending=nil;self:Config().itemID=id;self.message=nil;self:Invalidate();return true
end
function Food:Invalidate()
    self.generation=self.generation+1;self.inventory=nil;self.request=nil;self.progress=nil;self.meal=nil;self.observation=nil;self.lastInfo=nil;self.bagStock=nil;self.itemAttempts=nil
    self:Queue()
end
function Food:Stock(id)
    local count=call(C_Item and C_Item.GetItemCount or GetItemCount,id,false,false,false)
    local usable=call(C_Item and C_Item.IsUsableItem or IsUsableItem,id)
    if not number(count) or count<0 then return 0,false,"재고 확인 불가" end
    if count==0 then return 0,false,"보유하지 않음" end
    if usable~=true then return count,false,"현재 사용 불가" end
    if self.bagStock then
        local state=self.bagStock[id]
        return count,state and state.unlocked or false,state and state.unlocked and "사용 가능" or state and "가방에서 잠김" or "가방 상태 확인 불가"
    end
    local api=C_Container
    if not api or type(api.GetContainerNumSlots)~="function" or type(api.GetContainerItemInfo)~="function" then
        return count,false,"가방 상태 확인 불가"
    end
    local found,unlocked=false,false
    for bag=0,(NUM_BAG_SLOTS or 4) do
        local slots=call(api.GetContainerNumSlots,bag)
        if number(slots) and slots>=0 and slots<=100 then
            for slot=1,slots do
                local data=call(api.GetContainerItemInfo,bag,slot)
                if data then
                    local itemID,locked=call(function() return data.itemID,data.isLocked end)
                    if number(itemID) and itemID==id then
                        found=true;if locked==false then unlocked=true end
                    end
                end
            end
        end
    end
    return count,unlocked,unlocked and "사용 가능" or found and "가방에서 잠김" or "가방 상태 확인 불가"
end
function Food:Choose()
    local cfg=self:Config()
    if cfg.mode~="AUTO" then return cfg.itemID end
    local ids=self:BagCandidates()
    if self.selected and self:Verified(self.selected) then
        local count,usable=self:Stock(self.selected);if count>0 and usable then return self.selected end
    end
    for _,id in ipairs(ids) do local count,usable=self:Stock(id);if count>0 and usable then return id end end
end
function Food:Queue()
    if self.queued then return end
    self.queued=true
    C_Timer.After(0,function()
        self.queued=nil
        if not self:Enabled() then return end
        if call(InCombatLockdown)~=false then self.dirty=true;return end
        self:RefreshInventory();F:RefreshAlerts()
        if self.RefreshSummary then self:RefreshSummary() end
    end)
end
function Food:RefreshInventory()
    if not self:Enabled() or call(InCombatLockdown)~=false then self.dirty=true;return end
    self.dirty=nil;self.bagStock=nil
    local id=self:Choose()
    local now=call(GetTime)
    local waiting=self.request and number(now) and number(self.request.time) and now-self.request.time<=3
    if self.selected and id~=self.selected and (self.progress or self.meal or waiting) then id=self.selected end
    local info=id and (self:Info(id) or self.lastInfo and self.lastInfo.id==id and self.lastInfo)
    if id~=self.selected then self.request=nil;self.progress=nil;self.meal=nil;self.generation=self.generation+1 end
    self.selected=id
    if info then self:Evidence(id);info.count,info.usable,info.status=self:Stock(id);self.lastInfo=info end
    self.inventory=info
end
function Food:Stop()
    self.request=nil;self.progress=nil;self.meal=nil;self.inventory=nil;self.pending=nil;self.observation=nil;self.blockedStart=nil;self.lastInfo=nil;self.itemRequests=nil;self.itemAttempts=nil;self.bagStock=nil
    self.generation=self.generation+1
    if self.events then self.events:UnregisterAllEvents() end
end
function Food:Sync()
    if not self:Enabled() then self:Stop();return end
    if self.profile~=K.profileGeneration or self.config~=self:Config() then
        self:Stop();self.profile=K.profileGeneration;self.config=self:Config()
    end
    if not self.events then
        self.events=CreateFrame("Frame")
        self.events:SetScript("OnEvent",function(_,event,id,ready)
            if not self:Enabled() then self:Stop();return end
            if event=="ITEM_DATA_LOAD_RESULT" or event=="GET_ITEM_INFO_RECEIVED" then
                local pending=self.pending
                local requested=self.itemRequests and self.itemRequests[id]
                if requested then self.itemRequests[id]=nil end
                if not requested and id~=self.selected and (not pending or id~=pending.id) then return end
                if pending and ready==true and id==pending.id and pending.profile==K.profileGeneration and pending.config==self:Config() then
                    local before=self:Config().itemID
                    if self:Select(id) and before~=id then
                        K.UI:Changed(F.settings or K.settings)
                        if pending.path then K.UsageDiagnostics:Emit("setting.buffReminder.food.itemID","change",pending.path,nil,true) end
                    end
                end
            elseif event=="PLAYER_STARTED_MOVING" or event=="PLAYER_REGEN_DISABLED" then
                self:CancelProgress();self.observation=nil;F:RefreshAlerts();return
            end
            if event=="BAG_UPDATE_DELAYED" then self.itemAttempts=nil end
            self.inventory=nil;self:Queue()
        end)
    end
    for _,event in ipairs({"BAG_UPDATE_DELAYED","ITEM_LOCK_CHANGED","ITEM_DATA_LOAD_RESULT","GET_ITEM_INFO_RECEIVED","PLAYER_REGEN_ENABLED","PLAYER_REGEN_DISABLED","PLAYER_STARTED_MOVING"}) do
        call(self.events.RegisterEvent,self.events,event)
    end
    if not self.inventory and call(InCombatLockdown)==false then self:RefreshInventory() end
end
function Food:RegisterAuras(registered)
    self:Sync()
end
function Food:CancelProgress()
    local p=self.progress or self.meal
    if p then self.blockedStart=p.start end
    self.progress=nil;self.meal=nil;self.request=nil
end
function Food:Click(action)
    local info=self.inventory
    if not self:Enabled() or self.dirty or call(InCombatLockdown)~=false or not info or not info.usable
        or action.item~=info.id or not self:Config().enabled or not ForeverBuffReminderDB.locked
        or K.PositionEditor.active or F.testMode then return end
    self.request={id=info.id,generation=self.generation,profile=K.profileGeneration,time=call(GetTime)}
    K.UsageDiagnostics:Emit("feature.food.request","request","click")
end
function Food:Alert(batch)
    if not self:Enabled() or F.testMode then return end
    local info=self.inventory or self.lastInfo
    if not info then return end
    local row=self:Verified(info.id)
    local observed=self:ReadObservation()
    local fed=observed.fed
    local eating=observed.eating
    -- Optional explicit spell mapping uses the same existing public aura batch.
    if row and batch and row.wellFedSpell then fed=batch[row.wellFedSpell] or fed end
    if row and batch and row.eatingSpell then eating=batch[row.eatingSpell] or eating end
    local now=call(GetTime)
    if fed and fed.state=="ACTIVE" then
        if self.meal and self.meal.attributed and number(now) and now-self.meal.start<=self.meal.seconds+3 then
            K.UsageDiagnostics:Emit("feature.food.well_fed","execute","unknown")
        end
        self.progress=nil;self.meal=nil;self.request=nil;return
    end
    if not self.inventory and (not eating or eating.state~="ACTIVE") then return end
    local request=self.request
    if row and eating and eating.state=="ACTIVE" and number(eating.duration) and number(eating.expirationTime) and number(now)
        and fed and fed.state=="MISSING" then
        local start=eating.expirationTime-eating.duration
        local attributed=request and request.id==info.id and request.generation==self.generation and request.profile==K.profileGeneration
            and number(request.time) and start>=request.time-.25 and start<=now and now-request.time<=3
        if start<=now and now-start<row.seconds and self.blockedStart~=start and (not self.progress or self.progress.start~=start) then
            -- A readable eating timestamp can restore the visual countdown even
            -- for a bag click/reload. Attribution metrics still require our request.
            self.progress={id=info.id,start=start,seconds=row.seconds,attributed=attributed and true or false}
            self.meal=self.progress
            if attributed then K.UsageDiagnostics:Emit("feature.food.used","execute","unknown");self.request=nil end
        end
    else self.progress=nil;self.meal=nil end
    if self.progress and (not number(now) or now-self.progress.start>=self.progress.seconds) then self.progress=nil end
    if not fed or fed.state~="MISSING" then self.progress=nil;self.meal=nil;return end
    return {key="food",state="FOOD",name=info.name,icon=info.icon,item=self.inventory and info.usable and not self.dirty and info.id or nil,
        status=info.status,progress=self.progress}
end
function Food:Summary()
    local info=self.inventory
    if self.message then return self.message end
    if self:Config().mode=="AUTO" and not info then return "검증된 자동 선택 음식이 없습니다." end
    -- Settings can show the selected item before enabling the runtime feature.
    -- Read only this item; do not register bag events or scan inventory while OFF.
    if not info and self:Config().mode=="MANUAL" then
        info=self:Info(self:Config().itemID)
        if info then
            local count=call(C_Item and C_Item.GetItemCount or GetItemCount,info.id,false,false,false)
            info.count=number(count) and count or 0
            info.status=self:Config().enabled and "상태 확인 중" or "음식 알림 OFF"
        end
    end
    if not info then return "음식 ID·링크를 입력하거나 가방 아이템을 입력칸에 끌어 놓으세요." end
    return info.name.." · "..tostring(info.count or 0).."개 · "..info.status..(not self:Verified(info.id) and " · 포만감 효과·시간 미확인" or "")
end
