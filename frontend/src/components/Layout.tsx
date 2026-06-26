import { Link, useLocation, useNavigate } from 'react-router-dom';
import type { ReactNode } from 'react';
import { Button } from './ui';

interface LayoutProps {
  children: ReactNode;
}

function Layout({ children }: LayoutProps) {
  const location = useLocation();
  const navigate = useNavigate();
  const token = localStorage.getItem('token');
  const hideNav = ['/login', '/register'].includes(location.pathname);
  const isSettingsPage = location.pathname === '/settings';

  return (
    <div style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column' }}>
      {!hideNav && token && (
        <nav style={{
          background: 'var(--color-bg-muted)',
          borderBottom: '1px solid var(--color-border-subtle)',
          padding: '12px 24px',
          display: 'flex',
          gap: '24px',
          alignItems: 'center',
        }}>
          <Link to="/parties" style={{ fontWeight: 700, fontSize: '1.1rem' }}>
            🔥 Hell Setlog
          </Link>
          <button
            onClick={() => { if (isSettingsPage) { navigate(-1); } else { navigate('/settings'); } }}
            style={{
              background: 'none',
              border: 'none',
              color: 'var(--text-primary)',
              fontWeight: isSettingsPage ? 700 : 400,
              fontSize: '1rem',
              cursor: 'pointer',
              fontFamily: 'inherit',
              padding: 0,
            }}
          >
            ⚙️ 설정
          </button>
          <div style={{ flex: 1 }} />
          <Button
            variant="ghost"
            size="sm"
            onClick={() => {
              localStorage.removeItem('token');
              window.location.href = '/login';
            }}
          >
            로그아웃
          </Button>
        </nav>
      )}
      <main style={{ flex: 1, padding: hideNav ? 0 : '32px 24px' }}>
        {children}
      </main>
    </div>
  );
}

export default Layout;
