local _,K=...
K = assert(_G.KHQOL, "Install and enable the KHQOL core addon.")
local M=K.modules.partyFrames
local call=K.PublicCall
local required={"SetEnabled","SetUnit","SetMaxBuffs","SetMaxDebuffs","SetSmallAuraSize","SetLargeAuraSize","SetDebuffFilterString", "SetTargetIsFriendly","SetFlowLayoutSpacing","SetConstrainedFlowLayoutLineSize","SetNumConstrainedFlowLayoutLines","SetFlowLayoutMirroredVertically"}
M.debuffPositions={{value="BOTTOM",text="아래"},{value="TOP",text="위"},{value="LEFT",text="왼쪽"},{value="RIGHT",text="오른쪽"},{value="CENTER",text="프레임 안"}}
function M:AnchorDebuffs(f,b,cfg,ratio)
  ratio=ratio or 1
  local p,x,y,edge=cfg.position,cfg.x/ratio,cfg.y/ratio,2/ratio;f:ClearAllPoints()
  if p=="TOP" then f:SetPoint("BOTTOMLEFT",b,"TOPLEFT",x,y+edge)
  elseif p=="LEFT" then f:SetPoint("TOPRIGHT",b,"TOPLEFT",x-edge,y)
  elseif p=="RIGHT" then f:SetPoint("TOPLEFT",b,"TOPRIGHT",x+edge,y)
  elseif p=="CENTER" then f:SetPoint("CENTER",b,"CENTER",x,y)
  else f:SetPoint("TOPLEFT",b,"BOTTOMLEFT",x,y-edge) end
end
function M:StyleDebuffs(b)
  local cfg=self.visual.debuffs;local f=b.khqolDebuffs
  if not cfg.enabled then if f then call(f.SetEnabled,f,false) end;return end
  local filtered=self:StyleFilteredDebuffs(b,cfg)
  if filtered then
    if f and f~=filtered then call(f.SetEnabled,f,false) end
    b.khqolDebuffs=filtered;b.khqolDebuffsReady=true;self:SyncDebuffUnit(b);return
  end
  if b.khqolFilteredDebuffs then call(b.khqolFilteredDebuffs.SetEnabled,b.khqolFilteredDebuffs,false) end
  f=b.khqolNativeDebuffs
  local ok=pcall(function()
    if not f then
      -- Reuse the native secure-partition container. Addon Lua never receives
      -- aura records, enumerates aura slots, or reads secret container bounds.
      f=CreateFrame("AuraContainer",nil,b,"KHQOLPartyNativeAuraLayoutTemplate");b.khqolNativeDebuffs=f
    end
    for _,name in ipairs(required) do assert(type(f[name])=="function",name) end
    f:SetMaxBuffs(0);f:SetMaxDebuffs(cfg.count)
    f:SetDebuffFilterString("HARMFUL");f:SetTargetIsFriendly(true)
    f:SetSmallAuraSize(cfg.size);f:SetLargeAuraSize(cfg.size)
    f:SetFlowLayoutSpacing(cfg.gap,cfg.gap)
    f:SetConstrainedFlowLayoutLineSize(cfg.perRow*cfg.size+(cfg.perRow-1)*cfg.gap)
    f:SetNumConstrainedFlowLayoutLines(12);f:SetFlowLayoutMirroredVertically(cfg.position=="TOP")
    self:AnchorDebuffs(f,b,cfg)
    f:SetFrameLevel(b:GetFrameLevel()+5)
  end)
  if not ok then
    if f then call(f.SetEnabled,f,false) end
    b.khqolDebuffsReady=nil
    self:SetFeatureReason("debuffs","디버프 표시를 위한 게임 기본 표시기 API를 확인할 수 없습니다.")
    return
  end
  b.khqolDebuffsReady=true
  b.khqolDebuffs=f
  self:SyncDebuffUnit(b)
end
function M:SyncDebuffUnit(b)
  local f=b.khqolDebuffs;if not f then return end
  local unit=self:ReadUnit(b)
  local enabled=self.applied and self.visual and self.visual.debuffs.enabled and b.khqolDebuffsReady and unit and call(b.IsVisible,b)==true
  if not enabled then call(f.SetEnabled,f,false);return end
  local ok=pcall(function() f:SetUnit(unit);f:SetEnabled(true) end)
  if not ok then call(f.SetEnabled,f,false);self:SetFeatureReason("debuffUnit","현재 유닛의 디버프 표시 적용이 보류되었습니다.") end
end
