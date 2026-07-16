import { useParams, useNavigate, Link } from 'react-router-dom';
import { useEffect, useState, useRef, useCallback } from 'react';
import api from '../api';
import CharacterPreview from '../components/CharacterPreview';
import StreakBadge from '../components/StreakBadge';
import { Button } from '../components/ui';
import type { BodyPart } from '../components/CharacterPreview';
import VideoAttachment from '../components/VideoAttachment';

interface Member {
  id: string;
  user_id?: string | number;
  username: string;
  characterName?: string;
  avatar_url?: string;
  body_stats?: BodyPart[];
  role?: string;
}

interface PartyInfo {
  id: string | number;
  name: string;
  member_count: number;
  invite_code?: string;
  owner_id?: string | number;
  match_type: 'manual' | 'random' | string;
  max_members: number;
  is_open: boolean;
  last_matched_at?: string | null;
  members: Member[];
}

const isRandomParty = (party: PartyInfo) => party.match_type === 'random';

const getCurrentUserId = (): string | null => {
  const token = localStorage.getItem('token');
  if (!token) return null;
  try {
    const payload = token.split('.')[1];
    if (!payload) return null;
    const normalized = payload.replace(/-/g, '+').replace(/_/g, '/');
    const decoded = JSON.parse(window.atob(normalized.padEnd(Math.ceil(normalized.length / 4) * 4, '=')));
    return decoded.sub ? String(decoded.sub) : null;
  } catch {
    return null;
  }
};

interface FeedEvent {
  id: string;
  event_type: 'member_joined' | 'workout_start' | 'setlog' | 'workout_end' | 'reaction';
  username: string;
  content?: string;
  setlog_type?: 'start' | 'mid' | 'end';
  file_path?: string;
  media?: { id: string; poster_url?: string | null; duration_seconds?: number; content_type?: string };
  created_at: string;
  referenced_event_id?: string;
  reaction_type?: string;
  workout_stats?: {
    duration_seconds?: number;
    setlog_count?: number;
  };
  breakthroughs?: Array<{
    part: string;
    old_level: number;
    new_level: number;
  }>;
  body_stats?: BodyPart[];
  workout_id?: string;
  setlog_id?: string;
  target_type?: 'setlog' | 'workout';
  target_id?: string;
  user?: {
    id: number;
    username: string;
    character?: {
      id: number;
      name: string;
      avatar_seed: string;
      avatar_url?: string;
      body_stats?: BodyPart[];
    };
  };
}

function FeedAvatar({ avatarUrl, fallback }: { avatarUrl?: string; fallback: string }) {
  const [imgError, setImgError] = useState(false);
  const initial = fallback?.charAt(0)?.toUpperCase() || '?';

  return (
    <div style={{
      width: '24px',
      height: '24px',
      borderRadius: '50%',
      background: 'linear-gradient(135deg, var(--accent), #cc0000)',
      display: 'inline-flex',
      alignItems: 'center',
      justifyContent: 'center',
      fontSize: '0.65rem',
      fontWeight: 700,
      color: '#fff',
      flexShrink: 0,
      overflow: 'hidden',
      border: '1px solid var(--border)',
    }}>
      {avatarUrl && !imgError ? (
        <img
          src={avatarUrl}
          alt={fallback}
          onError={() => setImgError(true)}
          style={{ width: '100%', height: '100%', objectFit: 'cover' }}
        />
      ) : (
        initial
      )}
    </div>
  );
}

function PartyRoomPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [party, setParty] = useState<PartyInfo | null>(null);
  const [feed, setFeed] = useState<FeedEvent[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [copied, setCopied] = useState(false);
  const [leaving, setLeaving] = useState(false);
  const [kickingId, setKickingId] = useState<string | null>(null);
  const feedEndRef = useRef<HTMLDivElement>(null);
  const feedContainerRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = useCallback(() => {
    if (feedEndRef.current) {
      feedEndRef.current.scrollIntoView({ behavior: 'smooth' });
    }
  }, []);

  useEffect(() => {
    if (!id) return;
    setLoading(true);
    setError('');

    Promise.all([
      api.get(`/parties/${id}`),
      api.get(`/parties/${id}/feed`),
    ])
      .then(([partyRes, feedRes]) => {
        setParty(normalizeParty(partyRes.data));
        const events = Array.isArray(feedRes.data) ? feedRes.data : feedRes.data?.events ?? [];
        setFeed(events);
      })
      .catch((err) => {
        setError(err.response?.data?.message || '파티 정보를 불러오지 못했습니다');
      })
      .finally(() => setLoading(false));
  }, [id]);

  // Auto-scroll when new feed items load
  useEffect(() => {
    if (!loading && feed.length > 0) {
      // Small delay to let DOM render
      const timer = setTimeout(scrollToBottom, 100);
      return () => clearTimeout(timer);
    }
  }, [loading, feed.length, scrollToBottom]);

  const currentUserId = getCurrentUserId();
  const isOwner = !!party?.owner_id && currentUserId === String(party.owner_id);

  const handleLeaveParty = async () => {
    if (!id || !window.confirm('파티를 나가시겠습니까?')) return;
    setLeaving(true);
    try {
      await api.delete(`/parties/${id}/leave`);
      navigate('/parties');
    } catch (err: any) {
      alert(err.response?.data?.message || err.response?.data?.detail || '파티 나가기에 실패했습니다');
    } finally {
      setLeaving(false);
    }
  };

  const handleKickMember = async (member: Member) => {
    if (!id || !member.user_id) return;
    if (!window.confirm(`${member.username}님을 파티에서 내보내시겠습니까?`)) return;
    const userId = String(member.user_id);
    setKickingId(userId);
    try {
      await api.delete(`/parties/${id}/members/${userId}`);
      setParty((prev) => {
        if (!prev) return prev;
        const members = prev.members.filter((m) => String(m.user_id) !== userId);
        return { ...prev, members, member_count: Math.max(0, prev.member_count - 1) };
      });
    } catch (err: any) {
      alert(err.response?.data?.message || err.response?.data?.detail || '멤버 내보내기에 실패했습니다');
    } finally {
      setKickingId(null);
    }
  };

  const handleStartWorkout = async () => {
    try {
      const { data } = await api.post('/workouts', { party_id: id });
      navigate(`/workout/${data.id}`);
    } catch (err: any) {
      alert(err.response?.data?.message || '운동 시작에 실패했습니다');
    }
  };

  const handleCopyInvite = async () => {
    const code = party?.invite_code;
    if (!code) return;
    try {
      await navigator.clipboard.writeText(code);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      // Fallback: show code in alert
      alert(`초대 코드: ${code}`);
    }
  };

  const formatTime = (iso: string) => {
    try {
      const d = new Date(iso);
      return d.toLocaleTimeString('ko-KR', { hour: '2-digit', minute: '2-digit' });
    } catch {
      return iso;
    }
  };

  const formatDuration = (seconds?: number) => {
    if (!seconds) return '';
    const m = Math.floor(seconds / 60);
    const s = seconds % 60;
    return `${m}분 ${s}초`;
  };

  const PART_LABELS: Record<string, string> = {
    chest: '가슴', back: '등', shoulders: '어깨', arms: '팔',
    core: '코어', stamina: '유산소', abs: '복근', legs: '하체', cardio: '유산소',
  };

  const normalizeParty = (raw: any): PartyInfo => ({
    ...raw,
    match_type: raw.match_type ?? 'manual',
    max_members: raw.max_members ?? 4,
    is_open: raw.is_open ?? true,
    member_count: raw.member_count ?? raw.members?.length ?? 0,
    members: Array.isArray(raw.members) ? raw.members.map((m: any) => (m.user ? {
      id: String(m.user.id),
      user_id: m.user_id ?? m.user.id,
      username: m.user.username,
      characterName: m.user.character?.name,
      avatar_url: m.user.character?.avatar_url,
      body_stats: m.user.character?.body_stats,
      role: m.role,
    } : {
      ...m,
      id: String(m.id ?? m.user_id),
      user_id: m.user_id ?? m.id,
    })) : [],
  });

  const handleReact = async (target_type: 'setlog' | 'workout', target_id: string | number | undefined, emoji: string) => {
    if (!target_id) return;
    try {
      await api.post('/reactions', { target_type, target_id: Number(target_id), emoji });
      setFeed((prev) => [...prev, {
        id: 'reaction:local:' + Date.now(),
        event_type: 'reaction',
        username: '나',
        created_at: new Date().toISOString(),
        target_type,
        target_id: String(target_id),
        reaction_type: emoji,
      }]);
    } catch (err: any) {
      if (err.response?.status !== 409) {
        alert(err.response?.data?.message || err.response?.data?.detail || '반응 등록에 실패했습니다');
      }
    }
  };

  const renderReactionButtons = (target_type: 'setlog' | 'workout', target_id?: string | number) => (
    <div style={{ display: 'flex', gap: '6px', marginTop: '10px' }}>
      {['🔥', '💪', '👏'].map((emoji) => (
        <button key={emoji} type="button" onClick={() => handleReact(target_type, target_id, emoji)} style={reactionBtnStyle}>
          {emoji}
        </button>
      ))}
    </div>
  );

  // ---- Render helpers for each event type ----

  const renderEvent = (evt: FeedEvent, idx: number) => {
    const displayEventName = evt.user?.character?.name || evt.username;
    switch (evt.event_type) {
      case 'member_joined':
        return (
          <div key={evt.id || idx} style={systemMsgStyle}>
            <span>👋</span>
            <FeedAvatar avatarUrl={evt.user?.character?.avatar_url} fallback={displayEventName} />
            <span style={{ fontWeight: 600 }}>{displayEventName}</span>
            <span>님이 파티에 참가했습니다</span>
            <span style={timeStyle}>{formatTime(evt.created_at)}</span>
          </div>
        );

      case 'workout_start':
        return (
          <div key={evt.id || idx} style={eventCardStyle}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <FeedAvatar avatarUrl={evt.user?.character?.avatar_url} fallback={displayEventName} />
              <div>
                <div style={{ fontWeight: 600, fontSize: '0.95rem' }}>
                  {displayEventName}님 운동 시작
                </div>
                <div style={timeStyle}>{formatTime(evt.created_at)}</div>
                {renderReactionButtons('setlog', evt.setlog_id || evt.target_id)}
              </div>
            </div>
          </div>
        );

      case 'setlog': {
        const typeIcon = evt.setlog_type === 'start' ? '▶️' : evt.setlog_type === 'mid' ? '📸' : '✅';
        const typeLabel = evt.setlog_type === 'start' ? '시작' : evt.setlog_type === 'mid' ? '중간' : '종료';
        return (
          <div key={evt.id || idx} style={eventCardStyle}>
            <div style={{ display: 'flex', alignItems: 'flex-start', gap: '10px' }}>
              <FeedAvatar avatarUrl={evt.user?.character?.avatar_url} fallback={displayEventName} />
              <div style={{ flex: 1 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '4px' }}>
                  <span style={{ fontWeight: 600, fontSize: '0.9rem' }}>{displayEventName}</span>
                  <span style={{
                    fontSize: '0.7rem',
                    padding: '1px 6px',
                    borderRadius: '4px',
                    background: 'var(--bg-secondary)',
                    color: 'var(--text-secondary)',
                  }}>
                    {typeIcon} {typeLabel}
                  </span>
                </div>
                {evt.content && (
                  <div style={{
                    fontSize: '0.9rem',
                    color: 'var(--text-primary)',
                    whiteSpace: 'pre-wrap',
                    lineHeight: 1.5,
                    marginBottom: evt.file_path ? '10px' : 0,
                  }}>
                    {evt.content}
                  </div>
                )}
                {evt.file_path && (evt.media?.content_type === 'video/mp4' || /\.mp4($|\?)/i.test(evt.file_path) ? (
                  <VideoAttachment path={evt.file_path} posterUrl={evt.media?.poster_url} title={`${displayEventName} workout video`} />
                ) : (
                  <div style={{ marginTop: '8px', padding: '20px', background: 'var(--bg-secondary)', borderRadius: '8px', border: '1px dashed var(--border)', textAlign: 'center', color: 'var(--text-secondary)', fontSize: '0.85rem' }}>
                    ?? Media attached
                  </div>
                ))}
                <div style={timeStyle}>{formatTime(evt.created_at)}</div>
              </div>
            </div>
          </div>
        );
      }

      case 'workout_end': {
        const hasBreakthrough = evt.breakthroughs && evt.breakthroughs.length > 0;
        return (
          <div key={evt.id || idx} style={{
            ...eventCardStyle,
            borderColor: 'var(--accent)',
            boxShadow: '0 0 20px rgba(255,61,61,0.12)',
          }}>
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', marginBottom: '14px', gap: '8px' }}>
              <FeedAvatar avatarUrl={evt.user?.character?.avatar_url} fallback={displayEventName} />
              <div style={{ fontWeight: 700, fontSize: '1.1rem', color: 'var(--accent-glow)' }}>
                {displayEventName}님 운동 완료!
              </div>
            </div>

            {/* Stats */}
            {evt.workout_stats && (
              <div style={{
                display: 'flex',
                justifyContent: 'center',
                gap: '24px',
                marginBottom: '14px',
                padding: '12px',
                background: 'var(--bg-secondary)',
                borderRadius: '8px',
              }}>
                <div style={{ textAlign: 'center' }}>
                  <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>운동 시간</div>
                  <div style={{ fontWeight: 700, fontSize: '1rem' }}>
                    {formatDuration(evt.workout_stats.duration_seconds)}
                  </div>
                </div>
                <div style={{ textAlign: 'center' }}>
                  <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>세트로그</div>
                  <div style={{ fontWeight: 700, fontSize: '1rem' }}>{evt.workout_stats.setlog_count}개</div>
                </div>
              </div>
            )}

            {/* Body stats after workout */}
            {evt.body_stats && evt.body_stats.length > 0 && (
              <div style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(auto-fill, minmax(80px, 1fr))',
                gap: '6px',
                marginBottom: hasBreakthrough ? '10px' : 0,
              }}>
                {evt.body_stats.map((bs) => {
                  const breakthrough = evt.breakthroughs?.find((b) => b.part === bs.part);
                  const isNew = !!breakthrough;
                  return (
                    <div key={bs.part} style={{
                      textAlign: 'center',
                      padding: '6px 4px',
                      background: isNew ? 'rgba(255,61,61,0.1)' : 'var(--bg-secondary)',
                      borderRadius: '6px',
                      border: isNew ? '1px solid var(--accent)' : '1px solid transparent',
                    }}>
                      <div style={{ fontSize: '0.65rem', color: 'var(--text-secondary)' }}>
                        {PART_LABELS[bs.part] || bs.part}
                      </div>
                      <div style={{
                        fontWeight: 700,
                        fontSize: '0.85rem',
                        color: isNew ? 'var(--accent-glow)' : 'var(--text-primary)',
                      }}>
                        Lv.{bs.level}
                      </div>
                      {isNew && (
                        <div style={{ fontSize: '0.6rem', color: 'var(--accent-glow)' }}>
                          ✨ {breakthrough.old_level} → {breakthrough.new_level}
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            )}

            {/* Breakthrough message */}
            {hasBreakthrough && (
              <div style={{
                textAlign: 'center',
                marginTop: '10px',
                padding: '10px',
                background: 'rgba(255,61,61,0.12)',
                borderRadius: '8px',
                fontWeight: 700,
                color: 'var(--accent-glow)',
                fontSize: '0.95rem',
              }}>
                🔥 돌파 성공!{' '}
                {evt.breakthroughs?.map((b) => PART_LABELS[b.part] || b.part).join(', ')}{' '}
                레벨 상승!
              </div>
            )}
            {!hasBreakthrough && evt.body_stats && (
              <div style={{
                textAlign: 'center',
                marginTop: '10px',
                padding: '8px',
                color: 'var(--text-secondary)',
                fontSize: '0.85rem',
              }}>
                ⚡ 잠재력 누적
              </div>
            )}

            <div style={{ ...timeStyle, textAlign: 'center', marginTop: '8px' }}>
              {formatTime(evt.created_at)}
            </div>
            <div style={{ display: 'flex', justifyContent: 'center' }}>
              {renderReactionButtons('workout', evt.workout_id || evt.target_id)}
            </div>
          </div>
        );
      }

      case 'reaction':
        return (
          <div key={evt.id || idx} style={{
            padding: '2px 8px',
            fontSize: '0.8rem',
            color: 'var(--text-secondary)',
            display: 'flex',
            alignItems: 'center',
            gap: '4px',
          }}>
            <span>{evt.reaction_type || '❤️'}</span>
            <span style={{ fontWeight: 600 }}>{evt.username}</span>
          </div>
        );

      default:
        return null;
    }
  };

  // ---- Loading / Error states ----
  if (loading) {
    return (
      <div style={{ textAlign: 'center', padding: '80px 20px', color: 'var(--text-secondary)' }}>
        <div style={{ fontSize: '2rem', marginBottom: '12px' }}>⏳</div>
        <p>파티 불러오는 중...</p>
      </div>
    );
  }

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
        <Link to="/parties" style={{ color: 'var(--accent)' }}>← 파티 목록으로</Link>
      </div>
    );
  }

  if (!party) return null;

  // ---- Main render ----
  return (
    <div style={{
      maxWidth: 800,
      margin: '0 auto',
      display: 'flex',
      flexDirection: 'column',
      height: 'calc(100vh - 80px)', // account for nav
    }}>
      {/* ========== TOP: Party Info ========== */}
      <div style={{
        padding: '16px 0',
        borderBottom: '1px solid var(--border)',
        flexShrink: 0,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '10px' }}>
          <Link to="/parties" style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>
            ←
          </Link>
          <h1 style={{ fontSize: '1.4rem', fontWeight: 700, flex: 1 }}>
            🔥 {party.name}
            {isRandomParty(party) && <span style={randomBadgeStyle}>🎲 랜덤</span>}
          </h1>
          <StreakBadge />
          <span style={{
            fontSize: '0.85rem',
            color: 'var(--text-secondary)',
            background: 'var(--bg-card)',
            padding: '4px 10px',
            borderRadius: '20px',
            border: '1px solid var(--border)',
          }}>
            👥 {party.member_count}명{isRandomParty(party) ? ` / ${party.max_members}` : ''}
          </span>
        </div>

        {/* Invite code */}
        {party.invite_code && (
          <button
            onClick={handleCopyInvite}
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              gap: '6px',
              background: copied ? 'rgba(76,175,80,0.2)' : 'var(--bg-card)',
              border: `1px solid ${copied ? 'var(--success)' : 'var(--border)'}`,
              color: copied ? 'var(--success)' : 'var(--text-secondary)',
              padding: '6px 14px',
              borderRadius: '8px',
              fontSize: '0.8rem',
              cursor: 'pointer',
              transition: 'all 0.2s',
            }}
          >
            <span>📨</span>
            <span style={{ fontFamily: 'monospace', letterSpacing: '1px' }}>
              {party.invite_code}
            </span>
            <span style={{ fontSize: '0.7rem' }}>
              {copied ? '복사됨!' : '복사'}
            </span>
          </button>
        )}
      </div>

      {/* ========== Members row ========== */}
      {party.members && party.members.length > 0 && (
        <div style={{
          padding: '12px 0',
          borderBottom: '1px solid var(--border)',
          overflowX: 'auto',
          whiteSpace: 'nowrap',
          flexShrink: 0,
        }}>
          <div style={{ display: 'inline-flex', gap: '10px', paddingRight: '10px' }}>
            {party.members.map((m) => {
              const memberUserId = m.user_id ? String(m.user_id) : m.id;
              const canKick = isOwner && currentUserId !== memberUserId;
              return (
                <div key={m.id} style={memberChipStyle}>
                  <CharacterPreview
                    username={m.username}
                    characterName={m.characterName}
                    avatar_url={m.avatar_url}
                    body_stats={m.body_stats}
                    compact
                  />
                  {canKick && (
                    <button
                      type="button"
                      onClick={() => handleKickMember(m)}
                      disabled={kickingId === memberUserId}
                      style={kickBtnStyle}
                      title={`${m.username} 내보내기`}
                    >
                      {kickingId === memberUserId ? '...' : '내보내기'}
                    </button>
                  )}
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* ========== MAIN: Feed Timeline ========== */}
      <div
        ref={feedContainerRef}
        style={{
          flex: 1,
          overflowY: 'auto',
          padding: '16px 0',
          display: 'flex',
          flexDirection: 'column',
          gap: '10px',
        }}
      >
        {feed.length === 0 && (
          <div style={{
            textAlign: 'center',
            padding: '60px 20px',
            color: 'var(--text-secondary)',
          }}>
            <div style={{ fontSize: '2.5rem', marginBottom: '12px' }}>🏋️</div>
            <p style={{ fontSize: '1rem', marginBottom: '6px' }}>아직 활동이 없습니다</p>
            <p style={{ fontSize: '0.85rem' }}>첫 운동을 시작해보세요!</p>
          </div>
        )}
        {feed.map((evt, idx) => renderEvent(evt, idx))}
        <div ref={feedEndRef} />
      </div>

      {/* ========== BOTTOM: Quick Actions ========== */}
      <div style={{
        padding: '12px 0',
        borderTop: '1px solid var(--border)',
        display: 'flex',
        gap: '10px',
        flexShrink: 0,
      }}>
        <button
          onClick={handleStartWorkout}
          style={actionBtnStyle('#ff3d3d')}
        >
          🔥 운동 시작
        </button>
        <Button
          variant="secondary"
          onClick={handleLeaveParty}
          disabled={leaving}
          style={{ flex: 1 }}
        >
          {leaving ? '나가는 중...' : '🚪 나가기'}
        </Button>
        <button
          onClick={() => navigate('/parties')}
          style={actionBtnStyle('#555')}
        >
          📋 내 파티
        </button>
        <button
          onClick={handleCopyInvite}
          style={actionBtnStyle('#555')}
        >
          {copied ? '✅ 복사됨' : '📨 초대'}
        </button>
      </div>
    </div>
  );
}

// ---- Styles ----

const randomBadgeStyle: React.CSSProperties = {
  display: 'inline-flex',
  alignItems: 'center',
  marginLeft: '10px',
  padding: '2px 8px',
  borderRadius: '999px',
  background: 'rgba(255, 193, 7, 0.16)',
  border: '1px solid rgba(255, 193, 7, 0.38)',
  color: '#ffc107',
  fontSize: '0.72rem',
  fontWeight: 700,
  verticalAlign: 'middle',
};

const memberChipStyle: React.CSSProperties = {
  display: 'inline-flex',
  alignItems: 'center',
  gap: '6px',
  paddingRight: '4px',
};

const kickBtnStyle: React.CSSProperties = {
  background: 'rgba(244,67,54,0.12)',
  border: '1px solid rgba(244,67,54,0.35)',
  color: 'var(--danger)',
  borderRadius: '999px',
  padding: '4px 8px',
  fontSize: '0.72rem',
  cursor: 'pointer',
};

const systemMsgStyle: React.CSSProperties = {
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'center',
  gap: '6px',
  padding: '8px 16px',
  fontSize: '0.85rem',
  color: 'var(--text-secondary)',
  textAlign: 'center',
  flexWrap: 'wrap',
};

const eventCardStyle: React.CSSProperties = {
  background: 'var(--bg-card)',
  borderRadius: '12px',
  border: '1px solid var(--border)',
  padding: '14px 16px',
};

const timeStyle: React.CSSProperties = {
  fontSize: '0.7rem',
  color: 'var(--text-secondary)',
  marginTop: '6px',
};

const actionBtnStyle = (bg: string): React.CSSProperties => ({
  flex: 1,
  padding: '12px 8px',
  background: bg,
  border: 'none',
  borderRadius: '10px',
  color: '#fff',
  fontWeight: 700,
  fontSize: '0.9rem',
  cursor: 'pointer',
  transition: 'opacity 0.2s',
});

const reactionBtnStyle: React.CSSProperties = {
  background: 'var(--bg-secondary)',
  border: '1px solid var(--border)',
  borderRadius: '999px',
  padding: '4px 9px',
  cursor: 'pointer',
  fontSize: '0.9rem',
};

export default PartyRoomPage;
