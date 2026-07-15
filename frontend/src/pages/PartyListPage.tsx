import { useEffect, useState, type FormEvent, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import api from '../api';
import { Button } from '../components/ui';

interface PartyMember {
  id: string | number;
  user_id?: string | number;
  username?: string;
}

interface Party {
  id: string | number;
  name: string;
  member_count: number;
  invite_code?: string;
  created_at: string;
  last_activity?: string;
  owner_id?: string | number;
  match_type: 'manual' | 'random' | string;
  max_members: number;
  is_open: boolean;
  last_matched_at?: string | null;
  members: PartyMember[];
}

const normalizeParty = (raw: any): Party => ({
  ...raw,
  id: raw.id,
  match_type: raw.match_type ?? 'manual',
  max_members: raw.max_members ?? 4,
  is_open: raw.is_open ?? true,
  members: Array.isArray(raw.members) ? raw.members : [],
  member_count: raw.member_count ?? (Array.isArray(raw.members) ? raw.members.length : 0),
});

const isRandomParty = (party: Party) => party.match_type === 'random';

// Member avatar emojis for discovery cards
const AVATAR_EMOJIS = ['💪', '🏋️', '🔥', '⚡', '🦵', '💥', '💯', '👑', '🎯', '🏆'];

function PartyListPage() {
  const navigate = useNavigate();
  const [parties, setParties] = useState<Party[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  // Random discovery
  const [discoveryParties, setDiscoveryParties] = useState<Party[]>([]);
  const [discoveryLoading, setDiscoveryLoading] = useState(false);

  // Create party form
  const [showCreate, setShowCreate] = useState(false);
  const [createName, setCreateName] = useState('');
  const [creating, setCreating] = useState(false);
  const [createError, setCreateError] = useState('');

  // Join party form
  const [showJoin, setShowJoin] = useState(false);
  const [joinCode, setJoinCode] = useState('');
  const [joining, setJoining] = useState(false);
  const [joinError, setJoinError] = useState('');

  const [randomMatching, setRandomMatching] = useState(false);
  const [randomError, setRandomError] = useState('');

  const fetchParties = useCallback(() => {
    setLoading(true);
    api.get('/parties')
      .then(({ data }) => {
        const list = Array.isArray(data) ? data : data.parties ?? [];
        setParties(list.map(normalizeParty));
      })
      .catch((err) => setError(err.response?.data?.message || '파티 목록을 불러오지 못했습니다'))
      .finally(() => setLoading(false));
  }, []);

  const fetchDiscoveryParties = useCallback(() => {
    setDiscoveryLoading(true);
    api.get('/parties/random-browse')
      .then(({ data }) => {
        const list = Array.isArray(data) ? data : [];
        // Filter out parties the user is already a member of
        const myPartyIds = new Set(parties.map((p) => p.id));
        setDiscoveryParties(list.map(normalizeParty).filter((p: Party) => !myPartyIds.has(p.id)));
      })
      .catch(() => {
        // Silently fail — discovery is optional
      })
      .finally(() => setDiscoveryLoading(false));
  }, [parties]);

  useEffect(() => {
    fetchParties();
  }, [fetchParties]);

  useEffect(() => {
    if (!loading && parties.length >= 0) {
      fetchDiscoveryParties();
    }
  }, [loading, parties.length]);

  const handleCreate = async (e: FormEvent) => {
    e.preventDefault();
    setCreateError('');
    if (!createName.trim()) {
      setCreateError('파티 이름을 입력해주세요');
      return;
    }
    setCreating(true);
    try {
      const { data } = await api.post('/parties/', {
        name: createName.trim(),
      });
      setShowCreate(false);
      setCreateName('');
      // Navigate to new party
      navigate(`/party/${data.id}`);
    } catch (err: any) {
      setCreateError(err.response?.data?.message || '파티 생성에 실패했습니다');
    } finally {
      setCreating(false);
    }
  };

  const handleRandomMatch = async () => {
    setRandomError('');
    setRandomMatching(true);
    try {
      const { data } = await api.post('/parties/random-match');
      const matchedParty = normalizeParty(data);
      navigate(`/party/${matchedParty.id}`);
    } catch (err: any) {
      setRandomError(err.response?.data?.message || err.response?.data?.detail || '랜덤 파티 매칭에 실패했습니다');
    } finally {
      setRandomMatching(false);
    }
  };

  const handleJoinDiscovery = async (partyId: string | number) => {
    setRandomMatching(true);
    try {
      // We can't directly join by ID, so use random-match which will find this party
      // Actually, let's try to find the party's invite code from the data
      const party = discoveryParties.find((p) => p.id === partyId);
      if (party?.invite_code) {
        await api.post('/parties/join', { invite_code: party.invite_code });
        navigate(`/party/${partyId}`);
      } else {
        // Fallback to random match
        const { data } = await api.post('/parties/random-match');
        navigate(`/party/${data.id}`);
      }
    } catch (err: any) {
      setRandomError(err.response?.data?.message || err.response?.data?.detail || '참가에 실패했습니다');
    } finally {
      setRandomMatching(false);
    }
  };

  const handleJoin = async (e: FormEvent) => {
    e.preventDefault();
    setJoinError('');
    if (!joinCode.trim()) {
      setJoinError('초대 코드를 입력해주세요');
      return;
    }
    setJoining(true);
    try {
      const { data } = await api.post('/parties/join', { invite_code: joinCode.trim() });
      setShowJoin(false);
      setJoinCode('');
      navigate(`/party/${data.id}`);
    } catch (err: any) {
      setJoinError(err.response?.data?.message || '파티 가입에 실패했습니다');
    } finally {
      setJoining(false);
    }
  };

  const formatTimeAgo = (iso: string) => {
    try {
      const diff = Date.now() - new Date(iso).getTime();
      const minutes = Math.floor(diff / 60000);
      if (minutes < 1) return '방금 전';
      if (minutes < 60) return `${minutes}분 전`;
      const hours = Math.floor(minutes / 60);
      if (hours < 24) return `${hours}시간 전`;
      const days = Math.floor(hours / 24);
      return `${days}일 전`;
    } catch {
      return '';
    }
  };

  return (
    <div style={{ maxWidth: 800, margin: '0 auto', padding: '0 0 40px' }}>
      {/* Header */}
      <div style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'flex-start',
        marginBottom: '28px',
      }}>
        <div>
          <h1 style={{ fontSize: '1.6rem', fontWeight: 700, marginBottom: '4px' }}>
            🔥 내 파티
          </h1>
          <p style={{ color: 'var(--text-secondary)', fontSize: '0.85rem' }}>
            {parties.length > 0 ? `${parties.length}개의 파티` : '참여 중인 파티가 없습니다'}
          </p>
        </div>
        <div style={{ display: 'flex', gap: '8px' }}>
          <button onClick={() => { setShowCreate(true); setShowJoin(false); }} style={smallBtnStyle}>
            + 새 파티
          </button>
          <button onClick={() => { setShowJoin(true); setShowCreate(false); }} style={smallBtnStyle}>
            + 가입
          </button>
          <Button
            size="sm"
            onClick={handleRandomMatch}
            disabled={randomMatching}
            title="온라인 랜덤 파티에 참가합니다"
          >
            {randomMatching ? (
              <span style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                <span className="spinner" style={{
                  display: 'inline-block',
                  width: '14px',
                  height: '14px',
                  border: '2px solid rgba(255,255,255,0.3)',
                  borderTop: '2px solid #fff',
                  borderRadius: '50%',
                  animation: 'spin 0.6s linear infinite',
                }} />
                매칭 중
              </span>
            ) : '🎲 랜덤'}
          </Button>
        </div>
      </div>

      {/* Error */}
      {randomError && (
        <div style={{
          background: 'rgba(244,67,54,0.15)',
          color: 'var(--danger)',
          padding: '10px 14px',
          borderRadius: '8px',
          marginBottom: '20px',
          fontSize: '0.9rem',
        }}>
          {randomError}
        </div>
      )}
      {error && (
        <div style={{
          background: 'rgba(244,67,54,0.15)',
          color: 'var(--danger)',
          padding: '10px 14px',
          borderRadius: '8px',
          marginBottom: '20px',
          fontSize: '0.9rem',
        }}>
          {error}
        </div>
      )}

      {/* Create Party Form */}
      {showCreate && (
        <div style={{
          background: 'var(--bg-card)',
          borderRadius: '14px',
          border: '1px solid var(--accent)',
          padding: '24px',
          marginBottom: '24px',
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
            <h2 style={{ fontSize: '1.1rem', fontWeight: 600 }}>🆕 새 파티 만들기</h2>
            <button
              onClick={() => { setShowCreate(false); setCreateError(''); }}
              style={{ background: 'none', border: 'none', color: 'var(--text-secondary)', cursor: 'pointer', fontSize: '1.2rem' }}
            >
              ✕
            </button>
          </div>
          <form onSubmit={handleCreate}>
            {createError && (
              <div style={{
                background: 'rgba(244,67,54,0.15)',
                color: 'var(--danger)',
                padding: '8px 12px',
                borderRadius: '6px',
                marginBottom: '16px',
                fontSize: '0.85rem',
              }}>
                {createError}
              </div>
            )}
            <div style={{ marginBottom: '16px' }}>
              <label style={labelStyle}>파티 이름 *</label>
              <input
                type="text"
                value={createName}
                onChange={(e) => setCreateName(e.target.value)}
                placeholder="예: 헬지옥 정복단"
                style={inputStyle}
                autoFocus
              />
            </div>

            <button
              type="submit"
              disabled={creating}
              style={{
                width: '100%',
                padding: '12px',
                background: creating ? '#993333' : 'var(--accent)',
                border: 'none',
                borderRadius: '10px',
                color: '#fff',
                fontWeight: 700,
                fontSize: '0.95rem',
                cursor: creating ? 'not-allowed' : 'pointer',
              }}
            >
              {creating ? '생성 중...' : '파티 생성'}
            </button>
          </form>
        </div>
      )}

      {/* Join Party Form */}
      {showJoin && (
        <div style={{
          background: 'var(--bg-card)',
          borderRadius: '14px',
          border: '1px solid var(--accent)',
          padding: '24px',
          marginBottom: '24px',
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
            <h2 style={{ fontSize: '1.1rem', fontWeight: 600 }}>📨 초대 코드로 가입</h2>
            <button
              onClick={() => { setShowJoin(false); setJoinError(''); }}
              style={{ background: 'none', border: 'none', color: 'var(--text-secondary)', cursor: 'pointer', fontSize: '1.2rem' }}
            >
              ✕
            </button>
          </div>
          <form onSubmit={handleJoin}>
            {joinError && (
              <div style={{
                background: 'rgba(244,67,54,0.15)',
                color: 'var(--danger)',
                padding: '8px 12px',
                borderRadius: '6px',
                marginBottom: '16px',
                fontSize: '0.85rem',
              }}>
                {joinError}
              </div>
            )}
            <div style={{ marginBottom: '20px' }}>
              <label style={labelStyle}>초대 코드</label>
              <input
                type="text"
                value={joinCode}
                onChange={(e) => setJoinCode(e.target.value.toUpperCase())}
                placeholder="예: ABC123"
                style={{ ...inputStyle, fontFamily: 'monospace', letterSpacing: '2px', textAlign: 'center' }}
                autoFocus
              />
            </div>
            <button
              type="submit"
              disabled={joining}
              style={{
                width: '100%',
                padding: '12px',
                background: joining ? '#993333' : 'var(--accent)',
                border: 'none',
                borderRadius: '10px',
                color: '#fff',
                fontWeight: 700,
                fontSize: '0.95rem',
                cursor: joining ? 'not-allowed' : 'pointer',
              }}
            >
              {joining ? '가입 중...' : '파티 가입'}
            </button>
          </form>
        </div>
      )}

      {/* Loading */}
      {loading && (
        <div style={{ textAlign: 'center', padding: '60px 20px', color: 'var(--text-secondary)' }}>
          ⏳ 파티 목록 불러오는 중...
        </div>
      )}

      {/* Empty state */}
      {!loading && !error && parties.length === 0 && !showCreate && !showJoin && (
        <div style={{
          textAlign: 'center',
          padding: '80px 20px',
        }}>
          <div style={{ fontSize: '3rem', marginBottom: '16px' }}>🏋️</div>
          <h2 style={{
            fontSize: '1.2rem',
            fontWeight: 600,
            color: 'var(--text-primary)',
            marginBottom: '8px',
          }}>
            아직 참여 중인 파티가 없습니다
          </h2>
          <p style={{ color: 'var(--text-secondary)', marginBottom: '24px', fontSize: '0.9rem' }}>
            파티를 만들거나 초대 코드로 가입하세요!
          </p>
          <div style={{ display: 'flex', gap: '10px', justifyContent: 'center' }}>
            <button onClick={handleRandomMatch} disabled={randomMatching} style={{
              ...actionBtnStyle,
              background: randomMatching ? '#993333' : 'var(--accent)',
              cursor: randomMatching ? 'not-allowed' : 'pointer',
            }}>
              {randomMatching ? '매칭 중...' : '🎲 랜덤 온라인 파티'}
            </button>
            <button onClick={() => setShowCreate(true)} style={actionBtnStyle}>
              + 새 파티 만들기
            </button>
            <button onClick={() => setShowJoin(true)} style={{
              ...actionBtnStyle,
              background: 'var(--bg-card)',
              border: '1px solid var(--accent)',
              color: 'var(--accent)',
            }}>
              초대 코드로 가입
            </button>
          </div>
        </div>
      )}

      {/* ── Random Party Discovery Section ── */}
      {!loading && (
        <div style={{ marginBottom: '32px' }}>
          <div style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            marginBottom: '16px',
          }}>
            <h2 style={{ fontSize: '1.2rem', fontWeight: 700 }}>
              🎲 랜덤 파티 찾기
            </h2>
            {discoveryLoading && (
              <span style={{ color: 'var(--text-secondary)', fontSize: '0.8rem', display: 'flex', alignItems: 'center', gap: '6px' }}>
                <span className="spinner" style={{
                  display: 'inline-block',
                  width: '14px',
                  height: '14px',
                  border: '2px solid rgba(255,255,255,0.2)',
                  borderTop: '2px solid var(--text-secondary)',
                  borderRadius: '50%',
                  animation: 'spin 0.6s linear infinite',
                }} />
                검색 중...
              </span>
            )}
          </div>
          {discoveryParties.length > 0 ? (
            <div style={{ display: 'grid', gap: '10px' }}>
              {discoveryParties.map((party) => (
                <div
                  key={party.id}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    padding: '12px 20px',
                    background: 'var(--bg-card)',
                    borderRadius: '10px',
                    border: '1px solid var(--border)',
                    transition: 'border-color 0.2s, box-shadow 0.2s',
                    cursor: 'pointer',
                    aspectRatio: '32 / 9',
                  }}
                  onMouseEnter={(e) => {
                    (e.currentTarget as HTMLDivElement).style.borderColor = '#ff3d3d';
                    (e.currentTarget as HTMLDivElement).style.boxShadow = '0 0 12px rgba(255,61,61,0.15)';
                  }}
                  onMouseLeave={(e) => {
                    (e.currentTarget as HTMLDivElement).style.borderColor = 'var(--border)';
                    (e.currentTarget as HTMLDivElement).style.boxShadow = 'none';
                  }}
                >
                  {/* Party info */}
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{
                      fontSize: '1rem',
                      fontWeight: 600,
                      marginBottom: '4px',
                      overflow: 'hidden',
                      textOverflow: 'ellipsis',
                      whiteSpace: 'nowrap',
                    }}>
                      {party.name}
                    </div>
                    <div style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: '6px',
                    }}>
                      {/* Member avatars */}
                      <div style={{ display: 'flex', alignItems: 'center', gap: '2px' }}>
                        {Array.from({ length: Math.min(party.member_count, 4) }).map((_, i) => (
                          <span key={i} style={{ fontSize: '1rem' }}>
                            {AVATAR_EMOJIS[i % AVATAR_EMOJIS.length]}
                          </span>
                        ))}
                      </div>
                      <span style={{
                        fontSize: '0.78rem',
                        color: 'var(--text-secondary)',
                      }}>
                        {party.member_count}/{party.max_members}명
                      </span>
                      {party.last_matched_at && (
                        <span style={{
                          fontSize: '0.72rem',
                          color: 'var(--text-secondary)',
                          opacity: 0.7,
                        }}>
                          · {formatTimeAgo(party.last_matched_at)}
                        </span>
                      )}
                    </div>
                  </div>

                  {/* Join button */}
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      handleJoinDiscovery(party.id);
                    }}
                    disabled={randomMatching}
                    style={{
                      padding: '8px 20px',
                      background: 'var(--accent)',
                      border: 'none',
                      borderRadius: '8px',
                      color: '#fff',
                      fontWeight: 700,
                      fontSize: '0.85rem',
                      cursor: 'pointer',
                      marginLeft: '12px',
                      flexShrink: 0,
                      transition: 'opacity 0.15s',
                      opacity: randomMatching ? 0.6 : 1,
                    }}
                  >
                    참가
                  </button>
                </div>
              ))}
            </div>
          ) : (
            !discoveryLoading && (
              <div style={{
                background: 'var(--bg-card)',
                borderRadius: '12px',
                border: '1px dashed var(--border)',
                padding: '32px 24px',
                textAlign: 'center',
              }}>
                <div style={{ fontSize: '2rem', marginBottom: '12px' }}>🎲</div>
                <p style={{
                  color: 'var(--text-secondary)',
                  fontSize: '0.9rem',
                  marginBottom: '16px',
                }}>
                  현재 열려있는 랜덤 파티가 없습니다. 🎲 랜덤 매칭을 시작해보세요!
                </p>
                <button
                  onClick={handleRandomMatch}
                  disabled={randomMatching}
                  style={{
                    padding: '12px 28px',
                    background: randomMatching ? '#993333' : 'var(--accent)',
                    border: 'none',
                    borderRadius: '10px',
                    color: '#fff',
                    fontWeight: 700,
                    fontSize: '0.95rem',
                    cursor: randomMatching ? 'not-allowed' : 'pointer',
                  }}
                >
                  {randomMatching ? '매칭 중...' : '🎲 랜덤 매칭 시작'}
                </button>
              </div>
            )
          )}
        </div>
      )}

      {/* ── My Party Cards ── */}
      {!loading && parties.length > 0 && (
        <div style={{ display: 'grid', gap: '12px' }}>
          {parties.map((party) => (
            <div
              key={party.id}
              onClick={() => navigate(`/party/${party.id}`)}
              style={{
                padding: '20px 24px',
                background: 'var(--bg-card)',
                borderRadius: '12px',
                border: '1px solid var(--border)',
                cursor: 'pointer',
                transition: 'border-color 0.2s, box-shadow 0.2s',
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
              }}
              onMouseEnter={(e) => {
                (e.currentTarget as HTMLDivElement).style.borderColor = 'var(--accent)';
                (e.currentTarget as HTMLDivElement).style.boxShadow = '0 0 16px rgba(255,61,61,0.1)';
              }}
              onMouseLeave={(e) => {
                (e.currentTarget as HTMLDivElement).style.borderColor = 'var(--border)';
                (e.currentTarget as HTMLDivElement).style.boxShadow = 'none';
              }}
            >
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{
                  fontSize: '1.1rem',
                  fontWeight: 600,
                  marginBottom: '4px',
                  overflow: 'hidden',
                  textOverflow: 'ellipsis',
                  whiteSpace: 'nowrap',
                }}>
                  {party.name}
                  {isRandomParty(party) ? (
                    <span style={randomBadgeStyle}>🎲 랜덤</span>
                  ) : (
                    <span style={manualBadgeStyle}>👥 매뉴얼</span>
                  )}
                </div>

                {party.last_activity && (
                  <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>
                    마지막 활동: {formatTimeAgo(party.last_activity)}
                  </div>
                )}
              </div>
              <div style={{
                display: 'flex',
                alignItems: 'center',
                gap: '12px',
                flexShrink: 0,
                marginLeft: '16px',
              }}>
                <span style={{
                  fontSize: '0.85rem',
                  color: 'var(--text-secondary)',
                  background: 'var(--bg-secondary)',
                  padding: '4px 10px',
                  borderRadius: '20px',
                }}>
                  👥 {party.member_count}명{isRandomParty(party) ? ` / ${party.max_members}` : ''}
                </span>
                <span style={{ color: 'var(--text-secondary)', fontSize: '1.2rem' }}>→</span>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Spin animation keyframes (injected as style tag) */}
      <style>{`
        @keyframes spin {
          to { transform: rotate(360deg); }
        }
      `}</style>
    </div>
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

const smallBtnStyle: React.CSSProperties = {
  padding: '8px 16px',
  background: 'var(--bg-card)',
  border: '1px solid var(--border)',
  borderRadius: '8px',
  color: 'var(--text-primary)',
  fontWeight: 600,
  fontSize: '0.85rem',
  cursor: 'pointer',
  transition: 'border-color 0.2s',
};

const randomBadgeStyle: React.CSSProperties = {
  display: 'inline-flex',
  alignItems: 'center',
  marginLeft: '8px',
  padding: '2px 8px',
  borderRadius: '999px',
  background: 'rgba(255, 193, 7, 0.16)',
  border: '1px solid rgba(255, 193, 7, 0.38)',
  color: '#ffc107',
  fontSize: '0.72rem',
  fontWeight: 700,
  verticalAlign: 'middle',
};

const manualBadgeStyle: React.CSSProperties = {
  display: 'inline-flex',
  alignItems: 'center',
  marginLeft: '8px',
  padding: '2px 8px',
  borderRadius: '999px',
  background: 'rgba(100, 149, 237, 0.16)',
  border: '1px solid rgba(100, 149, 237, 0.38)',
  color: '#6495ed',
  fontSize: '0.72rem',
  fontWeight: 700,
  verticalAlign: 'middle',
};

const actionBtnStyle: React.CSSProperties = {
  padding: '14px 32px',
  background: 'var(--accent)',
  border: 'none',
  borderRadius: '12px',
  color: '#fff',
  fontWeight: 700,
  fontSize: '1rem',
  cursor: 'pointer',
};

export default PartyListPage;
