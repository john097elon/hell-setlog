# Flutter P0 Scaffold Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the legacy web application with an analyzable Flutter foundation for the HealSetLog mobile app.

**Architecture:** A Flutter root application uses `ProviderScope` but contains no product behavior. The repository declares the approved feature-first, three-layer boundaries as empty tracked directories, so later tasks can add code without reorganizing the project. Project context and agent guidance become repository-owned documents before app source is created.

**Tech Stack:** Flutter 3.44.6, Dart 3.12.2, Riverpod 2.x with code generation, go_router, Flutter localization, flutter_lints.

## Global Constraints

- Implement P0 only; P1 through P6 product behavior is out of scope.
- The app targets Android and iOS. Domain code must remain pure Dart when it is introduced.
- Use Riverpod only for state management and go_router only for navigation.
- Korean is the initial locale. User-facing strings must be localized when UI is introduced.
- Public classes and functions use Korean `///` documentation comments.
- Do not use `print()`, `dynamic`, empty catches, repository calls from widgets, or unrequested abstractions.
- Preserve untracked `.agent-cache/` and `.venv/`; they are not legacy application code.

---

## File structure

| Path | Responsibility |
| --- | --- |
| `docs/PROJECT_CONTEXT.md` | Product, architecture, data, domain-rule, and delivery-stage SSOT. |
| `AGENTS.md` | Codex implementation rules referencing the project context. |
| `CLAUDE.md` | Claude architecture/review rules referencing the project context. |
| `pubspec.yaml` | Flutter SDK constraints and P0 dependencies. |
| `analysis_options.yaml` | Flutter lint baseline plus no-print, explicit-return-type, and const rules. |
| `l10n.yaml` / `lib/l10n/app_ko.arb` | Korean localization-generation configuration. |
| `lib/main.dart` | Minimal `ProviderScope` application root. |
| `test/app_test.dart` | Verifies the foundation app renders without product UI. |
| `lib/**/.gitkeep` | Tracks the approved empty architecture directories only. |

## Task 1: Remove the legacy application and establish project guidance

**Files:**
- Delete: `.codegraph/.gitignore`, `.dockerignore`, `.env.example`, `.github/`, `backend/`, `e2e/`, `frontend/`, `ops/`
- Delete: `Dockerfile`, `README.md`, `compose.staging.yml`, `docker-compose.yml`, `_fix_auth.py`, `_fix_schemas.py`, `_gen_android.py`, `_integration_test.py`, `_smoke.py`, `_validate.py`
- Delete: `docs/contracts/`, `docs/operations/`, `docs/pwa/`, `docs/workout-record-ui.md`, `docs/workout-record-v2-api-contract.md`, `docs/superpowers/plans/2026-07-15-operational-data-deployment.md`, `docs/superpowers/specs/2026-07-15-operational-data-deployment-design.md`
- Create: `docs/PROJECT_CONTEXT.md`, `AGENTS.md`, `CLAUDE.md`
- Modify: `.gitignore`

**Interfaces:**
- Produces: the repository-local product contract used by every later task.
- Consumes: the approved Flutter reboot design at `docs/superpowers/specs/2026-07-21-flutter-reboot-design.md`.

- [ ] **Step 1: Remove only tracked legacy application paths**

Run:

```powershell
git rm -r .codegraph .github backend e2e frontend ops docs/contracts docs/operations docs/pwa
git rm .dockerignore .env.example Dockerfile README.md compose.staging.yml docker-compose.yml _fix_auth.py _fix_schemas.py _gen_android.py _integration_test.py _smoke.py _validate.py docs/workout-record-ui.md docs/workout-record-v2-api-contract.md docs/superpowers/plans/2026-07-15-operational-data-deployment.md docs/superpowers/specs/2026-07-15-operational-data-deployment-design.md .gitignore
```

Expected: `git status --short` lists only legacy deletions plus the existing untracked `.agent-cache/` directory.

- [ ] **Step 2: Create the context and agent guidance documents**

Write `docs/PROJECT_CONTEXT.md` with these non-negotiable sections and values:

```markdown
# 헬셋로그 (HealSetLog)

- Product: a set-level workout logger that uses parties and a growth character to make logging habitual.
- Primary UX constraint: recording a set takes at most three taps and 1.5 seconds.
- Stack: Flutter 3.x/Dart 3.x, Riverpod 2.x code generation, go_router, Drift SQLite local-first, Supabase Postgres/Auth/Storage/Realtime, LWW sync using `updatedAt` and soft deletes, video_compress limited to 30 seconds/720p, fl_chart, flutter_test/mocktail, GitHub Actions.
- Dependency direction: `presentation -> application -> domain <- data`; `domain/` imports no Flutter, Drift, or Supabase package; widgets never call repositories directly; features do not import each other.
- Synchronised tables use client-created UUID v4 `id`, `updatedAt`, `deletedAt`, and `syncStatus(local|pending|synced)`.
- Domain rules: Epley 1RM is `w × (1 + r/30)`; reps above 12 are low confidence; volume excludes warmups; ties are not PRs; EXP is set 5, session 50, PR 200, same-day party 30, seven-day streak 100, daily maximum 500; level EXP is `100 × level^1.5`; stages change at levels 1/10/25/50/100; rules live only in `core/constants/game_rules.dart`.
- Delivery order: P0 setup/theme/router, P1 local exercise database/set logging/timer, P2 routine/stats, P3 auth/sync, P4 party, P5 video, P6 character. Do not write P4-P6 code before P1-P2 complete.
- Code rules: snake_case files, PascalCase classes, Korean public-doc comments, review files over 300 lines and build methods over 80 lines, constants instead of magic numbers, Result<T, Failure> errors, no print/dynamic, localized strings, and Conventional Commit messages.
```

Write `AGENTS.md` to direct Codex to obey `docs/PROJECT_CONTEXT.md`, require a `TASK-Pn-xx` specification before implementation, implement domain before data before presentation, and run `flutter analyze` then `flutter test` before reporting. Write `CLAUDE.md` to direct Claude to write task contracts, review layer boundaries/domain rules/offline behavior/tests, and reject P4-P6 scope expansion.

- [ ] **Step 3: Add the Flutter-oriented ignore rules**

Create `.gitignore` with the Flutter-generated entries and preserve the local tooling exclusions:

```gitignore
.dart_tool/
.packages
.pub/
build/
.flutter-plugins
.flutter-plugins-dependencies
.idea/
.vscode/
android/.gradle/
android/app/debug/
android/app/profile/
android/app/release/
.agent-cache/
.codegraph/
.venv/
```

- [ ] **Step 4: Verify no tracked legacy source remains**

Run:

```powershell
git ls-files | Select-String -Pattern '^(backend|frontend|e2e|ops|\.github|Dockerfile|docker-compose)'
```

Expected: no output.

- [ ] **Step 5: Commit the guidance reset**

```powershell
git add -A
git commit -m "chore: reset repository for Flutter app"
```

Expected: the commit contains no `.agent-cache/` or `.venv/` path.

## Task 2: Generate and configure the Flutter foundation

**Files:**
- Create: `android/`, `ios/`, `lib/`, `test/`, `.metadata`, `devtools_options.yaml`, `README.md`, `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, `l10n.yaml`, `lib/l10n/app_ko.arb`
- Modify: `.gitignore`

**Interfaces:**
- Produces: the `heal_setlog` Flutter package and Korean localization generation.
- Consumes: Flutter 3.44.6 installed at `C:\Users\john\develop\flutter\bin\flutter.bat`.

- [ ] **Step 1: Generate the Android/iOS project**

Run:

```powershell
& 'C:\Users\john\develop\flutter\bin\flutter.bat' create --project-name heal_setlog --org com.john097elon --platforms=android,ios .
```

Expected: `pubspec.yaml`, `android/`, `ios/`, `lib/main.dart`, and `test/widget_test.dart` exist.

- [ ] **Step 2: Configure the P0 package manifest**

Replace the generated dependency sections with:

```yaml
environment:
  sdk: ^3.12.2

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1
  go_router: ^14.8.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  build_runner: ^2.4.15
  riverpod_generator: ^2.6.3
  riverpod_lint: ^2.6.3
  custom_lint: ^0.7.5
```

Set `flutter: generate: true` in the same manifest.

- [ ] **Step 3: Configure analysis and Korean localization**

Create `analysis_options.yaml`:

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    avoid_print: true
    always_declare_return_types: true
    prefer_const_constructors: true
    prefer_const_literals_to_create_immutables: true
```

Create `l10n.yaml` and the initial ARB file:

```yaml
arb-dir: lib/l10n
template-arb-file: app_ko.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
```

```json
{
  "@@locale": "ko",
  "appName": "헬셋로그"
}
```

- [ ] **Step 4: Resolve packages and verify generated localization support**

Run:

```powershell
& 'C:\Users\john\develop\flutter\bin\flutter.bat' pub get
& 'C:\Users\john\develop\flutter\bin\flutter.bat' gen-l10n
```

Expected: both commands exit 0 and no dependency uses Riverpod 3.x.

- [ ] **Step 5: Commit the generated foundation**

```powershell
git add .metadata devtools_options.yaml README.md android ios lib/main.dart test/widget_test.dart pubspec.yaml pubspec.lock analysis_options.yaml l10n.yaml lib/l10n .gitignore
git commit -m "chore: create Flutter P0 foundation"
```

## Task 3: Add the minimal application root and architecture directories

**Files:**
- Modify: `lib/main.dart`
- Delete: `test/widget_test.dart`
- Create: `test/app_test.dart`
- Create: `lib/core/{constants,di,error,extensions,router,theme}/.gitkeep`
- Create: `lib/data/{local,remote,repositories}/.gitkeep`
- Create: `lib/domain/{entities,repositories,usecases}/.gitkeep`
- Create: `lib/features/{workout_log,routine,stats,timer,exercise_db,party,feed}/.gitkeep`
- Create: `lib/features/character/{application,presentation}/.gitkeep`

**Interfaces:**
- Produces: `HealSetLogApp`, a public root widget that later P0-02 code replaces internally without changing `main()`.
- Consumes: `flutter_riverpod` only; it deliberately consumes no repository, router, theme, database, or remote dependency.

- [ ] **Step 1: Write the failing app-root test**

Create `test/app_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/main.dart';

void main() {
  testWidgets('앱 루트가 렌더링된다', (WidgetTester tester) async {
    await tester.pumpWidget(const HealSetLogApp());

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```powershell
& 'C:\Users\john\develop\flutter\bin\flutter.bat' test test/app_test.dart
```

Expected: FAIL because `HealSetLogApp` is not defined.

- [ ] **Step 3: Implement the minimal provider-scoped root**

Replace `lib/main.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 헬셋로그 애플리케이션을 시작한다.
void main() {
  runApp(const ProviderScope(child: HealSetLogApp()));
}

/// P0 기반 애플리케이션 루트다.
class HealSetLogApp extends StatelessWidget {
  /// 애플리케이션 루트를 생성한다.
  const HealSetLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Scaffold(body: SizedBox.shrink()));
  }
}
```

Create the listed `.gitkeep` files with no content. Do not add route, theme, entity, controller, repository, Drift, Supabase, or feature code.

- [ ] **Step 4: Run the required verification**

Run:

```powershell
& 'C:\Users\john\develop\flutter\bin\flutter.bat' analyze
& 'C:\Users\john\develop\flutter\bin\flutter.bat' test
```

Expected: `No issues found!` and all tests pass.

- [ ] **Step 5: Commit the P0-01 scaffold**

```powershell
git add lib/main.dart lib/core lib/data lib/domain lib/features test/app_test.dart
git rm test/widget_test.dart
git commit -m "feat(P0): scaffold HealSetLog Flutter app"
```

## Self-review

- Spec coverage: Task 1 establishes the SSOT and removes the obsolete implementation. Task 2 creates the exact mobile Flutter package and required foundational configuration. Task 3 establishes the architecture folders, Riverpod root, and verified minimal application.
- Scope: no P1+ product behavior, persistence, networking, or UI routes are included.
- Type consistency: the only public API introduced is `HealSetLogApp`, defined in Task 3 and imported by its test.
- Placeholder scan: no task relies on undefined functions, unspecified paths, or deferred implementation details.
