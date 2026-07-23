## TASK-P2-01: 루틴 템플릿 (데이터 + 도메인 레이어)

### 목표
사용자가 운동 루틴(종목 + 목표 세트/횟수/무게 묶음)을 만들고, 그 루틴으로 세션을 시작하면 계획된 세트가 미리 채워진다. 이번 태스크는 **도메인·데이터·레포지토리·프로바이더·usecase·테스트까지**. **화면(UI)은 P2-01-UI에서.**

### 배경
- P1 완료: Exercise, WorkoutSession/WorkoutSet, WorkoutRepository, AppDatabase(schemaVersion 2).
- 이번엔 Routine/RoutineItem 추가. AppDatabase에 테이블 2개, schemaVersion 2→3 마이그레이션.

### 생성/수정할 파일
- `lib/domain/entities/routine.dart` (신규, 순수 Dart)
- `lib/domain/entities/routine_item.dart` (신규, 순수 Dart)
- `lib/domain/repositories/routine_repository.dart` (신규)
- `lib/domain/usecases/start_session_from_routine.dart` (신규, 순수 함수 — RoutineItem 목록 → 미리 채울 세트 draft 목록 생성)
- `lib/data/local/tables/routines_table.dart` (신규)
- `lib/data/local/tables/routine_items_table.dart` (신규)
- `lib/data/local/daos/routine_dao.dart` (신규)
- `lib/data/local/app_database.dart` (수정: 테이블 2개 + DAO 등록, schemaVersion 3, 마이그레이션에 신규 테이블 createTable)
- `lib/data/repositories/routine_repository_impl.dart` (신규)
- `lib/features/routine/application/routine_providers.dart` (신규)
- `test/domain/start_session_from_routine_test.dart` (신규)
- `test/data/routine_repository_test.dart` (신규)

### 인터페이스 계약 (그대로 구현. 변경 필요하면 먼저 ask)

```dart
// lib/domain/entities/routine.dart — 순수 Dart

class Routine {
  final String id;          // uuid v4
  final String name;
  final String? description;
  final String ownerId;     // 인증 전: kLocalUserId
  final bool isTemplate;    // 공유 템플릿 여부. 지금은 개인 루틴이라 false 기본
  final DateTime createdAt;
  // 동기화 필드 (SSOT §4)
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;   // 기존 workout_set.dart의 SyncStatus 재사용

  const Routine({ required this.id, required this.name, this.description,
    required this.ownerId, this.isTemplate = false, required this.createdAt,
    required this.updatedAt, this.deletedAt, this.syncStatus = SyncStatus.local });
  Routine copyWith({ /* ... */ });
}
```

```dart
// lib/domain/entities/routine_item.dart — 순수 Dart

class RoutineItem {
  final String id;          // uuid v4
  final String routineId;
  final String exerciseId;
  final int order;          // 루틴 내 순서(0-base)
  final int targetSets;     // 목표 세트 수 (>=1)
  final int targetReps;     // 목표 횟수
  final double targetWeight;// 목표 무게(kg, 0 허용)
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;

  const RoutineItem({ required this.id, required this.routineId,
    required this.exerciseId, required this.order, required this.targetSets,
    required this.targetReps, required this.targetWeight,
    required this.updatedAt, this.deletedAt, this.syncStatus = SyncStatus.local });
  RoutineItem copyWith({ /* ... */ });
}
```

```dart
// lib/domain/repositories/routine_repository.dart — 모든 반환 Result, throw 금지

abstract class RoutineRepository {
  Future<Result<Routine, Failure>> createRoutine({required String name, String? description});
  Future<Result<List<Routine>, Failure>> getRoutines();          // deletedAt=null, createdAt desc
  Future<Result<Routine, Failure>> getRoutine(String id);         // 없으면 Err(NotFoundFailure)
  Future<Result<Routine, Failure>> renameRoutine(String id, {required String name, String? description});
  Future<Result<void, Failure>> deleteRoutine(String id);         // 소프트 삭제(아이템도 함께)

  Future<Result<RoutineItem, Failure>> addItem({required String routineId, required String exerciseId,
    required int targetSets, required int targetReps, required double targetWeight}); // order 자동증가
  Future<Result<RoutineItem, Failure>> updateItem(RoutineItem item);
  Future<Result<void, Failure>> removeItem(String itemId);        // 소프트 삭제
  Future<Result<List<RoutineItem>, Failure>> getItems(String routineId); // deletedAt=null, order asc
}
```

```dart
// lib/domain/usecases/start_session_from_routine.dart — 순수 함수, 테스트 대상
/// 루틴 아이템 목록을 세션 시작 시 미리 채울 세트 draft로 변환한다.
/// 각 RoutineItem 당 targetSets 개수만큼 (targetReps, targetWeight) draft 생성, isCompleted=false.
/// 실제 DB 쓰기는 컨트롤러/레포에서. 이 함수는 순수 변환만.
class PlannedSetDraft {
  final String exerciseId; final int reps; final double weight; final bool isWarmup;
  const PlannedSetDraft({required this.exerciseId, required this.reps, required this.weight, this.isWarmup = false});
}
List<PlannedSetDraft> plannedSetsFromRoutine(List<RoutineItem> items);
```

### 구현 요구사항
1. Drift 테이블 `Routines`, `RoutineItems` 추가. `AppDatabase` schemaVersion 2→3, `onUpgrade`에서 `from < 3`일 때 두 테이블 createTable(기존 데이터 보존).
2. enum SyncStatus는 기존 `workout_set.dart` 정의 재사용(중복 정의 금지). int index 저장.
3. `RoutineDao`: 루틴 CRUD + 아이템 CRUD. order/삭제는 P1-02 패턴과 동일(소프트삭제 deletedAt, 자동 order = count 기반).
4. `RoutineRepositoryImpl`: DAO↔엔티티 매핑, Result 래핑, 예외→Err(DatabaseFailure). 빈 catch·print 금지.
5. `deleteRoutine`은 루틴 + 그 아이템 전부 소프트삭제.
6. `plannedSetsFromRoutine`: 순수 함수. targetSets 만큼 반복해 draft 생성.
7. 프로바이더: `routineRepositoryProvider`, `routinesProvider`(목록). riverpod_annotation code-gen.

### 완료 조건 (DoD)
- [ ] `flutter analyze` 0
- [ ] `dart run build_runner build --delete-conflicting-outputs` 성공, 생성물 커밋
- [ ] `flutter test` **전체 스위트** 통과(신규 포함). 최소 케이스:
  - `plannedSetsFromRoutine`: 아이템 2개(targetSets 3,2) → draft 5개, 각 reps/weight 매핑 정확, 빈 목록=빈 결과
  - createRoutine → getRoutines에 포함, getRoutine 반환
  - addItem 3개 → order 0,1,2 자동, getItems order asc
  - deleteRoutine → getRoutines에서 빠지고 getItems도 빈 목록(아이템 함께 소프트삭제)
  - removeItem → getItems에서 빠짐
  - 마이그레이션 v2→v3 동작(기존 Exercise/Workout 데이터 보존), 메모리 DB
- [ ] domain 레이어에 flutter/drift import 없음

### 하지 말 것
- **UI 금지** (P2-01-UI). 통계/차트 금지(P2-02). 1RM 금지(P2-02).
- Supabase/remote/sync (P3). syncStatus 필드만 두고 항상 local.
- 공유 템플릿(isTemplate) 관련 서버 로직 — 필드만 두고 지금은 개인 루틴만.
- 과설계: 제네릭 Repository 베이스, 이벤트소싱 금지.
