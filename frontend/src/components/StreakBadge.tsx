import { useEffect, useState } from 'react';
import api from '../api';

interface StreakData {
  current_streak: number;
  longest_streak: number;
  current_streak_start: string | null;
  longest_streak_start: string | null;
  longest_streak_end: string | null;
}

function StreakBadge() {
  const [streak, setStreak] = useState<StreakData | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.get('/me/streak')
      .then(({ data }) => setStreak(data))
      .catch(() => setStreak(null))
      .finally(() => setLoading(false));
  }, []);

  if (loading) {
    return (
      <div style={badgeStyle}>
        <span style={{ fontSize: '0.7rem', color: 'var(--text-secondary)' }}>…</span>
      </div>
    );
  }

  if (!streak) return null;

  const { current_streak, longest_streak } = streak;
  const showLongest = current_streak < longest_streak;

  return (
    <div
      style={badgeStyle}
      title={showLongest ? `최장 연속 운동: ${longest_streak}일` : `연속 운동: ${current_streak}일`}
    >
      <span style={{ fontSize: '0.85rem', lineHeight: 1 }}>🔥</span>
      <span style={{
        fontWeight: 700,
        fontSize: '0.8rem',
        color: 'var(--text-primary)',
        lineHeight: 1,
      }}>
        {current_streak}
      </span>
      {showLongest && (
        <span style={{
          fontSize: '0.65rem',
          color: 'var(--text-secondary)',
          lineHeight: 1,
        }}>
          최장: {longest_streak}
        </span>
      )}
    </div>
  );
}

const badgeStyle: React.CSSProperties = {
  display: 'inline-flex',
  alignItems: 'center',
  gap: '4px',
  padding: '4px 10px',
  background: 'var(--bg-card)',
  border: '1px solid var(--border)',
  borderRadius: '20px',
  flexShrink: 0,
};

export default StreakBadge;
