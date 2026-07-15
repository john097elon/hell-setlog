import { useEffect, useState, type CSSProperties, type FormEvent } from 'react';
import api from '../api';
import { Alert, Button, Card, PageShell, TextField } from '../components/ui';

interface Character {
  name: string;
  avatar_seed: string;
  avatar_url?: string;
}

const WORKOUT_TAG_OPTIONS = ['근력', '유산소', '홈트', '크로스핏', '요가', '러닝', '수영', '기타'];

function SettingsPage() {
  const [character, setCharacter] = useState<any>(null);
  const [name, setName] = useState('');
  const [avatarSeed, setAvatarSeed] = useState('');
  const [avatarUrl, setAvatarUrl] = useState('/assets/avatars/default.svg');
  const [initialAvatarUrl, setInitialAvatarUrl] = useState('/assets/avatars/default.svg');
  const [workoutTags, setWorkoutTags] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');

  const getPreviewUrl = (seedStr: string) => {
    if (!seedStr) return '/assets/avatars/default.svg';
    let stageNum = 1;
    const parts = seedStr.split(',').map(p => p.trim());
    let hasOverride = false;
    for (const part of parts) {
      if (part.startsWith('stage_')) {
        const parsed = parseInt(part.split('_')[1], 10);
        if (!isNaN(parsed)) {
          stageNum = parsed;
          hasOverride = true;
        }
      }
    }
    if (!hasOverride && character && character.body_stats) {
      const totalLevel = character.body_stats.reduce((sum: number, s: any) => sum + s.level, 0);
      if (totalLevel < 15) {
        stageNum = 1;
      } else if (totalLevel < 30) {
        stageNum = 2;
      } else {
        stageNum = 3;
      }
    }
    if (stageNum < 1) stageNum = 1;
    if (stageNum > 3) stageNum = 3;

    const version = character?.asset_version || 'v2';
    const cdnUrl = character?.avatar_url && character.avatar_url.includes('://')
      ? character.avatar_url.split('/assets/avatars/')[0]
      : '';

    const path = `/assets/avatars/stage_${stageNum}.svg?v=${version}`;
    return cdnUrl ? `${cdnUrl}${path}` : path;
  };

  useEffect(() => {
    api
      .get('/auth/me')
      .then(({ data }) => {
        const character: Character | undefined = data.character;
        if (character) {
          setCharacter(character);
          setName(character.name);
          setAvatarSeed(character.avatar_seed);
          const url = character.avatar_url || data.avatar_url || '/assets/avatars/default.svg';
          setAvatarUrl(url);
          setInitialAvatarUrl(url);
        }
        // Parse workout_tags from string JSON
        if (data.workout_tags) {
          try {
            const parsed = JSON.parse(data.workout_tags);
            if (Array.isArray(parsed)) {
              setWorkoutTags(parsed);
            }
          } catch {
            // ignore invalid JSON
          }
        }
      })
      .catch((err) => {
        setError(err.response?.data?.message || err.response?.data?.detail || '프로필을 불러오지 못했습니다');
      })
      .finally(() => setLoading(false));
  }, []);

  const handleAvatarSeedChange = (val: string) => {
    setAvatarSeed(val);
    if (!val) {
      setAvatarUrl(initialAvatarUrl);
    } else {
      setAvatarUrl(getPreviewUrl(val));
    }
  };

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setMessage('');
    setError('');
    setSaving(true);
    try {
      const res = await api.patch('/characters/me', { name, avatar_seed: avatarSeed });
      if (res.data) {
        setCharacter(res.data);
        if (res.data.avatar_url) {
          setAvatarUrl(res.data.avatar_url);
          setInitialAvatarUrl(res.data.avatar_url);
        }
      }
      // Save workout tags
      await api.patch('/users/me/tags', { workout_tags: JSON.stringify(workoutTags) });
      setMessage('설정이 저장되었습니다');
    } catch (err: any) {
      setError(err.response?.data?.message || err.response?.data?.detail || '저장에 실패했습니다');
    } finally {
      setSaving(false);
    }
  };

  const toggleTag = (tag: string) => {
    setWorkoutTags((prev) =>
      prev.includes(tag) ? prev.filter((t) => t !== tag) : [...prev, tag]
    );
  };


  return (
    <PageShell centered maxWidth={500}>
      <Card style={{ '--card-padding': '40px' } as CSSProperties}>
        <h1 style={{ fontSize: 'var(--font-size-xl)', marginBottom: '8px' }}>⚙️ 설정</h1>
        <p style={{ color: 'var(--color-text-secondary)', marginBottom: '32px' }}>
          캐릭터와 운동 취향을 설정하세요
        </p>

        {loading ? (
          <p style={{ color: 'var(--color-text-secondary)' }}>불러오는 중...</p>
        ) : (
          <form onSubmit={handleSubmit}>
            {error && <Alert>{error}</Alert>}
            {message && <Alert variant="success">{message}</Alert>}

            <div style={{ display: 'flex', justifyContent: 'center', marginBottom: '24px' }}>
              <img
                src={avatarUrl}
                alt="아바타 미리보기"
                style={{
                  width: '96px',
                  height: '96px',
                  borderRadius: '50%',
                  border: '2px solid var(--color-border-subtle)',
                  background: 'var(--color-bg-muted)',
                }}
              />
            </div>

            <TextField
              label="이름"
              value={name}
              onChange={(e) => setName(e.target.value)}
              required
            />

            <TextField
              label="아바타 시드"
              value={avatarSeed}
              onChange={(e) => handleAvatarSeedChange(e.target.value)}
              placeholder="고유한 시드 값을 입력하세요"
            />

            {/* Workout Tags */}
            <div style={{ marginBottom: '24px', marginTop: '24px' }}>
              <label
                style={{
                  display: 'block',
                  marginBottom: '10px',
                  fontSize: '0.85rem',
                  fontWeight: 600,
                  color: 'var(--color-text-secondary)',
                }}
              >
                🏋️ 운동 취향 태그
              </label>
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px' }}>
                {WORKOUT_TAG_OPTIONS.map((tag) => {
                  const selected = workoutTags.includes(tag);
                  return (
                    <button
                      key={tag}
                      type="button"
                      onClick={() => toggleTag(tag)}
                      style={{
                        padding: '6px 16px',
                        borderRadius: '999px',
                        border: selected ? '1px solid #ff3d3d' : '1px solid var(--color-border-subtle)',
                        background: selected ? '#ff3d3d' : 'transparent',
                        color: selected ? '#fff' : 'var(--color-text-secondary)',
                        fontSize: '0.85rem',
                        fontWeight: selected ? 700 : 500,
                        cursor: 'pointer',
                        transition: 'all 0.15s ease',
                      }}
                    >
                      {tag}
                    </button>
                  );
                })}
              </div>
            </div>

            <Button type="submit" fullWidth disabled={saving}>
              {saving ? '저장 중...' : '저장'}
            </Button>
          </form>
        )}
      </Card>
    </PageShell>
  );
}

export default SettingsPage;
