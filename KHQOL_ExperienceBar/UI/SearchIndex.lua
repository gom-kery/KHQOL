local K=_G.KHQOL
local N=K.UI.SettingsNavigation
for _,title in ipairs({"완료 퀘스트 경험치 표시","예상 경험치 색상","레벨업 예상 표시"}) do
  N:Register({module="experienceBar",scope="현재 프로필",section="퀘스트 완료 예상 경험치"},title)
end
for _,title in ipairs({"레벨 배치","레벨 위치","레벨 표시 문구"}) do
  N:Register({module="experienceBar",scope="현재 프로필",section="텍스트"},title)
end
N:Register({module="experienceBar",scope="현재 프로필",section="위치"},"위치 잠금")
N:Register({module="experienceBar",scope="현재 프로필",section="위치"},"위치 기본값 복원")
