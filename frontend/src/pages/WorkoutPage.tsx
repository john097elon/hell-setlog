import { useParams, useNavigate } from 'react-router-dom';
import { useEffect, useState, useRef, type FormEvent } from 'react';
import api from '../api';
import StreakBadge from '../components/StreakBadge';
import type { BodyPart } from '../components/CharacterPreview';
import { useWorkoutDraft } from '../hooks/useWorkoutDraft';

interface Workout {
  id: string;
  party_id: string;
  status: 'active' | 'ended' | 'done' | 'cancelled';
  started_at: string;
  ended_at?: string;
  duration_seconds?: number;
  setlog_count?: number;
  notes?: string;
  body_stats?: BodyPart[];
  setlogs?: Setlog[];
  breakthroughs?: Array<{
    part: string;
    old_level: number;
    new_level: number;
  }>;
}

interface Setlog {
  id: string;
  type: 'start' | 'mid' | 'end';
  content: string;
  file_path?: string;
  created_at: string;
}

type WorkoutState = 'idle' | 'active' | 'ended';

const PART_LABELS: Record<string, string> = {
  chest: '가슴', back: '등', shoulders: '어깨', arms: '팔',
  core: '코어', stamina: '유산소', abs: '복근', legs: '하체', cardio: '유산소',
};

function WorkoutPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
const { draft, updateDraft, clearDraft } = useWorkoutDraft();

  // ---- State ----
  const [phase, setPhase] = useState<WorkoutState>(id ? 'active' : 'idle');
  const [workout, setWorkout] = useState<Workout | null>(null);
  const [setlogs, setSetlogs] = useState<Setlog[]>([]);
  const [loading, setLoading] = useState(!!id);
  const [error, setError] = useState('');

  // Idle form state
  const [partyId, setPartyId] = useState(draft.partyId || '');
  const [notes, setNotes] = useState(draft.notes || '');
  const [creating, setCreating] = useState(false);

  // Active form state
  const [setlogType, setSetlogType] = useState<'start' | 'mid' | 'end'>('start');
  const [setlogContent, setSetlogContent] = useState('');
  const [setlogFile, setSetlogFile] = useState<File | null>(null);
  const [submitting, setSubmitting] = useState(false);

  // Timer
  const [elapsed, setElapsed] = useState(0);
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Ended state
  const [ending, setEnding] = useState(false);
  const [resultWorkout, setResultWorkout] = useState<Workout | null>(null);

  // ---- Recover an in-progress workout when landing on the idle screen ----
  useEffect(() => {
    if (id) return;
    api.get('/workouts/')
      .then(({ data }) => {
        const active = Array.isArray(data)
          ? data.find((w: Workout) => w.status === 'active')
          : null;
        if (active) navigate(`/workout/${active.id}`, { replace: true });
      })
      .catch(() => {});
  }, [id]);

  // ---- Fetch existing workout ----
  useEffect(() => {
    if (!id) return;
    setLoading(true);
    api.get(`/workouts/${id}`)
      .then(({ data }) => {
        const w: Workout = data;
        setWorkout(w);
        if (w.status === 'cancelled') {
          // A cancelled workout has no result screen — go start a fresh one.
          navigate('/workout', { replace: true });
          return;
        }
        if (w.status === 'ended' || w.status === 'done') {
          setPhase('ended');
          // GET returns the persisted workout without the transient end payload;
          // recover the summary from timestamps and the setlog list.
          const durationSeconds = w.duration_seconds ?? (
            w.ended_at
              ? Math.floor((new Date(w.ended_at).getTime() - new Date(w.started_at).getTime()) / 1000)
              : undefined
          );
          setResultWorkout({
            ...w,
            duration_seconds: durationSeconds,
            setlog_count: w.setlog_count ?? (Array.isArray(w.setlogs) ? w.setlogs.length : undefined),
          });
        } else {
          setPhase('active');
          // Calculate elapsed from started_at
          const start = new Date(w.started_at).getTime();
          const now = Date.now();
          setElapsed(Math.floor((now - start) / 1000));
        }
        // Fetch setlogs if active
        if (w.status === 'active') {
          return api.get(`/workouts/${id}/setlogs`);
        }
      })
      .then((res) => {
        if (res) {
          setSetlogs(Array.isArray(res.data) ? res.data : []);
        }
      })
      .catch((err) => {
        setError(err.response?.data?.message || '운동 정보를 불러오지 못했습니다');
      })
      .finally(() => setLoading(false));
  }, [id]);

  // ---- Timer for active workouts ----
  useEffect(() => {
    if (phase !== 'active' || !workout) return;
    const start = new Date(workout.started_at).getTime();
    setElapsed(Math.floor((Date.now() - start) / 1000));

    timerRef.current = setInterval(() => {
      setElapsed(Math.floor((Date.now() - start) / 1000));
    }, 1000);

    return () => {
      if (timerRef.current) clearInterval(timerRef.current);
    };
  }, [phase, workout]);

  // ---- Handlers ----
  const formatElapsed = (totalSeconds: number) => {
    const h = Math.floor(totalSeconds / 3600);
    const m = Math.floor((totalSeconds % 3600) / 60);
    const s = totalSeconds % 60;
    if (h > 0) return `${h}:${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
    return `${m}:${String(s).padStart(2, '0')}`;
  };

  const formatDuration = (seconds?: number) => {
    if (!seconds) return '0분';
    const m = Math.floor(seconds / 60);
    const s = seconds % 60;
    return `${m}분 ${s}초`;
  };

  const handleStartWorkout = async (e: FormEvent) => {
    e.preventDefault();
    setCreating(true);
    setError('');
    try {
      const payload: Record<string, unknown> = {};
      if (partyId) payload.party_id = partyId;
      if (notes) payload.notes = notes;
      const { data } = await api.post('/workouts/', payload);
      navigate(`/workout/${data.id}`);
      clearDraft();
    } catch (err: any) {
      const detail = err.response?.data?.detail;
      // 409: an active workout already exists — resume it instead of erroring.
      if (err.response?.status === 409 && detail?.active_workout_id) {
        navigate(`/workout/${detail.active_workout_id}`);
        return;
      }
      setError(
        (typeof detail === 'string' ? detail : detail?.message)
        || err.response?.data?.message || err.message || '운동 시작에 실패했습니다',
      );
    } finally {
      setCreating(false);
    }
  };

  const handleAddSetlog = async (e: FormEvent) => {
    e.preventDefault();
    if (!setlogContent.trim() && !setlogFile) return;
    setSubmitting(true);
    try {
      // Upload the selected image first, then reference the returned key.
      let filePath: string | undefined;
      if (setlogFile) {
        const form = new FormData();
        form.append('file', setlogFile);
        const uploaded = await api.post('/media', form, {
          headers: { 'Content-Type': 'multipart/form-data' },
        });
        filePath = uploaded.data.key;
      }
      const { data } = await api.post(`/workouts/${id}/setlogs`, {
        type: setlogType,
        content: setlogContent,
        file_path: filePath,
      });
      setSetlogs((prev) => [...prev, data]);
      setSetlogContent('');
      setSetlogFile(null);
      if (fileInputRef.current) fileInputRef.current.value = '';
    } catch (err: any) {
      const detail = err.response?.data?.detail;
      alert((typeof detail === 'string' ? detail : detail?.message) || '세트로그 등록에 실패했습니다');
    } finally {
      setSubmitting(false);
    }
  };

  const handleCancelWorkout = async () => {
    if (!id) return;
    if (!window.confirm('운동을 취소하시겠습니까? 성장 보상은 지급되지 않습니다.')) return;
    try {
      await api.post(`/workouts/${id}/cancel`);
      if (timerRef.current) clearInterval(timerRef.current);
      navigate('/workout', { replace: true });
    } catch (err: any) {
      alert(err.response?.data?.detail || '운동 취소에 실패했습니다');
    }
  };

  const handleEndWorkout = async () => {
    if (!id) return;
    setEnding(true);
    try {
      const { data } = await api.post(`/workouts/${id}/end`);
      if (timerRef.current) clearInterval(timerRef.current);
      setResultWorkout(data);
      setPhase('ended');
    } catch (err: any) {
      alert(err.response?.data?.message || '운동 종료에 실패했습니다');
    } finally {
      setEnding(false);
    }
  };

  const getSetlogIcon = (type: string) => {
    switch (type) {
      case 'start': return '▶️';
      case 'mid': return '📸';
      case 'end': return '✅';
      default: return '📝';
    }
  };

  const getSetlogLabel = (type: string) => {
    switch (type) {
      case 'start': return '시작';
      case 'mid': return '중간';
      case 'end': return '종료';
      default: return type;
    }
  };

  // ---- Loading ----
  if (loading) {
    return (
      <div style={{ textAlign: 'center', padding: '80px 20px', color: 'var(--text-secondary)' }}>
        ⏳ 운동 불러오는 중...
      </div>
    );
  }

  // ---- Error ----
  if (error) {
    return (
      <div style={{ maxWidth: 800, margin: '0 auto', textAlign: 'center', padding: '80px 20px' }}>
        <div style={{
          background: 'rgba(244,67,54,0.15)',
          color: 'var(--danger)',
          padding: '16px 20px',
          borderRadius: '10px',
          marginBottom: '20px',
        }}>
          {error}
        </div>
      </div>
    );
  }

  // ====================================================================
  // STATE 1: BEFORE START (idle)
  // ====================================================================
  if (phase === 'idle') {
    return (
      <div style={{ maxWidth: 500, margin: '0 auto', padding: '40px 20px' }}>
        <div style={{ position: 'relative', marginBottom: '40px' }}>
          <div style={{ position: 'absolute', top: 0, right: 0 }}>
            <StreakBadge />
          </div>
          <div style={{ textAlign: 'center' }}>
            <div style={{ fontSize: '3rem', marginBottom: '12px' }}>🔥</div>
            <h1 style={{ fontSize: '1.6rem', fontWeight: 700, marginBottom: '6px' }}>
              오늘의 운동
            </h1>
            <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>
              운동을 시작하고 세트로그를 기록하세요
            </p>
          </div>
        </div>

        <form onSubmit={handleStartWorkout} style={{
          background: 'var(--bg-card)',
          borderRadius: '14px',
          border: '1px solid var(--border)',
          padding: '28px',
          display: 'flex',
          flexDirection: 'column',
          gap: '20px',
        }}>
          {error && (
            <div style={{
              background: 'rgba(244,67,54,0.15)',
              color: 'var(--danger)',
              padding: '10px 14px',
              borderRadius: '8px',
              fontSize: '0.9rem',
            }}>
              {error}
            </div>
          )}

          <div>
            <label style={labelStyle}>파티 ID (선택)</label>
            <input
              type="text"
              value={partyId}
              onChange={(e) => { setPartyId(e.target.value); updateDraft({ partyId: e.target.value }); }}
              placeholder="파티가 있다면 ID를 입력하세요"
              style={inputStyle}
            />
          </div>

          <div>
            <label style={labelStyle}>운동 메모 (선택)</label>
            <textarea
              value={notes}
              onChange={(e) => { setNotes(e.target.value); updateDraft({ notes: e.target.value }); }}
              placeholder="오늘의 운동 목표나 메모..."
              rows={3}
              style={{ ...inputStyle, resize: 'vertical', minHeight: '80px' }}
            />
          </div>

          <button
            type="submit"
            disabled={creating}
            style={{
              width: '100%',
              padding: '16px',
              background: creating ? '#993333' : 'var(--accent)',
              border: 'none',
              borderRadius: '12px',
              color: '#fff',
              fontWeight: 700,
              fontSize: '1.1rem',
              cursor: creating ? 'not-allowed' : 'pointer',
              transition: 'all 0.2s',
            }}
          >
            {creating ? '시작 중...' : '🔥 운동 시작하기'}
          </button>
        </form>
      </div>
    );
  }

  // ====================================================================
  // STATE 2: ACTIVE WORKOUT
  // ====================================================================
  if (phase === 'active' && workout) {
    return (
      <div style={{
        maxWidth: 800,
        margin: '0 auto',
        display: 'flex',
        flexDirection: 'column',
        height: 'calc(100vh - 80px)',
      }}>
        {/* Timer bar */}
        <div style={{
          textAlign: 'center',
          padding: '20px 0',
          borderBottom: '1px solid var(--border)',
          flexShrink: 0,
        }}>
          <div style={{ fontSize: '0.85rem', color: 'var(--text-secondary)', marginBottom: '4px' }}>
            🔥 운동 진행 중
          </div>
          <div style={{
            fontSize: '2.5rem',
            fontWeight: 700,
            fontFamily: 'monospace',
            color: 'var(--accent-glow)',
            letterSpacing: '2px',
          }}>
            {formatElapsed(elapsed)}
          </div>
          <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', marginTop: '4px' }}>
            세트로그 {setlogs.length}개
          </div>
        </div>

        {/* Setlogs list - scrollable */}
        <div style={{
          flex: 1,
          overflowY: 'auto',
          padding: '16px 0',
          display: 'flex',
          flexDirection: 'column',
          gap: '8px',
        }}>
          {setlogs.length === 0 && (
            <div style={{
              textAlign: 'center',
              padding: '40px 20px',
              color: 'var(--text-secondary)',
              fontSize: '0.9rem',
            }}>
              아직 기록이 없습니다.<br />첫 세트로그를 등록하세요!
            </div>
          )}
          {setlogs.map((sl) => (
            <div
              key={sl.id}
              style={{
                background: 'var(--bg-card)',
                borderRadius: '10px',
                border: '1px solid var(--border)',
                padding: '12px 16px',
                display: 'flex',
                gap: '10px',
                alignItems: 'flex-start',
              }}
            >
              <span style={{ fontSize: '1.2rem', marginTop: '1px' }}>
                {getSetlogIcon(sl.type)}
              </span>
              <div style={{ flex: 1 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '4px' }}>
                  <span style={{
                    fontSize: '0.7rem',
                    padding: '1px 6px',
                    borderRadius: '4px',
                    background: 'var(--bg-secondary)',
                    color: 'var(--text-secondary)',
                  }}>
                    {getSetlogLabel(sl.type)}
                  </span>
                  <span style={{ fontSize: '0.7rem', color: 'var(--text-secondary)' }}>
                    {new Date(sl.created_at).toLocaleTimeString('ko-KR', { hour: '2-digit', minute: '2-digit' })}
                  </span>
                </div>
                {sl.content && (
                  <div style={{
                    fontSize: '0.9rem',
                    color: 'var(--text-primary)',
                    whiteSpace: 'pre-wrap',
                    lineHeight: 1.5,
                  }}>
                    {sl.content}
                  </div>
                )}
                {sl.file_path && <SetlogMedia path={sl.file_path} />}
              </div>
            </div>
          ))}
        </div>

        {/* Setlog form */}
        <form
          onSubmit={handleAddSetlog}
          style={{
            borderTop: '1px solid var(--border)',
            padding: '12px 0',
            flexShrink: 0,
            display: 'flex',
            flexDirection: 'column',
            gap: '10px',
          }}
        >
          {/* Type selector */}
          <div style={{ display: 'flex', gap: '8px' }}>
            {(['start', 'mid', 'end'] as const).map((t) => (
              <button
                key={t}
                type="button"
                onClick={() => setSetlogType(t)}
                style={{
                  flex: 1,
                  padding: '8px 6px',
                  background: setlogType === t ? 'var(--accent)' : 'var(--bg-card)',
                  border: setlogType === t ? '1px solid var(--accent)' : '1px solid var(--border)',
                  borderRadius: '8px',
                  color: setlogType === t ? '#fff' : 'var(--text-secondary)',
                  fontWeight: setlogType === t ? 700 : 400,
                  fontSize: '0.8rem',
                  cursor: 'pointer',
                  transition: 'all 0.15s',
                }}
              >
                {getSetlogIcon(t)} {getSetlogLabel(t)}
              </button>
            ))}
          </div>

          {/* Content textarea */}
          <textarea
            value={setlogContent}
            onChange={(e) => setSetlogContent(e.target.value)}
            placeholder={`${getSetlogLabel(setlogType)} 기록을 입력하세요...`}
            rows={2}
            style={{
              ...inputStyle,
              resize: 'none',
              minHeight: '56px',
            }}
          />

          {/* File input + submit row */}
          <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
            <input
              ref={fileInputRef}
              type="file"
              accept="image/*"
              onChange={(e) => setSetlogFile(e.target.files?.[0] ?? null)}
              style={{ display: 'none' }}
              id="setlog-file-input"
            />
            <button
              type="button"
              onClick={() => fileInputRef.current?.click()}
              style={{
                padding: '10px 14px',
                background: 'var(--bg-card)',
                border: '1px solid var(--border)',
                borderRadius: '8px',
                color: setlogFile ? 'var(--accent-glow)' : 'var(--text-secondary)',
                fontSize: '0.85rem',
                cursor: 'pointer',
                whiteSpace: 'nowrap',
              }}
            >
              {setlogFile ? `📎 ${setlogFile.name.slice(0, 12)}...` : '📎 사진'}
            </button>
            <button
              type="submit"
              disabled={submitting || (!setlogContent.trim() && !setlogFile)}
              style={{
                flex: 1,
                padding: '10px 16px',
                background: submitting || (!setlogContent.trim() && !setlogFile)
                  ? '#555'
                  : 'var(--accent)',
                border: 'none',
                borderRadius: '8px',
                color: '#fff',
                fontWeight: 700,
                fontSize: '0.9rem',
                cursor: submitting || (!setlogContent.trim() && !setlogFile) ? 'not-allowed' : 'pointer',
                transition: 'all 0.15s',
              }}
            >
              {submitting ? '등록 중...' : '등록'}
            </button>
          </div>
        </form>

        {/* End workout button */}
        <div style={{ paddingBottom: '12px', flexShrink: 0 }}>
          <button
            onClick={handleEndWorkout}
            disabled={ending}
            style={{
              width: '100%',
              padding: '16px',
              background: ending
                ? 'linear-gradient(135deg, #993333, #663333)'
                : 'linear-gradient(135deg, var(--accent), #cc0000)',
              border: 'none',
              borderRadius: '14px',
              color: '#fff',
              fontWeight: 700,
              fontSize: '1.2rem',
              cursor: ending ? 'not-allowed' : 'pointer',
              transition: 'all 0.2s',
              boxShadow: ending ? 'none' : '0 4px 20px rgba(255,61,61,0.25)',
            }}
          >
            {ending ? '종료 중...' : '🔥 운동 종료'}
          </button>
          <button
            onClick={handleCancelWorkout}
            disabled={ending}
            style={{
              width: '100%',
              marginTop: '8px',
              padding: '10px',
              background: 'transparent',
              border: 'none',
              color: 'var(--text-secondary)',
              fontSize: '0.85rem',
              cursor: ending ? 'not-allowed' : 'pointer',
              textDecoration: 'underline',
            }}
          >
            운동 취소
          </button>
        </div>
      </div>
    );
  }

  // ====================================================================
  // STATE 3: WORKOUT ENDED (results)
  // ====================================================================
  if (phase === 'ended' && resultWorkout) {
    const rw = resultWorkout;
    const hasBreakthrough = rw.breakthroughs && rw.breakthroughs.length > 0;

    return (
      <div style={{ maxWidth: 600, margin: '0 auto', padding: '24px 20px' }}>
        {/* Celebration header */}
        <div style={{ textAlign: 'center', marginBottom: '28px' }}>
          <div style={{ fontSize: '3rem', marginBottom: '8px' }}>
            {hasBreakthrough ? '🏆' : '💪'}
          </div>
          <h1 style={{
            fontSize: '1.8rem',
            fontWeight: 700,
            color: hasBreakthrough ? 'var(--accent-glow)' : 'var(--text-primary)',
            marginBottom: '4px',
          }}>
            운동 완료!
          </h1>
          {hasBreakthrough ? (
            <p style={{ color: 'var(--accent-glow)', fontSize: '1rem', fontWeight: 600 }}>
              🔥 돌파 성공!
            </p>
          ) : (
            <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>
              ⚡ 잠재력 누적
            </p>
          )}
        </div>

        {/* Stats card */}
        <div style={{
          background: 'var(--bg-card)',
          borderRadius: '16px',
          border: '1px solid var(--border)',
          padding: '24px',
          marginBottom: '20px',
        }}>
          <h3 style={{ fontSize: '1rem', fontWeight: 600, marginBottom: '16px', color: 'var(--text-secondary)' }}>
            📊 운동 요약
          </h3>
          <div style={{
            display: 'flex',
            justifyContent: 'center',
            gap: '32px',
          }}>
            <div style={{ textAlign: 'center' }}>
              <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', marginBottom: '4px' }}>
                총 운동 시간
              </div>
              <div style={{ fontSize: '1.3rem', fontWeight: 700 }}>
                {formatDuration(rw.duration_seconds)}
              </div>
            </div>
            <div style={{ textAlign: 'center' }}>
              <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', marginBottom: '4px' }}>
                세트로그
              </div>
              <div style={{ fontSize: '1.3rem', fontWeight: 700 }}>
                {rw.setlog_count ?? 0}개
              </div>
            </div>
          </div>
        </div>

        {/* Body stats card */}
        {rw.body_stats && rw.body_stats.length > 0 && (
          <div style={{
            background: 'var(--bg-card)',
            borderRadius: '16px',
            border: '1px solid var(--border)',
            padding: '24px',
            marginBottom: '24px',
          }}>
            <h3 style={{ fontSize: '1rem', fontWeight: 600, marginBottom: '16px', color: 'var(--text-secondary)' }}>
              🎯 신체 부위 레벨
            </h3>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
              {rw.body_stats.map((stat) => {
                const breakthrough = rw.breakthroughs?.find((b) => b.part === stat.part);
                const isNew = !!breakthrough;
                const pct = Math.min((stat.potential / 100) * 100, 100);
                const maxLevel = 10;

                return (
                  <div key={stat.part}>
                    <div style={{
                      display: 'flex',
                      justifyContent: 'space-between',
                      alignItems: 'center',
                      marginBottom: '4px',
                    }}>
                      <span style={{
                        fontSize: '0.9rem',
                        fontWeight: 500,
                        color: isNew ? 'var(--accent-glow)' : 'var(--text-primary)',
                      }}>
                        {isNew && '✨ '}
                        {PART_LABELS[stat.part] || stat.part}
                      </span>
                      <span style={{
                        fontSize: '0.9rem',
                        fontWeight: 700,
                        color: isNew ? 'var(--accent-glow)' : 'var(--text-primary)',
                      }}>
                        Lv.{stat.level}
                        {isNew && breakthrough && (
                          <span style={{ fontSize: '0.7rem', marginLeft: '6px' }}>
                            ({breakthrough.old_level} → {breakthrough.new_level})
                          </span>
                        )}
                      </span>
                    </div>
                    {/* Level dots */}
                    <div style={{ display: 'flex', gap: '2px', marginBottom: '3px' }}>
                      {Array.from({ length: maxLevel }).map((_, i) => (
                        <div
                          key={i}
                          style={{
                            flex: 1,
                            height: '3px',
                            borderRadius: '1px',
                            background: i < stat.level
                              ? isNew ? 'var(--accent-glow)' : 'var(--accent)'
                              : 'var(--border)',
                          }}
                        />
                      ))}
                    </div>
                    {/* Potential bar */}
                    <div style={{
                      width: '100%',
                      height: '4px',
                      background: 'var(--border)',
                      borderRadius: '2px',
                      overflow: 'hidden',
                    }}>
                      <div style={{
                        width: `${pct}%`,
                        height: '100%',
                        background: isNew
                          ? 'linear-gradient(90deg, var(--accent), var(--accent-glow))'
                          : 'var(--text-secondary)',
                        borderRadius: '2px',
                        transition: 'width 0.5s',
                      }} />
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        )}

        {/* Breakthroughs */}
        {hasBreakthrough && rw.breakthroughs && (
          <div style={{
            background: 'rgba(255,61,61,0.1)',
            borderRadius: '14px',
            border: '1px solid var(--accent)',
            padding: '18px',
            marginBottom: '24px',
            textAlign: 'center',
          }}>
            <div style={{ fontSize: '1.5rem', marginBottom: '6px' }}>🏆</div>
            <div style={{ fontWeight: 700, color: 'var(--accent-glow)', fontSize: '1.05rem', marginBottom: '6px' }}>
              돌파 성공!
            </div>
            <div style={{ color: 'var(--text-secondary)', fontSize: '0.85rem' }}>
              {rw.breakthroughs.map((b) => (
                <span key={b.part}>
                  {PART_LABELS[b.part] || b.part} Lv.{b.old_level} → Lv.{b.new_level}{' '}
                </span>
              ))}
            </div>
            <div style={{ color: 'var(--text-secondary)', fontSize: '0.8rem', marginTop: '4px' }}>
              새로운 단계에 도달했습니다!
            </div>
          </div>
        )}

        {/* Back button */}
        <button
          onClick={() => navigate(`/party/${rw.party_id}`)}
          style={{
            width: '100%',
            padding: '16px',
            background: 'var(--bg-card)',
            border: '1px solid var(--accent)',
            borderRadius: '14px',
            color: 'var(--accent)',
            fontWeight: 700,
            fontSize: '1rem',
            cursor: 'pointer',
            transition: 'all 0.2s',
          }}
        >
          🏠 파티로 돌아가기
        </button>

        {/* Also: start new workout */}
        <button
          onClick={() => {
            setPhase('idle');
            setResultWorkout(null);
            setWorkout(null);
            setSetlogs([]);
            setPartyId(rw.party_id);
          }}
          style={{
            width: '100%',
            marginTop: '12px',
            padding: '14px',
            background: 'var(--accent)',
            border: 'none',
            borderRadius: '14px',
            color: '#fff',
            fontWeight: 700,
            fontSize: '1rem',
            cursor: 'pointer',
          }}
        >
          🔥 새 운동 시작
        </button>
      </div>
    );
  }

  return null;
}

// ---- Private media ----
// Media is owner-only and behind bearer auth, so a plain <img src> can't load
// it; fetch the bytes through the API client and render an object URL.
function SetlogMedia({ path }: { path: string }) {
  const [url, setUrl] = useState('');
  const [failed, setFailed] = useState(false);

  useEffect(() => {
    let objectUrl = '';
    let cancelled = false;
    api.get(`/media/${path}`, { responseType: 'blob' })
      .then((res) => {
        if (cancelled) return;
        objectUrl = URL.createObjectURL(res.data);
        setUrl(objectUrl);
      })
      .catch(() => { if (!cancelled) setFailed(true); });
    return () => {
      cancelled = true;
      if (objectUrl) URL.revokeObjectURL(objectUrl);
    };
  }, [path]);

  if (failed) {
    return (
      <div style={{
        marginTop: '6px', padding: '12px', background: 'var(--bg-secondary)',
        borderRadius: '6px', border: '1px dashed var(--border)',
        textAlign: 'center', color: 'var(--text-secondary)', fontSize: '0.8rem',
      }}>
        📎 사진을 불러올 수 없습니다
      </div>
    );
  }
  if (!url) {
    return (
      <div style={{
        marginTop: '6px', padding: '16px', background: 'var(--bg-secondary)',
        borderRadius: '6px', textAlign: 'center', color: 'var(--text-secondary)',
        fontSize: '0.8rem',
      }}>
        📎 사진 불러오는 중...
      </div>
    );
  }
  return (
    <img
      src={url}
      alt="세트로그 첨부 사진"
      style={{
        marginTop: '6px', maxWidth: '100%', borderRadius: '6px',
        border: '1px solid var(--border)', display: 'block',
      }}
    />
  );
}

// ---- Styles ----

const labelStyle: React.CSSProperties = {
  display: 'block',
  marginBottom: '6px',
  fontSize: '0.85rem',
  color: 'var(--text-secondary)',
};

const inputStyle: React.CSSProperties = {
  width: '100%',
  padding: '12px 14px',
  background: 'var(--bg-secondary)',
  border: '1px solid var(--border)',
  borderRadius: '8px',
  color: 'var(--text-primary)',
  fontSize: '0.95rem',
  outline: 'none',
  fontFamily: 'inherit',
};

export default WorkoutPage;
