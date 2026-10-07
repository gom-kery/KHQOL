local _, KHQOL = ...
local FC = KHQOL.modules.clock
FC.ADDON_NAME = ADDON_NAME or "ForeverClock"
FC.L = {}

local enUS = {
  TITLE = "ForeverClock", SETTINGS = "Settings", CLOCK = "Clock", MODULES = "Modules",
  ENABLE = "Enable", FONT_SIZE = "Font Size", SIDE_FONT_SIZE = "Side Font Size", POSITION = "Position", LOCK = "LOCK", UNLOCK = "UNLOCK", DRAG_TO_MOVE = "Unlock, then drag a side panel to a new dock slot.",
  DATE = "Date", MONEY = "Money", PERFORMANCE = "Performance", MONEY_DISPLAY = "Money Display",
  DATE_FORMAT = "Date Format", WEEKDAY = "Weekday", WEEKDAY_OFF = "Off", WEEKDAY_KO = "Korean", WEEKDAY_EN = "English",
  GOLD = "Gold", SILVER = "Silver", COPPER = "Copper", GOLD_SILVER = "Gold + Silver", GOLD_SILVER_COPPER = "Gold + Silver + Copper",
  TODO = "ToDO", CLOSE = "Close", PREVIOUS = "Previous", NEXT = "Next", NEW = "New", DELETE = "Delete", PAGE = "Page", ADD_TASK = "+ Task", ADD_GROUP = "+ Group", GROUP_DEFAULT = "Tasks", TEXT_MODE = "Text", CHECKLIST_MODE = "Checklist", BACKGROUND = "Background", TODO_PLACEHOLDER = "Write tasks or notes here. Changes are saved automatically.",
  CALENDAR_UNAVAILABLE = "ForeverClock: Calendar UI is not available.",
  CALENDAR_INVITE = "[ForeverClock] A new calendar invite is available.", CALENDAR_REMINDER = "[ForeverClock] %s begins in %d minutes.",
  LEFT_CLICK = "Left Click: Settings", RIGHT_CLICK = "Right Click: Show / Hide",
}
local koKR = {
  TITLE = "ForeverClock", SETTINGS = "설정", CLOCK = "시계", MODULES = "모듈",
  ENABLE = "사용", FONT_SIZE = "글씨 크기", SIDE_FONT_SIZE = "사이드 글씨 크기", POSITION = "위치", LOCK = "잠금", UNLOCK = "잠금 해제", DRAG_TO_MOVE = "잠금 해제 후 사이드 패널을 끌어 원하는 Dock Slot에 놓으세요.",
  DATE = "날짜", MONEY = "소지금", PERFORMANCE = "FPS / 지연시간", MONEY_DISPLAY = "소지금 표시",
  DATE_FORMAT = "날짜 표시", WEEKDAY = "요일", WEEKDAY_OFF = "미표시", WEEKDAY_KO = "한글", WEEKDAY_EN = "영문",
  GOLD = "골드", SILVER = "실버", COPPER = "코퍼", GOLD_SILVER = "골드 + 실버", GOLD_SILVER_COPPER = "골드 + 실버 + 코퍼",
  TODO = "ToDO", CLOSE = "닫기", PREVIOUS = "이전", NEXT = "다음", NEW = "새 페이지", DELETE = "삭제", PAGE = "페이지", ADD_TASK = "+ 할 일", ADD_GROUP = "+ 그룹", GROUP_DEFAULT = "할 일", TEXT_MODE = "텍스트", CHECKLIST_MODE = "체크리스트", BACKGROUND = "배경", TODO_PLACEHOLDER = "할일이나 메모를 입력하세요. 자동으로 저장됩니다.",
  CALENDAR_UNAVAILABLE = "ForeverClock: Calendar UI is not available.",
  CALENDAR_INVITE = "[ForeverClock] 새로운 달력 초대가 있습니다.", CALENDAR_REMINDER = "[ForeverClock] %s 일정이 %d분 후 시작됩니다.",
  LEFT_CLICK = "좌클릭: 설정", RIGHT_CLICK = "우클릭: 표시 / 숨김",
}
local locale = (GetLocale and GetLocale() == "koKR") and koKR or enUS
setmetatable(FC.L, { __index = locale })
