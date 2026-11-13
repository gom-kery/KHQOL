local K=_G.KHQOL
local N=K.UI.SettingsNavigation
N:Register({module="general",scope="현재 프로필",section="전역 설정"},"중앙 알림 텍스트 크기")
N:Register({module="convenienceChat"},"기본 대화창 편의")
for _,title in ipairs({"Alt+좌클릭 파티 초대","말머리 사용","일반 말머리 (최대 10글자)","파티 말머리 (최대 10글자)","길드 말머리 (최대 10글자)","공격대 말머리 (최대 10글자)","말머리 초기화","파티 자동 인사","공격대 자동 인사","인사말 (캐릭터별 저장 · 최대 255바이트)"}) do
  N:Register({module="convenienceChat"},title)
end
N:Register({module="generalConvenience"},"아이템 파괴 자동 입력")
N:Register({module="generalConvenience"},"잡템 자동 판매")
N:Register({module="generalConvenience"},"자동 수리")
N:Register({module="generalConvenience"},"길드 자금 우선 사용")
N:Register({module="generalConvenience"},"이미 습득한 아이템 표시")
  N:Register({module="generalConvenience"},"착용 아이템 레벨 표시")
N:Register({module="generalConvenience"},"도안")
N:Register({module="generalConvenience"},"탈것")
N:Register({module="generalConvenience"},"가방")
N:Register({module="generalConvenience"},"상점")
N:Register({module="generalConvenience"},"결투 요청")
N:Register({module="generalConvenience"},"거절 채팅 알림")
N:Register({module="generalConvenience"},"길드 초대")
N:Register({module="generalConvenience"},"파티 초대")
N:Register({module="generalConvenience"},"친구 허용")
N:Register({module="generalConvenience"},"길드원 허용")
N:Register({module="generalConvenience"},"채집 추적 상태 유지")
N:Register({module="generalConvenience"},"복원 채팅 알림")
N:Register({module="generalConvenience"},"상인 판매목록 확장")

for section,titles in pairs({
  ["전문기술 버튼"]={"전문기술 버튼 표시","위치 잠금","전문기술 위치 초기화","버튼 글자 크기","글자 색상","텍스트 효과"},
  ["펼친 목록"]={"펼침 방향","배치 방향","아이콘 크기","전문기술 사이 간격","목록 배경 불투명도","숙련도 표시","숙련도 글자 크기","숙련도 위치"},
  ["버튼 순서"]={"전문기술 순서 1","전문기술 순서 2","전문기술 순서 3","전문기술 순서 4","전문기술 순서 5"},
}) do
  for _,title in ipairs(titles) do N:Register({module="professions",section=section},title) end
end
