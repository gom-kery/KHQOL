local _, KHQOL = ...
local CursorTrail=KHQOL.modules.cursorTrail
function CursorTrail:BuildSettings(content,y)
  local b,db=KHQOL.UI:CreateBuilder(content,y),self:GetDB()
  b:Section("잔상 모양")
  b:Slider("잔상 길이",1,40,1,function() return db.length end,function(v) db.length=v; self:EnsurePool() end,tostring,nil,"화면에 동시에 표시할 수 있는 최대 잔상 포인트 수입니다.")
  b:Slider("크기",4,32,1,function() return db.size end,function(v) db.size=v; self:ApplyAppearance() end,tostring,nil,"머리의 크기입니다. 꼬리로 갈수록 가늘어집니다.")
  b:Color("색상",function() local c=self:GetColor(); return c.r,c.g,c.b end,function(r,g,bl) self:SetColor(r,g,bl) end,nil,function() return self:CaptureColorRestore() end)
  b:Slider("투명도",.10,1,.05,function() return db.alpha end,function(v) db.alpha=v; self:ApplyAppearance() end,function(v) return string.format("%d%%",v*100+.5) end)
  b:Section("고급 / 잔상 동작")
  b:Slider("포인트 간격",1,20,.5,function() return db.spacing end,function(v) self:SetSpacing(v) end,function(v) return string.format("%.1f",v) end,nil,"작을수록 촘촘해집니다. 같은 잔상 길이에서는 전체 꼬리가 짧아집니다.")
  b:Slider("유지 시간",.10,2,.05,function() return db.duration end,function(v) db.duration=v; self:ApplyAppearance() end,function(v) return string.format("%.2f초",v) end,nil,"잔상이 완전히 사라질 때까지의 시간입니다.")
  return b.y
end
