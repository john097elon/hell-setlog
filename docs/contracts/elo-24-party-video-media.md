# ELO-24: 파티 동영상 업로드·재생 계약 (W2)

MVP 계약 문서. 구현 없음. W7·W8이 추가 추측 없이 병렬 구현 가능한 수준으로 고정.

## 재사용 지점 (ELO-13, 신규 인프라·트랜스코딩 없음)

- 업로드 엔드포인트: `backend/routers/media.py:57` `POST /api/media` — 서버 중계 multipart(`UploadFile`), 클라이언트→스토리지 직결 없음.
- 오브젝트 키 생성: `backend/storage.py:119` `generate_object_key(owner_id, content_type) -> "users/{owner_id}/{uuid4().hex}{ext}"`.
- 저장: `backend/storage.py:106` `ObjectStorage.put(key, body, content_type)`.
- 존재 확인: `backend/storage.py:108` `ObjectStorage.head(key)`.
- 재생 URL 발급: `backend/storage.py:112-114` `signed_get_url(key, expires_seconds=SIGNED_URL_SECONDS)`, `SIGNED_URL_SECONDS = 300`(`backend/storage.py:26`). 신규 계약도 300초 그대로 사용.
- 접근 검사: `backend/routers/media.py:35` `_authorize_media_access` — 소유자 또는 Workout/Setlog를 거친 `PartyMember.status == "active"`(`:41-52`) 멤버만 허용. 신규 엔드포인트도 동일 검사 재사용.

## 고정 범위

- 서버 검증: `content_type == video/mp4` + 최대 파일 크기 10 MiB. 그 외 전부 거부.
- 코덱(H.264/AAC-LC)·재생 길이(60초) 검증은 모바일 클라이언트 책임(업로드 전 preflight) — 서버는 검증하지 않음. §후속 강화 범위 참고.
- 트랜스코딩 없음 — 업로드된 파일 그대로 저장·서빙.

## 1. 업로드 엔드포인트

`POST /api/media` (기존 라우터 확장, `content_type`이 `video/mp4`일 때만 아래 검증 경로 적용)

요청: `multipart/form-data`
| 필드 | 타입 | 필수 | 비고 |
|---|---|---|---|
| `file` | binary | Y | `Content-Type: video/mp4` |
| `party_id` | int | Y | 업로더가 활성 멤버여야 함 (`_authorize_media_access` 동일 로직) |

인증: `Depends(get_current_user)` 재사용.

응답 200/201 (JSON):
```json
{
  "key": "users/{owner_id}/{uuid4hex}.mp4",
  "content_type": "video/mp4",
  "size_bytes": 8123456,
  "checksum_sha256": "…",
  "duration_seconds": 42.3,
  "status": "ready"
}
```

## 2. MP4 검증 오류

기존 422/503 패턴(`backend/routers/media.py:66,71,73`)에 아래 사유를 추가. 코덱·재생 길이 서버 검증은 후속 범위(§후속 강화 범위) — 이 계약의 서버는 `content_type`·크기만 본다.

| HTTP | code | 조건 |
|---|---|---|
| 422 | `unsupported_media_type` | `content_type != video/mp4` |
| 422 | `file_too_large` | `size_bytes > 10*1024*1024` |
| 422 | `storage_policy_error` | 기존 `StoragePolicyError` 재사용 |
| 503 | `storage_unavailable` | 기존 `StorageUnavailable` 재사용 |

오류 응답 형식:
```json
{ "error": { "code": "file_too_large", "message": "..." } }
```

## 3. 피드 응답 (`media` 필드)

기존 `FeedEvent`/`FeedEventData`(`backend/schemas.py:214,241`)는 `file_path: Optional[str]`만 가짐. 신규 `media` 필드를 다음 형태로 추가 (기존 `file_path`는 유지, 신규 필드 병행):

```json
{
  "media": {
    "id": "users/{owner_id}/{uuid4hex}.mp4",
    "poster_url": null,
    "duration_seconds": 42.3,
    "size_bytes": 8123456
  }
}
```

- `media`는 비디오 없는 피드 항목에서 `null`.
- `poster_url`은 이 계약에서 항상 `null` (썸네일 생성 미도입 — 후속 강화 범위).

## 4. 재생 URL

`GET /api/media/{key}/playback`

응답 200:
```json
{
  "url": "https://.../signed?...",
  "expires_in_seconds": 300
}
```

- `signed_get_url(key, expires_seconds=300)` 그대로 사용.
- 접근 검사: `_authorize_media_access` 재사용 — 소유자 또는 해당 파티 활성 멤버만.
- 실패: 403 `forbidden`(멤버 아님/비활성), 404 `object_not_found`(`ObjectNotFound`, 기존 패턴).

## 5. 업로드 진행·상태 — 책임 경계

별도 `/status`·processing 상태 엔드포인트 없음 (동기식 서버 중계 업로드라 조회할 진행 상태가 서버에 없음).

- **업로드 진행률**: 서버가 제공하지 않음. 클라이언트가 Axios/XHR `onUploadProgress` 콜백으로 직접 표시.
- **업로드 완료 후 상태**: POST `/api/media` 응답으로 확정. 200/201 = `ready`(§1 응답 본문 그대로 사용), 4xx/5xx = `error`(§2 오류 코드로 사유 판별). 클라이언트는 이 응답 하나로 `ready | error` 상태를 결정하고 별도 폴링을 하지 않는다.
- **재생 가능 여부·60초 preflight**: 업로드 전 클라이언트 책임(§고정 범위). 서버는 검증하지 않는다.
- `plays_inline`(항상 `playsInline` 강제, 전체화면 자동 전환 금지)·`autoplay`(항상 false, 수동 재생만) 은 서버 응답 필드가 아니라 클라이언트 플레이어 구현 규칙으로 고정.

## 후속 강화 범위 (이번 계약 제외)

URL 단기화(300초 미만), 강퇴 직후 URL 회수, 서버 측 코덱/재생 길이 검증, MP4 외 코덱 지원, 썸네일/poster 생성, 업로드 진행 상태 조회 엔드포인트.
