# Flutter Reboot Design

## Decision

Replace the existing React/FastAPI application with a new Flutter application at the repository root. The Git history retains the legacy implementation; no `legacy/` copy is kept in the working tree.

The work starts at P0 and follows the sequence in `docs/PROJECT_CONTEXT.md`. P4 through P6 features are explicitly out of scope until P1 and P2 are complete.

## Scope: TASK-P0-01

1. Remove tracked legacy web/backend, Docker, Playwright, and CI assets that implement the previous product.
2. Add `docs/PROJECT_CONTEXT.md`, `AGENTS.md`, and `CLAUDE.md` as the new project guidance source.
3. Create a Flutter project named `heal_setlog` at the repository root for Android and iOS.
4. Add the feature-first, three-layer directory structure without speculative implementations:
   - `lib/core/`
   - `lib/data/{local,remote,repositories}/`
   - `lib/domain/{entities,repositories,usecases}/`
   - `lib/features/{workout_log,routine,stats,timer,exercise_db,party,feed,character}/`
5. Add only P0 foundation dependencies: `flutter_riverpod`, `riverpod_annotation`, `go_router`, and their code-generation/lint development dependencies. Drift and Supabase dependencies wait for their owning stages.
6. Configure static analysis to reject `print`, enforce explicit return types, and prefer `const` construction.
7. Use Flutter localization generation with Korean as the initial supported locale. P0-01 contains no product UI; P0-02 owns the theme and five routed screens.

## Architecture

The bootstrap application uses `ProviderScope` at its root. It contains only a minimal app shell required to compile; it does not introduce repositories, controllers, entities, themes, routes, persistence, or placeholder product behavior before those tasks own them.

Future dependencies follow this direction:

`presentation -> application -> domain <- data`

The domain layer remains pure Dart. UI will access application controllers only, never repository implementations. The directory scaffold itself creates no API that could later become accidental architecture.

## Error Handling and Data

P0-01 persists no data and calls no network services, so it has no runtime data or error flow. `Result<T, Failure>`, Drift, Supabase, and synchronization are deferred to the tasks that introduce their first use. This avoids a dead abstraction in the scaffold.

## Validation

- `flutter pub get` succeeds.
- `flutter analyze` reports zero issues.
- `flutter test` succeeds.
- The generated Android and iOS project directories exist.
- No tracked React, FastAPI, Docker, Playwright, or old CI files remain.

## Non-goals

- No workout logging, routines, statistics, timer, party, feed, video, character, authentication, persistence, or sync behavior.
- No Android SDK repair or emulator setup beyond recording the existing Flutter doctor limitation.
- No migration of legacy data or screens.
