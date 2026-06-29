import { useEffect, useState, useRef, type FormEvent } from 'react';
import api from '../../api';

interface Workout {
  id: string;
  started_at: string;
  ended_at?: string;
  status: 'active' | 'ended' | 'done';
  party_id?: string | null;
  notes?: string;
  duration_seconds?: number;
  setlog_count?: number;
  breakthroughs?: Array<{ part: string; old_level: number; new_level: number }>;
  body_stats?: Array<{ part: string; level: number; potential: number }>;
}

interface Setlog {
  id: string;
  type: 'start' | 'mid' | 'end';
  content: string;
  created_at: string;
}

const PART_LABELS: Record<string, string> = {
  chest: '가슴', back: '등', shoulders: '어깨', arms: '팔',
  core: '코어', stamina: '유산소', legs: '하체',
};

const SETLOG_ICON: Record<string, string> = { start: '▶', mid: '●', end: '✓' };
const SETLOG_LABEL: Record<string, string> = { start: '시작', mid: '중간', end: '종료' };
const SETLOG_COLOR: Record<string, string> = { start: '#4caf50', mid: '#f0a500', end: '#ff3d3d' };

interface WorkoutPanelProps {
  partyId: string | null;
  onWorkoutEnded?: () => void;
}

function WorkoutPanel({ partyId, onWorkoutEnded }: WorkoutPanelProps) {
  const [phase, setPhase] = useState<'loading' | 'idle' | 'active' | 'ended'>('loading');
  const [workout, setWorkout] = useState<Workout | null>(null);
  const [setlogs, setSetlogs] = useState<Setlog[]>([]);
  const [elapsed, setElapsed] = useState(0);
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const [setlogType, setSetlogType] = useState<'start' | 'mid' | 'end'>('start');
  const [setlogContent, setSetlogContent] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [ending, setEnding] = useState(false);

  const [notes, setNotes] = useState('');
  const [creating, setCreating] = useState(false);

  const [resultWorkout, setResultWorkout] = useState<Workout | null>(null);

  const scrollRef = useRef<HTMLDivElement>(null);

  // Find active workout on mount
  useEffect(() => {
    api.get('/workouts/')
      .then(({ data }) => {
        const list: Workout[] = Array.isArray(data) ? data : data.workouts ?? [];
        const active = list.find(w => w.status === 'active');
        if (active) {
          setWorkout(active);
          setPhase('active');
          return api.get(`/workouts/${active.id}/setlogs`);
        }
        setPhase('idle');
        return null;
      })
      .then(res => {
        if (res) setSetlogs(Array.isArray(res.data) ? res.data : []);
      })
      .catch(() => setPhase('idle'));
  }, []);

  // Timer
  useEffect(() => {
    if (phase !== 'active' || !workout) return;
    const start = new Date(workout.started_at).getTime();
    const tick = () => setElapsed(Math.floor((Date.now() - start) / 1000));
    tick();
    timerRef.current = setInterval(tick, 1000);
    return () => { if (timerRef.current) clearInterval(timerRef.current); };
  }, [phase, workout]);

  // Auto-scroll on new setlog
  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
    }
  }, [setlogs.length]);

  const fmt = (s: number) => {
    const h = Math.floor(s / 3600);
    const m = Math.floor((s % 3600) / 60);
    const sec = s % 60;
    if (h > 0) return `${h}:${String(m).padStart(2, '0')}:${String(sec).padStart(2, '0')}`;
    return `${String(m).padStart(2, '0')}:${String(sec).padStart(2, '0')}`;
  };

  const fmtDuration = (s?: number) => {
    if (!s) return '-';
    const m = Math.floor(s / 60);
    const sec = s % 60;
    return sec > 0 ? `${m}분 ${sec}초` : `${m}분`;
  };

  const handleStart = async (e: FormEvent) => {
    e.preventDefault();
    setCreating(true);
    try {
      const payload: Record<string, unknown> = {};
      if (partyId) payload.party_id = Number(partyId);
      if (notes.trim()) payload.notes = notes.trim();
      const { data } = await api.post('/workouts/', payload);
      setWorkout(data);
      setSetlogs([]);
      setPhase('active');
      setNotes('');
    } catch (err: any) {
      alert(err.response?.data?.detail || err.response?.data?.message || '운동 시작 실패');
    } finally {
      setCreating(false);
    }
  };

  const handleAddSetlog = async (e: FormEvent) => {
    e.preventDefault();
    if (!setlogContent.trim() || !workout) return;
    setSubmitting(true);
    try {
      const { data } = await api.post(`/workouts/${workout.id}/setlogs`, {
        type: setlogType,
        content: setlogContent.trim(),
      });
      setSetlogs(prev => [...prev, data]);
      setSetlogContent('');
    } catch (err: any) {
      alert(err.response?.data?.detail || '기록 실패');
    } finally {
      setSubmitting(false);
    }
  };

  const handleEnd = async () => {
    if (!workout || ending) return;
    setEnding(true);
    try {
      const { data } = await api.post(`/workouts/${workout.id}/end`);
      if (timerRef.current) clearInterval(timerRef.current);
      setResultWorkout(data);
      setPhase('ended');
      onWorkoutEnded?.();
    } catch (err: any) {
      alert(err.response?.data?.detail || '종료 실패');
    } finally {
      setEnding(false);
    }
  };

  // ── Loading ──────────────────────────────────────────────────────────────
  if (phase === 'loading') {
    return (
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100%', color: '#444' }}>
        로딩 중…
      </div>
    );
  }

  // ── Idle ─────────────────────────────────────────────────────────────────
  if (phase === 'idle') {
    return (
      <div style={{
        display: 'flex',
        flexDirection: 'column',
        height: '100%',
        alignItems: 'center',
        justifyContent: 'center',
        padding: '24px',
      }}>
        <div style={{ width: '100%', maxWidth: '380px' }}>
          <div style={{ textAlign: 'center', marginBottom: '28px' }}>
            <div style={{ fontSize: '2.5rem', marginBottom: '10px' }}>🔥</div>
            <h2 style={{ fontSize: '1.3rem', fontWeight: 700, marginBottom: '6px' }}>
              운동 시작하기
            </h2>
            <p style={{ color: 'var(--color-text-secondary)', fontSize: '0.85rem' }}>
              {partyId
                ? '선택된 파티와 함께 운동합니다'
                : '파티를 선택하거나 혼자 운동하세요'}
            </p>
          </div>

          <form onSubmit={handleStart} style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
            <textarea
              value={notes}
              onChange={e => setNotes(e.target.value)}
              placeholder="오늘 운동 목표나 메모… (선택)"
              rows={3}
              style={{
                padding: '11px 13px',
                background: 'var(--color-bg-surface)',
                border: '1px solid var(--color-border-subtle)',
                borderRadius: '10px',
                color: 'var(--color-text-primary)',
                fontSize: '0.88rem',
                resize: 'none',
                fontFamily: 'inherit',
                outline: 'none',
              }}
            />
            <button
              type="submit"
              disabled={creating}
              style={{
                padding: '13px',
                background: creating ? '#552200' : '#ff3d3d',
                border: 'none',
                borderRadius: '11px',
                color: '#fff',
                fontWeight: 700,
                fontSize: '0.95rem',
                cursor: creating ? 'not-allowed' : 'pointer',
                transition: 'background 0.15s',
              }}
            >
              {creating ? '시작 중…' : '🔥 운동 시작'}
            </button>
          </form>
        </div>
      </div>
    );
  }

  // ── Active ────────────────────────────────────────────────────────────────
  if (phase === 'active' && workout) {
    return (
      <div style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>

        {/* Timer bar */}
        <div style={{
          padding: '14px 20px',
          borderBottom: '1px solid var(--color-border-subtle)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          flexShrink: 0,
          background: 'var(--color-bg-muted)',
        }}>
          <div>
            <div style={{ fontSize: '0.65rem', color: '#555', textTransform: 'uppercase', letterSpacing: '0.1em', marginBottom: '2px' }}>
              운동 중
            </div>
            <div style={{
              fontSize: '1.9rem',
              fontWeight: 700,
              fontFamily: 'monospace',
              letterSpacing: '2px',
              color: '#ff3d3d',
              lineHeight: 1,
            }}>
              {fmt(elapsed)}
            </div>
          </div>
          <div style={{ textAlign: 'right', display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: '6px' }}>
            <div style={{ fontSize: '0.7rem', color: '#555' }}>
              {setlogs.length}개 기록
            </div>
            <button
              onClick={handleEnd}
              disabled={ending}
              style={{
                padding: '7px 14px',
                background: 'rgba(255,61,61,0.12)',
                border: '1px solid rgba(255,61,61,0.35)',
                borderRadius: '7px',
                color: '#ff3d3d',
                fontWeight: 700,
                fontSize: '0.8rem',
                cursor: ending ? 'not-allowed' : 'pointer',
                opacity: ending ? 0.6 : 1,
              }}
            >
              {ending ? '종료 중…' : '운동 종료'}
            </button>
          </div>
        </div>

        {/* Setlog list */}
        <div
          ref={scrollRef}
          style={{
            flex: 1,
            overflowY: 'auto',
            padding: '12px 16px',
            display: 'flex',
            flexDirection: 'column',
            gap: '6px',
          }}
        >
          {setlogs.length === 0 ? (
            <div style={{
              flex: 1,
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              justifyContent: 'center',
              color: '#444',
              fontSize: '0.85rem',
              gap: '8px',
              paddingTop: '40px',
            }}>
              <div style={{ fontSize: '1.8rem' }}>📝</div>
              <div>첫 세트로그를 등록하세요</div>
            </div>
          ) : (
            setlogs.map(sl => (
              <div
                key={sl.id}
                style={{
                  display: 'flex',
                  gap: '10px',
                  padding: '9px 12px',
                  background: 'var(--color-bg-surface)',
                  borderRadius: '8px',
                  border: '1px solid var(--color-border-subtle)',
                }}
              >
                <div style={{
                  fontSize: '0.78rem',
                  fontWeight: 700,
                  color: SETLOG_COLOR[sl.type],
                  flexShrink: 0,
                  width: '16px',
                  paddingTop: '1px',
                  textAlign: 'center',
                }}>
                  {SETLOG_ICON[sl.type]}
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: '0.87rem', color: 'var(--color-text-primary)', lineHeight: 1.5, whiteSpace: 'pre-wrap' }}>
                    {sl.content}
                  </div>
                  <div style={{ fontSize: '0.65rem', color: '#555', marginTop: '3px' }}>
                    {SETLOG_LABEL[sl.type]} · {new Date(sl.created_at).toLocaleTimeString('ko-KR', { hour: '2-digit', minute: '2-digit' })}
                  </div>
                </div>
              </div>
            ))
          )}
        </div>

        {/* Input area */}
        <form
          onSubmit={handleAddSetlog}
          style={{
            borderTop: '1px solid var(--color-border-subtle)',
            padding: '10px 14px',
            flexShrink: 0,
            display: 'flex',
            flexDirection: 'column',
            gap: '7px',
          }}
        >
          {/* Type selector */}
          <div style={{ display: 'flex', gap: '5px' }}>
            {(['start', 'mid', 'end'] as const).map(t => (
              <button
                key={t}
                type="button"
                onClick={() => setSetlogType(t)}
                style={{
                  flex: 1,
                  padding: '5px 4px',
                  background: setlogType === t ? `rgba(${t === 'start' ? '76,175,80' : t === 'mid' ? '240,165,0' : '255,61,61'},0.12)` : 'var(--color-bg-surface)',
                  border: setlogType === t
                    ? `1px solid ${SETLOG_COLOR[t]}55`
                    : '1px solid var(--color-border-subtle)',
                  borderRadius: '6px',
                  color: setlogType === t ? SETLOG_COLOR[t] : 'var(--color-text-secondary)',
                  fontWeight: setlogType === t ? 700 : 400,
                  fontSize: '0.76rem',
                  cursor: 'pointer',
                  transition: 'all 0.12s',
                }}
              >
                {SETLOG_ICON[t]} {SETLOG_LABEL[t]}
              </button>
            ))}
          </div>

          {/* Text input + submit */}
          <div style={{ display: 'flex', gap: '7px', alignItems: 'flex-end' }}>
            <textarea
              value={setlogContent}
              onChange={e => setSetlogContent(e.target.value)}
              onKeyDown={e => {
                if (e.key === 'Enter' && (e.metaKey || e.ctrlKey)) {
                  e.preventDefault();
                  handleAddSetlog(e as any);
                }
              }}
              placeholder={`${SETLOG_LABEL[setlogType]} 기록… (Ctrl+Enter)`}
              rows={2}
              style={{
                flex: 1,
                padding: '9px 11px',
                background: 'var(--color-bg-surface)',
                border: '1px solid var(--color-border-subtle)',
                borderRadius: '8px',
                color: 'var(--color-text-primary)',
                fontSize: '0.87rem',
                resize: 'none',
                fontFamily: 'inherit',
                outline: 'none',
              }}
            />
            <button
              type="submit"
              disabled={submitting || !setlogContent.trim()}
              style={{
                padding: '0 14px',
                height: '60px',
                background: submitting || !setlogContent.trim() ? '#222' : '#ff3d3d',
                border: 'none',
                borderRadius: '8px',
                color: submitting || !setlogContent.trim() ? '#555' : '#fff',
                fontWeight: 700,
                fontSize: '0.82rem',
                cursor: submitting || !setlogContent.trim() ? 'not-allowed' : 'pointer',
                flexShrink: 0,
                transition: 'all 0.12s',
              }}
            >
              등록
            </button>
          </div>
        </form>
      </div>
    );
  }

  // ── Ended ─────────────────────────────────────────────────────────────────
  if (phase === 'ended' && resultWorkout) {
    const rw = resultWorkout;
    const hasBreak = (rw.breakthroughs?.length ?? 0) > 0;

    return (
      <div style={{ display: 'flex', flexDirection: 'column', height: '100%', overflowY: 'auto' }}>
        <div style={{ maxWidth: '420px', margin: '0 auto', width: '100%', padding: '28px 20px' }}>

          {/* Header */}
          <div style={{ textAlign: 'center', marginBottom: '22px' }}>
            <div style={{ fontSize: '2.5rem', marginBottom: '8px' }}>{hasBreak ? '🏆' : '💪'}</div>
            <h2 style={{ fontSize: '1.4rem', fontWeight: 700, marginBottom: '4px' }}>운동 완료!</h2>
            <p style={{ color: hasBreak ? '#ff6b6b' : 'var(--color-text-secondary)', fontSize: '0.85rem' }}>
              {hasBreak ? '🔥 돌파 달성!' : '잠재력이 쌓이고 있어요 ⚡'}
            </p>
          </div>

          {/* Stats grid */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px', marginBottom: '14px' }}>
            <div style={statCard}>
              <div style={statLabel}>운동 시간</div>
              <div style={statValue}>{fmtDuration(rw.duration_seconds)}</div>
            </div>
            <div style={statCard}>
              <div style={statLabel}>세트로그</div>
              <div style={statValue}>{rw.setlog_count ?? 0}개</div>
            </div>
          </div>

          {/* Breakthroughs */}
          {hasBreak && rw.breakthroughs && (
            <div style={{
              background: 'rgba(255,61,61,0.07)',
              border: '1px solid rgba(255,61,61,0.22)',
              borderRadius: '10px',
              padding: '14px 16px',
              marginBottom: '14px',
            }}>
              <div style={{ fontWeight: 700, color: '#ff3d3d', fontSize: '0.88rem', marginBottom: '8px' }}>
                🏆 레벨 업!
              </div>
              {rw.breakthroughs.map(b => (
                <div key={b.part} style={{ fontSize: '0.82rem', color: 'var(--color-text-secondary)', marginBottom: '3px' }}>
                  {PART_LABELS[b.part] || b.part}
                  {' '}Lv.{b.old_level}{' '}
                  <span style={{ color: '#ff6b6b', fontWeight: 700 }}>→ Lv.{b.new_level}</span>
                </div>
              ))}
            </div>
          )}

          {/* Body stats */}
          {rw.body_stats && rw.body_stats.length > 0 && (
            <div style={{
              background: 'var(--color-bg-surface)',
              border: '1px solid var(--color-border-subtle)',
              borderRadius: '10px',
              padding: '14px 16px',
              marginBottom: '14px',
            }}>
              <div style={{ fontSize: '0.7rem', color: 'var(--color-text-secondary)', textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: '10px' }}>
                신체 부위
              </div>
              {rw.body_stats.map(stat => {
                const isNew = rw.breakthroughs?.some(b => b.part === stat.part);
                const pct = Math.min(stat.potential, 100);
                return (
                  <div key={stat.part} style={{ marginBottom: '8px' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '3px' }}>
                      <span style={{ fontSize: '0.8rem', color: isNew ? '#ff6b6b' : 'var(--color-text-primary)' }}>
                        {isNew && '✨ '}{PART_LABELS[stat.part] || stat.part}
                      </span>
                      <span style={{ fontSize: '0.8rem', fontWeight: 700, color: isNew ? '#ff6b6b' : 'var(--color-text-primary)' }}>
                        Lv.{stat.level}
                      </span>
                    </div>
                    <div style={{ height: '3px', background: '#1a1a1a', borderRadius: '2px', overflow: 'hidden' }}>
                      <div style={{
                        width: `${pct}%`,
                        height: '100%',
                        background: isNew ? '#ff3d3d' : '#333',
                        borderRadius: '2px',
                        transition: 'width 0.4s',
                      }} />
                    </div>
                  </div>
                );
              })}
            </div>
          )}

          {/* Actions */}
          <button
            onClick={() => {
              setPhase('idle');
              setResultWorkout(null);
              setWorkout(null);
              setSetlogs([]);
              setSetlogContent('');
            }}
            style={{
              width: '100%',
              padding: '13px',
              background: '#ff3d3d',
              border: 'none',
              borderRadius: '10px',
              color: '#fff',
              fontWeight: 700,
              fontSize: '0.92rem',
              cursor: 'pointer',
            }}
          >
            🔥 새 운동 시작
          </button>
        </div>
      </div>
    );
  }

  return null;
}

const statCard: React.CSSProperties = {
  background: 'var(--color-bg-surface)',
  borderRadius: '10px',
  padding: '14px',
  textAlign: 'center',
  border: '1px solid var(--color-border-subtle)',
};

const statLabel: React.CSSProperties = {
  fontSize: '0.7rem',
  color: 'var(--color-text-secondary)',
  marginBottom: '4px',
  textTransform: 'uppercase',
  letterSpacing: '0.06em',
};

const statValue: React.CSSProperties = {
  fontSize: '1.2rem',
  fontWeight: 700,
  color: 'var(--color-text-primary)',
};

export default WorkoutPanel;
