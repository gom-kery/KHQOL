# 1.11.8.19 참고 안내

아래 내용은 이전 버전의 조사/구현 기록입니다. 모듈별 위치 편집 메뉴는 1.11.8.19에서 제거했고 버프 알림 독립 잠금과 드래그를 추가했습니다. 현재 동작·검증·제한은 LOCK-UI-REPORT.md와 HEADER-LOCKS.md를 따르세요. 전문기술 숙련 데이터와 안내 동작은 유지합니다.

---

# 위치 대상 조회 모의 결과

시험 중 설정 상태별 결과입니다. 기본값이 아니며 실제 게임 검증은 NOT TESTED입니다. 같은 경로도 옵션에 따라 수가 달라집니다.

| 설정 경로 | 수 | 실제 ID · 이름 · 진입 |
|---|---:|---|
| module=experienceBar | 1 | `experience` · 경험치 바 · normal |
| module=experienceBar | 0 | 현재 조건에서 없음 |
| module=clock | 8 | `clock` · Clock · 시간 · normal<br>`clock.date` · Clock · 날짜 · normal<br>`clock.money` · Clock · 소지금 · normal<br>`clock.performance` · Clock · FPS / 지연시간 · normal<br>`clock.alert` · Clock · 중앙 알림 · normal<br>`clock.tools` · Clock · 알람 / 타이머 · normal<br>`clock.timerBar` · Clock · 타이머 바 · normal<br>`clock.stopwatch` · Clock · 스톱워치 · normal |
| module=resourceSwing | 1 | `resource` · Resource Swing · 자원 / 스윙 · normal |
| module=environmentTimer | 1 | `environment` · 환경 타이머 · 그룹 · normal |
| module=environmentTimer | 3 | `environment` · 환경 타이머 · 그룹 · normal<br>`environment.text.BREATH` · 환경 · 호흡 텍스트 · normal<br>`environment.text.EXHAUSTION` · 환경 · 피로도 텍스트 · normal |
| castUnit=player, module=castBar | 1 | `cast` · Cast Bar · 자유 위치 · normal |
| castUnit=player, module=castBar | 0 | 현재 조건에서 없음 |
| module=basicUI | 7 | `basicUI.Map` · 기본창 · 지도 · normal<br>`basicUI.Character` · 기본창 · 캐릭터창 · normal<br>`basicUI.Talents` · 기본창 · 특성 · normal<br>`basicUI.Spellbook` · 기본창 · 마법책 · normal<br>`basicUI.Macro` · 기본창 · 매크로창 · normal<br>`basicUI.roll` · 전리품 주사위 · normal<br>`basicUI.alerts` · 공통 알림 · normal |
| module=unitFrames, part=basic, unit=player | 1 | `unitFrames.player.root` · 플레이어 · 전체 프레임 · unitRoots |
| module=unitFrames, part=labels, unit=player | 2 | `unitFrames.player.name` · 플레이어 · 이름 · normal<br>`unitFrames.player.level` · 플레이어 · 레벨 · normal |
| module=unitFrames, part=labels, unit=player | 0 | 현재 조건에서 없음 |
| module=generalConvenience | 0 | 현재 조건에서 없음 |
| module=generalConvenience | 1 | `bagTrash` · 가방 휴지통 · normal |
| module=generalConvenience | 2 | `bagTrash` · 가방 휴지통 · normal<br>`buffThanks` · 버프 알림 · normal |
| module=convenienceParty | 1 | `partyButton` · 파티 버튼 · normal |
| module=professions | 1 | `professions` · 전문기술 버튼 · normal |
| module=todo | 2 | `note` · Forever Note · normal<br>`quest` · 퀘스트 / 노트 · 공용 안내 HUD · normal |
| module=questNavigator, tab=navigation | 1 | `quest` · 퀘스트 / 노트 · 공용 안내 HUD · normal |
| castUnit=target, module=castBar | 1 | `cast.target` · 대상 시전바 · normal |
| category=friendlyPlayer, module=unitFrames, part=auras, unit=target | 1 | `unitFrames.target.auras.friendlyPlayer` · 대상 · 아군 플레이어 버프·디버프 · normal |
| category=friendlyPlayer, module=unitFrames, part=auras, unit=target | 2 | `unitFrames.target.auras.friendlyPlayer.buffs` · 대상 · 아군 플레이어 · 버프 · normal<br>`unitFrames.target.auras.friendlyPlayer.debuffs` · 대상 · 아군 플레이어 · 디버프 · normal |
| category=attackableNPC, module=unitFrames, part=auras, unit=target | 1 | `unitFrames.target.auras.attackableNPC` · 대상 · 공격 가능한 NPC 버프·디버프 · normal |
| category=attackableNPC, module=unitFrames, part=auras, unit=target | 2 | `unitFrames.target.auras.attackableNPC.buffs` · 대상 · 공격 가능한 NPC · 버프 · normal<br>`unitFrames.target.auras.attackableNPC.debuffs` · 대상 · 공격 가능한 NPC · 디버프 · normal |
| module=partyFrames, tab=frames | 2 | `partyFrames.party` · 파티·솔로 프레임 · normal<br>`partyFrames.raid` · 10인 공격대 · normal |
| module=procAlert | 1 | `proc` · 발동 버프 · HUD · normal |
| module=buffReminder | 1 | `buffs` · Buff Reminder · 버프 그룹 · normal |
| module=procAlert | 0 | 현재 조건에서 없음 |
| module=castBar | 0 | 현재 조건에서 없음 |
| module=combatStatus | 1 | `combat` · Combat Status · 전투 알림 · normal |
| module=pvpAlert | 1 | `pvp` · PvP Alert · 경고 / 보조 목록 · normal |
| module=campfire | 2 | `campfire` · Campfire · 발견 / 진행 · normal<br>`campfire.complete` · Campfire · 효과 획득 · normal |
| module=threat | 1 | `threat` · Threat · 위협 수준 · normal |
| module=tooltip | 1 | `tooltip.position` · 툴팁 · 고정 커서 기준 · normal |
| module=range | 1 | `range` · Range · 사거리 · normal |
| module=questNavigator | 1 | `quest` · 퀘스트 / 노트 · 공용 안내 HUD · normal |
| module=partyFrames, tab=frames | 0 | 현재 조건에서 없음 |
| module=unitFrames | 0 | 현재 조건에서 없음 |
| module=npcAlert | 0 | 현재 조건에서 없음 |
| module=cursorTrail | 0 | 현재 조건에서 없음 |
| module=objectHighlight | 0 | 현재 조건에서 없음 |
