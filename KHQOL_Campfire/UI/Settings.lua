local KHQOL=_G.KHQOL
local UI=KHQOL.UI
local function campfireSettings(content,y)
  local cfa=KHQOL.modules.campfire
  local b=UI:CreateBuilder(content,y)
  b:Section("알림 간격")
  b:Slider("야영 효과 획득 후 재알림 지연",0,300,5,function() return cfa.db.rediscoveryDelay or 30 end,function(v) cfa.db.rediscoveryDelay=v; if cfa.benefitAcquiredAt then cfa:ScheduleRediscovery() end end,function(v) return v.."초" end)
  b:Description("야영 효과를 얻은 뒤 이 시간 동안 모닥불 발견 알림을 숨깁니다. 기본값 30초이며, 0초에서도 획득 메시지는 3초간 유지합니다.")
  b:Section("위치")
  b:Checkbox("위치 잠금",function() return cfa.db.locked end,function(on)
    cfa.db.locked=on
    if on then cfa:HideDiscovery()
    else cfa.ui.discovery:Show(); cfa.ui.complete:Hide(); cfa:ApplyLayout() end
  end)
  b:Description("위치 잠금을 해제하면 아이콘과 문구를 미리 보고 드래그로 이동할 수 있습니다.")
  b:Button("위치 초기화",function()
    cfa.db.position={point="CENTER",x=0,y=80}
    cfa.ui.root:ClearAllPoints(); cfa.ui.root:SetPoint("CENTER",UIParent,"CENTER",0,80)
  end)
  b:Section("알림 모양")
  b:Slider("아이콘 크기",100,140,5,function() return cfa.db.iconSize end,function(v) cfa.db.iconSize=v; cfa:ApplyLayout() end,function(v) return v.." px" end)
  b:Slider("글자 크기",40,70,5,function() return cfa.db.fontSize end,function(v) cfa.db.fontSize=v; cfa:ApplyLayout() end,function(v) return v.." px" end)
  b:Section("알림 문구")
  local input=b:Edit("표시할 문구",function() return cfa.db.message or "모닥불 발견!" end,function(v) cfa.db.message=v; cfa:ApplyLayout() end)
  b:Button("적용",function() cfa.db.message=input:GetText(); input:ClearFocus(); cfa:ApplyLayout() end,86)
  b:Description("Enter·다른 항목 클릭 또는 적용 버튼으로 문구를 반영합니다. ESC는 입력 중인 내용을 취소합니다.",true)
  return b.y
end

KHQOL.AlertSettings:RegisterTab("campfire",nil,campfireSettings)
