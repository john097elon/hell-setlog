export const MAX_VIDEO_BYTES = 10 * 1024 * 1024;
export const MAX_VIDEO_SECONDS = 60;

export type VideoPreflight = {
  durationSeconds: number;
};

export async function validateVideoFile(file: File): Promise<VideoPreflight> {
  if (file.type !== 'video/mp4') {
    throw new Error('Videos must be MP4 files.');
  }
  if (file.size > MAX_VIDEO_BYTES) {
    throw new Error('This video is too large. Choose an MP4 smaller than 10 MB.');
  }

  const video = document.createElement('video');
  if (!video.canPlayType('video/mp4')) {
    throw new Error('This device cannot play MP4 video.');
  }

  const objectUrl = URL.createObjectURL(file);
  try {
    const durationSeconds = await new Promise<number>((resolve, reject) => {
      const timeout = window.setTimeout(
        () => reject(new Error('Could not inspect this video. Try another MP4 file.')),
        10_000,
      );
      const finish = (callback: () => void) => {
        window.clearTimeout(timeout);
        callback();
      };
      video.preload = 'metadata';
      video.muted = true;
      video.playsInline = true;
      video.onloadedmetadata = () => finish(() => resolve(video.duration));
      video.onerror = () => finish(() => reject(new Error('This MP4 cannot be played on this device.')));
      video.src = objectUrl;
      video.load();
    });

    if (!Number.isFinite(durationSeconds) || durationSeconds <= 0) {
      throw new Error('Could not read this video duration.');
    }
    if (durationSeconds > MAX_VIDEO_SECONDS) {
      throw new Error('Videos must be 60 seconds or shorter.');
    }
    return { durationSeconds };
  } finally {
    video.removeAttribute('src');
    video.load();
    URL.revokeObjectURL(objectUrl);
  }
}