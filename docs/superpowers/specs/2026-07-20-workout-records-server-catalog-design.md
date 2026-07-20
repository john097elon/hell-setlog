# Workout Records V2: Server-Persisted Exercise Catalog

## Status

Approved product direction: server-persisted catalog. The UI refresh follows the
existing visual system and selectively adopts the supplied mobile mockup's
exercise-recording patterns.

## Problem

The current app can search a read-only system exercise list, save structured
sets to an active workout, and show calendar history. It cannot remember a
user-created exercise, favorite an exercise, or surface recently used exercises.
That makes repeat logging slow and prevents custom movements from being a
reliable input to later party and growth/statistics work.

## Goals

- Let a signed-in user select an exercise from **Recent**, **Favorites**, or
  **All exercises** while an active workout exists.
- Let a user create a private custom exercise with a name, body part, and unit
  type, then reuse it on any signed-in device.
- Record structured sets using the existing `WorkoutRecord` and `ExerciseSet`
  path, preserving idempotent retry behavior.
- Present an active-workout progress summary and a completion-ready record
  summary without changing the existing workout lifecycle.
- Work on small mobile screens with keyboard-safe controls, accessible labels,
  loading states, empty states, and recoverable save errors.

## Non-goals

- Party discovery/chat/video UX and growth/statistics dashboards; they are the
  next two design tracks after workout recording.
- Public sharing of custom exercises, exercise editing, exercise deletion, rest
  timers, templates/routines, or importing data from another service.
- Editing or deleting an already saved workout record in this iteration.

## Chosen Approach

Use a server-persisted exercise catalog:

- System exercises remain shared and read-only.
- Custom exercises are private to their creator.
- Favorites are a separate per-user relation, not a flag on an exercise.
- Recent exercises are derived from that user's saved workout records, so no
  stale client-side cache is treated as the source of truth.

This preserves cross-device behavior and gives future statistics a canonical
exercise and body-part identity.

## Data Model

### Exercise

Extend the existing `exercises` table with:

- `owner_user_id`: nullable foreign key to `users`; null means a system
  exercise, and a populated value means a private custom exercise.
- `is_system`: non-null boolean defaulting to true for existing seeded rows.

The existing globally unique `canonical_name` remains intact. The server
generates a namespaced canonical name for a custom exercise, for example
`user-42-dumbbell-floor-press`, so two users may choose the same display name
without colliding. `display_name_kr`, `body_part`, and `unit_kind` continue to
be the canonical metadata used by records and later statistics.

### ExerciseFavorite

Add `exercise_favorites`:

| Column | Rule |
| --- | --- |
| `user_id` | required foreign key to `users` |
| `exercise_id` | required foreign key to `exercises` |
| `created_at` | required creation timestamp |

`(user_id, exercise_id)` is unique. A favorite can refer to a system exercise
or to the user's own custom exercise. A user cannot read or favorite another
user's custom exercise.

### Existing records

`WorkoutRecord` continues to point to `exercise_id`; `ExerciseSet` remains the
only source for repetitions/weight, duration, or distance. No record migration
or backfill is required.

## API Contract

All routes require the existing authenticated user. Existing record endpoints
remain compatible.

| Route | Behavior |
| --- | --- |
| `GET /exercises` | Add optional `query`, `body_part`, and `scope=all|system|mine`; returns system exercises plus only the caller's custom exercises. |
| `POST /exercises/custom` | Create a private exercise from `display_name_kr`, `body_part`, and `unit_kind`; the server validates length, allowed body part/unit kind, and generates `canonical_name`. |
| `GET /exercises/recent` | Return up to a bounded limit of unique exercises ordered by the caller's latest `WorkoutRecord.performed_at`. |
| `GET /exercises/favorites` | Return the caller's favorites ordered by favorite creation time. |
| `PUT /exercises/{exercise_id}/favorite` | Add the exercise to the caller's favorites; repeat calls are idempotent. |
| `DELETE /exercises/{exercise_id}/favorite` | Remove the caller's favorite; repeating removal is successful and idempotent. |

`ExerciseOut` gains ownership metadata only when needed by the client, such as
`is_custom` and `is_favorite`; it never exposes another user's identifier. The
`POST /workout-records` contract, including `X-Idempotency-Key`, is unchanged.

## Mobile UX

### Exercise picker

The input view has three selector modes: **Recent**, **Favorites**, and
**All**. All mode includes search and body-part filtering. The selected mode
has an explicit empty state:

- Recent: explain that saved exercises will appear after the first record.
- Favorites: offer a link to All exercises.
- Search with no results: offer **Create custom exercise**.

Creating a custom exercise uses a small modal/bottom sheet with name, body
part, and unit type. The successful result becomes selected immediately. It is
not auto-favorited; favoriting remains an explicit, reversible action.

### Set editor

After selection, the editor uses the exercise unit type:

- `reps_weight`: repetitions and kilograms.
- `time`: seconds.
- `distance`: meters.

At least one set is visible. Adding a set copies the immediately preceding
set's values; each row can be removed only when another row remains. A sticky
save action records one exercise at a time. After a successful save, the page
shows a concise success message, refreshes Recent, and adds the record to the
session progress summary.

### Session and completion summary

The page queries existing records for the active `workout_id` to show completed
exercise count, set count, and involved body parts. When the existing workout
is ended, the summary combines these records with the current workout result;
the page does not create a second lifecycle or duplicate growth event.

### Failure and accessibility behavior

- Keep every entered value on network failure and retry with the same
  idempotency key.
- Disable duplicate submission only while a request is in flight.
- Use `aria-live` status for saves and an alert for recoverable errors.
- Give every numeric input an accessible set-and-field label and appropriate
  mobile `inputMode`.
- Keep controls at least 44 CSS px high, preserve the bottom safe area, and
  keep the sticky action above the mobile navigation and virtual keyboard.

## Authorization and Validation

- System exercises may be read by any authenticated user and cannot be edited
  through these routes.
- Custom exercises are visible only to their owner.
- Favorite and custom-create endpoints reject unauthenticated requests and
  inaccessible exercise ids with the existing API error conventions.
- Custom names are trimmed, length bounded, and deduplicated for the same user
  by normalized display name and metadata before a new row is created.
- Record creation retains its active-workout ownership check and validates set
  values according to `unit_kind`.

## Testing and Verification

Backend tests cover custom exercise visibility, cross-user isolation,
duplicate-custom handling, favorite idempotency, recent ordering, and record
compatibility with system and custom exercises. Migration tests cover existing
system rows and new constraints.

Frontend tests cover selector empty states, custom creation, selection,
favorite toggling, unit-specific set validation, retry preservation, and
session-summary refresh. Browser/E2E verification covers 360x800, 375x812,
430x932, and 844x390 viewports for no horizontal overflow, tappable sticky
actions, and keyboard-safe numeric fields.

## Acceptance Criteria

- A user can create a private movement, find it after signing in again, and
  save structured sets for it in an active workout.
- A user can favorite/unfavorite an allowed exercise and see the change on a
  second device/session.
- Recent exercises are based on successfully saved records, not unsaved drafts.
- A failed record save neither loses input nor creates more than one record on
  retry.
- Existing system exercise records, workout session routes, growth events, and
  calendar history continue to work.