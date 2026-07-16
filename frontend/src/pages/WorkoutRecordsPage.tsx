import { useCallback, useEffect, useMemo, useRef, useState, type FormEvent } from 'react';
import { Link } from 'react-router-dom';
import api from '../api';
import './WorkoutRecordsPage.css';

type UnitKind = 'reps_weight' | 'time' | 'distance';

type Exercise = {
  id: number;
  canonical_name: string;
  display_name_kr: string;
  unit_kind: UnitKind;
  body_part: string;
};

type DraftSet = {
  reps: string;
  weight_kg: string;
  duration_seconds: string;
  distance_meters: string;
};

type ExerciseSet = {
  set_index: number;
  reps?: number | null;
  weight_kg?: number | null;
  duration_seconds?: number | null;
  distance_meters?: number | null;
};

type RecordItem = {
  id: number;
  exercise: Exercise;
  performed_at: string;
  sets: ExerciseSet[];
};

type ActiveWorkout = {
  id: number;
  status: string;
};

type CalendarDay = {
  date: string;
  record_count: number;
  body_parts: string[];
};

const emptySet = (): DraftSet => ({
  reps: '',
  weight_kg: '',
  duration_seconds: '',
  distance_meters: '',
});

const localDateKey = (date: Date) => {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
};

const dateFromKey = (value: string) => new Date(`${value}T12:00:00`);
const firstOfMonth = (value: string) => {
  const date = dateFromKey(value);
  return new Date(date.getFullYear(), date.getMonth(), 1);
};
const lastOfMonth = (date: Date) => new Date(date.getFullYear(), date.getMonth() + 1, 0);
const addDays = (value: string, amount: number) => {
  const date = dateFromKey(value);
  date.setDate(date.getDate() + amount);
  return localDateKey(date);
};
const addMonths = (date: Date, amount: number) => new Date(date.getFullYear(), date.getMonth() + amount, 1);

const describeSet = (set: ExerciseSet, exercise: Exercise) => {
  if (exercise.unit_kind === 'time') return `${set.duration_seconds ?? 0}s`;
  if (exercise.unit_kind === 'distance') return `${set.distance_meters ?? 0}m`;
  return `${set.reps ?? 0} reps × ${set.weight_kg ?? 0}kg`;
};

export default function WorkoutRecordsPage() {
  const [tab, setTab] = useState<'input' | 'history'>('input');
  const [exercises, setExercises] = useState<Exercise[]>([]);
  const [exerciseId, setExerciseId] = useState<number>();
  const [activeWorkout, setActiveWorkout] = useState<ActiveWorkout | null>(null);
  const [query, setQuery] = useState('');
  const [sets, setSets] = useState<DraftSet[]>([emptySet()]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');
  const [selectedDate, setSelectedDate] = useState(localDateKey(new Date()));
  const [month, setMonth] = useState(firstOfMonth(localDateKey(new Date())));
  const [calendarDays, setCalendarDays] = useState<CalendarDay[]>([]);
  const [dayRecords, setDayRecords] = useState<RecordItem[]>([]);
  const [historyLoading, setHistoryLoading] = useState(false);
  const [calendarVersion, setCalendarVersion] = useState(0);
  const pendingIdempotencyKey = useRef<string | null>(null);

  const timeZone = useMemo(
    () => Intl.DateTimeFormat().resolvedOptions().timeZone || 'Asia/Seoul',
    [],
  );

  const loadInitial = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const [exerciseResponse, workoutResponse] = await Promise.all([
        api.get('/exercises'),
        api.get('/workouts/'),
      ]);
      const exerciseList: Exercise[] = Array.isArray(exerciseResponse.data)
        ? exerciseResponse.data
        : [];
      const workouts: ActiveWorkout[] = Array.isArray(workoutResponse.data)
        ? workoutResponse.data
        : [];
      setExercises(exerciseList);
      setExerciseId((current) => current ?? exerciseList[0]?.id);
      setActiveWorkout(workouts.find((item) => item.status === 'active') ?? null);
    } catch {
      setError('Could not load the workout record screen. Check your connection and try again.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void loadInitial();
  }, [loadInitial]);

  useEffect(() => {
    const start = localDateKey(month);
    const end = localDateKey(lastOfMonth(month));
    let active = true;
    api.get('/workout-records/calendar', { params: { from: start, to: end, tz: timeZone } })
      .then(({ data }) => {
        if (active) setCalendarDays(Array.isArray(data?.days) ? data.days : []);
      })
      .catch(() => {
        if (active) setCalendarDays([]);
      });
    return () => { active = false; };
  }, [calendarVersion, month, timeZone]);

  useEffect(() => {
    if (tab !== 'history') return;
    const start = dateFromKey(selectedDate);
    start.setHours(0, 0, 0, 0);
    const end = new Date(start);
    end.setHours(23, 59, 59, 999);
    let active = true;
    setHistoryLoading(true);
    api.get('/workout-records', {
      params: { from: start.toISOString(), to: end.toISOString(), limit: 100 },
    })
      .then(({ data }) => {
        if (active) setDayRecords(Array.isArray(data?.items) ? data.items : []);
      })
      .catch(() => {
        if (active) setError('Could not load records for this date.');
      })
      .finally(() => {
        if (active) setHistoryLoading(false);
      });
    return () => { active = false; };
  }, [selectedDate, tab, calendarVersion]);

  const selected = exercises.find((item) => item.id === exerciseId);
  const filtered = useMemo(() => {
    const normalized = query.trim().toLowerCase();
    if (!normalized) return exercises;
    return exercises.filter((item) =>
      `${item.display_name_kr} ${item.canonical_name} ${item.body_part}`
        .toLowerCase()
        .includes(normalized),
    );
  }, [exercises, query]);

  const calendarMap = useMemo(
    () => new Map(calendarDays.map((day) => [day.date, day])),
    [calendarDays],
  );
  const monthCells = useMemo(() => {
    const count = lastOfMonth(month).getDate();
    const leading = month.getDay();
    return [
      ...Array.from({ length: leading }, () => null),
      ...Array.from({ length: count }, (_, index) => index + 1),
    ];
  }, [month]);

  const updateSet = (index: number, field: keyof DraftSet, value: string) => {
    setSets((current) => current.map((item, itemIndex) =>
      itemIndex === index ? { ...item, [field]: value } : item,
    ));
  };

  const chooseExercise = (id: number) => {
    setExerciseId(id);
    setSets([emptySet()]);
    setError('');
  };

  const buildSets = (unitKind: UnitKind) => sets.map((item, index) => {
    if (unitKind === 'time') {
      return { set_index: index, duration_seconds: Number(item.duration_seconds) };
    }
    if (unitKind === 'distance') {
      return { set_index: index, distance_meters: Number(item.distance_meters) };
    }
    return {
      set_index: index,
      reps: Number(item.reps),
      weight_kg: Number(item.weight_kg),
    };
  });

  const validateSets = (unitKind: UnitKind) => {
    if (unitKind === 'time') {
      return sets.every((item) => Number(item.duration_seconds) >= 1);
    }
    if (unitKind === 'distance') {
      return sets.every((item) => Number(item.distance_meters) >= 1);
    }
    return sets.every((item) => Number(item.reps) >= 1 && Number(item.weight_kg) >= 0);
  };

  const save = async (event: FormEvent) => {
    event.preventDefault();
    setError('');
    setMessage('');
    if (!activeWorkout) {
      setError('Start a workout session before saving structured records.');
      return;
    }
    if (!selected) {
      setError('Select an exercise.');
      return;
    }
    if (!validateSets(selected.unit_kind)) {
      setError(selected.unit_kind === 'reps_weight'
        ? 'Reps must be at least 1 and weight cannot be negative.'
        : 'Enter a value of at least 1 for every set.');
      return;
    }

    const key = pendingIdempotencyKey.current
      ?? globalThis.crypto?.randomUUID?.()
      ?? `record-${Date.now()}-${Math.random().toString(16).slice(2)}`;
    pendingIdempotencyKey.current = key;
    setSaving(true);
    try {
      const payload = {
        workout_id: activeWorkout.id,
        exercise_id: selected.id,
        performed_at: new Date().toISOString(),
        sets: buildSets(selected.unit_kind),
      };
      await api.post('/workout-records', payload, {
        headers: { 'X-Idempotency-Key': key },
      });
      pendingIdempotencyKey.current = null;
      setSets([emptySet()]);
      setMessage(`${selected.display_name_kr} saved.`);
      setCalendarVersion((current) => current + 1);
    } catch (requestError: any) {
      const detail = requestError.response?.data?.detail;
      setError(
        (typeof detail === 'string' ? detail : detail?.message)
        || 'Could not save this record. Your entries are still here; tap save to retry.',
      );
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="records-page" aria-busy="true" aria-label="Loading workout records">
        <div className="records-skeleton" />
        <div className="records-skeleton records-skeleton--short" />
      </div>
    );
  }

  return (
    <div className="records-page">
      <header className="records-header">
        <div>
          <p className="records-eyebrow">WORKOUT LOG</p>
          <h1>Today&apos;s workout</h1>
          <p className="records-muted">Capture each set as you go.</p>
        </div>
        <Link className="session-link" to={activeWorkout ? `/workout/${activeWorkout.id}` : '/workout/session'}>
          {activeWorkout ? 'Open session' : 'Start session'}
        </Link>
      </header>

      <div className="record-tabs" role="tablist" aria-label="Workout record views">
        <button type="button" role="tab" aria-selected={tab === 'input'} className={tab === 'input' ? 'is-active' : ''} onClick={() => setTab('input')}>Log workout</button>
        <button type="button" role="tab" aria-selected={tab === 'history'} className={tab === 'history' ? 'is-active' : ''} onClick={() => setTab('history')}>History</button>
      </div>

      {message && <div className="records-notice" role="status">{message}</div>}
      {error && <div className="records-error" role="alert"><span>{error}</span>{loading ? null : <button type="button" onClick={() => void loadInitial()}>Retry</button>}</div>}

      {tab === 'input' ? (
        <form className="record-form" onSubmit={save}>
          {!activeWorkout && (
            <section className="session-callout">
              <div>
                <h2>Start a workout first</h2>
                <p>Structured sets attach to an active workout and feed your body-part growth.</p>
              </div>
              <Link to="/workout/session">Start workout</Link>
            </section>
          )}

          <section className="record-card">
            <div className="section-heading"><h2>What did you train?</h2></div>
            <label className="field-label" htmlFor="exercise-search">Exercise search</label>
            <input id="exercise-search" className="search-input" placeholder="Search exercises" value={query} onChange={(event) => setQuery(event.target.value)} />
            <div className="exercise-list" role="listbox" aria-label="Exercises">
              {filtered.map((item) => (
                <button type="button" role="option" aria-selected={item.id === exerciseId} className={item.id === exerciseId ? 'exercise-option selected' : 'exercise-option'} key={item.id} onClick={() => chooseExercise(item.id)}>
                  <span><strong>{item.display_name_kr}</strong><small>{item.body_part}</small></span>
                  <span className="selected-label" aria-hidden="true">{item.id === exerciseId ? 'Selected' : ''}</span>
                </button>
              ))}
              {!filtered.length && <p className="records-muted exercise-empty">No matching exercises.</p>}
            </div>
          </section>

          <section className="record-card">
            <div className="section-heading">
              <h2>{selected?.display_name_kr ?? 'Exercise'} sets</h2>
              <button type="button" className="text-button" onClick={() => setSets((current) => [...current, emptySet()])}>Add set</button>
            </div>
            {sets.map((item, index) => (
              <div className={`set-row ${selected?.unit_kind === 'reps_weight' ? '' : 'set-row--single'}`} key={index}>
                <span className="set-number" aria-label={`Set ${index + 1}`}>{index + 1}</span>
                {selected?.unit_kind === 'time' ? (
                  <label><span>Seconds</span><input aria-label={`Set ${index + 1} seconds`} inputMode="numeric" min="1" type="number" value={item.duration_seconds} onChange={(event) => updateSet(index, 'duration_seconds', event.target.value)} placeholder="60" /></label>
                ) : selected?.unit_kind === 'distance' ? (
                  <label><span>Meters</span><input aria-label={`Set ${index + 1} meters`} inputMode="decimal" min="1" step="1" type="number" value={item.distance_meters} onChange={(event) => updateSet(index, 'distance_meters', event.target.value)} placeholder="1000" /></label>
                ) : (
                  <>
                    <label><span>Reps</span><input aria-label={`Set ${index + 1} reps`} inputMode="numeric" min="1" type="number" value={item.reps} onChange={(event) => updateSet(index, 'reps', event.target.value)} placeholder="10" /></label>
                    <label><span>Weight (kg)</span><input aria-label={`Set ${index + 1} weight`} inputMode="decimal" min="0" step="0.5" type="number" value={item.weight_kg} onChange={(event) => updateSet(index, 'weight_kg', event.target.value)} placeholder="20" /></label>
                  </>
                )}
                <button type="button" className="copy-button" aria-label={`Duplicate set ${index + 1}`} onClick={() => setSets((current) => [...current, { ...current[index] }])}>Copy</button>
              </div>
            ))}
          </section>

          <div className="save-bar">
            <button className="save-button" type="submit" disabled={saving || !activeWorkout || !selected}>
              {saving ? 'Saving…' : 'Save workout'}
            </button>
          </div>
        </form>
      ) : (
        <section className="history-section">
          <div className="month-controls">
            <button type="button" aria-label="Previous month" onClick={() => setMonth((current) => addMonths(current, -1))}>‹</button>
            <strong>{month.toLocaleDateString(undefined, { month: 'long', year: 'numeric' })}</strong>
            <button type="button" aria-label="Next month" onClick={() => setMonth((current) => addMonths(current, 1))}>›</button>
          </div>
          <div className="calendar-card">
            <div className="calendar-weekdays" aria-hidden="true">{['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day, index) => <span key={`${day}-${index}`}>{day}</span>)}</div>
            <div className="calendar-grid">
              {monthCells.map((day, index) => {
                if (day === null) return <span key={`blank-${index}`} />;
                const key = localDateKey(new Date(month.getFullYear(), month.getMonth(), day));
                const summary = calendarMap.get(key);
                return (
                  <button type="button" key={key} className={selectedDate === key ? 'selected' : ''} aria-label={`${key}${summary ? `, ${summary.record_count} records` : ', no records'}`} aria-pressed={selectedDate === key} onClick={() => setSelectedDate(key)}>
                    <span>{day}</span>{summary && <small>{summary.record_count}</small>}
                  </button>
                );
              })}
            </div>
          </div>
          <div className="day-controls">
            <button type="button" aria-label="Previous day" onClick={() => setSelectedDate((current) => addDays(current, -1))}>‹</button>
            <strong>{selectedDate}</strong>
            <button type="button" aria-label="Next day" onClick={() => setSelectedDate((current) => addDays(current, 1))}>›</button>
          </div>
          {historyLoading ? <div className="records-skeleton records-skeleton--short" aria-label="Loading records" /> : dayRecords.length ? dayRecords.map((item) => (
            <article className="history-card" key={item.id}>
              <div><h2>{item.exercise.display_name_kr}</h2><p className="records-muted">{item.exercise.body_part} · {item.sets.length} sets</p></div>
              <ol>{item.sets.map((set) => <li key={set.set_index}>{describeSet(set, item.exercise)}</li>)}</ol>
            </article>
          )) : (
            <div className="empty-state"><h2>No records yet</h2><p>Saved workouts will appear on this date.</p><button type="button" onClick={() => setTab('input')}>Log a workout</button></div>
          )}
        </section>
      )}
    </div>
  );
}