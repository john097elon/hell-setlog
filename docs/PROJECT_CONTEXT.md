# 헬셋로그 (HealSetLog) 프로젝트 컨텍스트

## 제품 정의

헬셋로그는 세트 단위 운동 기록에 파티와 성장형 캐릭터를 결합한 헬스 로깅 앱이다. 운동 기록은 지루해 이탈하기 쉽지만, 함께 운동하는 사람과 눈에 보이는 성장이 습관을 만든다는 가설을 검증한다. 타깃은 종이 또는 메모 앱으로 기록 중이거나 기록을 포기한 헬스장 경력 3개월~3년 사용자다.

운동 중 세트 입력은 **탭 3회 이내, 1.5초 이내**여야 한다. 이 원칙과 충돌하는 기능은 뒤로 미룬다.

## 확정 기술 스택

| 영역 | 선택 |
| --- | --- |
| 프레임워크 | Flutter 3.x, Dart 3.x (iOS + Android) |
| 상태관리 | Riverpod 2.x, code generation 사용 |
| 라우팅 | go_router |
| 로컬 DB | Drift SQLite, 오프라인 퍼스트와 로컬 원본 |
| 백엔드 | Supabase Postgres, Auth, Storage, Realtime |
| 동기화 | `updatedAt` + soft delete 기반 커스텀 LWW sync layer |
| 영상 | Supabase Storage + video_compress, 최대 30초·720p |
| 차트 | fl_chart |
| 테스트 | flutter_test + mocktail, 도메인은 순수 Dart 단위 테스트 |
| CI | GitHub Actions: analyze → test → build |

## 아키텍처

Feature-first 3레이어이며 의존성은 항상 안쪽으로 향한다.

```text
lib/
  core/                 # 테마, 라우터, 에러, 확장, DI
  data/
    local/              # Drift 테이블과 DAO
    remote/             # Supabase 클라이언트와 DTO
    repositories/       # Repository 구현체
  domain/
    entities/           # 순수 Dart 모델
    repositories/       # Repository 추상 인터페이스
    usecases/           # 비즈니스 로직
  features/
    workout_log/ routine/ stats/ timer/ exercise_db/
    party/ feed/
    character/
      presentation/
      application/
```

- `domain/`은 `package:flutter/*`, Drift, Supabase를 import하지 않는다.
- 위젯은 Repository를 직접 호출하지 않고 controller 또는 usecase를 경유한다.
- feature끼리 직접 import하지 않는다. 공유는 `domain/` 또는 `core/`로 올린다.

## 핵심 데이터 모델

```text
Exercise        id, name, nameKo, muscleGroup, equipment, isCustom, thumbnailUrl
Routine         id, name, description, ownerId, isTemplate, createdAt
RoutineItem     id, routineId, exerciseId, order, targetSets, targetReps, targetWeight
WorkoutSession  id, userId, routineId?, partyId?, startedAt, endedAt, memo, totalVolume
WorkoutSet      id, sessionId, exerciseId, setIndex, weight, reps, rpe?,
                isWarmup, isCompleted, restSeconds, completedAt
PersonalRecord  id, userId, exerciseId, type(1RM|volume|reps), value, achievedAt, sessionId

Party           id, name, description, ownerId, inviteCode, memberLimit, createdAt
PartyMember     partyId, userId, role(owner|member), joinedAt, streakDays
PartyPost       id, partyId, userId, sessionId?, type(log|video|text), body, createdAt

VideoClip       id, userId, setId?, sessionId, storagePath, thumbPath,
                durationMs, visibility(private|party|public), createdAt

Character       userId, level, exp, stage, appearanceJson, updatedAt
CharacterStat   userId, statType(strength|endurance|consistency), value
ExpEvent        id, userId, source(set|session|streak|pr|party), amount, createdAt
```

동기화 대상 테이블은 모두 클라이언트 생성 UUID v4 `id`, `updatedAt`, `deletedAt`, `syncStatus(local|pending|synced)`를 가진다. 충돌은 `updatedAt` 비교의 last-write-wins다.

## 도메인 규칙

- 1RM 추정은 Epley 공식 `1RM = w × (1 + r/30)`이다. reps가 12 초과면 `estimated: low_confidence`다.
- 세션 볼륨은 `Σ(weight × reps)`이며 워밍업은 제외한다.
- PR은 동일 exercise의 기존 최고값을 초과할 때만 기록한다. 동률은 PR이 아니다.
- EXP는 완료 세트 5, 완료 세션 50, PR 200, 파티원과 같은 날 운동 30, 7일 연속 출석 100이다. 하루 상한은 500이다.
- 레벨 필요 EXP는 `100 × level^1.5`이며 스테이지 전환 레벨은 1/10/25/50/100이다.
- 이 규칙의 상수는 오직 `core/constants/game_rules.dart`에 둔다.

## 개발 순서

| 단계 | 내용 | 완료 기준 |
| --- | --- | --- |
| P0 | 스캐폴딩, 테마, 라우터 | analyze 0 이슈, 5개 빈 화면 라우팅 |
| P1 | 운동 DB, 세트 기록, 휴식 타이머 | 오프라인 운동 1회 완주 기록 |
| P2 | 루틴 템플릿, 통계, 차트 | 루틴 시작, 볼륨·1RM 그래프 |
| P3 | Supabase Auth와 동기화 | 두 기기 기록 일치 |
| P4 | 파티 | 초대코드 가입과 활동 표시 |
| P5 | 영상 | 30초 클립 업로드와 파티 피드 재생 |
| P6 | 캐릭터 성장 | 세션 완료 시 EXP와 레벨업 연출 |

P1과 P2가 끝나기 전에는 P4 이후 코드를 작성하지 않는다.

## 코딩 규약과 UX

- 파일·디렉터리는 `snake_case`, 클래스는 `PascalCase`를 사용한다.
- public 클래스·함수에는 한국어 `///` 문서 주석을 작성한다.
- 파일 300줄, 위젯 `build` 80줄을 넘기기 전에 분리를 검토한다.
- 매직 넘버 대신 `core/constants/`를 사용한다. `print()`, `dynamic`, 빈 `catch {}`는 금지한다.
- 오류는 `Result<T, Failure>`로 반환하고 도메인 레이어에서 예외를 throw하지 않는다.
- 위젯은 가능한 `const`를 사용하고 리스트는 `ListView.builder`를 사용한다. `ref.watch` 범위를 최소화한다.
- 문자열은 처음부터 l10n으로 분리한다. 비동기는 `AsyncValue`의 data/loading/error를 모두 처리한다.
- 직전 세트의 무게·횟수를 미리 채우고, 완료는 한 번의 탭으로 처리한다. 완료 즉시 휴식 타이머를 시작하며 삭제는 확인 다이얼로그 대신 스와이프와 undo 스낵바를 사용한다.
- 커밋은 Conventional Commits를 사용하고 브랜치는 단계 접두사를 사용한다.
