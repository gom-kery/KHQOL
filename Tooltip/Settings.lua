local _, KHQOL = ...
local Tooltip = KHQOL.modules.tooltip
function Tooltip:BuildSettings(content,y)
  local b,db=KHQOL.UI:CreateBuilder(content,y),self:GetDB()
  b:Checkbox("마우스 오른쪽에 표시",function() return db.mouseRight==true end,function(v) db.mouseRight=v end)
  b:Section("Information")
  b:Checkbox("플레이어 전문화 정보 표시",function() return db.showPlayerInfo~=false end,function(v)
    db.showPlayerInfo=v
    if not v and self.playerInfo then self.playerInfo:Cancel(true) end
    self:RefreshUnitTooltip()
  end)
  b:Description("아군 플레이어 Tooltip에 전문화와 현재 착용 장비 평균 아이템 레벨을 표시합니다.")
  b:Checkbox("전투 중 대상 툴팁 숨기기",function() return db.hideUnitTooltipInCombat==true end,function(v) db.hideUnitTooltipInCombat=v end)
  b:Checkbox("무기 전문가 정보",function() return db.weaponGuide~=false end,function(v) db.weaponGuide=v end)
  b:Section("Position")
  b:Slider("X 위치",-150,150,1,function() return db.x or 0 end,function(v) db.x=v end,function(v) return (v>0 and "+" or "")..v end,function() return db.mouseRight==true end)
  b:Slider("Y 위치",-150,150,1,function() return db.y or 0 end,function(v) db.y=v end,function(v) return (v>0 and "+" or "")..v end,function() return db.mouseRight==true end)
  b:Button("위치 초기화",function() db.x=0; db.y=0 end,120)
  b:Section("General")
  b:Slider("표시 유지 시간",-1.5,1.5,.5,function() return db.holdTimeOffset or 0 end,function(v) db.holdTimeOffset=v; self:ApplyHoldTime() end,function(v) return v==0 and "기본" or (v>0 and "+" or "")..string.format("%.1f초",v) end,nil,"기본값 0을 기준으로 -1.5초 ~ +1.5초까지 조절합니다.")
  b:Section("Appearance")
  b:Slider("텍스트 크기",-3,3,1,function() return db.textSize end,function(v) db.textSize=v; self:RefreshVisibleTooltip() end,function(v) return v==0 and "기본" or (v>0 and "+" or "")..v end,nil,"기본 Tooltip 글자 크기에서 -3 ~ +3만 조정합니다.")
  b:Checkbox("체력바 표시",function() return db.showHealthBar~=false end,function(v) db.showHealthBar=v; self:ConfigureHealthBar() end)
  return b.y
end
