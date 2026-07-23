## TASK-P2-01-UI: 루틴 화면 + 루틴으로 세션 시작

### 목표
사용자가 루틴을 만들고(종목 + 목표 세트/횟수/무게), 목록에서 보고, 루틴을 눌러 세션을 시작하면 계획 세트가 미리 채워진다. 이번 태스크는 **화면 + 컨트롤러 + 위젯테스트**. 새 도메인/데이터 로직 만들지 말 것(P2-01에 다 있음).

### 배경
- P2-01 완료: `RoutineRepository`(createRoutine/getRoutines/getRoutine/addItem/updateItem/removeItem/getItems), `plannedSetsFromRoutine`, `routineRepositoryProvider`/`routinesProvider`.
- P1-02/03: `WorkoutRepository`(startSession/addSet…), 세트 기록 화면.
- 기존 종목 선택 바텀시트(`exercise_picker_sheet.dart`) 재사용.

### 화면/파일 (features/routine/presentation)
- `routine_list_page.dart` (신규: 루틴 목록. 각 항목 "시작" 버튼 + 편집/삭제. 빈 상태 CTA "루틴 만들기")
- `routine_editor_page.dart` (신규: 루틴 이름 + 아이템 목록. 종목 추가(exercise_picker 재사용), 아이템별 목표 세트/횟수/무게 편집, 삭제)
- `application/routine_editor_controller.dart` (신규: 편집 상태 + repository 호출)
- `application/start_from_routine_controller.dart` (신규: 루틴 → startSession + plannedSetsFromRoutine로 계획세트 addSet 일괄 생성 → 세트기록 화면으로 이동)
- 라우터(`core/router`): `/routines`(목록), `/routines/edit/:id`(편집) 추가. 기록 탭 또는 홈에서 "루틴" 진입점 연결.

### UX
- 목록: `routinesProvider` 구독, `ListView.builder`, `const` 최대.
- 편집: 아이템 목표값은 `+/-` 스텝 또는 인라인 입력(키보드가 리스트 안 가리게).
- "루틴으로 시작": startSession(routineId) → plannedSetsFromRoutine(items)로 각 draft를 addSet(isCompleted=false)로 생성 → 기록 화면으로 push. 진행 중 세션 있으면 확인 후 처리(중복 active 방지 — 기존 active 종료 여부는 스낵바로 확인).
- taste-skill(design-taste-frontend/minimalist-ui) 적용, 다크 유틸리티 톤, 하드코딩 색/폰트 금지, 문자열 l10n.

### 완료 조건 (DoD)
- [ ] `flutter analyze` 0
- [ ] `dart run build_runner build --delete-conflicting-outputs` 성공(프로바이더 코드젠), 생성물 커밋
- [ ] `flutter test` **전체 스위트** 통과. 위젯/컨트롤러 테스트 최소:
  - 루틴 목록: routinesProvider mock → 항목 렌더, 빈 상태 CTA 노출
  - 편집: 종목 추가 시 addItem 호출(mocktail로 RoutineRepository mock)
  - start_from_routine: 아이템 2개(targetSets 3,2) 루틴 시작 → addSet 5회 호출(plannedSets 개수만큼), startSession 1회
- [ ] presentation은 repository 직접호출 금지(controller/provider 경유). domain에 flutter import 없음.

### 하지 말 것
- 새 repository/DB/도메인 로직 (P2-01에 있음. 없으면 ask).
- 통계/차트/1RM (P2-02). 공유 템플릿 서버 로직(P3). 캐릭터(P6).
- 과한 애니/모달 중첩.

### 검증 (worker_done 전 필수)
`flutter analyze`(0)와 `flutter test`(전체 통과)를 직접 실행하고, worker_done body에 analyze 이슈 수 + test 통과/실패 개수를 적을 것. 커밋 금지.
