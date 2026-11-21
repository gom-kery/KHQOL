local K=_G.KHQOL
local E=K.modules.environmentTimer
E.defaults.shieldHUDSide="left"
E.defaults.shieldCombat=true
E.defaults.hudTextColors={}
function E:CanEdit()
  return self.unlocked==true and K.PublicCall(InCombatLockdown)==false
end
function E:HUDSlots(items)
  local present={};for _,item in ipairs(items) do present[item.timer]=true end
  local out,lanes={},{left=0,right=0}
  for _,timer in ipairs(self.order) do
    if present[timer] then
      local side=self.shieldKeys[timer] and self.db.shieldHUDSide or timer=="EXHAUSTION" and "right" or "left"
      out[timer]={side=side,lane=lanes[side]};lanes[side]=lanes[side]+1
    end
  end
  return out
end
function E:HUDSpacing()
  return self.db.hudSize*128/420*(self.db.hudThickness/8)*.86+12
end
function E:HUDTextDefault(timer,slots)
  local db=self.db
  local slot=(slots or self.hudSlots or {})[timer] or {side=self.shieldKeys[timer] and db.shieldHUDSide or "left",lane=0}
  local sign=slot.side=="left" and -1 or 1
  return sign*(db.hudGap/2+db.hudThickness+db.hudSize*.12+slot.lane*self:HUDSpacing()),
    -db.hudSize/2-24-slot.lane*(db.hudTextSize*3+24)
end
function E:TextEditTimer()
  if not self.names[self.textEditTimer] then self.textEditTimer="BREATH" end
  return self.textEditTimer
end
function E:TextPosition(timer)
  local p=self.db.hudTextPositions[timer]
  local x,y=self:HUDTextDefault(timer)
  return p and K.IsPublicNumber(p.x) and p.x or x,p and K.IsPublicNumber(p.y) and p.y or y
end
function E:BuildTextSettings(b,content)
  local UI=K.UI
  local function edit() return self:IsEnabled() and self.db.style=="hud" and self:CanEdit() end
  local choices={};for _,id in ipairs(self.order) do choices[#choices+1]={value=id,text=self.names[id]} end
  b:Dropdown("편집할 텍스트",choices,function() return self:TextEditTimer() end,function(v)
    UI:CloseColorPicker();UI:CancelInputs(content);self.textEditTimer=v;UI:Refresh(content)
  end,edit)
  b:Flush()
  for _,axis in ipairs({"x","y"}) do
    local key=axis
    b:Slider("HUD 텍스트 "..key:upper().." 위치",-3000,3000,1,function()
      local x,y=self:TextPosition(self:TextEditTimer());return key=="x" and x or y
    end,function(v)
      local id=self:TextEditTimer();local x,y=self:TextPosition(id)
      self.db.hudTextPositions[id]={x=key=="x" and v or x,y=key=="y" and v or y};self:Changed()
    end,function(v) return string.format("%.0f px",v) end,edit)
  end
  b:Color("HUD 텍스트 색상",function()
    return unpack(self.db.hudTextColors[self:TextEditTimer()] or {.1,.75,.9,1})
  end,function(r,g,bl,a)
    self.db.hudTextColors[self:TextEditTimer()]={r,g,bl,a or 1};self:Changed()
  end,edit,function()
    local db,id,generation=self.db,self:TextEditTimer(),K.profileGeneration
    local original=db.hudTextColors[id] and K.CopyProfileValue(db.hudTextColors[id])
    return function()
      if self.db==db and K.profileGeneration==generation then db.hudTextColors[id]=original;self:Changed() end
    end
  end,true)
  local reset
  reset=b:Button("선택 텍스트 초기화",function()
    K.UsageDiagnostics:Begin(reset,"click")
    local id=self:TextEditTimer();self.db.hudTextPositions[id]=nil;self.db.hudTextColors[id]=nil;self:Changed()
    K.UsageDiagnostics:Finish(reset)
  end,nil,edit)
  UI.SettingsNavigation:Attach(content,reset,"선택 텍스트 초기화",function()
    local id=self:TextEditTimer();local p=self.db.hudTextPositions[id];local c=self.db.hudTextColors[id]
    return p and p.x,p and p.y,c and table.concat(c,",")
  end)
  b:Description("위치 잠금을 해제하면 텍스트별 테두리를 드래그하거나 대상을 골라 좌표·색상을 바꿀 수 있습니다. 색상을 고르면 고정 색상, 초기화하면 상태별 색상으로 돌아갑니다. 전투 중에는 편집 테두리만 숨깁니다.",true)
end
