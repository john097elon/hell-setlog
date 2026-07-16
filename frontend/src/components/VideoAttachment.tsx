import { useCallback, useEffect, useState } from 'react';
import api from '../api';

interface PlaybackResponse {
  url: string;
  expires_in_seconds?: number;
}

interface VideoAttachmentProps {
  path: string;
  posterUrl?: string | null;
  title?: string;
}

export default function VideoAttachment({
  path,
  posterUrl,
  title = 'Workout video',
}: VideoAttachmentProps) {
  const [url, setUrl] = useState('');
  const [state, setState] = useState<'loading' | 'ready' | 'offline' | 'error'>('loading');

  const load = useCallback(() => {
    if (!navigator.onLine) {
      setState('offline');
      return;
    }
    setState('loading');
    api.get<PlaybackResponse>(`/media/${path}/playback`)
      .then(({ data }) => {
        setUrl(data.url);
        setState('ready');
      })
      .catch(() => setState(navigator.onLine ? 'error' : 'offline'));
  }, [path]);

  useEffect(() => {
    load();
    const onOnline = () => load();
    const onOffline = () => setState('offline');
    window.addEventListener('online', onOnline);
    window.addEventListener('offline', onOffline);
    return () => {
      window.removeEventListener('online', onOnline);
      window.removeEventListener('offline', onOffline);
    };
  }, [load]);

  if (state !== 'ready') {
    return (
      <div className="video-attachment video-attachment--status" role="status">
        {state === 'loading' && 'Loading video…'}
        {state === 'offline' && 'Video unavailable offline.'}
        {state === 'error' && (
          <button type="button" onClick={load} className="video-attachment__retry">
            Video unavailable. Tap to retry.
          </button>
        )}
      </div>
    );
  }

  return (
    <div className="video-attachment">
      <video
        src={url}
        poster={posterUrl || undefined}
        controls
        playsInline
        preload="metadata"
        aria-label={title}
      />
    </div>
  );
}