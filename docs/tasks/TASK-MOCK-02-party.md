## TASK-MOCK-02-party: 파티 3탭 화면 (프레젠테이션 목업)

> SSOT 목업 예외: **화면 내부 mock 데이터만**. 실제 Party/PartyMember/Chat 도메인·Repository·Realtime·동기화는 P4에서. Drift/Supabase/네트워크 금지.

### 목표
파티 탭을 참조 목업(`docs/design/ui-reference-hell-log.md`) 기반 3서브탭 화면으로 교체: 내파티 / 탐색 / 채팅. 전부 mock 데이터로 룩앤필만.

### 배경
- P2-03에서 파티 탭은 기존 P0 목업(party_list_page 등).
- 이번엔 참조 IA(내파티/탐색/채팅)로 재구성. 여전히 목업(실동작 P4).

### 파일 (features/party/presentation)
- `party_page.dart` (신규 — 3서브탭 컨테이너, 상단 탭바 + "+ 개설")
- `widgets/my_party_panel.dart` (내파티: 파티카드[이름·멤버·미션진행률] + RANDOM MATCH 카드 + 친구초대 행)
- `widgets/explore_panel.dart` (탐색: 검색바 + 부위별 카테고리 칩 + 파티 목록 + PRO 배너)
- `widgets/party_chat_panel.dart` (채팅: 메시지 버블 목록 + 입력바, mock 전송 = 로컬 리스트 추가만)
- `models/party_view_data.dart` (화면전용 mock 뷰모델, 순수 Dart)
- 라우터/셸: 파티 탭이 party_page 가리키게(기존 파티 목업 라우트 대체)

### 화면 내용 (mock)
- **내파티**: 파티카드(예 "번개 레이더스", 3/4명, 오늘 +240XP, 미션 3/4 진행바), RANDOM MATCH 카드(GO 버튼, 탭 시 mock 스피너 스낵바/다이얼로그), 친구초대 가로 스크롤(아바타+이름+LV+초대버튼, 탭 시 "초대됨" 토글 mock).
- **탐색**: 검색 인풋(로컬 필터), 부위별 칩(전체/가슴/등/하체/어깨/팔/전신), 파티 목록 카드(이름·인원·참가버튼 mock), PRO 전용 배너(탭 시 PRO 안내 스낵바).
- **채팅**: 파티 채팅 버블(mock 메시지 몇 개) + 하단 입력바(전송 시 로컬 리스트에 내 버블 추가, 네트워크 없음).

### UX
- mock 데이터는 `party_view_data.dart`에. 하드코딩 색/폰트 금지(core/theme), l10n, taste-skill, 다크 유틸리티, const·ListView.builder.
- 실제 매칭/채팅 전송/초대는 **동작 흉내만**(로컬 상태). 네트워크·DB·Realtime 절대 금지.

### 완료 조건 (DoD)
- [ ] `flutter analyze` 0
- [ ] `dart run build_runner build --delete-conflicting-outputs` 성공(있으면), 생성물 커밋
- [ ] `flutter test` **전체 스위트** 통과. 위젯 테스트 최소:
  - 파티 3서브탭 렌더 및 전환
  - 내파티: 파티카드 + RANDOM MATCH 카드 존재
  - 탐색: 카테고리 칩 렌더 + 검색 필터 동작(mock 목록 줄어듦)
  - 채팅: 입력 후 전송 시 버블 추가
- [ ] 실 도메인/Repository/Realtime 없음(mock만). domain 불변.

### 하지 말 것
- 실 Party/PartyMember/PartyPost/ChatMessage 엔티티·Repository·Realtime·동기화 (P4).
- Supabase/네트워크. 랜덤매칭 실로직(P4). 새 도메인 로직.

### 검증 (worker_done 전 필수 — AGENTS.md)
`flutter analyze`(0)와 `flutter test`(전체 통과)를 직접 실행하고 worker_done body에 결과 수치 명시. 커밋 금지.
