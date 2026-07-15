import { useState, useEffect } from 'react';

interface BodyPart {
  part: string;
  level: number;
  potential: number;
}

interface CharacterPreviewProps {
  username: string;
  characterName?: string;
  avatar_url?: string;
  body_stats?: BodyPart[];
  compact?: boolean;
  onClick?: () => void;
  loading?: boolean;
}

const PART_LABELS: Record<string, string> = {
  chest: '가슴',
  back: '등',
  shoulders: '어깨',
  arms: '팔',
  abs: '복근',
  legs: '하체',
  cardio: '유산소',
  core: '코어',
  stamina: '유산소',
};

const PART_EMOJI: Record<string, string> = {
  chest: '🦾',
  back: '🔙',
  shoulders: '💪',
  arms: '💪',
  abs: '🏋️',
  legs: '🦵',
  cardio: '🫀',
  core: '🏋️',
  stamina: '🫀',
};

function CharacterPreview({
  username,
  characterName,
  avatar_url: _avatarUrl,
  body_stats,
  compact = false,
  onClick,
  loading = false,
}: CharacterPreviewProps) {
  const [expanded, setExpanded] = useState(false);
  const [imgError, setImgError] = useState(false);
  const [prefersReducedMotion, setPrefersReducedMotion] = useState(false);

  useEffect(() => {
    if (typeof window === 'undefined' || !window.matchMedia) return;
    const mediaQuery = window.matchMedia('(prefers-reduced-motion: reduce)');
    setPrefersReducedMotion(mediaQuery.matches);
    const handler = (e: MediaQueryListEvent) => setPrefersReducedMotion(e.matches);
    mediaQuery.addEventListener('change', handler);
    return () => mediaQuery.removeEventListener('change', handler);
  }, []);

  if (loading) {
    return (
      <div
        style={{
          background: 'var(--bg-card)',
          borderRadius: compact ? '8px' : '12px',
          border: '1px solid var(--border)',
          padding: compact ? '10px 12px' : '16px',
          display: 'inline-flex',
          flexDirection: 'column',
          alignItems: 'center',
          gap: compact ? '6px' : '10px',
          minWidth: compact ? '90px' : '140px',
          opacity: 0.6,
        }}
      >
        <div style={{
          width: compact ? '40px' : '56px',
          height: compact ? '40px' : '56px',
          borderRadius: '50%',
          background: 'var(--border)',
        }} />
        <div style={{
          width: '60px',
          height: '12px',
          background: 'var(--border)',
          borderRadius: '4px',
        }} />
      </div>
    );
  }

  const displayName = characterName || username;
  const initial = displayName?.charAt(0)?.toUpperCase() || '?';

  const maxLevel = 10;
  const totalLevel = body_stats?.reduce((sum, s) => sum + s.level, 0) ?? 0;
  const totalPotential = body_stats?.reduce((sum, s) => sum + s.potential, 0) ?? 0;

  const hasStats = body_stats && body_stats.length > 0;

  // Calculate stage
  let stage = 1;
  if (_avatarUrl) {
    const match = _avatarUrl.match(/stage_(\d+)/);
    if (match) {
      stage = parseInt(match[1], 10);
    } else if (hasStats) {
      stage = totalLevel < 15 ? 1 : totalLevel < 30 ? 2 : 3;
    }
  } else if (hasStats) {
    stage = totalLevel < 15 ? 1 : totalLevel < 30 ? 2 : 3;
  }
  stage = Math.max(1, Math.min(3, stage));

  // Next goal
  let nextGoal = '';
  if (stage === 1) {
    nextGoal = `Lv.15 (남은 레벨: ${15 - totalLevel})`;
  } else if (stage === 2) {
    nextGoal = `Lv.30 (남은 레벨: ${30 - totalLevel})`;
  } else {
    nextGoal = '최대 단계 달성';
  }

  return (
    <div
      role="button"
      tabIndex={hasStats || onClick ? 0 : undefined}
      aria-expanded={hasStats ? expanded : undefined}
      aria-label={`${displayName} 캐릭터 정보`}
      onClick={() => {
        if (onClick) onClick();
        if (hasStats) setExpanded(!expanded);
      }}
      onKeyDown={(e) => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          if (onClick) onClick();
          if (hasStats) setExpanded(!expanded);
        }
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
        transition: prefersReducedMotion ? 'none' : 'border-color 0.2s, box-shadow 0.2s',
        outline: 'none',
      }}
      onMouseEnter={(e) => {
        (e.currentTarget as HTMLDivElement).style.borderColor = 'var(--accent)';
        (e.currentTarget as HTMLDivElement).style.boxShadow = '0 0 12px rgba(255,61,61,0.15)';
      }}
      onMouseLeave={(e) => {
        (e.currentTarget as HTMLDivElement).style.borderColor = 'var(--border)';
        (e.currentTarget as HTMLDivElement).style.boxShadow = 'none';
      }}
      onFocus={(e) => {
        (e.currentTarget as HTMLDivElement).style.borderColor = 'var(--accent)';
        (e.currentTarget as HTMLDivElement).style.boxShadow = 'var(--shadow-focus)';
      }}
      onBlur={(e) => {
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
            alt={displayName}
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

      {/* Username / Character Name */}
      <span style={{
        fontSize: compact ? '0.8rem' : '0.95rem',
        fontWeight: 600,
        color: 'var(--text-primary)',
        textAlign: 'center',
        lineHeight: 1.2,
      }}>
        {displayName}
      </span>

      {/* Summary stats */}
      {hasStats && !expanded && (
        <div style={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          gap: '2px',
          fontSize: compact ? '0.65rem' : '0.75rem',
          color: 'var(--text-secondary)',
        }}>
          <div style={{ display: 'flex', gap: compact ? '4px' : '8px' }}>
            <span>Lv.{totalLevel}</span>
            <span style={{ color: 'var(--accent-glow)' }}>⚡{totalPotential}</span>
          </div>
          {!compact && (
            <span style={{ fontSize: '0.65rem', opacity: 0.8 }}>
              Stage {stage}
            </span>
          )}
        </div>
      )}

      {/* Expanded body stats */}
      {hasStats && expanded && (
        <div style={{
          width: '100%',
          display: 'flex',
          flexDirection: 'column',
          gap: '10px',
          marginTop: '4px',
        }}>
          {/* Stage & Next Goal Info */}
          <div style={{
            padding: '6px 8px',
            background: 'var(--bg-secondary)',
            borderRadius: '6px',
            fontSize: '0.7rem',
            color: 'var(--text-secondary)',
            display: 'flex',
            flexDirection: 'column',
            gap: '2px',
            border: '1px solid var(--border)',
          }}>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span>진화 단계</span>
              <span style={{ fontWeight: 700, color: 'var(--accent-glow)' }}>Stage {stage}</span>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span>다음 목표</span>
              <span style={{ fontWeight: 700 }}>{nextGoal}</span>
            </div>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
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
                      {isNearBreakthrough && (
                        <span style={{
                          fontSize: '0.6rem',
                          color: 'var(--accent-glow)',
                          fontWeight: 700,
                        }}>
                          ⚡돌파대기
                        </span>
                      )}
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
                          flex: 1,
                          height: '4px',
                          borderRadius: '1px',
                          background: i < stat.level ? 'var(--accent)' : 'var(--border)',
                        }}
                      />
                    ))}
                  </div>
                  {/* Potential bar */}
                  <div
                    role="progressbar"
                    aria-valuenow={stat.potential}
                    aria-valuemin={0}
                    aria-valuemax={100}
                    aria-label={`${PART_LABELS[stat.part] || stat.part} 잠재력`}
                    style={{
                      width: '100%',
                      height: '3px',
                      background: 'var(--border)',
                      borderRadius: '2px',
                      overflow: 'hidden',
                    }}
                  >
                    <div style={{
                      width: `${pct}%`,
                      height: '100%',
                      background: isNearBreakthrough
                        ? 'linear-gradient(90deg, var(--accent), var(--accent-glow))'
                        : 'var(--text-secondary)',
                      borderRadius: '2px',
                      transition: prefersReducedMotion ? 'none' : 'width 0.3s',
                    }} />
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}

export default CharacterPreview;
export type { BodyPart };
