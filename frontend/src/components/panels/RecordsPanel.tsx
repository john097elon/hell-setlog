import { useEffect, useState } from 'react';
import api from '../../api';

interface WorkoutRecord {
  id: string | number;
  started_at: string;
  ended_at?: string;
  status: string;
  notes?: string;
  setlogs?: Array<unknown>;
}

interface StreakData {
  current_streak: number;
  longest_streak: number;
}

function RecordsPanel({ refreshKey = 0 }: { refreshKey?: number }) {
  const [workouts, setWorkouts] = useState<WorkoutRecord[]>([]);
  const [streak, setStreak] = useState<StreakData>({ current_streak: 0, longest_streak: 0 });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    Promise.all([
      api.get('/workouts/').catch(() => ({ data: [] })),
      api.get('/streak').catch(() => ({ data: { current_streak: 0, longest_streak: 0 } })),
    ]).then(([wRes, sRes]) => {
      const list: WorkoutRecord[] = Array.isArray(wRes.data) ? wRes.data : wRes.data.workouts ?? [];
      // Only ended workouts, most recent first
      setWorkouts(list.filter(w => w.status !== 'active'));
      setStreak(sRes.data ?? { current_streak: 0, longest_streak: 0 });
    }).finally(() => setLoading(false));
  }, [refreshKey]);

  const today = new Date();
  const year = today.getFullYear();
  const month = today.getMonth();
  const firstDay = new Date(year, month, 1).getDay();
  const daysInMonth = new Date(year, month + 1, 0).getDate();

  const workoutDays = new Set(
    workouts
      .filter(w => {
        const d = new Date(w.started_at);
        return d.getFullYear() === year && d.getMonth() === month;
      })
      .map(w => new Date(w.started_at).getDate())
  );

  const MONTHS = ['1월','2월','3월','4월','5월','6월','7월','8월','9월','10월','11월','12월'];
  const DAYS = ['일','월','화','수','목','금','토'];

  function formatDate(iso: string): string {
    const d = new Date(iso);
    const diffDays = Math.floor((today.getTime() - d.getTime()) / 86400000);
    if (diffDays === 0) return '오늘';
    if (diffDays === 1) return '어제';
    if (diffDays < 7) return `${diffDays}일 전`;
    return `${d.getMonth() + 1}/${d.getDate()}`;
  }

  function formatDuration(start: string, end?: string): string {
    if (!end) return '-';
    const s = Math.floor((new Date(end).getTime() - new Date(start).getTime()) / 1000);
    const m = Math.floor(s / 60);
    return `${m}분`;
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%', overflowY: 'auto' }}>

      {/* Header */}
      <div style={{ padding: '12px 14px 6px', flexShrink: 0 }}>
        <span style={sectionLabel}>기록</span>
      </div>

      {/* Streak card */}
      <div style={{ margin: '0 10px 8px', padding: '12px 14px', background: 'var(--color-bg-surface)', borderRadius: '10px', border: '1px solid var(--color-border-subtle)' }}>
        <div style={{ fontSize: '0.65rem', color: 'var(--color-text-secondary)', textTransform: 'uppercase', letterSpacing: '0.1em', marginBottom: '8px' }}>
          스트릭
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <div>
            <div style={{ fontSize: '1.7rem', fontWeight: 800, color: '#ff3d3d', lineHeight: 1 }}>
              {streak.current_streak}
            </div>
            <div style={{ fontSize: '0.65rem', color: 'var(--color-text-secondary)', marginTop: '2px' }}>🔥 현재</div>
          </div>
          <div style={{ width: '1px', height: '32px', background: 'var(--color-border-subtle)' }} />
          <div>
            <div style={{ fontSize: '1.7rem', fontWeight: 800, color: '#555', lineHeight: 1 }}>
              {streak.longest_streak}
            </div>
            <div style={{ fontSize: '0.65rem', color: 'var(--color-text-secondary)', marginTop: '2px' }}>🏆 최장</div>
          </div>
        </div>
      </div>

      {/* Mini Calendar */}
      <div style={{ margin: '0 10px 8px', padding: '12px 14px', background: 'var(--color-bg-surface)', borderRadius: '10px', border: '1px solid var(--color-border-subtle)' }}>
        <div style={{ fontSize: '0.78rem', fontWeight: 600, marginBottom: '8px' }}>
          {year}년 {MONTHS[month]}
        </div>
        {/* Day headers */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: '1px', marginBottom: '3px' }}>
          {DAYS.map((d, i) => (
            <div key={d} style={{
              textAlign: 'center',
              fontSize: '0.6rem',
              color: i === 0 ? '#c0392b' : i === 6 ? '#2980b9' : '#444',
              fontWeight: 600,
            }}>
              {d}
            </div>
          ))}
        </div>
        {/* Day cells */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: '1px' }}>
          {Array.from({ length: firstDay }).map((_, i) => (
            <div key={`e${i}`} />
          ))}
          {Array.from({ length: daysInMonth }).map((_, i) => {
            const day = i + 1;
            const isToday = day === today.getDate();
            const hasDot = workoutDays.has(day);
            const isPast = day <= today.getDate();
            return (
              <div key={day} style={{ textAlign: 'center', padding: '2px 0' }}>
                <div style={{
                  display: 'inline-flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                  width: '20px',
                  borderRadius: '4px',
                  background: isToday ? 'rgba(255,61,61,0.15)' : 'transparent',
                  padding: '1px',
                }}>
                  <span style={{
                    fontSize: '0.65rem',
                    fontWeight: isToday ? 700 : 400,
                    color: isToday ? '#ff3d3d' : isPast ? 'var(--color-text-secondary)' : '#2a2a2a',
                    lineHeight: 1.2,
                  }}>
                    {day}
                  </span>
                  <div style={{
                    width: '4px', height: '4px',
                    borderRadius: '50%',
                    background: hasDot ? '#ff3d3d' : 'transparent',
                    marginTop: '1px',
                  }} />
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Recent workouts */}
      <div style={{ padding: '0 10px', flex: 1 }}>
        <div style={{ fontSize: '0.65rem', color: 'var(--color-text-secondary)', textTransform: 'uppercase', letterSpacing: '0.1em', marginBottom: '6px', padding: '0 2px' }}>
          최근 운동
        </div>

        {loading ? (
          <div style={{ fontSize: '0.75rem', color: '#444', padding: '6px 2px' }}>로딩 중…</div>
        ) : workouts.length === 0 ? (
          <div style={{ padding: '20px 8px', textAlign: 'center', fontSize: '0.82rem', color: '#444', lineHeight: 1.7 }}>
            아직 운동 기록이 없어요<br />
            <span style={{ fontSize: '1.2rem' }}>💪</span><br />
            첫 운동을 시작해보세요!
          </div>
        ) : (
          workouts.slice(0, 12).map(w => {
            const count = Array.isArray(w.setlogs) ? w.setlogs.length : 0;
            return (
              <div
                key={w.id}
                style={{
                  padding: '9px 10px',
                  background: 'var(--color-bg-surface)',
                  borderRadius: '8px',
                  border: '1px solid var(--color-border-subtle)',
                  marginBottom: '5px',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '9px',
                }}
              >
                <div style={{
                  width: '30px', height: '30px',
                  borderRadius: '6px',
                  background: 'rgba(255,61,61,0.08)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  fontSize: '0.9rem',
                  flexShrink: 0,
                }}>
                  💪
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <span style={{ fontSize: '0.8rem', fontWeight: 600 }}>
                      {formatDate(w.started_at)}
                    </span>
                    <span style={{ fontSize: '0.7rem', color: 'var(--color-text-secondary)' }}>
                      {formatDuration(w.started_at, w.ended_at)}
                    </span>
                  </div>
                  <div style={{ fontSize: '0.68rem', color: '#555', marginTop: '1px' }}>
                    세트로그 {count}개
                    {w.notes && (
                      <span style={{ marginLeft: '6px', color: '#444', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                        · {w.notes.slice(0, 16)}{w.notes.length > 16 ? '…' : ''}
                      </span>
                    )}
                  </div>
                </div>
              </div>
            );
          })
        )}
      </div>

      <div style={{ height: '16px', flexShrink: 0 }} />
    </div>
  );
}

const sectionLabel: React.CSSProperties = {
  fontSize: '0.66rem',
  fontWeight: 700,
  color: 'var(--color-text-secondary)',
  letterSpacing: '0.1em',
  textTransform: 'uppercase',
};

export default RecordsPanel;
