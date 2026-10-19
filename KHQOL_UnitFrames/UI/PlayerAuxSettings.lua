local K=assert(_G.KHQOL)
local A=K.PlayerAux
function A:BuildSettings(parent,y,builder)
 local UI=K.UI;local b=builder or UI:CreateBuilder(parent,y)
 parent.settingsRoute={module="unitFrames",unit="player",part="class"}
 local function db() return A:GetDB() end
 local function change(key,v) db()[key]=v;A:Initialize() end
 b:Section("탄약")
 b:Checkbox("탄약 표시",function() return A:IsAmmoClass() and db().showAmmo end,function(v) change("showAmmo",v) end,function() return A:IsAmmoClass() end)
 b:Description("탄약을 사용하는 직업·장착 무기에서 소지 수량을 표시합니다. 은행은 제외합니다. 탄약 사용 조건을 확인할 수 없으면 숨깁니다.",true)
 b:Section("영혼의 조각")
 b:Checkbox("영혼의 조각 표시",function() return A:IsWarlock() and db().showSoulShards end,function(v) change("showSoulShards",v) end,function() return A:IsWarlock() end)
 local function shards() return A:IsWarlock() and db().showSoulShards end
 b:Checkbox("영혼의 조각 문구 표시",function() return db().showSoulShardLabel end,function(v) change("showSoulShardLabel",v) end,shards)
 b:Edit("최대 보관 수량",function() return A:GetShardLimit() end,function(v)
  local ok,message=A:SetShardLimit(v)
  if not ok and DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("KHQOL: "..(message or "수량을 확인하세요.")) end
 end,shards)
 b:Description("보조 표시 위치 잠금 ON · 비전투에서 아이콘 좌클릭으로 초과 조각 1개를 확인창 없이 파괴하고, 숫자 우클릭으로 최대 수량을 바꿉니다. 최대 수량은 일반·영혼 가방 전체 칸 수 이내입니다.",true)
 b:Section("보조 표시 위치")
 local function available() return A:CanShowAux() end
 b:Checkbox("보조 표시 위치 잠금",function() return db().ammoLocked end,function(v) change("ammoLocked",v) end,available)
 b:Button("보조 표시 위치 초기화",function()
  local d=db();d.ammoPoint,d.ammoRelativePoint,d.ammoX,d.ammoY="CENTER","CENTER",0,-120;A:ApplyPosition()
 end,nil,available)
 for _,axis in ipairs({"X","Y"}) do
  local a=axis
  b:Slider("보조 표시 "..a.." 좌표",-3000,3000,1,function() return db()["ammo"..a] end,function(v) change("ammo"..a,v) end,function(v) return v.." px" end,available)
 end
 b:Slider("보조 표시 글자 크기",8,24,1,function() return db().ammoTextSize end,function(v) change("ammoTextSize",v) end,function(v) return v.." px" end,available)
 b:Description("탄약과 영혼의 조각은 직업에 따라 같은 위치를 사용합니다. 위치 잠금 OFF에서 표시를 드래그합니다. 자원/스윙바 사용 여부와 독립적으로 동작합니다.",true)
 b:Flush();return -b.y
end
