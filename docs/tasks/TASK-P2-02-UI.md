## TASK-P2-02-UI: 통계 화면 (차트)

### 목표
통계 화면에서 이번 주 요약, 주간 볼륨 막대차트, 부위별 분할, 종목별 1RM/볼륨 추이를 본다. **화면 + 위젯테스트**. 새 도메인/데이터 로직 금지(P2-02에 있음).

### 배경
- P2-02: `StatsRepository`(weeklyVolume/bodyPartSplit/personalRecords), `weeklyVolumeProvider`/`bodyPartSplitProvider`, 1RM/집계 usecase.
- 기존 `기록`/`통계` 목업 화면(`features/stats/presentation/stats_page.dart`)을 실제 화면으로 교체.

### 화면/파일 (features/stats/presentation)
- `stats_page.dart` (수정: 목업 → 실제 통계)
- `widgets/weekly_volume_chart.dart` (신규: fl_chart 막대)
- `widgets/body_part_split.dart` (신규: 근육군별 가로 바 + %)
- `widgets/summary_row.dart` (신규: 운동일/볼륨/PR 요약 카드 3개)
- (선택) `widgets/exercise_progress_chart.dart` (종목 선택 + 1RM 라인차트)
- `application/stats_view_controller.dart` (신규 시 — 종목 선택 상태 등, 필요시만)

### 의존성
```yaml
dependencies:
  fl_chart: ^0.69.0   # 버전은 호환 최신으로 조정 가능(조정 시 보고)
```

### UX
- 참조 목업(`docs/design/ui-reference-hell-log.md`) 반영: This Week 요약 3카드, Weekly Volume 막대, Body Part Split 가로바(%).
- 프로바이더 `AsyncValue.when(data/loading/error)` 전부 처리. 데이터 없을 때 빈 상태 표시.
- 하드코딩 색/폰트 금지(`core/theme`), 문자열 l10n, `const`·`ListView.builder`. taste-skill(design-taste-frontend/minimalist-ui) 적용, 다크 유틸리티 톤.
- presentation은 repository 직접호출 금지(provider 경유).

### 완료 조건 (DoD)
- [ ] `flutter analyze` 0
- [ ] `dart run build_runner build --delete-conflicting-outputs` 성공(코드젠 있으면), 생성물 커밋
- [ ] `flutter test` **전체 스위트** 통과. 위젯 테스트 최소:
  - 요약 카드: provider mock 데이터로 운동일/볼륨 값 렌더
  - 부위별 분할: mock 데이터로 근육군 바 개수/라벨 렌더
  - 빈 상태: 데이터 없음 → 빈 상태 위젯 노출
  - (차트 위젯은 렌더 스모크 테스트 — 예외 없이 build)
- [ ] domain에 flutter import 없음 유지

### 하지 말 것
- 새 집계/1RM/PR 로직 (P2-02에 있음. 없으면 ask).
- Supabase(P3)/캐릭터 EXP(P6).
- IA 재구성(운동 탭 서브탭 통합)은 **P2-03에서** — 이번엔 통계 화면만.

### 검증 (worker_done 전 필수 — AGENTS.md)
`flutter analyze`(0)와 `flutter test`(전체 통과)를 직접 실행하고 worker_done body에 analyze 이슈 수 + test 통과/실패 개수를 적을 것. 커밋 금지.
