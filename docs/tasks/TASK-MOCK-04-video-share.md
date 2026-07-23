## TASK-MOCK-04-video-share: 운동 공유 모달 (프레젠테이션 목업)

> SSOT 목업 예외: **UI 셸만**. 실제 카메라·녹화·업로드·압축은 P5에서(camera/video_compress/Supabase Storage). 이 태스크는 플러그인·권한·네트워크 추가 금지.

### 목표
세트로그의 "운동 완료 · 피드에 공유" 흐름에서 뜨는 **공유 바텀시트**를 목업으로 만든다. 운동 요약 태그, 카메라 자리(플레이스홀더), 녹화 링 버튼, 캡션 입력, 공유 버튼. 실제 카메라 없이 UX만.

### 배경
- 세트로그(`workout_log/presentation/workout_page.dart`)에 "운동 완료" CTA 존재(P1-03).
- 참조 목업(`ui-reference-hell-log.md`)의 Video Share Modal 참고.

### 파일 (features/feed/presentation 또는 workout_log/presentation/widgets)
- `share_workout_sheet.dart` (신규 — 바텀시트 위젯. `showModalBottomSheet`로 표시)
- `widgets/record_ring_button.dart` (신규 — 녹화 링 버튼, 탭 시 녹화중/정지 **UI 상태만** 토글)
- `models/share_view_data.dart` (신규 — 운동 요약 태그 등 mock/전달 데이터, 순수 Dart)
- 연결: 운동 완료 CTA에서 이 시트 열기(기존 흐름에 훅업)

### 화면 내용 (mock)
- 상단: 드래그 핸들 + "운동 공유" 타이틀 + 닫기.
- 운동 요약 태그 칩(예 `BENCH 80KG×4`, `SQUAT 100KG×3`, `+210 XP`) — 전달받은 mock/세션요약.
- 카메라 영역: **플레이스홀더**(카메라 아이콘 + "카메라 미리보기 (P5)" 문구). 실제 카메라 프리뷰 없음.
- 녹화 링 버튼: 탭 시 녹화중 상태 표시(빨간 사각형 + 타이머 텍스트 mock 증가) ↔ 정지. 실제 녹화 없음.
- 캡션 입력(TextField) + 태그.
- 공유 버튼: 탭 시 시트 닫고 "피드에 공유됨(mock)" 스낵바.

### UX
- `showModalBottomSheet` + 드래그. 하드코딩 색/폰트 금지(core/theme), l10n, taste-skill, const.
- 실제 카메라/파일/업로드/압축/네트워크 **절대 금지**. 타이머는 UI용 로컬 Ticker/상태.
- `dispose`에서 타이머/컨트롤러 해제.

### 완료 조건 (DoD)
- [ ] `flutter analyze` 0
- [ ] `dart run build_runner build --delete-conflicting-outputs` 성공(있으면), 생성물 커밋
- [ ] `flutter test` **전체 스위트** 통과. 위젯 테스트 최소:
  - 시트 열림 시 요약 태그·카메라 플레이스홀더·녹화 버튼·공유 버튼 렌더
  - 녹화 버튼 탭 시 녹화중 UI 상태 전환
  - 공유 버튼 탭 시 시트 닫힘 + 스낵바
- [ ] camera/video_compress 등 플러그인 미추가. 실 업로드 없음. domain 불변.

### 하지 말 것
- 실제 카메라(camera 플러그인)·녹화·video_compress·Supabase Storage 업로드 (P5).
- 권한 요청. 새 도메인 로직.

### 검증 (worker_done 전 필수 — AGENTS.md)
`flutter analyze`(0)와 `flutter test`(전체 통과)를 직접 실행하고 worker_done body에 결과 수치 명시. 커밋 금지.
