local K=_G.KHQOL
local N=K.UI.SettingsNavigation
N:Register({module="general",scope="현재 프로필",section="전역 설정"},"중앙 알림 텍스트 크기")
N:Register({module="generalConvenience"},"기본 대화창 편의")
for _,title in ipairs({"말머리 사용","일반 말머리 (최대 10글자)","파티 말머리 (최대 10글자)","길드 말머리 (최대 10글자)","공격대 말머리 (최대 10글자)","말머리 초기화"}) do
  N:Register({module="convenienceChat"},title)
end
for _,title in ipairs({"파티 자동 인사","공격대 자동 인사","인사말 (캐릭터별 저장 · 최대 255바이트)"}) do
  N:Register({module="convenienceParty",section="파티 자동 인사"},title)
end
N:Register({module="convenienceParty"},"Alt+좌클릭 파티 초대")
for _,title in ipairs({"파티 버튼 표시","파티 버튼 크기","파티 버튼 투명도","파티 인사 메시지","파티 작별 인사 메시지","파티 버튼 위치 편집","파티 버튼 위치 초기화"}) do
  N:Register({module="convenienceParty",section="파티 버튼"},title)
end
for _,title in ipairs({"버프 알림","버프 감사 메시지","버프 알림 위치 편집","버프 아이콘 크기","새 알림 표시 방향","알림 유지 시간"}) do
  N:Register({module="generalConvenience",section="버프 알림"},title,"버프 감사 알림 인사 귓속말")
end
N:Register({module="generalConvenience"},"아이템 파괴 자동 입력")
N:Register({module="generalConvenience"},"퀘스트 보상 최고 판매가 표시")
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
N:Register({module="generalConvenience"},"상인 판매목록 확장")
N:Register({module="generalConvenience",section="가방 휴지통"},"가방 휴지통 사용","휴지통 파괴 드롭")
N:Register({module="generalConvenience",section="가방 휴지통"},"퀘스트 분류 일반 아이템도 즉시 파괴","휴지통 퀘스트 아이템")
N:Register({module="itemProtection",section="아이템 보호"},"보호 목록 관리","아이템 보호 해제")

for section,titles in pairs({
  ["전문기술 버튼"]={"전문기술 사용","위치 잠금","전문기술 위치 초기화","버튼 글자 크기","글자 색상","텍스트 효과"},
  ["표시 설정"]={"펼침 방향","배치 방법","아이콘 크기","전문기술 사이 간격","목록 배경 불투명도","숙련도 표시","숙련도 글자 크기","숙련도 위치","부캐 전문기술 표시","목록에 보조 전문기술 표시"},
  ["전문기술 배치"]={"버튼 1","버튼 2","버튼 3","버튼 4","버튼 5"},
  ["숙련 단계 안내"]={"숙련 단계 안내","습득 위치 표시"},
}) do
  for _,title in ipairs(titles) do N:Register({module="professions",section=section},title) end
end
