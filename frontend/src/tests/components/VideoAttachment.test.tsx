import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import VideoAttachment from '../../components/VideoAttachment';
import api from '../../api';

vi.mock('../../api', () => ({ default: { get: vi.fn() } }));
const get = vi.mocked(api.get);

describe('VideoAttachment', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    Object.defineProperty(navigator, 'onLine', { configurable: true, value: true });
  });

  it('loads an authenticated playback URL and renders a native inline video', async () => {
    get.mockResolvedValue({ data: { url: 'https://cdn.test/video.mp4' } } as never);
    render(<VideoAttachment path="users/1/video.mp4" posterUrl="poster.jpg" />);
    const video = await screen.findByLabelText('Workout video');
    expect(video).toHaveAttribute('src', 'https://cdn.test/video.mp4');
    expect(video).toHaveAttribute('playsinline');
    expect(video).toHaveAttribute('poster', 'poster.jpg');
    expect(video).not.toHaveAttribute('autoplay');
    expect(get).toHaveBeenCalledWith('/media/users/1/video.mp4/playback');
  });

  it('shows a retry action after playback URL failure', async () => {
    get.mockRejectedValue(new Error('expired URL'));
    render(<VideoAttachment path="video.mp4" />);
    const retry = await screen.findByRole('button', { name: /tap to retry/i });
    await userEvent.setup().click(retry);
    expect(get).toHaveBeenCalledTimes(2);
  });

  it('shows an offline state and does not request playback while offline', async () => {
    Object.defineProperty(navigator, 'onLine', { configurable: true, value: false });
    render(<VideoAttachment path="video.mp4" />);
    expect(await screen.findByText(/unavailable offline/i)).toBeInTheDocument();
    expect(get).not.toHaveBeenCalled();
  });

  it('reserves a stable media container while the playback URL is loading', () => {
    get.mockReturnValue(new Promise(() => {}));
    const { container } = render(<VideoAttachment path="video.mp4" />);
    expect(container.firstChild).toHaveClass('video-attachment');
    expect(container.firstChild).toHaveAttribute('role', 'status');
  });
});
