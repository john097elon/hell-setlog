import { useLocation, useNavigate } from 'react-router-dom';
import type { ReactNode } from 'react';

interface LayoutProps {
  children: ReactNode;
}

function Layout({ children }: LayoutProps) {
  const location = useLocation();
  const navigate = useNavigate();
  const token = localStorage.getItem('token');
  const hideNav = ['/login', '/register'].includes(location.pathname);
  const isSettings = location.pathname === '/settings';

  return (
    <div style={{ height: '100vh', display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
      {!hideNav && token && (
        <nav style={{
          height: '48px',
          background: 'var(--color-bg-muted)',
          borderBottom: '1px solid var(--color-border-subtle)',
          padding: '0 16px',
          display: 'flex',
          alignItems: 'center',
          gap: '12px',
          flexShrink: 0,
        }}>
          <span
            onClick={() => navigate('/')}
            style={{
              fontWeight: 800,
              fontSize: '0.9rem',
              letterSpacing: '-0.01em',
              color: 'var(--color-text-primary)',
              cursor: 'pointer',
              userSelect: 'none',
            }}
          >
            🔥 Hell Setlog
          </span>

          <div style={{ flex: 1 }} />

          <button
            onClick={() => (isSettings ? navigate(-1) : navigate('/settings'))}
            style={{
              background: 'none',
              border: 'none',
              color: isSettings ? 'var(--color-text-primary)' : 'var(--color-text-secondary)',
              fontSize: '0.82rem',
              cursor: 'pointer',
              fontFamily: 'inherit',
              padding: '5px 9px',
              borderRadius: '6px',
            }}
          >
            {isSettings ? '← 돌아가기' : '⚙️ 설정'}
          </button>

          <button
            onClick={() => {
              localStorage.removeItem('token');
              window.location.href = '/login';
            }}
            style={{
              background: 'none',
              border: '1px solid var(--color-border-subtle)',
              color: 'var(--color-text-secondary)',
              fontSize: '0.78rem',
              cursor: 'pointer',
              fontFamily: 'inherit',
              padding: '5px 11px',
              borderRadius: '6px',
            }}
          >
            로그아웃
          </button>
        </nav>
      )}

      <div style={{ flex: 1, overflow: 'hidden', display: 'flex', flexDirection: 'column' }}>
        {hideNav || !token ? (
          // Auth pages: scrollable, centered
          <div style={{ flex: 1, overflowY: 'auto' }}>
            {children}
          </div>
        ) : isSettings ? (
          // Settings: scrollable with padding
          <div style={{ flex: 1, overflowY: 'auto', padding: '28px 24px' }}>
            {children}
          </div>
        ) : (
          // Main 3-panel layout: full height, no scroll
          <div style={{ flex: 1, overflow: 'hidden' }}>
            {children}
          </div>
        )}
      </div>
    </div>
  );
}

export default Layout;
