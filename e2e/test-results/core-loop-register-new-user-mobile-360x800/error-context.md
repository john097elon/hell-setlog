# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: core-loop.spec.ts >> register new user
- Location: tests\core-loop.spec.ts:15:5

# Error details

```
Test timeout of 30000ms exceeded.
```

```
Error: locator.fill: Test timeout of 30000ms exceeded.
Call log:
  - waiting for getByLabel(/사용자명|username/i)

```

# Page snapshot

```yaml
- main [ref=e4]:
  - generic [ref=e6]:
    - heading "🔥 회원가입" [level=1] [ref=e7]
    - paragraph [ref=e8]: 파티에 참여할 준비가 되셨나요?
    - generic [ref=e9]:
      - generic [ref=e10]:
        - generic [ref=e11]: 닉네임
        - textbox "닉네임" [ref=e12]
      - generic [ref=e13]:
        - generic [ref=e14]: 이메일
        - textbox "이메일" [ref=e15]
      - generic [ref=e16]:
        - generic [ref=e17]: 비밀번호
        - textbox "비밀번호" [ref=e18]
      - button "회원가입" [ref=e19] [cursor=pointer]
    - paragraph [ref=e20]:
      - text: 이미 계정이 있으신가요?
      - link "로그인" [ref=e21] [cursor=pointer]:
        - /url: /login
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
> 17  |   await page.getByLabel(/사용자명|username/i).fill(USERNAME);
      |                                           ^ Error: locator.fill: Test timeout of 30000ms exceeded.
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
  41  |   await expect(page).not.toHaveURL(/login/);
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
```