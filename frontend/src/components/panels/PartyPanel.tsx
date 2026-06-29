import { useEffect, useState, useCallback, type FormEvent } from 'react';
import api from '../../api';

interface PartyMember {
  id: string | number;
  user_id?: string | number;
  username: string;
  role?: string;
}

interface Party {
  id: string | number;
  name: string;
  description?: string;
  member_count: number;
  invite_code?: string;
  match_type: string;
  max_members: number;
  is_open: boolean;
  members: PartyMember[];
}

interface FeedEvent {
  id: string;
  event_type: string;
  username: string;
  content?: string;
  setlog_type?: string;
  created_at: string;
}

const normalizeParty = (raw: any): Party => ({
  ...raw,
  members: Array.isArray(raw.members) ? raw.members : [],
  member_count: raw.member_count ?? (Array.isArray(raw.members) ? raw.members.length : 0),
  match_type: raw.match_type ?? 'manual',
  max_members: raw.max_members ?? 4,
  is_open: raw.is_open ?? true,
});

function getFeedText(event: FeedEvent): string {
  switch (event.event_type) {
    case 'member_joined': return '파티에 참가했습니다';
    case 'workout_start': return '운동을 시작했습니다 🔥';
    case 'setlog': return event.content
      ? `"${event.content.slice(0, 22)}${event.content.length > 22 ? '…' : ''}"`
      : '세트로그를 등록했습니다';
    case 'workout_end': return '운동을 완료했습니다 💪';
    default: return '';
  }
}

function timeAgo(iso: string): string {
  try {
    const diff = Date.now() - new Date(iso).getTime();
    const m = Math.floor(diff / 60000);
    if (m < 1) return '방금';
    if (m < 60) return `${m}분 전`;
    const h = Math.floor(m / 60);
    if (h < 24) return `${h}시간 전`;
    return `${Math.floor(h / 24)}일 전`;
  } catch {
    return '';
  }
}

interface PartyPanelProps {
  selectedPartyId: string | null;
  onSelectParty: (id: string | null) => void;
}

function PartyPanel({ selectedPartyId, onSelectParty }: PartyPanelProps) {
  const [parties, setParties] = useState<Party[]>([]);
  const [selectedParty, setSelectedParty] = useState<Party | null>(null);
  const [feed, setFeed] = useState<FeedEvent[]>([]);
  const [loading, setLoading] = useState(true);
  const [tab, setTab] = useState<'members' | 'feed'>('members');
  const [copied, setCopied] = useState(false);
  const [matching, setMatching] = useState(false);
  const [mode, setMode] = useState<null | 'create' | 'join'>(null);
  const [createName, setCreateName] = useState('');
  const [joinCode, setJoinCode] = useState('');
  const [formLoading, setFormLoading] = useState(false);
  const [formError, setFormError] = useState('');

  const fetchParties = useCallback(async () => {
    try {
      const { data } = await api.get('/parties');
      const list = Array.isArray(data) ? data : data.parties ?? [];
      setParties(list.map(normalizeParty));
    } catch {
      // ignore
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchParties(); }, [fetchParties]);

  useEffect(() => {
    if (!selectedPartyId) {
      setSelectedParty(null);
      setFeed([]);
      return;
    }
    Promise.all([
      api.get(`/parties/${selectedPartyId}`),
      api.get(`/parties/${selectedPartyId}/feed`),
    ]).then(([partyRes, feedRes]) => {
      setSelectedParty(normalizeParty(partyRes.data));
      const events = Array.isArray(feedRes.data) ? feedRes.data : feedRes.data?.events ?? [];
      setFeed([...events].reverse().slice(0, 30));
    }).catch(() => {});
  }, [selectedPartyId]);

  // Auto-select first party
  useEffect(() => {
    if (!selectedPartyId && parties.length > 0) {
      onSelectParty(String(parties[0].id));
    }
  }, [parties, selectedPartyId, onSelectParty]);

  const handleCreate = async (e: FormEvent) => {
    e.preventDefault();
    if (!createName.trim()) return;
    setFormLoading(true);
    setFormError('');
    try {
      const { data } = await api.post('/parties/', { name: createName.trim() });
      await fetchParties();
      onSelectParty(String(data.id));
      setMode(null);
      setCreateName('');
    } catch (err: any) {
      setFormError(err.response?.data?.detail || err.response?.data?.message || '생성 실패');
    } finally {
      setFormLoading(false);
    }
  };

  const handleJoin = async (e: FormEvent) => {
    e.preventDefault();
    if (!joinCode.trim()) return;
    setFormLoading(true);
    setFormError('');
    try {
      const { data } = await api.post('/parties/join', { invite_code: joinCode.trim().toUpperCase() });
      await fetchParties();
      onSelectParty(String(data.id));
      setMode(null);
      setJoinCode('');
    } catch (err: any) {
      setFormError(err.response?.data?.detail || err.response?.data?.message || '가입 실패');
    } finally {
      setFormLoading(false);
    }
  };

  const handleRandomMatch = async () => {
    setMatching(true);
    try {
      const { data } = await api.post('/parties/random-match');
      await fetchParties();
      onSelectParty(String(data.id));
    } catch {
      // ignore
    } finally {
      setMatching(false);
    }
  };

  const copyInviteCode = async () => {
    const code = selectedParty?.invite_code;
    if (!code) return;
    try {
      await navigator.clipboard.writeText(code);
    } catch {
      // ignore
    }
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%', overflow: 'hidden' }}>

      {/* ── Party List ── */}
      <div style={{ flexShrink: 0 }}>
        <div style={{
          padding: '12px 12px 6px',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
        }}>
          <span style={sectionLabel}>파티</span>
          <div style={{ display: 'flex', gap: '2px' }}>
            <button
              onClick={() => { setMode(mode === 'create' ? null : 'create'); setFormError(''); }}
              style={iconBtn}
              title="파티 만들기"
            >＋</button>
            <button
              onClick={() => { setMode(mode === 'join' ? null : 'join'); setFormError(''); }}
              style={iconBtn}
              title="초대코드 입력"
            >#</button>
            <button
              onClick={handleRandomMatch}
              disabled={matching}
              style={{ ...iconBtn, opacity: matching ? 0.4 : 1 }}
              title="랜덤 매칭"
            >🎲</button>
          </div>
        </div>

        {/* Inline form */}
        {mode === 'create' && (
          <form onSubmit={handleCreate} style={inlineForm}>
            {formError && <div style={formErr}>{formError}</div>}
            <input
              autoFocus
              value={createName}
              onChange={e => setCreateName(e.target.value)}
              placeholder="파티 이름"
              style={inlineInput}
            />
            <div style={{ display: 'flex', gap: '4px' }}>
              <button type="submit" disabled={formLoading} style={submitBtn}>
                {formLoading ? '…' : '만들기'}
              </button>
              <button type="button" onClick={() => { setMode(null); setFormError(''); }} style={cancelBtn}>
                취소
              </button>
            </div>
          </form>
        )}

        {mode === 'join' && (
          <form onSubmit={handleJoin} style={inlineForm}>
            {formError && <div style={formErr}>{formError}</div>}
            <input
              autoFocus
              value={joinCode}
              onChange={e => setJoinCode(e.target.value.toUpperCase())}
              placeholder="초대코드 (예: ABC123)"
              style={{ ...inlineInput, fontFamily: 'monospace', letterSpacing: '2px' }}
            />
            <div style={{ display: 'flex', gap: '4px' }}>
              <button type="submit" disabled={formLoading} style={submitBtn}>
                {formLoading ? '…' : '가입'}
              </button>
              <button type="button" onClick={() => { setMode(null); setFormError(''); }} style={cancelBtn}>
                취소
              </button>
            </div>
          </form>
        )}

        {/* Party list */}
        <div style={{ padding: '0 8px 8px' }}>
          {loading ? (
            <div style={{ padding: '6px 6px', fontSize: '0.75rem', color: '#555' }}>로딩 중…</div>
          ) : parties.length === 0 ? (
            <div style={{ padding: '6px 6px', fontSize: '0.78rem', color: '#555' }}>파티가 없어요. 만들거나 참가해보세요!</div>
          ) : (
            parties.map(party => {
              const sel = selectedPartyId === String(party.id);
              return (
                <div
                  key={party.id}
                  onClick={() => onSelectParty(String(party.id))}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '8px',
                    padding: '7px 8px',
                    borderRadius: '7px',
                    background: sel ? 'rgba(255,61,61,0.08)' : 'transparent',
                    border: sel ? '1px solid rgba(255,61,61,0.22)' : '1px solid transparent',
                    cursor: 'pointer',
                    marginBottom: '2px',
                    transition: 'all 0.12s',
                  }}
                >
                  <div style={{
                    width: '6px', height: '6px',
                    borderRadius: '50%',
                    background: sel ? '#ff3d3d' : '#3a3a3a',
                    flexShrink: 0,
                  }} />
                  <span style={{
                    fontSize: '0.85rem',
                    fontWeight: sel ? 600 : 400,
                    color: sel ? 'var(--color-text-primary)' : 'var(--color-text-secondary)',
                    flex: 1,
                    overflow: 'hidden',
                    textOverflow: 'ellipsis',
                    whiteSpace: 'nowrap',
                  }}>
                    {party.name}
                  </span>
                  <span style={{ fontSize: '0.68rem', color: '#444', flexShrink: 0 }}>
                    {party.member_count}
                  </span>
                </div>
              );
            })
          )}
        </div>
      </div>

      {/* Divider */}
      {selectedParty && (
        <div style={{ borderTop: '1px solid var(--color-border-subtle)', flexShrink: 0 }} />
      )}

      {/* ── Selected Party Detail ── */}
      {selectedParty && (
        <div style={{ display: 'flex', flexDirection: 'column', flex: 1, overflow: 'hidden' }}>

          {/* Party header */}
          <div style={{ padding: '10px 12px 8px', flexShrink: 0 }}>
            <div style={{
              fontSize: '0.88rem',
              fontWeight: 600,
              marginBottom: '3px',
              overflow: 'hidden',
              textOverflow: 'ellipsis',
              whiteSpace: 'nowrap',
            }}>
              {selectedParty.name}
            </div>
            {selectedParty.invite_code && (
              <button
                onClick={copyInviteCode}
                style={{
                  background: 'none',
                  border: 'none',
                  color: copied ? '#4caf50' : '#555',
                  fontSize: '0.7rem',
                  cursor: 'pointer',
                  padding: 0,
                  fontFamily: 'monospace',
                  letterSpacing: '1px',
                  transition: 'color 0.2s',
                }}
              >
                {copied ? '✓ 복사됨' : `# ${selectedParty.invite_code}`}
              </button>
            )}
          </div>

          {/* Tabs */}
          <div style={{
            display: 'flex',
            borderTop: '1px solid var(--color-border-subtle)',
            borderBottom: '1px solid var(--color-border-subtle)',
            flexShrink: 0,
          }}>
            {(['members', 'feed'] as const).map(t => (
              <button
                key={t}
                onClick={() => setTab(t)}
                style={{
                  flex: 1,
                  padding: '7px 4px',
                  background: 'none',
                  border: 'none',
                  borderBottom: tab === t ? '2px solid #ff3d3d' : '2px solid transparent',
                  color: tab === t ? 'var(--color-text-primary)' : 'var(--color-text-secondary)',
                  fontSize: '0.76rem',
                  fontWeight: tab === t ? 600 : 400,
                  cursor: 'pointer',
                  marginBottom: '-1px',
                  transition: 'all 0.12s',
                }}
              >
                {t === 'members' ? `멤버 ${selectedParty.member_count}` : '피드'}
              </button>
            ))}
          </div>

          {/* Tab content */}
          <div style={{ flex: 1, overflowY: 'auto', padding: '6px 8px' }}>
            {tab === 'members' ? (
              selectedParty.members.length === 0 ? (
                <div style={{ padding: '12px 4px', fontSize: '0.78rem', color: '#555' }}>
                  멤버 없음
                </div>
              ) : (
                selectedParty.members.map(member => (
                  <div
                    key={member.id}
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: '8px',
                      padding: '6px 4px',
                      borderRadius: '6px',
                    }}
                  >
                    <div style={{
                      width: '28px',
                      height: '28px',
                      borderRadius: '50%',
                      background: '#1e1e1e',
                      border: '1px solid #333',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      fontSize: '0.8rem',
                      fontWeight: 700,
                      flexShrink: 0,
                      color: '#ff3d3d',
                    }}>
                      {(member.username ?? 'U')[0].toUpperCase()}
                    </div>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{
                        fontSize: '0.82rem',
                        fontWeight: 500,
                        overflow: 'hidden',
                        textOverflow: 'ellipsis',
                        whiteSpace: 'nowrap',
                      }}>
                        {member.username}
                      </div>
                      <div style={{ fontSize: '0.66rem', color: '#555' }}>
                        {member.role === 'owner' ? '👑 파티장' : '멤버'}
                      </div>
                    </div>
                  </div>
                ))
              )
            ) : (
              feed.length === 0 ? (
                <div style={{ padding: '12px 4px', fontSize: '0.78rem', color: '#555' }}>
                  아직 활동 없음
                </div>
              ) : (
                feed.map(event => (
                  <div
                    key={event.id}
                    style={{
                      padding: '6px 4px',
                      borderBottom: '1px solid rgba(255,255,255,0.03)',
                    }}
                  >
                    <div style={{ fontSize: '0.78rem', lineHeight: 1.4 }}>
                      <span style={{ fontWeight: 600, color: 'var(--color-text-primary)' }}>
                        {event.username}
                      </span>
                      {' '}
                      <span style={{ color: 'var(--color-text-secondary)' }}>
                        {getFeedText(event)}
                      </span>
                    </div>
                    <div style={{ fontSize: '0.64rem', color: '#444', marginTop: '2px' }}>
                      {timeAgo(event.created_at)}
                    </div>
                  </div>
                ))
              )
            )}
          </div>
        </div>
      )}
    </div>
  );
}

// ── Styles ──────────────────────────────────────────────────────────────────

const sectionLabel: React.CSSProperties = {
  fontSize: '0.66rem',
  fontWeight: 700,
  color: 'var(--color-text-secondary)',
  letterSpacing: '0.1em',
  textTransform: 'uppercase',
};

const iconBtn: React.CSSProperties = {
  width: '24px',
  height: '24px',
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'center',
  background: 'none',
  border: 'none',
  color: 'var(--color-text-secondary)',
  cursor: 'pointer',
  borderRadius: '5px',
  fontSize: '0.88rem',
  padding: 0,
};

const inlineForm: React.CSSProperties = {
  padding: '6px 8px 4px',
  display: 'flex',
  flexDirection: 'column',
  gap: '5px',
};

const inlineInput: React.CSSProperties = {
  width: '100%',
  padding: '7px 9px',
  background: 'var(--color-bg-surface)',
  border: '1px solid var(--color-border-subtle)',
  borderRadius: '6px',
  color: 'var(--color-text-primary)',
  fontSize: '0.82rem',
  outline: 'none',
  fontFamily: 'inherit',
  boxSizing: 'border-box',
};

const submitBtn: React.CSSProperties = {
  flex: 1,
  padding: '6px',
  background: '#ff3d3d',
  border: 'none',
  borderRadius: '6px',
  color: '#fff',
  fontWeight: 600,
  fontSize: '0.76rem',
  cursor: 'pointer',
};

const cancelBtn: React.CSSProperties = {
  padding: '6px 10px',
  background: 'transparent',
  border: '1px solid var(--color-border-subtle)',
  borderRadius: '6px',
  color: 'var(--color-text-secondary)',
  fontSize: '0.76rem',
  cursor: 'pointer',
};

const formErr: React.CSSProperties = {
  fontSize: '0.72rem',
  color: '#f44336',
  padding: '4px 6px',
  background: 'rgba(244,67,54,0.08)',
  borderRadius: '4px',
};

export default PartyPanel;
