## TASK-P1-03-REBUILD: 세트로그(운동 기록) 화면 전면 재구축

> 현재 세트로그 UI가 사용 불가 수준(스크린샷 근거). 앱의 **핵심 화면**이므로 Strong/Hevy 급으로 다시 만든다. 데이터/도메인/repository는 그대로(P1-02 사용), **프레젠테이션만 재구축**.

### 현재 문제 (반드시 해결)
1. 세트 행이 좁은 `ListTile`에 스텝퍼를 욱여넣어 숫자가 세로로 겹쳐 보임("15"→"1"/"5"). **열이 안 맞고 판독 불가.**
2. **열 헤더 없음** — 무게/횟수가 뭔지 라벨이 없다.
3. 세트가 **종목별로 그룹화되지 않고** 평평하게 나열됨. 종목명 대신 **UUID(exerciseId) 노출**.
4. 진행 중 세션에서 각 세트가 어느 종목인지, 이름이 안 보인다.

### 목표 UX (Strong/Hevy + `docs/design/ui-reference-hell-log.md`의 세트로그 레이아웃 참고)
- 세션은 **종목 블록**들의 세로 리스트. 각 블록 = 종목명(nameKo) 헤더 + 세트 테이블.
- 세트 테이블 열 헤더: **세트 · KG · 회 · ✓**. 각 세트 = 한 줄에 세트번호 / 무게 / 횟수 / 완료체크가 **정렬된 열**로.
- 무게·횟수 입력: 탭하면 인라인 편집(숫자 키패드, 리스트 안 가림) 또는 넉넉한 폭의 `− 값 +` 스텝퍼(무게 2.5 단위, 횟수 1 단위). 숫자는 절대 겹치지 않게 최소 폭 확보 + `FittedBox`/`tabular-nums`.
- **직전 세트 값 자동 프리필** → 완료 체크 1탭 = 세트 기록(탭 3회/1.5초 원칙).
- 종목 블록 하단 "+ 세트 추가", 화면 하단 "+ 운동 추가"(exercise_picker_sheet 재사용).
- 완료 즉시 휴식 타이머 자동 시작(기존 rest_timer 재사용). 삭제 = 스와이프 + undo 스낵바.
- 세션 종료 = "운동 완료 · 공유"(기존 share_workout_sheet).

### 종목명 조회 (핵심 수정)
- 세트의 `exerciseId`로 종목명(nameKo)을 얻어야 한다. `ExerciseRepository`/`exerciseRepositoryProvider`로 id→Exercise 조회하는 provider 추가(예: `exerciseByIdProvider` 또는 세션 내 종목 목록을 한 번에 로드하는 provider). **UUID를 화면에 절대 노출 금지.**

### 생성/수정 파일 (features/workout_log/presentation)
- `workout_page.dart` (재작성: 종목 블록 리스트 구조)
- `widgets/exercise_block.dart` (신규: 종목명 헤더 + 세트 테이블 + 세트추가)
- `widgets/set_row.dart` (재작성: 정렬된 열, 겹침 없음, 헤더와 정렬)
- `widgets/set_table_header.dart` (신규: 세트/KG/회/완료 헤더)
- `application/` 필요 시 종목명 조회 provider 추가(도메인 로직 아님, 조회 provider만)
- 위젯 테스트 갱신/추가

### 완료 조건 (DoD)
- [ ] `flutter analyze` 0
- [ ] `dart run build_runner build --delete-conflicting-outputs` 성공, 생성물 커밋
- [ ] `flutter test` **전체 스위트** 통과. 위젯 테스트 최소:
  - 종목 블록에 종목명(nameKo)이 표시되고 **UUID가 화면에 없음**(`find.textContaining('0000')` 등으로 UUID 부재 검증)
  - 세트 행: 무게/횟수/완료가 각각 렌더, 완료 1탭 시 completeSet 호출(mocktail)
  - 세트 추가/운동 추가 동작
  - 스와이프 삭제 + undo 스낵바
- [ ] presentation은 repository 직접호출 금지(provider/controller 경유). domain 불변.
- [ ] 세트 행 숫자가 겹치지 않도록 레이아웃 검증(테스트 또는 충분한 폭).

### 하지 말 것
- 도메인/데이터/repository 변경 (P1-02 그대로. 조회 provider만 추가 허용).
- 통계/캐릭터/파티. 새 DB.
- 스텝퍼 폭 부족으로 숫자 겹치는 레이아웃 재발.

### 참고
- `docs/design/ui-reference-hell-log.md` — `.ex-block`/`.set-head`/`.set-row-g` (세트/KG/REPS/체크 그리드)가 목표 레이아웃.
- taste-skill(design-taste-frontend/minimalist-ui) 적용, 다크 유틸리티. 하드코딩 색/폰트 금지, l10n.

### 검증 (worker_done 전 필수 — AGENTS.md)
`flutter analyze`(0)와 `flutter test`(전체 통과)를 직접 실행하고 worker_done body에 결과 수치 명시. 커밋 금지.
