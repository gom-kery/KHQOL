local K=_G.KHQOL
local N=K.UI.SettingsNavigation
N:Register({module="objectHighlight"},"강조 Y 위치")
N:Register({module="objectHighlight"},"강조 X 위치")
N:Register({module="objectHighlight"},"강조 위치 초기화")
N:Register({module="buffReminder",scope="현재 프로필",section="위치"},"위치 잠금")
N:Register({module="buffReminder",scope="현재 프로필",section="알림 모양"},"정렬 방향")
N:Register({module="buffReminder",scope="현재 프로필",section="알림 모양"},"아이콘 크기")
N:Register({module="buffReminder",scope="현재 프로필",section="버프 설정"},"직업 선택")
for _,title in ipairs({"퀘스트 오브젝트 반짝임 유지","채집 오브젝트 강조 사용","약초 강조","약초 효과","광맥 강조","광맥 효과","보물상자 강조","보물상자 효과","강조 크기","강조 투명도","전투 중 강조 표시"}) do
  N:Register({module="objectHighlight"},title)
end
