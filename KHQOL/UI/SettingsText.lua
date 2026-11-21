-- Fixed UI vocabulary. Original titles remain the logical identity used by
-- navigation, diagnostics, scope checks, disclosures and position locks.
local _,K=...
local UI=K.UI
local common={
  ["모양 및 크기"]="모양·크기",
  ["지정 음식 ID / 링크"]="지정 음식 ID·링크",
  ["글씨 크기"]="글자 크기",["텍스트 크기"]="글자 크기",
  ["색상 / 스타일"]="색상·스타일",["주술사 무기 / 토템"]="주술사 무기·토템",
  ["기본 대화창 편의"]="대화창 편의",["충분한 휴식·침낭"]="침낭·휴식",
  ["스킬북에서 등록"]="마법책에서 등록",["일시 정지 / 재개"]="일시 정지·재개",
  ["퀘스트 글씨 크기"]="퀘스트 글자 크기",["미리보기 켜기 / 끄기"]="미리보기 켜기·끄기",
  ["지역 접기 / 펼치기 사용"]="지역 접기·펼치기 사용",["모양 / 색상"]="모양·색상",
  ["테스트 / 진단"]="테스트·진단",["표시 시간 / 효과"]="표시 시간·효과",
  ["고급 / 잔상 동작"]="잔상 동작",["알람 / 타이머"]="알람·타이머",
  ["공용 데이터"]="계정 공용 데이터",
  ["중앙 알림 텍스트 크기"]="중앙 알림 글자 크기",
  ["탄약 / 영혼의 조각 위치"]="탄약·영혼의 조각 위치",
  ["고급 / 표시 레이어"]="표시 레이어",["상태 및 경고"]="상태·경고",
  ["프로필 백업 및 복원"]="프로필 백업·복원",
}
local owners={
  general={["기타"]="잠금·진단"},
  experienceBar={["기타 설정"]="최대 레벨·평판"},
  professions={["표시 설정"]="목록 표시·배치"},
  generalConvenience={
    ["버프 알림"]="버프 감사 알림",["버프 알림 사용"]="버프 감사 알림 사용",
    ["버프 알림 위치 잠금"]="버프 감사 알림 위치 잠금",["버프 아이콘 크기"]="감사 알림 아이콘 크기",
    ["자동 거절"]="요청 자동 거절",["기본 설정"]="대화창·상점",["아이템"]="아이템 표시·자동 처리",
  },
  partyFrames={["프로필"]="역할별 프레임 프로필",["역할 프로필"]="역할별 프레임 프로필"},
  profiles={["프로필 관리"]="KHQOL 프로필"},
  clock={["사이드 텍스트"]="보조 정보",["설정 대상"]="표시 항목",["알람·타이머·스톱워치"]="알람·시간 도구"},
  todo={["경로 안내"]="저장 위치 길 안내",["체크리스트 네비게이션"]="저장 위치 길 안내 연결",["네비게이션 연결"]="저장 위치 길 안내 사용"},
  range={["고급 / 확인"]="측정 상태·진단"},
  tooltip={["무기 전문가 정보"]="무기 전문가 안내"},
  minimap={["버튼 정리"]="미니맵 버튼"},
  buffReminder={["버프 리마인더"]="버프 유지 알림",["버프 알림"]="버프 유지 알림"},
}
function UI:DisplayRouteText(route,text)
  if type(text)~="string" or not route then return text end
  local R=self.SettingsRegistry
  if K.LabLock and (route.module=="labs" or K.LabLock:IsExperimental(route.module) or R.modules[route.module] and R.modules[route.module].group=="labs") then return text end
  if route.logicalLabel==text and route.displayLabel then return route.displayLabel end
  if route.screen=="weaponGuide" and text=="표시 정보" then return "무기 전문가 안내" end
  if route.module=="generalConvenience" and text=="기본 설정" then
    return route.screen=="merchant" and "상점·수리" or "대화창 편의"
  end
  local map=owners[route.module]
  return map and map[text] or common[text] or text
end
function UI:DisplayText(parent,text)
  local route=self.SettingsNavigation and self.SettingsNavigation:Context(parent)
  if not route then return text end
  return self:DisplayRouteText(route,text)
end
