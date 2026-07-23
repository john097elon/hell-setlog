## TASK-MOCK-01-monster: 몬스터 화면 (프레젠테이션 목업)

> SSOT "레거시 UI 목업 이식 예외" 적용: **화면 내부 mock 데이터만**. 실제 Character 도메인·Repository·EXP 계산·영속화는 P6에서. Drift/Supabase/네트워크 추가 금지.

### 목표
운동 탭의 `몬스터` 서브탭 플레이스홀더를 실제 화면으로 교체. 캐릭터 스프라이트, 스테이지/레벨, 부위별 스탯, EXP 바를 mock 데이터로 보여준다. 이후 P6에서 실데이터로 교체.

### 배경
- P2-03에서 `몬스터` 서브탭은 "곧 만나요" 플레이스홀더.
- 캐릭터 v0 스프라이트 존재: `assets/character/stage1_nyaongi.png` ~ `stage5_nyagwanwang.png` (96x96).
- 설계: `docs/design/character-spec.md` (부위별 성장 + 합산 진화 + bodyType).

### 파일 (features/character/presentation)
- `monster_page.dart` (신규 — 몬스터 서브탭 실제 화면. workout_tab_page의 몬스터 자리에 연결)
- `widgets/monster_stat_grid.dart` (신규 — 부위별 스탯 카드 그리드)
- `models/monster_view_data.dart` (신규 — **화면 전용 mock 뷰모델**, 순수 Dart. 도메인 엔티티 아님, presentation 로컬)
- `pubspec.yaml` (수정: `assets/character/` 등록)

### 화면 내용 (mock)
- 상단: 캐릭터 이름(예: 냐옹이~냐관왕 중 mock 스테이지), `LV.__`, bodyType 라벨(상체/하체/균형).
- 중앙: 현재 스테이지 스프라이트 이미지(`assets/character/stageN_*.png`, `Image.asset`, `FilterQuality.none`으로 픽셀 또렷).
- EXP 바: mock 진행률(예: 820/1000).
- 부위별 스탯 그리드: ARM / LEG / CORE / ENDURE (또는 근육군 6종 중 대표) — 각 라벨 + mock 값 + 바. `docs/design/character-spec.md`의 부위별 성장 반영.
- (선택) 진화 미리보기: 다음 스테이지 실루엣 흐리게.

### UX
- mock 데이터는 `monster_view_data.dart`에 상수/팩토리로. 하드코딩 색/폰트 금지(`core/theme`), 문자열 l10n.
- `Image.asset` 픽셀아트는 `filterQuality: FilterQuality.none` + `isAntiAlias: false`로 도트 선명하게.
- taste-skill 적용, 다크 유틸리티 톤. `const` 최대.

### 완료 조건 (DoD)
- [ ] `flutter analyze` 0
- [ ] `dart run build_runner build --delete-conflicting-outputs` 성공(있으면), 생성물 커밋
- [ ] `flutter test` **전체 스위트** 통과. 위젯 테스트 최소:
  - monster_page 렌더: 이름·LV·EXP·스탯 그리드 표시
  - 스탯 그리드: 부위 라벨 N개 렌더
  - 스프라이트 이미지 위젯 존재(Image.asset)
- [ ] 실제 도메인/Repository/persistence 추가 안 함(mock만). domain 레이어 불변.

### 하지 말 것
- 실제 Character/CharacterStat 엔티티·Repository·EXP 계산·DB (P6).
- Supabase/네트워크. 새 도메인 로직.
- 스프라이트 재생성(기존 v0 5종 사용).

### 검증 (worker_done 전 필수 — AGENTS.md)
`flutter analyze`(0)와 `flutter test`(전체 통과)를 직접 실행하고 worker_done body에 결과 수치 명시. 커밋 금지.
