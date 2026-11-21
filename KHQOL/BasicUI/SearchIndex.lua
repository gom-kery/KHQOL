local K=_G.KHQOL
local N=K.UI.SettingsNavigation
N:Register({module="castBar",castUnit="player",scope="현재 프로필",section="위치"},"위치 초기화")
N:Register({module="castBar",castUnit="player",scope="현재 프로필",section="위치"},"미리보기 켜기 / 끄기")
  N:Register({module="castBar",castUnit="target",scope="현재 프로필",section="대상 시전바"},"KHQOL 대상 시전바 사용")
  N:Register({module="castBar",castUnit="target",scope="현재 프로필",section="대상 시전바"},"대상 시전바 ")
  N:Register({module="castBar",castUnit="target",scope="현재 프로필",section="대상 시전바"},"대상 시전바 드래그 이동")
  N:Register({module="castBar",castUnit="target",scope="현재 프로필",section="대상 시전바"},"대상 시전바 위치 초기화")
for section,titles in pairs({["바 모양"]={"높이","폭","텍스처","바 색상","배경 색상","시전 중단 색상"},
  ["아이콘"]={"스킬 아이콘 표시","아이콘 위치","아이콘 크기"},["스킬명"]={"스킬명 표시","표시 위치","글자 크기"}}) do
  for _,title in ipairs(titles) do N:Register({module="castBar",castUnit="target",scope="현재 프로필",section=section},title) end
end
N:Register({module="basicUI",scope="현재 프로필",section="Blizzard 기본 프레임 이동"},"Blizzard 기본 프레임 이동")
N:Register({module="basicUI",scope="현재 프로필",section="Blizzard 기본 프레임 이동"},"이동 키 (+ 드래그)")
N:Register({module="basicUI",scope="현재 프로필",section="Blizzard 기본 프레임 이동"},"모든 프레임 위치 초기화")
N:Register({module="basicUI",scope="현재 프로필",section="Blizzard 기본 프레임 이동"},"기본창 전체 위치 편집")
for section,titles in pairs({["주사위 굴림"]={"주사위 굴림 외형 변경","창 크기","글자 크기","주사위 위치 편집","주사위 위치 초기화","주사위 굴림 설정 초기화"},
  ["알림"]={"기본 알림 위치·크기 변경","공통 알림 위치","공통 알림 위치 초기화","도안 습득 알림 크기","알림 설정 초기화"}}) do
  for _,title in ipairs(titles) do N:Register({module="basicUI",scope="계정 공용",section=section},title) end
end

N:Register({module="basicUI",scope="계정 공용",section="알림"},"도안·아이템 획득 알림","위치·크기·잠금 · 희귀 영웅 획득 배너","도안 습득 알림")
