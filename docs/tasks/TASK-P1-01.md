## TASK-P1-01: 운동 DB (Exercise) — 로컬 저장 + 시드 60종 + 검색/필터

### 목표
사용자가 오프라인에서 운동 종목 60종을 이름(한/영)으로 검색하고 근육군·장비로 필터링할 수 있다. 이후 세트 기록(P1-02)이 이 DB를 종목 선택 소스로 쓴다. 이번 태스크는 **데이터·도메인·레포지토리·프로바이더·테스트까지**만 만든다. **화면(UI)은 만들지 않는다.**

### 배경 / 현재 상태
- P0 완료: 라우터, 테마, 5화면 목업, l10n(ko). 
- 아직 없음: Drift, `Result`/`Failure`, 도메인 엔티티, 로컬 DB. 이번 태스크가 이 로컬 데이터 기반을 처음 세운다.

### 생성/수정할 파일
- `pubspec.yaml` (수정: 아래 의존성 추가)
- `lib/core/error/failure.dart` (신규 — 도메인 실패 타입)
- `lib/core/error/result.dart` (신규 — `Result<T, F>` 패턴)
- `lib/domain/entities/exercise.dart` (신규 — 순수 Dart)
- `lib/domain/repositories/exercise_repository.dart` (신규 — 추상 인터페이스)
- `lib/data/local/app_database.dart` (신규 — Drift `AppDatabase`)
- `lib/data/local/tables/exercises_table.dart` (신규 — Drift 테이블)
- `lib/data/local/daos/exercise_dao.dart` (신규 — DAO)
- `lib/data/local/seed/exercise_seed.dart` (신규 — 60종 시드 데이터)
- `lib/data/repositories/exercise_repository_impl.dart` (신규 — 구현체)
- `lib/features/exercise_db/application/exercise_providers.dart` (신규 — Riverpod 프로바이더)
- `test/domain/exercise_test.dart` (신규)
- `test/data/exercise_repository_test.dart` (신규)

### 추가할 의존성 (pubspec.yaml)
```yaml
dependencies:
  drift: ^2.20.0
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.1.0
  path: ^1.9.0
  uuid: ^4.5.0

dev_dependencies:
  drift_dev: ^2.20.0
  mocktail: ^1.0.0
```
> 버전은 pub 최신 호환으로 조정 가능. 조정하면 완료 보고에 명시.

### 인터페이스 계약 (이 시그니처를 그대로 구현. 변경 필요하면 먼저 질문)

```dart
// lib/domain/entities/exercise.dart  — package:flutter/* , drift, supabase import 금지 (순수 Dart)

/// 근육군. 필터·그룹핑의 기준.
enum MuscleGroup { chest, back, shoulders, legs, arms, core, fullBody, other }

/// 사용 장비.
enum Equipment { barbell, dumbbell, machine, cable, bodyweight, kettlebell, band, other }

/// 운동 종목. 로컬 DB가 원본이며 동기화 대상(추후 P3).
class Exercise {
  /// uuid v4 (클라이언트 생성). 시드 종목은 고정 uuid 사용.
  final String id;
  /// 영문/공식 표기명.
  final String name;
  /// 한국어 표기명. 필수(빈 문자열 금지).
  final String nameKo;
  final MuscleGroup muscleGroup;
  final Equipment equipment;
  /// 사용자 커스텀 종목 여부. 시드는 false.
  final bool isCustom;
  /// 썸네일 URL. 시드는 null 허용.
  final String? thumbnailUrl;

  const Exercise({
    required this.id,
    required this.name,
    required this.nameKo,
    required this.muscleGroup,
    required this.equipment,
    this.isCustom = false,
    this.thumbnailUrl,
  });
}
```

```dart
// lib/domain/repositories/exercise_repository.dart

/// 운동 종목 조회. 모든 반환은 Result로 감싼다(예외 throw 금지).
abstract class ExerciseRepository {
  /// 전체 종목.
  Future<Result<List<Exercise>, Failure>> getAll();

  /// 검색+필터. 모든 인자 null이면 getAll과 동일.
  /// query는 name 또는 nameKo에 대소문자 무시 부분일치.
  Future<Result<List<Exercise>, Failure>> search({
    String? query,
    MuscleGroup? muscleGroup,
    Equipment? equipment,
  });

  /// id로 단건. 없으면 Err(NotFoundFailure).
  Future<Result<Exercise, Failure>> getById(String id);
}
```

```dart
// lib/core/error/result.dart — 최소 구현. 과설계 금지.
sealed class Result<T, F> {
  const Result();
  R when<R>({required R Function(T value) ok, required R Function(F failure) err});
  bool get isOk;
}
final class Ok<T, F> extends Result<T, F> { final T value; const Ok(this.value); ... }
final class Err<T, F> extends Result<T, F> { final F failure; const Err(this.failure); ... }
```

```dart
// lib/core/error/failure.dart
sealed class Failure { const Failure(this.message); final String message; }
final class DatabaseFailure extends Failure { const DatabaseFailure([String m = 'DB 오류']) : super(m); }
final class NotFoundFailure extends Failure { const NotFoundFailure([String m = '찾을 수 없음']) : super(m); }
```

### 구현 요구사항
1. Drift `AppDatabase`는 단일 인스턴스. `schemaVersion = 1`. 파일 DB(`path_provider`의 앱 문서 디렉터리). 테스트에서는 `NativeDatabase.memory()` 주입 가능하게 생성자 파라미터로 `QueryExecutor`를 받는다.
2. `Exercises` Drift 테이블: id(text, pk), name(text), nameKo(text), muscleGroup(int enum index), equipment(int enum index), isCustom(bool, default false), thumbnailUrl(text nullable).
3. `ExerciseDao`: `getAll`, `searchExercises(query, muscleGroup, equipment)`, `getById`, `insertAll(seed)`. 검색은 Drift 쿼리의 `LIKE`(nameKo/name, `LOWER` 비교) + enum 필터. 
4. 앱 최초 실행(테이블 비어있을 때)에만 시드 60종 insert. 프로바이더 초기화 시 1회 보장.
5. 시드 60종: 근육군 8종에 고르게 분포. **모든 항목 nameKo 필수**. id는 고정 uuid 문자열(재실행해도 동일). 예: 벤치프레스/스쿼트/데드리프트/오버헤드프레스/바벨로우/랫풀다운/레그프레스/덤벨컬 등 헬스장 표준 종목.
6. `ExerciseRepositoryImpl`은 DAO 결과를 엔티티로 매핑하고 `Result`로 감싼다. DB 예외는 잡아서 `Err(DatabaseFailure)`. **빈 catch 금지, print 금지.**
7. 프로바이더: `exerciseRepositoryProvider`, 검색 상태용 프로바이더. `riverpod_annotation` + code-gen 사용(SSOT 규약). `build_runner` 돌려 생성물 포함.

### 완료 조건 (Definition of Done)
- [ ] `flutter analyze` 경고 0
- [ ] `dart run build_runner build --delete-conflicting-outputs` 성공, 생성물 커밋
- [ ] `flutter test` 전부 통과. 최소 케이스:
  - 시드 개수 == 60, 전 항목 `nameKo` 비어있지 않음
  - `search(query:'벤치')` → 벤치프레스 포함
  - `search(query:'bench')` (영문/대문자 무시) → 벤치프레스 포함
  - `search(muscleGroup: MuscleGroup.legs)` → 다리 종목만
  - `search(query:'벤치', equipment: Equipment.barbell)` → 조합 필터 동작
  - `search()` 인자 없음 → 전체 반환
  - `getById('없는id')` → `Err(NotFoundFailure)`
  - 메모리 DB로 테스트(파일 DB 접근 없이)
- [ ] domain 레이어에 flutter/drift import 없음(검증)

### 하지 말 것
- Supabase/remote/동기화 연동 (P3에서). 지금은 로컬만.
- 커스텀 종목 생성/편집 기능 (범위 밖).
- exercise_db 화면·위젯 (다음 태스크. 이번엔 data+domain+provider+test까지).
- `Result`/`Failure`에 map/flatMap/fold 등 안 쓰는 헬퍼 잔뜩 추가 (필요한 `when`/`isOk`만).
- 검색 성능 최적화용 별도 인덱스/캐시 레이어 (60행이라 불필요. LIKE 쿼리로 충분).
