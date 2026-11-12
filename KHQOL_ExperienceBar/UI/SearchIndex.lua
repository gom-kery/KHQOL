local K=_G.KHQOL
local N=K.UI.SettingsNavigation
for _,title in ipairs({"완료 퀘스트 경험치 표시","예상 경험치 색상","예상 경험치 수치 표시","레벨업 예상 표시"}) do
  N:Register({module="experienceBar",scope="현재 프로필",section="완료 퀘스트 경험치 미리보기"},title)
end
N:Register({module="experienceBar",scope="현재 프로필",section="위치"},"위치 잠금")
N:Register({module="experienceBar",scope="현재 프로필",section="위치"},"위치 기본값 복원")
N:Register({module="experienceBar",scope="현재 프로필",section="PlayerFrame 감싸기"},"위치 기본값 복원")
