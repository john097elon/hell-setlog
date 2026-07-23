# 헬셋로그 (HealSetLog) 프로젝트 컨텍스트

## 제품 정의

헬셋로그는 세트 단위 운동 기록에 파티와 성장형 캐릭터를 결합한 헬스 로깅 앱이다. 운동 기록은 지루해 이탈하기 쉽지만, 함께 운동하는 사람과 눈에 보이는 성장이 습관을 만든다는 가설을 검증한다. 타깃은 종이 또는 메모 앱으로 기록 중이거나 기록을 포기한 헬스장 경력 3개월~3년 사용자다.

운동 중 세트 입력은 **탭 3회 이내, 1.5초 이내**여야 한다. 이 원칙과 충돌하는 기능은 뒤로 미룬다.

소셜은 **파티 중심**이다. 전체 공개 글로벌 피드·스토리는 범위 밖이다. 네비게이션의 `운동` 탭은 세트로그·통계·몬스터(캐릭터) 서브탭으로 통합한다. 수익화는 **PRO 월 구독**으로 엘리트/인증 트레이너 파티 참여, 무제한 파티 개설, 고급 통계, 광고 제거를 제공한다(구현은 P7).

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
PartyMission    id, partyId, type, target, progress, periodStart, periodEnd
ChatMessage     id, partyId, userId, body, createdAt
MatchTicket     id, userId, muscleFocus, status(waiting|matched|expired), createdAt, expiresAt

VideoClip       id, userId, setId?, sessionId, storagePath, thumbPath,
                durationMs, visibility(private|party|public), createdAt

Character       userId, stage, bodyType(upper|lower|balanced), appearanceJson, updatedAt
CharacterStat   userId, part(chest|back|shoulders|legs|arms|core|endurance), level, exp
ExpEvent        id, userId, source(set|session|streak|pr|party), part?, amount, createdAt
Subscription    userId, tier(free|pro), status, currentPeriodEnd, provider
```

동기화 대상 테이블은 모두 클라이언트 생성 UUID v4 `id`, `updatedAt`, `deletedAt`, `syncStatus(local|pending|synced)`를 가진다. 충돌은 `updatedAt` 비교의 last-write-wins다.

## 도메인 규칙

- 1RM 추정은 Epley 공식 `1RM = w × (1 + r/30)`이다. reps가 12 초과면 `estimated: low_confidence`다.
- 세션 볼륨은 `Σ(weight × reps)`이며 워밍업은 제외한다.
- PR은 동일 exercise의 기존 최고값을 초과할 때만 기록한다. 동률은 PR이 아니다.
- EXP는 완료 세트 5, 완료 세션 50, PR 200, 파티원과 같은 날 운동 30, 7일 연속 출석 100이다. 하루 상한은 500이다.
- 레벨 필요 EXP는 `100 × level^1.5`이며 스테이지 전환 레벨은 1/10/25/50/100이다.
- **부위별 성장**: 근육군(chest/back/shoulders/legs/arms/core)별 볼륨을 누적해 부위 레벨을 산출한다. 캐릭터 **스테이지 진화는 부위 레벨 합산**이 1/10/25/50/100에 도달할 때 일어난다. 진화 사이 구간에는 부위별 성장만 표시한다. `bodyType`(상체/하체/균형)은 지배 근육군으로 결정된다. 부위 EXP 정확한 계수는 P6에서 확정한다.
- 이 규칙의 상수는 오직 `core/constants/game_rules.dart`에 둔다.

## 개발 순서

| 단계 | 내용 | 완료 기준 |
| --- | --- | --- |
| P0 | 스캐폴딩, 테마, 라우터 | analyze 0 이슈, 5개 빈 화면 라우팅 |
| P1 | 운동 DB, 세트 기록, 휴식 타이머 | 오프라인 운동 1회 완주 기록 |
| P2 | 루틴 템플릿, 통계, 차트 | 루틴 시작, 볼륨·1RM 그래프 |
| P3 | Supabase Auth와 동기화 | 두 기기 기록 일치 |
| P4 | 파티 (생성/초대/멤버 피드, 채팅, 미션, 탐색·부위별 카테고리, 랜덤 매칭) | 초대코드 가입·활동 표시, 파티 채팅, 운동성향 필터 랜덤매칭 |
| P5 | 영상 | 30초 클립 업로드와 파티 피드 재생 |
| P6 | 캐릭터 성장 (부위별 성장 + 합산 진화) | 세션 완료 시 부위 EXP·합산 레벨업·진화 연출 |
| P7 | 수익화 (PRO 구독) | PRO 결제, 엘리트/트레이너 파티·고급 통계·광고 제거 게이팅 |

P1과 P2가 끝나기 전에는 P4 이후의 **실제 데이터·도메인·백엔드 기능**을 작성하지 않는다.

파티 랜덤 매칭은 **운동 성향(목표 부위·시간대) 필터를 최우선**으로 하고 프로필에 소셜 계정 대신 운동 통계를 노출해 데이팅 앱 변질을 방지한다(조사 근거). 채팅은 P3 Supabase Realtime을 전제로 한다.

### 레거시 UI 목업 이식 예외

기존 React 앱에 이미 구현된 화면을 Flutter에서 검토할 수 있도록, P1~P2 완료 전에도 P4~P6 영역의 **프레젠테이션 전용 목업**을 이식할 수 있다. 이 예외는 다음 조건을 모두 지킨다.

- 목업은 메모리 안의 예시 데이터와 화면 내부 상태만 사용한다. Drift, Supabase, 네트워크 요청, 동기화, 실제 인증·영상 업로드는 추가하지 않는다.
- 파티·피드·캐릭터의 실제 도메인 엔티티, Repository, usecase, EXP 계산과 영속화는 각 단계(P4~P6)가 시작될 때 별도 태스크로 구현한다.
- 운동 입력의 탭 3회·1.5초 UX 원칙과 기존 단계 순서는 유지한다.

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
