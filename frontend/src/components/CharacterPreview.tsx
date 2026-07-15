import { useState } from 'react';

interface BodyPart {
  part: string;
  level: number;
  potential: number;
}

interface CharacterPreviewProps {
  username: string;
  avatar_url?: string;
  body_stats?: BodyPart[];
  compact?: boolean;
  onClick?: () => void;
}

const PART_LABELS: Record<string, string> = {
  chest: '가슴',
  back: '등',
  shoulders: '어깨',
  arms: '팔',
  abs: '복근',
  legs: '하체',
  cardio: '유산소',
};

const PART_EMOJI: Record<string, string> = {
  chest: '🦾',
  back: '🔙',
  shoulders: '💪',
  arms: '💪',
  abs: '🏋️',
  legs: '🦵',
  cardio: '🫀',
};

function CharacterPreview({ username, avatar_url: _avatarUrl, body_stats, compact = false, onClick }: CharacterPreviewProps) {
  const [expanded, setExpanded] = useState(false);
  const [imgError, setImgError] = useState(false);
  const initial = username?.charAt(0)?.toUpperCase() || '?';

  const maxLevel = 10;
  const totalLevel = body_stats?.reduce((sum, s) => sum + s.level, 0) ?? 0;
  const totalPotential = body_stats?.reduce((sum, s) => sum + s.potential, 0) ?? 0;

  const hasStats = body_stats && body_stats.length > 0;

  return (
    <div
      onClick={() => {
        if (onClick) onClick();
        if (hasStats) setExpanded(!expanded);
      }}
      style={{
        background: 'var(--bg-card)',
        borderRadius: compact ? '8px' : '12px',
        border: '1px solid var(--border)',
        padding: compact ? '10px 12px' : '16px',
        cursor: hasStats || onClick ? 'pointer' : 'default',
        display: 'inline-flex',
        flexDirection: 'column',
        alignItems: 'center',
        gap: compact ? '6px' : '10px',
        minWidth: compact ? '90px' : '140px',
        transition: 'border-color 0.2s, box-shadow 0.2s',
      }}
      onMouseEnter={(e) => {
        (e.currentTarget as HTMLDivElement).style.borderColor = 'var(--accent)';
        (e.currentTarget as HTMLDivElement).style.boxShadow = '0 0 12px rgba(255,61,61,0.15)';
      }}
      onMouseLeave={(e) => {
        (e.currentTarget as HTMLDivElement).style.borderColor = 'var(--border)';
        (e.currentTarget as HTMLDivElement).style.boxShadow = 'none';
      }}
    >
      {/* Avatar circle */}
      <div style={{
        width: compact ? '40px' : '56px',
        height: compact ? '40px' : '56px',
        borderRadius: '50%',
        background: 'linear-gradient(135deg, var(--accent), #cc0000)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        fontSize: compact ? '1rem' : '1.4rem',
        fontWeight: 700,
        color: '#fff',
        flexShrink: 0,
        overflow: 'hidden',
      }}>
        {_avatarUrl && !imgError ? (
          <img
            src={_avatarUrl}
            alt={username}
            onError={() => setImgError(true)}
            style={{
              width: '100%',
              height: '100%',
              objectFit: 'cover',
            }}
          />
        ) : (
          initial
        )}
      </div>

      {/* Username */}
      <span style={{
        fontSize: compact ? '0.8rem' : '0.95rem',
        fontWeight: 600,
        color: 'var(--text-primary)',
        textAlign: 'center',
        lineHeight: 1.2,
      }}>
        {username}
      </span>

      {/* Summary stats */}
      {hasStats && !expanded && (
        <div style={{
          display: 'flex',
          gap: compact ? '4px' : '8px',
          fontSize: compact ? '0.65rem' : '0.75rem',
          color: 'var(--text-secondary)',
        }}>
          <span>Lv.{totalLevel}</span>
          <span style={{ color: 'var(--accent-glow)' }}>⚡{totalPotential}</span>
        </div>
      )}

      {/* Expanded body stats */}
      {hasStats && expanded && (
        <div style={{
          width: '100%',
          display: 'flex',
          flexDirection: 'column',
          gap: '6px',
          marginTop: '4px',
        }}>
          {body_stats.map((stat) => {
            const pct = Math.min((stat.potential / 100) * 100, 100);
            const isNearBreakthrough = stat.potential >= 90;
            return (
              <div key={stat.part} style={{ width: '100%' }}>
                <div style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                  marginBottom: '2px',
                }}>
                  <span style={{
                    fontSize: '0.7rem',
                    color: 'var(--text-secondary)',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '3px',
                  }}>
                    <span>{PART_EMOJI[stat.part] || '⚪'}</span>
                    <span>{PART_LABELS[stat.part] || stat.part}</span>
                  </span>
                  <span style={{
                    fontSize: '0.7rem',
                    fontWeight: 700,
                    color: isNearBreakthrough ? 'var(--accent-glow)' : 'var(--text-primary)',
                  }}>
                    Lv.{stat.level}
                  </span>
                </div>
                {/* Level dots */}
                <div style={{
                  display: 'flex',
                  gap: '2px',
                  marginBottom: '2px',
                }}>
                  {Array.from({ length: maxLevel }).map((_, i) => (
                    <div
                      key={i}
                      style={{
                        width: '6px',
                        height: '4px',
                        borderRadius: '1px',
                        background: i < stat.level ? 'var(--accent)' : 'var(--border)',
                      }}
                    />
                  ))}
                </div>
                {/* Potential bar */}
                <div style={{
                  width: '100%',
                  height: '3px',
                  background: 'var(--border)',
                  borderRadius: '2px',
                  overflow: 'hidden',
                }}>
                  <div style={{
                    width: `${pct}%`,
                    height: '100%',
                    background: isNearBreakthrough
                      ? 'linear-gradient(90deg, var(--accent), var(--accent-glow))'
                      : 'var(--text-secondary)',
                    borderRadius: '2px',
                    transition: 'width 0.3s',
                  }} />
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

export default CharacterPreview;
export type { BodyPart };
