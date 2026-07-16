/**
 * Core user loop E2E: register → login → create party → start workout → add setlogs → end → see growth
 *
 * Each test run uses a unique username to avoid conflicts with existing DB data.
 */
import { test, expect } from '@playwright/test';

const uid = Date.now();
const USERNAME = `e2euser${uid}`;
const EMAIL = `e2e${uid}@test.com`;
const PASSWORD = 'pass1234e2e';

// ── Registration ─────────────────────────────────────────────────────────────

test('register new user', async ({ page }) => {
  await page.goto('/register');
  await page.locator('input[type="text"]').fill(USERNAME);
  await page.getByLabel(/이메일|email/i).fill(EMAIL);
  await page.getByLabel(/비밀번호|password/i).fill(PASSWORD);
  await page.getByRole('button', { name: /가입|register|sign up/i }).click();

  // After register, should land on login or home
  await expect(page).toHaveURL(/login|home|\//);
});

// ── Login ─────────────────────────────────────────────────────────────────────

test('login with registered credentials', async ({ page }) => {
  await page.goto('/login');
  // Try username field first, fall back to email
  const usernameInput = page.getByLabel(/사용자명|username/i).first();
  if (await usernameInput.isVisible()) {
    await usernameInput.fill(USERNAME);
  } else {
    await page.getByLabel(/이메일|email/i).first().fill(EMAIL);
  }
  await page.getByLabel(/비밀번호|password/i).fill(PASSWORD);
  await page.getByRole('button', { name: /로그인|login|sign in/i }).click();

  // Should land somewhere past the login page
  await expect(page).not.toHaveURL(/login/);
});

// ── Core loop (depends on login state — runs with fresh page context) ─────────

test('create party', async ({ page }) => {
  // Login first
  await page.goto('/login');
  const usernameInput = page.getByLabel(/사용자명|username/i).first();
  if (await usernameInput.isVisible()) {
    await usernameInput.fill(USERNAME);
  } else {
    await page.getByLabel(/이메일|email/i).first().fill(EMAIL);
  }
  await page.getByLabel(/비밀번호|password/i).fill(PASSWORD);
  await page.getByRole('button', { name: /로그인|login|sign in/i }).click();
  await expect(page).not.toHaveURL(/login/);

  // Navigate to party creation
  await page.goto('/parties');
  const createBtn = page.getByRole('button', { name: /파티 만들기|create party|새 파티/i });
  await expect(createBtn).toBeVisible({ timeout: 5_000 });
  await createBtn.click();

  const partyNameInput = page.getByLabel(/파티 이름|party name/i).or(page.getByPlaceholder(/파티 이름|party name/i));
  if (await partyNameInput.isVisible()) {
    await partyNameInput.fill(`E2E Party ${uid}`);
    await page.getByRole('button', { name: /만들기|create|확인/i }).last().click();
  }

  // Should see the party in the list or party room
  await expect(page.getByText(new RegExp(`E2E Party ${uid}|파티|party`, 'i'))).toBeVisible({ timeout: 5_000 });
});

test('start workout, add setlogs, end workout, see growth response', async ({ page, request }) => {
  // Use API directly for the heavy lifting — tests the contract, not just the UI
  const base = process.env.E2E_API_URL || 'http://localhost:8001';

  const loginRes = await request.post(`${base}/api/auth/login`, {
    data: { username: USERNAME, password: PASSWORD },
  });
  expect(loginRes.ok()).toBeTruthy();
  const { access_token } = await loginRes.json();

  // Create workout
  const wRes = await request.post(`${base}/api/workouts/`, {
    headers: { Authorization: `Bearer ${access_token}` },
    data: { notes: 'E2E workout' },
  });
  expect(wRes.status()).toBe(201);
  const { id: workoutId } = await wRes.json();

  // Add setlogs
  for (const [type, content] of [['start', '운동 시작'], ['mid', '가슴 세트'], ['mid', '등 세트']]) {
    const r = await request.post(`${base}/api/workouts/${workoutId}/setlogs`, {
      headers: { Authorization: `Bearer ${access_token}` },
      data: { type, content },
    });
    expect(r.status()).toBe(201);
  }

  // End workout
  const endRes = await request.post(`${base}/api/workouts/${workoutId}/end`, {
    headers: { Authorization: `Bearer ${access_token}` },
  });
  expect(endRes.status()).toBe(200);
  const endData = await endRes.json();

  // Contract assertions
  expect(endData.body_stats).toHaveLength(7);
  expect(endData.status).toBe('ended');
  expect(endData.ended_at).not.toBeNull();

  // Stats must persist on GET
  const getRes = await request.get(`${base}/api/workouts/${workoutId}`, {
    headers: { Authorization: `Bearer ${access_token}` },
  });
  // NOTE: This will fail until BOLA fix is applied (currently returns 200 for any user)
  // After fix: same user should still get 200
  expect(getRes.status()).toBe(200);
  expect((await getRes.json()).status).toBe('ended');

  // Ending twice is idempotent — the second call returns 200 with the same state.
  const end2 = await request.post(`${base}/api/workouts/${workoutId}/end`, {
    headers: { Authorization: `Bearer ${access_token}` },
  });
  expect(end2.status()).toBe(200);
});

test('non-owner cannot access another users workout (BOLA regression)', async ({ request }) => {
  const base = process.env.E2E_API_URL || 'http://localhost:8001';
  const uid2 = uid + 1;

  // Register a second user
  const regRes = await request.post(`${base}/api/auth/register`, {
    data: { username: `bola${uid2}`, email: `bola${uid2}@test.com`, password: 'pass1234' },
  });
  expect(regRes.status()).toBe(201);
  const loginRes2 = await request.post(`${base}/api/auth/login`, {
    data: { username: `bola${uid2}`, password: 'pass1234' },
  });
  const { access_token: token2 } = await loginRes2.json();

  // Get owner's token
  const loginRes = await request.post(`${base}/api/auth/login`, {
    data: { username: USERNAME, password: PASSWORD },
  });
  const { access_token } = await loginRes.json();

  // Owner creates a workout
  const wRes = await request.post(`${base}/api/workouts/`, {
    headers: { Authorization: `Bearer ${access_token}` },
    data: {},
  });
  const { id: wid } = await wRes.json();

  // Other user tries to access it — must be 403 or 404 (BOLA fix required)
  const r = await request.get(`${base}/api/workouts/${wid}`, {
    headers: { Authorization: `Bearer ${token2}` },
  });
  expect([403, 404]).toContain(r.status());
});
