import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter } from 'react-router-dom';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import api from '../../api';
import WorkoutRecordsPage from '../../pages/WorkoutRecordsPage';

vi.mock('../../api', () => ({ default: { get: vi.fn(), post: vi.fn() } }));
const get = vi.mocked(api.get);
const post = vi.mocked(api.post);

const exercise = {
  id: 1,
  canonical_name: 'squat',
  display_name_kr: 'Squat',
  unit_kind: 'reps_weight',
  body_part: 'legs',
};

function mockReads(active = true) {
  get.mockImplementation(((url: string) => {
    if (url === '/exercises') return Promise.resolve({ data: [exercise] });
    if (url === '/workouts/') return Promise.resolve({ data: active ? [{ id: 42, status: 'active' }] : [] });
    if (url === '/workout-records/calendar') return Promise.resolve({ data: { days: [] } });
    if (url === '/workout-records') return Promise.resolve({ data: { items: [], has_more: false, next_cursor: null } });
    return Promise.reject(new Error(`Unexpected GET ${url}`));
  }) as never);
}

describe('WorkoutRecordsPage', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockReads();
    post.mockResolvedValue({ data: { id: 7 } } as never);
  });

  it('saves structured sets against the active workout with an idempotency key', async () => {
    const user = userEvent.setup();
    render(<MemoryRouter><WorkoutRecordsPage /></MemoryRouter>);

    await screen.findByText('Squat');
    await user.type(screen.getByLabelText('Set 1 reps'), '10');
    await user.type(screen.getByLabelText('Set 1 weight'), '60');
    await user.click(screen.getByRole('button', { name: 'Save workout' }));

    await waitFor(() => expect(post).toHaveBeenCalledTimes(1));
    expect(post.mock.calls[0][0]).toBe('/workout-records');
    expect(post.mock.calls[0][1]).toMatchObject({
      workout_id: 42,
      exercise_id: 1,
      sets: [{ set_index: 0, reps: 10, weight_kg: 60 }],
    });
    expect(post.mock.calls[0][2]).toMatchObject({
      headers: { 'X-Idempotency-Key': expect.any(String) },
    });
    expect(await screen.findByRole('status')).toHaveTextContent('Squat saved.');
  });

  it('keeps save disabled and offers the session start flow without an active workout', async () => {
    mockReads(false);
    render(<MemoryRouter><WorkoutRecordsPage /></MemoryRouter>);

    expect(await screen.findByRole('link', { name: 'Start workout' })).toHaveAttribute('href', '/workout/session');
    expect(screen.getByRole('button', { name: 'Save workout' })).toBeDisabled();
  });
});