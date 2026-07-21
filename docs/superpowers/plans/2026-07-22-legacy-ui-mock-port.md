# Legacy UI Mock Port Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Port every legacy user-facing screen into a runnable Flutter Android mock without reintroducing the legacy backend.

**Architecture:** `go_router` owns login, registration, tab-shell, and party-room navigation. Presentation widgets own their short-lived mock state; no data, domain, remote, or repository layer is introduced. A central Flutter theme recreates the legacy charcoal-and-red visual language.

**Tech Stack:** Flutter 3.44.6, Dart 3.12.2, flutter_riverpod 2.x, go_router, Flutter localization, flutter_test.

## Global Constraints

- Keep P4~P6 work presentation-only under the UI mock exception in `docs/PROJECT_CONTEXT.md`.
- Add no Drift, Supabase, HTTP, persistence, external image, or font dependency.
- Use Korean ARB strings, Material icons, 44dp touch targets, dark mode, and Korean public documentation comments.
- Use `go_router` for navigation and do not let widgets call repositories.
- Run a failing widget test before production widget code, then run `flutter analyze`, `flutter test`, and `flutter build apk --debug`.

---

### Task 1: Establish the UI policy and app-entry expectation

**Files:**
- Modify: `docs/PROJECT_CONTEXT.md`
- Create: `docs/superpowers/specs/2026-07-22-legacy-ui-mock-port-design.md`
- Modify: `test/app_test.dart`

**Produces:** A documented presentation-only exception and a test requiring the mock app's first screen.

- [ ] **Step 1: Add the P4~P6 presentation-only exception to the project context.**
- [ ] **Step 2: Document legacy screen mapping, state limits, and verification in the design file.**
- [ ] **Step 3: Extend `test/app_test.dart` to expect the Korean login title and a `MaterialApp.router`.**

```dart
expect(find.text('로그인'), findsOneWidget);
expect(find.byType(MaterialApp), findsOneWidget);
```

- [ ] **Step 4: Run `flutter test test/app_test.dart`; expect failure because the current root is blank.**

### Task 2: Add theme, localization, and router shell

**Files:**
- Create: `lib/core/theme/app_theme.dart`
- Create: `lib/core/router/app_router.dart`
- Create: `lib/features/app_shell/presentation/app_shell.dart`
- Modify: `lib/l10n/app_ko.arb`
- Modify: `lib/main.dart`

**Produces:** Dark red `ThemeData`, localized `MaterialApp.router`, a typed route table, and a five-tab shell.

- [ ] **Step 1: Implement the colors as named theme tokens and use `Theme.of(context)` from pages.**
- [ ] **Step 2: Register login, registration, home, workout, stats, party, party-room, and profile routes with `GoRouter`.**
- [ ] **Step 3: Implement a `NavigationBar` shell with Home, record, stats, party, and profile destinations.**
- [ ] **Step 4: Generate localization with `flutter gen-l10n` and rerun `flutter test test/app_test.dart`; expect pass.**

### Task 3: Port authentication and home presentation

**Files:**
- Create: `lib/features/auth/presentation/login_page.dart`
- Create: `lib/features/auth/presentation/register_page.dart`
- Create: `lib/features/home/presentation/home_page.dart`
- Modify: `test/app_test.dart`

**Produces:** Legacy-style login and registration cards, plus a today dashboard after mock login.

- [ ] **Step 1: Add a widget test that enters non-empty credentials, taps login, and expects the today heading.**
- [ ] **Step 2: Run the test and confirm it fails because the login route has no mock submit flow.**
- [ ] **Step 3: Implement required fields and route to `/home`; route registration back to login after submission.**
- [ ] **Step 4: Rerun the focused test and expect pass.**

### Task 4: Port the workout start, active, and result states

**Files:**
- Create: `lib/features/workout_log/presentation/workout_page.dart`
- Modify: `test/app_test.dart`

**Produces:** A server-free three-state workout flow with immediate set completion feedback.

- [ ] **Step 1: Add a test that opens the record tab, taps the start action, adds a sample set, and finds the completion summary after ending.**
- [ ] **Step 2: Run it and confirm it fails because the record page is missing.**
- [ ] **Step 3: Implement only local state: start, completed-set list, elapsed display, end summary, and restart. Dispose the timer used for elapsed display.**
- [ ] **Step 4: Rerun the focused test and expect pass.**

### Task 5: Port party list and party-room presentation

**Files:**
- Create: `lib/features/party/presentation/party_list_page.dart`
- Create: `lib/features/party/presentation/party_room_page.dart`
- Modify: `test/app_test.dart`

**Produces:** Legacy-style party cards, create/join forms, an activity feed, reactions, and quick actions using fixed mock content.

- [ ] **Step 1: Add a test that opens the party tab, enters the first party room, and taps a reaction.**
- [ ] **Step 2: Run it and confirm it fails because the party routes are absent.**
- [ ] **Step 3: Implement example party cards, local form visibility, typed room route, feed cards, and reaction count state.**
- [ ] **Step 4: Rerun the focused test and expect pass.**

### Task 6: Port profile/character and statistics placeholder

**Files:**
- Create: `lib/features/character/presentation/profile_page.dart`
- Create: `lib/features/stats/presentation/stats_page.dart`
- Modify: `test/app_test.dart`

**Produces:** Character body-stat cards, editable workout tags with local save feedback, and an explicit P2 statistics preview state.

- [ ] **Step 1: Add a test that opens profile, selects a workout tag, and verifies the save confirmation.**
- [ ] **Step 2: Run it and confirm it fails because the profile tab has no content.**
- [ ] **Step 3: Implement local tag selection, character progress rows, save snackbar, and a no-data statistics card.**
- [ ] **Step 4: Rerun the focused test and expect pass.**

### Task 7: Validate the mobile mock and commit

**Files:** All files above.

- [ ] **Step 1: Run `flutter analyze`; expect `No issues found!`.**
- [ ] **Step 2: Run `flutter test`; expect all widget tests to pass.**
- [ ] **Step 3: Run `flutter build apk --debug`; expect `build/app/outputs/flutter-apk/app-debug.apk`.**
- [ ] **Step 4: Commit the UI mock port with `feat(P0): port legacy UI mock to Flutter`.**

## Self-review

- Every legacy page has a Flutter destination or an equivalent screen state: authentication, workout, parties, party room, character, and settings.
- Party, feed, and character are visual-only and have no data-layer implementation.
- The plan explicitly preserves the five P0 tabs and marks statistics as a P2-only visual preview.
- No step needs an unspecified service, interface, dependency, or data model.
