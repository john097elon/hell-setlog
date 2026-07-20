# Workout Records V2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a private, server-persisted custom exercise catalog with favorites and record-derived recents, then integrate it into the mobile structured workout-record flow.

**Architecture:** Extend the existing `Exercise` record only with ownership/system metadata and add a separate favorite relation. Keep `WorkoutRecord` and `ExerciseSet` immutable and unchanged as the record-of-truth. The backend exposes catalog views and idempotent favorite operations; focused React components compose the picker, custom-exercise sheet, and set editor into the existing `/workout` record hub.

**Tech Stack:** FastAPI, SQLAlchemy, Alembic, SQLite/PostgreSQL-compatible migrations, Pydantic, React, TypeScript, Vitest, Testing Library, Playwright.

## Global Constraints

- Existing system exercises are shared, read-only, and keep their globally unique `canonical_name`.
- Custom exercises are private to the authenticated creator; do not expose another user's custom exercise through list, recent, or favorite routes.
- Recent exercises are derived only from saved `WorkoutRecord.performed_at` values.
- `POST /workout-records` and its `X-Idempotency-Key` retry behavior remain backward-compatible.
- Valid body parts are `chest`, `back`, `legs`, `shoulders`, `arms`, `core`, and `stamina`.
- Valid unit kinds are `reps_weight`, `time`, and `distance`.
- Controls are at least 44 CSS px, support 360x800 through 844x390 viewports, and retain entered values after a save failure.
- Do not build party/chat/video, growth/statistics dashboards, templates, rest timers, editing/deleting saved records, or public custom exercises in this plan.

---

## File Structure

- Modify: `backend/models.py` — ownership metadata on `Exercise` and `ExerciseFavorite` persistence model.
- Create: `backend/migrations/versions/20260720_0004_exercise_catalog_personalization.py` — additive schema migration and existing-system-row backfill.
- Modify: `backend/schemas.py` — catalog/filter/create/favorite response models.
- Modify: `backend/routers/workout_records.py` — authenticated catalog, recent, custom-create, and favorite routes while retaining record routes.
- Modify: `backend/tests/api/test_workout_records_api.py` — preserve existing record compatibility coverage.
- Create: `backend/tests/api/test_exercise_catalog_api.py` — catalog ownership, recency, favorite, and validation contract tests.
- Create: `frontend/src/components/workout/ExercisePicker.tsx` — Recent/Favorites/All selector and searchable list.
- Create: `frontend/src/components/workout/CustomExerciseSheet.tsx` — accessible custom-exercise creation dialog.
- Create: `frontend/src/components/workout/WorkoutSetEditor.tsx` — unit-aware set rows with add, duplicate, and remove behavior.
- Create: `frontend/src/components/workout/workout-records.css` — component-scoped selector, sheet, editor, and progress styles.
- Modify: `frontend/src/pages/WorkoutRecordsPage.tsx` — compose catalog components, preserve idempotent saving, and show session progress.
- Modify: `frontend/src/pages/WorkoutRecordsPage.css` — retain history styling and make the page compose the new component styles.
- Modify: `frontend/src/tests/pages/WorkoutRecordsPage.test.tsx` — page-level save/retry/progress coverage.
- Create: `frontend/src/tests/components/workout/ExercisePicker.test.tsx` — selector/favorite/custom-empty-state coverage.
- Create: `frontend/src/tests/components/workout/WorkoutSetEditor.test.tsx` — unit, copy, delete, and validation coverage.
- Modify: `e2e/tests/mobile-matrix.spec.ts` — mobile width, sticky-action, and keyboard-safe regression coverage.
- Modify: `docs/workout-record-v2-api-contract.md` — document the additive catalog endpoints and authorization behavior.

---

### Task 1: Persist personalized exercise-catalog data

**Files:**
- Create: `backend/migrations/versions/20260720_0004_exercise_catalog_personalization.py`
- Modify: `backend/models.py`
- Test: `backend/tests/test_migrations.py`

**Interfaces:**
- Consumes: existing `Exercise(id, canonical_name, display_name_kr, unit_kind, body_part)` rows.
- Produces: `Exercise.owner_user_id: int | None`, `Exercise.is_system: bool`, and `ExerciseFavorite(user_id, exercise_id, created_at)`.

- [ ] **Step 1: Write the failing migration/model assertions**

```python
def test_exercise_catalog_personalization_schema(db):
    from models import Exercise, ExerciseFavorite

    exercise = Exercise(
        canonical_name="user-1-floor-press",
        display_name_kr="덤벨 플로어 프레스",
        unit_kind="reps_weight",
        body_part="chest",
        owner_user_id=1,
        is_system=False,
    )
    favorite = ExerciseFavorite(user_id=1, exercise=exercise)
    db.add_all([exercise, favorite])
    db.commit()
    assert exercise.owner_user_id == 1
    assert exercise.is_system is False
    assert favorite.exercise_id == exercise.id
```

- [ ] **Step 2: Run the focused test and verify it fails**

Run: `cd backend; pytest tests/test_migrations.py -k personalization -v`

Expected: FAIL because `owner_user_id`, `is_system`, or `ExerciseFavorite` does not exist.

- [ ] **Step 3: Add the migration and SQLAlchemy models**

```python
# backend/models.py
class Exercise(Base):
    # retain existing fields
    owner_user_id = Column(Integer, ForeignKey("users.id", name="fk_exercises_owner"), nullable=True, index=True)
    is_system = Column(Boolean, nullable=False, default=True)
    owner = relationship("User", foreign_keys=[owner_user_id])
    favorites = relationship("ExerciseFavorite", back_populates="exercise", cascade="all, delete-orphan")

class ExerciseFavorite(Base):
    __tablename__ = "exercise_favorites"
    __table_args__ = (UniqueConstraint("user_id", "exercise_id", name="uq_exercise_favorite_user_exercise"),)
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id", name="fk_exercise_favorites_user"), nullable=False, index=True)
    exercise_id = Column(Integer, ForeignKey("exercises.id", name="fk_exercise_favorites_exercise"), nullable=False, index=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    exercise = relationship("Exercise", back_populates="favorites")
```

```python
# migration upgrade excerpt
with op.batch_alter_table("exercises") as batch:
    batch.add_column(sa.Column("owner_user_id", sa.Integer(), nullable=True))
    batch.add_column(sa.Column("is_system", sa.Boolean(), nullable=False, server_default=sa.true()))
    batch.create_foreign_key("fk_exercises_owner", "users", ["owner_user_id"], ["id"])
op.create_index("ix_exercises_owner_user_id", "exercises", ["owner_user_id"], unique=False)
op.create_table(
    "exercise_favorites",
    sa.Column("id", sa.Integer(), primary_key=True),
    sa.Column("user_id", sa.Integer(), nullable=False),
    sa.Column("exercise_id", sa.Integer(), nullable=False),
    sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    sa.ForeignKeyConstraint(["user_id"], ["users.id"], name="fk_exercise_favorites_user"),
    sa.ForeignKeyConstraint(["exercise_id"], ["exercises.id"], name="fk_exercise_favorites_exercise"),
    sa.UniqueConstraint("user_id", "exercise_id", name="uq_exercise_favorite_user_exercise"),
)
op.execute("UPDATE exercises SET is_system = 1 WHERE is_system IS NULL")
```

- [ ] **Step 4: Run migration and model tests**

Run: `cd backend; pytest tests/test_migrations.py -v`

Expected: PASS, including upgrade/downgrade coverage for revision `20260720_0004`.

- [ ] **Step 5: Commit the persistence layer**

```bash
git add backend/models.py backend/migrations/versions/20260720_0004_exercise_catalog_personalization.py backend/tests/test_migrations.py
git commit -m "feat: persist personalized exercise catalog data"
```

### Task 2: Define and test the personalized catalog API

**Files:**
- Modify: `backend/schemas.py`
- Modify: `backend/routers/workout_records.py`
- Modify: `backend/main.py`
- Create: `backend/tests/api/test_exercise_catalog_api.py`
- Modify: `backend/tests/api/test_workout_records_api.py`

**Interfaces:**
- Consumes: `Exercise.owner_user_id`, `Exercise.is_system`, `ExerciseFavorite`, authenticated `User`, and existing `WorkoutRecord`.
- Produces: `GET /exercises`, `POST /exercises/custom`, `GET /exercises/recent`, `GET /exercises/favorites`, `PUT /exercises/{id}/favorite`, and `DELETE /exercises/{id}/favorite`.

- [ ] **Step 1: Write failing API contract tests**

```python
def test_custom_exercise_favorite_and_recent_are_private(client):
    _, owner_token = make_user(client, "catalog-owner", suffix="catalog")
    _, other_token = make_user(client, "catalog-other", suffix="catalog")
    created = client.post("/api/exercises/custom", json={
        "display_name_kr": "덤벨 플로어 프레스",
        "body_part": "chest",
        "unit_kind": "reps_weight",
    }, headers=auth(owner_token))
    assert created.status_code == 201
    exercise_id = created.json()["id"]
    assert client.put(f"/api/exercises/{exercise_id}/favorite", headers=auth(owner_token)).status_code == 204
    assert client.get("/api/exercises/favorites", headers=auth(owner_token)).json()[0]["id"] == exercise_id
    assert all(item["id"] != exercise_id for item in client.get("/api/exercises", headers=auth(other_token)).json())
```

```python
def test_recent_uses_saved_records_not_unsaved_drafts(client):
    _, token = make_user(client, "recent-user", suffix="catalog")
    exercise = client.get("/api/exercises", headers=auth(token)).json()[0]
    assert client.get("/api/exercises/recent", headers=auth(token)).json() == []
    workout_id = _start_workout(client, token)
    client.post("/api/workout-records", json={
        "workout_id": workout_id, "exercise_id": exercise["id"],
        "sets": [{"set_index": 0, "reps": 10, "weight_kg": 20}],
    }, headers=auth(token))
    assert client.get("/api/exercises/recent", headers=auth(token)).json()[0]["id"] == exercise["id"]
```

- [ ] **Step 2: Run the focused backend tests and verify they fail**

Run: `cd backend; pytest tests/api/test_exercise_catalog_api.py -v`

Expected: FAIL with 404 routes or missing custom/favorite response fields.

- [ ] **Step 3: Add Pydantic models and route helpers**

```python
class ExerciseCreate(BaseModel):
    display_name_kr: str = Field(min_length=1, max_length=100)
    body_part: str = Field(pattern="^(chest|back|legs|shoulders|arms|core|stamina)$")
    unit_kind: str = Field(pattern="^(reps_weight|time|distance)$")

class ExerciseCatalogOut(ExerciseOut):
    is_custom: bool
    is_favorite: bool = False
```

```python
@router.post("/exercises/custom", response_model=ExerciseCatalogOut, status_code=status.HTTP_201_CREATED)
def create_custom_exercise(body: ExerciseCreate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    name = " ".join(body.display_name_kr.split())
    existing = db.query(Exercise).filter(
        Exercise.owner_user_id == current_user.id,
        Exercise.display_name_kr == name,
        Exercise.body_part == body.body_part,
        Exercise.unit_kind == body.unit_kind,
    ).first()
    if existing:
        return _catalog_out(existing, current_user.id, False)
    exercise = Exercise(
        canonical_name=f"user-{current_user.id}-{uuid4().hex}",
        display_name_kr=name, body_part=body.body_part, unit_kind=body.unit_kind,
        owner_user_id=current_user.id, is_system=False,
    )
    db.add(exercise); db.commit(); db.refresh(exercise)
    return _catalog_out(exercise, current_user.id, False)
```

Implement `_visible_exercises`, `_catalog_out`, recent grouping by latest
`WorkoutRecord.performed_at`, and idempotent favorite insert/delete. Filter all
catalog queries with `Exercise.is_system == True OR Exercise.owner_user_id == current_user.id`.

Update the CORS declaration in `backend/main.py` so `allow_methods` includes `"PUT"`; favorite actions must work from the mobile browser, not only from API tests.

- [ ] **Step 4: Run catalog and existing record API tests**

Run: `cd backend; pytest tests/api/test_exercise_catalog_api.py tests/api/test_workout_records_api.py -v`

Expected: PASS; existing catalog/record tests continue to receive system exercises and immutable records.

- [ ] **Step 5: Commit the API contract**

```bash
git add backend/schemas.py backend/routers/workout_records.py backend/main.py backend/tests/api/test_exercise_catalog_api.py backend/tests/api/test_workout_records_api.py
git commit -m "feat: add personalized exercise catalog API"
```

### Task 3: Build the exercise picker and custom-exercise sheet

**Files:**
- Create: `frontend/src/components/workout/ExercisePicker.tsx`
- Create: `frontend/src/components/workout/CustomExerciseSheet.tsx`
- Create: `frontend/src/components/workout/workout-records.css`
- Create: `frontend/src/tests/components/workout/ExercisePicker.test.tsx`

**Interfaces:**
- Consumes: `ExerciseCatalogItem { id, display_name_kr, canonical_name, body_part, unit_kind, is_custom, is_favorite }` and callbacks supplied by `WorkoutRecordsPage`.
- Produces: `ExercisePicker` with `onSelect(exercise)`, `onToggleFavorite(exercise)`, and `onCreateCustom()`; `CustomExerciseSheet` with `onCreated(exercise)`.

- [ ] **Step 1: Write failing component tests**

```tsx
it('switches to favorites and exposes the all-exercises escape hatch when empty', async () => {
  const user = userEvent.setup();
  render(<ExercisePicker recent={[]} favorites={[]} all={[exercise]} selectedId={undefined} onSelect={vi.fn()} onToggleFavorite={vi.fn()} onCreateCustom={vi.fn()} />);
  await user.click(screen.getByRole('tab', { name: 'Favorites' }));
  expect(screen.getByText('즐겨찾는 운동이 없습니다.')).toBeVisible();
  await user.click(screen.getByRole('button', { name: '전체 운동 보기' }));
  expect(screen.getByRole('option', { name: /스쿼트/ })).toBeVisible();
});
```

```tsx
it('creates and selects a custom exercise after a no-result search', async () => {
  const user = userEvent.setup();
  const onCreated = vi.fn();
  render(<CustomExerciseSheet open onClose={vi.fn()} onCreated={onCreated} />);
  await user.type(screen.getByLabelText('운동 이름'), '덤벨 플로어 프레스');
  await user.selectOptions(screen.getByLabelText('운동 부위'), 'chest');
  await user.click(screen.getByRole('button', { name: '내 운동 만들기' }));
  await waitFor(() => expect(onCreated).toHaveBeenCalledWith(expect.objectContaining({ display_name_kr: '덤벨 플로어 프레스' })));
});
```

- [ ] **Step 2: Run component tests and verify they fail**

Run: `npm --prefix frontend test -- ExercisePicker.test.tsx --run`

Expected: FAIL because the picker and sheet components do not exist.

- [ ] **Step 3: Implement picker/sheet with explicit API boundaries**

```tsx
export type ExerciseCatalogItem = {
  id: number; canonical_name: string; display_name_kr: string;
  body_part: string; unit_kind: 'reps_weight' | 'time' | 'distance';
  is_custom: boolean; is_favorite: boolean;
};

export function ExercisePicker({ recent, favorites, all, selectedId, onSelect, onToggleFavorite, onCreateCustom }: ExercisePickerProps) {
  const [view, setView] = useState<'recent' | 'favorites' | 'all'>('recent');
  const [query, setQuery] = useState('');
  const visible = view === 'recent' ? recent : view === 'favorites' ? favorites : all.filter(matchesQuery(query));
  // Render tablist, search only in All, favorite toggle buttons, and exact empty states.
}
```

```tsx
export function CustomExerciseSheet({ open, onClose, onCreated }: CustomExerciseSheetProps) {
  const submit = async (event: FormEvent) => {
    event.preventDefault();
    const { data } = await api.post('/exercises/custom', { display_name_kr: name, body_part: bodyPart, unit_kind: unitKind });
    onCreated(data); onClose();
  };
  // Use role="dialog", aria-modal="true", labelled form controls, and preserve fields on request failure.
}
```

Add CSS for 44px tab/list/button controls, an `aria-selected` active state,
scroll containment, a keyboard-safe dialog, and the 360px single-column layout.

- [ ] **Step 4: Run picker tests and TypeScript build**

Run: `npm --prefix frontend test -- ExercisePicker.test.tsx --run; npm --prefix frontend run build`

Expected: PASS with no TypeScript errors.

- [ ] **Step 5: Commit picker UI**

```bash
git add frontend/src/components/workout frontend/src/tests/components/workout/ExercisePicker.test.tsx
git commit -m "feat: add exercise picker and custom exercise sheet"
```

### Task 4: Make the set editor unit-aware and resilient

**Files:**
- Create: `frontend/src/components/workout/WorkoutSetEditor.tsx`
- Create: `frontend/src/tests/components/workout/WorkoutSetEditor.test.tsx`
- Modify: `frontend/src/components/workout/workout-records.css`

**Interfaces:**
- Consumes: selected `ExerciseCatalogItem` and `DraftSet[]`.
- Produces: `WorkoutSetEditor` with `value`, `onChange(nextSets)`, and `valid` behavior used by the save action.

- [ ] **Step 1: Write failing set-editor tests**

```tsx
it('copies the preceding weight/repetition set and never removes the final set', async () => {
  const user = userEvent.setup();
  render(<WorkoutSetEditor exercise={weightExercise} value={[{ reps: '10', weight_kg: '60' }]} onChange={onChange} />);
  await user.click(screen.getByRole('button', { name: '세트 1 복사' }));
  expect(onChange).toHaveBeenLastCalledWith([{ reps: '10', weight_kg: '60' }, { reps: '10', weight_kg: '60' }]);
  expect(screen.queryByRole('button', { name: '세트 1 삭제' })).toBeNull();
});

it('renders seconds only for time exercises and meters only for distance exercises', () => {
  const { rerender } = render(<WorkoutSetEditor exercise={timeExercise} value={[emptySet]} onChange={onChange} />);
  expect(screen.getByLabelText('세트 1 시간(초)')).toBeVisible();
  rerender(<WorkoutSetEditor exercise={distanceExercise} value={[emptySet]} onChange={onChange} />);
  expect(screen.getByLabelText('세트 1 거리(m)')).toBeVisible();
});
```

- [ ] **Step 2: Run the editor tests and verify they fail**

Run: `npm --prefix frontend test -- WorkoutSetEditor.test.tsx --run`

Expected: FAIL because `WorkoutSetEditor` does not exist.

- [ ] **Step 3: Implement unit-specific fields and draft validation**

```tsx
export const emptyDraftSet = (): DraftSet => ({ reps: '', weight_kg: '', duration_seconds: '', distance_meters: '' });

export const isValidDraftSet = (set: DraftSet, unitKind: UnitKind) =>
  unitKind === 'reps_weight'
    ? Number(set.reps) >= 1 && Number(set.weight_kg) >= 0
    : unitKind === 'time'
      ? Number(set.duration_seconds) >= 1
      : Number(set.distance_meters) >= 1;
```

Render repetition/weight with `inputMode="numeric"` and `inputMode="decimal"`,
time with seconds, and distance with meters. Copy the prior set on add, show a
remove button only when `value.length > 1`, and never coerce an empty field to
zero before save validation.

- [ ] **Step 4: Run editor tests and frontend build**

Run: `npm --prefix frontend test -- WorkoutSetEditor.test.tsx --run; npm --prefix frontend run build`

Expected: PASS.

- [ ] **Step 5: Commit the set editor**

```bash
git add frontend/src/components/workout/WorkoutSetEditor.tsx frontend/src/components/workout/workout-records.css frontend/src/tests/components/workout/WorkoutSetEditor.test.tsx
git commit -m "feat: add resilient unit-aware workout set editor"
```

### Task 5: Compose catalog, set editor, and session progress into `/workout`

**Files:**
- Modify: `frontend/src/pages/WorkoutRecordsPage.tsx`
- Modify: `frontend/src/pages/WorkoutRecordsPage.css`
- Modify: `frontend/src/tests/pages/WorkoutRecordsPage.test.tsx`

**Interfaces:**
- Consumes: catalog endpoints from Task 2, `ExercisePicker`, `CustomExerciseSheet`, `WorkoutSetEditor`, and the existing `/workout-records?workout_id=<id>` list.
- Produces: a record hub that saves one selected exercise idempotently, keeps failed drafts, refreshes recent/favorites/progress, and preserves calendar history.

- [ ] **Step 1: Write failing page integration tests**

```tsx
it('keeps a failed draft and reuses the idempotency key on retry', async () => {
  post.mockRejectedValueOnce({ response: { data: { detail: 'offline' } } }).mockResolvedValueOnce({ data: { id: 9 } });
  const user = userEvent.setup();
  render(<MemoryRouter><WorkoutRecordsPage /></MemoryRouter>);
  await user.type(await screen.findByLabelText('세트 1 횟수'), '10');
  await user.type(screen.getByLabelText('세트 1 중량(kg)'), '60');
  await user.click(screen.getByRole('button', { name: '운동 저장' }));
  await user.click(await screen.findByRole('button', { name: '다시 저장' }));
  expect(post.mock.calls[0][2]?.headers?.['X-Idempotency-Key']).toBe(post.mock.calls[1][2]?.headers?.['X-Idempotency-Key']);
  expect(screen.getByLabelText('세트 1 횟수')).toHaveValue(10);
});

it('refreshes session progress after a successful record save', async () => {
  render(<MemoryRouter><WorkoutRecordsPage /></MemoryRouter>);
  await screen.findByText('오늘 진행 0종목 · 0세트');
  // Save a valid set and mock the workout-scoped records refresh.
  expect(await screen.findByText('오늘 진행 1종목 · 1세트')).toBeVisible();
});
```

- [ ] **Step 2: Run page tests and verify they fail**

Run: `npm --prefix frontend test -- WorkoutRecordsPage.test.tsx --run`

Expected: FAIL because the page has no catalog view, retry label, or session progress summary.

- [ ] **Step 3: Compose the components and preserve existing history**

```tsx
const refreshCatalog = async () => {
  const [all, recent, favorites] = await Promise.all([
    api.get('/exercises', { params: { scope: 'all' } }),
    api.get('/exercises/recent'),
    api.get('/exercises/favorites'),
  ]);
  setCatalog({ all: all.data, recent: recent.data, favorites: favorites.data });
};

const refreshSessionProgress = async (workoutId: number) => {
  const { data } = await api.get('/workout-records', { params: { workout_id: workoutId, limit: 100 } });
  setSessionRecords(data.items ?? []);
};
```

Use the existing `pendingIdempotencyKey` ref. Clear it and reset sets only after
`POST /workout-records` succeeds. On failure retain the selected exercise,
draft sets, and key; render an alert plus a `다시 저장` button. Keep the
calendar/history tab and its queries unchanged except for shared type imports.

- [ ] **Step 4: Run page tests, all frontend tests, and production build**

Run: `npm --prefix frontend test --run; npm --prefix frontend run build`

Expected: PASS, with the existing calendar/history tests still green.

- [ ] **Step 5: Commit the assembled record hub**

```bash
git add frontend/src/pages/WorkoutRecordsPage.tsx frontend/src/pages/WorkoutRecordsPage.css frontend/src/tests/pages/WorkoutRecordsPage.test.tsx
git commit -m "feat: integrate personalized catalog into workout records"
```

### Task 6: Verify mobile behavior and publish contract documentation

**Files:**
- Modify: `e2e/tests/mobile-matrix.spec.ts`
- Modify: `docs/workout-record-v2-api-contract.md`
- Modify: `backend/tests/api/test_exercise_catalog_api.py`
- Modify: `frontend/src/components/workout/workout-records.css`

**Interfaces:**
- Consumes: completed catalog API and `/workout` UI.
- Produces: documented additive contract and viewport regressions covering picker, sheet, set entry, and sticky save action.

- [ ] **Step 1: Write failing mobile/E2E assertions**

```ts
test('workout catalog stays tappable on narrow and short viewports', async ({ page }) => {
  for (const viewport of [{ width: 360, height: 800 }, { width: 844, height: 390 }]) {
    await page.setViewportSize(viewport);
    await page.goto('/workout');
    await expect(page.getByRole('tab', { name: '전체' })).toBeVisible();
    await expect(page.getByRole('button', { name: '운동 저장' })).toBeVisible();
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBeTruthy();
  }
});
```

- [ ] **Step 2: Run the focused E2E test and verify it fails**

Run: `npm --prefix e2e run test -- mobile-matrix.spec.ts`

Expected: FAIL until the new selector labels and mobile layout are implemented.

- [ ] **Step 3: Document exact endpoints and fix viewport-specific CSS**

Add request/response examples for custom creation, favorite put/delete, and
recent ordering to `docs/workout-record-v2-api-contract.md`. Add CSS that keeps
the picker list inside its card, places the custom sheet above
`env(safe-area-inset-bottom)`, and changes set rows to a single column below
`390px` without hiding the save action.

```css
@media (max-width: 390px) {
  .workout-set-editor__row { grid-template-columns: 32px minmax(0, 1fr); }
  .workout-set-editor__actions { grid-column: 2; justify-content: flex-end; }
  .workout-records__save-bar { bottom: calc(56px + env(safe-area-inset-bottom)); }
}
```

- [ ] **Step 4: Run complete verification**

Run: `cd backend; pytest tests/api/test_exercise_catalog_api.py tests/api/test_workout_records_api.py tests/test_migrations.py -v`

Run: `npm --prefix frontend test --run; npm --prefix frontend run build`

Run: `npm --prefix e2e run test -- mobile-matrix.spec.ts`

Expected: all commands exit 0; supported mobile viewports have no horizontal overflow.

- [ ] **Step 5: Commit documentation and final regression coverage**

```bash
git add e2e/tests/mobile-matrix.spec.ts docs/workout-record-v2-api-contract.md backend/tests/api/test_exercise_catalog_api.py frontend/src/components/workout/workout-records.css
git commit -m "test: verify personalized workout catalog on mobile"
```

## Plan Self-Review

- **Spec coverage:** Tasks 1-2 implement private custom exercises, favorites,
  record-derived recents, authorization, and validation. Tasks 3-5 implement
  selector modes, custom creation, unit-aware sets, idempotent retry, and
  session/completion-ready summary. Task 6 covers mobile, accessibility-facing
  controls, API documentation, and regression verification.
- **Placeholder scan:** No incomplete markers or deferred implementation steps
  appear in the task instructions; explicitly out-of-scope features are listed
  in Global Constraints.
- **Type consistency:** `ExerciseCatalogItem`, `DraftSet`, catalog route names,
  favorite routes, and `WorkoutSetEditor` callbacks are defined before they are
  consumed by later tasks.