## TASK-MOCK-03-settings: 설정/프로필 화면 (프레젠테이션 목업)

> SSOT 목업 예외: **화면 내부 mock/로컬 상태만**. 실제 인증·구독결제·서버 설정 저장은 P3/P7에서. Supabase/네트워크/결제 SDK 금지.

### 목표
`프로필` 탭을 참조 목업(`docs/design/ui-reference-hell-log.md`) 기반 설정/프로필 화면으로 교체. 프로필 카드 + 알림 토글 + 프라이버시 + 앱설정(단위/언어/다크) + PRO 진입 + 기타. 토글·선택은 로컬 상태로 흉내만.

### 파일 (features/settings/presentation 또는 features/character/presentation 정리)
- `settings_page.dart` (신규 — 프로필 탭 실제 화면)
- `widgets/setting_section.dart`, `widgets/setting_row.dart`, `widgets/setting_toggle.dart` (신규 — 재사용 행/섹션/토글)
- `application/settings_controller.dart` (신규 — 토글/선택 **로컬 상태** Riverpod. 영속화는 하지 않거나, 하더라도 SharedPreferences까지만; 이번엔 인메모리 상태로 충분)
- `models/settings_view_data.dart` (mock 프로필/버전 등)
- 라우터/셸: 프로필 탭이 settings_page 가리키게(기존 profile 목업 대체)

### 화면 내용 (mock)
- 프로필 카드: 아바타(이모지/플레이스홀더), 이름(예 "나"), LV·총XP mock, 편집 버튼(이름 편집 다이얼로그 mock).
- 알림: 운동 리마인더 / 파티 알림 / 채팅 알림 / 몬스터 성장 알림 토글(로컬 상태).
- 개인정보: 피드 공개범위 / 운동기록 공개 (선택 행, 탭 시 mock 시트/스낵바).
- 앱설정: 다크모드 토글, 언어(한국어), 무게 단위(kg/lb 선택 — 로컬 상태).
- 구독: HELL-LOG PRO 업그레이드 행(탭 시 PRO 안내 시트/스낵바 mock).
- 기타: 공지사항/문의/개인정보처리방침/앱버전(v0.1.0). 로그아웃(mock 스낵바).

### UX
- 토글/단위 선택은 `settings_controller`의 로컬 상태. 하드코딩 색/폰트 금지(core/theme), l10n, taste-skill, const.
- 실제 저장/인증/결제 없음 — 전부 흉내.

### 완료 조건 (DoD)
- [ ] `flutter analyze` 0
- [ ] `dart run build_runner build --delete-conflicting-outputs` 성공, 생성물 커밋
- [ ] `flutter test` **전체 스위트** 통과. 위젯 테스트 최소:
  - settings_page 섹션/행 렌더(프로필/알림/앱설정/구독/기타)
  - 토글 탭 시 상태 반영
  - 무게 단위 kg↔lb 선택 반영
- [ ] 실 인증/결제/서버저장 없음. domain 불변.

### 하지 말 것
- 실제 Auth/Supabase/결제 SDK/서버 설정 저장 (P3/P7).
- 새 도메인 로직. 다크모드 실제 테마 토글 배선까지는 선택(안 하면 UI만).

### 검증 (worker_done 전 필수 — AGENTS.md)
`flutter analyze`(0)와 `flutter test`(전체 통과)를 직접 실행하고 worker_done body에 결과 수치 명시. 커밋 금지.
