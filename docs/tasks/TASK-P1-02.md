## TASK-P1-02: 운동 세션·세트 기록 (데이터 + 도메인 레이어)

### 목표
사용자가 운동 세션을 시작하고, 종목별 세트(무게·횟수)를 기록·수정·완료·삭제하고, 세션을 종료하면 총 볼륨이 계산되어 로컬에 남는다. **전부 오프라인.** 이번 태스크는 **도메인·데이터·레포지토리·프로바이더·테스트까지**. **화면(UI)과 휴식 타이머는 P1-03에서** 한다.

### 배경 / 현재 상태
- P1-01 완료: `Exercise` 엔티티 + Drift `AppDatabase` + `ExerciseDao` + 시드 60종. `Result`/`Failure` 존재.
- 이번엔 그 위에 세션/세트 기록을 얹는다. `AppDatabase`에 테이블 2개 추가.

### 생성/수정할 파일
- `lib/domain/entities/workout_session.dart` (신규, 순수 Dart)
- `lib/domain/entities/workout_set.dart` (신규, 순수 Dart)
- `lib/domain/repositories/workout_repository.dart` (신규, 추상 인터페이스)
- `lib/domain/usecases/calculate_session_volume.dart` (신규, 순수 함수)
- `lib/data/local/tables/workout_sessions_table.dart` (신규 Drift 테이블)
- `lib/data/local/tables/workout_sets_table.dart` (신규 Drift 테이블)
- `lib/data/local/daos/workout_dao.dart` (신규 DAO)
- `lib/data/local/app_database.dart` (수정: 테이블 2개 + DAO 등록, schemaVersion 2, 마이그레이션)
- `lib/data/repositories/workout_repository_impl.dart` (신규 구현체)
- `lib/features/workout_log/application/workout_providers.dart` (신규 Riverpod 프로바이더)
- `test/domain/calculate_session_volume_test.dart` (신규)
- `test/data/workout_repository_test.dart` (신규)

### 인터페이스 계약 (그대로 구현. 변경 필요하면 먼저 ask)

```dart
// lib/domain/entities/workout_set.dart — 순수 Dart. flutter/drift import 금지.

/// 한 세트 기록. 로컬이 원본이며 동기화 대상(P3).
class WorkoutSet {
  final String id;            // uuid v4, 클라이언트 생성
  final String sessionId;
  final String exerciseId;
  final int setIndex;         // 세션 내 해당 종목의 세트 순번(0-base)
  final double weight;        // kg. 음수 금지(0 허용: 맨몸)
  final int reps;             // 음수 금지
  final double? rpe;          // 1~10, 선택
  final bool isWarmup;        // 볼륨 계산에서 제외됨
  final bool isCompleted;     // 완료 체크 여부
  final int restSeconds;      // 이 세트 후 휴식 목표(초). 기본 0
  final DateTime? completedAt;
  // 동기화 필드 (SSOT §4 규칙)
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;

  const WorkoutSet({
    required this.id,
    required this.sessionId,
    required this.exerciseId,
    required this.setIndex,
    required this.weight,
    required this.reps,
    this.rpe,
    this.isWarmup = false,
    this.isCompleted = false,
    this.restSeconds = 0,
    this.completedAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncStatus = SyncStatus.local,
  });

  WorkoutSet copyWith({ /* 모든 필드 nullable 파라미터 */ });
}

/// 동기화 상태. P3 sync 레이어에서 사용, 지금은 항상 local.
enum SyncStatus { local, pending, synced }
```

```dart
// lib/domain/entities/workout_session.dart — 순수 Dart

class WorkoutSession {
  final String id;            // uuid v4
  final String userId;        // 인증 전 단계: 'local' 고정 상수 사용
  final String? routineId;
  final String? partyId;
  final DateTime startedAt;
  final DateTime? endedAt;    // 진행 중이면 null
  final String? memo;
  final double totalVolume;   // 종료 시 계산되어 저장. 진행 중 0
  // 동기화 필드
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;

  const WorkoutSession({ required this.id, required this.userId, this.routineId,
    this.partyId, required this.startedAt, this.endedAt, this.memo,
    this.totalVolume = 0, required this.updatedAt, this.deletedAt,
    this.syncStatus = SyncStatus.local });

  bool get isActive => endedAt == null && deletedAt == null;
  WorkoutSession copyWith({ /* ... */ });
}
```

```dart
// lib/domain/repositories/workout_repository.dart — 모든 반환 Result, throw 금지

abstract class WorkoutRepository {
  /// 새 세션 시작. userId는 'local' 고정(인증 P3).
  Future<Result<WorkoutSession, Failure>> startSession({String? routineId, String? partyId});

  /// 진행 중인 세션(가장 최근 isActive) 조회. 없으면 Err(NotFoundFailure).
  Future<Result<WorkoutSession, Failure>> getActiveSession();

  /// 세션 종료. 총 볼륨 계산해 저장하고 endedAt 기록.
  Future<Result<WorkoutSession, Failure>> endSession(String sessionId, {String? memo});

  /// 세트 추가. setIndex는 (sessionId, exerciseId) 기준 자동 증가.
  Future<Result<WorkoutSet, Failure>> addSet({
    required String sessionId, required String exerciseId,
    required double weight, required int reps,
    double? rpe, bool isWarmup = false, int restSeconds = 0,
  });

  /// 세트 값 수정(무게/횟수/rpe/warmup/rest).
  Future<Result<WorkoutSet, Failure>> updateSet(WorkoutSet set);

  /// 세트 완료 토글(완료 시 completedAt 기록).
  Future<Result<WorkoutSet, Failure>> completeSet(String setId, {bool completed = true});

  /// 세트 소프트 삭제(deletedAt 설정, 물리 삭제 금지).
  Future<Result<void, Failure>> deleteSet(String setId);

  /// 세션의 세트 목록(삭제 제외, setIndex 순). 실시간 갱신용 Stream.
  Stream<List<WorkoutSet>> watchSets(String sessionId);
}
```

```dart
// lib/domain/usecases/calculate_session_volume.dart — 순수 함수, 테스트 대상
/// 세션 볼륨 = Σ(weight × reps), isWarmup=true 세트 제외, isCompleted=true만 집계.
/// deletedAt != null 세트 제외.
double calculateSessionVolume(Iterable<WorkoutSet> sets);
```

### 구현 요구사항
1. Drift 테이블 2개(`WorkoutSessions`, `WorkoutSets`) 추가. `AppDatabase` schemaVersion 1→2, `MigrationStrategy`로 신규 테이블 생성(기존 Exercises 데이터 보존, 시드 재실행 안 함).
2. enum(`SyncStatus`)은 int index로 저장. `DateTime`은 Drift 기본 매핑.
3. `WorkoutDao`: startSession/getActiveSession/endSession/insertSet/updateSet/getSetsBySession/watchSets(Drift `.watch()`). setIndex 자동증가는 DAO에서 count 기반.
4. `WorkoutRepositoryImpl`: DAO ↔ 엔티티 매핑, `Result` 래핑, DB 예외 → `Err(DatabaseFailure)`. 빈 catch·print 금지. `endSession`은 해당 세션 세트로 `calculateSessionVolume` 호출해 totalVolume 저장.
5. 삭제는 소프트(deletedAt). watchSets/집계는 deletedAt=null만.
6. userId는 `core/constants`에 `kLocalUserId = 'local'` 상수로.
7. 프로바이더: `workoutRepositoryProvider`, `activeSessionProvider`, `sessionSetsProvider(sessionId)`(watchSets 기반 StreamProvider). `riverpod_annotation` code-gen.

### 완료 조건 (DoD)
- [ ] `flutter analyze` 0
- [ ] `dart run build_runner build --delete-conflicting-outputs` 성공, 생성물 커밋
- [ ] `flutter test` 통과. 최소 케이스:
  - `calculateSessionVolume`: 일반 세트 합, **워밍업 제외**, 미완료 제외, 삭제 제외, 빈 목록=0, 맨몸(weight 0)=0
  - startSession → getActiveSession 반환, 두 번째 startSession 후 active는 최신
  - addSet 3개(같은 exercise) → setIndex 0,1,2 자동
  - completeSet → isCompleted/completedAt 설정
  - deleteSet → watchSets/목록에서 빠짐(소프트)
  - endSession → totalVolume = 완료·비워밍업 세트 볼륨, isActive=false
  - 메모리 DB, 마이그레이션(v1→v2) 동작
- [ ] domain 레이어에 flutter/drift/supabase import 없음

### 하지 말 것
- **UI·위젯·화면 금지** (P1-03). 휴식 타이머 로직/위젯 금지(P1-03).
- 1RM·PersonalRecord (P2 stats).
- Supabase/remote/실제 sync (P3). syncStatus 필드는 두되 항상 `local`, 동기화 로직 작성 금지.
- 캐릭터 EXP 연동 (P6).
- 과설계: 이벤트 소싱, CQRS, 제네릭 Repository 베이스클래스 금지.
