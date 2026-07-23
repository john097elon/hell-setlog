## TASK-P2-02: 통계 집계 + 1RM/PR (도메인 + 데이터 레이어)

### 목표
운동 기록에서 통계를 계산한다: 주간 볼륨, 부위별(근육군) 분할, 종목별 1RM 추정·진행 추이, 개인 최고기록(PR). 이번 태스크는 **usecase·엔티티·집계·레포지토리·프로바이더·테스트까지**. **차트 화면(UI)은 P2-02-UI에서.**

### 배경
- P1-02: `WorkoutSession`/`WorkoutSet`(exerciseId, weight, reps, isWarmup, isCompleted, deletedAt), `WorkoutRepository`.
- P1-01: `Exercise`(muscleGroup) + `ExerciseDao`.
- 새 테이블은 `PersonalRecord`만 추가(집계는 기존 데이터 쿼리). schemaVersion 3→4.

### 생성/수정할 파일
- `lib/domain/entities/personal_record.dart` (신규, 순수 Dart)
- `lib/domain/usecases/calculate_one_rep_max.dart` (신규, 순수 함수 — Epley)
- `lib/domain/usecases/aggregate_stats.dart` (신규, 순수 함수 — 세트 목록 → 주간볼륨/부위분할)
- `lib/domain/repositories/stats_repository.dart` (신규)
- `lib/data/local/tables/personal_records_table.dart` (신규 Drift)
- `lib/data/local/daos/stats_dao.dart` (신규 — 집계 쿼리 + PR CRUD)
- `lib/data/local/app_database.dart` (수정: 테이블 + DAO, schemaVersion 3→4 마이그레이션)
- `lib/data/repositories/stats_repository_impl.dart` (신규)
- `lib/features/stats/application/stats_providers.dart` (신규)
- `test/domain/calculate_one_rep_max_test.dart`, `test/domain/aggregate_stats_test.dart`, `test/data/stats_repository_test.dart` (신규)

### 인터페이스 계약 (그대로 구현. 변경 필요하면 먼저 ask)

```dart
// lib/domain/usecases/calculate_one_rep_max.dart — 순수 함수
/// Epley: 1RM = weight × (1 + reps/30). reps<=0이면 0.
/// reps>12면 lowConfidence=true.
class OneRepMax { final double value; final bool lowConfidence; const OneRepMax(this.value, {this.lowConfidence = false}); }
OneRepMax calculateOneRepMax(double weight, int reps);
```

```dart
// lib/domain/usecases/aggregate_stats.dart — 순수 함수. 완료·비워밍업·비삭제 세트만 집계.
/// 근육군별 볼륨 합. (세트 → exerciseId, 근육군은 인자로 받은 맵으로 해석)
Map<MuscleGroup, double> bodyPartVolume(Iterable<WorkoutSet> sets, Map<String, MuscleGroup> exerciseMuscle);
/// 최근 N일 일자별 볼륨. (키 = 날짜 yyyy-MM-dd)
Map<DateTime, double> dailyVolume(Iterable<WorkoutSession> sessions, Iterable<WorkoutSet> sets, {int days = 7});
```

```dart
// lib/domain/entities/personal_record.dart — 순수 Dart
enum PrType { oneRm, volume, reps }
class PersonalRecord {
  final String id; final String userId; final String exerciseId;
  final PrType type; final double value; final DateTime achievedAt; final String sessionId;
  final DateTime updatedAt; final DateTime? deletedAt; final SyncStatus syncStatus;
  const PersonalRecord({ required this.id, required this.userId, required this.exerciseId,
    required this.type, required this.value, required this.achievedAt, required this.sessionId,
    required this.updatedAt, this.deletedAt, this.syncStatus = SyncStatus.local });
}
```

```dart
// lib/domain/repositories/stats_repository.dart — 반환 Result, throw 금지
abstract class StatsRepository {
  Future<Result<Map<DateTime, double>, Failure>> weeklyVolume({int days = 7});
  Future<Result<Map<MuscleGroup, double>, Failure>> bodyPartSplit({int days = 30});
  Future<Result<List<PersonalRecord>, Failure>> personalRecords(String exerciseId);
  /// 세션 종료 후 호출: 해당 세션 세트로 exercise별 1RM/volume PR 갱신(초과 시에만 insert).
  Future<Result<List<PersonalRecord>, Failure>> updateRecordsForSession(String sessionId);
}
```

### 구현 요구사항
1. `calculateOneRepMax`: Epley. reps<=0 → OneRepMax(0). reps>12 → lowConfidence. 계수 30은 `core/constants/`(예: `game_rules.dart` 또는 `stats_constants.dart`)에서.
2. 집계 순수 함수는 완료·비워밍업·비삭제 세트만 대상(`calculateSessionVolume`와 동일 규칙 재사용/일관).
3. `StatsDao`: 기간 내 세션/세트 조인 쿼리, PR CRUD. `Exercise` muscleGroup 조인.
4. `updateRecordsForSession`: SSOT §도메인 — 동일 exercise 기존 최고값 **초과 시에만** PR 기록. 동률은 PR 아님.
5. `StatsRepositoryImpl`: Result 래핑, 예외→Err(DatabaseFailure). 빈 catch·print 금지.
6. schemaVersion 3→4, onUpgrade `from < 4`에서 personalRecords createTable(기존 데이터 보존).
7. 프로바이더: `statsRepositoryProvider`, `weeklyVolumeProvider`, `bodyPartSplitProvider`. riverpod_annotation.

### 완료 조건 (DoD)
- [ ] `flutter analyze` 0
- [ ] `dart run build_runner build --delete-conflicting-outputs` 성공, 생성물 커밋
- [ ] `flutter test` **전체 스위트** 통과. 최소 케이스:
  - `calculateOneRepMax`: 100kg×5 = 116.7 근사, reps=1 → weight, reps>12 → lowConfidence=true, reps<=0 → 0
  - `bodyPartVolume`: 워밍업/미완료/삭제 제외, 근육군별 합 정확
  - `dailyVolume`: 일자별 버킷팅, 빈 날 0/누락
  - PR: 기존 최고 초과 시만 기록, 동률 제외
  - 마이그레이션 v3→v4, 메모리 DB
- [ ] domain 레이어에 flutter/drift import 없음

### 하지 말 것
- **차트 UI·화면 금지** (P2-02-UI). fl_chart 위젯 금지(이번엔 집계까지).
- Supabase/remote/sync (P3). 캐릭터 EXP(P6).
- 과설계.

### 검증 (worker_done 전 필수 — AGENTS.md)
`flutter analyze`(0)와 `flutter test`(전체 통과)를 직접 실행하고 worker_done body에 analyze 이슈 수 + test 통과/실패 개수를 적을 것. 커밋 금지.
