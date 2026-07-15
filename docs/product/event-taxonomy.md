# Hell Setlog — 이벤트 Taxonomy

> **문서 ID**: ELO-21-TAX-001
> **상태**: 확정
> **관련 PRD**: [public-beta-prd.md](./public-beta-prd.md)

---

## 공통 속성

모든 이벤트는 다음 속성을 포함한다:

| 속성 | 타입 | 예시 |
|---|---|---|
| `event_name` | string | `workout_started` |
| `user_id` | integer | 42 |
| `timestamp` | datetime (ISO 8601) | `2026-07-15T12:34:56Z` |
| `session_id` | string (UUID) | `a1b2c3d4-e5f6-7890-abcd-ef1234567890` |

---

## 사용자 이벤트

### signup

발생 조건: POST /api/auth/register 201 응답 직후

| 속성 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `username` | string | Y | 사용자명 |
| `email_domain` | string | Y | email 도메인 (gmail.com, naver.com 등, 전체 email 미저장) |
| `has_character` | boolean | Y | true (회원가입 시 항상 생성) |

### login

발생 조건: POST /api/auth/login 200 응답 직후

| 속성 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `method` | string | Y | `username` 또는 `email` |

### logout

발생 조건: 사용자가 로그아웃 버튼 클릭 시 (프론트엔드 이벤트)

| 속성 | 타입 | 필수 | 설명 |
|---|---|---|---|
| - | - | - | 공통 속성만 |

### account_deleted

발생 조건: 회원탈퇴 API 호출 성공 직후

| 속성 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `reason` | string | N | 사용자 제공 사유 (옵션) |

---

## 파티 이벤트

### party_created

발생 조건: POST /api/parties/ 201 응답 직후 (수동 생성)

| 속성 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `party_id` | integer | Y | 파티 ID |
| `match_type` | string | Y | `manual` |

### party_random_matched

발생 조건: POST /api/parties/random-match 200/201 응답 직후

| 속성 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `party_id` | integer | Y | 파티 ID |
| `joined_existing` | boolean | Y | true=기존 파티, false=새 파티 생성 |
| `party_member_count_before` | integer | Y | 참여 전 active member 수 |

### party_joined

발생 조건: POST /api/parties/join 200 응답 직후

| 속성 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `party_id` | integer | Y | 파티 ID |
| `invite_code_used` | boolean | Y | 초대코드 사용 여부 |
| `party_member_count` | integer | Y | 참여 후 active member 수 |

### party_left

발생 조건: DELETE /api/parties/{id}/leave 200 응답 직후

| 속성 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `party_id` | integer | Y | 파티 ID |
| `was_owner` | boolean | Y | 파티장 여부 |
| `party_member_count_after` | integer | Y | 탈퇴 후 member 수 |

### member_kicked

발생 조건: DELETE /api/parties/{id}/members/{user_id} 200 응답 직후 (퇴장당한 대상 기준)

| 속성 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `party_id` | integer | Y | 파티 ID |
| `kicked_by_owner` | boolean | Y | true |

---

## 운동 이벤트

### workout_started

발생 조건: POST /api/workouts/ 201 응답 직후

| 속성 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `workout_id` | integer | Y | 운동 ID |
| `in_party` | boolean | Y | 파티 연동 여부 |
| `party_id` | integer | N | 연동된 파티 ID (in_party=true 시) |
| `has_notes` | boolean | Y | 운동 메모 입력 여부 |

### setlog_added

발생 조건: POST /api/workouts/{id}/setlogs 201 응답 직후

| 속성 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `workout_id` | integer | Y | 운동 ID |
| `setlog_id` | integer | Y | 세트로그 ID |
| `type` | string | Y | `start` / `mid` / `end` |
| `content_length` | integer | Y | 내용 문자 수 |
| `has_file` | boolean | Y | 파일 첨부 여부 |
| `setlog_count_so_far` | integer | Y | 해당 workout의 누적 setlog 수 |

### workout_ended

발생 조건: POST /api/workouts/{id}/end 200 응답 직후

| 속성 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `workout_id` | integer | Y | 운동 ID |
| `in_party` | boolean | Y | 파티 연동 여부 |
| `party_id` | integer | N | 파티 ID |
| `duration_seconds` | integer | Y | 운동 시간 (초) |
| `setlog_count_total` | integer | Y | 총 setlog 수 |
| `breakthrough_count` | integer | Y | 레벨업 발생 부위 수 (0~7) |
| `breakthrough_parts` | array[string] | Y | 레벨업 부위 목록 (예: ["chest", "arms"]) |
| `total_level_before` | integer | Y | 운동 전 7부위 level 합계 |
| `total_level_after` | integer | Y | 운동 후 7부위 level 합계 |
| `first_workout` | boolean | Y | 해당 사용자의 첫 workout 종료 여부 (Activation 판별용) |

### workout_deleted (Stage 2)

발생 조건: workout 삭제 API 호출 시 (미구현, Stage 2 예약)

---

## 소셜 이벤트

### reaction_added

발생 조건: POST /api/reactions/ 201 응답 직후

| 속성 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `reaction_id` | integer | Y | 반응 ID |
| `target_type` | string | Y | `setlog` / `workout` |
| `target_id` | integer | Y | 대상 ID |
| `emoji` | string | Y | 이모지 (🔥 / 💪 / 👏) |
| `target_owner_id` | integer | Y | 대상 작성자 user_id |
| `party_id` | integer | N | 소속 파티 ID (있을 시) |

### reaction_removed

발생 조건: DELETE /api/reactions/{id} 204 응답 직후

| 속성 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `reaction_id` | integer | Y | 반응 ID |
| `target_type` | string | Y | 대상 타입 |
| `emoji` | string | Y | 이모지 |

---

## 성장 이벤트

### breakthrough

발생 조건: workout 종료 시 level 증가가 1개 이상 발생

| 속성 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `workout_id` | integer | Y | 운동 ID |
| `part` | string | Y | 부위 (chest/back/legs/shoulders/arms/core/stamina) |
| `old_level` | integer | Y | 이전 레벨 |
| `new_level` | integer | Y | 새 레벨 |
| `character_total_level` | integer | Y | 현재 7부위 level 합계 |

### streak_updated

발생 조건: workout 종료 후 streak 재계산 시 (서버 내부 이벤트)

| 속성 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `workout_id` | integer | Y | 운동 ID |
| `current_streak` | integer | Y | 현재 연속 운동일 |
| `longest_streak` | integer | Y | 최장 연속 운동일 |
| `streak_milestone` | boolean | Y | 3/7/14/30일 도달 여부 |

---

## 페이지 뷰 이벤트 (프론트엔드)

> 공개 베타에서는 수집하지 않음. Stage 2 이후 도입 검토.

| 페이지 | event_name | 시점 |
|---|---|---|
| 로그인 | `page_view_login` | 페이지 마운트 |
| 회원가입 | `page_view_register` | 페이지 마운트 |
| 파티 목록 | `page_view_parties` | 페이지 마운트 |
| 파티 룸 | `page_view_party_room` | 페이지 마운트, party_id 포함 |
| 운동 페이지 | `page_view_workout` | 페이지 마운트, workout_id 포함 |
| 설정 | `page_view_settings` | 페이지 마운트 |

---

## 이벤트 로깅 방식

**공개 베타**: 아래 DB 쿼리 테이블의 created_at/status 필드로 이벤트 추론.
별도 events/logs 테이블 없이 운영.

| 이벤트 | 대체 쿼리 대상 |
|---|---|
| signup | users.created_at |
| workout_started | workouts.started_at |
| workout_ended | workouts.ended_at + workouts.status=ended |
| setlog_added | setlogs.created_at |
| breakthrough | body_stats.updated_at + level 변화 |
| party_joined | party_members.joined_at |
| reaction_added | reactions.created_at |
| streak | /streak API 현재값 (서버 계산) |

**Stage 2 이후**: 별도 analytics 테이블 또는 JSON 로그 파일 도입 검토.
