## TASK-P2-03: IA 재구성 — 운동 탭 서브탭 통합

### 목표
참조 목업(`docs/design/ui-reference-hell-log.md`)의 정보구조를 반영한다. 하단 네비를 정리하고, 흩어진 세트로그·통계를 `운동` 탭 하나에 서브탭으로 묶는다. **네비/라우팅/셸 구조 변경 + 위젯테스트.** 각 화면 내부 기능은 그대로 재사용(새 도메인/데이터 로직 금지).

### 배경
- 현재 하단 네비(P0): 홈 / 기록 / 통계 / 파티 / 프로필 (5탭, 대부분 목업).
- 이미 존재: 세트로그 화면(`workout_log/presentation/workout_page.dart`), 통계 화면(`stats/presentation/stats_page.dart`), 루틴 화면(`routine/presentation/`).

### 변경 (features/app_shell + core/router)
1. 하단 네비 **4탭**으로: `홈` / `운동` / `파티` / `프로필`. (설정은 프로필 또는 홈 상단 기어에서 진입 — 기존 라우트 유지)
2. **`운동` 탭 = 서브탭 3개**: `세트로그`(기존 workout_page) / `통계`(기존 stats_page) / `몬스터`(플레이스홀더 — "곧 만나요" 빈 상태, P6에서 실제 구현). 상단 세그먼트/탭바로 전환.
3. `홈` 탭: 개인 대시보드(글로벌 피드 아님). 오늘 운동 요약 + 빠른 시작(운동 시작 CTA) + 루틴 바로가기 정도의 가벼운 랜딩. mock/파생 데이터로.
4. `파티`/`프로필`: 기존 목업 유지(이번에 손대지 않음).
5. 라우터: 기존 5개 라우트를 새 4탭 구조로 정리. 딥링크 경로는 최대한 보존. 루틴 라우트(/routines)는 운동 또는 홈에서 진입 가능하게 유지.

### UX
- 서브탭 전환은 상태 유지(IndexedStack 등)로 스크롤/상태 보존.
- taste-skill 적용, 다크 유틸리티, 하드코딩 색/폰트 금지, 문자열 l10n.
- 기존 화면 위젯 자체는 재사용(중복 구현 금지). 위치만 재배치.

### 완료 조건 (DoD)
- [ ] `flutter analyze` 0
- [ ] `dart run build_runner build --delete-conflicting-outputs` 성공(있으면), 생성물 커밋
- [ ] `flutter test` **전체 스위트** 통과. 위젯 테스트 최소:
  - 하단 네비 4탭 렌더 및 탭 전환 동작
  - 운동 탭에서 세트로그/통계/몬스터 서브탭 전환
  - 홈 탭 대시보드 렌더 + 운동 시작 CTA 존재
  - 기존 깨진 네비/라우트 테스트가 있으면 새 구조에 맞게 갱신(테스트 약화 아님, 구조 변경 반영)
- [ ] presentation은 repository 직접호출 금지. domain에 flutter import 없음 유지.

### 하지 말 것
- 새 도메인/데이터/repository 로직 (재배치만).
- 몬스터 실제 구현(P6). 파티/영상/캐릭터 기능(단계별).
- 글로벌 홈 피드/스토리 (범위 밖 — 홈은 개인 대시보드).

### 검증 (worker_done 전 필수 — AGENTS.md)
`flutter analyze`(0)와 `flutter test`(전체 통과)를 직접 실행하고 worker_done body에 analyze 이슈 수 + test 통과/실패 개수를 적을 것. 커밋 금지.
