local K,F=_G.KHQOL,_G.ForeverBuffReminder
local S={};F.Sleep=S
local call,number=K.PublicCall,K.IsPublicNumber
local colors={{.95,.72,.15},{.20,.75,.65},{.65,.45,.95}}
function S:Enabled()
  return K:GetEnabled("buffReminder") and F:CommonConfig().rested and ForeverBuffReminderDB.sleepingBag.enabled and not F.testMode
end
function S:StopProgress()
  self.state=nil;self.phase=nil;self.previous=nil;self.lastStack=nil;self.moving=nil
  self.lastObservedCount=nil
  if self.completeTimer then self.completeTimer:Cancel();self.completeTimer=nil end
  if self.complete then self.complete:Hide() end
  if self.frame then self.frame:Hide() end
end
function S:HideExpiry()
  if self.expiryMessageTimer then self.expiryMessageTimer:Cancel();self.expiryMessageTimer=nil end
  if self.expiryMessage then self.expiryMessage:Hide() end
end
function S:Stop()
  self:StopProgress();self:HideExpiry()
end
function S:ReadCount(batch)
  local fed=batch and batch[429959]
  if fed and fed.state=="MISSING" then return 0 end
  if fed and fed.state=="ACTIVE" and number(fed.applications) and fed.applications>=1 and fed.applications<=3 then return fed.applications end
end
function S:ShowMessage(key,text,color)
  if not self[key] then
    local frame=CreateFrame("Frame",nil,UIParent);frame:SetSize(600,100);frame:SetFrameStrata("HIGH");frame:EnableMouse(false)
    frame.label=frame:CreateFontString(nil,"OVERLAY");frame.label:SetAllPoints()
    frame.label:SetFont(K.UI:Font(),46,"THICKOUTLINE");self[key]=frame
  end
  local frame=self[key];local timerKey=key.."Timer"
  frame.label:SetTextColor(unpack(color));frame.label:SetText(text)
  local camp=K.modules.campfire
  K.PositionUtils.ApplyPoint(frame,camp and camp.db and camp.db.completePosition or {point="CENTER",x=0,y=80})
  frame:Show()
  if self[timerKey] then self[timerKey]:Cancel() end
  self[timerKey]=C_Timer.NewTimer(3,function()
    self[timerKey]=nil
    if self[key] then self[key]:Hide() end
  end)
end
function S:ShowComplete()
  self:ShowMessage("complete","침낭 버프 획득",{.15,1,.25})
end
function S:UpdateExpiry(batch,schedule)
  local cfg=ForeverBuffReminderDB.sleepingBag
  if not K:GetEnabled("buffReminder") or not F:CommonConfig().rested or not cfg.expiryAlert or F.testMode then
    self:HideExpiry();return
  end
  local generation=K.profileGeneration or 0
  if self.expiry and self.expiry.profile~=generation then self.expiry=nil;self:HideExpiry() end
  local aura=batch and batch[429959]
  if aura and aura.state=="MISSING" then self.expiry=nil;self:HideExpiry();return end
  -- Never infer an expiry deadline from unreadable auras, stack estimates or bag use.
  if not aura or aura.state~="ACTIVE" or not number(aura.expirationTime) then return end
  local now=call(GetTime);if not number(now) or aura.expirationTime<=now then return end
  local expires=aura.expirationTime
  if not self.expiry or expires>self.expiry.expires+1 then
    self:HideExpiry()
    self.expiry={profile=generation,expires=expires,warned=false}
  else self.expiry.expires=expires end
  local remaining=expires-now
  if remaining>120 then schedule(remaining-120)
  elseif not self.expiry.warned then
    self.expiry.warned=true
    self:ShowMessage("expiryMessage","침낭 버프가 2분 이내에 만료됩니다.",{1,.65,.15})
  end
end
function S:Movement(moving)
  self.moving=moving;self.phase=nil;self.previous=nil
end
function S:Update(batch,schedule)
  self:UpdateExpiry(batch,schedule)
  if not self:Enabled() then self:StopProgress();return end
  local rest,fed=batch[1331671],batch[429959]
  local count=self:ReadCount(batch)
  if count==3 and self.lastObservedCount and self.lastObservedCount<3 then self:ShowComplete() end
  if count then self.lastObservedCount=count end
  if not rest or rest.state~="ACTIVE" then
    self.state=nil;self.phase=nil;self.lastStack=nil
    if rest and rest.state=="MISSING" then self.previous=false else self.previous=nil end
    if self.frame then self.frame:Hide() end
    return
  end
  local now=call(GetTime)
  if not number(now) then self.state=nil;self.phase=nil;return end
  local changed=count and self.lastStack and count~=self.lastStack
  if self.moving then self.phase=nil
  elseif count and count<3 then
    if rest.duration==60 and number(rest.expirationTime) and rest.expirationTime>now then
      self.phase={start=rest.expirationTime-60,finish=rest.expirationTime,estimated=false}
    elseif self.previous==false or changed then
      -- Indefinite Resting auras expose no minute deadline. Anchor an estimate
      -- only to observed entry/actual stack changes, never to a click or reload.
      self.phase={start=now,finish=now+60,estimated=true}
    end
  else self.phase=nil end
  self.previous=true;self.lastStack=count
  self.state={count=count,moving=self.moving,phase=self.phase,now=now}
  if count and count<3 and self.phase and now<self.phase.finish and not self.moving then schedule(1) end
end
function S:Render(bottom,size)
  local state=self.state
  if not state or state.count==3 or not self:Enabled() then if self.frame then self.frame:Hide() end;return end
  if not self.frame then
    local frame=CreateFrame("Frame",nil,F.alertContainer);frame:EnableMouse(false)
    frame:SetSize(210,36);frame.segments={}
    for i=1,3 do
      local bar=CreateFrame("StatusBar",nil,frame)
      bar:SetSize(68,10);bar:SetPoint("TOPLEFT",(i-1)*71,0)
      bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8");bar:SetMinMaxValues(0,1)
      bar:SetStatusBarColor(unpack(colors[i]))
      bar.background=bar:CreateTexture(nil,"BACKGROUND");bar.background:SetAllPoints();bar.background:SetColorTexture(.12,.12,.12,.9)
      frame.segments[i]=bar
    end
    frame.label=frame:CreateFontString(nil,"OVERLAY");frame.label:SetFont(K.UI:Font(),12,"OUTLINE")
    frame.label:SetPoint("TOP",frame,"TOP",0,-14);frame.label:SetWidth(300)
    self.frame=frame
  end
  local frame=self.frame;local count=state.count
  local phase=state.phase;local fraction=phase and math.max(0,math.min(1,(state.now-phase.start)/60)) or 0
  for i,bar in ipairs(frame.segments) do
    bar:SetValue(count and (i<=count and 1 or i==count+1 and fraction or 0) or 0)
  end
  local label=(count and tostring(count) or "?").."/3중첩"
  if state.moving then label=label.." · 휴식 중단"
  elseif count==3 then label=label.." · 완료"
  elseif not count then label=label.." · 중첩 확인 불가"
  elseif not phase then label=label.." · 다음 중첩 확인 중"
  elseif state.now>=phase.finish then label=label.." · 서버 중첩 갱신 대기"
  else
    local remaining=math.ceil(phase.finish-state.now)
    label=label.." · 다음 중첩까지 "..(phase.estimated and "약 " or "")..string.format("%02d:%02d",math.floor(remaining/60),remaining%60)
  end
  frame.label:SetText(label);frame:ClearAllPoints()
  frame:SetPoint("TOP",F.alertContainer,"CENTER",0,bottom-size-20);frame:Show()
end
