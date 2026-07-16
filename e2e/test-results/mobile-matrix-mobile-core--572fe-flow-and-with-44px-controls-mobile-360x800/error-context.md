# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: mobile-matrix.spec.ts >> mobile core journeys >> keeps the login surface usable without horizontal overflow and with 44px controls
- Location: tests\mobile-matrix.spec.ts:57:7

# Error details

```
Error: expect(received).toBeTruthy()

Received: false
```

# Page snapshot

```yaml
- main [ref=e4]:
  - generic [ref=e6]:
    - heading "🔥 Hell Setlog" [level=1] [ref=e7]
    - paragraph [ref=e8]: 지옥의 피트니스 파티에 오신 것을 환영합니다
    - generic [ref=e9]:
      - generic [ref=e10]:
        - generic [ref=e11]: 이메일
        - textbox "이메일" [ref=e12]
      - generic [ref=e13]:
        - generic [ref=e14]: 비밀번호
        - textbox "비밀번호" [ref=e15]
      - button "로그인" [ref=e16] [cursor=pointer]
    - paragraph [ref=e17]:
      - text: 계정이 없으신가요?
      - link "회원가입" [ref=e18] [cursor=pointer]:
        - /url: /register
```

# Test source

```ts
  1  | import { expect, test } from '@playwright/test';
  2  | 
  3  | const base = process.env.E2E_API_URL || 'http://localhost:8001';
  4  | const password = 'pass1234';
  5  | const auth = (token: string) => ({ Authorization: `Bearer ${token}` });
  6  | 
  7  | async function newUser(request: any, prefix: string) {
  8  |   const username = `${prefix}${Date.now()}${Math.random().toString(16).slice(2, 8)}`;
  9  |   const register = await request.post(`${base}/api/auth/register`, { data: { username, email: `${username}@test.com`, password } });
  10 |   expect(register.status()).toBe(201);
  11 |   const login = await request.post(`${base}/api/auth/login`, { data: { username, password } });
  12 |   expect(login.status()).toBe(200);
  13 |   return (await login.json()).access_token as string;
  14 | }
  15 | 
  16 | test.describe('mobile core journeys', () => {
  17 |   test('records a set, ends the workout, and exposes body-part growth', async ({ request }) => {
  18 |     const token = await newUser(request, 'matrix-record-');
  19 |     const workout = await request.post(`${base}/api/workouts/`, { headers: auth(token), data: { notes: 'mobile matrix record' } });
  20 |     expect(workout.status()).toBe(201);
  21 |     const workoutId = (await workout.json()).id;
  22 |     const exercises = await request.get(`${base}/api/exercises`, { headers: auth(token) });
  23 |     expect(exercises.status()).toBe(200);
  24 |     const exercise = (await exercises.json())[0];
  25 |     expect(exercise?.id).toBeTruthy();
  26 |     const record = await request.post(`${base}/api/workout-records`, { headers: { ...auth(token), 'X-Idempotency-Key': `matrix-${workoutId}` }, data: { workout_id: workoutId, exercise_id: exercise.id, performed_at: new Date().toISOString(), sets: [{ set_index: 0, reps: 10, weight_kg: 20 }] } });
  27 |     expect(record.status()).toBe(201);
  28 |     const ended = await request.post(`${base}/api/workouts/${workoutId}/end`, { headers: auth(token) });
  29 |     expect(ended.status()).toBe(200);
  30 |     const growth = await ended.json();
  31 |     expect(growth.status).toBe('ended');
  32 |     expect(growth.body_stats).toEqual(expect.arrayContaining([expect.objectContaining({ part: expect.any(String), level: expect.any(Number) })]));
  33 |   });
  34 | 
  35 |   test('uploads a party video, returns playback, and denies a non-member', async ({ request }) => {
  36 |     const owner = await newUser(request, 'matrix-video-owner-');
  37 |     const outsider = await newUser(request, 'matrix-video-outsider-');
  38 |     const party = await request.post(`${base}/api/parties/`, { headers: auth(owner), data: { name: 'Mobile matrix party' } });
  39 |     expect(party.status()).toBe(201);
  40 |     const partyId = (await party.json()).id;
  41 |     const upload = await request.post(`${base}/api/media`, { headers: auth(owner), multipart: { party_id: String(partyId), file: { name: 'matrix.mp4', mimeType: 'video/mp4', buffer: Buffer.from('matrix-video') } } });
  42 |     expect(upload.status()).toBe(201);
  43 |     const key = (await upload.json()).key as string;
  44 |     expect(key).toMatch(/^users\/\d+\/.*\.mp4$/);
  45 |     const workout = await request.post(`${base}/api/workouts/`, { headers: auth(owner), data: { party_id: partyId } });
  46 |     expect(workout.status()).toBe(201);
  47 |     const workoutId = (await workout.json()).id;
  48 |     const setlog = await request.post(`${base}/api/workouts/${workoutId}/setlogs`, { headers: auth(owner), data: { type: 'mid', content: 'party video', file_path: key } });
  49 |     expect(setlog.status()).toBe(201);
  50 |     const playback = await request.get(`${base}/api/media/${key}/playback`, { headers: auth(owner) });
  51 |     expect(playback.status()).toBe(200);
  52 |     expect((await playback.json()).url).toBeTruthy();
  53 |     const denied = await request.get(`${base}/api/media/${key}/playback`, { headers: auth(outsider) });
  54 |     expect(denied.status()).toBe(403);
  55 |   });
  56 | 
  57 |   test('keeps the login surface usable without horizontal overflow and with 44px controls', async ({ page }) => {
  58 |     await page.goto('/login');
  59 |     await expect(page).toHaveTitle(/setlog/i);
  60 |     const metrics = await page.evaluate(() => ({ viewport: window.innerWidth, scrollWidth: document.documentElement.scrollWidth, controls: Array.from(document.querySelectorAll('button, a, input, select, textarea')).map((el) => { const rect = el.getBoundingClientRect(); return { width: rect.width, height: rect.height }; }) }));
  61 |     expect(metrics.scrollWidth).toBeLessThanOrEqual(metrics.viewport + 1);
> 62 |     expect(metrics.controls.every(({ width, height }) => width >= 44 && height >= 44)).toBeTruthy();
     |                                                                                        ^ Error: expect(received).toBeTruthy()
  63 |   });
  64 | });
  65 | 
```