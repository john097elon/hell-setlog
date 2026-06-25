import { useState, type CSSProperties, type FormEvent } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import api from '../api';
import { Alert, Button, Card, PageShell, TextField } from '../components/ui';

function RegisterPage() {
  const navigate = useNavigate();
  const [username, setUsername] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError('');
    try {
      await api.post('/auth/register', { username, email, password });
      navigate('/login');
    } catch (err: any) {
      setError(err.response?.data?.message || '회원가입 실패');
    }
  };

  return (
    <PageShell centered maxWidth={400}>
      <Card style={{ '--card-padding': '40px' } as CSSProperties}>
        <h1 style={{ fontSize: 'var(--font-size-xl)', marginBottom: '8px' }}>🔥 회원가입</h1>
        <p style={{ color: 'var(--color-text-secondary)', marginBottom: '32px' }}>
          파티에 참여할 준비가 되셨나요?
        </p>

        <form onSubmit={handleSubmit}>
          {error && <Alert>{error}</Alert>}

          <TextField
            label="닉네임"
            type="text"
            value={username}
            onChange={(e) => setUsername(e.target.value)}
            required
          />

          <TextField
            label="이메일"
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
          />

          <TextField
            label="비밀번호"
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
          />

          <Button type="submit" fullWidth>
            회원가입
          </Button>
        </form>

        <p style={{ textAlign: 'center', marginTop: '24px', fontSize: '0.9rem', color: 'var(--color-text-secondary)' }}>
          이미 계정이 있으신가요?{' '}
          <Link to="/login">로그인</Link>
        </p>
      </Card>
    </PageShell>
  );
}

export default RegisterPage;
