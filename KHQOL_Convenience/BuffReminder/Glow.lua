local FBR=_G.ForeverBuffReminder
local K=_G.KHQOL

-- Plain textures use the same drawing API as the existing expiring border.
-- No library, mask, secure frame or permanent updater is required.
function FBR:StopMissingGlow(frame)
    if not frame.missingGlow then return end
    frame.missingGlow:SetScript("OnUpdate",nil)
    frame.missingGlow:Hide();frame.missingGlow.key=nil
end

function FBR:MissingGlow(frame,alert)
    local db=ForeverBuffReminderDB
    if alert.noGlow or alert.state~="MISSING" or db.glowType~="PIXEL" then self:StopMissingGlow(frame);return end
    local glow=frame.missingGlow
    if not glow then
        glow=CreateFrame("Frame",nil,frame);glow:SetAllPoints(frame)
        glow:EnableMouse(false);glow.parts={}
        for i=1,4 do glow.parts[i]=glow:CreateTexture(nil,"OVERLAY",nil,7) end
        glow.elapsed=0;frame.missingGlow=glow
        frame:HookScript("OnHide",function() FBR:StopMissingGlow(frame) end)
    end
    if glow.key~=alert.key then self:StopMissingGlow(frame);glow.elapsed=0 end
    glow.key=alert.key
    local c=db.glowColor
    for _,part in ipairs(glow.parts) do part:SetColorTexture(c[1],c[2],c[3],c[4]) end
    glow:Show()
    local function draw(_,elapsed)
        local w,h=frame:GetWidth(),frame:GetHeight()
        if not K.IsPublicNumber(w) or not K.IsPublicNumber(h) or w<=0 or h<=0 then return end
        glow.elapsed=(glow.elapsed+elapsed)%4
        local perimeter=2*(w+h)
        for i,part in ipairs(glow.parts) do
            local p=(glow.elapsed/4*perimeter+(i-1)*perimeter/4)%perimeter
            local length=math.max(2,math.min(w,h)/3)
            local x,y,pw,ph
            if p<w then x,y,pw,ph=p,2,math.min(length,w-p),2
            elseif p<w+h then x,y,pw,ph=w,-(p-w),2,math.min(length,w+h-p)
            elseif p<2*w+h then x,y,pw,ph=2*w+h-p,-h,math.min(length,2*w+h-p),2;x=x-pw
            else x,y,pw,ph=-2,-(perimeter-p),2,math.min(length,perimeter-p);y=y+ph end
            part:ClearAllPoints();part:SetPoint("TOPLEFT",frame,"TOPLEFT",x,y);part:SetSize(math.max(.1,pw),math.max(.1,ph))
        end
    end
    -- Refreshing a visible icon retains phase and reuses its four textures.
    draw(glow,0);glow:SetScript("OnUpdate",draw)
end
