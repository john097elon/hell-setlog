import { expect, test } from '@playwright/test';

const base = process.env.E2E_API_URL || 'http://localhost:8001';
const password = 'pass1234';
const auth = (token: string) => ({ Authorization: `Bearer ${token}` });

async function newUser(request: any, prefix: string) {
  const username = `${prefix}${Date.now()}${Math.random().toString(16).slice(2, 8)}`;
  const register = await request.post(`${base}/api/auth/register`, { data: { username, email: `${username}@test.com`, password } });
  expect(register.status()).toBe(201);
  const login = await request.post(`${base}/api/auth/login`, { data: { username, password } });
  expect(login.status()).toBe(200);
  return (await login.json()).access_token as string;
}

test.describe('mobile core journeys', () => {
  test('records a set, ends the workout, and exposes body-part growth', async ({ request }) => {
    const token = await newUser(request, 'matrix-record-');
    const workout = await request.post(`${base}/api/workouts/`, { headers: auth(token), data: { notes: 'mobile matrix record' } });
    expect(workout.status()).toBe(201);
    const workoutId = (await workout.json()).id;
    const exercises = await request.get(`${base}/api/exercises`, { headers: auth(token) });
    expect(exercises.status()).toBe(200);
    const exercise = (await exercises.json())[0];
    expect(exercise?.id).toBeTruthy();
    const record = await request.post(`${base}/api/workout-records`, { headers: { ...auth(token), 'X-Idempotency-Key': `matrix-${workoutId}` }, data: { workout_id: workoutId, exercise_id: exercise.id, performed_at: new Date().toISOString(), sets: [{ set_index: 0, reps: 10, weight_kg: 20 }] } });
    expect(record.status()).toBe(201);
    const ended = await request.post(`${base}/api/workouts/${workoutId}/end`, { headers: auth(token) });
    expect(ended.status()).toBe(200);
    const growth = await ended.json();
    expect(growth.status).toBe('ended');
    expect(growth.body_stats).toEqual(expect.arrayContaining([expect.objectContaining({ part: expect.any(String), level: expect.any(Number) })]));
  });

  test('uploads a party video, returns playback, and denies a non-member', async ({ request }) => {
    const owner = await newUser(request, 'matrix-video-owner-');
    const outsider = await newUser(request, 'matrix-video-outsider-');
    const party = await request.post(`${base}/api/parties/`, { headers: auth(owner), data: { name: 'Mobile matrix party' } });
    expect(party.status()).toBe(201);
    const partyId = (await party.json()).id;
    const upload = await request.post(`${base}/api/media`, { headers: auth(owner), multipart: { party_id: String(partyId), file: { name: 'matrix.mp4', mimeType: 'video/mp4', buffer: Buffer.from('matrix-video') } } });
    expect(upload.status()).toBe(201);
    const key = (await upload.json()).key as string;
    expect(key).toMatch(/^users\/\d+\/.*\.mp4$/);
    const workout = await request.post(`${base}/api/workouts/`, { headers: auth(owner), data: { party_id: partyId } });
    expect(workout.status()).toBe(201);
    const workoutId = (await workout.json()).id;
    const setlog = await request.post(`${base}/api/workouts/${workoutId}/setlogs`, { headers: auth(owner), data: { type: 'mid', content: 'party video', file_path: key } });
    expect(setlog.status()).toBe(201);
    const playback = await request.get(`${base}/api/media/${key}/playback`, { headers: auth(owner) });
    expect(playback.status()).toBe(200);
    expect((await playback.json()).url).toBeTruthy();
    const denied = await request.get(`${base}/api/media/${key}/playback`, { headers: auth(outsider) });
    expect(denied.status()).toBe(403);
  });

  test('keeps the login surface usable without horizontal overflow and with 44px controls', async ({ page }) => {
    await page.goto('/login');
    await expect(page).toHaveTitle(/setlog/i);
    const metrics = await page.evaluate(() => ({ viewport: window.innerWidth, scrollWidth: document.documentElement.scrollWidth, controls: Array.from(document.querySelectorAll('button, a, input, select, textarea')).map((el) => { const rect = el.getBoundingClientRect(); return { width: rect.width, height: rect.height }; }) }));
    expect(metrics.scrollWidth).toBeLessThanOrEqual(metrics.viewport + 1);
    expect(metrics.controls.every(({ width, height }) => width >= 44 && height >= 44)).toBeTruthy();
  });
});
