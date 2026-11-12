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
