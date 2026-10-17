# KHQOL 1.11.2 미니맵 검증 안내

2026-10-17. 이번 통합은 전용 모의 검사 18/18, 원본 KH_map 1.0.0 동작 대조 14/14를 통과했습니다. 전체 결과는 KHQOL/CHANGE-VALIDATION-REPORT.md를 따릅니다. 실제 게임 검증은 미실시입니다.

## 과거 KH_map 기록 원문

아래 본문은 1.0.0 당시의 이력입니다. 독립 설정창과 119개 검사에 대한 설명은 이번 통합 화면·이번 재실행 결과를 뜻하지 않습니다.

# KH_map 1.0.0 검사 결과

검증일: 2026-10-17. Lua 5.1 모의 검사 **119/119 통과**. **실제 Forever 인게임 검증은 미실시**입니다.

## 자동 모의 검사

각 항목은 별도 Lua 런타임에서 실행했습니다. 두 독립 런타임에 일반 설정값만 전달해 재접속 저장 호환성을 검사했고, 모든 시작·기능 검사는 로그 모듈 없이 실행했습니다. 삭제한 로그 기능의 기존 검사는 이전 버전 자료로 보관했습니다.

| 번호 | 검사 항목 | 결과 |
|---|---|---|
| 1 | independent startup and defaults without libraries or KHQOL | PASS |
| 2 | missing keys filled while saved choices and unrelated data survive | PASS |
| 3 | malformed and out-of-range saved values sanitized | PASS |
| 4 | appearance off restores native geometry mask alpha and anchors | PASS |
| 5 | square circle toggle and matching border segments | PASS |
| 6 | native centre ping and added square corner ping exactly once | PASS |
| 7 | native wheel zoom and zone click preserved, external wheel untouched | PASS |
| 8 | mail tracking calendar and user-positioned queue remain live | PASS |
| 9 | drag save clamp lock and position-only reset | PASS |
| 10 | screen and UI scale changes clamp display without corrupting saved size | PASS |
| 11 | native rotation reconfiguration reapplies mask and restores latest native state | PASS |
| 12 | native edit mode gets exclusive control then latest KH settings resume | PASS |
| 13 | unknown external map size yields and is never overwritten on release | PASS |
| 14 | unknown mask change yields and explicit off-on can reacquire | PASS |
| 15 | shape provider conflict and conditional restoration | PASS |
| 16 | later shape provider stays installed when own feature is disabled | PASS |
| 17 | unsupported client disables appearance safely while drawer remains available | PASS |
| 18 | real buttons retain all clicks modifiers tooltip icon and own shown flag | PASS |
| 19 | owner-hidden buttons never forcibly shown, owner Show Hide intention retained | PASS |
| 20 | per-button exclusion restores exact original properties and can recollect | PASS |
| 21 | saved exclusions honored at initial login | PASS |
| 22 | late library callbacks and manual custom-button refresh | PASS |
| 23 | late library load discovered after ADDON_LOADED | PASS |
| 24 | protected forbidden restricted secret and live-update buttons excluded | PASS |
| 25 | frames managed by another container and hover-faded buttons excluded | PASS |
| 26 | external parent or anchor mutation releases without fighting owner | PASS |
| 27 | later owner drag script survives conditional restoration | PASS |
| 28 | known addon conflicts pause individual features | PASS |
| 29 | combat changes defer all world mutations and apply only latest desired state | PASS |
| 30 | login during combat creates no protected descendants before regeneration | PASS |
| 31 | drawer wrapping pagination and every screen edge remain in bounds | PASS |
| 32 | toggle dragging stores angle and cleans up short-lived OnUpdate | PASS |
| 33 | repeated open-close and refresh do not leak hooks or schedule idle work | PASS |
| 34 | settings controls color cancel and native category entry | PASS |
| 35 | runtime data never enters SavedVariables | PASS |
| 36 | slash collision chooses unused command | PASS |
| 37 | actual installed KHQOL and Forever Note callbacks remain intact | PASS |
| 38 | actual KHQOL refresh keeps its button collected while respecting visibility | PASS |
| 39 | actual LibDBIcon v57 registration callbacks click tooltip and restoration | PASS |
| 40 | actual LibDBIcon Hide and Show preserve visibility and collection | PASS |
| 41 | actual LibDBIcon late creation and Refresh never fight for anchors | PASS |
| 42 | foreign frame level preserved despite automatic parent-level adjustment | PASS |
| 43 | access loss defers restoration, then restores after access returns | PASS |
| 44 | invalid library objects and secret values rejected before calculations | PASS |
| 45 | new anchoring restrictions defer map restoration without protected calls | PASS |
| 46 | native scale and queue anchor updates rebase only verified properties | PASS |
| 47 | EnhanceQoL flags isolate conflicts without changing its settings | PASS |
| 48 | foreign cluster scale pauses appearance while drawer keeps fixed icon units | PASS |
| 49 | Forever day-night indicator keeps events, tracks size layout, and restores native transform | PASS |
| 50 | 31 and 32 unit square buttons tolerate subpixel engine dimensions | PASS |
| 51 | button checks stay stable when parent changes alter resolved dimensions slightly | PASS |
| 52 | zone and lock changes retain appearance after tiny resolved size drift | PASS |
| 53 | appearance off restores original dimensions despite harmless layout rounding | PASS |
| 54 | fractional external size changes and genuinely rectangular buttons remain rejected | PASS |
| 55 | geometry tolerance never weakens parent script anchor-count or secret comparisons | PASS |
| 56 | actual Books on map button collects with original clicks tooltip visibility and restoration | PASS |
| 57 | late Books on map discovery and per-button exclusion use the real button | PASS |
| 58 | native compartment registration becomes a drawer launcher with full callback arguments | PASS |
| 59 | compartment late registration removal exclusion and drawer off retain native registry access | PASS |
| 60 | compartment entries represented by visible real icons avoid duplicate launchers | PASS |
| 61 | owner-hidden real icon keeps a separate registered compartment launch path | PASS |
| 62 | native metadata compartment callback still loads on demand and forces insecure execution | PASS |
| 63 | unsupported compartment entries retain the original access button | PASS |
| 64 | compartment launcher actions defer to user after combat without loading addons or changing game frames | PASS |
| 65 | calendar clock and header stay invisible through native Show and restore on appearance off | PASS |
| 66 | late native clock is parked after its addon loads and its own hidden intention survives | PASS |
| 67 | tracking uses provided artwork while original menus and native texture refresh remain functional | PASS |
| 68 | tracking and day-night drag offsets save independently and survive map movement | PASS |
| 69 | element drags stop on combat and position reset only changes element offsets | PASS |
| 70 | region name is hover-only above or inside the map with click and motion propagation | PASS |
| 71 | new element and hover data sanitize without overwriting old addon preferences | PASS |
| 72 | edit mode restores all native elements and resumes saved icon placements without WorldFrame writes | PASS |
| 73 | tracking button and its native wrapper are exactly 26 UI px and restore original sizes | PASS |
| 74 | mail becomes 29 by 21 with the envelope and survives native pending-mail layouts | PASS |
| 75 | mail can move without pending mail, follows map movement and shares position lock | PASS |
| 76 | mail movement stops on combat and native mail dimensions return during edit mode | PASS |
| 77 | visible minimap reaches all four screen edges without bottom clearance at multiple UI scales | PASS |
| 78 | native cluster clamp does not impose its larger bounds and restores on appearance off | PASS |
| 79 | drawer direction dropdown opens to each of the four chosen sides | PASS |
| 80 | every drawer direction stays contained at screen corners with wrapping and pages | PASS |
| 81 | open drawer follows minimap dragging before the drag finishes | PASS |
| 82 | element edge clamping uses the intended map center before the engine resolves its new rectangle | PASS |
| 83 | region hover covers the entire minimap and preserves original mouse handlers | PASS |
| 84 | settings title drag saves its position and survives refresh close and reopen | PASS |
| 85 | settings retain ninety percent of the former fitted size across viewports and UI scales | PASS |
| 86 | settings controls and dropdowns stay behind ordinary addon dialogs without raising on open | PASS |
| 87 | settings close during a drag stops movement and saved position fits a smaller screen | PASS |
| 88 | new mail direction and settings-position saved values sanitize without losing existing choices | PASS |
| 89 | LibDBIcon position radius size and drag updates retain collection and restore latest owner state | PASS |
| 90 | LibDBIcon unlocked drag scripts restore after an unlocked refresh while collected | PASS |
| 91 | KHQOL and Forever Note repeated refreshes keep their slots and restore new positions | PASS |
| 92 | foreign writes after a known LibDBIcon callback still release ownership | PASS |
| 93 | known owner updates do not reclaim a foreign parent or foreign scale | PASS |
| 94 | coalesced known owner updates retain latest position and lock without leaking hooks or idle work | PASS |
| 95 | owner refresh during combat defers collection writes until regeneration | PASS |
| 96 | actual LibDBIcon fixed layer buttons including EnhanceQoL render above the drawer and fully restore | PASS |
| 97 | new settings migrate old ranges and preserve saved shapes positions and exclusions | PASS |
| 98 | settings tabs keep header and divider fixed and clean up open dropdowns | PASS |
| 99 | standalone theme uses the KHQOL palette without requiring KHQOL or red button templates | PASS |
| 100 | shape and location dropdowns apply selections while zone OFF stays OFF | PASS |
| 101 | new slider limits and compact tracks update minimap and drawer sizes | PASS |
| 102 | region text scales from 100 to 200 percent without exceeding its map-width allocation | PASS |
| 103 | surrounding icon scaling preserves baselines and relative saved positions | PASS |
| 104 | element visibility preserves native mail events and restores original mouse access | PASS |
| 105 | all new native icon changes restore after appearance off and edit-mode transitions | PASS |
| 106 | horizontal and vertical radios produce six-column and six-row layouts without overlap | PASS |
| 107 | both drawer orientations paginate at all corners within a smaller viewport | PASS |
| 108 | storage toggle uses the supplied tray texture without a square fill or plus-minus label | PASS |
| 109 | fixed layer release preserves a later foreign fixed-flag intention | PASS |
| 110 | unreadable fixed-layer flags exclude a button before any frame changes | PASS |
| 111 | locking or hiding an element during a drag clears the short-lived update script | PASS |
| 112 | appearance switch sits below the map heading and above both shape and size rows | PASS |
| 113 | drawer background is exactly opaque hexadecimal 1F1F1F | PASS |
| 114 | renamed identity registers the new command and both compatibility aliases | PASS |
| 115 | renamed compatibility aliases never overwrite another addons slash commands | PASS |
| 116 | legacy account-file preferences survive while retired development data is discarded | PASS |
| 117 | active legacy addon pauses the renamed map and drawer while the new settings remain accessible | PASS |
| 118 | release removes log UI commands listeners and input hooks while normal actions remain live | PASS |
| 119 | SavedVariables replay across two independent Lua runtimes | PASS |

## 정적·원본 대조 검사

| 검사 | 결과 |
|---|---|
| Lua 5.1 syntax: all five production files | PASS |
| TOC name, AddOn-list icon, interface 16001 and consistent version | PASS |
| TOC references exact source filenames and load order | PASS |
| Account-wide settings only; retired log variable is not saved | PASS |
| Release 1.0.0 has no logging module, UI, command path, collection hooks or preview label | PASS |
| No mandatory or optional third-party dependencies | PASS |
| No global frame scans, tickers, method blocking, foreign DB writes or CVar changes | PASS |
| Pinned Forever family/game source selection, native dimensions and mask API contract | PASS |
| Downloaded reference hashes and read-only installed-source hashes unchanged | PASS |
| README, CHANGELOG and implementation/test report present | PASS |
| User icons and rounded switch atlas: source/pixel hashes, alpha and game texture format | PASS |

## 최종 설치 ZIP 검사

| 검사 | 결과 |
|---|---|
| Single KH_map top folder; only TOC, five Lua files, four Markdown documents and three TGA textures | PASS |
| ZIP CRC check for every entry | PASS |
| Every archived byte matches the verified workspace file | PASS |
| Archived Lua syntax, TOC references, interface, version and dependency declarations rechecked | PASS |

설치 ZIP에 개발 스크립트·모의 환경·다운로드한 UI 원본·외부 라이브러리·임시 파일은 포함하지 않았습니다.

## 직접 실행한 로컬 호환성 원본

다음은 읽기 전용 원본을 식별하는 SHA-256입니다. 해당 소스를 설치 ZIP에 동봉하지 않았습니다.

- `KHQOL/Core.lua`
  - SHA-256: `6e2ffd135258282aa37965e0a476cf0018cf0efde9acec1c412a42b053e38ae0`
- `KHQOL_Clock/Clock/Todo.lua`
  - SHA-256: `36a34e92317412c63ccc5c3f06eac9ee2b70595fdded8b9d92238f73edc39fc1`
- `EnhanceQoL/libs/LibDBIcon-1.0/LibDBIcon-1.0.lua`
  - SHA-256: `34b691e715853858e5c3f3f6363f1cf58b5cf1c2c0281d689e349b73b800cab8`
- `Books_on_map_Forever/modules/Minimap.lua`
  - SHA-256: `55170421016c44095e476401c1be77b4b958ad9a513818d90d0aa54210da4e77`
- `KHQOL/UI.lua`
  - SHA-256: `92b6c7bb8b1f06f078501788615b32080325af7540a8eb737822066da55ac40b`

Forever 기본 UI 커밋: `b401e0332adfbf0460d319b06d8ea29279a941f1`. 전체 근거와 실제 게임 점검표는 [REPORT.md](REPORT.md)에 있습니다.

## 검증의 한계

모의 환경의 PASS는 실제 화면·폰트·텍스처·엔진 보호·taint·핑·디스크 저장·전체 애드온 조합의 통과를 뜻하지 않습니다. 90% 화면과 확대된 닫기 버튼의 실제 표시·입력은 인게임 확인이 필요합니다. 실제 게임 검사 결과는 기록하지 않았습니다.
