import { Link, useLocation } from 'react-router-dom';
import type { ReactNode } from 'react';
import { Button } from './ui';

interface LayoutProps {
  children: ReactNode;
}

const NAV_ITEMS = [
  { path: '/parties', label: '파티', icon: '🏠' },
  { path: '/workout', label: '운동', icon: '🔥' },
  { path: '/settings', label: '설정', icon: '⚙️' },
];

const ACTIVE_WORKOUT_PATHS = ['/workout'];

function Layout({ children }: LayoutProps) {
  const location = useLocation();
  const token = localStorage.getItem('token');
  const hideNav = ['/login', '/register'].includes(location.pathname);
  const isActiveWorkout =
    ACTIVE_WORKOUT_PATHS.some((p) => location.pathname.startsWith(p)) &&
    location.pathname !== '/workout';

  const handleLogout = () => {
    localStorage.removeItem('token');
    window.location.href = '/login';
  };

  return (
    <div className={`layout-root ${hideNav ? 'layout-root--no-nav' : ''}`}>
      {/* Desktop top nav (hidden on mobile) */}
      {!hideNav && token && (
        <nav className="nav-top">
          <Link to="/parties" className="nav-top__brand">
            🔥 Hell Setlog
          </Link>
          <div className="nav-top__spacer" />
          <Button variant="ghost" size="sm" onClick={handleLogout}>
            로그아웃
          </Button>
        </nav>
      )}

      {/* Mobile bottom nav (hidden on desktop, hidden on login/register) */}
      {!hideNav && token && (
        <nav className="nav-bottom">
          {NAV_ITEMS.map((item) => {
            const isActive = location.pathname === item.path ||
              (item.path === '/workout' && isActiveWorkout);
            return (
              <Link
                key={item.path}
                to={item.path}
                className={`nav-bottom__item ${isActive ? 'nav-bottom__item--active' : ''}`}
              >
                <span className="nav-bottom__icon">{item.icon}</span>
                <span className="nav-bottom__label">{item.label}</span>
              </Link>
            );
          })}
        </nav>
      )}

      {/* Main content */}
      <main className={`layout-main ${hideNav ? 'layout-main--full' : ''}`}>
        {children}
      </main>
    </div>
  );
}

export default Layout;
