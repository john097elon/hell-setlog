# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: core-loop.spec.ts >> login with registered credentials
- Location: tests\core-loop.spec.ts:28:5

# Error details

```
Error: expect(page).not.toHaveURL(expected) failed

Expected pattern: not /login/
Received string: "http://localhost:5173/login"
Timeout: 5000ms

Call log:
  - Expect "not toHaveURL" with timeout 5000ms
    14 × unexpected value "http://localhost:5173/login"

```

```yaml
- main:
  - heading "🔥 Hell Setlog" [level=1]
  - paragraph: 지옥의 피트니스 파티에 오신 것을 환영합니다
  - alert: 로그인 실패
  - text: 이메일
  - textbox "이메일": e2e1784192388593@test.com
  - text: 비밀번호
  - textbox "비밀번호": pass1234e2e
  - button "로그인"
  - paragraph:
    - text: 계정이 없으신가요?
    - link "회원가입":
      - /url: /register
```

# Test source

```ts
  1   | /**
  2   |  * Core user loop E2E: register → login → create party → start workout → add setlogs → end → see growth
  3   |  *
  4   |  * Each test run uses a unique username to avoid conflicts with existing DB data.
  5   |  */
  6   | import { test, expect } from '@playwright/test';
  7   | 
  8   | const uid = Date.now();
  9   | const USERNAME = `e2euser${uid}`;
  10  | const EMAIL = `e2e${uid}@test.com`;
  11  | const PASSWORD = 'pass1234e2e';
  12  | 
  13  | // ── Registration ─────────────────────────────────────────────────────────────
  14  | 
  15  | test('register new user', async ({ page }) => {
  16  |   await page.goto('/register');
  17  |   await page.getByLabel(/사용자명|username/i).fill(USERNAME);
  18  |   await page.getByLabel(/이메일|email/i).fill(EMAIL);
  19  |   await page.getByLabel(/비밀번호|password/i).fill(PASSWORD);
  20  |   await page.getByRole('button', { name: /가입|register|sign up/i }).click();
  21  | 
  22  |   // After register, should land on login or home
  23  |   await expect(page).toHaveURL(/login|home|\//);
  24  | });
  25  | 
  26  | // ── Login ─────────────────────────────────────────────────────────────────────
  27  | 
  28  | test('login with registered credentials', async ({ page }) => {
  29  |   await page.goto('/login');
  30  |   // Try username field first, fall back to email
  31  |   const usernameInput = page.getByLabel(/사용자명|username/i).first();
  32  |   if (await usernameInput.isVisible()) {
  33  |     await usernameInput.fill(USERNAME);
  34  |   } else {
  35  |     await page.getByLabel(/이메일|email/i).first().fill(EMAIL);
  36  |   }
  37  |   await page.getByLabel(/비밀번호|password/i).fill(PASSWORD);
  38  |   await page.getByRole('button', { name: /로그인|login|sign in/i }).click();
  39  | 
  40  |   // Should land somewhere past the login page
> 41  |   await expect(page).not.toHaveURL(/login/);
      |                          ^ Error: expect(page).not.toHaveURL(expected) failed
  42  | });
  43  | 
  44  | // ── Core loop (depends on login state — runs with fresh page context) ─────────
  45  | 
  46  | test('create party', async ({ page }) => {
  47  |   // Login first
  48  |   await page.goto('/login');
  49  |   const usernameInput = page.getByLabel(/사용자명|username/i).first();
  50  |   if (await usernameInput.isVisible()) {
  51  |     await usernameInput.fill(USERNAME);
  52  |   } else {
  53  |     await page.getByLabel(/이메일|email/i).first().fill(EMAIL);
  54  |   }
  55  |   await page.getByLabel(/비밀번호|password/i).fill(PASSWORD);
  56  |   await page.getByRole('button', { name: /로그인|login|sign in/i }).click();
  57  |   await expect(page).not.toHaveURL(/login/);
  58  | 
  59  |   // Navigate to party creation
  60  |   await page.goto('/parties');
  61  |   const createBtn = page.getByRole('button', { name: /파티 만들기|create party|새 파티/i });
  62  |   await expect(createBtn).toBeVisible({ timeout: 5_000 });
  63  |   await createBtn.click();
  64  | 
  65  |   const partyNameInput = page.getByLabel(/파티 이름|party name/i).or(page.getByPlaceholder(/파티 이름|party name/i));
  66  |   if (await partyNameInput.isVisible()) {
  67  |     await partyNameInput.fill(`E2E Party ${uid}`);
  68  |     await page.getByRole('button', { name: /만들기|create|확인/i }).last().click();
  69  |   }
  70  | 
  71  |   // Should see the party in the list or party room
  72  |   await expect(page.getByText(new RegExp(`E2E Party ${uid}|파티|party`, 'i'))).toBeVisible({ timeout: 5_000 });
  73  | });
  74  | 
  75  | test('start workout, add setlogs, end workout, see growth response', async ({ page, request }) => {
  76  |   // Use API directly for the heavy lifting — tests the contract, not just the UI
  77  |   const base = process.env.E2E_API_URL || 'http://localhost:8001';
  78  | 
  79  |   const loginRes = await request.post(`${base}/api/auth/login`, {
  80  |     data: { username: USERNAME, password: PASSWORD },
  81  |   });
  82  |   expect(loginRes.ok()).toBeTruthy();
  83  |   const { access_token } = await loginRes.json();
  84  | 
  85  |   // Create workout
  86  |   const wRes = await request.post(`${base}/api/workouts/`, {
  87  |     headers: { Authorization: `Bearer ${access_token}` },
  88  |     data: { notes: 'E2E workout' },
  89  |   });
  90  |   expect(wRes.status()).toBe(201);
  91  |   const { id: workoutId } = await wRes.json();
  92  | 
  93  |   // Add setlogs
  94  |   for (const [type, content] of [['start', '운동 시작'], ['mid', '가슴 세트'], ['mid', '등 세트']]) {
  95  |     const r = await request.post(`${base}/api/workouts/${workoutId}/setlogs`, {
  96  |       headers: { Authorization: `Bearer ${access_token}` },
  97  |       data: { type, content },
  98  |     });
  99  |     expect(r.status()).toBe(201);
  100 |   }
  101 | 
  102 |   // End workout
  103 |   const endRes = await request.post(`${base}/api/workouts/${workoutId}/end`, {
  104 |     headers: { Authorization: `Bearer ${access_token}` },
  105 |   });
  106 |   expect(endRes.status()).toBe(200);
  107 |   const endData = await endRes.json();
  108 | 
  109 |   // Contract assertions
  110 |   expect(endData.body_stats).toHaveLength(7);
  111 |   expect(endData.status).toBe('ended');
  112 |   expect(endData.ended_at).not.toBeNull();
  113 | 
  114 |   // Stats must persist on GET
  115 |   const getRes = await request.get(`${base}/api/workouts/${workoutId}`, {
  116 |     headers: { Authorization: `Bearer ${access_token}` },
  117 |   });
  118 |   // NOTE: This will fail until BOLA fix is applied (currently returns 200 for any user)
  119 |   // After fix: same user should still get 200
  120 |   expect(getRes.status()).toBe(200);
  121 |   expect((await getRes.json()).status).toBe('ended');
  122 | 
  123 |   // Ending twice is idempotent — the second call returns 200 with the same state.
  124 |   const end2 = await request.post(`${base}/api/workouts/${workoutId}/end`, {
  125 |     headers: { Authorization: `Bearer ${access_token}` },
  126 |   });
  127 |   expect(end2.status()).toBe(200);
  128 | });
  129 | 
  130 | test('non-owner cannot access another users workout (BOLA regression)', async ({ request }) => {
  131 |   const base = process.env.E2E_API_URL || 'http://localhost:8001';
  132 |   const uid2 = uid + 1;
  133 | 
  134 |   // Register a second user
  135 |   const regRes = await request.post(`${base}/api/auth/register`, {
  136 |     data: { username: `bola${uid2}`, email: `bola${uid2}@test.com`, password: 'pass1234' },
  137 |   });
  138 |   expect(regRes.status()).toBe(201);
  139 |   const loginRes2 = await request.post(`${base}/api/auth/login`, {
  140 |     data: { username: `bola${uid2}`, password: 'pass1234' },
  141 |   });
```