## TASK-P1-03: 세트 기록 화면 + 휴식 타이머 (UI)

### 목표
사용자가 오프라인에서 운동 세션을 시작하고, 종목을 골라 세트를 **탭 3회 이내·1.5초 이내**로 기록하며, 세트 완료 시 휴식 타이머가 자동으로 돈다. 세션 종료까지 한 번에 완주 가능. **이 태스크로 P1이 완성된다.**

### 배경 / 현재 상태
- P1-01: `ExerciseRepository`(종목 검색/필터) + 프로바이더 완료.
- P1-02: `WorkoutRepository`(startSession/addSet/completeSet/updateSet/deleteSet/endSession/watchSets) + 프로바이더 완료.
- 이번엔 그 위에 **화면만** 얹는다. 새 도메인/데이터 로직 만들지 말고 기존 repository/provider를 쓴다.
- 기존 `기록` 탭은 목업(`features/workout_log/presentation/workout_page.dart`). 이걸 실제 화면으로 교체.

### 디자인 지침 (반드시 적용)
- **taste-skill 사용**: 구현 전 `design-taste-frontend` 또는 `minimalist-ui` 스킬을 읽고 그 원칙을 따른다. 제너릭 AI 디자인 회피.
- **다크 유틸리티 톤** (헬스장 조명 대응, SSOT). 필수 정보만 큼직하게. 정보 과밀 금지.
- 조사 보고서(`docs/research/design-research.md`) 3.1~3.3 반영: 스마트 프리필, 1-Tap 완료, `+/-` 퀵버튼, 키보드로 화면 가리기 금지.
- 하드코딩 색/폰트 금지 — `core/theme/` 토큰. 문자열 `l10n`(한국어 기본).

### 화면/파일 (features/workout_log/presentation)
- `workout_page.dart` (수정: 목업 → 실제 세션 화면. 진행 중 세션 없으면 "운동 시작" CTA, 있으면 세트 기록 뷰)
- `widgets/exercise_picker_sheet.dart` (신규: 종목 선택 바텀시트. ExerciseRepository 검색/필터 재사용)
- `widgets/set_row.dart` (신규: 세트 1줄 — 무게/횟수 입력, 완료 체크, 스와이프 삭제)
- `widgets/rest_timer_bar.dart` (신규: 휴식 타이머 바)
- `application/rest_timer_controller.dart` (신규: 타이머 상태 Riverpod Notifier — 순수 Dart 타이머 로직)
- `application/workout_session_controller.dart` (신규: 화면용 컨트롤러 — repository 호출 오케스트레이션)
- 라우터: 기존 `기록` 라우트가 이 화면 가리키게(이미 있으면 확인만)

### UX 계약 (완료 조건에서 검증)
1. **세트 입력 탭 3회 이내**: 종목 선택 후, 무게·횟수는 **직전 세트 값 자동 프리필**. 값 그대로면 **완료 체크 1탭**으로 세트 기록 = 탭 1회. 값 변경 시 `+/-` 스텝 버튼 또는 인라인 숫자패드(화면 하단, 리스트 안 가림).
2. **세트 완료 = 단일 탭**. 완료 즉시 (a) 다음 세트 행 프리필 생성, (b) **휴식 타이머 자동 시작**(restSeconds 기본값, 없으면 앱 기본 90초 — `core/constants`).
3. **삭제 = 스와이프 + undo 스낵바** (확인 다이얼로그 금지). undo는 소프트삭제 복구.
4. **모든 쓰기 로컬 우선** — 네트워크 대기 UI 블로킹 금지(P1은 전부 로컬이라 자연히 충족).
5. 세트 목록은 `watchSets` 스트림 구독(`ref.watch`, 필요한 범위만 `select`). `ListView.builder` + `const` 최대.
6. 휴식 타이머: 카운트다운 표시, `+15초`/`건너뛰기` 버튼, 0 되면 알림(햅틱/사운드는 선택, 소리 에셋 없으면 햅틱만). `dispose`에서 타이머 반드시 해제.

### 상수 (core/constants)
- `kDefaultRestSeconds = 90`
- `kRestTimerIncrementSeconds = 15`

### 완료 조건 (DoD)
- [ ] `flutter analyze` 0
- [ ] `dart run build_runner build --delete-conflicting-outputs` 성공, 생성물 커밋
- [ ] `flutter test` 통과. 위젯/컨트롤러 테스트 최소:
  - `rest_timer_controller`: 시작→틱 감소→0 정지, `+15초` 증가, 건너뛰기 정지 (fake timer 사용)
  - `workout_session_controller`: 세트 완료 시 다음 세트 프리필 값이 직전 세트와 동일
  - 위젯 테스트: 세트 완료 체크 1탭 시 `completeSet` 호출됨(mocktail로 repo mock)
  - 위젯 테스트: 스와이프 삭제 → `deleteSet` 호출 + undo 스낵바 노출
- [ ] 수동 확인 시나리오 보고: 세션 시작 → 종목 선택 → 세트 3개(프리필로 각 1탭) → 완료 시 타이머 작동 → 세션 종료 → 앱 재시작 후 기록 유지
- [ ] presentation 레이어는 repository 직접 호출 금지(controller/provider 경유). domain에 flutter import 없음 유지.

### 하지 말 것
- 새 repository/DB/도메인 로직 추가 (P1-02에 다 있음. 없으면 먼저 ask).
- 통계/차트 (P2). 루틴 템플릿 (P2). 1RM 표시 (P2).
- 캐릭터 EXP 연출 (P6). 지금은 세트완료 피드백 = 햅틱 + 타이머까지만.
- 파티/영상 (P4~P5).
- 소리 에셋 추가로 용량 늘리기 — 없으면 햅틱만.
- 과한 애니메이션/모달 중첩 (탭3회/1.5초 원칙 위반).
