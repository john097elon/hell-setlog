import { useState, useEffect } from 'react';

/**
 * Offline detection bar.
 * Shows a top banner when the browser goes offline and hides on reconnect.
 * Also updates the body data attribute for CSS consumption.
 */
function OfflineDetect() {
  const [offline, setOffline] = useState(false);

  useEffect(() => {
    function handleOnline() {
      setOffline(false);
      document.body.dataset.online = 'true';
    }
    function handleOffline() {
      setOffline(true);
      document.body.dataset.online = 'false';
    }

    // Initial state
    setOffline(!navigator.onLine);
    document.body.dataset.online = String(navigator.onLine);

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);
    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  if (!offline) return null;

  return (
    <div
      style={{
        position: 'fixed',
        top: 0,
        left: 0,
        right: 0,
        zIndex: 9998,
        background: '#e65100',
        color: '#fff',
        textAlign: 'center',
        padding: '10px 16px',
        fontSize: '0.85rem',
        fontWeight: 600,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        gap: '8px',
      }}
    >
      <span>📡</span>
      <span>인터넷 연결이 끊겼습니다 — 일부 기능이 제한됩니다</span>
    </div>
  );
}

export default OfflineDetect;
