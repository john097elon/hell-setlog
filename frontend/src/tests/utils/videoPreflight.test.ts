import { describe, expect, it } from 'vitest';
import { MAX_VIDEO_BYTES, validateVideoFile } from '../../utils/videoPreflight';

describe('validateVideoFile', () => {
  it('rejects non-MP4 video before reading metadata', async () => {
    const file = new File(['video'], 'clip.mov', { type: 'video/quicktime' });
    await expect(validateVideoFile(file)).rejects.toThrow('Videos must be MP4 files.');
  });

  it('rejects files above the 10 MiB contract limit', async () => {
    const file = new File([new Uint8Array(MAX_VIDEO_BYTES + 1)], 'clip.mp4', { type: 'video/mp4' });
    await expect(validateVideoFile(file)).rejects.toThrow('smaller than 10 MB');
  });
});