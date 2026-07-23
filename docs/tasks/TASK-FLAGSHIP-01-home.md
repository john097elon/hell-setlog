## TASK-FLAGSHIP-01-home: 홈 대시보드 플래그십 재설계

> 목표 = 다운로드 1000만+ 최상위 피트니스 앱(Hevy/Nike/토스) 수준의 홈. 첫 화면이라 제일 중요. 열자마자 동기부여되고 정제·신뢰감. 게임틱·아마추어 금지.

### 현재 문제
- 홈이 "운동 시작 버튼 + 루틴 링크"뿐. 약하고 밋밋함.

### 디자인 시스템 (반드시 준수)
- `core/theme/app_theme.dart`의 토큰만 사용: `AppColors`(쿨 차콜 + 크리스프 레드 액센트 + 그린), `AppSpacing`, `AppRadius`, `kTabularFigures`. 하드코딩 색/폰트/간격 금지.
- 강한 타이포 위계(대형 tabular 숫자), 넉넉한 여백(8pt 그리드), 클러터 제로(불필요 pill/badge 금지), 그라데이션·글래스·네온 금지, 큰 탭 타겟.
- 구현 전 `hallmark` 또는 `design-taste-frontend` 스킬 원칙 참고(anti-slop).

### 화면 구성 (features/home/presentation/home_page.dart 재작성 + 위젯 분리)
1. **상단 인사/날짜** — "오늘의 운동" 또는 요일/날짜, 차분한 헤더.
2. **이번 주 요약 카드** — 대형 지표 1~2개: 주간 총 볼륨(kg), 운동일 수. `weeklyVolumeProvider`(stats)에서 파생(값 합 = 총볼륨, 볼륨>0 날수 = 운동일). 큰 숫자 + 작은 라벨.
3. **주요 CTA** — "운동 시작"(풀폭 accent FilledButton, 큰 탭타겟). 진행 중 세션 있으면 "운동 이어하기"로.
4. **루틴 바로가기** — 루틴 목록 상위 2~3개(`routinesProvider`) 리스트/카드, 탭 시 그 루틴으로 시작 or /routines.
5. (선택) **캐릭터 미리보기** — 몬스터 스프라이트 작게 + 레벨(mock, `monster_view_data` 재사용 가능). 없으면 생략 가능.

### 데이터
- 기존 provider 재사용: `weeklyVolumeProvider`, `activeSessionProvider`, `routinesProvider`. 새 도메인/DB 로직 금지(없으면 ask).
- `AsyncValue.when(data/loading/error)` 전부 처리. **로딩은 blank(SizedBox.shrink) 금지** — 간단한 스켈레톤 또는 CircularProgressIndicator. 데이터 없을 때 빈상태 안내.

### 완료 조건 (DoD)
- [ ] `flutter analyze` 0
- [ ] `dart run build_runner build --delete-conflicting-outputs` 성공(있으면), 생성물 커밋
- [ ] `flutter test` **전체 스위트** 통과. 위젯 테스트:
  - 홈 렌더: 주간 요약 지표 + "운동 시작" CTA 존재
  - 로딩 상태에서 blank 아닌 인디케이터 노출
  - 루틴 섹션 렌더(mock provider)
- [ ] presentation은 provider 경유(repository 직접호출 금지). domain 불변.

### 하지 말 것
- 새 도메인/DB/repository. 글로벌 피드/스토리(범위 밖). 캐릭터 실EXP(P6, mock만).
- 하드코딩 색/간격. 그라데이션/글래스/네온. 클러터.

### 검증 (worker_done 전 필수 — AGENTS.md)
`flutter analyze`(0)와 `flutter test`(전체 통과)를 직접 실행하고 worker_done body에 결과 수치 명시. 커밋 금지.
