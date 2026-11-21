local K,F=_G.KHQOL,_G.ForeverBuffReminder
local Food=F.Food
function Food:RefreshSummary()
    local panel=F.settings
    if not panel or not panel:IsVisible() or not panel.foodSummary then return end
    panel.foodSummary:SetText(self:Summary())
    local info=self.inventory
    panel.foodIcon:SetTexture(info and info.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
end
function Food:Settings(b)
    b:Section("음식·포만감")
    b:Checkbox("음식 알림 사용",function() return self:Config().enabled end,function(v)
        self:Config().enabled=v;self:Invalidate();F:RefreshAlerts()
    end)
    b:Dropdown("음식 선택",{{value="MANUAL",text="지정 음식"},{value="AUTO",text="자동 선택"}},
        function() return self:Config().mode end,function(v) self:Config().mode=v;self:Invalidate();F:RefreshAlerts() end)
    local input=b:Edit("지정 음식 ID / 링크",function() return self:Config().itemID>0 and tostring(self:Config().itemID) or "" end,
        function(v) self:Select(v,"input");F:RefreshAlerts() end)
    input:SetScript("OnReceiveDrag",function()
        if K.PublicCall(InCombatLockdown)~=false or self:Config().mode=="AUTO" then return end
        local kind,id=K.PublicCall(GetCursorInfo)
        if kind=="item" then
            K.UsageDiagnostics:Begin(input,"drag")
            local accepted=self:Select(id,"drag")
            K.UsageDiagnostics:Finish(input)
            if accepted then K.UI:Changed(F.settings);K.PublicCall(ClearCursor);F:RefreshAlerts();F:RefreshSettings() end
        end
    end)
    b:Dropdown("섭취 진행 방향",{{value="VERTICAL",text="위 → 아래"},{value="HORIZONTAL",text="왼쪽 → 오른쪽"}},
        function() return self:Config().direction end,function(v) self:Config().direction=v;F:RefreshAlerts() end)
    b:Dropdown("음식 아이콘 위치",{{value="ABOVE",text="포만감 위"},{value="BELOW",text="포만감 아래"}},
        function() return self:Config().placement end,function(v) self:Config().placement=v;F:RefreshAlerts() end)
    local preview=CreateFrame("Frame",nil,F.settings);preview:SetSize(F.settings:GetWidth(),38)
    preview.icon=preview:CreateTexture(nil,"ARTWORK");preview.icon:SetPoint("TOPLEFT",0,-4);preview.icon:SetSize(28,28)
    local summary=K.UI:CreateDescription(preview,self:Summary(),38,-4)
    b:Block(preview,function()
        summary:SetWidth(math.max(40,preview:GetWidth()-42));summary:SetText(self:Summary())
        local info=self.inventory or self:Config().mode=="MANUAL" and self:Info(self:Config().itemID)
        preview.icon:SetTexture(info and info.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        return math.max(38,summary:GetStringHeight()+10)
    end)
    b:Description("잠긴 음식 아이콘을 좌클릭해 사용합니다. 자동 선택은 확인된 처치 경험치 5% 음식만 고릅니다. 실제 섭취 진행은 기본 포만감 아이콘에 표시합니다.",true)
    if F.settings then F.settings.foodSummary=summary;F.settings.foodIcon=preview.icon end
end
function Food:Render(frame,alert)
    local progress=alert and alert.progress
    if not progress then
        if frame.foodProgress then frame.foodProgress.progress=nil;frame.foodProgress:Hide();frame.foodProgress:SetScript("OnUpdate",nil) end
        return
    end
    local overlay=frame.foodProgress
    if not overlay then
        overlay=CreateFrame("Frame",nil,frame);overlay:SetAllPoints(frame);overlay:EnableMouse(false)
        overlay.fill=overlay:CreateTexture(nil,"OVERLAY");overlay.fill:SetColorTexture(.15,.7,1,.45)
        frame.foodProgress=overlay
        frame:HookScript("OnHide",function()
            overlay:SetScript("OnUpdate",nil);overlay:Hide()
            if overlay.progress and Food.progress==overlay.progress then Food.progress=nil;Food.meal=nil end
            overlay.progress=nil
        end)
    end
    local function draw()
        local now=K.PublicCall(GetTime)
        if Food.progress~=progress or not K.IsPublicNumber(now) then
            if Food.progress==progress then Food.progress=nil;Food.meal=nil end
            overlay:SetScript("OnUpdate",nil);overlay:Hide();return
        end
        local fraction=math.max(0,math.min(1,(now-progress.start)/progress.seconds))
        if fraction>=1 then
            Food.progress=nil;overlay:SetScript("OnUpdate",nil);overlay:Hide();frame.time:SetText("");return
        end
        local w,h=frame:GetSize()
        overlay.fill:ClearAllPoints();overlay.fill:SetPoint("TOPLEFT",frame,"TOPLEFT",0,0)
        overlay.fill:SetSize(Food:Config().direction=="HORIZONTAL" and w*fraction or w,
            Food:Config().direction=="VERTICAL" and h*fraction or h)
        frame.time:SetText(tostring(math.max(1,math.ceil(progress.seconds-(now-progress.start)))))
    end
    overlay.progress=progress
    overlay:Show();draw();overlay:SetScript("OnUpdate",overlay:IsShown() and Food.progress==progress and draw or nil)
end
