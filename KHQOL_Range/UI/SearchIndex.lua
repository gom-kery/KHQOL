local K=_G.KHQOL
local N=K.UI.SettingsNavigation
N:Register({module="range",scope="현재 프로필",section="사거리 기준 주문"},"스킬북에서 등록")
N:Register({module="range",scope="현재 프로필",section="원거리 무기 판정"},"근거리 공격도 가능으로 판정")
N:Register({module="range",scope="현재 프로필",section="원거리 무기 판정"},"데드존 감지 사용")
N:Register({module="range",scope="현재 프로필",section="마우스오버 거리 측정"},"마우스오버 거리 측정 사용")
N:Register({module="range",scope="현재 프로필",section="마우스오버 거리 측정"},"X 위치 보정")
N:Register({module="range",scope="현재 프로필",section="마우스오버 거리 측정"},"Y 위치 보정")
N:Register({module="range",scope="현재 프로필",section="마우스오버 거리 측정"},"글자 크기")
N:Register({module="range",scope="현재 프로필",section="위치"},"위치 잠금")
N:Register({module="range",scope="현재 프로필",section="위치"},"X 위치")
N:Register({module="range",scope="현재 프로필",section="위치"},"Y 위치")
N:Register({module="range",scope="현재 프로필",section="표시 모양"},"스킬 사거리 별 문구")
N:Register({module="range",scope="현재 프로필",section="표시 모양"},"특수 문자")
N:Register({module="range",scope="현재 프로필",section="표시 모양"},"크기")
N:Register({module="range",scope="현재 프로필",section="외곽선"},"외곽선 표시")
N:Register({module="range",scope="현재 프로필",section="외곽선"},"외곽선 두께")
N:Register({module="range",scope="현재 프로필",section="외곽선"},"외곽선 색상")
N:Register({module="range",scope="현재 프로필",section="고급 / 확인"},"표시 테스트")
N:Register({module="range",scope="현재 프로필",section="고급 / 확인"},"API 상태")
N:Register({module="range",section="표시 방식"},"표시 방식","스킬 유효 거리 대상 거리 숫자")
for _,title in ipairs({"거리 형식","거리 단위","최대 표시 거리 (50~100m)","최대 표시 거리 (55~109yd)",
  "거리 글자 크기","거리 위치 잠금","거리 X 위치","거리 Y 위치","거리 위치 편집","거리 위치 초기화"}) do
  N:Register({module="range",section="대상 거리"},title)
end
for _,title in ipairs({"근접 구간","원거리 무기 데드존 구간","원거리 구간","최대 거리 구간","중립·미확인"}) do
  N:Register({module="range",section="거리 색상"},title,"대상 거리 색상")
end

N:Register({module="range",section="마우스오버 거리 측정"},"마우스오버 표시 방식","텍스트 숫자 거리 동시 커서")
N:Register({module="range",section="마우스오버 거리 측정"},"표시 위치","툴팁 아래 왼쪽 커서 옆")
N:Register({module="range",section="마우스오버 거리 측정"},"마우스오버 위치 초기화")

for _,title in ipairs({"근접 최대","원거리 무기 데드존 최소","원거리 무기 데드존 최대","원거리 최소","원거리 최대"}) do
  N:Register({module="range",section="거리 색상"},title,"숫자 거리 구간")
end
N:Register({module="range",section="대상 거리"},"거리 단위","m yd 미표시 숫자")
N:Register({module="range",section="대상 거리"},"거리 구간 간격","원거리 최대 정수 기준 구간 27~30 31~34")
