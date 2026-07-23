## TASK-FLAGSHIP-02-consistency: 나머지 화면 플래그십 일관성 패스

> 세트로그·홈은 이미 플래그십으로 재설계됨. 나머지 화면(파티/설정/몬스터/통계)을 같은 시스템으로 정렬해 1000만+ 앱 수준의 일관성·완성도를 만든다. 기능/데이터 변경 없이 **프레젠테이션 폴리시만**.

### 디자인 시스템 (반드시 준수)
- `core/theme/app_theme.dart` 토큰만: `AppColors`(쿨차콜+크리스프레드+그린), `AppSpacing`, `AppRadius`, `kTabularFigures`. **하드코딩 색/폰트/간격 전부 제거** → 토큰으로.
- `core/formatting/app_format.dart`: 숫자는 `formatInt`/`formatWeight`/`formatVolumeKg`/`formatCompactNumber` 사용(천단위 콤마·단위).
- `core/widgets/app_states.dart`: 로딩은 `AppLoading`, 데이터 없음은 `AppEmptyState`. **blank(SizedBox.shrink) 로딩 금지.**
- 강한 타이포 위계(대형 tabular 숫자), 넉넉한 여백(8pt), 클러터 제로, 그라데이션/글래스/네온 금지, 큰 탭 타겟.
- 구현 전 `hallmark`/`design-taste-frontend` 스킬 원칙 참고.

### 대상 화면 (features/*/presentation)
1. **stats** — 부위별 분할 %·주간볼륨 등 숫자에 `app_format` 적용, 섹션 헤더/여백 정리, 큰 지표 tabular.
2. **party** (party_page + 3패널) — 카드/리스트 여백·타이포 정리, 하드코딩 색 제거, mock 로딩/빈상태는 AppLoading/AppEmptyState. mock 동작 유지.
3. **settings** — 섹션/행/토글 여백·타이포 정리, 하드코딩 색 제거, 토큰화.
4. **character(monster)** — 스탯 그리드/스프라이트 배치 여백·타이포 정리, 토큰화. mock 유지.

### 규칙
- **기능/데이터/도메인/provider 변경 금지.** 순수 시각 폴리시(위젯 스타일·여백·색토큰·숫자포맷·빈상태)만.
- 하드코딩 `Color(0x..)`/`Colors.xxx`/매직 간격 숫자 → 토큰으로 교체.
- 기존 위젯 테스트가 문자열/구조 바뀌어 깨지면 새 표현에 맞게 갱신(테스트 약화 금지 — 의미 유지).

### 완료 조건 (DoD)
- [ ] `flutter analyze` 0
- [ ] `dart run build_runner build --delete-conflicting-outputs` 성공(있으면), 생성물 커밋
- [ ] `flutter test` **전체 스위트** 통과
- [ ] 대상 화면들에서 하드코딩 색/blank 로딩 제거됨(grep으로 확인 가능)
- [ ] presentation은 provider 경유. domain 불변.

### 하지 말 것
- 기능 추가/변경, 새 도메인/DB/provider, 앱 아이콘(별도), 글로벌 피드.
- 레이아웃 대수술(구조는 유지, 톤·여백·타이포·색토큰·숫자·빈상태만 정렬).

### 검증 (worker_done 전 필수 — AGENTS.md)
`flutter analyze`(0)와 `flutter test`(전체 통과)를 직접 실행하고 worker_done body에 결과 수치 명시. 커밋 금지.
