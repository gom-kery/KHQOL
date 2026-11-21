local K=_G.KHQOL
local N=K.UI.SettingsNavigation
N:Register({module="objectHighlight"},"강조 Y 위치")
N:Register({module="objectHighlight"},"강조 X 위치")
N:Register({module="objectHighlight"},"강조 위치 초기화")
for _,title in ipairs({"채집 오브젝트 강조 사용","약초 강조 사용","채광 강조 사용","보물상자 강조 사용","약초 강조","채광 강조","보물상자 강조","약초 색상","채광 색상","보물상자 색상","강조 크기","강조 투명도","전투 중 강조 표시"}) do
  N:Register({module="objectHighlight"},title)
end
