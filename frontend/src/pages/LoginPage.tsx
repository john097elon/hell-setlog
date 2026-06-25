import { useState, type CSSProperties, type FormEvent } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import api from '../api';
import { Alert, Button, Card, PageShell, TextField } from '../components/ui';

function LoginPage() {
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError('');
    try {
      const { data } = await api.post('/auth/login', { email, password });
      localStorage.setItem('token', data.access_token || data.token);
      navigate('/parties');
    } catch (err: any) {
      setError(err.response?.data?.message || '로그인 실패');
    }
  };

  return (
    <PageShell centered maxWidth={400}>
      <Card style={{ '--card-padding': '40px' } as CSSProperties}>
        <h1 style={{ fontSize: 'var(--font-size-xl)', marginBottom: '8px' }}>🔥 Hell Setlog</h1>
        <p style={{ color: 'var(--color-text-secondary)', marginBottom: '32px' }}>
          지옥의 피트니스 파티에 오신 것을 환영합니다
        </p>

        <form onSubmit={handleSubmit}>
          {error && <Alert>{error}</Alert>}

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
            로그인
          </Button>
        </form>

        <p style={{ textAlign: 'center', marginTop: '24px', fontSize: '0.9rem', color: 'var(--color-text-secondary)' }}>
          계정이 없으신가요?{' '}
          <Link to="/register">회원가입</Link>
        </p>
      </Card>
    </PageShell>
  );
}

export default LoginPage;
