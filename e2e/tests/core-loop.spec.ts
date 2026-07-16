import { expect, test, type APIRequestContext } from '@playwright/test';

const apiBase = process.env.E2E_API_URL || 'http://localhost:8001';
const password = 'pass1234e2e';
const auth = (token: string) => ({ Authorization: `Bearer ${token}` });

type Session = { email: string; token: string; username: string };

function clientIp(seed: string) {
  let hash = 0;
  for (const character of seed) hash = ((hash << 5) - hash + character.charCodeAt(0)) | 0;
  return `198.51.${Math.abs(hash >> 8) % 254}.${Math.abs(hash) % 254 + 1}`;
}

async function newUser(request: APIRequestContext, prefix: string): Promise<Session> {
  const username = `${prefix}${Date.now()}${Math.random().toString(16).slice(2, 8)}`;
  const email = `${username}@test.com`;
  const headers = { 'X-Forwarded-For': clientIp(username) };
  const register = await request.post(`${apiBase}/api/auth/register`, {
    headers,
    data: { username, email, password },
  });
  expect(register.status()).toBe(201);
  const login = await request.post(`${apiBase}/api/auth/login`, {
    headers,
    data: { email, password },
  });
  expect(login.status()).toBe(200);
  return { email, token: (await login.json()).access_token as string, username };
}

test('registers through the UI and accepts the credentials', async ({ page, request }) => {
  const suffix = `${Date.now()}${Math.random().toString(16).slice(2, 8)}`;
  const username = `e2eui${suffix}`;
  const email = `${username}@test.com`;

  await page.goto('/register');
  await page.getByLabel('닉네임').fill(username);
  await page.getByLabel('이메일').fill(email);
  await page.getByLabel('비밀번호').fill(password);
  const registration = page.waitForResponse(
    (response) => response.url().endsWith('/api/auth/register') && response.request().method() === 'POST',
  );
  await page.getByRole('button', { name: '회원가입' }).click();
  expect((await registration).status()).toBe(201);
  await expect(page).toHaveURL(/\/login$/);

  const login = await request.post(`${apiBase}/api/auth/login`, {
    headers: { 'X-Forwarded-For': clientIp(username) },
    data: { email, password },
  });
  expect(login.status()).toBe(200);
  expect((await login.json()).access_token).toBeTruthy();
});

test('creates and lists a party with an independent session', async ({ request }) => {
  const session = await newUser(request, 'e2eparty');
  const partyName = `E2E Party ${Date.now()}`;
  const created = await request.post(`${apiBase}/api/parties/`, {
    headers: auth(session.token),
    data: { name: partyName },
  });
  expect(created.status()).toBe(201);

  const parties = await request.get(`${apiBase}/api/parties/`, {
    headers: auth(session.token),
  });
  expect(parties.status()).toBe(200);
  expect((await parties.json()).some((party: { name: string }) => party.name === partyName)).toBe(true);
});

test('ends a workout idempotently and persists body-part growth', async ({ request }) => {
  const session = await newUser(request, 'e2egrowth');
  const workout = await request.post(`${apiBase}/api/workouts/`, {
    headers: auth(session.token),
    data: { notes: 'E2E workout' },
  });
  expect(workout.status()).toBe(201);
  const workoutId = (await workout.json()).id as number;

  for (const [type, content] of [['start', '운동 시작'], ['mid', '가슴 세트'], ['mid', '팔 세트']]) {
    const setlog = await request.post(`${apiBase}/api/workouts/${workoutId}/setlogs`, {
      headers: auth(session.token),
      data: { type, content },
    });
    expect(setlog.status()).toBe(201);
  }

  const ended = await request.post(`${apiBase}/api/workouts/${workoutId}/end`, {
    headers: auth(session.token),
  });
  expect(ended.status()).toBe(200);
  const result = await ended.json();
  expect(result.body_stats).toHaveLength(7);
  expect(result.workout.status).toBe('ended');
  expect(result.workout.ended_at).not.toBeNull();

  const persisted = await request.get(`${apiBase}/api/workouts/${workoutId}`, {
    headers: auth(session.token),
  });
  expect(persisted.status()).toBe(200);
  expect((await persisted.json()).status).toBe('ended');

  const endedAgain = await request.post(`${apiBase}/api/workouts/${workoutId}/end`, {
    headers: auth(session.token),
  });
  expect(endedAgain.status()).toBe(200);
});

test('prevents a non-owner from reading another users workout', async ({ request }) => {
  const owner = await newUser(request, 'e2ebolaowner');
  const outsider = await newUser(request, 'e2ebolaoutsider');
  const workout = await request.post(`${apiBase}/api/workouts/`, {
    headers: auth(owner.token),
    data: {},
  });
  expect(workout.status()).toBe(201);
  const workoutId = (await workout.json()).id as number;

  const denied = await request.get(`${apiBase}/api/workouts/${workoutId}`, {
    headers: auth(outsider.token),
  });
  expect(denied.status()).toBe(404);
});
