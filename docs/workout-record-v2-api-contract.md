# ELO-23: 운동 카탈로그·세트 기록 v2 API 계약 (W1)

MVP 계약 문서. 구현 없음. W3·W4·W5가 추가 추측 없이 병렬 구현 가능한 수준으로 고정.

## 재사용 지점 (ELO-13 워크아웃 도메인, ELO-20 부위 taxonomy, ELO-14 GrowthEvent)

- 워크아웃 소유: `backend/routers/workouts.py:45-80` `POST /workouts` — 세트 기록은 반드시 `Workout.status == "active"`에 귀속(`:360-361`의 활성 체크와 동일 규칙).
- 부위 taxonomy: `backend/growth.py:8-16` `BODY_PARTS = (chest, back, legs, shoulders, arms, core, stamina)`. 신규 부위 추가 없음 — `Exercise.body_part`는 이 7값 CHECK 제약(`backend/models.py:286-289`의 `ck_body_stat_part`와 동일 패턴)을 그대로 재사용.
- GrowthEvent 멱등 제약: `backend/models.py:308-311` `UniqueConstraint("workout_id", "body_part", name="uq_growth_event_workout_part")`. v2 세트 기록도 이 제약을 그대로 쓴다 — 워크아웃당 부위별 GrowthEvent는 1건이 원칙이며, v2는 새 유니크 제약을 만들지 않는다.
- 성장 공식: `backend/growth.py:44-95` `compute_growth(duration_seconds, setlog_contents, current_stats, daily_used)`, `FORMULA_VERSION = 1`. 신규 성장 엔진 금지 — v2 세트 데이터는 기존 `compute_growth`의 입력을 대체/보강하는 어댑터로만 연결한다(§6).
- 종료 플로우: `backend/routers/workouts.py:205-337` `POST /workouts/{id}/end` — GrowthEvent 발급은 계속 이 엔드포인트가 담당한다. v2 세트 기록 자체는 GrowthEvent를 만들지 않는다.

## 고정 범위

- MVP는 카탈로그 조회 + 기록 생성·상세·목록·캘린더 집계까지만. 수정/삭제는 후속 범위(§7).
- 제출된 기록(`WorkoutRecord`)과 그 하위 세트(`ExerciseSet`)는 immutable — PATCH/DELETE 엔드포인트 없음.
- 신규 부위 체계·신규 성장 엔진·기존 XP 재migration 금지.

## 0. 데이터 모델 (신규 테이블)

### `exercises` (카탈로그, 시드 데이터 — 사용자 생성 아님)

| 컬럼 | 타입 | 비고 |
|---|---|---|
| `id` | int PK | |
| `canonical_name` | string(100) unique | 예: `bench_press` |
| `display_name_kr` | string(100) | 예: `벤치프레스` |
| `unit_kind` | string(20), CHECK IN (`reps_weight`, `time`, `distance`) | 세트 필드 결정 |
| `body_part` | string(20), CHECK IN 기존 7부위 | `growth.BODY_PARTS`와 동일 값만 |

### `workout_records` (운동별 1건, immutable)

| 컬럼 | 타입 | 비고 |
|---|---|---|
| `id` | int PK | |
| `workout_id` | FK → `workouts.id` | 반드시 `status == "active"`인 워크아웃 소유자만 생성 가능 |
| `user_id` | FK → `users.id` | |
| `exercise_id` | FK → `exercises.id` | |
| `performed_at` | datetime(tz) | 클라이언트 지정, 기본값 서버 `now()` |
| `status` | string(20), CHECK IN (`submitted`) | MVP는 `submitted` 고정값 1종만 — 후속 범위에서 상태 확장 |
| `idempotency_key` | string(100) nullable | §5 |
| `created_at` | datetime(tz) | |

`UniqueConstraint(user_id, idempotency_key)` — `idempotency_key IS NOT NULL`인 행에만 적용(부분 유니크 인덱스, `uq_body_stat`류 명명 규칙과 동일하게 `uq_workout_record_idempotency`).

### `exercise_sets` (하위, immutable)

| 컬럼 | 타입 | 비고 |
|---|---|---|
| `id` | int PK | |
| `workout_record_id` | FK → `workout_records.id` | |
| `set_index` | int | 0-base, 같은 `workout_record_id` 내에서 unique |
| `reps` | int nullable | `unit_kind == reps_weight`일 때만 |
| `weight_kg` | numeric nullable | `unit_kind == reps_weight`일 때만, 맨몸 운동은 `0` |
| `duration_seconds` | int nullable | `unit_kind == time`일 때만 |
| `distance_meters` | numeric nullable | `unit_kind == distance`일 때만 |

`unit_kind`에 해당하지 않는 필드는 반드시 `null` — 요청 검증에서 강제(§1).

## 1. `GET /api/exercises`

인증: `Depends(get_current_user)` 재사용(읽기 전용, 파티 무관).

응답 200:
```json
[
  {
    "id": 1,
    "canonical_name": "bench_press",
    "display_name_kr": "벤치프레스",
    "unit_kind": "reps_weight",
    "body_part": "chest"
  }
]
```

쿼리 파라미터: `body_part`(optional, 7값 중 하나) — 필터.

## 2. `POST /api/workout-records`

요청 헤더: `X-Idempotency-Key: <string, optional>` — §5.

요청 바디:
```json
{
  "workout_id": 123,
  "exercise_id": 1,
  "performed_at": "2026-07-16T05:30:00Z",
  "sets": [
    { "set_index": 0, "reps": 10, "weight_kg": 60 },
    { "set_index": 1, "reps": 8, "weight_kg": 65 }
  ]
}
```

검증 (모두 422, `detail`은 `backend/routers/workouts.py:65` 스타일의 dict):
- `workout_id`가 존재하지 않거나 `current_user`의 소유가 아님 → 404 (`workouts.py:106-107`과 동일하게 소유권 불일치도 404로 통일, enumeration 방지).
- `workout.status != "active"` → 409 `{"detail": {"message": "진행 중인 운동에만 기록할 수 있습니다"}}` (`workouts.py:360-361` 문구 재사용).
- `exercise_id` 미존재 → 404 `{"detail": "Exercise not found"}`.
- `sets`가 빈 배열 → 422 `{"detail": "세트가 최소 1개 필요합니다"}`.
- `set_index` 중복 → 422 `{"detail": "set_index는 중복될 수 없습니다"}`.
- `exercise.unit_kind`와 맞지 않는 필드가 채워짐(예: `reps_weight`인데 `duration_seconds` 지정) → 422 `{"detail": "unit_kind에 맞지 않는 세트 필드입니다"}`.

응답 201: §3의 `WorkoutRecordOut`과 동일 스키마.

## 3. `GET /api/workout-records/{id}`

인증: 소유자만(`workout.user_id == current_user.id`), 아니면 404(enumeration 방지, `workouts.py:106-107` 패턴).

응답 200:
```json
{
  "id": 501,
  "workout_id": 123,
  "exercise": {
    "id": 1,
    "canonical_name": "bench_press",
    "display_name_kr": "벤치프레스",
    "unit_kind": "reps_weight",
    "body_part": "chest"
  },
  "performed_at": "2026-07-16T05:30:00Z",
  "status": "submitted",
  "sets": [
    { "set_index": 0, "reps": 10, "weight_kg": 60 },
    { "set_index": 1, "reps": 8, "weight_kg": 65 }
  ],
  "created_at": "2026-07-16T05:30:05Z"
}
```

## 4. `GET /api/workout-records` (cursor 목록)

쿼리 파라미터:
| 파라미터 | 타입 | 비고 |
|---|---|---|
| `workout_id` | int, optional | 특정 워크아웃으로 필터 |
| `body_part` | string, optional | 7값 중 하나, `exercise.body_part` 필터 |
| `from` / `to` | datetime, optional | `performed_at` 범위 |
| `cursor` | string, optional | §4.1 |
| `limit` | int, default 20, 1-100 | |

응답 200:
```json
{
  "items": [ /* WorkoutRecordOut[], performed_at desc, id desc */ ],
  "next_cursor": "eyJwZXJmb3JtZWRfYXQiOiIyMDI2LTA3LTE2VDA1OjMwOjAwWiIsImlkIjo1MDF9",
  "has_more": true
}
```

### 4.1 커서 인코딩

`cursor` = base64url(JSON `{"performed_at": "<ISO8601>", "id": <int>}`) — 마지막으로 받은 항목의 값. 서버는 `(performed_at, id) < (cursor.performed_at, cursor.id)` (내림차순 keyset)로 다음 페이지를 조회. 잘못된 형식의 cursor → 400 `{"detail": "invalid cursor"}`.

## 5. 멱등성 (`X-Idempotency-Key`)

- 클라이언트가 헤더를 보내면 `(user_id, idempotency_key)`로 §0의 부분 유니크 인덱스에 저장.
- 동일 키로 재요청 시: 새로 만들지 않고 기존 `WorkoutRecordOut`을 201로 그대로 반환(재시도 안전).
- 헤더 생략 시 멱등 보장 없음 — 매 요청이 새 레코드.
- 헤더 값이 다른 `workout_id`/`exercise_id`/`sets`와 함께 재사용됨 → 409 `{"detail": "idempotency key already used with a different request"}`.

## 6. GrowthEvent 어댑터 연결

- v2 세트 기록은 GrowthEvent를 직접 만들지 않는다. `POST /workouts/{id}/end`(`workouts.py:205`)가 계속 유일한 발급 지점이다.
- `end_workout`은 기존 `setlog_contents` 키워드 매칭(`growth.py:58-59`) 대신, 해당 워크아웃에 제출된 `workout_records`가 있으면 그 `exercise.body_part`별 세트 수를 `compute_growth`의 "부위 언급" 신호로 매핑한다 — `compute_growth` 시그니처와 `FORMULA_VERSION` 자체는 변경하지 않는다(입력 산출 전 단계에서만 흡수).
- v2 기록이 없는 워크아웃은 기존 setlog 키워드 경로를 그대로 유지(하위 호환).
- 발급되는 `GrowthEvent`는 여전히 `(workout_id, body_part)` 유니크 제약(`models.py:309-311`) 하나로 귀결 — v2 어댑터가 같은 워크아웃·부위에 대해 이 논리 키로 중복 발급을 방지한다: `growth_event:{workout_id}:{body_part}:v{formula_version}`. 이 키는 DB 컬럼이 아니라 어댑터 내부 dedup/로그 키이며, 실제 유일성은 기존 `uq_growth_event_workout_part` 제약이 담보한다.

## 7. 캘린더 집계

`GET /api/workout-records/calendar`

쿼리 파라미터:
| 파라미터 | 타입 | 비고 |
|---|---|---|
| `from` / `to` | date (`YYYY-MM-DD`) | 필수 |
| `tz` | string, IANA 타임존, 예: `Asia/Seoul` | 필수 — 서버는 UTC 저장된 `performed_at`을 이 타임존 기준 로컬 날짜로 버킷팅 |

응답 200:
```json
{
  "days": [
    {
      "date": "2026-07-16",
      "record_count": 3,
      "body_parts": ["chest", "arms"]
    }
  ]
}
```

- `date`는 `tz` 기준 로컬 캘린더 날짜. 서버가 `performed_at`(UTC) → `tz` 변환 후 날짜만 추출.
- `body_parts`는 해당 로컬 날짜에 기록이 있었던 부위의 중복 제거 목록(순서: `growth.BODY_PARTS` 순).
- `from`/`to` 범위 밖 또는 잘못된 `tz` 문자열 → 400 `{"detail": "invalid tz"}`.

## 후속 범위 (이번 계약 제외)

`WorkoutRecord`/`ExerciseSet` 수정·삭제, 보상/정정 규칙, 사용자 정의 운동 추가, `status` enum 확장(예: `draft`), 세트별 RPE/템포 등 부가 필드.
