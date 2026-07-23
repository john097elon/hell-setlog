## TASK-THEME-SYSTEM: 멀티 테마 전환 시스템 배선

> 목표 = 사용자가 여러 디자인 테마(우선 Apple 화이트 / Nike 블랙)를 설정에서 골라 전환. 색뿐 아니라 밝기·그림자·타이포·모서리까지 다른 디자인. 향후 6개까지 확장 대비.

### 이미 만들어진 것 (사용하라)
- `lib/core/theme/app_tokens.dart` — `AppTokens` ThemeExtension + `context.tokens` getter.
- `lib/core/theme/app_themes.dart` — `AppThemeId`(appleWhite/nikeBlack) enum + `themeFor(id)` ThemeData 빌더. 각 테마가 `AppTokens` extension 포함.

### 할 일
1. **AppColors → context.tokens 스윕**: 화면/위젯 전역에서 정적 `AppColors.X` 사용을 `context.tokens.X`로 교체(테마 전환 반응하게). 매핑: `AppColors.brand→context.tokens.brand`, `text→text`, `mutedText→mutedText`, `faintText→faintText`, `surface→surface`, `mutedSurface→surface`, `border→border`, `borderStrong→borderStrong`, `success→success`, `warning→warning`, `brandLight→brandLight`, `brandDim→brandDim`, `onBrand→onBrand`, `background→bg`, `card→card`. `AppSpacing`/`AppRadius`/`kTabularFigures`는 그대로 static 유지(app_theme.dart).
   - `const` 위젯 안에서 `context.tokens`를 못 쓰면 해당 위젯의 const를 풀거나 build 안에서 값을 읽어 넘긴다.
2. **테마 provider**: `lib/features/settings/application/theme_controller.dart`(또는 core) — 선택된 `AppThemeId` 상태. **SharedPreferences로 영속**(재실행 유지). riverpod.
   - pubspec에 `shared_preferences` 추가.
3. **main.dart 배선**: `MaterialApp.router`의 `theme`를 `themeFor(선택된 id)`로. ProviderScope에서 provider 구독.
4. **설정 화면에 테마 선택 UI**: settings에 "테마" 섹션 — Apple 화이트 / Nike 블랙 선택(라디오/세그먼트/시트). 선택 즉시 앱 전체 전환.
5. `app_theme.dart`의 기존 `buildAppTheme()`는 남겨두되, main은 `themeFor` 사용. (기존 위젯테스트가 `buildAppTheme()` 쓰면 유지.)

### 완료 조건 (DoD)
- [ ] `flutter analyze` **0** (기존 app_themes const 린트 포함 전부 해결)
- [ ] `dart run build_runner build --delete-conflicting-outputs` 성공, 생성물 커밋
- [ ] `flutter test` **전체 스위트** 통과(테마 전환/영속 관련 최소 테스트 포함: 컨트롤러가 선택 저장·복원, 설정에서 테마 바꾸면 provider 상태 변경)
- [ ] 앱 전체가 선택 테마에 반응(정적 AppColors 잔존 없음 — `grep -rn "AppColors\." lib/features` 0에 가깝게, 남으면 사유)
- [ ] Apple 화이트=라이트, Nike 블랙=다크로 확실히 다르게 보임

### 하지 말 것
- 새 도메인/DB 로직(테마 상태·영속 제외). 화면 레이아웃 대수술(토큰 스윕 + 테마배선만).
- app_tokens.dart/app_themes.dart의 색값 임의 변경(디자인 확정본).

### 검증 (worker_done 전 필수 — AGENTS.md)
`flutter analyze`(0)와 `flutter test`(전체 통과)를 직접 실행하고 worker_done body에 결과 수치 명시. 커밋 금지.
