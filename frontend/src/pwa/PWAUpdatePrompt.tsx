import { useRegisterSW } from 'virtual:pwa-register/react';

/**
 * PWA update prompt component.
 * Shows a dismissable banner when a new service worker version is waiting.
 * The update is applied on user confirmation.
 */
function PWAUpdatePrompt() {
  const {
    needRefresh: [needRefresh, setNeedRefresh],
    offlineReady: [offlineReady, setOfflineReady],
    updateServiceWorker,
  } = useRegisterSW({
    onOfflineReady() {
      console.info('[PWA] App ready for offline use');
    },
  });

  const handleUpdate = () => {
    updateServiceWorker(true);
    setNeedRefresh(false);
    setOfflineReady(false);
  };

  const handleDismiss = () => {
    setNeedRefresh(false);
    setOfflineReady(false);
  };

  // Offline-ready banner (first install)
  if (offlineReady) {
    return (
      <div
        style={{
          position: 'fixed',
          bottom: 'max(16px, env(safe-area-inset-bottom))',
          left: '16px',
          right: '16px',
          zIndex: 9999,
          background: 'var(--color-bg-surface, #242424)',
          border: '1px solid var(--color-border-subtle, #333)',
          borderRadius: '14px',
          padding: '16px 20px',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          gap: '12px',
          boxShadow: '0 8px 32px rgba(0,0,0,0.5)',
        }}
      >
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontWeight: 700, fontSize: '0.95rem', marginBottom: '2px', color: 'var(--color-text-primary, #f0f0f0)' }}>
            오프라인 사용 가능
          </div>
          <div style={{ fontSize: '0.8rem', color: 'var(--color-text-secondary, #a0a0a0)' }}>
            인터넷 없이도 앱을 사용할 수 있습니다
          </div>
        </div>
        <button
          onClick={handleDismiss}
          style={{
            padding: '8px 18px',
            background: 'var(--color-brand-500, #ff3d3d)',
            border: 'none',
            borderRadius: '8px',
            color: '#fff',
            fontSize: '0.85rem',
            fontWeight: 700,
            cursor: 'pointer',
            fontFamily: 'inherit',
            flexShrink: 0,
          }}
        >
          확인
        </button>
      </div>
    );
  }

  if (!needRefresh) return null;

  return (
    <div
      style={{
        position: 'fixed',
        bottom: 'max(16px, env(safe-area-inset-bottom))',
        left: '16px',
        right: '16px',
        zIndex: 9999,
        background: 'var(--color-bg-surface, #242424)',
        border: '1px solid var(--color-border-subtle, #333)',
        borderRadius: '14px',
        padding: '16px 20px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        gap: '12px',
        boxShadow: '0 8px 32px rgba(0,0,0,0.5)',
      }}
    >
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontWeight: 700, fontSize: '0.95rem', marginBottom: '2px', color: 'var(--color-text-primary, #f0f0f0)' }}>
          새 버전이 있습니다
        </div>
        <div style={{ fontSize: '0.8rem', color: 'var(--color-text-secondary, #a0a0a0)' }}>
          업데이트를 적용하면 최신 기능을 사용할 수 있습니다
        </div>
      </div>
      <div style={{ display: 'flex', gap: '8px', flexShrink: 0 }}>
        <button
          onClick={handleDismiss}
          style={{
            padding: '8px 14px',
            background: 'transparent',
            border: '1px solid var(--color-border-subtle, #333)',
            borderRadius: '8px',
            color: 'var(--color-text-secondary, #a0a0a0)',
            fontSize: '0.85rem',
            fontWeight: 500,
            cursor: 'pointer',
            fontFamily: 'inherit',
          }}
        >
          나중에
        </button>
        <button
          onClick={handleUpdate}
          style={{
            padding: '8px 18px',
            background: 'var(--color-brand-500, #ff3d3d)',
            border: 'none',
            borderRadius: '8px',
            color: '#fff',
            fontSize: '0.85rem',
            fontWeight: 700,
            cursor: 'pointer',
            fontFamily: 'inherit',
          }}
        >
          업데이트
        </button>
      </div>
    </div>
  );
}

export default PWAUpdatePrompt;
